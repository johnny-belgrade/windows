# R029 capture: native setup install+boot WIM hardlinks before converter removes ISOFOLDER.
[CmdletBinding()]
param([string]$StageRoot='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function Gate([bool]$ok,[string]$why){if(-not $ok){throw ('R029_CAPTURE_HOLD_'+$why)}}
function Sha([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function Save([string]$p,$obj){
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
$stage=[IO.Path]::GetFullPath($StageRoot).TrimEnd('\')
$work=[IO.Path]::GetDirectoryName($stage)
$root=[IO.Path]::GetDirectoryName($work)
$logs=Join-Path $root 'BlueLite_Logs'
$wim=Join-Path $stage 'ISOFOLDER\sources\install.wim'
$boot=Join-Path $stage 'ISOFOLDER\sources\boot.wim'
$exe=Join-Path $stage 'bin\wimlib-imagex.exe'
$dest=Join-Path $stage 'BlueLite_R029_Outputs'
$record=Join-Path $logs 'BlueLite_R029_Capture_Result.json'
try {
 Gate ($root.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and $root -notmatch '\s') 'NOT_PORTABLE_C_WORK_ROOT'
 Gate ([IO.Path]::GetFileName($work) -eq 'BlueLite_Work') 'STAGE_NOT_CHILD_OF_SELECTED_BLUE_WORK'
 Gate ([IO.Path]::GetFileName($stage) -match '^BlueLite_Stage_v11_3_26300_\d+_[a-f0-9]{8}_[a-f0-9]{8}$') 'NOT_R029_COMPATIBLE_STAGE'
 Gate (Test-Path -LiteralPath $logs -PathType Container) 'ROOT_LOGS_MISSING'
 Gate (Test-Path -LiteralPath $wim -PathType Leaf) 'FINAL_INSTALL_WIM_NOT_PRESENT'
 Gate (Test-Path -LiteralPath $boot -PathType Leaf) 'SETUP_BOOT_WIM_NOT_PRESENT'
 Gate (Test-Path -LiteralPath $exe -PathType Leaf) 'ORIGINAL_STAGE_WIMLIB_MISSING'
 Gate (Test-Path -LiteralPath (Join-Path $logs 'BlueLite_R029_Offline_Result.json') -PathType Leaf) 'OFFLINE_WIM_RESULT_MISSING'
 Gate (-not(Test-Path -LiteralPath $dest) -and -not(Test-Path -LiteralPath $record)) 'CAPTURE_ALREADY_ATTEMPTED'
 $offline=Get-Content -LiteralPath (Join-Path $logs 'BlueLite_R029_Offline_Result.json') -Raw|ConvertFrom-Json
 Gate ([string]$offline.status -like 'CANDIDATE_OFFLINE_COMPLETE*') 'OFFLINE_WIM_NOT_COMMITTED'
 Gate ((Sha $wim) -eq [string]$offline.promoted_wim_sha256) 'WIM_NOT_EXACT_PROMOTED_SHA'
 $info=@(& $exe info $wim 1 2>&1|ForEach-Object{$_.ToString()})
 Gate ($LASTEXITCODE -eq 0) 'WIMLIB_INSTALL_INDEX'
 $bootInfo=@(& $exe info $boot 1 2>&1|ForEach-Object{$_.ToString()})
 Gate ($LASTEXITCODE -eq 0) 'WIMLIB_BOOT_INDEX'
 $recovery=@(& $exe dir $wim 1 '--path=/Windows/System32/Recovery' 2>&1|ForEach-Object{$_.ToString()})
 Gate ($LASTEXITCODE -eq 0) 'INSTALLED_RECOVERY_DIR_QUERY'
 Gate (@($recovery|Where-Object {$_ -match '(?i)(?:^|[\\/\s])Winre\.wim(?:\s|$)'}).Count -eq 0) 'WINRE_WIM_INSTALLED_IN_FINAL_IMAGE'
 $bootHash=Sha $boot
 [void][IO.Directory]::CreateDirectory($dest)
 $destWim=Join-Path $dest 'install.wim';$destBoot=Join-Path $dest 'boot.wim'
 New-Item -ItemType HardLink -Path $destWim -Target $wim -ErrorAction Stop|Out-Null
 New-Item -ItemType HardLink -Path $destBoot -Target $boot -ErrorAction Stop|Out-Null
 Gate ((Sha $destWim) -eq [string]$offline.promoted_wim_sha256 -and (Sha $destBoot) -eq $bootHash) 'CAPTURE_HARDLINK_SHA'
 $tempWinRE=Join-Path $stage 'temp\winre.wim'
 $status=[ordered]@{schema='BlueLite.R029.SetupWimCapture.v1';utc=[DateTime]::UtcNow.ToString('o');status='NATIVE_WIM_BOOT_HARDLINK_SHA_PASS';root=$root;stage=$stage;install_wim=$destWim;install_bytes=(Get-Item -LiteralPath $destWim).Length;install_sha256=(Sha $destWim);setup_boot_wim=$destBoot;setup_boot_bytes=(Get-Item -LiteralPath $destBoot).Length;setup_boot_sha256=$bootHash;installed_winre_wim_absent=$true;temporary_setup_recovery_winre_wim_existed=(Test-Path -LiteralPath $tempWinRE);no_release_certification=$true;one_next='NATIVE_PROVIDER_ISO_BUILD_AND_FINAL_INTEGRITY'}
 Save $record $status
 Write-Host ('R029_CAPTURE_WIM_BOOT_SHA_PASS '+$record)
 exit 0
}catch{
 $msg=$_.Exception.Message
 try{if((Test-Path -LiteralPath $logs) -and -not(Test-Path -LiteralPath $record)){Save $record ([ordered]@{status='HOLD';reason=$msg;utc=[DateTime]::UtcNow.ToString('o')})}}catch{}
 Write-Host ('R029_CAPTURE_HOLD '+$msg)
 exit 17
}
