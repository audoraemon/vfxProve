# KAK God Progression P2 "Lantern" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Run it the KAK way: `.claude/skills/kak-milestone/SKILL.md` (sonnet implementers, a sonnet task review only for the logic tasks, dispatches from `.superpowers/sdd/godp2/implementer.md`, briefs `.superpowers/sdd/godp2/task-N-brief.md`).

**Goal:** spec §14 row P2: the Lantern Notice moves (§10.1), a Notice of 100% makes the next night a Lantern Hunt played by a stand-in at the god tier's settings (§10.2), and the Hunt's result resets the Notice and pays Faith, or seals the god's most-carried ability for 3 nights (§10.3); the hub, Prepare, the pause menu and the results show all of it (§9.1, §9.2, §12). "No escape by quitting" (§9.1) now costs Notice, and a lost Hunt seals.

**Architecture:** all rules sit in the two P1 statics/data classes. `GodSlot` (one god, one file) gets the Notice and seal rules: `hunt_due()` (derived: `notice >= 100`, no new save field), `add_notice()`, `in_tree()`, `seal_target()`, `seal()`, `tick_seal()`. `GodNight` gets the Notice amounts, the five Hunts (`HUNTS`, by god tier), `hunt_for()`, `hunt_stake()`, `notice_delta()`, and extends `draw()` (the Hunt cannot be skipped), `bank()` and `forfeit()` (Notice, Hunt result, seal tick) and `def_for()` (the stand-in at the god tier, with the Hunt's name and banner). `TierBook.board()` gains an optional tier so the Informer can be played at Tier 3; with no tier it builds exactly what it builds today. The screens read the slot and the bank's dictionary; Game changes little (the pause menu's stake, a hub line when the god's file cannot be written, photographs, FLOW). The save's format is unchanged (P1 already writes `notice`, `sealed`, `seal_nights`).

**Tech Stack:** Godot 4.7.2 GDScript; headless suite `tests/run_all.gd` / `tools/dev/run_suite_parallel.sh`; references `tools/dev/refs_check.sh`; FLOW (`Game._flow_test()`, `--flow-test`); photographs `tools/capture.sh --show=`; landing by hand in `tools/dev/land.sh`'s order.

**Spec:** `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited §N). Controller rulings: `.superpowers/sdd/godp2/rulings.md` (C1-C7; binding over this text where they differ). P1 as built: `docs/KAK_God_P1_Summary.md`, `docs/KAK_God_P1_Rulings.md` (P1's P1-P24 hold unless a P2 ruling below changes them). This plan's own rulings: section "Rulings" at the end (P2-1 to P2-16).

## Global Constraints

The full text is `.superpowers/sdd/godp2/global-constraints.md`; in short:

- Worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/god-p2-lantern-04cddc`, branch `claude/god-p2-lantern-04cddc` (from `feat/god-progression` `a45a7c17`, tag `kak-god-p1`); every command from its root; foreground only, each under 10 minutes; `G = /c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; import after a new `class_name` or test file.
- Per task: focused tests (RED first), `bash tools/dev/run_suite_parallel.sh 8` (`3` in a parallel group) -> `failures=0`, the brief's `refs_check.sh --only=...` (`--jobs=2` in a parallel group); FLOW only in Tasks 4 and 5, alone.
- **No reference moves (C3):** `digest` `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`, every row of `tools/dev/refs/*.tsv`. P2 changes no mission rule; nothing is re-recorded.
- **Never edit `GodTree.TABLE` (C2)** (nor `GodTreeDev.TABLE`). Tests use the dev fill and take keys from the merged table at test time, never assuming the real table is empty or which keys a type holds.
- No PixelLab (C4); 640x360; `UiTheme`. Endless Night writes only the god's file. The title is unchanged.
- Copy quoted here is exact and *(my call)* unless the spec gives it.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; every `Ruling:` goes in the task's report.

## Review Focus

The milestone review checks, with the tests that prove each:

1. **The Notice never changes unseen and never leaves 0-100 (§10.1):** each bank and forfeit moves it by the ruled amount (P2-1, P2-2), the change is on the results screen or the hub line, and a damaged file reads in range. Tests: Task 1 `_notice_deltas`, `_notice_clamp`, `_forfeit_notice`, `_bad_seal_file`; Task 3 `_god_lines_notice`; FLOW (Task 5).
2. **The Hunt cannot be skipped or dodged (§10.2, §9.1):** at 100% the draw is the stand-in whatever the seed and the last mission, the dev Awaken is refused, and abandoning, closing the game mid-Hunt or losing it all count as a lost Hunt. Tests: Task 1 `_hunt_draw`, `_hunt_forfeit`; Task 3 `_hub_awaken_refused`; Task 4 `_load_god_hunt`; FLOW.
3. **The seal is exact and never traps the god (§10.3, P1's P8):** the target is the most-carried ability by the ruled order (P2-7), shown before the Hunt (Prepare, pause) and the same after; exactly the next 3 counted nights; dropped from the remembered loadout; a god is never left with nothing to draft. Tests: Task 1 `_seal_target`, `_seal_ticks`, `_seal_never_traps`, `_seal_replaced`; Task 3 `_prepare_sealed`, `_pause_hunt`.
4. **The stand-ins move no reference (C3):** `TierBook.board(id, state)` is unchanged for every board mission; only a Hunt passes a tier. Tests: Task 2 `_board_at_default`, `_board_at_informer`; references in Task 2 and at landing.
5. **Endless Night still never touches the board's save (P1's C7)**, and a failed write of the god's file is shown on the hub (P1 review M3). Tests: Task 4 `_write_fails`; FLOW's save-bytes check after the Lantern walk.

---

## Task order and parallelism

| # | Task | Model | Review | Parallel group |
|---|---|---|---|---|
| 1 | The Lantern rules: Notice, Hunt due, the Hunt's result, seals (`GodSlot`, `GodNight`) | sonnet | **sonnet** | serial |
| 2 | The Hunt's night: `TierBook.board()` at a tier, `GodNight.def_for()` for a Hunt | sonnet | **sonnet** | **B** (B1) |
| 3 | Screens: hub meter, Hunt and seal lines; results lines; Prepare's Hunt and sealed cards; the pause stake | sonnet | none | **B** (B2) |
| 4 | Game wiring: the pause stake, the write-failure line, `load_god` with a Hunt, photographs | sonnet | **sonnet** | serial |
| 5 | FLOW: the Lantern walk (Notice to 100%, a Hunt lost, the seal on the hub and Prepare) | sonnet | none | serial |
| 6 | Landing on `feat/god-progression` (controller-run steps; trial merge, gates, bench vs `kak-god-p1`) | controller / sonnet | none (opus milestone review) | serial |
| 7 | Notes: `docs/KAK_God_P2_Summary.md`, `docs/KAK_God_P2_Rulings.md` | sonnet | none | serial |

Order: 1 → B (2 and 3; no file is shared) → 4 → 5 → 6 → the controller's opus milestone review, one fix wave, sonnet re-review → 7 → tag `kak-god-p2` (local; nothing pushed without the user's yes, C1). Group B may run in parallel only in separate worktrees (as P1's C11: branch `god/p2-t<N>` from Task 1's commit, merged in task order, then suite 8 on the merged tree); otherwise run 2 then 3 here. FLOW: Task 4 runs it alone (Task 1 changed two FLOW strings, Task 4 changes Game); Task 5 runs it alone.

**Shared files and their owners** (one hunk each; keep all on merge):

| File | Task 1 | Group B | Task 4 | Task 5 |
|---|---|---|---|---|
| `src/game/god/god_slot.gd` | all P2 changes | -- | -- | -- |
| `src/game/god/god_night.gd` | consts, `HUNTS`, `hunt_for()`, `hunt_stake()`, `notice_delta()`, `draw()`, `bank()`, `forfeit()` | 2: `def_for()`'s Hunt branch, `_dress_hunt()` | -- | -- |
| `src/game/descend/tier_book.gd` | -- | 2: `board()`'s `at_tier` | -- | -- |
| `src/game/ui/god_hub.gd`, `results_screen.gd`, `prepare_screen.gd`, `pause_menu.gd` | -- | 3 only | -- | -- |
| `src/game/game.gd` | the two FLOW strings of the forfeit line in `_flow_endless()` | -- | `write_god()`, `_write_god()`, `_open_pause()`'s stake, `--show` entries and `_show_lantern()`, the `SAMPLE_HUNT_*` results | `_flow_lantern()` and its call after `_flow_endless(step)` |
| `tests/run_all.gd` | one SUITES line (`test_god_lantern.gd`) | -- | -- | -- |
| `tests/test_god_lantern.gd` | creates | 2: appends its sub-tests | -- | -- |
| `tests/test_god_night.gd`, `tests/test_god_slot.gd` | the P1 checks the Notice now changes | -- | -- | -- |
| `tests/test_endless_flow.gd` | the forfeit line's string | -- | `_load_god_hunt`, `_write_fails` | -- |
| `tests/test_faith_hub.gd`, `tests/test_endless_screens.gd` | -- | 3 only | -- | -- |
| `docs/KAK_God_P2_*.md` | -- | -- | -- | -- (Task 7) |

---

### Task 1: The Lantern rules (`GodSlot`, `GodNight`)

**Goal:** spec §10.1 (the Notice amounts), §10.2 (100% makes the next night a Hunt; it cannot be skipped), §10.3 (the Hunt's result, the seal), §9.1 (a forfeit is a lost night: Notice +25%, a lost Hunt seals). Pure rules and data; no screen.

**Files:**
- Modify: `src/game/god/god_slot.gd`, `src/game/god/god_night.gd`, `tests/test_god_night.gd` (`_dp`'s Notice check, `_forfeit`'s line), `tests/test_god_slot.gd` (`_bad_file` additions only if they fit there; else in the new file), `tests/test_endless_flow.gd` (the one line string in `_load_god_forfeits`), `src/game/game.gd` (only the two `hub.line ==` strings in `_flow_endless()`: Night 2's and Night 3's), `tests/run_all.gd` (one SUITES line).
- Create: `tests/test_god_lantern.gd`.

**Interfaces (produces):**
- `GodSlot.SEAL_NIGHTS := 3` (spec §10.3).
- `static GodSlot.nights_text(n: int) -> String`: `"1 night"`, else `"%d nights"`.
- `GodSlot.hunt_due() -> bool`: `notice >= NOTICE_MAX` (P2-3).
- `GodSlot.add_notice(delta: int) -> int`: clamps into 0..`NOTICE_MAX`, returns the change made (P2-1).
- `GodSlot.in_tree() -> PackedStringArray`: learned keys that sit in a spot, sealed included, in `GodTree.spots()` order. `draftable()` becomes `in_tree()` minus `sealed` (same result as today).
- `GodSlot.seal_target() -> String`: the most-carried ability (P2-7): over `in_tree()`, the highest `carried[key]` (absent = 0); ties to the higher `might_of(key)` (at its learned level); then the earlier in `in_tree()` order. `""` when `in_tree()` holds fewer than 2 keys.
- `GodSlot.seal(key: String) -> void`: `sealed = key`, `seal_nights = SEAL_NIGHTS`, the key removed from `loadout`; `""` does nothing.
- `GodSlot.tick_seal() -> String`: when a seal is on, one night off; at 0 the seal ends (`sealed = ""`) and the key is returned; else `""`.
- `GodSlot.read()`: `seal_nights` clamped 0..`SEAL_NIGHTS`; a seal with no key or no nights reads as no seal (both cleared). `VERSION` stays 1 (P2-12).
- `GodNight` consts: `NOTICE_LOST := 25`, `NOTICE_CAUGHT := 10`, `NOTICE_CLEAN := -5`, `NOTICE_LOST_RITE := 25` (P3's hook; unused in P2), `HUNT_WON_NOTICE := 0`, `HUNT_LOST_NOTICE := 50`, `HUNT_FAITH := 50` (times the god tier; *tunable*).
- `GodNight.HUNTS`: five Dictionaries, index = god tier - 1, each `{"id", "title", "plate"}` (P2-5, spec §10.2):
  1. `MissionBook.LOST_LAMB`, "Hide the faithful", "Lead your believers out before the inquisitors reach them"
  2. `MissionBook.BELL_RINGERS`, "Silence the witness", "Stop the runner carrying word of you to the Lantern"
  3. `MissionBook.INFORMER`, "Expel the inquisitor", "Drive out or kill the Lantern's captain in the town"
  4. `MissionBook.ARMOURY`, "Break the hunt", "Smash their standards before they reach your believers"
  5. `MissionBook.HEART_OF_FAITH`, "Face Halcyon", "His Gaze is on the whole town, and a seen death fills it"
- `static GodNight.hunt_for(slot) -> Dictionary`: `{}` unless `slot.hunt_due()`; else a copy of `HUNTS[tier - 1]` plus `"tier": slot.tier`.
- `static GodNight.hunt_stake(slot) -> String`: what losing the Hunt would cost, shown before it: `"The Lantern will seal %s for %s"` (the power's name, `nights_text(SEAL_NIGHTS)`), or `"The Lantern has nothing to seal"`.
- `static GodNight.notice_delta(d: Dictionary) -> int` (from a report's `descend`; P2-1, P2-2): `main` false -> `NOTICE_LOST`; `main` and `ascended` -> `NOTICE_CLEAN`; `main` and not `ascended` -> `NOTICE_CAUGHT`.
- `GodNight.draw(slot)`: when `hunt_for(slot)` is not empty, its `id` (no seed, no no-repeat: P2-4); else as P1.
- `GodNight.bank(...)`, in this order (P2-6 to P2-10): (1) `hunt := hunt_for(slot)` and, for a Hunt, `target := slot.seal_target()`, both before anything changes; (2) `unsealed := slot.tick_seal()`; (3) P1's night, `last_mission`, `in_night`, Faith, Divine Power; (4) bests only when not a Hunt; (5) `carried` and `loadout` as P1; (6) a Hunt won (`main`): Notice set to `HUNT_WON_NOTICE`, Faith `+ HUNT_FAITH x slot.tier`; a Hunt lost: `slot.seal(target)`, Notice set to `HUNT_LOST_NOTICE`, `unsealed = ""` (a new seal replaces); not a Hunt: `slot.add_notice(notice_delta(d))`. The dictionary keeps P1's keys (`faith` is still the believers' Faith; `faith_total` includes the bonus; `notice_change` is the real change, after the clamp) and adds `"hunt"` (`{}`, or `{"tier", "id", "title", "won": bool, "faith": int, "sealed": String, "seal_nights": int}`), `"unsealed"` (a key or `""`) and `"hunt_next"` (`not a Hunt and slot.hunt_due()`).
- `GodNight.forfeit(slot)`: the same Hunt check and target first, then `tick_seal()`, P1's counting; a Hunt -> lost Hunt (seal, Notice 50); else `add_notice(NOTICE_LOST)`. Returns P1's `{"night", "line"}` plus `"notice"`, `"notice_change"`, `"hunt"`, `"unsealed"`, `"hunt_next"`. The line (exact):
  - a night: `ABANDONED % night` (unchanged), then `" " + NOTICE_UP % change` when it rose (`NOTICE_UP := "Lantern Notice +%d%%."`), then `" " + UNSEALED % name` when a seal ended (`UNSEALED := "%s is no longer sealed."`). E.g. `"Night 2 was abandoned: a lost night. Lantern Notice +25%."`
  - a Hunt: `HUNT_ABANDONED % night` (`"Night %d was abandoned: the Hunt is lost."`), `" "`, `SEALS % [name, nights_text(3)]` (`"The Lantern seals %s for %s."`) or `NOTHING_SEALED` (`"The Lantern found nothing to seal."`), `" "`, `NOTICE_AT % 50` (`"Lantern Notice %d%%."`).

- [ ] **Step 1: Failing tests** `tests/test_god_lantern.gd` (SUITES line), dev fill on for the file (off at the end). A slot fixture as `test_god_night.gd`'s; keys from the merged table (global constraints):
  - `_notice_deltas`: bank a lost night (+25), a caught win (`main`, no `ascended`: +10), a clean win (`ascended`: -5); from 0 the clean win stays 0 (`notice_change == 0`); from 50 it is 45; from 90 a lost night is 100 with `notice_change == 10` and `hunt_next == true`; `notice_delta()` gives the three amounts.
  - `_notice_clamp`: `add_notice(-30)` from 10 returns -10; `add_notice(40)` from 80 returns 20.
  - `_forfeit_notice`: a night forfeited from 25 is 50; the line is exactly `"Night 1 was abandoned: a lost night. Lantern Notice +25%."`.
  - `_hunt_due`: 100 -> `hunt_due()` and `hunt_for()` is the tier's entry with `tier`; 99 -> not due, `{}`.
  - `_hunt_draw`: for tiers 1-5 at 100%, `draw()` is `HUNTS[t-1].id` for three seeds, and still when `last_mission` is that id; at 99% the draw is a tier mission and not the last one (P1).
  - `_hunt_won`: a Hunt banked won and caught (`main`, no `ascended`) at tier 2: Notice 0, `notice_change == -100`, Faith = believers + 100, `hunt.won`, `hunt.faith == 100`, Divine Power as `divine_power(d)`, no best written for the id, `last_mission` the id, `carried` counted, `hunt_next == false`.
  - `_hunt_lost`: a Hunt banked lost: `sealed == target` (computed before the bank), `seal_nights == 3`, Notice 50, the key gone from `loadout`, `hunt.sealed`, no bonus Faith, Divine Power 0.
  - `_hunt_forfeit`: a Hunt forfeited (`in_night` its id): the same seal and Notice; the line is `HUNT_ABANDONED`, `SEALS`, `NOTICE_AT` as above with the power's name.
  - `_seal_target`: most carried wins; a tie goes to the higher Might at the learned level (raise one key's level to make it so); a tie on both goes to the earlier `in_tree()` key; the Hunt's own draft is not counted (two keys tied at 2, the Hunt drafts the second and is lost: the first is sealed); a god with one key in the tree -> `""`.
  - `_seal_ticks`: after a seal, three counted nights (bank, forfeit, bank) give `seal_nights` 2, 1, 0; the key is out of `draftable()` but in `in_tree()` until the third, back after; the third's `unsealed` is the key and its forfeit line (if a forfeit) ends with `UNSEALED`.
  - `_seal_replaced`: a lost Hunt while sealed with 1 night left: the old seal ends and the new target is sealed for 3.
  - `_seal_never_traps`: a god with only its two starting abilities loses a Hunt: one sealed, `draftable()` still holds the other; with one key in the tree nothing is sealed, `hunt.sealed == ""`, Notice 50.
  - `_stake`: `hunt_stake()` names the target and "3 nights"; with one key, `"The Lantern has nothing to seal"`.
  - `_bad_seal_file`: `seal_nights: 9` reads 3; `sealed: "<a key>"` with `seal_nights: 0` reads no seal; `sealed: ""` with `seal_nights: 2` reads 0; `notice: -5` reads 0; a P1 file (`version 1`, notice 0, no seal) reads unchanged.
  - Updated P1 checks: `test_god_night._dp` (its fixture has no `ascended`: a caught win, `notice == 10`, `notice_change == 10`); `_forfeit`'s line (+25); `test_endless_flow._load_god_forfeits`'s line (`"Night 3 was abandoned: a lost night. Lantern Notice +25%."`); `game.gd` `_flow_endless()`'s two `hub.line ==` strings (Night 2: `+25%`; Night 3: `+25%`; Night 1 is an ascent, clean, so the Notice is 0, 25, 50).
- [ ] **Step 2: RED**, **Step 3: implement**, **Step 4: GREEN** (suite 8 `failures=0`).
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm)$'` -> all OK.
- [ ] **Step 6: Commit** `feat: the Lantern's rules -- the Notice moves, 100% brings the Hunt, a lost Hunt seals the most-carried ability (god P2)`.

**Numbers:** +25 / +10 / -5 / +25 (rite, P3); Hunt won 0% and `50 x god tier` Faith (*tunable*); lost 50% and 3 nights. **Model:** sonnet; **review:** sonnet (every later task reads these rules; Review Focus 1-3).

---

### Task 2: The Hunt's night (`TierBook.board()` at a tier, `GodNight.def_for()`)

**Goal:** spec §10.2: each Hunt is played by its stand-in "with the Hunt's title and plate, played at the god tier's settings" (P2-5). Only the Informer is not on its god tier (Tier 2 mission, Tier 3 Hunt).

**Files:**
- Modify: `src/game/descend/tier_book.gd` (`board()`), `src/game/god/god_night.gd` (`def_for()` and a private `_dress_hunt()` only).
- Test: `tests/test_god_lantern.gd` (append; Task 1 made it).

**Interfaces:**
- `TierBook.board(id: String, state: DescendState = null, at_tier := 0) -> MissionDef`: with `at_tier` 0 (every existing caller) exactly today's mission; with 1-5 the mission is built as if it sat on that tier: its `tier`, readiness floor, slots and Might (plus `state`), clock and stretch (`clock(at_tier) / own clock`), the unaware tag test, and the Gaze from `GAZE_TIER`. Still `null` for an id not on the board. One change: the tier `board()` builds with.
- `GodNight.def_for(slot, id)`: when `hunt_for(slot)` is not empty and `id` is its `id`, the def is `TierBook.board(id, null, slot.tier)`, then the god's numbers and Faith clock (P1), then `_dress_hunt()`: `def.name = title`, `def.intro_banner = title.to_upper()`. Brief, goal, lose and objectives stay the stand-in's (the plate is shown on Prepare, not in the def). Not a Hunt: P1's def.
- Consumers: Prepare and `Mission.night_def` already call `def_for()` (P1), so Game needs no change for the Hunt to be played.

- [ ] **Step 1: Failing tests** (append to `test_god_lantern.gd`):
  - `_board_at_default`: for every `TierBook.all()` id, `board(id)`, `board(id, null, 0)` and `board(id, null, tier_of(id))` agree on `tier`, `tier_floor`, `clock`, `stretch`, `slots`, `dp_capacity`, `mission_tags`, the act count, and whether `make_objectives` yields a `GazeObjective` (C3: the default path is unchanged).
  - `_board_at_informer`: `board("informer", null, 3)`: tier 3, floor `readiness(3)`, clock `clock(3)`, stretch `clock(3) / MissionBook.informer().clock`, slots `slots(3)`, Might `dp(3)`, no Gaze; at 5 it has a `GazeObjective`; `board("nosuch", null, 3)` is null.
  - `_hunt_def`: for god tiers 1-5 at 100%: `def_for(slot, HUNTS[t-1].id)` has `tier == t`, `name == title`, `intro_banner == title.to_upper()`, the god's slots, Might and pool (`draftable()`), clock `clock(t) + extra_clock()` (with one Faith clock bought); its goal is the stand-in's; Tier 5's objectives hold a `GazeObjective`; a `Descent.new().setup(def, 1).tier == t`.
  - `_hunt_def_not_due`: at 99% `def_for(slot, "lost_lamb")` is P1's (name "The Lost Lamb", banner unchanged).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `8`, or `3` in a parallel group).
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|informer_(none|play|toll)_1|lamb_play_1|ringers_play_1|armoury_play_1|heart_play_1)$'` (`--jobs=2` in a parallel group) -> all OK.
- [ ] **Step 6: Commit** `feat: the Lantern Hunt's night -- its stand-in at the god tier, with the Hunt's name and banner (god P2)`.

**Model:** sonnet; **review:** sonnet (a mission builder every board night uses; Review Focus 4).

---

### Task 3: Screens: hub, results, Prepare, pause

**Goal:** spec §9.1 (hub meter; Prepare shows seals), §9.2 (results: the Notice change), §10.1 ("never changes unseen"), §10.3 ("the hub and Prepare show the seal and the nights left"), §2 anti-goal "every penalty is shown before and after it happens" (P2-11).

**Files:**
- Modify: `src/game/ui/god_hub.gd`, `src/game/ui/results_screen.gd`, `src/game/ui/prepare_screen.gd`, `src/game/ui/pause_menu.gd`.
- Test: `tests/test_faith_hub.gd`, `tests/test_endless_screens.gd`.

**Interfaces and copy (exact):**
- **GodHub:** `lines()` unchanged (index 5 stays `"Lantern Notice %d%%"`, index 6 `"Night N"`; FLOW and P1 tests read them). A drawn meter beside the Notice line (`NOTICE_BAR: Rect2`, filled `notice / 100`, the bad colour; full at 100). `hunt_line() -> String`: `""`, or `HUNT_DUE % title` with `HUNT_DUE := "THE LANTERN HUNTS: the next night is the Hunt, %s"`. `seal_line() -> String`: `""`, or `SEALED % [name, GodSlot.nights_text(seal_nights)]` with `SEALED := "Sealed by the Lantern: %s, %s left"`. Both drawn in the bad colour above the buttons. The one-off `line` wraps at 600 px (it may now be two lines). The dev A key, while `hunt_due()`: no `awaken_dev`, a buzz, `line = AWAKEN_HUNT` (`"The Lantern hunts: face the Hunt first"`), redraw (P2-4). The button stays "Descend" (action `descend`).
- **ResultsScreen.god_lines()** (order, P2-11): Divine Power, level lines, the cap loss, believers and Faith, **the Notice line**, **the Hunt line**, **the unsealed line**, **the next-Hunt line**, `Night N`.
  - Notice: `"Lantern Notice %d%%"` when `notice_change` is 0 or absent (P1's text, P1 tests unchanged); else `"Lantern Notice %d%%  (%s%d%%)"` with `+` or `-` and the absolute change.
  - Hunt won: `"The Hunt is broken: Notice 0%, Faith +%d"` (the bonus). Hunt lost: `"The Lantern seals %s for %s"` (name, `nights_text(seal_nights)`) or `"The Lantern found nothing to seal"`.
  - Unsealed: `"%s is no longer sealed"`. Next Hunt: `"THE LANTERN HUNTS: the next night is the Hunt"`.
  - Colours: a Notice rise, a seal and the next-Hunt line in the bad colour; the Hunt won in gold; a fall in the text colour.
  - `static hunt_called(result) -> String`: `""`, or `"Lantern Hunt: %s  -  %s"` (title, `TierBook.tier_name(tier)`); `_draw_descend()` shows it in place of the mission-and-tier line when not empty.
- **PrepareScreen** (a god's draft): the god's tabs are built from `god.in_tree()` (a sealed key is listed even though the def's pool leaves it out). A sealed card: dimmed, a drawn seal mark over its icon (a red cross or a "SEALED" plate, drawn shapes only), its cost line `card_cost_text()` = `"Sealed: %s" % nights_text(seal_nights)`; a click on it (or on it in any way that would pick it) refuses with `REFUSE_SEALED % nights_text(...)`, `REFUSE_SEALED := "Sealed by the Lantern: %s left"`; it is never picked. `header_text() -> String`: `"THE LANTERN HUNT"` when `GodNight.hunt_for(god)` is not empty, else `"PREPARE THE MANIFESTATION"`. `brief_rows() -> Array` (the panel's `[label, value]` pairs, drawn as today): a Hunt's rows are `HUNT` (`"%s: %s" % [title, plate]`), `WIN`, `LOSE` (the stand-in's), `IF WON` (`"Notice 0%%, +%d Faith"`, `HUNT_FAITH x tier`), `IF LOST` (`"%s; Notice 50%%" % GodNight.hunt_stake(god)`), `LOADOUT`; other nights' rows are today's six. Every row must fit the panel (measure; shrink nothing else).
- **PauseMenu:** `CONFIRM_LOST := "Abandon now and the night is lost: no Divine Power, no Faith, Lantern Notice +25%."`; `var hunt_stake := ""` (set by Game before `setup()`); `CONFIRM_HUNT := "Abandon the Hunt and it is lost. %s, and the Notice goes to 50%%."`; `confirm_line()` gives `CONFIRM_HUNT % hunt_stake` when the night forfeits and `hunt_stake` is set, else as P1. The confirm's text wraps inside `CONFIRM_WIDTH` (check two lines fit). `InterludeScreen` keeps reading `PauseMenu.CONFIRM_LOST` (no stand-in has acts).

- [ ] **Step 1: Failing tests:**
  - `test_faith_hub.gd`: `_hub_notice` (`lines()` unchanged at 0 and 75%; the meter's fill fraction, exposed as `notice_fill() -> float`, is 0.75), `_hub_hunt` (100%: `hunt_line()` names tier 1's title; 99%: `""`), `_hub_seal` (`seal_line()` with 3, 1 night: "3 nights left", "1 night left"; none: `""`), `_hub_awaken_refused` (dev on: at 100% A emits nothing and sets `line` to `AWAKEN_HUNT`; at 99% A emits `awaken_dev`).
  - `test_endless_screens.gd`: `_god_lines_notice` (+25, -5, and 0/absent as P1), `_god_lines_hunt_won`, `_god_lines_hunt_lost`, `_god_lines_nothing_sealed`, `_god_lines_unsealed`, `_god_lines_hunt_next` (exact arrays from hand-built `god` dictionaries), `_hunt_called` (a Hunt result, and `""` for a night), `_prepare_sealed` (a god with a sealed key: listed in its tab, `card_cost_text()`, a click is refused with the exact text and picks nothing, `preselect` of the key picks nothing), `_prepare_hunt` (`header_text()` and `brief_rows()` labels and the IF LOST value naming the target; a night's rows unchanged), `_pause_hunt` (`confirm_line()` with a stake after the clock; `CONFIRM_LOST`'s new text without one).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite `8`, or `3` in a parallel group). P1's screen tests stay green.
- [ ] **Step 5: References** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm)$'` (`--jobs=2` in a parallel group).
- [ ] **Step 6: Commit** `feat: the Lantern on screen -- the hub's meter, Hunt and seal; the results' Notice change and Hunt lines; sealed cards and the Hunt's stake (god P2)`.

**Model:** sonnet; **review:** none (screens; the milestone review and FLOW cover them).

---

### Task 4: Game wiring and photographs

**Goal:** the Hunt's stake on the pause menu (§9.1 "the pause menu says so before it confirms"), a hub line when the god's file cannot be written (P1 milestone review M3, P2-13), the Hunt through `load_god` (a game closed mid-Hunt), and photographs of the new states (P2-15).

**Files:**
- Modify: `src/game/game.gd` (`write_god()`, `_write_god()`, `_open_pause()`, the `--show` match and a `_show_lantern()`, `SAMPLE_HUNT_WON` / `SAMPLE_HUNT_LOST`), `tests/test_endless_flow.gd` (new sub-tests).

**Interfaces:**
- `static Game.write_god(slot: GodSlot, file: String) -> String`: writes; `""` on success, else `WRITE_FAILED % err` with `WRITE_FAILED := "The god could not be saved (error %d): progress since the last save may be lost."`. `_write_god()` calls it and, on a failure, appends the line to `_hub_line` (after any line already there) and keeps P1's `push_warning`.
- `_open_pause()`: in Endless Night with the clock started and `god.hunt_due()`, `_pause.hunt_stake = GodNight.hunt_stake(god)` before `setup()`.
- `--show` names (with `_show_endless()`'s fixture god, `dev`, the show's slot files): `hub-hunt` (Notice 100%), `hub-sealed` (Smite-or-the-target sealed, 2 nights left, Notice 50%, the hub line of a lost Hunt's forfeit), `prepare-hunt` (100%: the Hunt's Prepare), `prepare-sealed` (a sealed card), `results-hunt-won`, `results-hunt-lost` (from the two `SAMPLE_HUNT_*` results, shaped as `bank()` returns them). Keys come from the fixture god's learned keys (the dev fill), not new literals.
- `load_god()` is unchanged: `GodNight.forfeit()` (Task 1) makes a Hunt left mid-way a lost Hunt.

- [ ] **Step 1: Failing tests** (`test_endless_flow.gd`): `_load_god_hunt` (a slot file at 100% with `in_night` the tier's Hunt id and `carried` set: `load_god()` gives the slot sealed on the target, 3 nights, Notice 50, the exact Hunt forfeit line, and the file agrees; opened again, nothing more happens); `_write_fails` (`write_god()` to `user://no_such_dir_p2/x.cfg` returns `WRITE_FAILED` with the error; to a good test file returns `""`).
- [ ] **Steps 2-4:** RED, implement, GREEN (suite 8).
- [ ] **Step 5: Photographs:** each of the six `--show` names with `SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`; look at each (text fits, nothing overlaps the buttons); paths in the report.
- [ ] **Step 6: References** `--only='^(digest|crowd_check|calm)$'`; **FLOW alone** (`tasklist | grep -i godot` first): `failures=0` (P1's walk with Task 1's new forfeit lines).
- [ ] **Step 7: Commit** `feat: the Lantern in Game -- the Hunt's stake on the pause menu, a hub line when the god cannot be saved, photographs (god P2)`.

**Model:** sonnet; **review:** sonnet (Game wiring; Review Focus 2, 5).

---

### Task 5: FLOW: the Lantern walk

**Goal:** C6: FLOW walks the Notice reaching 100% and a Hunt night, deterministically, through the real screens (P2-14).

**Files:** `src/game/game.gd` (`_flow_lantern(step)`, called right after `await _flow_endless(step)`; a doc comment listing its steps like `_flow_endless()`'s).

**The walk** (`dev = true`, the dev fill on; restored at the end exactly as `_flow_endless()`'s `out`):
1. The board's ENDLESS, Continue on slot 1 (the god `_flow_endless()` left): the hub shows `Lantern Notice 50%` (Night 1 an ascent: 0; Nights 2 and 3 forfeited: +25 each) and no Hunt line.
2. Fixture (written to the god's file, then the hub reopened): `notice = 75`; `carried` set so the target is the first starting key by count (e.g. that key 4, the other 1); a seed found by a loop (as P1's) so the draw is a single-act mission other than `last_mission`.
3. Descend, MANIFEST the two starting keys, past the intro, `in_night` set; pause: `confirm_line() == PauseMenu.CONFIRM_LOST`; Abandon: the hub's `line` is exactly `"Night 4 was abandoned: a lost night. Lantern Notice +25%."`, Notice 100, `hunt_line()` not empty, the file agrees.
4. Press A (dev): refused, the tier unchanged, `line == GodHub.AWAKEN_HUNT`.
5. Descend: `mission_id == GodNight.HUNTS[0].id` (whatever the seed), Prepare's `header_text() == "THE LANTERN HUNT"`, its IF LOST row names the target.
6. MANIFEST, past the intro: the night's def is the Hunt (`rules().mission.name == HUNTS[0].title`, `tier == 1`); pause: `confirm_line() == PauseMenu.CONFIRM_HUNT % GodNight.hunt_stake(god)`; resume.
7. Lose it the real way: `_mission.rules().force_end(false, "dawn")` (before the main objective); the results come up: `result.god.hunt.won == false`, `hunt.sealed` is the target, `god_lines()` holds the seal line, `hunt_called()` names the Hunt; the god and its file: sealed, 3 nights, Notice 50, Night 5, `last_mission` the Hunt's id, the target not in `loadout`, Divine Power and Faith unchanged.
8. Continue: the hub's `seal_line()` is exact (3 nights left), no Hunt line.
9. Descend: the draw is not the Hunt's id; Prepare lists the sealed card, its `card_cost_text()` is `"Sealed: 3 nights"`, a click on it is refused with the exact text and picks nothing; Back to the hub is free (Night 5 still).
10. Title; the board's save bytes are what they were at the walk's start (C7); out (dev, dev fill off, the board).

- [ ] Implement; run **FLOW alone** (`tasklist | grep -i godot` first): `failures=0`; report the checks count and the time (P1: 160 checks, 3 m 44 s; this walk should add about a minute: two night loads and one ending). If FLOW passes 10 minutes, report it (do not cut steps without the controller).
- [ ] Suite 8 (`test_flow.gd` unchanged: no new screen); references `--only='^(digest|crowd_check|calm)$'`.
- [ ] Commit `test: FLOW walks the Lantern -- the Notice to 100%, a Hunt lost, the seal on the hub and Prepare (god P2)`.

**Model:** sonnet; **review:** none.

---

### Task 6: Landing on `feat/god-progression` (C1, C7)

Run by the controller (the references and the bench pass 10 minutes; P1's R5: land.sh's steps by hand, in its order; the long ones in the background are fine for the controller). `land.sh` itself trial-merges `origin/feat/Develop-Main`, which P2 does not land on, so its steps are run by hand:

- [ ] `git fetch origin`; `git log --oneline HEAD..origin/feat/god-progression` (the user's Tier 1 fill may have landed). If it moved: commit nothing uncommitted first (memory `trial-merge-needs-commit`), `git merge-tree --write-tree --name-only HEAD origin/feat/god-progression`; clean -> `git merge --no-ff origin/feat/god-progression` into this branch; a conflict -> stop and report the files. Check API clashes by hand: the fill touches `GodTree.TABLE` only; any P1 or P2 test or FLOW step that assumed a key the fill now replaces is a P2 bug to fix here (a test assuming the table is empty is against C2).
- [ ] Import (exit 0); `bash tools/dev/run_suite_parallel.sh 8` -> `failures=0`.
- [ ] References, all rows: `bash tools/dev/refs_check.sh --jobs=8 > <scratch>/refs.txt 2>&1` (background; ~2 h); `grep -v ' OK$'` -> only the header lines; `digest` and `crowd_check` OK.
- [ ] FLOW alone (`tasklist | grep -i godot` first) -> `failures=0`; note the checks and the time.
- [ ] Bench vs `kak-god-p1` (C7): `bash tools/dev/land.sh --bench-only --bench=kak-god-p1` (background; it waits for a quiet machine) -> the five pairs within ~1 fps (rerun a noisy pair; memory `kak-m1-perf-debt`).
- [ ] A mover or a failure: find the task that caused it, fix in a commit naming it (`fix: god P2 landing -- <what>`), rerun the step.
- [ ] Then the controller's opus milestone review (one fix wave, sonnet re-review), Task 7, tag `kak-god-p2`, ff `feat/god-progression` to this branch. Nothing is pushed without the user's yes; `feat/Develop-Main` is never touched.

**Model:** controller (or a sonnet runner allowed background commands); **review:** the opus milestone review.

---

### Task 7: Notes

- [ ] `docs/KAK_God_P2_Summary.md` in P1's summary's shape: what you asked; what P2 built, by spec section (§9.1, §9.2, §10.1-§10.3, §12); how to see it (the DEV path, and how to reach a Hunt quickly: a god at 75% and one abandoned night); the numbers in play (exact / *tunable*); the stand-ins table; landing (the gates table, bench pairs); known small issues; what is not yet there (the five real Hunt nights P5, rites P3, the Awaken button routing to the Hunt); needs you.
- [ ] `docs/KAK_God_P2_Rulings.md` in P1's rulings' shape: C1-C7, any controller rulings added, P2-1 to P2-16, every task's `Ruling:` lines, the milestone review and fix wave. Every entry: what was decided, why, cost if wrong.
- [ ] One Dev Ledger line per task in the report (the controller writes the Ledger and refreshes the board).
- [ ] Commit `docs: god P2 summary and rulings`.

**Model:** sonnet; **review:** none.

---

## Rulings

Settled against the code at `a45a7c17`. Each has why and the cost if wrong.

- **P2-1 (Task 1): the Notice amounts map onto the bank exactly.** `Descent.report()`'s `descend` has `main`, `ascended`, `caught`: a lost night (`main` false, which is every night that is not won: a board night is won only through its main objective) +25; won and `ascended` -5; won and not `ascended` (caught after the main objective: dawn, the bell, the Gaze, ...) +10. There is no "won, neither clean nor caught" case in the code: a held night ends only by an ascent or a catch. A forfeit (Abandon, the interlude's Abandon, a game closed mid-night) is a lost night, +25. Clamped 0..100 by `add_notice()`; `notice_change` is the real change. The lost rite's +25 is `NOTICE_LOST_RITE`, unused until P3. Why: spec §10.1 and §9.1, read through the report's real fields. Cost if wrong: one constant or one condition in `notice_delta()`.
- **P2-2 (Task 1): "clean" is "ascended"; "caught" includes a dawn catch.** The spec's clean win is "ascended, no seen death", but the code counts no seen deaths per night (only some Gaze meters add them, and a Tier 5 night's Gaze would already have caught the god), and the spec's caught row ("Halcyon saw") is the code's `caught`, whose reasons also include dawn after the main objective. Every caught night is +10. Why: the report has no seen-death count, and adding one means touching `Crowd`/the directors (C3 risk) for a few percent. Cost if wrong: a per-night seen-death count in the Descent (a counter on `GazeMeter.seen_death()`-like calls) and one more condition; references to rerun.
- **P2-3 (Task 1): the Hunt is derived, not stored.** `hunt_due()` is `notice >= 100`. The Notice changes only at bank and forfeit, so the night being banked is a Hunt exactly when `hunt_due()` holds at the bank's start; both results of a Hunt take the Notice away from 100. No save field is added; `VERSION` stays 1. Why: one source of truth; P1 files read as they are. Cost if wrong: a `hunt_due` field and a version bump (small).
- **P2-4 (Tasks 1, 3): the Hunt cannot be skipped.** At 100% `draw()` returns the god tier's stand-in whatever the seed and even when it was the last mission (the no-repeat rule yields to the Hunt); quitting from Prepare and returning gives the same Hunt. The dev Awaken (hub key A) is refused while the Hunt is due, with a line; P3's Awaken button must route to the Hunt the same way (`hunt_due()`). Leaving from Prepare or the intro stays free (P1's P9). Why: spec §10.2 "cannot be skipped; Descend and Awaken both lead to it"; in P2 Awaken is only a dev hook that is not a night, so leading it to the Hunt would be a new path for nothing. Cost if wrong: the A key opens the Hunt's Prepare instead (a few lines).
- **P2-5 (Tasks 1, 2, 3): the stand-ins and how the Hunt shows.** The five Hunts are data (`GodNight.HUNTS`) with the spec's titles and plates and the stand-in ids (Lost Lamb, Bell Ringers, Informer, Armoury, Heart of Faith). Each is played at the god tier: `TierBook.board(id, null, god tier)`; only the Informer (a Tier 2 mission) differs from its own tier, and plays with Tier 3's readiness, clock, wishes and multiplier. The Hunt's title is the def's `name` and its intro banner; Prepare's header is "THE LANTERN HUNT" and its brief shows the title and plate, the stand-in's own WIN and LOSE (true to what is played), IF WON and IF LOST; the results show "Lantern Hunt: <title> - <tier>". The HUD is unchanged (it shows no mission name today). Why: spec §10.2 "with the Hunt's title and plate, played at the god tier's settings"; the plate describes the future Hunt, so the stand-in's real goal must stay readable. Cost if wrong: copy and one draw call per screen.
- **P2-6 (Task 1): the Hunt's result.** Won = the main objective done (caught after it still counts as won): Notice set to 0, Faith `+50 x god tier` (*tunable*; the god tier is the Hunt's tier), Divine Power as any night (`divine_power(d)` at the Hunt's tier). Lost (main not done, or forfeited): the seal, Notice set to 50; no +25 on top. Why: spec §10.3; "resets to 50%" is a set, not a delta. Cost if wrong: one line each.
- **P2-7 (Task 1): the most-carried ability, exactly.** Candidates: the god's learned keys that sit in a tree spot, sealed or not (`in_tree()`). Order: the most nights carried (`carried`, banked nights only, as P1's P16; a forfeit carries nothing), then the higher Might at the key's learned level (`might_of()`, what the draft charges), then the earlier key in `GodTree.spots()` order (ring order from Ruin, then tier, then index: the order `draftable()` and Prepare's tabs already use). The target is chosen from `carried` as it stood before the Hunt night (the Hunt's own draft is counted after), so what Prepare and the pause menu showed is what is sealed. Nothing is random. Why: spec §10.3; "earlier tree spot" needs one order and this is the code's. Cost if wrong: one sort key (e.g. own type first).
- **P2-8 (Task 1): the seal never traps the god.** With fewer than 2 keys in the tree nothing is sealed ("The Lantern found nothing to seal"; the Notice still goes to 50). A god always keeps at least one draftable ability, so P1's P8 (Descend blocked with nothing to draft) can never be reached through a seal. Why: a blocked Descend would end the god's run. Cost if wrong: a god with one ability goes unpunished (it cannot happen with a filled Tier 1: two starting abilities).
- **P2-9 (Task 1): the seal's 3 nights.** "The next 3 nights" are the next three nights that count after the Hunt, banked or forfeited, Hunts included. The seal ticks at the start of each bank and forfeit (before a new seal), so it covers exactly those three Prepares and ends as the third is banked; the results or the forfeit line say so ("<name> is no longer sealed"). A lost Hunt while a seal is on replaces it (one seal at a time: the save holds one key) with a fresh 3. The sealed key is dropped from the remembered loadout and not given back when the seal ends. Why: spec §10.3 "for the next 3 nights"; with +25 steps a new Hunt can only come on a seal's last night, so a replacement is the simplest rule that holds. Cost if wrong: a tick placement (one line) or a second seal field.
- **P2-10 (Task 1): Hunt bookkeeping.** The Hunt's stand-in id becomes `last_mission` (the next night's draw avoids it); the night counts; wishes are heard at the tier's count; `carried` counts the Hunt's draft; **no per-mission best is kept for a Hunt** (P1's Task 5 ruling "each mission id sits on one tier only" no longer holds for the Informer at Tier 3, and P5's real Hunts get their own ids). Cost if wrong: one condition in `bank()`.
- **P2-11 (Tasks 3, 4): showing it.** Hub: P1's lines unchanged, a drawn Notice meter, a "THE LANTERN HUNTS" line, the seal line with nights left, the refused-Awaken line. Results: the Notice line gains its change only when it moved (P1's results and tests unchanged otherwise), then the Hunt, unsealed and next-Hunt lines before `Night N`. Pause: the lost-night confirm names the Notice; a Hunt's names the ability it would seal. All copy in this plan is *(my call)*. Why: spec §10.1 "never changes unseen", §10.3 "the hub and Prepare show the seal", §2 "every penalty is shown before and after". Cost if wrong: copy and layout only.
- **P2-12 (Tasks 1, 4): the save and damaged files.** No new field (P1 writes `notice`, `sealed`, `seal_nights`); `VERSION` stays 1. `read()` clamps the Notice 0..100 (P1), `seal_nights` 0..3, and a half seal (key without nights or nights without key) to none. A sealed key that respec unlearned stays sealed until it ticks out (harmless: it is not draftable). Cost if wrong: a version bump later.
- **P2-13 (Task 4): a failed write is shown (P1 review M3).** `Game.write_god()` returns a line on failure, appended to the next hub line. Why: a forfeit now costs Notice, so a quit that escapes it through a disk error must at least be visible. Cost if wrong: one line.
- **P2-14 (Task 5): FLOW loses the Hunt.** The walk presets the Notice to 75% (a fixture, as P1's seed loop), abandons one night to reach 100%, then plays the Hunt and loses it through `Rules.force_end(false, "dawn")`, which goes through the real ending, bank and results (the Hunt's abandon path is covered by Task 1's `_hunt_forfeit` and Task 4's `_load_god_hunt`). A lost Hunt exercises more (the seal on results, hub and Prepare) than a win, and needs no scripted play. Deterministic: fixture seed, fixture `carried`, no wall clock in any check. Cost if wrong: a win walk later (main objective forced as P1's Warning stars).
- **P2-15 (Task 4): photographs.** Six `--show` names: `hub-hunt`, `hub-sealed`, `prepare-hunt`, `prepare-sealed`, `results-hunt-won`, `results-hunt-lost`, on P1's fixture god and the show's own slot files. Cost if wrong: none.
- **P2-16 (Task 6): landing.** Trial merge against `origin/feat/god-progression` (not `feat/Develop-Main`), the merged tree gated (suite, all references, FLOW alone), bench vs `kak-god-p1`; land.sh's steps by hand (its trial merge targets `feat/Develop-Main`), the long ones in the background by the controller (P1's R5). Cost if wrong: none.

## Needs the user (not blocking P2)

- The five real Hunt nights (spec §10.2: each its own short mission spec, P5) to replace the stand-ins.
- The Hunt's copy (titles and plates are the spec's; every other line is *(my call)*), and the Hunt's Faith bonus (`50 x tier`, *tunable*).
- Whether a clean win should also require no seen death (P2-2), which needs a seen-death count per night.
- The Tier 1 fill of `GodTree.TABLE` (P1's open item; the per-type win check runs then). Note that the Informer at Tier 3 (the Tier 3 Hunt's stand-in) is not checked winnable by the scripted players.
