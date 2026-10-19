# BlueLite v1.0 R20 - universal 26300.x source-bound high-impact native preflight.
# Exact operator 26300.9807 WIM is immutable. One owned /ReadOnly mount, /Discard.
[CmdletBinding()]
param(
 [string]$ImagePath='C:\work\26300.9807-UUP\install.wim',
 [string]$ExpectedSha256='0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49',
 [long]$ExpectedBytes=7021953581,
 [string]$ExpectedImageVersion='10.0.26300',
 [string]$ExpectedServicePackBuild='9807',
 [string]$PriorReport='C:\work\logs\BlueLite_26300_9807_DirectSourceIdentity_R19P.txt',
 [string]$ReportPath='C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20.txt',
 [string]$JsonPath='C:\work\logs\BlueLite_26300_9807_HighImpactNativePreflight_R20.json',
 [string]$MountPath='C:\BLR20RO'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R20_POWERSHELL7_REQUIRED'}
$principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R20_ADMIN_REQUIRED'}
$dism=Join-Path $env:WINDIR 'System32\dism.exe'
$wim=[IO.Path]::GetFullPath($ImagePath)
$mount=[IO.Path]::GetFullPath($MountPath)
$report=[IO.Path]::GetFullPath($ReportPath)
$json=[IO.Path]::GetFullPath($JsonPath)
$prior=[IO.Path]::GetFullPath($PriorReport)
if(-not [IO.File]::Exists($dism)){throw 'BL_R20_DISM_NOT_FOUND'}
if($wim -notmatch '^[A-Za-z]:\\' -or $mount -notmatch '^[A-Za-z]:\\BLR20RO$'){throw 'BL_R20_SOURCE_OR_OWNED_MOUNT_PATH_INVALID'}
if($wim -eq $mount -or $report -eq $json -or $report -eq $wim -or $json -eq $wim){throw 'BL_R20_PATH_COLLISION'}
if([IO.Directory]::Exists($mount) -or [IO.File]::Exists($mount)){throw 'BL_R20_OWNED_MOUNT_ALREADY_EXISTS'}
foreach($output in @($report,$json)){
 if([IO.File]::Exists($output)){throw ('BL_R20_OUTPUT_NO_OVERWRITE_'+$output)}
 if(-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($output))){throw 'BL_R20_OUTPUT_PARENT_MISSING'}
}
if($ExpectedSha256 -notmatch '^[0-9A-Fa-f]{64}$'){throw 'BL_R20_SHA_FORMAT'}
if($ExpectedImageVersion -notmatch '^10\.0\.26300(?:\.\d+)?$' -or $ExpectedServicePackBuild -notmatch '^\d{1,6}$'){throw 'BL_R20_EXPECTED_LINEAGE_FORMAT'}
if(-not [IO.File]::Exists($prior) -or (Get-Item -LiteralPath $prior).Length -ne 2482 -or
   (Get-FileHash -LiteralPath $prior -Algorithm SHA256).Hash -cne '2D9B7F61380B081EC062ABFF225EDABAC0C2E3E0C2394223EA0A12DDB4BFBF66'){
 throw 'BL_R20_ORIGINAL_R19P_EVIDENCE_MISMATCH'
}
$priorText=[IO.File]::ReadAllText($prior)
foreach($proof in @('ISO_SHA256=A564F5EF2F6C7B53E3DD42C66CCC4CAA2DF2995348E0FBDA4992A55212AA4A3F',
 'WIM_SHA256=0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49',
 'DISM_INDEX_1|Version : 10.0.26300',
 'DISM_INDEX_1|ServicePack Build : 9807',
 'DISM_INDEX_1|Edition : Professional',
 'RESULT=HOLD_R19P_SOURCE_IDENTITY')){
 if(-not $priorText.Contains($proof)){throw ('BL_R20_PRIOR_LOG_PROOF_MISSING_'+$proof)}
}
$enc=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($report,'',$enc)
function Note([string]$line){
 Write-Host $line
 [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$enc)
}
function Pin([string]$stage){
 $f=Get-Item -LiteralPath $wim -ErrorAction Stop
 if($f.Length -ne $ExpectedBytes){throw ('BL_R20_SOURCE_BYTE_DRIFT_'+$stage)}
 if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BL_R20_IMAGE_REPARSE'}
 $sha=(Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash
 if($sha -cne $ExpectedSha256.ToUpperInvariant()){throw ('BL_R20_SOURCE_SHA_DRIFT_'+$stage)}
 Note ('SOURCE_'+$stage+'_PIN=PASS;BYTES='+$f.Length+';SHA='+$sha)
}
function Native([string]$name,[string[]]$arguments,[bool]$strict=$true){
 $result=@(& $dism @arguments 2>&1|ForEach-Object {[string]$_})
 $exit=[int]$LASTEXITCODE
 $body=$result -join [Environment]::NewLine
 Note ('NATIVE_'+$name+'_EXIT='+$exit)
 if($strict -and ($exit -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.')){
  throw ('BL_R20_NATIVE_'+$name+'_FAILED_'+$exit)
 }
 return [pscustomobject]@{Exit=$exit;Body=$body}
}
function ZeroMounts([string]$step){
 $m=Native ('MOUNT_TABLE_'+$step) @('/English','/Get-MountedWimInfo')
 if($m.Body -notmatch '(?im)^[ \t]*No mounted images found\.[ \t]*$' -or
    $m.Body -match '(?im)^[ \t]*Mount Dir[ \t]*:'){
  throw ('BL_R20_OTHER_MOUNT_DETECTED_'+$step)
 }
 Note ('ZERO_MOUNTS_'+$step+'=PASS')
}
function ImagePart([string]$native){
 $a=[regex]::Match($native,'(?im)^[ \t]*Details for image[ \t]*:[^\r\n]*$')
 if(-not $a.Success){throw 'BL_R20_WIMINFO_IMAGE_SECTION_MISSING'}
 return $native.Substring($a.Index+$a.Length)
}
function Field([string]$section,[string]$key){
 $p='(?im)^[ \t]*'+[regex]::Escape($key)+'[ \t]*:[ \t]*([^\r\n]+)'
 $m=[regex]::Match($section,$p)
 if(-not $m.Success){throw ('BL_R20_WIMINFO_FIELD_MISSING_'+$key)}
 return $m.Groups[1].Value.Trim()
}
function Capability([string]$name){
 $r=Native ('CAP_'+($name -replace '[^A-Za-z0-9]','_')) @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$name)) $false
 if($r.Exit -ne 0){return 'UNRESOLVED_NATIVE'}
 $m=[regex]::Match($r.Body,'(?im)^[ \t]*State[ \t]*:[ \t]*(Installed|Not Present|Staged)[ \t]*$')
 if(-not $m.Success){return 'UNRESOLVED_OUTPUT'}
 return $m.Groups[1].Value.ToUpperInvariant().Replace(' ','_')
}
function PackageFamily([string]$prefix,[int]$limit){
 $dir=Join-Path $mount 'Windows\servicing\Packages'
 $all=@(Get-ChildItem -LiteralPath $dir -File -Filter ($prefix+'*.mum') -ErrorAction Stop|Sort-Object -Property Name)
 if($all.Count -gt $limit){throw ('BL_R20_TARGET_PACKAGE_LIMIT_'+$prefix)}
 $entries=[Collections.Generic.List[object]]::new()
 foreach($f in $all){
  if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BL_R20_PACKAGE_MUM_REPARSE'}
  $id=$f.BaseName
  $r=Native 'PKG_INFO' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$id)) $false
  $state='UNRESOLVED_NATIVE'
  if($r.Exit -eq 0){
   $m=[regex]::Match($r.Body,'(?im)^[ \t]*State[ \t]*:[ \t]*(Installed|Staged|Superseded|Install Pending|Uninstall Pending)[ \t]*$')
   if($m.Success){$state=$m.Groups[1].Value.ToUpperInvariant().Replace(' ','_')}
   else{$state='UNRESOLVED_OUTPUT'}
  }
  Note ('PACKAGE='+$id+';STATE='+$state+';NATIVE_EXIT='+$r.Exit)
  [void]$entries.Add([pscustomobject]@{Identity=$id;State=$state;NativeExit=$r.Exit})
 }
 return @($entries.ToArray())
}
$mountAttempt=$false;$mounted=$false;$succeeded=$false;$closed=$false;$data=$null
try{
 Note 'BLUELITE_R20_UNIVERSAL_26300_SOURCE_HIGH_IMPACT_NATIVE_PREFLIGHT'
 Note 'MODE=READONLY;PHASE=MAX_PRE;MUTATION=NONE'
 Note ('SOURCE='+$wim+';INDEX=1')
 Note 'R19P_ACTUAL_SOURCE_HASH_AND_NATIVE_RAW_IMAGE_IDENTITY=PASS;OLD_SCRIPT_VERSION_PARSER=FALSE_HOLD'
 Pin 'PRE'
 ZeroMounts 'PRE'
 $wi=Native 'WIMINFO' @('/English','/Get-WimInfo',('/WimFile:'+$wim),'/Index:1')
 $details=ImagePart $wi.Body
 $version=Field $details 'Version'
 $spb=Field $details 'ServicePack Build'
 $arch=Field $details 'Architecture'
 $edition=Field $details 'Edition'
 if($version -cne $ExpectedImageVersion -or $spb -cne $ExpectedServicePackBuild -or $arch -cne 'x64' -or $edition -cne 'Professional'){
  throw ('BL_R20_IMAGE_IDENTITY_NOT_EXPECTED_'+$version+'_'+$spb+'_'+$arch+'_'+$edition)
 }
 Note ('REAL_IMAGE_VERSION='+$version+';SP_BUILD='+$spb+';ARCH='+$arch+';EDITION='+$edition)
 [void][IO.Directory]::CreateDirectory($mount)
 $mountAttempt=$true
 $null=Native 'MOUNT_READONLY' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
 $mounted=$true
 Note 'OWNED_READONLY_MOUNT=PASS'
 $cap=[ordered]@{}
 foreach($name in @('Edge.Webview2.Platform~~~~','DirectX.Configuration.Database~~~~0.0.1.0',
   'Windows.Kernel.LA57~~~~0.0.1.0','Microsoft.Windows.Sense.Client~~~~','Language.Basic~~~en-US~0.0.1.0')){
  $key=$name
  $cap[$key]=Capability $name
  Note ('CAPABILITY='+$name+';STATE='+$cap[$key])
 }
 $app=Native 'APPX' @('/English',('/Image:'+$mount),'/Get-ProvisionedAppxPackages')
 $appList=[Collections.Generic.List[string]]::new()
 foreach($line in ($app.Body -split '[\r\n]+')){
  if($line -match '^[ \t]*DisplayName[ \t]*:[ \t]*(\S+)[ \t]*$'){[void]$appList.Add($Matches[1])}
 }
 if($appList.Count -eq 0){throw 'BL_R20_APPX_LIST_UNPARSED'}
 foreach($wanted in @('Microsoft.SecHealthUI','Microsoft.Windows.Photos','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad')){
  if($wanted -notin $appList){throw ('BL_R20_PROTECTED_APPX_MISSING_'+$wanted)}
 }
 Note ('PROVISIONED_APPX_COUNT='+$appList.Count+';FINAL_FOUR=PASS;APPINSTALLER_PROVISIONED='+('Microsoft.DesktopAppInstaller' -in $appList))
 $webPackages=@(PackageFamily 'Microsoft-Edge-WebView-FOD-Package' 12)
 $onePackages=@(PackageFamily 'Microsoft-Windows-OneDrive-Setup-Package' 24)
 $searchPackages=@(PackageFamily 'Microsoft-Windows-SearchEngine-Client-Package' 12)
 Note ('WEBVIEW_FOD_MUM_IDENTITIES='+$webPackages.Count+';ONEDRIVE_SETUP_MUM_IDENTITIES='+$onePackages.Count+';SEARCHENGINE_WRAPPER_MUM_IDENTITIES='+$searchPackages.Count)
 if(Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')){throw 'BL_R20_PENDING_XML'}
 $all=Native 'PACKAGE_STATES' @('/English',('/Image:'+$mount),'/Get-Packages')
 $pending=[regex]::Matches($all.Body,'(?im)^[ \t]*State[ \t]*:[ \t]*(Install Pending|Uninstall Pending|Partially Installed)[ \t]*$').Count
 Note ('PENDING_PACKAGE_STATE_ROWS='+$pending)
 if($pending -ne 0){throw 'BL_R20_PENDING_CBS_STATE'}
 $health=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
 if($health.Body -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R20_CBS_CHECKHEALTH_NOT_CLEAN'}
 Note 'CBS_CHECKHEALTH=CLEAN'
 if($cap['Microsoft.Windows.Sense.Client~~~~'] -cne 'INSTALLED'){throw 'BL_R20_DEFENDER_SENSE_PROTECTED_FLOOR'}
 if($cap['Language.Basic~~~en-US~0.0.1.0'] -cne 'INSTALLED'){throw 'BL_R20_LANGUAGE_ENUS_PROTECTED_FLOOR'}
 $web=$cap['Edge.Webview2.Platform~~~~']
 $next=if($web -ceq 'INSTALLED'){'WEBVIEW_FOD_26300_OWNER_GRAPH_THEN_NATIVE_DISPOSABLE'}elseif($web -ceq 'NOT_PRESENT'){'NEXT_HIGH_IMPACT_FOD_OR_CBS_TARGET_REQUIRED'}else{'WEBVIEW_FOD_DEPENDENCY_UNRESOLVED'}
 Note ('NEXT_HIGH_IMPACT='+$next)
 $data=[pscustomobject][ordered]@{
  Schema='BlueLite.MAXPRE.NativeSourcePreflight.v0.1'
  Source=$wim;SourceSha256=$ExpectedSha256.ToUpperInvariant();SourceBytes=$ExpectedBytes
  ImageVersion=$version;ServicePackBuild=$spb;Architecture=$arch;Edition=$edition
  CapabilityStates=$cap;ProvisionedAppx=@($appList.ToArray())
  WebViewPackages=@($webPackages);OneDrivePackages=@($onePackages);SearchEnginePackages=@($searchPackages)
  PendingPackageStateRows=$pending;CBSCheckHealth='CLEAN';NextHighImpact=$next
  MutationAllowed=$false;ReleaseCertified=$false
 }
 $succeeded=$true
}catch{
 Note ('FAIL_CLOSED='+$_.Exception.Message)
}finally{
 if($mountAttempt -and -not $mounted){
  try{
   $probe=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object{[string]$_})
   if([int]$LASTEXITCODE -eq 0 -and (($probe -join [Environment]::NewLine).Contains($mount))){
    $mounted=$true
    Note 'RECOVER_OWNED_MOUNT_FROM_NATIVE_TABLE=TRUE'
   }
  }catch{Note ('OWNED_MOUNT_RECOVERY_HOLD='+$_.Exception.Message)}
 }
 if($mounted){
  try{
   $null=Native 'DISCARD_OWNED_READONLY' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
   $mounted=$false
   Note 'OWNED_READONLY_DISCARD=PASS'
  }catch{Note ('OWNED_DISCARD_HOLD='+$_.Exception.Message)}
 }
 if($mountAttempt -and -not $mounted -and [IO.Directory]::Exists($mount)){
  try{[IO.Directory]::Delete($mount,$false);Note 'EMPTY_OWNED_MOUNT_FOLDER_DELETED=PASS'}
  catch{Note ('MOUNT_DIR_CLEANUP_HOLD='+$_.Exception.Message)}
 }
 try{
  ZeroMounts 'POST'
  Pin 'POST'
  if($mountAttempt -and [IO.Directory]::Exists($mount)){throw 'BL_R20_MOUNT_DIRECTORY_REMAINS'}
  $closed=$true
 }catch{Note ('LIFECYCLE_HOLD='+$_.Exception.Message)}
 if($succeeded -and $closed){
  [IO.File]::WriteAllText($json,($data|ConvertTo-Json -Depth 20)+[Environment]::NewLine,$enc)
  Note ('REPORT_JSON='+$json)
  Note 'RESULT=PASS_R20_NATIVE_26300_9807_HIGH_IMPACT_PREFLIGHT_READONLY_ONLY'
 }else{
  Note 'RESULT=HOLD_R20_NATIVE_SOURCE_PREFLIGHT'
 }
 Note 'NO_WIM_CLONE_NO_CBS_MUTATION_NO_ISO_BUILD_NO_RELEASE'
}
