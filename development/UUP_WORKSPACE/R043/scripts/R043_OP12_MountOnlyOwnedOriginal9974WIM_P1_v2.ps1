# R043 OP12 v2: corrected source independent QA property newOwnedDisposableWIM; initial v1 failed before mount/receipt. Mount ONLY independently SHA-pinned copied original .9974 WIM, native DISM; no original source or VM mutations.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$cycle='C:\work\_UUP\R043_PREMAX_P1_20261112'
$logs=Join-Path $cycle 'BlueLite_Logs'
$wim=Join-Path $cycle 'OwnedDisposable\R043_Original9974_P1_OWNED.wim'
$mount=Join-Path $cycle 'OwnedMount'
$log=Join-Path $logs 'R043_OP12_ActualDISM_Mount_Console.txt'
$errlog=Join-Path $logs 'R043_OP12_ActualDISM_Mount_StdErr.txt'
$receipt=Join-Path $logs 'R043_OP12_OwnedONLY_WimMount_Producer.json'
foreach($path in @($mount,$log,$errlog,$receipt)){if(Test-Path -LiteralPath $path){throw ('OP12_MOUNT_OR_RECEIPT_EXISTS_'+$path)}}
$src=Join-Path $logs 'R043_OP10_OwnedDisposable_WIM_Copy_IndependentVerify.json'
$p=Get-Content -LiteralPath $src -Raw|ConvertFrom-Json
if($p.status -ne 'R043_OP10_ORIGINAL_AND_ONLY_OWNED_DISPOSABLE_9974_WIMS_BOTH_INDEPENDENT_FULL_SHA_PASS' -or $p.newOwnedDisposableWIM -ne $wim -or $p.ownedDisposableSHA -ne '61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2' -or [IO.FileInfo]::new($wim).Length -ne 5602983183){throw 'WIM_COPY_SECOND_NATIVE_SOURCE_QA_NOT_PASS'}
if(@(Get-WindowsImage -Mounted).Count -ne 0 -or @(Get-VM|Where-Object{$_.State -ne 'Off'}).Count -ne 0 -or @(Get-Disk).Count -ne 1){throw 'BEFORE_DISM_MOUNT_HOST_NOT_RELEASED'}
$free=([IO.DriveInfo]::new('C')).AvailableFreeSpace
if($free -lt 60GB){throw 'HOST_C_FREE_BELOW_60GB_P1_MOUNT_HOLD'}
$start=[DateTime]::UtcNow.ToString('o')
[void][IO.Directory]::CreateDirectory($mount)
$args=@('/English','/Mount-Image',('/ImageFile:'+$wim),'/Index:1',('/MountDir:'+$mount),'/CheckIntegrity')
$rc=$null
$nativeError=''
try {
 $proc=Start-Process -FilePath (Join-Path $env:WINDIR 'System32\dism.exe') -ArgumentList $args -Wait -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError $errlog -ErrorAction Stop
 $rc=[int]$proc.ExitCode
}catch{$nativeError=$_.Exception.Message}
$current=@(Get-WindowsImage -Mounted -ErrorAction SilentlyContinue)
$actual=@($current|Select-Object ImagePath,Path,ImageIndex,MountStatus)
$owned=@($current|Where-Object{$_.Path -ieq $mount -and $_.ImagePath -ieq $wim})
$success=($rc -eq 0 -and $owned.Count -eq 1 -and $current.Count -eq 1)
$status=if($success){'R043_OP12_ONLY_OWNED_9974_WIM_RW_MOUNT_NATIVE0_SOURCE_BOUND_PASS'}else{'R043_OP12_DISM_MOUNT_NATIVE_OR_SOURCE_HOLD_REQUIRES_MOUNT_RELEASE'}
$o=[ordered]@{
 utcStart=$start
 utcEnd=[DateTime]::UtcNow.ToString('o')
 schema='BlueLite.R043.OP12.OnlyOwnedWimSourceMounted.v1'
 status=$status
 nativeDismMountExit=$rc
 nativeError=$nativeError
 nativeArgs=$args
 ownerWim=$wim
 mountDir=$mount
 mountedImageCount=$current.Count
 mountedImageData=$actual
 vendorConsole=$log
 vendorConsoleSHA=if([IO.File]::Exists($log)){(Get-FileHash $log -Algorithm SHA256).Hash}else{''}
 stderrBytes=if([IO.File]::Exists($errlog)){[IO.FileInfo]::new($errlog).Length}else{0}
 sourceIndependentFullSHAReceipt=(Get-FileHash $src -Algorithm SHA256).Hash
 originalSourceSHA='61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2'
 all3VMoff=(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count -eq 0)
 diskOnlyHost0=(@(Get-Disk).Count -eq 1)
 hostFreeAfter=[math]::Round(([IO.DriveInfo]::new('C')).AvailableFreeSpace/1GB,3)
 sourceOriginalWIMnotMounted=$true
 noGuestBootOrHostEFIBCDMutation=$true
}
[IO.File]::WriteAllText($receipt,(($o|ConvertTo-Json -Depth 9)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$status;nativeExit=$rc;mountedImageCount=$current.Count;matchedOwnedMounts=$owned.Count;mounted=$actual;CfreeGiB=$o.hostFreeAfter;receiptSHA=(Get-FileHash $receipt -Algorithm SHA256).Hash}|ConvertTo-Json -Depth 6 -Compress
if(-not $success){exit 17}
