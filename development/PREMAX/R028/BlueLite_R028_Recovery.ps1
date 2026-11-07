# R028: convert PREVIOUS VERIFIED R027 WIM-EXPORT HOLD into a new owned image candidate.
# No redownload, no replay of converter, no original vendor/GOLDEN modifications.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$Stage,[Parameter(Mandatory=$true)][string]$SelectedRoot,[Parameter(Mandatory=$true)][string]$ExpectedBuild)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function MustBL([bool]$x,[string]$why){if(-not $x){throw ('R028_RECOVER_HOLD_'+$why)}}
function HashBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function ExecBL([string[]]$DismArguments,[string]$label){& dism.exe @DismArguments;MustBL ($LASTEXITCODE -eq 0) ('DISM_'+$label+'_EXIT_'+$LASTEXITCODE)}
function EmitBL([string]$p,$o){$data=[Text.UTF8Encoding]::new($false).GetBytes(($o|ConvertTo-Json -Depth 15)+[Environment]::NewLine);$f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$f.Write($data,0,$data.Length)}finally{$f.Dispose()}}
$stage=[IO.Path]::GetFullPath($Stage).TrimEnd([char]'\')
$root=[IO.Path]::GetFullPath($SelectedRoot).TrimEnd([char]'\')
$logs=Join-Path $root 'BlueLite_Logs'
$srcWim=Join-Path $stage 'BlueLite_FinalWim_Work\install.compact.wim'
$isoFolder=Join-Path $stage 'ISOFOLDER'
$layoutWim=Join-Path $isoFolder 'sources\install.wim'
$boot=Join-Path $isoFolder 'sources\boot.wim'
$helper=Join-Path $root 'BlueLite_R028_FoD.ps1'
$baseLog=Join-Path $stage 'BlueLite_Logs\FinalWimDebloat.log'
$stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$owned=Join-Path $stage ('BlueLite_R028_Recovery_'+$stamp)
$mount=Join-Path $owned 'Mount'
$backup=Join-Path $owned 'PreviousUncompactedInstall.wim'
$out=Join-Path $stage 'BlueLite_R028_Outputs'
$target=Join-Path $out 'install.wim'
$targetBoot=Join-Path $out 'boot.wim'
$iso=Join-Path $out ('BlueLite_R028_'+$ExpectedBuild+'_amd64_en-us_professional.ISO')
$report=Join-Path $logs ('BlueLite_R028_Recovery_'+$stamp+'.json')
$fullStatus='NOT_STARTED'
$mounted=$false
try{
 MustBL ($stage.StartsWith((Join-Path $root 'BlueLite_Work')+'\',[StringComparison]::OrdinalIgnoreCase)) 'STAGE_OWNERSHIP'
 MustBL ($stage -match '\\BlueLite_Stage_v11_3_26300_9818_[a-f0-9]{8}_[a-f0-9]{8}$') 'ONLY_R027_FAILED_26300_9818_SUPPORTED'
 MustBL ($ExpectedBuild -eq '26300.9818') 'EXPECTED_BUILD'
 MustBL ((Test-Path $srcWim -PathType Leaf) -and (Test-Path $layoutWim -PathType Leaf) -and (Test-Path $boot -PathType Leaf)) 'EXACT_UNFINISHED_WIMS'
 MustBL ((Test-Path (Join-Path $stage 'BlueLite_Logs\ConvertStart.marker') -PathType Leaf)) 'CONVERTER_WAS_NOT_STARTED'
 MustBL ((Test-Path $baseLog) -and ([IO.File]::ReadAllText($baseLog).Contains('Compact export identity gate failed: expected build 26300.9818'))) 'WRONG_FAILURE_CAUSE'
 MustBL (-not(Test-Path -LiteralPath $out)) 'R028_OUTPUT_ALREADY_EXISTS'
 MustBL (@(Get-WindowsImage -Mounted).Count -eq 0) 'ACTIVE_WIM_MOUNTS'
 MustBL (@(Get-Process -Name 'dism','NTLite','aria2c' -ErrorAction SilentlyContinue).Count -eq 0) 'COMPETING_PROCESSES'
 MustBL ([IO.DriveInfo]::new($stage.Substring(0,3)).AvailableFreeSpace -gt 17GB) 'LOW_DISK_SPACE'
 $version=@(& dism.exe /English /Get-WimInfo "/WimFile:$srcWim" /Index:1 2>&1|ForEach-Object{$_.ToString()}) -join [Environment]::NewLine
 MustBL ($LASTEXITCODE -eq 0 -and $version -match '(?im)^[ \t]*Version\s*:\s*10\.0\.26300\s*$' -and $version -match '(?im)^[ \t]*Edition\s*:\s*Professional\s*$' -and $version -match '(?im)^[ \t]*Architecture\s*:\s*x64\s*$') 'COMPACT_WIM_IDENTITY'
 $originalHash=HashBL $srcWim
 [void][IO.Directory]::CreateDirectory($mount)
 $fullStatus='MOUNT_REQUESTED'
 ExecBL @('/English','/Mount-Image',"/ImageFile:$srcWim",'/Index:1',"/MountDir:$mount") 'MOUNT'
 $mounted=$true;$fullStatus='MOUNTED'
 $fodReport=Join-Path $logs ('BlueLite_R028_FoD_Recovery_'+$stamp+'.json')
 & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $helper -Mode Execute -MountPath $mount -ReportPath $fodReport -RemoveNetworkDriverFoD -RemoveSenseClientFoD
 MustBL ($LASTEXITCODE -eq 0) 'FOD_HELPER_HOLD'
 ExecBL @('/English',"/Image:$mount",'/Cleanup-Image','/CheckHealth') 'HEALTH'
 ExecBL @('/English','/Unmount-Image',"/MountDir:$mount",'/Commit') 'COMMIT'
 $mounted=$false;$fullStatus='FOD_COMMITTED'
 [void][IO.Directory]::CreateDirectory($out)
 ExecBL @('/English','/Export-Image',"/SourceImageFile:$srcWim",'/SourceIndex:1',"/DestinationImageFile:$target",'/Compress:max','/CheckIntegrity') 'EXPORT'
 MustBL ((Get-Item $target).Length -gt 2000000000L) 'EXPORTED_WIM_UNEXPECTEDLY_SMALL'
 $version=@(& dism.exe /English /Get-WimInfo "/WimFile:$target" /Index:1 2>&1|ForEach-Object{$_.ToString()}) -join [Environment]::NewLine
 MustBL ($LASTEXITCODE -eq 0 -and $version -match '(?im)^[ \t]*Version\s*:\s*10\.0\.26300\s*$' -and $version -match '(?im)^[ \t]*Edition\s*:\s*Professional\s*$') 'FINAL_WIM_IDENTITY'
 $wimlib=Join-Path $stage 'bin\wimlib-imagex.exe'
 $recovery=@(& $wimlib dir $target 1 '--path=/Windows/System32/Recovery' 2>&1|ForEach-Object{$_.ToString()})
 MustBL ($LASTEXITCODE -eq 0 -and -not(@($recovery|Where-Object{$_ -match '(?i)\\winre\.wim(\s|$)'}).Count)) 'WINRE_IN_INSTALL_WIM'
 New-Item -ItemType HardLink -Path $targetBoot -Target $boot -ErrorAction Stop | Out-Null
 MustBL ((HashBL $boot) -eq (HashBL $targetBoot)) 'BOOT_HARDLINK_SHA'
 $fullStatus='EXPORT_VERIFIED'
 # Preserve previous generated 7.49GB WIM under unique owned rescue as an exact rollback.
 Move-Item -LiteralPath $layoutWim -Destination $backup -ErrorAction Stop
 New-Item -ItemType HardLink -Path $layoutWim -Target $target -ErrorAction Stop | Out-Null
 MustBL ((HashBL $layoutWim) -eq (HashBL $target)) 'ISO_LAYOUT_WIM_SHA'
 $oscd=Join-Path $stage 'bin\cdimage.exe'
 MustBL (Test-Path $oscd -PathType Leaf) 'ORIGINAL_PROVIDER_CDIMAGE_NOT_FOUND'
 MustBL (Test-Path (Join-Path $isoFolder 'boot\etfsboot.com')) 'BIOS_BOOT_MISSING'
 MustBL (Test-Path (Join-Path $isoFolder 'efi\Microsoft\boot\efisys.bin')) 'UEFI_BOOT_MISSING'
 $bootParam='-bootdata:2#p0,e,b'+(Join-Path $isoFolder 'boot\etfsboot.com')+'#pEF,e,b'+(Join-Path $isoFolder 'efi\Microsoft\boot\efisys.bin')
 & $oscd $bootParam '-o' '-m' '-u2' '-udfver102' '-lBLUELITE_R028_26300' $isoFolder $iso
 MustBL ($LASTEXITCODE -eq 0 -and (Test-Path $iso -PathType Leaf)) ('NATIVE_ISO_EXIT_'+$LASTEXITCODE)
 $isoSize=(Get-Item $iso).Length
 MustBL ($isoSize -gt (Get-Item $target).Length) 'ISO_SMALLER_THAN_INSTALL_WIM'
 $archiver=Join-Path $stage 'bin\7z.exe'
 & $archiver t '-bd' $iso *> $null
 MustBL ($LASTEXITCODE -eq 0) 'ISO_7Z_TEST_FAILED'
 $fullStatus='ISO_BUILT_CANDIDATE'
 EmitBL $report ([ordered]@{schema='BlueLite.R028.Rescue.v1';status=$fullStatus;utc=[DateTime]::UtcNow.ToString('o');source_stage=$stage;source_compact_sha256=$originalHash;final_wim=$target;final_wim_sha256=(HashBL $target);final_wim_bytes=(Get-Item $target).Length;boot_wim_sha256=(HashBL $boot);iso=$iso;iso_sha256=(HashBL $iso);iso_bytes=$isoSize;offline_fod_report=$fodReport;old_uncompacted_wim_backup=$backup;install_winre_wim_absent=$true;release_certified=$false;one_next='RETURN_EVIDENCE_VERIFY_FOD_APP_INSTALLER_VM'})
 Write-Host ('R028_NATIVE_RESCUE_ISO_CANDIDATE_PASS '+$report)
 exit 0
}catch{
 Write-Host ('R028_RESCUE_HOLD '+$_.Exception.Message+' STATUS='+$fullStatus)
 if($mounted){& dism.exe /English /Unmount-Image "/MountDir:$mount" /Discard}
 try{if(-not(Test-Path $report)){EmitBL $report ([ordered]@{status='HOLD';reason=$_.Exception.Message;step=$fullStatus;source=$srcWim;stage=$stage;one_next='DO_NOT_REPEAT_RETURN_EVIDENCE'})}}catch{}
 exit 17
}
