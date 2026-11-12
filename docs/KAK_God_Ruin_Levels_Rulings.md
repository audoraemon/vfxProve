# KAK Ruin Ability Levels: every ruling

The Ruin ability levels milestone (five levels and a level-5 twist for each of Ruin's ten powers) was built straight through, subagent-driven, on `god/ruin-levels` on 2026-11-03, landing on `feat/god-progression`: a groundwork task, ten twist tasks in three parallel tracks, an opus final review with one fix wave, a re-review, and this note. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry below has what was decided and why; where the controller gave a cost-if-wrong, it is kept. The spec is `docs/superpowers/specs/2026-11-03-kak-ruin-ability-levels-design.md`, the plan `docs/superpowers/plans/2026-11-03-kak-ruin-ability-levels.md`, the summary `docs/KAK_God_Ruin_Levels_Summary.md`.

Groups, in order: the plan's rulings R1-R15, the rulings the final review and fix wave added (R5a, R12a, the recast rule and the others), the controller's process rulings (C1-C4 and the ledger rulings), the rulings each task reported (T1-T11), then the open and playtest notes. Where two disagree, the later one wins: R5a amends R5, R12a amends R12 (the plan and spec still say "1.6 s" and a lane that ends at the wave's reach; the code and this note are right). The user approved the spec ("All look good", 2026-11-03) and gave no separate rulings of their own; every number in the tables is a first guess, to tune in play.

Task 12 (this note) reported no rulings of its own.

## The plan's rulings R1-R15

- **R1 Tsunami's labels.** The spec calls `LENGTH` "wall length" and `WIDTH` "travel"; in `tsunami_breaker.gd` `LENGTH` is how far the wave runs along the drag and `WIDTH` the wall's breadth. The numbers follow the constant names (`LENGTH` 6.5/7.0/7.5/8.0/8.5, `WIDTH` 8.0/8.5/9.0/10.0/11.0); the docs and the tree name them correctly ("travel", "wall width").
- **R2 Per-level cooldown.** A table stat named `"cooldown"` (lower case: a row field, not an effect constant), read by `PowerBook.cooldown(key, level)`. Wrath of the Sky and Earthshatter have no cooldown column, so no `"cooldown"` key: they stay 999 (once a night).
- **R3 No Might in the tables.** The spec's Might column is `PowerBook.might(key, level)` already (the base cost, +1 at level 3, +1 at level 5); a test proves it equals the spec.
- **R4 Tree text.** `level_change_in()` prints a stat by a short label when `PowerBook.STAT_LABELS` has one ("kill radius", "damage", "cooldown", "start fire", "reach", "pull radius", "life", "bursts", "radius", "burn time", "breath", "sweep", "travel", "wall width", "stones", "rain radius", "storm", "bolts", "volley every", "longest crack", "fall width", "crawl"), else its raw name (the P1 fixture's `"radius 1.0 -> 1.1"` still reads so); a `Vector2i` prints `"5-7"`. The controller's own call.
- **R5 Previews follow the level.** `Targeting.area()` and `_on_cast_made()` (the crowd's danger lane) read the slot's level for the areas a table changes. `PowerBook.REACH` and `IMPACT` (how long the town treats a cast as dangerous, when it first kills) stay level-free. The controller's own call. **Amended by R5a.**
- **R6 Smite fork.** 0.12 s after the strike, a full Smite (kill `lv_kill_r`, `lv_damage` within `HIT_R`) on the nearest living person in the open within 2.5 of the bolt who was not struck; it leaps even when the first bolt struck nobody; none in reach, no fork.
- **R7 Ember leap.** Only if the first building caught (`lit`); 1.0 s after landing, a second spark to the nearest other standing burnable (`FireManager.burns()`) within 3.0 of the first one's centre that is not already burning, at the level's `START_LEVEL`. Quiet: no fright, no alarm, no `Crowd.on_cast()`.
- **R8 Twin Funnels.** Each twin pulls 1.8 for 4 s, core 0.4, wind damage radius 0.6 at the parent's rate; they run straight apart along the perpendicular of the parent's last heading at `WANDER_SPEED`; a twin flings its captives as the parent does (kind wind); twins never split again. A twin pulls only within its own radius (Task 4).
- **R9 Seeking Bursts.** The seek happens at each burst's compress (`_compress(i)`), moving `points[i]` to the nearest living person in the open within 1.5 of it; the random draws are unchanged.
- **R10 Wandering Sun.** The knot is the person within 4.0 of the pillar with the most neighbours within 1.0 (Tempest's `CROWD_R`); re-picked every 0.5 s; no one in reach, it stands. The pit follows the pillar and is left where it stops (`SolarisPit.move_to()`).
- **R11 Second Breath.** 2.0 s after the first breath ends, a second breath of the level's `BREATH_TIME`, sweeping the same arc back (right to left). The cast keeps the slots locked through it (busy stays the whole duration).
- **R12 Backwash is not lethal.** From 0.2 s after the crash it draws back over the ground the wave soaked; whoever is alive, in the open and in the lane behind the receding edge is carried with it and set down at the start, knocked; buildings are not hit again. The controller's own call. **Amended by R12a** (as written, the lane was empty).
- **R13 Lava Pool.** Opens at `_sink()` (radius 1.5 at the cast point) and burns 15 s; kills (kind cinder) whoever is in it, checked every 0.1 s; "beside it" = standing burnables within 3.0 of the centre (the volcano already levels 2.7), set alight at 0.4 when it opens and again every 3 s if not burning. The effect's duration stretches to cover it, but `busy` stays 12.0 (the slots unlock as today).
- **R14 Called Bolts.** A click on the ground with the Wrath slot focused, while its storm is `storming()`, drops one hard bolt exactly there after the storm's `LEAD` omen, at most once every 3.0 s; it counts in `bolts` (and so in `FIRE_EVERY`). Too soon, or after the storm, the click is refused as a cooldown is. No HUD change beyond the preview edge; the twist text tells the player. The controller's own call.
- **R15 Fault Lines.** Forks at 1/3 and 2/3 of the run, the first to the left of the run, the second to the right, 0.6 rad off the line, 5.0 long, the level's `HALF` and `SPEED`, each its own `Fissure` (stays open); busy and duration stretch to the last branch's end.

Plan-wide rules that act as rulings (from the plan's Global Constraints): level 1 equals today bit for bit (a table's level-1 value keeps its const's type; a derived timing is computed at cast time with the const's own expression; a duration written as a literal becomes `11.5 + (t_sink - T_SINK)`); twist code is gated before any `ctx.rng` call, `at()` scheduling or field call; twists use only `ctx.rng` or none, and ties go to distance, then field order; per-instance stat vars are `lv_<const>`; no PixelLab.

## Added by the final review and fix wave

The opus final review (`fb917db6..fa90cf99`) said "fix first" with three Important items; the fix wave (`e34c44aa`, `d00a8d09`, `e98bfc48`, `bb3b6588`) landed them and the re-review was clean.

- **R12a Backwash reaches the splash ring and 1.5 wider** (amends R12; fix wave 1). The crash kills its own lane and everything within 3.0 of the crash point, so a lane-only drag found nobody except people who walked into the flood afterwards. Now the receding edge starts at `lv_length + BACKWASH_REACH` (5.0, the splash's `r_max`), catches in a lane `BACKWASH_SIDE` (1.5) wider each side out to `lv_length + 5.5`, and takes `BACKWASH_TIME` 2.4 s (about 5.6 u/s, close to today's wave); the flood quad and its light are capped at `minf(_back_front, lv_length)` so they do not overshoot. It ends at crash + 2.6 s, inside the 9.5 s duration. Still non-lethal, still level 5 only.
- **R5a The town's danger radius follows the level** (amends R5; fix wave 2). `Crowd.on_cast(..., key, level := 1)` and `_cast_radius(key, level := 1)` read `Targeting.area_at`, and `danger_landed` carries the radius as a third argument, so the player and the town agree: a level-5 Cinderfall shows a 7.0 ring and the town flees a 7.0 circle (not 5.8). The Festival judges "broken goers" with the signalled radius; the Assassinate and Lost Lamb handlers take it optionally. `PowerBook.REACH` and `IMPACT` stay level-free. Level 1 is unchanged because `area_at(key, 1)` is `AREAS[key]`.
- **The recast rule** (fix wave 5; amends R14). `Rules.recast` and `Rules.can_recast` return false when the run is `finished` or `busy_left() > 0.0`: a called bolt is refused after the run is over and while another power holds the busy lock, the same lock `cast()` refuses on. Wrath's own gathering lock (`T_GATHER`) ends before a bolt can be called, so a normal storm click is never refused by it. Cost: another power cast during the storm blocks calling until its lock ends.
- **Wandering Sun leaves nothing behind** (fix wave 3). `_fade` uses `beam_at` for the closing burst, ring, smoke, embers and both sounds; `FxParts.ground_light` takes an optional `getter` (Solaris passes `func(): return beam_at`, so the scene light follows the pillar); the heat haze moves in `_follow`. Every other `ground_light` caller passes no getter, so nothing else changes.
- **One shared stage Impact** (fix wave 1, Minor). `FxStage.StageImpact` (`focus_of` returns the screen centre; `hitstop`, `impact_frame`, `aberration`, `dim` are no-ops) is installed by `FxStage.make()` and freed by `drop()`; the three local `StubImpact` classes in the dragon, tsunami and cinder tests are gone. A shared stage can now run a cast past 1.2 s, and the no-op `hitstop` removes the `Engine.time_scale` hazard at its source.
- **Lantern blow literal.** `lantern_eye_director.gd` `BLOW_MAX := 45.0`, commented as a level-1 Smite's worth: a mirror takes two blows at every level (a level-5 Smite's 65 is still less than the mirror's 90), and a later retune of `SmiteFx.DAMAGE` can no longer silently retune the Lantern. Lantern blows stay level-free.
- **Preview edge redraw.** `Targeting._process` redraws when the edge's ready state flips (cooldown end, storm end, the 3 s spacing), so a still mouse does not show a stale gold or red edge.
- **Test strengthening** (fix wave 5): a real `Targeting` press/release test replaces the source-text search for Called Bolts; the tornado check requires the dummy to be PULLED, alive and moved toward the nearest twin; a Cinder town case proves `fires.ignite` is the path; `twist_at` is false at levels 9 and 6; the skill tree pins the literal 2 -> 3 line for Smite.
- **Left as ruled by the controller** (fix wave brief, "Leave"): the Fault Lines branch start inside the main crack, Dragon's second breath's extra scene light, the called-bolt preview ring against its kill radius, and called bolts not being heard as casts. They are in the open notes below.

## Controller rulings C1-C4 (as kept in `rulings.md`)

- **C1** (all twist tasks): the implementer works in its track's worktree (named in the dispatch), not `vfxProve-god-t1r`; the workspace files stay in `vfxProve-god-t1r/.superpowers/sdd/2026-11-03-kak-ruin-ability-levels/` (briefs are read there, reports written there). The first command in a fresh worktree is the `--import` line.
- **C2**: per task run the focused twist test, `test_ruin_levels` and the effect's existing tests, and `bash tools/dev/refs_check.sh --only='^(digest|crowd_check)$'`; commit each task on its own. After a track's last task, `bash tools/dev/run_suite_parallel.sh 3` -> failures=0.
- **C3**: `twist_at()` is true only at exactly level 5 (the Task 1 review's Minor 3: `stat_in` clamps the level, so a caller-set level 9 had been true). `FxStage.drop()` resets `Engine.time_scale` (Minor 1).
- **C4**: three tracks run at once on this laptop; keep Godot runs to the C2 commands (no full refs, no FLOW).

## Ledger rulings (as kept in `progress.md`)

- **No opus pre-flight agent.** The plan's own R1-R15 and file table already answer the scan; the controller read it. Cost if wrong: a conflict surfaces in Task 1's review.
- **Three parallel tracks.** A (`god/rl-a`) Tasks 2, 3, 4, 5; B (`god/rl-b`) Tasks 6, 7, 8; C (`god/rl-c`) Tasks 9, 10, 11; each serial inside, cut from `3692f675`. One worktree is about eight hours serial; three tracks keep the Godot load bounded. Cost if wrong: merge conflicts at the end (none: the file sets are disjoint, and `git show --cc` showed 0 conflict hunks for each merge).
- **Per-task checks, full gate at landing.** Twist tracks run focused tests plus digest/crowd_check per task and one `run_suite_parallel.sh 3` at the track's end; the full suite, all references and FLOW run at landing. Cost if wrong: a cross-suite break shows late.
- **Park N1-N4.** The re-review's four Minors (below) are tests-only gaps or a cosmetic redraw; none changes behaviour. Cost if wrong: a later regression in those guards goes unseen.
- **Task 1 review disposition.** Approved with Minors; Minors 1 (the `time_scale` reset) and 3 (the `twist_at` level gate) were folded into `3692f675`, together with the Prepare cooldown fallback via `stat_in`. The ten placeholder `t.check(true, ...)` twist tests were plan-mandated and are replaced by Tasks 2-11 (`grep` finds none).

## Rulings the tasks reported

### Task 1 (groundwork, `d3455908`)

- Dragon's twist text is the brief's own wording ("Second Breath: breathes again, back the other way", 49 characters). The brief's "under 45 characters" is a goal; the real check, `UiTheme.width` against the tree's detail line, passes with room (278 of 488 px), and the test checks the width.
- `FxStage.make()`: the suites run from `_initialize`, when `tree.root` is not yet in the tree, so the Battlefield's `_ready()` has not run; `make()` calls it itself when `ctx.field` is null and sets `ctx.sfx = null` (nothing can sound off the tree). The engine prints one `ERROR: ... make_current` line per stage; it is not a `SCRIPT ERROR`, the runner does not count it, and the helper's header documents it.
- `STAT_LABELS` is one flat constant; the one clash (`RADIUS` in Solaris and Cinderfall) is handled by a `"<key>.<stat>"` override, so Cinderfall reads "rain radius" and Solaris "radius".
- Reference runs were split with `--only=` into chunks under ten minutes (the rendered sequential rows take 4-5 minutes each); the whole set, 508 of 508, passed with no row re-recorded.

### Task 2 (Smite, `60966840`)

- The fork target is chosen at the strike (position bound then), as the brief's `_fork.bind(where)` says: a person who walks off in 0.12 s is still struck at the spot.
- A fork can also kill others within `lv_kill_r` of the second spot (counted in `struck`), as "a full Smite".

### Task 3 (Ember, `4f5593d4`)

- The leap is scheduled at `T_LAND + LEAP_DELAY` rather than `t + LEAP_DELAY`: the same instant in a real frame loop, but independent of the step size (a test stepping 0.75 would otherwise shift it), and equal to the `duration` arithmetic.
- The target is chosen when the spark leaps, not at landing, so a house that caught or fell in the second between is judged as it stands then.

### Task 4 (Tornado, `c6a624dc`)

- The twin funnels get their own `RandomNumberGenerator` (seeds 4242 and 4243) for the Funnel's debris, so the cast's `ctx.rng` is untouched (R8 "no rng beyond today's").
- Stray captives: `pull_near` never touches an enemy that drifts out of every twin's radius; when the last twin ends, `release_all()` frees any such straggler (as the parent's dissipate does), so none stays PULLED.
- The twins do not re-register the parent's ground light; a twin captive uses its own funnel's radius for the spiral.
- The rng-neutrality check calls `_split()` and `_twins_step()` directly (a level-4 and a level-5 cast die at different times, so their rng states cannot be compared at one instant).

### Task 5 (Scatter Strike, `6f2d4202`)

- The 16th point at level 5 is a draw level 4 does not make (`BLASTS` 16 against 15), so "the draws before compress equal level 4's" is tested as the shared prefix of 15 points.

### Task 6 (Solaris, `f46cd2c2`)

- A tick's movement is `DRIFT` times the part of the tick inside the burn window, so a big test step does not jump (and the first call at exactly `T_CHARGE` moves nothing).
- The drift target is the knot person's position at the re-pick (not a centroid); people `inside` are not candidates; neighbours are counted with `EnemyField.in_radius(p, KNOT_R)` minus self; a lone person is still a candidate with 0 neighbours.
- Test geometry: the brief's "knot 3.0 east" is inside the level-5 pillar at once, so the drift test shrinks `lv_radius` to 1.0 to measure the drift (1.6 east after 2 s, within 0.05), and a second test uses the real 3.0 pillar with the knot 3.8 east.
- `beam_at` is set in `_build()`, since a field initialiser would run before `cast()` sets `origin`.

### Task 7 (Dragonfire, `b00bac5b`)

- The test installs a no-op `Impact` subclass because the suites run before the root is in the tree and `Impact.focus_of` (called in `_rise` at 2.2 s) has no viewport and aborts the cast. Later replaced by the shared `StageImpact` (fix wave).
- The second breath's start is its scheduled time, not the tick it fired on, so its sweep is tick-independent.
- Level 5's `lv_t_sink = T_BREATH + 2 * lv_breath_time + SECOND_GAP + 0.4`, so `duration = 11.5 + (lv_t_sink - T_SINK)` stretches to the second breath; busy stays -1 (the whole duration).

### Task 8 (Tsunami, `f38e62bf`)

- `BACKWASH_KNOCK` 2.5 u/s: with `KNOCK_DECAY` 8 the throw is about 0.39 total, about 0.34 by the test's check time; a harder throw would leave the 0.5 band by crash + 2.0.
- The drag reaches people from the far end inward, so a person near the start is first nudged slightly outward (the target is 0.25 inside the edge) before being brought back: the brief's own formula.
- The test sequence places people and the house just after the crash, because the crash itself kills everyone in the lane (the finding behind R12a).
- Same local no-op `Impact` subclass as Task 7 (since replaced by `StageImpact`).

### Task 9 (Cinderfall, `f5a0e1bc`)

- The stones fall until 7.5 s, so the test adds its houses at `T_SINK - 0.15` (after the barrage), so no stone can touch them.
- A stepped effect does not run tweens, so the sunk volcano's own 2.7 kill zone (`_volcano.sink < 0.9`) would stay on; the test sets `_volcano.sink = 1.0` after the sink so only the pool can kill at the centre.
- The stage's `Impact.focus_of()` logged a SCRIPT ERROR past 1.2 s; the test swapped in a tiny `Impact` subclass (since replaced by `StageImpact`).
- The sound fade and the scene dim-down used `duration - 1.3`; they now use `T_END - 1.3` (identical at every level but 5) so the lava voice and the dim end with the 12 s cast, not after the pool.
- The pool shows with the existing smaller "smoking crater" pool under it; with the stretched duration the stone craters' scorch and the ash plume last through the pool too.

### Task 10 (Wrath of the Sky, `be108c6c`)

- A cast plays no `UiSound` anywhere (the power's own sounds play), so a recast adds none; the called bolt's own omen and strike sounds are the feedback.
- Level-1 inert: for every other power `recast` is one `live_fx` walk of `_casts` and a `has_method` miss, then `cast()` runs exactly as before.
- The test steps the bare storm 0.15 s past the gathering so the storm's own first volley (told at 5.2 s) falls after the called bolt (5.65 s): the kill at the spot is the called bolt's.
- The route is `Targeting.release()` asking `_rules.recast(slot, _press)` on the plain-click path only, before the plain `cast()`; true returns without `cast_made` (so no `unfocus()` and no `Crowd.on_cast`), and the slot stays focused. `recast` writes neither `_cooldowns`, `_playing` nor `last_cast`.

### Task 11 (Earthshatter, `1f451de8`)

- The brief's dummies "2.0 along" each branch stand only 2*sin(0.6) = 1.13 off the main line, inside the main crack's own fall width (`HALF` 1.3 at level 4, 1.4 at level 5), so the main crack kills them and level 4 could not leave them alive. The test puts them 4.0 along (2.26 off the line, beyond `HALF` at every level, within the branch's 5.0).
- Each branch has its own `walls` dictionary (a building the main crack broke is `destroyed` and skipped anyway). `fell` and `broke` count branch victims too.
- A branch starts at the frame after the main front passes its fork (a frame of delay at most), and the first crawl frame past `T_CRACK` moves a whole frame, as the main crack always did; a branch can finish up to a frame before the computed busy, never after.
- The main crack's `_settle()` still arms the main fissure at its own crawl time; branches arm themselves. The crawl body became `_crawl(run)` with the same calls in the same order, so level 1 is identical; frights, dust, rumble and heat stay on the main crack.

## Open and playtest notes

None of these changes behaviour on a level 1-4 cast, and none blocks landing. Numbers are first guesses.

- **Backwash outer sliver.** The catch's far limit is `lv_length + 5.5`. A person at the splash ring's outer edge (5.0 out) is knocked outward by about 0.56 more before the edge arrives at 0.2 s, which puts them just past 5.5 on the radial line, so the outermost 0.1 of the ring may escape. Not worth a change; watch it in play.
- **Called-bolt preview ring against its kill radius.** The preview ring is Wrath's `AREAS` entry (radius 0.6), but a called bolt kills within `HARD_R.x` 1.6. R14 rules out HUD changes beyond the edge colour, so the ring understates the kill. Watch whether players mis-aim.
- **Called bolts are not heard as casts.** There is no `cast_made`, so the Lantern's Searchlight (which hunts every cast it hears), the Descent's `on_cast` and the town's `on_cast` do not hear them. Each bolt still frightens through `_bolt`. Deliberate (R14); revisit if Called Bolts feel too quiet against the Lantern.
- **Fault Lines branch start inside the main crack.** A branch is 1.13 off the line at 2.0 along, inside the fall width (1.4 at level 5), so only the outer 2.5 units of each branch take anyone new. Harmless double coverage near the fork; it matches R15 as written.
- **Dragon second breath's extra light.** The first cone's `LightField` entry keeps its getter (`_beam_angle()`), so during the second breath both entries sit at the current beam point until the first quad's light fades. Cosmetic, level 5 only, never seen in a real window.
- **Lantern balance.** At level 5 Forked Bolt reliably leaps between adjacent guards (`POST_GAP` 2.4 is less than `FORK_R` 2.5); that is the twist doing its job, but it is a balance point on the Lantern. A fork can also hit a tower a second time within 0.12 s only if someone stands within 0.7 of its footprint (rare, `POST_OUT` 1.0).
- **Lantern `BLOW_MAX` literal.** Now 45.0 on purpose (see above): a level 3-5 Smite deals 55-65 but a blow on a mirror is capped at a level-1 Smite's worth. A mirror still takes two blows at every level. Change the literal, not `SmiteFx.DAMAGE`, if the Lantern is ever retuned.
- **No danger registered for the pool or the drifting pillar.** The Lava Pool and the Wandering Sun's new positions register no crowd danger (R5 keeps `REACH` and `IMPACT` level-free); the town does not flee a pool it cannot see coming. Spec-silent.
- **Other spec-silent points.** Twin funnels are not clamped to the field's bounds (they run straight for 4 s); kills from the pool (to 24 s), called bolts and late twins fall outside `Rules.CAST_GRACE` (4 s), as Wrath's volleys already did.
- **Staged visuals unseen.** The lava pool, the twins' funnels, the receding flood, the second cone and the drifting pillar were only run headless. Look at each in a real window.
- **Parked minors N1-N4** (re-review; none load-bearing):
  - **N1** the Tsunami `_front <= lv_length` check is sampled only after the backwash is over (`_back_front` about 0), so a regression to `_front = _back_front` would pass. Sample it inside the backwash, for example at crash + 0.5.
  - **N2** the `Rules.recast` `finished` and busy-lock guards have no test; removing both leaves every suite green.
  - **N3** `Targeting` edge redraw is untested, and when the focused power has an empty area and the slot is refused, `_draw` returns before it updates `_edge_ready`, so `_process` calls `queue_redraw()` every frame (cheap, draws nothing).
  - **N4** the Cinder "an already-burning house is left alone" case cannot fail: the house is lit at 0.9 and `FireManager.ignite` takes `maxf(current, 0.4)`. Light it below 0.4 (for example 0.2) so a missing skip raises it to 0.4.
- **Process notes.** Task 1's tests were written after its code (no separate RED run); they assert independently typed values, which limits the cost. The engine's `make_current` ERROR line per stage is unchanged and documented in `tests/fx_stage.gd`. Level-1 derived-timing identity (`lv_t_end == T_END`, `duration == 11.5`) rests on the reference set plus the level-3 staged test, not on a direct level-1 assertion for every effect.
