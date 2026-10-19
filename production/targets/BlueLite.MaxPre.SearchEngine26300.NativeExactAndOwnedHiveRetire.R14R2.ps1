# BlueLite R14R2: retire only proven R14R1 temporary SOFTWARE-copy artifacts,
# then native exact SearchEngine package status on original S41 /ReadOnly.
# NO CBS change, package removal, new WIM clone, export, or source mutation.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R14R2_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R14R2_ADMIN_REQUIRED'}
 $log='C:\work\logs\BlueLite_MAXPRE_SearchEngine_26300.9711_NativeExact_R14R2.txt'
 $prev='C:\work\logs\BlueLite_MAXPRE_SearchEngine_26300.9711_ReadOnly_R14R1.txt'
 $wim='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $temp='C:\work\E2E\BlueLite_R14R1_SearchGate_Temporary'
 $mount='C:\BLR14R2M'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $wimHash='378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1'
 $old='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1591'
 $current='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(Test-Path -LiteralPath $log){throw 'BL_R14R2_LOG_ALREADY_EXISTS'}
 if(Test-Path -LiteralPath $mount){throw 'BL_R14R2_OWNED_MOUNT_ALREADY_EXISTS'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_R14R2_LOG_DIR_MISSING'}
 $r=Get-Item -LiteralPath $prev -Force -ErrorAction Stop
 if($r.PSIsContainer -or $r.Length -ne 3107 -or
    (Get-FileHash -LiteralPath $prev -Algorithm SHA256).Hash -cne
    '9014DF6D0B328B83F81699E4FF315810B1C1767298A265D131E9F12C556D0813'){
   throw 'BL_R14R2_ORIGINAL_R14R1_RECEIPT_PIN_MISMATCH'
 }
 $raw=[IO.File]::ReadAllText($prev)
 foreach($tag in @(
  'RESULT=HOLD_R14R1_SEARCHENGINE_READONLY',
  'CBS_EXACT_SEARCHENGINE_REGISTRATIONS=2',
  'CBS_INSTALLED_REGISTERED_COUNT=1',
  'CBS_HISTORICAL_SINGLE_OWNER_SHAPE=PASS;'+$current,
  'TEMP_COPY_HIVE_LOAD=PASS',
  'OWNED_COPY_SOFTWARE_HIVE_UNLOADED=PASS',
  'TEMP_CLEANUP_HOLD=BL_R14R1_UNKNOWN_TEMP_HIVE_CONTENT',
  'MOUNTS_POST_EXIT=0;EMPTY=1;ROWS=0',
  'PROJECT_HIVES_POST_EXIT=0;MATCHES=0')){
  if(-not $raw.Contains($tag)){throw ('BL_R14R2_R14R1_SEMANTIC_DRIFT='+$tag)}
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$s){Write-Host $s;[IO.File]::AppendAllText($log,$s+[Environment]::NewLine,$utf8)}
 function Pin([string]$stage){
  $f=Get-Item -LiteralPath $wim -Force -ErrorAction Stop
  if($f.PSIsContainer -or
     ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     $f.Length -ne 6636510185L -or
     (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $wimHash){
   throw ('BL_R14R2_S41_FULL_PIN_FAILED_'+$stage)
  }
  Note ('S41_'+$stage+'_SHA_SIZE=PASS;BYTES=6636510185;SHA='+$wimHash)
 }
 function ZeroMounts([string]$stage){
  $rows=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $empty=@($rows|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $found=@($rows|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$stage+'_EXIT='+$ec+';EMPTY='+$empty+';ROWS='+$found)
  if($ec -ne 0 -or $empty -ne 1 -or $found -ne 0){throw ('BL_R14R2_MOUNTS_NOT_ZERO_'+$stage)}
 }
 function ZeroHives([string]$stage){
  $rows=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $found=@($rows|Where-Object {
   $_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(?:BL[0-9]|BLR|BLWEB|BlueLite|FB[0-9])'
  }).Count
  Note ('PROJECT_HIVES_'+$stage+'_EXIT='+$ec+';MATCHES='+$found)
  if($ec -ne 0 -or $found -ne 0){throw ('BL_R14R2_HIVES_PRESENT_'+$stage)}
 }
 function PlainDir([string]$path){
  $d=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if(-not $d.PSIsContainer -or
     ($d.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
   throw ('BL_R14R2_UNTRUSTED_DIRECTORY='+$path)
  }
 }
 function Native([string]$tag,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1|ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $body=$lines -join [Environment]::NewLine
  if($ec -ne 0 -or
     $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$tag+'_RAW='+$line)}
   throw ('BL_R14R2_NATIVE_'+$tag+'_EXIT='+$ec)
  }
  return $body
 }
 function ExactPackage([string]$id,[string]$label){
  $rows=@(& $dism /English ('/Image:'+$mount) /Get-PackageInfo ('/PackageName:'+$id) 2>&1 |
   ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $body=$rows -join [Environment]::NewLine
  if($ec -eq -2146498555 -and $body -match '(?i)0x800f0805'){
   Note ('NATIVE_EXACT_'+$label+'=NONRESOLVING_0x800f0805;ID='+$id)
   return 'NONRESOLVING'
  }
  if($ec -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $rows){Note ('DISM_EXACT_'+$label+'_RAW='+$line)}
   throw ('BL_R14R2_NATIVE_EXACT_'+$label+'_EXIT='+$ec)
  }
  $m=[regex]::Match($body,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $st=[regex]::Match($body,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $m.Success -or $m.Groups[1].Value.Trim() -cne $id -or -not $st.Success){
   throw ('BL_R14R2_NATIVE_ID_OR_STATE_MISMATCH_'+$label)
  }
  $state=$st.Groups[1].Value.Trim()
  Note ('NATIVE_EXACT_'+$label+'='+$state+';ID='+$id)
  return $state
 }
 $mounted=$false;$made=$false;$passed=$false
 $status='HOLD_R14R2_SEARCH_NATIVE_AND_EPHEMERAL_RETIRE'
 try{
  Note 'BLUELITE_S41_R14R2_SEARCHENGINE_NATIVE_EXACT_AND_ORPHAN_HIVE_RETIRE'
  Note 'ORIGINAL_R14R1_SHA_AND_CBS_RECEIPT=PASS'
  Pin 'PRE'
  ZeroMounts 'PRE'
  ZeroHives 'PRE'
  Note 'STEP_01_RECOVER_ONLY_R14R1_EXACT_EPHEMERAL_SOFTWARE_COPY'
  PlainDir 'C:\work'
  PlainDir 'C:\work\E2E'
  if(Test-Path -LiteralPath $temp){
   PlainDir $temp
   $items=@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop)
   Note ('R14R1_TEMP_ENTRY_COUNT='+$items.Count)
   if($items.Count -lt 1 -or $items.Count -gt 16){throw 'BL_R14R2_TEMP_UNEXPECTED_ENTRY_COUNT'}
   $rootName='SOFTWARE.readonlycopy.hiv'
   $guid='\{[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\}'
   $allowed='^'+[regex]::Escape($rootName)+'(?:\.LOG[12]?|'+$guid+'\.TM\.blf|'+$guid+'\.TMContainer[0-9]{20}\.regtrans-ms)?$'
   $total=0L
   foreach($item in $items){
    $isLink=(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
    $itemSize=if($item.PSIsContainer){-1}else{[long]$item.Length}
    Note ('R14R1_TEMP_ENTRY='+$item.Name+';BYTES='+$itemSize+';DIRECTORY='+$item.PSIsContainer+';REPARSE='+$isLink)
    if($item.PSIsContainer -or $isLink -or $item.Name -cnotmatch $allowed){
     throw ('BL_R14R2_UNRECOGNIZED_TEMP_FILE='+$item.Name)
    }
    if($item.Length -gt 120000000L){throw ('BL_R14R2_TEMP_FILE_TOO_LARGE='+$item.Name)}
    $total += [long]$item.Length
   }
   if($total -gt 200000000L){throw 'BL_R14R2_TEMP_TOTAL_EXCEEDS_BOUND'}
   foreach($item in $items){
    Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
    Note ('OWNED_TEMP_FILE_DELETED='+$item.Name)
   }
   if(@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop).Count -ne 0){
    throw 'BL_R14R2_OWNED_TEMP_NOT_EMPTY'
   }
   [IO.Directory]::Delete($temp,$false)
   Note 'R14R1_EPHEMERAL_FOLDER_REMOVED=PASS'
  }else{Note 'R14R1_EPHEMERAL_FOLDER_ALREADY_ABSENT=PASS'}
  ZeroMounts 'BEFORE_RO'
  ZeroHives 'BEFORE_RO'
  Note 'STEP_02_NATIVE_EXACT_TWO_CURRENT_BUILD_PACKAGE_INFO_READONLY'
  [void][IO.Directory]::CreateDirectory($mount);$made=$true
  $null=Native 'MOUNT_READONLY' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true;Note 'S41_MOUNT_READONLY=PASS'
  $oldState=ExactPackage $old 'OLD_1591'
  $currentState=ExactPackage $current 'CURRENT_9711'
  Note ('NATIVE_EXACT_PAIR=PASS;OLD='+$oldState+';CURRENT='+$currentState)
  $pending=Native 'PENDING' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $n=@([regex]::Matches($pending,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$')).Count
  $px=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING='+$n+';PENDING_XML='+$px)
  if($n -ne 0 -or $px){throw 'BL_R14R2_PENDING_NOT_ZERO'}
  $health=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($health -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R14R2_CHECKHEALTH_NOT_CLEAN'}
  Note 'CBS_CHECKHEALTH=CLEAN'
  $passed=$true
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  if(-not $mounted -and $made){
   try{
    $row=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -eq 0 -and ($row -join [Environment]::NewLine).Contains($mount)){
     $mounted=$true;Note 'RECOVER_OWNED_MOUNT_FROM_NATIVE_TABLE=TRUE'
    }
   }catch{$passed=$false;Note ('MOUNT_RECOVERY_HOLD='+$_.Exception.Message)}
  }
  if($mounted){
   try{
    $null=Native 'DISCARD_READONLY' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
    $mounted=$false;Note 'S41_READONLY_DISCARD=PASS'
   }catch{$passed=$false;Note ('MOUNT_DISCARD_HOLD='+$_.Exception.Message)}
  }
  try{ZeroMounts 'POST'}catch{$passed=$false;Note ('POST_MOUNTS_HOLD='+$_.Exception.Message)}
  try{ZeroHives 'POST'}catch{$passed=$false;Note ('POST_HIVES_HOLD='+$_.Exception.Message)}
  if($made -and -not $mounted){
   try{
    if(@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -ne 0){
     throw 'BL_R14R2_MOUNT_DIR_NOT_EMPTY'
    }
    [IO.Directory]::Delete($mount,$false);Note 'OWNED_EMPTY_RO_MOUNT_REMOVED=PASS'
   }catch{$passed=$false;Note ('OWNED_MOUNT_DIR_HOLD='+$_.Exception.Message)}
  }
  try{Pin 'POST'}catch{$passed=$false;Note ('S41_POST_PIN_HOLD='+$_.Exception.Message)}
  if($passed -and -not $mounted){$status='PASS_S41_R14R2_EPHEMERAL_HIVE_RETIRE_AND_NATIVE_EXACT_READONLY_ONLY'}
  Note ('RESULT='+$status)
  Note ('REPORT='+$log)
  Note 'NO_PACKAGE_REMOVAL_NO_CBS_WRITE_NO_SOURCE_MUTATION_NO_NEW_WIM'
 }
 if($status -ne 'PASS_S41_R14R2_EPHEMERAL_HIVE_RETIRE_AND_NATIVE_EXACT_READONLY_ONLY'){
  throw 'BL_R14R2_HOLD'
 }
}
