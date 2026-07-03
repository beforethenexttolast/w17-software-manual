# W17 RC Project — Learning Manual

A beginner-friendly technical learning manual for the whole W17 project: a 1/10-scale,
FPV, 3D-printed RC Formula 1 car (Mercedes W17 livery) built around two ESP32 boards
and a laptop ground station.

**Status: PLAN PHASE.** This folder currently contains the *map and study plan*, not
the full manual. The full chapters (including line-by-line code walkthroughs) will be
written in later sessions, following [05_manual_structure.md](05_manual_structure.md)
and [06_learning_order.md](06_learning_order.md).

## The three repositories this manual covers

| Repo | What it is | Runs on |
|---|---|---|
| `w17-control-fw` | The car's "brain": radio in → decisions → servo/ESC out. Owns safety (failsafe, arm gate) and the shared protocols. | ESP32 #1 (control board) |
| `w17-soundlight-fw` | Engine sound synthesis + WS2812 light effects, driven by a one-way UART feed from board #1. | ESP32 #2 (sound + light board) |
| `w17-ground-station` | Viewer-only Electron desktop app: live FPV video + F1-style HUD + telemetry overlay. Does **not** control the car. | Laptop (Windows target; cross-platform) |

## Documents in this folder (plan phase)

| File | Contents |
|---|---|
| [01_system_overview.md](01_system_overview.md) | What the whole system is: hardware, software, and every communication link |
| [02_documentation_map.md](02_documentation_map.md) | What each existing doc in the repos is for, and how trustworthy/current it is |
| [03_codebase_map.md](03_codebase_map.md) | Folders, files, entry points, protocols, state machines, build systems |
| [04_knowledge_prerequisites.md](04_knowledge_prerequisites.md) | Every C++ / embedded / electronics / RC / desktop-app concept you'll need, and where it first appears |
| [05_manual_structure.md](05_manual_structure.md) | The proposed table of contents for the full manual |
| [06_learning_order.md](06_learning_order.md) | The recommended study order, with reasons and per-step prerequisites |
| [07_open_questions.md](07_open_questions.md) | Questions only you can answer (hardware state, intent, history) |

## Ground rules this manual follows

- **Confirmed vs assumed is always separated.** A claim marked *Confirmed* cites the
  exact file (and usually line/section) it came from. A claim marked *Inferred* explains
  the evidence chain. Anything else is labeled *Assumption — verify*.
- **Nothing in the source repos gets modified.** This folder is the only place the
  manual writes to.
- **Beginner-level explanations.** C++ syntax, electronics, and protocol details are
  explained from scratch — nothing is skipped because "a programmer would know it."
