# BlueLite R038_12_StopControlAfterScreenshot.ps1 — only exact owned CONTROL guest TurnOff after proven UEFI firmware error screenshot; no VM delete or host boot change.
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'ROOT_NOT_OWNED'}
$logs=Join-Path $Root 'BlueLite_Logs'
$p=Join-Path $logs 'R038_11_SBOffControl_GuestVideo_640x480.png'
$r=Join-Path $logs 'R038_11_GuestVideoCapture_Result.json'
$prior=Join-Path $logs 'R038_10_Start_SBOffControl.json'
$baselinePhoto=Join-Path $logs 'R038_07_UEFI_GuestVideo_640x480.png'
$destination=Join-Path $logs 'R038_12_StopSBOffControl_Result.json'
if(Test-Path -LiteralPath $destination){throw 'STOP_ALREADY_RECORDED_NO_RETRY'}
if((Get-FileHash $p).Hash -ne 'CC96C02291CE1D70C951F19F9608AE4C812754C7C46AE7A7204B6FCCAD304B4F'){throw 'CONTROL_SCREEN_EVIDENCE_SHA_DRIFT'}
if((Get-FileHash $r).Hash -ne '46BC5AAD1CCE03857787B694AFCBA42F3FE9DC127690EC3243A14F1011D3A15A'){throw 'CONTROL_SCREEN_RECEIPT_SHA_DRIFT'}
if((Get-FileHash $prior).Hash -ne '7147E08D0D69C71F8D7B7F13464A518F8C2D0DD73E34D71CD71ABD79ED1352DA'){throw 'CONTROL_START_RECEIPT_SHA_DRIFT'}
if((Get-FileHash $baselinePhoto).Hash -ne 'A7E7D02C710444858D629DFE9953C7E50B34B42F079AE05E4317B0E4BBC73AFF'){throw 'BASELINE_SCREEN_EVIDENCE_SHA_DRIFT'}
$cap=Get-Content -LiteralPath $r -Raw|ConvertFrom-Json
if($cap.status -ne 'GUEST_VIDEO_FRAME_CAPTURED_VISUAL_REVIEW_PENDING' -or $cap.vm_id -ne 'deb10ab5-3093-47a8-9a13-f3927446c606' -or $cap.control_secureboot -ne 'OFF' -or $cap.baseline_secureboot -ne 'ON'){throw 'CAPTURE_NOT_EXPECTED_CONTROL'}
$guest=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
$baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
if($guest.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $guest.Generation -ne 2 -or [string]$guest.State -ne 'Running'){throw 'CONTROL_ID_OR_STATE_CHANGED'}
if($baseline.Name -ne 'BlueLite-R038-UEFI-Baseline' -or [string]$baseline.State -ne 'Running'){throw 'ORIGINAL_BASELINE_NOT_RUNNING'}
$gf=Get-VMFirmware -VMName $guest.Name -ErrorAction Stop
$bf=Get-VMFirmware -VMName $baseline.Name -ErrorAction Stop
if([string]$gf.SecureBoot -ne 'Off' -or [string]$bf.SecureBoot -ne 'On'){throw 'POLICY_ISOLATION_CHANGED'}
if(@(Get-VM -ErrorAction Stop).Count -ne 2 -or @(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'OTHER_VMS_OR_WIM_MOUNTS'}
$dv=@(Get-VMDvdDrive -VMName $guest.Name)
$source=(Get-Content $prior -Raw|ConvertFrom-Json)
if($dv.Count -ne 1 -or $dv[0].Path -ne $source.dvd_path -or $gf.BootOrder[0].Device.Path -ne $source.dvd_path -or $source.original_ISO_sha_expected -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'GUEST_ORIGINAL_ISO_DRIFT'}
if((Get-Item -LiteralPath $source.dvd_path).Length -ne 6749851648){throw 'SOURCE_ISO_BYTES_DRIFT'}
$freeBefore=[long](Get-PSDrive C).Free
$freeRamBefore=[long](Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory*1024
# This virtual guest contains NO installed Windows; its own firmware error summary was physically screenshot-hashed. TurnOff is a controlled power removal, not a guest Windows shutdown.
Stop-VM -Name $guest.Name -TurnOff -Confirm:$false -ErrorAction Stop
$guest=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if([string]$guest.State -ne 'Off'){throw 'CONTROL_POWER_OFF_POSTCONDITION_FAILED'}
$baseline=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
if([string]$baseline.State -ne 'Running' -or [string](Get-VMFirmware -VMName $baseline.Name).SecureBoot -ne 'On'){throw 'BASELINE_CHANGED_AFTER_STOP'}
$record=[ordered]@{schema='BlueLite.R038.OnlyControlStopAfterEvidence.v1';utc=[datetime]::UtcNow.ToString('o');status='ONLY_CONTROL_GUEST_STOPPED_OFF_AFTER_FIRMWARE_SCREEN_EVIDENCE';script_sha256=(Get-FileHash $PSCommandPath).Hash;control_vm_name=$guest.Name;control_vm_id=$guest.VMId.ToString();control_state_after=[string]$guest.State;control_secureboot=[string](Get-VMFirmware -VMName $guest.Name).SecureBoot;baseline_vm_id=$baseline.VMId.ToString();baseline_state_after=[string]$baseline.State;baseline_secureboot=[string](Get-VMFirmware -VMName $baseline.Name).SecureBoot;control_visual_result='UEFI_SCSI_DVD_BOOT_LOADER_FAILED';baseline_visual_result='UEFI_SCSI_DVD_BOOT_LOADER_FAILED';control_png_sha=(Get-FileHash $p).Hash;control_capture_receipt_sha=(Get-FileHash $r).Hash;baseline_png_sha=(Get-FileHash $baselinePhoto).Hash;source_iso_sha_expected=$source.original_ISO_sha_expected;source_iso_not_modified=$true;guest_vhd_and_snapshots_not_deleted=$true;host_efi_bcd_not_modified=$true;free_ram_before=$freeRamBefore;free_ram_after=[long](Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory*1024;free_c_before=$freeBefore;free_c_after=[long](Get-PSDrive C).Free;guest_first_installed_boot='NOT_RUN';guest_repeat_boot='NOT_RUN'}
$buffer=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$fs=[IO.File]::Open($destination,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$fs.Write($buffer)}finally{$fs.Dispose()}
Write-Output ('R038_OP42_CONTROL_GUEST_STOPPED_PASS id='+$guest.VMId+' state='+$guest.State+' baseline='+$baseline.State+'/SBon RAMbefore='+$freeRamBefore+' RAMafter='+$record.free_ram_after+' fileSHA='+(Get-FileHash $destination).Hash+' FreeC='+$record.free_c_after)
