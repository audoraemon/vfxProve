# KAK Dominion Ability Levels Implementation Plan

Spec: `docs/superpowers/specs/2026-11-09-kak-dominion-ability-levels-design.md` (approved 2026-11-09, "Ok let's do it"; cited
**DS**). Model: the Ruin levels plan `docs/superpowers/plans/2026-11-03-kak-ruin-ability-levels.md` and its rulings
`docs/KAK_God_Ruin_Levels_Rulings.md` (R1-R15, R5a, R12a, the recast rule): every Ruin ruling that is not about a Ruin power
holds here too.

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md`
> (sonnet implementers; a sonnet task review for Task 1 and the Voice task only). **No full code in this plan**: it gives
> interfaces, files, numbers and test cases; the implementer writes the code.

**Goal:** five levels for each of Dominion's ten powers (whisper, discord, madness, wisp, clearmind, saint, sanctuary,
anathema, voice, schism): each level's stats exactly as DS's tables, read by the effects through `PowerBook.stat()`, and a
level-5 twist per power (DS's "puppet master": each twist is a new way to steer people already in the god's hand). Level 1
plays exactly as today: no reference moves.

**Architecture:** the level framework is in (god P1 + Ruin levels): `PowerBook.levels` tables, `MAX_LEVEL`, `MIGHT_STEPS`,
`stat()`, `level_stat()`, `stat_in()`, `cooldown()`, `mode_cooldown()`, `twist_at()`, `twist()`, `level_change()`,
`STAT_LABELS`, `levels_problems()`; `Rules.cast()` puts `extra["level"]` on every cast and takes the level's cooldown (a mode's own
cooldown wins: Wisp ENTHRALL 75 s); `Rules.recast()` / `can_recast()` / `live_fx()` (Ruin's Called Bolts: a click on a focused
slot whose effect is still running goes to that effect); `Targeting.area_at()` / `AREA_STATS`; `tests/fx_stage.gd`. This plan adds:
1. **Task 1 (groundwork):** the ten tables; every listed stat read through `PowerBook.stat()` (or `level_stat()` where the read
   is outside the effect); level-aware previews; **the one shared follow-up mechanism** (Called Bolts generalised); three inert
   `Person` hooks the twists call; the test files registered once.
2. **Tasks 2-11:** one twist each, in its own effect file, behind the level-5 gate, in three parallel tracks.
3. **Task 12:** docs.

**Tech stack:** Godot 4.7.2 GDScript; suite `tests/run_all.gd` (+ `tests/run_part.gd`, `tools/dev/run_suite_parallel.sh`);
references `tools/dev/refs_check.sh`; `tools/dev/behaviour_check.gd --level=<n>` for an optional smoke at a level.

---

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/bold-goldstine-e7bb80`, branch `god/dominion-levels` (cut from
  `feat/god-progression` `654f1b54`; DS committed `acaac609`). The twist tracks run in their own worktrees (see "Task order"). Every
  command from the worktree root; never cd elsewhere; never touch another worktree. Foreground commands, each under 10 minutes,
  each under `timeout`.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- One suite (`X` = the file's name without `test_` and `.gd`):
  `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); timeout 600 $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N 2>&1 | grep -E "SCRIPT ERROR|FAIL|failures="`
  **Always grep for `SCRIPT ERROR`**: a parse error makes run_part hang until the timeout, and prints no `failures=`.
- Full suite in 6 parts: `for i in 1 2 3 4 5 6; do timeout 900 $G --headless --path . --script res://tests/run_part.gd -- --part=$i --of=6 2>&1 | grep -E "SCRIPT ERROR|FAIL|failures="; done`
  -> six lines `failures=0` (or `bash tools/dev/run_suite_parallel.sh 3` -> `failures=0`).
- After adding a `class_name` file or a new test file: `timeout 900 $G --headless --editor --path . --import` (memory: the class
  cache; a fresh worktree needs it before its first headless run).
- **Only Task 1 edits `tests/run_all.gd`**: it registers every file this plan needs, so the parallel twist tasks never touch it.
- **Level 1 must not move anything.** Expected base results (do not re-record any row):
  - suite `failures=0`;
  - every row of `tools/dev/refs/*.tsv` (`references.tsv` and the rest; 508 rows today) through `bash tools/dev/refs_check.sh`,
    including `digest` `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679`;
  - **known base mismatch:** `bread_play_3` already shows `-133947279` on the base; it is not this work (do not fix, do not
    re-record; report it as "pre-existing");
  - FLOW `209/0` (run alone, on a quiet machine: memory `flow-needs-quiet-machine`).
- **Level-1 exactness rules** (every task):
  - A table's level-1 values equal the constants exactly and keep their type: `int` stays `int` (`LURE_MAX`, `MAX_GUARDS`,
    `GATHER_CAPACITY`, `MAX_FIGHTERS`), a float const stays float (`REACH 10.0`, `ATTACK_SECS 10.0`, `DISCORD_TIME 15.0`,
    `SPAN 40.0`, `DURATION 25.0`, `REGION 14.0`, `cooldown 8.0` ...).
  - A derived number is computed at cast time with the **same expression** as today (`T_CAST + lv_trance_time + 0.5`,
    `lv_wisp_time - 0.5`, Voice `float(COMMANDS[command]) * lv_command_x` with `COMMAND_X := 1.0`: `x * 1.0 == x` exactly).
  - A static helper that reads a levelled const (`DiscordFx.taken`, `MadnessBloomFx.victims_at`, `WillOWisp.drawn`,
    `SacredSanctuaryFx.picked_at`, `AnathemaFx.marked_at`, `MindWhisperFx.clamp_to`) gains a trailing parameter **defaulted to
    the const**; every existing caller (directors, routes, behaviour_check) keeps calling it without one and so stays level 1.
  - Twist code is gated **before** any `ctx.rng` call, any `at()` scheduling or any field/env/crowd call, so a level 1-4 cast
    consumes the same random numbers and schedules the same events as today.
  - The consts stay (directors, routes and tests read them); the effect reads its own per-instance copy.
- **No twist uses a random roll** (DS: "No twist is a random roll"). Twists use no rng at all; ties are broken by distance, then
  field order. No `randf()`, no wall clock, no `Time`.
- **Twist gate:** a twist runs only when `PowerBook.twist_at(extra, "<key>")` is true (exactly level 5). A level-4 cast never shows it.
- Per-instance stat vars are named `lv_<const in lower case>` (`lv_reach`, `lv_span`, `lv_max_guards`, ...), grep-checked unused in
  `src`, `tools`, `tests`; set at the top of `_build()`.
