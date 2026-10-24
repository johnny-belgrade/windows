# R002R26-G3B — strict ZIP/bundle fixtures and source freeze journal

**Scope:** source-only G3B under authorized R002 cycle, Master v6.3.1; §0BE individual action → checked journal → next. No 31-package real Verify, CAB, WIM/CBS/registry/ISO/NTLite/VM/host mutation. Working local draft root: `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts`. Source R23 SHA256 `0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6`, target `26300.9807` UUID `687d1ced-aab1-4cd5-ad05-705189769731`. Handoff reviewed ONE NEXT G3B. Original G3 v1/v2 retained.

## G3B-D1 — read-only native source SHA (2026-10-24)

- **Operation only:** RDC `pwsh.exe -NoLogo -NoProfile -NonInteractive -Command (Get-FileHash ... -Algorithm SHA256).Hash` on exact LOCAL v2 draft, PID `7976`, reported finished, cumulative attempt 1/3.
- **Observed SHA256:** `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E` exactly prior G3 reviewed pin. Original v1/v2 untouched; numeric native exit not separately exposed. This is source-byte integrity, NOT parser functional/static re-test or XML graph.
- **ONE NEXT:** check target GitHub source mirror path does not exist, then source exact mirror; journal each and independently read back.

## G3B-D2 — target Git noncollision probe

- **Operation only:** direct GitHub contents lookup for `development/PREMAX/R002/03_Drafts/R002R26_G3_AppxManifestGraph_v2_DRAFT.ps1`; returned native `NOT_FOUND`/HTTP404, so no existing path was overwritten. This is expected noncollision, not infrastructure failure. Attempt 1/3.
- **ONE NEXT:** obtain complete exact local v2 text bytes from scoped RDC and check encoded integrity before Git create.

## G3B-D3 — exact-source Git mirror transfer blocked BEFORE confirmed execution (2026-10-24)

- **Intended single logical operation:** source-exact freeze of pre-hashed local v2 at `03_Drafts/R002R26_G3_AppxManifestGraph_v2_DRAFT.ps1` using scoped RDC binary read for source transport and GitHub create on the confirmed absent development mirror path. Prior local v2 SHA256 PID7976 PASS and target Git 404 D2 recorded separately.
- **Literal result:** connector orchestration rejected with `This tool call was blocked by OpenAI's safety checks. Please double check what you are sending.` No PID, source payload or Git commit returned. **Attempt 1/3**, platform pre-execution safety rejection; **GIT_MIRROR_NOT_PROVEN**, no claim that either nested action ran, no blind retry, alternate channel, altered permission or bypass.
- **Result:** `G3B_SOURCE_MIRROR_PLATFORM_HOLD_1_OF_3`. v2 local prior SHA remains last proved content; v3 NOT_CREATED, extra strict fixtures NOT_RUN, AST/SelfTest v3 NOT_RUN; real 31-file Verify NOT_RUN; CAB/WIM/CBS/registry/ISO/NTLite/VM unchanged by this session's confirmed operations.
- **ONE NEXT:** reconcile/resolve platform rejection under operator-guided allowed process before resuming same exact source transfer; do not increment version or infer G3B completion. Close Current FIRST / Handoff FIRST+SECOND / Session Entry LAST and GUI pause.

## G3B-D4 — operator reconnect, mirror recovery cumulative attempt 2/3 PASS

- Operator explicitly confirmed GitHub reconnect and authorized two remaining attempts for failed exact-source Git mirror; Session Entry temporary `G3B_MIRROR_RETRY_IN_PROGRESS` commit `428ef2453efa799ff29a83818560353facfee956` blob `0f6c354fc0866bd2abb9414043bb16e508b25962`, independently fetched; Master blob unchanged. Live RDC DESKTOP-4J4KCEA online, only two approved roots, 33 original blocked commands including reg.
- **Transfer attempt 2/3 succeeded:** read locally preserved exact source `03_Drafts/R002R26_G3_AppxManifestGraph_v2_DRAFT.ps1` as original Base64 bytes, RDC PID `1536`, then new GitHub development source mirror commit `209d0ec043374dd49a15d6b8634b674fbf9885a6`. Git blob `8bcc7a463edb3bf43e7969bdd4723c919960d4af`; bytes `16464`, 242 logical lines + trailing newline. No earlier file replaced.
- **Independent GitHub raw-byte readback:** Git contents API base64 returned all 16,464 bytes; pure SHA256 implementation was verified against known canonical SHA256('abc') before hashing bytes; **observed and original native SHA256 identical** `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`. Exact v2 mirror **PASS**. This is not manifest XML graph closure nor runtime candidate promotion. No retries beyond resolved attempt 2/3.
- **ONE NEXT:** review strict G1-negative cases and create distinct v3 source with in-memory-only ZIP/XML synthetic fixtures, preserving v1/v2; independently hash/AST/SelfTest and checkpoint each operation. Real 31-AppX `-Mode Verify` excluded from G3B.

## G3B-D5 — NEW local-only v3 synthetic test draft written

- Single owned write via scoped RDC `write_file`, new non-overwriting `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R26_G3B_AppxManifestGraph_v3_DRAFT.ps1`; returned `Successfully wrote ... (315 lines)`. Input exact Git-mirrored v2 blob `8bcc7a463edb3bf43e7969bdd4723c919960d4af`, unchanged G3 core; adds in-memory ZIP fixture constructor, strict archive-rejection checker, 23 appended synthetic cases and positive control, new explicit G3B SelfTest status string. Output is **DRAFT**, no source hash/AST/SelfTest PASS yet, not a production candidate. Parent v1/v2 not modified.
- **ONE NEXT:** independently direct local readback of full v3 to inspect inserted helper/tests and final mode-dispatch, then separate native SHA, AST, SelfTest.

