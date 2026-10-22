# BlueLite R002-R22: NEW VERSIONED v5, source-bound two-queue metadata only; no UUP payload.
# Derived from R21 v4 blob 1766e509784de49741a293a2e4c5ff721e1f6a80; predecessors stay immutable.
# PREPARED_NOT_RUN. Each request has one 90s budget across headers and body; max 10 MiB, no retries/redirects.
# NEWLY_OBSERVED 26300.9807 Windows/Apps queue only, NOT historical original baseline.
[CmdletBinding()]
param(
 [ValidateSet('Probe','Fetch')][string]$Mode='Probe',
 [string]$Authorization=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -cne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'R002R22_PS7_REQUIRED' }
function Gate([string]$reason) { throw "R002R22_GATE=$reason" }
function Sha([string]$p) {
 if (-not [IO.File]::Exists($p)) { Gate 'REQUIRED_SOURCE_ABSENT' }
 return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToUpperInvariant()
}
$base='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$sourceRoot='C:\work\UUP_Source\26300.9807_687d1ced'
$zip=Join-Path $sourceRoot '26300.9807_amd64_en-us_professional_687d1ced_convert.zip'
$launcher=Join-Path $sourceRoot 'uup_download_windows.cmd'
$contract=Join-Path $sourceRoot 'BlueLite_S11_SourceContract.json'
$module='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
$target=Join-Path $base '05_Evidence\R002R22_9807_NewQueue_001'
$uuid='687d1ced-aab1-4cd5-ad05-705189769731'
# New owned trace only; network is reachable only after exact Fetch authorization and all source/URI gates.
if ($Mode -ceq 'Fetch' -and $Authorization -cne 'I_APPROVE_R002R22_TWO_METADATA_GET_ONLY') { Gate 'EXPLICIT_GUI_APPROVAL_REQUIRED' }
$traceDir=Join-Path $base '05_Evidence\R002R22_Run_001'
if ([IO.Directory]::Exists($traceDir) -or [IO.File]::Exists($traceDir)) { throw 'R002R22_TRACE_COLLISION' }
[void][IO.Directory]::CreateDirectory($traceDir)
$trace=Join-Path $traceDir 'R002R22_Native_Stages.txt'
$sw=[Diagnostics.Stopwatch]::StartNew()
function R22Mark([string]$message) {
 $v=('{0:D5}ms|{1}' -f $sw.ElapsedMilliseconds,$message)
 [IO.File]::AppendAllText($trace,$v+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
 Write-Output $v
}
R22Mark 'START_NEW_VERSIONED_METADATA_PRECHECK'
R22Mark ('UTC='+[DateTime]::UtcNow.ToString('o'))
R22Mark ('NATIVE_PID='+$PID)
R22Mark ('ADAPTER_SHA256='+(Sha $PSCommandPath))
R22Mark ('MODE='+$Mode)
R22Mark 'NO_HTTP_BEFORE_EXPLICIT_GATE'
R22Mark 'BEGIN_ZIP_SHA'
if ((Sha $zip) -cne '83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7') { Gate 'ZIP_SHA_DRIFT' }
R22Mark 'PASS_ZIP_SHA'
R22Mark 'BEGIN_LAUNCHER_SHA'
if ((Sha $launcher) -cne '289EBCBEA3352F66187BDF2E75961A855DAA187F6C9F4739E7301F9C9F12DEB5') { Gate 'LAUNCHER_SHA_DRIFT' }
R22Mark 'PASS_LAUNCHER_SHA'
R22Mark 'BEGIN_CONTRACT_SHA'
if ((Sha $contract) -cne '9D9DCD4FD8190863F1591679574879D3B652D2FE6DED176EEFED0C204D947D11') { Gate 'SOURCE_CONTRACT_SHA_DRIFT' }
R22Mark 'PASS_CONTRACT_SHA'
R22Mark 'BEGIN_D4_SHA'
if ((Sha $module) -cne '7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E') { Gate 'D4_MODULE_SHA_DRIFT' }
R22Mark 'PASS_D4_SHA'
R22Mark 'BEGIN_CONTRACT_JSON'
$c=Get-Content -LiteralPath $contract -Raw | ConvertFrom-Json
if ($c.build -cne '26300.9807' -or $c.uuid -cne $uuid -or $c.architecture -cne 'amd64' -or $c.language -cne 'en-us' -or $c.edition -cne 'professional' -or $c.original_zip_sha256 -cne (Sha $zip)) { Gate 'FROZEN_SOURCE_CONTRACT_DRIFT' }
R22Mark 'PASS_CONTRACT_JSON'
function Query([uri]$u,[string]$key) {
 $queryEntries=@($u.Query.TrimStart('?').Split('&') | Where-Object { $_.Split('=',2)[0] -ieq $key })
 if ($queryEntries.Count -ne 1) { Gate 'DUPLICATE_OR_MISSING_QUERY_KEY' }
 return [uri]::UnescapeDataString($queryEntries[0].Split('=',2)[1])
}
function VerifyUrl([uri]$u,[string]$pack,[string]$edition) {
 if ($u.Scheme -cne 'https' -or $u.Host -cne 'uupdump.net' -or $u.AbsolutePath -cne '/get.php' -or $u.UserInfo -or $u.Fragment) { Gate 'ENDPOINT_URI_SCOPE' }
 $all=@($u.Query.TrimStart('?').Split('&') | ForEach-Object { $_.Split('=',2)[0].ToLowerInvariant() } | Sort-Object)
 if (($all -join ',') -cne 'aria2,edition,id,pack') { Gate 'ENDPOINT_QUERY_KEYS' }
 if ((Query $u 'id') -cne $uuid -or (Query $u 'pack') -cne $pack -or (Query $u 'edition') -cne $edition -or (Query $u 'aria2') -cne '2') { Gate 'ENDPOINT_QUERY_VALUES' }
}
R22Mark 'BEGIN_LAUNCHER_ORIGINAL_ENDPOINT_PARSE'
$raw=[IO.File]::ReadAllText($launcher)
$found=@([regex]::Matches($raw,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object Value | Select-Object -Unique)
$win=@($found | Where-Object {
 try { (Query ([uri]$_) 'edition') -ceq 'professional' } catch { $false }
})
if ($win.Count -ne 1) { Gate 'ORIGINAL_WINDOWS_ENDPOINT_NOT_UNIQUE' }
R22Mark 'PASS_UNIQUE_WINDOWS_ENDPOINT'
$windows=[uri]$win[0]
$apps=[uri]("https://uupdump.net/get.php?id=$uuid&pack=neutral&edition=app&aria2=2")
R22Mark 'BEGIN_VERIFY_WINDOWS_URI'
VerifyUrl $windows 'en-us' 'professional'
R22Mark 'PASS_VERIFY_WINDOWS_URI'
R22Mark 'BEGIN_VERIFY_APPS_URI'
VerifyUrl $apps 'neutral' 'app'
R22Mark 'PASS_VERIFY_APPS_URI'
if ($Mode -eq 'Probe') {
 R22Mark 'HTTP_GET_REQUESTS=0'
 R22Mark 'RESULT=PASS_R002R22_INSTRUMENTED_METADATA_PROBE_NATIVE'
 exit 0
}
# R22: explicit metadata-only authorization below gates the bounded two-queue Fetch.
if ($Authorization -cne 'I_APPROVE_R002R22_TWO_METADATA_GET_ONLY') { Gate 'EXPLICIT_GUI_APPROVAL_REQUIRED' }
if ([IO.Directory]::Exists($target) -or [IO.File]::Exists($target)) { Gate 'OWNED_OUTPUT_COLLISION' }
Import-Module -Name $module -Force -ErrorAction Stop
[void][IO.Directory]::CreateDirectory($target)
$report=Join-Path $target 'R002R22_Native_Metadata_Receipt.txt'
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('BLUELITE_R002R22_9807_NATIVE_SMALL_METADATA_GET')
$lines.Add('STARTED_UTC='+[DateTime]::UtcNow.ToString('o'))
$lines.Add('NATIVE_PID='+$PID)
$lines.Add('POWERSHELL_VERSION='+$PSVersionTable.PSVersion.ToString())
$lines.Add('ADAPTER_SHA256='+(Sha $PSCommandPath))
$lines.Add('SOURCE_UUID='+$uuid)
$lines.Add('SOURCE_ZIP_SHA256='+(Sha $zip))
$lines.Add('REQUEST_LIMIT=2;UUP_PAYLOAD=NONE;ORIGINAL_PRE_RENEWAL_BASELINE=HOLD')
$lines.Add('OUTPUT='+$target)
$attempt=0
$client=$null
try {
 $handler=[Net.Http.HttpClientHandler]::new()
 $handler.AllowAutoRedirect=$false
 $handler.AutomaticDecompression=[Net.DecompressionMethods]::None
 $client=[Net.Http.HttpClient]::new($handler)
 $client.Timeout=[Threading.Timeout]::InfiniteTimeSpan
 foreach($item in @(@{Name='Windows';Uri=$windows},@{Name='Apps';Uri=$apps})) {
  $attempt++
  $name=$item.Name
  $destination=Join-Path $target ($name+'Queue.newly_observed.txt')
  if ([IO.File]::Exists($destination)) { Gate 'OUTPUT_COLLISION_DURING_GET' }
  # One GET per named queue, no retries, no redirects, no bulk payload.
  $cts=[Threading.CancellationTokenSource]::new()
  $cts.CancelAfter([TimeSpan]::FromSeconds(90))
  try {
   $response=$client.GetAsync($item.Uri,[Net.Http.HttpCompletionOption]::ResponseHeadersRead,$cts.Token).GetAwaiter().GetResult()
   try {
   $lines.Add('REQUEST_'+$attempt+'_KIND='+$name+';HTTP_STATUS='+[int]$response.StatusCode)
   if ([int]$response.StatusCode -ne 200) { Gate ('HTTP_STATUS_'+[int]$response.StatusCode) }
   if ($response.Content.Headers.ContentLength -gt 10485760) { Gate 'RESPONSE_TOO_LARGE' }
   $stream=$response.Content.ReadAsStream()
   $file=[IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
   try {
    $buf=[byte[]]::new(65536);$size=0
    while (($n=$stream.ReadAsync($buf,0,$buf.Length,$cts.Token).GetAwaiter().GetResult()) -gt 0) {
     $size+=$n
     if ($size -gt 10485760) { Gate 'RESPONSE_EXCEEDS_10MIB' }
     $file.Write($buf,0,$n)
    }
   } finally { $file.Dispose();$stream.Dispose() }
   } finally { $response.Dispose() }
  } finally { $cts.Dispose() }
  $info=Get-BlueLiteQueueIdentity -Path $destination
  $lines.Add($name.ToUpperInvariant()+'_FILE_BYTES='+$size)
  $lines.Add($name.ToUpperInvariant()+'_FILE_SHA256='+(Sha $destination))
  $lines.Add($name.ToUpperInvariant()+'_ENTRY_COUNT='+$info.Count)
  $lines.Add($name.ToUpperInvariant()+'_SEMANTIC_SHA256='+$info.SHA256)
  $lines.Add('REQUEST_'+$attempt+'_QUEUE_IDENTITY_VALIDATED=TRUE')
 }
 $lines.Add('NATIVE_METADATA_REQUESTS_COMPLETED='+$attempt)
 $lines.Add('FINISHED_UTC='+[DateTime]::UtcNow.ToString('o'))
 $lines.Add('RESULT=PASS_R002R22_NEWLY_OBSERVED_9807_WINDOWS_APPS_SOURCE_METADATA_ONLY')
 $lines | Set-Content -LiteralPath $report -Encoding utf8NoBOM
 'RESULT=PASS_R002R22_NEWLY_OBSERVED_9807_WINDOWS_APPS_SOURCE_METADATA_ONLY;REQUESTS='+$attempt
} catch {
 $lines.Add('NATIVE_METADATA_REQUESTS_ATTEMPTED='+$attempt)
 $lines.Add('FINISHED_UTC='+[DateTime]::UtcNow.ToString('o'))
 $lines.Add('RESULT=HOLD_R002R22_BOUNDED_GET_OR_QUEUE_VALIDATION')
 # Do not leak HTTP exception text or signed transport URLs into logs.
 $lines | Set-Content -LiteralPath $report -Encoding utf8NoBOM
 'RESULT=HOLD_R002R22_BOUNDED_GET_OR_QUEUE_VALIDATION;ATTEMPTED='+$attempt
 exit 86
} finally { if ($null -ne $client) { $client.Dispose() } }

