> Rescued 2026-08-17 from the orchestration session scratchpad.
> Consumed by: w17-mapper branch u4-arbiter (implementation in progress). Non-canonical dated snapshot.

# U4 head-intent arbiter — implementation blueprint (branch-only, plan, NO code)

Date: 2026-08-16. Prepared read-only against:

- `w17-control-fw/project-review/head_tracking_unlock_plan.md` (read via the audit
  worktree at `w17-control-fw` main = `3f4f9b7`; the plan doc is 1420 lines, sections
  cited as §) — the design authority for everything below.
- `w17-mapper` @ `w17-headtrack` tip **`432a809`** (read via the detached audit worktree;
  the live tree at `~/Documents/projects/w17-mapper` is on `w17-headtrack` and is treated
  as occupied — nothing here touches it).
- `W17_PRODUCT_VISION.md` — decision 9 reality check + the **2026-08-16 owner amendment**
  ("branch-only implementation approved — the U4 arbiter and its Groups A/B/C test matrix
  may be written on a `w17-mapper` feature branch with both FIRST_ACTIVE flags default-off
  and every shaping constant fail-closed; the branch is never merged or pushed before
  R1–R16 pass"), and decision 11 (driving-time gimbal link-loss vision = decay to center;
  the formal U8 re-review still happens at implementation).

Authorization scope this blueprint implements, nothing more: **code on a branch**. No
merge, no push, no flag flipped in any shared build, no proto change, no hardware, no
constants invented. FIRST_ACTIVE overall remains NO-GO/BLOCKED (§2.3.12.11); this branch
is §3.1 step **M pulled forward as branch-only work** by the amendment — step **L (the
fresh adversarial R1–R16 re-check) still gates merge, push, and any activation**, and
steps G–K still gate the calibration data the code refuses to run without.

---

## 1. Branch plan

**Base:** `w17-headtrack` @ `432a809` (current tip; carries `pkg/headintent`, the failsafe
fixes, and the 4-check pre-push hook).

**Branch name:** `u4-arbiter` (suggested; alternative `w17-u4-arbiter`). The hook scans
tree contents, not ref names, so the name is unconstrained — pick one that does not
pretend to be an approval state (avoid anything containing "active").

**Worktree — outside the workspace, per the CLAUDE.md concurrent-sessions rule.** The
live tree is on `w17-headtrack` and may be owned by another session; the branch must
never be checked out there. The implementing session creates:

```
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper worktree add \
    <that-session's-scratchpad>/u4-wt/w17-mapper -b u4-arbiter 432a809
```

Do not reuse the read-only audit worktree (`.../audit-wt/w17-mapper`, detached HEAD) —
it belongs to the audit flow. Before every commit: `git worktree list` +
`git branch --show-current` in the worktree, and re-check HEAD immediately before
committing (the workspace has been bitten twice by silent tree moves). Commit early and
often — committed work survives worktree/scratchpad cleanup because the branch ref lives
in the main repo's `.git`; uncommitted work does not.

**Rule set the branch operates under:**

1. **Never pushed, never merged before the R1–R16 review passes.** The FORK-NOTICE.md
   push-review rule is the control; `.githooks/pre-push` is the accident backstop. Every
   file this branch adds contains `w17_first_active` or a `first_?active`-style
   identifier, so **any push attempt of the branch tip is refused by hook checks 1/2/4 by
   construction** — that is the backstop working as designed, not an obstacle to route
   around. `git push --no-verify` stays forbidden by the FORK-NOTICE rule.
2. **Never merged into `w17-headtrack` "temporarily" either.** The hook scans only the
   pushed tip tree (its own documented limit), so a merge-then-revert would pass the hook
   while leaking gated code into pushed history. Merge happens once, after R-review, or
   never.
3. Verify the hook is live in the implementing clone before first commit:
   `git config core.hooksPath` must print `.githooks` (worktrees share the repo config,
   so the existing setting covers the new worktree — verify anyway).
4. `go.mod`, `go.sum`, `go.work`, `go.work.sum` byte-untouched (no new dependencies —
   stdlib only). `pkg/proto/**` and `webapp/**` byte-untouched (§4 below).
   `pkg/headintent/**` byte-untouched — `pack_deadend_test.go` must keep passing
   unmodified.
5. Both build modes green at every commit: `go build ./... && go test ./...` (default)
   and the same with `-tags w17_first_active`; `-race` on the touched packages.
6. One repo per session; diffs shown before commit; small focused commits
   (slice boundaries in §7).

---

## 2. Two-part FIRST_ACTIVE flag — exact Go realization

