# G-02 — Phone video: real glass-to-glass latency (and the phone-vs-laptop delta)

> Measures how far behind reality the giftee's cockpit view is, on the **phone** and on
> the **laptop**, in the same run, from the same event. Video only. This gate touches no
> control path: the phone is a viewer, it holds one socket for telemetry in
> (`UDP *:5601`), and video lives entirely inside WebKit's networking process
> (`iPhone_rc/docs/SIMULATOR_TESTING.md:386-388`).
>
> **Evidence label: NOT-EXECUTED.**

---

## Prerequisites

- **Phase B / CB5.** This is explicitly the bench-and-device slice:
  `iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:674-680` — *"Slice 5 — bench and device
  proof (Phase-B / CB5 gated, NOT part of the design branch)"*. CB5 is
  `BLOCKED_HARDWARE` (`CURRENT_STATUS.md:1341`), and A2 is NOT-EXECUTED ⇒ Phase B
  BLOCKED (`W17_CURRENT_STATE.md:61`). **Do not run this card before that changes.**
- A camera that is powered and streaming means the car (or at least the camera + its
  link) is powered. That is Phase-B class on its own.
- The ground station installed and able to serve its WHEP endpoint
  (`w17-ground-station/main/main.js:65` — `http://127.0.0.1:8889/cam/whep`;
  `w17-ground-station/mediamtx/mediamtx.yml:21` — `webrtcAddress: :8889`).
- The phone app pointed at the ground station (Settings → *Windows ground station* Host
  IP; *Video (camera picture)* → WHEP port **8889**, path **cam** —
  `iPhone_rc/docs/SIMULATOR_TESTING.md:244-246`).
- Decide, and **write down**, which video profile is under test. SHOWPIECE sets
  `jitterBufferTargetMs = 300` while DRIVE leaves it untouched
  (`w17-ground-station/docs/video_profiles.md:48`) — a 300 ms buffer is a deliberate
  latency knob, so a number measured under SHOWPIECE is not comparable to one measured
  under DRIVE. Measure **DRIVE first**.

## Required equipment

| Item | Why | Notes |
|---|---|---|
| A second phone or camera that films at **240 fps** | the measurement instrument | 240 fps ⇒ 4.167 ms per frame ⇒ ±4.17 ms random bound. A 120 fps device doubles that to ±8.33 ms; a 60 fps device (±16.7 ms) is too coarse for a 30 ms delta and must not be used for the delta question |
| A monitor for the **source** page | what the FPV camera looks at | its refresh rate must be recorded; it is a systematic bias term |
| The OpenIPC/APFPV camera, powered, on its link | the real path | **Phase B** |
| The ground-station laptop | serves WHEP to both viewers | |
| The iPhone, in the holder/EMV400 if that is the shipping configuration | the display under test | |
| A tripod or clamp | both screens must be in one frame, in focus, unmoving | |
| `bench-gates/tools/latency_rig.html` | the flash + counter source | offline, no network |
| `bench-gates/tools/latency_from_frames.py` | frame indices → latency | python3, stdlib only |

## Topology

```
   [ latency_rig.html on a monitor ]        <-- SOURCE: full-screen flash + ms counter
             │  photons                          + 12-bit binary strip (flash id)
             ▼
   OpenIPC / APFPV camera  ──5.8 GHz / Wi-Fi──►  laptop: mediamtx  ──WHEP/WebRTC──┬──► laptop <video>
                                                  (RTSP in, :8889 WebRTC out)      │
                                                                                   └──► iPhone WKWebView
                                                                                        (WHEP pull, OD-16)

   [ 240 fps camera on a tripod ] ── films the SOURCE monitor AND the display under test
                                     in ONE frame, both legible
```

Both viewers pull the **same** stream from the laptop — the phone's picture is
structurally *behind* the laptop's because it travels camera → laptop → phone
(`iPhone_rc/README.md:480`, `iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:196-200`). That is why the
delta, not the absolute, is the number this gate exists to produce.

## Exact procedure

1. **Record the rig.** Write down: capture fps, source monitor refresh Hz, phone display
   refresh Hz, camera fps/resolution/bitrate/GOP, video profile (DRIVE or SHOWPIECE),
   distance camera↔monitor, Wi-Fi channel, and the GS + iPhone build commits. Anything
   not recorded makes the number unrepeatable and therefore not evidence.
2. **Open the rig page** on the source monitor, full screen, `?period=2000`. Confirm the
   flash edges are crisp and the millisecond counter is legible.
