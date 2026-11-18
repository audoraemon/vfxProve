# KAK Death and Decree Ability Levels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md`
> (sonnet implementers; a sonnet task review for Task 1 and the follow-up twists). **No full code in this plan**: it gives
> interfaces, files, numbers and test cases; the implementer writes the code.

**Goal:** five levels for each of the ten Death and ten Decree powers, every stat read at its level, and twenty level-5 twists;
level 1 plays exactly as today.

**Architecture:** the level framework is in (Ruin, Dominion, Passage): `PowerBook` `levels` tables, `stat()`, `twist_at()`,
`level_change()`, `STAT_LABELS`, `levels_problems()`, `Rules.cast()` putting `extra["level"]` on every cast, the follow-up input
(`Rules.recast()`, `can_follow_up()` / `follow_up()` / `follow_up_area()`, the order wheel `follow_up_wheel()` /
`follow_up_subject()` / `follow_up_orders()` that Walking Corpse uses), `Targeting.AREA_STATS` / `area_at()`. This plan adds:
1. **Task 1 (groundwork):** the twenty tables; every listed stat through `PowerBook.stat()`; previews; the few shared hooks the
   twists call (inert at level 1); the bench aid's `--bench-level`; every new test file registered once.
2. **Tasks 2-21:** one twist each, in its own effect file, behind the level-5 gate, in three parallel tracks.
3. **Task 22:** docs.

**Tech Stack:** Godot 4.7.2 GDScript; suite `tests/run_all.gd` (+ `tests/run_part.gd`); references `tools/dev/refs_check.sh`;
bench `--bench-cast=KEY` in `src/game/mission.gd`.

**Spec:** `docs/superpowers/specs/2026-11-16-kak-death-decree-ability-levels-design.md` (approved 2026-11-17; cited **DS**). Model:
the Dominion plan `docs/superpowers/plans/2026-11-09-kak-dominion-ability-levels.md` and its rulings
`docs/KAK_God_Dominion_Levels_Rulings.md`; Death's shipped numbers are `docs/KAK_God_Death_Review_Rulings.md` (R28-R49).

## Global Constraints

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-ddl`, branch `god/dd-levels` (cut from `feat/god-progression` `76c03af1`). Tracks
  run in their own worktrees (see "Task order"). Every command from the worktree root; never touch another worktree. Each command
  under `timeout`, each under 10 minutes; longer runs in the background.
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
- One suite (`X` = the file's name without `test_` and `.gd`):
  `L=$(grep -o 'res://tests/test_[a-z0-9_]*\.gd' tests/run_all.gd); N=$(echo "$L"|wc -l); I=$(echo "$L"|grep -n "/test_X.gd"|cut -d: -f1); timeout 600 $G --headless --path . --script res://tests/run_part.gd -- --part=$I --of=$N 2>&1 | grep -E "SCRIPT ERROR|FAIL|failures="`
  Always grep for `SCRIPT ERROR`: a parse error hangs run_part with no `failures=`.
- Full gate: 4 parallel `run_part.gd --part=N --of=4` -> four `failures=0`; then crowd_check with `--fixed-fps 60` on its own.
- After adding a `class_name` or a test file, and first in every fresh worktree: `timeout 900 $G --headless --editor --path . --import`.
- **Only Task 1 edits `tests/run_all.gd`, `src/game/power_book.gd`, `src/game/targeting.gd`, `src/game/crowd/person.gd`,
  `src/game/crowd/crowd.gd`, `src/game/crowd/plague_manager.gd`, `src/game/crowd/remains.gd`, `src/game/mission.gd`.** A twist task
  that needs one of them stops and reports NEEDS_CONTEXT.
- **Level 1 moves nothing.** Expected base (do not re-record any row): suite `failures=0`; all 546 rows of `tools/dev/refs/*.tsv`
  OK through `refs_check.sh`, with `digest 61267b7e90524d800bf1c3473a71146b` and `crowd_check -535548941`; FLOW `209/0` alone on a
  quiet machine. A row showing `?` timed out under load: rerun it alone before calling it a failure.
- **Level-1 exactness:** a table's level-1 value equals the const and keeps its type (`MOST`, `CHAIN`, `INFECT_MAX`, `SPIRITS`,
  `KILLS_MOST`, `MAX_NAMED`, `GAWKERS`, `HORDE_KILLS`, `GIANT_BLOWS`, `WRAITH_TOUCHES` are `int`; every other stat is float:
  `RADIUS 3.0`, `HOLD_TIME 15.0`, `COUNTDOWN 30.0`, `cooldown 20.0` ...). A static helper that reads a levelled const gains a
  trailing parameter defaulted to the const; directors, routes and `behaviour_check` keep calling it without one. Derived numbers
  use today's expression. Consts stay; the effect reads `lv_<const in lower case>` set at the top of `_build()` (new names within
  their file).
