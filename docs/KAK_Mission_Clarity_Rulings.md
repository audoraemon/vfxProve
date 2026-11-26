# KAK Mission Clarity: Rulings

Every judgement call made while building Mission clarity, grouped by task. Each one has the reason and what it costs if it is wrong. They come from the task reports and the commit bodies (`git log da681d26..HEAD`). The summary is in `docs/KAK_Mission_Clarity_Summary.md`.

"Pre-flight" means `.superpowers/sdd/clarity/preflight.md`. Its rulings (B1-B2, I1-I13, M1-M15) are binding (R0 below).

## Controller rulings (R0-R3)

- **R0. The pre-flight is accepted.** Every Ruling in the pre-flight is binding. Key ones: B1 (never tell the player to "scare" a soldier target: ordinary loud casts do not frighten soldiers). B2 (the test kit casts the real power through `Rules.cast()` or the director's own hooks, never `p.panic()` or `p.lure()` shortcuts, so a test cannot pass on a false claim). I6 (a multi-verb power: a cast that counted never also banners). I8 (`why_not()` snapshots and restores the crowd RNG state, or provably draws none). I9 (shared test files split per group in Task 2).
- **R1. Scheduling.** Tasks 1 then 2 in one worktree. Tasks 3-8 in parallel worktrees off the merged groundwork. Task 9 last, then the final review, one fix wave, and landing. References never move: a moved row is a bug, not a re-record.
- **R2. Task 1+2 review (54be045f).** `test_mission_steps` `_advance` dispatches one `_advance_<group>()` per group, and each task adds its missions inside its own group's function only. `ClarityKit.snapshot()` covers buildings (hp, destroyed, scorch) and power cooldowns, so `assert_read_only` must pass for every director a task touches. Kit lure, confuse and hold go through the person calls: for each of those verbs a group's hints promise, one test casts the real power through the kit's real path (`Rules.cast` with the power's own fx) on that mission's target.
- **R3. Parallel phase under load (Tasks 3-8).** The machine ran about 45 Godot processes from other sessions. Each task ran its focused suites and its own missions' references, with no full suite and no FLOW. The controller runs both after the merge. Frame-time failures ("test_pale", "decree_cage", "inside", "horde", "tide") are load flakes: list them, do not chase them.

## Task 1: verbs and the legend's third page (68134a1d)

- Ember is not a Kill power. Its fx only lights a building and has no path that kills a person. The fire is the town's. Kill is the strike, fire (dragon, cinder) and death families but guise and ember, plus doom, hellspark, houndgate, breath and cage. If wrong, a Kill step for Ember is dropped and Task 2's Kit shows it.
- Scare's legend words read "citizens run from a loud power near them" (B1). Soldiers are not frightened by ordinary loud casts. If wrong, the legend under-promises.
- The Kill list is 30 keys, and every one's fx file mentions kill, die or dead (tested).
- The legend's "does" line for Hold is shortened to "the god's hand on a mind: they drop their task" so one line fits.

## Task 2: why-not hook, gate, phases and the test kit (4f76415b, 54be045f)

- `apply("scare")` frightens through `Crowd.on_cast` for Smite at KILL_R + 0.5 from the target, then runs past the impact. It never uses `p.panic()` (B1, I13). A soldier test would otherwise pass on a claim the game makes false.
- `apply()` casts through `Rules.cast()`: the key joins the loadout, and the caster hands back a `NoLeaveFx` or `BellLiesFx` so `last_fx()` is real. A refused cast is still emitted and flagged `s.refused` (B2). A verb is dropped only after a failing case on these paths.
- Lure uses a light 1.5 from the target (or `s.light`), and the case reads `s.took`, because a man on duty refuses a lure (B2).
- `_resolve` unions `hint_phases()` over every def that plays an id (I11). A Feast plays its act's director. Starfall adds stars, running and waiting. A city twin shares the base's phases, and the check asserts its steps equal the base's instead of building city directors. Building them runs the town override tune on a director that is not set up.
- The stub group suites carry one placeholder check, because the runner counts a suite with no checks as a failure. Each group task replaced its own.
- The commit trailer says "Claude Sonnet 5.5" where the implementer brief says "Opus 5.5". The controller may amend.

