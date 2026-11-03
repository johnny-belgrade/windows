# BlueLite UUP MAX_PRE v6.1 — konsolidovani paket

## Šta je isporučeno

Jedan komplet sa 38-fajlnim izvršnim overlay-em u `RUN`, celim GitHub `main` snimkom od 366 fajlova na commit-u `ab94087829167781a0dfad9ce5e7c11139eb6574`, izvornim R007 v6 overlay-em, pregledom promena, izvornim v5 operatorskim dokazom i svim R008 testovima/receipt-ima. GitHub snimak obuhvata sve fajlove tog stabla, uključujući razvoj, produkciju, ugovore, Registry, Sources, Master i Handoff; nije kopija svih istorijskih commit-ova/grana. Svi fajlovi stabla su preuzeti i provereni Git blob SHA-1 i SHA256, sav tekst indeksiran. Semantički pregled i popravke fokusirani su na aktuelni UUP put i povezane dokaze; arhivski mutacioni skriptovi nisu ponovo sertifikovani.

`RUN` je jedini tekući runtime kandidat. Arhivske skripte u `REFERENCE` i testovi u `TESTS` nisu deo automatskog proizvodnog toka. Originalni UUP ZIP i veliki Microsoft payload-i, WIM/ISO nisu uključeni. Izvor bira operator; nema hardkodovane CU revizije.

## Ispravke koje su stvarno završene

| Nalaz | Ispravka | Dokaz |
|---|---|---|
| Current/Session/Sources navode v5 NOT_RUN iako postoje noviji R007 dokazi | Preuzet i proveren originalni v5 evidence ZIP; aktivni checkpoint usklađen | 27/27 manifest članova, CRC, izvorni ZIP SHA |
| R007 preflight koristi automatski `$input`; proces sa otvorenim stdin čeka EOF | Preimenovano u `$sourceInputPath` | reprodukovan zastoj; naknadni PS7 open-stdin test PASS |
| Rani v6 gate proverava samo prisustvo tri metadata fajla | Preflight sada u zasebnom procesu proverava potpuni offline 1:1:1 ugovor pre mreže | originalna 98-redna triada PASS; missing/mismatch negative PASS |
| Parser je preskakao neispravne redove i dopuštao nepotpune/duplirane D4 atribute | Strogo parsiranje, jedinstveni GUID/filename/SHA, bez izvršavanja rename CMD | malformed/list/ledger/rename/duplicate/path/D4 negative PASS |
| FoD izveštaj veruje samo tekstualnom PASS markeru | JSON dokaz vezan za SHA256 celog D4 fajla i tri inputa; ponovna provera pri nastavku | bare marker, changed queue i changed metadata odbijeni |
| Završni CMD tekst tvrdi da su ostale samo četiri aplikacije | Tekst sada razlikuje željeni finalni skup od stvarnog residue izveštaja | source diff |

Deset od 38 R007 fajlova je promenjeno (uključujući profil, dokumentaciju i manifest); 28 je ostalo bit-identično. `BlueLite_PreDebloatWim.ps1` ostaje SHA256 `70B137758AB8CF7741DB84BB15E02C7544097DA58B492AB6DE2551FDBAD46DA5`. Downloader/URL-renewer, AppX manifest resolver, vendor hook i WIM mutaciona logika nisu prepravljani u ovom bloku. Tačan diff je `R008_v6_to_v6_1.patch`.

## Provere

- 26/26 glavnih native Windows fixture testova PASS, sa pojedinačnim receipt-om i novim nezavisnim PS7 Verify procesom posle svakog testa.
- Dodatne 3/3 provere PASS: PS7 preflight sa namerno otvorenim stdin; stvarni PS5.1 triad gate; stvarni PS5.1 precut classifier.
- Svih 15 runtime PS1 skripti parsirano bez greške u PS7 i Windows PS5.1.
- Originalni metadata/Windows queue 98/98; izabrani Apps queue 32; postojeći URL-renewer offline positive/negative PASS.
- Sintetička druga CU 26300.9999 prihvaćena samo kao preflight fixture, 26200 odbijen. Ovo NIJE drugi stvarni UUP build niti dokaz cross-build konverzije.
- Prvi neuspešan test i prva PS5.1 compatibility greška sačuvani su. Za PS5.1 compatibility child korišćen je njegov stock PSModulePath, jer RDC nasleđuje PS7 module i inicijalno nije pronalazio Get-FileHash; host environment nije trajno promenjen.
- R008 nije izvršavao UUP download, converter, WIM/CBS/registry/ISO mutation, NTLite ili VM. Master, originalni image-i, UUP-history i Handoff nisu menjani.

