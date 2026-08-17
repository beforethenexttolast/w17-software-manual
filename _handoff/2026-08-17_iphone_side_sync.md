# Codex handoff — iPhone-side sync: what moved on the Windows/GS side (2026-08-17)

**Transfer snapshot — not canonical.** Canonical sources: the Codex-owned contract set
(`iPhone_rc/docs/windows_bridge_contract.md` + `schemas/` + `examples/`); on the Claude side
`w17-ground-station` at `main` = `ca1cb86` (implementation copy
`docs/windows_bridge_contract.md`, code cited per item), `W17_PRODUCT_VISION.md`, and
`CURRENT_STATUS.md`. Ownership per `WORKSPACE_MAP.md`: `iPhone_rc` is ChatGPT-Codex-owned;
`w17-ground-station` is Claude-owned; this file goes stale and may be deleted after use.

Delivery note: the workspace convention delivers Claude→Codex transfers into
`iPhone_rc/docs/`, but this pass does not write into Codex-owned repos. The owner ferries
this file over.

---

## 1. What changed on the GS side (iPhone-HUD-relevant)

### 1a. mDNS discovery of the HUD is now implemented on Windows (CB4, `92cd894`, on main)

The Discovery section your side made canonical on 2026-07-10 (and the iPhone has advertised
since `1e332ef`) now has its Windows receiver: discovered HUDs appear as **suggestions** in
the PIT WALL address field, next to the last-W3-sender hint. Code:
`shared/dnsWire.js` (wire codec), `shared/hudDiscovery.js` (contract policy),
`main/HudDiscovery.js` (transport); no dependency added (hand-rolled over `node:dgram`).

As-implemented service/TXT acceptance (`shared/hudDiscovery.js`):

- Service `_w17hud._udp.local.`, instance `W17 HUD (<device name>)`, SRV port = W2 listen
  port (default 5601) — exactly the canonical definition, mirrored at rev `84532ed`.
- `v` is treated as the **only mandatory TXT key**, and must be `1` (else declined
  `unsupported-version`). `role`, if present, must be `hud` (case-insensitive).
- `tport`, if present, must equal the SRV port — a mismatch is declined (`port-mismatch`),
  per the contract's "must match" rule; we decline to guess which port is real.
- `feat`: unknown tokens are dropped, not rejected (known: `w2`, `w3`). `dev`: clamped to
  32 printable-ASCII chars. Max 8 candidates, one per address, 30 s age-out; a TTL-0
  goodbye retires the entry.
- An advertisement naming a different host than the datagram's sender is declined.

