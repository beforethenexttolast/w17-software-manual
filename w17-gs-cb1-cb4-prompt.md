# Session prompt — 6. CB1 right-stick indicator + CB4 Windows mDNS (no hardware)

Paste into a Claude Code session started at `~/Documents/projects/w17-ground-station`.

Lowest priority of the six — run after prompts 1 and 3. Two independent VR-FPV batches, both listed
`NOT_STARTED` in `../CURRENT_STATUS.md`, both buildable on macOS. **Ask me which one to do first**, and do
one per session — they are unrelated and CB4 is the larger of the two.

Read `../VR_FPV_MASTER_PLAN.md` (batch definitions), `w17-ground-station/CLAUDE.md` (viewer-only
invariants), and `docs/windows_bridge_contract.md` before starting.

---

## CB1 — right-stick indicator (authorized; code + tests in this repo)

The batch table says "authorized; code+tests in w17-ground-station" and nothing more, so **start by
reading the master plan's CB1 definition and telling me what it actually specifies** — then propose the
implementation before writing it. Relevant existing surface: the violet camera dot already mirrors pad axes
2/3 as `STICK INPUT · PAD` (pixel-probed rgb(178,141,248) in the 2026-07-17 audit), and
`docs/camera_aim_display_semantics.md` governs what any aim-adjacent indicator may claim.

Hard limits: display-only; **no** label may imply this app aims the camera, sets the car's mode, or moves
hardware; HEAD TRACKING card stays `LOCKED · SAFETY GATE NOT COMPLETE`; ACTIVE AUTHORITY stays
`NOT REPORTED BY MAPPER`.

## CB4 — Windows-side mDNS discovery of the iPhone HUD

Canonically **unblocked**: the canonical contract carries a Discovery section (`_w17hud._udp.local.`,
advisory user-confirmed hints only; canonical 2026-07-10, mirrored at rev `84532ed` 2026-07-14) and the
iPhone has advertised since `1e332ef`. Only the Windows side is unbuilt. The proposal to implement against
is `docs/proposals/iphone_mdns_discovery.md` — read it, verify it still matches the mirrored contract
section in `docs/windows_bridge_contract.md`, and flag any drift before coding.

Non-negotiables:
- Discovered addresses are **advisory hints requiring user confirmation** — never auto-connect, never
  auto-apply. The existing W3 precedent is the pattern: it surfaces the last accepted sender's IP as a
  user-confirmed suggestion, transport metadata only, guard-tested.
- W3 (UDP 5602) stays **LOG-ONLY**. No path from discovery to CRSF, servos, or the gimbal.
- No new preload/IPC key without telling me — `test/ipcSurface.test.js` pins the surface at exactly **24**
  keys and `smoke:electron` asserts `apiKeys:24`. If the feature genuinely needs a 25th, justify it and
  update both gates deliberately in the same commit.
- Any new dependency (an mDNS/bonjour library) needs my approval first, with a licence note — and it must
  not break the `windows-latest` `package-smoke` job or `electron-builder --dir`.
- Real-device validation is **hardware-blocked** (no iPhone on hand; the office guest network isolates
  clients). Build it, test it hermetically with fixtures, and mark real-device verification PENDING —
  do not claim the path works end-to-end.

## Both

`npx vitest run`, `npm run smoke:electron` 4/4, `npm run proto:check`, `noControlPath` / `ipcSurface` /
`responsiveLayout` green before anything ships. Show diffs before committing. Update the VR-FPV batch table
row in `../CURRENT_STATUS.md` with one line of evidence when the batch is done.
