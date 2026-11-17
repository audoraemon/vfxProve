# KAK Death and Decree Ability Levels: every ruling

The Death and Decree ability levels milestone (five levels and a level-5 twist for each of the twenty powers) was built subagent-driven on `god/dd-levels` on 2026-11-17, landing on `feat/god-progression`: a groundwork task in two halves, twenty twist tasks in three parallel tracks (A, B, C), an opus final review with one fix wave and one residual fix, and this note. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry says what was decided and, where the controller gave one, the cost if wrong. The spec is `docs/superpowers/specs/2026-11-16-kak-death-decree-ability-levels-design.md`, the plan `docs/superpowers/plans/2026-11-17-kak-death-decree-ability-levels.md`, the summary `docs/KAK_God_Death_Decree_Levels_Summary.md`.

Groups, in order: DL1-DL14 (decided before the build), C1-C9 (the controller's rulings), the rulings each task reported, the final review and its fixes, the deferred minors still open, then what is owed at landing. Where two disagree, the later one wins. The user approved the spec, and was told before "Go" that the plan departs from it on Third Clause (by wheel, DL12) and on stuns (no joiner, DL13). Every number in the tables is a first guess, to tune in play.

## DL1-DL14 (shared hooks and rulings)

- **DL1 No Might column in the tables.** Might is `PowerBook.might()`. Tier 5 rows have no `cooldown` key (once a descent).
- **DL2 Foul Dead counts its own line only.** Pestilence's Foul Dead counts only deaths whose infection traces to a level-5 cast (`plague_src` is that cast's instance id). A sick person from another cast's line is not foul. A foul spot's victim carries the same `plague_src`, so it is foul in turn (the spec: "everyone the plague spread to from them").
- **DL3 The Wake.** It raises a `DeathParts.zombie()` from the Death Mark body's remain at Raise's level-1 numbers (`ZOMBIE_LIFE`, `CHAIN` 3 for this cast alone), plague-carrying when the body was sick. The remain is taken (`Remains.take()`). "First gawker reaches it" is the first person who stops to look within `PICK_R` 1.0 of the body.
- **DL4 Body and Soul** applies to the ring's own bodies only. Chain risers give no spirit. A spirit whose body is gone (taken by another power) raises no zombie.
- **DL5 Swelling Host's wraiths** are `DeathParts.haunt()` wraiths (Gravecall's own), at most 4 per cast, rising at the body.
- **DL6 Deathless.** Once per guised person per cast. The fall is `knock_down()` and a 5.0 s `hold_pace(id, 0.0)`. Then full health, and the guise renewed to `t + 10.0` for that person (the effect's `duration` grows to cover it).
- **DL7 Borrowed Life** swaps the walker's look to the victim's (`design`, facing kept) and writes the same `design` into the walker's remain, so it lies down as the last victim.
- **DL8 Graves Answer.** The 8 nearest remains within 12.0 of the rift that are not hidden and not taken. Each grabs once: the nearest living person out of doors within 1.5, by the rift's own drag (`DRAG`, kill `&"pit"`). The remain is taken. Each taken one is a soul for the close (R35 sectors count it).
- **DL9 The Pall Grows** changes `lv_radius` live. Everything that reads the district radius each frame (crawl, douse, ghosts' bounds, draw) reads the grown one. The cast's danger (`Crowd.on_cast`) keeps the cast-time radius.
- **DL10 Shed Skin.** The band is the path's sample points (`STEP` apart), each a 0.5 half-width hit test. It is drawn with the Serpent's disc texture, one draw per point, faded over its last 3 s.
- **DL11 Scattered Bones.** `DeathParts.skeleton()` times 18 (the bones count), life 20.0, in the tide's pack under `LIVING_CAP`. Their kills are flagged not to rise (the tide's own on-kill rise skips them). Amended by C8: they claw as the tide's skeletons.
- **DL12 Follow-ups.** Further Claim, Dragged Cage and Precedent are plain-click follow-ups. Third Clause uses the order wheel with the fence's centre sigil as `follow_up_subject()` and the unused rule words as `follow_up_orders()`. A follow-up never starts a cooldown (the existing rule). Further Claim: the strip runs from the first strip's end toward the click, `min(6.0, distance)` long (a click under 1.0 away is refused). This departs from the spec's "Q/E picks" for Third Clause.
- **DL13 Party to the Bond.** A joiner is the `struck_by` of a bound person, struck within the last frame, alive, not already bound, 2 joiners per cast. A seizer joins when `director.seizer_of(p)` exists (else seizures add no one). Stuns carry no source and add no one. This is a ruling against the spec's "stuns": no source exists.
- **DL14 The Ledger Remembers** lists every person whose `ground_pos` was inside the district at any step of the countdown (one frame counts). At the bell each listed one alive dies `&"verdict"` wherever they are, indoors too.

## C1-C9 (controller rulings, binding over the plan text)

- **C1 Task 1 as two dispatches.** 1a: tables, stat reads, previews, `test_death_levels` and `test_decree_levels`, plus the `test_power_levels`, `test_tree_detail` and `test_skill_tree` updates. 1b: the shared hooks, `--bench-level`, `test_dd_hooks`, the twenty twist stubs and every new file in `run_all.gd`. Why: Task 1 touches about 30 files; two reviewable halves. Cost if wrong: one extra review.
- **C2 Read-only files for Tasks 2-21:** `death_parts.gd`, `decree_parts.gd`, `law_zone.gd`, `law_mark.gd`, `visitors.gd` and `rules.gd`. A task that needs a change there reports NEEDS_CONTEXT. (The final wave changed `rules.gd` for walker credit.)
- **C3 (superseded by C7).** The full gate at Task 1 and landing; a twist task ran focused suites, its power's suites and its rows.
- **C4 Tracks.** A, B and C run in parallel in their own worktrees (separate files by design), `refs_check.sh --jobs=2`.
- **C5 Task 15.** If the director has no `seizer_of()`, seizures add no joiner (DL13). It has none.
- **C6 Per-task reference rows are advisory.** Other sessions' reference runs load the machine, and hitstop is wall clock, so load can move checksums. The evidence: `armoury_none_1` (casts no power) read `-23783136` instead of `-380503721` on the branch, and on the base `76c03af1` the same row timed out. All 546 rows are judged at landing on a quiet machine, base against branch. Cost if wrong: a level-1 leak is found at landing, not per task (a bisect over about 22 commits).
- **C7 No per-task full suite (supersedes C3's suite step).** Under this load a full pass takes hours. A twist task runs its focused suites (its twist test, its power's suites, `test_death_levels`, `test_decree_levels`, `test_dd_hooks`) and digest and crowd_check, then commits and reports. The full gate runs once per track end and at landing. Cost if wrong: a cross-suite break is found at the track end.
- **C8 Scattered Bones skeletons are the tide's own** (R42 claws and the R45 spare), not bare `DeathParts.skeleton()`. Why: the spec says "R42's numbers" and DL11 named only the factory. Cost if wrong: more wrecks; perf was re-checked (`_perf_bones` 4.6 ms against 8.0).
- **C9 Shortcut's arrival stands.** After a move, a body is not moved again until it steps out of `SEAM_R` of its landing end (stepping out at any time since the move counts) and at least 1.0 s has passed. The plan had only the 1 s rest, and still-standers bounced every second for 15 s. Cost if wrong: a person can camp at an end.

## Rulings the tasks reported

### Task 1a (tables and stat reads, `6bdc5f7f`)

- Raise's ring (`RING_R`, `MOST`), Death Mark's `PICK_R` and Walking Corpse's pick radius have no levelled stat in the spec, so no helper change.
- `SPAN` is labelled per key ("time" here) to keep Dominion's "span" tree text.
- The Serpent's frighten radius (`BAND + 3`) and fright-back follow `lv_band`. So does the frost patch radius (`Frost.band`).
- The Sealed Verdict's rune count follows the countdown (`ceili(lv_countdown)`, 30 at level 1). Four amber inner-class `_init` moved to `_ready` because they now need `fx`.
- The Cage's `radius` var is set to `lv_radius` at build, so the bars draw at the level's size before landing.
- The existing `test_serpent` AREA_STATS equality was updated for the added `half` row.

### Task 1b (shared hooks, `94a609ae`)

- `foul_from(0)` is ignored (source 0 means "no cast"), so an untagged plague is never foul.
- The spared-death check lives in `Person.die` (an override) plus `EnemyField.kill`'s `if e.is_alive(): return false`, because `die()` returns void.
- Foul spots carry `src` as a fourth key, so a spot's victims are foul in turn (DL2).
- Crowd gained `clock()` (its `_clock`) for `struck_at`.
- The test "rng after 10 s equals the empty-foul run" uses one isolated sick person plus a direct check that the spot's infections leave `_rng.state` unchanged. A cluster comparison would legitimately differ.

### Task 2 (Death Mark, The Wake, `94cb2062`)

- Death Mark is not in `Remains.WANTED_BY`, so with no other Raise-family power the ledger is off. At level 5 the twist sets `remains.enabled = true` in `_build()` (as Pale Reign does) and never turns it off. Levels 1-4 never touch it. (Fix rounds later made the ledger restore itself and share a holder count across overlapping Wakes.)
- "First gawker" is the nearest (then lowest instance id) person the mark lured, alive and not inside, within `PICK_R` 1.0 of `body_at`. People lured by other powers do not count.
- The wake finds the body by its own remain (kind `deathmark`, within 0.2). If another power took it first, nothing rises.
- The mark stops luring at its own span. Only the zombie outlasts it.

### Task 3 (Raise the Dead, Body and Soul, `db4b3bcf`)

- "Had a soul" is `Remains.has_soul` at the cast (by the time a zombie ends, the 15 s SOUL is long past).
- Spirit-born zombies are the cast's first risers, not drawn from `_left`. Only their kills spend `CHAIN - 1`, shared by the whole cast (R29).
- DL4's "body gone": the cast itself takes the remain at the cast, so no other power can take it. The spirit's body always rises.
- A zombie's end at `ZOMBIE_LIFE` removes the zombies (`Visitors.take`, not counted slain) before the spirits rise.

### Task 4 (Pestilence, Foul Dead, `bc1a2985`)

- `plague_src` and `foul_from` are set in the existing 0.4 s infection event, only for people the cast actually infected. An already-sick person keeps their own line. A cast freed before 0.4 s infects and fouls nothing.

### Task 5 (Gravecall, Swelling Host, `19c02244`)

- "While haunting" is `haunting` true (all spirits arrived) until `_end_life`. Deaths while still travelling raise none.
- Every death counts (any kill kind, citizens and soldiers). The new wraiths join the cast's soldier freeze like the originals.
- The twist adds no alarm or `on_cast`.

### Task 6 (Corpse Guise, Deathless, `5d4a0f79`)

- The guise's count waits while a person lies. At the rise it is set to exactly 10.0 (DL6), even if more remained.
- Health at the fall is left as the blow left it (may be 0 or below). A second death while lying kills (the hook is spent).
- A cast ending or taken over mid-fall lets the person up at full health at once.
- The health restored is the larger of health at cast and the base citizen or soldier health.

### Task 7 (Walking Corpse, Borrowed Life, `cc54b4c7`)

- The look swap keeps the walker's own facing (DL7). The remain's facing stays as it was.
- A kill the field refuses (returns false) swaps nothing.

### Task 8 (The Gate Below, Graves Answer, `85caa50d`)

- DL8's "by the rift's own drag" is read as held where they stand for `DRAG`, then pulled under. No travel to the lip (a 12-unit drag in 1.5 s would be absurd). Same as R33's one-inside-the-lip rule. The coordinator accepted it.
- A hand with nobody near its body waits and retries on later ticks. One twist grab per rift tick. Ticks stop at `SPAN - DRAG`, as the rift's own do.
- Fix round: the body is taken when the victim goes under, not at the grab, so an early free no longer loses a remain.

### Task 9 (Pale Reign, The Pall Grows, `73d10353`)

- Every `Person` death within the current radius counts (indoors inside it too, as the existing ghost-per-death rule), any kind.
- The hush keeps the cast-time radius (the brief names crawl, douse, bounds and draw only). So does the ash emitter's spread.

### Task 10 (The Pale Serpent, Shed Skin, `7b67914d`)

- The skin's sickness does not touch `sickened` (the sight's counter). A person still held by the sight is skipped, so the skin can sicken them once the sight lets go.
- `test_serpent` has no frame-cost check. The skin draws once (a cached canvas item), so it adds no per-frame draw cost. No bench run (C7).

