# BlueLite R15R1 - exact 26300 SearchEngine CBS Updates target/old/parent READONLY classification.
# Original operator R15 Updates strict-gate HOLD; no native removal or WIM cloning permitted.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R15R1_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R15R1_ADMIN_REQUIRED'}
 $wim='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $wimSha='378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1'
 $r15='C:\work\logs\BlueLite_MAXPRE_SearchEngine_26300.9711_NativeAmber_R15.txt'
 $log='C:\work\logs\BlueLite_MAXPRE_SearchEngine_26300.9711_UpdatesReadOnly_R15R1.txt'
 $s43='C:\work\E2E\BlueLite_Stage1_S43_26300.9711_SearchEngine_AMBER_R15'
 $mount='C:\BLR15R1M'
 $temp='C:\work\E2E\BlueLite_R15R1_SearchUpdates_Temporary'
 $copy=Join-Path $temp 'SOFTWARE.readonlycopy.hiv'
 $alias='BLR15R1SOFT'
 $old='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1591'
 $current='Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $parent='Microsoft-Windows-Client-Desktop-Required-Package04~31bf3856ad364e35~amd64~~10.0.26100.9711'
 $oldParent='Microsoft-Windows-Client-Desktop-Required-Package04~31bf3856ad364e35~amd64~~10.0.26100.1742'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_R15R1_LOG_DIR_MISSING'}
 foreach($p in @($log,$mount,$temp)){if(Test-Path -LiteralPath $p){throw ('BL_R15R1_NO_OVERWRITE='+$p)}}
 if(Test-Path -LiteralPath $s43){throw 'BL_R15R1_FAILED_S43_MUST_BE_ABSENT'}
 $f=Get-Item -LiteralPath $r15 -Force -ErrorAction Stop
 if($f.PSIsContainer -or $f.Length -ne 1596 -or
    (Get-FileHash -LiteralPath $r15 -Algorithm SHA256).Hash -cne
    'B04B5FE5BDE13943F0C2466AD186809687FDAE92F3F500506FC89DD992F48FE1'){
  throw 'BL_R15R1_R15_ORIGINAL_LOG_PIN_FAILED'
 }
 $original=[IO.File]::ReadAllText($r15)
 foreach($required in @(
  'RESULT=HOLD_R15_S43_SEARCH_AMBER_NATIVE',
  'FAIL_CLOSED=BL_R15_TARGET_UPDATES_NOT_EXACT_SINGLE_ZERO',
  'TARGET_CBS_PRE=STATE_0x70;VISIBILITY_0x2',
  'FAILED_DISPOSABLE_S43_CLONE_AND_WORKDIR_RETIRED=PASS',
  'MOUNTS_FINAL_EXIT=0;EMPTY=1;ROWS=0',
  'HIVES_FINAL_EXIT=0;COUNT=0'
 )){
  if(-not $original.Contains($required)){throw ('BL_R15R1_ORIGINAL_SEMANTIC_DRIFT='+$required)}
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$msg){
  Write-Host $msg
  [IO.File]::AppendAllText($log,$msg+[Environment]::NewLine,$utf8)
 }
 function PinSource([string]$stage){
  $x=Get-Item -LiteralPath $wim -Force -ErrorAction Stop
  if($x.PSIsContainer -or $x.Length -ne 6636510185L -or
     ($x.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $wimSha){
   throw ('BL_R15R1_S41_PIN_'+$stage)
  }
  Note ('S41_'+$stage+'_SHA_SIZE=PASS;BYTES=6636510185;SHA='+$wimSha)
 }
 function ZeroMounts([string]$stage){
  $a=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $none=@($a|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $rows=@($a|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$stage+'_EXIT='+$exit+';EMPTY='+$none+';ROWS='+$rows)
  if($exit -ne 0 -or $none -ne 1 -or $rows -ne 0){
   throw ('BL_R15R1_NONZERO_MOUNTS_'+$stage)
  }
 }
 function ZeroHives([string]$stage){
  $a=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $hits=@($a|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(?:BL[0-9]|BLR|BLWEB|BlueLite|FB[0-9])'}).Count
  Note ('PROJECT_HIVES_'+$stage+'_EXIT='+$exit+';MATCHES='+$hits)
  if($exit -ne 0 -or $hits -ne 0){throw ('BL_R15R1_LIVE_HIVE_'+$stage)}
 }
 function Native([string]$label,[string[]]$argv){
  $a=@(& $dism @argv 2>&1 | ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $body=$a -join [Environment]::NewLine
  if($exit -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $a){Note ('DISM_'+$label+'_RAW='+$line)}
   throw ('BL_R15R1_NATIVE_'+$label+'_EXIT='+$exit)
  }
  return $body
 }
 function Exact([string]$identity,[string]$state){
  $body=Native 'PACKAGE' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$identity))
  $id=[regex]::Match($body,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $st=[regex]::Match($body,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $id.Success -or $id.Groups[1].Value.Trim() -cne $identity -or
     -not $st.Success -or $st.Groups[1].Value.Trim() -cne $state){
   throw ('BL_R15R1_EXACT_PACKAGE_STATE_DRIFT='+$identity)
  }
  Note ('PACKAGE='+$identity+';NATIVE_STATE='+$state)
 }
 function UpdateInfo([string]$root,[string]$id,[string]$label){
  $path=$root+'\'+$id
  $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($path,$false)
  if($null -eq $key){throw ('BL_R15R1_CBS_PACKAGE_MISSING_'+$label)}
  try{
   $state=$key.GetValue('CurrentState',$null)
   $vis=$key.GetValue('Visibility',$null)
   $st=if($null -eq $state){'MISSING'}else{'0x'+([uint32]$state).ToString('X')}
   $vv=if($null -eq $vis){'MISSING'}else{'0x'+([uint32]$vis).ToString('X')}
   Note ('CBS_'+$label+'_CURRENTSTATE='+$st+';VISIBILITY='+$vv)
   $updates=$key.OpenSubKey('Updates',$false)
   if($null -eq $updates){
    Note ('UPDATES_'+$label+'_KEY=MISSING;VALUES=0;CHILDKEYS=0')
    return
   }
   try{
    $names=@($updates.GetValueNames())
    $children=@($updates.GetSubKeyNames())
    if($names.Count -gt 40 -or $children.Count -gt 40){
     throw ('BL_R15R1_UPDATES_COUNT_OVERBOUND_'+$label)
    }
    Note ('UPDATES_'+$label+'_KEY=PRESENT;VALUES='+$names.Count+';CHILDKEYS='+$children.Count)
    foreach($child in $children){
     if($child.Length -gt 200){throw 'BL_R15R1_UPDATE_CHILD_NAME_TOO_LONG'}
     Note ('UPDATES_'+$label+'_CHILD='+$child)
    }
    foreach($name in $names){
     if($name.Length -gt 200){throw 'BL_R15R1_UPDATE_VALUE_NAME_TOO_LONG'}
     $kind=$updates.GetValueKind($name).ToString()
     $value=$updates.GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
     $display='NOT_SCALAR'
     if($kind -ceq 'DWord' -and $value -is [int]){
      $display='0x'+([uint32]$value).ToString('X')
     }elseif($kind -ceq 'QWord' -and $value -is [long]){
      $display='0x'+([uint64]$value).ToString('X')
     }elseif($kind -ceq 'String' -or $kind -ceq 'ExpandString'){
      $display='CHAR_COUNT='+([string]$value).Length
     }elseif($kind -ceq 'MultiString'){
      $display='ARRAY_COUNT='+@($value).Count
     }elseif($kind -ceq 'Binary'){
      $display='BYTE_COUNT='+@($value).Count
     }elseif($null -eq $value){$display='NULL'}
     Note ('UPDATES_'+$label+'_VALUE='+$name+';KIND='+$kind+';DATA='+$display)
    }
    if($label -ceq 'CURRENT'){
     $marker=$updates.GetValue('SearchEngine-Client-Package',$null)
     $match=($names.Count -eq 1 -and $names[0] -ceq 'SearchEngine-Client-Package' -and
      $children.Count -eq 0 -and $null -ne $marker -and
      $updates.GetValueKind('SearchEngine-Client-Package').ToString() -ceq 'DWord' -and
      [uint32]$marker -eq 0)
     Note ('CURRENT_UPDATES_HISTORICAL_EXACT_SINGLE_DWORD_ZERO='+$match)
    }
   }finally{$updates.Close()}
  }finally{$key.Close()}
 }
 function CleanupOwnTemp(){
  if(-not(Test-Path -LiteralPath $temp)){return}
  $it=Get-Item -LiteralPath $temp -Force -ErrorAction Stop
  if(-not $it.PSIsContainer -or ($it.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
   throw 'BL_R15R1_TEMP_NOT_PLAIN_DIRECTORY'
  }
  $items=@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop)
  if($items.Count -lt 1 -or $items.Count -gt 16){throw 'BL_R15R1_TEMP_ITEM_COUNT_UNEXPECTED'}
  $prefix=[regex]::Escape('SOFTWARE.readonlycopy.hiv')
  $guid='\{[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\}'
  $allowed='^'+$prefix+'(?:\.LOG[12]?|'+$guid+'\.TM\.blf|'+$guid+'\.TMContainer[0-9]{20}\.regtrans-ms)?$'
  $bytes=0L
  foreach($item in $items){
   $isLink=(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)
   $size=if($item.PSIsContainer){-1L}else{[long]$item.Length}
   Note ('OWNED_TEMP_ENTRY='+$item.Name+';SIZE='+$size+';DIR='+$item.PSIsContainer+';REPARSE='+$isLink)
   if($item.PSIsContainer -or $isLink -or $item.Name -cnotmatch $allowed -or $size -gt 120000000L){
    throw ('BL_R15R1_UNRECOGNIZED_TEMP_ENTRY='+$item.Name)
   }
   $bytes+=$size
  }
  if($bytes -gt 200000000L){throw 'BL_R15R1_TEMP_TOO_LARGE'}
  foreach($item in $items){
   Remove-Item -LiteralPath $item.FullName -Force -ErrorAction Stop
   Note ('OWNED_TEMP_FILE_DELETED='+$item.Name)
  }
  if(@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop).Count -ne 0){
   throw 'BL_R15R1_TEMP_REMAINDER'
  }
  [IO.Directory]::Delete($temp,$false)
  Note 'OWNED_TEMP_FOLDER_REMOVED=PASS'
 }
 $createdMount=$false;$mounted=$false;$mountedAttempt=$false
 $createdTemp=$false;$loaded=$false;$success=$false;$critical=$false
 $result='HOLD_R15R1_SEARCH_UPDATES_TOPOLOGY'
 try{
  Note 'BLUELITE_S41_R15R1_SEARCHENGINE_EXACT_UPDATES_CBS_READONLY'
  Note 'R15_ORIGINAL_SHA_AND_STRICT_GATE_HOLD=PASS'
  PinSource 'PRE'
  ZeroMounts 'PRE'
  ZeroHives 'PRE'
  if([IO.DriveInfo]::new('C').AvailableFreeSpace -lt 2GB){throw 'BL_R15R1_LOW_FREE_SPACE'}
  [void][IO.Directory]::CreateDirectory($mount);$createdMount=$true
  $mountedAttempt=$true
  $null=Native 'MOUNT_S41_RO' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true;Note 'S41_NATIVE_READONLY_MOUNT=PASS'
  Exact $current 'Installed'
  Exact $old 'Staged'
  Exact $parent 'Installed'
  $null=[IO.Directory]::CreateDirectory($temp);$createdTemp=$true
  Copy-Item -LiteralPath (Join-Path $mount 'Windows\System32\Config\SOFTWARE') -Destination $copy -ErrorAction Stop
  $copyItem=Get-Item -LiteralPath $copy -Force -ErrorAction Stop
  if($copyItem.Length -lt 1024){throw 'BL_R15R1_SOFTWARE_COPY_TOO_SMALL'}
  Note ('SOFTWARE_COPY_BYTES='+$copyItem.Length)
  $regLines=@(& $reg load ('HKLM\'+$alias) $copy 2>&1|ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0){throw ('BL_R15R1_COPY_HIVE_LOAD_FAIL='+($regLines -join ';'))}
  $loaded=$true;Note 'OWNED_COPY_HIVE_LOAD=PASS'
  $root=$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  UpdateInfo $root $current 'CURRENT'
  UpdateInfo $root $old 'OLD'
  UpdateInfo $root $parent 'CURRENT_PARENT04'
  UpdateInfo $root $oldParent 'OLD_PARENT04'
  $pending=Native 'PENDING' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $n=@([regex]::Matches($pending,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$')).Count
  $px=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING='+$n+';PENDING_XML='+$px)
  if($n -ne 0 -or $px){throw 'BL_R15R1_PENDING_NOT_ZERO'}
  $h=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($h -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R15R1_CHECKHEALTH_NOT_CLEAN'}
  Note 'CBS_CHECKHEALTH=CLEAN'
  $success=$true
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  if($loaded){
   try{
    [GC]::Collect();[GC]::WaitForPendingFinalizers()
    $lines=@(& $reg unload ('HKLM\'+$alias) 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -ne 0){throw ('REG_UNLOAD='+($lines -join ';'))}
    $loaded=$false
    Note 'OWNED_COPY_HIVE_UNLOADED=PASS'
   }catch{$critical=$true;Note ('CRITICAL_HIVE_UNLOAD='+$_.Exception.Message)}
  }
  if($createdTemp -and -not $loaded){
   try{CleanupOwnTemp}catch{$critical=$true;Note ('TEMP_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  if($mountedAttempt -and -not $mounted){
   try{
    $a=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -eq 0 -and ($a -join [Environment]::NewLine).Contains($mount)){
     $mounted=$true;Note 'RECOVER_OWNED_READONLY_MOUNT=TRUE'
    }
   }catch{$critical=$true;Note ('MOUNT_RECOVERY_HOLD='+$_.Exception.Message)}
  }
  if($mounted -and -not $loaded){
   try{
    $null=Native 'DISCARD_S41_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
    $mounted=$false;Note 'S41_READONLY_DISCARD=PASS'
   }catch{$critical=$true;Note ('RO_DISCARD_HOLD='+$_.Exception.Message)}
  }
  try{ZeroMounts 'POST'}catch{$critical=$true;Note ('POST_MOUNTS_HOLD='+$_.Exception.Message)}
  try{ZeroHives 'POST'}catch{$critical=$true;Note ('POST_HIVES_HOLD='+$_.Exception.Message)}
  if($createdMount -and -not $mounted){
   try{
    if(@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -ne 0){
     throw 'BL_R15R1_NONEMPTY_MOUNT_ROOT'
    }
    [IO.Directory]::Delete($mount,$false)
    Note 'OWNED_EMPTY_RO_MOUNT_REMOVED=PASS'
   }catch{$critical=$true;Note ('MOUNT_ROOT_HOLD='+$_.Exception.Message)}
  }
  try{PinSource 'POST'}catch{$critical=$true;Note ('SOURCE_POST_PIN_HOLD='+$_.Exception.Message)}
  if($success -and -not $critical -and -not $mounted -and -not $loaded){
   $result='PASS_S41_R15R1_SEARCHENGINE_UPDATES_EXACT_READONLY_CLASSIFICATION_ONLY'
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note 'NO_WIM_CLONE_NO_PACKAGE_REMOVAL_NO_CBS_MUTATION_NO_RELEASE'
 }
 if($result -ne 'PASS_S41_R15R1_SEARCHENGINE_UPDATES_EXACT_READONLY_CLASSIFICATION_ONLY'){
  throw 'BL_R15R1_UPDATES_CLASSIFICATION_HOLD'
 }
}
