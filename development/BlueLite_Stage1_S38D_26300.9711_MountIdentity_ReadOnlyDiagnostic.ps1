& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $report='C:\work\logs\BlueLite_Stage1_S38D_26300.9711_MountIdentity_ReadOnlyDiagnostic.txt'
 $source='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $candidate='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $oldMain='C:\work\logs\BlueLite_Stage1_S38_26300.9711_AppInstaller_PostCommitReadOnly.txt'
 $oldJson='C:\work\logs\BlueLite_Stage1_S38_26300.9711_AppInstaller_PostCommitSnapshot.json'
 $short='C:\BL38M'
 $expectedCandidate='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $expectedSource='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $utf8=[Text.UTF8Encoding]::new($false)
 $result='HOLD_S38D_MOUNT_IDENTITY_READONLY_DIAGNOSTIC'
 $mountLines=@();$hiveLines=@()
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if(-not $admin){throw 'PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOG_DIR_MISSING'}
 if(Test-Path -LiteralPath $report){throw 'S38D_DIAGNOSTIC_EXISTS_NO_OVERWRITE'}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$value) {
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$value
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$label,[string]$file,[string]$expected){
  if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw ('PIN_FILE_MISSING='+$label)}
  $actual=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  if($actual -cne $expected){throw ('PIN_MISMATCH='+$label+';'+$actual)}
  Note ('PIN_'+$label+'=PASS')
 }
 try {
  Note 'STAGE=S38D_26300_9711_READONLY_MOUNT_OWNER_DIAGNOSTIC'
  Note 'MODE=NO_MOUNT_NO_UNMOUNT_NO_REG_LOAD_NO_REG_UNLOAD_NO_MUTATION'
  Pin 'ORIGINAL_S38_MAIN' $oldMain '72FDD4417C3C87C634A1CF2E83C2C28B70134061FFD729FCCF37CFB236034C61'
  Pin 'ORIGINAL_S38_JSON' $oldJson '3115F5FAB64F9232C2F9CD3D8E8E266D88442440D0F65712019F95B6F297B072'
  Pin 'S31_PROTECTED_WIM' $source $expectedSource
  if(-not [IO.File]::Exists($candidate) -or (Get-Item -LiteralPath $candidate).Length -ne 6551362129L){
   throw 'S37_CANDIDATE_NOT_PRESENT_OR_SIZE_DRIFT'
  }
  Pin 'S37_COMMITTED_CANDIDATE' $candidate $expectedCandidate
  Note '[1/4] UNMODIFIED RAW DISM MOUNT TABLE'
  $mountLines=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $mountExit=[int]$LASTEXITCODE
  Note ('RAW_DISM_EXIT='+$mountExit)
  foreach($line in $mountLines){Note ('RAW_DISM_LINE='+$line)}
  if($mountExit -ne 0){throw 'RAW_DISM_MOUNT_TABLE_FAILED'}
  $groups=[System.Collections.Generic.List[object]]::new()
  $current=@{}
  foreach($line in $mountLines){
   $m=[regex]::Match([string]$line,'^\s*(Mount Dir|Image File|Image Index|Mounted Read/Write|Status)\s*:\s*(.*?)\s*$')
   if($m.Success){
    $name=$m.Groups[1].Value;$value=$m.Groups[2].Value.Trim()
    if($name -eq 'Mount Dir' -and $current.Count -gt 0){
     $groups.Add([pscustomobject]@{Fields=$current});$current=@{}
    }
    if($current.ContainsKey($name)){throw ('DISM_DUPLICATE_METADATA_FIELD='+$name)}
    $current[$name]=$value
    Note ('PARSED_FIELD='+$name+';VALUE='+$value)
   }
  }
  if($current.Count -gt 0){$groups.Add([pscustomobject]@{Fields=$current})}
  Note ('PARSED_MOUNT_GROUP_COUNT='+$groups.Count)
  $sameDir=0;$sameCandidate=0
  foreach($item in $groups){
   $fields=$item.Fields
   if($fields.ContainsKey('Mount Dir') -and $fields['Mount Dir'].TrimEnd('\') -ieq $short.TrimEnd('\')){$sameDir++}
   if($fields.ContainsKey('Image File') -and $fields['Image File'] -ieq $candidate){$sameCandidate++}
   Note ('MOUNT_GROUP_FIELD_COUNT='+$fields.Count)
  }
  Note ('OWNER_MOUNT_DIR_MATCHES='+$sameDir)
  Note ('OWNER_CANDIDATE_IMAGE_MATCHES='+$sameCandidate)
  Note '[2/4] PHYSICAL SHORT DIRECTORY EXISTS WITHOUT CHANGES'
  $pathExists=Test-Path -LiteralPath $short
  $dirExists=Test-Path -LiteralPath $short -PathType Container
  Note ('BL38M_PATH_EXISTS='+$pathExists)
  Note ('BL38M_IS_DIRECTORY='+$dirExists)
  if($pathExists){
   $info=Get-Item -LiteralPath $short -Force -ErrorAction Stop
   Note ('BL38M_ATTRIBUTES='+[string]$info.Attributes)
   Note ('BL38M_REPARSE_POINT='+[bool](($info.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0))
   foreach($sub in @('Windows','Windows\System32\config\SOFTWARE','Program Files\WindowsApps')){
    Note ('BL38M_CHILD='+$sub+';EXISTS='+(Test-Path -LiteralPath (Join-Path $short $sub)))
   }
  }
  Note '[3/4] NATIVE REGISTRY HIVELIST READONLY'
  $hiveLines=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1 | ForEach-Object {[string]$_})
  $regExit=[int]$LASTEXITCODE
  Note ('HIVELIST_EXIT='+$regExit)
  if($regExit -ne 0){throw 'HIVELIST_QUERY_FAILED'}
  $blAliases=@($hiveLines|Where-Object {$_ -match '(?i)\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'})
  Note ('BLUELITE_HIVE_ALIAS_COUNT='+$blAliases.Count)
  foreach($line in $blAliases){Note ('BLUELITE_HIVE='+$line.Trim())}
  Note '[4/4] TERMINAL; NO RESOURCE RELEASE ACTION ATTEMPTED'
  if($sameDir -gt 0 -or $sameCandidate -gt 0 -or $blAliases.Count -gt 0){
   $result='HOLD_S38D_EXISTING_MOUNT_OR_HIVE_REQUIRES_OWNER_REVIEW'
  }elseif($groups.Count -gt 0){
   $result='HOLD_S38D_OTHER_MOUNT_PRESENT_NO_ACTION'
  }elseif($dirExists){
   $result='HOLD_S38D_UNTRACKED_MOUNT_DIRECTORY_NO_ACTION'
  }else{
   $result='PASS_S38D_NO_ACTIVE_WIM_MOUNT_OR_BL_HIVE'
  }
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note 'DISM_UNMOUNT_DISCARD=NOT_RUN'
  Note 'REGISTRY_LOAD_UNLOAD=NOT_RUN'
  Note 'WIM_MUTATION=NOT_RUN'
  Note 'S38_POSTCOMMIT_AUDIT=NOT_TESTED_BY_THIS_DIAGNOSTIC'
  Note ('RESULT='+$result)
  Write-Host ('S38D_MAIN_LOG='+$report)
 }
}
