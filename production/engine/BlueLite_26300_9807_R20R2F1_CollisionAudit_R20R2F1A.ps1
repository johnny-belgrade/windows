# BlueLite 26300.9807 / R20R2F1A: collision and native mount table audit only.
# Standalone PS7 Admin. No script download, mount/unmount, deletion or WIM mutation.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'BL_R20R2F1A_PS7_REQUIRED' }
$principal = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'BL_R20R2F1A_ADMIN_REQUIRED'
}
$logdir = 'C:\work\logs'
$report = Join-Path $logdir 'BlueLite_26300_9807_R20R2F1_CollisionAudit_R20R2F1A.txt'
if (-not (Test-Path -LiteralPath $logdir -PathType Container)) {
    throw 'BL_R20R2F1A_LOG_DIRECTORY_MISSING'
}
if ((Get-Item -LiteralPath $logdir).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'BL_R20R2F1A_LOG_DIRECTORY_REPARSE'
}
if (Test-Path -LiteralPath $report) { throw 'BL_R20R2F1A_REPORT_NO_OVERWRITE' }
$dism = Join-Path $env:WINDIR 'System32\dism.exe'
if (-not [IO.File]::Exists($dism)) { throw 'BL_R20R2F1A_NATIVE_DISM_MISSING' }

$lines = [Collections.Generic.List[string]]::new()
function Add-Record([string]$line) {
    [void]$script:lines.Add($line)
    Write-Host $line
}
Add-Record 'BLUELITE_R20R2F1A_COLLISION_AND_NATIVE_MOUNT_AUDIT'
Add-Record 'MODE=READONLY;NO_MOUNT_NO_UNMOUNT_NO_CLEANUP_NO_NETWORK'
Add-Record 'PREVIOUS_GUARD=BL_R20R2F1_NO_OVERWRITE_OR_MOUNT_ALREADY_EXISTS'

# These four objects form the exact OR condition that rejected the previous command.
$objects = [ordered]@{
    F1_SCRIPT      = 'C:\work\scripts\BlueLite.MaxPre.NativeSourcePreflight.R20R2F1.ps1'
    R20R2_TXT      = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2.txt'
    R20R2_JSON     = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2.json'
    OWNED_MOUNT    = 'C:\BLR20R2RO'
    ORIGINAL_R20R2 = 'C:\work\scripts\BlueLite.MaxPre.NativeSourcePreflight.R20R2.ps1'
    SOURCE_WIM     = 'C:\work\26300.9807-UUP\install.wim'
}
$guardExists = 0
foreach ($key in $objects.Keys) {
    $path = [string]$objects[$key]
    $found = Test-Path -LiteralPath $path
    if ($found -and $key -in @('F1_SCRIPT','R20R2_TXT','R20R2_JSON','OWNED_MOUNT')) {
        $guardExists++
    }
    Add-Record ('OBJECT=' + $key + ';EXISTS=' + $found + ';PATH=' + $path)
    if (-not $found) { continue }
    try {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        $kind = if ($item.PSIsContainer) { 'DIRECTORY' } else { 'FILE' }
        $reparse = (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
        $length = if ($kind -eq 'FILE') { [string]$item.Length } else { 'N/A' }
        Add-Record ('OBJECT_DETAILS=' + $key + ';TYPE=' + $kind + ';BYTES=' + $length + ';REPARSE=' + $reparse)
        if ($kind -eq 'FILE' -and -not $reparse -and $key -in @('F1_SCRIPT','ORIGINAL_R20R2','R20R2_TXT','R20R2_JSON')) {
            if ($item.Length -le 67108864) {
                $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
                Add-Record ('OBJECT_SHA256=' + $key + ';HASH=' + $sha)
                if ($key -eq 'F1_SCRIPT') {
                    Add-Record ('F1_EXPECTED_SHA256_MATCH=' +
                        ($sha -ceq '88F03C07A7EE8F000C77BBD464D448E6B57001C5A49004984F0C0C6728D2C919'))
                }
            }
            else { Add-Record ('OBJECT_SHA256=' + $key + ';SKIPPED_LARGE_FILE') }
        }
    }
    catch { Add-Record ('OBJECT_PROBE_HOLD=' + $key + ';ERROR=' + $_.Exception.Message) }
}
Add-Record ('PREVIOUS_OR_GUARD_EXISTING_OBJECT_COUNT=' + $guardExists)

$nativeOK = $true
foreach ($option in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
    Add-Record ('NATIVE_BEGIN=' + $option)
    try {
        $out = @(& $dism /English $option 2>&1 | ForEach-Object { [string]$_ })
        $exit = [int]$LASTEXITCODE
        foreach ($row in $out) { Add-Record ('NATIVE_RAW=' + $option + '|' + $row) }
        $mountRows = @($out | Where-Object { $_ -match '(?i)^\s*Mount Dir\s*:' }).Count
        $emptyRows = @($out | Where-Object { $_.Trim() -ceq 'No mounted images found.' }).Count
        Add-Record ('NATIVE_EXIT=' + $option + '=' + $exit)
        Add-Record ('MOUNT_DIR_ROWS=' + $option + '=' + $mountRows)
        Add-Record ('EMPTY_MESSAGE_ROWS=' + $option + '=' + $emptyRows)
        if ($exit -ne 0) { $nativeOK = $false }
    }
    catch {
        $nativeOK = $false
        Add-Record ('NATIVE_HOLD=' + $option + ';ERROR=' + $_.Exception.Message)
    }
    Add-Record ('NATIVE_END=' + $option)
}
if ($nativeOK) {
    Add-Record 'RESULT=PASS_R20R2F1A_INVENTORY_CAPTURE_ONLY'
} else {
    Add-Record 'RESULT=HOLD_R20R2F1A_NATIVE_TABLE_CAPTURE'
}
Add-Record 'NO_SCRIPT_EXECUTION_NO_WIM_HASH_NO_WIM_MUTATION_NO_MOUNT_NO_UNMOUNT_NO_CLEANUP_NO_ISO'

# CreateNew enforces no-overwrite even if another process creates the output meanwhile.
$stream = [IO.File]::Open($report, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
try {
    $writer = [IO.StreamWriter]::new($stream, [Text.UTF8Encoding]::new($false))
    try {
        foreach ($line in $lines) { $writer.WriteLine($line) }
        $writer.Flush()
    }
    finally { $writer.Dispose() }
}
finally { $stream.Dispose() }
Write-Host ('REPORT_PATH=' + $report)
