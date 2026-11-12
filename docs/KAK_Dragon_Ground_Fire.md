# Kingdoms Amid Kataclysm (KAK) - Dragonfire Ground Fire Summary

*Engine: Godot 4.7.2. Branch `god/dragon-ground` (cut from `2178307b`, the Ruin levels landing). Dragonfire Parade now leaves burning ground: the strip its breath sweeps catches fire, the town runs from it, citizens beat it out, and it burns down on its own. Built 2026-11-03/04, subagent-driven: a groundwork task, three parallel-ish feature tasks, a references-and-gates task, an opus final review that said "fix first", one fix wave, and this note. Spec: `docs/superpowers/specs/2026-11-03-kak-dragon-ground-fire-design.md` (the design was approved by the user in chat on 2026-11-03). Plan: `docs/superpowers/plans/2026-11-03-kak-dragon-ground-fire.md`. The Ruin levels this builds on: `docs/KAK_God_Ruin_Levels_Summary.md`.*

## What the player sees

- **Patches.** Each breath lays about 8 **ground-fire patches** along the strip the beam sweeps, one after another as the beam passes, each at full strength (1.0). Every Dragonfire level lays ground; a longer breath lays more. Level 5's Second Breath lays a second strip of the same size, interleaved with the first. The old decorative flames are gone: the patches are their lasting form. A patch never grows, never moves and never spreads over other ground.
- **Look.** Two flames, rising embers, a thin smoke, a scorch mark on the ground and a flickering light pool, all shrinking as the patch burns down. They outlive the cast. When a patch is beaten out it ends in a grey smoke puff; either way the flames shrink over 0.6 s and the scorch mark fades over 6 s. One quiet `orb_embers` loop plays per strip and fades when the whole strip is out. There is no beating sound.
- **Harm.** Anyone who stands in a patch burns, and the harm builds with time inside. About 1.5 s inside kills; a quick dash across (about 0.9 s at the panic run) leaves the person **scorched** (darkened with soot for 8 s) and fleeing, but alive. A person knocked flat in a patch lies there 1.7 s and burns to death. A second dash soon after the first is more dangerous, because the heat leaves slowly (0.5 s a second). No random chance. Soldiers and Knights burn like citizens. Beaters burn too if they stray in.
- **The town's response.** A patch is a danger like a burning house: calm people who wander near run from it, every path bends round it, and the routine sends nobody onto it. When a patch goes out, its danger ends at once.
- **Buildings.** A patch touching a burnable building can set it alight, by the same chance a burning house uses to spread (0.08 a second at full strength).
- **Beaters.** Calm citizens nearby turn out as for a house fire (after any building fire, which comes first) and gather round the patch's edge, never stepping in. No water, no well: they beat the flames out. **3 beaters take about 5 s, 1 beater about 15 s**; 2 take about 7.5 s. While a patch is at full strength they wait a step further back, and start beating once it has burned down a little. Soldiers, rescue squads and engineers do not beat ground fires.
- **Burn-down.** Left alone a patch goes out in about **40 s**. Beaters replace the burning-down, they do not add to it.
- **Levels and Second Breath.** Patches per breath follow the breath time: L1 8, L2 9, L3 9, L4 10, L5 11, and at L5 Second Breath adds a second strip of 11 (22 in all). The patch's own numbers are the same at every level.

## The numbers

First guesses, to tune in play. `*` marks a call made where the spec was silent.

