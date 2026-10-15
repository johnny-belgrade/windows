# BlueLite UUP / pre-download / MAX_PRE evidence reconciliation — 2026-10-13

**Purpose:** stop duplicate research, preserve operator's September–October primary evidence and identify **unresolved implementation gaps only**. This review is a targeted source-history audit, **not** a claim to have opened every file in the Library. Status may be promoted only by original operator logs and supported runtime tests.

## Sources reviewed / grouped (Library paths)

1. `/UUP_PreBuild/Drafts/`: 1/6/7/8/9 original launcher drafts; alternative converter CMDs and configs; original/alternate CustomAppsList variants; `Timeline.txt`, `Timeline-04-09-26.txt`, `Timeline-06-09-26.txt`, `Timeline-14-05.txt`, **`Error_Timeline.txt`**. Earlier destructive UUP/FoD queue filtering caused wimlib delta/reference failure: missing `wow64_microsoft-windows-mccs-syncres.resources` zh-tw blob and exit **55**, despite seemingly unrelated target packages. Non-removal of Windows reference/delta/FoD/Sense/network queue is **settled**.
2. `/BlueLite_MASTER/Custom_UUP/`: early `BlueLite_FilterUUP.ps1`, `BlueLite_FilterApps.ps1`, `BlueLite_PatchConverter.ps1`, `BlueLite_DebloatFinalWim.ps1`, `Timeline_CMD.txt`, patterns and source scripts. In particular `BlueLite_FilterUUP.ps1` supports direct destructive aria2 and directory filtering; this is historical evidence / **not** a procedure to re-enable for Windows reconstruction.
3. `/BlueLite_v1.0/Custom_UUP/` (TEST4 and 26200.9445): `ResolvedUUP.json`, `WindowsQueue.original.txt`, `AppsQueue.filtered.txt`, `FilterApps.log`, `GenerateCustomAppsList.log`, `FinalWimDebloat.log`, bootstrap and original source resolver; the selected 26200.9445 `latest` was once frozen to an exact UUID and recovered against original launcher evidence. This original dynamic source-intake research was already done.
4. `/BlueLite_v1.0/Final_UUP/` RC1.2: `BlueLite_UUP.cmd`, `BlueLite_ResolveUUP.ps1`, `BlueLite_Bootstrap.ps1`, `BlueLite_FilterApps.ps1`, `BlueLite_ResolveAppDependencies.ps1`, `BlueLite_GenerateCustomAppsList.ps1`, `BlueLite_VerifySource.ps1`, `BlueLite_DebloatFinalWim.ps1`, `Timeline-14-09.txt`. Successful 26200.9445 conversion confirms actual installation image reconstruction and update servicing with retained five staging top-level Apps and required framework references (not merely a conceptual plan); source queue was not pruned. `GenerateCustomAppsList.log`: **69 candidates, five top-level selected and 64 disabled**. `FinalWimDebloat.log`: **30 recorded actions**, compact WIM **6,547,002,104 → 6,209,369,921 bytes** (337,632,183 bytes saved) with zero reported warnings, a *historical build-specific observed* result, not a new-release or footprint guarantee.
5. `/BL_UUP/` and `/BlueLite_v1.0/` R1–R15-R1 MAX_PRE packs plus R4–R15 native/AMBER audit logs: later shared MAX_PRE modules extend RC1.2 beyond initial native capability/feature removal, with Store/Notepad floor, 37 capability selectors, 21 exact superseded families, Search/OneDrive/FoDMetadata/LPD/LPR/Recall portable AMBER, protected service/VM/network floor, snapshot/delta post-gates, health and backup transactions. The R15-R1 package SHA `7D59DD0F653967717CC4B84D47C50A9DE2863F7EB3DD9EF09B0221B3E05E7BE8`, ZIP 55 files, **static evidence only; no current 26200.9550 MAX_PRE runtime**.
6. Later `R19–R25` frozen-source/converter reports: **188/188 SHA-256 equal** across the two staged 26200.9550 UUP payload trees; this is content *equivalence*, not independent full source closure. R56 converter has 210 static interlocks and unconditional entrypoint `exit /b 86` in main and helper; C33 process broker DENY_ONLY. These were **already thoroughly investigated** and must not be restarted from raw shell audit without new evidence.
7. Operator-returned `R26-D1` to `R26-D3` logs: D1 false short SHA constant, D2 PASS dynamic *frozen source* audit, D3 PASS R15 *static integration contract*; network/download/conversion/mount/MAX_PRE mutation never executed in R26-D2/D3. D3 is a review wrapper, **not** a working one-click downloader/reconstruction.
8. Normative [Master Strategy §§6.3,7,7.8,22,29](BlueLite-Master_Germanium_Strategy_final.md): **universal Germanium 26200.xxxx**, source-selection explicit and frozen; keep complete reconstruction inputs; preserve immutable reconstructed WIM; disposable pre-ISO MAX_PRE + later offline PS residue work **before** NTLite and final ISO; then virtualized validation. Temporary Windows host writes are allowed while `C:\work` remains potentially persistent under §6.1A.

