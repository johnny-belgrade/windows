[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$UUPRoot,
 [string]$WindowsQueueFile,
 [string]$LogPath='.\BlueLite_Logs\SourceTriad.log',
 [switch]$OfflineOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Add-Mapping($Map,[string]$Name,[string]$Hash,[string]$Tag) {
 if([string]::IsNullOrWhiteSpace($Name) -or $Name -ne [IO.Path]::GetFileName($Name) -or $Name -match '[\\/:*?"<>|]' -or $Name.Contains('..') -or $Name.TrimEnd('.',' ') -cne $Name){throw ('Invalid name in '+$Tag+': '+$Name)}
 if($Hash -notmatch '^[a-fA-F0-9]{40}$'){throw ('Invalid SHA1 in '+$Tag)}
 if($Map.ContainsKey($Name)){throw ('Duplicate filename in '+$Tag+': '+$Name)}
 $Map.Add($Name,$Hash.ToUpperInvariant())
}
function Compare-Mappings($A,$B,[string]$Tag) {
 if($A.Count -ne $B.Count){throw ('Count mismatch '+$Tag)}
 foreach($n in $A.Keys){if(-not $B.ContainsKey($n) -or $A[$n] -ne $B[$n]){throw ('Identity mismatch '+$Tag+': '+$n)}}
}
try {
 $root=(Resolve-Path -LiteralPath $UUPRoot).Path
 $files=@('List of files UUP.txt','File_renaming_script.cmd','SHA-1 checksums file.txt')
 $sourceHashes=[ordered]@{}
 foreach($n in $files){$p=Join-Path $root $n;if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('SOURCE_TRIAD_REQUIRED: '+$n)};$sourceHashes[$n]=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
 $makeMap={New-Object 'System.Collections.Generic.Dictionary[string,string]' ([StringComparer]::OrdinalIgnoreCase)}
 $ledger=& $makeMap; $list=& $makeMap; $renames=& $makeMap; $queue=& $makeMap
 foreach($line in [IO.File]::ReadAllLines((Join-Path $root $files[2]))){
  if(-not $line.Trim()){continue}
  $m=[regex]::Match($line,'^([a-fA-F0-9]{40})\s+\*(.+?)\s*$')
  if(-not $m.Success){throw 'Malformed SHA1 ledger row'}
  Add-Mapping $ledger $m.Groups[2].Value $m.Groups[1].Value 'SHA ledger'
 }
 foreach($line in [IO.File]::ReadAllLines((Join-Path $root $files[0]))){
  if(-not $line.Trim() -or $line -match '^File\tExpires\tSHA-1\tSize\s*$'){continue}
  $f=$line.Split([char]9)
  if($f.Length -ne 4 -or $f[2] -notmatch '^[a-fA-F0-9]{40}$'){throw 'Malformed UUP file-list row'}
  Add-Mapping $list $f[0].Trim() $f[2] 'UUP list'
 }
 $guidSet=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
 foreach($line in [IO.File]::ReadAllLines((Join-Path $root $files[1]))){
  # This file is NEVER executed. Only the known UUP rename-data grammar is accepted.
  if(-not $line.Trim() -or $line -match '(?i)^\s*(?:@?echo off|cd /d "%~dp0"|pause|exit /b(?: 0)?|rem(?:\s.*)?|::.*)\s*$'){continue}
  $m=[regex]::Match($line,'(?i)^\s*rename\s+"([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})"\s+"([^"]+)"\s*$')
  if(-not $m.Success){throw 'Malformed or unexpected rename-data row'}
  if(-not $guidSet.Add($m.Groups[1].Value)){throw 'Duplicate rename GUID'}
  $name=$m.Groups[2].Value
  if(-not $ledger.ContainsKey($name)){throw ('Rename-only filename: '+$name)}
  Add-Mapping $renames $name $ledger[$name] 'rename data'
 }
 if($ledger.Count -lt 1){throw 'Empty source ledger'}
 Compare-Mappings $ledger $list 'list/ledger'; Compare-Mappings $ledger $renames 'rename/ledger'
 $queueHash=$null
 if(-not $OfflineOnly){
  if(-not $WindowsQueueFile -or -not(Test-Path -LiteralPath $WindowsQueueFile -PathType Leaf)){throw 'Windows D4 queue required'}
  $out='';$hash='';$started=$false
  foreach($line in [IO.File]::ReadAllLines($WindowsQueueFile)){
   if($line -match '^\s*https?://'){
    if($started){if(-not $out -or -not $hash){throw 'Incomplete D4 record'};Add-Mapping $queue $out $hash 'D4'}
    $started=$true;$out='';$hash=''
   }elseif($line -match '^\s*out='){
    if(-not $started -or $out){throw 'Orphan/duplicate D4 out'}
    $out=$line.Trim().Substring(4).Trim().Trim('"')
    if(-not $out){throw 'Empty D4 out'}
   }elseif($line -match '^\s*checksum='){
    $m=[regex]::Match($line,'^\s*checksum=sha-1=([a-fA-F0-9]{40})\s*$')
    if(-not $started -or $hash -or -not $m.Success){throw 'Orphan/duplicate/malformed D4 checksum'}
    $hash=$m.Groups[1].Value
   }elseif($line.Trim() -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*(?:dir|header|user-agent|max-connection-per-server|split|continue|check-integrity)='){
    throw 'Unexpected D4 queue line'
   }
  }
  if(-not $started -or -not $out -or -not $hash){throw 'Incomplete final D4 record'}
  Add-Mapping $queue $out $hash 'D4';Compare-Mappings $ledger $queue 'D4/ledger'
  $queueHash=(Get-FileHash -LiteralPath $WindowsQueueFile -Algorithm SHA256).Hash
 }
 $status=if($OfflineOnly){'SOURCE_TRIAD_OFFLINE_PASS'}else{'SOURCE_TRIAD_D4_PASS'}
 $msg=('{0} names={1} GUID={2}' -f $status,$ledger.Count,$guidSet.Count)
 $dir=Split-Path -Parent $LogPath;if($dir -and -not(Test-Path -LiteralPath $dir)){[void][IO.Directory]::CreateDirectory($dir)}
 $msg | Set-Content -LiteralPath $LogPath -Encoding UTF8
 [ordered]@{schema='BlueLite.SourceTriad.v6.1';status=$status;utc=[DateTime]::UtcNow.ToString('o');count=$ledger.Count;guids=$guidSet.Count;source_sha256=$sourceHashes;windows_queue_sha256=$queueHash} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath ($LogPath+'.json') -Encoding UTF8
 Write-Host $msg -ForegroundColor Green;exit 0
}catch{
 $msg='SOURCE_TRIAD_D4_HOLD: '+$_.Exception.Message
 Write-Host $msg -ForegroundColor Red
 try{$msg|Set-Content -LiteralPath $LogPath -Encoding UTF8; if(Test-Path -LiteralPath ($LogPath+'.json')){Remove-Item -LiteralPath ($LogPath+'.json') -Force}}catch{}
 exit 1
}
