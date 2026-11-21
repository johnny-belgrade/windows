# R051 OP03C operator-authorized, source-bound one-time actual 26300.10066 PRE_MAX full Build.
# Exact source, manifest, official Apps queue, original vendor and controller SHA must pass.
# No direct host OS debloat; stage and output only in the uniquely owned R051 Build root.
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$PSNativeCommandUseErrorActionPreference=$false
$base='C:\work\_UUP'
$work=Join-Path $base 'temp\R051_OP03_RealBuild_20261121\10066'
$history=Join-Path $base 'UUP-history\R051_PREMAX_20261121'
$source=Join-Path $base 'R051_PREMAX_Universal_26300x\BlueLite_PRE_MAX_26300x_R051_v1.zip'
$vendor=Join-Path $base '_UUP_Originals\26300.10066_amd64_en-us_professional_0344497f_convert.zip'
$manifest=Join-Path $base 'temp\R043_OP211_WimOnlyManifest_20261117\R043_OP211_ProposedSource137Stage.json'
$apps=Join-Path $base 'R045_OP43_10066_StoreContract_20261121\BlueLite_Logs\Apps_original_aria2_attempt01.txt'
$started=Join-Path $history 'R051_OP03C_Started.json'
$stdout=Join-Path $history 'R051_OP03C_RealBuild_stdout.log'
$stderr=Join-Path $history 'R051_OP03C_RealBuild_stderr.log'
$receipt=Join-Path $history 'R051_OP03C_RealBuildOutcome.json'
function Sha([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()}
function SaveNew([string]$path,[object]$data){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($data|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
 $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
foreach($p in @($started,$stdout,$stderr,$receipt)){if(Test-Path -LiteralPath $p){throw ('OWNED_NATIVE_RESULT_COLLISION '+$p)}}
if(-not [IO.Directory]::Exists($work)){throw 'FRESH_VERIFIED_STAGE_ABSENT'}
if((Sha $source) -cne '2BEF0E01CB25AC7A5792329B2A63BBC5D3A67C296F0B138761DD4677AC6C18DB'){throw 'R051_SOURCE_SHA_CHANGED'}
if((Sha $vendor) -cne '8FE361765967DA0651078C324B21E6C6D7595081DBACBB26049EC53AB59DE404'){throw 'ORIGINAL_SELECTED_VENDOR_CHANGED'}
if((Sha $manifest) -cne 'FA831096050A74AF5DF58B8C61DDF19BFD8487D34FACD75551F440FBB425DD75'){throw 'SOURCE137_MANIFEST_CHANGED'}
if((Sha $apps) -cne 'C5D0C34037059E4B4F56E25F0FCCF51003FB6236CD10A850B3EDE4FC1C352EE6'){throw 'ORIGINAL_OFFICIAL_APPS_CATALOG_CHANGED'}
if((Sha (Join-Path $work 'Engine\BlueLite_OP46_BuildController_v1.ps1')) -cne 'AC498F03BCBA305D73237F805E2F4236AFF3B4D1BF012DA7F246D22290304139'){throw 'STAGED_CONTROLLER_FIX_MISSING'}
if((Sha (Join-Path $work 'BlueLite_PRE_MAX_26300x_R051_v1.zip')) -cne (Sha $source)){throw 'STAGED_R051_ZIP_CHANGED'}
if((Sha (Join-Path $work '26300.10066_amd64_en-us_professional_0344497f_convert.zip')) -cne (Sha $vendor)){throw 'STAGED_VENDOR_CHANGED'}
SaveNew $started ([ordered]@{Schema='BlueLite.R051.OP03C.BuildStarted.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID;Root=$work;Mode='Build';SourceSHA256=(Sha $source);VendorSHA256=(Sha $vendor);CacheManifestSHA256=(Sha $manifest);AppsCatalogSHA256=(Sha $apps);OneNext='TRUE_NATIVE_CMD_EXIT_AND_INDEPENDENT_PHYSICAL_IMAGE_QA'})
$exitCode=996
$errorMessage=''
$begin=[DateTime]::UtcNow
Push-Location -LiteralPath $work
try{
 try{
  & (Join-Path $env:SystemRoot 'System32\cmd.exe') /d /c '.\PRE_MAX.cmd' --build $manifest $apps 1> $stdout 2> $stderr
  $exitCode=$LASTEXITCODE
 }catch{
  $errorMessage=$_.Exception.Message
  if($null -ne $LASTEXITCODE){$exitCode=[int]$LASTEXITCODE}
 }
}finally{Pop-Location}
$finish=[DateTime]::UtcNow
$logs=Join-Path $work 'BlueLite_Logs'
$ev=@(Get-ChildItem -LiteralPath $logs -File -Recurse -Filter 'PRE_MAX_Evidence_*.zip' -ErrorAction SilentlyContinue)
$report=@(Get-ChildItem -LiteralPath $logs -File -Recurse -Filter '*SourceBuildPlan_Report.json' -ErrorAction SilentlyContinue)
$rec=[ordered]@{
 Schema='BlueLite.R051.OP03C.NativeFullBuildOutcome.v1';UTC=$finish.ToString('o')
 OriginalSourceBuild='26300.10066';Root=$work;TrueNativeChildExit=$exitCode
 NativeErrorMessage=$errorMessage
 StartUtc=$begin.ToString('o');EndUtc=$finish.ToString('o');ElapsedSec=[math]::Round(($finish-$begin).TotalSeconds,3)
 NewSourceZipSHA256=(Sha $source);OriginalVendorZipSHA256=(Sha $vendor)
 CacheManifestSHA256=(Sha $manifest);OfficialAppsQueueSHA256=(Sha $apps)
 NativeStdoutPath=$stdout;NativeStdoutSHA256=$(if([IO.File]::Exists($stdout)){Sha $stdout}else{''})
 NativeStderrPath=$stderr;NativeStderrSHA256=$(if([IO.File]::Exists($stderr)){Sha $stderr}else{''})
 ActualEvidence=@($ev|ForEach-Object{[ordered]@{Path=$_.FullName;SHA256=(Sha $_.FullName);Bytes=$_.Length}})
 ActualSourceReports=@($report|ForEach-Object{[ordered]@{Path=$_.FullName;SHA256=(Sha $_.FullName);Bytes=$_.Length}})
 ImagingStatus=$(if($exitCode -eq 0){'CHILD_EXIT0_AWAIT_INDEPENDENT_PHYSICAL_IMAGE_QA'}else{'CHILD_NONZERO_NO_IMAGE_SUCCESS_ASSERTED'})
 VMStatus='NOT_RUN';NeedRDCBaselineRestore=$true
 OneNext='RESTORE_ORIGINAL_RDC_33_AND_FRESH_INDEPENDENT_VERIFY_THEN_IMAGE_QA'
}
SaveNew $receipt $rec
Write-Host ('R051_OP03C_REAL_NATIVE_BUILD_CHILD_EXIT='+$exitCode+' ELAPSED_SEC='+$rec.ElapsedSec+' EVIDENCE='+$ev.Count+' REPORTS='+$report.Count+' RECEIPT_SHA='+(Sha $receipt))
exit $exitCode
