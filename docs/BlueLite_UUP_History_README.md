# BlueLite — UUP historical evidence corpus

**Datum organizacije:** 2026-10-21  
**Status:** RH06 organizacija i SHA256/byte-verified dedup PASS; nezavisna RH07 verifikacija PASS; RH08 sadržajni indeks PASS.

Ovaj folder je **istorijski analitički corpus READ-ONLY po operativnom ugovoru** (ne nužno NTFS ACL), ne aktivan executable skript-repozitorijum. Nikada direktno ne izvršavati stare `.ps1`, `.cmd`, `.sh`, arhivske ili instalacione fajlove odavde. **OBAVEZNO za svaki novi UUP/PRE_MAX development/test ciklus:** successor mora stvarno pročitati **ovaj `00_README.md`**, zatim relevantne `99_Index` manifeste i njihove tačne canonical izvore, uporediti sa Library originalima i GitHub Sources/Current/Handoff/Registry/Contracts. Draft i test fajlovi ne idu u UUP-history; otvaraju se kao **novi `C:\work\PREMAX-work\R###_short-purpose\`** (pravila u `C:\work\PREMAX-work\00_README.md`). Tek posebno pregledan, SHA-pinned kandidat može biti kopiran/promovisan u `C:\work\scripts` i na GitHub; stvarno izvršenje zahteva zasebno operatorsko odobrenje.

## Struktura

- `01_Timelines` — istorijske konzolne i druge vremenske evidencije
- `02_Scripts` — izvorni istorijski kod (read-only referenca)
- `03_Logs` — logovi i TXT dokazna evidencija
- `04_Analyses` — analize, review, diff i dokumentacija
- `05_Manifests` — JSON/CSV/INI/XML, konfiguracije i metapodaci
- `06_Archives` — kanonske arhive .7z i .zip (izvorni bajtovi)
- `07_Resources` — ostali izvori
- `99_Index` — manifesti, arhivski izvodi, provenijencija, SHA indeksi i audit

Unutar kategorija: `build_group\stage\name__SHA12.ext`. `Unresolved` znači da putanja sama ne identifikuje build, **ne** da je fajl neprikladan. `CrossBuild` znači zajednički byte-identičan sadržaj u više build-kontexta; **ne** znači automatski univerzalan recept.

## Obavezna evidencija i kako pronaći svaki izvor

- `99_Index\RH02_Original_PreMove.csv` — originalnih 1.947 fajlova, stare pune/relativne putanje, bytes i SHA256 pre bilo kakvog premeštanja.
- `99_Index\RH03_ArchiveAudit.csv` i `RH03_ArchiveMembers.csv` — 19 proverених arhiva i listing članova.
- `99_Index\RH04_ArchiveProvenance.csv` / `RH04_ExtractedFiles.csv` — 18 jedinstvenih raspakovanih arhiva i 469 raspakovanih fajlova.
- `99_Index\RH05_ApprovedScope_PreApplyPlan.csv` — plan svih 2.416 source/archived zapisa **pre** premeštanja/brisanja, očekivani SHA i destination.
- `99_Index\RH06_Exact_ActionJournal.txt` — vremenski redosled pomeranja i byte-comparison pre brisanja identičnih duplikata.
- `99_Index\RH06_Final_ProvenanceMapping.csv` — najvažniji indeks: `source_rel` (stari naziv), `archive_origin`, `source_sha256`, `final_rel` (kanonski sadašnji put), `action`.
- `99_Index\RH07_Independent_Verification.txt` / `RH07_Category_Build_Stage_Matrix.csv` / `RH07_Manifest_SHA256.txt` — nezavisno potvrđenih 549 SHA, 1.867 duplikata i 222 prazna foldera.
- `99_Index\RH08_ContentMarkers_ForUniversalDrafts.csv` — markeri buildova, UUP/MAX_PRE/DISM/NTLite/OneDrive iz samog sadržaja 549 kanonskih fajlova. Samo **discovery indeks**, ne dokaz izvršenja, kompatibilnosti ili zavisnosti.
- `99_Index\RH08_Summary.txt` — kontrolni zbir dodatne sadržajne klasifikacije.

**Rezultat:** 549 jedinstvenih kanonskih fajlova, 20.414.714 bajtova jedinstvenog klasifikovanog sadržaja. Izvornih 1.947 + raspakovanih 469 = 2.416 fizičkih zapisa; 1.867 identičnih kopija obrisano posle SHA + byte poređenja, 222 prazna podfoldera uklonjena. Originalne arhive zadržane kao jedinstveni kanonski fajlovi, osim jedne dokazano identične kopije.

**Važno:** deduplikacija ne briše izvornu provenijenciju: na staru putanju **koja je postojala unutar `C:\work\UUP-history` u trenutku RH02 inventara** pretraži `RH06_Final_ProvenanceMapping.csv` i pročitaj kolonu `final_rel`. To NIJE potvrda da su raniji **spoljni sibling UUP folderi i fajlovi direktno u `C:\work`** identični kanonskim fajlovima: korisnik ih je prethodno samo kopirao ovde, a poređenje spoljnog prostora **nije izvršeno**. Izričito je odlučeno da se **ne radi read-only `C:\work`→`UUP-history` reconciliation i ne briše/premešta ništa iz tih starih sibling foldera** u trenutnoj iteraciji. Originalni Library fajlovi i GitHub produkcioni dokazi nisu modifikovani RH01–RH08 organizacijom. Nijedan istorijski kod nije izvršen i nijedan WIM nije montiran/menjan.

**Successor:** [Master v6.1.0](https://github.com/johnny-belgrade/windows/blob/main/BlueLite-Master_Germanium_Strategy_final.md) → [Session Entry](https://github.com/johnny-belgrade/windows/blob/main/BlueLite_Session_Entry.md) → Current Status → Handoff. Pre sledećeg PRE_MAX univerzalnog drafta koristiti source-bound dokaze i eksplicitno proveriti build, sha, owner/dependency, ne zaključivati runtime PASS iz tekstualnih markera.

