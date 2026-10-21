# R20R2F14 26300.9807. Operator authorization + Total CMD close confirmation required.
# ONE disposable WIM; ONE Staged neutral OneDrive package; no LTSB/satellite/Backup edits.
& {
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$root='C:\work'
$orig='C:\work\26300.9807-UUP\install.wim'
$src='C:\BLR20R2F5\R20R2F6_exports\WebViewRemoved_26300_9807_MAX.wim'
$oHash='0FB778D4696DABA17EDC52E6391A3F217982422FB920C98C8273E0C51A094B49'
$sHash='F8F2FFF0A40508C88F8426B2923FEDCF9B00F3FFF3A5637A13C0EB0006E8BA7E'
$work='C:\work\E2E\BLR20R2F14_OneDrive'
$mount='C:\work\E2E\BLR20R2F14_Mount'
$wim=Join-Path $work 'install.wim'
$backup=Join-Path $work 'SOFTWARE_PRE_AMBER.hiv'
$regAlias='HKLM\BLR20R2F14_SOFT'
$regExe=Join-Path $env:WINDIR 'System32\reg.exe'
$dism=Join-Path $env:WINDIR 'System32\dism.exe'
$neut='Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~~10.0.26100.1'
$sat='Microsoft-Windows-OneDrive-Setup-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
$pn='Microsoft-Windows-Not-Supported-On-LTSB-Package~31bf3856ad364e35~amd64~~10.0.26100.1301'
$ps='Microsoft-Windows-Not-Supported-On-LTSB-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1'
$ledger='C:\work\logs\BlueLite_26300_9807_OneDriveAmber_R20R2F14.txt'
$prefix='C:\work\logs\BlueLite_26300_9807_OneDriveAmber_R20R2F14'
$utf8=[Text.UTF8Encoding]::new($false)
$writer=$null
$mountAttempt=$false
$hiveLoaded=$false
$ready=$false
$committed=$false
$releaseOk=$true
$result='HOLD_R20R2F14_NOT_CERTIFIED'
function Log([string]$msg) {
  $line="$(Get-Date -Format 'HH:mm:ss') | $msg"
  Write-Output $line
  if($null -ne $writer){$writer.WriteLine($line);$writer.Flush()}
}
function Pin([string]$name,[string]$p,[long]$size,[string]$sha) {
  $f=Get-Item -LiteralPath $p -Force -ErrorAction Stop
  if($f.PSIsContainer -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -or $f.Length -ne $size){throw "PIN_TYPE_SIZE_FAILED=$name"}
  if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -cne $sha){throw "PIN_SHA_FAILED=$name"}
  Log "PIN_$name=PASS;BYTES=$size;SHA=$sha"
}
function Run([string]$id,[string]$bin,[string[]]$argv,[bool]$expect=$true) {
  $p=$prefix+'_'+$id+'.txt'
  if([IO.File]::Exists($p)){throw "RUN_OUTPUT_EXISTS=$id"}
  $raw=@(& $bin @argv 2>&1 | ForEach-Object {[string]$_})
  $rc=[int]$LASTEXITCODE
  [IO.File]::WriteAllLines($p,$raw,$utf8)
  $txt=[string]::Join([char]10,$raw)
  Log "NATIVE_$($id)_EXIT=$rc;LINES=$($raw.Count);LOG=$p"
  if($expect -and ($rc -ne 0 -or $txt -notmatch '(?i)The operation completed successfully\.')){throw "NATIVE_OPERATION_FAILED=$id;CODE=$rc"}
  return [pscustomobject]@{Code=$rc;Text=$txt}
}
function RegRead([string]$key,[string]$val='') {
  $argv=@('query',$key);if($val.Length){$argv+=@('/v',$val)}
  $raw=@(& $regExe @argv 2>&1 | ForEach-Object {[string]$_})
  return [pscustomobject]@{Code=[int]$LASTEXITCODE;Text=[string]::Join([char]10,$raw)}
}
function RegDWORD([string]$key,[string]$name) {
  $r=RegRead $key $name
  $m=[regex]::Match($r.Text,'(?im)^\s*'+[regex]::Escape($name)+'\s+REG_DWORD\s+(0x[0-9a-f]+|\d+)\s*$')
  if($r.Code -ne 0 -or -not $m.Success){throw "CBS_VALUE_MISSING=$name"}
  $v=$m.Groups[1].Value
  if($v.StartsWith('0x')){return [Convert]::ToInt32($v.Substring(2),16)}
  return [int]$v
}
function Owner([string]$child,[string]$expectedName,[int]$expectedValue) {
  $q=RegRead "$child\Owners"
  $rows=@([regex]::Matches($q.Text,'(?im)^\s+(\S+)\s+REG_DWORD\s+(0x[0-9a-f]+|\d+)\s*$'))
  if($q.Code -ne 0 -or $rows.Count -ne 1){throw 'CBS_OWNER_CARDINALITY_FAILED'}
  $val=$rows[0].Groups[2].Value
  $num=if($val.StartsWith('0x')){[Convert]::ToInt32($val.Substring(2),16)}else{[int]$val}
  if($rows[0].Groups[1].Value -cne $expectedName -or $num -ne $expectedValue){throw 'CBS_OWNER_IDENTITY_DRIFT'}
}
function Parents {
  $c=$regAlias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  if((RegRead "$c\$pn").Code -ne 0 -or (RegDWORD "$c\$pn" 'CurrentState') -ne 64 -or (RegDWORD "$c\$pn" 'Visibility') -ne 2){throw 'LTSB_NEUTRAL_PARENT_DRIFT'}
  if((RegRead "$c\$ps").Code -ne 0 -or (RegDWORD "$c\$ps" 'CurrentState') -ne 112 -or (RegDWORD "$c\$ps" 'Visibility') -ne 2){throw 'LTSB_ENUS_PARENT_DRIFT'}
  Log 'BOTH_LTSB_PARENTS_PROTECTED=PASS'
}
function LoadHive {
  if($hiveLoaded -or (RegRead $regAlias).Code -eq 0){throw 'OFFLINE_HIVE_ALIAS_COLLISION'}
  $r=Run 'REG_LOAD' $regExe @('load',$regAlias,(Join-Path $mount 'Windows\System32\config\SOFTWARE')) $false
  if($r.Code -ne 0 -or (RegRead $regAlias).Code -ne 0){throw 'OFFLINE_HIVE_LOAD_FAILED'}
  Set-Variable -Name hiveLoaded -Value $true -Scope 1
  Log 'OFFLINE_SOFTWARE_LOADED=PASS'
}
function UnloadHive {
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
  $r=@(& $regExe unload $regAlias 2>&1 | ForEach-Object {[string]$_})
  $rc=[int]$LASTEXITCODE
  Log "OFFLINE_SOFTWARE_REG_UNLOAD_EXIT=$rc"
  if($rc -ne 0 -or (RegRead $regAlias).Code -eq 0){throw 'OFFLINE_HIVE_UNLOAD_FAILED'}
  Set-Variable -Name hiveLoaded -Value $false -Scope 1
}
function Package([string]$id,[string]$name,[string]$wanted){
  $x=Run $id $dism @('/English',"/Image:$mount",'/Get-PackageInfo',"/PackageName:$name")
  if($x.Text -notmatch "(?im)^\s*State\s*:\s*$wanted\s*$"){throw "PACKAGE_STATE_MISMATCH=$id"}
}
function PendingHealth([string]$id,[bool]$scan) {
  foreach($p in @('Windows\WinSxS\pending.xml','Windows\WinSxS\reboot.xml')){
    if(Test-Path -LiteralPath (Join-Path $mount $p)){throw "PENDING_XML=$id"}
  }
  $x=Run ($id+'_PACKAGES') $dism @('/English',"/Image:$mount",'/Get-Packages')
  if($x.Text -match '(?im)^\s*State\s*:\s*(Install Pending|Uninstall Pending)\s*$'){throw "PENDING_SERVICING=$id"}
  $h=Run ($id+'_CHECKHEALTH') $dism @('/English',"/Image:$mount",'/Cleanup-Image','/CheckHealth')
  if($h.Text -notmatch '(?i)No component store corruption detected'){throw "CBS_CHECKHEALTH_FAILURE=$id"}
  if($scan){
    $s=Run ($id+'_SCANHEALTH') $dism @('/English',"/Image:$mount",'/Cleanup-Image','/ScanHealth')
    if($s.Text -notmatch '(?i)No component store corruption detected'){throw "CBS_SCANHEALTH_FAILURE=$id"}
  }
  Log "CBS_PENDING_HEALTH_$id=PASS"
}
try {
  if($PSVersionTable.PSVersion.Major -ne 7 -or -not [Environment]::Is64BitProcess){throw 'PS7_X64_REQUIRED'}
  $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
  if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
  foreach($d in @('C:\work','C:\work\logs','C:\work\E2E')){
    $it=Get-Item -LiteralPath $d -Force
    if(-not $it.PSIsContainer -or ($it.Attributes -band [IO.FileAttributes]::ReparsePoint)){throw "OWNED_ROOT_INVALID=$d"}
  }
  if((Test-Path -LiteralPath $work) -or (Test-Path -LiteralPath $mount) -or [IO.File]::Exists($ledger)){throw 'R14_OUTPUT_PATH_EXISTS_NO_OVERWRITE'}
  $writer=[IO.StreamWriter]::new($ledger,$false,$utf8)
  Log 'BLUELITE_R20R2F14_ONE_NEUTRAL_26300_9807_DISPOSABLE'
  Log 'OPERATOR_CONFIRM_TOTALCMD_EXPLORER_CLOSED_REQUIRED_BEFORE_RUN'
  foreach($ref in @(
    @{Name='R12';Path='C:\work\logs\BlueLite_26300_9807_OneDriveParentOwner_R20R2F12.txt';SHA='1B32F0F86E3C3909784169F1B44E0486EB3D42335641F3A822C599F6FC28475B'},
    @{Name='R13';Path='C:\work\logs\BlueLite_26300_9807_OneDriveContract_R20R2F13.txt';SHA='1597A4000E008EB951FBA3CE33F81695F04345D5424FA9B7B091A2495C80B9D2'}
  )){
    if((Get-FileHash -LiteralPath $ref.Path -Algorithm SHA256).Hash -cne $ref.SHA){throw "EVIDENCE_PIN_DRIFT=$($ref.Name)"}
    Log "EVIDENCE_$($ref.Name)=PASS"
  }
  if(-not [IO.File]::ReadAllText('C:\work\logs\BlueLite_26300_9807_OneDriveContract_R20R2F13.txt').Contains('NEGATIVE_TOPOLOGY_FIXTURES=PASS_10_OF_10')){throw 'R13_GUARD_FIXTURES_MISSING'}
  Pin 'IMMUTABLE_PRE' $orig 7021953581L $oHash
  Pin 'WEBVIEW_SOURCE_PRE' $src 6407308664L $sHash
  foreach($kind in @('MountedWimInfo','MountedImageInfo')){
    $t=Run ('MOUNTS_PRE_'+$kind) $dism @('/English',('/Get-'+$kind))
    if($t.Text -match '(?im)^\s*Mount Dir\s*:'){throw 'PRE_EXISTING_MOUNT_FAIL_CLOSED'}
  }
  if((RegRead $regAlias).Code -eq 0){throw 'PREEXISTING_HIVE_ALIAS'}
  Log 'PRE_CATALOGS=EMPTY'
  [IO.Directory]::CreateDirectory($work)|Out-Null
  [IO.File]::Copy($src,$wim,$false)
  Pin 'DISPOSABLE_CLONE' $wim 6407308664L $sHash
  [IO.Directory]::CreateDirectory($mount)|Out-Null
  $mountAttempt=$true
  $m=Run 'MOUNT_RW' $dism @('/English','/Mount-Image',"/ImageFile:$wim",'/Index:1',"/MountDir:$mount")
  $mi=Run 'MOUNT_OWNER' $dism @('/English','/Get-MountedWimInfo')
  $fields=@{}
  foreach($line in ($mi.Text -split '[\r\n]+')){
    $v=[regex]::Match($line,'^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
    if($v.Success){if($fields.ContainsKey($v.Groups[1].Value)){throw 'DUPLICATE_MOUNT_FIELD'};$fields[$v.Groups[1].Value]=$v.Groups[2].Value}
  }
  if($fields.Count -ne 5 -or $fields['Mount Dir'] -ine $mount -or $fields['Image File'] -ine $wim -or $fields['Image Index'] -ne '1' -or $fields['Mounted Read/Write'] -ine 'Yes' -or $fields['Status'] -ine 'Ok'){throw 'WRONG_MOUNT_OWNER'}
  Log 'DISPOSABLE_RW_MOUNT_OWNERSHIP=PASS'
  PendingHealth 'PRE' $false
  Package 'PRE_NEUTRAL' $neut 'Staged'
  Package 'PRE_ENUS' $sat 'Installed'
  $setup=Join-Path $mount 'Windows\System32\OneDriveSetup.exe'
  if(-not(Test-Path -LiteralPath $setup)){throw 'EXPECTED_ONEDRIVE_SETUP_NOT_PRESENT'}
  $win=Join-Path $mount 'Windows\WinSxS'
  $beforeB=@(Get-ChildItem -LiteralPath $win -Directory -Force | Where-Object {$_.Name -match '(?i)onedrivebackup_' } | ForEach-Object {$_.Name})
  if($beforeB.Count -lt 1){throw 'PROTECTED_ONEDRIVEBACKUP_ABSENT_PRE'}
  [IO.File]::Copy((Join-Path $mount 'Windows\System32\config\SOFTWARE'),(Join-Path $work 'SOFTWARE_PRE.hiv'),$false)
  Log 'OFFLINE_SOFTWARE_BACKUP=PASS'
  LoadHive
  $c=$regAlias+'\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages'
  Parents
  if((RegDWORD "$c\$neut" 'CurrentState') -ne 64 -or (RegDWORD "$c\$neut" 'Visibility') -ne 2){throw 'NEUTRAL_CHILD_DRIFT'}
  if((RegDWORD "$c\$sat" 'CurrentState') -ne 112 -or (RegDWORD "$c\$sat" 'Visibility') -ne 2){throw 'SATELLITE_CHILD_DRIFT'}
  Owner "$c\$neut" $pn 0x30040
  Owner "$c\$sat" $ps 0x30070
  Log 'TWO_CHILD_OWNERS_AND_PARENTS=PASS'
  $e=Run 'EXPORT_NEUTRAL_CHILD' $regExe @('export',"$c\$neut",(Join-Path $work 'NEUTRAL_PRE.reg'),'/y') $false
  if($e.Code -ne 0){throw 'NEUTRAL_CHILD_EXPORT_FAILED'}
  $u=Run 'SET_NEUTRAL_VISIBILITY' $regExe @('add',"$c\$neut",'/v','Visibility','/t','REG_DWORD','/d','1','/f') $false
  if($u.Code -ne 0){throw 'NEUTRAL_VISIBILITY_FAILED'}
  $del=Run 'DELETE_NEUTRAL_OWNERS' $regExe @('delete',"$c\$neut\Owners",'/f') $false
  if($del.Code -ne 0){throw 'EXACT_CHILD_OWNERS_DELETE_FAILED'}
  if((RegDWORD "$c\$neut" 'Visibility') -ne 1 -or (RegRead "$c\$neut\Owners").Code -eq 0){throw 'CHILD_DECOUPLE_FAILED'}
  if((RegDWORD "$c\$sat" 'Visibility') -ne 2){throw 'SATELLITE_CHANGED_PRE_NATIVE'}
  Owner "$c\$sat" $ps 0x30070
  Parents
  Log 'NEUTRAL_CHILD_ONLY_DECOUPLED=PASS'
  UnloadHive
  $rm=Run 'REMOVE_ONE_NEUTRAL' $dism @('/English',"/Image:$mount",'/Remove-Package',"/PackageName:$neut")
  Log 'ONE_NATIVE_NEUTRAL_REMOVAL=EXIT0'
  foreach($spec in @(@{Id='NEUTRAL';Name=$neut},@{Id='SATELLITE';Name=$sat})){
    $q=Run ('POST_'+$spec.Id) $dism @('/English',"/Image:$mount",'/Get-PackageInfo',"/PackageName:$($spec.Name)") $false
    if($q.Code -eq 0 -or $q.Text -notmatch '(?i)0x800f0805'){throw "POST_TARGET_STILL_RESOLVING=$($spec.Id)"}
    Log "POST_$($spec.Id)_NONRESOLVING=PASS"
  }
  if(Test-Path -LiteralPath $setup){throw 'ONEDRIVESETUP_STILL_PRESENT'}
  $left=@(Get-ChildItem -LiteralPath $win -Directory -Force | Where-Object {$_.Name -match '^amd64_microsoft-windows-onedrive-setup_'})
  if($left.Count -ne 0){throw "WINSXS_ONEDRIVE_SETUP_RESIDUE=$($left.Count)"}
  $afterB=@(Get-ChildItem -LiteralPath $win -Directory -Force | Where-Object {$_.Name -match '(?i)onedrivebackup_'} | ForEach-Object {$_.Name})
  if(([string]::Join(';',@($beforeB|Sort-Object))) -cne ([string]::Join(';',@($afterB|Sort-Object)))){throw 'ONEDRIVEBACKUP_DRIFT'}
  LoadHive
  Parents
  UnloadHive
  PendingHealth 'POST' $true
  Log 'EXACT_POSTSTATE_AND_SCANHEALTH=PASS'
  $ready=$true
}
catch {
  if($null -ne $writer){Log ('ERROR='+$_.Exception.Message)}
  else{Write-Output ('EARLY_HOLD='+$_.Exception.Message)}
}
finally {
  if($hiveLoaded){
    try{UnloadHive}catch{Log ('CRITICAL_HIVE_UNLOAD='+$_.Exception.Message);$ready=$false;$releaseOk=$false}
  }
  if($mountAttempt){
    try{
      $rows=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
      if($LASTEXITCODE -ne 0){throw 'FINAL_DISM_MOUNT_QUERY_FAILURE'}
      $contains=[string]::Join([char]10,$rows)
      $ours=$contains -match ('(?im)^\s*Mount Dir\s*:\s*'+[regex]::Escape($mount)+'\s*$')
      if($ours -and -not $hiveLoaded){
        $action=if($ready){'/Commit'}else{'/Discard'}
        Log "OWNED_UNMOUNT_ACTION=$action"
        $un=@(& $dism /English /Unmount-Image "/MountDir:$mount" $action 2>&1 | ForEach-Object {[string]$_})
        [IO.File]::WriteAllLines($prefix+'_UNMOUNT.txt',$un,$utf8)
        $exit=[int]$LASTEXITCODE
        Log "OWNED_UNMOUNT_NATIVE_EXIT=$exit"
        if($exit -ne 0){$releaseOk=$false}
        elseif($ready){$committed=$true}
      }
      elseif($ours){$releaseOk=$false;Log 'OWNED_MOUNT_RETAINS_UNLOADED_HIVE_BLOCKER'}
      $again=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
      if($LASTEXITCODE -ne 0 -or ([string]::Join([char]10,$again)) -match ('(?im)^\s*Mount Dir\s*:\s*'+[regex]::Escape($mount)+'\s*$')){throw 'MOUNT_REMAINS_ACTIVE'}
      Log 'OWNED_MOUNT_RELEASED=PASS'
    }catch{$releaseOk=$false;Log ('CRITICAL_MOUNT_CLOSE='+$_.Exception.Message)}
  }
  foreach($p in @(
     @{Name='IMMUTABLE_POST';Path=$orig;Bytes=7021953581L;Sha=$oHash},
     @{Name='WEBVIEW_SOURCE_POST';Path=$src;Bytes=6407308664L;Sha=$sHash}
  )){
    try{Pin $p.Name $p.Path $p.Bytes $p.Sha}catch{$releaseOk=$false;Log ('CRITICAL_SOURCE_DRIFT='+$_.Exception.Message)}
  }
  if([IO.File]::Exists($wim) -and $releaseOk){
    Log ('DISPOSABLE_AFTER_BYTES='+(Get-Item -LiteralPath $wim).Length)
    Log ('DISPOSABLE_AFTER_SHA256='+(Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash)
  }
  if($ready -and $committed -and $releaseOk){$result='PASS_R20R2F14_ONE_NEUTRAL_DISPOSABLE_COMMITTED'}
  Log "READY=$ready;COMMITTED=$committed;CLOSE=$releaseOk"
  Log 'DIRECT_SATELLITE_LTSB_PARENT_ONEDRIVEBACKUP_MODIFICATION=NOT_RUN'
  Log 'NTLITE_VM_ISO_RELEASE=NOT_RUN'
  Log "RESULT=$result"
  Log "REPORT=$ledger"
  if($null -ne $writer){$writer.Dispose()}
}
if($result -notlike 'PASS_*'){throw $result}
}