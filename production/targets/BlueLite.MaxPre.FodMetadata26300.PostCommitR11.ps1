# BlueLite S41/R11: independent read-only postcommit proof of R10 superseded FoDMetadata MAIN removal.
# No debloat, no CBS registry writes, no export, no commit, no change to any protected WIM.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R11_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R11_ADMIN_REQUIRED'}
 $logs='C:\work\logs'
 $receipt=Join-Path $logs 'BlueLite_MAXPRE_FodMetadata_26300.9711_Native_R10.txt'
 $report=Join-Path $logs 'BlueLite_MAXPRE_FodMetadata_26300.9711_PostCommit_R11.txt'
 $s41='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $s39='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $mount='C:\work\MWF26300R11'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $old='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~31bf3856ad364e35~amd64~~10.0.26100.1742'
 $new='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $core='Microsoft-Windows-FodMetadata-Package~31bf3856ad364e35~amd64~~10.0.26100.1'
 $rollup='Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.9711.1.30'
 $prefix='Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package-Wrapper~31bf3856ad364e35~amd64~~10.0.'
 $wrapOld=$prefix+'26100.1742'; $wrapNew=$prefix+'26100.9711'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_R11_LOG_DIR_MISSING'}
 if(Test-Path -LiteralPath $report){throw 'BL_R11_REPORT_NO_OVERWRITE'}
 if(Test-Path -LiteralPath $mount){throw 'BL_R11_MOUNT_NO_OVERWRITE'}
 $i=Get-Item -LiteralPath $receipt -Force -ErrorAction Stop
 if($i.PSIsContainer -or $i.Length -ne 2659 -or
    (Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -cne
    '3F42C3949AFBFE1F0C381ABCA7C0EEC8C18AB3A7A2B6B2FDAA90D2E57AA33D28'){
  throw 'BL_R11_R10_ORIGINAL_RECEIPT_PIN_MISMATCH'
 }
 $proof=[IO.File]::ReadAllText($receipt)
 foreach($key in @(
  'RESULT=PASS_S41_R10_FODMETADATA_NATIVE_SUPERSEDED_MAIN_REMOVE_COMMIT_ONLY',
  'OWNED_S41_NATIVE_COMMIT=PASS',
  'TARGET_OLD_MAIN_POST=NONRESOLVING',
  'WRAPPERS_PRE_POST_EXACT_STATES_PRESERVED=PASS',
  'CBS_ScanHealth_POST=CLEAN',
  'MOUNTS_POST_EXIT=0;EMPTY=1;ROWS=0'
 )){if(-not $proof.Contains($key)){throw ('BL_R11_R10_RECEIPT_CONTRACT_DRIFT='+$key)}}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$s){Write-Host $s;[IO.File]::AppendAllText($report,$s+[Environment]::NewLine,$utf8)}
 function Pin([string]$path,[long]$size,[string]$sha,[string]$label){
  $f=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne $size -or
   ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
   (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -cne $sha){throw ('BL_R11_SOURCE_PIN_DRIFT_'+$label)}
  Note ('PIN_'+$label+'=PASS;BYTES='+$size+';SHA='+$sha)
 }
 function Native([string]$tag,[string[]]$argv){
  $rows=@(& $dism @argv 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE; $body=$rows -join [Environment]::NewLine
  if($ec -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($row in $rows){Note ('DISM_'+$tag+'_RAW='+$row)}
   throw ('BL_R11_NATIVE_'+$tag+'_EXIT='+$ec)
  }
  return $body
 }
 function ZeroMounts([string]$stage){
  $rows=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $empty=@($rows|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $found=@($rows|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$stage+'_EXIT='+$ec+';EMPTY='+$empty+';ROWS='+$found)
  if($ec -ne 0 -or $empty -ne 1 -or $found -ne 0){throw ('BL_R11_MOUNT_TABLE_NOT_ZERO_'+$stage)}
 }
 function QueryExact([string]$id,[bool]$allowAbsent){
  $rows=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$id) 2>&1 |
   ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE; $body=$rows -join [Environment]::NewLine
  if($allowAbsent -and $ec -eq -2146498555 -and $body -match '(?i)0x800f0805'){
   return 'NONRESOLVING'
  }
  if($ec -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($row in $rows){Note ('PACKAGE_RAW='+$row)}
   throw ('BL_R11_PACKAGE_NATIVE_ERROR='+$ec+';'+$id)
  }
  $im=[regex]::Match($body,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $st=[regex]::Match($body,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $im.Success -or $im.Groups[1].Value.Trim() -cne $id -or -not $st.Success){
   throw ('BL_R11_PACKAGE_ID_STATE_DRIFT='+$id)
  }
  return $st.Groups[1].Value.Trim()
 }
 $mounted=$false; $mountCreated=$false; $passed=$false
 $result='HOLD_R11_POSTCOMMIT_READONLY'
 try{
  Note 'BLUELITE_S41_R11_INDEPENDENT_FODMETADATA_POSTCOMMIT_READONLY'
  Note 'R10_OPERATOR_ORIGINAL_SHA_AND_RECEIPT=PASS'
  Pin $s41 6636510185L '378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1' 'S41_COMMITTED'
  Pin $s39 6595075169L '32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED' 'S39_PROTECTED'
  Pin $s37 6551362129L 'A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F' 'S37_PROTECTED'
  ZeroMounts 'PRE'
  $h=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
    @($h|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_R11_PROJECT_OFFLINE_HIVE_PRESENT'
  }
  Note 'PRE_NO_PROJECT_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount); $mountCreated=$true
  $null=Native 'MOUNT_READONLY' @('/English','/Mount-Image',('/ImageFile:'+$s41),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true; Note 'S41_READONLY_MOUNT=PASS'
  $expected=[ordered]@{}
  $expected[$old]='NONRESOLVING'; $expected[$new]='Installed'; $expected[$core]='Installed'
  $expected[$rollup]='Installed'; $expected[$wrapOld]='Staged'; $expected[$wrapNew]='Installed'
  foreach($id in $expected.Keys){
   $state=QueryExact $id ($id -ceq $old)
   Note ('PACKAGE='+$id+';STATE='+$state+';EXPECTED='+$expected[$id])
   if($state -cne $expected[$id]){throw ('BL_R11_EXACT_POSTSTATE_MISMATCH='+$id)}
  }
  Note 'EXACT_SIX_POSTCOMMIT_PACKAGES=PASS'
  $pk=Native 'PENDING' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pending=@([regex]::Matches($pk,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$'))
  $px=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING='+$pending.Count+';PENDING_XML='+$px)
  if($pending.Count -ne 0 -or $px){throw 'BL_R11_PENDING_SERVICING'}
  $health=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R11_CBS_CHECKHEALTH_NOT_CLEAN'}
  Note 'CBS_CheckHealth=CLEAN'
  $null=Native 'CAPABILITY_PROVIDER' @('/English',('/Image:'+$mount),'/Get-Capabilities','/Format:Table')
  Note 'CAPABILITY_PROVIDER_NATIVE_EXIT0=PASS'
  $passed=$true
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  if(-not $mounted -and $mountCreated){
   try{
    $observed=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if([int]$LASTEXITCODE -eq 0 -and $observed.Contains($mount)){$mounted=$true;Note 'RECOVER_OWNED_MOUNT_IN_TABLE=TRUE'}
   }catch{Note ('MOUNT_TABLE_RECOVERY_HOLD='+$_.Exception.Message)}
  }
  if($mounted){
   try{
    $null=Native 'DISCARD_READONLY' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
    $mounted=$false; Note 'S41_READONLY_DISCARD=PASS'
   }catch{$passed=$false;Note ('CRITICAL_DISCARD_FAILURE='+$_.Exception.Message)}
  }
  try{ZeroMounts 'POST'}catch{$passed=$false;Note ('CRITICAL_MOUNTS='+$_.Exception.Message)}
  if($mountCreated -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false); Note 'EMPTY_READONLY_MOUNT_REMOVED=PASS'
    }else{$passed=$false;Note 'HOLD_READONLY_MOUNT_NONEMPTY'}
   }catch{$passed=$false;Note ('MOUNT_DIRECTORY_HOLD='+$_.Exception.Message)}
  }
  try{
   Pin $s41 6636510185L '378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1' 'S41_POST'
   Pin $s39 6595075169L '32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED' 'S39_POST'
   Pin $s37 6551362129L 'A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F' 'S37_POST'
  }catch{$passed=$false;Note ('POST_SOURCE_SHA_HOLD='+$_.Exception.Message)}
  if($passed -and -not $mounted){$result='PASS_S41_R11_INDEPENDENT_FODMETADATA_POSTCOMMIT_READONLY_ONLY'}
  Note ('RESULT='+$result)
  Note ('REPORT='+$report)
  Note 'READONLY_NO_IMAGE_MUTATION_NO_EXPORT_NO_RELEASE_CERTIFICATION'
 }
 if($result -ne 'PASS_S41_R11_INDEPENDENT_FODMETADATA_POSTCOMMIT_READONLY_ONLY'){
  throw 'BL_R11_INDEPENDENT_POSTCOMMIT_HOLD'
 }
}