## Šta MAX_PRE trenutno stvarno daje

Preuzimanje AppX-a koristi pet obaveznih staging identiteta i stvarne framework zavisnosti. Native v5 izvor je redukovan sa 2798 Apps queue redova na 32. Celih 98 Windows transportnih fajlova ostaje: R007 je našao reference za svih 62 FoD kandidata u pregledanim CompDB izvorima; nijedno njihovo pre-download izostavljanje nije dokazano. Naziv komponente koju želimo ukloniti iz finalnog OS-a nije dokaz da njen transportni fajl nije potreban za rekonstrukciju.

Posle rekonstrukcije, postojeći engine obavlja native offline pre-ISO MAX_PRE. V5 native dokaz: 49 evidentiranih akcija, 18 capability promena, 9 feature promena, 211→76 package inventar redova (nije 135 direktnih uklanjanja), 4 upozorenja/skip-a, health clean i 11 zaštićenih fajlova prisutno. WIM `7,491,384,220 → 5,734,238,611` B; WIM SHA256 `6A94A7BBF5BC1EE078B535E07DAEA03DDE78D9F8F07A6B64F7458A4121FD1055` iz native loga. R007 native ISO evidencija: `6,820,456,448` B. V6.1 još nije prošao punu konverziju.

## Granice koje nisu proglašene popravljenim

| Stavka | Stvarno stanje |
|---|---|
| DesktopAppInstaller | Native provisioned residue ostaje; 26300 owner/hardlink/lifecycle HOLD; final 4-app release nije PASS |
| Language.Basic en-US | Native 0x800F0825; zadržan po v5 politici do CBS dokaza |
| WMIC | Dva invalid superseded selector skip-a ostaju F03 |
| WIM transakcija | Nasleđeni engine montira rekonstruisani kandidat i radi commit/export/replace; odvojeni immutable reconstructed checkpoint i rollback/promotion hardening F04 nisu implementirani ovim source-gate patch-em |
| Runtime mikro-receipt protokol | R008 testovi imaju pojedinačne receipte/nezavisni Verify; nasleđeni WIM engine koristi zbirni action/health/inventory log i nije ovde pretvoren u potpuni per-mutation fresh-process receipt engine |
| WinRE | SkipWinRE=1; Setup boot.wim ostaje. Recovery-on-Demand je opis/metapodatak, nije bootabilan recovery payload |
| Veličina / release | ISO oko 5GB nije dostignut; clean installed 14.5–15.5GB, OOBE, boot, CU, Defender, VM-host i NTLite nisu sertifikovani |
| Univerzalnost | Parametrizovan 26300.x amd64/en-us/Professional kandidat; dva različita native 26300 izvora još nisu dokazana |

Zato je oznaka isporuke **SOURCE_FIXTURE_VERIFIED / FULL_NATIVE_V6_1_NOT_RUN / RELEASE_NOT_CERTIFIED**. Paket sadrži kompletan postojeći rad i testirane source ispravke; ne pretvara otvorene zavisnosti u izvršene uspehe.

## Korišćenje isporuke

Raspakovati sadržaj `RUN` uz originalni, netaknuti UUP Dump ZIP u NOVOM folderu bez razmaka. Dodati tri stvarna fajla ZA ISTI izabrani izvor: `List of files UUP.txt`, `File_renaming_script.cmd` i `SHA-1 checksums file.txt`. Stare test-fixture metadata datoteke nisu univerzalni input za drugi CU. Originalni launcher mora ostati originalan.

Prva source-only provera u tom folderu (PowerShell 7):

```powershell
pwsh -NoProfile -File .\BlueLite\BlueLite_Preflight.ps1 -UUPRoot .
```

Za posebno odobrenu punu izgradnju koristi se `START.cmd` kao Administrator; to pokreće download/converter/offline WIM/ISO i znatno CPU/IO opterećenje. Ne koristiti GOLDEN folder kao radni folder. Nasleđeni portable runtime vraća jedan `BlueLite_EVIDENCE_*.zip` u tom UUP root-u; R008 razvojni test receipt-i su pod `C:\work\logs`. Ne pokretati arhivske skripte iz `REFERENCE`.
