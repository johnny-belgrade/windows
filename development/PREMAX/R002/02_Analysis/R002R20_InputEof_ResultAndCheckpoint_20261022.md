# BlueLite R002-R20 — native input/EOF diagnostic result and successor checkpoint

Date: 2026-10-22. **EXECUTED_PASS / GUI_PAUSE_AWAITING_OPERATOR**.
Result: **PASS_R002R20_SYNTHETIC_INPUT_EOF_MECHANISM**.

## What was analyzed and recorded before execution

The [R19 source review](R002R19_PowerShell_InputBoundary_SourceReview_20261022.md) compared frozen local/Git adapters and original Microsoft PowerShell v7.6.7 ConsoleHost/AstVisitor/Executor source. The v2/v3 adapters assign an ordinary source directory to automatic input. For -File, the engine detects that expression and may wait for redirected stdin EOF before running the script. A second ordinary collection uses automatic matches and must be renamed independently.

The operator's post-interruption instruction authorized one planned diagnostic block after prior analysis/plan recording, then actual result/checkpoint records and a pause. The [complete R20 source](../04_StaticTests/R002R20_InputEof_Diagnostic_v1.ps1) and [execution plan](R002R20_ExecutionPlan_20261022.md) were published and exactly read back. Current prework commit3f4e76e39e428a27e353bf52193c2ea658cb53f6, Handoff R19 SECOND f56e79ce6774c08b4efdefe970d7d9c421e1aad0 and Session IN_PROGRESS bf0c2e15af98e0f6908972243ba74c3af97eee0e were verified before local source delivery.

## Source identity and native gate

| Artifact | Bytes | SHA256 |
|---|---:|---|
| R20 diagnostic source | 7496 | DEED0863D04FFEE56286A79695C7A899D68C3562F244075D560D114FBF122D27 |
| AutomaticInput.ps1 fixture A | 129 | C9252A519CDC8EB1C135CE17DFDA292BAC2EF606531334950EFA20443D72DFF2 |
| OrdinarySourceRoot.ps1 fixture B | 139 | 909BA4E6C4716FF1050EFB3B4DA997DB48F1CD054296DD63DF4E64A806B0F218 |
| Original native JSON receipt | 1933 | D6D7FD2E139DF3D007C9F6EBB1E5A5382257F957CDA26C11309321E6A6178F69 |

The source was delivered once in five bounded write_file chunks. The read_file display omitted one final empty line, causing the first display-only equality comparison to fail. Native PID7684 independently read 7496 bytes, exact published SHA256, final character codes ending10,10, zero ParseFile errors and zero parent automatic-input AST references on installed PowerShell7.6.7. No source rewrite or rerun was needed.

## Actual native execution

One ordinary RDC default powershell.exe launch of pwsh -NoLogo -NoProfile -NonInteractive -File; outer PID1864, native diagnostic parent8620. Tool completion was exit0/runtime3.46s. Receipt started2026-10-22T17:43:16.8742013Z and finished2026-10-22T17:43:18.9575925Z.

| Controlled case | Child PID | Elapsed | Observed result |
|---|---:|---:|---|
| Ordinary sourceRoot, stdin left open | 6020 | 232ms | PASS; exact output, exit0 |
| Automatic input, stdin immediately closed | 7372 | 210ms | PASS; exact output, exit0 |
| Automatic input, stdin held1500ms then closed | 6948 | 1585ms | No first line or exit before EOF; then exact output and exit0 |

All cases had empty stderr and exact stdout R20_BEGIN / R20_VALUE=fixture / R20_END. All children exited normally; no forced termination. Code enforces short bounded waits and only owns its child objects. One diagnostic execution attempt, no network requests or original adapter invocation.

Native original: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence\R002R20_InputEof_001\R002R20_InputEof_NativeReceipt.json.

