# R030 OP07 — nested PREMAX-work junction target discovered; archive-only exception (2026-11-07)

Source OP06 protected Golden migration Git blob b129cb900005fe23bf3c4cd8ea1a8feb55b4b378 independently read back PASS. Actual Golden moved into UUP-history\09_ProtectedGolden and FULL 184 SHA and WIM/ISO/vendor SHA rechecked, original root absent.

Native RDC Windows PS7 PID4956 read-only inspected the SOLE reparse point listed by OP01:
C:\work\_UUP\PREMAX-work\R009_V61_OfflinePreflight\UUP\BlueLite_Logs
Attributes: Directory + ReparsePoint; LinkType **Junction**; exact absolute target **C:\work\logs\BlueLite_R009_V61_OfflinePreflight_v1** (which is OUTSIDE the newly mandated UUP root). This is HISTORICAL PREMAX-work evidence, NOT a currently active WIM mount and not proof of an operational file lock. We are NOT authorized to delete or mutate target C:\work\logs as part of the UUP-only root restructure.

**Current rule and handling**: Do NOT follow this link during inventory/copy/hash, and do NOT allow new UUP package scripts to target it or create any junctions leaving C:\work\_UUP. Historical PREMAX-work may be moved intact as an archive-only directory by SAME-VOLUME rename if owner root exact and independent content digest is identical pre/post; existing junction object remains metadata-only historical evidence, its absolute target unchanged. Document this as a permanent historical exception and safety/HOLD requiring future explicit operator review before eliminating it; no activation/execution from UUP-history. If moving a junction parent is prevented by tools, leave PREMAX-work in original place with HOLD. Never use destructive recursion following the junction.

No files moved or deleted by this OP; no external target touched. No new converter/image/download work.

**ONE NEXT**: create/test a generic R030 exact-plan category mover with per-item full file-content SHA digest and no-follow reparse identity, execute ONE category at a time after this independent Git readback, write category result plus readback before next group. First: all small, known historical 08_LegacyCycles entries EXCEPT PREMAX-work, R029 failed root and v5 root. Subsequent categories R029, v5, PREMAX with junction-preserving provenance, loose root docs and cleanup evidence, each separate OP. No non-UUP writes.
