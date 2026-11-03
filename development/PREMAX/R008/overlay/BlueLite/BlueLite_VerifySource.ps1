param(
    [Parameter(Mandatory=$true)][string]$UUPDirectory,
    [Parameter(Mandatory=$true)][string]$AppsQueueFile,
    [Parameter(Mandatory=$true)][string]$AppsQueueOriginalFile,
    [Parameter(Mandatory=$true)][string]$WindowsQueueFile,
    [Parameter(Mandatory=$true)][string]$WindowsQueueOriginalFile,
    [Parameter(Mandatory=$true)][string]$ExpectedBuild,
    [Parameter(Mandatory=$true)][string]$RequiredAppIdentitiesFile,
    [string]$LogPath = ".\BlueLite_Logs\VerifySource.log"
)

$ErrorActionPreference = 'Stop'

function Read-Patterns([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Pattern file not found: $Path" }
    return @(Get-Content -LiteralPath $Path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}
function Get-Aria2Records([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Queue not found: $Path" }
    $records=[System.Collections.Generic.List[object]]::new()
    $cur=[System.Collections.Generic.List[string]]::new()
    foreach ($line in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path))) {
        if ($line -match '^\s*https?://') {
            if ($cur.Count -gt 0) { [void]$records.Add($cur.ToArray()); $cur=[System.Collections.Generic.List[string]]::new() }
            [void]$cur.Add($line)
        }
        elseif ($cur.Count -gt 0) { [void]$cur.Add($line) }
    }
    if ($cur.Count -gt 0) { [void]$records.Add($cur.ToArray()) }
    return $records.ToArray()
}
function Get-OutName([string[]]$Record) {
    $o=$Record | Where-Object { $_ -match '^\s*out=' } | Select-Object -First 1
    if ($o) { return ($o -replace '^\s*out=','').Trim().Trim('"') }
    return $null
}

try {
    if ($ExpectedBuild -notmatch '^\d{5}\.\d+$') { throw "Unexpected build format: $ExpectedBuild" }
    if (-not (Test-Path -LiteralPath $UUPDirectory)) { throw "UUP directory not found: $UUPDirectory" }

    $winActiveHash=(Get-FileHash -LiteralPath $WindowsQueueFile -Algorithm SHA256).Hash
    $winOriginalHash=(Get-FileHash -LiteralPath $WindowsQueueOriginalFile -Algorithm SHA256).Hash
    if ($winActiveHash -ne $winOriginalHash) {
        throw 'Windows UUP queue changed after retrieval. BlueLite requires byte-for-byte intact Windows reference/delta closure.'
    }

    $apps=@(Get-Aria2Records $AppsQueueFile)
    $appsOriginal=@(Get-Aria2Records $AppsQueueOriginalFile)
    $wins=@(Get-Aria2Records $WindowsQueueFile)
    if ($apps.Count -eq 0 -or $appsOriginal.Count -eq 0) { throw 'Apps queue is empty.' }
    if ($wins.Count -eq 0) { throw 'Windows queue is empty.' }
    if ($apps.Count -gt $appsOriginal.Count) { throw 'Active Apps queue is larger than its original queue.' }

    $originalAppNames=@{}
    foreach ($r in $appsOriginal) { $n=Get-OutName ([string[]]$r); if ($n) { $originalAppNames[$n.ToLowerInvariant()]=$true } }
    $foreignActive=[System.Collections.Generic.List[string]]::new()
    foreach ($r in $apps) {
        $n=Get-OutName ([string[]]$r)
        if ($n -and -not $originalAppNames.ContainsKey($n.ToLowerInvariant())) { [void]$foreignActive.Add($n) }
    }
    if ($foreignActive.Count -gt 0) { throw "Active Apps queue contains $($foreignActive.Count) records absent from the original UUP Apps queue." }

    [string[]]$required=Read-Patterns $RequiredAppIdentitiesFile
    $missingRequired=[System.Collections.Generic.List[string]]::new()
    foreach ($req in $required) {
        $found=$false
        foreach ($r in $apps) { if (([string[]]$r -join "`n").IndexOf($req,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $found=$true; break } }
        if (-not $found) { [void]$missingRequired.Add($req) }
    }

    $files=@(Get-ChildItem -LiteralPath $UUPDirectory -Recurse -File -ErrorAction Stop)
    $byName=@{}
    foreach ($f in $files) { $byName[$f.Name.ToLowerInvariant()]=$true }
    $missing=[System.Collections.Generic.List[string]]::new()
    foreach ($r in @($apps + $wins)) {
        $n=Get-OutName ([string[]]$r)
        if (-not $n) { continue }
        $leaf=[IO.Path]::GetFileName($n).ToLowerInvariant()
        if (-not $byName.ContainsKey($leaf)) { [void]$missing.Add($n) }
    }

    $partials=@($files | Where-Object { $_.Name -like '*.aria2' })
    $coreChecks=@(
        @{Label='Professional edition ESD'; Pattern='professional'; Ext='.esd'},
        @{Label='Client Features source'; Pattern='Client-Features-Package'; Ext='.esd'},
        @{Label='Client Desktop Required source'; Pattern='Client-Desktop-Required-Package'; Ext='.esd'}
    )
    $coreMissing=[System.Collections.Generic.List[string]]::new()
    foreach ($c in $coreChecks) {
        $ok=$false
        foreach ($f in $files) {
            if ($f.Name.IndexOf($c.Pattern,[StringComparison]::OrdinalIgnoreCase) -ge 0 -and $f.Extension -ieq $c.Ext) { $ok=$true; break }
        }
        if (-not $ok) { [void]$coreMissing.Add($c.Label) }
    }

    $ldir=Split-Path -Parent $LogPath
    if ($ldir -and -not (Test-Path -LiteralPath $ldir)) { New-Item -ItemType Directory -Path $ldir -Force | Out-Null }
    @(
        'BlueLite v1.0 source verification',
        "Expected build: $ExpectedBuild",
        "Files scanned: $($files.Count)",
        "Apps queue records: $($apps.Count)",
        "Original Apps queue records: $($appsOriginal.Count)",
        "Windows queue records: $($wins.Count)",
        "Windows queue SHA256: $winActiveHash",
        "Missing required apps: $($missingRequired.Count)",
        "Missing queued downloads: $($missing.Count)",
        "Partial .aria2 files: $($partials.Count)",
        "Missing core reconstruction classes: $($coreMissing.Count)",
        "Foreign active Apps records: $($foreignActive.Count)",
        '', 'MISSING REQUIRED APPS:', $missingRequired,
        '', 'MISSING QUEUED DOWNLOADS:', $missing,
        '', 'PARTIAL DOWNLOADS:', ($partials | ForEach-Object FullName),
        '', 'MISSING CORE:', $coreMissing,
        '', 'FOREIGN ACTIVE APP RECORDS:', $foreignActive
    ) | Set-Content -LiteralPath $LogPath -Encoding UTF8

    if ($missingRequired.Count -gt 0 -or $missing.Count -gt 0 -or $partials.Count -gt 0 -or $coreMissing.Count -gt 0 -or $foreignActive.Count -gt 0) {
        throw "Verify gate failed. See $LogPath"
    }

    Write-Host "[OK] VERIFY GATE passed for $ExpectedBuild." -ForegroundColor Green
    Write-Host "[OK] Apps queue is a verified subset of the original; Windows queue stayed byte-for-byte intact." -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Add-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
