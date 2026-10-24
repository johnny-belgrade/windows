# R002R26-G3D — strict ZIP central-directory guards and real 31-AppX graph Verify design

**Status:** REVIEWED DESIGN ONLY / no runtime CERTIFICATION. Source R002 G3C v6 SHA256 `D407B162BCFA62BCE347C073AE5FFA8481B1722A09D9A7032B86E2016C36A401` / Git blob `0c4b4f7f9935176dd82c7c1dac66185d3f4f9c7c`, target 26300.9807 UUID `687d1ced-aab1-4cd5-ad05-705189769731`.

## 1. Input shape and fail-closed constraints

A real AppX/MSIX or bundle is ZIP-based but the current v6 simply uses .NET `ZipArchive` and reads manifest entry bytes. Its tests cover 50 synthetics, not the raw central headers. For each *bounded, seekable input stream* inspect the terminal End of Central Directory (EOCD) within max comment+22 bytes, require final EOCD comment length consistency, single disk, entries count <= `$MaxEntries=4096`, central-directory size/offset within the stream, exact per-entry CDFH signature `0x02014b50`. Reject ZIP64 sentinels, encrypted/strong encrypted flags (bit 0, 6), unsupported compression method (not stored=0/deflate=8), unknown flags, split/multi-disk members and malformed/truncated or duplicate entries with **specific HOLD** reason. Preserve central-directory byte spans and name/entry count matching with `ZipArchive`; never trust only one header copy. For each nested bundle, apply the same checks at depth one.

No unbounded memory allocation. Never treat absent CRC as zero; compare the CRC32 of each **decompressed manifest XML** used for graph parsing against its central-directory CRC32 using a bounded source-local implementation, report `ZIP_MANIFEST_CRC_MISMATCH`. Nested ZIP member payload integrity and nonmanifest payload CRC are separate proof tiers. Verify existing source SHA1 first and original/cache read-only.

## 2. Synthetic test matrix (pure in-memory)

Create ZIP archive via existing `New-SyntheticZip`; alter **only in-memory ZIP bytes**, never source files. Include: valid stored ZIP and valid deflate ZIP; encrypted bit0; strong-encryption flag; unsupported method=12/99; corrupt EOCD, truncated CDFH, invalid central offsets/count, ZIP64 sentinel, multi-disk marker, local-vs-central flags/method inconsistency, CRC mutation in central header and CRC mutation in local header; safe optional UTF8 flags; ZIP data-descriptor case; duplicate/casefold and unsafe path keep v6 negative suite. Expect explicit rejection code for each and positive control. Each negative must confirm the checker actually reaches intended branch and not a generic exception or unrelated Hold.

If strict real archives contain a supported ZIP variant not covered by fixture gates, classify as **HOLD_SOURCE_FORMAT_DEPENDENCY** and refine with separate reviewed proof; do not silently fall back.

## 3. Real AppX read-only Verify (later distinct block)

Preflight: Master/Session/Current/Handoff + contract, v7 exact script SHA, G1 five providers and F4 26 seed selected name/SHA1 + UUID/R23 metadata equality; original historical cache 31/31 names present; independent exact package SHA1 source byte check in Verify, read-only FileShare.Read, no network. Future evidence directory must not preexist; write only a newly owned report. Bound per-package archive entries/decompressed limits, classify every consumer→provider exact name, publisher, min version, architecture and ambiguous match; explicitly separate **EXTERNAL_PROVIDER_DEPENDENCY_WIM_FLOOR_NOT_EVALUATED** from graph-resolved-in-31. Target UUID-specific AggregatedMetadata CAB is separate NOT_ACQUIRED and cannot be inferred from 31 packages.

Validation must check code AST0, all synthetic tests, all source guard failures, report schema, no original/cache/source or live host mutation. Only a later independently checked operator-reviewed checkpoint can mark real graph evaluated. End each G3D block in §0R sequence, with GUI pause.
