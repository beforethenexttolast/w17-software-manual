# BG-05 — Coordinated two-board flash (link2 v2 lockstep)

*Card for `w17-control-fw/docs/COORDINATED_FLASH.md` (cited as **CF**). It is the detail behind
D8 Phase 9 and Phase 11a; **it does not open the gate on its own** (CF:3-6).*

## Prerequisites

1. **`A2-CLOSED` and `PHASE-B-OPEN`** recorded. Flashing is Phase B work (CF:3-6; D8 Phase -1).
2. **You have established that this actually IS a coordinated-flash situation.** It matters **only
   when the two repos' `lib/link2` trees have drifted** — a protocol change on one side and not the
   other. If both repos are at their current `main` with the copy check green, a normal
   one-at-a-time re-flash is *not* a coordinated flash and D8 Phase 9's plain steps cover it
   (CF:37-44). **Run the copy check first to find out which situation you are in.**
3. Both checkouts at the commits you intend to flash from — `w17-control-fw` and
   `w17-soundlight-fw`, each at its target commit (CF:82-87).
4. Observer present; wheels off the ground; battery pullable — the standing Phase B rules.

## Required equipment

- Both boards, both USB cables, a way to power each independently of the other.
- PlatformIO (`pio`) for both projects.
- `tools/link2_copy_check.sh` in `w17-control-fw` — the drift guard.
- A serial monitor at 115200 for board #2's `Link2Monitor` reports.
- The ability to **physically disconnect the link2 wire** (or power board #1 off) while board #2 is
  flashed — that is the whole point of the order (CF:73-80).

## Topology (ASCII)

```
   BOARD #1  w17-control-fw                        BOARD #2  w17-soundlight-fw
   owns the protocol (lib/link2/)                  carries a VERBATIM COPY of the shared subset
        |                                                        ^
        |  link2, ONE-WAY, TX only                               |
        |  GPIO25  ------------------------------------------->  GPIO16
        |  115200 8N1, common ground                             |
        |                                                        |
        |  board #1 has NO way to observe board #2 at all        |
        |                                                        |
   frame: [start 0xA5][length=14][payload 14 B][CRC-8 poly 0xD5] = 17 B total
          (Link2Frame.hpp:65-68; CRC over [length + payload], :10)
                    ^
                    +-- board #2 checks the LENGTH BYTE BEFORE the version byte.
                        A version bump  -> BadVersion  ("well-formed, just newer")
                        A length change -> FrameInvalid/BadLength, indistinguishable
                                           from a broken UART, EVERY frame, forever.
                        Board #2's own failsafe then engages within 500 ms:
                        engine to idle/off, hazard blink.

   FLASH ORDER:   board #2 FIRST (UART disconnected or board #1 off)
                  board #1 SECOND
                  reconnect / power the link2 wire ONLY after both are confirmed matching
```

## Exact procedure (numbered)

1. **Confirm what is on both checkouts** — `lib/link2/` and `docs/link2_protocol.md` — then run the
   copy check from the control-fw side. **Exit `0` with "identical across both repos" for the four
   code files** (`Link2Frame.hpp`, `Link2Codec.hpp`, `Link2Codec.cpp`, `library.json`) is the pass
   condition. A **reported (non-fatal) doc difference is expected and fine** (CF:82-87).
2. **Board #2 first**, with the UART disconnected or board #1 powered off:
   `pio run -e esp32dev -t upload` in `w17-soundlight-fw` — its **only** delivery env; no
   tuning/console variant exists on that board by design (CF:88-90).
3. **Board #1 second**: `pio run -e esp32dev_tuning -t upload` in `w17-control-fw` for bench work
   (Phase 11a covers the eventual plain-`esp32dev` delivery re-flash) (CF:91-93).
4. **Reconnect / power up the link2 wire** (GPIO25 → GPIO16, common ground, 115200 8N1) **only
   after both boards are running the confirmed-matching firmware** (CF:94-95).
5. **NVS check on board #1 only** — board #2 carries no persisted tuning (CF:97-98). If you are
   moving board #1 across the **v1 → v2** boundary, budget time to **recalibrate and `save`**: the
   version byte fails, the whole blob is discarded, and the board boots on **compiled defaults for
   every field — including `steer` trim/endpoints and `batt.ppt`**, not only the new v2 fields
   (CF:113-118).
6. **Post-flash verification, in order** (CF:137-149):
   a. `tools/link2_copy_check.sh` still exit-`0` on the two checkouts you actually flashed.
   b. D8 Phase 9's bench checks: `FrameReady` on board #2 (not `BadVersion`/`FrameInvalid`); engine
      sound + WS2812 respond to board #1 state; cutting the UART mid-run drops board #2 to its own
      failsafe **within 500 ms**.
   c. If board #1 crossed a version boundary: re-run D8 Phase 11a **steps 1–6 in full** — do not
      assume the old calibration survived; confirm it with `get`/`status` read-back.
   d. Re-run D8 Phase 5's safe-state checks on whichever board #1 build you actually ship next —
      **flashing is exactly the kind of change the re-arm invariant exists to catch a regression in**.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

# STOP if any line says "Phase B stays BLOCKED", or no dated "PHASE-B-OPEN" line
# appears: the rest of this card is not runnable.
grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN" CURRENT_STATUS.md | head
bench-gates/tools/bench_capture.sh BG-05 --no-serial --note "coordinated two-board flash"

# 1. Which situation is this? (add --sibling if soundlight is not at ../w17-soundlight-fw)
cd w17-control-fw
tools/link2_copy_check.sh
echo "copy check exit: $?"          # 0 with "identical across both repos" for the 4 code files

# Record exactly what you are about to flash:
git -C . rev-parse HEAD
git -C ../w17-soundlight-fw rev-parse HEAD

# 2. BOARD #2 FIRST — link2 wire disconnected, or board #1 powered off:
cd ../w17-soundlight-fw && pio run -e esp32dev -t upload

# 3. BOARD #1 SECOND:
cd ../w17-control-fw && pio run -e esp32dev_tuning -t upload

# 4. Only now reconnect the link2 wire, then verify:
cd .. && bench-gates/tools/bench_capture.sh BG-05 \
  --port /dev/tty.usbserial-BOARD2 --baud 115200 --seconds 300 \
  --note "post-flash: Link2Monitor FrameReady + mid-run UART cut"

# 6a. Belt and suspenders, on the checkouts you actually flashed:
cd w17-control-fw && tools/link2_copy_check.sh; echo "exit: $?"
```

## Expected evidence

- The **two commit SHAs** you flashed from, recorded before the flash (`meta.txt` captures them
  automatically).
- `link2_copy_check.sh` **exit code and output**, before and after.
- Board #2's console showing **`FrameReady`** in steady state, with a decoded frame matching sender
  intent (throttle %, brake bit, ERS-deploy bit, gear, driveMode — D8 B3.4).
- A capture of the **mid-run UART cut** and board #2 reaching hazard, with the elapsed time.
- If a version boundary was crossed: the **re-read `get` values** proving the calibration was
  redone, not assumed.
- The Phase 5 re-run result on whichever build was flashed last.

## PASS/FAIL criteria (objective numbers)

| Check | PASS | FAIL |
|---|---|---|
| Copy check (four code files) | exit **`0`**, "identical across both repos" | any code-file difference ⇒ **do not flash**; resolve the drift first |
| Copy check (doc tier) | a **reported, non-fatal** diff is acceptable | treating a reported doc diff as a blocker (it is not), or ignoring a *code* diff (it is) |
| Flash order | board **#2 first**, board **#1 second**, wire reconnected **last** | wire live between two boards not yet confirmed to agree |
| link2 frame geometry | payload **14 B**, frame **17 B** (`Link2Frame.hpp:67-68`; start 0xA5 at `:65`, version 2 at `:66`), CRC-8 poly **0xD5** over [length + payload] (`Link2Frame.hpp:10`) | a length mismatch — **every** frame becomes `FrameInvalid`/`BadLength` |
| Board #2 steady state | **`FrameReady`** | `BadVersion` (version drift) or `FrameInvalid` (length drift) |
| Mid-run UART cut | board #2 in its own failsafe **within 500 ms** — engine idle/off, hazard blink | slower, or no failsafe |
| NVS round-trip (same version) | every key in the list reads back identical after the flash | any key reverted ⇒ the blob was discarded; recalibrate |
| Keys that must survive | `steer.min`, `steer.max`, `steer.center`, `steer.trim`, `batt.ppt`, `gear.<N>.max`/`gear.<N>.expo` **for each gear**, `gimbal.decay`, `sound.profile`, `sound.volume` (CF:126-130) | any missing from the record |

**The failure direction is safe, and that is not the same as acceptable**: a mismatched pair does
not show a wrong reading — it shows a permanent "link lost" within half a second, every time
(CF:30-35). It is still the wrong car to hand over.

## Stop conditions

- **A code-file difference in the copy check** → stop. Resolve which side is right *before*
  flashing anything. A protocol change belongs on both sides or neither.
- **`BadVersion` or `FrameInvalid` after the flash** → do not proceed to on-car mounting with a
  version mismatch live (`w17-parts-to-gift-master-sequence.md`:236-237).
- **The link2 wire is live between two boards you have not confirmed agree** → disconnect it. The
  order rule exists only to avoid exactly this window (CF:73-80).
- **A calibration read-back that does not match after a version bump** → stop and redo D8 Phase 11a
  steps 1–6; do not ship on an assumed-surviving blob.
- **Never edit `w17-soundlight-fw` from a control-fw session** (workspace `CLAUDE.md`). The known
  doc drift below is routed, not fixed in place.

## Rollback

- **Board #1**: re-flash an older image, then either accept the stored NVS blob (if its version byte
  matches what that firmware expects) or `reset` + `save` to force compiled defaults and
  recalibrate. **There is no separate "undo" for a bad flash** beyond flashing a known-good image —
  the NVS guard chain's job is only to keep a *version mismatch* from becoming a *silent partial*
  mismatch (CF:153-158).
- **Board #2**: no persisted state at all; re-flashing an older `esp32dev` image is the entire
  rollback (CF:159-160).
- **Interrupted mid-procedure / wrong image on one side**: the live wire is harmless by design —
  board #2 either decodes normally or sits in its own failsafe. **Reconnect nothing** until the copy
  check confirms the two checkouts you intend to flash from agree, then redo both flashes in order
  (CF:161-165).

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-05/<UTC-stamp>/
  meta.txt                      # both repo HEADs, automatically
  MANIFEST.txt
  copy_check_before.txt         # command, output, exit code
  copy_check_after.txt
  flash_log_board2.txt          # pio output, soundlight esp32dev
  flash_log_board1.txt          # pio output, control-fw esp32dev_tuning
  link2_frameready.log          # board #2 console, steady state
  link2_frame_decode.md         # decoded frame vs sender intent (D8 B3.4)
  link2_cut_midrun.log          # the cut, with the elapsed time to hazard
  nvs_readback.txt              # every key from the "must survive" list
  phase5_rerun.md               # safe-state checks on the build actually flashed
```

## Downstream unlocked by PASS

- **`COORD-FLASH`** (master sequence stage 7, :221-237), whose evidence of done is exactly
  `FrameReady` plus a live decoded frame matching sender intent.
- D8 **Phase 9** closes; **Phase 11 / 11a** (on the car, delivery hand-off) become reachable.
- A confirmed-matching pair is the precondition for **BG-04's Phase 11a** ELF spot-check and ship
  decision.

## BENCH-TBD residue

- **The whole NVS migration is hypothetical.** "Merged" is a source-code fact only: **no board has
  ever been flashed with either blob version**, so v1→v2 behaviour is `[bench-TBD]` until the first
  real flash exercises it (CF:104-107). Phase 11a step 6 is what turns it into evidence (CF:119-125).
- **OWED — cross-repo doc re-sync.** As of CF's own 2026-09-03 revision, `docs/link2_protocol.md`
  differs **normatively** between the two repos: commit `02359a4` added a BT_SOLO paragraph to the
  control-fw copy's State matrix (~:198-209) that `w17-soundlight-fw`'s copy does not carry. The
  doc tier is *reported, never fatal*, so the copy check will not stop you — but this is **a real,
  known, one-paragraph gap**, not the "nothing to do" case the script's default message describes.
  It must be routed to a **soundlight-fw session**; never edit that repo from a control-fw session
  (CF:60-69).
- **Board #2's compile-time idle/max-RPM engine-sound constants** are a separate owner-requested
  tuning knob on that repo — a source change plus its own re-flash. They are **not** carried by
  board #1's NVS blob and nothing in this procedure moves them (CF:131-135).

## Evidence label at card creation

**NOT-EXECUTED.** Flashing is Phase B; A2 is NOT-EXECUTED and Phase B is BLOCKED (CF:3-6). No board
has ever been flashed with this firmware; the link2 wire has never carried a frame between two real
boards.
