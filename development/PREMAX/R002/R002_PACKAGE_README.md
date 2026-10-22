# R002 universal Stage1 UUP → MAX_PRE first development package (2026-10-22)

**Status:** DEVELOPMENT DRAFT / STATIC + R001 9711 READONLY PROOF / NOT RUNTIME AUTHORIZED.
**Owner:** `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package`.
**Goal:** one reuse-oriented universal control plane spanning original UUP ZIP, JIT queue identity, D5/G4 Apps staging, preserved Windows source, converter reconstruction, and *later separately authorized* offline MAX_PRE decision/servicing.

## Actual draft code
- `03_Drafts\R002_OriginalZip_OverlayPreflight_DRAFT.ps1`: read-only immutable ZIP SHA, 11-entry layout/required upstream names, traversal/duplicate checks; does not unpack or overwrite original.
- `03_Drafts\R002_Stage1_SourceTransport_Control_DRAFT.ps1`: data-driven SHA-pinned original ZIP+launcher+UUID, actual original/renewed D4 canonical queue equality, strict five-AppX policy and 11-phase Stage1-only plan. Does not fetch fresh signed URLs; reuses actually verified R001. Runtime authorization always false.
- `03_Drafts\R002_MAXPRE_OfflineDecisionPlan_DRAFT.ps1`: read-only pure recipe dispatcher contract. Rejects source/working WIM collision, out-of-scope paths, missing immutable SHA, claims of verified image and any runtime-true recipe; emits 7 held/handoff decisions. Positive fixture uses non-existent synthetic WIM paths; NEVER certifies actual CBS/AppX topology.
- `01_Inputs\R002_Stage1_Profile_9711.json`: source-specific data pins (not build hardcoding inside engine); `R002_RecipeRegistry_Snapshot.json` is a **summary of Registry r38**, NOT copied executable module.
- `04_StaticTests\R002_Synthetic_ImageContract.json`, `R002_StaticAndNegative_Test.ps1`, `Fixtures_001\`: real native PS7 test + 10 deliberate negative-only synthetic variations (kept as evidence).

## Why this is reusable
Frozen operator UUP ZIP identity is separate from transport; original/renewed Windows+Apps semantic SHA must match complete multiset. No selective deletion of Windows reconstruction queue. D4 source module must match its pinned SHA; D5/G4 remains the reviewed historical producer for only necessary Apps. Build/version/UUID/launcher SHA are configurable source data. Later real MAX_PRE worker must accept distinct immutable original and owned mutable WIM, use current-image registry/service/CBS/AppX/WinRE predicates, and produce native evidence before any commit.

## DO NOT RUN / MISSING RUNTIME IMPLEMENTATION
This package is **not** a finished custom ISO engine. It contains no source payload downloader, D5/G4 runtime integration, converter hook, DISM mount/unmount, CBS mutation, working WIM export, or ISO generation. These deliberate missing runtime components MUST be implemented/reused, reviewed and authorized later; never infer their success from this draft's static PASS. `06_Candidate` stays empty and Registry runtime flags remain false.

## Source authority
Master v6.3 §§0D/0E/7/22; Handoff §0Y / §4.0 / §5 / §8.121; verified Oct03 transfer `production/intelligence/BlueLite_UUP_Oct03_26200_Transfer_Review_20261019.md`; original Library and UUP-history per `02_Analysis` record; R001 2026-10-22 source-bound D4 actual evidence.

**ONE NEXT:** operator reviews this proof and authorizes precise next development block. Normal GUI STOP applies.
