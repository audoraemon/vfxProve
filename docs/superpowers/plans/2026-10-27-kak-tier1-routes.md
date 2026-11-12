# KAK Tier 1 Routes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, sonnet task review for mission and shared code, none for docs; dispatches from `.superpowers/sdd/t1routes/implementer.md`).

**Goal:** every god type wins all five Tier 1 missions with only its two Tier 1 powers (spec 2026-10-26 §5.2): the three shared rules (out of the walls, he bolts, they come to pray), the new routes of the user's table, a scripted policy per type per mission, the 30-pair gate, and the title's Campaign entry switched to Endless Night.

**Architecture:** one shared piece, `Walls` (`src/game/mission/walls.gd`, static: outside the mission's walls, the nearest map exit) plus a leaver's bookkeeping on `MissionDirector`; every new mission rule lives in the Tier 1 director (`StarfallDirector`/`WarningDirector` behind opt-in flags, `TaxCollectorDirector`/`AssassinateDirector` behind `walls_stop`, `HarvestDirector`, `LostLambDirector`, `FirstPrayersDirector`), so the shared bases play every other mission exactly as before. No power's effect changes: the directors read `Crowd.is_bell_lying()`, the Blight hooks, `Person.sick_left`, and a new read-only `Rules.last_fx()`. The scripted player gets `--god=<type>:1` (drafts `GodTree.keys_for(type, 1)`, plays `tools/dev/routes/god_t1.gd`'s dispatch to one file per mission, `tools/dev/routes/god_t1/<scenario>.gd`, `act_<type>()`), and `gate.sh --god=`.

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; scripted play `tools/dev/behaviour_check.gd`; gates `tools/dev/gate.sh`; FLOW (`Game._flow_test()`); landing `tools/dev/land.sh`.

