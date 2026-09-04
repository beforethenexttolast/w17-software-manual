# G-01 — FIRST_ACTIVE: preconditions to even *request* the gate

> ## FIRST_ACTIVE IS **NO-GO / BLOCKED**.
> `w17-control-fw/project-review/head_tracking_unlock_plan.md:1366-1385` (§2.3.12.11
> go/no-go table, verdict **NO-GO / BLOCKED**) · `W17_CURRENT_STATE.md:61`
> ("FIRST_ACTIVE NO-GO; nothing flashed/powered") ·
> `w17-mapper` `docs/u4-branch-README.md` (u4-arbiter branch, "BRANCH-ONLY. NEVER MERGE.
> NEVER PUSH.").
>
> **This card is not an execution plan and does not become one.** It is the list of
> things that must all be true, with evidence, *before an owner can be asked to
> convene the FIRST_ACTIVE review at all*. Assembling this list moves no gate. Running
> anything on this card moves no gate. Nothing on this card authorises power, flashing,
> servo movement, iPhone→CRSF, iPhone→servo, or an active pan/tilt path — all of which
> remain forbidden by workspace `CLAUDE.md` safety boundaries 1–7.
>
> **Evidence label: NOT-EXECUTED.**

---

## Prerequisites

Two layers gate the *request*, and they are not the same list.

**Layer 1 — the Codex-owned milestone document** (`iPhone_rc/docs/FIRST_ACTIVE_PAN_TILT_MILESTONE.md`).
Where the two disagree, this document gates movement
(`head_tracking_unlock_plan.md:9-12`). Its "Required Completed Milestones"
(`FIRST_ACTIVE_PAN_TILT_MILESTONE.md:24-47`) are, verbatim in substance:

| # | Required before first physical movement | Cited | Status today |
|---|---|---|---|
| L1 | Real iPhone bench test passed (`docs/REAL_IPHONE_BENCH_TEST_PLAN.md`) | :28 | **BENCH-TBD** — needs iPhone + bench network (`CURRENT_STATUS.md` CB6 `BLOCKED_HARDWARE`, :1342) |
| L2 | Core Motion yaw/pitch/roll axes documented on the real iPhone | :29 | **BENCH-TBD** (= R8 / U5, Codex Batch 5) |
| L3 | Phone mount orientation documented for the intended holder/VR setup | :30 | **BENCH-TBD** |
| L4 | Center/calibrate behaviour validated on the real iPhone | :31 | **BENCH-TBD** |
| L5 | Send gating validated: tracking off ⇒ no packets; enabled-not-centered ⇒ no packets; reset calibration ⇒ packets stop | :32-35 | **BENCH-TBD** (automated only) |
| L6 | Windows log-only bridge validated (`docs/WINDOWS_BRIDGE_INTEGRATION_PLAN.md`) | :36 | **BENCH-TBD** (= R9 / U1 / CB6) |
| L7 | Packet schema validation implemented and tested in Windows | :37 | **INFERRED PASS** — `w17-mapper/pkg/headintent/packet.go`, ported 1:1 from `w17-ground-station/shared/headTracking.js` (`head_tracking_unlock_plan.md:267-272`) |
| L8 | Malformed packet rejection validated | :38 | **INFERRED PASS** — same, invalid never replaces last-valid (`:273-275`) |
| L9 | Packet stale behaviour validated at the Windows bridge | :39 | **INFERRED PASS** for the 299/300/301 boundary, test-proven (`:274-276`); **BENCH-TBD** against a real device |
| L10 | iPhone local motion-sample freshness ≤ **250 ms**, and packet generation stops when the sample is older | :40 | **NO-GO** — R10 PARTIAL: automated only; real-device lifecycle pending (`head_tracking_unlock_plan.md:1379`). Shipped iPhone value is still **500 ms** — `staleAfter: TimeInterval = 0.5` at `iPhone_rc/FPVHUDApp/Models/MotionState.swift:112`, used at `:122`. (The plan cites this as `:82` at `head_tracking_unlock_plan.md:63`; the value is unchanged, the **line has drifted to 112** — a citation fix owed to `w17-control-fw`, a different repo and session.) |
| L11 | Packet rate and sequence behaviour observed | :41 | **BENCH-TBD** on a real device |
| L12 | Manual override behaviour designed | :42 | **PASS (design)** — right-stick-wins, no auto-restore (`head_tracking_unlock_plan.md` §2.3.11.2 item 7) |
| L13 | Operator arm/disarm behaviour designed | :43 | **PASS (design)** — Alternative C, owner-resolved 2026-07-15 (`head_tracking_unlock_plan.md:1591-1598`) |
| L14 | Output limits, deadband, smoothing, rate limiting **designed** | :44 | **PASS (design)**; the **values** are R12 and are **NO-GO** |
| L15 | A rollback plan exists to return to log-only behaviour | :45 | **PASS** — R14 (`head_tracking_unlock_plan.md:1383`); u4 rollback section, both halves |

`FIRST_ACTIVE_PAN_TILT_MILESTONE.md:47`: *"If any item is unknown, untested, or only
simulator-validated, do not proceed."* L1–L6, L9 (real device), L10 and L11 are exactly
that. **Layer 1 is not satisfiable at a desk.**

**Layer 2 — the Claude-side unlock checklist R1–R16**
(`head_tracking_unlock_plan.md:869-936`, verdict table `:1366-1385`):

| R | What it requires | Verdict | Why it is where it is |
|---|---|---|---|
| R1 | Codex milestone checklist passed, go/no-go table filled with evidence | **NO-GO** | not run (`:1370`) — this is Layer 1 above |
| R2 | readiness §8's 7 blockers accounted for; **no independent waiver** | **NO-GO** | pure cross-reference; passes only when R7/R12/R13/R4/R8/R9/R16 do (`:1371`) |
| R3 | Owner decision #2 video-loss reaction | **PASS (decision)** | §2.3.12.1, 2026-07-15 (`:1372`) |
| R4 | Failsafe hold-vs-center recorded | **PASS (bench scope only)** | driving-scope re-review still owed (`:1373`, `:1511`) |
| R5 | First head-tracked driving protocol / spotter | **PASS (decision)** | bench-only (`:1374`) |
| R6 | **A2 closed + Phase B approved** for any powered validation | **NO-GO** | A2 unexecuted, Phase B blocked (`:1375`, `W17_CURRENT_STATE.md:61`) |
| R7 | Real gimbal endpoints measured + deg↔CRSF-count table | **NO-GO** | hardware, gated behind R6 (`:1376`) |
| R8 | iPhone axis/mount validation on the real rig | **NO-GO** | hardware (`:1377`) |
| R9 | Real iPhone↔Windows log-only bridge, end to end | **NO-GO** | hardware/network (`:1378`) |
| R10 | iPhone sender-side 250 ms sample-age suppression | **PARTIAL — PASS (automated)** | real-device lifecycle + canonical commit + mirror pending (`:1379`) |
| R11 | Fork repo path/name/remote/branch + licence | **PASS** | `:1380` |
| R12 | Shaping constants **signed** — widened 2026-09-03 (OD-17) to `pkg/headarbiter/calib.go`'s **full** schema: 6 metadata + 14 per-axis + 10 policy + the bindings block | **NO-GO** | values need R7 measurement (`:1381`) |
| R13 | Full Group A/B/C matrix green, byte-identical-while-inactive on the default build | **NO-GO** | matrix *is* green in both build modes on `u4-arbiter`; still NO-GO because (a) **no adversarial desk R-review by anyone but its author** — roadmap step L — and (b) R15/R16 rows need hardware (`:1382`) |
| R14 | Written rollback | **PASS** | `:1383` |
| R15 | Device-loss disarm demonstrated by **physically unplugging** the pad, from `ARMING`/`ACTIVE`/`OVERRIDDEN`, reconnect proves no restore | **NO-GO** | hardware-*procedure* class, **not** Phase-B class; transport ruled OD-18 (git bundle by hand, never a push) (`:1384`) |
| R16 | **FIRST_ACTIVE R16** bench-only servo sweep, wheels off, no stall / no brown-out / correct direction, **no waiver clause** | **NO-GO** | requires Phase B, gated behind R6 (`:1385`) |

> ⚠ **Name collision, always qualify.** A *different* R16 exists in
> `w17-control-fw/project-review/10_risk_register.md`. A commit saying "R16 closed"
> refers to that one and says **nothing** about FIRST_ACTIVE R16
> (`head_tracking_unlock_plan.md:925-929`).

**Layer 3 — the roadmap order.** Even with every R item green, `head_tracking_unlock_plan.md:1525-1541`
puts step **L** (fresh adversarial full R1–R16 re-check) after steps A–K, and step **M**
(implement U4) only after approval. The u4 code exists early under a *branch-only*
amendment (`:855-867`); that amendment moved nothing else.

## Required equipment

**To assemble the request packet: none.** Everything on this card is reading and
writing. That is the point of the card.

For the reader's planning only — the equipment the *gated* work would later need, none
of which this card authorises: assembled gimbal mount + measuring rig (R7), a real
iPhone + a non-isolated bench network (R8/R9/L1–L6), a real Windows box + a real DS4
and a hand to unplug it (R15), and a powered bench with the car immobilised and wheels
off the ground plus an observer (R16 — **Phase B**).

## Topology

```
                 ┌────────────────────────── FORBIDDEN TODAY ───────────────────────────┐
                 │                                                                       │
  iPhone ──W3 UDP 5602 (LOG-ONLY)──► mapper (owned fork, w17-mapper)                     │
   HUD           │                     pkg/headintent  ── log-only ingest ──┐            │
                 │                     pkg/headarbiter  [u4-arbiter branch] │            │
                 │                       · compile-time tag w17_first_active│ INERT      │
                 │                       · runtime flag -first-active-arm   │ default-off│
                 │                       · signed calibration record        │ absent     │
                 │                       · per-tick arm gesture             │            │
                 │                                                          ▼            │
                 │                                          ch9 / ch10 ──►  ✗ ────────────┘
                 │                                                     (never, until FIRST_ACTIVE)
                 ▼
        Electron ground station  ──── viewer / config / log-only, never in the control path
                                       (test/noControlPath.test.js)

  DualShock ──► mapper node graph ──► [16]CRSFValue ──► CRSF ──► FT232 ──► ELRS TX
                                                                             │  radio
                                                                             ▼
                                          ESP32 #1 firmware: ch9/ch10 → pan/tilt servos
                                          (source-agnostic by construction; firmware is
                                           and stays iPhone-unaware — CLAUDE.md rule 4)
```

The `✗` is the whole gate. Everything left of it exists and is exercised; nothing
crosses it.

## Exact procedure

This procedure produces a **request packet**. It ends with a document handed to the
owner. It never ends with a test being run.

1. Re-read the two authorities in this order and record their tip commits:
   `iPhone_rc/docs/FIRST_ACTIVE_PAN_TILT_MILESTONE.md` (Layer 1, gates movement) then
   `w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.11.6 + §2.3.12.11
   (Layer 2). Where they disagree, Layer 1 wins (`head_tracking_unlock_plan.md:9-12`).
2. Read the `u4-arbiter` review packet **without checking the branch out** — it is
   `BRANCH-ONLY. NEVER MERGE. NEVER PUSH.` Use `git show` only (commands below).
3. For each of L1–L15 and R1–R16, fill one row of the packet with: current verdict, the
   `path:line` that establishes it, and — for anything not PASS — the single physical
   or owner act that would change it. Copy no verdict forward without re-reading its
   citation.
4. Copy the u4 branch's own honest list of what it **cannot** prove
   (`u4-branch-README.md` "Cannot be proven on this branch") into the packet verbatim,
   including the three live-node-graph items (SHARE/OPTIONS/D-pad DOWN unbound; the two
   manual-override axes' live config shape; the residual centre offset where a
   physically centred stick reads **991**, one count below `util.CRSFCenterValue`).
5. Add the standing collision warning about the two R16 series.
6. State the packet's own verdict. Given any NO-GO row, that verdict is
   **"do not convene"** — the review's own precedence rule
   (`head_tracking_unlock_plan.md:938-941`) forbids one R item's sign-off from waiving
   another's obligation, so no partial packet can be argued into sufficiency.
7. Hand the packet to the owner. **Stop.** Do not schedule, prepare, stage, or rehearse
   any FIRST_ACTIVE test as a consequence of writing it.

## Exact commands

Read-only. None of these builds, runs, flashes, powers or transmits anything.

```sh
# Layer 1 and Layer 2 authorities
sed -n '24,47p'     /Users/vitaliykhomenko/Documents/projects/iPhone_rc/docs/FIRST_ACTIVE_PAN_TILT_MILESTONE.md
sed -n '869,941p'   /Users/vitaliykhomenko/Documents/projects/w17-control-fw/project-review/head_tracking_unlock_plan.md
sed -n '1366,1386p' /Users/vitaliykhomenko/Documents/projects/w17-control-fw/project-review/head_tracking_unlock_plan.md
sed -n '1520,1542p' /Users/vitaliykhomenko/Documents/projects/w17-control-fw/project-review/head_tracking_unlock_plan.md   # roadmap A..O

# The u4 review packet — READ ONLY, never `git checkout u4-arbiter`
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper show u4-arbiter:docs/u4-branch-README.md | less
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper ls-tree -r --name-only u4-arbiter -- docs/u4-evidence/
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper show u4-arbiter:docs/u4-evidence/test_counts.txt
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper show u4-arbiter:docs/u4-evidence/pack_dumps.sha256
git -C /Users/vitaliykhomenko/Documents/projects/w17-mapper show u4-arbiter:docs/u4-evidence/calibration_record_TEMPLATE.md

# Standing gate state
sed -n '60,62p' /Users/vitaliykhomenko/Documents/projects/W17_CURRENT_STATE.md
```

**Commands that must NOT be run, and why:**

```sh
git -C .../w17-mapper checkout u4-arbiter     # forbidden: branch-only, and it would
                                              # relocate any other session's checkout
git -C .../w17-mapper merge u4-arbiter        # forbidden: NEVER MERGE
git push ... u4-arbiter                       # forbidden: the pre-push hook refuses this
                                              # tree by construction; --no-verify is
                                              # forbidden by the FORK-NOTICE push rule
go build -tags w17_first_active ./...         # not forbidden, but it is not this card's
                                              # work and produces nothing this packet needs
```

## Expected evidence

- A packet file with **31 rows** (L1–L15, R1–R16), each carrying a verdict and a
  `path:line`.
- The `u4-arbiter` "cannot be proven" list, quoted, not paraphrased.
- The tip commit of each authority document at the time the packet was written.
- An explicit statement that the packet's own verdict is **do not convene**.

## PASS / FAIL criteria

This card has **no PASS**. It is a request-readiness check, and its objective criterion
is a count:

| Criterion | Threshold | Today |
|---|---|---|
| R rows at NO-GO | must be **0** to convene | **10** — R1, R2, R6, R7, R8, R9, R12, R13, R15, R16 (`head_tracking_unlock_plan.md:1370-1385`; R12/R13/R15 restated as still NO-GO after the 2026-09-03 ratifications at `:1409`) |
| R rows at PARTIAL | must be **0** to convene | **1** (R10) |
| Layer-1 items not real-device validated | must be **0** to convene | **≥ 8** (L1–L6, L9-real, L10, L11) |
| Adversarial R1–R16 re-check by someone other than the u4 author (roadmap step **L**) | must exist | **does not exist** (`head_tracking_unlock_plan.md:1382`) |

**Any non-zero in that table ⇒ do not convene.** The result of this card is a packet,
never an authorisation.

## Stop conditions

Stop immediately, and say so in the report, if:

- anyone proposes checking out, merging, pushing, cherry-picking or bundling
  `u4-arbiter` as a *consequence* of this card (OD-18 rules the R15 transport, and that
  ruling belongs to R15's own session, not to this one);
- a source read here contradicts the standing NO-GO verdict — record it under
  **BASELINE CONTRADICTION** and act on nothing;
- an R row appears to have been closed without its cited evidence existing;
- any instruction to "just try it on the bench to see", in any wording. FIRST_ACTIVE's
  first movement test is bench-only *and still gated*
  (`FIRST_ACTIVE_PAN_TILT_MILESTONE.md:356-370`).

## Rollback

Nothing to roll back. This card writes one document and touches no repository other
than the workspace. The `u4-arbiter` resting state **is** the rollback (R14): default
builds carry no arbiter code, gated builds with the flag off are pure identity, and
deleting the branch restores `w17-headtrack` exactly — and, symmetrically, keeping the
branch cannot create a control path (no file it adds contains `net.`, `Listen`, `Dial`,
`5602` or `udp`).

## Outputs to save

```
bench-gates/evidence/G-01/
  first_active_request_packet.md      # the 31 rows + verdict + authority tip commits
  u4_cannot_be_proven.txt             # verbatim quote from the u4 review packet
  authority_tips.txt                  # git -C ... rev-parse for each source read
```

## Downstream unlocked by PASS

**Nothing.** By construction. A completed packet lets an owner *see* the distance to
FIRST_ACTIVE in one place; it unlocks no gate, authorises no test, and does not itself
count as R-item evidence for any row.

## BENCH-TBD residue

Everything real on this card. Named, so the residue is a list and not a feeling:

- **R6 chain** — A2 no-power inspection → Phase B approval → R7 endpoint measurement →
  R12 signature → FIRST_ACTIVE R16 sweep. Serial, and it starts with an owner act.
- **R8 / R9 / L1–L6** — a real iPhone on a real bench network.
- **R15** — a real Windows box, a real DS4, a hand on the cable; transport is a hand-copied
  `git bundle` (OD-18), never a push.
- **R13(a)** — an adversarial desk re-check of `u4-arbiter` by someone who did not write it.
- **The three live-node-graph unknowns** from the u4 packet: SHARE/OPTIONS/D-pad DOWN
  really unbound in the mapper's own graph (GS presets are only the display mirror);
  the two override axes' live `deadzone` / `output_invert` / `raw_min..crsf_max` shape
  versus the adapter's raw read; and the **991-vs-992** residual centre offset on a real pad.
- **Owner-facing degraded/lost-video state** — required before the active milestone,
  GS-side, separate repo.

## Evidence label

**NOT-EXECUTED.** No part of this card has been run. FIRST_ACTIVE remains **NO-GO /
BLOCKED**, and this card does not change that in either direction.
