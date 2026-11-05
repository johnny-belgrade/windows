# R009 OP01 — Source-only delivery artifact, independent static verification

**UTC date:** 2026-11-05. **Status:** STATIC_SOURCE_VERIFIED / NATIVE_R009_NOT_RUN. Exact predecessor Current: R008 delivered, R007 v5 native built, v6.1 runtime NOT_RUN.

- GUI executable: `BlueLite_R009_V61_OfflinePreflight_v1.ps1`, save to `C:\work\scripts\BlueLite_R009_V61_OfflinePreflight_v1.ps1`.
- Binary length: **102,863 bytes**, SHA256 **D9CBCDA8905682267F357E2450D364B1ADB68F05E28378E3A7BC852B164CDA56**. Source is an assistant-generated user-visible downloadable PS1, not a locally installed Windows file and not a native certified runtime.
- Original user R008 complete ZIP SHA256 `099ABC9C3E21CC25965EE15156C02676088D515863B3C032EA2D1F6085546B1E`; ZIP CRC PASS. One embedded RUN-only 38-member ZIP SHA256 `BBE96A90F11216AA4B46C18D0131821705943A59DFAF7A7A0A47D45523CAF449`.
- Independently extracted that embedded ZIP from the finished PS1, verified its SHA256, full ZIP CRC and exact **38/38 member byte identity** against original R008 `RUN/`. Original R008 inner manifest **37/37 file SHA256** PASS. The 38th file is the inner manifest itself.
- Static code inspection: exact OP01→OP05 receipt sequence, independent fresh-process PS7 Verify at every stage, immutable CreateNew receipts, source SHA snapshot, original UUP copied to new owned R009 working root, manifest-pinned overlay, native *offline-only* v6.1 `BlueLite_Preflight.ps1` using exact stage root, no START execution. All return logs in `C:\work\logs`; original source/GOLDEN untouched. Archive final `C:\work\logs\BlueLite_R009_V61_OfflinePreflight_v1_Evidence.zip`; final OP05 receipt and Verify JSON are separate (archive precedes their creation).
- OP01 native PS7 AST, fresh Windows readback of this delivered script, junction creation, full native source preflight and evidence ZIP: **NOT_RUN**. No falsely claimed PASS. Any failure stops with HOLD/evidence, no automatic overwrite. No WIM/CBS/ISO/registry/Defender/NTLite authorization.
- One next: record compact GitHub Current with exact artifact checksum and operator command, independently read it back, then operator saves/runs this script locally and returns 3 exact log files (ZIP, OP05 receipt, OP05 Verify). Only after native evidence review may R009 preflight be promoted.

Original R008 source remains frozen; this R009 orchestrator is an isolated *source-preflight wrapper*, not a rewrite of MAX_PRE engine.
