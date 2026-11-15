# BlueLite v1.0 / R043 OP111: versioned Edge FOD source-state gate v2, READONLY evidence only.
# Never changes a Windows image; full DISM diagnostic transcript + exact non-overwriting receipt.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$OwnerWim,
 [Parameter(Mandatory=$true)][string]$MountDir,
 [Parameter(Mandatory=$true)][ValidatePattern('^26300\.[0-9]+$')][string]$SourceBuild,
 [Parameter(Mandatory=$true)][string]$PackageName,
 [Parameter(Mandatory=$true)][string]$ReceiptPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
function FailClosed([string]$Reason) {throw ('BlueLite.EdgeFOD.DRYRUN.v2 HOLD: '+$Reason)}
function SHA256File([string]$Path){
 $hash=[Security.Cryptography.SHA256]::Create()
 $stream=[IO.File]::OpenRead($Path)
 try{[BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','')}
 finally{$stream.Dispose();$hash.Dispose()}
}
function CreateUTF8Once([string]$Path,[string]$Body){
 $bytes=[Text.UTF8Encoding]::new($false).GetBytes($Body)
 $file=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
 try{$file.Write($bytes,0,$bytes.Length)}finally{$file.Dispose()}
}
if($PackageName -cnotmatch '^Microsoft-Edge-WebView-FOD-Package~31bf3856ad364e35~amd64~~10\.0\.[0-9]+\.[0-9]+$'){
 FailClosed 'Source exact Edge WebView FOD CBS package identity not accepted'
}
if(-not(Test-Path -LiteralPath $OwnerWim -PathType Leaf)){FailClosed 'Expected owner WIM missing'}
if(-not(Test-Path -LiteralPath $MountDir -PathType Container)){FailClosed 'Expected existing mount missing'}
$wimFull=[IO.Path]::GetFullPath($OwnerWim).TrimEnd('\')
$mountFull=[IO.Path]::GetFullPath($MountDir).TrimEnd('\')
$receiptFull=[IO.Path]::GetFullPath($ReceiptPath)
$consoleFull=$receiptFull+'.native.txt'
$scriptDir=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
if([IO.Path]::GetExtension($wimFull) -ine '.wim'){FailClosed 'Owner path extension not WIM'}
if(-not [string]::Equals([IO.Path]::GetDirectoryName($receiptFull),$scriptDir,[StringComparison]::OrdinalIgnoreCase)){
 FailClosed 'Receipt must reside in the existing v2 helper source evidence directory'
}
if((Test-Path -LiteralPath $receiptFull) -or (Test-Path -LiteralPath $consoleFull)){
 FailClosed 'Receipt/transcript already exists; no replay or overwrite'
}
$mounts=@(Get-WindowsImage -Mounted)
if($mounts.Count -ne 1){FailClosed 'Exactly one existing mounted WIM required'}
$m=$mounts[0]
if(-not [string]::Equals([IO.Path]::GetFullPath([string]$m.ImagePath).TrimEnd('\'),$wimFull,[StringComparison]::OrdinalIgnoreCase) -or
 -not [string]::Equals([IO.Path]::GetFullPath([string]$m.Path).TrimEnd('\'),$mountFull,[StringComparison]::OrdinalIgnoreCase) -or
 [int]$m.ImageIndex -ne 1 -or [string]$m.MountMode -ne 'ReadOnly' -or [string]$m.MountStatus -ne 'Ok'){
 FailClosed 'WIM ownership/index/mount mode/state mismatch'
}
$cFree=[int64](Get-PSDrive C -ErrorAction Stop).Free
if($cFree -lt 64424509440){FailClosed 'C drive below 60GiB protection floor'}
$offVM=0
if(Get-Command Get-VM -ErrorAction SilentlyContinue){
 $vms=@(Get-VM | Where-Object {$_.Name -like 'BlueLite*'})
 if(@($vms | Where-Object {[string]$_.State -ne 'Off'}).Count -ne 0){FailClosed 'BlueLite Hyper-V guest running'}
 $offVM=$vms.Count
}
$dism=Join-Path $env:SystemRoot 'System32\dism.exe'
if(-not(Test-Path -LiteralPath $dism -PathType Leaf)){FailClosed 'Native DISM missing'}
$nativeArgs=@('/English',('/Image:'+$mountFull),'/Get-PackageInfo',('/PackageName:'+$PackageName))
$start=(Get-Date).ToUniversalTime().ToString('o')
$oldPreference=$ErrorActionPreference
$ErrorActionPreference='Continue'
try{
 $lines=@(& $dism @nativeArgs 2>&1 | ForEach-Object {$_.ToString()})
 $nativeExit=[int]$LASTEXITCODE
}finally{$ErrorActionPreference=$oldPreference}
$fullTranscript=($lines -join [Environment]::NewLine)+[Environment]::NewLine
CreateUTF8Once $consoleFull $fullTranscript
$nativeConsoleSHA=SHA256File $consoleFull
$nativeState=[regex]::Match($fullTranscript,'(?im)^\s*State\s*:\s*(?<v>[^\r\n]+)')
$nativeRelease=[regex]::Match($fullTranscript,'(?im)^\s*Release Type\s*:\s*(?<v>[^\r\n]+)')
$packageState=if($nativeState.Success){$nativeState.Groups['v'].Value.Trim()}else{'UNKNOWN'}
$releaseType=if($nativeRelease.Success){$nativeRelease.Groups['v'].Value.Trim()}else{'UNKNOWN'}
$statePass=($nativeExit -eq 0 -and $packageState -ne 'UNKNOWN' -and $releaseType -ne 'UNKNOWN')
$status=if($statePass){'READONLY_CBS_STATE_OBSERVED_NOT_REMOVAL_AUTHORIZATION'}else{'NATIVE_QUERY_HOLD_WITH_FULL_DIAGNOSTICS'}
$report=[ordered]@{
 schema='BlueLite.PREMAX.Germanium.EdgeFOD.SourceGate.DRYRUN.v2'
 timestampUtc=(Get-Date).ToUniversalTime().ToString('o')
 queryStartedUtc=$start
 status=$status
 sourceBuildClaim=$SourceBuild
 ownerWim=$wimFull
 mountDir=$mountFull
 mountMode='ReadOnly'
 exactPackageIdentity=$PackageName
 nativeDismExecutable=$dism
 nativeArguments=@($nativeArgs)
 nativeExit=$nativeExit
 packageCBSState=$packageState
 releaseType=$releaseType
 nativeTranscriptPath=$consoleFull
 nativeTranscriptSHA256=$nativeConsoleSHA
 nativeTranscriptBytes=(Get-Item -LiteralPath $consoleFull).Length
 currentCFreeBytes=$cFree
 BlueLiteGuestsOff=$offVM
 packageRemovabilityCertified=$false
 compressedBytesSaved=0
 hasModifiedAnyImage=$false
 requiresOwnerServicingDependencyProof=$true
 requiresSeparateExplicitOwnerApprovalForImageMutation=$true
}
CreateUTF8Once $receiptFull (($report|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$report|ConvertTo-Json -Depth 8
if(-not $statePass){FailClosed 'Native DISM query failed; full console and HOLD receipt preserved'}
