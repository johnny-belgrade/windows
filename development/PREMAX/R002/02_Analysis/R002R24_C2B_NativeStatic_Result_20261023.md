# BlueLite R002-R24 C2b — Native PS7 v1 source/AST and synthetic negative tests

**Actual source-only run on 2026-10-23: PASS_R002R24_C2B_SOURCE_AST_AND_NEGATIVE_FIXTURES** via scoped Desktop Commander outer PID 7936 and native PS7.6.7 PID 5440. Native stdout JSON was observed and analyzed directly; this document transcribes its proven fields, not an independent byte-for-byte capture of the process stream.

## Exact source and boundaries

- Frozen [R24 source](../03_Drafts/R002R24_9807_URLFree_SeedPreview_v1_DRAFT.ps1), commit `d12238c81d78b04ff86e2d7c29f12f9879a6c50a`, blob `9b41de86c29b0bc9c0df209e372e0907f8159c98`. Whole-text local RDC readback matched Git content before native test.
- Native `Get-FileHash` SHA256 **`3E3C6E1273585DA36311ED668B952D2F0464FD203B96C8CB54C542AAFE0F5406`**, native file size **8371 bytes**, native parse errors **0**.
- Native AST command set: `AssertHash,ConvertFrom-Json,ConvertTo-Json,ForEach-Object,Get-Content,Get-FileHash,Get-Item,IsForeignArch,IsForeignLang,Join-Path,NewExclusive,ReadPatterns,SelectPreviewCandidates,Set-StrictMode,Sort-Object,Test-Path,Where-Object,Write-Output`. Forbidden-command hits **0** within the explicitly reviewed set; automatic `$input` / `$matches` AST references **0**. This is not proof against every possible .NET side effect; the specific source has been reviewed for the local CreateNew behavior.
- Test harness: local `04_StaticTests/R002R24_C2B_NativeAstAndFixtures_v1.ps1`. It imported **only** source-pinned `IsForeignLang`, `IsForeignArch` and `SelectPreviewCandidates` function definition text from the parsed script AST for in-memory tests. The script's top-level code was **never invoked**.

## Actual fixtures

- Positive and exclusion fixture included `Calculator_11.2311.0.0_x64.msix`, `AppInstaller_language-af.msix`, `NotepadApp_x86.msix` and the R23 aggregate metadata filename. Expected/observed **2 candidates** (calculator plus reconstruction metadata); foreign language/architecture exclusion gates PASS.
- Three synthetic negative cases all refused: malformed checksum, case-folded duplicate Apps `out`, and unsafe `..\\` name. Native JSON reported `invalid_sha=true,duplicate_out=true,unsafe_path=true` — **3/3 PASS**.
- Future `05_Evidence/R002R24_URLFreeSeedPreview_001` directory **absent**, `preview_runtime_executed=false`, network requests **0**, image mutations **0**. No R24 full Preview, payload retrieval or manifest dependency-closure test has occurred.

## Exact bounded NEXT

**ONE NEXT C3:** prepare frozen execution/independent-verification contract for R24 local-only preview, including all source and G4 SHA pins, output collision guard, one ordinary `-File` launch only after separate checkpoint and explicit operator continuation, local poststate checks and failure preservation. Do not automatically execute Preview as part of this C2b result. The previous R23 pass is still the latest genuinely executed full metadata step. Master/RecipeRegistry/mutation approvals remain untouched.
