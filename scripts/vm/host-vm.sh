#!/usr/bin/env bash
#
# host-vm.sh — the Mac side of the W17 Windows-VM validation loop.
#
# One wrapper around `vmrun` + `ssh`/`scp` so a validation session is a
# sequence of named, idempotent verbs instead of hand-typed paths. Every verb
# is safe to re-run; `--dry-run` prints the exact commands and executes none.
#
# Read `w17-windows-vm-validation-runbook.md` (workspace root) first. This
# script implements §2.1 (vmrun lifecycle), §2.2 (ssh invocation), §2.3
# (staging the suite onto the guest) and §4.1 (evidence layout); it does not
# replace the one-time owner setup in §1.
#
# SAFETY (workspace CLAUDE.md rules 1-7). Nothing here flashes, powers, or
# connects hardware, and nothing opens a serial port. `suite` forwards an
# ALLOW-LIST of run-all.ps1 parameters and exits 2 on anything else — so
# -IncludeHidTransition, -HidTransitionNonInteractive and every ASCII
# spelling PowerShell binds to them (-Inc, -Hid, -INC, --Inc, -hid:$true …)
# are refused; non-ASCII dash forms (en dash, em dash, horizontal bar) abort
# binding before the script runs rather than being caught by this guard's own
# case match, which is ASCII-only (verified V-A3: every one of those tokens
# either falls to the guard's positional refusal, or — in the one slot that
# passes it — is read by PowerShell itself as a new parameter name, which
# starves the parameter it followed of its value and aborts before the
# script body runs). Step 7 needs a human at the DS4 cable AND the car
# unpowered / RX unbound (runbook §3.1), so it is never something this
# wrapper starts on its own. That refusal is ENFORCED in suite_guard(), not
# merely asserted in this header, and `host-vm.sh selftest` re-proves it on
# demand, host-only.
# A VM result is never physical proof: A2 stays NOT-EXECUTED, Phase B stays
# BLOCKED, R15 stays NO-GO.
#
# Requirements on the Mac: VMware Fusion (for `vmrun`) and an OpenSSH client
# (`ssh` and `scp`). `doctor` reports which of those are missing without
# needing any of them.
#
# Usage:
#   scripts/vm/host-vm.sh [--dry-run] [--vmx PATH] [--host ALIAS]
#                         [--ssh-config PATH] [--evidence DIR]
#                         [--session STAMP] [--interactive] <verb> [args...]
#
# Verbs:
#   doctor                 host preflight: Fusion, vmrun, RAM, free disk, ISO,
#                          ssh client, ssh key, ssh config entry. Runs with
#                          nothing installed.
#   status                 is the VM registered / running?
#   start                  power on headless (no-op if already running)
#   stop                   graceful guest shutdown (no-op if not running)
#   snapshots              list snapshots
#   snapshot NAME [--live] take snapshot NAME (no-op if NAME already exists;
#                          refuses a RUNNING VM without --live — see cmd_snapshot)
#   revert NAME            revert to snapshot NAME (VM is powered off first)
#   screenshot [PATH]      capture the guest console into the session directory
#   ip                     guest IP as VMware Tools reports it
#   ssh [CMD...]           ssh to the guest (interactive with no CMD)
#   push LOCAL REMOTE      scp a file/dir to the guest
#   pull REMOTE LOCAL      scp a file/dir back from the guest
#   stage                  copy w17-ground-station/scripts/windows-validation/
#                          to the guest. NOTHING else puts it there, and every
#                          `suite` / runbook §3 command runs run-all.ps1 from
#                          it. `suite` calls it before running; `check` calls
#                          it AFTER capturing guest-check.json.
#   bootstrap KEY SUBNET [MSI]
#                          copy guest-bootstrap.ps1 + the public key (and, if
#                          given, the pwsh MSI) to the guest and print the
#                          ELEVATED command to run there
#   check [OUTDIR]         copy + run guest-check.ps1 and pull its JSON (plus
#                          guest-bootstrap.json, if present) back, THEN stage.
#                          OPENS the evidence session (§4.1). Nothing but
#                          guest-check.ps1 itself reaches the guest before its
#                          state is captured.
#   suite [EXTRA...]       run-all.ps1 for the automatable steps only, into
#                          this session's own guest results root, then pull
#                          that run's results into the session directory.
#                          EXTRA is allow-listed -- see cmd_suite()
#   selftest               host-only regression test of that allow-list
#                          (needs no VM, no Fusion, no ssh)
#
# Configuration, in precedence order: flags, then environment, then
# ~/.w17vm.conf (plain `KEY=value` lines, sourced).
#   W17_VMX          absolute path to the .vmx
#   W17_SSH_HOST     ssh alias/host (default: w17vm)
#   W17_SSH_CONFIG   ssh config file (default: ~/.ssh/config)
#   W17_GUEST_ROOT   guest install root (default: C:\w17)
#   W17_EVIDENCE     local evidence root (default: ./evidence)
#   W17_ISO          path to the Windows 11 Arm64 ISO (doctor only)
#   W17_SESSION      evidence session stamp (default: the one `check` opened)
#   W17_VALIDATION_SRC  the windows-validation directory `stage` copies
#   VMRUN            override the vmrun binary
#
set -euo pipefail