- Directors, routes and `behaviour_check` keep reading the constants (they play level 1). E.g. `InformerDirector` reads
  `DiscordFx.DISCORD_TIME` as "confused with the full time left": a longer level-5 confusion still passes its `>=` test.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never `git stash` (use a WIP commit). Never push.
  No PixelLab. Twist visuals reuse the effect's own parts (`DominionParts`, `FxParts`, its inner classes). Every `Ruling:` the
  implementer makes goes in its report.

## The shared follow-up mechanism (decided here; built in Task 1)

DS's Notes ask for one way for a live cast to take a follow-up order. **It exists already for Ruin's Called Bolts; this plan
generalises it rather than adding a second one:**
- **Input (the same for every power):** the player selects the power's slot again (its number key or its card; allowed while it
  cools: `Mission._pick()` never refuses) and **clicks the ground**. While the slot's live effect can take an order, the slot
  aims as a plain click whatever its own aim kind (Divine Schism's CUSTOM is "two clicks"; Voice's command is the Q/E mode as for a
  cast). The click goes to the live effect, starts no cooldown, sends no `cast_made`, and the slot stays selected.
- **How the player knows:** (1) the HUD slot card turns gold while an order can be given (gold frame, its cooldown seconds in
  gold) -- `Rules.can_recast(i)`; (2) the aim preview's edge is gold, not red (already so for Called Bolts) and shows the
  follow-up's own area when the effect gives one; (3) the twist text says "click again" (tree and Prepare card; DS: "say it on
  the power's tooltip").
- **Interface:** an `FxTimeline` takes orders by having two methods (duck-typed, as today):
  `func can_follow_up() -> bool` and `func follow_up(at: Vector2, extra: Dictionary) -> bool` (true = taken), and may have
  `func follow_up_area() -> Dictionary` (a `Targeting.AREAS`-shaped area for the preview; `{}` = the power's own).
  - `Rules.recast(slot, at, extra := {}) -> bool` calls `fx.follow_up(at, extra)` (was `call_bolt(at)`);
    `Rules.can_recast(slot)` calls `fx.can_follow_up()` (was `can_call()`); new `Rules.follow_up_area(slot) -> Dictionary`.
    The recast rule stays: false when the run is `finished` or `busy_left() > 0.0`.
  - `TempestFx` gains `can_follow_up()` -> `can_call()` and `follow_up(at, _extra)` -> `call_bolt(at)` (both kept; Tempest's
    tests are unchanged and must pass).
- Three twists use it: **Procession** (Wisp), **Second Word** (Voice), **Turn the Tide** (Schism). **Held String is not a
  follow-up** (see R2): DS says its cooldown still applies, so it is an ordinary new whisper -- the same "select the slot, click"
  input, through `Rules.cast()`.

## Spec gaps and rulings (binding; D1-D18)

- **D1 Tables.** Stat keys are the effect's const names exactly; the cooldown key is `"cooldown"` (Ruin R2). **Divine Schism has
  no `"cooldown"` key** (999, once a night, as Tempest). **Wisp's ENTHRALL keeps 75 s** through `PowerBook.mode_cooldown()`, which
  `Rules.cast()` already prefers — Ruling: no table key for it — DS: "its mode cooldown wins, as today" — cost if wrong: none.
- **D2 No Might in the tables** (Ruin R3): `PowerBook.might(key, level)` equals DS's Might column for all ten (a test proves it,
  and Voice 7 + Schism 8 = 15 at level 5, under the cap of 16).
