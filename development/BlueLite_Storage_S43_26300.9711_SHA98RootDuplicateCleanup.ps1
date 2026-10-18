& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $origin='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $stage='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\UUPs'
 $receipt='C:\work\logs\BlueLite_Storage_S42F_26300.9711_AppsTree.txt'
 $log='C:\work\logs\BlueLite_Storage_S43_26300.9711_SHA98RootCleanup.txt'
 $encoding=[Text.UTF8Encoding]::new($false)
 $outcome='HOLD_S43_NO_DELETION'
 $deleted=0
 [long]$deletedBytes=0
 [long]$freeBefore=0
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOGS_DIR_MISSING'}
 if(Test-Path -LiteralPath $log){throw 'S43_LOG_EXISTS_NO_OVERWRITE'}
 [IO.File]::WriteAllText($log,'',$encoding)
 function Note([string]$text){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$text
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$encoding)
 }
 function Guard([string]$p){
  $node=Get-Item -LiteralPath $p -Force -ErrorAction Stop
  if(-not $node.PSIsContainer){throw ('NOT_DIRECTORY='+$p)}
  $ok=$false
  while($null -ne $node){
   if(($node.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('REPARSE_PARENT='+$node.FullName)}
   if($node.FullName -ieq 'C:\work'){$ok=$true;break}
   $node=$node.Parent
  }
  if(-not $ok){throw ('OUTSIDE_WORK='+$p)}
 }
 try{
  Note 'S43_EXACT_98_STAGE_ROOT_DUPLICATES_SHA_GATED'
  Note 'DELETE_ONLY_AFTER_98_OF_98_SHA256_PAIRS_PASS;NO_DIRECTORY_DELETION'
  $r=Get-Item -LiteralPath $receipt -ErrorAction Stop
  if($r.Length -ne 9550 -or (Get-FileHash -LiteralPath $receipt -Algorithm SHA256).Hash -cne
     '88411B0B87CE659669DE281AC1736F3EAAC3F02FD30B98E101BA1846F5C8D531'){
   throw 'PIN_S42F_RECEIPT_DRIFT'
  }
  Note 'PIN_S42F_ACTUAL=PASS'
  Guard $origin
  Guard $stage
  Guard (Join-Path $stage 'Apps')
  $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
  $output=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $dismExit=[int]$LASTEXITCODE
  $joined=$output -join [Environment]::NewLine
  if($dismExit -ne 0 -or -not $joined.Contains('No mounted images found.') -or
    -not $joined.Contains('The operation completed successfully.') -or
    @($output|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -gt 0){
   throw 'DISM_MOUNT_STATE_NOT_CLEAR'
  }
  $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
    @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'}).Count -gt 0){
   throw 'OFFLINE_HIVE_GATE_NOT_CLEAR'
  }
  Note 'ZERO_DISM_MOUNTS_ZERO_BLUE_HIVES=PASS'
  $protected=@(
   @{Path='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim';Bytes=6509216853L},
   @{Path='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim';Bytes=6551362129L}
  )
  foreach($pin in $protected){
   $item=Get-Item -LiteralPath $pin.Path -ErrorAction Stop
   if($item.PSIsContainer -or $item.Length -ne $pin.Bytes){throw ('PROTECTED_WIM_SIZE_DRIFT='+$pin.Path)}
  }
  Note 'PROTECTED_S31_S37_SIZE_AND_PRESENCE=PASS;WIM_HASH_NOT_REPEATED'
  $src=@(Get-ChildItem -LiteralPath $origin -File -Force -ErrorAction Stop)
  $srcDirs=@(Get-ChildItem -LiteralPath $origin -Directory -Force -ErrorAction Stop)
  $stg=@(Get-ChildItem -LiteralPath $stage -File -Force -ErrorAction Stop)
  $stgDirs=@(Get-ChildItem -LiteralPath $stage -Directory -Force -ErrorAction Stop)
  $appsFiles=@(Get-ChildItem -LiteralPath (Join-Path $stage 'Apps') -File -Force -ErrorAction Stop)
  $appsDirs=@(Get-ChildItem -LiteralPath (Join-Path $stage 'Apps') -Directory -Force -ErrorAction Stop)
  if($src.Count -ne 129 -or $srcDirs.Count -ne 0 -or
     $stg.Count -ne 101 -or $stgDirs.Count -ne 1 -or
     $stgDirs[0].Name -cne 'Apps' -or
     $appsFiles.Count -ne 1 -or $appsDirs.Count -ne 51){
   throw 'EXACT_EXPECTED_LAYOUT_DRIFT'
  }
  $origByName=@{}
  foreach($item in $src){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('SOURCE_REPARSE='+$item.Name)}
   if($origByName.ContainsKey($item.Name)){throw ('ORIGINAL_DUP_NAME='+$item.Name)}
   $origByName[$item.Name]=$item
  }
  $extras=@{
   '_AppsFilesList.csv'=313375L
   'Windows11.0-KB5043113-x64_inout.cab'=20094087L
   'Windows11.0-KB5127647-x64_inout.cab'=21110997L
  }
  $seen=@{}
  $pairs=[System.Collections.Generic.List[object]]::new()
  [long]$bytes=0
  foreach($file in $stg){
   if(($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('STAGED_REPARSE='+$file.Name)}
   if($origByName.ContainsKey($file.Name)){
    $reference=$origByName[$file.Name]
    if($file.Length -ne $reference.Length){throw ('DUPLICATE_SIZE_DRIFT='+$file.Name)}
    $bytes += [long]$file.Length
    $pairs.Add([pscustomobject]@{Staged=$file.FullName;Original=$reference.FullName;Name=$file.Name;Bytes=$file.Length})
   }elseif($extras.ContainsKey($file.Name)){
    if($seen.ContainsKey($file.Name) -or $file.Length -ne $extras[$file.Name]){throw ('EXTRA_SIZE_DRIFT='+$file.Name)}
    $seen[$file.Name]=$true
   }else{throw ('UNKNOWN_STAGED_ROOT_FILE='+$file.Name)}
  }
  if($pairs.Count -ne 98 -or $seen.Count -ne 3 -or $bytes -ne 8880359774L){
   throw ('PAIR_COUNT_OR_TOTAL_DRIFT='+$pairs.Count+';BYTES='+$bytes)
  }
  Note ('METADATA_GATE=PASS;CANDIDATES='+$pairs.Count+';LOGICAL_BYTES='+$bytes)
  $approved=[System.Collections.Generic.List[object]]::new()
  foreach($pair in ($pairs|Sort-Object Name)){
   $shaA=(Get-FileHash -LiteralPath $pair.Original -Algorithm SHA256).Hash
   $shaB=(Get-FileHash -LiteralPath $pair.Staged -Algorithm SHA256).Hash
   if($shaA -cne $shaB){throw ('SHA_PAIR_MISMATCH_NO_FILES_DELETED='+$pair.Name)}
   $approved.Add($pair)
   if($approved.Count%10 -eq 0 -or $approved.Count -eq 98){
    Note ('SHA256_PAIRS_MATCH='+$approved.Count+'/98')
   }
  }
  if($approved.Count -ne 98){throw 'APPROVAL_COUNT_NOT_98'}
  Note 'ALL_98_SHA256_EQUAL=PASS;DELETION_START'
  $freeBefore=[IO.DriveInfo]::new('C').AvailableFreeSpace
  $outcome='PARTIAL_S43_DELETION'
  foreach($pair in $approved){
   $current=Get-Item -LiteralPath $pair.Staged -ErrorAction Stop
   if($current.Length -ne $pair.Bytes){throw ('STAGED_FILE_DRIFT_AT_DELETE='+$pair.Name)}
   if(-not(Test-Path -LiteralPath $pair.Original -PathType Leaf)){throw ('SOURCE_MISSING_AT_DELETE='+$pair.Name)}
   Remove-Item -LiteralPath $pair.Staged -Force -ErrorAction Stop
   if(Test-Path -LiteralPath $pair.Staged){throw ('DELETE_VERIFY_FAILED='+$pair.Name)}
   $deleted++
   $deletedBytes += [long]$pair.Bytes
   Note ('REMOVED='+$pair.Name+';BYTES='+$pair.Bytes)
  }
  if($deleted -ne 98 -or $deletedBytes -ne 8880359774L){throw 'POSTDELETE_COUNT_ERROR'}
  $remaining=@(Get-ChildItem -LiteralPath $stage -File -Force -ErrorAction Stop)
  if($remaining.Count -ne 3){throw ('POST_STAGE_ROOT_COUNT='+$remaining.Count)}
  foreach($f in $remaining){
   if(-not $extras.ContainsKey($f.Name) -or $f.Length -ne $extras[$f.Name]){
    throw ('POST_STAGE_EXTRA_DRIFT='+$f.Name)
   }
  }
  if(@(Get-ChildItem -LiteralPath $origin -File -Force -ErrorAction Stop).Count -ne 129){
   throw 'ORIGINAL_129_CHANGED'
  }
  $outcome='PASS_S43_98_SHA_IDENTICAL_STAGED_ROOT_FILES_REMOVED'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$outcome+';REMOVED_FILES='+$deleted+';LOGICAL_REMOVED_BYTES='+$deletedBytes)
  if($freeBefore -gt 0){
   $freeAfter=[IO.DriveInfo]::new('C').AvailableFreeSpace
   Note ('C_FREE_BEFORE='+$freeBefore+';AFTER='+$freeAfter+';DELTA='+($freeAfter-$freeBefore))
  }
  Note 'ORIGINAL_UUP_APPS_CONVERTER_FILES_S31_S37_G5_NOT_TARGETED'
  Note 'NEXT=UNIVERSAL_26300_MAX_PRE_ENGINE_DEVELOPMENT'
  Write-Host ('S43_REPORT='+$log)
 }
}