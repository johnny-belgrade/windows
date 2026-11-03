# R004 OP05 — COMPLETE INVENTORY / HEALTH / SOURCE DIFF, original v4 native 26300.9818

Evidence zip: C:\work\26300.9818-UUP-MAX_PRE_26300_v4\BlueLite_EVIDENCE_20261103T160115024Z.zip; verified SHA256 D64DAD834847DE4CD4FA577D51ED25158085B29D3A81BF073697B673A14D3905.
Source authority: selected original UUP launcher and original UUP Dump 26300.9818 UUID; runtime SourceTriad.log states NOT_PROVIDED, so user metadata triad was NOT actually checked in this run (prior development fixture 98/98 is separate).
Source VerifySource.log: scanned=130; Windows queue=98; original Apps=2798, final Apps=32; missing/partials/core/foreign=0. Full content SHA1 reports files=129 bytes=9143080977, not 130 (unique queued names may overlap).
AppX dependency closure: passes=2; 27 seed records -> 32 final; five exact manifested dependencies added; unresolved=0. Original Apps catalog 2798; only four user-facing retained apps + SecHealthUI and staging DesktopAppInstaller, five frameworks. AppX retained in mounted WIM is exactly 10 (see details below).
DISM final CheckHealth + ScanHealth: all three health observations explicitly say No component store corruption detected; pre- and post-mutation protected VM/network/storage floor 11/11, pending package count 0 before and after. No ResetBase.
FinalWimDebloat.log: 49 action log entries, 5 warnings/skips, WIM bytes before=7488515256 after=5736092221; separate exact WIM SHA256 recorded only by image script.
Warnings: 1 DesktopAppInstaller provisioned residue; Language.Basic en-US capability failed DISM -2146498523 / 0x800F0825; two WMIC wow64/en-US Superseded package SKIPs as invalid Windows package; 1 release-forbidden DesktopAppInstaller residue handoff. STRICT release forbidden gate set to 0; unresolved residue is NOT a clean release PASS.
Scope: inventory package record delta does not prove exact bytes saved per package; cleanup and DISM transforms are conflated. Do not attribute all 135 missing package entries to individual explicit Remove-WindowsPackage calls.

## Packages — before=211 after=76; entries gone=135, new=0, changed-state=2
These are raw JSON enum state values, preserved without guessing their semantic name.
### Packages removed inventory entries
- Microsoft-OneCore-ApplicationModel-Sync-Desktop-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-OneCore-ApplicationModel-Sync-Desktop-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-OneCore-ApplicationModel-Sync-Desktop-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-OneCore-DirectX-Database-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-OneCore-DirectX-Database-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-OneCore-DirectX-Database-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-Client-LanguagePack-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-Ethernet-Client-Intel-E1i68x64-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Ethernet-Client-Intel-E2f68-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Ethernet-Client-Realtek-Rtcx21x64-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Ethernet-Client-Vmware-Vmxnet3-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-FodMetadataServicing-Desktop-Metadata-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Hello-Face-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Hello-Face-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-Hello-Face-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~11.0.26100.1
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~11.0.26100.1742
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~11.0.26100.9818
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~en-US~11.0.26100.1
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~en-US~11.0.26100.1742
- Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~en-US~11.0.26100.9818
- Microsoft-Windows-Kernel-LA57-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Kernel-LA57-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-Kernel-LA57-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-LanguageFeatures-Basic-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-LanguageFeatures-Handwriting-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-LanguageFeatures-Handwriting-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-LanguageFeatures-Handwriting-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-LanguageFeatures-OCR-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-LanguageFeatures-OCR-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-LanguageFeatures-OCR-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-LanguageFeatures-Speech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-LanguageFeatures-Speech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-LanguageFeatures-Speech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-LanguageFeatures-TextToSpeech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-LanguageFeatures-TextToSpeech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-LanguageFeatures-TextToSpeech-en-us-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-Licenses-Professional-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Licenses-Professional-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-Notepad-System-FoD-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-PowerShell-ISE-FOD-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-Printing-PMCPPC-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-StepsRecorder-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- Microsoft-Windows-TabletPCMath-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-TabletPCMath-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-TabletPCMath-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.9818
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-VBSCRIPT-FoD-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
- Microsoft-Windows-Wifi-Client-Broadcom-Bcmpciedhd63-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Broadcom-Bcmwl63a-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Broadcom-Bcmwl63al-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwbw02-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwew00-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwew01-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwlv64-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwns64-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwsw00-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwtw02-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwtw04-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwtw06-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwtw08-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Intel-Netwtw10-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Marvel-Mrvlpcie8897-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Qualcomm-Athw8x-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Qualcomm-Athwnx-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Qualcomm-Qcamain10x64-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Ralink-Netr28x-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Realtek-Rtl8192se-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Realtek-Rtwlane-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Realtek-Rtwlane01-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-Wifi-Client-Realtek-Rtwlane13-FOD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1742
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.1742
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~wow64~~10.0.26100.9818
- Microsoft-Windows-WMIC-FoD-Package~31bf3856ad364e35~wow64~en-US~10.0.26100.1
- OpenSSH-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1
- OpenSSH-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.1742
- OpenSSH-Client-Package~31bf3856ad364e35~amd64~~10.0.26100.9818
### Packages changed enum states
- Microsoft-Windows-SenseClient-FoD-Package~31bf3856ad364e35~amd64~~10.0.26100.1 : 6 -> 2
- Microsoft-Windows-SenseClient-FoD-Package~31bf3856ad364e35~amd64~en-US~10.0.26100.1 : 6 -> 2

