# BlueLite — PREMAX-work (aktivni razvojni workspace)

**Usvojeno:** 2026-10-21 · **Status:** struktura/sablon spremni; nijedan aktivni PRE_MAX ciklus ovim kreiranjem nije pokrenut.  
**Normativni autoritet:** [Master Strategy](https://github.com/johnny-belgrade/windows/blob/main/BlueLite-Master_Germanium_Strategy_final.md) §0D, aktuelni Session Entry/Current/Handoff. Ovaj README je lokalni radni vodič, ne samostalna dozvola za WIM mutaciju.

## Obavezni izvori PRE nego što počne svaki novi UUP/PRE_MAX ciklus

1. Pročitaj kompletan aktuelni Master i Session Entry; potvrdi live Current, relevantni Handoff, Registry i Contracts.
2. **Stvarno otvori i pročitaj** `C:\work\UUP-history\00_README.md` i ciljano `C:\work\UUP-history\99_Index\RH06_Final_ProvenanceMapping.csv`, `RH07_Manifest_SHA256.txt`, `RH08_ContentMarkers_ForUniversalDrafts.csv`, zajedno sa odgovarajućim originalnim kanonskim izvorima. Ne skenirati automatski ceo `C:\work` tražeći stari UUP materijal.
3. Ukrsti nalaze sa relevantnim originalima iz ChatGPT Library i iz GitHub Sources/production/target-specific logova. Source SHA/build/dependency dokaz ima prednost nad nazivom fajla, `CrossBuild`, rečju `PASS` u tekstu ili sećanjem.
4. Zabeleži tragove u novom `01_Inputs\Sources_And_Hashes.csv` ili u manifestu ciklusa: izvor/putanja, source_kind (LocalHistory/Library/GitHub/LiveLocal), SHA256, build, receipt, provereni predicate, nerazrešene zavisnosti.

## Kreiranje novog ciklusa

- Jedna nova nepostojeća putanja po odobrenom razvoju: `C:\work\PREMAX-work\R001_kratka-namena\`, zatim `R002_...`, itd. Broj je jedinstven u **ovom workspace-u**; ne podrazumeva odobrenje niti proizvodni R20R2 runtime broj. Ne prepisuj stare cikluse.
- Kopiraj prazan sadržaj podfoldera i `CycleManifest.template.json` iz `_TEMPLATE` u novi ciklus. U novom ciklusu nazovi kopiju `CycleManifest.json` i popuni `cycle_id`, `source_build`, SHA, owner, opseg, status i jedan NEXT; šablon nikada ne izvršavati.
- Registruj ciklus u `99_Index\CycleRegistry.csv` (jedna stavka po ciklusu, a zatim ažuriranje statusa te stavke). Za promene čuvaj SHA i output putanje, stare evidence ne prepisuj.

```text
C:\work\PREMAX-work\R001_kratka-namena\
    CycleManifest.json
    01_Inputs\       # reference / source hash / plan; bez slepog kopiranja GB WIM-a
    02_Analysis\     # diff, topology, lineage, dependency, acceptance criteria
    03_Drafts\       # nove, NEAUTORIZOVANE .ps1/.cmd draft verzije
    04_StaticTests\  # AST, syntax, dry-run, negative fixtures, parser tests
    05_Evidence\     # literal receipts, immutable logs, hashes, outcome
    06_Candidate\    # source-review-ready candidate, jos NE runtime-certified
```

## Promocija i granice

- `UUP-history` = istorijski **READ-ONLY po operativnom ugovoru** (ne nužno NTFS ACL): nikada ne menjati stare fajlove/niti izvršavati istorijske skripte direktno odatle. Arhivske byte-originals i indeks su trajna referenca.
- `PREMAX-work` = jedino podrazumevano razvojno mesto za **nove** UUP/PRE_MAX nacrte i test-artefakte. Novu probu radi u sopstvenom R### folderu; datirane snapshot-e, diffs, statičke i negativne dokaze drži uz taj ciklus. Ne izvršavaj draft na WIM-u samo zato što je u `06_Candidate`.
- `C:\work\scripts` = reviewed, SHA-pinned staging putanja za konkretan operatorom odobreni izvršni korak; **postojeći istorijski fajlovi u scripts nisu automatski re-certifikovani ovom promenom**. Verziju iz `06_Candidate` **kopirati/promovisati** tek posle potpunog pregleda. Puni identični izvor na GitHub `production/targets`/`production/engine` gde odgovara; receipt u `C:\work\logs` uz GitHub izvode.
- Svaka promena WIM/registry/CBS/ISO i dalje zahteva *posebnu eksplicitnu operatorsku GUI autorizaciju*, exact source/index/SHA, protected-floor guards, owner/mount/rollback i complete native post-state; uspešan static test nije runtime PASS.
- Nikad bez izričitog novog odobrenja ne premeštati/brisati stare UUP-foldere koji i dalje stoje kao siblings pod `C:\work`; **nema C:\work→UUP-history read-only reconciliation** u ovoj iteraciji, i nema samostalnog čišćenja tih direktorijuma.

**Veza sa prethodnim radom:** `C:\work\UUP-history\99_Index\RH06_Final_ProvenanceMapping.csv` mapira originalne putanje koje su *postojale unutar UUP-history u trenutku RH02 inventara* na sadašnji kanonski path; **ne** dokazuje da su spoljni `C:\work` UUP fajlovi identični. RH01–RH08 dokaz [GitHub](https://github.com/johnny-belgrade/windows/blob/main/production/evidence/BlueLite_UUP_History_RH07_20261021.md).

## Protokol radnih blokova i grešaka — Master v6.3.0 §0E (2026-10-21)

- Po završenoj nezavisnoj analizi/radnji ili prirodnoj grupi povezanih radnji: analiziraj rezultat, obavi obavezni Current/Handoff/Session Entry upis i nezavisan readback, zatim **PAUZA**. Operatoru u GUI vrlo kratko prikaži šta je urađeno, PASS/HOLD/FAIL i jedan NEXT; čekaj njegovo odobrenje ili promenu kursa.
- Za neuspešno čitanje, upis, preuzimanje, pristup, izvršenje, GitHub/web/server/alat ili bilo koju drugu grešku: **ukupno najviše tri pokušaja po istom problemu** (prvi uračunat; metoda/putanja/sesija ne resetuje limit). Bez slepog retry-a ili zaobilaženja sigurnosnih zabrana. Ako problem ostane, zaustavi blok, zapiši operaciju, grešku, broj pokušaja, poslednje dokazano stanje i neizvršeno u Current/Handoff ili drugi dostupan dozvoljen zapis, kratko prijavi u GUI i čekaj operatora. Ako zapis nije moguć, to izričito navedi.
- Samo ako operator tačno napiše **„Nastavi bez prekida“** može se preskočiti redovna pauza među uspešnim blokovima. **Nikad** se time ne preskaču pravila o greškama, zasebna GUI odobrenja (mreža/WIM/CBS/registry/ISO), source/SHA/dependency, §0R ili §0D.4 checkpoint.
- **Istorijski 2026-10-21 HTTP 502 HOLD je zatvoren 2026-10-22 isključivo operatorskom potvrdom ponovne dostupnosti i eksplicitnom dozvolom.** R001 26300.9711 dve metadata GET provere su sada zaista završene D4 PASS 98/2798; ovaj statički R002 ciklus nema dodatnu dozvolu za velike UUP/aria2 prenose, converter, WIM ili ISO mutacije. Operatorov raniji 60s monitor se ne duplira. UUP-history ostaje read-only.

**AKTUELNI WORKSPACE STATUS (2026-10-22):** Aktivni razvojni ciklusi su `R001_Universal_PREMAX_UUP` (26300.9711 dva metadata GET-a i D4 98/2798 PASS; 26300.9807 baseline HOLD) i `R002_Universal_Stage1_MAXPRE_Package` (3 razvojna PS7 drafta, AST/source/negativni statički PASS, lokalni ZIP source snapshot; nema converter/WIM/ISO izvršenja). `_TEMPLATE` je i dalje samo šablon. Autoritet za stvarno stanje je `CycleRegistry.csv` + pojedinačni `CycleManifest.json` i GitHub Current/Handoff/Session Entry. Nova faza rada traži zasebno operatorsko odobrenje po Master v6.3 §0E.
