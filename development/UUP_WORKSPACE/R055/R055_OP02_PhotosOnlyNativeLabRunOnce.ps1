# R055 OP02 owner authorized NEW final profile demotes Photos from required FINAL to user-optional, but keeps UUP staging.
# Genuine original Windows 11 Pro 26300.10066 only, independent fresh native post-state before servicing.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$base='C:\work\_UUP'
$lab=Join-Path $base 'temp\R055_Photos_20261121'
$short=Join-Path $base 'temp\R055M56'
$mount=Join-Path $short 'm'
$h='C:\work\logs\R055_20261121'
$old=Join-Path $base 'temp\R055_WiFi_20261121\install.R055.LZX.wim'
$expected='6C1C578C67C97D1FE67D3A20068732DC219DEFBFB0BD50E6489DF9D8574024DB'
$copy=Join-Path $lab 'work.wim'
$out=Join-Path $lab 'install.R055.Photos.LZX.wim'
$wm=Join-Path $base 'temp\R054_Lab_20261121\bin\wimlib-imagex.exe'
$verify='C:\work\scripts\R055_OP02_PhotosFreshIndependentVerify.ps1'
$started=Join-Path $h 'R055_OP02_Started.json'
$removed=Join-Path $h 'R055_OP02_ExactPhotosNative.json'
$removedQA=Join-Path $h 'R055_OP02_ExactPhotosFreshQA.json'
$final=Join-Path $h 'R055_OP02_NativeOutcome.json'
$photosPackage='Microsoft.Windows.Photos_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
function SHA([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
function WriteNewJson([string]$path,[object]$obj){
 $b=[Text.UTF8Encoding]::new($false).GetBytes(($obj|ConvertTo-Json -Depth 15)+[Environment]::NewLine)
 $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
}
if(Test-Path $lab){throw 'OWNER_NEW_PHOTOS_LAB_ALREADY_EXISTS'}
if(Test-Path $short){throw 'OWNER_NEW_SHORT_MOUNT_ALREADY_EXISTS'}
foreach($p in @($started,$removed,$removedQA,$final)){if(Test-Path $p){throw ('PHOTOS_OP02_IMMUTABLE_RECEIPT_COLLISION '+$p)}}
if(-not [IO.File]::Exists($verify) -or -not [IO.File]::Exists($wm)){throw 'REVIEWED_FRESH_VERIFIER_OR_ORIGINAL_WIMLIB_NOT_FOUND'}
if((Get-Item $old).Length -ne 5596636267 -or (SHA $old) -cne $expected){throw 'PROVEN_R055_WIM_SOURCE_HAS_CHANGED'}
$sourceFinal='C:\work\_UUP\temp\R054_Lab_20261121\BlueLite\BlueLite_RequiredFinalApps.txt'
$sourceStage='C:\work\_UUP\temp\R054_Lab_20261121\BlueLite\BlueLite_RequiredStagingApps.txt'
if((SHA $sourceFinal) -ne '9D723DE7CAC1198447F918DE8254415890D7D5A0ECF1D73C9B9A077A813E3C2B' -or (SHA $sourceStage) -ne '3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265'){throw 'UNVERIFIED_CURRENT_SOURCE_PHOTOS_POLICY'}
if(-not ((Get-Content $sourceFinal -Raw).Contains('Microsoft.Windows.Photos')) -or -not ((Get-Content $sourceStage -Raw).Contains('Microsoft.Windows.Photos'))){throw 'ORIGINAL_BOTH_REQUIRED_LISTS_MUST_REFERENCE_PHOTOS'}
if(@(Get-VM|Where-Object {$_.State -ne 'Off'}).Count -ne 0){throw 'VM_ALREADY_RUNNING'}
$m=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
if($LASTEXITCODE -ne 0 -or -not $m.Contains('No mounted images found.')){throw 'HOST_DISM_MOUNTS_DIRTY'}
if([IO.DriveInfo]::new('C').AvailableFreeSpace -lt 53687091200){throw 'C_FREE_LESS_THAN_50GIB'}
& fltmc.exe *> $null
if($LASTEXITCODE -ne 0){throw 'NOT_ELEVATED'}
[void][IO.Directory]::CreateDirectory($lab)
[void][IO.Directory]::CreateDirectory($mount)
$startedUTC=[DateTime]::UtcNow
WriteNewJson $started ([ordered]@{Schema='BlueLite.R055.OP02.PhotosSourceBoundLabStart.v1';UTC=$startedUTC.ToString('o');PID=$PID;OriginalGenuineWim=$old;ExpectedOriginalSHA=$expected;Copy=$copy;ShortMount=$mount;PhotosPackage=$photosPackage;OriginalRequiredFinalSHA=(SHA $sourceFinal);OriginalRequiredStagingSHA=(SHA $sourceStage);NewFinalPolicy='Photos optional user reinstallable AFTER mandatory UUP staging';OwnerMaxWIMBytes=5500000000})
[IO.File]::Copy($old,$copy,$false)
if((SHA $copy) -cne $expected){throw 'OWNER_NEW_IMAGE_COPY_SHA_MISMATCH'}
$mounted=$false;$complete=$false;$committed=$false;$status='NATIVE_HOLD';$err=''
$codeMount=-1;$codeCommit=-1;$codeCleanup=-1;$codeCheck=-1;$codeScan=-1;$codeExport=-1;$codeLZX=-1
$before=@();$after=@();$nativePhotosDone=$false;$freshPhotosQA=$false;$bytes=0;$outSha=''
try{
 & dism.exe /English /Mount-Image ("/ImageFile:"+$copy) /Index:1 ("/MountDir:"+$mount) *> (Join-Path $h 'R055_OP02_Mount.log')
 $codeMount=$LASTEXITCODE
 if($codeMount -ne 0){throw ('DISM_MOUNT_FAILED_'+$codeMount)}
 $mounted=$true
 if(-not [IO.Directory]::Exists((Join-Path $mount 'Windows'))){throw 'MOUNTED_WINDOWS_ROOT_NOT_REAL'}
 $before=@(Get-AppxProvisionedPackage -Path $mount -ErrorAction Stop)
 $photos=@($before|Where-Object {$_.DisplayName -ceq 'Microsoft.Windows.Photos'})
 if($before.Count -ne 10 -or $photos.Count -ne 1 -or $photos[0].PackageName -cne $photosPackage){throw 'REAL_ORIGINAL_PHOTOS_APPX_PACKAGE_OR_COUNT_MISMATCH'}
 $fullBefore=@($before|ForEach-Object{[ordered]@{DisplayName=$_.DisplayName;PackageName=$_.PackageName}})
 $removalStdout=Join-Path $h 'R055_OP02_ExactPhotosNativeConsole.json'
 $rem=Remove-AppxProvisionedPackage -Path $mount -PackageName $photosPackage -ErrorAction Stop
 [IO.File]::WriteAllText($removalStdout,($rem|ConvertTo-Json -Depth 6)+[Environment]::NewLine,[Text.UTF8Encoding]::new($false))
 $nativePhotosDone=$true
 WriteNewJson $removed ([ordered]@{Schema='BlueLite.R055.OP02.OneExactPhotosNativeRemoval.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID;NativeStatus='NATIVE_REMOVE_PROVISIONED_PHOTOS_COMPLETED';ExactPhotosPackageName=$photosPackage;BeforeAppx=$fullBefore;NativeRemoveOutputSHA=(SHA $removalStdout);OriginalFinalRequiredListStillUnmodified=$true;OriginalStagingRequiredListStillUnmodified=$true})
 $pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source
 & $pwsh -NoLogo -NoProfile -NonInteractive -File $verify -Mount $mount -NativeReceipt $removed -QAReceipt $removedQA *> (Join-Path $h 'R055_OP02_ExactPhotosVerifierConsole.log')
 if($LASTEXITCODE -ne 0 -or -not [IO.File]::Exists($removedQA)){throw 'PHOTOS_FRESH_PSH7_POST_QA_FAILED'}
 $vr=Get-Content $removedQA -Raw|ConvertFrom-Json -Depth 10
 if($vr.Status -cne 'TRUE_FRESH_PSH7_NATIVE_POST_PHOTOS_ONLY_REMOVED_VALIDATED' -or $vr.NativeReceiptSHA -cne (SHA $removed)){throw 'ORIGINAL_PHOTOS_POST_QA_NOT_BINDING_TO_NATIVE'}
 $freshPhotosQA=$true
 Write-Host ('R055_OP02_TRUE_ORIGINAL_PHOTOS_NATIVE_AND_SEPARATE_FRESH_QA_PASS SHA='+(SHA $removedQA))
 $cleanLog=Join-Path $h 'R055_OP02_StartComponentCleanup.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /StartComponentCleanup *> $cleanLog
 $codeCleanup=$LASTEXITCODE
 if($codeCleanup -ne 0){throw ('COMPONENT_CLEANUP_FAILED_'+$codeCleanup)}
 $checkLog=Join-Path $h 'R055_OP02_CheckHealth.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /CheckHealth *> $checkLog
 $codeCheck=$LASTEXITCODE
 if($codeCheck -ne 0 -or -not ([IO.File]::ReadAllText($checkLog) -match 'No component store corruption detected')){throw ('CHECK_HEALTH_NOT_CLEAR_'+$codeCheck)}
 $scanLog=Join-Path $h 'R055_OP02_ScanHealth.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /ScanHealth *> $scanLog
 $codeScan=$LASTEXITCODE
 if($codeScan -ne 0 -or -not ([IO.File]::ReadAllText($scanLog) -match 'No component store corruption detected')){throw ('SCAN_HEALTH_NOT_CLEAR_'+$codeScan)}
 $commitLog=Join-Path $h 'R055_OP02_UnmountCommit.log'
 & dism.exe /English /Unmount-Image ("/MountDir:"+$mount) /Commit *> $commitLog
 $codeCommit=$LASTEXITCODE
 if($codeCommit -ne 0){throw ('COMMIT_UNMOUNT_FAILED_'+$codeCommit)}
 $mounted=$false;$committed=$true
 $afterMount=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
 if($LASTEXITCODE -ne 0 -or -not $afterMount.Contains('No mounted images found.')){throw 'DIRTY_DISM_MOUNT_AFTER_COMMIT'}
 $exportLog=Join-Path $h 'R055_OP02_ExportMax.log'
 & dism.exe /English /Export-Image ("/SourceImageFile:"+$copy) /SourceIndex:1 ("/DestinationImageFile:"+$out) /Compress:max /CheckIntegrity *> $exportLog
 $codeExport=$LASTEXITCODE
 if($codeExport -ne 0){throw ('NATIVE_WIM_EXPORT_FAILED_'+$codeExport)}
 $maxSize=(Get-Item $out).Length
 $optLog=Join-Path $h 'R055_OP02_WimlibLZX100.log'
 & $wm optimize $out '--compress=LZX:100' *> $optLog
 $codeLZX=$LASTEXITCODE
 if($codeLZX -ne 0){throw ('WIMLIB_NATIVE_LZX_OPTIMIZE_FAILED_'+$codeLZX)}
 $bytes=(Get-Item $out).Length;$outSha=SHA $out
 $complete=$true
 $status=if($bytes -le 5500000000){'NATIVE_PHOTOS_ONLY_ADDITIONAL_WIM_AND_OWNER_SIZE_PASS_NEEDS_INDEPENDENT_QA'}else{'NATIVE_PHOTOS_ONLY_WIM_FINISHED_BUT_OWNER_SIZE_HOLD'}
}catch{
 $err=$_.Exception.Message
 $status='NATIVE_PHOTOS_APPX_OR_IMAGE_DEPENDENCY_HOLD'
}finally{
 if($mounted -or [IO.Directory]::Exists((Join-Path $mount 'Windows'))){
  try{
   & dism.exe /English /Unmount-Image ("/MountDir:"+$mount) /Discard *> (Join-Path $h 'R055_OP02_UnmountDiscard.log')
   $codeCommit=$LASTEXITCODE
  }catch{$codeCommit=-999;$err+=';DISM_DISCARD_EXCEPTION '+$_.Exception.Message}
 }
}
$mountState=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
$mount0=($LASTEXITCODE -eq 0 -and $mountState.Contains('No mounted images found.'))
$originalUnchanged=(SHA $old) -ceq $expected
if(-not $mount0 -or -not $originalUnchanged){$status='SECURITY_HOLD_DISM_MOUNT_OR_ORIGINAL_WIM_CHANGED'}
$result=[ordered]@{
 Schema='BlueLite.R055.OP02.TrueNativeOriginal10066PhotosOptionalLab.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 SourceBuild='26300.10066';ParentR055WiFiLZX_SHA256=$expected;ParentOriginalPreserved=$originalUnchanged
 GenuineOriginalPhotosPackage=$photosPackage;OriginalPhotosRequiredAtUUPStaging=$true
 R055NewOptionalPhotosFinalDesign=$true;NativePhotoRemoveCompleted=$nativePhotosDone;SeparateFreshPhotoAppxQA=$freshPhotosQA
 RealIndependentPhotoAppxNativeReceiptSHA=$(if(Test-Path $removed){SHA $removed}else{''})
 RealIndependentPhotosQAReceiptSHA=$(if(Test-Path $removedQA){SHA $removedQA}else{''})
 OriginalSourceAppxCount=10;PostProvisionedAppxCountExpected=9
 MountNativeExit=$codeMount;UnmountCommitOrDiscardExit=$codeCommit;TrueCommitted=$committed
 ComponentCleanupExit=$codeCleanup;CheckHealthExit=$codeCheck;ScanHealthExit=$codeScan;DISMMaxExportExit=$codeExport;WimlibLZX100Exit=$codeLZX
 OutputWimPath=$out;PhysicalOptimizedWIMBytes=$bytes;PhysicalOptimizedWIMSHA256=$outSha
 OwnerHardMaxWimBytes=5500000000;PhysicalBytesSavedVsR055WiFiParent=$(if($bytes -gt 0){5596636267-$bytes}else{$null})
 CurrentSizeOverage=$(if($bytes -gt 0){[Math]::Max(0,$bytes-5500000000)}else{$null})
 OwnerHardSizePASS=($complete -and $bytes -gt 0 -and $bytes -le 5500000000)
 DismMounted0AtFinal=$mount0;ActualImageOrVMOutsideOwnedLabsChanged=$false
 Error=$err;Status=$status
 OneNext='FRESH_INDEPENDENT_REAL_IMAGE_SHA_APPX_NIC_PROTECTED_FLOOR_AND_WINRE_QA_BEFORE_NEW_SOURCE_ZIP_AND_ISO'
}
WriteNewJson $final $result
Write-Host ('R055_OP02_REAL_PHOTOS_NATIVE_'+$status+' PHOTOS_QA='+$freshPhotosQA+' RESULT_BYTES='+$bytes+' EXTRA_SAVED='+$result.PhysicalBytesSavedVsR055WiFiParent+' OVER='+$result.CurrentSizeOverage+' MOUNT0='+$mount0+' SOURCE_UNCHANGED='+$originalUnchanged+' PRODUCER_SHA='+(SHA $final))
if(-not $complete -or -not $mount0 -or -not $originalUnchanged){exit 17}
if($bytes -gt 5500000000){exit 18}
exit 0
