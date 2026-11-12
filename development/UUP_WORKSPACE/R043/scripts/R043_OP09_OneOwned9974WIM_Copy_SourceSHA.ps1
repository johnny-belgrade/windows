# R043 OP09: ONE copy original R042 9974 WIM into R043 OWNED disposable for P1, no mount/other media.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$cycle='C:\work\_UUP\R043_PREMAX_P1_20261112'
$logs=Join-Path $cycle 'BlueLite_Logs'
$destDir=Join-Path $cycle 'OwnedDisposable'
$dest=Join-Path $destDir 'R043_Original9974_P1_OWNED.wim'
$receipt=Join-Path $logs 'R043_OP09_OwnedDisposable_WIM_Copy_Producer.json'
if([IO.File]::Exists($receipt) -or [IO.File]::Exists($dest)){throw 'OP09_DISPOSABLE_ALREADY_EXISTS_FAIL_CLOSED'}
$native='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111\BlueLite_Logs\BlueLite_R029_RESULT.json'
$r=Get-Content -LiteralPath $native -Raw|ConvertFrom-Json
if($r.build -ne '26300.9974' -or $r.install_wim_sha256 -ne '61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2' -or [long]$r.install_wim_bytes -ne 5602983183){throw 'ORIGINAL_SOURCE_NATIVE_R029_RECEIPT_NOT_PASS'}
$source=[string]$r.install_wim
$orig=[IO.FileInfo]::new($source)
if(-not $orig.Exists -or $orig.Length -ne 5602983183){throw 'ORIGINAL_WIM_BYTES_OR_MISSING'}
if(@(Get-VM|Where-Object{$_.State -ne 'Off'}).Count -or @(Get-WindowsImage -Mounted).Count -or @(Get-Disk).Count -ne 1 -or -not (Get-Disk -Number 0).IsSystem -or -not (Get-Disk -Number 0).IsBoot){throw 'HOST_WIM_VM_DISK_NOT_RELEASED'}
$freeBefore=([IO.DriveInfo]::new('C')).AvailableFreeSpace
if($freeBefore -lt 70GB){throw 'LESS_THAN_70G_PRE_COPY_NEEDS_OPERATOR_CLEANUP'}
$zip='C:\work\_UUP\R042_PREMAX_Delivery_20261111\BlueLite_PREMAX_R042_Universal26300x_NoPrompt_DRAFT.zip'
if((Get-FileHash $zip -Algorithm SHA256).Hash -ne '99BAF4E3407CF5F964DB2418F00A010C485F2622392ACE27C132D3BF0C2A21E1'){throw 'OLD_PROVEN_PORTABLE_SOURCE_CHANGED'}
$start=[DateTime]::UtcNow.ToString('o')
$originalSha=(Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
if($originalSha -ne $r.install_wim_sha256){throw 'SOURCE_ORIGINAL_WIM_PHYSICAL_SHA_DRIFT'}
[void][IO.Directory]::CreateDirectory($destDir)
[IO.File]::Copy($source,$dest,$false)
$clone=[IO.FileInfo]::new($dest)
if(-not $clone.Exists -or $clone.Length -ne $orig.Length){throw 'OWNED_WIM_COPY_PHYSICAL_SIZE_MISMATCH'}
$copySha=(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
if($copySha -ne $originalSha){throw 'OWNED_WIM_COPY_PHYSICAL_FULL_SHA_MISMATCH'}
$freeAfter=([IO.DriveInfo]::new('C')).AvailableFreeSpace
if($freeAfter -lt 60GB){throw 'DISPOSABLE_WIM_POST_COPY_HOST_SPACE_LOW'}
if(@(Get-WindowsImage -Mounted).Count -ne 0 -or @(Get-VM|Where-Object{$_.State -ne 'Off'}).Count){throw 'HOST_WIM_OR_VM_RESOURCE_CHANGED_DURING_COPY'}
$o=[ordered]@{
 schema='BlueLite.R043.OP09.OneBoundedOriginal9974WimDisposableClone.v1'
 utcStart=$start
 utcEnd=[DateTime]::UtcNow.ToString('o')
 status='R043_OP09_ONLY_OWNED_9974_5602983183B_DISPOSABLE_WIM_PHYSICAL_SHA_COPY_PRODUCER_PASS'
 originalSourceWIM=$source
 ownedDisposableWIM=$dest
 eachPhysicalBytes=$clone.Length
 originalFullSHA=$originalSha
 disposableFullSHA=$copySha
 sourceR029ReceiptSHA=(Get-FileHash $native -Algorithm SHA256).Hash
 pinnedOriginalPortableZIPsha=(Get-FileHash $zip -Algorithm SHA256).Hash
 freeBeforeBytes=$freeBefore
 freeAfterBytes=$freeAfter
 sourceOriginalNeverMutated=$true
 newOwnedWimNotYetMounted=$true
 all3HyperVOff=$true
 hostWimMounts=0
 noHyperVBootExperiment=$true
}
[IO.File]::WriteAllText($receipt,(($o|ConvertTo-Json -Depth 7)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status=$o.status;bytes=$clone.Length;originalSHA=$originalSha;copySHA=$copySha;CfreeGiB=[math]::Round($freeAfter/1GB,3);newDisposable=$dest;receiptSHA=(Get-FileHash $receipt -Algorithm SHA256).Hash}|ConvertTo-Json -Compress
