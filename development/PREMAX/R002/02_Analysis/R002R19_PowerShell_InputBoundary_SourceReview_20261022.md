# BlueLite R002-R19 — PowerShell launch / standard-input source review

Date: 2026-10-22. Tier: SOURCE_REVIEWED; no new Windows process execution. Result: SOURCE_DIFFERENCE_AND_UPSTREAM_MECHANISM_CONFIRMED; ORIGINAL_RUNTIME_CAUSE_NOT_YET_PROVEN.

## Exact gap

R14 v2 and R17 v3 were accepted by RDC but produced no output; R17 did not create its first trace directory. Existing R15/R16 checks prove input-file hashes and URI logic separately. What was missing is a comparison of the *launcher mode and automatic-variable semantics before the first script statement*. No image/component investigation or fresh UUP queue is needed to address this gap.

## Existing evidence actually read

| Evidence | Exact identity / observation |
|---|---|
| Complete Master v6.3.0 | Attached file equals GitHub text; SHA256 022D0BEBE79423E28742B5CF61D9E71D9E331240F2F8BFABD1C153A99BA18736 |
| R14 v2 | Git blob 8f4b1b007334a8867cd1a4053279f8b32b152000; all 118 local source lines match GitHub text |
| R17 v3 | Git blob 40b7c0cb41eb4bafd3a0ec4564485067d5b01f66; all 153 local source lines match GitHub text |
| R15 diagnostic | Git blob 35f1b7d09540893adc71977b86553a75af046ca2; native PID6080 completed in 74ms |
| R16 diagnostic | Git blob ea1ad72f7072a92e046c6adb47e1a30f17e13386; native PID4196 completed in 283ms |
| RDC original start_process history | 90 original calls read; exact R6/R14/R15/R16/R17 command arguments and results compared |
| Library 28-ChatGPT.md | libfile_d76bf84a9600819193af40b7f2fe1a8c, original 65,116 bytes, SHA256 F30813ADF5D54EC5EC884A6019EEC00B73CC2D8E6CE665F9864557EE6930FDAA; targeted R6, R8 and R11P passages read after direct materialization because indexed text was unavailable |
| Local history/workspace guides | Both 00_README files actually read; RH06/RH08 headers and RH07 verification/hash manifest inspected; no claim of reviewing all historical scripts |
| Governance | Current top, Handoff 0AR/0AQ/0R/0S/0L/12B, Sources, Contracts and Registry r38; no component recipe predicate changed |

Local-source comparison here is a full returned-text comparison, not a newly measured native Windows file-byte SHA. Original history remains immutable.

## Confirmed source difference

Both v2 and v3 assign the source directory to PowerShell's automatic variable `$input` and read it in three subsequent Join-Path calls. R15 uses `$inputRoot`; R16 uses a full launcher path.

R14/R17 both used `pwsh.exe -NoLogo -NoProfile -NonInteractive -File <adapter> -Mode Probe` through the default powershell.exe shell. R15/R16 used the same outer shell and -File pattern, so the outer shell alone is not a sufficient explanation.

Earlier R6 native Probe PASS PID3148 used RDC `shell=pwsh.exe` with a command string that parsed the file, then invoked it with the call operator. Its *outer command string* did not contain an actual automatic-input variable expression. This is a materially different startup contract; do not infer v2/v3 -File success from R6.

## Authoritative implementation mechanism

The following original Microsoft PowerShell source files were fetched at the version tag **v7.6.7**, matching R15's recorded engine version:

- [ConsoleHost.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/Microsoft.PowerShell.ConsoleHost/host/msh/ConsoleHost.cs), Git blob `632181d4161dfdf95e3ed12b5e68ca431f34fce8`: asynchronous -File startup parses the script and enables ReadInputObjects when IsUsingDollarInput returns true. The -Command path instead parses the outer command string.
- [AstVisitor.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/System.Management.Automation/engine/parser/AstVisitor.cs), blob `03b234cf41f7fc869c999cf0930081d036c63f8f`: detects a variable expression whose unqualified name is input, case-insensitively, without distinguishing an ordinary path assignment from intentional pipeline-input use; nested scriptblocks are excluded.
- [Executor.cs](https://github.com/PowerShell/PowerShell/blob/v7.6.7/src/Microsoft.PowerShell.ConsoleHost/host/msh/Executor.cs), blob `38924f3e39794c4f81ea54c369f4468c1b154729`: without ReadInputObjects it closes the pipeline input before invocation; with that option and redirected stdin it reads/deserializes stdin before closing pipeline input.
- [Microsoft automatic variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.6): automatic variables are engine-managed and should not be repurposed; input represents pipeline input.

**Inference:** an open redirected stdin plus the accidental input-variable reference explains the otherwise consistent no-first-marker symptom and the R6/R15/R16 comparison. **Not yet proven:** the stdin/EOF state of the original terminated PID2000/PID4608 inner processes, and reproduction with the installed Windows binary. No claim that the original adapter ran, that it was refused by platform execution controls, or that HTTP caused the delay.

The Query function also uses `$matches` as an ordinary collection name. Master §13 already prohibits that naming collision. It is *after* the first R17 marker and cannot by itself explain the absent trace. A later reviewed correction should use a task-specific name, preserve exact URI predicates and rerun their existing exact-gate tests.

## One discriminating next step

Prepare a bounded, isolated diagnostic using two tiny synthetic scripts that differ only in the ordinary variable name: input versus sourceRoot. No original adapter invocation, UUP access, HTTP, registry, WIM or security-setting changes.

Run under the same installed pwsh executable with explicitly redirected stdin:
1. Renamed script with stdin left open must complete with exact stdout and exit 0.
2. Original-name synthetic script with stdin immediately closed must complete identically.
3. Original-name synthetic script with stdin held open must have no first marker during a bounded observation; closing stdin must release it and produce the same exact output.

The test must print script-entry evidence, native engine version, fixture hashes, timing, stdout/stderr and exit status; reject mismatched/error outcomes. Bound child lifetimes and clean up only children created by the test. Preserve its own small immutable receipt. This tests the mechanism; a corrected integrated adapter Probe is still a later separate current-source gate.

## Scope and closeout

R19 used read-only Windows tools and GitHub documentation. No Windows script was launched; no new Windows artifact was created. The previously rejected R18 local audit was not retried or recreated. No connector configuration changes, downloads of UUP payloads, image operations or large disposable files. No fresh mount/hive state certification is claimed because R19 did not execute native image diagnostics. Active RDC sessions were empty at bootstrap.

26300.9807 original source UUID/ZIP pins remain unchanged, original pre-renewal Windows/Apps baseline UNKNOWN, newly observed queue GETs 0/2, Registry runtime flags unchanged. R19 is a source review and prepared diagnostic, not a MAX_PRE runtime or release PASS.