Per §2.3.11.4 the compile-time gate is **a Go build tag and only a build tag** (the const
alternative is deleted), and the tag literal is contractually **lowercase
`w17_first_active` exactly** — that is the string hook check 1 greps.

**Part 1 — compile-time.** Every functional arbiter file carries
`//go:build w17_first_active`. Default builds (`go build ./...` with no `-tags`) compile
**none** of them: no `Arbiter` type, no shaping math, no state machine, no wiring — the
symbols are *absent* from the binary, assertable with `go tool nm` (test A3). The
counterpart files carry `//go:build !w17_first_active` and contain only the passthrough
stub surface (details in §3). Note the negated tag string still contains the literal
`w17_first_active`, so even the stub files trip the hook — intended.

**Part 2 — runtime.** In a `w17_first_active` build only, an explicit runtime enable,
default off, plan working name kept: env **`W17_FIRST_ACTIVE_ARM`** parsed with the
existing `envTruthy` pattern, plus a CLI flag `-first-active-arm` registered from an
`init()` in the tag-gated `cmd` wiring file (registering from `init()` predates
`flag.Parse()` in `main`, so `main.go` needs no flag-plumbing change; explicit flag wins
over env, mirroring `-headtrack-ingest`). **The default build contains neither the flag
nor the env read** — there is nothing to enable. Runtime-on in a default build is
therefore meaningless (I3), and compile-on with runtime-off is a pure passthrough (I1
class). The runtime flag is only the third gate of five: per-tick `armed` (deadman) and
the full precondition set (§5) still sit on top, and `-headtrack-ingest` must separately
be on for an intent source to exist at all — ingest-on + FIRST_ACTIVE-off remains
today's log-only behavior verbatim (§2.3.11.4).

**How the combination is tested** (full matrix in §6):

| Build | Runtime | Expected | Proof |
|---|---|---|---|
| default (no tag) | n/a (flag absent) | byte-identical CRSF, no arbiter symbols | A1, A2, A3, A4 |
| `w17_first_active` | off | byte-identical CRSF | GB-1 (identity trio) |
| `w17_first_active` | on, no calibration | inert — byte-identical | GB-2, D18 |
| `w17_first_active` | on, calibrated (test fixture), not armed | byte-identical | GB-3, B1 |
| `w17_first_active` | on + armed + enabled + centered + fresh | shaped output on ch9/10 only | Group B/C/D |

---

## 3. File/package plan (exact, minimal-diff)

### 3.1 The choke point — named

`pkg/link/send.go`, function `SendLoop`, tick branch. At `432a809` the send tick runs:
`now := time.Now()` (**line 299**) → config-swap gate observe (**301**) →
`channelsData = gate.values(port.Name)` (**307**) → suppression checks (**320–333**) →
resume log (**335–338**) → **line 340:**

```go
if _, err = port.Write(crsf.PackChannels(channelsData)); err != nil {
```

The arbiter is a **single stage inserted between line 338 and line 340** — after every
suppression decision (a suppressed tick transmits nothing and the arbiter does not run;
its dt-clamp, §5.4, makes the gap step-safe), immediately before `crsf.PackChannels`:

```go
channelsData = c.arbitrate(channelsData, port.Name, now)   // W17 U4 seam; identity in default builds
```

This is the §2.3.11.1 single post-node-graph choke point: it reads the eval array and the
read-only intent snapshot, may replace **indices 8/9 only**, in a **copy** (D12 — the
array pointer is shared with `configCtl.EvalDataMap` and the diagnostics RPCs; the map
entry is never mutated in place), and passes the result to the packer. Nothing else in
the send loop, eval loop, node graph, receiver, broadcaster, proto, or firmware changes.

### 3.2 New package `pkg/headarbiter`

| File | Build tag | Contents |
|---|---|---|
| `doc.go` | none | package doc: safety boundary, gate structure, pointer to the unlock plan §2.3.11/§2.3.12 |
| `inert.go` | `!w17_first_active` | `func CanEverBeActive() bool { return false }` — the A3 predicate. No `Arbiter` type exists in this mode |
| `gate.go` | `w17_first_active` | `func CanEverBeActive() bool { return true }`; runtime-flag holder |
| `arbiter.go` | `w17_first_active` | `Arbiter` struct (single-goroutine tick state + a small mutex-guarded read-only status snapshot for tests/logs), `New(Config) (*Arbiter, error)`, `Process(portName string, in *[16]util.CRSFValue, now time.Time) *[16]util.CRSFValue` |
| `state.go` | `w17_first_active` | states IDENTITY/MANUAL/ARMING/ACTIVE/DECAYING/OVERRIDDEN/FAULT + transition function (§5.2 guards), transition logging |
| `shaping.go` | `w17_first_active` | single-pole low-pass, deadband (degrees), hybrid position→rate blend, deg→count conversion via the calibration table, endpoint clamp, rate+accel limiter with fractional accumulation and dt clamp |
| `calib.go` | `w17_first_active` | fail-closed calibration/policy record: schema, loader, validator (§3.4) |
| `controls.go` | `w17_first_active` | `ControlsSource` interface + edge/chord detection (arm gesture 1 s accumulation, SHARE short-press, deadman held, override deflection), all on values carrying explicit validity |
| tests | per-mode | `inert_test.go` (`!w17_first_active`), the rest `w17_first_active` (§6) |

