# OP11E2 PRE — resume extracted-only source correction

Keep E helper immutable. Reuse the verified, pristine R050_10066_StageFix1 extraction. New helper uses Environment.NewLine literal detection and a single-quoted PowerShell literal for the exact -LogFolder anchor. Guard all three output paths against known pristine source before writing and independently compare full archive member streams, both loose manifests and native AST after modification. No archive edits, no build.
