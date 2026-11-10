# BlueLite R038_66 exactly ONE SHA-bound disposable stage LEAF deletion per invocation.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('EFI_LOG2','EFI_LOG1','BIOS_LOG2','BIOS_LOG1','EFI_LOG','BIOS_LOG','BOOT_SDI')][string]$Mode)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\work\_UUP\R038_IsolatedBootBenchmark_26300'
$logs = Join-Path $root 'BlueLite_Logs'
$stage = Join-Path $logs 'R038_14_ISO_BCD_SDI'
$empty = 'E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855'
$items = @(
 [pscustomobject]@{mode='EFI_LOG2'; rel='efi\microsoft\boot\bcd.LOG2'; bytes=[long]0; sha=$empty},
 [pscustomobject]@{mode='EFI_LOG1'; rel='efi\microsoft\boot\bcd.LOG1'; bytes=[long]0; sha=$empty},
 [pscustomobject]@{mode='BIOS_LOG2'; rel='boot\bcd.LOG2'; bytes=[long]0; sha=$empty},
 [pscustomobject]@{mode='BIOS_LOG1'; rel='boot\bcd.LOG1'; bytes=[long]0; sha=$empty},
 [pscustomobject]@{mode='EFI_LOG'; rel='efi\microsoft\boot\bcd.LOG'; bytes=[long]32768; sha='C8BFF340EB83585BAE8564077BABA4F3093AE1A15C0649D2E407B94DBC7CA1D1'},
 [pscustomobject]@{mode='BIOS_LOG'; rel='boot\bcd.LOG'; bytes=[long]32768; sha='B97E5FA9AA83C992CA2FC68E1A2818E7E7156D88636C75AE16DC6EFFC25EE03F'},
 [pscustomobject]@{mode='BOOT_SDI'; rel='boot\boot.sdi'; bytes=[long]3170304; sha='CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD'}
)
$idx = -1
for ($i=0; $i -lt $items.Count; $i++) { if ($items[$i].mode -eq $Mode) { $idx=$i; break } }
if ($idx -lt 0) { throw 'INVALID_MODE' }
$stageDir = Get-Item -LiteralPath $stage -ErrorAction Stop
if (-not $stageDir.PSIsContainer -or (($stageDir.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw 'STAGE_DIR_INVALID' }
$extract = Join-Path $logs 'R038_14_Extract_Result.json'
if ((Get-FileHash -LiteralPath $extract -Algorithm SHA256).Hash -ne '6F27FBFE4C5B93023096579DABC31A0B0F1DCF7159DCCC54CE9902678D253B0B') { throw 'ORIGINAL_EXTRACTION_RECEIPT_SHA_CHANGED' }
$x = Get-Content -LiteralPath $extract -Raw | ConvertFrom-Json
if ($x.status -ne 'EXTRACTED_THREE_SOURCE_ISO_BOOT_FILES_SHA_PASS' -or $x.files.Count -ne 3) { throw 'EXTRACTION_RECEIPT_SCHEMA' }
$iso = [string]$x.original_iso_path
if (-not $iso.StartsWith('C:\work\_UUP\R035_Universal_PREMAX_26300\BlueLite_Work\',[StringComparison]::OrdinalIgnoreCase) -or -not $iso.EndsWith('.ISO',[StringComparison]::OrdinalIgnoreCase)) { throw 'SOURCE_ISO_OUT_OF_BOUND' }
$isoFile = Get-Item -LiteralPath $iso -ErrorAction Stop
if ($isoFile.Length -ne 6749851648 -or (($isoFile.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw 'SOURCE_ISO_FILE_CHANGED' }
if ((Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash -ne '54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC') { throw 'SOURCE_ISO_SHA_CHANGED' }
if ((Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteEFI_BCD.json')).Hash -ne 'CD2BA5589EDB30D31D72574F0C628E4E5E8E92725A7AE77EC6364CF3C2EC1F80') { throw 'ORIGINAL_EFI_RECEIPT_CHANGED' }
if ((Get-FileHash -LiteralPath (Join-Path $logs 'R038_15_DeleteBIOS_BCD.json')).Hash -ne 'E64D196FA81C124046324BF0F7934CCEB09163B23B7E2E977FBA782B63298680') { throw 'ORIGINAL_BIOS_RECEIPT_CHANGED' }
if ((Test-Path -LiteralPath (Join-Path $stage 'boot\bcd')) -or (Test-Path -LiteralPath (Join-Path $stage 'efi\microsoft\boot\bcd'))) { throw 'ORIGINAL_BCD_WORKCOPY_REAPPEARED' }
$base=Get-VM -Id 'c7536cc4-68f5-473a-9818-4053ba8794b2' -ErrorAction Stop
$ctl=Get-VM -Id 'deb10ab5-3093-47a8-9a13-f3927446c606' -ErrorAction Stop
if ($base.Name -ne 'BlueLite-R038-UEFI-Baseline' -or [string]$base.State -ne 'Running' -or [string](Get-VMFirmware -VMName $base.Name).SecureBoot -ne 'On') { throw 'BASELINE_VM_CHANGED' }
if ($ctl.Name -ne 'BlueLite-R038-UEFI-SBOff-Control' -or [string]$ctl.State -ne 'Off' -or [string](Get-VMFirmware -VMName $ctl.Name).SecureBoot -ne 'Off') { throw 'CONTROL_VM_CHANGED' }
if (@(Get-WindowsImage -Mounted -ErrorAction Stop).Count -ne 0) { throw 'MOUNTED_WIM_PRESENT' }
if ([long](Get-PSDrive C).Free -lt 75000000000) { throw 'HOST_DISK_FREE_BELOW_75GB' }
# Completed earlier modes must have fixed receipts and physically absent leafs.
for ($i=0; $i -lt $idx; $i++) {
 $prior=$items[$i]
 $oldPath=Join-Path $stage $prior.rel
 if (Test-Path -LiteralPath $oldPath) { throw ('EARLIER_OWNED_LEAF_STILL_PRESENT_'+$prior.mode) }
 $priorReceipt=Join-Path $logs ('R038_66_'+$prior.mode+'_Result.json')
 $pj=Get-Content -LiteralPath $priorReceipt -Raw -ErrorAction Stop|ConvertFrom-Json
 if ($pj.status -ne 'ONE_OWNED_LEAF_DELETED' -or $pj.mode -ne $prior.mode -or $pj.target_sha256 -ne $prior.sha -or $pj.target_bytes -ne $prior.bytes) { throw ('PRIOR_RECEIPT_INVALID_'+$prior.mode) }
}
# Exact present members (current and future in ordered source-bound array) only.
$actual=@(Get-ChildItem -LiteralPath $stage -Recurse -Force -File -ErrorAction Stop)
$expectedCount=$items.Count-$idx
if ($actual.Count -ne $expectedCount) { throw ('STAGE_COUNT_DRIFT_'+$actual.Count+'_EXPECTED_'+$expectedCount) }
foreach ($f in $actual) {
 $entry=@($items|Where-Object {[string]::Equals((Join-Path $stage $_.rel),$f.FullName,[StringComparison]::OrdinalIgnoreCase)})
 if ($entry.Count -ne 1 -or @($items|Where-Object {$_.mode -eq $entry[0].mode})[0].mode -eq $null) { throw ('FOREIGN_STAGE_LEAF_'+$f.FullName) }
 $e=$entry[0]
 $pos=[array]::IndexOf(@($items.mode),$e.mode)
 if ($pos -lt $idx) { throw ('ALREADY_DELETED_FILE_REAPPEARED_'+$e.mode) }
 if ($f.Length -ne $e.bytes -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0)) { throw ('STAGE_LEAF_SIZE_OR_LINK_DRIFT_'+$e.mode) }
 if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne $e.sha) { throw ('STAGE_LEAF_SHA_DRIFT_'+$e.mode) }
}
$selected=$items[$idx]
$target=Join-Path $stage $selected.rel
$receiptPath=Join-Path $logs ('R038_66_'+$Mode+'_Result.json')
if (Test-Path -LiteralPath $receiptPath) { throw 'OWNED_RECEIPT_ALREADY_EXISTS_NO_REPEAT' }
$f=Get-Item -LiteralPath $target -ErrorAction Stop
if ($f.PSIsContainer -or $f.Length -ne $selected.bytes -or (($f.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) -or (Get-FileHash -LiteralPath $target).Hash -ne $selected.sha) { throw 'TARGET_IS_NOT_EXACT_SHA_BOUND_LEAF' }
$parent=$f.Directory
while ($null -ne $parent -and $parent.FullName.StartsWith($stage,[StringComparison]::OrdinalIgnoreCase)) {
 if (($parent.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'PARENT_REPARSE_NOT_ALLOWED' }
 $parent=$parent.Parent
}
$before=[long](Get-PSDrive C).Free
# EXACTLY ONE irreversible deletion, of ONE assistant-owned extracted/created stage leaf.
[IO.File]::Delete($target)
if (Test-Path -LiteralPath $target) { throw 'TARGET_STILL_PRESENT_AFTER_DELETE' }
$after=@(Get-ChildItem -LiteralPath $stage -Recurse -Force -File -ErrorAction Stop)
if ($after.Count -ne ($expectedCount-1)) { throw 'POST_SINGLE_DELETE_COUNT_INVALID' }
$j=[ordered]@{
 schema='BlueLite.R038.OwnedLeafCleanup.v1'
 mode=$Mode; status='ONE_OWNED_LEAF_DELETED'
 utc=[datetime]::UtcNow.ToString('o')
 script_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash
 target_path=$target
 target_sha256=$selected.sha
 target_bytes=$selected.bytes
 actual_target_absent=$true
 stage_before=$expectedCount
 stage_after=$after.Count
 source_iso_sha256='54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC'
 protected_iso_bytes=6749851648
 vm_baseline='Running/SecureBootOn'
 vm_control='Off/SecureBootOff'
 wim_mount_count=0
 free_c_before=$before
 free_c_after=[long](Get-PSDrive C).Free
}
$json=$j|ConvertTo-Json -Depth 7
$raw=[Text.UTF8Encoding]::new($false).GetBytes($json+[Environment]::NewLine)
$h=[IO.File]::Open($receiptPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
try {$h.Write($raw)}finally {$h.Dispose()}
Write-Output ('R038_66_'+$Mode+'_ONE_LEAF_PASS target='+$target+' bytes='+$selected.bytes+' sha='+$selected.sha+' receiptSHA='+(Get-FileHash -LiteralPath $receiptPath).Hash+' stage_after='+$after.Count)
