# BlueLite v1.0 — MASTER GERMANIUM STRATEGY v3.0.0

**Status:** AUTHORITATIVE / UNIFIED PRODUCTION ARCHITECTURE — SUPERSEDES PREVIOUS MASTER REVISIONS  
**Date:** 2026-10-15  
**Scope:** Windows 11 **Germanium family**, including **26100.x (24H2), 26200.x (25H2), 26300.x (26H2)** and later family members confirmed through image lineage/dependency discovery; a numeric range alone does not certify an unknown OS branch  
**Project:** BlueLite v1.0  
**Team:** Operator + ChatGPT; all commands execute locally with the operator  
**Canonical historical evidence:** Library, predecessor sessions, GitHub `BlueLite_Current_Status.md`, and `BlueLite_Sources.md`  
**Production goal:** **Prepare once → build repeatedly → inspect only actual deltas → release quickly after predefined acceptance tests.**

---

## 0A. MASTER OPERATING CONTRACT — UNIVERSAL GERMANIUM FACTORY

### 0A.1 Šta je cilj, a šta nije

**BlueLite nije četrdesetodnevni debloat jednog builda. BlueLite je reproduktibilna, unapred pripremljena proizvodna fabrika za čitavu Germanium familiju.** Nijedna sesija, broj eksperimenta ili novi CU ne sme ponovo otvoriti već rešene zadatke bez konkretno dokazanog novog uzroka. Željeni rezultat je proizvodni paket koji operator pokreće na novoizabranom UUP izvoru i dobija najmanji dokazan Windows image uz definisane funkcije, zaštitu zavisnosti, Defender ON/OFF varijante, logove i testove.

**Univerzalnost NE znači** iste binarne pakete, identične verzije, istu veličinu, podršku za nepoznatu familiju bez provere, niti uklanjanje svake mandatory komponente. **Znači** da su tehnologija, konfiguracije i workflow već pripremljeni, a promene među buildovima sistem **automatski prepoznaje i obrađuje**. Uobičajena razlika u verziji ili identitetu ne pokreće novo istraživanje. Istraživanje se radi samo kad prethodno sertifikovano pravilo ne može da reši stvarno promenjenu zavisnost.

### 0A.2 ČETIRI SAMOSTALNO UNIVERZALNE FAZE — OBAVEZAN REDOSLED

1. **GERMANIUM UUP MAX_PRE:** Jedan verzionisan wrapper i skup univerzalnih skripti/config/answer fajlova za operatorov izbor i zamrzavanje UUP izvora, rekonstrukciono bezbedno pre-download AppX filtriranje, updates, pravilno sklapanje WIM-a, **automatski maksimalni post-reconstruction/pre-ISO debloat**, eksport, ISO i hash manifest. Za isti logički target ne postoje odvojene proizvodne UUP skripte za 26100, 26200 ili 26300.
2. **GERMANIUM POWERSHELL OFFLINE MAX-DEBLOAT:** Verziona, samostalno primenljiva univerzalna PowerShell/DISM/offline-registry produkciona kolekcija. Koristi **iste** remove/keep/restore/intelligence module kao MAX_PRE; proverava ranije već izvršeno i obrađuje samo stvarni offline ostatak. CBS/WinSxS, feature/capability, package, AppX, servis, registry, integracije, optional/payload i dependency-gates su unapred automatizovani.
3. **GERMANIUM NTLITE BUSINESS:** Jedan bazni, verzionisan i **ponovo primenljiv XML preset set** sa deklarativnim profilima i preciznim build-aware izuzecima. NTLite je za opravdan `COMPONENT_ENGINE_HANDOFF`, ne za ponavljanje PS faze. Profili su realno testirani na više Germanium izvora; NTLite može da obradi samo preostali deo koji je izričito planiran.
4. **GERMANIUM VM/VMBOX FINALIZACIJA:** Jedan unapred pripremljen VM bootstrap/first-logon/post-setup profil za ostatak online debloat-a, tweaks, **administratorski nalog**, Defender varijante, user desktop instalere, capture, testove i release. Guest-only VM proba nije dokaz da instalirani BlueLite može biti VMware/VirtualBox host.

**Sekvenca je fiksna, ali rad u sesijama nije proizvodni interfejs.** U razvoju radimo jednu lokalnu proverljivu komandu po poruci. U zrelom release režimu operator pokreće **prethodno pregledan** entrypoint bez stotina ručnih koraka; testovi, snapshot-i i nepovratne akcije imaju eksplicitne automatske ili operatorske granice.

### 0A.3 KOMPONENTNA PRAVILA, NE NEPRESTANO ISTRAŽIVANJE

**CORE = ENGINE + PROFILES (policy/XML/INI/JSON) + COMPONENT INTELLIGENCE + PRODUCTION MANIFEST + PREDEFINED TESTS.**

- **`UNCHANGED`, `VERSION_CHANGED`, `ALREADY_ABSENT`:** automatski izvrši potvrđeno pravilo ili idempotentni SKIP nakon uske provere sadašnjeg image-a. Ovo je **normalna fast path**, bez ponovnog dugog auditovanja.
- **`KNOWN_VARIANT`:** automatski primeni prethodno sertifikovanu alternativu po tačnom stanju/topologiji, ne po nagađanju build broja.
- **`UNKNOWN_TOPOLOGY` / `UNKNOWN_DEPENDENCY` / `NEW_TARGET`:** izoluj samo pogođeni target i zabeleži dokaz. Nepovezani sertifikovani koraci mogu da se nastave ako transakcije i zavisnosti to dozvoljavaju. Finalni release ostaje blokiran ako je taj target mandatory release gate; drugačije pravilo može ga klasifikovati kao dokazani `KEEP_SKIP` ili handoff.
- **`PERMANENT` / `PROTECTED` / `NOT_SUPPORTED`:** klasifikuj prema dokazanom CBS/AppX stanju i originalnoj politici. Ne pretvaraj failure automatski u `PASS`, ali ne ponavljaj istu već dokazano odbijenu naredbu pri svakoj sledećoj verziji.

Stvarna promene u `COMPONENT INTELLIGENCE` (npr. owner/graph varijanta, exact package/PFN, predicate, allowed delta i fallback) rešava problem **bez umnožavanja per-build proizvodnih skripti**. Neuspeo novi build ne poništava prethodnu potvrđenu metodu za buildove sa odgovarajućom topologijom.

### 0A.4 OBAVEZA KORIŠĆENJA VEĆ PRIKUPLJENOG ZNANJA

Pre svakog novog istraživanja koristi aktuelni MASTER, GitHub Current Status, Library istorijske i novije fajlove, prethodne sesije, izvore u `BlueLite_Sources.md`, službenu dokumentaciju i stvarni log trenutnog builda. **Historical Success Index** i **Known Failure Index** treba da budu mašinski čitljivi i pretraživi. Ako je problem već rešen u fazama 18C ili 44–48, polazi od tog pravila, ne od prvog neuspešnog DISM pokušaja. Isti failure koji se ponavlja ne smatra se novim nalazom.

Build Info drugih autora i reference debloated image-ova su **ciljni end-state / konfiguracioni uzori**; ne dokazuju automatski njihovu internu skriptu, način izrade, zdravstveno stanje ili trajanje procesa. Iz informacija o mogućem brzom release-u proizlazi opravdan inženjerski cilj standardizacije, **ne potvrđena tvrdnja o konkretnom uploaderovom privatnom postupku**.

### 0A.5 NEMA KONTRADIKCIJE IZMEĐU DEBLOATA I AUTOMATIZACIJE

Zadržavaju se najstroži tehnički dobri delovi projekta: immutable originalni izvori, dokumentovane dependency granice, uski target identiteti, provereni CBS/AppX post-state, ograničen uredan WinSxS, bez slepog registry/WinSxS carve-a, zaštita mreže/storage/VM host funkcija, nezavisni first-boot i servicing testovi. **Oni se izvršavaju automatizovano prema riziku i stanju**, umesto da pri svakom buildu zahtevaju novi ručni dnevnik analiza.

- Jednostavne, ponovljive operacije: brzi verifikacioni gate i odmah izvršenje.
- Novonastala/visokorizična dependency varijanta: ciljano duboko istraživanje i disposable dokaz **jednom za novu varijantu**; rezultat postaje trajno univerzalno pravilo.
- Razlikuj `rule validated`, `this-build verified` i `release certified`. Ni status ni XML sam po sebi ne garantuju rezultat.
- Jednom kad je tekst mutation modula pregledan i potpisan za proizvodnu verziju, operator **ne mora ponovo pregledati isti neizmenjeni izvor za svaki novi CU**; novi/revidirani visoko-uticajni modul zahteva novi pregled.
- Testne WIM kopije koje će biti korisne zadržati. Brisati samo sigurno nepotrebne ili bit-identično ponovljivo rekonstruisive kopije, uz owner/mount/hive/hash gate i operatorovu odluku. Nema rutinske local free-space provere.

### 0A.6 DOKAZ UNIVERZALNOSTI I METRIKE

Univerzalnost se dokazuje **matricom više stvarnih Germanium buildova**, uključujući 26100, 26200 i 26300 kad su im izvori dostupni, a ne proglasom na osnovu jednog uspešnog image-a. Proveriti source/config konverziju, baš isti proizvodni engine, AppX inventar, servisiranje, functional protected floor, NTLite profile compatibility, VM nalog/tweaks i oba Defender ogranka. Minimalni zahtev je automatizovana cross-build regresija sa pozitivnim/negativnim slučajevima; release odluka za konkretan build koristi brzi aktuelni run receipt i obavezni realni first-boot/servicing test.