## Newly identified, concrete gaps (not an invitation to redo prior studies)

### G1. Existing UUP V3 Phase A2 acquisition is proved; integrating it into R26-D5 remains missing

- R26-D2 assumes `C:\work\UUP_Source\<source>\BlueLite_SourceContract.json` and `BlueLite_Source_OriginalHashes.csv` already exist. Its dynamic source selector solves selection among **already frozen** sources only; it does not perform first-time source intake/freeze.
- **Historical correction supported by primary Library evidence:** `UUP_V3_PhaseA2_AcquireSource_20261005_154849.txt` (2026-10-05), plus the original full PowerShell execution transcript in `5-ChatGPT(1).md`, already demonstrate **actual original UUPDump ZIP retrieval, checksum, pristine launcher, eleven-file manifest and valid SourceContract**. Do NOT write a brand-new general-purpose source ZIP acquisition algorithm or redo that exact freeze experiment. The still-missing part is **integration/reuse of this proven Phase A2 flow in the R26-D5 pipeline for each newly chosen 26200.xxxx**.
- Previous RC1.2 `BlueLite_ResolveUUP.ps1` already parses **untouched** UUP Dump `uup_download_windows.cmd`, validates exact UUID against original URL, optional metadata, ConvertConfig and checkpoint, and writes `ResolvedUUP.json`. Reuse/adapt that *existing* source-intake work and add the fully pinned manifest/contract writer instead of inventing a new selector or hardcoding 26200.9550.
- Preserve the unaltered original launcher; original source UUID/build are operator-chosen, never silently replaced by `latest`.

### Proven local D5 acceptance / next novel runtime boundary (2026-10-13)

- Original operator PS7 `BlueLite_R26_D5_Local_Gate.txt` shows `R26_D5_LOCAL_GATE=PASS`, 15/15 hashes, AST 10, two actual-UUP provider tests PASS, generic frozen-source Audit PASS. Fixture log confirms missing `Microsoft.UI.Xaml.2.8` fails closed. **No Internet download, converter or MAX_PRE was executed**. This is successful local downloader G4 draft validation, not full UUP conversion certification.
- **Next non-duplicate test:** retrieve actual **Windows and Apps aria2 queue files only** from original frozen source endpoints, apply the existing SHA-pinned D5 production queue-identity module to *real external traffic*, preserve downloaded small queue texts under `C:\work\logs`, and record metadata; never fetch 9GB payload to retest known R20 SHA equivalence. This tests previously unproven source endpoint/network format compatibility (and may fail due to dated UUID/endpoint, a useful finding).

### G2. R26-D2's terminal Windows queue check uses the **same file** as active and original

- `BlueLite_DL_R26_D2.ps1` `Run-Helper BlueLite_VerifySource.ps1` passes **`'-WindowsQueueFile',$qWin,'-WindowsQueueOriginalFile',$qWin`**. In the helper, both SHA-256 values are therefore from identical path and necessarily equal.
- R26-D2 has a separate `OriginalQueueHashes.lock.json` (initial external ledger) and an earlier pair of SHA checks, which partially compensates; do not claim its final VerifySource equality alone is independent evidence.
- Needed: physically distinct frozen/original queue snapshot or explicit independently verified persisted original hash passed to the verifier; require exact `out=/checksum` identity mapping, not simply count/file presence, as the verification contract.

