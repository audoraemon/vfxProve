# The capital city: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** add a second, larger river-port city (the capital) to KAK. It uses the shared city format, the 73 GPT art sets, 420 citizens and 180 soldiers, and runs at 60 fps or better. Aldermere stays unchanged.

**Architecture:**
- A `CityDef` interface describes one city.
- `AldermereCity` implements it by delegating to the existing `TownLayout` statics and constants. Aldermere's data is not moved, so its behaviour is identical by construction.
- The builder layer reads the active city through `City.active`: `Town`, `TownFloor`, `TownDecor`, `WalkGrid`, the crowd's anchors, exits and districts, and `SpriteArt`.
- Aldermere-only mission directors keep reading `TownLayout`.
- `CapitalCity` implements the same interface with new data.
- Missions pick their city through `MissionDef.city`.

**Tech stack:** Godot 4.7.2 GDScript (GL Compatibility); Python 3.12 + Pillow for art tools.

**Spec:** `docs/superpowers/specs/2026-10-09-capital-city-design.md` (district plan: `2026-10-09-capital-district-plan.png`).

## Global constraints

- **Where:**
  - Work only in `C:\BURIN_NITRO\Godot\GIT\vfxProve-capital`, branch `feat/capital-city`.
  - Never edit other worktrees. `vfxProve` belongs to the v0.10/v0.11 session.
  - Before M2, merge `origin/feat/Develop-Main` into the branch (it must contain the GPT buildings merge) and run the M1 gates again.
- **Aldermere unchanged.** These must match the branch's start (or the latest Develop-Main) exactly:
  - digest `61267b7e90524d800bf1c3473a71146b` (`"$G" --headless --path . -s tools/dev/state_digest.gd 2>&1 | grep digest=`);
  - crowd_check `-346732806` (`"$G" --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`);
  - the deterministic behaviour checksums for `calm gates fire rite boats clip powers soldiers warning miras` (`"$G" --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=<s>`, grep `checksum=`).
  - Note: the cast scenarios `strike escalate bell engineers opening siege judgement quiet` vary from run to run because of hitstop's wall clock, so they are not gates.
- **Tests:**
  - Run `timeout 1800 "$G" --headless --path . --script res://tests/run_all.gd > <scratch>/t.txt 2>&1`, then check for `failures=0` and 0 `SCRIPT ERROR`.
  - Don't run `tools/test.sh`: its 400 s cap is too short now.
  - Run `"$G" --headless --path . --import > /dev/null 2>&1` after asset changes.
- **FLOW:** needs a quiet machine. Check `tasklist | grep -ci godot` first and rerun it alone if it aborts.
- **Bench:**
  - Command: `"$G" --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench [--mission=<id>]`, grep `bench[mission]`.
  - Run 3 or more alternating pairs, take the medians, and note other Godot processes. Rerun any run that throttles below 50 fps.
- **Art:**
  - Use the existing sets only: the `gpt_*` sets, the town sets and decor batch 4.
  - A missing art piece is reported, not generated.
  - Light comes from the left. Ruins stay clean.
- **Commits:**
  - Stage by name, including `.uid` and `.import` files.
  - End each commit message with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - Push only `feat/capital-city`. Merging into Develop-Main is the user's call.
