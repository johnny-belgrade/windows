# R002R26-G3H — Real 31-AppX source-scoped read-only Verify, per-operation journal — 2026-10-24

Boundary: existing R002 only, frozen v9a 728 lines/46855 bytes SHA256 `B422869D4629A87EDD8FC836508DE50BD4F3FC40769AF755D8B52A5ADE08456F`. First separate source/F4/G1/original 31 SHA1 and output/collision guards; real Verify only after all preflight gates. WIM/CBS/registry/ISO/NTLite/VM/cache mutation NOT AUTHORIZED. One operation -> journal + next -> independent Git readback.

## D0 — Master live pin
- GitHub Master v6.3.1 complete 160359 chars read blob `00d3d34e97c35d6fde241f5aa47f17de050d6eb7` unchanged. PASS, no mutation.
- ONE NEXT: Session Entry full checkpoint, then Current and Handoff authoritative scope.

## D1 — Session Entry current
- Entry full 39564 chars blob `21ecd3b865cca467501bce46a21add557a412520`, latest G3G v9a AST0/81 synthetic PASS, one next G3H, real Verify NOT_RUN. PASS.
- ONE NEXT: full Current latest state then Handoff §§0R/0BL/0BE.

## D2 — Current full read
- Main Current blob `89d90a0f8e052711bb5f42086d26abbd276e22ff`, full 1498808 chars, G3G v9a 81 synthetic only, G3H NOT_RUN. PASS.
- ONE NEXT: full Handoff §0R SECOND, mutation/execution permissions and source I/O gate.

## D3 — Handoff latest and governance
- Full Handoff blob `a9bcb45ef72b2bf06f194be775752d93c3db7f3e` 1087148 chars read; §0R SECOND G3H v9a/F4/G1, 31 SHA1, outputs absence and runtime bounds; §0BL scoped source-only Verify/new owned outputs allowed, §0BE operation checkpoints, §12B doc matrix. PASS.
- ONE NEXT: verify RDC live device/policy before native work.

## D4 — RDC device
- DESKTOP-4J4KCEA online ID `d892c878-1a42-4fcd-b0e7-c51caf510ab6`, v0.3.1. PASS.
- ONE NEXT: exact local config allowed roots and blocklist.

## D5 — native RDC policy
- Live v0.3.1 allowed roots exactly `C:\work`/`C:\BLR20R2F5`, 33 blocked including `reg`. No changes. PASS.
- ONE NEXT: Session Entry G3H IN_PROGRESS pointer preflight, then exact native v9a SHA.

## D6 — guarded Session Entry IN_PROGRESS
- Git Entry top CAS commit `8b07825ebf6e8f90a0c0edce09b4122eb2521829`, blob `2754f69f731c28ee7333c929881da240a530f2be` readback confirms scoped G3H and real Verify NOT_STARTED. PASS.
- ONE NEXT: local v9a SHA256 original exact gate.

## D7 — native frozen v9a SHA256
- Native PS7 PID3884 read v9a SHA256 `B422869D4629A87EDD8FC836508DE50BD4F3FC40769AF755D8B52A5ADE08456F` exact previous/Git source pin. No mutation. PASS.
- ONE NEXT: original F4 SHA256, one path only.

## D8 — successor UUP-history boundary README
- RDC directly read complete `C:\work\UUP-history\00_README.md` (38/38 lines), read-only historical corpus, original protected, RH06/RH07/RH08 indices are discovery not runtime. No historical execution, no mutations. Attempt1/3 PASS.
- ONE NEXT: read exact active `C:\work\PREMAX-work\00_README.md`, then local source SHA gates from D7.