Meriti zasebno: vreme do prvog ispravnog ISO-a, broj ručnih operatorskih intervencija, broj pravila koja su `AUTO_REUSED`, broj zaista novih dependency slučajeva, procenat obavljenog offline debloat-a pre NTLite, ISO/WIM/installed footprint (sa razlikovanjem compressed/unique/logical), health, reinstalacione i CU testove. **Cilj proizvodnog režima je izdavanje novog poznato-kompatibilnog Germanium builda u satima nakon dostupnosti kompletnog UUP izvora**, a ne novi višenedeljni istraživački projekat. Ovo je performance cilj, a ne obećanje za dosad nepoznat slučaj.

### 0A.7 OPERATORSKI ODNOS I GRANICE OVLAŠĆENJA

Operator određuje cilj i vrši lokalne radnje; ChatGPT proučava postojeće dokaze, gradi univerzalni kod/profil i proverava logove. Jedan lokalni korak po poruci **tokom razvoja**; pun copy/paste tekst, konkretne putanje/logovi, nijedan skriveni aktivni OS debloat. Pre svakog mount/unmount: **ZATVORI TOTAL CMD** i Explorer prozore na mount folderu. NTLite tek nakon offline faza; VM zadnja. Build 26300 je uključen u obim Germanium familije.

**Definition of Done:** postoje stvarni, pregledani, verzionisani i ponovo izvršivi **UUP MAX_PRE skripte**, **offline PowerShell skripte**, **NTLite XML preset-i** i **VM/admin/tweak skripte**; oni koriste iste politike i sertifikacione ugovore, rade na podržanoj Germanium matrici, a novi build standardno obrađuju uz minimalnu ručnu intervenciju. **Četiri samo teorijski univerzalna plana ili veliki broj testnih logova nisu isporuka.**

---

## 0. DOCUMENT AUTHORITY, EVIDENCE CORPUS AND PURPOSE

This v3.0 revision preserves the dependency and servicing evidence accumulated through v2.x, but changes the governing method from repeated per-build forensics to **prepared, reusable, delta-driven production**. Section 0A governs all later sections where historical research wording seems to require unnecessary repetition or automatic deletion. The historical four-chat evidence table remains a source record; later work is in the successor handoff. The historical four-chat evidence table below documents the earlier source corpus; later work is in the successor handoff.

This document is the governing strategy for BlueLite. It is not a summary of one build and it is not a list of isolated tweaks. It consolidates the complete project logic developed through the four chronological BlueLite chat histories and replaces the earlier Master Strategy wherever this document is more specific.

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
- **end-user virtual-machine hosting remains supported:** after BlueLite installation, users can independently install supported third-party hypervisors (at minimum VMware Workstation and Oracle VirtualBox) and create, start and operate their own VMs on hardware with the necessary virtualization capabilities; neither hypervisor is preinstalled in the common image;
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

## 2.4 From repeated disposable forensics to certified, reusable recipes

Research and routine production must not be confused:

1. Discover and prove each NEW high-risk method on an owned, source-verified disposable; record complete pre/post dependency state and image health.
2. Convert successful proof into an indexed, independently testable, versioned universal recipe with exact predicates and rollback/post-state.
3. For an unchanged or compatible known build, **reuse** that recipe automatically; no repeat of exploratory steps, native failures, lengthy owner-map surveys, or per-build approval of unchanged code.
4. When a genuinely novel dependency variant occurs, isolate its target, preserve logs and the useful forensic WIM, resolve once, and add the variant to Component Intelligence.
5. Release candidates still require current-image proof and functional gates. Fast path is **automation**, not suppression of verification.
6. Operator-managed project disposable WIMs are persistent until demonstrably unnecessary or bit-identically reproducible and authorized for scoped deletion. Ephemeral mount/hive handles must always be released. Never automatically delete potentially useful evidence after a failed probe.

This rule supersedes historical language elsewhere demanding automatic deletion or exhaustive new-build forensic re-certification of already-proven recipes.

## 2.5 From destructive UUP queue pruning to reconstruction-safe staging

Earlier UUP experiments demonstrated that deleting Windows/FoD/reference inputs before reconstruction can break delta/reference closure, producing `blob not found`, WIM errors or incomplete reconstruction.

Therefore the architecture changed:

- aggressively minimize **AppX selection** where the converter officially supports it;
- do **not** destructively prune the Windows/reference/delta/FoD closure merely because the final OS will not retain those components;
- allow reconstruction to finish correctly;
- then run the BlueLite offline pre-ISO engine against the reconstructed WIM.

This distinction is fundamental:

> **download/reconstruction dependency ≠ final-OS dependency**

## 2.6 NTLite only for proven scripted residue — not a research hostage

NTLite is the third factory stage, after usable UUP/PowerShell offline modules. This does **not** authorize stopping scripted research prematurely, but neither does it demand months of exhaustive investigation into every hypothetical component before using a prepared NTLite profile.

Each known/relevant target receives one terminal classification: `PRODUCTION_RULE`, `KEEP_SKIP`, `COMPONENT_ENGINE_HANDOFF`, or `RED_HOLD`. For **known and implementable scripted** cases, automate and finish first. Known NTLite-only cases pass with an explicit receipt. Unknown target dependencies become scoped issues; a mandatory release condition may block only the affected release candidate, **not the implementation of all other proven recipes or the ability to run a repeatable pipeline**.

Never treat a “fail-closed” dependency as permission to skip a mandatory target, but never turn a finished production rule into another ChatGPT-driven month of tests. When native offline solution becomes proven, migrate that rule from NTLite back to Stage1/2 and update the XML preset.

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

## 4.1 MANDATORY INTERNAL BLUELITE LIBRARY REVIEW

In addition to the public source catalog and GitHub governance files, **the operator's internal ChatGPT Library is a standing BlueLite research and evidence source**. It contains historical scripts, original operator logs, WIM/CBS/WinSxS and AppX inventories, reference-build `Build_info` records, forensic analyses, UUP helper materials and handoff documents. Its contents must not be overlooked in favor of reconstructing prior findings from memory or new web searches.

- **At the start of every BlueLite successor session**, after retrieving the live GitHub Current Status and governing Master Strategy, perform a targeted Library search for the latest relevant BlueLite evidence, decisions and supporting source files. Read the actual matching artifacts when material to the current task; do not claim to have reviewed the entire Library from a search alone.
- **Before new technical investigation, a dependency/removal decision, a revised production rule or a script proposal**, check the Library for original logs, prior tests, existing implementations and reference-build comparisons relevant to that specific target. Reuse independently verified findings where the current-image topology and certification scope permit it.
- Treat Library entries as **evidence candidates and historical knowledge**, not automatically current execution state, a certified production rule or authorization to mutate a WIM. Validate relevant file contents, dates, version/build identity, exact command or script, hashes, original log results, and their consistency with the live GitHub status and current-image evidence. Prefer original operator output over secondary summaries when a discrepancy matters.
- If Library search, a file or its full contents is inaccessible in the current session, state the specific evidence-access limitation and continue only from verifiable available material. Do not invent a file, assume the Library is fully indexed, or claim an unseen source was checked.

Library review complements, but **does not supersede**, the normative Master Strategy, the GitHub Current Status checkpoint, actual target-image evidence or BlueLite's operator-relay review and runtime certification gates.

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

## 6.1 OPERATOR-RELAY EXECUTION CONTRACT

BlueLite uses an explicit operator-relay execution model. ChatGPT designs, reviews and supplies complete commands/scripts; the operator executes them locally on the operator-controlled Windows workstation and returns the exact requested output/log. Direct remote control of the workstation by ChatGPT is not part of the BlueLite execution architecture.

Mandatory contract:

1. The live Windows installation is the **HOST**, never the target of ordinary BlueLite offline-image mutation.
2. Normal image mutation is permitted only against an explicitly verified offline image under the canonical `C:\work` workspace, with **paths determined by the current source/work manifest** (historical examples include `C:\work\extracted\install.wim` and `C:\work\G5\...\R113_Offline_AppX_Transactional\install.appx-transaction.wim`), verified Index and transaction-scoped mount. Never treat a historical path as universally current.
3. Debloat targets the verified **offline image**, not the active Windows installation. Native tooling may create/write temporary host `%SystemRoot%`, logs, TEMP, HKLM/offline-hive aliases and ancillary host-side state as required; such writes are allowed under §6.1A. Do not silently turn them into unreviewed durable configuration changes to the live OS; `/Online` debloat requires a separately approved scope.
4. ChatGPT does not directly execute commands on the workstation, browse its filesystem, control its processes, create persistent remote access or use remote-control plugins for the BlueLite workflow.
5. If a separate live-host administration task is explicitly requested, treat it as a separate scope; the operator executes the complete supplied command locally.
6. Before the first mutation of a session, an **operator-executed local preflight** verifies canonical paths, DISM mount table, WIM/index/mount identity, and absence of a stale/unintended target.
7. Ambiguous target identity means fail closed. A canonical image, disposable image and reference FBConan image may never share an ambiguous mount/hive namespace.
8. Read-only discovery and log collection follow the operator-relay model unless already available from files or certified evidence.
9. One complete copy/paste executable step at a time; specify exactly the required log/output and path.
10. No hidden alternate source of truth: production scripts stay in `C:\work\scripts`, logs in `C:\work\logs`, checkpoints in `C:\work\backup`.
11. No standing unattended remote authorization, remote bridge, autorun or scheduled host control is assumed or required.
12. A successor must preserve this model unless the operator explicitly changes the governing strategy.

## 6.1A LOCAL WRITE LIFECYCLE: EPHEMERAL HOST STATE VS PERSISTENT PROJECT STATE (2026-10-13)

