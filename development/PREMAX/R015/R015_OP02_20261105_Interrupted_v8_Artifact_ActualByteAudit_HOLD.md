# R015 OP02 — Interrupted Factory v8.0 exact archive byte audit: packaging HOLD
Date 2026-11-05. This document supersedes the earlier R015 OP01 v8.0 *downloadable archive byte/manifest* claim only. Historic R011 native, original UUP, Master/Handoff/GOLDEN and R015 native read-only in-memory parser evidence remain intact. No Windows writes.

## Independent local container audit after platform interruption
- Reopened exact active `/mnt/data/BlueLite_PREMAX_26300_Universal_Factory_v8_0.zip` and hashed original file bytes: **78,037 B**, SHA256 **`9B394BEA582CFE51E6DE457C3854D6E899C034DF265F6B68E114D05F0CFEC51D`**, ZIP CRC PASS, **41 unique members**.
- Earlier R015 Current/document and visible previous assistant answer had described **79,177 B, 42 members**, SHA256 `2842F0230537E54B7F9BEB8FBDFFF89D3FDA39FF02B84488017BDD6D950A4D3B`. These are **NOT** the active bytes in this container. Do NOT use that old SHA to validate the active ZIP, or claim it was confirmed here.
- Crucially active ZIP is MISSING `ONE-COMMAND.txt`, despite `/mnt/data/BlueLite_PREMAX_Factory_v8_src/ONE-COMMAND.txt` on disk and reference in README. Active ZIP inner manifest contains **40/40** entries for its 40 files other than the manifest (not the claimed 41/41). This is a packaging/delivery inconsistency; HOLD the older ZIP for operator use.
- Actual source tree on disk already contains `ONE-COMMAND.txt`, and internal `BlueLite_PREMAX_Factory_v8.ps1` SHA256 `F3A7E47E2DED1C01EC165111BC3902D2F1AD6B2055581F45A2549B3EA7FB8FBF`, same as in ZIP. Corrective repackage must be **new unique versioned downloadable path**, not a silent replacement of the previous filename. Independently rerun ZIP CRC/member SHA/bijection and only then publish true new SHA.

## Next operational boundary
ONE NEXT: Create immutable versioned R015R1 corrected *delivery* ZIP with `ONE-COMMAND.txt` included and exact source hashes, independently verify with separate process, record Git per-op receipt and fresh readback; then CAS one compact Current and deliver one accurate no-prompt Analyze command. Do NOT start UUP download/converter/WIM/ISO. Existing v8.0 incomplete ZIP must remain historical HOLD.
