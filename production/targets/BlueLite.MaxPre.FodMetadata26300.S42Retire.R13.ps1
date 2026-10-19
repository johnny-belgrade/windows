# BlueLite R13: retire ONLY two fully-evidenced owned S42 measurement WIMs after R12 PASS.
# Master v6 disposable lifecycle; DO NOT mutate S31/S37/S39/S40/S41.
& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R13_PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R13_ADMIN_REQUIRED'}
 $dir='C:\work\E2E\BlueLite_S42_26300.9711_R12_FodMetadata_EqualMaxExports'
 $root='C:\work\logs'
 $sourceDir='C:\work\E2E'
 $report=Join-Path $root 'BlueLite_MAXPRE_FodMetadata_26300.9711_S42Retire_R13.txt'
 $receipt=Join-Path $root 'BlueLite_MAXPRE_FodMetadata_26300.9711_ExportCompare_R12.txt'
 $s39='C:\work\E2E\BlueLite_Stage1_S39_26300.9711_WebView_FOD_Native_R6\install.webview-disposable.wim'
 $s41='C:\work\E2E\BlueLite_Stage1_S41_26300.9711_FodMetadata_Superseded_R10\install.fodmetadata-disposable.wim'
 $base=Join-Path $dir 'baseline-S39-max.wim'
 $after=Join-Path $dir 'fodmetadata-removed-S41-max.wim'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 if(-not(Test-Path -LiteralPath $root -PathType Container)){throw 'BL_R13_LOGS_DIR_MISSING'}
 if(Test-Path -LiteralPath $report){throw 'BL_R13_REPORT_NO_OVERWRITE'}
 if(-not(Test-Path -LiteralPath $dir -PathType Container)){throw 'BL_R13_OWNED_S42_DIR_MISSING'}
 function Note([string]$msg){
  Write-Host $msg
  [IO.File]::AppendAllText($report,$msg+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$f,[long]$size,[string]$sha,[string]$label){
  $file=Get-Item -LiteralPath $f -Force -ErrorAction Stop
  if($file.PSIsContainer -or $file.Length -ne $size -or
     ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or
     (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash -cne $sha){
   throw ('BL_R13_PIN_MISMATCH_'+$label)
  }
  Note ('PIN_'+$label+'=PASS;BYTES='+$size+';SHA='+$sha)
 }
 function IsPlainDirectory([string]$f,[string]$label){
  $item=Get-Item -LiteralPath $f -Force -ErrorAction Stop
  if(-not $item.PSIsContainer -or
     ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
   throw ('BL_R13_UNTRUSTED_DIRECTORY_'+$label)
  }
 }
 function ZeroMounts([string]$label){
  $rows=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  $empty=@($rows|Where-Object {$_ -match '^\s*No mounted images found\.\s*$'}).Count
  $listed=@($rows|Where-Object {$_ -match '^\s*Mount Dir\s*:'}).Count
  Note ('MOUNTS_'+$label+'_EXIT='+$ec+';EMPTY='+$empty+';ROWS='+$listed)
  if($ec -ne 0 -or $empty -ne 1 -or $listed -ne 0){
   throw ('BL_R13_NOT_ZERO_MOUNTS_'+$label)
  }
 }
 $status='HOLD_R13_S42_RETIRE'
 $deleted=0L
 [IO.File]::WriteAllText($report,'',$utf8)
 try{
  Note 'BLUELITE_R13_EXACT_S42_OWNED_EXPORT_LIFECYCLE_RETIRE'
  Note 'STEP_01_ARCHIVED_R12_ORIGINAL_AND_PROTECTED_FLOOR'
  Pin $receipt 1734L 'AF177CA3A617C87D5ADA926B2E1F93FB4347C337C69C3AED16218B481709BC30' 'R12_ORIGINAL_REPORT'
  $raw=[IO.File]::ReadAllText($receipt)
  foreach($key in @(
   'RESULT=PASS_R12_FODMETADATA_EQUAL_COMPRESSION_DUAL_NATIVE_EXPORT_MEASUREMENT_ONLY',
   'EQUAL_MAX_EXPORT_DELTA_S39_MINUS_S41_BYTES=713456',
   'TWO_SOURCE_WIMS_UNCHANGED=PASS',
   'EXPORTED_S39_DISM_GET_WIM_INFO=PASS',
   'EXPORTED_S41_DISM_GET_WIM_INFO=PASS',
   'EXPORT_S39='+$base,
   'EXPORT_S41='+$after
  )){if(-not $raw.Contains($key)){throw ('BL_R13_R12_REPORT_CONTENT_DRIFT='+$key)}}
  Note 'R12_RESULT_AND_EXACT_ARTIFACT_CONTRACT=PASS'
  Pin $s39 6595075169L '32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED' 'S39_PROTECTED'
  Pin $s41 6636510185L '378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1' 'S41_PROTECTED'
  Note 'STEP_02_OWNED_PATH_CONTENT_MOUNTS_HIVES'
  IsPlainDirectory 'C:\work' 'C_WORK'
  IsPlainDirectory $sourceDir 'E2E'
  IsPlainDirectory $dir 'S42'
  $items=@(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop)
  if($items.Count -ne 2 -or
     @($items|Where-Object {$_.Name -cnotin @('baseline-S39-max.wim','fodmetadata-removed-S41-max.wim')}).Count -ne 0){
   throw 'BL_R13_S42_HAS_UNKNOWN_OR_EXTRA_CONTENT'
  }
  foreach($item in $items){
   if($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw ('BL_R13_NONPLAIN_S42_CONTENT='+$item.Name)
   }
  }
  Note 'S42_ONLY_TWO_EXACT_FILES_NO_LINKS=PASS'
  ZeroMounts 'PRE'
  $h=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1 | ForEach-Object {[string]$_})
  if([int]$LASTEXITCODE -ne 0 -or
     @($h|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BLWEB|BlueLite|FB[0-9])'}).Count -ne 0){
   throw 'BL_R13_PROJECT_OFFLINE_HIVE_PRESENT'
  }
  Note 'PRE_NO_PROJECT_HIVES=PASS'
  Note 'STEP_03_FULL_SHA_OF_BOTH_MEASUREMENT_EXPORTS'
  Pin $base 5557124413L '940746260BE801FA797F2EEACC5D919283975C34A6F1A25E93ECAE1264DA6845' 'S42_BASELINE_S39'
  Pin $after 5556410957L '512F3BE8C0CEBA561EB463D99EF5BC59C7038118E42916CB56D84D855506B3EC' 'S42_REMOVED_S41'
  Note 'STEP_04_EXACT_OWNED_TWO_FILES_ONLY_DELETE'
  foreach($f in @($base,$after)){
   $size=(Get-Item -LiteralPath $f -Force -ErrorAction Stop).Length
   Remove-Item -LiteralPath $f -Force -ErrorAction Stop
   if(Test-Path -LiteralPath $f){throw ('BL_R13_FILE_STILL_EXISTS='+$f)}
   $deleted+=$size
   Note ('OWNED_FILE_DELETED='+$f+';LOGICAL_BYTES='+$size)
  }
  if(@(Get-ChildItem -LiteralPath $dir -Force -ErrorAction Stop).Count -ne 0){
   throw 'BL_R13_OWNED_DIR_NOT_EMPTY_AFTER_TWO_DELETIONS'
  }
  [IO.Directory]::Delete($dir,$false)
  if(Test-Path -LiteralPath $dir){throw 'BL_R13_OWNED_DIR_STILL_EXISTS'}
  Note 'OWNED_S42_DIR_REMOVED=PASS'
  Note 'STEP_05_PROTECTED_IMAGES_POST_AND_MOUNTS'
  Pin $s39 6595075169L '32AD747CD86052BDF6226A25B92A7B051E9946B3D43A591D1EFFD99B265AEBED' 'S39_POST'
  Pin $s41 6636510185L '378B6C7A20D434172EA7AB2F4857C78431393C0B3C1B13D993D8AAF125D6B6B1' 'S41_POST'
  Pin $receipt 1734L 'AF177CA3A617C87D5ADA926B2E1F93FB4347C337C69C3AED16218B481709BC30' 'R12_REPORT_POST'
  ZeroMounts 'POST'
  if($deleted -ne 11113535370L){throw 'BL_R13_DELETED_LOGICAL_BYTES_DIFFER'}
  Note ('OWNED_S42_WIM_LOGICAL_BYTES_DELETED='+$deleted)
  Note 'S31_S37_S39_S40_S41_PROTECTED;S39_S41_POST_SHA_PASS'
  $status='PASS_R13_EXACT_S42_TWO_EXPORT_DISPOSABLES_DELETED_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  Note ('RESULT='+$status)
  Note ('REPORT='+$report)
  Note 'ARCHIVED_R12_EVIDENCE_RETAINED_ON_GITHUB_AND_LOCAL;NO_OTHER_DELETION'
 }
 if($status -ne 'PASS_R13_EXACT_S42_TWO_EXPORT_DISPOSABLES_DELETED_ONLY'){
  throw 'BL_R13_S42_RETIRE_HOLD'
 }
}
