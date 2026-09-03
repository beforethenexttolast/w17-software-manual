# 15 — The Mapper: DualShock → CRSF → ELRS, and the Log-Only Head-Intent Pipeline

The fourth software repo. Chapters 01–13 told a three-repo story — two firmwares and a
viewer app — and treated the thing that turns the DualShock into radio frames as "an
external tool" (chapter 01 §2). That stopped being true on 2026-07-15: the project now
**owns** that tool as a fork called **`w17-mapper`**, it carries W17-specific safety
fixes, and it is also the production owner of the iPhone head-tracking *intent* receiver
— the most safety-sensitive log-only code in the workspace. This chapter teaches both
halves: the driving chain (gamepad → mapper → CRSF → ELRS → car) and the head-intent
chain (iPhone → UDP 5602 → diagnostics display, **and deliberately nothing further**).

**Prerequisites:** chapter 06 (control firmware architecture — failsafe, arm gate,
channel decode), chapter 09 (CRSF byte format). Chapter 08 helps for the ground-station
end. New here: a first look at **Go** — the mapper is the workspace's only Go program,
and Go concepts are explained as they appear, same as C++ was in chapter 04.

**Branch-state warning (updated 2026-09-03), read before citing this chapter:** the
mapper's current line is branch `w17-headtrack`, now well past the 2026-08-17
`432a809` snapshot — that is what "the mapper" means below unless a section says
otherwise. **Update:** what this chapter called `w17-audit-wave1` (the W17 profile
`configs/w17-ds4.json`, the four confirmed-audit-defect fixes, and the R1–R16 wording
correction) is **no longer a separate unmerged branch** — the owner committed it
directly onto `w17-headtrack` (`c383972` and later commits, author
`beforethenexttolast`; no `w17-audit-wave1` ref remains). It is trunk fact now, not a
pending review. One other branch still exists and is genuinely **not merged**:
`u4-arbiter` (gated head-tracking arbitration work that **never merges before the
R1–R16 safety review passes**; see §9) — that gate is unchanged. Sections below that
still say "unmerged wave-1" are dated and superseded by this note; §6/§9/§11 have been
corrected. **[C]** `git branch`/`git log --oneline w17-headtrack` in `w17-mapper`;
`../2026-08-16_orchestration_review_packet.md` §2, §5, §7½ (superseded on the
wave-1 point by this update).

---

## 1. The driving chain, end to end

When you drive the W17, this is the full path a stick motion takes:

```
DualShock 4 ──USB/Bluetooth──▶ PC (Windows on race day)
                                 │  SDL joystick API reads axes/buttons
                                 ▼
                      w17-mapper (Go program)
                        node-graph evaluation, ~every 25 ms
                        16 channel slots, 11-bit values
                                 │  crossfire.PackChannels → CRSF bytes
                                 ▼
                      ELRS TX module (ES24TX Pro) ── serial, 921600 baud
                                 │
                                 ▼ 2.4 GHz ExpressLRS radio
                      RadioMaster RP1 receiver (on the car)
                                 │  CRSF UART, 420000 baud, 8N1
                                 ▼
                      w17-control-fw (ESP32 #1) — chapter 06 takes it from here
```

- **[C]** SDL read: `w17-mapper/pkg/devices/util.go` `EnumerateDevices()` calls
  `sdl.JoystickOpen(i)` (line 27) — the mapper reads *joysticks*, not a
  DualShock-specific driver, which is why a sim wheel should enumerate the same way
  (`../W17_PRODUCT_VISION.md` reality check on decision 10).
- **[C]** Serial default: `w17-mapper/cmd/elrs-joystick-control/main.go` flag
  `--tx-serial-port-baud-rate` defaults to `921600` (PC→TX module link).
- **[C]** Radio hardware: ES24TX Pro ELRS TX module and RadioMaster RP1 receiver,
  `../HARDWARE_INVENTORY.md` §2.
- **[C]** Car-side UART: `crsf::kCrsfBaud = 420000`,
  `w17-control-fw/lib/crsf/include/crsf/CrsfFrame.hpp:89`.

Two things this chain is **not**:

