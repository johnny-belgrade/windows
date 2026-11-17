# R043 OP213 source-only: reviewed owned original-source copy, NOT YET AUTHORIZED TO EXECUTE, pristine v128m converter, three KEEP overlays.
[CmdletBinding()]param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$base='C:\work\_UUP'
$stage=Join-Path $base 'temp\R043_OP215_10066_WimOnly_20261117'
$source=Join-Path $base 'temp\R043_OP211_WimOnlyManifest_20261117\R043_OP211_ProposedSource137Stage.json'
$oldQA='C:\work\logs\R043_OP211_WimOnlyManifest_IndependentVerify.json'
$r042=Join-Path $base 'R042_FULL_ONECMD_9974_20261111\BlueLite_Work\BlueLite_Stage_v11_3_26300_9974_aa272a56_bd6402ad'
$zip=Join-Path $base '_UUP_Originals\26300.10066_amd64_en-us_professional_0344497f_convert.zip'
$archive=Join-Path $r042 'files\uup-converter-wimlib.7z'
$extractor=Join-Path $r042 'files\7zr.exe'
$report='C:\work\logs\R043_OP215_Stage137_Producer_v1.json'
$mirror=Join-Path $base 'R043_PREMAX_P1_20261112\BlueLite_Logs\R043_OP215_WimOnlyStage_Producer_v3.json'
$minFloor=[long]64424509440
$nextWim=[long]7384383716
$scratch=[long]6442450944
$utf8=[Text.UTF8Encoding]::new($false)
$r=[ordered]@{op='R043_OP215';gitPreBlob='b7a66a96d2819cc8aa040601cfd1bffe4788f2d6';utcStart=[DateTime]::UtcNow.ToString('o');status='PENDING';stageRoot=$stage;manifestSHA='';priorQASHA='';zipSHA='';originalConverterArchiveSHA='';unpatchedConverterSHA='';originalConfigSHA='';originalAppsListSHA='';ownedConfigSHA='';ownedAppsListSHA='';bootstrapSHA='';copiedCount=0;copiedB=[long]0;expectedB=[long]9119622618;rows=@();freeCBeforeB=[long]0;freeCAfterB=[long]0;minimumCFreeB=[long]0;VMoff=-1;WIMmounts=-1;originalSourceFilesModified=0;newWimBuilt=$false;error='';utcEnd=''}
function WriteNew([string]$path,[byte[]]$b){
 $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length);$f.Flush($true)}finally{$f.Dispose()}
}
function FloorGuard([long]$remainingB){
 $available=[long](Get-PSDrive C).Free
 if($r.minimumCFreeB -eq 0 -or $available -lt $r.minimumCFreeB){$r.minimumCFreeB=$available}
 if($available -lt ($minFloor+$nextWim+$scratch+$remainingB)){throw ('FUTURE_WIM_SCRATCH_FREE_FLOOR_HOLD_AFTER_'+$r.copiedCount)}
}
function OwnerConfig([string]$text){
 $rules=[ordered]@{AutoStart=@('1','3');SkipWinRE=@('0','1');CustomList=@('0','1');StubAppsFull=@('0','1');AutoExit=@('0','1')}
 foreach($name in $rules.Keys){
  $old=$rules[$name][0];$new=$rules[$name][1];$regex='(?m)^('+[regex]::Escape($name)+'\s*=\s*)'+$old+'\s*$'
  if([regex]::Matches($text,$regex).Count -ne 1){throw ('CONFIG_EXPECTED_ANCHOR_NOT_ONE_'+$name)}
  $text=[regex]::Replace($text,$regex,'${1}'+$new)
 }
 return $text
}
try{
 if([IO.Directory]::Exists($stage) -or [IO.File]::Exists($report) -or [IO.File]::Exists($mirror)){throw 'IMMUTABLE_OUTPUT_EXISTS'}
 Write-Output 'OP213_STEP_MANIFEST_SHA'
 $r.manifestSHA=(Get-FileHash $source -Algorithm SHA256).Hash
 Write-Output 'OP213_STEP_QA_SHA'
 $r.priorQASHA=(Get-FileHash $oldQA -Algorithm SHA256).Hash
 Write-Output 'OP213_STEP_ZIP_SHA'
 $r.zipSHA=(Get-FileHash $zip -Algorithm SHA256).Hash
 Write-Output 'OP213_STEP_CONVERTER_ARCHIVE_SHA'
 $r.originalConverterArchiveSHA=(Get-FileHash $archive -Algorithm SHA256).Hash
 if($r.manifestSHA -ne 'FA831096050A74AF5DF58B8C61DDF19BFD8487D34FACD75551F440FBB425DD75' -or $r.priorQASHA -ne 'FAD5F3E7D5A916D0DF1E90C36D63A5FE1DF0F980C42CCABC42CE34C4DFF438B0' -or $r.zipSHA -ne '8FE361765967DA0651078C324B21E6C6D7595081DBACBB26049EC53AB59DE404' -or $r.originalConverterArchiveSHA -ne '1597F39D614529843DCADF630ED6DD4543C955EA703B6B0D1FDBE65AA078A5F1'){throw 'IMMUTABLE_SOURCE_SHA_CHANGED'}
 if((Get-FileHash $extractor -Algorithm SHA256).Hash -ne '72C98287B2E8F85EA7BB87834B6CE1CE7CE7F41A8C97A81B307D4D4BF900922B'){throw 'EXTRACTOR_SHA_CHANGED'}
 $m=Get-Content -LiteralPath $source -Raw|ConvertFrom-Json
 if(@($m.sourceFiles).Count -ne 137 -or $m.stageBytes -ne $r.expectedB -or $m.targetRoot -ne 'C:\work\_UUP\temp\R043_OP213_10066_WimOnly_20261117'){throw 'STAGING_MANIFEST_IDENTITY_HOLD'}
 $r.freeCBeforeB=[long](Get-PSDrive C).Free
 Write-Output 'OP213_STEP_STAGE_FLOOR_GUARD'
 FloorGuard $r.expectedB
 Write-Output 'OP213_STEP_VM_STATE'
 $r.VMoff=@(Get-VM|Where-Object {$_.State -eq 'Off'}).Count
 Write-Output 'OP213_STEP_WIM_MOUNT'
 $r.WIMmounts=@(Get-WindowsImage -Mounted).Count
 if($r.VMoff -ne 3 -or $r.WIMmounts -ne 0 -or @(Get-Process -Name 'dism','dismhost','wimlib-imagex','aria2c' -ErrorAction SilentlyContinue).Count -gt 0){throw 'HOST_ACTIVE_BUILD_HOLD'}
 Write-Output 'OP213_STEP_STAGE_CREATE'
 [IO.Directory]::CreateDirectory($stage)|Out-Null
 $ownLog=Join-Path $stage 'BlueLite_Logs'
 [IO.Directory]::CreateDirectory($ownLog)|Out-Null
 $boot=[ordered]@{op='R043_OP215';utc=[DateTime]::UtcNow.ToString('o');mode='OWNED_STAGE137_SOURCE_COPY_ONLY';gitPre=$r.gitPreBlob;manifestSHA=$r.manifestSHA;originalProtectedNeverModified=$true;converterExecution='NOT_RUN'}
 $bootBytes=$utf8.GetBytes(($boot|ConvertTo-Json -Depth 10))
 WriteNew (Join-Path $ownLog 'R043_OP215_BOOTSTRAP.json') $bootBytes
 $r.bootstrapSHA=(Get-FileHash -LiteralPath (Join-Path $ownLog 'R043_OP215_BOOTSTRAP.json') -Algorithm SHA256).Hash
 Write-Output ('OP213_BOOTSTRAP_SHA='+$r.bootstrapSHA)
 # Extract authenticated V128m vendor converter in NEW owned directory only.
 Write-Output 'OP213_STEP_EXTRACT_CONVERTER'
 $process=& $extractor x "-o$stage" -y $archive 2>&1
 if($LASTEXITCODE -ne 0){throw ('ORIGINAL_CONVERTER_EXTRACT_EXIT_'+$LASTEXITCODE)}
 $cleanCmd=Join-Path $stage 'convert-UUP.cmd'
 Write-Output 'OP213_STEP_CONVERTER_SHA'
 $r.unpatchedConverterSHA=(Get-FileHash -LiteralPath $cleanCmd -Algorithm SHA256).Hash
 if($r.unpatchedConverterSHA -ne 'DA557A5EF7541C2E472B09FB171F6A9C823A25CA6A73212541A348ECDCE36A6B'){throw 'EXTRACTED_CONVERTER_NOT_PRISTINE'}
 # Original .10066 ZIP source is read-only. Preserve its configuration in OWN logs before owner-only patches.
 Write-Output 'OP213_STEP_OPEN_ZIP'
 Add-Type -AssemblyName System.IO.Compression
 $fzip=[IO.File]::OpenRead($zip)
 $z=[IO.Compression.ZipArchive]::new($fzip,[IO.Compression.ZipArchiveMode]::Read,$false)
 try{
  if($z.Entries.Count -ne 11){throw 'ZIP_11_MEMBER_CONTRACT_CHANGED'}
  $allPaths=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $origCfg='';$origApps=''
  foreach($e in $z.Entries){
   $name=[string]$e.FullName
   if($name -match '(^[\\/]|(^|/)\.\.(/|$)|\\)' -or $e.Length -gt 262144 -or -not $allPaths.Add($name)){throw 'ORIGINAL_ZIP_MEMBER_UNSAFE_OR_AMBIGUOUS'}
   $input=$e.Open();$mem=[IO.MemoryStream]::new()
   try{$input.CopyTo($mem);$b=$mem.ToArray()}finally{$input.Dispose();$mem.Dispose()}
   if($b.Length -ne $e.Length){throw 'VENDOR_SOURCE_ZIP_MEMBER_SIZE_CHANGED'}
   if($name -eq 'ConvertConfig.ini'){
    $origCfg=$utf8.GetString($b)
    WriteNew (Join-Path $ownLog 'ConvertConfig.original10066.ini') $b
    $r.originalConfigSHA=(Get-FileHash -LiteralPath (Join-Path $ownLog 'ConvertConfig.original10066.ini') -Algorithm SHA256).Hash
   }elseif($name -eq 'CustomAppsList.txt'){
    $origApps=$utf8.GetString($b)
    WriteNew (Join-Path $ownLog 'CustomAppsList.original10066.txt') $b
    $r.originalAppsListSHA=(Get-FileHash -LiteralPath (Join-Path $ownLog 'CustomAppsList.original10066.txt') -Algorithm SHA256).Hash
   }else{
    $dst=Join-Path $stage ($name.Replace('/',[IO.Path]::DirectorySeparatorChar))
    $parent=[IO.Path]::GetDirectoryName($dst)
    if(-not [IO.Directory]::Exists($parent)){[IO.Directory]::CreateDirectory($parent)|Out-Null}
    WriteNew $dst $b
   }
  }
  if($origCfg.Length -lt 200 -or $origApps.Length -lt 500){throw 'ORIGINAL_ZIP_CONFIG_OR_APPS_MISSING'}
  $newCfg=OwnerConfig $origCfg
  $newApps=$origApps
  foreach($keep in @('Microsoft.Windows.Photos_8wekyb3d8bbwe','Microsoft.WindowsNotepad_8wekyb3d8bbwe','Microsoft.WindowsCalculator_8wekyb3d8bbwe')){
   $regex='(?m)^\s*#\s*'+[regex]::Escape($keep)+'\s*$'
   if([regex]::Matches($newApps,$regex).Count -ne 1){throw ('EXPECTED_VENDOR_KEEP_COMMENT_MISSING_'+$keep)}
   $newApps=[regex]::Replace($newApps,$regex,$keep)
  }
  if($r.originalAppsListSHA -ne '1F2FBC910A0F016EAD61D1FEEF41D1E7B75E234753572AE37C83D0DAE955CC94'){throw 'VENDOR_KEEP_LIST_SHA_MISMATCH'}
  [IO.File]::WriteAllText((Join-Path $stage 'ConvertConfig.ini'),$newCfg,$utf8)
  [IO.File]::WriteAllText((Join-Path $stage 'CustomAppsList.txt'),$newApps,$utf8)
  $r.ownedConfigSHA=(Get-FileHash -LiteralPath (Join-Path $stage 'ConvertConfig.ini') -Algorithm SHA256).Hash
  $r.ownedAppsListSHA=(Get-FileHash -LiteralPath (Join-Path $stage 'CustomAppsList.txt') -Algorithm SHA256).Hash
 }finally{$z.Dispose();$fzip.Dispose()}
 Write-Output ('OP213_OVERLAYS_READY='+$r.ownedConfigSHA+' KEEP3='+$r.ownedAppsListSHA)
 # FileMode.CreateNew only and NO hardlinks. Signed original source stream SHA1+SHA256 per file.
 $receiptRoot='C:\work\logs\R043_OP215_Stage137_SourceReceipts_v1'
 if([IO.Directory]::Exists($receiptRoot)){throw 'IMMUTABLE_SOURCE_RECEIPTS_ALREADY_EXIST'}
 [IO.Directory]::CreateDirectory($receiptRoot)|Out-Null
 $buf=[byte[]]::new(4194304)
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 Write-Output 'OP213_STEP_COPY_SOURCE_START'
 foreach($entry in $m.sourceFiles){
  $src=[string]$entry.sourcePath
  $rel=[string]$entry.stagingRelative
  if(-not $seen.Add($rel) -or $rel -match '(^[\\/]|(^|[\\/])\.\.([\\/]|$))'){throw 'STAGE_DESTINATION_COLLISION_OR_TRAVERSAL'}
  $sourceFile=[IO.FileInfo]::new($src)
  if(-not $sourceFile.Exists -or $sourceFile.Length -ne [long]$entry.bytes -or ($sourceFile.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('ORIGINAL_SOURCE_BYTES_CHANGED_'+$rel)}
  $dest=Join-Path $stage $rel
  $parent=[IO.Path]::GetDirectoryName($dest)
  if(-not [IO.Directory]::Exists($parent)){[IO.Directory]::CreateDirectory($parent)|Out-Null}
  FloorGuard ([long]$r.expectedB-[long]$r.copiedB)
  $input=[IO.File]::Open($src,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
  $output=[IO.File]::Open($dest,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
  $h1=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA1)
  $h256=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
  $length=[long]0
  try{
   while(($size=$input.Read($buf,0,$buf.Length)) -gt 0){
    $h1.AppendData($buf,0,$size);$h256.AppendData($buf,0,$size)
    $output.Write($buf,0,$size)
    $length+=$size
    if($length -gt [long]$entry.bytes){throw 'SOURCE_CHANGED_DURING_COPY_SIZE'}
    if(($length % 67108864) -lt $size){FloorGuard ($r.expectedB-$r.copiedB-$length)}
   }
   $output.Flush($true)
   $sha1=[Convert]::ToHexString($h1.GetHashAndReset())
   $sha256=[Convert]::ToHexString($h256.GetHashAndReset())
  }finally{$h1.Dispose();$h256.Dispose();$output.Dispose();$input.Dispose()}
  if($sha1 -ne [string]$entry.sourceSHA1 -or $length -ne [long]$entry.bytes){throw ('ORIGINAL_SIGNED_SHA1_OR_LENGTH_MISMATCH_'+$rel)}
  $fileHash=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
  if($fileHash -ne $sha256){throw ('DESTINATION_SOURCE_COPY_SHA256_MISMATCH_'+$rel)}
  $record=[ordered]@{source=$src;relative=$rel;bytes=$length;sourceSHA1=$sha1;physicalCopySHA256=$sha256;stage=$dest}
  $recFile=Join-Path $receiptRoot (('{0:D3}.json' -f ($r.copiedCount+1)))
  WriteNew $recFile ($utf8.GetBytes(($record|ConvertTo-Json -Depth 8)))
  $r.rows+=,$record
  $r.copiedCount++
  $r.copiedB+=$length
  FloorGuard ($r.expectedB-$r.copiedB)
  if(($r.copiedCount % 16) -eq 0){Write-Output ('OP213_COPIED='+$r.copiedCount+'/137 BYTES='+$r.copiedB+' FREE='+[long](Get-PSDrive C).Free)}
 }
 if($r.copiedCount -ne 137 -or $r.copiedB -ne $r.expectedB){throw 'STAGE137_FINAL_COPY_COUNT_OR_SIZE'}
 if((Get-FileHash -LiteralPath $cleanCmd -Algorithm SHA256).Hash -ne $r.unpatchedConverterSHA){throw 'CLEAN_VENDOR_CONVERTER_CHANGED_AFTER_COPY'}
 if($r.VMoff -ne 3 -or @(Get-WindowsImage -Mounted).Count -ne 0){throw 'HOST_CHANGED_DURING_COPY'}
 $r.status='OWNED_10066_STAGE137_FULL_SOURCE_SHA1_SHA256_COPIES_PASS_PENDING_INDEPENDENT_QA'
}catch{$r.status='OWNED_STAGE_COPY_DEPENDENCY_HOLD';$r.error=[string]$_.Exception.Message}
$r.freeCAfterB=[long](Get-PSDrive C).Free
$r.utcEnd=[DateTime]::UtcNow.ToString('o')
$bytes=$utf8.GetBytes(($r|ConvertTo-Json -Depth 16))
foreach($dest in @($report,$mirror)){WriteNew $dest $bytes}
Write-Output ('OP213_STATUS='+$r.status+' COPIED='+$r.copiedCount+' BYTES='+$r.copiedB+' FREE='+$r.freeCAfterB+' ERROR='+$r.error)
Write-Output ('OP213_PRODUCER_SHA='+(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash)
if($r.status -ne 'OWNED_10066_STAGE137_FULL_SOURCE_SHA1_SHA256_COPIES_PASS_PENDING_INDEPENDENT_QA'){exit 17}
