# KAK — The Long Night: missions in acts — design

**Baseline:** `kak-v0.08.1` (with the v0.08.2 fix batch if it has landed), branch `feat/Develop-Main`.

**Goal:** make a mission more than one goal on one clock. *The Long Night* is played in three acts on the same map. A choice between acts picks the path, and timed events give each act short windows to seize or miss. How each act ends shapes the next.

**Proposed version: v0.09.** Resonance, Awakening Trials and the campaign save move to v0.10. This is the user's call; the work is the same either way.

## Decisions (with the user, 2026-10-04)

| Topic | Decision |
|---|---|
| Shape | **Acts inside one mission:** one map, 3 acts, the town's damage and dead carried through |
| What makes it exciting | **Choices that branch** and **timed events and targets**. Not power growth mid-mission, and not new hunter-type threats (both can come later) |
| Length | **6–10 minutes:** three acts of about 2–3 minutes |
| How a path is chosen | **Both:** a choice card between acts picks the path, and the last act's outcome changes the town you face |
| Failing an act | **Fail forward:** the night goes on, harder. Only the last act can lose the night |
| Loadout | **Re-draft each act:** same slots and DP, any power, all cooldowns reset |
| Placement | **A new Tier 3 mission** on the board. The Warning and Last Judgement stay as they are |

## 1. The Long Night

**Premise.** A star falls over Aldermere at dusk. Through one night the god wakes: first a whisper at the gate, then a blow at the town's heart, and by the end of the night the Citadel falls.

**Board card:** *The Long Night*, Tier 3, "Three acts, one night. Your choices shape the town you face."

**Loadout:** 4 slots and 10 DP, from every power. Re-drafted before each act; this is a starting value, tuned in balance.

```
Act I  The Omen (2:00)
   └─ choice card ─┬─ Act II-A  The Festival   (2:30)
                   └─ Act II-B  The Procession (2:30)
                                   └─ Act III  Judgement (3:00)
```

### Act I — The Omen (2:00)

This is The Warning as it plays today (`WarningDirector`), on an Unaware town, run as an act:
- **Success:** the warning dies, or the omen fades.
- **Failure:** the bell rings.
- **Bonus "Unseen":** the town never reaches Local Emergency.
- **What it carries forward:** the bell rang or not; the alarm stage reached; the dead.

### Between acts — the interlude

The mission freezes, and an interlude screen comes up over it:
1. **The act's result:** ✔ or ✘, its bonus, and the time it took.
2. **The choice card** (after Act I only): two path cards. Each shows its goal, its timed events, and how the town will meet you, given what just happened. Example: "The bell rang: soldiers watch the square."
3. **Re-draft:** the Prepare layout with the act's pool, slots and DP, preselected with the last loadout. All cooldowns reset.
4. **BEGIN** continues the same town into the next act, with a short camera sweep and the act's banner.

### Act II-A — The Festival (2:30)

At dusk the market fills for the Feast of Lanterns: bonfires, dancers, the night's biggest crowd.

**Setup:**
- **The festival crowd:** about 80 citizens are drawn to the market square and stay there (a routine override). Lanterns and bonfires give light, and do no damage.
- **The town:** the Act I outcome sets it (§2).

**Timed events:**
- **0:45 — The bonfire lights:** the crowd packs in tight around the fountain.
- **1:30 — The Mayor's address:** the Mayor (a new named citizen) stands on the fountain for 30 s. Killing him **spreads the panic town-wide** (every festival-goer flees). It is a target, not a requirement.
- **2:30 — The guard closes the square:** soldiers seal the market, and the act ends.

**Success:** the festival is broken. At least 50 festival-goers are dead or have fled the market district before the square closes.

**Failure:** the square closes with the festival standing.

**Bonus "Before the bell":** the bell does not ring during this act. Before the act starts, the bell can already have rung in Act I; the bonus counts only rings during the act.

**Carried forward:**
- Broken: the market lies in ruins, and the town's population stability is already down. Act III opens with **the gates jammed** by people still fleeing the festival.
- Not broken: the town is merely **Organized**, and its marshals hold the gates from the start of Act III.

