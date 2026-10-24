# KAK v0.12: every ruling

v0.12 "Many Towns" was built straight through, subagent-driven, from 2026-10-23 to 2026-10-24. A ruling is a choice the spec or plan left open, or a place where the code said something else. Each one has three parts: the decision, why, and what it costs if it is wrong. The spec is `docs/superpowers/specs/2026-10-23-kak-v012-many-towns.md`; `D<n>` is its decision number. Where two rulings disagree, the later group wins: the C rulings beat the R rulings and the plan text.

Groups: R1-R31 (plan rulings, 2026-10-23), C1-C11 (controller rulings: pre-flight, the M1 review, the M2 review), then the rulings the tasks reported (T1-T14, the M1 fix wave, the M2 fix wave).

## Plan rulings R1-R31 (spec and plan author, 2026-10-23)

- R1 [D7] (corrects the brief): The Capital HAS a Citadel -- `CapitalCity.citadel_origin()` is `(0, -25.5)` on the Royal Keep's hill and `Town` builds a `Citadel` node there in every city; the need `citadel` is met. Citadel/Keep missions stay out of scope by decision, not geometry -- the brief said "a Keep, NOT Aldermere's Citadel node (citadel_origin may be INF)"; the code says otherwise, and Tax Collector / Harvest (goods to the Citadel's gate) can be ported -- cost if wrong: none for M1-M2.
- R2 [D6] (corrects the brief): The Capital's references are measured, not remembered -- brief/memory say capital_calm -370675099, capital_evac -870513036; `docs/KAK_Capital_City_Summary.md` says -713901328 / 731230687 (60 fps). Task 1 records both at the tip `f7d74922` (own detached worktree) and on the merged tree; a difference is kept only with its cause named -- cost if wrong: none (measuring is cheap).
- R3 [D1] (corrects the brief/memory): `crowd_check` is `-935602679` (moved by v0.11.2's awareness), not -346732806; the 233 rows of `tools/dev/refs/*.tsv` are the Aldermere reference -- cost if wrong: none.
- R4 [D2]: Shared code added since `3ff44f10` reads TownLayout in one place only, `src/game/descend/pressed_wish.gd` (BARRACKS) -> `City.current().landmark(&"barracks")`; v0.11/v0.11.2 put their place reads in `src/game/mission` -- the brief expected many -- cost if wrong: the guard names another and the merge task fixes it.
- R5 [D11]: The guard (`tests/test_city.gd::_no_hardcoded`) adds `src/game/mission` and `tools/dev/routes` (descend is already in it), and a function-scoped scan of `behaviour_check.gd`'s Tier 1 policies; Aldermere-only scenarios keep their TownLayout reads -- they test Aldermere by design -- cost if wrong: a policy reads Aldermere in the Capital unnoticed until its gate.
- R6 [§1.3] (corrects the brief): 22 files under mission/descend mention TownLayout, but 19 read it in code (3 are comments only: `warning_director`, `market_panic_director`, `ruin_wish`) -- the guard strips comments -- cost if wrong: none.
- R7 [D4]: "Is this person clergy" tests use `CitizenProfile.is_clergy()` (the Capital's monks count) in `first_prayers_director` l.145, `lantern_bearer` l.235/248, `neighbours_wish`, `punish_wish`, `banishing_rite` x2; exact role picks `_citizen_near(at, Role.CLERGY)` (Lamb, Bishop, Heart, Sermon) and role tables stay -- Aldermere has no monks, nothing moves -- cost if wrong: a Capital monk is skipped where a cleric would be taken.
- R8 [D5]: A capital crowd rule (no step into the river, wade ashore from a fallen span, long steps land on the waypoint) that moves any Aldermere row at the merge goes behind a `CityDef` switch off for Aldermere, never a re-record -- the capital proved only v0.10's rows; v0.11 added bridge-falling nights it never ran -- cost if wrong: one more city flag.
- R9 [D8]: Places are named on `CityDef` (`landmark()`, new `place()`, `gate_towers()`, `barns()`); missions read them through the static `Places` helper, which errors on an unknown name -- `Rect2()`'s centre is the map's middle, a silent bug -- cost if wrong: a thin extra helper.
- R10 [D14]: Director spots are per-city data (town vars seeded by Aldermere's consts, set by a town's overrides), not landmark-relative rewrites -- exact for Aldermere and cheaper; door-relative offsets already in the code stay -- cost if wrong: each new town writes its own spots (data, not code).
- R11 [D15]: One overrides file per (town, mission): `src/game/town/cities/<city>_missions/<mission_id>.gd` with `static func overrides() -> Dictionary` (`{"def": {}, "director": {}}`), loaded by path in `CityDef.mission_overrides()` -- M2's five parallel tasks never share a data file; any town gets the mechanism by having the folder -- cost if wrong: many small files.
- R12 [D12, D13]: Needs are one table, `MissionNeeds.TABLE`, read by `MissionDef.needs()`, and a scan test checks every `Places.*(&"name")` a director (and its bases) reads is listed. Hostable = needs met AND (the mission's home city OR the town has its overrides file) -- needs alone would offer Tax Collector in the Capital in M1 with Aldermere's coordinates -- cost if wrong: none.
- R13 [D16]: Apply order in `make_director()`: stretch, the board's `tune`, then the town's director overrides; `def` overrides at `MissionBook.in_city()` -- the town is the most specific -- cost if wrong: a town cannot undo a board tune (none exists for Tier 1).
- R14 [D17]: A number written in copy (a hint, the tour's fixed text, the legend: Harvest's 10 s / 3 s, First Prayers' three) is not overridable in v0.12; tours that print a time read the var -- a town must never make the game's words false -- cost if wrong: a town needing another burn time waits for the copy to read the var.
- R15 [D18, D20]: A night in another town is `<mission>@<city>`; `MissionBook.is_dev()` is true for it (every power open); it has NO Descent in v0.12 (no wishes, believers, banking, tier progress: `_descent` only when `_def.city == &"aldermere"`); its best is saved under the composite id -- dev-only per the user; the town UX decides later -- cost if wrong: Capital gates run without the wishes' extra people.
- R16 [§1.6]: A DEV-tab town night is the board's version of the mission (`Mission.def_for(base, true, state)` then `in_city()`): Starfall for `warning`, the tier's clock and budget -- the same def Aldermere's board plays; the scripted Capital gates use exactly Aldermere's gate flags plus `--city=capital` -- cost if wrong: none for Tier 1 (board and MissionBook versions match except the Warning).
- R17 [D23]: Capital Starfall is gated like Aldermere's ★ Starfall, on route b `--board` (wins >=2/3, idle <=45, median reported), plus `gate.sh --with-none` (new) so "doing nothing loses" is proved; no route-a policy exists for it (route a of `warning` is the campaign night) -- cost if wrong: none.
- R18 [§2.0]: Toll cases in the Capital: Starfall (herald) and Tax (watch) binding >=2/3; First Prayers (a Gaze stealth night) per v0.11.2's C12 -- reported if under 2/3, the toll must still never lose outright; Harvest and Lamb have no Lantern, no toll case -- cost if wrong: a thin Prayers toll unnoticed (it is printed).
- R19 [D26, D27, D28]: Walk parity before tuning -- each mission's key walks (WalkGrid path length) in the Capital within 0.75-1.35x of Aldermere's, test-asserted; Starfall's gate runs 0.75-1.6x (the old town's gates are all >=15 from the tower); First Prayers' report run (shrine -> Temple door, ~1.45x) printed only. A gate miss is met by the spot, then the policy, then the numbers -- cost if wrong: a parity spot that plays badly; the gate still decides.
- R20 [D25]: Every Tier 1 night in the Capital is played inside the old town's wall ring (INNER, ~Aldermere's size): no route crosses the river, whose gatehouses queue one person a second (traffic = luck). Lamb leaves by the old town's own west gate; Starfall's stars fall over the harbour gate, the west river gate and the west gate (far to near) -- cost if wrong: the Capital's new town and harbour stay unused by Tier 1.
- R21 [D24, D29]: Bench -- Aldermere's five boards vs `kak-v0.11.2` (M1) and `kak-v012-m1` (M2), within ~1 fps; the Capital recorded only (`land.sh --bench-only` new; sandbox vs its tip `f7d74922`; Starfall@capital HEAD only). The capital's summary shows Aldermere 83.1 -> 80.6 fps across its polish 3 (border band, which Aldermere draws too): a drop traced to it is reported with numbers for the user, not fixed in v0.12 -- cost if wrong: Aldermere ~2 fps slower until a perf pass. NEEDS THE USER'S EYE.
- R22 [D21]: DEV cards show the mission's name, the town (`CAPITAL`, gold) and its type line, no brief -- six cards are ~94 px wide -- cost if wrong: a terse dev-only card.
- R23 [D22]: FLOW grows by one step per milestone: M1 the DEV tab's sandbox night and back to an exact Aldermere night; M2 `tax_collector@capital` from the DEV tab -- cost if wrong: a few seconds of FLOW.
- R24 [brief]: Tags are `kak-v012-m1` / `kak-v012-m2` as the brief says (earlier tags were `kak-v0.11.2` style) -- the brief is binding -- cost if wrong: a tag renamed.
- R25 [D10]: `MissionDef.camera_at` defaults to `Vector2.INF`, read through `MissionDef.camera()` as the active city's `citadel_origin()` -- a var initialiser cannot ask the active city safely; INF resolved at start is Aldermere's `TownLayout.CITADEL_ORIGIN` exactly -- cost if wrong: one more INF check.
- R26 [D20, D3]: Wishes stay Aldermere-only in v0.12 (no Descent elsewhere); the Citadel's gate becomes the place `citadel_gate` (Aldermere literal `(-10.5, -7.6)`, Capital `(0, -22.6)`) read by `RescueWish`, Harvest and Tax -- the three copies of one Aldermere point -- cost if wrong: none.
- R27 [D19]: `Mission` reads `--city=` itself when it starts on its own, so `behaviour_check`'s automatic and explicit starts build the same town; `Game` ignores it (the DEV tab is the game's door); the merged `mission.city` var stays for capital_calm/evac -- cost if wrong: none.
- R28 [§2.0]: The Capital's street patrols and wall loops are the town's, not a mission's opposition (they seize and guard nothing, but witness); the spread rule binds the mission's own people; a policy's unseen kill that fails for traffic moves the stage, never the numbers -- cost if wrong: a busier Capital night than Aldermere's.
- R29 [skill]: Every task is sonnet; none is a redesign (the merge follows the spec's resolution table). Reviews: sonnet on Tasks 1, 2, 4 and 9-13; none on mechanical/board/tooling/landing/notes; the controller's opus milestone review at each landing -- cost if wrong: a merge subtlety a sonnet review misses (full references and FLOW guard it).
- R30 [§2.0]: Capital references go one TSV per mission (`tools/dev/refs/capital_<scenario>.tsv`), rows `capital_<scenario>_<none|play|b_play|toll>_<n>` with `--city=capital` in `how`, so the parallel tasks never edit one file and `refs_check.sh` runs them in parallel -- cost if wrong: five small files.
- R31 [§1.5]: Town vars that the base class already has are seeded in a new `_init()` (set at `.new()`, before overrides) and dropped from `_plan()`/`_begin()`; others are declared with their const as default -- otherwise `_plan()` would overwrite a town's override at setup -- cost if wrong: none (tested by `_override_survives_setup`).

## Controller rulings C1-C11

### C1-C5: pre-flight (2026-10-23)

- C1. Every `Ruling:` proposed in preflight.md (11 BLOCKING, 13 RISK, 6 GAP) is adopted as written. Read the items naming your task.
- C2. Pre-flight BLOCKING 5: `MissionNeeds` (the needs table) and `Places.can_host()` move into Task 2 (serial), so Tasks 3 and 4 can run
  in parallel; Task 3 fills the mission rows it needs, Task 4 only reads them.
- C3. Every test that switches the city (City.use) restores Aldermere in a `finally`-style tail and asserts it at the end; the suite
  runner (run_all / run_part) asserts City.current() is Aldermere before and after each suite (pre-flight RISK: city state leaks).
- C4. No test or FLOW step writes the user's real save or settings (use test paths, as v0.11.2's Settings did).
- C5. (review-2 Minors) Task 3, which fills MissionNeeds' rows, also: makes Places.can_host() return false (after push_error) for an id
  with no row; makes Places.has() push_error on a `:n` count for a non-list need; adds a test that the Tier 2-5 CITADEL_GATE alias
  consts equal Aldermere's `citadel_gate` place.

### C6-C9: the M1 review fix wave (2026-10-24)

- C6. Mission start in a town that cannot host the mission (MissionBook.hostable false, incl. a non-home town with no overrides file)
  is an error: push_error and refuse to start; behaviour_check/gate.sh exits non-zero. Test with a misnamed fixture overrides file.
- C7. Each Tier 1 director declares `TOWN_VARS` (the names a town may override); Overrides.apply refuses any other key; the town values
  are applied where setup cannot overwrite them (after setup, or setup reads them), and a test asserts every override still holds after
  the director's setup.
- C8. The capital's long-step rule (dummy_enemy.gd ~186-199) goes behind a CityDef flag, off for Aldermere (Aldermere real-play walking
  as before the merge). References run at fixed 60 fps and must stay OK.
