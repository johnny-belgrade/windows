# R002-R26 G3 — granular read-only parser development journal (2026-10-24)

**Phase:** G3 scoped source-only IN_PROGRESS, no native archive Verify yet. Existing R002 owner; Master 6.3.1 Git blob `00d3d34e97c35d6fde241f5aa47f17de050d6eb7` unchanged. Operator authorized read-only draft/static negative tests via Handoff §0BL; not WIM/ISO/registry mutation. §0BE individual action/checkpoint/readback and §0R mandatory.

## G3-PRE — successor bootstrap / targeted source preflight (attempt 1 each)

- Actually read full attached Master 1625 lines, live Git Master header+matching blob, Session Entry `30cb886fb5ad152b43cfb9969c40f0abf7b8db6d` and Current TOP `745ae4ef82e5315d634a2671a2a515cf073fefd1`; Handoff current `3b34cfc1b0f1436bb5cb62171aa008f0ca746f39`, §§0BP/0BL/0BE/0BF/0R/0S/12B. Live Sources `275265a873ad15761ff082be9ec7434e8a7f04d3`, Contracts README `144889b63173adc392ff046826cf8dadcf914b78`, Registry r38 `44f6c2f37cf9d4fd8c10331b491ff3d75c7c136b` (runtime flags remain false).
- Last **actual** G2 receipt: target `26300.9807`, original R23 Apps URL-free inventory SHA256 `0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6`, frozen G1 matrix Git blob `a118b7e5510fb0153ae32f0d3f651566b878d7b1`, F4 26/26 seed SHA1 + G2 5/5 provider SHA1 = 31/31 **transport binary identities**, but `AppxManifest.xml` dependency graph not evaluated. Target-specific CAB absent/unverified. G1 exact design blob `8bcdee85a14bfaf7c58842db9021418dcdd8747c` read and reused, no redundant resolver re-creation.
- RDC live `DESKTOP-4J4KCEA` ONLINE v0.3.1, allowed only `C:\work` and `C:\BLR20R2F5`, existing 33 blocked command names incl. `reg`; no config mutation. Actually read local `C:\work\UUP-history\00_README.md` (38 lines) and `C:\work\PREMAX-work\00_README.md` (66 lines), targeted first canonical RH06 mapping index entries (2,416 rows) and original local F4 `R002R26_F_ReuseGate.json` first 48 of 206 lines to verify `files[].out/expected_sha1` shape. Library targeted lookup found historical S06 G4 receipt information (stale .9711 only), current G1/G2 Git governs .9807.
- Inspected local `R002\03_Drafts` direct directory: 18 existing files, **no G3 parser draft collision**. No host process, package read or archive extraction, download, WIM/CBS/registry/ISO, NTLite/VM; bootstrap Git Session Entry set `IN_PROGRESS_PREPARATION_ONLY` commit `1eb1e38625c3d8058020eca36758e7408c0c224d` blob `b0427dfc4872617de70dccf0cd61b6506d139204`, independently fetched exact.

**Source protection:** frozen source/cache unchanged. No change to Master, Recipe Registry or existing SHA-pinned scripts. Next planned operation: author only a new `R002R26_G3_AppxManifestGraph_v1_DRAFT.ps1` inside R002 `03_Drafts`, with explicit fail-closed parsing and negative fixtures; no native Verify until AST and source guards pass. Report target/shas and exact failure categories rather than borrowing G4 .9711 closure.

**ONE NEXT:** new G3 source write into the existing approved development workspace; then separately read back/hash and document its result before any test.

## G3-D1 — FIRST local source write, no execution (attempt 1/3)

RDC `write_file` succeeded for **NEW** owned `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R26_G3_AppxManifestGraph_v1_DRAFT.ps1`, 242 nonempty/current lines reported (source content 16,448 JS characters before transfer). This is a **draft**, not reviewed/promoted/certified or executable approval. Source targets 31 content SHA1-pinned AppX transports from F4+G1, ZIP entry checks/size bounds, entity-disabled XML manifest parser, bundle nested children, exact provider graph and local SelfTest negative fixtures, an output-absence guard. **Do not claim AST, native SelfTest or full Verify from successful file delivery.** No existing draft/image/cache was overwritten.

