# 02 — Documentation Source Map

What every existing document in the three repos is, what category it belongs to, and how
current/trustworthy it is. (Same [C]/[I]/[A] convention as 01.)

## 2.1 `w17-control-fw/` root

| File | Category | What it is |
|---|---|---|
| `CLAUDE.md` | **Architecture + requirements (the founding brief)** | The original build brief: project context, hardware target and full pin map, the 8-module functional spec, behavior defaults, 3-stage validation plan, architecture rules, and the 4 non-negotiable safety priorities. **[C]** This is the single most important document — the whole codebase is its implementation. **[I]** Written *before* the code (it says "starting proposal", "first deliverable — stop and show me"), so treat later docs/code as overriding on details (e.g., link2 frame grew from the sketch in §2.7 to the final 14-byte v1). |
| `platformio.ini` | Build config | Defines the four build environments: `esp32dev` (real/gift firmware), `esp32dev_sim` (+Wokwi CRSF feeder), `esp32dev_tuning` (+serial console), `native` (host unit tests). Heavily commented. |
| `wokwi.toml`, `diagram.json` | Simulation config | Wokwi virtual-hardware setup: which firmware binary to load and the virtual circuit (servos, pot on GPIO34, button on GPIO35, UART loopback). See `docs/SIMULATION.md`. |
| `.github/workflows/ci.yml` | CI | **[C exists; contents not yet read]** Per `ROADMAP.md` B2.1: native tests + both esp32 builds on every push. |

## 2.2 `w17-control-fw/docs/` — the main documentation set

| File | Category | What it is |
|---|---|---|
| `ROADMAP.md` | **Project history + status ledger** | The most information-dense doc after CLAUDE.md. Part A: the adversarial review verdict on deliverable #1 — 13 findings (A1–A13) incl. the critical boot-failsafe bug, each with file/line and fix. Part B: the full build log D1.5→D8 and Phase-2/3 items, each entry recording *what was built, what design decisions changed and why, and test counts*. **[C]** Status date 2026-07-02; entries through 2026-07-03. **[I]** This is effectively the project's decision journal — when the code looks surprising, the explanation is usually an A-finding or a D-entry here. |
| `00_BUILD_SHEET.md` | **Build/assembly (one-pager)** | The condensed physical build plan: locked mechanical config, print order table, packing layout (where each board/part physically sits in the car), the 7 confirmed pre-power bench fixes, pre-build checklist, paint/finish order. |
| `bill_of_materials_v2.md` | **Purchasing/manufacturing** | Complete verified buy-list with prices/links (AliExpress + rcMart + local), what's owned already (camera, transmitters), open purchase confirmations, and a "key build reminders" recap of the electrical fixes. Supersedes v1; documents *why* each v1→v2 change happened. |
| `print_spec_v2.md` | **Manufacturing (3D printing)** | Slicer settings and print order per part group: material choice per load/heat (PLA body, PETG floor/front, ASA rear axle/drivetrain), the layer-orientation golden rule, which upstream model folders to print vs skip, finishing/paint sequence. Firmware-irrelevant but explains physical constraints (e.g., why metal axle sleeves exist). |
| `w17_wiring_assembly_atlas.html` | **Wiring + assembly (diagrams)** | Self-contained HTML page with Mermaid diagrams. Part A electrical: system overview, the two power rails, control signal chain, ESP32 #1 I/O, ESP32 #2 I/O, camera↔WiFi wiring. Part B mechanical: drivetrain, steering linkage, front corner, rear axle, fasteners, chassis layout. **[I] Predates the firmware**: its footer says "pin numbers are illustrative — your firmware defines the real ones" and ELEC-04 references a nonexistent `esp32_car_control.ino`. Use it for *topology* (what connects to what), and `lib/config/PinMap.hpp` for actual pins. Open it in a browser — diagrams render on load. |
| `link2_protocol.md` | **Protocol specification** | The normative spec for the board#1→board#2 link: framing (0xA5 + length + payload + CRC8/DVB-S2), byte-exact v1 payload table, flag bit assignments, sender state matrix, 20 Hz timing, the mandatory 500 ms receiver staleness rule, and a worked hex example pinned by a unit test. **[C]** This repo owns the spec; the copy in `w17-soundlight-fw/docs/` is identical (verified: only this original exists as source of truth per soundlight `CLAUDE.md` "do not fork"). |
| `SIMULATION.md` | **Simulation/testing** | How to run the Wokwi virtual-hardware demo (`pio run -e esp32dev_sim`), the scripted ~25 s phase table (boot-safe, arm-block, driving, gear/ERS, three distinct failsafe scenarios), the interactive pot/button, known cosmetic quirks, and a first-run verify checklist. |
| `D8_BENCH_BRINGUP.md` | **Bench/bring-up runbook (testing on real hardware)** | The ordered 11-phase checklist from "nothing powered" to "driving on the car": pre-power electrical fixes → power rails → ELRS link characterization → CRSF reception → channel map → **failsafe/arm-gate proof gate** → steering → ESC/motor → gimbal → sensors → link2/board#2 → ground station → on-car. Encodes every accumulated bench-verify item from the design reviews. **[C]** This is the *next real-world step* for the project. |
| `f1_hud.html` | **Design mockup (UI)** | A standalone static HTML/CSS/JS mockup of the F1 HUD ("W17 — FPV HUD", video placeholder background). **[I]** The design prototype for what became `w17-ground-station/renderer/` — the README describes the same HUD; this file has no code links to the app. Reference for visual intent only. |