- C9. M1 summary names the camera clamp's effect on which off-screen people update during real play (next to the border band). M2
  briefs: override camera_at and intro_from together.

### C10-C11: the M2 review (2026-10-24)

- C10. (m2-review Important) Revert the Capital-only Discord filler in tools/dev/routes/tier1_b.gd (it only resets the idle counter;
  outcomes identical) and restore capital_prayers_b_play_1/2 to -252052717 / -531737743. Then, at most two rounds: move the Capital
  shrine or the poor's spot (First Prayers overrides only) so the route's own Aldermere filler (Silent Doom on a Faithful nobody sees)
  has a real target in the Capital and idle <=45 with wins >=2/3, route a and toll still PASS. If it does not reach <=45, keep the
  reverted policy and record "Capital First Prayers B idle ~48 s (Aldermere 42)" as REPORTED for the user (not binding).
- C11. (m2-review Minors to take in the same fix if one-line) rename the Capital "THE RIVER GATE" label to an unambiguous name;
  fix the "poor of the west market" wording if they are stall merchants; make the four can't-fail tests able to fail (or delete them).

## Rulings the tasks reported

### Tasks 1-8 (M1)

- T1: the capital's two river rules for walkers (no step off dry ground into the water; wade ashore from a fallen span) are one CityDef switch `river_rules()`, off for Aldermere -- both moved Aldermere rows (D5/R8 forbids re-recording) -- cost if wrong: one flag; a later Aldermere river change must flip it knowingly.
- T1: capital_evac is recorded at the merged value 122086902, not the tip's 731230687 -- the difference is v0.11.2's startle, proven by switching it off -- cost if wrong: the Capital's evacuation is a v0.11.2 evacuation, which is intended.
- T1: the DEV tab card keeps develop's layout (brief_lines/best_lines/rule_y) with the capital's "Dev sandbox" type line -- both sides' intent -- cost if wrong: a cosmetic line on a dev-only tab.
- T2: Spoiled Harvest's needs row is `["citadel", "citadel_gate", "temple"]` already in Task 2 -- every director reads the Temple through MissionDirector (preflight BLOCKING 6) -- cost if wrong: none.
- T2: `MissionNeeds.TABLE` holds plain string arrays and `of()` returns `PackedStringArray(...)` -- a `PackedStringArray(...)` call is not a constant expression -- cost if wrong: none for callers of `of()`.
- T2: `RescueWish.gate_point(grid)` is a static helper (testable without a crowd) -- cost if wrong: one small static.
- T3: needs counts are literal-index based -- `armoury` `["temple","barracks","taverns:2","gate_towers:2"]`, `crowns_bread` `["temple","barns:4","gate_towers:2"]`, `sermon` `["temple","wells:3"]`, `heretic_hunt` `["temple","districts:8"]` -- a count says what the code indexes; a town with fewer entries is refused rather than crashing -- cost if wrong: none.
- T3: `long_night` lists every act's reads plus `bell_tower` (Aldermere-only in v0.12) -- cost if wrong: none.
- T3: the reads scan also counts `.landmark(&"x")`, `.place(&"x")`, `.citadel_origin()` and any `.<list>()` call in the script chain -- closes the preflight RISK for locals -- cost if wrong: none.
- T3: the scan walks both `MissionBook.get_mission(id)` and `TierBook.board(id)` and every act's director -- preflight GAP -- cost if wrong: none.
- T3: the commit used the dispatch's attribution reminder (Claude Sonnet 5.5) rather than implementer.md's "Opus 5.5" line -- the harness reminder was more recent -- cost if wrong: a trailer to amend.
- T4: `Overrides.apply` rejects an int for a float property and a String for a StringName (strict `typeof`) -- a silent coercion is the failure to guard against -- cost if wrong: a red round in the first override file.
- T4: `City.by_id` returns the registered fixture instance itself; `unregister` clears `City.active` if it is that fixture -- fixture towns are stateless test doubles -- cost if wrong: none.
- T4: `in_city` on an unknown city id errors and returns the def unchanged -- cost if wrong: none.
- T4: the director-override tune is only chained when the town has `director` values -- a def put in a town without overrides is untouched -- cost if wrong: none.
- T5: `--with-none` on route a is a no-op (route a already requires none_lost 3/3) -- cost if wrong: none.
- T5: the toll-case verdict line also prints `city=<id>` when `--city` is given -- cost if wrong: a parser of the toll line sees an extra token.
- T6: the Tax Collector's `counting_spot` fallback keeps `Places.at(&"workshop")` -- identical for Aldermere -- cost if wrong: none.
- T6: `FETCH_STARE`, `NEED`, `POOR`, `FAITHFUL_CLERGY`, `LABELS` stay consts (copy / not in the table) -- cost if wrong: a town needing them waits for a later task.
- T7: card lines of a town mission are two stacked small lines (town, then type) -- one "CAPITAL  KILL" line would be wider than the 74 px of a six-card row -- cost if wrong: one more line of card height (still clear of the rule, tested).
- T7: the card-fit test covers Tier 1's five (the only missions a town can host in v0.12); later tiers' names would wrap at SIZE_BIG -- cost if wrong: a later tier hosted in a town needs a narrower name or smaller font on the DEV card.
- T7: `Game.bank_night` extracted as a static (preflight RISK option b) -- the user's save is never touched, no Results screen is built outside the tree -- cost if wrong: none.
- T7: the FLOW step sits after `_flow_tier5` (before `_veteran()`), ends on the board with `dev` restored -- cost if wrong: none.
- T8: no commit -- no table or reference row changed; FLOW rerun by hand after land.sh's run found no result under other sessions' load -- cost if wrong: none (FLOW 131/0 shown).

