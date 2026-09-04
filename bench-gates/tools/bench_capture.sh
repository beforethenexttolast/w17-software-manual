#!/usr/bin/env bash
# W17 bench-gate evidence capture: create the evidence folder, stamp the
# environment, and (optionally) log a serial console with per-line timestamps.
#
# READ-ONLY on the serial device. It configures the line and reads; it never
# writes a byte to the port, so it cannot type into a firmware console and
# cannot command anything. Opening a port does assert DTR/RTS on most USB-UART
# bridges, which resets an ESP32 -- that is why running this at all is Phase-B
# work: see the gate line below.
#
#   GATE: attaching a USB cable to a board is Phase B. Do not run the serial
#   half of this script until A2 is CLOSED and Phase B is APPROVED
#   (w17-control-fw/docs/D8_BENCH_BRINGUP.md Phase -1). Creating the folder
#   and stamping the environment (--no-serial) is safe at any time.
#
# Usage:
#   bench_capture.sh <GATE-ID> [--no-serial]
#   bench_capture.sh <GATE-ID> --port /dev/tty.usbserial-XXXX [--baud 115200]
#                              [--seconds 120] [--note "what you are doing"]
#
#   <GATE-ID>  one of BG-01 … BG-08 (see bench-gates/INDEX.md), or any short
#              token; it becomes the evidence subfolder name.
#
# Creates:  bench-gates/evidence/<GATE-ID>/<UTC-stamp>/
#             meta.txt      host, dates, repo HEADs, tool versions, the note
#             console.log   timestamped serial lines (serial mode only)
#             console.raw   untouched bytes as received (serial mode only)
#             MANIFEST.txt  sha256 of every file in the folder, written at exit
#
# Exit: 0 folder created (and capture ended normally) · 2 bad usage · 3 I/O

set -euo pipefail

GATE="${1:-}"
[ -n "$GATE" ] || { sed -n '1,30p' "$0"; exit 2; }
shift

PORT=""; BAUD=115200; SECONDS_LIMIT=""; NOTE=""; NO_SERIAL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --port)      PORT="${2:-}"; shift 2 ;;
    --baud)      BAUD="${2:-}"; shift 2 ;;
    --seconds)   SECONDS_LIMIT="${2:-}"; shift 2 ;;
    --note)      NOTE="${2:-}"; shift 2 ;;
    --no-serial) NO_SERIAL=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"                 # workspace repo root
STAMP="$(date -u +%Y-%m-%dT%H%M%SZ)"
DIR="$ROOT/bench-gates/evidence/$GATE/$STAMP"
mkdir -p "$DIR"

{
  echo "gate:            $GATE"
  echo "created (UTC):   $STAMP"
  echo "created (local): $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "host:            $(hostname)"
  echo "uname:           $(uname -a)"
  echo "operator note:   ${NOTE:-(none given)}"
  echo
  echo "--- repo HEADs at capture time (evidence must name the code it tested) ---"
  for repo in "$ROOT" \
              /Users/vitaliykhomenko/Documents/projects/w17-control-fw \
              /Users/vitaliykhomenko/Documents/projects/w17-soundlight-fw \
              /Users/vitaliykhomenko/Documents/projects/w17-ground-station \
              /Users/vitaliykhomenko/Documents/projects/w17-mapper; do
    if [ -d "$repo" ]; then
      label="$(basename "$repo")"
      [ "$repo" = "$ROOT" ] && label="workspace"
      printf '%-24s %s %s\n' "$label" \
        "$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo '?')" \
        "$(git -C "$repo" status --porcelain 2>/dev/null | grep -q . && echo '(DIRTY)' || echo '(clean)')"
    fi
  done
  echo
  echo "--- tools ---"
  echo "python3:  $(python3 --version 2>&1)"
  command -v pio >/dev/null && echo "pio:      $(pio --version 2>&1)" || echo "pio:      (not installed)"
  echo
  echo "--- serial ---"
  if [ -n "$PORT" ]; then
    echo "port: $PORT   baud: $BAUD   limit: ${SECONDS_LIMIT:-none}s"
  else
    echo "no serial capture requested"
  fi
  echo
  echo "--- ports visible on this Mac at capture time ---"
  ls -1 /dev/tty.* 2>/dev/null || echo "(none)"
} > "$DIR/meta.txt"