1. **Not a handset.** There is no physical RC transmitter in the main path — the PC
   *is* the transmitter, with the ELRS TX module as its radio. A plain ELRS handset
   bound to the RP1 is planned as a **backup** (vision decision 12), not the main path.
2. **Not the video path.** Video is a separate chain (camera → mediamtx → WHEP,
   chapter 08); the two never touch. Losing one does not lose the other — which is why
   the booklet can honestly say "watch the screen to know when she can hear you again."

## 2. What the mapper is — an owned GPL fork

The mapper began life as **ELRS Joystick Control** by kaack
(`github.com/kaack/elrs-joystick-control`): an open-source program that reads game
controllers through SDL and streams CRSF channel frames to an ELRS TX module over
serial. The 2026-07-14 CB0 investigation (read-only, upstream pinned at `2b8031a`)
found it was *almost* exactly what the project needed — a node-graph mixer with a gRPC
API (port 10000) and a web UI (port 3000) — but with **no UDP ingest of any kind**, so
the head-intent receiver could not be added from outside. Hence owner decision #1
(2026-07-15): fork it, own the fork. **[C]** `../CURRENT_STATUS.md` (CB0 entry);
`w17-mapper/FORK-NOTICE.md` (Provenance).

The legal shape matters and is worth learning as a pattern:

- Upstream is **dual-licensed**: GPL-3.0-or-later *or* Fair Source 0.9, recipient's
  choice. The fork **elected the GPL** (the Fair Source option carries a 1-user limit).
  **[C]** `w17-mapper/FORK-NOTICE.md` "Licence election".
- The GPL requires modified copies to carry **prominent notices of modification**
  (GPL §5(a)). The fork satisfies this with a dated modification table in
  `FORK-NOTICE.md` — every W17 change is a row with its commit hash. When you wonder
  "what did W17 change vs upstream?", that table is the index. **[C]** ibid.
- Because the GPL also forces source availability, the fork is **public**:
  `github.com/beforethenexttolast/w17-mapper`, since 2026-07-25 — the only W17 repo
  that is public before the gifting (vision decision 18). Publicness is why the
  pre-push hook exists (§9). **[C]** `../WORKSPACE_MAP.md` mapper row.
- A **read-only reference copy** of upstream lives at `_vendor/elrs-joystick-control`
  and is never edited — so "what does upstream do here?" is always answerable by
  diffing, not by memory. **[C]** ibid.

In-code, W17 additions are marked: look for `W17 fork addition` comments (e.g.
`pkg/config/input_channel.go:22`) and `SPDX-FileCopyrightText: © 2026 W17 project`
headers on wholly new files (e.g. `pkg/headintent/doc.go`).

## 3. Go anatomy in one box

Go, coming from the C++ you learned in chapter 04:

| Go thing | What it is | C++ analogue |
|---|---|---|
| `go.mod` | declares the module name + dependency pins | roughly `platformio.ini`'s `lib_deps`, but language-native |
| `cmd/elrs-joystick-control/main.go` | the executable's entry point; `func main()` | `src/main.cpp` |
| `pkg/<name>/` | a **package** — Go's unit of visibility and import | a library under `lib/`, but with enforced import direction |
| `Capitalized` names | exported (public) — visibility is spelling, not keywords | `public:` |
| `lowercase` names | unexported (package-private) | `private:` |
| `go test ./...` | runs `_test.go` files in every package | `pio test -e native` |
| goroutine + channel | lightweight thread + typed queue between goroutines | FreeRTOS task + queue, minus the manual sizing |
| `nil` | zero value for pointers/interfaces/maps/slices | `nullptr`, but more pervasive |

The one Go idea this chapter leans on repeatedly: **multiple return values with an
error/validity flag**. Where C++ code returns a value *or* sets a flag by reference,
Go returns both: the mapper's node evaluation returns
`(src IOType, out util.RawValue, ch util.ChannelNumber, nan bool)` — the `nan bool` is
the "this number is not usable" signal that the whole failsafe story (§5) rides on.
**[C]** signature throughout `pkg/config/input_*.go`.

