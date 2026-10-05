# KAK v0.10 M3 — Broken Lanterns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the Ruin path's Night 2, *Broken Lanterns*, becomes a real mission. Break Halcyon's six wayside shrines and let each stay broken long enough to drain, before the Vigil's flame-bearer relights it, while the Faithful pray at the standing shrines, the Lantern Knights come at 1:30 and the last shrine is ringed by kneelers.

**Architecture:**
- **The wayside shrine** is a new structure kind, `Structure.Kind.SHRINE` (last in the enum): a small stone post with a lantern niche.
  - The procedural art draws it on both art paths; it has no sprite yet.
  - Its role, `&"shrine"`, is not one of `Rules.BUILDING_ROLES`, so a shrine is never a building in the tally, the chain or the score.
- **The shrines exist only in Broken Lanterns.** `BrokenLanternsDirector` places them when the mission begins and hands them to the town (`Town._built`), which takes them away with its own buildings. `TownLayout` gains nothing, so every other mission's town (and the digest) is unchanged.
- **`BrokenLanternsDirector`** runs the night:
  - **Draining:** a broken shrine drains after `DRAIN_SECONDS`.
  - **Relighting:** the flame-bearer turns aside for a broken shrine; reaching it before it drains, he relights it (`Structure.restore()`).
  - **Prayer:** each shrine broken sends `PRAYERS` Faithful to each standing shrine, and their prayer feeds `GazeMeter.pray()`.
  - **The Knights:** at 1:30 the Lantern Knights come and guard the standing shrines. A guarded shrine takes no damage.
  - **The kneelers:** when five shrines are drained, the kneelers ring the last one.
- **`VigilRoute`** (M2) gains three opt-in switches, all off by default so Mira's House walks exactly as before:
  - `loop`: round again from the first point;
  - `divert()`: turn aside to one place, then take the route up again;
  - `pass_flame`: a dead bearer's flame passes to an acolyte.
- **`GazeMeter`** (M2) now judges seen deaths itself (`note_death()`, `judge_deaths()`), lifted out of `MirasHouseDirector`, so both directors share one rule.
- **The Lantern Knight** is a soldier added mid-mission (`Crowd.add_soldier()`), with a new last corps, `Person.Corps.KNIGHT`.
  - It has three times a soldier's health.
  - On the procedural path it wears a gold tabard; on the sprite path, the escort's sprite stands in.
  - No other corps' work (the rally, the marshals, the escorts) takes a Knight.
- **The objectives:**
  - the win: `ShrinesObjective`, six drained;
  - the losses: `BellSilentObjective`, `GazeObjective` and a dawn `ClockObjective`;
  - the bonus: `ThroughFaithfulObjective`.

**Tech Stack:** Godot 4.7.2, GDScript; headless tests in `tests/run_all.gd`; scripted scenarios in `tools/dev/behaviour_check.gd`.

**Spec:** `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Read §3.4, §4.1 (the Vigil, and Ruin — Broken Lanterns), §6, §7 and §8.3 before any task. This plan covers **M3**. M2's plan (`docs/superpowers/plans/2026-10-05-kak-v010-m2-gaze-miras-house.md`) built the pieces reused here.

## Global Constraints

- **Baseline:** `feat/Develop-Main` at `140a240` (tag `kak-v010-m2`, plus the merged VFX branch: Tier I powers, Death, Dominion with Disorder, Decree). The milestone tag is `kak-v010-m3`.
- **No playtest notes yet:** the user has not playtested M2. Every number below is a starting value from the spec, and Task 8 measures it.
- **Machine:** the BURIN_NITRO laptop.
  - **Repository:** the main checkout is `C:\BURIN_NITRO\Godot\GIT\vfxProve` (Git Bash `/c/BURIN_NITRO/Godot/GIT/vfxProve`) on `feat/Develop-Main`. Work in the checkout the controller names: the main checkout, or a session worktree on a branch made from `feat/Develop-Main`. Never touch other sessions' worktrees.
  - **In a fresh worktree,** run the import first.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`. Expected: `checks=N failures=0`. The baseline is **3140**; new suites add to it. The `leaked` / `still in use` lines at exit are there at baseline too.
  - **Digest:** `$G --headless --path . -s tools/dev/state_digest.gd`. Expected: `digest=61267b7e90524d800bf1c3473a71146b`.
  - **crowd_check:** `$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`. Expected: `checksum=-346732806`.
  - **Behaviour (exact):** `$G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<name>`. Give each run `timeout 600`, and run them in the background with a long limit, since the ten take about 15 min. The VFX merge moved them (M2 moved none); this is the **new** baseline:
    - `calm --seconds=60`: -355092532
    - `gates`: 589794389
    - `fire`: 250399241
    - `rite --interrupt`: -948525703
    - `soldiers --case=escort`: -778609674
    - `warning --case=none|doom|whisper|discord|mix`: -489775734, -905773030, -588314462, -997640091, -206935500
  - **Mira's House stays exact:** `--scenario=miras --case=play` prints the same `BEHAVIOUR miras result …` line and `BEHAVIOUR checksum=…` before and after Tasks 1 and 4 (a fixed step makes it repeatable). Task 1 Step 1 records them.
  - **FLOW:** `$G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`. Expected: `failures=0`. The baseline is **82** (it plays the Vigil Flame placeholder, not Broken Lanterns).
  - **Mission tests:** `--mission-test` within a few of: buildings about 53, citizens 184–193, escaped 0–1, stability 67–71%, citadel 50%. `--mission=warning --mission-test` gives `won=false reason=bell time≈24`. These are not exact (memory: hitstop wall clock).
  - **Captures:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
- **Powers:** 38 powers; the Authorities are Ruin, Veil, Dominion, Passage, Death, Decree. Broken Lanterns' pool is `MissionBook.VIGIL_POOL + RUIN_POOL` (whisper, doom, wisp, discord, thorns, heaven, tornado, dragon, gravity), unchanged.
- **Test style:** as in M2.
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - Build the town and crowd like `tests/test_miras_house.gd`'s `_setup()`, and step `crowd.advance(DT)` then `rules.advance(DT)`.
  - **Headless tests never move or think people:** `Crowd.advance()` does not call `Person.frame()`. Put people where a test needs them with `_arrive()`, and set a mind by hand (`p.mind = Person.Mind.RECOVER`) to stand for what thinking would do.
- **Code style:**
  - tabs; `##` docs in full sentences; `UPPER_CASE` constants with a `##` comment;
  - **new enum values go at the end:** `Structure.Kind.SHRINE` after `FOUNTAIN`, `Person.Corps.KNIGHT` after `RESCUE`;
  - `CitizenProfile.Role` and `CitizenProfile.Faith` gain nothing (the Faithful are M2's `Faith.FAITHFUL`).
- **Nothing outside Broken Lanterns may change.** The Warning, The Long Night, Last Judgement, Mira's House and the Vigil Flame placeholder play exactly as before. Every exact gate stays identical.
  - Shrines are placed only by `BrokenLanternsDirector`, never in `TownLayout` or `Town.build()`.
  - Nothing hashes `Structure.Kind` or `Person.Corps` by count; values appended at the end leave every existing value as it was.
- **Git:**
  - stage explicit paths, with each new script's `.gd.uid` file;
  - never stage `default_bus_layout.tres`, `captures/`, `.codex/` or `concepts/`;
  - commit subjects are tagged `(v0.10)` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
  - **do not push or tag:** the controller does that at the gate.
- **Tuning latitude:** the code was written against `140a240` and has not been run.
  - Fix real bugs and keep each test's intent.
  - Placement constants may move when the town's geometry needs it: `SHRINE_SPOTS`, `RELIGHT_OFF`, `PRAY_RING`, `KNEEL_RINGS`, `GUARD_OFFSETS`, `CAMERA_AT`, the shrine's drawing pixels.
  - Gameplay numbers move only in Task 8.
  - Report every deviation.

## Review Focus

These are inputs the spec implies but no feature test exercises. Each line has its test in the owning task.

1. **The flame-bearer is killed, then both acolytes** (a Silent Doom on the Vigil). The flame passes to the first living acolyte, then the next. With all three dead, nothing relights, broken shrines drain, the HUD arrow goes away, and there is no SCRIPT ERROR. *Test:* Task 5 (`_relight`).
2. **The fifth shrine drains while the sixth is already broken.** Nobody kneels. If the sixth drains too, the night is won without the bonus. If the flame relights the sixth instead, the kneelers come then. *Test:* Task 6 (`_focus`).
3. **The Knights come with fewer standing shrines than Knights, or none.** With fewer, they double up, two places to a shrine. With none, they come and guard nothing. Either way, no SCRIPT ERROR. *Test:* Task 6 (`_knights`).
4. **A shrine relit, then broken again.** Its drain starts again from 20 s, not where it stopped. While it is lit again it counts as standing. *Test:* Task 5 (`_relight`).
5. **The Faithful run out.** When everyone is dead, inside or walking the Vigil, a break sends nobody. Prayers killed at their shrine leave no ghost entries behind. *Test:* Task 6 (`_focus`).

## Where this plan departs from the spec

The controller reports these to the user at the gate.

1. **"Guard" means a shield.** A shrine with a living Lantern Knight within `GUARD_REACH` (1.5) takes no damage. A Knight cannot be confused, whispered, lured or frightened (he is a soldier), so he has to be killed first. A Heaven Splitter's line strikes people before stones, so one cast can kill the Knight and break the shrine. The spec's three times the health counts only against blows. A power kills a Knight outright, as it kills anyone.
2. **The Faithful do not report in Broken Lanterns.** The spec's Broken Lanterns section lists no reports and its own losses (the bell, the Gaze, the clock), and Ruin is loud by nature. Their answer to a broken shrine is prayer. The Gaze rises from prayer, seen deaths and the bell. M2's `TempleReport` is not used here.
3. **The flame passes on.** When the bearer dies, the first living acolyte takes up the flame. Only with all three dead does relighting stop. The spec is silent; otherwise one Silent Doom would end the night's only threat to the plan.
4. **Prayer is topped up, not stacked.** Each break tops every standing shrine up to `PRAYERS` (3) living Faithful, instead of sending 3 more each time. No one prays before the first break. When the last shrine is broken, its kneelers stay kneeling by it rather than being let go.
5. **The bonus counts the kneelers from the step before the blow.** So a strike that kills kneelers as it breaks the shrine still counts them as "still there". That is what "strike through them" asks.
6. **Looks wait for M5.** The shrine is drawn by the procedural art on both art paths. The Knight wears the escort's sprite on the sprite path and a gold tabard on the procedural one.
7. **Loadouts.** The mission's default loadout is Heaven Splitter, Silent Doom and Discord (5 DP), so it fits a Night 2 played after a bite. The scripted policy drafts Heaven Splitter, Dragonfire Parade and Silent Doom (6 DP), within §7's 8 DP.

---

## File structure

| File | Responsibility |
|---|---|
| `src/environment/structure.gd` | `Kind.SHRINE` (last), `SHRINE_HP`, its palette and its lantern niche |
| `src/game/crowd/person.gd` | `Corps.KNIGHT` (last), `HEALTH_KNIGHT`, the gold tabard |
| `src/environment/art/people_art.gd` | The Knight's design name and its stand-in (the escort's sprite) |
| `src/game/crowd/crowd.gd` | `add_soldier()`: a soldier come mid-mission |
| `src/game/mission/gaze_meter.gd` | `note_death()`, `judge_deaths()`: seen deaths judged by the Gaze |
| `src/game/mission/miras_house_director.gd` | Uses the Gaze's death judge (no change in play) |
| `src/game/mission/vigil_route.gd` | `loop`, `divert()`, `pass_flame`, `flame_passed` |
| `src/game/mission/broken_lanterns_director.gd` | **New.** Broken Lanterns |
| `src/game/mission/shrines_objective.gd`, `through_faithful_objective.gd` | **New.** The night's win and its bonus |
| `src/game/mission/mission_book.gd` | `broken_lanterns()` becomes the real mission |
| `src/game/ui/results_screen.gd` | The titles `drained`, `relit` |
| `tools/dev/behaviour_check.gd` | The `lanterns` scenario |
| `src/game/game.gd` | `--show=lanterns` |
| `tests/test_shrine.gd`, `test_lantern_knight.gd`, `test_broken_lanterns.gd` | **New** tests |
| `tests/test_gaze.gd`, `test_vigil_route.gd`, `test_mission_book.gd` | New checks |