**Spec:** `docs/superpowers/specs/2026-10-27-kak-tier1-routes-design.md` (cited §N). Rulings: `.superpowers/sdd/t1routes/rulings.md` (D1-D9 and the controller's answers to spec §13; binding over this text).

## Global Constraints

- G = `/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`. Milestone worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r`, branch `god/t1routes` (base `420a4e37`). Tasks 2-6 each in their own worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-god-t1r-t<N>`, branch `god/t1r-t<N>` cut from `god/t1routes` after Task 1, merged in task order onto `god/t1routes` by the controller (D9). Every command from the worktree root; foreground only, each under 10 minutes (a long references slice is split into several `--only=` runs). Import once and again after a new `class_name` or test file: `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
- Never cd elsewhere, never edit another worktree, never stop a process you did not start (record the PIDs you launch; other sessions run Godot, refs_check.sh and land.sh on this machine).
- Per task: focused tests, then `bash tools/dev/run_suite_parallel.sh 8` (`3` while other tasks run in parallel; expect `failures=0`), then the task's `refs_check.sh --only=...` (`--jobs=2` in parallel), then its gates. FLOW only where the task says, alone (`tasklist | grep -i godot` first; memory `flow-needs-quiet-machine`), never during the parallel group (the controller runs it after merging the group).
- Scripted runs are exact only with `--fixed-fps 60` and hit-stop off: every `--route=b`, `--case=toll` and `--god=` run turns hit-stop off (Smite's hit-stop is wall clock; memory `mission-test-not-exact`).
- **References (D6):** may move, re-recorded in the commit that moves them with the reason in its body — the five missions' 99 rows: `tax_*`, `harvest_*`, `lamb_*`, `prayers_*` (with `tax_toll_*`, `prayers_toll_*`), `warning_b_play_*`, `starfall_toll_*`, `capital_{starfall,tax,harvest,lamb,prayers}_*`. **Must not move:** the other 187 rows, `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`. A mover outside the 99 is a bug in the task that moved it; nothing is re-recorded for it. New rows: `god_<type>_<scenario>_play_<n>` in `tools/dev/refs/god_t1_<scenario>.tsv` (one file per mission task).
- **Every new rule is opt-in** in a shared base (`WarningDirector`, `AssassinateDirector`): a flag defaulting to the old behaviour, set only by the Tier 1 director; `EscortDirector`, `MirasHouseDirector`, `RazeDirector` and every power effect are not edited. A task that must touch a shared base proves its protected rows (its task section lists them).
- **The user's mission rules (D4) are every mission task's gate:** every timed wait ≤ 60 s; doing nothing loses 3/3; per-type play wins ≥ 2/3; no idle stretch over 45 s in a play run; route A median 180-240 s, route B and per-type (tier missions) 150-270 s, the board Warning's median reported only (spec §9, as the controller rules R-a); every moving target tagged with an edge arrow; countdowns in tags; hints fit `Hud.HINT_LINES` lines of `Hud.HINT_W`.
- **Existing gates keep their verdicts:** each mission's route A, route B, toll and `none` gates PASS as before, in Aldermere and the Capital (D5). If a new rule breaks one, first make that policy answer the rule as a player would; never bend the rule for it.
- **A gate miss:** first make the scripted policy work the opposition as a player would; then tune in the spec's order (§4.4, §5.5, §6.9, §7.5, §8.8), at most three rounds; if it still misses, report DONE_WITH_CONCERNS with the numbers. Never tune the opposition down to pass.
- Numbers from the spec are exact; *tunable* ones are first guesses. Copy marked *(my call)* in the spec is a first draft; every hint line is tested to fit.
- Freed bodies: never touch a freed node; read people held across frames through `MissionDirector._alive()` / `is_instance_valid()`; a person removed by `send_off()` may be freed the next frame.
- Tests: `t.check(cond, "message")`, one `static func run(t) -> void` per file, sub-tests `static func _name(t) -> void`, each new file one line in `tests/run_all.gd` SUITES. A test that turns `GodTree.dev_fill` on turns it off; a test that calls `City.use(&"capital")` calls `City.use(&"aldermere")` before it returns. Tests come first where a task says RED then GREEN.
- Style: comments say what and why, in the game's plain English (versions noted as `(god T1R)`); no full code from this plan pasted as-is (the plan gives interfaces, tests and numbers only).
- Shared files: stage only your own hunks (`git add -p`, `git diff --cached`); the owners are in the table below. Python here defaults to cp874: pass `encoding='utf-8'` or use the Edit tool.
- No PixelLab (D9). Text, drawn shapes and existing icons only.
- Commits end with `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>` (or the implementer's own model). Every `Ruling:` a report makes goes to `.superpowers/sdd/t1routes/rulings.md` (the controller) and the rulings doc (Task 10).
- D8: P2 (Lantern Notice, Hunt, seals) is being built on `claude/god-p2-lantern-04cddc`; do not touch P2 code. Whichever lands on `feat/god-progression` second trial-merges onto the first and re-gates.

## Review Focus

1. **Opt-in rules leave the other missions alone:** with the flags off, the campaign Warning, the Omen, The Bell-Ringers, The Informer and The Bishop play exactly as before. Tests: Task 2 `_flags_off`, Task 3 `_walls_off`; references in Tasks 2, 3, 9.
2. **Out of the walls is the same rule everywhere:** however a carrier, collector or carter gets past `town().grow(MARGIN)` (gate, whisper, flight, fold), he is stopped once, sent off the map and never counted twice; the chain starts at that second. Tests: Task 1 `_walls`, `_fold_outside`, `_send_off`; Tasks 2-4 `_out_*`.
3. **Doing nothing still loses 3/3** after the bolt, the walking poor and the early carters. Gates: each mission task's `none` case, both towns.
4. **No hidden loss:** a dead carter is replaced; a guarded granary refuses the plague and Blight with a banner; a collector at a door with his guard near shows `GUARDED`. Tests: Task 4 `_replaced`, `_plague_guarded`, `_blight_guarded`; Task 3 `_mob_guarded`.
5. **The per-type policies use only their two powers:** `--god=<type>:1` drafts exactly `GodTree.keys_for(type, 1)`; a policy casting another key is refused by the slot lookup. Test: Task 1 `_god_draft`; Task 7 `_all_filled`.

---

## Task order and parallelism

| # | Task | Model | Review | Group |
|---|---|---|---|---|
| 1 | Groundwork: `Walls`, the leaver, `Rules.last_fx()`, `--god=<type>:1` per-type policies, `gate.sh --god=` | sonnet | sonnet | serial |
| 2 | The Warning (Starfall): W1, W2, six policies, gates, references | sonnet | sonnet | **P** (own worktree) |
| 3 | The Tax Collector: T1, T2, six policies | sonnet | sonnet | **P** |
| 4 | Spoiled Harvest: H0-H5, six policies | sonnet | sonnet | **P** |
| 5 | The Lost Lamb: L1, L2, six policies | sonnet | sonnet | **P** |
| 6 | First Prayers: F1-F5, six policies | sonnet | sonnet | **P** |
| 7 | The 30-pair gate (`god_gate.sh`) and the real tree's Tier 1 test | sonnet | none | serial |
| 8 | The title switch (D7) with FLOW | sonnet | sonnet | serial |
| 9 | Landing checks on `feat/god-progression` | sonnet | none (controller's opus review) | serial |
| 10 | Notes: summary, rulings doc, Dev Ledger lines | sonnet | none | serial |

Order: 1 → P (2, 3, 4, 5, 6 at once, each in its worktree; merged onto `god/t1routes` in number order, the controller resolving shared-file hunks per the table below and rerunning the suite after each merge) → FLOW alone on the merged tree → 7 → 8 → 9 → 10 → the controller's opus milestone review, one fix wave, sonnet re-review, tag `kak-god-t1r` locally (D1; the controller asks the user before any push).

**Shared files and their owners** (one hunk each; keep all on merge):

| File | Task 1 | Tasks 2-6 (one each) | 7-8 |
|---|---|---|---|
| `src/game/mission/walls.gd` (new) | 1 only | -- | -- |
| `src/game/mission/mission_director.gd` | 1: `send_off()`, `_step_leaving()`, `leaving` | -- | -- |
| `src/game/rules.gd` | 1: `last_fx()` | -- | -- |
| `src/game/mission/warning_director.gd`, `starfall_director.gd` | -- | 2 only | -- |
| `src/game/mission/assassinate_director.gd`, `tax_collector_director.gd`, `assassinate_objective.gd` | -- | 3 only | -- |
| `src/game/mission/harvest_director.gd` | -- | 4 only | -- |
| `src/game/mission/lost_lamb_director.gd` | -- | 5 only | -- |
| `src/game/mission/first_prayers_director.gd`, `temple_report.gd` (`drop()` only) | -- | 6 only | -- |
| `src/game/mission/mission_book.gd` | -- | 3 `tax_collector()`, 4 `spoiled_harvest()`, 5 `lost_lamb()`, 6 `first_prayers()` (copy only) | -- |
| `src/game/descend/tier_book.gd` | -- | 2: `_warning()` copy only | -- |
| `src/game/mission/mission_hints.gd` | -- | each its own mission's keys | -- |
| `tests/test_mission_hints.gd` | -- | each its own mission's spec lines | -- |
| `src/game/town/cities/capital_missions/<mission>.gd` | -- | its own file (only if a number needs the Capital's value) | -- |
| `tools/dev/behaviour_check.gd` | 1: `--god` dispatch, `_god_route()`, header | each may edit only its own scenario's A function (`_warning`, `_tax`, `_harvest`, `_lamb`, `_prayers` and their helpers) when a new rule breaks A | -- |
| `tools/dev/routes/tier1_b.gd` | -- | each its own mission's `act_*`/`state_*` when a new rule breaks B | -- |
| `tools/dev/routes/god_t1.gd` (new dispatcher) | 1 only | -- | 7: `_all_filled` reads it |
| `tools/dev/routes/god_t1/<scenario>.gd` (new) | 1: five stubs | its own file | -- |
| `tools/dev/gate.sh` | 1: `--god=` | -- | -- |
| `tools/dev/god_gate.sh` (new) | -- | -- | 7 only |
| `tools/dev/refs/references.tsv`, `routes_t1.tsv`, `lantern_*.tsv` | -- | each its own mission's rows | -- |
| `tools/dev/refs/capital_<mission>.tsv`, `god_t1_<scenario>.tsv` | -- | its own files | -- |
| `tests/run_all.gd` SUITES | 1: two lines | none expected (existing files grow) | 7, 8: none expected |
| `src/game/ui/title_screen.gd`, `src/game/game.gd`, `tests/test_options.gd` | -- | -- | 8 only |
| `tests/test_god_tree.gd` | -- | -- | 7: `_tier1_real` |

---

### Task 1: Groundwork

**Goal:** spec §2.1's shared piece, §3's `Rules.last_fx()`, §9's plumbing. No reference moves.

**Files:**
- Create: `src/game/mission/walls.gd` (`class_name Walls`), `tools/dev/routes/god_t1.gd` (no `class_name`: preloaded as `GOD_T1` by `behaviour_check.gd` and as `GodT1` by the tests, as the tier files are), `tools/dev/routes/god_t1/warning.gd`, `tax.gd`, `harvest.gd`, `lamb.gd`, `prayers.gd` (stubs).
- Modify: `src/game/mission/mission_director.gd` (leaver), `src/game/rules.gd` (`last_fx()`), `tools/dev/behaviour_check.gd` (`--god` dispatch, `_god_route()`, header), `tools/dev/gate.sh` (`--god=`).
- Test: `tests/test_walls.gd`, `tests/test_god_routes.gd` (new; SUITES).

**Interfaces (produces):**
- `Walls.MARGIN := 0.5` (*tunable*, spec §2.1); `static func outside(at: Vector2, city: CityDef = null) -> bool` — `not (city or City.current()).town().grow(MARGIN).has_point(at)`; `static func way_off(at: Vector2) -> Vector2` — the nearest of `City.current().exits()` (straight line), `Vector2.INF` with none.
- `MissionDirector.leaving: Array = []` (untyped: bodies are freed); `func send_off(p: Person) -> void` — `crowd.off_duty(p)` if on duty, `p.go_duty(Walls.way_off(p.ground_pos))`, appended to `leaving` (once); `func _step_leaving() -> void` — each one alive within 1.2 of his way off is removed (`crowd._field.remove(p)`, `crowd.escape(p)`), dead or freed ones dropped; one knocked off duty (a fright) is sent again when back in a `RECALL_MINDS` mind. A director that calls `send_off()` calls `_step_leaving()` in its `step()`. `func is_leaving(p: Variant) -> bool`.
- `Rules.last_fx() -> FxTimeline` — the latest cast's effect (`_casts.back().fx`), null with none; read-only.
- `tools/dev/routes/god_t1.gd`: `const SCENARIOS := ["warning", "tax", "harvest", "lamb", "prayers"]`; `const FILES := {scenario: preload("res://tools/dev/routes/god_t1/<scenario>.gd")}`; `static func has_policy(scenario: String, type: String) -> bool` (the file has `act_<type>`); `static func filled(scenario) -> PackedStringArray` (its file's `FILLED`); `static func act(scenario, type, bc, ctx) -> String`; `static func state(scenario, bc, ctx) -> String`.
- Each `god_t1/<scenario>.gd`: `const FILLED := []` (the types whose policy is written; each mission task fills it), `static func act_<type>(bc, ctx: Dictionary) -> String` for all six `GodTree.RING` types (stubs return `""`), `static func state(bc, ctx: Dictionary) -> String` (Task 1: tier1_b's `state_<scenario>`).
- `behaviour_check.gd`: `--god=<type>:1` **with no `--route`** on a scenario in `GodT1.SCENARIOS`: `powers = GodTree.keys_for(type, 1)` (the real tree, D2), hit-stop off, prints `BEHAVIOUR god=<type>:1 route=god`, plays `_god_route(scenario, type, case)` through `_scripted()` with `ctx` as `_route_ctx()` builds it (label = scenario; `--board` as route b needs it for `warning`). `--god` with `--route=a|b`, or on another scenario: P1's check-and-refuse, unchanged. `--level` as P1.
- `gate.sh --god=<type>:<tier>`: passes `--god=` to every run; CASES `play` (`--with-none` adds `none`); verdict line `gate <s>[ city=<id>] route=god:<type> none_lost=... wins=K/3 median=S idle_max=S PASS|FAIL`; judged: wins ≥ 2, idle ≤ 45, median 150-270 unless `--board` (reported), a refusal FAILs.

- [ ] **Step 1: Failing tests** `tests/test_walls.gd`:

```gdscript
# _aldermere: Walls.outside(Vector2(0, 0)) false; (2.7, 15.9) false (in the Main Gate's passage); (2.7, 16.6) true (past 16 + 0.5);
#   (-16.4, 0) false; (-16.6, 0) true; Walls.way_off(Vector2(2.7, 17.0)) == Vector2(2.7, 29.6) (TownLayout.EXITS[0])
# _capital: City.use(&"capital"); (-24.6, -13.0) true (out by the west gate); (-23.0, -13.0) false; (4.0, 4.6) true (onto a bridge);
#   City.use(&"aldermere") before returning
# _fold_outside: a Person on a walk grid of Aldermere, fold(Vector2(2.7, 18.0)) -> true and Walls.outside(p.ground_pos) (the Mirrorfold
#   needs no change, spec §3)
# _send_off: a MissionDirector set up on a test crowd (as tests/test_starfall.gd builds one); send_off(p) -> p.mind == DUTY, p.anchor ==
#   Walls.way_off(...), is_leaving(p); set p.ground_pos within 1.0 of it, _step_leaving() -> p not in crowd.citizens; a second send_off of
#   the same person adds nothing
```

`tests/test_god_routes.gd`:

```gdscript
# _dispatch: GodT1.SCENARIOS == ["warning", "tax", "harvest", "lamb", "prayers"]; for each scenario and each GodTree.RING type,
#   has_policy() is true and act() on an empty ctx returns "" (stubs); state() returns a String; an unknown scenario -> has_policy false
# _god_draft: GodTree.keys_for("decree", 1) == ["noleave", "belllies"] (D2, the real tree; dev_fill off)
# _last_fx: a Rules built as tests/test_board_nights.gd builds one, cast smite -> last_fx() is the returned FxTimeline; before any cast null
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 8 `failures=0`).
- [ ] **Step 5: Plumbing smoke:** `$G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=tax --case=play --seed=1 --god=veil:1` prints `BEHAVIOUR god=veil:1 route=god` and a result line (the stub casts nothing; `won=false` is expected); `--scenario=tax --route=b --god=veil:1` still prints `BEHAVIOUR refused ... outside=ember,smite,wisp` and exits 1; `bash tools/dev/gate.sh tax --god=veil:1` prints a `route=god:veil ... FAIL` line (stubs).
- [ ] **Step 6: Unmoved:** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|gates|tax_play_1|harvest_play_1|lamb_play_1|prayers_play_1|warning_b_play_1|informer_play_1)$'` → all OK.
- [ ] **Step 7: Commit** `feat: Tier 1 routes groundwork -- Walls, the leaver, Rules.last_fx, behaviour_check --god per-type policies, gate.sh --god (god T1R)`.

