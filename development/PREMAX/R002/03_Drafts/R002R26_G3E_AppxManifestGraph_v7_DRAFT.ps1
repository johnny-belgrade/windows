# BlueLite R002R26-G3E v7 DRAFT: integrated G3D strict ZIP central guards and decompressed XML CRC; NOT CERTIFIED.
# Verify reads only 31 SHA1-pinned historic cache package files; creates one NEW evidence JSON.
[CmdletBinding()]
param(
    [ValidateSet('SelfTest','Verify')][string]$Mode = 'SelfTest',
    [string]$MatrixPath = 'C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\02_Analysis\R002R26_G1_9807_SourceProviderChecksum_Matrix_20261024.json'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
$Cycle = 'C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$Cache = 'C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\UUPs'
$F4 = Join-Path $Cycle '05_Evidence\R002R26_F_HistoricCache_SHA1_001\R002R26_F_ReuseGate.json'
$F4Sha = '8989870BADFEA64A3675E2AF22B4C29AC631CA222D6D8BD14CBAF5416D45084A'
$R23Sha = '0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6'
$Report = Join-Path $Cycle '05_Evidence\R002R26_G3_AppxGraph_001\R002R26_G3_Graph.json'
$MaxEntries = 4096
$MaxArchiveExpanded = 268435456L
$MaxManifest = 4194304L
$MaxNested = 134217728L
function Hold([string]$Code) { throw "G3_HOLD_$Code" }
function Assert-Leaf([string]$Name) {
    if ($Name -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._-]{0,180}\.(appx|msix|appxbundle|msixbundle)$') { Hold 'UNSAFE_SOURCE_LEAF' }
}
function Assert-Entry([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name) -or $Name.Length -gt 512 -or
        $Name.Contains('\') -or $Name.Contains(':') -or $Name.StartsWith('/') -or
        $Name.Contains('//') -or $Name -match '(^|/)\.{1,2}(/|$)' -or
        $Name -match '[\x00-\x1F]') { Hold 'ZIP_UNSAFE_ENTRY_PATH' }
}
function Parse-Manifest([byte[]]$Bytes, [string]$Kind) {
    if ($Bytes.Length -eq 0 -or $Bytes.Length -gt $MaxManifest) { Hold 'MANIFEST_SIZE' }
    $settings = [System.Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $settings.MaxCharactersInDocument = $MaxManifest
    $settings.MaxCharactersFromEntities = 0L
    $ms = [System.IO.MemoryStream]::new($Bytes, $false)
    try {
        $reader = [System.Xml.XmlReader]::Create($ms, $settings)
        try {
            $doc = [System.Xml.XmlDocument]::new()
            $doc.XmlResolver = $null
            try { $doc.Load($reader) } catch { Hold 'XML_REJECTED' }
        } finally { $reader.Dispose() }
    } finally { $ms.Dispose() }
    $root = $doc.DocumentElement
    if ($null -eq $root -or $root.LocalName -cne $Kind) { Hold 'UNSUPPORTED_MANIFEST_NAMESPACE' }
    if ($Kind -ceq 'Package') {
        if ($root.NamespaceURI -cnotmatch '^http://schemas\.microsoft\.com/appx/(?:manifest/[A-Za-z0-9-]+(?:/[A-Za-z0-9-]+)*|20[0-9]{2}/manifest(?:/[A-Za-z0-9-]+)*)$') { Hold 'UNSUPPORTED_MANIFEST_NAMESPACE' }
    } else {
        if ($root.NamespaceURI -cnotmatch '^http://schemas\.microsoft\.com/appx/(?:20[0-9]{2}/bundle(?:/[A-Za-z0-9-]+)*|bundle(?:/[A-Za-z0-9-]+)*)$') { Hold 'UNSUPPORTED_MANIFEST_NAMESPACE' }
    }
    foreach ($el in $doc.GetElementsByTagName('*')) {
        if ($el.NamespaceURI -eq 'http://www.w3.org/2001/XInclude') { Hold 'XML_XINCLUDE' }
    }
    return $doc
}
function Get-Identity([System.Xml.XmlElement]$Root, [bool]$Bundle) {
    $id = $Root.SelectSingleNode("./*[local-name()='Identity']")
    if ($null -eq $id) { Hold 'IDENTITY_MISSING' }
    $name = [string]$id.GetAttribute('Name')
    $publisher = [string]$id.GetAttribute('Publisher')
    $v = [string]$id.GetAttribute('Version')
    $arch = if ($Bundle) { 'bundle' } else { [string]$id.GetAttribute('ProcessorArchitecture') }
    if ($name -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_.-]{0,150}$' -or
        [string]::IsNullOrWhiteSpace($publisher) -or $publisher.Length -gt 512 -or
        $v -cnotmatch '^\d{1,5}(\.\d{1,5}){3}$' -or
        $arch -notin @('bundle','x64','neutral','x86','arm64')) { Hold 'IDENTITY_INVALID' }
    try { $parsed = [version]$v } catch { Hold 'IDENTITY_VERSION_INVALID' }
    return [pscustomobject]@{Name=$name;Publisher=$publisher.Trim();Version=$v;ParsedVersion=$parsed;Arch=$arch;ResourceId=[string]$id.GetAttribute('ResourceId')}
}
function Read-EntryBytes([System.IO.Compression.ZipArchiveEntry]$Entry, [long]$Limit) {
    if ($Entry.Length -le 0 -or $Entry.Length -gt $Limit) { Hold 'ZIP_ENTRY_SIZE_LIMIT' }
    if ($Entry.CompressedLength -eq 0 -or ($Entry.Length / [math]::Max(1,$Entry.CompressedLength)) -gt 1000) { Hold 'ZIP_EXPANSION_LIMIT' }
    $m = [System.IO.MemoryStream]::new()
    try {
        $stream = $Entry.Open()
        try {
            $buffer = [byte[]]::new(65536)
            [long]$n = 0
            while (($read = $stream.Read($buffer,0,$buffer.Length)) -gt 0) {
                $n += $read
                if ($n -gt $Limit) { Hold 'ZIP_RUNTIME_EXPANSION_LIMIT' }
                $m.Write($buffer,0,$read)
            }
            if ($n -ne $Entry.Length) { Hold 'ZIP_ENTRY_LENGTH_MISMATCH' }
            return $m.ToArray()
        } finally { $stream.Dispose() }
    } finally { $m.Dispose() }
}

function Assert-ZipBudget([object[]]$Entries,[long]$Limit) {
    [long]$total = 0
    foreach ($entry in $Entries) {
        [long]$length = $entry.Length
        if ($length -lt 0 -or $length -gt $Limit -or $total -gt ($Limit - $length)) { Hold 'ZIP_CUMULATIVE_SIZE_LIMIT' }
        $total += $length
    }
}
function Assert-SourceContract([object]$Matrix,[object]$Seed) {
    if ($Matrix.source_build -cne '26300.9807' -or
        $Matrix.source_uuid -cne '687d1ced-aab1-4cd5-ad05-705189769731' -or
        $Matrix.source_inventory_sha256 -cne $R23Sha -or
        $Seed.target_build -cne $Matrix.source_build -or
        $Seed.target_uuid -cne $Matrix.source_uuid -or
        @($Seed.files).Count -ne 26 -or @($Matrix.provider_records).Count -ne 5) { Hold 'SOURCE_RECORD_CONTRACT' }
}
function Assert-MatchedSha1([string]$Expected,[string]$Actual) {
    if ($Expected -cnotmatch '^[A-F0-9]{40}$' -or $Actual -cnotmatch '^[A-F0-9]{40}$' -or $Expected -cne $Actual) { Hold 'SOURCE_SHA1_MISMATCH' }
}

function G3E-U16([byte[]]$B,[int]$O) {
    if ($O -lt 0 -or $O -gt ($B.Length-2)) { Hold 'ZIP_TRUNCATED_FIELD' }
    return [BitConverter]::ToUInt16($B,$O)
}
function G3E-U32([byte[]]$B,[int]$O) {
    if ($O -lt 0 -or $O -gt ($B.Length-4)) { Hold 'ZIP_TRUNCATED_FIELD' }
    return [BitConverter]::ToUInt32($B,$O)
}
function G3E-EOCD([byte[]]$B) {
    if ($B.Length -lt 22) { Hold 'ZIP_EOCD_MISSING' }
    $low=[Math]::Max(0,$B.Length-65557)
    for([int]$i=$B.Length-22;$i -ge $low;$i--) {
        if((G3E-U32 $B $i) -eq 0x06054b50) {
            if((G3E-U16 $B ($i+20)) -ne ($B.Length-$i-22)) { continue }
            return $i
        }
    }
    Hold 'ZIP_EOCD_MISSING'
}
function G3E-Crc32Bytes([byte[]]$Bytes) {
    [uint32]$crc=[uint32]::MaxValue
    foreach($b in $Bytes) {
        $crc=[uint32]($crc -bxor [uint32]$b)
        for($i=0;$i -lt 8;$i++) {
            if(($crc -band [uint32]1) -ne 0) {
                $crc=[uint32](($crc -shr 1) -bxor [uint32]3988292384)
            } else { $crc=[uint32]($crc -shr 1) }
        }
    }
    return [uint32]($crc -bxor [uint32]::MaxValue)
}
function G3E-Check-ZipCentral([byte[]]$B) {
    $end=G3E-EOCD $B
    if((G3E-U16 $B ($end+4)) -ne 0 -or (G3E-U16 $B ($end+6)) -ne 0) { Hold 'ZIP_MULTIDISK_UNSUPPORTED' }
    $onDisk=G3E-U16 $B ($end+8);$total=G3E-U16 $B ($end+10)
    [uint32]$size=G3E-U32 $B ($end+12);[uint32]$start=G3E-U32 $B ($end+16)
    if($onDisk -eq 65535 -or $total -eq 65535 -or $size -eq [uint32]::MaxValue -or $start -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
    if($total -lt 1 -or $total -gt 4096 -or $onDisk -ne $total) { Hold 'ZIP_CENTRAL_COUNT' }
    if(([long]$start+[long]$size) -ne $end) { Hold 'ZIP_CENTRAL_LAYOUT' }
    $map=[System.Collections.Generic.Dictionary[string,uint32]]::new([StringComparer]::OrdinalIgnoreCase)
    $at=[int]$start
    for($entry=0;$entry -lt $total;$entry++) {
        if(([long]$at+46) -gt $end -or (G3E-U32 $B $at) -ne 0x02014b50) { Hold 'ZIP_CENTRAL_HEADER' }
        $flags=G3E-U16 $B ($at+8);$method=G3E-U16 $B ($at+10)
        if(($flags -band 0x0041) -ne 0) { Hold 'ZIP_ENCRYPTED_UNSUPPORTED' }
        if(($flags -band 0xF7F0) -ne 0) { Hold 'ZIP_FLAGS_UNSUPPORTED' }
        if($method -notin @(0,8)) { Hold 'ZIP_METHOD_UNSUPPORTED' }
        [uint32]$expectCrc=G3E-U32 $B ($at+16)
        [uint32]$packed=G3E-U32 $B ($at+20);[uint32]$plain=G3E-U32 $B ($at+24)
        [int]$nameLen=G3E-U16 $B ($at+28);[int]$extraLen=G3E-U16 $B ($at+30);[int]$commentLen=G3E-U16 $B ($at+32)
        if($packed -eq [uint32]::MaxValue -or $plain -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
        if((G3E-U16 $B ($at+34)) -ne 0) { Hold 'ZIP_MULTIDISK_UNSUPPORTED' }
        [uint32]$local=G3E-U32 $B ($at+42)
        if($local -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
        $next=[long]$at+46+$nameLen+$extraLen+$commentLen
        if($next -gt $end) { Hold 'ZIP_CENTRAL_HEADER' }
        if(([long]$local+30) -gt $at -or (G3E-U32 $B ([int]$local)) -ne 0x04034b50) { Hold 'ZIP_LOCAL_HEADER' }
        if((G3E-U16 $B ([int]$local+6)) -ne $flags -or (G3E-U16 $B ([int]$local+8)) -ne $method) { Hold 'ZIP_LOCAL_CENTRAL_MISMATCH' }
        if(($flags -band 8) -eq 0 -and (G3E-U32 $B ([int]$local+14)) -ne $expectCrc) { Hold 'ZIP_LOCAL_CRC_MISMATCH' }
        [int]$localName=G3E-U16 $B ([int]$local+26);[int]$localExtra=G3E-U16 $B ([int]$local+28)
        if($localName -ne $nameLen) { Hold 'ZIP_LOCAL_CENTRAL_MISMATCH' }
        [long]$offset=[long]$local+30+$localName+$localExtra
        if(($offset+[long]$packed) -gt $at) { Hold 'ZIP_LOCAL_DATA_RANGE' }
        if($method -eq 0 -and $plain -ne $packed) { Hold 'ZIP_STORED_SIZE_UNSUPPORTED' }
        if($nameLen -lt 1) { Hold 'ZIP_ENTRY_NAME_EMPTY' }
        [byte[]]$memberRaw=[byte[]]::new($nameLen)
        [Array]::Copy($B,$at+46,$memberRaw,0,$nameLen)
        if(($flags -band 0x0800) -ne 0) {
            try { $member=[Text.UTF8Encoding]::new($false,$true).GetString($memberRaw) }
            catch { Hold 'ZIP_ENTRY_ENCODING_UNSUPPORTED' }
        } else {
            foreach($byte in $memberRaw) { if($byte -gt 127) { Hold 'ZIP_ENTRY_ENCODING_UNSUPPORTED' } }
            $member=[Text.Encoding]::ASCII.GetString($memberRaw)
        }
        Assert-Entry $member
        if($map.ContainsKey($member)) { Hold 'ZIP_DUPLICATE_CASEFOLD_ENTRY' }
        [byte[]]$localRaw=[byte[]]::new($localName)
        [Array]::Copy($B,([int]$local+30),$localRaw,0,$localName)
        for([int]$k=0;$k -lt $nameLen;$k++) {
            if($memberRaw[$k] -ne $localRaw[$k]) { Hold 'ZIP_LOCAL_CENTRAL_MISMATCH' }
        }
        $extAt=$at+46+$nameLen; $extEnd=$extAt+$extraLen
        while($extAt -lt $extEnd) {
            if(($extAt+4) -gt $extEnd) { Hold 'ZIP_EXTRA_FIELD_MALFORMED' }
            $extraId=G3E-U16 $B $extAt;$extraSize=G3E-U16 $B ($extAt+2)
            if(($extAt+4+$extraSize) -gt $extEnd) { Hold 'ZIP_EXTRA_FIELD_MALFORMED' }
            if($extraId -eq 1) { Hold 'ZIP64_UNSUPPORTED' }
            $extAt+=4+$extraSize
        }
        $map.Add($member,$expectCrc)
        $at=[int]$next
    }
    if($at -ne $end) { Hold 'ZIP_CENTRAL_LAYOUT' }
    return $map
}


function G3E-ReadCentral([System.IO.Stream]$SourceStream) {
    if(-not $SourceStream.CanSeek -or -not $SourceStream.CanRead) { Hold 'ZIP_SOURCE_NOT_SEEKABLE' }
    [long]$len=$SourceStream.Length
    if($len -lt 22 -or $len -gt 268435456L) { Hold 'ZIP_SOURCE_SIZE_LIMIT' }
    [byte[]]$raw=[byte[]]::new([int]$len)
    $SourceStream.Position=0
    [int]$at=0
    while($at -lt $raw.Length) {
        [int]$n=$SourceStream.Read($raw,$at,$raw.Length-$at)
        if($n -le 0) { Hold 'ZIP_SOURCE_SHORT_READ' }
        $at+=$n
    }
    $SourceStream.Position=0
    return (G3E-Check-ZipCentral $raw)
}
function G3E-ManifestBytes([System.IO.Compression.ZipArchiveEntry]$Entry,[uint32]$Expected) {
    [byte[]]$bytes=Read-EntryBytes $Entry $MaxManifest
    if((G3E-Crc32Bytes $bytes) -ne $Expected) { Hold 'ZIP_MANIFEST_CRC_MISMATCH' }
    return ,$bytes
}

function Read-Archive([System.IO.Stream]$SourceStream, [string]$Origin, [int]$Depth) {
    if ($Depth -gt 1) { Hold 'BUNDLE_NESTING_DEPTH' }
    $central=G3E-ReadCentral $SourceStream
    try { $z = [System.IO.Compression.ZipArchive]::new($SourceStream, [System.IO.Compression.ZipArchiveMode]::Read, $true) }
    catch { Hold 'INVALID_ZIP' }
    try {
        if ($z.Entries.Count -lt 1 -or $z.Entries.Count -gt $MaxEntries) { Hold 'ZIP_ENTRY_COUNT' }
        Assert-ZipBudget @($z.Entries) $MaxArchiveExpanded
        if($z.Entries.Count -ne $central.Count) { Hold 'ZIP_CENTRAL_ARCHIVE_COUNT_MISMATCH' }
        $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $byName = [System.Collections.Generic.Dictionary[string,System.IO.Compression.ZipArchiveEntry]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($e in $z.Entries) {
            Assert-Entry $e.FullName
            if(-not $central.ContainsKey($e.FullName)) { Hold 'ZIP_CENTRAL_ARCHIVE_NAME_MISMATCH' }
            if (-not $seen.Add($e.FullName)) { Hold 'ZIP_DUPLICATE_CASEFOLD_ENTRY' }
            $byName.Add($e.FullName,$e)
        }
        $bundlePath='AppxMetadata/AppxBundleManifest.xml'
        if ($byName.ContainsKey($bundlePath)) {
            if ($Depth -ne 0 -or $byName.ContainsKey('AppxManifest.xml')) { Hold 'BUNDLE_UNSUPPORTED_LAYOUT' }
            $doc = Parse-Manifest (G3E-ManifestBytes $byName[$bundlePath] $central[$bundlePath]) 'Bundle'
            $identity = Get-Identity $doc.DocumentElement $true
            $children = @($doc.SelectNodes("/*[local-name()='Bundle']/*[local-name()='Packages']/*[local-name()='Package']"))
            if ($children.Count -lt 1 -or $children.Count -gt 256) { Hold 'BUNDLE_CHILD_COUNT' }
            $output = [System.Collections.Generic.List[object]]::new()
            $childNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($child in $children) {
                $fn=[string]$child.GetAttribute('FileName')
                Assert-Leaf $fn
                if (-not $childNames.Add($fn)) { Hold 'BUNDLE_DUPLICATE_CHILD' }
                if (-not $byName.ContainsKey($fn)) { Hold 'BUNDLE_CHILD_MISSING' }
                if ($byName[$fn].Length -gt $MaxNested) { Hold 'BUNDLE_CHILD_TOO_LARGE' }
                $raw = Read-EntryBytes $byName[$fn] $MaxNested
                $nested = [System.IO.MemoryStream]::new($raw, $false)
                try { $members = @(Read-Archive $nested "$Origin/$fn" ($Depth+1)) }
                finally { $nested.Dispose() }
                if ($members.Count -ne 1) { Hold 'BUNDLE_CHILD_AMBIGUOUS' }
                $m=$members[0]
                $declArch=[string]$child.GetAttribute('Architecture')
                if ($m.Name -cne $identity.Name -or $m.Publisher -cne $identity.Publisher -or
                    $m.Version -cne $identity.Version -or
                    ($declArch -ne '' -and $declArch -cne $m.Arch)) { Hold 'BUNDLE_CHILD_IDENTITY_MISMATCH' }
                $output.Add($m)
            }
            return $output.ToArray()
        }
        if (-not $byName.ContainsKey('AppxManifest.xml')) { Hold 'PACKAGE_MANIFEST_MISSING' }
        $doc=Parse-Manifest (G3E-ManifestBytes $byName['AppxManifest.xml'] $central['AppxManifest.xml']) 'Package'
        $id=Get-Identity $doc.DocumentElement $false
        $deps=[System.Collections.Generic.List[object]]::new()
        $dNodes=@($doc.SelectNodes("/*[local-name()='Package']/*[local-name()='Dependencies']/*"))
        foreach ($dn in $dNodes) {
            if ($dn.LocalName -eq 'PackageDependency') {
                $n=[string]$dn.GetAttribute('Name');$p=[string]$dn.GetAttribute('Publisher');$v=[string]$dn.GetAttribute('MinVersion')
                if ([string]::IsNullOrWhiteSpace($n) -or [string]::IsNullOrWhiteSpace($p) -or
                    $v -cnotmatch '^\d{1,5}(\.\d{1,5}){3}$') { Hold 'DEPENDENCY_IDENTITY_INVALID' }
                try { $pv=[version]$v } catch { Hold 'DEPENDENCY_VERSION_INVALID' }
                $deps.Add([pscustomobject]@{Name=$n;Publisher=$p.Trim();MinVersion=$v;RequiredVersion=$pv})
            } elseif ($dn.LocalName -notin @('TargetDeviceFamily','OSMinVersion','OSMaxVersionTested')) {
                Hold 'UNSUPPORTED_DEPENDENCY_ELEMENT'
            }
        }
        $frame=$doc.SelectSingleNode("/*[local-name()='Package']/*[local-name()='Properties']/*[local-name()='Framework']")
        $framework = $null -ne $frame -and $frame.InnerText.Trim().ToLowerInvariant() -eq 'true'
        return ,([pscustomobject]@{Origin=$Origin;Name=$id.Name;Publisher=$id.Publisher;Version=$id.Version;ParsedVersion=$id.ParsedVersion;Arch=$id.Arch;ResourceId=$id.ResourceId;Framework=$framework;Dependencies=@($deps.ToArray())})
    } finally { $z.Dispose() }
}
function Resolve-Edges([object[]]$Packages) {
    $edges=[System.Collections.Generic.List[object]]::new()
    foreach ($consumer in $Packages) {
        foreach ($dep in $consumer.Dependencies) {
            $n=@($Packages | Where-Object { $_.Name -ceq $dep.Name })
            $p=@($n | Where-Object { $_.Publisher -ceq $dep.Publisher })
            $v=@($p | Where-Object { $_.ParsedVersion -ge $dep.RequiredVersion })
            $a=@($v | Where-Object { $_.Arch -eq 'neutral' -or $_.Arch -eq $consumer.Arch })
            $result = if ($n.Count -eq 0) {'MISSING_PROVIDER'} elseif ($p.Count -eq 0) {'WRONG_PUBLISHER'} elseif ($v.Count -eq 0) {'VERSION_BELOW_MINIMUM'} elseif ($a.Count -eq 0) {'ARCH_MISMATCH'} elseif ($a.Count -gt 1) {'AMBIGUOUS_DUPLICATE'} else {'PROVEN_PROVIDER'}
            $edges.Add([pscustomobject]@{consumer=$consumer.Name;consumer_arch=$consumer.Arch;provider=$dep.Name;required_publisher=$dep.Publisher;minimum_version=$dep.MinVersion;result=$result;resolved=if($a.Count -eq 1){$a[0].Origin}else{$null}})
        }
    }
    return $edges.ToArray()
}
function Expect-Hold([scriptblock]$Action,[string]$Expected) {
    try { & $Action; Hold "SELFTEST_FALSE_ACCEPT_$Expected" }
    catch {
        $actual=[string]$_.Exception.Message
        if ($actual -cne "G3_HOLD_$Expected") { throw "SELFTEST_WRONG_REJECTION expected=$Expected actual=$actual" }
    }
}
function New-SyntheticZip([object[]]$Rows) {
    $mem=[System.IO.MemoryStream]::new()
    try {
        $zip=[System.IO.Compression.ZipArchive]::new($mem,[System.IO.Compression.ZipArchiveMode]::Create,$true)
        try {
            foreach ($row in $Rows) {
                $entry=$zip.CreateEntry([string]$row.Name,[System.IO.Compression.CompressionLevel]::Optimal)
                $stream=$entry.Open()
                try {
                    [byte[]]$data=$row.Bytes
                    if ($data.Length -gt 0) {$stream.Write($data,0,$data.Length)}
                } finally {$stream.Dispose()}
            }
        } finally {$zip.Dispose()}
        return ,([byte[]]$mem.ToArray())
    } finally {$mem.Dispose()}
}
function Expect-SyntheticZipHold([object[]]$Rows,[string]$Expected) {
    [byte[]]$raw=New-SyntheticZip $Rows
    $stream=[System.IO.MemoryStream]::new($raw,$false)
    try {Expect-Hold { [void](Read-Archive $stream 'synthetic.appx' 0) } $Expected}
    finally {$stream.Dispose()}
}
function SelfTest {
    $passed=0
    Expect-Hold { Assert-Leaf '../evil.appx' } 'UNSAFE_SOURCE_LEAF';$passed++
    Expect-Hold { Assert-Entry '../evil.xml' } 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-Hold { Assert-Entry 'C:\evil' } 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-Hold { Parse-Manifest ([Text.Encoding]::UTF8.GetBytes('<!DOCTYPE Package [<!ENTITY x SYSTEM "file:///C:/secret">]><Package>&x;</Package>')) 'Package' } 'XML_REJECTED';$passed++
    Expect-Hold { Parse-Manifest ([Text.Encoding]::UTF8.GetBytes('<Package xmlns="urn:unknown"/>')) 'Package' } 'UNSUPPORTED_MANIFEST_NAMESPACE';$passed++
    Expect-Hold { Parse-Manifest ([byte[]]::new(0)) 'Package' } 'MANIFEST_SIZE';$passed++
    Expect-Hold { Get-Identity ([xml]'<Package />').DocumentElement $false } 'IDENTITY_MISSING';$passed++
    $root=([xml]'<Package><Identity Name="Foo" Publisher="CN=X" Version="broken" ProcessorArchitecture="x64"/></Package>').DocumentElement
    Expect-Hold { Get-Identity $root $false } 'IDENTITY_INVALID';$passed++
    $bad = [System.IO.MemoryStream]::new([byte[]](1,2,3,4),$false)
    try { Expect-Hold { Read-Archive $bad 'x.appx' 0 } 'ZIP_SOURCE_SIZE_LIMIT';$passed++ } finally {$bad.Dispose()}
    $provider=[pscustomobject]@{Name='Contoso.Framework';Publisher='CN=Microsoft';ParsedVersion=[version]'1.0.0.0';Arch='x64';Origin='fixture.framework';Dependencies=@()}
    $consumer=[pscustomobject]@{Name='Contoso.Consumer';Publisher='CN=Consumer';Arch='x64';Dependencies=@([pscustomobject]@{Name='Contoso.Framework';Publisher='CN=Microsoft';MinVersion='2.0.0.0';RequiredVersion=[version]'2.0.0.0'})}
    $edge=@(Resolve-Edges @($provider,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'VERSION_BELOW_MINIMUM') { throw 'SELFTEST_VERSION_NEGATIVE_FAILED' };$passed++
    $consumer.Dependencies[0].RequiredVersion=[version]'1.0.0.0'
    $consumer.Dependencies[0].Publisher='CN=Wrong'
    $edge=@(Resolve-Edges @($provider,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'WRONG_PUBLISHER') { throw 'SELFTEST_PUBLISHER_NEGATIVE_FAILED' };$passed++
    $consumer.Dependencies[0].Publisher='CN=Microsoft'
    $provider.Arch='arm64'
    $edge=@(Resolve-Edges @($provider,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'ARCH_MISMATCH') { throw 'SELFTEST_ARCH_NEGATIVE_FAILED' };$passed++

    # G3B source-only, zero-file synthetic ZIP/XML/bundle/provider fixtures; exact rejection codes.
    $ns='http://schemas.microsoft.com/appx/manifest/foundation/windows10'
    $bn='http://schemas.microsoft.com/appx/2013/bundle'
    $pkg="<Package xmlns='$ns'><Identity Name='Contoso.Test' Publisher='CN=Demo' Version='1.0.0.0' ProcessorArchitecture='x64'/></Package>"
    $pkgBytes=[Text.Encoding]::UTF8.GetBytes($pkg)
    $manifestRow=@{Name='AppxManifest.xml';Bytes=$pkgBytes}
    Expect-SyntheticZipHold @(@{Name='NoManifest.txt';Bytes=[byte[]](1)}) 'PACKAGE_MANIFEST_MISSING';$passed++
    Expect-SyntheticZipHold @($manifestRow,$manifestRow) 'ZIP_DUPLICATE_CASEFOLD_ENTRY';$passed++
    Expect-SyntheticZipHold @($manifestRow,@{Name='appxmanifest.XML';Bytes=$pkgBytes}) 'ZIP_DUPLICATE_CASEFOLD_ENTRY';$passed++
    Expect-SyntheticZipHold @(@{Name='../escape.txt';Bytes=[byte[]](1)},$manifestRow) 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-SyntheticZipHold @(@{Name='/absolute.txt';Bytes=[byte[]](1)},$manifestRow) 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-SyntheticZipHold @(@{Name='dir\wrong.txt';Bytes=[byte[]](1)},$manifestRow) 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-SyntheticZipHold @(@{Name='C:wrong.txt';Bytes=[byte[]](1)},$manifestRow) 'ZIP_UNSAFE_ENTRY_PATH';$passed++
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[byte[]]::new(0)}) 'ZIP_ENTRY_SIZE_LIMIT';$passed++
    Expect-Hold {Parse-Manifest ([byte[]]::new([int]($MaxManifest+1))) 'Package'} 'MANIFEST_SIZE';$passed++
    $badVersion=$pkg.Replace("Version='1.0.0.0'","Version='bad.version'")
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($badVersion)}) 'IDENTITY_INVALID';$passed++
    $missingIdentity="<Package xmlns='$ns'/>"
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($missingIdentity)}) 'IDENTITY_MISSING';$passed++
    $xmlWithXInclude=$pkg.Replace('</Package>',"<xi:include xmlns:xi='http://www.w3.org/2001/XInclude' href='file:///C:/secret'/></Package>")
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($xmlWithXInclude)}) 'XML_XINCLUDE';$passed++
    $wrongNs="<Package xmlns='urn:wrong'><Identity Name='Contoso.Test' Publisher='CN=Demo' Version='1.0.0.0' ProcessorArchitecture='x64'/></Package>"
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($wrongNs)}) 'UNSUPPORTED_MANIFEST_NAMESPACE';$passed++
    $badDependency=$pkg.Replace('</Package>',"<Dependencies><UnsupportedItem /></Dependencies></Package>")
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($badDependency)}) 'UNSUPPORTED_DEPENDENCY_ELEMENT';$passed++
    $badMin=$pkg.Replace('</Package>',"<Dependencies><PackageDependency Name='Contoso.F' Publisher='CN=Demo' MinVersion='invalid'/></Dependencies></Package>")
    Expect-SyntheticZipHold @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($badMin)}) 'DEPENDENCY_IDENTITY_INVALID';$passed++
    $nestedBytes=New-SyntheticZip @($manifestRow)
    $bundleEmpty="<Bundle xmlns='$bn'><Identity Name='Contoso.Test' Publisher='CN=Demo' Version='1.0.0.0'/><Packages/></Bundle>"
    Expect-SyntheticZipHold @(@{Name='AppxMetadata/AppxBundleManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($bundleEmpty)}) 'BUNDLE_CHILD_COUNT';$passed++
    $bundleOne="<Bundle xmlns='$bn'><Identity Name='Contoso.Test' Publisher='CN=Demo' Version='1.0.0.0'/><Packages><Package FileName='child.appx' Architecture='x64'/></Packages></Bundle>"
    $bundleRow=@{Name='AppxMetadata/AppxBundleManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($bundleOne)}
    Expect-SyntheticZipHold @($bundleRow) 'BUNDLE_CHILD_MISSING';$passed++
    Expect-SyntheticZipHold @($bundleRow,$manifestRow) 'BUNDLE_UNSUPPORTED_LAYOUT';$passed++
    $bundleMismatch=$bundleOne.Replace("Architecture='x64'","Architecture='arm64'")
    Expect-SyntheticZipHold @(@{Name='AppxMetadata/AppxBundleManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($bundleMismatch)},@{Name='child.appx';Bytes=$nestedBytes}) 'BUNDLE_CHILD_IDENTITY_MISMATCH';$passed++
    $bundleDup=$bundleOne.Replace("</Packages>","<Package FileName='child.appx' Architecture='x64'/></Packages>")
    Expect-SyntheticZipHold @(@{Name='AppxMetadata/AppxBundleManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($bundleDup)},@{Name='child.appx';Bytes=$nestedBytes}) 'BUNDLE_DUPLICATE_CHILD';$passed++
    $consumer.Dependencies[0].Name='Absent.Provider'
    $edge=@(Resolve-Edges @($provider,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'MISSING_PROVIDER') { throw 'SELFTEST_MISSING_PROVIDER_NEGATIVE_FAILED' };$passed++
    $consumer.Dependencies[0].Name='Contoso.Framework'
    $provider.Arch='x64'
    $edge=@(Resolve-Edges @($provider,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'PROVEN_PROVIDER') { throw 'SELFTEST_VALID_PROVIDER_CONTROL_FAILED' };$passed++
    $duplicate=[pscustomobject]@{Name='Contoso.Framework';Publisher='CN=Microsoft';ParsedVersion=[version]'1.0.0.0';Arch='x64';Origin='duplicate.framework';Dependencies=@()}
    $edge=@(Resolve-Edges @($provider,$duplicate,$consumer))
    if ($edge.Count -ne 1 -or $edge[0].result -cne 'AMBIGUOUS_DUPLICATE') { throw 'SELFTEST_DUPLICATE_PROVIDER_NEGATIVE_FAILED' };$passed++

    # G3C additional in-memory-only synthetic guards; exact rejection reasons.
    Expect-Hold { Assert-ZipBudget @([pscustomobject]@{Length=60},[pscustomobject]@{Length=45}) 100 } 'ZIP_CUMULATIVE_SIZE_LIMIT';$passed++
    Expect-Hold { Assert-ZipBudget @([pscustomobject]@{Length=-1}) 100 } 'ZIP_CUMULATIVE_SIZE_LIMIT';$passed++
    Assert-ZipBudget @([pscustomobject]@{Length=60},[pscustomobject]@{Length=40}) 100
    $passed++
    $syntheticMatrix=[pscustomobject]@{source_build='26300.9807';source_uuid='687d1ced-aab1-4cd5-ad05-705189769731';source_inventory_sha256=$R23Sha;provider_records=@(1..5)}
    $syntheticSeed=[pscustomobject]@{target_build='26300.9807';target_uuid='687d1ced-aab1-4cd5-ad05-705189769731';files=@(1..26)}
    Assert-SourceContract $syntheticMatrix $syntheticSeed;$passed++
    $syntheticMatrix.source_build='26300.9711'
    Expect-Hold { Assert-SourceContract $syntheticMatrix $syntheticSeed } 'SOURCE_RECORD_CONTRACT';$passed++
    $syntheticMatrix.source_build='26300.9807'
    $syntheticMatrix.source_uuid='wrong-source-uuid'
    Expect-Hold { Assert-SourceContract $syntheticMatrix $syntheticSeed } 'SOURCE_RECORD_CONTRACT';$passed++
    $syntheticMatrix.source_uuid='687d1ced-aab1-4cd5-ad05-705189769731'
    $syntheticMatrix.source_inventory_sha256='wrong-source-sha'
    Expect-Hold { Assert-SourceContract $syntheticMatrix $syntheticSeed } 'SOURCE_RECORD_CONTRACT';$passed++
    $syntheticMatrix.source_inventory_sha256=$R23Sha
    $syntheticSeed.target_uuid='wrong-target-uuid'
    Expect-Hold { Assert-SourceContract $syntheticMatrix $syntheticSeed } 'SOURCE_RECORD_CONTRACT';$passed++
    $syntheticSeed.target_uuid='687d1ced-aab1-4cd5-ad05-705189769731'
    $syntheticMatrix.provider_records=@(1..4)
    Expect-Hold { Assert-SourceContract $syntheticMatrix $syntheticSeed } 'SOURCE_RECORD_CONTRACT';$passed++
    $syntheticMatrix.provider_records=@(1..5)
    $goodSha='AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
    Expect-Hold { Assert-MatchedSha1 $goodSha 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' } 'SOURCE_SHA1_MISMATCH';$passed++
    Expect-Hold { Assert-MatchedSha1 $goodSha 'BAD' } 'SOURCE_SHA1_MISMATCH';$passed++
    Assert-MatchedSha1 $goodSha $goodSha;$passed++
    $otherName=$pkg.Replace("Name='Contoso.Test'","Name='Contoso.Other'")
    $nameChild=New-SyntheticZip @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($otherName)})
    Expect-SyntheticZipHold @($bundleRow,@{Name='child.appx';Bytes=$nameChild}) 'BUNDLE_CHILD_IDENTITY_MISMATCH';$passed++
    $otherVersion=$pkg.Replace("Version='1.0.0.0'","Version='1.0.0.1'")
    $versionChild=New-SyntheticZip @(@{Name='AppxManifest.xml';Bytes=[Text.Encoding]::UTF8.GetBytes($otherVersion)})
    Expect-SyntheticZipHold @($bundleRow,@{Name='child.appx';Bytes=$versionChild}) 'BUNDLE_CHILD_IDENTITY_MISMATCH';$passed++
    $nestedBundle=New-SyntheticZip @($bundleRow)
    Expect-SyntheticZipHold @($bundleRow,@{Name='child.appx';Bytes=$nestedBundle}) 'BUNDLE_UNSUPPORTED_LAYOUT';$passed++
    Write-Output "PASS_R002R26_G3C_STATIC_SELFTEST_$($passed)_SYNTHETIC_FIXTURES_NOT_SOURCE_GRAPH"


}
function Verify {
    if (-not (Test-Path -LiteralPath $F4 -PathType Leaf) -or
        (Get-FileHash -LiteralPath $F4 -Algorithm SHA256).Hash -cne $F4Sha) { Hold 'F4_SOURCE_SHA256' }
    if (-not (Test-Path -LiteralPath $MatrixPath -PathType Leaf)) { Hold 'G1_MATRIX_MISSING' }
    $matrix=Get-Content -LiteralPath $MatrixPath -Raw -Encoding utf8 | ConvertFrom-Json
    $f4=Get-Content -LiteralPath $F4 -Raw -Encoding utf8 | ConvertFrom-Json
    Assert-SourceContract $matrix $f4
    $pins=[System.Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($rec in @($f4.files)+@($matrix.provider_records)) {
        $name=[string]$rec.out;Assert-Leaf $name
        $sha=if ($rec.PSObject.Properties.Name -contains 'expected_sha1') {[string]$rec.expected_sha1} else {''}
        if ($sha -cnotmatch '^[A-F0-9]{40}$' -or $pins.ContainsKey($name)) { Hold 'SOURCE_SHA1_OR_DUPLICATE' }
        $pins.Add($name,$sha)
    }
    if ($pins.Count -ne 31 -or (Test-Path -LiteralPath $Report)) { Hold 'OUTPUT_OR_CARDINALITY' }
    $root=[System.IO.Path]::GetFullPath($Cache).TrimEnd('\') + '\'
    $packages=[System.Collections.Generic.List[object]]::new()
    foreach ($kv in $pins.GetEnumerator()) {
        $path=[System.IO.Path]::GetFullPath((Join-Path $Cache $kv.Key))
        if (-not $path.StartsWith($root,[StringComparison]::OrdinalIgnoreCase)) { Hold 'SOURCE_PATH_ESCAPE' }
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Hold 'CACHE_FILE_MISSING' }
        Assert-MatchedSha1 $kv.Value (Get-FileHash -LiteralPath $path -Algorithm SHA1).Hash
        $fs=[System.IO.File]::Open($path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::Read)
        try { foreach ($unit in @(Read-Archive $fs $kv.Key 0)) {$packages.Add($unit)} } finally { $fs.Dispose() }
    }
    $edges=@(Resolve-Edges $packages.ToArray())
    $notProven=@($edges | Where-Object { $_.result -cne 'PROVEN_PROVIDER' })
    $result=if ($notProven.Count -eq 0) {'GRAPH_EDGES_RESOLVED_SOURCE_SCOPED_CAB_SEPARATE'}else{'HOLD_UNRESOLVED_APPX_EDGES'}
    $out=[ordered]@{schema='BlueLite.R002R26.G3.SourceScopedGraph.v1';target_build=$matrix.source_build;source_uuid=$matrix.source_uuid;source_r23_sha256=$R23Sha;packages_transport_count=$pins.Count;manifest_units_count=$packages.Count;dependency_edges_count=$edges.Count;unresolved_count=$notProven.Count;result=$result;packages=@($packages.ToArray());edges=$edges;metadata_cab='NOT_ACQUIRED';network_requests=0;wim_mutation=$false}
    $parent=Split-Path -Parent $Report
    if (Test-Path -LiteralPath $parent) { Hold 'OWNED_EVIDENCE_DEST_EXISTS' }
    [void](New-Item -ItemType Directory -Path $parent)
    $out | ConvertTo-Json -Depth 22 | Set-Content -LiteralPath $Report -Encoding utf8
    Write-Output "G3_REPORT=$Report"
    if ($notProven.Count -gt 0) { Hold "UNRESOLVED_EDGES_$($notProven.Count)" }
    Write-Output "PASS_R002R26_G3_SOURCE_SCOPED_APPX_GRAPH_ONLY_NOT_CAB_OR_WIM"
}
if ($Mode -eq 'SelfTest') { SelfTest } else { Verify }
