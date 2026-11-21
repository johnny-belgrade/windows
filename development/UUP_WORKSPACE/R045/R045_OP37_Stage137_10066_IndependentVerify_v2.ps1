# BlueLite R045 OP37 ATTEMPT2 independently validate v2 original signed137 UUP source/stage with fresh PS7 full SHA1/SHA256.
[CmdletBinding()]param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$root='C:\work\_UUP'
$owner=Join-Path $root 'R045_OP37_Stage137_10066_20261121'
$manifestPath=Join-Path $root 'temp\R043_OP211_WimOnlyManifest_20261117\R043_OP211_ProposedSource137Stage.json'
$stageProducer='C:\work\logs\R045_OP37_Stage137_Producer_v2.json'
$producerMirror=Join-Path $owner 'BlueLite_Logs\R045_OP37_Stage137_Producer_v2.json'
$receipts='C:\work\logs\R045_OP37_Stage137_SourceReceipts_v2'
$report='C:\work\logs\R045_OP37_Stage137_IndependentQA_v2.json'
$mirror=Join-Path $owner 'BlueLite_Logs\R045_OP37_Stage137_IndependentQA_v2.json'
$authZip=Join-Path $root '_UUP_Originals\26300.10066_amd64_en-us_professional_0344497f_convert.zip'
$record=[ordered]@{op='R045_OP37';utc=[DateTime]::UtcNow.ToString('o');status='PENDING';stageRoot=$owner;sourceManifestSHA='';stageProducerSHA='';zipSHA='';unpatchedConverterSHA='';ownerConfigSHA='';ownerAppsSHA='';verifiedSources=0;verifiedStageFiles=0;windowsCount=0;appsCount=0;bytesVerified=[long]0;bytesExpected=[long]9119622618;producerReceiptCount=0;unmatchedStageFiles=0;protectedApps=@();CFreeB=[long]0;VMoff=-1;WIMmounts=-1;imageCreated=$false;sourceMutation=$false;error=''}
function AssertSHA([string]$path,[string]$sha,[string]$name){
 $f=[IO.FileInfo]::new($path)
 if(-not $f.Exists -or ($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('MISSING_OR_REPARSE_'+$name)}
 $h=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
 if($h -ne $sha){throw ('PHYSICAL_SHA256_CHANGED_'+$name)}
 return $h
}
try{
 if([IO.File]::Exists($report) -or [IO.File]::Exists($mirror)){throw 'IMMUTABLE_QA_EXISTS'}
 if(-not [IO.Directory]::Exists($owner) -or -not [IO.Directory]::Exists($receipts)){throw 'STAGED_OWNER_OR_RECEIPTS_MISSING'}
 $record.sourceManifestSHA=AssertSHA $manifestPath 'FA831096050A74AF5DF58B8C61DDF19BFD8487D34FACD75551F440FBB425DD75' 'SOURCE_MANIFEST'
 $record.zipSHA=AssertSHA $authZip '8FE361765967DA0651078C324B21E6C6D7595081DBACBB26049EC53AB59DE404' 'SIGNED_VENDOR_ZIP'
 $record.stageProducerSHA=(Get-FileHash -LiteralPath $stageProducer -Algorithm SHA256).Hash
 if((Get-FileHash -LiteralPath $producerMirror -Algorithm SHA256).Hash -ne $record.stageProducerSHA){throw 'PRODUCER_MIRROR_SHA_CHANGED'}
 $producer=Get-Content -LiteralPath $stageProducer -Raw|ConvertFrom-Json
 $manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
 if($producer.status -ne 'OWNED_10066_STAGE137_FULL_SOURCE_SHA1_SHA256_COPIES_PASS_PENDING_INDEPENDENT_QA' -or [int]$producer.copiedCount -ne 137 -or [long]$producer.copiedB -ne $record.bytesExpected -or @($producer.rows).Count -ne 137){throw 'PRODUCER_NOT_NATIVE_STAGE_PASS'}
 if($producer.stageRoot -ne $owner -or $manifest.targetRoot -ne 'C:\work\_UUP\temp\R043_OP213_10066_WimOnly_20261117' -or @($manifest.sourceFiles).Count -ne 137){throw 'STAGE_OR_MANIFEST_IDENTITY_HOLD'}
 $record.unpatchedConverterSHA=AssertSHA (Join-Path $owner 'convert-UUP.cmd') 'DA557A5EF7541C2E472B09FB171F6A9C823A25CA6A73212541A348ECDCE36A6B' 'UNPATCHED_CONVERTER'
 $cfg=Join-Path $owner 'ConvertConfig.ini'
 $apps=Join-Path $owner 'CustomAppsList.txt'
 $record.ownerConfigSHA=(Get-FileHash -LiteralPath $cfg -Algorithm SHA256).Hash
 $record.ownerAppsSHA=(Get-FileHash -LiteralPath $apps -Algorithm SHA256).Hash
 $cfgText=[IO.File]::ReadAllText($cfg)
 foreach($rule in @('AutoStart\s*=\s*3','SkipWinRE\s*=\s*1','CustomList\s*=\s*1','StubAppsFull\s*=\s*1','AutoExit\s*=\s*1')){
  if([regex]::Matches($cfgText,'(?m)^\s*'+$rule+'\s*$').Count -ne 1){throw ('OWNER_CONFIG_MISSING_'+$rule)}
 }
 $appsText=[IO.File]::ReadAllText($apps)
 foreach($keep in @('Microsoft.Windows.Photos_8wekyb3d8bbwe','Microsoft.WindowsNotepad_8wekyb3d8bbwe','Microsoft.WindowsCalculator_8wekyb3d8bbwe','Microsoft.WindowsStore_8wekyb3d8bbwe','Microsoft.StorePurchaseApp_8wekyb3d8bbwe','Microsoft.SecHealthUI_8wekyb3d8bbwe','Microsoft.DesktopAppInstaller_8wekyb3d8bbwe')){
  $regex='(?m)^\s*'+[regex]::Escape($keep)+'\s*$'
  if([regex]::Matches($appsText,$regex).Count -ne 1){throw ('REQUIRED_KEEP_NOT_ACTIVE_'+$keep)}
  $record.protectedApps+=,$keep
 }
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 $i=0
 foreach($item in $manifest.sourceFiles){
  $i++
  $rel=[string]$item.stagingRelative
  $orig=[string]$item.sourcePath
  $dest=Join-Path $owner $rel
  if(-not $seen.Add($rel) -or $rel -match '(^[\\/]|(^|[\\/])\.\.([\\/]|$))'){throw 'SOURCE_TARGET_PATH_COLLISION_OR_TRAVERSAL'}
  $receipt=Join-Path $receipts (('{0:D3}.json' -f $i))
  if(-not [IO.File]::Exists($receipt)){throw ('MISSING_NATIVE_FILE_RECEIPT_'+$i)}
  $data=Get-Content -LiteralPath $receipt -Raw|ConvertFrom-Json
  $srcFi=[IO.FileInfo]::new($orig)
  $stgFi=[IO.FileInfo]::new($dest)
  if(-not $srcFi.Exists -or -not $stgFi.Exists -or ($srcFi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 -or ($stgFi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('SOURCE_OR_STAGED_FILE_MISSING_'+$rel)}
  if($srcFi.Length -ne [long]$item.bytes -or $stgFi.Length -ne [long]$item.bytes -or $data.bytes -ne [long]$item.bytes -or $data.stage -ne $dest -or $data.relative -ne $rel -or $data.source -ne $orig){throw ('FILE_AND_RECEIPT_BYTES_OR_PATH_MISMATCH_'+$rel)}
  $origSHA=(Get-FileHash -LiteralPath $orig -Algorithm SHA1).Hash
  $stageSHA1=(Get-FileHash -LiteralPath $dest -Algorithm SHA1).Hash
  $stageSHA256=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
  if($origSHA -ne [string]$item.sourceSHA1 -or $stageSHA1 -ne $origSHA -or $data.sourceSHA1 -ne $origSHA -or $stageSHA256 -ne $data.physicalCopySHA256){throw ('INDEPENDENT_FULL_SOURCE_OR_STAGE_HASH_MISMATCH_'+$rel)}
  $record.verifiedSources++
  $record.verifiedStageFiles++
  $record.bytesVerified+=[long]$stgFi.Length
  if([string]$item.role -like 'Windows*'){$record.windowsCount++}else{$record.appsCount++}
  $record.producerReceiptCount++
  if(($i%20) -eq 0){Write-Output ('OP37_INDEPENDENT_QA_PROGRESS='+$i+'/137')}
 }
 $extra=@(Get-ChildItem -LiteralPath (Join-Path $owner 'UUPs') -File -Recurse -Force)
 $record.unmatchedStageFiles=$extra.Count-$seen.Count
 if($record.verifiedSources -ne 137 -or $record.verifiedStageFiles -ne 137 -or $record.producerReceiptCount -ne 137 -or $record.windowsCount -ne 98 -or $record.appsCount -ne 39 -or $record.bytesVerified -ne $record.bytesExpected -or $record.unmatchedStageFiles -ne 0){throw 'STAGED_SOURCE137_RECONCILIATION_HOLD'}
 $record.CFreeB=[long](Get-PSDrive C).Free
 if($record.CFreeB -lt ([long]64424509440+[long]7384383716+[long]6442450944)){throw 'WIM_FIRST_FREE_RESERVE_HOLD'}
 $record.VMoff=@(Get-VM|Where-Object {$_.State -eq 'Off'}).Count
 $record.WIMmounts=@(Get-WindowsImage -Mounted).Count
 if($record.VMoff -ne 3 -or $record.WIMmounts -ne 0){throw 'HOST_WIM_OR_VM_BUSY'}
 if([IO.File]::Exists((Join-Path $owner 'install.wim'))){throw 'STAGE_UNEXPECTED_INSTALL_WIM'}
 $record.status='INDEPENDENT_NATIVE_STAGE137_ORIGINAL_SHA1_STAGED_SHA1_SHA256_KEEP7_PASS'
}catch{$record.status='INDEPENDENT_NATIVE_STAGE137_QA_HOLD';$record.error=[string]$_.Exception.Message}
$b=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 12))
foreach($target in @($report,$mirror)){
 $f=[IO.File]::Open($target,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
Write-Output ('OP37_INDEPENDENT_QA='+$record.status+' SOURCES='+$record.verifiedSources+' STAGED_BYTES='+$record.bytesVerified+' ERROR='+$record.error)
Write-Output ('OP37_INDEPENDENT_QA_SHA256='+(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash)
if($record.status -ne 'INDEPENDENT_NATIVE_STAGE137_ORIGINAL_SHA1_STAGED_SHA1_SHA256_KEEP7_PASS'){exit 17}
