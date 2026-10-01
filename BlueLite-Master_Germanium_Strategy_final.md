# BlueLite v1.0 — MASTER GERMANIUM STRATEGY v2.2

**Status:** AUTHORITATIVE / SUPERSEDES PREVIOUS MASTER STRATEGY  
**Date:** 2026-10-01  
**Scope:** Windows 11 Germanium family, current development lineage 26100.x / 26200.x  
**Project:** BlueLite v1.0  
**Team:** Johnny + ChatGPT  
**Canonical source catalog:** `johnny-belgrade/windows/BlueLite_Sources.md`

---

## 0. DOCUMENT AUTHORITY, EVIDENCE CORPUS AND PURPOSE

This document is the new governing strategy for BlueLite. It is not a summary of one build and it is not a list of isolated tweaks. It consolidates the complete project logic developed through the four chronological BlueLite chat histories and replaces the earlier Master Strategy wherever this document is more specific.

The strategy was reconstructed from the following complete chat exports:

| Chat | Period covered | Parsed Prompt/Response records | SHA-256 of reviewed export |
|---|---|---:|---|
| `ChatGPT-1-25H2 26200.9278-20260929-1529.md` | 2026-08-28 → 2026-09-10 | 2,111 | `9E5FDD7FBAAE409ACDC8B350BF40FAA22FE4A9C11C58D438D16B6DCFC1D48AE0` |
| `ChatGPT-2-25H2 26200.xxxx-20260929-1528.md` | 2026-09-10 → 2026-09-12 | 1,524 | `415D4DB693AEC6D3C55A06F3263E7AD8A8746146E53485013219042BEFF5BB57` |
| `ChatGPT-3-25H2 26200.xxxx-20260929-1527.md` | 2026-09-12 → 2026-09-15 | 507 | `4DFED785D6E8D4D4C151C25BD5B76A791A825DD86894E39B03FEFDB756F2305F` |
| `ChatGPT-4-25H2 26200.xxxx-20260929-1524.md` | 2026-09-15 → 2026-09-29 | 715 | `5A688FA201140A922EE18211B5BF9E822407F2F7B2FCDF9411BBA59F56D7068A` |

Total reviewed Prompt/Response records: **4,857**.

The first two histories establish the project objective, dependency-first methodology, UUP work, initial offline debloat and deep AppX/CBS/WinSxS forensics. The third history converts that research into a canonical production/release architecture. The fourth history is the most important operational refinement: it stress-tests the strategy, rejects unsafe methods, certifies reusable AMBER patterns, formalizes disposable testing and pre-production gates, preserves the VM-host dependency floor, and moves maximal pre-debloat into a reconstruction-safe UUP → pre-ISO pipeline.

The purpose of this document is therefore:

1. to define the invariant architecture of BlueLite;
2. to preserve the logic behind decisions, including failed approaches that must not be repeated;
3. to define how a new Germanium build is transformed without rebuilding the project from chat history;
4. to distinguish build-independent engine code from build-specific component intelligence;
5. to define the exact point at which NTLite and later VirtualBox are allowed;
6. to turn each successful research result into a portable production rule;
7. to make each future Germanium build require less manual analysis than the previous one.

When this document conflicts with an old development script name, phase number, local path or provisional chat conclusion, this document is the strategy authority. Actual current-image evidence remains the final technical authority for mutation.

---

# 1. PROJECT DEFINITION AND NON-NEGOTIABLE TARGET

BlueLite is not a one-build preset.

BlueLite is an **automated, build-independent Windows 11 Germanium transformation system** that accepts an appropriate Windows 11 Germanium source, reconstructs it correctly, applies the maximum proven offline debloat and integration set, hands only true residue to a secondary component engine, validates the result online, and produces repeatable Defender ON and Defender OFF release artifacts.

The target envelope is:

- final ISO approximately **3.5–5 GB**;
- installed footprint approximately **11–15 GB** before machine-specific drivers and user programs;
- maximum offline debloat consistent with the proven dependency and servicing graph;
- maximum practical WinSxS reduction consistent with clean servicing state;
- Microsoft Store ecosystem not actively provisioned in the common base;
- Windows Update paused to **2100-12-31T23:59:59Z**, while preserving working Resume and later normal Pause behavior;
- Defender ON and Defender OFF final variants;
- retained core user apps kept functional;
- networking and the required VMware Workstation / VirtualBox host dependency floor preserved;
- optional user content moved outside the permanent active OS whenever possible;
- repeatable build process with logs, hashes, checkpoints and post-state certification.

If a specific Germanium build cannot reach the target envelope because of newly mandatory dependencies, BlueLite must not respond by silently weakening verification. It must quantify:

- what payload remains;
- which component/dependency owns it;
- why it cannot be removed by the current engine;
- whether it is a temporary RED hold or a secondary component-engine handoff;
- what measurable footprint impact remains.

The governing question is never “whether we debloat aggressively.” The governing question is **which dependency-aware sequence reaches the target while keeping the image internally consistent and reproducible**.

---

# 2. THE CENTRAL LESSON OF THE FOUR HISTORIES

BlueLite evolved through several methodological corrections. These corrections are now permanent strategy rules.

## 2.1 From removal list to dependency graph

The project began with a cross-build list of components commonly removed by successful custom Windows builds. That list remains useful as a candidate map, but it is not authority.

A target is removable only after its real current-image identity, ownership and dependency boundary are understood.

Therefore:

`candidate name → exact identity → owner/dependency graph → physical/runtime projection → validated removal method → verified post-state`

is the required direction of reasoning.

## 2.2 From build-specific commands to ENGINE + COMPONENT INTELLIGENCE

The early 26200.9278 work proved that hardcoding a build revision creates repeated manual work and brittle scripts. Later 26200.9445 work proved that the same logical target can usually be resolved dynamically if topology is unchanged.

BlueLite therefore separates:

- reusable **ENGINE** logic;
- machine-readable **COMPONENT INTELLIGENCE**;
- per-build **discovery/delta evidence**.

A new build should change intelligence records only where Microsoft actually changed identities or dependency topology.

## 2.3 From “physical removal succeeded” to “servicing-consistent removal succeeded”

The Sense experiments are the decisive proof.

A raw Sense carve physically removed the expected runtime payload and hundreds of hardlink names, while pending servicing remained zero. Nevertheless, `/ScanHealth` exposed `CorruptPayloadFile`, and the component store became Repairable because CBS still considered Sense installed.

Therefore:

> **Physical absence is never sufficient proof of successful removal.**

A production rule must leave the servicing graph, metadata state, physical payload and runtime projections mutually consistent.

## 2.4 From direct experimentation on canonical to disposable proof first

The later histories established the durable AMBER pattern:

1. inspect canonical read-only;
2. create an exact disposable WIM copy;
3. verify copy identity by size/hash;
4. mount disposable;
5. perform one controlled mutation;
6. independently certify disposable post-state;
7. reject and delete disposable if any gate fails;
8. only then revalidate current canonical topology;
9. apply the already proven method to canonical;
10. independently certify canonical;
11. commit only after certification.

This is the standard for new AMBER rules.

## 2.5 From destructive UUP queue pruning to reconstruction-safe staging

Earlier UUP experiments demonstrated that deleting Windows/FoD/reference inputs before reconstruction can break delta/reference closure, producing `blob not found`, WIM errors or incomplete reconstruction.

