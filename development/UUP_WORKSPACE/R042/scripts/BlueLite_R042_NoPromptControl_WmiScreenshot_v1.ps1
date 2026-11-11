# R042 isolated Gen2 control WMI native guest frame capture, source-adapted from SHA-known R038 07 v1.1.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$CycleRoot,
 [int]$Width=640,
 [int]$Height=480
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$root=[IO.Path]::GetFullPath($CycleRoot).TrimEnd([char]92,[char]47)
if($root -ne 'C:\work\_UUP\R042_NoPromptISO_9974_20261111'){throw 'TEST_CYCLE_ROOT_NOT_PROVEN'}
if($Width -ne 640 -or $Height -ne 480){throw 'ONLY_PROVEN_640x480_CAPTURE'}
$vmid='deb10ab5-3093-47a8-9a13-f3927446c606'
$vmname='BlueLite-R038-UEFI-SBOff-Control'
$baselineName='BlueLite-R038-UEFI-Baseline'
$logs=Join-Path $root 'BlueLite_Logs'
$png=Join-Path $logs 'R042_OP14_Control_GuestVideo_640x480.png'
$receipt=Join-Path $logs 'R042_OP14_Control_GuestVideoReceipt.json'
if([IO.File]::Exists($png) -or [IO.File]::Exists($receipt)){throw 'FRAME_ALREADY_CAPTURED_NO_OVERWRITE'}
$priorPath=Join-Path $logs 'R042_OP12_Gen2Control_Start_Producer.json'
$indPath=Join-Path $logs 'R042_OP12_Gen2Control_Start_IndependentVerify.json'
$mediaProof=Join-Path $logs 'R042_NoPromptISO_IndependentVerify.json'
foreach($f in @($priorPath,$indPath,$mediaProof)){if(-not [IO.File]::Exists($f)){throw ('MISSING_PREVIOUS_NATIVE_PROOF_'+$f)}}
$startProof=Get-Content -LiteralPath $priorPath -Raw -Encoding UTF8|ConvertFrom-Json
$ind=Get-Content -LiteralPath $indPath -Raw -Encoding UTF8|ConvertFrom-Json
$media=Get-Content -LiteralPath $mediaProof -Raw -Encoding UTF8|ConvertFrom-Json
if($startProof.status -ne 'R042_GEN2_CONTROL_VM_POWER_ON_PASS_BOOT_UI_NOT_YET_VERIFIED' -or $ind.status -ne 'R042_GEN2_NO_PROMPT_TEST_VM_POWERON_INDEPENDENT_PASS_SETUP_SCREEN_NOT_CHECKED' -or $media.status -ne 'DERIVED_ISO_FULLSHA_OUTSIDE_PATCH_IDENTICAL_SAME_SOURCE_NOPROMPT_AND_UDF_CRC_PASS'){throw 'CURRENT_VM_MEDIA_PROOF_NOT_PASS'}
$v=Get-VM -Id $vmid -ErrorAction Stop
$baseline=Get-VM -Name $baselineName -ErrorAction Stop
if($v.Name -ne $vmname -or $v.Generation -ne 2 -or [string]$v.State -ne 'Running' -or [string]$baseline.Id -ne 'c7536cc4-68f5-473a-9818-4053ba8794b2' -or [string]$baseline.State -ne 'Running'){throw 'EXPECTED_TEST_AND_BASELINE_VMS_NOT_RUNNING'}
$fw=Get-VMFirmware -VMName $vmname
$baseFw=Get-VMFirmware -VMName $baselineName
if([string]$fw.SecureBoot -ne 'Off' -or [string]$baseFw.SecureBoot -ne 'On'){throw 'VM_SECUREBOOT_TOPOLOGY_CHANGED'}
$dvd=@(Get-VMDvdDrive -VMName $vmname)
$bdvd=@(Get-VMDvdDrive -VMName $baselineName)
if($dvd.Count -ne 1 -or $bdvd.Count -ne 1 -or $dvd[0].Path -ne $media.derivedISO -or $fw.BootOrder[0].Device.Path -ne $media.derivedISO -or $bdvd[0].Path -ne $startProof.baselineISO){throw 'TEST_OR_BASELINE_VIRTUAL_DVD_CHANGED'}
if([IO.FileInfo]::new([string]$dvd[0].Path).Length -ne [long]$media.isoBytes){throw 'TEST_DVD_SOURCE_SIZE_CHANGED'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'HOST_WIM_MOUNT_ACTIVE'}
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
$payload=[ordered]@{
 schema='BlueLite.R042.ControlGen2NoPromptWmiFrame.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_GEN2_CONTROL_GUEST_VIDEO_CAPTURED_ACTUAL_VISUAL_REVIEW_PENDING'
 scriptSha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 vmId=$vmid
 vmName=$vmname
 vmGeneration=2
 vmState='Running'
 secureBoot='Off'
 vmSnapshotReferenceCount=@($allSettings|Where-Object{$_.VirtualSystemType -like '*Snapshot*'}).Count
 wmiRealizedSettingInstance=$current[0].InstanceID
 wmiReturnCode=[uint32]$response.ReturnValue
 currentVideoWidth=[int]$video[0].CurrentHorizontalResolution
 currentVideoHeight=[int]$video[0].CurrentVerticalResolution
 capturedWidth=$Width
 capturedHeight=$Height
 rawRgb565Bytes=$raw.Length
 pixelBytesUsed=$pixelBytes
 trailingPaddingIgnored=$ignoredTrailingBytes
 pngPath=$png
 pngBytes=$fi.Length
 pngSHA256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash
 attachedISO=$dvd[0].Path
 expectedAttachedISOSHA256=$media.derivedISOSHA256
 sourceMediaVerifyReceiptSHA256=(Get-FileHash -LiteralPath $mediaProof -Algorithm SHA256).Hash
 originalPowerReceiptSHA256=(Get-FileHash -LiteralPath $priorPath -Algorithm SHA256).Hash
 independentPowerReceiptSHA256=(Get-FileHash -LiteralPath $indPath -Algorithm SHA256).Hash
 baselineProtectedVM=$baselineName
 baselineProtectedVMState='Running'
 baselineProtectedDVD=$bdvd[0].Path
 actualVisibleSetupUI='PENDING_HUMAN_IMAGE_VISUAL_REVIEW'
 firstInstalledBoot='NOT_RUN'
 repeatedWindowsBoot='NOT_RUN'
 hostBootChanged=$false
 guestPowerChangedByCapture=$false
 zeroHostMounts=$true
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($payload|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {$f.Write($bytes,0,$bytes.Length)} finally {$f.Dispose()}
Write-Output ('R042_CONTROL_WMI_FRAME_CAPTURE_PASS PNG='+$png+' SHA256='+$payload.pngSHA256+' BYTES='+$payload.pngBytes+' WMI='+$payload.wmiReturnCode+' ACTUAL_UI_PENDING_REVIEW')
exit 0