**Operator-authoritative clarification; replaces earlier excessively restrictive interpretations:** BlueLite is developed and executed locally on the normal Windows workstation. **All local write operations needed by the agreed offline workflow are allowed in principle**, including operations which use or temporarily write Windows `%SystemRoot%`, `%TEMP%`, native DISM system state/logs, host-side registry handles/`HKLM` aliases, and temporary Windows-managed resources. **Do not confuse an allowed temporary host write with the intended durable modification of the running Windows installation.** Our debloat/servicing target remains an explicitly verified **offline** WIM or its approved disposable derivative; native tooling can still use the host's facilities. An isolated boot, VHDX, VM, or remote server is not a prerequisite for ordinary offline processing. Never impose blanket bans on `%SystemRoot%`, registry writes, DISM logging, or host TEMP merely because they are local.

**Two storage / lifetime classes must always be explicit:**

1. **EPHEMERAL HOST-SESSION STATE**: `%SystemRoot%` (including Windows TEMP/logs), user/system `%TEMP%` and `%TMP%`, system-managed DISM scratch/logs/mount handles, any temporary `HKLM` offline-hive aliases and registry changes deliberately made as part of the scoped local workflow, transient process/helper files, and other incidental host changes. Writes are **allowed**, subject to the purpose, target, permissions, scope, and reversibility of the operation. The operator routinely clears system logs/TEMP/transient registry traces before shutdown. Never treat these locations as the only durable record, nor assume their contents survive a session. Do not interpret nightly cleanup as image rollback.
2. **PERSISTENT / OPERATOR-MANAGED PROJECT STATE**: `C:\work` and its explicit subfolders, including `C:\work\scripts` (code), `C:\work\logs` (authoritative operator evidence), `C:\work\backup` (checkpoints), frozen UUP sources, WIMs, manifests, and owned workspace/disposable images under `C:\work\E2E`. These **may survive indefinitely across sessions** until the operator specifically decides to remove or replace them. "Disposable" project files are *not automatically deleted*. Every file deletion must follow scope/ownership and operator confirmation as required by the project.

**Execution and closeout contract:**

3. Native `DISM /Mount-Wim`, `/Unmount-Wim` (commit or discard as explicitly decided), servicing, `reg.exe load/unload` of verified offline hive files, plus ancillary temporary host registry/file operations are normal. A temporary hive attached at `HKLM\<owned alias>` is host-visible but the modified payload belongs to the offline hive file, not the live OS configuration. The running OS's **production component/service/driver configuration** must not accidentally become the target of debloat. Host helper writes that affect its own files/settings should be recognized, reviewed for scope and reversal, not categorically prohibited.
4. Before processing, identify **offline target**, index and mount, source/derivative identity, expected effect, checkpoints and any host-side temporary write dependencies. Redirect logs/scratch to project paths when useful, but it is **optional**, not an isolation obligation. Capture necessary forensic output explicitly in `C:\work\logs`; system Windows logs need not be preserved.
5. At the start of each new session, independently verify current mount table, image ownership and identity, offline registry alias mappings and filesystem paths. **Never rely on yesterday's mount, registry state, Windows TEMP or system DISM logs**. Never treat a loaded hive or mounted image as implicitly owned based solely on a familiar alias/path.
6. When the operator announces shutdown: **pause further build steps**; close relevant Total Commander/Explorer handles; inspect DISM mounted-image table and project mount directories; identify and release every **project-owned** offline-hive alias with `reg unload`; commit/discard and unmount any owned WIM according to operator instruction; verify that no project mount or registry alias remains loaded and no known project transient operations are unfinished; record the final evidence in `C:\work\logs`. Do not unload someone else's hives or use sweeping DISM cleanup/deletes on unrelated resources.
7. **Cleanup and safety are separate concerns.** Host logs, TEMP files, native registry aliases, scratch folders and the like may be written freely within a controlled task and cleared later; the operator's nightly cleanup is not a substitute for correct target selection, restoring any host configuration that a task explicitly changed, or completing owned mount/unload transactions. Broad destructive paths (e.g. `robocopy /MIR`, deletion of system log directories, root-drive scratch, source-UUP moves) require actual target/ownership and effect checks before execution. No assumed ban; no unreviewed destructive impact on unrelated content.
8. **Preserve auditability:** operator executes every complete step locally; ChatGPT reviews provided evidence. Keep external source references, Library research and active GitHub project records available, and keep release/runtime certification separate from temporary-host-state housekeeping.

This section controls interpretations of "host isolation", "local writes", "offline target", and "persistent evidence" elsewhere in the strategy. VMBox remains a later phase.

---

## 6.2 OPERATOR REVIEW GATE FOR CANONICAL DEBLOAT MUTATION

Every command/sequence/script mutation intended for the canonical reusable debloat set **must be shown in full to the operator for review before its first execution** as a candidate production mutation. Material revisions require renewed review.

- Read-only discovery, inventories, health and evidence collection are supplied to the operator for local execution.
- The reviewed text must be the **actual complete mutation logic**; an opaque ZIP, SHA-256 checksum, static-anchor check or label of “certified” cannot replace source review.
- Review precedes local execution of a candidate production mutation.
- Operator review is additional to, not a substitute for, disposable testing, topology/dependency validation, pre/post-state certification and rollback.
- No phase number, previous static PASS, plugin availability or continuation of a past chat grants implicit execution authorization.

## 6.3 GERMANIUM 26100 / 26200 / 26300 AND LATER FAMILY UNIVERSAL IMPLEMENTATION RULE

Normative §0A applies to **all four production phases**, not only to one PowerShell wrapper. The production code accepts an operator-selected Germanium source, discovers actual target identity/version/edition/language/PFN/CBS ownership, selects an already-certified method and runs it; no source-code patch for every CU or 26100/26200/26300 revision.

- Keep source-specific values in declarative manifest/Component Intelligence, not proliferating release scripts named for a single build. Exact old build identifiers may appear in fixtures or proven exception records, never as a substitute for actual topology.
- The source UUP/converter, standalone offline PowerShell, NTLite XML preset and VM setup must be **separately reusable**, and together idempotent. An external tool's XML can cover only the operations that tool actually supports; use PS/DISM/CBS, official UUP options and NTLite according to their real semantics.
- Ordinary `UNCHANGED`/`VERSION_CHANGED`/`ALREADY_ABSENT` cases are automatic fast-path. Certified known alternatives use dynamic predicates. Unrecognized dependency/owner delta causes target-level hold and exception entry, not wholesale restart of forensic history.
- Full source review is mandatory for NEW or materially CHANGED canonical mutation code. A previously accepted, hashed release module may be executed on another compatible build without renewed source-text review, subject to automatic source integrity/current-image checks and operator-run authorization.
- Universal packaging is a **measurable deliverable**: named script/config/preset artifacts, a one-entry command, logs, minimal operator prompts, cross-build fixtures and runtime acceptance.
- All source and runtime gates remain in §6.1/§6.2, §8, §10 and §31; apply them risk-proportionately and automatically. Do not use universal as an excuse for undocumented raw carve, nor dependency review as an excuse for a month of serial research.

**Compatibility classification is topology-based, not hardcoded version-based.** When 26300 shares an identified recipe with 26100/26200, reuse it; when it differs, update Intelligence and validate only that changed recipe.


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

## 7.4 Verified UUP converter selection — preserve current staging/final distinction

Use the **actual pinned UUP converter implementation** and its supported configuration surfaces before touching UUP download queues. In tested uup-converter-wimlib, `ConvertConfig.ini` supports `CustomList=1` and a `CustomAppsList.txt` or `CustomAppsList2.txt` input; the selected converter code/manifest and resulting filtered reference closure are release inputs, not assumptions. Prefer supported `SkipApps`, `AppsLevel`, `CustomList`, `StubAppsFull` and update/cleanup switches where available and appropriate. Never blindly invent/remove a converter option because another release used it.

**BlueLite current known contract (not a claim for all future AppX revisions):**

- **UUP / pre-ISO STAGING — 5 required top-level identities:** `Microsoft.SecHealthUI`, `Microsoft.DesktopAppInstaller`, `Microsoft.WindowsCalculator`, `Microsoft.WindowsNotepad`, `Microsoft.Windows.Photos`. This staging contract is deliberate and must not be changed merely because the final App Installer is forbidden.
- **COMMON BASE / FINAL — 4 top-level keep apps:** SecHealthUI, Calculator, Notepad, Photos. Store, StorePurchaseApp, DesktopAppInstaller and Services.Store.Engagement are release-forbidden according to existing final policy. Retain framework/runtime dependencies resolved from installed manifests/owners.
- The exact selection may change only by recorded operator-approved policy revision. Runtime direct removal refusal does not license dropping an agreed staging dependency or silently changing the final keep set.
- Preserve UUP Windows/FoD/delta/reference reconstruction closure (already demonstrated by failed source pruning). Safe source minimization ≠ final OS removal; recover package size through **after-reconstruction** WIM debloat where necessary.
- Automatic audit prints selected/disabled/stub/aggregate payload inventory; compare with source-converter contract and fail only mismatching requirements, not unrelated UUP items.

## 7.5 Three configuration mechanisms — XML is important but not magic

1. **Converter-native INI/list/scripts**: `ConvertConfig.ini`, `CustomAppsList*.txt`, original UUP wrapper/CMD and app/download closure control. The original UUP launcher and frozen metadata are immutable; BlueLite supplies a reversible overlay and source-verified adapter.
2. **Microsoft deployment answer files**: `Unattend.xml` with `offlineServicing` can describe supported packages and required servicing order; `autounattend.xml`/`unattend.xml` for Windows Setup/OOBE/accounts/locale/partition options as appropriate. Only settings/packages supported by the applicable Windows component/pass are placed here. **Unattend.xml is not an undocumented universal CBS component remover, nor automatically a native uup-dump configuration.**
3. **NTLite XML presets + Windows post-setup scripts**: NTLite XML expresses reusable tool-side choices; `.ps1`/`.cmd` and `.reg` cover supported procedural/runtime work. Do not conflate an NTLite preset with an unattended Windows answer file or the converter's source list.

