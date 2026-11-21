# R055 OP02 FRESH distinct PS7 verifier for single Windows Photos source-specific AppX post-state.
[CmdletBinding()]param(
 [Parameter(Mandatory=$true)][string]$Mount,
 [Parameter(Mandatory=$true)][string]$NativeReceipt,
 [Parameter(Mandatory=$true)][string]$QAReceipt
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Mount -cne 'C:\work\_UUP\temp\R055M56\m'){throw 'OP02_UNEXPECTED_MOUNT_ROOT'}
if(-not [IO.File]::Exists($NativeReceipt) -or [IO.File]::Exists($QAReceipt)){throw 'OP02_NATIVE_RECEIPT_MISSING_OR_QA_ALREADY_EXISTS'}
$n=Get-Content $NativeReceipt -Raw|ConvertFrom-Json -Depth 13
if($n.Schema -cne 'BlueLite.R055.OP02.OneExactPhotosNativeRemoval.v1' -or $n.NativeStatus -cne 'NATIVE_REMOVE_PROVISIONED_PHOTOS_COMPLETED' -or $n.ExactPhotosPackageName -cne 'Microsoft.Windows.Photos_2024.401.617.0_neutral_~_8wekyb3d8bbwe'){throw 'NOT_EXACT_GENUINE_PHOTOS_REMOVE_REPORT'}
if(@($n.BeforeAppx).Count -ne 10){throw 'SOURCE_SELECTED_STAGING_APPS_NOT_10'}
$after=@(Get-AppxProvisionedPackage -Path $Mount -ErrorAction Stop)
if($after.Count -ne 9 -or @($after|Where-Object {$_.DisplayName -eq 'Microsoft.Windows.Photos'}).Count -ne 0){throw ('PHOTOS_NOT_REMOVED_OR_OTHER_APPX_REMOVED_ACTUAL_COUNT_'+$after.Count)}
$beforeOther=@($n.BeforeAppx |Where-Object {$_.DisplayName -ne 'Microsoft.Windows.Photos'})
foreach($b in $beforeOther){
 $match=@($after|Where-Object {$_.DisplayName -ceq $b.DisplayName -and $_.PackageName -ceq $b.PackageName})
 if($match.Count -ne 1){throw ('OLD_PROTECTED_OR_OTHER_APPX_CHANGED '+$b.DisplayName)}
}
foreach($name in @('Microsoft.SecHealthUI','Microsoft.DesktopAppInstaller','Microsoft.WindowsCalculator','Microsoft.WindowsNotepad','Microsoft.NET.Native.Framework.2.2','Microsoft.NET.Native.Runtime.2.2','Microsoft.UI.Xaml.2.8','Microsoft.VCLibs.140.00.UWPDesktop','Microsoft.VCLibs.140.00')){
 if(@($after|Where-Object {$_.DisplayName -ceq $name}).Count -ne 1){throw ('PROTECTED_APPX_DETECTED_MISSING '+$name)}
}
$caps=@(Get-WindowsCapability -Path $Mount -ErrorAction Stop)
$ethernet=@($caps|Where-Object{$_.Name -match '^Microsoft\.Windows\.Ethernet\.Client\.' -and [string]$_.State -eq 'Installed'})
$wifi=@($caps|Where-Object{$_.Name -match '^Microsoft\.Windows\.Wifi\.Client\.' -and [string]$_.State -eq 'Installed'})
if($ethernet.Count -ne 4 -or $wifi.Count -ne 0){throw ('NETWORK_FOD_UNEXPECTED_ETHERNET_'+$ethernet.Count+'_WIFI_'+$wifi.Count)}
$qa=[ordered]@{
 Schema='BlueLite.R055.OP02.PhotosRemovedFreshIndependentPostStateQA.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 NativeReceiptSHA=(Get-FileHash $NativeReceipt).Hash
 ExactRemoved='Microsoft.Windows.Photos_2024.401.617.0_neutral_~_8wekyb3d8bbwe'
 RealOriginalAppxCount=10;ActualAfterAppxCount=$after.Count;OtherNinePackageIdentityExact=$true
 OriginalNineProtectedSecHealthAppInstallerFrameworksCalcNotepad=$true
 OriginalWiFi23AlreadyAbsent=$true;FourEthernetInstalled=$true
 Status='TRUE_FRESH_PSH7_NATIVE_POST_PHOTOS_ONLY_REMOVED_VALIDATED'
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($qa|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
$f=[IO.File]::Open($QAReceipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
Write-Host ('R055_OP02_FRESH_PHOTOS_POST_STATE_PASS SEC_HEALTH_APPINSTALLER_FRAMEWORKS_PRESERVED ETH4 QA_SHA='+(Get-FileHash $QAReceipt).Hash)
