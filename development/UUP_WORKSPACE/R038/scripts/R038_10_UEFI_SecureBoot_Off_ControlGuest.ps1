# BlueLite R038_10_UEFI_SecureBoot_Off_ControlGuest.ps1 — ONLY new isolated Gen2 control VM; one mode/receipt per operation.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('Create','AttachMedia','SetSecureBootOff','Start')][string]$Mode,
 [string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'SCOPE_ROOT_CHANGED'}
$name='BlueLite-R038-UEFI-SBOff-Control'
$guestFolder=Join-Path $Root 'Guest_UEFI_SBOff_Control'
$vmDir=Join-Path $guestFolder 'HyperV_Config'
$disk=Join-Path $guestFolder 'Guest_DynamicDisk.vhdx'
$logs=Join-Path $Root 'BlueLite_Logs'
$receiptPath=Join-Path $logs ('R038_10_'+$Mode+'_SBOffControl.json')
if(Test-Path -LiteralPath $receiptPath){throw 'MODE_RECEIPT_ALREADY_PRESENT_NO_BLIND_RERUN'}
$sourcePath=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
$fatPath=Join-Path $logs 'R038_09_EFIFATBootloader_SecureBoot_Result.json'
if((Get-FileHash -LiteralPath $sourcePath).Hash -ne '44B29FB8BFB13A4CD7627570C4CD8C65314647CEDFD8BF1A2B69B5A56163D290'){throw 'ORIGINAL_SOURCE_RECEIPT_SHA'}
if((Get-FileHash -LiteralPath $fatPath).Hash -ne '6D9B0A21CA475FDB619F12CB2BA767A47D9CEE5AE7A8907B1964B1FA04BD3804'){throw 'SOURCE_FAT_CERT_RECEIPT_SHA'}
$orig=Get-Content -LiteralPath $sourcePath -Raw|ConvertFrom-Json
$iso=@($orig.media|Where-Object {$_.kind -eq 'R035_ISO'})
if($iso.Count -ne 1 -or $iso[0].sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'WRONG_R035_ORIGINAL_ISO'}
if((Get-Item -LiteralPath $iso[0].path -ErrorAction Stop).Length -ne 6749851648){throw 'SOURCE_ISO_FILE_LENGTH_DRIFT'}
$baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $baseline.Generation -ne 2){throw 'BASELINE_NOT_SAME_VM'}
$baselineFW=Get-VMFirmware -VMName $baseline.Name -ErrorAction Stop
if([string]$baselineFW.SecureBoot -ne 'On'){throw 'BASELINE_SECUREBOOT_MUST_REMAIN_ON'}
$baselineDvd=@(Get-VMDvdDrive -VMName $baseline.Name -ErrorAction Stop)
if($baselineDvd.Count -ne 1 -or $baselineDvd[0].Path -ne $iso[0].path){throw 'BASELINE_SOURCE_ISO_CHANGED'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'HOST_WIM_MOUNTS_MUST_BE_ZERO'}
$freeBefore=[long](Get-PSDrive C).Free
if($freeBefore -lt 75000000000){throw 'DISK_HEADROOM_BELOW_75GB'}
$v=Get-VM -Name $name -ErrorAction SilentlyContinue
$records=@(Get-VM -ErrorAction Stop)
if($Mode -eq 'Create'){
 if($null -ne $v -or (Test-Path -LiteralPath $guestFolder)){throw 'CONTROL_ALREADY_OWNED_STOP'}
 if($records.Count -ne 1){throw 'UNEXPECTED_OTHER_HYPERV_VM_BEFORE_CREATE'}
}else{
 if($null -eq $v){throw 'CONTROL_VM_MISSING_MUST_CREATE_FIRST'}
 if($v.Name -ne $name -or $v.Generation -ne 2){throw 'CONTROL_VM_IDENTITY_OR_GENERATION'}
 if(-not $v.Path.StartsWith($guestFolder,[StringComparison]::OrdinalIgnoreCase)){throw 'CONTROL_VM_CONFIG_NOT_OWNED'}
 if($records.Count -ne 2){throw 'OTHER_HYPERV_VMS_PRESENT'}
 $createPath=Join-Path $logs 'R038_10_Create_SBOffControl.json'
 $crec=Get-Content -LiteralPath $createPath -Raw|ConvertFrom-Json
 if($crec.status -ne 'GEN2_CONTROL_CREATED_OFF_NO_ISO' -or $crec.vm_id -ne $v.VMId.ToString()){throw 'CONTROL_CREATE_RECEIPT_NOT_MATCHED'}
 if([string]$v.State -ne 'Off'){throw 'CONTROL_MUST_BE_OFF_BEFORE_MODE'}
}
$stateBefore=$(if($null -eq $v){'NONEXISTENT'}else{[string]$v.State})
$vmIdentity=$null
$status=$null
$isoShaChecked=$false
switch($Mode){
 'Create'{
  [IO.Directory]::CreateDirectory($guestFolder)|Out-Null
  New-VM -Name $name -Generation 2 -Path $vmDir -NewVHDPath $disk -NewVHDSizeBytes 51539607552 -MemoryStartupBytes 4294967296 -ErrorAction Stop|Out-Null
  $v=Get-VM -Name $name -ErrorAction Stop
  if($v.Generation -ne 2 -or [string]$v.State -ne 'Off' -or $v.MemoryStartup -ne 4294967296){throw 'NEW_CONTROL_VM_GENERATION_OR_MEMORY'}
  $hdds=@(Get-VMHardDiskDrive -VMName $name -ErrorAction Stop)
  if($hdds.Count -ne 1 -or $hdds[0].Path -ne $disk){throw 'NEW_VM_DISK_NOT_OWNED'}
  if(@(Get-VMDvdDrive -VMName $name -ErrorAction Stop).Count -ne 0){throw 'NEW_VM_DVD_NOT_EMPTY'}
  $status='GEN2_CONTROL_CREATED_OFF_NO_ISO'
 }
 'AttachMedia'{
  $dvd=@(Get-VMDvdDrive -VMName $name -ErrorAction Stop)
  if($dvd.Count -ne 0){throw 'CONTROL_ALREADY_HAS_DVD'}
  $sha=(Get-FileHash -LiteralPath $iso[0].path -Algorithm SHA256).Hash
  if($sha -ne $iso[0].sha256){throw 'ORIGINAL_ISO_FULL_SHA_CHANGED'}
  $isoShaChecked=$true
  Add-VMDvdDrive -VMName $name -Path $iso[0].path -ErrorAction Stop|Out-Null
  $dvd=@(Get-VMDvdDrive -VMName $name -ErrorAction Stop)
  if($dvd.Count -ne 1 -or $dvd[0].Path -ne $iso[0].path){throw 'CONTROL_DVD_ATTACHMENT_FAILED'}
  Set-VMFirmware -VMName $name -FirstBootDevice $dvd[0] -ErrorAction Stop
  $firm=Get-VMFirmware -VMName $name -ErrorAction Stop
  if($firm.BootOrder[0].Device.Path -ne $iso[0].path -or [string]$firm.SecureBoot -ne 'On'){throw 'CONTROL_PRETOGGLE_FIRMWARE_UNEXPECTED'}
  $status='CONTROL_SOURCE_ISO_ATTACHED_OFF_SECUREBOOT_STILL_ON'
 }
 'SetSecureBootOff'{
  $ar=Join-Path $logs 'R038_10_AttachMedia_SBOffControl.json'
  $att=Get-Content -LiteralPath $ar -Raw|ConvertFrom-Json
  if($att.status -ne 'CONTROL_SOURCE_ISO_ATTACHED_OFF_SECUREBOOT_STILL_ON' -or $att.vm_id -ne $v.VMId.ToString()){throw 'ATTACH_SOURCE_NOT_VERIFIED'}
  $dv=@(Get-VMDvdDrive -VMName $name -ErrorAction Stop)
  if($dv.Count -ne 1 -or $dv[0].Path -ne $iso[0].path){throw 'CONTROL_DVD_CHANGED'}
  $f=Get-VMFirmware -VMName $name -ErrorAction Stop
  if([string]$f.SecureBoot -ne 'On'){throw 'CONTROL_SECUREBOOT_ALREADY_OFF'}
  Set-VMFirmware -VMName $name -EnableSecureBoot Off -ErrorAction Stop
  $f=Get-VMFirmware -VMName $name -ErrorAction Stop
  if([string]$f.SecureBoot -ne 'Off' -or $f.BootOrder[0].Device.Path -ne $iso[0].path){throw 'CONTROL_SECUREBOOT_TOGGLE_FAILED'}
  $status='CONTROL_VM_SECUREBOOT_OFF_GUEST_OFF_NO_BOOT'
 }
 'Start'{
  $sr=Join-Path $logs 'R038_10_SetSecureBootOff_SBOffControl.json'
  $off=Get-Content -LiteralPath $sr -Raw|ConvertFrom-Json
  if($off.status -ne 'CONTROL_VM_SECUREBOOT_OFF_GUEST_OFF_NO_BOOT' -or $off.vm_id -ne $v.VMId.ToString()){throw 'CONTROL_POLICY_RECEIPT_MISSING'}
  $dv=@(Get-VMDvdDrive -VMName $name -ErrorAction Stop)
  if($dv.Count -ne 1 -or $dv[0].Path -ne $iso[0].path){throw 'CONTROL_SOURCE_OR_DVD_CHANGED'}
  $f=Get-VMFirmware -VMName $name -ErrorAction Stop
  if([string]$f.SecureBoot -ne 'Off' -or $f.BootOrder[0].Device.Path -ne $iso[0].path){throw 'CONTROL_FIRMWARE_NOT_EXACT_OFF_POLICY'}
  $os=Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
  $freeRam=[long]$os.FreePhysicalMemory*1024
  if($freeRam -lt 4697620480){throw ('HOST_FREE_RAM_FOR_SECOND_4G_VM_TOO_LOW_'+$freeRam)}
  $sha=(Get-FileHash -LiteralPath $iso[0].path -Algorithm SHA256).Hash
  if($sha -ne $iso[0].sha256){throw 'ORIGINAL_ISO_HASH_CHANGED'}
  $isoShaChecked=$true
  Start-VM -Name $name -ErrorAction Stop|Out-Null
  $v=Get-VM -Name $name -ErrorAction Stop
  if([string]$v.State -ne 'Running'){throw 'CONTROL_GUEST_NOT_RUNNING'}
  $status='CONTROL_GUEST_POWERED_ON_SETUP_UI_NOT_YET_OBSERVED'
 }
 default{throw 'INVALID_MODE'}
}
$v=Get-VM -Name $name -ErrorAction Stop
$fw=Get-VMFirmware -VMName $name -ErrorAction Stop
$dvd=@(Get-VMDvdDrive -VMName $name -ErrorAction Stop)
$hdds=@(Get-VMHardDiskDrive -VMName $name -ErrorAction Stop)
if($hdds.Count -ne 1 -or -not $hdds[0].Path.StartsWith($guestFolder,[StringComparison]::OrdinalIgnoreCase)){throw 'CONTROL_VHD_NOT_OWNED'}
$record=[ordered]@{schema='BlueLite.R038.Gen2SecureBootOffAB.v1';utc=[datetime]::UtcNow.ToString('o');mode=$Mode;status=$status;script_sha256=(Get-FileHash $PSCommandPath).Hash;vm_name=$name;vm_id=$v.VMId.ToString();generation=$v.Generation;vm_path=$v.Path;owned_guest_directory=$guestFolder;guest_vhd_path=$hdds[0].Path;guest_vhd_bytes=(Get-Item $hdds[0].Path).Length;guest_ram_startup=$v.MemoryStartup;vm_state_before=$stateBefore;vm_state_after=[string]$v.State;control_secureboot=[string]$fw.SecureBoot;control_secureboot_template=$(if($fw.PSObject.Properties.Name -contains 'SecureBootTemplate'){[string]$fw.SecureBootTemplate}else{$null});boot_first=$(if($fw.BootOrder.Count){[string]$fw.BootOrder[0].BootType}else{$null});dvd_count=$dvd.Count;dvd_path=$(if($dvd.Count){[string]$dvd[0].Path}else{$null});original_ISO_sha_expected=$iso[0].sha256;original_ISO_full_sha_checked_this_mode=$isoShaChecked;baseline_vm_id=$baseline.VMId.ToString();baseline_secureboot_unchanged=[string]$baselineFW.SecureBoot;source_fat_cert_receipt_sha=(Get-FileHash $fatPath).Hash;source_media_receipt_sha=(Get-FileHash $sourcePath).Hash;free_drive_before=$freeBefore;free_drive_after=[long](Get-PSDrive C).Free;setup_UI='NOT_VERIFIED';first_installed_windows_boot='NOT_RUN';later_installed_windows_boot='NOT_RUN';host_boot_or_production_source_mutation=$false}
$encoded=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
$fp=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$fp.Write($encoded)}finally{$fp.Dispose()}
Write-Output ('R038_10_'+$Mode+'_PASS state='+$v.State+' SBoot='+$fw.SecureBoot+' controlID='+$v.VMId+' isoSHAfull='+$isoShaChecked+' receiptSHA='+(Get-FileHash $receiptPath).Hash+' free='+$record.free_drive_after)
