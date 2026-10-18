param(
 [Parameter(Mandatory)][ValidatePattern('^[0-9]{5}\.[0-9]+$')][string]$Build,
 [Parameter(Mandatory)][string]$CoreModulePath,
 [Parameter(Mandatory)][string]$RegistryPath,
 [Parameter(Mandatory)][string]$SourceContractPath,
 [Parameter(Mandatory)][string]$OriginalWimPath,
 [Parameter(Mandatory)][string]$WorkingWimPath,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedCoreSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedRegistrySHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$ExpectedSourceContractSHA256,
 [Parameter(Mandatory)][ValidatePattern('^[A-Fa-f0-9]{64}$')][string]$DeclaredOriginalWimSHA256,
 [long]$ExpectedOriginalWimBytes=0,
 [string]$LogRoot='C:\work\logs',
 [string]$OwnerRoot='C:\work'
)
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 if(-not(Test-Path -LiteralPath $LogRoot -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
 if(-not(Test-Path -LiteralPath $CoreModulePath -PathType Leaf)){throw 'BL_CORE_MISSING'}
 if(-not(Test-Path -LiteralPath $RegistryPath -PathType Leaf)){throw 'BL_REGISTRY_MISSING'}
 if(-not(Test-Path -LiteralPath $SourceContractPath -PathType Leaf)){throw 'BL_SOURCE_CONTRACT_MISSING'}
 if(-not(Test-Path -LiteralPath $OriginalWimPath -PathType Leaf)){throw 'BL_ORIGINAL_WIM_MISSING'}
 $tag=$Build -replace '[^0-9.]','_'
 $log=Join-Path $LogRoot ('BlueLite_MAXPRE_SourceBoundPlan_R1_'+$tag+'.txt')
 $planFile=Join-Path $LogRoot ('BlueLite_MAXPRE_SourceBoundPlan_R1_'+$tag+'.json')
 $receiptFile=Join-Path $LogRoot ('BlueLite_MAXPRE_SourceBoundReceipt_R1_'+$tag+'.json')
 foreach($f in @($log,$planFile,$receiptFile)){
  if(Test-Path -LiteralPath $f){throw ('BL_OUTPUT_EXISTS_NO_OVERWRITE='+$f)}
 }
 $utf8=[Text.UTF8Encoding]::new($false)
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$message){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$name,[string]$file,[string]$expected){
  $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256 -ErrorAction Stop).Hash
  if($hash -cne $expected.ToUpperInvariant()){
   throw ('BL_PIN_SHA_MISMATCH='+$name+';ACTUAL='+$hash)
  }
  Note ('SHA_PIN_'+$name+'=PASS;'+$hash)
 }
 $result='HOLD_MAXPRE_SOURCEBOUND_PLAN_ONLY'
 try {
  Note 'MAXPRE_PRODUCTION_SOURCEBOUND_PLAN_AND_RESULTRECEIPT'
  Note 'NO_WIM_HASHING_NO_CLONE_NO_MOUNT_NO_DISM_NO_MUTATION'
  Pin 'CORE' $CoreModulePath $ExpectedCoreSHA256
  Pin 'RECIPE_REGISTRY' $RegistryPath $ExpectedRegistrySHA256
  Pin 'SOURCE_CONTRACT' $SourceContractPath $ExpectedSourceContractSHA256
  $sourceContract=Get-Content -LiteralPath $SourceContractPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 80 -ErrorAction Stop
  if($null -eq $sourceContract){throw 'BL_SOURCE_CONTRACT_JSON_EMPTY'}
  $registry=Get-Content -LiteralPath $RegistryPath -Raw -ErrorAction Stop | ConvertFrom-Json -Depth 100 -ErrorAction Stop
  if($registry.schema_version -cne '1.0.0' -or
    [string]::IsNullOrWhiteSpace([string]$registry.registry_revision) -or
    @($registry.recipes).Count -lt 1){
   throw 'BL_REGISTRY_CONTRACT_NOT_RECOGNIZED'
  }
  if(@($registry.recipes|Where-Object { $_.runtime_execution_allowed -eq $true }).Count -ne 0){
   throw 'BL_UNEXPECTED_RUNTIME_ENABLED_RECIPE'
  }
  Import-Module -Name $CoreModulePath -Force -ErrorAction Stop
  $owner=[IO.Path]::GetFullPath($OwnerRoot).TrimEnd('\')
  $null=Assert-BlueLiteOwnedPath -Path $OriginalWimPath -OwnerRoot $owner -MustExist
  $null=Assert-BlueLiteOwnedPath -Path $SourceContractPath -OwnerRoot $owner -MustExist
  $null=Assert-BlueLiteOwnedPath -Path $LogRoot -OwnerRoot $owner -MustExist -Directory
  $null=Assert-BlueLiteDistinctImages -OriginalWim $OriginalWimPath -WorkingWim $WorkingWimPath
  $null=Assert-BlueLiteOwnedPath -Path $WorkingWimPath -OwnerRoot $owner
  Note 'PATH_ANCESTRY_FILEINFO_DIRECTORYINFO_WORKING_DECLARATION=PASS'
  $orig=Get-Item -LiteralPath $OriginalWimPath -Force -ErrorAction Stop
  if($ExpectedOriginalWimBytes -gt 0 -and $orig.Length -ne $ExpectedOriginalWimBytes){
   throw ('BL_SOURCE_WIM_BYTES_DRIFT='+$orig.Length)
  }
  Note ('SOURCE_WIM_METADATA=PASS;BYTES='+$orig.Length+';SHA_NOT_REHASHED')
  $recipes=@(Get-BlueLiteMaxPreRecipePlan -Registry $registry -Build $Build -Phase STAGE1_MAX_PRE)
  if($recipes.Count -lt 1 -or @($recipes|Where-Object { $_.AutoExecute -eq $true }).Count -gt 0){
   throw 'BL_PLAN_EMPTY_OR_AUTOEXEC_ENABLED'
  }
  foreach($decision in $recipes){
   Note ('RECIPE='+$decision.RecipeId+';VARIANT='+$decision.VariantId+
    ';DECISION='+$decision.Decision+';AUTOEXEC='+$decision.AutoExecute)
  }
  $scriptHash=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256 -ErrorAction Stop).Hash
  $run='BL-'+$tag+'-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
  $plan=[ordered]@{
   plan_version='1.0.0'
   run_id=$run
   mode='MAX_PRE'
   source_build=$Build
   source_contract_path=$SourceContractPath
   source_contract_sha256=$ExpectedSourceContractSHA256.ToUpperInvariant()
   original_wim_path=$OriginalWimPath
   original_wim_bytes=[long]$orig.Length
   original_wim_declared_sha256=$DeclaredOriginalWimSHA256.ToUpperInvariant()
   original_wim_sha256_verified_this_run=$false
   planned_working_wim_path=$WorkingWimPath
   original_working_distinct=$true
   registry_revision=[string]$registry.registry_revision
   registry_sha256=$ExpectedRegistrySHA256.ToUpperInvariant()
   core_sha256=$ExpectedCoreSHA256.ToUpperInvariant()
   controller_sha256=$scriptHash
   recipe_count=$recipes.Count
   recipes=@($recipes)
   execution_authorized=$false
   mutations_executed=0
   certification='SOURCEBOUND_PLANNING_ONLY'
  }
  $receipt=[ordered]@{
   contract_version='1.0.0'
   run_id=$run
   checkpoint_utc=[DateTime]::UtcNow.ToString('o')
   phase='MAX_PRE'
   source_build=$Build
   source_contract_sha256=$ExpectedSourceContractSHA256.ToUpperInvariant()
   script_path=$PSCommandPath
   script_sha256=$scriptHash
   operator_executed=$true
   result='STATIC_VERIFIED'
   evidence_tier='STATIC'
   mutation_performed=$false
   raw_evidence_paths=@($log)
   health='NOT_RUN'
   pending_count=$null
   protected_floor='NOT_RUN'
   recipe_results=@($recipes)
   independent_post_state_verified=$false
   next_action_authorized=$false
   next_action='Build and verify transaction dispatcher before any MAX_PRE removal'
   limitations=@(
    'SourceContract hash verified; source WIM SHA declared from retained operator evidence, not rehashed',
    'No mounted-image native DISM, CBS or AppX inspection in this plan-only step',
    'Recipe runtime flags all disabled; no mutation or release authorization'
   )
  }
  [IO.File]::WriteAllText($planFile,($plan|ConvertTo-Json -Depth 35),$utf8)
  [IO.File]::WriteAllText($receiptFile,($receipt|ConvertTo-Json -Depth 35),$utf8)
  $p=Get-Content -LiteralPath $planFile -Raw | ConvertFrom-Json -Depth 80
  $rr=Get-Content -LiteralPath $receiptFile -Raw | ConvertFrom-Json -Depth 80
  if($p.recipe_count -ne $recipes.Count -or $p.execution_authorized -ne $false -or
   $rr.result -cne 'STATIC_VERIFIED' -or $rr.mutation_performed -ne $false){
   throw 'BL_SERIALIZED_PLAN_OR_RECEIPT_INVALID'
  }
  Note ('PRODUCTION_PLAN=PASS;RECIPES='+$recipes.Count+';AUTOEXEC=0')
  Note ('PLAN_JSON='+$planFile)
  Note ('RECEIPT_JSON='+$receiptFile)
  $result='PASS_MAXPRE_SOURCEBOUND_PRODUCTION_PLAN_STATIC_NO_IMAGE_TOUCH'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'WIM_HASH_THIS_RUN=NOT_RUN;DISM=NOT_RUN;MOUNT=NOT_RUN;MUTATION=NOT_RUN'
  Write-Host ('REPORT='+$log)
 }
 if($result -ne 'PASS_MAXPRE_SOURCEBOUND_PRODUCTION_PLAN_STATIC_NO_IMAGE_TOUCH'){
  throw 'BL_MAXPRE_SOURCEBOUND_PLAN_FAILED'
 }
}