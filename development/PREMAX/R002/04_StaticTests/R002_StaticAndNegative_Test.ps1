# R002 actual PS7 AST, read-only positive, synthetic negative fixtures. NO WIM/transport.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root='C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package'
$source=Join-Path $root '03_Drafts\R002_Stage1_SourceTransport_Control_DRAFT.ps1'
$plan=Join-Path $root '03_Drafts\R002_MAXPRE_OfflineDecisionPlan_DRAFT.ps1'
$profile=Join-Path $root '01_Inputs\R002_Stage1_Profile_9711.json'
$recipes=Join-Path $root '01_Inputs\R002_RecipeRegistry_Snapshot.json'
$image=Join-Path $root '04_StaticTests\R002_Synthetic_ImageContract.json'
$fx=Join-Path $root '04_StaticTests\Fixtures_001'
if(Test-Path -LiteralPath $fx){throw 'FIXTURE_FOLDER_MUST_NOT_PREEXIST'}
$null=[IO.Directory]::CreateDirectory($fx)
$badNames='(?i)^(Invoke-WebRequest|Invoke-RestMethod|Start-Process|dism|reg|aria2c|Remove-Item|Set-ItemProperty|New-ItemProperty|Mount-WindowsImage|Dismount-WindowsImage|Export-WindowsImage|Copy-Item|Move-Item)$'
foreach($f in @($source,$plan)){
 $tokens=$null;$errors=$null
 $ast=[Management.Automation.Language.Parser]::ParseFile($f,[ref]$tokens,[ref]$errors)
 if(@($errors).Count -gt 0){throw ('AST_FAIL='+[IO.Path]::GetFileName($f))}
 $cmd=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.CommandAst]},$true))
 $forbidden=@($cmd | Where-Object {$_.GetCommandName() -match $badNames})
 if($forbidden.Count -ne 0){throw ('DRAFT_UNAUTHORIZED_MUTATING_OR_NETWORK_AST='+$forbidden.Count)}
 Write-Output ('AST_PASS='+[IO.Path]::GetFileName($f)+';COMMANDS='+$cmd.Count)
}
$pass=@(& $source -Mode Plan -ProfilePath $profile -RecipeRegistryPath $recipes)
if(@($pass | Where-Object {$_ -match '^R002_SOURCE_TRANSPORT_STATIC=PASS;BUILD=26300.9711;WINDOWS=98;APPS=2798;NO_NETWORK=TRUE$'}).Count -ne 1){throw 'REAL_9711_SAVED_QUEUE_POSITIVE_FAILED'}
if(@($pass | Where-Object {$_ -eq 'R002_EXECUTION_AUTHORIZATION=FALSE'}).Count -ne 1){throw 'SOURCE_SCRIPT_RUNTIME_GUARD_MISSING'}
Write-Output 'NATIVE_POSITIVE_SOURCE=PASS_9711_98_2798'
$planOut=@(& $plan -ImageContractPath $image -RecipeSnapshotPath $recipes)
if(@($planOut | Where-Object {$_ -match '^R002_MAXPRE_PLAN_ONLY;RECIPE='}).Count -ne 7 -or
 @($planOut | Where-Object {$_ -eq 'R002_WIM_READ=FALSE;WIM_MUTATION=FALSE;NATIVE_POSTSTATE=NOT_RUN'}).Count -ne 1){throw 'PLAN_POSITIVE_NOT_DENY_ONLY'}
