# R028 OP06 — source-only PatchEngine identity matcher false HOLD, no image mutation

- Corrected exact pinned PreDebloatWim SHA through GitHub CAS commit d78f92fd79958cd9eb22855594b64dbead6e53a5, blob 94200d05223486e0d054f2240f4da31409823398; independent Git fetch and exact local text readback PASS.
- Native Windows PS7 PID9924 ran PatchEngine -Mode Inspect only on isolated OWNED minimal fixture, returned R028_PATCH_HOLD_WIM_IDENTITY_ANCHOR_COUNT_0.
- Independently inspected original donor PreDebloatWim source lines around 466; exact line is: if (($exportInfo -join [backtick]n quoted) -notmatch [regex]::Escape($actualBuild)) { throw Compact export identity gate failed: expected build $actualBuild. }. Need avoid over-specific nested regex, require ONE exact line that contains both error string, original Get-WimInfo variable and unchanged quoted build marker.
- No operator R027 stage changes, no source downloads, no WIM mounts or ISO. Next: implement validated unique fail-closed full-line anchor with precise content conditions, switch new FoD helper to PS7 to avoid inherited PS5 module path limitation, Git CAS, readback, local readback, rerun synthetic Inspect and native AST. 