3. **Aim the FPV camera** at the source monitor. Fill the frame with the flash area;
   the counter and strip must both survive the H.264 encode legibly on the far end.
   Check on the **laptop** viewer before involving the phone.
4. **Bring both viewers up.** Laptop cockpit view live; phone app live. Confirm the
   phone reports presented frames, not merely decoded ones — the app logs
   `frames src=rvfc total=… dropped=0 advanced=true`
   (`iPhone_rc/docs/SIMULATOR_TESTING.md:259-277`). `getVideoPlaybackQuality()
   .totalVideoFrames` returns **0 forever** against a `MediaStream` in `WKWebView`, so a
   harness reading that API measures nothing (`iPhone_rc/docs/SIMULATOR_TESTING.md:272-277`).
5. **Frame the shot.** Position the 240 fps camera so the source monitor and the display
   under test are both sharp in one frame. Lock focus and exposure — autofocus hunting
   mid-run invalidates frame indices.
6. **Soak first, measure second.** Let the stream run ≥ 60 s before the first sample, so
   the WebRTC jitter buffer has settled. A number taken in the first seconds after
   `event playing → phase live` is a start-up transient, not steady state.
7. **Capture ≥ 25 flash edges** (≥ 50 s at `period=2000`). 25, not 10: the script refuses
   to call p95 meaningful below `--min-samples` (default 20).
8. **Read the frame indices.** Step the capture frame by frame. For each edge, record the
   first frame on which the SOURCE goes dark→light, and the first frame on which the
   DISPLAY UNDER TEST does. Record them as `n_source,n_display` rows in a CSV.
   Cross-check every fifth sample against the on-screen counter: source counter reading
   minus display counter reading on the *same* capture frame should agree with the frame
   arithmetic to within one frame. If it does not, the two indices are not the same
   flash edge — re-read them.
9. **Run the script** for the phone, then for the laptop, then compute the delta.
10. **Repeat for the second profile** (SHOWPIECE) and, if the owner wants it, at the edge
    of hotspot range. Label each run.
11. **Record thermal and battery** on the phone at the end of a ≥ 5-minute soak, and the
    laptop's CPU with two WebRTC peers — both are named CB5 questions
    (`iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:681-687`).

## Exact commands

Source page (any machine driving the monitor; no network needed):

```sh
open "file:///Users/vitaliykhomenko/Documents/projects/bench-gates/tools/latency_rig.html?period=2000"
# keys: F = force a flash edge now, H = hide the footer
```

Reduce the frame indices. Two runs, then the delta:

```sh
cd /Users/vitaliykhomenko/Documents/projects

# The three rates below are RIG FACTS from step 1, not defaults. Substitute what you
# MEASURED on this rig -- the tool cannot tell a guess from a measurement, and criterion 5
# reads as satisfied the moment all three are supplied, whatever they say. If you did not
# measure one, OMIT the flag: the tool then prints `systematic bias NOT ACCOUNTED`, which
# is an honest gap; a plausible-looking 60/60/30 is not. (A non-positive value is now a
# usage error, exit 2, rather than a silently inverted interval.)

python3 bench-gates/tools/latency_from_frames.py \
  --fps 240 \
  --pairs-file bench-gates/evidence/G-02/phone_drive_pairs.csv \
  --label "phone, DRIVE profile, 5 m, 2026-__-__" \
  --src-refresh-hz <MEASURED> --dst-refresh-hz <MEASURED> --camera-fps <MEASURED> \
  --json bench-gates/evidence/G-02/phone_drive.json
echo "exit=$?"

python3 bench-gates/tools/latency_from_frames.py \
  --fps 240 \
  --pairs-file bench-gates/evidence/G-02/laptop_drive_pairs.csv \
  --label "laptop, DRIVE profile, same run" \
  --src-refresh-hz <MEASURED> --dst-refresh-hz <MEASURED> --camera-fps <MEASURED> \
  --json bench-gates/evidence/G-02/laptop_drive.json
echo "exit=$?"

# the delta (the number that matters), from the two saved medians
python3 - <<'PY'
import json
p = json.load(open("bench-gates/evidence/G-02/phone_drive.json"))
l = json.load(open("bench-gates/evidence/G-02/laptop_drive.json"))
d = p["median_ms"] - l["median_ms"]
print("phone  median %.1f ms" % p["median_ms"])
print("laptop median %.1f ms" % l["median_ms"])
print("DELTA         %.1f ms  (+/- %.1f ms; the systematic bias is common to both runs "
      "and cancels in the delta)" % (d, 2 * p["uncertainty"]["random_bound_ms"]))
PY
```

