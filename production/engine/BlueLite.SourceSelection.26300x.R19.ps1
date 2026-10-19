# BlueLite R19 independent 26300.9807 ISO local source selection, metadata only.
[CmdletBinding()]
param([string]$ExtraRoot='', [string]$ReportPath='C:\work\logs\BlueLite_26300_9807_SourceSelection_R19.txt')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($PSVersionTable.PSVersion.Major -ne 7){throw 'BL_R19_PS7_REQUIRED'}
$admin=[Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $admin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'BL_R19_ADMIN_REQUIRED'}
$report=[IO.Path]::GetFullPath($ReportPath)
if([IO.File]::Exists($report)){throw 'BL_R19_REPORT_NO_OVERWRITE'}
if(-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($report))){throw 'BL_R19_LOG_DIR_MISSING'}
$old='C:\work\logs\BlueLite_MAXPRE_NativeGreenDispatcher_R18.txt'
if(-not [IO.File]::Exists($old) -or
 (Get-Item -LiteralPath $old).Length -ne 595 -or
 (Get-FileHash -LiteralPath $old -Algorithm SHA256).Hash -cne 'CC41506716DD32EEB7DEA8B15099D0B7A97D8C118DA2471BCA35582B5DA9B7DD'){
 throw 'BL_R19_ORIGINAL_R18_LOG_PIN_MISSING'
}
$original=[IO.File]::ReadAllText($old)
foreach($required in @('RESULT=PASS_R18_NATIVE_DISPATCHER_SOURCE_BOUND_FASTPATH_NOOP_ONLY','GREEN_QUEUE_COUNT=0;WEBVIEW=ALREADY_ABSENT;SENSE=KEEP','SOURCE_POST_SHA_BYTES=PASS','ZERO_MOUNTS_POST=PASS')){
 if(-not $original.Contains($required)){throw ('BL_R19_R18_SEMANTIC_DRIFT_'+$required)}
}
$enc=[Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($report,'',$enc)
function Note([string]$line){
 Write-Host $line
 [IO.File]::AppendAllText($report,$line+[Environment]::NewLine,$enc)
}
function Short([string]$path){
 return $path.Replace([char]13,[char]95).Replace([char]10,[char]95).Replace([char]124,[char]95)
}
$known='C:\work\UUP_Source\26300.9807_687d1ced'
Note 'BLUELITE_R19_LOCAL_26300_9807_SOURCE_SELECTION'
Note 'R18_SOURCE_PIN_AND_ACTUAL_PASS=PASS'
Note 'MODE=METADATA_ONLY;WINDOWS_DOWNLOAD=NONE;WIM_MOUNT=NONE'
Note 'REFERENCE_FINAL_ISO_SIZE=8094824448;SIZE_ONLY_NOT_VERSION_OR_SHA_PROOF'
Note ('FROZEN_UUP_ROOT='+$known+';EXISTS='+[IO.Directory]::Exists($known))
if([IO.Directory]::Exists($known)){
 $flat=@(Get-ChildItem -LiteralPath $known -Force -ErrorAction SilentlyContinue)
 $fi=@($flat|Where-Object {-not $_.PSIsContainer -and -not (($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)})
 Note ('FROZEN_UUP_IMMEDIATE_FILES='+$fi.Count+';DIRS='+@($flat|Where-Object {$_.PSIsContainer}).Count+';IMMEDIATE_BYTES='+(($fi|Measure-Object Length -Sum).Sum))
}
$roots=[Collections.Generic.List[object]]::new()
function Root([string]$path,[int]$depth,[string]$tag){
 if([string]::IsNullOrWhiteSpace($path)){return}
 $full=[IO.Path]::GetFullPath($path)
 if([IO.Directory]::Exists($full)){[void]$roots.Add([pscustomobject]@{Path=$full;Depth=$depth;Tag=$tag})}
}
Root 'C:\work\E2E' 6 'PROJECT'
Root $known 5 'UUP_SOURCE'
Root 'C:\work' 4 'WORK'
Root 'C:\work\Downloads' 4 'WORK_DL'
Root (Join-Path $env:USERPROFILE 'Downloads') 6 'USER_DL'
Root (Join-Path $env:USERPROFILE 'Desktop') 4 'DESKTOP'
if($ExtraRoot){Root $ExtraRoot 7 'EXTRA'}
foreach($d in [IO.DriveInfo]::GetDrives()){
 if($d.IsReady -and $d.DriveType -eq [IO.DriveType]::Fixed){Root $d.RootDirectory.FullName 2 'DRIVE_TOP'}
}
Note ('ROOTS='+$roots.Count)
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$candidates=[Collections.Generic.List[object]]::new()
$errors=0;$reparse=0;$folders=0;$limit=6000
$bounded=$false
foreach($root in $roots){
 if($bounded){break}
 Note ('ROOT='+[string](Short $root.Path)+';DEPTH='+$root.Depth+';TYPE='+$root.Tag)
 $stack=[Collections.Generic.Stack[object]]::new()
 $stack.Push([pscustomobject]@{Path=$root.Path;N=0})
 while($stack.Count -gt 0){
  if($folders -ge $limit -or $candidates.Count -ge 100){$bounded=$true;break}
  $node=$stack.Pop()
  if(-not $seen.Add([string]$node.Path)){continue}
  $folders++
  try{$entries=@(Get-ChildItem -LiteralPath $node.Path -Force -ErrorAction Stop)}
  catch{$errors++;continue}
  foreach($item in $entries){
   if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){$reparse++;continue}
   if($item.PSIsContainer){
    if($node.N -lt $root.Depth){
     if($root.Tag -eq 'DRIVE_TOP' -and $item.Name -match '^(Windows|Program Files|Program Files \(x86\)|ProgramData|System Volume Information|\$Recycle\.Bin)$'){continue}
     $stack.Push([pscustomobject]@{Path=$item.FullName;N=$node.N+1})
    }
    continue
   }
   $ext=[IO.Path]::GetExtension($item.Name).ToLowerInvariant()
   $iso=$ext -eq '.iso' -and ($item.Length -eq 8094824448 -or $item.Name -match '(?i)(26300|9807|26h2)')
   $wim=$ext -in @('.wim','.esd') -and $item.FullName -match '(?i)(26300\.9807|9807)'
   if(-not ($iso -or $wim)){continue}
   $tier=if($iso -and $item.Length -eq 8094824448){'ORIGINAL_ISO_TIMELINE_SIZE_MATCH'}elseif($iso){'ISO_NAME_MATCH_UNVERIFIED'}else{'WIM_PATH_MATCH_UNVERIFIED'}
   [void]$candidates.Add([pscustomobject]@{Tier=$tier;Path=$item.FullName;Bytes=$item.Length})
   if($candidates.Count -ge 100){$bounded=$true;break}
  }
 }
}
Note ('FOLDERS_VISITED='+$folders+';ACCESS_ERRORS='+$errors+';REPARSE_SKIPPED='+$reparse+';LIMIT_REACHED='+$bounded)
Note ('CANDIDATES='+$candidates.Count)
$ordered=@($candidates|Sort-Object @{Expression={if($_.Tier -eq 'ORIGINAL_ISO_TIMELINE_SIZE_MATCH'){0}elseif($_.Tier -eq 'ISO_NAME_MATCH_UNVERIFIED'){1}else{2}}},Path -Unique)
foreach($c in $ordered){Note ('CANDIDATE='+$c.Tier+';BYTES='+$c.Bytes+';PATH='+[string](Short $c.Path))}
$exact=@($ordered|Where-Object {$_.Tier -eq 'ORIGINAL_ISO_TIMELINE_SIZE_MATCH'})
if($exact.Count -eq 1){
 Note ('SOURCE_SELECTION=ONE_ISO_SIZE_MATCH_NEEDS_FULL_SHA_AND_WIN11_26300_VERSION_PROOF;PATH='+[string](Short $exact[0].Path))
}elseif($exact.Count -gt 1){
 Note 'SOURCE_SELECTION=MULTIPLE_ISO_SIZE_MATCHES_OPERATOR_EXACT_PATH_NEEDED'
}elseif($ordered.Count -gt 0){
 Note 'SOURCE_SELECTION=WEAK_CANDIDATE_ONLY_OPERATOR_EXACT_SOURCE_PATH_NEEDED'
}else{
 Note 'SOURCE_SELECTION=NOT_FOUND_IN_BOUNDED_LOCAL_ROOTS_OPERATOR_EXACT_PATH_NEEDED'
}
Note 'NEXT=PIN_VERIFIED_ORIGINAL_9807_ISO_AND_WIM_INDEX_BEFORE_ANY_MUTATION'
Note 'RESULT=PASS_R19_LOCAL_SOURCE_SELECTION_METADATA_ONLY'
Note 'NO_NETWORK_NO_HASH_OF_GB_IMAGES_NO_WIM_CLONE_NO_DISM_MOUNT_NO_MUTATION'