Useful flags of the binary (all in `cmd/elrs-joystick-control/main.go`): `--grpc-port`
(default 10000), `--webapp-port` (3000), `--tx-serial-port-name`,
`--tx-serial-port-baud-rate` (921600), `--config-file-path` (load a profile headless —
the race-day path, so the giftee never sees the editor UI), `--disable-web-ui`, and the
environment variable `W17_HEADTRACK_INGEST` (the log-only receiver's default-off
switch; W17 addition). **[C]** that file, flag block.

## 4. The node-graph concept

The mapper's configuration is a JSON document describing a **tree of typed nodes**.
Each CRSF channel owns a subtree; evaluating the tree bottom-up yields one number per
channel. That's the entire mental model:

```
"channel" node (ch5, crsf_min/max, failsafe)        ← produces the CRSF value
    └── "and" node (rails: output_true/false)       ← logic
         ├── "seq" node (toggle on press+release)   ← stateful logic
         │     └── "button" node (TRIANGLE)         ← reads hardware
         │           └── "gamepad" node (DS4 id)    ← names the device
         └── "linear" node (constant 1 / nan probe)
               └── "axis" node (LX)
                     └── "gamepad" node
```

- **Leaf nodes** name hardware: `gamepad` (a device id), `axis`, `button`, `hat`.
  Values arrive in SDL's signed 16-bit range: **−32768…+32767** (`util.MinRaw`/
  `util.MaxRaw`, `pkg/util/util.go:32-33`).
- **Transform nodes** reshape numbers: `linear` (rescale), `invert`, `trim`, `map`,
  `add`/`subtract`/`min`/`max`, comparison nodes (`gt`, `lt`, `eq`…), logic nodes
  (`and`, `or`, `if`, `case`, `switch`), and the stateful `seq` (a toggle that advances
  through `output_values` on a timed press+release). One file per node type:
  `pkg/config/input_<type>.go` — 27 node types in all. **[C]** directory listing;
  FORK-NOTICE `e452d55` row (the "27 node types" count).
- **The `channel` node** is the root of each subtree. It linearly maps the subtree's
  raw result from `raw_min…raw_max` into `crsf_min…crsf_max`
  (`util.MapRange`, called at `pkg/config/input_channel.go:164`) and carries the
  channel's **`failsafe`** value (§5).
- The web UI on port 3000 is a visual editor for exactly this JSON. Per the operator
  model it is a **build-time tool**: the giftee never opens it; race day loads a saved
  profile via `--config-file-path`. **[C]** `../W17_PRODUCT_VISION.md` operator model.

An **evaluation loop** re-evaluates the whole graph on a ~25 ms tick
(`pkg/config/eval.go` `EvalLoop`), and a **send loop** (`pkg/link/send.go` `SendLoop`)
packs the 16 evaluated channel values into CRSF `RC_CHANNELS_PACKED` frames —
`crossfire.PackChannels` (`pkg/crossfire/util.go:119`) is the exact mirror of the
firmware's `decodeRcChannels` from chapter 09 — and writes them to the TX module's
serial port. *(History: the 25 ms tickers used to live inside streaming gRPC handlers,
so with zero subscribers the eval loop could stop ticking — confirmed audit defect 2.
**Fixed, now on trunk**: `pkg/config/eval.go` runs a subscriber-independent heartbeat
ticker (`evalHeartbeatInterval`) that re-evaluates every synthetic per-port
transmitter regardless of subscriber count — the fix landed on `w17-headtrack` itself,
not a separate branch. **[C]** `pkg/config/eval.go:118-153`;
`../2026-08-16_vision_audit_report.md` §3 defect 2.)*

## 5. Failsafe values and `nan` — the W17 fork's main safety work

Upstream had a hole the W17 fork spent four commits closing (FORK-NOTICE rows
`2dc7c5a`, `630ea96`, `e452d55`, `c60843e`): **what number does a channel transmit when
its input subtree cannot produce one?** — because the gamepad unplugged, a node was
misconfigured, or a wrapper node swallowed the result. Upstream's answer was variously
"hold the last value" (dangerous: a dead pad keeps transmitting its final stick
positions) or "send an all-zeros frame" (worse — see §7). The fork's answer:

1. Every `channel` node carries a **`failsafe`** CRSF value. When JSON omits it, the
   default is **center (992)** — never 0. **[C]** `pkg/config/input_channel.go:117-121`
   (`UnmarshalJSON`), `:131-136` (`FailsafeValue()`).
