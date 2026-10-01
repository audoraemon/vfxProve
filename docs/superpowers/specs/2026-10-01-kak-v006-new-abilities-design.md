# KAK v0.06 — New abilities — design and plan

**Baseline:** `kak-v0.05`.

**Goal:** abilities of new kinds, not only destruction. Four small-radius powers, one of each kind:
- **control:** move the crowd;
- **route control:** reshape the streets;
- **sabotage:** undo the town's organization without killing;
- **curse:** spread over time.

Each plays against systems the town already has. The Prepare screen gains tabs by kind.

## Decisions (with the user, 2026-10-01)

| Topic | Decision |
|---|---|
| Kinds wanted | All four: crowd control, route control, sabotage responders, curses/economy |
| First batch | One per kind: **Will-o'-Wisp**, **Thornwall**, **Discord**, **Pestilence**. The rest of the suggestions wait for a playtest (Dread, Mire, Veil of Silence, False Omen, Gorgon's Gaze, Soul Harvest) |
| Prepare screen | **Tabs by kind** (Cataclysm, Control, Quiet, Curse) with a loadout bar for the four picks |

## 1. The abilities

| Power | Tab | DP | Cooldown | Aim | Quiet |
|---|---|---|---|---|---|
| Will-o'-Wisp | Control | 10 | 25 s | click | yes |
| Thornwall | Control | 14 | 30 s | drag | no (+1 alarm) |
| Discord | Quiet | 10 | 20 s | click | yes |
| Pestilence | Curse | 16 | 40 s | click | yes (its deaths are not) |

### 1.1 Will-o'-Wisp
- **The light:** a pale light hovers at the aim point for `WISP_TIME` (12 s), drifting a little, flickering, shedding motes.
- **The lure:** up to `LURE_MAX` (25) citizens within `LURE_REACH` (6), nearest first, walk to it. They come from the minds Calm, Recover, Watching (observe) and Regroup. They gather in a loose ring 0.8–1.6 from it and stand staring until it fades, then go back to their day.
- **Unaffected:** soldiers, and anyone fleeing, panicking, sheltering, inside a shelter, or on duty (the bellkeeper, the clergy, the engineers).
- **Quiet:** no threat and no alarm. Anything that frightens the gathered crowd works on them as usual.

### 1.2 Thornwall
- **The wall:** a line of brambles `THORN_LENGTH` (3) long, centred on the press, along the drag, made of `THORN_SEGMENTS` (5) square segments of 0.6. It grows over 0.6 s, blocks walking for `THORN_TIME` (25 s), then withers and is removed.
- **People in the way:** anyone standing on a segment as it grows is shoved to the nearest free ground, unhurt.
- **Effect on the town:** the walk grid closes under it. Evacuation routes rebuild, gate queues recompute their spots, and evacuees reroute or jam behind it.
- **Alarm:** +1 (`Crowd.THORN_ALARM`), and citizens within 3 stop to look.
- **Counters:**
  - **Engineers:** a new job, Clear: priority 70, `CLEAR_TIME` 5 s per segment, which removes the segment.
  - **Fire:** the segments are tree-kind structures (tag `thorns`, 30 hp), so they burn and fall to the player's own powers.
  - **Bookkeeping:** a destroyed segment counts like a felled tree, not as a building.

### 1.3 Discord
- **The effect:** every citizen within `DISCORD_R` (1.2) is confused for `DISCORD_TIME` (15 s). They wander near where they stand, with a swirling sigil over their heads, then resume:
  - those who were fleeing flee again;
  - everyone else recovers and returns to their day, and the responders' managers take them back.
- **What it breaks** (the managers already drop anyone who leaves duty):
  - the rite (clergy step out; under 2 in the ring breaks it);
  - the bell (the climb drops; the bellkeeper retries 10 s after recovering);
  - the engineers (the work stops);
  - the fire brigade (responders leave the fire).
