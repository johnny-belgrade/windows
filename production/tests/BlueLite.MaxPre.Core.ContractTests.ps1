param(
 [Parameter(Mandatory)][string]$ModulePath,
 [string]$Report='C:\work\logs\BlueLite_MAXPRE_Core_ContractTests.txt'
)
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_LOGS_DIR_MISSING'}
 if(Test-Path -LiteralPath $Report){throw 'BL_TEST_REPORT_EXISTS_NO_OVERWRITE'}
 [IO.File]::WriteAllText($Report,'',[Text.UTF8Encoding]::new($false))
 function Note([string]$value){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$value
  Write-Host $line
  [IO.File]::AppendAllText($Report,$line+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
 }
 function MustFail([string]$name,[scriptblock]$action,[string]$message){
  $caught=''
  try{$null=& $action}catch{$caught=$_.Exception.Message}
  if(-not $caught.Contains($message)){throw ('NEGATIVE_TEST_FAILED='+$name+';ACTUAL='+$caught)}
  Note ('PASS_NEGATIVE='+$name+';REASON='+$message)
 }
 $result='HOLD_MAXPRE_CORE_CONTRACT_TESTS'
 try{
  Note 'MAXPRE_PRODUCTION_CORE_STATIC_AND_NEGATIVE_TESTS'
  Note 'NO_WIM_READ_WRITE_NO_DISM_CALL_NO_MOUNT_NO_DISPOSABLE'
  Import-Module -Name $ModulePath -Force -ErrorAction Stop
  $exports=@(Get-Command -Module 'BlueLite.MaxPre.Core' -ErrorAction Stop)
  if($exports.Count -ne 5){throw ('EXPORTED_FUNCTION_COUNT='+$exports.Count)}
  Note 'IMPORT=PASS;PUBLIC_FUNCTIONS=5'
  $read=Test-BlueLiteDismCommand -Arguments @('/Get-Packages','/Format:Table')
  if($read.IsMutation -or -not $read.ExplicitOfflineImageRequired){throw 'READONLY_DISM_DISPATCH_CONTRACT_FAIL'}
  Note 'NATIVE_DISM_READONLY_VERB_CONTRACT=PASS'
  $remove=Test-BlueLiteDismCommand -Arguments @('/Remove-Package','/PackageName:Microsoft-Windows-Example~31bf3856ad364e35~amd64~~10.0.26300.1')
  if(-not $remove.IsMutation){throw 'MUTATION_VERB_NOT_CLASSIFIED'}
  Note 'NATIVE_DISM_MUTATION_CLASSIFICATION=PASS'
  MustFail 'ONLINE_FORBIDDEN' {Test-BlueLiteDismCommand -Arguments @('/Online','/Get-Packages')} 'BL_DISM_FORBIDDEN_OR_AMBIGUOUS_ARGUMENT'
  MustFail 'MOUNT_VERB_DENIED' {Test-BlueLiteDismCommand -Arguments @('/Mount-Image')} 'BL_DISM_FORBIDDEN_OR_AMBIGUOUS_ARGUMENT'
  MustFail 'UNKNOWN_SWITCH_DENIED' {Test-BlueLiteDismCommand -Arguments @('/Get-Packages','/Apply-Unattend')} 'BL_DISM_READ_SELECTOR_DENIED'
  MustFail 'WIM_ALIAS_DENIED' {Assert-BlueLiteDistinctImages -OriginalWim 'C:\work\source.wim' -WorkingWim 'C:\work\source.wim'} 'BL_ORIGINAL_AND_WORKING_ALIAS'
  $diff=Assert-BlueLiteDistinctImages -OriginalWim 'C:\work\source.wim' -WorkingWim 'C:\work\owned.wim'
  if(-not $diff){throw 'DISTINCT_IMAGE_CHECK_FAIL'}
  Note 'IMMUTABLE_SOURCE_AND_OWNED_WORKING_PATH_GATE=PASS'
  $fixture=[pscustomobject]@{
   recipes=@(
    [pscustomobject]@{
     recipe_id='BL.TEST.Appx'
     phase='STAGE1_MAX_PRE'
     disposition='PRODUCTION_RULE'
     runtime_execution_allowed=$false
     variants=@([pscustomobject]@{
      variant_id='26300-fixture'
      supported_lineage=@('26300.x')
      topology_status='KNOWN_MATCHING'
     })
    },
    [pscustomobject]@{
     recipe_id='BL.TEST.Historical'
     phase='STAGE1_MAX_PRE'
     disposition='PRODUCTION_RULE'
     runtime_execution_allowed=$false
     variants=@([pscustomobject]@{
      variant_id='26200-only'
      supported_lineage=@('26200.x')
      topology_status='KNOWN_MATCHING'
     })
    },
    [pscustomobject]@{
     recipe_id='BL.TEST.Red'
     phase='STAGE1_MAX_PRE'
     disposition='RED_HOLD'
     runtime_execution_allowed=$false
     variants=@()
    }
   )
  }
  $plan=@(Get-BlueLiteMaxPreRecipePlan -Registry $fixture -Build '26300.9711')
  if($plan.Count -ne 3){throw ('RECIPE_COUNT_DRIFT='+$plan.Count)}
  $map=@{}
  foreach($x in $plan){$map[$x.RecipeId]=$x}
  if($map['BL.TEST.Appx'].Decision -cne 'RECIPE_RUNTIME_DISABLED' -or
    $map['BL.TEST.Historical'].Decision -cne 'NO_CERTIFIED_BUILD_TOPOLOGY' -or
    $map['BL.TEST.Red'].Decision -cne 'RED_HOLD' -or
    @($plan|Where-Object AutoExecute).Count -ne 0){
   throw 'RECIPE_PLAN_AUTHORIZATION_FAILURE'
  }
  Note 'GERMANIUM_26300_RECIPE_AND_RUNTIME_GATES=PASS;AUTOEXEC=0'
  MustFail 'UNAUTHORIZED_MUTATION_DENIED' {
   Invoke-BlueLiteOfflineDism -MountDir 'C:\work\NOT_A_MOUNT' -OwnerRoot 'C:\work' -Arguments @('/Remove-Package','/PackageName:example')
  } 'BL_MUTATION_NOT_AUTHORIZED_BY_OPERATOR_AND_RECIPE'
  MustFail 'FORCED_MUTATION_FLAGS_DENIED' {
   Invoke-BlueLiteOfflineDism -MountDir 'C:\work\NOT_A_MOUNT' -OwnerRoot 'C:\work' -Arguments @('/Remove-Package','/PackageName:example') -OperatorAuthorizedMutation -RecipeRuntimeAllowed
  } 'BL_MUTATION_TRANSACTION_ENGINE_NOT_YET_CERTIFIED'
  Note 'UNAUTHORIZED_AND_FORCED_MUTATION=BLOCKED'
  $result='PASS_MAXPRE_CORE_STATIC_AND_NEGATIVE_TESTS_NO_IMAGE_TOUCH'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'NO_SOURCE_WIM_CLONE_MOUNT_MUTATION_OR_DISPOSABLE_CREATION'
  Write-Host ('REPORT='+$Report)
 }
 if($result -ne 'PASS_MAXPRE_CORE_STATIC_AND_NEGATIVE_TESTS_NO_IMAGE_TOUCH'){
  throw 'MAXPRE_CORE_CONTRACT_TESTS_FAILED'
 }
}