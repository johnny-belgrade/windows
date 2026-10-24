# BlueLite R002R26-G3D standalone ZIP central-header negative-fixture DRAFT v1.
# Synthetic in-memory archives only. No real UUP/AppX, WIM, host, report or network access.
[CmdletBinding()]
param([ValidateSet('SelfTest')][string]$Mode='SelfTest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
function Hold([string]$Code) { throw "G3D_HOLD_$Code" }
function U16([byte[]]$B,[int]$O) {
    if ($O -lt 0 -or $O -gt ($B.Length-2)) { Hold 'ZIP_TRUNCATED_FIELD' }
    return [BitConverter]::ToUInt16($B,$O)
}
function U32([byte[]]$B,[int]$O) {
    if ($O -lt 0 -or $O -gt ($B.Length-4)) { Hold 'ZIP_TRUNCATED_FIELD' }
    return [BitConverter]::ToUInt32($B,$O)
}
function EOCD([byte[]]$B) {
    if ($B.Length -lt 22) { Hold 'ZIP_EOCD_MISSING' }
    $low=[Math]::Max(0,$B.Length-65557)
    for([int]$i=$B.Length-22;$i -ge $low;$i--) {
        if((U32 $B $i) -eq 0x06054b50) {
            if((U16 $B ($i+20)) -ne ($B.Length-$i-22)) { continue }
            return $i
        }
    }
    Hold 'ZIP_EOCD_MISSING'
}
function Crc32Bytes([byte[]]$Bytes) {
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
function Check-ZipCentral([byte[]]$B) {
    $end=EOCD $B
    if((U16 $B ($end+4)) -ne 0 -or (U16 $B ($end+6)) -ne 0) { Hold 'ZIP_MULTIDISK_UNSUPPORTED' }
    $onDisk=U16 $B ($end+8);$total=U16 $B ($end+10)
    [uint32]$size=U32 $B ($end+12);[uint32]$start=U32 $B ($end+16)
    if($onDisk -eq 65535 -or $total -eq 65535 -or $size -eq [uint32]::MaxValue -or $start -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
    if($total -lt 1 -or $total -gt 4096 -or $onDisk -ne $total) { Hold 'ZIP_CENTRAL_COUNT' }
    if(([long]$start+[long]$size) -ne $end) { Hold 'ZIP_CENTRAL_LAYOUT' }
    $at=[int]$start
    for($entry=0;$entry -lt $total;$entry++) {
        if(([long]$at+46) -gt $end -or (U32 $B $at) -ne 0x02014b50) { Hold 'ZIP_CENTRAL_HEADER' }
        $flags=U16 $B ($at+8);$method=U16 $B ($at+10)
        if(($flags -band 0x0041) -ne 0) { Hold 'ZIP_ENCRYPTED_UNSUPPORTED' }
        if(($flags -band 0xF7F0) -ne 0) { Hold 'ZIP_FLAGS_UNSUPPORTED' }
        if($method -notin @(0,8)) { Hold 'ZIP_METHOD_UNSUPPORTED' }
        [uint32]$expectCrc=U32 $B ($at+16)
        [uint32]$packed=U32 $B ($at+20);[uint32]$plain=U32 $B ($at+24)
        [int]$nameLen=U16 $B ($at+28);[int]$extraLen=U16 $B ($at+30);[int]$commentLen=U16 $B ($at+32)
        if($packed -eq [uint32]::MaxValue -or $plain -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
        if((U16 $B ($at+34)) -ne 0) { Hold 'ZIP_MULTIDISK_UNSUPPORTED' }
        [uint32]$local=U32 $B ($at+42)
        if($local -eq [uint32]::MaxValue) { Hold 'ZIP64_UNSUPPORTED' }
        $next=[long]$at+46+$nameLen+$extraLen+$commentLen
        if($next -gt $end) { Hold 'ZIP_CENTRAL_HEADER' }
        if(([long]$local+30) -gt $at -or (U32 $B ([int]$local)) -ne 0x04034b50) { Hold 'ZIP_LOCAL_HEADER' }
        if((U16 $B ([int]$local+6)) -ne $flags -or (U16 $B ([int]$local+8)) -ne $method) { Hold 'ZIP_LOCAL_CENTRAL_MISMATCH' }
        if(($flags -band 8) -eq 0 -and (U32 $B ([int]$local+14)) -ne $expectCrc) { Hold 'ZIP_LOCAL_CRC_MISMATCH' }
        [int]$localName=U16 $B ([int]$local+26);[int]$localExtra=U16 $B ([int]$local+28)
        if($localName -ne $nameLen) { Hold 'ZIP_LOCAL_CENTRAL_MISMATCH' }
        [long]$offset=[long]$local+30+$localName+$localExtra
        if(($offset+[long]$packed) -gt $at) { Hold 'ZIP_LOCAL_DATA_RANGE' }
        if($method -eq 0) {
            if($plain -ne $packed -or $plain -gt 4194304) { Hold 'ZIP_STORED_SIZE_UNSUPPORTED' }
            [byte[]]$data=[byte[]]::new([int]$plain)
            if($plain -gt 0) {[Array]::Copy($B,[int]$offset,$data,0,[int]$plain)}
            if((Crc32Bytes $data) -ne $expectCrc) { Hold 'ZIP_STORED_CRC_MISMATCH' }
        }
        $at=[int]$next
    }
    if($at -ne $end) { Hold 'ZIP_CENTRAL_LAYOUT' }
}
function New-SyntheticZip([string]$Compression) {
    $m=[IO.MemoryStream]::new()
    try {
        $z=[IO.Compression.ZipArchive]::new($m,[IO.Compression.ZipArchiveMode]::Create,$true)
        try {
            $mode=if($Compression -ceq 'store') {[IO.Compression.CompressionLevel]::NoCompression} else {[IO.Compression.CompressionLevel]::Optimal}
            $e=$z.CreateEntry('AppxManifest.xml',$mode)
            $stream=$e.Open()
            try {
                [byte[]]$data=[Text.Encoding]::UTF8.GetBytes('<Package/>')
                $stream.Write($data,0,$data.Length)
            } finally {$stream.Dispose()}
        } finally {$z.Dispose()}
        return ,([byte[]]$m.ToArray())
    } finally {$m.Dispose()}
}
function Put16([byte[]]$B,[int]$O,[uint16]$V) {[Array]::Copy([BitConverter]::GetBytes($V),0,$B,$O,2)}
function Put32([byte[]]$B,[int]$O,[uint32]$V) {[Array]::Copy([BitConverter]::GetBytes($V),0,$B,$O,4)}
function Expect-Hold([scriptblock]$Call,[string]$Code) {
    try { & $Call; throw "G3D_SELFTEST_ACCEPTED_$Code" }
    catch {
        if($_.Exception.Message -cne "G3D_HOLD_$Code") { throw "G3D_SELFTEST_WRONG expected=$Code actual=$($_.Exception.Message)" }
    }
}
function SelfTest {
    $passed=0
    $a=New-SyntheticZip 'store'
    Check-ZipCentral $a;$passed++
    $b=New-SyntheticZip 'deflate'
    Check-ZipCentral $b;$passed++
    if((Crc32Bytes ([Text.Encoding]::ASCII.GetBytes('123456789'))) -ne [uint32]3421780262) { throw 'G3D_CRC32_KNOWN_VECTOR' };$passed++
    $end=EOCD $a;[int]$cd=U32 $a ($end+16);[int]$loc=U32 $a ($cd+42)
    $v=[byte[]]$a.Clone();Put16 $v ($cd+8) 1;Put16 $v ($loc+6) 1
    Expect-Hold {Check-ZipCentral $v} 'ZIP_ENCRYPTED_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($cd+8) 64;Put16 $v ($loc+6) 64
    Expect-Hold {Check-ZipCentral $v} 'ZIP_ENCRYPTED_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($cd+10) 99;Put16 $v ($loc+8) 99
    Expect-Hold {Check-ZipCentral $v} 'ZIP_METHOD_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($cd+8) 4096;Put16 $v ($loc+6) 4096
    Expect-Hold {Check-ZipCentral $v} 'ZIP_FLAGS_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();$v[$end]=0
    Expect-Hold {Check-ZipCentral $v} 'ZIP_EOCD_MISSING';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($end+4) 1
    Expect-Hold {Check-ZipCentral $v} 'ZIP_MULTIDISK_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($end+10) 65535
    Expect-Hold {Check-ZipCentral $v} 'ZIP64_UNSUPPORTED';$passed++
    $v=[byte[]]$a.Clone();Put32 $v ($end+16) 999999
    Expect-Hold {Check-ZipCentral $v} 'ZIP_CENTRAL_LAYOUT';$passed++
    $v=[byte[]]$a.Clone();Put32 $v $cd 0
    Expect-Hold {Check-ZipCentral $v} 'ZIP_CENTRAL_HEADER';$passed++
    $v=[byte[]]$a.Clone();Put16 $v ($loc+8) 8
    Expect-Hold {Check-ZipCentral $v} 'ZIP_LOCAL_CENTRAL_MISMATCH';$passed++
    $v=[byte[]]$a.Clone();Put32 $v ($loc+14) 0
    Expect-Hold {Check-ZipCentral $v} 'ZIP_LOCAL_CRC_MISMATCH';$passed++
    $v=[byte[]]$a.Clone();Put32 $v ($cd+16) 0;Put32 $v ($loc+14) 0
    Expect-Hold {Check-ZipCentral $v} 'ZIP_STORED_CRC_MISMATCH';$passed++
    Write-Output "PASS_R002R26_G3D_ZIP_SYNTHETIC_$($passed)_NOT_INTEGRATED_NOT_REAL_APPX"
}
SelfTest