Therefore the architecture changed:

- aggressively minimize **AppX selection** where the converter officially supports it;
- do **not** destructively prune the Windows/reference/delta/FoD closure merely because the final OS will not retain those components;
- allow reconstruction to finish correctly;
- then run the BlueLite offline pre-ISO engine against the reconstructed WIM.

This distinction is fundamental:

> **download/reconstruction dependency ≠ final-OS dependency**

## 2.6 From “NTLite next” to “NTLite only after the Intelligence queue is exhausted”

A premature transition to NTLite was explicitly rejected during the later work.

Completing the currently known AMBER list does not authorize opening NTLite. Before handoff, every realistic remaining offline candidate must end in one of four terminal dispositions:

- `PRODUCTION_RULE`
- `KEEP_SKIP`
- `COMPONENT_ENGINE_HANDOFF`
- `RED_HOLD`

Only `COMPONENT_ENGINE_HANDOFF` items belong in the normal secondary component-engine queue.

## 2.7 From global inventory assumptions to target-specific evidence

The OneDrive pre-production gate showed that `/Get-Packages /Format:Table` may not enumerate every family in a way suitable for a strict target gate even when individual package identities resolve correctly.

Therefore:

- broad inventory is useful for discovery;
- **target-specific `Get-PackageInfo` / capability / feature / registry / CBS checks are authoritative for the target contract**;
- a global table must not be treated as the sole truth for exact package existence.

## 2.8 From large forensic script history to small canonical production set

Hundreds of numbered development phases were valuable for research, but they are not the desired release interface.

The end product is a small ordered production set plus a component intelligence database. Forensic scripts remain evidence and research tools, not normal build steps.

---

# 3. ARCHITECTURE: FIVE PERMANENT LAYERS

BlueLite has five logically separate layers.

## 3.1 SOURCE INTAKE

Responsible for:

- exact source selection;
- original UUP descriptor/archive validation;
- source metadata capture;
- architecture/language/edition selection;
- original launcher/config preservation;
- reconstruction inputs.

The source layer must not contain component-removal knowledge beyond safe source-selection/AppX policy.

## 3.2 ENGINE

Build-independent implementation for:

- source staging;
- mount/unmount/commit;
- WIM copy/export;
- DISM package/capability/feature operations;
- AppX handling;
- offline SOFTWARE/SYSTEM/COMPONENTS hive operations;
- CBS/component/WinSxS discovery;
- hardlink/projection analysis;
- transactional backup/rollback;
- logging;
- hash generation;
- health and pending checks;
- disposable image lifecycle;
- certification;
- cleanup;
- ISO assembly.

The engine must avoid exact build revisions unless a source format technically requires them.

## 3.3 COMPONENT INTELLIGENCE

A machine-readable knowledge base for each logical target.

At minimum each target record must support:

- logical target name;
- aliases;
- target family/selectors;
- package identities;
- capability identities;
- feature identities;
- AppX/PFN identities;
- service/driver identities;
- package → deployment → component mapping;
- owners and upstream parents;
- runtime/System32/SystemApps/WindowsApps projections;
- WinSxS families;
- hardlink relationships;
- retained dependency floor;
- validated removal class;
- validated removal method;
- expected post-state;
- protected sibling/parent state;
- tested builds;
- serviceability result;
- rollback method;
- NTLite/MSMG/community naming/mapping when useful;
- source/evidence references;
- measured build-specific footprint evidence;
- final disposition.

## 3.4 EVIDENCE / CERTIFICATION

Stores:

- baseline manifests;
- delta manifests;
- pre-production gate reports;
- disposable test reports;
- independent post-mutation certifications;
- `CheckHealth`/`ScanHealth` evidence;
- pending-state evidence;
- hashes;
- source identities;
- release manifests;
- NTLite handoff manifests;
- VM validation reports.

No rule becomes production because “it worked once.” It becomes production because its evidence package defines a reproducible contract.

## 3.5 ORCHESTRATION / RELEASE

Defines the canonical order and decides, based on the current build manifest, whether a target is:

- unchanged;
- version-changed with unchanged topology;
- topology-changed;
- new;
- already absent.

The orchestrator must never expand scope simply because a wildcard produces more matches.

---

# 4. SOURCE AND EVIDENCE POLICY

The central source catalog is:

`https://github.com/johnny-belgrade/windows/blob/main/BlueLite_Sources.md`

Use of that catalog is mandatory throughout the project, not just when a problem appears.

Evidence priority:

1. **actual state of the current target image**;
2. Microsoft servicing documentation and observed native servicing behavior;
3. BlueLite previously certified cross-build results;
4. NTLite/MSMG/W10UI/wimlib/CBS reverse-engineering and component databases;
5. reputable community scripts, registry research and technical forums;
6. FBConan and other proven custom builds as forensic end-state oracles.

No external source authorizes mutation by itself.

A custom build can prove that a small footprint or a particular end-state is achievable. It does not prove that copying its carve is servicing-safe.

For every meaningful target, the intelligence record should retain the evidence trail, including relevant `BlueLite_Sources.md` entries.

---

# 5. CANONICAL LOCAL ENVIRONMENT — UPDATED 2026-09-29

The old root:

`C:\Users\Admin\Downloads\work`

is retired.

The canonical offline workspace is now:

```text
C:\work
```

Required subpaths retain the old layout:

```text
C:\work\
├── extracted\
│   └── install.wim
├── mount\
├── scripts\
├── logs\
└── backup\
```

Canonical WIM:

```text
C:\work\extracted\install.wim
```

Canonical mount:

```text
C:\work\mount
```

Development/production scripts:

```text
C:\work\scripts
```

Logs:

```text
C:\work\logs
```

Backups/checkpoints:

```text
C:\work\backup
```

All future scripts must use the new root or derive paths from one root variable. No new canonical script should embed the retired Downloads path.

Reference/forensic mounts such as FBConan remain physically and logically separate and must never be confused with `C:\work\mount`.

## 5.1 Main workstation

The main development workstation is now:

- ASUS motherboard;
- Intel Core **i7-11700F**;
- NVIDIA **GTX 1050**;
- **16 GB DDR4 3200 MHz** RAM.

This is the primary machine for normal BlueLite development, DISM work, disposable WIM tests, hashing, comparison, compression and production runs.

## 5.2 Test / backup machine

The previous host becomes the test/backup machine:

- AMD Ryzen 5 **4500U**;
- **8 GB RAM**.

On this machine:

- run heavy DISM operations serially;
- avoid unnecessary parallel scans;
- avoid whole-binary regex operations when bounded/string-offset analysis is enough;
- limit compression threads when required;
- avoid running multiple large inventory/compression jobs concurrently.

The engine should remain usable on both machines. Performance tuning must not change correctness.

---

# 6. CHATGPT ↔ OPERATOR EXECUTION PROTOCOL

The project team is the operator and ChatGPT.

Operational rules:

1. **One executable step at a time.**
2. A command or script is part of that one step.
3. Do not present several future execution steps unless necessary to explain the current decision.
4. Give complete copy/paste commands. The operator should not need to edit fragments.
5. Development file numbering/naming is chosen by the operator unless a canonical release filename has already been locked.
6. When asking for output, specify exactly:
   - “send only command output”, or
   - the exact log filename, or
   - both.
