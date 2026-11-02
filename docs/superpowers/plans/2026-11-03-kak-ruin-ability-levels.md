# KAK Ruin Ability Levels Implementation Plan

Spec: `docs/superpowers/specs/2026-11-03-kak-ruin-ability-levels-design.md` (approved 2026-11-03; cited **RS**). Background:
`docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` §5.4 (ability levels) and §6 (Might).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax. Run it the KAK way:
> `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers; a sonnet task review for Task 1 and the Tempest task only).

**Goal:** five levels for each of Ruin's ten powers (smite, ember, tornado, scatter, solaris, dragon, tsunami, cinder,
tempest, shatter): each level's 2-3 stats exactly as RS's tables, read by the effects through `PowerBook.stat()`, and a
level-5 twist per power. Level 1 plays exactly as today: no reference moves.

**Architecture:** the framework is already in (god P1): `PowerBook.levels` plumbing (`has_levels`, `stat_in`, `level_stat`,
`stat`, `twist`, `twist_in`, `level_change`, `levels_problems`, `MAX_LEVEL`), `PowerBook.might(key, level)` (dp, +1 at 3, +1
at 5 -- RS's Might column is exactly this, so the tables hold **no** Might key), `Rules.levels` / `Rules.level_of(slot)`,
`Rules.cast()` putting `extra["level"]` on every cast, the board's Prepare level picker (`PrepareScreen.level_picker`,
`Draft.set_level`) feeding `Game.levels` -> `Mission.levels` -> `Rules.levels`, and the tree's "Level effects not set"
(`PowerBook.NO_LEVELS`, `SkillTreeScreen.spot_lines()`). What is missing, and this plan adds:
1. **Task 1 (groundwork):** the ten tables; a per-level cooldown (today `Rules.cast()` sets `_cooldowns[slot] =
   float(p.cooldown)`, a row field no table reaches); every listed stat read through `PowerBook.stat()` with derived
   timings computed at cast time; a twist gate; level-aware previews; the ten twist test files registered once.
2. **Tasks 2-11:** one twist each, in its own effect file, behind the level-5 gate.
3. **Task 12:** docs.

**Tech stack:** Godot 4.7.2 GDScript; suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references
`tools/dev/refs_check.sh`; `tools/dev/behaviour_check.gd --level=<n>` for a smoke at a level.

---

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r`, branch `god/ruin-levels`. Every command from its root. Never cd
  elsewhere; never touch another worktree. Foreground commands only, each under 10 minutes.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- One suite: `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N`
- Full suite: `bash tools/dev/run_suite_parallel.sh 4` -> `failures=0` before every commit.
- After a new `class_name` or a new test file: `timeout 900 $G --headless --editor --path . --import`.
- New test files are added to `tests/run_all.gd` (`SUITES`). **Only Task 1 edits `tests/run_all.gd`**: it registers every
  file this plan needs, so the parallel twist tasks never touch it.
- **Level 1 must not move any reference:** every row of `tools/dev/refs/*.tsv` (508 rows today) including `digest`
  `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679`. No row is re-recorded. Check:
  `bash tools/dev/refs_check.sh --only='^(digest|crowd_check)$'` in every task; Task 1 runs the whole file (split with
  `--only=` regexes into runs under 10 minutes each, e.g. `'^[a-f]'`, `'^[g-m]'`, `'^[n-s]'`, `'^[t-z]'`).
- **Level-1 exactness rules** (every task):
  - A table's level-1 values equal the constants exactly and keep their type: `int` stays `int` (`BLASTS`, `STONES`),
    a float const stays float (`DAMAGE := 45.0` -> `45.0`, `LIFETIME := 10.0` -> `10.0`, `STORM_TIME 25.0`,
    `MAX_LENGTH 18.0`, `cooldown 10.0`), `VOLLEY` stays `Vector2i`.
  - A derived timing is computed at cast time with the **same expression** as the const it replaces (e.g. Solaris
    `T_CHARGE + beam_time`, Tornado `T_FORM + lifetime`, Dragon `T_BREATH + breath_time + 0.4`) so level 1 is
    bit-identical; a duration written as a literal (Dragon `11.5`) becomes `11.5 + (t_sink - T_SINK)`.
  - Twist code is gated **before** any `ctx.rng` call, any `at()` scheduling or any field/env call, so a level 1-4 cast
    consumes the same random numbers and schedules the same events as today.
  - The consts stay (tests, routes and `PowerBook.IMPACT` read them); the effect reads its own per-instance copy.
- **Determinism:** twists use only `ctx.rng` (or no randomness) and the field's own iteration order; ties are broken by
  distance, then by field order. No `randf()`, no wall clock, no `Time`.
- **Twist gate:** a twist runs only when `PowerBook.twist_at(extra, "<key>")` is true (level 5). A level-4 cast never shows it.
- Per-instance stat vars are named `lv_<const in lower case>` (`lv_kill_r`, `lv_lifetime`, ...), grep-checked unused in
  `src`, `tools`, `tests`; derived ones `lv_t_end`, `lv_t_sink`, ... Set at the top of `_build()`.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Every `Ruling:` goes in the task's report.
- No PixelLab. Twist visuals reuse the effect's own parts (`FxParts`, `Set2Parts`, its inner classes).

