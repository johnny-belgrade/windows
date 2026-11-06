# BlueLite R027 — captures final offline-debloated WIM and Setup WinPE before original converter :QUIT.
[CmdletBinding()]
param([string]$StageRoot='.')
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Need([bool]$x,[string]$why){if(-not $x){throw ('R027_CAPTURE_HOLD_'+$why)}}
function Hash([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function Save([string]$path,$value){$json=($value|ConvertTo-Json -Depth 8)+[Environment]::NewLine;$bytes=New-Object System.Text.UTF8Encoding($false);$stream=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None);try{$data=$bytes.GetBytes($json);$stream.Write($data,0,$data.Length)}finally{$stream.Dispose()}}
$root=[IO.Path]::GetFullPath($StageRoot).TrimEnd([char]'\')
$src=Join-Path $root 'ISOFOLDER\sources'
$install=Join-Path $src 'install.wim'
$boot=Join-Path $src 'boot.wim'
$destination=Join-Path $root 'BlueLite_FinalImages'
$logs=Join-Path $root 'BlueLite_Logs'
Need ($root -match '\\BlueLite_Stage_v11_3_26300_9818_6c7bf258_[a-f0-9]{8}$') 'STAGE_ID'
Need (Test-Path -LiteralPath $install -PathType Leaf) 'INSTALL_WIM'
Need (Test-Path -LiteralPath $boot -PathType Leaf) 'SETUP_BOOT_WIM'
Need (-not (Test-Path -LiteralPath $destination)) 'FINAL_IMAGES_ALREADY_PRESENT'
Need (Test-Path -LiteralPath $logs -PathType Container) 'STAGE_LOG_DIRECTORY'
$wimlib=Join-Path $root 'bin\wimlib-imagex.exe'
Need (Test-Path -LiteralPath $wimlib -PathType Leaf) 'WIMLIB_MISSING'
& $wimlib info $install 1 | Out-Null
Need ($LASTEXITCODE -eq 0) 'WIM_INDEX1_INVALID'
& $wimlib info $boot 1 | Out-Null
Need ($LASTEXITCODE -eq 0) 'BOOT_WIM_INVALID'
$size=(Get-Item -LiteralPath $install).Length+(Get-Item -LiteralPath $boot).Length
$drive=New-Object System.IO.DriveInfo($root.Substring(0,3))
Need ($drive.AvailableFreeSpace -gt ($size+2GB)) 'INSUFFICIENT_CAPTURE_SPACE'
[IO.Directory]::CreateDirectory($destination) | Out-Null
$destInstall=Join-Path $destination 'install.wim'
$destBoot=Join-Path $destination 'boot.wim'
Copy-Item -LiteralPath $install -Destination $destInstall -ErrorAction Stop
Copy-Item -LiteralPath $boot -Destination $destBoot -ErrorAction Stop
$installHash=Hash $install;$bootHash=Hash $boot
Need ((Hash $destInstall) -eq $installHash) 'INSTALL_COPY_SHA'
Need ((Hash $destBoot) -eq $bootHash) 'BOOT_COPY_SHA'
$stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')
$record=[ordered]@{schema='BlueLite.R027.ImageCapture.v1';utc=[DateTime]::UtcNow.ToString('o');status='CAPTURED_SHA_PASS';stage=$root;install_wim=$destInstall;install_wim_bytes=(Get-Item $destInstall).Length;install_wim_sha256=$installHash;setup_boot_wim=$destBoot;boot_wim_bytes=(Get-Item $destBoot).Length;boot_wim_sha256=$bootHash;release_certified=$false;one_next='ORIGINAL_ISO_CONVERTER'}
Save (Join-Path $logs ('R027_Capture_'+$stamp+'.json')) $record
Write-Host 'R027_FINAL_WIM_AND_SETUP_BOOT_CAPTURE_SHA_PASS'
exit 0
