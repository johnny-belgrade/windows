[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$UUPRoot)
$ErrorActionPreference='Stop'
try {
 Add-Type -AssemblyName System.IO.Compression
 $root=(Resolve-Path -LiteralPath $UUPRoot).Path
 $logDir=Join-Path $root 'BlueLite_Logs'
 if(Test-Path -LiteralPath $logDir) {
  if(@(Get-ChildItem -LiteralPath $logDir -Force).Count -gt 0) {
   Write-Host 'EXISTING_SESSION_LOGS_RETAINED'
   exit 0
  }
 }
 $archives=@(Get-ChildItem -LiteralPath $root -File -Filter 'BlueLite_EVIDENCE_*.zip' | Sort-Object Name -Descending)
 if($archives.Count -eq 0) {
  Write-Host 'FRESH_UUP_SESSION_NO_EVIDENCE_TO_RESTORE'
  exit 0
 }
 $archive=$archives[0].FullName
 $zip=[IO.Compression.ZipFile]::OpenRead($archive)
 try {
  $items=@($zip.Entries | Where-Object {$_.FullName.StartsWith('Logs/',[StringComparison]::OrdinalIgnoreCase) -and -not $_.FullName.EndsWith('/')})
  if($items.Count -eq 0){throw 'Latest evidence archive has no Logs entries.'}
  $tmp=Join-Path $root ('BlueLite_RESTORE_'+[guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp -Force|Out-Null
  foreach($entry in $items){
   $rel=$entry.FullName.Substring(5).Replace('/','\')
   if(-not $rel -or $rel.Contains('..') -or [IO.Path]::IsPathRooted($rel)){throw ('Unsafe evidence entry: {0}' -f $entry.FullName)}
   $dest=Join-Path $tmp $rel
   $par=Split-Path -Parent $dest
   if(-not(Test-Path -LiteralPath $par)){New-Item -ItemType Directory -Path $par -Force|Out-Null}
   [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$dest,$false)
  }
  $manifestEntry=$zip.GetEntry('FilesManifest.json')
  if($null -eq $manifestEntry){throw 'FilesManifest.json absent in latest evidence archive.'}
  $sr=New-Object IO.StreamReader($manifestEntry.Open())
  try{$manifestText=$sr.ReadToEnd()}finally{$sr.Dispose()}
  $manifest=@($manifestText|ConvertFrom-Json)
  foreach($item in $manifest){
   if(-not([string]$item.Path).StartsWith('Logs/')){continue}
   $rel=([string]$item.Path).Substring(5).Replace('/','\')
   if($rel.Contains('..') -or [IO.Path]::IsPathRooted($rel)){throw 'Unsafe manifest path.'}
   $actual=Join-Path $tmp $rel
   if(-not(Test-Path -LiteralPath $actual -PathType Leaf)){throw ('Missing extracted log: {0}' -f $rel)}
   if((Get-FileHash -LiteralPath $actual -Algorithm SHA256).Hash -ne [string]$item.SHA256){throw ('Evidence hash mismatch: {0}' -f $rel)}
  }
  if(Test-Path -LiteralPath $logDir -PathType Container){
   if(@(Get-ChildItem -LiteralPath $logDir -Force).Count -ne 0){throw 'Log directory changed during evidence restoration.'}
   Remove-Item -LiteralPath $logDir -Force
  }
  Move-Item -LiteralPath $tmp -Destination $logDir
  Write-Host ('PREVIOUS_LOG_CHECKPOINT_RESTORED entries={0}' -f $items.Count) -ForegroundColor Green
 }finally{$zip.Dispose()}
 exit 0
}catch{
 Write-Host ('RESTORE_EVIDENCE_HOLD: '+$_.Exception.Message) -ForegroundColor Red
 exit 1
}