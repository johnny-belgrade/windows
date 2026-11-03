# R008 source repair scope

Source: GitHub ab94087829167781a0dfad9ce5e7c11139eb6574; native R007 v6 overlay 38 files / 37 manifest rows verified. R006 v5 native evidence 27 members independently verified. Entire 366-file GitHub snapshot retained unchanged.

Fix only source gates and misleading delivery labels. Before any network, validate all three metadata maps, not just presence/size. Reject malformed data rows, duplicate records, unsafe names and incomplete D4 records rather than ignoring them. Keep rename CMD data-only. Bind precut classification to SHA256 of the exact queue and metadata inputs, removing reliance on a bare PASS string. Refresh classification on resume. Preserve proven WIM engine, recipe policy, AppX dependency resolver, renewal and native converter hook.

Verification: original 98-entry source triad and native queues; missing/mismatched/malformed/duplicate inputs; changed queue after gate; stale marker; tampered overlay; unsupported build; AST in PS7 and PS5.1. No download, converter execution, WIM, CBS, registry or ISO mutation. Run each test in a child process, write individual immutable native receipts and verify each in another child process.

Known unresolved: F01 DesktopAppInstaller ownership, F02 Language.Basic CBS, F03 WMIC selectors, F04 WIM promotion transaction, two-source native universality, Setup/VM/installed footprint and release certification. No source FoD omission proven: preserve Windows reconstruction inputs.
