# R038 OP114: independent non-mutating final stage proof. Only read file hashes and guest state.
$ErrorActionPreference='Stop'
$root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs=Join-Path $root 'BlueLite_Logs'
$stage=Join-Path $logs 'R038_14_ISO_BCD_SDI'
$empty='E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
$engineSha='D0B09B655BCA1672B66876B25DFB315ABD993118F39C556A07A7BD0A07E3C21E'
$items=@(
 [pscustomobject]@{mode='EFI_LOG2';rel='efi\microsoft\boot\bcd.LOG2';size=[long]0;sha=$empty;receipt='AA7CA233F8E4ABB5F16E3C9A4CFEFA0F9AD68A068F59E4111DA29A914D4FB1F2'}
 [pscustomobject]@{mode='EFI_LOG1';rel='efi\microsoft\boot\bcd.LOG1';size=[long]0;sha=$empty;receipt='682050CF46C3EDC98ECB3966BF1F2EA8892AD253D9158F982301CE3364D77974'}
 [pscustomobject]@{mode='BIOS_LOG2';rel='boot\bcd.LOG2';size=[long]0;sha=$empty;receipt='34816F396F300AE86B696A8033B391FFAF054640489998BFD8B7B36F4B405DD9'}
 [pscustomobject]@{mode='BIOS_LOG1';rel='boot\bcd.LOG1';size=[long]0;sha=$empty;receipt='10FFBC6694A17FAB6F2119AAE38A34D6D3489C52AF1D67FBC23C0E097197A761'}
 [pscustomobject]@{mode='EFI_LOG';rel='efi\microsoft\boot\bcd.LOG';size=[long]32768;sha='C8BFF340EB83585BAE8564077BABA4F3093AE1A15C0649D2E407B94DBC7CA1D1';receipt='934B68C1E4568364083A302D2AEB8EB00452DBC163B64CBA8AFB6AE8D976ED41'}
 [pscustomobject]@{mode='BIOS_LOG';rel='boot\bcd.LOG';size=[long]32768;sha='B97E5FA9AA83C992CA2FC68E1A2818E7E7156D88636C75AE16DC6EFFC25EE03F';receipt='E104E39BBC1DCB31A8191F89D1DC5529A51F0584B779DF007FC984949F255BD0'}
 [pscustomobject]@{mode='BOOT_SDI';rel='boot\boot.sdi';size=[long]3170304;sha='CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD';receipt='B62C355B6E3D440DA2E3F61B1B5BEF91A4C9C476BD36B9720FF24C1FDC23E1D0'}
)
$r=[ordered]@{
 schema='BlueLite.R038.OP114.FinalStageEmptyPhysical.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD';script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 receipt_count=0;receipts=@();all_target_absent=$null
 stage_file_count=$null;stage_dir_count=$null
 original_efi_bcd_absent=$null;original_bios_bcd_absent=$null
 prior_efi_bcd_receipt_sha256=$null;prior_bios_bcd_receipt_sha256=$null
 source_iso_bytes=$null;source_iso_sha256=$null
 guest_baseline=$null;guest_control=$null;mounted_wim_count=$null;error=$null
}
try {
 $s=Get-Item -LiteralPath $stage -Force -ErrorAction Stop
 if(-not $s.PSIsContainer -or (($s.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)){throw 'STAGE_ROOT_INVALID'}
 $dirs=@(Get-ChildItem -LiteralPath $stage -Directory -Recurse -Force -ErrorAction Stop)
 $r.stage_dir_count=$dirs.Count
 foreach($dir in $dirs){if(($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw ('STAGE_REPARSE_DIR_'+$dir.FullName)}}
 $members=@(Get-ChildItem -LiteralPath $stage -File -Recurse -Force -ErrorAction Stop)
 $r.stage_file_count=$members.Count
 if($members.Count -ne 0){throw 'STAGE_REGULAR_FILES_NOT_EMPTY'}
 $allAbsent=$true
 for($i=0;$i -lt $items.Count;$i++){
  $item=$items[$i]
  $target=Join-Path $stage $item.rel
  $exists=[IO.File]::Exists($target)
  if($exists){$allAbsent=$false;throw ('EXTRACTED_TARGET_REAPPEARED_'+$item.mode)}
  $receiptPath=Join-Path $logs ('R038_66_'+$item.mode+'_Result.json')
  $sha=(Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256 -ErrorAction Stop).Hash
  if($sha -ne $item.receipt){throw ('RECEIPT_SHA_'+$item.mode)}
  $j=Get-Content -LiteralPath $receiptPath -Raw -ErrorAction Stop|ConvertFrom-Json
  if($j.schema -ne 'BlueLite.R038.OwnedLeafCleanup.v1' -or $j.status -ne 'ONE_OWNED_LEAF_DELETED' -or $j.mode -ne $item.mode){throw ('RECEIPT_SCHEMA_'+$item.mode)}
  if(-not [string]::Equals([string]$j.target_path,$target,[StringComparison]::OrdinalIgnoreCase) -or [long]$j.target_bytes -ne $item.size -or [string]$j.target_sha256 -ne $item.sha){throw ('RECEIPT_TARGET_'+$item.mode)}
  if([long]$j.stage_before -ne (7-$i) -or [long]$j.stage_after -ne (6-$i) -or [string]$j.script_sha256 -ne $engineSha -or $j.actual_target_absent -ne $true){throw ('RECEIPT_ORDER_OR_ENGINE_'+$item.mode)}
  $r.receipts += [ordered]@{mode=$item.mode;sha256=$sha;bytes=[long]$item.size;physically_absent=$true}
 }
 $r.receipt_count=$r.receipts.Count
 $r.all_target_absent=$allAbsent
 $r.original_efi_bcd_absent=-not ([IO.File]::Exists((Join-Path $stage 'efi\microsoft\boot\bcd')))
 $r.original_bios_bcd_absent=-not ([IO.File]::Exists((Join-Path $stage 'boot\bcd')))
 if(-not $r.original_efi_bcd_absent -or -not $r.original_bios_bcd_absent){throw 'ORIGINAL_BCD_WORKCOPY_REAPPEARED'}
 $r.prior_efi_bcd_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteEFI_BCD.json') -Algorithm SHA256).Hash
 $r.prior_bios_bcd_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteBIOS_BCD.json') -Algorithm SHA256).Hash
 if($r.prior_efi_bcd_receipt_sha256 -ne 'CD2BA5589EDB30D31D72574F0C628E4E5E8E92725A7AE77EC6364CF3C2EC1F80' -or $r.prior_bios_bcd_receipt_sha256 -ne 'E64D196FA81C124046324BF0F7934CCEB09163B23B7E2E977FBA782B63298680'){throw 'ORIGINAL_BCD_RECEIPTS_CHANGED'}
 $originalReceipt=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $originalReceipt -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B'){throw 'EXTRACT_RECEIPT_CHANGED'}
 $iso=[string]((Get-Content -LiteralPath $originalReceipt -Raw|ConvertFrom-Json).original_iso_path)
 if(-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)){throw 'ORIGINAL_ISO_PATH_NOT_ALLOWED'}
 $isoFile=Get-Item -LiteralPath $iso -ErrorAction Stop
 if(($isoFile.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0){throw 'SOURCE_ISO_REPARSE'}
 $r.source_iso_bytes=[long]$isoFile.Length
 if($r.source_iso_bytes -ne 6749851648){throw 'ORIGINAL_ISO_SIZE'}
 $r.source_iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if($r.source_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'ORIGINAL_ISO_SHA'}
 $base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $ctl=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $r.guest_baseline=([string]$base.State)+'/'+([string](Get-VMFirmware -VMName $base.Name).SecureBoot)
 $r.guest_control=([string]$ctl.State)+'/'+([string](Get-VMFirmware -VMName $ctl.Name).SecureBoot)
 if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $ctl.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $r.guest_baseline -ne 'Running/On' -or $r.guest_control -ne 'Off/Off'){throw 'DEVELOPMENT_GUEST_STATE_CHANGED'}
 $r.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($r.mounted_wim_count -ne 0){throw 'MOUNTED_WIM_EXISTS'}
 $r.status='INDEPENDENT_ALL_SEVEN_OWNED_STAGE_LEAVES_REMOVED_ORIGINAL_ISO_VM_PASS'
}
catch{$r.error=$_.Exception.Message}
$r|ConvertTo-Json -Depth 7
if($r.status -ne 'INDEPENDENT_ALL_SEVEN_OWNED_STAGE_LEAVES_REMOVED_ORIGINAL_ISO_VM_PASS'){exit 2}
exit 0
