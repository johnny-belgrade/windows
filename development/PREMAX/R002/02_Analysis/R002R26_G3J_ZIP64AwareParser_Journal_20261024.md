# BlueLite R002R26-G3J — ZIP64-aware bounded parser draft / synthetic fixtures — 2026-10-24

Project existing R002 only, target 26300.9807 Pro amd64 en-US UUID `687d1ced-aab1-4cd5-ad05-705189769731`. Controlled cycle: one operation → journal append → independent fresh Git readback → next. Master unchanged. **No original AppX, v9a, WIM/CBS/ISO/registry mutation, no actual v9a Verify rerun.**

## D0 — authoritative bootstrap source-bound reads
- GitHub read complete Master Strategy v6.3.1 original blob `00d3d34e97c35d6fde241f5aa47f17de050d6eb7` (160359 characters, 1625 lines) first, then full Session Entry blob `0e04dff344c0940d6c8bb198fc0dfdc696073467` (46058 chars), live Current full blob `8dbcfa37a0c15f04528efa880dfe8ccd0bd0b0ff` (1508201 chars), Handoff full blob `5f969dba72fe695d63a9cd8b160db94f4f0ad2b1` (1098532 chars), mandatory latest §0CD / §0BL / §0BE / §0R / §0S / §12B; exact prior G3I journal blob `0e2b6ae1928c85c348ce4b77ae8f6d4c70863908`. Last proved G3I native 31 original SHA1 PASS; all classical ZIP EOCD sentinel, one independently verified ZIP64 locator & record, 31 XML graph HOLD; G3J source NOT_DELIVERED_NOT_RUN.
- Operator physically confirms installed `C:\Program Files\7-Zip\7z.exe` but tool access is confined to RDC allowroots; operator did not run PS or restart RDC. No claim that exact binary was remotely executed. No PATH/connector config mutations. Initial document bootstrap = read-only, PASS.
- ONE NEXT: live GitHub identity and RDC device/config connection evidence; inspect original source and create only new source-owned G3J draft, negative fixtures first.

## D1 — authenticated GitHub reconnect
- Native GitHub `get_user_login` returns `johnny-belgrade`, authenticated ID 323928627. PASS attempt1/3, no protected mutation.
- ONE NEXT: RDC online device discovery.

## D2 — RDC connection
- Fresh `list_devices` shows DESKTOP-4J4KCEA Online, device `d892c878-1a42-4fcd-b0e7-c51caf510ab6` RDC v0.3.1. PASS attempt1/3, no config mutation.
- ONE NEXT: read full connector config to confirm root and 33 blocked commands.

## D3 — live RDC policy and 7-Zip boundary
- RDC v0.3.1 native config exact allowed roots `C:\work` and `C:\BLR20R2F5`, 33 blocked commands incl `reg`, default shell powershell.exe, unchanged. Operator physical `C:\Program Files\7-Zip\7z.exe` exists outside allowed roots and is NOT being accessed or executed through RDC; PATH change not needed for G3J code. PASS attempt1/3.
- ONE NEXT: review pinned G3G v9a ZIP parser and G3I sample implementation before new source creation.

## D4 — frozen v9a parser-source review
- Read full Git original v9a source path `development/PREMAX/R002/03_Drafts/R002R26_G3G_AppxManifestGraph_v9a_DRAFT.ps1`, original blob `333befcf162b53bf0ce8a73fabfbd5a22705ab57`, 46855 chars. Existing `G3E-Check-ZipCentral` rejects ZIP64 EOCD sentinel or central 0x0001 extra, then otherwise checks entry count, EOCD layout, flags, compression, CRC, path, casefold, local-central name, offsets. `Read-Archive` relies on its dictionary of manifest CRCs before bounded .NET ZipArchive. All this original MUST remain unmodified; G3J standalone candidate can return matching `Dictionary[string,uint32]` with safe ZIP64-aware central validation, not claim integrated graph PASS.
- ONE NEXT: verify new exact G3J local draft path does not exist, then create nonoverwriting source-only candidate with in-memory positive/negative fixtures.

## D5 — new G3J draft destination guard
- Native RDC PS7 PID1748 `Test-Path` exact `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\04_StaticTests\R002R26_G3J_Zip64Central_v1_DRAFT.ps1` = False. New owned version noncollision, no original/source mutation, attempt1/3 PASS.
- ONE NEXT: author reviewed standalone bounded ZIP64/classic central-directory validation and synthetic positive/negative cases only under this new path, then full readback and AST.

## D6 — original G3J v1 source-only candidate created
- RDC `write_file` wrote **new, previously absent** 212-line standalone draft `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\04_StaticTests\R002R26_G3J_Zip64Central_v1_DRAFT.ps1`; no overwrite and no v9a/original/cache mutations. Contains ZIP64 EOCD+locator/record, bounded 64-bit counts and central offsets, optional zero-length ZIP64 extra, entry/local/CRC/path checks, generated in-memory classic/ZIP64 fixtures including adversarial negative cases. **SOURCE WRITE only; complete local source readback, native AST, hash and any self-test pending.** Attempt1/3 write confirmed.
- ONE NEXT: independent full 212-line source readback; journal and verify before AST.

## D7 — independent 212-line source readback
- RDC direct read completed full 212/212 lines from new owned G3J v1; verified isolated `SelfTest` entrypoint, in-memory fixtures and no original access/filestream original or output write. ZIP64 record/central/path/local/CRC guard functions are present. No claim AST/test readiness. Attempt1/3 readback PASS.
- ONE NEXT: native PS7 parser AST-only examination of exact owned v1, separately journal result before any execution.

## D8 — native v1 PS7 AST zero errors
- RDC native PS7 PID9400 parsed exact new 212-line G3J v1 source, printed `G3J_V1_AST_ERRORS=0`, process finished. No source execution or artifact changes, PASS attempt1/3.
- ONE NEXT: native SHA256 pin of exact G3J v1, journal and readback, then isolated synthetic-only SelfTest.

## D9 — native G3J v1 source SHA256 pinned
- RDC native PS7 PID11084 `Get-FileHash` exact new owned 212-line G3J source = `945779796A2037A1840BE987590605E0DC930FB6A04BBE0CC0C74839D0877618`. Process finished; source-level SHA PASS attempt1/3. No original changes.
- ONE NEXT: isolated `-Mode SelfTest` against only in-memory classic/ZIP64 fixtures; if fail report literal details and preserve frozen v1 source, do not overwrite it.