Keep these as versioned **separate templates** sharing one manifest/intelligence policy. Validate schemas and syntax, rendered per-build identities, actual apply logs and post-state. Choose the best native configuration surface first; use code only where configuration alone cannot express the proven operation.

## 7.6 Reusable release entrypoint — fast mode versus research mode

Production interface: one pinned `START.cmd`/`Build-BlueLite.ps1` that reads an operator-chosen source and product profile, then runs discovery → native UUP download/reconstruction → MAX_PRE → standalone offline residue → NTLite handoff/preset → VM/bootstrap validation → export/release, with explicit phase manifests. The same engine serves stand-alone and pre-ISO calls: no divergent “second debloat implementation”.

**FAST_RELEASE** (normal new CU): automatic reuse of validated rules with compact selective hashes, source identity, actual current target predicate, expected post-state and predetermined smoke/integration tests. No routine giant full-volume search, 740-item hardlink check, every-owner registry dump or monthly re-certification **unless a matching rule's own conditional gate requires it**.

**RESEARCH/FORENSIC** (new changed dependency): targeted deep package/owner/hardlink/CBS/component-store data; new disposable proof, observed-delta analysis and cross-build regression. Its tested result must be incorporated into production Intelligence so that it runs automatically next time.

A build report must state `FAST_PATH_REUSED`, `KNOWN_VARIANT_APPLIED`, `TARGET_BLOCKED_NEW_DEPENDENCY`, `NEEDS_NTLITE_HANDOFF`, `ALREADY_ABSENT` and `RELEASE_PASS` accurately. One unforeseen block does not require re-running independently finished stages. Resume is checkpoint-aware with source hashes and run IDs, never “start over” by default.

## 7.7 Idempotent handoff

If a target was already removed by the UUP pre-ISO engine, the later standalone offline orchestrator must detect the expected post-state and return `ALREADY_ABSENT` / `SKIP`, not fail or attempt a second removal.

---

## 7.8 CANONICAL MAX_PRE EXECUTION — ONE ENGINE / ONE PRE-ISO PATH

The **primary** BlueLite build route is: frozen operator-selected UUP source → reconstruction with the entire required delta/FoD/reference closure → immutable reconstructed WIM → disposable mutable WIM → dependency-aware **MAX_PRE GREEN and AMBER** post-reconstruction/pre-ISO removals → independent verification and atomic WIM promotion → final ISO assembly.

1. Only converter-supported source/AppX selection is permitted before reconstruction; do not prune reconstruction-critical Windows/FoD/delta downloads to mimic final-OS removals.
2. The immutable original reconstructed WIM is hashed and never mutated in place; modifications target an independently identified, hash-verified disposable copy. Mount/dispose/export/rollback is orchestrator-owned.
3. **Every already-certified** native GREEN/portable AMBER operation safe for the current frozen build belongs before ISO assembly, not a separate post-ISO debloat pipeline. Preserve explicit dependent ordering (e.g. OneDrive current neutral → WOW64 neutral → old staged neutral).
4. `START.cmd` and standalone offline orchestration must call the **same** versioned engine and Component Intelligence selectors; no duplicate divergent implementations.
5. Subsequent Phase E/F handlers execute only genuinely unprocessed residue or newly proven rules; completed pre-ISO work yields idempotent `ALREADY_ABSENT`, not a second removal.
6. Exact pre-state, dynamic owners, native transitions, expected satellites, physical post-state, retained service/VM/network floor, pending count, health and rollback must pass **before** commit/export/replace.
7. A static PASS never authorizes UUP download, converter execution or mutating WIM. Converter and MAX_PRE require separate runtime certification and explicit operator review/approval.
8. The operator may defer the next download or disposable test. No development milestone by itself overrides that instruction.

**Canonical operating invariant:** maximizing pre-ISO removal is an engine capability, not a justification for mutating an unproven CBS dependency graph.

# 8. DELTA-DRIVEN BUILD DISCOVERY — FAST PATH IS THE DEFAULT

## 8.1 Minimal release-time manifest, not a new forensic campaign

For a new operator-selected 26100/26200/26300 Germanium source, collect **only the data needed to resolve existing recipes**: UUP/source hash, resolved lineage, edition/language/architecture/index, update and pending state, AppX/PFN list, package/feature/capability state for configured targets, protected service/driver/network/VM floor, exact targets' dependency fingerprints, and compact component-store health. Reuse cached **verified unchanged** data where the artifact identity is identical. Log provenance of every reused datum.

Compare the manifest with certified recipe predicates, not merely with the last build number. Native target probes are exact; a full CBS/WinSxS/hardlink crawl is a **conditional deep audit**, not a mandatory new-CU tax.

## 8.2 Automatic classifications and decisions

| Classification | Production action | Required evidence |
|---|---|---|
| `ALREADY_ABSENT` / `UNCHANGED` | Skip or automatically use known rule | Current exact post/pre predicate, protected floor |
| `VERSION_CHANGED` | Resolve current exact instance; run the same recipe | Same semantic owner/servicing/dependency fingerprint, updated identity |
| `KNOWN_VARIANT` | Select pre-certified variant by topology predicate | Recorded alternate recipe and allowed post-delta |
| `PERMANENT` / `PROTECTED` | Use prior validated fallback/disposition if explicitly available; otherwise targeted block | Exact CBS/AppX refusal and protected dependency mapping |
| `UNKNOWN_TOPOLOGY` / `UNKNOWN_DEPENDENCY` | Quarantine ONLY affected target for forensic work | Small diff manifest; current source; no unintended mutation |
| `NEW_TARGET` | Automatic categorization, then only necessary targeted research | Exact new identity and preflight |

Final release gate remains absolute for declared mandatory removals and protected capabilities. Unrelated certified work need not be restarted after an isolated block. `FAIL_CLOSED` is a safety decision, not a demand for endless manual work.

## 8.3 Cross-build regression and quick release

The regression matrix must cover representative real builds **26100.x, 26200.x, 26300.x** (as image sources are available), including positive and deliberately negative fixtures. Regression code validates the engine, recipe variants and expected state. A new CU on unchanged topology runs **selective** current-image tests and an end-to-end acceptance suite; it does not redo full historical rule creation. Deep `ScanHealth`/new hardlink ownership proof is mandatory on newly researched high-impact topology, not automatically on every already-certified unchanged removal. Final release still needs its declared health/serviceability tests.

Generate machine-readable result per target: `source_identity`, `logical_id`, `resolved_exact_identity`, `topology_fingerprint`, `recipe_id/version`, `decision`, `post_state`, `expected_delta`, `observed_delta`, `protected_floor`, `time_ms`. A simple syntax/anchor PASS is never substituted for runtime behavior.

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

## 10.2 New AMBER rule — one-time variant certification, repeatable production use

**Research mode: only when no valid known recipe matches**

1. Read exact current target topology and prior historical proof, including failed methods, dependencies, hardlinks, registry/CBS owners and protected siblings.
2. Create an owned, hash-verified disposable WIM only when mutation/rollback testing actually requires it. Name and record its retained-use classification. Never touch immutable operator source.
3. Run the smallest preapproved metadata/native/physical operation with narrowly scoped backup/rollback and recorded exact identifiers. No wildcard expansion and no shared owner carve.
4. Verify exact post-state, allowed observed CBS delta, retained dependencies, component-store health, pending=0 and `ScanHealth` for a new/high-impact CBS/WinSxS rule; negative self-tests are required to catch wrong owner/parent and failed DISM exits.
5. Promote the successful variant into a data-driven, source-reviewed **universal engine recipe**; add machine-readable fixture(s), logical size/physical unique bytes and a state-transition contract. Do not publish an unproven carve as GREEN merely because directories disappeared.
6. Release hive/mount handles and preserve operator-valued disposable image. Delete only if confirmed no longer needed or bit-identically reproducible and approved; preserve forensic and release receipts.

**Fast production mode: on another compatible Germanium build**

7. Dynamically select and validate the recipe by exact current-image predicates/fingerprint, not fixed build number.
8. Execute the already reviewed recipe on the separately owned mutable candidate, check its expected post-state and run the predefined health/smoke gates. No full repeat of items 1–6 unless a predicate differs.
9. If the current build changes the owner/CBS/AppX graph, block this target; append a **new variant**, not a new set of one-off build scripts.
10. Promote only verified transaction results; retain immutable source, separately recorded checkpoints and source hashes.

This section supersedes earlier wording which made every AMBER recipe an automatic new full research cycle or unconditionally deleted every failed test WIM.

## 10.3 EVIDENCE LADDER — STATIC IS NOT RUNTIME

Every module, wrapper and complete release records the highest proven tier, with no implicit promotion:

1. `STATIC_VERIFIED`: script/package manifests (SHA-256), PowerShell AST, ordering, source anchors, integrity and read-only audit checks passed; no WIM execution implied.
2. `DISPOSABLE_RUNTIME_VERIFIED`: a clone of a frozen WIM underwent actual native execution and exact post-state/health/rollback verification; retain logs and before/after measured deltas.
3. `CURRENT_BUILD_CERTIFIED`: the exact currently selected source, dynamic topology and full pre-ISO workflow were executed and verified on the current build.
4. `RELEASE_CERTIFIED`: common base, component-engine work if needed, Defender branches, first boot/new account, CU/serviceability, final footprint and distribution hashes certified.

