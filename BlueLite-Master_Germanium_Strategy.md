# BlueLite v1.0 --- MASTER STRATEGY

## 1. DEFINICIJA PROJEKTA

BlueLite nije build-specifičan preset.

BlueLite je **automatizovan, build-independent Windows 11 Germanium
transformation pipeline** koji prihvata odgovarajući stock/custom-UUP
Germanium `install.wim` i pretvara ga u BlueLite po istim pravilima, bez
hardkodovanja konkretne 26200.x revizije.

Trenutni build služi kao razvojni i validacioni uzorak. Sledeći
Germanium build mora koristiti isti engine; menjaju se samo intelligence
pravila za komponente koje su se stvarno promenile.

Krajnji razvojni artefakt nije samo finalni image, već uređen,
verzionisan i tačno redosledno definisan skup offline production
skripti. Taj skup počinje odmah nakon završenog custom UUP
download/reconstruction procesa i dobijenog ISO/install.wim-a, izvršava
samo nekoliko neophodnih analiza za konkretan build, zatim primenjuje
sav unapred dogovoreni i dokazani maksimalni offline debloat i offline
integracije, i završava se tek na jasno definisanoj granici za NTLite.

NTLite faza sme da sadrži isključivo true residue: targete za koje je
prethodno dokazano da ih BlueLite offline scripted engine ne može
pouzdano, dependency-aware i build-independent rešiti. Nakon NTLite-a
sledi offline recertification, a tek zatim online VirtualBox faza za
dodatni debloat, integracije, finishing i validaciju koji objektivno
zahtevaju pokrenut Windows.

Cilj:

-   finalni ISO približno 4.5--5 GB;
-   installed footprint približno 13--15 GB pre specifičnih
    drajvera/programa;
-   maksimalan offline debloat;
-   maksimalno smanjenje WinSxS-a koje prođe naše dependency i servicing
    gate-ove;
-   reproducibilan rezultat;
-   Defender ON i Defender OFF finalne varijante;
-   svaki BlueLite build mora ostati sposoban da bude **VM host**:
    minimalni release contract je očuvana normalna host virtualizacija
    za VMware Workstation / VirtualBox-klasu proizvoda; uklanjanje
    Hyper-V/VMP i srodnog Microsoft virtualization payload-a dozvoljeno
    je samo dok ne narušava taj host-capability contract;
-   Windows Update pauziran do 31-Dec-2100, uz funkcionalan Resume i
    kasniji normalan Pause;
-   Microsoft Store ekosistem nije aktivno provisioned u common base-u;
-   korisnički opcioni sadržaj, instaleri, REG fajlovi i enable/disable
    alati ostavljaju se u BlueLite korisničkom paketu umesto da
    nepotrebno ostaju aktivni u image-u.

Ako konkretan Germanium build zbog novih obaveznih dependencies
objektivno ne može da dostigne ciljni footprint, mora se kvantifikovati
šta zauzima prostor i zašto.

## 2. OSNOVNO PRAVILO ARHITEKTURE

Pipeline ima dva trajno odvojena sloja.

### ENGINE

Build-independent kod za:

-   UUP staging;
-   mount/unmount/commit;
-   DISM;
-   AppX;
-   offline registry hive handling;
-   CBS inventory;
-   component/WinSxS discovery;
-   hardlink analizu;
-   logging;
-   validation;
-   cleanup;
-   WIM export;
-   ISO creation.

Engine ne sme znati konkretne verzije paketa ako to nije tehnički
neophodno.

Production manifestacija ENGINE sloja je mali skup canonical skripti sa
fiksnim redosledom izvršavanja, jasnim ulaznim/izlaznim gate-ovima,
logovima i hashovima. Novi Germanium build ne treba da zahteva ručno
ponovno izvođenje kompletne forenzike; engine izvodi samo discovery koji
je potreban da potvrdi da se poznata pravila i dependencies i dalje mogu
bezbedno primeniti.

### COMPONENT INTELLIGENCE

Machine-readable baza pravila koja zna:

-   logičko ime targeta;
-   aliases;
-   package/capability/feature/AppX identitete;
-   CBS package → deployment → component vezu;
-   dependencies i owners;
-   WinSxS/runtime projekcije;
-   removal klasu;
-   dozvoljeni removal metod;
-   očekivani post-state;
-   buildove na kojima je pravilo dokazano;
-   MSMG/NTLite/community mapping kada postoji;
-   servisni rizik i rollback uslove.

Novi Germanium build prvenstveno ažurira ovaj intelligence sloj, ne
kompletan engine.