---

## Milestone 3 — Broken Lanterns

### Task 1: The Gaze judges seen deaths

**Files:**
- Modify: `src/game/mission/gaze_meter.gd`, `src/game/mission/miras_house_director.gd:80-81,160,176-189`, `tests/test_gaze.gd`

**Interfaces:**
- Consumes: `Crowd._doomed`, `Crowd.nearest_witness(at)`, `Crowd._settle_doom()`.
- Produces: `GazeMeter.note_death(at: Vector2)`, `GazeMeter.judge_deaths(crowd: Crowd)`. Every Night 2 director calls `note_death` from its `enemy_killed` handler, and `judge_deaths` once per step.

- [ ] **Step 1: Record Mira's House.** Run `--scenario=miras --case=play` and keep its last two lines (`BEHAVIOUR miras result …` and `BEHAVIOUR checksum=…`). Task 4 compares against them too.

- [ ] **Step 2: Write the failing test.** In `tests/test_gaze.gd`, add `_deaths(t)` as the last line of `run()`, and add these functions to the file:

```gdscript
static func _crowd() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## Seen deaths (v0.10 M3: judged by the Gaze itself, for every Night 2 director): a death with a living witness within
## Crowd.DOOM_WITNESS adds SEEN_DEATH, once; an unseen one adds nothing; nothing is judged while a Silent Doom's victims
## are still being judged (they never witness each other).
static func _deaths(t) -> void:
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var g := GazeMeter.new()
	var victim := crowd.citizens[3]
	var witness := crowd.citizens[4]
	witness.ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	crowd._field.kill(victim, &"doom")
	g.note_death(victim.ground_pos)
	g.judge_deaths(crowd)
	t.check(g.value == 0.0 and not crowd._doomed.is_empty(), "nothing is judged while a Silent Doom's victims still are")
	crowd._settle_doom()
	g.judge_deaths(crowd)
	t.near(g.value, GazeMeter.SEEN_DEATH, 0.001, "a death someone saw adds 10")
	g.judge_deaths(crowd)
	t.near(g.value, GazeMeter.SEEN_DEATH, 0.001, "and is judged once")
	g.note_death(Vector2(60.0, 60.0))
	g.judge_deaths(crowd)
	t.near(g.value, GazeMeter.SEEN_DEATH, 0.001, "a death nobody saw adds nothing")
	g.judge_deaths(null)
	t.near(g.value, GazeMeter.SEEN_DEATH, 0.001, "and without a crowd nothing is judged")
	_done(s)
```

- [ ] **Step 3: Run the tests to verify they fail.** Expected: a Parse Error naming `note_death`.

- [ ] **Step 4: The Gaze's death judge.** In `src/game/mission/gaze_meter.gd`:
  - Under `var value := 0.0`, add:

```gdscript
## Where people died, waiting for judge_deaths().
var _deaths: Array[Vector2] = []
```

  - At the end of the file, add:

```gdscript
## Someone died at `at` (v0.10 M3, for every Night 2 director): judge_deaths() decides whether anyone saw it.
func note_death(at: Vector2) -> void:
	_deaths.append(at)


## Each noted death that someone living saw (Crowd.nearest_witness()) adds SEEN_DEATH. It waits while the crowd is
## still judging a Silent Doom's victims, so a cast's victims never witness each other.
func judge_deaths(crowd: Crowd) -> void:
	if _deaths.is_empty() or crowd == null or not crowd._doomed.is_empty():
		return
	for at in _deaths:
		if crowd.nearest_witness(at) != null:
			seen_death()
	_deaths.clear()
```

- [ ] **Step 5: Mira's House uses it.** In `src/game/mission/miras_house_director.gd`:
  - Delete the two lines `## Where people died this step, judged once the crowd has judged its own doomed.` and `var _deaths: Array[Vector2] = []`.
  - In `step()`, replace `_judge_deaths()` with `gaze.judge_deaths(crowd)`.
  - Delete the whole `_judge_deaths()` function, with its `##` line.
  - In `_on_killed()`, replace `_deaths.append(e.ground_pos)` with `gaze.note_death(e.ground_pos)`.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`. `tests/test_miras_house.gd` passes unchanged.
- [ ] **Step 7: Check that Mira's House is unchanged.** Run `--scenario=miras --case=play`. Expected: the same two lines as Step 1.
- [ ] **Step 8: Commit.**

```bash
git add src/game/mission/gaze_meter.gd src/game/mission/miras_house_director.gd tests/test_gaze.gd
git commit -m "refactor: Halcyon's Gaze judges the seen deaths itself (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 2: The wayside shrine

**Files:**
- Create: `tests/test_shrine.gd`
- Modify: `src/environment/structure.gd:16-19, after line 37 (TORCH_LIGHT), 208-211, 813-837, 1066-1089`, `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `Structure.Kind.SHRINE`, last in the enum;
  - `Structure.SHRINE_HP := 40.0`, the shrine's `max_hp`;
  - `Structure.COL_NICHE`.
- `SpriteArt.name_for()` returns `""` for a shrine and `ArtKit.plan_for()` returns `{}`, both through their existing defaults. So the procedural box and its niche draw the shrine on both art paths, and no art file changes.
- `Town.collapse_cue()` gives `&"collapse_stone"`, through its existing default.

- [ ] **Step 1: Write the failing test.** Create `tests/test_shrine.gd`:

```gdscript
extends RefCounted
## v0.10 M3 the wayside shrine (Structure.Kind.SHRINE): a stone post with a lantern niche, Broken Lanterns' own. Its
## health, its fall, and its relighting (restore()). Drawn by the procedural art on either art path. Never part of the
## shared town.


static func run(t) -> void:
	var env := EnvironmentField.new()
	var s := env.add_structure(Rect2(0.0, 0.0, 0.4, 0.4), 22.0, Structure.Kind.SHRINE, &"shrine")
	var fell := [0]
	s.broken.connect(func(_b: Structure) -> void: fell[0] += 1)
	t.check(Structure.Kind.SHRINE == Structure.Kind.FOUNTAIN + 1, "the shrine kind comes last, after the fountain")
	t.check(s.max_hp == Structure.SHRINE_HP and s.hp == s.max_hp and not s.walkable,
		"a shrine stands at full health and blocks the way")
	t.check(SpriteArt.name_for(s) == "" and s.sprite.is_empty() and s.art.is_empty(),
		"no sprite and no art plan: the procedural post draws it on either art path")
	t.check(s.tuning_key() == "shrine" and Town.collapse_cue(s) == &"collapse_stone", "it falls with a stone crash")
	s.damage(Structure.SHRINE_HP - 1.0, s.center(), &"stone")
	t.check(not s.destroyed and fell[0] == 0, "a blow short of its health leaves it standing")
	s.damage(2.0, s.center(), &"stone")
	t.check(s.destroyed and fell[0] == 1, "the next breaks it")
	s.restore()
	t.check(not s.destroyed and s.hp == s.max_hp and s.scorch == 0.0, "relit, it stands again, whole")
	var shrines := 0
	for d in TownLayout.structures():
		shrines += 1 if d.kind == Structure.Kind.SHRINE else 0
	t.check(shrines == 0, "the shared town has no shrines: only Broken Lanterns places them")
	env.clear()
	env.free()
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `SHRINE`.

- [ ] **Step 3: The kind.** In `src/environment/structure.gd`:
  - Make the enum:

```gdscript
enum Kind {
	TOWER, BLOCK, WALL, CRATES, KEEP, CASTLE_WALL, HOUSE, TORCH,
	TEMPLE, BARRACKS, MARKET_STALL, GATE, BRIDGE, FARM_FIELD, TREE, FOUNTAIN,
	SHRINE,
}
```

  - Under `const TORCH_LIGHT := Color(1.0, 0.55, 0.22)`, add:

```gdscript
## The wayside shrine (v0.10 M3, Broken Lanterns). Its health is a stone post's: sturdier than a torch, under a house,
## and every Ruin power in the night's pool breaks it in one blow. COL_NICHE is its lantern niche's dark.
const SHRINE_HP := 40.0
const COL_NICHE := Color("1a1410")
```

  - In `setup()`'s `max_hp` dictionary, change the last entry `Kind.FOUNTAIN: 80.0}[k]` to `Kind.FOUNTAIN: 80.0, Kind.SHRINE: SHRINE_HP}[k]`.
  - In `_palette()`, before `_:`, add:

```gdscript
		Kind.SHRINE:
			return [Color("a49c90"), Color("8a8378"), Color("6e685f")]
```

  - In `_draw_kind_details()`'s `match kind:`, after the `Kind.CRATES:` branch, add:

```gdscript
		Kind.SHRINE:
			# A lantern niche in the front face, its flame lit while the shrine stands, under a capstone.
			var niche := (_s[3].lerp(_s[2], 0.5) + Vector2(0, -height * 0.62)).round()
			draw_rect(Rect2(niche + Vector2(-2, -4), Vector2(4, 5)), COL_NICHE)
			draw_rect(Rect2(niche + Vector2(-1, -3), Vector2(2, 3)), COL_FLAME[1])
			draw_rect(Rect2(niche + Vector2(-1, -2), Vector2(1, 1)), COL_FLAME[0])
			draw_rect(Rect2(roof + Vector2(-6, -2), Vector2(12, 2)), top_c.lightened(0.12))
```

  (`_draw()` already draws a kind outside `ART_KINDS` as a lit box, and `_draw_kind_details()` returns early for a destroyed structure, so the niche shows only while it stands.)

- [ ] **Step 4: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.
- [ ] **Step 5: Run Digest and crowd_check.** Expected: unchanged.
- [ ] **Step 6: Commit.**

```bash
git add src/environment/structure.gd tests/test_shrine.gd tests/test_shrine.gd.uid tests/run_all.gd
git commit -m "feat: the wayside shrine structure (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 3: The Lantern Knight

**Files:**
- Create: `tests/test_lantern_knight.gd`
- Modify: `src/game/crowd/person.gd:18,124,160-164,1707`, `src/environment/art/people_art.gd:25-27`, `src/game/crowd/crowd.gd` (after `_add_person()`, line 423), `tests/run_all.gd`

**Interfaces:**
- Produces:
  - `Person.Corps.KNIGHT`, last in the enum;
  - `Person.HEALTH_KNIGHT := HEALTH_SOLDIER * 3.0`;
  - `Person.SOL_KNIGHT`;
  - `Crowd.add_soldier(at: Vector2) -> Person`: a soldier at its post `at`, appended to `Crowd.soldiers`, with no corps;
  - `PeopleArt.SOLDIER` gains `"knight"`, and `PeopleArt.STAND_INS` gains `"knight": "escort"`.
- Facts the director relies on:
  - `Crowd.rally()` and the marshals take only `Corps.NONE`, and the escorts only `Corps.ESCORT`, so they leave a Knight alone.
  - `Crowd._investigate()` draws only from the patrols' index range, which a soldier appended after the spawn is past.

- [ ] **Step 1: Write the failing test.** Create `tests/test_lantern_knight.gd`:

```gdscript
extends RefCounted
## v0.10 M3 the Lantern Knight: a soldier come mid-mission (Crowd.add_soldier()), one of the town's soldiers from then
## on, given the KNIGHT corps. He has three times a soldier's health and a gold tabard, and wears the escort's sprite
## until his own is drawn. No other corps' work takes him: not the rally, the marshals or the escorts.


static func _crowd() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd}