2. `nan` propagation: a detached gamepad stops resolving
   (`devices.InputGamepad.Attached()`), so its axis/button nodes evaluate with
   `nan = true`, and that unusability flows up the tree. **[C]** FORK-NOTICE `2dc7c5a`.
3. The transmitter drives every channel whose subtree did not resolve **this pass** to
   that channel's own failsafe — resolved per *owning* `channel` node, not per
   top-level holder, via an arming walk (`channelOwners`) plus a per-pass tri-state on
   each channel (`channelEvalState`: not-evaluated / resolved / failed —
   `pkg/config/input_channel.go:42-51`). And if the ownership walk itself truncates,
   the port's frames are **suppressed entirely** (`OutputTransmitter.Unresolved`), so
   the receiver's own link-loss failsafe fires rather than trusting unknown channels.
   **[C]** FORK-NOTICE `e452d55`, `c60843e` rows.
4. A config **swap** suppresses frames for a bounded window, so channels the new
   config no longer maps fail over to the receiver's link-loss failsafe instead of
   riding a stale center. **[C]** FORK-NOTICE `e452d55` row;
   `pkg/link/send_configswap_test.go`.

Hold this thought: **the mapper's failsafe layer and the firmware's failsafe layer are
different layers.** Pad dies but radio link alive → the *mapper* substitutes per-channel
failsafe values (this section). Radio link dies → the *firmware's* failsafe state
machine acts (chapter 06/10), regardless of anything the mapper wanted. Defense in
depth, and neither layer trusts the other.

## 6. The W17 profile — `configs/w17-ds4.json`

**Lives on trunk `w17-headtrack`** (`configs/w17-ds4.json`) — no longer a separate
branch awaiting review (see the branch-state warning above); the owner committed it
directly. Two placeholders still must be filled at the Windows bench: the DS4's
device id and the ELRS TX COM port (`REPLACE-WITH-DS4-ID`, `REPLACE-WITH-COM-PORT`).
**[C]** that file; packet §4 item 7.

Button numbering note (2026-09-03 correction): the profile's original commit mixed
SDL HIDAPI axis numbering with raw-HID button numbering — "a pairing no Windows
driver produces" (`FORK-NOTICE.md` row `4e27b0e`, review blocker F1). The numbers
below are the corrected HIDAPI GameController order, test-pinned for the bound set
`{2,3,9,10}`:

| CRSF ch | Control | DS4 input (SDL HIDAPI id) | Graph shape | `failsafe` |
|---|---|---|---|---|
| 1 | steering | left stick X (axis 0, deadzone 2000) | `axis` | 992 (center) |
| 3 | throttle | R2 fwd / L2 brake (axes 5, 4) | each `linear`-rescaled 0…32767, then `subtract` | 992 (neutral) |
| 5 | **arm** | TRIANGLE (button 3) | `and(seq toggle, liveness probe)` — see below | **172 (OFF)** |
| 6 | DRS | SQUARE (button 2), hold | `button` | **172 (OFF)** |
| 7 | gear up | R1 (button 10), momentary | `button` (firmware edge-detects, ch06) | **172 (OFF)** |
| 8 | gear down | L1 (button 9), momentary | `button` | **172 (OFF)** |
| 9 | gimbal pan | right stick X (axis 2) | `axis` — stick-driven only, **not** head tracking | 992 |
| 10 | gimbal tilt | right stick Y (axis 3) | `axis` — same | 992 |
| 11 | ERS boost | — pinned OFF | `number` rail −32768 | **172** |
| 12 | ERS overtake | — pinned OFF | `number` rail −32768 | **172** |
| 13 | drive mode | — pinned LOW = TRAINING | `number` rail −32768 | **172** |

SHARE (button 4), OPTIONS (button 6), and the D-pad are **deliberately unbound** —
reserved as future head-tracking affordances ("Alternative C"), and the profile's own
`tx` label says so; a mapper test asserts no button node may reference either
(`pkg/config/w17_profile_test.go`). Every channel carries `crsf_min: 172, crsf_max:
1811` — that is §7's story. **[C]** all rows from the JSON itself;
`configs/README.md`.