DRY_RUN=0
INTERACTIVE=0
VMX="${W17_VMX:-}"
SSH_HOST="${W17_SSH_HOST:-w17vm}"
SSH_CONFIG="${W17_SSH_CONFIG:-$HOME/.ssh/config}"
GUEST_ROOT="${W17_GUEST_ROOT:-C:\\w17}"
EVIDENCE_ROOT="${W17_EVIDENCE:-$PWD/evidence}"
ISO_PATH="${W17_ISO:-}"
SESSION="${W17_SESSION:-}"
VMRUN_BIN="${VMRUN:-/Applications/VMware Fusion.app/Contents/Public/vmrun}"
CONF="$HOME/.w17vm.conf"

# Minimum free host disk doctor demands before it will call the disk
# precondition met, in DECIMAL GB -- deliberately the same unit as runbook
# §1.3's budget table, which sums vendor-stated decimal GB figures. An earlier
# version compared `df -g` (GiB) against that table and so silently demanded
# 75.2 GB. Derived in §1.3 from the ISO (~6.5 GB), the guest footprint and one
# snapshot's delta -- NOT from a measured install, so it is a floor to plan
# against, not an observation.
MIN_FREE_GB=70
MIN_HOST_RAM_GIB=16

if [ -f "$CONF" ]; then
  # Precedence is flags > environment > conf. Sourcing the conf OVERWRITES the
  # W17_* environment variables before the ${W17_X:-$X} expansions below can
  # read them, which silently inverted the last two -- so the environment's
  # values are captured first and win afterwards.
  ENV_VMX="${W17_VMX:-}"
  ENV_SSH_HOST="${W17_SSH_HOST:-}"
  ENV_SSH_CONFIG="${W17_SSH_CONFIG:-}"
  ENV_GUEST_ROOT="${W17_GUEST_ROOT:-}"
  ENV_EVIDENCE="${W17_EVIDENCE:-}"
  ENV_ISO="${W17_ISO:-}"
  ENV_SESSION="${W17_SESSION:-}"
  ENV_VALIDATION_SRC="${W17_VALIDATION_SRC:-}"
  # shellcheck disable=SC1090
  . "$CONF"
  VMX="${ENV_VMX:-${W17_VMX:-$VMX}}"
  SSH_HOST="${ENV_SSH_HOST:-${W17_SSH_HOST:-$SSH_HOST}}"
  SSH_CONFIG="${ENV_SSH_CONFIG:-${W17_SSH_CONFIG:-$SSH_CONFIG}}"
  GUEST_ROOT="${ENV_GUEST_ROOT:-${W17_GUEST_ROOT:-$GUEST_ROOT}}"
  EVIDENCE_ROOT="${ENV_EVIDENCE:-${W17_EVIDENCE:-$EVIDENCE_ROOT}}"
  ISO_PATH="${ENV_ISO:-${W17_ISO:-$ISO_PATH}}"
  SESSION="${ENV_SESSION:-${W17_SESSION:-$SESSION}}"
  W17_VALIDATION_SRC="${ENV_VALIDATION_SRC:-${W17_VALIDATION_SRC:-}}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The validation suite lives in the w17-ground-station repo, beside this one.
VALIDATION_SRC="${W17_VALIDATION_SRC:-$SCRIPT_DIR/../../w17-ground-station/scripts/windows-validation}"

die()  { printf 'host-vm: %s\n' "$*" >&2; exit 2; }
info() { printf '  %s\n' "$*"; }
ok()   { printf 'OK      %s\n' "$*"; }
bad()  { printf 'BLOCKED %s\n' "$*"; }
# STDERR, deliberately. warn() is called from session_stamp(), which callers
# read through `$(...)` -- on stdout the warning text became PART OF the
# session stamp, so `suite` with no open session built a guest ResultsRoot
# containing spaces and an embedded newline and sent it through a cmd.exe
# login shell. A diagnostic must never be able to contaminate a value.
# (info/ok/bad stay on stdout: they are this script's report, and no function
# that calls them is read through a command substitution -- keep it that way.)
warn() { printf 'WARN    %s\n' "$*" >&2; }

# Non-interactive by construction. The autonomous-drive design (runbook §2) is
# `ssh` with nobody at the console, and the exact failure §1.5 predicts -- a
# key in the wrong authorized_keys file, or an ACL sshd refuses -- surfaces as
# a PASSWORD PROMPT, which blocks forever under an unattended run and "looks
# like success". BatchMode turns it into `Permission denied (publickey)` in
# ConnectTimeout seconds. So does the first-connect host-key question, which
# accept-new answers once. `--interactive` drops BatchMode for the one
# deliberate case: an `ssh -t` step-7 session with a human present.
SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new)
SSH_OPTS_INTERACTIVE=(-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new)

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
  [ -n "$VMX" ] || die "no VMX path. Pass --vmx PATH, set W17_VMX (QUOTE IT -- Fusion's default path contains a space), or put W17_VMX=... in $CONF."
  [ "$DRY_RUN" = 1 ] || [ -f "$VMX" ] || die "VMX '$VMX' does not exist. Fusion's default path contains a space ('~/Virtual Machines.localized/...'), so an unquoted 'export W17_VMX=...' sets the wrong value -- quote it."
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
  if [ "$INTERACTIVE" = 1 ]; then
    run ssh -t "${SSH_OPTS_INTERACTIVE[@]}" -F "$SSH_CONFIG" "$SSH_HOST" "$@"
  else
    run ssh "${SSH_OPTS[@]}" -F "$SSH_CONFIG" "$SSH_HOST" "$@"
  fi
}