### Act II-B — The Procession (2:30)

The Prince leaves the Citadel to sail away from the omen.

**Setup:**
- **The procession:** the Prince (a new role, `NOBLE`, with a crown-and-cape look), 4 escort soldiers and 6 attendants. They walk a fixed route from the Citadel gate to the dock, at a stately walking pace.
- **The escorts:** when the Prince is frightened, they **close in** around him (within 1.0). An unseen kill is then much harder.
- **The town:** the Act I outcome sets it (§2).

**Timed events:**
- **1:00 — The blessing:** the procession stops at the cathedral steps for 20 s. Clergy and onlookers gather; this is a window where the Prince stands still in a crowd.
- **2:00 — The ship docks.** The Prince boards when he reaches the dock after 2:00.
- **2:30 — The last tide:** the ship sails, with or without him.

**Success:** the Prince is dead before he boards.

**Failure:** he boards, or the act ends with him still alive.

**Bonus "A quiet succession":** he dies with no witness, using the Silent Doom witness rule.

**Carried forward:**
- Killed unseen: the town is leaderless and confused. Act III starts at **Organized**, and the Citadel's guard is not rallied.
- Killed seen: the town knows a god is abroad. Act III starts **Prepared** (rite, boats, engineers).
- He escaped: the kingdom rallies. Act III starts **Prepared**, the Citadel's soldiers are already on the ring, and the escape limit is 40 instead of 50.

### Act III — Judgement (3:00)

This is Last Judgement compressed into a final act, in the town the night has made.

**Objectives:**
- **Win:** the Citadel is down and stability broken, before 3:00.
- **Lose:** escapes reach the limit (50, or 40 if the Prince escaped). Only escapes during Act III count.
- **Lose:** the clock runs out.

**Timed events.** Each happens only if the town has that response:
- **1:30 — The clergy gather** for the Banishing Rite (Prepared).
- **2:00 — The boats** start taking people from the dock (Prepared).
- **2:30 — The last ferry** leaves; the dock closes.

**Bonus "Dawn never comes":** win with at least 0:30 left.

### Results — the night

- **Each act:** its name, ✔ or ✘, and its bonus.
- **The path taken:** Festival or Procession.
- **Act III's** score lines.
- **A rank for the night**, from acts won, bonuses, and Act III's score.

**The save:** the best night rank, and whether each path has been won. These show on the board card ("Festival ✔ Procession ✘").

## 2. The town between acts (fail forward)

The town's readiness rises with the night. It never falls. An act's outcome is applied when the next act starts:

| After | Outcome | Next act's town |
|---|---|---|
| Act I | warning stopped | Unaware: still asleep, bell not rung |
| Act I | bell rang | Organized; the town is warned (`bell_rung`); soldiers watch the square |
| Act II-A | festival broken | Organized; gates jammed; many already fleeing |
| Act II-A | festival held | Organized; marshals at the gates from the start |
| Act II-B | Prince killed unseen | Organized; no rally at the Citadel |
| Act II-B | Prince killed seen | Prepared |
| Act II-B | Prince escaped | Prepared; Citadel guard rallied; escape limit 40 |

**The dead stay dead and the ruins stay ruined.** Escapes only count toward the act they happen in.

## 3. Architecture

- **`ActDef`** (new) describes one act:
  - id, name, clock, intro banner, camera;
  - primary objectives, bonuses, the director script;
  - a `town(night) -> ResponseProfile` rule;
  - its timed events.

  **`MissionDef`** gains `acts: Array[ActDef]` and `paths`, the choice after an act. A mission without acts plays as today: The Warning and Last Judgement are unchanged.
- **`NightState`** (new) holds what carries between acts:
  - each act's result (won, reason, bonuses, time);
  - the path chosen;
  - the outcome flags (`bell_rang`, `prince`, `festival`).

  An act's director and its `town()` rule read it.
