param(
    [Parameter(Mandatory=$true)][string]$Aria2File,
    [Parameter(Mandatory=$true)][string]$AppAllowPatternsFile,
    [Parameter(Mandatory=$true)][string]$AlwaysKeepPatternsFile,
    [Parameter(Mandatory=$true)][string]$RequiredAppIdentitiesFile,
    [string]$Language = 'en-us',
    [ValidateSet('amd64','x64')][string]$Architecture = 'amd64',
    [string]$LogPath = ".\BlueLite_Logs\FilterApps.log"
)

$ErrorActionPreference = 'Stop'

function Read-Patterns([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Pattern file not found: $Path" }
    return @(Get-Content -LiteralPath $Path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}
function Matches-Any([string]$Text,[string[]]$Patterns) {
    foreach ($p in $Patterns) { if ($Text.IndexOf($p,[StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true } }
    return $false
}
function Split-Aria2Records([string[]]$Lines) {
    $prefix = [System.Collections.Generic.List[string]]::new()
    $records = [System.Collections.Generic.List[object]]::new()
    $cur = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        if ($line -match '^\s*https?://') {
            if ($cur.Count -gt 0) { [void]$records.Add($cur.ToArray()); $cur=[System.Collections.Generic.List[string]]::new() }
            [void]$cur.Add($line)
        }
        elseif ($cur.Count -gt 0) { [void]$cur.Add($line) }
        else { [void]$prefix.Add($line) }
    }
    if ($cur.Count -gt 0) { [void]$records.Add($cur.ToArray()) }
    return [pscustomobject]@{ Prefix=$prefix.ToArray(); Records=$records.ToArray() }
}
function Get-OutName([string[]]$Record) {
    $o = $Record | Where-Object { $_ -match '^\s*out=' } | Select-Object -First 1
    if ($o) { return ($o -replace '^\s*out=','').Trim().Trim('"') }
    return $null
}
function Is-ForeignLanguage([string]$Name,[string]$TargetLanguage) {
    $target=$TargetLanguage.ToLowerInvariant(); $targetBase=($target -split '-')[0]
    $m=[regex]::Match($Name,'(?i)(?:language[-_]|_language-)([a-z]{2,3}(?:-[a-z0-9]{2,8})*)')
    if (-not $m.Success) { return $false }
    $tag=$m.Groups[1].Value.ToLowerInvariant()
    return -not ($tag -eq $target -or $tag -eq $targetBase)
}
function Is-ForeignArchitecture([string]$Name,[string]$Arch) {
    if ($Arch -notin @('amd64','x64')) { return $false }
    return ($Name -match '(?i)(?:^|[._-])(x86|arm64|arm)(?:[._-]|$)')
}

try {
    if (-not (Test-Path -LiteralPath $Aria2File)) { throw "aria2 file not found: $Aria2File" }
    [string[]]$allow=Read-Patterns $AppAllowPatternsFile
    [string[]]$always=Read-Patterns $AlwaysKeepPatternsFile
    [string[]]$required=Read-Patterns $RequiredAppIdentitiesFile
    $parsed=Split-Aria2Records ([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Aria2File)))
    if ($parsed.Records.Count -eq 0) { throw 'No aria2 URL records found.' }

    $kept=[System.Collections.Generic.List[object]]::new()
    $removed=[System.Collections.Generic.List[string]]::new()
    $removedLanguage=[System.Collections.Generic.List[string]]::new()
    $removedArch=[System.Collections.Generic.List[string]]::new()

    foreach ($obj in $parsed.Records) {
        [string[]]$record=$obj
        $text=$record -join "`n"
        $name=Get-OutName $record
        if (-not ((Matches-Any $text $allow) -or (Matches-Any $text $always))) {
            [void]$removed.Add($(if($name){$name}else{'<unnamed>'})); continue
        }
        if ($name -and (Is-ForeignLanguage $name $Language)) { [void]$removedLanguage.Add($name); continue }
        if ($name -and (Is-ForeignArchitecture $name $Architecture)) { [void]$removedArch.Add($name); continue }
        [void]$kept.Add($record)
    }

    if ($kept.Count -lt 3) { throw "Seed filter would leave only $($kept.Count) records. Original queue was NOT modified." }
    foreach ($r in $required) {
        $found=$false
        foreach ($obj in $kept) {
            if (($obj -join "`n").IndexOf($r,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $found=$true; break }
        }
        if (-not $found) { throw "Required retained app '$r' was not found in the seed Apps queue." }
    }

    $backup="$Aria2File.prebluelite-v1.bak"
    Copy-Item -LiteralPath $Aria2File -Destination $backup -Force
    $out=[System.Collections.Generic.List[string]]::new()
    foreach ($l in $parsed.Prefix) { [void]$out.Add([string]$l) }
    foreach ($obj in $kept) { foreach ($l in [string[]]$obj) { [void]$out.Add($l) }; [void]$out.Add('') }
    [IO.File]::WriteAllLines((Resolve-Path -LiteralPath $Aria2File),$out.ToArray(),(New-Object Text.UTF8Encoding($false)))

    $ldir=Split-Path -Parent $LogPath
    if ($ldir -and -not (Test-Path -LiteralPath $ldir)) { New-Item -ItemType Directory -Path $ldir -Force | Out-Null }
    @(
        'BlueLite v1.0 Apps seed pre-download filter',
        "Input records: $($parsed.Records.Count)",
        "Seed records kept: $($kept.Count)",
        "Removed non-BlueLite records: $($removed.Count)",
        "Removed foreign-language records: $($removedLanguage.Count)",
        "Removed foreign-architecture records: $($removedArch.Count)",
        "Target language: $Language", "Target architecture: $Architecture",
        "Backup: $backup",
        '', 'REMOVED NON-BLUELITE:', $removed,
        '', 'REMOVED FOREIGN LANGUAGE:', $removedLanguage,
        '', 'REMOVED FOREIGN ARCH:', $removedArch
    ) | Set-Content -LiteralPath $LogPath -Encoding UTF8

    Write-Host "[OK] Apps seed queue: $($parsed.Records.Count) -> $($kept.Count) records." -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Set-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
