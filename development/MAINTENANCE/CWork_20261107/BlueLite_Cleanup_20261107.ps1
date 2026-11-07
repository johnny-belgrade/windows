# BlueLite v1.0 — operator-only C:\work cleanup of TWO exact failed UUP stages.
# Default Audit performs no deletion. Delete requires exact GUI-entered confirmation.
# All receipts and preserved source logs are in C:\work\BlueLite_Cleanup_20261107\BlueLite_Logs.
[CmdletBinding()]
param(
 [ValidateSet('Audit','Delete')][string]$Mode='Audit',
 [string]$ConfirmPhrase=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function HoldBL([bool]$ok,[string]$reason){if(-not $ok){throw ('BL_CLEANUP_HOLD_'+$reason)}}
function HashBL([string]$p){(Get-FileHash -LiteralPath $p -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function WriteJsonBL([string]$p,$value) {
 if(Test-Path -LiteralPath $p){throw ('BL_CLEANUP_REPORT_ALREADY_EXISTS_'+$p)}
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($value|ConvertTo-Json -Depth 16)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
function FolderBL([string]$p,[long]$expectedBytes,[int]$expectedCount) {
 HoldBL (Test-Path -LiteralPath $p -PathType Container) ('STAGE_MISSING_'+$p)
 HoldBL (([IO.File]::GetAttributes($p) -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_STAGE_'+$p)
 $dirs=@(Get-ChildItem -LiteralPath $p -Force -Directory -Recurse -ErrorAction Stop)
 foreach($d in $dirs){HoldBL (($d.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_DIR_'+$d.FullName)}
 $files=@(Get-ChildItem -LiteralPath $p -Force -File -Recurse -ErrorAction Stop)
 $total=0L
 foreach($f in $files){HoldBL (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) ('REPARSE_FILE_'+$f.FullName);$total+=[long]$f.Length}
 HoldBL ($files.Count -eq $expectedCount -and $total -eq $expectedBytes) ('STAGE_DRIFT_'+$p+'_files_'+$files.Count+'_bytes_'+$total)
 return [pscustomobject]@{path=$p;files=$files.Count;logicalBytes=$total}
}
$package='C:\work\BlueLite_Cleanup_20261107'
$logs=Join-Path $package 'BlueLite_Logs'
$original='C:\work\26300.9818-UUP-MAX_PRE_26300_v4'
$srcOriginal=Join-Path $original 'UUPs'
$stageR027='C:\work\_UUP_PREMAX_v11.2\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_734c2696'
$stageR028='C:\work\PREMAX-work\R028_Universal_Full_UUP_20261107\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_273212e7'
$stages=@(
 [pscustomobject]@{tag='R028_FAILED';path=$stageR028;bytes=19273553336L;count=1400;kind='COM_ERROR_0x8007007A'},
 [pscustomobject]@{tag='R027_FAILED';path=$stageR027;bytes=25061978653L;count=1404;kind='FALSE_WIM_IDENTITY_GATE'}
)
$proof=Join-Path $logs 'CWork_20261107T1650576887287Z_UUP_3way_SHA256.csv'
$expectedProofSHA='872B94D2FE8BC5E7F9BEC8536B29D3D641DE50E4FDA4E81988C0894F702268DD'
$iso=Join-Path $original '26300.9818.261025-0959.26H2_GE_RELEASE_SVC_PROD3_CLIENTPRO_OEMRET_X64FRE_EN-US.ISO'
$goldenWim=Join-Path $original 'install.wim'
$prefix='BlueLite_Cleanup_20261107_V3_'+$Mode.ToUpperInvariant()
$receipt=Join-Path $logs ($prefix+'_RESULT.json')
$evidence=Join-Path $logs ($prefix+'_EVIDENCE.zip')
$started=Join-Path $logs ($prefix+'_STARTED.json')
$state='NOT_STARTED'
$removed=@()
$freeBefore=0L
try {
 HoldBL ([IO.Path]::GetFullPath($package).TrimEnd('\') -ceq 'C:\work\BlueLite_Cleanup_20261107') 'WRONG_CLEANUP_PACKAGE_ROOT'
 HoldBL (Test-Path -LiteralPath $logs -PathType Container) 'LOGS_MISSING'
 HoldBL (([IO.File]::GetAttributes($package) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'PACKAGE_REPARSE'
 HoldBL (-not(Test-Path -LiteralPath $receipt) -and -not(Test-Path -LiteralPath $evidence)) 'MODE_ALREADY_EXECUTED_NO_OVERWRITE'
 if($Mode -eq 'Delete'){
  HoldBL ($ConfirmPhrase -ceq 'DELETE_TWO_FAILED_STAGES') 'EXACT_OPERATOR_CONFIRMATION_REQUIRED'
  & fltmc.exe *> $null
  HoldBL ($LASTEXITCODE -eq 0) 'ADMIN_REQUIRED'
 }
 HoldBL (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'DISM_IMAGE_MOUNT_EXISTS'
 HoldBL (@(Get-Process -Name 'dism','dismhost','aria2c','NTLite','wimlib-imagex' -ErrorAction SilentlyContinue).Count -eq 0) 'ACTIVE_DISM_DOWNLOAD_OR_NTLITE_PROCESS'
 foreach($hiveAlias in @('Registry::HKEY_LOCAL_MACHINE\BlueLiteSOFTWARE','Registry::HKEY_LOCAL_MACHINE\BlueLiteSYSTEM')) {
  HoldBL (-not(Test-Path -LiteralPath $hiveAlias -ErrorAction Stop)) ('PROJECT_HIVE_STILL_LOADED_'+$hiveAlias)
 }
 HoldBL (Test-Path $proof -PathType Leaf) 'TRIPLE_SHA_RECEIPT_MISSING'
 HoldBL ((HashBL $proof) -eq $expectedProofSHA) 'TRIPLE_SHA_RECEIPT_TAMPER'
 $proofRows=@(Import-Csv -LiteralPath $proof)
 HoldBL ($proofRows.Count -eq 184) 'SOURCE_184_PROOF_REQUIRED'
 HoldBL ((Get-Item -LiteralPath $goldenWim).Length -eq 5736092221L -and (HashBL $goldenWim) -eq '3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4') 'GOLDEN_INSTALL_WIM_NOT_PROVEN'
 HoldBL ((Get-Item -LiteralPath $iso).Length -eq 6822354944L -and (HashBL $iso) -eq '570BD12E9DBBBB51CACFB3B9A403326AA5000FAC1D2F7E44482EFCC154CB3736') 'GOLDEN_ISO_NOT_PROVEN'
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $sourceBytes=0L
 foreach($r in $proofRows) {
  $rel=[string]$r.RelativePath
  HoldBL ($rel -match '^[A-Za-z0-9_.\\-]+$' -and -not $rel.Contains('..') -and $seen.Add($rel)) ('INVALID_SOURCE_MEMBER_'+$rel)
  $gold=Join-Path $srcOriginal $rel
  $old=Join-Path (Join-Path $stageR027 'UUPs') $rel
  $new=Join-Path (Join-Path $stageR028 'UUPs') $rel
  HoldBL ($gold -ieq [string]$r.Golden -and $old -ieq [string]$r.R027 -and $new -ieq [string]$r.R028) ('SOURCE_PATH_MISMATCH_'+$rel)
  foreach($p in @($gold,$old,$new)){
   HoldBL (Test-Path -LiteralPath $p -PathType Leaf) ('SOURCE_FILE_MISSING_'+$p)
   HoldBL ((Get-Item -LiteralPath $p).Length -eq [long]$r.Bytes) ('SOURCE_SIZE_DRIFT_'+$p)
   HoldBL ((HashBL $p) -eq [string]$r.SHA256) ('SOURCE_SHA_DRIFT_'+$p)
  }
  $sourceBytes+=[long]$r.Bytes
 }
 HoldBL ($sourceBytes -eq 9184770517L) 'PROTECTED_SOURCE_BYTES_MISMATCH'
 $stageSnapshots=@()
 foreach($t in $stages) {
  $stageSnapshots+=FolderBL $t.path $t.bytes $t.count
  $meta=Join-Path $t.path 'BlueLite_Logs\ResolvedUUP.json'
  HoldBL (Test-Path -LiteralPath $meta -PathType Leaf) ('SOURCE_IDENTITY_MISSING_'+$t.tag)
  $ident=Get-Content -LiteralPath $meta -Raw -Encoding UTF8|ConvertFrom-Json
  HoldBL ([string]$ident.UUP_ID -eq '6c7bf258-2632-47dd-83ee-c23945978da1') ('SOURCE_UUID_MISMATCH_'+$t.tag)
  HoldBL (Test-Path -LiteralPath (Join-Path $t.path 'BlueLite_Logs\ConvertStart.marker') -PathType Leaf) ('NO_FAILED_CONVERTER_MARKER_'+$t.tag)
  HoldBL (-not(@(Get-ChildItem -LiteralPath $t.path -File -Filter '*.ISO' -ErrorAction Stop).Count)) ('FINISHED_ISO_PRESENT_'+$t.tag)
  $debloat=Join-Path $t.path 'BlueLite_Logs\FinalWimDebloat.log'
  HoldBL (Test-Path -LiteralPath $debloat -PathType Leaf) ('DEBLOAT_LOG_MISSING_'+$t.tag)
  $failureText=[IO.File]::ReadAllText($debloat)
  if($t.tag -eq 'R028_FAILED'){HoldBL ($failureText -match '0x8007007A') 'R028_FAILURE_NOT_EXACT'}
  else {HoldBL ($failureText -match 'Compact export identity gate failed') 'R027_FAILURE_NOT_EXACT'}
 }
 $state='SOURCE_AND_FAILED_STAGE_VERIFIED'
 Write-Host 'BL_CLEANUP_184X3_SHA_PASS'
 $archived=[Collections.Generic.List[object]]::new()
 foreach($t in $stages) {
  $stage=$t.path
  $capture=[Collections.Generic.List[object]]::new()
  foreach($sub in @('BlueLite_Logs','BlueLite')){
    $dir=Join-Path $stage $sub
    HoldBL (Test-Path -LiteralPath $dir -PathType Container) ('EVIDENCE_DIR_MISSING_'+$t.tag+'_'+$sub)
    foreach($f in Get-ChildItem -LiteralPath $dir -File -Force -Recurse){$capture.Add($f)}
  }
  foreach($f in Get-ChildItem -LiteralPath $stage -File -Force){$capture.Add($f)}
  foreach($f in $capture) {
   HoldBL ($f.Length -le 64MB) ('EVIDENCE_MEMBER_TOO_LARGE_'+$f.FullName)
   $rel=$f.FullName.Substring($stage.Length+1).Replace('\','/')
   HoldBL ($rel -notmatch '(^/|\.\.|:)' -and $rel -notmatch '^UUPs/' -and $rel -notmatch '^ISOFOLDER/') 'EVIDENCE_UNSAFE_PATH'
   $archived.Add([pscustomobject]@{Tag=$t.tag;File=$f.FullName;ArchiveName=$t.tag+'/'+$rel;Bytes=[long]$f.Length;SHA256=(HashBL $f.FullName)})
  }
 }
 HoldBL ($archived.Count -ge 35 -and $archived.Count -le 300) ('EVIDENCE_COUNT_'+$archived.Count)
 $combined=($archived|Measure-Object -Property Bytes -Sum).Sum
 HoldBL ($combined -lt 200MB) 'EVIDENCE_TOTAL_TOO_LARGE'
 $z=[IO.Compression.ZipFile]::Open($evidence,[IO.Compression.ZipArchiveMode]::Create)
 try{foreach($f in $archived){[void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z,$f.File,$f.ArchiveName,[IO.Compression.CompressionLevel]::Optimal)}}finally{$z.Dispose()}
 $za=[IO.Compression.ZipFile]::OpenRead($evidence)
 try{
  HoldBL ($za.Entries.Count -eq $archived.Count) 'EVIDENCE_ZIP_COUNT'
  $dict=@{};foreach($f in $archived){$dict[$f.ArchiveName]=$f.SHA256}
  foreach($entry in $za.Entries){HoldBL $dict.ContainsKey($entry.FullName) ('UNKNOWN_ZIP_ENTRY_'+$entry.FullName);$stream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create();try{$v=[Convert]::ToHexString($sha.ComputeHash($stream))}finally{$stream.Dispose();$sha.Dispose()};HoldBL ($v -eq $dict[$entry.FullName]) ('ARCHIVE_ENTRY_SHA_'+$entry.FullName)}
 }finally{$za.Dispose()}
 $zipSHA=HashBL $evidence
 $state='PREDELETE_EVIDENCE_ARCHIVED_AND_INDEPENDENTLY_SHA_VERIFIED'
 $drive=[IO.DriveInfo]::new('C:')
 $freeBefore=$drive.AvailableFreeSpace
 if($Mode -eq 'Audit') {
  WriteJsonBL $receipt ([ordered]@{schema='BlueLite.Cleanup.v1';utc=[DateTime]::UtcNow.ToString('o');mode=$Mode;status='AUDIT_PASS_NO_DELETE';source_sha_manifest=$expectedProofSHA;source_count=184;source_bytes_each=$sourceBytes;stages=$stageSnapshots;logical_candidate_bytes=44335531989L;evidence_zip=$evidence;evidence_zip_sha256=$zipSHA;archived_entries=$archived.Count;no_deletions=$true;freeCBytes=$freeBefore;one_next='OPERATOR_RUN_EXPLICIT_DELETE_COMMAND'})
  Write-Host ('BL_CLEANUP_AUDIT_PASS_NO_DELETE '+$receipt)
  Write-Host ('BL_CLEANUP_AUDIT_EVIDENCE '+$evidence)
  exit 0
 }
 WriteJsonBL $started ([ordered]@{status='DELETE_STARTED';utc=[DateTime]::UtcNow.ToString('o');exact_targets=@($stages|ForEach-Object {$_.path});evidence_zip_sha256=$zipSHA;original_v4_protected=$true})
 $state='DELETE_STARTED'
 foreach($t in $stages) {
  HoldBL (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'MOUNT_APPEARED_BEFORE_DELETE'
  HoldBL (@(Get-Process -Name 'dism','dismhost','aria2c','NTLite','wimlib-imagex' -ErrorAction SilentlyContinue).Count -eq 0) 'PROCESS_APPEARED_BEFORE_DELETE'
  [IO.Directory]::Delete($t.path,$true)
  HoldBL (-not(Test-Path -LiteralPath $t.path)) ('DELETE_NOT_COMPLETE_'+$t.tag)
  $removed+=([ordered]@{tag=$t.tag;path=$t.path;logicalBytes=$t.bytes;status='DELETE_COMPLETE';freeCBytes=([IO.DriveInfo]::new('C:')).AvailableFreeSpace})
  WriteJsonBL (Join-Path $logs ('BlueLite_Cleanup_20261107_'+$t.tag+'_DELETE_PASS.json')) $removed[-1]
  Write-Host ('BL_CLEANUP_DELETE_PASS '+$t.tag+' '+$t.path)
 }
 HoldBL ((Test-Path -LiteralPath $goldenWim -PathType Leaf) -and (Test-Path -LiteralPath $iso -PathType Leaf)) 'GOLDEN_LOST_AFTER_DELETE'
 HoldBL ((Get-ChildItem -LiteralPath $srcOriginal -File -Force -Recurse).Count -eq 184) 'GOLDEN_SOURCE_COUNT_AFTER_DELETE'
 $freeAfter=([IO.DriveInfo]::new('C:')).AvailableFreeSpace
 $state='DELETE_PASS'
 WriteJsonBL $receipt ([ordered]@{schema='BlueLite.Cleanup.v1';utc=[DateTime]::UtcNow.ToString('o');mode=$Mode;status=$state;exact_deleted=$removed;logical_candidate_bytes=44335531989L;actualCFreeBeforeBytes=$freeBefore;actualCFreeAfterBytes=$freeAfter;actualCFreeIncreaseBytes=($freeAfter-$freeBefore);evidence_zip=$evidence;evidence_zip_sha256=$zipSHA;original_golden_preserved=$true;source_proof_sha256=$expectedProofSHA;one_next='RETURN_DELETE_RESULT_AND_EVIDENCE_THEN_STOP'})
 Write-Host ('BL_CLEANUP_DELETE_PASS '+$receipt)
 Write-Host ('BL_CLEANUP_DELETE_EVIDENCE '+$evidence)
 exit 0
}catch{
 $reason=$_.Exception.Message
 Write-Host ('BL_CLEANUP_HOLD '+$reason+' AT '+$state)
 try{if(-not(Test-Path -LiteralPath $receipt)){WriteJsonBL $receipt ([ordered]@{schema='BlueLite.Cleanup.v1';utc=[DateTime]::UtcNow.ToString('o');status='HOLD';mode=$Mode;phase=$state;reason=$reason;partial_deletions=$removed;one_next='DO_NOT_RETRY_RETURN_RECEIPT_AND_EXISTING_EVIDENCE'})}}catch{}
 Write-Host ('BL_CLEANUP_RESULT '+$receipt)
 Write-Host ('BL_CLEANUP_EVIDENCE '+$evidence)
 exit 17
}