**ONE NEXT:** independently direct-read back this exact new local source and obtain native SHA256/AST separately; journal each action and independently read back before subsequent action.

## G3-D2 — independent local direct source readback (attempt 1/3)

RDC direct `read_file` from the **same exact new source path**, independent of the writing call, returned **242/242 lines**, full beginning (Param/SHA/ownership guards) and intact final `if ($Mode -eq 'SelfTest') { SelfTest } else { Verify }`. Expected read-only functions present, no partial/truncated remote source. This verifies line content presence, **not native file SHA256 or PowerShell AST**; neither has run. No second write or mutation.

**ONE NEXT:** one separately scoped read-only native PowerShell SHA256 of this exact new source; then journal/readback and isolated AST.

## G3-D3 — native read-only draft SHA256 (attempt 1/3)

RDC `start_process`, shell `powershell.exe` invoking PowerShell 7 Get-FileHash on only new 242-line draft, native PID **1228**, completed stdout SHA256 **`C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46`**. Remote tool reports process finished; numeric native exit was not separately exposed. No source/cache writes, packages read, network, WIM or registry. This is a content pin **not** AST, negative fixtures or manifest closure.

**ONE NEXT:** single independent PS7 parser/AST0 check of exact pinned local new source, read-only; document and read back the result before negative fixtures.

## G3-D4 — read-only PS7 AST parser check (attempt 1/3)

RDC `start_process` using **pwsh.exe**, native PID **7912**, parser `System.Management.Automation.Language.Parser::ParseFile` against new source with frozen SHA256 `C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46` completed and emitted literal `AST_ERRORS=0`. Only syntax validated, **no SelfTest, Verify, package archive read, output JSON or graph closure**. Native numeric exit unexposed. Original G1 matrix remains source-pinned; no code promotion.

**ONE NEXT:** invoke isolated source-only `-Mode SelfTest` against **unchanged SHA-pinned draft**, record exact negative-fixture stdout/error and limit retries to 3 total; then journal independent readback. No Verify or cache reads in this step.

## G3-D5 — FIRST native v1 SelfTest FAIL_CLOSED (attempt 1/3 for this SelfTest issue)

RDC native **PID6740**, unchanged v1 SHA256 `C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46`, `-Mode SelfTest`, process completed with red exception at draft line 170: `SELFTEST_WRONG_REJECTION expected=INVALID_ZIP actual=Cannot convert the "System.Collections.ArrayList+ArrayListEnumeratorSimple" value of type ... to type "System.IO.Stream".` **NOT PASS** despite AST0, provider graph Verify **NOT_RUN**, no source packages opened, no owned graph output, no image mutation. One attempt for this logical SelfTest failure; do not blind retry. The exception shows a test harness type/binding problem before intended invalid-ZIP gate; need targeted read-only review of exact fixture and function signature, then create **NEW versioned v2** if needed (v1 immutable for audit). No platform/safety bypass.

**ONE NEXT:** inspect only v1 lines surrounding the faulty `INVALID_ZIP` synthetic fixture and `Read-Archive` invocation, determine exact cause and patch in *v2*, then AST and negative SelfTest as separately journaled steps, not G3 real Verify.

## G3-D6 — focused read-only v1 fixture/function review (attempt 1/3)

Independently read exact original local draft lines around `Expect-Hold`, `SelfTest` and `Read-Archive` invocation. The `INVALID_ZIP` test is passed a `System.IO.MemoryStream`, but the declared `Read-Archive([System.IO.Stream]$Input, ...)` reuses **PowerShell automatic `$input` variable** (case-insensitive); its value can be a pipeline enumerator rather than the caller's stream. This accounts for native observed `ArrayListEnumeratorSimple`→`Stream` conversion error. **Technical hypothesis from source/error**, not yet corrected/tested. Do not retry unchanged v1. Scoped fix: new v2 with exactly `Read-Archive` formal `$Input`→`$SourceStream` and corresponding ZipArchive constructor argument; leave v1 frozen. Source draft status `AST0_BUT_SELFTEST_FAIL_CLOSED`, G3 Verify NOT_RUN.

