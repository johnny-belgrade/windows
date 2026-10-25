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