- **Twist gate:** `var _twist := PowerBook.twist_at(extra, "<key>")` once in `_build()`, tested before any `ctx.rng` call, `at()`
  scheduling or field/crowd call the twist adds, so a level 1-4 cast draws the same numbers and schedules the same events.
- **No twist draws a random number** (DS anti-goal): ties by distance, then instance id.
- **Quiet powers stay quiet:** a twist of a `quiet` power adds no `Crowd.on_cast`, alarm or fright of its own (Death Mark, Pestilence,
  Corpse Guise, Walking Corpse, Leaving Is Prohibited, Redefine, Bound in Law, Sealed Verdict).
- **The faithful** are `ctx.rules.director.faithful` (null-safe: no rules or no director = nobody is faithful).
- **Frame budgets** (DS notes; Death rulings R13/R47): at level 5 with the twist firing, Gate Below, Pale Reign and the Serpent
  within a cast/base `avg_ms` ratio of 1.55 and Grave Tide within 1.9 (back-to-back pairs, `--bench-cast=KEY --bench-level=5`);
  `test_gravetide`'s `PERF_MS 8.0` and `test_pale`'s `5.0` hold at level 5 too. Over budget: cut the twist's drawing first, then its
  growth, never level 1.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never `git stash` (WIP commit). Never push from a
  task. No PixelLab: twist visuals reuse the power's own parts (`DeathParts`, `DecreeParts`, `FxParts`, the effect's inner classes).
  Every `Ruling:` an implementer makes goes in its report.

## Review Focus

1. **A twist spawn at the cap.** Scattered Bones with the tide's pack at `LIVING_CAP 60`, Swelling Host past its 4, Graves Answer
   with 30 bodies in reach: nothing rises past its cap, nothing errors, the frame budget holds. (Tests in Tasks 9, 11, 14.)
2. **A twist's subject freed mid-twist.** A person who dies, goes indoors or is freed while carried by Dragged Cage, joined to a
   bond, named by Precedent, held by And None May Leave or listed in the Ledger: skipped, no crash, no leak at the effect's end.
   (Tests in Tasks 13, 15, 17, 20, 21.)
3. **Torn down at level 5.** Every twist effect freed early (`queue_free` mid-run, as `test_*` teardown checks do today) leaves no
   pace hold, LawZone, LawMark, carried law, plague source or visitor behind. (One teardown check in every twist task.)
4. **Two casts of the same power.** A level-5 cast while an earlier level-5 cast of the same power still runs (Raise, Gravecall,
   Pestilence, Disorder): each twist keeps its own list and owner id; neither lifts the other's laws. (Tests in Tasks 3, 4, 5, 17.)
5. **The faithful.** Held for Trial never names one; every other twist treats them as its power does (DS calls). (Tests in Task 12
   and Task 21.)

---

## Shared hooks (decided here; built in Task 1, inert until a twist calls them)

- **Foul plague source (Foul Dead).** `Person.plague_src: int = 0`. `PlagueManager._spread()` sets `q.plague_src = p.plague_src`
  when it infects `q` (after its rng draw, so draws do not move). `PlagueManager.foul := {}` (source id -> true) and
  `func foul_from(src: int) -> void`. On a plague death (`_field.kill(p, &"plague")` true) with `foul.has(p.plague_src)`:
  `foul_spots.append({"pos": p.ground_pos, "left": 15.0, "most": 3})`; `step()` ages them and, each `SCAN_EVERY`, infects the
  nearest healthy people out of doors within 1.2 of a spot (`infect(PLAGUE_LIFE)`, `plague_src` copied, the spot's `most` counted
  down; no rng). `draw_ground()` draws a spot as Pestilence's miasma ring. With `foul` empty nothing changes.
- **Carried law (Bad Counsel).** `Person.carried_laws := {}` (kind -> seconds left), stepped down in `Person` each frame and erased
  at 0. `Crowd.in_law(p, kind)` is also true while `p.carried_laws.get(kind, 0.0) > 0.0` (a Person only; visitors unchanged).
  `law_of()` is unchanged (it returns a zone; callers that need the zone do not change).
- **Struck-by memory (Party to the Bond).** `Person.struck_by: WeakRef = null` and `struck_at := -1.0`, set in `hurt(amount, by)`
  when `by != null` (`struck_at` from the crowd clock). Read only by Bound in Law's twist.
