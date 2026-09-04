# Booklet Editorial Packet — F1 truth pass, 2026-09-05

Companion to `14_glovebox_owners_booklet.md`. Produced by worker F1 (Sonnet 5) in the W17
OFFLINE READINESS program, worktree `offline/booklet-editorial`, workspace baseline
f1fc46e. Scope: verify every technical claim in the printed booklet (lines 44–509, the
banner + draft-notes are scaffolding, not print content) against current canonical
sources, fix stale facts in place, leave voice alone, and hand back what still needs a
human.

## How to review this packet in 15 minutes

1. Read §1 below first — it's the only section with an actual code change (one line).
   Diff it against the booklet yourself: `git -C learning-manual diff HEAD~1 --
   14_glovebox_owners_booklet.md` (or just read the two rewritten lines quoted here).
2. Skim §2's table — five real candidate lines, not a padded checklist. Each has two
   short alternatives; pick one, edit yours in, or leave as printed (all five are already
   *correct*, just possibly worth a tone pass).
3. Skim §3 — the 18 `[TBD-at-bench: …]` markers still in the printed text, grouped by
   what resolves them (mostly: build the car, then measure). Nothing to decide here,
   just context for what "print-ready" is still waiting on.
4. Confirm the link-checker line at the bottom of this file — exit code 0, both modes.
5. That's the whole review. No other technical claim changed; everything else in the
   booklet was independently re-checked against current repo state (all five trunk SHAs
   match the program baseline exactly, so nothing moved under this pass) and found
   accurate — see "Verification performed, no fix needed" at the end for what was
   checked and how.
6. If you only have 2 minutes: read the single diff in §1, and know that §2 is optional
   polish, not corrections.

---

## 1. Fixes made (facts only, voice untouched)

One stale technical statement found and fixed. No other line in the printed booklet
(44–509) was found factually wrong or stale against current canonical sources.

| Line(s) | Before | After | Source |
|---|---|---|---|
| 121 (now ~126, section 3 step 3) | "…breathes softly for a few seconds while she gets herself sorted, then settles to a calm glow. `[TBD-at-bench: final wake-up light show — she may get a proper ignition animation]`" | "…breathes softly for a few seconds while she gets herself sorted. Either it settles to a calm glow, or, if something's not right inside, she'll blink amber within a few seconds to tell you plainly — either way, she never just breathes forever." | `w17-soundlight-fw` main `7220c08` (unchanged from program baseline — independently re-verified, not just cited from an old note): `neverConnectedGraceMs = 5000` (`lib/lights/include/lights/LightRenderer.hpp:202`, range-checked in `valid()` at `:241`); the bounded grace-breathe → calm-halo-or-amber-hazard logic at `lib/lights/src/LightRenderer.cpp:216-247`. This is the exact behavior section 6's "Gentle breathing glow, just after key-in" row *already* printed as settled fact with no marker of its own (fixed under `[fix-wave: soundlight docs-truth-7]`, 2026-09-03) — section 3's marker was simply never retired when that row was fixed. Same-file consistency fix; no code changed. |
| 17–31 (intro banner) | "What remains marked — **19 markers**…" | "What remains marked — **18 markers**…" (clause added recording the removal above) | Direct consequence of the fix above — recount, not a new finding. |

Commit: `2dae39b` on `offline/booklet-editorial` — `docs(booklet): retire stale key-in wake-up TBD marker, now a decided code fact`. A matching draft-note paragraph was added at the end of the file's own running history (same convention as the existing 2026-09-03/09-04 entries), so the fix is traceable in place without needing this packet.

---

## 2. Lines that could use the owner's ear (voice/tone, not facts)