Two **independent** workflow gates are mandatory: `CONVERTER_RUNTIME_AUTHORIZED` and `PRE_ISO_MUTATION_RUNTIME_CERTIFIED`. Neither is set by a static AST/hash PASS in the other workstream.

**Historical tier note:** on 2026-10-12 MAX_PRE `v2.0-R15-R1` was only statically verified. This is NOT current operational status: on 2026-10-15 real R113 five-AppX provisioning completed and R115 actually invoked original R15, but ended fail-closed on `Language.Basic` permanent CBS refusal `0x800F0825`, with additional DesktopAppInstaller release-forbidden residue; R116 native DISM `0x80073CFA` confirmed policy refusal; R119 R113 readonly topology passed but hardlink closure was incomplete (702 closed, 38 errors). No promoted R15 production RELEASE resulted from these trials. The live `BlueLite_Current_Status.md` and operator logs, not this historical date snapshot, determine present state.

## 10.4 AMBER PRE/POST CBS OBSERVED-DELTA TRANSACTION

Extend the R10 prototype, R11 Search, R12 OneDrive, R13 FoDMetadata, R14 printing and R15 Recall/AIX gates to **every** AMBER target:

- freeze target-specific CBS owners/states/sibling/provider state *before the first mutation*;
- require exact expected count, owner values, `Visibility`, `CurrentState` and retained parent with no guesswork;
- export/backup the exact registry keys/hive and preserve a verified disposable WIM checkpoint;
- perform the smallest allow-listed metadata transition, unload hive before native DISM;
- allow only named native target and documented satellite side effects;
- verify target absence/non-resolving identity where applicable, physical payload/hardlinks, retained dependencies, pending=0, CheckHealth and ScanHealth;
- independently compare observed CBS delta against the preapproved expected map **before WIM commit/promotion**;
- fail closed and restore/discard on unexplained drift or unknown topology; no wildcard broadening.

The R10 implementation is the first working model of the data contract, not a claim that its static review has certified an entire cross-build graph.

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

# 12. HEALTH STANDARD — AUTOMATED, RISK-PROPORTIONAL CERTIFICATION

## 12.1 Routine current-build release gates

A production run checks actual source/lineage, installed package/AppX/feature post-state, protected dependency floor, zero unintended pending servicing, and `CheckHealth` at meaningful candidate/branch boundaries. Native DISM exit is interpreted together with actual post-state, never alone. Record output in machine-readable receipts.

## 12.2 `ScanHealth` / deep CBS proof

A full `ScanHealth` is required when a new **high-impact/AMBER/physical CBS** recipe is first certified, when an unknown owner graph/observed CBS delta is changed, after surprising corruption, and at defined final serviceability certification points. A matching known variant with a previously proven method may use its **predefined cheaper target-specific predicate checks during individual operations** and defer its full image scan to the normal release acceptance suite. **Do not make every minor, unchanged subtarget trigger an independent ScanHealth**; still never skip final required image-health evidence. First-time Sense-style carve remains rejected unless ScanHealth/CBS evidence is clean.

## 12.3 Pending and runtime serviceability

At formal certification points `Install Pending` / `Uninstall Pending` must be zero unless intentionally in a documented servicing transaction. Before release, require appropriate `CheckHealth/ScanHealth`, current-image target post-states, both Defender branch tests, a valid CU servicing path (using snapshot/rollback), no unexpected resurrection, networking and end-user VM-host capability according to §19.

## 12.4 Failure is targeted, evidence retained

Failed deep audit or unknown target does not automatically corrupt image or undo independent tasks; it blocks promotion of the candidate until required affected gates pass. Parser/report errors are tool defects, not evidence of WIM corruption. Logs and useful forensic copies persist according to §0A/§6.1A.

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

## 13.1 NEGATIVE FIXTURES / AUDITOR SELF-TEST / DUAL POWERSHELL HOSTS

A static package audit must verify **itself**, not merely engine string anchors. In addition to the positive case, inject deliberate failures: corrupted SHA, invalid AST, malformed or missing anchor, incorrect WIM/index/source, absent/duplicate candidate, extra or wrong-value owner, wrong `CurrentState`/`Visibility`, dropped protected parent, unexpected side effect, failed native exit and missing post-health or premature commit. Every negative fixture must return FAIL_CLOSED.

Specific MAX_PRE defects and durable fixes:

- R14: PowerShell interpolation `$logical:` is invalid in a double-quoted string; use `$($logical):` or `${logical}:`.
- R15: the auditor used double quotes around an expected `$PSScriptRoot` source literal and expanded its own path, causing a **false** missing-engine-contract failure. Use literal patterns (single quotes, or correctly escaped) and test auditor self-interpolation.
- R11/R12: implicit `$Matches` reuse after `-notmatch` is not reliable for authorizing owner registry edits; use explicit `[regex]::Match()` captures and typed owner data.

The operator normally uses **PowerShell 7 Admin**, while an upstream converter hook may invoke **Windows PowerShell 5.1** through `powershell.exe`. AST/static checks must test the syntax of all relevant `.ps1` files and record the host/engine contract; successful PS7 AST does not establish PS5.1 runtime behavior, or vice versa. Do not mistake parser/auditor failure for servicing damage.

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

**Differentiate STAGING, COMMON BASE and OPTIONAL PAYLOAD.** Staging has five required top-level AppX identities: `Microsoft.SecHealthUI`, `Microsoft.DesktopAppInstaller`, `Microsoft.WindowsCalculator`, `Microsoft.WindowsNotepad`, `Microsoft.Windows.Photos`. The desired common-base final keep set is **four** (all except DesktopAppInstaller); DesktopAppInstaller, Store, StorePurchaseApp and Services.Store.Engagement are release-forbidden as already specified by the current policy. Framework/runtime/VC dependencies are resolved automatically from actual manifests, not dropped by broad label.

Historical **11 September Batch 18C-D/E** and **14 September phases 44–48 on 26200.9445** are explicit prior successful method evidence for DesktopAppInstaller despite native DISM error `15610 / 0x80073CFA`: narrowly scoped AppX application/staging/config lifecycle deprovisioning and preserved native `Deprovisioned` marker, followed by guarded physical WindowsApps removal only after proving each package root's unique hardlink owner, while keeping shared AppInstallerPrompt/WinRT/OneCore/PolicyManager support. For 26200.9445 Phase 48 removed **740 files / 148,137,728 bytes** with post `CheckHealth=CLEAN` and no pending packages. **Those details are historical topology-specific data, not hardcoded universal file-count requirements.**

R119 26200.9711 read-only audit saw identical four roots and file/byte totals, but only **702 hardlink checks closed; 38 errors**. A production physical carve is **not authorized by counts alone**. Next improvement is a reusable owner-resolution method that handles WIM-mount reparse/hardlink reporting correctly and falls back to exact verified disallow/hold, not repeating another DISM refusal. This belongs in a universal AppX lifecycle recipe with topology predicates and new-variant regression. If an offline policy-based remove works for a certified target, it may replace lower-level handling; never assume an undocumented provider override.

Do not use broad `EndOfLife` / `Deleted-EndOfLife` changes, global AppX registry deletes, or `StateRepository` SQLite surgery as generic substitutes for real package lifecycle. Optional Microsoft Store/MSIX/winget installation packages, classic Photo Viewer tools and end-user conveniences belong in post-install optional payload; no active Store provisioning is required in the common base.

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

## 19.1 End-user VM-host capability — mandatory post-install contract

The **installed BlueLite OS must remain capable of hosting user-created virtual machines**, not merely booting as a guest during our VirtualBox QA phase. On compatible x64 hardware with firmware virtualization enabled, the user must be able to install a supported third-party hypervisor **after first boot** (at minimum VMware Workstation and Oracle VirtualBox), install its signed host drivers/services and required networking adapters, create virtual disks and guests, and start, run, stop and restart those guests. **No VM software is permanently preinstalled** in the common base.

Every virtualization debloat rule must preserve or permit normal installation of the required host interfaces and dependency providers: applicable VT-x/AMD-V and Windows hypervisor/WHP interfaces, kernel-mode driver installation and service registration, NAT/bridged/host-only virtual networking, virtual storage and host file I/O, and required Windows feature activation pathways. Preserve only dependencies proven necessary for this contract; do not retain the whole Hyper-V management stack by default. **Microsoft Hyper-V as an optional built-in hypervisor requires its own separately validated feature/edition contract; it is not implicitly guaranteed by third-party VM-host compatibility.**

A reduction that breaks subsequent supported-hypervisor installation or guest execution is **VM_HOST_DEPENDENCY_BLOCKED**, not an acceptable debloat result. Certification requires an actual post-install VM-host test on suitable physical hardware (or a demonstrably nested-virtualization-capable equivalent), for **both Defender ON and Defender OFF**, covering hypervisor installation, host driver/network setup, guest boot, disk I/O, network operation, clean shutdown and a repeat run after host reboot. A first-boot test of BlueLite **inside** a VM alone does not establish this host contract. Where physical test hardware is unavailable, mark the contract **NOT_YET_RUNTIME_CERTIFIED** and do not report VM-host support as proven.

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

## 21.1 FBCONAN REFERENCE FORENSICS: COMPRESSION, USERS AND SERVICING

FBConan / Windows X-Lite 25H2 Pro v2 (26200.7019) is a **reference end-state**, not automatic permission to reproduce a CBS carve on BlueLite.

**WIM / size:** the reference had a two-index Defender OFF/ON solid/recovery WIM of roughly 2.845 GB with extensive shared data, while logical per-index image size was about 17.17 GB. `SetupComplete.cmd` applied `compact /c /s /i /a /exe:XPRESS8K "%SystemDrive%\*"`; offline `CompactOS:Query` did not report CompactOS enabled. File-level NTFS compression, solid WIM and index sharing can reduce reported distribution/installed physical footprint **without** representing equivalent dependency payload removal. Independently benchmark each lever, and keep the serviceable development master separate from final transport compression.