Component Intelligence za svaki target mora čuvati i source/evidence
trag: relevantne Microsoft, GitHub/community, NTLite/MSMG i druge
reference koje su korišćene pri klasifikaciji, uključujući linkove iz
centralnog BlueLite_Sources.md kataloga kada su relevantni.

## 3. IZVORNI UUP SLOJ

Autoritet je **tačno onaj originalni UUP Dump archive koji korisnik
izabere**.

BlueLite:

-   ne bira sam „latest" build;
-   ne menja originalni `uup_download_windows.cmd`;
-   čita UUID/build iz originalnog izvora;
-   radi kao overlay/wrapper;
-   čuva originalni launcher/config/list fajlove pre izmene;
-   koristi kratak root bez razmaka;
-   vodi poseban `BlueLite_Logs`.

`CustomAppsList.txt` i `UUP_Timeline_CMD.txt` su trajni
intelligence/evidence izvori:

-   daju stvarna imena Apps/paketa;
-   pokazuju šta je UUP converter uključio;
-   pokazuju redosled UUP servicing operacija;
-   ne koriste se kao slepa removal lista.

### Pre-download

Agresivno se filtrira samo Apps queue.

Zadržani top-level inbox Apps common base-a:

-   Microsoft.SecHealthUI
-   Microsoft.WindowsCalculator
-   Microsoft.WindowsNotepad
-   Microsoft.Windows.Photos

Njihovi framework/runtime dependencies se ne hardkoduju. Resolver čita
stvarne manifeste i iterativno dodaje samo dependencies potrebne
zadržanim Apps.

### Windows UUP queue

Windows/reference/delta queue se **ne filtrira destruktivno pre
reconstruction-a**.

Download/reconstruction closure nije isto što i final-OS dependency.
Windows payload se prvo korektno rekonstruiše; servicing-aware debloat
počinje nad gotovim offline WIM-om.

Formalni početak BlueLite offline production seta je trenutak kada je
custom UUP download/reconstruction završen i ciljnom ISO/install.wim-u
više nije potrebna UUP reconstruction obrada. Od tog trenutka normalan
build prelazi u canonical offline skripte; ad-hoc ručna analiza nije
normalan deo release workflow-a osim kada delta discovery označi NEW ili
TOPOLOGY-CHANGED target.

## 4. BUILD DISCOVERY I DELTA ANALIZA

Svaki novi build prvo prolazi kroz read-only discovery.

Discovery mora biti minimalan i svrhovit. Normalan sledeći Germanium
build ne ponavlja sve razvojne analize od nule, već izvodi samo one
provere koje su neophodne da potvrde source/build/edition/index,
health/pending stanje, verzije/identitete targeta i promene
dependency/owner topologije koje utiču na postojeća production pravila.

Pipeline automatski evidentira:

-   image build/edition/index;
-   packages i states;
-   capabilities;
-   features;
-   provisioned AppX/MSIX;
-   services/drivers;
-   component-store stanje;
-   relevantne offline SOFTWARE/SYSTEM/COMPONENTS hive podatke;
-   ciljane WinSxS component families;
-   hardlink/projection stanje za poznate AMBER targete.

Zatim se novi manifest poredi sa poslednjim sertifikovanim BlueLite
Germanium manifestom.

Rezultat je:

-   UNCHANGED --- koristi postojeće dokazano pravilo;
-   VERSION-CHANGED --- resolver pronalazi novu verziju istog targeta;
-   TOPOLOGY-CHANGED --- automatska mutation se blokira i target ide na
    analizu;
-   NEW --- novi target/intelligence kandidat;
-   ABSENT --- idempotentni SKIP.

Nikakav broad version-pattern removal tipa „obriši sve 26100.xxxx" nije
dozvoljen.

Ako je target UNCHANGED ili samo VERSION-CHANGED uz isti dokazani
dependency graph, pipeline treba da ga resolve-uje i obradi automatski.
Duboka forenzika se aktivira samo za NEW, TOPOLOGY-CHANGED ili drugi
fail-closed slučaj koji može promeniti bezbednost mutation-a.

## 5. REMOVAL KLASE

### GREEN

Microsoft-supported ili potpuno dokazani standardni mehanizam:

-   DISM package removal;
-   capability removal;
-   feature disable/remove payload;
-   provisioned AppX removal;
-   dokumentovane offline registry/service/policy izmene.

GREEN se automatizuje odmah, uz post-state proveru.

