# Session prompt — 11. Mapper durability + the last hardware unknown (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-mapper` for phase A, then move to
`~/Documents/projects` for phases B and C.

Two loose threads left by the 2026-07-25 serial-bump slice, plus one cleanup. Nothing here needs hardware
and nothing changes a gate: **A2 stays NOT-EXECUTED, Phase B stays BLOCKED.**

## Phase A — `w17-mapper` has no backup, and that is now the biggest single-point-of-failure in the project

Verified 2026-07-25: this repo's **only** remote is `upstream`
(`https://github.com/kaack/elrs-joystick-control.git`) whose push URL is literally
`DISABLED_no_push_without_approval`. There is **no `origin`**. That means two commits of owned work —
`59d1739` (CB8 slices 1–3A: LOG-ONLY UDP 5602 head-intent ingest, `pkg/headintent`, the read-only gRPC
diagnostics stream, the pinned proto-codegen toolchain) and `f0a18f3` (the v1.6.0 bump that finally cleared
`go build ./...`) — exist on **one disk and nowhere else**. Weeks of reviewed, evidence-backed work with no
recovery path.

**Do the zero-decision part first, before any discussion:** `git bundle create` the whole repo (all refs)
to a durable location **outside** any session scratchpad — those are ephemeral and get cleaned. Verify the
bundle with `git bundle verify` and by cloning it to a temp dir and confirming `59d1739` and `f0a18f3` are
present with `go test ./pkg/headintent/` green in the clone. That removes the risk today regardless of what
I decide next.

**Then put the remote decision to me** with the trade-offs spelled out. What I need to weigh:

- **Licence:** the fork is **GPL-3.0-or-later** with provenance recorded (R11 PASS). GPL obligations attach
  to **distribution** — a private remote adds no new obligation; a public one is permitted and satisfied by
  construction (the source *is* what's published), provided upstream attribution, the licence text, and the
  `2b8031a` fork point stay intact. Confirm those are all present before recommending publication.
- **Safety:** publishing today distributes **no control path** — `server.proto` still ends at
  `HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8`, there is no active enum value, UDP 5602 is LOG-ONLY, and
  FIRST_ACTIVE is **NO-GO/BLOCKED**. State plainly whether you agree after checking, because that is the
  premise the whole option rests on.
- **The subtle risk:** "no remote" is currently doing safety work by accident — it makes accidental
  distribution impossible. If a remote is added, that protection must be replaced by something deliberate:
  a documented push-review rule, and ideally a pre-push hook that refuses when the FIRST_ACTIVE compile tag
  or an active enum value is present. Propose the mechanism; do not rely on the absence of a remote as a
  safety control once a remote exists.
- Options to lay out: **private remote** (my default expectation — durability without distribution),
  **public fork** (durability + upstream-contributable, GPL-clean, but publishes the head-tracking work),
  or **bundle-only** (no account, but a manual step that will be forgotten).

Do not create any remote or push anything until I choose. `upstream`'s push URL stays disabled either way.

## Phase B — the ELRS TX Windows-enumeration unknown belongs on the bench list, not in the mapper's record

The v1.6.0 analysis closed every timing question it could on this host — `Write`/`Read` byte-identical
v1.5.0 → v1.6.0 in `serial_unix.go` and `serial_windows.go`, delta confined to enumeration / `Open` error
wrapping / an unused `Drain()` / cgo wrappers, and `crsf.PackChannels` byte-identical (12 frames / 312 bytes,
one SHA across off / on-valid / on-stale / on-invalid, matching the v1.5.0 dumps). One residual remains:
**real Windows enumeration of the ELRS TX**, unverifiable on a macOS host.

That is a bench item, and it should sit with the other Windows-hardware unknowns rather than living inside a
dependency-bump record where nobody will look for it. Add it to the **Pending validations** section of
`CURRENT_STATUS.md`, alongside the Pixel IPv4-lease/ICS path, real iPhone W2/W3, camera→mediamtx→WHEP, and
Windows DPAPI. **Cross-reference, do not duplicate** the two existing authoritative ledgers
(`w17-ground-station/docs/setup_flow_bench_checklist.md` + the evidence matrix in
`docs/audits/2026-07-12-pre-hardware-hardening-audit.md`, and `w17-control-fw/project-review/11_hardware_validation_plan.md`).

**Single-writer rule:** `CURRENT_STATUS.md` has exactly one writer per pass. If you run this **before**
prompt 10, do **not** edit that file — hand the line back to me as text and prompt 10 lands it. If you run
this **after** prompt 10, edit it directly.

## Phase C — durable archive for the deleted GS artifacts

The 2026-07-25 bookkeeping session archived 15 spent ground-station artifacts to
`spent-gs-artifacts-2026-07-25.tgz` before deleting them — good practice, but it went to a **session
scratchpad** (`/private/tmp/claude-501/…/2a194d4f-…/scratchpad/`, 220 KB, confirmed present today). Those are
ephemeral and session-scoped, so the recovery path expires with the session that made it.

The deletion evidence was strong — the committed in-repo audit is a 2592-line superset of the 1818-line root
copy and names the landing chain, 90–96% of patch content is present verbatim at HEAD, and every apparent gap
traced via `git log -S` to `79fa2e0` plus later refactoring. So this is belt-and-braces, not doubt. Either
move the tarball somewhere durable (and tell me where), or confirm to me that the git-history evidence is
sufficient and the tarball can be allowed to expire. Say which you did — do not leave it implicitly relying
on a temp directory.

## Boundaries

Edit `w17-mapper` in phase A only, workspace docs in phases B/C only. Do **not** touch
`w17-ground-station`, `w17-control-fw`, or any Codex-owned repo (`w17-3d-codex`, `../Codex/*`). Show diffs
before committing. No powering, flashing, or connecting anything.