7. Never ask vaguely for “the result”.
8. Do not repeat a question whose answer already exists in current history, files, evidence or project context.
9. Before mutation, explicitly identify:
   - target;
   - dependency/owner boundary;
   - expected post-state;
   - rollback/checkpoint.
10. The live host OS is never the target of offline BlueLite mutation.
11. Until the controlled VM phase begins, all Windows-image work targets offline images only.
12. Before mount/unmount/commit/discard, close Total Commander and Explorer windows that point into the relevant mount, WIM or disposable root.
13. At end of a work session:
   - release offline hives;
   - verify mount table;
   - clean stale disposable mountpoints only when identified;
   - leave no accidental test hive loaded.
14. Read-only investigative mount sessions are normally discarded, not committed.
15. A canonical mutation is committed only after its post-state is certified.

## 6.1 REMOTE EXECUTION CONTRACT

Remote Desktop Commander (RDC), when installed, authorized and online on the main workstation, is the standard BlueLite remote execution transport between ChatGPT and the operator-controlled host. Its purpose is to remove unnecessary manual copy/paste relay while preserving the same target, dependency and certification rules defined elsewhere in this strategy.

The presence of RDC changes **how commands are transported and executed**. It does not change **what BlueLite is allowed to target**.

Mandatory contract:

1. The live main-desk Windows installation is the **HOST**, not the BlueLite image target.
2. Normal BlueLite image mutation is permitted only against an explicitly verified offline image under the canonical `C:\work` workspace, normally:

   ```text
   SOURCE WIM : C:\work\extracted\install.wim
   INDEX      : 1
   MOUNT      : C:\work\mount
   ```

3. `/Online`, live-registry, live-service, live-package, live-driver or equivalent host mutation is prohibited during normal BlueLite image work unless the operator explicitly assigns a separate live-host administration task. Such a task is outside the offline-image mutation contract and must be identified as such before execution.
4. Before the first mutation of a work session, ChatGPT must remotely verify at least:
   - connected device identity;
   - canonical `C:\work` paths;
   - current DISM mount table;
   - intended WIM/index/mount target;
   - absence of an unintended or stale target that could redirect the operation to the host or another image.
5. If target identity is ambiguous, remote mutation fails closed.
6. Read-only discovery, log retrieval, file inspection and command output collection may be performed directly through RDC without requiring the operator to copy/paste each result.
7. Script execution through RDC must still obey the BlueLite one-step protocol: one authorized executable step at a time, followed by inspection/certification before the next mutation step. Remote execution is not permission to batch speculative future mutations.
8. Canonical scripts and logs remain under `C:\work\scripts` and `C:\work\logs`; remote execution does not create a second hidden workflow or alternate source of truth.
9. Existing RDC/host security boundaries, blocked-command policy, permissions and authorization controls must be respected. BlueLite must not weaken or bypass them merely to make automation easier.
10. The main workstation may automatically start the RDC remote bridge at user logon using the operator-approved scheduled task. Persistent remote authorization is an execution convenience, not standing authorization for unsupervised BlueLite mutation.
11. If RDC is offline or unavailable, the project falls back to the established operator-relay model: ChatGPT supplies the complete command/script and the operator executes it locally and returns the requested output/log.
12. A successor ChatGPT session should use the connected RDC transport when available, but the **Master Strategy remains the authority** for target boundaries, paths and execution rules. Tool availability alone must never be treated as proof that a mutation is authorized.

Current main-workstation remote execution implementation, as of 2026-10-01:

```text
Remote transport : Remote Desktop Commander
Device            : DESKTOP-4J4KCEA
Autostart task    : BlueLite - Remote Desktop Commander
Node.js           : 24.19.0
PowerShell        : 7.6.6
ExecutionPolicy   : RemoteSigned
```

These implementation details are current-environment evidence, not eternal architectural requirements. If the device name, Node/PowerShell version, transport implementation or task name changes, update the environment record without weakening the contract above.

---

# 7. UUP SOURCE POLICY AND RECONSTRUCTION-SAFE ONE-CLICK ARCHITECTURE

## 7.1 Source authority

The canonical release source is the **exact UUP Dump source/archive selected by the operator**.

BlueLite must capture and log:

- UUP UUID/set identity where available;
- build;
- architecture;
- language;
- edition;
- selected conversion profile;
- hashes of source descriptor/config files.

BlueLite must not silently change the release source.

An optional AUTO discovery mode may exist as a convenience, but it is not canonical until the discovered source is frozen, logged and explicitly accepted for that run. Reproducibility always requires a fixed resolved source identity.

## 7.2 Do not rewrite the original UUP launcher

The original `uup_download_windows.cmd` is source evidence and should remain intact.

BlueLite works as a wrapper/overlay:

- preserve original launcher/config/list files;
- install BlueLite config/policy files;
- run fail-closed preflight;
- invoke the original downloader/converter;
- run post-run audit.

## 7.3 Reconstruction closure is sacred

Do not destructively filter the Windows/reference/delta/FoD input queue just because a component is unwanted in the final OS.

Specifically, the project history demonstrated that network FoD, language/FoD metadata, Sense and other reference inputs can be required by the converter even when their final runtime presence is undesirable.

The UUP layer must first satisfy the converter's reconstruction dependency closure.

## 7.4 Safe pre-download minimization

The primary aggressive pre-download policy applies to the supported AppX selection layer.

Current common-base top-level retained inbox Apps:

- `Microsoft.SecHealthUI`
- `Microsoft.WindowsCalculator`
- `Microsoft.WindowsNotepad`
- `Microsoft.Windows.Photos`

Framework/runtime dependencies are resolved from actual manifests. They are not preserved by a static “keep every framework” rule and are not removed by a static “framework is bloat” rule.

Store, StorePurchaseApp and DesktopAppInstaller are not common-base requirements. If a later user wants Store or another optional application, it belongs in the optional user payload unless a newly proven dependency changes that rule.

## 7.5 Pre-debloat has two different meanings

BlueLite must distinguish:

### A. Pre-download/source minimization
Only operations proven safe for reconstruction, primarily supported AppX selection and converter-supported options.

### B. Post-reconstruction / pre-ISO offline debloat
After a correct `install.wim` exists, BlueLite may invoke already-certified native and portable AMBER production modules before the final ISO is assembled.

This second stage is where the project can achieve large “pre-debloat” gains without corrupting the UUP dependency closure.

## 7.6 One-click package principle

The desired UUP user experience is a wrapper package with a single entry point such as `START.cmd`, but “one click” must not mean “one opaque script.”

Internally the package must still have:

- source resolution;
- source freeze/manifest;
- config/AppX policy installation;
- UUP reconstruction;
- post-reconstruction WIM discovery;
- canonical BlueLite pre-ISO modules;
- health/pending gates;
- VM/network protected-floor gates;
- cleanup/export;
- ISO assembly;
- logs and hashes.

The one-click package and the standalone offline production pipeline must consume the **same production rules**, not separate copies that drift.

## 7.7 Idempotent handoff

If a target was already removed by the UUP pre-ISO engine, the later standalone offline orchestrator must detect the expected post-state and return `ALREADY_ABSENT` / `SKIP`, not fail or attempt a second removal.

---

# 8. BUILD DISCOVERY AND DELTA MODEL

Every newly reconstructed Germanium `install.wim` begins with a minimal, read-only discovery pass **before any post-reconstruction BlueLite mutation is allowed**.