- **Evacuees** stop and wander, so a gate, postern or dock queue loses people for 15 s.
- **Quiet:** no threat and no alarm. Soldiers are not affected.

### 1.4 Pestilence
- **The cast:** infects up to `INFECT_MAX` (3) people within `INFECT_R` (0.8), nearest first. Citizens only; soldiers are immune.
- **The sick:** green-tinged, with cough motes, moving at 70% speed. Each dies `PLAGUE_LIFE` (30 s) after infection, with the damage kind `plague`.
- **Spread:** every `SPREAD_EVERY` (3 s) each sick person infects each healthy citizen within `SPREAD_R` (0.6) with chance `SPREAD_CHANCE` (0.3), up to `PLAGUE_MAX` (60) sick at once. People inside a shelter count: a sick person who takes cover infects the others inside at the same chance each tick.
- **Quiet when cast.** A plague death is an ordinary death: it counts, raises the alarm and is an incident.
- **Boats:** a sick person who boards escapes like anyone else.

## 2. How it is built

### 2.1 Shared
- **Cast lock:** `FxTimeline.busy` (seconds; −1 = the whole duration). `Rules.busy_left()` uses it when set. The four new effects lock about 1 s while they linger. Every existing power keeps its whole-duration lock.
- **Structure signals:** `EnvironmentField` emits `structure_added` (from `add_structure`) and `structure_removed` (from `remove`).
  - `WalkGrid` stamps an added non-walkable structure solid (`refresh`). On removal it reopens the ground as on destruction.
  - `Crowd` clears its cached gate queue spots on either.
- **Power kinds:** each `PowerBook` entry gets `"kind"`: cataclysm, control, quiet or curse. Quiet casts skip `Crowd.on_cast()`'s danger reaction as in v0.05; Thornwall is quiet to `on_cast` and reports its own +1 alarm (2.3).
- **Prepare screen:**
  - a tab row above the grid, with a count per tab and a gold dot on any tab holding a pick;
  - a 3-column grid of 140×50 cards for the open tab;
  - a loadout bar (the four picks in slot order, with MANIFEST) between the grid and the difficulty strip.
  - The tab under the mouse, or Tab / Shift-Tab, switches. The tab of the first pick opens first.

### 2.2 Will-o'-Wisp
- `Person.lure(at, seconds)`: the Watching mind with a walk to a spot round `at`, its watch timer set to `seconds`. It stands on arrival, as Watching already does.
- The effect (`src/fx/control/will_o_wisp.gd`) picks the persons from `ctx.field`, draws the light (a light quad, a flickering core, motes), and sets `busy` 1.0 and `duration` = `WISP_TIME`.

### 2.3 Thornwall
- The effect (`src/fx/control/thornwall.gd`):
  - adds the segments with `ctx.env.add_structure(..., Kind.TREE, &"thorns", &"thorns")`;
  - shoves people off them;
  - removes the segments still standing at `THORN_TIME` (`env.remove`);
  - `busy` 1.0.
- **Art:** `PropArt._thorns()`: tangled dark stems, thorns and dark berries, about 14 px tall, swaying with the wind material.
- **Crowd:** on `structure_added` with role `thorns`, +1 alarm, and calm citizens within 3 watch it. `Crowd._on_structure_destroyed` treats thorns like decor.
- **EngineerManager:** `Job.CLEAR` (priority 70) for standing thorn segments. Clearing takes `CLEAR_TIME` with both at the site, then `env.remove()`.

### 2.4 Discord
- A new Person mind **CONFUSED**, with a new Intent **CONFUSED** drawn violet in the overlay. `Person.confuse(seconds)` remembers whether the person was fleeing, then drifts round where it stands; the sigil is drawn over the head.
- On expiry: `flee()` if it was fleeing, otherwise `_recover()`.
- `panic()` still works on the confused.
- The effect (`src/fx/quiet/discord.gd`): the swirl at the aim and the confusion of citizens within `DISCORD_R`; `busy` 0.6.