Write-Output 'SYNTHETIC_PLAN_POSITIVE=PASS_7_HOLDS'
function Negative([string]$Name,[string]$Body,[string]$Expected,[string]$Mode){
 $f=Join-Path $fx ($Name+'.json')
 [IO.File]::WriteAllText($f,$Body,[Text.UTF8Encoding]::new($false))
 try{
  if($Mode -eq 'Source'){ $out=@(& $source -ProfilePath $f -RecipeRegistryPath $recipes -ErrorAction Stop) }
  elseif($Mode -eq 'Image'){ $out=@(& $plan -ImageContractPath $f -RecipeSnapshotPath $recipes -ErrorAction Stop) }
  else{ $out=@(& $source -Mode Plan -ProfilePath $profile -RecipeRegistryPath $f -ErrorAction Stop) }
  throw ('NEGATIVE_UNEXPECTED_PASS='+$Name)
 }catch{
  $msg=$_.Exception.Message
  if($msg -like 'NEGATIVE_UNEXPECTED_PASS=*'){throw}
  if($msg -notmatch [regex]::Escape($Expected)){throw ('NEGATIVE_WRONG_ERROR='+$Name+':'+$msg)}
  Write-Output ('NEGATIVE_PASS='+$Name+';GATE='+$Expected)
 }
}
$original=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json
$baseImage=Get-Content -LiteralPath $image -Raw | ConvertFrom-Json
$registry=Get-Content -LiteralPath $recipes -Raw | ConvertFrom-Json
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.source.zip_sha256=('0'*64)
Negative 'wrong_zip_sha' ($o|ConvertTo-Json -Depth 20) 'ORIGINAL_ZIP_SHA_DRIFT' 'Source'
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.source.uuid='bad-id'
Negative 'wrong_uuid' ($o|ConvertTo-Json -Depth 20) 'UUID_BAD_FORMAT' 'Source'
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.staging.windows_queue='PRUNE_FOD'
Negative 'prune_windows' ($o|ConvertTo-Json -Depth 20) 'WINDOWS_INPUT_PRUNING_PROHIBITED' 'Source'
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.staging.winre='SKIP_INSTALLED_WINRE'
Negative 'drop_winre' ($o|ConvertTo-Json -Depth 20) 'WINRE_RECOVERY_CHANGE_REQUIRES_SEPARATE_APPROVAL' 'Source'
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.staging.required_apps=@($o.staging.required_apps | Where-Object {$_ -ne 'Microsoft.Windows.Photos'})
Negative 'missing_photos' ($o|ConvertTo-Json -Depth 20) 'STAGING_FIVE_CARDINALITY' 'Source'
$o=Get-Content -LiteralPath $profile -Raw | ConvertFrom-Json;$o.queue.original_apps_identity_sha256='0'*64
Negative 'wrong_apps_identity' ($o|ConvertTo-Json -Depth 20) 'FROZEN_APPS_IDENTITY_OR_COUNT' 'Source'
$o=Get-Content -LiteralPath $image -Raw | ConvertFrom-Json;$o.image_working=$o.image_original
Negative 'same_wim_alias' ($o|ConvertTo-Json -Depth 20) 'IMMUTABLE_AND_WORKING_WIM_COLLIDE' 'Image'
$o=Get-Content -LiteralPath $image -Raw | ConvertFrom-Json;$o.operator_authorized_mutation=$true
Negative 'pretend_approved' ($o|ConvertTo-Json -Depth 20) 'NO_RUNTIME_ALLOWED_IN_THIS_DRAFT' 'Image'
$o=Get-Content -LiteralPath $image -Raw | ConvertFrom-Json;$o.image_working='C:\Windows\system32\oops.wim'
Negative 'out_of_scope' ($o|ConvertTo-Json -Depth 20) 'WIM_PATH_OUTSIDE_OWNED_SCOPE' 'Image'
$o=Get-Content -LiteralPath $recipes -Raw | ConvertFrom-Json;$o.recipes[0].runtime_execution_allowed=$true
Negative 'registry_runtime_enabled' ($o|ConvertTo-Json -Depth 20) 'REGISTRY_RUNTIME_FLAG_NOT_FALSE' 'Registry'
Write-Output 'R002_NEGATIVE_TESTS=10_OF_10_PASS'
Write-Output 'R002_OVERALL=PASS_AST_NATIVE_9711_STATIC_PLAN_SYNTHETIC_NEGATIVE_ONLY'
