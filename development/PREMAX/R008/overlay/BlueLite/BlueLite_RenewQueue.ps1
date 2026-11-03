[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Windows','Apps')][string]$Mode,
 [Parameter(Mandatory=$true)][string]$Url,
 [Parameter(Mandatory=$true)][string]$ActiveQueueFile,
 [Parameter(Mandatory=$true)][string]$OriginalQueueFile,
 [Parameter(Mandatory=$true)][string]$FrozenQueueFile,
 [string]$LogPath='.\BlueLite_Logs\RenewQueue.log',
 [string]$OfflineCandidateQueueFile,
 [switch]$VerifyOnly
)
$ErrorActionPreference='Stop'
function Read-Queue([string]$Path) {
 if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw ('Queue missing: {0}' -f $Path)}
 $groups=[Collections.Generic.List[object]]::new()
 $lines=[IO.File]::ReadAllLines([IO.Path]::GetFullPath($Path))
 $start=-1
 for($i=0;$i -le $lines.Length;$i++){
  $isUrl=($i -lt $lines.Length -and $lines[$i] -match '^\s*https?://')
  if($isUrl -or $i -eq $lines.Length){
   if($start -ge 0){
    $out='';$sha=''
    for($j=$start+1;$j -lt $i;$j++){
     if($lines[$j] -match '^\s*out=(.+?)\s*$'){$out=$Matches[1].Trim().Trim('"')}
     if($lines[$j] -match '^\s*checksum=sha-1=([a-fA-F0-9]{40})\s*$'){$sha=$Matches[1].ToUpperInvariant()}
    }
    if(-not $out -or -not $sha){throw ('Missing out/SHA1 in {0} record {1}' -f $Path,$groups.Count)}
    if($out -ne [IO.Path]::GetFileName($out) -or $out.Contains('..')){throw ('Unsafe output name: {0}' -f $out)}
    [void]$groups.Add([pscustomobject]@{Out=$out;Sha=$sha;Url=$lines[$start].Trim();Line=$start})
   }
   if($isUrl){$start=$i}
  }
 }
 if($groups.Count -lt 1){throw ('No records in queue {0}' -f $Path)}
 return [pscustomobject]@{Lines=$lines;Records=$groups.ToArray()}
}
function Map-Queue($Queue) {
 $map=[Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($r in $Queue.Records) {
  if($map.ContainsKey($r.Out)){throw ('Duplicate output in queue: {0}' -f $r.Out)}
  $map.Add($r.Out,$r)
 }
 return $map
}
try {
 if($Url -notmatch '(?i)^https://uupdump\.net/get\.php\?'){throw 'Source URL is not the original UUP Dump get.php endpoint.'}
 $urlUuid=[regex]::Match($Url,'(?i)[?&]id=([0-9a-f-]{36}(?:_rev\.\d+)?)')
 if(-not $urlUuid.Success){throw 'Original UUP UUID missing in source URL.'}
 if(-not(Test-Path -LiteralPath $OriginalQueueFile)){throw 'Original queue missing.'}
 if(-not(Test-Path -LiteralPath $ActiveQueueFile)){throw 'Active queue missing.'}
 $base=if(Test-Path -LiteralPath $FrozenQueueFile){$FrozenQueueFile}else{$OriginalQueueFile}
 $frozen=Read-Queue $base
 $old=Read-Queue $ActiveQueueFile
 $baseMap=Map-Queue $frozen
 $oldMap=Map-Queue $old
 if($Mode -eq 'Windows' -and $oldMap.Count -ne $baseMap.Count){throw 'Windows source count differs from frozen D4.'}
 foreach($item in $oldMap.Values){
  if(-not $baseMap.ContainsKey($item.Out) -or $baseMap[$item.Out].Sha -ne $item.Sha){throw ('Active queue changed frozen identity: {0}' -f $item.Out)}
 }
 if(-not $OfflineCandidateQueueFile){
  $folder=Split-Path -Parent ([IO.Path]::GetFullPath($LogPath))
  if(-not(Test-Path -LiteralPath $folder)){New-Item -ItemType Directory -Path $folder -Force|Out-Null}
  $OfflineCandidateQueueFile=Join-Path $folder ('renew_candidate_'+[guid]::NewGuid().ToString('N')+'.txt')
  Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 90 -OutFile $OfflineCandidateQueueFile -ErrorAction Stop
 }
 $fresh=Read-Queue $OfflineCandidateQueueFile
 $freshMap=Map-Queue $fresh
 if($freshMap.Count -ne $baseMap.Count){throw ('SOURCE_IDENTITY_CHANGED: expected {0}, renewed {1}' -f $baseMap.Count,$freshMap.Count)}
 foreach($item in $baseMap.Values){
  if(-not $freshMap.ContainsKey($item.Out) -or $freshMap[$item.Out].Sha -ne $item.Sha){throw ('SOURCE_IDENTITY_CHANGED: {0}' -f $item.Out)}
 }
 $lines=[string[]]$old.Lines.Clone()
 foreach($item in $old.Records){$lines[$item.Line]=$freshMap[$item.Out].Url}
 $pDir=Split-Path -Parent ([IO.Path]::GetFullPath($LogPath))
 if(-not(Test-Path -LiteralPath $pDir)){New-Item -ItemType Directory -Path $pDir -Force|Out-Null}
 $msg=('QUEUE_RENEW_IDENTITY_PASS mode={0} uuid={1} frozen={2} active={3}' -f $Mode,$urlUuid.Groups[1].Value,$baseMap.Count,$oldMap.Count)
 if($VerifyOnly){Write-Host $msg -ForegroundColor Green;exit 0}
 if(-not(Test-Path -LiteralPath $FrozenQueueFile)){Copy-Item -LiteralPath $OriginalQueueFile -Destination $FrozenQueueFile -ErrorAction Stop}
 $tmpActive=$ActiveQueueFile+'.bltmp'
 [IO.File]::WriteAllLines([IO.Path]::GetFullPath($tmpActive),$lines,(New-Object Text.UTF8Encoding($false)))
 $activePrev=$ActiveQueueFile+'.blprev'
 $originalPrev=$OriginalQueueFile+'.blprev'
 Copy-Item -LiteralPath $ActiveQueueFile -Destination $activePrev -Force
 Copy-Item -LiteralPath $OriginalQueueFile -Destination $originalPrev -Force
 try {
  if($Mode -eq 'Windows'){
   Copy-Item -LiteralPath $OfflineCandidateQueueFile -Destination $OriginalQueueFile -Force
   Copy-Item -LiteralPath $OfflineCandidateQueueFile -Destination $ActiveQueueFile -Force
  }else{
   Copy-Item -LiteralPath $OfflineCandidateQueueFile -Destination $OriginalQueueFile -Force
   Move-Item -LiteralPath $tmpActive -Destination $ActiveQueueFile -Force
  }
 }catch{
  Copy-Item -LiteralPath $activePrev -Destination $ActiveQueueFile -Force
  Copy-Item -LiteralPath $originalPrev -Destination $OriginalQueueFile -Force
  throw
 }
 $msg | Set-Content -LiteralPath $LogPath -Encoding UTF8
 Write-Host $msg -ForegroundColor Green
 exit 0
}catch{
 $msg=('QUEUE_RENEW_HOLD mode={0}: {1}' -f $Mode,$_.Exception.Message)
 Write-Host $msg -ForegroundColor Red
 try{$msg|Set-Content -LiteralPath $LogPath -Encoding UTF8}catch{}
 exit 1
}