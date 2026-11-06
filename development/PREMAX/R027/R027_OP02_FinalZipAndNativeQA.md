# BlueLite R027 OP02 — exact native ZIP package / independent QA

**2026-11-06; single operator UUP folder, normative Master §0N.** Preceding independently fetched OP01 blob `1a388f8f1df768eba3098a8880f892cda2e55b96`. The artifact was created **directly on the operator's authorized Windows computer** from native-verified R027 source copies. No sandbox-path alias or earlier-session binary is presumed.

**One exact ZIP ready on user's PC:** `C:\work\_UUP_PREMAX_v11.2\BlueLite_PREMAX_26300_v11_3_R027_RESUME_20261106.zip`. **9,216 bytes, SHA256 `4B219BC4981D76455D7CBCDFE1439112198EE2AB02EC150FE47F3940999987E2`**. Created PS7 PID9696. Contains only five root-level unique safe files: `BlueLite_RESUME_BUILD.cmd`, `BlueLite_R027_Resume.ps1`, `BlueLite_R027_CaptureImages.ps1`, `BlueLite_R027_ReadMe.txt`, `BlueLite_R027_Package_SHA256.txt`. No original vendor UUP ZIP, no 9GB payload, no v11.3 build re-download launcher embedded.

**Exact source checksums in manifest (native generated, 4 files, 4 rows):**
- CMD SHA256 `0AF606D5EE5069CBFA43E72517D7AA8EA0B71E72EF475D2D00D2F42065EC90E4`
- Resume controller SHA256 `E4C63C89E8F4BEB63D4F48AD34512B670F7543AE1FC049443E2055F543BCE433`
- Capture helper SHA256 `E526B6F557425A72DDEA5F3F1E02EA98319B9B097B5639A2308C1EB7ED8D24DC`
- README SHA256 `996CCB1CF6B94D7FF4AD9EEAA55F5E83D67D12CEBC46E9BE2FFB81D13CD6C560`
- Manifest SHA256 `21F9EE53EBCEC0696E267FF982A297C98D0E69B195498999CF13DD18730C131B`.

**Independent post-build QA:** native fresh PS7 PID4408 reopened ZIP entries, exact 5 member names, size/case/path checks, all **5 decompressed contents independently SHA256 matched separately read source files**, four manifest rows SHA256 matched originals, archived bytes and outer ZIP SHA matched. Native separate installed 7-Zip **v26.05 PID2092 `7z t`: Everything is Ok, files=5, unpacked 19,611 B, compressed 9,216 B, exit0.** Source Git file readbacks and native AST before package creation PASS. This is **ZIP/source QA**, not a real WIM/ISO runtime.

**Current operator action:** original selected root already contains the exact v11.3 stage/OPDL chain, original vendor ZIP and extracted 11 vendor files. Extract R027 ZIP directly into same root, no nested folder, run ONLY `BlueLite_RESUME_BUILD.cmd` elevated. On PASS/HOLD supply the newest `C:\work\_UUP_PREMAX_v11.2\BlueLite_Logs\BlueLite_R027_*_EVIDENCE.zip`. **No blind rerun after ConvertStart marker**, don't run original `BlueLite_BUILD.cmd` (would redownload), no deleting old v11.2 stage/26300 original/R004 GOLDEN before candidate evidence review. Final size, boot/VM/OOBE/Defender/WU and comparative quality NOT_RUN/NOT_CERTIFIED.

**ONE NEXT:** append compact R027 status to only live `BlueLite_Current_Status.md`, independent CAS readback; prepend short `Session Entry` router entry, readback; GUI report + protocol pause before any image work. Do not silently run operator's one-CMD Build remotely.
