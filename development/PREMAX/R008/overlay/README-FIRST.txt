BlueLite v1.0 | MAX_PRE 26300.x UNIVERSAL OVERLAY v6.1 | 2026-11-03
================================================================

READ ME FIRST (original UUP Dump authoritative, build not hardcoded)
1) Select/download a *fresh ORIGINAL* UUP Dump Windows ZIP for ANY 26300.x,
   amd64, en-us, Professional, AddUpdates=1, WIM not ESD, NetFx3=0.
2) Extract ORIGINAL UUP Dump ZIP into one clean folder YOU CHOOSE (NO SPACES
   in folder path; original UUP converter rejects paths with spaces).
3) Extract ENTIRE BlueLite MAX_PRE v6.1 ZIP into SAME root folder. When done:
     YOUR_ROOT\START.cmd
     YOUR_ROOT\uup_download_windows.cmd   <-- untouched original vendor
     YOUR_ROOT\BlueLite\BlueLite_UUP.cmd  <-- overlay runner
     YOUR_ROOT\BlueLite_Package_SHA256.txt
4) Right-click YOUR_ROOT\START.cmd -> Run as administrator.
   DO NOT run uup_download_windows.cmd directly (that bypasses BlueLite).
   DO NOT run the 3rd party File_renaming_script.cmd; DATA ONLY.
5) MANDATORY: put *three metadata files for EXACT chosen build* in same root:
     List of files UUP.txt
     File_renaming_script.cmd
     SHA-1 checksums file.txt
   All three are REQUIRED and tied to the chosen source; preflight refuses any missing file BEFORE download. Full 1:1:1 + D4 equality is checked before Windows payload transfer.
6) UUP payload download/converter/CBS servicing is CPU/IO intensive.
   This is a REAL image factory, not a source-only preparatory script.
7) Result evidence is ONE latest BlueLite_EVIDENCE_yyyyMMddTHHmmssfffZ.zip
   in the chosen root. It includes all operation logs. On success/failure
   the temporary BlueLite_Logs folder is removed only after zip SHA checks.
   On failed evidence archival, original logs are retained.
8) For a resume, run START.cmd again; previous verified evidence log ZIP
   is restored before the original engine assesses checkpoints.
   Full failed WIM conversion cannot blindly be resumed when ISOFOLDER exists.
9) Do not mix original UUP ZIP contents, three metadata files, copied
   queues or content from different UUP UUIDs/builds.

CONTENT AND ACCEPTANCE
- Builds: 26300.x only; selected per original UUP Dump launcher, not pinned
  to .9818/.9725 or to a converter version.
- The original source Windows queue is retained intact in file identities
  and full reconstruction. Vendor converter downloaded from original manifests.
- Five AppX staging identities, exact manifest framework resolution, four
  final retained user apps. FoD and Superseded-only package policies after WIM
  reconstruction. Pending/CBS health/VM floor gates, no ResetBase.
- SHA1 verifies each downloaded Windows/AppX byte-stream before conversion.
- Microsoft URL renewal is allowed once only when ALL original (out,SHA1)
  identities and the original UUP UUID are unchanged; never silently switch CU.
- WIM failure before commit -> DISM /Discard. No forced save on a failed gate.
- No NTLite, ResetBase, full offline AMBER or VM release claim in this overlay.
- No guarantee of final ISO or clean installed footprint until native proof;
  true 26300.9818 v4 WIM/ISO was operator-runtime PASS; this v5 policy-delta is not yet downloaded/built natively.

IMPORTANT: User project files, GitHub and unrelated C:\work paths are not
modified by the EXTRACTED overlay. Its runtime footprint is inside chosen
original UUP root. It downloads original Microsoft UUP sources only when run.

V5 STRICT DEPENDENCY HANDOFF: The proven v4 engine and converter/reconstruction flow are unchanged. Only the failed Basic en-US GREEN removal attempt is deferred; AppInstaller (F01), Basic CBS owner (F02), WMIC exceptions (F03), and post-debloat/NTLite/VM require later dedicated work. BlueLite may emit warnings for these. Do not claim ISO <=5GB or installed <=15.5GB until validated.

R007 strict: required source triad, 98/98 native proof for 26300.9818, generic other 26300 sources require their OWN three metadata files. SourcePrecutDecision.json records candidate/KEEP before Windows transfer. No unsupported Windows FoD source omission; 62/62 current FoD candidates appear in selected CompDB, full converter owner graph still OPEN. Keep five AppX top-level staging identities + framework dependencies.
RECOVERY-ON-DEMAND: SkipWinRE=1 is already effective; the bundled Recovery-on-Demand.txt is metadata only OUTSIDE base ISO. Preserve Setup sources/boot.wim; do not claim another 700MB or functional native recovery without separate VM test.

R008 v6.1: strict offline triad validation before network; malformed/duplicate data refused; D4 SHA256-bound precut receipt; recheck on resume. WIM engine unchanged. Static/fixture result is not native v6.1 conversion or release certification.