### Tasks 9-13 (M2: the five missions in the Capital)

**Task 9**

- the river gate's post stands 3.4 inside the gate -- keeps its run inside the 1.6x band -- cost if wrong: the star falls a little off its gate.
- the policy falls back to the emptiest corner (1.0 less room, never under 3.0) when a street has no 4.5 corner -- a player does this, and Aldermere's rows are unchanged -- cost if wrong: a Capital kill seen by one witness hands the errand on.
- `capital_starfall_toll_*` rows are binding at >=2/3 but their idle is reported only -- gate.sh does the same for every toll case -- cost if wrong: none.

**Task 10**

- every debtor spot is a dwelling's own centre (not the spec's guesses) -- the old town has 18 dwellings and the guesses resolved to far or cross-river houses -- cost if wrong: none (the test pins the resolved houses and their band).
- `counting_spot` is the weigh-house's centre alongside `counting_tag` -- the director falls back to it when the tag is absent -- cost if wrong: none.
- the camera rests on the weigh-house centre + (-2, 3) (Aldermere's offset, applied to the centre as Aldermere's code does, not the door the spec says) -- the HUD check passes there -- cost if wrong: a new offset.

**Task 11**

- parity is judged on the whole set (total 0.75-1.35x, each trip 0.75x Aldermere's shortest to 1.35x its longest), not by rank -- the old town has no dwelling over 29.3 by path, so Aldermere's 40.6 has no counterpart (0.72x at best) -- cost if wrong: the carter empties a Capital granary sooner (load_count 6 is the spare knob).
- spots are the doors of three dwellings (west/south/east) instead of the spec's NE/SE/W guess -- NE (14.6,-13.4) is only 19.7 away (0.70x Aldermere's NE) -- cost if wrong: a gate miss would move a spot first.

