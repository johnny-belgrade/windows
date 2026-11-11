# BlueLite universal 26300.x post-converter no-prompt derived ISO independent full byte-range / UDF verifier.
# Portable selected 26300.x cycle root; read-only except ONE independent receipt in cycle BlueLite_Logs, no VM/image mutation.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$CycleRoot,[string]$OutputRoot='')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Gate([bool]$Condition,[string]$Why){if(-not $Condition){throw ('BLUELITE_ISO_NOPROMPT_V3_VERIFY_HOLD_'+$Why)}}
function SHA([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function ReadFull([IO.FileStream]$Stream,[byte[]]$Buffer,[int]$Count){
 $done=0
 while($done -lt $Count){
  $n=$Stream.Read($Buffer,$done,$Count-$done)
  Gate ($n -gt 0) 'ISO_SOURCE_SHORT_READ'
  $done+=$n
 }
}
$cycle=[IO.Path]::GetFullPath($CycleRoot).TrimEnd([char]92,[char]47)
if([string]::IsNullOrWhiteSpace($OutputRoot)){$OutputRoot=Join-Path $cycle 'BlueLite_NoPrompt'}
$root=[IO.Path]::GetFullPath($OutputRoot).TrimEnd([char]92,[char]47)
Gate ([IO.Directory]::Exists($cycle) -and [IO.Directory]::Exists($root)) 'SELECTED_CYCLE_OR_DERIVED_OUTPUT_NOT_FOUND'
Gate ([string]::Equals([IO.Path]::GetDirectoryName($root),$cycle,[StringComparison]::OrdinalIgnoreCase)) 'DERIVED_OUTPUT_NOT_CHILD_OF_SELECTED_SOURCE_CYCLE'
Gate (([IO.File]::GetAttributes($cycle) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'SELECTED_SOURCE_CYCLE_REPARSE'
$logs=Join-Path $cycle 'BlueLite_Logs'
$producerPath=Join-Path $logs 'BlueLite_R042_UEFI_NoPrompt_BootProducer.json'
$receiptPath=Join-Path $logs 'BlueLite_R042_UEFI_NoPrompt_IndependentVerify.json'
Gate ([IO.File]::Exists($producerPath) -and -not [IO.File]::Exists($receiptPath)) 'SOURCE_RECEIPT_MISSING_OR_ALREADY_VERIFIED'
$prior=Get-Content -LiteralPath $producerPath -Raw -Encoding UTF8 | ConvertFrom-Json
Gate ($prior.status -eq 'SOURCE_BOUND_NEW_ISO_NOPROMPT_FAT_PATCH_PRODUCER_PASS_VERIFY_AND_BOOT_PENDING' -and [string]$prior.originalSourceBuild -match '^26300\.\d+$' -and $prior.originalMediaUnchanged -eq $true) 'UNVERIFIED_OR_WRONG_SOURCE_PRODUCER'
$source=[string]$prior.sourceISO
$target=[string]$prior.outputISO
Gate ([string]::Equals([IO.Path]::GetDirectoryName($target),$root,[StringComparison]::OrdinalIgnoreCase)) 'DERIVED_ISO_PATH_ESCAPES_OUTPUT_ROOT'
$length=[long]$prior.outputISOBytes
$offset=[long]$prior.uefiBootFATOffset
$patch=[long]$prior.uefiBootFATBytes
Gate ([IO.File]::Exists($source) -and [IO.File]::Exists($target)) 'SOURCE_OR_DERIVED_ISO_MISSING'
Gate (([IO.FileInfo]::new($source)).Length -eq $length -and ([IO.FileInfo]::new($target)).Length -eq $length) 'FULL_ISO_LENGTH_CHANGED'
Gate ($length -eq [long]$prior.sourceISOBytes -and $offset -gt 0 -and $patch -ge 524288 -and $patch -le 16777216 -and $offset+$patch -le $length) 'PATCH_OFFSET_NOT_IN_SOURCE_BOUNDS'
Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'ACTIVE_WIM_MOUNT'
$srcSHA=SHA $source
$dstSHA=SHA $target
Gate ($srcSHA -eq [string]$prior.sourceISOSHA256) 'ORIGINAL_ISO_SHA_CHANGED'
Gate ($dstSHA -eq [string]$prior.outputISOSHA256 -and $dstSHA -ne $srcSHA) 'DERIVED_ISO_SHA_CHANGED_OR_NOT_PATCHED'
# Compare ENTIRE original+derived stream in TWO ranges, on both sides of the 1.44MB (or source-defined)
# EFI FAT boot image. SHA per equal-sized chunk; no unsupported ReadOnlySpan<byte> construction.
$a=[byte[]]::new(8*1024*1024)
$b=[byte[]]::new(8*1024*1024)
$original=[IO.File]::Open($source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$derived=[IO.File]::Open($target,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
$shaA=[Security.Cryptography.SHA256]::Create()
$shaB=[Security.Cryptography.SHA256]::Create()
$outsideBytes=0L
$chunkCount=0L
function CompareOutside([long]$Start,[long]$Count) {
 $original.Position=$Start
 $derived.Position=$Start
 $remaining=$Count
 while($remaining -gt 0){
  $n=[int][Math]::Min([long]$a.Length,$remaining)
  ReadFull $original $a $n
  ReadFull $derived $b $n
  $first=[Convert]::ToHexString($shaA.ComputeHash($a,0,$n))
  $second=[Convert]::ToHexString($shaB.ComputeHash($b,0,$n))
  Gate ($first -eq $second) ('NONPATCH_ISO_BYTES_DIVERGED_AT_'+($Start+$Count-$remaining))
  $script:outsideBytes+=$n
  $script:chunkCount++
  $remaining-=$n
 }
}
try {
 CompareOutside 0 $offset
 CompareOutside ($offset+$patch) ($length-$offset-$patch)
 Gate ($outsideBytes -eq ($length-$patch)) 'FULL_OUTSIDE_PATCH_RANGE_NOT_COVERED'
 $original.Position=$offset
 $derived.Position=$offset
 $oldFat=[byte[]]::new([int]$patch)
 $newFat=[byte[]]::new([int]$patch)
 ReadFull $original $oldFat ([int]$patch)
 ReadFull $derived $newFat ([int]$patch)
 $oldFatSHA=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($oldFat))
 $newFatSHA=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($newFat))
 Gate ($oldFatSHA -eq [string]$prior.standardEmbeddedFATSHA256 -and $newFatSHA -eq [string]$prior.nopromptUdfBootFATSHA256 -and $oldFatSHA -ne $newFatSHA) 'FAT_PATCH_SHA_DOES_NOT_MATCH_ORIGINAL_AND_SIGNED_SOURCE_NOPROMPT'
} finally {$shaA.Dispose();$shaB.Dispose();$original.Dispose();$derived.Dispose()}
# Source original complete cycle's native receipt resides alongside original pre-extracted UUP source.
$sourceRoot=[IO.Path]::GetDirectoryName([string]$prior.originalUupZip)
Gate ([string]::Equals($sourceRoot,$cycle,[StringComparison]::OrdinalIgnoreCase)) 'VENDOR_ORIGINAL_ZIP_NOT_FROM_SELECTED_CYCLE_ROOT'
$nativePath=Join-Path (Join-Path $sourceRoot 'BlueLite_Logs') 'BlueLite_R029_RESULT.json'
Gate ([IO.File]::Exists($nativePath)) 'ORIGINAL_NATIVE_26300_RECEIPT_MISSING'
$native=Get-Content -LiteralPath $nativePath -Raw -Encoding UTF8 | ConvertFrom-Json
Gate ($native.iso -eq $source -and $native.status -eq 'IMAGE_CANDIDATE_BUILT_NOT_RELEASE_CERTIFIED') 'ORIGINAL_NATIVE_SOURCE_NOT_MATCHING'
$seven=Join-Path $native.stage 'bin\7z.exe'
Gate ([IO.File]::Exists($seven)) 'SOURCE_BUNDLED_7ZIP_MISSING'
$isoTest=(& $seven t -bd $target 2>&1 | Out-String)
$vendorExit=$LASTEXITCODE
Gate ($vendorExit -eq 0 -and $isoTest.Contains('Everything is Ok')) ('DERIVED_UDF_FULL_7Z_CRC_HOLD_'+$vendorExit)
Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'LATE_HOST_WIM_MOUNT_APPEARED'
$reported=[ordered]@{
 schema='BlueLite.R042.PortableSameSourceUEFINoPromptIndependentVerify.v3'
 utc=[datetime]::UtcNow.ToString('o')
 status='DERIVED_ISO_FULLSHA_OUTSIDE_PATCH_IDENTICAL_SAME_SOURCE_NOPROMPT_AND_UDF_CRC_PASS'
 originalBuild=[string]$prior.originalSourceBuild
 originalUUID=[string]$prior.originalSourceUUID
 originalISO=$source
 originalISOSHA256=$srcSHA
 derivedISO=$target
 derivedISOSHA256=$dstSHA
 isoBytes=$length
 patchOffset=$offset
 patchBytes=$patch
 unpatchedBytesCompared=$outsideBytes
 hashVerifiedChunks=$chunkCount
 originalEmbeddedFATSHA256=$oldFatSHA
 derivedEmbeddedFATSHA256=$newFatSHA
 vendor7zNativeExit=$vendorExit
 vendor7zEverythingIsOk=$true
 nativeUdfFiles=$(if($isoTest -match 'Files:\s*(\d+)'){$Matches[1]}else{'NOT_AVAILABLE'})
 nativeUdfFolders=$(if($isoTest -match 'Folders:\s*(\d+)'){$Matches[1]}else{'NOT_AVAILABLE'})
 originalProducerReceiptSHA256=SHA $producerPath
 verifierSourceSHA256=SHA $PSCommandPath
 mountedWIMs=0
 guestBootNotYetPerformed=$true
 releaseCertified=$false
}
$reportBytes=[Text.UTF8Encoding]::new($false).GetBytes(($reported|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$handle=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$handle.Write($reportBytes,0,$reportBytes.Length)}finally{$handle.Dispose()}
Write-Output ('R042_PORTABLE_NOPROMPT_ISO_INDEPENDENT_V3_FULL_BYTE_RANGE_SHA_AND_NATIVE_UDF_CRC_PASS original='+$srcSHA+' derived='+$dstSHA+' comparedOutside='+$outsideBytes+' patchBytes='+$patch+' receipt='+$receiptPath)
exit 0