### Task 11 (Grave Tide, Scattered Bones, `df542c8f`, fixed in `4462da06`)

- First build used bare skeletons. The reviewer found a stale `_end_giant` after a late fall wiped the bones. Controller ruling C8: the bones claw as the tide's own skeletons (`_up_skeleton()`, `SKELETON_WRECK` 6.0 every 1.5, R45 spare), counted in `raised`.
- The tide ends at fall + 20 + `FADE`, and no earlier than `LIFE + FADE` if the horde is up. Bones only spawn at the fall (18 pack members), so the 1.9 cast/base ceiling was not benched.

### Task 12 (Leaving Is Prohibited, Held for Trial, `ce4806cc`)

- "Inside at the end" is held by the law (`bound`), within `lv_radius + 0.5` of the cell's origin, alive and not in a building. People carried out past the edge are not named.

### Task 13 (Breathing Is Prohibited, And None May Leave, `ebad833a`)

- The stay zone is added to the crowd with no holder and `hold_by(self)` set afterwards. `Crowd.add_law` hooks `tree_exiting` once per holder, and the NO BREATH law already uses it (a second connect errors). The cast's own `_exit_tree` lifts it instead. No C2 file touched.

### Task 14 (Redefine, Precedent, `45bd61c8`)

- A dead named one is no source for a new copy (copies already given stay).
- No time left (0 or less) refuses the copy.