- **Shell:**
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe`
  - Scratch: `C:\Users\dorae\AppData\Local\Temp\claude\C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab\64321455-71f5-4ef9-84ed-ba260def80dc\scratchpad\capital\`
- **Desktop:** the user's desktop is `C:\Users\dorae\OneDrive\Desktop`. Test shortcuts go in `KAK Tests\<n> <build>\`.

## Review focus

1. **Static state leaking between cities.** `City.active` must be reset when a mission builds. A capital sandbox followed by an Aldermere mission in the same session must build Aldermere exactly. Test in Task 4: build the capital, then Aldermere, and compare Aldermere's structure list against a fresh build.
2. **Unreachable places in the capital.** Every routine point, spawn point and exit must be reachable on the walk grid. A citizen spawned behind a wall or on an island must never exist. Test in Task 8.
3. **Bridge and footbridge destroyed during an evacuation.** People must reroute to another bridge or the ferry, not freeze or walk into the river. Test in Task 12.
4. **Hardcoded Aldermere constants in shared code.** Code that runs in both cities must not read `TownLayout` directly. Task 4 adds a grep test that forbids `TownLayout.` in the files listed there, outside documented exceptions.
5. **Frame rate when the whole city is visible at max zoom-out.** This is the worst case for draw calls. The M5 bench must include a zoomed-out pass. Task 14.

---

## Milestone M1: shared city format (Aldermere unchanged)

### Task 1: Baseline gates

**Files:** none. Record the results in the ledger.

- [ ] **Step 1:** In the worktree at its starting HEAD, run `--import`.
- [ ] **Step 2:** Run the tests, digest, crowd_check, the 10 deterministic behaviour checksums and FLOW. Record every number in `.superpowers/sdd/<plan>/progress.md` as the baseline.
- [ ] **Step 3:** Run the bench: 3 runs on Aldermere, recording the medians. No commit.

### Task 2: `CityDef` interface and `AldermereCity`

**Files:**
- Create: `src/game/town/city_def.gd`
- Create: `src/game/town/cities/aldermere_city.gd`
- Create: `src/game/town/city.gd` (the registry)
- Test: `tests/test_city.gd`; add it to `tests/run_all.gd`

**Interfaces (produced):**

```gdscript
class_name CityDef
extends RefCounted
## One city's layout: what the town builder, floor, decor, walk grid and crowd read (via City.active).
## Rects are ground cells; every method is deterministic and returns fresh arrays (callers may mutate them).
func id() -> StringName: return &""
func map() -> Rect2: return Rect2()
func town() -> Rect2: return Rect2()                       # the walled core (Aldermere: TownLayout.TOWN)
func rivers() -> Array[Rect2]: return []
func roads() -> Array: return []                           # polylines as in TownLayout.ROADS
func exits() -> Array[Vector2]: return []
func districts() -> Array: return []                       # as TownLayout.DISTRICTS
func structures() -> Array[Dictionary]: return []          # as TownLayout.structures()
func houses() -> Array[Rect2]: return []
func blockers() -> Array[Rect2]: return []
func anchors() -> Dictionary: return {}                    # as TownLayout.anchors()
func street_props() -> Array[Dictionary]: return []
func gardens() -> Array[Rect2]: return []
func queue_fans(margin := 0.3) -> Array[PackedVector2Array]: return []
func fields() -> Array[Rect2]: return []
func stalls() -> Array[Rect2]: return []
func fountains() -> Array[Rect2]: return []
func wells() -> Array[Rect2]: return []
func citadel_origin() -> Vector2: return Vector2.INF       # INF = this city has no Aldermere-style Citadel node
func landmark(name: StringName) -> Rect2: return Rect2()   # empty Rect2 = unknown
func floor_areas() -> Dictionary: return {}                # name -> Array[Rect2], see Task 3
```

`AldermereCity extends CityDef`. Each method returns the matching `TownLayout` constant or calls the matching static function, duplicating any arrays. `landmark()` maps these names to the matching `TownLayout` constants:
- `market_square`, `temple`, `citadel_court`, `bell_tower`, `dock`, `dock_wait`, `main_gate`, `barracks`, `barracks_yard`, `workshop`, `smithy`, `carpenter`, `windmill`, `watermill`, `bridge`, `fountain_plaza`.

```gdscript
class_name City
extends RefCounted
## The city being built or played. Missions set it before building (Mission, town_debug); defaults to Aldermere.
static var active: CityDef = null
static func current() -> CityDef:
	if active == null:
		active = AldermereCity.new()
	return active
static func use(id: StringName) -> void:
	active = by_id(id)
static func by_id(id: StringName) -> CityDef:
	match id:
		&"capital":
			return load("res://src/game/town/cities/capital_city.gd").new()
		_:
			return AldermereCity.new()
```

- [ ] **Step 1: Write the failing test** in `tests/test_city.gd`:

```gdscript
extends RefCounted
## The shared city format: Aldermere through CityDef is exactly TownLayout.