**Numbers:** `Walls.MARGIN` 0.5. **References:** none may move. **Model:** sonnet; **review:** sonnet (every mission task builds on it).

---

### Task 2: The Warning (the board's Starfall)

**Goal:** spec §4: W1 out of the walls, W2 the keeper who heard ALL IS WELL, six per-type policies, both towns.

**Files:**
- Modify: `src/game/mission/warning_director.gd` (`walls_stop := false`, `lie_stops := false`, `stopped_how := ""`; the out check each step for the carrier in every phase, the Herald included; the lie branch in `_deliver()` and `_take_rope()`; the BELLKEEPER tag's lie countdown; `report()` keys), `src/game/mission/starfall_director.gd` (sets both flags on each warning before `setup()`, `_step_leaving()`, report counts `out` and `lies`), `src/game/descend/tier_book.gd` (`_warning()` goal and lose copy if the hint's words change them), `src/game/mission/mission_hints.gd` (`warning`, `warning.relay`), `tools/dev/routes/god_t1/warning.gd` (six policies, `FILLED`), `tests/test_starfall.gd`, `tests/test_warning.gd`, `tests/test_capital_starfall.gd`, `tests/test_mission_hints.gd`; references: `tools/dev/refs/routes_t1.tsv` (`warning_b_play_*`), `lantern_herald.tsv` (`starfall_toll_*`), `capital_starfall.tsv`; new `tools/dev/refs/god_t1_warning.tsv`.