## Capabilities — before=424 after=424; entries gone=0, new=0, changed-state=18
These are raw JSON enum state values, preserved without guessing their semantic name.
### Capabilities removed inventory entries
- NONE
### Capabilities changed enum states
- App.StepsRecorder~~~~0.0.1.0 : 4 -> 0
- Browser.InternetExplorer~~~~0.0.11.0 : 4 -> 0
- DirectX.Configuration.Database~~~~0.0.1.0 : 4 -> 0
- Hello.Face.20134~~~~0.0.1.0 : 4 -> 0
- Language.Handwriting~~~en-US~0.0.1.0 : 4 -> 0
- Language.OCR~~~en-US~0.0.1.0 : 4 -> 0
- Language.Speech~~~en-US~0.0.1.0 : 4 -> 0
- Language.TextToSpeech~~~en-US~0.0.1.0 : 4 -> 0
- MathRecognizer~~~~0.0.1.0 : 4 -> 0
- Media.WindowsMediaPlayer~~~~0.0.12.0 : 4 -> 0
- Microsoft.Wallpapers.Extended~~~~0.0.1.0 : 4 -> 0
- Microsoft.Windows.Notepad.System~~~~0.0.1.0 : 4 -> 0
- Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0 : 4 -> 0
- OneCoreUAP.OneSync~~~~0.0.1.0 : 4 -> 0
- OpenSSH.Client~~~~0.0.1.0 : 4 -> 0
- Print.Management.Console~~~~0.0.1.0 : 4 -> 0
- VBSCRIPT~~~~ : 4 -> 0
- Windows.Kernel.LA57~~~~0.0.1.0 : 4 -> 0

## Features — before=137 after=136; entries gone=1, new=0, changed-state=9
These are raw JSON enum state values, preserved without guessing their semantic name.
### Features removed inventory entries
- WindowsMediaPlayer
### Features changed enum states
- MediaPlayback : 2 -> 0
- Microsoft-RemoteDesktopConnection : 2 -> 0
- MSRDC-Infrastructure : 2 -> 0
- Printing-Foundation-InternetPrinting-Client : 2 -> 0
- SearchEngine-Client-Package : 2 -> 0
- SmbDirect : 2 -> 6
- WCF-Services45 : 2 -> 0
- WCF-TCP-PortSharing45 : 2 -> 0
- WorkFolders-Client : 2 -> 6

## Provisioned AppX full inventory
Before count=10, after count=10
- Microsoft.DesktopAppInstaller | Microsoft.DesktopAppInstaller_2024.401.617.0_neutral_~_8wekyb3d8bbwe
- Microsoft.NET.Native.Framework.2.2 | Microsoft.NET.Native.Framework.2.2_2.2.29512.0_x64__8wekyb3d8bbwe
- Microsoft.NET.Native.Runtime.2.2 | Microsoft.NET.Native.Runtime.2.2_2.2.28604.0_x64__8wekyb3d8bbwe
- Microsoft.SecHealthUI | Microsoft.SecHealthUI_1000.26100.1.0_x64__8wekyb3d8bbwe
- Microsoft.UI.Xaml.2.8 | Microsoft.UI.Xaml.2.8_8.2310.30001.0_x64__8wekyb3d8bbwe
- Microsoft.VCLibs.140.00 | Microsoft.VCLibs.140.00_14.0.30704.0_x64__8wekyb3d8bbwe
- Microsoft.VCLibs.140.00.UWPDesktop | Microsoft.VCLibs.140.00.UWPDesktop_14.0.30704.0_x64__8wekyb3d8bbwe
- Microsoft.Windows.Photos | Microsoft.Windows.Photos_2024.401.617.0_neutral_~_8wekyb3d8bbwe
- Microsoft.WindowsCalculator | Microsoft.WindowsCalculator_2024.401.618.0_neutral_~_8wekyb3d8bbwe
- Microsoft.WindowsNotepad | Microsoft.WindowsNotepad_2024.401.617.0_neutral_~_8wekyb3d8bbwe
No provisioned app was actually removed between these 10-element before/after inventories; DesktopAppInstaller survived. User-facing 64 disabled top-level apps were prevented from admission at source rather than removed offline.

## Native receipt provenance, OP05
Direct archive SHA and ZIP members were re-read on operator Windows; results above independently derived by script from both inventory JSON snapshots, not copied from previous assistant narrative.
NEXT OP06: source filename/SHA comparison against predecessor; final physical ISO/WIM size, WinRE configuration and dependency/size opportunities; no mutation or source deletion.
