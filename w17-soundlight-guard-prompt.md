# Session prompt — 9. Soundlight: make the link2 guard bite + re-sync the protocol doc (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-soundlight-fw`.

Run **after** the 2026-07-25 control-fw batch has landed on that repo's main (prompt 2 settles its branch
rename). Two items, both handed over from that session. **Edit this repo only** — `w17-control-fw` owns the
link2 protocol and the script; this repo owns the enforcement.

Baseline: HEAD `ec5ddf8`, native tests **94/94**. This repo had 11 unpushed commits as of 2026-07-25 — if
they're still unpushed, confirm 94/94 and push them before starting new work. **No hardware** — no flashing,
no powering, no I2S/WS2812 bench work. A2 stays NOT-EXECUTED, Phase B stays BLOCKED.

## 1. The CI step that makes the cross-repo guard real

`w17-control-fw` now ships `tools/link2_copy_check.sh`. It diffs the four shared link2 files
(`Link2Frame.hpp`, `Link2Codec.hpp`, `src/Link2Codec.cpp`, `library.json`) against
`../w17-soundlight-fw/lib/link2/` — all four are byte-identical today, and this repo's copy is a strict
subset (no `Link2Sender.cpp`). Semantics as built: `--strict` so an absent sibling cannot pass,
**exit 1 = drifted**, **exit 2 = could-not-check**, drift fatal in both modes. It was verified to bite on an
injected `kPayloadLen` change and on a deleted file.

Until a CI step calls it, the guard is **advisory only**. Add that step here:

- Call the script in `--strict` mode from this repo's CI, with `w17-control-fw` checked out alongside.
  Work out how — sibling checkout step, or a vendored copy of the script invoked against a fetched
  control-fw — and tell me the trade-off you chose. The script lives in control-fw; **do not fork it here**
  without saying so, because two copies of a drift checker is its own joke.
- Distinguish the exit codes in CI output: exit 2 must not read like a pass, and must not read like drift
  either. A "could not check" that looks green is exactly the failure mode `--strict` exists to prevent.
- Verify the step **actually fails** on injected drift, the way the control-fw session verified the script
  (throwaway fake sibling). A guard nobody has watched fail is not a guard — this workspace has already
  been bitten by a vacuously-passing assertion (`085e1d1` in the ground station).

## 2. Re-sync `docs/link2_protocol.md` — with judgment, not `cp`

That doc was **also** a byte-identical copy across the two repos, and the control-fw session's edit diverged
it (its new ownership section names a script that does not exist over here). The session deliberately left
this for a human: byte-identity is the **wrong bar** for a doc that legitimately carries repo-local prose, so
the script treats it as a second, non-fatal tier — it prints a `REPORT` line and still exits 0.

So: pull across the substantive protocol content (control-fw is the protocol owner and its version is
canonical), but **keep or adapt** anything that is legitimately local to this repo, and drop or reword
control-fw-only references such as the `tools/link2_copy_check.sh` ownership paragraph. Show me the
three-way picture before you write: what changed upstream, what is local here, what you propose to end up
with. Do not blind-copy, and do not edit control-fw's version.

While you're there, confirm the doc's gear-range wording matches the decision recorded 2026-07-25: **4 gears
is canonical** (`Gearbox::kMaxGears` = 6 is *array capacity*, not a gear count — that misread is what
created the phantom "6"), and drive-mode display labels are **TRAINING / RACE / ERS** with the wire enum
`TRAINING / GEARBOX / GEARBOX_ERS` deliberately different. If this repo's copy states either differently,
that's real drift worth flagging.

## Gates

`pio test -e native` (**expect 94/94**, plus whatever your CI work adds) and all environments build. Show
diffs before committing; focused commits. **Do not touch `CURRENT_STATUS.md`** — prompt 2 is the single
writer; hand results back as text. Do not edit `w17-control-fw` or the ground station.
