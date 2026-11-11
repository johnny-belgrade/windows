# BlueLite 26300.x universal post-converter UEFI noprompt ISO derivative, portable source-tested, release-not-certified.
# Never modifies original UUP source, install.wim, boot.wim or original ISO.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][string]$CycleRoot,
 [string]$OutputRoot=''
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$ProgressPreference='SilentlyContinue'
function Gate([bool]$Valid,[string]$Reason){if(-not $Valid){throw ('BLUELITE_UEFI_NOPROMPT_HOLD_'+$Reason)}}
function SHA([string]$Path){(Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash.ToUpperInvariant()}
function ReadJson([string]$Path){Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json}
function ReadSector([IO.FileStream]$FS,[long]$LBA) {
 Gate ($LBA -ge 16 -and ($LBA+1)*2048 -le $FS.Length) 'ISO_SECTOR_OOB'
 $b=[byte[]]::new(2048)
 $FS.Position=$LBA*2048
 Gate ($FS.Read($b,0,2048) -eq 2048) 'ISO_SECTOR_TRUNCATED'
 return ,$b
}
function IsoCatalog([string]$ISO) {
 $file=[IO.File]::Open($ISO,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
 try {
  $br=$null
  for($lba=16;$lba -le 95;$lba++){
   $sector=ReadSector $file $lba
   if([Text.Encoding]::ASCII.GetString($sector,1,5) -ne 'CD001'){break}
   if($sector[0] -eq 0 -and [Text.Encoding]::ASCII.GetString($sector,7,32).StartsWith('EL TORITO SPECIFICATION')){$br=$sector}
   if($sector[0] -eq 255){break}
  }
  Gate ($null -ne $br) 'EL_TORITO_BOOT_RECORD_ABSENT'
  $catalogLba=[long][BitConverter]::ToUInt32($br,71)
  $catalog=ReadSector $file $catalogLba
  $sum=[long]0
  for($x=0;$x -lt 32;$x+=2){$sum+=[BitConverter]::ToUInt16($catalog,$x)}
  Gate ($catalog[0] -eq 1 -and $catalog[30] -eq 0x55 -and $catalog[31] -eq 0xAA -and (($sum -band 65535) -eq 0)) 'EL_TORITO_CATALOG_INVALID'
  $bootEntry=$null;$o=64
  while($o+64 -le $catalog.Length){
   $section=[int]$catalog[$o]
   if($section -ne 0x90 -and $section -ne 0x91){break}
   $platform=[int]$catalog[$o+1]
   $count=[int][BitConverter]::ToUInt16($catalog,$o+2)
   Gate ($count -gt 0 -and $count -le 20) 'EL_TORITO_SECTION_COUNT_INVALID'
   for($j=0;$j -lt $count;$j++){
    $entry=$o+32+$j*32
    if($platform -eq 0xEF -and $catalog[$entry] -eq 0x88 -and (($catalog[$entry+1] -band 0x0F) -eq 0)){
     Gate ($null -eq $bootEntry) 'EL_TORITO_UEFI_MULTIPLE_ENTRIES_AMBIGUOUS'
     $bootEntry=$entry
    }
   }
   $o+=32*(1+$count)
   if($section -eq 0x91){break}
  }
  Gate ($null -ne $bootEntry) 'EL_TORITO_UEFI_ENTRY_ABSENT'
  $fatLba=[long][BitConverter]::ToUInt32($catalog,$bootEntry+8)
  $first=ReadSector $file $fatLba
  $bps=[int][BitConverter]::ToUInt16($first,11)
  $sct=[long][BitConverter]::ToUInt16($first,19)
  if($sct -eq 0){$sct=[long][BitConverter]::ToUInt32($first,32)}
  $bytes=[long]$bps*$sct
  Gate ($bps -in @(512,1024,2048,4096) -and $bytes -ge 524288 -and $bytes -le 16777216 -and ($fatLba*2048+$bytes) -le $file.Length -and $first[510] -eq 0x55 -and $first[511] -eq 0xAA) 'EL_TORITO_FAT_GEOMETRY_INVALID'
  $buf=[byte[]]::new([int]$bytes)
  $file.Position=$fatLba*2048
  $pos=0
  while($pos -lt $buf.Length){
   $n=$file.Read($buf,$pos,$buf.Length-$pos)
   Gate ($n -gt 0) 'EL_TORITO_FAT_SHORT_READ'
   $pos+=$n
  }
  return [pscustomobject]@{
   catalogLba=$catalogLba;catalogSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($catalog))
   fatLba=$fatLba;fatOffset=[long]$fatLba*2048;fatBytes=$bytes
   fatOriginalSha256=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($buf))
   fatOriginal=$buf;bytesPerSector=$bps;sectors=$sct;catalogEntryOffset=$bootEntry
  }
 } finally {$file.Dispose()}
}
function OriginalUdfMember([string]$Seven,[string]$ISO,[string]$Member,[long]$MaximumBytes){
 $p=[Diagnostics.ProcessStartInfo]::new()
 $p.FileName=$Seven;$p.UseShellExecute=$false;$p.RedirectStandardOutput=$true;$p.RedirectStandardError=$true;$p.CreateNoWindow=$true
 foreach($arg in @('e','-so','-bd',$ISO,$Member)){[void]$p.ArgumentList.Add([string]$arg)}
 $pr=[Diagnostics.Process]::new();$pr.StartInfo=$p
 $memory=[IO.MemoryStream]::new()
 try {
  Gate ($pr.Start()) 'VENDOR_7Z_FAILED_TO_START'
  $stderrTask=$pr.StandardError.ReadToEndAsync()
  $pr.StandardOutput.BaseStream.CopyTo($memory)
  Gate ($pr.WaitForExit(45000)) 'VENDOR_7Z_SOURCE_TIMEOUT'
  Gate ($pr.ExitCode -eq 0) ('VENDOR_7Z_SOURCE_EXIT_'+$pr.ExitCode+'_'+$stderrTask.GetAwaiter().GetResult())
  Gate ($memory.Length -gt 0 -and $memory.Length -le $MaximumBytes) 'VENDOR_7Z_UDF_BOOT_SOURCE_SIZE'
  return ,$memory.ToArray()
 } finally {$memory.Dispose();$pr.Dispose()}
}
$root=[IO.Path]::GetFullPath($CycleRoot).TrimEnd([char]92,[char]47)
if([string]::IsNullOrWhiteSpace($OutputRoot)){$OutputRoot=Join-Path $root 'BlueLite_NoPrompt'}
$targetRoot=[IO.Path]::GetFullPath($OutputRoot).TrimEnd([char]92,[char]47)
Gate ([IO.Path]::IsPathRooted($root) -and [IO.Path]::IsPathRooted($targetRoot)) 'SOURCE_AND_OUTPUT_MUST_BE_ABSOLUTE'
Gate ([IO.Directory]::Exists($root) -and -not [string]::Equals([IO.Path]::GetPathRoot($root),$root,[StringComparison]::OrdinalIgnoreCase)) 'SOURCE_MUST_BE_EXISTING_FOLDER_NOT_DRIVE_ROOT'
Gate ([string]::Equals([IO.Path]::GetDirectoryName($targetRoot),$root,[StringComparison]::OrdinalIgnoreCase)) 'OUTPUT_MUST_BE_DIRECT_CHILD_OF_SELECTED_CYCLE_ROOT'
Gate ($root -ne $targetRoot -and -not [IO.Directory]::Exists($targetRoot) -and -not [IO.File]::Exists($targetRoot)) 'OUTPUT_ROOT_EXISTS_OR_ALIASES_SOURCE'
Gate (([IO.File]::GetAttributes($root) -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'SOURCE_ROOT_REPARSE'
Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'OTHER_WIM_MOUNTED'
$logs=Join-Path $root 'BlueLite_Logs'
$receiptSource=Join-Path $logs 'BlueLite_R029_RESULT.json'
Gate ([IO.File]::Exists($receiptSource)) 'SOURCE_R029_NATIVE_RESULT_MISSING'
$native=ReadJson $receiptSource
Gate ($native.status -eq 'IMAGE_CANDIDATE_BUILT_NOT_RELEASE_CERTIFIED' -and [string]$native.build -match '^26300\.\d+$' -and -not [string]::IsNullOrWhiteSpace([string]$native.uuid)) 'ONLY_COMPLETED_26300X_NATIVE_CANDIDATE_ALLOWED'
Gate ([string]::Equals([string]$native.root,$root,[StringComparison]::OrdinalIgnoreCase)) 'SOURCE_NATIVE_ROOT_MISMATCH'
$originalZip=@(Get-ChildItem -LiteralPath $root -File -Filter '*_convert.zip')
Gate ($originalZip.Count -eq 1) 'REQUIRE_EXACT_ONE_ORIGINAL_VENDOR_ZIP'
Gate ((SHA $originalZip[0].FullName) -eq [string]$native.original_source_zip_sha256) 'ORIGINAL_UUP_ARCHIVE_SHA_DRIFT'
$iso=[string]$native.iso
Gate ([IO.File]::Exists($iso) -and ([IO.FileInfo]::new($iso)).Length -eq [long]$native.iso_bytes) 'NATIVE_ISO_SOURCE_MISSING_OR_SIZE'
Gate ([string]::Equals((SHA $iso),[string]$native.iso_sha256,[StringComparison]::OrdinalIgnoreCase)) 'SOURCE_ISO_SHA_DRIFT'
Gate ([IO.File]::Exists([string]$native.install_wim) -and (SHA ([string]$native.install_wim)) -eq [string]$native.install_wim_sha256) 'NATIVE_WIM_SOURCE_SHA_DRIFT'
$stage=[string]$native.stage
$seven=Join-Path $stage 'bin\7z.exe'
Gate ([IO.File]::Exists($seven)) 'NATIVE_CONVERTER_7ZIP_TOOL_MISSING'
$sourceCatalog=IsoCatalog $iso
$standard=OriginalUdfMember $seven $iso 'efi\microsoft\boot\efisys.bin' 16777216
$noprompt=OriginalUdfMember $seven $iso 'efi\microsoft\boot\efisys_noprompt.bin' 16777216
Gate ($standard.Length -eq $sourceCatalog.fatBytes -and $noprompt.Length -eq $standard.Length) 'STANDARD_NOPROMPT_DIFFERENT_LENGTH'
$standardSHA=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($standard))
$nopromptSHA=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($noprompt))
Gate ($standardSHA -eq $sourceCatalog.fatOriginalSha256 -and $nopromptSHA -ne $standardSHA) 'CURRENT_EFI_FAT_UDF_SOURCE_MISMATCH'
Gate ([BitConverter]::ToUInt16($noprompt,11) -eq $sourceCatalog.bytesPerSector -and $noprompt[510] -eq 0x55 -and $noprompt[511] -eq 0xAA) 'NOPROMPT_BPB_OR_FAT_SIGNATURE_MISMATCH'
Gate ([IO.DriveInfo]::new('C').AvailableFreeSpace -gt ([long]$native.iso_bytes+15GB)) 'INSUFFICIENT_FREE_SPACE_FOR_ISO_COPY'
# Only now create the new output root and mutate the newly owned DERIVED copy, never source ISO.
[void][IO.Directory]::CreateDirectory($targetRoot)
$targetName=[IO.Path]::GetFileNameWithoutExtension($iso)+'.BlueLite.NoPrompt.TEST.iso'
$targetISO=Join-Path $targetRoot $targetName
Gate (-not [IO.File]::Exists($targetISO)) 'DERIVED_ISO_ALREADY_EXISTS'
[IO.File]::Copy($iso,$targetISO,$false)
$f=[IO.File]::Open($targetISO,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
try {
 Gate ($f.Length -eq [long]$native.iso_bytes) 'COPIED_ISO_SIZE_CHANGED'
 $before=[byte[]]::new([int]$sourceCatalog.fatBytes)
 $f.Position=[long]$sourceCatalog.fatOffset
 $read=0
 while($read -lt $before.Length){
  $n=$f.Read($before,$read,$before.Length-$read)
  Gate ($n -gt 0) 'COPIED_ISO_PREPATCH_READ_TRUNCATED'
  $read+=$n
 }
 Gate ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($before)) -eq $standardSHA) 'COPIED_ISO_FAT_SOURCE_NOT_IDENTICAL'
 $f.Position=[long]$sourceCatalog.fatOffset
 $f.Write($noprompt,0,$noprompt.Length)
 $f.Flush($true)
} finally {$f.Dispose()}
$derivedSHA=SHA $targetISO
Gate ($derivedSHA -ne [string]$native.iso_sha256 -and ([IO.FileInfo]::new($targetISO)).Length -eq [long]$native.iso_bytes) 'DERIVED_ISO_NO_ACTUAL_CHANGE'
Gate ((SHA $iso) -eq [string]$native.iso_sha256) 'ORIGINAL_SOURCE_ISO_CHANGED_AFTER_DERIVATION'
Gate (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -eq 0) 'MOUNT_APPEARED'
$outlogs=Join-Path $root 'BlueLite_Logs'
[void][IO.Directory]::CreateDirectory($outlogs)
$receipt=Join-Path $outlogs 'BlueLite_R042_UEFI_NoPrompt_BootProducer.json'
$report=[ordered]@{
 schema='BlueLite.Generic26300x.NoPromptDerivedIso.v1'
 status='SOURCE_BOUND_NEW_ISO_NOPROMPT_FAT_PATCH_PRODUCER_PASS_VERIFY_AND_BOOT_PENDING'
 utc=[datetime]::UtcNow.ToString('o')
 originalUupZip=$originalZip[0].FullName
 originalUupZipSHA256=[string]$native.original_source_zip_sha256
 originalSourceBuild=[string]$native.build
 originalSourceUUID=[string]$native.uuid
 sourceISO=$iso
 sourceISOSHA256=[string]$native.iso_sha256
 sourceISOBytes=[long]$native.iso_bytes
 sourceWimSHA256=[string]$native.install_wim_sha256
 outputISO=$targetISO
 outputISOSHA256=$derivedSHA
 outputISOBytes=([IO.FileInfo]::new($targetISO)).Length
 bootCatalogLBA=$sourceCatalog.catalogLba
 bootCatalogSHA256=$sourceCatalog.catalogSha256
 uefiBootFATLBA=$sourceCatalog.fatLba
 uefiBootFATOffset=[long]$sourceCatalog.fatOffset
 uefiBootFATBytes=[long]$sourceCatalog.fatBytes
 standardEmbeddedFATSHA256=$standardSHA
 nopromptUdfBootFATSHA256=$nopromptSHA
 patchBytesOnly=$sourceCatalog.fatBytes
 originalMediaUnchanged=$true
 targetMediaExperimental=$true
 releaseCertified=$false
 UefiSetupBootVerified=$false
 guestFirstBootVerified=$false
 repeatedBootTimeVerified=$false
 sourceScriptSHA256=SHA $PSCommandPath
 next='SEPARATE_FULL_BYTE_DIFF_ISO_UDF_CRC_VERIFY_THEN_HYPERV_GEN2_REAL_BOOT_SCREENSHOT'
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 12)+[Environment]::NewLine)
$rstream=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {$rstream.Write($bytes,0,$bytes.Length)} finally {$rstream.Dispose()}
Write-Output ('BLUELITE_NOPROMPT_DERIVED_ISO_PRODUCER_PASS SOURCE_BUILD='+$native.build+' TARGET='+$targetISO+' SHA256='+$derivedSHA+' RECEIPT='+$receipt+' BOOT_NOT_RUN')
exit 0