static func _done(s: Dictionary) -> void:
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func run(t) -> void:
	var s := _crowd()
	var crowd: Crowd = s.crowd
	var before := crowd.soldiers.size()
	var at := crowd._grid.nearest_walkable(Vector2(1.0, 2.0))
	var k := crowd.add_soldier(at)
	t.check(crowd.soldiers.size() == before + 1 and crowd.soldiers.back() == k and k.soldier
		and k.mind == Person.Mind.POST and k.anchor == at and k.post == at and k.corps == Person.Corps.NONE
		and is_equal_approx(k.health, Person.HEALTH_SOLDIER), "a soldier come mid-mission joins the town's soldiers at its post")
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT
	t.check(Person.Corps.KNIGHT == Person.Corps.RESCUE + 1 and is_equal_approx(Person.HEALTH_KNIGHT, Person.HEALTH_SOLDIER * 3.0),
		"the Knight corps comes last, and a Knight has three times a soldier's health")
	var design := PeopleArt.design_for(true, 0, Person.Corps.KNIGHT, 0.5)
	t.check(PeopleArt.wanted(true, 0, Person.Corps.KNIGHT, 0.5) == "knight" and PeopleArt.has(design)
		and (PeopleArt.has("knight") or design == PeopleArt.STAND_INS["knight"]),
		"a Knight wants his own design and wears the escort's until it is drawn (%s)" % design)
	k.hurt(Person.HEALTH_SOLDIER, null)
	t.check(k.is_alive(), "he stands through blows that would fell a soldier")
	k.confuse(15.0)
	t.check(k.mind == Person.Mind.POST and not k.whisper(at + Vector2(3.0, 0.0), 8.0) and not k.lure(at, 6.0),
		"the quiet powers do not hold him")
	crowd.rally()
	t.check(k.mind == Person.Mind.POST and k.anchor == at, "the town's rally leaves a Knight at his post")
	_done(s)
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `add_soldier` or `KNIGHT`.

- [ ] **Step 3: The corps.** In `src/game/crowd/person.gd`:
  - Change the comment above `enum Corps` to end "…escort for a responder, or rescue squad; v0.10 M3's Lantern Knight, Broken Lanterns' shrine guard." and make the enum `enum Corps { NONE, MARSHAL, ESCORT, RESCUE, KNIGHT }`.
  - Under `const HEALTH_SOLDIER := 2.0`, add:

```gdscript
## A Lantern Knight's (v0.10 M3): three times a soldier's.
const HEALTH_KNIGHT := HEALTH_SOLDIER * 3.0
```

  - Under `const SOL_SHOVEL := Color("8a8e96")`, add:

```gdscript
## A Lantern Knight's gold tabard (v0.10 M3).
const SOL_KNIGHT := Color("e0b84a")
```

  - In `_draw_soldier()`, replace the line `var tabard := SOL_MARSHAL if corps == Corps.MARSHAL else (SOL_ESCORT if corps == Corps.ESCORT else SOL_TABARD)` with:

```gdscript
	var tabard := SOL_MARSHAL if corps == Corps.MARSHAL else (SOL_ESCORT if corps == Corps.ESCORT
		else (SOL_KNIGHT if corps == Corps.KNIGHT else SOL_TABARD))
```

- [ ] **Step 4: The look on the sprite path.** In `src/environment/art/people_art.gd`:
  - Make `STAND_INS` `{"watchman": "bellkeeper", "mayor": "merchant_a", "noble": "resident_a", "knight": "escort"}`.
  - Add to its comment: "…and the Lantern Knight (v0.10 M3) an escort's white tabard until M5's PixelLab pass."
  - Make `SOLDIER` `["guard", "marshal", "escort", "rescue", "knight"]`.

- [ ] **Step 5: A soldier come mid-mission.** In `src/game/crowd/crowd.gd`, after `_add_person()`, add:

```gdscript
## A soldier come mid-mission (v0.10 M3: Broken Lanterns' Lantern Knights), standing at `at` as its post: one of the
## town's soldiers from now on, after those spawned, with no corps until its caller gives it one.
func add_soldier(at: Vector2) -> Person:
	var p := _add_person(true, at)
	p.post = at
	soldiers.append(p)
	return p
```

- [ ] **Step 6: Run the tests to verify they pass.** Expected: `checks=N failures=0`. `tests/test_people_art.gd`'s loop over every corps now covers `KNIGHT` too, and passes through the stand-in.
- [ ] **Step 7: Run Digest and crowd_check.** Expected: unchanged.
- [ ] **Step 8: Commit.**

```bash
git add src/game/crowd/person.gd src/environment/art/people_art.gd src/game/crowd/crowd.gd tests/test_lantern_knight.gd tests/test_lantern_knight.gd.uid tests/run_all.gd
git commit -m "feat: the Lantern Knight, a soldier come mid-mission (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 4: The Vigil loops, turns aside and passes the flame

**Files:**
- Modify: `src/game/mission/vigil_route.gd` (whole file below), `tests/test_vigil_route.gd`

**Interfaces:**
- Consumes: `Person.go_duty()`, `Person.Mind`.
- Produces, on `VigilRoute`. All three switches are off by default, and with them off the walk is exactly M2's:
  - `signal flame_passed(to: Person)`;
  - `var loop := false`;
  - `var pass_flame := false`;
  - `var detour := Vector2.INF`;
  - `func goal() -> Vector2`;
  - `func divert(at: Vector2)`, where `Vector2.INF` sends the bearer back to the route.

- [ ] **Step 1: Write the failing test.** In `tests/test_vigil_route.gd`:
  - Add these helpers above `run()`:

```gdscript
static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## One look at the walk (VigilRoute.TICK), stepped at DT.
static func _tick(v: VigilRoute) -> void:
	for i in roundi(VigilRoute.TICK / DT) + 1:
		v.step(DT)
```

  - In `run()`, insert just before the final `_done(s)`:

```gdscript
	# v0.10 M3, for Broken Lanterns: round again, turned aside, the flame passed on.
	var b4: Person = crowd.citizens[14]
	var first: Person = crowd.citizens[16]
	var second: Person = crowd.citizens[18]
	var a4: Array[Person] = [first, second]
	var v4 := VigilRoute.new().setup(points, b4, a4)
	v4.loop = true
	v4.pass_flame = true
	var passed: Array[Person] = []
	v4.flame_passed.connect(func(p: Person) -> void: passed.append(p))
	v4.start()
	for pt in points:
		_arrive(b4, pt)
		_tick(v4)
	t.check(v4.active and not v4.finished and v4.leg == 0 and b4.anchor.distance_to(points[0]) < 0.01,
		"a looping Vigil goes round again from the first point")
	var aside := grid.nearest_walkable(points[0] + Vector2(0.0, 3.0))
	v4.divert(aside)
	t.check(v4.detour == aside and v4.goal() == aside and b4.anchor.distance_to(aside) < 0.01,
		"turned aside, the bearer makes for the place at once")
	_arrive(b4, aside)
	_tick(v4)
	t.check(v4.detour == Vector2.INF and v4.leg == 0 and b4.anchor.distance_to(points[0]) < 0.01,
		"there, he takes the route up where he left it")
	v4.divert(aside)
	v4.divert(Vector2.INF)
	t.check(v4.detour == Vector2.INF and b4.anchor.distance_to(points[0]) < 0.01, "a detour called off sends him back to the route")
	crowd._field.kill(b4, &"doom")
	_tick(v4)
	t.check(v4.active and v4.bearer == first and passed.size() == 1 and passed[0] == first
		and first.mind == Person.Mind.DUTY and first.anchor.distance_to(v4.goal()) < 0.01,
		"a dead bearer's flame passes to the first living acolyte, who walks on")
	crowd._field.kill(first, &"doom")
	_tick(v4)
	t.check(v4.active and v4.bearer == second and passed.size() == 2, "and on again when that one falls")
	crowd._field.kill(second, &"doom")
	_tick(v4)
	t.check(v4.finished and v4.walkers().is_empty(), "with all three dead the Vigil is over")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `loop` or `divert`.

- [ ] **Step 3: Write the new `VigilRoute`.** Replace `src/game/mission/vigil_route.gd` with:

```gdscript
class_name VigilRoute
extends RefCounted
## The Vigil (v0.10, spec §4.1): a priest, the flame-bearer, walks a route point by point, two acolytes keeping beside
## him. A fright stops him; once on his feet again he takes the route up where he left it. At the last point the walk is
## over and all three go back to their day; a dead bearer ends it at once. Mira's House walks it past her door.
## Broken Lanterns (M3) walks it round Halcyon's six wayside shrines and asks three things more, each off unless set:
## the walk goes round again from the first point (`loop`); the bearer turns aside to one place, then takes the route up
## where he left it (divert()); and a dead bearer's flame passes to the first living acolyte (`pass_flame`), so only all
## three dead end the walk.

## The flame passed to `to` (pass_flame).
signal flame_passed(to: Person)

## How near a point counts as reached, and seconds between looks at the walk.
const ARRIVE := 0.6
const TICK := 0.5
## Where each acolyte keeps beside the bearer (ground units), and how far off their place they may drift.
const ACOLYTE_OFFSETS := [Vector2(-0.7, 0.4), Vector2(0.7, 0.4)]
const ACOLYTE_DRIFT := 0.5
## Minds the bearer takes the route up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]

var bearer: Person
var acolytes: Array[Person] = []
var route := PackedVector2Array()
var leg := 0
var active := false
var finished := false
## func(p: Person) -> bool: a walker busy elsewhere (v0.10: carrying a report to the Temple), not to be pulled back.
var busy: Callable
## Round again from the first point after the last (v0.10 M3), rather than finishing.
var loop := false
## A dead bearer's flame passes to the first living acolyte (v0.10 M3), rather than ending the walk.
var pass_flame := false
## Where the bearer has turned aside to (divert()), or Vector2.INF while he walks the route.
var detour := Vector2.INF
var _tick := 0.0


func setup(points: PackedVector2Array, bearer_p: Person, acolyte_ps: Array[Person]) -> VigilRoute:
	route = points
	bearer = bearer_p
	acolytes = acolyte_ps
	return self


func start() -> void:
	if route.is_empty() or not _alive(bearer):
		finish()
		return
	active = true
	leg = 0
	_tick = TICK
	bearer.go_duty(route[0])
	_keep_acolytes()


## The living bearer and acolytes.
func walkers() -> Array[Person]:
	var out: Array[Person] = []
	for p in [bearer] + acolytes:
		if _alive(p):
			out.append(p)
	return out


## Where the bearer is walking now: his detour, else the route's next point.
func goal() -> Vector2:
	return detour if detour != Vector2.INF else route[leg]


## Turn the bearer aside to `at` (Vector2.INF: back to the route). On his way he makes for it at once; once there he
## takes the route up where he left it.
func divert(at: Vector2) -> void:
	detour = at
	if not active or not _alive(bearer) or bearer.mind != Person.Mind.DUTY:
		return
	if busy.is_valid() and bool(busy.call(bearer)):
		return
	bearer.go_duty(goal())


func step(delta: float) -> void:
	if not active:
		return
	if not _alive(bearer) and not _take_flame():
		finish()
		return
	if busy.is_valid() and bool(busy.call(bearer)):
		return  # carrying a report: the walk waits for him
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if bearer.mind != Person.Mind.DUTY:
		if bearer.mind in RESUMABLE:
			bearer.go_duty(goal())
		return
	var at := goal()
	if bearer.ground_pos.distance_to(at) <= ARRIVE or not bearer.has_goal():
		if bearer.ground_pos.distance_to(at) <= ARRIVE:
			if detour != Vector2.INF:
				detour = Vector2.INF
			else:
				leg += 1
				if leg >= route.size():
					if not loop:
						finish()
						return
					leg = 0
		bearer.go_duty(goal())
	_keep_acolytes()


## The walk is over: everyone still on it goes back to their day.
func finish() -> void:
	active = false
	finished = true
	for p in walkers():
		if p.mind == Person.Mind.DUTY:
			p.leave_shelter(false)


## The bearer is dead: with pass_flame, the first living acolyte takes the flame up and walks on (at once, if on his
## feet); false when nobody can.
func _take_flame() -> bool:
	if not pass_flame:
		return false
	for a in acolytes:
		if not _alive(a):
			continue
		bearer = a
		acolytes.erase(a)
		_tick = 0.0
		if a.mind == Person.Mind.DUTY or a.mind in RESUMABLE:
			a.go_duty(goal())
		flame_passed.emit(a)
		return true
	return false


func _keep_acolytes() -> void:
	for i in acolytes.size():
		var a := acolytes[i]
		if not _alive(a) or not (a.mind == Person.Mind.DUTY or a.mind in RESUMABLE):
			continue
		if busy.is_valid() and bool(busy.call(a)):
			continue
		var place := bearer.ground_pos + (ACOLYTE_OFFSETS[i % ACOLYTE_OFFSETS.size()] as Vector2)
		if a.mind != Person.Mind.DUTY or a.anchor.distance_to(place) > ACOLYTE_DRIFT:
			a.go_duty(place)


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
```

  (With the switches off: `goal()` is `route[leg]` and `_take_flame()` is false, so `start()`, `step()` and `finish()` act exactly as M2's.)

- [ ] **Step 4: Run the tests to verify they pass.** Expected: `checks=N failures=0`. M2's checks in the same file pass unchanged.
- [ ] **Step 5: Check that Mira's House is unchanged.** Run `--scenario=miras --case=play`. Expected: the same two lines as Task 1 Step 1.
- [ ] **Step 6: Commit.**

```bash
git add src/game/mission/vigil_route.gd tests/test_vigil_route.gd
git commit -m "feat: the Vigil loops, turns aside and passes the flame (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 5: Broken Lanterns — the shrines, the drain and the flame

**Files:**
- Create: `src/game/mission/broken_lanterns_director.gd`, `src/game/mission/shrines_objective.gd`, `tests/test_broken_lanterns.gd`
- Modify: `src/game/mission/mission_book.gd` (`miras_house()`'s comment, `broken_lanterns()`), `src/game/ui/results_screen.gd:39-41`, `tests/test_mission_book.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes:
  - `Structure.Kind.SHRINE` and `Structure.damage_filter` (Task 2);
  - `VigilRoute.loop`, `pass_flame`, `divert()`, `detour`, `flame_passed` (Task 4);
  - `GazeMeter.note_death()` / `judge_deaths()` (Task 1);
  - `EnvironmentField.add_structure()`, `Structure.restore()`, `Town._built`, `Crowd._env`, `Crowd._grid`, `Crowd._field`.
- Produces, on `BrokenLanternsDirector extends MissionDirector`:
  - constants `SHRINE_SPOTS`, `SHRINE_SIZE`, `SHRINE_H`, `ROLE`, `RELIGHT_OFF`, `RELIGHT_REACH`, `DRAIN_SECONDS`, `FAITHFUL`, `CAMERA_AT`, `MARK_LIT`, `MARK_DRAINING`;
  - vars `shrines: Array[Structure]`, `faithful: Array[Person]`, `vigil: VigilRoute`, `temple_door: Vector2`, `drain_left: Dictionary` (Structure -> float), `drained: Dictionary` (Structure -> true), `relit: int`;
  - funcs `relight_point(s) -> Vector2`, `draining(s) -> bool`, `is_drained(s) -> bool`, `drained_count() -> int`, `standing_shrines() -> Array[Structure]`, `guarded(s) -> bool` (false until Task 6), `marks()`, `marker()`, `report()` (`{"drained", "relit"}`);
  - Task 6's hooks, empty here: `_add_events()`, `_prayers_step(delta)`, `_broke(s)`, `_relit(s)`, `_drained_one(s)`.
- Also produced:
  - `ShrinesObjective`: label `"Shrines drained"`, reason `"drained"`, `hud_text` `"Shrines drained 2 / 6"`;
  - `MissionBook.broken_lanterns()`: the real mission;
  - `ResultsScreen.ACT_TITLES` gains `"drained": "THE LANTERNS ARE DARK"` and `"relit": "THE LANTERNS BURN ON"`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_broken_lanterns.gd`:

```gdscript
extends RefCounted
## v0.10 M3 Broken Lanterns (BrokenLanternsDirector). Six wayside shrines stand on the Vigil's route. A broken shrine
## drains after 20 s, unless the flame-bearer reaches it first and relights it. All six drained win; the bell, a full
## Gaze or dawn lose. Task 6 adds the Faithful praying at the standing shrines, the Lantern Knights at 1:30, the
## kneelers at the last shrine, and the bonus.

const DT := 0.05
## Somewhere far from every shrine, where the tests park the Vigil so the flame relights nothing it is not meant to.
const AWAY := Vector2(14.0, -14.0)


static func _setup() -> Dictionary:
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = ResponseProfile.unaware()
	crowd.spawn()
	# The town's alarm hushed: shrines falling in a test never call the bellkeeper (the bell's own case sets it rung).
	crowd.hush(9999.0)
	var def := MissionBook.broken_lanterns()
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null) as BrokenLanternsDirector
	rules.director = director
	var banners: Array[String] = []
	rules.banner.connect(func(text: String) -> void: banners.append(text))
	return {"env": env, "town": town, "grid": grid, "field": field, "world": world, "crowd": crowd, "rules": rules,
		"d": director, "banners": banners}


