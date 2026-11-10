# R038 OP60: NON-MUTATING, independently rerunnable only when platform permits.
# Reads exact local proof; no deletion, guest power change, BCD calls, WIM mount, or security alteration.
$ErrorActionPreference = 'Stop'
$root = 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs = Join-Path $root 'BlueLite_Logs'
$stage = Join-Path $logs 'R038_14_ISO_BCD_SDI'
$report = [ordered]@{
 schema='BlueLite.R038.OP60.IndependentReadOnlyPostcheck.v1'
 utc=[DateTime]::UtcNow.ToString('o')
 status='HOLD'
 verifier_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
 bios_receipt_sha256=$null; efi_receipt_sha256=$null
 bios_bcd_absent=$null; efi_bcd_absent=$null
 stage_file_count=$null; sdi_bytes=$null; sdi_sha256=$null
 original_iso_path=$null; original_iso_bytes=$null; original_iso_sha256=$null
 baseline_state=$null; baseline_secureboot=$null
 control_state=$null; control_secureboot=$null
 mounted_wim_count=$null; error=$null
}
try {
 if (-not [string]::Equals($root,'C:\work\_UUP\R038_IsolatedBootBenchmark_26300',[StringComparison]::OrdinalIgnoreCase)) { throw 'OWNED_ROOT_MISMATCH' }
 $extractPath = Join-Path $logs 'R038_14_Extract_Result.json'
 if ((Get-FileHash -LiteralPath $extractPath -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B') { throw 'EXTRACT_RECEIPT_SHA' }
 $extract = Get-Content -LiteralPath $extractPath -Raw | ConvertFrom-Json
 $original = [string]$extract.original_iso_path
 if (-not $original.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $original.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)) { throw 'ISO_NOT_PROTECTED_SOURCE' }
 $biosReceipt = Join-Path $logs 'R038_15_DeleteBIOS_BCD.json'
 $efiReceipt = Join-Path $logs 'R038_15_DeleteEFI_BCD.json'
 $report.bios_receipt_sha256 = (Get-FileHash -LiteralPath $biosReceipt -Algorithm SHA256).Hash
 $report.efi_receipt_sha256 = (Get-FileHash -LiteralPath $efiReceipt -Algorithm SHA256).Hash
 if ($report.bios_receipt_sha256 -ne 'E64D196FA81C124046324BF0F7934CCEB09163B23B7E2E977FBA782B63298680') { throw 'BIOS_RECEIPT_SHA_MISMATCH' }
 if ($report.efi_receipt_sha256 -ne 'CD2BA5589EDB30D31D72574F0C628E4E5E8E92725A7AE77EC6364CF3C2EC1F80') { throw 'EFI_RECEIPT_SHA_MISMATCH' }
 $null = Get-Content -LiteralPath $biosReceipt -Raw | ConvertFrom-Json
 $report.bios_bcd_absent = -not (Test-Path -LiteralPath (Join-Path $stage 'boot\bcd') -PathType Leaf)
 $report.efi_bcd_absent = -not (Test-Path -LiteralPath (Join-Path $stage 'efi\microsoft\boot\bcd') -PathType Leaf)
 if (-not $report.bios_bcd_absent -or -not $report.efi_bcd_absent) { throw 'WORKCOPY_BCD_STILL_PRESENT' }
 $files = @(Get-ChildItem -LiteralPath $stage -Recurse -Force -File -ErrorAction Stop)
 $report.stage_file_count = $files.Count
 if ($files.Count -ne 1) { throw 'STAGE_NOT_EXACTLY_ONE_FILE' }
 $sdi = Join-Path $stage 'boot\boot.sdi'
 if (-not [string]::Equals($files[0].FullName,$sdi,[StringComparison]::OrdinalIgnoreCase) -or (($files[0].Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw 'STAGE_SURVIVOR_NOT_OWNED_SDI' }
 $report.sdi_bytes = [int64]$files[0].Length
 $report.sdi_sha256 = (Get-FileHash -LiteralPath $sdi -Algorithm SHA256).Hash
 if ($report.sdi_bytes -ne 3170304 -or $report.sdi_sha256 -ne 'CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD') { throw 'SDI_SHA_OR_SIZE_MISMATCH' }
 $isoItem = Get-Item -LiteralPath $original -ErrorAction Stop
 if (($isoItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'ISO_REPARSE_POINT' }
 $report.original_iso_path = $original
 $report.original_iso_bytes = [int64]$isoItem.Length
 if ($report.original_iso_bytes -ne 6749851648) { throw 'ISO_SIZE_MISMATCH' }
 $report.original_iso_sha256 = (Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash
 if ($report.original_iso_sha256 -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC') { throw 'ORIGINAL_ISO_SHA_MISMATCH' }
 $baseVM = Get-VM -Name 'BlueLite-R038-UEFI-Baseline' -ErrorAction Stop
 $controlVM = Get-VM -Name 'BlueLite-R038-UEFI-SBOff-Control' -ErrorAction Stop
 $report.baseline_state = [string]$baseVM.State
 $report.control_state = [string]$controlVM.State
 $report.baseline_secureboot = [string](Get-VMFirmware -VMName $baseVM.Name -ErrorAction Stop).SecureBoot
 $report.control_secureboot = [string](Get-VMFirmware -VMName $controlVM.Name -ErrorAction Stop).SecureBoot
 if ($report.baseline_state -ne 'Running' -or $report.control_state -ne 'Off' -or $report.baseline_secureboot -ne 'On' -or $report.control_secureboot -ne 'Off') { throw 'VM_GUEST_STATE_DRIFT' }
 $mounts = @(Get-WindowsImage -Mounted -ErrorAction Stop)
 $report.mounted_wim_count = $mounts.Count
 if ($mounts.Count -ne 0) { throw 'WIM_MOUNTS_NONZERO' }
 $report.status='INDEPENDENT_PHYSICAL_READ_ONLY_PASS'
}
catch { $report.error = $_.Exception.Message }
$report | ConvertTo-Json -Depth 5
if ($report.status -ne 'INDEPENDENT_PHYSICAL_READ_ONLY_PASS') { exit 2 }
exit 0