**Interfaces:** `WarningDirector.walls_stop`, `lie_stops` (set before `setup()`); `stopped_how` ∈ `"" | "kill" | "out" | "lie"`; `StarfallDirector.report()` adds `"out"`, `"lies"`. Uses `Walls`, `send_off()`, `crowd.is_bell_lying()`.

- [ ] **Step 1: Failing tests** (`tests/test_starfall.gd` unless named):

```gdscript
# _out_stops: a board Warning on a test town; once star 1's watchman runs, set him down outside the walls (fold) -> next step
#   warning_dead, stopped_how == "out", the banner THE WARNING LEAVES TOWN, he is_leaving(); fall_at(1) == stop second + stop_wait
# _out_staring: the watchman whispered out during his stare -> stopped before he runs (the star still fell)
# _out_herald: Herald night, bell tolled, the Herald set down outside -> herald_open() false, warning_dead
# _out_relay: a seen kill whose nearest witness stands outside the walls -> stopped at once, relays == 1
# _lie_stops: crowd.bell_lies(45.0) then the messenger at the keeper -> stopped_how == "lie", bell still IDLE, ALL IS WELL banner,
#   the messenger off duty; _lie_rope: keeper dead, messenger at the foot while lying -> stopped, bell not rung
# _lie_over: crowd.bell_lies(1.0), 2 s later the delivery -> delivered as today (bell called)
# _lie_tag: while lying the BELLKEEPER tag reads "BELLKEEPER - ALL IS WELL 0:4x" (mission seconds)
# tests/test_warning.gd _flags_off: a lone WarningDirector (the campaign's) with walls_stop/lie_stops at their defaults: the same out
#   and lie set-ups change nothing (not stopped, delivered)
# tests/test_mission_hints.gd: the new lines are the spec's (§4.3) and fit
```

- [ ] **Step 2: RED**, **Step 3: implement W1, W2**, **Step 4: GREEN** (suite 3 in the group).
- [ ] **Step 5: Protected rows unmoved:** `bash tools/dev/refs_check.sh --jobs=2 --only='^(digest|crowd_check|warning_(none|doom|whisper|discord|mix)|warning_toll_[123]|ringers_(none|play|toll|b_play)_[123]|night_b_play_[123])$'` → all OK (the campaign Warning, the Omen, The Bell-Ringers).
- [ ] **Step 6: Existing gates keep their verdicts** (Aldermere, then `--city=capital`): `gate.sh warning --route=b --board --with-none` (none_lost 3/3, wins ≥ 2/3, idle ≤ 45) and `gate.sh warning --route=b --board --case=toll` (wins ≥ 2/3). B leads the runner to quiet spots "within 40 u of walking (outside the walls)" (v0.11.1 Task 8 ruling): with W1 such a lead is a stop, so B's rows move and it wins sooner; re-record.
- [ ] **Step 7: Six policies** in `god_t1/warning.gd` (spec §4.2), each iterating `StarfallDirector.stars` as tier1_b's `act_warning` does: ruin (Smite led, Ember to clear the street), death (Death Mark in the stare, Pestilence when all within 2.0 fall with him), veil (Doom; never Blight the tower), passage (way ins laid 19-30 s ahead and far along, way out beyond the wall; Thornwall to lengthen a run), decree (ALL IS WELL timed to each delivery; LIP holds a runner at his post), dominion (whisper out through his gate; Discord to hold). `FILLED` lists all six.
- [ ] **Step 8: Per-type gates** (Aldermere, binding): `gate.sh warning --board --god=<type>:1` for the six → wins ≥ 2/3, idle ≤ 45 each (median reported). Capital: the same with `--city=capital`, reported. Passage or Decree missing after three rounds: DONE_WITH_CONCERNS with the per-seed lines (spec Problems 4, 5).
- [ ] **Step 9: References:** re-record every moved row of `warning_b_play_*`, `starfall_toll_*`, `capital_starfall_*` with the reason; record `god_<type>_warning_play_<1-3>` (18, `--scenario=warning --case=play --board --god=<type>:1 --seed=N`) in `god_t1_warning.tsv`; rerun `refs_check.sh --only='^(warning_b|starfall|capital_starfall|god_[a-z]+_warning)_'` → all OK.
- [ ] **Step 10: Commit** `feat: The Warning's routes for every god type -- out of the walls, the keeper who heard ALL IS WELL (god T1R Task 2)`.

