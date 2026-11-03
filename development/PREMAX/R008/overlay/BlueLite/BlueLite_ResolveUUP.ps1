param(
    [Parameter(Mandatory=$true)][string]$OriginalLauncherPath,
    [Parameter(Mandatory=$true)][string]$OriginalConfigPath,
    [string]$EnvOutputPath = ".\BlueLite_Logs\ResolvedUUP.env.cmd",
    [string]$JsonOutputPath = ".\BlueLite_Logs\ResolvedUUP.json",
    [string]$ExistingCheckpointPath
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Read-SimpleIni([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { throw "INI not found: $Path" }
    $map=@{}
    foreach($line in Get-Content -LiteralPath $Path) {
        $t=$line.Trim()
        if(-not $t -or $t.StartsWith('#') -or $t.StartsWith(';') -or $t.StartsWith('[')) { continue }
        $i=$t.IndexOf('=')
        if($i -lt 1) { continue }
        $map[$t.Substring(0,$i).Trim()]=$t.Substring($i+1).Trim()
    }
    return $map
}

function Get-QueryValue([string]$Url,[string]$Name) {
    $m=[regex]::Match($Url,'(?i)(?:[?&])'+[regex]::Escape($Name)+'=([^&"\s]+)')
    if(-not $m.Success) { return '' }
    return [uri]::UnescapeDataString($m.Groups[1].Value)
}

function Invoke-UupApi([string]$Url) {
    $old=[Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
        return Invoke-RestMethod -Uri $Url -Method Get -Headers @{ 'User-Agent'='BlueLite-Original-UUP-Resolver/1.1' } -TimeoutSec 90
    }
    finally {
        [Net.ServicePointManager]::SecurityProtocol=$old
    }
}

function Get-PropString($Object,[string]$Name) {
    if($null -eq $Object) { return '' }
    $p=$Object.PSObject.Properties[$Name]
    if($null -eq $p -or $null -eq $p.Value) { return '' }
    return [string]$p.Value
}

try {
    foreach($p in @($OriginalLauncherPath,$OriginalConfigPath)) {
        if(-not (Test-Path -LiteralPath $p)) { throw "Original UUP file not found: $p" }
    }

    $launcher=(Resolve-Path -LiteralPath $OriginalLauncherPath).Path
    $config=(Resolve-Path -LiteralPath $OriginalConfigPath).Path
    $raw=[IO.File]::ReadAllText($launcher)

    if($raw -match '(?i)BlueLite v1\.0|BlueLite TEST|BlueLite Universal') {
        throw 'The source launcher is already a BlueLite-modified launcher. Use the untouched uup_download_windows.cmd from the original UUP Dump ZIP.'
    }

    $urls=@([regex]::Matches($raw,'(?i)https://uupdump\.net/get\.php\?[^"\r\n]+') | ForEach-Object { $_.Value } | Select-Object -Unique)
    if($urls.Count -lt 1) { throw 'No UUP Dump get.php URL was found in the original launcher.' }

    $windowsUrl=''
    $appsUrl=''
    foreach($u in $urls) {
        $ed=(Get-QueryValue $u 'edition').ToLowerInvariant()
        if($ed -eq 'app') { if(-not $appsUrl) { $appsUrl=$u }; continue }
        if($ed) { if(-not $windowsUrl) { $windowsUrl=$u } }
    }
    if(-not $windowsUrl) { throw 'Could not identify the Windows UUP URL in the original launcher.' }

    $uuid=Get-QueryValue $windowsUrl 'id'
    $pack=(Get-QueryValue $windowsUrl 'pack').ToLowerInvariant()
    $edition=(Get-QueryValue $windowsUrl 'edition').ToLowerInvariant()
    if($uuid -notmatch '^[0-9a-fA-F-]{36}(?:_rev\.\d+)?$') { throw "Unexpected original UUP UUID: $uuid" }
    if($pack -ne 'en-us') { throw "BlueLite v1.0 requires original UUP language en-us; original launcher uses '$pack'." }
    if($edition -ne 'professional') { throw "BlueLite v1.0 requires original UUP edition professional; original launcher uses '$edition'." }

    if(-not $appsUrl) {
        $appsUrl="https://uupdump.net/get.php?id=$uuid&pack=neutral&edition=app&aria2=2"
    }

    $cfg=Read-SimpleIni $config
    $required=[ordered]@{
        'AutoStart'='1'
        'AddUpdates'='1'
        'NetFx3'='0'
        'wim2esd'='0'
        'SkipISO'='0'
    }
    foreach($kv in $required.GetEnumerator()) {
        if(-not $cfg.ContainsKey([string]$kv.Key) -or [string]$cfg[[string]$kv.Key] -ne [string]$kv.Value) {
            throw "Original UUP ConvertConfig invariant failed: $($kv.Key) must be $($kv.Value)."
        }
    }

    $launcherHash=(Get-FileHash -LiteralPath $launcher -Algorithm SHA256).Hash
    $configHash=(Get-FileHash -LiteralPath $config -Algorithm SHA256).Hash

    $build=''
    $arch=''
    $title=''
    $ring=''
    $created=''
    $metadataMode='launcher-fallback'

    $bm=[regex]::Match($raw,'(?<!\d)(\d{5}\.\d+)(?!\d)')
    if($bm.Success) { $build=$bm.Groups[1].Value }

    $meta=$null
    try {
        $meta=Invoke-UupApi ("https://api.uupdump.net/updateinfo.php?id="+[uri]::EscapeDataString($uuid)+"&ignoreFiles=1")
    }
    catch {
        Write-Host "[WARN] Exact UUID metadata lookup failed; using original-launcher metadata where possible: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    if($null -ne $meta -and $null -ne $meta.response -and $null -ne $meta.response.info) {
        $info=$meta.response.info
        $apiBuild=Get-PropString $info 'build'
        $apiArch=(Get-PropString $info 'arch').ToLowerInvariant()
        $apiTitle=Get-PropString $info 'title'
        $apiRing=(Get-PropString $info 'ring').ToUpperInvariant()
        $apiCreated=Get-PropString $info 'created'
        if($apiBuild) {
            if($build -and $apiBuild -ne $build) { throw "Original launcher build '$build' disagrees with exact UUID metadata '$apiBuild'." }
            $build=$apiBuild
        }
        if($apiArch) { $arch=$(if($apiArch -eq 'x64'){'amd64'}else{$apiArch}) }
        $title=$apiTitle; $ring=$apiRing; $created=$apiCreated
        $metadataMode='exact UUID metadata validation'
    }

    if($build -notmatch '^\d{5}\.\d+$') { throw "Could not prove a concrete Windows build from the original UUP archive. Detected='$build'." }
    $buildFamily=($build -split '\.')[0]
    if($arch -and $arch -ne 'amd64') { throw "BlueLite v1.0 supports amd64 only; exact UUID metadata reports '$arch'." }
    if(-not $arch) { $arch='amd64' }

    if($ExistingCheckpointPath -and (Test-Path -LiteralPath $ExistingCheckpointPath)) {
        $old=Get-Content -LiteralPath $ExistingCheckpointPath -Raw | ConvertFrom-Json
        if([string]$old.UUP_ID -ne $uuid) { throw 'Existing BlueLite checkpoint belongs to a different original UUP UUID.' }
        if($old.SOURCE_LAUNCHER_SHA256 -and [string]$old.SOURCE_LAUNCHER_SHA256 -ne $launcherHash) { throw 'Existing BlueLite checkpoint belongs to a different original UUP launcher snapshot.' }
    }

    foreach($p in @($EnvOutputPath,$JsonOutputPath)) {
        $d=Split-Path -Parent $p
        if($d -and -not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }

    @(
        '@echo off',
        ('set "UUP_ID={0}"' -f $uuid),
        ('set "UUP_BUILD={0}"' -f $build),
        ('set "UUP_ARCH={0}"' -f $arch),
        ('set "UUP_PACK={0}"' -f $pack),
        ('set "UUP_EDITION={0}"' -f $edition),
        ('set "UUP_WINDOWS_URL={0}"' -f $windowsUrl),
        ('set "UUP_APPS_URL={0}"' -f $appsUrl)
    ) | Set-Content -LiteralPath $EnvOutputPath -Encoding ASCII

    [pscustomobject]@{
        SelectedAtUtc=[DateTime]::UtcNow.ToString('o')
        UUP_ID=$uuid
        UUP_BUILD=$build
        UUP_ARCH=$arch
        UUP_PACK=$pack
        UUP_EDITION=$edition
        UUP_TITLE=$title
        UUP_RING=$ring
        UUP_CREATED=$created
        BUILD_FAMILY=$buildFamily
        SELECTION_MODE='original UUP Dump archive is authoritative; no latest-build selection performed'
        METADATA_MODE=$metadataMode
        SOURCE_LAUNCHER=(Split-Path -Leaf $launcher)
        SOURCE_LAUNCHER_SHA256=$launcherHash
        SOURCE_CONFIG=(Split-Path -Leaf $config)
        SOURCE_CONFIG_SHA256=$configHash
        UUP_WINDOWS_URL=$windowsUrl
        UUP_APPS_URL=$appsUrl
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $JsonOutputPath -Encoding UTF8

    Write-Host "[OK] Original UUP archive target accepted: $build $arch / $pack / $edition" -ForegroundColor Green
    Write-Host "[OK] UUID: $uuid" -ForegroundColor Green
    Write-Host "[INFO] Selection authority: original uup_download_windows.cmd" -ForegroundColor Cyan
    if($ring) { Write-Host "[INFO] Exact UUID metadata ring: $ring (informational only; it did not choose the build)" -ForegroundColor DarkCyan }
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
