# BlueLite UUP-history corpus — RH01–RH08 evidence checkpoint (2026-10-21)

**Status:** actual operator-authorized local file classification/deduplication **PASS** on `DESKTOP-4J4KCEA`, confirmed by original local `RH06_Final_Summary.txt`, **independent** `RH07_Independent_Verification.txt`, and source-derived `RH08_Summary.txt`. **No WIM, DISM, CBS, image mount or OneDrive R14 run** in this corpus work. Historical scripts not executed. Master unchanged.

## Authorization and filesystem scope

Operator created/copied a historical UUP corpus under `C:\work\UUP-history\` and authorized subfolder classification, SHA256 inventory, safe 7-Zip 26.04 archive extraction, same-root file moves, deletion of verified byte-identical duplicate files and empty/unneeded same-root directories. No source-file content rewrite and no external folder deletion authorized. User says Total Commander and Explorer remain closed until explicitly announced otherwise, superseding routine mount-closure GUI warnings. Existing R14 runtime is a separate workstream, not executed in this pass. Handoff v1.5.154 and Session Entry record the consent BEFORE any local operations.

## Exact locally observed figures

| Phase | Observation |
|---|---|
| RH01 first read-only probe | **1,947 files** in **147 directories**, **22,052,701** logical bytes |
| RH02 SHA pre-move manifest | **171** identical-source hash groups; **1,526** redundant initial source copies (before expansion); **9,773,634** duplicate source bytes |
| RH03 archive inspection | **19** archives = **17 ZIP + 2 7z**; 7-Zip **26.04 x64** verified; archive member path/integrity check PASS |
| RH04 controlled expansion | **18 unique archives** expanded; **one identical duplicate archive** not re-expanded; **469** member files / **14,397,564** bytes; 19 archive provenance refs retained |
| RH05 frozen pre-apply plan | **2,416** loose+expanded entries, **549** distinct SHA256, **1,867** redundant copies, **16,035,551** logical bytes to remove |
| RH06 actual apply | **549** canonical moves and SHA verification, **1,867** duplicates removed after byte-level match to existing canonical file; **222** empty directories removed; terminal `PASS_RH06_FULL_CLASSIFY_AND_BYTE_VERIFIED_DEDUP` |
| RH07 independent readback | All **549 survivor hashes PASS**; all **2,416** provenance rows resolve to survivor, **19** original archive pointers valid; action journal entries 549/1867/222 match; no remaining extraction scratch; terminal `PASS_RH07_POST_APPLY_INDEPENDENT_SHA_AND_PROVENANCE` |
| RH08 secondary content index | **504** text files scanned; **141** files contain build-version text mentions, **133** contain MAX_PRE text mentions; terminal `PASS_RH08_DISCOVERY_INDEX_NO_MUTATION` |

**Final original content:** **549 physical canonical files**, **20,414,714 logical bytes**, 549 distinct SHA256 (not counting reports and index files newly generated in `99_Index`). Seven folders: `01_Timelines` 37; `02_Scripts` 188; `03_Logs` 85; `04_Analyses` 118; `05_Manifests` 73; `06_Archives` 26; `07_Resources` 22; plus `99_Index` and generated `00_README.md`.

**Limit of automatic attribution:** source-path-based classification leaves **459** canonical files as `Unresolved` for exact build and **13** `CrossBuild`. This is deliberately conservative; content marker index is discovery-only and no recipe/runtime certification, because a build mention is not an exact target identity.

## Durable exact local evidence and path/sha anchors

- `C:\work\UUP-history\00_README.md` — operator-facing directory usage/lookup instructions.
- `99_Index\RH02_Original_PreMove.csv` SHA256 `54F46A377E61B8891E25A34B9B0D41416021E1645B2A63497FEB3C9215F2F8DF`.
- `99_Index\RH03_ArchiveAudit.csv` SHA256 `D579110E0F995B6FC71916B5334AEDDCED66C0953E478CFEE75AB5AA3C7DB0A6`.
- `99_Index\RH04_ExtractedFiles.csv` SHA256 `5571EC1ACEF3B970EFEF8799F8B09A19CDD7866F9AC4FF1D8C975C663A41FA07`.
- `99_Index\RH05_ApprovedScope_PreApplyPlan.csv` SHA256 `EE234E07BDF097156EC62ED524ACFC6E803F401E9BB53D630AFAE501D6C5CFFC`.
- `99_Index\RH06_Final_ProvenanceMapping.csv` SHA256 `AE45B2A4FF35A063B72DDAA9A77B7F0994B8AEDEE5A5C9C560F9C6AE3A187D2D` (**key lookup: original `source_rel` → new `final_rel`**, all 2,416 entries).
- `99_Index\RH06_Exact_ActionJournal.txt` SHA256 `A8C7943B77F70725024CB7112E81096FBA6671600699262A49CD72A8C7A9556E` (individual move, confirmed byte comparison, delete and empty-directory events).
- `99_Index\RH07_Manifest_SHA256.txt` enumerates nine source/audit SHA-pinned CSV/TXT indices.
- `99_Index\RH07_Independent_Verification.txt`, `RH07_Category_Build_Stage_Matrix.csv` and `RH08_ContentMarkers_ForUniversalDrafts.csv` are supporting discovery/verification outputs. RH08 markers CSV SHA256 `B20F3A1068D1DE4A63A65BEB71ADF9E689FE4A66C995874C9FCD6739523C0753`.
- Local analysis/organization scripts: `C:\work\scripts\BlueLite.UUPHistory.Probe.RH01.ps1`, `Inventory.RH02.ps1`, `ArchiveAudit.RH03.ps1`, `Extract.RH04.ps1`, `Plan.RH05.ps1`, `Apply.RH06.ps1`, `Verify.RH07.ps1`, `ContentIndex.RH08.ps1` (each prefixed `BlueLite.UUPHistory.`). They are one-off audit tools, not pre-approved production UUP removal recipes.

**Post-condition / next:** consult operator as requested. Only after that consultation resume separately scoped R14 or use this corpus to design a new reviewed, source-bound universal PRE_MAX draft. No present corpus entry is promoted to executable production authority by file type, PASS string, `CrossBuild` classification or content markers.