scp_() {
  if [ "$INTERACTIVE" = 1 ]; then
    run scp "${SSH_OPTS_INTERACTIVE[@]}" -F "$SSH_CONFIG" "$@"
  else
    run scp "${SSH_OPTS[@]}" -F "$SSH_CONFIG" "$@"
  fi
}

# ---------------------------------------------------------------------------
# Evidence session (runbook §4.1 rule 1): ONE directory per session, shared by
# check, suite and screenshot. Each of those used to mint its OWN `date -u`
# stamp, which scattered a single session across three directories and so
# defeated rule 2 (a results directory without guest-check.json cannot be
# interpreted later). `check` OPENS the session and records the stamp in
# evidence/.current-session; `suite` and `screenshot` reuse it. --session
# STAMP (or W17_SESSION) overrides.
# ---------------------------------------------------------------------------
session_stamp() {
  if [ -z "$SESSION" ] && [ -f "$EVIDENCE_ROOT/.current-session" ]; then
    SESSION="$(cat "$EVIDENCE_ROOT/.current-session")"
  fi
  if [ -z "$SESSION" ]; then
    SESSION="$(date -u +%Y%m%dT%H%M%SZ)"
    warn "no open evidence session -- minted '$SESSION'. Runbook 4.1 rule 2: run '$0 check' FIRST, so guest-check.json lands in the same directory."
  fi
  printf '%s\n' "$SESSION"
}

session_open() {
  if [ -z "$SESSION" ]; then SESSION="$(date -u +%Y%m%dT%H%M%SZ)"; fi
  if [ "$DRY_RUN" != 1 ]; then
    mkdir -p "$EVIDENCE_ROOT"
    printf '%s\n' "$SESSION" > "$EVIDENCE_ROOT/.current-session"
  fi
  printf '%s\n' "$SESSION"
}

# Runbook §4.1 rule 4: a session is not finished without these four lines, and
# they are invisible in any exit code. Scaffold them so they cannot be
# forgotten; never overwrite one that already has content.
notes_scaffold() {
  local dir="$1" stamp="$2"
  if [ "$DRY_RUN" = 1 ]; then info "DRY-RUN: would scaffold $dir/NOTES.md"; return 0; fi
  if [ -f "$dir/NOTES.md" ]; then return 0; fi
  cat > "$dir/NOTES.md" <<EOF
# W17 VM validation session $stamp

Runbook §4.1 rule 4 — fill all four in before calling this session finished.

## Snapshot this session started from
<clean-giftee-pc, or which other>

## Artifacts staged, and from which CI run
<the w17-ground-station-nsis-unsigned artifact + its GitHub Actions run URL; the mapper zip>

## USB devices passed through
<FT232RL / DualShock 4 / AP-capable Wi-Fi adapter — and which did NOT land>

## Steps skipped, and why
<run-all.ps1 SKIPS, never fails, a step it lacks parameters for, so a skip is
invisible in the exit code. 30-hotspot.ps1 and 40's hotspot half do not run on
this VM at all (§1.9) — say so here rather than leaving a silent gap.>
EOF
  info "$dir/NOTES.md (scaffold — rule 4 lines are still yours to fill in)"
}

