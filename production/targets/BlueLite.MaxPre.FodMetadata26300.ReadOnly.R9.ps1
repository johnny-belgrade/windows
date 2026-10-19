# BlueLite R9 - bounded FoDMetadata CBS family native read-only classification on committed S39.
# Regression: Library 162/174/339. NO package removal or protected image mutation.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $u=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $u.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $r8=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_ExportCompare_R8.txt'
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $s39='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $s37sha='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $s39sha='32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED'
 $mount='C:\work\MWV26300R9'
 $log=Join-Path $root 'BlueLite_MAXPRE_FodMetadata_26300.9711_ReadOnly_R9.txt'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_R9_LOG_ROOT_MISSING'}
 foreach($p in @($mount,$log)){if(Test-Path -LiteralPath $p){throw ('BL_R9_OWNED_PATH_EXISTS='+$p)}}
 $e=Get-Item -LiteralPath $r8 -Force -ErrorAction Stop
 if($e.PSIsContainer -or $e.Length -ne 1640 -or
    (Get-FileHash -LiteralPath $r8 -Algorithm SHA256).Hash -cne
    '426E004E351F5EAE2654B858756201CAB75D6A87A99A981F19E72E6B7BD73A1F'){
  throw 'BL_R9_OPERATOR_R8_EVIDENCE_PIN_MISMATCH'
 }
 $r8proof=[IO.File]::ReadAllText($r8)
 foreach($line in @(
  'RESULT=PASS_R8_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY',
  'EQUAL_MAX_EXPORT_DELTA_S37_MINUS_S39_BYTES=603556113',
  'TWO_SOURCE_WIMS_UNCHANGED=PASS'
 )){
  if(-not $r8proof.Contains($line)){throw 'BL_R9_R8_RESULT_REQUIRED'}
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$line){
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$path,[long]$bytes,[string]$hash,[string]$label){
  $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if($item.PSIsContainer -or $item.Length -ne $bytes -or
     ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $hash){
   throw ('BL_R9_SOURCE_PIN_DRIFT_'+$label)
  }
  Note ('SOURCE_'+$label+'_FULL_SHA_SIZE=PASS')
 }
 function DismOK([string]$label,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $text=$lines -join [Environment]::NewLine
  if($code -ne 0 -or $text -match '(?im)^\s*Error\s*:' -or
     $text -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$label+'_RAW='+$line)}
   throw ('BL_R9_DISM_'+$label+'_EXIT='+$code)
  }
  return $text
 }
 function ZeroMounts([string]$step){
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $empty=@($lines|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $present=@($lines|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('DISM_'+$step+'_EXIT='+$code+';EMPTY='+$empty+';LISTED='+$present)
  if($code -ne 0 -or $empty -ne 1 -or $present -ne 0){
   throw ('BL_R9_MOUNT_TABLE_NOT_ZERO_'+$step)
  }
 }
 $attempt=$false;$mounted=$false;$created=$false
 $result='HOLD_R9_FODMETADATA_READONLY'
 try{
  Note 'BLUELITE_S39_R9_FODMETADATA_NARROW_NATIVE_READONLY_CLASSIFICATION'
  Note 'ORIGINAL_R8_SHA_SIZE_AND_RESULT=PASS'
  Pin $s37 6551362129L $s37sha 'PROTECTED_S37'
  Pin $s39 6595075169L $s39sha 'COMMITTED_S39'
  ZeroMounts 'MOUNT_PRE'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|
   ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
    @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
    throw 'BL_R9_PROJECT_HIVE_ALIAS_PRESENT'
  }
  Note 'PRE_NO_PROJECT_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true;$attempt=$true
  $null=DismOK 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$s39),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'NATIVE_S39_RO_MOUNT=PASS'
  $list=DismOK 'GET_PACKAGES' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $found=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  foreach($match in [regex]::Matches($list,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')){
   $id=$match.Groups[1].Value.Trim()
   if($id -match '^(Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package(?:-Wrapper)?|Microsoft-Windows-FodMetadata-Package)~'){
    [void]$found.Add($id)
   }
  }
  Note ('FODMETADATA_FAMILY_MATCHING_NATIVE_PACKAGE_IDENTITIES='+$found.Count)
  if($found.Count -gt 16){throw 'BL_R9_FODMETADATA_FAMILY_TOO_MANY_ENTRIES'}
  $superseded=0;$installed=0;$staged=0
  foreach($id in @($found|Sort-Object)){
   $details=DismOK 'EXACT_PACKAGE_INFO' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$id))
   $nameMatch=[regex]::Match($details,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
   $stateMatch=[regex]::Match($details,'(?im)^\s*State\s*:\s*(\S+(?:\s+\S+)?)\s*$')
   if(-not $nameMatch.Success -or $nameMatch.Groups[1].Value.Trim() -cne $id -or
      -not $stateMatch.Success){throw ('BL_R9_EXACT_PACKAGE_INFO_UNRESOLVED='+$id)}
   $state=$stateMatch.Groups[1].Value.Trim()
   $family=if($id -match '^Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package-Wrapper~'){'WRAPPER'}
    elseif($id -match '^Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~'){'MAIN'}
    else{'CORE'}
   Note ('FODMETADATA='+$family+';PACKAGE='+$id+';NATIVE_PACKAGE_STATE='+$state)
   if($family -eq 'MAIN' -and $state -eq 'Superseded'){$superseded++}
   if($family -eq 'MAIN' -and $state -eq 'Installed'){$installed++}
   if($family -eq 'MAIN' -and $state -eq 'Staged'){$staged++}
  }
  Note ('FODMETADATA_MAIN_SUPERSEDED_COUNT='+$superseded)
  Note ('FODMETADATA_MAIN_INSTALLED_COUNT='+$installed)
  Note ('FODMETADATA_MAIN_STAGED_COUNT='+$staged)
  Note 'FOCUS_NEXT=ONLY_NATIVE_SUPERSEDED_MAIN_IF_PRESENT;WRAPPERS_AND_CORE_KEEP_PENDING_SEPARATE_OWNER_PROOF'
  $health=DismOK 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R9_CHECKHEALTH_NOT_CLEAN'}
  Note 'NATIVE_CHECKHEALTH=CLEAN'
  Note 'NO_WIM_CLONE_NO_MUTATION_NO_REMOVE_PACKAGE_NO_CBS_HIVE_CHANGE'
  $result='PASS_S39_R9_FODMETADATA_EXACT_NATIVE_READONLY_CLASSIFICATION_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($attempt){
   try{
    $status=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $status.Contains($mount)){
     $null=DismOK 'RO_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'NATIVE_S39_RO_DISCARD=PASS'
    }
    ZeroMounts 'MOUNT_POST'
    $mounted=$false
   }catch{
    $mounted=$true;$result='HOLD_R9_RO_DISCARD_OR_MOUNTS'
    Note ('CRITICAL_DISCARD_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_RO_MOUNT_DIR_REMOVED=PASS'
    }else{$result='HOLD_R9_OWNED_MOUNT_NONEMPTY';Note 'OWNED_MOUNT_NONEMPTY'}
   }catch{
    $result='HOLD_R9_MOUNT_DIR_CLEANUP'
    Note ('RO_MOUNT_DIR_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if(-not $mounted){
   try{Pin $s37 6551362129L $s37sha 'PROTECTED_S37_POST';Pin $s39 6595075169L $s39sha 'COMMITTED_S39_POST'}
   catch{$result='HOLD_R9_PROTECTED_OR_S39_FULL_HASH';Note ('SOURCE_POST_HASH_HOLD='+$_.Exception.Message)}
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note 'S31_S37_S39_AND_S40_EXPORTS_PRESERVED;NO_RELEASE_CERTIFICATION'
 }
 if($result -ne 'PASS_S39_R9_FODMETADATA_EXACT_NATIVE_READONLY_CLASSIFICATION_ONLY'){
  throw 'BL_R9_FODMETADATA_CLASSIFICATION_HOLD'
 }
}
