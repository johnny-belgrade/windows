# BlueLite R002R16: NEW scoped full-exact v2 URL functions plus synthetic in-memory stalled ReadAsync cancellation.
# No external sockets, no original adapter invocation, no modifications outside own receipt directory.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$v2=Join-Path $root '03_Drafts\R002R14_9807_TwoQueue_Bounded90s_v2_DRAFT.ps1'
$own=Join-Path $root '05_Evidence\R002R16_ExactUriCancel_001'
$launcher='C:\work\UUP_Source\26300.9807_687d1ced\uup_download_windows.cmd'
$uuid='687d1ced-aab1-4cd5-ad05-705189769731'
if ([IO.Directory]::Exists($own) -or [IO.File]::Exists($own)) { throw 'R002R16_OWNED_OUTPUT_COLLISION' }
[void][IO.Directory]::CreateDirectory($own)
$receipt=Join-Path $own 'R002R16_ExactUriCancel_NativeReceipt.txt'
$clock=[Diagnostics.Stopwatch]::StartNew()
function Mark([string]$line) {
 $v=('{0:D5}ms|{1}' -f $clock.ElapsedMilliseconds,$line)
 [IO.File]::AppendAllText($receipt,$v+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
 Write-Output $v
}
function Gate([string]$reason) { throw "R002R6_GATE=$reason" }
function Query([uri]$u,[string]$key) {
 $matches=@($u.Query.TrimStart('?').Split('&') | Where-Object { $_.Split('=',2)[0] -ieq $key })
 if ($matches.Count -ne 1) { Gate 'DUPLICATE_OR_MISSING_QUERY_KEY' }
 return [uri]::UnescapeDataString($matches[0].Split('=',2)[1])
}
function VerifyUrl([uri]$u,[string]$pack,[string]$edition) {
 if ($u.Scheme -cne 'https' -or $u.Host -cne 'uupdump.net' -or $u.AbsolutePath -cne '/get.php' -or $u.UserInfo -or $u.Fragment) { Gate 'ENDPOINT_URI_SCOPE' }
 $all=@($u.Query.TrimStart('?').Split('&') | ForEach-Object { $_.Split('=',2)[0].ToLowerInvariant() } | Sort-Object)
 if (($all -join ',') -cne 'aria2,edition,id,pack') { Gate 'ENDPOINT_QUERY_KEYS' }
 if ((Query $u 'id') -cne $uuid -or (Query $u 'pack') -cne $pack -or (Query $u 'edition') -cne $edition -or (Query $u 'aria2') -cne '2') { Gate 'ENDPOINT_QUERY_VALUES' }
}
function AstFn($ast,[string]$name) {
 $a=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst]},$true) | Where-Object {$_.Name -ceq $name})
 if ($a.Count -ne 1) { throw ('AST_FN_NOT_UNIQUE_'+$name) }
 return $a[0].Extent.Text.Trim()
}
function RequireGate([string]$id,[uri]$u,[string]$pack,[string]$edition,[string]$expected) {
 $actual=''
 try { VerifyUrl $u $pack $edition } catch { $actual=$_.Exception.Message }
 if ($actual -cne "R002R6_GATE=$expected") { throw "NEGATIVE_WRONG_GATE=$id" }
 Mark ('PASS_NEGATIVE_'+$id+'_'+$expected)
}
try {
 Mark 'BEGIN_R002R16_EXACT_URI_CANCEL_NATIVE'
 $tokens=$null;$errs=$null
 $oldAst=[Management.Automation.Language.Parser]::ParseFile($v2,[ref]$tokens,[ref]$errs)
 if (@($errs).Count -ne 0) { throw 'V2_AST_ERROR' }
 $tokens=$null;$errs=$null
 $newAst=[Management.Automation.Language.Parser]::ParseFile($PSCommandPath,[ref]$tokens,[ref]$errs)
 if (@($errs).Count -ne 0) { throw 'R16_AST_ERROR' }
 foreach($name in @('Query','VerifyUrl')) {
  if ((AstFn $oldAst $name) -cne (AstFn $newAst $name)) { throw ('NOT_EXACT_V2_FN_'+$name) }
  Mark ('PASS_EXACT_V2_AST_FUNCTION_'+$name)
 }
 Mark 'BEGIN_LAUNCHER_EXACT_WINDOWS_URI'
 $raw=[IO.File]::ReadAllText($launcher)
 $found=@([regex]::Matches($raw,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object Value | Select-Object -Unique)
 $win=@($found | Where-Object {
  try { (Query ([uri]$_) 'edition') -ceq 'professional' } catch { $false }
 })
 if ($win.Count -ne 1) { Gate 'ORIGINAL_WINDOWS_ENDPOINT_NOT_UNIQUE' }
 $windows=[uri]$win[0]
 $apps=[uri]("https://uupdump.net/get.php?id=$uuid&pack=neutral&edition=app&aria2=2")
 VerifyUrl $windows 'en-us' 'professional'
 Mark 'PASS_EXACT_WINDOWS_URI'
 VerifyUrl $apps 'neutral' 'app'
 Mark 'PASS_EXACT_APPS_URI'
 RequireGate 'HOST' ([uri]("https://example.invalid/get.php?id=$uuid&pack=en-us&edition=professional&aria2=2")) 'en-us' 'professional' 'ENDPOINT_URI_SCOPE'
 RequireGate 'EDITION' ([uri]("https://uupdump.net/get.php?id=$uuid&pack=en-us&edition=enterprise&aria2=2")) 'en-us' 'professional' 'ENDPOINT_QUERY_VALUES'
 RequireGate 'DUPLICATE_ID' ([uri]("https://uupdump.net/get.php?id=$uuid&id=$uuid&pack=en-us&edition=professional&aria2=2")) 'en-us' 'professional' 'ENDPOINT_QUERY_KEYS'
 RequireGate 'MISSING_ARIA2' ([uri]("https://uupdump.net/get.php?id=$uuid&pack=en-us&edition=professional")) 'en-us' 'professional' 'ENDPOINT_QUERY_KEYS'
 RequireGate 'USERINFO' ([uri]("https://user@uupdump.net/get.php?id=$uuid&pack=en-us&edition=professional&aria2=2")) 'en-us' 'professional' 'ENDPOINT_URI_SCOPE'
 Mark 'BEGIN_SYNTHETIC_MEMORY_READ_CANCEL'
 $b=[byte[]]::new(16)
 $ms=[IO.MemoryStream]::new([byte[]](65,66,67))
 $pre=[Threading.CancellationTokenSource]::new()
 try {
  $pre.Cancel()
  $wasCancelled=$false
  try { [void]$ms.ReadAsync($b,0,$b.Length,$pre.Token).GetAwaiter().GetResult() } catch [OperationCanceledException] { $wasCancelled=$true }
  if (-not $wasCancelled) { throw 'PRE_CANCEL_READ_FAILED' }
  Mark 'PASS_PRE_CANCELLED_MEMORYSTREAM_READASYNC'
 } finally { $ms.Dispose();$pre.Dispose() }
 Mark 'BEGIN_SYNTHETIC_STALLED_PIPE_READ'
 [void][Reflection.Assembly]::Load('System.IO.Pipelines')
 $pipe=[System.IO.Pipelines.Pipe]::new()
 $stream=$pipe.Reader.AsStream()
 $cts=[Threading.CancellationTokenSource]::new()
 try {
  $cts.CancelAfter([TimeSpan]::FromMilliseconds(150))
  $pending=$stream.ReadAsync($b,0,$b.Length,$cts.Token)
  $watchdog=[Threading.Tasks.Task]::Delay(1800)
  $first=[Threading.Tasks.Task]::WhenAny($pending,$watchdog).GetAwaiter().GetResult()
  if (-not [object]::ReferenceEquals($first,$pending)) { throw 'STALLED_PIPE_READ_WATCHDOG_EXPIRED' }
  $cancelled=$false
  try { [void]$pending.GetAwaiter().GetResult() } catch [OperationCanceledException] { $cancelled=$true }
  if (-not $cancelled) { throw 'STALLED_PIPE_READ_NOT_CANCELLED' }
  Mark 'PASS_STALLED_INMEMORY_PIPE_READASYNC_CANCEL_AFTER_150MS'
 } finally {
  $cts.Cancel()
  $cts.Dispose()
  $stream.Dispose()
  $pipe.Writer.Complete()
 }
 Mark 'HTTP_GET_REQUESTS=0'
 Mark 'WIM_Dism_Registry_ImageMutations=0'
 Mark 'RESULT=PASS_R002R16_EXACT_URI_AND_INMEMORY_STREAM_CANCEL_NATIVE'
} catch {
 Mark ('RESULT=HOLD_R002R16_STAGE;ERROR='+$_.Exception.Message)
 exit 86
}
