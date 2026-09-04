#!/usr/bin/env bash
#
# host-vm.sh — the Mac side of the W17 Windows-VM validation loop.
#
# One wrapper around `vmrun` + `ssh`/`scp` so a validation session is a
# sequence of named, idempotent verbs instead of hand-typed paths. Every verb
# is safe to re-run; `--dry-run` prints the exact commands and executes none.
#
# Read `w17-windows-vm-validation-runbook.md` (workspace root) first. This
# script implements §2.1 (vmrun lifecycle), §2.2 (ssh invocation) and §4.1
# (evidence layout); it does not replace the one-time owner setup in §1.
#
# SAFETY (workspace CLAUDE.md rules 1-7). Nothing here flashes, powers, or
# connects hardware, and nothing opens a serial port. `suite` deliberately
# refuses to pass -IncludeHidTransition: step 7 needs a human at the DS4
# cable AND the car unpowered / RX unbound (runbook §3.1), so it is never
# something this wrapper starts on its own. A VM result is never physical
# proof: A2 stays NOT-EXECUTED, Phase B stays BLOCKED, R15 stays NO-GO.
#
# Requirements on the Mac: VMware Fusion (for `vmrun`), OpenSSH client.
# `doctor` reports which of those are missing without needing any of them.
#
# Usage:
#   scripts/vm/host-vm.sh [--dry-run] [--vmx PATH] [--host ALIAS]
#                         [--ssh-config PATH] <verb> [args...]
#
# Verbs:
#   doctor                 host preflight: Fusion, vmrun, RAM, free disk, ISO,
#                          ssh key, ssh config entry. Runs with nothing installed.
#   status                 is the VM registered / running?
#   start                  power on headless (no-op if already running)
#   stop                   graceful guest shutdown (no-op if not running)
#   snapshots              list snapshots
#   snapshot NAME          take snapshot NAME (no-op if NAME already exists)
#   revert NAME            revert to snapshot NAME (VM is powered off first)
#   screenshot [PATH]      capture the guest console to PATH
#   ip                     guest IP as VMware Tools reports it
#   ssh [CMD...]           ssh to the guest (interactive with no CMD)
#   push LOCAL REMOTE      scp a file/dir to the guest
#   pull REMOTE LOCAL      scp a file/dir back from the guest
#   bootstrap KEY SUBNET   copy + run guest-bootstrap.ps1 (see its own header)
#   check [OUTDIR]         copy + run guest-check.ps1, pull its JSON back
#   suite [EXTRA...]       run-all.ps1 for the automatable steps only, then
#                          pull the whole results directory into evidence/
#
# Configuration, in precedence order: flags, then environment, then
# ~/.w17vm.conf (plain `KEY=value` lines, sourced).
#   W17_VMX          absolute path to the .vmx
#   W17_SSH_HOST     ssh alias/host (default: w17vm)
#   W17_SSH_CONFIG   ssh config file (default: ~/.ssh/config)
#   W17_GUEST_ROOT   guest install root (default: C:\w17)
#   W17_EVIDENCE     local evidence root (default: ./evidence)
#   W17_ISO          path to the Windows 11 Arm64 ISO (doctor only)
#   VMRUN            override the vmrun binary
#
set -euo pipefail

DRY_RUN=0
VMX="${W17_VMX:-}"
SSH_HOST="${W17_SSH_HOST:-w17vm}"
SSH_CONFIG="${W17_SSH_CONFIG:-$HOME/.ssh/config}"
GUEST_ROOT="${W17_GUEST_ROOT:-C:\\w17}"
EVIDENCE_ROOT="${W17_EVIDENCE:-$PWD/evidence}"
ISO_PATH="${W17_ISO:-}"
VMRUN_BIN="${VMRUN:-/Applications/VMware Fusion.app/Contents/Public/vmrun}"
CONF="$HOME/.w17vm.conf"

# Minimum free host disk (GiB) doctor demands before it will call the disk
# precondition met. Derived in the runbook §1.3 from the ISO (~6.5 GB), the
# actual post-install guest footprint, and one snapshot's delta -- NOT from a
# measured install, so it is a floor to plan against, not an observation.
MIN_FREE_GIB=70
MIN_HOST_RAM_GIB=16

if [ -f "$CONF" ]; then
  # shellcheck disable=SC1090
  . "$CONF"
  VMX="${W17_VMX:-$VMX}"
  SSH_HOST="${W17_SSH_HOST:-$SSH_HOST}"
  SSH_CONFIG="${W17_SSH_CONFIG:-$SSH_CONFIG}"
  GUEST_ROOT="${W17_GUEST_ROOT:-$GUEST_ROOT}"
  EVIDENCE_ROOT="${W17_EVIDENCE:-$EVIDENCE_ROOT}"
  ISO_PATH="${W17_ISO:-$ISO_PATH}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die()  { printf 'host-vm: %s\n' "$*" >&2; exit 2; }
