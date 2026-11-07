# R030 OP04 — protected Golden WIM/ISO and 184 source SHA verification PASS (2026-11-07)

OP03 HOLD was written/read back Git blob 3be482bcfaf711197d6097e546cb9eec96e9ddcd. This was a WRONG expected hash derived from an entirely DIFFERENT original UUPdump vendor ZIP in the old R029 folder, not proof Golden's own ZIP was corrupted. Native Windows PS7 PID5816 independently streamed every archive member from both original ZIP snapshots: Golden zip 8,218 B SHA256 8117C725C1EF9C8F5C73C5A22887DB38C222C373ED601C94D24DC9109AFEDEF8; R029 other vendor zip 8,218 B SHA256 C21761A87501845F303B3A6AB47E521ADDCC7FEE88E2F2D9F50FBBCC68AC57BD. Both contain 11 files, eight identical and three different platform downloader script members. Keep as separate valid snapshots. No source edits.

Native PS7 PID8348 performed new full read-only verification exit0/33.77s:
- Golden original install.wim 5,736,092,221 bytes SHA256 3D606513D9C1D2B157AAFD6925FF1655C9A48520CE5D4219AF2ED654C82753E4 PASS.
- Golden original ISO 6,822,354,944 bytes SHA256 570BD12E9DBBBB51CACFB3B9A403326AA5000FAC1D2F7E44482EFCC154CB3736 PASS.
- Golden OWN original UUPdump ZIP 8,218B SHA256 8117C725C1EF9C8F5C73C5A22887DB38C222C373ED601C94D24DC9109AFEDEF8, 11 ZIP members PASS.
- All **184 UUP source files**, names, lengths and FULL SHA256 separately checked against immutable original pre-cleanup source proof CSV SHA256 872B94D2FE8BC5E7F9BEC8536B29D3D641DE50E4FDA4E81988C0894F702268DD; **184/184 PASS**, total 9,184,770,517 bytes.
- Entire Golden folder **308 files / 21,763,288,259 logical bytes** matches OP01 inventory. No image mount or original mutation.

LOCAL exact current read-only receipt:
C:\work\_UUP\UUP-history\_Governance\R030_20261107\R030_OP04_GoldenSourceSHA_PASS.json.
Previous OP03 HOLD evidence remains. Golden original location C:\work\_UUP\26300.9818-UUP-MAX_PRE_26300_v4 STILL UNMOVED in OP04.

**ONE NEXT**: if allowed, perform exact one same-volume atomic move of the verified protected Golden DIRECTORY to C:\work\_UUP\UUP-history\09_ProtectedGolden\26300.9818-UUP-MAX_PRE_26300_v4 with destination absent. Verify AFTER move same 308 file count/bytes, original WIM/ISO/vendor SHA and every 184 UUP SHA against source proof, then write Git R030 OP05 + independent readback. If RDC safety layer blocks the move, HOLD and do not circumvent.
