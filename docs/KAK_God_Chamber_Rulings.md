# KAK God's Chamber: rulings

Decisions the controller took while building the God's Chamber branch (`feat/god-chamber`) without asking, each with its reason and what it costs if wrong.
They are copied from the build ledgers, in the order they were made. Rework any that is wrong.

## Open decision for the user

- Spec decision 2 (Last Judgement and the Long Night's Act III in the Capital: count the old town only if the scripted play wins fewer than 2 of 3) was NOT applied. The scripted play loses by the 50-escape limit in both towns (Aldermere too), so the stability area cannot change the result. In the Capital the limit comes about 25% sooner (40-47 s against 55-58 s); Act III is 0 of 9 against Aldermere's 1 of 9. A lever would be an escape limit by population; the spec forbids tuning it.

## Play-test items

- Market Panic route b in the Capital (parked at 2 of 3).
- Procession: seed 2 wins in 49 s (luck smell).
- Armoury: stage 3 on route b is easier (0.50x).
- Sermon: placed in the far south-west; route a 2 of 3 with zero margin.
- Relic Run: toll case 2 of 3 (Aldermere 3 of 3); idle 53 s.
- Last Judgement and the Long Night's Act III: see the open decision.
- Lantern's Eye: one guard post stands 0.5 beyond the wall at the north tower.
- Exodus: route a and b 2 of 3; the east household is seized at the harbour gate's watch.
- Heart of Faith: the oil-house is the far west house.
- Moved spots and cameras in general; the Vigil Flame shrine's look; the DEV tab's paging.

## God's Chamber (milestone 1)

- Ruling: whole-suite per task is deferred to one run on a quiet machine before the final review — machine loaded by another session, parts time out — a regression in an untouched suite is found later, not per task
- Ruling: Task 3 complete with FLOW/probe/suite gate carried to the quiet-machine run before the final review — reviewer traced every hub call FLOW and the probe make onto GodChamber — if FLOW fails for a real reason it is found one task late.

## World Map and Conquer Progress

- Ruling: full refs_check + FLOW deferred to one run after Task 6 (machine loaded; refs are board-mission rows, conquest only set on Endless nights) — cost if wrong: a moved reference found late.
- Ruling: `converts` lives in result.conquest (not top level of bank's result) — the results line reads it there; cost if wrong: one key rename.
- Ruling: Task 6's one Important (test wording) goes to the final fix wave instead of its own round — it changes no behaviour; cost if wrong: none beyond a later edit.
- Ruling: "0 believers = today's night" after the first frame rests on code reading (handlers only record, no RNG at count 0) plus a start-of-night digest test, not on a frame-by-frame test (two Mission runs in one process differ anyway through wall-clock inputs) — cost if wrong: a subtle Endless-night behaviour change found only in play.

## The Capital at every tier

- Ruling: spec coordinates are first guesses (the writer scanned directors, did not read every body) — each task confirms by its own tests — a wrong spot costs a tuning round in that task.
- Ruling: under load refs_check rows time out at 600 s — tasks use `bash <workspace>/refs_long.sh` (same script, 2400 s) — costs wall time only.
- Ruling: parity is measured on the real grid walk, not the straight line — the spec's design rule is about time the player has — costs a re-gate per mission whose first-guess spot is off.
- Ruling: gate median windows (route a 180-240 s, b 150-270 s) are judged against the mission's own Aldermere median, not absolute, where Aldermere itself is outside the window (Mira: 43 s / 94 s) — the windows were written for longer missions — wrong if the user wants every Capital night long.
- Ruling (Task 2): no old-town dwelling reaches the walk band (max 22.9); Mira moves to the east tenement (23.26, -12.37), walk 29.3 — parity over district flavour — costs the noble-quarter setting; fallbacks shophouse (25.1, -12.19), tavern (22.7, -6.45).
- Ruling (Task 3): route b median 295 s vs Aldermere 198.7 (1.48x, over the 1.35 band) is accepted: wins 3/3, none lost 3/3, and the spot that fixed route b (1/3 -> 3/3) is what lengthened it - a winnable long night over an unwinnable short one - costs a slow Capital route b; list for the user's play test.
- Ruling (Task 3): no route a play rows in capital_lanterns.tsv (Heaven Splitter hit-stop is wall clock; Aldermere has none either) - matches memory mission-test-not-exact - costs replay cover of route a play in the Capital.
- Ruling (Task 3): route a gate FAIL on the 180-240 s window stands unfixed: the night's clock is 180 s and Aldermere's median is 150 s, so the window cannot be met - same ruling as Mira - list for the user.
- Ruling (Task 5): route b miss and the false place word are correctness gaps, sent back before review (pre-review fix, FIX_BASE b5aad069) - three more tuning rounds, policy first, Aldermere panic_b_play rows must stay bit-exact - costs wall time.
- Task 5: parked - route b in the Capital wins 2/3 (271.5 s, 289.4 s; seed 1 lost at 27/36), outside the 150-270 s window - Ruling: real and deferred. Seven tuning rounds (spots, wave_at, policy) did not close it; the next lever is the mission's own numbers (goal count, FAIR_R, warden return) which is a design change for the user, not a placement. Route a passes 3/3 at 221 s, so the mission is playable. Nothing downstream builds on it. Costs: a hard Capital route b until the user's play test; capital_panic_b_play_1 has no reference row.
- Ruling: Informer contacts are old-town townhouse centres (only 18 fit RuinWish.fits); potter moved to (-0.27,1.1) (arrow was under the HUD), lodging to NE townhouse (10.2,-15.1) (0.87x parity) — spec coordinates are first guesses — cost if wrong: one overrides file to re-tune.
- Ruling: `visit_at(i)` method renamed `visit_time()` (clash with the new var) — no outside callers — cost if wrong: one rename.
- Ruling: DEV tab row 1 pages, 6 cards at a time (DEV_PAGE), window follows the selection, "< N" / "N >" markers — the tab will hold ~27 cards by Tier 5, one row cannot — dev-only UI; cost if wrong: one board file to redo. Dispatched as fix round 1 to the Task 7 implementer.
- Ruling: tier closes run the tier's Aldermere rows + every capital_* row (refs_long.sh), not all 561 rows; all rows + FLOW run once at landing on a quiet machine — 561 rows under this load is 12-24 h per tier close, FLOW aborts under parallel Godot load (10 foreign Godot processes now) — cost if wrong: a moved Aldermere row outside the tier is found at landing, not at the tier close.
- Ruling: Step 4 (every Tier 2 Capital gate once more, together) is covered by the 174 bit-exact reference rows (the same none/play/b/toll runs, seeds 1-3, same checksums = same outcomes and times as each task's gate) — headless fixed-fps runs are deterministic — not covered: Lanterns route a play (no ref rows: hit-stop wall clock) and capital_panic_b_play_1 (parked loss); cost if wrong: found at landing gates.
- Ruling: Capital mira_shrine = (19.1,-22.7), outside the old town's east wall by a wall tower, 23.5 from the spire (Aldermere ~23), carry 0.88x — spec spot gave 0.06x carry; (32,-16) was outside the Searchlight — a bare spot, no dwelling: user play test to judge the look; cost if wrong: one literal + 12 ref rows.
- Ruling: Vigil Flame Capital gates judged vs Aldermere: a 3/3 91 s idle 50 (Aldermere a 1/3, 360 s, idle 235: window unreachable there too); b 3/3 125 s (Aldermere 130 s, floor 150); toll 2/3 110 s PASS.
- Ruling: carry hint words changed for both towns ("out past the walls") — MissionHints has one line per id; true in both — cost: one string.
- Ruling: crowns_bread hint reworded for both towns ("...The strip shows when each comes into use.") — one hint line per id; the old one named the granary and the mill — cost: less specific in Aldermere; one string to restore if the user wants per-town hints.
- Ruling: Prisoner in the Capital: extra town var `exit_name` ("HARBOUR GATE"); hints/tour say "way out" for both towns (+pins); route a seed 1 loses (taken at 80.8 s), row capital_prisoner_play_1 omitted, 2/3 meets the gate — cost: one seed of three is a loss for scripted play; the user may want the stocks or first beat moved.
- Ruling: Capital hunt none seed 2 loses by cellar found at 355.1 s (my 300-350 s window was "roughly"; Aldermere 323-342) accepted — it is the right lose reason, before dawn — cost: 5 s margin to dawn on one seed; next lever step_at[3] 200 -> 190.
- Ruling: Capital Heretic Hunt differs from the spec: cellar (-10,15) area Rect2(-16,10,16,8); sweeps cathedral quarter / west market / south gate quarter (noble quarter dropped); camera (-9,9), intro (-9,15); step_at [60,115,185,200] — spec values gave a 0.55x captain walk and sweeps that did not close on the cellar — cost: user may prefer the noble quarter in the hunt; values live in capital_missions/heretic_hunt.gd.
- Ruling: Procession camera in the Capital (-1,-12), not the spec's (9.3,-18.6) — the spec value hides the cathedral door's and the court's arrows under the HUD — cost: none seen; one value in capital_missions/procession.gd.
- Ruling: Capital Procession route a accepted at 3/3, 281.9/49.3/251.4 s, median 251 s (window 180-240; Aldermere's own route a 2/3, 390 s) after the 3-round cap; route point 0 (0,-20.5) not the spec's (0,-22.4) — the court's south corner had no citizens, the Prince was alone at once — cost: seed 2 still wins at 49.3 s (a luck smell); next lever point 1 (cathedral door) or the policy; user play test to judge.
- Ruling: the Capital gets a ship (ship_at (31.0,-0.65), CityDef.ship_last()) per spec decision 4; RiverFerry now animates a ship in the Capital — cost: visual only; other capital_ rows unmoved.
- Ruling: Task 15 opening-situation crowd count not sent back for a fix round — none runs lose at bishop_taken 300 s in both towns and both gates sit in window, so the 50 s-win failure mode of Task 14 is not present — cost: a thinner report; user play test covers the feel.
- Ruling: Bishop in the Capital: refuges are the civic square houses (10.1,-5.1) and (1.6,-5.1), camera (2,-9), arrive_at not a town var (it is the night's clock) — spec spots gave 0.67x walk and hid the Cathedral door under the HUD — cost: values in capital_missions/bishop.gd.
- Ruling: Armoury camera in the Capital (-16,-4), intro (-16,2) — spec's (-16,-6) hid the west tavern under the HUD; the barracks shows as an edge arrow (Cap.camera_clear counts it) — cost: none seen.
- Ruling: Capital Armoury stage_at [40,110,150]; route b stage 3 horn->raze stays 0.50x of Aldermere's (11 s vs 22 s, reinforcements 0.3 vs 1.3) — the Keep's gate is beside its barracks and route b clears the watch before the horn; lower than 150 pulls route a's median under 180 s — cost: stage 3 is easier in the Capital for a player who strikes first; fix would be layout (Keep gate) or a Capital-only reinforcement delay; user play test to judge.
- Ruling: Task 17 escalated one tier (opus) for a placement redesign before review — the failing shape is geometric (report run 0.47x, pulpit in the watched centre, pulpit_well never varied) — search all wells x dwellings on the walk grid for Aldermere's shape, max 3 gating rounds, no rule changes; if still failing, park like Market Panic route b. Cost: one opus run.
- Ruling: Capital Sermon accepted: pulpit at wells()[1] (south-west), house (-20.5,18.7), sources (-27.75,13.45),(-10.25,22.95),(-25.75,22.95), camera (-23,20); every spec value replaced (spec's "east of x = 8" placement put the god's door inside the preacher's voice / the watched centre: 0-1 wins) — route a 2/3 median 222 s (seed 1 loses 6/8 believers), toll 3/3, route b 0/3 in both towns (known Aldermere debt), report run 1.45x — cost: route a has zero margin; the whole Sermon sits in the far south-west corner; user play test to judge; next lever = policy or mission numbers (user's choice).
- Ruling: Task 18 escalated to opus placement search (as Task 17): knob widened to the whole cart_route (halts may move; last point stays the Citadel gate), pip_spot, drop_spot, camera — spec coordinates are first guesses (standing ruling) — cost if wrong: one opus round.
- Ruling: Task 18 var named `cart_route` not `route` (route is the built walkable array); `mira_shrine` override dropped (dead data in RelicRun); first halt's words "the south-east gate watch-house" — accepted, true by place.
- Ruling: Task 18 toll 2/3 (Aldermere 3/3) and idle 53 s (Aldermere 49) accepted — B improved to 3/3, all in band — cost if wrong: toll case slightly harder in the Capital; play-test item.
- Ruling: Tier 4 refs moved to a detached worktree C:/BURIN_NITRO/Godot/GIT/vfxProve-chamber-refs @867c871e so Task 20 can run in parallel — 83/253 rows OK saved in t19_refs_part1.txt, 170 left (t19_left_names.txt) via refs_left.sh NAMES=. Task 19 completes when those end bad=0. Remove the worktree after.
- Ruling: spec decision 2 (old-town-only stability) NOT applied — every loss is the 50-escape limit, stability area cannot change it; Aldermere loses the same way (known debt, judgement_b 0/3 on Develop-Main) — parity holds as "not winnable by script in either town". Cost if wrong: Capital Judgement harder for a human (escapes come ~25% sooner); play-test item for the user; lever would be ESCAPE_LIMIT by population (forbidden by spec D17, user decision).
- Ruling: capital_judgement.tsv records capital_judgement_b_play_1..3 as played (losses), mirroring Aldermere's judgement_b_play rows, for regression cover.
- Ruling: Task 21 tower moves accepted (spec coordinates are first guesses); one guard post 0.5 beyond the wall at the north tower accepted, pinned as the one exception — cost if wrong: a guard stands in the wall line; play-test look.
- Ruling: Task 22 gates accepted by the standing rule (judge vs Aldermere's own median, band 0.75-1.35): A wins' median 260 = 1.22x of 213, 2/3; B 2/3 — zero margin like Sermon; cause (east household seized at the harbour gate watch ~115 s) is a play-test item — cost if wrong: Exodus in the Capital tighter than Aldermere. No OUT_AT/SHUT_AT change (copy rule).
- Ruling: Task 23 oil-house and camera moves accepted (spec coordinates first guesses) — play-test look: oil-house far west of the cathedral.
- Ruling: Task 24 accepted as parity — Act III unwinnable by script in both towns (Task 20 verdict; Cap 0/9 vs Ald 1/9) — play-test item. Deviations accepted: WARNING_TOWN_VARS post/post_name instead of gate_spot (gate_spot is derived at setup); Omen camera (-21,-13.7) intro (-21,-7.7); acts reuse their missions' own overrides files (single source of truth); _draw_none changed to every-tier-draws (Task 25 Step 1 partly done).
- Task 25: dispatched (base c6fd5fe6; Step 1 remainder + Step 2 + commit; implementer sonnet). Ruling: Step 3 (whole suite, refs, FLOW, bench) runs AFTER the final review's fix wave, on final code: suite + rows '^(capital_|eye|exodus|heart|judgement|night)' now; all rows + FLOW + bench at landing on a quiet machine (standing ruling).
- Ruling: capital_calm / capital_evac re-recorded (-112219378, 41568922) — they start the default mission (Last Judgement) in the Capital, which now has Capital overrides; Capital-only rows; no Aldermere row moved — cost if wrong: a real Capital crowd change hidden in those two rows (bisect points only at the overrides file + policy table).
