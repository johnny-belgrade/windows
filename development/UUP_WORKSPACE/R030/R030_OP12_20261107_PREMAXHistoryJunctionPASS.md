# R030 OP12 — PREMAX-work archived SHA-verified with single historical junction preserved (2026-11-07)

Previous OP11 v5 category readback Git blob 65b0a1f3ccae6d8c843e1c91d97080c2893e8e78 PASS. Native Windows PS7 PID8748 -Mode PREMAX executed one same-volume Directory.Move and independently matched all 2,548 file-content SHA256 values and relative-path/byte lengths before/after. Exact 145,062,284 logical bytes; one known reparse junction metadata unchanged. Native category exit0/3.46sec and local summary SHA256 D2821910953CE165C58C68592717A33D33B3FFE8639F36B5CC9F088F0C101F01; item receipt R030_MOVED_PREMAX-work.json and R030_MOVE_PREMAX_RESULT.json both under C:\work\_UUP\UUP-history\_Governance\R030_20261107.

OLD source C:\work\_UUP\PREMAX-work absent. NEW canonical HISTORIC target:
C:\work\_UUP\UUP-history\08_LegacyCycles\PREMAX-work

**Historical exception**: the retained PREMAX-work\R009_V61_OfflinePreflight\UUP\BlueLite_Logs JUNCTION still has exact original absolute link target C:\work\logs\BlueLite_R009_V61_OfflinePreflight_v1 outside the new UUP root. Its *link object* is archived solely as provenance; neither the external target nor any member underneath that junction was followed, read, written or deleted by relocation. Subsequent UUP code MUST NEVER use this link for active logs, and history integrity routines must skip it. Future operator can separately authorize replacing this external historical junction with an immutable local snapshot, but no old outside-root mutation is authorized here.

No new UUP downloader, WIM mount, ISO or deletion.

**ONE NEXT:** move exact four loose root files into UUP-history\08_LegacyRootFiles, full SHA after compare with pinned plan; report Git OP13 and independently fetch, then move historic cleanup evidence OP14. Finish root inventory and dual-log mirror implementation.
