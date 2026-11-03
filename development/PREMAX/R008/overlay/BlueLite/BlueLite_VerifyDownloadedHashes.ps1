[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$UUPDirectory,
 [Parameter(Mandatory=$true)][string]$AppsQueueFile,
 [Parameter(Mandatory=$true)][string]$WindowsQueueFile,
 [string]$LogPath='.\BlueLite_Logs\ContentSHA1.log'
)
$ErrorActionPreference='Stop'
function Read-Queue([string]$Path) {
 if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){throw "Queue not found: $Path"}
 $rows=[System.Collections.Generic.List[object]]::new()
 $out=''; $hash=''; $url=''
 foreach($line in [IO.File]::ReadAllLines([IO.Path]::GetFullPath($Path))) {
  if($line -match '^\s*https?://') {
   if($url) {
    if(-not $out -or -not $hash){throw ('Incomplete aria2 record: {0}' -f $Path)}
    [void]$rows.Add([pscustomobject]@{Name=$out;SHA1=$hash;Url=$url})
   }
   $url=$line.Trim(); $out=''; $hash=''
  } elseif($line -match '^\s*out=(.+?)\s*$') {
   $out=$Matches[1].Trim().Trim('"')
  } elseif($line -match '^\s*checksum=sha-1=([0-9a-fA-F]{40})\s*$') {
   $hash=$Matches[1].ToUpperInvariant()
  }
 }
 if($url) {
  if(-not $out -or -not $hash){throw ('Incomplete last aria2 record: {0}' -f $Path)}
  [void]$rows.Add([pscustomobject]@{Name=$out;SHA1=$hash;Url=$url})
 }
 if($rows.Count -eq 0){throw ('Empty aria2 queue: {0}' -f $Path)}
 return $rows.ToArray()
}
try {
 $dir=(Resolve-Path -LiteralPath $UUPDirectory).Path
 $want=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($queue in @($WindowsQueueFile,$AppsQueueFile)){
  foreach($entry in @(Read-Queue $queue)){
   $n=[string]$entry.Name
   if($n -ne [IO.Path]::GetFileName($n) -or $n.Contains('..') -or $n.IndexOfAny([char[]]@('/','\')) -ge 0){throw ('Unsafe queue output: {0}' -f $n)}
   if($want.ContainsKey($n)){
    if($want[$n] -ne $entry.SHA1){throw ('Conflicting hashes for {0}' -f $n)}
   }else{$want.Add($n,$entry.SHA1)}
  }
 }
 $log=[Collections.Generic.List[string]]::new()
 $totalBytes=[long]0; $checked=0
 foreach($n in @($want.Keys | Sort-Object)){
  $file=Join-Path $dir $n
  if(-not (Test-Path -LiteralPath $file -PathType Leaf)){throw ('Missing UUP payload: {0}' -f $n)}
  $f=Get-Item -LiteralPath $file
  $h=(Get-FileHash -LiteralPath $file -Algorithm SHA1).Hash.ToUpperInvariant()
  if($h -ne $want[$n]){throw ('SHA1_MISMATCH {0} expected={1} actual={2}' -f $n,$want[$n],$h)}
  $totalBytes += $f.Length; $checked++
  [void]$log.Add(('PASS {0} {1}' -f $h,$n))
 }
 $parent=Split-Path -Parent $LogPath
 if($parent -and -not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
 @("CONTENT_SHA1_PASS files=$checked bytes=$totalBytes") + $log.ToArray() | Set-Content -LiteralPath $LogPath -Encoding UTF8
 Write-Host ("CONTENT_SHA1_PASS files={0} bytes={1}" -f $checked,$totalBytes) -ForegroundColor Green
 exit 0
}catch{
 $msg=$_.Exception.Message
 try{("CONTENT_SHA1_HOLD: "+$msg)|Set-Content -LiteralPath $LogPath -Encoding UTF8}catch{}
 Write-Host ("CONTENT_SHA1_HOLD: "+$msg) -ForegroundColor Red
 exit 1
}