### Task 15 (Bound in Law, Party to the Bond, `de6b66e1`)

- C5 applied: the director has no `seizer_of()`, so seizures add no joiner (guarded by `has_method`, tested).
- A joiner's baseline is taken at joining: they take the blow that brought them in, not earlier ones.
- "Within the last frame" is `crowd.clock() - struck_at <= delta`, and the blow must also have taken health this frame.

### Task 16 (Erasing Distance, Shortcut, `45def175`, fixed in `f1c4328f`)

- An arrival may stand within 0.6 of the far end. The first version took it back after the 1 s rest if it stayed. The reviewer found `er_tear` retriggering every frame near an end. C9 replaced the rule: no move until it steps out of `SEAM_R` of its landing end.
- The "stepped out" flag is sticky from the first step seen outside the ring, so a step out inside the 1.0 s still counts once the second has passed.
- Living visitors are gathered once per step and tested at both ends in one pass.
- The seam drawing is staged-only, so it is not asserted in headless tests.

### Task 17 (Disorder, Bad Counsel, `8f67cfa5`)

- "Crosses out" is seen inside in an earlier step and outside now (a newcomer who walked in and out counts). An already carried DISORDER is refreshed to the larger of existing and 8.0, never shortened.

### Task 18 (Eminent Domain, Further Claim, `b11b7b68`)

