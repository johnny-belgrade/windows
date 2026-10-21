# BlueLite R001: D4 module REUSE, queue-metadata ONLY. DEVELOPMENT DRAFT / NOT RUNTIME AUTHORIZED.
# AuditSaved reads existing queues; FetchMetadata performs TWO REAL SMALL get.php GETs ONLY AFTER separate GUI authorization.
# No aria2, no full UUP download, no converter, no WIM/registry/WinRE operation.
[CmdletBinding()]
param(
  [ValidateSet('AuditSaved','FetchMetadata')][string]$Mode='AuditSaved',
  [ValidateSet('9711','9807')][string]$Profile='9711',
  [string]$OutputDirectory='',
  [string]$Authorization=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function Stop-Gate([string]$id) { throw "R001_FAIL_CLOSED=$id" }
function Hash([string]$path) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Stop-Gate "MISSING_FILE=$path" }
  return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
}
$cycle='C:\work\PREMAX-work\R001_Universal_PREMAX_UUP'
$module='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
$moduleHash='7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E'
if ((Hash $module) -cne $moduleHash) { Stop-Gate 'D4_MODULE_SHA_DRIFT' }
Import-Module -Name $module -Force -ErrorAction Stop
$profiles=@{
 '9711'=@{
  Build='26300.9711'; UUID='2b22470a-8b6f-498f-9c88-66f7b9fb56b1'; Pack='en-us'; Edition='professional';
  Zip='C:\work\26300.9711-UUP\26300.9711_amd64_en-us_professional_2b22470a_convert.zip';
  ZipSHA='D3E7162605A61D8A0FD62E1738DE523B52B36059D6AAC8F756F90AEFCB64C4A2';
  Root='C:\work\UUP_Source\26300.9711_2b22470a'; LauncherSHA='CC52FB726E1DCD645C8C7C2A96A59A2EB83DD0323EBBEE6471AB6DCA6F4E1A90';
  QueueRoot='C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\Queues';
  WindowsIdentity='07EB7120FC7B41001D0FA4E71213D6EB03901A0CDAAA951F8BF90D2D21B61C06';
  AppsIdentity='DF2747330DB66B5ACB8398EDF8DC29BDC22F3F80FA3088C005131324B5A5C566'
 };
 '9807'=@{
  Build='26300.9807'; UUID='687d1ced-aab1-4cd5-ad05-705189769731'; Pack='en-us'; Edition='professional';
  Zip='C:\work\26300.9807-UUP\26300.9807_amd64_en-us_professional_687d1ced_convert.zip';
  ZipSHA='83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7';
  Root='C:\work\UUP_Source\26300.9807_687d1ced'; LauncherSHA='289EBCBEA3352F66187BDF2E75961A855DAA187F6C9F4739E7301F9C9F12DEB5';
  QueueRoot=''; WindowsIdentity=''; AppsIdentity=''
 }
}
$p=$profiles[$Profile]
if ((Hash $p.Zip) -cne $p.ZipSHA) { Stop-Gate 'ORIGINAL_UUP_ZIP_SHA_DRIFT' }
$launcher=Join-Path $p.Root 'uup_download_windows.cmd'
if ((Hash $launcher) -cne $p.LauncherSHA) { Stop-Gate 'FROZEN_LAUNCHER_SHA_DRIFT' }
function Query-Param([uri]$u,[string]$name) {
 foreach ($pair in $u.Query.TrimStart('?').Split('&')) {
  $t=$pair.Split('=',2)
  if ($t.Count -eq 2 -and $t[0] -ieq $name) { return [uri]::UnescapeDataString($t[1]) }
 }
 return ''
}
$raw=[IO.File]::ReadAllText($launcher)
$urls=@([regex]::Matches($raw,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object Value | Select-Object -Unique)
$windows=@($urls | Where-Object { (Query-Param ([uri]$_) 'edition') -ieq $p.Edition })
if ($windows.Count -ne 1) { Stop-Gate 'WINDOWS_ENDPOINT_COUNT_NOT_ONE' }
$winUrl=[uri]$windows[0]
$appUrl=[uri]("https://uupdump.net/get.php?id=$($p.UUID)&pack=neutral&edition=app&aria2=2")
foreach ($e in @(@{Url=$winUrl;Edition=$p.Edition;Pack=$p.Pack},@{Url=$appUrl;Edition='app';Pack='neutral'})) {
 $u=$e.Url
 if ($u.Scheme -cne 'https' -or $u.Host -cne 'uupdump.net' -or $u.AbsolutePath -cne '/get.php' -or
     (Query-Param $u 'id') -cne $p.UUID -or (Query-Param $u 'pack') -cne $e.Pack -or
     (Query-Param $u 'edition') -cne $e.Edition -or (Query-Param $u 'aria2') -cne '2') {
  Stop-Gate 'FROZEN_SOURCE_ENDPOINT_IDENTITY_DRIFT'
 }
}
if (-not $p.QueueRoot) { Stop-Gate '9807_INDEPENDENT_FROZEN_QUEUE_BASELINE_NOT_YET_PROVEN' }
$wo=Join-Path $p.QueueRoot 'WindowsQueue.original.txt'
$ao=Join-Path $p.QueueRoot 'AppsQueue.original.txt'
$wa=Join-Path $p.QueueRoot 'WindowsQueue.active.txt'
$aa=Join-Path $p.QueueRoot 'AppsQueue.active.txt'
$wi=Get-BlueLiteQueueIdentity -Path $wo
$ai=Get-BlueLiteQueueIdentity -Path $ao
if ($wi.SHA256 -cne $p.WindowsIdentity -or $ai.SHA256 -cne $p.AppsIdentity) { Stop-Gate 'FROZEN_QUEUE_SEMANTIC_DRIFT' }
if ($Mode -eq 'FetchMetadata') {
 if ($Authorization -cne 'I_APPROVE_R001_TWO_METADATA_GET_ONLY') { Stop-Gate 'SEPARATE_METADATA_GET_GUI_APPROVAL_REQUIRED' }
 if (-not $OutputDirectory) { Stop-Gate 'OWNED_OUTPUT_DIRECTORY_REQUIRED' }
 $full=[IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
 if (-not $full.StartsWith("$cycle\",[StringComparison]::OrdinalIgnoreCase)) { Stop-Gate 'OUTPUT_NOT_UNDER_R001_CYCLE' }
 if (Test-Path -LiteralPath $full) { Stop-Gate 'OUTPUT_MUST_NOT_PREEXIST' }
 [void](New-Item -ItemType Directory -Path $full -ErrorAction Stop)
 $wnew=Join-Path $full 'WindowsQueue.renewed.txt'
 $anew=Join-Path $full 'AppsQueue.renewed.txt'
 try {
  Invoke-WebRequest -Uri $winUrl.AbsoluteUri -OutFile $wnew -TimeoutSec 120 -ErrorAction Stop | Out-Null
  Invoke-WebRequest -Uri $appUrl.AbsoluteUri -OutFile $anew -TimeoutSec 120 -ErrorAction Stop | Out-Null
  $wproof=Assert-BlueLiteQueueSamePayload -Baseline $wo -Candidate $wnew
  $aproof=Assert-BlueLiteQueueSamePayload -Baseline $ao -Candidate $anew
  Write-Output "R001_METADATA_ONLY_PASS;PROFILE=$Profile;WINDOWS=$($wproof.Count);APPS=$($aproof.Count);SIGNED_URLS_REDACTED=TRUE"
 } catch {
  # Keep exact owned evidence for diagnosis; never print signed transport URLs or silently retry.
  Write-Output 'R001_METADATA_ONLY_HOLD;OWNED_RECEIPT_RETAINED_FOR_REVIEW'
  throw
 }
} else {
 $wproof=Assert-BlueLiteQueueSamePayload -Baseline $wo -Candidate $wa
 $aproof=Assert-BlueLiteQueueSamePayload -Baseline $ao -Candidate $aa
 Write-Output "R001_SAVED_D4_QUEUE_IDENTITY_PASS;PROFILE=$Profile;WINDOWS=$($wproof.Count);APPS=$($aproof.Count);NO_NETWORK=TRUE"
}
