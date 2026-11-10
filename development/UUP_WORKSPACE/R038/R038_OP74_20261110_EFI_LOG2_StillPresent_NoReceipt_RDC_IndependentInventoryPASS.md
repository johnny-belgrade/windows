# R038 OP74 — RDC independent filesystem inventory proves EFI_LOG2 STILL PRESENT / no producer receipt — HOLD
Date 2026-11-10. OP73 PREPLAN Git `02b5f602efa1f37bbefaaafc9cf0e5421113f845` independently readback BEFORE read-only native RDC inventory. NO PowerShell command, NO file deletion, NO VM or user ISO mutation this OP.
Results of independent built-in RDC `list_directory` stage exact `C:\work\_UUP\R038_IsolatedBootBenchmark_26300\BlueLite_Logs\R038_14_ISO_BCD_SDI`: **SEVEN original observed files still exist**, exactly
```
boot\bcd.LOG
boot\bcd.LOG1
boot\bcd.LOG2
boot\boot.sdi
efi\microsoft\boot\bcd.LOG
efi\microsoft\boot\bcd.LOG1
efi\microsoft\boot\bcd.LOG2
```
Independent built-in `get_file_info` exact `efi\microsoft\boot\bcd.LOG2`: **size 0**, regular file (not a directory), created and last modified **2026-11-09T18:31:21.863Z**, permissions 666, unchanged since OP62; `boot\boot.sdi` remains original **3,170,304 B**, created 18:27:36.765Z, last modified 2026-10-26. Built-in `list_directory` exact `BlueLite_Logs` root confirms **NO `R038_66_EFI_LOG2_Result.json`**; only earlier original `R038_15_DeleteBIOS_BCD.json`, `R038_15_DeleteEFI_BCD.json` present. Therefore PID7072 failure at source line68 genuinely occurred BEFORE any deletion or receipt create; target remained present; no phantom cleanup success or outside file action. The producer did apparently traverse initial seven stage members successfully.
**Status `PREDELETE_GET_ITEM_FAILED_BUT_DIRECTORY_EXACT_FILE_PRESENT / OWNED_STAGE_SEVEN_INTACT`**. RCA still unresolved: PowerShell Get-Item direct path vs listing/file stream API discrepancy, perhaps path/provider metadata; no ungrounded assertion of Windows reason. No new safety/refusal issue, no need three blind retries. Original protected ISO SHA and guest states remain last independently PASS from OP64, not rehashed during this RDC inventory.
**ONE NEXT:** source+Git-preplanned transparent **native read-only API differential** on ONLY this exact zero-byte file: compare `Get-ChildItem` metadata, `Get-Item -LiteralPath` result/exception, `[IO.File]::Exists`, `[IO.File]::GetAttributes`, size/hash read, exact file URI and reparse flag, no mutation. Freeze standalone script source, local SHA/AST0 and readback, one normal execution, immutable POST/fetch. Do not run cleanup again until diagnosis, own script plan and fresh proof. Parallel PRE_MAX install.wim and Hyper-V installed host release contract remain OPEN.
