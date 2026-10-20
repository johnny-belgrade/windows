& {
    $path = 'C:\work\scripts\BlueLite.MaxPre.WebViewDirectDetails.R20R2F4R1.ps1'
    if (-not (Test-Path -LiteralPath 'C:\work\scripts' -PathType Container)) { throw 'BL_F4R1_SCRIPTS_DIR_MISSING' }
    $source = @'
# BlueLite v1.0 R20R2F4R1 exact native WebView detail receipt, READONLY ONLY.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'BL_F4R1_PS7_REQUIRED' }
$admin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'BL_F4R1_ADMIN_REQUIRED' }
$wim = 'C:\work\26300.9807-UUP\install.wim'
$sha = '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
$prev = 'C:\work\logs\BlueLite_26300_9807_WebViewNativeDelta_R20R2F4.txt'
$report = 'C:\work\logs\BlueLite_26300_9807_WebViewDirectDetails_R20R2F4R1.txt'
$mount = 'C:\BLR20R2F4R1RO'
$dism = Join-Path $env:WINDIR 'System32\dism.exe'
$package = 'Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1'
if (-not [IO.File]::Exists($dism)) { throw 'BL_F4R1_DISM_MISSING' }
if ((Get-Item -LiteralPath $prev -ErrorAction Stop).Length -ne 947 -or
    (Get-FileHash -LiteralPath $prev -Algorithm SHA256).Hash -cne '7E76DBF15717D9711BB4EECDCF312520E421A2591AC05D49EDDA548BF5CBEF3B') {
    throw 'BL_F4R1_PREVIOUS_ORIGINAL_NOT_PINNED'
}
$prevText = [IO.File]::ReadAllText($prev)
foreach ($tag in @('NATIVE_GET_PACKAGES_LIST_EXIT=0','FAIL_CLOSED=BL_F4_WEBVIEW_REGISTERED_SET_EMPTY_OR_OVERLIMIT',
  'OWNED_RO_DISCARD=PASS','ORIGINAL_WIM_POST_SHA=PASS','RESULT=HOLD_R20R2F4_NATIVE_REGISTERED_WEBVIEW_DELTA')) {
    if (-not $prevText.Contains($tag)) { throw 'BL_F4R1_PRIOR_REPORT_SHAPE' }
}
foreach ($p in @($report,$mount)) {
    if (Test-Path -LiteralPath $p) { throw ('BL_F4R1_NO_OVERWRITE_OR_UNKNOWN_MOUNT=' + $p) }
}
function Pin([string]$when) {
    $f = Get-Item -LiteralPath $wim -ErrorAction Stop
    if ($f.PSIsContainer -or $f.Length -ne 7021953581 -or
        ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $sha) {
        throw ('BL_F4R1_ORIGINAL_WIM_DRIFT_' + $when)
    }
    Log ('ORIGINAL_WIM_' + $when + '_SHA=PASS')
}
$encoding = [Text.UTF8Encoding]::new($false)
$handle = [IO.File]::Open($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$handle.Dispose()
function Log([string]$line) {
    Write-Host $line
    [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$encoding)
}
function Native([string]$tag,[string[]]$arguments) {
    $rows = @(& $dism @arguments 2>&1 | ForEach-Object { [string]$_ })
    $code = [int]$LASTEXITCODE
    Log ('NATIVE_' + $tag + '_EXIT=' + $code)
    foreach ($line in $rows) { Log ('RAW_' + $tag + '|' + $line) }
    $body = $rows -join [Environment]::NewLine
    if ($code -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.') {
        throw ('BL_F4R1_NATIVE_' + $tag + '_HOLD_' + $code)
    }
    return $body
}
function EmptyTables([string]$phase) {
    foreach ($op in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
        $kind = if ($op -eq '/Get-MountedWimInfo') {'WIM'} else {'IMAGE'}
        $body = Native ($phase + '_' + $kind) @('/English',$op)
        $lines = @($body -split '\r\n|\n|\r')
        if (@($lines | Where-Object { $_.Trim() -ceq 'No mounted images found.' }).Count -ne 1 -or
            @($lines | Where-Object { $_ -match '(?i)^\s*(Mount Dir|Image File|Image Index)\s*:' }).Count -ne 0) {
            throw ('BL_F4R1_MOUNT_TABLE_NOT_EMPTY_' + $phase + '_' + $kind)
        }
        Log ('ZERO_MOUNTS_' + $phase + '_' + $kind + '=PASS')
    }
}
$attempt = $false; $mounted = $false; $ok = $false; $closed = $false
try {
    Log 'BLUELITE_R20R2F4R1_EXACT_HIDDEN_WEBVIEW_PROVIDER_DETAILS_READONLY'
    Pin 'PRE'
    EmptyTables 'PRE'
    [void][IO.Directory]::CreateDirectory($mount)
    $attempt = $true
    $null = Native 'MOUNT_READONLY' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
    $mounted = $true
    $cap = Native 'WEBVIEW_CAPABILITY_INFO' @('/English',('/Image:'+$mount),'/Get-CapabilityInfo','/CapabilityName:Edge.Webview2.Platform~~~~')
    if ($cap -notmatch '(?im)^[ \t]*Capability Identity[ \t]*:[ \t]*Edge\.Webview2\.Platform~~~~[ \t]*\r?$' -or
        $cap -notmatch '(?im)^[ \t]*State[ \t]*:[ \t]*Installed[ \t]*\r?$') { throw 'BL_F4R1_CAPABILITY_SHAPE_DRIFT' }
    $pkg = Native 'EXACT_FOD_PACKAGE_INFO' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$package))
    if ($pkg -notmatch '(?im)^[ \t]*Package Identity[ \t]*:[ \t]*Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10\.0\.26100\.1[ \t]*\r?$' -or
        $pkg -notmatch '(?im)^[ \t]*State[ \t]*:[ \t]*Staged[ \t]*\r?$') { throw 'BL_F4R1_PACKAGE_SHAPE_DRIFT' }
    Log ('NATIVE_DIRECT_EXACT_CAPABILITY_INSTALLED_FOD_STAGED=PASS;' + $package)
    $ok = $true
} catch {
    Log ('FAIL_CLOSED=' + $_.Exception.Message)
} finally {
    if ($attempt -and -not $mounted) {
        try {
            $rows = @(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object { [string]$_ })
            if ([int]$LASTEXITCODE -eq 0 -and (($rows -join [Environment]::NewLine).Contains($mount))) {
                $mounted = $true; Log 'RECOVER_OWNED_MOUNT_FROM_NATIVE_TABLE=TRUE'
            }
        } catch { Log ('RECOVERY_HOLD=' + $_.Exception.Message) }
    }
    if ($mounted) {
        try {
            $null = Native 'DISCARD_OWNED_READONLY' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
            $mounted = $false
            Log 'OWNED_READONLY_DISCARD=PASS'
        } catch { Log ('DISCARD_HOLD=' + $_.Exception.Message) }
    }
    if ($attempt -and -not $mounted -and [IO.Directory]::Exists($mount)) {
        try { [IO.Directory]::Delete($mount,$false); Log 'OWNED_MOUNT_FOLDER_REMOVED=PASS' }
        catch { Log ('MOUNT_FOLDER_HOLD=' + $_.Exception.Message) }
    }
    try {
        EmptyTables 'POST'
        Pin 'POST'
        if ($attempt -and [IO.Directory]::Exists($mount)) { throw 'BL_F4R1_MOUNT_REMAINS' }
        $closed = $true
    } catch { Log ('CLOSEOUT_HOLD=' + $_.Exception.Message) }
    if ($ok -and $closed) { Log 'RESULT=PASS_R20R2F4R1_NATIVE_DIRECT_WEBVIEW_DETAILS_READONLY' }
    else { Log 'RESULT=HOLD_R20R2F4R1_NATIVE_DIRECT_WEBVIEW_DETAILS_READONLY' }
    Log 'NO_WIM_MUTATION_NO_REMOVAL_NO_ISO_NO_RELEASE;JSON_NOT_EXPECTED'
}
'@
    $source = (($source -replace "`r`n|`r|`n", "`n").TrimEnd([char]10)) + "`n"
    $encoding = [Text.UTF8Encoding]::new($false)
    $bytes = $encoding.GetBytes($source)
    if ($bytes.Length -ne 6375) { throw 'BL_F4R1_CLIPBOARD_LENGTH_MISMATCH' }
    if (-not (Test-Path -LiteralPath $path)) {
        $stream = [IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try { $stream.Write($bytes,0,$bytes.Length) } finally { $stream.Dispose() }
    }
    if ((Get-Item -LiteralPath $path -ErrorAction Stop).Length -ne 6375 -or
        (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne '04DAA5E4057EADC4DA4170FB48F523075847D3021EC27959067C8BC0B309E678') {
        throw 'BL_F4R1_LOCAL_PS1_SHA_MISMATCH'
    }
    $tokens = $null; $errors = $null
    $null = [Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    if (@($errors).Count -gt 0) { throw ('BL_F4R1_PS7_AST_INVALID: ' + $errors[0].Message) }
    & $path
}
