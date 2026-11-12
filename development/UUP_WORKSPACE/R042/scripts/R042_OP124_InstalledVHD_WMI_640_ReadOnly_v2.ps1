# R042 owner-only first installed Windows .9974 Gen2 actual WMI live video screenshot.
# Uses previous proven Hyper-V CIM RGB565 method; no guest power/firmware/HDD mutations.
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$vmid='7984d165-f71d-4db5-ad13-06f1558dccf3'
$name='BlueLite-R042-FullCMD-9974-Setup-20261111'
$parent='C:\work\_UUP\R042_InstalledBoot_9974_20261112\R042_Installed26300_9974_SourceOwner.vhdx'
$logDir='C:\work\_UUP\R042_InstalledBoot_9974_20261112\BlueLite_Logs'
$png=Join-Path $logDir 'R042_OP124_InstalledVHD_FirstBoot_640x480.png'
$receipt=Join-Path $logDir 'R042_OP124_InstalledVHD_FirstBoot_WMI_Producer.json'
if([IO.File]::Exists($png) -or [IO.File]::Exists($receipt)){throw 'R042_OP124_PNG_OR_RECEIPT_ALREADY_EXISTS'}
$vm=Get-VM -Id $vmid -ErrorAction Stop
$fw=Get-VMFirmware -VMName $name -ErrorAction Stop
$hdd=@(Get-VMHardDiskDrive -VMName $name)
$dvd=@(Get-VMDvdDrive -VMName $name)
if($vm.Name -ne $name -or $vm.Generation -ne 2 -or [string]$vm.State -ne 'Running' -or [string]$fw.SecureBoot -ne 'Off' -or $hdd.Count -ne 1 -or $dvd.Count -ne 1){throw 'NOT_ACTUAL_NEW_RUNNING_INSTALLED_GEN2_VM'}
$child=Get-VHD -Path $hdd[0].Path -ErrorAction Stop
$original=Get-VHD -Path $parent -ErrorAction Stop
$firmwarePaths=@($fw.BootOrder|ForEach-Object{if($_.Device -and $_.Device.PSObject.Properties['Path']){[string]$_.Device.Path}else{''}})
if($child.VhdType.ToString() -ne 'Differencing' -or $child.ParentPath -ne $parent -or $child.DiskIdentifier.ToString() -ne 'EAD9D878-14EA-4E8F-9501-AFEFF4D12FE0' -or $original.DiskIdentifier.ToString() -ne $child.DiskIdentifier.ToString() -or $hdd[0].Path -notin $firmwarePaths){throw 'CHILD_AVHDX_PARENT_AND_FIRMWARE_BOOT_SOURCE_MISMATCH'}
$old1=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
$old2=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if([string]$old1.State -ne 'Running' -or [string]$old2.State -ne 'Running' -or [string](Get-VMFirmware -VMName $old1.Name).SecureBoot -ne 'On'){throw 'ORIGINAL_R038_PROTECTED_VMS_CHANGED'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'HOST_WIM_MOUNT_PRESENT'}
$ns='root/virtualization/v2'
$service=@(Get-CimInstance -Namespace $ns -ClassName Msvm_VirtualSystemManagementService -ErrorAction Stop)
$systems=@(Get-CimInstance -Namespace $ns -ClassName Msvm_ComputerSystem -Filter ('Name='+[char]39+$vmid+[char]39) -ErrorAction Stop)
if($service.Count -ne 1 -or $systems.Count -ne 1){throw 'WMI_VMMS_SERVICE_OR_EXACT_GUEST_NOT_UNIQUE'}
$settings=@(Get-CimAssociatedInstance -InputObject $systems[0] -ResultClassName Msvm_VirtualSystemSettingData -ErrorAction Stop)
$real=@($settings|Where-Object{$_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized'})
if($real.Count -ne 1){throw 'WMI_REALIZED_HYPERV_GUEST_NOT_UNIQUE'}
$w=[int]640
$h=[int]480
$video=@(Get-CimAssociatedInstance -InputObject $systems[0] -ResultClassName Msvm_VideoHead -ErrorAction Stop)
if($video.Count -ne 1 -or [int]$video[0].CurrentHorizontalResolution -lt $w -or [int]$video[0].CurrentVerticalResolution -lt $h){throw 'GUEST_WMI_VIDEO_HEAD_RESOLUTION_UNAVAILABLE'}
$response=Invoke-CimMethod -InputObject $service[0] -MethodName GetVirtualSystemThumbnailImage -Arguments @{TargetSystem=$real[0];WidthPixels=[uint16]$w;HeightPixels=[uint16]$h} -ErrorAction Stop
if([uint32]$response.ReturnValue -ne 0){throw ('WMI_THUMBNAIL_NATIVE_RESULT_'+$response.ReturnValue)}
$raw=[byte[]]$response.ImageData
if($null -eq $raw -or ($raw.Length -ne 614400 -and $raw.Length -ne 614404)){throw 'WMI_RGB565_FRAME_LENGTH_NOT_PROVEN'}
Add-Type -AssemblyName System.Drawing -ErrorAction Stop
$bmp=[System.Drawing.Bitmap]::new($w,$h,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$lock=$null
try{
 $lock=$bmp.LockBits([System.Drawing.Rectangle]::new(0,0,$w,$h),[System.Drawing.Imaging.ImageLockMode]::WriteOnly,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $stride=[int]$lock.Stride
 if($stride -le 0){throw 'WMI_PNG_NEGATIVE_STRIDE'}
 $bytes=[byte[]]::new($stride*$h)
 for($y=0;$y -lt $h;$y++){
  for($x=0;$x -lt $w;$x++){
   $i=($y*$w+$x)*2
   $v565=[int]$raw[$i] -bor ([int]$raw[$i+1] -shl 8)
   $j=$y*$stride+$x*3
   $bytes[$j]=[byte][math]::Round(($v565 -band 31)*255.0/31.0)
   $bytes[$j+1]=[byte][math]::Round((($v565 -shr 5) -band 63)*255.0/63.0)
   $bytes[$j+2]=[byte][math]::Round((($v565 -shr 11) -band 31)*255.0/31.0)
  }
 }
 [Runtime.InteropServices.Marshal]::Copy($bytes,0,$lock.Scan0,$bytes.Length)
 $bmp.UnlockBits($lock)
 $lock=$null
 $bmp.Save($png,[System.Drawing.Imaging.ImageFormat]::Png)
}finally{
 if($null -ne $lock){$bmp.UnlockBits($lock)}
 $bmp.Dispose()
}
$fi=[IO.FileInfo]::new($png)
if(-not $fi.Exists -or $fi.Length -lt 100 -or $fi.Length -gt 10000000){throw 'WMI_FIRST_INSTALLED_PNG_NOT_SAVED'}
$power=Get-Content -LiteralPath 'C:\work\_UUP\R042_PREMAX_Delivery_20261111\R042_OP122_InstalledVHD_FirstPower_Producer.json' -Raw|ConvertFrom-Json
$record=[ordered]@{
 schema='BlueLite.R042.OP124.InstalledOriginal9974FirstBootWmiLiveVideo.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_OP124_FIRST_INSTALLED_ORIGINAL_R042_9974_VM_WMI_RGB565_PNG_CAPTURED_VISUAL_PENDING'
 guestID=$vmid
 guestName=$name
 generation=2
 sourceGuestState='Running'
 secureBoot='Off'
 activeDifferencingChild=$hdd[0].Path
 childParentPath=$child.ParentPath
 parentVHDidentifier=$child.DiskIdentifier.ToString()
 sourceFirmwareBootPaths=$firmwarePaths
 sourceOriginalWindowsWimFullSHA256='61AA38CD52B85962C52E4A8F9D14C4F7C4D0699D9A57446261D26EB723C0AEC2'
 PNGpath=$png
 PNGbytes=$fi.Length
 PNGsha256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash
 PNGwidth=640
 PNGheight=480
 WMIreturnCode=[uint32]$response.ReturnValue
 RGB565byteLength=$raw.Length
 nativeFirstVMstartUTC=$power.startUTC
 visibleInstalledOOBE='PENDING_ASSISTANT_REAL_IMAGE_INSPECTION'
 firstInstalledBootTimeCertified=$false
 oldProtectedR038VMsUnchanged=$true
 noGuestPowerFirmwareOrDiskChanges=$true
}
$buf=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew)
try{$f.Write($buf,0,$buf.Length)}finally{$f.Dispose()}
[pscustomobject]@{status=$record.status;PNGpath=$png;PNGbytes=$fi.Length;PNGsha256=$record.PNGsha256;child=$record.activeDifferencingChild;parent=$record.childParentPath;receiptSHA=(Get-FileHash $receipt -Algorithm SHA256).Hash}|ConvertTo-Json -Depth 6 -Compress