**Numbers:** none of the mission's; `Walls.MARGIN` only (spec §4.4). **Model:** sonnet; **review:** sonnet.

---

### Task 3: The Tax Collector

**Goal:** spec §5: T1 out of the walls, T2 the debtors' mob, six policies, both towns.

**Files:**
- Modify: `src/game/mission/assassinate_director.gd` (`walls_stop := false`; `State.OUT` appended; `stopped()`; `all_fallen()` and `killed()`'s callers read stopped; `_lost()` skips OUT; `_judge`/chain from the stop; `report()` key `out`; tags and `hint_phase()` pass over OUT), `src/game/mission/tax_collector_director.gd` (`walls_stop = true`; the mob: `MOB_DOOR_R`, `MOB_GUARD_R`, `MOB_AFTER`, the visited doors, `_on_cast` holding `noleave` effects via `Rules.last_fx()`, the mob's kill and its sight; the `GUARDED` tag), `src/game/mission/assassinate_objective.gd` (label only if needed), `src/game/mission/mission_book.gd` (`tax_collector()` copy), `mission_hints.gd` (`tax_collector`), `tools/dev/routes/god_t1/tax.gd`, tests `tests/test_tax_collector.gd`, `tests/test_capital_tax.gd`, `tests/test_informer.gd` / `tests/test_bishop.gd` (one `_walls_off` check each), `tests/test_mission_hints.gd`; references `references.tsv` (`tax_*`), `routes_t1.tsv` (`tax_b_play_*`), `lantern_watch.tsv` (`tax_toll_*`), `capital_tax.tsv`; new `god_t1_tax.tsv`.

**Interfaces:** `AssassinateDirector.walls_stop`, `State.OUT`, `stopped() -> int`, `out_count() -> int`; `TaxCollectorDirector.MOB_DOOR_R := 3.0`, `MOB_GUARD_R := 1.5`, `MOB_AFTER := 3.0` (*tunable*), `mob_ready(q) -> bool` (read-only: bound, at a visited door, no guard near). Kill kind `&"mob"`; `Rules.POWER_KINDS`-style credit to `noleave` only if the credit table needs it (else `killed_by = "noleave"` set by the director).

- [ ] **Step 1: Failing tests** (`tests/test_tax_collector.gd`):