info() { printf '  %s\n' "$*"; }
ok()   { printf 'OK      %s\n' "$*"; }
bad()  { printf 'BLOCKED %s\n' "$*"; }
warn() { printf 'WARN    %s\n' "$*"; }

# Echo-or-execute. Every external mutation in this script goes through run().
# Display an argv the way a human would retype it: bare when it is a plain
# token, single-quoted when it contains whitespace or a quote. %q would be
# correct too but renders every Windows backslash escaped, which is unreadable
# for exactly the paths this script passes.
show_argv() {
  local a first=1
  for a in "$@"; do
    [ "$first" = 1 ] && first=0 || printf ' '
    case "$a" in
      *[[:space:]\'\"]*) printf "'%s'" "$(printf '%s' "$a" | sed "s/'/'\\\\''/g")" ;;
      '')                 printf "''" ;;
      *)                  printf '%s' "$a" ;;
    esac
  done
  printf '\n'
}

run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf 'DRY-RUN: '; show_argv "$@"
    return 0
  fi
  "$@"
}

# Same, but the caller wants stdout back. Under --dry-run this prints the
# command and returns empty output, so callers must tolerate that.
run_capture() {
  if [ "$DRY_RUN" = 1 ]; then
    { printf 'DRY-RUN: '; show_argv "$@"; } >&2
    return 0
  fi
  "$@"
}

VMRUN_WARNED=0
need_vmrun() {
  [ -x "$VMRUN_BIN" ] && return 0
  # --dry-run must stay usable on a Mac with no Fusion installed -- that is
  # exactly the state this workspace is in until the owner installs it, and
  # reviewing the commands is the only thing possible until then.
  if [ "$DRY_RUN" = 1 ]; then
    if [ "$VMRUN_WARNED" = 0 ]; then
      warn "vmrun not present at '$VMRUN_BIN' -- dry run continues, commands are printed only"
      VMRUN_WARNED=1
    fi
    return 0
  fi
  die "vmrun not found at '$VMRUN_BIN'. Install VMware Fusion, or set VMRUN. Run '$0 doctor' for the full preflight."
}

need_vmx() {
  [ -n "$VMX" ] || die "no VMX path. Pass --vmx PATH, set W17_VMX, or put W17_VMX=... in $CONF."
  [ "$DRY_RUN" = 1 ] || [ -f "$VMX" ] || die "VMX '$VMX' does not exist."
}

vmrun_() { need_vmrun; run "$VMRUN_BIN" -T fusion "$@"; }
vmrun_capture() { need_vmrun; run_capture "$VMRUN_BIN" -T fusion "$@"; }

is_running() {
  need_vmrun; need_vmx
  [ "$DRY_RUN" = 1 ] && return 1
  "$VMRUN_BIN" -T fusion list 2>/dev/null | tail -n +2 | grep -Fxq "$VMX"
}

has_snapshot() {
  [ "$DRY_RUN" = 1 ] && return 1
  "$VMRUN_BIN" -T fusion listSnapshots "$VMX" 2>/dev/null | tail -n +2 | grep -Fxq "$1"
}

ssh_() {
  run ssh -F "$SSH_CONFIG" "$SSH_HOST" "$@"
}

