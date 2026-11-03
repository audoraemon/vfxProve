# Kingdoms Amid Kataclysm (KAK) - Ruin Ability Levels Summary

*Engine: Godot 4.7.2. Branch `god/ruin-levels` (cut from the design commit `7c5a00d5`), landing on `feat/god-progression`. Each of Ruin's ten powers now has five levels and a level-5 twist. Built 2026-11-03, straight through and subagent-driven: a groundwork task, ten twist tasks in three parallel tracks, an opus final review that said "fix first", one fix wave, a clean re-review, and this note. Spec: `docs/superpowers/specs/2026-11-03-kak-ruin-ability-levels-design.md` (approved: "All look good"). Plan: `docs/superpowers/plans/2026-11-03-kak-ruin-ability-levels.md`. Every ruling is in `docs/KAK_God_Ruin_Levels_Rulings.md`. The levels framework itself is `docs/KAK_God_P1_Summary.md`.*

## What levels do

- Each power has **five levels**. Each level raises two or three of its numbers by roughly 10-15% (the tables below), and one of them is the cooldown.
- **Level 5 adds a twist**: a new behaviour, not a bigger number. A level-4 cast never shows it.
- **Level 1 is today, exactly.** Hunts, routes and the reference set play at level 1, so nothing moved: `digest` `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679` are unchanged and no reference row was re-recorded.
- **Might** is not in the tables: it is the existing rule (the base cost at levels 1-2, +1 at levels 3-4, +2 at level 5), and a test proves it equals the spec's Might column.
- The skill tree prints what the next level changes in plain words ("kill radius 0.6 -> 0.65, damage 45.0 -> 50.0, cooldown 10.0 -> 9.5"), and level 5 prints the twist line.
- The cooldown is now per level: `PowerBook.cooldown(key, level)`. Wrath of the Sky and Earthshatter are once a night and have no cooldown column.

## The ten tables

Level 1 / 2 / 3 / 4 / 5. Names are the effect's own constants with the tree's short words in brackets.

| Tier | Power | Stat (word) | Values | Cooldown (s) |
|---|---|---|---|---|
| 1 | Smite | `KILL_R` (kill radius) | 0.6 / 0.65 / 0.7 / 0.75 / 0.8 | 10 / 9.5 / 9 / 8.5 / 8 |
| | | `DAMAGE` (damage) | 45 / 50 / 55 / 60 / 65 | |
| 1 | Ember (quiet) | `START_LEVEL` (start fire) | 0.45 / 0.5 / 0.55 / 0.6 / 0.65 | 15 / 14 / 13 / 12 / 11 |
| | | `REACH` (reach) | 1.0 / 1.0 / 1.2 / 1.2 / 1.4 | |
| 2 | Tornado | `PULL_RADIUS` (pull radius) | 3.2 / 3.4 / 3.6 / 3.8 / 4.0 | 45 / 45 / 42 / 40 / 38 |
| | | `LIFETIME` (life) | 10 / 11 / 12 / 13 / 14 | |
| 2 | Scatter Strike | `BLASTS` (bursts) | 12 / 13 / 14 / 15 / 16 | 30 / 29 / 28 / 27 / 25 |
| | | `KILL_R` (kill radius) | 0.9 / 0.9 / 1.0 / 1.0 / 1.1 | |
| 3 | Light of Solaris | `RADIUS` (radius) | 2.2 / 2.4 / 2.6 / 2.8 / 3.0 | 105 / 100 / 100 / 95 / 90 |
| | | `BEAM_TIME` (burn time) | 5.0 / 5.0 / 5.5 / 6.0 / 6.5 | |
| 3 | Dragonfire | `BREATH_TIME` (breath) | 2.4 / 2.6 / 2.8 / 3.0 / 3.2 | 54 / 52 / 50 / 48 / 46 |
| | | `SWEEP_ARC` (sweep, radians) | 1.0 / 1.0 / 1.1 / 1.2 / 1.3 | |
| 4 | Tsunami Breaker | `LENGTH` (travel: how far the wave runs along the drag) | 6.5 / 7.0 / 7.5 / 8.0 / 8.5 | 60 / 58 / 55 / 53 / 50 |
| | | `WIDTH` (wall width) | 8.0 / 8.5 / 9.0 / 10.0 / 11.0 | |
| 4 | Cinderfall | `STONES` (stones) | 20 / 22 / 24 / 26 / 28 | 75 / 72 / 70 / 66 / 62 |
| | | `RADIUS` (rain radius) | 5.8 / 5.8 / 6.2 / 6.6 / 7.0 | |
| 5 | Wrath of the Sky | `STORM_TIME` (storm) | 25 / 27 / 29 / 31 / 33 | once a night |
| | | `VOLLEY` (bolts) | 5-7 / 5-7 / 6-8 / 6-8 / 7-9 | |
| | | `VOLLEY_EVERY` (volley every) | 1.3 / 1.3 / 1.3 / 1.2 / 1.2 | |
| 5 | Earthshatter | `MAX_LENGTH` (longest crack) | 18 / 20 / 22 / 24 / 26 | once a night |
| | | `HALF` (fall width) | 1.1 / 1.2 / 1.2 / 1.3 / 1.4 | |
| | | `SPEED` (crawl) | 2.0 / 2.0 / 2.2 / 2.2 / 2.5 | |

