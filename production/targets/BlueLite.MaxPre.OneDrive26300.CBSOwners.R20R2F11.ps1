# BlueLite v1.0 / 26300.9807 / R20R2F11: native CBS owner/Visibility read-only source-bound probe.
# IMAGE: one owned RO mount, no WIM mutation. REGISTRY: load ONLY a disposable SOFTWARE hive copy.
& {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    if ($PSVersionTable.PSVersion.Major -ne 7 -or [IntPtr]::Size -ne 8) { throw 'BL_F11_PS7_X64_REQUIRED' }
    $identity = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $identity.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'BL_F11_ADMIN_REQUIRED' }
    $original = 'C:\work\26300.9807-UUP\install.wim'
    $candidate = 'C:\BLR20R2F5\R20R2F6_exports\WebViewRemoved_26300_9807_MAX.wim'
    $previous = 'C:\work\logs\BlueLite_26300_9807_OneDriveExactTopology_R20R2F10.txt'
    $report = 'C:\work\logs\BlueLite_26300_9807_OneDriveCBSOwners_R20R2F11.txt'
    $root = 'C:\BLR20R2F11'
    $mount = Join-Path $root 'mount'
    $hive = Join-Path $root 'SOFTWARE.hiv'
    $alias = 'BLR20R2F11_SOFT'
    $reg = Join-Path $env:SystemRoot 'System32\reg.exe'
    $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
    $packages = @(
        'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1',
        'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
    )
    $writer = $null
    $created = $false
    $attempted = $false
    $mounted = $false
    $hiveLoaded = $false
    $pass = $false
    $closePass = $true
    function Say([string]$line) {
        Write-Host $line
        if ($null -ne $writer) { $writer.WriteLine($line); $writer.Flush() }
    }
    function Pin([string]$tag,[string]$path,[long]$bytes,[string]$sha) {
        $item = Get-Item -LiteralPath $path -Force -ErrorAction Stop
        if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $item.Length -ne $bytes) {
            throw "BL_F11_PIN_FILE_TYPE_OR_LENGTH=$tag"
        }
        $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($actual -cne $sha) { throw "BL_F11_PIN_SHA_DRIFT=$tag" }
        Say "PIN_$tag=PASS;BYTES=$bytes;SHA256=$sha"
    }
    function NativeDism([string]$tag,[string[]]$argsList) {
        $raw = @(& $dism @argsList 2>&1 | ForEach-Object { [string]$_ })
        $rc = [int]$LASTEXITCODE
        $body = $raw -join "`n"
        Say "DISM_$tag`_EXIT=$rc;LINES=$($raw.Count)"
        if ($rc -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or $body -notmatch '(?i)The operation completed successfully\.') {
            foreach ($line in $raw) { Say "DISM_${tag}_RAW=$line" }
            throw "BL_F11_NATIVE_DISM_HOLD=$tag"
        }
        return $body
    }
    function EmptyMounts([string]$stage) {
        foreach ($verb in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
            $raw = @(& $dism /English $verb 2>&1 | ForEach-Object { [string]$_ })
            $rc = [int]$LASTEXITCODE
            $body = $raw -join "`n"
            if ($rc -ne 0 -or $body -notmatch '(?im)^\s*No mounted images found\.\s*$' -or $body -match '(?im)^\s*Mount Dir\s*:') {
                foreach ($line in $raw) { Say "MOUNT_${stage}_RAW=$line" }
                throw "BL_F11_NONEMPTY_MOUNT_$stage`:$verb`:$rc"
            }
            Say "MOUNT_$stage`:$verb=EMPTY;EXIT=0"
        }
    }
    function RegistryRoots([string]$stage) {
        $raw = @(& $reg query HKLM /reg:64 2>&1 | ForEach-Object { [string]$_ })
        $rc = [int]$LASTEXITCODE
        if ($rc -ne 0) { throw "BL_F11_REG_ROOT_EXIT=$stage`:$rc" }
        $allowed = @('BCD00000000','COMPONENTS','DRIVERS','HARDWARE','SAM','SECURITY','SOFTWARE','SYSTEM')
        $seen = [System.Collections.Generic.List[string]]::new()
        foreach ($line in $raw) {
            $trim = $line.Trim()
            if ($trim.StartsWith('HKEY_LOCAL_MACHINE\',[StringComparison]::OrdinalIgnoreCase)) {
                $m = [regex]::Match($trim,'^HKEY_LOCAL_MACHINE\\([A-Za-z0-9_]+)$','IgnoreCase')
                if (-not $m.Success -or $allowed -notcontains $m.Groups[1].Value) { throw "BL_F11_UNEXPECTED_HKLM_HIVE=$trim" }
                $seen.Add($m.Groups[1].Value)
            }
        }
        if (-not $seen.Contains('SOFTWARE') -or -not $seen.Contains('SYSTEM')) { throw "BL_F11_BAD_HKLM_ROOTS=$stage" }
        Say "HKLM_$stage=KNOWN_HOST_ROOTS_ONLY;COUNT=$($seen.Count);EXIT=0"
    }
    if (-not [IO.Directory]::Exists('C:\work\logs') -or [IO.File]::Exists($report) -or
        [IO.Directory]::Exists($root) -or [IO.File]::Exists($root)) {
        throw 'BL_F11_REPORT_OR_OWNED_ROOT_EXISTS_NO_OVERWRITE'
    }
    try {
        $file = [IO.FileStream]::new($report,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $writer = [IO.StreamWriter]::new($file,[Text.UTF8Encoding]::new($false))
        $writer.AutoFlush = $true
        Say 'BLUELITE_R20R2F11_26300_9807_ONEDRIVE_CBS_OWNER_REGISTRY_READONLY'
        Say 'SOURCE_WIM_RO;SOFTWARE_HIVE_COPIED;NO_COMPONENT_OR_ORIGINAL_HIVE_MUTATION'
        Pin 'R20R2F10_RECEIPT' $previous 4247 '3F6E43D9F967F5F81B58488A5AA62A836E681AB1584A49F02453A7E8F90A5B8D'
        if (-not [IO.File]::ReadAllText($previous).Contains('RESULT=PASS_R20R2F10_26300_9807_ONEDRIVE_SEARCH_EXACT_NATIVE_TOPOLOGY_READONLY_ONLY')) {
            throw 'BL_F11_PREDECESSOR_RESULT_DRIFT'
        }
        Pin 'IMMUTABLE_ORIGINAL' $original 7021953581 '0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
        Pin 'WEBVIEW_REMOVED_MAX' $candidate 6407308664 'F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'
        EmptyMounts 'PRE'
        RegistryRoots 'PRE'
        if ((Get-PSDrive C).Free -lt 4294967296L) { throw 'BL_F11_LOW_DISK_FREE_BELOW_4GIB' }
        [void][IO.Directory]::CreateDirectory($mount)
        $created = $true
        $attempted = $true
        $null = NativeDism 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$candidate),'/Index:1',('/MountDir:'+$mount),'/ReadOnly','/CheckIntegrity')
        $mounted = $true
        $soft = Join-Path $mount 'Windows\System32\Config\SOFTWARE'
        if (-not [IO.File]::Exists($soft)) { throw 'BL_F11_NO_MOUNTED_SOFTWARE_WITNESS' }
        Say 'MOUNT_WITNESS=OFFLINE_WINDOWS_SOFTWARE_EXISTS;RO_ONLY'
        [IO.File]::Copy($soft,$hive,$false)
        $hiveItem = Get-Item -LiteralPath $hive -Force
        if ($hiveItem.Length -lt 1024) { throw 'BL_F11_COPIED_SOFTWARE_TOO_SMALL' }
        Say "OFFLINE_SOFTWARE_COPIED_ONLY;BYTES=$($hiveItem.Length)"
        $result = @(& $reg load ('HKLM\'+$alias) $hive 2>&1 | ForEach-Object { [string]$_ })
        $rc = [int]$LASTEXITCODE
        Say "REG_LOAD_COPIED_SOFTWARE_NATIVE_EXIT=$rc"
        if ($rc -ne 0) { foreach ($line in $result) { Say "REG_LOAD_RAW=$line" }; throw 'BL_F11_COPIED_HIVE_LOAD_FAILED' }
        $hiveLoaded = $true
        foreach ($id in $packages) {
            $key = 'HKLM\'+$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\'+$id
            $raw = @(& $reg query $key /s 2>&1 | ForEach-Object { [string]$_ })
            $code = [int]$LASTEXITCODE
            Say "CBS_KEY=$id;REG_QUERY_EXIT=$code;RAW_ROWS=$($raw.Count)"
            if ($code -ne 0) {
                foreach ($line in $raw) { Say "CBS_NEGATIVE_RAW=$line" }
                throw "BL_F11_CBS_PACKAGE_ROOT_NOT_RESOLVED=$id"
            }
            $state = @($raw | Where-Object { $_ -match '^\s*CurrentState\s+REG_DWORD\s+' })
            $visibility = @($raw | Where-Object { $_ -match '^\s*Visibility\s+REG_DWORD\s+' })
            $owner = @($raw | Where-Object { $_ -match '(?i)\\Owners(\\|$)|^\s*Owners\s+' })
            foreach ($line in $raw) { Say "CBS_RAW_$id=$line" }
            Say "CBS_FIELDS_$id`=CURRENTSTATE_COUNT=$($state.Count);VISIBILITY_COUNT=$($visibility.Count);OWNER_MARKER_COUNT=$($owner.Count)"
            if ($state.Count -ne 1 -or $visibility.Count -ne 1) { throw "BL_F11_CBS_STATE_OR_VISIBILITY_MISSING=$id" }
        }
        Say 'CBS_TWO_SOURCE_BOUND_KEYS_STATE_VISIBILITY=CAPTURED;OWNERS_UNASSESSED_UNTIL_ORIGINAL_REPORT_REVIEW'
        $pass = $true
    } catch {
        Say ('ERROR=' + ($_.Exception.Message -replace '[\r\n]+',' '))
        $pass = $false
    } finally {
        # A failed reg load can still leave the alias visible; always test by native name.
        if (-not $hiveLoaded -and $attempted) {
            $null = @(& $reg query ('HKLM\'+$alias) 2>&1)
            if ([int]$LASTEXITCODE -eq 0) { $hiveLoaded=$true;Say 'NATIVE_ALIAS_FOUND_AFTER_FAILED_LOAD=REQUIRES_UNLOAD' }
        }
        if ($hiveLoaded) {
            try {
                $raw = @(& $reg unload ('HKLM\'+$alias) 2>&1 | ForEach-Object { [string]$_ })
                $rc = [int]$LASTEXITCODE
                Say "REG_UNLOAD_COPIED_SOFTWARE_NATIVE_EXIT=$rc"
                if ($rc -ne 0) { foreach ($line in $raw) { Say "REG_UNLOAD_RAW=$line" }; throw 'BL_F11_COPIED_HIVE_UNLOAD_HOLD' }
                $hiveLoaded = $false
            } catch { $closePass=$false;Say ('CRITICAL_HIVE_UNLOAD_HOLD='+$_.Exception.Message) }
        }
        if (-not $hiveLoaded -and $created) {
            try {
                RegistryRoots 'AFTER_UNLOAD'
            } catch { $closePass=$false;Say ('CRITICAL_HKLM_CLOSEOUT_HOLD='+$_.Exception.Message) }
        }
        if ($attempted) {
            try {
                $raw = @(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
                if ($mounted -or $raw.Contains($mount)) {
                    $null = NativeDism 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
                    $mounted = $false
                    Say 'OWNED_NATIVE_RO_DISCARD=PASS'
                }
                EmptyMounts 'POST'
            } catch { $closePass=$false;Say ('CRITICAL_DISM_CLOSEOUT_HOLD='+$_.Exception.Message) }
        }
        if ($created -and -not $mounted -and -not $hiveLoaded) {
            try {
                if ([IO.File]::Exists($hive)) { [IO.File]::Delete($hive) }
                if (@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -ne 0) { throw 'OWNED_MOUNT_NOT_EMPTY' }
                [IO.Directory]::Delete($mount,$false)
                [IO.Directory]::Delete($root,$false)
                Say 'OWNED_HIVE_COPY_AND_EMPTY_MOUNT_ROOT_REMOVED=PASS'
            } catch { $closePass=$false;Say ('CRITICAL_OWNED_SCRATCH_CLOSEOUT_HOLD='+$_.Exception.Message) }
        }
        foreach ($pin in @(
            @{Name='IMMUTABLE_ORIGINAL_POST';Path=$original;Bytes=7021953581L;SHA='0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'},
            @{Name='WEBVIEW_REMOVED_MAX_POST';Path=$candidate;Bytes=6407308664L;SHA='F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'}
        )) {
            try { Pin $pin.Name $pin.Path $pin.Bytes $pin.SHA }
            catch { $closePass=$false;Say ('CRITICAL_POST_PIN_HOLD='+$_.Exception.Message) }
        }
        if ($pass -and $closePass -and -not $hiveLoaded -and -not $mounted) {
            Say 'RESULT=PASS_R20R2F11_EXACT_CBS_VISIBILITY_STATE_READONLY_METADATA_ONLY'
        } else {
            Say 'RESULT=HOLD_R20R2F11_CBS_OR_OWNED_HIVE_MOUNT_CLOSEOUT'
        }
        Say 'OWNER_AUTHORIZATION=NOT_CERTIFIED;NO_NATIVE_REMOVAL_OR_PRODUCTION_PROMOTION;JSON_NOT_EXPECTED'
        Say "REPORT=$report"
        if ($null -ne $writer) { $writer.Dispose();$writer=$null }
    }
    if (-not $pass -or -not $closePass -or $hiveLoaded -or $mounted) { throw 'BL_F11_HOLD_SEND_ORIGINAL_TXT_DO_NOT_RERUN' }
}
