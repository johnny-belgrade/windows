# R051 OP06 read-only same-WIM, four fresh PS7 inventory probes, independent per-probe QA and mandatory safe DISM dismount.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$base='C:\work\_UUP'
$hist=Join-Path $base 'UUP-history\R051_PREMAX_20261121'
$root=Join-Path $base 'temp\R053_COMProbe_20261121'
$mount=Join-Path $root 'Mount'
$wim=Join-Path $base 'temp\R052\BlueLite_Work\OP45_SourceOnly_26300_10066_0344497f_0fce93d5\BlueLite_Work\BlueLite_Stage_v11_3_26300_10066_0344497f_24422d89\ISOFOLDER\sources\install.wim'
$expectedWimSHA256='99407C0AA99EC0A06355D8F5C23DBEEAD6E1A1D5F147771026AF48D4AD638916'
$probe=Join-Path $hist 'R051_OP06_ProbeOne.ps1'
$verifier=Join-Path $hist 'R051_OP06_VerifyOne.ps1'
$started=Join-Path $hist 'R051_OP06_Start.json'
$receipt=Join-Path $hist 'R051_OP06_Orchestrator.json'
$mountLog=Join-Path $hist 'R051_OP06_DismMountReadOnly.log'
$unmountLog=Join-Path $hist 'R051_OP06_DismUnmountDiscard.log'
$tests=@('Packages','Capabilities','Features','ProvisionedApps')
$nativeReceipts=[ordered]@{}
function SHA([string]$path){return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToUpperInvariant()}
function NewJson([string]$path,[object]$record) {
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
 $f=[IO.File]::Open($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
$startedUTC=[DateTime]::UtcNow
$didMount=$false;$mountExit='NOT_RUN';$unmountExit='NOT_RUN';$failure='';$allFour=$false;$initialMountNone=$false
$afterMountNone=$false;$originalUnchanged=$false;$afterWimSHA='NOT_CHECKED';$admin=$false
try{
 if((Test-Path $root) -or (Test-Path $started) -or (Test-Path $receipt) -or (Test-Path $mountLog) -or (Test-Path $unmountLog)){throw 'NEW_READ_ONLY_DIAGNOSTIC_OUTPUT_COLLISION'}
 foreach($test in $tests){foreach($suffix in @('Native.json','Independent.json','NativeConsole.log','QAVerify.log')){
  if(Test-Path (Join-Path $hist ('R051_OP06_'+$test+'_'+$suffix))){throw ('PER_CMDLET_OUTPUT_COLLISION '+$test)}
 }}
 if(-not [IO.File]::Exists($wim) -or (Get-Item $wim).Length -ne 7414889686){throw 'SOURCE_RECONSTRUCTED_WIM_SIZE_CHANGED'}
 if((SHA $wim) -cne $expectedWimSHA256){throw 'SOURCE_RECONSTRUCTED_WIM_SHA_CHANGED'}
 foreach($p in @($probe,$verifier)){if(-not [IO.File]::Exists($p)){throw ('REVIEWED_TEST_SOURCE_ABSENT '+$p)}}
 if(@(Get-VM|Where-Object {$_.State -ne 'Off'}).Count -ne 0){throw 'VM_NOT_OFF'}
 if([IO.DriveInfo]::new('C').AvailableFreeSpace -lt 64424509440){throw 'C_FREE_LT_60GIB'}
 & fltmc.exe *> $null
 $admin=($LASTEXITCODE -eq 0)
 if(-not $admin){throw 'ADMIN_REQUIRED_FOR_READ_ONLY_OFFLINE_MOUNT'}
 $mounted=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
 if($LASTEXITCODE -ne 0 -or -not $mounted.Contains('No mounted images found.')){throw 'INITIAL_DISM_WIM_MOUNTED_OR_TOOL_HOLD'}
 $initialMountNone=$true
 [void][IO.Directory]::CreateDirectory($mount)
 NewJson $started ([ordered]@{Schema='BlueLite.R051.OP06.ReadOnlyWimDiagnosticStarted.v1';UTC=$startedUTC.ToString('o');PID=$PID;InputWim=$wim;ExpectedSHA256=$expectedWimSHA256;SourceWimBytes=(Get-Item $wim).Length;MountDir=$mount;MountIsReadOnly=$true;TestNames=$tests;VMsOff=$true;DismMountedBefore=0})
 & dism.exe /English /Mount-Image ("/ImageFile:"+$wim) /Index:1 ("/MountDir:"+$mount) /ReadOnly *> $mountLog
 $mountExit=$LASTEXITCODE
 if($mountExit -ne 0){throw ('NATIVE_DISM_READ_ONLY_MOUNT_EXIT_'+$mountExit)}
 $didMount=$true
 if(-not [IO.Directory]::Exists((Join-Path $mount 'Windows'))){throw 'REAL_READ_ONLY_WINDOWS_IMAGE_ROOT_MISSING'}
 $pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source
 foreach($test in $tests){
  $native=Join-Path $hist ('R051_OP06_'+$test+'_Native.json')
  $qa=Join-Path $hist ('R051_OP06_'+$test+'_Independent.json')
  $console=Join-Path $hist ('R051_OP06_'+$test+'_NativeConsole.log')
  $verifyLog=Join-Path $hist ('R051_OP06_'+$test+'_QAVerify.log')
  & $pwsh -NoLogo -NoProfile -NonInteractive -File $probe -TestName $test -Mount $mount -ExpectedWimSHA256 $expectedWimSHA256 -ReceiptPath $native *> $console
  $childExit=$LASTEXITCODE
  if($childExit -ne 0 -or -not [IO.File]::Exists($native)){throw ('INDIVIDUAL_NATIVE_INVENTORY_NO_RECEIPT_'+$test+'_CHILD_'+$childExit)}
  & $pwsh -NoLogo -NoProfile -NonInteractive -File $verifier -TestName $test -NativeReceipt $native -QAReceipt $qa -ExpectedWimSHA256 $expectedWimSHA256 *> $verifyLog
  $qaExit=$LASTEXITCODE
  if($qaExit -ne 0 -or -not [IO.File]::Exists($qa)){throw ('INDIVIDUAL_INDEPENDENT_QA_FAILED_'+$test+'_CHILD_'+$qaExit)}
  $r=Get-Content $native -Raw|ConvertFrom-Json -Depth 12
  $v=Get-Content $qa -Raw|ConvertFrom-Json -Depth 12
  if($r.TestName -cne $test -or $v.TestName -cne $test -or $v.NativeReceiptSHA256 -cne (SHA $native)){throw ('PHYSICAL_TEST_AND_QA_MISMATCH_'+$test)}
  $nativeReceipts[$test]=[ordered]@{
   TestName=$test;NativeStatus=$r.NativeCmdletStatus;ResultCount=$r.ReturnedObjectCount
   ErrorType=$r.RealExceptionType;HResult=$r.RealExceptionHResult;ErrorMessage=$r.RealExceptionMessage
   NativeReceiptSHA256=(SHA $native);IndependentQA_SHA256=(SHA $qa)
   NativeConsoleSHA256=(SHA $console);VerifyConsoleSHA256=(SHA $verifyLog)
  }
 }
 $allFour=$true
}catch{
 $failure=$_.Exception.Message
}finally{
 if($didMount -or [IO.Directory]::Exists((Join-Path $mount 'Windows'))){
  try{
   & dism.exe /English /Unmount-Image ("/MountDir:"+$mount) /Discard *> $unmountLog
   $unmountExit=$LASTEXITCODE
  }catch{
   $unmountExit='EXCEPTION'
   if($failure){$failure+='; '}
   $failure+=('DISM_DISCARD_EXCEPTION '+$_.Exception.Message)
  }
 }
}
try{
 $mountQuery=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
 $afterMountNone=($LASTEXITCODE -eq 0 -and $mountQuery.Contains('No mounted images found.'))
 if([IO.File]::Exists($wim)){$afterWimSHA=SHA $wim}
 $originalUnchanged=($afterWimSHA -ceq $expectedWimSHA256)
}catch{
 if($failure){$failure+='; '}
 $failure+=('POST_WIM_OR_MOUNT_AUDIT '+$_.Exception.Message)
}
$finish=[DateTime]::UtcNow
$ok=($allFour -and -not $failure -and $mountExit -eq 0 -and $unmountExit -eq 0 -and $afterMountNone -and $originalUnchanged)
$report=[ordered]@{
 Schema='BlueLite.R051.OP06.ReadOnlyShortMountedWimFourInventoryIsolation.v1'
 UTC=$finish.ToString('o');PID=$PID;StartedUTC=$startedUTC.ToString('o');ElapsedSeconds=[math]::Round(($finish-$startedUTC).TotalSeconds,3)
 InputWimPath=$wim;InputWimBytes=7414889686;ExpectedOriginalWimSHA256=$expectedWimSHA256;PhysicalWimSHAAfter=$afterWimSHA
 ShortMountRoot=$mount;MountReadOnly=$true;Admin=$admin;DismMountedBeforeNone=$initialMountNone
 NativeMountExit=$mountExit;NativeMountLogSHA256=$(if(Test-Path $mountLog){SHA $mountLog}else{''})
 NativeUnmountDiscardExit=$unmountExit;NativeUnmountLogSHA256=$(if(Test-Path $unmountLog){SHA $unmountLog}else{''})
 FourIndividualNativeTestsAndIndependentQAs=$nativeReceipts;AllFourRecordedAndIndependentlyChecked=$allFour
 DismNoMountedImagesAfter=$afterMountNone;OriginalSourceWimUnchanged=$originalUnchanged
 Error=$failure
 Result=$(if($ok){'ATOMIC_READ_ONLY_FOUR_INVENTORY_CMDLET_DIAGNOSTIC_WITH_SAFE_DISM_DISCARD_COMPLETE'}else{'MOUNT_OR_QA_OR_HYGIENE_HOLD'})
 VMRuntime='NOT_RUN';ImageMutation='NONE_READ_ONLY'
 OneNext=$(if($ok){'EXACT_NATIVE_CMDLET_RESULT_REVIEW_AND_SOURCE_SPECIFIC_FIX_PROOF_BEFORE_ANY_THIRD_BUILD'}else{'STOP_AND_RECONCILE_NATIVE_MOUNT_QA_OR_ORIGINAL_SOURCE'})
}
NewJson $receipt $report
Write-Host ('R051_OP06_TRUE_READ_ONLY_DIAGNOSTIC '+$report.Result+' MOUNT_EXIT='+$mountExit+' DISMOUNT_EXIT='+$unmountExit+' FOUR='+$allFour+' DISM0='+$afterMountNone+' ORIGINAL_WIM_SAME='+$originalUnchanged+' RECEIPT_SHA='+(SHA $receipt))
foreach($test in $tests){if($nativeReceipts.Contains($test)){Write-Host ('R051_OP06_'+$test+' '+$nativeReceipts[$test].NativeStatus+' count='+$nativeReceipts[$test].ResultCount+' err='+$nativeReceipts[$test].HResult)}}
if(-not $ok){Write-Host ('R051_OP06_REASON='+$failure);exit 17}
exit 0
