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

## Obavezni cilj svih offline-WIM/PRE_MAX nacrta — Indexing OFF (operator 2026-10-25)

Po Master §16.1, svaka nova ili promovisana offline modifikacija zajedničke baze mora imati acceptance stavku **Windows Search file/content indexing OFF**: `WSearch` Disabled u ciljanom offline servisnom stanju, primenljive proverene sistemske/policy zabrane indeksiranja i mehanizam održanja posle OOBE, prvog boot-a, restart-a i servicing-a. Standardni korisnik ne sme jednim GUI klikom uključiti indeksiranje; ponovna aktivacija je namerna administrativna višekoračna reverzija, bez obaveze jednokliknog desktop enable paketa.

U `02_Analysis` zabeležiti tačan OS build, offline servisna/policy mesta, dependency odnos sa Start/Search UI, CBS i Update; u `04_StaticTests` negativne kontrole i dokaz podrške tih mehanizama, a u `05_Evidence` native post-state `WSearch`/efektivnih politika i post-boot/perzistencije tek kada bude odobren izvršni test. Ne uklanjati Search/shell komponente naslepo niti izmišljati policy ključeve; ako neki nivo nije podržan, HOLD dependency i odvojiti servisni minimum od punog PASS. **Ova smernica nije dozvola za novu WIM/hive/CBS/registry mutaciju**, niti dokaz implementacije na 26300.9807; postojeće zaštite originalnih UUP ostaju na snazi.

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

## Latest Stage1 PREMAX R002-R4 pointer (2026-10-22)

- New current R002-R4 source-only original-vendor `abbodi1406/BatUtil` v128m branch audit **PASS**, precise full ISO media reconstruction with `install.wim` and `boot.wim`, then `SkipISO=1` exits before final ISO creation; native PS7 AST PASS and **11/11 synthetic negative PASS**. Vendor upstream source bytes independently matched exact Git blobs but upstream full script remains a read-only local reference, not executed or republished.
- Source/frozen-version boundary remains **HOLD**: operator 26300.9711 UUP ZIP declares v126 while latest official UUP Dump metadata declares v128m; no archive binary/runtime compatibility tested. 26300.9807 independent original queue baseline remains HOLD. R002`06_Candidate` empty; RecipeRegistry r38 runtime disabled; no WIM/ISO mutation.
- Owned evidence under `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence\R002R4_StockVendor_PreISO_Static_Receipt_20261022.txt`, CycleManifest `r4_stock_vendor_preiso`, GitHub Current/Handoff/Session Entry. The operator thermal advance notice and selective owner-verified disposable WIM cleanup below remain mandatory. No new runtime/dowload permission.

## Obavezno operatorsko upozorenje na CPU temperaturu i kontrolisano uklanjanje velikih disposable artefakata (2026-10-22)

