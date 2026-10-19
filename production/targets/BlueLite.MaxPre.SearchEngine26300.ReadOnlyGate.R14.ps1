# BlueLite S41/R14: targeted SearchEngine wrapper native/CBS-owner READONLY classification.
# Historical Library 131/346/347; independently resolve 26300 topology.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R14_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R14_ADMIN_REQUIRED'}
 $wim='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $wimSHA='378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1'
 $r13='C:\work\logs\BlueLite_MAXPRE_FodMetadata_26300.9711_S42Retire_R13.txt'
 $r13SHA='32C8852F457671C0D7BFA1C774543D894F01E6AB0E7C01F83ED1E9052F9AA62C'
 $log='C:\work\logs\BlueLite_MAXPRE_SearchEngine_26300.9711_ReadOnly_R14.txt'
 $mount='C:\BLR14M'
 $temp='C:\work\E2E\BlueLite_R14_SearchGate_Temporary'
 $hiveFile=Join-Path $temp 'SOFTWARE.readonlycopy.hiv'
 $alias='BLR14SOFT'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(Test-Path -LiteralPath $log){throw 'BL_R14_LOG_NO_OVERWRITE'}
 if(Test-Path -LiteralPath $mount){throw 'BL_R14_MOUNT_NO_OVERWRITE'}
 if(Test-Path -LiteralPath $temp){throw 'BL_R14_TEMP_NO_OVERWRITE'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'BL_R14_LOG_DIRECTORY_MISSING'}
 $ev=Get-Item -LiteralPath $r13 -ErrorAction Stop
 if($ev.PSIsContainer -or $ev.Length -ne 1949 -or
    (Get-FileHash -LiteralPath $r13 -Algorithm SHA256).Hash -cne $r13SHA){throw 'BL_R14_R13_ORIGINAL_SHA_DRIFT'}
 $raw=[IO.File]::ReadAllText($r13)
 foreach($tag in @('RESULT=PASS_R13_EXACT_S42_TWO_EXPORT_DISPOSABLES_DELETED_ONLY',
                   'OWNED_S42_WIM_LOGICAL_BYTES_DELETED=11113535370',
                   'MOUNTS_POST_EXIT=0;EMPTY=1;ROWS=0')){
  if(-not $raw.Contains($tag)){throw ('BL_R14_R13_RESULT_DRIFT='+$tag)}
 }
 if(Test-Path -LiteralPath 'C:\work\E2E\BlueLite_S42_26300.9711_R12_FodMetadata_EqualMaxExports'){
  throw 'BL_R14_R13_S42_REAPPEARED'
 }
 [IO.File]::WriteAllText($log,'',$utf8)
 function Note([string]$s){Write-Host $s;[IO.File]::AppendAllText($log,$s+[Environment]::NewLine,$utf8)}
 function PinWim([string]$label){
  $item=Get-Item -LiteralPath $wim -Force -ErrorAction Stop
  if($item.PSIsContainer -or $item.Length -ne 6636510185L -or
     ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash -cne $wimSHA){
   throw ('BL_R14_S41_PIN_FAILED_'+$label)
  }
  Note ('S41_'+$label+'_FULL_SHA_SIZE=PASS;'+$wimSHA)
 }
 function Native([string]$label,[string[]]$argv){
  $lines=@(& $dism @argv 2>&1 | ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE;$body=$lines -join [Environment]::NewLine
  if($code -ne 0 -or $body -match '(?im)^\s*Error\s*:' -or
     $body -notmatch '(?i)The operation completed successfully\.'){
   foreach($line in $lines){Note ('DISM_'+$label+'_RAW='+$line)}
   throw ('BL_R14_NATIVE_'+$label+'_EXIT='+$code)
  }
  return $body
 }
 function ZeroMounts([string]$label){
  $lines=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $empty=@($lines|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $rows=@($lines|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$label+'_EXIT='+$code+';EMPTY='+$empty+';ROWS='+$rows)
  if($code -ne 0 -or $empty -ne 1 -or $rows -ne 0){throw ('BL_R14_MOUNTS_NOT_ZERO_'+$label)}
 }
 function ProjectHives([string]$label){
  $lines=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1 | ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  $found=@($lines|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(?:BL[0-9]|BLWEB|BLR14|BlueLite|FB[0-9])'}).Count
  Note ('PROJECT_HIVES_'+$label+'_EXIT='+$code+';MATCHES='+$found)
  if($code -ne 0 -or $found -ne 0){throw 'BL_R14_PROJECT_HIVES_PRESENT'}
 }
 function StateExact([string]$identity){
  $info=Native 'EXACT_PACKAGE' @('/English',('/Image:'+$mount),'/Get-PackageInfo',('/PackageName:'+$identity))
  $idmatch=[regex]::Match($info,'(?im)^\s*Package Identity\s*:\s*(\S+)\s*$')
  $state=[regex]::Match($info,'(?im)^\s*State\s*:\s*([^\r\n]+)')
  if(-not $idmatch.Success -or $idmatch.Groups[1].Value.Trim() -cne $identity -or -not $state.Success){
   throw ('BL_R14_EXACT_ID_STATE_DRIFT='+$identity)
  }
  return $state.Groups[1].Value.Trim()
 }
 $mounted=$false;$loaded=$false;$tempMade=$false;$mountMade=$false;$ok=$false
 $result='HOLD_R14_SEARCHENGINE_READONLY'
 try{
  Note 'BLUELITE_S41_R14_SEARCHENGINE_CBS_OWNERS_SCOPED_READONLY'
  Note 'STEP_01_PINS_AND_NATIVE_PRECHECKS'
  Note 'R13_ORIGINAL_PASS_SHA=PASS'
  PinWim 'PRE'
  ZeroMounts 'PRE'
  ProjectHives 'PRE'
  $null=[IO.Directory]::CreateDirectory($mount);$mountMade=$true
  Note 'STEP_02_NATIVE_S41_READONLY_MOUNT'
  $null=Native 'MOUNT_RO' @('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  $mounted=$true;Note 'S41_NATIVE_READONLY_MOUNT=PASS'
  $all=Native 'GET_PACKAGES' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pattern='(?im)^\s*Package Identity\s*:\s*(Microsoft-Windows-SearchEngine-Client-Package~31bf3856ad364e35~amd64~~[0-9.]+)\s*$'
  $names=@([regex]::Matches($all,$pattern)|ForEach-Object {$_.Groups[1].Value.Trim()}|Select-Object -Unique)
  Note ('SEARCHENGINE_EXACT_FAMILY_COUNT='+$names.Count)
  $states=@()
  foreach($name in $names){
   $state=StateExact $name
   $states+=@([pscustomobject]@{Identity=$name;State=$state})
   Note ('SEARCH_PACKAGE='+$name+';NATIVE_STATE='+$state)
  }
  $chosen=@($states|Where-Object {$_.State -ceq 'Installed'})
  if($chosen.Count -gt 1){throw 'BL_R14_MULTIPLE_INSTALLED_SEARCH_WRAPPERS'}
  Note 'STEP_03_SEARCH_CBS_OWNER_COPIED_SOFTWARE_HIVE'
  $classification='ABSENT_NATIVE_SEARCHENGINE_PACKAGE'
  if($chosen.Count -eq 1){
   $identity=[string]$chosen[0].Identity
   $null=[IO.Directory]::CreateDirectory($temp);$tempMade=$true
   $originalHive=Join-Path $mount 'Windows\System32\Config\SOFTWARE'
   Copy-Item -LiteralPath $originalHive -Destination $hiveFile -ErrorAction Stop
   if((Get-Item -LiteralPath $hiveFile).Length -lt 1024){throw 'BL_R14_HIVE_COPY_TRUNCATED'}
   Note ('COPY_ONLY_SOFTWARE_HIVE_BYTES='+(Get-Item -LiteralPath $hiveFile).Length)
   $load=@(& $reg load ('HKLM\'+$alias) $hiveFile 2>&1 | ForEach-Object {[string]$_})
   if([int]$LASTEXITCODE -ne 0){throw ('BL_R14_REG_LOAD_FAILED='+($load -join ';'))}
   $loaded=$true;Note 'TEMP_COPY_HIVE_LOAD=PASS'
   $keyPath=$alias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\'+$identity
   $key=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath,$false)
   if($null -eq $key){throw 'BL_R14_CBS_EXACT_PACKAGE_KEY_MISSING'}
   try{
    $stateRaw=$key.GetValue('CurrentState',$null)
    $visRaw=$key.GetValue('Visibility',$null)
    if($null -eq $stateRaw -or $null -eq $visRaw){throw 'BL_R14_CBS_STATE_OR_VIS_MISSING'}
    $st=[uint32]$stateRaw;$vis=[uint32]$visRaw
    Note ('CBS_CURRENTSTATE=0x'+$st.ToString('X'))
    Note ('CBS_VISIBILITY=0x'+$vis.ToString('X'))
    $ownerKey=$key.OpenSubKey('Owners',$false)
    $owners=@()
    if($null -ne $ownerKey){
     try{
      foreach($oname in @($ownerKey.GetValueNames())){
       $ov=$ownerKey.GetValue($oname,$null)
       $kind=$ownerKey.GetValueKind($oname).ToString()
       $owners+=@([pscustomobject]@{Name=$oname;Value=$ov;Kind=$kind})
       $num=if($null -ne $ov){([uint32]$ov).ToString('X')}else{'NULL'}
       Note ('CBS_OWNER='+$oname+';KIND='+$kind+';VALUE_HEX=0x'+$num)
      }
     }finally{$ownerKey.Close()}
    }
    Note ('CBS_OWNERS_EXACT_COUNT='+$owners.Count)
    $parentInstalled=$false
    if($owners.Count -eq 1){
     $parent=[string]$owners[0].Name
     if($parent -match '^Microsoft-Windows-Client-Desktop-Required-Package\d+~31bf3856ad364e35~amd64~~[0-9.]+$'){
      $parentState=StateExact $parent
      Note ('CBS_OWNER_PARENT_STATE='+$parentState)
      $parentInstalled=$parentState -ceq 'Installed'
     }else{Note 'CBS_OWNER_PARENT_FAMILY=UNEXPECTED'}
    }
    if($st -eq 0x70 -and $vis -eq 0x2 -and $owners.Count -eq 1 -and
       $owners[0].Kind -ceq 'DWord' -and [uint32]$owners[0].Value -eq 0x30070 -and
       $parentInstalled){
      $classification='MATCHES_HISTORICAL_SINGLE_OWNER_AMBER_SHAPE'
    }else{$classification='UNKNOWN_26300_OWNER_OR_VISIBILITY_VARIANT'}
   }finally{$key.Close()}
  }elseif($names.Count -gt 0){
   $classification='SEARCH_FAMILY_PRESENT_BUT_NOT_INSTALLED'
  }
  Note ('SEARCH_CBS_NATIVE_CLASSIFICATION='+$classification)
  Note 'STEP_04_ONLY_SRCHADMIN_COMPONENT_FOLDER_METADATA'
  $sx=Join-Path $mount 'Windows\WinSxS'
  $dirs=@(Get-ChildItem -LiteralPath $sx -Directory -ErrorAction Stop |
   Where-Object {$_.Name -match '^(amd64|wow64)_desktop_shell-search-srchadmin_31bf3856ad364e35_'})
  Note ('SRCHADMIN_EXACT_FAMILY_DIR_COUNT='+$dirs.Count)
  if($dirs.Count -gt 15){throw 'BL_R14_SRCHADMIN_DIR_COUNT_UNEXPECTED'}
  foreach($d in $dirs){
   if(($d.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'BL_R14_SRCHADMIN_DIRECTORY_REPARSE'}
   $files=@(Get-ChildItem -LiteralPath $d.FullName -Force -ErrorAction Stop)
   if($files.Count -gt 120){throw 'BL_R14_SRCHADMIN_FILE_COUNT_LIMIT'}
   $bytes=0L;$reparse=0
   foreach($f in $files){
    if($f.PSIsContainer){throw 'BL_R14_SRCHADMIN_UNEXPECTED_CHILD_DIRECTORY'}
    if(($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$reparse++}
    $bytes+=[long]$f.Length
   }
   Note ('SRCHADMIN_DIR='+$d.Name+';FILES='+$files.Count+';LOGICAL_BYTES='+$bytes+';REPARSE_FILES='+$reparse)
  }
  Note 'STEP_05_HEALTH_PENDING_AND_FINISH_RO'
  $packages=Native 'PENDING' @('/English',('/Image:'+$mount),'/Get-Packages','/Format:List')
  $pending=@([regex]::Matches($packages,'(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$')).Count
  $px=Test-Path -LiteralPath (Join-Path $mount 'Windows\WinSxS\pending.xml')
  Note ('PENDING_COUNT='+$pending+';PENDING_XML='+$px)
  if($pending -ne 0 -or $px){throw 'BL_R14_PENDING_NOT_ZERO'}
  $h=Native 'CHECKHEALTH' @('/English',('/Image:'+$mount),'/Cleanup-Image','/CheckHealth')
  if($h -notmatch '(?i)No component store corruption detected\.'){throw 'BL_R14_CHECKHEALTH_NOT_CLEAN'}
  Note 'CBS_CHECKHEALTH=CLEAN'
  $ok=$true
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  if($loaded){
   try{
    [GC]::Collect();[GC]::WaitForPendingFinalizers()
    $unload=@(& $reg unload ('HKLM\'+$alias) 2>&1 | ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -ne 0){throw ($unload -join ';')}
    $loaded=$false;Note 'OWNED_COPY_SOFTWARE_HIVE_UNLOADED=PASS'
   }catch{$ok=$false;Note ('HIVE_UNLOAD_HOLD='+$_.Exception.Message)}
  }
  if(-not $loaded -and $tempMade){
   try{
    if(@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop).Count -eq 1 -and
      (Test-Path -LiteralPath $hiveFile -PathType Leaf)){
     Remove-Item -LiteralPath $hiveFile -Force -ErrorAction Stop
    }
    if(@(Get-ChildItem -LiteralPath $temp -Force -ErrorAction Stop).Count -eq 0){
     [IO.Directory]::Delete($temp,$false);Note 'OWNED_EPHEMERAL_HIVE_COPY_DELETED=PASS'
    }else{throw 'BL_R14_TEMP_NOT_EMPTY'}
   }catch{$ok=$false;Note ('TEMP_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  if(-not $mounted -and $mountMade){
   try{
    $lines=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
    if([int]$LASTEXITCODE -eq 0 -and ($lines -join [Environment]::NewLine).Contains($mount)){
     $mounted=$true;Note 'RECOVER_OWNED_MOUNT=TRUE'
    }
   }catch{$ok=$false;Note ('MOUNT_TABLE_RECOVERY_HOLD='+$_.Exception.Message)}
  }
  if($mounted){
   try{
    $null=Native 'DISCARD_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
    $mounted=$false;Note 'S41_READONLY_DISCARD=PASS'
   }catch{$ok=$false;Note ('RO_DISCARD_HOLD='+$_.Exception.Message)}
  }
  try{ZeroMounts 'POST'}catch{$ok=$false;Note ('MOUNT_CLOSE_HOLD='+$_.Exception.Message)}
  if($mountMade -and -not $mounted){
   try{
    if(@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop).Count -eq 0){
     [IO.Directory]::Delete($mount,$false);Note 'OWNED_EMPTY_RO_MOUNT_REMOVED=PASS'
    }else{throw 'BL_R14_MOUNT_DIR_NOT_EMPTY'}
   }catch{$ok=$false;Note ('MOUNT_DIR_CLEANUP_HOLD='+$_.Exception.Message)}
  }
  try{PinWim 'POST'}catch{$ok=$false;Note ('POST_SOURCE_PIN_HOLD='+$_.Exception.Message)}
  if($ok -and -not $loaded -and -not $mounted){
   $result='PASS_S41_R14_SEARCHENGINE_CBS_OWNER_READONLY_CLASSIFICATION_ONLY'
  }
  Note ('RESULT='+$result)
  Note ('REPORT='+$log)
  Note 'NO_CBS_CHANGE_NO_PACKAGE_REMOVAL_NO_WIM_CLONE_NO_RELEASE'
 }
 if($result -ne 'PASS_S41_R14_SEARCHENGINE_CBS_OWNER_READONLY_CLASSIFICATION_ONLY'){
  throw 'BL_R14_SEARCHENGINE_CLASSIFICATION_HOLD'
 }
}
