# W17 PROCUREMENT AND PHYSICAL ACTIONS (v0.1 Director seed, 2026-09-05 — the D1 worker's reconciliation replaces this)

Buckets: BUY NOW (blocks foreseeable work) · CHECK IF I ALREADY HAVE · OPTIONAL · WAIT (resolve requirement first).
Fields: requirement/spec · why · unlocks · evidence/source · exact model necessary? · status.

## BUY NOW
| item | requirement | why | unlocks | source | exact model? | status |
|---|---|---|---|---|---|---|
| 5 GHz AP-capable USB Wi-Fi adapter | Mobile-Hotspot-capable on Windows 11 **ARM64** (driver must exist for ARM64) and 5 GHz SoftAP | hotspot half of the WS3 validation suite; race-day hotspot on the giftee PC | 30-hotspot.ps1, giftee-ux-2 checks | runbook §0 box, §1.8 | chipset family matters, exact model not: Realtek RTL8812AU/BU class (e.g. Alfa AWUS036ACH) primary per A3; x64 Windows only — NO ARM64 driver exists (VERIFIED/OBSERVED) | WAIT: owner decision on hotspot host + gift-kit scope (see W17_OWNER_ACTIONS.md) |
| In-envelope 2S car pack | ≤70×40×22 mm target, hard fail 75×45×25; 2S soft-case ≥25C JST-XH balance, XT60 preferred | car has no fitting battery | Phase B on-car power (later) | HARDWARE_INVENTORY.md "Not on hand yet" #1 | no — shop to dimensions | not sourced |

## CHECK IF I ALREADY HAVE
| item | requirement | why | source | status |
|---|---|---|---|---|
| Powered USB hub | externally powered, USB-A ports for DS4 + ELRS TX + Wi-Fi adapter simultaneously | passthrough of three devices to the VM | runbook §1.8; CURRENT_STATUS residue list | a USB3.2 hub is attached now (OBSERVED) — powered? unknown |
| SP3T switch | boot-mode selector, size per M-13 | selector-driven shelf show / boot mode | measurement prompt M-13; CURRENT_STATUS residue | unknown |
| USB-C cables / USB-A→C, micro-USB for ESP32 boards | data-capable | flashing (later, gated) and bench | control-fw COORDINATED_FLASH.md | unknown |

## OPTIONAL
| item | why | status |
|---|---|---|
| ELRS TX label (printed) | booklet/handover clarity | pending D1 |
| External SSD ≥ 256 GB | VM disk if internal space cannot be freed | owner choice |

## WAIT
| item | resolve first | source |
|---|---|---|
| 2S balancing USB-C charge module | OP-49 decision (IP2326 ×2 on hand vs other) | HARDWARE_INVENTORY.md #4, OP-49 |
| TX16S-related item | D1 to identify the exact check (module bay / firmware / USB mode) | CURRENT_STATUS residue list |
