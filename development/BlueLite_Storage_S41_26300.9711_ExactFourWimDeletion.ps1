& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $root='C:\work'
 $logs='C:\work\logs'
 $report=Join-Path $logs 'BlueLite_Storage_S41_26300.9711_ExactFourWimDeletion.txt'
 $s31='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $g5='C:\work\G5\R133_26200_9711_R4_Disposable_20261016\install.r130-r4-disposable.wim'
 $uup='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 $result='HOLD_S41_EXACT_FOUR_WIM_DELETION'
 $preflight=$false;$allDeleted=$false;$postProtected=$false
 $deleted=[System.Collections.Generic.List[object]]::new()
 $targets=@(
  [pscustomobject]@{
   Stage='S23_CLEANED_MUTABLE'
   Path='C:\work\E2E\BlueLite_Stage1_S23_26300.9711_MUTABLE\install.wim'
   Bytes=9016114092L;SHA='BF5646DEB600AD63B43FBD73070169AB2B29F5C65E1F643914D9B83C08627ABA'
  },
  [pscustomobject]@{
   Stage='S20_INITIAL_CONVERTER_OUTPUT'
   Path='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\26300.9711.261009-2244.26H2_GE_RELEASE_SVC_PROD1_CLIENTPRO_OEMRET_X64FRE_EN-US\sources\install.wim'
   Bytes=8969178010L;SHA='587B1A065B85ED08FE5D9E71E60D5E3B1406B5FEF061FFC2E8F0267425DBB228'
  },
  [pscustomobject]@{
   Stage='S28_GREEN_CHECKPOINT'
   Path='C:\work\E2E\BlueLite_Stage1_S28_26300.9711_GreenCapabilities\install.wim'
   Bytes=6467485131L;SHA='32A913A01FC1CE26B213128888448B0BCFD0DFCAE8C8E9F57E5A2F42576DFABA'
  },
  [pscustomobject]@{
   Stage='S26_FRESH_EXPORT'
   Path='C:\work\E2E\BlueLite_Stage1_S26_26300.9711_FreshExport\install.wim'
   Bytes=6423868607L;SHA='8A79773464E6F2CDDDD67ACA5DC59F8BB9CBA41E36D5CBB9C82A73F1F5C995B1'
  }
 )
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
 if(-not $admin){throw 'PS7_ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath $logs -PathType Container)){throw 'LOG_DIR_MISSING'}
 if(Test-Path -LiteralPath $report){throw 'S41_LOG_ALREADY_EXISTS_NO_OVERWRITE'}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$message){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$label,[string]$file,[string]$sha,[long]$bytes){
  if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw ('EVIDENCE_MISSING='+$label)}
  $item=Get-Item -LiteralPath $file -Force -ErrorAction Stop
  if($bytes -ge 0 -and $item.Length -ne $bytes){throw ('PIN_SIZE_MISMATCH='+$label+';'+$item.Length)}
  $got=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
  if($got -cne $sha){throw ('PIN_SHA_MISMATCH='+$label+';'+$got)}
  Note ('PIN_'+$label+'=PASS;BYTES='+$item.Length+';SHA256='+$got)
 }
 function AssertNoReparse([string]$file){
  $item=Get-Item -LiteralPath $file -Force -ErrorAction Stop
  if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('REPARSE_TARGET_FORBIDDEN='+$file)}
  $dir=$item.Directory
  while($null -ne $dir){
   if(($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('REPARSE_PARENT_FORBIDDEN='+$dir.FullName)}
   if($dir.FullName.TrimEnd('\') -ieq $root.TrimEnd('\')){return}
   $dir=$dir.Parent
  }
  throw ('PATH_NOT_UNDER_OWNED_ROOT='+$file)
 }
 try{
  Note 'STAGE=S41_26300_9711_EXACT_FOUR_OLD_WIM_DELETION'
  Note 'SCOPE=FOUR_EXPLICIT_FILES_ONLY_NO_WILDCARD_NO_RECURSION_NO_UUP_OR_G5'
  if($targets.Count -ne 4){throw 'EXACT_ALLOWLIST_COUNT_NOT_FOUR'}
  $uniq=@($targets|Select-Object -ExpandProperty Path -Unique)
  if($uniq.Count -ne 4){throw 'ALLOWLIST_DUPLICATE'}
  $expected=[long]30876645840
  $sum=[long]0;foreach($t in $targets){$sum += [long]$t.Bytes}
  if($sum -ne $expected){throw 'ALLOWLIST_EXPECTED_BYTES_DRIFT'}
  Note '[1/4] PIN ORIGINAL S40 AND HISTORICAL REUSABLE EVIDENCE'
  $s40txt=Join-Path $logs 'BlueLite_Storage_S40_26300.9711_ReadOnlyInventory.txt'
  $s40csv=Join-Path $logs 'BlueLite_Storage_S40_26300.9711_ImageAndLargeFiles.csv'
  Pin 'S40_MAIN_ORIGINAL' $s40txt 'A78017708CD4959998857B7DAA65FC863DC9D8F4B86774071694B18F6CA0588C' 30438
  Pin 'S40_CSV_ORIGINAL' $s40csv '3AA43372C5ECA93C3C14C1B970D3C918DDD002C3CD3B901A0F73D0BC1704D8AB' 71640
  $prior=[IO.File]::ReadAllText($s40txt)
  if(-not $prior.Contains('RESULT=PASS_S40_READONLY_INVENTORY_READY_TO_CLASSIFY') -or
     -not $prior.Contains('ZERO_MOUNTS=True;ZERO_BLUE_HIVES=True')){throw 'S40_NATIVE_INVENTORY_NOT_PASS'}
  $rows=@(Import-Csv -LiteralPath $s40csv -Encoding utf8)
  if($rows.Count -ne 279){throw 'S40_CSV_RECORD_COUNT_CHANGED'}
  foreach($t in $targets){
   $match=@($rows|Where-Object {$_.Path -ieq $t.Path})
   if($match.Count -ne 1 -or [long]$match[0].Bytes -ne $t.Bytes -or
      $match[0].Category -cne 'REVIEW_POSSIBLE_DISPOSABLE'){
    throw ('S40_ALLOWLIST_CSV_MISMATCH='+$t.Stage)
   }
   Note ('S40_CSV_TARGET=PASS;STAGE='+$t.Stage+';BYTES='+$t.Bytes)
  }
  $evidence=@(
   @('S21_CONVERTER','BlueLite_Stage1_S21_26300.9711_Converter_v127_FirstRun.txt','E132BAFCF6D85BC9AA09A5B662808D0197A89954194954C62A7987507977065D',1306),
   @('S25_CBS_CLEANUP','BlueLite_Stage1_S25R1_26300.9711_Native_CBS_Cleanup.txt','94DFBE1EA6DD097D7AE1D5D1951B0BC11260E7BA44D7432CE1E7671E489C2F5F',-1),
   @('S26_FRESH_EXPORT','BlueLite_Stage1_S26_26300.9711_FreshWIM_Export.txt','C570731B7BB46FD70D32CC65702C044DE824FE0075E11E9D8E3088D428F06306',2242),
   @('S28_GREEN_CAPABILITIES','BlueLite_Stage1_S28_26300.9711_Native_GreenCapabilities.txt','7E54D4C1C51A65509F9C1294E0F18E01A230332CBD28CA24A854ECE1C7A0B5FC',29629),
   @('S31_ONEDRIVE','BlueLite_Stage1_S31_26300.9711_OneDrive_AMBER_Apply.txt','0BEE37DAD57F111F878EAF37C5EFB9B0B59BF68C4B7ED638F067008603C20DF6',8111),
   @('S38R3_NATIVE','BlueLite_Stage1_S38R3_26300.9711_AppInstaller_PostCommitReadOnly.txt','E8DF9623888B6AECA976FDEEAC19FB04324A57F4D91A649D92247B479943BD08',6159)
  )
  foreach($e in $evidence){Pin ([string]$e[0]) (Join-Path $logs $e[1]) ([string]$e[2]) ([long]$e[3])}
  $s38json=Join-Path $logs 'BlueLite_Stage1_S38R3_26300.9711_AppInstaller_PostCommitSnapshot.json'
  Pin 'S38R3_NATIVE_JSON' $s38json '9F1AF74B8C9F6B21E136B40D33109E5B20043869DE74109010A558D25CEE63BA' 4101
  $s38state=Get-Content -LiteralPath $s38json -Raw -Encoding utf8 | ConvertFrom-Json
  if(-not $s38state.ReadonlyAuditSucceeded -or $s38state.FinalReleaseCertificateGranted -or
     @($s38state.ExpectedNinePackages).Count -ne 9 -or
     @($s38state.InspectedOfflineRegistry).Count -ne 10){throw 'INDEPENDENT_S38R3_POSTCOMMIT_EVIDENCE_NOT_PASS'}
  Note 'S38R3_POSTCOMMIT_SNAPSHOT=PASS_VERIFIED_NOT_RELEASE'
  Note '[2/4] PROTECTED WIMS, UUP/G5, ACTIVE MOUNT/HIVE GATES'
  Pin 'IMMUTABLE_S31_KEEP' $s31 'F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B' 6509216853
  Pin 'CURRENT_S37_KEEP' $s37 'A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F' 6551362129
  if(-not(Test-Path -LiteralPath $uup -PathType Container)){throw 'ORIGINAL_UUP_SOURCE_NOT_FOUND'}
  if(-not(Test-Path -LiteralPath $g5 -PathType Leaf) -or
     (Get-Item -LiteralPath $g5).Length -ne 8989749806L){throw 'HISTORICAL_G5_REGRESSION_WIM_NOT_PRESENT_OR_SIZE_CHANGED'}
  $raw=@(& $dism /English /Get-MountedWimInfo 2>&1|ForEach-Object {[string]$_})
  $exit=[int]$LASTEXITCODE
  $table=$raw -join [Environment]::NewLine
  $mountRecords=@($raw|Where-Object {$_ -match '^\s*Mount Dir\s*:'})
  if($exit -ne 0 -or -not $table.Contains('The operation completed successfully.') -or
     $table.Contains('DISM.exe [dism_options]') -or $mountRecords.Count -ne 0 -or
     -not $table.Contains('No mounted images found.')){throw 'ACTIVE_OR_UNPROVEN_DISM_MOUNT'}
  Note 'NATIVE_DISM_MOUNTS=PASS_ZERO'
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1|ForEach-Object {[string]$_})
  $regExit=[int]$LASTEXITCODE
  $blue=@($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'})
  if($regExit -ne 0 -or $blue.Count -ne 0){throw 'ACTIVE_OR_UNPROVEN_BL_HIVES'}
  Note 'NATIVE_BLUE_HIVE_ALIASES=PASS_ZERO'
  Note '[3/4] PREHASH AND PATH SCOPE VERIFY ALL FOUR BEFORE FIRST DELETE'
  foreach($t in $targets){
   if($t.Path -ieq $s31 -or $t.Path -ieq $s37 -or $t.Path -ieq $g5){throw 'ALLOWLIST_CONTAINS_PROTECTED_IMAGE'}
   if(-not $t.Path.StartsWith('C:\work\E2E\BlueLite_Stage1_', [StringComparison]::OrdinalIgnoreCase)){throw ('TARGET_OUTSIDE_STAGE1_E2E='+$t.Stage)}
   AssertNoReparse $t.Path
   Pin ('DELETE_CANDIDATE_'+$t.Stage) $t.Path $t.SHA $t.Bytes
  }
  $preflight=$true
  $freeBefore=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('S41_ALL_FOUR_PREFLIGHT=PASS;LOGICAL_BYTES='+$sum+';DISK_FREE_BEFORE='+$freeBefore)
  Note '[4/4] REMOVE ONLY FOUR EXACT FILE PATHS; DO NOT REMOVE DIRECTORIES'
  foreach($t in $targets){
   Remove-Item -LiteralPath $t.Path -Force -ErrorAction Stop
   if(Test-Path -LiteralPath $t.Path){throw ('POSTDELETE_TARGET_STILL_EXISTS='+$t.Stage)}
   $deleted.Add([pscustomobject]@{Stage=$t.Stage;Path=$t.Path;Bytes=$t.Bytes;SHA256=$t.SHA})
   Note ('S41_REMOVED='+$t.Stage+';BYTES='+$t.Bytes+';PATH='+$t.Path)
  }
  $allDeleted=($deleted.Count -eq 4)
  $freeAfter=[IO.DriveInfo]::new('C').AvailableFreeSpace
  Note ('DISK_FREE_AFTER='+$freeAfter)
  Note ('OBSERVED_C_FREE_BYTE_DELTA='+($freeAfter-$freeBefore))
  Note ('TOTAL_LOGICAL_FILE_BYTES_REMOVED='+$sum)
  $protected31=(Get-Item -LiteralPath $s31 -ErrorAction Stop).Length -eq 6509216853L -and
    (Get-FileHash -LiteralPath $s31 -Algorithm SHA256).Hash -ceq 'F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
  $protected37=(Get-Item -LiteralPath $s37 -ErrorAction Stop).Length -eq 6551362129L -and
    (Get-FileHash -LiteralPath $s37 -Algorithm SHA256).Hash -ceq 'A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
  $postProtected=$protected31 -and $protected37
  Note ('S31_S37_POSTDELETE_SHA_UNCHANGED='+$postProtected)
  if($allDeleted -and $postProtected){$result='PASS_S41_EXACT_FOUR_SUPERSEDED_WIM_FILES_REMOVED'}
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  Note ('S41_PREFLIGHT_ALL_PASSED='+$preflight+';REMOVED_COUNT='+$deleted.Count)
  Note ('S41_ALL_FOUR_REMOVED='+$allDeleted+';S31_S37_POST_PROTECTION='+$postProtected)
  Note 'S20_STAGED_UUP=KEEP;ORIGINAL_UUP=KEEP;G5_REGRESSION=KEEP'
  Note 'DIRECTORY_RECURSIVE_DELETE=NOT_RUN;NTLITE=NOT_RUN;WIM_COPY=NOT_RUN'
  Note ('RESULT='+$result)
  Write-Host ('S41_REPORT='+$report)
 }
}
