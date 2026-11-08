# R033 OP05 — nine native fixture assertions PASS; QA wrapper exit correction

OP04 b0369f26d720e3e39288e819184256bc7fda1fb5 readback PASS. Native PID6028 actual verifier positive PASS; receipt SHA tamper rejected17; log tamper rejected17; native15610 receipt integrity accepted while native_success=False. Actual parser retains Not Present20/20. Finalizer creates HOLD report once and rejects second write preserving first SHA. Fixtures.json status PASS9 tests independently read back in a separate native process.

Material limitation found: QA script omitted explicit final exit0, so caller inherited intentional negative report test exit1 despite nine passed assertions. Record this rather than claim process exit0. New reviewed v1.1 QA adds explicit success exit. Additional source review finds receipt-write I/O exceptions could be caught as ordinary dependency warnings in offline loops; v1.1 wraps receipt/log persistence and verifier failures with fatal marker, before native dependency classification. Do not silently overwrite original v1; retain it under TEMP/Source and source ZIP. New SourceV11 and unique fixture/results paths.

ONE NEXT: author complete v1.1 with these two corrections, native AST/fixtures in new owned TEMP subtree, separate receipt/hash verification, then original vendor Inspect only. No actual image execution.
