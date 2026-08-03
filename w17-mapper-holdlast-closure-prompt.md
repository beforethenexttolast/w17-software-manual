# Session prompt — close (or re-open) the mapper hold-last throttle-freeze defect

Paste into a Claude Code session started at `~/Documents/projects`. **No hardware.** Highest-value
software job on the board: it sits directly under the "failsafe first" priority in
`w17-control-fw/CLAUDE.md`.

---

`CURRENT_STATUS.md` records a **gamepad-dropout throttle-freeze defect** in `w17-mapper` as
"**Tracked as a separate item; not yet investigated or fixed**" (2026-07-30 entry, under
*VR-FPV batch status*). I believe that line is **stale** — `w17-mapper` `2dc7c5a`
("fix(config): drive stale channels to a defined neutral, not hold-last", 2026-07-30) appears to
address exactly it. I want that verified against live code, not against a commit message, and then
either closed or re-opened with evidence.

**Read the RETRACTION entry in `CURRENT_STATUS.md` (2026-07-27) before you start.** The recorded
lesson from that incident is: *open the file*. A claim that confirms a suspicion you already hold is
exactly the kind that slips through. Do not close this on the strength of `git log`.

## 1. Establish the defect as originally described

From the 2026-07-30 entry, the mechanism was:
- `pkg/config/input_button.go:77` returns `nan=true` when the gamepad is absent from the device registry
- `pkg/config/output_tx.go:43` does `if nan || ch < 1 || ch > 16 { continue }` over a **persistent
  `*[16]util.CRSFValue` struct field never reset at the top of a tick** → `continue` retains the
  previous tick's value indefinitely
- Result: a USB gamepad dropout while driving freezes the last throttle command, and the **firmware
  failsafe does not fire** — the link is up, frames are well-formed, CRC is valid, payload is stale

Confirm each hop still reads that way at the pre-fix commit, so you know what "fixed" has to mean.

## 2. Verify the fix at HEAD, in the source

`w17-mapper` HEAD is `5a28106` (the `CURRENT_STATUS.md` checkpoint row still says `0e11d6b` — also
stale, see §5). Read the actual files, not the diff summary:

- Is the persistent `Values` array now written on **every** tick for every mapped channel, or only
  on the nan path? A `continue` anywhere else reproduces the same class of bug.
- `InputGamepad.Attached()` — does `GetInputGamepad` gate on it on **every** resolution path, or only
  the one the commit exercised?
- `centeredValues()` initial state — is 992 correct for *switch-like* channels, or does an unmapped
  switch channel now sit in the decoder's ±250 dead band (which HOLDS previous state — the DEFECT 2
  failure class)? This is the interaction most likely to have been missed.

## 3. Close the residual the status file explicitly recorded as untraced

Quoting the entry: *"whether `AlertDeviceChan` / device-removal handling elsewhere invalidates the
config or zeroes the array before the next tick was **not** traced — the mechanism is confirmed, the
end-to-end outcome is PLAUSIBLE and needs a test."*

Trace it. Then answer the second recorded open question: `EvalNoData` is `{0,…,0}` — what does the
firmware decoder now do with an all-zeros payload, given `91f830f` (`kChannelRawPlausibleMin/Max` =
100/1900 ⇒ implausible decodes as **absent**, arm forced OFF)? Confirm the two halves compose.

## 4. Prove the tests bite

The commit claims tests were checked against pre-fix behaviour. **Verify that independently** —
injected-regression style, the way this workspace does it elsewhere: remove the neutralizing branch,
confirm the test fails; restore, confirm it passes. A test that passes vacuously is the failure mode
that has bitten this workspace before (the jsdom class-only assertions in GS `085e1d1`).

Run: `go build ./...`, `go vet ./...` (note: `vet` is **not** green and that is **not** a
regression — see unlock plan §2.3.12.9 item 2), `go test ./... -count=1` and `-race` on the touched
packages. Confirm `crsf.PackChannels` byte-identity still holds.

## 5. Reconcile the record

Whichever way it lands:
- Correct the 2026-07-30 "not yet investigated or fixed" line in `CURRENT_STATUS.md` to what is
  actually true, dated.
- Update the `w17-mapper` **checkpoint row** `0e11d6b` → real HEAD, listing what landed since
  (`2dc7c5a`, `53f4806`, `d42a277`, `630ea96`, `5a28106`).
- If it is **not** fully closed, say precisely what remains and do not soften it.

**Safety:** no hardware, nothing flashed or powered. No head-intent, no FIRST_ACTIVE, no arbitration
code — the fork's `.githooks/pre-push` must stay clean. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.
Show diffs before committing; work in `w17-mapper` and the workspace repo only; branch off main.
