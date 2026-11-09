# BlueLite R038_14_ExtractOnlyBCDSDI_ReadOnly_v1.1.ps1 — two independently gated modes: exact 3x tiny ISO source copy and explicit offline /store BCD inspection.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Extract','ReadBCD')][string]$Mode,
 [string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300',
 [string]$ExpectedExtractReceiptSHA=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'OWNED_ROOT_ONLY'}
$logs=Join-Path $Root 'BlueLite_Logs'
$stage=Join-Path $logs 'R038_14_ISO_BCD_SDI'
$pre=Join-Path $logs 'R038_13_ISOFileTree_ReadOnly_Result.json'
$extractReceipt=Join-Path $logs 'R038_14_Extract_Result.json'
$readReceipt=Join-Path $logs 'R038_14_ReadBCD_Result.json'
if((Get-FileHash $pre).Hash -ne '01B80C84D22BE8D674B78BD3B663ED8876E7B7BA4AEFA545AE58C7FDF15E4529'){throw 'SOURCE_ISO_UDF_LIST_SHA_DRIFT'}
$report=Get-Content -LiteralPath $pre -Raw | ConvertFrom-Json
if($report.schema -ne 'BlueLite.R038.ISOSourceFileTreeReadOnly.v1' -or $report.status -ne 'NATIVE_7Z_ISO_CONTENTS_READ_ONLY_LISTED_BOOT_CHAIN_DEPENDENCIES_NOT_YET_CERTIFIED' -or $report.iso_extracted_files -ne 0){throw 'UNEXPECTED_SOURCE_UDF_REPORT'}
$iso=[string]$report.source_iso_path
if($report.source_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC' -or [long]$report.source_iso_bytes -ne 6749851648){throw 'SOURCE_ISO_MANIFEST_WRONG'}
$isoInfo=Get-Item -LiteralPath $iso -ErrorAction Stop
if($isoInfo.Length -ne 6749851648 -or (($isoInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'SOURCE_ISO_FILE_CHANGED_OR_REPARSE'}
$exe='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.exe'
$dll='C:\work\E2E\BlueLite_R85_Native_Converter_26200.9711_85096553\bin\7z.dll'
if((Get-FileHash $exe).Hash -ne '9E2631C19B243C28B0980607CED2540E9447B1166572483475547C1A9DD4AC0E' -or (Get-FileHash $dll).Hash -ne '3DB62076E5FCC897FF29DA47FE4029900A4AD696B395B6FA96ACFF1229444C1D'){throw '7Z_VENDOR_SHA_CHANGED'}
$baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
$control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or [string]$baseline.State -ne 'Running' -or [string]$control.State -ne 'Off'){throw 'HYPERV_GUEST_STATE_CHANGED'}
if([string](Get-VMFirmware -VMName $baseline.Name).SecureBoot -ne 'On' -or [string](Get-VMFirmware -VMName $control.Name).SecureBoot -ne 'Off'){throw 'HYPERV_SECUREBOOT_POLICY_CHANGED'}
if(@(Get-WindowsImage -Mounted).Count){throw 'HOST_WIM_MOUNTS'}
$wanted=@(
 [ordered]@{key='efi_microsoft_boot_bcd';expected_path='efi\microsoft\boot\bcd';expected_size=16384},
 [ordered]@{key='bios_boot_bcd';expected_path='boot\bcd';expected_size=16384},
 [ordered]@{key='bios_boot_sdi';expected_path='boot\boot.sdi';expected_size=3170304}
)
$sourceRows=[Collections.Generic.List[object]]::new()
foreach($w in $wanted){
 $src=@($report.paths|Where-Object {$_.key -eq $w.key})
 if($src.Count -ne 1 -or $src[0].found_count -ne 1 -or $src[0].matches.Count -ne 1){throw ('SOURCE_LIST_MEMBER_NOT_UNIQUE_'+$w.key)}
 $m=$src[0].matches[0]
 if([long]$m.size_bytes -ne [long]$w.expected_size){throw ('SOURCE_LIST_MEMBER_LENGTH_CHANGED_'+$w.key)}
 $archivePath=[string]$m.path
 $normalized=$archivePath.TrimStart([char[]]@('\','/')).Replace('/','\')
 if($normalized.ToLowerInvariant() -ne $w.expected_path -or $archivePath -ne $normalized -or $archivePath.Contains('..') -or [IO.Path]::IsPathRooted($archivePath)){throw ('SOURCE_MEMBER_PATH_NOT_SAFE_'+$w.key)}
 [void]$sourceRows.Add([ordered]@{key=$w.key;relative_path=$archivePath;expected_bytes=[long]$w.expected_size;destination=(Join-Path $stage $normalized)})
}
if([long](Get-PSDrive C).Free -lt 75000000000){throw 'DISK_HEADROOM_BELOW_75GB'}
$originalIsoHash=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
if($originalIsoHash -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'ORIGINAL_ISO_FULL_SHA_DRIFT'}
$scriptSHA=(Get-FileHash -LiteralPath $PSCommandPath).Hash
switch($Mode){
 'Extract' {
  if(Test-Path $stage){throw 'EXTRACTION_STAGE_ALREADY_EXISTS'}
  if(Test-Path $extractReceipt){throw 'EXTRACTION_RESULT_ALREADY_EXISTS'}
  [void][IO.Directory]::CreateDirectory($stage)
  $outputs=[Collections.Generic.List[object]]::new()
  foreach($member in $sourceRows){
   $dest=[string]$member.destination
   if(Test-Path -LiteralPath $dest){throw 'EXACT_DESTINATION_ALREADY_PRESENT'}
   $args=@('x','-y','-bd',("-o"+$stage),$iso,([string]$member.relative_path))
   $raw=@(& $exe @args 2>&1|ForEach-Object {[string]$_})
   $code=$LASTEXITCODE
   if($raw.Count -gt 1500 -or $code -ne 0){throw ('7Z_EXTRACT_ERR_'+$member.key+'_exit'+$code+'_'+([string]::Join(';',@($raw|Select-Object -Last 5))))}
   $file=Get-Item -LiteralPath $dest -ErrorAction Stop
   if($file.Length -ne [long]$member.expected_bytes -or (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw ('EXTRACTED_SIZE_OR_LINK_WRONG_'+$member.key)}
   [void]$outputs.Add([ordered]@{key=$member.key;source_iso_member=$member.relative_path;original_iso_path=$iso;path=$dest;bytes=$file.Length;sha256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash;extract_exit_code=$code})
   Write-Output ('R038_OP52_EXTRACTED_SHA_PASS '+$member.key+' bytes='+$file.Length+' sha='+(Get-FileHash $dest).Hash)
  }
  if($outputs.Count -ne 3){throw 'EXPECTED_THREE_EXTRACTED'}
  $totalBytes=[long]0;foreach($v in $outputs){$totalBytes+=[long]$v.bytes}
  $data=[ordered]@{schema='BlueLite.R038.SmallBCDSDIExtraction.v1';utc=[DateTime]::UtcNow.ToString('o');mode='Extract';status='EXTRACTED_THREE_SOURCE_ISO_BOOT_FILES_SHA_PASS';script_sha256=$scriptSHA;parent_udf_inventory_receipt_sha=(Get-FileHash $pre).Hash;original_iso_path=$iso;original_iso_bytes=$isoInfo.Length;original_iso_sha256=$originalIsoHash;sevenzip_executable_sha256=(Get-FileHash $exe).Hash;sevenzip_dll_sha256=(Get-FileHash $dll).Hash;owned_stage_directory=$stage;files=@($outputs);total_extracted_bytes=$totalBytes;guest_baseline='RUNNING_SECUREBOOT_ON';guest_control='OFF_SECUREBOOT_OFF';host_BCD_EFI_modified=$false;original_ISO_WIM_modified=$false;guest_modified=$false}
  $json=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
  $fh=[IO.File]::Open($extractReceipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$fh.Write($json)}finally{$fh.Dispose()}
  Write-Output ('R038_14_EXTRACT_PASS receiptSha='+(Get-FileHash $extractReceipt).Hash+' fileCount='+$outputs.Count+' totalBytes='+$data.total_extracted_bytes+' noHostBCDChange=true')
 }
 'ReadBCD' {
  if([string]::IsNullOrWhiteSpace($ExpectedExtractReceiptSHA) -or $ExpectedExtractReceiptSHA -notmatch '^[A-Fa-f0-9]{64}$'){throw 'EXACT_EXTRACT_RECEIPT_SHA_REQUIRED_FOR_BCD'}
  if((Get-FileHash -LiteralPath $extractReceipt).Hash -ne $ExpectedExtractReceiptSHA.ToUpperInvariant()){throw 'EXTRACT_RECEIPT_SHA_CHANGED'}
  if(Test-Path $readReceipt){throw 'BCD_READ_RESULT_ALREADY_EXISTS'}
  $ex=Get-Content -LiteralPath $extractReceipt -Raw|ConvertFrom-Json
  if($ex.schema -ne 'BlueLite.R038.SmallBCDSDIExtraction.v1' -or $ex.status -ne 'EXTRACTED_THREE_SOURCE_ISO_BOOT_FILES_SHA_PASS' -or $ex.files.Count -ne 3 -or $ex.script_sha256 -ne $scriptSHA){throw 'EXTRACT_REPORT_NOT_VALID_FOR_THIS_SCRIPT'}
  foreach($f in $ex.files){
   $expectedOne=@($sourceRows|Where-Object {$_.key -eq $f.key})
   if($expectedOne.Count -ne 1 -or $f.path -ne $expectedOne[0].destination){throw ('EXTRACT_DEST_NOT_OWNED_'+$f.key)}
   $physical=Get-Item -LiteralPath $f.path -ErrorAction Stop
   if($physical.Length -ne [long]$f.bytes -or (Get-FileHash $f.path).Hash -ne $f.sha256){throw ('EXTRACTED_SMALL_SOURCE_SHA_DRIFT_'+$f.key)}
  }
  $bcd='C:\Windows\System32\bcdedit.exe'
  if(-not(Test-Path -LiteralPath $bcd -PathType Leaf)){throw 'EXPLICIT_SYSTEM32_BCDEDIT_NOT_FOUND'}
  $bcdReports=[Collections.Generic.List[object]]::new()
  foreach($key in @('efi_microsoft_boot_bcd','bios_boot_bcd')){
   $files=@($ex.files|Where-Object {$_.key -eq $key})
   if($files.Count -ne 1){throw ('BCD_STAGED_NOT_UNIQUE_'+$key)}
   $store=[string]$files[0].path
   if(-not $store.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase) -or $store -notmatch '(?i)\\BCD$'){throw ('UNOWNED_OFFLINE_BCD_STORE_'+$key)}
   # The /store argument is mandatory and explicit; no host BCD manager is touched.
   $native=@(& $bcd /store $store /enum all /v 2>&1|ForEach-Object {[string]$_})
   $exit=$LASTEXITCODE
   if($native.Count -gt 3000){throw 'BCDEDIT_OUTPUT_UNBOUNDED'}
   $text=[string]::Join([Environment]::NewLine,$native)
   if($text.Length -gt 200000){throw 'BCDEDIT_TEXT_UNBOUNDED'}
   $small=@($native|Where-Object {$_ -match '(?i)(ramdisk|sdi|\.wim|boot manager|boot loader|device|osdevice|winpe|path|description|recovery)' }|Select-Object -First 150)
   [void]$bcdReports.Add([ordered]@{key=$key;store_path=$store;store_sha256=$files[0].sha256;store_bytes=$files[0].bytes;command='bcdedit.exe /store <explicit owned BCD> /enum all /v';exit_code=$exit;native_text_sha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)));native_text=$text;matched_relevant_lines=@($small)})
   Write-Output ('R038_14_OFFLINE_BCD '+$key+' exit='+$exit+' records='+$native.Count+' textSHA='+$bcdReports[$bcdReports.Count-1].native_text_sha256)
  }
  $allOK=@($bcdReports|Where-Object {$_.exit_code -eq 0}).Count -eq 2
  $status=if($allOK){'TWO_EXPLICIT_OFFLINE_BCD_STORES_READ_ONLY_ENUMERATED_PASS'}else{'EXPLICIT_OFFLINE_BCD_READ_DEPENDENCY_HOLD'}
  $data=[ordered]@{schema='BlueLite.R038.OfflineBCDSourceReview.v1';utc=[DateTime]::UtcNow.ToString('o');mode='ReadBCD';status=$status;script_sha256=$scriptSHA;extract_receipt_sha256=(Get-FileHash $extractReceipt).Hash;source_iso_sha256=$originalIsoHash;original_iso_bytes=$isoInfo.Length;literal_cmd_store_only=$true;native_bcdedit_path=$bcd;entries=@($bcdReports);boot_sdi_source_sha256=@($ex.files|Where-Object{$_.key -eq 'bios_boot_sdi'})[0].sha256;host_bcd_changed=$false;host_efi_changed=$false;guest_changed=$false;source_iso_modified=$false;stageA_setup_ui='NOT_REACHED';installed_first_boot='NOT_RUN';later_boots='NOT_RUN'}
  $json=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
  if($json.Length -gt 500000){throw 'BCD_JSON_TOO_LARGE'}
  $fh=[IO.File]::Open($readReceipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  try{$fh.Write($json)}finally{$fh.Dispose()}
  Write-Output ('R038_14_READBCD status='+$status+' receiptSha='+(Get-FileHash $readReceipt).Hash+' sourceISOunchanged=true')
  if(-not $allOK){exit 17}
 }
 default{throw 'UNSUPPORTED_MODE'}
}