static func _done(s: Dictionary) -> void:
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


static func _run(s: Dictionary, seconds: float) -> void:
	for i in roundi(seconds / DT):
		(s.crowd as Crowd).advance(DT)
		(s.rules as Rules).advance(DT)


static func _arrive(p: Person, at: Vector2) -> void:
	p.ground_pos = at
	p._goal = Vector2.INF
	p._path = PackedVector2Array()


## The Vigil's walkers parked far from every shrine.
static func _away(d: BrokenLanternsDirector) -> void:
	var i := 0
	for p in d.vigil.walkers():
		_arrive(p, AWAY + Vector2(float(i), 0.0))
		i += 1


## A blow no shrine stands through, unless a Knight guards it.
static func _break(sh: Structure) -> void:
	sh.damage(9999.0, sh.center(), &"stone")


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()


static func run(t) -> void:
	_cast(t)
	_drain(t)
	_relight(t)
	_ending(t)


static func _cast(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var town: Town = s.town
	var grid: WalkGrid = s.grid
	var placed := d.shrines.size() == BrokenLanternsDirector.SHRINE_SPOTS.size()
	for i in d.shrines.size():
		var sh := d.shrines[i]
		placed = placed and sh.kind == Structure.Kind.SHRINE and sh.role == BrokenLanternsDirector.ROLE and not sh.destroyed \
			and town._built.has(sh) and sh.damage_filter.is_valid() \
			and sh.center().distance_to(BrokenLanternsDirector.SHRINE_SPOTS[i]) < 2.0
	t.check(placed, "six wayside shrines stand on the Vigil's route, the town's to take away")
	t.check(not Rules.BUILDING_ROLES.has(BrokenLanternsDirector.ROLE), "a shrine is not a building for the tally or the score")
	var reach := true
	for sh in d.shrines:
		reach = reach and grid.walkable(d.relight_point(sh)) and not grid.path(d.temple_door, d.relight_point(sh)).is_empty()
	t.check(reach, "the bearer can walk from the Temple to every shrine's side")
	var faithful_ok := d.faithful.size() >= BrokenLanternsDirector.FAITHFUL
	for f in d.faithful:
		faithful_ok = faithful_ok and f.profile.faith == CitizenProfile.Faith.FAITHFUL
	t.check(faithful_ok, "the Faithful chosen (%d)" % d.faithful.size())
	t.check(d.vigil != null and d.vigil.active and d.vigil.loop and d.vigil.pass_flame and d.vigil.walkers().size() == 3
		and d.vigil.route.size() == d.shrines.size() and d.faithful.has(d.vigil.bearer),
		"the Vigil sets out round the six shrines, looping, the flame passing on")
	t.check(d.gaze != null and d.gaze.value == 0.0 and d.drain_left.is_empty() and d.drained_count() == 0,
		"the Gaze at 0, nothing broken")
	var lit := d.marks().size() == 6
	for m: Array in d.marks():
		lit = lit and (m[1] as Color) == BrokenLanternsDirector.MARK_LIT
	t.check(lit, "the HUD marks the six standing shrines")
	t.check(d.marker() == Vector2.INF and d.timeline != null, "no arrow yet, and a timeline for the night's windows")
	_done(s)


static func _drain(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var rules: Rules = s.rules
	_away(d)
	var sh := d.shrines[0]
	_break(sh)
	t.check(sh.destroyed and d.draining(sh) and not d.is_drained(sh), "a broken shrine starts draining")
	t.check(rules.buildings_down == 0, "and is not counted as a building")
	var ember := false
	for m: Array in d.marks():
		ember = ember or ((m[0] as Vector2) == sh.center() and (m[1] as Color) == BrokenLanternsDirector.MARK_DRAINING)
	t.check(ember, "the HUD marks it draining")
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 1.0)
	t.check(d.draining(sh) and d.drained_count() == 0, "still draining after 19 s")
	_run(s, 1.5)
	t.check(d.is_drained(sh) and d.drained_count() == 1 and not d.draining(sh), "drained after 20 s broken")
	t.check(ShrinesObjective.new().hud_text(rules) == "Shrines drained 1 / 6" and (s.banners as Array).has("A LANTERN IS DRAINED (1 / 6)"),
		"the objective and a banner count it")
	_arrive(d.vigil.bearer, d.relight_point(sh))
	_run(s, DT * 2.0)
	t.check(sh.destroyed and d.relit == 0, "the flame cannot relight a drained shrine")
	_done(s)


## Relighting, a shrine broken twice (review focus 4), and the flame passing on until nobody is left (review focus 1).
static func _relight(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var banners: Array[String] = s.banners
	_away(d)
	var sh := d.shrines[1]
	_break(sh)
	t.check(d.vigil.detour.distance_to(d.relight_point(sh)) < 0.01 and d.marker() == d.vigil.bearer.ground_pos,
		"the flame-bearer turns aside for the broken shrine, and the HUD points at him")
	_arrive(d.vigil.bearer, d.relight_point(sh))
	_run(s, DT * 2.0)
	t.check(not sh.destroyed and sh.hp == sh.max_hp and not d.draining(sh) and d.relit == 1
		and banners.has("THE FLAME RELIGHTS A LANTERN"), "reaching it before it drains, he relights it: it stands again")
	t.check(d.vigil.detour == Vector2.INF and d.marker() == Vector2.INF and d.standing_shrines().has(sh),
		"he goes back to his round; the relit shrine stands")
	_away(d)
	_run(s, 5.0)
	_break(sh)
	t.check(d.draining(sh) and is_equal_approx(float(d.drain_left[sh]), BrokenLanternsDirector.DRAIN_SECONDS),
		"broken again, it drains from the start")
	var first: Person = d.vigil.bearer
	var acolyte: Person = d.vigil.acolytes[0]
	(s.crowd as Crowd)._field.kill(first, &"doom")
	_run(s, VigilRoute.TICK + DT)
	t.check(d.vigil.active and d.vigil.bearer == acolyte and banners.has("AN ACOLYTE TAKES UP THE FLAME"),
		"the bearer killed, an acolyte takes up the flame")
	for p in d.vigil.walkers():
		(s.crowd as Crowd)._field.kill(p, &"doom")
	_run(s, VigilRoute.TICK * 3.0)
	t.check(not d.vigil.active and d.marker() == Vector2.INF, "with all three dead the Vigil is over")
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS)
	t.check(d.is_drained(sh), "and nobody relights the shrine")
	_done(s)


static func _ending(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var rules: Rules = s.rules
	_away(d)
	for sh in d.shrines:
		_break(sh)
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
	t.check(rules.finished and rules.won and rules.over_reason == "drained" and d.drained_count() == 6,
		"six drained win the night (%s)" % rules.over_reason)
	t.check(int(rules.result().get("drained", -1)) == 6 and ResultsScreen.title_for(true, "drained") == "THE LANTERNS ARE DARK",
		"the results report the shrines, under their title")
	_done(s)

	var s2 := _setup()
	var crowd2: Crowd = s2.crowd
	if crowd2.bell != null:
		crowd2.bell.state = BellNetwork.State.RUNG
	_run(s2, DT * 2.0)
	t.check(crowd2.bell == null or ((s2.rules as Rules).finished and (s2.rules as Rules).over_reason == "bell"
		and (s2.d as BrokenLanternsDirector).gaze.is_full()), "the bell loses the night, and fills the Gaze")
	_done(s2)

	var s3 := _setup()
	(s3.d as BrokenLanternsDirector).gaze.fill()
	_run(s3, DT)
	t.check((s3.rules as Rules).finished and (s3.rules as Rules).over_reason == "gaze", "a full Gaze loses it")
	_done(s3)

	var s4 := _setup()
	(s4.rules as Rules).time_left = DT
	_run(s4, DT * 2.0)
	t.check((s4.rules as Rules).finished and not (s4.rules as Rules).won and (s4.rules as Rules).over_reason == "relit"
		and ResultsScreen.title_for(false, "relit") == "THE LANTERNS BURN ON", "dawn with a shrine still lit loses it")
	_done(s4)

	var s5 := _setup()
	var d5: BrokenLanternsDirector = s5.d
	var victim := d5.faithful[5]
	d5.faithful[6].ground_pos = victim.ground_pos + Vector2(1.0, 0.0)
	(s5.crowd as Crowd)._field.kill(victim, &"doom")
	_run(s5, DT * 3.0)
	t.near(d5.gaze.value, GazeMeter.SEEN_DEATH, 0.001, "a seen death adds 10 to the Gaze")
	_done(s5)
```

Register it at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `BrokenLanternsDirector`.

- [ ] **Step 3: Write `ShrinesObjective`.** Create `src/game/mission/shrines_objective.gd`:

```gdscript
class_name ShrinesObjective
extends Objective
## Broken Lanterns (v0.10): every one of Halcyon's shrines drained wins the night ("drained").


func _init() -> void:
	label = "Shrines drained"
	reason = "drained"


func check(rules: Rules) -> Status:
	var d := rules.director as BrokenLanternsDirector
	if d == null or d.shrines.is_empty():
		return Status.PENDING
	return Status.DONE if d.drained_count() >= d.shrines.size() else Status.PENDING


func hud_text(rules: Rules) -> String:
	var d := rules.director as BrokenLanternsDirector
	return "Shrines drained %d / %d" % [d.drained_count() if d != null else 0, d.shrines.size() if d != null else 6]
```

- [ ] **Step 4: Write the director.** Create `src/game/mission/broken_lanterns_director.gd`:

```gdscript
class_name BrokenLanternsDirector
extends MissionDirector
## Broken Lanterns (v0.10 M3, the Ruin path's Night 2): Halcyon's six wayside shrines anchor his protection over the
## town. Break them before the Vigil relights them, and drink what was in them. A broken shrine is drained once it has
## stayed broken DRAIN_SECONDS. The flame-bearer walks the Vigil round the six, turns aside for a broken shrine, and
## relights it if he reaches it first (it stands again). A drained shrine is gone for good. All six drained win the
## night. A death someone sees adds to Halcyon's Gaze, and the bell fills it. Task 6 adds the Faithful's prayer at the
## standing shrines, the Lantern Knights at 1:30 and the kneelers at the last shrine. The shrines are this mission's
## own: placed here, never in the shared town layout, and taken away with the town (Town._built).

## Where the six shrines stand, in the Vigil's order (ground units; each is moved to the nearest open ground). Each
## stands well beyond GUARD_REACH of the Temple's door, where the Knights come out, so no Knight guards one by
## standing there.
const SHRINE_SPOTS := [Vector2(5.5, -4.8), Vector2(10.2, -8.8), Vector2(12.0, 9.2), Vector2(0.5, 13.0),
	Vector2(-7.0, 10.0), Vector2(-7.5, -4.0)]
## A shrine's footprint and height (a stone post, Structure.Kind.SHRINE), and its role. The role is not one of
## Rules.BUILDING_ROLES, so a shrine is never a building in the tally, the chain or the score.
const SHRINE_SIZE := Vector2(0.4, 0.4)
const SHRINE_H := 22.0
const ROLE := &"shrine"
## Where the bearer stands to relight a shrine (from its centre), and how near its footprint he must be.
const RELIGHT_OFF := Vector2(0.0, 0.7)
const RELIGHT_REACH := 1.2
## A broken shrine is drained once it has stayed broken this long.
const DRAIN_SECONDS := 20.0
## How many Faithful there are besides the clergy (spec §4.1: about 20 devout citizens).
const FAITHFUL := 20
## Where the camera opens: the market, between the shrines.
const CAMERA_AT := Vector2(1.0, 2.0)
## The marks over the shrines: standing (Halcyon's gold), and broken but not yet drained (ember).
const MARK_LIT := Color(0.95, 0.82, 0.42, 0.9)
const MARK_DRAINING := Color("ff9a3a")

var shrines: Array[Structure] = []
var faithful: Array[Person] = []
var vigil: VigilRoute
var temple_door := Vector2.INF
## Broken shrines not yet drained -> seconds left before they are.
var drain_left := {}
## Drained shrines (-> true): gone for good.
var drained := {}
## How many times the flame has relit a shrine.
var relit := 0
## Shrine -> where the bearer stands to relight it.
var _relight_at := {}


func _begin() -> void:
	gaze = GazeMeter.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	_place_shrines()
	_choose_faithful()
	_start_vigil()
	crowd._field.enemy_killed.connect(_on_killed)
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	_add_events()
	rules.banner.emit("BREAK THE SIX LANTERNS")


func _place_shrines() -> void:
	for spot: Vector2 in SHRINE_SPOTS:
		var at := _walkable(spot)
		var s := crowd._env.add_structure(Rect2(at - SHRINE_SIZE * 0.5, SHRINE_SIZE), SHRINE_H, Structure.Kind.SHRINE, ROLE)
		s.damage_filter = _shield
		s.broken.connect(_on_broken)
		town._built.append(s)  # the town takes it away with its own buildings (Town.teardown())
		shrines.append(s)
		_relight_at[s] = _walkable(at + RELIGHT_OFF)


func _walkable(g: Vector2) -> Vector2:
	var w := crowd._grid.nearest_walkable(g) if crowd._grid != null else g
	return w if w != Vector2.INF else g


## The clergy, and FAITHFUL lay citizens spread through the rest, are Halcyon's Faithful.
func _choose_faithful() -> void:
	var keeper: Person = crowd.bell.keeper if crowd.bell != null else null
	var lay: Array[Person] = []
	for p in crowd.citizens:
		if not _alive(p) or p.profile == null or p.inside or p == keeper:
			continue
		if p.profile.role == CitizenProfile.Role.CLERGY:
			_make_faithful(p)
		elif not p.profile.role in [CitizenProfile.Role.ENGINEER, CitizenProfile.Role.BELLKEEPER]:
			lay.append(p)
	if lay.is_empty():
		return
	var stride := maxi(1, lay.size() / FAITHFUL)
	var i := stride / 2
	var added := 0
	while i < lay.size() and added < FAITHFUL:
		_make_faithful(lay[i])
		added += 1
		i += stride


func _make_faithful(p: Person) -> void:
	p.profile.faith = CitizenProfile.Faith.FAITHFUL
	faithful.append(p)


## The flame-bearer and his two acolytes are the clergy nearest the Temple's door (else any Faithful). They walk the six
## shrines round and round from the first, turning aside for broken ones, the flame passing on if the bearer falls.
func _start_vigil() -> void:
	var pool: Array[Person] = faithful.duplicate()
	pool.sort_custom(func(a: Person, b: Person) -> bool:
		var ca := a.profile.role == CitizenProfile.Role.CLERGY
		var cb := b.profile.role == CitizenProfile.Role.CLERGY
		if ca != cb:
			return ca
		return a.ground_pos.distance_to(temple_door) < b.ground_pos.distance_to(temple_door))
	if pool.is_empty():
		return
	var route := PackedVector2Array()
	for s in shrines:
		route.append(relight_point(s))
	var acolytes: Array[Person] = []
	acolytes.assign(pool.slice(1, 3))
	vigil = VigilRoute.new().setup(route, pool[0], acolytes)
	vigil.loop = true
	vigil.pass_flame = true
	vigil.flame_passed.connect(func(_to: Person) -> void:
		rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME")
		_sync_detour())
	vigil.start()


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	if vigil != null:
		vigil.step(delta)
	_drain(delta)
	_relight()
	_prayers_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


## A shrine broke: it drains from the start (a relit shrine broken again starts over).
func _on_broken(s: Structure) -> void:
	if drained.has(s):
		return
	drain_left[s] = DRAIN_SECONDS
	rules.banner.emit("A LANTERN BREAKS")
	_broke(s)
	_sync_detour()


func _drain(delta: float) -> void:
	for s: Structure in drain_left.keys():
		drain_left[s] = float(drain_left[s]) - delta
		if float(drain_left[s]) > 0.0:
			continue
		drain_left.erase(s)
		drained[s] = true
		rules.banner.emit("A LANTERN IS DRAINED (%d / %d)" % [drained.size(), shrines.size()])
		_drained_one(s)
		_sync_detour()


## The flame-bearer at a broken shrine not yet drained relights it: it stands again, whole.
func _relight() -> void:
	if vigil == null or not vigil.active or not _alive(vigil.bearer):
		return
	for s: Structure in drain_left.keys():
		if s.distance_to(vigil.bearer.ground_pos) > RELIGHT_REACH:
			continue
		drain_left.erase(s)
		s.restore()
		relit += 1
		rules.banner.emit("THE FLAME RELIGHTS A LANTERN")
		_relit(s)
		_sync_detour()


## The bearer turns aside for the nearest broken shrine not yet drained, or goes back to his round when there is none.
func _sync_detour() -> void:
	if vigil == null or not vigil.active:
		return
	var from := vigil.bearer.ground_pos if _alive(vigil.bearer) else temple_door
	var best := Vector2.INF
	for s: Structure in drain_left.keys():
		var p := relight_point(s)
		if best == Vector2.INF or from.distance_to(p) < from.distance_to(best):
			best = p
	if best != vigil.detour:
		vigil.divert(best)


## Structure.damage_filter for every shrine: a guarded shrine (Task 6: a Lantern Knight beside it) only shakes; any
## other takes the blow as a structure does, cracking and then breaking.
func _shield(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	if guarded(s):
		s.shake(2.5)
		return
	s.hp -= amount
	s.mark_hit(amount / s.max_hp, kind)
	if s.hp <= 0.0:
		s.destroy(source, kind)
	elif s.hp < s.max_hp * Structure.CRACK_AT:
		s.crack()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)


func relight_point(s: Structure) -> Vector2:
	var p: Vector2 = _relight_at.get(s, s.center())
	return p


func draining(s: Structure) -> bool:
	return drain_left.has(s)


func is_drained(s: Structure) -> bool:
	return drained.has(s)


func drained_count() -> int:
	return drained.size()


func standing_shrines() -> Array[Structure]:
	var out: Array[Structure] = []
	for s in shrines:
		if not s.destroyed:
			out.append(s)
	return out


func marks() -> Array:
	var out := []
	for s in shrines:
		if not s.destroyed:
			out.append([s.center(), MARK_LIT])
		elif drain_left.has(s):
			out.append([s.center(), MARK_DRAINING])
	return out


## The HUD's arrow: the flame-bearer, while he is on his way to relight a shrine.
func marker() -> Vector2:
	if vigil == null or not vigil.active or vigil.detour == Vector2.INF or not _alive(vigil.bearer):
		return Vector2.INF
	return vigil.bearer.ground_pos


func report() -> Dictionary:
	return {"drained": drained.size(), "relit": relit}


func teardown() -> void:
	if is_instance_valid(crowd) and crowd._field != null and crowd._field.enemy_killed.is_connected(_on_killed):
		crowd._field.enemy_killed.disconnect(_on_killed)
	for s in shrines:
		if is_instance_valid(s) and s.broken.is_connected(_on_broken):
			s.broken.disconnect(_on_broken)
	vigil = null
	timeline = null


## Task 6 fills these in: the Lantern Knights' event; prayer and the Knights, each step; a shrine broken, relit or
## drained; and the Knights' guard.
func _add_events() -> void:
	pass


func _prayers_step(_delta: float) -> void:
	pass


func _broke(_s: Structure) -> void:
	pass


func _relit(_s: Structure) -> void:
	pass


func _drained_one(_s: Structure) -> void:
	pass


func guarded(_s: Structure) -> bool:
	return false


static func _alive(p: Variant) -> bool:
	return is_instance_valid(p) and (p as Person).is_alive()
```

- [ ] **Step 5: The mission.** In `src/game/mission/mission_book.gd`:
  - In `miras_house()`'s doc comment, replace "the Vigil Flame and Broken Lanterns are still M1's placeholders held until dawn, with the spec's briefs and pools, until M4 and M3 build them." with "Broken Lanterns (the Ruin path) is M3's; the Vigil Flame is still M1's placeholder held until dawn, with the spec's brief and pool, until M4 builds it."
  - Replace `broken_lanterns()` with:

```gdscript
## Night 2 of the campaign, the Ruin path (v0.10 M3): break Halcyon's six wayside shrines and let them drain before the
## Vigil relights them (BrokenLanternsDirector). The default loadout costs 5 DP, so it fits a Night 2 after a bite.
static func broken_lanterns() -> MissionDef:
	var m := _vigil(BROKEN_LANTERNS, "Broken Lanterns", PackedStringArray(["Six shrines anchor the Lantern.",
		"Break them before they are relit."]), PackedStringArray(VIGIL_POOL + RUIN_POOL))
	m.goal = "Break Halcyon's six shrines, and let them drain before the Vigil relights them"
	m.goal_label = "The lanterns are dark"
	m.lose = "The bell tolls, the Lantern looks, or dawn finds a shrine still lit"
	m.clock = 180.0
	m.camera_at = BrokenLanternsDirector.CAMERA_AT
	m.intro_from = BrokenLanternsDirector.CAMERA_AT + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["heaven", "doom", "discord"])
	m.director = BrokenLanternsDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [ShrinesObjective.new(), BellSilentObjective.new(), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "relit")]
		return out
	return m
