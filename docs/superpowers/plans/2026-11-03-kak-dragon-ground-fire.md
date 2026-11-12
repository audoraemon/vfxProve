# KAK Dragonfire Ground Fire Implementation Plan

Spec: `docs/superpowers/specs/2026-11-03-kak-dragon-ground-fire-design.md` (design approved by the user 2026-11-03; cited
**GS**). Background: `docs/KAK_God_Ruin_Levels_Rulings.md` (R11 Second Breath, R13 Lava Pool) and
`docs/superpowers/plans/2026-11-03-kak-ruin-ability-levels.md` (its house rules).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. Run it the KAK way:
> `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers; a sonnet task review for Tasks 1, 2 and 5).

**Goal:** Dragonfire Parade (`dragon`, `src/fx/set2/dragonfire_parade.gd`) leaves burning ground at every level: about 8
ground-fire patches per breath along the beam's path, which the town fears and routes round like a burning house, which
burn whoever stays in them (1.5 s kills, a dash scorches), may catch a touching building, burn down in 40 s, and which calm
citizens gather round and beat out (3 beaters 5 s, 1 beater 15 s). Level 1 changes on purpose: the Dragonfire rows are
re-recorded and the Dragonfire gates re-run; nothing else moves.

**Architecture:** fires today are `FireManager.fires` keyed by `Structure`; many readers (`rescue_manager`,
`engineer_manager`, nine mission directors, routes, `behaviour_check`) iterate it as `Structure`s. So patches are a
**separate list** on the same manager (`FireManager.patches: Array[GroundFire]`), stepped inside `FireManager.step()` after
the building fires, with their own rng stream. With no patch laid, every existing call, draw and order is unchanged. The
patch's look is a lasting node (`GroundFireSprite`, group `fx_lasting`, the `SolarisPit` / `Fissure` pattern) that outlives
the cast and, with no town, steps its patch itself.
1. **Task 1 (groundwork):** `GroundFire`, `FireManager.lay()` and the patch step (burn-down, harm, danger, catching),
   `ThreatManager.end()`, `Person` scorch bits, `Battlefield.clear_effects()`; every new test file registered once.
2. **Task 2:** beaters (`Person.beat()`, the ring, the round, the rate).
3. **Task 3:** `GroundFireSprite` (visual, sound handoff, the no-town step).
4. **Task 4:** Dragonfire lays the patches (levels, Second Breath).
5. **Task 5:** references re-recorded, gates re-run.
6. **Task 6:** docs.

**Tech stack:** Godot 4.7.2 GDScript; suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references
`tools/dev/refs_check.sh`; gates `tools/dev/gate.sh`.

---

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r`, branch `god/dragon-ground`. Every command from its root. Never cd
  elsewhere; never touch another worktree. Foreground commands only, each under 10 minutes.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- One suite: `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N`
- Full suite: `bash tools/dev/run_suite_parallel.sh 4` -> `failures=0` before every commit.
- After a new `class_name` or a new test file: `timeout 900 $G --headless --editor --path . --import`.
- New test files are added to `tests/run_all.gd` (`SUITES`, next to `test_fire.gd`). **Only Task 1 edits
  `tests/run_all.gd`**: it registers `test_ground_fire.gd`, `test_ground_fire_crew.gd`, `test_ground_fire_sprite.gd`,
  `test_dragon_ground.gd` (the last three as stubs: `static func run(t) -> void` with one passing `t.check(true, "<name>:
  pending (Task N)")`).
- **The exact references.** `R='^(digest|crowd_check|lanterns_|judgement_b_play_|night_b_play_)'`.
  - Tasks 1-3 lay no patch anywhere, so **no row may move**: `bash tools/dev/refs_check.sh --only="$R"` all OK (this proves
    the groundwork is inert on the very runs that will cast Dragonfire later).
  - Task 4: `bash tools/dev/refs_check.sh --only='^(digest|crowd_check)$'` OK (the Dragon rows are expected to move; Task 5
    re-records them).
  - Task 5: the whole set (below).
  - `digest` `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679` never move. Neither runs Dragonfire.
