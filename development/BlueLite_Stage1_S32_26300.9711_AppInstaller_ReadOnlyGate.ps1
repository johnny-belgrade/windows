& {
    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    $PSNativeCommandUseErrorActionPreference = $false
    $wim = 'C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
    $mount = 'C:\work\E2E\BlueLite_Stage1_S32_26300.9711_RO_Mount'
    $report = 'C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_ReadOnlyGate.txt'
    $csv = 'C:\work\logs\BlueLite_Stage1_S32_26300.9711_AppInstaller_PhysicalInventory.csv'
    $main = 'C:\work\logs\BlueLite_Stage1_S31_26300.9711_OneDrive_AMBER_Apply.txt'
    $scan = 'C:\work\logs\BlueLite_Stage1_S31_26300.9711_POST_SCANHEALTH.txt'
    $expected = 'F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
    $dism = Join-Path $env:SystemRoot 'System32\dism.exe'
    $result = 'HOLD_S32_APPINSTALLER_READONLY_GATE'
    $auditOK = $false
    $released = $false
    $hashOK = $false
    $mounted = $false
    $targets = @(
        'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.8521',
        'Microsoft-Windows-OneDrive-Setup-WOW64-Package~31bf3856ad364e35~amd64~~10.0.26100.1',
        'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1',
        'Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1',
        'Microsoft-Windows-OneDrive-Setup-WOW64-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
    )
    $keep = @(
        'Microsoft.SecHealthUI', 'Microsoft.DesktopAppInstaller',
        'Microsoft.WindowsCalculator', 'Microsoft.WindowsNotepad',
        'Microsoft.Windows.Photos'
    )
    if ($PSVersionTable.PSVersion.Major -ne 7 -or -not (
        [Security.Principal.WindowsPrincipal]::new(
            [Security.Principal.WindowsIdentity]::GetCurrent()
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    )) { throw 'PS7_ADMIN_REQUIRED' }
    if ((Test-Path -LiteralPath $report) -or (Test-Path -LiteralPath $csv) -or
        (Test-Path -LiteralPath $mount)) { throw 'S32_OUTPUT_ALREADY_EXISTS' }
    if (-not (Test-Path -LiteralPath 'C:\work\logs' -PathType Container)) {
        throw 'CWORK_LOG_DIRECTORY_MISSING'
    }
    [IO.File]::WriteAllText($report, '', [Text.UTF8Encoding]::new($false))
    function Note([string]$msg) {
        $line = (Get-Date -Format 'HH:mm:ss') + ' | ' + $msg
        Write-Host $line
        [IO.File]::AppendAllText($report, $line + [Environment]::NewLine,
            [Text.UTF8Encoding]::new($false))
    }
    function Pin([string]$label,[string]$path,[string]$sha) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "PIN_MISSING=$label"
        }
        $got=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($got -cne $sha) { throw "PIN_DRIFT=$label;$got" }
        Note "PIN=$label;SHA256=PASS"
    }
    function Table {
        $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 |
            ForEach-Object { [string]$_ })
        if ($LASTEXITCODE -ne 0) { throw 'MOUNT_TABLE_FAILED' }
        return $lines
    }
    function Owned([string[]]$lines) {
        foreach ($line in $lines) {
            $m=[regex]::Match([string]$line,'^\s*Mount Dir\s*:\s*(.*?)\s*$')
            if ($m.Success -and $m.Groups[1].Value.Trim() -ieq $mount) {
                return $true
            }
        }
        return $false
    }
    function Dism([string]$label,[string[]]$arguments) {
        $lines=@(& $dism @arguments 2>&1 | ForEach-Object { [string]$_ })
        $code=[int]$LASTEXITCODE
        $out=$lines -join [Environment]::NewLine
        Note "DISM_$label=$code"
        if ($code -ne 0 -and $label -ne 'ONEDRIVE_ABSENCE') {
            throw "DISM_FAIL=$label;$code"
        }
        return [pscustomobject]@{ Code=$code; Text=$out }
    }
    try {
        Note 'STAGE=S32_26300_9711_READONLY_APPINSTALLER_PREOWNER'
        Note 'MODE=READ_ONLY_NO_IMAGE_MUTATION'
        Note '[1/6] PIN S31 SOURCE AND ORIGINAL EVIDENCE'
        Pin 'S31_MAIN' $main '0BEE37DAD57F111F878EAF37C5EFB9B0B59BF68C4B7ED638F067008603C20DF6'
        Pin 'S31_SCAN' $scan '1E02D1A863874ACB0C9B0CB6FA6010F7C42449F79481BDE90EC656A49E9DF3AB'
        $s31=[IO.File]::ReadAllText($main)
        foreach ($marker in @('RESULT=PASS_S31_9711_ONEDRIVE_AMBER_COMMITTED',
                             'S31_WIM_COMMIT=PASS','S31_MOUNT_RELEASED=PASS',
                             'S31_WIM_SHA256_AFTER=F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B')) {
            if (-not $s31.Contains($marker)) { throw "S31_MARKER_MISSING=$marker" }
        }
        if (-not (Test-Path -LiteralPath $wim -PathType Leaf) -or
            (Get-Item -LiteralPath $wim).Length -ne 6509216853) {
            throw 'S31_WIM_NOT_EXACT_SOURCE'
        }
        Note 'S31_WIM_HASH_PREFLIGHT=START'
        Pin 'S31_WIM' $wim $expected
        $before=@(Table)
        if (@($before | Where-Object { $_ -match '^\s*Mount Dir\s*:' }).Count -ne 0) {
            throw 'EXISTING_MOUNT_NO_FOREIGN_ACTION'
        }
        Note '[2/6] MOUNT EXACT WIM READ ONLY'
        $null=New-Item -ItemType Directory -Path $mount -ErrorAction Stop
        $null=Dism 'MOUNT' @('/English','/Mount-Image',"/ImageFile:$wim",
                             '/Index:1',"/MountDir:$mount",'/ReadOnly')
        $mounted=$true
        $fields=@{}
        foreach ($line in @(Table)) {
            $m=[regex]::Match([string]$line,
                '^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
            if ($m.Success) {
                if ($fields.ContainsKey($m.Groups[1].Value)) { throw 'DUPLICATE_MOUNT_FIELD' }
                $fields[$m.Groups[1].Value]=$m.Groups[2].Value.Trim()
            }
        }
        if ($fields.Count -ne 5 -or $fields['Mount Dir'] -ine $mount -or
            $fields['Image File'] -ine $wim -or $fields['Image Index'] -ne '1' -or
            $fields['Mounted Read/Write'] -ine 'No' -or $fields['Status'] -ine 'Ok') {
            throw 'OWNED_READONLY_MOUNT_IDENTITY_FAILED'
        }
        Note 'READONLY_MOUNT_OWNER=PASS_5_FIELDS'
        Note '[3/6] INDEPENDENT S31 POSTCOMMIT SERVICING GATE'
        foreach ($pkg in $targets) {
            $r=Dism 'ONEDRIVE_ABSENCE' @('/English',"/Image:$mount",
                                        '/Get-PackageInfo',"/PackageName:$pkg")
            if ($r.Code -eq 0 -or $r.Text -notmatch '0x800f0805') {
                throw "ONEDRIVE_POSTCOMMIT_DRIFT=$pkg"
            }
            Note "NONRESOLVING=PASS;$pkg"
        }
        if (Test-Path -LiteralPath (Join-Path $mount 'Windows\System32\OneDriveSetup.exe')) {
            throw 'ONEDRIVESETUP_STILL_EXISTS'
        }
        $setupDirs=@(Get-ChildItem -LiteralPath (Join-Path $mount 'Windows\WinSxS') -Force -Directory |
            Where-Object { $_.Name -match '^amd64_microsoft-windows-onedrive-setup_' })
        if ($setupDirs.Count -ne 0) { throw 'ONEDRIVE_SETUP_OWNER_RESIDUE' }
        foreach ($pending in @('Windows\WinSxS\pending.xml','Windows\WinSxS\reboot.xml')) {
            if (Test-Path -LiteralPath (Join-Path $mount $pending)) {
                throw "UNEXPECTED_PENDING_FILE=$pending"
            }
        }
        $h=Dism 'CHECKHEALTH' @('/English',"/Image:$mount",'/Cleanup-Image','/CheckHealth')
        if ($h.Text -notmatch 'No component store corruption detected') {
            throw 'POSTCOMMIT_CBS_NOT_CLEAN'
        }
        Note 'POSTCOMMIT_ONEDRIVE=PASS_CLEAN'
        Note '[4/6] PROVISIONED APPX AND FOUR APPINSTALLER ROOTS'
        $a=Dism 'APPX' @('/English',"/Image:$mount",'/Get-ProvisionedAppxPackages')
        $names=@([regex]::Matches($a.Text,'(?im)^\s*DisplayName\s*:\s*(\S+)\s*$') |
            ForEach-Object { $_.Groups[1].Value })
        Note "PROVISIONED_APPX_TOTAL=$($names.Count)"
        foreach ($name in @($names | Sort-Object -Unique)) { Note "PROVISIONED_APPX=$name" }
        foreach ($name in $keep) {
            if (@($names | Where-Object { $_ -ceq $name }).Count -ne 1) {
                throw "FIVE_STAGING_APPX_CONTRACT_FAILED=$name"
            }
        }
        foreach ($blocked in @('Microsoft.WindowsStore','Microsoft.StorePurchaseApp',
                                'Microsoft.Services.Store.Engagement')) {
            if ($names -contains $blocked) { throw "FORBIDDEN_STORE_PROVISIONED=$blocked" }
        }
        $roots=@(Get-ChildItem -LiteralPath (Join-Path $mount 'Program Files\WindowsApps') -Force -Directory |
            Where-Object { $_.Name -match '^Microsoft\.DesktopAppInstaller_.*_8wekyb3d8bbwe$' } |
            Sort-Object Name)
        Note "APPINSTALLER_ROOT_COUNT=$($roots.Count)"
        if ($roots.Count -ne 4) { throw 'APPINSTALLER_FOUR_ROOT_VARIANT_CHANGED' }
        $rows=[System.Collections.Generic.List[object]]::new()
        foreach ($item in $roots) {
            $files=@(Get-ChildItem -LiteralPath $item.FullName -File -Force -Recurse -ErrorAction Stop)
            [long]$logical=0
            [int]$reparse=0
            foreach ($file in $files) {
                $logical += [long]$file.Length
                $isReparse=(($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
                if ($isReparse) { $reparse++ }
                $rows.Add([pscustomobject]@{
                    Root=$item.Name
                    Relative=$file.FullName.Substring($item.FullName.Length).TrimStart('\')
                    BytesLogical=[long]$file.Length
                    ReparsePoint=[bool]$isReparse
                    Attributes=[string]$file.Attributes
                })
            }
            Note "ROOT=$($item.Name);FILES=$($files.Count);LOGICAL_BYTES=$logical;REPARSE=$reparse"
        }
        $rows | Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation
        Note "APPINSTALLER_CSV=$csv"
        Note "APPINSTALLER_INVENTORY_ROWS=$($rows.Count)"
        Note 'HARDLINK_OWNER_CLOSURE=NOT_CERTIFIED'
        Note 'APPINSTALLER_MUTATION=NOT_RUN'
        $auditOK=$true
    }
    catch {
        Note "ERROR=$($_.Exception.Message)"
    }
    finally {
        Note '[5/6] OWNED DISCARD AND HASH RECHECK'
        try {
            $table=@(Table)
            if (Owned $table) {
                $null=Dism 'DISCARD' @('/English','/Unmount-Image',
                                       "/MountDir:$mount",'/Discard')
                Note 'READONLY_UNMOUNT_DISCARD=PASS'
            }
            if (-not (Owned @(Table))) {
                $released=$true
                Note 'OWNED_MOUNT_RELEASED=PASS'
            }
            if ($released) {
                Note 'S31_WIM_HASH_POSTMOUNT=START'
                $post=(Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash
                $hashOK=($post -ceq $expected -and
                          (Get-Item -LiteralPath $wim).Length -eq 6509216853)
                Note "S31_WIM_UNCHANGED=$hashOK"
            }
        }
        catch {
            Note "CLOSEOUT_ERROR=$($_.Exception.Message)"
        }
        Note '[6/6] TERMINAL RESULT'
        if ($auditOK -and $released -and $hashOK) {
            $result='PASS_S32_9711_READONLY_APPINSTALLER_PREOWNER_GATE'
        }
        Note 'WIM_MUTATION=NOT_RUN'
        Note 'NEXT_REMOVAL_AUTHORITY=NOT_GRANTED'
        Note "RESULT=$result"
        Write-Host "MAIN_LOG=$report"
        Write-Host "CSV=$csv"
    }
}
