# BlueLite v1.0 - R20R2F11R1: close out ONLY the previous copied-SOFTWARE scratch.
# No WIM mount, no hive load/unload, no servicing and no recursive deletion.
& {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    if ($PSVersionTable.PSVersion.Major -ne 7 -or [IntPtr]::Size -ne 8) { throw 'BL_F11R1_PS7_X64_REQUIRED' }
    $principal = [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'BL_F11R1_ADMIN_REQUIRED' }
    $root = 'C:\BLR20R2F11'
    $mount = 'C:\BLR20R2F11\mount'
    $receipt = 'C:\work\logs\BlueLite_26300_9807_OneDriveCBSOwners_R20R2F11.txt'
    $out = 'C:\work\logs\BlueLite_26300_9807_OneDriveScratchCloseout_R20R2F11R1.txt'
    $dism = Join-Path $env:WINDIR 'System32\dism.exe'
    $reg = Join-Path $env:WINDIR 'System32\reg.exe'
    $writer = $null
    $pass = $false
    $deleted = 0
    function Note([string]$line) {
        Write-Host $line
        if ($null -ne $writer) { $writer.WriteLine($line); $writer.Flush() }
    }
    function NoMounts([string]$when) {
        foreach ($opt in @('/Get-MountedWimInfo','/Get-MountedImageInfo')) {
            $raw = @(& $dism /English $opt 2>&1 | ForEach-Object { [string]$_ })
            $rc = [int]$LASTEXITCODE
            $t = $raw -join "`n"
            if ($rc -ne 0 -or $t -notmatch '(?im)^\s*No mounted images found\.\s*$' -or $t -match '(?im)^\s*Mount Dir\s*:') {
                throw "BL_F11R1_MOUNT_TABLE_HOLD=$when/$opt/EXIT=$rc"
            }
            Note "DISM_${when}:$opt=EMPTY;EXIT=0"
        }
    }
    function CheckHiveRoots([string]$when) {
        $raw = @(& $reg query HKLM /reg:64 2>&1 | ForEach-Object { [string]$_ })
        if ([int]$LASTEXITCODE -ne 0) { throw "BL_F11R1_HKLM_NATIVE_QUERY_HOLD=$when" }
        $allow = @('BCD00000000','COMPONENTS','DRIVERS','HARDWARE','SAM','SECURITY','SOFTWARE','SYSTEM')
        $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($line in $raw) {
            $s = $line.Trim()
            if ($s.StartsWith('HKEY_LOCAL_MACHINE\',[StringComparison]::OrdinalIgnoreCase)) {
                $m = [regex]::Match($s,'^HKEY_LOCAL_MACHINE\\([A-Za-z0-9_]+)$','IgnoreCase')
                if (-not $m.Success -or $allow -notcontains $m.Groups[1].Value) {
                    throw "BL_F11R1_UNEXPECTED_HIVE_ALIAS=$s"
                }
                [void]$seen.Add($m.Groups[1].Value)
            }
        }
        if (-not $seen.Contains('SOFTWARE') -or -not $seen.Contains('SYSTEM')) { throw 'BL_F11R1_HKLM_OUTPUT_SHAPE_HOLD' }
        Note "HKLM_$when=EXPECTED_ONLY;COUNT=$($seen.Count);EXIT=0"
    }
    try {
        $logdir = Get-Item -LiteralPath 'C:\work\logs' -Force -ErrorAction Stop
        if (-not $logdir.PSIsContainer -or ($logdir.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'BL_F11R1_LOG_DIRECTORY_NOT_ORDINARY' }
        if ([IO.File]::Exists($out)) { throw 'BL_F11R1_REPORT_ALREADY_EXISTS_NO_OVERWRITE' }
        $fs = [IO.FileStream]::new($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        $writer = [IO.StreamWriter]::new($fs,[Text.UTF8Encoding]::new($false))
        $writer.AutoFlush = $true
        Note 'BLUELITE_R20R2F11R1_OWNED_COPIED_HIVE_SCRATCH_CLOSEOUT_ONLY'
        Note 'NO_WIM_ACCESS_NO_HIVE_LOAD_NO_SERVICING_NO_RECURSIVE_DELETE'
        $f = Get-Item -LiteralPath $receipt -Force -ErrorAction Stop
        if ($f.PSIsContainer -or $f.Length -ne 7117 -or
           (Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -cne '7C7C3BCC378524ACF0CACD941B60DAEC836CA88E5DFF3EDD24DD7AD0095E778D') {
            throw 'BL_F11R1_ORIGINAL_R11_REPORT_SHA_OR_SIZE_HOLD'
        }
        $receiptText = [IO.File]::ReadAllText($receipt)
        foreach ($line in @('REG_UNLOAD_COPIED_SOFTWARE_NATIVE_EXIT=0','OWNED_NATIVE_RO_DISCARD=PASS',
            'MOUNT_POST:/Get-MountedWimInfo=EMPTY;EXIT=0','MOUNT_POST:/Get-MountedImageInfo=EMPTY;EXIT=0',
            'RESULT=HOLD_R20R2F11_CBS_OR_OWNED_HIVE_MOUNT_CLOSEOUT')) {
            if (-not $receiptText.Contains($line)) { throw "BL_F11R1_R11_PROOF_MISSING=$line" }
        }
        Note 'ORIGINAL_R11_RECEIPT_SHA_NATIVE_UNLOAD_DISCARD_AND_HOLD=PASS'
        NoMounts 'PRE'
        CheckHiveRoots 'PRE'
        if (Test-Path -LiteralPath $mount) { throw 'BL_F11R1_OWNED_MOUNT_EXISTS_NO_DELETE' }
        if (-not (Test-Path -LiteralPath $root)) {
            Note 'OWNED_SCRATCH=ALREADY_ABSENT'
        } else {
            $dir = Get-Item -LiteralPath $root -Force -ErrorAction Stop
            if (-not $dir.PSIsContainer -or ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw 'BL_F11R1_ROOT_NOT_ORDINARY_DIRECTORY'
            }
            $items = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop)
            Note "SCRATCH_IMMEDIATE_CHILDREN=$($items.Count)"
            # Native reg load of an owned copied SOFTWARE.hiv can create these transaction sidecars.
            # Any directory, reparse point, copied base hive, or other name means HOLD before deleting anything.
            $known = '^SOFTWARE\.hiv(?:\.LOG[12]|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\.TM\.blf|\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\.TMContainer\d+\.regtrans-ms)$'
            foreach ($item in $items) {
                Note "SCRATCH_ITEM=$($item.Name);BYTES=$($item.Length);ATTRIBUTES=$($item.Attributes)"
                if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
                    $item.Name -cnotmatch $known -or $item.FullName -cne (Join-Path $root $item.Name)) {
                    throw "BL_F11R1_UNKNOWN_SCRATCH_CHILD_NO_DELETION=$($item.Name)"
                }
            }
            # Re-inventory before deletion; changes from the approved snapshot cause HOLD.
            $again = @(Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop)
            if ($again.Count -ne $items.Count -or
                (@($again | Select-Object -ExpandProperty Name | Sort-Object) -join '|') -cne
                (@($items | Select-Object -ExpandProperty Name | Sort-Object) -join '|')) {
                throw 'BL_F11R1_SCRATCH_CHANGED_DURING_PREFLIGHT'
            }
            foreach ($item in $items) {
                [IO.File]::Delete($item.FullName)
                $deleted++
                Note "RETIRED_TRANSACTION_SIDECAR=$($item.Name)"
            }
            if (@(Get-ChildItem -LiteralPath $root -Force -ErrorAction Stop).Count -ne 0) {
                throw 'BL_F11R1_SCRATCH_NOT_EMPTY_POST_EXACT_FILE_DELETES'
            }
            [IO.Directory]::Delete($root,$false)
            Note 'OWNED_EMPTY_SCRATCH_ROOT_REMOVED=PASS'
        }
        if (Test-Path -LiteralPath $root) { throw 'BL_F11R1_SCRATCH_ROOT_STILL_PRESENT' }
        NoMounts 'POST'
        CheckHiveRoots 'POST'
        Note "EXACT_TRANSIENT_FILES_RETIRED=$deleted"
        $pass = $true
    } catch {
        Note ('ERROR=' + ($_.Exception.Message -replace '[\r\n]+',' '))
    } finally {
        if ($pass) { Note 'RESULT=PASS_R20R2F11R1_OWNED_SCRATCH_CLOSEOUT_ONLY' }
        else { Note 'RESULT=HOLD_R20R2F11R1_PRESERVE_UNKNOWN_OWNED_SCRATCH' }
        Note "REPORT=$out"
        if ($null -ne $writer) { $writer.Dispose() }
    }
    if (-not $pass) { throw 'BL_F11R1_SCRATCH_CLOSEOUT_HOLD_SEND_REPORT_DO_NOT_RERUN_BLINDLY' }
}
