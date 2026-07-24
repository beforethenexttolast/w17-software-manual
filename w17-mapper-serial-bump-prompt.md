# Session prompt — 5. Mapper `go.bug.st/serial` bump (isolated slice, no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-mapper`.

---

Do the **one approved, isolated** dependency slice in the owned mapper fork. Read
`../w17-control-fw/project-review/head_tracking_unlock_plan.md` §2.3.9 / §2.3.12 and
`../CURRENT_STATUS.md` first.

**Standing facts (verified 2026-07-25):** this is the owned GPL-3.0-or-later fork `w17-mapper`, branch
`w17-headtrack` off upstream `2b8031a`, HEAD `59d1739` (CB8 slices 1–3A), **push disabled**.
`go test ./pkg/headintent/...` is green. Full `go build ./...` fails **only** in third-party
`go.bug.st/serial/enumerator` v1.5.0 under the go1.26 cgo rule — pre-existing, fails on pristine upstream
too. A temporary bump to **v1.7.1** makes the whole build green; it has been applied and reverted three
times for validation because that dependency sits in the **CRSF send path**, which made it an owner
decision. That decision is **RESOLVED**: approved as a future isolated mapper slice, not mixed with
anything else (`§2.3.12`, 2026-07-15).

This session does that, and nothing else:

1. Confirm the starting state is pristine — `go.mod` / `go.sum` / `go.work` byte-identical to `HEAD`, and
   reproduce the current `go build ./...` failure so we have the before-picture on record.
2. Bump `go.bug.st/serial` to **v1.7.1** and nothing else. Show me the exact `go.mod` / `go.sum` diff.
   If the module graph pulls anything else along, stop and show me before proceeding.
3. Evidence required, because this touches the send path:
   - `go build ./...` fully green (the point of the slice).
   - `go vet ./...`, `go test ./...`, plus `-race` on `./pkg/headintent/` and `./pkg/server/`.
   - **The `crsf.PackChannels` byte-identity proof must still hold** — `pkg/headintent/pack_deadend_test.go`
     (12 frames / 312 bytes, `bytes.Equal`) flag-off vs flag-on under valid / stale / invalid UDP traffic
     **and** with diagnostics subscribers connected, slow, and disconnected. Report the actual comparison,
     not just "tests pass".
   - Read the v1.5.0 → v1.7.1 changelog and tell me whether anything in the serial **write** path,
     timeout semantics, or port enumeration changed in a way that could alter CRSF frame timing. This is
     the real risk of the slice; an honest "changelog shows X, unverifiable without hardware" is the right
     answer if that's the case.
   - `go list -deps` must still show `pkg/headintent` reaching no config / link / crossfire / serial /
     devices / output package (crossfire test-only).
4. Then commit — **this slice alone**, with the upstream-provenance and license note the fork convention
   requires. Push stays disabled; do not enable it.

**Hard boundaries:** no head-intent **shaping or arbitration** code (FIRST_ACTIVE is NO-GO / BLOCKED —
R1/R2/R6–R9/R12/R13 are hardware/evidence class); the proto must still end at
`HEAD_INTENT_STATE_ACTIVE_LOG_ONLY = 8` with **no active enum value**; UDP 5602 stays **LOG-ONLY**; no
regeneration of proto stubs (nothing here changes the proto — if `pkg/proto/generate.sh` runs at all it must
be a zero diff); do not touch `w17-ground-station` (its `npm run proto:check` should stay clean without any
change on this side).
