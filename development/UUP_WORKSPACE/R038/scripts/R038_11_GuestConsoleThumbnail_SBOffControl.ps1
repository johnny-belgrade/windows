# BlueLite R038_11_GuestConsoleThumbnail_SBOffControl.ps1 -- read-only Hyper-V guest video RGB565 -> owned PNG + SHA receipt
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300',[int]$Width=640,[int]$Height=480)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'WRONG_WORKSPACE'}
if($Width -ne 640 -or $Height -ne 480){throw 'ONLY_PREAPPROVED_640x480_CAPTURE'}
$vmid='deb10ab5-3093-47a8-9a13-f3927446c606'
$vmname='BlueLite-R038-UEFI-SBOff-Control'
$logs=Join-Path $Root 'BlueLite_Logs'
$png=Join-Path $logs 'R038_11_SBOffControl_GuestVideo_640x480.png'
$receipt=Join-Path $logs 'R038_11_GuestVideoCapture_Result.json'
if((Test-Path $png) -or (Test-Path $receipt)){throw 'GUEST_FRAME_ALREADY_CAPTURED_NOT_OVERWRITING'}
$startPath=Join-Path $logs 'R038_10_Start_SBOffControl.json'
$priorPath=Join-Path $logs 'R038_10_SetSecureBootOff_SBOffControl.json'
if((Get-FileHash $startPath).Hash -ne '7147E08D0D69C71F8D7B7F13464A518F8C2D0DD73E34D71CD71ABD79ED1352DA'){throw 'START_RECEIPT_SHA_DRIFT'}
if((Get-FileHash $priorPath).Hash -ne 'D58D3D7E4932A19079A7BE2CA92BF040BB58523434EF84CB30590F5D7BFB64F1'){throw 'CONTROL_POLICY_RECEIPT_SHA_DRIFT'}
$v=Get-VM -Id $vmid -ErrorAction Stop
if($v.Name -ne $vmname -or $v.Generation -ne 2 -or [string]$v.State -ne 'Running'){throw 'EXACT_GUEST_NOT_RUNNING'}
$fw=Get-VMFirmware -VMName $vmname -ErrorAction Stop
if([string]$fw.SecureBoot -ne 'Off'){throw 'CONTROL_GUEST_POLICY_MUST_BE_OFF'}
$base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or [string]$base.State -ne 'Running' -or [string](Get-VMFirmware -VMName $base.Name).SecureBoot -ne 'On'){throw 'BASELINE_MUST_REMAIN_RUNNING_SBON'}
if(@(Get-VM).Count -ne 2){throw 'OTHER_VM_PRESENT'}

if(@(Get-WindowsImage -Mounted).Count -ne 0){throw 'HOST_HAS_MOUNTED_WIM'}
$dvd=@(Get-VMDvdDrive -VMName $vmname -ErrorAction Stop)
if($dvd.Count -ne 1){throw 'GUEST_ORIGINAL_DVD_COUNT'}
$record=Get-Content $startPath -Raw|ConvertFrom-Json
if($dvd[0].Path -ne $record.dvd_path -or $record.original_ISO_sha_expected -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'SOURCE_ISO_ID_DRIFT'}
$pol=Get-Content $priorPath -Raw|ConvertFrom-Json
if($pol.status -ne 'CONTROL_VM_SECUREBOOT_OFF_GUEST_OFF_NO_BOOT' -or $record.status -ne 'CONTROL_GUEST_POWERED_ON_SETUP_UI_NOT_YET_OBSERVED' -or $record.vm_id -ne $vmid -or $pol.vm_id -ne $vmid){throw 'CONTROL_SOURCE_RECEIPT_STATUS_VM_ID'}
if((Get-VMFirmware -VMName $vmname).BootOrder[0].Device.Path -ne $record.dvd_path){throw 'CONTROL_GUEST_DVD_NOT_FIRST'}