```

- [ ] **Step 6: The titles.** In `src/game/ui/results_screen.gd`, add `"drained": "THE LANTERNS ARE DARK", "relit": "THE LANTERNS BURN ON"` to `ACT_TITLES`.

- [ ] **Step 7: The mission book's test.** In `tests/test_mission_book.gd`, after the `"Broken Lanterns adds four Ruin powers, not Nova"` check, add:

```gdscript
	var bl_reasons := []
	for o in bl.objectives():
		bl_reasons.append(o.reason)
	var bl_dp := 0
	for key in bl.default_loadout:
		bl_dp += int(PowerBook.get_power(key).dp)
	t.check(bl.tier == 2 and bl.profile == "unaware" and not bl.scored and bl.director == BrokenLanternsDirector
		and bl_reasons == ["drained", "bell", "gaze", "relit"] and is_equal_approx(bl.clock, 180.0),
		"Broken Lanterns is Tier 2, Unaware, on 3:00: won by six drained, lost to the bell, the Gaze or dawn (%s)" % [bl_reasons])
	t.check(bl_dp <= 5 and Array(bl.default_loadout).all(func(k: String) -> bool: return bl.allows(k)),
		"its default loadout is in its pool and fits a bitten Night 2's 5 DP (%d)" % bl_dp)
