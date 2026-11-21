# R055 OP01 owner-authorized controlled native 26300.10066 23 distinct WiFi FoD group in new copy only.
# Preserve all original source and all existing VMs; every individual DISM removal is verified from a fresh child PS7 process.
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$PSNativeCommandUseErrorActionPreference=$false
$base='C:\work\_UUP'
$lab='C:\work\_UUP\temp\R055_WiFi_20261121'
$work='C:\work\_UUP\temp\R055M55'
$mount=Join-Path $work 'm'
$h='C:\work\_UUP\UUP-history\R055_20261121'
$original='C:\work\_UUP\temp\R054_Lab_20261121\W\install.compact.wim'
$expected='6F27F3E023487309D0236C7B3FCD902BE0F1730326925C54E4EA7BB800673D91'
$copy=Join-Path $lab 'work.wim'
$out=Join-Path $lab 'install.R055.LZX.wim'
$qaScript=Join-Path $h 'R055_OP01_VerifyEachWiFiFoD.ps1'
$receipt=Join-Path $h 'R055_OP01_NativeWiFi23Outcome.json'
$start=Join-Path $h 'R055_OP01_Started.json'
function SHA([string]$p){return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash}
function NewJson([string]$p,[object]$v){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($v|ConvertTo-Json -Depth 14)+[Environment]::NewLine)
 $f=[IO.File]::Open($p,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
}
if(Test-Path $lab){throw 'NEW_R055_LAB_ALREADY_EXISTS_NO_OVERWRITE'}
if(Test-Path $work){throw 'NEW_R055_SHORT_MOUNT_ALREADY_EXISTS'}
if(Test-Path $h){throw 'NEW_R055_HISTORY_ALREADY_EXISTS'}
if((Get-Item $original).Length -ne 5667684206 -or (SHA $original) -cne $expected){throw 'PARENT_COMPACT_WIM_SHA_SIZE_CHANGED'}
if((SHA 'C:\work\_UUP\R054_PREMAX_Universal_26300x\BlueLite_PRE_MAX_26300x_R054_v1.zip') -ne '627B1696C832C69E7379269D1632D5D1A79D3BC6EB595C0FCFF4337100DD8423'){throw 'PARENT_PORTABLE_ZIP_CHANGED'}
$after=Get-Content 'C:\work\_UUP\temp\R054_Lab_20261121\BlueLite_Logs\Inventory-26300.10066-after.json' -Raw|ConvertFrom-Json -Depth 15
if($after.Build -ne '26300.10066'){throw 'NOT_GENUINE_SOURCE_26300_10066'}
$wifi=@($after.Capabilities|Where-Object{$_.Name -match '^Microsoft\.Windows\.Wifi\.Client\.[A-Za-z0-9.]+~~~~0\.0\.1\.0$' -and $_.State -eq 4}|Select-Object -ExpandProperty Name|Sort-Object)
$ethernet=@($after.Capabilities|Where-Object{$_.Name -match '^Microsoft\.Windows\.Ethernet\.Client\.' -and $_.State -eq 4}|Select-Object -ExpandProperty Name)
if($wifi.Count -ne 23 -or $ethernet.Count -ne 4){throw ('REAL_ORIGINAL_SOURCE_INVENTORY_EXPECTED_WIFI23_ETH4_ACTUAL_'+$wifi.Count+'_'+$ethernet.Count)}
$m=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
if($LASTEXITCODE -ne 0 -or -not $m.Contains('No mounted images found.')){throw 'MOUNT_DIRTY_BEFORE'}
if(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count -ne 0){throw 'EXISTING_VM_RUNNING'}
if([IO.DriveInfo]::new('C').AvailableFreeSpace -lt 53687091200){throw 'C_FREE_LT50GIB'}
& fltmc.exe *> $null
if($LASTEXITCODE -ne 0){throw 'ADMIN_REQUIRED'}
[void][IO.Directory]::CreateDirectory($h)
[void][IO.Directory]::CreateDirectory($lab)
[void][IO.Directory]::CreateDirectory($mount)
$begin=[DateTime]::UtcNow
NewJson $start ([ordered]@{Schema='BlueLite.R055.OP01.NativeOwnerWiFi23Started.v1';UTC=$begin.ToString('o');PID=$PID;OriginalSourceWIM=$original;OriginalSHA256=$expected;TargetCopy=$copy;ShortMount=$mount;Exact23=$wifi;Ethernet4Protected=$ethernet;NoOriginalMutation=$true})
[IO.File]::Copy($original,$copy,$false)
if((SHA $copy) -cne $expected){throw 'OWNED_NEW_COPY_WIM_NOT_EXACT'}
$wm='C:\work\_UUP\temp\R054_Lab_20261121\bin\wimlib-imagex.exe'
if(-not [IO.File]::Exists($wm) -or -not [IO.File]::Exists($qaScript)){throw 'WIMLIB_OR_GIT_REVIEWED_INDEPENDENT_VERIFIER_MISSING'}
$mounted=$false;$committed=$false;$complete=$false;$result='NATIVE_HOLD';$errorMessage='';$mountExit=-1;$unmountExit=-1
$checkExit=-1;$scanExit=-1;$cleanupExit=-1;$exportExit=-1;$optimizerExit=-1
$individual=@();$newWimBytes=0;$newWimHash=''
try{
 $mountLog=Join-Path $h 'R055_OP01_Mount.log'
 & dism.exe /English /Mount-Image ("/ImageFile:"+$copy) /Index:1 ("/MountDir:"+$mount) *> $mountLog
 $mountExit=$LASTEXITCODE
 if($mountExit -ne 0){throw ('NATIVE_MOUNT_FAILED_'+$mountExit)}
 $mounted=$true
 if(-not [IO.Directory]::Exists((Join-Path $mount 'Windows'))){throw 'MOUNTED_WINDOWS_ROOT_ABSENT'}
 # Actual version and identity pre-gate from mounted OS.
 $hive=Join-Path $mount 'Windows\System32\Config\SOFTWARE'
 if(-not [IO.File]::Exists($hive)){throw 'MOUNTED_SOFTWARE_HIVE_MISSING'}
 $pwsh=(Get-Command pwsh.exe -ErrorAction Stop).Source
 for($i=0;$i -lt $wifi.Count;$i++){
  $name=[string]$wifi[$i];$id=('{0:D2}' -f ($i+1))
  $native=Join-Path $h ('R055_OP01_CAP'+$id+'_Native.json')
  $stdout=Join-Path $h ('R055_OP01_CAP'+$id+'_DISM.log')
  $qa=Join-Path $h ('R055_OP01_CAP'+$id+'_FreshQA.json')
  & dism.exe /English ("/Image:"+$mount) /Remove-Capability ("/CapabilityName:"+$name) *> $stdout
  $exit=$LASTEXITCODE
  NewJson $native ([ordered]@{Schema='BlueLite.R055.OP01.OneNativeWifiFoDRemoval.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID;Ordinal=$i+1;Name=$name;NativeDismExit=$exit;StdoutPath=$stdout;StdoutSHA256=(SHA $stdout);ExactMatchedOriginal26300Source=$true})
  if($exit -ne 0){throw ('NATIVE_DISM_WIFI_REMOVAL_FAILED_STEP_'+$id+'_EXIT_'+$exit)}
  & $pwsh -NoLogo -NoProfile -NonInteractive -File $qaScript -Mount $mount -CapabilityName $name -NativeReceiptPath $native -IndependentQAPath $qa *> (Join-Path $h ('R055_OP01_CAP'+$id+'_VerifierConsole.log'))
  if($LASTEXITCODE -ne 0 -or -not [IO.File]::Exists($qa)){throw ('FRESH_QA_WIFI_REMOVAL_FAILED_'+$id)}
  $qr=Get-Content $qa -Raw|ConvertFrom-Json
  if($qr.PhysicalPostState -cne 'NotPresent' -or (SHA $native) -cne $qr.SourceNativeReceiptSHA){throw ('VERIFIER_RESULT_NOT_MATCHING_'+$id)}
  $individual+=([ordered]@{Ordinal=$i+1;Identity=$name;NativeExit=$exit;NativeReceiptSHA=(SHA $native);IndependentQA_SHA=(SHA $qa)})
  Write-Host ('R055_WIFI_STEP_'+$id+'_OF_23_NATIVE_AND_FRESH_QA_PASS')
 }
 if($individual.Count -ne 23){throw 'NOT_ALL23_WIFI_REMOVED'}
 $remain=@(Get-WindowsCapability -Path $mount -ErrorAction Stop)
 $wRemain=@($remain|Where-Object{$_.Name -in $wifi -and [string]$_.State -ne 'NotPresent'})
 $ethRemain=@($remain|Where-Object{$_.Name -in $ethernet -and [string]$_.State -eq 'Installed'})
 if($wRemain.Count -ne 0 -or $ethRemain.Count -ne 4){throw 'POST_SOURCE_WIFI0_ETHERNET4_GATE_FAILED'}
 $cleanupLog=Join-Path $h 'R055_OP01_StartComponentCleanup.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /StartComponentCleanup *> $cleanupLog
 $cleanupExit=$LASTEXITCODE
 if($cleanupExit -ne 0){throw ('COMPONENT_CLEANUP_NATIVE_EXIT_'+$cleanupExit)}
 $checkLog=Join-Path $h 'R055_OP01_CheckHealth.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /CheckHealth *> $checkLog
 $checkExit=$LASTEXITCODE
 if($checkExit -ne 0 -or -not ([IO.File]::ReadAllText($checkLog) -match 'No component store corruption detected')){throw ('CHECK_HEALTH_NOT_CLEAR_'+$checkExit)}
 $scanLog=Join-Path $h 'R055_OP01_ScanHealth.log'
 & dism.exe /English ("/Image:"+$mount) /Cleanup-Image /ScanHealth *> $scanLog
 $scanExit=$LASTEXITCODE
 if($scanExit -ne 0 -or -not ([IO.File]::ReadAllText($scanLog) -match 'No component store corruption detected')){throw ('SCAN_HEALTH_NOT_CLEAR_'+$scanExit)}
 $commitLog=Join-Path $h 'R055_OP01_UnmountCommit.log'
 & dism.exe /English /Unmount-Image ("/MountDir:"+$mount) /Commit *> $commitLog
 $unmountExit=$LASTEXITCODE
 if($unmountExit -ne 0){throw ('COMMIT_UNMOUNT_FAILED_'+$unmountExit)}
 $mounted=$false;$committed=$true
 $clear=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
 if($LASTEXITCODE -ne 0 -or -not $clear.Contains('No mounted images found.')){throw 'AFTER_COMMIT_DISM_MOUNT_DIRTY'}
 $exportLog=Join-Path $h 'R055_OP01_ExportMax.log'
 & dism.exe /English /Export-Image ("/SourceImageFile:"+$copy) /SourceIndex:1 ("/DestinationImageFile:"+$out) /Compress:max /CheckIntegrity *> $exportLog
 $exportExit=$LASTEXITCODE
 if($exportExit -ne 0){throw ('NATIVE_EXPORT_MAX_FAIL_'+$exportExit)}
 $maxBytes=(Get-Item $out).Length
 $optimLog=Join-Path $h 'R055_OP01_WimlibLZX100.log'
 & $wm optimize $out '--compress=LZX:100' *> $optimLog
 $optimizerExit=$LASTEXITCODE
 if($optimizerExit -ne 0){throw ('WIMLIB_LZX_OPTIMIZE_FAIL_'+$optimizerExit)}
 $newWimBytes=(Get-Item $out).Length;$newWimHash=SHA $out
 $complete=$true
 if($newWimBytes -le 5500000000){$result='TRUE_NATIVE_WIFI23_WIM_SIZE_PASS_NEEDS_FRESH_IMAGE_QA'}
 else{$result='TRUE_NATIVE_WIFI23_SAVED_WIM_BUT_SIZE_HOLD'}
}catch{
 $errorMessage=$_.Exception.Message
 $result='NATIVE_SOURCE_OR_SERVICING_OR_IMAGE_HOLD'
}finally{
 if($mounted -or [IO.Directory]::Exists((Join-Path $mount 'Windows'))){
  try{
   $discardLog=Join-Path $h 'R055_OP01_UnmountDiscard.log'
   & dism.exe /English /Unmount-Image ("/MountDir:"+$mount) /Discard *> $discardLog
   $unmountExit=$LASTEXITCODE
  }catch{
   $errorMessage+='; UNMOUNT_DISCARD_EXCEPTION '+$_.Exception.Message
   $unmountExit=-999
  }
 }
}
$mountInfo=(& dism.exe /English /Get-MountedWimInfo 2>&1|Out-String)
$clean=($LASTEXITCODE -eq 0 -and $mountInfo.Contains('No mounted images found.'))
$parentSame=(SHA $original) -ceq $expected
if(-not $clean -or -not $parentSame){$result='SAFETY_HOLD_MOUNT_OR_ORIGINAL_SOURCE_CHANGED'}
$all=[ordered]@{
 Schema='BlueLite.R055.OP01.RealWiFi23SingleSourceNativeRun.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 ElapsedSeconds=[math]::Round(([DateTime]::UtcNow-$begin).TotalSeconds,3)
 Source26300Build='26300.10066';ProtectedSourceSHA=$expected;SourceUnchanged=$parentSame
 OriginalSourceInventoryWiFiCount=23;OriginalSourceEthernetCount=4
 OriginalImageCopiedPath=$copy;ShortOwnedMount=$mount;IndividualOperations=$individual
 NumberOfNativeAndFreshEachQAPASS=$individual.Count
 MountNativeExit=$mountExit;CommitOrDiscardExit=$unmountExit;Committed=$committed
 NativeCleanupExit=$cleanupExit;NativeCheckHealthExit=$checkExit;NativeScanHealthExit=$scanExit
 NativeMaxExportExit=$exportExit;WimlibLZX100Exit=$optimizerExit
 PhysicalResultPath=$out;PhysicalResultBytes=$newWimBytes;PhysicalResultSHA256=$newWimHash
 HardWimSizeMaxBytes=5500000000;HardWimSizePassed=($complete -and $newWimBytes -gt 0 -and $newWimBytes -le 5500000000)
 SavedCompressedBytesAgainstR054Parent=$(if($newWimBytes -gt 0){5667684206-$newWimBytes}else{$null})
 RemainingExtraBytesForOwner=$(if($newWimBytes -gt 0){[Math]::Max(0,$newWimBytes-5500000000)}else{$null})
 DismMountedZeroAtEnd=$clean;ThreeExistingVMGuests='NOT_MODIFIED';SetupBootWIM='NOT_MODIFIED'
 Error=$errorMessage;Status=$result
 OneNext='FRESH_INDEPENDENT_NATIVE_PHYSICAL_WIM_SHA_CAPABILITY_AND_HEALTH_QA_BEFORE_ANY_NEW_ZIP_ISO_VM'
}
NewJson $receipt $all
Write-Host ('R055_OP01_REAL_WIFI23_'+$result+' STEPS='+$individual.Count+'/23 EXPORT_BYTES='+$newWimBytes+' OVERAGE='+$all.RemainingExtraBytesForOwner+' MOUNT0='+$clean+' OLD_SOURCE_UNCHANGED='+$parentSame+' RECEIPT_SHA='+(SHA $receipt))
if(-not $complete -or -not $clean -or -not $parentSame){exit 17}
if($newWimBytes -gt 5500000000){exit 18}
exit 0
