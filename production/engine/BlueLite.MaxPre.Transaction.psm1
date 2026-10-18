# BlueLite universal MAX_PRE transaction gate v0.1.
# This code deliberately contains NO filesystem image mutators or native DISM calls.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Assert-BlueLitePlanReceiptPair {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Plan,
  [Parameter(Mandatory)][object]$Receipt
 )
 if($null -eq $Plan -or $null -eq $Receipt){throw 'BL_TX_PAIR_NULL'}
 if([string]$Plan.plan_version -cne '1.0.0' -or
    [string]$Plan.mode -cne 'MAX_PRE' -or
    [string]$Receipt.phase -cne 'MAX_PRE' -or
    [string]$Receipt.contract_version -cne '1.0.0'){
  throw 'BL_TX_CONTRACT_OR_PHASE_DRIFT'
 }
 if([string]::IsNullOrWhiteSpace([string]$Plan.run_id) -or
    [string]$Plan.run_id -cne [string]$Receipt.run_id -or
    [string]$Plan.source_build -cne [string]$Receipt.source_build -or
    [string]$Plan.source_contract_sha256 -cne [string]$Receipt.source_contract_sha256 -or
    [string]$Plan.controller_sha256 -cne [string]$Receipt.script_sha256){
  throw 'BL_TX_CROSS_RECEIPT_IDENTITY_DRIFT'
 }
 if([string]$Plan.source_build -cnotmatch '^[0-9]{5}\.[0-9]+$'){
  throw 'BL_TX_UNRECOGNIZED_BUILD'
 }
 if([string]$Receipt.result -cne 'STATIC_VERIFIED' -or
    [string]$Receipt.evidence_tier -cne 'STATIC' -or
    $Receipt.operator_executed -cne $true -or
    $Receipt.mutation_performed -cne $false -or
    $Receipt.next_action_authorized -cne $false -or
    $Receipt.independent_post_state_verified -cne $false -or
    $Plan.execution_authorized -cne $false -or
    [int]$Plan.mutations_executed -ne 0 -or
    $Plan.original_wim_sha256_verified_this_run -cne $false){
  throw 'BL_TX_UNEXPECTED_RUNTIME_OR_MUTATION_CLAIM'
 }
 if([string]::Equals([string]$Plan.original_wim_path,[string]$Plan.planned_working_wim_path,[StringComparison]::OrdinalIgnoreCase) -or
    $Plan.original_working_distinct -cne $true){
  throw 'BL_TX_ORIGINAL_WORKING_ALIAS'
 }
 $a=@($Plan.recipes)
 $b=@($Receipt.recipe_results)
 if($a.Count -lt 1 -or $a.Count -ne [int]$Plan.recipe_count -or
    $a.Count -ne $b.Count){
  throw 'BL_TX_RECIPE_COUNT_MISMATCH'
 }
 $seen=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 for($i=0;$i -lt $a.Count;$i++){
  $x=$a[$i]
  $y=$b[$i]
  if(-not $seen.Add([string]$x.RecipeId)){throw 'BL_TX_DUPLICATE_RECIPE_ID'}
  foreach($field in @('RecipeId','Phase','Build','VariantId','Decision')){
   if([string]$x.$field -cne [string]$y.$field){
    throw ('BL_TX_RECIPE_DECISION_MISMATCH='+$field)
   }
  }
  if($x.AutoExecute -cne $false -or $y.AutoExecute -cne $false){
   throw 'BL_TX_AUTOEXECUTION_FLAG_NOT_FALSE'
  }
  if([string]$x.Build -cne [string]$Plan.source_build){
   throw 'BL_TX_RECIPE_BUILD_MISMATCH'
  }
 }
 return [pscustomobject]@{
  PairContract='PASS'
  RunId=[string]$Plan.run_id
  Build=[string]$Plan.source_build
  RecipeCount=$a.Count
  SourceContractSHA256=[string]$Plan.source_contract_sha256
  ControllerSHA256=[string]$Plan.controller_sha256
  WIMHashIndependentlyVerifiedInPlan=$false
 }
}