- **Inert when empty** (every task): with `patches` empty, `FireManager.step()` makes the same calls in the same order and
  draws the same `_rng` numbers as today; `_recruit()`'s building part is untouched (its early `fires.is_empty()` return
  becomes "no building fires: skip to the patches"); `Person.panic()` with its default `startle = true` behaves as today.
- **Determinism:** no `randf()`, no `Time`, no wall clock. Patch spread draws `FireManager._patch_rng` only (seeded
  `seed_value + 1` in `setup()`, never `_rng`); laying draws nothing; sprites' particles are seeded from the patch `id`.
  Order: patches in lay order, people in field order (`EnemyField.in_radius`), recruits by distance then `Crowd.citizens`
  index, heat entries in insertion order.
- Consts from GS §2 are named as there and live on `GroundFire` (the shared ones) or the effect (`PATCH_RATE`,
  `PATCH_NEAR`, `PATCH_FAR`, `GOLDEN := 0.618034`); `SPREAD`, `START`, `RENEW`, `WIND_GROW`, `RECRUIT_REACH` are
  `FireManager`'s own, reused.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Every `Ruling:` goes in the task's report.
- No PixelLab, no new sound files. Visuals reuse `FxParts` shaders/ramps and set2's `FlameSprite`.
- **Design numbers are the user's** (GS §2, *guess*). A gate that fails is fixed in the route script (Task 5) or reported
  -- never by changing a GS number without the user.

## Spec gaps and rulings (binding; G1-G12)

- **G1 One list, not one dict.** Patches are `FireManager.patches`, not keys of `fires`: every `for s: Structure in
  fires.keys()` reader stays right. Nothing outside `FireManager`, `GroundFireSprite` and Dragonfire reads patches.
- **G2 The rate rule.** `strength -= dt * maxf(BURN_DOWN, beaters * BEAT)`; the only linear rule giving 40 s / 15 s / 5 s (GS §2).
- **G3 Full strength** = `strength > BEAT_FROM` (0.9); beaters wait on the wait ring until it is not.
- **G4 Harm is per person, not per patch:** in two overlapping patches a person heats once a tick.
- **G5 No startle in fire:** `Person.panic(from, radius, kind, startle := true)`; the patch passes `false`. Only that branch
  (`if from_other_mind and startle:`) changes.
- **G6 The threat ends with the patch:** `ThreatManager.end(id)` -- the same move to `_recent` (and `epoch += 1`) that
  `step()` does at expiry; unknown id: nothing.
- **G7 Spread** is today's building roll on `_patch_rng` against the first touching, standing, not burning burnable
  (`env.near(at, radius + TOUCH)` order, `s.distance_to(at) <= radius + TOUCH`), lit at `START`.
- **G8 Beaters are citizens** recruited after building fires; rescue squads and engineers ignore patches; Magnify ignores
  patches.
- **G9 No goal inside a patch** (beat ring `radius + 0.35`, wait ring `radius + 1.0`, the spot test of GS §8).
- **G10 No-town patches** (sandbox, staged tests) burn down at `BURN_DOWN` and harm, stepped by their sprite; no danger,
  no buildings, no beaters.
- **G11 Laying draws no `ctx.rng`;** the old `_fire_patch()` flames go (their `ctx.rng` draws go with them -- this is part
  of why the Dragon rows move).
- **G12 Lasting and clearing:** a sprite outlives its cast (not `track()`ed); `FireManager.clear()` puts every patch out;
  `Battlefield.clear_effects()` also calls `ctx.crowd.fires.clear_patches()` when there is a crowd. Between a night's acts
  (`end_powers()`) patches stay, like building fires.

---

## Task order and parallelism