`pkg/headarbiter` imports: stdlib, `pkg/util` (CRSFValue, MapRange), `pkg/headintent`
(the `Diagnostics` value type only — read-only), and **nothing else**. It never imports
`config`, `link`, `crossfire`, `serial`, `devices`, `server`, `http` (A5 keeps
`go list -deps` clean; the SDL adapter lives in `cmd`, below, so the arbiter core stays
device-free and fake-able).

### 3.3 Existing files changed (the complete diff list)

| File | Change | Mode |
|---|---|---|
| `pkg/link/send.go` | +1 line: the seam call between lines 338/340 (+ a short comment) | both builds |
| `pkg/link/controller.go` | +1 line: embed `arbiterSlot` in `Controller` (struct at lines 20–46) | both builds |
| `pkg/link/arbiter_off.go` (new) | `//go:build !w17_first_active`: `type arbiterSlot struct{}` and `func (c *Controller) arbitrate(v *[16]util.CRSFValue, _ string, _ time.Time) *[16]util.CRSFValue { return v }` — returns the same pointer, provably identity | default |
| `pkg/link/arbiter_on.go` (new) | `//go:build w17_first_active`: `arbiterSlot{arb *headarbiter.Arbiter}`, `AttachArbiter(...)`, `arbitrate` delegating `nil`-safe to `arb.Process` | gated |
| `cmd/elrs-joystick-control/main.go` | ~4 lines: hoist `var hiDiag func() hi.Diagnostics` out of the `if *headTrackIngest` block (set to `hiRcv.Diagnostics` inside it, line ~89–101) and one call `armHeadArbiter(linkCtl, devicesCtl, hiDiag)` after line 119 | both builds |
| `cmd/elrs-joystick-control/firstactive_off.go` (new) | `//go:build !w17_first_active`: no-op `armHeadArbiter` | default |
| `cmd/elrs-joystick-control/firstactive_on.go` (new) | `//go:build w17_first_active`: `init()` registers `-first-active-arm` (env `W17_FIRST_ACTIVE_ARM` default); `armHeadArbiter` loads calibration (`W17_HEADTRACK_CALIB` path), builds the SDL `ControlsSource` adapter over `devicesCtl` (below), constructs the arbiter, `linkCtl.AttachArbiter(...)`. Refuses (stays inert, logs why) when: runtime flag off, `hiDiag == nil` (ingest off), calibration absent/invalid, bindings absent/invalid | gated |

**Zero changes anywhere else.** Explicitly untouched: `pkg/headintent/**` (including
`pack_deadend_test.go`, which must pass unmodified), `pkg/proto/**` + generated stubs +
`webapp/**` (§4), `pkg/config/**`, `pkg/devices/**`, `pkg/serial/**`, `pkg/crossfire/**`,
`pkg/server/**`, `go.mod`/`go.sum`/`go.work`/`go.work.sum`, `.githooks/pre-push`,
`FORK-NOTICE.md` (its GPL §5(a) table is updated only when something is *published*,
which this branch never is; add the row at merge time post-review).

**The SDL ControlsSource adapter** (inside `firstactive_on.go` or a sibling gated file in
`cmd`): implements `headarbiter.ControlsSource` over `devicesCtl` per the §2.3.11.1
input-provenance rule — arm/deadman/override are **never** read from the `[16]CRSFValue`
array. Each tick it resolves the bound gamepad via `devicesCtl.Gamepad(id)` and gates on
`InputGamepad.Attached()` (`pkg/devices/device.go:33` — the SDL-level presence check the
2026-07-30 fix added); returns `(snapshot, ok)` where `ok=false` (missing id or detached)
is an **affirmative disarm** (I10). It reads deadman/arm/recenter controls and the two
override axes as raw device values, converting axes to counts with the same
`util.MapRange` the axis path uses so the takeover threshold compares in CRSF counts.
Bindings (device id; SHARE=8, OPTIONS=9, D-pad DOWN=13 per the adopted Alternative C, but
carried as *configured* button-or-hat bindings, not hardcoded, because a D-pad is a hat
on some pads and **the live node-graph binding validation is still owed** — §2.3.12.6)
come from the same fail-closed config file as calibration. Known residual to record for
R-review: this adds a second goroutine reading SDL joystick values (the send loop) beside
the eval loop and the gRPC device streams — same pattern the codebase already has, but
real-hardware concurrency behavior is a bench item.

