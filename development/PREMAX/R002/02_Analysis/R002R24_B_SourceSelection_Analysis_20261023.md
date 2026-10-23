# BlueLite R002-R24 B — Native input/policy source proof and safe out-only selector boundary

**2026-10-23, B SOURCE/PIN PASS — no R24 candidate script yet.** Operator-approved continuation of R23 last verified local-only inventory, under individual process write/readback protocol. Local native PS7.6.7 -File verifier `04_StaticTests/R002R24_B_SourcePins_v1.ps1` executed via RDC outer PID1020/native PID4124, result `PASS_R002R24_B_SOURCE_PIN_AND_OUT_ONLY_DISCOVERY`. It made zero external requests and zero image/registry mutations.

## Actual local/native SHA checks

The real local R23 URL-free JSON is SHA256 `0058049376679F6011F9BD3C9D51FE49BD631E46D843E38CF09E15D7AFD1CDE6`, 2,798 Apps records (plus original 98 Windows retained separately); R23 source output remains immutable. G4 pinned local files exact compared with the hash manifest:

| Original local G4 file | Actual SHA256 | Gate |
|---|---|---|
| `BlueLite_AppAllowPatterns.txt` | `B099C3F688A8AEC7AF151E838E263DC713D05432F682117E002AD0BDC19B49DB` | PASS |
| `BlueLite_AppAlwaysKeepPatterns.txt` | `DA6638876F07453A3185F0EC420FA7FD52C615D9CA29702F9E89E6CCC72F8B5B` | PASS |
| `BlueLite_RequiredStagingApps.txt` | `3812FFA2EBE6085889F007D1522D2EC3F970A9C23E1457B8B2D73798FD252265` | PASS |
| `BlueLite_FilterApps.ps1` | `827CC9BAC9B8690AC05BDD45545138ABB9FDBD097AE47CD37AA51496157C8BD8` | PASS |
| `BlueLite_ResolveAppDependencies.ps1` | `D9835FC164FDC2C6684DF44798E9F41EDFC9961F889B112BE27CD984441015FF` | PASS |

Native B compared G4 allow+always patterns with `out` only, filtered foreign language and x86/arm64/arm filename tokens according to historic policy semantics. **27 candidate out-only entries** resulted including `AggregatedMetadata.cab`: AppInstaller scale/stub/x64/bundle, Calculator scale/x64/bundle, Lightbox (Photos) scale/x64/bundle, Notepad scale/x64/bundle, plus Microsoft.SecHealthUI. This is `PREVIEW_CANDIDATES=27`, not `SELECTED_APPS_PARITY_PASS`. The historical 26300.9711 S06 seed also had 27, but this source build is .9807 and URL-containing original record matching is **not tested**.

## R24 v1 selector/source review decisions

- Read existing R23 JSON only, no raw URL queues, assert exact SHA, source/UUID, 98 Windows/2798 Apps and 2,896 total; record fields exactly `queue,out,checksum`. Reject malformed/empty/unsafe duplicate Apps outputs or checksum strings. Source G4 policy and historic filter+resolver SHA guard before any preview.
- Use actual local allow/always-keep patterns against **out field only**, apply known regex language and arch exclusion, keep separate `reconstruction_metadata` vs `appx_candidate` roles. Never infer true package identity/publisher/version/dependency from filename aliases.
- Each of five staging required identity anchors must be identifiable exactly once in proposed Apps candidates via canonical `Microsoft.*` archive names, otherwise fail-closed `MISSING_OR_AMBIGUOUS_IDENTITY`. Multiple language/scale resource records are not themselves duplicate canonical identities. Five staging vs four final remains unchanged.
- `url_record_filter_parity=UNPROVEN_URL_FIELDS_INTENTIONALLY_EXCLUDED`, `manifest_dependency_closure=NOT_EVALUATED`, `payload_sha_verified=false`, `runtime_execution_allowed=false`.
- Future script `R002R24_9807_URLFree_SeedPreview_v1_DRAFT.ps1` must be versioned, source-reviewed, PS7 AST checked; `Preview` output only in a new owned `05_Evidence/R002R24_URLFreeSeedPreview_001` directory, CreateNew + collision fail; never perform URL/network/payload, converter, DISM, WIM, registry, source mutation. The reviewed script and exact execution contract are the **ONE NEXT C**, no native preview invocation in this B process.

**Proof boundary:** B is source/hash and preview-discovery only; full URL-based S06 filter parity and AppX manifest closure/payload status unknown. Master and Registry unchanged, no new approval beyond local source development.