```

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `checks=N failures=0`.
  - If `_cast`'s "walk from the Temple to every shrine's side" check fails, a shrine has closed a street. Move that `SHRINE_SPOTS` entry to open ground nearby (a square, a forecourt, a wide street) and report it.
- [ ] **Step 9: Run Digest, crowd_check and FLOW.** Expected: unchanged.
- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/broken_lanterns_director.gd src/game/mission/broken_lanterns_director.gd.uid src/game/mission/shrines_objective.gd src/game/mission/shrines_objective.gd.uid src/game/mission/mission_book.gd src/game/ui/results_screen.gd tests/test_broken_lanterns.gd tests/test_broken_lanterns.gd.uid tests/test_mission_book.gd tests/run_all.gd
git commit -m "feat: Broken Lanterns: the shrines, the drain and the flame (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 6: Broken Lanterns — prayer, the Lantern Knights, the kneelers

**Files:**
- Create: `src/game/mission/through_faithful_objective.gd`
- Modify: `src/game/mission/broken_lanterns_director.gd`, `src/game/mission/mission_book.gd`, `tests/test_broken_lanterns.gd`, `tests/test_mission_book.gd`

**Interfaces:**
- Consumes:
  - Task 5's director and hooks;
  - `GazeMeter.pray(praying, delta)`;
  - `Crowd.add_soldier()`, `Person.Corps.KNIGHT`, `Person.HEALTH_KNIGHT` (Task 3);
  - `Person.send_to_post(at, rally, hurried)`, `Person.go_duty()`, `Person.leave_shelter(false)`.
- Produces, on `BrokenLanternsDirector`:
  - constants `PRAYERS`, `PRAY_RING`, `PRAY_REACH`, `PRAYER_SCALE`, `KNEELERS`, `KNEEL_RINGS`, `BONUS_REACH`, `KNIGHTS_AT`, `KNIGHTS`, `GUARD_REACH`, `GUARD_OFFSETS`, `TICK`, `RESUMABLE`;
  - vars `praying: Dictionary` (Person -> [Structure, Vector2]), `kneelers: Array[Person]`, `kneel_shrine: Structure`, `knights: Array[Person]`, `guarding: Dictionary` (Person -> Structure), `last_kneelers: int`;
  - funcs `praying_count() -> int`, `kneeling_near() -> int`, `guarded(s) -> bool`, `guard_of(s) -> Person`, `living_knights() -> int`, `faithful_near(at, r) -> int`.
- Also produced: `ThroughFaithfulObjective`: label `"Through the faithful"`, reason `"faithful"`, `NEED := 10`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_broken_lanterns.gd`, add `_prayers(t)`, `_knights(t)`, `_kneelers(t)` and `_focus(t)` to `run()` after `_ending(t)`, and add:

```gdscript
## Each shrine broken: PRAYERS Faithful to each standing shrine; at their places they pray, feeding the Gaze up to its
## cap; a held or frightened mind does not pray; one back on its feet goes back; a broken shrine keeps nobody praying.
static func _prayers(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	_away(d)
	t.check(d.praying.is_empty(), "nobody prays before a shrine breaks")
	_break(d.shrines[0])
	var per := {}
	var sent_ok := true
	for k: Variant in d.praying.keys():
		var e: Array = d.praying[k]
		per[e[0]] = int(per.get(e[0], 0)) + 1
		sent_ok = sent_ok and d.faithful.has(k) and not d.vigil.walkers().has(k) and (k as Person).mind == Person.Mind.DUTY
	sent_ok = sent_ok and not per.has(d.shrines[0])
	for i in range(1, 6):
		sent_ok = sent_ok and int(per.get(d.shrines[i], 0)) == BrokenLanternsDirector.PRAYERS
	t.check(sent_ok, "a shrine broken sends three Faithful to each standing shrine (%s)" % [per.values()])
	for k: Variant in d.praying.keys():
		_arrive(k as Person, d.praying[k][1])
	_run(s, DT)
	t.check(d.praying_count() == 5 * BrokenLanternsDirector.PRAYERS, "at their places they pray (%d)" % d.praying_count())
	var g0 := d.gaze.value
	_run(s, 1.0)
	t.near(d.gaze.value - g0, GazeMeter.PRAYER_CAP * BrokenLanternsDirector.PRAYER_SCALE, 0.05,
		"fifteen at prayer feed the Gaze at its cap")
	var ps: Array = d.praying.keys()
	for i in range(2, ps.size()):
		(ps[i] as Person).confuse(15.0)
	_run(s, DT)
	t.check(d.praying_count() == 2, "a mind the god holds does not pray (%d)" % d.praying_count())
	var p0 := ps[0] as Person
	p0.mind = Person.Mind.PANIC
	t.check(d.praying_count() == 1, "nor a frightened one")
	p0.mind = Person.Mind.RECOVER
	_run(s, BrokenLanternsDirector.TICK + DT)
	t.check(p0.mind == Person.Mind.DUTY and p0.anchor.distance_to(d.praying[p0][1]) < 0.01,
		"back on their feet, a prayer goes back to their place")
	_break(d.shrines[2])
	var on_broken := 0
	var per2 := {}
	for k: Variant in d.praying.keys():
		var sh: Structure = d.praying[k][0]
		on_broken += 1 if sh.destroyed else 0
		if _alive(k):
			per2[sh] = int(per2.get(sh, 0)) + 1
	t.check(on_broken == 0, "nobody is left praying at a broken shrine")
	var full := d.standing_shrines().size() == 4
	for sh in d.standing_shrines():
		full = full and int(per2.get(sh, 0)) == BrokenLanternsDirector.PRAYERS
	t.check(full, "the standing four are topped up to three each")
	_done(s)


## 1:30: the Knights come and guard; a guarded shrine takes no blow; its Knight killed first, it breaks; a Knight whose
## shrine fell guards another; with fewer standing shrines they double up, with none they guard nothing (review focus 3).
static func _knights(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	var crowd: Crowd = s.crowd
	_away(d)
	var before := crowd.soldiers.size()
	d.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	t.check(d.knights.size() == BrokenLanternsDirector.KNIGHTS and crowd.soldiers.size() == before + BrokenLanternsDirector.KNIGHTS
		and (s.banners as Array).has("THE LANTERN KNIGHTS"), "1:30: four Lantern Knights come from the Temple")
	var kn_ok := true
	var guarded_shrines := {}
	for k in d.knights:
		var sh: Structure = d.guarding.get(k)
		kn_ok = kn_ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
			and k.mind == Person.Mind.POST and sh != null and not sh.destroyed \
			and sh.distance_to(k.anchor) <= BrokenLanternsDirector.GUARD_REACH
		if sh != null:
			guarded_shrines[sh] = true
	t.check(kn_ok and guarded_shrines.size() == BrokenLanternsDirector.KNIGHTS,
		"each is sent to guard a different standing shrine (%d)" % guarded_shrines.size())
	var k0 := d.knights[0]
	var sh0: Structure = d.guarding[k0]
	_arrive(k0, k0.anchor)
	_break(sh0)
	t.check(not sh0.destroyed and sh0.hp == sh0.max_hp and d.guarded(sh0) and d.guard_of(sh0) == k0,
		"a Knight beside it, the shrine shrugs off the blow")
	crowd._field.kill(k0, &"lightning")
	_break(sh0)
	t.check(sh0.destroyed and d.draining(sh0), "its Knight struck down first, the shrine breaks")
	var k1 := d.knights[1]
	var sh1: Structure = d.guarding[k1]
	_break(sh1)
	_run(s, BrokenLanternsDirector.TICK + DT)
	var now: Structure = d.guarding.get(k1)
	t.check(sh1.destroyed and now != null and now != sh1 and not now.destroyed and now.distance_to(k1.anchor) <= BrokenLanternsDirector.GUARD_REACH,
		"a Knight not yet at his shrine when it falls goes to guard another")
	t.check(d.living_knights() == BrokenLanternsDirector.KNIGHTS - 1, "the HUD's count of Knights alive")
	_done(s)

	var s2 := _setup()
	var d2: BrokenLanternsDirector = s2.d
	_away(d2)
	for i in 4:
		_break(d2.shrines[i])
	d2.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	var per := {}
	for k in d2.knights:
		var sh: Structure = d2.guarding.get(k)
		if sh != null:
			per[sh] = int(per.get(sh, 0)) + 1
	t.check(per.size() == 2 and per.values().all(func(n: int) -> bool: return n == 2),
		"two shrines standing: the four Knights guard them two by two (%s)" % [per.values()])
	_done(s2)

	var s3 := _setup()
	var d3: BrokenLanternsDirector = s3.d
	_away(d3)
	for sh in d3.shrines:
		_break(sh)
	d3.timeline.step(BrokenLanternsDirector.KNIGHTS_AT)
	_run(s3, BrokenLanternsDirector.TICK + DT)
	t.check(d3.knights.size() == BrokenLanternsDirector.KNIGHTS and d3.guarding.is_empty(),
		"with no shrine standing, the Knights come and guard nothing")
	_done(s3)


## Five drained: the kneelers ring the last shrine within BONUS_REACH. Broken with ten or more still there, the bonus;
## drawn away first, none.
static func _kneelers(t) -> void:
	for drawn_away in [false, true]:
		var s := _setup()
		var d: BrokenLanternsDirector = s.d
		var rules: Rules = s.rules
		_away(d)
		for i in 5:
			_break(d.shrines[i])
		_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
		var last := d.shrines[5]
		var placed := d.drained_count() == 5 and d.kneel_shrine == last and d.kneelers.size() == BrokenLanternsDirector.KNEELERS
		for p in d.kneelers:
			var spot: Vector2 = d.praying[p][1]
			placed = placed and spot.distance_to(last.center()) <= BrokenLanternsDirector.BONUS_REACH
		t.check(placed and (s.banners as Array).has("THE FAITHFUL KNEEL AT THE LAST LANTERN"),
			"five drained: fifteen Faithful kneel round the last shrine (%d)" % d.kneelers.size())
		for p in d.kneelers:
			var spot: Vector2 = d.praying[p][1]
			_arrive(p, spot if not drawn_away else last.center() + Vector2(5.0, 0.0))
		_run(s, DT)
		_break(last)
		_run(s, BrokenLanternsDirector.DRAIN_SECONDS + 0.5)
		var res := rules.result()
		var earned: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
		if not drawn_away:
			t.check(rules.won and d.last_kneelers >= ThroughFaithfulObjective.NEED and earned,
				"struck through ten or more kneelers: won, and Through the faithful (%d)" % d.last_kneelers)
		else:
			t.check(rules.won and d.last_kneelers == 0 and not earned, "drawn away first: won, without the bonus")
		_done(s)


## Review focus 2 and 5: the last shrine already broken when the fifth drains; the Faithful run out.
static func _focus(t) -> void:
	var s := _setup()
	var d: BrokenLanternsDirector = s.d
	_away(d)
	for i in 5:
		_break(d.shrines[i])
	_run(s, 10.0)
	_break(d.shrines[5])
	_run(s, BrokenLanternsDirector.DRAIN_SECONDS - 10.0 + 0.5)
	t.check(d.drained_count() == 5 and d.draining(d.shrines[5]) and d.kneel_shrine == null and d.kneelers.is_empty(),
		"the last shrine already broken when the fifth drains: nobody kneels")
	_arrive(d.vigil.bearer, d.relight_point(d.shrines[5]))
	_run(s, DT * 2.0)
	t.check(not d.shrines[5].destroyed and d.kneel_shrine == d.shrines[5] and d.kneelers.size() == BrokenLanternsDirector.KNEELERS,
		"relit, the kneelers come then")
	_done(s)

	var s2 := _setup()
	var d2: BrokenLanternsDirector = s2.d
	_away(d2)
	var walking := d2.vigil.walkers()
	for f in d2.faithful:
		if not walking.has(f):
			f.inside = true
	_break(d2.shrines[0])
	t.check(d2.praying.is_empty(), "with no Faithful free, a break sends nobody")
	for f in d2.faithful:
		f.inside = false
	_break(d2.shrines[1])
	var victims: Array[Person] = []
	for k: Variant in d2.praying.keys():
		if d2.praying[k][0] == d2.shrines[2]:
			victims.append(k as Person)
	for v in victims:
		(s2.crowd as Crowd)._field.kill(v, &"stone")
	_run(s2, BrokenLanternsDirector.TICK + DT)
	var ghosts := 0
	for k: Variant in d2.praying.keys():
		ghosts += 0 if _alive(k) else 1
	t.check(victims.size() == BrokenLanternsDirector.PRAYERS and ghosts == 0, "prayers killed at their shrine leave no ghosts")
	_done(s2)
```

  In `tests/test_mission_book.gd`, after the default-loadout check added in Task 5, add:

