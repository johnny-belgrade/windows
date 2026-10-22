# BlueLite R002-R15: distinct read-only staged diagnostic of v2 Probe input preflight. No network.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$own=Join-Path $root '05_Evidence\R002R15_Probe_Preflight_001'
$draft=Join-Path $root '03_Drafts\R002R14_9807_TwoQueue_Bounded90s_v2_DRAFT.ps1'
$inputRoot='C:\work\UUP_Source\26300.9807_687d1ced'
$zip=Join-Path $inputRoot '26300.9807_amd64_en-us_professional_687d1ced_convert.zip'
$launcher=Join-Path $inputRoot 'uup_download_windows.cmd'
$contract=Join-Path $inputRoot 'BlueLite_S11_SourceContract.json'
$module='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
if ([IO.Directory]::Exists($own) -or [IO.File]::Exists($own)) { throw 'R002R15_OWNED_COLLISION' }
[void][IO.Directory]::CreateDirectory($own)
$receipt=Join-Path $own 'R002R15_ProbePreflight_Stages.txt'
$clock=[Diagnostics.Stopwatch]::StartNew()
function Mark([string]$value) {
  $line=('{0:D5}ms|{1}' -f $clock.ElapsedMilliseconds,$value)
  [IO.File]::AppendAllText($receipt,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
  Write-Output $line
}
function ExpectHash([string]$tag,[string]$path,[string]$expected) {
  Mark "BEGIN_SHA_$tag"
  if (-not [IO.File]::Exists($path)) { throw "MISSING_$tag" }
  $actual=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()
  if ($actual -cne $expected) { throw "SHA_DRIFT_$tag" }
  Mark "PASS_SHA_$tag"
}
try {
  Mark 'BEGIN_R002R15_READ_ONLY_STAGE_DIAGNOSTIC'
  Mark ('PS_VERSION='+$PSVersionTable.PSVersion.ToString())
  Mark 'BEGIN_AST'
  $tokens=$null;$errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile($draft,[ref]$tokens,[ref]$errors)
  if (@($errors).Count -gt 0) { throw 'V2_AST_ERRORS' }
  Mark 'PASS_AST_ERRORS_ZERO'
  ExpectHash 'SOURCE_ZIP' $zip '83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7'
  ExpectHash 'LAUNCHER' $launcher '289EBCBEA3352F66187BDF2E75961A855DAA187F6C9F4739E7301F9C9F12DEB5'
  ExpectHash 'CONTRACT' $contract '9D9DCD4FD8190863F1591679574879D3B652D2FE6DED176EEFED0C204D947D11'
  ExpectHash 'D4_MODULE' $module '7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E'
  Mark 'BEGIN_CONTRACT_PARSE'
  $c=Get-Content -LiteralPath $contract -Raw | ConvertFrom-Json
  if ($c.build -cne '26300.9807' -or $c.uuid -cne '687d1ced-aab1-4cd5-ad05-705189769731' -or $c.architecture -cne 'amd64' -or $c.language -cne 'en-us' -or $c.edition -cne 'professional' -or $c.original_zip_sha256 -cne '83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7') { throw 'FROZEN_CONTRACT_DRIFT' }
  Mark 'PASS_CONTRACT_PARSE'
  Mark 'BEGIN_LAUNCHER_READ_AND_URI_PARSE'
  $raw=[IO.File]::ReadAllText($launcher)
  $found=@([regex]::Matches($raw,'https://uupdump\.net/get\.php\?[^"\s]+') | ForEach-Object Value | Select-Object -Unique)
  $win=@($found | Where-Object {
    try { ([uri]$_).Query -match 'edition=professional' } catch { $false }
  })
  if ($win.Count -ne 1) { throw 'WINDOWS_ENDPOINT_NOT_UNIQUE' }
  $u=[uri]$win[0]
  if ($u.Scheme -cne 'https' -or $u.Host -cne 'uupdump.net' -or $u.AbsolutePath -cne '/get.php') { throw 'WINDOWS_ENDPOINT_SCOPE' }
  $app=[uri]'https://uupdump.net/get.php?id=687d1ced-aab1-4cd5-ad05-705189769731&pack=neutral&edition=app&aria2=2'
  if ($app.Scheme -cne 'https' -or $app.Host -cne 'uupdump.net') { throw 'APP_ENDPOINT_SCOPE' }
  Mark 'PASS_LAUNCHER_URI_PARSE'
  Mark 'NO_EXTERNAL_HTTP_REQUESTS'
  Mark 'RESULT=PASS_R002R15_NATIVE_PREPROBE_STAGE_DIAGNOSTIC'
} catch {
  Mark ('RESULT=HOLD_R002R15_STAGE_DIAGNOSTIC;ERROR='+$_.Exception.Message)
  exit 86
}
