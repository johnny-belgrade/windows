# R041 final-only audit of CLOSED UUP logs. No changes to original sources/images.
[CmdletBinding()]
param(
 [ValidateSet('Pack','Verify')][string]$Mode='Pack',
 [Parameter(Mandatory=$true)][string]$CycleRoot,
 [int]$NativeExit=17
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
$root=[IO.Path]::GetFullPath($CycleRoot).TrimEnd([char]92,[char]47)
$logs=Join-Path $root 'BlueLite_Logs'
$zipPath=Join-Path $logs 'BlueLite_R041_EVIDENCE.zip'
$manifestPath=Join-Path $logs 'BlueLite_R041_EvidenceManifest.json'
function Need([bool]$OK,[string]$Why){if(-not $OK){throw ('R041_EVIDENCE_HOLD_'+$Why)}}
function Sha([string]$P){(Get-FileHash -LiteralPath $P -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function SaveNew([string]$P,$Obj){
 $data=[Text.UTF8Encoding]::new($false).GetBytes(($Obj|ConvertTo-Json -Depth 14)+[Environment]::NewLine)
 $s=[IO.File]::Open($P,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$s.Write($data,0,$data.Length)}finally{$s.Dispose()}
}
function EligibleFile([IO.FileInfo]$File){
 if($File.Name -match '^BlueLite_R041_EVIDENCE\.zip$'){return $false}
 if($File.Name -match '^BlueLite_R041_EvidenceVerify_'){return $false}
 if($File.Name -eq 'BlueLite_R041_EvidenceManifest.json'){return $false}
 if($File.Length -gt 20000000L){return $false}
 if($File.Name -notmatch '^[A-Za-z0-9_.-]+$'){return $false}
 if($File.Extension -eq '.zip'){return ($File.Name -eq 'BlueLite_R035_EVIDENCE.zip')}
 if($File.Extension -in @('.txt','.json','.log','.csv')){
  try{
   $t=[IO.File]::ReadAllText($File.FullName)
   if($t -match '(?i)(?:[?&](?:sig|signature|token|auth|authorization|access_token|se|sp|sv)=)[^ \r\n]+'){return $false}
  }catch{return $false}
 }
 return $true
}
try {
 Need ([IO.Directory]::Exists($root) -and [IO.Directory]::Exists($logs)) 'SELECTED_CYCLE_ROOT_OR_LOGS_MISSING'
 Need (([IO.File]::GetAttributes($root) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'CYCLE_ROOT_REPARSE'
 Need ([IO.File]::Exists((Join-Path $logs 'UUP_post-debloat_info.txt'))) 'FINAL_INFO_REPORT_NOT_YET_CLOSED'
 Need ([IO.File]::Exists((Join-Path $logs 'BlueLite_R041_CMD_Bootstrap.log'))) 'EARLY_CMD_BOOTSTRAP_MISSING'
 Need ([IO.File]::Exists((Join-Path $logs 'BlueLite_R035_CMD_Bootstrap.log'))) 'NATIVE_CMD_BOOTSTRAP_MISSING'
 $nativeBoot=[IO.File]::ReadAllText((Join-Path $logs 'BlueLite_R035_CMD_Bootstrap.log'))
 Need ($nativeBoot.Contains('R035_CMD_END native_exit=')) 'NATIVE_BOOTSTRAP_NOT_CLOSED'
 if($Mode -eq 'Pack'){
  Need (-not [IO.File]::Exists($zipPath) -and -not [IO.File]::Exists($manifestPath)) 'PREVIOUS_EVIDENCE_EXISTS_DO_NOT_OVERWRITE'
  $included=[Collections.Generic.List[object]]::new()
  $skipped=[Collections.Generic.List[string]]::new()
  foreach($f in @(Get-ChildItem -LiteralPath $logs -File | Sort-Object Name)){
   if(EligibleFile $f){
    $included.Add([pscustomobject]@{name=$f.Name;bytes=[long]$f.Length;sha256=(Sha $f.FullName)})
   }else{$skipped.Add($f.Name)}
  }
  $names=@($included | ForEach-Object {$_.name})
  foreach($mandatory in @('UUP_post-debloat_info.txt','BlueLite_R041_CMD_Bootstrap.log','BlueLite_R035_CMD_Bootstrap.log')){
   Need ($names -ccontains $mandatory) ('REQUIRED_LOG_EXCLUDED_'+$mandatory)
  }
  $manifest=[ordered]@{
    schema='BlueLite.R041.FinalClosedLogArchive.v1'
    status='FINAL_REPORT_AND_NATIVE_LOG_HANDLES_CLOSED'
    createdUtc=[DateTime]::UtcNow.ToString('o')
    nativeExit=$NativeExit
    sourceRoot=$root
    members=@($included.ToArray())
    excludedLogFileNames=@($skipped.ToArray())
    unprovenImageBuildOrRelease=$true
  }
  SaveNew $manifestPath $manifest
  $z=[IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
  try{
   foreach($m in @($included.ToArray())){
    $full=Join-Path $logs $m.name
    Need ((Sha $full) -eq $m.sha256 -and [IO.FileInfo]::new($full).Length -eq $m.bytes) ('LOG_CHANGED_BEFORE_ARCHIVE_'+$m.name)
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$full,('BlueLite_Logs/'+$m.name),[IO.Compression.CompressionLevel]::Optimal)
   }
   [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$manifestPath,'BlueLite_Logs/BlueLite_R041_EvidenceManifest.json',[IO.Compression.CompressionLevel]::Optimal)
  }finally{$z.Dispose()}
  Write-Output ("R041_FINAL_CLOSED_LOGS_PACKED ZIP="+$zipPath+" SHA256="+(Sha $zipPath)+" LOGS="+$included.Count+" SKIPPED="+$skipped.Count)
  exit 0
 }
 Need ([IO.File]::Exists($zipPath) -and [IO.File]::Exists($manifestPath)) 'EVIDENCE_ZIP_OR_MANIFEST_MISSING'
 $m=Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
 Need ($m.schema -eq 'BlueLite.R041.FinalClosedLogArchive.v1') 'MANIFEST_SCHEMA_MISMATCH'
 $items=@($m.members)
 Need ($items.Count -ge 3) 'TOO_FEW_CLOSED_LOGS'
 $verify=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $z=[IO.Compression.ZipFile]::OpenRead($zipPath)
 try{
  Need ($z.Entries.Count -eq ($items.Count+1)) 'ZIP_ENTRY_COUNT_CHANGED'
  foreach($row in $items){
   $name=[string]$row.name
   Need ($name -eq [IO.Path]::GetFileName($name) -and $verify.Add($name)) ('UNSAFE_DUPLICATE_MEMBER_'+$name)
   $entry=$z.GetEntry('BlueLite_Logs/'+$name)
   Need ($null -ne $entry -and [long]$entry.Length -eq [long]$row.bytes) ('ARCHIVED_LOG_MISSING_OR_LENGTH_'+$name)
   $stream=$entry.Open()
   try{$digest=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($stream))}finally{$stream.Dispose()}
   Need ($digest -eq [string]$row.sha256 -and $digest -eq (Sha (Join-Path $logs $name))) ('ARCHIVED_LOG_SHA_CHANGED_'+$name)
  }
  $e=$z.GetEntry('BlueLite_Logs/BlueLite_R041_EvidenceManifest.json')
  Need ($null -ne $e) 'MANIFEST_NOT_EMBEDDED'
  $s=$e.Open()
  try{$mh=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($s))}finally{$s.Dispose()}
  Need ($mh -eq (Sha $manifestPath)) 'EMBEDDED_MANIFEST_SHA_MISMATCH'
 }finally{$z.Dispose()}
 $receipt=[ordered]@{
  schema='BlueLite.R041.IndependentFinalArchiveVerify.v1'
  status='INDEPENDENT_ALL_CLOSED_LOGS_SHA_PASS'
  utc=[DateTime]::UtcNow.ToString('o')
  archive=$zipPath
  archive_sha256=(Sha $zipPath)
  archivedLogMembers=$items.Count
  nativeExit=[int]$m.nativeExit
  manifest_sha256=(Sha $manifestPath)
  sourceRoot=$root
  firstCMDLogPresent=$verify.Contains('BlueLite_R041_CMD_Bootstrap.log')
  finalCMDLogPresent=$verify.Contains('BlueLite_R035_CMD_Bootstrap.log')
  finalInfoPresent=$verify.Contains('UUP_post-debloat_info.txt')
  resultScope='LOG_ARCHIVE_ONLY_NOT_WIM_OR_ISO_CERTIFICATION'
 }
 $rv=Join-Path $logs ('BlueLite_R041_EvidenceVerify_'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffffffZ')+'_'+[Guid]::NewGuid().ToString('N').Substring(0,8)+'.json')
 SaveNew $rv $receipt
 Write-Output ('R041_FINAL_EVIDENCE_INDEPENDENT_SHA_PASS ZIP='+$zipPath+' SHA256='+$receipt.archive_sha256+' LOGS='+$items.Count+' VERIFY='+$rv)
 exit 0
}catch{
 [Console]::Error.WriteLine('R041_FINAL_EVIDENCE_HOLD '+$_.Exception.Message)
 exit 17
}
