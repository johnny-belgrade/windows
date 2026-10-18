& {
 Set-StrictMode -Version Latest
 $ErrorActionPreference='Stop'
 $PSNativeCommandUseErrorActionPreference=$false
 $root='C:\work'
 $logs='C:\work\logs'
 $report=Join-Path $logs 'BlueLite_Storage_S40_26300.9711_ReadOnlyInventory.txt'
 $csv=Join-Path $logs 'BlueLite_Storage_S40_26300.9711_ImageAndLargeFiles.csv'
 $s31='C:\work\E2E\BlueLite_Stage1_S31_26300.9711_OneDriveAMBER\install.wim'
 $s37='C:\work\E2E\BlueLite_Stage1_S37_26300.9711_FullR4Candidate\install.disposable.wim'
 $p31='F52389FA66F8B60D56661C8786EC99409FB95447403B3C6FCBB94121EF8E340B'
 $p37='A599CF7B7CB44748D738D1F5AD75D1D6C462DD15293755DFFB17F6D2ABE0BE9F'
 $dism=Join-Path $env:SystemRoot 'System32\dism.exe'
 $reg=Join-Path $env:SystemRoot 'System32\reg.exe'
 $utf8=[Text.UTF8Encoding]::new($false)
 $outcome='HOLD_S40_READONLY_STORAGE_INVENTORY'
 $pins=$false;$noMount=$false;$noBlueHives=$false;$scanOK=$false
 $images=@('.wim','.esd','.swm','.iso','.vhd','.vhdx','.ffu','.vdi','.vmdk')
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 if(-not [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath $root -PathType Container) -or -not(Test-Path -LiteralPath $logs -PathType Container)){throw 'C_WORK_OR_LOGS_MISSING'}
 foreach($p in @($report,$csv)){if(Test-Path -LiteralPath $p){throw ('S40_OUTPUT_ALREADY_EXISTS='+$p)}}
 [IO.File]::WriteAllText($report,'',$utf8)
 function Note([string]$msg){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$msg
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$utf8)
 }
 function Pin([string]$tag,[string]$p,[string]$hash,[long]$size){
  if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw ('PIN_FILE_MISSING='+$tag)}
  $n=(Get-Item -LiteralPath $p).Length
  if($n -ne $size){throw ('PIN_SIZE_CHANGED='+$tag)}
  $got=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash
  if($got -cne $hash){throw ('PIN_SHA_CHANGED='+$tag+';'+$got)}
  Note ('PIN_'+$tag+'=PASS;BYTES='+$n+';SHA256='+$got)
 }
 function GroupName([string]$p){
  $parts=$p.Substring($root.Length).TrimStart('\').Split('\')
  if($parts.Count -ge 3 -and $parts[0] -ieq 'E2E'){return ('E2E\'+$parts[1])}
  if($parts.Count -ge 2){return $parts[0]}
  return '(root)'
 }
 try{
  Note 'STAGE=S40_26300_9711_STORAGE_INVENTORY'
  Note 'MODE=READONLY_NO_COPIES_NO_DELETE_NO_MOUNT_OR_UNMOUNT'
  Pin 'S38R3_LOG' (Join-Path $logs 'BlueLite_Stage1_S38R3_26300.9711_AppInstaller_PostCommitReadOnly.txt') 'E8DF9623888B6AECA976FDEEAC19FB04324A57F4D91A649D92247B479943BD08' 6159
  Pin 'S38R3_JSON' (Join-Path $logs 'BlueLite_Stage1_S38R3_26300.9711_AppInstaller_PostCommitSnapshot.json') '9F1AF74B8C9F6B21E136B40D33109E5B20043869DE74109010A558D25CEE63BA' 4101
  Pin 'PROTECT_S31' $s31 $p31 6509216853L
  Pin 'PROTECT_S37' $s37 $p37 6551362129L
  $pins=$true
  $disk=[IO.DriveInfo]::new('C')
  Note ('DISK_C_FREE_BYTES='+$disk.AvailableFreeSpace)
  Note ('DISK_C_TOTAL_BYTES='+$disk.TotalSize)
  Note '[1/3] NATIVE MOUNT/HIVE STATUS'
  $raw=@(& $dism /English /Get-MountedWimInfo 2>&1 | ForEach-Object {[string]$_})
  $ec=[int]$LASTEXITCODE
  foreach($line in $raw){Note ('DISM_RAW='+$line)}
  $str=$raw -join [Environment]::NewLine
  $actual=($ec -eq 0 -and $str.Contains('The operation completed successfully.') -and -not $str.Contains('DISM.exe [dism_options]'))
  $mounted=@($raw|Where-Object {$_ -match '^\s*Mount Dir\s*:'})
  $noMount=($actual -and $mounted.Count -eq 0 -and $str.Contains('No mounted images found.'))
  Note ('DISM_REAL_QUERY='+$actual+';MOUNTS='+$mounted.Count+';NO_MOUNTS='+$noMount)
  $hives=@(& $reg query 'HKLM\SYSTEM\CurrentControlSet\Control\hivelist' 2>&1 | ForEach-Object {[string]$_})
  $hec=[int]$LASTEXITCODE
  $bl=@($hives|Where-Object {$_ -match '(?i)^\s*\\REGISTRY\\MACHINE\\(BL[0-9]|BlueLite|FB[0-9])'})
  foreach($entry in $bl){Note ('BLUE_HIVE='+$entry)}
  $noBlueHives=($hec -eq 0 -and $bl.Count -eq 0)
  Note ('REG_HIVELIST_EXIT='+$hec+';BLUE_HIVES='+$bl.Count+';NONE='+$noBlueHives)
  Note '[2/3] READ METADATA OF FILES UNDER C:\work'
  $errors=@()
  $files=@(Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue -ErrorVariable errors)
  $scanOK=($errors.Count -eq 0)
  Note ('FILES_ENUMERATED='+$files.Count+';ENUMERATION_ERRORS='+$errors.Count)
  foreach($err in $errors|Select-Object -First 10){Note ('ENUM_ERROR='+$err)}
  $selected=[System.Collections.Generic.List[object]]::new()
  foreach($file in $files){
   if($images -notcontains $file.Extension.ToLowerInvariant() -and $file.Length -lt 1073741824L){continue}
   $kind='REVIEW'
   if($file.FullName -ieq $s31){$kind='PROTECT_S31_KEEP'}
   elseif($file.FullName -ieq $s37){$kind='PROTECT_S37_KEEP'}
   elseif($file.FullName -match '(?i)\\G5\\|R133_26200|R130_26200'){$kind='REVIEW_HISTORIC_REGRESSION'}
   elseif($file.FullName -match '(?i)UUP|26300\.9807'){$kind='REVIEW_UUP_OR_SOURCE'}
   elseif($file.FullName -match '(?i)Disposable|\\E2E\\'){$kind='REVIEW_POSSIBLE_DISPOSABLE'}
   $selected.Add([pscustomobject]@{
    Category=$kind;Path=$file.FullName;Bytes=[long]$file.Length;
    GiB=[math]::Round($file.Length/1GB,3);
    Extension=$file.Extension;LastWriteUtc=$file.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ');
    StorageGroup=(GroupName $file.FullName)
   })
  }
  $ordered=@($selected|Sort-Object Bytes -Descending)
  $ordered|Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding utf8
  Note ('CSV='+$csv+';RECORDS='+$ordered.Count)
  Note '[3/3] TOP WORK GROUPS AND LARGE FILES (LOGICAL BYTES)'
  $total=[long]0
  foreach($file in $files){$total += [long]$file.Length}
  Note ('C_WORK_LOGICAL_FILE_BYTES='+$total)
  $groups=@($files|Group-Object -Property {GroupName $_.FullName}|ForEach-Object{
    $bytes=[long]0
    foreach($entry in $_.Group){$bytes += [long]$entry.Length}
    [pscustomobject]@{Name=$_.Name;Bytes=$bytes;Count=$_.Count}
  }|Sort-Object Bytes -Descending)
  foreach($g in $groups|Select-Object -First 40){Note ('GROUP='+$g.Name+';BYTES='+$g.Bytes+';FILES='+$g.Count)}
  foreach($r in $ordered|Select-Object -First 140){Note ('FILE='+$r.Category+';BYTES='+$r.Bytes+';PATH='+$r.Path)}
  Note 'DELETION_AUTHORITY=NOT_GRANTED_BY_INVENTORY'
  if($pins -and $noMount -and $noBlueHives -and $scanOK){
   $outcome='PASS_S40_READONLY_INVENTORY_READY_TO_CLASSIFY'
  }
 }catch{Note ('FAIL_CLOSED='+$_.Exception.Message)}
 finally{
  Note ('PROTECTED_WIM_AND_REPORT_PINS_PASS='+$pins)
  Note ('ZERO_MOUNTS='+$noMount+';ZERO_BLUE_HIVES='+$noBlueHives)
  Note 'WIM_COPIES=ZERO;IMAGE_DELETIONS=ZERO;REGISTRY_MUTATIONS=ZERO'
  Note ('RESULT='+$outcome)
  Write-Host ('S40_REPORT='+$report)
  if(Test-Path -LiteralPath $csv -PathType Leaf){Write-Host ('S40_CSV='+$csv)}
 }
}
