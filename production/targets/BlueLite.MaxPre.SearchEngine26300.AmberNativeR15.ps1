# BlueLite S43/R15: one exact 26300 SearchEngine-Client AMBER target-only experiment.
# Only S41 whole-hash-pinned source cloned to NEW owned S43 RW WIM. NEVER mutate S41.
# Based on 26200 Library 131/346/347 and actual 26300 R14R1/R14R2 exact native/CBS.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R15_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R15_ADMIN_REQUIRED'}
 $logs='C:\work\logs'
 $evidence=Join-Path $logs 'BlueLite_MAXPRE_SearchEngine_26300.9711_NativeExact_R14R2.txt'
 $report=Join-Path $logs 'BlueLite_MAXPRE_SearchEngine_26300.9711_NativeAmber_R15.txt'
 $source='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $sourceSha='378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1'
 $owned='C:\work\E2E\BlueLite_Stage1_S43_26300.9711_SearchEngine_AMBER_R15'
 $clone=Join-Path $owned 'install.search-disposable.wim'
 $mount=Join-Path $owned 'mount'
 $backup=Join-Path $owned 'SOFTWARE.pre-amber.copy.hiv'
 $target='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $old='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1591'
 $parent='Microsoft-Windows-Client-Desktop-Required-Package04~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $oldParent='Microsoft-Windows-Client-Desktop-Required-Package04~31bf3856ad364e35~amd64~~10.0.26100.1742'
 $rollup='Package_for_RollupFix~31bf3856ad364e35~amd64~~26100.9711.1.30'
 $alias='BLR15SOFT'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_R15_LOG_DIR_MISSING'}
 foreach($p in @($owned,$report)){if(Test-Path -LiteralPath $p){throw ('BL_R15_NO_OVERWRITE='+$p)}}
 $ev=Get-Item -LiteralPath $evidence -Force -ErrorAction Stop
 if($ev.PSIsContainer -or $ev.Length -ne 2652 -or
    (Get-FileHash -LiteralPath $evidence -Algorithm SHA256).Hash -cne
    '40EC240558E8FECE65C11B69EBF67A25C5AF5FAB118BAC534BCBD9715585433A'){
  throw 'BL_R15_R14R2_ORIGINAL_EVIDENCE_PIN_DRIFT'
 }
 $proof=[IO.File]::ReadAllText($evidence)
 foreach($tag in @(
  'RESULT=PASS_S41_R14R2_EPHEMERAL_HIVE_RETIRE_AND_NATIVE_EXACT_READONLY_ONLY',
  ('NATIVE_EXACT_OLD_1591=Staged;ID='+$old),
  ('NATIVE_EXACT_CURRENT_9711=Installed;ID='+$target),
  'NATIVE_EXACT_PAIR=PASS;OLD=Staged;CURRENT=Installed',
  'R14R1_EPHEMERAL_FOLDER_REMOVED=PASS',
  'CBS_CHECKHEALTH=CLEAN',
  'MOUNTS_POST_EXIT=0;EMPTY=1;ROWS=0',
  'PROJECT_HIVES_POST_EXIT=0;MATCHES=0'
 )){if(-not $proof.Contains($tag)){throw ('BL_R15_R14R2_PROOF_MISSING='+$tag)}}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$s){Write-Host $s;[IO.File]::AppendAllText($report,$s+[Environment]::NewLine,$utf8)}
 function Pin([string]$f,[long]$length,[string]$sha,[string]$label){
  $x=Get-Item -LiteralPath $f -Force -ErrorAction Stop
  if($x.PSIsContainer -or ($x.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     $x.Length -ne $length -or (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -cne $sha){
   throw ('BL_R15_PIN_FAIL_'+$label)
  }
  Note ('PIN_'+$label+'=PASS;BYTES='+$length+';SHA='+$sha)
 }
 function Native([string]$label,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $txt=$lines -join [Environment]::NewLine
  if($ec -ne 0 -or $txt -match '(?im)^\s*Error\s*:' -or
     $txt -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$label+'_RAW='+$line)}
   throw ('BL_R15_NATIVE_'+$label+'_EXIT='+$ec)
  }
  return $txt
 }
 function ZeroMounts([string]$stage){
  $rows=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $empty=@($rows|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $count=@($rows|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$stage+'_EXIT='+$ec+';EMPTY='+$empty+';ROWS='+$count)
  if($ec -ne 0 -or $empty -ne 1 -or $count -ne 0){throw ('BL_R15_MOUNT_NOT_ZERO_'+$stage)}
 }
 function ZeroHives([string]$stage){
  $rows=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $count=@($rows|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(?:BL[0-9]|BLR|BLWEB|BlueLite|FB[0-9])'}).Count
  Note ('HIVES_'+$stage+'_EXIT='+$ec+';COUNT='+$count)
  if($ec -ne 0 -or $count -ne 0){throw ('BL_R15_OFFLINE_HIVE_LEFTOVER_'+$stage)}
 }
 function Exact([string]$id,[bool]$allowAbsent){
  $rows=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$id) 2>&1|
   ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $out=$rows -join [Environment]::NewLine
  if($allowAbsent -and $ec -eq -2146498555 -and $out -match '(?i)0x800f0805'){
   return 'NONRESOLVING'
  }
  if($ec -ne 0 -or $out -match '(?im)^\s*Error\s*:' -or
     $out -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $rows){Note ('PACKAGE_NATIVE_RAW='+$line)}
   throw ('BL_R15_PACKAGE_NATIVE_ERROR='+$ec+';'+$id)
  }
  $m=[regex]::Match($out,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $state=[regex]::Match($out,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $id -or -not $state.Success){
   throw ('BL_R15_EXACT_PACKAGE_ID_STATE_MISMATCH='+$id)
  }
  return $state.Groups[1].Value.Trim()
 }
 function Pending([string]$stage){
  $out=Native ('PENDING_'+$stage) @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $count=@([regex]::Matches($out,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$')).Count
  $pendingXml=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING_'+$stage+'='+$count+';PENDING_XML='+$pendingXml)
  if($count -ne 0 -or $pendingXml){throw ('BL_R15_PENDING_'+$stage)}
 }
 function Health([string]$stage,[string]$kind){
  $x=Native ($kind+'_'+$stage) @('/English',('/Image:'+$mount),'/Cleanup-Image',('/'+$kind))
  if($x -notmatch '(?i)No component store corruption detected\.'){
   throw ('BL_R15_HEALTH_'+$kind+'_'+$stage)
  }
  Note ('CBS_'+$kind+'_'+$stage+'=CLEAN')
 }
 function StateFloor([string]$stage){
  foreach($p in @(
   @{N=$old;Expect='Staged';Label='OLD_SEARCH_STAGED'},
   @{N=$parent;Expect='Installed';Label='REQUIRED_PARENT04'},
   @{N=$rollup;Expect='Installed';Label='ROLLUPFIX'}
  )){
   $state=Exact $p.N $false
   Note ('FLOOR_'+$stage+'_'+$p.Label+'='+$state)
   if($state -cne $p.Expect){throw ('BL_R15_FLOOR_'+$stage+'_'+$p.Label+'_DRIFT')}
  }
 }
 function RegCall([string]$label,[string[]]$argv){
  $rows=@(& $reg @argv 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  if($ec -ne 0){
   foreach($row in $rows){Note ('REG_'+$label+'_RAW='+$row)}
   throw ('BL_R15_REG_'+$label+'_EXIT='+$ec)
  }
  Note ('REG_'+$label+'=PASS')
 }
 $created=$false;$mounted=$false;$load=$false;$mountedAttempt=$false;$committed=$false
 $status='HOLD_R15_S43_SEARCH_AMBER_NATIVE'
 $critical=$false
 try{
  Note 'BLUELITE_S43_R15_SEARCHENGINE_EXACT_AMBER_OWNED_DISPOSABLE'
  Note 'R14R2_ORIGINAL_NATIVE_AND_SOURCE_GATES=PASS'
  Pin $source 6636510185L $sourceSha 'S41_ORIGINAL_PRE'
  $free=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('FREE_C_PRE_BYTES='+$free)
  if($free -lt 20GB){throw 'BL_R15_MIN_FREE_20_GIB'}
  ZeroMounts 'PRE'
  ZeroHives 'PRE'
  [void][IO.Directory]::CreateDirectory($owned);$created=$true
  [IO.File]::Copy($source,$clone,$false)
  Pin $clone 6636510185L $sourceSha 'S43_CLONE_PRE'
  [void][IO.Directory]::CreateDirectory($mount)
  $mountedAttempt=$true
  $null=Native 'MOUNT_RW' @('/English','/Mount-Image',('/ImageFile:'+$clone),'/Index:1',('/MountDir:'+$mount))
  $mounted=$true
  Note 'S43_OWNED_RW_MOUNT=PASS'
  if((Exact $target $false) -cne 'Installed'){throw 'BL_R15_TARGET_NOT_NATIVE_INSTALLED'}
  Note 'TARGET_CURRENT_PRE=Installed'
  StateFloor 'PRE'
  Pending 'PRE'
  Health 'PRE' 'CheckHealth'
  Note 'STEP_01_PRE_AMBER_BACKUP_AND_CBS_EXACT_OWNER_UPDATES_GATE'
  $hive=Join-Path $mount 'Windows\System32\Config\SOFTWARE'
  [IO.File]::Copy($hive,$backup,$false)
  $a=Get-Item -LiteralPath $hive -ErrorAction Stop
  $b=Get-Item -LiteralPath $backup -ErrorAction Stop
  if($a.Length -ne $b.Length -or
     (Get-FileHash -LiteralPath $hive -Algorithm SHA256).Hash -cne
     (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash){
   throw 'BL_R15_SOFTWARE_BACKUP_COPY_PIN_MISMATCH'
  }
  Note ('OWNED_SOFTWARE_BACKUP_SHA=PASS;BYTES='+$b.Length)
  RegCall 'LOAD_OWNED_S43_SOFTWARE' @('load',('HKLM\'+$alias),$hive)
  $load=$true
  $root=$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  $targetKey=$root+'\'+$target
  $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($targetKey,$false)
  if($null -eq $key){throw 'BL_R15_TARGET_CBS_KEY_MISSING'}
  try{
   $state=$key.GetValue('CurrentState',$null);$vis=$key.GetValue('Visibility',$null)
   $stateKind=$key.GetValueKind('CurrentState').ToString()
   $visKind=$key.GetValueKind('Visibility').ToString()
   if($null -eq $state -or $null -eq $vis -or $stateKind -cne 'DWord' -or
      $visKind -cne 'DWord' -or [uint32]$state -ne 0x70 -or [uint32]$vis -ne 0x2){
    throw 'BL_R15_TARGET_CBS_STATE_VIS_MISMATCH'
   }
   Note 'TARGET_CBS_PRE=STATE_0x70;VISIBILITY_0x2'
   $owners=$key.OpenSubKey('Owners',$false)
   if($null -eq $owners){throw 'BL_R15_OWNER_KEY_MISSING'}
   try{
    $names=@($owners.GetValueNames())
    if($names.Count -ne 1 -or $names[0] -cne $parent -or
       $owners.GetValueKind($parent).ToString() -cne 'DWord' -or
       [uint32]$owners.GetValue($parent) -ne 0x30070){
     throw 'BL_R15_CBS_OWNER_NOT_EXACT_ONE_PARENT04'
    }
   }finally{$owners.Close()}
   Note ('TARGET_CBS_SINGLE_OWNER_0x30070=PASS;'+$parent)
   $updates=$key.OpenSubKey('Updates',$false)
   if($null -eq $updates){throw 'BL_R15_TARGET_UPDATES_KEY_MISSING'}
   try{
    $u=@($updates.GetValueNames())
    $marker=$updates.GetValue('SearchEngine-Client-Package',$null)
    if($u.Count -ne 1 -or $u[0] -cne 'SearchEngine-Client-Package' -or
       $null -eq $marker -or
       $updates.GetValueKind('SearchEngine-Client-Package').ToString() -cne 'DWord' -or
       [uint32]$marker -ne 0){
     throw 'BL_R15_TARGET_UPDATES_NOT_EXACT_SINGLE_ZERO'
    }
   }finally{$updates.Close()}
   Note 'CBS_TARGET_UPDATES_EXACT_0x0=PASS'
  }finally{$key.Close()}
  $parentKey=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($root+'\'+$parent),$false)
  if($null -eq $parentKey){throw 'BL_R15_REQUIRED_PARENT_CBS_KEY_MISSING'}
  try{
   $ps=$parentKey.GetValue('CurrentState',$null)
   if($null -eq $ps -or [uint32]$ps -ne 0x70){throw 'BL_R15_REQUIRED_PARENT_CBS_NOT_INSTALLED'}
  }finally{$parentKey.Close()}
  Note 'CURRENT_REQUIRED_PARENT04_CBS_0x70=PASS'
  $oldKey=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(($root+'\'+$old),$false)
  if($null -eq $oldKey){throw 'BL_R15_OLD_STAGED_CBS_KEY_MISSING'}
  try{
   $os=$oldKey.GetValue('CurrentState',$null)
   if($null -eq $os -or [uint32]$os -ne 0x40){throw 'BL_R15_OLD_CBS_NOT_STAGED'}
  }finally{$oldKey.Close()}
  Note 'OLD_SEARCH_STAGED_CBS_0x40=PASS'
  Note 'STEP_02_TARGET_ONLY_CBS_AMBER_VISIBILITY_AND_OWNERS'
  RegCall 'TARGET_VISIBILITY_TO_1' @('add',('HKLM\'+$targetKey),'/v','Visibility','/t','REG_DWORD','/d','1','/f')
  RegCall 'TARGET_OWNERS_KEY_DELETE' @('delete',('HKLM\'+$targetKey+'\Owners'),'/f')
  $targetCheck=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($targetKey,$false)
  if($null -eq $targetCheck){throw 'BL_R15_POST_DECOUPLE_TARGET_KEY_MISSING'}
  try{
   if([uint32]$targetCheck.GetValue('Visibility',0) -ne 1 -or
      $null -ne $targetCheck.OpenSubKey('Owners',$false)){
    throw 'BL_R15_TARGET_ONLY_DECOUPLE_NOT_VERIFIED'
   }
  }finally{$targetCheck.Close()}
  Note 'TARGET_CBS_VISIBILITY_0x1_OWNERS_ABSENT=PASS'
  [GC]::Collect();[GC]::WaitForPendingFinalizers()
  RegCall 'UNLOAD_BEFORE_NATIVE_DISM' @('unload',('HKLM\'+$alias))
  $load=$false
  Note 'STEP_03_NATIVE_EXACT_SEARCHENGINE_REMOVE'
  $null=Native 'REMOVE_ONLY_CURRENT_SEARCHENGINE' @('/English',('/Image:'+$mount),'/Remove-Package',('/PackageName:'+$target))
  Note 'TARGET_NATIVE_REMOVE_EXIT0=PASS'
  $post=Exact $target $true
  Note ('TARGET_CURRENT_POST='+$post)
  if($post -cne 'NONRESOLVING'){throw 'BL_R15_TARGET_NATIVE_POST_NOT_NONRESOLVING'}
  StateFloor 'POST'
  Pending 'POST'
  Health 'POST' 'CheckHealth'
  Health 'POST' 'ScanHealth'
  Note 'S43_NATIVE_TARGET_REMOVED_PARENT_OLD_STAGED_PRESERVED_PENDING0_HEALTH_CLEAN=PASS'
  $null=Native 'COMMIT_OWNED_S43' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Commit')
  $mounted=$false;$committed=$true
  Note 'OWNED_S43_NATIVE_COMMIT=PASS'
  ZeroMounts 'POST'
  ZeroHives 'POST'
  Pin $source 6636510185L $sourceSha 'S41_ORIGINAL_POST'
  $out=Get-Item -LiteralPath $clone -Force -ErrorAction Stop
  Note ('S43_COMMITTED_WIM_BYTES='+$out.Length)
  Note ('S43_COMMITTED_WIM_SHA256='+(Get-FileHash -LiteralPath $clone -Algorithm SHA256).Hash)
  $status='PASS_S43_R15_SEARCHENGINE_NATIVE_AMBER_REMOVE_COMMIT_ONLY'
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  if($load){
   try{
    [GC]::Collect();[GC]::WaitForPendingFinalizers()
    RegCall 'UNLOAD_ON_HOLD' @('unload',('HKLM\'+$alias));$load=$false
   }catch{$critical=$true;Note ('CRITICAL_HIVE_UNLOAD_HOLD='+$_.Exception.Message)}
  }
  if($mountedAttempt -and -not $committed -and -not $load){
   try{
    $table=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
    if($mounted -or (($table -join [Environment]::NewLine).Contains($mount))){
     $null=Native 'DISCARD_OWNED_S43_ON_HOLD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     $mounted=$false;Note 'OWNED_S43_DISCARD_ON_HOLD=PASS'
    }
    ZeroMounts 'AFTER_HOLD'
   }catch{$critical=$true;Note ('CRITICAL_DISCARD_HOLD='+$_.Exception.Message)}
  }
  if($created -and -not $load -and -not $mounted){
   try{
    if(Test-Path -LiteralPath $mount){
     if(@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -ne 0){
      throw 'BL_R15_MOUNT_DIR_NOT_EMPTY'
     }
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
    }
    if($committed){
     if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Force -ErrorAction Stop;Note 'REDUNDANT_PRE_AMBER_SOFTWARE_BACKUP_REMOVED=PASS'}
    }elseif(-not $critical){
     if(Test-Path -LiteralPath $backup){Remove-Item -LiteralPath $backup -Force -ErrorAction Stop}
     if(Test-Path -LiteralPath $clone){Remove-Item -LiteralPath $clone -Force -ErrorAction Stop}
     if(@(Get-ChildItem -LiteralPath $owned -Force -ErrorAction Stop).Count -ne 0){
      throw 'BL_R15_FAILED_S43_UNKNOWN_REMAINDER'
     }
     [IO.Directory]::Delete($owned,$false)
     Note 'FAILED_DISPOSABLE_S43_CLONE_AND_WORKDIR_RETIRED=PASS'
    }
   }catch{$critical=$true;Note ('CRITICAL_OWNED_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  try{Pin $source 6636510185L $sourceSha 'S41_POST_FINAL'}catch{$critical=$true;Note ('CRITICAL_SOURCE_POST_PIN='+$_.Exception.Message)}
  try{ZeroMounts 'FINAL'}catch{$critical=$true;Note ('CRITICAL_MOUNT_FINAL='+$_.Exception.Message)}
  try{ZeroHives 'FINAL'}catch{$critical=$true;Note ('CRITICAL_HIVE_FINAL='+$_.Exception.Message)}
  if($critical){$status='HOLD_R15_CRITICAL_CLEANUP_REVIEW'}
  Note ('RESULT='+$status)
  Note ('REPORT='+$report)
  Note 'S41_SOURCE_PROTECTED;S43_PASS_RETAIN_FOR_INDEPENDENT_POSTCOMMIT_ONLY;NO_GENERIC_ENGINE_CERTIFICATION'
 }
 if($status -ne 'PASS_S43_R15_SEARCHENGINE_NATIVE_AMBER_REMOVE_COMMIT_ONLY'){
  throw 'BL_R15_SEARCHENGINE_AMBER_NATIVE_HOLD'
 }
}
