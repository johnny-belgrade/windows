# BlueLite R002R26-G3M — source-selected 31 AppX read-only verification preflight journal (2026-10-25)

**Authority/scope:** Complete Master v6.3.1 governs; Git Session Entry G3M IN_PROGRESS commit `2b423c4ce4a423b3d42dc15d8e7a800b24e4f2d4`, blob `35c63f34bc726401e59bdfcb6760f683e6ea9839`, independent readback PASS. Previous G3L D0–D50 synthetic block closed, new G3M separately operator-continuation authorized. G3L v5 source SHA256 `C1F97F6ED041482C882AD4E28AB3F74347FB417989D2B3F94D0C99F5F4AE53AA`, native 92 synthetic PASS **not** original-31 source verification. Relevant Handoff §0CH SECOND requires exact F4+G1 31 source pin, source root/leaf/reparse/size/CRC/XML and G3L graph/failure owned destination collision checks before `-Mode Verify`. Existing R002 path only. No original/cache, WIM/CBS/host OS, registry/ISO/NTLite/VM, Master or frozen code mutation; source-specific CAB and external WIM floor independent HOLD.

**D0 — GitHub/connector reachability and successor reconciliation:** Live GitHub main Session Entry, Current/Handoff exact SHA and G3L journal D50 independently fetched; Latest Current SHA `8b14e9517f981a4682f4034285e917d49483893c`, Handoff SHA `c9a49f8c6928cd986ddda8b8760e756bf71f4812`, G3L journal `bfbcb911659df864ba668e9b80f388d8b0f31100`. Current and Handoff full content independently fetched using immutable Git blob SHA because GitHub path fetch returned empty on oversized docs; no erroneous conclusion of data loss. Direct RDC `list_devices`: `DESKTOP-4J4KCEA` **Online**, id `d892c878-1a42-4fcd-b0e7-c51caf510ab6`, app v0.3.1. No native task run. The previous D37 failed write already resolved in the completed G3L v5 checkpoint; do **not** repeat it.

**STATUS:** `PASS_G3M_INIT_CHECKPOINT_AND_LIVE_DEVICE_REACHABLE` / `PREFLIGHT_NOT_RUN` / `REAL_31_NOT_RUN`.

**D1 — live RDC configuration independently inspected:** Direct RDC `get_config` on exact authorized device returned version `0.3.1`, Windows `win32`, allowedDirectories **exactly** `["C:\\work","C:\\BLR20R2F5"]`, `blockedCommands` length **33** (existing 33 including `reg`, `diskpart`, `netsh`), `fileReadLineLimit=1000`, `fileWriteLineLimit=50`. No configuration changes or new root grants; this does not prove process-level containment and does not authorize any unapproved paths. Existing G3L owned R002 remains within `C:\\work`.

**STATUS:** `PASS_G3M_RDC_LIVE_CONFIG_ROOTS_AND_33_BLOCKED` / `SOURCE_GATES_NOT_YET_RUN`.

**D2 — exact complete local G3L v5 source readback:** RDC `read_file` of only owned R002 `03_Drafts\\R002R26_G3L_AppxManifestGraph_Zip64_v5_DRAFT.ps1` returned explicit **892/892 lines (0 remaining)**. Source has `function Verify`, `G3L-ZipHold`, ZIP64 in-memory fixtures and manifest/CRC routines, intended new graph JSON path `05_Evidence\\R002R26_G3L_AppxGraph_001\\R002R26_G3L_Graph.json`. Its `$Cache` literal points to preserved historical `C:\\work\\E2E\\BlueLite_Stage1_S06_26300_9711_2b22470a\\UUPs`; **do not infer target source identity from directory name**. F4+G1 target UUID, queue SHA1 and exact cache leaf identity require verification. No source execution or files modified in this read-only action. Native source SHA and destination collision checks **still pending**, even though v5 SHA is recorded in predecessor G3L.

**STATUS:** `PASS_G3M_G3L_V5_FULL_892_LINE_SOURCE_READBACK` / `REAL31_NOT_RUN`.

**D3 — fresh native immutable G3L v5 source pin:** RDC native PowerShell7 PID **7192** completed `Get-FileHash -Algorithm SHA256` on exact authorized existing `03_Drafts\\R002R26_G3L_AppxManifestGraph_Zip64_v5_DRAFT.ps1`, exact stdout **`C1F97F6ED041482C882AD4E28AB3F74347FB417989D2B3F94D0C99F5F4AE53AA`** equals G3L v5 frozen source pin. Direct full local source readback 892/892 separately proved D2. No source execution, writes, original/cache/WIM/CBS mutation.

**STATUS:** `PASS_G3M_G3L_V5_NATIVE_SHA256_PARITY` / `VERIFY_GATE_PREFLIGHT_PENDING`.

**ONE NEXT:** Targeted read-only source review: inspect `Verify` function and actual source identity, SHA1, archive/manifest checks, output/failure CreateNew flow, then separately document exact safety dependencies.