# ---------------------------------------------------------------------------
# doctor -- runs on a Mac with nothing installed and says what is missing.
# ---------------------------------------------------------------------------
cmd_doctor() {
  echo '=== host-vm doctor (macOS side preflight) ==='
  echo
  echo 'Host:'
  info "$(sw_vers -productName) $(sw_vers -productVersion) ($(uname -m))"
  local ram_gib free_gb df_line
  ram_gib=$(( $(sysctl -n hw.memsize) / 1073741824 ))
  info "RAM ${ram_gib} GiB, $(sysctl -n hw.ncpu) logical CPUs"
  # DECIMAL GB, to match runbook 1.3's table. The raw `df -h` line is printed
  # too, so the owner sees the same string the runbook quotes and does not
  # have to reconcile two numerals for one fact. macOS reports three different
  # "free" figures (df, container free, and free-without-reclaiming-purgeable);
  # this is the df one.
  df_line="$(df -h / | awk 'NR==2')"
  free_gb=$(df -k / | awk 'NR==2 {printf "%.0f", $4 * 1024 / 1000000000}')
  info "free disk on / : ${free_gb} GB (decimal)"
  info "df -h / : $df_line"
  echo
  echo 'Preconditions:'

  if [ "$ram_gib" -ge "$MIN_HOST_RAM_GIB" ]; then
    ok "host RAM ${ram_gib} GiB (>= ${MIN_HOST_RAM_GIB} GiB)"
  else
    warn "host RAM ${ram_gib} GiB is below ${MIN_HOST_RAM_GIB} GiB -- see runbook 1.3 for guest sizing"
  fi

  if [ "$free_gb" -ge "$MIN_FREE_GB" ]; then
    ok "free disk ${free_gb} GB (>= ${MIN_FREE_GB} GB, decimal — runbook 1.3)"
  else
    bad "free disk ${free_gb} GB against the ${MIN_FREE_GB} GB (decimal) the ISO + guest + one snapshot need (runbook 1.3). FREE ABOUT $(( MIN_FREE_GB - free_gb )) GB MORE, or host the VM bundle on external APFS/HFS+ storage, before creating the VM."
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

  # The header claims doctor reports a missing OpenSSH client; it now does.
  if command -v ssh >/dev/null 2>&1 && command -v scp >/dev/null 2>&1; then
    ok "OpenSSH client ($(command -v ssh), $(command -v scp))"
  else
    bad "OpenSSH client incomplete: ssh $(command -v ssh >/dev/null 2>&1 && echo present || echo MISSING), scp $(command -v scp >/dev/null 2>&1 && echo present || echo MISSING). Every verb after 'start' needs both."
  fi

  if [ -n "$ISO_PATH" ] && [ -f "$ISO_PATH" ]; then
    ok "Windows 11 Arm64 ISO at $ISO_PATH"
  else
    bad "no Windows 11 Arm64 ISO (set W17_ISO once downloaded -- runbook 1.2)"
  fi

  if [ -n "$VMX" ] && [ -f "$VMX" ]; then
    ok "VMX at $VMX"
  else
    bad "no VMX yet (set W17_VMX after Fusion creates the VM -- runbook 2.1; QUOTE the path, Fusion's default contains a space)"
  fi

  if [ -d "$VALIDATION_SRC" ]; then
    ok "validation suite to stage: $VALIDATION_SRC"
  else
    bad "no validation suite at $VALIDATION_SRC. It lives in the w17-ground-station repo -- check that repo out beside this one, or set W17_VALIDATION_SRC. Without it 'stage' and 'suite' cannot run (runbook 2.3)."
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
  local name='' live=0 a
  for a in "$@"; do
    case "$a" in
      --live) live=1 ;;
      *)      [ -n "$name" ] && die "snapshot takes ONE name (got '$name' and '$a')"; name="$a" ;;
    esac
  done
  [ -n "$name" ] || die "snapshot NAME [--live] required"
  need_vmx
  if has_snapshot "$name"; then info "snapshot '$name' already exists -- not retaken"; return 0; fi
  # A snapshot of a RUNNING VM captures MEMORY as well as disk: runbook 1.3
  # sizes the guest at 8 GB, so that is an ~8 GB .vmem written to a host whose
  # free disk is this program's hardest blocker -- and 1.3's "~5-15 GB
  # snapshot delta" row does not include it. Reverting to a live snapshot also
  # restores a powered-ON VM, which makes the documented `revert && start`
  # chain fail with "already powered on".
  if [ "$live" != 1 ] && is_running; then
    die "the VM is RUNNING. A live snapshot writes an ~8 GB memory image the runbook 1.3 disk budget does not account for, and reverting to it restores a powered-ON state. Run '$0 stop' first (runbook 1.7), or pass --live if you deliberately want the memory state."
  fi
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
  local stamp out
  stamp="$(session_stamp)"
  # INSIDE the session directory, not one level above it (runbook 4.1).
  out="${1:-$EVIDENCE_ROOT/$stamp/screen-$(date -u +%Y%m%dT%H%M%SZ).png}"
  run mkdir -p "$(dirname "$out")"
  vmrun_ captureScreen "$VMX" "$out"
  info "$out"
}

cmd_ip() { need_vmx; vmrun_capture getGuestIPAddress "$VMX" -wait; }

cmd_ssh() {
  if [ "$#" -eq 0 ]; then
    run ssh "${SSH_OPTS_INTERACTIVE[@]}" -F "$SSH_CONFIG" "$SSH_HOST"
  else
    ssh_ "$@"
  fi
}

cmd_push() {
  local src="${1:-}" dst="${2:-}"
  [ -n "$src" ] && [ -n "$dst" ] || die "push LOCAL REMOTE"
  scp_ -r "$src" "$SSH_HOST:$dst"
}

cmd_pull() {
  local src="${1:-}" dst="${2:-}"
  [ -n "$src" ] && [ -n "$dst" ] || die "pull REMOTE LOCAL"
  run mkdir -p "$dst"
  scp_ -r "$SSH_HOST:$src" "$dst"
}

# stage -- put the validation suite on the guest.
#
# Nothing else does. Runbook §1.0 step 11 carries three files (the public key,
# the pwsh MSI, guest-bootstrap.ps1); §2.3 covers only the GS installer and the
# mapper bundle; and every §3 row plus `suite` runs
# C:\w17\scripts\windows-validation\run-all.ps1. Without this verb the first
# `suite` after a by-the-book §1.0 dies on a missing file.
STAGE_DONE=0
cmd_stage() {
  if [ "$STAGE_DONE" = 1 ]; then return 0; fi
  if [ ! -d "$VALIDATION_SRC" ]; then
    if [ "$DRY_RUN" = 1 ]; then
      warn "validation suite not found at '$VALIDATION_SRC' -- dry run continues, the scp is printed only"
    else
      die "validation suite not found at '$VALIDATION_SRC'. It lives in the w17-ground-station repo, which a workspace-root worktree does not check out. Check that repo out beside this one, or set W17_VALIDATION_SRC to its scripts/windows-validation directory."
    fi
  fi
  ssh_ "cmd /c mkdir \"$GUEST_ROOT\\scripts\" 2>nul & exit 0"
  scp_ -r "$VALIDATION_SRC" "$SSH_HOST:$GUEST_ROOT\\scripts\\"
  STAGE_DONE=1
  info "staged $VALIDATION_SRC -> $GUEST_ROOT\\scripts\\windows-validation"
}

