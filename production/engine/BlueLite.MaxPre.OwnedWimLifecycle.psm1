# BlueLite MAX_PRE owner-bound WIM lifecycle v0.1
# Production API: pure source-bound authorization analysis plus an explicitly
# gated, isolated WIM Prepare implementation. No implicit cloning or mounting.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function New-BlueLiteOwnedWimLifecycle {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Plan,
  [Parameter(Mandatory)][object]$Receipt,
  [Parameter(Mandatory)][object]$Transaction,
  [Parameter(Mandatory)][object]$NativeReceipt
 )
 if($null -eq $Plan -or $null -eq $Receipt -or
    $null -eq $Transaction -or $null -eq $NativeReceipt){
  throw 'BL_LIFECYCLE_MISSING_EVIDENCE'
 }
 if([string]$Plan.plan_version -cne '1.0.0' -or
    [string]$Receipt.contract_version -cne '1.0.0' -or
    [string]$NativeReceipt.contract_version -cne '1.0.0' -or
    [string]$Plan.mode -cne 'MAX_PRE' -or
    [string]$Receipt.phase -cne 'MAX_PRE'){
  throw 'BL_LIFECYCLE_CONTRACT_VERSION_OR_PHASE_DRIFT'
 }
 $id=[string]$Plan.run_id
 $build=[string]$Plan.source_build
 if([string]::IsNullOrWhiteSpace($id) -or $build -cnotmatch '^[0-9]{5}\.[0-9]+$' -or
    $id -cne [string]$Receipt.run_id -or
    $id -cne [string]$Transaction.source_run_id -or
    $id -cne [string]$NativeReceipt.source_run_id -or
    $build -cne [string]$Receipt.source_build -or
    $build -cne [string]$Transaction.source_build -or
    $build -cne [string]$NativeReceipt.source_build){
  throw 'BL_LIFECYCLE_SOURCE_RUN_OR_BUILD_MISMATCH'
 }
 $src=[IO.Path]::GetFullPath([string]$Plan.original_wim_path)
 $work=[IO.Path]::GetFullPath([string]$Plan.planned_working_wim_path)
 if([string]::Equals($src,$work,[StringComparison]::OrdinalIgnoreCase) -or
    $Plan.original_working_distinct -cne $true){
  throw 'BL_LIFECYCLE_SOURCE_WORKING_ALIAS'
 }
 foreach($v in @(
  @{Value=$Transaction.original_wim_path;Label='TX_SOURCE'},
  @{Value=$Transaction.working_wim_path;Label='TX_WORK'},
  @{Value=$NativeReceipt.source_wim_path;Label='NATIVE_SOURCE'},
  @{Value=$NativeReceipt.working_wim_path;Label='NATIVE_WORK'}
 )){
  $value=[IO.Path]::GetFullPath([string]$v.Value)
  $expect=if($v.Label -like '*SOURCE'){$src}else{$work}
  if(-not [string]::Equals($value,$expect,[StringComparison]::OrdinalIgnoreCase)){
   throw ('BL_LIFECYCLE_PATH_IDENTITY_DRIFT='+$v.Label)
  }
 }
 if([string]$Receipt.source_contract_sha256 -cne
    [string]$Plan.source_contract_sha256 -or
    [string]$Transaction.source_contract_sha256 -cne
    [string]$Plan.source_contract_sha256){
  throw 'BL_LIFECYCLE_SOURCE_CONTRACT_HASH_DRIFT'
 }
 if([string]$Transaction.transaction_status -cne 'PREFLIGHT_ONLY_MUTATION_BLOCKED' -or
    [string]$NativeReceipt.result -cne 'PASS_MAXPRE_NATIVE_OWNED_PREFLIGHT_READONLY' -or
    $NativeReceipt.dism_zero_mounted_images -cne $true -or
    $NativeReceipt.blue_offline_hive_aliases_zero -cne $true -or
    $NativeReceipt.dism_index_one_germanium_26300 -cne $true){
  throw 'BL_LIFECYCLE_NATIVE_OR_TX_PRECONDITIONS_NOT_PROVEN'
 }
 $recipes=@($Plan.recipes)
 $actions=@($Transaction.actions)
 if($recipes.Count -eq 0 -or $recipes.Count -ne [int]$Plan.recipe_count -or
    $recipes.Count -ne $actions.Count -or $recipes.Count -ne [int]$Transaction.action_count){
  throw 'BL_LIFECYCLE_ACTION_COUNT_DRIFT'
 }
 for($i=0;$i -lt $recipes.Count;$i++){
  if([string]$recipes[$i].RecipeId -cne [string]$actions[$i].RecipeId -or
     [string]$recipes[$i].Decision -cne [string]$actions[$i].Decision -or
     [string]$recipes[$i].VariantId -cne [string]$actions[$i].VariantId){
   throw 'BL_LIFECYCLE_RECIPE_ACTION_PAIR_DRIFT'
  }
 }
 $blocking=[System.Collections.Generic.List[string]]::new()
 if($NativeReceipt.source_wim_sha256_verified_this_run -cne $true){
  $blocking.Add('SOURCE_SHA_NOT_VERIFIED_THIS_RUN')
 }
 if($NativeReceipt.native_image_health_checked -cne $true){
  $blocking.Add('NATIVE_HEALTH_NOT_PROVEN')
 }
 if($NativeReceipt.protected_floor_verified -cne $true){
  $blocking.Add('PROTECTED_FLOOR_NOT_PROVEN')
 }
 if($NativeReceipt.next_action_authorized -cne $true -or
    $NativeReceipt.mutation_authorized -cne $true){
  $blocking.Add('NATIVE_OPERATOR_AUTHORIZATION_MISSING')
 }
 if($Transaction.transaction_authorized -cne $true -or
    $Receipt.next_action_authorized -cne $true){
  $blocking.Add('TRANSACTION_OPERATOR_AUTHORIZATION_MISSING')
 }
 $eligible=@($actions|Where-Object {
  $_.EligibleForMutation -ceq $true -and
  $_.TransactionStatus -ceq 'EXECUTABLE' -and
  $_.MutationApplied -ceq $false
 })
 if($eligible.Count -lt 1){$blocking.Add('NO_AUTHORIZED_ACTIONABLE_RECIPE')}
 if($NativeReceipt.working_wim_created -cne $false -or
    $Transaction.working_wim_created -cne $false){
  $blocking.Add('WORKING_WIM_CREATION_STATE_NOT_CLEAR')
 }
 return [pscustomobject]@{
  contract='BlueLite.MAX_PRE.OwnedWimLifecycle.v0.1'
  source_run_id=$id
  source_build=$build
  source_wim_path=$src
  working_wim_path=$work
  source_wim_bytes=[long]$Plan.original_wim_bytes
  declared_source_sha256=[string]$Plan.original_wim_declared_sha256
  recipe_count=$recipes.Count
  actionable_recipe_count=$eligible.Count
  gate_blockers=@($blocking.ToArray())
  preparation_authorized=($blocking.Count -eq 0)
  working_wim_created=$false
  native_mount_performed=$false
  mutations_performed=0
  lifecycle_state=if($blocking.Count -gt 0){'BLOCKED_BEFORE_PREPARE'}else{'PREPARE_ELIGIBLE_REQUIRES_OPERATOR_CONFIRMATION'}
 }
}

