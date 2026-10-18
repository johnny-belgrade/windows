& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $original='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $staged='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\UUPs'
 $apps=Join-Path $staged 'Apps'
 $report='C:\work\logs\BlueLite_Storage_S42E_26300.9711_LayoutAwarePairs.txt'
 $csv='C:\work\logs\BlueLite_Storage_S42E_26300.9711_LayoutAwarePairs.csv'
 $utf8=[Text.UTF8Encoding]::new($false)
 $result='HOLD_S42E_LAYOUT_AWARE_PAIRS_READONLY'
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOG_DIR_MISSING'}
 foreach($p in @($report,$csv)){if(Test-Path -LiteralPath $p){throw 'S42E_OUTPUT_EXISTS_NO_OVERWRITE'}}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$message){
  $s=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $s
  [IO.File]::AppendAllText($report,$s+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$file,[long]$bytes,[string]$sha){
  $info=Get-Item -LiteralPath $file -ErrorAction Stop
  if($info.Length -ne $bytes){throw ('PIN_SIZE_DRIFT='+$tag)}
  if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -cne $sha){throw ('PIN_SHA_DRIFT='+$tag)}
  Note ('PIN_'+$tag+'=PASS;BYTES='+$bytes)
 }
 function SafeDirectory([string]$path){
  $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if(-not $item.PSIsContainer){throw ('NOT_DIRECTORY='+$path)}
  $cursor=$item
  $inside=$false
  while($null -ne $cursor){
   if(($cursor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw ('REPARSE_ANCESTOR='+$cursor.FullName)
   }
   if($cursor.FullName -ieq 'C:\work'){$inside=$true;break}
   $cursor=$cursor.Parent
  }
  if(-not $inside){throw ('OUTSIDE_WORK='+$path)}
 }
 function Files([string]$path){
  return @(Get-ChildItem -LiteralPath $path -File -Force -ErrorAction Stop)
 }
 function Dirs([string]$path){
  return @(Get-ChildItem -LiteralPath $path -Directory -Force -ErrorAction Stop)
 }
 function NoLinks([object[]]$items,[string]$tag){
  foreach($item in $items){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw ('REPARSE_ENTRY='+$tag+';'+$item.Name)
   }
  }
 }
 try {
  Note 'S42E_LAYOUT_AWARE_UUP_CONTENT_CERTIFICATION_READONLY'
  Note 'NO_DOWNLOAD_NO_DELETION_NO_CONVERTER_NO_WIM_MUTATION'
  Pin 'S42D_REPORT' 'C:\work\logs\BlueLite_Storage_S42D_26300.9711_UUPShape.txt' 4754 '781C39101645F7FDACD602A49C9CD0C331B15033FACECF476191EE0B4EEECB65'
  Pin 'S42D_CSV' 'C:\work\logs\BlueLite_Storage_S42D_26300.9711_UUPShape.csv' 16933 'C1E7A0E51B17E12EF6F253AF473C6583B38E1ECE6332D1616935C66FC0010FFF'
  Pin 'S42_HOLD' 'C:\work\logs\BlueLite_Storage_S42_26300.9711_UUPPairs.txt' 668 '5C83E45CD28B493B0F0853F9028E547479118D56542CC52C4A70B67E683DFACB'
  $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
  $dismRaw=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $dismStatus=[int]$LASTEXITCODE
  $native=$dismRaw -join [Environment]::NewLine
  if($dismStatus -ne 0 -or -not $native.Contains('No mounted images found.') -or
     -not $native.Contains('The operation completed successfully.') -or
     $native.Contains('DISM.exe [dism_options]') -or
     @($dismRaw|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'DISM_MOUNT_NOT_EMPTY_OR_UNPROVEN'
  }
  $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
  $hive=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($hive|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'}).Count -gt 0){
   throw 'OFFLINE_HIVE_ALIAS_ACTIVE_OR_UNPROVEN'
  }
  Note 'DISM_ZERO_MOUNTS_AND_BLUE_HIVES=PASS'
  foreach($p in @($original,$staged,$apps)){SafeDirectory $p}
  $sourceFiles=@(Files $original)
  $sourceDirs=@(Dirs $original)
  $stageFiles=@(Files $staged)
  $stageDirs=@(Dirs $staged)
  $appFiles=@(Files $apps)
  $appDirs=@(Dirs $apps)
  NoLinks $sourceFiles 'ORIGINAL'
  NoLinks $sourceDirs 'ORIGINAL_DIR'
  NoLinks $stageFiles 'STAGED_ROOT'
  NoLinks $stageDirs 'STAGED_DIR'
  NoLinks $appFiles 'STAGED_APPS'
  NoLinks $appDirs 'STAGED_APPS_DIR'
  if($sourceFiles.Count -ne 129 -or $sourceDirs.Count -ne 0 -or
     $stageFiles.Count -ne 101 -or $stageDirs.Count -ne 1 -or
     $stageDirs[0].Name -cne 'Apps' -or
     $appFiles.Count -ne 31 -or $appDirs.Count -ne 0){
   Note ('SHAPE_ORIGINAL='+$sourceFiles.Count+'/'+$sourceDirs.Count+
     ';STAGE='+$stageFiles.Count+'/'+$stageDirs.Count+
     ';APPS='+$appFiles.Count+'/'+$appDirs.Count)
   throw 'S42E_EXPECTED_CONVERTER_LAYOUT_CHANGED'
  }
  Note 'SHAPE=ORIGINAL_129_ROOT;STAGED_101_ROOT_PLUS_31_APPS'
  $sourceByName=@{}
  foreach($f in $sourceFiles){
   if($sourceByName.ContainsKey($f.Name)){throw ('SOURCE_DUPLICATE_NAME='+$f.Name)}
   $sourceByName[$f.Name]=$f
  }
  $stageByName=@{}
  $rootCopyCount=0
  [long]$rootBytes=0
  $extras=@{
   '_AppsFilesList.csv'=313375L
   'Windows11.0-KB5043113-x64_inout.cab'=20094087L
   'Windows11.0-KB5127647-x64_inout.cab'=21110997L
  }
  $extrasSeen=@{}
  foreach($f in $stageFiles){
   $rootBytes += [long]$f.Length
   if($sourceByName.ContainsKey($f.Name)){
    if($stageByName.ContainsKey($f.Name)){throw ('STAGED_DUPLICATE_NAME='+$f.Name)}
    $stageByName[$f.Name]=$f
    $rootCopyCount++
   }elseif($extras.ContainsKey($f.Name)){
    if($extrasSeen.ContainsKey($f.Name) -or $f.Length -ne $extras[$f.Name]){
     throw ('EXTRA_FILE_DRIFT='+$f.Name)
    }
    $extrasSeen[$f.Name]=$true
   }else{
    throw ('UNKNOWN_STAGE_ROOT_FILE='+$f.Name)
   }
  }
  [long]$appBytes=0
  foreach($f in $appFiles){
   $appBytes += [long]$f.Length
   if(-not $sourceByName.ContainsKey($f.Name)){throw ('UNKNOWN_APPS_FILE='+$f.Name)}
   if($stageByName.ContainsKey($f.Name)){throw ('STAGED_DUPLICATE_FILE='+$f.Name)}
   $stageByName[$f.Name]=$f
  }
  foreach($file in $sourceFiles){
   if(-not $stageByName.ContainsKey($file.Name)){throw ('STAGED_FILE_MISSING='+$file.Name)}
   if($stageByName[$file.Name].Length -ne $file.Length){
    throw ('SIZE_MISMATCH='+$file.Name)
   }
  }
  [long]$originalBytes=0
  foreach($file in $sourceFiles){$originalBytes += [long]$file.Length}
  if($originalBytes -ne 8992976071L -or $rootBytes -ne 8921878233L -or
     $appBytes -ne 112616297L -or $rootCopyCount -ne 98 -or
     $extrasSeen.Count -ne 3 -or $stageByName.Count -ne 129){
   Note ('COUNTS_SOURCE_BYTES='+$originalBytes+';ROOT_BYTES='+$rootBytes+
     ';APPS_BYTES='+$appBytes+';ROOT_COPIES='+$rootCopyCount+
     ';EXTRAS='+$extrasSeen.Count+';MAPPED='+$stageByName.Count)
   throw 'S42E_BYTES_OR_FILENAME_MAPPING_DRIFT'
  }
  Note ('SHAPE_AND_BYTES=PASS;ROOT_COPIES=98;APPS_COPIES=31;APP_BYTES='+$appBytes)
  Note 'SHA256_PAIR_VERIFICATION_START_129;READ_VOLUME_APPROX_18_GB'
  $rows=[System.Collections.Generic.List[object]]::new()
  $differences=0
  foreach($f in ($sourceFiles|Sort-Object Name)){
   $copy=$stageByName[$f.Name]
   $sourceHash=(Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
   $stageHash=(Get-FileHash -LiteralPath $copy.FullName -Algorithm SHA256).Hash
   $ok=($sourceHash -ceq $stageHash -and $f.Length -eq $copy.Length)
   if(-not $ok){$differences++}
   $location=if($copy.DirectoryName -ieq $apps){'Apps'}else{'UUPs'}
   $rows.Add([pscustomobject]@{
    Name=$f.Name;SourceBytes=$f.Length;StagedBytes=$copy.Length;
    StagedLocation=$location;SourceSHA256=$sourceHash;
    StagedSHA256=$stageHash;Identical=$ok
   })
   if($rows.Count%8 -eq 0 -or $rows.Count -eq 129){
    Note ('PAIRS_VERIFIED='+$rows.Count+'/129;DIFFERENCES='+$differences)
   }
  }
  $rows|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation
  Note ('MATCHED='+($rows.Count-$differences)+';DIFFERENCES='+$differences+';PAIRS='+$rows.Count)
  Note ('SOURCE_BYTES='+$originalBytes+';STAGE_DUPLICATE_BYTES='+($rootBytes+$appBytes-41518459L))
  if($rows.Count -eq 129 -and $differences -eq 0){
   $result='PASS_S42E_LAYOUT_AWARE_129_UUP_PAIRS_SHA256_IDENTICAL_READONLY'
  }else{
   Note 'CONTENT_MISMATCH_NO_DELETION_AUTHORITY'
  }
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$result)
  Note 'S43_DELETION=NOT_AUTHORIZED_AND_NOT_RUN'
  Note 'DOWNLOAD=NOT_RUN;CONVERTER=NOT_RUN;WIM=NOT_TOUCHED'
  Write-Host ('REPORT='+$report)
  if(Test-Path -LiteralPath $csv -PathType Leaf){Write-Host ('CSV='+$csv)}
 }
}