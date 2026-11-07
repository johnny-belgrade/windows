# R028 OP02 — native READ-ONLY Inspect, diagnosed interpreter defect

- Operator-selected real root: C:\work\_UUP_PREMAX_v11.2, one original UUP archive and full extracted vendor. Source controller SHA: Git blob c33973ff261095f20c56402d15a5e95a1309370b; readback PASS after prior platform interruption.
- PID1672 real native Windows PS7 '-Mode Inspect' returned: R028_CONTROLLER_HOLD The term 'if' is not recognized as a name of a cmdlet, function, script file, or executable program.
- Cause in new root controller: inline '(if($null -eq $stage){...}else{...})' used as though if expression returned in parentheses. PowerShell requires precomputed variable or subexpression with $(), not command invocation of 'if'.
- No WIM mounting, source download, image writes, cleanup or original vendor changes occurred. Controller generated no new image. Next: replace inline if with simple variable; Git CAS, fresh independent fetch, RDC write+readback, native PS7 AST, retry READ-ONLY Inspect. Separately verify no different source stage selected.
