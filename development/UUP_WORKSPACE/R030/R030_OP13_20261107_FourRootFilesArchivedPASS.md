# R030 OP13 — four loose historical UUP root files moved and full SHA validated PASS (2026-11-07)

Previous OP12 readback Git blob 308c944029cd2cadd063869d1a6db1c98e4714cc independently PASS. Native Windows PS7 PID9088 executed category RootFiles exit0. All FOUR root-level previously loose files are now in C:\work\_UUP\UUP-history\08_LegacyRootFiles with their exact original filenames; each original root file is ABSENT, and each moved target content SHA256/size matches original manifest independently before/after:
- BlueLite_Universal_UUP_Overlay_v2_20261102.zip 45,321 B
- BlueLite_Universal_UUP_Overlay_v2.zip 45,321 B (separate original named instance, not deduped)
- Start_Instruction.md historical local snapshot 26,143 B (CURRENT GitHub Start_Instruction remains authoritative)
- Timeline_07-11_17-28.txt historic user timeline 11,467 B
All four total **128,252 logical bytes**, zero reparse. Individual per-item JSON SHA-fingerprint receipts R030_MOVED_<original-name>.json and complete category R030_MOVE_RootFiles_RESULT.json SHA256 **6B6B8428B572C6D3307630A0CD79D1EB22156AB34FB50930C2A13819ED0AE03D** under history governance. No source bytes changed, no deletions, no new root-level files.

**ONE NEXT**: relocate historical operator cleanup proofs C:\work\_UUP\BlueLite_Cleanup_20261107 to C:\work\_UUP\UUP-history\10_HistoricEvidence\BlueLite_Cleanup_20261107, hash-verify all 17 original files, then Git OP14+independent readback. After that verify no unexpected loose UUP root contents except UUP-history, create automatic per-cycle log mirroring and finish permanent documentation.
