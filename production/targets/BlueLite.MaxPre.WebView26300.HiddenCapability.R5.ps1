# BlueLite S37 WebView R5 - exact historical hidden FoD capability contract on 26300.
# Native DISM read-only on retained S37; direct capability/three known FoD package details ONLY.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $pr=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $pr.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $root='C:\work\logs'
 $r3csv=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.csv'
 $r4txt=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParentGate_R4.txt'
 $r4csv=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParents_R4.csv'
 $image='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $imageSHA='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $mount='C:\work\MWV26300R5'
 $log=Join-Path $root 'BlueLite_MAXPRE_WebViewEdge_26300.9711_HiddenCapability_R5.txt'
 $capability='Edge.Webview2.Platform~~~~'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_LOG_ROOT_MISSING'}
 foreach($path in @($mount,$log)){if(Test-Path -LiteralPath $path){throw ('BL_R5_PATH_EXISTS='+$path)}}
 $pins=@(
   @{Path=$r3csv;Size=1405L;SHA='0998C6FFB7A9875C5F1A194982AD114D64B16FE48466860756B626F1317927AF'},
   @{Path=$r4txt;Size=4897L;SHA='E0C661061D64E3C85258CDE34B69D42A5A29D9C4F61CAFA4F910FBC4BFF44848'},
   @{Path=$r4csv;Size=2565L;SHA='CBA75A6D4778CC34FD1C19A6A256C52B69DC3C059F040E4DA9A7FBEEAF80650F'}
 )
 foreach($pin in $pins){
  $file=Get-Item -LiteralPath $pin.Path -Force -ErrorAction Stop
  if($file.PSIsContainer -or $file.Length -ne $pin.Size -or
    (Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash -cne $pin.SHA){
    throw ('BL_R5_ORIGINAL_EVIDENCE_DRIFT='+$pin.Path)
  }
 }
 $r3=@(Import-Csv -LiteralPath $r3csv -Encoding utf8)
 $r4=@(Import-Csv -LiteralPath $r4csv -Encoding utf8)
 $fos=@($r3|Where-Object {$_.PackageIdentity -match '^Microsoft-Edge-WebView-FOD-Package(?:-Wrapper)?~'})
 if($r3.Count -ne 8 -or $fos.Count -ne 3 -or
    @($fos|Where-Object {$_.DismGetPackageInfoExit -cne '0'}).Count -ne 0 -or
    @($fos|Where-Object {$_.DismPackageState -ceq 'Installed'}).Count -ne 2 -or
    @($fos|Where-Object {$_.DismPackageState -ceq 'Staged'}).Count -ne 1 -or
    $r4.Count -ne 9 -or
    @($r4|Where-Object {$_.CBSRegistryExit -cne '0' -or $_.DismPackageInfoExit -cne '0' -or $_.ImageMutated -cne 'False'}).Count -ne 0){
   throw 'BL_R5_PREVIOUS_NATIVE_TOPOLOGY_CHANGED'
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$line){
  Write-Host $line
  [IO.File]::AppendAllText($log,$line+[Environment]::NewLine,$utf8)
 }
 function Native([string]$label,[string[]]$args){
  $reply=@(& $dism @args 2>&1|ForEach-Object {[string]$_})
  $status=[int]$LASTEXITCODE
  $txt=$reply -join [Environment]::NewLine
  if($status -ne 0 -or $txt -notmatch '(?i)The operation completed successfully\.' -or
     $txt -match '(?im)^\s*Error\s*:'){
    throw ('BL_R5_DISM_'+$label+'_FAILED='+$status)
  }
  return $txt
 }
 $result='HOLD_R5_HIDDEN_CAPABILITY'
 $attempted=$false
 $mounted=$false
 $created=$false
 try{
  Note 'BLUELITE_26300_S37_R5_EXACT_HIDDEN_WEBVIEW_CAPABILITY_READONLY'
  foreach($pin in $pins){Note ('PREVIOUS_ORIGINAL_SHA=PASS;'+[IO.Path]::GetFileName($pin.Path)+';'+$pin.SHA)}
  $f=Get-Item -LiteralPath $image -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne 6551362129L -or
    ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
    (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash -cne $imageSHA){
   throw 'BL_R5_S37_PROTECTED_WIM_DRIFT'
  }
  Note ('S37_PROTECTED_WIM_SHA=PASS;'+$imageSHA)
  $mounts=Native 'ZERO_MOUNTS_PRE' @('/English','/Get-MountedWimInfo')
  if(-not $mounts.Contains('No mounted images found.') -or
    $mounts -match '(?im)^\s*Mount Dir\s*:'){throw 'BL_R5_DISM_MOUNT_ALREADY_PRESENT'}
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
    @($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
    throw 'BL_R5_PROJECT_HIVE_ALIAS_ALREADY_PRESENT'
  }
  Note 'PRE_ZERO_MOUNTS_AND_PROJECT_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true
  $attempted=$true
  $null=Native 'READONLY_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$image),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'NATIVE_READONLY_MOUNT=PASS'
  # This is the historically proven exact hidden identity, not Get-Capabilities name search.
  $details=Native 'EXACT_HIDDEN_CAPABILITY' @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$capability))
  $capIdent=@($details -split '\r?\n'|Where-Object {$_ -cmatch '^\s*Capability Identity\s*:'})
  $capState=@($details -split '\r?\n'|Where-Object {$_ -match '^\s*State\s*:'})
  if($capIdent.Count -ne 1 -or $capIdent[0].Split(':',2)[1].Trim() -cne $capability -or
     $capState.Count -ne 1){throw 'BL_R5_EXACT_CAPABILITY_IDENTITY_OR_STATE_MISSING'}
  $state=$capState[0].Split(':',2)[1].Trim()
  Note ('EXACT_CAPABILITY_IDENTITY='+$capability)
  Note ('EXACT_CAPABILITY_STATE='+$state)
  foreach($line in $details -split '\r?\n'){
   if($line -match '(?i)^\s*(Display Name|Download Size|Install Size)\s*:'){
    Note ('EXACT_CAPABILITY_DETAIL='+$line.Trim())
   }
  }
  if($state -cne 'Installed'){throw ('BL_R5_26300_HIDDEN_CAPABILITY_UNEXPECTED_STATE='+$state)}
  foreach($entry in @($fos|Sort-Object PackageIdentity)){
   $id=$entry.PackageIdentity
   $body=Native 'EXACT_FOD_PACKAGE' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$id))
   $identities=@($body -split '\r?\n'|Where-Object {$_ -cmatch '^\s*Package Identity\s*:'})
   $pkgStates=@($body -split '\r?\n'|Where-Object {$_ -match '^\s*State\s*:'})
   $pkgCaps=@($body -split '\r?\n'|Where-Object {$_ -match '^\s*Capability Identity\s*:'})
   if($identities.Count -ne 1 -or $identities[0].Split(':',2)[1].Trim() -cne $id -or
      $pkgStates.Count -ne 1){throw ('BL_R5_PACKAGE_INFO_DRIFT='+$id)}
   $ps=$pkgStates[0].Split(':',2)[1].Trim()
   if($ps -cne $entry.DismPackageState){throw ('BL_R5_PACKAGE_STATE_CHANGED='+$id)}
   $namedCap=if($pkgCaps.Count -eq 1){$pkgCaps[0].Split(':',2)[1].Trim()}else{'UNRESOLVED'}
   Note ('FOD_PACKAGE='+$id+';STATE='+$ps+';CAPABILITY='+$namedCap)
   if($id -match '^Microsoft-Edge-WebView-FOD-Package~' -and $namedCap -cne $capability){
    throw ('BL_R5_CHILD_CAPABILITY_LINK_NOT_MATCHED='+$id)
   }
  }
  Note 'REGRESSION_REUSE=LIBRARY_142_145_148;CURRENT_IMAGE_NATIVE_MATCH_ONLY'
  Note 'NO_WIM_COPY_NO_MUTATION_NO_REMOVAL_NO_SAVINGS_ASSUMED'
  $result='PASS_S37_R5_EXACT_HIDDEN_EDGE_WEBVIEW_CAPABILITY_NATIVE_READONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($attempted){
   try{
    $stateNow=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $stateNow.Contains($mount)){
     $null=Native 'READONLY_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'NATIVE_DISCARD=PASS'
    }
    $after=Native 'ZERO_MOUNTS_POST' @('/English','/Get-MountedWimInfo')
    if(-not $after.Contains('No mounted images found.')){throw 'BL_R5_DISM_MOUNTS_REMAIN'}
    $mounted=$false
    Note 'POST_ZERO_MOUNTS=PASS'
   }catch{
    $mounted=$true
    $result='HOLD_R5_MOUNT_CLEANUP'
    Note ('CRITICAL_MOUNT_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_MOUNT_DIRECTORY_REMOVED=PASS'
    }else{Note 'OWNED_NONEMPTY_MOUNT_DIRECTORY_RETAINED_FOR_REVIEW'}
   }catch{
    Note ('OWNED_DIR_CLEANUP_HOLD='+$_.Exception.Message)
    $result='HOLD_R5_OWNED_DIRECTORY_CLEANUP'
   }
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note 'S31_S37_PROTECTED;NO_WIM_CLONE_NO_MUTATION'
 }
 if($result -ne 'PASS_S37_R5_EXACT_HIDDEN_EDGE_WEBVIEW_CAPABILITY_NATIVE_READONLY'){
  throw 'BL_R5_26300_HIDDEN_CAPABILITY_GATE_HOLD'
 }
}