- **D3 COMMAND_X.** `VoiceOfGodFx` gains `const COMMAND_X := 1.0`; the cast's `seconds = float(COMMANDS[command]) *
  lv_command_x` for every command. `COMMANDS` is unchanged.
- **D4 Whisper's REACH is read where the walk is clamped**: `Targeting.release()` (via `MindWhisperFx.clamp_to(grid, from, to,
  reach := REACH)`) and the aim line (`Targeting._whisper_line`), with `PowerBook.level_stat("whisper", _rules.level_of(slot),
  "REACH", MindWhisperFx.REACH)`. The effect itself never clamps (`extra.to` is already clamped) — Ruling — cost if wrong: a
  scripted level-5 whisper sent past 10 is not clamped by the effect, as today.
- **D5 Previews follow the level** (Ruin R5/R5a): `Targeting.AREA_STATS` gains `discord {"r": "DISCORD_R"}`, `madness {"r":
  "RADIUS"}`, `clearmind {"r": "RADIUS"}`, `anathema {"r": "RADIUS"}`, `sanctuary {"r": "PICK_R"}`; the preview's "who would be
  taken" ringing passes the level's numbers to the static helpers (`taken`, `victims_at`, `drawn` cap, `picked_at`, `marked_at`).
  Saint's `PICK_R`, Wisp's `RING`/`LURE_REACH`, Voice and Schism areas have no levelled stat and stay.
- **D6 STAT_LABELS** gain: `"whisper.REACH": "walk reach"`, `ATTACK_SECS "attack"`, `DISCORD_R "circle"`, `DISCORD_TIME
  "forgetting"`, `SEED "starting madness"`, `LURE_MAX "lure cap"`, `WISP_TIME "lure time"`, `ENTHRALL_TIME "enthrall"`,
  `TRANCE_TIME "trance"`, `SPAN "span"`, `MAX_GUARDS "guards"`, `PICK_R "guard reach"`, `"anathema.RADIUS": "district"`,
  `COMMAND_X "command length"`, `GATHER_CAPACITY "gather cap"`, `REGION "region"`, `MAX_FIGHTERS "fighters"`, `DURATION
  "length"`. (`RADIUS` "radius", `REACH` "reach", `cooldown` exist.) Ruin's tree text must not change (its tests pin it).
- **D7 Twist texts** (each under the tree's detail width, checked with `UiTheme.width` as Ruin did; the follow-up ones say
  "click again"): whisper "Held String: whisper the same one again", discord "Tangled Threads: forgetting spreads one hop",
  madness "Directed Frenzy: the broken hunt soldiers", wisp "Procession: click again to lead the light", clearmind "Forgetting:
  the trance wipes their fear", saint "Passed Mark: the mark outlives its bearer", sanctuary "Pressed into Service: intruders
  guard", anathema "Spreading Mark: spreads to buildings near", voice "Second Word: click again for a second command", schism
  "Turn the Tide: click a fighter to turn them". *(wording my call; shorten if a width check fails)*
- **D8 Held String** — Ruling: a level-5 whisper (walk, attack or burn) leaves **no shake-off** when it wears off: `Person._wake()`
  sets `_shaken_left = 0.0` instead of `SHAKE_OFF` for a person a level-5 whisper holds. Because `SHAKE_OFF` is 20 s, this is
  exactly "for 20 s after a whisper the not-the-same-one wait does not apply"; the 20 s counts from when the whisper wears off,
  not from the cast — why: a walk of 14 plus the 8 s linger outlasts 20 s from the cast, so a window from the cast would rarely
  ever be usable — cost if wrong: the twist is a little more generous than DS meant. Cooldown applies (it is a normal cast); "Might
  still applies" needs nothing (Might is the loadout's budget, not spent per cast). A later level 1-4 whisper on the same person
  clears the flag (its wake shakes as today).
- **D9 Tangled Threads.** For `TANGLE_TIME 5.0` s after the cast, every `TANGLE_EVERY 0.1` s: anyone alive, out in the open, not
  `resists_mind()`, not already touched by this cast, within `TANGLE_R 1.0` of a person this cast confused **who is still
  confused** (`mind == CONFUSED`) is confused for the **full** `lv_discord_time` (DS "same forgetting time") and recorded as
  caught; the caught pass nothing on. Soldiers too (as Discord). At level 5 `duration = TANGLE_TIME + 0.2`; `busy` stays 0.6.
- **D10 Directed Frenzy** — Ruling: a directed person who reaches Broken skips `_draw_outcome()` (no roll; **panic excluded too**:
  DS says "everyone ... goes into frenzy") and screams then frenzies as today; at the frenzy, `fight(soldier, FRENZY_DURATION,
  ATTACK_DAMAGE, FightRule.ANYONE, Person.FIGHT_SIGHT, &"madness")` on the nearest living soldier out in the open within
  `Person.FIGHT_SIGHT` (tie: field order), else `fight(null, ...)` as today; `_outbreak()` unchanged. Once that soldier is down the
  frenzy goes on under its ANYONE rule for the rest of its time. Only the cast's seeds are directed (spreads via `afflict()` are not).
- **D11 Procession.** `follow_up(at, _)` is true at level 5 while the light burns (`t < duration - 1.0`), any number of times,
  each replacing the destination. The light (`var light_at := origin`) drifts toward it at `PROCESSION_SPEED :=
  DummyEnemy.WALK_SPEED` (0.6 u/s, a walk), never past it. LURE: each lured person keeps its offset from the light (recorded at the
  lure) and is re-sent to `light_at + offset` (nearest walkable) every `REGOAL_EVERY 0.5` s while the light moves and once when it
  stops, via `Person.relure()`. ENTHRALL: `_spots` and `_held` shift with the light; a held person's `anchor` and goal follow (as
  Saint's `_ring()` moves its guards); newcomers are taken round `light_at` (`enthralled(field, light_at, ...)`, `_edge_spot`
  from `light_at`). Light, motes and the ENTHRALL ring draw at `light_at` (`FxParts.ground_light(..., getter)`). At levels 1-4
  `light_at == origin` throughout. `follow_up_area()` = `{"shape": "circle", "r": RING.y}`.
- **D12 Forgetting** — Ruling: at `T_CAST + lv_trance_time` (only if the trance runs its time; `end_now()` does not forget), each
  entranced person alive and not inside calls `Person.forget_fright()`: awareness to UNAWARE, `_threat` cleared, the flight it
  owes (`_whisper_fled`, `_reassured_fled`) dropped, and if PANIC/FLEE/REGROUP/RECOVER or OBSERVE-not-lured, back to its day with a
  fixed 1.0 s recover (no rng). DS's own call holds: the town's Notice and evacuation are not touched. See Questions Q1.
- **D13 Passed Mark (SINNER)** — Ruling: once, the first frame the chosen is dead: the mark goes to the nearest living person out
  in the open within `PASS_R 3.0` of where they fell who is **not one of the mob** (`people`) — why: the mob stands round the
  chosen, so the nearest is nearly always a hunter; a mob turning on its own is not the god's steer — cost if wrong: the jump lands
  on a bystander rather than a hunter. The new chosen wears the noose for what is left; every living mob member is set on them
  (`fight(new, left, ..., TARGET_ONLY, GUARD_SIGHT, &"sinner")`); `var passed_to: Person`. Nobody in reach: nothing.
- **D14 Passed Mark (SAINT)** — Ruling: "strikes" uses today's detection (a foe within `GUARD_R` fighting the chosen); the cap
  `GUARDS_PER_THREAT` is lifted to every guard not already fighting — cost if wrong: guards answer an intent, not a blow, as today.
- **D15 Pressed into Service** — Ruling: "driven out" is the moment a guard lets go because its quarry, alive, is outside the
  wall (today's `stop_fighting()` branch). That quarry, unless already a guard or `resists_mind()`, and while `guards.size() <
  lv_max_guards`, joins: appended to `guards` with a place on the wall nearest them (`static func wall_spot(kind, centre, g) ->
  Vector2`: circle `centre + dir * CIRCLE_R`; rect: the nearest point on the rect's border), `_post()`ed for what is left of the
  span, SHIELD badge, counted in `var pressed := 0`. Soldiers too. They fight later intruders as any guard.
- **D16 Spreading Mark** — Ruling: at `T_CAST + SPREAD_AT (20.0)` (20 s after the marks are laid): every standing building of a
  `MARKED` role, not already marked by this cast, whose footprint lies within `SPREAD_R 3.0` of an originally marked building's
  footprint (`m.footprint.grow(3.0).intersects(s.footprint)`) is marked for `T_CAST + lv_span - t`; appended to `buildings` (the
  shun and the shrouds cover them) and to `var spread: Array[Structure]`. Once; the spread ones do not spread. The Citadel's role is
  not in `MARKED` (assert it in a test). HALLOWED: citizens within `SPREAD_R` of a newly marked building are sent in as `_gather()`
  does (its code, restricted to the new buildings and those people).
- **D17 Second Word** — Ruling: `follow_up(at, extra)` is true at level 5, once per cast, while the first command holds
  (`T_SPEAK <= t < T_SPEAK + seconds`), with `extra.mode` (the Q/E command shown; default the first's); JUDGE needs someone at the
  click (`judged_at(field, at)`), else false. When the first ends, every person the first reached (`_reached`) alive and out in the
  open takes the second command at once (no wave), for `float(COMMANDS[second]) * lv_command_x`; its place is **the follow-up
  click** (FLEE runs from it, GATHER walks to it, JUDGE condemns the one picked there; RETURN, KNEEL, HALT, SILENCE need no place);
  SILENCE hushes the town for its seconds. No rng: a second GATHER sizes `spots_for()` to `mini(lv_gather_capacity, reached)` and
  any beyond stand at the place; a second FLEE from a person exactly on the click runs `Vector2.RIGHT`. `duration` becomes
  `T_SPEAK + seconds + seconds2 + 1.0`; `busy` unchanged. `follow_up_area()` = `{}` (the Voice's own preview, which rings the
  judged for JUDGE).
- **D18 Turn the Tide** — Ruling: `follow_up(at, _)` is true at level 5 while `T_BREAK <= t < T_BREAK + lv_duration`, mode not
  `"tumult"`, `turns < MAX_TURNS (10)`, and a member (`side != 0`, alive, not inside) stands within `TURN_PICK 1.0` of the click
  (the nearest; tie field order). It moves them to the other side through the same code as `_enlist()` (factored into
  `_lay_side(p, s, left)`; level 1 identical): counts, badge, fight re-laid (`OTHER_SIDE`) or, for PURGE, a citizen turned onto the
  condemned side runs and a condemned one turned back fights. `turns += 1`. `follow_up_area()` = `{"shape": "circle", "r":
  TURN_PICK}`.

## Questions for the user

- **Q1 Forgetting is nearly invisible as written.** Clear Mind already calms the frightened when it takes them, and they never pick
  the fright up again; during the trance nothing frightens them. So at the trance's end the only things left to forget are a
  hidden awareness level and a whispered person's owed flight. Build it as written (D12, the default), or make it stronger (for
  example: for 15 s after the trance they still sense nothing, so a cleared square stays calm while the god acts)? The plan builds
  D12 unless told otherwise; changing it later touches only Task 6.

---

## Rows that cast each power (for the per-task reference checks)

Found by grepping `tools/dev` for each key (`"discord"` etc.); a row's name says its route. Regexes for `refs_check.sh --only=`:
- **whisper, discord, wisp:** most mission plays cast them (route A and B policies in `behaviour_check.gd` and
  `routes/tier1-5_b.gd`, the god T1 routes `routes/god_t1/*`, the god hunts `routes/god_hunts/*`, the capital B rows) plus
  `warning_(whisper|discord|mix)`. Per task: seed 1 of every play row, in three runs (120 rows + the warning rows):
  `'^warning_|^[a-f].*_play_1$'`, `'^[g-k].*_play_1$'`, `'^[l-z].*_play_1$'`.
- **madness:** `'^(expel_inquisitor|silence_witness)_dominion_play_[0-9]+$|^judgement_b_play_[0-9]+$'`.
- **sanctuary:** `'^break_hunt_dominion_play_[0-9]+$'`.
- **voice:** `'^face_halcyon_dominion_play_[0-9]+$'`.
- **clearmind, saint, anathema, schism:** no route casts them: `digest` and `crowd_check` only.
- Always also `'^(digest|crowd_check)$'` (sequential and rendered: run it on its own).

## Task order and parallelism

| # | Task | Files (edit) | Track | Depends on |
|---|---|---|---|---|
| 1 | Groundwork: tables, stat reads, previews, follow-up mechanism, Person hooks, test files | `power_book.gd`, `rules.gd`, `targeting.gd`, `hud.gd`, `prepare_screen.gd`, `person.gd`, `ruin/tempest.gd`, the ten effect files (stat reads only), tests (below), `run_all.gd` | serial, first | -- |
| 2 | Mind Whisper: Held String | `src/fx/dominion/mind_whisper.gd`, `tests/test_dominion_twist_whisper.gd` | A | 1 |
| 3 | Discord: Tangled Threads | `src/fx/quiet/discord.gd`, `tests/test_dominion_twist_discord.gd` | A | 1 |
| 4 | Madness Bloom: Directed Frenzy | `src/fx/curse/madness_bloom.gd`, `src/game/crowd/madness_manager.gd`, `tests/test_dominion_twist_madness.gd` | A | 1 |
| 5 | Will-o'-Wisp: Procession | `src/fx/control/will_o_wisp.gd`, `tests/test_dominion_twist_wisp.gd` | B | 1 |
| 6 | Clear Mind: Forgetting | `src/fx/dominion/clear_mind.gd`, `tests/test_dominion_twist_clearmind.gd` | A | 1 |
| 7 | Saint or Sinner: Passed Mark | `src/fx/dominion/saint_or_sinner.gd`, `tests/test_dominion_twist_saint.gd` | C | 1 |
| 8 | Sacred Sanctuary: Pressed into Service | `src/fx/dominion/sacred_sanctuary.gd`, `tests/test_dominion_twist_sanctuary.gd` | C | 1 |
| 9 | Anathema: Spreading Mark | `src/fx/dominion/anathema.gd`, `tests/test_dominion_twist_anathema.gd` | C | 1 |
| 10 | Voice of God: Second Word (sonnet review) | `src/fx/dominion/voice_of_god.gd`, `tests/test_dominion_twist_voice.gd` | B | 1 |
| 11 | Divine Schism: Turn the Tide | `src/fx/dominion/divine_schism.gd`, `tests/test_dominion_twist_schism.gd` | B | 1 |
| 12 | Docs: summary and rulings | `docs/KAK_God_Dominion_Levels_Summary.md`, `docs/KAK_God_Dominion_Levels_Rulings.md` | serial, last | 2-11 |

Tasks 2-11 share no file: each owns its effect file and its own test file; `madness_manager.gd` belongs to Task 4 only. Everything
shared (`person.gd`, `rules.gd`, `targeting.gd`, `hud.gd`, `power_book.gd`, `run_all.gd`) is Task 1's. A twist task that finds it
needs a file outside its row stops and reports NEEDS_CONTEXT.

**Tracks** (as Ruin: three at once, each serial inside, cut from Task 1's commit, merged back into `god/dominion-levels`):
- **A** `god/dl-a`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-dl-a`: Tasks 2, 3, 4, 6 (Tier 1-3 crowd twists; the ref-heavy powers).
- **B** `god/dl-b`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-dl-b`: Tasks 5, 10, 11 (the three follow-up twists).
- **C** `god/dl-c`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-dl-c`: Tasks 7, 8, 9 (Tier 3-4 district twists).
First command in each fresh worktree: the `--import` line. While three tracks run: per-task checks only (no full refs, no FLOW);
`--jobs=2` for `refs_check.sh`; after a track's last task, the full suite in 6 parts.

---

### Task 1: Groundwork (sonnet; sonnet task review)

**PowerBook (`src/game/power_book.gd`)**
- [ ] Ten `levels` arrays (index 0 = level 1), values exactly DS (no Might key, D2):
  - whisper: `REACH` 10.0/11.0/12.0/13.0/14.0, `ATTACK_SECS` 10.0/11.0/12.0/13.0/14.0, `cooldown` 8.0/7.5/7.0/6.5/6.0
  - discord: `DISCORD_R` 1.2/1.3/1.4/1.5/1.6, `DISCORD_TIME` 15.0/16.0/17.0/18.0/20.0, `cooldown` 30.0/28.0/26.0/24.0/22.0
  - madness: `RADIUS` 1.5/1.65/1.8/1.95/2.1, `SEED` 0.02/0.04/0.06/0.08/0.10, `cooldown` 40.0/38.0/36.0/34.0/32.0
  - wisp: `LURE_MAX` 25/27/30/32/35 (int), `WISP_TIME` 12.0/13.0/14.0/15.0/16.0, `ENTHRALL_TIME` 30.0/32.0/34.0/37.0/40.0,
    `cooldown` 30.0/28.0/26.0/25.0/24.0 (ENTHRALL's 75 stays the mode's, D1)
  - clearmind: `RADIUS` 5.0/5.4/5.8/6.2/6.5, `TRANCE_TIME` 30.0/32.0/34.0/37.0/40.0, `cooldown` 60.0/57.0/54.0/51.0/48.0
  - saint: `RADIUS` 6.0/6.4/6.8/7.2/7.5, `SPAN` 30.0/32.0/34.0/37.0/40.0, `cooldown` 60.0/57.0/54.0/51.0/48.0
  - sanctuary: `MAX_GUARDS` 40/44/48/52/55 (int), `SPAN` 40.0/44.0/48.0/52.0/55.0, `PICK_R` 5.0/5.25/5.5/5.75/6.0,
    `cooldown` 90.0/86.0/82.0/78.0/74.0
  - anathema: `RADIUS` 6.0/6.4/6.8/7.2/7.5, `SPAN` 40.0/44.0/48.0/52.0/55.0, `cooldown` 90.0/86.0/82.0/78.0/74.0
  - voice: `COMMAND_X` 1.0/1.1/1.2/1.3/1.4, `GATHER_CAPACITY` 150/160/175/185/200 (int), `cooldown` 180.0/170.0/160.0/150.0/140.0
  - schism: `REGION` 14.0/15.0/16.0/17.0/18.0, `MAX_FIGHTERS` 140/150/160/170/180 (int), `DURATION` 25.0/27.0/29.0/32.0/35.0
    (no cooldown key, D1)
  - level 5 of each: `"twist": true`, `"twist_text"` (D7).
- [ ] `STAT_LABELS` additions (D6). `NO_LEVELS`' comment: "Ruin's and Dominion's powers have one".

**The follow-up mechanism** (see its section)
- [ ] `rules.gd`: `recast(slot, at, extra := {})` -> `fx.follow_up(at, extra)`; `can_recast()` -> `fx.can_follow_up()`;
  `func follow_up_area(slot: int) -> Dictionary`. Doc comments say "a live power's follow-up (Called Bolts, Procession, Second
  Word, Turn the Tide)".
- [ ] `ruin/tempest.gd`: `can_follow_up()` and `follow_up(at, _extra)` wrapping `can_call()` / `call_bolt()`.
- [ ] `targeting.gd`: `_aim_kind()` returns `"click"` while `slot >= 0 and _rules.can_recast(slot)`; `release()` passes its
  `extra` (the mode) to `_rules.recast(slot, _press, extra)`; `area()` returns `_rules.follow_up_area(slot)` when non-empty (and the
  per-power "who would be taken" ringing in `_draw()` is skipped then).
- [ ] `hud.gd` `_draw_slots()`: while `_rules.can_recast(i)` the card's frame is drawn picked (gold) and its cooldown seconds in
  `UiTheme.COL_GOLD` (Tempest's storm shows it too: Ruling, a visible cue only).
- [ ] `prepare_screen.gd` `_draw_power_card()`: at the drafted level 5 of a power with a twist, one more line in gold after the
  shape: `PowerBook.twist(key)` (wrapped like the shape).

**Person hooks (`src/game/crowd/person.gd`)** -- inert until a twist calls them; level 1 never does:
- [ ] `func hold_string() -> void` sets `_held_string := true`; `_wake()` sets `_shaken_left = 0.0 if _held_string else SHAKE_OFF`
  then clears the flag; a whisper laid without `hold_string()` clears it too (`whisper()` resets it; the level-5 caller sets it
  after). (D8)
- [ ] `func relure(spot: Vector2) -> bool`: only when alive, `mind == Mind.OBSERVE and _lured`: `_threat = spot`, `set_goal(spot)`;
  true. Nothing else changes (its `_observe_left` runs on). (D11)
- [ ] `func forget_fright() -> void` (D12): awareness UNAWARE, `_threat = Vector2.INF`, `_whisper_fled = false`, `_reassured_fled =
  false`; if mind in PANIC/FLEE/REGROUP/RECOVER, or OBSERVE and not `_lured`: `release_from_queue()`, `passing_gate = null`,
  `_recover(1.0)`.

**Stat reads -- every listed stat through `PowerBook.stat()`** (top of `_build()`; level 1 identical):
- [ ] `mind_whisper.gd`: `lv_attack_secs` (`_build_order`'s `whisper_fight`); `clamp_to(grid, from, to, reach := REACH)`.
  `targeting.gd`: the whisper release clamp and `_whisper_line`'s reach use the slot's level (D4).
- [ ] `discord.gd`: `lv_discord_r`, `lv_discord_time`; `taken(field, at, r := DISCORD_R)`.
- [ ] `madness_bloom.gd`: `lv_radius` (`victims_at(field, at, r := RADIUS)`, haze, light, motes), `lv_seed` (the status value).
  The manager reads the value off the person, so the SEED path needs nothing else.
- [ ] `will_o_wisp.gd`: `lv_lure_max` (`drawn(field, at, cap := LURE_MAX)`), `lv_wisp_time` (duration, `lv_wisp_time - 0.5` lure,
  emitter), `lv_enthrall_time` (duration, emitter; `_take()` reads `duration`).
- [ ] `clear_mind.gd`: `lv_radius` (`_join`, sigils, pulses, `Spiral` via `fx.lv_radius`), `lv_trance_time` (duration, `holding()`,
  `_join`'s left, ground sigil, `Spiral`'s end).
- [ ] `saint_or_sinner.gd`: `lv_radius` (`_decide`'s people, pulse, wave), `lv_span` (duration, badges, fights, `_ring`'s left).
- [ ] `sacred_sanctuary.gd`: `lv_max_guards`, `lv_pick_r` (`picked_at(field, at, r := PICK_R, cap := MAX_GUARDS)`, the pick sigil),
  `lv_span` (duration, `_post`, `_fx_process`'s end, `shown()`, `Ground` via `fx.lv_span`).
- [ ] `anathema.gd`: `lv_radius` (`marked_at(env, at, r := RADIUS)`, `_gather`, sigils, pulse, wave), `lv_span` (duration,
  `mark_structure`, `holding()`, `_gather`'s compel, icons, `shown()`, `Shroud` via `fx.lv_span`).
- [ ] `voice_of_god.gd`: `const COMMAND_X := 1.0`; `lv_command_x` (D3); `lv_gather_capacity` (`spots_for` count).
- [ ] `divine_schism.gd`: `lv_region` (`_near(..., REGION)` x3, `_panic_point`), `lv_max_fighters` (the four `slice`s),
  `lv_duration` (duration, `at(..., _end)`, `_enlist`/`_strike`/`_repick_panicked` lefts, the tumult and spreading gates).
- [ ] `targeting.gd`: `AREA_STATS` additions (D5); the `_draw()` ringing passes the level's numbers to `taken`, `victims_at`,
  `drawn` (cap), and wherever `picked_at` / `marked_at` are called.

**Tests**
- [ ] New `tests/test_dominion_levels.gd` (the Ruin `test_ruin_levels.gd` shape):
  - `_shapes`: each of the ten `has_levels()` and `levels_problems()` empty; stat keys exactly DS's (plus `twist`, `twist_text` at
    5); no Might key; `twist(key)` == D7's text and fits the tree's detail width.
  - `_level_one`: level 1 `==` the const with the same `typeof` for every stat (`LURE_MAX`, `MAX_GUARDS`, `GATHER_CAPACITY`,
    `MAX_FIGHTERS` are `TYPE_INT`; `COMMAND_X` is `1.0`); `PowerBook.cooldown(key, 1) == float(row.cooldown)` for all ten; every
    value at 1-5 equals DS (DS's tables typed again in the test); `cooldown("schism", 5) == 999.0`.
  - `_might`: `might(key, L)` equals DS's Might column for 10 x 5; `might("voice", 5) + might("schism", 5) == 15`.
  - `_cooldown_at_level`: Rules with whisper and wisp, `levels = {"whisper": 3, "wisp": 5}`: after a whisper cast
    `cooldown_left == 7.0`; a LURE wisp cast `cooldown_of == 24.0`; an ENTHRALL cast waits 75.0 at level 5 too.
  - `_cast_reads_level3` (headless contexts as the existing Dominion tests build them): Discord `lv_discord_r == 1.4` takes a person
    at 1.35 (not at level 1) and confuses for 17.0; Madness seeds `0.06` and takes a person at 1.7; Wisp `drawn(..., 30)` caps 30 of
    31 calm people; Clear Mind `duration == T_CAST + 34.0 + 0.5`; Saint `duration == T_CAST + 34.0 + 0.5` and a person at 6.6 from
    the chosen joins; Sanctuary picks 48 of 50 within 5.5; Anathema marks a house 6.6 away; Voice kneel `seconds == 12.0 * 1.2`;
    Schism `duration == T_BREAK + 29.0 + 0.5` and a person 15.5 away is enlisted (not at level 1); Whisper `lv_attack_secs == 12.0`.
  - `_twist_gate`: `twist_at({"level": 5}, k)` true and `{"level": 4}`, `{"level": 6}`, `{}` false for all ten.
  - `_previews`: `Targeting.area_at(k, 1) == Targeting.AREAS[k]` for the five; `area_at("discord", 5).r == 1.6`;
    `area_at("sanctuary", 3).r == 5.5`; `area_at("saint", 5) == AREAS.saint`; `MindWhisperFx.clamp_to(null, O, O + 20 * RIGHT)` is
    10 away and with `reach 14.0` 14 away.
  - `_tree_text`: `level_change("wisp", 3)` == `"lure cap 27 -> 30, lure time 13.0 -> 14.0, enthrall 32.0 -> 34.0, cooldown 28.0 ->
    26.0"` (the table's key order); `level_change("voice", 5)` ends with D7's voice text; `level_change("smite", 2)` unchanged.
  - `_person_hooks`: a whispered person with `hold_string()` is not `shaken()` after the whisper wears off; without it, shaken for
    20 s; `relure()` on a lured person moves its goal and is false for a calm one; `forget_fright()` takes a THREATENED fleeing
    person to UNAWARE and out of FLEE, and leaves a COMPELLED one alone.
- [ ] New `tests/test_follow_up.gd`: a stub `FxTimeline` script (in the test) with `can_follow_up`/`follow_up` and a Rules with a
  recording caster: `recast(slot, p, {"mode": "halt"})` hands the extra through, emits `recast_made`, leaves `cooldown_left` and
  `cast_made` untouched; false while another cast's busy lock holds or after `finished`; `follow_up_area(slot)` is the stub's;
  a real `Targeting` (as Ruin's fix wave did): a slot whose aim is "two clicks" aims as a click while `can_recast`, and a press +
  release reaches `recast` with the mode, not `cast`; HUD `slot_state` unchanged. Tempest's own suite still passes unchanged.
- [ ] New stubs `tests/test_dominion_twist_<key>.gd` for the ten keys (each `static func run(t) -> void` with one passing
  `t.check(true, "<key> twist: pending (Task N)")`), registered in `run_all.gd` next to `test_dominion_levels.gd` and
  `test_follow_up.gd`.
- [ ] Existing tests written against "only Ruin has tables": `test_power_levels._no_tables` -> "only Ruin's ten and Dominion's ten
  have a table"; `test_skill_tree` gains a Dominion spot whose level-5 line is the twist (Thornwall still reads `NO_LEVELS`).
- [ ] Import; focused suites; full suite in 6 parts `failures=0`; the **whole** reference set in `--only=` runs under 10 minutes
  each (e.g. `'^[a-f]'`, `'^[g-m]'`, `'^[n-s]'`, `'^[t-z]'`), all OK but the known `bread_play_3`; commit
  "feat: Dominion's ten powers have five levels -- tables, every stat read at its level, one way to give a live power an order".

Check (Task 1): `test_dominion_levels`, `test_follow_up`, `test_power_levels`, `test_ruin_levels`, `test_ruin_twist_tempest`,
`test_skill_tree`, and the ten effects' suites (`test_whisper`, `test_whisper_wheel`, `test_discord`, `test_madness`, `test_wisp`,
`test_wisp_enthrall`, `test_clear_mind`, `test_saint`, `test_sanctuary`, `test_anathema`, `test_voice`, `test_schism`,
`test_schism_tumult`, `test_dominion_tiers`); then the full suite and **all** references.

---

### Tasks 2-11: the twists (tracks A, B, C)

Each task: gate with `PowerBook.twist_at(extra, key)` first (store it once as `var _twist := false` in `_build()`); fill its stub
test file (RED first); focused suites; commit "feat: <Power> level 5 -- <Twist>". Every task's tests include: **level 4** = the
same setup at `{"level": 4}` shows nothing of the twist, and where the effect is headless, `ctx.rng.state` after a fixed time at
level 4 equals the value recorded on Task 1's commit (record it first, as a literal); the effect's existing suite still passes.
Per-task check line = the focused suites + `bash tools/dev/refs_check.sh --jobs=2 --only='^(digest|crowd_check)$'` + the power's
rows (the table above).

#### Task 2: Mind Whisper -- Held String (`mind_whisper.gd`; track A)
- Hook: `_build()` / `_build_order()`: when the whisper took and `_twist`, `_target.hold_string()` (D8). Nothing else.
- Tests (the `test_whisper` context, a Rules with the real caster): level 5 walk whisper on P; after it wears off `not P.shaken()`;
  after the 6.0 s cooldown `rules.cast()` on P is not refused and P is WHISPERED again; same at level 4: refused "shaken" with
  `refused_who == P`; level-5 attack order: after the fight P is not shaken; a level-5 whisper then a level-4 one: shaken after
  the second. Cooldown still runs at level 5 (`cooldown_left == 6.0` after the cast).
- Check: `test_dominion_twist_whisper`, `test_whisper`, `test_whisper_wheel`, `test_dominion_levels`; refs digest|crowd_check and
  the three seed-1 play runs.

#### Task 3: Discord -- Tangled Threads (`discord.gd`; track A)
- Hook: `_build()` keeps `var confused: Array[Person]` (today's `taken` list) and, at `_twist`, `duration = TANGLE_TIME + 0.2`;
  `_fx_process` scans every `TANGLE_EVERY` while `t < TANGLE_TIME` (D9); `var caught := {}`.
- Tests (headless): A at the click; B placed 0.8 from A at t = 2.0 is confused for 20.0 (level 5's time) and in `caught`; C placed
  0.8 from B (1.6 from A) at t = 3.0 is not (one hop); D placed 0.8 from A at t = 5.3 is not (window over); a soldier near A is
  caught; A recovered (no longer confused) passes nothing; level 4: B is not confused and `duration == 1.2`; `busy == 0.6` at both.
- Check: `test_dominion_twist_discord`, `test_discord`; refs digest|crowd_check and the three seed-1 play runs.

#### Task 4: Madness Bloom -- Directed Frenzy (`madness_bloom.gd`, `madness_manager.gd`; track A)
- `MadnessManager`: `var directed := {}` and `func direct(p: Person) -> void`; `_enter(BROKEN)`: a directed person takes
  `Outcome.FRENZY` without `_draw_outcome()`; `_frenzy(p)`: a directed one goes for the nearest soldier first (D10). Undirected
  people are untouched (same `_rng` draws as today). `_end(p)` / a death drops the entry.
- `MadnessBloomFx._build()`: at `_twist` and with `ctx.crowd != null and ctx.crowd.madness != null`, `direct(p)` each afflicted.
- Tests (the `test_madness` crowd context): six seeded at level 5, values forced to 0.89, stepped past Broken: all six
  `outcome == FRENZY`; after the scream each `fight_target` is the nearest soldier within FIGHT_SIGHT; with no soldier in sight,
  `fight_target == null` (as today); a person they spread it to (`afflict`) is not in `directed`; level 4: `directed` empty and the
  manager's rng state after the same steps equals Task 1's recorded value.
- Check: `test_dominion_twist_madness`, `test_madness`; refs digest|crowd_check and the madness rows.

#### Task 5: Will-o'-Wisp -- Procession (`will_o_wisp.gd`; track B)
- `can_follow_up()`, `follow_up(at, _)`, `follow_up_area()` (D11); `var light_at := origin`, `_dest`, `_offsets` (LURE, recorded
  at the lure only at level 5), `_regoal_in`. `_fx_process` moves the light before the ENTHRALL scan; `_draw`, `_light`, motes and
  the ring use `light_at`.
- Tests (headless): LURE level 5, three calm people drawn; `follow_up(origin + Vector2(4, 0), {})` true; after 3.0 s `light_at`
  is 1.8 east (± 0.05) and each lured person's goal is within 0.5 of `light_at + offset`; after 8 s the light stops at the spot and
  a lured person is within 1.0 of its new ring place; a second `follow_up` replaces the destination; after the light is out (or in
  its last second) false. ENTHRALL level 5: a held person's `anchor` moves with the light; a person standing near the new spot
  (and not near the old) is taken at the next scan. Level 4: `can_follow_up()` false, `light_at == origin`. Through Rules: a
  level-5 wisp cast then `rules.recast(slot, p)` true, `cooldown_left` unchanged, no second `cast_made`.
- Check: `test_dominion_twist_wisp`, `test_wisp`, `test_wisp_enthrall`, `test_follow_up`; refs digest|crowd_check and the three
  seed-1 play runs.

#### Task 6: Clear Mind -- Forgetting (`clear_mind.gd`; track A)
- Hook: `_build()` at `_twist`: `at(T_CAST + lv_trance_time, _forget)`; `_forget()` calls `forget_fright()` on each entranced
  person alive and not inside (D12); `var forgot := 0`.
- Tests: a THREATENED person in the circle and a whispered-while-fleeing one (owes flight): level 5, after the trance both are
  UNAWARE and neither flees; `forgot == 2`; `end_now()` before the end forgets nobody; level 4: awareness kept.
- Check: `test_dominion_twist_clearmind`, `test_clear_mind`; refs digest|crowd_check.

#### Task 7: Saint or Sinner -- Passed Mark (`saint_or_sinner.gd`; track C)
- SINNER: `_fx_process` gains a sinner branch (before today's `mode != "saint"` return) that runs the pass once (D13);
  `var passed_to: Person`. SAINT: `_guard()`'s cap is `people.size()` at `_twist` (D14). Links/badges follow the new chosen (staged).
- Tests (the `test_saint` context): SINNER level 5, mob of four, bystander B 2.0 from the chosen, C 3.5 away: kill the chosen ->
  `passed_to == B`, B wears the noose, every living mob member's `fight_target == B`; kill B -> no second pass; nobody within 3 ->
  `passed_to == null`; level 4 -> no pass. SAINT level 5: six guards, one attacker fighting the chosen -> all six (not fighting)
  set on him at the next RETHINK; level 4 -> 3.
- Check: `test_dominion_twist_saint`, `test_saint`; refs digest|crowd_check.

#### Task 8: Sacred Sanctuary -- Pressed into Service (`sacred_sanctuary.gd`; track C)
- Hook: `_fx_process`'s let-go branch (D15); `static func wall_spot(kind, centre, g) -> Vector2`; `var pressed := 0`.
- Tests: circle, level 5, four guards; an intruder inside is set on; moved outside -> at the next RETHINK it is in `guards`,
  COMPELLED within 0.5 of `wall_spot(...)`, wearing SHIELD; a soldier intruder too; with `guards.size() == lv_max_guards` it is not
  taken; rect: the post is on the rect's border; level 4: the intruder is not a guard. `wall_spot` unit cases for both shapes.
- Check: `test_dominion_twist_sanctuary`, `test_sanctuary`; refs digest|crowd_check and the sanctuary rows.

#### Task 9: Anathema -- Spreading Mark (`anathema.gd`; track C)
- Hook: `_build()` at `_twist`: `at(T_CAST + SPREAD_AT, _spread)` (D16); `var spread: Array[Structure]`.
- Tests (crowd + env with houses): house A within the district, B outside it 2.5 from A, C 3.5 from A, D within 3 of B only, and
  a Citadel within 3 of A: at `T_CAST + 19.9` B is unmarked; at `T_CAST + 20.1` B is marked (CURSED) until `T_CAST + lv_span`, C, D
  and the Citadel are not; HALLOWED: a citizen 1.0 from B is sent in at the spread; level 4: nothing spreads.
- Check: `test_dominion_twist_anathema`, `test_anathema`; refs digest|crowd_check.

#### Task 10: Voice of God -- Second Word (`voice_of_god.gd`; track B; sonnet review)
- Refactor `_command(p)` into `_command(p, cmd, place, secs, t0)` (level 1: the first command calls it with today's values, same
  call order); `can_follow_up()`, `follow_up(at, extra)` (D17); `var second := ""`, `second_at`, `_second_done`; `_fx_process`
  applies the second when `t >= T_SPEAK + seconds`.
- Tests (headless, the `test_voice` context): level 5 KNEEL (seconds 16.8): before `T_SPEAK` `follow_up` false; at `T_SPEAK + 3.0`
  `follow_up(p, {"mode": "halt"})` true, a second call false; at `T_SPEAK + 16.9` the reached are COMPELLED with no kneel pose,
  holding for 16.8 s; `duration == T_SPEAK + 33.6 + 1.0`; a second GATHER walks the reached to the follow-up's place (each goal
  within the place's spots); a second JUDGE with nobody near the click is false; a person the first never reached (inside) is not
  touched; level 4: `can_follow_up()` false. Through Rules + Targeting: with the Voice slot focused and Q/E on HALT, a click during
  the KNEEL is the second word (`recast_made`, no `cast_made`, cooldown untouched).
- Check: `test_dominion_twist_voice`, `test_voice`, `test_voices`, `test_follow_up`; refs digest|crowd_check and the voice rows.

#### Task 11: Divine Schism -- Turn the Tide (`divine_schism.gd`; track B)
- Refactor `_enlist()` into `_enlist()` + `_lay_side(p, s, left)` (level 1 identical); `can_follow_up()`, `follow_up(at, _)`,
  `follow_up_area()` (D18); `var turns := 0`.
- Tests (headless, `test_schism`'s context): FACTION level 5 after the wave: `follow_up` on a citizen (side 1) -> side 2, `counts`
  moved by one each way, crimson badge, fighting OTHER_SIDE; a click 1.5 from any member false; ten turns true, the eleventh false;
  before `T_BREAK` and after `T_BREAK + lv_duration` false; PURGE: a turned condemned citizen fights, a turned hunter citizen runs;
  TUMULT: `can_follow_up()` false; level 4: false. CUSTOM through Targeting: the focused Schism slot aims as a click while live.
- Check: `test_dominion_twist_schism`, `test_schism`, `test_schism_tumult`, `test_follow_up`; refs digest|crowd_check.

After each track's last task: full suite in 6 parts `failures=0` in the track's worktree; the controller merges the track into
`god/dominion-levels` (`git show --cc` shows no conflict hunk: the file sets are disjoint).

---

### Task 12: Docs (sonnet; no review)
- [ ] `docs/KAK_God_Dominion_Levels_Summary.md` (short, as Ruin's): what levels do, the ten tables (stat names with the D6 words),
  the ten twists one line each, **the follow-up input** (select the slot again, click; the gold card), how to try them (the
  board's Prepare level picker; `behaviour_check --level=5`), what stays level-free (directors, routes), the test files, commits.
- [ ] `docs/KAK_God_Dominion_Levels_Rulings.md`: D1-D18, Q1's answer, every `Ruling:` the task reports gave (with its task), the
  final review's and fix wave's rulings, the open and playtest notes.
- [ ] Update the Dev Ledger after landing (memory `kak-dev-ledger`); commit "docs: Dominion ability levels summary and rulings".

## Landing checks (after all tracks are merged and the final review's fix wave)
- Import; full suite in 6 parts, six `failures=0`.
- **All references**: `bash tools/dev/refs_check.sh` in `--only=` runs under 10 minutes each -> every row OK but the pre-existing
  `bread_play_3` (`-133947279`); `digest 61267b7e90524d800bf1c3473a71146b`, `crowd_check -935602679` unchanged; no row re-recorded.
- **FLOW alone** on a quiet machine (no other Godot running; `bash tools/dev/land.sh` waits for one) -> `209/0`.
- Landing target: `feat/god-progression` (where Ruin's levels landed), with memory `check-before-every-merge`; never push from a task.

## Review focus (milestone review, opus)
1. Level 1 is today, bit for bit: the whole reference set, `_level_one`, the rng-state literals in Tasks 2-11, and no caller of a
   static helper outside Targeting passes a level.
2. Every DS number is in its table and read at its level: `_shapes`, `_cast_reads_level3`, `_cooldown_at_level`, `_previews`,
   ENTHRALL still 75 s, Schism still once.
3. One follow-up mechanism, not four: Wisp, Voice and Schism go through `Rules.recast` exactly as Tempest does; a follow-up never
   starts a cooldown, never sends `cast_made`, is refused under another power's busy lock and after the run; the aim-as-click switch
   cannot strand a half-placed two-click aim; the HUD cue and the preview tell the player.
4. Each twist runs at 5 and never at 4; no twist draws a random number; quiet powers stay quiet (no `Crowd.on_cast`, no fright
   from the twist itself).
5. Person hooks are inert unless called (`hold_string`, `relure`, `forget_fright`), and `shaken()` is unchanged for everyone else.
