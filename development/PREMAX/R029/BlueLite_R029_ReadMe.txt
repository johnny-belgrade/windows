BlueLite R029 / Germanium 26300.x universal one-folder UUP PRE_MAX source-bound package
===================================================================================

CURRENT STATUS: R029 SOURCE-CANDIDATE. Native PowerShell AST, ZIP source SHA and
original vendor parity can be tested before the first real Build. NOT a certified
Windows image or guarantee of a smaller ISO/installed footprint. Release is
NOT_CERTIFIED until actual UUP/WIM/ISO/CBS/AppX/OOBE/VM/WU/Defender testing.

ONE FOLDER — THE ONLY ONE YOU NEED
---------------------------------
The supplied BlueLite ZIP is physically delivered in
C:\work\_UUP\BlueLite_PREMAX_R029_20261107\
You may move the contents to ANY OTHER NO-SPACES selected folder under C:\work;
this package uses CMD %~dp0 and PowerShell $PSScriptRoot, NOT a hard-coded path.

1. Put exactly ONE untouched original UUPdump file ending *_convert.zip in
   that SAME folder as BlueLite_R029_PREMAX_20261107.zip.
2. Extract the original UUPdump ZIP and the BlueLite R029 ZIP DIRECTLY
   into that same folder (no extra nested wrapper folder).
3. In Total Commander (you do NOT need to close it, nor Explorer), run as
   administrator ONLY this one CMD in the selected folder:
       BlueLite_R029_RUN.cmd
4. After the run, send EXACTLY this ONE evidence ZIP from YOUR selected root:
       <your folder>\BlueLite_Logs\BlueLite_R029_EVIDENCE.zip
   If HOLD occurs before evidence ZIP creation, send:
       <your folder>\BlueLite_Logs\BlueLite_R029_RESULT.json
   and the names of any missing reports. Never blindly rerun after a HOLD.

SAME SELECTED FOLDER layout:
  BlueLite_R029_PREMAX_20261107.zip           [BlueLite original distribution]
  26300.XXXX_amd64_en-us_professional_*_convert.zip  [genuine UUPdump ZIP]
  BlueLite_R029_RUN.cmd                       [ONE elevated entry CMD]
  BlueLite_R029_Run.ps1, Prepare.ps1, OfflineWim.ps1, Capture.ps1
  BlueLite_R029_Manifest.sha256               [all 62 source files]
  original extracted uup_download_windows.cmd, files\, ...
  BlueLite_Work\                             [owned download/source/mount/outputs]
  BlueLite_Logs\                             [ALL R029 reports & evidence in ONE place]

OPERATIONS IN THE ONE CMD:
 - Check native admin, PS7, exact 62 source SHA256, 11 original vendor
   archive/extracted member SHA256, build 26300.x en-US Pro x64, one UUID.
 - If this folder holds no independently SHA verified UUP stage, genuine full
   UUP downloader downloads the original source. This may consume ~9 GB
   network/source space; no source is silently omitted from reconstruction.
 - If a source stage is already fully downloaded and receipt verified, reuse
   it and do NOT redownload. If any ConvertStart.marker or ISOFOLDER exists,
   HOLD rather than blindly rerun; no source/ISO corruption.
 - Modify ONLY the source-matched OWNED staged converter script (not original
   vendor ZIP/extracted files). Back it up by SHA, insert R029 native-DISM
   offline WIM phase before ISO and SHA/WinRE WIM capture hook.
 - Native dism.exe /Get-Capabilities/Get-Packages/Get-Features/Get-Provisioned-
   AppxPackages replaces fragile PowerShell large COM inventory. Every DISM
   invocation logs the exact operation, exit code and output in BlueLite_Logs.
 - Remove INSTALLED hardware NIC driver FoDs, SenseClient EDR FoD, and proven
   optional legacy capabilities/features; after each removal verify actual
   installed capability state. Preserve Windows network stack, CBS/Windows
   Update, Defender/Security UI, storage and OOBE. Retain Language.Basic
   en-US F02 CBS_E_CANNOT_UNINSTALL. DesktopAppInstaller F01 may remain
   provisioned: record RELEASE_HOLD, NEVER mislabel it removed.
 - Before WIM export check CBS pending and health. Export to LZX/max WIM;
   identity must match offline CurrentBuildNumber plus UBR separately and
   WIMInfo Version 10.0.26300 / Professional / x64.
 - Native Setup boot.wim remains; temporary converter winre.wim for Setup
   boot image is allowed. Final install.wim Winre.wim absence tested with
   native wimlib. Capture final WIM/boot SHA before ISO media cleanup.
 - Build ISO, test 7zip CRC, record exact WIM/ISO bytes+SHA. After proven
   ISO and SHA, remove ONLY one owned precompact WIM intermediate to avoid
   7GB unnecessary copy. Source UUP/download cache is preserved.
 - Always package stage + root logs into SAME ROOT:
       BlueLite_Logs\BlueLite_R029_EVIDENCE.zip
       BlueLite_Logs\BlueLite_R029_RESULT.json

DEPLOYMENT CONTRACT:
 - EXACT ONE original UUPdump archive and one BlueLite ZIP in one selected
   root. No additional operator-run helper, no copying scripts elsewhere.
 - NEVER require closing Explorer or Total Commander. Normal file manager
   windows are not evidence of mounts/locks. Actual DISM mounted WIM and
   competing DISM/aria2c/NTLite processes are protected gates.
 - NO deletion of original vendor archive, original GOLDEN v4 image, old
   historical Source/Library/GitHub files or random C:\work directories.
 - All R029 custom reports, failure diagnostics and operator return archive
   live under this UUP package root \BlueLite_Logs; other project workflows
   may retain C:\work\scripts and C:\work\logs by Master §0N scope.
 - UUP operations are compute/disk intensive, ensure sufficient C: space.
 - R004 original MAX_PRE 26300.9818 benchmark ISO 6,822,354,944 bytes,
   install.wim 5,736,092,221 bytes. Those are proof baselines, not R029
   size claims. Actual post-install 11–15 GB and desired ISO 3.5–5 GB
   remain release targets subject to real dependency closure/VM tests.
 - On a HOLD inspect exact root BlueLite_R029_RESULT.json and its associated
   evidence ZIP before any further operation. Do not run failed converter
   again or delete a mounted WIM.
