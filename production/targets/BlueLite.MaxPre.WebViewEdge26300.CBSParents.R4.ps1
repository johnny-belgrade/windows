# BlueLite Germanium S37 R4: dynamically derive nine external CBS parent package identities
# from pinned R3 original evidence. Existing S37 WIM index1 READ-ONLY, copied SOFTWARE hive.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $r3txt=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.txt'
 $r3csv=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.csv'
 $image='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $imageHash='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $mount='C:\work\MWV26300R4'
 $copy=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_SOFTWARE_Copy_R4.dat'
 $log=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParentGate_R4.txt'
 $csv=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParents_R4.csv'
 $alias='HKLM\BLWEBR4'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
 foreach($path in @($mount,$copy,$log,$csv)){
  if(Test-Path -LiteralPath $path){throw ('BL_R4_NO_OVERWRITE='+$path)}
 }
 foreach($p in @(
  @{Path=$r3txt;Size=28421L;Sha='ED642AB518824526775BD9E46D9AC404418EDF2D21D37609AB023E46F7BD674F'},
  @{Path=$r3csv;Size=1405L;Sha='0998C6FFB7A9875C5F1A194982AD114D64B16FE48466860756B626F1317927AF'}
 )){
  $fi=Get-Item -LiteralPath $p.Path -Force -ErrorAction Stop
  if($fi.PSIsContainer -or $fi.Length -ne $p.Size -or
     (Get-FileHash -LiteralPath $p.Path -Algorithm SHA256).Hash -cne $p.Sha){
   throw ('BL_R3_ORIGINAL_PIN_MISMATCH='+$p.Path)
  }
 }
 $text=@([IO.File]::ReadAllLines($r3txt))
 $records=@(Import-Csv -LiteralPath $r3csv -Encoding utf8)
 if($text.Count -ne 179 -or
    $text -cnotcontains 'RESULT=PASS_WEBVIEW_EDGE_S37_R3_EIGHT_EXACT_CBS_REGISTRATION_READONLY_ONLY' -or
    $records.Count -ne 8 -or
    @($records|Where-Object {
      $_.RegQueryExit -cne '0' -or $_.OwnersQueryExit -cne '0' -or
      $_.DismGetPackageInfoExit -cne '0' -or $_.ReadonlyOnly -cne 'True'
    }).Count -ne 0 -or
    @($records|Where-Object {$_.DismPackageState -eq 'Installed'}).Count -ne 5 -or
    @($records|Where-Object {$_.DismPackageState -eq 'Staged'}).Count -ne 3 -or
    (@($records|Measure-Object -Property OwnersValues -Sum)[0].Sum -ne 11)){
  throw 'BL_R3_NATIVE_TIER_OR_TOPOLOGY_DRIFT'
 }
 # REG_RAW lines already authenticated through the original entire-report SHA pin.
 $edges=[System.Collections.Generic.List[object]]::new()
 $ownerRX='^REG_RAW=([^;]+);(\S+)\s+REG_DWORD\s+(0x[0-9a-fA-F]+)$'
 $parentRX='^(?:Package_for_RollupFix|Runlevel-Win4-Package|Microsoft-Windows-Desktop-Required-ClientOnly(?:-SharedWithServer)?-removable-Package)~31bf3856ad364e35~amd64~'
 foreach($line in $text){
  if($line -cmatch $ownerRX){
   $child=$Matches[1];$parent=$Matches[2];$state=$Matches[3]
   if($parent -match $parentRX){
    if($child -notin @($records|ForEach-Object {$_.PackageIdentity})){
     throw 'BL_OWNER_CHILD_NOT_IN_PINNED_R3_CSV'
    }
    $edges.Add([pscustomobject]@{Child=$child;Parent=$parent;ParentOwnerValue=$state})
   }
  }
 }
 $parents=@($edges|Select-Object -ExpandProperty Parent -Unique|Sort-Object)
 if($edges.Count -ne 9 -or $parents.Count -ne 9 -or
   @($parents|Where-Object {$_ -like 'Package_for_RollupFix~*'}).Count -ne 1 -or
   @($parents|Where-Object {$_ -like 'Runlevel-Win4-Package~*'}).Count -ne 4 -or
   @($parents|Where-Object {$_ -like 'Microsoft-Windows-Desktop-Required-*'}).Count -ne 4){
  throw ('BL_R3_EXTERNAL_PARENT_SET_DRIFT='+$parents.Count+'_'+$edges.Count)
 }
 $probe=@(& $reg query $alias 2>&1|ForEach-Object {[string]$_})
 if([int]$LASTEXITCODE -ne 1){throw 'BL_R4_TRANSIENT_HIVE_ALIAS_NOT_ABSENT'}
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$line){
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function NativeDism([string]$stage,[string[]]$arguments){
  $reply=@(& $dism @arguments 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $body=$reply -join [Environment]::NewLine
  if($exit -ne 0 -or $body -notmatch '(?i)The operation completed successfully\.' -or
    $body -match '(?im)^\s*Error\s*:'){
   throw ('BL_R4_NATIVE_DISM_'+$stage+'_EXIT='+$exit)
  }
  return $body
 }
 $mounted=$false
 $attempted=$false
 $created=$false
 $copied=$false
 $hiveLoaded=$false
 $result='HOLD_S37_R4_PARENT_GATE'
 $out=[System.Collections.Generic.List[object]]::new()
 try {
  Note 'BLUELITE_S37_WEBVIEW_R4_NINE_EXACT_PARENT_CBS_STATE_READONLY'
  Note 'ORIGINAL_R3_TXT_PIN=PASS;ED642AB518824526775BD9E46D9AC404418EDF2D21D37609AB023E46F7BD674F'
  Note 'ORIGINAL_R3_CSV_PIN=PASS;0998C6FFB7A9875C5F1A194982AD114D64B16FE48466860756B626F1317927AF'
  Note ('R3_EXACT_EXTERNAL_OWNER_EDGES='+$edges.Count+';DISTINCT_PARENTS='+$parents.Count)
  $source=Get-Item -LiteralPath $image -Force -ErrorAction Stop
  if($source.PSIsContainer -or $source.Length -ne 6551362129L -or
     ($source.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -cne $imageHash){
   throw 'BL_S37_PROTECTED_WIM_CHANGED'
  }
  Note ('S37_WIM_SHA256=PASS;'+$imageHash)
  $before=NativeDism 'PRE_MOUNTS' @('/English','/Get-MountedWimInfo')
  if(-not $before.Contains('No mounted images found.') -or
     $before -match '(?im)^\s*Mount Dir\s*:'){throw 'BL_R4_DISM_MOUNTS_NOT_ZERO'}
  $loaded=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($loaded|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_R4_BLUE_HIVE_ALIAS_PRESENT'
  }
  Note 'PRE_ZERO_MOUNTS_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true
  $attempted=$true
  $null=NativeDism 'READONLY_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$image),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'S37_NATIVE_READONLY_MOUNT=PASS'
  $software=Join-Path $mount 'Windows\System32\config\SOFTWARE'
  $si=Get-Item -LiteralPath $software -Force -ErrorAction Stop
  if($si.PSIsContainer -or $si.Length -le 0 -or $si.Length -gt 1073741824L){
   throw 'BL_R4_SOFTWARE_METADATA_INVALID'
  }
  $copied=$true
  Copy-Item -LiteralPath $software -Destination $copy -ErrorAction Stop
  if((Get-Item -LiteralPath $copy).Length -ne $si.Length){throw 'BL_R4_SOFTWARE_COPY_SIZE_DRIFT'}
  $softwareHash=(Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash
  if($si.Length -ne 76808192L -or $softwareHash -cne 'D913FC14F2A3759C64B93D504A1CD5871586E29FF1F3743BF274139C5316FBBC'){
   throw 'BL_R4_SOFTWARE_COPY_PIN_DRIFT'
  }
  Note ('COPIED_SOFTWARE_SHA=PASS;'+$softwareHash)
  $reply=@(& $reg load $alias $copy 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0){throw 'BL_R4_COPIED_HIVE_LOAD_FAILED'}
  $hiveLoaded=$true
  Note 'COPIED_SOFTWARE_HIVE_LOAD=PASS'
  $base=$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  foreach($parent in $parents){
   $ref=@($edges|Where-Object {$_.Parent -ceq $parent})
   $lines=@(& $reg query ($base+'\'+$parent) 2>&1|ForEach-Object {[string]$_})
   $regExit=[int]$LASTEXITCODE
   if($regExit -notin @(0,1)){throw ('BL_R4_PARENT_CBS_REG_EXIT='+$regExit+'_'+$parent)}
   $state='NOT_RETURNED'
   $vis='NOT_RETURNED'
   foreach($line in $lines){
    if($line -match '(?i)^\s*CurrentState\s+REG_\w+\s+(.+)$'){$state=$Matches[1].Trim()}
    if($line -match '(?i)^\s*Visibility\s+REG_\w+\s+(.+)$'){$vis=$Matches[1].Trim()}
   }
   $native=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$parent) 2>&1|
    ForEach-Object {[string]$_})
   $dismExit=[int]$LASTEXITCODE
   $nativeState='NOT_RETURNED'
   $release='NOT_RETURNED'
   $errorCode='NOT_RETURNED'
   foreach($line in $native){
    if($line -match '(?i)^\s*State\s*:\s*(.+)$'){$nativeState=$Matches[1].Trim()}
    if($line -match '(?i)^\s*Release Type\s*:\s*(.+)$'){$release=$Matches[1].Trim()}
    if($line -match '(?i)^\s*Error\s*:\s*(.+)$'){$errorCode=$Matches[1].Trim()}
   }
   Note ('PARENT='+$parent+';REG_EXIT='+$regExit+';CBS_STATE='+$state+';VIS='+$vis+
    ';DISM_EXIT='+$dismExit+';DISM_STATE='+$nativeState+';RELEASE_TYPE='+$release+
    ';NATIVE_ERROR='+$errorCode)
   foreach($item in $ref){Note ('EDGE='+$item.Child+' -> '+$parent+';OWNER_DWORD='+$item.ParentOwnerValue)}
   $out.Add([pscustomobject]@{
    ParentIdentity=$parent;ChildCount=$ref.Count;DirectChildIdentities=($ref.Child -join '|')
    R3OwnerDword=($ref.ParentOwnerValue -join '|');CBSRegistryExit=$regExit
    CBSCurrentState=$state;CBSVisibility=$vis;DismPackageInfoExit=$dismExit
    DismState=$nativeState;DismReleaseType=$release;DismError=$errorCode
    ImageMutated=$false
   })
  }
  if($out.Count -ne 9){throw 'BL_R4_PARENT_SCOPE_INCOMPLETE'}
  $out|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation -ErrorAction Stop
  Note ('NATIVE_PARENT_QUERIES='+$out.Count)
  Note 'PARENT_STATE_READONLY_ONLY;NO_PARENT_CHANGES_NO_CBS_COMPONENT_OWNER_GRAPH_CERTIFICATION'
  Note 'S37_NO_MUTATION_NO_WIM_CLONE_NO_PACKAGE_REMOVAL_NO_SPACE_SAVINGS_PROOF'
  $result='PASS_WEBVIEW_S37_R4_NINE_PARENT_NATIVE_CBS_READONLY_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($hiveLoaded){
   try{
    $reply=@(& $reg unload $alias 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -ne 0){throw 'BL_R4_TEMP_HIVE_UNLOAD_FAILED'}
    $hiveLoaded=$false
    Note 'COPIED_HIVE_UNLOADED=PASS'
   }catch{
    $result='HOLD_R4_HIVE_HANDLE'
    Note ('CRITICAL_HIVE_UNLOAD_HOLD='+$_.Exception.Message)
   }
  }
  if($copied -and -not $hiveLoaded){
   try{
    if(Test-Path -LiteralPath $copy){Remove-Item -LiteralPath $copy -Force -ErrorAction Stop}
    Note 'OWNED_TEMP_SOFTWARE_COPY_REMOVED=PASS'
   }catch{
    $result='HOLD_R4_HIVE_COPY_CLEANUP'
    Note ('TEMP_HIVE_COPY_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($attempted){
   try{
    $status=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $status.Contains($mount)){
     $null=NativeDism 'READONLY_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'NATIVE_DISCARD=PASS'
    }
    $after=NativeDism 'POST_MOUNTS' @('/English','/Get-MountedWimInfo')
    if(-not $after.Contains('No mounted images found.')){throw 'BL_R4_POST_DISM_MOUNT_REMAINS'}
    $mounted=$false
    Note 'POST_DISM_MOUNTS_ZERO=PASS'
   }catch{
    $result='HOLD_R4_NATIVE_MOUNT_CLEANUP'
    $mounted=$true
    Note ('CRITICAL_MOUNT_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_MOUNT_DIR_REMOVED=PASS'
    }else{Note 'OWNED_NONEMPTY_MOUNT_DIR_KEPT_FOR_REVIEW'}
   }catch{Note ('OWNED_FOLDER_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note ('CSV='+$csv)
  Note 'S31_S37_IMMUTABLE;NO_COPY_OF_WIM_NO_MUTATION'
 }
 if($result -ne 'PASS_WEBVIEW_S37_R4_NINE_PARENT_NATIVE_CBS_READONLY_ONLY'){
  throw 'BL_R4_SCOPED_PARENT_GATE_READONLY_FAILED'
 }
}
