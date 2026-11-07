# BlueLite R028 — hardlink final install.wim + setup boot.wim BEFORE converter ISOFOLDER cleanup.
# Never edits original vendor archive, OS volume or Windows installation.
[CmdletBinding()]
param([string]$StageRoot='.')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
function NeedBL([bool]$v,[string]$why){if(-not $v){throw ('R028_CAPTURE_HOLD_'+$why)}}
function HashBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
$stage=[IO.Path]::GetFullPath($StageRoot).TrimEnd([char]'\')
$src=Join-Path $stage 'ISOFOLDER\sources'
$install=Join-Path $src 'install.wim'
$boot=Join-Path $src 'boot.wim'
$out=Join-Path $stage 'BlueLite_R028_Outputs'
$work=[IO.Directory]::GetParent($stage)
$root=if($null -ne $work){[IO.Directory]::GetParent($work.FullName)}else{$null}
NeedBL ($stage.StartsWith('C:\work\',[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $stage -Leaf) -match '^BlueLite_Stage_v11_3_26300_\d+_[a-f0-9]{8}_[a-f0-9]{8}$') 'STAGE_NAME'
NeedBL ($null -ne $root -and $work.Name -eq 'BlueLite_Work') 'STAGE_PARENT'
$logs=Join-Path $root.FullName 'BlueLite_Logs'
NeedBL (Test-Path -LiteralPath $logs -PathType Container) 'LOGS_NOT_IN_SELECTED_UUP_ROOT'
NeedBL (Test-Path -LiteralPath $install -PathType Leaf) 'INSTALL_MISSING'
NeedBL (Test-Path -LiteralPath $boot -PathType Leaf) 'SETUP_BOOT_MISSING'
NeedBL (-not(Test-Path -LiteralPath $out)) 'OUTPUT_DIR_ALREADY_USED'
$exe=Join-Path $stage 'bin\wimlib-imagex.exe'
NeedBL (Test-Path -LiteralPath $exe -PathType Leaf) 'WIMLIB_MISSING'
& $exe info $install 1 *> $null; NeedBL ($LASTEXITCODE -eq 0) 'INSTALL_INDEX_NOT_VALID'
& $exe info $boot 1 *> $null; NeedBL ($LASTEXITCODE -eq 0) 'BOOT_INDEX_NOT_VALID'
$dirResult=@(& $exe dir $install 1 '--path=/Windows/System32/Recovery' 2>&1 | ForEach-Object { $_.ToString() })
NeedBL ($LASTEXITCODE -eq 0) 'RECOVERY_PATH_QUERY_FAILED'
NeedBL ((@($dirResult | Where-Object {$_ -match '(?i)\\Winre\.wim(\s|$)'})).Count -eq 0) 'INSTALLED_WINRE_PRESENT'
[void][IO.Directory]::CreateDirectory($out)
$destInstall=Join-Path $out 'install.wim';$destBoot=Join-Path $out 'boot.wim'
try {
 New-Item -ItemType HardLink -Path $destInstall -Target $install -ErrorAction Stop|Out-Null
 New-Item -ItemType HardLink -Path $destBoot -Target $boot -ErrorAction Stop|Out-Null
} catch {throw ('NTFS_HARDLINK_REQUIRED_NO_FALLBACK_COPY '+$_.Exception.Message)}
$ih=HashBL $install;$bh=HashBL $boot
NeedBL ((HashBL $destInstall) -eq $ih -and (HashBL $destBoot) -eq $bh) 'HARDLINK_SHA_VERIFY_FAILED'
$stamp=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$rec=Join-Path $logs ('BlueLite_R028_Capture_'+$stamp+'.json')
$obj=[ordered]@{schema='BlueLite.R028.Capture.v1';utc=[DateTime]::UtcNow.ToString('o');status='WIM_BOOT_CAPTURE_HARDLINK_SHA_PASS';stage=$stage;install_wim=$destInstall;install_bytes=(Get-Item $destInstall).Length;install_sha256=$ih;setup_boot_wim=$destBoot;boot_bytes=(Get-Item $destBoot).Length;boot_sha256=$bh;install_winre_wim_absent=$true;setup_winpe_retained=$true;release_certified=$false;one_next='CREATE_NATIVE_ISO'}
$raw=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$f=[IO.File]::Open($rec,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($raw,0,$raw.Length)}finally{$f.Dispose()}
Write-Host ('R028_CAPTURE_HARDLINK_SHA_PASS '+$rec)
exit 0
