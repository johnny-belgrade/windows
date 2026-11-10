# R038 OP99 independent verifier for BIOS_LOG1: SHA checks ONLY, no mutation.
$ErrorActionPreference='Stop'
$root='C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs=Join-Path $root 'BlueLite_Logs'
$stage=Join-Path $logs 'R038_14_ISO_BCD_SDI'
$empty='E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
$expected=@(
 [pscustomobject]@{rel='efi\microsoft\boot\bcd.LOG';bytes=[long]32768;sha='C8BFF340EB83585BAE8564077BABA4F3093AE1A15C0649D2E407B94DBC7CA1D1'}
 [pscustomobject]@{rel='boot\bcd.LOG';bytes=[long]32768;sha='B97E5FA9AA83C992CA2FC68E1A2818E7E7156D88636C75AE16DC6EFFC25EE03F'}
 [pscustomobject]@{rel='boot\boot.sdi';bytes=[long]3170304;sha='CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD'}
)
$r=[ordered]@{
 schema='BlueLite.R038.OP99.IndependentOneLeafPost.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 audit_script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 receipt_sha256=$null;receipt_status=$null;receipt_mode=$null;previous_receipt_sha256=$null;previous_efi_log1_receipt_sha256=$null;previous_bios_log2_receipt_sha256=$null
 target_absent=$null;previous_efi_log2_absent=$null;previous_efi_log1_absent=$null;previous_bios_log2_absent=$null; original_efi_bcd_absent=$null;original_bios_bcd_absent=$null
 stage_count=$null;survivors=@()
 source_iso_bytes=$null;source_iso_sha256=$null
 guest_baseline=$null;guest_control=$null
 mounted_wim_count=$null;error=$null
}
try {
 $receiptPath=Join-Path $logs 'R038_66_BIOS_LOG1_Result.json'
 $r.receipt_sha256=(Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256).Hash
 if ($r.receipt_sha256 -ne '10FFBC6694A17FAB6F2119AAE38A34D6D3489C52AF1D67FBC23C0E097197A761') {throw 'RECEIPT_SHA_CHANGED'}
 $j=Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
 $r.receipt_status=[string]$j.status
 $r.receipt_mode=[string]$j.mode
 $target=Join-Path $stage 'boot\bcd.LOG1'
 if ($j.schema -ne 'BlueLite.R038.OwnedLeafCleanup.v1' -or $r.receipt_status -ne 'ONE_OWNED_LEAF_DELETED' -or $r.receipt_mode -ne 'BIOS_LOG1') {throw 'RECEIPT_SCHEMA_STATUS_MODE_MISMATCH'}
 if (-not [string]::Equals([string]$j.target_path,$target,[StringComparison]::OrdinalIgnoreCase) -or [long]$j.target_bytes -ne 0 -or [string]$j.target_sha256 -ne $empty -or [long]$j.stage_before -ne 4 -or [long]$j.stage_after -ne 3) {throw 'RECEIPT_EXACT_TARGET_OR_STAGE_MISMATCH'}
 if ([string]$j.script_sha256 -ne 'D0B09B655BCA1672B66876B25DFB315ABD993118F39C556A07A7BD0A07E3C21E') {throw 'RECEIPT_ENGINE_SHA_MISMATCH'}
 $r.target_absent=-not ([IO.File]::Exists($target))
 $r.previous_efi_log2_absent=-not ([IO.File]::Exists((Join-Path $stage 'efi\microsoft\boot\bcd.LOG2')))
 $r.previous_efi_log1_absent=-not ([IO.File]::Exists((Join-Path $stage 'efi\microsoft\boot\bcd.LOG1')))
 $r.previous_bios_log2_absent=-not ([IO.File]::Exists((Join-Path $stage 'boot\bcd.LOG2')))
 $r.previous_bios_log2_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_66_BIOS_LOG2_Result.json') -Algorithm SHA256).Hash
 if($r.previous_bios_log2_receipt_sha256 -ne '34816F396F300AE86B696A8033B391FFAF054640489998BFD8B7B36F4B405DD9'){throw 'PREVIOUS_BIOS_LOG2_RECEIPT_SHA_CHANGED'}
 $r.previous_efi_log1_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_66_EFI_LOG1_Result.json') -Algorithm SHA256).Hash
 if($r.previous_efi_log1_receipt_sha256 -ne '682050CF46C3EDC98ECB3966BF1F2EA8892AD253D9158F982301CE3364D77974'){throw 'PREVIOUS_EFI_LOG1_RECEIPT_SHA_CHANGED'}
 $r.previous_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_66_EFI_LOG2_Result.json') -Algorithm SHA256).Hash
 if($r.previous_receipt_sha256 -ne 'AA7CA233F8E4ABB5F16E3C9A4CFEFA0F9AD68A068F59E4111DA29A914D4FB1F2'){throw 'PREVIOUS_RECEIPT_SHA_CHANGED'}
 $r.original_efi_bcd_absent=-not ([IO.File]::Exists((Join-Path $stage 'efi\microsoft\boot\bcd')))
 $r.original_bios_bcd_absent=-not ([IO.File]::Exists((Join-Path $stage 'boot\bcd')))
 if (-not $r.target_absent -or -not $r.previous_efi_log2_absent -or -not $r.previous_efi_log1_absent -or -not $r.previous_bios_log2_absent -or -not $r.original_efi_bcd_absent -or -not $r.original_bios_bcd_absent) {throw 'BCD_WORKCOPY_OR_TARGET_REAPPEARED'}
 $present=@(Get-ChildItem -LiteralPath $stage -Recurse -Force -File -ErrorAction Stop)
 $r.stage_count=$present.Count
 if ($present.Count -ne 3) {throw 'STAGE_SURVIVOR_COUNT_NOT_THREE'}
 foreach($fi in $present) {
  $matching=@($expected|Where-Object { [string]::Equals((Join-Path $stage $_.rel),$fi.FullName,[StringComparison]::OrdinalIgnoreCase) })
  if($matching.Count -ne 1) {throw ('UNEXPECTED_STAGE_MEMBER_'+$fi.FullName)}
  $e=$matching[0]
  if ([long]$fi.Length -ne $e.bytes -or (($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) {throw ('SURVIVOR_SIZE_LINK_'+$e.rel)}
  $sha=(Get-FileHash -LiteralPath $fi.FullName -Algorithm SHA256).Hash
  if($sha -ne $e.sha) {throw ('SURVIVOR_SHA_'+$e.rel)}
  $r.survivors += [ordered]@{rel=$e.rel;bytes=[long]$fi.Length;sha256=$sha}
 }
 $extract=Join-Path $logs 'R038_14_Extract_Result.json'
 if((Get-FileHash -LiteralPath $extract -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B') {throw 'EXTRACTION_RECEIPT_SHA'}
 $iso=[string]((Get-Content -LiteralPath $extract -Raw|ConvertFrom-Json).original_iso_path)
 if(-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)) {throw 'UNEXPECTED_SOURCE_ISO_PATH'}
 $item=Get-Item -LiteralPath $iso -ErrorAction Stop
 if(($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {throw 'SOURCE_ISO_REPARSE'}
 $r.source_iso_bytes=[long]$item.Length
 if($r.source_iso_bytes -ne 6749851648){throw 'SOURCE_ISO_SIZE'}
 $r.source_iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if($r.source_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'){throw 'SOURCE_ISO_SHA'}
 $base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
 $ctrl=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
 $r.guest_baseline=([string]$base.State)+'/'+([string](Get-VMFirmware -VMName $base.Name).SecureBoot)
 $r.guest_control=([string]$ctrl.State)+'/'+([string](Get-VMFirmware -VMName $ctrl.Name).SecureBoot)
 if($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or $ctrl.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or $r.guest_baseline -ne 'Running/On' -or $r.guest_control -ne 'Off/Off'){throw 'GUEST_STATES_CHANGED'}
 $r.mounted_wim_count=@(Get-WindowsImage -Mounted -ErrorAction Stop).Count
 if($r.mounted_wim_count -ne 0){throw 'MOUNTED_WIM_EXISTS'}
 $r.status='INDEPENDENT_BIOS_LOG1_ONE_LEAF_PHYSICAL_PASS'
}
catch {$r.error=$_.Exception.Message}
$r|ConvertTo-Json -Depth 7
if($r.status -ne 'INDEPENDENT_BIOS_LOG1_ONE_LEAF_PHYSICAL_PASS'){exit 2}
exit 0