**ONE NEXT:** create non-overwriting v2 from pinned native v1 SHA with exactly two reviewed replacements and output collision guard; then separate direct readback, hash, AST and SelfTest, with each action independently journaled/readback.

## G3-D7 — new v2 draft creation PASS (write attempt 1/3)

One source-bound local PS7 process **PID6620**, first attempt, checked **v1 SHA256 exactly `C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46`**, nonexistence of v2, and each of two exact source anchors once, then created **NEW** `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R26_G3_AppxManifestGraph_v2_DRAFT.ps1`, stdout `CREATED_V2_ONLY_TWO_SOURCE_SUBSTITUTIONS`. Two intended textual replacements rename function parameter `Read-Archive(...$Input...)` to `$SourceStream` and ZipArchive constructor argument to `$SourceStream`. v1 unchanged; no script executed here, graph Verify NOT_RUN, no source cache, WIM or registry edits. Native tool completion, numeric exit unreported.

**ONE NEXT:** independent local v2 full readback and SHA256/diff proof in isolated operations; log/readback after each, then AST and second cumulative v2 negative SelfTest.

## G3-D8 — independent new v2 direct local readback PASS (attempt 1/3)

RDC direct `read_file` of exact new v2 path returned **242/242 lines**, with `function Read-Archive([System.IO.Stream]$SourceStream` and ZipArchive constructor consuming `$SourceStream`, former `Read-Archive(...$Input` absent; end-of-file SelfTest/Verify dispatch intact. Source not executed. This is independent syntactic-presence QA, not byte-level full diff/AST or native negative fixture proof.

**ONE NEXT:** independently compute v2 native SHA256 and exact full-file v1→v2 two-substitution diff, recording native result before executing SelfTest.

## G3-D9 — native v2 SHA256 receipt PASS (attempt 1/3)

RDC native PS7 `Get-FileHash` on exact new v2 draft, PID **1532**, completed with stdout SHA256 **`75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`**, numeric native exit not separately exposed. Original v1 pin `C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46` remains distinct and unchanged; no archive Verify, no WIM/cache edits. v2 is still DRAFT.

**ONE NEXT:** read-only exact v1→v2 normalized text compare asserting only two intended substitutions; then independent checkpoint readback before AST and native SelfTest attempt2.

## G3-D10 — independent v1→v2 full-text difference QA PASS (attempt 1/3)

Read-only native PS7 PID **2124**, separately obtained full original v1/v2 UTF8 text; compared entire v2 with v1 after exactly two expected, source-literal parameter/constructor substitutions. Native stdout `PASS_V2_EXACT_TWO_TEXT_SUBSTITUTIONS`, completed. v1 SHA `C7964D4C7B5D1820A4C40E25B8C6640C96BD04ECCE3FB5F75E24975F070DDF46`; v2 SHA `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`, distinct versioned files. Neither ZIP/MSIX source bytes nor WIM accessed in this compare. No parser runtime success inferred.

**ONE NEXT:** one isolated read-only PS7 AST0 v2 check, followed by its independent Git journal readback, before second cumulative native SelfTest.

## G3-D11 — separate v2 PS7 AST verification PASS (attempt 1/3)

RDC native **PID448**, exact local v2 source SHA256 `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`, read-only PowerShell 7 parser `System.Management.Automation.Language.Parser::ParseFile` completed with literal stdout **`V2_AST_ERRORS=0`**. Native numeric exit not separately surfaced; no v2 SelfTest or real archive Verify run by this operation, no cache/source-image/registry mutation. Source was exactly v1+two reviewed parameter/constructor substitutions (D10). **ONE NEXT:** native v2 `-Mode SelfTest`, cumulative attempt 2/3 for original INVALID_ZIP fixture failure; journal original outcome/readback before any new action.

