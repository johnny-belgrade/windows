# BlueLite G3J v1 DRAFT ZIP64-aware central integrity, only in-memory synthetic fixtures.
# Not integrated into G3G v9a; never opens original files, extracts ZIP, or writes output.
[CmdletBinding()]
param([ValidateSet('SelfTest')][string]$Mode='SelfTest')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$MaxEntries=4096
$MaxBytes=268435456L
$MaxCentral=16777216L
function G3J-Hold([string]$reason){throw ('G3J_HOLD_'+$reason)}
function U16([byte[]]$b,[long]$i){if($i -lt 0 -or $i+2 -gt $b.Length){G3J-Hold 'TRUNCATED_FIELD'};return [BitConverter]::ToUInt16($b,[int]$i)}
function U32([byte[]]$b,[long]$i){if($i -lt 0 -or $i+4 -gt $b.Length){G3J-Hold 'TRUNCATED_FIELD'};return [BitConverter]::ToUInt32($b,[int]$i)}
function U64([byte[]]$b,[long]$i){if($i -lt 0 -or $i+8 -gt $b.Length){G3J-Hold 'TRUNCATED_FIELD'};return [BitConverter]::ToUInt64($b,[int]$i)}
function Assert-Entry([string]$name){
    if([string]::IsNullOrWhiteSpace($name) -or $name.Length -gt 512 -or
       $name.Contains('\') -or $name.Contains(':') -or $name.StartsWith('/') -or
       $name.Contains('//') -or $name -match '(^|/)\.{1,2}(/|$)' -or
       $name -match '[\x00-\x1F]'){G3J-Hold 'UNSAFE_ENTRY_PATH'}
}
function G3J-Check-ZipCentral([byte[]]$b){
    if($b.Length -lt 22 -or $b.Length -gt $MaxBytes){G3J-Hold 'SOURCE_SIZE_LIMIT'}
    $end=-1
    for($i=$b.Length-22;$i -ge [Math]::Max(0,$b.Length-65557);$i--){
        if((U32 $b $i) -eq 0x06054b50 -and (U16 $b ($i+20)) -eq ($b.Length-$i-22)){$end=$i;break}
    }
    if($end -lt 0){G3J-Hold 'EOCD_MISSING'}
    if((U16 $b ($end+4)) -ne 0 -or (U16 $b ($end+6)) -ne 0){G3J-Hold 'MULTIDISK'}
    [uint64]$onDisk=U16 $b ($end+8)
    [uint64]$count=U16 $b ($end+10)
    [uint64]$size=U32 $b ($end+12)
    [uint64]$start=U32 $b ($end+16)
    $zip64=($onDisk -eq 65535 -or $count -eq 65535 -or $size -eq [uint32]::MaxValue -or $start -eq [uint32]::MaxValue)
    [long]$centralEnd=$end
    if($zip64){
        $loc=$end-20
        if($loc -lt 0 -or (U32 $b $loc) -ne 0x07064b50){G3J-Hold 'ZIP64_LOCATOR_MISSING'}
        if((U32 $b ($loc+4)) -ne 0 -or (U32 $b ($loc+16)) -ne 1){G3J-Hold 'ZIP64_MULTIDISK'}
        [uint64]$recOff=U64 $b ($loc+8)
        if($recOff -gt [uint64]($loc-56)){G3J-Hold 'ZIP64_RECORD_BOUND'}
        [long]$rec=[long]$recOff
        if((U32 $b $rec) -ne 0x06064b50){G3J-Hold 'ZIP64_RECORD_SIGNATURE'}
        [uint64]$recordSize=U64 $b ($rec+4)
        if($recordSize -lt 44 -or $recordSize -gt 4096 -or ([uint64]$rec+12+$recordSize) -ne [uint64]$loc){G3J-Hold 'ZIP64_RECORD_SIZE'}
        if((U16 $b ($rec+14)) -lt 45){G3J-Hold 'ZIP64_VERSION'}
        if((U32 $b ($rec+16)) -ne 0 -or (U32 $b ($rec+20)) -ne 0){G3J-Hold 'ZIP64_MULTIDISK'}
        [uint64]$entriesDisk=U64 $b ($rec+24)
        [uint64]$entriesAll=U64 $b ($rec+32)
        [uint64]$size64=U64 $b ($rec+40)
        [uint64]$offset64=U64 $b ($rec+48)
        if($entriesDisk -ne $entriesAll){G3J-Hold 'ZIP64_ENTRIES_MISMATCH'}
        if($onDisk -ne 65535 -and $onDisk -ne $entriesDisk){G3J-Hold 'ZIP64_LEGACY_CONFLICT'}
        if($count -ne 65535 -and $count -ne $entriesAll){G3J-Hold 'ZIP64_LEGACY_CONFLICT'}
        if($size -ne [uint32]::MaxValue -and $size -ne $size64){G3J-Hold 'ZIP64_LEGACY_CONFLICT'}
        if($start -ne [uint32]::MaxValue -and $start -ne $offset64){G3J-Hold 'ZIP64_LEGACY_CONFLICT'}
        $count=$entriesAll;$onDisk=$entriesDisk;$size=$size64;$start=$offset64;$centralEnd=$rec
    }
    if($count -lt 1 -or $count -gt $MaxEntries -or $onDisk -ne $count){G3J-Hold 'CENTRAL_COUNT'}
    if($size -lt 46 -or $size -gt $MaxCentral -or $start -gt [uint64]$centralEnd){G3J-Hold 'CENTRAL_BUDGET'}
    if($start+$size -ne [uint64]$centralEnd){G3J-Hold 'CENTRAL_LAYOUT'}
    $offset=[long]$start
    $map=[Collections.Generic.Dictionary[string,uint32]]::new([StringComparer]::OrdinalIgnoreCase)
    for($idx=0;$idx -lt [int]$count;$idx++){
        if($offset+46 -gt $centralEnd -or (U32 $b $offset) -ne 0x02014b50){G3J-Hold 'CENTRAL_HEADER'}
        [uint16]$flags=U16 $b ($offset+8)
        [uint16]$method=U16 $b ($offset+10)
        if(($flags -band 0x0041) -ne 0){G3J-Hold 'ENCRYPTED'}
        if(($flags -band 0xF7F0) -ne 0){G3J-Hold 'FLAGS_UNSUPPORTED'}
        if($method -notin @(0,8)){G3J-Hold 'METHOD_UNSUPPORTED'}
        [uint32]$crc=U32 $b ($offset+16)
        [uint64]$packed=U32 $b ($offset+20)
        [uint64]$plain=U32 $b ($offset+24)
        [int]$n=U16 $b ($offset+28)
        [int]$x=U16 $b ($offset+30)
        [int]$c=U16 $b ($offset+32)
        [uint16]$disk=U16 $b ($offset+34)
        if($disk -ne 0){G3J-Hold 'MULTIDISK'}
        [uint64]$local=U32 $b ($offset+42)
        [long]$next=$offset+46+$n+$x+$c
        if($next -gt $centralEnd -or $n -lt 1){G3J-Hold 'CENTRAL_TRUNCATED'}
        $needPlain=($plain -eq [uint32]::MaxValue)
        $needPacked=($packed -eq [uint32]::MaxValue)
        $needLocal=($local -eq [uint32]::MaxValue)
        $foundExtra=$false
        [long]$at=$offset+46+$n
        [long]$extraEnd=$at+$x
        while($at -lt $extraEnd){
            if($at+4 -gt $extraEnd){G3J-Hold 'EXTRA_MALFORMED'}
            [int]$id=U16 $b $at
            [int]$length=U16 $b ($at+2)
            [long]$value=$at+4
            if($value+$length -gt $extraEnd){G3J-Hold 'EXTRA_MALFORMED'}
            if($id -eq 1){
                if($foundExtra){G3J-Hold 'ZIP64_DUPLICATE_EXTRA'}
                $foundExtra=$true
                [long]$cur=$value
                if($needPlain){if($cur+8 -gt $value+$length){G3J-Hold 'ZIP64_EXTRA_SHORT'};$plain=U64 $b $cur;$cur+=8}
                if($needPacked){if($cur+8 -gt $value+$length){G3J-Hold 'ZIP64_EXTRA_SHORT'};$packed=U64 $b $cur;$cur+=8}
                if($needLocal){if($cur+8 -gt $value+$length){G3J-Hold 'ZIP64_EXTRA_SHORT'};$local=U64 $b $cur;$cur+=8}
                if($cur -ne $value+$length){G3J-Hold 'ZIP64_EXTRA_UNEXPECTED'}
            }
            $at=$value+$length
        }
        if(($needPlain -or $needPacked -or $needLocal) -and -not $foundExtra){G3J-Hold 'ZIP64_EXTRA_MISSING'}
        if($packed -gt [uint64]$MaxBytes -or $plain -gt [uint64]$MaxBytes -or $local -gt [uint64]$offset){G3J-Hold 'ENTRY_SIZE_OR_OFFSET'}
        if($method -eq 0 -and $packed -ne $plain){G3J-Hold 'STORED_SIZE'}
        $raw=[byte[]]::new($n);[Array]::Copy($b,[int]($offset+46),$raw,0,$n)
        if(($flags -band 0x0800) -ne 0){
            try{$name=[Text.UTF8Encoding]::new($false,$true).GetString($raw)}catch{G3J-Hold 'ENTRY_ENCODING'}
        }else{
            foreach($byte in $raw){if($byte -gt 127){G3J-Hold 'ENTRY_ENCODING'}}
            $name=[Text.Encoding]::ASCII.GetString($raw)
        }
        Assert-Entry $name
        if($map.ContainsKey($name)){G3J-Hold 'CASEFOLD_DUPLICATE'}
        if([long]$local+30 -gt [long]$start -or (U32 $b ([long]$local)) -ne 0x04034b50){G3J-Hold 'LOCAL_HEADER'}
        if((U16 $b ([long]$local+6)) -ne $flags -or (U16 $b ([long]$local+8)) -ne $method){G3J-Hold 'LOCAL_CENTRAL_MISMATCH'}
        if(($flags -band 8) -eq 0 -and (U32 $b ([long]$local+14)) -ne $crc){G3J-Hold 'LOCAL_CRC'}
        [int]$localName=U16 $b ([long]$local+26)
        [int]$localExtra=U16 $b ([long]$local+28)
        if($localName -ne $n){G3J-Hold 'LOCAL_CENTRAL_MISMATCH'}
        [long]$payload=[long]$local+30+$localName+$localExtra
        if($payload+[long]$packed -gt [long]$start){G3J-Hold 'LOCAL_RANGE'}
        for($j=0;$j -lt $n;$j++){
            if($b[[int]([long]$local+30+$j)] -ne $raw[$j]){G3J-Hold 'LOCAL_NAME'}
        }
        $map.Add($name,$crc)
        $offset=$next
    }
    if($offset -ne $centralEnd){G3J-Hold 'CENTRAL_TRAILING'}
    return $map
}
function New-Fixture([bool]$isZip64,[string]$name,[bool]$extra){
    $mem=[IO.MemoryStream]::new()
    $w=[IO.BinaryWriter]::new($mem,[Text.Encoding]::UTF8,$true)
    try{
        [byte[]]$nameBytes=[Text.Encoding]::UTF8.GetBytes($name)
        if($nameBytes.Length -gt 512){throw 'FIXTURE_NAME'}
        [uint16]$ver=if($isZip64){45}else{20}
        $w.Write([uint32]0x04034b50);$w.Write($ver);$w.Write([uint16]0);$w.Write([uint16]0)
        $w.Write([uint16]0);$w.Write([uint16]0);$w.Write([uint32]0);$w.Write([uint32]0)
        $w.Write([uint32]0);$w.Write([uint16]$nameBytes.Length);$w.Write([uint16]0);$w.Write($nameBytes)
        [uint64]$cdStart=[uint64]$mem.Position
        $w.Write([uint32]0x02014b50);$w.Write([uint16]45);$w.Write($ver)
        $w.Write([uint16]0);$w.Write([uint16]0);$w.Write([uint16]0);$w.Write([uint16]0)
        $w.Write([uint32]0);$w.Write([uint32]0);$w.Write([uint32]0)
        $w.Write([uint16]$nameBytes.Length);$extraBytes=0;if($extra){$extraBytes=4};$w.Write([uint16]$extraBytes)
        $w.Write([uint16]0);$w.Write([uint16]0);$w.Write([uint16]0);$w.Write([uint32]0);$w.Write([uint32]0)
        $w.Write($nameBytes)
        if($extra){$w.Write([uint16]1);$w.Write([uint16]0)}
        [uint64]$cdSize=[uint64]$mem.Position-$cdStart
        if($isZip64){
            [uint64]$rec=[uint64]$mem.Position
            $w.Write([uint32]0x06064b50);$w.Write([uint64]44);$w.Write([uint16]45);$w.Write([uint16]45)
            $w.Write([uint32]0);$w.Write([uint32]0);$w.Write([uint64]1);$w.Write([uint64]1)
            $w.Write([uint64]$cdSize);$w.Write([uint64]$cdStart)
            $w.Write([uint32]0x07064b50);$w.Write([uint32]0);$w.Write([uint64]$rec);$w.Write([uint32]1)
        }
        $w.Write([uint32]0x06054b50);$w.Write([uint16]0);$w.Write([uint16]0)
        if($isZip64){
            $w.Write([uint16]65535);$w.Write([uint16]65535)
            $w.Write([uint32]::MaxValue);$w.Write([uint32]::MaxValue)
        }else{
            $w.Write([uint16]1);$w.Write([uint16]1)
            $w.Write([uint32]$cdSize);$w.Write([uint32]$cdStart)
        }
        $w.Write([uint16]0);$w.Flush()
        return ,$mem.ToArray()
    }finally{$w.Dispose();$mem.Dispose()}
}
function Expect-Hold([byte[]]$bytes,[string]$why){
    try{[void](G3J-Check-ZipCentral $bytes);throw 'UNEXPECTED_ACCEPT'}
    catch{
        if($_.Exception.Message -cne ('G3J_HOLD_'+$why)){throw ('FIXTURE_EXPECTED_'+$why+'_GOT_'+$_.Exception.Message)}
    }
}
function Test{
    [int]$pass=0
    [byte[]]$classic=New-Fixture $false 'a.txt' $false
    $m=G3J-Check-ZipCentral $classic
    if($m.Count -ne 1 -or -not $m.ContainsKey('a.txt')){throw 'CLASSIC_POSITIVE'};$pass++
    [byte[]]$zip64=New-Fixture $true 'a.txt' $false
    $m=G3J-Check-ZipCentral $zip64
    if($m.Count -ne 1 -or -not $m.ContainsKey('a.txt')){throw 'ZIP64_POSITIVE'};$pass++
    [byte[]]$optional=New-Fixture $true 'a.txt' $true
    $m=G3J-Check-ZipCentral $optional
    if($m.Count -ne 1){throw 'OPTIONAL_ZIP64_EXTRA'};$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone();$bad[$bad.Length-42] = $bad[$bad.Length-42] -bxor 1
    Expect-Hold $bad 'ZIP64_LOCATOR_MISSING';$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone()
    [BitConverter]::GetBytes([uint64]1234567).CopyTo($bad,$bad.Length-34)
    Expect-Hold $bad 'ZIP64_RECORD_BOUND';$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone()
    [BitConverter]::GetBytes([uint64]5000).CopyTo($bad,$bad.Length-98+32)
    [BitConverter]::GetBytes([uint64]5000).CopyTo($bad,$bad.Length-98+24)
    Expect-Hold $bad 'CENTRAL_COUNT';$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone()
    [BitConverter]::GetBytes([uint16]1).CopyTo($bad,$bad.Length-22+4)
    Expect-Hold $bad 'MULTIDISK';$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone()
    [BitConverter]::GetBytes([uint16]1).CopyTo($bad,35+8)
    Expect-Hold $bad 'ENCRYPTED';$pass++
    [byte[]]$unsafe=New-Fixture $true '../x' $false
    Expect-Hold $unsafe 'UNSAFE_ENTRY_PATH';$pass++
    [byte[]]$bad=[byte[]]$zip64.Clone()
    [BitConverter]::GetBytes([uint32]1).CopyTo($bad,14)
    Expect-Hold $bad 'LOCAL_CRC';$pass++
    [byte[]]$bad=[byte[]]$optional.Clone()
    [BitConverter]::GetBytes([uint16]8).CopyTo($bad,35+46+5+2)
    Expect-Hold $bad 'EXTRA_MALFORMED';$pass++
    Write-Output ('PASS_G3J_ZIP64_CENTRAL_SYNTHETIC_'+$pass+'_ONLY_NOT_REAL_APPX')
}
if($Mode -eq 'SelfTest'){Test}
