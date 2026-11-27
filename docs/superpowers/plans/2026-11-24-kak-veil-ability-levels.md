# KAK Veil Ability Levels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax. Run it the KAK way (`.claude/skills/kak-milestone/SKILL.md`).
> **No full code in this plan**: it gives files, interfaces, numbers and test cases; the implementer writes the code.

**Goal:** five levels for each of the ten Veil powers, every sized stat a `light / dark` pair read at the cast's level, the dusk
by level, the Pale Eye, and ten level-5 twists ("the dark watches back"). Level 1 plays exactly as today.

**Architecture:** the level framework is in (`PowerBook` `levels`, `stat()`, `twist_at()`, `level_rows_in()`, `levels_problems()`,
`Rules.cast()` stamping `extra["level"]` and `extra["dark"]`, `--bench-level`). The Veil adds the pair: a sized stat's table value is
a two-element Array `[light, dark]`, read through `VeilRules.size(key, stat, dark, level)`. Order:
1. **G1** (alone): tables, sizes and dusk by level, every effect reading its level, the aim, the tree's text, the table test.
2. **G2** (alone, after G1): the Pale Eye and every shared hook a twist needs; ten stub twist suites.
3. **Tracks A-D** (parallel, own worktrees, disjoint files): the ten twists.
4. **F** (after the merge): docs, bench, whole suite, references, FLOW.

**Spec:** `docs/superpowers/specs/2026-11-24-kak-veil-ability-levels-design.md` (cited **VS**; numbers in VS section 5, the Pale Eye in
VS 6, the twists in VS 7). Model: `docs/superpowers/plans/2026-11-17-kak-death-decree-ability-levels.md`.

