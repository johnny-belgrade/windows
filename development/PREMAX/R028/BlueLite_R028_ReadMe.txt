BlueLite R028 — ONE ROOT, ONE COMMAND, SOURCE-BOUND 26300.x MAX_PRE
======================================================================
Development/operational image-candidate package. R028 complete native WIM/ISO,
setup boot, Defender, WU, VM/OOBE and 11–15GB installed-footprint tests
ARE NOT YET PROVEN. Never claim superior to frozen R004 until measured.

EXACT OPERATOR FOLDER CONTRACT (Master §0N applies only to UUP)
1. Create/choose ONE FOLDER under C:\work with NO SPACES in any part.
2. Put exactly ONE genuine original UUP Dump *_convert.zip and this
   BlueLite_R028_Universal_UUP_MAXPRE.zip into that SAME folder.
3. Extract BOTH ZIPs DIRECTLY into that SAME folder (no nested wrapper).
   Never alter/replace the genuine original UUP ZIP or its vendor files.
4. Run ONE CMD elevated as Administrator:
      BlueLite_R028_RUN.cmd
5. Return the latest BlueLite_Logs\BlueLite_R028_*_EVIDENCE.zip,
   plus any explicitly named EngineEvidence ZIP if an internal gate fails.

Mode selection is automatic and SOURCE/UUID matched:
 A. Exact failed R027 stage with valid source receipt + compact WIM +
    converter-start marker -> single-use recovery of already committed
    install.compact.wim, new FoD trimming, native ISO from existing
    Setup media; NO redownload and NO repeat converter.
 B. Fully verified downloaded stage with no converter marker/ISOFOLDER ->
    SHA-pinned new BlueLite WIM/FoD/capture hook into OWNED staged
    converter copy, run original converter ONCE; no redownload.
 C. NEW original UUP source in an EMPTY chosen folder -> original UUP
    full download verified by v11.3 native source manifest and SHA1,
    then same OWNED-stage converter from those exact files.
 All logs, receipts, and evidence ZIPs for UUP are under selected
 root\BlueLite_Logs. Stage/images stay under root\BlueLite_Work.
 Non-UUP projects still use C:\work\scripts and C:\work\logs.

What this package tries to improve:
 - Fix broken WIM full build+UBR identity check. DISM /Get-WimInfo
   carries Version 10.0.26300, while UBR is offline SOFTWARE. Current
   build/UBR is verified before servicing, export identity checks 26300
   family+Professional+x64 and fresh WIM hash after successful export.
 - Enumerate ACTUALLY INSTALLED network hardware driver FoDs, not only
   UUP download/reference ESDs. Remove 4 Ethernet/24 Wi-Fi installed
   driver capabilities when present, and SenseClient EDR capability,
   with per-item DISM output, readback and STRICT HOLD on any failure.
   This trades off built-in NIC hardware-driver coverage: inject the
   correct LAN/Wi-Fi drivers as needed after Setup. Generic networking
   stack/NDIS/VM/storage/Defender/WU/OOBE floors are not targets.
 - Retain Language.Basic en-US where CBS_E_CANNOT_UNINSTALL dependency
   is not closed, and keep required four modern apps and SecHealthUI.
   DesktopAppInstaller remains an unresolved F01 dependency and can
   prevent final release certification. No unsupported CBS/hardlink
   surgery is performed to fake AppX removal.
 - Skip including Winre.wim in install.wim, but keep temporary native
   winre.wim processing required by provider for Setup boot.wim.
   Capture/check final installed Recovery path; keep genuine WinPE.
 - LZX/max WIM and ISO source-bound evidence; use real hashes/bytes.
   Desired ISO 3.5–5GB and installed OS 11–15GB are TARGETS, not
   claimed outcomes. No automatic ResetBase or original source deletion.

Resource/rollback constraints: CPU/disk intensive; ensure 25GiB+ free
for fresh conversion, 17GiB+ for failed-stage recovery, close any open
mounts and concurrent DISM/NTLite. R004 GOLDEN must remain unchanged.
No broad cleanup. If after a HOLD any ConvertStart.marker exists, DO NOT
rerun blindly: return evidence for inspection. Original vendor ZIP and
downloaded UUP files remain unchanged. Partial operations may leave
an owned stage with logs; only an exact QA-approved cleanup plan can
later remove it.

Important: The source ZIP includes the upstream/v11.3 compatibility
CMD tools and scripts for historical verification, but you run ONLY
BlueLite_R028_RUN.cmd. Never run BlueLite_BUILD.cmd, BlueLite_DOWNLOAD.cmd
or START-ENGINE-APPROVED.cmd directly in the selected root. The new
BlueLite_R028_Manifest.sha256 verifies ALL 63 source members before
any vendor or image operation; original UUP ZIP and its 11 extracted
members are separately byte/SHA verified. Native PASS from manifest,
AST or preflight does NOT certify installability or footprint.
