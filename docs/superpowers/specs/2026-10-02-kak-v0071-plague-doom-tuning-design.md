# KAK v0.07.1 — Pestilence and Silent Doom tuning — design

**Baseline:** `kak-v0.07`.

**Goal:** make two powers useful after a playtest.
- **Pestilence** kills too slowly (30 s), and the sick are hard to see in a crowd.
- **Silent Doom** has a small area, takes at most 3, and waits 15 s between casts.

## Decisions (with the user, 2026-10-02)

| Topic | Decision |
|---|---|
| Plague life | **5 s** from catching it to death (was 30) |
| Spread | **Every 1 s**, a 30% chance per healthy person within 1.0 (was every 3 s). Still at most 60 sick at once |
| Soldiers | **Catch the plague** like citizens: at the cast, by spreading, in shelters |
| The sick's look | **Strong body tint plus a pulsing ground ring**, green when caught, turning red as death nears |
| Spread effect | **A green smoke puff** on each new infection, in the cast's colours |
| Silent Doom | **Cooldown 2.5 s** (was 15). It takes **everyone living within its radius**, with no cap. Radius 0.8 and 8 DP unchanged |

## 1. Pestilence

### 1.1 Rules
- `PlagueManager.PLAGUE_LIFE` 30 → **5.0**; `SPREAD_EVERY` 3 → **1.0**. `SPREAD_R` 1.0, `SPREAD_CHANCE` 0.3 and `PLAGUE_MAX` 60 are unchanged.
- **Soldiers catch it.**
  - `Person.infect()` no longer refuses soldiers.
  - `PestilenceFx.victims_at()` includes them, so the cast takes the 3 nearest people of any kind.
  - `PlagueManager._spread()` passes it to them.
  - `PlagueManager._collect()` also scans `crowd.soldiers` for the newly sick.
  - A soldier killed by the plague is an ordinary soldier death: Military stability, +0.4 DP, score.
  - Sick soldiers move at `SICK_PACE` (70%), as citizens do. Discord still ignores soldiers.
- Unchanged:
  - the cast is quiet;
  - a plague death is an ordinary death (it counts, raises the alarm, is an incident);
  - the sickness waits under rubble (v0.07);
  - a death inside a shelter is carried out first.

### 1.2 Looks
- **`Person.sick_stage()`**:
  - 0 when healthy;
  - 1 to 5 while sick, from how much of the sickness has run (`1 − sick_left / sick_total`), in five equal steps.
  - `infect()` stores `sick_total`.
- **`Person.sick_color()`**: `SICK_TINT` green at stage 1, blending to a new `SICK_RED` at stage 5.
- **Body tint**, citizens and soldiers alike:
  - **Citizens:** the skin, coat or robe and legs blend strongly toward `sick_color()` (skin 0.6, clothes 0.55).
  - **Soldiers:** the skin, mail and tabard blend the same way.
  - The cough mote stays, coloured `sick_color()`.
  - `_art_signature()` includes the stage, so the sprite redraws as it changes. That means 5 redraws over 5 s.
- **Ground ring:**
  - `PlagueManager.draw_ground(ci)` draws a small iso ellipse (radius 0.32 ground units) under every visible sick person, in `sick_color()`. Its alpha pulses at about 3 Hz.
  - All rings are drawn in one `draw_multiline_colors()` call, on the crowd's ground drawer (z −3, under people).
  - `Crowd.ResponseDrawer.showing()` is true while anyone is sick, so the drawers redraw then.
- **Spread puff:**
  - On each new infection by spreading (not at the cast, which has its own miasma), `PlagueManager` spawns a `PixelParticles` puff at the victim.
  - The puff uses shape PUFF, `PestilenceFx.MIASMA` colours, 6 particles and about 0.8 s of life, with the cast's drag and rise.
  - It is parented to the crowd's overlay drawer (z 60), with its own visual RNG so the spread's rolls are unchanged.
  - At most `PUFF_MAX` (40) puffs are alive at once; extra infections get none.
  - Puffs free themselves.
- **Card text:** PowerBook `shape` reads "a fast plague spreading through crowds".

## 2. Silent Doom
- PowerBook `cooldown` 15 → **2.5**. Its effect lasts 1.4 s, inside the cooldown, and the cast lock does not limit it.
- `SilentDoom.victims_at()` returns **every living person within `RADIUS` (0.8)**, citizens and soldiers. `VICTIMS` is removed.
- The aim preview already rings what `victims_at()` returns, so it rings them all.
- **Witnesses:** unchanged. Anyone living within `Crowd.DOOM_WITNESS` of a victim sees it.
- **Card text:** `shape` reads "everyone within reach struck down, unseen".

## 3. Measures
- **Tests:**
  - **`test_plague`:**
    - the 5 s life;
    - spreading each 1 s;
    - soldiers catch it from the cast, from spreading, and their deaths count as soldier kills;
    - `sick_stage()` rises 1 → 5, and `sick_color()` runs from green to red;
    - the ring is drawn while anyone is sick (`ResponseDrawer.showing()`);
    - a spread puff is spawned per spread infection, capped at `PUFF_MAX`.
  - **`test_quiet`:**
    - Doom takes all within reach (five packed, all taken) and nobody beyond;
    - the cooldown is 2.5 s.
- **Runs:**
  - the `powers` scenario's plague and combo cases (new numbers for the summary);
  - a mission bench against `kak-v0.07`, plus one bench with 60 sick in view, to cost the rings and puffs.
- **Gates:** tests, digest, crowd_check, FLOW.

## Milestone
One milestone, tag `kak-v0.07.1`:
1. Plague rules.
2. Plague looks.
3. Doom.
4. Measurements, summary, tag.