**OOBE / users:** `Users\Default\NTUSER.DAT` seeded consumer-content/Spotlight/privacy first-run flags, but did not pre-capture an AppX repository for all future users. FBConan's local Admin RID 1000 was a **previously initialized captured profile** (e.g. `LogonCount=14`, `AppReadinessLogonComplete=1`, `PostAppInstallTasksCompleted=1`). `unattend.xml` provisioned a local Admin and bypassed parts of OOBE; the rapid bootstrap desktop (around 5–6 minutes as reported) is **not** proof of equal speed for a fresh profile. Measure bootstrap and genuinely new account first logon separately. Do not copy reference SAM/SID/ACL or assume an unsecured duplicate local account is a release pattern.

**WinSxS / metadata:** FBConan retained broad manifests, MUM/CAT and staged package metadata, but `WinSxS\Backup` and `WinSxS\Migration` were absent. Its DISM `CheckHealth` reported **repairable**, therefore it is not the reference for a clean serviceable BlueLite release. Physical carve and metadata carve are different classes and must not be conflated.

**Disk Cleanup ~190 MB:** the operator repeatedly saw roughly 190 MB left in *Windows Update Cleanup* across FBConan installations. An earlier BlueLite `WinSxS\Backup` inventory was ~192.604 MB, **but the FBConan Backup directory is absent**; they are not a proven match or even the same metric. Examine cleanup handlers and estimation, CBS metadata/history, packages, compaction and servicing floor as competing hypotheses. Never blindly remove files merely to force a cleanmgr indicator to zero.

**Experiment measurements:** distinguish (1) logical bytes, (2) hardlink-aware unique physical payload, (3) actual compressed NTFS allocated size, (4) WIM/ISO transport compressed bytes, (5) clean first-logon time. Hypothesis and observed result must be labeled separately. A `repairable` servicing graph is a research input, not a production PASS.

# 22. CANONICAL PRODUCTION PIPELINE — FOUR GERMANIUM-UNIVERSAL FACTORY STAGES

The prior A–N investigation checklist is **not** a set of separate new-CU operator tasks. It becomes internal jobs of the four prebuilt stages, driven by the same manifest, job state and source-hash ledger. Each job is resumable and idempotent; timestamps and run IDs are evidence, not reason to rerun an already verified parent step.

## STAGE 1 — SOURCE/UUP/RECONSTRUCTION + PRE-ISO MAX_PRE FACTORY

Input: selected/frozen operator-approved UUP source, edition/index, language/arch, supported converter binary/version, standardized policy/profile/config, release configuration.

1. Check source identity and cached downloads. Run source-native UUP download/conversion; preserve required Windows/FoD/delta/reference closure, apply supported source-side AppX selection and update options.
2. Reconstruct WIM; separate immutable source, owned working image and target ISO. Dynamic build/lineage fingerprint determines applicable rules.
3. Perform a small discovery manifest, auto-select known GREEN/AMBER recipes by current topology, apply maximum proven pre-ISO removals, record allow-listed deltas and pending/health receipts. Five staging apps / four final apps remain the current AppX contract.
4. Write intermediate working WIM/checkpoint and detailed stage manifest; assemble **candidate** ISO where appropriate. It is **not** yet the RELEASE until downstream NTLite/VM certification.
5. Record source hashes, downloads reuse, exact identities, removed/already-absent, known-variant, remaining targets, errors and measured efficiency.

**Deliverables:** `Stage1_ReconstructedSource.wim` (logical output, path chosen by run manifest), `Stage1_MAXPRE_Working.wim`, selectable candidate ISO, `Stage1_Receipt.json` and rollback/source metadata. Working artifacts are retained according to operator-managed lifetime; these filenames describe roles rather than mandatory duplicate 9GB files.

## STAGE 2 — STANDALONE OFFLINE POWERSHELL MAX-DEBLOAT

1. Read the Stage1 manifest and working WIM without new independent forensic copies unless needed for a risky new mutation.
2. Use **exact same** recipes/policy modules; skip already completed targets; finish proven offline removals and integration/configuration not executed pre-ISO; apply remaining component store cleanup rules only when permitted.
3. On changed target topology, automatically contain the block; process independently safe targets; research only the changed dependency and fold the result into global Intelligence.
4. Prove common-base post-state, no unexpected pending, critical serviceability, retained optional restore payload, protected networking/storage/VM-host floor, Store release forbidden and native OS app keep set.
5. Produce `Stage2_CommonBase.wim` or in-place approved candidate checkpoint, `Stage2_Receipt.json` and exact `NTLite_Handoff.json`.

**Do not open NTLite until the known scriptable queue is exhausted or every remaining target has a documented KEEP/HANDOFF/RED disposition**. A new investigatory target does not block processing all unrelated known rules. High-risk handoff remains explicit.

## STAGE 3 — NTLITE BUSINESS UNIVERSAL PRESET

1. Compare actual NTLite component names and remaining Stage2 handoff entries against the **versioned Germanium preset** and conditional Component Intelligence mapping.
2. Apply only approved handoff components/settings. Emit the exact preset used, NTLite version, source index, observed removals and changed dependencies. If no handoff exists, record `SKIPPED_NOT_NEEDED`.
3. Independently certify post-NTLite output using the shared post-state/servicing floor. A portable module later proven outside NTLite migrates to Stage1/2 instead of remaining duplicated.
4. Preserve common-base WIM, versioned XML preset and post-NTLite receipt.

## STAGE 4 — VM / FIRST-BOOT / ADMIN / TWEAKS / CAPTURE / RELEASE

1. Start from the Stage3-certified candidate; snapshot/rollback before runtime changes and updates. Use parameterized unattended/OOBE and bootstrap scripts for **local administrator account** and optional user onboarding, with a secure per-release credential/set-up policy (no published hardcoded passwords, copied SID/SAM or blind inherited captured accounts).
2. Apply only validated online-only tweaks/add-ons; keep a reversible log for every policy/service/user-profile change. Capture changes into a reproducible final image only after exact functional tests.
3. Verify both Defender ON and OFF variants: fresh-new-user first-logon, Calculator/Notepad/Photos/SecHealthUI function, networking, Update Resume/re-pause, optional installer paths, storage/security protected floor, serviceability/reboot, package resurrection, CU test in snapshot, proper profile states and VM host functionality on appropriate physical hardware.
4. Finalize capture/export/compression, image indexes, boot/setup architecture and distribution ISO; verify transport signatures/hashes and measure installed footprint after clean boot. Mark release only after the full matrix passes.
5. Produce `Stage4_VM_Receipt.json`, branch-specific test results, captured WIM/ISO SHA-256, efficiency/time ledger and `Release_Manifest.json`. If tests fail, return a targeted defect to its originating stage and keep the reusable pipeline intact.

**Stage sequencing:** Stage1 → Stage2 → Stage3 → Stage4. An interim pre-ISO ISO is a distribution/candidate artifact, not an excuse to stop offline work; final release ISO uses final certified/captured images. No automatic VM work before prior stages. All stages are genuinely **Germanium-universal**, not merely connected by a universal shell.

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

## 23.4 OPERATOR SOURCE REVIEW VS STATIC PACKAGE AUDIT

Before first production execution of a new/changed reusable mutation, show the operator the complete exact code (Section 6.2), its target/owner/expected post-state, rollback and all changed modules. SHA/AST/static PASS indicates file and parser consistency, **not** execution approval, success of native DISM, or confirmation of a future build. Read-only static audit does not mount, invoke DISM mutators, run the downloader/converter or alter the live host.

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

# 25. NTLITE BUSINESS — REPRODUCIBLE XML PRESETS, NOT AD-HOC CLICKING

NTLite Business is the operator's **only paid tool** and acts as a secondary offline component engine after reusable UUP/PowerShell processing. The accepted product is a **version-controlled, reusable XML preset family**, not a set of per-build screenshots or manual click lists. NTLite official documentation confirms presets contain saved choices in XML and can be loaded in GUI/command-line workflows: https://ntlite.com/docs/presets/ ; current command-line syntax must be checked against the operator-installed version using `ntlite.exe /?` and its official docs, never invented from another NTLite release.

**Preset architecture**:
- Common `Germanium_Base.xml` for logical cross-build rules and protected compatibility settings.
- Optional platform/edition/Defender variants, merged/selected by manifest and **actual NTLite-visible component identity**, not by hardcoded cumulative-update version.
- Machine-readable `NTLite_Handoff.json` generated by Stage2 specifies exactly which logical target remains, the mapped NTLite component identity, required dependencies and desired post-state.
- Before apply: static XML validation, source index/edition and NTLite version compatibility, preview of intended removals, no unplanned side effects, exact snapshot/rollback.
- After apply: actual exit/receipt, target-specific post-state and servicing revalidation. If preset-only action cannot be represented for that build, record a conditional handoff or target block, not guessed removal.

**No duplicate work:** component already absent in Stage1/2 must not be removed again in NTLite. No NTLite until Stage2 complete. Build-specific preset forks are exception records only when a proven schema/platform limitation requires them; no uncontrolled manual divergence. A reusable headless/hybrid GUI path is acceptable if NTLite version limitations demand it, but the steps and inputs remain explicit and automated wherever tool support permits.

NTLite Unattended setup can write Windows answer-file content, but the NTLite XML preset and Microsoft's `unattend.xml` have distinct roles; do not confuse them. Reference: https://ntlite.com/docs/unattended/ .

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

## 26.1 MEASURED DEBLOAT EFFICIENCY LEDGER