**Task 12**

- `camera_at` is the fixed point (-12.0, -2.0), not `charge_start.lerp(gate_at, 0.3)` -- the Capital's west gate lies far up-left of the acolyte on the iso screen, so any camera that has the acolyte in view puts the WEST GATE arrow in the HUD stack (a brute-force scan of cameras found none with both clear and the acolyte on screen); at (-12,-2) the acolyte's arrow is at the right edge, the gate's at the top, all clear of the padded stack -- cost if wrong: the acolyte starts off screen (its arrow points east).
- `hideout_name` is a town var on `LostLambDirector` (review minor 5: the tour's "north-east fountain" is false in the Capital) -- a town must never make the game's words false -- cost if wrong: none.
- the "beat >= 6 from the door" check is the nearest approach of the whole beat segment, not just its endpoints -- a patrol walks the whole line (the spec's first beat 1 passed an endpoint test at 5.1 yet ran 3.0 from the door) -- cost if wrong: a stricter test.
- parity band asserted for the four long legs only (start->gate, gate->guardhouse, both beats); gate->exit and start->door are printed with a walk-exists check (short or not a night walk) -- cost if wrong: none.

**Task 13**

- the poor's parity is the straight distance spot -> door (path printed) -- a Mind Whisper hop is straight and Aldermere's own 19.5 path is a 1.8x detour round one house; the spec's "~11.3" is a straight number too -- cost if wrong: a path-parity spot behind the stalls leaves the poor beyond one hop (tried, the policy fails).
- the shrine on the Great Market's south promenade (-9.25, 0.75), not the west edge -- stalls fill the west edge -- cost if wrong: the promenade is busier near the river gate.
- poor spot in the west market, the camera on the way from the shrine to the poor (lerp 0.8) -- the poor are west of the shrine, so a shrine camera hides them under the HUD stack -- cost if wrong: the intro frames the poor more than the shrine.
- FirstPrayersDirector gets the town var `poor_quarter` (copy that named Aldermere's quarter) -- a director edit beyond the overrides file, no base class, Aldermere's text unchanged and asserted -- cost if wrong: the Capital's tour would say "south-west quarter".
- kept Aldermere's numbers (32 s, 75/150, 3 lay) -- every knob tried made A or B worse -- cost if wrong: B's idle 48 s stays.
- the filler is keyed on the city id and the window, 32 s idle -- cost if wrong: a Capital-only line in a shared route file. (SUPERSEDED by C10: the M2 review found the filler only reset the idle counter; it was reverted and Prayers B idle ~48 s is REPORTED.)

### Task 14 (M2 landing)

- the FLOW step lives in `_flow_dev_town` (it extends the M1 step, same `dev` handling) and picks `tax_collector@capital` from the DEV board right after the sandbox night -- the board reopens on the DEV tab after a town night, so no tab switch is needed -- cost if wrong: none.
- the landing's bench-only, references and FLOW were run as separate commands with private output paths instead of the single `land.sh` -- the shared `/tmp/kak_land` was in use by another session's landing -- cost if wrong: land.sh's own summary file was not produced; each piece's output is in the report. (Afterwards `land.sh` was changed to use a private folder per run, commit 93a08366.)

### The M1 fix wave (C6, C7, C8)

- `hosting_error` skips the check when the town is the mission's home (judged by `get_mission(def.id).city`, falling back to `def.city` for an id `get_mission` cannot resolve) -- a home start is never refused, so Tier 2-5 and campaign missions without a MissionNeeds row are unaffected -- cost if wrong: a mission with an unresolvable id played in another town is not checked.
- `Mission.unhosted_ok` exists for `capital_calm` and `capital_evac` only -- they put Last Judgement in the Capital to test the crowd, and their references must stay -- cost if wrong: another scenario could set it and skip the check.
- `TOWN_VARS` leaves out the names that setup assigns, instead of moving those assignments after the tune -- the smallest change that makes an override impossible to lose silently -- cost if wrong: a town cannot override a label until the director reads it from a var.

### The M2 fix wave (C10, C11)

- the Task 13 spots stay (shrine and poor's spot) -- two rounds of other spots did not reach idle <= 45 and made route A or B worse -- cost if wrong: Capital First Prayers B idle ~48 s (Aldermere 42), REPORTED for the user.