Assert against the RULED target (2026-09-05, D-4 O-1; see PASS/FAIL criterion 6):

```sh
python3 bench-gates/tools/latency_from_frames.py --fps 240 \
  --pairs-file bench-gates/evidence/G-02/phone_drive_pairs.csv \
  --median-target-ms 200 --p95-target-ms 200      # both flags = the RULED 200 ms MAXIMUM (D-4 O-1);
                                                  # the 150 ms DESIRED figure is reported by hand below,
                                                  # never passed as a flag — a flag is a FAIL bound in this tool
```

CSV shape (`n_source,n_display[,label]`; a header row is optional, `#` lines ignored):

```
n_source,n_display,label
1200,1236,edge 1
1680,1719,edge 2
```

## Expected evidence

- Two `*_pairs.csv` files (phone, laptop) with ≥ 25 rows each, from the **same** capture.
- Two JSON results carrying the per-sample table, min/median/p95/max, the random bound,
  the itemised systematic bias, and the median interval.
- The computed **delta** with its uncertainty.
- The rig record from step 1.
- The phone's own `frames src=rvfc … dropped=0 advanced=true` samples across the run,
  proving the picture was live and not a frozen last frame.
- A short note on thermal/battery and laptop CPU with two peers.

## PASS / FAIL criteria

> ### THRESHOLD MISSING — owner/bench decides.
> **There is no recorded acceptance number for the phone-vs-laptop delta**, which is
> the number the shipped design says matters
> (`iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:679-680`). This card must not invent one.

What *does* exist, and what it is worth:

| Number | Source | Standing |
|---|---|---|
| 150 ms desired / **200 ms** maximum glass-to-glass | `iPhone_rc/docs/VR_FPV_IMPLEMENTATION_PLAN.md:541` | **RULED 2026-09-05 (D-4 O-1):** retained as the acceptance target for the phone's own glass-to-glass latency, despite the OD-16 topology change (laptop-relayed WHEP pull replacing the direct APFPV RTP path this target was originally written against). This is the target for the phone's **absolute** latency, not the phone-vs-laptop delta — the delta (C2-1) stays **BENCH-TBD**, see the THRESHOLD MISSING note above |
| "300–500 ms" | brief-illustrative only | Explicitly refused as a measurement by `iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:198-200` — *"must not be laundered into this document"*. **Do not use it** |
| 98–136 ms | `iPhone_rc/docs/SIMULATOR_TESTING.md:317` | Simulator, loopback, `testsrc`. `:319` — *"This is not a bench number and must not be quoted as one."* |

**Objective criteria this card can assert without inventing anything:**

| # | Criterion | PASS | FAIL |
|---|---|---|---|
| 1 | The phone is not *ahead* of the laptop | `delta ≥ 0` within the random bound | a negative delta means the two viewers were not measured on the same edge — the run is void, not fast |
| 2 | Both runs are steady-state | ≥ 25 samples, taken ≥ 60 s after `phase live`, `dropped=0` throughout | any dropped frames, or samples inside the start-up transient |
| 3 | The number is repeatable | median of a second capture within **2 capture frames** (8.33 ms at 240 fps) of the first | wider ⇒ the rig, not the pipeline, is the dominant term; fix the rig |
| 4 | p95 is meaningful | `n ≥ 20` (the script says so explicitly) | fewer samples ⇒ report the median only, and say p95 was not established |
| 5 | The systematic bias is bounded, not ignored | all three of `--src-refresh-hz`, `--camera-fps`, `--dst-refresh-hz` supplied **from step 1's measurements of this rig** — the tool cannot tell a guess from a measurement, so this criterion is only as good as the honesty of the three numbers | the script prints `systematic bias NOT ACCOUNTED`, and the result is a raw number with an unknown floor |
| 6 | Phone glass-to-glass latency vs the RULED target (2026-09-05, D-4 O-1: **150 ms desired / 200 ms maximum**) | median ≤ **200 ms** and p95 ≤ **200 ms** (the maximum) — `--median-target-ms 200 --p95-target-ms 200`, script exit 0. Then state, by hand in `RESULT.md`, whether the median also met the **150 ms desired** figure — that is a report line, not an exit-code bound, because every `--*-target-ms` flag in `latency_from_frames.py` is a FAIL bound (`:262-280`) | median or p95 above **200 ms** ⇒ FAIL, script exit 1. A median between 150 and 200 ms PASSES the maximum and is recorded as "short of the 150 ms desired figure" |

