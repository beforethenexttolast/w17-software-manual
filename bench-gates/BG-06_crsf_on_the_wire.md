# BG-06 — CRSF on the wire

*The open bench gate named in `CURRENT_STATUS.md`'s top entry and
`closeout/vision-alignment-2026-09-04.md`:264 as* **"CRSF on the wire — not one frame has ever
been observed leaving the mapper."** *No runbook owns it today; this card is that runbook.*

> **Two independent wires carry CRSF in this project, and only one of them is car-side.** They fail
> differently, they need different equipment, and they can be proven on different days:
>
> | Tap | Wire | Baud | Gate that owns it | Needs the car? |
> |---|---|---|---|---|
> | **T1** | PC (`elrs-joystick-control` / mapper) → ELRS TX module, over USB serial | **921600** | this card, **PC half** | **No** — TX module + PC only |
> | **T2** | RP1 receiver → ESP32 #1 GPIO16 | **420000** | this card, **car half**; also Phase B **B1.1** and D8 Phase 2 | **Yes** — Phase B |
>
> T1's PC half is the one nothing has ever observed. It is **independent of A2 and Phase B**: no
> car, no battery, no firmware. The ground-track worker owns the mapper's own behaviour; this card
> owns the **wire-level proof** and the tool that produces it.

## Prerequisites

**T1 (PC → TX module) — no car-side gate at all:**

1. The ELRS TX module and a PC running the mapper (`w17-mapper`, `elrs-joystick-control`).
2. A saved profile whose `tx.port` names the port the link will actually run on. **A link started
   on a port the profile does not name resolves no channels and writes no channel frame at all** —
   the process runs, the ground station says "running", and the car does not move
   (`w17-mapper/configs/README.md`:23-30). That failure mode is exactly what this tap exists to
   catch.
3. Both profile placeholders filled — `REPLACE-WITH-DS4-ID` and `REPLACE-WITH-COM-PORT`
   (`w17-mapper/configs/w17-ds4.json`). An unfilled placeholder is refused before the RPC
   (`w17-mapper/pkg/config/placeholders.go`).
4. A **passive tap** on the TX serial line, or a second serial adapter on the same physical line —
   see the topology. **This is Windows-side work in practice**; the mapper's Windows behaviour is
   `[win-TBD]` until the VM validation session (`W17_CURRENT_STATE.md` §6).