DISM exit code sam po sebi nije dokaz uspeha. **Stvarni post-state je
autoritet.**

### AMBER

Target nema čist standardni removal put, ali imamo dovoljno podataka da
možemo napraviti dependency-aware engine.

Pre automatizacije AMBER target mora imati:

-   stabilan discovery selector bez hardkodovane build verzije;
-   package/deployment/component mapu;
-   dependency/owner mapu;
-   fizički payload i hardlink mapu;
-   jasno definisan retained dependency floor;
-   precondition gate;
-   precizan mutation scope;
-   precizan očekivani post-state;
-   rollback/checkpoint;
-   idempotency test;
-   `CheckHealth``=CLEAN`;
-   pending packages = 0;
-   test na disposable kopiji.

Kada AMBER procedura prođe ove uslove, ona više nije „ručni eksperiment"
--- postaje **portable BlueLite production engine**.

To je model već dokazan za Recall/AIX i AppX/framework workflow.

### RED

Nedovoljno dokazan target:

-   raw WinSxS deletion;
-   broad COMPONENTS manipulation;
-   StateRepository SQLite surgery;
-   brisanje aktivnog shared framework/runtime payload-a;
-   nepoznati owners/dependencies;
-   zahvat koji ostavlja CBS metadata i payload u kontradiktornom
    stanju.

RED nije automatski „NTLite target".

RED znači: **ne dirati dok se dependency ne razume**.

Može kasnije:

-   postati AMBER/portable script;
-   biti bezbedno rešen NTLite-om;
-   ostati netaknut.

## 6. COMPONENT REMOVAL INTELLIGENCE MAP

Centralni istraživački dokument/baza projekta mora mapirati najmanje:

`BlueLite`` target` → `Windows logical component` →
`AppX``/Capability/Feature/CBS identity` → `CBS deployment` →
`CBS component family` → `physical payload` → `runtime ``hardlinks` →
`dependencies/owners` → `MSMG ``naziv` → `NTLite`` ``naziv` →
`FBConan``/reference ``stanje` → `removal class` → `validated method` →
`validated builds` → `serviceability result`

Prioritetne porodice:

-   Windows App Runtime / WinAppSDK;
-   UI.Xaml/VCLibs/frameworks;
-   Store/AppInstaller infrastruktura;
-   Recall/AIX;
-   CoreAI;
-   AOT/UserExperience;
-   AIFabric;
-   Sense;
-   Defender;
-   Search/Indexing;
-   Windows Update ecosystem;
-   Edge/WebView/Widgets;
-   networking/FOD/legacy tooling;
-   ostali veliki Client-Desktop-Required / Client-Features umbrella
    targets.

FBConan i drugi custom buildovi služe kao **forenzički oracle krajnjeg
stanja**, nikada kao dovoljan dokaz da treba kopirati isti carve.

Za svaki važan target Intelligence Map treba, gde postoji, da sadrži
direktne source/evidence reference: BlueLite_Sources.md stavku,
Microsoft dokumentaciju, relevantni repository/commit/script,
NTLite/MSMG mapping i naše lokalne dokazne logove. Time se sledeći build
ne oslanja na memoriju razgovora ili na jednu alatku.

## 7. OFFLINE PRODUCTION PIPELINE

Normalan build mora teći ovim redom.

Ovaj redosled mora biti implementiran kao canonical offline production
set koji se pokreće od post-UUP image-a do pre-NTLite granice.
Development/forensic skripte ne ulaze u taj normalni set osim kada su
unapređene u dokazano production pravilo.

Cilj ove faze nije samo removal. Pre NTLite-a moraju biti završene i sve
dogovorene offline integracije, policy/service izmene, optional payload
priprema i druge operacije koje je moguće pouzdano izvršiti nad offline
image-om.

### PHASE A --- UUP / PRE-DEBLOAT

1.  Original UUP archive validation.
2.  App queue dependency filtering.
3.  Potpuno Windows UUP reconstruction closure.
4.  Update integration i normalan UUP cleanup.
5.  Rekonstrukcija Professional `install.wim`.
6.  Supported pre-debloat nad reconstructed WIM-om.
7.  Initial health gate.

### PHASE B --- PREFLIGHT / BASELINE

Read-only:

-   source/mount verification;
-   edition/build/index;
-   `CheckHealth`;
-   pending package gate;
-   inventory;
-   hive accessibility;
-   machine-readable baseline.

Fail-closed pre bilo kakve mutation.

### PHASE C --- GREEN REMOVAL