function Resolve-BlueLiteTransactionRecipe {
 [CmdletBinding()]
 param([Parameter(Mandatory)][object]$Recipe)
 $reason=switch([string]$Recipe.Decision){
  'RED_HOLD' {'DEPENDENCY_RED_HOLD';break}
  'COMPONENT_ENGINE_HANDOFF' {'NEEDS_COMPONENT_ENGINE';break}
  'RECIPE_RUNTIME_DISABLED' {'RECIPE_EXECUTION_NOT_ENABLED';break}
  'NO_CERTIFIED_BUILD_TOPOLOGY' {'NO_CURRENT_AUTOEXEC_TOPOLOGY';break}
  'MULTIPLE_VARIANTS_REVIEW_REQUIRED' {'AMBIGUOUS_VARIANT';break}
  'RECIPE_RUNTIME_FLAG_TRUE_STILL_NEEDS_OPERATOR_AND_IMAGE_GATES' {'RUNTIME_EVIDENCE_REQUIRED';break}
  default {'UNRECOGNIZED_RECIPE_DECISION'}
 }
 return [pscustomobject]@{
  RecipeId=[string]$Recipe.RecipeId
  VariantId=[string]$Recipe.VariantId
  Decision=[string]$Recipe.Decision
  BlockReason=$reason
  TransactionStatus='NOT_EXECUTABLE'
  EligibleForMutation=$false
  MutationApplied=$false
 }
}

function New-BlueLiteMaxPreTransaction {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Plan,
  [Parameter(Mandatory)][object]$Receipt
 )
 $pair=Assert-BlueLitePlanReceiptPair -Plan $Plan -Receipt $Receipt
 $actions=@($Plan.recipes|ForEach-Object {Resolve-BlueLiteTransactionRecipe -Recipe $_})
 if($actions.Count -ne $pair.RecipeCount){throw 'BL_TX_ACTION_COUNT_DRIFT'}
 return [pscustomobject]@{
  transaction_contract_version='0.1.0'
  source_run_id=$pair.RunId
  source_build=$pair.Build
  source_contract_sha256=$pair.SourceContractSHA256
  original_wim_path=[string]$Plan.original_wim_path
  working_wim_path=[string]$Plan.planned_working_wim_path
  working_wim_created=$false
  current_source_wim_sha_verified=$false
  native_mount_state_verified=$false
  recipe_runtime_enabled=$false
  operator_mutation_authorized=$false
  protected_floor_verified=$false
  native_servicing_health_verified=$false
  actions=$actions
  action_count=$actions.Count
  mutations_executed=0
  transaction_status='PREFLIGHT_ONLY_MUTATION_BLOCKED'
  next_stage='OWNED_IMAGE_TRANSACTION_ENGINE_RUNTIME_GATE'
  transaction_authorized=$false
 }
}

function Assert-BlueLiteMaxPreMutationGate {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Transaction,
  [switch]$OperatorAuthorization,
  [switch]$RecipeAuthorization,
  [switch]$ImageOwnership,
  [switch]$NativeHealthVerified
 )
 if($null -eq $Transaction -or
    [string]$Transaction.transaction_contract_version -cne '0.1.0'){
  throw 'BL_TX_OBJECT_MISSING_OR_UNRECOGNIZED'
 }
 if(-not $OperatorAuthorization -or -not $RecipeAuthorization -or
    -not $ImageOwnership -or -not $NativeHealthVerified){
  throw 'BL_TX_MUTATION_NOT_AUTHORIZED_OR_NOT_CERTIFIED'
 }
 # No call-site switch can assert native evidence, protected floor, or
 # substitute for a certifiable owned-WIM transaction executor.
 throw 'BL_TX_NATIVE_MUTATION_DISPATCHER_NOT_YET_CERTIFIED'
}

Export-ModuleMember -Function Assert-BlueLitePlanReceiptPair,Resolve-BlueLiteTransactionRecipe,New-BlueLiteMaxPreTransaction,Assert-BlueLiteMaxPreMutationGate
