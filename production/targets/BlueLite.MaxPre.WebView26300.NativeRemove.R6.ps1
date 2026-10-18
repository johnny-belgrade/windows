# BlueLite 26300 S37 WebView R6: single owned DISPOSABLE native Remove-Capability test.
# Preserves S37, RollupFix, Runlevel-Win4 and Desktop-Required. No host OS debloat.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $who=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $who.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $src='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $srcHash='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $owned='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6'
 $clone=Join-Path $owned 'install.webview-disposable.wim'
 $mount=Join-Path $owned 'mount'
 $log=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_NativeRemoval_R6.txt'
 $r3=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.csv'
 $r4=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParents_R4.csv'
 $r5=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_HiddenCapability_R5R1.txt'
 $cap='Edge.Webview2.Platform~~~~'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
 foreach($p in @($owned,$log)){
  if(Test-Path -LiteralPath $p){throw ('BL_R6_OWNED_PATH_ALREADY_EXISTS='+$p)}
 }
 foreach($pin in @(
  @{Path=$r3;Size=1405L;SHA='0998C6FFB7A9875C5F1A194982AD114D64B16FE48466860756B626F1317927AF'},
  @{Path=$r4;Size=2565L;SHA='CBA75A6D4778CC34FD1C19A6A256C52B69DC3C059F040E4DA9A7FBEEAF80650F'},
  @{Path=$r5;Size=2037L;SHA='C9E371715EC961FA8FC89D2CBFD96D6E908FDB705931446ADAB9BB45248BA49E'}
 )){
  $f=Get-Item -LiteralPath $pin.Path -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne $pin.Size -or
     (Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash -cne $pin.SHA){
   throw ('BL_R6_ORIGINAL_EVIDENCE_PIN_FAILED='+$pin.Path)
  }
 }
 $r3rows=@(Import-Csv -LiteralPath $r3 -Encoding utf8)
 $parents=@(Import-Csv -LiteralPath $r4 -Encoding utf8)
 if($r3rows.Count -ne 8 -or $parents.Count -ne 9 -or
   @($r3rows|Where-Object {$_.DismGetPackageInfoExit -cne '0' -or $_.RegQueryExit -cne '0'}).Count -ne 0 -or
   @($parents|Where-Object {$_.DismPackageInfoExit -cne '0' -or $_.CBSRegistryExit -cne '0' -or $_.ImageMutated -cne 'False'}).Count -ne 0){
  throw 'BL_R6_R3_R4_TOPOLOGY_CHANGED'
 }
 $fod=@($r3rows|Where-Object {$_.PackageIdentity -match '^Microsoft-Edge-WebView-FOD-Package(?:-Wrapper)?~'})
 if($fod.Count -ne 3 -or
   @($fod|Where-Object {$_.DismPackageState -ceq 'Installed'}).Count -ne 2 -or
   @($fod|Where-Object {$_.DismPackageState -ceq 'Staged'}).Count -ne 1){
  throw 'BL_R6_FOD_THREE_EXPECTATIONS_CHANGED'
 }
 $originalR5=[IO.File]::ReadAllText($r5)
 foreach($proof in @(
   'RESULT=PASS_S37_R5R1_EXACT_HIDDEN_EDGE_WEBVIEW_CAPABILITY_NATIVE_READONLY',
   'EXACT_CAPABILITY_IDENTITY=Edge.Webview2.Platform~~~~',
   'EXACT_CAPABILITY_STATE=Installed',
   'POST_ZERO_MOUNTS=PASS'
 )){
  if(-not $originalR5.Contains($proof)){throw ('BL_R6_R5R1_PROOF_MISSING='+$proof)}
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$msg){
  Write-Host $msg
  [IO.File]::AppendAllText($log,$msg+[Environment]::NewLine,$utf8)
 }
 function RunDism([string]$tag,[string[]]$dismArgs,[bool]$requireCompletion=$true){
  $reply=@(& $dism @dismArgs 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $text=$reply -join [Environment]::NewLine
  if($code -ne 0 -or $text -match '(?im)^\s*Error\s*:' -or
     ($requireCompletion -and $text -notmatch '(?i)The operation completed successfully\.')){
   foreach($line in $reply){Note ('DISM_'+$tag+'_RAW='+$line)}
   throw ('BL_R6_DISM_'+$tag+'_FAILED_EXIT='+$code)
  }
  return $text
 }
 function ZeroMounts([string]$phase){
  $out=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $empty=@($out|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $busy=@($out|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('DISM_'+$phase+'_EXIT='+$exit+';EMPTY_MARKERS='+$empty+';MOUNT_ROWS='+$busy)
  if($exit -ne 0 -or $empty -ne 1 -or $busy -ne 0){
   foreach($line in $out){Note ('DISM_'+$phase+'_RAW='+$line)}
   throw ('BL_R6_'+$phase+'_ZERO_NOT_VERIFIED')
  }
 }
 function StateFrom([string]$raw){
  $match=[regex]::Match($raw,'(?im)^\s*State\s*:\s*(.+?)\s*$')
  if(-not $match.Success){throw 'BL_R6_NATIVE_STATE_NOT_RETURNED'}
  return $match.Groups[1].Value.Trim()
 }
 function GetCap(){
  $raw=RunDism 'EXACT_CAPABILITY' @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$cap))
  $m=[regex]::Match($raw,'(?im)^\s*Capability Identity\s*:\s*(.+?)\s*$')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $cap){
   throw 'BL_R6_NATIVE_CAPABILITY_IDENTITY_CHANGED'
  }
  return (StateFrom $raw)
 }
 function GetPackage([string]$id){
  $raw=RunDism 'PACKAGE_INFO' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$id))
  $m=[regex]::Match($raw,'(?im)^\s*Package Identity\s*:\s*(.+?)\s*$')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $id){
   throw ('BL_R6_PACKAGE_IDENTITY_CHANGED='+$id)
  }
  return (StateFrom $raw)
 }
 function CheckParents([string]$phase){
  foreach($p in $parents){
   $state=GetPackage $p.ParentIdentity
   Note ('PARENT_'+$phase+'='+$p.ParentIdentity+';STATE='+$state)
   if($state -cne $p.DismState){throw ('BL_R6_PROTECTED_PARENT_STATE_DRIFT_'+$phase+'='+$p.ParentIdentity)}
  }
  Note ('PROTECTED_NINE_PARENTS_'+$phase+'=PASS')
 }
 function CheckHealth([string]$phase,[string]$method){
  $raw=RunDism ($method+'_'+$phase) @('/English',('/Image:'+$mount),'/Cleanup-Image',('/'+$method))
  if($raw -notmatch '(?i)No component store corruption detected\.'){
   throw ('BL_R6_CBS_HEALTH_NOT_CLEAN_'+$phase+'_'+$method)
  }
  Note ('CBS_'+$method+'_'+$phase+'=CLEAN')
 }
 function PendingZero([string]$phase){
  $out=RunDism ('PACKAGES_'+$phase) @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pending=@([regex]::Matches($out,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$'))
  $pendingXml=Join-Path $mount 'Windows\WinSxS\pending.xml'
  $pendingFile=Test-Path -LiteralPath $pendingXml
  Note ('PENDING_'+$phase+'_NATIVE='+$pending.Count+';PENDING_XML='+$pendingFile)
  if($pending.Count -ne 0 -or $pendingFile){throw ('BL_R6_PENDING_NOT_ZERO_'+$phase)}
 }
 $attempt=$false
 $mounted=$false
 $created=$false
 $committed=$false
 $result='HOLD_R6_NATIVE_CAPABILITY_DISPOSABLE'
 try{
  Note 'BLUELITE_S37_R6_NATIVE_EDGE_WEBVIEW_CAPABILITY_DISPOSABLE_TEST'
  Note 'ORIGINAL_R3_R4_R5R1_SHA_PINS=PASS'
  $origin=Get-Item -LiteralPath $src -Force -ErrorAction Stop
  if($origin.PSIsContainer -or $origin.Length -ne 6551362129L -or
     ($origin.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $srcHash){
   throw 'BL_R6_S37_PROTECTED_SOURCE_WIM_CHANGED'
  }
  Note ('S37_ORIGINAL_SHA256=PASS;'+$srcHash)
  $free=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('C_DRIVE_FREE_BYTES_BEFORE='+$free)
  if($free -lt 15GB){throw 'BL_R6_INSUFFICIENT_FREE_SPACE_15_GIB_REQUIRED'}
  ZeroMounts 'PRE'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_R6_PREEXISTING_BL_HIVE_ALIAS'
  }
  Note 'PRE_NO_MOUNTS_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($owned)
  $created=$true
  [IO.File]::Copy($src,$clone,$false)
  $copied=Get-Item -LiteralPath $clone -Force -ErrorAction Stop
  if($copied.Length -ne $origin.Length -or
     (Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash -cne $srcHash){
   throw 'BL_R6_CLONE_HASH_NOT_EQUAL_ORIGINAL'
  }
  Note ('OWNED_CLONE_PRE_SHA256=PASS;'+$srcHash)
  [void][IO.Directory]::CreateDirectory($mount)
  $attempt=$true
  $null=RunDism 'MOUNT_RW' @('/English','/Mount-Image',('/ImageFile:'+$clone),'/Index:1',('/MountDir:'+$mount))
  $mounted=$true
  Note 'OWNED_DISPOSABLE_NATIVE_RW_MOUNT=PASS'
  $preCap=GetCap
  Note ('CAPABILITY_BEFORE='+$cap+';STATE='+$preCap)
  if($preCap -cne 'Installed'){throw 'BL_R6_EXPECTED_INSTALLED_CAPABILITY_MISSING'}
  foreach($p in $fod){
   $state=GetPackage $p.PackageIdentity
   if($state -cne $p.DismPackageState){throw ('BL_R6_FOD_PRESTATE_DRIFT='+$p.PackageIdentity)}
   Note ('FOD_BEFORE='+$p.PackageIdentity+';STATE='+$state)
  }
  CheckParents 'PRE'
  PendingZero 'PRE'
  CheckHealth 'PRE' 'CheckHealth'
  Note 'AUTHORIZED_DISPOSABLE_NATIVE_REMOVE_CAPABILITY_BEGIN=Edge.Webview2.Platform~~~~'
  $removal=RunDism 'REMOVE_CAPABILITY' @('/English',('/Image:'+$mount),'/Remove-Capability',('/CapabilityName:'+$cap))
  Note 'DISM_REMOVE_CAPABILITY_EXIT=0;COMPLETED=PASS'
  $postCap=GetCap
  Note ('CAPABILITY_AFTER='+$cap+';STATE='+$postCap)
  if($postCap -cne 'Not Present'){throw 'BL_R6_CAPABILITY_POST_NOT_ABSENT'}
  foreach($p in $fod){
   $packageId=$p.PackageIdentity
   $raw=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$packageId) 2>&1|
    ForEach-Object {[string]$_})
   $packageCode=[int]$LASTEXITCODE
   $reason=($raw -join [Environment]::NewLine)
   Note ('FOD_AFTER='+$packageId+';DISM_EXIT='+$packageCode)
   if($packageCode -ne -2146498555 -or $reason -notmatch '(?i)0x800f0805'){
    foreach($line in $raw){Note ('FOD_AFTER_RAW='+$line)}
    throw ('BL_R6_FOD_PACKAGE_STILL_RESOLVING_OR_UNEXPECTED='+$packageId)
   }
  }
  Note 'THREE_EXACT_FOD_PACKAGE_IDENTITIES_NONRESOLVING=PASS'
  CheckParents 'POST'
  PendingZero 'POST'
  CheckHealth 'POST' 'CheckHealth'
  CheckHealth 'POST' 'ScanHealth'
  Note 'PRECOMMIT_NATIVE_CAPABILITY_PARENT_PENDING_SCANHEALTH=PASS'
  $null=RunDism 'COMMIT_OWNED_CLONE' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Commit')
  $mounted=$false
  $committed=$true
  Note 'OWNED_DISPOSABLE_NATIVE_COMMIT=PASS'
  ZeroMounts 'POST'
  $after=Get-Item -LiteralPath $clone -ErrorAction Stop
  Note ('DISPOSABLE_WIM_PRE_BYTES='+$origin.Length+';POST_BYTES='+$after.Length)
  Note ('DISPOSABLE_WIM_AFTER_SHA256='+(Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash)
  if((Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash -cne $srcHash){
   throw 'BL_R6_PROTECTED_S37_POST_HASH_CHANGED'
  }
  Note 'PROTECTED_S37_POST_SHA256=PASS'
  $result='PASS_S37_R6_NATIVE_WEBVIEW_DISPOSABLE_PRECOMMIT_POSTSTATE_AND_COMMIT_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($attempt -and -not $committed){
   try{
    $table=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $table.Contains($mount)){
     $null=RunDism 'DISCARD_FAILED_DISPOSABLE' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'FAILED_DISPOSABLE_MOUNT_DISCARDED=PASS'
     $mounted=$false
    }
    ZeroMounts 'POST_FAILURE'
   }catch{
    $result='HOLD_R6_DISPOSABLE_MOUNT_CLEANUP'
    Note ('CRITICAL_R6_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if(Test-Path -LiteralPath $mount){
     if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
      [IO.Directory]::Delete($mount,$false)
      Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
     }else{Note 'OWNED_NONEMPTY_MOUNT_DIR_RETAINED_FOR_REVIEW'}
    }
   }catch{
    $result='HOLD_R6_OWNED_MOUNT_DIR_CLEANUP'
    Note ('R6_DIR_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note ('DISPOSABLE_WIM='+$clone)
  Note 'S31_S37_PROTECTED;NO_HOST_OS_DEBLOAT;NO_RELEASE_CERTIFICATION'
 }
 if($result -ne 'PASS_S37_R6_NATIVE_WEBVIEW_DISPOSABLE_PRECOMMIT_POSTSTATE_AND_COMMIT_ONLY'){
  throw 'BL_S37_R6_DISPOSABLE_NATIVE_FOD_TEST_HOLD'
 }
}