### 3.4 Fail-closed calibration/policy struct (D18)

`headarbiter.Calibration`, loaded from a JSON file named by `W17_HEADTRACK_CALIB`
(gated build only). **Absent path, unreadable file, parse error, any missing field, any
out-of-policy value, or missing sign-off ⇒ `New` returns an inert arbiter** that can
never leave passthrough even with both flags on and everything held — and logs one line
saying so. **No numeric default exists anywhere in code — not one.** Required content
mirrors the §2.3.12.8 derivation record:

- Per axis (pan, tilt): `center_count`, `safe_min_count`, `safe_max_count`, `sign`,
  `counts_per_degree` (or a monotone deg↔count table — the U3/CB9 bench artifact),
  `stationary_jitter_deg`, `controller_noise_counts`.
- Policy constants (R12-class, same file, same fail-closed rule): `deadband_deg`
  (validator enforces the §2.3.12.8 floor/cap: reject < 1.0 or > 3.0 — over-cap is a
  review, not a clamp), `max_rate_deg_s` (reject ≤ 0 or > 10), `max_accel_deg_s2`
  (reject ≤ 0 or > 20), `takeover_threshold_counts` (reject below
  `max(controller_noise_counts, 0.10 × usable half-range)`), `lowpass_tau_ms`,
  `invalid_fault_threshold` + `invalid_fault_window_ms`, `fault_recovery_valid_ms`,
  `bindings` (device id + control bindings + `target_port` — the CRSF port name the
  arbiter is allowed to touch; any other port is identity, reinforcing I4).
- Metadata, all required non-empty: `hardware_id`, `measured_date`, `operator`,
  `evidence_source`, `signed_off_by`, `schema_version`.

Until R7/R12 exist there is no valid production file; test fixtures carry values labeled
TEST-ONLY inside the test files. This is exactly the owner's "missing calibration ⇒ FAIL
CLOSED, no production values signed" decision realized as the loader's contract.

---

## 4. Proto policy — ZERO proto changes on this branch (recommended)