Automatizovati sve što Microsoft servicing/AppX mehanizmi mogu regularno
ukloniti:

-   Apps;
-   capabilities/FOD;
-   optional features;
-   validne standalone packages;
-   legacy tooling;
-   nepotrebne language/speech/OCR/handwriting payload-e prema ciljnom
    profilu.

Ne pokušavati nepostojeći target.\
Ne koristiti broad parent-package force removal.

### PHASE D --- COMMON BASE SERVICES / POLICIES

Common base ostaje Defender-ON.

Trenutni dokazani floor uključuje:

-   telemetry/diagnostic/search nepotrebne servise disabled;
-   WSearch disabled;
-   SysMain disabled;
-   WU servicing core sačuvan;
-   WU UX timestamps do `2100-12-31T23:59:59Z`;
-   native 35-day pause logika sačuvana;
-   Recall/AI policies neutralisane;
-   Defender OFF nije primenjen.

Windows Update engine se ne amputira iz common base-a jer BlueLite
zahteva funkcionalan Resume/Pause i CU serviceability.

### PHASE E --- PORTABLE AMBER ENGINES / OFFLINE INTEGRATIONS

Pokrenuti sve već sertifikovane portable production engines.

Svaki novi dokazani target dodaje se ovoj fazi.

AMBER research se nastavlja dok postoji realan kandidat koji možemo
bezbedno pretvoriti u build-independent offline proceduru.

**NTLite se ne otvara samo zato što je trenutna lista AMBER motora
završena.**

Pre završetka Phase E mora se obraditi Intelligence queue za sve realne
preostale offline kandidate. Svaki kandidat mora završiti kao production
rule, potvrđeni SKIP, explicit component-engine/NTLite handoff ili RED
sa jasnim razlogom. Dok postoji realna mogućnost da target postane
pouzdana build-independent offline procedura, istraživanje nije
završeno.

### PHASE F --- COMMON BASE CERTIFICATION

Posle svakog značajnog mutation layer-a, a obavezno pre sekundarnog
engine-a:

-   `CheckHealth``=CLEAN`;
-   pending packages = 0;
-   retained Apps/frameworks present;
-   removed targets stvarno odsutni;
-   deprovision-only targets u očekivanom stanju;
-   service/policy assertions;
-   component-store report;
-   Defender ON baseline intact;
-   no unexpected mutation.

Certification skripta ništa ne menja.

Phase F je formalna granica sopstvenog BlueLite offline scripted
engine-a. Tek image koji je ovde certified može preći na secondary
component engine, i tada samo sa unapred definisanim handoff targetima.
Ako nema true residue targeta, NTLite faza može biti prazna/preskočena.

## 8. PRAVILO ZA SVAKU MUTATION SKRIPTU

Svaka production skripta mora biti transakciona:

1.  Verify source/build/mount.
2.  Verify prerequisites.
3.  Resolve targets dinamički.
4.  Audit/dry-run mode po defaultu gde je moguće.
5.  Explicit `-Apply` za destruktivni AMBER zahvat.
6.  Mutate samo allow-listed target.
7.  Verify stvarni post-state.
8.  `CheckHealth`.
9.  Pending-state check.
10. Idempotency rerun.
11. Log rezultat.
12. Hash canonical script-a.

Skripta mora:

-   biti fail-closed;
-   preskočiti target koji je već u pravilnom post-state-u;
-   nikada ne širiti target wildcardom bez dokaza;
-   nikada ne koristiti live host OS kao target;
-   uvek jasno odvojiti audit od mutation-a.

## 9. SERVICING / WINSXS POLITIKA

WinSxS nije folder koji se „čisti" prostim filesystem delete-om.

Redosled autoriteta: 1. native servicing; 2. dokazani package/component
removal; 3. naš dependency-aware AMBER engine; 4. NTLite/component
engine; 5. raw carve samo ako je potpuno dokazano --- praktično RED
research territory.

`COMPONENTS`, MUM/CAT/manifests i WinSxS payload moraju se posmatrati
kao jedan servicing graph.

Single-link WinSxS fajl nije dovoljan razlog za deletion.

`UnstagedFiles`, `f!`, `c!`, hardlinks i package state su intelligence
signali, ne samostalna dozvola za brisanje.

Component-store cleanup se ne radi usred forenzike.

Finalni cleanup ide tek kada su mutation slojevi završeni i image ponovo
sertifikovan:

-   AnalyzeComponentStore;
-   StartComponentCleanup;
-   opcioni ResetBase kada release policy prihvati njegove posledice;
-   ponovno health/pending testiranje;
-   export u novi WIM.

