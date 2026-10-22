# BlueLite R002-R22 — bounded two-queue metadata execution contract

2026-10-22. **PREPARED_NOT_RUN / NOT_DELIVERED**. This is the single successor step after R21; the current R21 block ends with a GUI pause. No native R22 AST, Probe, Fetch or external request has occurred.

## Reviewed source and evidence basis

[Complete v5](../03_Drafts/R002R22_9807_TwoQueue_Bounded90s_v5_DRAFT.ps1): 9114 bytes, SHA256 E48556CD44C0E1188143F8F1F040CBDA569B34C86E2D334ACCF7CF43254F892D; Git commit 6a7f44b35994217b1b96ad820fdb83266d8e68b3 / blob d7847e6bdd4db0be25cf48a0879a06cacca271f8, exact readback.

The R21 v4 preflight actually passed through ordinary -File (exit0, trace84ms, zero GET); [original trace](../05_Evidence/R002R21_Native_PreflightStages.txt) SHA256 3F4463567AF509F863ABDBFD958BB2BDF44D859C5F18BFC1D5DA0C2930F882D8. Full current 113-line pinned D4 module was read: Get-BlueLiteQueueIdentity returns Count/SHA256/Records and validates nonempty records, safe unique output names, supported checksum shape and HTTP(S) transport syntax. It computes out+checksum semantic identity; it does not download or cryptographically verify payload content.

V5 preserves v4's source/contract/URI predicates and existing bounded streaming implementation, corrected ordinary variable names and immutable predecessors. Reviewed changes are new R22 paths/result identities, PS7 requirement, replacement of the unconditional Fetch rejection by exact authorization gates, UTC/PID/adapter-SHA receipt fields and an accurate QUEUE_IDENTITY_VALIDATED marker. Early Fetch authorization precedes trace creation; the second guard immediately before Fetch remains. No actual R22 native parser or HTTP PASS is claimed.

## Owned paths and preflight

All relative paths below are under C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package.

- Script: 03_Drafts\R002R22_9807_TwoQueue_Bounded90s_v5_DRAFT.ps1
- Trace: 05_Evidence\R002R22_Run_001\R002R22_Native_Stages.txt
- Metadata directory: 05_Evidence\R002R22_9807_NewQueue_001
- Queue files: WindowsQueue.newly_observed.txt and AppsQueue.newly_observed.txt
- Receipt: R002R22_Native_Metadata_Receipt.txt inside that metadata directory.

On operator resumption, read the current Master/checkpoint/mandatory READMEs; verify live Git and connector config, sessions and exact owned paths. Record Session IN_PROGRESS/readback before delivery. Deliver frozen source through ordinary RDC, verify exact SHA/bytes, native PS7 AST zero errors and no unintended automatic-input/matches expressions. Both new output directories must be absent. Never delete a collision or reuse a partial run directory. Do not run v5 in Probe mode first against the same trace folder; the gate is AST/hash, and actual Fetch reexecutes the inherited preflight. V4's native Probe proof is already retained.

Source ZIP/launcher/contract/D4 SHA and source26300.9807/UUID687d1ced-aab1-4cd5-ad05-705189769731/en-us/Professional predicates must pass. Windows URI is extracted from the immutable original launcher; Apps URI is source-bound neutral/app. Both are restricted to https://uupdump.net/get.php with exactly id,pack,edition,aria2=2, no userinfo/fragment, exact UUID and respective pack/edition.

## Exact one-step invocation and bounds

Before executing, announce the two small metadata downloads, low expected CPU, at most20MiB combined response bodies and exact local destinations. No converter/image operation is included.

~~~powershell
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R22_9807_TwoQueue_Bounded90s_v5_DRAFT.ps1" -Mode Fetch -Authorization "I_APPROVE_R002R22_TWO_METADATA_GET_ONLY"
~~~

Use the ordinary RDC default-shell launch, short polls, and retain its exact process ID. At most one GET for each of Windows and Apps, zero redirects or explicit retries. One CancellationTokenSource per request covers GetAsync(headers) and every ReadAsync(body),90s total; content-length and streamed-byte bounds10MiB each; FileMode.CreateNew; D4 semantic parsing before acceptance. No aria2/payload download and no reference-file modification. Expected normal network ceiling180s plus small parsing/logging overhead; use a210s total observation bound and short waits that permit GUI updates. If still active, stop only the owned process tree, verify termination, retain partial files and report HOLD; no rerun in a fresh directory to hide the failure.

Success requires native exit0 and original receipt PASS_R002R22_NEWLY_OBSERVED_9807_WINDOWS_APPS_SOURCE_METADATA_ONLY, NATIVE_METADATA_REQUESTS_COMPLETED=2, two HTTP200 statuses, two queue-identity validations, independently matching actual file bytes/SHA256 and D4 Count/semantic-SHA. Counts are unknown until read; do not borrow .9711 values. Both outputs remain NEWLY_OBSERVED, never historical pre-renewal baseline proof.

Failure requires exact observed stage/status, actual attempt count and native exit/partial receipt. Preflight/collision/import failures can precede the final metadata receipt: retain the original trace and console output, never manufacture a receipt. The catch deliberately excludes HTTP exception text and signed transport URLs.

## Evidence, cleanup and closure

Queue files contain signed transport URLs: keep them local; do not upload queues, raw URL-bearing exceptions or their source-only ZIP equivalents. Publish only the native summary/trace and hash/count/semantic evidence after inspection. Independently check source unchanged, owned processes ended, exact connector settings unchanged, no unexpected output and actual source/queue identity. Do not claim current mount/hive certification from this step.

Retain the small queue metadata for the next dependency/closure analysis. No large disposable image is created. Source ZIP, predecessors, history, Registry flags and Master remain unchanged.

After each analysis/execution process, write and independently read back relevant Current/Handoff/Session checkpoints. After the actual R22 report perform §0R FIRST before defining one successor step, SECOND Handoff and Session LAST, brief GUI report and pause. Fetch PASS proves metadata transport and D4 parsing only; AppX closure, converter compatibility, MAX_PRE execution and release remain separate gates.
