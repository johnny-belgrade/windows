# BlueLite R038_13_ISOSetupBCD_BootWIM_ReadOnly_v1.1.ps1 — bounded ISO file-tree LIST; SHA-pinned vendor 7z; no mounting/extraction/VM edits.
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'OWNED_R038_ROOT_REQUIRED'}
$logs=Join-Path $Root 'BlueLite_Logs'
$out=Join-Path $logs 'R038_13_ISOFileTree_ReadOnly_Result.json'
if(Test-Path -LiteralPath $out){throw 'OUTPUT_EXISTS_NO_BLIND_RERUN'}
$manifestPath=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
if((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash -ne '44B29FB8BFB13A4CD7627570C4CD8C65314647CEDFD8BF1A2B69B5A56163D290'){throw 'SOURCE_MANIFEST_SHA_DRIFT'}
$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
$isoItem=@($manifest.media|Where-Object {$_.kind -eq 'R035_ISO'})
$bootItem=@($manifest.media|Where-Object {$_.kind -eq 'R035_SETUP_BOOT_WIM'})
if($isoItem.Count -ne 1 -or $bootItem.Count -ne 1){throw 'SOURCE_MANIFEST_NOT_UNIQUE'}
$iso=[string]$isoItem[0].path
$boot=[string]$bootItem[0].path
if($isoItem[0].sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC' -or [long]$isoItem[0].bytes -ne 6749851648){throw 'EXPECTED_ISO_SOURCE_PIN_DRIFT'}
if($bootItem[0].sha256 -ne 'F659254B86D7478B02A5D02204530CDA8805FE8EA58A4DFE69F69BB4C0144A26' -or [long]$bootItem[0].bytes -ne 824384151){throw 'EXPECTED_BOOTWIM_PIN_DRIFT'}
foreach($info in @($isoItem[0],$bootItem[0])){
 $fi=Get-Item -LiteralPath ([string]$info.path) -ErrorAction Stop
 if($fi.Length -ne [long]$info.bytes -or (($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ('SOURCE_FILE_CHANGED_OR_LINK_'+$info.kind)}
}
$exe='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
$dll='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
$expExe='9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E'
$expDll='3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'
if((Get-FileHash -LiteralPath $exe).Hash -ne $expExe -or (Get-FileHash -LiteralPath $dll).Hash -ne $expDll){throw 'VENDOR_TOOL_BINARY_SHA_CHANGED'}
$baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
$control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if([string]$baseline.State -ne 'Running' -or [string]$control.State -ne 'Off' -or $baseline.Generation -ne 2 -or $control.Generation -ne 2){throw 'GUEST_STATES_CHANGED_FROM_OP42'}
if([string](Get-VMFirmware -VMName $baseline.Name).SecureBoot -ne 'On' -or [string](Get-VMFirmware -VMName $control.Name).SecureBoot -ne 'Off'){throw 'GUEST_SECUREBOOT_POLICY_CHANGED'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'HOST_WIM_MOUNTED'}
# One time immutable-input content SHA, not inferred from size. 7-Zip 'l' only reads the ISO.
$isoHash=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
if($isoHash -ne $isoItem[0].sha256){throw 'ORIGINAL_ISO_SHA_CHANGED'}
$bootHash=(Get-FileHash -LiteralPath $boot -Algorithm SHA256).Hash
if($bootHash -ne $bootItem[0].sha256){throw 'ORIGINAL_BOOT_WIM_SHA_CHANGED'}
$actualImages=@(Get-WindowsImage -ImagePath $boot -ErrorAction Stop)
if($actualImages.Count -ne 2 -or $actualImages[0].ImageIndex -ne 1 -or $actualImages[1].ImageIndex -ne 2){throw 'ACTUAL_SETUP_WIM_INDICES_CHANGED'}
# Read-only 7-Zip listing: not extracting or copying any ISO member.
$raw=@(& $exe l -slt $iso 2>&1)
$code=$LASTEXITCODE
$lines=@($raw|ForEach-Object {[string]$_})
if($lines.Count -lt 8 -or $lines.Count -gt 150000){throw ('7Z_LIST_OUTPUT_BOUND_'+$lines.Count)}
if($code -ne 0){throw ('7Z_LIST_NONZERO_'+$code+'_'+($lines|Select-Object -Last 4))}
$full=[string]::Join([Environment]::NewLine,$lines)
if($full.Length -gt 16000000){throw 'LIST_OUTPUT_OVER_16M_CHARS'}
$listSha=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($full)))
$list=[Collections.Generic.List[object]]::new()
$current=$null
$hasDivider=$false
$mediaType=$null
foreach($line in $lines){
 if($line -match '^Type = (.+)$' -and $null -eq $mediaType){$mediaType=$Matches[1]}
 if($line -match '^-{4,}\s*$'){$hasDivider=$true}
 if($line -match '^Path = (.*)$'){
  $candidate=[string]$Matches[1]
  if([string]::IsNullOrWhiteSpace($candidate)){continue}
  if(($candidate -eq $iso) -or ($candidate.StartsWith('C:\',[StringComparison]::OrdinalIgnoreCase))){$current=$null;continue}
  $n=$candidate.TrimStart([char[]]@('\','/')).Replace('/','\')
  if(-not $n){continue}
  $current=[ordered]@{path=$candidate;normalized=$n;size_bytes=$null;is_directory=$null}
  [void]$list.Add($current)
  if($list.Count -gt 100000){throw 'ISO_FILES_OVER_BOUNDED_COUNT'}
 }elseif($null -ne $current -and $line -match '^Size = ([0-9]+)$'){
  $current.size_bytes=[long]$Matches[1]
 }elseif($null -ne $current -and $line -match '^Folder = ([+-])$'){
  $current.is_directory=($Matches[1] -eq '+')
 }
}
$expected=@(
 [ordered]@{key='efi_boot_bootx64_efi';path='efi\boot\bootx64.efi'},
 [ordered]@{key='efi_microsoft_boot_bcd';path='efi\microsoft\boot\bcd'},
 [ordered]@{key='bios_boot_bcd';path='boot\bcd'},
 [ordered]@{key='bios_boot_sdi';path='boot\boot.sdi'},
 [ordered]@{key='setup_boot_wim';path='sources\boot.wim'},
 [ordered]@{key='bootmgr';path='bootmgr'},
 [ordered]@{key='efi_bootmgfw';path='efi\microsoft\boot\bootmgfw.efi'},
 [ordered]@{key='efi_boot_sdi';path='efi\microsoft\boot\boot.sdi'}
)
$pathEvidence=[Collections.Generic.List[object]]::new()
foreach($item in $expected){
 $found=@($list|Where-Object {([string]$_.normalized).ToLowerInvariant() -eq $item.path})
 [void]$pathEvidence.Add([ordered]@{key=$item.key;expected_path=$item.path;found_count=$found.Count;matches=@($found)})
 Write-Output ('R038_OP47_ISO_TREE '+$item.key+' count='+$found.Count+' size='+$(if($found.Count){$found[0].size_bytes}else{'NOT_LISTED'}))
}
$special=@($list|Where-Object { ([string]$_.normalized) -match '(?i)(^|\\)(bcd|boot\.sdi|boot\.wim|bootx64\.efi|bootmgfw\.efi|etfsboot\.com|efisys\.bin)$' }|Select-Object -First 100)
$report=[ordered]@{
 schema='BlueLite.R038.ISOSourceFileTreeReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='NATIVE_7Z_ISO_CONTENTS_READ_ONLY_LISTED_BOOT_CHAIN_DEPENDENCIES_NOT_YET_CERTIFIED'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash
 source_iso_path=$iso
 source_iso_bytes=6749851648
 source_iso_sha256=$isoHash
 source_boot_wim_path=$boot
 source_boot_wim_bytes=824384151
 source_boot_wim_sha256=$bootHash
 boot_wim_images=@($actualImages|ForEach-Object {[ordered]@{index=$_.ImageIndex;name=$_.ImageName}})
 sevenzip_executable_path=$exe
 sevenzip_executable_sha256=$expExe
 sevenzip_dll_sha256=$expDll
 sevenzip_listing_exit_code=$code
 sevenzip_listing_text_sha256=$listSha
 sevenzip_media_type=$mediaType
 sevenzip_entry_count=$list.Count
 sevenzip_line_count=$lines.Count
 sevenzip_divider_seen=$hasDivider
 paths=@($pathEvidence)
 other_boot_related=@($special)
 guest_secureboot_on_baseline='Running'
 guest_secureboot_off_control='Off'
 host_wim_mounts=0
 iso_extracted_files=0
 original_source_file_mutated=$false
 host_BCD_EFI_written=$false
 setup_GUI='NOT_REACHED'
 installed_first_boot='NOT_RUN'
 installed_repeat_boot='NOT_RUN'
}
$json=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
if($json.Length -gt 800000){throw 'EVIDENCE_RECEIPT_UNBOUNDED'}
$f=[IO.File]::Open($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($json)}finally{$f.Dispose()}
Write-Output ('R038_OP47_SOURCE_ISO_LIST_READONLY_PASS pathCount='+$list.Count+' mediaType='+$mediaType+' reportSha='+(Get-FileHash $out).Hash+' sourceSha='+$isoHash+' scriptSHA='+$report.script_sha256)