## 10. NTLITE BUSINESS ver. 2025.8.10552

NTLite je **sekundarni dependency-aware component engine**, ne zamena za
analizu i ne autoritet nad našom bazom.

NTLite nije opšti drugi prolaz za debloat. Njegov ulaz je eksplicitna
handoff lista iz Component Intelligence baze, sastavljena samo od
targeta za koje su GREEN i realni portable-AMBER/offline scripted putevi
iscrpljeni ili dokazano neprikladni.

Pre NTLite-a:

-   iscrpeti GREEN;
-   iscrpeti postojeće portable AMBER engines;
-   završiti analizu realnih kandidata za nove portable engines;
-   common base mora biti certified;
-   napraviti rollback checkpoint.

Lokalna NTLite verzija se uvek evidentira.

Koristiti samo targete koje:

-   nisu već rešeni u canonical offline production setu;
-   imaju dokumentovan razlog zašto ostaju true residue;
-   lokalna verzija NTLite-a stvarno prepoznaje;
-   naša Intelligence Map potvrđuje;
-   možemo post-testirati.

NTLite se posebno koristi tamo gde component-level dependency database
daje bezbedniji rezultat od našeg ručnog CBS carve-a.

NTLite ne sme da postane razlog za prerano odustajanje od
automatizacije. Ako se određena NTLite operacija može pouzdano
reprodukovati našim build-independent engine-om, kandidat je za buduću
migraciju iz NTLite faze u offline scripted fazu.

Posle NTLite-a obavezna je kompletna common-base recertifikacija.

U NTLite-u se ne ponavlja posao koji naše skripte već rade i ne
uključuju se dodatne komponente „usput". Svaki NTLite
removal/integration target mora biti unapred poznat, mapiran i
post-testabilan. Ako se NTLite operacija kasnije može pouzdano
reprodukovati offline, ona se migrira nazad u BlueLite scripted engine i
uklanja iz trajnog NTLite handoff-a.

## 11. DEFENDER BRANCHING

Jedan common base se održava kao Defender-ON referenca.

Tek nakon završetka svih common-base removal faza i njihove
certifikacije pravi se split:

### Defender ON

Nema dodatne Defender-disable mutation logike.

### Defender OFF

Posebna branch-only skripta sa eksplicitnim allow-listom.

Trenutni runtime targets:

-   MDCoreSvc
-   WinDefend
-   WdNisSvc
-   WdNisDrv
-   WdBoot
-   WdFilter
-   Sense

Ne koristiti wildcard `Wd*`.

SecurityHealthService, wscsvc i SecHealthUI nisu automatski deo Defender
engine-disable grupe.

Fizički Defender/Sense CBS/WinSxS payload se uklanja samo ako zasebna
component-removal analiza to dokaže.

Nikada ne primenjivati Defender OFF skriptu nad jedinom common-base
kopijom.

## 12. PACKAGING

Tokom razvoja canonical master ostaje servisabilni WIM.

Tek po završetku: 1. cleanup; 2. commit; 3. export u čist WIM; 4. hash;
5. branch export; 6. ISO assembly.

Za distribuciju se može napraviti dodatni kompresovani derivat.

LZMS/solid nije razvojni master. To je finalni transport/size
optimization sloj jer daje bolju kompresiju, ali je sporiji, traži više
memorije i ima lošiji random access.

Originalni servicing master i finalni distributivni artifact moraju
imati odvojene hashove i evidenciju.

## 13. VMBOX / VIRTUALBOX FINALNA FAZA

VMBox dolazi tek kada su offline mogućnosti završene.

To znači: završene canonical offline skripte, obrađen true-residue
NTLite handoff i izvršena post-NTLite recertifikacija. Tek tada je
dozvoljena online faza.

VM nije mesto gde se „ručno popravlja" ono što pipeline nije rešio.

### VM-HOST COMPATIBILITY RELEASE CONTRACT

Svaki BlueLite build mora ostati upotrebljiv kao **host za virtuelne
mašine**. Minimalni obavezni release contract je očuvana normalna host
virtualizacija za VMware Workstation / VirtualBox-klasu proizvoda.

Zbog toga se prilikom offline debloat-a virtualization/HV/VMBus,
network/storage i srodni slojevi ne ocenjuju samo po trenutnom
Windows-feature stanju. Svaki kandidat za removal mora proći poseban
dependency/protected-set gate koji potvrđuje da host capability nije
narušen.

