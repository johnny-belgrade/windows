BlueLite R027 — SAME-STAGE PRE_MAX 26300.9818 (reviewed resume candidate)
========================================================================
UUP-ONLY PORTABLE RULE: MASTER §0N (2026-11-06)

This single ZIP is a small continuation overlay for the ALREADY DOWNLOADED,
SHA1-verified 26300.9818 v11.3 source in the currently selected operator
UUP folder. It is NOT a new universal full-download package and it does
NOT contain any of the original vendor files or 9.14 GB UUP payload.

ONE OPERATOR ACTION AFTER REVIEW:
1. Preserve your original *_convert.zip and its 11 extracted vendor
   members, plus the existing BlueLite_Work/ and BlueLite_Logs/ folders.
2. Extract THIS entire ZIP DIRECTLY into the SAME selected, no-spaces
   C:\work\<your-chosen-UUP-folder> (no nested ZIP subfolder).
3. Right-click BlueLite_RESUME_BUILD.cmd -> RUN AS ADMINISTRATOR.
   Do NOT run the old BlueLite_BUILD.cmd or BlueLite_DOWNLOAD.cmd.
4. Return the newest BlueLite_Logs\BlueLite_R027_*_EVIDENCE.zip on PASS/HOLD.
   NEVER blindly repeat a run that reached ConvertStart.marker.

The existing stage is selected from the exact verified OPDL PASS
report/receipt/fresh Verify under this root. Checks original vendor ZIP,
55/55 stage SHA256, source UUID/build/config, 98 Windows+32 Apps queue,
130 files / 9,143,081,111 B, and 129 unique source SHA1 files.
No new aria2 download or cleanup of older stage happens.

After separate receipt verification, Build creates a new helper under the
OWNED staging directory, SHA-backs up and patches only the OWNED
convert-UUP.cmd copy. The ORIGINAL vendor ZIP/scripts stay unchanged.
The source-proven converter reconstructs install.wim, applies existing
R004/R007-equivalent protected offline PRE_MAX and retains Setup WinPE.
The new capture saves final install.wim and boot.wim before ISOFOLDER
cleanup, then the unchanged provider ISO path runs.

UUP logs and result evidence ZIP: <selected UUP root>\BlueLite_Logs
UUP stage + resulting ISO/WIM: <selected UUP root>\BlueLite_Work
All NON-UUP work: C:\work\scripts and C:\work\logs (unchanged).

Minimum 25 GiB free; heavy CPU/disk/thermal use. Close Total Commander
and Explorer windows accessing mount/stage paths before actual Build.
No automatic source deletion, old WIM/ISO deletion, or new download.
On HOLD preserve the stage and all evidence; send log before further run.

NATIVE PROVEN SO FAR: full v11.3 downloaded source/129 SHA1 PASS,
R027 PowerShell 7 AST and standalone native full Preflight PASS,
receipt negative SHA rejection and unique converter patch anchor PASS.
NOT RUN: R027 complete conversion, final ISO/WIM SHA, Setup/VM/Defender/
WU/OOBE/installed footprint, final four-app release certification.
DO NOT claim this is smaller or better than frozen R004 until measured.
