# Session prompt — vet a candidate 2S pack against the W17 envelope (no hardware)

Paste into a Claude Code session started at `~/Documents/projects`. Short, repeatable — run it once
per candidate listing. This is **the one line that blocks the car ever moving**.

---

I'm sourcing the in-envelope 2S LiPo. I'll paste a product listing (or several); check each against
the W17 spec and give me a **GO / NO-GO per candidate**, with the reason.

## State of play — read `HARDWARE_INVENTORY.md` §D/§E first

- **Zero in-envelope packs exist.** The ZEEE 1500 mAh recorded as arrived on 2026-07-29 **never
  arrived** — "one battery" in the owner's report was mapped to the *ordered* 1500 line and the
  order-spec dimensions were then written in as though measured. Corrected 2026-07-31.
- The only battery on hand is the **5200 mAh, 138×47×37 mm** — out of envelope on all three axes
  (+63 / +2 / +12; ≈3.9× the volume). **Bench-only, not a car pack.**
- Nothing is owed against an order. I may buy **to spec rather than to the ZEEE part number**.

## The spec

| Property | Requirement | Why it bites |
|---|---|---|
| **Envelope** | ≤ **75 × 45 × 25 mm** | Two independent reasons, both already established: `w17-3d-codex/BUILD_SHEET.md` ruled a **115**×35×24 pack won't fit the 2024 body; and the Z3 central tub is only **14–40 mm wide where it is ≥45 mm tall** |
| **Cells** | 2S | |
| **Capacity** | **any that fits** — 1300 / 1500 / 1800 mAh all fine | "1500 mAh" was never a requirement, only the number on the order |
| **C rating** | **≥ 25C** (30C+ preferred) | Gentle use ≠ gentle *peaks*. A punch into a stalled motor through a 120 A ESC will sag a 10C pack and brown out the receiver. 1500 mAh × 25C ≈ 37 A burst = ample |
| **Case** | soft-case | |
| **Main lead** | XT60 — **or re-terminable to XT60 by me** | S7 of A2 probes from battery −, and the assembled chain is pack XT60 f → XT90-S pigtail → PDB |
| **Balance lead** | JST-XH | the IP2326 2S charger is a balancing charger |
| **Quantity** | 1 is enough to make the car drivable | the ×2 is **runtime insurance, not a gate** (`learning-manual/05…:395`). Buying two at once is still the practical call given how hard this is proving to source |

## How to judge a listing

- **Treat listed dimensions as a claim, not a measurement** — that is precisely the mistake this file
  is recovering from. Say "listing claims 70×35×19, unverified" and note that it must be calipered on
  arrival before anything is derived from it.
- Watch for the **lead/balance connector being sold separately or unspecified** — very common, and it
  changes whether I need to re-terminate.
- If a candidate is marginal on one axis, say which axis and by how much; don't round in the pack's
  favour.
- If a listing omits a spec, mark it **unknown** rather than assuming a typical value.

## Output

Per candidate: **GO / NO-GO / MARGINAL**, the deciding property, and what would need calipering on
arrival. If a candidate is a GO, remind me to log it in `HARDWARE_INVENTORY.md` as **⏳ ordered** —
not ✅ — and that ✅ requires a calipered measurement, not the owner's word for "a battery."

**Safety:** no hardware, nothing powered. Buying is not powering — arrival of a pack moves **no** gate.
A2 stays NOT-EXECUTED, Phase B stays BLOCKED. Any charging (IP2326) is powered work → Phase B only.
Show diffs before committing; branch off main.