| # | Task | Files (edit) | Depends on | Independent of |
|---|---|---|---|---|
| 1 | Groundwork: GroundFire, patch step, danger, harm, scorch, catching | `src/game/crowd/ground_fire.gd` (new), `src/game/crowd/fire_manager.gd`, `src/game/crowd/threat_manager.gd`, `src/game/crowd/person.gd` (panic, scorch only), `src/game/battlefield.gd`, `tests/test_ground_fire.gd` (new), three stubs (new), `tests/run_all.gd` | -- | -- (serial, first) |
| 2 | Beaters: gather and beat | `src/game/crowd/fire_manager.gd`, `src/game/crowd/person.gd`, `tests/test_ground_fire_crew.gd` | 1 | 3 |
| 3 | GroundFireSprite: look, sound, no-town step | `src/fx/set2/ground_fire_sprite.gd` (new), `tests/test_ground_fire_sprite.gd` | 1 | 2 |
| 4 | Dragonfire lays the ground | `src/fx/set2/dragonfire_parade.gd`, `tests/test_dragon_ground.gd`; `tests/test_ruin_twist_dragon.gd` / `tests/test_ruin_levels.gd` only if a check there reads the old flames | 1, 3 | 2 |
| 5 | References re-recorded, gates re-run | `tools/dev/refs/routes_t2.tsv`, `tools/dev/refs/routes_t5.tsv`, `tools/dev/refs/lantern_night2.tsv`; only on a failing gate `tools/dev/routes/tier2_b.gd`, `tools/dev/routes/tier5_b.gd`, `tools/dev/behaviour_check.gd` (lanterns only) | 2, 4 | -- |
| 6 | Docs | `docs/KAK_Dragon_Ground_Fire.md` (new) | 5 | -- |

Tasks 2 and 3 share no file and may run in parallel worktrees cut from Task 1's commit (`run_suite_parallel.sh 3` each in
a parallel group). Task 4 may start once 3 is in (it can run beside 2). A task that finds it needs a file outside its row
stops and reports NEEDS_CONTEXT.

---

### Task 1: Groundwork (sonnet review)

**`GroundFire` (`src/game/crowd/ground_fire.gd`, `class_name GroundFire extends RefCounted`)**
- [ ] Consts (GS §2): `RADIUS 0.7`, `BURN_DOWN 0.025`, `BEAT 0.06`, `BEAT_FROM 0.9`, `CREW 3`, `BURN_KILL 1.5`,
  `HARM_TICK 0.1`, `COOL 0.5`, `SCORCH_SHOW 8.0`, `THREAT_PAD 0.3`, `TOUCH 0.3`, `BEAT_GAP 0.35`, `WAIT_GAP 1.0`,
  `BEAT_SWING 0.6`.
- [ ] Vars: `id: int`, `at: Vector2`, `radius := RADIUS`, `strength := 1.0`, `out := false`, `beaten := false`,
  `owned := false`, `crew: Array[Person] = []`, `threat_id := -1`, `renew_in := 0.0`, `base_angle := INF`.
- [ ] `func _init(p_at := Vector2.ZERO, p_radius := RADIUS, p_id := 0)`.
- [ ] `func burn_down(dt: float, beaters: int) -> void` (G2); reaching `<= 0.0`: `strength = 0.0`, `out = true`,
  `beaten = beaters > 0`.
- [ ] `func full() -> bool` (`strength > BEAT_FROM`); `func over(g: Vector2) -> bool` (`g.distance_to(at) <= radius`).
- [ ] `static func scorch(field: EnemyField, patches: Array, heat: Dictionary, dt: float) -> int` (GS §5; returns deaths):
  build the tick's in-fire list (patch order, `field.in_radius(p.at, p.radius)` order, skip `out` patches, skip a `Person`
  `inside`, each person once, remembering the first patch); for each: `heat[e] = {"heat": h + dt, "in": true}`, entering
  (no entry or `in == false`) and a `Person` -> `panic(patch.at, patch.radius + THREAT_PAD, &"fire", false)`; a `Person` ->
  `scorched_left = SCORCH_SHOW`; `h + dt >= BURN_KILL - 0.001` -> `field.kill(e, &"fire", patch.at)`, erase. Then every other
  entry (`heat.keys()` order): invalid or dead -> erase; else `heat -= COOL * dt`, `in = false`, `<= 0` -> erase.

**`FireManager` (`src/game/crowd/fire_manager.gd`)**
- [ ] `var patches: Array[GroundFire] = []`, `var _patch_rng := RandomNumberGenerator.new()` (`setup()`: `_patch_rng.seed =
  seed_value + 1`, after `_rng.seed`), `var _heat := {}`, `var _harm_in := 0.0`, `var _next_patch_id := 1`, counters
  `patches_laid`, `patches_beaten`, `patches_burned_out`.
