# BlueLite CWork Cleanup / OP01 — exhaustive native inventory, 3-way SHA256 source proof

2026-11-07, operator requested full disk hygiene FIRST and explicitly HALT subsequent BlueLite development until cleanup confirmed. Source user evidence R028 OP16 already git committed / read back (real failure 0x8007007A, no FoD work). All below was READ-ONLY except creating inventory/proof receipts in ONE direct child `C:\work\BlueLite_Cleanup_20261107\BlueLite_Logs`; **NO DELETION/IMAGE MUTATION**.

## Exact comprehensive native inventory
Native Windows PowerShell 7 PID5808 recursively enumerated all non-reparse entries under `C:\work`; finished 9.59 seconds, **19,328 regular files, 2,506 directory visits, 75,005,653,472 LOGICAL bytes (69.854 GiB), 0 failed directory/file reads, 7 reparse entries intentionally skipped, mounted images=0**. C: was 208,569,720,832 bytes free at scan time. Logical file-length sums can overcount NTFS hardlinks/sparse data, so actual disk reclaimed must be measured after deletion. Complete locally preserved CSV receipts:
- `C:\work\BlueLite_Cleanup_20261107\BlueLite_Logs\CWork_20261107T1647122645482Z_AllFiles.csv` (EVERY non-reparse file path + length + UTC last-write).
- `...\CWork_20261107T1647122645482Z_TopLevel.csv` (all first-level folder/root file groups with sizes/counts);
- `...\CWork_20261107T1647122645482Z_Largest100.csv` (100 largest);
- `...\CWork_20261107T1647122645482Z_Skipped.csv` (7 reparse entries);
- `...\CWork_20261107T1647122645482Z_State.json` (exact counts, path, free disk, zero mounts).
7 skipped links: one `PREMAX-work\R009_V61_OfflinePreflight\UUP\BlueLite_Logs` and six intentionally link/junction-protected E2E test fixtures. **No skipped paths are deletion candidates**.

## First-level dominant logical sizes (bytes; file count)
| Direct C:\work child | Logical bytes | Files | Disposition |
|---|---:|---:|---|
| `_UUP_PREMAX_v11.2` | 25,064,557,956 | 1,621 | KEEP root metadata; failed R027 stage candidate |
| `26300.9818-UUP-MAX_PRE_26300_v4` | 21,763,288,259 | 308 | **PROTECT** original frozen Golden ISO, install.wim and source UUPs |
| `PREMAX-work` | 19,418,615,620 | 3,948 | KEEP workspace/old cycles; failed R028 stage candidate |
| `E2E` | 7,156,082,140 | 5,486 | HISTORIC/UNKNOWN: NOT eligible for delete without independent corpus/owner review |
| `26300.9818-UUP-v5` | 912,487,870 | 296 | UNKNOWN, do not auto-delete |
| `logs` | 611,205,376 | 3,306 | Historical receipts; KEEP |

## Exactly two proposed failed-stage deletion candidates (no other trees)
- **R027_FAILED**: `C:\work\_UUP_PREMAX_v11.2\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_734c2696`: **25,062,321,218 logical bytes / 1,479 files**, including stale `ISOFOLDER` 8,585,467,862 B, `BlueLite_FinalWim_Work` compact WIM 5,738,596,977 B, original-source UUPs 9,184,770,517 B, and temporary converter data. R027 real failure identity-gate detailed R027 OP03.
- **R028_FAILED**: `C:\work\PREMAX-work\R028_Universal_Full_UUP_20261107\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_273212e7`: **19,273,553,336 logical bytes / 1,400 files**, including stale `ISOFOLDER` WIM 7,440,965,397 B, source UUPs 9,184,770,517 B and temporary converter/Setup data. R028 failed native COMException 0x8007007A after mount, before FoD; see OP16. The R028 package ZIP and small draft files OUTSIDE stage stay untouched.
- **Total candidate logical files 44,335,874,554 B = 41.291 GiB**; actual physical bytes freed unknown until measured. No deletion already happened.

## Exact triple immutable-source proof
Native Windows PS7 PID8860 performed **full independent SHA256** of every relative-file-name-matched source in:
1. Protected **GOLDEN canonical** `C:\work\26300.9818-UUP-MAX_PRE_26300_v4\UUPs`;
2. R027 failed stage `...\_UUP_PREMAX_v11.2\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_734c2696\UUPs`;
3. R028 failed stage `...\PREMAX-work\R028_Universal_Full_UUP_20261107\BlueLite_Work\BlueLite_Stage_v11_3_26300_9818_6c7bf258_273212e7\UUPs`.
**184/184 filenames + byte lengths + SHA256 EACH of all three files identical**, total each 9,184,770,517 B. Prior script assumed 184 files at immediate UUPs root but there are 102 immediate +82 nested; it failed closed without receipt or deletion, corrected to recursive enumerator before success. The final machine-readable proof:
`C:\work\BlueLite_Cleanup_20261107\BlueLite_Logs\CWork_20261107T1650576887287Z_UUP_3way_SHA256.csv`, SHA256 `872B94D2FE8BC5E7F9BEC8536B29D3D641DE50E4FDA4E81988C0894F702268DD`.
Independent summary JSON same prefix `..._UUP_3way_SHA256.json`, status `THREE_WAY_SHA256_184_PASS`. Only the protected v4 copy must remain after optional operator cleanup; no redownload needed for these 184 source files.

## Mandatory release/cleanup gates
**DO NOT DELETE yet.** Deliver one versioned **review-first / explicit phrase-confirmed** script directly under `C:\work\BlueLite_Cleanup_20261107`. All associated output, pre-delete preserved logs/config and post-delete evidence go solely into `C:\work\BlueLite_Cleanup_20261107\BlueLite_Logs`. Script exact allowlist ONLY these two stage paths, no other C:\work children. Before deletion: check stage path/owner/sentinel, exact counts+bytes, 3-way UUP source proof against original Golden and pinned CSV receipt, v4 Golden unchanged, reparse/mount/process/hive guards, archive all small stage logs/config/scripts with independent SHA verification, fail-closed on any discrepancy. Operator separately executes deletion with explicit phrase, never via assistant RDC. If successful expect logical footprint reduced by 41.291 GiB (physical delta measured, could differ because NTFS hardlinks/sparse). E2E and legacy v5 held for separate future provenance review, not part of this cleanup.

**ONE NEXT:** source-review and test precise single-cleanup script, commit GitHub with independent readback, place exact reviewed file in `C:\work\BlueLite_Cleanup_20261107`, native script Audit PASS with zero deletion, deliver one explicit user command+exact local log file names, update compact Current checkpoint and Session Entry router CAS+readback, then **PAUSE until operator returns cleanup log and confirms**.
