# BlueLite R038_15_CleanupSingleBCDWorkcopy.ps1 — exactly one SHA-bound disposable LEAF deletion per mode; never original ISO or receipt.
[CmdletBinding()]
param(
 [Parameter(Mandatory=$true)][ValidateSet('EFI_BCD','BIOS_BCD','BOOT_SDI')][string]$Mode,
 [string]$Root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if($Root -ne 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'){throw 'FIXED_OWNED_ROOT_ONLY'}
$logs=Join-Path $Root 'BlueLite_Logs'
$stage=Join-Path $logs 'R038_14_ISO_BCD_SDI'
$extract=Join-Path $logs 'R038_14_Extract_Result.json'
$semantic=Join-Path $logs 'R038_14_ReadBCD_Result.json'
$sourceReceipt=Join-Path $logs 'R038_00_PreflightReadOnly_Result.json'
if((Get-FileHash -LiteralPath $extract).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'ORIGINAL_EXTRACT_RECEIPT_SHA'}
if((Get-FileHash -LiteralPath $semantic).Hash -ne 'BA09DD67A7985335F84AFCE0D6571DF852A8AB4732F30D9E3862786A79AF8261'){throw 'OFFLINE_BCD_SEMANTIC_RECEIPT_SHA'}
if((Get-FileHash -LiteralPath $sourceReceipt).Hash -ne '44B29FB8BFB13A4CD7627570C4CD8C65314647CEDFD8BF1A2B69B5A56163D290'){throw 'FIRST_SOURCE_RECEIPT_SHA'}
$record=Get-Content -LiteralPath $extract -Raw|ConvertFrom-Json
if($record.status -ne 'EXTRACTED_THREE_SOURCE_ISO_BOOT_FILES_SHA_PASS' -or $record.files.Count -ne 3){throw 'EXTRACT_REPORT_SCHEMA'}
$iso=[string]$record.original_iso_path
$si=Get-Item -LiteralPath $iso -ErrorAction Stop
if($si.Length -ne 6749851648 -or (($si.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'ORIGINAL_SOURCE_ISO_SIZE_OR_LINK_CHANGED'}
if((Get-FileHash -LiteralPath $iso).Hash -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'ORIGINAL_SOURCE_ISO_SHA_CHANGED'}
$base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
$control=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or [string]$base.State -ne 'Running' -or [string](Get-VMFirmware -VMName $base.Name).SecureBoot -ne 'On'){throw 'BASELINE_VM_CHANGED'}
if($control.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or [string]$control.State -ne 'Off' -or [string](Get-VMFirmware -VMName $control.Name).SecureBoot -ne 'Off'){throw 'CONTROL_VM_CHANGED'}
if(@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0){throw 'HOST_WIM_MOUNT_NOT_ZERO'}
if([long](Get-PSDrive C).Free -lt 75000000000){throw 'HOST_DISK_HEADROOM_BELOW_75GB'}
$items=@(
 [pscustomobject]@{mode='EFI_BCD';rel='efi\microsoft\boot\bcd';bytes=[long]20480;sha='F49C659098B0DD98D0B5821D839C5C480F5DD61E518507DAFC83B30023C98B34';oldSha='9B4987F21D897E32F8D3D2A0BDCE5880A786C3BD2E4CFE5AF583F5BF37910B53';oldBytes=16384;receipt='R038_15_DeleteEFI_BCD.json'},
 [pscustomobject]@{mode='BIOS_BCD';rel='boot\bcd';bytes=[long]20480;sha='D3CC16108794E96504E82187B768CFD875892AFFF7C9D78747C675C9E73A2FE2';oldSha='8FE93D6764C2C7EA87B782BD5B47AF77C40D93E67E539F28ACC6A3B21896537D';oldBytes=16384;receipt='R038_15_DeleteBIOS_BCD.json'},
 [pscustomobject]@{mode='BOOT_SDI';rel='boot\boot.sdi';bytes=[long]3170304;sha='CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD';oldSha='CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD';oldBytes=3170304;receipt='R038_15_DeleteBOOT_SDI.json'}
)
$item=@($items|Where-Object {$_.mode -eq $Mode})
if($item.Count -ne 1){throw 'MODE_SCOPE_NOT_UNIQUE'}
$t=$item[0]
$target=Join-Path $stage $t.rel
$out=Join-Path $logs $t.receipt
if(Test-Path -LiteralPath $out){throw 'DELETION_RECEIPT_ALREADY_EXISTS_DO_NOT_REPEAT'}
$stageInfo=Get-Item -LiteralPath $stage -ErrorAction Stop
if(-not $stageInfo.PSIsContainer -or (($stageInfo.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'OWNED_STAGE_NOT_EXACT_DIRECTORY'}
if($Mode -eq 'BIOS_BCD'){
 $pr=Join-Path $logs 'R038_15_DeleteEFI_BCD.json'
 if(-not(Test-Path $pr)){throw 'EFI_CLEANUP_RECEIPT_NOT_PRESENT'}
 $report=Get-Content $pr -Raw|ConvertFrom-Json
 if($report.status -ne 'ONE_OWNED_SHA_BOUND_WORKCOPY_LEAF_DELETED' -or $report.mode -ne 'EFI_BCD' -or $report.target_file_sha256 -ne $items[0].sha){throw 'EFI_CLEANUP_PRIOR_PROVENANCE_INVALID'}
}
if($Mode -eq 'BOOT_SDI'){
 foreach($modeBefore in @('EFI_BCD','BIOS_BCD')){
  $prior=@($items|Where-Object {$_.mode -eq $modeBefore})
  $pr=Join-Path $logs $prior[0].receipt
  if(-not(Test-Path $pr)){throw ('PRIOR_RECEIPT_NOT_PRESENT_'+$modeBefore)}
  $proof=Get-Content $pr -Raw|ConvertFrom-Json
  if($proof.status -ne 'ONE_OWNED_SHA_BOUND_WORKCOPY_LEAF_DELETED' -or $proof.mode -ne $modeBefore -or $proof.target_file_sha256 -ne $prior[0].sha){throw ('PRIOR_RECEIPT_INVALID_'+$modeBefore)}
 }
}
$remaining=@(Get-ChildItem -LiteralPath $stage -Recurse -File -ErrorAction Stop)
$expectedCount=if($Mode -eq 'EFI_BCD'){3}elseif($Mode -eq 'BIOS_BCD'){2}else{1}
if($remaining.Count -ne $expectedCount){throw ('STAGE_FILE_COUNT_NOT_EXPECTED_'+$remaining.Count)}
foreach($fi in $remaining){
 $allowed=@($items|Where-Object {[string]::Equals((Join-Path $stage $_.rel),$fi.FullName,[StringComparison]::OrdinalIgnoreCase)})
 if($allowed.Count -ne 1){throw ('UNAUTHORIZED_STAGE_FILE_'+$fi.FullName)}
 $entry=$allowed[0]
 if($fi.Length -ne $entry.bytes -or (Get-FileHash -LiteralPath $fi.FullName).Hash -ne $entry.sha){throw ('STAGED_SOURCE_SHA_OR_SIZE_DRIFT_'+$entry.mode)}
 if(($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'STAGED_FILE_SYMLINK_FORBIDDEN'}
}
if(-not([string]::Equals((Join-Path $stage $t.rel),$target,[StringComparison]::OrdinalIgnoreCase))){throw 'TARGET_NOT_FIXED_STAGE'}
$file=Get-Item -LiteralPath $target -ErrorAction Stop
if($file.PSIsContainer -or $file.Length -ne $t.bytes -or (Get-FileHash -LiteralPath $target).Hash -ne $t.sha){throw 'TARGET_NOT_LEAF_OR_SHA'}
$dir=$file.Directory
while($null -ne $dir -and $dir.FullName.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase)){
 if(($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'PARENT_DIRECTORY_REPARSE_BLOCK'}
 $dir=$dir.Parent
}
$shaBefore=(Get-FileHash -LiteralPath $target).Hash
$bytesBefore=$file.Length
$timeBefore=$file.LastWriteTimeUtc.ToString('o')
# ONE irreversible native mutation, exact owned LEAF file only. Do not delete directories.
[IO.File]::Delete($target)
if(Test-Path -LiteralPath $target){throw 'TARGET_STILL_PRESENT_AFTER_DELETE'}
$after=@(Get-ChildItem -LiteralPath $stage -Recurse -File -ErrorAction Stop)
if($after.Count -ne ($expectedCount-1)){throw ('POST_DELETE_STAGE_COUNT_DRIFT_'+$after.Count)}
$receipt=[ordered]@{
 schema='BlueLite.R038.OwnedSmallWorkcopyDeletion.v1'
 utc=[datetime]::UtcNow.ToString('o')
 mode=$Mode
 status='ONE_OWNED_SHA_BOUND_WORKCOPY_LEAF_DELETED'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash
 target_exact_path=$target
 target_file_sha256=$shaBefore
 target_file_bytes=$bytesBefore
 target_file_lastwrite_utc=$timeBefore
 original_extracted_source_sha256=$t.oldSha
 original_extracted_source_bytes=$t.oldBytes
 source_iso_sha256='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'
 source_iso_bytes=6749851648
 original_extract_receipt_sha256=(Get-FileHash -LiteralPath $extract).Hash
 offline_bcd_text_receipt_sha256=(Get-FileHash -LiteralPath $semantic).Hash
 stage_files_before=$expectedCount
 stage_files_after=$after.Count
 actual_target_absent=$true
 baseline_vm_original_running_secureboot_on=$true
 control_vm_off_secureboot_off=$true
 original_media_or_host_BCD_EFI_modified=$false
 other_BlueLite_Logs_receipts_preserved=$true
 free_c=[long](Get-PSDrive C).Free
}
$bytes=[Text.UTF8Encoding]::new($false).GetBytes(($receipt|ConvertTo-Json -Depth 8)+[Environment]::NewLine)
$fh=[IO.File]::Open($out,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try{$fh.Write($bytes)}finally{$fh.Dispose()}
Write-Output ('R038_15_'+$Mode+'_SHA_GUARDED_ONE_FILE_DELETED_PASS target='+$target+' bytes='+$bytesBefore+' sha='+$shaBefore+' receiptSha='+(Get-FileHash -LiteralPath $out).Hash+' remaining='+$after.Count)
