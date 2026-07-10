# Handoff: ground-station setup flow landed + mDNS proposal for iPhone_rc

**Transfer snapshot, 2026-07-10 — not canonical; may be deleted after use.**
Canonical sources: `w17-ground-station/README.md` (feature description),
`w17-ground-station/docs/proposals/iphone_mdns_discovery.md` (the proposal itself),
`w17-ground-station/docs/setup_flow_bench_checklist.md` (validation runbook),
`../CURRENT_STATUS.md` (checkpoints / pending validations).

## What changed in w17-ground-station (Claude Code side), `4103db2`…`3c16954`

- `4103db2` — persisted settings (`settings.json` in userData) + session runtime; env
  vars always override settings; latent macOS IPC re-registration bug fixed.
- `3ab016d` — platform services: WiFi scan/join, hotspot (Mobile Hotspot preferred,
  `hostednetwork` RT5370 fallback), launch-only elrs-joystick-control integration
  (detached spawn, structurally no kill/IPC), sender-IP address-hint seam on the W3
  receiver (accepted packets, IP string only — guard-tested).
- `f771a42` — controller device pick + DualShock/Xbox/generic layout presets.
- `34a1446` — the pit-wall setup UI: GARAGE → PIT WALL → SEAT FIT → GRID → start
  lights; START ANYWAY override; team-radio messages; settings menu (sounds off by
  default, LOG-ONLY W3 toggle, elrs path, telemetry source).
- `b63479f` / `3c16954` — docs (incl. the mDNS proposal) + orchestration tests + bench
  runbook. 217/217 tests green; **OS-level paths are bench-unvalidated**.

## What this means for iPhone_rc (Codex side)

- **Nothing breaking.** W2 (UDP 5601, Windows→iPhone) and W3 (UDP 5602, iPhone→Windows,
  LOG-ONLY) packet shapes, ports, and semantics are untouched. Windows just gained a UI
  way to enable them and to stand up the shared network.
- **One request:** review/adopt the mDNS discovery proposal so Windows can later
  discover the iPhone HUD instead of manual IP entry. Windows has the consumption seam
  stubbed and will implement **nothing** until the canonical contract (owned by
  iPhone_rc) adopts a service definition.

## Codex prompt (paste into the iPhone_rc Codex session)

```text
Context: iPhone_rc repo (you own it and the canonical Windows-bridge contract).
The Windows ground station (w17-ground-station, Claude-owned) has proposed mDNS/
Bonjour discovery so Windows can find the iPhone HUD's telemetry address instead
of manual IP entry. The full proposal is in that repo at
docs/proposals/iphone_mdns_discovery.md — I'll paste it if you need it.

Task — review and, if you agree, adopt the proposal on the iPhone side:

1. Contract addendum in docs/windows_bridge_contract.md (and schemas/examples if
   you keep any for discovery): a new "Discovery" section defining
   - service type `_w17hud._udp.local.`, instance "W17 HUD (<device name>)",
     SRV port = the app's W2 telemetry listen port (default 5601);
   - TXT keys: v=1 (contract version), role=hud, tport=5601, feat=w2|w2,w3,
     dev=<short device name>;
   - the rule that discovery is ADVISORY: receivers treat advertisements as
     user-confirmed hints, never as authority; adding TXT keys is
     backward-compatible, changing the service type or key meanings bumps `v`.
2. Implementation in the iPhone app: advertise via NWListener (Bonjour) while the
   HUD app is foregrounded with its telemetry receiver listening; withdraw on
   background/stop. Info.plist: NSBonjourServices += _w17hud._udp, plus the
   NSLocalNetworkUsageDescription string if not already present.
3. Amend freely where you disagree (naming, TXT keys, lifecycle) — but reply with
   the final adopted service definition so the Windows repo can re-sync its
   contract copy (its rule: §1–7 mirrored verbatim from your canonical doc).

Hard boundaries (unchanged, non-negotiable): W3 head-tracking stays log-only on
Windows; no iPhone→CRSF/servo/gimbal path; firmware stays iPhone-unaware; this
task adds no control semantics anywhere — discovery is addressing convenience
for the send-only W2 telemetry stream. Do not implement anything Windows-side;
that repo is Claude-owned and will follow once your contract revs.
```

## Open items after this handoff

1. Windows bench validation of the setup flow's OS paths — runbook:
   `w17-ground-station/docs/setup_flow_bench_checklist.md`; results go to
   `../CURRENT_STATUS.md`.
2. iPhone_rc adopts/amends the mDNS proposal → Windows re-syncs its contract copy
   §1–7 and implements `mdnsCandidates()` behind the existing seam.
3. Real-device W2/W3 pass on the hotspot network (unchanged from the 2026-07-09
   finding: gate every UDP attempt on a peer-to-peer ping).