function Invoke-BlueLiteOwnedWimPrepare {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Lifecycle,
  [Parameter(Mandatory)][string]$OwnerRoot,
  [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSourceSHA256,
  [switch]$ExplicitOperatorApproval
 )
 if($Lifecycle.contract -cne 'BlueLite.MAX_PRE.OwnedWimLifecycle.v0.1'){
  throw 'BL_PREPARE_UNRECOGNIZED_LIFECYCLE'
 }
 if($Lifecycle.preparation_authorized -cne $true -or
    $Lifecycle.actionable_recipe_count -lt 1 -or
    @($Lifecycle.gate_blockers).Count -ne 0){
  throw 'BL_PREPARE_BLOCKED_BY_EVIDENCE_AND_RECIPE_GATES'
 }
 if(-not $ExplicitOperatorApproval){throw 'BL_PREPARE_OPERATOR_APPROVAL_REQUIRED'}
 $root=[IO.Path]::GetFullPath($OwnerRoot).TrimEnd('\','/')
 $source=[IO.Path]::GetFullPath([string]$Lifecycle.source_wim_path)
 $target=[IO.Path]::GetFullPath([string]$Lifecycle.working_wim_path)
 if(-not $source.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
    -not $target.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase) -or
    [string]::Equals($source,$target,[StringComparison]::OrdinalIgnoreCase)){
  throw 'BL_PREPARE_OWNER_ROOT_OR_PATH_ALIAS'
 }
 $file=Get-Item -LiteralPath $source -Force -ErrorAction Stop
 if($file.PSIsContainer -or $file.Length -ne $Lifecycle.source_wim_bytes){
  throw 'BL_PREPARE_SOURCE_BYTES_OR_TYPE_DRIFT'
 }
 if(Test-Path -LiteralPath $target){throw 'BL_PREPARE_TARGET_ALREADY_EXISTS'}
 $parent=[IO.Path]::GetDirectoryName($target)
 if(-not(Test-Path -LiteralPath $parent -PathType Container)){
  throw 'BL_PREPARE_TARGET_DIRECTORY_MISSING'
 }
 foreach($p in @($file.FullName,$parent)){
  $cursor=Get-Item -LiteralPath $p -Force -ErrorAction Stop
  $rootFound=$false
  while($null -ne $cursor){
   if(($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw 'BL_PREPARE_REPARSE_ANCESTOR'
   }
   if($cursor.FullName.TrimEnd('\','/') -ieq $root){$rootFound=$true;break}
   $cursor=if($cursor -is [IO.FileInfo]){$cursor.Directory}else{$cursor.Parent}
  }
  if(-not $rootFound){throw 'BL_PREPARE_OWNERSHIP_CHAIN_UNPROVEN'}
 }
 $hash=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
 if($hash -cne $ExpectedSourceSHA256.ToUpperInvariant() -or
    $hash -cne [string]$Lifecycle.declared_source_sha256){
  throw 'BL_PREPARE_SOURCE_SHA_IDENTITY_DRIFT'
 }
 # This is the ONLY image-copy action in v0.1, intentionally unreachable
 # for current r12 and operator R1 native evidence.
 Copy-Item -LiteralPath $source -Destination $target -ErrorAction Stop
 $copyHash=(Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
 if($copyHash -cne $hash){
  throw 'BL_PREPARE_COPY_SHA_FAILED_PRESERVE_FOR_FORENSIC_AND_SAFE_CLEANUP'
 }
 return [pscustomobject]@{
  lifecycle_state='OWNED_IMAGE_PREPARED_NOT_MOUNTED'
  owner_root=$root
  source_wim_path=$source
  working_wim_path=$target
  source_sha256=$hash
  prepared_wim_sha256=$copyHash
  prepared_wim_bytes=[long](Get-Item -LiteralPath $target).Length
  native_mount_performed=$false
  mutation_performed=$false
 }
}

Export-ModuleMember -Function New-BlueLiteOwnedWimLifecycle,Invoke-BlueLiteOwnedWimPrepare