Microsoft Hyper-V/VMP/WHP payload sme biti uklonjen ili redukovan kada
nije potreban za ovaj obavezni host contract. Hyper-V/NanaBox host
capability nije sama po sebi obavezna ako bi zahtevala čuvanje dodatnog
Microsoft virtualization payload-a koji BlueLite inače može bezbedno da
ukloni.

### VIRTUALBOX I NANABOX POLITIKA

**VirtualBox ostaje primarna VM platforma** za BlueLite online
finishing i release validation. Razlozi su zreo snapshot/rollback
workflow, lako grananje testnih stanja i činjenica da predstavlja
nezavisan, non-Hyper-V primarni validation path.

**NanaBox se koristi samo kao sekundarni, opcioni validation backend**
kada želimo dodatnu proveru preko Microsoft HCS/Hyper-V/VMP puta,
posebno za VMBus/synthetic-device, Secure Boot/TPM i druge Microsoft
virtualization dependency površine.

NanaBox nikada ne sme postati razlog da BlueLite trajno zadrži komponentu
koju bismo inače bezbedno uklonili. Drugim rečima, test alat ne definiše
debloat floor. Ako NanaBox za rad zahteva dodatni Hyper-V/VMP payload,
to se tretira kao zahtev sekundarnog testa, ne kao automatski BlueLite
release dependency.

Kada je praktično, isti finalni ISO treba validirati prvo u VirtualBox-u,
a zatim opciono u NanaBox-u. Ta dva testa se smatraju komplementarnim,
jer proveravaju različite virtualization dependency površine.

Primarne funkcije VM-a:

-   dodatni online debloat koji objektivno zahteva pokrenut Windows;
-   online integracije i finishing operacije koje nije moguće pouzdano
    izvršiti offline;
-   first-boot validation;
-   OOBE/local-account validation;
-   potpuno nov user profil;
-   retained Apps/runtime test;
-   reboot/shutdown ciklusi;
-   Event/CBS sanity;
-   component-store health;
-   Windows Update Resume/Pause test;
-   Defender ON test;
-   Defender OFF test;
-   instalacija sledećeg odgovarajućeg Germanium cumulative update-a;
-   provera da uklonjene komponente nisu neočekivano vraćene;
-   footprint merenje.

Koristiti snapshot pre CU testa.

Ako je za finalni release neophodan VM-only finishing/captured-user
sloj, koristiti Audit Mode/Sysprep i dokumentovan capture workflow. Sve
što se pokaže reproducibilnim offline kasnije treba vratiti iz VM faze u
automatizovani offline pipeline.

VM nije trajno skladište ručnih trikova. Svaka online
debloat/integration operacija mora biti dokumentovana, a ako naknadna
analiza pokaže da je reproduktivna i dependency-aware offline, u
sledećoj reviziji se prebacuje u canonical offline script set.

Release ne postoji dok oba Defender branch-a ne prođu VM validaciju.

## 14. OPTIONAL USER PAYLOAD

Sve što ne mora trajno da bude deo aktivnog OS-a ostavlja se korisniku
kao odvojeni BlueLite paket/folder:

-   Store reinstall;
-   optional Apps;
-   enable/disable REG fajlovi;
-   feature installers;
-   scripts/toggles;
-   troubleshooting/recovery alati.

Ovo smanjuje common image i sprečava da opcionalni dependencies postanu
permanentni OS dependencies.

## 15. NOVI GERMANIUM BUILD --- AUTOMATSKI WORKFLOW

Za svaki novi 26200.x / Germanium build:

Normalan release workflow mora zahtevati minimalnu ručnu intervenciju:
custom UUP daje polazni image, canonical skripte rade samo neophodnu
discovery/delta proveru i zatim izvršavaju sav već dogovoreni maksimalni
offline debloat i integracije u tačno definisanom redosledu.

1.  Korisnik bira originalni UUP source.
2.  BlueLite UUP overlay rekonstruiše image.
3.  Završeni custom UUP ISO/install.wim postaje ulaz u canonical offline
    production script set.
4.  Pipeline izvodi samo neophodne preflight/delta analize za potvrdu
    postojećih pravila i detekciju stvarno promenjene topologije.
5.  Pipeline generiše baseline manifest.
6.  Manifest se diff-uje sa prethodnim certified buildom.
7.  Poznati GREEN/AMBER targeti se resolve-uju dinamički.
8.  Promenjeni/novi dependency topology targeti se automatski SKIP-uju i
    šalju u Intelligence queue.