# bootstrap PUBKEY NATSUBNET [PWSH_MSI] -- stages guest-bootstrap.ps1, the
# public key and (optionally) the PowerShell 7 ARM64 MSI on the guest over
# SSH, and prints the elevated command to run there.
#
# CHICKEN AND EGG: this verb needs SSH, and SSH is what guest-bootstrap.ps1
# sets up. So the FIRST bootstrap is done at the guest console, with the files
# carried in over a Fusion shared folder or drag-and-drop (runbook 1.0 step
# 11). This verb is for every run after that -- re-scoping the firewall rule,
# adding a second key, or re-checking idempotency.
cmd_bootstrap() {
  local key="${1:-}" subnet="${2:-}" msi="${3:-}" msi_arg='' user_arg='' sshuser=''
  [ -n "$key" ] && [ -n "$subnet" ] || die "bootstrap PUBLIC_KEY_FILE NAT_SUBNET_CIDR [PWSH_ARM64_MSI]  (e.g. ~/.ssh/w17vm_ed25519.pub 192.168.230.0/24 ~/Downloads/PowerShell-7.6.5-win-arm64.msi)"
  [ "$DRY_RUN" = 1 ] || [ -f "$key" ] || die "public key '$key' not found"
  [ -z "$msi" ] || [ "$DRY_RUN" = 1 ] || [ -f "$msi" ] || die "pwsh MSI '$msi' not found"
  ssh_ "cmd /c mkdir \"$GUEST_ROOT\\scripts\\vm\" 2>nul & exit 0"
  scp_ "$SCRIPT_DIR/guest-bootstrap.ps1" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\"
  scp_ "$key" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\w17vm.pub"
  if [ -n "$msi" ]; then
    ssh_ "cmd /c mkdir \"$GUEST_ROOT\\dist\" 2>nul & exit 0"
    scp_ "$msi" "$SSH_HOST:$GUEST_ROOT\\dist\\"
    msi_arg=" -PwshMsiPath $GUEST_ROOT\\dist\\$(basename "$msi")"
  fi
  # The account that will LOG IN over ssh is not necessarily the elevated
  # identity guest-bootstrap.ps1 runs as, and the two read DIFFERENT
  # authorized_keys files. Take it from the ssh config so the key lands in the
  # file sshd will actually read for that login.
  if command -v ssh >/dev/null 2>&1; then
    sshuser="$(ssh -G -F "$SSH_CONFIG" "$SSH_HOST" 2>/dev/null | awk '$1 == "user" { print $2; exit }')" || sshuser=''
  fi
  [ -z "$sshuser" ] || user_arg=" -SshUser $sshuser"
  echo 'guest-bootstrap.ps1 must run ELEVATED. It is staged at'
  echo "  $GUEST_ROOT\\scripts\\vm\\guest-bootstrap.ps1"
  echo 'Run it from an elevated console in the guest (runbook 1.5). Use'
  echo 'powershell.exe (5.1), NOT pwsh: this script is what installs pwsh 7.'
  echo "  powershell -ExecutionPolicy Bypass -File $GUEST_ROOT\\scripts\\vm\\guest-bootstrap.ps1 -NatSubnet $subnet -PublicKeyPath $GUEST_ROOT\\scripts\\vm\\w17vm.pub${msi_arg}${user_arg}"
  if [ -z "$msi" ]; then
    echo 'NOTE: no MSI path given, so the pwsh 7 step will be SKIPPED. Pass the'
    echo '      ARM64 MSI as the third argument (runbook 1.6) unless pwsh 7 is'
    echo '      already installed from the machine-wide MSI.'
  fi
  echo 'It is idempotent -- re-running it changes nothing already correct.'
  echo 'Exit codes: 0 OK · 1 a step FAILED · 2 not elevated · 3 not Windows ·'
  echo '            4 configured, but a posture action is OUTSTANDING (read it).'
}

# check -- capture the guest's state FIRST, then stage.
#
# ORDER IS LOAD-BEARING (runbook §4.1 rule 2, §2.3, §5): guest-check.json is the
# only record of what the guest looked like UNMODIFIED, so nothing this wrapper
# installs or stages may precede it. `stage` used to run at the TOP of this
# function, which made three sentences in the runbook false. It runs at the end
# instead -- `suite` needs the suite staged, `check` does not, and the session
# still ends with both the capture and the staging done.
#
# The one thing that does precede the capture is guest-check.ps1 itself, copied
# to C:\w17\scripts\vm\. It has to be: it is the measuring instrument. It
# installs nothing and writes only its own JSON.
cmd_check() {
  local stamp out
  stamp="$(session_open)"
  out="${1:-$EVIDENCE_ROOT/$stamp}"
  run mkdir -p "$out"
  ssh_ "cmd /c mkdir \"$GUEST_ROOT\\scripts\\vm\" 2>nul & exit 0"
  scp_ "$SCRIPT_DIR/guest-check.ps1" "$SSH_HOST:$GUEST_ROOT\\scripts\\vm\\"
  ssh_ "pwsh -NoProfile -File $GUEST_ROOT\\scripts\\vm\\guest-check.ps1 -EvidencePath $GUEST_ROOT\\evidence\\guest-check.json"
  scp_ "$SSH_HOST:$GUEST_ROOT\\evidence\\guest-check.json" "$out/"
  # guest-bootstrap.json is the only record of the firewall scope, the ACL and
  # the pwsh install (runbook 4.1). It does not exist until guest-bootstrap.ps1
  # has run once, so its absence is reported, never fatal.
  scp_ "$SSH_HOST:$GUEST_ROOT\\evidence\\guest-bootstrap.json" "$out/" \
    || info "no guest-bootstrap.json on the guest yet (runbook 1.0 step 12 has not run there) -- not fatal"
  notes_scaffold "$out" "$stamp"
  info "$out/guest-check.json"
  # Only now: the guest's un-modified state is already captured and pulled.
  cmd_stage
}

