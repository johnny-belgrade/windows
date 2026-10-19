# BlueLite MAX_PRE Universal Impact Planner v0.1 - READ ONLY, 26300.x
[CmdletBinding()]
param(
 [Parameter(Mandatory)][string]$ImagePath,
 [Parameter(Mandatory)][string]$ExpectedSha256,
 [Parameter(Mandatory)][long]$ExpectedBytes,
 [Parameter(Mandatory)][string]$ReportPath,
 [Parameter(Mandatory)][string]$JsonPath,
 [int]$Index=1
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_ENGINE_PS7_REQUIRED'}
$p=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ENGINE_ADMIN_REQUIRED'}
if($Index -ne 1){throw 'BL_ENGINE_INDEX1_ONLY'}
$wim=[IO.Path]::GetFullPath($ImagePath)
$log=[IO.Path]::GetFullPath($ReportPath)
$json=[IO.Path]::GetFullPath($JsonPath)
$mount='C:\BLUIM1RO'
$dism=Join-Path $env:WINDIR 'System32\dism.exe'
if(-not [IO.File]::Exists($wim)){throw 'BL_ENGINE_SOURCE_NOT_FOUND'}
if(-not [IO.File]::Exists($dism)){throw 'BL_ENGINE_DISM_NOT_FOUND'}
if($wim -notmatch '^[A-Za-z]:\\'){throw 'BL_ENGINE_LOCAL_WIM_REQUIRED'}
if(-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($log)) -or -not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($json))){throw 'BL_ENGINE_LOG_PARENT_MISSING'}
if([IO.File]::Exists($log) -or [IO.File]::Exists($json)){throw 'BL_ENGINE_REPORT_OVERWRITE_REFUSED'}
if([IO.Directory]::Exists($mount) -or [IO.File]::Exists($mount)){throw 'BL_ENGINE_MOUNT_EXISTS'}
if($wim -eq $log -or $wim -eq $json -or $log -eq $json){throw 'BL_ENGINE_PATH_COLLISION'}
$utf8=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($log,'',$utf8)
function Note([string]$s){
 Write-Host $s
 [IO.File]::AppendAllText($log,$s+[Environment]::NewLine,$utf8)
}
function Native([string]$label,[string[]]$arguments,[bool]$strict=$true){
 $rows=@(& $dism @arguments 2>&1 | ForEach-Object {[string]$_})
 $rc=[int]$LASTEXITCODE
 $body=$rows -join [Environment]::NewLine
 Note ('NATIVE_'+$label+'_EXIT='+$rc)
 if($strict -and ($rc -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.')){
  throw ('BL_ENGINE_NATIVE_'+$label+'_FAILED_'+$rc)
 }
 return [pscustomobject]@{Exit=$rc;Body=$body}
}
function ZeroMounts([string]$stage){
 $r=Native ('MOUNTS_'+$stage) @('/English','/Get-MountedWimInfo')
 if($r.Body -notmatch '(?im)^\s*No mounted images found\.\s*$' -or $r.Body -match '(?im)^\s*Mount Dir\s*:'){
  throw ('BL_ENGINE_MOUNT_TABLE_NOT_ZERO_'+$stage)
 }
 Note ('ZERO_MOUNTS_'+$stage+'=PASS')
}
function PinWim([string]$stage){
 $f=Get-Item -LiteralPath $wim -ErrorAction Stop
 if($f.Length -ne $ExpectedBytes){throw ('BL_ENGINE_WIM_SIZE_MISMATCH_'+$stage)}
 $hash=(Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash
 if($hash -cne $ExpectedSha256.ToUpperInvariant()){throw ('BL_ENGINE_WIM_SHA_MISMATCH_'+$stage)}
 Note ('WIM_'+$stage+'_PIN=PASS;BYTES='+$f.Length+';SHA='+$hash)
}
function Cap([string]$name){
 $q=Native ('CAP_'+($name -replace '[^a-zA-Z0-9]','_')) @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$name)) $false
 if($q.Exit -ne 0){return 'UNRESOLVED_NATIVE'}
 $m=[regex]::Match($q.Body,'(?im)^\s*State\s*:\s*(Installed|Not Present|Staged)\s*$')
 if(-not $m.Success){return 'UNRESOLVED_OUTPUT'}
 return $m.Groups[1].Value.ToUpperInvariant().Replace(' ','_')
}
function AppNames {
 $r=Native 'APPX' @('/English',('/Image:'+$mount),'/Get-ProvisionedAppxPackages')
 $names=[Collections.Generic.List[string]]::new()
 foreach($line in ($r.Body -split '[\r\n]+')){
  if($line -match '^\s*DisplayName\s*:\s*(\S+)\s*$'){[void]$names.Add($Matches[1])}
 }
 if($names.Count -eq 0){throw 'BL_ENGINE_APPX_LIST_UNPARSED'}
 return @($names.ToArray())
}
function Row([string]$target,[int]$priority,[string]$state,[string]$decision,[Nullable[long]]$measuredDelta,[string]$evidence){
 [pscustomobject][ordered]@{
  Target=$target;Priority=$priority;ObservedState=$state;Decision=$decision
  EqualCompressionWimDeltaReferenceBytes=$measuredDelta
  ReferenceEvidence=$evidence;ProductionRemovalAuthorized=$false
 }
}
$mountAttempt=$false
$mounted=$false
$bodyOK=$false
$cleanupOK=$false
$plan=$null
try{
 Note 'BLUELITE_MAXPRE_UNIVERSAL_IMPACT_PLANNER_V01'
 Note 'MODE=READONLY;MUTATION=FORBIDDEN;SOURCE_SPECIFIC_PIN_REQUIRED'
 Note ('SOURCE='+$wim+';INDEX='+$Index)
 PinWim 'PRE'
 ZeroMounts 'PRE'
 $free=[IO.DriveInfo]::new([IO.Path]::GetPathRoot($wim)).AvailableFreeSpace
 if($free -lt 2147483648){throw 'BL_ENGINE_FREE_SPACE_LT_2GIB'}
 $info=Native 'WIMINFO' @('/English','/Get-WimInfo',('/WimFile:'+$wim),('/Index:'+$Index))
 if($info.Body -notmatch '(?im)^\s*Version\s*:\s*10\.0\.26300(?:\.\d+)?\s*$'){throw 'BL_ENGINE_NOT_26300_LINEAGE'}
 $arch='UNRESOLVED'
 if($info.Body -match '(?im)^\s*Architecture\s*:\s*(.+?)\s*$'){$arch=$Matches[1].Trim()}
 Note ('LINEAGE=26300.x;ARCH='+$arch)
 [void][IO.Directory]::CreateDirectory($mount)
 $mountAttempt=$true
 $null=Native 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$wim),('/Index:'+$Index),('/MountDir:'+$mount),'/ReadOnly')
 $mounted=$true
 Note 'READONLY_MOUNT=PASS'
 $web=Cap 'Edge.Webview2.Platform~~~~'
 $dx=Cap 'DirectX.Configuration.Database~~~~0.0.1.0'
 $la=Cap 'Windows.Kernel.LA57~~~~0.0.1.0'
 $sense=Cap 'Microsoft.Windows.Sense.Client~~~~'
 $apps=@(AppNames)
 $four=@('Microsoft.SecHealthUI','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad','Microsoft.Windows.Photos')
 $missing=@($four|Where-Object {$_ -notin $apps})
 $appInstaller=('Microsoft.DesktopAppInstaller' -in $apps)
 $store=('Microsoft.WindowsStore' -in $apps)
 $purchase=('Microsoft.StorePurchaseApp' -in $apps)
 $on=@(Get-ChildItem -LiteralPath (Join-Path $mount 'Windows\servicing\Packages') -File -Filter 'Microsoft-Windows-OneDrive-Setup-Package~*.mum' | Select-Object -ExpandProperty Name)
 Note ('CAP_STATES=WEBVIEW:'+ $web+';DIRECTX:'+ $dx+';LA57:'+ $la+';SENSE:'+ $sense)
 Note ('APPS='+$apps.Count+';FOUR_KEEP_MISSING='+($missing -join ',')+';APPINSTALLER='+$appInstaller+';STORE='+$store+';PURCHASE='+$purchase)
 Note ('ONEDRIVE_SETUP_MUM_COUNT='+$on.Count)
 if(Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')){throw 'BL_ENGINE_PENDING_XML'}
 $health=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
 if($health.Body -notmatch '(?i)No component store corruption detected\.'){throw 'BL_ENGINE_HEALTH_NOT_CLEAN'}
 Note 'CBS_CHECKHEALTH=CLEAN;PENDING_XML=FALSE'
 if($sense -ne 'INSTALLED'){throw ('BL_ENGINE_PROTECTED_SENSE_NOT_INSTALLED_'+$sense)}
 if($missing.Count -gt 0){throw ('BL_ENGINE_PROTECTED_FOUR_APPS_MISSING_'+($missing -join ','))}
 $targets=@(
  (Row 'WebView.FoD' 1 $web $(if($web -eq 'INSTALLED'){'NEEDS_EXACT_OWNER_GATE'}elseif($web -eq 'NOT_PRESENT'){'ALREADY_ABSENT'}else{'UNKNOWN_DEPENDENCY'}) ([long]603556113) 'R8 26300.9711 equal-max WIM comparison only'),
  (Row 'OneDrive.Setup' 2 ('MUM_FILES_'+$on.Count) $(if($on.Count -gt 0){'NEEDS_NATIVE_PACKAGE_INFO'}else{'MUM_ABSENT_NOT_NATIVE_PROOF'}) $null 'S31 26300 native group removal; MUM count not installed state'),
  (Row 'DesktopAppInstaller' 3 $(if($appInstaller){'PROVISIONED'}else{'NOT_PROVISIONED'}) $(if($appInstaller){'NEEDS_OWNER_GATE'}else{'ALREADY_NOT_PROVISIONED'}) $null 'S36/S37 26300 proven AppX source-specific'),
  (Row 'DirectX.Configuration.Database' 4 $dx $(if($dx -eq 'INSTALLED'){'KNOWN_NATIVE_RECIPE_GATE'}elseif($dx -eq 'NOT_PRESENT'){'ALREADY_ABSENT'}else{'UNKNOWN_DEPENDENCY'}) $null 'S28 26300 native GREEN'),
  (Row 'Windows.Kernel.LA57' 5 $la $(if($la -eq 'INSTALLED'){'KNOWN_NATIVE_RECIPE_GATE'}elseif($la -eq 'NOT_PRESENT'){'ALREADY_ABSENT'}else{'UNKNOWN_DEPENDENCY'}) $null 'S28 26300 native GREEN'),
  (Row 'Defender.Sense' 99 $sense 'KEEP_PROTECTED' $null 'Defender ON floor'),
  (Row 'SearchEngine.ClientWrapper' 100 'NOT_REPROBED' 'LOW_PAYOFF_HOLD' $null 'R15R1 26300.9711 CBS Updates FF; 26200 tiny wrapper')
 )
 $plan=[pscustomobject][ordered]@{
  Schema='BlueLite.MAXPRE.ImpactPlan.v0.1'
  Mode='READONLY';Source=$wim;ImageIndex=$Index;ImageSha256=$ExpectedSha256.ToUpperInvariant()
  Lineage='26300.x';Architecture=$arch;TargetObservation=@{WebView=$web;DirectX=$dx;LA57=$la;Sense=$sense}
  ProvisionedAppx=@($apps);OneDriveSetupMumNames=@($on)
  Candidates=@($targets);MutationAllowed=$false;ReleaseCertified=$false
 }
 $bodyOK=$true
}catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
finally{
 if($mountAttempt -and -not $mounted){
  try{
   $r=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object{[string]$_})
   if([int]$LASTEXITCODE -eq 0 -and (($r -join [Environment]::NewLine).Contains($mount))){
    $mounted=$true
    Note 'OWNED_MOUNT_RECOVERED_FROM_TABLE=TRUE'
   }
  }catch{Note ('MOUNT_RECOVERY_HOLD='+$_.Exception.Message)}
 }
 if($mounted){
  try{
   $null=Native 'RO_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
   $mounted=$false
   Note 'READONLY_DISCARD=PASS'
  }catch{Note ('RO_DISCARD_HOLD='+$_.Exception.Message)}
 }
 if(-not $mounted -and $mountAttempt -and [IO.Directory]::Exists($mount)){
  try{[IO.Directory]::Delete($mount,$false);Note 'EMPTY_OWNED_MOUNT_REMOVED=PASS'}
  catch{Note ('OWNED_MOUNT_FOLDER_HOLD='+$_.Exception.Message)}
 }
 try{
  ZeroMounts 'POST'
  PinWim 'POST'
  if($mountAttempt -and [IO.Directory]::Exists($mount)){throw 'BL_ENGINE_OWNED_MOUNT_NOT_RELEASED'}
  $cleanupOK=$true
 }catch{Note ('CLEANUP_HOLD='+$_.Exception.Message)}
 if($bodyOK -and $cleanupOK){
  [IO.File]::WriteAllText($json,($plan|ConvertTo-Json -Depth 10)+[Environment]::NewLine,$utf8)
  Note ('JSON='+$json)
  Note 'RESULT=PASS_UNIVERSAL_MAXPRE_IMPACT_PLANNER_READONLY_ONLY'
 }else{Note 'RESULT=HOLD_UNIVERSAL_MAXPRE_IMPACT_PLANNER_READONLY'}
 Note 'NO_WIM_CLONE_NO_NATIVE_REMOVE_NO_CBS_OR_APPX_MUTATION_NO_ISO_NO_RELEASE'
}