9.  Dok se Intelligence queue ne obradi, ne radi se opasan carve.
10. Nova dokazana procedura ulazi u Component Intelligence bazu.
11. Kada je moguće, dobija portable production engine.
12. Ceo common-base pipeline se izvršava i certifikuje.
13. Tek preostali targeti idu sekundarnom component engine-u/NTLite-u.
14. NTLite obrađuje isključivo eksplicitni true-residue handoff; sve što
    je rešivo canonical skriptama mora biti završeno pre toga.
15. Common base se ponovo certifikuje.
16. Defender branch split.
17. Cleanup/export/ISO.
18. VM validation.
19. Online-only debloat/integration/finalization u VM-u, samo za
    operacije koje nisu pouzdano izvodljive offline.
20. CU/serviceability validation.
21. Build dobija status BlueLite RELEASE samo kada svi obavezni gate-ovi
    prođu.

Na taj način novi build ne zahteva novu BlueLite skriptu od nule.

## 16. SOURCE / EVIDENCE HIJERARHIJA

Prilikom donošenja odluke koristiti sledeći red prioriteta:

### OBAVEZNA SOURCE POLITIKA

Korišćenje izvora nije opciona pomoć nego obavezni deo rada kroz ceo
projekat: od custom UUP skripti, preko offline
discovery/removal/integration faza i NTLite handoff-a, do VirtualBox
finishing-a i serviceability validacije.

Centralni katalog je GitHub repository johnny-belgrade/windows, fajl
BlueLite_Sources.md:

https://github.com/johnny-belgrade/windows/blob/main/BlueLite_Sources.md

Za svaki relevantan target ili fazu ChatGPT mora aktivno koristiti
odgovarajuće linkove, baze, repozitorijume, dokumentaciju i reference iz
BlueLite_Sources.md, zajedno sa svim drugim relevantnim izvorima i
bazama znanja kojima ima pristup. Ne sme se osloniti samo na prethodnu
konverzaciju, sopstvenu memoriju, jedan alat ili jednu community bazu.

Ovi izvori se koriste za pronalaženje targeta, aliases/component
identiteta, dependency/owner veza, poznatih servicing posledica, removal
pristupa, cross-build promena i boljih build-independent metoda. Kada
postoji relevantan repository, script, manifest, issue, dokumentacija
ili component database, treba ga proveriti pre zaključka da je neki
offline put iscrpljen.

Spoljni izvor nikada sam ne autorizuje mutation. Konačni tehnički
autoritet ostaje stvarno stanje trenutnog image-a, naši dependency/owner
dokazi i post-state/serviceability gate-ovi.

### SOURCE / EVIDENCE HIJERARHIJA

1.  Stvarno stanje trenutnog stock/BlueLite image-a.
2.  Microsoft servicing dokumentacija i native tool behavior.
3.  Naši prethodno sertifikovani cross-build rezultati.
4.  NTLite/MSMG/W10UI/wimlib/CBS reverse-engineering izvori.
5.  Community scripts i registry research.
6.  FBConan i drugi custom builds kao forenzički oracle.

Ni jedan community izvor ili tuđi custom build sam za sebe nije dovoljan
da autorizuje mutation.

FBConan i drugi provereni custom buildovi služe kao dokaz da je određeni
krajnji footprint ili component state možda ostvariv; BlueLite zatim
mora utvrditi dependency-aware i servicing-aware put do tog stanja.

I kada već imamo radno rešenje, izvori se ponovo konsultuju ako mogu da
otkriju čistiji, bezbedniji ili više build-independent metod. Cilj
source research-a nije samo trenutni build, već smanjenje ručne analize
na svakom sledećem Germanium buildu.

## 17. RAZVOJNI I RELEASE ARTEFAKTI

Razdvojiti:

### FORENSIC / DEVELOPMENT

Skripte za:

-   discovery;
-   dependency research;
-   component mapping;
-   binary/string analysis;
-   comparison sa reference buildovima.

Ne izvršavaju se u normalnom BlueLite build-u.

### PRODUCTION

Mali broj canonical, versioned, hashed i idempotent skripti.

Te production skripte moraju zajedno činiti kompletan, dokumentovan i
pravilno poređan post-UUP → pre-NTLite workflow. Potreban je jasan
execution manifest/redosled tako da sledeći Germanium build može da se
obradi bez rekonstrukcije procedure iz chat istorije.

Production set mora sadržati samo neophodni discovery/preflight,
dokazani GREEN/AMBER removal, offline integrations, certification i
handoff metadata. Forensic skripte ostaju van normalnog release toka.