This pre-mutation baseline is a release gate, not merely a reporting artifact. It establishes whether previously certified production contracts still match the current build before the pre-ISO engine is allowed to act.

The baseline manifest must capture at least:

- source identity;
- build/edition/index;
- mount identity;
- packages and states;
- capabilities;
- features;
- provisioned AppX/MSIX;
- relevant services/drivers;
- component-store state;
- pending servicing state;
- relevant SOFTWARE/SYSTEM/COMPONENTS evidence;
- known target component families;
- known hardlink/projection contracts;
- protected VM/network floor.

The new manifest is compared with the last certified Germanium baseline.

Target result:

- `UNCHANGED`
- `VERSION_CHANGED`
- `TOPOLOGY_CHANGED`
- `NEW`
- `ABSENT`

Rules:

### UNCHANGED
Use the existing production rule after the current pre-production gate.

### VERSION_CHANGED
Resolve the new exact identities dynamically. If owner/dependency topology matches the certified contract, reuse the production rule.

### TOPOLOGY_CHANGED
Fail closed. Do not mutate. Send target to Intelligence research.

### NEW
Create a new intelligence candidate.

### ABSENT
Idempotent success/skip.

No broad rule such as “remove every 26100.x package” is allowed.

Version numbers are evidence used to resolve an instance of a logical target; they are not the target definition.

---

# 9. TWO-DIMENSION CLASSIFICATION: REMOVAL CLASS + RELEASE DISPOSITION

Earlier strategy discussions sometimes overloaded RED and NTLite/handoff concepts. The later histories prove that these must be separated.

## 9.1 Removal class

### GREEN
Native/supported and dependency-understood removal:

- `Remove-Package`;
- `Remove-Capability`;
- feature disable/remove payload;
- provisioned AppX removal;
- documented offline registry/service/policy change.

### AMBER
No clean default removal path, but BlueLite can prove and automate a narrow dependency-aware method.

Typical certified AMBER patterns include:

- exact single-owner decouple followed by native servicing removal;
- exact-owner neutral/merged package removal;
- controlled multi-owner decouple where the exact retained owner set is proven;
- servicing-driven satellite removal while touching only neutral production targets.

### RED
BlueLite does not yet understand the dependency/servicing boundary well enough to authorize mutation.

Examples:

- raw WinSxS carve without state transition;
- broad COMPONENTS manipulation;
- StateRepository database surgery;
- shared framework/runtime deletion with unknown consumers;
- target whose mutation leaves CBS metadata and payload contradictory.

## 9.2 Release disposition

Each intelligence candidate must end as exactly one of:

### `PRODUCTION_RULE`
A GREEN or certified AMBER method is ready for canonical automation.

### `KEEP_SKIP`
Target is intentionally retained, already absent, metadata-only with no useful physical gain, or part of the required dependency floor.

### `COMPONENT_ENGINE_HANDOFF`
The target is understood well enough to define the desired outcome and protected dependencies, but our scripted offline engine cannot safely reproduce the required servicing transition. It is eligible for NTLite/secondary component engine.

### `RED_HOLD`
Dependency is not sufficiently understood. It does **not** automatically go to NTLite.

This distinction is mandatory.

---

# 10. PROVING A NEW PRODUCTION RULE

## 10.1 New GREEN rule

For a newly discovered native target:

1. read-only current topology audit;
2. disposable test if the blast radius is not trivial or the target has shared ownership;
3. execute native removal;
4. verify target state;
5. verify retained dependencies;
6. pending = 0;
7. `CheckHealth`;
8. `ScanHealth` for a first certification or meaningful component-store change;
9. record measured physical delta;
10. classify and lock the rule.

A previously certified GREEN target on a new build can skip redundant deep forensics only when delta discovery proves topology unchanged.

## 10.2 New AMBER rule — mandatory lifecycle

1. **Canonical read-only discovery**
   - exact identities;
   - owners;
   - deployments;
   - components;
   - physical payload;
   - projections/hardlinks;
   - protected parents/siblings.

2. **Disposable preparation**
   - canonical WIM must be unmounted or otherwise protected from accidental targeting;
   - copy WIM;
   - verify exact byte size and SHA-256;
   - mount disposable RW;
   - verify `Status=Ok`;
   - verify pre-health.

3. **Controlled mutation**
   - touch only allow-listed metadata/owners;
   - unload hives before DISM servicing;
   - invoke the smallest native servicing operation possible;
   - no broad wildcard mutation.

4. **Independent post-mutation certification**
   - target exact post-state;
   - removed physical payload;
   - protected parent/sibling state;
   - runtime projections;
   - capability/feature/package providers still operational where required;
   - `pending=0`;
   - `CheckHealth=CLEAN`;
   - `ScanHealth=CLEAN`;
   - protected VM/network floor;
   - no unexpected feature drift.

5. **Classification lock**
   - record exact rule;
   - record expected topology;
   - record allowed servicing-driven side effects;
   - record measured delta;
   - hash report/evidence if part of release corpus.

6. **Disposable cleanup**
   - discard;
   - unmount;
   - delete;
   - verify canonical still intact.

7. **Canonical pre-production gate**
   - re-resolve the current canonical target;
   - require topology to match the certified contract exactly.

8. **Canonical production apply**
   - repeat the proven sequence only;
   - backup required hives/metadata;
   - no research logic added during production apply.

9. **Independent canonical certification**
   - same expected post-state;
   - `pending=0`;
   - `CheckHealth`;
   - `ScanHealth` for AMBER/high-impact removals;
   - all protected contracts pass.

10. **Commit**
    - only now may the canonical WIM be committed.

---

# 11. POST-STATE IS THE AUTHORITY

Command exit codes are evidence, not proof.

Examples established in the histories:

- a native operation may return success but remove no payload;
- a target may disappear physically while CBS still considers it Installed;
- a global package table may omit a target that individual package queries resolve;
- a feature may validly transition from `Disabled` to completely absent after a later production phase;
- servicing may correctly remove language satellites as a side effect of neutral package removal.

Therefore every rule defines an **expected post-state contract**.

The contract must specify:

- target package/capability/feature/AppX state;
- expected non-resolving identities where applicable;
- retained dependency state;
- expected physical directories/files;
- expected runtime projections;
- expected provider functionality;
- pending count;
- servicing health.

---

# 12. HEALTH STANDARD

## 12.1 `CheckHealth`

Required:

- before canonical mutation;
- after meaningful canonical mutation;
- in certification boundaries;
- after cleanup/export transitions where applicable.

## 12.2 `ScanHealth`

Mandatory for:

- certification of every new AMBER rule;
- any raw/component-level experiment;
- any method that changes CBS owner relationships;
- any removal whose physical footprint is large or servicing topology is non-trivial;
- canonical AMBER production apply unless a later strategy revision explicitly proves a cheaper equivalent gate.

Sense proved why `CheckHealth` alone is not enough for first-time carve certification.

## 12.3 Pending servicing

`Install Pending` / `Uninstall Pending` count must be zero at all formal certification gates unless a specific, intentionally pending servicing transaction is itself the object of the test.

---

# 13. POWERSHELL / SCRIPT ENGINEERING STANDARD

Production scripts run under PowerShell 7 as Administrator, but must be written defensively against PowerShell-specific failure modes discovered during the project.

Required practices:

- `Set-StrictMode -Version Latest` for new production scripts where compatible;
- `$ErrorActionPreference = 'Stop'`;
- explicit string/array typing where ambiguity matters;
- wrap command output with `@(...)` when scalar-vs-array behavior can change `.Count`;
- never assume a property exists without checking;
- do not create empty pipeline elements;
- parse scripts statically before release;
- use explicit `[regex]::Match()` objects for important captures;
- do not shadow the automatic `$Matches` variable with `$matches`, because PowerShell variable names are case-insensitive;
- use `[AllowEmptyCollection()]` when a function legitimately accepts an initially empty typed list;
- do not trust implicit regex capture state after `-match`/`-notmatch` chains;
- use `try/finally` for offline hive cleanup;
- dispose registry handles where created;
- call GC/finalizer release before `reg unload` when necessary;
- retry hive unload only in a bounded, logged manner;
- fail closed if a source hash or structural anchor does not match;
- preserve newline/encoding intentionally when generating canonical scripts;
- hash every canonical production script;
- static dependency audit must be rerun whenever a canonical script changes.

A parser or reporting failure in a read-only certification script is a script defect, not evidence that the image is damaged. Fix the script without mutating the image.

---

# 14. CBS / WINSXS POLICY

WinSxS is not a cleanup directory.

Authority order:

1. native servicing;
2. validated package/capability/feature removal;
3. BlueLite dependency-aware AMBER method;
4. secondary servicing-aware component engine;
5. raw carve only as RED research, never as a default production technique.

Treat as one graph:

- package metadata;
- MUM/CAT;
- COMPONENTS;
- deployments;
- owners;
- components;
- manifests;
- WinSxS payload;
- hardlink projections.

A single-link file, `UnstagedFiles`, `f!`, `c!`, or an apparently orphaned directory is only a signal to investigate. It is not a delete permit.

Targeted owner-metadata changes are allowed only when the exact owner topology is proven and a disposable servicing test demonstrates a clean resulting state.

Broad `COMPONENTS` edits are prohibited.

---

# 15. COMPONENT STORE CLEANUP POLICY

Component-store cleanup is not interleaved blindly with forensics.

Use cleanup at deliberate boundaries after the relevant mutation layer has been certified.

Final release cleanup sequence:

1. `AnalyzeComponentStore`;
2. `StartComponentCleanup`;
3. optional `ResetBase` only when release policy explicitly accepts rollback/serviceability consequences;
4. `CheckHealth`;
5. `ScanHealth` when appropriate;
6. pending-state gate;
7. export to a new clean WIM;
8. hash.

If the UUP one-click pipeline performs cleanup/ResetBase in its post-reconstruction pre-ISO stage, that stage must already have completed its own mutation and health gates. `ResetBase` must never be used as a way to hide an unresolved servicing contradiction.

---

# 16. COMMON BASE SERVICES AND POLICY FLOOR

The common base remains **Defender ON** until the final branch split.

Validated policy intent:

- unnecessary telemetry/diagnostic services disabled;
- `WSearch` disabled;
- `SysMain` disabled;
- Recall/AI policies neutralized;
- Windows Update pause timestamps set to `2100-12-31T23:59:59Z`;
- native pause framework remains functional;
- `SetMaxPauseDays=35` remains preserved rather than replacing native Pause/Resume behavior.

The Windows Update servicing core is retained because BlueLite requires:

- working Resume/Pause;
- cumulative-update serviceability;
- Defender ON update path;
- normal CBS servicing.

Validated common-base servicing floor from the development build included:

- `wuauserv` retained;
- `UsoSvc` retained;
- `WaaSMedicSvc` retained;
- `BITS` retained;
- `CryptSvc` retained;
- `TrustedInstaller` retained.

Exact service start values must be verified against the current certified rule, not assumed from one historical build.

Do not “debloat” the common base by amputating the entire Windows Update engine.

---

# 17. APPX / STORE / OPTIONAL APPLICATION POLICY

The common base retains the currently defined top-level inbox set:

- SecHealthUI;
- Calculator;
- Notepad;
- Photos.

Framework dependencies are retained only if the actual current manifests require them.

The following are not common-base requirements:

- Microsoft Store;
- StorePurchaseApp;
- DesktopAppInstaller/winget;
- optional user apps.

The Store ecosystem is removed/deprovisioned through supported or certified methods. Do not use broad EndOfLife/Deleted-EndOfLife registry manipulation as a substitute for understanding package state. Do not use StateRepository SQLite surgery as normal production logic.

Classic Windows Photo Viewer, Store reinstall, optional MSIX/AppX packages and user conveniences belong in the optional BlueLite payload when they do not need to be active OS dependencies.

---

# 18. DEFENDER BRANCHING

Maintain one canonical common base with Defender ON.

Branching happens only after all common-base scripted/component-engine work and corresponding certification are finished.

## Defender ON

No Defender-disable branch mutation.

## Defender OFF

Separate branch-only engine with an explicit allow-list.

Known runtime targets include:

- `MDCoreSvc`
- `WinDefend`
- `WdNisSvc`
- `WdNisDrv`
- `WdBoot`
- `WdFilter`
- `Sense`

Never use a wildcard such as `Wd*`.

`SecurityHealthService`, `wscsvc` and `SecHealthUI` are not automatically equivalent to the Defender AV engine and are not included merely because their names are security-related.

Physical Defender/Sense CBS/WinSxS payload removal requires separate component-removal proof.

Never apply Defender OFF logic to the only common-base copy.

---

# 19. VMWARE / VIRTUALBOX HOST COMPATIBILITY FLOOR

A major late-stage refinement was that BlueLite may remove selected Hyper-V/virtualization management and guest-oriented components while still preserving the required host dependency floor.

Every virtualization-related AMBER rule must protect and revalidate at least the currently proven critical set:

| Role | Current proven path |
|---|---|
| Windows Hypervisor Platform interface | `Windows\System32\WinHvPlatform.dll` |
| AMD/SVM Hyper-V hypervisor image | `Windows\System32\hvax64.exe` |
| Intel/VT-x Hyper-V hypervisor image | `Windows\System32\hvix64.exe` |
| Virtual machine bus | `Windows\System32\drivers\vmbus.sys` |
| Virtualization infrastructure driver | `Windows\System32\drivers\vid.sys` |
| Network dependency floor | `Windows\System32\drivers\ndis.sys` |
| Network dependency floor | `Windows\System32\drivers\netio.sys` |
| Network dependency floor | `Windows\System32\drivers\tcpip.sys` |
| Storage dependency floor | `Windows\System32\drivers\storport.sys` |
| Storage dependency floor | `Windows\System32\drivers\disk.sys` |
| Storage dependency floor | `Windows\System32\drivers\partmgr.sys` |

`hvax64.exe` and `hvix64.exe` are **not two Intel-only binaries**: the former is the AMD/SVM hypervisor image and the latter is the Intel/VT-x image. A portable x64 BlueLite image must therefore preserve the architecture-specific hypervisor images actually supplied by the retained Windows virtualization stack. Do not invent or hardcode unverified alternatives such as `hvamd64.exe` / `hvimd64.exe`.

The file names above are the **current proven Germanium identities**, not eternal assumptions. For every new build, the virtualization floor gate must first resolve the actual source-image files/components/owners. If Microsoft changes an identity, packaging or ownership topology, classify that contract as `TOPOLOGY_CHANGED` and block the virtualization mutation until the floor is re-certified.

The gate must verify:

