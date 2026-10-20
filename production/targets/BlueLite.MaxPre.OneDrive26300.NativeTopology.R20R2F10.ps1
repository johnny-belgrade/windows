# BlueLite v1.0 R20R2F10 | 26300.9807 OneDrive + Search exact native topology
# READONLY ONLY. Target = retained WebViewRemoved MAX WIM. No clone/removal/registry load.
& {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    if ($PSVersionTable.PSVersion.Major -ne 7 -or [IntPtr]::Size -ne 8) { throw 'BL_F10_PS7_X64_REQUIRED' }
    $admin = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'BL_F10_ADMIN_REQUIRED' }
    $source = 'C:\work\26300.9807-UUP\install.wim'
    $candidate = 'C:\BLR20R2F5\R20R2F6_exports\WebViewRemoved_26300_9807_MAX.wim'
    $f9 = 'C:\work\logs\BlueLite_26300_9807_WebViewPostCommitNative_R20R2F9.txt'
    $report = 'C:\work\logs\BlueLite_26300_9807_OneDriveExactTopology_R20R2F10.txt'
    $parent = 'C:\BLR20R2F10'
    $mount = 'C:\BLR20R2F10\mount'
    $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
    $reg = Join-Path $env:SystemRoot 'System32\reg.exe'
    if (-not [IO.Directory]::Exists('C:\work\logs') -or [IO.File]::Exists($report) -or
        [IO.Directory]::Exists($parent) -or [IO.File]::Exists($parent)) {
        throw 'BL_F10_REPORT_OR_MOUNT_ALREADY_EXISTS_OR_LOG_DIR_MISSING'
    }
    $expected = @(
        [pscustomobject]@{Role='ONEDRIVE_NEUTRAL';Id='Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1';State='Staged'},
        [pscustomobject]@{Role='ONEDRIVE_EN_US';Id='Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1';State='Installed'},
        [pscustomobject]@{Role='SEARCH_BASE_NEUTRAL';Id='Microsoft-Windows-SearchEngine-Client-Package-base-Package~31bf3856ad364e35~amd64~~10.0.26100.1';State='Installed'},
        [pscustomobject]@{Role='SEARCH_BASE_EN_US';Id='Microsoft-Windows-SearchEngine-Client-Package-base-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1';State='Installed'},
        [pscustomobject]@{Role='SEARCH_ONECORE_NEUTRAL';Id='Microsoft-Windows-SearchEngine-Client-Package-onecoreuap-Package~31bf3856ad364e35~amd64~~10.0.26100.1591';State='Staged'},
        [pscustomobject]@{Role='SEARCH_ONECORE_EN_US';Id='Microsoft-Windows-SearchEngine-Client-Package-onecoreuap-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1';State='Installed'},
        [pscustomobject]@{Role='SEARCH_SHELL_NEUTRAL';Id='Microsoft-Windows-SearchEngine-Client-Package-shell-Package~31bf3856ad364e35~amd64~~10.0.26100.1591';State='Staged'},
        [pscustomobject]@{Role='SEARCH_SHELL_EN_US';Id='Microsoft-Windows-SearchEngine-Client-Package-shell-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1591';State='Staged'},
        [pscustomobject]@{Role='SEARCH_MAIN_NEUTRAL';Id='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1591';State='Staged'},
        [pscustomobject]@{Role='SEARCH_MAIN_EN_US';Id='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1591';State='Staged'}
    )
    $writer = $null
    $created = $false
    $attempted = $false
    $needsDiscard = $false
    $auditPass = $false
    $closePass = $true
    function Note([string]$message) {
        Write-Host $message
        if ($null -ne $writer) { $writer.WriteLine($message); $writer.Flush() }
    }
    function Pin([string]$role,[string]$path,[long]$bytes,[string]$sha) {
        $f = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        if ($f.PSIsContainer -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $f.Length -ne $bytes) {
            throw "BL_F10_PIN_SIZE_OR_TYPE_DRIFT=$role"
        }
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha) { throw "BL_F10_PIN_SHA_DRIFT=$role" }
        Note "PIN_$role=PASS;BYTES=$bytes;SHA256=$sha"
    }
    function DismOk([string]$label,[string[]]$argsNative) {
        $raw = @(& $dism @argsNative 2>&1 | ForEach-Object { [string]$_ })
        $exit = [int]$LASTEXITCODE
        $text = $raw -join "`n"
        Note "DISM_$label`_EXIT=$exit;LINES=$($raw.Count)"
        if ($exit -ne 0 -or $text -match '(?im)^\s*Error\s*:' -or
            $text -notmatch '(?i)The operation completed successfully\.') {
            foreach ($line in $raw) { Note "NATIVE_$label=$line" }
            throw "BL_F10_NATIVE_Dism_$label`_HOLD_EXIT_$exit"
        }
        return $text
    }
    function ZeroMounts([string]$when) {
        foreach ($option in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
            $raw = @(& $dism /English $option 2>&1 | ForEach-Object { [string]$_ })
            $rc = [int]$LASTEXITCODE
            $text = $raw -join "`n"
            if ($rc -ne 0 -or $text -notmatch '(?im)^\s*No mounted images found\.\s*$' -or
                $text -match '(?im)^\s*Mount Dir\s*:') {
                foreach ($line in $raw) { Note "MOUNTS_$when`_RAW=$line" }
                throw "BL_F10_NONEMPTY_OR_UNRECOGNIZED_MOUNT_TABLE=$when;$option;EXIT=$rc"
            }
            Note "MOUNTS_$when`:$option=EMPTY;EXIT=0"
        }
    }
    function HiveRoots([string]$when) {
        $raw = @(& $reg query HKLM /reg:64 2>&1 | ForEach-Object { [string]$_ })
        if ($LASTEXITCODE -ne 0) { throw "BL_F10_HKLM_QUERY_NATIVE_EXIT=$LASTEXITCODE" }
        $allowed = @('BCD00000000','COMPONENTS','DRIVERS','HARDWARE','SAM','SECURITY','SOFTWARE','SYSTEM')
        $roots = [System.Collections.Generic.List[string]]::new()
        foreach ($line in $raw) {
            $s = $line.Trim()
            if ($s.StartsWith('HKEY_LOCAL_MACHINE\',[StringComparison]::OrdinalIgnoreCase)) {
                $m = [regex]::Match($s,'^HKEY_LOCAL_MACHINE\\([A-Za-z0-9_]+)$','IgnoreCase')
                if (-not $m.Success -or $allowed -notcontains $m.Groups[1].Value) { throw "BL_F10_UNKNOWN_HKLM_ALIAS=$s" }
                $roots.Add($m.Groups[1].Value)
            }
        }
        if (-not $roots.Contains('SOFTWARE') -or -not $roots.Contains('SYSTEM')) { throw 'BL_F10_HKLM_REQUIRED_ROOTS_MISSING' }
        Note "HKLM_$when=EXPECTED_ONLY;COUNT=$($roots.Count);NATIVE_EXIT=0"
    }
    try {
        $stream = [IO.FileStream]::new($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $writer = [IO.StreamWriter]::new($stream,[Text.UTF8Encoding]::new($false))
        $writer.AutoFlush = $true
        Note 'BLUELITE_R20R2F10_ONEDRIVE_AND_SEARCH_NATIVE_EXACT_TOPOLOGY_26300_9807'
        Note 'READONLY_ONLY;NO_WIM_CLONE;NO_REMOVE;NO_REGISTRY_LOAD;NO_RELEASE'
        Pin 'R20R2F9_OPERATOR_REPORT' $f9 2662 '4BC8725A04900ECD3238E8C759DA6FAFA116912E7E03EE561B923AA5BFAE8633'
        if (-not [IO.File]::ReadAllText($f9).Contains('RESULT=PASS_R20R2F9_WEBVIEW_9807_INDEPENDENT_READONLY_POSTCOMMIT_SCOPE_ONLY')) {
            throw 'BL_F10_R9_RESULT_MISSING'
        }
        Pin 'IMMUTABLE_ORIGINAL' $source 7021953581 '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
        Pin 'REMOVED_MAX' $candidate 6407308664 'F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'
        ZeroMounts 'PRE'
        HiveRoots 'PRE'
        if ((Get-PSDrive C).Free -lt 8589934592L) { throw 'BL_F10_LESS_THAN_8GIB_FREE' }
        [void][IO.Directory]::CreateDirectory($mount)
        $created = $true
        $attempted = $true
        $null = DismOk 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$candidate),'/Index:1',('/MountDir:'+$mount),'/ReadOnly','/CheckIntegrity')
        $needsDiscard = $true
        if (-not [IO.File]::Exists((Join-Path $mount 'Windows\System32\Config\SOFTWARE'))) { throw 'BL_F10_DISM_HELP_OR_WRONG_MOUNT_WITNESS' }
        Note 'MOUNTED_WINDOWS_STRUCTURE=PASS;READONLY=TRUE'
        foreach ($item in $expected) {
            $text = DismOk $item.Role @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$item.Id))
            $idMatch = [regex]::Match($text,'(?im)^\s*Package Identity\s*:\s*(.*?)\s*$')
            $stateMatch = [regex]::Match($text,'(?im)^\s*State\s*:\s*(.*?)\s*$')
            if (-not $idMatch.Success -or $idMatch.Groups[1].Value -cne $item.Id -or
                -not $stateMatch.Success -or $stateMatch.Groups[1].Value -cne $item.State) {
                throw "BL_F10_EXACT_IDENTITY_OR_STATE_DRIFT=$($item.Role);ACTUAL=$($stateMatch.Groups[1].Value)"
            }
            Note "PACKAGE=$($item.Role);IDENTITY=$($item.Id);STATE=$($item.State);NATIVE_EXIT=0"
        }
        Note 'ONEDRIVE_2_NATIVE_EXACT_STATES=PASS;SEARCH_8_SIBLINGS_NATIVE_EXACT_STATES=PASS'
        foreach ($rel in @('Windows\System32\OneDriveSetup.exe','Windows\SysWOW64\OneDriveSetup.exe')) {
            $file = Join-Path $mount $rel
            if ([IO.File]::Exists($file)) {
                $info = Get-Item -LiteralPath $file -Force -ErrorAction Stop
                Note "ONEDRIVE_SETUP_PAYLOAD=$rel;PRESENT=True;LOGICAL_BYTES=$($info.Length);REPARSE=$([bool]($info.Attributes -band [IO.FileAttributes]::ReparsePoint))"
            } else { Note "ONEDRIVE_SETUP_PAYLOAD=$rel;PRESENT=False" }
        }
        $dirs = @(Get-ChildItem -LiteralPath (Join-Path $mount 'Windows\WinSxS') -Directory -Force -ErrorAction Stop |
            Where-Object { $_.Name -like '*onedrive*' })
        Note "ONEDRIVE_WINSXS_DIR_COUNT=$($dirs.Count);METADATA_ONLY_NOT_PHYSICAL_SAVINGS"
        foreach ($d in $dirs) { Note "ONEDRIVE_WINSXS_DIR=$($d.Name)" }
        $packages = DismOk 'PACKAGE_LIST_PENDING' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
        $pending = @([regex]::Matches($packages,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$')).Count
        $pendingFile = [IO.File]::Exists((Join-Path $mount 'Windows\WinSxS\pending.xml'))
        Note "CBS_PENDING_COUNT=$pending;PENDING_XML=$pendingFile"
        if ($pending -ne 0 -or $pendingFile) { throw 'BL_F10_CBS_PENDING_HOLD' }
        $health = DismOk 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
        if ($health -notmatch '(?i)No component store corruption detected\.') { throw 'BL_F10_CHECKHEALTH_NOT_CLEAN' }
        Note 'CBS_CHECKHEALTH=CLEAN'
        $auditPass = $true
    } catch {
        Note ('ERROR=' + ($_.Exception.Message -replace '[\r\n]+',' '))
    } finally {
        if ($attempted) {
            try {
                $raw = @(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object { [string]$_ })
                if ($needsDiscard -or (($raw -join "`n").Contains($mount))) {
                    $null = DismOk 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
                    $needsDiscard = $false
                    Note 'OWNED_NATIVE_READONLY_DISCARD=PASS'
                }
                ZeroMounts 'POST'
                HiveRoots 'POST'
            } catch {
                $closePass = $false
                Note ('CRITICAL_CLOSEOUT_HOLD=' + ($_.Exception.Message -replace '[\r\n]+',' '))
            }
        }
        if ($created -and -not $needsDiscard -and $closePass) {
            try {
                if (@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -ne 0) { throw 'OWNED_MOUNT_NOT_EMPTY' }
                [IO.Directory]::Delete($mount,$false)
                [IO.Directory]::Delete($parent,$false)
                Note 'OWNED_EMPTY_MOUNT_AND_PARENT_REMOVED=PASS'
            } catch {
                $closePass = $false
                Note ('CRITICAL_OWNED_DIRECTORY_CLOSEOUT_HOLD=' + $_.Exception.Message)
            }
        }
        foreach ($p in @(
            @{Role='ORIGINAL_POST';Path=$source;Bytes=7021953581L;SHA='0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'},
            @{Role='REMOVED_MAX_POST';Path=$candidate;Bytes=6407308664L;SHA='F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'}
        )) {
            try { Pin $p.Role $p.Path $p.Bytes $p.SHA } catch { $closePass = $false; Note ('CRITICAL_SHA_POST_HOLD=' + $_.Exception.Message) }
        }
        if ($auditPass -and $closePass -and -not $needsDiscard) {
            Note 'RESULT=PASS_R20R2F10_26300_9807_ONEDRIVE_SEARCH_EXACT_NATIVE_TOPOLOGY_READONLY_ONLY'
        } else {
            Note 'RESULT=HOLD_R20R2F10_NATIVE_TOPOLOGY_OR_MOUNT_CLOSEOUT'
        }
        Note 'NO_COMPONENT_REMOVAL_NO_WIM_CLONE_NO_ISO_NO_RELEASE;JSON_NOT_EXPECTED'
        Note "REPORT=$report"
        if ($null -ne $writer) { $writer.Dispose(); $writer = $null }
    }
    if (-not $auditPass -or -not $closePass -or $needsDiscard) { throw 'BL_F10_HOLD_SEND_ORIGINAL_TXT_DO_NOT_RERUN_BLINDLY' }
}
