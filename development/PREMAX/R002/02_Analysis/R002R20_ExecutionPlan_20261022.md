# BlueLite R002-R20 — authorized execution plan

Date: 2026-10-22. Prepared before execution. State at publication: APPROVED_NOT_RUN.

The operator requested, after a platform interruption: finish the analysis, record the evidence and planned steps before execution, execute the planned block, document its actual result and successor checkpoint, then stop for GUI review. This authorizes this one bounded diagnostic block.

## Reason and proof boundary

[R19 source review](R002R19_PowerShell_InputBoundary_SourceReview_20261022.md) identifies a concrete PowerShell automatic-input dependency. In v2/v3 an ordinary directory is assigned to the automatic input variable. Original PowerShell v7.6.7 source activates stdin consumption when -File detects that variable. The terminated historical PIDs' stdin state remains unavailable. This test checks the mechanism with new tiny synthetic fixtures, not the original adapters or HTTP transport.

## Reviewed source and exact paths

- Git source: [R002R20_InputEof_Diagnostic_v1.ps1](../04_StaticTests/R002R20_InputEof_Diagnostic_v1.ps1)
- Source SHA256: DEED0863D04FFEE56286A79695C7A899D68C3562F244075D560D114FBF122D27
- Git source commit: 6277365eabbfb0d490ff347cf0bf223379d45f5c; blob f3e9a39eeecea4ac65bab749595a2bba319745f0; exact readback confirmed.
- Local source: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\04_StaticTests\R002R20_InputEof_Diagnostic_v1.ps1
- New fixture directory: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\04_StaticTests\R002R20_InputEof_001
- New receipt directory: C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\05_Evidence\R002R20_InputEof_001
- Expected native report: R002R20_InputEof_NativeReceipt.json in that receipt directory.

The source and both output directories were absent in direct RDC listings. The v1 source is frozen; material correction must receive a new revision. Preserve existing history and the rejected R18 audit's absence.

## Execution sequence

1. Refresh the short Session Entry IN_PROGRESS with exact scope and independently read it back.
2. Deliver the complete reviewed source through ordinary RDC write_file; read it back and compare the complete text.
3. Use the installed PS7 parser to verify zero AST errors, native source SHA and zero unintended automatic-input expressions in the parent. This is an AST/source gate only.
4. Invoke the source once using the ordinary pwsh -NoLogo -NoProfile -NonInteractive -File launch.
5. Three controlled cases: renamed variable with stdin open completes; automatic input variable with stdin closed completes; automatic input variable with stdin held open emits no first marker until EOF, then completes.
6. Each child requires exact stdout, empty stderr and exit 0. Child waits are bounded; cleanup targets only the child's own process object. Record all actual outcomes and never convert an unexpected timing/result into PASS.
7. Independently read the native JSON, verify source/fixture hashes and finished owned children/sessions, preserve exact original receipt and Git mirror, then update Current, Handoff FIRST/SECOND and compact Session Entry LAST.
8. Stop after a short GUI report. A corrected integrated adapter, fresh metadata GET and all converter/image work are future steps, not part of this block.

## Operational envelope

Low CPU, three short PS7 child processes, only small source/fixture/report files under the exact R002 directories above. No large transfer or disposable image. No command unblock, allowlist change, registry/DISM/WIM/ISO, source overwrite, converter, NTLite or VM. No launch of v2/v3 and no retry/recreation of the rejected R18 local audit.

Success is PASS_R002R20_SYNTHETIC_INPUT_EOF_MECHANISM, which proves the controlled test mechanism on the installed engine; it does not retrospectively recover the original PIDs' handles or certify the integrated adapter or MAX_PRE. Failure is HOLD with exact stage/error and cleaned owned children. At most three attempts for one problem, no blind retry; stop immediately on definitive platform denial.
