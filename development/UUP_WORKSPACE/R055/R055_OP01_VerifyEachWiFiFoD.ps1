# R055 one single WIFi CAP fresh-process verify; run only on new owned offline mount after native DISM Exit0.
[CmdletBinding()]param(
 [Parameter(Mandatory=$true)][string]$Mount,
 [Parameter(Mandatory=$true)][string]$CapabilityName,
 [Parameter(Mandatory=$true)][string]$NativeReceiptPath,
 [Parameter(Mandatory=$true)][string]$IndependentQAPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Mount -cne 'C:\work\_UUP\temp\R055M55\m'){throw 'WRONG_MOUNT_SCOPE'}
if($CapabilityName -notmatch '^Microsoft\.Windows\.Wifi\.Client\.[A-Za-z0-9.]+~~~~0\.0\.1\.0$'){throw 'NOT_AN_EXACT_WIFI_DRIVER_CAPABILITY'}
if(-not [IO.File]::Exists($NativeReceiptPath) -or [IO.File]::Exists($IndependentQAPath)){throw 'MISSING_NATIVE_RECEIPT_OR_QA_COLLISION'}
$n=Get-Content $NativeReceiptPath -Raw|ConvertFrom-Json -Depth 10
if($n.Schema -cne 'BlueLite.R055.OP01.OneNativeWifiFoDRemoval.v1' -or $n.Name -cne $CapabilityName -or $n.NativeDismExit -ne 0){throw 'NATIVE_WIFI_REMOVAL_NOT_EXIT0_OR_WRONG_IDENTITY'}
if((Get-FileHash $n.StdoutPath).Hash -ne $n.StdoutSHA256){throw 'NATIVE_DISM_STDOUT_CHANGED'}
$cap=@(Get-WindowsCapability -Path $Mount -Name $CapabilityName -ErrorAction Stop)
if($cap.Count -ne 1 -or $cap[0].Name -cne $CapabilityName -or [string]$cap[0].State -ne 'NotPresent'){throw ('NATIVE_WIFI_AFTER_STATE_NOTPRESENT_HOLD '+@($cap|ForEach-Object{"$($_.Name)=$($_.State)"}) -join ',')}
# Protect four physical vendor ethernet capabilities while removing Wi-Fi; they remain installed for network fallback.
$ethernet=@(Get-WindowsCapability -Path $Mount -ErrorAction Stop|Where-Object{$_.Name -match '^Microsoft\.Windows\.Ethernet\.Client\.' -and [string]$_.State -eq 'Installed'})
if($ethernet.Count -ne 4){throw ('ETHERNET_CAPABILITY_FLOOR_NOT4_AFTER_WIFI '+$ethernet.Count)}
$q=[ordered]@{Schema='BlueLite.R055.OP01.FreshEachNativeWifiRemovalQA.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID;SourceNativeReceiptSHA=(Get-FileHash $NativeReceiptPath).Hash;ExactWiFiCapability=$CapabilityName;PhysicalPostState='NotPresent';VerifiedEthernetInstalledCount=$ethernet.Count;VerifiedOriginalNativeExit0=$true;ImageMutation='ONLY_NEW_OWNED_MOUNT';Result='INDEPENDENT_EACH_WIFI_FOD_DISM_REMOVE_PASS'}
$b=[Text.UTF8Encoding]::new($false).GetBytes(($q|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
$f=[IO.File]::Open($IndependentQAPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($b,0,$b.Length)}finally{$f.Dispose()}
Write-Host ('R055_WIFI_FRESH_INDEPENDENT_PASS '+$CapabilityName+' QA_SHA='+(Get-FileHash $IndependentQAPath).Hash)
