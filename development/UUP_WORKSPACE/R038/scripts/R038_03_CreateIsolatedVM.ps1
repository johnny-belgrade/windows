# BlueLite R038_03_CreateIsolatedVM.ps1 — native Hyper-V ONLY, scoped guest config + dynamic disk
# Each mode is one separated mutation op; every mode has a separate receipt, independent verification before next.
[CmdletBinding()]
param(
 [ValidateSet('Create','AttachMedia','Start')][string]$Mode,
 [ValidateSet('BlueLite-R038-UEFI-Baseline','BlueLite-R038-BIOS-SetupBaseline')][string]$VMName='BlueLite-R038-UEFI-Baseline',
 [string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'UNEXPECTED_ROOT'}
$logs=Join-Path $Root 'BlueLite_Logs'
$pre=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
$cand=Join-Path $logs 'R038_01_CandidateManifest_Result.json'
if(-not(Test-Path $pre -PathType Leaf) -or -not(Test-Path $cand -PathType Leaf)){throw 'SOURCE_PROOF_MISSING'}
$p=Get-Content $pre -Raw|ConvertFrom-Json
$q=Get-Content $cand -Raw|ConvertFrom-Json
if($p.status -ne 'ISOLATED_HOST_AND_SIX_SOURCE_SHA_PASS_VM_NOT_CREATED' -or $q.status -ne 'SIX_NATIVE_WIM_INDEX_METADATA_AND_ISO_COMPOSITION_PASS_NO_BOOT'){throw 'SOURCE_PROOF_NOT_PASS'}
if($VMName -eq 'BlueLite-R038-UEFI-Baseline'){$gen=2;$dir=Join-Path $Root 'Guest_UEFI_Baseline'}else{$gen=1;$dir=Join-Path $Root 'Guest_BIOS_SetupBaseline'}
$vmDir=Join-Path $dir 'HyperV_Config'
$vhd=Join-Path $dir 'Guest_DynamicDisk.vhdx'
$logfile=Join-Path $logs ('R038_03_'+$Mode+'_'+$VMName+'.json')
if(Test-Path $logfile){throw 'VM_OPERATION_ALREADY_RECORDED'}
if(@(Get-WindowsImage -Mounted).Count -ne 0){throw 'OFFLINE_WIM_MOUNT_PRESENT'}
$diskFree=[long](Get-PSDrive C).Free
if($diskFree -lt 75000000000){throw 'LOW_DISK_SPACE_BEFORE_GUEST_OP'}
$meta=[ordered]@{schema='BlueLite.R038.HyperVVMOperation.v1';utc=[datetime]::UtcNow.ToString('o');mode=$Mode;vm_name=$VMName;generation=$gen;scoped_vm_path=$vmDir;guest_vhd_path=$vhd;source_iso_path=$null;source_iso_sha=$null;vm_state_before=$null;vm_state_after=$null;free_disk_before=$diskFree;status='NOT_EXECUTED';script_sha256=(Get-FileHash $PSCommandPath).Hash;original_media_mutated=$false;host_BCD_EFI_modified=$false}
$existing=Get-VM -Name $VMName -ErrorAction SilentlyContinue
if($Mode -eq 'Create'){
 if($null -ne $existing){throw 'VM_NAME_ALREADY_EXISTS'}
 if(Test-Path $dir){throw 'GUEST_DIRECTORY_ALREADY_EXISTS'}
 if($VMName -eq 'BlueLite-R038-BIOS-SetupBaseline' -and -not(Test-Path (Join-Path $logs 'R038_03_Create_BlueLite-R038-UEFI-Baseline.json'))){throw 'BASELINE_UEFI_FIRST'}
 [IO.Directory]::CreateDirectory($dir)|Out-Null
 # Dynamic 48 GiB virtual disk. Initial host allocation is tiny; upper capacity is capped.
 New-VM -Name $VMName -Generation $gen -Path $vmDir -NewVHDPath $vhd -NewVHDSizeBytes 51539607552 -MemoryStartupBytes 4294967296 -ErrorAction Stop|Out-Null
 $v=Get-VM -Name $VMName -ErrorAction Stop
 if($v.Generation -ne $gen -or [string]$v.State -ne 'Off' -or -not(Test-Path $vhd)){throw 'VM_CREATE_POSTCONDITION_FAILED'}
 $meta.vm_state_after=[string]$v.State
 $meta.status='NEW_OWNED_GUEST_VM_CREATED_OFF_NO_ISO_NOT_BOOT_TESTED'
}elseif($Mode -eq 'AttachMedia'){
 if($null -eq $existing){throw 'VM_CREATE_FIRST'}
 if([string]$existing.State -ne 'Off'){throw 'CANNOT_CHANGE_RUNNING_VM'}
 $meta.vm_state_before=[string]$existing.State
 $item=@($p.media|Where-Object kind -eq 'R035_ISO')
 if($item.Count -ne 1){throw 'ORIGINAL_ISO_NOT_FOUND_IN_RECEIPT'}
 $iso=[string]$item[0].path
 $f=Get-Item -LiteralPath $iso -ErrorAction Stop
 if($f.Length -ne 6749851648 -or (Get-FileHash -LiteralPath $iso).Hash -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'ORIGINAL_ISO_SHA_DRIFT'}
 $dvd=@(Get-VMDvdDrive -VMName $VMName -ErrorAction Stop)
 if($dvd.Count -eq 0){Add-VMDvdDrive -VMName $VMName -Path $iso -ErrorAction Stop|Out-Null}else{if($dvd.Count -ne 1){throw 'DVD_DEVICE_COUNT_UNEXPECTED'};Set-VMDvdDrive -VMName $VMName -ControllerNumber $dvd[0].ControllerNumber -ControllerLocation $dvd[0].ControllerLocation -Path $iso -ErrorAction Stop}
 $attached=@(Get-VMDvdDrive -VMName $VMName -ErrorAction Stop)
 if($attached.Count -ne 1 -or $attached[0].Path -ne $iso){throw 'DVD_ATTACHMENT_FAILED'}
 if($gen -eq 2){Set-VMFirmware -VMName $VMName -FirstBootDevice $attached[0] -EnableSecureBoot On -ErrorAction Stop}
 $meta.source_iso_path=$iso;$meta.source_iso_sha=$item[0].sha256
 $meta.vm_state_after=[string](Get-VM -Name $VMName).State
 $meta.status='SOURCE_ISO_SHA_PINNED_ATTACHED_TO_GUEST_FIRMWARE_BOOT_NOT_RUN'
}elseif($Mode -eq 'Start'){
 if($null -eq $existing){throw 'VM_DOES_NOT_EXIST'}
 if([string]$existing.State -ne 'Off'){throw 'VM_MUST_BE_OFF_BEFORE_SINGLE_BOOT'}
 $att=@(Get-VMDvdDrive -VMName $VMName -ErrorAction Stop)
 $iso=@($p.media|Where-Object kind -eq 'R035_ISO')
 if($att.Count -ne 1 -or $iso.Count -ne 1 -or $att[0].Path -ne $iso[0].path){throw 'SOURCE_ISO_NOT_ATTACHED_CORRECTLY'}
 $meta.vm_state_before=[string]$existing.State
 $meta.source_iso_path=$iso[0].path;$meta.source_iso_sha=$iso[0].sha256
 Start-VM -Name $VMName -ErrorAction Stop|Out-Null
 $v=Get-VM -Name $VMName -ErrorAction Stop
 if([string]$v.State -ne 'Running'){throw 'VM_POWER_ON_NOT_RUNNING'}
 $meta.vm_state_after=[string]$v.State
 # Powered-on is not equivalent to WinPE, usable Setup, installed first boot or repeat boot PASS.
 $meta.status='VM_POWERED_ON_SETUP_UI_AND_GUEST_BOOT_NOT_YET_VERIFIED'
}else{throw 'INVALID_MODE'}
$meta.free_disk_after=[long](Get-PSDrive C).Free
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($meta|ConvertTo-Json -Depth 7)+[Environment]::NewLine)
$stream=[IO.File]::Open($logfile,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$stream.Write($bytes)}finally{$stream.Dispose()}
Write-Output ('R038_03_'+$Mode+'_PASS '+$VMName+' result='+$meta.status+' result_SHA='+(Get-FileHash $logfile).Hash+' free='+$meta.free_disk_after)
