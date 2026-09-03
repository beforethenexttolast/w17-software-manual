# W17 Readiness Program — 2026-09-02

> Dated program packet. **Goal (owner, 2026-09-02, verbatim intent):** "EVERYTHING IS READY and
> the only thing remains (before gifting) is assembly." Everything that can be finished without
> hardware is finished and reviewed; the hardware phase (mechanical assembly, harness + A2 staged
> gates, Phase B first power, flashing, bench gates, giftee-PC handover) is the only remaining
> work. Status and hashes live in `CURRENT_STATUS.md`; this file records the owner's decisions of
> the day, the workstreams, and the authorities under which they run. It is the successor of the
> 2026-08-16 orchestration packet for the readiness pass.

## 1. Vision alignment — owner decisions of 2026-09-02

Asked and answered in-session (two AskUserQuestion rounds). Each is a product/process decision;
none touches safety boundaries 1–7 or the hardware gates.

| # | Topic | Decision |
|---|---|---|
| A1 | Stranger-rebuildable manual ("ideally" in v1.0) | **Post-gift.** The manual stays truthful to current code (a staleness truth pass runs now); the rebuild-track chapters may be written by a **parallel, low-priority workflow** for whatever is writable without the bench. |
| A2 | iPhone HUD distribution to Lola's phone | **Free-account Xcode sideload for now** (paid Apple developer account is out while the project is a single gift and unpublished). Consequence accepted: the app must be re-signed from the owner's Mac every 7 days; this is a pit-crew burden and the booklet must say so honestly. The laptop HUD is the primary display; the phone HUD is an extra. |
| A3 | Mechanical design (electronics trays/cassette, second-floor cage for the ESPs, DRS flap linkage, USB-C charge flap, GCS box) | **Claude Code takes over** (owner: "Take over that part as well"). Some parts have been printed by a print shop; test assembly may start. Owner's stated plan: compute the best assembly structure ("what goes where") and possibly an additional inner cage / second floor for devices such as the ESPs. The `w17-3d-codex` repo is the home; `~/Documents/Codex/w17-rc-print-codex` stays a read-only reference. Recorded as an ownership-split change in `CLAUDE.md` (invariant change, owner-authorized). |
| A4 | Real-Windows validation | **Later, via a Windows VM on this Mac**: VMware Fusion (free for personal use) with USB passthrough; the owner connects the adapters, and the environment must let Claude **test almost everything autonomously** (design target: VMware Tools + `vmrun`, OpenSSH server in the guest, snapshots, scripted PowerShell checks). A real Windows PC is the final proof at handover only. |
| A5 | Program approval | **Go, all six workstreams.** |
| A6 | OpenSCAD on this Mac | **Approved** (`brew install --cask openscad`); see §4 for the install outcome. |
| A7 | Push authority | **Full grant for this program** (owner: "I grant you full possible authority"): every reviewed, merged trunk may be pushed; mapper only after its FORK-NOTICE push-review checks; `u4-arbiter` never (hook + rule). The grant closes when the program closes (recorded then in `CURRENT_STATUS.md`). |
| A8 | **Model allocation policy (owner, 2026-09-03)** | Fable 5.1 = scarce supervisory intelligence only (top-level strategy, architecture/root-cause meta-review, adversarial challenge of the aggregate, adjudication of disputed findings, final synthesis). Opus 5 = senior engineering (hard module reviews, boundaries, state/lifecycle/concurrency, subtle correctness, high-severity findings, difficult implementations, independent verification, adversarial review). Sonnet 5 = default workforce (reconnaissance, ordinary review, docs, most implementation + verification, test execution). Haiku 4.5 optional for mechanical low-risk work only. **No workflow or subagent may inherit the session model silently — every agent call carries an explicit model.** Reviewer, implementer and verifier contexts stay independent; no implementer self-certifies; deterministic tools beat opinions; findings persist in durable files; worker output is compressed before expensive synthesis. |
| A9 | **Grand-verdict decisions (owner, 2026-09-03)** | The grand review (159 Opus/Sonnet agents + 3 Fable perspectives + 1 Fable verdict; `scratchpad/review-seeds/grand.verdict.json`) returned NOT READY for assembly-only. The owner **accepted all fifteen recommendations OD-1…OD-15** with these explicit rulings: **OD-1** instruction-file batch approved (one orchestrator-authored commit per repo: cf/sl/GS CLAUDE.md + AGENTS.md — changed invariants: re-arm 2026-08-20, wire-selected voice + volume 2026-08-16, race-day mapper-process management 2026-08-17; GS guardrail 'may manage the mapper PROCESS, never SEND it anything; read-only stream subscriptions are viewer consumers'); **OD-2** ship image = `esp32dev` by default, booklet §5 becomes "two later tricks the pit crew can unlock", upgrade to `esp32dev_btshowoff` only if BT1 passes before handover; **OD-3 (override): phone live video IS a gift deliverable** — H.264 720p60 per the ratified baseline becomes a ranked branch with a design-first step; booklet §4 keeps the live-view promise; **OD-4** GS read-only mapper-gRPC telemetry source + race-day telemetry step + "BATT shows a number on both screens" as a handover gate; **OD-5** mapper self-starts the RF link from the profile's port after SetConfig, refusing REPLACE-WITH-*; card says "running" only when the link is up; the web-UI flag ban stays; **OD-6** code: auto-advance to GRID on race-day success and auto-START when required checks are green (START ANYWAY stays); **OD-7** already-on hotspot with the saved SSID = ok('external'); LEAVE HOTSPOT RUNNING hidden in giftee builds; **OD-8** mapper binds 127.0.0.1 by default (-bind-all for the hobbyist path; pprof flag-gated); **OD-9** lint fatal for W17-marked profiles; placeholders refused in the headless path AND by the GS; hot-plug fixed in code and the booklet; **OD-10** battery sense gains an explicit implausible state (both bounds), no fabricated value, CRSF frame omitted deliberately, no link2 bit now; **OD-11** Hall ISR rate guard with ≥20× margin + a Phase-B measurement row; speedo glitch reads 0; **OD-12** keep cap-then-gamma, raise floors to a named minimum duty + bench gate; enableLoopWDT; implement indicator min-on; **OD-13** per-field placeholders, contract sentence "baseline is unknown, never demo", threshold-parity comment + GS ⚙ note, drop RSSI/SNR from the drive strip with one plain banner, placeholder labels only, demo OFF on cold start + checklist; **OD-14** "CI green at trunk" joins the ready definition — fix the three red jobs first; **OD-15** SHA-256 pin for mediamtx, fetch in CI, packaging assertion. |
| A10 | **Second owner round (2026-09-03) + orchestrator adjudications** | Owner: phone video = design direction (a) or (b) with "lowest possible latency and general comfort" as the priority → **OD-16 (orchestrator adjudication under A8):** transport (a) WHEP/WebRTC pulled from the laptop's mediamtx into a bundled WKWebView; the iPhone_rc rule "one outbound send site" is amended to "one outbound INTENT send site; a read-only media pull is a viewer consumer"; glass-to-glass latency measured at slice 2 and recorded `[bench-TBD]`; (b) native RTSP+VideoToolbox stays the fallback only if the measured latency is unacceptable to the owner. Design Q3–Q8 accepted as recommended (DRIVE profile; auto-start when live; reuse the Windows-host setting, no auto-derive; one clarifying contract sentence; scoped GS change so mediamtx is reachable from the hotspot). **OD-17:** dtClampMs = 50 ms RATIFIED as a policy constant; R12's signed scope WIDENED to the full calib schema (every field the record refuses to load without); FIRST_ACTIVE stays NO-GO. **OD-18:** R15's gated build reaches the Windows VM as a `git bundle`/archive copied by hand — never a push; hook intact; bundle deleted after the session. Builder-question adjudications (orchestrator): iPhone speed outside [0, 1000] km/h renders `--`; stale/lost HUD strings become plain language (contract names Debug-only); demo mode session-only + off at cold start; GS pins the extracted mediamtx binary, windows_amd64 digest recorded after the first windows-latest run then `--require-pin`; mediamtx error retry-forever and one `.bak` generation accepted; cf Hall guard re-arms every 1 s (ruled); sl loop WDT at the framework's 5 s with the asymmetry documented; mapper exit-1 on an unfilled profile accepted (GS branch B surfaces it); B4 scripts require PowerShell 7 and script 60 is reframed (R15 discharged by nothing in the suite). Full text: session scratchpad `briefs/RULINGS-2026-09-03b.md` (copied into `W17_CURRENT_STATE.md`). |
| A11 | **OD-19 (orchestrator adjudication, 2026-09-04, within A8)** | From the Opus review of GS branch B: race day may persist exactly ONE key, `telemetry.source = 'mapper-grpc'`, once, through a narrow store method that never round-trips the hotspot credential (skipped as `unavailable` when the credential state is undecryptable/session-only/unavailable) and the GARAGE screen says the setting changed. `link-down` keeps halting the sequence (OD-5), but a first bring-up reports `link-not-yet` until the mapper has positively claimed link state; the 5 s window is `[bench-TBD]` (WS3 script 50 records the real port-open latency). Unreadable already-on SSID stays fail-closed (OD-7); auto-START ships with no countdown (OD-6); the three `W17_*` dev knobs stay and the namespace table goes into the next instruction-file batch; a smoke:electron scenario boots with `W17_SINGLE_INSTANCE=1`. Refinement (2026-09-04): the skip applies only to `undecryptable` / `session-only` (a credential could be lost); `unavailable` (nothing stored, no OS encryption) proceeds — the one-key patch never round-trips the credential in any state. Full text: session scratchpad `briefs/RULINGS-2026-09-03b.md` (last two paragraphs). |
| A12 | **Two adjudications from the second review round (orchestrator, 2026-09-04, within A8)** | **OD-19 addendum:** race day's auto-START (OD-6) arms only on a POSITIVE link claim (`running`), never on `link-not-yet`/`link-unknown` — the Opus re-verify proved the GRID's TELEMETRY guard does not exist when `telemetry.source` stays `none`, so a dead radio auto-started a cockpit over a car that cannot move; race day still walks to the GRID, with a plain radio line and the headline "ALMOST — THE RADIO IS STILL COMING UP; THE GRID WAITS FOR YOU"; the IT SAID row keeps 8 lines, longest preferred. **OD-9/D2 addendum:** the headless race-day bring-up refuses an UNMARKED profile (the W17 profile must carry `"w17_profile": true`), the editor's SetConfig stays permissive for upstream rigs; the pre-push hook's enum check fails CLOSED on any unparsed line in the HeadIntentState block and compares names case-insensitively; FORK-NOTICE states exactly what the check does; the lint refusal never suggests removing the marker. Full text: session scratchpad `briefs/RULINGS-2026-09-03b.md`. |

