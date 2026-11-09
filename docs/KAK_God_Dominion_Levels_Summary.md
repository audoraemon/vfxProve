# Kingdoms Amid Kataclysm (KAK) - Dominion Ability Levels Summary

*Engine: Godot 4.7.2. Branch `god/dominion-levels` (cut from `feat/god-progression` `654f1b54`), landing on `feat/god-progression`. Each of Dominion's ten powers now has five levels and a level-5 twist. Built 2026-11-09, subagent-driven: a groundwork task, ten twist tasks in three parallel tracks, an opus final review that said "with fixes", one fix wave, and this note. Spec: `docs/superpowers/specs/2026-11-09-kak-dominion-ability-levels-design.md` (approved: "Ok let's do it"). Plan: `docs/superpowers/plans/2026-11-09-kak-dominion-ability-levels.md`. Every ruling is in `docs/KAK_God_Dominion_Levels_Rulings.md`. The levels framework is `docs/KAK_God_P1_Summary.md`; Ruin did the same in `docs/KAK_God_Ruin_Levels_Summary.md`.*

The user's brief for the god: "puppet master that pulling string and dominate people to be direction of the god's will." So every level holds more people, for longer, and recasts sooner. Every twist is a new way to steer people the god already holds. No twist is a random roll.

## What levels do

- Each power has **five levels**. Each level raises two or three of its numbers by roughly 5-15% (the tables below), and one of them is the cooldown.
- **Level 5 adds a twist**: a new way to steer, not a bigger number. A level-4 cast never shows it.
- **Level 1 is today, exactly.** Hunts, routes and the reference set play at level 1, so nothing moved. `digest` `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679` were unchanged at every task and after the fix wave; no reference row was re-recorded.
- **Might** is not in the tables: it is the existing rule (base cost at levels 1-2, +1 at levels 3-4, +2 at level 5), and a test proves it equals the spec's column. A Tier 5 pair at level 5 is Voice 7 + Schism 8 = 15, under the cap of 16.
- The skill tree prints what the next level changes in plain words, and level 5 prints the twist line. The Prepare card shows the twist line (gold) for a level-5 draft.
- Divine Schism stays once a night (no cooldown column). Will-o'-Wisp's ENTHRALL keeps its own 75 s cooldown at every level.

## The ten tables

Level 1 / 2 / 3 / 4 / 5. Names are the effect's own constants, with the tree's short word in brackets (D6).