# ---------------------------------------------------------------------------
# suite -- the automatable part of runbook 3 only.
#
# THE STEP-7 REFUSAL IS AN ALLOW-LIST, NOT A DENY-LIST.
#
# The first version of this guard matched four exact-case literals
# (-IncludeHidTransition / -HidTransitionNonInteractive, bare and :value).
# That is not enough, because bash `case` and PowerShell parameter binding
# disagree in two ways: PowerShell is case-INSENSITIVE, and it binds any
# UNAMBIGUOUS PREFIX of a parameter name. VERIFIED on this Mac (pwsh
# 7.7.0-preview.4) against a replica of run-all.ps1's param block: `-Inc`,
# `-INC`, `-includehidtransition`, `--Inc`, `--IncludeHidTransition` and
# `-includehidtransition:$true` all set -IncludeHidTransition; `-Hid` and
# `-hid` set -HidTransitionNonInteractive; and the pair `-Inc -Hid` runs step 7
# NON-INTERACTIVELY. Every one of those walked straight through the literal
# guard while the banner below still said the switch had not been passed.
#
# So this verb no longer tries to enumerate what to refuse. It forwards ONLY
# the parameters named in SUITE_ALLOWED_PARAMS, spelled in FULL, and dies
# (exit 2) on anything else. Over-refusal is free -- it costs one clear error
# message, and `--interactive ssh` is right there for anything exotic. Under-
# refusal is a safety defect. The two step-7 switches are additionally refused
# by prefix, ahead of the allow-list, so that they get their own message.
#
# Three facts about PowerShell binding this guard depends on, each VERIFIED the
# same way:
#   * `-Name:value` binds; `-Name=value` does NOT -- but it does not error
#     either. `pwsh -File` (the only mode this wrapper uses) silently ignores
#     the whole token and runs with that parameter left unset (V-A3 V3-4:
#     verified on macOS pwsh 7.7.0-preview.4; `-File` argument handling is
#     shared cross-platform, so Windows is INFERRED identical). That makes
#     refusing it here MORE valuable than a bind error would be -- a
#     `-Ssid=W17-GRID` typo would otherwise run the whole suite against the
#     default SSID with nothing on stderr. The name is therefore everything
#     before the first ':' or '='.
#   * A token starting with '-' is ALWAYS read as a parameter name, never as
#     the preceding parameter's value: `-Password -Inc` does not set the
#     password to "-Inc" -- it errors on the missing argument AND sets the
#     switch. A value that starts with '-' must be written `-Password:-value`.
#   * A one-letter prefix such as `-I` or `-M` is ambiguous and errors; it is
#     refused here anyway, because "PowerShell would have errored" is a weaker
#     guarantee than "this wrapper never sent it".
#
# `selftest` (below) exercises all of this.
# ---------------------------------------------------------------------------

# run-all.ps1's parameters that `suite` will forward, lower-cased, full names.
# Deliberately absent: -IncludeHidTransition and -HidTransitionNonInteractive
# (step 7, refused above); -MapperExeForHidTransition (meaningless without
# them); -ResultsRoot (this wrapper owns it -- runbook 4.1's per-session guest
# results root); and every CmdletBinding common parameter.
SUITE_ALLOWED_PARAMS='installerpath installdir userdatadir mapperexe profile ssid password mdnstimeoutms mapperwaitms shell'

SUITE_STEP7_HINT="Run it deliberately, by hand:
    $0 --interactive ssh 'pwsh -NoProfile -File $GUEST_ROOT\\scripts\\windows-validation\\60-hid-transition.ps1 -MapperExe ...'
It discharges nothing: R15 stays NO-GO."

# Dies unless every argument is a forwardable run-all.ps1 parameter (or a value
# belonging to one). Prints nothing on success.
suite_guard() {
  local a low name want_value=0 taking=0
  for a in "$@"; do
    taking="$want_value"; want_value=0
    case "$a" in
      *\'*) die "refusing an argument containing a single quote, which this quoting cannot survive: $a" ;;
    esac
    case "$a" in
      -*)
        low="$(printf '%s' "$a" | tr '[:upper:]' '[:lower:]')"
        low="${low#-}"; low="${low#-}"
        name="${low%%:*}"; name="${name%%=*}"
        case "$name" in
          i|in|inc*|includ*|hid*|hidtransition*|mapperexeforhid*)
            die "refusing '$a'. PowerShell binds parameter names case-insensitively and by unambiguous PREFIX, so this argument is (or abbreviates) a step-7 switch: 60-hid-transition.ps1 needs a human at the DS4 cable AND the car UNPOWERED / RX UNBOUND (runbook 3.1). $SUITE_STEP7_HINT" ;;
          resultsroot*)
            die "refusing '$a'. -ResultsRoot is this wrapper's to set: 'suite' gives the guest this evidence session's own results root (runbook 4.1) so the pull carries THIS run and not runs 1..N. Use --session STAMP to choose the session instead." ;;
        esac
        case "${low%%:*}" in
          *=*) die "refusing '$a'. 'pwsh -File' does not bind '-Name=value' -- it silently IGNORES the token and runs with that parameter unset, which is worse than an error. Write '-Name value' or '-Name:value'." ;;
        esac
        case " $SUITE_ALLOWED_PARAMS " in
          *" $name "*) ;;
          *) die "refusing '$a': not on suite's allow-list. This wrapper forwards only these run-all.ps1 parameters, spelled in full: -InstallerPath -InstallDir -UserDataDir -MapperExe -Profile -Ssid -Password -MdnsTimeoutMs -MapperWaitMs -Shell. Anything else -- abbreviations included -- goes through '$0 --interactive ssh' by hand, deliberately." ;;
        esac
        # A ':'-form carries its own value; a bare name expects the next token.
        case "$a" in
          *:*) ;;
          *)   want_value=1 ;;
        esac
        ;;
      *)
        [ "$taking" = 1 ] || die "refusing the positional argument '$a'. Every value must follow the parameter it belongs to (e.g. -Ssid W17-GRID); run-all.ps1's positional binding would otherwise put it somewhere neither of us chose."
        ;;
    esac
  done
}

