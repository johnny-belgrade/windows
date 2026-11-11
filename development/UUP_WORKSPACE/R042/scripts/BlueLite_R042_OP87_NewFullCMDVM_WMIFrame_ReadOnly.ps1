# R042 QA-only NEW full PRE_MAX CMD media A391 ISO Hyper-V Gen2 WMI RGB565 live frame.
# Only new owned VM GUID 7984d165; NEVER run original R042 old protected control screenshot source on the new ISO.
[CmdletBinding()]
param([int]$Width=640,[int]$Height=480)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
$vmid='7984d165-f71d-4db5-ad13-06f1558dccf3'
$vmname='BlueLite-R042-FullCMD-9974-Setup-20261111'
$baselineName='BlueLite-R038-UEFI-Baseline'
$controlName='BlueLite-R038-UEFI-SBOff-Control'
$expectedISO='C:\work\_UUP\R042_FULL_ONECMD_9974_20261111\BlueLite_NoPrompt\26300.9974.261109-0904.26H2_GE_RELEASE_SVC_PROD1_CLIENTPRO_OEMRET_X64FRE_EN-US.BlueLite.NoPrompt.TEST.iso'
$expectedSHA='A3913F0133A0195622D3CA4FD89DDA1C2591E527C0FF46C3C777BBA76872E9BA'
$devRoot='C:\work\_UUP\R042_PREMAX_Delivery_20261111'
$logRoot='C:\work\_UUP\R042_VM_FullCMD_9974_Setup_20261111\BlueLite_Logs'
$png=Join-Path $logRoot 'R042_OP87_NewFullCMDVM_GuestVideo_640x480.png'
$receipt=Join-Path $logRoot 'R042_OP87_NewFullCMDVM_GuestVideoReceipt.json'
if($Width -ne 640 -or $Height -ne 480){throw 'ONLY_640X480_PROVEN_VIDEO_METHOD'}
if([IO.File]::Exists($png) -or [IO.File]::Exists($receipt)){throw 'NEW_GUEST_VIDEO_RECEIPT_OR_PNG_EXISTS_NO_OVERWRITE'}
[void][IO.Directory]::CreateDirectory($logRoot)
$record=[ordered]@{
 schema='BlueLite.R042.OP87.NewExactFullCMDGen2LiveWMIPixelFrame.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='R042_OP87_NEW_VM_WMI_VIDEO_DEPENDENCY_HOLD'
 error=''
 expectedVMname=$vmname
 expectedVMID=$vmid
 capturedOriginalISO=$expectedISO
 originalSourceFullISOExpectedSHA256=$expectedSHA
 sourcePNG=$png
 pngBytes=0
 pngSHA256=''
 pngWidth=$Width
 pngHeight=$Height
 actualWin11SetupUI='PENDING_INDEPENDENT_VISUAL_REVIEW'
 installedWindowsFirstBoot='NOT_RUN'
 bootSpeed='NOT_MEASURED'
 noVmPowerOrFirmwareChanged=$true
 protectedOriginalR038BaselineUnchanged=$false
}
try {
 $sourceProof=Join-Path $devRoot 'R042_OP85_NewGen2_FirstPowerOn_IndependentVerify.json'
 $mediaProof=Join-Path $devRoot 'R042_OP81_NewVM_ExactDVD_IndependentVerify.json'
 $bootProof=Join-Path $devRoot 'R042_OP83_NewVM_DVDFirstBoot_IndependentVerify.json'
 foreach($f in @($sourceProof,$mediaProof,$bootProof)){if(-not [IO.File]::Exists($f)){throw ('MISSING_PRIOR_SOURCE_VERIFIED_RECEIPT_'+$f)}}
 $p=Get-Content -LiteralPath $sourceProof -Raw -Encoding UTF8|ConvertFrom-Json
 $m=Get-Content -LiteralPath $mediaProof -Raw -Encoding UTF8|ConvertFrom-Json
 $boot=Get-Content -LiteralPath $bootProof -Raw -Encoding UTF8|ConvertFrom-Json
 if($p.status -ne 'R042_OP85_NEW_ORIGINAL_A391_ISO_GEN2_SBOFF_VM_RUNNING_SECOND_NATIVE_POWER_QA_PASS_UI_NOT_YET_PROVEN' -or $m.status -ne 'R042_OP81_ONLY_NEW_GEN2_SBOFF_OFF_EXACT_A391_ISO_FULL_SHA_DVD_SECOND_NATIVE_PASS' -or $boot.status -ne 'R042_OP83_NEW_GEN2_SBOFF_OFF_EXACT_A391_DVD_FIRST_INDEPENDENT_NATIVE_PASS'){throw 'INDEPENDENT_ORIGINAL_POWER_DVD_FIRMWARE_SOURCE_NOT_PASS'}
 if($p.vmID -ne $vmid -or $m.isoFullSHA256 -ne $expectedSHA -or $boot.bootFirstDVDSource -ne $expectedISO){throw 'ORIGINAL_POWER_ISO_SHA_GUID_MISMATCH'}
 $v=Get-VM -Id $vmid -ErrorAction Stop
 $b=Get-VM -Name $baselineName -ErrorAction Stop
 $control=Get-VM -Name $controlName -ErrorAction Stop
 if($v.Name -ne $vmname -or [int]$v.Generation -ne 2 -or [string]$v.State -ne 'Running'){throw 'EXACT_NEW_GUEST_NOT_RUNNING_GEN2'}
 if([string]$b.Id -ne 'c7536cc4-68f5-473a-9818-4053ba8794b2' -or [string]$b.State -ne 'Running' -or [string]$control.Id -ne 'deb10ab5-3093-47a8-9a13-f3927446c606' -or [string]$control.State -ne 'Running'){throw 'ORIGINAL_R038_PROTECTED_VM_CHANGED'}
 $fw=Get-VMFirmware -VMName $vmname -ErrorAction Stop
 $baseFw=Get-VMFirmware -VMName $baselineName -ErrorAction Stop
 $controlFw=Get-VMFirmware -VMName $controlName -ErrorAction Stop
 if([string]$fw.SecureBoot -ne 'Off' -or [string]$baseFw.SecureBoot -ne 'On' -or [string]$controlFw.SecureBoot -ne 'Off'){throw 'HYPERV_SOURCE_BOOT_POLICY_CHANGED'}
 $dvd=@(Get-VMDvdDrive -VMName $vmname)
 if($dvd.Count -ne 1 -or $dvd[0].Path -ne $expectedISO -or [string]$fw.BootOrder[0].Device.Path -ne $expectedISO){throw 'NEW_GUEST_DVD_NOT_EXACT_A391_FIRST'}
 $fi=[IO.FileInfo]::new($dvd[0].Path)
 if(-not $fi.Exists -or $fi.Length -ne 6686275584){throw 'FULL_SOURCE_DVD_FILE_SIZE_NOT_A391_CANDIDATE'}
 if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count){throw 'HOST_WIM_MOUNT_PRESENT'}
 $ns='root/virtualization/v2'
 $services=@(Get-CimInstance -Namespace $ns -ClassName Msvm_VirtualSystemManagementService -ErrorAction Stop)
 if($services.Count -ne 1){throw 'VMM_WMI_SERVICE_CARDINALITY'}
 if(@($services[0].CimClass.CimClassMethods|Where-Object{$_.Name -eq 'GetVirtualSystemThumbnailImage'}).Count -ne 1){throw 'HYPERV_WMI_THUMBNAIL_METHOD_MISSING'}
 $sys=@(Get-CimInstance -Namespace $ns -ClassName Msvm_ComputerSystem -Filter ("Name='"+$vmid+"'") -ErrorAction Stop)
 if($sys.Count -ne 1){throw 'WMI_GUEST_VM_GUID_NOT_FOUND'}
 $settings=@(Get-CimAssociatedInstance -InputObject $sys[0] -ResultClassName Msvm_VirtualSystemSettingData -ErrorAction Stop)
 $real=@($settings|Where-Object{$_.VirtualSystemType -eq 'Microsoft:Hyper-V:System:Realized'})
 if($real.Count -ne 1){throw 'WMI_REALIZED_GUEST_SETTING_NOT_UNIQUE'}
 if($real[0].InstanceID.ToUpperInvariant() -ne ('MICROSOFT:'+$vmid.ToUpperInvariant())){throw 'WMI_GUEST_REALIZED_CONFIG_ID_CHANGED'}
 $video=@(Get-CimAssociatedInstance -InputObject $sys[0] -ResultClassName Msvm_VideoHead -ErrorAction Stop)
 if($video.Count -ne 1 -or [int]$video[0].CurrentHorizontalResolution -lt $Width -or [int]$video[0].CurrentVerticalResolution -lt $Height){throw 'WMI_VIDEO_RESOLUTION_NOT_READY'}
 $response=Invoke-CimMethod -InputObject $services[0] -MethodName GetVirtualSystemThumbnailImage -Arguments @{
  TargetSystem=$real[0]
  WidthPixels=[uint16]$Width
  HeightPixels=[uint16]$Height
 } -ErrorAction Stop
 if([uint32]$response.ReturnValue -ne 0){throw ('WMI_THUMBNAIL_NATIVE_ERROR_'+[uint32]$response.ReturnValue)}
 $raw=[byte[]]$response.ImageData
 $pixelBytes=$Width*$Height*2
 if($null -eq $raw -or ($raw.Length -ne $pixelBytes -and $raw.Length -ne ($pixelBytes+4))){throw 'WMI_RGB565_EXPECTED_PIXEL_BYTES_OR_FOUR_PADDING'}
 Add-Type -AssemblyName System.Drawing -ErrorAction Stop
 $bitmap=[System.Drawing.Bitmap]::new($Width,$Height,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
 $lock=$null
 try {
  $rect=[System.Drawing.Rectangle]::new(0,0,$Width,$Height)
  $lock=$bitmap.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::WriteOnly,[System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $stride=[int]$lock.Stride
  if($stride -le 0){throw 'WMI_BITMAP_NEGATIVE_STRIDE'}
  $rgb=[byte[]]::new($stride*$Height)
  for($y=0;$y -lt $Height;$y++){
   for($x=0;$x -lt $Width;$x++){
    $i=($y*$Width+$x)*2
    $v565=[int]$raw[$i] -bor ([int]$raw[$i+1] -shl 8)
    $off=$y*$stride+$x*3
    $rgb[$off]=[byte][math]::Round(($v565 -band 31)*255.0/31.0)
    $rgb[$off+1]=[byte][math]::Round((($v565 -shr 5) -band 63)*255.0/63.0)
    $rgb[$off+2]=[byte][math]::Round((($v565 -shr 11) -band 31)*255.0/31.0)
   }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($rgb,0,$lock.Scan0,$rgb.Length)
  $bitmap.UnlockBits($lock);$lock=$null
  $bitmap.Save($png,[System.Drawing.Imaging.ImageFormat]::Png)
 }finally{
  if($null -ne $lock){$bitmap.UnlockBits($lock)}
  $bitmap.Dispose()
 }
 $f=[IO.FileInfo]::new($png)
 if(-not $f.Exists -or $f.Length -lt 100 -or $f.Length -gt 10000000){throw 'PNG_NOT_CREATED_OR_INVALID_SIZE'}
 $record.status='R042_OP87_NEW_EXACT_A391_VM_WMI_RGB565_PNG_CAPTURED_VISUAL_PENDING'
 $record.actualGuestVMstate=[string]$v.State
 $record.actualGuestVMgeneration=[int]$v.Generation
 $record.actualGuestSecureBoot=[string]$fw.SecureBoot
 $record.actualFirstBootDVD=$dvd[0].Path
 $record.capturedPNGWidth=$Width
 $record.capturedPNGHeight=$Height
 $record.wmiReturnCode=[uint32]$response.ReturnValue
 $record.wmiVideoCurrentWidth=[int]$video[0].CurrentHorizontalResolution
 $record.wmiVideoCurrentHeight=[int]$video[0].CurrentVerticalResolution
 $record.rawRgb565FrameBytes=$raw.Length
 $record.pixelsByteCount=$pixelBytes
 $record.fourPaddingBytesIgnored=$raw.Length-$pixelBytes
 $record.pngBytes=$f.Length
 $record.pngSHA256=(Get-FileHash -LiteralPath $png -Algorithm SHA256).Hash
 $record.scriptFullSHA256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 $record.previousPowerNativeSecondReceiptSHA256=(Get-FileHash $sourceProof -Algorithm SHA256).Hash
 $record.mediaIndependentSourceReceiptSHA256=(Get-FileHash $mediaProof -Algorithm SHA256).Hash
 $record.protectedOriginalR038BaselineUnchanged=$true
 $record.actualWin11SetupUI='PENDING_INDEPENDENT_VISUAL_REVIEW'
}catch{
 $record.error=$_.Exception.Message
}
$record.utcEnd=[DateTime]::UtcNow.ToString('o')
$data=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($data,0,$data.Length)}finally{$f.Dispose()}
[pscustomobject]@{status=$record.status;error=$record.error;guest=$vmname;guestID=$vmid;sourceISO=$expectedSHA;png=$png;pngBytes=$record.pngBytes;pngSHA256=$record.pngSHA256;realVideoWMI=$record.wmiReturnCode;actualSetupUI=$record.actualWin11SetupUI;receiptSHA256=(Get-FileHash $receipt -Algorithm SHA256).Hash}|ConvertTo-Json -Compress -Depth 6
if($record.status -ne 'R042_OP87_NEW_EXACT_A391_VM_WMI_RGB565_PNG_CAPTURED_VISUAL_PENDING'){exit 17}
