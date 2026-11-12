# KAK Dominion Ability Levels: every ruling

The Dominion ability levels milestone (five levels and a level-5 twist for each of Dominion's ten powers) was built subagent-driven on `god/dominion-levels` on 2026-11-09, landing on `feat/god-progression`: a groundwork task, ten twist tasks in three parallel tracks, an opus final review with one fix wave, and this note. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each entry has what was decided and why; where the controller gave a cost-if-wrong, it is kept. The spec is `docs/superpowers/specs/2026-11-09-kak-dominion-ability-levels-design.md`, the plan `docs/superpowers/plans/2026-11-09-kak-dominion-ability-levels.md`, the summary `docs/KAK_God_Dominion_Levels_Summary.md`.

Groups, in order: the plan's rulings D1-D18, the controller's rulings, the rulings each task reported (T1-T11), the final review and fix wave, then the open and playtest notes. Where two disagree, the later one wins. The user approved the spec ("Ok let's do it") and made one ruling of their own: Clear Mind's twist is Sleepwalk, not Forgetting (D12). Every number in the tables is a first guess, to tune in play.

Task 12 (this note) reported no rulings of its own.

## The plan's rulings D1-D18

- **D1 Tables.** Stat keys are the effect's const names exactly; the cooldown key is `"cooldown"` (Ruin R2). Divine Schism has no `"cooldown"` key (999, once a night, as Tempest). Wisp's ENTHRALL keeps 75 s through `PowerBook.mode_cooldown()`, which `Rules.cast()` already prefers, so it has no table key. Cost if wrong: none.
- **D2 No Might in the tables** (Ruin R3). `PowerBook.might(key, level)` equals the spec's Might column for all ten; a test proves it, and Voice 7 + Schism 8 = 15 sits under the cap of 16.
- **D3 COMMAND_X.** `VoiceOfGodFx` gains `const COMMAND_X := 1.0`. Each cast's seconds are `float(COMMANDS[command]) * lv_command_x`. `COMMANDS` is unchanged, and `x * 1.0 == x` exactly, so level 1 is today.
- **D4 Whisper's REACH is read where the walk is clamped:** `Targeting.release()` (through `MindWhisperFx.clamp_to(grid, from, to, reach := REACH)`) and the aim line `_whisper_line`. The effect never clamps itself, because `extra.to` is already clamped. Cost if wrong: a scripted level-5 whisper sent past 10 is not clamped by the effect, as today.
- **D5 Previews follow the level** (Ruin R5/R5a). `Targeting.AREA_STATS` gains discord `DISCORD_R`, madness `RADIUS`, clearmind `RADIUS`, anathema `RADIUS`, sanctuary `PICK_R`; the "who would be taken" ringing passes the level's numbers to `taken`, `victims_at`, `drawn`, `picked_at` and `marked_at`. Saint's `PICK_R`, Wisp's ring and lure reach, and the Voice and Schism areas have no levelled stat and stay.
- **D6 STAT_LABELS** gain: walk reach, attack, circle, forgetting, starting madness, lure cap, lure time, enthrall, trance, span, guards, guard reach, district (`anathema.RADIUS`), command length, gather cap, region, fighters, length. Ruin's tree text must not change (its tests pin it).
- **D7 Twist texts** (each checked against the tree's detail width): Held String "whisper the same one again"; Tangled Threads "forgetting spreads one hop"; Directed Frenzy "the broken hunt soldiers"; Procession "click again to lead the light"; Sleepwalk "click again to walk the entranced"; Passed Mark "the mark outlives its bearer"; Pressed into Service "intruders guard"; Spreading Mark "spreads to buildings near"; Second Word "click again for a second command"; Turn the Tide "click a fighter to turn them". The wording was the planner's call.
- **D8 Held String.** A level-5 whisper (walk, attack or burn) leaves no shake-off when it wears off: `Person._wake()` sets `_shaken_left = 0.0` instead of `SHAKE_OFF` for a person a level-5 whisper holds. The 20 s therefore counts from when the whisper wears off, not from the cast. Why: a walk of 14 plus the 8 s linger outlasts 20 s from the cast, so a window from the cast would rarely be usable. Cost if wrong: the twist is a little more generous than the spec meant. The cooldown applies (it is a normal cast); a later level 1-4 whisper on the same person clears the flag.
- **D9 Tangled Threads.** For `TANGLE_TIME` 5.0 s after the cast, every 0.1 s: anyone alive, in the open, not `resists_mind()`, not already touched by this cast, within `TANGLE_R` 1.0 of a person this cast confused who is still confused, is confused for the full forgetting time and recorded as caught. The caught pass nothing on. Soldiers too. At level 5 `duration = TANGLE_TIME + 0.2`; `busy` stays 0.6.
- **D10 Directed Frenzy.** A directed person who reaches Broken skips the outcome roll (panic is excluded too: the spec says "everyone ... goes into frenzy"), screams, then frenzies as today. At the frenzy they `fight()` the nearest living soldier in the open within `Person.FIGHT_SIGHT` (tie: field order), else `fight(null, ...)` as today. Once that soldier is down the frenzy goes on under its ANYONE rule. Only the cast's seeds are directed; spreads through `afflict()` are not.
- **D11 Procession.** True at level 5 while the light burns (`t < duration - 1.0`), any number of times, each click replacing the destination. `light_at` is set to `origin` at the top of `_build()` (a member initialiser runs before `origin`). The light drifts at `PROCESSION_SPEED` = a walk (0.6 u/s), never past the spot. LURE: each lured person keeps its offset from the light and is re-sent to `light_at + offset` every 0.5 s while the light moves, and once when it stops, through `Person.relure()`. ENTHRALL: the spots and the held shift with the light, and newcomers are taken round `light_at`. At levels 1-4 `light_at == origin` throughout.
- **D12 Sleepwalk** (the user's pick, replacing Forgetting). True at level 5 while the trance holds and someone entranced is alive and in the open; any number of times, each click re-sending everyone entranced at that moment (later joiners wait for the next click). Each walks calmly to a spot of its own at the click (`CongregationFx.spots_for`, no rng; any past the spots stand at the place), by a generic `compel`, so no Person hook is needed. The trance itself is untouched, so they still sense nothing. The circle and its joining stay at `origin`. Cost if wrong: the walk is absolute, so nothing breaks it (the trance already ignores danger).
- **D13 Passed Mark (SINNER).** Once, the first frame the chosen is dead: the mark goes to the nearest living person in the open within `PASS_R` 3.0 of where they fell who is not one of the mob. Why: the mob stands round the chosen, so the nearest is nearly always a hunter, and a mob turning on its own is not the god's steer. Cost if wrong: the jump lands on a bystander rather than a hunter. Every living mob member is set on the new chosen. Nobody in reach: nothing.
- **D14 Passed Mark (SAINT).** "Strikes" uses today's detection (a foe within `GUARD_R` fighting the chosen). The cap `GUARDS_PER_THREAT` is lifted to every guard not already fighting. Cost if wrong: guards answer an intent, not a blow, as today.
- **D15 Pressed into Service.** "Driven out" is the moment a guard lets go because its quarry, alive, is outside the wall. That quarry, unless already a guard or `resists_mind()`, and while there is room, joins: appended to `guards` and its place appended to `places` (the two arrays stay index for index), the place being the point on the wall nearest them (`wall_spot`). It is posted for what is left of the span, wears the SHIELD, and is counted in `pressed`. Soldiers too.
- **D16 Spreading Mark.** At `T_CAST + SPREAD_AT` (20.0), every standing building of a marked role, not already marked by this cast, whose footprint lies within `SPREAD_R` 3.0 of an original's footprint (`footprint.grow(3.0).intersects(...)`) is marked for the rest of the span. Once; the spread ones do not spread. The Citadel's role is not in `MARKED`. Hallowed: citizens near a newly marked building are sent in as the lay path does.
- **D17 Second Word.** True at level 5, once per cast, while the first command holds (after the busy lock), with `extra.mode` the Q/E command shown. JUDGE needs someone at the click. When the first ends, everyone the first reached who is alive and in the open takes the second at once, for `COMMANDS[second] * lv_command_x`; its place is the follow-up click. **No rng, and the level-1 stream unchanged:** `_command(p, cmd, place, secs, t0, scatter := true)` keeps today's two rng draws (FLEE on a person exactly on the click, GATHER past the spots) on the `scatter` path; the first command always passes `true`, the second `false` (FLEE from the click's own spot runs `Vector2.RIGHT`; GATHER overflow stands at the place). A test asserts the rng state is the same before and after the second command is laid. `duration` becomes `T_SPEAK + seconds + seconds2 + 1.0`; `busy` is unchanged.
- **D18 Turn the Tide.** True at level 5 while `T_BREAK + 1.0 <= t < T_BREAK + lv_duration`, mode not TUMULT, fewer than `MAX_TURNS` (10) used, and a member (alive, not inside) stands within `TURN_PICK` 1.0 of the click (the nearest; tie field order). The move goes through the same code as `_enlist()`, factored into `_lay_side(p, s, left)` with level 1 identical. For PURGE a citizen turned onto the condemned side runs, and a condemned one turned back fights.

Plan-wide rules that act as rulings (from the plan's Global Constraints): level 1 equals today bit for bit (a table's level-1 value keeps its const's type; a derived number uses the const's own expression; a static helper gains a trailing parameter defaulted to the const, and no caller outside Targeting passes a level); twist code is gated before any `ctx.rng` call, `at()` scheduling or field call; no twist uses a random roll; ties go to distance, then field order; per-instance stat vars are `lv_<const>`; no PixelLab.

## The shared follow-up mechanism

The plan decided one way for a live cast to take an order, by generalising Ruin's Called Bolts: select the slot again and click; `Rules.recast`, `can_recast` and `follow_up_area` call the effect's `follow_up`, `can_follow_up` and `follow_up_area`; the click starts no cooldown, sends no `cast_made`, and is refused under any busy lock or after the run. Held String is not a follow-up (D8). The full text is in the plan.

## Controller rulings (`rulings.md` and `progress.md`)

- **C1** (2026-11-09): Clear Mind's twist is Sleepwalk (the user's pick). Any plan text about Forgetting is void.
- **Gate.** This milestone has no missions. The gate per task is: focused tests green, level 1 moves no reference (digest, crowd_check and the rows the plan names), and the full suite before commit where the machine allowed.
- **One implementer per track, one review per track.** Tracks A (Tasks 2, 3, 4), B (5, 6, 10, 11) and C (7, 8, 9) each ran serial inside; one sonnet review covered each track instead of one per task. Cost if wrong: a bad task found only in the final review.
- **Leave the ENTHRALL scan as it is.** `enthralled()` takes people other powers have compelled; that is level-1 behaviour (the latest power wins), outside the twist's scope, and changing it could move references. Cost if wrong: a Procession light walking into a Voice crowd takes them, as a level-1 ENTHRALL cast there already does today.
- **Trailers.** The track commits carried the session's Sonnet trailer and were cherry-picked onto `god/dominion-levels` with the trailer changed to Opus.
- **Landing target.** Local `feat/god-progression` moved while the work ran (first `554bcdc1`, then `4c911917`; only `play_dev.bat` changed). Rebase or merge onto the tip at landing, after a fetch.
- **Task 1 review disposition.** Approved. Its Minors were parked: a duplicated sanctuary `picked_at` call in Targeting (M1), `follow_up_area` read every frame (M2), directors use the level-1 consts (M3, conservative), the Clear Mind radius test (M4), and a guard in the skill tree (M5).
- **Track reviews.** A: Tasks 2-4 approved. B: Tasks 6, 10, 11 approved; Task 5 needed a fix (below). C: Tasks 7 and 9 needed fixes (below); Task 8 approved. Track fix rounds were re-reviewed and approved.

## Rulings the tasks reported

### Task 1 (groundwork, `1d57a0b7`)

- `Rules.follow_up_area(slot)` returns `{}` unless `can_recast(slot)`, so a closed follow-up never changes a preview.
- The HUD redraw signature gets an "f" suffix only while a slot can take a follow-up, so no level-1 string changes.
- The commit trailer used the session's attribution line (later changed to Opus).

### Task 2 (Whisper, `e07ed947`)

- No ruling reported. Held String is checked on the real route: a level-5 whisper is not shaken after it wears off, the cooldown still runs, a level 4 whisper is refused "shaken", and a level-5 then level-4 whisper shakes again.

### Task 3 (Discord, `d4e9f407`)

- No ruling reported. The level-1 path is unchanged apart from keeping the taken list.

### Task 4 (Madness, `92953fba`)

- The level-4 rng check compares a live level-1 run, not a recorded number.
- The nearest-soldier choice is checked right after the manager step, because ANYONE retargets at once.

### Task 5 (Wisp, `5e1b59db`)

- `Person.redirect()` was added (not in the plan). Without it a walker re-sent every 0.5 s hardly advanced, because each fresh path starts at the centre of the walker's own cell.
- Held and lured people are re-sent on the 0.5 s cadence from the light's position at that moment, so the goal lags the light by at most 0.3.
- The tests run in an open patch of the town (`_arena()`) with `pace = 1.0`: the market square is cluttered and each person has its own pace, so walks there proved nothing.

### Task 6 (Clear Mind, `dd2f8f5d`)

- A person compelled by another power (not one of this cast's walkers) is not sent, so Sleepwalk never steals someone Voice or Wisp holds.
- The arrival check is 0.6, not the plan's 0.5: a walker stops inside `GOAL_REACH` 0.45, and one stopped at 0.50.

### Task 7 (Saint, `cb6d82fc`)

- The pass is split out of `_fx_process`'s combined early return, so the level 1-4 order of checks and calls is unchanged.

### Task 8 (Sanctuary, `dedcdcf7`)

- `wall_spot` is a static: a circle uses `centre + dir * CIRCLE_R` (a centre falls to RIGHT); a rect uses the nearest border point, pushing an inside point to the nearest side.

### Task 9 (Anathema, `4704019d`)

- `_gather(among, folk)` and `_show(s, life)` were factored out so the spread reuses the lay path; level 1 calls them with the same arguments in the same order.
- "Within 3" is a box-gap test (the final review notes it can reach about 4.2 on a diagonal; D16 prescribes it).

### Task 10 (Voice, `4610bfaa`)

- The second word's full seconds start when it is laid (`t0 = t`), so a person holds for exactly the second command's seconds.
- The second word is not added to `_reached` (no new threads) and does not count in `obeyed`.
- `_command` gained the `scatter` parameter (D17); the track review called it a justified addition.

### Task 11 (Schism, `06f707ae`)

- A turned fighter is `stop_fighting()`-ed first so it returns to a clean state before the new side's fight is laid. (The track review noted this does nothing for a running citizen, since `stop_fighting()` returns unless the mind is FIGHT. Harmless: `fight()` overrides.)
- `_enlist` was split into `_enlist` and `_lay_side`; the only reordering is `counts[s] += 1` before the sparkle burst, a visual.

## Track review fixes

- **Task 5, Procession** (`8fbb3dd0`): `_regoal` re-anchored every held person with no ownership test, so a person Voice or Clear Mind had since compelled was walked away from its order. Now a held person whose anchor is no longer ours is dropped from `_held`, put in `_skipped` (so the scan does not retake them) and left alone. Also: `redirect()` returns for ASLEEP; Sleepwalk's `_sendable` counts a walker only while its anchor is still ours; the Voice test asserts the dead person is untouched.
- **Task 7, Passed Mark** (`587c3a59`): the "passed once" test could not fail (no bystander in reach of the second death). A third bystander was added, and the test goes red without the guard. The leaked first scene and an unused variable were removed, and the guard cap was hoisted out of the loop.
- **Task 9, Spreading Mark** (`587c3a59`): the HALLOWED spread did not skip people indoors, unlike the lay path. It does now, with a test; a destroyed original no longer spreads.

## Final review and fix wave

The opus final review (`463d4885..8fbb3dd0`, 13 commits) said "with fixes": one Important and several Minors. The fix wave (`375f4888`) landed these:

- **Important 1: a half-placed two-click aim was stranded.** During Schism's busy lock a click sets `placed`; when the lock ended the slot aimed as a plain click, and `placed` stayed set. After the follow-up closed, the next click would be read as the second click of the old placement (after a Divine Surge, a real CUSTOM Schism from a stale point). Now a click taken by `recast` clears `placed`. Test: `test_follow_up._stranded`, red without the fix.
- **Minor 1: a Sinner mark could pass with no mob.** If the chosen died before `_decide`, the pass still ran and a bystander wore the noose with no hunters. `_pass_mark` now needs `hunters > 0`. Test in the saint twist suite.
- **Minor 3: a missed follow-up showed the wrong reason.** A Tide click that finds no fighter (or a Judge second word with nobody near) fell through to `cast()` and was refused as "cooldown". While `can_recast(slot)` is true, a failed follow-up is now refused and never reaches `cast()`. This also closes the misfire half of Minor 2. Its reason is "missed", with the banner "NOTHING THERE TO COMMAND" (the fix-wave re-review: "nobody" showed the Whisper's "NO ONE TO WHISPER TO" for every power).
- **Minor 6: Procession re-pathed every held person every 0.5 s** (one A* each, up to about 240 for an ENTHRALL ring). Every held spot still updates each tick, but only one slice in `REGOAL_SLICES` (4) is re-pathed per tick, and all of them on arrival. No dedicated test (no hook to count paths); the wisp suites stay green. **Needs the landing profile.**
- **Minor 7: a second-word RETURN left people where they were.** For anyone without a home or post, the anchor was the first command's compel spot. `voice_of_god.gd` now caches `_homes[p] = p.anchor` before the first command lays, and RETURN uses it. Test `_return`.

References after the wave: `digest` `61267b7e...` and `crowd_check` `-935602679` unchanged.

## Plan deviations (confirmed as intentional)

- `Person.redirect()` is not in the plan. It is reached only from `relure()` and Wisp's ENTHRALL `_regoal`, both level 5 only, so level 1 cannot change.
- Schism's `follow_up` calls `stop_fighting()` before `_lay_side`: harmless.
- Clear Mind's `_sendable` skips people another power has compelled, and Wisp's `_regoal` drops and skips them: stricter than D11 and D12, and an improvement.
- The plan asked for a recorded level-4 `ctx.rng.state` literal in each twist test. Most do not have one: Madness compares against a live level-1 run, Saint and Voice compare before and after, and the other seven have no rng check. No twist draws rng (verified by reading), so this is a test-strength gap, not a defect; the references at landing are the real proof.
- The tracks' full suites printed no result for part 3 under load; those suites were rerun in slices or one by one, all `failures=0`. The merged tree has not had the full suite, all references or FLOW yet.

## Open and playtest notes

- **After a Divine Surge, a live level-5 follow-up power swallows clicks** (final review Minor 2). Surge resets every cooldown, but while a Procession light burns every click on the Wisp slot is a follow-up, so a fresh Wisp cannot be cast. Rare (once a mission, level 5 only) and the same shape as Called Bolts. Accepted; revisit if a playtest hits it. (The misfire half, a missed Tide click casting for real, was fixed.)
- **Some previews do not show the real place or numbers** (Minor 4). Sleepwalk previews a 1.0 circle at the cursor, but the walk snaps to a building centre within 0.6 of the click (rarely far). Voice's second GATHER uses the Voice's own preview, which shows no level-scaled gather area. Both cosmetic.
- **Level-4 rng literals are mostly absent** (Minor 5). Optional to add; the references cover level 1.
- **Parked minors** (Minor 8): pressed guards get no link to the site and raise the `spare` budget (`guards.size()` grows); `Person.redirect()` has no direct unit test (it is covered by the Wisp walk tests); Saint's new links leave the old ones on the dead chosen; the Clear Mind walk tolerance in the test is 0.6 against the plan's 0.5.
- **Other items the track reviews noted and left:** Procession accepts any point (unwalkable or off the map; people go to the nearest walkable spot); skipping the first waypoint in `redirect()` can in theory clip a corner on a diagonal step (the movement code slides); Spreading Mark can overwrite a mark another live Anathema laid (today's lay does the same inside its district).
- **Set aside by the final review as consistent with today:** Sleepwalk and Voice's second word wake Curfew sleepers (every existing `compel` does); Voice's second word re-compels people another power took during the first command (latest power wins); the ENTHRALL scan takes people other powers compelled (the controller's ruling above); Sanctuary's pressing overrides a person another power holds, as the original pick does.
- **Playtest, to eyeball:** a level-5 Mind Whisper card on the Prepare screen (the longest shape plus the twist line; geometry says it fits, ~60 px of shape plus 12-24 px of twist against a panel end of 314, but it was not checked on screen); a full-ring ENTHRALL Procession for frame cost; the gold card cue and gold preview edge for each of the four follow-ups; whether the follow-up waits (Wisp 1.0 s, Clear Mind 0.9 s, Voice 2.6 s, Schism 2.8 s) feel like a delay; Held String's generosity (D8); and all twist numbers. No twist has been seen in a real window.
- **Landing checks still to run on the merged tree:** import; the full suite in 6 parts (six `failures=0`); every reference row in `--only=` runs under 10 minutes (all OK but the pre-existing `bread_play_3`, `-133947279`; `digest` `61267b7e90524d800bf1c3473a71146b` and `crowd_check` `-935602679` unchanged; no row re-recorded); FLOW alone on a quiet machine (`209/0`). Then land on `feat/god-progression` with `check-before-every-merge`.