```gdscript
# _out_stops: the collector walking his round set down outside the walls -> state OUT, counts in stopped(), a banner, is_leaving();
#   the deputy's out_at(1) == stop second + chain_wait; all three OUT or dead -> AssassinateObjective done (reason collector)
# _out_not_safe: an OUT collector removed at the map's edge is not SAFE (_lost does not fire): any_safe() false
# _mob: a NoLeaveFx sealed over a visited debtor's door binding the collector, his guards compelled away -> MOB_AFTER later he is dead,
#   judged unseen (bell IDLE), killed_by == "noleave", the banner
# _mob_guarded: the same with a guard of his within MOB_GUARD_R -> alive; his tag reads "TAX COLLECTOR - GUARDED"
# _mob_far: bound 5 from any door he visited -> alive
# tests/test_informer.gd, test_bishop.gd _walls_off: a target set down outside the walls with walls_stop at its default -> not OUT
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN**.
- [ ] **Step 5: Protected rows unmoved:** `refs_check.sh --jobs=2 --only='^(digest|crowd_check|informer_(none|play|toll|b_play)_[123]|bishop_(none|play|b_play)_[123])$'` → all OK.
- [ ] **Step 6: Existing gates keep their verdicts** (Aldermere, Capital): `gate.sh tax` (route a with none), `gate.sh tax --route=b` (B is 2/3 in both towns today: it must stay ≥ 2/3), `gate.sh tax --case=toll`.
- [ ] **Step 7: Six policies** in `god_t1/tax.gd` (spec §5.3): ruin (B's Smite and the Ember flush, without the Wisp), death (Death Mark ≥ 10 s before his next door; Pestilence on him and his guards), veil (A's Doom), passage (mirror out between stops; Thornwall to keep him on the mirror's line), decree (CALL THE GUARD ≥ 8 from his door as the visit ends, LIP over the door as he comes out), dominion (whisper beyond the wall; Discord to hold).
- [ ] **Step 8: Per-type gates** (Aldermere binding, Capital reported): `gate.sh tax --god=<type>:1` → wins ≥ 2/3, idle ≤ 45, median 150-270.
- [ ] **Step 9: References:** re-record moved `tax_*`, `tax_b_play_*`, `tax_toll_*`, `capital_tax_*`; record 18 `god_<type>_tax_play_<n>` rows; rerun the slice → OK.
- [ ] **Step 10: Commit** `feat: The Tax Collector's routes for every god type -- out of the walls, the debtors' mob (god T1R Task 3)`.

**Numbers:** `MOB_DOOR_R` 3.0, `MOB_GUARD_R` 1.5, `MOB_AFTER` 3.0, tuned in spec §5.5's order. **Model:** sonnet; **review:** sonnet.

---

### Task 4: Spoiled Harvest

**Goal:** spec §6: H0 carters early, H1 out of the walls, H2 plague, H3 Blight, H4 the seized cart, H5 the replaced carter; six policies; both towns.

**Files:**
- Modify: `src/game/mission/harvest_director.gd` only among the directors (`CARTER_LEAD`, `SEIZE_R`, `RELIEF_AFTER` reused; the early set-out in `step()`/`_deliver()`; the out check, the sick check, the Blight hooks `blight_target/blight_takes/blighted/blight_words`, the seize watch on `rules.cast_made` + `Rules.last_fx()`, the replacement, the carter tags, `_step_leaving()`; `TOWN_VARS` gains `carter_lead` only if the Capital needs another value), `mission_book.gd` (`spoiled_harvest()` copy if changed), `mission_hints.gd` (`spoiled_harvest`), `tools/dev/routes/god_t1/harvest.gd`, tests `tests/test_spoiled_harvest.gd`, `tests/test_capital_harvest.gd`, `tests/test_mission_hints.gd`; references `references.tsv` (`harvest_*`), `routes_t1.tsv` (`harvest_b_play_*`), `capital_harvest.tsv`; new `god_t1_harvest.tsv`.

**Interfaces:** `HarvestDirector.CARTER_LEAD := 30.0`, `SEIZE_R := 2.5` (*tunable*); `carter_out_at(i) -> float` (when granary i's carter sets out: `grain_due(i) - CARTER_LEAD`, clamped to now); `spoiled_by: Dictionary` (Structure -> `"fire" | "fall" | "out" | "plague" | "blight" | "seized"`, for the report and the tests). `RazeDirector` is not edited: spoils go through its `_raze()` (a subclass call).

- [ ] **Step 1: Failing tests** (`tests/test_spoiled_harvest.gd`):

```gdscript
# _carter_early: at grain_due(0) - 30 the first carter sets out from the Citadel's gate and waits at the door; he takes no load before
#   the grain; tags: "CARTER - GRAIN IN 0:xx" edge-arrowed
# _out: the carter set down outside the walls (before his grain) -> granary 0 razed, spoiled_by "out", the chain from now, is_leaving
# _plague: no watchman on guard, the carter infected -> razed "plague"; _plague_guarded: a watchman on guard -> not razed, the banner
#   THE WATCH TURNS THE SICK CART AWAY
# _blight: grain in, watchmen away -> blight_target(near the granary) != INF, blighted() razes it "blight", words "BLIGHT - THE GRAIN ROTS";
#   _blight_guarded: a watchman on guard -> blight_takes false, words "THEIR WATCH KEEPS IT", not razed, no alarm;
#   _blight_empty: before its grain -> words "NO GRAIN TO ROT YET"
# _seized: a BellLiesFx in mode "guard" cast at the carter (a test caster), the first called soldier arrives -> razed "seized";
#   2.6 from the place -> not seized
# _replaced: the carter killed -> RELIEF_AFTER later a new carter sets out from the Citadel's gate; the granary's loads unchanged
# _none_loses (gate, not unit): see Step 6
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN**.
- [ ] **Step 5: Protected rows unmoved:** `refs_check.sh --jobs=2 --only='^(digest|crowd_check|bread_(none|play|b_play)_[123]|armoury_(none|play|b_play)_[123]|heart_(none|play|b_play)_[123]|hunt_(none|play|b_play)_[123]|eye_(none|play|b_play)_[123])$'` → all OK (the other Raze and Blight-hook missions).
- [ ] **Step 6: Existing gates keep their verdicts** (Aldermere, Capital): `gate.sh harvest` (route a: none_lost 3/3; its median sits at 182 against 180 — the early carter must not speed A: if it does, `CARTER_LEAD` is the knob, never the grain), `gate.sh harvest --route=b`.
- [ ] **Step 7: Six policies** in `god_t1/harvest.gd` (spec §6.7).
- [ ] **Step 8: Per-type gates** (Aldermere binding, Capital reported): `gate.sh harvest --god=<type>:1`. Decree's idle is expected ~55-60 s (spec Problem 6): report it against the controller's ruling R-c.
- [ ] **Step 9: References:** re-record moved `harvest_*`, `harvest_b_play_*`, `capital_harvest_*`; record 18 `god_<type>_harvest_play_<n>`; rerun → OK.
- [ ] **Step 10: Commit** `feat: Spoiled Harvest's routes for every god type -- early carters, out of the walls, plague, Blight, the seized cart (god T1R Task 4)`.

