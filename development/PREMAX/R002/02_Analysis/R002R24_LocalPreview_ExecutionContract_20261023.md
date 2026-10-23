# BlueLite R002-R24 — bounded local URL-free out-name preview execution contract

**2026-10-23. PREPARED_NOT_RUN / SOURCE_DELIVERED / AST_AND_3_NEGATIVE_FIXTURES_PASS.** This contract is a future single reviewed local-only metadata-preview action, NOT an assertion that the R24 script has been executed or that metadata-only candidate enumeration verifies actual AppX dependency closure.

## Immutable pins / native preflight

- Source build 26300.9807 Pro amd64 en-US, UUID `687d1ced-aab1-4cd5-ad05-705189769731`, original ZIP SHA256 `83203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7`.
- [Frozen complete R24 v1 script](../03_Drafts/R002R24_9807_URLFree_SeedPreview_v1_DRAFT.ps1), Git commit `d12238c81d78b04ff86e2d7c29f12f9879a6c50a`, blob `9b41de86c29b0bc9c0df209e372e0907f8159c98`, **8371 bytes**, native SHA256 **`3E3C6E1273585DA36311ED668B952D2F0464FD203B96C8CB54C542AAFE0F5406`**. Already delivered full-text exact to `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R24_9807_URLFree_SeedPreview_v1_DRAFT.ps1` with full RDC readback.
- [Actual native C2b source-only test/receipt](R002R24_C2B_NativeStatic_Result_20261023.md), commit `f8c3a49a427c9303ed76b8567baa799b695d0043`: PS7.6.7 parser0, unsafe command AST hits0, automatic input/matches refs0, in-memory positive2 plus negative fixtures3/3 PASS. No script-top-level Preview runtime has occurred.
- Actual R23 immutable safe JSON `05_Evidence\R002R23_MetadataInventory_001\R002R23_SafeQueueInventory.json`: 485382B/SHA256 `0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6`, 98 Windows/2798 Apps, exactly `queue,out,checksum`, original queue hashes separately retained.
- Original local S06 G4 source files, all independently verified in B PS7 native: `BlueLite_AppAllowPatterns.txt` `B099C3F688A8AEC7AF151E838E263DC713D05432F682117E002AD0BDC19B49DB`; `BlueLite_AppAlwaysKeepPatterns.txt` `DA6638876F07453A3185F0EC420FA7FD52C615D9CA29702F9E89E6CCC72F8B5B`; `BlueLite_RequiredStagingApps.txt` `3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265`; `BlueLite_FilterApps.ps1` `827CC9BAC9B8690AC05BDD45545138ABB9FDBD097AE47CD37AA51496157C8BD8`; `BlueLite_ResolveAppDependencies.ps1` `D9835FC164FDC2C6684DF44798E9F41EDFC9961F889B112BE27CD984441015FF`.
- Fresh RDC get_config must still show only approved roots `C:\work` and `C:\BLR20R2F5`, all 33 original blocked commands, no unrelated live session. Fresh source/AST/hash and **absent target output folder** before execution. Never overwrite existing partial evidence or retry with another output root.

## Future permitted action: one ordinary PS7 -File local preview ONLY

User/operator explicitly resumes this precise reviewed action after this source+contract and all necessary §0R documents are read back. The invocation requires exact literal authorization token and must not contain any network or Windows-image mutation command:

```powershell
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R24_9807_URLFree_SeedPreview_v1_DRAFT.ps1" -Authorization "I_APPROVE_R002R24_LOCAL_OUT_ONLY_PREVIEW_ONLY"
```

Only new local owned output path: `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence\R002R24_URLFreeSeedPreview_001`. Expected two small URL-free files, `R002R24_URLFree_SeedPreview.json` and `R002R24_Native_Preview_Receipt.json`; CreateNew, no replacement. Expected source/out-only selection: Apps 2798 / Windows 98 unchanged; 27 name candidates including one AggregatedMetadata.cab and five canonical **staging** identities, checksum carried forward from exact R23 entries. Staging5 versus final4 unchanged.

Bounded RDC process observation: at most 30 seconds with short polls. If timed out, terminate **only** its recorded owned PID process tree through allowed safe action, retain partial artifacts, check absence of processes, declare HOLD and pause; do not auto-retry. If platform refuses invocation, record it as platform refusal (not a native PASS) and do not bypass. No heavy download/aria2/converter, AppX payload read, OS image, registry, DISM, NTLite, VM, ISO or WIM work; no need to change allowed roots or blocklist.

## Native acceptance and independent post-state

Require actual native exit 0, literal `PASS_R002R24_OUT_ONLY_PREVIEW_NOT_CLOSURE`, script SHA, R23 SHA, 27 candidate records and five canonical identities, zero HTTP, `manifest_dependency_closure=NOT_EVALUATED`, `runtime_execution_allowed=false`; two and only two owned output files. Independent native readback of both JSON files must check actual local byte lengths and SHA against receipt; strict `out/checksum/role` keys and no URI/URL; each projected candidate must equal exact R23 Apps `out+checksum`; expected five identity anchors and one metadata role; no duplicate `out`, foreign language or foreign arch; input JSON and five G4 SHA immutable; original source script same; process exited. Do not silently treat native stdout return code or receipt presence alone as full PASS.

**Proof boundaries:** This would prove a URL-free out-only preview ONLY. Original G4 filter matched complete URL-bearing record (not present in safe R23 JSON), so filter parity `UNPROVEN_URL_FIELDS_INTENTIONALLY_EXCLUDED`. Payload content hashes, MSIX/AppX AppxManifest.xml dependency provider name/publisher/minimum-version/architecture closure, original pre-renewal queue, vendor converter/MAX_PRE/servicing/release remain separately unproven. Only a separately approved, hash-pinned actual payload/manifest reuse or transfer can satisfy these later requirements.

On verified R24 runtime evidence, first Current+Handoff readbacks, then propose exactly one dependent successor step, sync R002 CycleManifest/CycleRegistry and Sources as warranted, §0R SECOND and Session Entry LAST. Master, RecipeRegistry seven runtime flags, protected connector settings, historical R23 original and all mutation approvals remain unchanged.
