# R051 OP06 truly separate PS7 child independent readback and field/sha validation of one native receipt.
[CmdletBinding()]param(
 [Parameter(Mandatory=$true)][ValidateSet('Packages','Capabilities','Features','ProvisionedApps')][string]$TestName,
 [Parameter(Mandatory=$true)][string]$NativeReceipt,
 [Parameter(Mandatory=$true)][string]$QAReceipt,
 [Parameter(Mandatory=$true)][string]$ExpectedWimSHA256
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if(-not [IO.File]::Exists($NativeReceipt) -or [IO.File]::Exists($QAReceipt)){throw 'RECEIPT_MISSING_OR_QA_COLLISION'}
$p=(Get-FileHash $NativeReceipt).Hash
$o=Get-Content $NativeReceipt -Raw|ConvertFrom-Json -Depth 12
if($o.Schema -cne 'BlueLite.R051.OP06.SingleShortReadonlyInventoryCmdlet.v1' -or $o.TestName -cne $TestName){throw 'RECEIPT_SCHEMA_OR_TESTNAME_CHANGED'}
if($o.MountedImageRoot -cne 'C:\work\_UUP\temp\R053_COMProbe_20261121\Mount'){throw 'INDEPENDENT_MOUNT_SCOPE_WRONG'}
if($o.ReconstructedSourceWimSHA256 -cne $ExpectedWimSHA256){throw 'SOURCE_WIM_SHA_FIELD_WRONG'}
if($o.NativeCmdletStatus -eq 'NATIVE_READ_ONLY_CMDLET_PASS'){
 if($o.ReturnedObjectCount -le 0 -or $o.RealExceptionType -or $o.RealExceptionMessage){throw 'PASS_PREDICATE_FALSE'}
}elseif($o.NativeCmdletStatus -eq 'NATIVE_READ_ONLY_CMDLET_HOLD'){
 if(-not $o.RealExceptionType -or -not $o.RealExceptionMessage){throw 'HOLD_WITHOUT_REAL_EXCEPTION_EVIDENCE'}
}else{throw 'UNRECOGNIZED_CMDLET_STATUS'}
$rec=[ordered]@{
 Schema='BlueLite.R051.OP06.IndependentSingleCmdletReceiptQA.v1';UTC=[DateTime]::UtcNow.ToString('o');PID=$PID
 TestName=$TestName;NativeReceiptSHA256=$p;NativeStatus=$o.NativeCmdletStatus;Count=$o.ReturnedObjectCount
 CapturedExceptionType=$o.RealExceptionType;CapturedHResult=$o.RealExceptionHResult
 ReconstructedSourceWimSHA256=$ExpectedWimSHA256
 IndependentQA='PASS_FOR_ACCURATE_NATIVE_CMDLET_PASS_OR_HOLD';OneNext='NEXT_DISTINCT_READ_ONLY_CMDLET_OR_SAFE_DISM_DISMOUNT'
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($rec|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$f=[IO.File]::Open($QAReceipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes,0,$bytes.Length)}finally{$f.Dispose()}
Write-Output ('R051_OP06_TRUE_SEPARATE_QA_'+$TestName+' PASS NATIVE='+$o.NativeCmdletStatus+' NATIVE_SHA='+$p+' QA_SHA='+(Get-FileHash $QAReceipt).Hash)
exit 0
