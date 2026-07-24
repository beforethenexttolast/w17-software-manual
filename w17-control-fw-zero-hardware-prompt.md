# Session prompt — 4. Control-firmware zero-hardware batch (simulation only, NO POWER)

Paste into a Claude Code session started at `~/Documents/projects/w17-control-fw`.

---

Four items that need **no physical hardware**. Read `CLAUDE.md` (this repo) and
`../CURRENT_STATUS.md` first. **No flashing, no battery, no bench PSU, no powered board** — A2 stays
NOT-EXECUTED and Phase B stays BLOCKED for the whole session. HEAD should be `1834852`.

Start by confirming the baseline: `pio test -e native` (**expect 224/224**) and that `esp32dev`,
`esp32dev_tuning`, `esp32dev_sim` all build.

### 1. Wokwi watchdog observation — the "PENDING" item that isn't actually hardware-gated

`CURRENT_STATUS.md` lists "Live Wokwi stall → watchdog panic → reboot observation: PENDING" and
`open_questions.md` notes the `SIMULATION.md` checklist boxes are all unchecked (→ R16). `wokwi.toml` and
`diagram.json` both exist in this repo. This is a **virtual** ESP32 — it needs no gate.

- Get the sim running (`esp32dev_sim`) and tell me honestly whether it reaches a live link
  (`failsafe=0`) or only builds — that question has never been answered.
- Then exercise the R5-b path: force a stall inside the 50 Hz control tick, observe the 2-second Task
  Watchdog fire, and capture the panic → reboot → reset-reason output. Record what the RTC-retained
  diagnostics report (we have only ever seen `POWER_ON` / `retained=no` on real boards, 2026-07-22).
- Be explicit about what the sim **cannot** settle: real reboot-to-safe-output timing, GPIO13/GPIO14
  logic level during the reset→`ledcAttachPin` window, and real ESC signal-loss behaviour all stay
  Phase-B evidence. Do not upgrade any of those to PASS.
- Fill in the `SIMULATION.md` checklist with what actually passed, and record the result.

### 2. CB3 — firmware comment hygiene

The VR-FPV batch table lists CB3 as `NOT_STARTED`, "tiny; `ChannelDecoder.hpp:57-58`". Verify the anchor,
fix the comment, done. While you're there, `open_questions.md` flags a related overstatement pattern (the
`crsf.js` "firmware golden vectors are reused" claim was already found false) — if you spot an equivalent
overstatement in this repo's comments, list it but don't fix beyond the CB3 scope without asking.

### 3. link2 drift guard — design it, then ask before building

`open_questions.md` R06: the link2 constants exist in **three** places — this repo (protocol owner,
`docs/link2_protocol.md`), `w17-soundlight-fw`'s copy of `lib/link2`, and `w17-ground-station`'s
`shared/feelConstants.js`. There is **no** CI check for drift today. This repo owns the protocol, so the
guard belongs here. Propose the mechanism (checked-in canonical descriptor + a native test, in the style of
the ground station's `test/protoDrift.test.js`, vs. a submodule) with the trade-offs, and **wait for my
decision** — a cross-repo guard touches sibling repos and this session is scoped to this one.

### 4. Ask me the four owner decisions that need no hardware

`project-review/open_questions.md` §"Owner decisions (no hardware needed — you choose)". Put each to me
with the concrete consequence of each answer, then record my answers and identify the small code/doc fix
each one unblocks (don't implement them this session unless one is genuinely a one-liner and I say go):

1. Should the HUD's `armed` / `failsafe` indicators be driven from something real, or is it acceptable that
   a real link loss silently reverts the HUD to simulated values? (→ R01)
2. Which gear count is authoritative — gearbox **4**, link2 doc **6**, or HUD **8**? (→ R05) This sets the
   FLIGHTMODE `G%u` string, the protocol doc, and the HUD dial.
3. Which drive-mode labels ship — "Gearbox / Gearbox+ERS" (firmware/doc) or "RACE / ERS" (HUD)? (→ R19)
4. Is the `lib/link2` copy in soundlight-fw permanent (two evolving copies) or a bootstrap toward a shared
   submodule? (→ R06) This decides item 3's answer.

Edit this repo only. Show diffs before committing; keep commits focused; re-run `pio test -e native` before
anything ships.
