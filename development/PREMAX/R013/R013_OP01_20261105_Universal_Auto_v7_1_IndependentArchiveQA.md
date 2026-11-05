# R013 OP01 — independent full archive and immutable engine QA (BlueLite PRE_MAX AUTO v7.1)
Date 2026-11-05. Scope source/ZIP verification only. Prior source/protocol R013 OP00 `development/PREMAX/R013/R013_OP00_20261105_AutoLaunch_RootDiscovery_Review.md`, commit `2319f5f655aba33ff50082214aec8de7bb49ea96`, independent blob `01a35c182624a00d68faa9c3f52cb16a236ffa14`.

## Actual user-downloadable archive
- `BlueLite_PREMAX_26300_Universal_Auto_v7_1.zip` exact verified current-container path `/mnt/data/BlueLite_PREMAX_26300_Universal_Auto_v7_1.zip`, **123,482 bytes**, SHA256 **`7B5F28AA1963D978E23EC28481E7FB410D2DB3E6A98BF1E205874758FF792B96`**.
- A fresh independent Python verification process reopened the exact finished ZIP, tested zip CRC PASS, **61 unique safe member paths**, exact `BlueLite_Package_SHA256.txt` **60/60 independent SHA256 content hashes**, and manifest bijection: every member except manifest represented exactly once.
- Regression compared every original v7.0 `BlueLite/` runtime module and root `BlueLite_PREMAX_Test.ps1`, `START.cmd` SHA against new ZIP; **34/34 original executable/engine/selectors byte-identical PASS**. Unchanged v7 main script SHA256 **`A869E3294595AF26B3654E4534C6526886CC6CABB8BAF23904B145E0878A78E0`**.
- Newly added standalone `BlueLite_PREMAX_AutoLaunch_v7_1.ps1` 7,212 bytes SHA256 **`670119C4C3EFADE42BA61F7F86A4E764AA3569B499D4E182CB8413BCEC0E65EB`**. `BLUELITE-AUTO-COMMAND.txt` contains a copy/paste one-line PowerShell 7 instruction independent of Explorer and `Read-Host` input; README and execution order were amended accordingly. `V7.1-AUTO-DELTA.txt` explicitly documents launcher-only change.
- Independent source/static checklist **19/19 PASS**: no `Read-Host` invocation, pinned engine SHA, C:\work scope, exactly-one-root fail-closed, recognized metadata triad, complete manifest check, PS7 AST parser gate, only Analyze child invocation, immutable root `C:\work\logs` HOLD receipt via FileMode.CreateNew; no downloader/mutating Build in launcher.

## Exact boundary
- **WIN_NATIVE_PS7_AST_NOT_RUN; WIN_NATIVE_V7_1_ANALYZE_NOT_RUN; FULL_UUP_DOWNLOAD_WIM_ISO_NOT_RUN; RELEASE_NOT_CERTIFIED**. ZIP static/CRC SHA pass does not certify native runtime. On operator Analyze, return exactly five `C:\work\logs` files from main v7 engine: Report/Receipt/Verify/Timeline/WindowsInputInventory, or root-level HOLD JSON.
- Existing historical 26300.9725 metadata-only root lacks full vendor launcher/converter, so native full Build remains blocked until complete original UUP Dump package selected. WinRE omission retains Setup WinPE/boot.wim. Target 3.5–5GB ISO, 11–15GB installed footprint NOT measured for v7.1.
- No Master/Handoff/Registry/source ISO/WIM/GOLDEN modification. No new operator log subfolders. Core v7 engine is not altered.

ONE NEXT: CAS update only compact `BlueLite_Current_Status.md` after read-only fresh fetch, then independent Git readback. Deliver actual ZIP and exact no-prompt one-line command from any PowerShell current directory. On native logs, independently prove end state before proposing a separate Build authorization.