Development analiza mora na kraju rezultirati jednim od:

-   novim production pravilom;
-   potvrđenim SKIP pravilom;
-   NTLite/component handoff pravilom;
-   RED klasifikacijom sa jasnim razlogom.

Ako analiza ne menja nijedan od ova četiri ishoda, nema vrednost za
release pipeline.

## 18. LOKALNO RADNO OKRUŽENJE

Canonical putanje:

`C:\Users\Admin\Downloads\work`

Source WIM: `C:\Users\Admin\Downloads\work\extracted\install.wim`

Mount: `C:\Users\Admin\Downloads\work\mount`

Scripts: `C:\Users\Admin\Downloads\work\scripts`

Logs: `C:\Users\Admin\Downloads\work\logs`

Backup/checkpoints: `C:\Users\Admin\Downloads\work\backup`

`mount_FBConan` i slični mountovi su reference/forensic images i nikada
se ne mešaju sa aktivnim BlueLite mountom.

Rad je isključivo OFFLINE nad target image-om dok ne počne kontrolisana
VM validation faza.

## 19. HARDWARE-AWARE EXECUTION

Trenutni backup/test host:

-   Ryzen 5 4500U
-   8 GB RAM

Na njemu:

-   DISM operacije serijalno;
-   bez nepotrebnog paralelizma;
-   bez ogromnih whole-DLL regex scanova;
-   koristiti bounded/string/offset analizu;
-   ograničiti broj wimlib compression threadova kada je potrebno;
-   ne kombinovati više teških inventory/compression operacija u isti
    korak.

Kada korisnik potvrdi povratak na glavni i7 desktop,
kompleksnije/paralelnije analize mogu se prilagoditi tom hardveru.

## 20. RADNI PROTOKOL CHATGPT ↔ KORISNIK

Radi se samo jedan izvršni korak u jednom trenutku.

Komanda/skripta je deo tog koraka.

Ne iznositi unapred sledeće izvršne korake ako nisu potrebni za
razumevanje trenutnog.

Pre svake mutation operacije mora biti jasno:

-   target;
-   dependency;
-   expected state;
-   rollback/checkpoint.

Kada korisnik treba da pošalje rezultat, zahtev mora biti konkretan:

-   „Pošalji samo output komande", ili
-   „Pošalji `<``tačno``-``ime``-log-``fajla``>`", ili
-   oba.

Ne tražiti neodređeno „pošalji rezultat".

Korisnik određuje redne brojeve/nazive razvojnih fajlova osim kada je
canonical release filename već zaključan.

Ne ponavljati pitanje na koje odgovor već postoji u istoriji, Memory
Summary-ju ili dostupnim fajlovima.

Pre davanja komande koja zavisi od stare odluke prvo proveriti postojeću
istoriju/fajl, umesto rekonstrukcije napamet.

Pre zaključka da neki target mora u NTLite/VM ili da je neki offline put
iscrpljen, proveriti relevantne BlueLite_Sources.md reference i druge
dostupne baze/izvore, osim kada je isto pitanje već potpuno dokazano
našim trenutnim image evidence-om i sertifikovanim cross-build pravilom.

## 21. GLAVNO PRAVILO

Cilj nije da napravimo jedan mali 26200.x image.

Cilj je da napravimo **BlueLite compiler za Germanium**:

CUSTOM UUP / STOCK GERMANIUM → MINIMAL DISCOVER / DELTA CHECK → CLASSIFY
→ RESOLVE DEPENDENCIES → GREEN REMOVE → AMBER PORTABLE ENGINES + OFFLINE
INTEGRATIONS → CERTIFY → SECONDARY COMPONENT ENGINE ONLY FOR TRUE
RESIDUE → CERTIFY → BRANCH → CLEAN / EXPORT → VM ONLINE-ONLY DEBLOAT /
INTEGRATION / FINALIZATION + VALIDATION → RELEASE

Svaka nova analiza treba da smanji količinu ručnog rada na sledećem
buildu.

Ako nešto možemo dokazati i automatizovati offline, ono pripada BlueLite
engine-u, ne trajno NTLite-u i ne VM-u.

Svaki sledeći Germanium build zato treba da prolazi kroz isti ordered
script set: nekoliko neophodnih analiza, maksimalni unapred dogovoreni
offline debloat/integracije, NTLite samo za dokazani residue i tek zatim
VM-only završnicu. Relevantni BlueLite_Sources.md i ostali dostupni
izvori obavezno se koriste tokom svake od tih faza.
