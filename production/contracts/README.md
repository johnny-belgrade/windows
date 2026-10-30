# BlueLite machine-readable contracts — initial governance foundation

**Status:** CONTRACT_DESIGN_ONLY, 2026-10-17. These files are versioned, syntactically valid JSON Schema 2020-12 designs and a historical recipe index, **not a running converter, mutation engine, image certification or operator authorization**.

Canonical authority: [Master](../../BlueLite-Master_Germanium_Strategy_final.md) > current-image operator proof > [Current Status](../../BlueLite_Current_Status.md). [Handoff](../../BlueLite_Germanium_Handoff.md) explains how to use these contracts.

## Files and ownership

| File | Intended integration |
|---|---|
| `BlueLite_RunManifest.schema.json` | One source-bound run manifest; frozen ZIP/contract, original vs renewed queues, tools, owned WIM paths and explicit authorization gates. |
| `BlueLite_Recipe.schema.json` | One logical target + verified topology variants, dependency/protected floor, engine module SHA, post-state and rollback. |
| `BlueLite_ResultReceipt.schema.json` | Operator-run receipt with exact result/tier, source+script SHA, raw log, native exit, post-state, limited PASS boundaries. |
| [Recipe registry](../intelligence/BlueLite_RecipeRegistry.json) | Historical candidate index. Initial entries are explicitly `HISTORICAL_REFERENCE` and `runtime_execution_allowed=false`. |

## Hard invariants

1. A schema PASS proves only the **shape of an authored record**, never exact current-image topology, network queue identity, module integrity, native execution, health or release.
2. Source `original_zip_sha256` / `source_contract_sha256` and package content `out + algorithm + digest` remain immutable. Refreshed signed URL text may differ.
3. `image.original_wim_path` is immutable; `image.working_wim_path` is an independently owned disposable derivative. No same-path aliases, no auto-overwrite.
4. `operator_authorized_transfer`, `operator_authorized_mutation`, `converter_runtime_authorized` are **explicit**; documentation alone is always `false`.
5. GREEN/AMBER and terminal disposition are separate dimensions. A historical `PRODUCTION_RULE` disposition does **not** make the untested 26300 target executable.
6. Runtime must independently validate all gate logic in code. These schemas define required data representations; no JSON field by itself executes or permits an operation.
7. The real operator log is retained under `C:\work\logs`; evidence references are not embedded binaries. Delete temporary owned WIM only after verified log/archive retention and release of mounts/hives.
8. A downstream engine may return `ALREADY_ABSENT` only on exact current-image expected post-state; it cannot infer success from filenames or previous build alone.
9. Record failed negative fixtures, known dependency holds and separately approved exception paths. No auto-promote from `STATIC_VERIFIED` to `RELEASE_CERTIFIED`.
10. Master release gates remain normative (Defender ON/OFF, Store policy, servicing/pending, Update Pause/Resume, VMware/VirtualBox **host** testing, footprint and SHA).

## Obavezni offline common-base indexing acceptance contract — operator 2026-10-25

Normativan cilj iz [Master §16.1](../../BlueLite-Master_Germanium_Strategy_final.md): **Windows Search file/content indexing u osnovnom offline target OS-u je OFF**, `WSearch` Disabled, sa podržanim sistemskim/policy i post-setup ograničenjima koja ne dopuštaju trivijalno uključivanje standardnom korisniku. Oporavak je samo namerna administrativna višekoračna promena. **Ne uklanjati Start/Search UI/CBS/servicing zavisnosti** radi prividnog smanjenja. Svaka implementacija mora imati target-build proof efektivnog policy ključa i WSearch start-state, posle prvog boot-a/restarta i servicing-a, negativni test user-toggle, i nezavisne native/post-state dokaze pre oznake PASS. Slučaj unsupported policy ili nerazrešenog dependency ide na HOLD; nema izmišljenog ključa, automatske promocije ili aktiviranja runtime recipe-a.

Ovaj README i postojeći JSON Schema/RecipeRegistry **ne omogućavaju izvršenje**; svi originalni `runtime_execution_allowed=false` ostaju kakvi jesu, a istorijski dokaz nije sertifikacija za 26300.9807. Za konkretnu offline WIM promenu i dalje se zahteva posebno eksplicitno odobrenje i rollback/health. Ova izmena je *isključivo dokumentacioni zahtev*, ne potvrda da je offline slika modifikovana.

## Next engineering work, not completed by this commit

Bind the existing D4/D6/Stage1 scripts and later common engine to the same manifest and receipt contracts; replace provisional intelligence records with exact `engine_module` SHA and actual independent negative/runtime evidence **only after operator authorization and tests**. Do not duplicate the D4 URL renewer or restart 26200 R7 experiments.

Keep this directory compact: a change to one schema or registry revision requires review, static/negative schema fixtures and a new Git commit, not recreation of unrelated historical tests.

## 2026-10-30 — Master §0H 26300-only MVP and recovery/size contract

- **NEW build target:** only the run-specific operator-selected official GA 26300.x source. Never make 26300.9711, 26300.9807 or 26300.9818 a default. Historical 26200 references remain revision-only fixtures, not new build/run requirements. Original ZIP/UUID/launcher/converter/version/config/list hashes remain source-bound.
- **MVP1/P0 is first:** produce runnable verified UUP source/renewal/native converter/CustomAppsList package and a standard WinPE/Setup bootable ISO plus install.wim, with actual native stdout, source/WIM/ISO hashes and original queue closure. Vendor converter may be reviewed at v128m for the operator's original 26300.9818 ZIP, but the ZIP and version must be inspected before assuming its semantics. No promise that any build/converter has run because this documentation changed.
- **MVP2/P1 next:** large *measured* current-topology safe payload reduction on an approved owned offline derivative. Nonblocking fine-grained CBS/AppX residue and unresolved G3O/ZIP64 deep analysis pass to Stage2/Stage3 or scoped diagnostics. Existing P03 HOLD remains; do not pretend full real31 manifest closure is certified. Mandatory final release gates stay binding.
- **WinPE retained; WinRE candidate:** Standard Setup boot.wim remains. Installed winre.wim may be omitted only by source-verified supported SkipWinRE=1 or independently reviewed offline mechanism, with post-state proof and documented external recovery route. Record the unavailable built-in recovery functions; do not remove recovery/Setup dependency blindly.
- **Measured acceptance:** final ISO target **around 5 GB**, NOT 3.5–5 GB, installed clean footprint still approximately 11–15 GB. Never remove WinSxS wholesale or disable functional Windows Update to meet packaging size. Track source/reconstruction/Setup/first login/each repeat boot separately on comparable hardware; no speed PASS without measurement.
- **Outcome separation:** MVP_CONVERSION_VERIFIED is a candidate-level result and does not imply PRE_ISO_MUTATION_CERTIFIED or RELEASE_CERTIFIED. Existing JSON schemas remain design-only unless separately updated and fixture-tested for these fields; a documentation statement does not alter runtime flags or authorizations.
