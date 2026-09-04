#!/usr/bin/env bash
# Cross-check crsf_sniff.py's CRC8 and channel unpacking against the FIRMWARE's
# own C++ implementation (w17-control-fw/lib/crsf/src/CrsfParser.cpp).
#
# Why this exists: test_crsf_sniff.py proves the Python decoder is
# self-consistent. This script proves it agrees with the code that actually
# runs on board #1, on 300 pseudo-random vectors, so "the sniffer accepted the
# frame" and "the car would accept the frame" are the same statement.
#
# Host-only. Compiles two files, reads nothing from hardware, writes nothing
# to any device. Safe to run at any time, gate-independent.
#
# Usage:  bench-gates/tools/crsf_xcheck_cpp.sh [path-to-w17-control-fw]
# Exit:   0 = every vector matched · 1 = mismatch · 2 = setup problem

set -euo pipefail

CF="${1:-/Users/vitaliykhomenko/Documents/projects/w17-control-fw}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -f "$CF/lib/crsf/src/CrsfParser.cpp" ] || { echo "ERROR: no CrsfParser.cpp under $CF" >&2; exit 2; }
command -v c++ >/dev/null || { echo "ERROR: no C++ compiler on PATH" >&2; exit 2; }

cat > "$WORK/xcheck.cpp" <<'CPP'
#include "crsf/CrsfParser.hpp"
#include <cstdio>
#include <cstdint>
#include <random>
int main() {
    std::mt19937 rng(12345);                 // fixed seed: reproducible vectors
    for (int i = 0; i < 200; ++i) {          // CRC8 over random bodies
        int len = 1 + (int)(rng() % 30);
        uint8_t buf[64];
        for (int j = 0; j < len; ++j) buf[j] = (uint8_t)(rng() & 0xFF);
        printf("CRC %d ", len);
        for (int j = 0; j < len; ++j) printf("%02x", buf[j]);
        printf(" %02x\n", crsf::computeCrc8(buf, (size_t)len));
    }
    for (int i = 0; i < 100; ++i) {          // 16x11-bit unpack of random payloads
        uint8_t p[22];
        for (int j = 0; j < 22; ++j) p[j] = (uint8_t)(rng() & 0xFF);
        uint16_t ch[16];
        crsf::unpackChannels(p, ch);
        printf("UNPACK ");
        for (int j = 0; j < 22; ++j) printf("%02x", p[j]);
        for (int j = 0; j < 16; ++j) printf(" %u", ch[j]);
        printf("\n");
    }
    return 0;
}
CPP

c++ -std=c++17 -O1 -I "$CF/lib/crsf/include" \
    "$WORK/xcheck.cpp" "$CF/lib/crsf/src/CrsfParser.cpp" -o "$WORK/xcheck"
"$WORK/xcheck" > "$WORK/vectors.txt"

VECTORS="$WORK/vectors.txt" TOOLS="$HERE" python3 - <<'PY'
import os, sys
sys.path.insert(0, os.environ["TOOLS"])
from crsf_sniff import compute_crc8, unpack_channels

bad = n = 0
for line in open(os.environ["VECTORS"], encoding="utf-8"):
    f = line.split()
    if f[0] == "CRC":
        data, exp = bytes.fromhex(f[2]), int(f[3], 16)
        got = compute_crc8(data)
        n += 1
        if got != exp:
            bad += 1
            print(f"CRC MISMATCH {f[2]} py=0x{got:02x} cpp=0x{exp:02x}")
    else:
        payload, exp_ch = bytes.fromhex(f[1]), [int(x) for x in f[2:]]
        got_ch = unpack_channels(payload)
        n += 1
        if got_ch != exp_ch:
            bad += 1
            print(f"UNPACK MISMATCH {f[1]}\n  py ={got_ch}\n  cpp={exp_ch}")
print(f"{n} vectors compared against the firmware C++ decoder, {bad} mismatches")
sys.exit(1 if bad else 0)
PY