For each logical target/build, record baseline → expected → actual delta with units and artifact scope: logical WinSxS bytes; unique hardlink-aware NTFS payload; compressed allocated size on disk; WIM/export/final ISO bytes at the same compression settings; Defender ON/OFF index sharing; operation duration; health/pending; and the protected dependency/residue cost. Never add logical hardlinked aliases as reclaimed physical storage or treat solid compression as CBS removal.

Historical physical target deltas on 26200.9445 were approximately: OneDrive Setup **196.71 MiB**; Search srchadmin wrapper **0.244 MiB**; FoDMetadata core **0.562 MiB**; LPD+LPR **0.242 MiB**. These are **historical** measurements, not promised new-build WIM/ISO reductions. Favor large reproducible wins while preserving cheap smaller certified removals and avoiding endless small checks with no new runtime evidence.

# 27. VMBOX / VIRTUALBOX — UNIVERSAL ONLINE FINALIZATION AND ADMIN ACCOUNT

This is **fourth, final** production stage. It is **not** a repeat of earlier component removal and not an improvised GUI tweak session.

**Shared VM bootstrap contract**: a versioned PowerShell/cmd/reg package and parameterized Windows unattended first-boot/OOBE configuration, with protected user choice over local admin naming and credential creation (credentials never in a public repo or release logs). Profile-specific tweaks are declared in settings files and applied conditionally by edition/user/defender-state; use verified registry/service ownership and rollbacks. Default profile must preserve first-time OOBE user and app provisioning semantics; do not distribute a copied configured account's SID/SAM as universal admin creation. Captured existing-profile variants require separate approval and genuinely new-account regression.

**Repeatable VM testing**: golden clean VM snapshot; machine-readable boot/user/app/network/service/Update/CBS/CU tests; both Defender branches; first-install footprint; optional MSIX/Store install user workflows; reboots; shutdown; and hash-verified image capture. Actual end-user VMware Workstation/VirtualBox HOST ability must be checked on physical virtualization-capable hardware (both branches), because running BlueLite **as a guest** is not evidence of successful host use.

**Feedback path**: every online tweak that can be expressed reliably offline migrates back to Stage1/2; every VM-only procedure becomes a stable Stage4 script/answer-file recipe. New Germanium builds replay these tests and tweaks without repeating their design; changed dependencies lead only to targeted variant research.

**Target timing**: standard release runs this prebuilt QA suite once per new compatible build and publishes only on PASS; it is a fixed cost, not a month of ad-hoc tests.

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

# 29. A NEW GERMANIUM BUILD — MINIMAL-HUMAN FAST RELEASE RUNBOOK

### 29.1 Prepare once (engineering work, not repeated each CU)

Maintain versioned production engine modules, UUP converter overlay, XML/INI/JSON profiles, shared Component Intelligence and historical rule-success/failure index, cross-build fixtures, WIM artifact lineage map, install/Defender variants, NTLite XML preset, unattended/setup/admin scripts, VM/physical-host test harness and signing/hash/logging tools. Every confirmed research win is integrated into an automatic recipe, **not** archived only as another numbered script/log.

### 29.2 Each new available UUP source (normal production)

1. Operator selects source and desired profile; `START.cmd` freezes source hash/identity and reports anticipated capabilities.
2. Tool confirms Germanium lineage (including 26300), supported converter configuration, caches/downloads/reconstruction closure and applies source AppX policy, reconstructs and integrates updates.
3. Stage1 records tiny actual manifest, dynamically selects known rules and executes MAX_PRE automatically; no routine deep re-research.
4. Stage2 finishes only required offline residue, idempotent known recipes and common-base QA.
5. Stage3 applies the reusable NTLite XML preset to real handoff (or records skip).
6. Stage4 executes existing VM/admin/tweak/bootstrap and branch QA, capture/export and final release.
7. Report source/version, time elapsed, automated-rules reuse, exceptions, actual ISO/installed bytes, failure or PASS. Keep relevant intermediate/source images per retention policy.

**Expected operator involvement**: initial source and release profile; review of truly novel canonical mutation or exceptional changed dependency; approval of high-impact irreversible/capture/credential/release decisions. Routine per-target PowerShell cut-and-paste is a **development workflow only**.

### 29.3 Exception lane, not infinite loop

New target/failure → automatically collect focused state and retrieve prior matching cases → classify dependency owner/protection and expected release impact → create a bounded, targeted research issue and reusable variant recipe if needed → negative/positive regression → merge into production → resume from checkpoint. Existing unchanged rules must remain auto-reusable.

No universal system can guarantee a fixed ISO or instant release for every future OS revision. A truly new mandatory dependency may delay an individual release; it does **not** justify discarding automation and rebuilding the analysis from zero. Publishing under an unresolved mandatory release gate is forbidden. Maintain a release-candidate versus released distinction.

### 29.4 Acceptance benchmark

Record repeated end-to-end dry runs on at least one certified representative each from 26100, 26200 and 26300 (when sources and build conditions allow). Track median operator touches, automated rule coverage, unknown-dependency count, build wall time (separate network/download/CPU/VM portions), SHA reproducibility for identical inputs/toolchains and final serviceability. Target same-day/hours for **compatible known-topology** new sources once production artifacts exist; do not claim uploader competitors' private implementation or actual times without evidence.

# 30. CANONICAL DELIVERABLES — VERSIONED REAL FILES, NOT HUNDREDS OF DEVELOPMENT SCRIPTS

The repository must converge on a **small, runnable source-controlled production package**. This is a proposed logical layout (not a statement that all files already exist):

~~~text
BlueLite-Master_Germanium_Strategy_final.md
BlueLite_Current_Status.md
BlueLite_Sources.md
production/
  START.cmd                         # single operator entrypoint
  Build-BlueLite.ps1                # orchestrator
  Manifest.schema.json
  config/
    Germanium-Profile.json          # optional/keep/remove/branch policy
    ConvertConfig.overlay.ini       # converter-native options
    CustomAppsList.template.txt     # staging 5, build-resolved
    offlineServicing.template.xml    # supported servicing answer file
    autounattend.template.xml       # setup/OOBE/admin profile
  engine/
    Source-Resolve.psm1
    UUP-Adapter.psm1
    Image-Servicing.psm1
    AppX-Lifecycle.psm1
    CBS-ComponentOwner.psm1
    Dependency-Gates.psm1
    WIM-Transaction.psm1
    Release-Certification.psm1
  intelligence/
    Component_Intelligence.json
    Known_Rule_Success.json
    Known_Rule_Failures.json
    CrossBuild_Topology_Regression.json
  ntlite/
    Germanium_Base.xml
    Handoff-Mapping.json
  vm/
    Bootstrap.ps1
    Online-Tweaks.ps1
    Admin-Account-Setup.ps1
    VM-Tests.ps1
    Capture-And-Validate.ps1
  tests/
    positive/
    negative/
    cross-build/
  manifests/
    Recipe_Hash_Manifest.json
    Production_Execution_Manifest.schema.json
    Release_Manifest.schema.json
~~~ 

**Priority:** make existing R15/UUP-D6/R91–R119 logic and proven AMBER recipes into these **few actual reusable files**. Hash-controlled immutable historical scripts remain research sources; do not rename old source to “production” without factoring hardcoded paths, state and redundant gates. Each item is `PLANNED` until actual repo file and runnable tests exist. A document alone does not satisfy the Definition of Done.

Every actual release has its own local run receipts (source, exact image, engine/recipe hashes, target decisions, native provider exit, health, pending, NTLite preset, VM test, output and SHA), indexed from GitHub Current Status rather than pasted there in full. Historical Library evidence, FBConan and uploader Build Info remain in evidence catalog with a flag for `OBSERVED` versus `INFERRED` or `UNTESTED`.

## 30.1 MANDATORY SUCCESSOR WORKFLOW — GITHUB CURRENT STATUS

**Mandatory for every successor assistant/session** (operator-relay only):

1. **Before planning or proposing the next BlueLite command**, fetch `BlueLite_Current_Status.md` from the canonical GitHub repository `johnny-belgrade/windows`, branch `main`: `https://github.com/johnny-belgrade/windows/blob/main/BlueLite_Current_Status.md`. Also read the current Master Strategy and the latest relevant operator log/handoff. Do not assume the historical chat or Handoff_4's last snapshot is still current. **As part of the same required pre-command review, search the internal ChatGPT Library for relevant BlueLite source files, original operator evidence and prior analyses, and inspect material matches before repeating research or proposing mutations (see §4.1).**
2. Treat Master Strategy as **normative authority**, Current Status as the **latest operational checkpoint**, and exact current-image/operator evidence as the authority for whether a mutation is permitted. Any mismatch or stale status must be explicitly reconciled, not silently guessed.
3. **After every material operator-confirmed milestone**, update the same GitHub `BlueLite_Current_Status.md` in place. Material milestones include new static/negative-test results, disposable runtime certification, current-build certification, source freeze, new ZIP/script hashes, discovered `TOPOLOGY_CHANGED` blockers, approved pipeline or branch changes, NTLite/VM stage transitions and release decisions. Do not claim a PASS from a script merely delivered but not run.
4. At a chat-to-chat handoff, a significant workflow change, or the close of a productive work session, ensure the last confirmed milestone has been persisted in GitHub Current Status; preserve open blockers and **one next operator-approved action**. Do not schedule unattended work or mutate the user's Windows host.
5. GitHub update is a **concurrency-safe write**: read the latest file and blob SHA, merge only verified changes (retain unrelated newer records), update with the expected SHA, then independently fetch the committed file and confirm its content/commit. Use the GitHub connector's authorized write path. The presence of `push: true` alone does not prove write success.
6. If GitHub write fails (403, 409/conflict, disconnect, unavailable integration), **never state that the remote status was updated**. Preserve a clearly labeled local candidate and report the blocker; retry only with authorized access. Never paste personal access tokens into chat or source files.
7. The current status is a concise, timestamped **single source of operational truth**, not a replacement for evidence logs, Component Intelligence or release manifests. Never silently promote `STATIC_VERIFIED` to runtime certification. Update the Master Strategy only when a general project rule changes; do not rewrite it for ordinary task progress.