[Byte-exact Git mirror](../05_Evidence/R002R20_InputEof_NativeReceipt.json): commit0095bcd80259f67c532c66657aace18c521cb274 / blobff34f9f2728cd7d8098abe72f95def9c78466b26. RDC read_file normalizes CRLF to LF in display; restoring those61 line endings produced exactly1933 bytes and the independently measured native SHA256 above. Git fetch returned identical CRLF content. The original receipt was not edited.

## Independent post-state and proof limits

Native closeout PID6140 at17:43:48.9095535Z independently hashed all four files and found no outer1864,parent8620,child6020,7372,6948 processes. Its own command completed. RDC session listing was empty. Connector0.3.1 protected configuration matched prework exactly: allowedDirectories C:\work and C:\BLR20R2F5,33 blocked commands,default powershell.exe,read/write limits unchanged. The previously rejected R18 audit remained absent.

The result **proves the controlled input/EOF mechanism on installed PS7.6.7**. It materially strengthens the R19 explanation for R14/R17 no-output, but it does not recover the historical terminated processes' stdin handles. That exact retrospective causal attribution remains an inference. It does not certify an integrated adapter Probe, HTTP transport, pre-debloat package, image or release.

Fresh .9807 Windows/Apps metadata GETs remain0/2; original pre-renewal baseline remains unknown. No UUP payload/converter/DISM/WIM/ISO/registry/NTLite/VM/security setting operation occurred. The four tiny retained files total9697 bytes; they remain useful evidence, no large disposable copy exists.

Immutable source: 26300.9807 amd64 en-us Professional; UUID687d1ced-aab1-4cd5-ad05-705189769731; original ZIP SHA25683203A6E79E62579A7D64204120BCECC111FE114C614AB1DBFAE032BB02DE7B7. Master blob7e1433ff26448e094f6f9cf5b5170972a27fa210 remains unchanged. Registry r38 and all seven runtime_execution_allowed=false remain unchanged; this runtime diagnostic supplies no new component recipe/topology. Contract schemas and historical UUP evidence need no alteration.

## Recorded next step, not executed

Handoff §0R FIRST was completed before preparing the next source: Current8ea20bb24819da76540bcae87fc8d97cfd898401 / blobad4c3d9d721e605a0e7968ee2c6ee41b693bb228 and Handoff73f5a9b011c467092dbbfe50d03b0ef1782ca32a / bloba32d766e6ae9eb88e788b72598b07fd3caacac56; both exact readback.

One [v4 Probe source](../03_Drafts/R002R21_9807_TwoQueue_Instrumented_v4_PROBE_DRAFT.ps1) is now prepared with only the two automatic-variable substitutions, new R21 trace/result identifiers and provenance/status comments. Source commitabe232ebee25711ea39b40aaa0e71c06419853c2 / blob1766e509784de49741a293a2e4c5ff721e1f6a80,8470 bytes,SHA256959A04FDA12C319BF60A2DFC806FF1166FC1CE3B9C3F5635A0E11C5233ED4A3E; exact readback. Frozen predecessors and every original guard remain; Fetch is still hard-disabled.

The [complete next execution contract](R002R21_ProbeOnly_ExecutionContract_20261022.md), commitf282ac614a88228621ed92e9c50a6fe795dbc03c / blob5ffb437c2f652eebccdb534ba7e6a65bd6506af6, states prospective local paths, AST/hash/collision gates, exact ordinary -File -Mode Probe command,15s observation limit, owned-process cleanup, expected R002R21_Native_PreflightStages.txt and actual-result closure requirements. Status **PREPARED_NOT_AUTHORIZED / NOT_DELIVERED_NOT_RUN** during the requested pause. No native syntax or execution PASS for v4 is implied.

**ONE NEXT on operator resumption:** deliver, verify and run only the pinned R21 native Probe under that contract. No Fetch or subsequent block in the present session. Synchronize Current, Handoff SECOND and Session Entry LAST, give the brief GUI report, then await instructions.
