# BlueLite R20R2F4: 26300.9807 native WebView FOD registration delta, READONLY.
# Paste the entire & { ... } block in PowerShell 7 Administrator. No downloads.
& {
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if ($PSVersionTable.PSVersion.Major -ne 7) { throw 'BL_F4_PS7_REQUIRED' }
$admin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'BL_F4_ADMIN_REQUIRED' }
$wim = 'C:\work\26300.9807-UUP\install.wim'
$srcSha = '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
$txt = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F3.txt'
$json = 'C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20R2F3.json'
$report = 'C:\work\logs\BlueLite_26300_9807_WebViewNativeDelta_R20R2F4.txt'
$mount = 'C:\BLR20R2F4RO'
$dism = Join-Path $env:WINDIR 'System32\dism.exe'
foreach ($p in @($report,$mount)) {
    if (Test-Path -LiteralPath $p) { throw ('BL_F4_OUTPUT_OR_MOUNT_ALREADY_EXISTS=' + $p) }
}
foreach ($i in @(
    @{Path=$txt; Bytes=6667; SHA='A4B3C5FDD83B7D3B0677DDF98CE080E397CD8F304731D3249853233708503A21'},
    @{Path=$json; Bytes=3472; SHA='62575ED0F012228D36D2E8CB86E9B196552F44298F40280AF24A01E13A3E547C'}
)) {
    $f = Get-Item -LiteralPath $i.Path -ErrorAction Stop
    if ($f.PSIsContainer -or $f.Length -ne $i.Bytes -or
        ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
        (Get-FileHash -LiteralPath $i.Path -Algorithm SHA256).Hash -cne $i.SHA) {
        throw ('BL_F4_ORIGINAL_EVIDENCE_NOT_PINNED=' + $i.Path)
    }
}
$receipt = Get-Content -LiteralPath $json -Raw | ConvertFrom-Json -ErrorAction Stop
$prior = Get-Content -LiteralPath $txt -Raw
if ($prior -notmatch 'RESULT=PASS_R20R2_NATIVE_26300_9807_HIGH_IMPACT_PREFLIGHT_READONLY_ONLY' -or
    $receipt.SourceSha256 -cne $srcSha -or $receipt.SourceBytes -ne 7021953581 -or
    $receipt.CapabilityStates.'Edge.Webview2.Platform~~~~' -cne 'INSTALLED' -or
    $receipt.CBSCheckHealth -cne 'CLEAN' -or $receipt.PendingPackageStateRows -ne 0 -or
    $receipt.MutationAllowed -ne $false -or $receipt.ReleaseCertified -ne $false) {
    throw 'BL_F4_PRIOR_NATIVE_RECEIPT_MISMATCH'
}
$src = Get-Item -LiteralPath $wim -ErrorAction Stop
if ($src.PSIsContainer -or $src.Length -ne 7021953581 -or
    ($src.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
    (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $srcSha) { throw 'BL_F4_SOURCE_PRE_PIN_HOLD' }
if (-not (Test-Path -LiteralPath $dism -PathType Leaf)) { throw 'BL_F4_DISM_MISSING' }
$enc = [Text.UTF8Encoding]::new($false)
$fs = [IO.File]::Open($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
$fs.Dispose()
function Log([string]$line) {
    Write-Host $line
    [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$enc)
}
function Native([string]$label,[string[]]$arguments) {
    $output = @(& $dism @arguments 2>&1 | ForEach-Object { [string]$_ })
    $code = [int]$LASTEXITCODE
    $body = $output -join [Environment]::NewLine
    Log ('NATIVE_' + $label + '_EXIT=' + $code)
    if ($code -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.') {
        Log ('NATIVE_' + $label + '_OUTPUT=' + (($output | Select-Object -Last 12) -join ' || '))
        throw ('BL_F4_NATIVE_' + $label + '_HOLD')
    }
    return [pscustomobject]@{Exit=$code; Body=$body}
}
function TableEmpty([string]$label) {
    foreach ($opt in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
        $kind = if ($opt -eq '/Get-MountedWimInfo') { 'WIM' } else { 'IMAGE' }
        $r = Native ($label + '_' + $kind) @('/English',$opt)
        $lines = @($r.Body -split '\r\n|\n|\r')
        if (@($lines | Where-Object { $_.Trim() -ceq 'No mounted images found.' }).Count -ne 1 -or
            @($lines | Where-Object { $_ -match '(?i)^\s*(Mount Dir|Image File|Image Index)\s*:' }).Count -ne 0) {
            throw ('BL_F4_NONEMPTY_OR_UNKNOWN_MOUNT_TABLE_' + $label + '_' + $kind)
        }
        Log ('ZERO_MOUNTS_' + $label + '_' + $kind + '=PASS')
    }
}
function ParsePackages([string]$body) {
    $out = [Collections.Generic.List[object]]::new()
    $id = $null
    $state = $null
    $selected = $false
    foreach ($line in ($body -split '\r\n|\n|\r')) {
        if ($line -match '^\s*Package Identity\s*:\s*(\S+)\s*$') {
            if ($selected) {
                if ($null -eq $state) { throw ('BL_F4_STATE_MISSING=' + $id) }
                [void]$out.Add([pscustomobject]@{Identity=$id;State=$state})
            }
            $id = $Matches[1]
            $selected = $id -match '^(?i:Microsoft-Edge-WebView-FOD-Package(?:-Wrapper)?|Microsoft-OneCore-Edge-WebRuntime-Package|Microsoft-Windows-MicrosoftEdgeDevToolsClient-Package)~'
            $state = $null
        } elseif ($selected -and $line -match '^\s*State\s*:\s*([^\r\n]+?)\s*$') {
            $state = $Matches[1].Trim()
            if ($state -notin @('Installed','Staged','Superseded','Install Pending','Uninstall Pending')) {
                throw ('BL_F4_UNKNOWN_PACKAGE_STATE=' + $id + ':' + $state)
            }
        }
    }
    if ($selected) {
        if ($null -eq $state) { throw ('BL_F4_STATE_MISSING=' + $id) }
        [void]$out.Add([pscustomobject]@{Identity=$id;State=$state})
    }
    return @($out.ToArray())
}
# CRLF/LF positive/negative parsers; do not accept unknown CBS state.
foreach ($nl in @(([string][char]13+[string][char]10),([string][char]10))) {
    $fixture = 'Package Identity : Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1' + $nl + 'State : Staged' + $nl
    $parsed = @(ParsePackages $fixture)
    if ($parsed.Count -ne 1 -or $parsed[0].State -cne 'Staged') { throw 'BL_F4_PACKAGE_PARSE_FIXTURE' }
}
$bad = 'Package Identity : Microsoft-Edge-WebView-FOD-Package~x' + [Environment]::NewLine + 'State : Unknown'
try { $null = ParsePackages $bad; throw 'BL_F4_NEGATIVE_FIXTURE_NOT_REJECTED' }
catch { if ($_.Exception.Message -eq 'BL_F4_NEGATIVE_FIXTURE_NOT_REJECTED') { throw } }
$attempt = $false
$mounted = $false
$completed = $false
$cleaned = $false
try {
    Log 'BLUELITE_R20R2F4_WEBVIEW_REGISTERED_CBS_PACKAGE_DELTA_NATIVE_READONLY'
    Log ('SOURCE=' + $wim + ';INDEX=1;BYTES=7021953581;SHA256=' + $srcSha)
    Log 'F3_ORIGINAL_TXT_JSON_SHA=PASS;F4_PARSER_FIXTURES=PASS'
    TableEmpty 'PRE'
    [void][IO.Directory]::CreateDirectory($mount)
    $attempt = $true
    $null = Native 'MOUNT_READONLY' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
    $mounted = $true
    $cap = Native 'EXACT_WEBVIEW_CAPABILITY' @('/English',('/Image:'+$mount),'/Get-CapabilityInfo','/CapabilityName:Edge.Webview2.Platform~~~~')
    if ($cap.Body -notmatch '(?im)^\s*Capability Identity\s*:\s*Edge\.Webview2\.Platform~~~~\s*\r?$' -or
        $cap.Body -notmatch '(?im)^\s*State\s*:\s*Installed\s*\r?$') {
        throw 'BL_F4_CAPABILITY_NATIVE_SHAPE_HOLD'
    }
    Log 'CAPABILITY=Edge.Webview2.Platform~~~~;STATE=INSTALLED;NATIVE=PASS'
    $pkg = Native 'GET_PACKAGES_LIST' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
    $found = @(ParsePackages $pkg.Body)
    if ($found.Count -eq 0 -or $found.Count -gt 24) { throw 'BL_F4_WEBVIEW_REGISTERED_SET_EMPTY_OR_OVERLIMIT' }
    $fod = @($found | Where-Object { $_.Identity -match '^Microsoft-Edge-WebView-FOD-Package(?:-Wrapper)?~' })
    if ($fod.Count -eq 0) { throw 'BL_F4_NO_REGISTERED_FOD_WHILE_INSTALLED_CAPABILITY' }
    foreach ($entry in $found) {
        Log ('REGISTERED_PACKAGE=' + $entry.Identity + ';STATE=' + $entry.State)
    }
    Log ('WEBVIEW_REGISTERED_TOTAL=' + $found.Count + ';FOD_REGISTERED=' + $fod.Count + ';FOD_INSTALLED=' + @($fod|Where-Object State -eq 'Installed').Count)
    if (@($found|Where-Object { $_.State -match 'Pending' }).Count -ne 0) { throw 'BL_F4_TARGET_PACKAGE_PENDING_HOLD' }
    Log 'SCOPE=PACKAGE_REGISTRATION_DELTA_ONLY;NO_OWNER_GRAPH_OR_REMOVAL_CERTIFICATION'
    $completed = $true
} catch {
    Log ('FAIL_CLOSED=' + $_.Exception.Message)
} finally {
    if ($attempt -and -not $mounted) {
        try {
            $probe = @(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object { [string]$_ })
            if ([int]$LASTEXITCODE -eq 0 -and (($probe -join [Environment]::NewLine) -match [regex]::Escape($mount))) {
                $mounted = $true
                Log 'OWNED_PARTIAL_MOUNT_RECOVERED_FROM_NATIVE_TABLE=TRUE'
            }
        } catch { Log ('MOUNT_RECOVERY_HOLD=' + $_.Exception.Message) }
    }
    if ($mounted) {
        try {
            $null = Native 'DISCARD_OWNED_READONLY' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
            $mounted = $false
            Log 'OWNED_RO_DISCARD=PASS'
        } catch { Log ('OWNED_DISCARD_HOLD=' + $_.Exception.Message) }
    }
    if ($attempt -and -not $mounted -and [IO.Directory]::Exists($mount)) {
        try { [IO.Directory]::Delete($mount,$false); Log 'OWNED_EMPTY_MOUNT_REMOVED=PASS' }
        catch { Log ('OWNED_MOUNT_DIR_HOLD=' + $_.Exception.Message) }
    }
    try {
        TableEmpty 'POST'
        if ((Get-Item -LiteralPath $wim -ErrorAction Stop).Length -ne 7021953581 -or
            (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $srcSha) {
            throw 'BL_F4_SOURCE_POST_SHA_HOLD'
        }
        Log 'ORIGINAL_WIM_POST_SHA=PASS'
        if ($attempt -and [IO.Directory]::Exists($mount)) { throw 'BL_F4_MOUNT_DIR_REMAINS' }
        $cleaned = $true
    } catch { Log ('CLOSEOUT_HOLD=' + $_.Exception.Message) }
    if ($completed -and $cleaned) { Log 'RESULT=PASS_R20R2F4_NATIVE_REGISTERED_WEBVIEW_DELTA_READONLY' }
    else { Log 'RESULT=HOLD_R20R2F4_NATIVE_REGISTERED_WEBVIEW_DELTA' }
    Log 'NO_WIM_MUTATION_NO_CBS_REMOVAL_NO_ISO_NO_RELEASE;JSON_NOT_EXPECTED'
}
}
