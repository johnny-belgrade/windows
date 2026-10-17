# BlueLite v1.0 — Germanium Universal Successor Handoff

**Verzija dokumenta:** 1.0.0 · **Izrađeno:** 2026-10-17  
**Status:** Trajni tehničko-operativni handoff; **ne predstavlja release sertifikat**  
**Primarni proizvod:** Windows 11 **26H2 GA / 26300.x**, x64; trenutno potvrđen izvor 26300.9711 / en-US / Professional.  
**Istorijska/regresiona baza:** 26200.x; zajednički servisni referentni koren: 26100.x. Nove Germanium linije samo po odluci operatora i uz proveru porekla.  
**Vlasnik cilja i lokalnog izvršavanja:** operator; **inženjerski saradnik:** ChatGPT.  
**Normativna osnova:** [`BlueLite-Master_Germanium_Strategy_final.md`](BlueLite-Master_Germanium_Strategy_final.md), v6.0.0.  
**Živi dnevnik i tačka nastavka:** [`BlueLite_Current_Status.md`](BlueLite_Current_Status.md).  
**Historijski UUP dokazni indeks:** [`BlueLite_UUP_Evidence_Reconciliation_20261013.md`](BlueLite_UUP_Evidence_Reconciliation_20261013.md).  
**Celokupan spoljašnji katalog:** [`BlueLite_Sources.md`](BlueLite_Sources.md).  
**Repo:** <https://github.com/johnny-belgrade/windows>; branch `main`.

> **OBAVEZNO ZA SVAKOG NAREDNOG CHATGPT NASLEDNIKA — PRE BILO KAKVOG KODA ILI KOMANDE**
>
> 1. Pročitaj **sve raspoložive aktuelne ne-istorijske dokumente u root-u GitHub repozitorijuma** i proveri njihovu strukturu, verziju i relacije: najpre MASTER (pravno/tehnički autoritet pravila), ovaj HANDOFF (procedura i mapa nasleđenog znanja), **Current Status od prvog/najnovijeg checkpoint-a** (stvarni najnoviji korak), **UUP Evidence** (tačna istorijska dokazna ograničenja) i **Sources** (svaka tematski relevantna spoljašnja referenca). Proveri i druge root dokumente/indekse otkrivene inventarom; ovo nije zatvorena lista. Ako se dokument ne može pročitati, to **prijavi**; ne tvrdi da je pregledan.
> 2. Pretraži **kompletnu dostupnu ChatGPT Library/projektnu arhivu** ciljano, ali sistematski: originalne operaterske logove, skripte, ZIP manifest-e, Build_info drugih autora, WIM/CBS/WinSxS/AppX inventare, Timeline fajlove, stare handoff-e i sve relevantne `*ChatGPT*.md` / `Chats*.md` zapise. Za materijalne nalaze **pročitaj sadržaj**, ne samo rezultat pretrage. Ne tvrdi da su sve stotine fajlova fizički pročitane ako nisu; evidentiraj nedostupne izvore. Ponovi ciljano traženje **pre svake nove analize, dependency odluke, izmene modula ili mutation komande**. Ako je precizan dokaz već pribavljen za odgovarajući identitet/topologiju, **zabranjeno je ponavljati ga samo zato što je nova sesija**; ako nedostaje deo, istraži samo razliku.
> 3. Iz GitHub `BlueLite_Sources.md` prouči sav popis linkova i **koristi svaku relevantnu referencu za konkretan target**, ne samo Microsoft; proveravaj Microsoft Learn/KB, abbodi1406/UUP Dump, DISM, wimlib, NTLite, MSMG, PowerShell, reg, Win32, community, WinCert, MDL, ElevenForum i uploader/Build_info gde pomažu. Smernica ili primer nisu runtime dozvola. Dokumentuj proverenu URL/reviziju/primenljivost i datum. Ne predstavljaj neotvorene linkove kao analizirane.
> 4. Zatim uporedi **aktuelni operatorski dokaz** sa Current-om i pravilima: build, source UUID, hash, UUP izdanje/jezik/arhitektura, WIM index, montiranje, zdravlje/CBS pending, verzija skripte, rezultat i **da li je kod zaista izvršen**. S01–S06 status u ovom handoff-u je snapshot na 2026-10-17; noviji Current ima prvenstvo za stanje izvršavanja.
> 5. **Radi identično kao prethodni tim:** jedna samostalna i potpuna komanda/skripta po poruci u razvojnom režimu; samo PowerShell 7 **Admin**, precizna očekivana putanja izlaznog `.txt`/`.json` loga, jasna kontrola hash-a i negativnih slučajeva, fail-closed, bez delimičnih komandi koje operator mora da popravlja, bez iste neprijatne stare analize. Operator bira osnovu i cilj, ChatGPT priprema/proverava/interpretira, **operator jedini izvršava lokalno** i vraća izlaz. Ne tvrdi da ChatGPT direktno vidi host disk ili upravlja procesima.
> 6. **Nikada ne targetiraj živi host Windows za offline BlueLite debloat.** Host može legitimno pisati TEMP/DISM log i privremene offline-hive alias-e; ciljna mutacija sme ići samo u provereno **offline, operatorsko** WIM stanje. Pre svakog mount/unmount: traži da se zatvore **Total Commander** i Explorer prozori na mount direktorijumu. Na kraju sesije odjavi owned offline hives, proveri DISM mount tabelu i očisti samo identifikovane napuštene mountpoint-e. Read-only mount se obično DISCard-uje. Ne preuzimaj drugi proizvoljan WIM zbog provere koja već ima dokumentovan rezultat.
> 7. Nakon **svakog stvarno potvrđenog** novog checkpoint-a ažuriraj **isti** `BlueLite_Current_Status.md`: datum, izvor/hashes, izvršen korak, rezultat, granice dokaza, grešku/zavisnost, potrebne logove i **jedan naredni dozvoljeni korak**. GitHub zapis radi uz `fetch → expected blob SHA → merge bez gubitka tuđih promena → update → ponovni fetch i exact read-back`. Ako repo nije dostupan, ostavi verifikovan `.md` fajl operatoru, jasno kaži šta nije upisano. Master menjaj samo ako se promeni trajno pravilo; HANDOFF revidiraj samo zbog nove arhitekture ili važnog dokaza koji utiče na sve buduće sesije. **Current je dnevnik, ne nova zbirka celih chat transkripata.**
> 8. Statusi su strogo različiti: `PROPOSED`, `DELIVERED_NOT_RUN`, `STATIC_VERIFIED`, `NATIVE_OPERATOR_PASS` za ograničen test, `THIS_BUILD_CERTIFIED`, `RELEASE_PASS` i precizni `HOLD/BLOCKED_*`. Tuđi screenshot, stari log, parsirana skripta ili uspešan skraćeni audit **nisu** kompletan 26300 production/release PASS. Ako postoji razlika između Mastera, starog UUP Evidence teksta i novijeg operator loga, **ne popravljaj istoriju retroaktivno**: izričito označi superseded tvrdnju i relevantni datum.

## 1. Autoritet, pravila saradnje i zašto postoji ovaj handoff

**Handoff** čuva **koncept, arhitekturu, tehnička obrazloženja, indeks prenosivih recepata, evidence pointers i protokol**. **Current** je revizionisan, hronološki/obrnutohronološki **dnevnik rada sa checkpoint-ima**. **Master** definiše normativni cilj i release gates. **UUP Evidence** čuva istorijski argument i komparativnu bazu. **Sources** čuva živi katalog istraživačkih referenci; **Library** originalne fajlove i dugotrajne analize. Ne kopi-pejstuj naredne chatove u novi `Chats*.md` dnevnik i ne pretvaraj Current u drugo 600 KB obrazloženje svakog algoritma. Minimalna zaokružena jedinica rada: **jedna proverljiva odluka + izvor + stvarni output + status + sledeća tačka**.

Univerzalnost nije npr. `if ($build -eq '26300.9711') ...`; ona je **engine + profili + Component Intelligence + manifest + pozitivni/negativni fixtures + dokaz trenutne topologije**. Isti kod treba da obradi naredni operatorom izabrani GA `26300.x`, bez prepravljanja izvora svaki CU; samo `UNKNOWN_DEPENDENCY/TOPOLOGY_CHANGED` otvara ciljanu novu analizu. Povratne 26200 eksperimente pokretati **samo kao regresione testove**, ne kao drugu aktivnu proizvodnu granu.

Ciljni ISO **3,5–5 GB**, čista instalacija **11–15 GB** bez dodatnih specifičnih drajvera/programa; oba broja **meriti**, ne garantovati niti zameniti logički WinSxS zbir stvarno oslobođenim bajtovima. Debloat maksimum uz poznatu servisnu granicu i dodatnu opcionalizaciju. Ako realan 26300 build ne može u taj opseg: iskazati tačne mandatory zavisnosti i njihov fizički/transportni trošak; nikad proglasiti lažnu uštedu. Korisnik preferira termin **zavisnost**, ne neodređeno zastrašivanje terminom nestabilnost.

**Fiksan redosled:** (1) univerzalni UUP downloader + konverzija + post-reconstruction/pre-ISO MAX_PRE, (2) univerzalni samostalni offline PowerShell MAX-debloat koji obrađuje preostalo i zna šta je već urađeno, (3) NTLite **Business** lokalno tek za opravdani `COMPONENT_ENGINE_HANDOFF`, (4) VirtualBox/OOBE/online finishing/capture/release. Dva Defender ogranka **ON/OFF** nastaju iz čistog common-base-a. U normalnom budućem release-u operator pokreće već pregledan **jedan ulazni orchestrator**, dok je **jedan operator korak po poruci** razvojni/diagnostički način rada.

Svi potrebni alati osim operatorskog NTLite Business treba da budu besplatni i lokalni/online. Ne sugeriši kupovinu duplih proizvoda. Ne preskači offline mogućnosti prelaskom u VM. Ne preuzimaj ogromne podatke ponovo radi već sertifikovanog parser testa.