## Spec gaps and rulings (binding; R1-R15)

- **R1 Tsunami's labels.** RS calls `LENGTH` "wall length" and `WIDTH` "travel"; in `tsunami_breaker.gd` `LENGTH` is how far
  the wave runs along the drag and `WIDTH` the wall's breadth. The **numbers follow the constant names** (LENGTH
  6.5/7.0/7.5/8.0/8.5, WIDTH 8.0/8.5/9.0/10.0/11.0); the docs name them correctly.
- **R2 Per-level cooldown** is a table stat named `"cooldown"` (lower case: a row field, not an effect const), read by
  `PowerBook.cooldown(key, level)`. Tempest and Earthshatter have no cd column: no `"cooldown"` key; they stay 999 (once).
- **R3 No Might in the tables.** RS's Might column is `PowerBook.might(key, level)` already; a test proves it equals RS.
- **R4 Tree text.** `level_change_in()` prints a stat by a short label when `PowerBook.STAT_LABELS` has one ("kill radius",
  "damage", "cooldown", "start fire", "reach", "pull radius", "life", "bursts", "radius", "burn time", "breath",
  "sweep", "travel", "wall width", "stones", "rain radius", "storm", "bolts", "volley every", "longest crack",
  "fall width", "crawl"), else its raw name (the P1 fixture's `"radius 1.0 -> 1.1"` still reads so); a `Vector2i` prints
  `"5-7"`. *(my call)*
- **R5 Previews follow the level.** `Targeting.area()` and `_on_cast_made()` (the crowd's danger lane) read the slot's
  level for the areas a table changes (Task 1). `PowerBook.REACH` / `IMPACT` (how long the town treats a cast as
  dangerous, when it first kills) stay level-free. *(my call)*
- **R6 Smite fork:** 0.12 s after the strike, a full Smite (kill `lv_kill_r`, `lv_damage` within `HIT_R`) on the nearest
  living person in the open within 2.5 of the bolt who was not struck; it leaps even when the first bolt struck nobody;
  none in reach, no fork.
- **R7 Ember leap:** only if the first building caught (`lit`); 1.0 s after landing, a second spark to the nearest other
  standing burnable (`FireManager.burns()`) within 3.0 of the first one's centre that is not already burning, at the
  level's `START_LEVEL`. Quiet: no fright, no alarm, no `Crowd.on_cast()`.
- **R8 Twin Funnels:** each twin pulls 1.8 for 4 s, core 0.4, wind damage radius 0.6 at the parent's rate; they run
  straight apart along the parent's last heading's perpendicular at `WANDER_SPEED`; a twin flings its captives as the
  parent does (kind wind); twins never split again. A twin pulls only within its own radius (see Task 4).
- **R9 Seeking Bursts:** the seek happens at each burst's compress (`_compress(i)`), moving `points[i]` to the nearest
  living person in the open within 1.5 of it; the random draws are unchanged.
- **R10 Wandering Sun:** the knot is the person within 4.0 of the pillar with the most neighbours within 1.0
  (Tempest's `CROWD_R`); re-picked every 0.5 s; no one in reach, it stands. The pit follows the pillar and is left where
  it stops (`SolarisPit.move_to()`).
- **R11 Second Breath:** 2.0 s after the first breath ends, a second breath of the level's `BREATH_TIME`, sweeping the
  same arc back (right to left). The cast keeps the slots locked through it (busy stays the whole duration).
- **R12 Backwash** is not lethal: from 0.2 s after the crash it draws back from `LENGTH` to 0 over 1.6 s; whoever is
  alive, in the open and in the lane behind the receding edge is carried with it and set down at the start, knocked;
  buildings are not hit again. *(my call)*
- **R13 Lava Pool:** opens at `_sink()` (radius 1.5 at the cast point) and burns 15 s; kills (kind cinder) whoever is in
  it, checked every 0.1 s; "beside it" = standing burnables within 3.0 of the centre (the volcano already levels 2.7),
  set alight at `Tempest.FIRE_LEVEL`-like 0.4 when it opens and again every 3 s if not burning. The effect's duration
  stretches to cover it, but `busy` stays 12.0 (the slots unlock as today).
- **R14 Called Bolts:** a click on the ground with the Wrath slot focused, while its storm is `storming()`, drops one
  hard bolt exactly there after the storm's `LEAD` omen, at most once every 3.0 s; it counts in `bolts` (and so in
  `FIRE_EVERY`). Too soon, or after the storm, the click is refused as a cooldown is. No HUD change beyond the preview
  edge (Task 10); the twist text tells the player. *(my call)*
- **R15 Fault Lines:** forks at 1/3 and 2/3 of the run, the first to the left of the run, the second to the right, 0.6 rad off the line, 5.0 long, the level's
  `HALF` and `SPEED`, each its own `Fissure` (stays open); busy/duration stretch to the last branch's end.

---

## Task order and parallelism

| # | Task | Files (edit) | Depends on | Independent of |
|---|---|---|---|---|
| 1 | Groundwork: tables, cooldown, stat reads, gate, previews, test files | `power_book.gd`, `rules.gd`, `targeting.gd`, `hud.gd`, `prepare_screen.gd`, the ten effect files, tests (below), `run_all.gd` | -- | -- (serial, first) |
| 2 | Smite: Forked Bolt | `src/fx/ruin/smite.gd`, `tests/test_ruin_twist_smite.gd` | 1 | 3-11 |
| 3 | Ember: Leaping Spark | `src/fx/ruin/ember.gd`, `tests/test_ruin_twist_ember.gd` | 1 | 2, 4-11 |
| 4 | Tornado: Twin Funnels | `src/fx/set2/tornado_tempest.gd`, `src/enemies/enemy_field.gd`, `tests/test_ruin_twist_tornado.gd` | 1 | 2-3, 5-11 |
| 5 | Scatter: Seeking Bursts | `src/fx/ruin/scatter_strike.gd`, `tests/test_ruin_twist_scatter.gd` | 1 | 2-4, 6-11 |
| 6 | Solaris: Wandering Sun | `src/fx/solaris/light_of_solaris.gd`, `src/fx/solaris/solaris_pit.gd`, `tests/test_ruin_twist_solaris.gd` | 1 | 2-5, 7-11 |
| 7 | Dragon: Second Breath | `src/fx/set2/dragonfire_parade.gd`, `tests/test_ruin_twist_dragon.gd` | 1 | 2-6, 8-11 |
| 8 | Tsunami: Backwash | `src/fx/set2/tsunami_breaker.gd`, `tests/test_ruin_twist_tsunami.gd` | 1 | 2-7, 9-11 |
| 9 | Cinder: Lava Pool | `src/fx/set2/cinderfall_barrage.gd`, `tests/test_ruin_twist_cinder.gd` | 1 | 2-8, 10-11 |
| 10 | Tempest: Called Bolts | `src/fx/ruin/tempest.gd`, `src/game/rules.gd`, `src/game/targeting.gd`, `tests/test_ruin_twist_tempest.gd` | 1 | 2-9, 11 |
| 11 | Earthshatter: Fault Lines | `src/fx/ruin/earthshatter.gd`, `tests/test_ruin_twist_shatter.gd` | 1 | 2-10 |
| 12 | Docs: summary and rulings | `docs/KAK_God_Ruin_Levels_Summary.md`, `docs/KAK_God_Ruin_Levels_Rulings.md` | 2-11 | -- |

Tasks 2-11 share no file (each owns its effect file and its own test file; `enemy_field.gd`, `solaris_pit.gd`,
`rules.gd`, `targeting.gd` each belong to one twist task only), so they may run in parallel worktrees cut from Task 1's
commit (`--jobs=2` / suite `3` in a parallel group). `FireManager` (`fire_manager.gd`) is only called, never edited.
A twist task that finds it needs a file outside its row stops and reports NEEDS_CONTEXT.

---

### Task 1: Groundwork (mechanical; sonnet review)

**PowerBook (`src/game/power_book.gd`)**
- [ ] Ten `levels` arrays on the rows `smite, ember, tornado, scatter, solaris, dragon, tsunami, cinder, tempest,
  shatter`, index 0 = level 1, keys = RS's stat names exactly, values exactly RS's tables:
  - smite: `KILL_R` 0.6/0.65/0.7/0.75/0.8, `DAMAGE` 45.0/50.0/55.0/60.0/65.0, `cooldown` 10.0/9.5/9.0/8.5/8.0
  - ember: `START_LEVEL` 0.45/0.5/0.55/0.6/0.65, `REACH` 1.0/1.0/1.2/1.2/1.4, `cooldown` 15.0/14.0/13.0/12.0/11.0
  - tornado: `PULL_RADIUS` 3.2/3.4/3.6/3.8/4.0, `LIFETIME` 10.0/11.0/12.0/13.0/14.0, `cooldown` 45.0/45.0/42.0/40.0/38.0
  - scatter: `BLASTS` 12/13/14/15/16 (int), `KILL_R` 0.9/0.9/1.0/1.0/1.1, `cooldown` 30.0/29.0/28.0/27.0/25.0
  - solaris: `RADIUS` 2.2/2.4/2.6/2.8/3.0, `BEAM_TIME` 5.0/5.0/5.5/6.0/6.5, `cooldown` 105.0/100.0/100.0/95.0/90.0
  - dragon: `BREATH_TIME` 2.4/2.6/2.8/3.0/3.2, `SWEEP_ARC` 1.0/1.0/1.1/1.2/1.3, `cooldown` 54.0/52.0/50.0/48.0/46.0
  - tsunami: `LENGTH` 6.5/7.0/7.5/8.0/8.5, `WIDTH` 8.0/8.5/9.0/10.0/11.0, `cooldown` 60.0/58.0/55.0/53.0/50.0 (R1)
  - cinder: `STONES` 20/22/24/26/28 (int), `RADIUS` 5.8/5.8/6.2/6.6/7.0, `cooldown` 75.0/72.0/70.0/66.0/62.0
  - tempest: `STORM_TIME` 25.0/27.0/29.0/31.0/33.0, `VOLLEY` Vector2i(5,7)/(5,7)/(6,8)/(6,8)/(7,9), `VOLLEY_EVERY`
    1.3/1.3/1.3/1.2/1.2 (no cooldown, R2)
  - shatter: `MAX_LENGTH` 18.0/20.0/22.0/24.0/26.0, `HALF` 1.1/1.2/1.2/1.3/1.4, `SPEED` 2.0/2.0/2.2/2.2/2.5
  - level 5 of each also: `"twist": true`, `"twist_text"` (short, from RS): smite "Forked Bolt: leaps to one more nearby",
    ember "Leaping Spark: jumps to the next house", tornado "Twin Funnels: splits in two as it dies", scatter "Seeking
    Bursts: each burst finds someone near", solaris "Wandering Sun: drifts toward the crowd", dragon "Second Breath:
    breathes again, back the other way", tsunami "Backwash: drags the living back", cinder "Lava Pool: a burning pool
    stays 15 s", tempest "Called Bolts: click to call a bolt every 3 s", shatter "Fault Lines: forks twice as it runs".
    *(my call: wording; under 45 characters so the tree's detail line fits -- check `UiTheme.width` in the test)*
- [ ] `static func cooldown(key: String, level := 1) -> float` -- `float(level_stat(key, level, "cooldown", row.cooldown))`;
  0.0 for an unknown key.
- [ ] `static func twist_at(extra: Dictionary, key: String) -> bool` -- `bool(stat(extra, key, "twist", false))` (true only
  at level 5 of a row whose level 5 carries the twist).
- [ ] `const STAT_LABELS := {...}` and `level_change_in()` using it, `Vector2i` as `"a-b"` (R4).

**Rules (`src/game/rules.gd`)**
- [ ] `cast()`: `_cooldowns[slot] = PowerBook.cooldown(key, int(told.level))` -- move the line after `told` is built so a
  caller-set level counts. `func cooldown_of(slot: int) -> float` (the slot's full cooldown at its level).
- [ ] `func live_fx(key: String) -> FxTimeline`: the latest running (valid, not finished) effect of `key` in `_casts`, or
  null (Task 10 uses it; added here so Task 10 does not reshape `_casts`).

**HUD / Prepare**
- [ ] `PrepareScreen.cooldown_text(p: Dictionary, level := 1)`: the row's cooldown at that level (via
  `PowerBook.cooldown(p.key, level)` when the row has a key, else `p.cooldown` -- `test_draft`'s `{"cooldown": 2.5}` still
  passes). Lines 397, 399, 704-706 pass `draft.level_of(key)`.
- [ ] `hud.gd` 1611: `cooldown_text(_rules.power(i), _rules.level_of(i))`; 1621: `_rules.cooldown_of(i)`.

**Targeting (`src/game/targeting.gd`) -- R5**
- [ ] `const AREA_STATS := {"smite": {"r": "KILL_R"}, "ember": {"r": "REACH"}, "tornado": {"r": "PULL_RADIUS"},
  "dragon": {"arc": "SWEEP_ARC"}, "tsunami": {"length": "LENGTH", "half": "WIDTH*0.5"}, "cinder": {"r": "RADIUS"},
  "solaris": {"r": "RADIUS"}, "shatter": {"half": "HALF", "length": "MAX_LENGTH"}}` (scatter's `r` is `RADIUS`, not in
  its table; tempest's preview has no levelled stat). `static func area_at(key, level) -> Dictionary` applies them via
  `PowerBook.level_stat`; `area()` and `_on_cast_made()` use it with `_rules.level_of(slot)` (`_on_cast_made` gets the
  slot it is already handed). At level 1 it returns `AREAS[key]` unchanged.
- [ ] The Ember preview passes the level's reach: `EmberFx.target(env, at, reach := REACH)` gains the parameter.

**The ten effects -- every listed stat through `PowerBook.stat()`** (top of `_build()`; level 1 identical):
- [ ] `smite.gd`: `lv_kill_r`, `lv_damage`; `_strike()` and the staged mark ring read them.
- [ ] `ember.gd`: `lv_reach` (`target(ctx.env, origin, lv_reach)`), `lv_start_level` (`_land()`'s ignite).
- [ ] `tornado_tempest.gd`: `lv_pull_radius` (pull, `shake_radius`, visuals), `lv_lifetime`, `lv_t_end := T_FORM +
  lv_lifetime` replacing every `T_END` read (duration, `at()`, emitter lengths, `curve()` keys).
- [ ] `scatter_strike.gd`: `lv_blasts` (int; the point loop, the schedule, `duration`, `busy`), `lv_kill_r`.
- [ ] `light_of_solaris.gd`: `lv_radius` (scour, pit, visuals), `lv_beam_time`, `lv_t_end := T_CHARGE + lv_beam_time`
  (duration, the scour schedule, `_lift`, `_fx_process` curves, emitters).
- [ ] `dragonfire_parade.gd`: `lv_breath_time`, `lv_sweep_arc` (start angle, arc indicator, sweep, the light callback),
  `lv_t_sink := T_BREATH + lv_breath_time + 0.4`, `duration = 11.5 + (lv_t_sink - T_SINK)`.
- [ ] `tsunami_breaker.gd`: `lv_length`, `lv_width` (lane, wall, sweep, crash point, flood, flotsam, aftermath).
- [ ] `cinderfall_barrage.gd`: `lv_stones` (int), `lv_radius` (barrage placement, `shake_radius`, any visual).
- [ ] `tempest.gd`: `lv_storm_time` (`storming()`, `_build` schedule, `duration`, clouds, dust, rain, `_volley`'s cut-off),
  `lv_volley` (Vector2i), `lv_volley_every`.
- [ ] `earthshatter.gd`: `lv_max_length` (the clamp), `lv_half` (fall test, `Fissure.setup`, wall reach), `lv_speed`
  (crawl, `busy`, `duration`).

**Tests**
- [ ] New `tests/test_ruin_levels.gd` (in `run_all.gd`):
  - `_shapes`: each of the ten rows `has_levels()` and `levels_problems()` is empty; the stat keys per row are exactly
    RS's (plus `twist`, `twist_text` at 5); no row has a Might key; `twist(key)` is the level-5 text and fits the tree's
    detail width.
  - `_level_one`: for each row and stat, level 1 `==` the effect's const with the same `typeof` (e.g.
    `typeof(PowerBook.level_stat("scatter", 1, "BLASTS", 0)) == TYPE_INT`; `level_stat("tempest", 1, "VOLLEY", ...) ==
    TempestFx.VOLLEY`); `PowerBook.cooldown(key, 1) == float(row.cooldown)` for all ten; every value at 1-5 equals RS.
  - `_might`: `PowerBook.might(key, L)` equals RS's Might column for all ten x five.
  - `_cooldown_at_level`: Rules with smite and tornado, `levels = {"smite": 3, "tornado": 5}`, a recording caster:
    after a cast `cooldown_left(0) == 9.0` and `cooldown_of(1) == 38.0`; with no levels, 10.0 and 45.0.
  - `_cast_reads_level3` (one per effect where headless works; the rest staged, below): a level-3 cast reads the
    level-3 value -- Smite `lv_kill_r == 0.7` and a person at 0.68 dies at level 3, lives at level 1; Scatter
    `points.size() == 14`; Solaris `duration == T_CHARGE + 5.5 + AFTER`; Tempest `duration == T_GATHER + 29.0 + T_BREAK`;
    Earthshatter a 30-unit two-click run clamps to 22.0 and `busy == T_CRACK + 22.0 / 2.2`; Ember `lv_reach == 1.2`
    picks a house 1.1 away (none at level 1); Tornado, Dragon, Tsunami, Cinder through the stage: `lv_pull_radius ==
    3.6`, `duration == 11.5 + 0.4` (dragon), `lv_length == 7.5`, `lv_stones == 24`.
  - `_twist_gate`: `twist_at({"level": 5}, k)` true and `{"level": 4}` / `{}` false for all ten; false for `"doom"`.
  - `_previews`: `Targeting.area_at("tornado", 1) == Targeting.AREAS.tornado`; `area_at("tornado", 5).r == 4.0`;
    `area_at("tsunami", 4).half == 5.0`; `area_at("scatter", 5) == AREAS.scatter`.
  - `_tree_text`: `level_change("smite", 2)` names kill radius, damage and cooldown with the right numbers;
    `level_change("tempest", 3)` contains `"5-7 -> 6-8"`; level 5 ends with the twist text.
- [ ] New `tests/fx_stage.gd` (a helper, **not** a suite; no `class_name`): `static func make(seed: int) -> Battlefield`
  adds a `Battlefield` to `(Engine.get_main_loop() as SceneTree).root` (its `_ready()` builds the full `FxContext`),
  sets `ctx.rng.seed`, `field.bounds`; `static func drop(bf)` frees it. The staged set2 effects (tornado, dragon,
  tsunami, cinder use `ctx.impact` / `ctx.lights` / `ctx.shake` unguarded) are cast with `FxTimeline.cast(script,
  bf.ctx, at, {"level": n})` and stepped by `fx._process(dt)`. If a `Battlefield` cannot stage headless, stop and
  report NEEDS_CONTEXT (do not guard the effects).
- [ ] New stubs `tests/test_ruin_twist_<key>.gd` for the ten keys, each `static func run(t) -> void` with one passing
  `t.check(true, "<key> twist: pending (Task N)")`, all registered in `run_all.gd` next to `test_ruin_levels.gd`.
- [ ] Existing tests that P1 wrote against "no table": `test_power_levels._no_tables` -> "no row outside Ruin's ten has a
  table" and its no-table examples use `"doom"`; `test_skill_tree._lines` expects `PowerBook.level_change("smite", 3)`
  as the fifth line, and adds a non-Ruin spot showing `NO_LEVELS`.
- [ ] Import; suite `failures=0`; the **whole** reference set (split `--only=` runs) all OK; commit
  "feat: Ruin's ten powers have five levels -- tables, per-level cooldown, every stat read at its level".

---

### Tasks 2-11: the twists (group B, parallel)

Each task: gate with `PowerBook.twist_at(extra, key)` first; fill its stub test file with the tests listed (RED first);
focused suite; full suite; `refs_check.sh --only='^(digest|crowd_check)$'`; a smoke `behaviour_check.gd --level=5` on a
scenario that drafts the power is optional; commit "feat: <Power> level 5 -- <Twist>". Level-4 test = the same setup at
`{"level": 4}` shows nothing of the twist (and, where the effect is headless, the same `ctx.rng` state after the cast as
level 4 had before this task: `ctx.rng.state` equal at a fixed time).

#### Task 2: Smite -- Forked Bolt (`smite.gd`)
- Hook: `_strike()`. At level 5, after the main strike, `_fork_target() -> DummyEnemy` (nearest alive, not `inside`,
  not struck by this bolt, within `FORK_R := 2.5` of `origin`; tie by distance then field order); `at(t + FORK_DELAY
  (0.12), _fork.bind(where))` strikes at that person's position (kill within `lv_kill_r`, `lv_damage` within `HIT_R`,
  kinds lightning / smite, `struck` counts both; `var forked_at := Vector2.INF` records it). Staged: a short
  `Set2Parts.bolt` from the first spot to the second.
- `duration` 2.2 covers it (no change). (R6)
- Tests (headless, the `test_awareness._smite_lands` context): two people 0.3 and 2.0 from the click, one more at 3.0;
  level 5: both nearer die, the one at 3.0 lives, `forked_at` is the second's spot; level 4: only the first dies,
  `forked_at == Vector2.INF`; level 5 with nobody near: `forked_at == INF`; with nobody at the click but one at 2.0: it
  forks to them.

#### Task 3: Ember -- Leaping Spark (`ember.gd`)
- Hook: `_land()`. At level 5 and `lit`: `at(t + LEAP_DELAY (1.0), _leap)`; `static func leap_target(env, from:
  Structure, fires) -> Structure` = nearest standing burnable within `LEAP_R := 3.0` of `from.center()`, not `from`,
  not already burning (`fires.is_burning` when a town keeps fires); `_leap()` ignites it at `lv_start_level`
  (`ctx.crowd.fires.ignite` or the no-town `damage(1.0, .., &"fire")` path, as `_land()` does). `var leapt: Structure`.
  `duration` becomes `T_LAND + LEAP_DELAY + 1.6` only at level 5; `busy` stays `T_LAND`. Nothing calls `Crowd.on_cast`
  or `fright` (quiet). (R7)
- Tests: houses A at the click, B 2.5 from A, C 3.5 from A; level 5: after `T_LAND + 1.1` both A and B are lit, C not;
  level 4: only A; level 5 with A not burnable / nothing in reach: no leap; B already burning: the leap takes the next
  nearest within 3 or none; `PowerBook.is_quiet("ember")` still true.

#### Task 4: Tornado -- Twin Funnels (`tornado_tempest.gd`, `enemy_field.gd`)
- Problem found: `EnemyField.pull()` steps **every** enemy already `PULLED`, wherever it is, and `_dissipate()` calls
  `release_all()`. Two twins calling `pull()` would drag each other's captives. Add
  `EnemyField.pull_near(center, radius, strength, swirl, delta)` (only within `radius`; nothing else changes; `pull()`
  untouched, so level 1 is identical) and release a twin's captives one by one (`DummyEnemy.release()`).
- Hook: `_dissipate()`. At level 5, after the parent's own dissipate: two `Twin` records (inner class, plain data:
  `center`, `heading`, `life`, `captured`, a small `Funnel` node at `grow` ~0.45) at `_center`, headings
  `_heading ± PI/2`; `_fx_process` (which today returns once `_pulling` is false) runs `_twins_step(delta)`: move at
  `WANDER_SPEED`, `pull_near(center, TWIN_PULL 1.8, ...)`, capture within `TWIN_CORE 0.4` and fling as `_fling()`,
  `damage_radius(center, 0.6, 140.0 * delta, &"wind")`, end at `TWIN_LIFE 4.0` (fling or release captives, fade the
  funnel). `duration` at level 5 = `lv_t_end + maxf(2.8, TWIN_LIFE + 0.6)`. No rng beyond today's. (R8)
- Tests (stage): level 5, `fx._process` to `lv_t_end + 0.1`: `twins.size() == 2`, centres moving apart (distance grows
  over 1 s, > 2.0 after 1.5 s); a dummy 1.5 from a twin is pulled toward it, one 2.5 away is not; a dummy at a twin's
  core is killed (kind wind) within `CAPTURE_TIME + 0.2`; at `lv_t_end + 4.2` no twin is left and no enemy is `PULLED`.
  Level 4: no twins, `duration == lv_t_end + 2.8`. A unit test of `pull_near` (an enemy `PULLED` elsewhere is not moved).

#### Task 5: Scatter Strike -- Seeking Bursts (`scatter_strike.gd`)
- Hook: `_compress(i)` (first line). At level 5: `points[i] = seek(points[i])`, `func seek(p) -> Vector2` = the nearest
  alive, not `inside` person within `SEEK_R := 1.5` of `p`, else `p`. `_blast(i)` already reads `points[i]`. No new rng. (R9)
- Tests (headless): fixed seed, record level-4 `points` (same seed => same draws); put a person 1.0 from `points[3]`
  and one 2.0 from `points[5]` before the compress; level 5: `points[3]` becomes the first's position at its compress
  and that person dies at its blast, `points[5]` unchanged; level 4: no point moves; a person `inside` is never sought;
  the draws before compress equal level 4's.

#### Task 6: Light of Solaris -- Wandering Sun (`light_of_solaris.gd`, `solaris_pit.gd`)
- `var beam_at := origin` (the pillar's centre). `scour()` uses `beam_at`, not `origin` (same value at levels 1-4).
- Hook: `_fx_process(delta)` -- moved above its `_light` early return so it runs headless: at level 5 while `T_CHARGE <=
  t < lv_t_end`, re-pick `_knot()` every `KNOT_EVERY 0.5` (R10: within `WANDER_R 4.0` of `beam_at`, most neighbours within
  `KNOT_R 1.0`, tie by distance then field order), move `beam_at` toward it at `DRIFT 0.8` u/s (never past it), then
  `pit.move_to(beam_at)`; staged pieces (`_column`, `_glow`, `_halo`, `_light`, `_rays`) follow.
- `SolarisPit.move_to(g: Vector2)`: sets `center` and its quad's position (no other change).
- Tests (headless): a knot of 5 people 3.0 east of the cast, one person 2.0 west; level 5: after 2 s of beam
  `beam_at` is ~1.6 east (± 0.05), `pit.center == beam_at`, people in the knot die once the pillar reaches them; level 4:
  `beam_at == origin` throughout; a knot 5.0 away is ignored (it stands).

#### Task 7: Dragonfire -- Second Breath (`dragonfire_parade.gd`)
- `var _back := false` (sweeping back). At level 5 `_build()` also schedules `at(T_BREATH + lv_breath_time +
  SECOND_GAP (2.0) - (T_BREATH - T_INHALE), _inhale)` and `at(T_BREATH + lv_breath_time + SECOND_GAP, _breathe_back)`;
  `_breathe_back()` sets `_back = true`, a `_breath_start` time, and reuses `_breathe()`'s set-up (refactor
  `_breathe()` to take the start time; level 1 calls it unchanged). `_fx_process` uses `(t - _breath_start)` and, when
  `_back`, `beam_angle = _start_angle + _sweep` (right to left). `lv_t_sink` at level 5 = `T_BREATH + 2 * lv_breath_time +
  SECOND_GAP + 0.4`; `duration = 11.5 + (lv_t_sink - T_SINK)`. Busy stays the whole duration. (R11)
- Tests (stage): level 5 (`bt` 3.2): a dummy in the cone dies in the first breath; a second dummy placed in the arc at
  `T_BREATH + bt + 0.5` (after the first breath) dies during the second; `breaths == 2` (a new counter);
  `duration == 11.5 + (2 * 3.2 + 2.0 - 2.4)` (17.5); level 4: one breath, the late dummy lives,
  `duration == 11.5 + (3.0 - 2.4)`.

#### Task 8: Tsunami -- Backwash (`tsunami_breaker.gd`)
- Hook: `_crash()` -> at level 5 `at(t + BACKWASH_DELAY (0.2), _backwash)`; `_fx_process` while backwashing:
  `_back_front` goes `lv_length -> 0` over `BACKWASH_TIME 1.6`; each alive, not `inside` enemy in `in_lane(origin, _dir,
  lv_width * 0.5 + 0.2, _back_front - CARRY_BAND, lv_length + 0.5)` joins `_dragged`; the dragged follow
  `origin + _dir * maxf(_back_front - 0.25, 0) + side offset` as `_carried` do; at the end each is set down at its
  start-side spot and `knock()`ed toward `-_dir`. No kills, no `damage_*` calls. The flood quad shrinks with it
  (staged). Duration 9.5 covers it (crash 4.3 + 0.2 + 1.6). (R12)
- Tests (stage): two people placed after the crash, 5.0 and 2.0 along the lane, one 1.0 outside it; level 5: at
  `T_CRASH + 2.0` both lane people are alive and within 0.5 of the lane start's line, the outsider has not moved;
  level 4: nobody moves; no building takes damage during the backwash (hp unchanged).

#### Task 9: Cinderfall -- Lava Pool (`cinderfall_barrage.gd`, uses `FireManager`)
- Hook: `_sink()` -> at level 5 `_open_pool()`: `var pool_open := true`, `pool_until := t + LAVA_TIME (15.0)`; a staged
  `LavaPool` inner `Node2D` (reuse the barrage's lava-pool decal and `ground_light`, radius `LAVA_R 1.5`) on
  `ctx.ground`; `_fx_process` (headless part first) every `0.1`: `field.kill(e, &"cinder", origin)` for each alive, not
  `inside` within `LAVA_R`; every `LAVA_IGNITE_EVERY 3.0` (first at open): each standing `FireManager.burns(s)` within
  `LAVA_SIDE 3.0` of `origin`, not burning, `ctx.crowd.fires.ignite(s, 0.4)` (no town: `s.damage(1.0, .., &"fire")`).
  At level 5 `duration = T_SINK + LAVA_TIME + 1.0`, `busy = 12.0` (R13); the pool fades over its last second.
- Tests (stage, with a `Crowd` where fires are needed -- or the no-town path): level 5: at `T_SINK + 5.0` a dummy walked
  to 1.0 from the centre dies (kind cinder); a house 2.9 away is set alight (or damaged by fire without a town), one 3.5
  away is not; at `T_SINK + 15.5` a dummy at the centre lives; `busy == 12.0`; level 4: `duration == 12.0`, the dummy
  at 1.0 after the sink lives.

#### Task 10: Wrath of the Sky -- Called Bolts (`tempest.gd`, `rules.gd`, `targeting.gd`; sonnet review)
How a click reaches the live storm (least invasive): the player focuses the Wrath slot again (allowed while cooling:
`Mission._pick()` never refuses) and clicks the ground. `Targeting.release()`'s plain-click path, just before
`_rules.cast(slot, _press, extra)`, asks `_rules.recast(slot, _press)`; true -> the click was the storm's, the slot stays
focused (no `cast_made`, so no `unfocus()`), `UiSound` as a cast. False -> `cast()` runs as today and buzzes "cooldown".
- `Rules.recast(slot: int, at: Vector2) -> bool`: `fx := live_fx(key(slot))`; true only when `fx` has method
  `call_bolt` and `fx.call_bolt(at)` is true. Emits `recast_made(slot, key, at)` (new signal; nothing listens yet but
  tests). No cooldown change. Scripted routes may call it directly (deterministic: it has no rng).
- `TempestFx.call_bolt(at) -> bool`: false unless `twist_at(extra, "tempest")`, `storming()` and
  `t - _last_called >= CALL_EVERY (3.0)` (start `-INF`); then `_omen(at, LEAD, true)`, `at(t + LEAD, _bolt(at, true))`,
  `called += 1`, `_last_called = t`. The bolt is exactly at `at` (no `_pick`, no rng). (R14)
- `Targeting._draw()`: the focused slot's edge is `COL_EDGE` (not `COL_BAD`) while `_rules.can_recast(slot)`
  (`Rules.can_recast`: the same test without acting; `TempestFx.can_call()`).
- Tests (headless `TempestFx` with the minimal context; Rules + recording caster for routing; a `Targeting` with a stub
  Rules is not needed -- the route is asserted through `Rules.recast` and one source check that `release()` calls it
  before `cast`):
  - level 5: during the storm, `call_bolt(p)` true; a person at `p` dies at `+LEAD`; a second call 1 s later false,
    at 3.1 s true; before `T_GATHER` and after the storm false; `bolts` counts it.
  - level 4: `call_bolt` always false.
  - Rules: a level-5 Wrath cast through `Rules.cast()` with a real caster (FxTimeline.cast into a minimal ctx), then
    `recast(slot, p)` true and `cooldown_left` unchanged; with no storm running, `recast` false and `cast()` refuses
    "cooldown".

#### Task 11: Earthshatter -- Fault Lines (`earthshatter.gd`)
- Refactor the crawl body of `_fx_process` into `_crawl(run: Dictionary, delta)` where a run is `{from, dir, length,
  reach, fissure, walls}` (the main crack is run 0; its fields mirror today's `origin`, `to`, `length`, `reach`,
  `fissure`, `_walls_done`, which stay as the public names tests read). The frights, dust and heat stay on the main
  run only. Level 1 identical: same order of field/env calls.
- At level 5: `forks := [lv_length / 3.0, 2.0 * lv_length / 3.0]`; when the main `reach` passes a fork, a branch run
  starts there, direction `dir.rotated(-FORK_ANGLE)` then `+FORK_ANGLE` (0.6 rad; first left, second right), length
  `FORK_LEN 5.0`, its own `Fissure.setup(field, at, at + d * 5.0, lv_half, ctx.rng.randi())` added to `ctx.ground`;
  branches crawl at `lv_speed`, kill (pit) / shove / break as the main crack, and are armed at their end. `busy` /
  `duration` = `T_CRACK + maxf(length, forks[1] + FORK_LEN) / lv_speed` (+ `T_SETTLE`). (R15)
- Tests (headless, `test_shatter`'s context): a 12-unit run at level 5: two branch fissures exist after the crawl, in
  group `fx_lasting`, armed, 5.0 long, on opposite sides of the line; a dummy 2.0 along the first branch dies (pit), one
  mirrored on the other side 2.0 along the second branch dies too; a 4-unit run's busy covers its second branch; level 4:
  one fissure only and the branch-side dummies live.

---

### Task 12: Docs (sonnet; no review)
- [ ] `docs/KAK_God_Ruin_Levels_Summary.md` (short): what levels do, the ten tables (stat names with the R1/R4 words), the
  ten twists in one line each, how to try them (board's Prepare level picker; `behaviour_check --level=5`), what stays
  level-free (R5), the test files.
- [ ] `docs/KAK_God_Ruin_Levels_Rulings.md`: R1-R15 above plus every `Ruling:` the task reports gave, each with its task.
- [ ] Update the Dev Ledger after landing (memory `kak-dev-ledger`); commit "docs: Ruin ability levels summary and rulings".

## Review focus (milestone review)
1. Level 1 is today, bit for bit: the whole reference set, `_level_one`, the rng-state checks in Tasks 2-11.
2. Every RS number is in its table and read at its level: `_shapes`, `_cast_reads_level3`, `_cooldown_at_level`, `_previews`.
3. Each twist runs at 5 and never at 4; deterministic; quiet stays quiet (Ember).
4. The Called Bolts route cannot fire a normal cast or start a cooldown, and nothing else changes in `Targeting`.