if((Get-Item $dvd[0].Path).Length -ne 6749851648){throw 'ISO_BYTES_DRIFT'}
$ns='root/virtualization/v2'
$services=@(Get-CimInstance -Namespace $ns -ClassName Msvm_VirtualSystemManagementService -ErrorAction Stop)
if($services.Count -ne 1){throw 'VMMS_WMI_SERVICE_NOT_UNIQUE'}
$names=@($services[0].CimClass.CimClassMethods|ForEach-Object {$_.Name})
if(@($names|Where-Object {$_ -eq 'GetVirtualSystemThumbnailImage'}).Count -ne 1){throw 'THUMBNAIL_METHOD_NOT_EXPOSED'}
$vm=@(Get-CimInstance -Namespace $ns -ClassName Msvm_ComputerSystem -Filter "Name='$vmid'" -ErrorAction Stop)
if($vm.Count -ne 1){throw 'WMI_VM_ID_DRIFT'}
$allSettings=@(Get-CimAssociatedInstance -InputObject $vm[0] -ResultClassName Msvm_VirtualSystemSettingData -ErrorAction Stop)
$current=@($allSettings|Where-Object {$_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized'})
if($current.Count -ne 1){throw 'WRONG_OR_MULTIPLE_REALIZED_GUEST_SETTINGS'}
$expectedInstance='MICROSOFT:'+$vmid.ToUpperInvariant()
if($current[0].InstanceID.ToUpperInvariant() -ne $expectedInstance){throw 'REALIZED_VM_CONFIG_ID_CHANGED'}
$video=@(Get-CimAssociatedInstance -InputObject $vm[0] -ResultClassName Msvm_VideoHead -ErrorAction Stop)
if($video.Count -ne 1 -or [int]$video[0].CurrentHorizontalResolution -lt $Width -or [int]$video[0].CurrentVerticalResolution -lt $Height){throw 'VIDEO_HEAD_RESOLUTION_UNSUPPORTED'}
$response=Invoke-CimMethod -InputObject $services[0] -MethodName GetVirtualSystemThumbnailImage -Arguments @{
 TargetSystem=$current[0]
 WidthPixels=[uint16]$Width
 HeightPixels=[uint16]$Height
} -ErrorAction Stop
if([uint32]$response.ReturnValue -ne 0){throw ('WMI_THUMBNAIL_RESULT_'+[uint32]$response.ReturnValue)}
$raw=[byte[]]$response.ImageData
$pixelBytes=$Width*$Height*2
if($null -eq $raw -or ($raw.Length -ne $pixelBytes -and $raw.Length -ne ($pixelBytes+4))){throw ('RGB565_FRAME_BYTE_LENGTH_'+$(if($null -eq $raw){-1}else{$raw.Length}))}
$ignoredTrailingBytes=$raw.Length-$pixelBytes
# Hyper-V WMI returns exactly four extra bytes on this native host (614404 for 640x480). Only the first W*H*2 bytes are pixel input.
Add-Type -AssemblyName System.Drawing -ErrorAction Stop
$bitmap=[System.Drawing.Bitmap]::new($Width,$Height,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$lock=$null
try {
 $rect=[System.Drawing.Rectangle]::new(0,0,$Width,$Height)
 $lock=$bitmap.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::WriteOnly,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $stride=[int]$lock.Stride
 if($stride -le 0){throw 'UNEXPECTED_NEGATIVE_PNG_STRIDE'}
 $rgb=[byte[]]::new($stride*$Height)
 for($y=0;$y -lt $Height;$y++){
  for($x=0;$x -lt $Width;$x++){
   $i=($y*$Width+$x)*2
   $v565=[int]$raw[$i] -bor ([int]$raw[$i+1] -shl 8)
   $off=$y*$stride+$x*3
   $r5=($v565 -shr 11) -band 31
   $g6=($v565 -shr 5) -band 63
   $b5=$v565 -band 31
   $rgb[$off]=[byte][math]::Round($b5*255.0/31.0)
   $rgb[$off+1]=[byte][math]::Round($g6*255.0/63.0)
   $rgb[$off+2]=[byte][math]::Round($r5*255.0/31.0)
  }
 }
 [System.Runtime.InteropServices.Marshal]::Copy($rgb,0,$lock.Scan0,$rgb.Length)
 $bitmap.UnlockBits($lock);$lock=$null
 $bitmap.Save($png,[System.Drawing.Imaging.ImageFormat]::Png)
}finally{
 if($null -ne $lock){$bitmap.UnlockBits($lock)}
 $bitmap.Dispose()
}
$fi=Get-Item -LiteralPath $png -ErrorAction Stop
if($fi.Length -lt 100 -or $fi.Length -gt 10000000){throw 'PNG_SIZE_OUT_OF_RANGE'}
$hb=@(Get-VMIntegrationService -VMName $vmname|Where-Object Name -eq 'Heartbeat')
$payload=[ordered]@{schema='BlueLite.R038.HyperVControlThumbnail.v1';utc=[datetime]::UtcNow.ToString('o');status='GUEST_VIDEO_FRAME_CAPTURED_VISUAL_REVIEW_PENDING';script_sha256=(Get-FileHash $PSCommandPath).Hash;vm_id=$vmid;vm_name=$vmname;vm_generation=2;vm_state='Running';vm_snapshot_reference_count=@($allSettings|Where-Object{$_.VirtualSystemType -like '*Snapshot*'}).Count;wmi_current_vm_setting_instance=$current[0].InstanceID;wmi_return_code=[uint32]$response.ReturnValue;source_video_width=[int]$video[0].CurrentHorizontalResolution;source_video_height=[int]$video[0].CurrentVerticalResolution;requested_width=$Width;requested_height=$Height;raw_rgb565_bytes=$raw.Length;rgb565_pixel_bytes_used=$pixelBytes;wmi_trailing_padding_ignored=$ignoredTrailingBytes;wmi_trailing_padding_hex=$(if($ignoredTrailingBytes -gt 0){[BitConverter]::ToString($raw,$pixelBytes,$ignoredTrailingBytes)}else{$null});png_path=$png;png_bytes=$fi.Length;png_sha256=(Get-FileHash $png).Hash;heartbeat_status=$(if($hb.Count){$hb[0].PrimaryStatusDescription}else{'UNAVAILABLE'});start_receipt_sha=(Get-FileHash $startPath).Hash;prior_control_policy_receipt_sha=(Get-FileHash $priorPath).Hash;source_iso_sha_expected=$record.original_ISO_sha_expected;control_secureboot='OFF';baseline_secureboot='ON';guest_setup_UI='PENDING_INDEPENDENT_VISUAL_REVIEW';first_installed_OS_boot='NOT_RUN';repeat_OS_boot='NOT_RUN';host_image_mutated=$false;host_BCD_EFI_mutated=$false;free_c=[long](Get-PSDrive C).Free}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($payload|ConvertTo-Json -Depth 7)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes)}finally{$f.Dispose()}
Write-Output ('R038_OP40_CONTROL_GUEST_FRAME_RGB565_CAPTURED_WMI_PASS pngSha='+$payload.png_sha256+' pngBytes='+$payload.png_bytes+' pixels='+$Width+'x'+$Height+' receiptSha='+(Get-FileHash $receipt).Hash+' setupUI=PENDING_INDEPENDENT_VISUAL_REVIEW')
