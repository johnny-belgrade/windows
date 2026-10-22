# BlueLite R002-R21 — v4 Probe-only execution contract

Date: 2026-10-22. **PREPARED_NOT_AUTHORIZED** for execution during the closed R20 block; **NOT_DELIVERED_NOT_RUN**. The operator requested a pause after R20. Resume only after the operator's next instruction and a fresh Session IN_PROGRESS/readback.

## Exact source and bounded purpose

- [Complete v4 source](../03_Drafts/R002R21_9807_TwoQueue_Instrumented_v4_PROBE_DRAFT.ps1)
- SHA256: 959A04FDA12C319BF60A2DFC806FF1166FC1CE3B9C3F5635A0E11C5233ED4A3E; 8470 UTF-8 bytes.
- Git commit abe232ebee25711ea39b40aaa0e71c06419853c2; blob 1766e509784de49741a293a2e4c5ff721e1f6a80; complete exact readback.
- Parent frozen v3 blob 40b7c0cb41eb4bafd3a0ec4564485067d5b01f66.
- Prospective local source: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R21_9807_TwoQueue_Instrumented_v4_PROBE_DRAFT.ps1
- Only owned write target: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence\R002R21_Probe_001
- Expected trace: R002R21_Native_PreflightStages.txt in that directory.

Purpose: validate the integrated, immutable-source-bound preflight after the R20 synthetic proof. Four ordinary-directory references change from the automatic input variable to sourceRoot; three ordinary query collection references change from the automatic matches variable to queryEntries. R17 trace/function/result identifiers become R21; header provenance/status and a trailing empty line change. The reviewed line diff contains no other behavior changes. Original source ZIP/launcher/contract/module SHA gates, contract predicates, URI uniqueness/scheme/host/path/credentials/fragment/query-key/query-value checks and Probe exit remain identical. Fetch remains unconditionally rejected before all legacy HTTP code; inherited unreachable fetch code is not reviewed into authorization by this preparation.

## Gates and one intended invocation

1. Read complete current Master, Session, Current and Handoff governing/latest sections; verify current Git state, connector device/config/sessions and mandatory local READMEs. Observe the requested pause; no automatic background run.
2. Record Session IN_PROGRESS with exact R21 source/target/command, then independent readback. Inspect whether the prospective local source and trace directory exist. A trace collision is HOLD; never delete, reuse or overwrite an existing trace to make this run succeed.
3. Deliver the complete frozen v4 through ordinary scoped RDC file operations. Native SHA256 must match the pin above. PS7 ParseFile must have zero errors and zero ordinary assignments/references to automatic input or matches; do not count immutable comments as AST expressions. Do not mutate source in place after a failed gate; a material fix is a new revision.
4. Confirm source paths remain the pinned .9807 input and D4 module. No original predecessor invocation, no R18 rejected audit retry and no execution route change to evade an error.
5. Execute once through ordinary RDC default powershell.exe launching this exact child command:

~~~powershell
pwsh.exe -NoLogo -NoProfile -NonInteractive -File "C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R21_9807_TwoQueue_Instrumented_v4_PROBE_DRAFT.ps1" -Mode Probe
~~~

Use short connector timeouts/polls. Require prompt first trace output and native completion; overall observation budget 15s. If unfinished, stop the exact owned RDC process/process tree through authorized connector controls, independently verify its termination, retain partial trace, record HOLD and pause. No blind rerun, shell-switch workaround, unrelated-process termination or security change.

## Acceptance, cleanup and proof limits

Expected final trace includes all source SHA/contract/URI PASS markers, HTTP_GET_REQUESTS=0 and RESULT=PASS_R002R21_INSTRUMENTED_METADATA_PROBE_NATIVE. Require native exit0, independently read and hash the actual trace, inspect that the old R6 queue output has not been newly created by this step, and confirm no owned active process remains. Source code currently proves the intended no-HTTP branch; a future actual trace/exit can prove the executed Probe. No native parser, delivery, trace or Probe PASS is claimed now.

On failure preserve original trace and exact native error/exit and missing post-state; do not write a synthetic PASS receipt. Only small reviewed source/trace files are expected; retain them as evidence. No offline/image target, WIM mount, hive load, converter, package download, registry/security/config change or large disposable file is part of R21. Original source/predecessors remain immutable.

After the actual R21 report: follow Handoff §0R FIRST Current+Handoff write/readback, define one resulting next step, SECOND Handoff, Session pointer LAST and GUI pause. If Probe passes, a separate review may prepare a new bounded two-queue metadata-fetch revision; R21 itself never enables Fetch. Runtime recipe flags remain false until their own component gates are proven.