- **PRE** svakog većeg download-a, UUP/converter rada, WIM export-a ili sličnog CPU/disk-intenzivnog posla: ChatGPT mora u GUI **unapred** da napiše šta se izvršava, približnu veličinu kada je poznata, očekivano CPU opterećenje, sve odredišne putanje i da operator može da nadgleda temperaturu. Navedena najava nije zasebno odobrenje za mutacioni/network runtime — prethodni Master gates ostaju.
- Sva velika preuzimanja, payload, disposable WIM, radni ISO i konverzijski output idu u jasno owned **`C:\work\...`**, osim kada je dokazano potrebno `C:\` root i operator posebno potvrdi tačan path. Nema implicitne dozvole za drugi root.
- Nakon završetka analize obavezno razmotri ciljano brisanje **samo dokazano owned** velikih nepotrebnih disposable artefakata, naročito WIM, **tek kad** postoje dovoljni native report/log/sha/source backup/rollback dokazi, direktorijum više nije aktivna zavisnost, mount/hive su oslobođeni, a original i history nisu u pitanju. Ne brisati izvorni ZIP, referentni/operativni WIM ili nepotvrđene/susedne fajlove; brisanje konkretnih WIM zahteva zasebnu odobrenu operaciju.

**AKTUELNI WORKSPACE STATUS (2026-10-22):** `R001_Universal_PREMAX_UUP` .9711 metadata D4 PASS 98/2798, .9807 frozen baseline HOLD; `R002_Universal_Stage1_MAXPRE_Package` izvorna tri statička drafta PASS i nova **R002-R2 verzija** overlay/D4/D5/G4 malog fixture 11 originalnih ZIP članova, Windows 98, G4 Apps 32, 4/4 negativna testa PASS. `04_StaticTests\R002R2_Fixture_001` sadrži lokalne signed URL-ove: ne uploadovati na GitHub. `05_Evidence\R002R2_SourceOnly_20261022.zip` je bez njih. `06_Candidate` prazno, realan UUP/converter/WIM runtime nije autorizovan. Tačno stanje održavaju `CycleRegistry.csv`, `CycleManifest.json`, Current/Handoff/Session Entry. Svaki novi logički blok čeka operatora po Master §0E.

## Trajna operatorska odluka — RDC privremena dozvola potrebne komande (2026-10-22 / R002-R7)

- Operator je odobrio svakom successor-u privremeni izuzetak za konkretno potrebnu stavku RDC `blockedCommands` (na primer `reg` tokom zasebno odobrenog offline hive posla), **ne** trajno ukidanje svih stavki i ne izmenu `allowedDirectories`. Master v6.3.0 §0D.4(5) ostaje nadređen.
- Obavezno: očitaj i sačuvaj kompletan originalni `get_config` (lista `blockedCommands` u izvornom redosledu i `allowedDirectories`); proveri stvarnu neophodnost komande, cilj i pojedinačno odobrenje; privremeno izdvoji samo nužnu stavku; posle koraka ili izuzetka/greške **vrati celokupnu početnu listu** i nezavisnim `get_config` readback-om potvrdi identitet. Ako vraćanje ne uspe, odmah `ERROR_HOLD` i operatorovo obaveštenje. Sve promene evidentirati, ne pretpostavljati.
- To nije pravo za zaobilaženje nezavisnih OpenAI/platform safety odbijanja, širenje root pristupa, debloat live Windows-a, ponavljanje blokiranog poziva drugim putem ili neodobrenu WIM/CBS/ISO/registry mutaciju. Ako konkretan korak ne zahteva RDC izuzetak, listu ne menjati.
- R002-R6 status na 2026-10-22: original 26300.9807 SourceProbe PASS, negativni test još nije izvršen usled platformske zabrane pre starta, metadata GET 0/2; operator je potvrdio UUP Dump PHP dostupnost, što nije native queue identity receipt. GitHub reconnect provereno radi; nastaviti prema najnovijem Current/Handoff/Session Entry, bez ponavljanja istorijskog pokušaja kao PASS.


## Hybrid v2 — 2026-10-29 (current normative workflow for this workspace)

The operator approved Master §0G. It supersedes obsolete **routine** Git Current→Handoff FIRST→Handoff SECOND→Session Entry LAST writes and redundant full-history startup reads in older sections above. The detailed old log remains historical evidence, never a live execution permission.

- Primary: GitHub approved, versioned code and short **single live Current**; Session Entry = short router; Handoff = frozen historical archive. Preserve pre-compaction Git blobs/commits. Never create another active status file.
- Local: keep exact original/native receipts in owned C:\work\logs or the cycle 05_Evidence. For each **individual** operation, write a **new** uniquely named receipt (CreateNew), then use **separate process/readback** comparing expected SHA and required fields, before next operation. Journal a material logical block in compact Current with Git CAS/independent readback; no per-action Git megafile update.
- Verified helper: GitHub development/PREMAX/tools/BlueLite-ReceiptGate-v2.ps1; local mirror C:\work\scripts\BlueLite-ReceiptGate-v2.ps1. Record vs Verify in independent runs. The helper is **not** a generic runner nor a production mutation. Actual native stdout, path, source SHA, report and privilege/authorization require separate review. LOCAL_QA_PASS is not automatically assistant-verified result.
- RDC (lane A) only with live nonempty allowedDirectories of exactly approved roots and 33 original blocks. If unavailable or unsuitable **without a platform safety denial**, use reviewed GitHub/GUI source + operator-run **one exact verified PS7 command** (lane B) and return local receipt/stdout; never claim the GUI download was automatically copied to C:\work. A platform-safety denial must not be rerouted to lane B to evade it. No WIM/OS mutation without explicit separate approval.
- Continue mandatory local UUP-history/00_README and targeted RH06/RH07/RH08 original evidence reviews for **new** UUP/PREMAX research. All source/WIM/Registry/NTLite/VM requirements, three-attempt cap, GUI block pause and permanent Master §16.1 Windows indexing-OFF release gate remain unchanged.