- **A no-body kill (Borrowed Life).** Kill kind `&"borrowed"`: not in `Remains.BODY_KINDS`; added to `DeathVoices.QUIET_KINDS`;
  `Crowd._on_killed` returns for it where it returns for `&"grave"` (R14), so no alarm, nobody stirs; it counts as a death as
  `&"grave"` does. `Remains.Remain.design` may be rewritten by its owner (a doc comment says so).
- **The deathless fall (Deathless).** `Person.deathless: Callable` (default empty). In `Person.die(kind, from)` (and the field's
  kill path that calls it), when `deathless.is_valid()` and `deathless.call(self, kind)` returns true, the death is cancelled: the
  person is knocked down where they stand and nothing else happens (no kill counted, no remain, no alarm). Corpse Guise sets it on
  each guised person at level 5 and clears it in `_lift` / `_release`. Kinds it never catches: `&"pit"`, `&"gone"` (taken whole).
- **Bench level.** `mission.gd` `_bench_cast()`: `--bench-level=N` (default 1) sets the cast power's level in `_rules.levels`
  before the cast.

## Rulings (binding; DL1-DL14)

- **DL1** No Might column in the tables: Might is `PowerBook.might()`. Tier 5 rows have no `cooldown` key (once a descent).
- **DL2** Pestilence's Foul Dead counts only deaths whose infection traces to a level-5 cast (`plague_src` = that cast's instance
  id); a sick person from another cast's line is not foul. Spots never chain foulness by themselves: a spot's victim carries the
  same `plague_src`, so it is foul in turn (DS: "everyone the plague spread to from them").