# Set by suite_build_remote. A global, not a $(...) capture: the banner below
# is owner-facing stdout and must not end up inside the command it describes.
SUITE_REMOTE=''

# Guard, THEN announce, THEN build -- one code path, in that order, so the
# banner can never describe a command the guard has not already vetted.
suite_build_remote() {
  local stamp="$1"; shift
  local a
  suite_guard "$@"
  echo 'Running run-all.ps1 WITHOUT -IncludeHidTransition.'
  echo 'Step 7 (60-hid-transition.ps1) is human-in-the-loop and has a safety'
  echo 'precondition -- car UNPOWERED or RX UNBOUND (runbook 3.1). This wrapper'
  echo 'REFUSES that switch, and every abbreviation of it, by allow-list (it'
  echo 'exits 2); run step 7 deliberately, by hand, over ssh -t.'
  # Per-argument quoting. "$*" joined argv on IFS inside a double-quoted
  # string, which destroyed every argument containing a space -- and the two
  # most likely parameters both contain one by construction: -InstallDir
  # defaults under 'C:\Program Files\...' and -Password is the owner's real
  # hotspot password. PowerShell reads single quotes as a literal string,
  # which survives the cmd.exe login shell Windows OpenSSH uses (left alone
  # deliberately -- see guest-bootstrap.ps1's header).
  # BENCH-TBD (V-A3 V3-2): this quoting has never been executed against a
  # real Windows guest -- cmd.exe's own argument splitting and Windows
  # pwsh.exe's CRT-style argv split are both unverified offline. First guest
  # session: run the echo-back check in the runbook's first-session step
  # before trusting any space-bearing -InstallDir/-Password/-Ssid value.
  #
  # ResultsRoot is THIS session's own directory on the guest, so the pull
  # below carries this run's results and not sessions 1..N (runbook 4.1).
  SUITE_REMOTE="pwsh -NoProfile -File $GUEST_ROOT\\scripts\\windows-validation\\run-all.ps1 -ResultsRoot $GUEST_ROOT\\results\\$stamp"
  for a in "$@"; do
    case "$a" in
      ''|*[[:space:]]*) SUITE_REMOTE="$SUITE_REMOTE '$a'" ;;
      *)                SUITE_REMOTE="$SUITE_REMOTE $a" ;;
    esac
  done
}

cmd_suite() {
  local stamp out
  stamp="$(session_stamp)"
  out="$EVIDENCE_ROOT/$stamp"
  suite_build_remote "$stamp" "$@"
  run mkdir -p "$out"
  cmd_stage
  ssh_ "$SUITE_REMOTE"
  scp_ -r "$SSH_HOST:$GUEST_ROOT\\results\\$stamp" "$out/results"
  info "$out/results"
}