- [ ] `func lay(at: Vector2, radius := GroundFire.RADIUS) -> GroundFire`: new patch, `owned = true`, appended, its danger
  registered at once (`_renew_patch()`), `patches_laid += 1`.
- [ ] `step()`: in the `_step_in` branch, after `_burn(1.0 / HZ)`, `_burn_patches(1.0 / HZ)`; then the harm timer
  (`_harm_in -= delta`; due and (`patches` or `_heat` not empty): `GroundFire.scorch(_crowd._field, patches, _heat,
  GroundFire.HARM_TICK)`). `_recruit` / `_tend_responders` unchanged here (Task 2 adds the beaters).
- [ ] `_burn_patches(dt)`: for each patch (a copy of the list): `burn_down(dt, _beaters(p))` (Task 1: `_beaters()` returns
  0); out -> `_patch_out(p)`; else renew (`renew_in -= dt`, `<= 0` -> `_renew_patch(p)`), then the spread roll (G7, windy
  as `_windy(at)`).
- [ ] `_renew_patch(p)`: `p.renew_in = RENEW`; `p.threat_id = _crowd.threats.register(p.at, p.radius +
  GroundFire.THREAT_PAD, 0.5, RENEW + 0.5, 5.0, 7.0, &"fire")` (the previous id is left to expire as today's renewals do).
- [ ] `_patch_out(p)`: `out = true`, `beaten` -> `patches_beaten += 1` else `patches_burned_out += 1`;
  `_crowd.threats.end(p.threat_id)`; crew stand down (Task 2 fills it in; here the loop over an empty crew); erased from
  `patches`.
- [ ] `func clear_patches()`: every patch `out = true`, `patches.clear()`, `_heat.clear()`; `clear()` calls it.
- [ ] `static func patch_catch(env: EnvironmentField, p: GroundFire, fires: Dictionary) -> Structure` (G7's pick; a test
  hook) and `static func spread_chance(strength: float, windy: bool, dt: float) -> float`.

**Elsewhere**
- [ ] `ThreatManager.end(id: int)` (G6).
- [ ] `Person`: `panic(..., startle := true)` (G5); `var scorched_left := 0.0`, stepped down in the frame like `badge_left`;
  `_draw_body` (or the sprite path that draws `flash()`) darkens toward `SCORCH_COLOR := Color(0.12, 0.09, 0.08)` at `0.45 *
  clampf(scorched_left / 2.0, 0, 1)` while it lasts. A dead person keeps no tint.
- [ ] `Battlefield.clear_effects()`: `if ctx.crowd != null and ctx.crowd.fires != null: ctx.crowd.fires.clear_patches()`.

**Tests -- `tests/test_ground_fire.gd`** (town as `test_fire.gd`: `Town`, `WalkGrid`, `EnemyField`, `Crowd.setup(..., 5)`,
`spawn()`; people moved by hand)
- [ ] `_burns_down`: `lay(g)`; `_burn_patches(0.25)` x 159 (39.75 s) still burning, strength `~0.00625`; one more -> out,
  `patches_burned_out == 1`, `patches.is_empty()`; `GroundFire.new().burn_down(1.0, 3)` takes 0.18.
- [ ] `_danger`: after `lay(g)` an active threat at `g`, radius 1.0, kind `fire`; a calm citizen set 2.0 away panics on
  `crowd._watch_threats()`; one 4.0 away stays calm; after the patch goes out `threats.is_active(id)` is false at once.
- [ ] `_harm_kills`: a citizen held at `g` (re-placed and `_goal` cleared before each `scorch(..., 0.1)`): alive after 14
  ticks (1.4 s), dead (kind `fire`) at the 15th.
- [ ] `_dash_scorches`: in for 9 ticks, then 2.0 away: alive, `scorched_left > 0`, mind `PANIC`, no startle (`_startle_left
  == 0`); its heat entry gone after 18 more ticks; back in for 9 ticks: alive again (cooled).
- [ ] `_once_in_overlap`: two patches 0.3 apart, a person in both: 14 ticks alive (heat 1.4, not 2.8).
- [ ] `_inside_safe`: a person `inside` at `g` is never heated.
- [ ] `_catching`: `patch_catch` picks a house whose footprint is 0.9 from `g` (within 1.0), not one 1.3 away, not a stone
  wall, not one already burning; `spread_chance(1.0, false, 0.25) == 0.02`, windy x3.
- [ ] `_own_stream`: one `FireManager` with a patch stepped 30 s and no building fire, one with none: `_rng.state` equal
  (patches never draw the building stream).
- [ ] `_inert_when_empty`: two crowds from the same seed, one with `lay()` never called: 20 s of `crowd.advance(1/60)` give
  equal `fm._rng.state`, `fires.size()`, `threats.epoch` and every citizen's `ground_pos` (sanity of "inert").
- [ ] `_clear`: `clear()` -> patches out and empty, heat empty; `ThreatManager.end()` with an unknown id does nothing.
- [ ] Import; suite `failures=0`; `refs_check.sh --only="$R"` all OK; commit "feat: ground fire -- GroundFire patches in
  the FireManager: burn down, burn who stays, frighten and bend routes, catch buildings".

---

### Task 2: Beaters (sonnet review)

**`Person`**
- [ ] `var assist_patch: GroundFire`, `var assist_beating := false`, `var _beat_in := 0.0`.
- [ ] `func beat(patch: GroundFire) -> void`: as `assist()` (same refusals: soldier, dead, FLEE, FIGHT, `held_by_will(WILL_FIRM)`)
  then `mind = ASSIST`, `assist_patch = patch`, `assist_fire = null`, `assist_beating = false`, `walk_speed = _mind_speed()`.
- [ ] `func swing_at(g: Vector2) -> void`: faces `g` (as the fight sets `_facing`) and `_swing_left = SWING_SHOW`.
- [ ] `stand_down()` and `_hold_begin()`'s `ASSIST` case also clear `assist_patch`, `assist_beating`.

**`FireManager`**
- [ ] `_recruit()`: the building part as today (only its `fires.is_empty()` early return moved so patches still recruit),
  then `_recruit_patches()` (GS §8): stage rule as the brigade's, skip `out`/veiled, crew filtered to valid `ASSIST` with
  `assist_patch == p`, `most := mini(GroundFire.CREW, _crowd.profile.fire_crew)`, the pool (CALM/RECOVER, profile, alive,
  not inside, not `over()` any patch, within `RECRUIT_REACH`), sorted by `[distance, citizens index]`; each taken:
  `base_angle` set from the first; `_patch_spot(p, slot, WAIT_GAP or BEAT_GAP)` (Vector2.INF = no good spot -> not sent);
  `beat(p)`, `walk_to(spot)`.
- [ ] `_patch_spot(p, slot, gap) -> Vector2` (G9, GS §8: angle `base_angle + slot * TAU / CREW`, 8 turns of `TAU/8`,
  `_crowd._spot_near(spot, 0.1)`, within `radius + gap + 0.3`, not within `radius + 0.2` of any burning patch).
- [ ] `_tend_beaters(delta)` after `_tend_responders(delta)`: per patch, per crew member: invalid / not ASSIST / other
  patch -> dropped; evacuating and not `assist_stays` -> `stand_down()`; `has_goal()` -> wait; arrived: `full()` -> to the
  wait spot if not there, `assist_beating = false`; else to the beat spot if not within `radius + BEAT_GAP +
  Person.GOAL_REACH`; there `assist_beating = true`, `_beat_in -= delta`, `<= 0` -> `_beat_in = BEAT_SWING`,
  `swing_at(p.at)`.
- [ ] `_beaters(p) -> int`: crew members `ASSIST`, `assist_patch == p`, `assist_beating`, within `radius + BEAT_GAP +
  GOAL_REACH`. `_patch_out()` stands its crew down (`stand_down()` for those still on it).

**Tests -- `tests/test_ground_fire_crew.gd`** (town as Task 1; `_arrive(p)` as `test_fire.gd`; stage set to
`crowd.profile.fire_from`)
- [ ] `_turn_out`: five calm citizens 3, 4, 5, 6 and 12 from a patch, everyone else 20 away: `_recruit()` -> the three
  nearest are `ASSIST`, `assist_patch == patch`, `assist_fire == null`, `intent() == Intent.ASSIST`; the others calm. Below
  `fire_from`: nobody. A soldier 2 away is never taken. With a profile `fire_crew` of 2: two.
- [ ] `_wait_then_beat`: at strength 1.0 each goal is `radius + WAIT_GAP` (± 0.15) from the centre and no beater beats
  (`_beaters == 0`, strength falls at `BURN_DOWN`); at 0.9 their next goal is `radius + BEAT_GAP` (± 0.15); no goal in the
  run is ever within `radius` (checked every step).
- [ ] `_rates`: from 0.9, three arrived beaters: out after 5.0 s (± 0.25); two: 7.5 s; one: 15.0 s; `beaten == true`,
  `patches_beaten == 1`; each beater `RECOVER`, `assist_patch == null`; the patch's threat no longer active.
- [ ] `_stand_down`: at `EVACUATION` the crew stands down; a beater frightened by `panic()` leaves and the next
  `_recruit()` takes a new one; `_swing_left > 0` is seen while beating.
- [ ] `_house_first`: a burning house and a patch, four calm citizens near both, `fire_crew` 4: all four go to the house.
- [ ] `_inert_when_empty` (Task 1's) still passes.
- [ ] Focused suites `test_fire`, `test_ground_fire`, `test_ground_fire_crew`, `test_corps`, `test_engineers` (if present);
  full suite; `refs_check.sh --only="$R"` all OK; commit "feat: ground fire -- calm citizens gather round a patch and beat
  it out".

---

### Task 3: GroundFireSprite (`src/fx/set2/ground_fire_sprite.gd`)

- [ ] `class_name GroundFireSprite extends Node2D`; `const GROUP := &"fx_lasting"`; `var patch: GroundFire`;
  `func setup(p: GroundFire, ctx: FxContext) -> GroundFireSprite` (adds itself to `ctx.world` at the patch's screen point,
  `add_to_group(GROUP)`, builds its ground node in `ctx.ground` -- decal `FxParts.SH_DECAL`, light `FxParts.SH_LIGHT`
  registered with `ctx.lights` when it is not null -- two `FlameSprite`s, embers and smoke `PixelParticles` with
  `rng.seed = p.id * 7919 + 13`).
- [ ] `func hold_voice(voice: Node, strip: Array) -> void`: keeps the strip's `orb_embers` loop; fades it with
  `ctx.fade_out(voice, 1.0)` once every patch of `strip` is `out`.
- [ ] `func advance(delta)` (and `_process` calls it): when `not patch.owned`: `patch.burn_down(delta, 0)` and its own
  harm tick (`GroundFire.scorch(ctx.field, [patch], _heat, HARM_TICK)` every `HARM_TICK`). Always: visuals follow
  `patch.strength` (GS §9); on `out`: a smoke puff if `beaten`, flames out over 0.6 s, scorch fade 6 s, then `queue_free()`
  of itself and its ground node.
- [ ] `_exit_tree()` frees the ground node if it still stands (so `Battlefield.clear_effects()` freeing the sprite leaves
  nothing).

**Tests -- `tests/test_ground_fire_sprite.gd`** (`FxStage.make()`; `sprite.advance(dt)` by hand)
- [ ] `_no_town`: an unowned patch: after 39.9 s still burning, after 40.1 s `out`; a dummy held in it dies at 1.5 s
  (kind fire); the sprite is in group `fx_lasting` under `ctx.world`; 6.7 s after `out` the sprite is queued for freeing.
- [ ] `_owned`: an owned patch's strength is never changed by the sprite (set to 0.5 by hand, 10 s of `advance`: still 0.5);
  the flames' strength follows `sqrt(0.5)`.
- [ ] `_voice`: `hold_voice(null, strip)` with no Sfx does not fail (headless `ctx.play()` returns null).
- [ ] `_no_ctx_rng`: `bf.ctx.rng.state` unchanged by `setup()` and 5 s of `advance()`.
- [ ] Import; focused suite; full suite; `refs_check.sh --only="$R"` all OK; commit "feat: ground fire -- the patch's look:
  flames, embers, smoke, scorch and light, lasting past the cast".

---

### Task 4: Dragonfire lays the ground (`dragonfire_parade.gd`)

- [ ] Consts `PATCH_RATE := 8.0 / BREATH_TIME`, `PATCH_NEAR := 2.0`, `PATCH_FAR := 9.5`, `GOLDEN := 0.618034`; vars `strips:
  Array = []`, `patches_laid := 0`, `_laid := 0` (this breath), `_lv_patches := 0` (set in `_build()`:
  `roundi(PATCH_RATE * lv_breath_time)`).
- [ ] `_breathe()` starts a new strip (`strips.append([])`, `_laid = 0`); `_breathe_back()` resets `_laid` instead of
  `_next_patch` (the var goes).
- [ ] `_fx_process`: the `_next_patch` block and `_fire_patch()` are removed (G11). In their place: `while _laid <
  _lv_patches and k >= (_laid + 0.5) / _lv_patches: _lay(beam_angle, _laid); _laid += 1`.
- [ ] `_lay(angle, i)`: `phase := 0.0 if _back else 0.5`; `d := PATCH_NEAR + (PATCH_FAR - PATCH_NEAR) * fposmod(phase + i *
  GOLDEN, 1.0)`; `g := origin + Vector2.RIGHT.rotated(angle) * d`; skip outside `ctx.field.bounds` or in a river
  (`City.current().rivers()`; if `City.current()` is not safe headless, the river test only runs with `ctx.crowd`);
  `patch := ctx.crowd.fires.lay(g) if ctx.crowd != null else GroundFire.new(g, GroundFire.RADIUS, 1000 + patches_laid)`;
  `GroundFireSprite.new().setup(patch, ctx)`; the strip's first patch also `ctx.play(&"orb_embers", g, -6.0)` -> handed to
  its sprite's `hold_voice(voice, strips.back())`; `strips.back().append(patch)`; `patches_laid += 1`.
- [ ] Nothing else moves: the beam's kills, building damage, `duration`, `busy`, the twist schedule are untouched.

**Tests -- `tests/test_dragon_ground.gd`** (`FxStage`, as `test_ruin_twist_dragon.gd`; step `fx._process(1/60)`)
- [ ] `_level_one`: after the breath, `strips.size() == 1`, `strips[0].size() == 8`; every patch lies within `PATCH_NEAR -
  0.01 .. PATCH_FAR + 0.01` of `origin` and within the arc (`_start_angle - 0.05 .. _start_angle + lv_sweep_arc + 0.05`);
  no two consecutive patches lie within 1.0 of each other's distance; eight `GroundFireSprite`s in `ctx.world`.
- [ ] `_levels`: level 2 -> 9, 3 -> 9, 4 -> 10; level 5 -> `strips.size() == 2`, 11 + 11; the second strip's distances differ
  from the first's (phase).
- [ ] `_no_rng`: two casts at level 1 with different `ctx.rng` seeds lay patches at the same points (± 0.001).
- [ ] `_town`: with a `Crowd` + `FireManager` on the stage (as `test_ruin_twist_cinder._town_pool`), the patches are in
  `crowd.fires.patches`, `owned`, and their danger is registered; `crowd.fires.patches_laid == 8`.
- [ ] `_outlives`: after `fx` finishes (stepped past `duration`) the sprites remain and their patches still burn; a dummy
  placed in the first patch then dies within 1.6 s (no town: the sprite's step).
- [ ] If `test_ruin_twist_dragon` / `test_ruin_levels` / `test_awareness` read the old flames or a recorded rng state, update
  that check only, with a `Ruling:` line.
- [ ] Import; focused suites (`test_dragon_ground`, `test_ruin_twist_dragon`, `test_ruin_levels`, `test_awareness`); full
  suite; `refs_check.sh --only='^(digest|crowd_check)$'` OK; commit "feat: Dragonfire Parade leaves burning ground -- a strip
  of ground fire per breath".

---

### Task 5: References and gates (sonnet review)

Machine quiet first (memory `flow-needs-quiet-machine`: no other session's Godot; `powershell` count as `land.sh`'s
`busy()`).

- [ ] **Find every Dragonfire run again**: `grep -rn '"dragon"' tools/dev/routes src/game/mission tools/dev/behaviour_check.gd
  tools/dev/refs` -- expected: `behaviour_check.gd` (lanterns, route a), `tier2_b.gd` (lanterns route b), `tier5_b.gd`
  (judgement and the night's Judgement act, route b), `route_book.gd`. Anything new joins the lists below.
- [ ] **The Dragon rows:** `bash tools/dev/refs_check.sh --only='^(lanterns_|judgement_b_play_|night_b_play_)'`. Expected to
  MISMATCH (12): `lanterns_b_play_1-3` (`routes_t2.tsv`), `lanterns_toll_1-3` (`lantern_night2.tsv`),
  `judgement_b_play_1-3`, `night_b_play_1-3` (`routes_t5.tsv`). Expected OK: `lanterns_none` (case none never casts). A
  night row that stays OK is fine if its run never cast Dragonfire (say so). Any other mismatch in this set: stop, report.
- [ ] **Everything else unmoved:** the whole set in four runs under 10 minutes each: `--only='^[a-f]'`, `'^[g-m]'`, `'^[n-s]'`,
  `'^[t-z]'`. Only the rows above may mismatch; `digest` and `crowd_check` OK.
- [ ] **Gates** (each must PASS its bar; print the verdict lines in the report):
  - `bash tools/dev/gate.sh lanterns` (route a: none lost 3/3, play wins >= 2/3, median 180-240 s, idle <= 45)
  - `bash tools/dev/gate.sh lanterns --case=toll` (wins >= 2/3)
  - `bash tools/dev/gate.sh lanterns --route=b --board` (wins >= 2/3, median 150-270 s, idle <= 45)
  - `bash tools/dev/gate.sh judgement --route=b --board`
  - `bash tools/dev/gate.sh night --route=b --board`
  - A FAIL: first read why (burning ground now kills more, or beaters pull citizens off a duty the route counted on); fix in
    that route's own script (`tier2_b.gd`, `tier5_b.gd`, or the lanterns part of `behaviour_check.gd`), rerun its gate and
    its rows; never a GS number. A route fix that moves a row outside the Dragon set is not allowed: stop and report.
- [ ] **Re-record** each moved row in place with the new checksum (from the refs line `name: <got> ...`); append to each
  touched file's header comment "Re-recorded for Dragonfire's burning ground (2026-11-03)". Rerun
  `refs_check.sh --only='^(lanterns_|judgement_b_play_|night_b_play_)'` -> all OK.
- [ ] Full suite `failures=0`. FLOW is not needed (no FLOW/board/director change) unless a route fix touched a shared path.
- [ ] Commit "refs: Dragonfire's burning ground -- N Dragon rows re-recorded, five gates pass" with a body listing every row
  `name old -> new` and the reason (Dragonfire now lays ground fire: patches burn people, frighten and reroute the crowd,
  draw beaters; its old decorative flames' `ctx.rng` draws are gone), and every gate verdict line.

---

### Task 6: Docs (sonnet; no review)
- [ ] `docs/KAK_Dragon_Ground_Fire.md` (short): what the ground does (GS §1), the numbers table, how to see it (a Dragonfire
  cast in the sandbox; `behaviour_check --scenario=lanterns --route=b --board`), the rulings G1-G12 plus every `Ruling:` the
  task reports gave (each with its task), the moved rows and gate lines from Task 5, the out-of-scope list (GS §11).
- [ ] Update the Dev Ledger after landing (memory `kak-dev-ledger`); commit "docs: Dragonfire ground fire summary and rulings".

## Review focus (milestone review)
1. Inert when empty: `_inert_when_empty`, `_own_stream`, and Tasks 1-3's `refs_check --only="$R"` all OK.
2. The design's numbers: 40 s / 15 s / 5 s, 1.5 s kills, a dash scorches, beaters wait at full strength and never stand in.
3. Determinism: no `ctx.rng` in laying or sprites; the patch stream is its own; orders as stated.
4. Only Dragon rows moved, each named in Task 5's commit; the five gates pass.
