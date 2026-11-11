# R042 QA-only one-shot full CMD: deliberately bound to an isolated .9974 fixture, NOT part of universal distribution.
# This script never touches original source R041, Golden or host BCD/EFI; emits one external QA receipt.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Need([bool]$Condition,[string]$Why) { if(-not $Condition) { throw ('R042_OP64_FRESH_ONE_CMD_FULL_HOLD_'+$Why) } }
function Sha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant() }
$root='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111'
$delivery='C:\work\_UUP\R042_PREMAX_Delivery_20261111'
$batch=Join-Path $root 'PRE_MAX.cmd'
$vendor=Join-Path $root '26300.9974_amd64_en-us_professional_aa272a56_convert.zip'
$logs=Join-Path $root 'BlueLite_Logs'
$sourceQA=Join-Path $delivery 'R042_OP62_FullOriginalRootStageIndependentVerify.json'
$stdout=Join-Path $delivery 'R042_OP64_FullCMD_Console.txt'
$stderr=Join-Path $delivery 'R042_OP64_FullCMD_Stderr.txt'
$receipt=Join-Path $delivery 'R042_OP64_OneCMDFullNative_Producer.json'
Need (-not [IO.File]::Exists($stdout) -and -not [IO.File]::Exists($stderr) -and -not [IO.File]::Exists($receipt)) 'ALREADY_LAUNCHED_OR_RECEIPT_EXISTS_NO_RETRY'
Need ([IO.File]::Exists($sourceQA) -and [IO.File]::Exists($batch) -and [IO.File]::Exists($vendor)) 'SOURCE_QA_CMD_OR_ORIGINAL_VENDOR_MISSING'
$j=Get-Content -LiteralPath $sourceQA -Raw -Encoding UTF8 | ConvertFrom-Json
Need ($j.status -eq 'R042_OP62_FULL_NEW_ROOT_73_SOURCE_FILES_54SEALED_6OVERLAY_SECOND_NATIVE_PASS' -and [string]$j.newRoot -eq $root) 'SOURCE_SECOND_INDEPENDENT_NOT_PASS'
Need ((Sha $batch) -eq '372ABF8FE05A1532AF5037892888C6CCE17B5BF8D477CCF44036680160CE4123') 'DISTRIBUTED_CMD_SHA_CHANGED'
Need ((Sha $vendor) -eq 'A8D3FA7235528E3586206D4116ED724077CFF57CE34A2BB9E0B67778630FE778') 'ORIGINAL_UUP_VENDOR_ZIP_CHANGED'
Need ([IO.Directory]::Exists($logs) -and @(Get-ChildItem -LiteralPath $logs -Force).Count -eq 0) 'ROOT_BLUE_LITE_LOGS_NOT_EMPTY'
Need (-not [IO.Directory]::Exists((Join-Path $root 'BlueLite_Work')) -and -not [IO.Directory]::Exists((Join-Path $root 'BlueLite_NoPrompt'))) 'WORK_OR_DERIVED_ALREADY_EXISTS'
Need (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'PREEXISTING_MOUNTED_WIM'
Need (([IO.DriveInfo]::new('C')).AvailableFreeSpace -ge 80GB) 'C_DRIVE_FREE_BELOW_80GIB'
$startUtc=[DateTime]::UtcNow
$env:BLUELITE_R041_QA_NO_PAUSE='1'
$nativeExit=17
$started=$false
$startError=''
try {
 $p=Start-Process -FilePath $env:ComSpec -ArgumentList @('/d','/c',$batch) -WorkingDirectory $root -RedirectStandardOutput $stdout -RedirectStandardError $stderr -Wait -PassThru -ErrorAction Stop
 $started=$true
 $nativeExit=[int]$p.ExitCode
} catch {
 $startError=$_.Exception.Message
}
$finishedUtc=[DateTime]::UtcNow
$nativeLog=Join-Path $logs 'BlueLite_R035_CMD_Bootstrap.log'
$info=Join-Path $logs 'UUP_post-debloat_info.txt'
$r029Path=Join-Path $logs 'BlueLite_R029_RESULT.json'
$r029=$null
if([IO.File]::Exists($r029Path)) {
 try { $r029=Get-Content -LiteralPath $r029Path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { }
}
$derivedDir=Join-Path $root 'BlueLite_NoPrompt'
$derivedIso=if([IO.Directory]::Exists($derivedDir)){@(Get-ChildItem -LiteralPath $derivedDir -Filter '*.iso' -File | Select-Object FullName,Length)}else{@()}
$files=if([IO.Directory]::Exists($logs)){@(Get-ChildItem -LiteralPath $logs -File | Sort-Object Name | Select-Object Name,Length)}else{@()}
$mounts=@(Get-WindowsImage -Mounted -ErrorAction SilentlyContinue)
$record=[ordered]@{
 schema='BlueLite.R042.OP64.ActualFullOneCMDProducer.v1'
 utcStart=$startUtc.ToString('o')
 utcEnd=$finishedUtc.ToString('o')
 status=if($started -and $nativeExit -eq 0){'R042_OP64_INTEGRATED_FULL_CMD_NATIVE0_PRODUCER_REQUIRES_INDEPENDENT_QA'}else{'R042_OP64_INTEGRATED_FULL_CMD_NATIVE_HOLD_OR_RUNNER_ERROR'}
 cmdProcessStarted=$started
 cmdProcessLaunchError=$startError
 trueNativeCMDExit=$nativeExit
 exactCMD=$batch
 fullCycleRoot=$root
 originalUUPZip=$vendor
 originalUUPZipSHA256=Sha $vendor
 originalR042RootCMDsha256=Sha $batch
 priorFreshRootSourceQAsha256=Sha $sourceQA
 consoleFile=$stdout
 consolePresent=[IO.File]::Exists($stdout)
 consoleSHA256=if([IO.File]::Exists($stdout)){Sha $stdout}else{''}
 consoleBytes=if([IO.File]::Exists($stdout)){[IO.FileInfo]::new($stdout).Length}else{0}
 stderrFile=$stderr
 stderrPresent=[IO.File]::Exists($stderr)
 stderrSHA256=if([IO.File]::Exists($stderr)){Sha $stderr}else{''}
 stderrBytes=if([IO.File]::Exists($stderr)){[IO.FileInfo]::new($stderr).Length}else{0}
 nativeR035CMDlogPresent=[IO.File]::Exists($nativeLog)
 nativeR035CMDlogSHA256=if([IO.File]::Exists($nativeLog)){Sha $nativeLog}else{''}
 finalInfoPresent=[IO.File]::Exists($info)
 finalInfoSHA256=if([IO.File]::Exists($info)){Sha $info}else{''}
 originalR029ImageResultPresent=[IO.File]::Exists($r029Path)
 originalR029ImageResultSHA256=if([IO.File]::Exists($r029Path)){Sha $r029Path}else{''}
 originalR029Status=if($r029){[string]$r029.status}else{'NOT_PRESENT'}
 originalR029ISO=if($r029){[string]$r029.iso}else{''}
 portableUEFIBootProducerPresent=[IO.File]::Exists((Join-Path $logs 'BlueLite_R042_UEFI_NoPrompt_BootProducer.json'))
 portableUEFIBootIndependentVerifyPresent=[IO.File]::Exists((Join-Path $logs 'BlueLite_R042_UEFI_NoPrompt_IndependentVerify.json'))
 derivedMedia=@($derivedIso)
 rootLogs=@($files)
 hostMountedWIMCount=$mounts.Count
 sourceOriginalOutsideOwnedRootChangedByLauncher=$false
 releaseCertified=$false
 firstInstalledBoot='NOT_RUN'
 bootSpeed='NOT_MEASURED'
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {$f.Write($bytes,0,$bytes.Length)} finally {$f.Dispose()}
[pscustomobject]@{status=$record.status;nativeExit=$nativeExit;durationSec=[Math]::Round(($finishedUtc-$startUtc).TotalSeconds,1);stdoutBytes=$record.consoleBytes;stderrBytes=$record.stderrBytes;nativeR029=$record.originalR029Status;bootProducer=$record.portableUEFIBootProducerPresent;bootIndependent=$record.portableUEFIBootIndependentVerifyPresent;derivedISO=$record.derivedMedia;rootLogCount=$files.Count;mountedWIMs=$mounts.Count;receipt=$receipt;receiptSHA256=Sha $receipt} | ConvertTo-Json -Compress -Depth 7
exit 0