### G3. Resume and expiring transport URLs are not separated from content identity

- Real historical `WindowsQueue.original.txt` records use time-bound signed Microsoft download URLs with `P1` transport expiry and `checksum=sha-1=...` plus `out=...`. R26-D2 `Queue-Fetch` always reuses an existing saved queue from disk when present.
- On later days a valid cached *content identity* can have expired URLs even though the output set is unchanged. Need a controlled refresh path which verifies immutable content identities (`out`, checksums, UUID) independently of volatile URL parameters before replacing only transport URLs. No stale/unknown source promotion.
- Offline no-network fixtures can prove the identity-vs-transport behavior without repeating a massive UUP download.

### G4. AppX dependency closure requires a measured unresolved-dependency disposition

- The R15 `BlueLite_ResolveAppDependencies.ps1` recursively parses MSIX/AppX manifests and selected bundle members; it is **not the same as merely keeping static names**. It currently logs any unresolved dependency which lacks an Apps queue record as an `OS/external` dependency, and can exit 0. Some may genuinely be OS components, but this classification needs a **verified current-image/provider** gate rather than granting automatic full closure.
- The RC1.2 predecessor **deliberately bypassed** the dynamic resolver as a v125r/CompDB broad staging closure had worked on 26200.9445. R26-D2 re-enables the resolver for the first time in this branch. This is **unproven behavior requiring targeted actual-queue fixture validation**, not a reason to redo AppX policy research.

### G5. Immutable original WIM vs MAX_PRE promotion/backup retention

- R15-R1 `BlueLite_PreDebloatWim.ps1` uses `[IO.File]::Replace($exportWim,$WimPath,$backupWim)` (source lines ~1890) and later `Remove-Item -LiteralPath $WorkDirectory -Recurse` (~1928), which includes the transaction backup. R15 can do correct transactional recovery during the run, but it does not itself guarantee a persistent immutable baseline after success if invoked with the only reconstructed WIM path.
- Master §7.8 requires the pristine WIM to remain immutable and *outside* mutable promotion. Integrate by creating/checking a separate immutable reconstructed authority and making the R15 **WimPath explicitly a disposable derivative**; decide full backup-retention policy before any integration runtime.

### G6. Build-family scope and order-of-stages mismatch

- **Superseded production scope note (2026-10-15):** R26-D2's broader historical family declaration is no longer authoritative. **MASTER v5.0.0 accepts only 26200.x, 26300.x and later verified Germanium**. R15's original certified profile remains restricted to its actually proven family until the new dependency rules are certified. A servicing-base version in a historical reconstruction log is not a supported UUP release target. Audit the build-policy module against the active policy, not an old static D2/D3 claim.
- The pipeline is **UUP input → reconstruction/update → immutable WIM → disposable MAX_PRE → remaining offline PS/GREEN/AMBER/residue → NTLite → re-certification/branch → final export/ISO → VirtualBox**. An ISO made *before* offline PS finishing is not the canonical release order (the earlier assistant visual pipeline mislabeled it).

## What is already proved vs what must be developed

- **Proved in earlier operator runtime for 26200.9445:** original-launcher exact-source resolution, full reference queue conversion, updated `install.wim`, stage AppX selection, 30-action native offline pass and WIM size reduction on that historical build.
- **Proved static only:** portable R15-R1 MAX_PRE source/AST/audit, R26-D2 frozen-source audit, R26-D3 R15 source contract, 188 staged-source equality, C33 R56 fail-closed static interlocks.
- **NOT proved:** R26-D2 `Download` execution on a *new* build, correct resume after signed-URL expiry, complete AppX closure classification on live source, full reconstruction against current frozen input with protected transactional WIM, R15-R1 applied runtime/post-health in that image, target ISO/footprint.
- **Next concentrated engineering work** should be **one source-intake / queue-identity / resume+dependency-closure integration change set**, grounded in original RC1.2 modules and real queue fixtures. It must be reviewed under PS7 AST and test negative fixtures locally, without another 188-file duplicate payload download just to re-prove known content identity. Implement and test on **operator-owned files** with one command at a time. Do not resume C33 converter 200-site forensics as the default next step.

