# R038 OP66 — PREPLAN freeze 7-leaf SHA-bound assistant-owned stage cleanup engine (SOURCE_ONLY, NO EXECUTION)
Date 2026-11-10. Owner explicitly approved follow-through with protocol and per-operation writes. Live Current Git SHA `7243fee7295938198f65719ab0f63ceb49ca57bc`, independently fetched; native R038 OP64 independent physical proof `2cd90f442dcdf05d2e93c17722602b7ad40396bf` independently fetched; original R035 6,749,851,648B ISO SHA `54719935DBB05261D562DE964635E934E1D066975E1AAB8334D67CF6F7EE2CEC` and R035 WIMs, Golden, VHDX, host BCD/EFI MUST remain unchanged. Master protected SHA `3b32f372267fb6fb8fbdb5430476d915c4054c83`.
## Exact source-only scope and sequence
Author one generic explicit seven-entry allowlist cleanup PS7 source `development/UUP_WORKSPACE/R038/scripts/R038_66_CleanupOwnedStageLeaf.ps1` with fixed root `C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs\R038_14_ISO_BCD_SDI`. Entries:
- `EFI_LOG2` `efi\microsoft\boot\bcd.LOG2` 0B SHA `E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855`
- `EFI_LOG1` `efi\microsoft\boot\bcd.LOG1` 0B same SHA;
- `BIOS_LOG2` `boot\bcd.LOG2` 0B same SHA;
- `BIOS_LOG1` `boot\bcd.LOG1` 0B same SHA;
- `EFI_LOG` `efi\microsoft\boot\bcd.LOG` 32768B SHA `C8BFF340EB83585BAE8564077BABA4F3093AE1A15C0649D2E407B94DBC7CA1D1`;
- `BIOS_LOG` `boot\bcd.LOG` 32768B SHA `B97E5FA9AA83C992CA2FC68E1A2818E7E7156D88636C75AE16DC6EFFC25EE03F`;
- `BOOT_SDI` `boot\boot.sdi` 3170304B SHA `CD2C00CE027687CE4A8BDC967F26A8AB82F651C9BECD703658BA282EC49702BD`, LAST only once six LOGs absent and 6 valid independent receipts exist.

The engine is SHA/source/ownership-gated; command `-Mode` MUST target one exact file, with entire remaining stage exactly matching allowlist expected SHA/bytes, no unexpected extra or reparse. Every invocation hashes original ISO and verifies two BCD original deletion receipt SHAs, original extraction receipt, guest statuses and WIM mount 0; verifies previous sidecar deletion receipt (all previous modes) before accepting a later step. Emits unique JSON receipt outside stage under `BlueLite_Logs\R038_66_<MODE>_Result.json` exclusively CreateNew, after **one** leaf delete and fixed stage absent validation; no folder/wildcard delete. Never modify/delete original ISO, source artifacts, VM state, host registry, security settings. Source should be written once then readback exact.

Each mode requires its OWN distinct Git PREEXEC and fresh independent fetch, one single native PS7 execution, separate native independent receipt/target absence+keeper ISO SHA and stage survivor audits, a Git POST and independent fetch, Current CAS as required BEFORE following mode. No pipeline bulk execution or safety bypass. Any permission denial or unexpected stage/lock -> immediate HOLD, no retry of irreversible deletion; ordinary R/W connection failures max 3, platform safety refusal first time terminal.
## ONE NEXT
Freeze implementation source and separately readback Git, then first target `EFI_LOG2` PREEXEC with full script SHA, physical preflight; after each individual documented proof continue only when PASS. No other mutation in this OP. Hyper-V installed BlueLite host release gate and parallel source install.wim + UEFI/boot remain open, not tested by cleanup.