- protected files exist;
- expected WinSxS/hardlink relationship remains;
- networking floor remains;
- storage floor remains;
- virtualization feature contract does not drift unexpectedly;
- capability providers required by the host remain operational;
- `pending=0`;
- servicing health remains clean.

The protected list is intelligence, not an eternal hardcoded assumption. If a future Germanium build changes the VM-host dependency graph, delta discovery must update it before virtualization removals run.

---

# 20. VALIDATED INTELLIGENCE SNAPSHOT AS OF 2026-09-29

This section records proven development outcomes. It is not a hardcoded build list. Every production rule still requires current-build resolution and pre-production gates.

| Logical target | Current validated disposition | Key rule |
|---|---|---|
| Recall / AIX closure | `PRODUCTION_RULE` | Portable scripted AMBER engine; final feature absence is a valid post-state |
| AppX/framework cleanup | `PRODUCTION_RULE` | Preserve four common-base Apps and only required frameworks |
| Edge WebView FoD | `PRODUCTION_RULE` | Native `Remove-Capability`; large clean payload reduction |
| WebView2Standalone residue | `COMPONENT_ENGINE_HANDOFF` | Shared owner blast radius too broad for package removal/raw carve |
| DirectX Configuration Database | `PRODUCTION_RULE` | Native `Remove-Capability` |
| DirectX helper/updater residue | `COMPONENT_ENGINE_HANDOFF` | Do not broaden package removal |
| Kernel LA57 | `PRODUCTION_RULE` | Native `Remove-Capability` |
| LA57 setup-helper residue | `COMPONENT_ENGINE_HANDOFF` | Keep out of broad package removal |
| `Language.Basic~~~en-US` | `PRODUCTION_RULE` | Native `Remove-Capability`, while Client Language Pack remains KEEP |
| FoDMetadata superseded main | `PRODUCTION_RULE` | Native `Remove-Package` |
| Old FoDMetadata wrapper | `KEEP_SKIP` | Retained servicing metadata |
| FoDMetadata core | `PRODUCTION_RULE` | Exact self-owner AMBER decouple + native `Remove-Package` |
| Desktop-CompDB | `KEEP_SKIP` | Servicing dependency / capability-provider floor |
| OneDrive setup package set | `PRODUCTION_RULE` | Portable AMBER sequence: current neutral → WOW64 neutral → old staged neutral; satellites removed by servicing |
| OneDriveBackup residue | `COMPONENT_ENGINE_HANDOFF` | Do not broaden the proven package rule |
| SearchEngine wrapper / srchadmin | `PRODUCTION_RULE` | Portable AMBER wrapper removal |
| Remaining Search physical set | `COMPONENT_ENGINE_HANDOFF` | WSearch remains disabled; residue not raw-carved |
| XPS residual | `COMPONENT_ENGINE_HANDOFF` | Native removal path exhausted/no-op; broad package carve rejected |
| Internet Printing Client | `KEEP_SKIP` | Disabled; physical payload absent; servicing metadata only |
| LPD neutral package set | `PRODUCTION_RULE` | Exact-owner AMBER rule |
| LPR neutral package set | `PRODUCTION_RULE` | Exact-owner AMBER rule after disposable certification |
| Sense | `COMPONENT_ENGINE_HANDOFF` / ongoing intelligence | Native capability removal fails; raw carve rejected because it makes component store Repairable |
| UserExperience-AOT | `COMPONENT_ENGINE_HANDOFF` | Secondary servicing-aware engine target |
| CoreAI | `COMPONENT_ENGINE_HANDOFF` | Secondary servicing-aware engine target |
| AIFabric | `COMPONENT_ENGINE_HANDOFF` | Secondary servicing-aware engine target |
| Current required FoDMetadata servicing layer | `KEEP_SKIP` | Current provider/servicing dependency |
| Selected Hyper-V/virtualization child families | `PRODUCTION_RULE` where individually certified | Exact-owner/multi-owner AMBER, always behind VM-host protected-floor gate |

Validated virtualization examples include, where their individual certificates passed:

- VMMS;
- Hyper-V Worker;
- Compute Host;
- Compute Host VirtualMachines;
- Chipset;
- IsolatedVM merged;
- Containers Client SDN/VFP;
- Hyper-V UX PowerShell neutral merged;
- LegacyChipset neutral merged;
- IsolatedVM-SVC neutral merged;
- VmSerial;
- Virtio;
- VmBus-VirtualDevice.

These names are logical intelligence targets. Future builds must resolve exact package/deployment/component identities dynamically.

Build-specific measured savings, such as the large Edge WebView and OneDrive reductions, are evidence that the rules have value; they are not guaranteed byte counts for a new build.

---

# 21. KNOWN ANTI-PATTERNS — DO NOT REPEAT

The following approaches were tried, exposed as brittle, or explicitly rejected:

1. deleting Windows/FoD/reference UUP inputs before reconstruction closure is satisfied;
2. treating a physical directory name as a servicing identity;
3. broad version-pattern removal;
4. broad parent-package removal to get one small child component;
5. raw WinSxS deletion while package/component state remains Installed;
6. treating `CheckHealth` alone as proof for a new raw/AMBER carve;
7. trusting DISM exit code without post-state;
8. trusting `/Get-Packages` global table as the only authority for an exact target;
9. using broad `sense` matching that also captures `StorageSense`;
10. editing a shared SystemApp binary because one logical app uses it;
11. editing package manifests/signature surfaces without a complete registration/integrity model;
12. broad `COMPONENTS` manipulation;
13. StateRepository database surgery as a default removal path;
14. using EndOfLife markers as a blind first-boot cleanup mechanism;
15. opening NTLite because the current AMBER list “looks finished”;
16. allowing NTLite to duplicate work already handled by canonical scripts;
17. applying Defender OFF to the only common-base copy;
18. committing an investigative read-only mount;
19. leaving test hives or stale disposable mounts registered;
20. using a production script whose source hash, parser state or structural anchors are not verified.

---

# 22. CANONICAL PRODUCTION PIPELINE

The normal release pipeline is:

## PHASE A — SOURCE FREEZE

1. Operator selects/accepts exact UUP source.
2. Capture source identity/hashes.
3. Preserve original UUP launcher/config/list.

## PHASE B — UUP RECONSTRUCTION + PRE-MUTATION DISCOVERY GATE

1. Apply supported AppX selection.
2. Preserve full required Windows/reference/delta closure.
3. Download/reconstruct.
4. Integrate updates.
5. Produce Professional `install.wim`.
6. Initial health/pending gate.
7. Capture the reconstructed **pre-mutation baseline manifest** defined in Section 8.
8. Diff it against the last certified Germanium baseline and classify known targets as `UNCHANGED`, `VERSION_CHANGED`, `TOPOLOGY_CHANGED`, `NEW` or `ABSENT`.
9. Block mutation for `TOPOLOGY_CHANGED` / unsafe `NEW` targets before any certified pre-ISO module can touch them.

## PHASE C — PRE-ISO OFFLINE ENGINE

Run only already-certified production modules that are safe and useful immediately after reconstruction **and whose current-build contract has passed the Phase B discovery/pre-production gates**.

This phase may include:

- native capability removals;
- native standalone package removals;
- already-certified portable AMBER modules;
- AppX cleanup;
- common offline policy/service work;
- protected-floor validation.

It must not contain unproven research carves.

## PHASE D — POST-PRE-ISO RESIDUE + INTELLIGENCE MANIFEST

