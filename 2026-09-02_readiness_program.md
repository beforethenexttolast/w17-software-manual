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

Filled as waves land (branch, builder verdict, reviewer verdict, merge hash, push). Until then
`CURRENT_STATUS.md` carries the live state.