```gdscript
	t.check(bl.bonuses().size() == 1 and bl.bonuses()[0].label == "Through the faithful", "one bonus, Through the faithful")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a Parse Error naming `praying`, `KNIGHTS_AT` or `ThroughFaithfulObjective`.

- [ ] **Step 3: Write `ThroughFaithfulObjective`.** Create `src/game/mission/through_faithful_objective.gd`:

```gdscript
class_name ThroughFaithfulObjective
extends Objective
## Broken Lanterns' bonus (v0.10): the last shrine breaks with at least NEED of its kneelers still within
## BrokenLanternsDirector.BONUS_REACH of it. They are counted the step before the blow, so a strike through them still
## counts them.

const NEED := 10


func _init() -> void:
	label = "Through the faithful"
	reason = "faithful"


func check(rules: Rules) -> Status:
	var d := rules.director as BrokenLanternsDirector
	if d == null or d.drained_count() < d.shrines.size():
		return Status.PENDING
	return Status.DONE if d.last_kneelers >= NEED else Status.FAILED
```

  In `src/game/mission/mission_book.gd`'s `broken_lanterns()`, before `return m`, add:

```gdscript
	m.make_bonuses = func() -> Array[Objective]:
		var out: Array[Objective] = [ThroughFaithfulObjective.new()]
		return out
```

- [ ] **Step 4: The director's prayer, Knights and kneelers.** In `src/game/mission/broken_lanterns_director.gd`:
  - Under `const MARK_DRAINING`, add:

```gdscript
## Each shrine broken (spec §4.1): every standing shrine is topped up to PRAYERS Faithful sent to pray there, on a ring
## PRAY_RING round it. On their duty and within PRAY_REACH of their place, they pray. Prayer feeds Halcyon's Gaze
## (GazeMeter.pray()), scaled by PRAYER_SCALE: 1.0 is the spec's rate, and the scale is this mission's own lever for
## balance, so M4's Gaze is untouched.
const PRAYERS := 3
const PRAY_RING := 1.0
const PRAY_REACH := 0.6
const PRAYER_SCALE := 1.0
## When five are drained, KNEELERS Faithful kneel round the last standing shrine on these rings ([radius, places]), all
## within BONUS_REACH of it (ThroughFaithfulObjective).
const KNEELERS := 15
const KNEEL_RINGS := [[1.0, 6], [1.7, 9]]
const BONUS_REACH := 2.0
## 1:30 -- KNIGHTS Lantern Knights come from the Temple and guard the standing shrines, each at one of a shrine's
## GUARD_OFFSETS places. A shrine with a living Knight within GUARD_REACH takes no damage.
const KNIGHTS_AT := 90.0
const KNIGHTS := 4
const GUARD_REACH := 1.5
const GUARD_OFFSETS := [Vector2(0.8, -0.6), Vector2(-0.8, -0.6)]
## Seconds between the director's looks at its prayers and Knights.
const TICK := 0.5
## Minds a prayer is sent back from (back on their feet). A Faithful in one of these, or on a duty, can be called.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
```

  - Under `var _relight_at := {}`, add:

```gdscript
## Person -> [Structure, Vector2]: the Faithful sent to pray, at which shrine, and where.
var praying := {}
var kneelers: Array[Person] = []
## The shrine the kneelers ring, once five are drained.
var kneel_shrine: Structure
var knights: Array[Person] = []
## Knight -> the shrine he guards.
var guarding := {}
## Kneelers within BONUS_REACH of the last shrine when it last broke, counted the step before the blow.
var last_kneelers := 0
var _kneeling_near := 0
var _tick := 0.0
```

  - Replace the six Task 5 stubs (from the `## Task 6 fills these in` comment through `guarded()`) with:

```gdscript
func _add_events() -> void:
	timeline.add(KNIGHTS_AT, "knights", "The Lantern Knights", _knights_come)


func _prayers_step(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_tend_prayers()
		_tend_knights()
	gaze.pray(praying_count(), delta * PRAYER_SCALE)
	_kneeling_near = kneeling_near()


## The shrine's prayers are let go (its kneelers stay by it), and every standing shrine is topped up.
func _broke(s: Structure) -> void:
	last_kneelers = _kneeling_near if s == kneel_shrine else 0
	for k: Variant in praying.keys():
		if praying[k][0] != s or kneelers.has(k):
			continue
		praying.erase(k)
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	_call_prayers()


func _relit(_s: Structure) -> void:
	_maybe_kneel()


func _drained_one(_s: Structure) -> void:
	_maybe_kneel()


## A living Lantern Knight stands within GUARD_REACH of the shrine.
func guarded(s: Structure) -> bool:
	return guard_of(s) != null


func guard_of(s: Structure) -> Person:
	for k in knights:
		if _alive(k) and s.distance_to(k.ground_pos) <= GUARD_REACH:
			return k
	return null


func living_knights() -> int:
	var n := 0
	for k in knights:
		n += 1 if _alive(k) else 0
	return n


func faithful_near(at: Vector2, reach: float) -> int:
	var n := 0
	for f in faithful:
		n += 1 if _alive(f) and not f.inside and f.ground_pos.distance_to(at) <= reach else 0
	return n


## Each standing shrine is topped up to PRAYERS living Faithful sent to pray there, the nearest free ones first.
func _call_prayers() -> void:
	for s in standing_shrines():
		var have := 0
		for k: Variant in praying.keys():
			if praying[k][0] == s and _alive(k):
				have += 1
		for i in range(have, PRAYERS):
			var p := _free_faithful(s.center())
			if p == null:
				return
			_send(p, s, _ring(s, PRAY_RING, i, PRAYERS))


## The living Faithful nearest `at` who is free to be sent: out in the open, not walking the Vigil, not already sent,
## and on their day or back on their feet (or on a duty: a prayer whose shrine fell). Null when there is nobody.
func _free_faithful(at: Vector2) -> Person:
	var walking: Array[Person] = vigil.walkers() if vigil != null else ([] as Array[Person])
	var best: Person = null
	for f in faithful:
		if not _alive(f) or f.inside or praying.has(f) or walking.has(f):
			continue
		if not (f.mind in RESUMABLE or f.mind == Person.Mind.DUTY):
			continue
		if best == null or f.ground_pos.distance_to(at) < best.ground_pos.distance_to(at):
			best = f
	return best


func _send(p: Person, s: Structure, spot: Vector2) -> void:
	praying[p] = [s, spot]
	p.go_duty(spot)


## The i-th of n places on a ring of radius r round the shrine, on open ground.
func _ring(s: Structure, r: float, i: int, n: int) -> Vector2:
	return _walkable(s.center() + Vector2.from_angle(TAU * float(i) / float(n) + 0.4) * r)


## The dead are let go; those back on their feet are sent to their places again.
func _tend_prayers() -> void:
	for k: Variant in praying.keys():
		if not _alive(k):
			praying.erase(k)
			continue
		var p := k as Person
		if p.mind in RESUMABLE:
			var e: Array = praying[k]
			p.go_duty(e[1])


## The Faithful praying now: alive and out, on their duty within PRAY_REACH of their place, at a standing shrine.
func praying_count() -> int:
	var n := 0
	for k: Variant in praying.keys():
		if not _alive(k):
			continue
		var p := k as Person
		var e: Array = praying[k]
		var spot: Vector2 = e[1]
		if not p.inside and p.mind == Person.Mind.DUTY and not (e[0] as Structure).destroyed \
				and p.ground_pos.distance_to(spot) <= PRAY_REACH:
			n += 1
	return n


## Kneelers alive and out within BONUS_REACH of the last shrine.
func kneeling_near() -> int:
	if kneel_shrine == null:
		return 0
	var n := 0
	for p in kneelers:
		if _alive(p) and not p.inside and p.ground_pos.distance_to(kneel_shrine.center()) <= BONUS_REACH:
			n += 1
	return n


## Five drained and the last shrine standing: KNEELERS Faithful kneel round it, once a night. They are whoever was
## praying anywhere, and the nearest free others.
func _maybe_kneel() -> void:
	if kneel_shrine != null or drained.size() != shrines.size() - 1:
		return
	var last: Structure = null
	for s in shrines:
		if not drained.has(s):
			last = s
	if last == null or last.destroyed:
		return
	kneel_shrine = last
	praying.clear()
	for place in _kneel_places(last):
		var p := _free_faithful(last.center())
		if p == null:
			break
		_send(p, last, place)
		kneelers.append(p)
	rules.banner.emit("THE FAITHFUL KNEEL AT THE LAST LANTERN")


func _kneel_places(s: Structure) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for ring: Array in KNEEL_RINGS:
		for i in int(ring[1]):
			out.append(_ring(s, float(ring[0]), i, int(ring[1])))
	return out


## 1:30 -- the Lantern Knights come from the Temple's door: soldiers with three times a soldier's health, who guard the
## standing shrines.
func _knights_come() -> void:
	for i in KNIGHTS:
		var k := crowd.add_soldier(_walkable(temple_door + Vector2(float(i) - float(KNIGHTS - 1) * 0.5, 0.6)))
		k.corps = Person.Corps.KNIGHT
		k.health = Person.HEALTH_KNIGHT
		knights.append(k)
	_tend_knights()


## Each living Knight to a standing shrine. One whose shrine fell goes to the standing shrine with the fewest Knights
## (the nearest of those). One taken off his place (an investigation) is sent back to it.
func _tend_knights() -> void:
	var standing := standing_shrines()
	for k in knights:
		if not _alive(k):
			continue
		var s: Structure = guarding.get(k)
		if s == null or s.destroyed:
			guarding.erase(k)
			s = _least_guarded(standing, k)
			if s == null:
				continue
			guarding[k] = s
		var place := _guard_place(s, k)
		if k.mind == Person.Mind.POST and k.anchor.distance_to(place) > 0.3:
			k.send_to_post(place, false, true)


func _least_guarded(standing: Array[Structure], k: Person) -> Structure:
	var best: Structure = null
	var best_n := 0
	for s in standing:
		var n := _guards(s).size()
		if best == null or n < best_n \
				or (n == best_n and s.center().distance_to(k.ground_pos) < best.center().distance_to(k.ground_pos)):
			best = s
			best_n = n
	return best


## The living Knights guarding `s`, in the order they came.
func _guards(s: Structure) -> Array[Person]:
	var out: Array[Person] = []
	for k in knights:
		if _alive(k) and guarding.get(k) == s:
			out.append(k)
	return out


func _guard_place(s: Structure, k: Person) -> Vector2:
	var i := maxi(_guards(s).find(k), 0)
	return _walkable(s.center() + (GUARD_OFFSETS[i % GUARD_OFFSETS.size()] as Vector2))
```

  - Change `report()` to `return {"drained": drained.size(), "relit": relit, "knights": living_knights()}`.

