# BlueLite R002R14 - native exact-gate regression; NEW source; no network GET.
# Uses R002R10 declared fixtures, pinned D4 module/draft, and a unique owned result.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$specPath=Join-Path $root '02_Analysis\R002R10_ExactGate_NegativeSpec_20261022.json'
$mod='C:\work\scripts\BlueLite_Stage1_S06_26300_G4_AppsOnly\BlueLite_QueueIdentity.psm1'
$draft=Join-Path $root '03_Drafts\R002R6_9807_TwoQueue_MetadataOnly_DRAFT.ps1'
$out=Join-Path $root '04_StaticTests\R002R14_ExactGates_001'
$getOutput=Join-Path $root '05_Evidence\R002R6_9807_NewQueue_001'
function StopGate([string]$name) { throw "R002R14_QA_HOLD=$name" }
if ([IO.Directory]::Exists($out) -or [IO.File]::Exists($out)) { StopGate 'RESULT_COLLISION' }
if ([IO.Directory]::Exists($getOutput) -or [IO.File]::Exists($getOutput)) { StopGate 'GET_OUTPUT_ALREADY_EXISTS' }
if (-not [IO.File]::Exists($specPath)) { StopGate 'SPEC_ABSENT' }
if ((Get-FileHash -LiteralPath $mod -Algorithm SHA256).Hash -cne '7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E') { StopGate 'D4_MODULE_SHA_DRIFT' }
if ((Get-FileHash -LiteralPath $draft -Algorithm SHA256).Hash -cne '755412852CF6E6A16DAC25386DFD988B2743924039BF969E0AB4DB91163D460F') { StopGate 'ORIGINAL_DRAFT_SHA_DRIFT' }
$spec=Get-Content -LiteralPath $specPath -Raw | ConvertFrom-Json
if ($spec.schema -cne 'BlueLite.PREMAX.R002R10.NegativeGateSpec.v1' -or $spec.cases.Count -ne 7 -or $spec.runtime_execution_allowed -ne $false) { StopGate 'SPEC_CONTRACT_DRIFT' }
$ids=@('N01_EMPTY','N02_MISSING_CHECKSUM','N03_UNSAFE_OUT','N04_UNSUPPORTED_CHECKSUM','N05_DUPLICATE_OUT','N06_SERVER_ERROR','N07_AUTHORIZATION_DENY')
for ($i=0; $i -lt 7; $i++) { if ($spec.cases[$i].id -cne $ids[$i]) { StopGate 'SPEC_CASE_ID_DRIFT' } }
Import-Module -Name $mod -Force -ErrorAction Stop
[void][IO.Directory]::CreateDirectory($out)
$receipt=Join-Path $out 'R002R14_ExactNegative_NativeReceipt.txt'
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('BLUELITE_R002R14_EXACT_NEGATIVE_GATE_NATIVE_V1')
$lines.Add('SOURCE_BUILD=26300.9807')
$lines.Add('MODE=OWNED_SYNTHETIC_NO_NETWORK')
$lines.Add('D4_SHA256=7015C86B97F91E38D691B2831B9AD353EB6D2369E8AD69559B8DC6FF5E31745E')
$lines.Add('ORIGINAL_DRAFT_SHA256=755412852CF6E6A16DAC25386DFD988B2743924039BF969E0AB4DB91163D460F')
$passed=0
try {
  for ($i=0; $i -lt 6; $i++) {
    $case=$spec.cases[$i]
    if ([string]::IsNullOrEmpty([string]$case.expected_error_prefix) -or $null -eq $case.fixture_content) { StopGate ('INCOMPLETE_SPEC_'+$case.id) }
    $fixture=Join-Path $out ($case.id+'.txt')
    [IO.File]::WriteAllText($fixture,[string]$case.fixture_content,[Text.UTF8Encoding]::new($false))
    $actual=''
    try {
      $null=Get-BlueLiteQueueIdentity -Path $fixture
    } catch {
      $actual=$_.Exception.Message
    }
    if ($actual -ceq '') { StopGate ('UNEXPECTED_ACCEPT_'+$case.id) }
    if (-not $actual.StartsWith([string]$case.expected_error_prefix,[StringComparison]::Ordinal)) { StopGate ('WRONG_GATE_'+$case.id) }
    $passed++
    $lines.Add(('CASE_'+$case.id+'=PASS_EXACT_PREFIX_'+$case.expected_error_key))
  }
  $last=$spec.cases[6]
  if ($last.expected_error_exact -cne 'R002R6_GATE=EXPLICIT_GUI_APPROVAL_REQUIRED' -or $last.source_authorization -cne 'NOT_AUTHORIZED') { StopGate 'AUTH_CASE_SPEC_DRIFT' }
  $actual=''
  try {
    & $draft -Mode Fetch -Authorization NOT_AUTHORIZED | Out-Null
  } catch {
    $actual=$_.Exception.Message
  }
  if ($actual -cne [string]$last.expected_error_exact) { StopGate 'AUTH_NOT_EXACT_OR_SOURCE_DRIFT' }
  if ([IO.Directory]::Exists($getOutput) -or [IO.File]::Exists($getOutput)) { StopGate 'UNAUTHORIZED_GET_OUTPUT' }
  $passed++
  $lines.Add('CASE_N07_AUTHORIZATION_DENY=PASS_EXACT_MESSAGE')
  $lines.Add('PASSED='+$passed+'/7')
  $lines.Add('HTTP_GET_ATTEMPTS=0')
  $lines.Add('NETWORK_PAYLOAD=NONE')
  $lines.Add('ORIGINAL_SCRIPTS_MODIFIED=FALSE')
  $lines.Add('RESULT=PASS_R002R14_EXACT_GATE_NATIVE_7_OF_7')
  [IO.File]::WriteAllLines($receipt,$lines.ToArray(),[Text.UTF8Encoding]::new($false))
  'RESULT=PASS_R002R14_EXACT_GATE_NATIVE_7_OF_7;NETWORK=NONE'
} catch {
  $lines.Add('PASSED_BEFORE_HOLD='+$passed+'/7')
  $lines.Add('RESULT=HOLD_R002R14_EXACT_GATE_NATIVE')
  $lines.Add('QA_ERROR='+$_.Exception.Message)
  [IO.File]::WriteAllLines($receipt,$lines.ToArray(),[Text.UTF8Encoding]::new($false))
  throw
}
