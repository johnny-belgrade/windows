param(
 [Parameter(Mandatory)][string]$ModulePath,
 [Parameter(Mandatory)][string]$PlanPath,
 [Parameter(Mandatory)][string]$ReceiptPath,
 [Parameter(Mandatory)][string]$ExpectedModuleSHA256,
 [Parameter(Mandatory)][string]$ExpectedPlanSHA256,
 [Parameter(Mandatory)][string]$ExpectedReceiptSHA256
)
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $log='C:\work\logs\BlueLite_MAXPRE_TransactionGate_26300.9711.txt'
 $json='C:\work\logs\BlueLite_MAXPRE_TransactionGate_26300.9711.json'
 $utf8=[Text.UTF8Encoding]::new($false)
 foreach($f in @($log,$json)){
  if(Test-Path -LiteralPath $f){throw ('BL_TEST_OUTPUT_EXISTS_NO_OVERWRITE='+$f)}
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$message){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$path,[string]$expected){
  $hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop).Hash
  if($hash -cne $expected.ToUpperInvariant()){throw ('BL_SHA_DRIFT_'+$tag+'='+$hash)}
  Note ('SHA_'+$tag+'=PASS;'+$hash)
 }
 function MustReject([string]$tag,[scriptblock]$body,[string]$reason){
  $caught=''
  try{$null=& $body}catch{$caught=$_.Exception.Message}
  if($caught -cne $reason){throw ('BL_NEGATIVE_FAILED='+$tag+';ACTUAL='+$caught)}
  Note ('NEGATIVE='+$tag+';EXPECTED_REJECTION=PASS;'+$reason)
 }
 $result='HOLD_MAXPRE_TRANSACTION_GATE_STATIC_ONLY'
 try{
  Note 'MAXPRE_TRANSACTION_GATE_CURRENT_R1_EVIDENCE_NEGATIVE_FIXTURES'
  Note 'NO_WIM_IO_NO_DISM_NO_REGISTRY_MUTATION_NO_MOUNT_NO_DOWNLOAD'
  Pin 'MODULE' $ModulePath $ExpectedModuleSHA256
  Pin 'PLAN_R1' $PlanPath $ExpectedPlanSHA256
  Pin 'RECEIPT_R1' $ReceiptPath $ExpectedReceiptSHA256
  Import-Module -Name $ModulePath -Force -ErrorAction Stop
  $plan=Get-Content -LiteralPath $PlanPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 80 -ErrorAction Stop
  $receipt=Get-Content -LiteralPath $ReceiptPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 80 -ErrorAction Stop
  $pair=Assert-BlueLitePlanReceiptPair -Plan $plan -Receipt $receipt
  if($pair.Build -cne '26300.9711' -or $pair.RecipeCount -ne 6 -or
     $pair.RunId -cne 'BL-26300.9711-20261018T085316328Z'){
   throw 'BL_CURRENT_OPERATOR_R1_IDENTITY_CHANGED'
  }
  Note ('SOURCEBOUND_R1_PAIR=PASS;RUN='+$pair.RunId+';RECIPES='+$pair.RecipeCount)
  $transaction=New-BlueLiteMaxPreTransaction -Plan $plan -Receipt $receipt
  if($transaction.action_count -ne 6 -or
     $transaction.transaction_authorized -cne $false -or
     $transaction.mutations_executed -ne 0 -or
     @($transaction.actions|Where-Object {$_.EligibleForMutation -ne $false}).Count -gt 0){
   throw 'BL_TRANSACTION_AUTOEXECUTION_OR_COUNT_DRIFT'
  }
  foreach($a in $transaction.actions){
   Note ('TRANSACTION_RECIPE='+$a.RecipeId+';VARIANT='+$a.VariantId+
    ';BLOCK='+$a.BlockReason+';ELIGIBLE='+$a.EligibleForMutation)
  }
  $oneDrive=@($transaction.actions|Where-Object {$_.RecipeId -ceq 'BL.CBS.OneDrive.NeutralSequence'})
  if($oneDrive.Count -ne 1 -or $oneDrive[0].BlockReason -cne 'RECIPE_EXECUTION_NOT_ENABLED'){
   throw 'BL_S31_ONEDRIVE_RUNTIME_DISPOSITION_DRIFT'
  }
  Note 'TRANSACTION_6_RECIPES_CLASSIFIED=PASS;AUTO_MUTATIONS=0'
  $r1=($receipt|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $r1.run_id='BL-WRONG-RUN'
  MustReject 'RECEIPT_RUN_DRIFT' {
   Assert-BlueLitePlanReceiptPair -Plan $plan -Receipt $r1
  } 'BL_TX_CROSS_RECEIPT_IDENTITY_DRIFT'
  $r2=($receipt|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $r2.next_action_authorized=$true
  MustReject 'FORGED_EXECUTION_AUTHORIZATION' {
   Assert-BlueLitePlanReceiptPair -Plan $plan -Receipt $r2
  } 'BL_TX_UNEXPECTED_RUNTIME_OR_MUTATION_CLAIM'
  $p1=($plan|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $p1.recipes[0].AutoExecute=$true
  MustReject 'FORGED_RECIPE_AUTOEXECUTION' {
   Assert-BlueLitePlanReceiptPair -Plan $p1 -Receipt $receipt
  } 'BL_TX_AUTOEXECUTION_FLAG_NOT_FALSE'
  MustReject 'MUTATION_DEFAULT_DENIED' {
   Assert-BlueLiteMaxPreMutationGate -Transaction $transaction
  } 'BL_TX_MUTATION_NOT_AUTHORIZED_OR_NOT_CERTIFIED'
  MustReject 'MUTATION_ALL_CALLER_SWITCHES_FORCED_DENIED' {
   Assert-BlueLiteMaxPreMutationGate -Transaction $transaction -OperatorAuthorization -RecipeAuthorization -ImageOwnership -NativeHealthVerified
  } 'BL_TX_NATIVE_MUTATION_DISPATCHER_NOT_YET_CERTIFIED'
  $caseVariant=($plan|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $caseVariant.planned_working_wim_path=([string]$plan.original_wim_path).ToUpperInvariant()
  MustReject 'CASE_INSENSITIVE_WIM_ALIAS' {
   Assert-BlueLitePlanReceiptPair -Plan $caseVariant -Receipt $receipt
  } 'BL_TX_ORIGINAL_WORKING_ALIAS'
  $record=[ordered]@{
   transaction=$transaction
   evidence_pair_hashes=[ordered]@{
    module=$ExpectedModuleSHA256.ToUpperInvariant()
    plan=$ExpectedPlanSHA256.ToUpperInvariant()
    receipt=$ExpectedReceiptSHA256.ToUpperInvariant()
   }
   test_result='STATIC_CONTRACT_PASS_MUTATION_BLOCKED'
   deletion_or_wim_access_performed=$false
  }
  [IO.File]::WriteAllText($json,($record|ConvertTo-Json -Depth 40),$utf8)
  $back=Get-Content -LiteralPath $json -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 50 -ErrorAction Stop
  if($back.transaction.action_count -ne 6 -or $back.transaction.transaction_authorized -ne $false -or
     $back.test_result -cne 'STATIC_CONTRACT_PASS_MUTATION_BLOCKED'){
   throw 'BL_TRANSACTION_JSON_ROUNDTRIP_FAILED'
  }
  Note ('TRANSACTION_JSON='+$json)
  $result='PASS_MAXPRE_TRANSACTION_GATE_STATIC_NEGATIVE_TESTS_NO_IMAGE_TOUCH'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'ACTUAL_MUTATION_NOT_AUTHORIZED;WIM_MOUNT_CLONE_DISM_NOT_RUN'
  Write-Host ('REPORT='+$log)
 }
 if($result -ne 'PASS_MAXPRE_TRANSACTION_GATE_STATIC_NEGATIVE_TESTS_NO_IMAGE_TOUCH'){
  throw 'BL_TRANSACTION_GATE_TEST_FAILED'
 }
}