## G3B-D6 — independent complete local v3 source readback

- Direct RDC `read_file` returned **315/315 lines** from new v3 only; beginning/closing dispatch, `New-SyntheticZip` helper, new exact negative fixture assertions and `PASS_R002R26_G3B_STATIC_SELFTEST_` marker all present. No original v2 overwrite and no local runtime claimed. Attempt 1/3.
- **ONE NEXT:** independent native SHA256 hash of frozen local v3 for source pin; then AST parsing separately.

## G3B-D7 — local v3 standalone native SHA256

- Native `pwsh.exe Get-FileHash -Algorithm SHA256` PID `7732`, process finished, SHA256 `C1F6E6AC17D52A0BC0EBA435248D58343D267240525D210617B03E995EF979DC` for `R002R26_G3B_AppxManifestGraph_v3_DRAFT.ps1`; independent original v2 SHA still `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`. Native numeric exit separately unavailable; stdout hash proven, **no AST/SelfTest result yet**.
- **ONE NEXT:** read-only AST parse of exactly v3, no source edits.

## G3B-D8 — AST wrapper quotation failure, NOT source AST result

- First AST subprocess command PID `3356` exited after outer Windows PowerShell expanded embedded `$t/$e` variables inside double-quoted `pwsh.exe -Command` argument; child printed parser error `You must provide a value expression following the '+' operator`. **Wrapper AST attempt 1/3; v3 source AST NOT_EVALUATED**, no v3 file change. This is a command-string quoting issue, not proof that v3 code is malformed.
- **ONE NEXT:** use literal-safe escaped variables in same intended bounded PowerShell AST-only command (attempt 2/3), with independent output and journal.

## G3B-D9 — v3 native AST 0 syntax errors after corrected wrapper

- Second cumulative AST wrapper attempt PID `7736` (outer-PowerShell variable escaping corrected) finished with literal `G3B_V3_AST_ERRORS=0`; exact local v3 source SHA256 still previously pinned `C1F6E6AC17D52A0BC0EBA435248D58343D267240525D210617B03E995EF979DC` (pre-run). No edits, no real manifest Verify. **AST0 PASS**, SelfTest still NOT_RUN. First wrapper failure remains in D8 history; cumulative 2/3.
- **ONE NEXT:** native v3 `-Mode SelfTest` synthetic ZIP/XML/provider test, separately capture precise result and journal before any correction or mirror.

## G3B-D10 — v3 native SelfTest FAIL_CLOSED, actual namespace predicate bug discovered

- **Native PID4996:** new 315-line, AST0 v3 `-Mode SelfTest` failed closed: `SELFTEST_WRONG_REJECTION expected=IDENTITY_INVALID actual=G3_HOLD_UNSUPPORTED_MANIFEST_NAMESPACE`, at exact synthetic valid Windows10 package XML `xmlns=http://schemas.microsoft.com/appx/manifest/foundation/windows10`. Cumulative new SelfTest attempt **1/3**; no real 31-AppX Verify and no v3 file modification.
- **Root cause from exact v2/v3 source review:** `Parse-Manifest` had root namespace regex `^http://schemas\\.microsoft\\.com/appx/.+/(manifest|bundle)(/|$)`; it requires an extra segment before `/manifest` and excludes expected `/appx/manifest/foundation/windows10`. Historical v2 12 negatives never exercised a valid manifest. This is a concrete parser namespace **dependency** bug, not permission for accept-all namespaces. Keep v3 immutable; create distinct v4 with narrowly corrected explicit Microsoft package/bundle namespace patterns and independently test.
- **ONE NEXT:** source-review and create new v4 with exact namespace-gate correction, AST/SHA individually, native SelfTest attempt 2/3; if another failure, diagnose before final attempt and preserve all drafts.

## G3B-D11 — v4 draft creator expansion ERROR, NOT_RUN

- Scoped RDC distinct new v4 draft **written**, `R002R26_G3B_AppxManifestGraph_v4_DRAFT.ps1`, returned 847 lines / 63486 JS source chars instead of expected ~320 lines. Cause: JS `String.replace(pattern,replacementString)` interpreted literal `$'` from end-anchored PowerShell regex in replacement as JS replacement special token (remainder-of-source), injecting repeated content. **This is a draft-creation bug**, detected from immediate write cardinality/char output, **NOT AST or native SelfTest attempt**. v3 original remains immutable, SelfTest cumulative 1/3. Keep v4 as failed owned historical draft, do not execute/promote.
- **ONE NEXT:** generate a unique v5 from the same v3 using callback-based literal replacement (no JS replacement-dollar expansion), assert exact new/old source diff and bounds before one local write. Then separately hash/AST and native SelfTest attempt 2/3.

## G3B-D12 — v5 corrected literal source replacement, new local draft written

- New non-overwriting local `R002R26_G3B_AppxManifestGraph_v5_DRAFT.ps1` written via RDC `write_file`: 317 lines / 23,158 chars, generated only from preserved v3 315-line source. JS callback-based literal replacement eliminates `$'` replacement expansion; exactly one old namespace predicate matched; exact source length change **+335 chars**, equal replacement-text length delta, no other planned change. New rule restricts package to Microsoft AppX manifest namespaces (including `manifest/foundation/windows10`) and bundle to explicit Microsoft bundle namespaces. Unchecked v4 retained unexecuted; v1/v2/v3 untouched. Source SHA, AST and SelfTest **not yet run**.
- **ONE NEXT:** independent complete readback of local v5, native SHA and AST, then SelfTest cumulative attempt 2/3.
