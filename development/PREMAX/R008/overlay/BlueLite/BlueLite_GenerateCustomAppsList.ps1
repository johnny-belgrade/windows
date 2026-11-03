param(
    [Parameter(Mandatory=$true)][string]$TemplatePath,
    [Parameter(Mandatory=$true)][string]$AllowPatternsFile,
    [Parameter(Mandatory=$true)][string]$RequiredAppIdentitiesFile,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$LogPath = ".\BlueLite_Logs\GenerateCustomAppsList.log"
)

$ErrorActionPreference = 'Stop'

function Read-Patterns([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "Pattern file not found: $Path" }
    return @(Get-Content -LiteralPath $Path | ForEach-Object { $_.Trim() } | Where-Object { $_ -and -not $_.StartsWith('#') })
}

function Matches-Any([string]$Text,[string[]]$Patterns) {
    foreach ($p in $Patterns) {
        if ($Text.IndexOf($p,[StringComparison]::OrdinalIgnoreCase) -ge 0) { return $true }
    }
    return $false
}

try {
    if (-not (Test-Path -LiteralPath $TemplatePath)) { throw "Official CustomAppsList template not found: $TemplatePath" }
    [string[]]$allow = Read-Patterns $AllowPatternsFile
    [string[]]$required = Read-Patterns $RequiredAppIdentitiesFile
    if ($allow.Count -eq 0) { throw 'App allowlist is empty.' }
    if ($required.Count -eq 0) { throw 'Required app identity list is empty.' }

    $selected = [System.Collections.Generic.List[string]]::new()
    $disabled = [System.Collections.Generic.List[string]]::new()
    $out = [System.Collections.Generic.List[string]]::new()
    $seenCandidates = 0

    foreach ($line in Get-Content -LiteralPath $TemplatePath) {
        $trim = $line.Trim()
        if (-not $trim -or $trim.StartsWith('###') -or $trim.StartsWith('##')) {
            [void]$out.Add($line)
            continue
        }

        $candidate = $trim -replace '^#\s*',''
        if ($candidate -match '^[A-Za-z0-9][A-Za-z0-9._-]+_[A-Za-z0-9]+$') {
            $seenCandidates++
            if (Matches-Any $candidate $allow) {
                [void]$out.Add($candidate)
                [void]$selected.Add($candidate)
            }
            else {
                [void]$out.Add("# $candidate")
                [void]$disabled.Add($candidate)
            }
        }
        else {
            # Preserve future UUP dump comments/section syntax we do not understand.
            [void]$out.Add($line)
        }
    }

    if ($seenCandidates -lt 5) {
        throw "Official app template yielded only $seenCandidates app entries; refusing to generate an incomplete list."
    }

    foreach ($r in $required) {
        $found = $false
        foreach ($s in $selected) {
            if ($s.IndexOf($r,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $found=$true; break }
        }
        if (-not $found) { throw "Required BlueLite app is absent from current UUP dump CustomAppsList: $r" }
    }

    $odir = Split-Path -Parent $OutputPath
    if ($odir -and -not (Test-Path -LiteralPath $odir)) { New-Item -ItemType Directory -Path $odir -Force | Out-Null }
    [IO.File]::WriteAllLines([IO.Path]::GetFullPath($OutputPath),$out.ToArray(),(New-Object Text.UTF8Encoding($false)))

    $ldir = Split-Path -Parent $LogPath
    if ($ldir -and -not (Test-Path -LiteralPath $ldir)) { New-Item -ItemType Directory -Path $ldir -Force | Out-Null }
    @(
        'BlueLite v1.0 dynamic CustomAppsList',
        "Template: $TemplatePath",
        "Candidates: $seenCandidates",
        "Selected top-level apps: $($selected.Count)",
        "Disabled top-level apps: $($disabled.Count)",
        '', 'SELECTED:', $selected,
        '', 'DISABLED:', $disabled
    ) | Set-Content -LiteralPath $LogPath -Encoding UTF8

    Write-Host "[OK] CustomAppsList: $($selected.Count) selected / $($disabled.Count) disabled." -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Set-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
