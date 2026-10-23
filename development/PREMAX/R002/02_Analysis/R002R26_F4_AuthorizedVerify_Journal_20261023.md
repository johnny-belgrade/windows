# R002-R26 F4 — Authorized SHA-1 Verify, per-action verified journal

2026-10-23. Operator explicitly authorized `R26-F v1 -Mode Verify` and standing analytical autonomy for future successors, retaining Master v6.3.1 and per-action verified checkpoint rule. Governance first: Handoff §0BL commit `730b0417196411fe3d8ff81f39c91b9be682eef2`, full blob `7c7f8f970e993802d35b88624c1bb96820dfa3cd` independently fetched; Session Entry `IN_PROGRESS_R002R26_F4` commit `d9aa7924c0ff4b99168259802a59b9fb8fe8e73f`, blob `a97d817f75f3ad5311f9f435a7e15eaf68c7c395` exact readback.

## A — separate online device + config preflight

Attempt1 RDC list_devices: DESKTOP-4J4KCEA online, ID `d892c878-1a42-4fcd-b0e7-c51caf510ab6`, v0.3.1. Separate get_config attempt1: exactly `C:\work`, `C:\BLR20R2F5` allowed roots; 33 blocked commands including `reg` and default `powershell.exe` unchanged. No config modification; this Verify does not need `reg`.

Frozen F code: `C:\work\PREMAX-work\R002_Universal_Stage1_MAXPRE_Package\03_Drafts\R002R26_F_HistoricCache_SHA1_ReuseGate_v1_DRAFT.ps1`; expected SHA256 `A937E1CE2234AC42840B98F682965DA56E752AF5BC41F9725384AE3DF420670F`. R24 expected SHA256 `2D91B0C75970738DC2DC93A66C75AEA761BC02CB8452DF5B7055FFDE22029A82`; R26 `24DD6D74DB006A7DC9D39190CD3044A62F43DB23863D5CCEEEEF8423D004EDED`. One local read-only Verify after fresh individual guards. Payload read volume at most 115765780 B/110.4MiB; no network, original/cache/Windows image alteration, one new owned JSON only.

**ONE NEXT:** separately list live RDC sessions, journal and readback before hashing source.

## B — pre-launch connector sessions

Attempt1 independent same-RDC `list_sessions`: **No active sessions**. No competing connector-owned process detected. Next: standalone source SHA256, note original PID/stdout; no scripts run yet.