**The arm channel is the profile's one clever graph, and it exists because of a trap.**
A `seq` node is a *stateful toggle*: TRIANGLE press+release (50–1000 ms) advances it
between 0 and 32767. But when every condition of a `seq` evaluates `nan` (pad
detached), the seq **returns its current output value as a perfectly valid number** —
`pkg/config/input_seq.go` `_Eval`: "if all conditions are not numbers, result is the
current output value". So a naked seq stays "armed" straight through a dropout, the
channel keeps resolving, and the 172 failsafe never fires. **[C]** that file.

The fix is an `and` node whose **right side is exactly one operand**: a `linear` probe
over left-stick-X that outputs constant 1 while the pad resolves and `nan` once it
detaches. The `and`'s right-operand loop skips nan operands, *but if all of them are
nan the whole `and` returns nan* (`pkg/config/input_and.go:58-81`). One probe, so "one
nan" = "all nan" = channel unresolved = failsafe 172 = the firmware's `decodeSwitch`
reads OFF = **disarm**.

**2026-09-03 update — a second layer on top of the probe:** the `seq` node itself now
sets `reset_on_nan: true` (`FORK-NOTICE.md` row `4e27b0e`, "arm toggle resets on
dropout"). Without it, the AND-probe defense above stops the *channel* from
transmitting armed, but the `seq`'s own internal toggle state is untouched by a
dropout — so if the pad reconnected mid-phase, the toggle could still be internally
"on" and the channel would go straight back to armed the instant the liveness probe
resolved again, with no fresh press. `reset_on_nan` closes that: any tick where every
condition is `nan` also resets the toggle's stored value to `0` (DISARMED), so a
reconnect always starts from disarmed and **always** needs one deliberate fresh
TRIANGLE press — not "may be out of phase," but guaranteed. **[C]**
`pkg/config/input_seq.go` (`reset_on_nan` handling); the channel's own JSON label
("reset_on_nan returns it to DISARMED on any pad dropout, so an auto-reconnect can
never silently re-arm"). *(Why not probe with the TRIANGLE button itself? A button
also reads as valid 0 when idle — the probe must be a node that is truthy while alive
and `nan` when dead, which the constant-output `linear` over an axis is.)* **[I]**
design reading of the same files.

## 7. Why a *default* config could not arm — the plausibility band

Here is confirmed audit defect 3, and it is the best protocol-safety lesson in the
project. Upstream's channel defaults are `CRSFMinValue = 0`, `CRSFMaxValue = 1984`
(`pkg/util/util.go:39-40`) — full 11-bit-ish endpoints. The nominal CRSF range,
which the firmware and chapter 09 use, is **172 = −100%, 992 = 0%, 1811 = +100%**
(`w17-control-fw/lib/crsf/include/crsf/CrsfFrame.hpp:66-68`).

The firmware does not merely prefer the nominal range — it enforces a **plausibility
band** around it: `kChannelRawPlausibleMin = 100`, `kChannelRawPlausibleMax = 1900`
(`CrsfFrame.hpp:85-86`; the values are marked PROVISIONAL pending Phase-B bench
calibration). Any raw channel value outside 100–1900 is treated as **ABSENT** — analog
reads as 0, a switch reads as OFF — via `rawPlausible()` in
`w17-control-fw/lib/channels/src/ChannelDecoder.cpp:11-13`, applied at `:49-51`
(analog) and `:62-68` (switch, forced OFF *without* touching the hysteresis latch).

Why so strict? Because a value like 0 or 2047 is not "a TX with generous endpoints" —
it is *someone not speaking the protocol*: a corrupt frame that squeaked past CRC8, or
an all-zeros sentinel payload. Normalizing garbage to full deflection would be the
least safe possible reading; treating it as "control absent" is the safest. Values
*slightly* outside nominal (say 150, from a TX with expanded endpoints) still clamp to
the endpoint. **[C]** the constant's comment block, `CrsfFrame.hpp:70-84`.

Now put the two together. A default-endpoint mapper channel at full deflection
transmits ~0 or ~1984. Both sit **outside** 100–1900. So the arm switch at "ON"
arrived as *implausible* → decoded as OFF → **a car driven by a default config can
never arm**. Not a crash — a silent, total refusal. The W17 profile's fix is simply
`crsf_min: 172, crsf_max: 1811` on every channel, plus (now on trunk `w17-headtrack`,
same commit set) a load-time lint that warns when a profile's endpoints leave the
firmware's band.
**[C]** `../2026-08-16_vision_audit_report.md` §3 defect 3; the profile JSON.

The teaching point: **two correct programs disagreed about a contract neither had
written down.** Upstream chose generic endpoints; the firmware chose strict
plausibility; both defensible, and their composition was "cannot arm." The profile is
where the contract now lives explicitly.

## 8. Why switch failsafes are 172, not center

Confirmed audit defect 1, and the reason six rows of §6's table say **172**.

Chapter 06 taught `decodeSwitch`: the firmware normalizes a channel to −1000…+1000
(exact at the anchors 172/992/1811) and applies **hysteresis** — ON above +250, OFF
below −250, and **in between it holds the previous state**
(`w17-control-fw/lib/channels/include/channels/ChannelDecoder.hpp:38-39`,
`.../src/ChannelDecoder.cpp:78-84`). Hysteresis is the right tool against a noisy
analog source flickering a switch. But it has a corollary: **center is inside the hold
band.** A switch channel sitting at 992 does not mean OFF — it means *keep whatever you
last decided*.

So imagine the pad dies mid-drive with the fork's *default* failsafe (992, §5) on the
arm channel: the mapper dutifully drives ch5 to center… and the firmware **holds
armed**. Reconnect the pad and it resumes armed. Same latch for DRS and both gear
channels. That is defect 1 verbatim. The W17 profile therefore pins every switch-like
channel's `failsafe` to **172 — the OFF rail, an unambiguous below-−250 reading** —
which forces `decodeSwitch` to a definite OFF: disarm, DRS closed, no phantom gear
edges. The proportional channels keep 992 because *their* semantics make center the
safe value: steering straight, throttle neutral (the ESC runs forward/brake — chapter
09's link2 notes), gimbal centered. **[C]** audit §3 defect 1;
`pkg/config/input_channel.go:22-29` (the fork documents exactly this trade in the
`Failsafe` field comment); profile JSON labels.

Note the symmetry with §7: both defects are *composition* bugs between a sane mapper
and a sane firmware. This is why the manual keeps hammering "the contract is the
artifact" — and why trunk now carries a profile lint asserting `failsafe: 172` on
decodeSwitch channels rather than trusting future profile edits to remember.

## 9. The head-intent pipeline — log-only, by construction

The other half of the mapper is `pkg/headintent`: the production receiver for the
iPhone's head-tracking **intent** packets. The word *intent* is load-bearing — the
iPhone expresses "the wearer's head points here"; nothing on the PC or the car is
allowed to *act* on it yet. Safety boundaries 1–5 (`../CLAUDE.md`) forbid any
iPhone→control path until the separately-reviewed FIRST_ACTIVE milestone passes, and
it has **not** (NO-GO, hardware-evidence blockers). What exists today, live-validated
end to end, is a diagnostics chain:

```
iPhone (Codex iPhone_rc app)
  │ JSON datagrams, UDP port 5602 (windows_bridge_contract.md §3)
  ▼
w17-mapper  pkg/headintent          ← LOG-ONLY receiver (default OFF;
  │   receiver.go  (socket, 5602)      env W17_HEADTRACK_INGEST enables)
  │   packet.go    (validation; staleness authority = LOCAL monotonic
  │                 receive time, 300 ms — 299/300 fresh, 301 stale)
  │   monitor.go   (state machine + counters)
  ▼
read-only gRPC stream  WatchHeadIntentDiagnostics
  │   pkg/server/headintent_stream.go; enum in pkg/proto/server.proto
  ▼
w17-ground-station (viewer)
      main/HeadIntentDiagnosticsClient.js + main/headIntentGrpcConnect.js
      shared/headIntentView.mjs → renderer/hud.js   ← pixels, nothing else
```

**[C]** all paths: the files themselves; port/staleness constants
`pkg/headintent/receiver.go:20` (`DefaultPort = 5602`) and
`pkg/headintent/packet.go:16-19` (`DefaultStaleMs = 300`). The 300 ms boundary and the
"receive time, never the packet's own timestamp" rule are ported 1:1 from the reviewed
Windows reference implementation `w17-ground-station/shared/headTracking.js`
(`pkg/headintent/doc.go`), and 300 ms is the workspace-ratified stale canon
(`../CURRENT_STATUS.md`). The GS reference receiver still exists in that repo, but the
**mapper is the production owner of 5602 ingest** (owner decision #1, topology (a),
2026-07-15 — `../WORKSPACE_MAP.md` mapper row), and since a UDP port is an **exclusive
bind** — one socket per port per host — only one of the two receivers can listen on a
given machine anyway. **[C]** `../CURRENT_STATUS.md` ("UDP 5602 remains an exclusive
bind").

The state machine's proto enum is worth reading in full, because its *last member* is
a safety statement (`pkg/proto/server.proto:519-528`):

| Value | State | Meaning |
|---|---|---|
| 0 | `UNSPECIFIED` | never sent; guards against a defaulted field |
| 1 | `DISABLED` | receiver not running (the default) |
| 2 | `FAULT` | socket/config error |
| 3 | `IDLE` | running, no valid packet yet |
| 4 | `INVALID` | only invalid packets seen |
| 5 | `STALE` | had valid, silent > 300 ms |
| 6 | `INACTIVE` | fresh valid, tracking disabled |
| 7 | `NOT_CENTERED` | fresh valid, enabled, not centered |
| 8 | `ACTIVE_LOG_ONLY` | fresh, valid, enabled, centered — **and still no output** |

**The enum stops at 8.** There is deliberately no state 9, no `ACTIVE`. The best
possible head-tracking condition the system can express is "everything is perfect,
and we are still only logging it." The package doc
(`pkg/headintent/doc.go`) states the boundary as an import contract: `headintent`
never imports `pkg/config`, `pkg/link`, `pkg/crossfire`, or `pkg/serial` — verified
mechanically with `go list -deps ./pkg/headintent/` (FORK-NOTICE push checklist), and
behaviorally by a **byte-identity proof**: `crsf.PackChannels` output is bit-for-bit
identical with ingest off vs on, across valid/stale/invalid traffic
(`pkg/headintent/pack_deadend_test.go`; 12 frames / 312 bytes, one SHA-256). A dead
end, proven dead. **[C]** all cited files.

**What about actually *using* head intent some day?** The shaping/arbitration layer
("U4 arbiter") exists **only on the never-merged `u4-arbiter` branch**, written under
an explicit 2026-08-16 owner amendment that allows branch-only implementation with
every activation flag default-off — and it **cannot merge or push before the R1–R16
review plus bench evidence** (`w17-control-fw/project-review/head_tracking_unlock_plan.md`;
packet §5). If you are reading this chapter to learn the system as it runs: **there is
no arbiter in any built or running mapper.** Do not plan against it. **[C]** packet §5;
vision doc reality check on decision 9.

## 10. The guards that keep "log-only" true

Because the fork is public, "we just won't push gated code" needed teeth. Three layers,
weakest to strongest:

1. **The pre-push hook** — `w17-mapper/.githooks/pre-push` (tracked in the repo;
   enabled per clone with `git config core.hooksPath .githooks`, because git never
   auto-enables repo-supplied hooks — a security property of git itself worth
   knowing). Four greps over the pushed tip: the `w17_first_active` build tag in
   code/build files; a `FIRST_ACTIVE` identifier in Go/proto; any proto
   `HEAD_INTENT_STATE_ACTIVE` not suffixed `_LOG_ONLY` (the enum must still end at 8);
   and any case-insensitive `first_?active` identifier. Its own header documents its
   verification matrix (injections I1–I4 refused, I5 — a differently-named const —
   deliberately documented as *not catchable*) and its honest limits: it matches
   **names, not semantics**, `git push --no-verify` bypasses it, and it does nothing
   in a clone that never set `hooksPath`. In the file's own words, it is "a speed bump
   against accident, NOT a control against intent." **[C]** the hook file.
2. **The push-review rule** — `FORK-NOTICE.md` "Safety boundary": no push may add
   shaping/arbitration/output paths before the FIRST_ACTIVE checklist passes, plus a
   four-point pre-push confirmation list (enum ends at 8; no gated identifiers;
   `go test ./pkg/headintent/` green including the byte-identity proof; `go list
   -deps` shows no control-package edge). *(History: `FORK-NOTICE.md` used to say
   "R1–R14" in two places against an actual R1–R16 checklist — confirmed audit low
   finding 12. Fixed, now on trunk: `git grep 'R1–R16' FORK-NOTICE.md` at current
   `w17-headtrack` HEAD returns three hits, zero "R1–R14" remain.)* **[C]**
   FORK-NOTICE.md:68,73,125; audit §3.
3. **The actual gate** — the FIRST_ACTIVE review itself (R1–R16 + bench evidence +
   owner approval), which is a process, not a grep. The hook and the notice exist so
   that *accidents* cannot outrun the process.

The lesson to generalize: when a safety property depends on something *not* existing
(no active state, no import edge, no push), make its absence **checkable** — an enum
that must end at a known value, a dependency query, a byte-identity test — and then
automate the check at the moment of risk (push time). Absences that are merely
remembered eventually stop being true.

## 11. Current reality — the ledger for this chapter (updated 2026-09-03)

| Thing | Where it lives | Status |
|---|---|---|
| Mapper current line | `w17-headtrack` (moves; `git rev-parse w17-headtrack` for the live tip) | everything in §1–§10 |
| W17 profile + lint, 4 defect fixes, R1–R16 wording | **merged onto `w17-headtrack` directly** (no `w17-audit-wave1` ref remains; owner-authored) | trunk fact, not pending review |
| Defects 2 & 4 (eval heartbeat; `InputRead` recursion crash) | fixed on `w17-headtrack` | verified at HEAD: `pkg/config/eval.go`'s heartbeat ticker and the `InputRead` re-entrancy guard (`read_cycles.go`) both exist on trunk (audit §3.4 closed) |
| U4 arbiter (+51 tests at last check, flags off) | `u4-arbiter` branch — **actively moving during this 2026-09-02 readiness pass** (a separate builder session is landing steps there right now; do not cite a commit hash here, it will be stale within the hour) | branch-only by owner amendment; **never merges/pushes before R1–R16 + bench**; not in any running build |
| Head-intent ingest | `w17-headtrack` (merged, live-validated) | **LOG-ONLY**; enum ends at `ACTIVE_LOG_ONLY = 8`; FIRST_ACTIVE = NO-GO |
| Pad device id + COM port in the profile | placeholders | Windows-bench items (packet §4.7) |

If you read this chapter long after 2026-08 — reconcile this table against
`../CURRENT_STATUS.md` before trusting it; branch states are the most perishable facts
in this manual.

---

## Questions to check your understanding

1. Trace a TRIANGLE press from plastic to disarm-gate: which mapper node types does it
   pass through, what CRSF value leaves the mapper when the toggle lands "armed", and
   which firmware function turns that value into a boolean?
2. The pad's battery dies mid-drive while the ELRS link stays perfect. Which failsafe
   layer acts, what exact value does CRSF ch5 carry, and why would 992 have been
   dangerous there — but is *correct* on ch1?
3. Why can't a freshly-downloaded upstream `elrs-joystick-control` with a default
   config ever arm this car, even wired and bound correctly? Name the two constants
   (one per side) whose composition causes it.
4. A naked `seq` toggle holds its state through a gamepad dropout. Explain the
   mechanism in `input_seq.go` that makes that true, and the exact property of
   `input_and.go`'s right-operand loop the liveness probe exploits to defeat it.
5. The head-intent enum's best state is `ACTIVE_LOG_ONLY = 8`. List the three
   *mechanical* checks (not policies) that would each independently catch someone
   adding a state 9 that feeds channels 9/10.
6. The pre-push hook's own header says injection I5 (`const enableShaping = false`)
   passes clean, and calls this "not a bug". Why is that honesty load-bearing — what
   would a hook that *claimed* to catch semantics teach its users to do?
7. Two log-only 5602 receivers exist in the workspace (mapper `pkg/headintent`, GS
   `shared/headTracking.js`). Which one is production, per which owner decision, and
   why can they never both run at once on one machine?
