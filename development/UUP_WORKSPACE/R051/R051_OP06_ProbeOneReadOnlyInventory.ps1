# R051 OP06 one read-only PowerShell7 offline image inventory cmdlet per fresh process.
[CmdletBinding()]param(
 [Parameter(Mandatory=$true)][ValidateSet('Packages','Capabilities','Features','ProvisionedApps')][string]$TestName,
 [Parameter(Mandatory=$true)][string]$Mount,
 [Parameter(Mandatory=$true)][string]$ExpectedWimSHA256,
 [Parameter(Mandatory=$true)][string]$ReceiptPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
if(-not ([IO.Directory]::Exists($Mount)) -or -not ([IO.Directory]::Exists((Join-Path $Mount 'Windows')))){throw 'EXPECTED_READ_ONLY_OFFLINE_MOUNT_MISSING'}
if($Mount -notlike 'C:\work\_UUP\temp\R053_COMProbe_20261121\Mount'){throw 'READ_ONLY_SCOPE_MOUNT_ROOT_WRONG'}
if($ExpectedWimSHA256 -cne '99407C0AA99EC0A06355D8F5C23DBEEAD6E1A1D5F147771026AF48D4AD638916'){throw 'RECONSTRUCTED_10066_SOURCE_SHA_NOT_PINNED'}
$stopwatch=[Diagnostics.Stopwatch]::StartNew()
$actualStatus='CMDLET_HOLD';$items=0;$errorType='';$hresult='';$detail='';$fqi='';$position=''
try{
 switch($TestName){
  'Packages' {$data=@(Get-WindowsPackage -Path $Mount -ErrorAction Stop | Select-Object PackageName,PackageState,ReleaseType)}
  'Capabilities' {$data=@(Get-WindowsCapability -Path $Mount -ErrorAction Stop | Select-Object Name,State)}
  'Features' {$data=@(Get-WindowsOptionalFeature -Path $Mount -ErrorAction Stop | Select-Object FeatureName,State)}
  'ProvisionedApps' {$data=@(Get-AppxProvisionedPackage -Path $Mount -ErrorAction Stop | Select-Object DisplayName,PackageName,Version,Architecture,ResourceId)}
 }
 $items=@($data).Count
 if($items -le 0){throw 'CMDLET_UNEXPECTED_EMPTY_RESULT'}
 $actualStatus='NATIVE_READ_ONLY_CMDLET_PASS'
}catch{
 $errorType=$_.Exception.GetType().FullName
 $innerException=$_.Exception.InnerException
 if($innerException){$errorType+=' / inner '+$innerException.GetType().FullName}
 $hresult='0x'+([Convert]::ToString(([int64]$_.Exception.HResult -band 4294967295),16).ToUpperInvariant().PadLeft(8,'0'))
 $detail=[string]$_.Exception.Message
 $fqi=[string]$_.FullyQualifiedErrorId
 $position=[string]$_.InvocationInfo.PositionMessage
 $actualStatus='NATIVE_READ_ONLY_CMDLET_HOLD'
}
$stopwatch.Stop()
$record=[ordered]@{
 Schema='BlueLite.R051.OP06.SingleShortReadonlyInventoryCmdlet.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 TestName=$TestName;MountedImageRoot=$Mount;ReconstructedSourceWimSHA256=$ExpectedWimSHA256
 NativeCmdletStatus=$actualStatus;ReturnedObjectCount=$items
 RealExceptionType=$errorType;RealExceptionHResult=$hresult;RealExceptionMessage=$detail
 RealFullyQualifiedErrorId=$fqi;RealInvocationPosition=$position
 ElapsedSeconds=[math]::Round($stopwatch.Elapsed.TotalSeconds,3)
 ImageMutation='READ_ONLY_MOUNT_NO_MUTATION';OneNext='SEPARATE_FRESH_NATIVE_QA_BEFORE_NEXT_CMDLET'
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($record|ConvertTo-Json -Depth 9)+[Environment]::NewLine)
$f=[IO.File]::Open($ReceiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
Write-Output ('R051_OP06_NATIVE_'+$TestName+' STATUS='+$actualStatus+' COUNT='+$items+' ERROR_TYPE='+$errorType+' HRESULT='+$hresult+' RECEIPT_SHA='+(Get-FileHash $ReceiptPath).Hash)
exit 0