- **A new `Rules` per act, on the same town and crowd.** The old Rules is torn down, and the new one gets the act's clock, objectives, director and loadout, with fresh cooldowns. The Citadel, the dead and the ruins persist.
- **Raising the town mid-mission:** `Crowd.raise_profile(profile)`. The response managers (rite, boats, engineers, marshals) are made at spawn **for every tier**, but act only when the profile turns them on. A raise turns on what the new profile has: rite, boats, more marshals, rallied soldiers. This is the biggest engine change in this design, and it needs its own tests.
- **`EventTimeline`** (new) holds an act's timed events: `[time, id, label, callback]`.
  - Each event fires once, when the act's clock reaches it.
  - Each comes with a banner.
  - The HUD shows the next two events as a small strip under the clock ("1:30 The Mayor's address"). This makes the windows readable.
- **Directors:**
  - Act I reuses `WarningDirector`;
  - `FestivalDirector` (new): the crowd override, the bonfires, the Mayor, the closing of the square;
  - `ProcessionDirector` (new): the Prince and his escort, the route, the blessing, the ship, boarding;
  - `JudgementDirector` (new): Act III's town carry-over and its events.
- **Screens:**
  - **`Interlude`** (new): the act result, the choice card, the re-draft and BEGIN. It sits over the frozen mission, like Pause.
  - **Game flow:** `mission:act_over` → INTERLUDE → `interlude:begin` → MISSION (the same node, next act). The last act → RESULTS.
- **New people:** `NOBLE` (the Prince) and the Mayor (a citizen role, `MAYOR`), each with its own look. Enum values are appended last, as always.

## 4. Measures

- **Tests:**
  - act transitions: a new Rules on the same town; cooldowns reset; the dead kept;
  - `NightState` and every row of §2's table;
  - `Crowd.raise_profile` (each response turns on correctly mid-mission);
  - `EventTimeline` (each event fires once, in order, with its banner);
  - the festival crowd override and its success count;
  - the procession: its route, the blessing stop, boarding, the escorts closing in, unseen versus seen kills;
  - the night's results and save.
- **Behaviour scenario `night`:**
  - `--path=festival|procession`, plus `--act1=` and `--act2=` set to `win`, `lose` or `skip` (forced outcomes), so every row of §2 can be played;
  - each run reports per-act results and times, and Act III's ending.
- **Gates:**
  - The Warning and Last Judgement unchanged: tests, digest, crowd_check, the exact behaviour checksums, FLOW, the Warning cases;
  - FLOW covers one full night through the interlude;
  - the bench: Last Judgement within 5 fps of `kak-v0.08.1`. The festival's 80-person crowd in the market gets its own bench run.

## 5. Milestones (each tagged)

1. **M1 — Acts:**
   - `ActDef`, `NightState`, a new Rules per act;
   - the interlude: result, choice card, re-draft, BEGIN;
   - the night's results and save;
   - *The Long Night* on the board, with Act I (The Warning), Act II as a placeholder ("Hold for 2:30"), and Act III (Judgement without events).
2. **M2 — The town between acts and timed events:**
   - `Crowd.raise_profile` and the §2 table;
   - `EventTimeline` and the HUD strip;
   - Act III's events (rite, boats, last ferry).
3. **M3 — Act II-A, The Festival:** the crowd, the bonfires, the Mayor, the closing.
4. **M4 — Act II-B, The Procession:** the Prince and escort, the route, the blessing, the ship, the quiet succession.
5. **M5 — Wrap-up:**
   - the `night` scenario;
   - balance: act lengths, the night's slots and DP, success thresholds;
   - the bench;
   - a summary, and the tag.

## 6. Open points for review

- **Version:** v0.09 for this, with Resonance, Trials and the campaign save moving to v0.10?
- **Starting numbers, tuned in M5:**
  - 4 slots and 10 DP for the night;
  - festival success at 50 of about 80;
  - escape limits of 50 and 40;
  - act clocks of 2:00, 2:30 and 3:00.
- **Can the act be won early?** The festival could end as soon as 50 have fled, or play on to 2:30. Proposed: an act ends when its success is reached, after a 3 s beat, so a sharp player shortens the night.
- **The Prince's carriage:** the procession is on foot here, because a carriage needs a new moving vehicle. A carriage could come later as art.
