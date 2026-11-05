# R010 OP01 — immutable native HOLD intake, exact bug RCA (2026-11-05)

User/operator returned seven original root-level files for **R010 v1**: `BlueLite_R010_HOLD.json`, `BlueLite_R010_OP01_SourceReport.json`, `BlueLite_R010_OP01_Receipt.json`, `BlueLite_R010_OP01_Verify.json`, `BlueLite_R010_OP02_OverlayReport.json`, `BlueLite_R010_OP02_Receipt.json`, `BlueLite_R010_OP02_Verify.json`. Preserved without overwrite. Exact operator stdout: `OP01_INDEPENDENT_VERIFY_PASS`, `OP02_INDEPENDENT_VERIFY_PASS`, `R010_HOLD OP03: R009 receipt/verify ordering not monotonic`, parent exit **17**. Operator HOLD UTC `2026-11-05T13:31:23.8490356Z`.

## R010 original OP01 + OP02 **PASS** independently reviewed
- v1 source hash `69212C74DFFF366458ABA6151303E0ABBB74C316E3EA3A9804190A1A77790BB1` matches receipt-script identity.
- OP01 receipt SHA256 `B3B6562BDAF938721283E5DAFB49E50D13744FFBF6D9477763DCFEC0F8D35675`; independent Verify explicitly pins it; report SHA256 `878F4A26BB8268BBCBC90ACFB32D6E47111EC3113B771C444B525B17147F6CC5`, 15 source members, exact original/stage proof, PASS.
- OP02 receipt SHA256 `6FB389EF65ABF228B5170DAD2C08E5C0B982ABD96C5742491B8EC4717837C4FD`; independent Verify explicitly pins it; report SHA256 `465AFF961E9E5FB6B58A7DA7723FA2ECF5D93066A72497E06A6AC5AC7121BF30`, 37 overlay members, 15 PS1, START present and **not executed**, PASS.
- R010 v1 HOLD root SHA `D1ACEEACB2B405123C118F11D7D19EEEFE748C34CA9298B187260F2033E3D789`. The v1 script did **not** create an OP03 PASS receipt, ZIP, or full-runtime operation. Correct fail closed. No v1 overwrite or blind rerun.

## Independently verified root cause, not a source-time violation
R009 original ZIP SHA256 `7FCE894119179A34DBF6B2E903F795022EE0E8E2FDD54F6208248191509F128C`, OP05 receipt and Verify read from original user uploads. Original ten UTC strings **strictly increase** (9/9 positive deltas). First three: OP01 receipt `2026-11-05T12:51:20.1011288Z`, OP01 Verify `2026-11-05T12:51:20.4332050Z`, OP02 receipt `2026-11-05T12:51:20.4971423Z`.

In R010 v1 `ReadJson` uses `ConvertFrom-Json` default ISO timestamp conversion. The expressions `[DateTimeOffset]::Parse([string]$rec.utc)` and `...ver.utc` first stringify the already-parsed DateTime, **dropping fractional seconds**. Thus the false `-gt` comparison sees same-second timestamps as equal.

Direct Windows RDC PowerShell 7 diagnostic (read only; no shell image work) faithfully recomputed the old v1 logic on original R009 files: `CMP 1 GT=False DeltaTicks=0`, `CMP 2 GT=False DeltaTicks=0`, `CMP 3 GT=False DeltaTicks=0`, `CMP 4 GT=False DeltaTicks=0`, confirming timestamp precision loss. Correct remedy is `ConvertFrom-Json -DateKind String` (PowerShell 7.6, preserve exact ISO strings), parse as `DateTimeOffset`, and compare `.UtcTicks` with clear pair-identifying failure; positive tests and negative shuffled test required. No changes to original R009 files or Master.

## Hard requirements for R010R1
- **RESUME from already verified R010 OP01+OP02**: do not rerun these native steps; instead source/readback verify their immutable report/receipt/Verify hashes and their byte-bound input paths in a new scoped `R010R1_OP00` resume gate.
- Corrected R010R1 code version with **new script basename**, exact hash to operator, new `BlueLite_R010R1_*` output filenames (direct `C:\work\logs` **root only**) so original failed `BlueLite_R010_*` remains immutable.
- New OP00 receipt→separate fresh PS7 Verify→OP03 receipt→separate fresh PS7 Verify→OP04 archive receipt→separate fresh PS7 Verify. One CreateNew file per output; no output directory creation; no START/network/converter/WIM/CBS/ISO. On HOLD, new root `BlueLite_R010R1_HOLD.json`.
- Return one new evidence ZIP + final OP04 receipt/Verify, all in root; independent review before Current promotion. Update compact Current by fresh blob CAS + independent GitHub readback after artifact source QA.

**ONE NEXT:** versioned R010R1 source-only resume PS1, source static QA and exact PS7 UTC regression fixture tests; then operator run and return independent receipts. Source-only R009 and original R010 OP01/02 maintain PASS; R010 v1 OP03 remains HOLD.