## 2. Reference i nivo dokaza — čitati pre posla

| Izvor | Uloga | Obavezna radnja naslednika |
|---|---|---|
| [`Master Strategy v6.0.0`](BlueLite-Master_Germanium_Strategy_final.md) | **Normativni autoritet**; §§0A,0B,2–10,14–19,20,22,26–31 | Proveri poslednju verziju; sve nove recepte i izuzetke uskladi sa njom |
| [`Current Status`](BlueLite_Current_Status.md) | **Stvarni živi poslednji checkpoint**; log S01–S06 i stara R1–R142 istorija | Čitaj od vrha; proveri razlike i status nove sesije; nakon PASS upiši samo dodatnu dnevničku stavku |
| [`UUP Evidence`](BlueLite_UUP_Evidence_Reconciliation_20261013.md) | 26200 transport/CompDB/dependency/MAX_PRE komparativni dokaz; §G1–G6 | Prenesi algoritam, **ne** 26200 output state/veličine; zastarelo „26300 još nije pribavljen“ prevaziđeno S01–S06 |
| [`Sources`](BlueLite_Sources.md) | Index **svih** spoljašnjih istraživačkih veza | Pregledaj ceo katalog; koristi i verifikuj kategorije primenljive na cilj, uklj. upstream kod |
| Interna Library `/BlueLite_v1.0`, `/BL_UUP`, `/BlueLite_MASTER`, `/UUP_PreBuild`, raniji handoff-i i razgovori | Originalni `*.ps1`, `*.zip`, logovi, CBS/WinSxS, `Timeline*`, reference uploadera | Targeted complete search i otvaranje materijalnih fajlova; ne tvrdi da je 700+ stavki pregledano ako nije |
| Originalni operatorski izvršni `*.json` / `*.txt` / DISM | Da li se nešto **stvarno desilo** | Poveži izvor SHA, target, naredbu, post-state, exit, zdravlje, pending |
| Git commit, blob SHA i exact source ZIP | Identitet objavljenog kod-a | Koristi konkretan SHA/commit, ne filename sam za sebe |

