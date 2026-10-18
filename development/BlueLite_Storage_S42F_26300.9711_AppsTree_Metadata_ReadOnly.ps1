& {
 $ErrorActionPreference='Stop'
 Set-StrictMode -Version Latest
 $root='C:\work'
 $orig='C:\work\E2E\BlueLite_DL_R26_D6_26300.9711_2b22470a\UUPs'
 $stage='C:\work\E2E\BlueLite_Stage1_S20_26300.9711_ConverterWorkspace\UUPs'
 $apps=Join-Path $stage 'Apps'
 $previous='C:\work\logs\BlueLite_Storage_S42E_26300.9711_LayoutAwarePairs.txt'
 $report='C:\work\logs\BlueLite_Storage_S42F_26300.9711_AppsTree.txt'
 $csv='C:\work\logs\BlueLite_Storage_S42F_26300.9711_AppsTree.csv'
 $enc=[Text.UTF8Encoding]::new($false)
 if($PSVersionTable.PSVersion.Major -ne 7){throw 'PS7_REQUIRED'}
 $principal=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'ADMIN_REQUIRED'}
 if(-not(Test-Path -LiteralPath 'C:\work\logs' -PathType Container)){throw 'LOGS_MISSING'}
 foreach($target in @($report,$csv)){
  if(Test-Path -LiteralPath $target){throw 'S42F_OUTPUT_EXISTS_NO_OVERWRITE'}
 }
 [IO.File]::WriteAllText($report,'',$enc)
 [IO.File]::WriteAllText($csv,'Kind,Entry,DescendantFiles,DescendantDirectories,DescendantBytes,ReparseCount,AppxManifestCount,SamplePaths'+[Environment]::NewLine,$enc)
 function Note([string]$message){
  $line=(Get-Date -Format 'HH:mm:ss')+' | '+$message
  Write-Host $line
  [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$enc)
 }
 function GuardDir([string]$path){
  $item=Get-Item -LiteralPath $path -Force -ErrorAction Stop
  if(-not $item.PSIsContainer){throw ('NOT_DIRECTORY='+$path)}
  $current=$item
  $found=$false
  while($null -ne $current){
   if(($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
    throw ('REPARSE_ANCESTOR='+$current.FullName)
   }
   if($current.FullName -ieq $root){$found=$true;break}
   $current=$current.Parent
  }
  if(-not $found){throw ('OUTSIDE_WORK='+$path)}
 }
 $rows=[System.Collections.Generic.List[object]]::new()
 $result='HOLD_S42F_APPS_TREE_METADATA_READONLY'
 try{
  Note 'S42F_READONLY_APPS_TREE_TOPOLOGY'
  Note 'NO_UUP_HASH_NO_DOWNLOAD_NO_DELETE_NO_COPY_NO_CONVERTER_NO_MOUNT'
  $pin=Get-Item -LiteralPath $previous -ErrorAction Stop
  if($pin.Length -ne 595 -or
     (Get-FileHash -LiteralPath $previous -Algorithm SHA256).Hash -cne
       '1D03588CFA978231B3599DC0CE8FE4C5AEDA71A22FF10BC42841848C1BCBD545'){
    throw 'S42E_HOLD_LOG_PIN_MISMATCH'
  }
  Note 'PIN_S42E_ORIGINAL_HOLD=PASS;BYTES=595'
  foreach($path in @($orig,$stage,$apps)){GuardDir $path}
  $origFiles=@(Get-ChildItem -LiteralPath $orig -File -Force -ErrorAction Stop)
  $origDirs=@(Get-ChildItem -LiteralPath $orig -Directory -Force -ErrorAction Stop)
  $stageFiles=@(Get-ChildItem -LiteralPath $stage -File -Force -ErrorAction Stop)
  $stageDirs=@(Get-ChildItem -LiteralPath $stage -Directory -Force -ErrorAction Stop)
  $appsFiles=@(Get-ChildItem -LiteralPath $apps -File -Force -ErrorAction Stop)
  $appsDirs=@(Get-ChildItem -LiteralPath $apps -Directory -Force -ErrorAction Stop)
  Note ('ROOT_COUNTS=ORIGINAL:'+ $origFiles.Count +'/'+$origDirs.Count+
    ';STAGED:'+ $stageFiles.Count+'/'+ $stageDirs.Count+
    ';APPS:'+ $appsFiles.Count+'/'+ $appsDirs.Count)
  $stageNames=@{}
  foreach($file in $stageFiles){$stageNames[$file.Name]=$true}
  $missing=@($origFiles|Where-Object {-not $stageNames.ContainsKey($_.Name)}|Sort-Object Name)
  Note ('ORIGINAL_ROOT_NAMES_ABSENT_FROM_STAGED_ROOT='+$missing.Count)
  foreach($file in $missing){Note ('ORIGINAL_ONLY_NAME='+$file.Name+';BYTES='+$file.Length)}
  $entries=@(Get-ChildItem -LiteralPath $apps -Force -ErrorAction Stop|Sort-Object Name)
  [long]$totalBytes=0
  [long]$totalFiles=0
  [long]$totalDirs=0
  [long]$reparse=0
  [long]$manifests=0
  foreach($entry in $entries){
   $tree=if($entry.PSIsContainer){@(Get-ChildItem -LiteralPath $entry.FullName -Force -Recurse -ErrorAction Stop)}else{@()}
   $all=@($entry)+@($tree)
   $fileCount=0
   $dirCount=0
   [long]$bytes=0
   $links=0
   $manifestCount=0
   $samples=[System.Collections.Generic.List[string]]::new()
   foreach($item in $all){
    if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){
     $links++
     continue
    }
    if($item.PSIsContainer){$dirCount++}
    else{
     $fileCount++
     $bytes += [long]$item.Length
     if($item.Name -ieq 'AppxManifest.xml'){$manifestCount++}
     if($samples.Count -lt 3){$samples.Add($item.FullName.Substring($apps.Length+1))}
    }
   }
   $kind=if($entry.PSIsContainer){'DIRECTORY'}else{'FILE'}
   $sample=($samples.ToArray() -join ' | ')
   $rows.Add([pscustomobject]@{
    Kind=$kind;Entry=$entry.Name;DescendantFiles=$fileCount
    DescendantDirectories=$dirCount;DescendantBytes=$bytes
    ReparseCount=$links;AppxManifestCount=$manifestCount;SamplePaths=$sample
   })
   $totalBytes += $bytes
   $totalFiles += $fileCount
   $totalDirs += $dirCount
   $reparse += $links
   $manifests += $manifestCount
   Note ('ENTRY='+$kind+';NAME='+$entry.Name+
     ';FILES='+$fileCount+';DIRS='+$dirCount+
     ';BYTES='+$bytes+';MANIFESTS='+$manifestCount+';REPARSE='+$links)
  }
  Note ('APPS_TREE_TOTALS=FILES:'+ $totalFiles+';DIRS:'+ $totalDirs+
    ';BYTES:'+ $totalBytes+';APPX_MANIFESTS:'+ $manifests+';REPARSE:'+ $reparse)
  if($reparse -ne 0){throw ('REPARSE_LINKS_FOUND='+$reparse)}
  if($origFiles.Count -ne 129 -or $origDirs.Count -ne 0 -or
     $stageFiles.Count -ne 101 -or $stageDirs.Count -ne 1 -or
     $stageDirs[0].Name -cne 'Apps' -or
     $appsFiles.Count -ne 1 -or $appsDirs.Count -ne 51 -or
     $missing.Count -ne 31 -or $rows.Count -ne 52){
   throw 'S42F_OBSERVED_TOPOLOGY_DRIFT'
  }
  Note 'APPX_INPUT_ARCHIVES_TO_EXTRACTED_TREE_MAPPING=NOT_YET_PROVEN'
  Note 'SOURCE_TO_STAGED_FILE_SHA256=NOT_RUN;S43_DELETION=NOT_AUTHORIZED'
  $result='PASS_S42F_APPS_TREE_METADATA_CAPTURED_ONLY'
 }catch{
  Note ('FAIL_CLOSED='+$_.Exception.Message)
 }finally{
  if($rows.Count -gt 0){
   try{
    $rows|Export-Csv -LiteralPath $csv -Encoding utf8 -NoTypeInformation -ErrorAction Stop
    Note ('CSV_ROWS='+$rows.Count)
   }catch{
    Note ('CSV_EXPORT_ERROR='+$_.Exception.Message)
    $result='HOLD_S42F_CSV_EXPORT'
   }
  }else{
   Note 'CSV_ROWS=0;CSV_HEADER_ONLY'
  }
  Note ('RESULT='+$result)
  Note 'DELETE=NOT_RUN;DOWNLOAD=NOT_RUN;CONVERTER=NOT_RUN;WIM=NOT_TOUCHED'
  Write-Host ('REPORT='+$report)
  Write-Host ('CSV='+$csv)
 }
}