1. Build a machine-readable post-pre-ISO residue manifest.
2. Diff it against the Phase B pre-mutation manifest and the last certified post-pre-ISO Germanium state.
3. Verify the expected post-state and measured delta of every module executed in Phase C.
4. Populate the Intelligence queue with unresolved `TOPOLOGY_CHANGED`, `NEW` and other realistic remaining offline candidates.
5. Preserve the Phase B pre-mutation manifest and Phase D residue manifest as separate evidence artifacts; never overwrite one with the other.

## PHASE E — GREEN PRODUCTION

Apply all proven native rules whose current contract matches.

## PHASE F — PORTABLE AMBER PRODUCTION

Apply all certified AMBER rules whose pre-production gates match.

## PHASE G — INTELLIGENCE QUEUE EXHAUSTION

For every remaining realistic offline candidate, produce one terminal disposition:

- production rule;
- keep/skip;
- component-engine handoff;
- RED hold.

Do not open NTLite while a realistic offline production candidate remains unresolved.

## PHASE H — COMMON BASE CERTIFICATION

Read-only certification of:

- mount/source identity;
- `CheckHealth`;
- pending = 0;
- retained AppX/frameworks;
- removed target post-states;
- service/policy floor;
- Windows Update pause/servicing floor;
- Defender ON baseline;
- component-store report;
- protected VM/network floor;
- no unexpected mutation.

## PHASE I — SECONDARY COMPONENT ENGINE / NTLITE

Only explicit `COMPONENT_ENGINE_HANDOFF` targets.

## PHASE J — POST-COMPONENT-ENGINE RECERTIFICATION

Repeat common-base certification and target-specific post-tests.

## PHASE K — DEFENDER BRANCH

Create Defender ON and Defender OFF derivatives from the certified common base.

## PHASE L — FINAL CLEANUP / EXPORT / ISO

1. component-store analysis;
2. approved cleanup;
3. commit;
4. clean WIM export;
5. hashes;
6. branch artifacts;
7. ISO assembly.

## PHASE M — VIRTUALBOX ONLINE-ONLY FINISHING + VALIDATION

Only after offline and NTLite/component-engine work is finished.

## PHASE N — RELEASE

A build becomes BlueLite RELEASE only when all required branch/serviceability/runtime gates pass.

---

# 23. CANONICAL SCRIPT SET VS FORENSIC HISTORY

## 23.1 Forensic/development scripts

Used for:

- package/component discovery;
- owner graph research;
- hardlink analysis;
- binary/string analysis;
- FBConan/reference comparison;
- disposable experiments;
- blast-radius measurement;
- new-rule certification.

They are not part of every future build.

## 23.2 Production scripts/modules

Small, ordered, versioned, hashed and idempotent.

The final production set should cover:

- preflight/delta;
- native GREEN removals;
- portable AMBER removals;
- AppX handling;
- common services/policies;
- pre-production gates;
- certification;
- cleanup/export;
- handoff manifest generation.

A new Germanium release should not require reconstructing the procedure from chat phase numbers.

## 23.3 Static release-pack audit

Every canonical script update invalidates the previous static-pack hash contract.

Before runtime release use:

- parser = 0 errors;
- expected filenames;
- expected SHA-256;
- dependency ordering;
- no forbidden mutation primitive in read-only certification scripts;
- correct source/target references;
- correct expected post-state contracts.

---

# 24. COMMON BASE CERTIFICATION DESIGN

Certification scripts are read-only.

They must not:

- remove packages;
- remove AppX;
- change features;
- write registry values;
- run component cleanup;
- commit/unmount.

Certification must tolerate **only explicitly documented idempotent post-states**.

Example lesson: after Recall/AIX production removal, `Recall` being unknown/absent is a valid expected state. A certification script that still insists on `Recall=Disabled` is stale and must fail closed until updated.

Certification output should include:

- exact image identity;
- target state matrix;
- service/policy matrix;
- retained AppX matrix;
- component-store metrics;
- pending count;
- health result;
- Defender branch state;
- handoff list;
- final certification token.

---

# 25. NTLITE BUSINESS POLICY

NTLite is a **secondary dependency-aware component engine**.

It is not:

- the first debloat tool;
- a replacement for BlueLite intelligence;
- an excuse to stop offline automation research;
- a place to click additional removals “while we are there.”

Before NTLite:

- GREEN exhausted;
- certified portable AMBER exhausted;
- real Intelligence candidates analyzed;
- common base certified;
- rollback/checkpoint created;
- exact handoff manifest generated.

Each NTLite target must contain:

- logical BlueLite target;
- exact current NTLite-visible target name;
- reason scripted path is not used;
- desired post-state;
- protected dependencies;
- post-test.

If no true residue exists, NTLite may be skipped.

After NTLite, full common-base recertification is mandatory.

If an NTLite action is later reproduced reliably by the BlueLite build-independent engine, it must migrate back into the scripted pipeline.

The actual local NTLite version must be logged on each release. Historical project reference: Business 2025.8.10552; do not assume this remains the installed version forever.

---

# 26. PACKAGING AND ARTIFACT POLICY

During development, the canonical master remains a serviceable WIM.

Artifacts are distinct:

1. source/reconstruction artifact;
2. certified common-base servicing master;
3. Defender ON branch;
4. Defender OFF branch;
5. final distribution-compressed derivative;
6. ISO.

Every major artifact gets:

- size;
- SHA-256;
- source parent identity;
- build/edition/index;
- production manifest version;
- certification status.

LZMS/solid compression is a final transport optimization, not the development master.

---

# 27. VIRTUALBOX FINAL PHASE

VirtualBox begins only after all realistic offline work and the secondary component-engine handoff are complete and recertified.

VM is not a repair shop for incomplete offline work.

Functions:

- first boot;
- OOBE/local-account validation;
- new user profile;
- retained app/runtime test;
- reboot/shutdown cycles;
- Event/CBS sanity;
- component-store health;
- Windows Update Resume/Pause test;
- Defender ON test;
- Defender OFF test;
- networking test;
- VMware/VirtualBox host compatibility checks where applicable;
- install next appropriate Germanium CU;
- verify removed targets are not unexpectedly resurrected;
- footprint measurement;
- online-only finishing/integration.

Use snapshot before CU/serviceability tests.

If an online action proves deterministic and dependency-aware offline, migrate it back to the offline engine in the next revision.

Release does not exist until both Defender branches pass the required VM validation.

---

# 28. OPTIONAL USER PAYLOAD

Anything that does not need to be a permanent active OS dependency belongs outside the common image.

Examples:

- Store reinstall package;
- optional Apps;
- classic Photo Viewer integration;
- enable/disable REG files;
- feature installers;
- scripts/toggles;
- troubleshooting tools;
- recovery helpers.

This keeps the common base small and prevents optional functionality from forcing permanent framework/runtime retention.

---

# 29. NEW GERMANIUM BUILD — EXPECTED AUTOMATIC WORKFLOW

For each new Germanium build:

1. freeze exact source;
2. reconstruct full dependency closure;
3. apply supported source/AppX minimization;
4. create reconstructed `install.wim`;
5. run initial health/pending gate;
6. generate the reconstructed **pre-mutation baseline/delta manifest**;
7. resolve known logical targets dynamically and block unsafe `TOPOLOGY_CHANGED` / `NEW` mutation;
8. execute only certified pre-ISO production modules whose current contracts match;
9. run post-pre-ISO health/pending and expected-post-state gates;
10. generate a separate post-pre-ISO residue/intelligence manifest;
11. SKIP absent targets idempotently;
12. automatically process remaining `UNCHANGED` / safe `VERSION_CHANGED` rules whose topology matches;
13. research only the changed/new Intelligence queue;
14. promote successful new methods into production rules;
15. exhaust GREEN;
16. exhaust portable AMBER;
17. classify all remaining candidates;
18. certify common base;
19. send only true component-engine handoff targets to NTLite/secondary engine;
20. recertify;
21. branch Defender ON/OFF;
22. cleanup/export/hash/ISO;
23. VM online-only finishing and validation;
24. CU/serviceability test;
25. measure ISO/installed footprint;
26. declare RELEASE only if all gates pass.

The desired trend is that each new Germanium build needs fewer research steps than the previous one.

---

# 30. REQUIRED FUTURE REPOSITORY ARTIFACTS

The repository should progressively converge on the following canonical artifacts:

```text
BlueLite-Master_Germanium_Strategy_v2.1.md
BlueLite_Sources.md
Component_Intelligence.*
Production_Execution_Manifest.*
Production_Hash_Manifest.*
NTLite_Handoff_Manifest.*
Release_Manifest.*
```

The exact data format for machine-readable files may evolve, but their logical roles should remain stable.

`Component_Intelligence` should become the durable repository of target rules so that chat memory is never required to reconstruct the project.

---

# 31. RELEASE GATES

A release is blocked if any of the following is true:

- source identity is ambiguous;
- mount identity is ambiguous;
- unexpected pending servicing exists;
- `CheckHealth` is not clean;
- required `ScanHealth` gate is not clean;
- a protected dependency is missing;
- an AMBER topology differs from the certified contract;
- a production script hash/parser/static audit is invalid;
- a RED target was mutated without new proof;
- an unclassified realistic offline candidate remains while NTLite handoff is being attempted;
- NTLite performed an unplanned target operation;
- post-NTLite recertification fails;
- Defender branch validation fails;
- Windows Update Resume/Pause contract fails;
- CU serviceability validation fails;
- final artifact hashes are missing.

Fail-closed behavior is a feature of BlueLite, not a defect.

---

# 32. MAIN RULE

The project is not trying to create one small `26200.x` image.

It is building a **BlueLite compiler for Windows 11 Germanium**.

Canonical conceptual pipeline:

```text
USER-SELECTED UUP SOURCE
    ↓
SOURCE FREEZE
    ↓
FULL RECONSTRUCTION CLOSURE
    ↓
SUPPORTED APPX/SOURCE MINIMIZATION
    ↓
RECONSTRUCTED install.wim
    ↓
PRE-MUTATION BASELINE + DELTA / TOPOLOGY GATE
    ↓
CERTIFIED PRE-ISO OFFLINE MODULES
    ↓
POST-PRE-ISO RESIDUE + INTELLIGENCE MANIFEST
    ↓
GREEN PRODUCTION RULES
    ↓
PORTABLE AMBER PRODUCTION RULES
    ↓
INTELLIGENCE QUEUE EXHAUSTION
    ↓
COMMON-BASE CERTIFICATION
    ↓
SECONDARY COMPONENT ENGINE / NTLITE
ONLY FOR TRUE HANDOFF RESIDUE
    ↓
RECERTIFICATION
    ↓
DEFENDER ON / DEFENDER OFF BRANCH
    ↓
CLEANUP / EXPORT / HASH / ISO
    ↓
VIRTUALBOX ONLINE-ONLY FINISHING + VALIDATION
    ↓
CU / SERVICEABILITY TEST
    ↓
BLUELITE RELEASE
```

The highest-level invariant is:

> **If BlueLite can prove and reproduce a dependency-aware operation offline, that operation belongs in the BlueLite engine — not permanently in NTLite, not permanently in VM, and not in manual chat history.**

Every new investigation must reduce future manual work.

---

# 33. CHANGE SUMMARY FROM THE PREVIOUS MASTER STRATEGY

This v2.2 strategy incorporates the v2.1 late-history/review corrections and the 2026-10-01 remote-execution operating contract:

1. workspace moved from `C:\Users\Admin\Downloads\work` to **`C:\work`**;
2. main workstation changed to **ASUS / i7-11700F / GTX 1050 / 16 GB DDR4-3200**;
3. Ryzen 5 4500U / 8 GB is now the test/backup machine;
4. UUP pre-debloat is explicitly split into safe source/AppX minimization and post-reconstruction pre-ISO offline debloat;
5. destructive Windows/FoD/reference queue pruning is prohibited;
6. one-click UUP packaging must consume the same canonical production rules as standalone offline processing;
7. removal class and release disposition are formally separated;
8. `COMPONENT_ENGINE_HANDOFF` is an explicit terminal disposition and is not equivalent to RED;
9. disposable test → independent certification → canonical pre-production gate → canonical apply → independent certification is the standard AMBER lifecycle;
10. `ScanHealth` is mandatory for new AMBER certification and other high-risk servicing changes;
11. target-specific package/capability evidence outranks assumptions from global inventory tables;
12. PowerShell production coding rules now include protection against `$Matches` shadowing, empty typed-list binding and scalar/array ambiguity;
13. virtualization removals now require an explicit VM/network protected-floor gate;
14. the validated intelligence snapshot records the production vs handoff split discovered in Phases 94–353;
15. the Intelligence queue must be exhausted before NTLite;
16. release scripts are a small canonical set; forensic phase history is retained as evidence but removed from normal build execution.

## v2.1 review corrections

17. virtualization-floor terminology now explicitly records `hvax64.exe` as the AMD/SVM hypervisor image and `hvix64.exe` as the Intel/VT-x image; unverified `hvamd64.exe` / `hvimd64.exe` names are not introduced;
18. every future Germanium virtualization rule must resolve the actual architecture-specific hypervisor identities and owners from the current source WIM and fail closed on topology drift;
19. the reconstructed pre-mutation baseline/delta gate now occurs **before** certified pre-ISO mutation, resolving the ambiguity between Section 8 and the former Sections 22/29/32 ordering;
20. a separate post-pre-ISO residue/intelligence manifest is mandatory so source topology evidence is never overwritten by the mutated post-state.

## v2.2 remote execution contract

21. Remote Desktop Commander is formally recognized as the standard remote execution transport on the authorized main workstation when available;
22. remote execution changes transport only and does not change the canonical target boundary: the live OS remains the host, while normal BlueLite mutation remains restricted to explicitly verified offline images under `C:\work`;
23. before first mutation in a session, remote preflight must verify device identity, canonical paths, DISM mount state and exact WIM/index/mount target, failing closed on ambiguity;
24. read-only discovery/log collection may be performed directly by ChatGPT without manual copy/paste relay, while mutation still follows the one-executable-step-at-a-time protocol;
25. RDC autostart/persistent authorization is treated as an execution convenience, not standing authorization for unsupervised mutation;
26. successor sessions should use RDC when available but must derive authority from this Master Strategy, not merely from tool access;
27. if RDC is unavailable, the workflow degrades cleanly to the established operator-executes / ChatGPT-analyzes relay model.

---

**End of BlueLite v1.0 — MASTER GERMANIUM STRATEGY v2.2**