- The second strip is a level-1 cast of the same `EminentFx` (`FxTimeline.cast(get_script(), ...)` from `to`), sized by two private extra keys `strip_len` and `strip_half_w` that only `follow_up` sends. This reuses the whole tear-down (claim, tear, shove, throw, rubble, decor, walk grid) with no copy and no change to level 1 arithmetic. The keys are absent in every ordinary cast.
- The parent `duration` extends to `t + second.duration` on a follow-up.
- No `follow_up_area()` at first: the shapes anchor at the cursor. (The final review changed this, M5.)
- The follow-up sends no `Crowd.on_cast` of its own. The second strip's own `ed_roar` sound plays.

### Task 19 (Fenced Rule, Third Clause, `cc02827d`, fixed in `4f45257b` and `3a061639`)

- No new `LawZone` API. `LawZone.kinds` is a public array that every consumer reads live, so appending the kind to the fence's own zone holds the third rule for exactly the time the law has left and lifts with it. `law_zone.gd` untouched (C2).
- The wheel's order words are the RULES keys, and the `Targeting` pick step sends `{"order", "to"}` so a slice then a click anywhere takes the order (like Walking Corpse's "enter"). `follow_up` ignores `to`.
- The sigil is made at level 5 whether or not the cast is staged (headless tests have `ctx.overhead`), tracked, and freed on `_finish` and `_exit_tree`. It is alive only while the clause can still be taken.
- The level-5 hold time is the table's 38 s. The clause adds no time.
- Fix round 1: the wheel showed bare keys ("run", "leave"). It now shows NO RUN, NO ARMS, NO DOORS, NO SIGHT and NO EXIT ("no exit" is shorter than NO LEAVING). The old key words are no longer accepted. The cap-refusal test loops over every wheel word.

