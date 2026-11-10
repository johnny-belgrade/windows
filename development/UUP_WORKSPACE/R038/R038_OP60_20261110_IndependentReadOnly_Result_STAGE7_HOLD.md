# R038 OP60 — independent read-only verifier ACTUAL executed, STAGE_FILE_COUNT_7 versus 1, HOLD
Date 2026-11-10 (Europe/Belgrade). Preplan Git blob `ef437dbc0b3f6fa685572a98941d2c73a2fef368`; new non-mutating verifier source Git blob `7255ac2b4a202793e313a0b639ce31894128b017` fetched/compared with exact local `C:\work\scripts\R038_60_IndependentReadOnlyPostcheck.ps1` prior to execution (one missing trailing LF on first RDC write; explicit append LF then second complete RDC readback proved byte-for-byte exact). Source local native self-SHA **FB77CA0D5A2F922054DA618B305B3BDB3A9B80F8DD3ACA45137E5542700B5E2E**, produced by script; Git is blob SHA, not a SHA256 assertion.
## ONE native observation — no change to source media/VM
RDC `start_process` called `pwsh.exe -NoProfile -NonInteractive -File "C:\work\scripts\R038_60_IndependentReadOnlyPostcheck.ps1"` ONCE, Windows PID **8292**, tool reported process finished execution. Script JSON stdout:
```json
{
  "schema":"BlueLite.R038.OP60.IndependentReadOnlyPostcheck.v1",
  "utc":"2026-11-10T12:10:14.9170150Z",
  "status":"HOLD",
  "verifier_sha256":"FB77CA0D5A2F922054DA618B305B3BDB3A9B80F8DD3ACA45137E5542700B5E2E",
  "bios_receipt_sha256":"E64D196FA81C124046324BF0F7934CCEB09163B23B7E2E977FBA782B63298680",
  "efi_receipt_sha256":"CD2BA5589EDB30D31D72574F0C628E4E5E8E92725A7AE77EC6364CF3C2EC1F80",
  "bios_bcd_absent":true,
  "efi_bcd_absent":true,
  "stage_file_count":7,
  "sdi_bytes":null,
  "sdi_sha256":null,
  "original_iso_path":null,
  "original_iso_bytes":null,
  "original_iso_sha256":null,
  "baseline_state":null,
  "baseline_secureboot":null,
  "control_state":null,
  "control_secureboot":null,
  "mounted_wim_count":null,
  "error":"STAGE_NOT_EXACTLY_ONE_FILE"
}
```
Tool did **not expose an independent process exit code** in its response; script source intentionally exits 2 on `HOLD`. Do not promote to full independent PASS.
## Evidence classification
- **New partial independent physical PASS**: original PID7592 claimed BIOS receipt SHA exists and matches fixed SHA; EFI receipt still matches; disposable BIOS BCD absent; disposable EFI BCD absent (all measured by new PID8292). This confirms the two BCD absence claims but **does not** certify total 3-source-file stage clean because 7 recursive files were found.
- **NEW ACTIVE HOLD**: fixed stage `C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs\R038_14_ISO_BCD_SDI` contained **seven** recursive regular files, not one. The script intentionally STOPPED before individually hashing SDI, original full R035 ISO or checking guest and mounted-WIM state. Therefore those fields remain NOT_CHECKED in this OP, last applicable older SHA proofs still R038 OP57.
- The extra six files may be legitimate unrelated owner outputs or unexpected stage drift; **do not guess or delete**. No changes to Master, original ISO/WIM/Golden, BCD/EFI or Hyper-V guest; no existing receipt overwritten. No platform safety check blocked OP60: this is a verifiable physical **content HOLD**, different from OP59 prior safety HOLD. User-requested no bypass applied.
## Exactly ONE NEXT
Perform **separately preplanned read-only listing of the 7 files with exact full path, size, reparse/owner hints** through ordinary RDC directory inventory, independently read and Git record. Determine whether OP60 cardinality assumption was overspecified, or genuinely foreign file contamination, before rewriting verifier or permitting any cleanup. Never switch to deletion, VM modification or unreviewed extra ISO. Preserve final-size and installed BlueLite Hyper-V HOST release gates from R039 OP01. Protocol individual write/readback before inspecting next operation.