static func run(t) -> void:
	var c := AldermereCity.new()
	t.check(c.id() == &"aldermere", "Aldermere's city id")
	t.check(c.map() == TownLayout.MAP, "map")
	t.check(c.structures() == TownLayout.structures(), "same structures, same order")
	t.check(c.houses() == TownLayout.houses(), "same houses")
	t.check(c.anchors() == TownLayout.anchors(), "same anchors")
	t.check(c.blockers() == TownLayout.blockers(), "same blockers")
	t.check(c.landmark(&"market_square") == TownLayout.MARKET_SQUARE, "market landmark")
	t.check(c.landmark(&"nowhere") == Rect2(), "unknown landmark is empty")
	City.active = null
	t.check(City.current() is AldermereCity, "Aldermere is the default city")
```

- [ ] **Step 2:** Run the tests. They should fail: `AldermereCity` doesn't exist yet.
- [ ] **Step 3:** Write the three files as specified above.
- [ ] **Step 4:** Run the tests. They pass with 0 SCRIPT ERROR.
- [ ] **Step 5:** Commit: `feat: CityDef city format and AldermereCity (delegates to TownLayout)`.

### Task 3: Builder layer reads `City.current()`

**Files:**
- Modify:
  - `src/game/town/town.gd`
  - `src/game/town/town_floor.gd`
  - `src/game/town/town_decor.gd`
  - `src/game/town/walk_grid.gd`
  - `src/game/crowd/crowd.gd`
  - `src/game/crowd/person.gd`
  - `src/game/crowd/citizen_profile.gd`
  - `src/game/crowd/alarm_manager.gd`
  - `src/game/crowd/evacuation_manager.gd`
  - `src/game/crowd/engineer_manager.gd`
  - `src/game/crowd/river_ferry.gd`
  - `src/environment/art/sprite_art.gd`
  - `src/environment/art/decor_sprites.gd`
  - `src/game/targeting.gd`
  - `src/game/mission.gd` (`MAP` / `CITADEL_ORIGIN` / `MAIN_GATE` reads only)
- Modify: `src/game/town/cities/aldermere_city.gd`, extending `floor_areas()`.

**Interfaces:**
- Consumes `CityDef` / `City.current()` from Task 2.
- Produces `floor_areas()` keys, which `AldermereCity` returns:
  - `&"plazas"`: `[MARKET_SQUARE, TEMPLE, CITADEL_COURT, FOUNTAIN_PLAZA] + GATE_PLAZAS`;
  - `&"yards"`: `[BARRACKS_YARD, CARPENTER_YARD, …]`;
  - `&"farm"`: `FIELDS + BARNS + [WINDMILL, WATERMILL]`.

  Each key lists the exact constants `town_floor.gd` reads today for that purpose; read the file to get the list.

- [ ] **Step 1:** In each listed file, replace every `TownLayout.<X>` read with the `City.current()` method or landmark that returns the same value.
  - Keep the same iteration order.
  - Where a constant is used only as a type (`TownLayout.Prop`), leave it.
  - Aldermere-only mission directors are NOT in this list and keep `TownLayout`.
- [ ] **Step 2:** Run `--import`, then the tests. Expect failures=0 and 0 SCRIPT ERROR.
- [ ] **Step 3:** Run the digest, crowd_check, the 10 deterministic behaviour checksums and FLOW. All must equal the Task 1 baseline exactly.
- [ ] **Step 4:** Take a capture: `GODOT=$G SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --capture-town --only=town_overview`. Read it; it should be the same town. A capture diff isn't proof (memory: capture diffs are unreliable), so the checksums are the proof.
- [ ] **Step 5:** Commit: `refactor: town builder, floor, decor, walk grid, crowd and art read the active city`.

### Task 4: Mission picks its city; leak guard and grep guard

**Files:**
- Modify: `src/game/mission/mission_def.gd`. Add `var city: StringName = &"aldermere"`, plus parsing if `MissionDef`s are data-driven: read how `mission_book.gd` builds them.
- Modify: `src/game/mission.gd`. Call `City.use(def.city)` before building the town, at the start of a fresh mission.
- Modify: `src/game/town_debug.gd`. Add `--city=<id>` (default aldermere) and call `City.use()` before building.
- Test: `tests/test_city.gd`.

- [ ] **Step 1: Write the failing tests** (Review Focus 1 and 4):

```gdscript
static func _leak(t) -> void:
	# A capital build then an Aldermere build gives exactly Aldermere (no state carried over).
	City.use(&"aldermere")
	var fresh := City.current().structures()
	City.use(&"capital")
	City.use(&"aldermere")
	t.check(City.current().structures() == fresh, "Aldermere rebuilds identically after another city")