**Numbers:** `CARTER_LEAD` 30, `SEIZE_R` 2.5, `RELIEF_AFTER` 30 (the watchmen's); spec §6.9's order. **Model:** sonnet; **review:** sonnet.

---

### Task 5: The Lost Lamb

**Goal:** spec §7: L1 he bolts, L2 out of the walls is out, six policies, both towns.

**Files:**
- Modify: `src/game/mission/lost_lamb_director.gd` only (`BOLT_AT`, `BOLT_REACH`, `BOLT_PACE`; `led`, `bolting`, `bolt_at`; the startle listeners — `crowd.danger_landed`, `crowd._field.enemy_killed`, a per-look check for a structure newly burning within reach and the hiding fountain's `blighted`; `_step_free()` and `_exit_reached()` overrides; the timeline event; tags; teardown disconnects; `TOWN_VARS` gains `bolt_at` only if the Capital needs it), `mission_book.gd` (`lost_lamb()` copy), `mission_hints.gd` (`lost_lamb`, `lost_lamb.running`), `tools/dev/routes/god_t1/lamb.gd`, tests `tests/test_lost_lamb.gd`, `tests/test_capital_lamb.gd`, `tests/test_mission_hints.gd`; references `references.tsv` (`lamb_*`), `routes_t1.tsv` (`lamb_b_play_*`), `capital_lamb.tsv`; new `god_t1_lamb.tsv`. If the controller rules Problem 10 (a): `POSTS` / the Capital's `watch_posts` and `tests/test_capital_lamb.gd`.

**Interfaces:** `LostLambDirector.BOLT_AT := 60.0`, `BOLT_REACH := 6.0`, `BOLT_PACE := CHARGE_PACE` (*tunable*); `led: bool`, `bolting: bool`; `bolt_left() -> float` (mission seconds to `BOLT_AT`, 0 once bolting or led). `EscortDirector` is not edited.

- [ ] **Step 1: Failing tests** (`tests/test_lost_lamb.gd`):

```gdscript
# _bolts_at_one: nothing done -> at BOLT_AT he is bolting, on duty for exit_at, the banner, the tag "ACOLYTE - RUNNING"
# _bolts_on_smite: a Smite's danger landing 4 from him at 0:20 -> bolting; at 7 -> not
# _bolts_on_fire / _bolts_on_death / _bolts_on_blight: a house within 6 set alight; a citizen within 6 killed; his fountain blighted -> bolting
# _led_never_bolts: whispered at 0:05 -> at BOLT_AT not bolting (led); a startle later -> still not
# _bolt_fear: bolting, a fright on him -> he keeps his run (not inside, still on duty for the exit)
# _bolt_seized_freed: bolting, seized, the seizer killed -> bolting again at once
# _out_anywhere: set down outside the walls 3 from exit_at -> escaped (L2)
# _tag_countdown: at 0:18 his tag reads "ACOLYTE - BOLTS IN 0:42"
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN**.
- [ ] **Step 5: Protected rows unmoved:** `refs_check.sh --jobs=2 --only='^(digest|crowd_check|prisoner_(none|play|b_play)_[123]|exodus_(none|play|b_play)_[123])$'` → all OK.
- [ ] **Step 6: Existing gates keep their verdicts** (both towns): `gate.sh lamb` (none_lost 3/3: the 1:00 bolt into the watch), `gate.sh lamb --route=b`.
- [ ] **Step 7: Six policies** in `god_t1/lamb.gd` (spec §7.3); Death keeps every Pestilence ≥ 8 from him.
- [ ] **Step 8: Per-type gates** (Aldermere binding, Capital reported): `gate.sh lamb --god=<type>:1`. Passage's median below 150 (Problem 10) is reported against ruling R-c.
- [ ] **Step 9: References:** re-record moved `lamb_*`, `lamb_b_play_*`, `capital_lamb_*`; record 18 `god_<type>_lamb_play_<n>`; rerun → OK.
- [ ] **Step 10: Commit** `feat: The Lost Lamb's routes for every god type -- he bolts for the gate (god T1R Task 5)`.

**Numbers:** `BOLT_AT` 60, `BOLT_REACH` 6, `BOLT_PACE` 0.385; spec §7.5's order. **Model:** sonnet; **review:** sonnet.

---

### Task 6: First Prayers

**Goal:** spec §8: F1 they come to pray, F2 fire pulls the Faithful, F3 Thornwall blocks sight, F5 ALL IS WELL; six policies; both towns.

**Files:**
- Modify: `src/game/mission/first_prayers_director.gd` (`POOR_OUT_AT`, `POOR_CHAIN`, `FIRE_PULL`; the walkers (`walker`, `_walks_left`), their timeline events and `expect()`; `_brought()` override for a walker at the door; `_sees()` override (thorns); the fire pull in `step()`; the lie in `step()` and `_line_door()`; tags; `TOWN_VARS` gains `poor_out_at` only if the Capital needs it), `src/game/mission/temple_report.gd` (`drop()`: closes the report undelivered and lets its carrier go — nothing else calls it), `mission_book.gd` (`first_prayers()` copy), `mission_hints.gd` (`first_prayers`), `tools/dev/routes/god_t1/prayers.gd`, tests `tests/test_first_prayers.gd`, `tests/test_capital_prayers.gd`, `tests/test_mission_hints.gd`; references `references.tsv` (`prayers_*`), `routes_t1.tsv` (`prayers_b_play_*`), `lantern_night2.tsv` (`prayers_toll_*`), `capital_prayers.tsv`; new `god_t1_prayers.tsv`.

**Interfaces:** `FirstPrayersDirector.POOR_OUT_AT := [60.0, 135.0, 200.0]`, `POOR_CHAIN := 35.0`, `FIRE_PULL := 6.0` (*tunable*); `walker: Person` (null between walks); `walk_due() -> float`. `MirasHouseDirector` is not edited (Mira's House and The Sermon keep its base).

- [ ] **Step 1: Failing tests** (`tests/test_first_prayers.gd`):

```gdscript
# _walker_sets_out: at POOR_OUT_AT[0] the nearest unbelieving poor sets out on duty for the door, tagged "POOR - TO THE SHRINE";
#   the next sets out POOR_CHAIN after he went in (or at POOR_OUT_AT[1], the sooner)
# _walker_seen: the door watched (a liner at it) when he arrives -> turned away, a report started; _walker_prays: door clear -> inside
# _walker_waits: one praying -> the walker waits at the door, goes in when the shrine is free (unless watched then)
# _walker_whispered: a walker whispered elsewhere drops the walk and takes it up again when the whisper ends
# _fire_pulls: a house within FIRE_PULL of the door set burning during the market window -> liners on duty by the fire; out -> back
# _thorns_block: a thorn segment on the line from a liner to the door -> faithful_seeing(door, SIGHT) null; moved off the line -> him
# _lie: crowd.bell_lies(45) during the market window -> liners stood down, a report running dropped (TempleReport closed, nothing
#   delivered, the Gaze unchanged); a window due during the lie forms when it ends, for its seconds left
# _drop: TempleReport.drop() on an open report -> not is_open(), its step() delivers nothing
```

- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN**.
- [ ] **Step 5: Protected rows unmoved:** `refs_check.sh --jobs=2 --only='^(digest|crowd_check|miras_(none|play|toll|b_play)_[123]|sermon_(none|play|toll|b_play)_[123]|lanterns_(none|play|toll|b_play)_[123]|relic_(none|play|toll|b_play)_[123])$'` → all OK (Mira's base; the other `TempleReport` users).
- [ ] **Step 6: Existing gates keep their verdicts** (both towns): `gate.sh prayers` (none_lost 3/3; route A's median must stay ≥ 180: the walkers help A — the knob is `POOR_OUT_AT[1..2]`), `gate.sh prayers --route=b` (Capital B's idle was 48, REPORTED in v0.12: report it again, not a new failure), `gate.sh prayers --case=toll`.
- [ ] **Step 7: Six policies** in `god_t1/prayers.gd` (spec §8.6).
- [ ] **Step 8: Per-type gates** (Aldermere binding, Capital reported): `gate.sh prayers --god=<type>:1`.
- [ ] **Step 9: References:** re-record moved `prayers_*`, `prayers_b_play_*`, `prayers_toll_*`, `capital_prayers_*`; record 18 `god_<type>_prayers_play_<n>`; rerun → OK.
- [ ] **Step 10: Commit** `feat: First Prayers' routes for every god type -- the poor come to pray (god T1R Task 6)`.

**Numbers:** `POOR_OUT_AT` [60, 135, 200], `POOR_CHAIN` 35, `FIRE_PULL` 6; spec §8.8's order. **Model:** sonnet; **review:** sonnet.

---

### Task 7: The 30-pair gate and the real tree's Tier 1

**Goal:** D5 on the merged tree: all 30 pairs pass in Aldermere; the tree's Tier 1 is D2's.

**Files:** Create `tools/dev/god_gate.sh`; modify `tests/test_god_tree.gd`, `tests/test_god_routes.gd`.

**Interfaces:** `bash tools/dev/god_gate.sh [--tier=1] [--city=<id>] [--only=<scenario>] [--jobs=N]`: for each scenario (or the one `--only` names) in `GodT1.SCENARIOS` and each type in `GodTree.RING` runs `gate.sh <s> --god=<type>:1` (`--board` for warning), then `--with-none` once per mission; prints a 6 × 5 table of `wins/median/idle` and a last line `god_gate tier=1[ city=<id>] pass=K/30 none_lost=5/5 PASS|FAIL` (exit 1 on FAIL).

- [ ] **Step 1: Failing tests:** `tests/test_god_tree.gd` `_tier1_real`: `GodTree.real()` Tier 1 is exactly ruin smite+ember, death deathmark+pestilence, veil doom+blight, passage thorns+mirror, decree noleave+belllies, dominion whisper+discord (D2), in spot order; `tests/test_god_routes.gd` `_all_filled`: every `god_t1/<scenario>.gd`'s `FILLED` holds all six types (RED only if a mission task left one out).
- [ ] **Step 2: GREEN**, suite 8.
- [ ] **Step 3:** `bash tools/dev/god_gate.sh --only=<scenario>` for each of the five on a quiet machine (18 + 3 runs each, so each foreground call stays under 10 minutes) → each `pass=6/6 none_lost=1/1 PASS`, together 30/30. Then `--city=capital`, reported.
- [ ] **Step 4: Commit** `dev: the Tier 1 per-type gate, 30 pairs (god T1R Task 7)`.

**Model:** sonnet; **review:** none.

---

### Task 8: The title switch (D7)

**Goal:** spec §11: the title's first row is Endless Night with the real tree; the campaign leaves the title, its code stays.

**Files:** Modify `src/game/ui/title_screen.gd` (`ROWS`, `LABELS`, header comment), `src/game/game.gd` (the title's `"endless"` action: `GodTree.dev_fill = false`, `_endless_from = Screen.TITLE`, go to SLOTS; `slots:back` to TITLE or BOARD by `_endless_from`; the board's ENDLESS sets `_endless_from = Screen.BOARD`; the `"campaign"` handler kept; FLOW's `_flow_title_endless()` and its call), `tests/test_options.gd` (`_title`), `tests/test_endless_screens.gd` (`_title_entry`).

**Interfaces:** `TitleScreen.ROWS := ["endless", "play", "options", "sandbox", "quit"]`, `LABELS := ["Endless Night", "Missions", "Options", "VFX Sandbox", "Quit"]`; `Game._endless_from: Screen`.

- [ ] **Step 1: Failing tests:** `_title` rows as above; `_title_entry`: a Game on the title, action `"endless"` → screen SLOTS, `GodTree.dev_fill` false; Back → TITLE; the board's ENDLESS → SLOTS with dev fill on, Back → BOARD.
- [ ] **Step 2: GREEN** (suite 8).
- [ ] **Step 3: FLOW** (alone): `_flow_title_endless`: title Endless Night → slots (three Empty) → New → god select → Ruin → hub Night 1 → Descend → Prepare offers exactly smite and ember → back to the hub → Title. The campaign walk still runs (it emits `"campaign"` directly). `failures=0`.
- [ ] **Step 4: Commit** `feat: the title's first button is Endless Night (god T1R Task 8, D7)`.

**Model:** sonnet; **review:** sonnet (FLOW and `game.gd`).

---

### Task 9: Landing checks

**Goal:** D1: everything checked on the merged tree against `feat/god-progression`; nothing reaches `feat/Develop-Main`; nothing is pushed.

- [ ] Memory `check-before-every-merge` against `feat/god-progression` (local and `origin/` if it exists): fetch; a throwaway commit if anything is uncommitted (memory `trial-merge-needs-commit`); trial merge; P2 (D8) landed first → merge it, check API clashes (the Lost Lamb as the Hunt stand-in, `game.gd`, `GodNight`), rerun Tasks 2-8's gates on the merged tree.
- [ ] `bash tools/dev/land.sh --bench=kak-god-p1` (alone; its Develop-Main trial merge is reported only): import exit 0; suite `failures=0`; references all rows OK (286 + 90 new = 376; the moved ones as re-recorded); FLOW `failures=0`; the five board benches within ~1 fps of `kak-god-p1` (rerun a noisy pair quiet; memory `kak-m1-perf-debt`).
- [ ] `bash tools/dev/god_gate.sh` on the merged tree → `pass=30/30`.
- [ ] Report: the landing table, the 30-pair table, every `Ruling:` from Tasks 1-8, one Dev Ledger line per task. Commit only if something changed (`fix: Tier 1 routes landing -- <what>`). The controller then runs the opus milestone review, one fix wave and the sonnet re-review, ff's `feat/god-progression` and tags `kak-god-t1r` locally (D1).

**Model:** sonnet; **review:** none here.

---

### Task 10: Notes

**Files:** Create `docs/KAK_God_T1_Routes_Summary.md` (what you asked; the three shared rules and each mission's new rules in plain words; the routes table as built, per type, with each pair's wins/median/idle; the numbers with *tunable* marks; the title switch; Problems and how each was ruled; what to play by hand first); `docs/KAK_God_T1R_Rulings.md` (D1-D9, the answers to spec §13, every task's `Ruling:`).

- [ ] Commit `docs: Tier 1 routes summary and rulings`.
- [ ] Report the Dev Ledger lines for the controller (memory `kak-dev-ledger`; the controller writes them and refreshes the Discord board): a release row `kak-god-t1r` (branch `feat/god-progression`, the landing numbers); one `done` task per Task 1-8; `todo`s left open (any pair reported, the Capital per-type rows if not binding, the level tables batch 1, P2's re-gate if it lands second); ideas (per-type hints, a Lamb outer post if not ruled in).

**Model:** sonnet; **review:** none.