## Task 3: assassinate group (99b711b4, fix 3c83d772)

- The Informer waiting hint says "A companion you scare off walks back" and drops "lure". A lure never takes on a companion on duty (`Person.lure` refuses DUTY). One verb is not offered.
- The Informer why-nots follow pre-flight I1: before word, only scare, lead, lure and confuse on the contact or company give TOO EARLY. Banish and Kill say nothing. I1 is binding. (The controller later changed this for one case: see the fix below.)
- Fix 3c83d772: before word nothing turns the contact. A Skylift on him only sets him down to walk back, so the banner now says TOO EARLY. A lift on his company still says nothing (I1: it clears the way). Read-only, no rule moves.
- The Tax Collector gets a new `ready` phase (hint_phase only, no reference moves) with a step and a hint (I2). If wrong, the countdown is off in the first 35 s.
- The Tax `inside` hint names no (blue) guards and no burning. Guard tags are not drawn while he is indoors. Burning the house only drives him out in a panic, which is not a count.
- HE IS INDOORS is for a collector visiting or hiding only, and never for Burn or Strike keys. A waiting collector is smoked out by a cast at the door (the director's own handler), and a burn or blow may bring the house down.
- Tax Seal banners: SEAL A DOOR HE WENT IN AT; TOO SOON - SEAL AS HE COMES OUT (I12); HIS GUARD (BLUE) STOPS THE MOB (a guard at the door while he is inside, or near him outside).
- The Expel captain hint adds "while he walks". A fright counts only while he is walking (hiding and fleeing ignore it).
- STILL SHAKEN is judged against `_fright_wait > PowerBook.impact(key)`, since the count is made when the danger lands. One banner may be off by under a second.
- Expel constants are renamed with the `EI_WHY_` prefix (C2 prefix rule).
- "Walks back" is proved by the scare taking, the fright cleared and the person's own `_recover`, then the director re-posting him. A scared citizen stands in SHELTER in the headless world, so this is weaker than watching the walk.
- Tests ask `why_not` before the impact for Expel frights, because the HUD asks at cast time.

## Task 4: convert and rite group (7ff879e5)

- Colours are checked by a local `_name_of` (the nearest of the five legend colours within 70, not the kit's 40). Wren's cyan, the flame and lantern gold, and the poor's pale gold are drawn a shade off the legend. The kit would call them uncoloured.
- Houses, wells and shrines are "(gold)". The doorway has no colour word (I3). Orange stays for the checkpoint, Mira's shrine and believers.
- The Vigil "" step names the acolytes with no colour and says "lead or confuse them off". "Wren (blue)" appears only from the "wren" phase (I4): before he comes, no red or blue tag is drawn. A held acolyte still sees, and only a whisper or Discord blinds him. The "" step counts down to Wren.
- The Relic Run watch says "lead, confuse or kill", not "Hold" (I4). An oath stops the watch but a lure does not, and the word Hold names both. A player with only Oathbound is under-told, and nothing false is said.
- The First Taste drag says "Hold or kill the Watch", not "scare" (B1). The Watch are soldiers. The march and the cleanse keep "kill or scare" because the marchers are clergy citizens, and the cases prove `Crowd.on_cast` frightens them.
- Broken Lanterns' bearer is "lead the flame-bearer away". Measured with a broken lantern 5 units from him and a 22 s run: left alone he relights it at 2.3 s. Killed (an acolyte takes the flame), 2.9 s. Held by a compel, 8.8 s. Confused, 17.6 s. A lure is refused (he is on duty). Only a Lead 6 units away keeps him off the whole drain. So only "lead" is promised.
- The Knights hint says "kill him, or lead him away". A Wisp does not take a soldier at his post (`Person.lure()` refuses the POST mind). A Confuse or compel leaves him at the lantern, which is the banner's claim.
- The Relic Run `citadel` step is "The relic is lost at the Citadel" (Q6, settled by the test). Past the last halt no halt ever begins, so Pip cannot board even at a cart stood by its three dead hands. The step opens with no vocabulary verb and has no counter. Pre-flight minor 10 allows the exception. The dead end stays until you decide on a rule change.
- The clause "A lure draws them only once Pip follows you" stays in `relic_run.watched`, with a case and a why-not. It is the one place the Hold word's lure half is true.
- Lures and compels are judged by who stands in their reach, not by the state they leave. A cast is announced (`cast_made`) before its effect lands, except a Mind Whisper (`_whispered_at`). A whisper at the spot a person already stands on has no goal, so the destination falls back to his position (I7).
- Mira's "HELD, HE STILL SEES - CONFUSE HIM" speaks only for a key whose verbs are exactly [hold] (a compel). A lure on a Faithful at the door is refused (he is on duty). Mira's, First Prayers' and The Sermon's sentries share it.
- TOO FAR TO PULL THE FAITHFUL (First Prayers) fires when no building within FIRE_PULL of the door is reached, one or more lie beyond, and a Faithful watches (I7).
- Kept lines that named a vocabulary verb loosely were rewritten (I10). "Ascend, or hold until dawn" is now "Ascend, or wait for dawn". "Stop him" in the report and bell lines is "Kill him". "Remove them first" (Sermon) is "Lead, confuse or kill them first".
- First Prayers' "{n}" is 0 when no walker is due, so the line reads "the next sets out in 0 s". True but empty, a cosmetic zero for a few seconds.
- The commit trailer says Sonnet 5.5 where the brief says Opus 5.5.

## Task 5: intercept group (bf6e025c)

- "Strike" on people becomes Kill or Scare (warning.relay, bell_ringers.relay, festival.packed "scare them there and one cast breaks many", market_panic.open) (I10). If wrong, coverage demands a strike case.
- No step or hint tells the player to scare a soldier. Starfall's postern watchman gets no "keeps the warning" banner for a fright, because it takes him out through the postern key (W3). If wrong, a false banner.
- Lure on a Market Panic warden is judged by the real rule. Wardens stand CALM, so a light within GUARD_REACH leaves him on guard (STANDS FAST), and a farther one draws him off (no banner).
- Starfall and Bell-Ringers aggregate over every warning out: any cast that could stop one says nothing (review focus 3).
- The warning "waiting" step keeps the n/m counter, because the NEXT STAR tag counts down. If wrong, no clock on that step.
- Bell-Ringers' "Lead or lure his mates off" means off past DOOM_WITNESS. A lured or led mate stands his goal away. A mate lured but within sight panics at a seen kill. A lure reaches a mate only within 3, so the light goes just beyond him.
- Silence's mates are held, not confused (`_could_carry`), so the Witness gets no confused-mate banner.

## Task 6: hunt group (57d96bb5)

- No step or hint names Lure for the hunts. A hunt guard or wright is on DUTY and refuses a lure (no `answers_lure`), so the plan's "lure far" row and the spec's "Lure ... HELD" banner never fire. The held banner is judged on `held_by_god()` and fires for a compel only. A banner "HELD" on a refused lure would be false.
- Break the Hunt's Kill-on-a-guarded-bearer banner is not added. The escort who takes the standard up already banners THE STANDARD IS TAKEN UP, and a second banner would double up. One fewer cause of the two the plan lists.
- "Be at the captain's road" replaces the spec's "Be on ..." (opener rule, pre-flight M10).
- The guarded hints say "stand over" in place of "hold", because "hold" is a vocabulary verb with no case.
- Break the Hunt's Scare is true once the new bearer's 5 s steadiness has run, so the carried-phase scare case waits it out. The text stays "Kill or scare him too". A scare in the first 5 s does nothing, silently.
- The mission's own ("") hint names the standard (gold), which is raised only at 0:45. Its colours are checked in the guarded world. This wording was already there.
- The commit trailer says Sonnet 5.5 where the brief says Opus 5.5.

## Task 7: escort group (c7f6ffe5)

- Prisoner, Exodus and Hide's searchers use "Lead, scare or kill" (or "Lead or kill") instead of "Hold". Pre-flight I4 names the Prisoner. Lay watchmen stay on watch while lured (OBSERVE in POST_MINDS), and Hold includes the lure powers. Applied to Exodus and Hide trail for the same reason. The copy is slightly less like the spec.
- No "scare" on soldiers (Lamb captor, patrols and watch, Hide watch, Face escorts) (B1).
- Face's "STILL GUARDED - HOLD MORE ESCORTS" has fixed text, no count. The gate keys on text (minor 4) and the hint says "two of three". No live count.
- Exodus and Hide have no why-not. A whisper on a follower or a self-walking believer is not ignored by the code: he walks where sent, and the walk resumes. The spec says a banner only if ignored. A wasted whisper has no banner.
- The Lamb Wisp banner cause is "beyond WISP_HAND" (I5), not CHARGE_LURE_R. Death Mark and Windfall get none.
- Lamb `led`'s hint keeps "holds". Vague verbs ("Send", "Clear", "Remove", "Stop") are replaced with phase verbs (I10).
- `prisoner.bound` keeps "one left seizes her for the Citadel", because test_prisoner pins it.
- The Face gaze step is "Hold the escort (red), kill none" (`named_in` skips "kill none").
- Test note: headless Person movement needs explicit ticks, so the Exodus "household follows" case moves the lamp with `Kit.arrive`, as test_exodus does.

## Task 8: raze group (8f773612)

- The Harvest `watchman` phase drops "Scare" (step "Kill or lead the watchman (red)"). A watchman at a burning granary has `fearless_left = HOLD_POST`, so a fright does not move him, and the Kit proof failed. The `""` and `empty` phases keep "scare" (proved). If wrong, one verb is missing in one phase.
- The `""` hints of Crown's Bread, Armoury and Heart drop "(gold)". At "" no target is gold (all grey, not in use), and the colour check requires every colour word to be a tag drawn in that phase. The spec's "keep" would fail its own test. One colour cue fewer in an overview line. Crown's Bread's `""` hint says "Kill or lead ... burn or strike it down while it is in use ... (strike only)".
- "Clear" and "Remove" (I10) are rewritten to the phase's verbs. Harvest `empty` says "scare, lead or kill its watchmen (red) just before". Crown's Bread `""` and `engineers` say "Kill, lead, confuse or scare every one first". Lines get longer.
- Crown's Bread `not_yet` step is "Kill or lead its engineers (red)" with seconds (spec). The `engineers` step is the same with a count. The hint lists confuse and scare as well (both proved).
- Lines of the mission's own phase `""` (the whole loop) have their verbs proved where they count (for example burn and strike at "" proved in the `open` world and recorded for both phases).
- Rot gives no why-not in Harvest. `BlightFx` already banners NO GRAIN TO ROT YET and THEIR WATCH KEEPS IT, and a second banner would double (pre-flight minor 3). Burn gets NO GRAIN YET - THE FIRE GOES OUT.
- LURED, HE STILL WATCHES IT and LURED, HE STILL MENDS IT are gated on `Person.lured()` and `_on_guard()` (pre-flight minor 7). A lure that was refused says nothing. Armoury and Heart have no lure banner: a lured man there is `held_by_god()` and leaves guard (the lure counts as Hold). If wrong, a missed banner.
- A why-not is "" when the cast `_may_kill()` any of the target's guards (I6). A Smite aimed at a building beside its Knights may have killed one, which counts. The tests aim strikes at the footprint point farthest from the men (`_aim`). If wrong, a silent cast near guards.
- KILLING THE CARTER SPOILS NOTHING needs a fallen carter within the kill radius and no watchman within it.
- Judgement (the Long Night act) shares Last Judgement's copy and phases. Its cases are recorded from the Last Judgement world (`JudgementDirector extends LastJudgementDirector`, same `hint_phases()`). If wrong, an act-only gap.
- `fallen` proofs: the Citadel is brought down by `_fall()` (a real fall needs thousands of budgeted blows). Stability part drops are asserted for a kill (population) and a burned house (infrastructure).