static func _no_hardcoded(t) -> void:
	# Shared code reads the active city, never Aldermere's constants (Aldermere-only directors excepted).
	const SHARED := ["res://src/game/town/town.gd", "res://src/game/town/town_floor.gd",
		"res://src/game/town/town_decor.gd", "res://src/game/town/walk_grid.gd",
		"res://src/game/crowd/crowd.gd", "res://src/game/crowd/evacuation_manager.gd",
		"res://src/game/crowd/alarm_manager.gd", "res://src/game/crowd/citizen_profile.gd"]
	for p: String in SHARED:
		var src := FileAccess.get_file_as_string(p)
		var n := src.count("TownLayout.") - src.count("TownLayout.Prop")
		t.check(n == 0, "%s reads no TownLayout constants (found %d)" % [p, n])
```

  Until Task 6 exists, `City.use(&"capital")` loads a stub: add a minimal `capital_city.gd` returning empty data, with `id()` = `&"capital"`.
- [ ] **Step 2:** Run the tests. They fail until the field and the `City.use` calls are wired.
- [ ] **Step 3:** Implement the changes above.
- [ ] **Step 4:** Run the tests, then the digest, crowd, behaviour checksums and FLOW. All must equal the baseline.
- [ ] **Step 5:** Commit: `feat: missions choose their city (default Aldermere); leak and hardcode guards`.

### Task 5: M1 checkpoint (controller)

- Run the full gates and the bench (within noise of Task 1).
- Push the branch.
- Update the Dev Ledger card p14.
- Stop for the user.

---

## Milestone M2: capital geography and plots

### Task 6: Merge Develop-Main (GPT buildings) and capital geography

**Files:**
- Merge `origin/feat/Develop-Main`.
- Create `src/game/town/cities/capital_city.gd`.
- Test: `tests/test_capital.gd`.

**Interfaces:**
- Produces `CapitalCity extends CityDef` (`id()` = `&"capital"`).
- Map: `map()` = `Rect2(-40,-40,80,80)`.
- Water and crossings:
  - `rivers()` = the river band `Rect2(-40,6,80,6)` plus the harbour basin `Rect2(22,-2,18,20)`;
  - bridges, as BRIDGE-kind structures, at x≈−14 and x≈4 (stone) and x≈14 (footbridge set `gpt_footbridge`).
- Walls: two rings, built with the same wall, tower and gate pieces as `TownLayout.walls()` (reuse its helpers by parameterising, not by copying):
  - inner ring around `Rect2(-24,-30,42,34)`;
  - outer ring around `Rect2(-30,12,52,22)`.
- Exits: south barbican (≈7,34), west gate (≈−24,−13), the harbour ferry, and the map edges along the roads.
- Roads: polylines for the avenues, plus 1-cell lanes.
- Districts, with the rects from the spec §1 table.

- [ ] **Step 1:** Merge `origin/feat/Develop-Main`. Rerun the M1 gates; they must match the baseline taken after the merge, which you re-record in the ledger.
- [ ] **Step 2: Write the failing tests.**
  - Build `CapitalCity`.
  - Rivers are inside the map.
  - The walls form closed rings with gates.
  - The district rects match the spec.
  - The three bridges cross the river band.
- [ ] **Step 3:** Implement the geography only, with no buildings yet.
- [ ] **Step 4:** Run the tests and the M1 gates, which must be unchanged.
- [ ] **Step 5:** Commit: `feat: capital geography: river, harbour, bridges, two wall rings, roads, districts`.

### Task 7: Capital plots: every building on its plot

**Files:**
- Modify `capital_city.gd`: `structures()`, `houses()`, `stalls()`, `fields()`, `fountains()`, `wells()`, `anchors()`, `blockers()`, `floor_areas()`.
- Create `src/game/town/cities/capital_plots.gd`, a block generator.

**Interfaces:**
- `structures()` returns `TownLayout`-style dictionaries: `{rect, height, kind, seed, role, tag}`.
- Each GPT building uses its blockout footprint and height from `concepts/GPT/blockout_sheets.py`.
- Art maps through tag `&"gpt_<name>"`: `SpriteArt.name_for` returns the matching set when `role == &"gpt"`.
- The existing citadel, cathedral, stall, house, tavern, smithy and tower sets are reused as in Aldermere.
- Generator: `CapitalPlots.row(block: Rect2, plot: Vector2, gap: float, seed: int) -> Array[Rect2]` fills house blocks deterministically.

Placement follows the spec §1 table. Rules:
- streets at least 1 cell wide, avenues 2 cells;
- landmarks (keep, cathedral, town hall, market hall) not hidden by taller buildings in front of them.

- [ ] **Step 1: Write the failing tests.**
  - No two structure rects overlap.
  - Every structure lies inside the map and off the river, except BRIDGE kinds.
  - Every one of the 73 GPT sets is placed at least once, except props.
  - About 140–180 houses in total.
- [ ] **Step 2:** Implement the plots.
- [ ] **Step 3:** Run the tests.
- [ ] **Step 4:** Add `town_debug --city=capital`, plus capture shots `capital_overview`, `capital_old_town`, `capital_harbour`, `capital_south`. Run them and read them.
- [ ] **Step 5:** Commit: `feat: capital plots: every district built from the GPT and town art sets`.

### Task 8: Capital floor, forest, decor, walk grid and reachability

**Files:**
- Modify `capital_city.gd`: `floor_areas()`, `street_props()`, `gardens()`, `queue_fans()`.
- Modify whatever in `TownFloor` or `TownDecor` turns out to still assume Aldermere geography. Fix it through `CityDef`, not special cases.

- [ ] **Step 1: Write the failing test** (Review Focus 2):
  - Build the walk grid for the capital.
  - Flood-fill from each exit.
  - Every anchor, routine point and spawn point is reachable.
  - Every district rect contains at least one reachable cell.
- [ ] **Step 2:** Implement until the test passes. Floor: streets, plazas, paving, fields and riverbanks. Forest ring and decor follow the city.
- [ ] **Step 3:** Run the tests and the M1 gates (Aldermere unchanged). Take the captures and read them.
- [ ] **Step 4:** Commit: `feat: capital ground, forest, decor and walk grid; every place reachable`.

### Task 9: M2 checkpoint (controller)

- Run the gates and take the captures.
- Make a desktop shortcut in `KAK Tests\4 Capital\` running `town_debug --city=capital`.
- Push, update the ledger, and stop for the user's review of the city's look.

---

## Milestone M3: new building types

### Task 10: Gameplay types for the GPT buildings

**Files:**
- Modify `src/environment/structure.gd`, only where a new kind or role needs behaviour.
- Create `src/game/town/building_types.gd`: a data table per `gpt_*` set.
- Test: `tests/test_building_types.gd`.

**Interfaces:**
- `BuildingTypes.info(tag: StringName) -> Dictionary` returns:
  - `kind`;
  - `hp`;
  - `walkable: bool`;
  - `flat: bool`;
  - `burns: bool`;
  - `smokes: bool`.
- Walkable or flat kinds: bridges, footbridge, district gate paving, tournament ground, fields, vineyard, fishpond rim (no), monument plinth (no).

- [ ] **Step 1: Write the failing tests.** For each type:
  - a hit damages it;
  - destroy reaches ruins;
  - burning types catch fire;
  - smoking types smoke from their chimney key;
  - walkable types are walkable on the walk grid.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the tests and the M1 gates.
- [ ] **Step 4:** Commit: `feat: capital building types: hp, fire, smoke, walkable kinds`.

---

## Milestone M4: people

### Task 11: Citizens, roles and routines

**Files:**
- Modify `capital_city.gd`:
  - `anchors()`, adding routine points `home`, `work`, `queue`, `wash`, `pray`, `market`, `harbour`, `gate` and `field`, by district;
  - a new method `func spawn_roles() -> Dictionary`, returning role → count per district, about 420 in total.
- Modify `src/game/crowd/citizen_profile.gd` and `src/game/crowd/crowd.gd`, only to read roles and points from the city.

New roles reuse the existing person designs, mapped like this:

| New role | Uses the design of |
|---|---|
| baker | merchant |
| washer | commoner |
| dockworker | labourer |
| monk | priest |
| noble | noble |
| beggar | commoner (ragged look) |

- [ ] **Step 1: Write the failing tests:**
  - a fixed-step capital crowd build spawns 400–440 citizens;
  - every role's points are reachable;
  - a 60 s calm run shows each routine visited at least once: bakery queue, wash house, harbour, chapel.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Add a deterministic `--scenario=capital_calm` to `behaviour_check.gd`, using `City.use(&"capital")`, and record its checksum.
- [ ] **Step 4:** Commit: `feat: capital citizens: 420 across districts with routines`.

### Task 12: Soldiers, alarm and evacuation

**Files:**
- Modify `capital_city.gd`: soldier posts, and exits per district.
- Modify `evacuation_manager.gd` and `alarm_manager.gd`, only to read from the city.

- [ ] **Step 1: Write the failing tests** (Review Focus 3):
  - about 180 soldiers at their posts;
  - an alarm in the old town evacuates through the gates and bridges;
  - destroying one bridge mid-evacuation reroutes its users to another crossing or the ferry, with nobody stuck and nobody entering the river cells.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Add a `--scenario=capital_evac` checksum.
- [ ] **Step 4:** Commit: `feat: capital soldiers and evacuation routes`.

---

## Milestone M5: frame rate

### Task 13: Profile

- [ ] **Step 1:** Add a capital bench mission entry: `--mission=capital_sandbox`, using the Task 15 mission definition. If needed, add a dev-only stub now.
- [ ] **Step 2:** Run the bench (3 pairs) plus a zoomed-out pass. Record the frame time split (crowd, structures, draw calls).
- [ ] **Step 3:** Write the findings in the ledger. No commit unless code changed.

### Task 14: Fix to 60 fps or better

Fix in profile order, cheapest first:
- people off screen think less often (a crowd LOD tick);
- wider structure sleep and culling;
- larger forest and plant bands;
- walk-grid path cache.

- [ ] **Step 1: Write a failing test per lever** (for example, the off-screen think rate halves the per-frame person updates in a test crowd).
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the bench:
  - the capital must reach 60 fps or better at the default zoom;
  - the zoomed-out pass is reported (Review Focus 5);
  - Aldermere must stay within about 3 fps of baseline;
  - the Aldermere checksums must be unchanged. A crowd LOD must not change Aldermere's deterministic results: gate it per city, or prove the checksums equal.
- [ ] **Step 4:** Commit per lever.

---

## Milestone M6: capital sandbox mission

### Task 15: Sandbox mission and board entry

**Files:**
- Modify `src/game/mission/mission_book.gd`: add `capital_sandbox` (`city = &"capital"`, every power, no objectives, a free-play timer like the Last Judgement skirmish).
- The board entry is dev-only: behind a flag or the existing dev list. Read how dev entries are shown.

- [ ] **Step 1: Write the failing tests:**
  - the mission exists;
  - it builds the capital;
  - ending it and starting an Aldermere mission builds Aldermere identically (Review Focus 1);
  - FLOW is unaffected.
- [ ] **Step 2:** Implement.
- [ ] **Step 3:** Run the full gates, FLOW and the bench.
- [ ] **Step 4:** Commit: `feat: capital sandbox mission (dev entry)`.

### Task 16: Wrap-up (controller)

- Final whole-branch review on the most capable model, then one fix wave and a re-review.
- Write a summary doc covering:
  - the gates;
  - the bench;
  - the city map capture;
  - what the campaign chapter can build on.
- Push and update the Dev Ledger.
- Stop for the user. Merging into Develop-Main follows the check-before-every-merge procedure and needs the user's yes.
