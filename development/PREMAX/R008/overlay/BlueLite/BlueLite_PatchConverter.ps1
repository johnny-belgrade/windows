param(
    [Parameter(Mandatory=$true)][string]$ConverterPath,
    [Parameter(Mandatory=$true)][string]$ConfigPath,
    [string]$LogPath = ".\BlueLite_Logs\PatchConverter.log"
)

$ErrorActionPreference = 'Stop'

try {
    if (-not (Test-Path -LiteralPath $ConverterPath)) { throw "Converter not found: $ConverterPath" }
    if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "ConvertConfig not found: $ConfigPath" }

    # BlueLite v1.0 depends on these converter modes. Refuse silent local edits that would
    # re-embed WinRE, skip the final ISO, create ESD instead of WIM, or integrate
    # Store-app stubs contrary to the BlueLite design.
    $cfgRaw = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $ConfigPath).Path)
    $requiredIni = [ordered]@{
        'AutoStart'    = '1'
        'AddUpdates'   = '1'
        'Cleanup'      = '0'
        'ResetBase'    = '0'
        'wim2esd'      = '0'
        'SkipISO'      = '0'
        'SkipWinRE'    = '1'
        'SkipEdge'     = '1'
        'SkipApps'     = '0'
        'StubAppsFull' = '1'
        'CustomList'   = '1'
    }
    foreach ($kv in $requiredIni.GetEnumerator()) {
        $rx = '(?im)^\s*' + [regex]::Escape([string]$kv.Key) + '\s*=\s*' + [regex]::Escape([string]$kv.Value) + '\s*$'
        if ($cfgRaw -notmatch $rx) { throw "ConvertConfig invariant failed: $($kv.Key) must be $($kv.Value)." }
    }

    $full = (Resolve-Path -LiteralPath $ConverterPath).Path
    $enc = [Text.Encoding]::GetEncoding(1252)
    $raw = [IO.File]::ReadAllText($full,$enc)
    $actions = New-Object 'System.Collections.Generic.List[string]'

    $vr = [regex]::Match($raw,'(?im)^@?set\s+uivr=([^\r\n]+)\s*$')
    if (-not $vr.Success) { throw 'Could not detect UUP Converter revision (uivr=...). Refusing to patch unknown structure.' }
    $revision = $vr.Groups[1].Value.Trim()
    [void]$actions.Add("Detected converter revision: $revision")

    # Semantic guards rather than an exact converter revision.  Batch labels are
    # subroutine/goto targets; their physical order in the file is NOT execution order.
    # Validate the actual control-flow anchors instead of comparing character offsets.
    $fin = [regex]::Matches($raw,'(?m)^:finISO\s*$')
    if ($fin.Count -ne 1) { throw "Expected exactly one :finISO anchor; found $($fin.Count)." }
    $winre = [regex]::Matches($raw,'(?m)^:WinreWim\s*$')
    if ($winre.Count -ne 1) { throw "Expected exactly one :WinreWim anchor; found $($winre.Count)." }
    $bakIso = [regex]::Matches($raw,'(?m)^:BakISO\s*$')
    if ($bakIso.Count -ne 1) { throw "Expected exactly one :BakISO anchor; found $($bakIso.Count)." }

    # Native converter semantics: during install.wim flow SkipWinRE=1 skips embedding
    # winre.wim into install.wim.  During ISO flow the converter explicitly jumps to
    # :WinreWim with return target BakISO, then BakISO creates boot.wim.
    if ($raw -notmatch '(?im)^if %SkipWinRE% equ 0 goto :WinreWim\s*$') {
        throw 'Converter-native SkipWinRE install.wim behavior was not found; refusing to assume WinRE semantics.'
    }
    if ($raw -notmatch '(?im)^set _rtrn=BakISO\s*\r?\n\s*goto :WinreWim\s*\r?\n:BakISO\s*$') {
        throw 'Converter-native ISO WinRE return flow (BakISO -> WinreWim -> BakISO) was not found.'
    }
    if ($raw -notmatch '(?ims)^:BakISO\s*\r?\n.{0,4096}?Creating\s+boot\.wim') {
        throw 'Converter-native :BakISO boot.wim creation flow was not found.'
    }

    # After boot/ISO preparation v125r routes through esdSWM and returns to :finISO.
    # Verify that semantic route and that :finISO is the ISO-creation gate.
    if ($raw -notmatch '(?im)^set isiso=1\s*\r?\nset _rtrn=finISO\s*\r?\ngoto :esdSWM\s*\r?\n:finISO\s*$') {
        throw 'Converter-native return flow into :finISO was not found.'
    }
    if ($raw -notmatch '(?ims)^:finISO\s*\r?\n.{0,1024}?if %SkipISO% neq 0') {
        throw ':finISO no longer exposes the expected ISO-creation gate.'
    }

    $backup = "$full.prebluelite-v1.bak"
    Copy-Item -LiteralPath $full -Destination $backup -Force
    [void]$actions.Add("Pristine converter backup: $backup")

    # Historical BlueLite drafts had a destructive pre-conversion source-deletion block.
    # A fresh official converter should never contain it; remove it if an old custom file
    # accidentally survived in the working directory.
    $legacyStart = 'echo === Debloating source files before conversion . . .'
    $normalStart = 'echo === Detecting UUP editions files . . .'
    $iLegacy = $raw.IndexOf($legacyStart,[StringComparison]::OrdinalIgnoreCase)
    if ($iLegacy -ge 0) {
        $iNormal = $raw.IndexOf($normalStart,$iLegacy,[StringComparison]::OrdinalIgnoreCase)
        if ($iNormal -lt 0) { throw 'Legacy source deletion marker found but recovery anchor was not found.' }
        $lineStart = $raw.LastIndexOf("`n",$iLegacy)
        if ($lineStart -lt 0) { $lineStart=0 } else { $lineStart++ }
        $raw = $raw.Substring(0,$lineStart) + $raw.Substring($iNormal)
        [void]$actions.Add('Removed legacy destructive Windows-UUP pre-conversion source deletion block.')
    } else {
        [void]$actions.Add('No legacy destructive Windows-UUP source deletion block detected.')
    }

    # BlueLite v1.0 does NOT rewrite :WinreWim. ConvertConfig uses native SkipWinRE=1.
    # The stock ISO path still creates temp\winre.wim and uses it as the boot.wim source,
    # then skips only the step that embeds winre.wim into install.wim.
    [void]$actions.Add('Stock WinRE/boot.wim flow preserved; native SkipWinRE=1 semantics verified.')

    $marker = 'BLUELITE_MAX_PRE_V2_WIM_HOOK'
    if ($raw -notmatch [regex]::Escape($marker)) {
        $hook = @'
:finISO
:: BLUELITE_MAX_PRE_V2_WIM_HOOK
call :dk_color1 %Blue% "=== BlueLite MAX_PRE v2.0 reconstruction-safe offline pre-debloat before ISO . . ." 4 5
if not exist "ISOFOLDER\sources\install.wim" (
  echo [BlueLite ERROR] ISOFOLDER\sources\install.wim was not found.
  exit /b 91
)
powershell -NoProfile -ExecutionPolicy Bypass -File "BlueLite\BlueLite_PreDebloatWim.ps1" -WimPath "ISOFOLDER\sources\install.wim" -Index 1 -CapabilityPatternsFile "BlueLite\BlueLite_CapabilityRemovePatterns.txt" -FeatureDisableOnlyFile "BlueLite\BlueLite_FeatureDisableOnly.txt" -FeatureRemovePayloadFile "BlueLite\BlueLite_FeatureRemovePayload.txt" -PackagePatternsFile "BlueLite\BlueLite_PackageRemovePatterns.txt" -CustomAppsListPath ".\CustomAppsList.txt" -ProfilePath "BlueLite\BlueLite_Profile.ini" -ComponentWatchlistFile "BlueLite\BlueLite_ComponentWatchlist.txt" -RequiredStagingAppIdentitiesFile "BlueLite\BlueLite_RequiredStagingApps.txt" -RequiredFinalAppIdentitiesFile "BlueLite\BlueLite_RequiredFinalApps.txt" -StagingOnlyAppPatternsFile "BlueLite\BlueLite_StagingOnlyAppPatterns.txt" -ReleaseForbiddenAppPatternsFile "BlueLite\BlueLite_ReleaseForbiddenAppPatterns.txt" -OfflineHandoffPatternsFile "BlueLite\BlueLite_OfflineHandoffPatterns.txt" -ProtectedFloorFile "BlueLite\BlueLite_ProtectedFloor.txt" -ExpectedBuildFile ".\BlueLite_Logs\ResolvedUUP.json" -LogPath ".\BlueLite_Logs\FinalWimDebloat.log"
if errorlevel 1 (
  echo [BlueLite ERROR] Pre-debloat WIM stage failed. ISO creation is stopped.
  exit /b 92
)

'@
        $raw = [regex]::Replace($raw,'(?m)^:finISO\s*\r?\n',[Text.RegularExpressions.MatchEvaluator]{param($m) $hook},1)
        [void]$actions.Add('Inserted BlueLite MAX_PRE v2.0 pre-debloat hook at :finISO.')
    } else {
        [void]$actions.Add('BlueLite MAX_PRE v2.0 pre-debloat hook already present.')
    }

    if ($raw -notmatch [regex]::Escape($marker)) { throw 'Final-WIM hook validation failed.' }
    if ($raw.IndexOf($legacyStart,[StringComparison]::OrdinalIgnoreCase) -ge 0) { throw 'Legacy destructive source-deletion marker survived patch.' }

    [IO.File]::WriteAllText($full,$raw,$enc)
    [void]$actions.Add('Patched converter written successfully.')

    $ldir = Split-Path -Parent $LogPath
    if ($ldir -and -not (Test-Path -LiteralPath $ldir)) { New-Item -ItemType Directory -Path $ldir -Force | Out-Null }
    $actions | Set-Content -LiteralPath $LogPath -Encoding UTF8
    $actions | ForEach-Object { Write-Host "[OK] $_" -ForegroundColor Green }
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Set-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
