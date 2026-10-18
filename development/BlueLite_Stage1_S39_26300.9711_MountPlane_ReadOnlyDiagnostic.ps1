& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $source='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $sourceSHA='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $candidate='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $candidateSHA='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $previous='C:\work\logs\BlueLite_Stage1_S38R2_26300.9711_AppInstaller_PostCommitReadOnly.txt'
 $previousJson='C:\work\logs\BlueLite_Stage1_S38R2_26300.9711_AppInstaller_PostCommitSnapshot.json'
 $mount='C:\BL39M'
 $report='C:\work\logs\BlueLite_Stage1_S39_26300.9711_MountPlane_ReadOnlyDiagnostic.txt'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 $attempted=$false;$discardOK=$false;$sourceOK=$false;$candidateOK=$false
 $captured=$false;$result='HOLD_S39_9711_MOUNT_PLANE_READONLY_DIAGNOSTIC'
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if($PSVersionTable.PSVersion.Major -ne 7 -or -not $admin){throw 'S39_PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'S39_LOGS_DIR_MISSING'}
 foreach($target in @($mount,$report)){
  if(Test-Path -LiteralPath $target){throw ('S39_OWNED_PATH_ALREADY_EXISTS='+$target)}
 }
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$v){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$v
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$name,[string]$path,[string]$sha){
  if(-not [IO.File]::Exists($path)){throw ('PIN_MISSING='+$name)}
  $got=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if($got -cne $sha){throw ('PIN_FAILED='+$name+';'+$got)}
  Note ('PIN_'+$name+'=PASS')
 }
 function DismProbe([string]$label,[string[]]$args){
  Note ('PROBE_BEGIN='+$label)
  $lines=@(& $dism @args 2>&1|ForEach-Object {[string]$_})
  $code=[int]$LASTEXITCODE
  Note ('PROBE_'+$label+'_EXIT='+$code)
  Note ('PROBE_'+$label+'_LINE_COUNT='+$lines.Count)
  foreach($line in $lines){Note ('PROBE_'+$label+'_RAW='+$line)}
  return $code
 }
 try{
  Note 'STAGE=S39_26300_9711_MOUNT_PLANE_DIAGNOSTIC'
  Note 'MODE=OWNED_SHORT_READONLY_MOUNT_DISCARD_NO_REGISTRY_OR_IMAGE_MUTATION'
  Pin 'S38R2_MAIN' $previous 'CA875A819DF3EFBC749F614DFB5199713A37DB5DAC3C993D0D5BF857404D0E84'
  Pin 'S38R2_JSON' $previousJson 'C448B39978DF02E965237805FED1682C5C2C6D4138DA8361D789AB9CF479BB96'
  if((Get-Item -LiteralPath $candidate -ErrorAction Stop).Length -ne 6551362129L){throw 'CANDIDATE_SIZE_DRIFT'}
  Pin 'S31_SOURCE' $source $sourceSHA
  Pin 'S37_CANDIDATE' $candidate $candidateSHA
  $pre1=DismProbe 'PRE_MOUNTED_WIM' @('/English','/Get-MountedWimInfo')
  $pre2=DismProbe 'PRE_MOUNTED_IMAGE' @('/English','/Get-MountedImageInfo')
  if($pre1 -ne 0 -or $pre2 -ne 0){throw 'PRE_DSIM_PROBE_FAILED'}
  $preRaw=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  if($LASTEXITCODE -ne 0 -or @($preRaw|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count -ne 0){
   throw 'PREEXISTING_MOUNT_NO_NEW_ACTION'
  }
  Note 'PREEXISTING_MOUNT=ZERO_CONFIRMED'
  $null=New-Item -ItemType Directory -Path $mount
  $attempted=$true
  $mountCode=DismProbe 'RO_MOUNT' @('/English','/Mount-Image',('/ImageFile:'+$candidate),
    '/Index:1',('/MountDir:'+$mount),'/ReadOnly')
  Note ('MOUNT_RETURNED_ZERO='+($mountCode -eq 0))
  Note '[1/3] ON-DISK MOUNT PLANE PRESENCE BEFORE ANY DISCARD'
  foreach($name in @('Windows','Windows\System32\config\SOFTWARE',
    'Windows\System32\ntoskrnl.exe','Program Files','Program Files\WindowsApps')){
   $path=Join-Path $mount $name
   Note ('MOUNT_PATH='+$name+';EXISTS='+(Test-Path -LiteralPath $path))
  }
  $children=@(Get-ChildItem -LiteralPath $mount -Force -ErrorAction Stop)
  Note ('MOUNT_ROOT_CHILD_COUNT='+$children.Count)
  foreach($child in $children|Select-Object -First 30){
   Note ('MOUNT_ROOT_CHILD='+$child.Name+';DIRECTORY='+$child.PSIsContainer)
  }
  Note '[2/3] BOTH DISM MOUNT TABLE VIEWS WHILE IMAGE SHOULD BE MOUNTED'
  $table1=DismProbe 'POST_MOUNTED_WIM' @('/English','/Get-MountedWimInfo')
  $table2=DismProbe 'POST_MOUNTED_IMAGE' @('/English','/Get-MountedImageInfo')
  $captured=$true
  Note ('POST_MOUNT_PROBE_CODES='+$table1+','+$table2)
  Note 'MOUNT_OWNER_OR_CONTENT_NOT_ASSUMED_BY_PROBE_EXIT_CODE'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note '[3/3] EXACT OWNED READONLY DISCARD AND SHA RECHECK'
  if($attempted){
   try{
    $ec=DismProbe 'DISCARD_OWNED_RO' @('/English','/Unmount-Image',('/MountDir:'+$mount),'/Discard')
    $discardOK=($ec -eq 0)
    Note ('S39_NATIVE_DISCARD_CONFIRMED='+$discardOK)
   }catch{Note ('DISCARD_PROBE_ERROR='+$_.Exception.Message)}
  }else{
   Note 'DISCARD_NOT_ATTEMPTED_NO_NEW_MOUNT'
  }
  try{
   $null=DismProbe 'AFTER_DISCARD_MOUNTED_WIM' @('/English','/Get-MountedWimInfo')
  }catch{Note ('POST_DISCARD_QUERY_ERROR='+$_.Exception.Message)}
  try{
   if([IO.File]::Exists($source) -and (Get-Item -LiteralPath $source).Length -eq 6509216853L){
    $sourceOK=((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ceq $sourceSHA)
   }
  }catch{Note ('SOURCE_SHA_ERROR='+$_.Exception.Message)}
  try{
   if([IO.File]::Exists($candidate) -and (Get-Item -LiteralPath $candidate).Length -eq 6551362129L){
    $candidateOK=((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash -ceq $candidateSHA)
   }
  }catch{Note ('CANDIDATE_SHA_ERROR='+$_.Exception.Message)}
  Note ('S31_SOURCE_SHA_UNCHANGED='+$sourceOK)
  Note ('S37_CANDIDATE_SHA_UNCHANGED='+$candidateOK)
  if($captured -and $discardOK -and $sourceOK -and $candidateOK){
   $result='PASS_S39_9711_MOUNT_PLANE_EVIDENCE_COLLECTED_READONLY'
  }
  Note 'PASS_S39_IS_DIAGNOSTIC_ONLY_NOT_A_POSTCOMMIT_AUDIT'
  Note 'ORIGINAL_OR_CANDIDATE_MUTATION=NOT_RUN'
  Note 'FINAL_RELEASE_CERTIFICATION=NOT_GRANTED'
  Note ('RESULT='+$result)
  Write-Host ('MAIN_LOG='+$report)
 }
}
