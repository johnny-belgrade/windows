# BlueLite R038_01_CandidateManifest_v1.1.ps1 — corrected real DISM index-list metadata, no WIM/ISO modification
[CmdletBinding()]
param([string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300')
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'UNEXPECTED_ROOT'}
$logs=Join-Path $Root 'BlueLite_Logs'
$prior=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
$receipt=Join-Path $logs 'R038_01_CandidateManifest_Result.json'
if(-not(Test-Path -LiteralPath $prior -PathType Leaf)){throw 'NO_R038_00_PHYSICAL_SOURCE_RECEIPT'}
if(Test-Path $receipt){throw 'CANDIDATE_RECEIPT_ALREADY_EXISTS'}
$pre=Get-Content -LiteralPath $prior -Raw|ConvertFrom-Json
if($pre.status -ne 'ISOLATED_HOST_AND_SIX_SOURCE_SHA_PASS_VM_NOT_CREATED' -or $pre.media.Count -ne 6){throw 'PRECHECK_NOT_PASS'}
$records=[Collections.Generic.List[object]]::new()
foreach($entry in $pre.media){
 if(-not(Test-Path $entry.path -PathType Leaf)){throw ('MISSING_ORIGINAL_'+$entry.kind)}
 $item=Get-Item $entry.path -ErrorAction Stop
 if($item.Length -ne [long]$entry.bytes){throw ('CHANGED_BYTES_'+$entry.kind)}
 if($entry.kind -like '*WIM*' -or $entry.kind -match 'LZX|XPRESS'){
  $images=@(Get-WindowsImage -ImagePath $entry.path -ErrorAction Stop)
  $imageCount=$images.Count
  $wanted=if($entry.kind -in @('R035_SETUP_BOOT_WIM','R036_DUAL_XPRESS')){2}else{1}
  if($imageCount -ne $wanted){throw ('UNEXPECTED_WIM_INDICES_'+$entry.kind+'_'+$imageCount)}
  $imageInfo=@($images|ForEach-Object { [ordered]@{index=$_.ImageIndex;name=$_.ImageName;description=$_.ImageDescription;image_size_from_wiminfo=$_.ImageSize;architecture_from_indexlist='NOT_EXPOSED'} })
  [void]$records.Add([ordered]@{kind=$entry.kind;path=$entry.path;bytes=$item.Length;source_sha=$entry.sha256;image_count=$imageCount;images=$imageInfo})
  Write-Output ('R038_WIM_MANIFEST_PASS '+$entry.kind+' count='+$imageCount+' B='+$item.Length)
 }else{
  [void]$records.Add([ordered]@{kind=$entry.kind;path=$entry.path;bytes=$item.Length;source_sha=$entry.sha256;image_count=$null;images=@()})
 }
}
$iso=@($pre.media|Where-Object kind -eq 'R035_ISO')
$install=@($pre.media|Where-Object kind -eq 'R035_INSTALL_WIM')
$boot=@($pre.media|Where-Object kind -eq 'R035_SETUP_BOOT_WIM')
$lzx=@($pre.media|Where-Object kind -eq 'R036_SETUPONLY_LZX')
$sum=[long]$install[0].bytes+[long]$boot[0].bytes
$other=[long]$iso[0].bytes-$sum
$bootSaving=[long]$boot[0].bytes-[long]$lzx[0].bytes
if($other -ne 261837992 -or $bootSaving -ne 13563551){throw 'SOURCE_COMPOSITION_NOT_AS_PROVEN'}
$maxWinPEScope=@('WinPE-SRT','WinPE-Rejuv','WinPE-HTA','WinPE-WMI','WinPE-Audio','WinPE-SecureStartup')
$report=[ordered]@{schema='BlueLite.R038.CandidateManifest.v1';utc=[datetime]::UtcNow.ToString('o');status='SIX_NATIVE_WIM_INDEX_METADATA_AND_ISO_COMPOSITION_PASS_NO_BOOT';ownroot=$Root;script_sha256=(Get-FileHash $PSCommandPath).Hash;preflight_receipt_sha=(Get-FileHash $prior).Hash;media=@($records);iso_bytes=$iso[0].bytes;install_wim_bytes=$install[0].bytes;boot_wim_bytes=$boot[0].bytes;other_iso_bytes=$other;setup_only_lzx_bytes=$lzx[0].bytes;setup_only_lzx_saving=$bootSaving;unbuilt_boot_only_iso_theoretical_bytes=6736288097;additional_compressed_bytes_for_exact_5GB_if_other_constant=1736288097;packaging_media_modified=$false;pending_real_installed_WinPE_package_state=$maxWinPEScope;actual_UEFI_BIOS_Setup_testing='NOT_RUN';actual_first_installed_boot='NOT_RUN';actual_repeat_boot='NOT_RUN'}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($report|ConvertTo-Json -Depth 10)+[Environment]::NewLine)
$f=[IO.File]::Open($receipt,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$f.Write($bytes)}finally{$f.Dispose()}
Write-Output ('R038_01_CANDIDATE_MANIFEST_PASS receiptSHA='+(Get-FileHash $receipt).Hash+' images='+$records.Count+' WinPEBootCompressionFaster_NOT_PROVEN')
