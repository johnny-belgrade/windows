# BlueLite S37 WebView/Edge R3: eight exact MUM identities -> DISM package + copied-offline-SOFTWARE CBS registrations.
# Read-only image mount; reg load operates exclusively on copied hive in C:\work\logs. No servicing mutation.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $image='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $imageHash='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $previous=@(
  @{Path=(Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_ServicingOwners_R2.txt');Size=2893L;SHA='BA43886C7111B8DA9AA7A5A8CAEAB968D4AC48BE76BECD48B7F37FCB1271DE1E'},
  @{Path=(Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_ServicingMetadata_R2.csv');Size=1949L;SHA='3965B7B66C6841F99A375160534BB976DB3EE82CF76E8AE8BA57EAF5E0F0745E'}
 )
 $mount='C:\work\MWV26300R3'
 $copy=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_SOFTWARE_Copy_R3.dat'
 $log=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.txt'
 $csv=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.csv'
 $alias='HKLM\BLWEBR3'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
 foreach($p in @($mount,$copy,$log,$csv)){
  if(Test-Path -LiteralPath $p){throw ('BL_R3_NO_OVERWRITE='+$p)}
 }
 $pins=@()
 foreach($item in $previous){
  $f=Get-Item -LiteralPath $item.Path -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne $item.Size -or
     (Get-FileHash -LiteralPath $item.Path -Algorithm SHA256).Hash -cne $item.SHA){
   throw ('BL_R2_ORIGINAL_PIN_DRIFT='+$item.Path)
  }
  $pins+=($f.Name+':'+$item.SHA)
 }
 $prior=@(Import-Csv -LiteralPath $previous[1].Path -Encoding utf8)
 $mums=@($prior|Where-Object {$_.Kind -eq 'SERVICING_MUM_NAME'})
 if($prior.Count -ne 12 -or $mums.Count -ne 8 -or
   @($mums|Where-Object {$_.Present -cne 'True' -or $_.ContentRead -cne 'False' -or
    $_.Identity -notmatch '^Microsoft-[A-Za-z0-9-]+~31bf3856ad364e35~amd64~(?:en-US)?~10\.0\.26100\.\d+\.mum$'}).Count -ne 0 -or
   @($mums|Select-Object -ExpandProperty Identity -Unique).Count -ne 8 -or
   @($mums|Where-Object {$_.Identity -match 'Edge-WebView-FOD-Package'}).Count -ne 3 -or
   @($mums|Where-Object {$_.Identity -match 'OneCore-Edge-WebRuntime-Package'}).Count -ne 3 -or
   @($mums|Where-Object {$_.Identity -match 'MicrosoftEdgeDevToolsClient-Package'}).Count -ne 2){
  throw 'BL_R2_EIGHT_NAME_TOPOLOGY_CHANGED'
 }
 $preAlias=@(& $reg query $alias 2>&1|ForEach-Object {[string]$_})
 if([int]$LASTEXITCODE -eq 0){throw 'BL_TRANSIENT_HIVE_ALIAS_ALREADY_PRESENT'}
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$t){
  Write-Host $t
  [IO.File]::AppendAllText($log,$t+[Environment]::NewLine,$utf8)
 }
 function DismSuccess([string]$tag,[string[]]$callArguments){
  $data=@(& $dism @callArguments 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $joined=$data -join [Environment]::NewLine
  if($exit -ne 0 -or $joined -notmatch '(?i)The operation completed successfully\.' -or
     $joined -match '(?im)^\s*Error\s*:'){
   throw ('BL_NATIVE_DISM_'+$tag+'_FAILED='+$exit)
  }
  return $joined
 }
 $attempted=$false
 $mounted=$false
 $created=$false
 $hiveLoaded=$false
 $copied=$false
 $result='HOLD_WEBVIEW_EDGE_R3'
 $all=[System.Collections.Generic.List[object]]::new()
 try{
  Note 'BLUELITE_S37_WEBVIEW_EDGE_R3_EIGHT_EXACT_CBS_NATIVE_REGISTRATION_READONLY'
  foreach($pin in $pins){Note ('R2_EVIDENCE_PIN_PASS='+$pin)}
  $f=Get-Item -LiteralPath $image -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne 6551362129L -or
    ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
    (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -cne $imageHash){
   throw 'BL_PROTECTED_S37_WIM_IDENTITY_CHANGED'
  }
  Note ('S37_PROTECTED_WIM_SHA=PASS;'+$imageHash)
  $mounts=DismSuccess 'ZERO_MOUNT_PRE' @('/English','/Get-MountedWimInfo')
  if(-not $mounts.Contains('No mounted images found.') -or
     $mounts -match '(?im)^\s*Mount Dir\s*:'){throw 'BL_DISM_PREEXISTING_MOUNT'}
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
    @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_PREEXISTING_PROJECT_HIVE_ALIAS'
  }
  Note 'PRE_ZERO_MOUNTS_AND_PROJECT_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true
  $attempted=$true
  $null=DismSuccess 'READONLY_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$image),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'S37_NATIVE_READONLY_MOUNT=PASS'
  $offlineSoftware=Join-Path $mount 'Windows\System32\config\SOFTWARE'
  $sw=Get-Item -LiteralPath $offlineSoftware -Force -ErrorAction Stop
  if($sw.PSIsContainer -or $sw.Length -le 0 -or $sw.Length -gt 1073741824L){
   throw 'BL_OFFLINE_SOFTWARE_METADATA_INVALID'
  }
  Copy-Item -LiteralPath $offlineSoftware -Destination $copy -ErrorAction Stop
  $copied=$true
  if((Get-Item -LiteralPath $copy).Length -ne $sw.Length){throw 'BL_COPIED_SOFTWARE_SIZE_MISMATCH'}
  Note ('COPIED_OFFLINE_SOFTWARE_BYTES='+$sw.Length)
  Note ('COPIED_SOFTWARE_SHA256='+(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash)
  $load=@(& $reg load $alias $copy 2>&1|ForEach-Object {[string]$_})
  $loadExit=[int]$LASTEXITCODE
  if($loadExit -ne 0){throw ('BL_REG_LOAD_OFFLINE_COPY_FAILED='+$loadExit)}
  $hiveLoaded=$true
  Note 'OFFLINE_COPIED_SOFTWARE_HIVE_LOADED=PASS'
  $cbsRoot=$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  foreach($entry in $mums){
   $id=$entry.Identity.Substring(0,$entry.Identity.Length-4)
   $key=$cbsRoot+'\'+$id
   $regLines=@(& $reg query $key 2>&1|ForEach-Object {[string]$_})
   $regExit=[int]$LASTEXITCODE
   $ownersLines=@(& $reg query ($key+'\Owners') 2>&1|ForEach-Object {[string]$_})
   $ownersExit=[int]$LASTEXITCODE
   if($regExit -notin @(0,1) -or $ownersExit -notin @(0,1) -or
     (@($regLines)+@($ownersLines) -join ' ') -match '(?i)access is denied|access denied'){
    throw ('BL_CBS_REGISTRY_NATIVE_ERROR='+$id)
   }
   $state='NOT_RETURNED'
   $vis='NOT_RETURNED'
   foreach($line in $regLines){
    if($line -match '(?i)^\s*CurrentState\s+REG_\w+\s+(.+)$'){$state=$Matches[1].Trim()}
    if($line -match '(?i)^\s*Visibility\s+REG_\w+\s+(.+)$'){$vis=$Matches[1].Trim()}
   }
   $ownNames=@($ownersLines|Where-Object {$_ -match '^\s*HKEY_LOCAL_MACHINE\\' -and $_ -match '\\Owners\\'})
   $ownVals=@($ownersLines|Where-Object {$_ -match '^\s*\S.+\s+REG_\w+\s+'})
   Note ('PACKAGE_CBS='+$id+';REG_EXIT='+$regExit+';CURRENT_STATE='+$state+
       ';VISIBILITY='+$vis+';OWNERS_EXIT='+$ownersExit+
       ';OWNERS_SUBKEYS='+$ownNames.Count+';OWNERS_VALUES='+$ownVals.Count)
   foreach($line in @($regLines)+@($ownersLines)){
    if($line.Trim().Length -gt 0){Note ('REG_RAW='+$id+';'+$line.Trim())}
   }
   $raw=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$id) 2>&1 |
     ForEach-Object {[string]$_})
   $nativeExit=[int]$LASTEXITCODE
   $pkgState='NOT_RETURNED'
   $reason='NOT_RETURNED'
   foreach($line in $raw){
    if($line -match '(?i)^\s*State\s*:\s*(.+)$'){$pkgState=$Matches[1].Trim()}
    if($line -match '(?i)^\s*Error\s*:\s*(.+)$'){$reason=$Matches[1].Trim()}
   }
   Note ('DISM_EXACT='+$id+';EXIT='+$nativeExit+';STATE='+$pkgState+';ERROR='+$reason)
   foreach($line in $raw){if($line -match '(?i)Package Identity|State\s*:|Release Type|Error\s*:|not found|completed successfully'){
      Note ('DISM_DETAIL='+$id+';'+$line.Trim())
   }}
   $all.Add([pscustomobject]@{
    PackageIdentity=$id;RegQueryExit=$regExit;CBSCurrentState=$state;CBSVisibility=$vis
    OwnersQueryExit=$ownersExit;OwnersSubkeys=$ownNames.Count;OwnersValues=$ownVals.Count
    DismGetPackageInfoExit=$nativeExit;DismPackageState=$pkgState;DismError=$reason
    ReadonlyOnly=$true
   })
  }
  if($all.Count -ne 8){throw 'BL_EIGHT_PACKAGE_RESOLUTION_INCOMPLETE'}
  $all|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation -ErrorAction Stop
  Note ('EXACT_PACKAGES_QUERIED='+$all.Count)
  Note ('REGISTRY_CBS_ROOT='+$cbsRoot)
  Note 'CBS_COMPONENT_OWNER_EDGES_NOT_YET_CERTIFIED;NO_REMOVAL_AUTHORIZED'
  Note 'NO_WIM_MUTATION_NO_CBS_EDIT_NO_SOURCE_CARVE_NO_HEALTH_OR_PENDING_CERTIFICATION'
  $result='PASS_WEBVIEW_EDGE_S37_R3_EIGHT_EXACT_CBS_REGISTRATION_READONLY_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($hiveLoaded){
   try{
    $unload=@(& $reg unload $alias 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -ne 0){throw 'BL_COPIED_HIVE_UNLOAD_FAILED'}
    $hiveLoaded=$false
    Note 'COPIED_OFFLINE_HIVE_UNLOADED=PASS'
   }catch{
    $result='HOLD_R3_OFFLINE_HIVE_CLEANUP'
    Note ('CRITICAL_HIVE_UNLOAD_HOLD='+$_.Exception.Message)
   }
  }
  if($copied -and -not $hiveLoaded){
   try{
    Remove-Item -LiteralPath $copy -Force -ErrorAction Stop
    Note 'OWNED_TEMP_SOFTWARE_COPY_REMOVED=PASS'
   }catch{
    $result='HOLD_R3_TEMP_HIVE_COPY_CLEANUP'
    Note ('TEMP_COPY_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($attempted){
   try{
    $state=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $state.Contains($mount)){
     $null=DismSuccess 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'NATIVE_READONLY_DISCARD=PASS'
    }
    $after=DismSuccess 'ZERO_MOUNTS_POST' @('/English','/Get-MountedWimInfo')
    if(-not $after.Contains('No mounted images found.')){throw 'BL_POST_MOUNTS_NONZERO'}
    $mounted=$false
    Note 'POST_ZERO_MOUNTS=PASS'
   }catch{
    $mounted=$true
    $result='HOLD_R3_MOUNT_CLEANUP'
    Note ('CRITICAL_MOUNT_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
    }else{Note 'OWNED_NONEMPTY_MOUNT_DIR_KEPT_FOR_REVIEW'}
   }catch{Note ('OWNED_MOUNT_FOLDER_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note ('CSV='+$csv)
  Note 'S31_S37_PROTECTED;NO_WIM_CLONE_NO_MUTATION'
 }
 if($result -ne 'PASS_WEBVIEW_EDGE_S37_R3_EIGHT_EXACT_CBS_REGISTRATION_READONLY_ONLY'){
  throw 'BL_S37_WEBVIEW_R3_SCOPED_READONLY_FAILED'
 }
}
