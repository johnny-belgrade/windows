# BlueLite Project Sources

## Installed PowerShell input/EOF reproduction — R002R20 native evidence (2026-10-22)

- [Original native receipt, byte-exact mirror](development/PREMAX/R002/05_Evidence/R002R20_InputEof_NativeReceipt.json): commit `0095bcd80259f67c532c66657aace18c521cb274`, SHA256 `D6D7FD2E139DF3D007C9F6EBB1E5A5382257F957CDA26C11309321E6A6178F69`, 1933 bytes, exact Git/native hash reconciliation.
- [Source, execution observations and proof limits](development/PREMAX/R002/02_Analysis/R002R20_InputEof_ResultAndCheckpoint_20261022.md): commit `299438f20c0f6471eb693eff6c3fb323ae7f6ec9`. Installed PS7.6.7 passed all three controlled cases: renamed variable/open stdin; automatic input/closed stdin; automatic input/held-then-closed stdin. The latter emitted no first marker during the 1500ms hold and completed after EOF. Exact outputs, empty stderr and native exit 0 verified.
- This extends the earlier R19 **source-only** finding below with native proof of the controlled mechanism. Historical R14/R17 handles remain unavailable, so their exact causal attribution is still inferred. No integrated adapter, HTTP, component-removal or MAX_PRE certification follows.

## PowerShell launch and automatic input — R002R19 source finding (2026-10-22)

- [Microsoft automatic variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.6): engine-managed `$input` must not be reused as an ordinary source-path variable.
- Original **PowerShell v7.6.7** implementation: [ConsoleHost.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/Microsoft.PowerShell.ConsoleHost/host/msh/ConsoleHost.cs) blob `632181d4161dfdf95e3ed12b5e68ca431f34fce8`; [AstVisitor.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/System.Management.Automation/engine/parser/AstVisitor.cs) blob `03b234cf41f7fc869c999cf0930081d036c63f8f`; [Executor.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/Microsoft.PowerShell.ConsoleHost/host/msh/Executor.cs) blob `38924f3e39794c4f81ea54c369f4468c1b154729`. All directly fetched/read. -File AST detection of the automatic input variable activates redirected-stdin consumption; -Command detection instead inspects the outer command text. This supports a testable explanation for R14/R17 no-output, **not a native reproduction or proof of their historical stdin state**.
- [R19 exact evidence and proof limits](development/PREMAX/R002/02_Analysis/R002R19_PowerShell_InputBoundary_SourceReview_20261022.md). No adapter or image runtime certification is inferred.

## Original UUP converter — current stock pre-ISO proof (2026-10-22)

