# BlueLite v1.0: universal 26300.x MAX_PRE recipe controller v0.1
# Compiles an operator-verified R16 planner result against Component Intelligence.
# It deliberately cannot mount or alter Windows images.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$PlannerTxt,
 [Parameter(Mandatory)][string]$PlannerTxtSha256,
 [Parameter(Mandatory)][string]$PlannerJson,
 [Parameter(Mandatory)][string]$PlannerJsonSha256,
 [Parameter(Mandatory)][string]$RegistryPath,
 [Parameter(Mandatory)][string]$RegistrySha256,
 [Parameter(Mandatory)][string]$ReportPath,
 [Parameter(Mandatory)][string]$OutputJson
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R17_PS7_REQUIRED'}
function Verify([string]$path,[string]$sha,[string]$tag){
 if(-not [IO.File]::Exists($path)){throw ('BL_R17_FILE_MISSING_'+$tag)}
 if($sha -notmatch '^[0-9A-Fa-f]{64}$'){throw ('BL_R17_SHA_FORMAT_'+$tag)}
 if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha.ToUpperInvariant()){
  throw ('BL_R17_SHA_MISMATCH_'+$tag)
 }
}
function Require([bool]$ok,[string]$reason){if(-not $ok){throw ('BL_R17_'+$reason)}}
function Compile($p,$r){
 Require ($p.Schema -ceq 'BlueLite.MAXPRE.ImpactPlan.v0.1') 'SCHEMA_MISMATCH'
 Require ($p.Lineage -ceq '26300.x') 'LINEAGE_MISMATCH'
 Require ($p.ImageSha256 -match '^[0-9A-Fa-f]{64}$' -and $p.ImageIndex -eq 1) 'IMAGE_IDENTITY_INVALID'
 Require ($p.MutationAllowed -eq $false -and $p.ReleaseCertified -eq $false) 'PLANNER_NOT_READONLY'
 Require (@($p.Candidates).Count -ge 7) 'CANDIDATES_INCOMPLETE'
 foreach($k in @('Microsoft.SecHealthUI','Microsoft.Windows.Photos','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad')){
  Require ($k -in @($p.ProvisionedAppx)) ('PROTECTED_APPX_MISSING_'+$k)
 }
 Require ($p.TargetObservation.Sense -ceq 'INSTALLED') 'PROTECTED_SENSE_MISSING'
 $names=@('BL.FOD.EdgeWebView2','BL.CBS.OneDrive.NeutralSequence','BL.APPX.DesktopAppInstaller.ExactLifecycle','BL.CBS.Sense','BL.CBS.FoDMetadata.Superseded')
 $map=@{}
 foreach($id in $names){
  $hits=@($r.recipes|Where-Object {$_.recipe_id -ceq $id})
  Require ($hits.Count -eq 1) ('REGISTRY_RECIPE_NOT_UNIQUE_'+$id)
  $map[$id]=$hits[0]
  Require ($hits[0].runtime_execution_allowed -eq $false) ('REGISTRY_RUNTIME_DRIFT_'+$id)
 }
 Require ($map['BL.CBS.Sense'].removal_class -ceq 'RED') 'SENSE_REMOVAL_CLASS_DRIFT'
 $rows=[Collections.Generic.List[object]]::new()
 function Add([string]$name,[int]$rank,[string]$state,[string]$decision,[string]$regid,[Nullable[long]]$historic){
  $rid=$(if($regid){$regid}else{'BUILTIN_NATIVE_GREEN'})
  $variantCount=$(if($regid){@($map[$regid].variants).Count}else{0})
  [void]$rows.Add([pscustomobject][ordered]@{
   Target=$name;Priority=$rank;Observed=$state;Decision=$decision
   RecipeId=$rid;KnownRegistryVariants=$variantCount
   MeasuredReferenceWimBytes=$historic;CanMutate=$false
  })
 }
 $w=[string]$p.TargetObservation.WebView
 $dw=$(if($w -ceq 'NOT_PRESENT'){'ALREADY_ABSENT'}elseif($w -ceq 'INSTALLED'){'OWNER_AND_NATIVE_GATE_REQUIRED'}else{'UNKNOWN_DEPENDENCY'})
 Add 'WebView.FoD' 1 $w $dw 'BL.FOD.EdgeWebView2' ([long]603556113)
 $ones=@($p.OneDriveSetupMumNames).Count
 Add 'OneDrive.Setup' 2 ('MUM_COUNT_'+$ones) $(if($ones -gt 0){'NATIVE_PACKAGE_OWNER_GATE_REQUIRED'}else{'MUM_ABSENT_NOT_NATIVE_PROOF'}) 'BL.CBS.OneDrive.NeutralSequence' $null
 $app=$(if('Microsoft.DesktopAppInstaller' -in @($p.ProvisionedAppx)){'PROVISIONED'}else{'NOT_PROVISIONED'})
 Add 'DesktopAppInstaller' 3 $app $(if($app -eq 'PROVISIONED'){'APPX_OWNER_GATE_REQUIRED'}else{'ALREADY_NOT_PROVISIONED'}) 'BL.APPX.DesktopAppInstaller.ExactLifecycle' $null
 foreach($n in @('DirectX','LA57')){
  $state=[string]$p.TargetObservation.$n
  $decision=$(if($state -ceq 'NOT_PRESENT'){'ALREADY_ABSENT'}elseif($state -ceq 'INSTALLED'){'NATIVE_GREEN_GATE_REQUIRED'}else{'UNKNOWN_DEPENDENCY'})
  Add $n $(if($n -eq 'DirectX'){4}else{5}) $state $decision '' $null
 }
 Add 'FoDMetadata.Superseded' 90 'NOT_IN_R16' 'DEFER_PROVEN_SMALL_RECIPE' 'BL.CBS.FoDMetadata.Superseded' $null
 Add 'Defender.Sense' 99 'INSTALLED' 'KEEP_PROTECTED' 'BL.CBS.Sense' $null
 return [pscustomobject][ordered]@{
  Schema='BlueLite.MAXPRE.RecipeControl.v0.1';Lineage=$p.Lineage
  SourceImage=$p.Source;SourceImageSha256=$p.ImageSha256
  RegistryRevision=$r.registry_revision;DecisionRows=@($rows.ToArray())
  SkipCount=@($rows.ToArray()|Where-Object {$_.Decision -in @('ALREADY_ABSENT','ALREADY_NOT_PROVISIONED')}).Count
  MutationsApplied=0;MutationAllowed=$false;ReleaseCertified=$false
 }
}
$rp=[IO.Path]::GetFullPath($ReportPath)
$jp=[IO.Path]::GetFullPath($OutputJson)
Require ($rp -ne $jp) 'OUTPUT_COLLISION'
foreach($output in @($rp,$jp)){
 Require (-not [IO.File]::Exists($output)) 'OUTPUT_ALREADY_EXISTS'
 Require ([IO.Directory]::Exists([IO.Path]::GetDirectoryName($output))) 'OUTPUT_DIRECTORY_MISSING'
}
Verify $PlannerTxt $PlannerTxtSha256 'R16_TXT'
Verify $PlannerJson $PlannerJsonSha256 'R16_JSON'
Verify $RegistryPath $RegistrySha256 'REGISTRY'
$log=[IO.File]::ReadAllText($PlannerTxt)
Require ($log -match '(?m)^RESULT=PASS_UNIVERSAL_MAXPRE_IMPACT_PLANNER_READONLY_ONLY\s*$') 'R16_NOT_PASS'
Require ($log -match '(?m)^ZERO_MOUNTS_POST=PASS\s*$') 'R16_MOUNTS_NOT_ZERO'
Require ($log -match '(?m)^WIM_POST_PIN=PASS;') 'R16_WIM_NOT_PINNED'
$p=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($PlannerJson)) -Depth 40
$r=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($RegistryPath)) -Depth 40
$plan=Compile $p $r
Require ($plan.SkipCount -eq 4) 'R16_FOUR_FASTPATH_SKIPS_EXPECTED'
$tested=[Collections.Generic.List[string]]::new()
[void]$tested.Add('ACTUAL_R16_FOUR_SKIPS')
Require (@($plan.DecisionRows|Where-Object {$_.Target -eq 'OneDrive.Setup' -and $_.Decision -eq 'MUM_ABSENT_NOT_NATIVE_PROOF'}).Count -eq 1) 'ONEDRIVE_NEGATIVE'
[void]$tested.Add('ONEDRIVE_NOT_INFERRED_FROM_MUM')
$synthetic=ConvertFrom-Json -InputObject ($p|ConvertTo-Json -Depth 40) -Depth 40
$synthetic.TargetObservation.WebView='INSTALLED'
$synthetic.TargetObservation.DirectX='INSTALLED'
$synthetic.TargetObservation.LA57='INSTALLED'
$branch=Compile $synthetic $r
Require (@($branch.DecisionRows|Where-Object {$_.Target -eq 'WebView.FoD' -and $_.Decision -eq 'OWNER_AND_NATIVE_GATE_REQUIRED'}).Count -eq 1) 'WEBVIEW_INSTALLED_GATE'
[void]$tested.Add('SYNTHETIC_INSTALLED_WEBVIEW_HELD')
Require (@($branch.DecisionRows|Where-Object {$_.Decision -eq 'NATIVE_GREEN_GATE_REQUIRED'}).Count -eq 2) 'NATIVE_GREEN_GATE'
[void]$tested.Add('SYNTHETIC_NATIVE_GREEN_REQUIRES_GATE')
$synthetic.TargetObservation.Sense='NOT_PRESENT'
$denied=$false
try{$null=Compile $synthetic $r}catch{if($_.Exception.Message -eq 'BL_R17_PROTECTED_SENSE_MISSING'){$denied=$true}}
Require $denied 'SENSE_NEGATIVE_FIXTURE'
[void]$tested.Add('SYNTHETIC_SENSE_FLOOR_NEGATIVE')
$synthetic.TargetObservation.Sense='INSTALLED'
$synthetic.Lineage='26200.x'
$denied=$false
try{$null=Compile $synthetic $r}catch{if($_.Exception.Message -eq 'BL_R17_LINEAGE_MISMATCH'){$denied=$true}}
Require $denied 'LINEAGE_NEGATIVE_FIXTURE'
[void]$tested.Add('SYNTHETIC_LINEAGE_NEGATIVE')
$synthetic.Lineage='26300.x'
$synthetic.ProvisionedAppx=@($synthetic.ProvisionedAppx|Where-Object {$_ -ne 'Microsoft.SecHealthUI'})
$denied=$false
try{$null=Compile $synthetic $r}catch{if($_.Exception.Message -eq 'BL_R17_PROTECTED_APPX_MISSING_Microsoft.SecHealthUI'){$denied=$true}}
Require $denied 'APPX_NEGATIVE_FIXTURE'
[void]$tested.Add('SYNTHETIC_APPX_FLOOR_NEGATIVE')
Require (@($plan.DecisionRows|Where-Object {$_.CanMutate -ne $false}).Count -eq 0) 'UNAUTHORIZED_MUTATION'
[void]$tested.Add('RUNTIME_MUTATION_DENIED')
$plan|Add-Member -NotePropertyName FixtureTests -NotePropertyValue @($tested.ToArray())
$lines=[Collections.Generic.List[string]]::new()
[void]$lines.Add('BLUELITE_R17_UNIVERSAL_MAXPRE_RECIPE_CONTROLLER_V01')
[void]$lines.Add('R16_TXT_SHA256='+$PlannerTxtSha256.ToUpperInvariant())
[void]$lines.Add('R16_JSON_SHA256='+$PlannerJsonSha256.ToUpperInvariant())
[void]$lines.Add('REGISTRY_SHA256='+$RegistrySha256.ToUpperInvariant())
[void]$lines.Add('REGISTRY_REVISION='+$r.registry_revision)
foreach($row in $plan.DecisionRows){[void]$lines.Add('TARGET='+$row.Target+';OBSERVED='+$row.Observed+';DECISION='+$row.Decision)}
[void]$lines.Add('FIXTURES_PASS='+$tested.Count+';NAMES='+($tested -join ','))
[void]$lines.Add('WIM_NOT_OPENED=TRUE;NO_CLONE=TRUE;NO_MUTATION=TRUE')
[void]$lines.Add('RESULT=PASS_R17_UNIVERSAL_RECIPE_CONTROLLER_FASTPATH_ONLY')
[void]$lines.Add('NEXT=GUARDED_NATIVE_COMPONENT_BATCH_ENGINE')
$enc=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($jp,($plan|ConvertTo-Json -Depth 40)+[Environment]::NewLine,$enc)
[IO.File]::WriteAllText($rp,($lines -join [Environment]::NewLine)+[Environment]::NewLine,$enc)
foreach($line in $lines){Write-Host $line}