**This is an explicit standing instruction to future BlueLite ChatGPT successors**, not an optional suggestion. Publication of the status file on 2026-10-12 was confirmed by GitHub commit `3e820e30002629145f264eda7162c6d278f2d0c0`; the latest blob SHA is dynamic and must always be fetched afresh.

---

# 31. RELEASE GATES — FAIL CLOSED WITHOUT RESEARCH LOOPS

Every **final release** requires:

1. Frozen exact source and pinned converter/engine/config/preset versions; recognized Germanium lineage including 26300 support, edition/index, protected immutable original.
2. A complete Stage1→Stage4 receipt chain with target decisions. Previously known recipes dynamically reused; affected genuinely changed targets get explicit exception disposition, never fake green.
3. Required AppX contract: staging five, final four, release-forbidden Store family absent (or a new operator-approved policy replacing this rule); services/network/storage/VM-host protected floor, Windows Update Resume and long Pause requirement, optional user payload boundaries.
4. Offline and post-NTLite healthy CBS/serviceability state, no unexplained pending servicing, target-specific post-state and expected/observed change, `CheckHealth` and defined `ScanHealth` acceptance, no unexplained AMBER owner drift or mismatched source hash.
5. Both Defender branches and VM/admin account bootstrap, clean-new-user, functional app/network, rollback/reboot and CU checks on representative required setups. Guest-only VirtualBox QA does not establish installed BlueLite's ability to host VMware/VirtualBox on suitable hardware.
6. Final WIM/ISO artifacts SHA-256, measured compressed transport size versus logical/physical installed footprint, reproducible lineage and correct Defender branch labels.
7. Source-reviewed production mutation code and signed-off preset version; static and negative fixtures; no unauthorized on-the-fly change to a critical release target.

**Automatic outcome states**: `RELEASE_PASS`; `RELEASE_BLOCKED_TARGET_DEPENDENCY`; `RELEASE_BLOCKED_SERVICEABILITY`; `RELEASE_BLOCKED_RUNTIME`; `RELEASE_BLOCKED_SOURCE`. Scope each failure with exact owner and next action. A blocked release must not silently ship; however **do not restart source download, known-rule engineering or unrelated finished stages because one target changed**. Rebuild/resume only jobs whose input/dependency fingerprints became invalid.

The 3.5–5 GB ISO and 11–15 GB installed footprint are **measured engineering targets**, not permitted excuses to mutilate shared CBS ownership or misrepresent solid compression as removed Windows payload. If the build exceeds them, report exact dependency and size cost, alternative optionalization and why it remains.

# 32. MAIN RULE — BUILD FACTORY, NOT MONTH-LONG RESEARCH

**BlueLite is a Germanium compiler and repeatable release factory**. All four stages must produce real reusable software/configuration assets; one universal controller wrapping per-build manual debloat is insufficient.

~~~text
FROZEN SELECTED UUP (26100 / 26200 / 26300 / later verified Germanium)
    + pinned source/config/INTELLIGENCE and known successful/failing recipes
    |
    v
STAGE 1: UUP CONVERTER + PRE-ISO MAX_PRE
    supported AppX/INI + validated offlineServicing XML + universal PS
    |
    v
STAGE 2: STANDALONE POWERSHELL OFFLINE RESIDUE
    SAME RULES, dynamic targeting, idempotent and dependency-aware
    |
    v
STAGE 3: NTLITE BUSINESS
    versioned reusable XML preset applied ONLY to actual handoff
    |
    v
STAGE 4: VM / OOBE / ADMIN / ONLINE-ONLY TWEAKS / QA / CAPTURE
    universal bootstrap, Defender branches, CU tests, final ISO
    |
    v
RELEASE + MANIFEST + SHA + MEASURED ISO/INSTALLED FOOTPRINT
~~~

At each stage:
`KNOWN_VALID_RULE` → apply automatically → certify compactly → continue.
`KNOWN_VARIANT` → select recorded recipe by topology → continue.
`ALREADY_ABSENT` → skip idempotently.
`UNKNOWN_DEPENDENCY` → isolate the affected target → deep-diagnose **once** → turn outcome into a known rule; withhold release only when the unresolved dependency violates a mandatory gate.

> **Sredi jednom, zatim ponavljaj proizvodnju; za novi build istražuj samo stvarno nove zavisnosti.**

The success metric is not the count of scripts, phases or retrieved logs. It is how many **finished Germanium releases** can be produced from available verified UUP sources with **minimal operator intervention** and accurate serviceability/functional evidence.

# 33. CHANGE HISTORY AND AUTHORITY

**v3.0.0 — 2026-10-15, substantive strategy reset authorized by operator.** Source and servicing evidence from v2.x are preserved; the former labor-intensive per-build development framing is superseded. Four **independently universal** stages explicitly cover 26100, 26200 and **26300** Germanium family lineage. Repeatable **FAST_RELEASE** with recipe/Component Intelligence reuse becomes the default. A new CU is not another long research project. New owner/dependency variant alone enters a bounded forensic lane, then becomes a certified automatic rule. Five AppX staging/four final distinction is retained, with prior 18C/44–48 success as candidate evidence and R119 hardlink gap flagged. Distinguish UUP converter INI/lists, Microsoft servicing/setup XML and NTLite XML; none is a universal magic remove script. NTLite Business becomes actual versioned portable preset, Stage4 includes repeatable admin account/VM tweaks, and expected artifacts are named. Operator-managed disposable WIMs are retained if useful. Cross-build quick acceptance and machine-readable source/health/footprint/time gates replace repeated redundant exhaustive forensics.

**v2.5.3 — 2026-10-15, historical intermediate.** Clarified four-stage order but left contradictory demands for near-constant new-build research. Replaced by v3.0.0.

**v2.5.2 / v2.5 — 2026-10-12 to 13, retained technical evidence.** Reconstruction-safe UUP MAX_PRE, R10–R15 AMBER observed-delta, failure fixtures, Sense/OneDrive/FoDMetadata/Recall/AIX and user-controlled local writes, FBConan comparisons, distinction of logical bytes/compression/actual removal, immutable source and servicing floor.

**v2.4 and earlier — retained governance/evidence where technically valid.** Operator-relay-only Windows PS7 Admin execution in development, current project file authority, read-only initial audits, source REVIEW for new mutation, post-state not filename, NTLite and VM after offline work. Any old language that forces rewriting per-build production code, automatic disposal of useful WIMs, hardcoded 26200-only scope, or open-ended manual forensics is superseded by §0A, §8, §22 and §29.

### 33.1 Technical source register — verified scope, not inferred capability

- **Microsoft 26H2 enablement/servicing lineage:** https://support.microsoft.com/en-us/servicing/os/windows-11/2026/09/kb5121794-feature-update-to-windows-11-version-26h2 — 24H2/25H2/26H2 common servicing core. This confirms shared family relationship, **not** every package has the same ownership or that 26300 will always be bit-identical to 26100.
- **UUP converter official source/readme:** https://github.com/abbodi1406/BatUtil/blob/master/uup-converter-wimlib/convert-UUP.cmd ; https://github.com/abbodi1406/BatUtil/blob/master/uup-converter-wimlib/ReadMe.html — converter-specific `ConvertConfig.ini`, `SkipApps`, `AppsLevel`, `CustomList`, `StubAppsFull`, optional `CustomAppsList*.txt`. Always inspect pinned local converter fork/version.
- **UUP Dump custom app selection source:** https://git.uupdump.net/uup-dump/misc/src/commit/10915414f3d8103e43fbe1ea170f980a45048131/autodl_files/CustomAppsList.txt — illustrates select-app list and required `CustomList=1`; not a complete CBS removal mechanism.
- **Microsoft DISM offline packages and unattended answer file:** https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-or-remove-packages-offline-using-dism?view=windows-11 — supported `/Add-Package` / `/Remove-Package` / `/Apply-Unattend` offlineServicing; dependency ordering and exact package identity. Does **not** claim arbitrary permanent packages can be removed by XML.
- **NTLite official Presets and Unattended docs:** https://ntlite.com/docs/presets/ ; https://ntlite.com/docs/unattended/ — reusable NTLite XML presets, tool-controlled unattended setup and CLI reuse; verify applicable Business version.
- **Microsoft policy-based inbox app removal:** https://learn.microsoft.com/en-us/windows/configuration/policy-based-inbox-app-removal/policy-based-inbox-app-removal — edition/management restrictions (managed Enterprise/Education) and runtime provisioning timing, so **not a universal offline replacement** for supported AppX operations across all BlueLite editions.
- **Project authoritative sources:** https://github.com/johnny-belgrade/windows/blob/main/BlueLite_Sources.md ; historical Library reports, `FBConan-BUILD_INFO-v3.txt`, 18C–18E, Phase44, Phase46-HOTFIX2, Phase47, Phase48, R113/R115/R116/R118/R119. These are operator-supplied evidence; descriptions of another uploader's own private scripts, tooling and publishing speed are **unverified inference** unless independently demonstrated.

**Source precedence:** Current operator evidence for the exact source and target > official provider semantics > previously certified matching-topology BlueLite recipe > reliable third-party implementation > reference build end-state. A new external tip produces a candidate recipe, not an approved mutation.


---

**End of BlueLite v1.0 — MASTER GERMANIUM STRATEGY v3.0.0**