- [Original author abbodi1406 — stock convert-UUP.cmd](https://github.com/abbodi1406/BatUtil/blob/master/uup-converter-wimlib/convert-UUP.cmd): direct GitHub connector source blob `262a6e6b0ad2016d1345927bdc334898f71b49f2`, locally byte-exact Git blob verified; current literal `uivr=v128m`. [Original ReadMe](https://github.com/abbodi1406/BatUtil/blob/master/uup-converter-wimlib/ReadMe.html) blob `58aeee6f7a1eba3fbeb1675e9cd7ba65251fdbd1`. This **source-level** authority is not a certification that any vendor converter archive was downloaded or run.
- [Official UUP Dump misc — converter_windows selection metadata](https://git.uupdump.net/uup-dump/misc/src/branch/master/autodl_files/converter_windows): as observed 2026-10-22, latest listed 2026-10-16 source chooses `uup-converter-wimlib-v128m.7z`, declared archive SHA256 `1597F39D614529843DCADF630ED6DD4543C955EA703B6B0D1FDBE65AA078A5F1`. In contrast operator-frozen original 26300.9711 ZIP metadata declares `v126` archive SHA256 `1448F7E33353FA63D558333C4B6DDB8B41B992A7911F19D3B72BA3246CF349BC`; do not exchange without independent compatibility gates.
- Detailed original-vendor `AutoStart=1;SkipISO=1` branch order and separately controlled pre-final-ISO MAX_PRE architecture: [R002R4 static review](development/PREMAX/R002/02_Analysis/R002R4_OriginalStock_PreISO_Handoff_Review.md); actual PowerShell source guard and 11/11 negative tests were executed READ-ONLY on local source snapshot, while official binary/runtime, WIM and ISO are NOT yet certified. Future source/version re-pinning, converter download/CPU advance notice, `C:\work` path and separate operator approval mandatory.

> **MASTER v6.0.0 / 2026-10-16 — PRIMARNI 26H2 GA / 26300.x**. 26200.x ostaje istorijski/regresioni i Component Intelligence izvor; 26100.x je shared-servicing referenca. **ČVRSTA ZVANIČNA ČINJENICA:** Microsoft dokumentuje da **Windows 11 26H2, 25H2 i 24H2 dele isti core operativni sistem, zajednički skup sistemskih fajlova i servicing foundation/branch**. KB5121794 je EKB za dormant funkcije, a KB5127648 iz 2026-10-13 obuhvata **26300.9711, 26200.9711 i 26100.9711**. Ova platformska činjenica omogućava reuse BlueLite recepata, ali NE dokazuje automatski isti CBS/AppX/FoD owner/post-state na novom buildu. **26H2 GA od 2026-09-29.** Istorijski status „26300 UUP još nije preuzet“ važio je samo pre S01 (2026-10-16): **2026-10-17 S01–S06 actual PASS do AppsOnly/G4 32/32**, bez punog Windows UUP payload-a, konverzije ili 26300 WIM-a. Za aktivno stanje vidi [Current](BlueLite_Current_Status.md), a trajnu proceduru i proverenu mapu dokaza u [Germanium Handoff](BlueLite_Germanium_Handoff.md). [Master v6.0.0](BlueLite-Master_Germanium_Strategy_final.md) | [UUP 26300 plan](BlueLite_UUP_Evidence_Reconciliation_20261013.md) | [Current Status](BlueLite_Current_Status.md).

> **BlueLite local-write and evidence-lifetime contract (2026-10-13):** All **local writes required by approved offline work are allowed in principle**. Windows `%SystemRoot%`, user/system TEMP, DISM logs and temporary HKLM/offline-registry-hive mappings are **ephemeral session state**. `C:\work` (scripts, logs, WIM, backup, frozen UUP and operator-managed E2E artifacts) is **potentially persistent project state** and not automatically deleted. The workflow never depends on Windows TEMP/system-registry/log content surviving overnight; when operator announces shutdown, reconcile owned WIM mounts, offline hive aliases and transient operations, preserving durable evidence in `C:\work\logs`. The verified **offline image**, not the running Windows install, is the debloat target. Temporary host writes are not categorically banned. Contract: [Master Strategy §6.1A](BlueLite-Master_Germanium_Strategy_final.md#61a-local-write-lifecycle-ephemeral-host-state-vs-persistent-project-state-2026-10-13); execution checkpoint: [Current Status](BlueLite_Current_Status.md). Consult external sources, Library and original operator evidence together.

## Microsoft 26H2 / 24H2–25H2–26H2 Shared Servicing — PRIMARY VERIFIED EVIDENCE (2026-10-16)

* [Microsoft — What's new in Windows 11, version 26H2 for IT pros](https://learn.microsoft.com/en-us/windows/whats-new/whats-new-windows-11-version-26h2) — **26H2, 25H2 i 24H2 imaju zajednički servicing foundation i servicing branch**. Feature aktivacija, novi interfejsi, inbox Sysmon i WMIC expected-absence proveravaju se protiv stvarnog target image-a.
* [Microsoft KB5121794 — 26H2 feature update enablement](https://support.microsoft.com/en-gb/servicing/os/windows-11/2026/09/kb5121794-feature-update-to-windows-11-version-26h2) — **shared core operating system with identical set of system files** u 24H2/25H2/26H2; dormant features i enablement-package master-switch za podržane postojeće instalacije. To NIJE isti proces kao čista 26300 UUP rekonstrukcija.
* [Microsoft — Windows 11 26H2 GA / Release Health](https://learn.microsoft.com/en-us/windows/release-health/status-windows-11-26H2) — **General Availability od 2026-09-29**, uz aktivno praćenje poznatih pitanja. GA ne znači da je prilagođeni BlueLite install.wim već verifikovan.
* [Microsoft — KB5127648 (2026-10-13)](https://support.microsoft.com/en-us/servicing/os/windows-11/2026/10/kb5127648-windows-11-24h2-25h2-26h2-security-update) — kumulativni update za **26300.9711 / 26200.9711 / 26100.9711**, neposredni dokaz zajedničkog mesečnog servicing ciklusa i zasebnih build prefiksa.
* [Microsoft — Windows 11 release information](https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information) — autoritativna GA/build/source-revision provera pred svaki novi operatorov 26300 UUP izbor.
* [Microsoft — removed features](https://learn.microsoft.com/en-us/windows/whats-new/removed-features) — koristi za expected ALREADY_ABSENT (npr. WMIC), ne za pretpostavku da je BlueLite uklonio Microsoft-om već uklonjenu komponentu.
* [BlueLite UUP evidence — 26300 applicability matrix](BlueLite_UUP_Evidence_Reconciliation_20261013.md) — povezivanje 26200 Library/Timeline/R100/Python/DISM podataka sa build-resolved 26300 source/transport/AppX/FoD/CBS/NTLite/VM gates.
* [BlueLite MASTER v6.0.0](BlueLite-Master_Germanium_Strategy_final.md) — konačna odluka i priority precedence: 26300 PRIMARY, 26200 regression only.

## Bases & Image Building
* [UUPdump](https://uupdump.net/) - Izvor za preuzimanje i generisanje originalnih Windows instalacionih ISO fajlova direktno preko UUP paketa.
* [marcinmajsc/uup-dump-build-and-get-windows-iso](https://github.com/marcinmajsc/uup-dump-build-and-get-windows-iso) - Automatizacija UUP preuzimanja, generisanja Windows ISO fajlova i objave artefakata preko GitHub Actions; istraživačka referenca za BlueLite one-click UUP workflow.
* [OldGodShen/AutoUUPBuild](https://github.com/OldGodShen/AutoUUPBuild) - Automatizovani alat za preuzimanje i buildovanje UUP slika.
* [Cairnstew/uup-builder](https://github.com/Cairnstew/uup-builder) - Python projekat za kreiranje i prilagođavanje Windows ISO slika; istraživačka alternativa nekadašnjem UUPBuildByPy projektu.
* [issenn/uup-converter-wimlib](https://github.com/issenn/uup-converter-wimlib) - Skripte za konverziju UUP datoteka u WIM/ISO format pomoću wimlib-a.
* [gitntel/uupdump_actions](https://github.com/gitntel/uupdump_actions) - GitHub Actions radni procesi za automatsko generisanje UUP dump ISO fajlova.
* [lzw29107/uupdump](https://github.com/lzw29107/uupdump) - Dodatni repozitorijum prilagođen za rad sa UUP dump sistemom.
* [Satxm/UUP-ISO-Scripts](https://github.com/Satxm/UUP-ISO-Scripts) - Skripte za generisanje i pakovanje ISO slika iz UUP izvora.

## DISM & NTLite References
* [Microsoft DISM Documentation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/what-is-dism?view=windows-11) - Zvanična Microsoft dokumentacija za komande, servisiranje i upravljanje Windows WIM/ESD slikama.
* [NTLite Official Guide](https://www.ntlite.com/docs/) - Zvanično uputstvo za korišćenje NTLite alata za live i offline modifikaciju Windows komponenti.

## Windows Debloat & Scripting
* [farag2/Sophia-Script-for-Windows](https://github.com/farag2/Sophia-Script-for-Windows) - Moćna PowerShell skripta za napredno podešavanje, optimizaciju i debloat Windows 10/11 sistema.
* [raphire/win11debloat](https://github.com/raphire/win11debloat) - Efikasna skripta za uklanjanje bloatware aplikacija i telemetrije sa Windows 11.
* [simeononsecurity/Windows-Optimize-Debloat](https://github.com/simeononsecurity/Windows-Optimize-Debloat) - Zbirka skripti i alata za sistematsku optimizaciju i sigurnosno učvršćivanje Windows okruženja.
* [sctg-development/windows-in-place-updater](https://github.com/sctg-development/windows-in-place-updater) - Alat namenjen za in-place nadogradnje i flešovanje Windows sistema.
* [raspiduino/updateinsider](https://github.com/raspiduino/updateinsider) - Skripte za praćenje i primenu Insider nadogradnji.
* [ArKT-7/woawin](https://github.com/ArKT-7/woawin) - Alat za optimizaciju i prilagođavanje Windows instalacija.
* [abbodi1406/W10UI direktorijum](https://github.com/abbodi1406/BatUtil/tree/master/W10UI) - Kolekcija skripti i dokumentacije za integraciju Windows ažuriranja u offline WIM/ISO slike; zamena za nepostojeći ISO-Update repozitorijum.
* [oskarx/Win_ISO_Patching_Scripts_zhCN](https://github.com/oskarx/Win_ISO_Patching_Scripts_zhCN) - Kolekcija skripti za flešovanje i patchovanje Windows ISO fajlova.

## Advanced Image Customization & Servicing
* [MSMG Toolkit](https://forums.mydigitallife.net/threads/msmg-toolkit.50572/) - Potvrđena originalna MSMG ToolKit diskusija na My Digital Life forumu; referenca za offline servicing, integraciju i uklanjanje Windows komponenti.
* [W10UI (Windows 10/11 Update Integrator)](https://github.com/abbodi1406/BatUtil/blob/master/W10UI/W10UI.cmd) - Originalna W10UI.cmd skripta autora abbodi1406 za integraciju Windows nadogradnji (CAB, MSU) u instalacionu sliku.
* [Windows ADK (Assessment and Deployment Kit)](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) - Zvanični alati za masovnu primenu Windows-a, uključuje Windows PE, Sysprep i OSCDIMG.
* [Sysprep (System Preparation) Documentation](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/sysprep--system-preparation--overview) - Baza znanja za generalizaciju Windows slika pre pravljenja finalnog ISO fajla.

## Premium Debloat, Privacy & Tweaking Tools
* [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) - Jedan od najpopularnijih PowerShell alata za instalaciju programa, tweak-ovanje i debloat Windows-a. Izvor odličnih registry rešenja.
* [builtbybel/Bloatynosy](https://github.com/builtbybel/Bloatynosy) - Aplikacija specifično dizajnirana za uklanjanje telemetrije i bloatware-a iz Windows 11.
* [undergroundwires/privacy.sexy](https://github.com/undergroundwires/privacy.sexy) - Open-source kolekcija skripti za privatnost i bezbednost, korisna kao istraživački izvor za registry i policy podešavanja.
* [Winaero Tweaker](https://winaero.com/winaero-tweaker/) - Ultimativni UI alat za Windows tweakove; njihov blog je najbolja svetska baza za pronalaženje skrivenih registry ključeva.
* [O&O ShutUp10++](https://www.oo-software.com/en/shutup10) - Referenca za antispy i telemetrijska podešavanja na nivou operativnog sistema.
* [Michaelunkai/windowsapps](https://github.com/Michaelunkai/windowsapps) - Skripte za upravljanje i uklanjanje fabričkih Windows aplikacija.

## Scripting, Syntax & Cheat Sheets
* [SS64 CMD & PowerShell Reference](https://ss64.com/) - Biblija za komandnu liniju! Ultimativni cheat sheet za svaku CMD, PowerShell i VBScript komandu sa primerima sintakse.
* [PowerShell Gallery](https://www.powershellgallery.com/) - Zvanični repozitorijum za PowerShell module, gde možemo nalaziti gotove funkcije za manipulaciju sistemom.
* [Microsoft Win32 API Registry Reference](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry) - Dubinska dokumentacija o tome kako Windows rukuje registry bazom pod haubom.
* [davidanger/BatUtil](https://github.com/davidanger/BatUtil) - Zbirka pomoćnih komandnih i batch skripti.
* [abbodi1406/BatUtil](https://github.com/abbodi1406/BatUtil) - Pomoćne batch skripte i rutine od proverenog autora (`abbodi1406`).
* [GhostwheeI/TheBatchCompendium](https://github.com/GhostwheeI/TheBatchCompendium) - Sveobuhvatni zbornik naprednih batch skripti i trikova za komandnu liniju.
* [DVSB/BatUtil](https://github.com/DVSB/BatUtil) - Dodatne CMD/Batch komunalne skripte za automatizaciju.

## ISO Creation & Deployment
* [Rufus (GitHub)](https://github.com/pbatard/rufus) - Referenca za kreiranje bootabilnih USB-ova i zaobilaženje TPM/SecureBoot restrikcija kroz Windows Setup.
* [Ventoy (GitHub)](https://github.com/ventoy/Ventoy) - Alat za multiboot USB. Sjajan izvor za razumevanje kako bootloaderi rade sa Windows ISO fajlovima.
* [OSCDIMG Command-Line Options](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/oscdimg-command-line-options) - Alat za pakovanje foldera nazad u bootabilni ISO fajl nakon što završimo debloat WIM slike.

## Virtualization & VM Validation — VMware Workstation Pro
* [VMware Workstation Pro — Official Product Documentation](https://docs.vmware.com/en/VMware-Workstation-Pro/index.html) — zvanična dokumentacija; referenca za kontrolisane BlueLite VM instalacije, hardverski profil i validation gate-ove.
* [VMware Workstation Pro 17 — User Guide & Advanced Configuration](https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.workstation.using.doc/GUID-880F0860-2E24-4B39-8631-EC83E71661A3.html) — podešavanje i napredne opcije virtuelnih mašina; izvorni korisnički link (17.x dokumentacija, proveriti primenljivost na noviju verziju).
* [Broadcom Knowledge Base — Troubleshooting & KB Hub](https://knowledge.broadcom.com/) — zvanične ispravke, poznata ograničenja i dijagnostika VMware Workstation okruženja.
* [VMware Workstation Pro 17 — Windows 11 vTPM & Secure Boot Guide](https://docs.vmware.com/en/VMware-Workstation-Pro/17/com.vmware.workstation.using.doc/GUID-D8E9F6B9-130C-4A2D-A4EB-6EE454E5F528.html) — izvorni vodič za Windows 11 vTPM/Secure Boot VM konfiguraciju; za 26H1 i novije uporediti aktuelnu dokumentaciju.
* [Broadcom — Download & License VMware Workstation Pro](https://knowledge.broadcom.com/external/article/368667/download-and-license-information-for-vmw.html) — aktuelno službeno pojašnjenje besplatnog komercijalnog/ličnog korišćenja i postupka preuzimanja.
* [VMware Workstation 26H1 — Official Release Notes Overview](https://blogs.vmware.com/cloud-foundation/2026/05/14/announcing-vmware-workstation-and-fusion-26h1/) — novija zvanična generacija 64-bitnog Workstation Pro, relevantna za izbor VM platforme 2026.

## Package Management
* [Windows Package Manager (WinGet)](https://github.com/microsoft/winget-cli) - Referenca za implementaciju i automatizaciju instalacije osnovnih programa u BlueLite instalaciju bez korisničke interakcije.

## Deep Windows Communities & Tutorials
* [ElevenForum Tutorials](https://www.elevenforum.com/t/windows-11-tutorial-index.462/) - Najveća i najažurnija baza (od autora Shawn Brink-a) sa gotovim `.reg` fajlovima i tutorijalima za svaki mogući detalj u Windows 11.
* [WinCert Forums](https://www.wincert.net/forum/) - Forum specijalizovan za Windows Customization, unattended instalacije i integraciju drajvera.
* [Reddit r/Windows11 & r/PowerShell](https://www.reddit.com/r/Windows11/) - Korisno za praćenje najnovijih bagova, skrivenih opcija i rešenja koja zajednica nalazi za nove preview i insider buildove (poput 26200+).
* [TNCTR Forum (Saf vs Ince Ayarlı)](https://www.tnctr.com/topic/1201254-saf-windows-mu-yoksa-i%CC%87nce-ayarl%C4%B1-m%C4%B1/) - Diskusije zajednice o poređenju čistih (saf) i fino podešenih (ince ayarlı) Windows instalacija.
* [Blog CSDN Technical Article](https://blog.csdn.net/Primary_student/article/details/137924676) - Tehnički članak i analiza dubinskih podešavanja sistema.

## External Forums & Communities
* [TeamOS Community](https://www.teamos.xyz/) - Glavna zajednica za custom OS buildove, diskusije o optimizaciji i preuzimanje alata.
* [My Digital Life Forums](https://forums.mydigitallife.net/) - Tehnički forum za dublju analizu Windows instalacija, aktivacija i skriptovanja.
* [kravenrus/chatGPT](https://github.com/kravenrus/chatGPT) - Dodatni community repozitorijumi i alati vezani za AI integracije i skripte.

## Official Repositories & Documentation
* [GitHub Official Homepage](https://github.com/) - Glavna platforma za hostovanje koda, repozitorijume i praćenje projekata.
* [PowerShell Documentation on GitHub](https://github.com/PowerShell/PowerShell) - Zvanični GitHub repozitorijum za PowerShell, module i dokumentaciju.
* [abbodi1406/website-public](https://github.com/abbodi1406/website-public) - Javni sajt i dokumentacija projekata od ključnog autora za Windows alate (`abbodi1406`).
* [Atlas-OS/Atlas](https://github.com/Atlas-OS/Atlas) - Open-source projekat optimizacije Windows performansi, privatnosti i upotrebljivosti; tematska zamena za nedostupni Dash2KoF/website, a ne njegov nastavak.
