# BlueLite R009 OP00 — PRE-EXECUTION PLAN (2026-11-05)

Status: SOURCE-ONLY OPERATOR PACKAGE PREPARED; NATIVE R009 NOT_RUN. Single live Current remains `BlueLite_Current_Status.md`. Normative Master v6.3.4 §0G/§0I/§0J/§0L. Predecessor R008 v6.1 complete archive SHA256 `099ABC9C3E21CC25965EE15156C02676088D515863B3C032EA2D1F6085546B1E` independently checked. R008 native 26/26+3/3 is source/fixture proof only. R007 v5 native WIM/ISO proof preserved.

## Operator correction and approved next
- 2026-11-05 prior `pwsh -File .\\BlueLite\\BlueLite_Preflight.ps1 -UUPRoot .` failed before script start because PowerShell CWD was `C:\\Program Files\\PowerShell\\7`, not a UUP root. Not an R008 software failure.
- Authorized next is selected source-only offline preflight, not download, converter, WIM/ISO/registry changes. Default selected regression source is the existing original `C:\\work\\26300.9818-UUP`, whose original launcher, converter files and three metadata files were read-only discovered by scoped RDC. Not a new production CU preference. Operator can choose a different official 26300.x source by explicitly supplying its verified root.
- Strict delivery: one self-contained executable `C:\\work\\scripts\\BlueLite_R009_V61_OfflinePreflight_v1.ps1`; all operator-return logs/receipts/ZIP strictly under `C:\\work\\logs`. Embedded R008 RUN overlay is 38 exact, separately source-manifest verified files; no external downloads or reliance on CWD.
- Owned isolated new source-copy root `C:\\work\\PREMAX-work\\R009_V61_OfflinePreflight\\UUP`. Preserve original UUP source and all R004 GOLDEN/WIM/ISO, R005-R008 cycles, Master, Handoff and UUP-history unchanged. Do not run START.cmd.

## Exactly ordered native micro-operations
1. OP01: bounded untouched source inventory with original launcher, metadata triad and file SHA256; immutable source manifest and receipt under `C:\\work\\logs\\BlueLite_R009_V61_OfflinePreflight_v1`; fresh independent PS7 verifier rehashes before proceeding.
2. OP02: copy the exact original UUP source only into new owned root; immutable receipt; fresh separate PS7 hash/scope readback.
3. OP03: extract embedded RUN overlay (38) after checking self-contained ZIP SHA256 and 37/37 v6.1 runtime SHA manifest; immutable receipt; fresh separate PS7 verification, source still intact.
4. OP04: create owned log-routing junction into `C:\\work\\logs`; invoke only native `BlueLite_Preflight.ps1 -UUPRoot <new-root>` as separate PowerShell 7 process; capture source triad/AST/manifest and stdout; record native exit and separate PS7 Verify. STOP on any HOLD; no network/converter/image mutation.
5. OP05: package previous immutable receipts/native logs into `C:\\work\\logs\\BlueLite_R009_V61_OfflinePreflight_v1_Evidence.zip`; immutable archive SHA/member manifest receipt; fresh independent PS7 ZIP member-by-member hash/readback. Final OP05 receipt+Verify JSON are provided alongside ZIP, as they are written after archive creation.

No automatic retries/overwrites. Existing R009 source/log/output collision is HOLD. Runtime source not certified until the user returns exact native ZIP+final receipt+independent Verify. One next after delivery: operator runs the exact GUI command on Windows PS7 and returns those outputs; then independent assistant evidence review and CAS Current update. No status promotion before evidence.