All five lines below are printed as *correct facts already* — nothing here is a
correctness issue. These are the handful of spots in the booklet's later, orchestrator-
written truth-pass insertions (rather than the original 2026-08-16 owner-voiced draft)
that read slightly more technical/defensive than the rest of the booklet's warmer,
established voice. Ordered by the section they appear in (the booklet's own "one section
per spread" structure stands in for page numbers).

| Section | Line (quoted) | Why it needs a human | Alternative A | Alternative B |
|---|---|---|---|---|
| 4 (line ~152) | "**One honest thing about the phone app:** think of it as a fun extra, not the main event. The computer screen is always there and always current — the pit crew keeps the phone app itself fresh behind the scenes (a little chore, done about once a week), so if it ever looks out of date or won't open, that's a known quirk of a phone app made just for her, not something you did." | Longest, most explanatory paragraph in the booklet; reads like a support-doc caveat dropped into a gift booklet. Written in the 2026-09-03 truth pass to cover the weekly re-sign honestly, not voiced by the owner. | Trim to: "One honest thing: the phone app is a fun extra, not the main event — the computer screen is always there. The pit crew keeps the phone app fresh behind the scenes; if it ever looks out of date, that's just her app being hers, not something you did." | Split the mechanism out of the promise: keep "She's a fun extra, not the main event — the computer's always there and always right." as its own sentence, and fold the weekly-refresh caveat into the section 9 troubleshooting table instead of the main narrative. |
| 6 (line ~180) | "**Green, right at the outer edges of the tail light** \| Her rear wing is open. If she's braking or has stopped herself at the same moment, that always shows first." | The second sentence is a priority-order disclaimer (which light wins) merged in from a 2026-09-03 fix; useful but reads like a rules footnote rather than the dictionary-entry voice of the rest of the table. | Drop the second sentence from the table entirely — it's an edge case, not something Lola needs to parse from a legend. | Shorten to "…open. (Braking always shows first if both happen together.)" — keeps it, but as a parenthetical aside instead of a full sentence. |
| 9 (line ~252) | "Reconnect the controller — she picks it right back up, so there's no need to close the app or start over. She always plays it safe though: a dropped controller switches her engine off, so wake it again with a fresh triangle press, same two-step as section 3." | Two clauses doing two different jobs (reassurance, then a caveat) back to back; the "she always plays it safe though" pivot is functional but a little clunky next to the rest of the troubleshooting table's terser rows. Rewritten for the MAP-6 closure (2026-09-04), not voice-reviewed. | "Just reconnect it — she picks it right back up, no need to close the app. One thing though: a dropped controller switches her engine off for safety, so give her a fresh triangle press to wake it again (section 3's two-step)." | Split into two table cells' worth of content kept in one line but reordered: lead with the caveat, end on the reassurance — "A dropped controller switches her engine off, on purpose — just reconnect and give her a fresh triangle press. She picks the pad right back up; no need to close the app." |
| 1 (line ~76) | "**One note:** her companion app runs on your own computer — and her helmet view runs on your phone (section 4). Both were installed and set up when she was handed over, so they're ready to go. If you ever change computers or phones, ping Vitaliy — it's a five-minute job." | The "it's a five-minute job" estimate is a specific time promise with no source behind it (not measured, not in any doc) — reads like a filler reassurance rather than a checked fact. Not wrong, just unverifiable as stated. | Drop the time estimate: "…ping Vitaliy — happy to help." | Make it explicitly informal rather than quantified: "…ping Vitaliy — it's a quick fix, not a big deal." |
| 3 (line ~126, this pass's own fix) | "…breathes softly for a few seconds while she gets herself sorted. Either it settles to a calm glow, or, if something's not right inside, she'll blink amber within a few seconds to tell you plainly — either way, she never just breathes forever." | This is F1's own fix (§1 above) — deliberately modeled on section 6's already-approved wording to stay in voice, but it duplicates section 6's sentence almost verbatim across two sections. Flagging for awareness, not because it's wrong. | Leave as-is (safest — matches an already-approved sentence). | Shorten section 3's version to just "…gets herself sorted, then settles to a calm glow (see section 6 if she ever blinks amber instead)." and let section 6 carry the full explanation once. |

---

## 3. Remaining `[TBD-at-bench]` markers (18) — what resolves each

None of these are open owner decisions; every one is either a physical measurement that
needs the built car, or a bench observation that needs the car powered up. Grouped by
what unlocks them. No `[win-TBD]` markers appear in the printed booklet text itself
(those live in `w17-giftee-pc-install-guide.md` and
`w17-ground-station/docs/GIFTEE_FIRST_LAUNCH.md`, out of this packet's scope).

**Unlocked by assembly + first power-up (Phase B, still BLOCKED — A2 NOT-EXECUTED):**
- Station box wall adapter, yes/no (§1)
- Charging flap location on the body (§2)
- Charge light location + exact meanings (§2)
- Charge time low→full (§2)
- Drive time per full charge (§2)
- Confirmed charger recommendation / minimum wattage (§2)
- Key plug location on the body (§2)
- Spare key ships in box, yes/no (§2)
- Comfortable operating range — how far is far (§2)
- Rear-wing green tell's actual brightness/visibility on the finished car (§6)
- Charge-light colors: charging / done / problem (§6)
- Safe lift points for carrying her (§8)

**Unlocked by a Windows/GS validation session with the built car (WS3, `w17-windows-vm-validation-runbook.md`):**
- Controller connection: cable vs. wireless pairing, and to what (§3, §5.2 of the install
  guide carries the same open marker)
- Whether the phone's video appears automatically or needs one tap the first time, and
  which Wi-Fi the phone should join (§4) — this one also needs OD-16's WHEP path
  exercised against a real hotspot, not just the code path (already `CI GREEN` at
  iPhone `7aaf2cf`, but never run on real Windows/real phone hardware)

**Unlocked by a real safe-stop / reconnect drill on the bench (needs the car built and
powered, controller connected):**
- The feel of the restart ritual after a safe-stop (§7) — the *mechanism* is already a
  decided code fact (owner-ratified rearm-latch, `w17-mapper/pkg/config/input_seq.go`
  `ResetOnNaN`); what's open is whether it *reads* as simple as the booklet promises to
  a first-time user, which only a real drill can tell you

**Unlocked by thermal/battery bench testing (needs a built pack, a charger, and time):**
- Battery cool-down time before recharging (§8) — the printed "ten minutes" is flagged
  in the source as a placeholder pattern, not a measurement
- How to part-charge for long-term storage — whether the charger has a storage setting
  (§8)

---

## 4. Link checker

`scripts/check_readiness_runbook_links.sh` is the only link-checking script in the
workspace (`grep -r "link" scripts/ learning-manual/*.md` found nothing else). It does
not include the booklet in its default seven-file list, so it was run four ways from
this worktree: the default list (informational + against the real workspace root), and
explicitly targeting the booklet (same two modes).

| Run | Mode | Exit code | MISSING (hard failures) |
|---|---|---|---|
| Default 7-doc list | no `--workspace-root` (informational; `MISSING-NESTED` doesn't fail) | **0** | 0 |
| Default 7-doc list | `--workspace-root /Users/vitaliykhomenko/Documents/projects` (real check) | **0** | 0 |
| Booklet only | no `--workspace-root` | **0** | 0 |
| Booklet only | `--workspace-root /Users/vitaliykhomenko/Documents/projects` | **0** | 0 |

All four runs exit 0. With `--workspace-root` pointed at the real checkout, every
markdown-link and backticked-path citation the booklet makes into `w17-mapper`,
`w17-ground-station`, and the workspace root resolves. The script's own scope note: it
does not check `.cpp`/`.hpp` citations (source-header extensions are out of scope by
design) — the `LightRenderer.hpp`/`.cpp` citations this pass added (§1 above) were
verified by hand with `Read`/`grep`, not by this script.

---

## Verification performed, no fix needed

For the record — not because these are findings, but so a reviewer doesn't have to
re-derive what was independently re-checked in this pass (all five trunk SHAs matched
the 2026-09-05 baseline exactly, so nothing had drifted since the last truth pass):

- Race-day flow (RACE DAY → STRAIGHT TO THE GRID → START, auto-arm only on a positive
  link claim): `w17-ground-station/renderer/setupFlow.js:290-322`,
  `main/raceDayOrchestrator.js:76` (`STEP_ORDER`). Matches booklet §3 steps 4–5.
- START LIGHTS defaults OFF: `w17-ground-station/shared/settings.js:55`; the handover
  checklist (not this booklet) owns turning it on before gift day.
- Two-tier low-battery banner (warn/critical volts): `renderer/index.html:569-571`,
  `shared/lowBattery.mjs`. Matches booklet §6's "calm note, then a serious one."
- Controller bindings — steering (left stick X), throttle (R2/L2), arm (TRIANGLE, CH5,
  `reset_on_nan`), DRS (SQUARE, CH6), gimbal look (right stick X/Y, CH9/10, stick-driven
  only): `w17-mapper/configs/w17-ds4.json:16,43,115-144,191-202,275-313`. Matches
  booklet §3 step 7.
- DRS-open green tell: `kDrsGreen{0,255,0}`,
  `w17-soundlight-fw/lib/lights/src/LightRenderer.cpp:36,341,344`. Matches booklet §6.
- iPhone phone-video path (WHEP/WebRTC in a bundled WKWebView, OD-16): landed at
  `iPhone_rc` main `7aaf2cf`; `demoModeEnabled` now `false` at cold start
  (`FPVHUDApp/Settings/AppSettings.swift:27`); RSSI/SNR/LQ are Debug-only
  (`FPVHUDApp/UI/HUD/FPVHUDView.swift:96-98`); stale/lost telemetry strings render in
  plain language (`FPVHUDApp/Models/TelemetryState.swift:219-224`). Matches booklet §4
  and the "battery/telemetry honesty" brief.
- 7-day free-account re-sign ritual, framed in booklet §4 as "a little chore, done about
  once a week": matches `iPhone_rc/docs/GIFTEE_INSTALL.md:216-274` and
  `w17-handover-checklist.md:139-146,226`.
- "There is nothing to type" (§4) for phone/computer pairing remains a live overstatement
  against `SettingsPanelView.swift:17` (`windowsHost` is a manual text field, no
  auto-derive) — already correctly logged as `OWNER-GATED, NOT fixed here` in the
  booklet's own trailing notes (`[fix-wave: phone-pairing-hostip]`); re-confirmed
  unresolved, left untouched per that note and per this program's "fix only facts, leave
  voice/product-scope calls to the owner" rule.
- Controller-reconnect promise (§9): `w17-mapper/pkg/devices/hotplug.go:99-146,171-185`,
  `pkg/config/input_seq.go:267-287`, `configs/w17-ds4.json:138` — the Windows/HIDAPI half
  stays `[bench-TBD]` per `w17-mapper/configs/README.md:353-356`, exactly as the booklet
  already documents it.
- Reverse-promise dependency on ESC configuration (§1): `Gearbox.hpp:61-64` — still an
  unenforced-in-firmware promise; already correctly logged `OWNER-GATED, NOT fixed here`.
- All five trunk SHAs (`w17-control-fw` `39a4f3c`, `w17-soundlight-fw` `7220c08`,
  `w17-ground-station` `379cf29`, `iPhone_rc` `7aaf2cf`, `w17-3d-codex` `5dddedb`)
  confirmed identical to the program baseline via `git log -1` on each repo's real
  checkout — nothing moved under this pass.

No BASELINE CONTRADICTION found.