### Task 20 (The Closing Cage, Dragged Cage, `5724b03f`)

- A click on the centre (distance 0.0001 or less) is refused and does not spend the drag.
- The follow-up area preview is a circle of the ring's current radius.
- A person carried into a cracked building the bars pass through is cut down like one pinned against it (crushed).
- A building whose middle the sweeping leading edge crosses also falls (the brief says crossed buildings are crushed).

### Task 21 (The Sealed Verdict, The Ledger Remembers, `8821e8a1`, fixed in `68c97b33`)

- The twist never consults `director.faithful`: the base verdict already kills every person, so a faithful on the list dies as anyone does.
- Only people `in_radius` (outdoors, in the field) were listed per step at first. Fix round 1: each step also walks `shelters_at(...)` (the base verdict's own helper) and lists the `inside` persons by instance id. The "already doomed" check at the bell is a set of ids.

## Final review and fixes

The opus whole-branch review of `76c03af1..c60497c4` said **with fixes**: three Important, four Minor. One fix wave (`2907492c`), then a scoped re-review that found 7 of 7 addressed and one new Important, fixed in `cf1a1a62`.

- **I1 Sealed shelter leak.** The Ledger killed a listed person sheltering in a house outside the district in place, leaving a dead occupant in `ShelterManager.shelters[s].inside`. Fix: listed shelterers are released before the kill. Test: the person dies and is no longer an occupant.
- **I2 Walker credit.** `POWER_KINDS["walker"]` lacked `&"borrowed"`, so Borrowed Life kills were credited to no power. Fix: `[&"grave", &"borrowed"]` in `rules.gd`. Tests in `test_walker` and `test_death_twist_walker`.
- **I3 Deathless lay too short.** `knock_down` lies 1.0 s plus 0.7 s getup, then the person stood frozen about 3.3 s of the 5 s. Fix: `Person.knock_down(lie, force)` with a default lie of `DOWN_SECONDS` (level 1 unchanged), `deathless_lie`, and `stand_up()`. The guise lies `FALL_TIME - GETUP` and rises as the 5 s ends. It works when the person is already down or frozen. Tests: down at 4.0 s, up after 5.0 s, the already-down and frozen cases.
- **M4 Guise, second death while lying.** A person dying again while lying kept the guise status and shroud up to 5 s. Fix: `_rise(p, false)` then `_lift(p)`.
- **M5 Further Claim preview.** No `follow_up_area()`, so the preview showed the normal 12-long lane at the cursor. Ruling: `EminentFx.follow_up_area()` is a small ring of `FOLLOW_MIN` while the window is open. The lane shape cannot anchor at the first strip's end. This is why the preview is a small ring.
- **M6 Spared plague victim.** A person spared from a plague death (Deathless) kept `plague_src`, so a later infection from another power would have made their death foul (DL2 forbids that). Fix: `plague_src = 0` when the kill returns false.
- **M7 Rite kill cancelled.** `p.die(&"rite")` on a guised captive was cancelled by Deathless while the shard was counted. Fix: `&"rite"` joins `&"pit"` and `&"gone"` as kinds Deathless never catches.
- **Residual (breaker adjudication, `cf1a1a62`).** The re-review found a negative down-pose frame during the 4.3 s Deathless lie (`person.gd` near line 2946). Fix: `Person._down_total` remembers the lie's length (default `DOWN_SECONDS`), and the down pose uses `maxf(_down_total - _down_left, 0)`. Level 1 is identical, and a `test_person` check proves the level-1 frames equal the old formula. Cost if wrong: one more small `person.gd` change.

After the wave: twists, base, plague, `dd_hooks`, levels, person, rules, rite, bound, fight_back, madness and pilgrim suites all `failures=0`. Digest and crowd_check OK.

## Deferred minors (left open)

From the reviews, not fixed:

- **Task 2:** the typed `Array[Person] _looked` may hold freed nodes (guarded). A stale `wake_ledger_holders` meta if `crowd.clear` keeps the Remains object. Another power lighting the ledger after a Wake is switched off by the last Wake (only a mid-night lighter could hit it, since `WANTED_BY` powers light at load).
- **Task 3:** the SPIRIT teardown is asserted before the first half ends (trivial). No teardown with a live spirit-born zombie. No shared-`_left` multi-body test. SPIRIT pair overlap is not checked.
- **Task 5:** `var at` shadows `at()` in `gravecall.gd` near line 79.
- **Task 6:** the guise sets 10.0 rather than the larger of current and 10 at `_rise`. (The "stands frozen" and "dies while lying" notes were fixed by I3 and M4.)
- **Task 7:** no test for the body taken meanwhile (the guard is probably unreachable).
- **Task 8:** the hand stays at its old position if another power moves the body (cosmetic). The teardown test does not assert graves emptied or the arm let go.
- **Task 9:** the freed-node teardown test does not assert `enemy_killed` is disconnected. An unused var grew.
- **Task 10:** stray tab characters mid-line in the `_fx_process` early-out. The skin tint stacks dense (0.22 times about 4). A header typo ("Shed ShedSkin") and trailing whitespace in the test.
- **Task 11:** the late-fall "gone" check is at +20.1, not +20.0. `_claws[0]` throws if there are none.
- **Task 13:** the 0.3 s timing margin rests on `Person`'s panic path. A possible harmless double `lift()` at expiry. Faithful-held is not tested.
- **Task 14:** stray tabs mid-line at `redefine.gd` near line 104. The source is chosen only among the named within 2.0 of the click (the brief's wording). The preview circle sits at the cursor.
- **Task 15:** the bead flare's draw order changed at all levels (judged acceptable). Joiner chains show no bead. A tab-continuation line in `_join`. No freed-joiner test. `struck_at` against delta under hitstop is unverified live.
- **Task 17:** a second `in_rect` pass per step. A sub-step crossing is not caught.
- **Task 18:** the second strip re-registers no danger or alarm. A second strip back over the first is untested.
- **Task 19:** no test for a null `ctx.overhead`.
- **Task 20:** an ungated `_exit_tree` law lift at levels 1-4 (no observable change). The level-5 perf "untouched" check is vacuous. Carried people bypass the walk grid (ruled).
- **Task 21:** `shelters_at` each frame could ride the `TALLY_EVERY` throttle.

## Owed at landing

None of these ran to a clean result in the build, because other sessions' Godot runs kept the machine loaded (C6, C7). Run them on a quiet machine before the merge into `feat/god-progression`.

1. **All 546 reference rows, base against branch.** Base is `76c03af1`. Any mismatch is judged side by side on the base. The none-rows (a cast of no power) should match exactly. The Death and Decree groups timed out at 1700 s in every attempt. Only a row that moves on the branch and not on the base counts as a level-1 leak (then bisect over about 22 commits).
2. **FLOW alone.** It aborts under parallel Godot load or a concurrent FLOW (shared `user://test_flow.cfg`). A failure alone is a real bug.
3. **Level-5 bench pairs** for `gatebelow`, `pale`, `serpent` and `gravetide`, with the twist firing, base against branch (`--bench-cast=KEY --bench-level=5`). The budgets: Gate, Pale and Serpent within 5 ms (cast/base 1.55 on a loaded machine), Grave Tide within 8 ms (1.9). If one is over, cut its twist's draw first, then its growth, never the level 1 numbers. Pale at level 5 read 4.2 to 4.85 ms, with one 5.33 under load.
4. **`test_decree_cage` 2 ms perf check, alone.** It failed under load at level 1 and level 5 alike, and on the base at level 1 too, so it is a load flake until proven otherwise. A quiet failure is real.
5. **The full suite in parts** on the merged tree, since every task ran only its focused suites (C7).
