# R030 OP10 — failed R029 UUP candidate archived intact with source SHA evidence (2026-11-07)

Previous small-cycles OP09 independently Git readback blob 4851401e67b6af1d91bcbec30a6058a91df0a3d7. Native Windows PS7 PID5948 ran category R029 and completed exit0: **394 files, 3,213,310 logical bytes** atomically moved with full BEFORE/AFTER per-file SHA fingerprint + exact relative path/size, zero reparse and source absent.

OLD root path now ABSENT:
C:\work\_UUP\BlueLite_PREMAX_R029_20261107
NEW archival path:
C:\work\_UUP\UUP-history\08_LegacyCycles\BlueLite_PREMAX_R029_20261107
Original extracted UUPdump vendor ZIP, BlueLite ZIP, four QA fixture trees and original small BlueLite_Logs all retained byte-identically, no deletion. Per-item native receipt:
C:\work\_UUP\UUP-history\_Governance\R030_20261107\R030_MOVED_BlueLite_PREMAX_R029_20261107.json
Category summary R030_MOVE_R029_RESULT.json SHA256 **E407B4E40CFB776B8148FAED1EF5FEE707E98C3647ED6D9812E0B8A73B49B9B0**. This source candidate is **HISTORICAL RUNTIME HOLD** because operator observed Admin CMD closes without a new log; reason cannot be proven without actual preflight output. Earlier source/ZIP QA is not native runtime PASS. No new CMD invocation or download attempted. The next PRE_MAX engineer must build a new, separately named UUP root with an early durable CMD/PowerShell bootstrap log and history mirrored evidence before testing, instead of mutating this frozen R029 archive.

**ONE NEXT**: independently migrate older v5 root 912,487,870 logical bytes (preserve original content, per-file SHA before/after), then separate Git OP11/readback. Later PREMAX-work with junction, loose roots and cleanup evidence. Do not move/delete RH02–RH08 canonical files.