| Tier | Power | Stat (word) | Values | Cooldown (s) |
|---|---|---|---|---|
| 1 | Mind Whisper | `REACH` (walk reach) | 10 / 11 / 12 / 13 / 14 | 8 / 7.5 / 7 / 6.5 / 6 |
| | | `ATTACK_SECS` (attack) | 10 / 11 / 12 / 13 / 14 | |
| 1 | Discord (quiet) | `DISCORD_R` (circle) | 1.2 / 1.3 / 1.4 / 1.5 / 1.6 | 30 / 28 / 26 / 24 / 22 |
| | | `DISCORD_TIME` (forgetting) | 15 / 16 / 17 / 18 / 20 | |
| 2 | Madness Bloom (quiet) | `RADIUS` (radius) | 1.5 / 1.65 / 1.8 / 1.95 / 2.1 | 40 / 38 / 36 / 34 / 32 |
| | | `SEED` (starting madness) | 0.02 / 0.04 / 0.06 / 0.08 / 0.10 | |
| 2 | Will-o'-Wisp (quiet) | `LURE_MAX` (lure cap) | 25 / 27 / 30 / 32 / 35 | 30 / 28 / 26 / 25 / 24 |
| | | `WISP_TIME` (lure time) | 12 / 13 / 14 / 15 / 16 | ENTHRALL: 75 at every level |
| | | `ENTHRALL_TIME` (enthrall) | 30 / 32 / 34 / 37 / 40 | |
| 3 | Clear Mind (quiet) | `RADIUS` (radius) | 5.0 / 5.4 / 5.8 / 6.2 / 6.5 | 60 / 57 / 54 / 51 / 48 |
| | | `TRANCE_TIME` (trance) | 30 / 32 / 34 / 37 / 40 | |
| 3 | Saint or Sinner (quiet) | `RADIUS` (radius) | 6.0 / 6.4 / 6.8 / 7.2 / 7.5 | 60 / 57 / 54 / 51 / 48 |
| | | `SPAN` (span) | 30 / 32 / 34 / 37 / 40 | |
| 4 | Sacred Sanctuary (quiet) | `MAX_GUARDS` (guards) | 40 / 44 / 48 / 52 / 55 | 90 / 86 / 82 / 78 / 74 |
| | | `SPAN` (span) | 40 / 44 / 48 / 52 / 55 | |
| | | `PICK_R` (guard reach) | 5.0 / 5.25 / 5.5 / 5.75 / 6.0 | |
| 4 | Anathema (quiet) | `RADIUS` (district) | 6.0 / 6.4 / 6.8 / 7.2 / 7.5 | 90 / 86 / 82 / 78 / 74 |
| | | `SPAN` (span) | 40 / 44 / 48 / 52 / 55 | |
| 5 | Voice of God | `COMMAND_X` (command length, times each command's seconds) | 1.0 / 1.1 / 1.2 / 1.3 / 1.4 | 180 / 170 / 160 / 150 / 140 |
| | | `GATHER_CAPACITY` (gather cap) | 150 / 160 / 175 / 185 / 200 | |
| 5 | Divine Schism | `REGION` (region) | 14 / 15 / 16 / 17 / 18 | once a night |
| | | `MAX_FIGHTERS` (fighters) | 140 / 150 / 160 / 170 / 180 | |
| | | `DURATION` (length) | 25 / 27 / 29 / 32 / 35 | |

`COMMAND_X` is new (D3): a constant of 1.0 that multiplies each command's seconds. Level 1 is `x * 1.0`, which is exact. Whisper's walk reach is read where the walk is clamped (the targeting release and the aim line), because the effect never clamps itself (D4).

## The ten twists (level 5 only)

Four of them take a follow-up order and are marked **(click again)**. See the next section.

- **Mind Whisper, Held String.** A level-5 whisper (walk, attack or burn) leaves no shake-off when it wears off, so that person can be whispered again at once. It is an ordinary new whisper: the cooldown still applies.
- **Discord, Tangled Threads.** For 5 s after the cast, anyone alive and in the open within 1.0 of a person this Discord confused, who is still confused, is confused too for the full forgetting time. One hop: the caught pass nothing on. Soldiers too.
- **Madness Bloom, Directed Frenzy.** Everyone the cast seeded who reaches Broken goes into frenzy (never the stun, the erratic or the panic outcome) and goes for the nearest soldier in sight, else as today. People the madness spreads to are not directed.
- **Will-o'-Wisp, Procession (click again).** While the light burns, in either mode, click a new spot. The light drifts there at walking pace and everyone it holds walks with it, keeping their place in the ring. Free: no Might, no cooldown.
- **Clear Mind, Sleepwalk (click again).** While the trance holds, click a spot. Everyone entranced walks there calmly, each to a spot of its own, still sensing nothing, and stands until the trance ends. Free. This replaced the first design, "Forgetting" (the user's pick, D12).
- **Saint or Sinner, Passed Mark.** SINNER: when the chosen falls, the mark jumps once to the nearest living bystander within 3 (not one of the mob), and the whole mob goes after them for the rest of the span. SAINT: whoever strikes the Saint draws every idle guard, not only three.
- **Sacred Sanctuary, Pressed into Service.** An intruder the wall drives out does not run: it takes a post on the wall and guards for the rest of the span. Soldiers too, up to the level's guard cap.
- **Anathema, Spreading Mark.** 20 s in, the mark (cursed or hallowed) spreads once to every standing building of a marked role within 3 of a marked one, for the rest of the span. Never the Citadel. Hallowed also sends nearby citizens in.
- **Voice of God, Second Word (click again).** While the first command holds, click to speak a second one (the Q/E mode shown; any of the seven). The same people take it up when the first ends. Free, once per cast. Judge needs someone at the click.
- **Divine Schism, Turn the Tide (click again).** While the sides fight, click a fighter to move it to the other side, up to ten times a cast. Free. Nothing happens in TUMULT, which has no sides.

## The follow-up input (one way, not four)

Ruin's Called Bolts already took an order from a live cast. This milestone made that the one mechanism, so Procession, Sleepwalk, Second Word and Turn the Tide use the same input as Tempest.

- **To give the order:** select the power's slot again (its number key or its card; allowed while it cools), then click the ground. While the live cast can take an order, the slot aims as a plain click, whatever its own aim (Schism's two clicks, Voice's Q/E mode).
- **What it costs:** nothing. A follow-up starts no cooldown, sends no `cast_made` (so no alarm and no `Crowd.on_cast`), and the slot stays selected.
- **When it is refused:** while any other cast holds the busy lock, and after the run is over. A click that finds nothing (Tide misses every fighter, Judge with nobody there) is refused as "nobody", and never falls through to a real cast.
- **How the player knows:** the HUD slot card turns gold (gold frame, gold cooldown seconds) while an order can be given; the aim preview's edge is gold and shows the follow-up's own area when it has one; the twist text says "click again" in the tree and on the Prepare card.
- **In code:** `Rules.recast`, `Rules.can_recast` and `Rules.follow_up_area` call the live effect's `follow_up(at, extra)`, `can_follow_up()` and `follow_up_area()`. Tempest keeps `call_bolt` and `can_call` behind thin wrappers, so its tests are unchanged.
- **Held String is not a follow-up.** Its cooldown still applies, so it is a normal new whisper (select the slot, click) through `Rules.cast`.

## What follows the level, and what does not

- Follows: every table stat, the cooldown (Rules, the HUD shade, the cards), the Might cost, the tree text, the aiming preview (`Targeting.AREA_STATS` now covers discord, madness, clear mind, anathema and sanctuary, and the "who would be taken" ringing uses the level's numbers), and Whisper's walk reach.
- Level-free: the directors and routes (they read the constants and play level 1), Saint's `PICK_R`, Wisp's ring and lure reach, and the Voice and Schism preview shapes.

## How to try them

- **Board:** the Prepare screen's level picker (1-5) per drafted power feeds `Game.levels` into the mission.
- **Scripted:** `tools/dev/behaviour_check.gd --level=1..5` plays every drafted key at that level (a Hunt stays at level 1).
- **Tree:** the detail line for a Dominion power shows the next level's changes, and the level-5 line shows the twist.
- **The four follow-ups need the real input:** cast, wait out the busy lock (Wisp 1.0 s, Clear Mind 0.9 s, Voice 2.6 s, Schism 2.8 s), select the slot again, and click. The card should turn gold.

## Commits (`463d4885..375f4888`, branch `god/dominion-levels`)

- `acaac609` design (spec `668bf981`), `463d4885` plan (Forgetting changed to Sleepwalk).
- `1d57a0b7` Task 1 groundwork: tables, per-level cooldown, every stat read at its level, the shared follow-up mechanism, previews, HUD gold cue, test files.
- Twists, one commit each: `e07ed947` Whisper, `d4e9f407` Discord, `92953fba` Madness (track A); `5e1b59db` Wisp, `dd2f8f5d` Clear Mind, `4610bfaa` Voice, `06f707ae` Schism (track B); `cb6d82fc` Saint, `dedcdcf7` Sanctuary, `4704019d` Anathema (track C).
- Track fixes: `587c3a59` (Passed Mark's once test can fail; Spreading Mark skips people indoors), `8fbb3dd0` (Procession leaves a person another power has since compelled; redirect skips sleepers; Sleepwalk checks ownership).
- Fix wave after the final review: `375f4888` (recast clears a half-placed two-click aim; a failed follow-up is refused as nobody; Sinner pass needs hunters; Procession re-path staggered; second-word RETURN uses the cached home).

## Tests

- New: `tests/test_dominion_levels.gd` (442 checks: shapes, level one with types, DS's tables typed again, Might, cooldown at level, level-3 casts, previews, tree text), `tests/test_follow_up.gd` (19 at Task 1, plus the stranded-aim and "nobody" cases), and ten `tests/test_dominion_twist_<key>.gd` for whisper, discord, madness, wisp, clearmind, saint, sanctuary, anathema, voice and schism (about 10, 12, 7, 31, 15, 8+, 19, 10, 24 and 20 checks; the fix rounds added cases). Each twist has a level-4 case that shows nothing.
- Digest and crowd_check unchanged at every step. Each track's own suite part 3 printed no result under load; the suites in it were rerun in slices or one by one, all `failures=0`.
- **Landing checks not yet run on the merged tree:** the full suite in 6 parts, all 508 reference rows (only `bread_play_3`, `-133947279`, may differ), FLOW alone (`209/0`), and one level-5 ENTHRALL Procession with a full ring profiled for frame cost.

## Not done, on purpose

- Numbers are first guesses, to tune in play. No twist has been looked at in a real window: the suites run headless.
- Level-4 `rng.state` literals asked for by the plan are mostly absent (see the rulings note).
- The open and playtest notes are at the end of `docs/KAK_God_Dominion_Levels_Rulings.md`.