echo "evidence folder: $DIR"
echo "wrote:           $DIR/meta.txt"

finish() {
  ( cd "$DIR" && for f in *; do
      [ -f "$f" ] && [ "$f" != "MANIFEST.txt" ] && \
        printf '%s  %s\n' "$(shasum -a 256 "$f" | awk '{print $1}')" "$f"
    done ) > "$DIR/MANIFEST.txt" 2>/dev/null || true
  echo "wrote:           $DIR/MANIFEST.txt"
  echo
  echo "Record this folder path in the gate card's 'Outputs to save' section."
}
trap finish EXIT

if [ "$NO_SERIAL" = "1" ] || [ -z "$PORT" ]; then
  echo "(no serial capture — folder and meta only)"
  exit 0
fi

[ -e "$PORT" ] || { echo "ERROR: no such device: $PORT" >&2; exit 3; }

echo
echo "!! GATE CHECK: a USB cable on a W17 board is Phase B work."
echo "!! A2 must be CLOSED and Phase B APPROVED in CURRENT_STATUS.md."
echo "!! Opening this port asserts DTR/RTS and will reset the board."
echo "Press Ctrl-C now to abort; capture starts in 5 s."
sleep 5

# Raw line settings; -echo and no local flow control. Reading only.
stty -f "$PORT" "$BAUD" cs8 -cstopb -parenb raw -echo 2>/dev/null \
  || { echo "ERROR: stty failed on $PORT" >&2; exit 3; }

echo "capturing… Ctrl-C to stop"

# One reader, two sinks: console.raw keeps the untouched bytes, console.log
# gets a real arrival timestamp per line (wall-clock UTC + seconds since the
# first byte). Read-only: the port is opened "rb", never "wb"/"r+b".
PORT="$PORT" SECONDS_LIMIT="${SECONDS_LIMIT:-}" DIR="$DIR" python3 - <<'PY'
import datetime, os, sys, time

port = os.environ["PORT"]
limit = os.environ.get("SECONDS_LIMIT") or None
limit = float(limit) if limit else None
d = os.environ["DIR"]

t_start = time.monotonic()
first = None
buf = bytearray()
lines = 0
try:
    with open(port, "rb", buffering=0) as tty, \
         open(os.path.join(d, "console.raw"), "wb") as raw, \
         open(os.path.join(d, "console.log"), "w", encoding="utf-8") as log:
        log.write("# W17 bench capture — [UTC | +s since first byte] line\n")
        log.write(f"# port={port} baud={os.environ.get('BAUD','?')}\n")
        log.flush()
        while True:
            if limit is not None and time.monotonic() - t_start >= limit:
                break
            chunk = tty.read(4096)
            if not chunk:
                time.sleep(0.01)
                continue
            now = time.monotonic()
            if first is None:
                first = now
            raw.write(chunk)
            raw.flush()
            buf.extend(chunk)
            while b"\n" in buf:
                line, _, rest = buf.partition(b"\n")
                buf = bytearray(rest)
                stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%H:%M:%S.%f")[:-3]
                log.write(f"[{stamp} | +{now - first:8.3f}] "
                          f"{line.rstrip(bytes([13])).decode('utf-8', 'replace')}\n")
                lines += 1
            log.flush()
except KeyboardInterrupt:
    pass
except OSError as exc:
    print(f"ERROR: {exc}", file=sys.stderr)
    sys.exit(3)
print(f"wrote:           {os.path.join(d, 'console.raw')}")
print(f"wrote:           {os.path.join(d, 'console.log')}  ({lines} lines)")
PY
