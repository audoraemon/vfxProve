# KAK Mission Clarity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. KAK runs it through the `kak-milestone` skill (sonnet implementers, sonnet task review, opus final review).

**Goal:** Every mission step and hint says exactly what to do, in one verb vocabulary, and a cast that lands on a target but does not count says why in a banner -- with no rule, number or reference change.

**Architecture:** A read-only `why_not(key, at)` virtual on `MissionDirector`, answered per director and shown by the HUD through a rate-limiting `WhyNotGate`; a `MissionVerbs` table (12 verbs -> powers) that the copy, the tests and a third legend page share; the step and hint tables rewritten per mission group, each verb they name proved by a Kit-world test.

**Tech Stack:** Godot 4.7.2 GDScript, the headless test suite (`tests/run_part.gd`, `tools/dev/run_suite_parallel.sh`), the exact references (`tools/dev/refs_check.sh`).

**Spec:** `docs/superpowers/specs/2026-11-19-kak-mission-clarity.md` (read §0, §3, §4, §6 and your group's part of §5 before starting).

## Global Constraints

- Godot: `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. One suite: `"$G" --headless --path . --script res://tests/run_part.gd -- --only=<file stem>`. A new `class_name`: run `"$G" --headless --path . --import` first.
- **No rule changes.** No mission mechanic, number, timing, tag, objective or balance change. All 233 rows of `tools/dev/refs/*.tsv` stay byte-identical; a task that moves one is wrong, not the reference.
- New code that a mission runs is **read-only**: `why_not()`, `hint_phases()`, and new `hint_seconds()`/`step_seconds()` overrides. No rng, no `go_duty`, no timeline, no signal, no field write.
- Steps: `MissionSteps.MAX_LABEL` = 32 characters. Hints: fit `Hud.HINT_LINES` (3) x `Hud.HINT_W` (236 px) by the existing fit test. Banners: upper case, at most 36 characters.
- Copy is the spec's §5 rows **verbatim** (steps in backticks, hints in quotes, banners in backticks). If a Kit test proves a verb false in that phase, change the copy (drop that verb), never the rule, and add a `Ruling:` line to the commit body.
- Verbs: only `MissionVerbs.verbs()` words name actions ("Kill", "Scare", "Lead", "Lure", "Confuse", "Hold", "Burn", "Strike", "Rot", "Seal", "Banish", "Calm"); no power name in a step or hint. "Press C" (the rite's key) stays.
- `WhyNotGate.REPEAT` = 30.0 s, `WhyNotGate.GAP` = 4.0 s, `MissionDirector.WHY_MARGIN` = 1.0.
- Each group task edits **only its own block** in `mission_steps.gd`, `mission_hints.gd` and `tests/test_mission_hints.gd` (Task 2 makes the blocks), its own directors, and its own `tests/test_clarity_<group>.gd`.
- Per task: the focused suites, then `bash tools/dev/run_suite_parallel.sh 8`, then `bash tools/dev/refs_check.sh --only='<group regex>'`. FLOW is not needed per task (no behaviour change); landing runs `bash tools/dev/land.sh --bench=<last tag>`.
- Commit messages end with the session's attribution lines.

## Review Focus

1. **A why_not() that writes.** A helper it calls (`_walkable()`, a refresh, a cached list) mutates state, so a reference moves on a machine with the HUD up. Each group's test runs `ClarityKit.assert_read_only()` on every director it touched, every verb, every tag point.
2. **Banner flood.** A Heaven Splitter's strokes, a follow-up recast, or two casts a second apart near two targets: at most one why-not per cast, none within `GAP`, each text once per `REPEAT`. Task 2 pins it with two causes 1 s apart -> one banner.
3. **Two targets, two phases.** Starfall with two warnings out, Exodus with two households: a cast that counts for one target and not the other must return "". Task 5 (Starfall) and Task 7 (Exodus) each pin one such case.
4. **No director, free play, a Capital id.** `rules.director == null`, `Rules.free_play`, and `tax_collector@capital`: no banner, no error, and `hint_phases()`/steps resolve for the composite id. Task 2 pins null and free play; the resolve test runs the Capital ids.
5. **Handler order.** The HUD must judge after the director's own `_on_cast` (the whisper that turns the contact must not read "TOO EARLY"). Task 3 pins it: a whisper that turns him gives "".

---

### Task 1: The verb vocabulary and the legend's third page

**Files:**
- Create: `src/game/mission/mission_verbs.gd` (class_name `MissionVerbs`)
- Modify: `src/game/ui/legend_panel.gd` (page 3), `src/game/mission.gd:1368` (`open_legend()` passes the loadout)
- Test: `tests/test_mission_verbs.gd` (new; register in `tests/run_all.gd`), `tests/test_legend.gd`

**Interfaces:**
- Produces:
  - `const VERBS := [{"v": "kill", "word": "Kill", "does": String, "keys": Array}, ...]` -- spec §3's twelve rows in order; Scare's row carries `"loud": true` and no keys (computed).
  - `static func verbs() -> PackedStringArray` (`"kill"`, `"scare"`, ... table order)
  - `static func powers(verb: String) -> PackedStringArray` (book order of `PowerBook.POWERS`; Scare = every `not PowerBook.is_quiet(key)`)
  - `static func verbs_of(key: String) -> PackedStringArray`
  - `static func word(verb: String) -> String`, `static func does(verb: String) -> String`
  - `static func named_in(text: String) -> PackedStringArray` -- verbs whose word occurs as a whole word, any case, in table order
  - `static func legend_rows(loadout: PackedStringArray) -> Array` -- `[[word, does, equipped names: Array, other names: Array], ...]`, names from `PowerBook.get_power(key).name`
  - `LegendPanel.setup(tags: Array[MapTag], loadout := PackedStringArray()) -> LegendPanel`; `TITLES` gains `"WHAT YOUR POWERS DO"`; the counter reads `"%d / 3"`.

- [ ] **Step 1: Write the failing tests** in `tests/test_mission_verbs.gd`:
  - `_table`: `MissionVerbs.verbs() == PackedStringArray(["kill","scare","lead","lure","confuse","hold","burn","strike","rot","seal","banish","calm"])`; every key of every row is in `PowerBook.keys()`.
  - `_families`: `powers("burn")` equals the `PowerBook.FAMILY` "fire" keys; `powers("strike")` the "strike" keys; `powers("scare")` equals the keys with `not PowerBook.is_quiet(k)`.
  - `_sources`: for every key, read its fx script text (`FileAccess.get_file_as_string(PowerBook.get_power(k).path)`); `powers("lead")` == keys whose text has `.whisper(`; `powers("confuse")` == `.confuse(`; `powers("lure")` == `.lure(`; `powers("hold")` == union of `.whisper(`, `.confuse(`, `.compel(`, `.lure(`; `powers("banish")` == `.fold(`. (Expected per spec §3; if the scan disagrees with the spec's list, the scan wins and the spec's row is corrected in this commit.)
  - `_kill`: every `powers("kill")` key's fx header comment mentions a death (`die`, `dies`, `kill`, `dead`); `"guise"` is not in it.
  - `_named`: `named_in("Kill or lead its guards (red)") == ["kill","lead"]`; `named_in("Keep it burning") == []`; `named_in("Burn the refuge (gold) now") == ["burn"]` (not "burning").
  - `_legend_rows`: `legend_rows(["whisper","smite"])` -- the Lead row's equipped == `["Mind Whisper"]`, Scare's equipped contains `"Smite"` and its others do not; 12 rows.
  In `tests/test_legend.gd`: `_pages` now expects 3 pages (H: 1 -> 2 -> 3 -> closed, `closed` emitted once); `_page3_fits`: at 640x360 and 960x495 every page-3 row lies inside `PANEL` (reuse `_fit`'s measuring).
- [ ] **Step 2: Run** `"$G" --headless --path . --script res://tests/run_part.gd -- --only=test_mission_verbs` and `--only=test_legend`. Expected: FAIL (`MissionVerbs` not found; 2 pages).
- [ ] **Step 3: Implement** `mission_verbs.gd` and page 3. Page 3 row: verb word in `UiTheme.COL_GOLD`, `does` in `UiTheme.COL_TEXT`, then equipped names in `COL_TEXT`, others in `COL_DIM`, cut to the row's room with `" +%d"`; one line per verb, `TEXT_S`. A verb with no equipped power is drawn dim. `Mission.open_legend()` passes `_rules.loadout`.
- [ ] **Step 4: Run** the two suites -> PASS; then `bash tools/dev/run_suite_parallel.sh 8` -> `failures=0`.
- [ ] **Step 5: Commit** `feat: mission verbs and the legend's third page (Mission clarity T1)`.

### Task 2: The why-not hook, the gate, the phases, the test kit, the blocks

**Files:**
- Modify: `src/game/mission/mission_director.gd` (hook, margin, `_cast_reaches`, `hint_phases`), every director that overrides `hint_phase()` (add `hint_phases()` beside it: spec §5's phase lists), `src/game/ui/hud.gd` (wiring)
- Create: `src/game/ui/why_not_gate.gd` (class_name `WhyNotGate`), `tests/clarity_kit.gd` (preloaded helper, no class_name), `tests/test_why_not.gd`, six stubs `tests/test_clarity_{assassinate,convert,intercept,hunt,escort,raze}.gd` (`static func run(t) -> void: pass`)
- Modify: `tests/run_all.gd` (register the 7 new files), `tests/test_mission_steps.gd` (`_resolve`), `src/game/mission/mission_steps.gd`, `src/game/mission/mission_hints.gd`, `tests/test_mission_hints.gd` (reorder only)

**Interfaces:**
- Produces:
  - `MissionDirector.why_not(key: String, at: Vector2) -> String` (virtual, `""`)
  - `MissionDirector.hint_phases() -> PackedStringArray` (virtual, `[""]`)
  - `const WHY_MARGIN := 1.0`; `func _cast_reaches(key: String, at: Vector2, g: Vector2) -> bool` = `at.distance_to(g) <= Crowd._cast_radius(key) + WHY_MARGIN`
  - `WhyNotGate`: `const REPEAT := 30.0`, `const GAP := 4.0`, `func allow(text: String, now: float) -> bool`
  - `Hud._on_cast_why(slot: int, key: String, at: Vector2) -> void` (connected to `Rules.cast_made` in `setup()`), `var _why_clock := 0.0` (real seconds, `_process`)
  - `ClarityKit` (`const ClarityKit := preload("res://tests/clarity_kit.gd")`):
    - `static func world(def: MissionDef, made: MissionDirector = null) -> Dictionary` -- `test_tier2_groundwork.world()`'s dictionary
    - `const DEFAULT_KEY := {"kill": "doom", "scare": "smite", "lead": "whisper", "lure": "wisp", "confuse": "discord", "hold": "oath", "burn": "ember", "strike": "smite", "rot": "blight", "seal": "noleave", "banish": "skylift", "calm": "belllies"}`
    - `static func apply(s: Dictionary, verb: String, target: Variant, key := "") -> String` -- lands the verb's effect as its power does, then emits `Rules.cast_made(0, key, at)`; returns the key. Person: kill `crowd._field.kill(p, key)`; scare `p.panic(at, 1.0)`; lead `p.whisper(s.get("to", p.ground_pos + Vector2(2, 0)), MindWhisperFx.LINGER)`; lure `p.lure(at, 6.0, at)` with `at = s.get("light", p.ground_pos)`; confuse `p.confuse(DiscordFx.DISCORD_TIME)`; hold `p.compel(p.ground_pos, 6.0, 1.0, Color.WHITE)`; banish `p.ground_pos =` the nearest point `Walls.outside()` holds. Structure: burn `crowd.fires.ignite(s, 0.6)`; strike `env.damage_radius(s.center(), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")`; rot `director.blighted(s.center())`. Seal and calm: the patterns of `tests/test_tax_collector.gd:1053` (a sealed `NoLeaveFx`) and `tests/test_warning.gd:_lie`.
    - `static func assert_read_only(t, s: Dictionary, label: String) -> void` -- snapshot (every person's `ground_pos`, `mind`, `inside`; `d.report()`; `d.hint_phase()`; `d.tags()` labels; a `Rules.banner` emission counter), call `d.why_not(DEFAULT_KEY[v], g)` for every verb and every tag's ground point, snapshot again, `t.check(equal)`.
    - `static func check_coverage(t, ids: PackedStringArray, cases: Array) -> void` -- `cases` rows `{"id", "phase", "verb"}`; for every step and hint of `ids` (each phase in the director's `hint_phases()`), every `MissionVerbs.named_in()` verb has a case; every label `<= MAX_LABEL`.
    - `static func colours_ok(t, d: MissionDirector, text: String, label: String) -> void` -- each `(gold|orange|red|blue|grey)` in `text` is the colour of some tag in `d.tags()` (gold `d8b23a`, orange `ff9a3a`, red `c8342a`, blue `8fb8e8`, grey `9a948a`, by nearest RGB).

- [ ] **Step 1: Write the failing tests** in `tests/test_why_not.gd`:
  - `_base`: `MissionDirector.new().why_not("smite", Vector2.ZERO) == ""` and `.hint_phases() == PackedStringArray([""])`.
  - `_gate`: `g.allow("", 0) == false`; `allow("A", 0)` true; `allow("A", 10)` false; `allow("B", 2)` false (GAP); `allow("B", 5)` true; `allow("A", 31)` true.
  - `_hud`: a `Hud` set up with a stub director whose `why_not` returns `"NOPE"`; emit `cast_made` -> `hud.banners()` has `"NOPE"` once; emit again 1 s later -> still once; a stub returning `""` adds nothing; `rules.director = null` and `rules.free_play = true` each add nothing and raise no error.
  - `_flood` (Review Focus 2): stub returns "A" then "B" for two casts 1 s apart -> one banner.
  In `tests/test_mission_steps.gd` add `_resolve`: for every id of `_all_ids()` and its `MissionBook.city_id(id, &"capital")` twin, with `def.make_director()` (not set up), every step's `"ph"` and every `MissionHints.LINES` key `"<id>.<ph>"` is in `hint_phases()`; every phase of `hint_phases()` resolves to a step (`MissionSteps.index_for() >= 0`).
- [ ] **Step 2: Run** `--only=test_why_not` and `--only=test_mission_steps` -> FAIL.
- [ ] **Step 3: Implement** the hook, the gate, the HUD wiring and every director's `hint_phases()` (the phase lists of spec §5; a subclass returns the union with `super()` where it adds phases: Lost Lamb, Starfall). Banner via `push_banner(text, true)`; nothing through `Rules.banner`.
- [ ] **Step 4: Reorder** `MissionSteps.STEPS`, `MissionHints.LINES` and `test_mission_hints.gd`'s `SPEC` into six blocks, each opened by a comment line `# --- clarity block: <group> ---` and closed by a blank line, in this order: intercept (warning, omen, long_night, bell_ringers, silence_witness, festival, feast_festival, market_panic, procession, feast_procession), assassinate (informer, tax_collector, bishop, expel_inquisitor), escort (lost_lamb, prisoner, exodus, hide_faithful, face_halcyon), raze (spoiled_harvest, crowns_bread, armoury, heart_of_faith, judgement, last_judgement), hunt (heretic_hunt, lantern_eye, break_hunt), convert (first_prayers, miras_house, sermon, vigil_flame, relic_run, broken_lanterns, first_taste); the rest (capital_sandbox, remembrance, the Lantern's) after. No text changes. Write `tests/clarity_kit.gd` and the six stubs; register the seven new suites in `run_all.gd`.
- [ ] **Step 5: Run** the two suites -> PASS; `run_suite_parallel.sh 8` -> `failures=0`; `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|informer|tax|lamb|warning|hunt|heart)'` -> all match.
- [ ] **Step 6: Commit** `feat: why-not hook, gate, hint phases and the clarity test kit (Mission clarity T2)`.

---

Tasks 3-8 run **in parallel** (one worktree each, after Task 2). Each follows the same five steps; the task lists what differs.

**The steps of every group task:**
- [ ] **Step 1: Write the failing cases** in `tests/test_clarity_<group>.gd`: `static func cases() -> Array` (the table below, `{"id", "phase", "verb"}`), `run(t)` calling one function per row (set the phase in a `ClarityKit.world()`, `ClarityKit.apply()`, `Kit.run_for(s, <seconds>)`, assert the **counts** column), one per why-not row (`d.why_not(key, at) == <text>` and `== ""` for the same cast `Crowd._cast_radius(key) + WHY_MARGIN + 2` away), `ClarityKit.assert_read_only()` per director, `ClarityKit.check_coverage(t, <ids>, cases())`, and `ClarityKit.colours_ok()` on each new step and hint in its case's world. Update the group's rows of `tests/test_mission_hints.gd` `SPEC` to the spec's new lines. Fix any existing suite of the group that asserts the old copy.
- [ ] **Step 2: Run** `--only=test_clarity_<group>` -> FAIL (old copy, no `why_not`).
- [ ] **Step 3: Implement** the read-only readouts listed, each director's `why_not()` (gate on `_cast_reaches()` to the phase's targets first; judge by the key's `MissionVerbs.verbs_of(key)`), and the copy: the group's block in `mission_steps.gd` and `mission_hints.gd`, verbatim from the spec section named.
- [ ] **Step 4: Run** `--only=test_clarity_<group>`, `--only=test_mission_steps`, `--only=test_mission_hints`, the group's own mission suites -> PASS; `run_suite_parallel.sh 8` -> `failures=0`; `refs_check.sh --only='<regex>'` -> all match.
- [ ] **Step 5: Commit** `feat: clear steps, hints and why-not banners for <group> (Mission clarity T<n>)`, with any `Ruling:` lines.

A case "counts" means the director's own progress moves within the seconds given: the objective's n/m rises, the phase leaves, or the named list (`guards(i)`, `on_guard()`, `onlookers()`) shrinks -- the column says which.

### Task 3: Assassinate group (worst first: Informer, Tax Collector, Bishop, Expel)

**Files:** `src/game/mission/informer_director.gd`, `tax_collector_director.gd`, `bishop_director.gd`, `expel_inquisitor_director.gd` (and `assassinate_director.gd` only for a shared read-only helper); `tests/test_clarity_assassinate.gd`; blocks "assassinate". Copy: spec §5.2. refs: `'(informer|tax|bishop|expel)'`.

**Read-only readouts:** `InformerDirector.hint_seconds() -> float` = `visit_in(contacts.find(contact_now()))` in `waiting`, else 0. `TaxCollectorDirector.hint_seconds() -> float` = the current collector's visit seconds left in `inside`, the seconds to the next set-out in `next`, else 0.

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| informer | "" | confuse (discord) | contact (onlookers confused with him) | `turned_count()` 0 -> 1 at once |
| informer | "" | lead (whisper) | contact, onlookers cleared | `turned_count()` 1 |
| informer | found | kill (doom) | the informer | `quarries[0].dead` |
| informer | hiding | burn (ember) | the house he hides in | he is out of doors within 3 s |
| tax_collector | "" | kill (doom) | collector walking | `stopped()` 1 |
| tax_collector | "" | banish (skylift) | collector | state OUT |
| tax_collector | inside | seal (noleave) | a visited door, guards away | dead `MOB_AFTER` after he comes out |
| tax_collector | hiding | burn (ember) | counting-house | flushed (`q.flushed`) |
| bishop | waiting/guarded | kill (doom), hold (oath) | a Knight on guard | `guards_at(i)` shrinks |
| bishop | open | burn (ember) | refuge | phase -> burning |
| bishop | square | kill (doom) | the bishop | dead |
| expel_inquisitor | "" | kill (doom), banish (skylift) | a warden | `stopped()` +1 |
| expel_inquisitor | captain | scare (smite) x3, 8 s apart | the captain | state OUT after the third |

Why-not cases: spec §5.2's (Informer 3, Tax 3, Bishop 1, Expel 2). Review Focus 5: a whisper that turns the contact -> `why_not("whisper", at) == ""` (call it after `cast_made` as the HUD does). The user's case: in `waiting`, `apply(s, "banish", companion)` and `apply(s, "confuse", contact)` -> `"TOO EARLY - NO WORD YET"`, and `turned_count()` stays 0 after `visit_in()`-1 s.

### Task 4: Convert and rite group (First Prayers, Broken Lanterns, Relic Run, Vigil Flame, Sermon, Mira's House, First Taste)

**Files:** `first_prayers_director.gd`, `broken_lanterns_director.gd`, `relic_run_director.gd`, `vigil_flame_director.gd`, `sermon_director.gd`, `miras_house_director.gd`, `first_taste_director.gd`; `tests/test_clarity_convert.gd`; blocks "convert". Copy: spec §5.6. refs: `'(prayers|lanterns|relic|flame|sermon|miras|first_taste|rite)'`.

**Read-only readouts:** `FirstPrayersDirector.hint_seconds()` = `walk_due()` less the timeline's elapsed in "" (0 when INF or a walker is out); `VigilFlameDirector.hint_seconds()` = `WREN_AT` stretched less elapsed in "" before Wren (RelicRun overrides it back to its own, 0 unless it has one).

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| first_prayers | "" | lead (whisper) | a poor man, to the door, door clear | he is inside (`_reading`) |
| first_prayers | "" | lure (wisp) | light at the shrine, a poor man within `FETCH_R` | he walks to it (`mind` OBSERVE, goal near the door) |
| first_prayers | watched | burn (ember) | a house within `FIRE_PULL` | `hint_phase()` leaves watched |
| first_prayers | watched | calm (belllies) | the town | liners stood down |
| first_prayers | watched | lead, confuse (whisper, discord), kill | a Faithful at the door | `faithful_seeing(door, SIGHT)` null |
| miras_house | "" | lead, lure | a grieving, to the door | inside |
| sermon | rapt | confuse, scare, lead | the preacher | `preaching()` false |
| sermon | "" / coming | lead | a listener not rapt | goes in |
| sermon | watched | lead, confuse, kill | a sentry | the door unwatched |
| sermon | report / bell | kill | runner / keeper | report closed / keeper dead |
| vigil_flame | "" | hold (oath), lead, kill | an acolyte | not counted as a seer when Wren swaps |
| vigil_flame | wren / homeward | lead (whisper) [lure (wisp): test, keep only if it counts] | Wren | `swapped` after `SWAP_SECONDS` |
| vigil_flame | carry | lead | Wren to the shrine | night won |
| relic_run | "" / last_halt | lead | Pip to the halt | aboard after `BOARD` |
| relic_run | moving / watched / aboard | hold (oath), kill | a warden | `watched()` false |
| relic_run | citadel | kill x3 | carter and escorts | **decides the copy** (spec §5.6, Q6): if Pip can then board, step `Kill the cart's three hands` and a case for it; else `The relic is lost at the Citadel`, no verb, `Ruling:` line |
| broken_lanterns | "" | strike (heaven) | an unguarded lantern | broken, draining |
| broken_lanterns | "" | (the bearer: the verb the test proves keeps him off -- kill, hold or lure -- becomes the hint's "keep the flame-bearer off" words) | flame-bearer | no relight in 20 s |
| broken_lanterns | knights | kill, lead, lure (far) | the Knight | `guard_of(s)` null |
| first_taste | drag | hold (oath), scare | a gripping breaker | his grip resets |
| first_taste | march | kill, scare | all but one marcher | the march stops |
| first_taste | cleanse | kill, scare | a kneeler | the cleanse stops |

Why-not cases: spec §5.6 (First Prayers 4, Mira 2, Sermon 1, Vigil 2, Relic 1, Broken Lanterns 2, First Taste 1).

### Task 5: Intercept group (Market Panic, Bell-Ringers, Warning/Starfall/Omen/Long Night, Festival, Procession, Silence the Witness)

**Files:** `market_panic_director.gd`, `festival_director.gd`, `bell_ringers_director.gd`, `ringer_director.gd`, `warning_director.gd`, `starfall_director.gd`, `procession_director.gd`, `silence_witness_director.gd`, `witness_director.gd`; `tests/test_clarity_intercept.gd`; blocks "intercept". Copy: spec §5.1. refs: `'(panic|ringers|warning|starfall|festival|feast|procession|silence_witness|night)'`.

**Read-only readouts:** `FestivalDirector.hint_seconds()` = seconds to the close in "" (Market Panic: its own close or 0, as its lines have no `{n}`); `ProcessionDirector.hint_seconds()` = blessing seconds left in `blessing`, seconds to boarding in `dock`.

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| market_panic | "" / steadied | kill, lead, confuse, hold (oath) | a warden on guard | `on_guard()` shrinks |
| market_panic | open / coming | scare (smite), kill | goers | broken count rises |
| festival | "" / packed | scare, kill | goers | broken count rises |
| festival | address | kill | the Mayor | dead |
| bell_ringers | "" / relay | kill unseen | ringer / witness | `stopped()` +1 |
| bell_ringers | mates | lead, lure | a mate, beyond `DOOM_WITNESS` | a kill then is unseen |
| bell_ringers | climbing | lead, scare | the climber | off the rope |
| bell_ringers | bell | kill, hold | the keeper | no toll |
| warning (board) | stars / running | kill unseen; banish; calm | the carrier | warning stopped (`solved_by` kill / out / lie) |
| warning | relay / bell | kill unseen | witness / ringer | stopped |
| procession | blessing / dock | kill | the Prince | dead |
| silence_witness | "" / relay / near | kill (mates held: hold) ; banish | the witness | `stopped()` +1 |

Why-not cases: spec §5.1 (Warning 1, Bell-Ringers 1, Market/Festival 3, Procession 1). Review Focus 3: Starfall with two warnings running -- a kill that stops one returns "" though it lands near the other.

### Task 6: Hunt group (Heretic Hunt, Lantern's Eye, Break the Hunt)

**Files:** `hunt_director.gd` (the shared guard why-not), `heretic_hunt_director.gd`, `lantern_eye_director.gd`, `break_hunt_director.gd`; `tests/test_clarity_hunt.gd`; blocks "hunt". Copy: spec §5.5. refs: `'(hunt|eye)'`.

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| heretic_hunt | "" / guarded | kill, lead, confuse; lure (light beyond `guard_reach`) | a guard | `party_on(i)` shrinks |
| heretic_hunt | open | strike (smite), rot (blight) | the standard | broken |
| heretic_hunt | captain / searching | kill | the captain | dead |
| lantern_eye | guarded | as heretic_hunt | a guard | `party_on(i)` shrinks |
| lantern_eye | open / eye | strike x2, rot | the mirror | shattered |
| lantern_eye | shattered | kill, lead, confuse | a wright | `_working()` false |
| break_hunt | "" / carried / taken | kill, scare | a bearer with no escort guarding | standard broken |
| break_hunt | "" | hold (oath), scare | the escorts | `_guarded(i)` false |

Why-not cases: spec §5.5 (Heretic 2, Eye 1 more, Break the Hunt 2).

### Task 7: Escort group (Lost Lamb, Prisoner, Face Halcyon, Exodus, Hide the Faithful)

**Files:** `escort_director.gd` (shared: `watch_change_in() -> float`, read-only; the captor why-nots), `lost_lamb_director.gd`, `prisoner_director.gd`, `face_halcyon_director.gd`, `exodus_director.gd`, `hide_faithful_director.gd`; `tests/test_clarity_escort.gd`; blocks "escort". Copy: spec §5.3. refs: `'(lamb|prisoner|exodus|hide_faithful|face_halcyon)'`.

**Read-only readouts:** `EscortDirector.watch_change_in()` = seconds to the next watch change (0 when none is scheduled); `LostLambDirector.hint_seconds()` = to `BOLT_AT` (stretched) in "" while neither led nor bolting, `watch_change_in()` in `gate`; `PrisonerDirector.hint_seconds()` = `watch_change_in()` in `gate`; `FaceHalcyonDirector.hint_seconds()` = the burning believer's seconds left in `pyre` (else 0, as today).

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| lost_lamb | "" / led | lead, lure (near) | the acolyte | moves (`led`) |
| lost_lamb | "" | scare (smite within `BOLT_REACH`) | by the acolyte | `bolting` |
| lost_lamb | running / gate | hold (oath), scare, kill | a watcher | `_watching()` false |
| lost_lamb | caught | hold, scare, kill | the captor | released |
| lost_lamb | clear | lead | the acolyte | escaped |
| prisoner | bound | kill, lead, confuse | each gaoler; then strike/burn the stocks | freed, not seized |
| prisoner | "" | lead, lure | her | moves |
| prisoner | caught / hounds / gate | hold, scare, kill | captor / hound / watch | released / not seeing |
| exodus | "" / shut | lead | the lamp | the household follows |
| exodus | caught / hounds / gate / waiting | hold, scare, kill | the watcher | released / not seeing |
| hide_faithful | "" / trail / seized | hold, scare, kill | watch / searcher / seizer | not seeing / released |
| face_halcyon | "" / pyre / gaze | hold, scare | escorts until fewer than `FH_ESCORT_HOLD` able | believer freed |

Why-not cases: spec §5.3 (Lamb 2, Prisoner 2, Exodus 0-1, Hide 0-1, Face 2; the "only if the code ignores it" rows are kept only when a test shows the cast is ignored). Review Focus 3: Exodus with two households out.

### Task 8: Raze group (Spoiled Harvest, Armoury, Crown's Bread, Heart of Faith, Last Judgement/Judgement)

**Files:** `raze_director.gd` (shared read-only helpers only), `harvest_director.gd`, `armoury_director.gd`, `crowns_bread_director.gd`, `heart_of_faith_director.gd`, `last_judgement_director.gd`, `judgement_director.gd`; `tests/test_clarity_raze.gd`; blocks "raze". Copy: spec §5.4. refs: `'(harvest|bread|armoury|heart|judgement)'`.

**Read-only readouts:** `HarvestDirector.hint_seconds()` = `step_seconds()` in `empty`; `ArmouryDirector.hint_seconds()` = `step_seconds()` in `not_yet`.

| id | phase | verb (key) | target | counts |
|---|---|---|---|---|
| spoiled_harvest | "" / watchman | scare, lead, confuse, kill | a watchman | `guards(s)` shrinks |
| spoiled_harvest | "" | burn, rot | a granary, grain in, unguarded | spoiled |
| spoiled_harvest | "" | banish | the carter | spoiled |
| crowns_bread | not_yet / engineers | kill, lead, confuse, scare | an engineer | `guards(i)` shrinks |
| crowns_bread | open | burn (granary, mill), strike (bridge) | the target | razed |
| armoury | not_yet / guarded | kill, hold | an armed man | `guards(i)` shrinks |
| armoury | stone / open | strike; burn (not stone) | the target | razed |
| heart_of_faith | not_yet / guarded | kill, hold | a Knight | `guards_at(i)` shrinks |
| heart_of_faith | open | burn | the target | burning |
| heart_of_faith | litter / on_foot | kill | bearers / Odran | litter falls / won |
| heart_of_faith | rite | scare, lead, confuse | Odran | the rite restarts |
| last_judgement | "" | strike | the Citadel | destroyed |
| last_judgement | rite | kill, scare | clergy in the ring | the rite breaks |

Why-not cases: spec §5.4 (Harvest 4, Crown's Bread 3, Armoury 3, Heart 3).

---

### Task 9: Notes (after Tasks 3-8 are merged)

**Files:** Create `docs/KAK_Mission_Clarity_Summary.md` and `docs/KAK_Mission_Clarity_Rulings.md`; modify `README.md` (the `H` row: "again for the second and third pages (what your powers do)"; one Versions sentence).

- [ ] **Step 1:** Summary: the twelve verbs and their powers (from `MissionVerbs`), the why-not banners by mission (from the group tests' cases), the legend's third page, the open questions Q1-Q8 as asked, and the tour captions that still name a power (grep `tour()` strings for `PowerBook` names) for a later pass.
- [ ] **Step 2:** Rulings: every `Ruling:` line from Tasks 1-8's commit bodies.
- [ ] **Step 3:** `bash tools/dev/run_suite_parallel.sh 8` -> `failures=0`; `bash tools/dev/refs_check.sh` (all 233) -> all match.
- [ ] **Step 4: Commit** `docs: mission clarity summary, rulings and README (Mission clarity T9)`.

## Task order and parallelism

1. Task 1, then Task 2 (Task 2's kit uses `MissionVerbs`).
2. Tasks 3, 4, 5, 6, 7, 8 in parallel worktrees, each cut from Task 2's commit. They share no file but their own blocks; the controller merges them in order 3-8 (block separators keep the shared tables conflict-free).
3. Task 9 after all six merge; then landing (`land.sh`).
