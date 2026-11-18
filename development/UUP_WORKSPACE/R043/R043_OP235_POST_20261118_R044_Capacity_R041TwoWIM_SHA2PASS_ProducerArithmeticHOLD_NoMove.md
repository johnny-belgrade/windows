# R043 OP235 POST — R044 C capacity read-only: two historical R041 WIM full SHA independently PASS; initial producer arithmetic HOLD; no file move

Date 2026-11-18. PRE Git commit edbee339835bead3fd1d176c473bf0932a426746, blob 5adc2dfda40731dd93be79d4ea902e7384; independent PRE fetch/readback PASS. Last prior immutable R043 OP234 POST blob c2bf33b565c0684a9a9019fc35c996c54a0947ca. Master blob 3b32f372267fb6fb8fbdb5430476d915c4054 UNCHANGED.

## What actually ran (read-only, no D filesystem access)

- Native PS7 PID2920 producer, exit0 / 23.09 s; source C:\\work\\scripts\\BlueLite_R043_OP235_ReadOnlyCandidates_v1.ps1 SHA256 D15A1FEE22DCEDCB58DDE96EC8BA707E7C7961A5BC2BDACA9F8F9A575C21C02F AST0.
- Immutable producer C:\\work\\logs\\R043_OP235_HistoricalWIM_Capacity_Producer.json SHA256 73FF97AF087A105FB36A016C55E726F80F197EDDE4ED9BD1D64A16EAE3983CA0. Correct actual physical source file sizes and SHA256, 3 VM Off, WIM mounts0, neither target VM-referenced or a reparse file. **Recorded CandidateTotalB=0 is a REAL PRODUCER ARITHMETIC BUG** due Measure-Object on ordered-hashtable rows: source arithmetic part HOLD, never corrected/overwritten or represented as PASS.
- Revised independent fresh PS7 PID9076 verifier, exit0 / 22.99 s; source C:\\work\\scripts\\BlueLite_R043_OP235_IndependentVerify_v2.ps1 SHA256 DFAE0B3C49EFBE7326641FC215B0816827AF7D8E81CEFDEFD05044C70713D5F1 AST0. Separate independently streaming full SHA256 on both 7+GB source bytes PASS; independently computes total without Measure-Object; verifies no VM path reference, zero WIM mounts, untouched R044 ZIP SHA.
- Immutable independent QA C:\\work\\logs\\R043_OP235_HistoricalWIM_Capacity_IndependentVerify_v2.json SHA256 1CC64D5B3C424D3839733F0318B2BB2643D5342E0C99495C7872738777A9A735, exact read_file PASS. Third independent certutil exit0 verifies full actual producer SHA 73FF97AF... and verifier SHA 1CC64D5B... MATCH. Original v1 independent verifier was written but **NEVER EXECUTED**; no receipt claimed from it.

## Actual candidate facts (NOT delete eligibility and NOT actual reclaimed capacity)

1. R041 stage BlueLite_R029_install.precompact.wim, exact bytes **7,432,403,765**, source and independent full SHA256 **0C8D5A853611C8EF84879CDDBB716FAA90DD74A1F625BA79822CEC4F27453C3D**.
2. R041 stage BlueLite_R033_reconstructed.baseline.wim, exact bytes **7,384,196,890**, source and independent full SHA256 **5421EE6EBEF27F147B3B7C667D9FD1325F78CE8BD8FC735DA3F05668A49713C1**.

Physical SHA2/2 PASS; combined **14,816,600,655B LOGICAL**, independently calculated, different source files, no Hyper-V VM path references and no mounts. These are UNIQUE historical WIMs (do not treat as duplicates) and remain physically untouched on C:. NTFS hardlink count/fileIDs, all historical script-path dependencies and physical reclaim have not been certified for MOVE. No operation on D: performed.

## Exact capacity gate

At producer sampling: C free **100,400,410,624B**, R044 protected hard gate **107,374,182,400B / 100GiB**, gap **6,973,771,776B**. D volume metadata free **124,959,211,520B**; **D filesystem is outside RDC allowedDirectories ["C:\\work"]**; no D browsing, writes or scope bypass. If BOTH unique files are safely relocated as independent exact SHA-preserved copies then C file logical size sum 14,816,600,655B would make hypothetical free **115,217,011,279B** and surplus above 100GiB 7,842,828,879B; these are NUMERICAL SCENARIO ONLY, NOT measured NTFS allocated free or actual post-move result. Required actual gain and keeper checks must be independently measured. R044 clean delivery ZIP still 126438B SHA D77781967775FF4E09866A0F790E4DC37FA80DFAB51E0765FF507E4C8085515E; actual 26300.10066 new WIM/ISO STILL NOT_BUILT.

**Final OP235:** READ_ONLY_WIM_SHA2_INDEPENDENT_PASS / PRODUCER_NUMERIC_HOLD_PRESERVED / R044_BUILD_STORAGE_HOLD / ARCHIVAL_MOVE_NOT_RUN / ZERO_BYTES_RELOCATED_OR_DELETED. No protected source, image, VM, Master or ZIP mutated. No Git document other than immutable OP235 PRE/POST and compact Current updated.

## Exactly ONE NEXT

**R043 OP236 — USER TARGET-SPECIFIC RELOCATION AUTHORIZATION GATE**: operator explicitly approves or rejects exact SHA-preserving archival relocation of the two named protected unique historical R041 stage WIMs to a reviewed D: archival destination (or supplies >7GB independently confirmed alternative C free). Only after approval: preflight NTFS hardlink/fileID/reference + D volume/destination+expected SHA+capacity, separately scoped operator-local move transaction copy→independent D SHA/readback→source deletion only with approved exact path/keeper proven→independent C free/mount/VM verification, per-file PRE/POST, no wildcard and no R044 build until C free >=100GiB. If D remains outside RDC allowlist, prepare a reviewed Lane B operator script, do not evade connector restriction. Boot-speed SECOND.
