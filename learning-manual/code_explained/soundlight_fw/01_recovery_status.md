# S1 — Recovery / Completion Status (2026-07-05)

A short bookkeeping note written after S1's main document was created but before final
confirmation (a session/request limit interrupted the batch). It records that S1 is
complete and what was verified. Authoritative content lives in
`01_link2_receiver_and_protocol_compatibility.md`; status lives in
`../../source_code_progress.md`. This file is the one-page recovery checkpoint.

## Status: S1 COMPLETE

The main batch document
(`01_link2_receiver_and_protocol_compatibility.md`, ~1074 lines) was verified complete —
every required section is present:

| Required section | Present? | Where |
|---|---|---|
| Exact scope/files table | ✅ | "Scope" |
| C8 compatibility comparison | ✅ | §1, §8 |
| link2 copy / diff verification | ✅ | §1.1 (diff + md5) |
| frame length / start / version / payload / flags / endian / CRC verification | ✅ | §1.2 checklist table |
| stale-link behavior | ✅ | §5 (recompute), §7.3–7.4 |
| safe defaults before first valid frame | ✅ | §5 branch 1, §7.1 |
| tests + assertion explanations | ✅ | §6 (test_link2), §7 (test_link2monitor) |
| what S1 proves | ✅ | §10.1 |
| what S1 does NOT prove | ✅ | §10.2 |
| what waits for later soundlight batches | ✅ | §10.5 |
| what waits for hardware | ✅ | §10.6 |
| understanding questions | ✅ | §10.7 (10 questions) |
| concepts for later teaching | ✅ | §10.8 |

No content was missing; **no patch to the S1 document was required** during recovery.

## Tests run and result

- `pio test -e native -f test_link2 -f test_link2monitor` → **11/11 PASSED**
  (test_link2 5/5, test_link2monitor 6/6).
- Full `pio test -e native` (all six soundlight suites) → **40/40 PASSED**
  (test_integration, test_link2, test_link2monitor, test_soundsynth, test_enginesim,
  test_lights).

Native tests only — logic on the Mac, not electrical behaviour on an ESP32.

## Files explained (all `w17-soundlight-fw/`)

- `lib/config/include/config/PinMap.hpp` + `lib/config/library.json`
- `lib/link2/…/Link2Frame.hpp`, `Link2Codec.hpp`, `src/Link2Codec.cpp`, `library.json`
  — **md5-byte-identical to control**; referenced to C8, not re-explained.
- `lib/link2monitor/…/Link2Monitor.hpp`, `src/Link2Monitor.cpp`, `library.json`
  — the new module (staleness watchdog + per-field projection).
- `test/test_link2/test_main.cpp` (receiver-focused rewrite, 5 tests) and
  `test/test_link2monitor/test_main.cpp` (6 tests) — walked assertion-by-assertion.

## Diff verification (the batch's core act)

- `diff -r w17-control-fw/lib/link2 w17-soundlight-fw/lib/link2` → only
  `Link2Sender.{hpp,cpp}` absent from soundlight (**correct** — sender is board #1's job).
- `md5` on all four shared files (`Link2Frame.hpp`, `Link2Codec.hpp`, `Link2Codec.cpp`,
  `library.json`): **byte-identical**. `docs/link2_protocol.md` byte-identical too.
- Both repos hard-code and pass the same golden frame
  `A5 0B 01 2A E7 4C 03 DC 05 DC 1E 3C 02 CE`.

## C8 PROVISIONAL claims resolved

- **Cross-repo link2 compatibility → VERIFIED (source/test level).** Identical codec
  source + shared golden frame passing in both suites. (Wire-level still bench.)
- **"Two independent failsafe mechanisms" (frame `failsafe` flag vs board #2 local
  staleness) → upgraded INFERRED → VERIFIED.** Both halves in explained source.
- The golden frame as human-maintained three-way contract (control test / soundlight
  test / spec doc) → VERIFIED (all three carry the same bytes).

## Protocol mismatches / stale comments

- **Protocol mismatches: none.** Every §1.2 checklist item identical across repos.
- **New finding #50 (cosmetic):** the copied `lib/link2/library.json` carries a dangling
  `"hal"` dependency in soundlight (no `lib/hal` there; nothing includes it; native build
  unaffected). A cost of do-not-fork discipline. `esp32dev` build impact PROVISIONAL → S5.
- **C8 doc correction applied:** the stale "12-byte" comment was misattributed to
  `Link2Frame.hpp` — it lives only in control's `IByteSink.hpp:9` and
  `Esp32Link2Uart.hpp:14` (sender-side, never copied). Board #2's copy is accurate.
- **Comment-precision note (no action):** "engine to idle" (copied header) vs "idle/off"
  (spec) vs "silence" (brief + actual S2 behaviour) — implementation satisfies the
  strictest reading.

## Remaining hardware-only assumptions

- The physical GPIO25 → GPIO16 wire + **common ground**, 115200 timing between the two
  boards' independent crystals, and the spec's parasitic-powering caution — D8-style bench.
- Reserved ack pins staying unwired (board #1 GPIO26 = open q #33; board #2 GPIO17).
- I2S/MAX98357A strap behaviour and WS2812 electrical fixes (pin map notes; S4/S5 code).
- Whether 500 ms *feels* right on the physical car (tunable, config-ready).

## Bookkeeping applied during recovery

- `source_code_progress.md` — header updated; S1 batch-log entry added; all 8 soundlight
  S1 rows → `explained`.
- `glossary.md` — added **Link2Monitor**, **LinkStatus**, **Effective state / per-field
  staleness projection**.
- `open_questions.md` — added **#50** (dangling `hal` dep).
- `09_communication_protocols.md` — deep-dive pointer now cites S1 for the receiver side;
  §2.4 staleness rule annotated **[C]** with the S1-verified specifics.
- `07_soundlight_firmware_architecture.md` — §2 staleness table annotated **[C]
  S1-verified** (full ch07 re-audit + #43 still await S2–S5).
- `08_link2_outbound_protocol.md` (C8) — S1 resolution note added up top; the misattributed
  "12-byte" note corrected.

## Ready for?

- **S1 concept teaching:** YES — the material is complete and internally consistent; a
  concept-notes companion (like C9a/C9b/C10 have) could be written on request. Optional,
  deferred by default per the no-bloat rule.
- **S2 (`lib/enginesim` — the virtual engine):** YES, unblocked. Entry dependency (S1's
  effective `VehicleState`) is explained. **Not started** — awaiting approval.

*Recovery complete. No source code modified. Stop after S1.*
