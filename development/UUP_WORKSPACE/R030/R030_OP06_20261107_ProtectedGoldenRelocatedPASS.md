# R030 OP06 — protected Golden relocated into UUP-history, full verified PASS (2026-11-07)

Previous OP05 readback Git blob ac8b3dd68b77094e08d94c7aead831bfbad31590 documents the strictly pre-move PowerShell Count error; no source changed then. Independent native PS7 PID9056 tested FIXED V2 source file R030_OP06_MoveGoldenV2.ps1, AST PASS, original source existed and destination did not exist, code SHA256 AEBF967976CEE3B042FD641206B2CC85CB0CFD138ADDBA6B222349E3A9DE2756.

Native Windows PS7 PID7984 performed a SINGLE original GOLDEN source-bound same-volume [IO.Directory]::Move, then verified EVERY item after relocation; exit0 in 51.71seconds.

**EXACT RESULT** original directory C:\work\_UUP\26300.9818-UUP-MAX_PRE_26300_v4 ABSENT, new protected canonical directory
C:\work\_UUP\UUP-history\09_ProtectedGolden\26300.9818-UUP-MAX_PRE_26300_v4
PRESENT. 308 files / 21,763,288,259 logical bytes PASS before and after. Independent full SHA after move:
- original WIM 5,736,092,221 B SHA256 3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4 PASS
- original ISO 6,822,354,944 B SHA256 570BD12E9DBBBB51CACFB3B9A403326AA5000FAC1D2F7E44482EFCC154CB3736 PASS
- Golden's own original UUPdump ZIP SHA256 8117C725C1EF9C8F5C73C5A22887DB38C222C373ED601C94D24DC9109AFEDEF8 PASS
- ALL 184 independent SHA256 original UUP source payload files checked against prior original proof CSV after move: 184/184 SHA PASS, byte sum 9,184,770,517 B.
No WIM mounted or image content edited; no source deleted or duplicated. Exact local receipt: C:\work\_UUP\UUP-history\_Governance\R030_20261107\R030_OP06_GoldenMoveV2.json, with original/new path and source SHA count. Old Golden absolute paths in earlier Git documents have become historical source paths, and must be updated to new canonical history path in Sources/Current/Start/Master after all moves.

**ONE NEXT**: use remaining 52 explicit entries in immutable local R030_OP02_RelocationPlan.csv and one-by-one / category-grouped destination relocation under UUP-history, first check PREMAX-work nested reparse/link target. Each logical category must have local per-source source/target byte/filecount journal and SHA verification and separate Git OP/readback. Preserve frozen historical RH02–RH08 index, user original vendor ZIP snapshots and all evidence. No mass delete, no new R029 Build.
