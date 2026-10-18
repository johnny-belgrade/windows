# BlueLite high-impact target gate R1: reparse-aware bounded WinSxS owner metadata.
# Read-only native DISM mount of existing S37; no image clones/removals.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work'
 $image='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $mount='C:\work\MWV26300R1'
 $log='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_TargetGate_R1.txt'
 $csv='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_Owners_R1.csv'
 $sha='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $originalReport='C:\work\logs\BlueLite_MAXPRE_WebViewEdge_26300.9711_TargetGate.txt'
 $originalHash='5AB59F509804D4786376A64569D6E604C29FD3EBB2E99F6D23D0FB26D47EF622'
 if((Get-Item -LiteralPath $originalReport -Force -ErrorAction Stop).Length -ne 915 -or
    (Get-FileHash -LiteralPath $originalReport -Algorithm SHA256).Hash -cne $originalHash){
  throw 'BL_ORIGINAL_S37_WEBVIEW_HOLD_REPORT_PIN_DRIFT'
 }
 $utf8=[Text.UTF8Encoding]::new($false)
 foreach($p in @($log,$csv,$mount)){
  if(Test-Path -LiteralPath $p){throw ('BL_NO_OVERWRITE_OR_EXISTING_MOUNT='+$p)}
 }
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_LOGS_MISSING'}
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$s){
  Write-Host $s
  [IO.File]::AppendAllText($log,$s+[Environment]::NewLine,$utf8)
 }
 function NativeDism([string]$tag,[string[]]$argsForDism){
  $bin=Join-Path $env:SystemRoot 'System32\dism.exe'
  $lines=@(& $bin @argsForDism 2>&1|ForEach-Object {[string]$_})
  $exitCode=[int]$LASTEXITCODE
  $all=$lines -join [Environment]::NewLine
  if($exitCode -ne 0 -or $all -notmatch '(?i)The operation completed successfully\.' -or
     $all -match '(?im)^\s*Error\s*:'){
   throw ('BL_DISM_'+$tag+'_FAILED_EXIT_'+$exitCode)
  }
  return $all
 }
 $mounted=$false
 $mountAttempted=$false
 $created=$false
 $result='HOLD_WEBVIEW_EDGE_TARGET_GATE_READONLY'
 try{
  Note 'MAXPRE_EDGE_WEBVIEW_26300_S37_DELTA_DEPENDENCY_GATE_R1'
  Note ('ORIGINAL_HOLD_REPORT_PIN=PASS;'+$originalHash)
  Note 'READONLY_REPARSE_METADATA_CLASSIFICATION_NO_TARGET_FOLLOW'
  Note 'S27_LOGICAL_BASELINE_WEBVIEW_EDGE=940205314_BYTES;OWNERS=3;NOT_RECLAIMABLE_BYTES'
  Note 'TARGET_HIGH_PAYLOAD_FIRST;NO_WIM_CLONE_NO_WIM_MUTATION_NO_RAW_CARVE'
  $info=Get-Item -LiteralPath $image -Force -ErrorAction Stop
  if($info.PSIsContainer -or $info.Length -ne 6551362129L -or
     ($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
   throw 'BL_PROTECTED_S37_IDENTITY_OR_REPARSE_DRIFT'
  }
  $actual=(Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash
  if($actual -cne $sha){throw 'BL_S37_SOURCE_SHA_DRIFT'}
  Note ('S37_PROTECTED_WIM_SHA=PASS;'+$sha)
  $before=NativeDism 'ZERO_MOUNTS_PRE' @('/English','/Get-MountedWimInfo')
  if(-not $before.Contains('No mounted images found.') -or
     $before -match '(?im)^\s*Mount Dir\s*:'){
   throw 'BL_PREEXISTING_WIM_MOUNT'
  }
  $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_OFFLINE_BLUE_HIVE_PREEXISTS'
  }
  Note 'DISM_MOUNTS_AND_BLUE_HIVES_ZERO=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true
  $mountAttempted=$true
  $mountedOutput=NativeDism 'READONLY_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$image),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'S37_NATIVE_READONLY_MOUNT=PASS'
  $caps=NativeDism 'CAPABILITY_INVENTORY' @('/English',('/Image:'+$mount),'/Get-Capabilities')
  $packages=NativeDism 'PACKAGE_INVENTORY' @('/English',('/Image:'+$mount),'/Get-Packages')
  foreach($inventory in @(
   @{Tag='CAPABILITY';Text=$caps;Pattern='(?i)(edge|webview|browser|chromium)'},
   @{Tag='PACKAGE';Text=$packages;Pattern='(?i)(edge|webview|browser|chromium)'}
  )){
   $kind=[string]$inventory.Tag
   $relevant=@($inventory.Text -split '\r?\n'|Where-Object {$_ -match $inventory.Pattern})
   Note ($kind+'_MATCH_LINES='+$relevant.Count)
   foreach($line in $relevant){
    Note ($kind+'_IDENTITY='+$line.Trim())
   }
  }
  $winsxs=Join-Path $mount 'Windows\WinSxS'
  $dirs=@(Get-ChildItem -LiteralPath $winsxs -Directory -Force -ErrorAction Stop |
   Where-Object {$_.Name -match '(?i)(edge|webview)' } |
   Sort-Object Name)
  if($dirs.Count -gt 40){throw ('BL_TARGET_OWNER_SCOPE_EXPANDED='+$dirs.Count)}
  Note ('CURRENT_WEBVIEW_EDGE_WIN_SXS_OWNER_DIRS='+$dirs.Count)
  $rows=[System.Collections.Generic.List[object]]::new()
  [long]$logical=0
  [long]$reparseLogical=0
  [int]$allReparseFiles=0
  [int]$skippedReparseDirs=0
  [int]$broadOnly=0
  [int]$familyDirs=0
  [int]$totalFiles=0
  foreach($dir in $dirs){
   $type=if($dir.Name -match '(?i)_(microsoft-edge-webview|microsoft-edge|microsoft-windows-edge|microsoft-windows-webview)_'){'EDGE_WEBVIEW_FAMILY'}else{'BROAD_NAME_ONLY'}
   if($type -eq 'EDGE_WEBVIEW_FAMILY'){$familyDirs++}else{$broadOnly++}
   $ownerIsReparse=(($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
   [long]$bytes=0
   [long]$repBytes=0
   [int]$fileCount=0
   [int]$repCount=0
   [int]$nestedDirCount=0
   [int]$nestedSkipped=0
   if($ownerIsReparse){
    $skippedReparseDirs++
    Note ('OWNER_REPARSE_DIRECTORY_NOT_TRAVERSED='+$dir.Name)
   }else{
    $pending=[System.Collections.Generic.Stack[object]]::new()
    $pending.Push([pscustomobject]@{Path=$dir.FullName;Depth=0})
    while($pending.Count -gt 0){
     $item=$pending.Pop()
     if($item.Depth -gt 8){throw 'BL_OWNER_NESTING_DEPTH_LIMIT'}
     $children=@(Get-ChildItem -LiteralPath $item.Path -Force -ErrorAction Stop)
     foreach($child in $children){
      if($child -is [IO.DirectoryInfo]){
       $nestedDirCount++
       if(($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
        $nestedSkipped++
        $skippedReparseDirs++
       }else{
        $pending.Push([pscustomobject]@{Path=$child.FullName;Depth=($item.Depth+1)})
       }
      }elseif($child -is [IO.FileInfo]){
       $fileCount++
       $totalFiles++
       if($totalFiles -gt 15000){throw 'BL_TARGET_METADATA_FILE_SCOPE_LIMIT'}
       if(($child.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
        $repCount++
        $allReparseFiles++
        $repBytes += [long]$child.Length
       }else{
        $bytes += [long]$child.Length
       }
      }else{throw 'BL_OWNER_UNEXPECTED_OBJECT_TYPE'}
     }
    }
   }
   $logical += $bytes
   $reparseLogical += $repBytes
   $rows.Add([pscustomobject]@{
    OwnerName=$dir.Name;OwnerClass=$type
    OwnerIsReparse=$ownerIsReparse
    Files=$fileCount;ReparseFiles=$repCount;NormalFileLogicalBytes=$bytes
    ReparseFileLengthMetadataBytes=$repBytes
    NestedDirectoriesSeen=$nestedDirCount
    ReparseDirectoriesNotTraversed=$nestedSkipped
   })
   Note ('WIN_SXS_OWNER='+$dir.Name+';CLASS='+$type+
    ';FILES='+$fileCount+';REPARSE_FILES='+$repCount+
    ';NORMAL_LOGICAL_BYTES='+$bytes+';REPARSE_FILE_LENGTH_METADATA='+$repBytes+
    ';SKIPPED_REPARSE_DIRS='+$nestedSkipped)
  }
  $rows|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation -ErrorAction Stop
  Note ('SCOPED_OWNER_DIRS='+$dirs.Count+';EXACT_EDGE_WEBVIEW_FAMILY='+$familyDirs+
   ';BROAD_NAME_ONLY='+$broadOnly+';REPARSE_FILES='+$allReparseFiles+
   ';REPARSE_DIRS_NOT_TRAVERSED='+$skippedReparseDirs)
  Note ('NON_REPARSE_FILE_LOGICAL_BYTES='+$logical+
   ';REPARSE_FILE_LENGTH_METADATA_BYTES='+$reparseLogical+
   ';NOT_UNIQUE_OR_RECLAIMABLE_BYTES')
  Note ('S27_THREE_OWNER_SCOPE_NOT_COMPARABLE_UNTIL_NAME_MATCHED=TRUE')
  foreach($suffix in @(
   'Program Files (x86)\Microsoft\EdgeWebView',
   'Program Files (x86)\Microsoft\Edge',
   'Windows\SystemApps\Microsoft.MicrosoftEdge*'
  )){
   if($suffix.Contains('*')){
    $parent=Join-Path $mount 'Windows\SystemApps'
    $matches=@(Get-ChildItem -LiteralPath $parent -Directory -Force -ErrorAction Stop|
     Where-Object {$_.Name -like 'Microsoft.MicrosoftEdge*'})
    Note ('EDGE_SYSTEMAPPS_MATCHES='+$matches.Count)
   }else{
    Note ('RUNTIME_PATH='+$suffix+';PRESENT='+(Test-Path -LiteralPath (Join-Path $mount $suffix)))
   }
  }
  Note 'TARGET_RECIPE=BL.FOD.EdgeWebView2;REGISTRY_R12_RUNTIME_DISABLED'
  Note 'SERVICING_OWNER_DEPENDENCIES=NOT_CERTIFIED;NO_DELETION_AUTHORIZED'
  Note 'REPARSE_FLAG_ON_MOUNTED_WIM_FILE_NOT_AUTOMATIC_CBS_ERROR'
  $result='PASS_WEBVIEW_EDGE_S37_R1_REPARSE_AWARE_DISCOVERY_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($mountAttempted){
   try{
    $mountInfo=@(& (Join-Path $env:SystemRoot 'System32\dism.exe') /English /Get-MountedWimInfo 2>&1 |
     ForEach-Object {[string]$_}) -join [Environment]::NewLine
    $ownedMountListed=$mountInfo.Contains($mount)
    if($mounted -or $ownedMountListed){
     $null=NativeDism 'READONLY_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'READONLY_UNMOUNT_DISCARD=PASS'
    }
    $after=NativeDism 'POST_UNMOUNT_TABLE' @('/English','/Get-MountedWimInfo')
    if(-not $after.Contains('No mounted images found.')){
     throw 'BL_POST_UNMOUNT_NONZERO_MOUNTS'
    }
    $mounted=$false
    Note 'POST_UNMOUNT_ZERO_MOUNTS=PASS'
   }catch{
    $mounted=$true
    Note ('CRITICAL_UNMOUNT_VERIFICATION_FAILURE='+$_.Exception.Message)
    $result='HOLD_WEBVIEW_EDGE_UNMOUNT_MANUAL_HANDLE_REVIEW'
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_MOUNT_DIRECTORY_REMOVED=PASS'
    }else{Note 'MOUNT_FOLDER_NOT_EMPTY_RETAINED_FOR_REVIEW'}
   }catch{Note ('MOUNT_FOLDER_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  Note ('RESULT='+$result)
  Note 'S31_S37_PROTECTED;NO_COPY_NO_MUTATION_NO_RAW_CARVE'
  Write-Host ('REPORT='+$log)
  Write-Host ('OWNERS_CSV='+$csv)
 }
 if($result -ne 'PASS_WEBVIEW_EDGE_S37_R1_REPARSE_AWARE_DISCOVERY_ONLY'){
  throw 'BL_WEBVIEW_EDGE_NATIVE_DISCOVERY_FAILED'
 }
}