## 2.3 `w17-soundlight-fw/` docs

| File | Category | What it is |
|---|---|---|
| `CLAUDE.md` | **Architecture brief** | Board #2's founding brief: what it consumes/produces, its own pin map (UART RX 16, I2S 26/25/22, LED 4), the house architecture rules plus two new ones — the **cross-core atomic rule** and the **audio dead-man** (params stale 500 ms → volume to 0) — and the module map. |
| `README.md` | Overview | Public-facing summary: role, build/test commands, module table with purity flags, dual-core note. |
| `docs/link2_protocol.md` | Protocol (copy) | **[C]** Copy of the control repo's spec ("copied from the control repo, which owns it" — README). Read the control repo's version; changes land there first. |
| `docs/SIMULATION.md` | Simulation/testing | The standalone bench demo (`esp32dev_sim` + `-DW17_SIM_LINK2_FEEDER`): 14 s scripted phase loop (idle → drive → ERS → harvest → cornering → **dropout → local failsafe** → recovery) and a first-run bench checklist (I2S sanity, MAX98357A straps, WS2812 fixes, synth voicing, LED power budget). |

## 2.4 `w17-ground-station/` docs

| File | Category | What it is |
|---|---|---|
| `README.md` | **Architecture + overview** | The app's role (viewer-only rationale), video/HUD/telemetry feature list, run commands, dev-environment troubleshooting (Electron postinstall gate, `ELECTRON_RUN_AS_NODE` leak), layout table. |
| `docs/SETUP.md` | **Bench verification (video pipeline)** | The ordered hardware-fact checklist: **H.264 vs H.265 codec (the #1 risk)**, camera RTSP URL, mediamtx/WHEP verification, telemetry serial-port sharing, offline demo with ffmpeg, and the zero-code gift-day fallback. |
| `docs/TELEMETRY.md` | **Protocol/contract** | The normative telemetry contract: the normalized `Telemetry` object fields (all optional, >1 s stale → back to simulation), which CRSF frame carries which truth and why (0x08/0x02/0x21/0x14), why standard frames instead of MSP, the exclusive-COM-port obstacle and its three resolutions, and the frame→field mapping with golden-vector cross-testing against the firmware. |
| `docs/CODESIGNING.md` | Packaging/deployment | **[C exists; not yet read in detail]** Per ROADMAP "still deferable": how to optionally code-sign the Windows .exe to remove the SmartScreen prompt. |
| `electron-builder.yml`, `mediamtx/mediamtx.yml` | Build/deploy config | Windows packaging config; pinned mediamtx server config (`paths.cam.source` is where the real camera RTSP URL goes). |

## 2.5 Category cross-index

- **Architectural / requirements:** control `CLAUDE.md`, soundlight `CLAUDE.md`, ground `README.md`, ground `docs/TELEMETRY.md` (contract half)
- **Project history / decisions:** control `docs/ROADMAP.md` (unique — nothing else records the "why")
- **Protocol:** control `docs/link2_protocol.md` (owner) + soundlight copy; ground `docs/TELEMETRY.md`; CRSF specifics live in code comments (`lib/crsf/`) + `CLAUDE.md` §2.1
- **Simulation / testing:** control `docs/SIMULATION.md` + `wokwi.toml`/`diagram.json`; soundlight `docs/SIMULATION.md`; both `test/` trees; ground `test/` (vitest)
- **Bench / bring-up:** control `docs/D8_BENCH_BRINGUP.md` (master runbook), ground `docs/SETUP.md`
- **Manufacturing / printing / wiring / purchasing:** `00_BUILD_SHEET.md`, `print_spec_v2.md`, `bill_of_materials_v2.md`, `w17_wiring_assembly_atlas.html`
- **UI design:** `f1_hud.html` (mockup)

## 2.6 Trust ordering (when documents disagree)

**[I]** Reasoned from the docs' own supersession notes:

1. **Code + its unit tests** (golden frames pin protocols byte-exactly)
2. `docs/ROADMAP.md` D/Phase entries (records what actually landed, including deviations from CLAUDE.md — e.g., "no raw Direct mode" design change in B2.2)
3. Protocol docs (`link2_protocol.md`, `TELEMETRY.md`) — kept in lockstep with code by golden tests
4. `CLAUDE.md` briefs (original intent; a few details superseded)
5. `w17_wiring_assembly_atlas.html` (pre-firmware, topology-level)
6. Anything marked v1 (both v2 docs supersede their v1s, which are not in the repo)
