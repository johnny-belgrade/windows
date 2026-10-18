param(
 [string]$ModulePath,
 [string]$PlanPath,
 [string]$ReceiptPath,
 [string]$TransactionPath,
 [string]$NativePath,
 [string]$ModuleSHA,
 [string]$PlanSHA,
 [string]$ReceiptSHA,
 [string]$TransactionSHA,
 [string]$NativeSHA
)
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $report='C:\work\logs\BlueLite_MAXPRE_OwnedLifecycle_26300.9711.txt'
 $output='C:\work\logs\BlueLite_MAXPRE_OwnedLifecycle_26300.9711.json'
 foreach($f in @($report,$output)){if(Test-Path -LiteralPath $f){throw 'BL_REPORT_EXISTS_NO_OVERWRITE'}}
 $utf8=[Text.UTF8Encoding]::new($false)
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$s){
  Write-Host $s
  [IO.File]::AppendAllText($report,$s+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$name,[string]$path,[string]$sha){
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha){
   throw ('BL_SHA_MISMATCH_'+$name)
  }
  Note ('PIN_'+$name+'=PASS')
 }
 function ExpectReject([string]$name,[scriptblock]$action,[string]$errorName){
  $caught=''
  try{$null=& $action}catch{$caught=$_.Exception.Message}
  if($caught -cne $errorName){throw ('BL_EXPECTED_DENIAL_FAILED_'+$name+'='+$caught)}
  Note ('DENIAL_'+$name+'=PASS')
 }
 $result='HOLD_MAXPRE_OWNED_LIFECYCLE'
 try{
  Note 'MAXPRE_OWNED_WIM_LIFECYCLE_REAL_EVIDENCE_TEST'
  Note 'NO_COPY_NO_DISM_NO_MOUNT_NO_MUTATION'
  Pin 'MODULE' $ModulePath $ModuleSHA
  Pin 'PLAN' $PlanPath $PlanSHA
  Pin 'RECEIPT' $ReceiptPath $ReceiptSHA
  Pin 'TRANSACTION' $TransactionPath $TransactionSHA
  Pin 'NATIVE' $NativePath $NativeSHA
  Import-Module -Name $ModulePath -Force -ErrorAction Stop
  $plan=Get-Content -LiteralPath $PlanPath -Raw|ConvertFrom-Json -Depth 80
  $receipt=Get-Content -LiteralPath $ReceiptPath -Raw|ConvertFrom-Json -Depth 80
  $tx=(Get-Content -LiteralPath $TransactionPath -Raw|ConvertFrom-Json -Depth 80).transaction
  $native=Get-Content -LiteralPath $NativePath -Raw|ConvertFrom-Json -Depth 80
  $l=New-BlueLiteOwnedWimLifecycle -Plan $plan -Receipt $receipt -Transaction $tx -NativeReceipt $native
  if($l.source_build -cne '26300.9711' -or $l.recipe_count -ne 6 -or
     $l.actionable_recipe_count -ne 0 -or
     $l.preparation_authorized -cne $false -or
     $l.lifecycle_state -cne 'BLOCKED_BEFORE_PREPARE'){
   throw 'BL_LIFECYCLE_STATE_DRIFT'
  }
  Note ('RECIPE_COUNT='+$l.recipe_count+';ACTIONABLE=0;PREPARE=BLOCKED')
  foreach($reason in @('SOURCE_SHA_NOT_VERIFIED_THIS_RUN','NATIVE_HEALTH_NOT_PROVEN',
     'PROTECTED_FLOOR_NOT_PROVEN','NATIVE_OPERATOR_AUTHORIZATION_MISSING',
     'TRANSACTION_OPERATOR_AUTHORIZATION_MISSING','NO_AUTHORIZED_ACTIONABLE_RECIPE')){
   if($reason -cnotin @($l.gate_blockers)){throw ('BL_BLOCK_REASON_MISSING='+$reason)}
   Note ('BLOCK='+$reason)
  }
  ExpectReject 'FORCED_PREPARE' {
   Invoke-BlueLiteOwnedWimPrepare -Lifecycle $l -OwnerRoot 'C:\work' -ExplicitOperatorApproval -ExpectedSourceSHA256 'F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
  } 'BL_PREPARE_BLOCKED_BY_EVIDENCE_AND_RECIPE_GATES'
  $n=($native|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $n.dism_index_one_germanium_26300=$false
  ExpectReject 'FALSE_NATIVE_INDEX' {
   New-BlueLiteOwnedWimLifecycle -Plan $plan -Receipt $receipt -Transaction $tx -NativeReceipt $n
  } 'BL_LIFECYCLE_NATIVE_OR_TX_PRECONDITIONS_NOT_PROVEN'
  $n=($native|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $n.source_run_id='FORGED'
  ExpectReject 'FALSE_SOURCE_RUN' {
   New-BlueLiteOwnedWimLifecycle -Plan $plan -Receipt $receipt -Transaction $tx -NativeReceipt $n
  } 'BL_LIFECYCLE_SOURCE_RUN_OR_BUILD_MISMATCH'
  $p=($plan|ConvertTo-Json -Depth 80|ConvertFrom-Json -Depth 80)
  $p.planned_working_wim_path=([string]$p.original_wim_path).ToUpperInvariant()
  ExpectReject 'CASE_ALIAS' {
   New-BlueLiteOwnedWimLifecycle -Plan $p -Receipt $receipt -Transaction $tx -NativeReceipt $native
  } 'BL_LIFECYCLE_SOURCE_WORKING_ALIAS'
  $record=[ordered]@{
   source_run_id=$l.source_run_id
   source_build=$l.source_build
   lifecycle=$l
   source_wim_sha256_reread=$false
   working_image_copied=$false
   result='STATIC_LIFECYCLE_PASS_PREPARE_BLOCKED'
  }
  [IO.File]::WriteAllText($output,($record|ConvertTo-Json -Depth 35),$utf8)
  Note ('JSON='+$output)
  $result='PASS_MAXPRE_OWNED_LIFECYCLE_TESTS_NO_IMAGE_TOUCH'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'COPY_MOUNT_WIM_HASH_MUTATION=NOT_RUN'
  Write-Host ('REPORT='+$report)
 }
 if($result -ne 'PASS_MAXPRE_OWNED_LIFECYCLE_TESTS_NO_IMAGE_TOUCH'){
  throw 'BL_OWNED_LIFECYCLE_TEST_FAILED'
 }
}