# ---------------------------------------------------------------------------
# doctor -- runs on a Mac with nothing installed and says what is missing.
# ---------------------------------------------------------------------------
cmd_doctor() {
  echo '=== host-vm doctor (macOS side preflight) ==='
  echo
  echo 'Host:'
  info "$(sw_vers -productName) $(sw_vers -productVersion) ($(uname -m))"
  local ram_gib free_gib
  ram_gib=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  info "RAM ${ram_gib} GiB, $(sysctl -n hw.ncpu) logical CPUs"
  free_gib=$(df -g / | awk 'NR==2 {print $4}')
  info "free disk on / : ${free_gib} GiB"
  echo
  echo 'Preconditions:'

  if [ "$ram_gib" -ge "$MIN_HOST_RAM_GIB" ]; then
    ok "host RAM ${ram_gib} GiB (>= ${MIN_HOST_RAM_GIB} GiB)"
  else
    warn "host RAM ${ram_gib} GiB is below ${MIN_HOST_RAM_GIB} GiB -- see runbook 1.3 for guest sizing"
  fi

  if [ "$free_gib" -ge "$MIN_FREE_GIB" ]; then
    ok "free disk ${free_gib} GiB (>= ${MIN_FREE_GIB} GiB)"
  else
    bad "free disk ${free_gib} GiB is below the ${MIN_FREE_GIB} GiB the ISO + guest + one snapshot need (runbook 1.3). Free space or host the VM bundle on external storage before creating the VM."
  fi

  if [ -d "/Applications/VMware Fusion.app" ]; then
    ok "VMware Fusion installed"
  else
    bad "VMware Fusion not installed (runbook 1.1)"
  fi

  if [ -x "$VMRUN_BIN" ]; then
    ok "vmrun at $VMRUN_BIN"
  else
    bad "vmrun missing at $VMRUN_BIN (ships with Fusion)"
  fi

  if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
    ok "Windows 11 Arm64 ISO at $ISO_PATH"
  else
    bad "no Windows 11 Arm64 ISO (set W17_ISO once downloaded -- runbook 1.2)"
  fi

  if [ -n "$VMX" ] && [ -f "$VMX" ]; then
    ok "VMX at $VMX"
  else
    bad "no VMX yet (set W17_VMX after Fusion creates the VM -- runbook 2.1)"
  fi

  if [ -f "$HOME/.ssh/w17vm_ed25519" ]; then
    ok "ssh key ~/.ssh/w17vm_ed25519"
  else
    bad "no ssh key -- ssh-keygen -t ed25519 -f ~/.ssh/w17vm_ed25519 -C w17-vm (runbook 1.5)"
  fi

  # Deliberately a plain word match rather than \< ... \> : BSD grep on macOS
  # does not take GNU's word-boundary escapes.
  if [ -f "$SSH_CONFIG" ] && awk -v h="$SSH_HOST" '
        tolower($1) == "host" { for (i = 2; i <= NF; i++) if ($i == h) { found = 1 } }
        END { exit found ? 0 : 1 }' "$SSH_CONFIG"; then
    ok "ssh config has a '$SSH_HOST' entry"
  else
    bad "no '$SSH_HOST' entry in $SSH_CONFIG (runbook 1.5)"
  fi

  echo
  echo 'Nothing above was changed. Every BLOCKED line is an owner action.'
}

cmd_status() {
  need_vmx
  if is_running; then echo "running: $VMX"; else echo "not running: $VMX"; fi
}

cmd_start() {
  need_vmx
  if is_running; then info "already running -- nothing to do"; return 0; fi
  vmrun_ start "$VMX" nogui
}

cmd_stop() {
  need_vmx
  if ! is_running; then info "not running -- nothing to do"; return 0; fi
  vmrun_ stop "$VMX" soft
}

cmd_snapshots() { need_vmx; vmrun_capture listSnapshots "$VMX"; }

cmd_snapshot() {
  local name="${1:-}"; [ -n "$name" ] || die "snapshot NAME required"
  need_vmx
  if has_snapshot "$name"; then info "snapshot '$name' already exists -- not retaken"; return 0; fi
  vmrun_ snapshot "$VMX" "$name"
}

cmd_revert() {
  local name="${1:-}"; [ -n "$name" ] || die "revert NAME required"
  need_vmx
  if [ "$DRY_RUN" != 1 ] && ! has_snapshot "$name"; then
    die "snapshot '$name' does not exist. '$0 snapshots' lists what does."
  fi
  if is_running; then vmrun_ stop "$VMX" soft || vmrun_ stop "$VMX" hard; fi
  vmrun_ revertToSnapshot "$VMX" "$name"
}

cmd_screenshot() {
  need_vmx
  local out="${1:-$EVIDENCE_ROOT/screen-$(date -u +%Y%m%dT%H%M%SZ).png}"
  run mkdir -p "$(dirname "$out")"
  vmrun_ captureScreen "$VMX" "$out"
  info "$out"
}

cmd_ip() { need_vmx; vmrun_capture getGuestIPAddress "$VMX" -wait; }

cmd_ssh() {
  if [ "$#" -eq 0 ]; then run ssh -F "$SSH_CONFIG" "$SSH_HOST"; else ssh_ "$@"; fi
}

cmd_push() {
  local src="${1:-}" dst="${2:-}"
  [ -n "$src" ] && [ -n "$dst" ] || die "push LOCAL REMOTE"
  run scp -F "$SSH_CONFIG" -r "$src" "$SSH_HOST:$dst"
}

cmd_pull() {
  local src="${1:-}" dst="${2:-}"
  [ -n "$src" ] && [ -n "$dst" ] || die "pull REMOTE LOCAL"
  run mkdir -p "$dst"
  run scp -F "$SSH_CONFIG" -r "$SSH_HOST:$src" "$dst"
}