# ---------------------------------------------------------------------------
# selftest -- the guard's own regression suite. Host-only: every case runs this
# script under --dry-run into a throwaway evidence root, so nothing is copied,
# started, powered or connected. It needs no VM, no Fusion and no ssh.
#
# Case list: the eleven smuggle variants a reviewer found bypassing the
# earlier literal guard, plus the four the fix brief added, plus the legitimate
# parameters, which must still go through untouched.
# ---------------------------------------------------------------------------
cmd_selftest() {
  local self tmp out rc total=0 failures=0
  self="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/w17-host-vm-selftest.XXXXXX")"

  _st_run() {
    set +e
    out="$("$self" --dry-run --session SELFTEST --evidence "$tmp" suite "$@" 2>&1)"
    rc=$?
    set -e
  }

  # Must exit 2, must not print the banner, and must not reach the ssh call.
  _st_refuse() {
    local label="$*"
    total=$((total + 1)); _st_run "$@"
    if [ "$rc" != 2 ]; then
      failures=$((failures + 1)); printf 'FAIL    not refused (exit %s): suite %s\n' "$rc" "$label"; return 0
    fi
    case "$out" in
      *'Running run-all.ps1 WITHOUT'*)
        failures=$((failures + 1)); printf 'FAIL    banner printed for a refused argument: suite %s\n' "$label"; return 0 ;;
    esac
    # die() runs inside suite_build_remote, i.e. before mkdir, before stage and
    # before the run-all.ps1 call -- so a refusal must emit no DRY-RUN line at
    # all. (The refusal MESSAGE names run-all.ps1, so grepping for that string
    # would test nothing.)
    case "$out" in
      *'DRY-RUN: '*)
        failures=$((failures + 1)); printf 'FAIL    a command was still emitted: suite %s\n' "$label"; return 0 ;;
    esac
    printf 'PASS    refused (exit 2): suite %s\n' "$label"
  }

  # Must exit 0, must build the command, must contain $1, and must not smuggle
  # either step-7 switch into the built command line.
  _st_accept() {
    local expect="$1"; shift
    local label="$*" sshline
    total=$((total + 1)); _st_run "$@"
    if [ "$rc" != 0 ]; then
      failures=$((failures + 1)); printf 'FAIL    legitimate call refused (exit %s): suite %s\n' "$rc" "$label"; return 0
    fi
    # The BUILT run-all.ps1 command only -- not the banner (which names the
    # switch in prose) and not stage's own ssh/scp lines, which come first.
    sshline="$(printf '%s\n' "$out" | grep -m1 'DRY-RUN: ssh .*run-all\.ps1' || true)"
    if [ -z "$sshline" ]; then
      failures=$((failures + 1)); printf 'FAIL    no ssh command built: suite %s\n' "$label"; return 0
    fi
    if [ -n "$expect" ]; then
      case "$sshline" in
        *"$expect"*) ;;
        *) failures=$((failures + 1)); printf 'FAIL    built command lacks %s: suite %s\n' "$expect" "$label"; return 0 ;;
      esac
    fi
    case "$sshline" in
      *-Inc*|*-inc*|*-INC*|*-Hid*|*-hid*|*-HID*)
        failures=$((failures + 1)); printf 'FAIL    a step-7 switch reached the command: suite %s\n' "$label"; return 0 ;;
    esac
    printf 'PASS    forwarded: suite %s\n' "$label"
  }

  echo '=== host-vm.sh selftest: the suite step-7 allow-list ==='
  echo

  echo '-- the two switches, verbatim and in :value form'
  _st_refuse -IncludeHidTransition
  _st_refuse -HidTransitionNonInteractive
  _st_refuse '-IncludeHidTransition:$true'
  _st_refuse '-HidTransitionNonInteractive:$true'

  echo '-- case folding (PowerShell binding is case-insensitive)'
  _st_refuse -includehidtransition
  _st_refuse -INCLUDEHIDTRANSITION
  _st_refuse '-includehidtransition:$true'
  _st_refuse -hid

  echo '-- prefix abbreviation (PowerShell binds any unambiguous prefix)'
  _st_refuse -Inc
  _st_refuse -IncludeHid
  _st_refuse -Hid
  _st_refuse -I
  _st_refuse -Inc -Hid

  echo '-- other spellings'
  _st_refuse --IncludeHidTransition
  _st_refuse -IncludeHidTransition=1
  _st_refuse -IncludeHid=1
  _st_refuse -MapperExeForHidTransition 'C:\w17\mapper\w17-mapper.exe'

  echo '-- everything else off the allow-list'
  _st_refuse -Verbose
  _st_refuse -ResultsRoot 'C:\w17\results\somewhere-else'
  _st_refuse -NotAParameter
  _st_refuse 'C:\stray\positional.exe'
  _st_refuse -Ssid W17-GRID stray-positional

  echo
  echo '-- the legitimate parameters still pass'
  _st_accept ''                             # no arguments at all
  _st_accept "-Ssid W17-GRID" -Ssid W17-GRID
  _st_accept "-Ssid:W17-GRID" -Ssid:W17-GRID
  _st_accept "'C:\\Program Files\\W17 Ground Station'" -InstallDir 'C:\Program Files\W17 Ground Station'
  _st_accept "'my secret pw'" -Password 'my secret pw'
  _st_accept "-MdnsTimeoutMs 8000" -MdnsTimeoutMs 8000
  _st_accept "-Shell pwsh" -Shell pwsh
  _st_accept "-MapperWaitMs 12000" -InstallerPath 'C:\w17\dist\gs.exe' -MapperExe 'C:\w17\mapper\m.exe' -Profile w17 -MapperWaitMs 12000
  _st_accept "-UserDataDir" -UserDataDir 'C:\Users\w17\AppData\Roaming\w17'

  rmdir "$tmp" 2>/dev/null || true
  echo
  if [ "$failures" = 0 ]; then
    printf 'RESULT: %s/%s PASS\n' "$total" "$total"; return 0
  fi
  printf 'RESULT: %s of %s FAILED\n' "$failures" "$total"; return 1
}

# ---------------------------------------------------------------------------
usage() {
  # Print the header comment block and stop at the first non-comment line --
  # a fixed line range over-ran it and leaked five lines of shell source.
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "${BASH_SOURCE[0]}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=1; shift ;;
    --interactive) INTERACTIVE=1; shift ;;
    --vmx)        VMX="${2:-}"; shift 2 ;;
    --host)       SSH_HOST="${2:-}"; shift 2 ;;
    --ssh-config) SSH_CONFIG="${2:-}"; shift 2 ;;
    --evidence)   EVIDENCE_ROOT="${2:-}"; shift 2 ;;
    --session)    SESSION="${2:-}"; shift 2 ;;
    -h|--help)    usage; exit 0 ;;
    --)           shift; break ;;
    -*)           die "unknown flag '$1' (try --help)" ;;
    *)            break ;;
  esac
done

VERB="${1:-}"; [ -n "$VERB" ] || { usage; exit 2; }
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
  stage)      cmd_stage "$@" ;;
  bootstrap)  cmd_bootstrap "$@" ;;
  check)      cmd_check "$@" ;;
  suite)      cmd_suite "$@" ;;
  selftest)   cmd_selftest "$@" ;;
  *)          die "unknown verb '$VERB' (try --help)" ;;
esac