Unchanged by this pass: the done-bar 1–8, decisions 1–18, safety boundaries 1–7, A2 NOT-EXECUTED
⇒ Phase B BLOCKED, nothing flashed or powered, FIRST_ACTIVE NO-GO, BT1 bench gate.

## 2. Findings that shaped the program (three probes, 2026-09-02)

- **Test baseline reproduced at every trunk:** control-fw 330 native + 5 envs, soundlight 137 + 2
  envs, GS 1447/67 files + `proto:check` clean, iPhone 74, mapper 180 + `-race` clean (`go vet`
  = the one documented upstream finding). Nits: `iPhone_rc` lacks a `__pycache__` gitignore
  entry; `smoke:electron` stays environment-blocked in agent shells.
- **Runbook layer has holes.** No single parts-to-gift sequence. Missing: giftee-PC install guide,
  coordinated two-board link2-v2 flash procedure, standalone Phase B doc, BT1 bench checklist,
  iPhone distribution procedure, handover / gift-day checklist. Stale: A2 checklist has no
  continuity/isolation rows for the SP3T strap pins GPIO27/GPIO32; `D8_BENCH_BRINGUP.md` teaches
  the pre-2026-08-20 re-arm rule and no boot modes/BT1/simbt/demo:low-battery; D8 flash-before-
  Phase-0 vs `w17-control-fw/CLAUDE.md` no-flash-before-A2 is unreconciled;
  `w17-elrs-backup-handset.md:126-129` says the car may re-arm after recovery (firmware now
  forbids it); GS README says start lights default on (they default off — the booklet's single
  handover item); manual ch. 11/13 env tables list 3 of 5 firmware envs; rebuild stub 21 cites a
  dead branch; GS `SETUP.md` / `setup_flow_bench_checklist.md` predate race-day + NSIS.
