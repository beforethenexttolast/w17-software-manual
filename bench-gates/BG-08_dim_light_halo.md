# BG-08 — Dim-light / daylight halo visibility judgement

*The open bench gate listed in `CURRENT_STATUS.md`'s top entry ("dim-light halo visibility") and in
`closeout/vision-alignment-2026-09-04.md`:260 as* **"Dim-light / daylight halo judgement at the
raised floors (soundlight #55)."** *Source question: `learning-manual/open_questions.md` #55.*

> **What is actually being asked.** The compositor applies the brightness cap **before** gamma
> (`LightRenderer.hpp`:141-152, owner-ruled OD-12 Q1(a) 2026-09-03). At the default cap **110** that
> makes a full channel render at only **40/255** duty — so *everything* the strip can show lives in
> duty 0…40, and the quiet states live near the bottom of that. The firmware defends them with a
> compile-time floor, **`kMinVisibleDuty = 6`** (`LightRenderer.hpp`:127), enforced by
> `static_assert`s at the palette's definition site (`LightRenderer.cpp`:155-160, :175-180). The
> header says so itself: *"whether 6/255 actually reads in daylight is a bench judgement"*
> (`LightRenderer.hpp`:121-123). **This gate is that judgement and nothing more.** It cannot be
> closed by computation, and computation has already gone as far as it can.

## Prerequisites

1. **`A2-CLOSED` + `PHASE-B-OPEN`.** This gate requires board #2 flashed and the strip powered, and
   nothing is flashed or powered before those two states exist (`D8_BENCH_BRINGUP.md`:3-13).
   *(The 2026-07-17 bare-board smoke test was a one-time, narrowly scoped, owner-approved exception
   before A2 existed in its staged form — `w17-parts-to-gift-master-sequence.md`:106-114. It is
   historical evidence, **not a precedent this card may reuse.**)*
2. **A2 gate S5 passed**: W1 ≈330 Ω series resistor, W2 0.15–0.35 V forward across the 1N5819, W3
   OL reversed, W4 band toward strip VDD, W5 the 1000 µF charging (A2:471-477). A dim halo caused
   by a missing series resistor or a backwards diode is a wiring finding, not a palette finding.
3. **The strip mounted as it will ship** — behind the printed diffuser / halo part, in the body, not
   bare on the bench. A bare strip judged "plenty bright" says nothing about a strip behind
   `halo 2.1` and the **rear-light diffuser** (`00_BUILD_SHEET.md`:15).
4. **The segment layout bench-tuned or at least recorded.** The defaults are
   brake `{0,6}`, rainLight `{6,2}`, **halo `{8,14}`**, leftIndicator `{22,4}`, rightIndicator
   `{26,4}` on a **30-LED** strip (`LightRenderer.hpp`:11, :130-135). If the physical strip is
   arranged differently, the judgement is about different pixels.
5. Both **lighting conditions** available on the day: a genuinely dim room **and** real daylight —
   the question is explicitly about both (`open_questions.md` #55: *"plausibly fine at dusk,
   plausibly invisible in daylight"*).

## Required equipment

- Board #2 + the WS2812 strip + the printed halo/diffuser parts.
- `pio` for `w17-soundlight-fw`.
- A camera that can be locked to **fixed manual exposure** — auto-exposure will make every state
  look equally bright and destroy the comparison. Photographs are supporting evidence; **the human
  eye is the instrument**, because the question is "does a person see it".
- Optionally a lux meter, to record the ambient level each judgement was made at. Without it,
  record the condition in words ("overcast daylight, indoors by a window, 14:00").
- Serial monitor at 115200 for the sim build's phase narration.

## Topology (ASCII)

```
   The render pipeline this gate judges (LightRenderer.cpp applyBrightnessAndGamma, :135-138)
   ------------------------------------------------------------------------------------------

     designed colour  --> [ cap: channel * 110 / 255 ]  --> [ gamma 2.2 LUT ]  --> PWM duty
                             ^ CAP FIRST                        ^ THEN GAMMA
                             (OD-12 Q1(a); the header used to claim the opposite order)

     consequence:  renderedDuty(255, 110) == 40   =>  the ENTIRE usable range is duty 0..40
     floor:        kMinVisibleDuty == 6           =>  every designed-visible quiet state clears 6

   Board #2 standalone, no board #1 needed:
        pio run -e esp32dev_sim  -->  W17_SIM_LINK2_FEEDER injects a scripted link2 drive
        through the REAL assembler + monitor path, so every light state below appears on a
        21 s loop with nothing else attached (w17-soundlight-fw/docs/SIMULATION.md:1-6).

     0-2s IDLE(crank->armed teal) · 2-6 DRIVING · 6-8 ERS · 8-9.5 BRAKE+rain · 9.5-11 CORNERING
     11-12 DROPOUT(amber hazard) · 12-14 RECOVERED · 14-15.5 PARKED(dim-white halo)
     15.5-19.5 SHOWCASE(teal breathe) · 19.5-21 SHOW_LOWBATT(red pulse, no hazard)
```

## Exact procedure (numbered)

1. **Record the palette you are about to judge**, from the code, not from a document — the values
   have been raised once already (see BENCH-TBD residue). Compute the rendered duties for the cap
   actually compiled in.
2. **Flash `esp32dev_sim` on board #2** and let the 21 s loop run. It reaches every state this gate
   cares about with no board #1, no CRSF and no car.
3. **Judge each quiet state, in a genuinely dim room first**, with the strip behind its shipped
   diffuser. For each: *seen / marginal / not seen*, in those three words, plus a sentence.
   - **disarmed halo** (`kDimWhite`) — the PARKED beat, 14–15.5 s
   - **always-on tail** (`kDimRed`) — present in the base layer
   - **showcase breathe floor** — the dip of the SHOWCASE beat, 15.5–19.5 s
   - **showcase breathe peak** vs its floor — *is it seen to breathe, or does it look static?*
   - **NeverConnected grace breathe peak** — power board #2 with **no** link2 input at all
   - **armed halo teal** — the IDLE→armed beat
   - **low-battery red pulse** — SHOW_LOWBATT, 19.5–21 s
4. **Repeat the whole judgement in real daylight.** This is the half the open question actually
   doubts; a dim-room pass alone does not close the gate.
5. **Judge the contrast pairs, not only the absolute levels** — the compile-time asserts pin these
   relationships, and a person has to confirm they read as intended
   (`LightRenderer.cpp`:175-181):
   - **dim red tail vs bright brake bar**: the tail must not look like a brake light that is
     always on (the assert requires tail duty × 3 ≤ brake duty).
   - **disarmed dim-white halo vs armed teal**: disarmed must read *dimmer*.
   - **teal family vs amber hazard vs red brake**: never confusable
     (`LightRenderer.cpp`:60-62).
6. **Photograph each state at a fixed manual exposure**, same settings for every shot, so the images
   are comparable to each other. Note the exposure settings in the evidence.
7. **If a state fails**: the fix is a **palette or cap retune**, not a code redesign. The power
   budget has real headroom — `valid()`'s model is a **true upper bound** at **180 mA**
   (`LightRenderer.hpp`:226 with `kNumPixels` 30) against a **900 mA** budget
   (`LightRenderer.hpp`:209), while the actual all-amber hazard draw is **≈104 mA**
   (`LightRenderer.hpp`:215-216). **Brightness can rise substantially within budget** — but check
   the **UBEC headroom** before raising the cap (`w17-soundlight-fw/docs/SIMULATION.md`:49-53), and
   re-run the native suite, because the floors are `static_assert`ed and a careless edit fails the
   build rather than shipping something invisible.
8. **Record the verdict per state and per lighting condition.** A single global "looks fine" is not
   the output of this gate.

## Exact commands (fenced)

```bash
cd /Users/vitaliykhomenko/Documents/projects

grep -n "A2 .*NOT-EXECUTED\|Phase B .*BLOCKED\|PHASE-B-OPEN" CURRENT_STATUS.md | head
bench-gates/tools/bench_capture.sh BG-08 --no-serial --note "dim-light halo judgement"

# 1. The palette AS COMPILED — read it from the code every time, it has moved before:
grep -n "kTeal\|kDimWhite\|kDimRed\|kBrightRed\|kAmber\|kWhite\|kGraceBreathePeak\|kShowcaseBreatheFloor" \
     w17-soundlight-fw/lib/lights/src/LightRenderer.cpp
grep -n "maxBrightness\|kMinVisibleDuty\|kNumPixels\|kBudgetMilliamps" \
     w17-soundlight-fw/lib/lights/include/lights/LightRenderer.hpp

# 1b. Rendered duty for any colour, replicating the integer pipeline exactly
#     (cap BEFORE gamma; gamma LUT = round(255*(i/255)^2.2)):
python3 - <<'PY'
g=[int(255.0*((i/255.0)**2.2)+0.5) for i in range(256)]
rd=lambda ch,cap=110: g[ch*cap//255]
for name,c in [("kTeal (armed halo)",(0,130,120)),
               ("kDimWhite (disarmed halo)",(91,91,105)),
               ("kDimRed (tail)",(105,0,0)),
               ("kBrightRed (brake)",(255,0,0)),
               ("kAmber (hazard/indicator)",(255,90,0)),
               ("kWhite (rain light)",(255,255,255)),
               ("grace breathe peak",(55,110,110))]:
    print(f"{name:32} designed {c} -> duty {tuple(rd(x) for x in c)}")
lvl=206  # kShowcaseBreatheFloor
print(f"{'showcase breathe floor':32} designed {(0,130*lvl//255,120*lvl//255)} -> duty "
      f"{tuple(rd(x) for x in (0,130*lvl//255,120*lvl//255))}")
print("renderedDuty(255,110) =", rd(255), " kMinVisibleDuty = 6")
PY

# 2. Board #2 standalone demo build (PHASE B — this flashes hardware):
cd w17-soundlight-fw && pio run -e esp32dev_sim -t upload

# 3. Phase narration, so each photo can be tied to the state it shows:
cd /Users/vitaliykhomenko/Documents/projects
bench-gates/tools/bench_capture.sh BG-08 --port /dev/tty.usbserial-BOARD2 \
  --baud 115200 --seconds 300 --note "21 s demo loop, dim room pass"

# 7. If the palette is retuned, the floors are compile-time — the build itself checks them:
cd w17-soundlight-fw && pio test -e native
```

## Expected evidence

- **The as-compiled palette table** with its rendered duties, produced by the command above and
  saved verbatim — this is what makes the judgement reproducible against a specific commit.
- **A verdict per state per condition**: seen / marginal / not seen, plus a sentence, for the dim
  room **and** for daylight.
- **The three contrast-pair judgements** (tail vs brake, disarmed vs armed, teal vs amber vs red).
- **Fixed-exposure photographs** of each state, with the exposure settings recorded.
- The **ambient conditions** for each pass (lux if measured, words if not) and the **time of day**.
- Whether the strip was judged **behind its shipped diffuser** — and if not, the verdict is
  provisional.
- If anything was retuned: the **new palette values, the new rendered duties, the `pio test -e
  native` result**, and the **UBEC headroom check**.

## PASS/FAIL criteria (objective numbers)

The *numbers* are compile-time facts; the *verdict* is a human judgement. Both belong in the record.

**As-compiled duties at cap 110 (VERIFIED this session by replicating the integer pipeline;
`LightRenderer.cpp`:17-22, :64-71, :86-88, `LightRenderer.hpp`:110-111, :152):**

| State | Designed colour | Rendered duty (R,G,B) | Brightest channel | vs `kMinVisibleDuty` = 6 |
|---|---|---|---|---|
| armed halo `kTeal` | {0,130,120} | **{0, 9, 7}** | 9 | clears by 3 |
| disarmed halo `kDimWhite` | {91,91,105} | **{4, 4, 6}** | **6** | **exactly at the floor** |
| tail `kDimRed` | {105,0,0} | **{6, 0, 0}** | **6** | **exactly at the floor** |
| showcase breathe **floor** | {0,105,96} | **{0, 6, 5}** | **6** | **exactly at the floor** |
| showcase breathe **peak** | {0,130,120} | **{0, 9, 7}** | 9 | the whole breathe swings **6 → 9** |
| NeverConnected grace peak | {55,110,110} | **{1, 6, 6}** | **6** | **exactly at the floor** |
| brake `kBrightRed` | {255,0,0} | **{40, 0, 0}** | 40 | the ceiling |
| hazard/indicator `kAmber` | {255,90,0} | **{40, 4, 0}** | 40 | the ceiling |
| rain light `kWhite` | {255,255,255} | **{40, 40, 40}** | 40 | the ceiling |

| Check | PASS | FAIL |
|---|---|---|
| Every designed-visible quiet state | **seen** by eye in a **dim room**, behind the shipped diffuser | "not seen" for any of them |
| Every designed-visible quiet state | **seen** by eye in **daylight** | "not seen" ⇒ retune the cap or the palette; **this is the half the open question doubts** |
| Showcase breathe | reads as **breathing** | reads static — the swing is only **6 → 9** duty, deliberately shallow (`LightRenderer.cpp`:64-70) |
| Tail vs brake | brake unmistakably brighter; the tail never reads as a stuck brake light | the tail competes with the brake bar |
| Disarmed vs armed halo | disarmed reads **dimmer** than armed | they look the same |
| Colour families | teal / amber / red never confusable across a room | any confusion ⇒ a safety-signal problem, not a taste problem |
| Power, if the cap is raised | model stays a true upper bound and within **900 mA**; measured strip draw recorded; UBEC headroom checked | raising the cap without the headroom check |

> **THRESHOLD MISSING — owner/bench decides:** *what "visible" means here.* No document sets a lux
> level, a viewing distance, or a contrast ratio. `kMinVisibleDuty = 6` is a **floor the code
> enforces**, explicitly **"a floor, not a look"** (`LightRenderer.hpp`:114-127) — it is not a pass
> criterion for the human question. The verdict is the owner's, on the owner's bench, in both
> lighting conditions.
>
> **THRESHOLD MISSING — owner/bench decides:** *the maximum acceptable `maxBrightness`.* The
> budget arithmetic permits a substantial rise (180 mA modelled vs 900 mA budgeted, ≈104 mA
> actual), but the real constraint is the **UBEC rail headroom**, and **no current figure exists
> for any other rail-A load** — see `bench-gates/tools/first_power_current_limits.md`, rows T1–T13.

## Stop conditions

- **A2 gate S5 not passed** → stop. Judge nothing about brightness until the 330 Ω resistor, the
  1N5819 orientation and the bulk cap are proven; a wiring fault masquerading as a palette
  problem would be retuned into a real defect.
- **The strip glitches while audio DMA runs** → that is D8 B3.6 / Phase 9, a different fault. Fix it
  before judging colours (`SIMULATION.md`:42-44).
- **Judging on a bare strip, not behind the shipped diffuser** → not a stop, but the verdict is
  **provisional** and must be labelled so.
- **Auto-exposure photographs** → the evidence is worthless for comparison; re-shoot at fixed
  exposure.
- **The urge to "just raise the cap" without the headroom check** → the cap sits on rail A with the
  camera, the Wi-Fi module, both ESP32s, the RP1 and the amp, and **not one of those has a
  documented current draw** (see the second THRESHOLD MISSING note).
- **The urge to fix a "dim" state by editing a `static_assert`** → those asserts are the mechanism
  that keeps a quiet state from silently becoming invisible. Change the palette, not the guard.

## Rollback

- **A retune is a source change on `w17-soundlight-fw` and needs its own re-flash.** It is not
  carried by board #1's NVS blob and nothing in the coordinated flash moves it
  (`COORDINATED_FLASH.md`:131-135).
- **Reverting a palette change** is a git revert plus a re-flash; `pio test -e native` must be green
  again afterwards, since the floors and the budget are compile-time checks.
- **Nothing persists on board #2** — it carries no NVS tuning at all (`COORDINATED_FLASH.md`:97-98),
  so re-flashing an earlier image is the complete rollback.
- **If the judgement is inconclusive**, that is a legitimate outcome: record *marginal* and defer.
  Do not manufacture a verdict to close the gate.

## Outputs to save (evidence/ paths)

```
bench-gates/evidence/BG-08/<UTC-stamp>/
  meta.txt   MANIFEST.txt   console.log        # meta.txt names the soundlight commit judged
  palette_as_compiled.txt        # grep output + the computed duty table, verbatim
  verdict_dim_room.md            # per state: seen / marginal / not seen + a sentence
  verdict_daylight.md            # the same states, the half the open question doubts
  contrast_pairs.md              # tail vs brake, disarmed vs armed, teal vs amber vs red
  conditions.md                  # lux or words, time of day, diffuser fitted yes/no
  photos/exposure_settings.txt   # ONE fixed manual exposure for every shot
  photos/armed_teal.jpg  photos/disarmed_dimwhite.jpg  photos/tail_dimred.jpg
  photos/showcase_breathe_floor.jpg  photos/showcase_breathe_peak.jpg
  photos/grace_breathe_peak.jpg  photos/brake_bar.jpg  photos/hazard_amber.jpg
  retune/                        # only if anything changed:
    new_palette.txt  new_duties.txt  native_test_result.txt  ubec_headroom.md
```

## Downstream unlocked by PASS

- Closes the **"dim-light halo visibility"** bench gate in `CURRENT_STATUS.md`'s open list and
  **soundlight #55** in `learning-manual/open_questions.md`.
- Settles the companion bench-tune it is explicitly paired with: the **strip-layout `Segment`
  values** (`open_questions.md` #55) — you cannot judge which pixels read until you know which
  pixels are which.
- Feeds the **showcase-mode presentation**, which the vision names as core
  (`W17_PRODUCT_VISION.md`; memory note "showcase mode core"): the showcase breathe is one of the
  states judged here, and it is what the giftee sees with the car parked.
- Any retune becomes an input to the **soundlight shipped-tune compile pin** already tracked in
  `CURRENT_STATUS.md`.

## BENCH-TBD residue

- **The judgement itself is the residue** — it is the one thing here that cannot be computed, which
  is why the code comment says so at the definition site (`LightRenderer.hpp`:121-123).
- **DOC DRIFT, found this session:** `learning-manual/open_questions.md` #55 (:335-345) and
  `learning-manual/code_explained/soundlight_fw/04_lights_and_light_hal.md` (~:369-380) still quote
  the **pre-raise** palette — kDimWhite {40,40,46} → duty {1,1,1}, kDimRed {40,0,0} → {1,0,0},
  breathe peak → {1,3,3}. The code now carries **kDimWhite {91,91,105}** and **kDimRed {105,0,0}**
  (`LightRenderer.cpp`:18-19), which render at **{4,4,6}** and **{6,0,0}**. The closeout already
  frames this gate as "at the **raised** floors", so the direction is known — but the manual's
  numbers are stale and would mislead an operator who took them to the bench. **Recorded, not
  edited** (manual repo files are read-only to this session).
- **Whether the shipped diffuser changes the answer** is untested — every duty figure above is at
  the LED, not through the printed part.
- **No current figure exists for any rail-A load**, so "raise the cap, it fits the budget" is only
  half an argument until the UBEC headroom is measured
  (`bench-gates/tools/first_power_current_limits.md`).
- The **indicator self-cancel trim trap** (`SIMULATION.md`:54-61) is a neighbouring `[bench-TBD]`:
  a TX trim leaving the centred stick in `[20, 40)` makes an indicator blink forever. Not this
  gate's item, but the same session will see it.

## Evidence label at card creation

**NOT-EXECUTED** for the judgement — no light has ever been lit on this car. The **duty table is
VERIFIED** (computed this session by replicating the firmware's exact integer pipeline — cap then
gamma, `kGamma` LUT — against the palette constants at `w17-soundlight-fw` `7220c08`), which is a
statement about *what the code will drive*, not about *what a person will see*.
