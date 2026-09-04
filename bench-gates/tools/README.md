# bench-gates/tools/

Host-side tooling for the bench gate cards — **both** ladders. **Nothing here powers, flashes or
commands any hardware, and nothing here opens a serial port for write.** Everything below needed no
hardware to write; the "runs without hardware" column says which need none to run.

## Firmware/bench side (`INDEX.md`, the `BG-*` cards)

| Tool | Purpose | Runs without hardware? |
|---|---|---|
| `crsf_sniff.py` | passive CRSF frame sniffer/decoder for a read-only serial tap; also replays a captured byte file | **yes**, with `--file` / `--stdin` |
| `test_crsf_sniff.py` | 21 synthetic-frame unit tests for the decoder | **yes** |
| `crsf_xcheck_cpp.sh` | 300 pseudo-random vectors compared against the firmware's own `CrsfParser.cpp` | **yes** (needs a C++ compiler) |
| `bench_capture.sh` | evidence folder + environment/HEAD stamp + read-only timestamped serial capture + sha256 manifest | `--no-serial`: **yes**. The serial half is **Phase B**. |
| `pdb_continuity_sheet.md` | no-power multimeter worksheet using A2's own row IDs | worksheet |
| `first_power_current_limits.md` | what the documents fix vs the 13 thresholds that are missing | reference |

## Ground side (`G-INDEX.md`, the `G-*` cards)

These arrive with the `offline/bench-gates-ground` branch and share this directory without
overlapping a filename.

| Tool | Purpose | Runs without hardware? |
|---|---|---|
| `latency_rig.html` | G-02's offline flash rig: full-screen flash + 7-digit ms counter + 12-bit binary flash-id strip. No network, no external asset | **yes** (a browser) |
| `latency_from_frames.py` | G-02: frame indices → glass-to-glass latency, with the random bound and each systematic-bias term reported separately and never folded into the headline number | **yes** |
| `raceday_timing.py` | G-04: a timestamped capture → press/spawn/link-claim deltas, judged against `LINK_UP_WAIT_MS`. Refuses a capture with no stamp anywhere (`exit 2`) rather than inventing a zero; prefers a `W17T` line's own payload timestamp over any wrapper stamp, and measures on the monotonic `m` when both ends of a leg carry one | **yes** |
| `tests/run_tests.py` | 81 checks over synthetic fixtures for both ground tools | **yes** |

## The consolidated gap list

[`../MISSING_THRESHOLDS.md`](../MISSING_THRESHOLDS.md) is the single deduplicated list of every
number these cards need and no document supplies — 27 items, split into the 7 the owner can rule
today with no hardware and the 20 a bench measurement has to set. `first_power_current_limits.md`
holds the car-side current rows in full; the consolidated file points at it rather than copying it.

## Safety properties, stated so they can be checked

- **`crsf_sniff.py` has no transmit path.** It opens the port with pyserial and only ever calls
  `read()`. `test_crsf_sniff.py::test_no_transmit_path_exists` asserts that no serial write appears
  in the source. The real guarantee is still the **wire**: leave the tap adapter's TX pin
  unconnected (BG-06 says so twice, for the same reason).
- **`bench_capture.sh` reads the tty and never writes to it.** It does configure the line with
  `stty` and it does open the port — which asserts DTR/RTS on most USB-UART bridges and **will
  reset an ESP32**. That is exactly why the serial half is gated behind Phase B, and why the script
  prints a gate warning and waits 5 s before starting.
- **No tool in either set builds, flashes or uploads anything.** The `pio` commands live in the
  cards, where their gate is stated next to them.
- **No tool in either set opens a serial port for write.** The only `serial.Serial(...)` in the
  directory is `crsf_sniff.py:391`, followed at `:397` by `ser.read(4096)` and nothing else; the
  `write` calls in the tree write *capture files*, not ports. The ground tools read text files and
  never touch a device at all.

## Quick verification, any time, no hardware

```bash
cd /Users/vitaliykhomenko/Documents/projects
python3 bench-gates/tools/test_crsf_sniff.py    ; echo "exit: $?"  # expect 21/21, exit 0
bench-gates/tools/crsf_xcheck_cpp.sh             ; echo "exit: $?"  # expect 300 vectors, 0 mismatches, exit 0
python3 bench-gates/tools/tests/run_tests.py     ; echo "exit: $?"  # expect 81 checks, 0 failures, exit 0
```

All three were run at card-creation time and after the 2026-09-05 review fixes, and all three
exited `0` (OBSERVED on this Mac). That proves the **tools**; it proves nothing about any wire, any
Windows machine or any phone — see BG-06, G-03 and G-02 respectively.