The gate's own verdict is **the measured delta plus its uncertainty, handed to the
owner** — who then decides whether it is acceptable, and whether the recorded fallbacks
(`(b)` native RTSP/RTP + VideoToolbox, `(c)` RTP straight from the camera —
`iPhone_rc/README.md:482`) come off the shelf.

## Stop conditions

Stop and power down if:

- the car moves, or anything other than the camera and its link draws power. This card
  authorises **no** propulsion, steering, gimbal or servo activity;
- the camera or the link is hot to the touch, or the phone reports a serious thermal
  state;
- the phone's picture freezes but the app keeps claiming it is live — that is the
  "plausible-looking stale" failure the contract forbids
  (`iPhone_rc/docs/SIMULATOR_TESTING.md:310-313`); stop and record it as a defect, it is
  worth more than the latency number;
- autofocus, exposure or the tripod moves mid-capture — void the run rather than
  correcting indices by hand;
- anyone suggests reading the number off the on-screen counters alone without the frame
  indices. The counter is the **cross-check**, not the measurement: it cannot tell you
  which screen was sampled first inside one capture frame.

## Rollback

Nothing to undo in software. Close the rig page, stop the phone app, stop the stream,
power the camera down. No setting is changed by this card except the video profile
selection, which is switched back to whatever the owner had before. No repository is
modified; the evidence files are new files under `bench-gates/evidence/G-02/`.

## Outputs to save

```
bench-gates/evidence/G-02/
  rig_record.md                 # step 1: every parameter, plus build commits
  phone_drive_pairs.csv
  laptop_drive_pairs.csv
  phone_drive.json              # --json output
  laptop_drive.json
  delta.txt                     # the computed delta and its uncertainty
  phone_showpiece_pairs.csv     # second profile, if run
  laptop_showpiece_pairs.csv
  frames_rvfc.txt               # the app's own presented-frame samples
  thermal_battery_cpu.md
  capture/                      # the 240 fps clips, or a note saying where they live
```

## Downstream unlocked by PASS

- Answers the CB5 line item *"glass-to-glass latency on the phone and on the laptop,
  same event, same run"* (`iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:679-680`) and lets
  `iPhone_rc/README.md:480`'s `[bench-TBD]` be replaced by a real figure.
- Gives the owner the input to Q3 — whether DRIVE, SHOWPIECE, or a third phone-specific
  tuning is right for the phone (`iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:686-687`).
- Settles whether the recorded fallbacks (b)/(c) stay on the shelf.

**It unlocks nothing on the control side.** In particular it does **not** touch
FIRST_ACTIVE, R6, R8 or R9, and it discharges no A2 or Phase B item beyond having been
run under them.

## BENCH-TBD residue

- **Simultaneous stability**: whether the second WebRTC peer degrades the laptop's own
  picture over a ≥ 5-minute soak (`iPhone_rc/docs/PHONE_LIVE_VIDEO_DESIGN.md:681-683`) — measure it in
  the same session, but it is a separate claim from latency.
- **Range**: behaviour at the edge of hotspot range and recovery after a Wi-Fi drop.
- **The camera's own encoder settings** (bitrate, GOP, resolution, codec) live on the IP
  camera and are outside the ground station (`video_profiles.md:100`); they dominate
  latency and are unmeasured.
- **SHOWPIECE ingest assumption**: that the camera serves interleaved RTSP/TCP alongside
  its other consumers (`video_profiles.md:40`, BENCH-TBD CB5).
- **`writeQueueSize 1024`** right-sized against the camera's real bitrate/GOP burst
  (`video_profiles.md:41`).
- **Whether DRIVE wants a *sub*-default write queue** once real latency is measured —
  deliberately not pre-tuned (`video_profiles.md:94-96`).
- **The acceptance number itself.** See PASS/FAIL: THRESHOLD MISSING.

## Evidence label

**NOT-EXECUTED.** Nothing on this card has been run. Every latency figure in the repos
today is a simulator/loopback figure and stays `[bench-TBD]`
(`iPhone_rc/README.md:480`, `iPhone_rc/docs/SIMULATOR_TESTING.md:319-323`).