**Važna granica pristupa u ovoj izradi:** GitHub connector je uspešno otvorio i proverio **četiri aktuelna root governance dokumenta** (Master, Current, Sources, UUP Evidence). Istorijski repo commit **[`c49da5f`](https://github.com/johnny-belgrade/windows/commit/c49da5f259d366f544b1900b9775dd82f84b457b)** navodi `ChatsGPT.md`, ali direktni `fetch_file(ChatsGPT.md, main)` i pokušaj na tom commitu trenutno su vratili `404`. Zato ne tvrdimo da je taj transkript u ovom radu pročitan iz repoa. Umesto izmišljanja njegovog sadržaja, za istorijsku osnovu korišćeni su živi **Current**, Master, UUP Evidence, ranije dostupni Library transcripti (`9-ChatGPT.md`, `10-ChatGPT.md`, `11-ChatGPT.md`, `11-13-ChatGPT.md`, stare `ChatGPT-1…4` izvozne reference) i **originalni operatorski logovi**. Pre brisanja repo `Chats*.md` operator mora da proveri stvarni spisak i jedinstvene informacije, i sačuva lokalnu kopiju/git reviziju; ako je sadašnji transkript još dostupan pod drugim imenom, naredni naslednik ga ciljano pretražuje. **Nijedno nedostupno poglavlje nije označeno kao pročitano.**

### 2.1 Kako koristiti „thinking“ iz ranijeg rada

Ne zavisi od nedostupnih privatnih međukoraka. Prenosi **javno obrazloženje inženjerskih odluka**: uslov (source/state), alternativne mogućnosti, dokaz i negativni test, šta smo odbacili i zašto, status, uslov prenosa u univerzalno pravilo, link ka primarnom logu/kodu. Relevantni tragovi su [Master §2](BlueLite-Master_Germanium_Strategy_final.md#2-the-central-lesson-of-the-four-histories), [Master §§7–10](BlueLite-Master_Germanium_Strategy_final.md#7-uup-source-policy-and-reconstruction-safe-one-click-architecture), [Evidence §G1–G6](BlueLite_UUP_Evidence_Reconciliation_20261013.md#newly-identified-concrete-gaps-not-an-invitation-to-redo-prior-studies), [Current R26-D4/D5/D6; R113–R142; S01–S06](BlueLite_Current_Status.md). Te reference predstavljaju proverljiv razlog odluke, a **ne zahtev za pristup skrivenom modelskom chain-of-thought-u**.

### 2.2 Glavni spoljašnji linkovi — izvori koje prvo povezati sa konkretnim pravilom

- Microsoft 26H2 IT Pro: <https://learn.microsoft.com/en-us/windows/whats-new/whats-new-windows-11-version-26h2>; KB5121794: <https://support.microsoft.com/en-gb/servicing/os/windows-11/2026/09/kb5121794-feature-update-to-windows-11-version-26h2>; KB5127648: <https://support.microsoft.com/en-us/servicing/os/windows-11/2026/10/kb5127648-windows-11-24h2-25h2-26h2-security-update>; release health: <https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-26H2>. Zajednički **core/servicing** za 26100/26200/26300 **nije** identičan CBS/AppX state.
- UUP Dump: <https://uupdump.net/>; upstream converter `abbodi1406/BatUtil`: <https://github.com/abbodi1406/BatUtil/tree/master/uup-converter-wimlib>; UUP source/converter Git: <https://git.uupdump.net/uup-dump/misc>; arija2 input/sha: <https://aria2.github.io/manual/en/html/aria2c.html>; wimlib repo/engine reference u [Sources](BlueLite_Sources.md).
- DISM: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/what-is-dism?view=windows-11>; capabilities: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-capabilities-package-servicing-command-line-options?view=windows-11>; WinSxS cleanup: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/clean-up-the-winsxs-folder?view=windows-11>; FoD: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/features-on-demand-non-language-fod?view=windows-11>.
- NTLite dokumentacija/presets: <https://www.ntlite.com/docs/> i <https://ntlite.com/docs/presets/>; deployment/ISO: <https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options>.
- Ostali linkovi nisu nevažni: kompletan [Sources](BlueLite_Sources.md) uključuje W10UI, MSMG, Sophia, Win11Debloat, Winaero, privacy.sexy, ElevenForum, WinCert, MDL, TeamOS, GitHub, SS64, Win32 registry, PowerShell, Sysprep, Ventoy/Rufus. **Pregledaj svaku tematski potrebnu vezu u trenutku odluke; ne prihvataj uploaderovo „removed“ kao servisni dokaz.**

## 3. Lokalni operator i identiteti — šta je stvarno gde

**Trenutni canonical root:** `C:\work`. Raniji `C:\Users\Admin\Downloads\work` je **istorijska lokacija** iz avgusta/septembra, NE nova proizvodna putanja. Lokalni host je Windows i operatorski PS7 Admin (raniji original R133 transcript PS 7.6.7); proveri realni host iz najnovijeg loga. Nema dostupnog automatskog ChatGPT RDP/plugin pristupa. Rezultat dobijaš samo kada operator izvrši potpunu komandu.

| Lokalna putanja ili konvencija | Namena/ograničenje |
|---|---|
| `C:\work\scripts` | Stvarni operatorski skript paketi, pregledan `.ps1`, `.zip`, u razvojnoj istoriji numerisani `.txt` fajlovi |
| `C:\work\logs` | Trajni `.json`, `.txt`, DISM i manifest izlazi; **traži tačan filename**; ne zapisivati rutinske BlueLite logove u C root |
| `C:\work\backup` | Tačni checkpoint-i, rollback; nikad automatski brisati zaštićene originale |
| `C:\work\UUP_Source` | Zamrznuti originalni UUP kontrolni izvori/contracti; više verzija može deliti identične nazive kontrolnih fajlova **uz različit sadržaj** |
| `C:\work\E2E` | Strogo owned disposable testovi, payload, mutation WIM kandidati, audit i G4 artefakti |
| `C:\work\G5` | UUP → MAX_PRE integracioni razvoj, source-bound kandidati i R113/R133 reference |
| `C:\work\tools\aria2c.exe` | Pinned postojeći transportni izvršni fajl (SHA naveden ispod), ne skidati iznova bez stvarnog razloga |
| `C:\work\tools\UUP\uup-converter-wimlib-v127.7z` | Pinovani v127 converter arhiv; nije automatski verifikovana end-to-end kompatibilnost sa 26300 |
| `C:\work\26300.9711-UUP\26300.9711_amd64_en-us_professional_2b22470a_convert.zip` | **Immutable PRIMARY ORIGINAL** UUP Dump upravljački ZIP za 26300.9711 |
| `C:\work\UUP_Source\26300.9711_2b22470a` | S04 frozen original control files + `BlueLite_SourceContract.json` + original SHA manifest, **jedini aktivni 26300 SourceContract** |
| `C:\work\UUP_Source\26200.9550_cb4d2d02` | Stari 26200.9550 frozen fixture — zadržati kao referencu |
| `C:\work\UUP_Source\26200.9711_85096553` | Stari 26200.9711 frozen fixture — zadržati |
| `C:\work\UUP_Source\_download\26200.9711_85096553_original_uupdump.zip` | Originalni 26200 kontrolni ZIP u istorijskoj posebnoj putanji |
| `C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a` | S06 **postojeći** 26300 AppX-only verified payload i queue/Policy; ne prepisivati niti ponavljati download slepo |
| `C:\work\G5\G5_26200_9711_86D3D9215219BE64\R113_Offline_AppX_Transactional\install.appx-transaction.wim` | Istorijska zaštićena pet-AppX izvorna WIM regresija (R113), ne trenutni 26300 image |
| `C:\work\E2E\BlueLite_R91_OfflineServicing_26200.9711_85096553\install.wim` | 26200 R91 servicing base fixture; ne računaj da je aktivno montiran |
| `C:\work\extracted\install.wim`, `C:\work\mount`, stari `mount_FBConan` | Raniji primeri, **ne** univerzalni defaults; nikada mount bez dinamičkog `Get-MountedWimInfo` i izvornog manifesta |

**Owned artefakti:** svaki run manifest mora uključiti `WorkspaceRoot/FrozenUUP/OriginalWimPath/WorkingWimPath/Index/MountDirectory/CheckpointDirectory/LogDirectory/RecipeManifestVersion/ReleaseOutput`. Validirati da je cilj tačno owned; štititi izvore, R113/R133 i tuđe mount-ove. Za dnevnike koristiti datumski/step-specifična imena koja ne gaze ranije PASS. Za read-only mount koristiti `/Discard`, za novu mutaciju `/Commit` tek kad su pre/post/health/pending gates PASS. Offline registry hive alias-e unload i verifikovati **pre** unmount.

### 3.1 Životni vek podataka i restart

`C:\work` je projektni prostor; `TEMP`, DISM host log, HKLM `reg load` alias i drugi privremeni host resursi su legitimni, **ephemeral**. Ne pokušavaj da ukloniš sve host TEMP upise: zabrana se odnosi na nedozvoljenu debloat mutaciju **aktivnog Windows-a**, ne na privremene servising poslove. Kada operator kaže da gasi računar: zatvori Total Commander/Explorer, oslobodi postojeće owned hives, pregledaj `DISM /Get-MountedWimInfo`, po odluci pravilno /Commit ili /Discard, bez nasumičnog `/Cleanup-Wim` na tuđe montaže. Disposable se briše **tek kad su jedinstveni dokaz i Library/project arhiva provereno očuvani**; nikad automatski obrisati original, backup ili nedovršen jedinstveni dokaz. Ne pokreći svaki dan opštu proveru slobodnog prostora bez konkretnog storage razloga.

## 4. Inženjerska arhitektura — hibridni UUP model koji se pokazao ispravnim

### 4.1 Pre-download minimalni izbor + puna reconstruction closure + veliki offline rez

**Problem:** naivno uklanjanje velikih Windows/FoD/ESD/CAB/MSU fajlova iz UUP pre rekonstrukcije može prekinuti reference/delta mapu i WIM reconstruction; stari `UUP_PreBuild/Drafts` neuspeh (wimlib exit **55**, nedostajući `wow64_microsoft-windows-mccs-syncres.resources` zh-tw blob) je dovoljan negativni dokaz. Zaključak: **Windows original queue se ne amputira naslepo**. Windows `.ESD`, LCUs/checkpoint `KB5043080`, SSU/DU, edition, language, desktop, reference/delta, FoD, mreža, Sense i update inputi ostaju prema originalnoj source/konverterskoj zavisnosti do završenog WIM-a. `SkipEdge=1` može značiti preskakanje *integracije*, ne dozvolu brisanja `Edge.wim` iz originalnog download-a. Ne poistovećivati `.NET 3.5 OFF` sa .NET 4.8.1 update izbacivanjem.

**Sa druge strane**, iz originalnih 2.798 Apps **aria2 zapisa** filter bira nekoliko ciljnih top-level AppX identiteta i **sve stvarno potrebne manifest-derived providers**, pa se preuzimaju samo potrebni AppX/MSIX/bundle paketi. Top-level staging **pet**: `Microsoft.SecHealthUI`, `Microsoft.DesktopAppInstaller`, `Microsoft.WindowsCalculator`, `Microsoft.WindowsNotepad`, `Microsoft.Windows.Photos`. Ciljni **common-base četiri** su svi osim `DesktopAppInstaller`; MS Store/PurchaseApp/Services.Store.Engagement i AppInstaller su final-forbidden. Top-level Apps i manifest frameworks nisu isto. Pomenutih „2.798“ su queue zapisi, **nisu 2.798 korisničkih aplikacija**.

Zatim originalni pinovani UUP converter (verifikovane semantike njegovog *konkretnog* izdanja, profilnih INI opcija i index-a) sklapa Windows, integriše updates i proizvodi **immutable reconstructed `install.wim`**. Na **novoj owned disposable izvedenici**, nakon pre-mutation baseline/delta/topology, MAX_PRE izvodi skriptovani servicing-aware debloat pre *finalnog* ISO pakovanja. Odmah zatim nezavisni offline PS dovršava ostatak bez ponovnog uklanjanja već obrađenog; tek potom NTLite XML za striktno preostali handoff; u poslednjoj fazi VM online/capture i final release ISO. Initial converter ISO, ako postoji, samo je privremeni artefakt; **nije finalni BlueLite release**.

### 4.2 R15/G5: immutable i transactional pravilo

Istorijski MAX_PRE original `BlueLite_PreDebloatWim.ps1` R15-R1 (55-file pack) radi export pa `[IO.File]::Replace($exportWim,$WimPath,$backupWim)` i potom čisti transakcioni workdir. **Nikada ne predaj jedinog originalnog rekonstruisanog WIM-a kao `-WimPath`**. Ulaz R15 mora biti owned mutable derivative; original ostaje nepromenjen i hash-pinned. Pojam „komitovao je R133“ ne znači finalnu certifikaciju ili automatsko promovisanje u izvor. R49/G5 immutable promotion, R105/R107/R113/R115/R120/R122/R123/R128/R129/R130/R131/R132/R133 moraju se pregledati kao postojeće **komponente integracije**, ne koristiti svi kao proizvodni skripti u nizu. R133 potvrđuje jednu R4 transakciju u 26200, **ne** novu 26300 MAX_PRE certifikaciju.

### 4.3 Tri nezavisna sloja konfiguracije

1. **Converter-native INI** (`ConvertConfig.ini`, direktna v127 semantika za AddUpdates, Cleanup, ResetBase, NetFx3, wim2esd, SkipApps, AppsLevel, CustomList, SkipEdge/SkipWinRE gde stvarno podržano). Originalni ZIP je immutable; politika ide u nov staging overlay, nikad edit originalnog ZIP-a bez zaštićene kopije.
2. **BlueLite policy/profile** (`*.json`, `CustomAppsList`, allow/keep patterns, engine flags, dependency provider gate, immutable source/working WIM manifest). Ovo je pravo mesto za build-independent pravila.
3. **Windows `unattend.xml` / `offlineServicing.xml` i NTLite XML** imaju ograničene, različite uloge. Answer-file nije univerzalna zamena za `Remove-Capability`, CBS owner lifecycle, provider graph ili DISM post-health. NTLite XML je poseban kasniji component-engine profil, ne slobodna mutacija u Stage1.

## 5. Potvrđena obnova kratkotrajnih Microsoft UUP download URL-ova — CENTRALNO PRAVILO

**Razdvojiti tri nepromenljive stvari od promenljive četvrte:**

- **Originalni operator UUP Dump ZIP**: autoritet build/UUID/edition/language, launcher, `ConvertConfig`, `CustomAppsList`, manifest i SHA-256. Ne prepisuje se zbog URL isteka.
- **Zamrznuti originalni sadržaj queue-a**: Windows/Apps set datoteka, za svaku relativni `out=` naziv, tip algoritma (`sha-1`, `sha-256` kako izvor zaista deklarише) i checksum/digest, svi sa jedinstvenim output imenima i validnim izlaznim path-om. Ovo je **content identity**.
- **UUP payload fajlovi**: postojeći već dobijeni bajtovi; pri resume-u potvrđuje se deklarisani hash, ne pretpostavlja validnost prema nazivu.
- **Privremeni URL**: `https://tlu.dl.delivery.mp.microsoft.com/...` signed transport link iz UUP Dump `get.php` queue-a, sa `P1` epoch istekom i mogućim tokenima. On se **mora i može obnoviti** kroz originalni, tačno isti UUP Dump UUID/endpoint; URL promena sama nije promena paketa.

**Izvorna ulazna dva endpoint-a izvedena iz netaknutog launcher-a** za konkretan S01 26300.9711 izvor:

- Windows: `https://uupdump.net/get.php?id=2b22470a-8b6f-498f-9c88-66f7b9fb56b1&pack=en-us&edition=professional&aria2=2`
- Apps: `https://uupdump.net/get.php?id=2b22470a-8b6f-498f-9c88-66f7b9fb56b1&pack=neutral&edition=app&aria2=2`

Za **sledeći** 26300 izvor URL se **dinamički izvodi iz njegovog originalnog launcher-a**, nikad ne ostaje ovaj UUID. Podržavati više alternativnih HTTP(S) URL-ova u *jednom* aria2 zapisu i očuvati njegove `out=`/`checksum=` opcije. Ne štampati pune potpisane URL-ove/tokene u javne logove. Proveriti HTTPS i očekivane source endpoint host/path/tuple pre upotrebe, bez slepog praćenja redirect-a. S02-R1 je popravio prvobitni stroži parser koji je padao na multi-URI format; S05 D4 modul je to testirao 14/14 starim fixture-ima plus pozitivnim i negativnim multi-URI/digest slučajevima.

**Postupak G2/G3, primenjiv pri svakom preuzimanju i resume-u:**

1. Originalni `Windows.original` i `Apps.original` queue + content-identity hash **zabeleži jednom**, read-only frozen ledger. Drugi, *nezavisni* `active` queue je samo transport.
2. **Just in time pre prvog UUP payload transfera** (i pri resume-u kad transport istekne) zatraži DVA mala aria2 `get.php` metadata odgovora za isti zamrznuti source UUID/pack/edition; preuzimanje tih metapodataka **nije** GB payload download.
3. Parsiraj `out`, checksum algoritam/digest, multi-URI host i record count; odbaci missing/duplicated/unsafe output, unknown protocol, nedostajući hash, format/drift izvan definisanih pravila.
4. Uporedi **Windows full 98/98** i Apps full 2798/2798 **multiskup sadržajnih identiteta** sa **nezavisnim** frozen S02 originalnim ledgerom. Jednak broj fajlova ili jednak naziv nije dovoljан. Ako je bilo šta promenjeno → `HOLD_SOURCE_PAYLOAD_IDENTITY_DRIFT`, bez download-a. Ne poredi SHA256 celog `aria2` teksta ako se očekuje rotacija signed URL-a: sirovi fajl se sme promeniti, content identity **ne sme**.
5. Osveži samo `active` signed transport polja, zadrži zaseban originalni ledger i provenance. Odaberi proverenu AppX seed podskupovu listu; G4 iz manifest izvora iterativno dodaje stvarno potrebne frameworks/bundle providers, proverava publisher/minver/arch i izvorni hash, i odbacuje nerešenu zavisnost. **Windows queue ostaje kompletan za full rekonstruisanje.**
6. `aria2c` uz `--check-integrity` / checksum i podržanu resume politiku čuva već preuzete ispravne pakete. Ako remote signed URL ponovo istekne, osveži ponovo **samo transport** nakon identitetskog gate-a. Ne resetovati i ne duplicirati ceo cache. Ako checksum padne, stvarno preuzeti payload nije PASS bez opravke i nove provere.

**Dokaz, ne samo ideja:** R26-D4 G2/G3 implementirao original-vs-active i URL refresh bez menjanja out+checksum; R26-D5 dodao strogu provider zavisnost, D6 integrisao oba. Raniji R33 native remote test proverio stvarni queue renewal i dva mala aria2 transfer/resume; 26200 D6 proverio AppsOnly 32/32. **Na primarnom 26300.9711:** S02-R1 original Windows 98/Apps 2798, S05 D4 14/14 + multi-URI negativni digest, a S06 **stvarno ponovo pribavio oba live queue-a i potvrdio identične 98/2798 content fingerprint-e pre AppsOnly preuzimanja**, zatim 32/32 SHA-app closure PASS. Zbog toga je mehanizam URL obnove **VERIFIED_26300 za queue renewal i AppsOnly download**, ali **full Windows download/resume i converter još nisu verified 26300**.

**Relevantne reference:** [Current S02–S06](BlueLite_Current_Status.md), [Evidence G2/G3/G4](BlueLite_UUP_Evidence_Reconciliation_20261013.md#g2-r26-d2s-terminal-windows-queue-check-uses-the-same-file-as-active-and-original), originalni Library `BlueLite_R28_Real_UUPDump_QueueProbe.ps1`, `BlueLite_R33_Real_Aria2_Transport_Smoke.ps1` + `.txt`, `BlueLite_R26_D6_Germanium_Source_Audit.txt`, originalni D6 ZIP, S05 i S06 review ZIP; <https://aria2.github.io/manual/en/html/aria2c.html>. **Nikad ne mešati originalni source ZIP, već preuzeti payload i privremeni HTTP URL.**

## 6. Trenutni PRIMARY 26300.9711 — već potvrđeno S01–S06 (snapshot 2026-10-17)

**Uvek prvo proveri Current za noviji status, pa tek onda ovaj snapshot.** Početne stare UUP Evidence tvrdnje `26300_UUP_EVER_DOWNLOADED=NO` bile su **tačne na 2026-10-16 pre S01**, sada su **superseded**: *kontrolni ZIP i stvarni AppsOnly payload jesu pribavljeni*, dok puni Windows UUP, v127 conversion i MAX_PRE **nisu izvršeni**.

| Faza | Pravi dokaz i podaci | Završna klasifikacija |
|---|---|---|
| **S01** Source freeze | ZIP 8,218 B; SHA `D3E7162605A61D8A0FD62E1738DE523B52B36059D6AAC8F756F90AEFCB64C4A2`; UUID `2b22470a-8b6f-498f-9c88-66f7b9fb56b1`; original 11 fajlova | `VERIFIED_26300_SOURCE_IDENTITY` |
| **S02-R1** independent queues | Original Windows **98**, Apps **2798**; raw SHA Windows `AC302ADEF6AC5AED61B927BBBC4DDA0D091D547027C9C6D1B1B811C902880E93`, Apps `E238008DF4D643B320E78C4EE79CB6C59F3D372254FA49279E003BBB26EE8CA1`. `HOLD_SIGNED_URLS_EXPIRED_OR_EXPIRING` samo za stare URL-ove | `VERIFIED_26300_FROZEN_QUEUES`, URL reset JIT |
| **S03-R1** v127 converter archive | `C:\work\tools\UUP\uup-converter-wimlib-v127.7z`, SHA `F0FD93C62DAAF703F69B0DE8FA37953FE3EC0DBB7D99BCD295BCD5C3FA64692A`; official Git raw fallback (stari uupdump.net/misc endpoint 404) | `VERIFIED_26300_TOOL_ACQUISITION_ONLY`, **konverter nije pokrenut** |
| **S04** SourceContract | `C:\work\UUP_Source\26300.9711_2b22470a`, 11/11; contract SHA `08C05398AD37DB6FE0A58714D7F31B7C02A52CC91AFE3779402DB9CD1B2FEDEA`, original manifest SHA `FF335E84B83F3C44501FAA7B50FBDEAB309528F2CA96F9A0BCC92A01AF67DB20`; existing `aria2c.exe` SHA `B9CD71B275AF11B63C33457B0F43F2F2675937070C563E195F223EFD7FA4C74B` | `VERIFIED_26300_FROZEN_CONTRACT` |
| **S05** D6/D4 26300 adapter | Original R26-D6 ZIP SHA `80807FFFDE870084A3B37A3F773C058532B6FDA03400E12AE8A09BFE2FABBA79`, source adapter SHA `14D605D1827B38166449EE6ED36D62945C24C327ECC9C44182B9FDB629071F50`; 14 original fixtures PASS; multi-URI checksum negative PASS; D6 explicit-source Audit PASS | `VERIFIED_26300_SOURCE_AND_QUEUE_AUDIT` |
| **S06** AppsOnly / G4 | S06 adapter ZIP SHA `539D72F6D2DCA9CDC875D984FD00314F9BAAA4BCED9BDFA65B621EAE44ADBF03`; real operator G4 result `PASS_26300_APPS_ONLY_G4_STRICT_CLOSURE`; **27 seed → 32 closed/hash verified files, 115,765,780 B (~110.404 MiB)**; Windows UUP payload downloaded=0 | `VERIFIED_26300_APPS_ONLY_G4_NATIVE_PASS`, **nije full download/WIM release** |

**S05/S06 zamrznuti content-identity fingerprint-i (nisu SHA sirovog URL-teksta):**

- Windows 98: `07EB7120FC7B41001D0FA4E71213D6EB03901A0CDAAA951F8BF90D2D21B61C06`.
- Apps 2798: `DF2747330DB66B5ACB8398EDF8DC29BDC22F3F80FA3088C005131324B5A5C566`.
- S06 obnovljeni raw active queue hashovi **namerno drugačiji** zbog tokena: Windows `2DCD9C90B1FF0DA5041114502CE2906E519962B80A572FBF4C22EC87F23C237B`, Apps `FFE480553CA5CB9282B1603095E3730E26B6962CF9F384554F150AEC44FAC576`. Originalni identity **PASS exact**.

**S06 originalni logovi za operatora, otvoreni i međusobno provereni:**

- `C:\work\logs\BlueLite_Stage1_S06_26300.9711_D6_AppsOnly.txt` — `SOURCE_SELECTION=EXPLICIT_FROZEN_ROOT`, `S06_LIVE_QUEUE_REISSUE=PASS_S02_EXACT_PAYLOAD_98_2798`, `WINDOWS_AND_APPS_TRANSPORT_RENEWAL=PASS_PAYLOAD_IDENTITY`, `SEED_APPS_QUEUE_COUNT=27`, `CLOSED_APPS_QUEUE_COUNT=32`, `APPS_ONLY_ACTUAL_CLOSED_AND_HASHED=32`, `APPS_ONLY_CLOSED_BYTES=115765780`, `R26_D6=PASS_APPS_ONLY_INTEGRATED_PRODUCTION_BRANCH`.
- `C:\work\logs\BlueLite_Stage1_S06_26300.9711_AppsOnly_G4.json` — `PASS_26300_APPS_ONLY_G4_STRICT_CLOSURE`, 32/32, 115765780 B, original untouched, no WIM/converter/full Windows. Timestamp `2026-10-17T04:01:19.1193361Z`.
- `C:\work\logs\BlueLite_Stage1_S05_26300.9711_D6_Audit.txt`; `...S05_26300.9711_D6_Adapter.json`; S01–S04 receipt-i analogno.
- **Dodatni report za granularni G4 provider graf**, ako je potreban pri serijskom runtime certificiranju: `C:\work\E2E\BlueLite_Stage1_S06_26300_9711_2b22470a\Queues\ResolveAppDependencies.log`. Ovaj zasebni log nije bio dostavljen uz dva završna S06 fajla: ne pretvarati 32−27=5 u izmišljenu listu tačno pet zasebnih framework identiteta.

**D6 log još sadrži** `DRAFT_NOT_RUNTIME_CERTIFIED=TRUE` / `DRAFT_DOWNLOAD_PATH_NOT_RUNTIME_CERTIFIED=TRUE`, što se odnosi na **celi** istorijski downloader / konverzioni lanac, a ne poništava ograničeni **stvarni S06 AppsOnly PASS**. Full 26300 Windows `Download` mode ostao je namerno zabranjen u S06. **Nema 26300 install.wim, final ISO, NTLite ili VM runtime rezultata.**

### 6.1 Konkretni postojeći fajlovi — ne praviti ih ponovo

Na operatorskom hostu `C:\work\scripts` nalaze se prethodno dostavljeni S04/S05/S06 skript paketi; njihove hashove i tačnu verziju proveriti pre poziva. Za S06 ZIP: `BlueLite_Stage1_S06_26300_G4_AppsOnly.zip` (16 ZIP članova, 14 u SHA manifestu) sadrži modifikovani **D6 main**, originalne D4/strict G4/filter/verify/module fajlove, `BlueLite_Stage1_S06_26300_AppsOnly.ps1`, README, manifest. S05 ZIP analogno sadrži adapter i pozitivne/negativne fixture-e; originalni D6 review ZIP je na operatorskom hostu i u Library. **Ne pisati novi downloader, resolver ili URL-renewer od nule** bez specifičnog dokaza da taj modul ne može da podrži sledeću izmenu.

## 7. Dokazna mapa istorijske 26200 baze koju MORAMO da prenesemo, ali provereno

### 7.1 UUP/Stage1 istorija i izvori

| Poreklo | Primarni Library skripti/logovi | Šta je zaista dokazano | Prenos na 26300 |
|---|---|---|---|
| `/UUP_PreBuild/Drafts`, 26200.9278, 26200.9445 | `Timeline-04-09-26.txt`, `Timeline-06-09-26.txt`, `Error_Timeline.txt`, `Timeline-10-09-26.txt`; originalni `uup_download_windows.cmd`, `ConvertConfig.ini`, `CustomAppsList.txt` | Stara destruktivna Windows queue removal greška wimlib **55**; potreba kompletnih delta/reference | `VERIFIED_26200_TRANSFER_CANDIDATE` negativni gate; za 26300 confirmed policy full Windows input |
| `/BlueLite_v1.0/Custom_UUP`, `/Final_UUP` RC1.2 26200.9445 | `BlueLite_UUP.cmd`, `BlueLite_ResolveUUP.ps1`, `BlueLite_Bootstrap.ps1`, `BlueLite_FilterApps.ps1`, `BlueLite_ResolveAppDependencies.ps1`, `BlueLite_GenerateCustomAppsList.ps1`, `BlueLite_VerifySource.ps1`, `BlueLite_DebloatFinalWim.ps1`, `FinalWimDebloat.log`, `Timeline-14-09.txt` | Stvaran 26200 UUP→WIM; 69 AppX candidates, **5 top-level keep / 64 off**, **30 offline actions**; WIM `6,547,002,104 → 6,209,369,921` B | Reuse architecture; novo 26300 WIM/health/target-specific recipe tek čekaju runtime |
| R19–R25 source/resume | R19/R20 188/188 original UUP SHA, R26-D1/D2/D3, R56 engine interlocks, Phase A2 `UUP_V3_PhaseA2_AcquireSource_20261005_154849.txt` | Source freeze/identity/2 tree equality; R56 210 static interlocks i `exit /b 86` deny-only | Ne pokretati 200-site forenziku; preneti proverena pravila, otkloniti samo novo usko ograničenje |
| R26-D4/D5/D6, R28/R33, R84 | `BlueLite_DL_R26_D6_REVIEW.zip`, `BlueLite_QueueIdentity.psm1`, `BlueLite_R26_D4_QueueFixture_Test.ps1`, `BlueLite_ResolveAppDependencies.ps1`, `BlueLite_R28_Real_UUPDump_QueueProbe.ps1`, `BlueLite_R33_Real_Aria2_Transport_Smoke.ps1`/`.txt`, `BlueLite_R26_D6_Germanium_Source_Audit.txt` | D4 G2/G3 signed URL obnovu sa invariantnim `out+checksum`; D5 strict G4; D6 26200 AppsOnly 32/32 (~115,777,070 B); R33 stvarna dva mala transfer/resume | **VERIFIED_26300** do S06 queue+AppsOnly; full Windows UUP i converter još testirati |
| R100/A01/A02/A03 | `BlueLite_R100_E2E_UUP_Pair_SHA_Audit_26200.9711_85096553.csv` (129), `BlueLite_R100_R1_9550_RootUUP_SHA_Audit_26200.9711_85096553.csv` (98), Storage_A01/A02/A03 logs | 227/227 SHA parova, 92/98 zajedničkih 26200.9550→9711 SHA; autorizovano brisanje duplog R132 artefakta; sačuvan R133 | Izbegni ponovo 227+ downloads i analiziranje iste kompresije; ne proglasi 26300 paket identičnim |
| R105/R107/R113/R115/R120/R122/R123/R128–R133 | `BlueLite_Stage1_Germanium_R133_IntegratedSource.zip`, `BlueLite_R120_Germanium_UUP_Production_Source_Handoff.ps1`, R122 Compatibility, R123 ProductionContract, `BlueLite_R128_MAX_PRE_Germanium_R4R7_Resolver.ps1`, R129–R133 selftests/transcripts | Pre-ISO MAX_PRE integraciona arhitektura; R113 pet AppX, R133 **R4 physical AppInstaller disposable PASS**. R7 i full MAX_PRE i dalje target dependency HOLD | Ciljana source adaptation; **ne** proglašavati R133 runtime globalnim 26300 MAX_PRE PASS |

**26200.9711 UUP transport brojke (nisu 26300 ili final ISO):** 129 ukupnih izvora ≈8,367 GiB (98 Windows plus odvojena Apps selekcija); MSU ≈4,944 GiB, ESD ≈2,307 GiB, CAB ≈0,843 GiB, AppX ≈107,4 MiB, Edge.wim ≈171,85 MiB. KB5127648 MSU oko **4553,84 MiB** je servicing input, **ne 4,5 GiB neto dobiti u finalnom ISO-u**. Za sledeći 26300 source izmeriti samo delta naspram poznatog fingerprint-a; ne imputirati ove istorijske transport veličine. Originalna analiza u Library: `BlueLite_Germanium_UUP_MAX_PRE_Analiza_2026-10-16.md` (pored `FBConan-BUILD_INFO.txt`, `FBConan-BUILD_INFO-v3.txt`, `Extreme-11-26H2-Removed.txt`).

### 7.2 R133 i AppInstaller — izdvojena važna offline debloat referenca

R113 source 26200.9711 pet provisioned Apps je očuvan kao protected baseline. Na R133 **owned disposable** kandidatu tačno R4 AppInstaller (četiri fizička WindowsApps package root-a) prošao je jednu **native post-commit** transakciju: prije `APPX=5`, **740 hardlink owner** dokaza, exact offline registry marker leaf (0 children / 0 values), pravilan hive unload i lifecycle; posle `APPX=4`, **nula** AppInstaller roots, CBS `CLEAN`, pending `0`, unmount `/Commit`, sve mount/hive reference oslobođene. Kandidat SHA `7B94D33551A69942FB41EB90B073E86143D61677AE348ED71D215EB03E8B875B`. Zasebna `BlueLite_R133_R4_PostCommit_ReadOnly.txt` potvrdila je iste četiri keep apps i nula root-a, R7 i dalje **installed/block**. **`R133_RELEASE=NOT_CERTIFIED`; R4 PASS samo za disposable izvor/topologiju**.

Originalni relevantni Library fajlovi: `BlueLite_R133_R4_26200_9711_Console.txt`, `BlueLite_R133_R4_26200_9711_Transaction.txt`, `BlueLite_R133_R4_PostCommit_ReadOnly.txt`; izvorne skripte `BlueLite_R126_R2_R113_R4_AppInstaller_Transactional.ps1`, `BlueLite_R125_R113_AppInstaller_ShortMount_OwnerGate.ps1`, `BlueLite_R4_Transactional_R130.ps1`, `BlueLite_R132_to_R133_Marker_RegistryAPI.diff`. Master §17 čuva još ranije 26200.9445 **Batch 18C-D/E / Phase 44–48**, kad je native AppInstaller removal odbio `15610/0x80073CFA`, a egzaktan lifecycle + guarded unique physical removal uklonio 740 fajlova / 148,137,728 B, bez CBS/pending problema. **NIKADA** ne primenjuj R133 hardkodovane root verzije ili SID na 26300: otkrij stvarne package families, SIDs, offline AppX policy i link ownership. Ne briši globalni `EndOfLife/Deleted-EndOfLife` ili SQLite `StateRepository` radi prečice.

### 7.3 Language.Basic/R7 i FoD — dokaz blokade, ne izgovor za odustajanje

`Microsoft-Windows-LanguageFeatures-Basic-en-us-Package-amd64.cab` je na istorijskom 26200.9711 odgovarao realnom FoD paketu sa **~44,34 MB / tri CBS packages**, nasuprot **0 B** u ranijoj 26200.9445 varijanti. Native R115 removal kod određene R7 putanje je prijavio **`0x800F0825`**, zbog čega je status `RED_HOLD` za **taj** trenutni build/topologiju, dok je R4 nezavisno obrađen. Pregledana su R127/R134–R142: read-only `Language.Basic` delta, MUM/CAT/CBs package state, offline SOFTWARE registration, reverse MUM, child component XML i WinSxS surface, COMPONENTS structure. **R142 nije automatska dozvola za raw carve; R7 remains BLOCKED** u R133 post-commit. Za 26300, proveri stvarno capability/package owner/health stanje *jednom, ciljano*; ako odgovara poznatoj varijanti, primeni odgovarajući postojeći disposition, inače kreiraj novu izolovanu dependency varijantu. **Client Language Pack en-US KEEP**.

Library primeri: `BlueLite_R127_R7_LanguageBasic_9711_ReadOnly_Delta.txt`; `BlueLite_R134_R7_CBS_Metadata_26200_9711.txt`; `BlueLite_R135_R7_CBS_ChildIdentity_26200_9711.txt`; `BlueLite_R136_R7_ChildServicing_26200_9711.txt`; `BlueLite_R137_R7_CBS_PackageState_26200_9711.txt`; `BlueLite_R138_R7_CBS_Registration_26200_9711.txt`; `BlueLite_R139_R7_ReverseMUM_26200_9711.txt`; `BlueLite_R140-R1_R7_ComponentXML_26200_9711.txt`; `BlueLite_R141_R7_ComponentWinSxS_26200_9711.txt`; `BlueLite_R142_R7_COMPONENTS_Structure_26200_9711.txt`. Ostaju kao istorijski izvor i intelligence, ne ponoviti niz R134→R142 naslepo.

## 8. Offline debloat: logičke klase recepata, koraci i 26300 uslovi

Master [§20](BlueLite-Master_Germanium_Strategy_final.md#20-validated-intelligence-snapshot-as-of-2026-09-29) je najprecizniji sažeti `Component Intelligence` indeks. Pravilnik nije vezan za imena builda već za `installed/capability/owner/WinSxS/hardlink/manifest/service/health` predikate. Sledeći pregledi su **26200 proven, 26300 TARGET-SPECIFIC VERIFY**, osim odvojeno potvrđenog S06 AppX sourcing-a.

### 8.1 Predloženi klasifikacioni izlazi

- **GREEN**: dokumentovana native DISM/PowerShell operacija sa malim blast-radiusom i potpunim postojećim pravilom; može `PRODUCTION_RULE` posle target-state/health gate-a.
- **AMBER**: owner/topology-aware native ili kontrolisani servicing-consistent engine; prvo normalna native putanja, zatim egzaktan owner/certifikovana alternativa; provera **pre/post CBS Installed/Staged/Superseded, WinSxS, hives, hardlink, health/pending**. Reuse samo uz matching topology.
- **RED**: shared/permanent/protected/metadata/unsigned ili nerešena owner zavisnost; `RED_HOLD` / `KEEP_SKIP` ili izričit `COMPONENT_ENGINE_HANDOFF`, ne sirovo brisanje. Novi stvarni topology delta ide kroz izolovan disposable test.
- Release dispozicije su odvojena osa: `PRODUCTION_RULE`, `KEEP_SKIP`, `COMPONENT_ENGINE_HANDOFF`, `RED_HOLD`. Ovaj izbor mora biti naveden u evidence/recipe record-u.

**Post-state je autoritet.** DISM exit 0 ili file absence nije sam po sebi `CBS CLEAN`. Precizna release provera uključuje package/capability/feature/AppX state, servisni intent, pending 0, `CheckHealth`, procenjen `ScanHealth` prema riziku, pravilan hive unload, OS funkcionalnost i izmerene jedinstvene bajtove. Pri raw carve koja daje component-store `Repairable`, rezultat je NOT PASS bez obzira na uštedu. DISM `/Get-Packages` globalno može propustiti konkretan owner target: proveri offline registry/Servicing Packages kada treba.

### 8.2 Reuse matrica poznatih target-a

| Logički target | Potvrđen istorijski dispozitiv | Osnovni poznati metod / zaštićena zavisnost | 26300 klasifikacija pre izvršenja |
|---|---|---|---|
| Recall/AIX | `PRODUCTION_RULE` | Portable AMBER feature/AI state closure; ne brisati shared Client.CBS | `VERIFIED_26200_TRANSFER_CANDIDATE` — otkriti 26H2 feature/PFN/owner |
| AppX + Store ecosys | `PRODUCTION_RULE` | 5 staging → 4 common keep; Store/Purchase/Engagement/AppInstaller final absent; framework providers iz stvarnog manifesta | **S06 SOURCE/G4 VERIFIED_26300**; offline removal `REQUIRES_26300_IMAGE_TEST` |
| Edge integration | converter policy candidate | v127 `SkipEdge` semantika, ne delete `Edge.wim` pre closure | `REQUIRES_CONVERTER_V127_RUNTIME` |
| Edge WebView FoD | `PRODUCTION_RULE` | `DISM /Remove-Capability` na egzaktno instaliranoj verziji; shared WebView2StandAlone posebno | `REQUIRES_26300_CAPABILITY_STATE` |
| WebView2StandAlone | `COMPONENT_ENGINE_HANDOFF` | Preširok shared owner; ne naterati broad package/carve | `BLOCKED_BY_DEPENDENCY` dok engine/preset target ne bude sertifikovan |
| DirectX Configuration Database | `PRODUCTION_RULE` | Exact native `Remove-Capability`; DirectX helper/updater ostaje za component engine | `REQUIRES_26300_CAPABILITY_STATE` |
| Kernel LA57 | `PRODUCTION_RULE` | Exact native `Remove-Capability`; ne broad LA57 setup helpers | `REQUIRES_26300_CAPABILITY_STATE` |
| Language.Basic en-US | 26200.9445 `PRODUCTION_RULE`, 26200.9711 **R7 `RED_HOLD`** | 26300 owner variant prvo klasifikovati; Client Language Pack KEEP | `KNOWN_VARIANT / R7_HOLD` dok novi target nije proveren |
| FoDMetadata superseded main / core | `PRODUCTION_RULE` pod uslovima | Native exact Remove-Package; core exact self-owner AMBER decouple; wrapper/current servicing metadata KEEP | `REQUIRES_26300_EXACT_CBS_OWNER` |
| Desktop-CompDB | `KEEP_SKIP` | Servicing/capability-provider granica | `PROTECTED_BY_DEPENDENCY` osim novog operatorovog ugovora |
| OneDrive Setup package + WOW64/old staged | `PRODUCTION_RULE` | Portable AMBER exact ordering/owner, OneDriveBackup residue handoff | `REQUIRES_26300_TOPOLOGY` |
| SearchEngine wrapper / srchadmin | `PRODUCTION_RULE` | Portable AMBER wrapper; WSearch disabled; remaining physical Search set handoff | `REQUIRES_26300_TOPOLOGY` |
| XPS residual | `COMPONENT_ENGINE_HANDOFF` | Native removal exhausted/no-op, broad CBS carve rejected | `BLOCKED_BY_DEPENDENCY` |
| Internet Printing Client | `KEEP_SKIP` | Disabled; no physical payload, metadata servicing | `VERIFY_TARGET_ABSENCE` |
| LPD/LPR neutral packages | `PRODUCTION_RULE` | Exact-owner AMBER physical-removal certificates | `REQUIRES_26300_OWNER` |
| Sense / SenseClient FoD | `COMPONENT_ENGINE_HANDOFF` | Native fails, raw carve → component store Repairable; Defender ON floor | `BLOCKED_BY_DEPENDENCY`, no blind WinSxS deletion |
| UserExperience-AOT, CoreAI, AIFabric | `COMPONENT_ENGINE_HANDOFF` | Shared CBS/SystemApps/AOT ownership; DiscoveryHub inside `Client.CBS` not standalone servicing package | `REQUIRES_26300_OWNER`, NTLite only later |
| Selected Hyper-V / VMMS / Worker / ComputeHost / Vmbus child etc. | Some `PRODUCTION_RULE` with individual certificates | Precise owner/predicates; never remove VM-host protected floor | `REQUIRES_26300_FLOOR_AND_OWNER` |
| Defender ON/OFF | **planned release branching**, not common removal | Defender ON common base; OFF only exact allow-list; never wildcard Wd* | `REQUIRES_BRANCH_AND_VM_RUNTIME` |

**Script/reference patterns to search in Library**: `BlueLite_R4_Transactional_R130.ps1`; `BlueLite_R128_MAX_PRE_Germanium_R4R7_Resolver.ps1`; original R15 `BlueLite_PreDebloatWim.ps1`; RC1.2 `BlueLite_DebloatFinalWim.ps1`; september Phase18C-D/E, Phases44–48 logs; `FBCONAN 48–54` original offline AppX tables; `338-Canonical-FodMetadata-Superseded-PreProduction-Gate.txt`, `339-R1-Canonical-FodMetadata-Superseded-Native-Production-Removal.txt`, `342-R1-Canonical-OneDrive-AMBER-PreProduction-Gate.txt`; `Release05_CommonBase_Certification`, `100-Sense-Carve` negative tests, R91–R142. Često su imena u Library numerisana/sa sufiksom `(1)`; pronađi tačan aktuelni fajl i hash, ne rekonstruiši po sećanju.

### 8.3 Minimalna 26300 offline image delta-provera

Po prvom stvarno rekonstruisanom 26300 WIM-u (i zasebnom immutable hash-u), jednom ciljano pribaviti: `DISM /Get-WimInfo`/index/edition/build, `/Get-Packages`, `/Get-Features`, `/Get-Capabilities`, provisioned Apps i postall-user provision provider state, CBS `Servicing\Packages` i `COMPONENTS` owner gde potrebno, WinSxS manifest/hardlink za AMBER, `AnalyzeComponentStore`, pending/reboot, `CheckHealth` (i ScanHealth prema riziku), zaštićeni VM-host/storage/network/security floor. **Ne prikupljati ogromne logove ako identičan prethodni evidence + fingerprint dovoljan**; jedan delta report ide Component Intelligence. Pre prve mutation izaberi `UNCHANGED/VERSION_CHANGED/ALREADY_ABSENT/KNOWN_VARIANT/UNKNOWN_TOPOLOGY` za svaki ciljni recipe; izvršavaj known recipes i zadrži jasnu blokadu za mandatory unknown.

### 8.4 Servis/registry/Windows Update profile

Common-base čuva `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, `BITS`, `CryptSvc`, `TrustedInstaller` zbog CBS/update/Defender ON/korisničkog **Resume/Pause**. `WSearch` i `SysMain` mogu biti disabled prema sertifikovanom profilu. Windows Update **Pause do `2100-12-31T23:59:59Z` uz funkcionalan Resume i ponovno Pause**; native `SetMaxPauseDays=35` ne menjati grubo da bi korisnik izgubio Pause mehanizam. Korisnički cilj „disable/trim Windows Update“ je limitiran ovim eksplicitnim recentnim Master shared serviceability floor-om: očuvati zavisnosti, ne amputirati kompletan servicing engine. Telemetry/Recall i first-run consumer naglasci kroz validiranu offline policy/tweak granu. Finalni desktop sadrži opcionalne `.reg`, `.msix`, installers, repair helpers i enable/disable pakete umesto trajnog zadržavanja neobaveznih payload-a.

### 8.5 Defender + VMware/VirtualBox HOST contract

Common base **Defender ON** dok ne prođe certificirana zajednička baza; nakon toga kopije/grane. OFF tačan ograničen allow-list: `MDCoreSvc`, `WinDefend`, `WdNisSvc`, `WdNisDrv`, `WdBoot`, `WdFilter`, `Sense`; bez `Wd*` wildcard-a i bez neselektivnog uklanjanja `SecurityHealthService`, `wscsvc` ili `SecHealthUI`. Physical CBS Defender/Sense carve nije deo implicitnog OFF profila.

**End-user OS mora moći da INSTALIRA i HOSTUJE VMware Workstation/VirtualBox i VM drivere kasnije, ne samo da se izvršava kao VirtualBox guest za QA.** Trenutno poznati protected floor: `WinHvPlatform.dll`, `hvax64.exe` (AMD/SVM), `hvix64.exe` (Intel/VT-x), `vmbus.sys`, `vid.sys`, `ndis.sys`, `netio.sys`, `tcpip.sys`, `storport.sys`, `disk.sys`, `partmgr.sys`. Stvarni 26300 ownership mora se dinamički ponovo razrešiti; ne čuvati sav Hyper-V po automatizmu, ali ne ukloniti host neophodan WHP/driver install/virtual NIC/storage/network/service/path. Potrebni su stvarni host-drivers+guest-boot/network/disk/reboot testovi **oba Defender branch-a na odgovarajućem fizičkom host-u ili validnoj nested virtualizaciji**. VM guest boot sam po sebi nije taj test.

## 9. Izuzetno važni negativni dokazi — već rešene „slepe ulice“

1. **UUP queue prune** Windows/FoD/ESD reference pre converter closure → 26200 wimlib exit **55**. Ne ponavljati destruktivno filtriranje jer fajl deluje opciono.
2. **`Remove-Package` broad CBS parent, raw WinSxS carve** dok state Installed i hardlink/shared owner još služi drugima → `Repairable` ili pending; `CheckHealth=CLEAN` samo po sebi nije dovoljno za novu AMBER mutaciju. Nema globalnog `COMPONENTS` registry carve-a.
3. **Sense** native capability failure/physical deletion pokazali Repairable; `COMPONENT_ENGINE_HANDOFF`, ne „isti pokus još jednom“.
4. **Shared Client.CBS DiscoveryHub** nije samostalni DISM servisni paket; embedded AppX AOT/Windows SystemApps se ne rešava brisanjem `DiscoveryHubApp.exe`/shared `appxmanifest.xml` hardlink površina.
5. **AppInstaller** native DISM `15610/0x80073CFA` na jednoj 26200 topologiji nije univerzalna zabrana; potvrđeni exact R133 R4 lifecycle/poststate je bolji target-specific precedent, ali ga ne kopirati u 26300 bez re-resolve i neg fixtures. Ne raditi globalni `EndOfLife`, `StateRepository` SQLite surgery.
6. **R7 26200.9711 `0x800F0825`** + tri child CBS paketna entiteta: old 26200.9445 0-byte cleanup nije prenosiv bez topology. R142 nije „permission“ za remove.
7. **R15 static source / R122 source audit / 26200 R113 R133** nisu dokaz univerzalnog 26300 download→converter→MAX_PRE, niti je S06 dokaz finalne četiri provisioned Apps u izgrađenom WIM-u.
8. **NTLite** prerano i ručni screenshot preset duplira offline PS i blokira stvarnu univerzalnost. Nemoj preskakati Stage2 niti zamenjivati predicate output slepim klikom.
9. **WIM solid/LZMS/NTFS compact** može maskirati stvarni payload. FBConan 26200.7019 ≈2.845 GB *solid/recovery two-index* WIM i ~17.17GB logički per-index nisu dokaz identične fizičke uštede. Njegov `CheckHealth=repairable` nije naš release cilj. `CompactOS:Query` nije dokaz isto kao SetupComplete `compact /exe:XPRESS8K`. Poredi više metrika.
10. **Old converter URL 404** (S03) nije razlog za pravljenje novog konvertera; v127 official Git raw SHA već PASS. **Istek potpisanih Microsoft URL-ova** nije korupcija/izmena originalnog UUP ZIP-a: obnovi samo signed transport prema frozen content ledgeru.
11. **PowerShell source engineering**: PS7 AST/parser 0 errors; ne koristi `$Matches` kao korisnički rezervisan lokalni name bez kontrole; izbegavati `h` alias (Get-History), never assume property `.Count` on scalar, guarded `Get-Item` hash/PSObject, exact `Start-Process` exit and no empty pipe. Predlozi „hotfix 2/3/4“ imaju istorijske failed/working revizije; nađi konačan actual PASS i hash.
12. **Mount/Hive stale handles**: ranije BL100 INVALID mount / `HKLM\BL100_SOFTWARE_*` i BL103 unload access denied, FB77COMPONENTS handle, R131 mount recovery. Pre novog mount-a: proveri `Get-MountedWimInfo` i tačno alias, oslobodi zadatkom owned hive; ne menjaj živu host registry semantiku zbog offline-a.

## 10. Prenosivost 26200 → 26300, bez preuveličavanja

| Sloj / tvrdnja | Trenutni status | Dokaz ili naredni uslov za promociju |
|---|---|---|
| 26100/26200/26300 shared-core i servicing branch | `VERIFIED_PLATFORM_FACT` | Microsoft KB5121794/KB5127648/26H2 IT Pro, ali pojedinačna target topologija nije garantovana |
| Frozen original ZIP, exact source SHA/UUID, 11 controls | `VERIFIED_26300` na 26300.9711 | S01/S04, za naredni 26300 izvor zameniti samo manifest-pinned source input |
| Original queue parse, multi-URI, content identity, JIT URL refresh | `VERIFIED_26300` na 26300.9711 | S02R1 + S05 + S06 live reissue, 98/2798 exact content ledger |
| AppsOnly 27→32 provider/hash closure | `VERIFIED_26300` na 26300.9711 | S06 actual 32/32 files, 115,765,780 B; drugi build ponovo manifest-resolve |
| 26300 **FULL Windows UUP** svih 98 payload-a | `NOT_RUN / NEEDS_SEPARATE_GATE` | Source-bound FULL mode uz 98/98 fresh payload identity; staged resumable output owner, AppX closure, disk/resource, native downloader receipts |
| v127 26300 conversion/update servicing→WIM | `NOT_RUN / REQUIRES_RUNTIME` | V127 archive hash pinned S03; proveriti stvarne native converter opcije i postconversion DISM/health |
| R15 MAX_PRE / G5 immutable WIM integration | `VERIFIED_26200_TRANSFER_CANDIDATE` | R113/R133 i stari RC1.2 stvarni 26200; zahteva prvi genuine 26300 rebuilt image + exact owner + poststate |
| Post-download offline PS GREEN/AMBER | `VERIFIED_26200_TRANSFER_CANDIDATE` / pojedine `BLOCKED_BY_DEPENDENCY` | Master §20 logic, target 26300 CBS/AppX/FoD/VM-floor delta; R7, Sense ostaju scoped holds |
| NTLite Business XML preset i component-engine residue | `PLANNED / NOT_RUN_26300` | Tek nakon Stage1/2, reproducibilni XML sa current target komponentama + post-health |
| VMBox first boot, optional installers, Admin/OOBE, VM-host i Defender ON/OFF | `PLANNED / NOT_RUN_26300` | Nakon offline završetka, first boot + **native VM HOST** test oba Defender branch-a |
| ISO 3.5–5GB; installed 11–15GB | `MEASUREMENT_TARGET` | Pravi build, build-aware compressed ISO i čista nova instalacija; različite definicije veličine |

**U prevodu:** dokazan kontinuitet tehnologije ≠ svako pojedinačno uklanjanje je bezuslovno bez zavisnosti. Pravila treba automatski ponovo koristiti kada predicate **odgovara**; ne otvarati sistematski preglede svakog `MUM` ako nema delta/UNKNOWN. Ako se pojavi novi owner ili novi obavezni consumer, analiziraj samo taj dependency i vrati ga u Component Intelligence.

## 11. Šta sledi za 26300 — logičko-hronološki, NE kao odmah odobrene komande

**Trenutna pauza:** operator je nakon S06 zatražio analizu, upis u Current i pauzu; sledeći zahtev je **ovaj handoff**, ne autorizacija punog Windows UUP download-a. Novi naslednik mora čitati poslednji Current i sačekati operatorovu novu jasnu osnovu/cilj. Ovo je tehnička **mapa narednih dependency gate-ova**, ne spisak komandi koje treba odmah poslati.

1. **P0 — evidence continuity:** Potvrdi da su S01–S06 logovi i SHA, script ZIP i tačni 26300 source root očuvani; ako konkretan novi posao zahteva svih 32 G4 identiteta, pribavi baš `E2E\...\Queues\ResolveAppDependencies.log`, a ne ponavljaj S06 AppsOnly download samo radi toga.
2. **P1 — source-bound full Windows queue approval:** Iskoristi postojeći D6/S06 i D4/JIT identitetski renewal, proširi/otključaj *posebnu* FULL granu samo posle izvornog pregleda i neg fixture testova; 98/98 Windows full manifest locked, potrebni originalni servicing/delta/ESD/FoD/edition inputi, AppX 32 closed, explicit `FrozenRoot`, exact source SHA, resume/no overwrite, free capacity samo kad je stvarno potreban veliki download. Potencijalni veliki Windows transfer zahteva operatorski jasan korak. **Ne** skidaj ponovo 26200 R100 gigabajte.
3. **P2 — genuine converter v127:** originalni `uup-converter-wimlib-v127.7z` SHA, stvarni syntax/profile review i 26300 UUP input; integracija update/Cleanup i korigovana `ResetBase`/`NetFx3=0`/`wim2esd`/SkipEdge politika; završni `install.wim` i exact `DISM /Get-WimInfo` 26300, edition/Index, CBS health, pending, immutable SHA. Preskočiti integrisani early ISO finalni status.
4. **P3 — vlasništvo i MAX_PRE:** Clone immutable WIM u owned disposable image, jedan minimalni 26300 package/AppX/feature/CBS/WinSxS/VM-host delta report; naći existing R15/R128/R130/R133 recipes koji odgovaraju topologiji; izvršiti green/amber uz pričvršćene before/after i health gates. Post-state prvenstveno; if R7/Sense variant unknown, izolovan hold, ne globalna bezciljna forenzika.
5. **P4 — standalone offline PS MAX-DEBLOAT:** Dovrši realni Stage1 residue kroz **iste** parametrizovane module; nema duplog pokušaja za ALREADY_ABSENT. Uključuje driver/service/policy AppX, Search, FoD, WinSxS cleanup/optional ResetBase i Defender ON common-base floor.
6. **P5 — NTLite / VM / Defender / release:** NTLite Business verzionisani reproducibilni XML samo za dokazan handoff; oba Defender branch-a, opcionalni Desktop folderi i User installers, unattended Admin/OOBE, online tweaks i VM QA; fizički hypervisor HOST test; finalni WIM/ISO hashes, veličine, log, release PASS samo po Master §31.

Pravilo razvoja novih skripti: sačuvati prethodni izvor; napraviti minimalni review `diff` i hash-manifest, explicit owner/scope/expected state/negative fixtures; operator izvrši jednu punu PS7 Admin komandu; ChatGPT čita **realni** rezultat; posle toga nadograditi Current. Oporavak od `FAIL_CLOSED` kreće od sačuvanih parcijalnih fajlova u originalnom owned direktorijumu, nikad slepog re-run/overwrite. Dobar failure gate štedi sate: ne tretirati ga kao osnovu za ručni reset celog projekta.

## 12. Šablon za mašinski proverljivu evidenciju i Current dnevnik

Za svaki stvarno odrađen milestone sačuvati **bar**:

```yaml
checkpoint_utc: 'ISO-8601 UTC'
source: {family: 'Germanium', build: '<aktuelni 26300.x>', uuid: '<original>', zip_sha256: '<sha>'}
target: {wim_path: '<ako postoji>', wim_sha256_before: '<sha>', index: 1, mount_path: '<owned>'}
script: {name: '<exact>', sha256: '<sha>', command: '<originalni puni poziv>', mode: 'Audit/Apply/...'}
proof: {result: 'PASS/HOLD/FAIL_CLOSED', evidence_paths: [], native_exit: null}
post_state: {cbs_health: 'CLEAN/REPAIRABLE/NOT_RUN', pending: '0/other/NOT_RUN', appx_keep: [], protected_floor: 'PASS/HOLD/NOT_RUN'}
classification: {rule: 'PRODUCTION_RULE/KEEP_SKIP/COMPONENT_ENGINE_HANDOFF/RED_HOLD', confidence: 'STATIC/ACTUAL_THIS_BUILD/RELEASE'}
decision: '<tačna tehnička odluka i razlog>'
next_one_operator_step: '<jedna odobrena ili eksplicitno pending radnja>'
```

Naravno `null`/`NOT_RUN` ostavljati pošteno kada podatak još ne postoji. **Dnevnik je sažet indeks ka logu**, ne zamena za originalni raw DISM ili AppX manifest. Treba čuvati SHA i source verziju i po mogućstvu GitHub commit za svaki review ZIP. Na početku sledeće sesije successor vidi samo **četiri stvari** za nastavak: normativni Master, ovaj handoff, najnoviji Current checkpoint, konkretnu pripadajuću log/datoteku. Library i Sources se pretražuju pre novog rizika.

## 13. BlueLite Sources i offline dokazni inventar: kako tražiti bez ponavljanja

**Najbrži način pre nove analize:**

- Za source/UUP: pretraži `UUP_V3_PhaseA2`, `R26-D4`, `R26-D5`, `R26-D6`, `R28`, `R33`, `R84`, `R100`, `S01..S06`, RC1.2, `Final_UUP/`, `UUP_PreBuild/Drafts`, `Timeline*`, `CustomAppsList`, `ConvertConfig`, `AppxManifest`, `CompDB`.
- Za MAX_PRE/offline: `R15-R1`, `R49 G5`, `R105`, `R107`, `R113`, `R115–R116`, `R119`, `R120–R133`, `338`, `339`, `342`, `18C`, `44–48`, `Search`, `OneDrive`, `FoDMetadata`, `Language.Basic`, `R134–R142`, `Sense`, `WinSxS`, `COMPONENTS`, `Release05`.
- Za fragmentovane nekadašnje sesije: Library `9-ChatGPT.md`, `10-ChatGPT.md`, `11-ChatGPT.md`, `11-13-ChatGPT.md`, `12-ChatGPT.md`, historijske `ChatGPT-1-25H2 26200.9278-20260929-1529.md`, `ChatGPT-2-25H2 26200.xxxx-20260929-1528.md`, `ChatGPT-3-25H2 26200.xxxx-20260929-1527.md`, `ChatGPT-4-25H2 26200.xxxx-20260929-1524.md`, canonical handoff `BlueLite_v1.0_CANONICAL_HANDOFF_10*.md`; proveri Library dostupnost pre poziva. Tačni najnoviji repo `Chats*.md` nazivi se moraju inventarisati, jer ranije pokušani `ChatsGPT.md` na `main` nije bio čitljiv. **Ne zamenjuj missing original novim fikcionim transkriptom**.
- Za reference drugih custom autora: `FBConan-BUILD_INFO.txt`, `FBConan-BUILD_INFO-v3.txt`, `Extreme-11-26H2-Removed.txt`; MDL/TeamOS/NTLite/MSMG poređenja; reference *end-state*, ne neproverena potvrda skraćenog postupka. Dodatne specifikacije po build-u samo ako doprinose konkretnom target-u.
- **Pretraži relevantnu Library stvarno**, ne samo naslove: `files.search` → `files.read/find` opseg, pa originalni CSV/ZIP/script kad je potreban za patch. Ako ZIP file bytes nisu dostupni (historijski prethodnik dobio `not authorized raw-byte materialization path`), zatraži od operatora **samo taj** manji konkretan ZIP, kao uspešno za originalni D6 ~30,896 B. Nikada ne tvrdi da je nedostupan ZIP otvoren. Ako je mnogo dostupnih dokaza, čitaj reprezentativne originalne PASS i FAIL logove uz sažetak u UUP Evidence, a ne svaki redundantni duplikat.

## 14. Kompaktni „Never forget“ za naslednika

1. **Master FIRST; Current TOP; Handoff; UUP Evidence; Sources; Library FIRST.** Nijedna nova analiza ili komanda pre toga.
2. **26300 GA PRIMARY**; 26200 historical regression, 26100 servicing core; ne hardkodirati 26300.9711 kao večno aktivan build.
3. `C:\work` canonical; PS7 Admin; **jedna kompletna komanda**, tačan log, lokalno operator jedini izvršava; **offline WIM**, Total Commander/Explorer zatvoreni pre mount/unmount.
4. Originalni UUP ZIP, immutable WIM, originalni queue fingerprint i već provereni payload nisu potrošna staging putanja; **transport URL jeste**. Osvežava se JIT sa `out+checksum` identitetom; **S06 26300 ovo stvarno potvrđuje**.
5. **Stage1 S01–S06 actual PASS do AppsOnly 32/32 / 115765780 B**. **No full Windows payload, no v127 converter, no 26300 WIM/ISO, no MAX_PRE**, iako S03 converter arhiv SHA PASS.
6. Stari R15/R133/18C/44–48, R7/R142, Sense itd. **biblioteka certifikovanih ili odbijenih varijanti**, ne blanket dozvole za 26300. G4 provider dependency engine već postoji.
7. Final staging **5** ≠ common-base keep **4**; Store/AppInstaller final absent; policy strogo prati manifest. Windows Update pauza do 2100 uz Resume; Defender common ON pa razgranati; VM **HOST** floor.
8. Zadržati servicing-consistent CBS/WinSxS; ne rezati fizički shared/persistent WinSxS bez owner i health/pending testa. „Repairable“ je gate failure, ne prihvatljiv shortcut.
9. `Current` je **jedan centralni živi dnevnik rada**: nakon svakog potvrđenog operatorovog koraka upis+read-back. Izvršen operatorov log nadjačava ranije `DELIVERED`, ali ne proglašava nepotvrđene faze uspešnim.
10. **Trenutno postoji operatorska pauza.** Nema nove naredbe/download-a dok operator ne postavi sledeći zadatak. Kad nastavi sa 26300, sledeće su ciljane preostale Full UUP/G4 provider detalj/v127/MAX_PRE zavisnosti, jedna po jedna, bez vraćanja na stare analize.

---

**Održavanje:** ovaj dokument je stabilan operativni ugovor i precizna mapa istorijskog znanja. Nove izvršne rezultate dodavati u **Current**, ne ponovno u ogromne `Chats*.md` transkripte. Kada se trajno promeni arhitektura ili istorijska matrica prenosivosti, revidirati handoff uz SHA/commit i obrazloženje; promena norme ide u Master. **Brisanje starih repo `Chats*.md` dozvoliti tek kada su svi jedinstveni primarni dokazi lokalno/git-istorijski očuvani**, a korisnik potvrdi da ovaj handoff omogućava neprekinut nastavak.
