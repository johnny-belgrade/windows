# R047 OP01 POST — OP47 archive integrity PASS / production-quality findings HOLD

UTC 2026-11-21. PRE immutable Git commit 8a9d1bd0febbedfa7fa1900eb8b38acbf77b3f58 blob c13da9999f5054c3589ba1569106e9ae00a90a1c, independently fetched/readback before native operation. Authorized scope READ-ONLY archive/source QA only. No native Build, UUP binary download, converter, WIM/ISO/registry/VM modifications; original archive unmodified.

## Actual physical native evidence

Selected original Windows one-ZIP delivery: C:\work\_UUP\R046_PRE_MAX_26300x\BlueLite_PRE_MAX_26300x_OP47.zip length **109995 B**, **SHA256 C3226AFE1A637C7245D1FD0CFFC89616C77CCAD9681D7B7B21927809A81F4304** unchanged. Actual Windows PS7.6.9 PID9148 opened ZIP read-only, enumerated **51 members**, rehashed and matched all **50/50 SHA256SUMS entries** with **0 mismatches**, then wrote a NEW immutable receipt (FileMode.CreateNew):
C:\work\_UUP\UUP-history\R047_OP47_ArchiveReview_20261121\R047_OP01_ArchiveQA.json SHA256 **8C05714D5D38F6EBF4B0A1DC35105BC2C948A888180306BED0DC03B8987066C5**.
Independent fresh Windows PS7 PID8672 rehashed *physical original ZIP and receipt*, checked mandatory source/manifest/status fields, independently re-enumerated unique entries and created:
C:\work\_UUP\UUP-history\R047_OP47_ArchiveReview_20261121\R047_OP01_IndependentVerify.json SHA256 **E6C7488D5EAB824BA5CFA39FA1AE61399D6687ADBE9A103B9E8C3E4B624624F4**.
Independent Library copy also physically sha-matched same exact original ZIP; Python zipfile.testzip CRC PASS, names unique51, unpacked289591B. Live origin delivery folder previously direct-list showed only original ZIP/0 dirs. User Chats latest 52-WORK.md confirms last OP47 source-only; Git sole Current originally aac55157cbbd326288b8ecb0467bfeb57dae9b6d. Preserve the earlier five native cross-build Plan PASS and negatives; they are NOT full converter/WIM proof.

## Source-grounded audit findings (STATIC only, do not mislabel actual runtime failure)

1. **Priority P0: Evidence exit masking**. Root Run.ps1 line81 catch branch after evidence ZIP / mirror failure unconditionally replaces a prior successful native Build result with 17. Master §0S requires separate evidence HOLD, actual native child outcome preserved. Never call it a demonstrated runtime failure; it is a source-level failure path.
2. **Priority P0: Missing earliest bootstrap**. Root PRE_MAX.cmd line4 checks hardcoded ProgramFiles PowerShell7 path before any durable log; if absent, console HOLD17 with no guaranteed bootstrap record. Master §0P requires first CMD action persistent bootstrap. This also restricts otherwise valid nonstandard PS7 locations despite claimed portable workflow.
3. **Priority P1: WIM promotion transaction boundary**. Engine/BlueLite/BlueLite_PreDebloatWim.ps1 line469 Move-Item -Force after committed original working WIM + exported derivative has no separate post-replacement image integrity/rollback transaction. Need owner-scoped atomic versioned promotion and independent final hash/native image identity before BUILD_CERTIFIED; do not assert this line has produced corruption.
4. **Scope limitation, not new bug**: Engine/BlueLite/BlueLite_Profile.ini line14 StrictReleaseForbiddenAppGate=0; release-forbidden DesktopAppInstaller residue can be warned/handed off. Stage1 can still PASS with explicit residue; genuinely maximal four-app final policy is pending downstream, known old F01; do not invent removal.
5. **Packaging hygiene**: README.txt included as executable-unreachable explanatory file; Master §0G §0R prefer runtime-only ZIP. Check reachability before removing this in a separately versioned candidate.

Additional required acceptance not performed: genuine source-selected G4 binary dependency closure, expiring signed URL live retry under Build, actual vendor converter, Stage1/Setup boot/ISO, 2 different full native 26300.x builds, full VM and installed footprint. Four Plan builds are not cross-build end-to-end proof.

## Classification and next

**STATIC_ARCHIVE_INTEGRITY_PASS / REAL_SOURCE_QA_PASS / PRODUCTION_QUALITY_HOLD (P0/P1 source gaps) / NATIVE_IMAGE_RUNTIME_OP47_NOT_RUN.** No modification to OP47, Golden, Master, original vendor, Sources/Entry/Handoff, and no reparse deletion/temporary bypass. RDC baseline remains allowedDirectories=[C:\work], 33 blocked commands including reg; no temporary exception needed. All P0 findings are proposed fixes, never coded/tested here.

**ONE NEXT:** create separate versioned OP47-successor source-only candidate in fresh owned QA workspace, fix evidence-exit and earliest bootstrap contract first, then transaction-safe WIM promotion, preserve inherited 33/33 source core identity for unchanged files, run PS7/PS5 AST, negative error injections, original UUP 4-build plans and ZIP+native independent QA. Perform true Build only after reviewed new code and exact separately authorized image target, then actual cross-build and downstream certification. Protocol PAUSE.
