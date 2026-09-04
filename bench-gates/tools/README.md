# bench-gates/tools/

Host-side tooling for the firmware/bench gate cards. **Nothing here powers, flashes or commands any
hardware.** Two of the six need no hardware at all to run, and all six needed none to write.

| Tool | Purpose | Runs without hardware? |
|---|---|---|
| `crsf_sniff.py` | passive CRSF frame sniffer/decoder for a read-only serial tap; also replays a captured byte file | **yes**, with `--file` / `--stdin` |
| `test_crsf_sniff.py` | 21 synthetic-frame unit tests for the decoder | **yes** |
| `crsf_xcheck_cpp.sh` | 300 pseudo-random vectors compared against the firmware's own `CrsfParser.cpp` | **yes** (needs a C++ compiler) |
| `bench_capture.sh` | evidence folder + environment/HEAD stamp + read-only timestamped serial capture + sha256 manifest | `--no-serial`: **yes**. The serial half is **Phase B**. |
| `pdb_continuity_sheet.md` | no-power multimeter worksheet using A2's own row IDs | worksheet |
| `first_power_current_limits.md` | what the documents fix vs the 13 thresholds that are missing | reference |

## Safety properties, stated so they can be checked

- **`crsf_sniff.py` has no transmit path.** It opens the port with pyserial and only ever calls
  `read()`. `test_crsf_sniff.py::test_no_transmit_path_exists` asserts that no serial write appears
  in the source. The real guarantee is still the **wire**: leave the tap adapter's TX pin
  unconnected (BG-06 says so twice, for the same reason).
- **`bench_capture.sh` reads the tty and never writes to it.** It does configure the line with
  `stty` and it does open the port — which asserts DTR/RTS on most USB-UART bridges and **will
  reset an ESP32**. That is exactly why the serial half is gated behind Phase B, and why the script
  prints a gate warning and waits 5 s before starting.
- **Neither tool builds, flashes or uploads anything.** The `pio` commands live in the cards, where
  their gate is stated next to them.

## Quick verification, any time, no hardware

```bash
cd /Users/vitaliykhomenko/Documents/projects
python3 bench-gates/tools/test_crsf_sniff.py ; echo "exit: $?"     # expect 21/21, exit 0
bench-gates/tools/crsf_xcheck_cpp.sh          ; echo "exit: $?"     # expect 300 vectors, 0 mismatches, exit 0
```

Both were run at card-creation time and both exited `0` (OBSERVED on this Mac, 2026-09-05).
That proves the **decoder**; it proves nothing about any wire — see BG-06.
