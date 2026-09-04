# bench-gates/ — the firmware/bench gate ladder

**Every card in this directory is NOT-EXECUTED.** Nothing here grants, opens, weakens or executes
any gate. A2 is NOT-EXECUTED, Phase B is BLOCKED, BT1 is unopened, nothing has been flashed or
powered (`CURRENT_STATUS.md` top entry; `W17_CURRENT_STATE.md` §6).

These cards are **session wrappers** around runbooks that already exist. The runbook is always the
authority; where a card and its source disagree, **the source wins** and the card is wrong. Each
card names its source in its first line.

## The ladder

```
  OWNER RESIDUE (no gate, but SF cannot start without them)
     OW1  socket-stack caliper  vs  S0 >= 9.82 mm          ] both OWED,
     OW2  MH-ET silkscreen adjacent-pin list               ] neither closable on paper
             |
             v
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │ BG-01  A2 staged no-power gates      SF -> S1 -> S2 -> S3 -> S4/S4b(+S8a)     │  multimeter only
  │                                          -> S4c -> S5 -> S6 -> S7 -> S8b      │  NOTHING energised
  └──────────────────────────────────────────────────────────────────────────────┘
             |  the filled §11 table + 15 photos
             v
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │ BG-02  A2 closure   Part 1 reviewer check  +  Part 2 owner attestation        │  paperwork only
  └──────────────────────────────────────────────────────────────────────────────┘
             |  token: A2-CLOSED   (a RECORD, explicitly not a safety verdict)
             v
        [ OWNER-ONLY DECISION ]  token: PHASE-B-OPEN     <-- not automatic from A2-CLOSED
             |
             +----------------------------------------------+
             v                                              v
  ┌───────────────────────────────────┐        ┌──────────────────────────────────┐
  │ BG-03  Phase B first power        │        │ BG-06  CRSF on the wire          │
  │        B1 links & signals         │        │   T2 car half (RP1 -> GPIO16,    │
  │        B2 THE SAFETY CHAIN  ***   │<-------│      420000) needs Phase B       │
  │        B3 actuators + board #2    │        │   T1 PC half (mapper -> TX mod,  │
  │        B4 sensors                 │        │      921600) needs NO gate ------+---> runnable today
  └───────────────────────────────────┘        └──────────────────────────────────┘
             |  B2 passed in full — the ONLY thing that permits considering motor power
             v
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │ BG-04  D8 bench bring-up   Phase 0,1,2,3,(3b),4,5,6,7,7b,8,9,(10),11,11a       │
  │        Phase 5 = THE GATE.  Phase 7 = motor = Phase C territory.               │
  └──────────────────────────────────────────────────────────────────────────────┘
             |                              |                         |
             v                              v                         v
  ┌────────────────────────┐   ┌────────────────────────┐  ┌──────────────────────────┐
  │ BG-05 coordinated flash│   │ BG-08 dim-light halo   │  │ BG-07 BT1 show-off       │
  │  board #2 then #1,     │   │  judgement, dim room   │  │  needs A2 + Phase B      │
  │  wire reconnected last │   │  AND daylight          │  │  AND owner opens BT1     │
  └────────────────────────┘   └────────────────────────┘  │  AND the SP3T in hand    │
             |                              |               └──────────────────────────┘
             |                              |                         |
             +--------------+---------------+-------------------------+
                            v
                   D8 Phase 11a  DELIVERY HAND-OFF
                   ELF spot-check must print 0  ->  ship plain esp32dev  (OD-2 default)
                   ship esp32dev_btshowoff ONLY if BG-07 PASSED before handover
```

## The cards

| # | Card | Source of authority | Gate token | Needs power? |
|---|---|---|---|---|
| **BG-01** | [A2 staged no-power gates](BG-01_a2_staged_no_power.md) | `w17-control-fw/project-review/13_phase_a_a2_no_power_checklist.md` | SF…S8b | **No** — multimeter only |
| **BG-02** | [A2 closure](BG-02_a2_closure.md) | same file §12 | `A2-CLOSED` | No — review + attestation |
| **BG-03** | [Phase B first power](BG-03_phase_b_first_power.md) | `w17-control-fw/docs/PHASE_B_FIRST_POWER.md` | B1…B4 | **Yes**, logic only |
| **BG-04** | [D8 bench bring-up](BG-04_d8_bench_bringup.md) | `w17-control-fw/docs/D8_BENCH_BRINGUP.md` | D8-P0…P11a | **Yes** |
| **BG-05** | [Coordinated two-board flash](BG-05_coordinated_flash.md) | `w17-control-fw/docs/COORDINATED_FLASH.md` | `COORD-FLASH` | **Yes** |
| **BG-06** | [CRSF on the wire](BG-06_crsf_on_the_wire.md) | *(new — no prior runbook)*; `CrsfFrame.hpp`, `configs/README.md` | — | **T1 no · T2 yes** |
| **BG-07** | [BT1 show-off bench gate](BG-07_bt1_show_off.md) | `w17-control-fw/docs/BT1_BENCH_GATE.md` | `BT1` | **Yes** + owner opens BT1 |
| **BG-08** | [Dim-light halo judgement](BG-08_dim_light_halo.md) | `learning-manual/open_questions.md` #55; `w17-soundlight-fw/lib/lights` | — | **Yes** (board #2 + strip) |

