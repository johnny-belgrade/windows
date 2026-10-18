# BlueLite MAX_PRE | reusable offline-only runtime core | v0.1
# No implicit mutation, source copying, WIM mounting, or recipe authorization.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Assert-BlueLiteOwnedPath {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][string]$Path,
  [Parameter(Mandatory)][string]$OwnerRoot,
  [switch]$MustExist,
  [switch]$Directory
 )
 if(-not [IO.Path]::IsPathRooted($Path)){throw 'BL_PATH_NOT_ABSOLUTE'}
 if(-not [IO.Path]::IsPathRooted($OwnerRoot)){throw 'BL_OWNER_NOT_ABSOLUTE'}
 $root=[IO.Path]::GetFullPath($OwnerRoot).TrimEnd('\','/')
 $full=[IO.Path]::GetFullPath($Path).TrimEnd('\','/')
 if(-not $full.StartsWith($root+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){
  throw 'BL_PATH_OUTSIDE_OWNER_ROOT'
 }
 $base=Get-Item -LiteralPath $root -Force -ErrorAction Stop
 if(-not $base.PSIsContainer){throw 'BL_OWNER_NOT_DIRECTORY'}
 $cursor=if(Test-Path -LiteralPath $full){Get-Item -LiteralPath $full -Force -ErrorAction Stop}else{$base}
 while($null -ne $cursor){
  if(($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
   throw ('BL_REPARSE_PATH='+$cursor.FullName)
  }
  if($cursor.FullName.TrimEnd('\','/') -ieq $root){break}
  $cursor=$cursor.Parent
 }
 if($MustExist){
  $x=Get-Item -LiteralPath $full -Force -ErrorAction Stop
  if($Directory -and -not $x.PSIsContainer){throw 'BL_EXPECTED_DIRECTORY'}
  if(-not $Directory -and $x.PSIsContainer){throw 'BL_EXPECTED_FILE'}
 }
 return $full
}

function Assert-BlueLiteDistinctImages {
 [CmdletBinding()]
 param([Parameter(Mandatory)][string]$OriginalWim,
       [Parameter(Mandatory)][string]$WorkingWim)
 $a=[IO.Path]::GetFullPath($OriginalWim)
 $b=[IO.Path]::GetFullPath($WorkingWim)
 if($a.Equals($b,[StringComparison]::OrdinalIgnoreCase)){
  throw 'BL_ORIGINAL_AND_WORKING_ALIAS'
 }
 return $true
}

function Test-BlueLiteDismCommand {
 [CmdletBinding()]
 param([Parameter(Mandatory)][string[]]$Arguments)
 if($Arguments.Count -eq 0){throw 'BL_DISM_EMPTY_ARGUMENTS'}
 foreach($a in $Arguments){
  if([string]::IsNullOrWhiteSpace($a) -or
    $a -match '(?i)^/(online|image:|wimfile:|mount-image|unmount-image|apply-image|capture-image|delete-image|export-image|add-package|add-capability|enable-feature)' -or
    $a -match '[\r\n]'){
   throw 'BL_DISM_FORBIDDEN_OR_AMBIGUOUS_ARGUMENT'
  }
 }
 $first=$Arguments[0]
 $read=@('/Get-ProvisionedAppxPackages','/Get-Packages','/Get-Features',
   '/Get-Capabilities','/Get-PackageInfo','/Get-FeatureInfo','/Get-CapabilityInfo')
 $mutate=@('/Remove-Package','/Remove-Capability','/Disable-Feature',
   '/Remove-ProvisionedAppxPackage')
 $mutation=$false
 if($first -cin $read){
  # Exact verb, only documented selector /Format switches, no second verb.
  foreach($arg in @($Arguments|Select-Object -Skip 1)){
   if($arg -cnotmatch '^/(PackageName|CapabilityName|FeatureName|Format):[A-Za-z0-9_.~\-]+$'){
    throw 'BL_DISM_READ_SELECTOR_DENIED'
   }
  }
 }elseif($first -ceq '/Cleanup-Image'){
  if($Arguments.Count -ne 2 -or
    $Arguments[1] -cnotin @('/CheckHealth','/ScanHealth','/AnalyzeComponentStore')){
   throw 'BL_DISM_CLEANUP_VERB_DENIED'
  }
 }elseif($first -cin $mutate){
  $mutation=$true
  if($Arguments.Count -ne 2){throw 'BL_DISM_MUTATION_EXACT_SELECTOR_REQUIRED'}
  $name=if($first -ceq '/Remove-Capability'){'CapabilityName'}
        elseif($first -ceq '/Disable-Feature'){'FeatureName'}
        else{'PackageName'}
  if($Arguments[1] -cnotmatch ('^/'+$name+':[A-Za-z0-9_.~\-]+$')){
   throw 'BL_DISM_MUTATION_SELECTOR_DENIED'
  }
 }else{
  throw 'BL_DISM_UNLISTED_VERB'
 }
 return [pscustomobject]@{
  Command=$first
  IsMutation=$mutation
  ExplicitOfflineImageRequired=$true
 }
}

function Invoke-BlueLiteOfflineDism {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][string]$MountDir,
  [Parameter(Mandatory)][string]$OwnerRoot,
  [Parameter(Mandatory)][string[]]$Arguments,
  [switch]$OperatorAuthorizedMutation,
  [switch]$RecipeRuntimeAllowed
 )
 $contract=Test-BlueLiteDismCommand -Arguments $Arguments
 if($contract.IsMutation){
  if(-not $OperatorAuthorizedMutation -or -not $RecipeRuntimeAllowed){
   throw 'BL_MUTATION_NOT_AUTHORIZED_BY_OPERATOR_AND_RECIPE'
  }
  # The production dispatcher/transaction/evidence module is not yet certified.
  # A caller-provided switch alone cannot authorize removal.
  throw 'BL_MUTATION_TRANSACTION_ENGINE_NOT_YET_CERTIFIED'
 }
 $mount=Assert-BlueLiteOwnedPath -Path $MountDir -OwnerRoot $OwnerRoot -MustExist -Directory
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 if(-not(Test-Path -LiteralPath $dism -PathType Leaf)){throw 'BL_NATIVE_DISM_MISSING'}
 $nativeArgs=@('/English',('/Image:'+$mount))+@($Arguments)
 $output=@(& $dism @nativeArgs 2>&1 | ForEach-Object {[string]$_})
 $code=[int]$LASTEXITCODE
 $text=$output -join [Environment]::NewLine
 if($code -ne 0 -or
    $text -notmatch '(?i)The operation completed successfully\.' -or
    $text -match '(?i)DISM\.exe\s+\[dism_options\]'){
  throw ('BL_NATIVE_DISM_FAILED_OR_HELP;EXIT='+$code+';CMD='+$contract.Command)
 }
 return [pscustomobject]@{
  ExitCode=$code
  Command=$contract.Command
  MountDir=$mount
  Mutated=[bool]$contract.IsMutation
  Output=$text
 }
}

function Get-BlueLiteMaxPreRecipePlan {
 [CmdletBinding()]
 param(
  [Parameter(Mandatory)][object]$Registry,
  [Parameter(Mandatory)][ValidatePattern('^[0-9]{5}\.[0-9]+$')][string]$Build,
  [ValidateSet('STAGE1_MAX_PRE','STAGE2_OFFLINE')][string]$Phase='STAGE1_MAX_PRE'
 )
 if($null -eq $Registry -or $null -eq $Registry.recipes){
  throw 'BL_RECIPE_REGISTRY_NOT_RECOGNIZED'
 }
 $family=$Build.Split('.')[0]
 $list=[System.Collections.Generic.List[object]]::new()
 foreach($r in @($Registry.recipes)){
  if($r.phase -ne $Phase -and $r.phase -ne 'CROSS_STAGE'){continue}
  $matching=@($r.variants|Where-Object {
   $_.supported_lineage -contains ($family+'.x') -and
   $_.topology_status -in @('KNOWN_MATCHING','KNOWN_VARIANT','GREEN','AMBER')
  })
  $status='NO_CERTIFIED_BUILD_TOPOLOGY'
  if($r.disposition -eq 'RED_HOLD'){$status='RED_HOLD'}
  elseif($r.disposition -eq 'COMPONENT_ENGINE_HANDOFF'){$status='COMPONENT_ENGINE_HANDOFF'}
  elseif($matching.Count -gt 1){$status='MULTIPLE_VARIANTS_REVIEW_REQUIRED'}
  elseif($matching.Count -eq 1 -and $r.runtime_execution_allowed -eq $true){
   $status='RECIPE_RUNTIME_FLAG_TRUE_STILL_NEEDS_OPERATOR_AND_IMAGE_GATES'
  }
  elseif($matching.Count -eq 1){$status='RECIPE_RUNTIME_DISABLED'}
  $id=if($matching.Count -eq 1){[string]$matching[0].variant_id}else{''}
  $list.Add([pscustomobject]@{
   RecipeId=[string]$r.recipe_id
   Phase=$Phase
   Build=$Build
   VariantId=$id
   Decision=$status
   AutoExecute=$false
  })
 }
 return $list.ToArray()
}

Export-ModuleMember -Function Assert-BlueLiteOwnedPath,Assert-BlueLiteDistinctImages,Test-BlueLiteDismCommand,Invoke-BlueLiteOfflineDism,Get-BlueLiteMaxPreRecipePlan