# bootstrap PUBKEY NATSUBNET -- stages guest-bootstrap.ps1 + the public key on
# the guest over SSH and prints the elevated command to run there.
#
# CHICKEN AND EGG: this verb needs SSH, and SSH is what guest-bootstrap.ps1
# sets up. So the FIRST bootstrap is done at the guest console, with the two
# files carried in over a Fusion shared folder or drag-and-drop (runbook
# 1.0 step 11). This verb is for every run after that -- re-scoping the
# firewall rule, adding a second key, or re-checking idempotency.
cmd_bootstrap() {
  local key="${1:-}" subnet="${2:-}"
  [ -n "$key" ] && [ -n "$subnet" ] || die "bootstrap PUBLIC_KEY_FILE NAT_SUBNET_CIDR  (e.g. ~/.ssh/w17vm_ed25519.pub 192.168.230.0/24)"
  [ "$DRY_RUN" = 1 ] || [ -f "$key" ] || die "public key '$key' not found"
  ssh_ "cmd /c mkdir \"$GUEST_ROOT\\scripts\\vm\" 2>nul & exit 0"
  run scp -F "$SSH_CONFIG" "$SCRIPT_DIR/guest-bootstrap.ps1" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\"
  run scp -F "$SSH_CONFIG" "$key" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\w17vm.pub"
  echo 'guest-bootstrap.ps1 must run ELEVATED. It is staged at'
  echo "  $GUEST_ROOT\\scripts\\vm\\guest-bootstrap.ps1"
  echo 'Run it from an elevated console in the guest (runbook 1.5):'
  echo "  pwsh -NoProfile -File $GUEST_ROOT\\scripts\\vm\\guest-bootstrap.ps1 -NatSubnet $subnet -PublicKeyPath $GUEST_ROOT\\scripts\\vm\\w17vm.pub"
  echo 'It is idempotent -- re-running it changes nothing already correct.'
}

cmd_check() {
  local out="${1:-$EVIDENCE_ROOT/$(date -u +%Y%m%dT%H%M%SZ)}"
  run mkdir -p "$out"
  ssh_ "cmd /c mkdir \"$GUEST_ROOT\\scripts\\vm\" 2>nul & exit 0"
  run scp -F "$SSH_CONFIG" "$SCRIPT_DIR/guest-check.ps1" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\"
  ssh_ "pwsh -NoProfile -File $GUEST_ROOT\\scripts\\vm\\guest-check.ps1 -EvidencePath $GUEST_ROOT\\evidence\\guest-check.json"
  run scp -F "$SSH_CONFIG" "$SSH_HOST:$GUEST_ROOT\\evidence\\guest-check.json" "$out/"
  info "$out/guest-check.json"
}

# suite -- the automatable part of runbook 3 only.
cmd_suite() {
  local stamp out
  stamp="$(date -u +%Y%m%dT%H%M%SZ)"
  out="$EVIDENCE_ROOT/$stamp"
  run mkdir -p "$out"
  echo 'Running run-all.ps1 WITHOUT -IncludeHidTransition.'
  echo 'Step 7 (60-hid-transition.ps1) is human-in-the-loop and has a safety'
  echo 'precondition -- car UNPOWERED or RX UNBOUND (runbook 3.1). This'
  echo 'wrapper never starts it; run it deliberately, by hand, over ssh -t.'
  ssh_ "pwsh -NoProfile -File $GUEST_ROOT\\scripts\\windows-validation\\run-all.ps1 -ResultsRoot $GUEST_ROOT\\results $*"
  run scp -F "$SSH_CONFIG" -r "$SSH_HOST:$GUEST_ROOT\\results" "$out/"
  info "$out/results"
}

# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --vmx)        VMX="${2:-}"; shift 2 ;;
    --host)       SSH_HOST="${2:-}"; shift 2 ;;
    --ssh-config) SSH_CONFIG="${2:-}"; shift 2 ;;
    --evidence)   EVIDENCE_ROOT="${2:-}"; shift 2 ;;
    -h|--help)    sed -n '2,60p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --)           shift; break ;;
    -*)           die "unknown flag '$1' (try --help)" ;;
    *)            break ;;
  esac
done

VERB="${1:-}"; [ -n "$VERB" ] || { sed -n '2,60p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
shift

case "$VERB" in
  doctor)     cmd_doctor "$@" ;;
  status)     cmd_status "$@" ;;
  start)      cmd_start "$@" ;;
  stop)       cmd_stop "$@" ;;
  snapshots)  cmd_snapshots "$@" ;;
  snapshot)   cmd_snapshot "$@" ;;
  revert)     cmd_revert "$@" ;;
  screenshot) cmd_screenshot "$@" ;;
  ip)         cmd_ip "$@" ;;
  ssh)        cmd_ssh "$@" ;;
  push)       cmd_push "$@" ;;
  pull)       cmd_pull "$@" ;;
  bootstrap)  cmd_bootstrap "$@" ;;
  check)      cmd_check "$@" ;;
  suite)      cmd_suite "$@" ;;
  *)          die "unknown verb '$VERB' (try --help)" ;;
esac