- **Head tracking is code-complete, evidence-poor.** R13/R14 close on paper; the parked
  `u4-arbiter` branch (base `432a809`, 14 headtrack commits behind) needs a rebase (one
  `FORK-NOTICE.md` append conflict; fold its private hat decode into `DecodeHatDirection`; note
  the corrected SHARE=4/OPTIONS=6 layout), an evidence-matrix re-run, and a desk R-review of its
  nine recorded deviations. The unlock plan's go/no-go table (`:1333` "no U4 code exists") and
  hook note (`:771-775`) are stale. R15 needs a gamepad + Windows box, not Phase B. R6/R7/R8/R9/
  R10-residual/R16 are bench-only.
- **Environment:** Apple Silicon Mac, no VM software; `w17-3d-codex` print log says nothing printed
  (contradicted by the owner — the real printed-parts list comes from the owner).

## 3. Workstreams (all run under the standard pipeline: builder → adversarial reviewer → fix → scoped re-verify → orchestrator guarded ff merge → push under A7)

| WS | Scope | Repos | Deliverables |
|---|---|---|---|
| 1 | **Multi-workflow code review** (owner's explicit ask) | cf, sl, GS, mapper (`w17-headtrack`), iPhone_rc | One Workflow per repo: dimension reviewers (safety-boundary/gate drift, correctness/robustness, giftee-UX truth vs booklet/vision, docs-vs-code truth) → adversarial verification → confirmed findings → fix builders → reviews → merges. Plus a cross-repo contract check (link2 v2 both copies, windows_bridge_contract mirror, proto snapshot). |
| 2 | **Runbooks** | cf docs/project-review, workspace root, GS docs/README, iPhone_rc docs, mapper CI | Master parts-to-gift sequence (reconciling D8 vs A2 flash order); A2 strap rows; D8 refresh (re-arm, boot modes/SP3T, BT1 checklist promoted from the design draft, two-board flash, simbt, low-battery demo); Phase B standalone; giftee-PC install guide; iPhone sideload ritual (7-day refresh) with the booklet made honest; handover checklist (START LIGHTS on, markers filled, re-sign schedule); every stale line in §2; a W17 mapper release job bundling `elrs-joystick-control.exe` + `configs/w17-ds4.json`. |
| 3 | **Windows validation path** | workspace runbook + GS `scripts/` | VMware Fusion + Windows 11 ARM runbook designed for autonomous driving (vmrun, guest OpenSSH, snapshot "clean-giftee-PC", USB passthrough list), PowerShell validation scripts (install, hotspot, mDNS, mapper profile, one-action race day, R15 pad-unplug). Session runs when the owner installs the VM. |
| 4 | **Head-tracking desk work** | mapper branch `u4-arbiter` (+ backup ref), cf `project-review/head_tracking_unlock_plan.md` | Rebase onto `9cb501e`; evidence re-run (matrix, nm, hex dumps); plan table + hook-note refresh; fresh adversarial desk R-review (adjudicate 9 deviations; close R13/R14 on paper); calibration-record template with blank numeric slots. Branch stays unmerged + unpushed. |
| 5 | **Mechanical takeover** | `w17-3d-codex` (+ CLAUDE.md/WORKSPACE_MAP/vision ownership lines, done by the orchestrator) | Placement study ("what goes where") from the envelope/keep-out registers + batch-1 measurements + the ZK cassette study, incl. the second-floor cage concept; parametric OpenSCAD drafts (cage/trays, DRS linkage check, charge-flap placement, GCS box) with fit-check test prints first; a printable no-power measurement-session prompt for the owner (incl. the printed-parts inventory). Final dimensions are measurement-gated. |
| 6 | **Manual** | `learning-manual/` | Staleness truth pass against every trunk (ch. 11/13 env tables, stub 21, booklet honesty line for the phone HUD + handover note); rebuild chapters writable today as a low-priority parallel workflow. |

Close-out: full baseline re-run; a dated vision-alignment audit workflow (successor of
`2026-08-16_vision_audit_report.md`); `CURRENT_STATUS.md` + memory brief updated; push grant closed.

## 4. Environment record

- `brew install --cask openscad` (2026-09-02): **cask disabled upstream 2026-09-01** (fails the
  macOS Gatekeeper check). Alternative recorded in `CURRENT_STATUS.md` once resolved.

## 5. Pipeline record

**2026-09-03 — WS-1 review sweep COMPLETE (v2 topology).** The first attempt (2026-09-02) let every
workflow worker inherit Fable and died on the usage limit; the scripts were rewritten with explicit
routing (A8) and re-run with the retained Fable-era results replayed from seed files (9 reviewers,
12 verdicts kept; nothing re-derived). v2 run: **159 agents (127 Opus, 32 Sonnet), 0 failures.**
Per-repo synthesized reports (durable, session scratchpad `review-seeds/<repo>.v2report.json`):
control-fw 16 ranked (2 gift-blocking: Hall ISR rate unbounded, battery-sense implausibility floor
missing), soundlight 19 (2 gift-blocking: brightness cap before gamma renders quiet states at PWM 1,
sim feeder), ground-station 18 (8 gift-blocking; blockers: race day never starts the radio link,
zombie process after a cancelled quit), mapper 16 (7 gift-blocking; blockers: `-config-file-path`
double-wraps the profile so the headless mapper panics, race day never starts the link), iPhone 14
(blocker: telemetry merge baseline seeded with demo values, so omitted fields render as live numbers
incl. the battery that arms the low-battery banner). Grand review (3 Fable perspectives + 1 Fable
verdict) launched over the compressed digest; builder sweep 2 relaunched on Sonnet/Opus with durable
briefs (`scratchpad/briefs/`). 
**2026-09-03 — recovery + first landings.** Second usage-limit stop recovered from durable state
(`2026-09-03_recovery_checkpoint.md`); grand review's three Fable perspectives retained, the verdict
re-run as a bounded one-agent workflow. Cross-repo probe COMPLETE (10 checks; 8 with drift, none
touching a safety boundary; report in the scratchpad `review-seeds/cross-repo-probe.md`).
Landed: **iPhone_rc main = `61ad68f`** (B5 giftee install docs: `docs/GIFTEE_INSTALL.md` free-account
sideload + provisioning; contract references repointed; head-tracking packet examples fixed;
canonical contract's stale related-doc line removed → GS mirror re-sync in flight) — built Sonnet,
adversarially reviewed Opus (FIX_REQUIRED ×3 blocking, all fixed), re-verified Sonnet PASS, 74/74,
**pushed** under A7. In flight: B1/B2/B3/B7 branches in review/fix/verify; B8 desk R-review; B4/B6/B9
builders; the Fable verdict.

**2026-09-03 — verdict + second landings.** Grand verdict delivered (see A9). Landed and PUSHED:
**mapper `w17-headtrack` = `21834fe`** (B7 W17 Windows release job + FORK-NOTICE row + configs/README
packaged-release section; Sonnet build → Opus review FIX_REQUIRED ×4 → Sonnet fix → Sonnet re-verify PASS;
180 tests, hook greps clean; the job's first useful run is deferred until mapper branch A lands MAP-1/2);
**control-fw main = `7c00668`** (B8's unlock-plan refresh: R13 dated amendment, hook note, layout note;
Opus desk R-review MERGE_CLEAN). `u4-arbiter` @ `8007603` stays parked, never merged/pushed, backup ref
intact; its desk R-review returned FIX_REQUIRED on one miscitation (dtClampMs cites D10 wrongly) plus
an R12 scope gap and the R15 transport question (owner items). B1/B2/B3 branches in fix; B4/B6/B9
complete awaiting review. Fix wave launched per the verdict's branch list.
**Also landed + PUSHED: ground-station main = `35e5efc`** (B3: Sonnet build → Opus review FIX_REQUIRED ×2 blocking
→ Sonnet fix → Sonnet re-verify (one banner sentence corrected, body byte-identical to canonical `61ad68f`)).
Fix wave in flight: mapper A (Opus), GS A (Opus), cf sensor-honesty-and-ci (Opus), sl lights (Opus), sl docs (Sonnet),
iPhone telemetry-honesty-and-ci (Opus), OD-3 phone-video DESIGN (Opus), OD-1 instruction-file batch (Sonnet);
u4-arbiter fixer (Opus) on the desk-review items; reviews of B4/B6/B9 (Opus); B1/B2 fixers (Sonnet).