- [ ] **Step 5: Run the tests to verify they pass.** Expected: `checks=N failures=0`.
  - If a kneel spot snaps beyond `BONUS_REACH` (a wall beside the last shrine), move that shrine's `SHRINE_SPOTS` entry to more open ground, not the bonus reach, and report it.
- [ ] **Step 6: Run Digest, crowd_check and FLOW.** Expected: unchanged.
- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/broken_lanterns_director.gd src/game/mission/through_faithful_objective.gd src/game/mission/through_faithful_objective.gd.uid src/game/mission/mission_book.gd tests/test_broken_lanterns.gd tests/test_mission_book.gd
git commit -m "feat: Broken Lanterns: prayer, the Lantern Knights, the kneelers (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 7: The `lanterns` scenario, and the photograph

**Files:**
- Modify: `tools/dev/behaviour_check.gd`, `src/game/game.gd`

**Interfaces:**
- Consumes:
  - `BrokenLanternsDirector` (Tasks 5–6): `standing_shrines()`, `guarded()`, `guard_of()`, `faithful_near()`, `drained_count()`, `drain_left`, `relit`, `praying_count()`, `living_knights()`, `vigil`, `gaze`;
  - `Rules.cast(slot, ground, extra)`, `Rules.refusal(slot)`, `Rules.key(slot)`;
  - `BellNetwork.State`.
- Produces:
  - `--scenario=lanterns --case=none|play`, which prints `BEHAVIOUR lanterns t=… drained=… broken=… relit=… praying=… gaze=… knights=…` every 10 s and a final `BEHAVIOUR lanterns result won=… reason=… time=… drained=… relit=… gaze=… bonus=…`;
  - `--show=lanterns` on the game scene: Broken Lanterns as its intro lands, for the photograph.

- [ ] **Step 1: The scenario.** In `tools/dev/behaviour_check.gd`:
  - Add to the scenario list in the header comment, after the `miras` lines: `##   lanterns  (v0.10 M3) Broken Lanterns, --case=none (nothing cast) or play (Heaven Splitter, Dragonfire Parade and Silent Doom: break the standing shrine with the fewest Faithful near; doom the called bellkeeper, the bearer near a draining shrine, or the Knight in the way).`
  - Under `const LOOK_FRAMES := 6`, add:

```gdscript
## The Broken Lanterns policy (v0.10 M3): how far round a shrine counts its Faithful, and how near a draining shrine the
## flame-bearer may come before Silent Doom takes him.
const LANTERN_CROWD_R := 3.0
const LANTERN_BEARER_NEAR := 6.0
```

  - In the setup block, beside `elif scenario == "miras":`, add:

```gdscript
	elif scenario == "lanterns":
		powers = PackedStringArray(["heaven", "dragon", "doom"])
		mission.mission_id = MissionBook.BROKEN_LANTERNS
```

  - In the `match scenario:`, after `"miras":`, add:

```gdscript
		"lanterns":
			await _lanterns(Battlefield.arg_value(args, "--case"))
```

  - After `_miras()`, add:

```gdscript
## Broken Lanterns (v0.10 M3), played by a simple policy every LOOK_FRAMES. Silent Doom takes the bellkeeper once he is
## called; else the flame-bearer once he nears a draining shrine; else the Knight guarding the next shrine. Otherwise a
## Heaven Splitter or a Dragonfire Parade lands on the standing, unguarded shrine with the fewest Faithful near it.
## `none` casts nothing.
func _lanterns(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BrokenLanternsDirector
	var crowd: Crowd = mission._crowd
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR lanterns t=%d drained=%d broken=%d relit=%d praying=%d gaze=%d knights=%d" % [roundi(t),
				d.drained_count(), d.drain_left.size(), d.relit, d.praying_count(), roundi(d.gaze.value), d.living_knights()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		if _slot_ready(rules, slots, "doom"):
			var mark := _lantern_doom_target(d, crowd)
			if mark != null:
				rules.cast(slots.doom, mark.ground_pos)
				continue
		var target := _lantern_target(d)
		if target == null:
			continue
		for key in ["heaven", "dragon"]:
			if _slot_ready(rules, slots, key):
				rules.cast(slots[key], target.center(), {"dir": Vector2(1, 0)})
				break
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR lanterns result won=%s reason=%s time=%.1f drained=%d relit=%d gaze=%d bonus=%s" % [res.won,
		res.reason, float(res.time), d.drained_count(), d.relit, roundi(d.gaze.value), bonus])


func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
	return slots.has(key) and rules.refusal(int(slots[key])) == ""


## Whom the Broken Lanterns policy strikes down quietly: the bellkeeper once called, the flame-bearer near a draining
## shrine, or the Knight guarding the next shrine; else null.
func _lantern_doom_target(d: BrokenLanternsDirector, crowd: Crowd) -> Person:
	var bell := crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] \
			and is_instance_valid(bell.keeper) and bell.keeper.is_alive():
		return bell.keeper
	var v := d.vigil
	if v != null and v.active and v.detour != Vector2.INF and is_instance_valid(v.bearer) and v.bearer.is_alive() \
			and v.bearer.ground_pos.distance_to(v.detour) <= LANTERN_BEARER_NEAR:
		return v.bearer
	var target := _lantern_target(d, true)
	if target != null and d.guarded(target):
		return d.guard_of(target)
	return null


## The shrine the Broken Lanterns policy breaks next: of the standing ones (only unguarded ones, unless `guarded_too`),
## the one with the fewest Faithful near; else null.
func _lantern_target(d: BrokenLanternsDirector, guarded_too := false) -> Structure:
	var best: Structure = null
	var best_n := 0
	for s in d.standing_shrines():
		if not guarded_too and d.guarded(s):
			continue
		var n := d.faithful_near(s.center(), LANTERN_CROWD_R)
		if best == null or n < best_n:
			best = s
			best_n = n
	return best
```

- [ ] **Step 2: Run the scenario.** Run `--scenario=lanterns --case=none` and `--scenario=lanterns --case=play`.
  - Expected: no SCRIPT ERROR either way.
  - `none` loses with reason `relit` at about 180 s: nothing broken, so no prayer and no Gaze.
  - `play` prints its result line. Record both lines for Task 8: this step checks only that the night runs.
- [ ] **Step 3: The photograph.** In `src/game/game.gd`'s `_ready()` `match show:`, add before `_:`:

```gdscript
		"lanterns":
			# Broken Lanterns as its intro lands (v0.10 M3), for the photograph of the shrines, their marks, the Gaze bar and
			# the objectives (unpaused, as Mira's House's).
			mission_id = MissionBook.BROKEN_LANTERNS
			loadout = MissionBook.broken_lanterns().default_loadout
			go_to(Screen.MISSION)
```

  Capture `--show=lanterns`, then again with `-- --art=procedural` added. Check by eye, on both:
  - the shrines in view are small grey stone posts, each with a lit niche under a capstone;
  - a gold diamond sits over each standing shrine;
  - the objective rows read "Shrines drained 0 / 6", "Halcyon's Gaze 0%" and "Dawn 3:00";
  - the event strip shows "1:30 The Lantern Knights".

  Fix the niche's pixels or `CAMERA_AT` if needed, and report what changed.
- [ ] **Step 4: Run Tests, Digest and crowd_check.** Expected: unchanged counts.
- [ ] **Step 5: Commit.**

```bash
git add tools/dev/behaviour_check.gd src/game/game.gd
git commit -m "test: the lanterns scenario and Broken Lanterns photograph (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 8: Balance

**Files:** `src/game/mission/broken_lanterns_director.gd`, `src/environment/structure.gd` (`SHRINE_HP`), `src/game/mission/mission_book.gd` (the clock), `src/game/mission/through_faithful_objective.gd` (`NEED`), `tools/dev/behaviour_check.gd` (the policy's loadout); numbers only.

- [ ] **Step 1: Measure.** Run `--case=none` three times and `--case=play` three times (seeds `--seed=1|2|3`). Record each result line, and each play run's 10-second lines.
- [ ] **Step 2: Compare with the spec's intent (§7: "each Night 2 mission winnable at 8 DP by a scripted policy"):**
  - doing nothing loses;
  - the policy wins at least two seeds out of three;
  - the night is not won before about 1:30, so the Knights and the kneelers must matter.
- [ ] **Step 3: Expect prayer to be the wall.** At the spec's numbers, six Faithful praying already reach the cap of 6 Gaze a second, and the first break sends fifteen. So prayer alone fills the Gaze about 17 s after they kneel. If `play` loses to `gaze` with the 10-second lines showing `praying=` at 6 or more, try these levers first, in order:
  1. `PRAYER_SCALE`: this mission only. `GazeMeter`'s constants stay, for M4.
  2. `PRAYERS`.
  3. `PRAY_REACH`.
- [ ] **Step 4: Tune only these:** `PRAYER_SCALE`, `PRAYERS`, `PRAY_REACH`, `KNEELERS`, `DRAIN_SECONDS`, `RELIGHT_REACH`, `KNIGHTS`, `KNIGHTS_AT`, `GUARD_REACH`, `FAITHFUL`, `Structure.SHRINE_HP`, the clock, `ThroughFaithfulObjective.NEED`, and the policy's loadout (3 slots, at most 8 DP, from the pool). Record each change with before and after result lines. If the bell ends most runs (shrines falling raise the town's alarm), say so. That is the town's own rule, not a number to tune here.
- [ ] **Step 5: Run Tests.** Retune any test that pins a changed number.
- [ ] **Step 6: Commit** with the measurements in the message body.

```bash
git add src/game/mission/broken_lanterns_director.gd src/environment/structure.gd src/game/mission/mission_book.gd src/game/mission/through_faithful_objective.gd tools/dev/behaviour_check.gd tests/test_broken_lanterns.gd tests/test_shrine.gd
git commit -m "tune: Broken Lanterns balance from measured runs (v0.10)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

### Task 9 (controller): M3 gate

- [ ] **Step 1: Gates:**
  - Tests: `failures=0`;
  - Digest and crowd_check unchanged;
  - the ten exact behaviour checksums identical to the new baseline above;
  - `--scenario=miras --case=play` identical to Task 1 Step 1;
  - FLOW: `failures=0`;
  - Mission tests in range.
- [ ] **Step 2: Photographs:**
  - `--show=lanterns`, with the default art and with `--art=procedural`;
  - `--show=miras` and `--show=campaign-choice`, unchanged.

  Show them to the user.
- [ ] **Step 3: Playtest by hand:** Campaign, then on Night 2 choose Broken Lanterns.
- [ ] **Step 4: Land:** fast-forward `feat/Develop-Main`. If origin moved, merge it first and rerun the gates on the merged code. With the user's go-ahead, tag `kak-v010-m3` and push. Report the plan's departures from the spec (above) and Task 8's measurements.
- [ ] **Step 5: Update the Dev Ledger:** M3 to done; `meta/project` with the new counts.
- [ ] **Step 6: Write the M4 plan** (The Vigil Flame).