---

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-veil`, branch `god/veil-levels`. Every command from the worktree root, under `timeout`.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- After a new `class_name`, a new test file or in a fresh worktree, once: `timeout 900 $G --headless --path . --import`.
- One suite (`X` = file name without `test_` and `.gd`):
  `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); timeout 600 $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N 2>&1 | grep -E "SCRIPT ERROR|FAIL|failures="`
  Pass = `failures=0` and no `SCRIPT ERROR` line. No `failures=` at all = a parse error hung the run: a failure.
- Whole suite: `timeout 3000 bash tools/dev/run_suite_parallel.sh 4` -> `checks=C failures=0` (C not below the base's count; the known
  load-flaky perf checks, `test_decree_cage` and friends, rerun alone before calling them failures).
- References: `bash tools/dev/refs_check.sh --jobs=2 --only='<regex>'` prints `OK` / `MISMATCH(want ...)` per row and
  `refs ok=K bad=0` last. A `?` row timed out under load: rerun it alone. **Never re-record a row.**
- **Level 1 changes nothing.** Every level-1 table value equals today's constant and `VeilRules.SIZES` (same type: `MOST`,
  `ILL_MOST`, `TAKE_LAST`, `TORCHES` are `int`, the rest `float`); `VeilRules.SIZES`, `DUSK_R`, `DUSK_TIME` and every effect const stay
  as they are. Scripts keep Blight's 36 s pace (`Rules.pace`). Hunts, routes, bots, clips: level 1, untouched.
- **Twist gate:** `var _twist := PowerBook.twist_at(extra, "<key>")` once in `_build()`; nothing a twist adds (a tick, a list, an
  `at()`, a Pale Eye call, a hook registration) runs unless `_twist`. A level 1-4 cast schedules and measures exactly what it does today.
- **No luck:** every pick by distance (to the point the twist names), a tie to the lower instance id. No `ctx.rng` draw in a twist.
- **The Veil stays quiet:** no twist calls `Crowd.on_cast`, `fright`, `add_alarm`, `threats.register` or a town-heard sound. The one
  new sound is the Pale Eye's player cue.
- **Spared:** no twist's answer touches `Crowd.spared(p)` (the god's believers, whom the mission keeps alive) beyond what the power
  does at level 1: the spared may be eyed, never answered.
- **Held already:** a twist's answer skips anyone `VeilParts.held(p)` names (asleep, a shadow, dreaded), unless VS names him.
- **Reusable effects:** nothing of one twist in `CitizenAgent` or `Person`; G2's named hooks are the only shared additions.
- **Teardown:** what a twist builds (ticks, lists, holds, open-ended eyes, looks) is undone in `_finish()`, `_exit_tree()` and
  `NOTIFICATION_PREDELETE`; a bare context (no crowd, no field, no ground layer) builds and finishes without error; nothing
  screen-only is built headless (`DisplayServer.get_name() == "headless"` or `DominionParts.staged(self)` false). The one exception,
  Blight's watch, is ruled in Track A.
- **Cheap:** a twist that looks for "walks in / comes near / steps out" polls on a `TICK := 0.25` s accumulator over
  `ctx.field.in_radius()` of its own area, never every person every frame.
- **Shared files** (`src/game/power_book.gd`, `src/game/veil_rules.gd`, `src/fx/veil/veil_parts.gd`, `src/fx/veil/veil_cast_looks.gd`,
  `src/fx/veil/pale_eye.gd`, `src/game/crowd/crowd.gd`, `src/game/crowd/person.gd`, `src/game/targeting.gd`, `src/game/rules.gd`,
  `src/audio/sfx.gd`, `src/game/mission/*`, `tests/run_all.gd`) are edited by G1/G2 only. A track that finds it needs one stops and
  reports NEEDS_CONTEXT; a new look goes in an inner class of its own effect file.
- Windowed scripted runs use `user://test_*` files, never `kak_save.cfg`. No PixelLab. Audio sources CC0 or public domain from
  `C:/BURIN_NITRO/SoundLibrary` only (never its `sonniss/`).
- Commits end with the line `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Never `git stash` (a WIP commit). No pushes.
  Every implementer's `Ruling:` goes in its report and, in Task F, into the rulings as a `VL` line.

---

## Decisions (binding; Task F copies them into the rulings as VL1-VL16)

- **VL1 Pair storage.** A sized stat's table value is `[light, dark]` (Array, ints for counts). `VeilRules.SIZES` stays the level-1
  pairs; `VeilRules.size()` reads the row's table at the level and falls back to `SIZES` for a stat the table does not name
  (Evernight's `TAKE_EVERY`). Printed `0.8 / 1.6` (`PowerBook._stat_text()`).
- **VL2 Dusk by level** lives once, in `VeilRules` (`DUSK_RS`, `DUSK_TIMES`, VS 5.1); the tree shows it as one extra row "dusk"
  (`3.0 for 20 s -> 3.25 for 22 s`) on every Veil row but Evernight's. `VeilParts.land()` reads the cast's level.
- **VL3 The watch** = `Crowd.is_watch(p)`: every soldier, plus whoever a mission director's `watches(p)` names (default: its
  `faithful`). `assassinate`'s and `procession`'s `witnesses()` are "anyone near", not the watch.
- **VL4 Blind** is `Person.blind_for(seconds)`: `statuses[&"blind"]`, run down in `Person.tick()`. It joins `veil_blind()` (ruling
  C13's one read: sees, seizes, finds, reports, delivers nothing) and the two copied witness skip lists (`Crowd.nearest_witness()`,
  `TempleReport._witness()`) and the bell keeper. He still walks, flees, fights and cries out. Standing inside a veil does **not**
  blind (the law of the Veil is unchanged, VS non-goal): only VS's leavers and Cloak's turned watch are blind.
- **VL5 Pale Eye life.** An eye is one `(person, cast)` entry: `seconds` (default 4.0, INF = until `unmark`/`release`). It closes on
  time, on `unmark`, on `release` (open-ended ones only), and for good for that cast when the person is taken, dies or is inside;
  another cast may eye him again (a new record entry). Timed eyes outlive their cast (they are the ledger's, a drawing); `release(fx)`
  in every twist's teardown closes the cast's open-ended ones.
- **VL6 Pale Eye place.** One `PaleEye` node per crowd (`crowd.pale_eye`), made on the first `mark()`, on `ctx.overhead_back` (else
  `ctx.overhead`), absolute `z_index 4` (under Targeting's 5), kept the layer's last child so an Unseen Hour blanket or Dread wall at
  the same z never covers it. Headless: the ledger works, nothing is drawn.
- **VL7 Pale Eye cue** `&"v_pale_eye"`: when an eye opens, at most once per `CUE_GAP 1.0` s (eye clock), through the context's
  `play()` at the eyed man when on screen, else at the screen centre's ground point; quiet band (`test_power_sounds` VEIL_MOMENTS).
- **VL8 Silent Doom's witnesses** are named and answered inside `Crowd._settle_doom()` through `answer_doom()` (G2): the effect stays
  out of `crowd.gd`. A silenced witness is killed `&"doom"`, so his own death is judged at the next settle by today's rule.
- **VL9 Dreamless** judges with `nearest_witness(at, null, skip)`, `skip` = every sitter and resting finder of this cast.
- **VL10 Cloak's "drop the pursuit"** is `Person.turn_away(6.0)`: stop fighting, out of a queue, back to post (a soldier) or calm
  with no goal (one of the watch who is not a soldier), and blind 6 s. A director's own errand stops through `_sees()`/`veil_blind()`.
- **VL11 Dread's "stopped at its edge"** is `Person.dread_balked_at` (crowd clock of his last step refused by a dread), set in
  `_step_blocked()`; Track C counts it only within 1.0 of its own dreaded ground.
- **VL12 Blight's watch outlives the cast.** It is the foothold's (a node in `SolarisPit.GROUP`, its id in the foothold meta), ended
  by `BlightFx.heal()`, by its building freed, destroyed or taken, by its crowd freed and by `Battlefield.clear_effects()`.
- **VL13 The Swallowing Dark's marked spared** (believers, the mission-kept) are eyed and marked but not taken outside the circle at
  the fold (anti-goal over "as today"); inside it the power takes them as today.
- **VL14 Evernight's huddle** keeps level 1's slots (`TORCH_R - 0.3`); only the light shrinks (VS 7). Light field: the static light
  is re-added when its radius has shrunk by `LIGHT_STEP 0.05` (no `LightField` change).
- **VL15 Slumber's "not in it at the cast"** = anyone within its circle at `T_FALL`, slept or not. **Unseen Hour's leavers** include
  anyone inside at the fall; the veil lifting blinds nobody.
- **VL16 Twist texts** (fit the tree's detail line; shorten words, never the name, if the fit check fails): doom "No Witness: the
  nearest who saw it falls too"; blight "Watchful Rot: the watch falls ill in your rot"; slumber "Heavy Air: who walks in sleeps
  too"; cloak "Averted Eyes: the watch near them turns away"; unseen "Eyes Within: see the watch; leavers stay blind"; dreamless
  "Found by No One: never found; a finder rests"; dread "The Dark Looks Back: who stops to look is held"; shadowplay "The Shadows
  Keep Watch: who comes close joins"; swallow "Nothing Leaves: who walks out is taken too"; evernight "The Light Gives Way: the
  torchlight shrinks".

---

## Review Focus (the five failure modes most likely to bite; each has a named test)

1. **Two level-5 casts of the same power overlapping.** Holds and eyes are per cast id: Dread's edge-frozen held by two casts stay
   frozen until both lift (Track C `_rf1_two_dreads`); two Unseen Hour veils release only their own eyes (Track A
   `_rf1_two_veils`); a walker caught by one Heavy Air circle is not slept again by the second (`held()`) (Track B `_rf1_two_circles`).
2. **A level-5 cast ended early** (`end_now()`, an act change) or freed (`free()` off the tree) while people are eyed, frozen,
   joined, resting, marked or turned: every hold lifted, every open-ended eye closed, nobody taken, no dusk laid in teardown (Dread),
   no answer left in `Crowd` (Doom). Tests: G2 `_release`; every track's `_teardown`; Track C `_rf2_end_now_frozen`.
3. **An answer landing on someone another Veil power holds** (asleep by Slumber, frozen by Dread, a shadow, a Dreamless sitter):
   skipped by `VeilParts.held()` (G2 `_held`), Track B `_rf3_held_walker` (Slumber, Cloak), Track C `_rf3_held` (Dread, Shadow Play),
   Track B `_rf3_sleeping_finder` (Dreamless: a Slumber sleeper who is the nearest witness rests deep, per today's witness rule).
4. **Evernight's HASTE with level-5 cooldowns:** a level-5 Slumber slot (cooldown 32 s) under a level-5 Evernight is ready after 16 s
   of game time; Evernight's own slot (999) never hastes. Track D `_rf4_haste`.
5. **A level-4 cast next to a level-5 cast:** only the level-5 one's deaths name witnesses (Track A `_rf5_doom_mixed`, struck in one
   frame); a walker in the level-4 circle only stays awake (Track B `_rf5_slumber_mixed`); a night of level-4 casts builds no Pale Eye
   (G2 `_nothing_below_five`).

---

## Task order and parallelism

| Task | Owns | When |
|---|---|---|
| G1 | tables, `VeilRules`, `VeilParts` (sizes, dusk), ten effects (stat reads), `Targeting`, `Rules`, tree text, `test_veil_levels` | first, alone |
| G2 | `PaleEye`, its cue, shared hooks in `crowd.gd`/`person.gd`/mission/report/bell, `VeilParts.held`, stubs | after G1, alone |
| A | `silent_doom.gd`, `blight.gd`, `unseen_hour.gd` + their suites | after G2, parallel |
| B | `slumber.gd`, `cloak_of_night.gd`, `dreamless.gd` + their suites | after G2, parallel |
| C | `dread_of_the_dark.gd`, `shadow_play.gd` + their suites | after G2, parallel |
| D | `the_swallowing_dark.gd`, `evernight.gd`, `evernight_marks.gd`, `evernight_sky.gd`, `shaders/evernight_shade.gdshader` + their suites | after G2, parallel |
| F | docs, bench, landing checks | after A-D merge |

Tracks: branch `god/veil-levels-<a|b|c|d>` cut from G2's commit, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-veil-<a|b|c|d>` (import
first), merged back into `god/veil-levels` in the order A, B, C, D (no shared file, so no conflict expected; a conflict is a plan bug:
stop). While tracks run: per-task suites and `--jobs=2` references only; no FLOW, no bench.

**Rows per task** (`--only=`): every task `'veil'` (36 rows) and `'^(digest|crowd_check|warning_doom)$'`; G1 and F all 508 rows in
four runs (`'^[a-f]'`, `'^[g-m]'`, `'^[n-s]'`, `'^[t-z]'`).

---

### Task G1: tables, sizes and dusk by level, the aim, the tree

**Files.** Modify `src/game/power_book.gd`, `src/game/veil_rules.gd`, `src/fx/veil/veil_parts.gd`, `src/game/targeting.gd`,
`src/game/rules.gd`, the ten effects (`src/fx/quiet/{silent_doom,blight,unseen_hour}.gd`,
`src/fx/veil/{slumber,cloak_of_night,dreamless,dread_of_the_dark,shadow_play,the_swallowing_dark,evernight}.gd`; stat reads only),
`tests/test_power_levels.gd`, `tests/test_ruin_levels.gd`, `tests/test_tree_detail.gd`, `tests/run_all.gd`. Create
`tests/test_veil_levels.gd`.

**Interfaces produced.**
- `PowerBook.POWERS`: the ten rows gain `levels` with VS 5.2-5.6 exactly (index 0 = level 1), stats in VS's column order; sized stats
  as `[light, dark]` (Doom `RADIUS`; Blight `DUSK_R`, `ILL_MOST`; Slumber `RADIUS`; Cloak `MARK_R`, `MOST`; Unseen `RADIUS`,
  `VEIL_TIME`; Dreamless `REACH`, `MOST`; Dread `REACH`; Shadow Play `RADIUS`; Swallow `FULL_R`; Evernight `NIGHT_TIME` (by day / in
  a NIGHT mission)); plain stats `ILL_REACH`, `SLEEP_TIME`, `SPAN`, `REST`, `HOLD`, `GROW`, `TAKE_LAST`, `TORCHES`; `cooldown` from the
  `cd` column (none for `swallow`, `evernight`); level 5 adds `"twist": true` and VL16's `"twist_text"`. `"shape"` lines unchanged.
- `PowerBook._stat_text(v)`: a 2-element Array prints `"%s / %s"` of its two `str()`s.
- `PowerBook.level_rows_in(entry, level)`: after the table rows, appends `VeilRules.dusk_row(String(entry.key), level)` when non-empty.
- `PowerBook.STAT_LABELS` gains: `"ILL_MOST": "fall ill"`, `"ILL_REACH": "ill reach"`, `"blight.DUSK_R": "rot dusk"`,
  `"SLEEP_TIME": "sleep"`, `"cloak.SPAN": "hidden for"`, `"VEIL_TIME": "veil time"`, `"dreamless.MOST": "sit down"`,
  `"REST": "found in"`, `"HOLD": "hold"`, `"shadowplay.SPAN": "play"`, `"FULL_R": "full size"`, `"GROW": "growth"`,
  `"NIGHT_TIME": "night"`, `"TAKE_LAST": "most taken"`, `"TORCHES": "torches"` (existing labels serve `RADIUS`, `REACH`,
  `MARK_R`, `MOST`, `cooldown`).
- `VeilRules`:
  `const DUSK_RS := [3.0, 3.25, 3.5, 3.75, 4.0]`, `const DUSK_TIMES := [20.0, 22.0, 24.0, 26.0, 28.0]` (`DUSK_R`, `DUSK_TIME` stay);
  `static func dusk_r(level := 1) -> float`; `static func dusk_time(level := 1) -> float` (level clamped 1-5);
  `static func pair(key: String, stat: String, level := 1) -> Array` (`[light, dark]`, `[]` when unknown);
  `static func size(key: String, stat: String, dark: bool, level := 1) -> float` (0.0 when unknown, as today);
  `static func dusk_row(key: String, level: int) -> Dictionary` (`{"label": "dusk", "old": "3.0 for 20 s", "new": "3.25 for 22 s"}`;
  `{}` below level 2, for `evernight` and for a non-Veil key).
- `VeilParts`: `static func level(fx: FxTimeline) -> int` (`extra["level"]`, 1 when absent, clamped);
  `size(fx, key, stat)` reads `VeilRules.size(.., dark(fx), level(fx))`;
  `static func land(fx: FxTimeline, at: Vector2, r := 0.0) -> int` lays `maxf(r, VeilRules.dusk_r(level))` for
  `VeilRules.dusk_time(level)` (same numbers at level 1 for every caller).
- Effects, per DD's convention (`lv_<const lower>` set at the top of `_build()` via `PowerBook.stat(extra, key, STAT, CONST)`, used
  wherever the const sized this cast): Slumber `lv_sleep_time`; Cloak `lv_span`; Dreamless `lv_rest` (`duration`, `_found`'s time,
  `rest_left()`, `sleep(lv_rest + 5.0)`); Dread `lv_hold` (`duration`, `_lift`'s time, `crowd.dread()`, `_hold()`, `_strength()`);
  Shadow Play `lv_span`; Swallow `lv_grow` (`t_full`, `radius()`); Evernight `lv_take_last` (`take_count()`), `lv_torches`
  (`bearers()`), `NIGHT_TIME` through `VeilRules.size(.., night, level)`; Blight `lv_ill_reach`.
  Static helpers gain a trailing parameter defaulted to the const: `BlightFx.sick_with(crowd, p, most, reach := ILL_REACH)`,
  `EvernightFx.bearers(crowd, most := TORCHES)`, `DreadOfTheDarkFx.refusal(crowd, ground, dark, level := 1)` (light reach at the level).
- `Rules.cast()`: build `told` (level and dark stamped) before `veil_refusal()` and pass `told` to it; `veil_refusal(key, ground,
  extra)` keeps its signature (a test overrides it) and hands Dread `int(extra.get("level", 1))`.
- `Targeting`: `area()` passes `_rules.level_of(slot)` to `VeilRules.size()`; `static func veil_ringed(key, crowd, at, dark, level := 1)`
  and `static func blight_ill(crowd, p, dark, level := 1)` read the level (Blight also its `ILL_REACH`); `_draw()`'s two callers pass the
  slot's level. `AREAS` stays level 1.

**Tests** (`tests/test_veil_levels.gd`, the `test_death_levels.gd` shape; VS's tables typed again in the test as `VS := {...}`):
- `_shapes`: all ten `has_levels`, `levels_problems()` empty, exactly VS's stat names at every level plus the twist keys at 5 only,
  no Might key, each pair stat an Array of 2 at every level, twist text == VL16 and fits the detail line (the death test's check).
- `_level_one`: level 1 `==` const with the same `typeof` (`SilentDoom.RADIUS` 0.8, `SlumberFx.SLEEP_TIME` 20.0, `CloakOfNightFx.SPAN`
  25.0, `DreamlessFx.REST` 20.0, `DreadOfTheDarkFx.HOLD` 25.0, `ShadowPlayFx.SPAN` 30.0, `TheSwallowingDarkFx.GROW` 0.5,
  `EvernightFx.TAKE_LAST` 10, `EvernightFx.TORCHES` 6, `BlightFx.ILL_REACH` 2.0); every level-1 pair `==` `VeilRules.SIZES[key][stat]`;
  `PowerBook.cooldown(key, 1) == row.cooldown`; `VeilRules.dusk_r(1) == DUSK_R` and `dusk_time(1) == DUSK_TIME`.
- `_values`: every value at levels 1-5 equals VS (pairs element by element).
- `_never_worse`: level to level, `cooldown` and `TORCHES` never rise, every other number (each pair element) never falls.
- `_might`: `might(k, L)` = dp, dp, dp+1, dp+1, dp+2; `might("swallow",5) + might("evernight",5) == 16`;
  `might("dread",5) + might("shadowplay",5) == 13`.
- `_sizes_by_level`: `VeilRules.size("doom","RADIUS",true,5) == 2.2`, `size("cloak","MOST",false,4) == 4.0`,
  `size("evernight","TAKE_EVERY",true,5) == 1.5` (SIZES fallback), `size("smite","RADIUS",true,5) == 0.0`.
- `_cast_reads_level` (headless test context, one number per power): Doom level 3 dark: a person at 1.85 is struck, at level 1 he is not;
  Blight `sick_with(crowd, p, 4, 2.4)` at level 3 dark sickens 4 with the others at 2.3; Slumber level 3 `lv_sleep_time == 24.0`, light
  ring 1.6; Cloak level 4 light marks 4; Unseen level 3 dark: `radius == 7.8`, `veil_time == 34.0`; Dreamless level 4 light: 2 sit,
  found at `T_SIT + 26.0`; Dread level 3 `lv_hold == 30.0`, light `reach == 6.5`; Shadow Play level 3 dark `_r == 6.6`, ends at
  `T_RISE + 34.0`; Swallow level 3 light `full_r == 10.4`, `t_full == 10.4 / 0.6`; Evernight level 4 by day `night_time == 66.0`,
  5 bearers of 6 eligible soldiers.
- `_evernight_takes`: headless EvernightFx (no crowd): `takes` and the sum of `take_count(k)`: level 1 by day 29 / 218; level 5 by day
  33 / 281; level 5 in a NIGHT mission (`night_mission` crowd) 67 / 570.
- `_dusk_by_level`: a level-3 Slumber cast lays `r_at(at) == 3.5` that is gone after 24.0 s and live at 23.9; a level-1 cast 3.0 / 20.0
  (unchanged); Swallow lays `full_r`; Evernight lays none; a level-5 dark Blight building cast's foothold `r_at == 6.2`.
- `_twist_gate`: `twist_at({"level": L}, k)` true only at 5, for all ten; a level-5 cast of each in a crowd context plays level 5's
  numbers and builds nothing else (no `crowd.pale_eye` property yet in G1: check no new child node beyond level 1's).
- `_previews`: Targeting with a slot at level 3: `area().r` for cloak over dark ground 4.5, over light 2.1; `veil_ringed("cloak", crowd,
  at, true, 4).size() == 11` with 12 people in reach; `veil_ringed("dreamless", .., false, 5).size() == 2`; `blight_ill(.., true, 5)` 5.
- `_refusal`: Dread cast in the light with dusk only at 6.6 from the click: refused (`"no_dark"`) at level 1, cast at level 5 (7.0).
- `_tree`: `level_rows("doom", 2)` holds `{"label": "radius", "old": "0.8 / 1.6", "new": "0.8 / 1.75"}` and the dusk row
  `"3.0 for 20 s" -> "3.25 for 22 s"`; `level_rows("evernight", 2)` has no dusk row; `level_change("cloak", 5)` ends with its twist.
- Existing suites: `test_power_levels._no_tables` gains the ten Veil keys ("only Ruin's, Dominion's, Passage's, Death's, Decree's and
  the Veil's have a table") and its `doom` table-less examples become `nova`; `test_ruin_levels` line 351 the same; `test_tree_detail`
  adds a Veil spot: `level_column(s, "slumber")` at 2 has rows (radius, sleep, cooldown, dusk) and a level-5 twist line.

**Verify.** Import; `veil_levels`, `power_levels`, `ruin_levels`, `tree_detail`, `skill_tree`, `power_book`, every `veil_*` suite,
`first_prayers` -> `failures=0`; all 508 rows OK (four `--only` runs); `digest` and `crowd_check` OK.

**Commit** "feat: the Veil's ten powers have five levels -- light/dark pairs, dusk by level, the aim at the slot's level".

---

### Task G2: the Pale Eye and the twists' shared hooks (inert below level 5)

**Files.** Create `src/fx/veil/pale_eye.gd`, `tools/audio/foley/ability/veil/v_pale_eye.json`,
`assets/audio/ability/veil/v_pale_eye.wav` (+ `.import`), `tests/test_pale_eye.gd`, `tests/test_veil_level_hooks.gd`, ten stubs
`tests/test_veil_twist_{doom,blight,unseen,slumber,cloak,dreamless,dread,shadowplay,swallow,evernight}.gd`
(`static func run(t) -> void: t.check(true, "<key> twist: pending (Track X)")`). Modify `src/game/crowd/crowd.gd`,
`src/game/crowd/person.gd`, `src/game/crowd/bell_network.gd`, `src/game/mission/temple_report.gd`,
`src/game/mission/mission_director.gd`, `src/fx/veil/veil_parts.gd`, `src/audio/sfx.gd`, `tools/audio/loudness.tsv`,
`assets/audio/CREDITS.md`, `tests/test_power_sounds.gd`, `tests/run_all.gd` (the twelve new suites).

**The Pale Eye** (`class_name PaleEye extends Node2D`, VS 6, VL5-VL7):
```
const TIME := 4.0
const CUE := &"v_pale_eye"
const CUE_GAP := 1.0
const Z := 4
const EDGE_MARGIN := 12.0
var record: Array[Dictionary]   # {"id": int (person instance id), "key": String, "fx": int (cast instance id), "at": float (crowd clock)}
var cues := 0                   # cue requests made (tests)
static func mark(fx: FxTimeline, p: Person, key: String, seconds := TIME) -> bool   # true when p is eyed by fx after the call
static func unmark(fx: FxTimeline, p: Person) -> void
static func release(fx: FxTimeline) -> void      # closes fx's open-ended (INF) eyes; its timed ones run out
static func of(crowd: Crowd) -> PaleEye          # the crowd's ledger, or null; never makes one
static func edge_point(view: Rect2, screen: Vector2, margin := EDGE_MARGIN) -> Vector2
func is_eyed(p: Person) -> bool
func eyed() -> Array[Person]                     # open eyes, by instance id
func held_by(fx_id: int) -> int                  # open eyes a cast holds
func step(delta: float) -> void                  # _process() calls it; tests call it
func edge_marks() -> int                         # off-screen markers drawn last frame (0 headless)
```
`mark()` returns false with no crowd, no layer, a null/freed/dead/inside person or one this cast's eye closed for good; it makes the
node on first use (VL6), sets `crowd.pale_eye`, adds a record entry when `(p, fx)` was not open, keeps `max(left, seconds)` when it
was. One `_draw()` for all eyes over the heads (a pale almond eye, code-drawn, no badge: `Person.set_badge` untouched); an eyed man off
the view gets an eye at `edge_point()` pointing to him.

**Shared hooks** (each inert unless a twist calls it):
- `Crowd`: `var pale_eye: PaleEye` (cleared with the town where `_doomed.clear()` is); `var mission_watch: Array[Callable]` (cleared in
  `clear_mission_hooks()`); `func is_watch(p: Person) -> bool` (VL3); `func nearest_witness(at: Vector2, exclude: Person = null,
  skip: Dictionary = {}) -> Person` (`skip`: instance ids never chosen; its skip list becomes `hidden_from_watch() or veil_blind()`);
  `func answer_doom(victim: Person, answer: Callable) -> void` and `func unanswer_doom(answer: Callable) -> void`: in `_settle_doom()`,
  before today's loop and only when answers are registered, each registered victim in `dead` (in order) names `nearest_witness(at)`;
  each distinct witness (by instance id, first naming wins) gets `answer.call(witness)` once (an invalid callable is skipped); the
  registered victims are then forgotten and today's loop runs unchanged.
- `MissionDirector`: `func watches(p: Person) -> bool` (virtual, `faithful.has(p)`), registered into `crowd.mission_watch` beside
  `keeps_alive` (line 56's spot).
- `Person`: `func blind_for(seconds: float) -> void` (longest wins; nothing for the dead), `func is_blind() -> bool`, `_blind_left` run
  down in `tick()` (and scaled where `badge_left` is), the status erased at 0; `veil_blind()` includes `&"blind"`;
  `var dread_balked_at := -INF` set to `crowd.clock()` when `_step_blocked()`'s dread branch refuses a step;
  `func turn_away(seconds: float) -> bool` (VL10; false for the dead or inside).
- `TempleReport._witness()` and `BellNetwork`'s keeper check: `is_shadow() or is_dreaded()` -> `veil_blind()`.
- `VeilParts`: `static func held(p: Person) -> bool` = asleep, a shadow or dreaded.

**The cue.** Recipe `tools/audio/foley/ability/veil/v_pale_eye.json` like `v_cloak.json`: about 0.9 s, `rms_db` near -24, a soft high
glassy tone (a CC0 Kenney `impactBell_*` or an oga CC0 glass already listed in `CREDITS.md`, pitched up, high-passed, long fade) over a
breath of air (a CC0 oga wind or breath), light reverb; confirm each source's licence in the library manifest. Build:
`python tools/audio/foley.py v_pale_eye`, `python tools/audio/loudness.py` (then `--check` clean), `python tools/audio/foley.py --credits`,
import. `Sfx.CATALOG[&"v_pale_eye"]` with `"voices": 1` and the `db` that lands it in the Veil quiet band; `test_power_sounds.gd`
`VEIL_MOMENTS` gains `&"v_pale_eye": "res://src/fx/veil/pale_eye.gd"` (the script plays the literal cue).

**Tests.**
- `test_pale_eye.gd`: `_mark` (true; `is_eyed`; one record entry `{id, key "slumber", fx, at == crowd.clock()}`; a second mark by the
  same cast: no new entry, life extended to the longer); `_time_out` (default: eyed at 3.9 s of `step`, not at 4.1; record kept);
  `_open_ended` (`seconds = INF` stays until `unmark`; `release(fxA)` closes A's INF eyes only, not B's, not A's timed ones);
  `_gone_for_good` (taken by `crowd.take()`, killed, `inside = true`: closed on the next step; back outside, the same cast's mark ->
  false and no entry; another cast's mark -> true and a new entry); `_cue` (three eyes opened in one frame -> `cues == 1`; another
  0.5 s later -> 1; at 1.0 s -> 2); `_quiet` (marking five: `crowd.alarm`, `threats.active_count()`, every mind unchanged); `_badge`
  (a badge set before the mark keeps glyph, colour and seconds); `_one_node` (five eyed: one `PaleEye`, no child per person, absolute
  `z_index == 4` < Targeting's 5, the layer's last child after a z-4 sibling is added); `_edge_point` (view `Rect2(0,0,800,600)`:
  `(400,300)` stays; `(1200,300)` -> `(788,300)`; `(-100,-100)` lands on the border on the ray from the centre); `_bare` (no crowd:
  false, nothing made; `of(crowd)` null before any mark); `_headless` (`edge_marks() == 0`, nothing drawn);
  `_nothing_below_five` (every Veil power cast at level 4 in a crowd context run to its end: `PaleEye.of(crowd) == null`, RF5).
- `test_veil_level_hooks.gd`: `_is_watch` (a soldier of each `Corps` true; a citizen false; a director's faithful true through
  `mission_watch`; false after `clear_mission_hooks()`); `_blind` (`blind_for(6)`: `is_blind`, `veil_blind`, `on_watch()` false,
  `nearest_witness` and `TempleReport._witness` pass him over, `MissionDirector._sees` false; after 6.1 s of `tick()` not blind and the
  status gone; while blind he still flees when `panic()`ed and still fights; `blind_for(2)` with 5 left keeps 5; the dead get none);
  `_skip` (the nearest in `skip` -> the next; empty skip == today's answer); `_answer_doom` (a registered victim killed `&"doom"`,
  settle: called once with his nearest witness; two registered victims, one witness: once; an unregistered death: not called; an
  answer that kills the witness: the victim's death judged after with him gone (no alarm with no other witness); `unanswer_doom`: not
  called; a freed object's callable: skipped, no error; no registration: `_settle_doom` as today); `_balked` (a walker into dreaded
  ground: stopped and `dread_balked_at == crowd.clock()`; no dread: `-INF`); `_turn_away` (a fighting soldier: not fighting, mind POST,
  goal his post, blind 6 s; a faithful: CALM, no goal; dead or inside: false); `_held` (asleep, shadow, dreaded true; cloaked, blind,
  sick false).

**Verify.** Import; the two new suites, `power_sounds`, every `veil_*`, `temple_*`/`mira*` and `bell*` suites, `power_levels` ->
`failures=0`; rows `'veil'` and `'^(digest|crowd_check|warning_doom)$'` OK; plus `'^(mira|vigil|god_t1_prayers)'` (the TempleReport
nights) OK.

**Commit** "feat: the Pale Eye and the Veil twists' shared hooks (inert below level 5)".

---

### The twist tracks (A-D)

Every twist: fill its stub first (RED), gate on `_twist`, focused suites (its twist suite, its power's existing suite, `pale_eye`,
`veil_level_hooks`, `veil_levels`), rows (above), one commit "feat: <Power> level 5 -- <Twist>". Every twist suite holds: **level 4**
(the same setup at `{"level": 4}`: nothing of the twist, `PaleEye.of(crowd) == null`); **teardown** (`end_now()` mid-twist and
`free()` off the tree: holds lifted, `held_by(fx_id) == 0`, nobody taken by the twist); **bare** (no crowd, no field: builds,
finishes); the eye's **record** (key = the power's key). Positions below are ground units from the click unless said.

#### Track A: Silent Doom, Blight, Unseen Hour (`src/fx/quiet/{silent_doom,blight,unseen_hour}.gd`; `tests/test_veil_twist_{doom,blight,unseen}.gd`, `test_veil_sizes.gd`, `test_veil_blight.gd`)

**A1 Silent Doom -- No Witness.** At `T_STRIKE`, before the kills, `ctx.crowd.answer_doom(v, _answer)` for each victim; `_answer(w)`:
`PaleEye.mark(self, w, "doom")`, then `ctx.field.kill(w, &"doom", origin)` unless `crowd.spared(w)`. Teardown: `unanswer_doom(_answer)`.
Tests (light, level 5: victim V at the click, witnesses placed within 1.2 of V and outside 0.9 so the cast's own dusk cannot hide them):
- W1 at 1.0, nobody else: W1 eyed and dead (`killed_citizens` +2), `crowd.alarm` unchanged, no `doom` threat: V unseen.
- W1 at 1.0 and W2 at 1.15: W1 falls, W2 lives and is not eyed, V is seen (alarm +`ALARM_KILL`, as today).
- Two victims, one witness: he falls once (+3 dead in all).
- No second hop: W1's own witness X at 1.0 from W1: W1's death is seen at the next settle; X alive, not eyed.
- W1 a believer, then W1 kept by `mission_keeps`: eyed, alive, V seen.
- `_rf5_doom_mixed`: a level-4 cast and a level-5 cast struck in one frame, a witness each: only the level-5 one's witness falls.
- A death inside an Unseen Hour veil names nobody. Teardown: freed before `T_STRIKE` -> no answer left registered.

**A2 Blight -- Watchful Rot.** A level-5 building cast (not a person or a director's thing) gives its foothold a `RotWatch`
(inner class, VL12; `const REST_AFTER := 15.0`), its id in the `FOOTHOLD` meta; `heal()` frees it. Each tick, of
`crowd.is_watch()` people alive, out of doors and not `held()`, those within the foothold's dusk radius now but not at the last tick
stepped in: each is eyed; the first (by distance to the building's centre, then id) while not resting falls ill as `_make_ill()`
makes him (a quarry `make_ill(ILL_TIME)`, else `send_home_sick()`), no cue, and the watch rests 15 s; a spared one is eyed only and
starts no rest. Those inside the dusk at the plant did not step in.
Tests (light, level 5: foothold r 3.4): soldier S from 4.0 to 3.0 -> eyed, `home_sick`; S2 stepping in 5 s later -> eyed only; S3 at 16 s
-> ill; a citizen stepping in -> nothing; a faithful (mission watch) -> ill; a soldier inside at the plant -> nothing; a quarry ->
`make_ill(20)`, not sent home; a fourth blight heals it -> no watch node, S4 stepping in -> nothing; its building freed -> the watch
frees itself; a level-5 person cast -> no watch; no `q_blight_ill` or other cue for the rot's sick, alarm unchanged; bare: no watch.

**A3 Unseen Hour -- Eyes Within.** From the fall to the rise, each tick: the watch within `radius + 4` is eyed open-ended (unmarked when
he leaves that ring); everyone within `radius` joins the cast's insiders; an insider now outside `radius` (alive, out of doors) gets
`blind_for(6.0)` and leaves the list. At the rise and in teardown `release(self)`; nobody is blinded by the lift (VL15).
Tests (light, level 5: radius 5.4): soldier at 9.0 eyed within one tick of the fall; at 9.6 not; a citizen at 6.0 not eyed; the soldier
walks to 10.0 -> unmarked; citizen inside at 3.0 walks to 6.0 -> blind 6.0 s, `nearest_witness` of a death beside him passes him over,
not blind at 6.1 s; one inside at the rise is not blind; `_rf1_two_veils` (a watcher eyed by veils A and B: A's end leaves him eyed by
B, B's end closes it); level 4: no eye, no blind; `end_now()` mid-veil -> every eye of the cast closed.

#### Track B: Slumber, Cloak of Night, Dreamless (`src/fx/veil/{slumber,cloak_of_night,dreamless}.gd`; `tests/test_veil_twist_{slumber,cloak,dreamless}.gd`, `test_veil_slumber.gd`, `test_veil_cloak.gd`, `test_veil_dreamless.gd`)

**B1 Slumber -- Heavy Air.** At level 5 the cast lasts to `T_FALL + lv_sleep_time` and its ring stays drawn (its own look, staged
only). At `_fall`, everyone within `_r` is noted. Each tick, anyone within `_r` alive, out of doors, not noted, not `held()` and not
caught before by this cast sleeps `p.sleep(T_FALL + lv_sleep_time - t, _dark)`, is eyed, and is caught.
Tests (level 5, light r 1.7, sleep 28): a walker entering at t 10 -> asleep with about 18.6 s left, eyed, light (a blow wakes him); the
same in the dark -> deep; one standing in the circle at the fall but awake (a shadow) -> never slept; a woken walker re-entering -> not
slept again; `_rf3_held_walker` (a shadow and a dreaded walking in: not slept, not eyed); `_rf1_two_circles` (a walker caught by one,
walking into a second level-5 circle: still the first's sleep, not eyed again by the second); `_rf5_slumber_mixed` (level-4 and level-5
circles side by side: into the level-4 one, awake); `end_now()` at t 10 -> no more catches, sleepers sleep on.

**B2 Cloak of Night -- Averted Eyes.** Each tick while the cast keeps anyone cloaked: the watch within 2.0 of a person this cast keeps,
alive, out of doors, not `held()` and not turned before by this cast: eyed, `turn_away(6.0)`.
Tests (level 5): a soldier fighting toward a cloaked man reaches 1.9 -> eyed, not fighting, mind POST to his post, `on_watch()` false
for 6 s; at 2.1 -> nothing; the same soldier again -> not turned twice; a citizen -> nothing; a faithful -> CALM, blind; after 6.1 s he
may fight again; `_rf3_held_walker` (a dreaded soldier near: skipped); two level-5 casts -> one soldier turned at most once by each;
`end_now()` -> the ticks stop, the turned stay turned (their own timer).

**B3 Dreamless -- Found by No One.** At `_found`, level 5: sitters in order (nearest the click, then id); `skip` = every sitter's and
resting finder's id (VL9). For each sitter still dreamless and deep asleep: `w := crowd.nearest_witness(s.ground_pos, null, skip)`:
none -> `crowd.take(s, &"dreamt")`; `w` not spared -> take `s`, eye `w`, `w` rests: `w.sleep(lv_rest * 0.5 + 5.0, true)`,
`statuses[&"dreamless"]`, added to `skip` and judged at `t + lv_rest * 0.5` (nobody near by the same search -> taken; somebody -> killed
`&"dreamless"`, a body judged by today's settle); `w` spared -> eye `w`, kill `s` `&"dreamless"` (today). One finder rests once.
`duration` covers the finders' rest; `_undo()` wakes resting finders too.
Tests (level 5, light, `REST` 28): two sitters, nobody within `doom_witness()` -> both taken, no remain, alarm unchanged; a citizen W at
1.5 -> the sitter taken, W eyed, deep asleep, at +14 s with nobody near W -> taken; with X at 1.0 from W -> W killed (a remain), X not
eyed and awake; W a believer -> eyed only, the sitter a body; two sitters, one W -> W rests once; sitters never name each other;
`_rf3_sleeping_finder` (W asleep by Slumber is the nearest witness: he rests deep, then is judged); level 4 -> bodies as today;
`end_now()` while W rests -> W awake, status gone, nobody taken.

#### Track C: Dread of the Dark, Shadow Play (`src/fx/veil/{dread_of_the_dark,shadow_play}.gd`; `tests/test_veil_twist_{dread,shadowplay}.gd`, `test_veil_dread.gd`, `test_veil_shadowplay.gd`)

**C1 Dread of the Dark -- The Dark Looks Back.** From `_fall` to `_lift`, each tick, of the living out of doors within `reach + 1.0`,
not `held()`, not already held by this cast, standing outside this cast's dreaded ground (`origin.distance_to(q) <= reach and
crowd.in_dark(q)`): one whose `dread_balked_at >= fall clock` and who is within 1.0 of it, or who has stood within 1.0 of it for 2.0 s
(per-id timer, reset when he is not), is eyed open-ended and held (`_hold()`, kept in `_edge_ids`, which `_hold_all()` never lets go).
`const EDGE_MOST := 16` a cast, nearest the click first. `_release()` lets them go with the rest and `release(self)`.
Tests (level 5, a dark patch beside the click as `test_veil_dread` lays it): a walker with a goal across stops at the edge -> held
within one tick, eyed, silent (`_voice` skips him); standing 0.8 from the edge for 2.1 s -> held, 1.9 s -> not; at 1.2 -> never; 20
candidates -> 16 held, the 16 nearest the click; at the lift every edge-held man is free and unmarked; `_rf1_two_dreads` (one man held
at the edges of A and B: A lifts, still held; B lifts, free); `_rf2_end_now_frozen` (`end_now()` while 3 are edge-held: all free, no
eye open, no dusk laid); `_rf3_held` (a shadow and a sleeper at the edge: never held); a level-4 cast beside it: its edge holds nobody.

**C2 Shadow Play -- The Shadows Keep Watch.** From `_rise` to `_end`, each tick, anyone alive, out of doors, not `held()`, within 1.0 of
a shadow this cast owns (by distance to that shadow, then id), up to `const JOIN_MOST := 12` a cast: becomes a shadow exactly as
`_rise()` makes one (status `_me`, black, dressed when staged, in `_held`), eyed. `_end()` treats them as the cast's own.
Tests (level 5): a walker at 0.9 from a shadow -> a shadow of this cast, eyed; at 1.1 -> not; at the end in the light he lies down and
wakes (`lain` counts him); in the dark a joined soldier is taken (`taken` +1) and a joined citizen wakes; 15 walkers -> 12 join;
`_rf3_held` (a Slumber sleeper and a dreaded man near a shadow: not joined; another cast's shadow: not taken over by joining); two
level-5 casts: each end treats only its own joined; `end_now()` -> joined let go, nobody taken, `edges() == 0`.

#### Track D: The Swallowing Dark, Evernight (`src/fx/veil/{the_swallowing_dark,evernight,evernight_marks,evernight_sky}.gd`, `shaders/evernight_shade.gdshader`; `tests/test_veil_twist_{swallow,evernight}.gd`, `test_veil_swallow.gd`, `test_veil_evernight.gd`)

**D1 The Swallowing Dark -- Nothing Leaves.** Until `_swallow`, each tick: everyone within `radius()` joins the cast's "stood inside";
one of them now beyond `radius()` (alive) is eyed open-ended and marked (a thin dark thread on him, an inner-class look, staged only).
At `_swallow`, after `_inside()`, every marked man still alive and not already queued is queued and taken by `VeilParts.take_out()`
wherever he is (sheltering or indoors too), except a spared one outside the circle (VL13). Eyes released at the fold and in teardown.
Tests (level 5, light: 10.8 at 0.7/s): a man inside at 3 s walks out to 12 -> eyed, marked; at the fold he is taken though at 12; one who
never stood inside -> untouched; a marked man who went into a shelter -> taken, the shelter's list clean; a marked believer outside ->
alive, eyed; a marked man who died meanwhile -> no error; `end_now()` before the fold -> marked alive, threads gone, eyes closed; level
4 -> the walker out lives.

**D2 Evernight -- The Light Gives Way.** `func torch_r() -> float`: at level 5 `lerpf(TORCH_R, END_R, clampf((t - WAVE) / night_time,
0, 1))` with `const END_R := 1.2`, else `TORCH_R`. Every rules reader takes it: `_in_light(at, lit, r := TORCH_R)` and
`loneliest_n(.., r := TORCH_R)` gain the radius, `_take`'s re-check, `put_out()`'s reach, `_on_laid()` (`r + torch_r()`); every look
reader takes it: the light field (VL14), `NightWash`'s ring, the shade's `torch_r` (set each frame by the sky owner), the glows and warm
islands. The huddle slots stay level 1's (VL14). A claimed man stays claimed. Each bearer is eyed open-ended from `_fall` to `_dawn`
(`release(self)` at dawn and in teardown).
Tests (level 5 by day): `torch_r()` 2.5 at the fall, 1.85 at `WAVE + 34`, 1.2 at `t_dawn`; level 4: 2.5 throughout; a citizen 2.0 from a
torch is not claimable at the fall and is by `WAVE + 27`; huddle slots within `TORCH_R - 0.3` of their torch as at level 1; a 0.5
patch laid straight on the ledger (`crowd.lay_dusk`) 2.3 from a torch at `WAVE + 60` puts it out at level 4 (2.3 <= 0.5 + 2.5) and not
at level 5 (0.5 + `torch_r()` about 1.35); `put_out()` late takes only those within `torch_r()`; 5 bearers
eyed, none at dawn; a NIGHT mission shrinks over 102 s; `_rf4_haste` (a level-5 Slumber slot under a level-5 Evernight is ready after
16 s; Evernight's slot is not hastened); `end_now()` mid-night: no light-field static of the cast left, no eye open.

---

### Task F: finish (after A-D merge into `god/veil-levels`)

**Files.** Modify `docs/KAK_God_Veil_Summary.md` (a "Levels" section: the tables in stat words, the dusk row, the ten twists one line
each, the Pale Eye, how to try them (Prepare's level picker; `--bench-cast=KEY --bench-level=5`), what only the user can judge: VS 11),
`docs/KAK_God_Veil_Rulings.md` (a "Levels (prefix VL)" section: VL1-VL16, every implementer `Ruling:` as VL17 on, the bench table).

**Checks.**
- [ ] Import; whole suite -> `failures=0` (known perf flakes rerun alone).
- [ ] All 508 rows in four `--only` runs -> OK; `digest`, `crowd_check`, `warning_doom` OK; nothing re-recorded.
- [ ] Bench, quiet machine (no other Godot; memory `kak-m1-perf-debt`), three back-to-back pairs each, base
  `timeout 300 $G --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench --loadout=<keys>` against the
  same with `--bench-cast=<keys> --bench-level=5 --bench-after=<s>` (Swallow `--bench-after=17`, VA9; the others 4): `dread`,
  `shadowplay`, `swallow`, `evernight`, `evernight,unseen`, `evernight,dread`. Pass: `avg_ms` cast / base <= 1.55. Over the bar: a
  finding for the user with its number (no tuning in F).
- [ ] FLOW alone: `timeout 900 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep -a "FLOW result"`
  -> `209/0`.
- [ ] One windowed look (a `user://test_*` save): the skill tree's Cloak spot at level 4 shows its rows and the dusk row unclipped.
- [ ] Commit "docs: the Veil's ability levels -- summary, VL rulings and the level-5 bench".
