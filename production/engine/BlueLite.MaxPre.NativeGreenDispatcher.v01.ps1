# BlueLite MAX_PRE universal GREEN native dispatcher v0.1
# Previews source-bound R17 results without mounting. ExperimentalApply is only for a NEW, owned, hash-pinned disposable.
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ControlJson,
 [Parameter(Mandatory)][string]$ControlJsonSha256,
 [Parameter(Mandatory)][string]$SourceWim,
 [Parameter(Mandatory)][string]$SourceWimSha256,
 [Parameter(Mandatory)][long]$SourceWimBytes,
 [Parameter(Mandatory)][string]$ReportPath,
 [ValidateSet('Preview','ExperimentalApply')][string]$Mode='Preview',
 [string]$OwnedDisposableDirectory='',
 [string]$OwnedMountDirectory=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R18_PS7_REQUIRED'}
$admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R18_ADMIN_REQUIRED'}
$dism=Join-Path $env:WINDIR 'System32\dism.exe'
$src=[IO.Path]::GetFullPath($SourceWim)
$ctl=[IO.Path]::GetFullPath($ControlJson)
$report=[IO.Path]::GetFullPath($ReportPath)
if(-not [IO.File]::Exists($dism)){throw 'BL_R18_DISM_MISSING'}
if($src -notmatch '^[A-Za-z]:\\'){throw 'BL_R18_ONLY_LOCAL_SOURCE_WIM'}
if($SourceWimSha256 -notmatch '^[0-9A-Fa-f]{64}$'){throw 'BL_R18_SOURCE_SHA_FORMAT'}
if($ControlJsonSha256 -notmatch '^[0-9A-Fa-f]{64}$'){throw 'BL_R18_CONTROL_SHA_FORMAT'}
foreach($pair in @(@($src,$SourceWimSha256),@($ctl,$ControlJsonSha256))){
 if(-not [IO.File]::Exists($pair[0])){throw ('BL_R18_INPUT_MISSING='+$pair[0])}
 if((Get-FileHash -LiteralPath $pair[0] -Algorithm SHA256).Hash -cne $pair[1].ToUpperInvariant()){
  throw ('BL_R18_INPUT_HASH_MISMATCH='+$pair[0])
 }
}
if((Get-Item -LiteralPath $src).Length -ne $SourceWimBytes){throw 'BL_R18_IMAGE_BYTECOUNT_DRIFT'}
if([IO.File]::Exists($report)){throw 'BL_R18_REPORT_NO_OVERWRITE'}
if(-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($report))){throw 'BL_R18_REPORT_PARENT_MISSING'}
if($report -eq $src -or $report -eq $ctl){throw 'BL_R18_FILE_COLLISION'}
$plan=ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($ctl)) -Depth 40
if($plan.Schema -cne 'BlueLite.MAXPRE.RecipeControl.v0.1' -or $plan.Lineage -cne '26300.x'){
 throw 'BL_R18_PLAN_SCHEMA_LINEAGE'
}
if($plan.MutationAllowed -ne $false -or $plan.ReleaseCertified -ne $false -or $plan.MutationsApplied -ne 0){
 throw 'BL_R18_CONTROL_NOT_READONLY'
}
if($plan.SourceImageSha256 -cne $SourceWimSha256.ToUpperInvariant() -or
   [IO.Path]::GetFullPath([string]$plan.SourceImage) -ine $src){
 throw 'BL_R18_CONTROL_SOURCE_BINDING_MISMATCH'
}
if(@($plan.FixtureTests).Count -ne 8 -or @($plan.DecisionRows).Count -ne 7){
 throw 'BL_R18_CONTROL_FIXTURES_OR_TARGETS_INCOMPLETE'
}
foreach($row in @($plan.DecisionRows)){
 if($row.CanMutate -ne $false){throw 'BL_R18_UNAUTHORIZED_PLAN_MUTATION'}
}
$targets=@(
 [pscustomobject]@{Name='DirectX';Capability='DirectX.Configuration.Database~~~~0.0.1.0'},
 [pscustomobject]@{Name='LA57';Capability='Windows.Kernel.LA57~~~~0.0.1.0'}
)
$queue=[Collections.Generic.List[object]]::new()
foreach($t in $targets){
 $rows=@($plan.DecisionRows|Where-Object {$_.Target -ceq $t.Name})
 if($rows.Count -ne 1){throw ('BL_R18_MISSING_PLAN_TARGET_'+$t.Name)}
 $r=$rows[0]
 if($r.Decision -ceq 'NATIVE_GREEN_GATE_REQUIRED' -and $r.Observed -ceq 'INSTALLED'){
  [void]$queue.Add($t)
 }elseif($r.Decision -cne 'ALREADY_ABSENT' -or $r.Observed -cne 'NOT_PRESENT'){
  throw ('BL_R18_UNSUPPORTED_GREEN_DECISION_'+$t.Name)
 }
}
$web=@($plan.DecisionRows|Where-Object {$_.Target -ceq 'WebView.FoD'})
if($web.Count -ne 1){throw 'BL_R18_WEBVIEW_ROW_MISSING'}
$webNeedsOwnerGate=$false
if($web[0].Observed -ceq 'INSTALLED' -and $web[0].Decision -ceq 'OWNER_AND_NATIVE_GATE_REQUIRED'){
 $webNeedsOwnerGate=$true
}elseif($web[0].Observed -cne 'NOT_PRESENT' -or $web[0].Decision -cne 'ALREADY_ABSENT'){
 throw 'BL_R18_WEBVIEW_UNEXPECTED_STATE'
}
$sense=@($plan.DecisionRows|Where-Object {$_.Target -ceq 'Defender.Sense'})
if($sense.Count -ne 1 -or $sense[0].Observed -cne 'INSTALLED' -or $sense[0].Decision -cne 'KEEP_PROTECTED'){
 throw 'BL_R18_PROTECTED_SENSE_FLOOR'
}
$utf8=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($report,'',$utf8)
function Note([string]$v) {
 Write-Host $v
 [IO.File]::AppendAllText($report,$v+[Environment]::NewLine,$utf8)
}
function Native([string]$label,[string[]]$arguments){
 $rows=@(& $dism @arguments 2>&1|ForEach-Object {[string]$_})
 $rc=[int]$LASTEXITCODE
 $body=$rows -join [Environment]::NewLine
 Note ('NATIVE_'+$label+'_EXIT='+$rc)
 if($rc -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.'){
  throw ('BL_R18_DISM_'+$label+'_ERROR_'+$rc)
 }
 return $body
}
function ZeroMounts([string]$stage) {
 $body=Native ('MOUNT_TABLE_'+$stage) @('/English','/Get-MountedWimInfo')
 if($body -notmatch '(?im)^\s*No mounted images found\.\s*$' -or $body -match '(?im)^\s*Mount Dir\s*:'){
  throw ('BL_R18_MOUNT_TABLE_NOT_ZERO_'+$stage)
 }
 Note ('ZERO_MOUNTS_'+$stage+'=PASS')
}
function ProtectedApps([string]$mount,[string]$stage){
 $body=Native ('APPX_'+$stage) @('/English',('/Image:'+$mount),'/Get-ProvisionedAppxPackages')
 foreach($required in @('Microsoft.SecHealthUI','Microsoft.Windows.Photos','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad')){
  if($body -notmatch ('(?im)^\s*DisplayName\s*:\s*'+[regex]::Escape($required)+'\s*$')){
   throw ('BL_R18_PROTECTED_APPX_MISSING_'+$stage+'_'+$required)
  }
 }
 Note ('PROTECTED_FOUR_APPX_'+$stage+'=PASS')
}
function SourcePin([string]$stage){
 $f=Get-Item -LiteralPath $src -ErrorAction Stop
 if($f.Length -ne $SourceWimBytes -or (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $SourceWimSha256.ToUpperInvariant()){
  throw ('BL_R18_SOURCE_DRIFT_'+$stage)
 }
 Note ('SOURCE_'+$stage+'_SHA_BYTES=PASS')
}
function NativeCapabilityState([string]$mount,[string]$cap){
 $b=Native ('CAP_'+($cap -replace '[^A-Za-z0-9]','_')) @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$cap))
 $m=[regex]::Match($b,'(?im)^\s*State\s*:\s*(Installed|Not Present|Staged)\s*$')
 if(-not $m.Success){throw 'BL_R18_CAPABILITY_STATE_PARSE'}
 return $m.Groups[1].Value.ToUpperInvariant().Replace(' ','_')
}
Note 'BLUELITE_R18_UNIVERSAL_GREEN_NATIVE_DISPATCHER_V01'
Note ('MODE='+$Mode+';LINEAGE='+$plan.Lineage+';SOURCE_SHA='+$SourceWimSha256.ToUpperInvariant())
Note ('GREEN_QUEUE_COUNT='+$queue.Count+';WEBVIEW='+$web[0].Decision+';SENSE=KEEP')
if($webNeedsOwnerGate){Note 'WEBVIEW_OWNER_GRAPH=DEFER_TO_SEPARATE_EXACT_NINE_PARENT_MODULE'}
$completed=$false
$mountUsed=$false
$mounted=$false
$ownedCreated=$false
$mount=''
$owned=''
$clone=''
try{
 SourcePin 'PRE'
 ZeroMounts 'PRE'
 $info=Native 'WIMINFO' @('/English','/Get-WimInfo',('/WimFile:'+$src),'/Index:1')
 if($info -notmatch '(?im)^\s*Version\s*:\s*10\.0\.26300(?:\.\d+)?\s*$'){
  throw 'BL_R18_IMAGE_NOT_26300'
 }
 if($queue.Count -eq 0){
  Note 'FASTPATH_ALL_GREEN_TARGETS_ALREADY_ABSENT_FROM_R17_CONTROL=PASS'
  $completed=$true
 }elseif($Mode -ceq 'Preview'){
  foreach($t in $queue){Note ('GUARDED_NATIVE_CAPABILITY_PENDING='+$t.Capability)}
  Note 'PREVIEW_ONLY_NO_MUTATION=PASS'
  $completed=$true
 }else{
  if([string]::IsNullOrWhiteSpace($OwnedDisposableDirectory) -or
     [string]::IsNullOrWhiteSpace($OwnedMountDirectory)){throw 'BL_R18_APPLY_REQUIRES_BOTH_OWNED_PATHS'}
  $owned=[IO.Path]::GetFullPath($OwnedDisposableDirectory)
  $mount=[IO.Path]::GetFullPath($OwnedMountDirectory)
  if($owned -notmatch '^[A-Za-z]:\\work\\E2E\\BlueLite_R18_' -or
     $mount -notmatch '^[A-Za-z]:\\BLR18M' -or
     $owned -eq $mount -or $src.StartsWith($owned,[StringComparison]::OrdinalIgnoreCase)){
   throw 'BL_R18_OWNED_PATH_CONTRACT_FAILED'
  }
  if([IO.Directory]::Exists($owned) -or [IO.Directory]::Exists($mount) -or
     [IO.File]::Exists($owned) -or [IO.File]::Exists($mount)){
   throw 'BL_R18_OWNED_PATH_PREEXISTS'
  }
  $free=[IO.DriveInfo]::new([IO.Path]::GetPathRoot($owned)).AvailableFreeSpace
  if($free -lt (4*$SourceWimBytes)){throw 'BL_R18_INSUFFICIENT_FREE_SPACE'
  }
  [void][IO.Directory]::CreateDirectory($owned)
  $ownedCreated=$true
  $clone=Join-Path $owned 'install.green-owned-disposable.wim'
  [IO.File]::Copy($src,$clone,$false)
  if((Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash -cne $SourceWimSha256.ToUpperInvariant()){throw 'BL_R18_CLONE_SHA_MISMATCH'}
  Note 'OWNED_DISPOSABLE_CLONE_PIN=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $mountUsed=$true
  $null=Native 'MOUNT_RW' @('/English','/Mount-Image',('/ImageFile:'+$clone),'/Index:1',('/MountDir:'+$mount))
  $mounted=$true
  $owner=Native 'MOUNT_OWNER' @('/English','/Get-MountedWimInfo')
  if(-not $owner.Contains($mount) -or -not $owner.Contains($clone)){
   throw 'BL_R18_EXACT_MOUNT_OWNER_MISSING'
  }
  foreach($t in $queue){
   if((NativeCapabilityState $mount $t.Capability) -cne 'INSTALLED'){throw ('BL_R18_NATIVE_PRESTATE_DRIFT_'+$t.Name)}
  }
  $webPre=NativeCapabilityState $mount 'Edge.Webview2.Platform~~~~'
  if($webPre -cne ([string]$web[0].Observed)){throw 'BL_R18_WEBVIEW_PRESTATE_DRIFT'}
  if((NativeCapabilityState $mount 'Microsoft.Windows.Sense.Client~~~~') -cne 'INSTALLED'){throw 'BL_R18_SENSE_FLOOR_MISSING'}
  if((NativeCapabilityState $mount 'Language.Basic~~~en-US~0.0.1.0') -cne 'INSTALLED'){throw 'BL_R18_LANGUAGE_FLOOR_MISSING'}
  ProtectedApps $mount 'PRE'
  if(Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')){throw 'BL_R18_PENDING_XML'}
  $health=Native 'PRE_CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R18_PREHEALTH_NOT_CLEAN'}
  foreach($t in $queue){
   $null=Native ('REMOVE_'+$t.Name) @('/English',('/Image:'+$mount),'/Remove-Capability',('/CapabilityName:'+$t.Capability))
   if((NativeCapabilityState $mount $t.Capability) -cne 'NOT_PRESENT'){throw ('BL_R18_POST_TARGET_NOT_ABSENT_'+$t.Name)}
  }
  if((NativeCapabilityState $mount 'Edge.Webview2.Platform~~~~') -cne $webPre){throw 'BL_R18_WEBVIEW_POSTSTATE_DRIFT'}
  if((NativeCapabilityState $mount 'Microsoft.Windows.Sense.Client~~~~') -cne 'INSTALLED'){throw 'BL_R18_POST_SENSE_FLOOR_MISSING'}
  if((NativeCapabilityState $mount 'Language.Basic~~~en-US~0.0.1.0') -cne 'INSTALLED'){throw 'BL_R18_POST_LANGUAGE_FLOOR_MISSING'}
  ProtectedApps $mount 'POST'
  $health=Native 'POST_CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R18_POSTHEALTH_NOT_CLEAN'}
  $health=Native 'POST_SCANHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/ScanHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R18_SCANHEALTH_NOT_CLEAN'}
  if(Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')){throw 'BL_R18_POST_PENDING_XML'}
  $null=Native 'COMMIT_OWNED' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Commit')
  $mounted=$false
  Note 'EXPERIMENTAL_OWNED_DISPOSABLE_COMMIT=PASS'
  $completed=$true
 }
}catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
finally{
 if($mountUsed -and -not $mounted){
  try{
   $look=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
   if([int]$LASTEXITCODE -eq 0 -and (($look -join [Environment]::NewLine).Contains($mount))){
    $mounted=$true;Note 'RECOVER_OWNED_MOUNT=TRUE'
   }
  }catch{Note ('RECOVER_PROBE_HOLD='+$_.Exception.Message)}
 }
 if($mounted){
  try{$null=Native 'DISCARD_OWNED' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard');$mounted=$false;Note 'OWNED_DISCARD=PASS'}
  catch{Note ('DISCARD_HOLD='+$_.Exception.Message)}
 }
 if($mountUsed -and -not $mounted -and [IO.Directory]::Exists($mount)){
  try{[IO.Directory]::Delete($mount,$false);Note 'EMPTY_OWNED_MOUNT_REMOVED=PASS'}
  catch{Note ('OWNED_MOUNT_FOLDER_HOLD='+$_.Exception.Message)}
 }
 if($ownedCreated -and -not $completed -and -not $mounted){
  try{
   if([IO.Directory]::Exists($owned) -and [IO.File]::Exists($clone)){
    [IO.File]::Delete($clone)
   }
   [IO.Directory]::Delete($owned,$false)
   Note 'FAILED_OWNED_DISPOSABLE_RETIRED=PASS'
  }catch{Note ('OWNED_ROLLBACK_HOLD='+$_.Exception.Message)}
 }
 $clean=$false
 try{
  ZeroMounts 'POST'
  SourcePin 'POST'
  if($mountUsed -and [IO.Directory]::Exists($mount)){throw 'BL_R18_OWNED_MOUNT_STILL_EXISTS'}
  $clean=$true
 }catch{Note ('POST_SOURCE_OR_MOUNT_HOLD='+$_.Exception.Message)}
 if($completed -and $clean){
  if($queue.Count -eq 0){
   Note 'RESULT=PASS_R18_NATIVE_DISPATCHER_SOURCE_BOUND_FASTPATH_NOOP_ONLY'
  }elseif($Mode -ceq 'Preview'){
   Note 'RESULT=PASS_R18_NATIVE_DISPATCHER_GUARDED_PREVIEW_ONLY'
  }else{Note 'RESULT=PASS_R18_NATIVE_DISPOSABLE_GREEN_COMMIT_SCOPE_ONLY'}
 }else{Note 'RESULT=HOLD_R18_NATIVE_DISPATCHER'}
 Note 'NO_HOST_DEBLOAT_NO_UNPROVEN_WEBVIEW_OR_AMBER_NO_ISO_NO_RELEASE'
}