Every card carries the same thirteen headings, in the same order: **Prerequisites · Required
equipment · Topology (ASCII) · Exact procedure · Exact commands · Expected evidence · PASS/FAIL
criteria · Stop conditions · Rollback · Outputs to save · Downstream unlocked by PASS · BENCH-TBD
residue · Evidence label at card creation.**

## Prerequisites and what each PASS unlocks

| Card | Prerequisites | Unlocked by PASS |
|---|---|---|
| BG-01 | OW1 + OW2 closed; parts on hand; build order = gate order | the **record** BG-02 reviews. Nothing else. |
| BG-02 | BG-01 complete; reviewer ≠ measurer | **`A2-CLOSED`** — a precondition of, never a grant of, `PHASE-B-OPEN` |
| BG-03 | `A2-CLOSED` **and** `PHASE-B-OPEN`; observer; wheels off ground; motor leads off; RP1 on "No Pulses" | B2 in full is what makes motor power *considerable*; BG-04, BG-05, BG-06-T2 become reachable |
| BG-04 | BG-03, especially **B2** | D8 stage 6 done; Phase 11a → shippable as `esp32dev` |
| BG-05 | `A2-CLOSED` + `PHASE-B-OPEN`; copy check run **first** to learn whether this is even a coordinated-flash situation | **`COORD-FLASH`**; D8 Phase 9 closes |
| BG-06 | **T1: none** (PC + TX module only). T2: full Phase B rules | closes the standing "no frame has ever been observed leaving the mapper" finding; frame-level evidence for B1.1 / D8 Phase 2 |
| BG-07 | `A2-CLOSED` + `PHASE-B-OPEN` + **owner opens BT1** + SP3T wired + a genuine pad | **`BT1`**; makes the `SHIP-IMAGE` upgrade path available under OD-2 |
| BG-08 | `A2-CLOSED` + `PHASE-B-OPEN`; A2 gate **S5** passed; strip behind its shipped diffuser | closes the dim-light halo gate and soundlight open question **#55** |

## What can be done **today**, with no gate at all

- **BG-06 step 1** — the sniffer's own proof: `test_crsf_sniff.py` (21/21, exit 0) and
  `crsf_xcheck_cpp.sh` (300 vectors against the firmware's own `CrsfParser.cpp`, 0 mismatches).
  Both are host-only and already run.
- **BG-06 T1** — the PC→TX-module tap. No car, no battery, no firmware, no A2. It is the half of
  the standing finding that has never needed a gate.
- **BG-07 item 9** — `pio run -e esp32dev_btshowoff` for the size report (a build, not a flash), and
  the ELF quarantine spot-check.
- **BG-08 step 1** — reading the as-compiled palette and computing its rendered duties.
- **BG-01's OW1 and OW2** — calipers and a silkscreen. Both are OWED and both gate SF.

## Tools

| Tool | What it does | Hardware needed to *write* it | Hardware needed to *run* it |
|---|---|---|---|
| [`tools/crsf_sniff.py`](tools/crsf_sniff.py) | passive CRSF decoder; live tap or offline replay; **no transmit path** | none | none for `--file`; a serial adapter for `--port` |
| [`tools/test_crsf_sniff.py`](tools/test_crsf_sniff.py) | 21 synthetic-frame tests | none | none |
| [`tools/crsf_xcheck_cpp.sh`](tools/crsf_xcheck_cpp.sh) | 300 random vectors vs the firmware's `CrsfParser.cpp` | none | none (a C++ compiler) |
| [`tools/bench_capture.sh`](tools/bench_capture.sh) | evidence folder + env/HEAD stamp + read-only timestamped serial capture + sha256 manifest | none | `--no-serial` needs none; the serial half is **Phase B** |
| [`tools/pdb_continuity_sheet.md`](tools/pdb_continuity_sheet.md) | no-power multimeter worksheet using A2's own row IDs | none | a multimeter |
| [`tools/first_power_current_limits.md`](tools/first_power_current_limits.md) | what the documents fix, and the **13 thresholds that are missing** | none | — |

## Evidence

All evidence lands under `bench-gates/evidence/<GATE-ID>/<UTC-stamp>/`, created by
`bench_capture.sh`. See [`evidence/README.md`](evidence/README.md) for the convention and for what
makes a capture citable.

## The rules that outrank every card here

1. **Nothing is flashed, powered or connected** until A2 is closed and Phase B is approved — and
   BT1 additionally needs the owner to open it.
2. **No unattended powering or flashing.** An observer is a precondition, not a courtesy.
3. **Wheels off the ground; ESC motor leads disconnected** through all of Phase B.
4. **A procedure existing is not a PASS.** Never promote a simulation, a native test or a static
   analysis to physical verification.
5. **Never invent a threshold.** Where the documents fix no number, these cards say
   **"THRESHOLD MISSING — owner/bench decides"** and the first real measurement is what sets it.