Behavior notes your side may care about: the query is demand-driven (only while PIT WALL is
the active setup step; never in the background, never in sim mode), sent from an ephemeral
port with the QU bit rather than binding 5353, out every local IPv4 interface. Advisory per
the contract: a suggestion is click-filled by the operator and the GRID ping stays the
ground truth — nothing is ever auto-applied. **Real-device verification is PENDING** (all
evidence is byte fixtures; residuals in `docs/proposals/iphone_mdns_discovery.md` "As
built"). First bench run with a real phone exercises QU response behavior and the
sender/address match first.

### 1b. Low-battery banner on the laptop HUD (`6268cad` + review fixes `abaddbd`, on main)

Vision operator-model item "unmissable low battery" (car lights already pulse; the HUD
banner is the ground-side half). `w17-ground-station/shared/lowBattery.mjs`:

- Thresholds in **pack volts** (what `battery_v` carries): defaults **warn 7.0 V /
  critical 6.6 V** (3.5 / 3.3 V per cell on the 2S pack), configurable in ⚙ +
  `settings.json`; hysteresis 0.15 V, enter-immediately / exit one level at a time.
- Exact copy (`LOW_BATTERY_LABELS`): warn **"BATTERY LOW — finish your lap and park"**,
  critical **"BATTERY CRITICAL — park the car now"**. Plain language by requirement; the
  BATT panel next to it shows the number.
- Display-only, derived in the renderer from telemetry it already receives; the
  warn-never-auto-cut safety invariant is untouched.

**Parity suggestion** (ask 2 below): the iPhone HUD receives the same `battery_v` in the W2
snapshot, so the same classification can be computed client-side — same thresholds, same
wording family, and both screens tell the same story. No schema change involved.

### 1c. Race-day autoBridge: W2 can start without a human toggling it (branch, not merged)

Branch `feat/race-day-orchestration` (tip `a64fa0d`, in owner review — **not on main**).
One giftee-facing RACE DAY press sequences hotspot → mapper → phone link
(`main/raceDayOrchestrator.js`). The bridge step adds **no new path**: it runs the existing
session applier (the same code the setup flow/⚙ uses) and mirrors the outcome. W2
auto-enables only when **all** hold: persisted `fpvMode = 'iphone-hud'`, AND
`racePrep.autoBridge` is on (**default ON**, `shared/racePrep.mjs`), AND persisted settings
resolve to an enabled bridge (user-confirmed address; a set `W17_IPHONE_BRIDGE` env always
wins). Honest skips/failures (`shared/raceDayView.mjs`): desktop session → "the phone is
not used"; toggled off → "switched off in ⚙"; no saved address → "run setup once with the
phone connected"; env-forced-off → honest failure. Race-day STOP does **not** touch the
phone link (it follows persisted settings; STOP winds down only the managed mapper).

iPhone-side consequence once merged: after one button press, telemetry may begin arriving
on 5601 at the last confirmed address with nobody touching a bridge toggle. Packet shape,
port, cadence semantics: unchanged.

## 2. What did NOT change

- **The bridge contract itself.** Schemas, ports (W2 5601 send-only, W3 5602 receive-only),
  direction, packet shapes, freshness rules — all stable. The GS implementation copy still
  mirrors canonical rev `84532ed` (2026-07-14); no re-sync is owed by content, only the
  ask-1 confirmation below.
- **W3 stays LOG-ONLY.** The 5602 receiver validates and logs; `test/noControlPath.test.js`
  still pins the structural dead end (the only sanctioned seam remains the sender-IP-string
  address hint). Nothing reaches CRSF, servos, or the gimbal.
- **Head tracking stays gated.** FIRST_ACTIVE remains NO-GO/BLOCKED (R1–R16 + bench
  evidence). The 2026-08-16 owner amendment permits a **branch-only** U4 arbiter in
  `w17-mapper` (both flags default-off, never merged/pushed before R1–R16 pass) — a process
  amendment, not an activation; W3 semantics are untouched by it.
- **R10 iPhone-side residuals are still owed** (`CURRENT_STATUS.md`, 2026-07-15 entry):
  R10 = PASS (automated only) — the 250 ms send-time gate verified read-only in `iPhone_rc`
  (249/250 eligible, 251 stale; cached-active cannot bypass) — but **real-device
  lifecycle/axes/mount validation, the canonical commit, and the mirror remain pending.**

## 3. Asks to Codex

1. **Confirm the mDNS TXT contract canonical-side.** Windows now enforces the acceptance
   policy in 1a — notably "`v` is the only required TXT key" and "`tport` mismatch ⇒
   declined". If the canonical Discovery section already reads exactly this way, a
   confirmation (with the canonical commit hash) is enough; if any nuance differs, rev the
   canonical doc first per its own versioning rule and reply with the hash so the GS mirror
   can record it.
2. **Consider HUD low-battery parity.** Same two levels, same defaults (7.0 / 6.6 V pack,
   configurable), same wording family as 1b, computed from the `battery_v` you already
   receive. If adopted, carry the hysteresis (0.15 V, one-level-at-a-time exit) so the
   banner never flaps. Client-side only; not a contract change.
3. **Be aware of the queued owner decision on the iPhone helmet view** (orchestration
   packet, owner queue item 6): helmet view **in the glovebox booklet vs kept as the
   in-person reveal**. The booklet draft deliberately omits it pending the call. The answer
   lands on `iPhone_rc` docs — in-booklet means giftee-grade helmet-view text sourced from
   your repo; reveal means your docs stay hobbyist-facing. No action until the owner
   decides; flagging so it doesn't surprise you.

---

Non-canonical, dated, disposable after use (`_handoff/README.md`). The contract and its
schemas/examples remain `iPhone_rc`-owned; the Windows implementation and everything in
section 1 remain `w17-ground-station`-owned; vision and status live in
`W17_PRODUCT_VISION.md` / `CURRENT_STATUS.md`.
