# BlueLite Germanium 26300 S39 R7: native post-COMMIT read-only verification of WebView FoD removal.
# Only reads the existing committed S39 and protected S37. No WIM clone or servicing mutation.
& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_PS7_REQUIRED'}
 $user=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_ADMIN_REQUIRED'}
 $logs='C:\work\logs'
 $source='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $s39dir='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6'
 $s39=Join-Path $s39dir 'install.webview-disposable.wim'
 $mount='C:\work\MWV26300R7'
 $out=Join-Path $logs 'BlueLite_MAXPRE_WebViewEdge_26300.9711_PostCommit_R7.txt'
 $r4=Join-Path $logs 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSParents_R4.csv'
 $r3=Join-Path $logs 'BlueLite_MAXPRE_WebViewEdge_26300.9711_CBSRegistration_R3.csv'
 $r6=Join-Path $logs 'BlueLite_MAXPRE_WebViewEdge_26300.9711_NativeRemoval_R6R1.txt'
 $originalHash='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $committedHash='32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED'
 $cap='Edge.Webview2.Platform~~~~'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'BL_R7_LOG_DIRECTORY_MISSING'}
 foreach($p in @($mount,$out)){if(Test-Path -LiteralPath $p){throw ('BL_R7_NO_OVERWRITE='+$p)}}
 foreach($pin in @(
  @{Path=$r4;Length=2565L;Hash='CBA75A6D4778CC34FD1C19A6A256C52B69DC3C059F040E4DA9A7FBEEAF80650F'},
  @{Path=$r3;Length=1405L;Hash='0998C6FFB7A9875C5F1A194982AD114D64B16FE48466860756B626F1317927AF'},
  @{Path=$r6;Length=6860L;Hash='673E04082074A027BFE9C597737E0D28070B1DA7D957534A9939B56DC199D72D'}
 )){
  $f=Get-Item -LiteralPath $pin.Path -Force -ErrorAction Stop
  if($f.PSIsContainer -or $f.Length -ne $pin.Length -or
     (Get-FileHash -LiteralPath $pin.Path -Algorithm SHA256).Hash -cne $pin.Hash){
    throw ('BL_R7_EVIDENCE_SHA_SIZE_DRIFT='+$pin.Path)
  }
 }
 $proof=[IO.File]::ReadAllText($r6)
 foreach($p in @(
  'RESULT=PASS_S39_R6R1_NATIVE_WEBVIEW_DISPOSABLE_PRECOMMIT_POSTSTATE_AND_COMMIT_ONLY',
  'DISM_REMOVE_CAPABILITY_EXIT=0;COMPLETED=PASS',
  'CAPABILITY_AFTER=Edge.Webview2.Platform~~~~;STATE=Not Present',
  'THREE_EXACT_FOD_PACKAGE_IDENTITIES_NONRESOLVING=PASS',
  'PROTECTED_NINE_PARENTS_POST=PASS_PACKAGE_CBS_DERIVED',
  'CBS_ScanHealth_POST=CLEAN',
  'OWNED_DISPOSABLE_NATIVE_COMMIT=PASS',
  'PROTECTED_S37_POST_SHA256=PASS',
  ('DISPOSABLE_WIM_AFTER_SHA256='+$committedHash)
 )){
  if(-not $proof.Contains($p)){throw ('BL_R7_OPERATOR_R6R1_PROOF_MISSING='+$p)}
 }
 $pr=@(Import-Csv -LiteralPath $r4 -Encoding utf8)
 $fod=@(Import-Csv -LiteralPath $r3 -Encoding utf8|Where-Object {
   $_.PackageIdentity -match '^Microsoft-Edge-WebView-FOD-Package(?:-Wrapper)?~'
 })
 if($pr.Count -ne 9 -or @($pr|Select-Object -ExpandProperty ParentIdentity -Unique).Count -ne 9 -or
    $fod.Count -ne 3 -or
    @($pr|Where-Object {$_.DismPackageInfoExit -cne '0' -or $_.CBSRegistryExit -cne '0'}).Count -ne 0){
   throw 'BL_R7_R4_R3_EXACT_SCOPE_DRIFT'
 }
 $d=Get-Item -LiteralPath $s39dir -Force -ErrorAction Stop
 if(-not $d.PSIsContainer -or ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
  throw 'BL_R7_OWNED_S39_DIRECTORY_NOT_ORDINARY'
 }
 $items=@(Get-ChildItem -LiteralPath $s39dir -Force -ErrorAction Stop)
 if($items.Count -ne 1 -or $items[0].FullName -cne $s39 -or $items[0].PSIsContainer -or
    ($items[0].Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
  throw 'BL_R7_S39_OWNED_CONTENT_UNEXPECTED'
 }
 [IO.File]::WriteAllText($out,'',$utf8)
 function Note([string]$line){
  Write-Host $line
  [IO.File]::AppendAllText($out,$line+[Environment]::NewLine,$utf8)
 }
 function DismOK([string]$tag,[string[]]$dismArgs){
  $lines=@(& $dism @dismArgs 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $joined=$lines -join [Environment]::NewLine
  if($code -ne 0 -or
     $joined -match '(?im)^\s*Error\s*:' -or
     $joined -notmatch '(?i)The operation completed successfully\.'){
    foreach($line in $lines){Note ('DISM_'+$tag+'_RAW='+$line)}
    throw ('BL_R7_DISM_'+$tag+'_EXIT='+$code)
  }
  return $joined
 }
 function ZeroMounts([string]$stage){
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $empty=@($lines|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $listed=@($lines|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('DISM_MOUNT_'+$stage+'_EXIT='+$code+';EMPTY='+$empty+';LISTED='+$listed)
  if($code -ne 0 -or $empty -ne 1 -or $listed -ne 0){
   foreach($line in $lines){Note ('DISM_MOUNT_'+$stage+'_RAW='+$line)}
   throw ('BL_R7_NATIVE_MOUNTS_NOT_ZERO_'+$stage)
  }
 }
 function NativeState([string]$text){
  # Only the first package State, not optional-feature entries later in Get-PackageInfo.
  $m=[regex]::Match($text,'(?im)^\s*State\s*:\s*(.+?)\s*$')
  if(-not $m.Success){throw 'BL_R7_NATIVE_STATE_ABSENT'}
  return $m.Groups[1].Value.Trim()
 }
 function CapState(){
  $raw=DismOK 'EXACT_CAPABILITY' @('/English',('/Image:'+$mount),'/Get-CapabilityInfo',('/CapabilityName:'+$cap))
  $m=[regex]::Match($raw,'(?im)^\s*Capability Identity\s*:\s*(.+?)\s*$')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $cap){
   throw 'BL_R7_EXACT_HIDDEN_CAPABILITY_IDENTITY_DRIFT'
  }
  return (NativeState $raw)
 }
 function PackageState([string]$id){
  $raw=DismOK 'EXACT_PARENT' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$id))
  $m=[regex]::Match($raw,'(?im)^\s*Package Identity\s*:\s*(.+?)\s*$')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $id){
   throw ('BL_R7_PACKAGE_IDENTITY_DRIFT='+$id)
  }
  return (NativeState $raw)
 }
 $mounted=$false
 $attempt=$false
 $created=$false
 $result='HOLD_R7_POSTCOMMIT_READONLY'
 try{
  Note 'BLUELITE_S39_R7_NATIVE_WEBVIEW_POSTCOMMIT_READONLY_AUDIT'
  Note 'OPERATOR_R6R1_TXT_R4CSV_R3CSV_ORIGINAL_SHA_PINS=PASS'
  $sourceFi=Get-Item -LiteralPath $source -Force -ErrorAction Stop
  $fi=Get-Item -LiteralPath $s39 -Force -ErrorAction Stop
  if($sourceFi.PSIsContainer -or $sourceFi.Length -ne 6551362129L -or
     ($sourceFi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $originalHash){
   throw 'BL_R7_PROTECTED_S37_WIM_SHA_SIZE_CHANGED'
  }
  if($fi.PSIsContainer -or $fi.Length -ne 6595075169L -or
     ($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $s39 -Algorithm SHA256).Hash -cne $committedHash){
   throw 'BL_R7_COMMITTED_S39_WIM_SHA_SIZE_CHANGED'
  }
  Note ('S37_SOURCE_SHA=PASS;'+$originalHash)
  Note ('S39_POSTCOMMIT_WIM_SHA=PASS;'+$committedHash+';BYTES='+$fi.Length)
  ZeroMounts 'PRE'
  $hive=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($hive|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
    throw 'BL_R7_PREEXISTING_BL_HIVE_ALIAS'
  }
  Note 'PRE_ZERO_MOUNTS_AND_HIVES=PASS'
  [void][IO.Directory]::CreateDirectory($mount)
  $created=$true
  $attempt=$true
  $null=DismOK 'S39_RO_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$s39),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true
  Note 'S39_INDEPENDENT_POSTCOMMIT_NATIVE_READONLY_MOUNT=PASS'
  $cs=CapState
  Note ('POSTCOMMIT_CAPABILITY='+$cap+';STATE='+$cs)
  if($cs -cne 'Not Present'){throw 'BL_R7_POSTCOMMIT_CAPABILITY_NOT_ABSENT'}
  foreach($pkg in $fod){
   $id=$pkg.PackageIdentity
   $native=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$id) 2>&1|
     ForEach-Object {[string]$_})
   $code=[int]$LASTEXITCODE
   $txt=$native -join [Environment]::NewLine
   Note ('POSTCOMMIT_FOD='+$id+';DISM_EXIT='+$code)
   if($code -ne -2146498555 -or $txt -notmatch '(?i)0x800f0805'){
    foreach($line in $native){Note ('POSTCOMMIT_FOD_NATIVE_RAW='+$line)}
    throw ('BL_R7_POSTCOMMIT_FOD_PRESENT_OR_WRONG_EXIT='+$id)
   }
  }
  Note 'POSTCOMMIT_THREE_EXACT_FOD_PACKAGES_NONRESOLVING=PASS'
  $seen=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach($p in $pr){
   $id=$p.ParentIdentity
   if(-not $seen.Add($id)){throw 'BL_R7_DUPLICATE_PARENT'}
   $expected=switch -CaseSensitive ($p.CBSCurrentState){
    '0x40' {'Staged';break}
    '0x70' {'Installed';break}
    default {throw ('BL_R7_CBS_EXPECTATION_UNKNOWN='+$p.CBSCurrentState)}
   }
   $actual=PackageState $id
   Note ('POSTCOMMIT_PARENT='+$id+';STATE='+$actual+';EXPECTED='+$expected+
    ';CBS='+$p.CBSCurrentState+';R4_LAST_STATE='+$p.DismState)
   if($actual -cne $expected){throw ('BL_R7_POSTCOMMIT_PARENT_STATE_DRIFT='+$id)}
  }
  if($seen.Count -ne 9){throw 'BL_R7_INCOMPLETE_PARENT_SET'}
  Note 'POSTCOMMIT_NINE_PARENTS_NATIVE_PACKAGE_STATE=PASS'
  $pkgList=DismOK 'POSTCOMMIT_PENDING_PACKAGES' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pending=@([regex]::Matches($pkgList,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$'))
  $pendingXml=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('POSTCOMMIT_PENDING_NATIVE='+$pending.Count+';PENDING_XML='+$pendingXml)
  if($pending.Count -ne 0 -or $pendingXml){throw 'BL_R7_POSTCOMMIT_PENDING_STATE'}
  $health=DismOK 'POSTCOMMIT_CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){
   throw 'BL_R7_POSTCOMMIT_CHECKHEALTH_NOT_CLEAN'
  }
  Note 'POSTCOMMIT_CHECKHEALTH=CLEAN'
  $winSxS=Join-Path $mount 'Windows\WinSxS'
  $componentDirs=@(Get-ChildItem -LiteralPath $winSxS -Directory -Force -ErrorAction Stop|
    Where-Object {$_.Name -like 'amd64_microsoft-edge-webview_*'})
  Note ('POSTCOMMIT_EXACT_EDGE_WEBVIEW_COMPONENT_DIRS='+$componentDirs.Count)
  foreach($folder in $componentDirs){Note ('POSTCOMMIT_EDGE_WEBVIEW_COMPONENT_DIR='+$folder.Name)}
  Note 'COMPONENT_DIR_COUNT_IS_METADATA_NOT_PHYSICAL_BYTES_OR_OTHER_SHARED_WEBVIEW2_CLEANUP'
  Note 'R7_NO_CLONE_NO_MUTATION_NO_REPACK_NO_HOST_OS_CHANGES'
  $result='PASS_S39_R7_WEBVIEW_INDEPENDENT_POSTCOMMIT_READONLY_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($attempt){
   try{
    $status=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_}) -join [Environment]::NewLine
    if($mounted -or $status.Contains($mount)){
     $null=DismOK 'S39_RO_DISCARD' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
     Note 'S39_NATIVE_READONLY_DISCARD=PASS'
    }
    ZeroMounts 'POST'
    $mounted=$false
    Note 'POST_DISM_MOUNTS_ZERO=PASS'
   }catch{
    $mounted=$true
    $result='HOLD_R7_RO_MOUNT_CLEANUP'
    Note ('CRITICAL_RO_MOUNT_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if($created -and -not $mounted){
   try{
    if((Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop|Measure-Object).Count -eq 0){
     [IO.Directory]::Delete($mount,$false)
     Note 'OWNED_EMPTY_RO_MOUNT_DIRECTORY_REMOVED=PASS'
    }else{
     $result='HOLD_R7_OWNED_RO_MOUNT_DIRECTORY'
     Note 'OWNED_NONEMPTY_RO_MOUNT_DIR_HELD'
    }
   }catch{
    $result='HOLD_R7_OWNED_RO_DIR_CLEANUP'
    Note ('OWNED_RO_DIR_CLEANUP_HOLD='+$_.Exception.Message)
   }
  }
  if(-not $mounted -and $attempt){
   try{
    if((Get-FileHash -LiteralPath $s39 -Algorithm SHA256).Hash -cne $committedHash){
     throw 'BL_R7_S39_POST_RO_HASH_CHANGED'
    }
    if((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -cne $originalHash){
     throw 'BL_R7_S37_POST_RO_HASH_CHANGED'
    }
    Note 'POST_RO_S39_AND_PROTECTED_S37_FULL_SHA=PASS'
   }catch{
    $result='HOLD_R7_SOURCE_OR_DISPOSABLE_HASH_DRIFT'
    Note ('CRITICAL_POST_RO_HASH_HOLD='+$_.Exception.Message)
   }
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$out)
  Note 'PROTECTED_S31_S37_UNMODIFIED;S39_COMMITTED_RETAINED;NO_RELEASE_OR_PHYSICAL_SAVINGS_CERT'
 }
 if($result -ne 'PASS_S39_R7_WEBVIEW_INDEPENDENT_POSTCOMMIT_READONLY_ONLY'){
  throw 'BL_R7_INDEPENDENT_POSTCOMMIT_AUDIT_HOLD'
 }
}