- **DL3** The Wake raises a `DeathParts.zombie()` from the Death Mark body's remain at Raise's level-1 numbers
  (`RaiseTheDeadFx.ZOMBIE_LIFE`, `CHAIN` 3 counted for this cast alone), plague-carrying when the body was sick. The remain is taken
  (`Remains.take()`). "First gawker reaches it" = the first person who stops to look (DeathMarkFx's gawker list) within
  `PICK_R` 1.0 of the body.
- **DL4** Body and Soul applies to the ring's own bodies only; chain risers give no spirit (DS). A spirit's body that is gone
  (taken by another power) raises no zombie.
- **DL5** Swelling Host's wraiths are `DeathParts.haunt()` wraiths (Gravecall's own), at most 4 per cast, rising at the body.
- **DL6** Deathless: once per guised person per cast; the fall is `knock_down()` and a 5.0 s `hold_pace(id, 0.0)`; then full health,
  the guise renewed to `t + 10.0` for that person (the effect's `duration` grows to cover it).
- **DL7** Borrowed Life swaps the walker's look to the victim's (`design`, facing kept) and writes the same `design` into the
  walker's remain, so it lies down as the last victim.
- **DL8** Graves Answer: the 8 nearest remains within 12.0 of the rift that are not hidden and not taken; each grabs once, the nearest
  living person out of doors within 1.5, by the rift's own drag (`DRAG`, kill `&"pit"`), and the remain is taken; each taken one is
  a soul for the close (R35 sectors count it).
- **DL9** The Pall Grows changes `lv_radius` live; everything that reads the district radius each frame (crawl, douse, ghosts' bounds,
  draw) reads the grown one; the cast's danger (`Crowd.on_cast`) keeps the cast-time radius.
- **DL10** Shed Skin: the band is the path's sample points (`STEP` apart), each a 0.5 half-width hit test; drawn with the Serpent's
  disc texture, one draw per point, faded over its last 3 s.
- **DL11** Scattered Bones: `DeathParts.skeleton()` x 18 (bones count), life 20.0, in the tide's pack under `LIVING_CAP`; their kills
  are flagged not to rise (the tide's own on-kill rise skips them).
- **DL12** Further Claim and Dragged Cage and Precedent are plain-click follow-ups; Third Clause uses the order wheel with the fence's
  centre sigil as `follow_up_subject()` and the three unused rule words as `follow_up_orders()`. A follow-up never starts a cooldown
  (the existing rule). Further Claim: the strip runs from the first strip's end toward the click, `min(6.0, distance)` long (a
  click under 1.0 away is refused).
- **DL13** Party to the Bond: a joiner is the `struck_by` of a bound person, struck within the last frame, alive, not already bound,
  2 joiners per cast; a seizer joins when `director.seizer_of(p)` exists (else seizures add no one). Stuns carry no source and add no
  one (Ruling against DS's "stuns": no source exists).
- **DL14** The Ledger Remembers lists every person whose `ground_pos` was inside the district at any step of the countdown (one
  frame counts); at the bell each listed one alive dies `&"verdict"` wherever they are, indoors too.

## Task order and parallelism

| # | Task | Owns | Track |
|---|---|---|---|
| 1 | Groundwork | the shared files above, the 20 effect files (stat reads only), level tests, stubs | serial, first |
| 2 | Death Mark: The Wake | `death/death_mark.gd`, `tests/test_death_twist_deathmark.gd` | A |
| 3 | Raise the Dead: Body and Soul | `death/raise_the_dead.gd`, `tests/test_death_twist_raise.gd` | A |
| 4 | Pestilence: Foul Dead | `curse/pestilence.gd`, `tests/test_death_twist_pestilence.gd` | A |
| 5 | Gravecall: Swelling Host | `death/gravecall.gd`, `tests/test_death_twist_gravecall.gd` | A |
| 6 | Corpse Guise: Deathless | `death/corpse_guise.gd`, `tests/test_death_twist_guise.gd` | A |
| 7 | Walking Corpse: Borrowed Life | `death/walking_corpse.gd`, `tests/test_death_twist_walker.gd` | A |
| 8 | The Gate Below: Graves Answer | `death/the_gate_below.gd`, `tests/test_death_twist_gatebelow.gd` | B |
| 9 | Pale Reign: The Pall Grows | `death/pale_reign.gd`, `tests/test_death_twist_pale.gd` | B |
| 10 | The Pale Serpent: Shed Skin | `death/pale_serpent.gd`, `tests/test_death_twist_serpent.gd` | B |
| 11 | Grave Tide: Scattered Bones | `death/grave_tide.gd`, `tests/test_death_twist_gravetide.gd` | B |
| 12 | Leaving Is Prohibited: Held for Trial | `decree/leaving_is_prohibited.gd`, `tests/test_decree_twist_noleave.gd` | C |
| 13 | Breathing Is Prohibited: And None May Leave | `decree/breathing_is_prohibited.gd`, `tests/test_decree_twist_breath.gd` | C |
| 14 | Redefine: Precedent | `decree/redefine.gd`, `tests/test_decree_twist_redefine.gd` | C |
| 15 | Bound in Law: Party to the Bond | `decree/bound_in_law.gd`, `tests/test_decree_twist_bound.gd` | C |
| 16 | Erasing Distance: Shortcut | `decree/erasing_distance.gd`, `tests/test_decree_twist_erase.gd` | C |
| 17 | Disorder: Bad Counsel | `decree/disorder.gd`, `tests/test_decree_twist_disorder.gd` | C |
| 18 | Eminent Domain: Further Claim | `decree/eminent_domain.gd`, `tests/test_decree_twist_eminent.gd` | C |
| 19 | Fenced Rule: Third Clause | `decree/fenced_rule.gd`, `tests/test_decree_twist_fenced.gd` | C |
| 20 | The Closing Cage: Dragged Cage | `decree/the_closing_cage.gd`, `tests/test_decree_twist_cage.gd` | B |
| 21 | The Sealed Verdict: The Ledger Remembers | `decree/the_sealed_verdict.gd`, `tests/test_decree_twist_sealed.gd` | B |
| 22 | Docs | `docs/KAK_God_Death_Decree_Levels_Summary.md`, `..._Rulings.md` | serial, last |

Tasks 2-21 share no file. **Tracks**, each serial inside, cut from Task 1's commit, merged back into `god/dd-levels`:
- **A** `god/ddl-a`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-ddl-a`: Tasks 2-7 (Death Tiers 1-3).
- **B** `god/ddl-b`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-ddl-b`: Tasks 8-11, 20, 21 (the Tier 4-5 set; the benches).
- **C** `god/ddl-c`, worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-ddl-c`: Tasks 12-19 (Decree Tiers 1-4; the follow-ups).
While tracks run: per-task checks only, `refs_check.sh --jobs=2`; no FLOW, no bench (benches run after the merge, Landing).

**Rows per task** (`refs_check.sh --only=`): Death tasks `'death'`; Decree tasks `'decree'` (33 rows each); every task also
`'^(digest|crowd_check)$'` on its own. Task 2 and Task 4 also `'^[a-m].*_play_1$'` and `'^[n-z].*_play_1$'` (Death Mark and
Pestilence are cast by the tier routes); Tasks 12 and 13 the same (`noleave`, `breath` are in the god T1 routes).

---

### Task 1: Groundwork (sonnet; sonnet task review)

**Files:** Modify `src/game/power_book.gd`, `src/game/targeting.gd`, `src/game/crowd/person.gd`, `src/game/crowd/crowd.gd`,
`src/game/crowd/plague_manager.gd`, `src/game/crowd/remains.gd`, `src/game/crowd/death_voices.gd` (wherever `QUIET_KINDS` lives),
`src/game/mission.gd`, the twenty effect files (stat reads only), `tests/test_power_levels.gd`, `tests/run_all.gd`. Create
`tests/test_death_levels.gd`, `tests/test_decree_levels.gd`, `tests/test_dd_hooks.gd`, and the twenty `test_*_twist_*.gd` stubs.

**Interfaces produced:** the twenty tables; `lv_*` fields named below; the shared hooks (section above) with those exact names;
`--bench-level=N`.

- [ ] **Step 1: Tables.** Twenty `levels` arrays in `PowerBook.POWERS`, values exactly DS's tables (index 0 = level 1), keys in DS's
  column order, `cooldown` from the `cd` column (absent for `serpent`, `gravetide`, `cage`, `sealed`), level 5 with `"twist": true`
  and `"twist_text"` = DS's twist sentence shortened to the tree's detail width (the test checks the fit). Gate Below's table carries
  `EDGE` too (DS's column). `STAT_LABELS` gains a label for every new stat name (e.g. `MARK_TIME` "death in", `GAWKERS` "gawkers",
  `LOOK_R` "drawn from", `ZOMBIE_LIFE` "zombie time", `CHAIN` "chain", `SPIRIT_LIFE` "spirit time", `INFECT_MAX` "infected",
  `INFECT_R` "reach", `SPIRITS` "wraiths", `HAUNT` "haunt", `FREEZE` "freeze", `MOST` "hidden", `MARK_R` "reach", `SPAN` "time",
  `WALK_LIFE` "walk time", `KILLS_MOST` "kills", `ATTACK_R` "attack reach", `EDGE` "rift", `WRAITH_TOUCHES` "wraith touches",
  `HORDE_KILLS` "kills", `BAND` "shadow", `SIGHT` "seen from", `SICK` "sickness", `GIANT_LIFE` "giant time", `GIANT_BLOWS`
  "giant blows", `SLAM_R` "slam", `SLAM_WRECK` "slam on walls", `HOLD_TIME` "hold", `MAX_NAMED` "named", `MAX_LEN` "line",
  `CRUSH_W` "crush", `THROW_W` "throw", `HALF_W` "width", `CLOSE_TIME` "closes in", `COUNTDOWN` "bell in"); reuse an existing
  key's label where the same name is already labelled. Where two powers share a name with different meaning, use the
  `"<key>.<STAT>"` label form already in the table (`cinder.RADIUS`).
- [ ] **Step 2: Stat reads.** Each effect reads its DS stats into `lv_*` at the top of `_build()` via
  `PowerBook.stat(extra, key, "<STAT>", CONST)` and uses them wherever the const sized this cast (durations, radii, counts, schedule
  times). Static helpers that read a levelled const (`CorpseGuiseFx.marked_at`, `PestilenceFx.victims_at`, `DeathMarkFx.target_at`
  if it reads one, Raise's ring pick, Bound's `pair_at` / `refusal` (`REACH`), the Decree preview helpers) gain a trailing parameter
  defaulted to the const. Gate Below: `lv_edge` from the table (not derived), so level 1 stays `4.2` exactly. Grave Tide: only the
  giant's four stats. Pale: `HORDE_KILLS` stat; `HORDE_CAP`, `MAX_RISEN` untouched.
- [ ] **Step 3: Previews.** `Targeting.AREA_STATS` gains each power's area stat (`RADIUS`, `REACH`, `LENGTH`/`MAX_LEN`, `MARK_R`,
  `INFECT_R` ...) as the existing rows do; `area_at(key, 1) == AREAS[key]` for all twenty.
- [ ] **Step 4: Shared hooks** exactly as the section above. Each is inert unless a level-5 twist calls it.
- [ ] **Step 5: Tests.**
  - `test_death_levels.gd` / `test_decree_levels.gd` (the `test_dominion_levels.gd` shape): `_shapes` (has_levels, no
    `levels_problems()`, keys exactly DS's plus twist keys at 5, no Might key, twist text fits); `_level_one` (level 1 `==` const,
    same `typeof`, all twenty; `cooldown(key, 1) == row.cooldown`); every value at 1-5 equals DS (tables typed again in the test);
    `_might` (`might(k, L)` = DS's Might column; `might("serpent",5) + might("gravetide",5) == 16`,
    `might("cage",5) + might("sealed",5) == 16`); `_cast_reads_level3` per power with a headless context, one number each that
    differs from level 1 (e.g. Raise `lv_chain == 4`, Gate `lv_edge == 4.55`, Pale `lv_horde_kills == 28`, Erase `lv_max_len ==
    11.0`, Cage `lv_close_time == 28.0`, Sealed `lv_countdown == 28.0`); `_twist_gate` (`twist_at` true only at 5); `_previews`.
  - `test_dd_hooks.gd`: foul source spreads by copy, a foul death lays a spot that infects at most 3 within 1.2 and none at 1.3,
    a non-foul death lays none, rng state after 10 s of plague steps equals a run with `foul` empty; a carried DISORDER makes
    `in_law` true for 8 s and false after; `hurt(x, by)` sets `struck_by`; a `&"borrowed"` kill leaves no remain, raises no alarm
    and counts in `killed_citizens`; a `deathless` callable that returns true leaves the person alive and down, false lets the
    death happen, an empty one changes nothing; `--bench-level` parses.
  - `test_power_levels._no_tables`: the list gains the twenty keys; message "only Ruin's, Dominion's, Passage's, Death's and Decree's
    have a table". `test_tree_detail` / `test_skill_tree`: a Death spot's level-5 line is its twist.
  - Twenty stubs `static func run(t) -> void: t.check(true, "<key> twist: pending (Task N)")`, all registered in `run_all.gd`
    with the three test files above.
- [ ] **Step 6: Verify.** Import; the new suites and every Death/Decree effect suite (`test_death_*`, `test_decree*`, `test_raise*`,
  `test_gatebelow`, `test_gravecall`, `test_gravetide`, `test_guise`, `test_pale`, `test_serpent`, `test_walker`, `test_law_*`,
  `test_power_levels`, `test_tree_detail`, `test_skill_tree`) -> `failures=0`; full gate; **all** references in `--only=` runs under
  10 minutes each (`'^[a-f]'`, `'^[g-m]'`, `'^[n-s]'`, `'^[t-z]'`) -> all OK, no row re-recorded.
- [ ] **Step 7: Commit** "feat: Death's and Decree's twenty powers have five levels -- tables, stat reads, shared twist hooks".

---

### Tasks 2-21: the twists

Every twist task: fill its stub test first (RED), gate on `_twist`, focused suites, commit "feat: <Power> level 5 -- <Twist>". Every
test file includes: **level 4** (the same setup at `{"level": 4}` shows nothing of the twist; where the effect is headless,
`ctx.rng.state` after a fixed time equals the literal recorded on Task 1's commit); **teardown** (the effect freed mid-twist
leaves no hold, law, mark, carried law, foul source or visitor; Review Focus 3); and the effect's existing suites still pass.
Check = focused suites + the task's rows (above).

#### Task 2: Death Mark -- The Wake (track A)
- Hook: after `_die()`'s body lands, watch the gawkers; the first within 1.0 of the body raises it (DL3); the effect's `duration`
  covers the zombie's life only through the zombie's own pack (as Raise keeps its pack).
- Tests: level 5, the marked dies, a gawker arrives -> one zombie stands at the body, the remain is taken, it hunts; its kills
  raise at most 2 more (CHAIN 3); a body taken by another power first -> no zombie, no error; quiet: no `on_cast` from the rising.

#### Task 3: Raise the Dead -- Body and Soul (track A)
- Hook: ZOMBIE mode: each ring zombie's end (cut down or `ZOMBIE_LIFE`) raises `DeathParts.spirit()` at its spot if its remain
  had a soul; SPIRIT mode: each ring spirit's fade raises `DeathParts.zombie()` from its own body (counted in `CHAIN`) (DL4).
- Tests: 3 bodies, ZOMBIE, level 5: after `lv_zombie_life` 3 spirits; a soulless body gives none; chain risers give none; SPIRIT,
  level 5: each faded spirit's body rises once, never a second spirit; two level-5 casts on separate rings keep separate counts
  (Review Focus 4).

#### Task 4: Pestilence -- Foul Dead (track A)
- Hook: at level 5 set each infected `plague_src = get_instance_id()` and call `crowd.plague.foul_from(get_instance_id())` (DL2).
- Tests: the cast's victim dies of plague -> a spot; a healthy person walking within 1.2 is infected, a 4th is not; a person sick
  from a level-4 cast dies -> no spot; two level-5 casts both foul; spots end after 15 s.

#### Task 5: Gravecall -- Swelling Host (track A)
- Hook: while haunting, a death inside `HAUNT_R` of the haunt spot raises one `DeathParts.haunt()` wraith at the body, 4 at most;
  it haunts until the cast's haunt ends (DL5).
- Tests: 5 deaths inside -> 4 more wraiths; a death at `HAUNT_R + 0.1` -> none; two casts' circles overlapping: each counts its own.

#### Task 6: Corpse Guise -- Deathless (track A)
- Hook: set `p.deathless` on each guised at level 5 (DL6); clear on lift, release and teardown.
- Tests: a guised person struck to death lies down, alive, rises after 5.0 s at full health, still guised until +10.0; a second
  death in the same cast kills; taken by the Gate (`&"pit"`) is not caught; a person whose guise ended dies normally; level 4: dies.

#### Task 7: Walking Corpse -- Borrowed Life (track A)
- Hook: an ATTACK kill at level 5 uses `&"borrowed"`; the walker's design and its remain's design become the victim's (DL7).
- Tests: the kill leaves no remain and counts a death; no alarm; the walker's design is the victim's; after lying down the remain at
  its spot has that design; two kills -> the last victim's design; level 4: `&"grave"` and a body.

#### Task 8: The Gate Below -- Graves Answer (track B)
- Hook: at open, pick the bodies (DL8); each shows a grave hand (the R34 sheet, the rift's hand drawing) and grabs once on the
  rift's `GRAB_EVERY` clock.
- Tests: 10 bodies within 12, a person 1.0 from each -> 8 taken, each remain taken; souls counted = rift's own + 8; a body at 12.5
  -> nothing; 30 bodies in reach -> still 8 hands (Review Focus 1).

#### Task 9: Pale Reign -- The Pall Grows (track B)
- Hook: each death in the district adds 0.25 to `lv_radius` up to the cast-time `lv_radius + 3.0` (DL9).
- Tests: 12 deaths at level 5 -> radius 14.0, a 13th changes nothing; a person 12.5 away crawls after the 6th death and not
  before; `test_pale`'s 5.0 ms perf check passes at level 5 with 12 deaths.

#### Task 10: The Pale Serpent -- Shed Skin (track B)
- Hook: at depart, lay the band (DL10) for 30.0 s; a person stepping on it is sickened once (the cast's own `hold_pace` id and
  `lv_sick`).
- Tests: a person crossing the path 5 s after departure is slowed `SICK_PACE` for `lv_sick` and plagued when a plague is live; the
  same person crossing again is not re-sickened; a person 0.6 off the path is untouched; the band is gone at 30.0 s.

#### Task 11: Grave Tide -- Scattered Bones (track B)
- Hook: the giant's fall (cut down or `lv_giant_life`) spawns up to 18 skeletons (DL11).
- Tests: giant cut down with 20 in the pack -> 18 skeletons; with 50 -> 10; at 60 -> 0 (Review Focus 1); their kills raise none;
  they leave at 20.0 s; `test_gravetide`'s `PERF_MS 8.0` passes at level 5 with the bones out.

#### Task 12: Leaving Is Prohibited -- Held for Trial (track C)
- Hook: at the cell's end, `LawMark.set_law(p, LawMark.CRIMINAL, 15.0, get_instance_id())` on each person inside, skipping
  `ctx.rules.director.faithful`.
- Tests: 3 inside, 1 faithful -> 2 named CRIMINAL for 15.0, the faithful not; a guard hunts a named one; a person who left before
  the end is not named; no director -> all inside named.

#### Task 13: Breathing Is Prohibited -- And None May Leave (track C)
- Hook: at level 5, a `LawZone.circle(origin, lv_radius, [LawZone.NO_LEAVING], 2.0)` laid with the NO_BREATH zone; `CHOKE` stays 3.0.
- Tests: a person at the centre walking out dies at 3.0; a person 0.3 inside the edge running out is held until 2.0 then leaves
  before 3.0 and lives; the NO_LEAVING zone is lifted at 2.0; a person who dies at 1.0 frees nothing (Review Focus 2).

#### Task 14: Redefine -- Precedent (track C; sonnet review)
- Hook: `can_follow_up()` while names hold and fewer than 3 copies given; `follow_up(at, _)` names the person nearest the click
  within 2.0 of a named one (not named already) with that name for the name's time left (DL12).
- Tests: 3 copies taken, a 4th refused; a click 2.5 from every named one refused; a copied CRIMINAL ends with its source; the follow-up
  starts no cooldown; a named one that dies mid-span leaves the copy valid.

#### Task 15: Bound in Law -- Party to the Bond (track C)
- Hook: the two `BondEnd`s become an array; every onset on one end is laid on all others; joiners per DL13.
- Tests: a soldier strikes A -> the soldier joins, A's hurt reaches B and the soldier (strikes himself); a third striker joins, a
  fourth does not; one dies -> all die; a joiner who goes indoors still shares fate; level 4: the striker stays outside the bond.

#### Task 16: Erasing Distance -- Shortcut (track C)
- Hook: after the spring-back, two seams at the line's ends for 15.0 s; anyone (people, soldiers, visitors) within 0.6 of one end
  is set down at the other (Skylift's set-down: the person's `ground_pos` set to the far end's nearest walkable, path cleared),
  then cannot be moved again for 1.0 s.
- Tests: a person stepping on end A appears at B; a hound too; no ping-pong within 1.0 s; seams gone at 15.0 s; an end on unwalkable
  ground uses its nearest walkable point.

#### Task 17: Disorder -- Bad Counsel (track C)
- Hook: each step, a person inside the zone gets `carried_laws[LawZone.DISORDER] = 8.0` when they cross out (inside last step,
  outside now), once per person per cast.
- Tests: a person leaving at 5 s is still in DISORDER at 12 s, not at 13.1 s; a person they pass is not disordered; two casts
  overlapping both carry, neither lifts the other.

#### Task 18: Eminent Domain -- Further Claim (track C; sonnet review)
- Hook: `can_follow_up()` for 5.0 s after the first strip is torn down; `follow_up(at, _)` tears a second strip (DL12) with the same
  width and work as the first.
- Tests: a click 4 away at 90 degrees tears a 4-long strip from the end; a click 10 away tears 6; a second follow-up refused; after
  5.0 s refused; a click 0.5 away refused.

#### Task 19: Fenced Rule -- Third Clause (track C; sonnet review)
- Hook: the wheel follow-up (DL12): `follow_up_wheel()` true, `follow_up_subject()` the fence's centre sigil, `follow_up_orders()`
  the three rule words not in force; `follow_up(at, {"order": word})` adds that rule to the live `LawZone` for its time left, once.
- Tests: NO RUNNING + NO ARMS, add NO DOORS -> all three hold; a fourth refused; the orders list never includes a rule in force;
  the third clause lifts with the fence.

#### Task 20: The Closing Cage -- Dragged Cage (track B; sonnet review)
- Hook: `can_follow_up()` once while closing; `follow_up(at, _)` moves the centre up to 6.0 toward the click over 2.0 s; people
  inside move with it (each held inside as today); buildings the ring crosses are crushed by the existing crush rule.
- Tests: a click 10 away moves the centre 6.0; a person inside ends 6.0 along; a house on the new ring's path is crushed; a second
  follow-up refused; a person who dies while dragged is skipped.

#### Task 21: The Sealed Verdict -- The Ledger Remembers (track B)
- Hook: DL14; the list is built each step of the countdown; at the bell, each listed living one dies `&"verdict"`.
- Tests: a person who walks through the district at 5 s and is 20 away at the bell dies; one who never entered lives; a person
  indoors on the list dies; a faithful who entered dies (DS call); a person freed before the bell is skipped.

---

### Task 22: Docs (sonnet; no review)
- [ ] `docs/KAK_God_Death_Decree_Levels_Summary.md`: what levels do, the twenty tables (stat words), the twenty twists one line each,
  the follow-up inputs (Precedent, Further Claim, Dragged Cage: select the slot again, click; Third Clause: the wheel), how to try
  them (Prepare's level picker; `--bench-cast=KEY --bench-level=5`), test files, commits.
- [ ] `docs/KAK_God_Death_Decree_Levels_Rulings.md`: DL1-DL14, every `Ruling:` from the reports, the bench table (Landing), open notes.
- [ ] Commit "docs: Death and Decree ability levels summary and rulings".

## Landing checks (after the three tracks merge into `god/dd-levels` and the final review's fix wave)
- Import; full gate (4 parts `failures=0`; crowd_check `-535548941`).
- **All 546 references** in `--only=` runs -> OK; `digest` unchanged; no row re-recorded.
- **Bench** (quiet machine; memory `kak-m1-perf-debt`): Gate, Pale, Serpent, Grave Tide at `--bench-level=5` with the twist firing,
  3 back-to-back pairs each -> ratios inside the Global Constraints; record them in the rulings doc.
- **FLOW alone** -> `209/0`.
- Land on `feat/god-progression` per memory `check-before-every-merge` (fetch, trial-merge, API clash check, gate the merged tree,
  ff, push) only on the user's word; then #god-changelog, Ledger `death-decree-levels`, #board.