## G3-D12 — second cumulative native SelfTest v2 PASS (attempt 2/3)

PowerShell 7 remote process **PID7720**, frozen local **v2** SHA256 `75CAED7CC858D9FF1C131BBFDA7880F7E2D9CCEDE3F1F14C21373D1F660C2B1E`, actual `-Mode SelfTest` completed with exact stdout **`PASS_R002R26_G3_STATIC_SELFTEST_12_NEGATIVE_FIXTURES_NOT_SOURCE_GRAPH`**. First native v1 attempt (PID6740) failed closed on `$Input` automatic-variable collision; this v2 attempt **2/3 resolved** the same SelfTest issue. Numeric process exit was not separately exposed. 12 local synthetic fixtures only: **not** all G1 design cases, no real ZIP/AppxManifest XML graph verify, no 26300.9807 target-specific CAB, no source/cache/image/network/registry modifications and no release certification. v1 draft preserved unchanged; v2 remains DRAFT, not production promoted.

**ONE NEXT:** close this G3 parser-development logical block with exact source-bound static result in Current FIRST, Handoff FIRST/SECOND, and concise Session Entry LAST; separately review extended negative ZIP/bundle fixtures and source provenance before any real 31-archive Verify; §0E GUI pause.

## G3-D13 — Handoff §0R FIRST large-file independent SHA blob readback PASS (read issue resolved 3/3)

After Current FIRST commit `9d5cf3a590ddd37b7e698aba6ce51f5ad5b03a84` blob `afb0bac436f7b8a112b290dd90010e3c0692d2ec` independent content readback PASS, Handoff §0R FIRST GitHub update returned commit **`36ff6c6f8bce4bce38c26ceeffa1985704e68e37`**, new blob **`2e1fe99c9bf500246323d6926e740f3e237ffdb2`**. Two `fetch_file` content attempts produced **empty `content` despite accurate new SHA** on this unusually large Handoff (large API content-read limitation, not evidence of deleted file); a third independent read via native GitHub connector **`fetch_blob` of that exact returned SHA** delivered **1,045,751 full characters**, beginning with unchanged canonical Handoff title and new `## 0BQ` / `§0R FIRST` G3 entry, ending with historical original Handoff close. Thus **readback verified from exact blob**, not an inferred status based on update response. No alternate connector, bypass, repo force write or retries beyond three. §0R FIRST PASS and original append-only history preserved.

**ONE NEXT:** prepare reviewed G3B strict additional ZIP/bundle fixtures as later SINGLE next block; write Handoff §0R SECOND with exact source SHA and `STATIC_ONLY` gate, independently `fetch_blob` complete committed content, then Session Entry LAST and pause.

## G3-D14 — Handoff §0R SECOND closeout PASS; Session Entry LAST pending

Handoff §0R SECOND GitHub CAS with full **1,045,751-character** prior SHA-pinned first-stage content preserved and reviewed G3B one NEXT added; commit **`6445008d67395d5d9698931b5db5002c7ffa9ed4`**, blob **`9a875fff719e8979e9a6b4c2ca742253ff71877a`**. Independent **GitHub `fetch_blob` exact new SHA** returned full **1,048,355 characters**, first and second G3 sections correct, history intact through original ending; readback PASS. Current FIRST Git blob `afb0bac436f7b8a112b290dd90010e3c0692d2ec` exact readback PASS. No Master, Registry or local config edits. G3 v2 source remains locally frozen DRAFT, AST0/SelfTest12 PASS only, no actual ZIP source archive graph Verify. **ONE NEXT:** replace temporary G3 IN_PROGRESS marker in compact Session Entry **LAST**, independently read back, then GUI_PAUSE_AWAITING_OPERATOR; later G3B strict ZIP/bundle additional negative test development only.
