# R038 OP64 seven fixed members + source ISO + two development guest states, READ ONLY.
$ErrorActionPreference = 'Stop'
$root = 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs = Join-Path $root 'BlueLite_Logs'
$stage = Join-Path $logs 'R038_14_ISO_BCD_SDI'
$expected = [ordered]@{
 'boot\bcd.LOG'=32768
 'boot\bcd.LOG1'=0
 'boot\bcd.LOG2'=0
 'boot\boot.sdi'=3170304
 'efi\microsoft\boot\bcd.LOG'=32768
 'efi\microsoft\boot\bcd.LOG1'=0
 'efi\microsoft\boot\bcd.LOG2'=0
}
$report = [ordered]@{
 schema='BlueLite.R038.OP64.SevenMemberReadOnly.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 stage_files=@()
 actual_stage_file_count=$null
 bios_bcd_absent=$null
 efi_bcd_absent=$null
 bios_delete_receipt_sha256=$null
 efi_delete_receipt_sha256=$null
 protected_iso_bytes=$null
 protected_iso_sha256=$null
 baseline_state=$null
 baseline_secureboot=$null
 control_state=$null
 control_secureboot=$null
 mounted_wim_count=$null
 error=$null
}
try {
 $actual=@(Get-ChildItem -LiteralPath $stage -File -Recurse -Force -ErrorAction Stop)
 $report.actual_stage_file_count=$actual.Count
 if ($actual.Count -ne $expected.Count) { throw 'STAGE_FILE_COUNT_NOT_SEVEN' }
 foreach ($fi in $actual) {
  $rel=$fi.FullName.Substring($stage.Length).TrimStart('\')
  if (-not $expected.Contains($rel)) { throw ('FOREIGN_STAGE_FILE_'+$rel) }
  if ($fi.Length -ne [int64]$expected[$rel]) { throw ('STAGE_FILE_SIZE_'+$rel) }
  if (($fi.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw ('STAGE_REPARSE_'+$rel) }
  $sha=(Get-FileHash -LiteralPath $fi.FullName -Algorithm SHA256).Hash
  if ($rel -eq 'boot\boot.sdi' -and $sha -ne 'CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD') { throw 'SOURCE_SDI_SHA' }
  if ($fi.Length -eq 0 -and $sha -ne 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855') { throw ('ZERO_LOG_SHA_'+$rel) }
  $report.stage_files += [ordered]@{rel=$rel; bytes=[int64]$fi.Length; sha256=$sha}
 }
 $report.bios_bcd_absent= -not (Test-Path -LiteralPath (Join-Path $stage 'boot\bcd') -PathType Leaf)
 $report.efi_bcd_absent= -not (Test-Path -LiteralPath (Join-Path $stage 'efi\microsoft\boot\bcd') -PathType Leaf)
 if (-not $report.bios_bcd_absent -or -not $report.efi_bcd_absent) { throw 'BCD_WORKCOPY_REAPPEARED' }
 $report.bios_delete_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteBIOS_BCD.json') -Algorithm SHA256).Hash
 $report.efi_delete_receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteEFI_BCD.json') -Algorithm SHA256).Hash
 if ($report.bios_delete_receipt_sha256 -ne 'E64D196FA81C124046324BF0F7934CCEB09163B23B7E2E977FBA782B63298680' -or $report.efi_delete_receipt_sha256 -ne 'CD2BA5589EDB30D31D72574F0C628E4E5E8E92725A7AE77EC6364CF3C2EC1F80') { throw 'EXTRACTED_BCD_RECEIPT_SHA' }
 $extract=Join-Path $logs 'R038_14_Extract_Result.json'
 if ((Get-FileHash -LiteralPath $extract -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B') { throw 'ORIGINAL_EXTRACT_RECEIPT_CHANGED' }
 $iso=[string]((Get-Content -LiteralPath $extract -Raw | ConvertFrom-Json).original_iso_path)
 if (-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)) { throw 'ISO_PATH_NOT_APPROVED' }
 $isoFile=Get-Item -LiteralPath $iso -ErrorAction Stop
 if (($isoFile.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'ORIGINAL_ISO_IS_REPARSE' }
 $report.protected_iso_bytes=[int64]$isoFile.Length
 if ($report.protected_iso_bytes -ne 6749851648) { throw 'ISO_BYTES_CHANGED' }
 $report.protected_iso_sha256=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 if ($report.protected_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC') { throw 'ISO_SHA_CHANGED' }
 $base=Get-VM -Name 'BlueLite-R038-UEFI-Baseline' -ErrorAction Stop
 $ctl=Get-VM -Name 'BlueLite-R038-UEFI-SBOff-Control' -ErrorAction Stop
 $report.baseline_state=[string]$base.State
 $report.control_state=[string]$ctl.State
 $report.baseline_secureboot=[string](Get-VMFirmware -VMName $base.Name -ErrorAction Stop).SecureBoot
 $report.control_secureboot=[string](Get-VMFirmware -VMName $ctl.Name -ErrorAction Stop).SecureBoot
 if ($report.baseline_state -ne 'Running' -or $report.control_state -ne 'Off' -or $report.baseline_secureboot -ne 'On' -or $report.control_secureboot -ne 'Off') { throw 'HYPERV_DEVELOPMENT_GUEST_STATE_DRIFT' }
 $mounts=@(Get-WindowsImage -Mounted -ErrorAction Stop)
 $report.mounted_wim_count=$mounts.Count
 if ($report.mounted_wim_count -ne 0) { throw 'WIM_MOUNTS_PRESENT' }
 $report.status='INDEPENDENT_READ_ONLY_7_MEMBER_ISO_VM_PASS'
}
catch { $report.error=$_.Exception.Message }
$report | ConvertTo-Json -Depth 7
if ($report.status -ne 'INDEPENDENT_READ_ONLY_7_MEMBER_ISO_VM_PASS') { exit 2 }
exit 0