**T2 (RP1 → ESP32 #1) — full Phase B rules:**

5. `A2-CLOSED` **and** `PHASE-B-OPEN` recorded (BG-02, then the owner).
6. RP1 bound to the TX at the same ELRS major.minor and the same bind phrase, with failsafe mode
   **"No Pulses"** (`D8_BENCH_BRINGUP.md`:61-64).
7. Wheels off the ground, observer present, ESC motor leads disconnected, actuators disconnected
   (this is a B1-class row: `PHASE_B_FIRST_POWER.md`:33-34).

## Required equipment

- **A USB-serial adapter to use as the tap** — RX and GND only. It must be capable of the tap's
  baud: **420000** for T2, **921600** for T1. A generic CP210x/CH340 at 420000 is not guaranteed;
  an FT232-class bridge is the safer choice. **Confirm the adapter can actually do the rate before
  concluding "no frames".**
- `bench-gates/tools/crsf_sniff.py` (pure stdlib for replay; `pyserial` only for `--port`).
- `python3 -m pip install pyserial` if tapping live.
- An oscilloscope or logic analyser is **optional here** but is the fallback when the sniffer sees
  nothing: it distinguishes "no bytes at all" from "bytes at the wrong rate".

## Topology (ASCII)

```
  T1 — PC half (NO car, NO battery, NO firmware; independent of A2/Phase B)
  -------------------------------------------------------------------------
     elrs-joystick-control (mapper)
            |  USB serial, 921600 8N1
            v
       [ TX module ]
            ^
            |  tap: adapter RX  <---- the SAME line (Y-splice or a passive T)
            |  tap: adapter GND <---- common ground
            |  adapter TX       ----  NOT CONNECTED.  Ever.
       [ USB-serial adapter ] -> Mac/PC -> crsf_sniff.py --baud 921600


  T2 — car half (Phase B: A2 CLOSED + Phase B APPROVED)
  -----------------------------------------------------
       [ RP1 receiver ] --- RP1_TX ---+--------> GPIO16 (ESP32 #1, CRSF RX)
                                      |
                                      +--> tap adapter RX
                                           tap adapter GND -> star ground
                                           tap adapter TX  -> NOT CONNECTED
       -> crsf_sniff.py --baud 420000


  THE ONE WIRING RULE:  the tap's TX pin is never connected to anything.
  A tap that can transmit is a second talker on a half-duplex-ish line, and on
  T2 that talker sits on the input the failsafe trusts. crsf_sniff.py has no
  transmit path by construction (test_crsf_sniff.py::test_no_transmit_path_exists),
  but the WIRE is the real guarantee — leave TX unconnected.
```

## Exact procedure (numbered)

1. **Prove the tool before you trust its silence.** Run the offline self-tests and the
   cross-check against the firmware's own decoder. Both must exit `0`. A sniffer you have not
   tested cannot distinguish "no frames on the wire" from "my decoder is broken".
2. **Prove the adapter can do the baud.** Loop the adapter's TX to its own RX, send a known byte
   pattern at the target rate, and confirm it comes back. **Do this with the adapter off the car's
   wire.** If it fails, the adapter is the finding, not the link.
3. **T1 — wire the tap** on the PC→TX-module line: adapter **RX** to the line, adapter **GND** to
   common, adapter **TX unconnected**.
4. **T1 — start the mapper** on its profile and let the link come up on the profile's own `tx.port`
   (`selfStartLink`, `w17-mapper/pkg/client/grpc_client.go`; owner decision OD-5(a),
   `configs/README.md`:14-19).
5. **T1 — capture 30 s** with the sniffer at **921600**, saving the raw bytes. Move a gamepad axis
   during the capture so channel values are *seen to change*, not merely to exist.
6. **T1 — read the summary**: frames decoded, CRC failures, types seen, and whether channel values
   actually tracked the stick.
7. **T2 — only inside Phase B.** Wire the same style of tap on RP1_TX → GPIO16, adapter TX
   unconnected, GND to the star node.
8. **T2 — capture 30 s at 420000** with the TX on, again moving sticks, then **turn the TX off
   mid-capture** and keep capturing for a further 10 s.
9. **T2 — read the summary and the tail of the log**: the LQ=0 `LINK_STATISTICS` burst on
   disconnect, and then silence (because the RP1's failsafe mode is **"No Pulses"** — if RC frames
   keep arriving after the TX is off, the RX is misconfigured to "Set Position", which defeats the
   firmware's frame-timeout failsafe entirely, `D8_BENCH_BRINGUP.md`:63-64).
10. **Reconcile both taps with the firmware's own view**: whatever the sniffer decodes on T2 is what
    the board sees. If the sniffer decodes clean frames and the firmware reports none, the fault is
    between GPIO16 and the parser, not on the wire — and that is a genuinely useful narrowing.
11. Record the counts. **A gate that says "frames were seen" without a count is not evidence.**

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# 1. Prove the tool. Both must exit 0. Run this EVERY session — it is free.
python3 bench-gates/tools/test_crsf_sniff.py ; echo "unit tests exit: $?"
bench-gates/tools/crsf_xcheck_cpp.sh          ; echo "xcheck exit: $?"

# 1b. Prove it decodes a known-good stream (build one, replay it):
python3 - <<'PY'
import sys; sys.path.insert(0, "bench-gates/tools")
from crsf_sniff import build_frame, pack_channels, TYPE_RC_CHANNELS_PACKED
open("/tmp/w17_ref.bin","wb").write(build_frame(TYPE_RC_CHANNELS_PACKED, pack_channels([992]*16))*50)
PY
python3 bench-gates/tools/crsf_sniff.py --file /tmp/w17_ref.bin --quiet --summary

# 2. Evidence folder.
bench-gates/tools/bench_capture.sh BG-06 --no-serial --note "CRSF on the wire, tap T1/T2"

# 3. T1 — PC -> ELRS TX module, 921600 (no car, no Phase B gate):
python3 bench-gates/tools/crsf_sniff.py \
  --port /dev/tty.usbserial-TAP --baud 921600 --seconds 30 \
  --raw-out bench-gates/evidence/BG-06/<stamp>/T1_pc_to_tx.bin \
  --summary | tee bench-gates/evidence/BG-06/<stamp>/T1_summary.txt

# 4. T2 — RP1 -> ESP32 #1, 420000 (PHASE B ONLY):
python3 bench-gates/tools/crsf_sniff.py \
  --port /dev/tty.usbserial-TAP --baud 420000 --seconds 40 \
  --raw-out bench-gates/evidence/BG-06/<stamp>/T2_rp1_to_esp32.bin \
  --summary | tee bench-gates/evidence/BG-06/<stamp>/T2_summary.txt

# 5. Re-read any capture offline, as many times as you like, with no hardware:
python3 bench-gates/tools/crsf_sniff.py \
  --file bench-gates/evidence/BG-06/<stamp>/T2_rp1_to_esp32.bin --summary
python3 bench-gates/tools/crsf_sniff.py \
  --file bench-gates/evidence/BG-06/<stamp>/T2_rp1_to_esp32.bin --json | tail -40
```

## Expected evidence

- **The raw byte captures themselves** (`T1_*.bin`, `T2_*.bin`) — replayable forever, by anyone,
  with no hardware. This is the durable artefact; the summaries are derived from it.
- The two `--summary` JSON blobs, each carrying `frames_ok`, `frames_crc_fail`, `crc_fail_pct`,
  `resyncs`, `by_type`, and (live taps only) `rc_frame_rate_hz`.
- For T1: a note of the **gamepad axis moved** and the channel that changed, so "frames exist" is
  upgraded to "frames carry this PC's intent".
- For T2: the **LQ=0 `LINK_STATISTICS` burst** at TX-off and then **silence**.
- The tool-proof outputs from step 1 (both exit codes), in the same folder — they are what make the
  capture interpretable.
- `meta.txt`'s repo HEADs, naming the mapper/firmware commits the observation belongs to.

## PASS/FAIL criteria (objective numbers)

| Check | PASS | FAIL |
|---|---|---|
| Tool proof — unit tests | `test_crsf_sniff.py` exits **0** (**21/21**) | any failure ⇒ fix the tool before believing any capture |
| Tool proof — cross-check | `crsf_xcheck_cpp.sh` exits **0**, **300 vectors, 0 mismatches** | any mismatch ⇒ the decoder disagrees with the firmware; stop |
| Adapter loopback | the known pattern returns at the target baud | ⇒ the adapter cannot do this rate; the capture proves nothing |
| **T1 frames exist** | `frames_ok` **> 0**, with **`RC_CHANNELS_PACKED`** among `by_type` | `frames_ok == 0` ⇒ **the standing finding is confirmed, not resolved**: no frame has left the mapper |
| T1 intent | a moved axis changes the matching channel's raw value across captured frames | frames present but every channel static ⇒ the link resolved no channels (the `tx.port` mismatch) |
| T2 frames exist | `frames_ok` **> 0**, type **0x16** present | `frames_ok == 0` ⇒ check RP1 binding, baud, inversion before firmware (`PHASE_B_FIRST_POWER.md`:53-54) |
| T2 framing | sync **0xC8**, RC length byte **24**, on-wire frame **26 B**, CRC-8 poly **0xD5** over [type+payload] (`CrsfFrame.hpp`:9-12, :20, :51-52, :59-63) | any deviation ⇒ not CRSF as this firmware defines it |
| T2 channel scale | raw values inside **172 … 1811** (centre **992**); values outside **100 … 1900** decode as ABSENT by design (`CrsfFrame.hpp`:66-68, :85-86) | values pinned at 0 or 2047 ⇒ a sender not speaking the protocol |
| Link integrity | **`crc_fail_pct` ≈ 0** on a good bench link, and **`resyncs` low** | see the threshold note below |
| T2 link loss | LQ=0 `LINK_STATISTICS` burst, then **no RC frames at all** | RC frames continuing after TX-off ⇒ RX is on "Set Position"; **fix the RX, this defeats the failsafe** |

> **THRESHOLD MISSING — owner/bench decides:** *what CRC-failure rate is acceptable on a healthy
> bench link.* No document in this project states one. Zero is what a short bench tap should
> produce, but no tolerance has ever been set, and the first real capture is what should set it.
> Record the observed rate; do not adopt a number from anywhere else.
>
> **THRESHOLD MISSING — owner/bench decides:** *the expected RC frame rate at the chosen ELRS
> packet rate.* `rc_frame_rate_hz` will show it, but nothing in the documents fixes what it ought
> to be (the packet rate is a TX setting, and D8 Phase 2 asks you to *characterise* it, not to
> match a target — `D8_BENCH_BRINGUP.md`:67-70).

## Stop conditions

- **The tap's TX pin is connected to anything.** Stop and re-wire. On T2 that pin sits on the input
  the failsafe trusts.
- **T2: no frames at all** → do not start editing firmware. Check, in this order: RP1 binding, baud,
  inversion, then the adapter's own rate capability (`PHASE_B_FIRST_POWER.md`:53-54).
- **T2: RC frames continue after the TX is switched off** → hard stop on the *radio configuration*:
  the RP1 is on "Set Position", which defeats the frame-timeout failsafe. Fix the RX before any
  further Phase B row.
- **T1: frames exist but no channel ever changes** → the link resolved no channels. Check that
  `-tx-serial-port-name` (if passed at all) names the **same** port as the profile's `tx.port`;
  bring-up prints a warning when they disagree and **the warning is the only thing that notices**
  (`w17-mapper/configs/README.md`:23-30).
- **Any temptation to conclude "the wire is fine" from a capture taken with a decoder that failed
  its own tests.** The tool proof is step 1 for exactly this reason.

## Rollback

- **Nothing to roll back on T1**: it is a passive read. Unplug the adapter.
- **T2**: power down at the master switch / XT60 split, then remove the tap. The tap adds no
  persistent state to the harness — but a tap left spliced into the RP1 line is a **build
  deviation** and must be removed and re-checked against A2's S4 rows (C1/C2, K1–K4) before the car
  is considered assembled again.
- **If the capture is bad but the wire is fine** (wrong baud, adapter dropouts): nothing needs
  undoing; re-capture. The raw `.bin` is cheap and re-decodable offline.

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-06/<UTC-stamp>/
  meta.txt   MANIFEST.txt
  tool_proof_unit_tests.txt      # test_crsf_sniff.py output + exit code
  tool_proof_xcheck.txt          # crsf_xcheck_cpp.sh output + exit code
  adapter_loopback.txt           # proof the adapter does 420000 / 921600
  T1_pc_to_tx.bin                # RAW BYTES — the durable artefact
  T1_summary.txt                 # crsf_sniff.py --summary
  T1_intent.md                   # which axis moved, which channel changed
  T2_rp1_to_esp32.bin
  T2_summary.txt
  T2_linkloss_tail.txt           # the LQ=0 burst, then silence
  wiring_photo_tap.jpg           # shows the tap TX pin UNCONNECTED
  notes.md
```

## Downstream unlocked by PASS

- **The standing finding closes**: "not one frame has ever been observed leaving the mapper"
  (`closeout/vision-alignment-2026-09-04.md`:264) becomes a dated observation with a byte capture
  behind it — **T1 alone does that, with no car and no Phase B**.
- **T2 PASS** is the frame-level evidence for **Phase B B1.1** and **D8 Phase 2**, and it de-risks
  every later row that assumes "the link works".
- Together they separate two failure classes that otherwise look identical on the car: *nothing is
  transmitting* versus *the board is not decoding*.
- Feeds the race-day link-window question (the 5 s wait for the mapper's positive link claim,
  `[bench-TBD]` — `CURRENT_STATUS.md`) with a real measurement of when frames actually start.

## BENCH-TBD residue

- **The acceptable CRC-failure rate and the expected frame rate are both unset** (see the two
  THRESHOLD MISSING notes above).
- **The mapper's Windows behaviour is `[win-TBD]`** until the VM validation session; a T1 pass on
  one PC is not a pass on the giftee's PC (`W17_CURRENT_STATE.md` §6).
- **Telemetry in the return direction is untested**: whether ELRS relays each frame type the
  firmware emits (battery 0x08, GPS 0x02, FLIGHTMODE 0x21, LINK_STATISTICS 0x14) with the `0xC8`
  address is plan item **CG3**, ground-side, `[bench-TBD]`
  (`11_hardware_validation_plan.md`:116).
- **The adapter's ability to sustain 420000/921600 is itself unproven** on this owner's hardware —
  step 2 exists because a failed capture at an unsupported rate is indistinguishable from a dead
  wire.
- The **channel plausibility band 100…1900** is explicitly **PROVISIONAL** in the firmware and asks
  to be confirmed against the real TX during Phase B endpoint calibration (`CrsfFrame.hpp`:80-84).
  A capture here is the raw material for that.

## Evidence label at card creation

**NOT-EXECUTED** for both taps. No CRSF frame has ever been observed on either wire in this
project. The **tooling**, by contrast, is **VERIFIED** offline on this Mac: `test_crsf_sniff.py`
21/21 exit 0, and `crsf_xcheck_cpp.sh` 300/300 vectors matching the firmware's own
`CrsfParser.cpp`, 0 mismatches — that is a statement about the decoder, **not** about any wire.