### 2.5 Pestilence
- `PlagueManager` (`src/game/crowd/plague_manager.gd`), made by `Crowd.spawn()` and stepped in `advance()`:
  - **The sick:** `Person.sick_left` (seconds to live; 0 = healthy) and the 70% pace.
  - **Spread:** a tick every `SPREAD_EVERY` over the sick list, using `EnemyField.in_radius`. People inside a shelter spread to the others inside.
  - **Deaths:** `EnemyField.kill(p, &"plague")`.
- **Look:** a green tint and cough motes, in `Person._draw_citizen`.
- **Infection:** the effect (`src/fx/curse/pestilence.gd`) infects through `Person.infect()`, which `PlagueManager` collects next step (it scans the citizens for newly sick). `busy` 0.8.
- `Rules.POWER_KINDS["pestilence"] = [&"plague"]`, so plague deaths count toward the caster's chains.

### 2.6 Assets
- **Icons:** painted by `tools/dev/make_power_icons.py` (the quiet-icon script, extended and renamed) at 84 and 42 px:
  - a pale wisp over a dark field;
  - a thorn tangle;
  - a broken spiral over a staring eye;
  - a green plague skull.
- **Clips:** recorded in the real mission (`behaviour_check.gd --scenario=clip --power=<key>`), because the sandbox's dummy troopers cannot be lured, confused or infected.

## 3. Measures
- **Tests:** one test file per ability.
  - Wisp: who is lured and who is not, the ring, the release.
  - Thornwall: the grid closes and reopens, rerouting, the shove, the engineers clearing it, the alarm.
  - Discord: each response interrupted and recovered; evacuees resume fleeing.
  - Pestilence: infection, the spread chance and cap, deaths, shelters.
  - Plus the Prepare tabs and loadout bar, and the cast lock.
- **Behaviour scenario `powers`:** each ability cast in the mission with its counts (lured; queue size behind the wall; the confused and the responses interrupted; infected and dead over 60 s), plus captures.
- **Gates:** tests, digest, FLOW, crowd_check, mission test, and a bench against `kak-v0.05` (at most a 5-fps loss).

## Milestones (each tagged)
1. **M1 — Framework:** the cast lock, power kinds, structure signals with the grid and crowd hooks, the Prepare tabs and loadout bar.
2. **M2 — Will-o'-Wisp.**
3. **M3 — Thornwall**, with the engineers' Clear job.
4. **M4 — Discord.**
5. **M5 — Pestilence.**
6. **M6 — Assets and tuning:** icons, clips, the `powers` scenario, the bench, the v0.06 summary, tag `kak-v0.06`.

---

## Changes made while executing

### M1
- **The cast lock:** `FxTimeline.busy`, read by `Rules.busy_left()`.
- **Power kinds:** every PowerBook entry has a `kind`, and `PowerBook.KINDS`, `KIND_TITLES`, `of_kind()` and `kind_of()` exist.
- **Structure signals:**
  - `EnvironmentField.structure_added` / `structure_removed`. The walk grid stamps or reopens; the crowd clears its gate spot cache.
  - `remove(s, announce := true)`: the town's teardown removes silently (`announce` false), so a restart does not walk the grid through every building.
- **Prepare screen:**
  - **Tabs** (title and count, gold when open, with a gold mark when holding a pick). Tab / Shift-Tab and clicks switch; the first pick's tab opens first.
  - **The open tab's cards** in the 3-column grid at y 60.
  - **The loadout bar:** four slots with the icon, the slot number and the name (cut to fit), each giving its pick back on a click, then MANIFEST.
  - Hovering a slot previews its power in the left panel.
- **The plan moved icons and clips forward:** each power's milestone brings its own, because the tests require one for every power.
- **Checks:** FLOW 24/24; crowd_check unchanged at −346732806; digest unchanged; 931 checks.