`pkg/proto/server.proto` stays byte-identical: `HeadIntentState` still ends at
`HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` (`server.proto:527`) — that terminal value is a
deliberate safety marker, and hook check 3 refuses any `HEAD_INTENT_STATE_ACTIVE*`
addition. No new fields on `HeadIntentDiagnostics`, no new RPC, no stub regeneration, no
webapp change. Arbiter observability on the branch is **log-only**: one line per state
transition (D13's branch-scope form) plus an in-process read-only status getter consumed
by tests. The existing log-only diagnostic states are untouched and keep flowing to the
GS exactly as today.

**The alternative, and why it is deferred to R-review:** export arbiter state over the
existing stream (an `arbiter_state` field or enum on `HeadIntentDiagnostics`, or a ninth+
enum value). Deferred because (a) the §2.3.12.10 D13 row itself says no active enum value
exists "before the gated slice adds it **under review**" — the shape of the wire-visible
active vocabulary is precisely an R-review item; (b) it would regenerate four committed
artifacts (`pkg/proto/generated/pb/*.go`, `webapp/src/generated/*.js`) and ripple into
the GS canonical snapshot — cross-repo churn with zero bench value while diagnostics are
log-only; (c) it converts the hook's check 3 from a hard backstop into something the
branch must negotiate with. The operator-facing display of arbiter state (and the
required degraded-video state, §2.3.12.1) are activation-milestone work, not branch work.

**GS proto-drift guard — why the branch cannot disturb it:** the non-hermetic half
(`w17-ground-station/scripts/check-canonical-proto.js`, `resolveMapperProto`) reads
`W17_MAPPER_REPO` or `../w17-mapper` — i.e. the **live checkout** in the workspace, which
stays on `w17-headtrack`; the U4 branch exists only in a worktree outside the workspace,
so the guard never sees it. The hermetic half (`test/protoDrift.test.js`) compares the GS
copy against the checked-in snapshot and involves the mapper not at all. And because the
branch changes zero proto bytes, even a hypothetical mis-checkout would produce no drift.
`npm run proto:check` stays green with nothing to do.

---

## 5. Behavior spec condensed to implementable units

### 5.1 Where this sits in the canonical A–O order (§3.1)

This branch is step **M** ("implement U4 in small reviewed slices") executed early as
**branch-only code** under the 2026-08-16 amendment. **L** (fresh adversarial R1–R16
re-check) still gates merge/push/flag-flip; **G–K** (A2, Phase B, U3 measurements, iPhone
validation, constants signing) still gate the calibration file without which this code is
inert; **N/O** (bench validation, driving milestone) are untouched. Decision 11's
driving-time decay-to-center vision belongs to the firmware radio-loss layer and the U8
re-review — out of arbiter scope (the arbiter's own intent-loss layer already decays to
992).

### 5.2 State machine (from §2.3.12.10, verbatim semantics)

States: `IDENTITY` (compile flag absent or runtime flag off — only reachable state in
default builds; bit-for-bit passthrough), `MANUAL` (flags on, not armed; passthrough),
`ARMING` (arm gesture accumulating; passthrough), `ACTIVE` (shaped head output),
`DECAYING` (ramp to 992; `virtualCameraCenter` discarded), `OVERRIDDEN` (manual latched;
passthrough via limiter until converged), `FAULT` (ramp to 992 then passthrough; head
ineligible).

Transitions and guards, mapped to one pure function
`step(prev State, in Inputs) (next State, Effects)`:

- `MANUAL→ARMING`: D-pad DOWN + OPTIONS both newly held (Alternative C), device valid.
- `ARMING→ACTIVE`: 1000 ms continuous hold elapsed AND explicit recenter performed
  (SHARE short-press latched during the armed-pending window) AND all §5.3 preconditions
  true this tick. Any interruption of the chord before completion → `MANUAL`.
  (OPTIONS may release after the 1 s completes; D-pad DOWN remains the continuous
  deadman.)
- `ACTIVE→DECAYING`: any precondition lost, one invalid packet (invalid-count delta > 0),
  or intent silence past the active gate. Also `ARMING/ACTIVE→MANUAL/DECAYING` on deadman
  release or device loss (release and disappearance reach the identical disarm — I10).
- `ACTIVE|DECAYING→OVERRIDDEN`: manual deflection past `takeover_threshold_counts` on
  **either** override axis (global takeover, both axes, wins during active AND during
  decay — §2.3.12.5).
- `DECAYING→ACTIVE`: **never automatic**; requires explicit recenter (deadman may remain
  held). Fresh data alone never re-acquires.
- `OVERRIDDEN→ACTIVE`: explicit recenter + rearm only (full gesture).
- `ANY→FAULT`: invalid packets ≥ `invalid_fault_threshold` within
  `invalid_fault_window_ms`, or receiver state `fault`.
- `FAULT→MANUAL`: operator disarm AND continuous valid traffic for
  `fault_recovery_valid_ms` AND explicit recenter, in that order; rearm then proceeds
  through `ARMING` normally.
- Deadman release / device absence in any state ⇒ immediate disarm ⇒ `DECAYING` (if head
  authority engaged) then `MANUAL`.

Effects: every transition logs once; every output change routes through the limiter
(§2.3.11.2 item 8 — no transition may step the output).

### 5.3 Per-tick execution pipeline (function map)

`Arbiter.Process(portName, in, now)` — called once per send tick from the seam:

1. `guardPort` — `portName != calib.TargetPort` ⇒ return `in` unchanged.
2. `readIntent` — `diag()` snapshot (`headintent.Diagnostics`; read-only). Freshness =
   `*PacketAgeMs` (mapper receive-time; the iPhone `timestamp_ms` is never consulted —
   I7). **Active gate ≤ 250 ms: 249/250 fresh, 251 not-fresh** — stricter than and
   distinct from the 300 ms log-only boundary (299/300 fresh, 301 stale) that
   `DefaultStaleMs` (`pkg/headintent/packet.go:19`) and the monitor keep owning
   unchanged.
3. `readControls` — `ControlsSource.Snapshot()`; `ok=false` ⇒ disarm-now (provenance
   rule; never from the channel array).
4. `updateEligibility` — invalid-count delta (one invalid ⇒ eligibility removed
   immediately, decay begins — §2.3.12.4), fault latch bookkeeping (never cleared by
   traffic alone), enabled (`LastValid.TrackingEnabled`), centered (the exact
   `StateNotCentered` guard: `Centered` explicitly true and not `Calibrated == false`).
5. `step` — §5.2 transition function.
6. `computeTarget` (ACTIVE only) — `lowpass(yaw,pitch, tau, dt)` → subtract
   `virtualCameraCenter` (head-pose neutral seeded at recenter; command baseline seeded
   from the arbiter's last **commanded** value, never a claimed measured angle — §1.3/1.4)
   → `applyDeadband` in **degrees** → `hybridBlend` (position near neutral, smooth
   continuous transition to rate near the comfort boundary; yaw→pan, pitch→tilt, roll
   ignored) → `degToCounts` via the measured table → `clampSafe` to per-axis
   min/max counts. DECAYING/FAULT target = exactly 992/992. OVERRIDDEN/MANUAL/ARMING
   target = the eval array's own ch9/10 (manual path).
7. `limitToward` — rate ≤ `maxRate·dt`, rate-change ≤ `maxAccel·dt`, fractional
   sub-count remainders accumulated (D8), `dt = clamp(now-prev, 0, dtMax)` so ticker
   pauses/suppression gaps/wall-clock anomalies can never manufacture a step (D10; Go
   `time.Time` arithmetic is monotonic).
8. `emit` — if output == input values, return `in` (no copy); else copy the 16-array,
   write indices 8/9 only, return the copy (D12, I4). Update the status snapshot; log on
   transition.

### 5.4 Cross-cutting rules bound into the implementation

- **Decay target is commanded 992** (`util.CRSFCenterValue`, `pkg/util/util.go:49`),
  reached only through the limiter; `virtualCameraCenter` is discarded on every exit from
  ACTIVE (I5). 992 is a commanded neutral, not a physically validated one (§1.3).
- **Manual override latches** until explicit recenter + rearm (I6); stick-return does not
  restore; override detection reads device axes, output value during OVERRIDDEN is the
  graph's own ch9/10 passthrough (converged via limiter).
- **Video loss is invisible by design**: sender suppression ⇒ ordinary silence ⇒ the same
  not-fresh decay (D16 asserts indistinguishability). No video-health input exists in the
  arbiter.
- **Invalid packets can never acquire/extend/define anything** — not last-valid, not
  freshness, not center (§2.3.12.4; the monitor already never lets invalid replace
  last-valid).
- **Controller affordances** (Alternative C, bench-only): short-press SHARE = recenter;
  hold D-pad DOWN + OPTIONS 1 s = arm; OPTIONS may release; D-pad DOWN = continuous
  deadman; release = disarm. GS presets confirm 8/9/13 unbound in the display mirror
  (`w17-ground-station/shared/inputPresets.mjs` STANDARD_MAP binds axes 0/2/3 and buttons
  1–7 only), but **the binding authority is the mapper's node-graph config — the live
  binding validation (SHARE/OPTIONS/D-pad DOWN unbound and not intercepted) is still
  required before any active use and cannot be closed on this branch** (open item,
  §2.3.12.6; if any control is bound, active testing stays blocked, no silent remap).

---

## 6. Test plan

Conventions: gated tests carry `//go:build w17_first_active` and run under
`go test -tags w17_first_active`; default-mode tests run plain. The arbiter's unit tests
use injected clocks, a fake `ControlsSource`, and synthetic `headintent.Diagnostics`
values — no sleeps, no sockets, except where the existing dead-end pattern already uses
real loopback UDP.

### Group A — inactive byte-identity (default build; proves I1, I3, I4)

| Plan row | Go test (package) | Notes |
|---|---|---|
| A1 | `TestSeamIdentityFlagOff_PackBytes` (`pkg/link`) | pack_deadend vectors (12 frames/312 bytes) routed through `Controller.arbitrate` vs direct: `bytes.Equal` + same-pointer assertion, under no/valid/stale/invalid traffic against a real loopback receiver; existing `TestPackChannelsUnchangedByReceiver` (`pkg/headintent/pack_deadend_test.go:180`) continues to pass untouched |
| A2 | `TestSeamIdentityFlagOff_WithSubscribers` (`pkg/link`) | same with a running Broadcaster + connected/slow/disconnected subscribers (mirrors `pack_deadend_test.go:224`) |
| A3 | `TestCanEverBeActiveFalse` (`pkg/headarbiter`, `!w17_first_active`) + `scripts` check `verify_inert_build.sh` (branch-local) | predicate false; build default `cmd` binary and assert `go tool nm` shows **no** `headarbiter` arbiter/state/shaping symbols (host needs SDL + `webapp/dist`, same prerequisites `go build ./...` already has) |
| A4 | `FuzzSeamIdentityFlagOff` (`pkg/link`) | fuzz random 16-channel arrays incl. random ch9/10: output array identical, same pointer |
| A5 | `TestArbiterDependencyBoundary` (`pkg/headarbiter`) | `go list -deps` assertions: headarbiter reaches no config/link/crossfire/serial/devices/server/http; nothing outside `pkg/link`+`cmd` (gated files) imports headarbiter; `pkg/headintent` production deps unchanged |

### Gated-build identity trio (the three explicit preservation proofs)

`TestGatedIdentity_RuntimeOff` / `TestGatedIdentity_Uncalibrated` /
`TestGatedIdentity_CalibratedDisarmed` (`pkg/link`, gated): flags-on builds with (1)
runtime flag off, (2) runtime on + nil/invalid calibration, (3) runtime on + TEST-ONLY
calibration + never armed — packed bytes `bytes.Equal` to the default-build baseline hex
(the A1 dump), under valid/stale/invalid traffic. Plus
`TestGatedDeadEndSuiteStillGreen`: the untouched `pkg/headintent` suite also runs green
under `-tags w17_first_active`.

### Group B — active gating (gated build; proves I2, I5, I6, I7)

B1 `TestPreconditionDropout` (table-driven single-negation of {compile≡build-mode note,
runtime flag, armed, enabled, centered, fresh} ⇒ decay to exactly 992);
B2 `TestDeadbandDegrees` (inside band ⇒ 992, band converted through the fixture table);
B3 `TestRateLimit`; B4 `TestAccelLimit`; B5 `TestFreshnessBoundary249_250_251` (and, in
the same test, the log-only 299/300/301 boundary unchanged); B6 `TestDecayReaches992Ramped`
(+ virtualCameraCenter discarded); B7 `TestTimestampSkewIgnored`;
B8 `TestOtherChannelsUntouched` (14 non-gimbal channels byte-identical in every Group-B
case). All in `pkg/headarbiter`.

### Group C — arbitration & no-auto-restore (gated; proves I6, I8, I9)

C1 `TestOverrideWinsImmediately`; C2 `TestNoAutoRestoreAfterOverride`;
C3 `TestNoAutoArm` (no input combination arms without the gesture);
C4 `TestRearmReseedsFromCommanded`; C5 `TestEveryTransitionRamped` (arm/disarm/override/
stale/fault each assert per-tick |Δ| bounds); C6 `TestArbiterReadOnlyInputs` (state-diff
harness over receiver diagnostics, fake controls, and the input array before/after —
also covers D12 with the shared-map non-mutation assertion).

### Group D — gated implementation details (§2.3.12.10 rows)

D1 `TestOneInvalidRemovesEligibility`; D2 `TestRepeatedInvalidLatchesFault`;
D3 `TestFaultRecoveryOrder` (disarm→valid-interval→recenter, each alone insufficient);
D4/D5 `TestOverrideDuringActive/DuringDecay`; D6 `TestHybridBlendContinuity` (value-
continuous, derivative-bounded across the position→rate transition);
D7 `TestRecenterDefinesNeutral`; D8 `TestFractionalAccumulation` (no truncation bias at
sub-count rates); D9 `TestEndpointClampNeverExceeded` (including transients);
D10 `TestMonotonicTimeAndDtClamp` (wall-clock jumps + tick gaps ⇒ no step);
D11 `TestNoDataEverIdentity`; D12 `TestCopyOnWrite`; D13 `TestTransitionLogging`
(log-only form; proto untouched asserted by A5/no-diff); D14 `TestReconnectAloneNeverRestores`;
D15 `TestDeadmanReleaseFromEveryState`; D16 `TestVideoSuppressionIndistinguishableFromStale`;
D17 `TestLowpassStepResponse` (matches tau, no overshoot); D18 `TestCalibrationFailClosed`
(absent/unreadable/missing-field/out-of-policy/unsigned ⇒ inert; plus deadband>3° rejected,
rate>10°/s rejected, accel>20°/s² rejected, threshold-below-formula rejected);
D19–D22 (unit seam layer) `TestDeviceLossSeam_Arming/Active/Overridden/ReconnectAlone` —
fake ControlsSource flips `ok=false`: disarm identical to release, reconnect restores
nothing, and device-absent never maps to a retained previous value (I10). The
**physical-unplug** arm of D19–D22 is R15 and stays open (below).

### Race/concurrency

`TestProcessVsDiagnosticsRace`, `TestProcessVsStatusReaderRace` (gated, `-race`): send-
tick `Process` concurrent with live receiver ingest + broadcaster fan-out + status reads;
plus the whole suite under `go test -race` in both build modes (the repo's existing
39-test/-race baseline must stay green).

### Invariant coverage table

| Invariant | Proven by |
|---|---|
| I1 inactive ⇒ byte-identical | A1, A2, identity trio, existing dead-end suite |
| I2 active is multi-gated | B1, GB trio, D18, C3 |
| I3 default build cannot be active | A3 (predicate + symbol absence), A4 |
| I4 ch9/ch10 only | B8, emit design + `TestOtherChannelsUntouched`, guardPort test |
| I5 decay-to-992 ramped, never hold/step | B6, C5, D9 |
| I6 no auto-arm / no auto-restore | C2, C3, D14, D5 |
| I7 receive-time freshness only | B5, B7 |
| I8 read-only inputs | C6, D12, A5 |
| I9 firmware/Electron boundaries intact | zero-diff outside w17-mapper (branch rule 4), A5, proto no-diff; GS suite unaffected by construction |
| I10 device loss ⇒ disarm | D15, D19–D22 seam layer; physical arm = R15 (open) |

Estimated total: **~48 Go test functions** (A:5+script, trio:4, B:8, C:6, D:22, race:2,
loader/table subtests inside D18) executed in **two build modes**.

### Cannot be proven on this branch — stays open for R-review (honest list)

1. **R15 / D19–D22 physical arm** — real gamepad unplug/reconnect from ARMING, ACTIVE,
   OVERRIDDEN on the real SDL/OS removal path (hardware-procedure class; unit seam only
   approximates it).
2. **R16 (FIRST_ACTIVE)** bench servo sweep — Phase B gated; nothing on this branch
   moves hardware.
3. **R7** — real deg↔count table, endpoints, signs, jitter floor: the calibration file
   contents themselves. Until then the arbiter is inert by design.
4. **R12** — signed production constants (the branch ships validators, not values).
5. **R8/R9/R10 residuals** — iPhone axes/mount, real-device log-only bridge, real-device
   sender lifecycle.
6. **Live node-graph binding validation** — SHARE/OPTIONS/D-pad DOWN unbound and not
   intercepted in the *mapper's* config (GS preset evidence is only the display mirror);
   includes settling button-vs-hat reality for D-pad DOWN on the bench pad.
7. **SDL cross-goroutine reads on real hardware** and real Windows ELRS enumeration.
8. **Operator-facing degraded-video state** (required before the active milestone;
   GS-side, separate repo).
9. Arm-gesture ergonomics (1 s hold feel), the R1/R6 gates themselves, and everything in
   the §2.3.12.11 NO-GO table that is hardware-evidence class.

---

## 7. Effort & sequencing — 4 slices, each independently green in both build modes

**Slice 1 — pure core, no wiring.** `pkg/headarbiter`: doc/inert/gate files, calibration
loader + validator (D18 complete), shaping math (lowpass/deadband/hybrid/clamp/limiter/
fractional/dt-clamp) as pure functions with B2–B4, D6, D8–D10, D17. Nothing imports the
package; both modes build; default binary unchanged by construction. (Largest slice;
roughly a third of the work.)

**Slice 2 — state machine + eligibility.** `state.go`, `controls.go` seams, invalid/fault
policy, freshness gate, virtualCameraCenter seeding. Tests B1, B5–B7, C1–C5, D1–D5, D7,
D11, D13–D16, D19–D22 seam layer. Still unwired.

**Slice 3 — the seam + cmd wiring.** `pkg/link` slot/off/on files + the send.go line +
controller.go embed; `cmd` off/on wiring files, runtime flag, SDL ControlsSource adapter,
fail-closed refusals. Tests: Group A complete (A1–A5), gated identity trio, B8, C6, D12,
race pair, symbol-absence script. This is the slice where byte-identity is demonstrated
end-to-end and hex dumps are archived as evidence.

**Slice 4 — matrix closure + review packet.** Full `go test` + `-race` in both modes,
`go vet` scoped to owned packages (`./pkg/headarbiter ./pkg/link ./pkg/headintent
./pkg/server` — repo-wide vet is documentedly not green upstream), coverage sweep against
the §2.3.11.5 + §2.3.12.10 matrices, evidence bundle (dumps, nm output, deps listings),
and the R-review handoff: the §6 open-items list verbatim, so the review consumes code +
evidence + honest gaps in one place.

Sequencing note: slices 1–2 are pure-Go and independent of the SDL/webapp host
prerequisites; slice 3 needs the full-build host state that `go build ./...` already
has (SDL2, `webapp/dist`, serial v1.6.0). Nothing in any slice requires hardware, the
network, the live 5602 port, or any repo other than `w17-mapper`.
