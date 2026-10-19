# BlueLite 26300 FoDMetadata R10: ONE superseded MAIN native removal, OWNED S41 disposable ONLY.
# Basis: original 26300 R9 + 26200 Library 162 and 339-R1; wrappers, core, current MAIN KEEP.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $source='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $sourceSha='32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED'
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $s37Sha='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $owned='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10'
 $clone=Join-Path $owned 'install.fodmetadata-disposable.wim'
 $mount=Join-Path $owned 'mount'
 $report=Join-Path $root 'BlueLite_MAXPRE_FodMetadata_26300.9711_Native_R10.txt'
 $r9=Join-Path $root 'BlueLite_MAXPRE_FodMetadata_26300.9711_ReadOnly_R9.txt'
 $old='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~31bf3856ad364e35~amd64~~10.0.26100.1742'
 $new='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $core='Microsoft-Windows-FodMetadata-Package~31bf3856ad364e35~amd64~~10.0.26100.1'
 $wrapperPrefix='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package-Wrapper~31bf3856ad364e35~amd64~~10.0.'
 $wrappers=@(($wrapperPrefix+'26100.1742'),($wrapperPrefix+'26100.9711'))
 $rollup='Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.9711.1.30'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_R10_LOGS_DIR_MISSING'}
 foreach($path in @($owned,$report)){if(Test-Path -LiteralPath $path){throw ('BL_R10_NO_OVERWRITE='+$path)}}
 $logItem=Get-Item -LiteralPath $r9 -Force -ErrorAction Stop
 if($logItem.PSIsContainer -or $logItem.Length -ne 1504 -or
    (Get-FileHash -LiteralPath $r9 -Algorithm SHA256).Hash -cne
    '7996B6BC49611645B3E79C87E0FC8D063BBE805CC42565067A7FE7436D19D727'){
  throw 'BL_R10_R9_ORIGINAL_OPERATOR_EVIDENCE_SHA_DRIFT'
 }
 $r9Proof=[IO.File]::ReadAllText($r9)
 foreach($needed in @(
  'RESULT=PASS_S39_R9_FODMETADATA_EXACT_NATIVE_READONLY_CLASSIFICATION_ONLY',
  ('FODMETADATA=MAIN;PACKAGE='+$old+';NATIVE_PACKAGE_STATE=Superseded'),
  ('FODMETADATA=MAIN;PACKAGE='+$new+';NATIVE_PACKAGE_STATE=Installed'),
  ('FODMETADATA=CORE;PACKAGE='+$core+';NATIVE_PACKAGE_STATE=Installed'),
  'FODMETADATA_MAIN_SUPERSEDED_COUNT=1',
  'NATIVE_CHECKHEALTH=CLEAN'
 )){
  if(-not $r9Proof.Contains($needed)){throw ('BL_R10_R9_PROOF_NOT_FOUND='+$needed)}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$line){
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$path,[long]$size,[string]$sha,[string]$label){
  $it=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if($it.PSIsContainer -or $it.Length -ne $size -or
     ($it.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha){
   throw ('BL_R10_PIN_FAILED_'+$label)
  }
  Note ('PIN_'+$label+'=PASS;BYTES='+$size+';SHA='+$sha)
 }
 function Native([string]$tag,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $output=$lines -join [Environment]::NewLine
  if($ec -ne 0 -or $output -match '(?im)^\s*Error\s*:' -or
     $output -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$tag+'_RAW='+$line)}
   throw ('BL_R10_DISM_'+$tag+'_FAILED_EXIT='+$ec)
  }
  return $output
 }
 function ZeroMounts([string]$step){
  $rows=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $empty=@($rows|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $mountedRows=@($rows|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$step+'_EXIT='+$ec+';EMPTY='+$empty+';ROWS='+$mountedRows)
  if($ec -ne 0 -or $empty -ne 1 -or $mountedRows -ne 0){
   throw ('BL_R10_MOUNT_TABLE_NOT_ZERO_'+$step)
  }
 }
 function QueryExact([string]$identity,[bool]$allowMissing){
  $lines=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$identity) 2>&1|
   ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $text=$lines -join [Environment]::NewLine
  if($allowMissing -and $code -eq -2146498555 -and $text -match '(?i)0x800f0805'){
   return 'NONRESOLVING'
  }
  if($code -ne 0 -or $text -match '(?im)^\s*Error\s*:' -or
     $text -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('PACKAGE_NATIVE_RAW='+$line)}
   throw ('BL_R10_PACKAGE_LOOKUP_UNEXPECTED_EXIT='+$code+';'+$identity)
  }
  $match=[regex]::Match($text,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $state=[regex]::Match($text,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $match.Success -or $match.Groups[1].Value.Trim() -cne $identity -or
     -not $state.Success){throw ('BL_R10_NATIVE_ID_OR_STATE_DRIFT='+$identity)}
  return $state.Groups[1].Value.Trim()
 }
 function CheckProtectedFloor([string]$stage){
  $cur=QueryExact $new $false
  $central=QueryExact $core $false
  $ru=QueryExact $rollup $false
  Note ('KEEP_'+$stage+'_CURRENT_MAIN='+$cur)
  Note ('KEEP_'+$stage+'_CORE='+$central)
  Note ('KEEP_'+$stage+'_ROLLUPFIX='+$ru)
  if($cur -cne 'Installed' -or $central -cne 'Installed' -or $ru -cne 'Installed'){
   throw ('BL_R10_CURRENT_MAIN_CORE_OR_ROLLUP_DRIFT_'+$stage)
  }
 }
 function PendingZero([string]$stage){
  $pk=Native ('PENDING_'+$stage) @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pending=@([regex]::Matches($pk,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$'))
  $pendingXml=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING_'+$stage+'='+$pending.Count+';PENDING_XML='+$pendingXml)
  if($pending.Count -ne 0 -or $pendingXml){throw ('BL_R10_PENDING_'+$stage)}
 }
 function Health([string]$stage,[string]$kind){
  $details=Native ($kind+'_'+$stage) @('/English',('/Image:'+$mount),'/Cleanup-Image',('/'+$kind))
  if($details -notmatch '(?i)No component store corruption detected\.'){
   throw ('BL_R10_CBS_'+$kind+'_'+$stage+'_NOT_CLEAN')
  }
  Note ('CBS_'+$kind+'_'+$stage+'=CLEAN')
 }
 $attempt=$false;$mounted=$false;$created=$false;$committed=$false
 $result='HOLD_S41_R10_FODMETADATA_SUPERSEDED_NATIVE'
 try{
  Note 'BLUELITE_S41_R10_FODMETADATA_ONE_SUPERSEDED_MAIN_NATIVE_REMOVAL'
  Note 'R9_ORIGINAL_SHA_STATE_PINS=PASS'
  Pin $source 6595075169L $sourceSha 'S39_PROTECTED'
  Pin $s37 6551362129L $s37Sha 'S37_PROTECTED'
  $free=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('FREE_C_PRE_BYTES='+$free)
  if($free -lt 16GB){throw 'BL_R10_MIN_FREE_16_GIB'}
  ZeroMounts 'PRE'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_R10_PROJECT_HIVE_PRESENT'
  }
  Note 'PRE_NO_PROJECT_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($owned)
  $created=$true
  [IO.File]::Copy($source,$clone,$false)
  Pin $clone 6595075169L $sourceSha 'S41_OWNED_CLONE_PRE'
  [void][IO.Directory]::CreateDirectory($mount)
  $attempt=$true
  $null=Native 'MOUNT_RW' @('/English','/Mount-Image',('/ImageFile:'+$clone),'/Index:1',('/MountDir:'+$mount))
  $mounted=$true
  Note 'OWNED_S41_RW_MOUNT=PASS'
  $oldState=QueryExact $old $false
  Note ('TARGET_OLD_MAIN_PRE='+$oldState)
  if($oldState -cne 'Superseded'){throw 'BL_R10_TARGET_NOT_EXACT_SUPERSEDED'}
  CheckProtectedFloor 'PRE'
  $wrapperStates=[ordered]@{}
  foreach($id in $wrappers){
   $state=QueryExact $id $true
   $wrapperStates[$id]=$state
   Note ('WRAPPER_PRE='+$id+';STATE='+$state)
  }
  PendingZero 'PRE'
  Health 'PRE' 'CheckHealth'
  Note ('NATIVE_EXACT_REMOVE_START='+$old)
  $null=Native 'REMOVE_OLD_SUPERSEDED_MAIN' @('/English',('/Image:'+$mount),'/Remove-Package',('/PackageName:'+$old))
  Note 'NATIVE_REMOVE_SUPERSEDED_MAIN_EXIT=0;COMPLETED=PASS'
  $oldAfter=QueryExact $old $true
  Note ('TARGET_OLD_MAIN_POST='+$oldAfter)
  if($oldAfter -cne 'NONRESOLVING'){throw 'BL_R10_SUPERSEDED_MAIN_STILL_REGISTERED'}
  CheckProtectedFloor 'POST'
  foreach($id in $wrappers){
   $state=QueryExact $id $true
   Note ('WRAPPER_POST='+$id+';STATE='+$state+';PRE='+$wrapperStates[$id])
   if($state -cne $wrapperStates[$id]){
    throw ('BL_R10_WRAPPER_STATE_CHANGED='+$id)
   }
  }
  Note 'WRAPPERS_PRE_POST_EXACT_STATES_PRESERVED=PASS'
  PendingZero 'POST'
  Health 'POST' 'CheckHealth'
  Health 'POST' 'ScanHealth'
  Note 'PRECOMMIT_TARGET_ABSENT_CURRENT_CORE_ROLLUPFIX_WRAPPERS_PRESERVED_PENDING0_HEALTH_CLEAN=PASS'
  $null=Native 'COMMIT_OWNED_S41' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Commit')
  $mounted=$false;$committed=$true
  Note 'OWNED_S41_NATIVE_COMMIT=PASS'
  ZeroMounts 'POST'
  $f=Get-Item -LiteralPath $clone -ErrorAction Stop
  Note ('OWNED_S41_POST_WIM_BYTES='+$f.Length)
  Note ('OWNED_S41_POST_WIM_SHA256='+(Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash)
  Pin $source 6595075169L $sourceSha 'S39_POST'
  Pin $s37 6551362129L $s37Sha 'S37_POST'
  $result='PASS_S41_R10_FODMETADATA_NATIVE_SUPERSEDED_MAIN_REMOVE_COMMIT_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($attempt -and -not $committed){
   try{
    $mountTable=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $mountTable.Contains($mount)){
     $null=Native 'DISCARD_OWNED_S41' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'FAILED_S41_OWNED_MOUNT_DISCARDED=PASS'
     $mounted=$false
    }
    ZeroMounts 'AFTER_HOLD'
   }catch{
    $result='HOLD_R10_OWNED_DISCARD_CLEANUP'
    Note ('CRITICAL_OWNED_DISCARD_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if(Test-Path -LiteralPath $mount){
     if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
      [IO.Directory]::Delete($mount,$false)
      Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
     }else{$result='HOLD_R10_OWNED_MOUNT_NONEMPTY';Note 'OWNED_MOUNT_NONEMPTY'}
    }
   }catch{
    $result='HOLD_R10_MOUNT_DIRECTORY_CLEANUP'
    Note ('MOUNT_DIR_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$report)
  Note ('OWNED_DISPOSABLE_S41_WIM='+$clone)
  Note 'PROTECTED_S31_S37_S39_S40_UNCHANGED;NO_RELEASE_OR_PHYSICAL_SAVINGS_CERTIFICATION'
 }
 if($result -ne 'PASS_S41_R10_FODMETADATA_NATIVE_SUPERSEDED_MAIN_REMOVE_COMMIT_ONLY'){
  throw 'BL_R10_FODMETADATA_OWNED_NATIVE_TEST_HOLD'
 }
}