| Name | Value | Meaning |
|---|---|---|
| `GroundFire.RADIUS` | 0.7 | a patch's burning radius |
| `PATCH_RATE` | 8.0 / `BREATH_TIME` = 3.333 /s | patches per second of breath |
| patches per breath | `roundi(PATCH_RATE * lv_breath_time)` | 8 / 9 / 9 / 10 / 11 (+11 Second Breath) |
| `PATCH_NEAR` / `PATCH_FAR` | 2.0 / 9.5 * | how far along the beam a patch lies |
| `BURN_DOWN` | 0.025 /s | untended 1.0 to 0 in 40 s |
| `BEAT` | 0.06 /s per beater | a patch loses `maxf(BURN_DOWN, beaters * BEAT)` a second |
| `BEAT_FROM` | 0.9 * | "full strength" is above this; beaters wait until it falls to it (4 s untended) |
| `CREW` | 3 * (never above the profile's `fire_crew`) | beaters per patch |
| `BURN_KILL` | 1.5 s | seconds inside that kill |
| `HARM_TICK` | 0.1 s * | how often the fire looks for who is in it |
| `COOL` | 0.5 s a second * | how fast heat leaves a person once out |
| `SCORCH_SHOW` | 8.0 s * | how long a scorched person shows soot |
| `THREAT_PAD` | 0.3 * | the danger's radius is `RADIUS + 0.3` = 1.0 |
| `TOUCH` | 0.3 * | a building touches a patch within `RADIUS + TOUCH` of its centre |
| `SPREAD` | `FireManager.SPREAD` 0.08 | building-catch chance a second at full strength |
| `BEAT_GAP` / `WAIT_GAP` | 0.35 / 1.0 * | the beat ring and the wait ring: `RADIUS + gap` |
| `BEAT_SWING` | 0.6 s * | a beater swings this often |
| `RENEW` | `FireManager.RENEW` 3.0 s | how often a patch's danger is renewed |
| `RESPOT` | 0.25 s (fix wave) | a beater short of its spot re-picks at most this often |

Beat times from `BEAT_FROM`: 1 beater 0.9 / 0.06 = 15 s, 2 beaters 7.5 s, 3 beaters 5 s.

## How to try it

- **Sandbox:** cast Dragonfire. With no town the patch's sprite steps it: burn-down and harm only (no danger, no buildings, no beaters).
- **In a town:** `behaviour_check --scenario=lanterns --route=b --board` (Broken Lanterns route B casts Dragonfire in the town).
- **Scripted levels:** `behaviour_check --level=1..5` plays Dragonfire at that level.

## Where it lives

- `src/game/crowd/ground_fire.gd` (`GroundFire`, plain state and the rules that need no town: `burn_down`, the shared harm rule `scorch`).
- `src/game/crowd/fire_manager.gd`: keeps `patches` (a list, lay order, separate from `fires`, so every reader of `fires` is unchanged), burns them down, harms, renews dangers, catches buildings (own `_patch_rng`, seed + 1), recruits and tends beaters.
- `src/fx/set2/ground_fire_sprite.gd` (`GroundFireSprite`, group `fx_lasting`): the look, the light and the unowned (no-town) step.
- `src/fx/set2/dragonfire_parade.gd`: lays the strip(s). No random numbers: where a patch lies depends only on the arc and the clock, with a golden-ratio scatter along the beam.
- Small additions: `ThreatManager.end/refresh/first_near/has_kind`, `Person.panic(..., startle := true)`, `scorched_left`, `beat()`, `assist_slot`, `LightField.register_quad_at()`.

## Commits (`caee0214..795a8c54`, branch `god/dragon-ground`)

- `caee0214` spec and plan.
- `444b1486` Task 1: GroundFire patches in the FireManager (burn down, burn who stays, frighten and bend routes, catch buildings); `d14165ae` its review fixes (both dangers end, `clear_patches` ends dangers, harm debt clamped).
- `ca478dda` Task 3: the patch's look (parallel, merged `2607defd`).
- `b49e1d5b` Task 2: calm citizens beat it out.
- `ca1ac02c` Task 4: Dragonfire lays the strip (parallel, merged `d649c95c`).
- `b384b715` Task 5: 11 Dragon rows re-recorded.
- `253b0b8c` fix wave after the final review (src and tests); `795a8c54` its references (lanterns_b_play_1-3).

## References re-recorded

`digest` 61267b7e90524d800bf1c3473a71146b and `crowd_check` -935602679 did not move at any step, and no non-Dragon row moved: of the 508 rows, only Dragonfire-casting rows changed. `lanterns_none` (never casts) and `lanterns_toll_1` held. Reason for all: Dragonfire now lays ground (patches burn people, frighten and reroute the crowd, draw beaters) and its old decorative flames and their `ctx.rng` draws are gone (G11).

Re-recorded in `b384b715` (Task 5), old -> new:

| Row | File | Old | New (Task 5) | Outcome |
|---|---|---|---|---|
| lanterns_toll_2 | lantern_night2.tsv | -872747931 | -834111690 | won drained 121.8 |
| lanterns_toll_3 | lantern_night2.tsv | -371330133 | -64643372 | won drained 123.3 |
| lanterns_b_play_1 | routes_t2.tsv | -570485431 | 899943793 | won drained 198.8 |
| lanterns_b_play_2 | routes_t2.tsv | -632882101 | 781100896 | won drained 308.9 |
| lanterns_b_play_3 | routes_t2.tsv | 465629693 | 491577989 | won drained 252.9 |
| judgement_b_play_1 | routes_t5.tsv | 306700222 | -658480590 | lost escapes 67.6 (was lost 63.2) |
| judgement_b_play_2 | routes_t5.tsv | -721575751 | -668506297 | lost escapes 61.9 (was lost 61.8) |
| judgement_b_play_3 | routes_t5.tsv | -594002650 | -527069333 | lost escapes 66.9 (was lost 64.8) |
| night_b_play_1 | routes_t5.tsv | 207366634 | 929766781 | lost timeout 333.5 (same) |
| night_b_play_2 | routes_t5.tsv | -913637529 | 693964412 | lost gaze 348.9 (was lost timeout 355.2) |
| night_b_play_3 | routes_t5.tsv | 718260393 | 966721283 | lost timeout 331.6 (same) |

Moved a second time in `795a8c54` (fix wave), reason: dangers renewed in place changes the order of the active dangers, and the beater fixes (dead beaters, engineers, stale references) change who beats:

| Row | Before the fix wave | Final | Outcome |
|---|---|---|---|
| lanterns_b_play_1 | 899943793 | 621577431 | won drained 198.8 (was 198.8) |
| lanterns_b_play_2 | 781100896 | 143923128 | won drained 308.0 (was 308.9) |
| lanterns_b_play_3 | 491577989 | 529666047 | won drained 198.3 (was 252.9) |

All other rows held through the fix wave (25 rows checked: digest, crowd_check, calm, fire, flame_*, lanterns_*, judgement_b_play_*, night_b_play_*; 22 OK, 3 moved). Each file's header comment names the re-record.

## Gates

| Gate | Result | Baseline `2178307b` |
|---|---|---|
| `gate.sh lanterns --case=toll` | PASS, wins 3/3, median 122, idle max 43 | - |
| `gate.sh lanterns --route=b --board` | PASS, wins 3/3, median 199, idle max 43 (clean gate-script line, from the fix wave; Task 5's own gate run was cut by the 600 s wall-clock timeout under load, its direct runs won 3/3) | - |
| `gate.sh lanterns` (route a) | FAIL, median 142 (under 180), wins 3/3 | same: median 142 FAIL |
| `gate.sh judgement --route=b --board` | FAIL, wins 0/3 (escapes) | same: 0/3 |
| `gate.sh night --route=b --board` | FAIL, wins 0/3 (timeout, gaze, timeout) | same: 0/3 |

Lanterns a, judgement b and night b sit at their known baseline states, identical to `2178307b`, so the ground fire changes no pass/fail. Judgement b and night b have lost 0/3 since v0.11.1 (the known, reported-not-binding state in `docs/KAK_Version_0.11_Summary.md` and `docs/KAK_v011_Rulings.md` C5). Lanterns a's median is under the 180 s floor at baseline too (seed 1 got 21 s faster with the patches, since Dragonfire is the route's back-up cast).

## Bench, before and after the fix wave

A real level-5 Dragonfire cast through the Battlefield (22 patches, sprites and lights live), rendered, `--fixed-fps 60 --disable-vsync`, seed 7, 30 s (1800 frames) after 4 s of calm; machine shared with another session's Godot runs, so read the means. Milliseconds per frame, mean / p99 / worst:

| bucket | before the fix wave | after | cast, no ground | no cast |
|---|---|---|---|---|
| frame total | 29.1-29.3 / 47.5 / 121-150 | 26.3-26.4 / 44.8-45.6 / 121-129 | 18.2-18.6 / 38.5-39.6 / 113-127 | 14.0-14.5 / 19.9-21.5 / 23-25 |
| sim (people + crowd) | 6.26-6.31 / 21.4-21.7 / 30-35 | 5.24-5.30 / 19.5-20.8 / 35 | 5.20-5.33 / 21.3-22.7 / 35-44 | 3.75-3.87 / 6.4-6.9 / 8 |
| fires | 0.48 / 4.1 / 7.8-8.2 | 0.16 / 2.0-2.2 / 4.3-4.8 | 0.02 / 0.1 | 0.01 |
| harm scan | 0.30 / 3.4 / 4.0-4.2 | 0.05 / 0.55 / 1.1-1.4 | - | - |
| beaters | 0.12 / 1.5-1.6 / 2.3-2.8 | 0.07 / 0.35 / 0.5 | - | - |
| evac | 0.57 / 5.7 / 8.1 | 0.37 / 5.0 / 7.4-8.2 | 0.41 / 5.8-6.1 / 8.7-9.0 | 0.02 |
| flame draw | 4.11 / 8.45 / 10.0 | 3.22 / 8.17 / 13.8 | 0 | 0 |
| render CPU | 8.95 / 13.8 / 16.0 | 9.0 / 13.8-13.9 / 16.0-16.3 | 7.0 / 11.5 | 6.2-6.4 / 9.5-10.2 |

- The ground fire's own simulation cost is now level with a cast that leaves no ground (sim 5.24-5.30 vs 5.20-5.33).
- Danger-epoch bumps over the 30 s: 453 -> 127 (no-ground cast: 164). Script errors a run: 92 -> 0 (a freed-beater loop in the beaters' round had been aborting that frame's round).
- The task-5 bench (crowd only, 22 patches laid directly, no sprites) before the fix wave: frame mean 3.4 -> 4.4-5.0 ms, p99 7.6 -> 13.1, worst frame 10 -> 22-35 ms.
- What is left (Rf3's "p99 and worst within about 2 ms of no cast" is NOT met): see the open items.

## Rulings

Binding from the plan (G1-G12):

- **G1** One list, not one dict: patches are `FireManager.patches`, not keys of `fires`, so every `fires` reader is unchanged.
- **G2** The rate rule: `strength -= dt * maxf(BURN_DOWN, beaters * BEAT)`; the only linear rule giving 40 s / 15 s / 5 s.
- **G3** Full strength is `strength > BEAT_FROM` (0.9); beaters wait on the wait ring until it is not.
- **G4** Harm is per person, not per patch: in two overlapping patches a person heats once a tick.
- **G5** No startle in fire: `Person.panic(from, radius, kind, startle := true)`; the patch passes `false`.
- **G6** The threat ends with the patch: `ThreatManager.end(id)`, the same move to the recent impacts that expiry makes.
- **G7** Spread is today's building roll on its own `_patch_rng` (seed + 1) against the first touching, standing, unburnt burnable, lit at `START`.
- **G8** Beaters are citizens, recruited after building fires; rescue squads and engineers ignore patches; Magnify ignores patches.
- **G9** No goal inside a patch (beat ring `radius + 0.35`, wait ring `radius + 1.0`, the spot test).
- **G10** No-town patches (sandbox, staged tests) burn down and harm, stepped by their sprite; no danger, no buildings, no beaters.
- **G11** Laying draws no `ctx.rng`; the old `_fire_patch()` flames go (part of why the Dragon rows move).
- **G12** A sprite outlives its cast; `FireManager.clear()` puts every patch out; `Battlefield.clear_effects()` clears patches too; `end_powers()` between a night's acts leaves them, like building fires.

Controller rulings (workspace `rulings.md` and `progress.md`):

- **C1-C3** Process: Tasks 3 and 4 worked in their own worktrees (`god/dg-3`, `god/dg-4`) from `444b1486`, with the suite run at 3 jobs because other sessions ran Godot; Task 4 did not re-record Dragon rows (Task 5 does); Task 2 covers soot only if its crew tests touch scorched people (they did not; the sprite suite owns it).
- **C4** (Task 5) Fix the scripted judgement b and night b policy first if they lose with the patches; do not tune the patch numbers or the opposition. Max three rounds per gate. Premise found wrong: both routes lost 0/3 before the feature, so no rounds were spent.
- **No separate pre-flight** by an opus agent: the planner's file table answers it (cost if wrong: Task 1's review catches it).
- **No haiku re-review of the Task 1 fix round**: each finding got its own test and the suite was green (cost if wrong: the milestone review finds it).
- **Accept the gate states**: each equals its baseline on `2178307b`, so the ground fire changes no pass/fail (cost if wrong: a route that was close got worse unseen; judgement/night stay a known open item).
- No separate review of Task 2: the milestone review covers it.

Task rulings (each from its report):

- **Task 1.** `GroundFire.END_BELOW := 1e-9`: a patch is out at `strength <= 1e-9`, not `<= 0.0` (160 subtractions of 0.25 s leave a 1e-16 residue). The harm timer keeps its 0.1 s cadence with `_harm_in += HARM_TICK` every frame and scorches only with patches or heat. `_inert_when_empty` uses a veiled off-map patch on one crowd; equality of an empty manager with the old code is proven by the references. Procedural (non-atlas) bodies show no soot; only the people-atlas path does. Fix round: both threat ids end when a patch goes out (I-1), `clear_patches` ends dangers (M-1), the harm debt is clamped (M-2), `Battlefield.clear_effects()` is tested (M-3).
- **Task 2.** `Person.assist_slot` (R1): a crew member's ring slot, so a replacement takes the freed slot. "At the wait spot" means within `GOAL_REACH` of the last `walk_to` anchor (R2), so a beater stopped short is not re-walked (and does not draw `Crowd._rng`) every frame. A beater dropped because its mind changed (fright) has its stale `assist_patch` and `assist_beating` cleared (R3). A beater whose spot finds no good place after arriving is stood down; a recruit with no spot is skipped (R4).
- **Task 3.** The scorch fade starts after the flames are out (0.6 s + 6.0 s to freeing). Smoke seed is `id * 7919 + 14` (embers `+ 13`, puff `+ 15`): three distinct streams, none from `ctx.rng`. Particles are children of the sprite, so nothing to clean up in `clear_effects()`. `_exit_tree()` lets the strip's voice go, because a beaten first patch's sprite can free long before the rest of its strip is out.
- **Task 4.** The river skip runs only with `ctx.crowd`, so staged tests at the origin never depend on Aldermere's rivers. A skipped patch (outside bounds or in a river) still consumes its index; the strip's voice goes with the first patch actually laid.
- **Task 5.** All five gate states accepted as above; no route script was changed. Six `expel_inquisitor_*` rows and two lanterns-b runs were killed by refs_check's own 600 s timeout under load and reproduce when rerun alone (not moves).
- **Fix wave (Rf1-Rf3).** Rf1: the fixes may change only Dragonfire-casting rows; digest, crowd_check and every other row must hold; P2-P4 and P6 must be byte-identical (checked on a build with P1 and B1-B3 gated back: 15/15 OK); P1 may reorder active dangers. Rf2: if Dragon rows move, re-run the lanterns toll and lanterns b gates; each must still win 3/3 within its bar (done). Rf3: re-run the bench; the target was not met (see open items).
- **Fix wave edges.** A renewal that fails because the place became veiled leaves the old id to expire (at most 0.5 s) and it is not ended at out. The building brigade's missing `is_alive` and engineer filters predate this feature and were left alone (only the beater pool got B1/B3).
- **Review, by design.** Fleeing (FLEE) evacuees keep their course through a patch, because `panic()` returns early (the spec says panic's own rules apply). A beater's walk can still cross a neighbouring patch of the same strip (the danger weight is 6x, not a block); it panics and leaves the crew, which is acceptable under G9.
- **Coupling, deterministic.** `_patch_spot` uses `Crowd._spot_near`, which draws `Crowd._rng`; a beater re-spot therefore shifts later `Crowd._rng` users, but only when patches exist.

## Tests

- New: `tests/test_ground_fire.gd` (41 checks: rates, harm, dash, danger renewal, catching, clearing, first_near, renewal quiet), `tests/test_ground_fire_crew.gd` (41), `tests/test_ground_fire_sprite.gd` (26), `tests/test_dragon_ground.gd` (16). All four are registered in `tests/run_all.gd`. With the old behaviour switched back on, 8 of the fix wave's new or changed checks fail (teeth confirmed).
- Suite counts: after Task 1 14730/0; after Task 4 14802/0 (run as parts); after Task 5 14800/0 (one shared-directory race in `test_hunt_tools`, green alone); after the fix wave 14814/0.
- Landing: refs 508/0 (only Dragonfire rows re-recorded) / FLOW 209/0 alone / suite 14814/0

## Open items

- **Flame draw cost: a visual choice for the user.** 22 patches x 2 FlameSprites x 3-5 tongues x 4 layers is about 700 GDScript-built polygons a frame for about 45 s: about 3.2 ms a frame plus about 2 ms of renderer CPU. The identical-output rewrite saved 0.9 ms; going further changes the look. Options: one FlameSprite per patch, a 30 Hz flame redraw, fewer layers, or the cheaper shader flame. Until then Rf3 (p99 and worst frame within about 2 ms of no cast) is not met.
- **The soldiers' rally re-path storm (predates this feature).** Every 40 frames 18-37 soldiers in RALLY re-path to a Citadel rally slot they cannot reach; each `set_goal` is a full failed A* search of about 1 ms, giving `paths` a p99 of about 15 ms and a worst of 80-120 ms. It is the same with no ground and with a Heaven Splitter cast. Fixing it moves non-Dragon rows, so it needs its own task.
- **Hand playtest.** No staged visual (patches, scorched soot, beaters round a patch, the light pools) has been looked at in a real window; suites and reference runs are headless. The numbers are first guesses: radius 0.7, 1.5 s kill, 40 s burn-down, 3-beater crew, the sizes of flames and light.
- **Judgement b and night b** stay 0/3 and **lanterns a** keeps its median of 142 (all baseline, v0.11 C5): a policy problem for the scripted routes, not this feature.
- **The bench script** lives only in the scratchpad (`dragon_bench.gd`); a `--bench-dragon` hook on the mission would make it repeatable.
- **Final re-review** of the fix wave: clean. Parked minors: a renewal at a veiled place orphans the old danger (lingers up to 0.5 s); the sprite cull and several fix-wave helpers have no test.

## Out of scope (ideas for later)

Water powers or rain putting patches out; Magnify raising a patch; patches spreading over ground; the Lava Pool (Cinderfall) as a `GroundFire` (its rule differs on purpose: lava kills on contact and cannot be beaten out); a beating sound; rescue squads and engineers beating ground fires.