Tsunami's two names are the spec's labels swapped (R1): the numbers follow the constants, and the docs and tree say "travel" for `LENGTH` and "wall width" for `WIDTH`.

## The ten twists (level 5 only)

- **Smite, Forked Bolt.** 0.12 s after the strike, a full Smite falls on the nearest other living person in the open within 2.5 of the bolt, even if the first bolt hit nobody. Nobody in reach, no fork.
- **Ember, Leaping Spark.** One second after the first house catches, a second spark jumps to the nearest other standing building within 3.0 that is not already burning. Still quiet: no fright, no alarm.
- **Tornado, Twin Funnels.** When it dies it splits in two small twisters (pull 1.8, 4 s) that run apart at right angles to its heading, pulling and flinging as the parent did. Twins never split again.
- **Scatter Strike, Seeking Bursts.** Each burst moves to the nearest living person in the open within 1.5 of its random point. The spread stays wide, but it finds people.
- **Light of Solaris, Wandering Sun.** While it burns, the pillar drifts 0.8 units/s toward the thickest knot of people within 4. The closing burst, the sounds, the ground light and the haze all follow it.
- **Dragonfire, Second Breath.** Two seconds after the first breath, the dragon breathes again, sweeping the same arc back the other way. The slots stay locked through both.
- **Tsunami Breaker, Backwash.** After the wave breaks, the water draws back over the ground it soaked (the lane, 1.5 wider each side, and the splash ring beyond the wall) and carries whoever is still alive back to where it started, knocked down. Not lethal; buildings are not hit again.
- **Cinderfall, Lava Pool.** The volcano leaves a lava pool (radius 1.5) that burns 15 s, kills whoever walks in and sets the buildings within 3.0 alight every 3 s. The slots unlock at 12 s as today.
- **Wrath of the Sky, Called Bolts.** While the storm lasts, a click with the Wrath slot focused drops one sure, hard bolt exactly there, once every 3 s. It is not a cast: no cooldown starts and nothing else casts.
- **Earthshatter, Fault Lines.** The crack forks twice, at a third and two thirds of the run, one to each side (0.6 rad off the line, 5 units long). Both branches stay open and kill, shove and break as the main crack does.

## What follows the level, and what does not

- Follows: every table stat above, the cooldown (Rules, the HUD shade, the cards), the Might cost, the tree text, the aiming preview (`Targeting.area_at`), and **the town's danger radius** (R5a): a level-5 Cinderfall makes the town flee a 7.0 circle, the one the player sees.
- Level-free (R5): `PowerBook.REACH` and `IMPACT` (how long the town treats a cast as dangerous, when it first kills) and the Lantern mirror's blow cap (a literal 45.0).

## How to try it

- **Board:** the Prepare screen's level picker (1-5) per drafted power feeds `Game.levels` into the mission.
- **Scripted:** `tools/dev/behaviour_check.gd` takes `--level=1..5` and plays every drafted key at that level (a Hunt stays at level 1).
- **Tree:** the skill tree's detail line for a Ruin power shows the next level's changes, and the level-5 line shows the twist.

## Commits (`fb917db6..bb3b6588`, branch `god/ruin-levels`)

- `7c5a00d5` design, `fb917db6` plan.
- `d3455908` Task 1 groundwork (tables, per-level cooldown, every stat read at its level, previews, test files); `3692f675` its review fixes.
- Twists, one commit each: `60966840` Smite, `4f5593d4` Ember, `c6a624dc` Tornado, `6f2d4202` Scatter (track A, merged `3f659924`); `f46cd2c2` Solaris, `b00bac5b` Dragon, `f38e62bf` Tsunami (track B, merged `11aef49e`); `f5a0e1bc` Cinder, `be108c6c` Tempest, `1f451de8` Earthshatter (track C, merged `fa90cf99`).
- Fix wave after the final review: `e34c44aa` Backwash reach (R12a) and one shared stage Impact, `d00a8d09` the town's danger radius follows the level (R5a), `e98bfc48` Wandering Sun leaves nothing behind, `bb3b6588` minors (Lantern literal, recast guards, edge redraw, behavioural click test, sharper twist tests).

## Tests

- New: `tests/test_ruin_levels.gd` (423 checks: shapes, level one with types, the spec's tables typed again, Might, cooldown at level, level-3 casts, twist gate, previews, tree text), the shared `tests/fx_stage.gd` helper (with `StageImpact`), and ten `tests/test_ruin_twist_<key>.gd` (at their task: smite 12, ember 15, tornado 18, scatter 13, solaris 17, dragon 9, tsunami 12, cinder 13, tempest 26, shatter 18; the fix wave added cases). `tests/test_threats.gd` gained the danger-radius cases.
- Suite counts so far: tracks A 14578/0, B 14560/0, C 14579/0; merged suite 14661/0; after the fix wave 14688/0. Digest and crowd_check unchanged at every step.
- Landing: refs 508/0 (level 1 moved nothing; digest and crowd_check unchanged) / FLOW 209/0 alone / suite 14688/0

## Not done, on purpose

- Numbers are first guesses, to tune in play. No staged visual (lava pool, twins, receding flood, second cone, drifting pillar) has been looked at in a real window: the suites run headless.
- The open and playtest notes are at the end of the rulings note.
