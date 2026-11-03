param(
    [Parameter(Mandatory=$true)][string]$OriginalQueueFile,
    [Parameter(Mandatory=$true)][string]$ActiveQueueFile,
    [Parameter(Mandatory=$true)][string]$UUPDirectory,
    [Parameter(Mandatory=$true)][string]$Aria2Path,
    [ValidateSet('amd64','x64')][string]$Architecture = 'amd64',
    [string]$Language = 'en-us',
    [string]$AriaLogPath = '.\BlueLite_Logs\aria2_download.log',
    [string]$OriginalAppsUrl = '',
    [string]$FrozenAppsQueueFile = '.\BlueLite_Logs\AppsQueue.frozen.txt',
    [int]$MaxPasses = 8,
    [string]$LogPath = ".\BlueLite_Logs\ResolveAppDependencies.log"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Split-Aria2Records([string[]]$Lines) {
    $prefix=[System.Collections.Generic.List[string]]::new()
    $records=[System.Collections.Generic.List[object]]::new()
    $cur=[System.Collections.Generic.List[string]]::new()
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
    $o=$Record | Where-Object { $_ -match '^\s*out=' } | Select-Object -First 1
    if ($o) { return ($o -replace '^\s*out=','').Trim().Trim('"') }
    return $null
}

function Write-Aria2Queue([string]$Path,[string[]]$Prefix,[object[]]$Records) {
    $out=[System.Collections.Generic.List[string]]::new()
    foreach ($l in $Prefix) { [void]$out.Add([string]$l) }
    foreach ($obj in $Records) {
        foreach ($l in [string[]]$obj) { [void]$out.Add($l) }
        [void]$out.Add('')
    }
    [IO.File]::WriteAllLines([IO.Path]::GetFullPath($Path),$out.ToArray(),(New-Object Text.UTF8Encoding($false)))
}

function Normalize-PackageToken([string]$Value) {
    if (-not $Value) { return '' }
    $s=[IO.Path]::GetFileName($Value).ToLowerInvariant()
    $s=$s -replace '(?i)\.(msixbundle|appxbundle|msix|appx)$',''
    $s=$s -replace '(?i)_(8wekyb3d8bbwe|cw5n1h2txyewy|kzf8qxf38zg5c|yxz26nhyzhsrt)$',''
    $s=$s -replace '(?i)(^|[._-])(x64|amd64|x86|arm64|arm|neutral)(?=[._-]|$)','$1'
    return ($s -replace '[^a-z0-9]','')
}

function Get-DependencyTokens([string]$Name) {
    $v=[System.Collections.Generic.List[string]]::new()
    if (-not $Name) { return @() }
    [void]$v.Add((Normalize-PackageToken $Name))

    # UUP queue filenames use 14.00 for VCLibs whose package identity is commonly 140.00.
    if ($Name -match '(?i)^Microsoft\.VCLibs\.140\.00(?<tail>.*)$') {
        [void]$v.Add((Normalize-PackageToken ("Microsoft.VCLibs.14.00" + $Matches['tail'])))
    }
    if ($Name -match '(?i)^Microsoft\.VCLibs\.140\.00\.UWPDesktop$') {
        [void]$v.Add((Normalize-PackageToken 'Microsoft.VCLibs.14.00.Desktop'))
    }
    return @($v | Where-Object { $_ } | Select-Object -Unique)
}

function Is-ForeignArchitecture([string]$Name,[string]$Arch) {
    if ($Arch -notin @('amd64','x64')) { return $false }
    return ($Name -match '(?i)(?:^|[._-])(x86|arm64|arm)(?:[._-]|$)')
}

function Is-ForeignLanguage([string]$Name,[string]$TargetLanguage) {
    $target=$TargetLanguage.ToLowerInvariant(); $targetBase=($target -split '-')[0]
    $m=[regex]::Match($Name,'(?i)(?:language[-_]|_language-)([a-z]{2,3}(?:-[a-z0-9]{2,8})*)')
    if (-not $m.Success) { return $false }
    $tag=$m.Groups[1].Value.ToLowerInvariant()
    return -not ($tag -eq $target -or $tag -eq $targetBase)
}

function Get-ManifestFact([string]$XmlText,[string]$Source) {
    try { [xml]$xml=$XmlText } catch { return $null }
    $idNode=$xml.SelectSingleNode("/*[local-name()='Package']/*[local-name()='Identity']")
    if ($null -eq $idNode) { return $null }
    $name=[string]$idNode.GetAttribute('Name')
    if (-not $name) { return $null }

    $deps=[System.Collections.Generic.List[string]]::new()
    $nodes=$xml.SelectNodes("/*[local-name()='Package']/*[local-name()='Dependencies']/*[local-name()='PackageDependency']")
    foreach ($n in @($nodes)) {
        $d=[string]$n.GetAttribute('Name')
        if ($d) { [void]$deps.Add($d) }
    }
    return [pscustomobject]@{ Identity=$name; Dependencies=@($deps | Select-Object -Unique); Source=$Source }
}

function Read-EntryText([System.IO.Compression.ZipArchiveEntry]$Entry) {
    $stream=$Entry.Open()
    try {
        $reader=New-Object IO.StreamReader($stream,[Text.Encoding]::UTF8,$true)
        try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
    }
    finally { $stream.Dispose() }
}

function Get-ArchiveFacts([string]$Path) {
    $facts=[System.Collections.Generic.List[object]]::new()
    $zip=$null
    try {
        $zip=[System.IO.Compression.ZipFile]::OpenRead($Path)
        $manifest=$zip.Entries | Where-Object { $_.FullName -ieq 'AppxManifest.xml' } | Select-Object -First 1
        if ($manifest) {
            $f=Get-ManifestFact (Read-EntryText $manifest) ([IO.Path]::GetFileName($Path))
            if ($f) { [void]$facts.Add($f) }
        }

        # Bundles contain package archives. Parse their inner AppxManifest.xml as well;
        # this keeps the resolver useful even if a future UUP queue stops publishing the
        # architecture package as a separate record.
        foreach ($entry in @($zip.Entries | Where-Object { $_.FullName -match '(?i)\.(appx|msix)$' })) {
            if ($entry.Length -le 0 -or $entry.Length -gt 536870912) { continue }
            $es=$entry.Open()
            $ms=New-Object IO.MemoryStream
            try {
                $es.CopyTo($ms)
                $ms.Position=0
                $inner=[System.IO.Compression.ZipArchive]::new($ms,[System.IO.Compression.ZipArchiveMode]::Read,$true)
                try {
                    $im=$inner.Entries | Where-Object { $_.FullName -ieq 'AppxManifest.xml' } | Select-Object -First 1
                    if ($im) {
                        $f=Get-ManifestFact (Read-EntryText $im) (([IO.Path]::GetFileName($Path)) + '!' + $entry.FullName)
                        if ($f) { [void]$facts.Add($f) }
                    }
                }
                finally { $inner.Dispose() }
            }
            finally { $es.Dispose(); $ms.Dispose() }
        }
    }
    catch {
        # A malformed/non-ZIP payload is not silently treated as a dependency-free package.
        throw "Could not inspect AppX/MSIX archive '$Path': $($_.Exception.Message)"
    }
    finally { if ($zip) { $zip.Dispose() } }
    return @($facts.ToArray())
}


function Get-BundleMemberNames([string]$Path) {
    if ($Path -notmatch '(?i)\.(appxbundle|msixbundle)$') { return @() }
    $zip=$null
    try {
        $zip=[System.IO.Compression.ZipFile]::OpenRead($Path)
        return @($zip.Entries | Where-Object { $_.FullName -match '(?i)\.(appx|msix)$' } | ForEach-Object { [IO.Path]::GetFileName($_.FullName) } | Where-Object { $_ } | Select-Object -Unique)
    }
    finally { if ($zip) { $zip.Dispose() } }
}

function Find-DependencyRecords([string]$Dependency,[object[]]$OriginalRecords,[string]$Arch,[string]$Lang) {
    $tokens=@(Get-DependencyTokens $Dependency)
    if ($tokens.Count -eq 0) { return @() }
    $matched=[System.Collections.Generic.List[object]]::new()
    foreach ($obj in $OriginalRecords) {
        [string[]]$record=$obj
        $name=Get-OutName $record
        if (-not $name -or (Is-ForeignArchitecture $name $Arch) -or (Is-ForeignLanguage $name $Lang)) { continue }
        $n=Normalize-PackageToken $name
        foreach ($t in $tokens) {
            if ($n -eq $t) { [void]$matched.Add($record); break }
        }
    }
    return @($matched.ToArray())
}

try {
    foreach ($p in @($OriginalQueueFile,$ActiveQueueFile,$Aria2Path)) {
        if (-not (Test-Path -LiteralPath $p)) { throw "Required file not found: $p" }
    }
    if (-not (Test-Path -LiteralPath $UUPDirectory)) { throw "UUP directory not found: $UUPDirectory" }
    $ariaLogDir=Split-Path -Parent ([IO.Path]::GetFullPath($AriaLogPath))
    if($ariaLogDir -and -not (Test-Path -LiteralPath $ariaLogDir)) { New-Item -ItemType Directory -Path $ariaLogDir -Force | Out-Null }

    $orig=Split-Aria2Records ([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $OriginalQueueFile)))
    $active=Split-Aria2Records ([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $ActiveQueueFile)))
    if ($orig.Records.Count -eq 0 -or $active.Records.Count -eq 0) { throw 'Original or active Apps queue is empty.' }

    $origByOut=@{}
    foreach ($obj in $orig.Records) {
        [string[]]$r=$obj; $n=Get-OutName $r
        if ($n) { $origByOut[$n.ToLowerInvariant()]=$r }
    }

    $activeRecords=[System.Collections.Generic.List[object]]::new()
    $activeOut=@{}
    foreach ($obj in $active.Records) {
        [string[]]$r=$obj; $n=Get-OutName $r
        if (-not $n) { continue }
        if (-not $origByOut.ContainsKey($n.ToLowerInvariant())) { throw "Active Apps record is not present in original queue: $n" }
        [void]$activeRecords.Add($r); $activeOut[$n.ToLowerInvariant()]=$true
    }

    $events=[System.Collections.Generic.List[string]]::new()
    $unresolved=@{}
    $pass=0
    $converged=$false

    while ($pass -lt $MaxPasses) {
        $pass++
        $facts=[System.Collections.Generic.List[object]]::new()

        foreach ($obj in $activeRecords.ToArray()) {
            [string[]]$r=$obj; $outName=Get-OutName $r
            if (-not $outName -or $outName -notmatch '(?i)\.(appx|msix|appxbundle|msixbundle)$') { continue }
            $leaf=[IO.Path]::GetFileName($outName)
            $path=Join-Path $UUPDirectory $leaf
            if (-not (Test-Path -LiteralPath $path)) { throw "Active AppX payload not downloaded: $leaf" }
            foreach ($f in @(Get-ArchiveFacts $path)) { [void]$facts.Add($f) }
        }

        $identities=@{}
        foreach ($f in $facts) { $identities[[string]$f.Identity]=$true }
        [void]$events.Add("PASS ${pass}: manifests=$($facts.Count), identities=$($identities.Count), activeRecords=$($activeRecords.Count)")

        $additions=[System.Collections.Generic.List[object]]::new()
        $addOut=@{}

        # UUP Apps queues often publish both a bundle and its constituent architecture/resource
        # packages. Derive those members from the selected bundle itself instead of hardcoding
        # versioned aliases. This is part of selected-app closure, not a generic framework keep.
        foreach ($obj in $activeRecords.ToArray()) {
            [string[]]$r=$obj; $outName=Get-OutName $r
            if (-not $outName -or $outName -notmatch '(?i)\.(appxbundle|msixbundle)$') { continue }
            $bundlePath=Join-Path $UUPDirectory ([IO.Path]::GetFileName($outName))
            foreach ($member in @(Get-BundleMemberNames $bundlePath)) {
                $key=$member.ToLowerInvariant()
                if ($activeOut.ContainsKey($key) -or $addOut.ContainsKey($key)) { continue }
                if ($origByOut.ContainsKey($key)) {
                    $mr=[string[]]$origByOut[$key]
                    if (-not (Is-ForeignArchitecture $member $Architecture) -and -not (Is-ForeignLanguage $member $Language)) {
                        [void]$additions.Add($mr); $addOut[$key]=$true
                        [void]$events.Add("ADD bundle member '$outName' -> $member")
                    }
                }
            }
        }

        foreach ($f in $facts) {
            foreach ($dep in @($f.Dependencies)) {
                if ($identities.ContainsKey([string]$dep)) { continue }
                $depMatches=@(Find-DependencyRecords -Dependency ([string]$dep) -OriginalRecords $orig.Records -Arch $Architecture -Lang $Language)
                if ($depMatches.Count -eq 0) {
                    $unresolved[[string]$dep]="declared by $($f.Identity) ($($f.Source)); no Apps-queue payload matched"
                    continue
                }
                foreach ($m in $depMatches) {
                    [string[]]$mr=$m; $n=Get-OutName $mr
                    if (-not $n) { continue }
                    $key=$n.ToLowerInvariant()
                    if ($activeOut.ContainsKey($key) -or $addOut.ContainsKey($key)) { continue }
                    [void]$additions.Add($mr); $addOut[$key]=$true
                    [void]$events.Add("ADD dependency '$dep' -> $n (required by $($f.Identity))")
                }
            }
        }

        if ($additions.Count -eq 0) { $converged=$true; break }

        $tmp=Join-Path (Split-Path -Parent ([IO.Path]::GetFullPath($ActiveQueueFile))) ("AppsDependencies.pass{0}.aria2" -f $pass)
        Write-Aria2Queue -Path $tmp -Prefix @() -Records $additions.ToArray()
        Write-Host "[INFO] App dependency pass ${pass}: downloading $($additions.Count) additional record(s)..." -ForegroundColor Cyan
        & $Aria2Path '--no-conf' '--async-dns=false' '--console-log-level=warn' '--log-level=info' ("--log="+[IO.Path]::GetFullPath($AriaLogPath)) '--allow-overwrite=true' '--auto-file-renaming=false' '-x16' '-s16' '-j12' '-c' '-R' '-d' $UUPDirectory '-i' $tmp
        if ($LASTEXITCODE -ne 0) {
            if (-not $OriginalAppsUrl) { throw "aria2 dependency download failed in pass $pass; original Apps URL is not available for source-bound renewal." }
            Write-Host "[INFO] AppX dependency transfer failed; refreshing SAME UUID and FULL original SHA1 catalog." -ForegroundColor Yellow
            $renew=Join-Path $PSScriptRoot 'BlueLite_RenewQueue.ps1'
            & $renew -Mode Apps -Url $OriginalAppsUrl -ActiveQueueFile $ActiveQueueFile -OriginalQueueFile $OriginalQueueFile -FrozenQueueFile $FrozenAppsQueueFile -LogPath (Join-Path $ariaLogDir 'RenewAppsDependencies.log')
            if ($LASTEXITCODE -ne 0) { throw "Original Apps UUID/content identity changed or renewal failed in dependency pass $pass." }

            # Replace stale source URLs in MEMORY as well as on disk. No change to out/SHA1 identities.
            $orig=Split-Aria2Records ([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $OriginalQueueFile)))
            $origByOut=@{}
            foreach($o in $orig.Records){[string[]]$entry=$o;$key=Get-OutName $entry;if($key){$origByOut[$key.ToLowerInvariant()]=$entry}}
            $active=Split-Aria2Records ([IO.File]::ReadAllLines((Resolve-Path -LiteralPath $ActiveQueueFile)))
            $activeRecords.Clear()
            foreach($o in $active.Records){[void]$activeRecords.Add([string[]]$o)}
            $newAdditions=[System.Collections.Generic.List[object]]::new()
            foreach($oldEntry in $additions.ToArray()){
                [string[]]$oldRecord=$oldEntry
                $name=Get-OutName $oldRecord
                if(-not $name -or -not $origByOut.ContainsKey($name.ToLowerInvariant())){throw "Renewal lost required Apps dependency record: $name"}
                [void]$newAdditions.Add([string[]]$origByOut[$name.ToLowerInvariant()])
            }
            $additions=$newAdditions
            Write-Aria2Queue -Path $tmp -Prefix @() -Records $additions.ToArray()
            & $Aria2Path '--no-conf' '--async-dns=false' '--console-log-level=warn' '--log-level=info' ("--log="+[IO.Path]::GetFullPath($AriaLogPath)) '--allow-overwrite=true' '--auto-file-renaming=false' '-x16' '-s16' '-j12' '-c' '-R' '-d' $UUPDirectory '-i' $tmp
            if ($LASTEXITCODE -ne 0) { throw "aria2 Apps dependency transfer still failed after verified same-UUID renewal in pass ${pass}: $LASTEXITCODE" }
        }

        foreach ($m in $additions.ToArray()) {
            [string[]]$mr=$m; $n=Get-OutName $mr
            [void]$activeRecords.Add($mr); $activeOut[$n.ToLowerInvariant()]=$true
        }
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        Write-Aria2Queue -Path $ActiveQueueFile -Prefix $active.Prefix -Records $activeRecords.ToArray()
    }

    if (-not $converged) { throw "App dependency resolver reached MaxPasses=$MaxPasses without convergence; refusing an unproven closure." }

    Write-Aria2Queue -Path $ActiveQueueFile -Prefix $active.Prefix -Records $activeRecords.ToArray()

    $ldir=Split-Path -Parent $LogPath
    if ($ldir -and -not (Test-Path -LiteralPath $ldir)) { New-Item -ItemType Directory -Path $ldir -Force | Out-Null }
    @(
        'BlueLite v1.0 AppX dependency closure',
        "Original Apps queue records: $($orig.Records.Count)",
        "Final Apps queue records: $($activeRecords.Count)",
        "Passes: $pass",
        "Unresolved external/system dependencies: $($unresolved.Count)",
        '', 'EVENTS:', $events,
        '', 'UNRESOLVED (no matching Apps-queue payload):',
        @($unresolved.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Name) :: $($_.Value)" })
    ) | Set-Content -LiteralPath $LogPath -Encoding UTF8

    Write-Host "[OK] App dependency closure complete: $($activeRecords.Count) / $($orig.Records.Count) Apps records retained." -ForegroundColor Green
    if ($unresolved.Count -gt 0) {
        Write-Host "[INFO] $($unresolved.Count) manifest dependencies had no Apps-queue payload; logged as OS/external dependencies." -ForegroundColor DarkCyan
    }
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    try { $_.Exception.ToString() | Set-Content -LiteralPath $LogPath -Encoding UTF8 } catch {}
    exit 1
}
