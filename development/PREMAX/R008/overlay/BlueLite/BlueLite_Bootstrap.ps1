param(
    [string]$FilesDirectory = '.\files',
    [string]$PreparedConverterDirectory = '.\files\converter_ready',
    [string]$LogPath = '.\BlueLite_Logs\Bootstrap.log',
    [string]$AriaLogPath = '.\BlueLite_Logs\aria2_download.log'
)

$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'

function Ensure-Directory([string]$Path) {
    if(-not (Test-Path -LiteralPath $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}
function Parse-ConverterList([string]$Path) {
    $text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
    $blocks=@($text -split '(?:\r?\n){2,}')
    $items=[System.Collections.Generic.List[object]]::new()
    foreach($block in $blocks) {
        $url=[regex]::Match($block,'(?im)^\s*(https://\S+)\s*$')
        $out=[regex]::Match($block,'(?im)^\s*out=(\S+)\s*$')
        $hash=[regex]::Match($block,'(?im)^\s*checksum=sha-256=([0-9a-f]{64})\s*$')
        if($url.Success -and $out.Success -and $hash.Success) {
            [void]$items.Add([pscustomobject]@{Url=$url.Groups[1].Value.Trim();Out=$out.Groups[1].Value.Trim();Sha256=$hash.Groups[1].Value.ToUpperInvariant()})
        }
    }
    return @($items.ToArray())
}
function Test-PreparedConverter([string]$Path) {
    if(-not (Test-Path -LiteralPath (Join-Path $Path 'convert-UUP.cmd'))) { return $false }
    foreach($f in @('7z.dll','7z.exe','bcdedit.exe','bfi.exe','bootmui.txt','bootwim.txt','cdimage.exe','imagex.exe','libwim-15.dll','offlinereg.exe','offreg.dll','wimlib-imagex.exe','PSFExtractor.exe','cabarc.exe')) {
        if(-not (Test-Path -LiteralPath (Join-Path (Join-Path $Path 'bin') $f))) { return $false }
    }
    return $true
}

try {
    Ensure-Directory $FilesDirectory
    Ensure-Directory (Split-Path -Parent $LogPath)
    Ensure-Directory (Split-Path -Parent $AriaLogPath)
    $events=[System.Collections.Generic.List[string]]::new()
    [void]$events.Add('BlueLite v1.0 original-UUP bootstrap')

    $getAria=Join-Path $FilesDirectory 'get_aria2.ps1'
    $converterList=Join-Path $FilesDirectory 'converter_windows'
    $converterMulti=Join-Path $FilesDirectory 'converter_multi'
    foreach($p in @($getAria,$converterList,$converterMulti)) {
        if(-not (Test-Path -LiteralPath $p)) { throw "Original UUP bootstrap file missing: $p" }
        [void]$events.Add("SOURCE SHA256 $p = $((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash)")
    }

    # get_aria2.ps1 is a PowerShell script, not a native executable.
    # $LASTEXITCODE is not reliably populated when a .ps1 is invoked with & in-process.
    # Run the ORIGINAL UUP bootstrap in a child Windows PowerShell process so its
    # explicit Exit code becomes a real process exit code we can validate.
    & powershell.exe -NoProfile -ExecutionPolicy Unrestricted -File $getAria
    $getAriaExitCode = $LASTEXITCODE
    if($getAriaExitCode -ne 0) { throw "Original UUP get_aria2.ps1 failed with exit code $getAriaExitCode" }
    [void]$events.Add("Original get_aria2.ps1 completed with exit code $getAriaExitCode")
    $aria2=Join-Path $FilesDirectory 'aria2c.exe'
    if(-not (Test-Path -LiteralPath $aria2)) { throw 'Original UUP bootstrap did not produce files\aria2c.exe.' }

    $items=@(Parse-ConverterList $converterList)
    $seven=$items | Where-Object { $_.Out -ieq '7zr.exe' } | Select-Object -First 1
    $conv=$items | Where-Object { $_.Out -ieq 'uup-converter-wimlib.7z' } | Select-Object -First 1
    if($null -eq $seven -or $null -eq $conv) { throw 'Original files\converter_windows does not expose 7zr.exe and uup-converter-wimlib.7z.' }

    & $aria2 '--no-conf' '--async-dns=false' '--console-log-level=warn' '--log-level=info' ("--log="+[IO.Path]::GetFullPath($AriaLogPath)) '-x16' '-s16' '-j2' '-c' '-R' ("-d"+[IO.Path]::GetFullPath($FilesDirectory)) ("-i"+[IO.Path]::GetFullPath($converterList))
    if($LASTEXITCODE -ne 0) { throw "Original converter download failed with aria2 exit code $LASTEXITCODE" }

    $sevenPath=Join-Path $FilesDirectory '7zr.exe'
    $convPath=Join-Path $FilesDirectory 'uup-converter-wimlib.7z'
    foreach($pair in @(@($sevenPath,$seven.Sha256),@($convPath,$conv.Sha256))) {
        if(-not (Test-Path -LiteralPath $pair[0])) { throw "Downloaded converter asset missing: $($pair[0])" }
        $actual=(Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash
        if($actual -ne $pair[1]) { throw "SHA256 mismatch for $($pair[0]). Expected $($pair[1]), got $actual" }
        [void]$events.Add("VERIFIED SHA256 $($pair[0]) = $actual")
    }

    Remove-Item -LiteralPath $PreparedConverterDirectory -Recurse -Force -ErrorAction SilentlyContinue
    Ensure-Directory $PreparedConverterDirectory
    & $sevenPath -y x $convPath ("-o"+[IO.Path]::GetFullPath($PreparedConverterDirectory)) *> $null
    if($LASTEXITCODE -ne 0 -or -not (Test-PreparedConverter $PreparedConverterDirectory)) { throw 'Original UUP converter could not be extracted/validated.' }

    $cmd=Join-Path $PreparedConverterDirectory 'convert-UUP.cmd'
    $vr=[regex]::Match([IO.File]::ReadAllText($cmd),'(?im)^@?set\s+uivr=([^\r\n]+)\s*$')
    $rev=if($vr.Success){$vr.Groups[1].Value.Trim()}else{'unknown'}
    [void]$events.Add("Prepared converter from ORIGINAL files\converter_windows; revision=$rev")
    [void]$events.Add("aria2c SHA256 = $((Get-FileHash -LiteralPath $aria2 -Algorithm SHA256).Hash)")

    $events | Set-Content -LiteralPath $LogPath -Encoding UTF8
    $events | ForEach-Object { Write-Host "[OK] $_" -ForegroundColor Green }
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Set-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
