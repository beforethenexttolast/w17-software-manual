# Session prompt — CB2: gimbal / head-tracking explainer artifact (optional, no hardware)

Paste into a Claude Code session started at `~/Documents/projects`. Marked `NOT_STARTED` / **optional**
in the VR-FPV batch table — the only batch with no blocker at all. Good low-stakes filler while
hardware is waiting on parts.

---

I want the **CB2 gimbal explainer** built: a single self-contained visual artifact that explains how
camera aim actually works in W17 today, and why the active path is locked.

## Why it's worth doing

The head-tracking story is spread across `head_tracking_unlock_plan.md` (large), the VR master plan,
two safety docs, and the GS display-semantics doc. Nobody — including me — can currently see the whole
picture at a glance, and the **most important fact about it is a negative**: there is no iPhone →
control path, and there is not going to be one until a reviewed safety milestone says so. Negatives
are exactly what prose buries.

## What it must show

1. **The real signal path today**, end to end: iPhone → UDP 5602 → `w17-mapper` `pkg/headintent`
   (LOG-ONLY) → gRPC `WatchHeadIntentDiagnostics` → Electron GS display. And **separately**, the actual
   control path: sticks → CRSF ch9/10 → firmware → gimbal servos.
2. **The gap between them, drawn as a gap.** These two paths do not touch. `crsf.PackChannels` output
   is byte-identical with head-intent ingest off vs on — that proof is the whole point and should be
   visible, not a footnote.
3. **The state machine**: IDLE / INVALID / STALE / INACTIVE / NOT_CENTERED / ACTIVE_LOG_ONLY / FAULT
   (plus UNSPECIFIED / DISABLED, unit-tested but not emitted in topology (a)). The proto ends at
   `ACTIVE_LOG_ONLY = 8` — **there is no active enum value**, and the diagram should make that
   conspicuous.
4. **The two timing boundaries and why they differ**: 300 ms log-only staleness (canonical; 299 fresh /
   301 stale) vs the **≤250 ms** active-freshness gate that only exists in the U4 *design*.
5. **The gates**: FIRST_ACTIVE is a two-part flag (compile-tag `w17_first_active` + runtime, both
   default off, **both** required), behind checklist R1–R16, overall verdict **NO-GO / BLOCKED**.

## Constraints

- **Self-contained HTML**, inline CSS/JS only, no external fetches — same shape as the existing
  visualisations (see `w17-steering-servo-fit-diagram.html` at the workspace root, and the ~30
  self-contained HTML visualisations Codex ships in `w17-3d-codex`, read-only).
- Match `w17-design-system` where it applies — read `DESIGN_NOTES.md` first.
- **Accurate over pretty.** Every claim traceable to a file; where you are unsure, say so on the
  artifact rather than drawing a confident arrow.
- **This is display-only.** It changes no gate, no status, no code path.

## Where it lives

Owner decision needed at the end — offer both, don't pick: `w17-control-fw/project-review/` (next to
the unlock plan it summarises) or `w17-ground-station/docs/` (next to
`camera_aim_display_semantics.md`). Then flip the CB2 row in `CURRENT_STATUS.md` to DONE with one line
of evidence.

**Safety:** no hardware, nothing powered or flashed. No iPhone → CRSF, no iPhone → servo/gimbal/ESC;
firmware stays iPhone-unaware; W3 stays LOG-ONLY. A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Show
diffs before committing; branch off main.
