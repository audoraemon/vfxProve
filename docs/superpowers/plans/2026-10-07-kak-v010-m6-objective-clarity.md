# KAK v0.10 M6: Objective Clarity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Each Night 2 objective shows on the map as labelled tags with edge arrows. Every mission gets a one-line how-to-win under its objectives. Each Night 2 mission opens with a skippable camera tour of its key places.

**Architecture:**
- A `MapTag` value class: `MissionDirector.tags()` replaces v0.10's `marks()` and feeds one HUD layer. That layer lays out the diamonds, the labels (never overlapping) and the edge arrows.
- `MissionHints` holds the how-to-win lines, keyed by mission or act id and by phase. Each director reports its phase.
- `IntroTour` is a pure camera timeline. `Mission` plays it in place of the 2 s sweep when the director offers stops.

**Tech Stack:** Godot 4.7.2 GDScript. Headless test runner `tests/run_all.gd`. Behaviour scenarios in `tools/dev/behaviour_check.gd`. The FLOW test in `src/game/game.gd`.

**Spec:** `docs/superpowers/specs/2026-10-07-kak-v010-m6-objective-clarity-design.md`

## Global Constraints

- **Baseline:** branch `claude/lantern-campaign-spec` at `88ccb94` (`kak-v0.10`). The milestone tag `kak-v010-m6` is the controller's to set.
- **Text and drawn shapes only (spec §1):** no PixelLab, no new images, no new fonts.
- **Read only (spec §2.2, §6):**
  - `tags()`, `hint_phase()`, `tour()` and every new HUD function change no game state and draw no random numbers.
  - No director rule, number or timing changes.
  - The behaviour checksums below stay identical after every task.
- **Machine:** the BURIN_NITRO laptop.
  - Work in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` (Git Bash path `/c/BURIN_NITRO/...`) on `claude/lantern-campaign-spec`.
  - Never touch other sessions' worktrees.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands:**
  - **Import** (after a new `class_name` file or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`.
    - Expected: `checks=N failures=0`. The baseline at `88ccb94` is **3626**; each task adds to it. Report the count.
    - The `leaked` / `still in use` lines at exit are there at baseline too.
  - **Quick loop (optional):** the controller's SDD workspace holds `run_some.gd`, a copy of `run_all.gd` that runs only the suites named after `--`:
    - `timeout 600 $G --headless --path . -s <workspace>/run_some.gd -- res://tests/test_map_tags.gd`
    - Run the full Tests before each commit regardless.
  - **Night 2 references:** `timeout 600 $G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- <args>`.
    - Mira's House (exact): `--scenario=miras --case=play`.
      - Prints `BEHAVIOUR miras result won=false reason=gaze time=94.9 believers=3 gaze=100 reports=3`.
      - Prints `BEHAVIOUR checksum=-200101558`.
    - Broken Lanterns (exact): `--scenario=lanterns --case=none --seed=1`.
      - Prints `BEHAVIOUR lanterns result won=false reason=relit time=180.0 drained=0 relit=0 gaze=0 bonus=false`.
      - Prints `BEHAVIOUR checksum=424350965`.
    - Vigil Flame (outcome only; its time varies a little between runs): `--scenario=flame --case=none --seed=1`.
      - Prints `won=false reason=gaze` and `swapped=true seen=true`.
  - **FLOW:** `timeout 900 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`.
    - Expected: `FLOW result checks=N failures=0` (86 at baseline).
  - **Photos:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`.
    - Writes `captures/screen_<name>.png` at twice the 640x360 size.
  - **The full gates** (digest, `crowd_check`, the ten exact behaviour checksums, the mission test) are the controller's, at landing.
- **Style:**
  - Tabs. Static types.
  - A `##` doc comment on every new const, var and func, in full sentences, in the file's own voice, tagged "v0.10 M6".
  - Match the neighbouring code.
- **Commits:** one per task. End every message with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **A crowded view.**
   - The situation: zoomed out over Broken Lanterns, six shrine labels, the flame-bearer and four Knights in one view.
   - Expected: labels never overlap, and the shrines' labels, listed first, are the ones kept.
   - Pinned by: Task 1 `_labels` and Task 4 `_cast`.
2. **A tagged person dies or is freed mid-night** (a runner, Venn, Wren, a Knight).
   - Expected: their tag simply goes, with no error.
   - Pinned by: Tasks 3, 4 and 5.
3. **A tour stop has no one to show** (Venn dead before the start, no Vigil).
   - Expected: the stop is left out, and a director with no stops plays the old sweep.
   - Pinned by: Task 6 `_stops`.
4. **Skipping the tour.**
   - Expected: the press that skips it casts nothing and opens nothing, and Esc during the tour still pauses.
   - Pinned by: Task 6 `_skips` and the FLOW tour step.
5. **A restart of a Night 2 mission** (R, or Pause > Restart).
   - Expected: the tour plays again from the top, and no caption is left on screen once the camera lands.
   - Pinned by: the Task 6 FLOW tour step.

---

## File Structure

- **Created:**
  - `src/game/mission/map_tag.gd`: one thing the HUD points out (spec §2.1).
  - `src/game/mission/mission_hints.gd`: the how-to-win lines (spec §3).
  - `src/game/mission/intro_tour.gd`: the tour's timeline (spec §5).
  - `tests/test_map_tags.gd`, `tests/test_mission_hints.gd`, `tests/test_intro_tour.gd`.
- **Modified:**
  - `src/game/mission/mission_director.gd`:
    - `tags()` replaces `marks()`;
    - adds `hint_phase()`, `tour()` and `watchers()` / `_sees()`.
  - `src/game/ui/hud.gd`: the tag layer, the hint plate and the caption.
  - The three Night 2 directors (`miras_house_director.gd`, `broken_lanterns_director.gd`, `vigil_flame_director.gd`):
    - their tags, phases and tours;
    - their `marker()` overrides go.
  - `src/game/mission.gd`: plays the tour; adds `skip_intro()`.
  - `src/game/game.gd`:
    - the `--show` photos skip the tour; a new `--show=tour`;
    - FLOW gains `_past_intro()` and `_flow_tour()`.
  - Existing tests: `test_gaze.gd`, `test_hud.gd`, `test_miras_house.gd`, `test_broken_lanterns.gd`, `test_vigil_flame.gd`, and `tests/run_all.gd`.
  - Docs: `docs/KAK_Version_0.10_Summary.md`, `README.md`.

---

### Task 1: The map's tags: MapTag, the HUD's tag layer, `tags()` in place of `marks()`

**Files:**
- Create: `src/game/mission/map_tag.gd`, `tests/test_map_tags.gd`
- Modify: `src/game/mission/mission_director.gd` (the `marks()` func, lines 53-57)
- Modify: `src/game/ui/hud.gd`
- Modify: the three directors' `marks()` funcs (`miras_house_director.gd:256`, `broken_lanterns_director.gd:244`, `vigil_flame_director.gd:334`)
- Modify tests:
  - `test_gaze.gd:42-43`
  - `test_miras_house.gd:98, 119-120`
  - `test_broken_lanterns.gd:128-130, 146-147`
  - `test_vigil_flame.gd:165-167, 192-193, 217-218, 400-401`
  - `run_all.gd`

**Interfaces:**
- Consumes: `Iso.ground_to_screen(g: Vector2) -> Vector2`, `UiTheme.width(s, size)`, `Hud.EDGE_MARGIN`, `Hud.PLATE_H`.
- Produces:
  - **`MapTag`:**
    - vars: `at: Vector2`, `color: Color`, `label: String`, `rise: float`, `lift: float`, `size: float`, `edge: bool`, `outline: Rect2`;
    - consts: `PERSON_LIFT := 22.0`, `PLACE_LIFT := 8.0`, `SIZE := 4.0`, `PIP_SIZE := 3.0`;
    - constructors: `static person(at, color, label := "", edge := false) -> MapTag`, `static pip(at, color) -> MapTag`, `static place(at, color, label, rise := 0.0, edge := true) -> MapTag`;
    - `valid() -> bool`.
  - **`MissionDirector`:** `tags() -> Array[MapTag]`, empty by default. `marks()` is removed.
  - **`Hud`, static:**
    - `tags_shown(rules) -> bool`, replacing `marks_shown`;
    - `tag_point(t: MapTag, xf: Transform2D) -> Vector2`;
    - `on_screen(c: Vector2, view: Vector2) -> bool`;
    - `edge_point(point: Vector2, view: Vector2) -> Vector2`;
    - `label_rect(text: String, centre: Vector2, view: Vector2) -> Rect2`;
    - `tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2) -> Array`. Its entries are Dictionaries `{tag, c, mode, arrow, dir, label, show}`, with `mode` being `"map"`, `"arrow"` or `""`;
    - `mark_shape(c: Vector2, r := MARK_R)`.
  - **`Hud` consts:** `LABEL_GAP := 2.0`, `ARROW_REACH := 17.0`. `MARK_LIFT` is removed.

- [ ] **Step 1: Write the failing test.** Create `tests/test_map_tags.gd`:

```gdscript
extends RefCounted
## v0.10 M6 the map's tags (spec §2): MapTag's three kinds; where the HUD puts a tag's diamond and its label, and off
## screen its arrow; labels never overlap (the first placed stays, review focus 1) and stay inside the screen; a tag
## without a label or a point shows none.

const VIEW := Vector2(640.0, 360.0)
## The camera for these checks: the ground's origin at the screen's centre, no zoom.
const MID := Vector2(320.0, 180.0)


static func _tags(list: Array) -> Array[MapTag]:
	var out: Array[MapTag] = []
	out.assign(list)
	return out


static func run(t) -> void:
	_kinds(t)
	_points(t)
	_labels(t)
	_edge(t)


static func _kinds(t) -> void:
	var p := MapTag.person(Vector2(1.0, 2.0), Color.RED, "WREN", true)
	t.check(p.at == Vector2(1.0, 2.0) and p.color == Color.RED and p.label == "WREN" and p.edge and p.rise == 0.0
		and p.lift == MapTag.PERSON_LIFT and p.size == MapTag.SIZE and not p.outline.has_area(), "a person's tag")
	var bare := MapTag.person(Vector2.ZERO, Color.RED)
	t.check(not bare.edge and bare.label == "", "a person's tag has no label and no arrow unless asked")
	var pip := MapTag.pip(Vector2.ZERO, Color.RED)
	t.check(pip.label == "" and pip.size == MapTag.PIP_SIZE and pip.size < MapTag.SIZE and not pip.edge,
		"a pip: small and bare")
	var pl := MapTag.place(Vector2.ZERO, Color.GOLD, "TEMPLE", 40.0)
	t.check(pl.rise == 40.0 and pl.lift == MapTag.PLACE_LIFT and pl.edge and pl.label == "TEMPLE",
		"a place: raised, labelled, pointed at from the edge")
	t.check(not MapTag.place(Vector2.ZERO, Color.GOLD, "DOOR", 0.0, false).edge, "a place may go without its arrow")
	t.check(MapTag.SIZE == Hud.MARK_R and MapTag.PERSON_LIFT == 22.0, "a person's tag sits where v0.10's marks sat")
	t.check(p.valid() and not MapTag.person(Vector2.INF, Color.RED).valid(), "a tag at no point is not valid")


static func _points(t) -> void:
	var xf := Transform2D(0.0, MID)
	var pl := MapTag.place(Vector2.ZERO, Color.GOLD, "TEMPLE", 40.0)
	var want := (MID + Iso.ground_to_screen(Vector2.ZERO) - Vector2(0.0, 40.0 + MapTag.PLACE_LIFT)).round()
	t.check(Hud.tag_point(pl, xf) == want, "a place's diamond: up its rise, then its lift (%s)" % Hud.tag_point(pl, xf))
	var zoomed := Transform2D(0.0, Vector2(0.5, 0.5), 0.0, MID)
	var p := MapTag.person(Vector2.ZERO, Color.RED)
	var want_p := (MID + Iso.ground_to_screen(Vector2.ZERO) * 0.5 - Vector2(0.0, MapTag.PERSON_LIFT)).round()
	t.check(Hud.tag_point(p, zoomed) == want_p, "the lift is in screen pixels, whatever the zoom")
	var shape := Hud.mark_shape(Vector2(50.0, 50.0), MapTag.PIP_SIZE)
	t.check(shape[0] == Vector2(50.0, 50.0 - MapTag.PIP_SIZE) and shape[1] == Vector2(50.0 + MapTag.PIP_SIZE, 50.0),
		"a pip's diamond is its own size")


static func _labels(t) -> void:
	var xf := Transform2D(0.0, MID)
	var a := MapTag.person(Vector2.ZERO, Color.RED, "INQUISITOR")
	var b := MapTag.person(Vector2.ZERO, Color.RED, "TO THE TEMPLE")
	var bare := MapTag.person(Vector2.ZERO, Color.RED)
	var lay := Hud.tag_layout(_tags([bare, a, b]), xf, VIEW)
	t.check(lay.size() == 3 and String(lay[0].mode) == "map" and not bool(lay[0].show), "a bare tag shows no label")
	t.check(bool(lay[1].show) and not bool(lay[2].show) and String(lay[2].mode) == "map",
		"two labels at one point: the first stays, the second is left out, its diamond still shown (review focus 1)")
	var r: Rect2 = lay[1].label
	var c: Vector2 = lay[1].c
	t.check(r.end.y <= c.y - a.size and absf(r.get_center().x - c.x) <= 1.0
		and is_equal_approx(r.size.x, UiTheme.width("INQUISITOR", UiTheme.SIZE_SMALL) + 2.0),
		"a label sits centred above its diamond, as wide as its words (%s over %s)" % [r, c])
	var apart := Hud.tag_layout(_tags([a, MapTag.person(Vector2(0.0, 6.0), Color.RED, "WREN")]), xf, VIEW)
	t.check(bool(apart[0].show) and bool(apart[1].show), "labels apart both show")
	var edge_xf := Transform2D(0.0, Vector2(12.0, 180.0))
	var left := Hud.tag_layout(_tags([MapTag.person(Vector2.ZERO, Color.RED, "HALCYON'S FLAME")]), edge_xf, VIEW)
	var lr: Rect2 = left[0].label
	t.check(String(left[0].mode) == "map" and lr.position.x == 0.0 and Rect2(Vector2.ZERO, VIEW).encloses(lr),
		"a label by the screen's edge is kept inside it (%s)" % lr)
	t.check(Hud.tag_layout(_tags([MapTag.person(Vector2.INF, Color.RED, "X")]), xf, VIEW).is_empty(),
		"a tag at no point is left out")


static func _edge(t) -> void:
	var xf := Transform2D(0.0, MID)
	var far := Vector2(400.0, 0.0)
	var off := MapTag.person(far, Color.RED, "WREN")
	var arrow := MapTag.person(far, Color.RED, "WREN", true)
	var lay := Hud.tag_layout(_tags([off, arrow]), xf, VIEW)
	t.check(String(lay[0].mode) == "" and not bool(lay[0].show), "off screen without an arrow: nothing shown")
	var at: Vector2 = lay[1].arrow
	t.check(String(lay[1].mode) == "arrow" and Rect2(Vector2.ZERO, VIEW).grow(-Hud.EDGE_MARGIN + 0.5).has_point(at)
		and at.distance_to(Hud.edge_point(Hud.tag_point(arrow, xf), VIEW)) < 0.01,
		"off screen with one: an arrow at the edge, pointing its way (%s)" % at)
	var lr: Rect2 = lay[1].label
	t.check(bool(lay[1].show) and Rect2(Vector2.ZERO, VIEW).encloses(lr) and not lr.has_point(at),
		"its label beside it, inside the screen, clear of the tip (%s)" % lr)
	t.check(Hud.on_screen(MID, VIEW) and not Hud.on_screen(Vector2(-5.0, 180.0), VIEW)
		and not Hud.on_screen(Vector2(5.0, 180.0), VIEW), "on screen means inside the edge's margin")
```

- [ ] **Step 2: Move the existing tests from `marks()` to `tags()`.**
  - Each `marks()` entry `[Vector2, Color]` becomes a `MapTag`: `m[0]` is `m.at` and `m[1]` is `m.color`. Loop with `for m in d.tags():` (no `: Array` type).
  - Exactly:
    - `test_gaze.gd:42-43`:

```gdscript
	t.check(MissionDirector.new().tags().is_empty(), "a director tags nothing by default")
	t.check(not Hud.tags_shown(rules), "with nothing tagged the HUD can stay a still picture")
```

    - `test_miras_house.gd:98`: `t.check(d.tags().size() == MirasHouseDirector.GRIEVING, "the HUD marks the grieving")`
    - `test_miras_house.gd:119-120`:

```gdscript
	for m in d.tags():
		marked_believer = marked_believer or (m.at == g.ground_pos and m.color == MirasHouseDirector.MARK_BELIEVER)
```

    - `test_broken_lanterns.gd:128-130`:

```gdscript
	var lit := d.tags().size() == 6
	for m in d.tags():
		lit = lit and m.color == BrokenLanternsDirector.MARK_LIT
```

    - `test_broken_lanterns.gd:146-147`:

```gdscript
	for m in d.tags():
		ember = ember or (m.at == sh.center() and m.color == BrokenLanternsDirector.MARK_DRAINING)
```

    - `test_vigil_flame.gd:165-167`:

```gdscript
	var marks := d.tags()
	t.check(marks.size() == 2 and marks[0].color == VigilFlameDirector.MARK_SHRINE
		and marks[1].at == d.vigil.bearer.ground_pos and marks[1].color == VigilFlameDirector.MARK_FLAME,
```

    - `test_vigil_flame.gd:192-193`:

```gdscript
	for m in d.tags():
		seen = seen or (m.at == w.ground_pos and m.color == VigilFlameDirector.MARK_WREN)
```

    - `test_vigil_flame.gd:217-218`:

```gdscript
	for m in d.tags():
		lantern_marked = lantern_marked or m.color == VigilFlameDirector.MARK_FLAME
```

    - `test_vigil_flame.gd:400-401`:

```gdscript
	for m in d.tags():
		marked = marked or (m.at == fell and m.color == VigilFlameDirector.MARK_FLAME)
```

  - Add `"res://tests/test_map_tags.gd",` to `SUITES` in `tests/run_all.gd`, after `"res://tests/test_cael_lines.gd",`.

- [ ] **Step 3: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `MapTag` or `tags`.

- [ ] **Step 4: Create `src/game/mission/map_tag.gd`:**

```gdscript
class_name MapTag
extends RefCounted
## One thing the HUD points out on the map (v0.10 M6, spec §2.1): a coloured diamond over a ground point, raised by
## `rise` world pixels (a building's height) and then `lift` screen pixels, with a label above it if it has one, the
## outline of a ground footprint if it has one, and -- with `edge` -- an arrow at the screen's edge while it is off
## screen. A director makes them in MissionDirector.tags(); the HUD draws them (Hud._draw_tags()).

## A person's diamond sits this far above their feet (v0.10's marks); a place's, this far above its top (screen px).
const PERSON_LIFT := 22.0
const PLACE_LIFT := 8.0
## A diamond's half size, and a crowd pip's.
const SIZE := 4.0
const PIP_SIZE := 3.0

## The ground point (ground units).
var at := Vector2.ZERO
## The diamond's, the label's and the arrow's colour.
var color := Color.WHITE
## A few words in upper case; "" for a plain mark.
var label := ""
## World pixels above the ground point: a building's height (Structure.height), 0 for a person or a spot.
var rise := 0.0
## Screen pixels above that.
var lift := PERSON_LIFT
## The diamond's half size.
var size := SIZE
## Off screen, an arrow at the screen's edge points to it.
var edge := false
## A ground footprint to outline (Mira's house); an empty Rect2 for none.
var outline := Rect2()


## A person: a diamond over the head, labelled if given, pointed at from the edge if asked.
static func person(p_at: Vector2, p_color: Color, p_label := "", p_edge := false) -> MapTag:
	var t := MapTag.new()
	t.at = p_at
	t.color = p_color
	t.label = p_label
	t.edge = p_edge
	return t


## One of a crowd: a small diamond, no label.
static func pip(p_at: Vector2, p_color: Color) -> MapTag:
	var t := person(p_at, p_color)
	t.size = PIP_SIZE
	return t


## A place: a labelled diamond `p_rise` world pixels up (a building's height; 0 on the ground) and PLACE_LIFT over that,
## pointed at from the edge unless told not to be.
static func place(p_at: Vector2, p_color: Color, p_label: String, p_rise := 0.0, p_edge := true) -> MapTag:
	var t := person(p_at, p_color, p_label, p_edge)
	t.rise = p_rise
	t.lift = PLACE_LIFT
	return t


## The HUD can draw it: its point is a real one (not Vector2.INF).
func valid() -> bool:
	return at.is_finite()
```

- [ ] **Step 5: `MissionDirector.tags()`.** In `src/game/mission/mission_director.gd`, replace the `marks()` func and its comment (lines 53-57) with:

```gdscript
## What the HUD points out on the map (v0.10 M6, spec §2.2): MapTags, the most important first -- a label that would
## overlap one before it is left out. None by default. Only reads: it changes nothing and draws no random numbers.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	return out
```

- [ ] **Step 6: The HUD's tag layer.** In `src/game/ui/hud.gd`:
  - Replace the `MARK_LIFT` / `MARK_R` / `MARK_EDGE` block (its comment, lines 48-52) with:

```gdscript
## A tag's diamond (v0.10's marks; M6's tags, MapTag): its half size unless the tag sets its own, and its dark edge (M5
## doubled it and gave it an edge, so it reads on the cobbles). Tags are drawn first, under the rest of the HUD; their
## edge arrows last, over it.
const MARK_R := 4.0
const MARK_EDGE := Color(0.04, 0.04, 0.06, 0.9)
## A tag's label (v0.10 M6) stands this far above its diamond; an edge arrow's label starts this far in from its tip, past
## the arrow's disc.
const LABEL_GAP := 2.0
const ARROW_REACH := 17.0
```

  - Add after `var _slot_names`:

```gdscript
## The tags' layout for the frame being drawn (v0.10 M6, tag_layout()): placed by _draw_tags() and shared with
## _draw_tag_arrows(), so the arrows' labels keep clear of the map's.
var _layout: Array = []
```

  - In `advance()`, replace `marks_shown(_rules)` with `tags_shown(_rules)`.
  - Replace `marks_shown()` and its comment with:

```gdscript
## The director tags something (v0.10 M6): the tags follow people and the camera, so the HUD redraws every frame.
static func tags_shown(rules: Rules) -> bool:
	return rules != null and rules.director != null and not rules.director.tags().is_empty()
```

  - Replace `_draw_marks()` and `mark_shape()` (with their comments) with:

```gdscript
## The tags on the map (v0.10 M6, spec §2.3): each one's footprint outline, then, while on screen, its diamond and its
## label. Lays the frame's tags out first (tag_layout()).
func _draw_tags() -> void:
	_layout = []
	if _rules.director == null:
		return
	var xf := get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY
	_layout = tag_layout(_rules.director.tags(), xf, _view())
	for e: Dictionary in _layout:
		var t: MapTag = e.tag
		if t.outline.has_area():
			_draw_outline(t.outline, xf, t.color)
		if String(e.mode) != "map":
			continue
		var shape := mark_shape(e.c, t.size)
		draw_colored_polygon(shape, t.color)
		shape.append(shape[0])
		draw_polyline(shape, MARK_EDGE, 1.0)
		if bool(e.show):
			_plate((e.label as Rect2).position, t.label, t.color)


## The tags off screen (v0.10 M6): an arrow at the edge for each, its label beside it. Drawn last, over the HUD.
func _draw_tag_arrows() -> void:
	for e: Dictionary in _layout:
		if String(e.mode) != "arrow":
			continue
		var t: MapTag = e.tag
		_draw_arrow(e.arrow, e.dir, t.color, t.color.darkened(0.4))
		if bool(e.show):
			_plate((e.label as Rect2).position, t.label, t.color)


## A ground footprint's outline (v0.10 M6): its diamond on the ground, through the camera `xf`, 1 px in `col`.
func _draw_outline(r: Rect2, xf: Transform2D, col: Color) -> void:
	var pts := PackedVector2Array()
	for g: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]:
		pts.append((xf * Iso.ground_to_screen(g)).round())
	draw_polyline(pts, col, 1.0)


## The diamond a tag is drawn as, centred on `c` (screen pixels), `r` each way.
static func mark_shape(c: Vector2, r := MARK_R) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0.0, -r), c + Vector2(r, 0.0), c + Vector2(0.0, r), c + Vector2(-r, 0.0)])


## Where a tag's diamond sits on screen (v0.10 M6): its ground point raised `rise` world pixels, through the camera `xf`,
## then `lift` screen pixels up.
static func tag_point(t: MapTag, xf: Transform2D) -> Vector2:
	return (xf * (Iso.ground_to_screen(t.at) - Vector2(0.0, t.rise)) - Vector2(0.0, t.lift)).round()


## A screen point is in the frame, EDGE_MARGIN in from its edge (v0.10 M6).
static func on_screen(c: Vector2, view: Vector2) -> bool:
	return Rect2(Vector2.ZERO, view).grow(-EDGE_MARGIN).has_point(c)


## A label's plate (v0.10 M6): as wide as its words, PLATE_H tall, centred on `centre` and kept inside the screen.
static func label_rect(text: String, centre: Vector2, view: Vector2) -> Rect2:
	var box := Vector2(UiTheme.width(text, UiTheme.SIZE_SMALL) + 2.0, PLATE_H)
	var at := (centre - box * 0.5).round()
	return Rect2(at.clamp(Vector2.ZERO, (view - box).max(Vector2.ZERO)), box)


## Where each tag goes this frame (v0.10 M6, spec §2.3), in the tags' order, as {tag, c, mode, arrow, dir, label, show}.
## - `c`: its diamond's centre on screen.
## - `mode`: "map" on screen; "arrow" off screen with an edge arrow (`arrow` is its tip and `dir` its heading); "" off
##   screen without one (only its outline may show).
## - `label`: its label's plate.
## - `show`: the label is drawn. Not when it has none, nor when its plate would overlap one placed before it (review focus
##   1), which is why a director lists its most important tags first.
## A tag at no point is left out.
static func tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2) -> Array:
	var out := []
	var placed: Array[Rect2] = []
	for t in tags:
		if not t.valid():
			continue
		var c := tag_point(t, xf)
		var e := {"tag": t, "c": c, "mode": "", "arrow": Vector2.INF, "dir": Vector2.ZERO, "label": Rect2(), "show": false}
		if on_screen(c, view):
			e.mode = "map"
			e.label = label_rect(t.label, c - Vector2(0.0, t.size + LABEL_GAP + PLATE_H * 0.5), view)
		elif t.edge:
			var tip := edge_point(c, view)
			var d := (c - view * 0.5).normalized()
			var reach := ARROW_REACH + absf(d.x) * (UiTheme.width(t.label, UiTheme.SIZE_SMALL) + 2.0) * 0.5 \
				+ absf(d.y) * PLATE_H * 0.5
			e.mode = "arrow"
			e.arrow = tip
			e.dir = d
			e.label = label_rect(t.label, tip - d * reach, view)
		if String(e.mode) != "" and t.label != "":
			var r: Rect2 = e.label
			var clear := true
			for p in placed:
				clear = clear and not r.intersects(p)
			if clear:
				placed.append(r)
				e.show = true
		out.append(e)
	return out
```

  - Replace the body of `edge_arrow()` (keep its comment) and add `edge_point()` after it:

```gdscript
func edge_arrow(point: Vector2) -> Vector2:
	return edge_point(point, _view())


## edge_arrow() for a screen `view` wide and tall (v0.10 M6: static, for tag_layout()).
static func edge_point(point: Vector2, view: Vector2) -> Vector2:
	var mid := view * 0.5
	var d := point - mid
	var half := mid - Vector2.ONE * EDGE_MARGIN
	var k := 1.0
	if absf(d.x) > half.x:
		k = half.x / absf(d.x)
	if absf(d.y) * k > half.y:
		k = half.y / absf(d.y)
	return mid + d * k
```

  - In `_draw_marker()`, replace everything from `var dark := ...` to the end with the code below. Then add `_draw_arrow()` after it. `MARK_EDGE` is the same colour `dark` was, so the marker draws exactly as before.

```gdscript
	if Rect2(Vector2.ZERO, view).grow(-EDGE_MARGIN).has_point(tip):
		var down := PackedVector2Array([tip + Vector2(-5.0, -7.0), tip + Vector2(5.0, -7.0), tip])
		draw_colored_polygon(down, UiTheme.COL_GOLD)
		down.append(down[0])
		draw_polyline(down, MARK_EDGE, -1.0)
		return
	_draw_arrow(edge_arrow(tip), (tip - view * 0.5).normalized(), UiTheme.COL_GOLD, UiTheme.COL_GOLD_DARK)


## An arrow at the screen's edge (v0.08's marker; v0.10 M6's tags): `col` on a dark disc ringed in `ring`, its tip at
## `at`, pointing along `dir`. On a dark disc, so it stands out from the town's warm roofs and stalls.
func _draw_arrow(at: Vector2, dir: Vector2, col: Color, ring: Color) -> void:
	var side := Vector2(-dir.y, dir.x)
	draw_circle(at - dir * 5.0, 10.0, MARK_EDGE)
	draw_arc(at - dir * 5.0, 10.0, 0.0, TAU, 24, ring, -1.0)
	var arrow := PackedVector2Array([at, at - dir * 10.0 + side * 6.0, at - dir * 10.0 - side * 6.0])
	draw_colored_polygon(arrow, col)
	arrow.append(arrow[0])
	draw_polyline(arrow, MARK_EDGE, -1.0)
```

  - In `_draw()`:
    - Replace its first comment and `_draw_marks()` with:

```gdscript
	# The tags on the map (v0.10; M6) are drawn first, so they sit under every other HUD element -- the clock, the bars,
	# the events, the objectives, the status, the banners, Cael's plate, the slots and the marker -- and never hide one.
	_draw_tags()
```

    - After the closing `_draw_marker()` line, add:

```gdscript
	# Last of all, the tags' edge arrows (v0.10 M6), as the marker's.
	_draw_tag_arrows()
```

- [ ] **Step 7: Port the three directors.**
  - Each `marks()` becomes `tags()`. The same marks become `MapTag.person` tags with no label, so nothing on screen moves yet.
  - In `miras_house_director.gd`, replace `marks()` with:

```gdscript
## The tags (v0.10 M6): the grieving, and the Believers among them.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p in grieving:
		if _alive(p) and not p.inside:
			out.append(MapTag.person(p.ground_pos, MARK_BELIEVER if believers.has(p) else MARK_GRIEVING))
	return out
```

  - In `broken_lanterns_director.gd`, replace `marks()` with:

```gdscript
## The tags (v0.10 M6): the standing shrines, and the broken ones still draining.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for s in shrines:
		if not s.destroyed:
			out.append(MapTag.person(s.center(), MARK_LIT))
		elif drain_left.has(s):
			out.append(MapTag.person(s.center(), MARK_DRAINING))
	return out
```

  - In `vigil_flame_director.gd`, replace `marks()` with:

```gdscript
## The tags (v0.10 M6): Mira's shrine, the real flame while in its lantern, and Wren once he has come.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = [MapTag.person(shrine, MARK_SHRINE)]
	if not swapped and _lantern != Vector2.INF:
		out.append(MapTag.person(_lantern, MARK_FLAME))
	if appeared and _alive(wren) and not wren.inside:
		out.append(MapTag.person(wren.ground_pos, MARK_WREN))
	return out
```

  - Search for any other caller: `grep -rn "marks()\|marks_shown\|MARK_LIFT" src tests tools` must print nothing.

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by the new checks (about 3646).

- [ ] **Step 9: The references.** Run the Mira's House and Broken Lanterns references. Expected: identical to Global Constraints.

- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/map_tag.gd src/game/mission/mission_director.gd src/game/ui/hud.gd src/game/mission/miras_house_director.gd src/game/mission/broken_lanterns_director.gd src/game/mission/vigil_flame_director.gd tests/test_map_tags.gd tests/run_all.gd tests/test_gaze.gd tests/test_miras_house.gd tests/test_broken_lanterns.gd tests/test_vigil_flame.gd
git commit -m "feat: map tags -- MapTag and the HUD's tag layer, in place of marks (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Also add any `.uid` files Godot made for the new scripts: `git add src/game/mission/map_tag.gd.uid tests/test_map_tags.gd.uid` if they exist.)

---

### Task 2: How to win: a line under the objectives for every mission

**Files:**
- Create: `src/game/mission/mission_hints.gd`, `tests/test_mission_hints.gd`
- Modify: `src/game/mission/mission_director.gd`, `src/game/ui/hud.gd`, `tests/test_hud.gd`, `tests/run_all.gd`

**Interfaces:**
- Consumes: `Hud` from Task 1. `MissionDef.id`, `MissionDef.has_acts()`, `MissionDef.acts`. The `MissionBook` makers.
- Produces:
  - **`MissionHints`:** `const LINES: Dictionary`, `const WARNING_LINE: String`, `static line(id: String, phase := "") -> String`.
  - **`MissionDirector`:** `hint_phase() -> String`, `""` by default.
  - **`Hud`:**
    - consts: `HINT_W := 228.0`, `HINT_LINES := 3`, `HINT_COL`;
    - `hint_text() -> String`, `static hint_lines(text: String) -> PackedStringArray`, `hint_top() -> float`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_mission_hints.gd`:

```gdscript
extends RefCounted
## v0.10 M6 how to win (spec §3): the lines are the spec's, word for word; a phase's line, the fallbacks; a line for every
## mission and act the game plays; and each fits the HUD's plate (HINT_LINES lines of HINT_W).

## The spec's table: [key, line].
const SPEC := [
	["warning", "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."],
	["omen", "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."],
	["festival", "Break the festival: kill or scatter fifty of its crowd before the guard closes the square."],
	["procession", "Kill the Prince before he boards his ship. If no one sees him die, the town is left leaderless."],
	["judgement", "Bring the Citadel down before dawn, before too many of its people escape."],
	["last_judgement", "Destroy the Citadel and break the city before time runs out. Fifty escaping loses it."],
	["miras_house", "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn."],
	["miras_house.four", "Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling."],
	["miras_house.burning", "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn."],
	["broken_lanterns", "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six."],
	["broken_lanterns.knights", "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike."],
	["vigil_flame", "At 0:50 the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first."],
	["vigil_flame.wren", "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red)."],
	["vigil_flame.homeward", "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple."],
	["vigil_flame.carry", "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight."],
]


static func run(t) -> void:
	var spec := {}
	var wrong := PackedStringArray()
	for row: Array in SPEC:
		spec[row[0]] = row[1]
		if String(MissionHints.LINES.get(row[0], "")) != String(row[1]):
			wrong.append(String(row[0]))
	t.check(wrong.is_empty() and MissionHints.LINES.size() == SPEC.size(),
		"the lines are the spec's (wrong: %s; %d lines)" % [", ".join(wrong), MissionHints.LINES.size()])
	t.check(MissionHints.line("miras_house", "burning") == spec["miras_house.burning"], "a phase's own line")
	t.check(MissionHints.line("miras_house", "dawn") == spec["miras_house"] and MissionHints.line("miras_house") == spec["miras_house"],
		"a phase with no line of its own, or none, gives the mission's")
	t.check(MissionHints.line("nowhere") == "" and MissionHints.line("nowhere", "burning") == "", "an unknown mission has none")

	# Every mission and act the game plays: the board's, the campaign's, The Long Night's acts and the Feast's.
	var played: Array[MissionDef] = []
	for m: MissionDef in [MissionBook.warning(), MissionBook.long_night(), MissionBook.last_judgement(),
			MissionBook.miras_house(), MissionBook.vigil_flame(), MissionBook.broken_lanterns(), MissionBook.feast("festival"),
			MissionBook.feast("procession")]:
		if m.has_acts():
			for a in m.acts:
				played.append(a)
		else:
			played.append(m)
	var missing := PackedStringArray()
	for m in played:
		if MissionHints.line(m.id) == "":
			missing.append(m.id)
	t.check(missing.is_empty(), "every mission and act played has a line (missing: %s)" % ", ".join(missing))

	var long := PackedStringArray()
	for key: String in MissionHints.LINES:
		if UiTheme.wrap(String(MissionHints.LINES[key]), Hud.HINT_W, UiTheme.SIZE_SMALL).size() > Hud.HINT_LINES:
			long.append(key)
	t.check(long.is_empty(), "every line fits %d lines of %d px (too long: %s)" % [Hud.HINT_LINES, int(Hud.HINT_W),
		", ".join(long)])
	t.check(Hud.hint_lines("").is_empty() and Hud.hint_lines(spec["miras_house"]).size() == Hud.HINT_LINES,
		"no line, no plate; Mira's House's takes the plate's three lines")
	t.check(MissionDirector.new().hint_phase() == "", "a director has no phase of its own by default")
```

  - In `tests/test_hud.gd`, after the check on `hud.objective_text()` (the one that names "Royal Citadel"), add:

```gdscript
	# How to win (v0.10 M6): Last Judgement's line, under its objective panel.
	t.check(hud.hint_text() == MissionHints.line(MissionBook.LAST_JUDGEMENT) and hud.hint_text() != ""
		and hud.hint_top() == Hud.OBJECTIVE_PANEL.end.y + 4.0, "the how-to-win line, under the objectives (%s)" % hud.hint_text())
```

  - Add `"res://tests/test_mission_hints.gd",` to `SUITES` after `"res://tests/test_map_tags.gd",`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `MissionHints`, `hint_text` or `hint_phase`.

- [ ] **Step 3: Create `src/game/mission/mission_hints.gd`:**

```gdscript
class_name MissionHints
extends RefCounted
## How to win, in a line (v0.10 M6, spec §3): the HUD shows the line for the mission or act being played under its
## objectives, and a director's phase (MissionDirector.hint_phase()) can put another in its place. Kept apart from the
## logic, as CampaignText is, so a writing change never touches it. The colours named are the map tags' (spec §4).

## The Warning's line, which its act in The Long Night shares.
const WARNING_LINE := "Stop the messenger (gold arrow) before the bell tolls, or hold out until the omen fades."
## Lines by the played mission's or act's id, and by "<id>.<phase>" for a phase's own. The Feast plays The Long Night's
## act, so it has the act's line.
const LINES := {
	"warning": WARNING_LINE,
	"omen": WARNING_LINE,
	"festival": "Break the festival: kill or scatter fifty of its crowd before the guard closes the square.",
	"procession": "Kill the Prince before he boards his ship. If no one sees him die, the town is left leaderless.",
	"judgement": "Bring the Citadel down before dawn, before too many of its people escape.",
	"last_judgement": "Destroy the Citadel and break the city before time runs out. Fifty escaping loses it.",
	"miras_house": "Whisper a grieving (gold) to Mira's door while no Faithful (red) watches. Four must believe by dawn.",
	"miras_house.four": "Four believe. Keep the Believers (orange) alive until dawn, and the Gaze from filling.",
	"miras_house.burning": "Her house burns: no one can go in now. Keep your Believers (orange) alive until dawn.",
	"broken_lanterns": "Break a lantern (gold), then keep the flame-bearer off it for 20 s while it drains. Drain all six.",
	"broken_lanterns.knights": "A Knight (blue) shields the lantern he guards. Draw him off or kill him, then strike.",
	"vigil_flame": "At 0:50 the boy Wren comes for the flame (gold). Its acolytes would see him: draw them off first.",
	"vigil_flame.wren": "Whisper Wren (blue) to the flame (gold) while no Faithful but its bearer is near him (red).",
	"vigil_flame.homeward": "The Vigil turns for home: have the flame swapped before its bearer reaches the Temple.",
	"vigil_flame.carry": "Walk Wren to Mira's shrine (orange), west past the wall. Keep him out of the searchlight.",
}


## The line for the mission or act `id` in `phase`: the phase's own if it has one, else the mission's, else "".
static func line(id: String, phase := "") -> String:
	if phase != "" and LINES.has(id + "." + phase):
		return String(LINES[id + "." + phase])
	return String(LINES.get(id, ""))
```

- [ ] **Step 4: `MissionDirector.hint_phase()`.** Add after `tags()`:

```gdscript
## Virtual (v0.10 M6, spec §3): the phase whose how-to-win line the HUD shows (MissionHints), "" for the mission's own.
func hint_phase() -> String:
	return ""
```

- [ ] **Step 5: The HUD's hint.** In `src/game/ui/hud.gd`:
  - Add after `EDGE_MARGIN`:

```gdscript
## How to win (v0.10 M6, spec §3): a line under the objectives, wrapped to HINT_W, at most HINT_LINES lines, pale gold.
const HINT_W := 228.0
const HINT_LINES := 3
const HINT_COL := Color("e8d690")
```

  - Add after `event_rows()`:

```gdscript
## The how-to-win line for the mission or act being played, in its director's phase (v0.10 M6, MissionHints); "" for
## none.
func hint_text() -> String:
	if _rules == null or _rules.mission == null:
		return ""
	return MissionHints.line(_rules.mission.id, _rules.director.hint_phase() if _rules.director != null else "")


## The how-to-win line as drawn (v0.10 M6): wrapped to HINT_W, at most HINT_LINES lines; none for no line.
static func hint_lines(text: String) -> PackedStringArray:
	if text == "":
		return PackedStringArray()
	return UiTheme.wrap(text, HINT_W, UiTheme.SIZE_SMALL).slice(0, HINT_LINES)


## Where the how-to-win plate starts (v0.10 M6): under the objective panel of a scored mission, else under the objective
## rows (at the top with none).
func hint_top() -> float:
	if _rules.mission.scored:
		return OBJECTIVE_PANEL.end.y + 4.0
	var rows := objective_rows().size()
	return 2.0 + (5.0 + ROW_H * float(rows) + 4.0 if rows > 0 else 0.0)
```

  - Add after `_draw_rows()`:

```gdscript
## The how-to-win line (v0.10 M6) on its own dark plate under the objectives, in HINT_COL.
func _draw_hint() -> void:
	var lines := hint_lines(hint_text())
	if lines.is_empty():
		return
	var wide := 0.0
	for l in lines:
		wide = maxf(wide, UiTheme.width(l, UiTheme.SIZE_SMALL))
	var top := hint_top()
	draw_rect(Rect2(2.0, top, wide + 10.0, 5.0 + UiTheme.LINE_SMALL * float(lines.size())), UiTheme.COL_PANEL)
	var y := top + 12.0
	for l in lines:
		UiTheme.text(self, Vector2(6.0, y), l, UiTheme.SIZE_SMALL, HINT_COL)
		y += UiTheme.LINE_SMALL
```

  - In `_draw()`, call `_draw_hint()` right after the `if _rules.mission.scored: ... else: _draw_rows()` block.
  - In `_signature()`, after the events are added, add `out += "|" + hint_text()`, so a phase change redraws a still HUD.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`.

- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/mission_hints.gd src/game/mission/mission_director.gd src/game/ui/hud.gd tests/test_mission_hints.gd tests/test_hud.gd tests/run_all.gd
git commit -m "feat: how to win -- a line under the objectives for every mission (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Add the new scripts' `.uid` files if Godot made them.)

---

### Task 3: Mira's House tags: the house, its door, the Inquisitor, runners

**Files:**
- Modify: `src/game/mission/mission_director.gd`: `watchers()`, `_sees()`, and `faithful_seeing()` on top of them.
- Modify: `src/game/mission/miras_house_director.gd`: the tags, `hint_phase()`; `marker()` goes.
- Modify: `tests/test_miras_house.gd`

**Interfaces:**
- Consumes: `MapTag` and `tags()` (Task 1). `hint_phase()` and `Hud.hint_text()` / `hint_top()` (Task 2). `BelieversObjective.NEED`.
- Produces:
  - **`MissionDirector`:**
    - `watchers(at: Vector2, reach: float, exclude: Person = null) -> Array[Person]`;
    - `_sees(f: Person, at: Vector2, reach: float, exclude: Person) -> bool`.
  - **`MirasHouseDirector`:**
    - consts `MARK_HOUSE`, `MARK_CLEAR`, `MARK_WATCHED`, `MARK_VENN`;
    - `hint_phase()` returns `"burning"`, `"four"` or `""`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_miras_house.gd`:
  - Add this helper after `_bring()`:

```gdscript
## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null
```

  - Add `_tags(t)` to `run()`, after `_lines(t)`, and this function:

```gdscript
## v0.10 M6 (spec §4.1): the map's tags -- the house first, named, outlined and pointed at from the edge; its door clear
## or watched, a red diamond on each watcher; the Inquisitor, pointed at while she searches; a runner and the Temple
## while a report runs; the crying Believer, pointed at; no door once the house burns, no house once it falls; nobody
## dead is tagged (review focus 2); the hint's phases, as the HUD shows them.
static func _tags(t) -> void:
	var s := _setup()
	var d: MirasHouseDirector = s.d
	var house: MapTag = d.tags()[0]
	t.check(house.label == "MIRA'S HOUSE" and house.at == d.house.center() and house.rise == d.house.height
		and house.edge and house.outline == d.house.footprint and house.color == MirasHouseDirector.MARK_HOUSE,
		"the house comes first: named, outlined, pointed at from the edge")
	_blind(d, d.door)
	var door := _tag(d, "DOOR - CLEAR")
	t.check(door != null and door.at == d.door and not door.edge and door.color == MirasHouseDirector.MARK_CLEAR,
		"no Faithful in sight: the door is clear")
	var f: Person = null
	for p in d.faithful:
		if p != d.venn and p.is_alive():
			f = p
			break
	_arrive(f, d.door + Vector2(1.0, 0.0))
	var red := false
	for m in d.tags():
		red = red or (m.at == f.ground_pos and m.color == MirasHouseDirector.MARK_WATCHED and m.label == "")
	t.check(_tag(d, "DOOR - WATCHED") != null and _tag(d, "DOOR - CLEAR") == null and red,
		"a Faithful by it: the door is watched, and the watcher marked red")
	var venn := _tag(d, "INQUISITOR")
	t.check(venn != null and venn.at == d.venn.ground_pos and venn.color == MirasHouseDirector.MARK_VENN and not venn.edge,
		"the Inquisitor is named; no arrow before her search")
	d._report(f, d.temple_door)
	var runner := _tag(d, "TO THE TEMPLE")
	var temple := _tag(d, "TEMPLE")
	t.check(runner != null and runner.at == f.ground_pos and runner.edge and temple != null and temple.at == d.temple_door
		and temple.edge, "a report on its way: the runner and the Temple, both pointed at from the edge")
	d.reports.clear()
	t.check(_tag(d, "TO THE TEMPLE") == null and _tag(d, "TEMPLE") == null, "no report running: neither")
	var g := d.grieving[0]
	d.believers.append(g)
	d.shouter = g
	var cry := _tag(d, "CRYING OUT")
	t.check(cry != null and cry.at == g.ground_pos and cry.edge and d.marker() == Vector2.INF,
		"the crying Believer is tagged and pointed at (the director keeps no marker of its own)")
	(s.crowd as Crowd)._field.kill(g, &"fire")
	t.check(_tag(d, "CRYING OUT") == null, "dead, they are not tagged (review focus 2)")
	t.check(d.hint_phase() == "", "fewer than four believe: the mission's own line")
	for i in range(1, 1 + BelieversObjective.NEED):
		d.believers.append(d.grieving[i])
	t.check(d.hint_phase() == "four", "four Believers out: the hint says keep them")
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	t.check(hud.hint_text() == MissionHints.line(MissionBook.MIRAS_HOUSE, "four") and hud.hint_top() > Hud.ROW_H,
		"the HUD shows the phase's line, under the objective rows")
	hud.free()
	_run(s, MirasHouseDirector.VENN_AT + DT)
	t.check(d.venn_searching and _tag(d, "INQUISITOR") != null and _tag(d, "INQUISITOR").edge,
		"searching, the Inquisitor is pointed at from the edge")
	(s.crowd as Crowd)._field.kill(d.venn, &"fire")
	t.check(_tag(d, "INQUISITOR") == null, "struck down, she is not tagged (review focus 2)")
	d._burn()
	t.check(_tag(d, "DOOR - CLEAR") == null and _tag(d, "DOOR - WATCHED") == null and d.hint_phase() == "burning",
		"the house burning: no door, and the hint says so")
	d.house.destroy(d.house.center(), &"fire")
	t.check(_tag(d, "MIRA'S HOUSE") == null, "the house gone, its tag goes")
	_done(s)
```

  - In `_cast`, replace the check `t.check(d.tags().size() == MirasHouseDirector.GRIEVING, "the HUD marks the grieving")` with:

```gdscript
	var grieving_tags := 0
	for m in d.tags():
		grieving_tags += 1 if m.color == MirasHouseDirector.MARK_GRIEVING else 0
	t.check(grieving_tags == MirasHouseDirector.GRIEVING, "the HUD marks the grieving")
```

  - In `_events`, replace `and d2.marker() == b.ground_pos,` with `and _tag(d2, "CRYING OUT") != null and _tag(d2, "CRYING OUT").at == b.ground_pos,`.

- [ ] **Step 2: Run the tests to verify they fail.** Expected: FAILs from `_tags` ("the house comes first…") and from `_events`, and no SCRIPT ERROR other than a missing `MARK_HOUSE`-style constant (Parse Error is also acceptable).

- [ ] **Step 3: `MissionDirector.watchers()`.**
  - In `mission_director.gd`, replace `faithful_seeing()` (keep its comment) with the code below.
  - Add `watchers()` and `_sees()` after it.
  - The order and the `<` comparison are unchanged, so `faithful_seeing()` picks the same Faithful as before.

```gdscript
func faithful_seeing(at: Vector2, reach: float, exclude: Person = null) -> Person:
	var best: Person = null
	for f in faithful:
		if _sees(f, at, reach, exclude) and (best == null or f.ground_pos.distance_to(at) < best.ground_pos.distance_to(at)):
			best = f
	return best


## Every Faithful who would see `at` from within `reach`, as faithful_seeing() judges, but `exclude`, in the order of
## `faithful` (v0.10 M6: the watchers the HUD marks red).
func watchers(at: Vector2, reach: float, exclude: Person = null) -> Array[Person]:
	var out: Array[Person] = []
	for f in faithful:
		if _sees(f, at, reach, exclude):
			out.append(f)
	return out


## `f` would see `at`: alive, out in the open, not held by the god, not `exclude`, and within `reach` (v0.10 M6).
func _sees(f: Person, at: Vector2, reach: float, exclude: Person) -> bool:
	return _alive(f) and not f.inside and not (f.mind in BLIND) and f != exclude and f.ground_pos.distance_to(at) <= reach
```

- [ ] **Step 4: Mira's House's tags.** In `miras_house_director.gd`:
  - Add after `MARK_BELIEVER`:

```gdscript
## The tags' other colours (v0.10 M6, spec §4.1): the house's gold; its door clear (green) or watched (red), the red a
## runner, the Temple and each watcher share; the Inquisitor's violet.
const MARK_HOUSE := Color("d8b23a")
const MARK_CLEAR := Color("7fc46a")
const MARK_WATCHED := Color("c8342a")
const MARK_VENN := Color("c070ff")
```

  - Replace `tags()` (from Task 1) with:

```gdscript
## The tags (v0.10 M6, spec §4.1), the most important first:
## - the house, named, outlined and pointed at from the edge, until it is destroyed;
## - its door, clear or watched, until it burns;
## - each report's runner and, while one runs, the Temple, pointed at from the edge;
## - the crying Believer, pointed at;
## - the Inquisitor, pointed at while she searches;
## - a red diamond on each Faithful watching the door (but her);
## - the grieving, and the Believers among them.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if house != null and not house.destroyed:
		var h := MapTag.place(house.center(), MARK_HOUSE, "MIRA'S HOUSE", house.height)
		h.outline = house.footprint
		out.append(h)
	var open := not burning and not roof_fallen
	if open:
		var watched := faithful_seeing(door, SIGHT) != null
		out.append(MapTag.place(door, MARK_WATCHED if watched else MARK_CLEAR,
			"DOOR - WATCHED" if watched else "DOOR - CLEAR", 0.0, false))
	var running := false
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			out.append(MapTag.person(r.carrier.ground_pos, MARK_WATCHED, "TO THE TEMPLE", true))
			running = true
	if running:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	if _alive(shouter):
		out.append(MapTag.person(shouter.ground_pos, MARK_BELIEVER, "CRYING OUT", true))
	if _alive(venn) and not venn.inside:
		out.append(MapTag.person(venn.ground_pos, MARK_VENN, "INQUISITOR", venn_searching))
	if open:
		for f in watchers(door, SIGHT, venn):
			out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	for p in grieving:
		if _alive(p) and not p.inside:
			out.append(MapTag.person(p.ground_pos, MARK_BELIEVER if believers.has(p) else MARK_GRIEVING))
	return out


## The hint's phase (v0.10 M6, spec §4.1): "burning" once the house burns or falls, else "four" with four or more
## Believers out, else "".
func hint_phase() -> String:
	if burning or roof_fallen:
		return "burning"
	return "four" if believers_outside() >= BelieversObjective.NEED else ""
```

  - Delete `marker()` and its comment at the end of the file: the crying Believer's tag points at them now.

- [ ] **Step 5: Run the tests to verify they pass.** Run Tests. Expected: `failures=0`.

- [ ] **Step 6: The reference.** Run the Mira's House reference. Expected: identical, including `BEHAVIOUR checksum=-200101558`.

- [ ] **Step 7: The photo.**
  - Run `--show=miras`. Look at `captures/screen_miras.png` (Read it).
  - The house shows its name and outline, its door is labelled, the grieving wear diamonds, and the how-to-win plate sits under the objective rows.
  - Report what you see. Changing only the drawing constants `MapTag.PLACE_LIFT` and `Hud.LABEL_GAP` is allowed here if a label is cut or hidden; say so.

- [ ] **Step 8: Commit.**

```bash
git add src/game/mission/mission_director.gd src/game/mission/miras_house_director.gd tests/test_miras_house.gd
git commit -m "feat: Mira's House tags -- the house, its door, the Inquisitor, runners (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Broken Lanterns tags: shrines, draining time, the flame-bearer, Knights

**Files:**
- Modify: `src/game/mission/broken_lanterns_director.gd`: the tags, `hint_phase()`; `marker()` goes.
- Modify: `tests/test_broken_lanterns.gd`

**Interfaces:**
- Consumes: `MapTag`, `tags()`, `hint_phase()`. `guarded(s: Structure) -> bool`, `living_knights() -> int`, `drain_left`, `vigil`, `knights`.
- Produces: `BrokenLanternsDirector.MARK_KNIGHT`. `hint_phase()` returns `"knights"` or `""`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_broken_lanterns.gd`:
  - Add after `_alive()`:

```gdscript
## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null
```

  - In `_cast`, replace the block from `var lit := d.tags().size() == 6` through the `"no arrow yet, and a timeline…"` check with:

```gdscript
	var lit := 0
	var first_six := true
	var tags := d.tags()
	for i in tags.size():
		var m := tags[i]
		lit += 1 if m.label == "LANTERN" and m.color == BrokenLanternsDirector.MARK_LIT and m.edge \
			and m.rise == BrokenLanternsDirector.SHRINE_H else 0
		if i < 6:
			first_six = first_six and m.rise == BrokenLanternsDirector.SHRINE_H
	t.check(lit == 6, "the HUD names the six standing shrines, each pointed at from the edge")
	t.check(first_six, "the shrines come first, so a crowded view keeps their labels (review focus 1)")
	var bearer := _tag(d, "FLAME-BEARER")
	t.check(bearer != null and bearer.at == d.vigil.bearer.ground_pos and not bearer.edge and d.hint_phase() == ""
		and d.timeline != null, "the flame-bearer is named, no arrow yet; the hint's own line; a timeline for the windows")
```

  - In `_drain`, replace the `ember` loop and its check with:

```gdscript
	var left := "DRAINING %d" % ceili(float(d.drain_left[sh]))
	var ember := _tag(d, left)
	t.check(left == "DRAINING 20" and ember != null and ember.at == sh.center()
		and ember.color == BrokenLanternsDirector.MARK_DRAINING and ember.edge, "the HUD shows it draining, 20 s left")
```

  - In `_drain`, after the `"drained after 20 s broken"` check, add:

```gdscript
	var untagged := true
	for m in d.tags():
		untagged = untagged and m.at != sh.center()
	t.check(untagged, "a drained shrine has no tag")
```

  - In `_relight`:
    - replace `and d.marker() == d.vigil.bearer.ground_pos,` with `and _tag(d, "FLAME-BEARER").edge,`;
    - replace `and d.marker() == Vector2.INF and d.standing_shrines().has(sh),` with `and not _tag(d, "FLAME-BEARER").edge and d.standing_shrines().has(sh),`;
    - replace `t.check(not d.vigil.active and d.marker() == Vector2.INF, …` with `t.check(not d.vigil.active and _tag(d, "FLAME-BEARER") == null, "with all three dead the Vigil is over, and nobody is the flame-bearer")`.
  - In `_knights`, after the `"each is sent to guard a different standing shrine"` check, add:

```gdscript
	var knight_tags := 0
	for m in d.tags():
		knight_tags += 1 if m.label == "KNIGHT" and m.color == BrokenLanternsDirector.MARK_KNIGHT and not m.edge else 0
	t.check(knight_tags == BrokenLanternsDirector.KNIGHTS and d.hint_phase() == "knights",
		"each Knight is named, and the hint says how to get past them")
```

  - In `_knights`, after the `"a Knight beside it, the shrine shrugs off the blow"` check, add:

```gdscript
	var guarded_tag := _tag(d, "GUARDED")
	t.check(guarded_tag != null and guarded_tag.at == sh0.center() and guarded_tag.color == BrokenLanternsDirector.MARK_KNIGHT,
		"the shrine he stands by shows GUARDED")
```

  - In `_knights`, after the `"its Knight struck down first, the shrine breaks"` check, add:

```gdscript
	var still := 0
	for m in d.tags():
		still += 1 if m.label == "KNIGHT" else 0
	t.check(still == BrokenLanternsDirector.KNIGHTS - 1, "a Knight struck down is no longer tagged (review focus 2)")
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: FAILs in `_cast`, `_drain` and `_knights`, or a Parse Error naming `MARK_KNIGHT`.

- [ ] **Step 3: The tags.** In `broken_lanterns_director.gd`:
  - Add after `MARK_DRAINING`:

```gdscript
## The Knights' steel blue (v0.10 M6, spec §4.2): a Knight's tag, and a shrine one guards.
const MARK_KNIGHT := Color("8fb8e8")
```

  - Replace `tags()` with:

```gdscript
## The tags (v0.10 M6, spec §4.2), the most important first:
## - each standing shrine: GUARDED while a Knight guards it, else LANTERN;
## - each broken one draining, with its whole seconds left;
## - all of those pointed at from the edge;
## - the flame-bearer, pointed at while he is on his way to relight one;
## - each living Knight.
## A drained shrine has none.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for s in shrines:
		if not s.destroyed:
			var g := guarded(s)
			out.append(MapTag.place(s.center(), MARK_KNIGHT if g else MARK_LIT, "GUARDED" if g else "LANTERN", SHRINE_H))
		elif drain_left.has(s):
			out.append(MapTag.place(s.center(), MARK_DRAINING, "DRAINING %d" % ceili(float(drain_left[s])), SHRINE_H))
	if vigil != null and vigil.active and _alive(vigil.bearer):
		out.append(MapTag.person(vigil.bearer.ground_pos, MARK_LIT, "FLAME-BEARER", vigil.detour != Vector2.INF))
	for k in knights:
		if _alive(k):
			out.append(MapTag.person(k.ground_pos, MARK_KNIGHT, "KNIGHT"))
	return out


## The hint's phase (v0.10 M6, spec §4.2): "knights" while a Lantern Knight lives, else "".
func hint_phase() -> String:
	return "knights" if living_knights() > 0 else ""
```

  - Delete `marker()` and its comment: the flame-bearer's tag points at him now.

- [ ] **Step 4: Run the tests to verify they pass.** Expected: `failures=0`.

- [ ] **Step 5: The reference.** Run the Broken Lanterns reference. Expected: identical, including `BEHAVIOUR checksum=424350965`.

- [ ] **Step 6: The photo.**
  - Run `--show=lanterns` and look at `captures/screen_lanterns.png`.
  - Each shrine on screen is labelled LANTERN, the ones off screen have edge arrows, the flame-bearer is named, and the how-to-win plate is under the objectives. Report what you see.

- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/broken_lanterns_director.gd tests/test_broken_lanterns.gd
git commit -m "feat: Broken Lanterns tags -- shrines, draining time, the flame-bearer, Knights (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Vigil Flame tags: Wren, the flame, Mira's shrine, witnesses

**Files:**
- Modify: `src/game/mission/vigil_flame_director.gd`: the tags, `hint_phase()`; `marker()` goes.
- Modify: `tests/test_vigil_flame.gd`

**Interfaces:**
- Consumes: `MapTag`, `tags()`, `hint_phase()`, `watchers()` (Task 3). `Crowd.DOOM_WITNESS`. `appeared`, `wren`, `home`, `swapped`, `homeward`, `_lantern`, `shrine`, `temple_door`, `vigil`.
- Produces: `VigilFlameDirector.MARK_WATCHED`. `hint_phase()` returns `"carry"`, `"homeward"`, `"wren"` or `""`.

- [ ] **Step 1: Write the failing tests.** In `tests/test_vigil_flame.gd`:
  - Add after `_alive()`:

```gdscript
## The first of the director's tags labelled `label`, or null.
static func _tag(d: MissionDirector, label: String) -> MapTag:
	for m in d.tags():
		if m.label == label:
			return m
	return null
```

  - In `_cast`, replace the `var marks := d.tags()` check and the `"no arrow yet; the strip shows…"` check with:

```gdscript
	var tags := d.tags()
	t.check(tags.size() == 2 and tags[0].label == "HALCYON'S FLAME" and tags[0].at == d.vigil.bearer.ground_pos
		and tags[0].color == VigilFlameDirector.MARK_FLAME and tags[0].edge and tags[1].label == "MIRA'S SHRINE"
		and tags[1].at == d.shrine and tags[1].color == VigilFlameDirector.MARK_SHRINE and tags[1].edge,
		"the HUD names the flame and Mira's shrine, both pointed at from the edge")
	var next := d.timeline.upcoming(2)
	t.check(d.hint_phase() == "" and next.size() == 2 and next[0].id == "wren" and next[1].id == "route",
		"before Wren, the mission's own line; the strip shows Wren coming and the route shortening")
```

  - In `_wren`, replace the `seen` loop and its check with:

```gdscript
	var wt := _tag(d, "WREN")
	t.check(wt != null and wt.at == w.ground_pos and wt.color == VigilFlameDirector.MARK_WREN and wt.edge
		and d.hint_phase() == "wren", "the HUD names him and points at him; the hint says whisper him to the flame")
```

  - Add `_tags(t)` to `run()`, after `_lines(t)`, and this function:

```gdscript
## v0.10 M6 (spec §4.3): while Wren may be seen taking it, each Faithful near enough to see him is marked red, never the
## bearer; the Temple is tagged while the Vigil takes the real flame home; once swapped the hint says carry it, and the
## flame's and the Temple's tags go; dead, Wren is not tagged (review focus 2).
static func _tags(t) -> void:
	var s := _setup()
	var d: VigilFlameDirector = s.d
	_wren_now(d)
	_bearer_out(s)
	_clear_watchers(d)
	_bring_wren(d)
	var reds := 0
	for m in d.tags():
		reds += 1 if m.color == VigilFlameDirector.MARK_WATCHED and m.label == "" else 0
	t.check(reds == 0, "the bearer alone by Wren: nobody marked red")
	var acolyte := d.vigil.acolytes[0]
	_arrive(acolyte, d.wren.ground_pos + Vector2(0.5, 0.0))
	var marked := false
	for m in d.tags():
		marked = marked or (m.at == acolyte.ground_pos and m.color == VigilFlameDirector.MARK_WATCHED and m.label == "")
	t.check(marked, "an acolyte beside him: marked red, a witness")
	d.timeline.step(VigilFlameDirector.ROUTE_AT - VigilFlameDirector.WREN_AT)
	var temple := _tag(d, "TEMPLE")
	t.check(d.homeward and temple != null and temple.at == d.temple_door and temple.edge and d.hint_phase() == "homeward",
		"the Vigil turned for home: the Temple is tagged, and the hint says hurry")
	(s.crowd as Crowd)._field.kill(d.wren, &"doom")
	t.check(_tag(d, "WREN") == null, "dead, Wren is not tagged (review focus 2)")
	_done(s)

	var s2 := _setup()
	var d2: VigilFlameDirector = s2.d
	_do_swap(s2)
	t.check(d2.swapped and d2.hint_phase() == "carry" and _tag(d2, "HALCYON'S FLAME") == null and _tag(d2, "TEMPLE") == null
		and _tag(d2, "MIRA'S SHRINE") != null and _tag(d2, "WREN") != null,
		"swapped: the hint says carry it home; Wren and Mira's shrine stay tagged, the lantern's flame does not")
	_done(s2)
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: FAILs in `_cast`, `_wren` and `_tags`, or a Parse Error naming `MARK_WATCHED`.

- [ ] **Step 3: The tags.** In `vigil_flame_director.gd`:
  - Add after `MARK_SHRINE`:

```gdscript
## The red of the Temple's tag and of each witness's (v0.10 M6, spec §4.3).
const MARK_WATCHED := Color("c8342a")
```

  - Replace `tags()` with:

```gdscript
## The tags (v0.10 M6, spec §4.3), the most important first:
## - Wren, from his coming until the flame is home;
## - the real flame while it is still in its lantern;
## - Mira's shrine;
## - all of those pointed at from the edge;
## - the Temple while the Vigil takes the real flame home;
## - while Wren may yet be seen taking the flame, a red diamond on each Faithful near enough to see him (never the
##   bearer, who is robbed).
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var with_us := appeared and _alive(wren) and not wren.inside
	if with_us and not home:
		out.append(MapTag.person(wren.ground_pos, MARK_WREN, "WREN", true))
	if not swapped and _lantern != Vector2.INF:
		out.append(MapTag.person(_lantern, MARK_FLAME, "HALCYON'S FLAME", true))
	out.append(MapTag.place(shrine, MARK_SHRINE, "MIRA'S SHRINE"))
	if homeward and not swapped:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	if with_us and not swapped:
		for f in watchers(wren.ground_pos, Crowd.DOOM_WITNESS, vigil.bearer if vigil != null else null):
			out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.10 M6, spec §4.3): "carry" once the flame is swapped, else "homeward" while the Vigil goes home,
## else "wren" once he has come; "" before.
func hint_phase() -> String:
	if swapped:
		return "carry"
	if homeward:
		return "homeward"
	return "wren" if appeared else ""
```

  - Delete `marker()` and its comment: Wren's tag points at him now.
  - Check `tests/test_vigil_flame.gd` for any remaining `d.marker()` check (`grep -n "marker()" tests/test_vigil_flame.gd`). A check that he is pointed at becomes `_tag(d, "WREN").edge`, and one that nobody is becomes `_tag(d, "WREN") == null`.

- [ ] **Step 4: Run the tests to verify they pass.** Expected: `failures=0`.

- [ ] **Step 5: The references.** Run the Vigil Flame reference (outcome) and the Mira's House reference (exact).

- [ ] **Step 6: The photo.**
  - Run `--show=flame` and look at `captures/screen_flame.png`.
  - The flame is named on its bearer, and Mira's shrine is named or pointed at from the west edge. Report what you see.

- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/vigil_flame_director.gd tests/test_vigil_flame.gd
git commit -m "feat: Vigil Flame tags -- Wren, the flame, Mira's shrine, witnesses (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: The tour: each Night 2 mission opens on its key places, and a press skips it

**Files:**
- Create: `src/game/mission/intro_tour.gd`, `tests/test_intro_tour.gd`
- Modify: `src/game/mission/mission_director.gd` (`tour()`)
- Modify: the three Night 2 directors (`tour()`)
- Modify: `src/game/mission.gd` (`_begin_intro`, `_process`, `_unhandled_input`; new `_land`, `skip_intro`, `touring`, `skips_tour`)
- Modify: `src/game/ui/hud.gd` (the caption)
- Modify: `src/game/game.gd` (`--show`, FLOW)
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: the directors' `door`, `temple_door`, `venn`, `standing_shrines()`, `vigil`, `shrine`, `_lantern`. `Mission._director`, `_hud`, `_rules`, `_bf`, `_def`, `_act`, `INTRO_SECONDS`, `INTRO_FROM_ZOOM`, `PLAY_ZOOM`.
- Produces:
  - **`IntroTour`:**
    - consts `MOVE_SECONDS := 1.0`, `HOLD_SECONDS := 1.6`;
    - `setup(from: Vector2, stops: Array, to: Vector2) -> IntroTour`, `seconds() -> float`, `step(delta: float)`, `skip()`, `done() -> bool`, `camera() -> Vector2`, `caption() -> String`, `zoom_k() -> float`.
  - **`MissionDirector.tour() -> Array`:** `[Vector2, String]` pairs, empty by default.
  - **`Mission`:** `touring() -> bool`, `skip_intro()`, `static skips_tour(event: InputEvent) -> bool`.
  - **`Hud`:** `set_caption(text: String)`, `caption() -> String`, `CAPTION_TOP := 262.0`.
  - **`Game`:** `_past_intro()`, `_flow_tour(step)`, `--show=tour`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_intro_tour.gd`:

```gdscript
extends RefCounted
## v0.10 M6 the intro's tour (spec §5): IntroTour's timeline -- a move to each stop, a hold under its caption, a move on to
## where play begins, the zoom coming in over the first move, skip() landing it; Mission.skips_tour() takes Space, Enter
## and a left click, and nothing else (review focus 4); each Night 2 director's stops, a stop with no one to show left
## out (review focus 3); the HUD's caption.

const A := Vector2(0.0, 0.0)
const B := Vector2(10.0, 0.0)
const C := Vector2(10.0, 10.0)
const D := Vector2(0.0, 10.0)


static func run(t) -> void:
	_timeline(t)
	_skips(t)
	_stops(t)


static func _timeline(t) -> void:
	var tour := IntroTour.new().setup(A, [[B, "one"], [C, "two"]], D)
	var move := IntroTour.MOVE_SECONDS
	var hold := IntroTour.HOLD_SECONDS
	t.near(tour.seconds(), 3.0 * move + 2.0 * hold, 0.001, "three moves and two holds")
	t.check(tour.camera() == A and tour.caption() == "one" and tour.zoom_k() == 0.0 and not tour.done(),
		"it opens where the intro starts, on its way to the first stop, under its caption")
	tour.step(move * 0.5)
	t.check(tour.camera().x > 0.0 and tour.camera().x < 10.0 and tour.zoom_k() > 0.0 and tour.zoom_k() < 1.0,
		"half way there, zooming in (%s)" % tour.camera())
	tour.step(move * 0.5 + hold * 0.5)
	t.check(tour.camera() == B and tour.caption() == "one" and tour.zoom_k() == 1.0, "holding at the first stop")
	tour.step(hold * 0.5 + move + 0.01)
	t.check(tour.camera().distance_to(C) < 0.01 and tour.caption() == "two", "then at the second, under its caption")
	tour.step(hold)
	t.check(tour.caption() == "" and not tour.done(), "on the way to play: no caption")
	tour.step(move)
	t.check(tour.done() and tour.camera() == D, "it ends where play begins")
	tour.step(5.0)
	t.check(tour.done() and tour.camera() == D, "and stays there")
	var skipped := IntroTour.new().setup(A, [[B, "one"]], D)
	skipped.skip()
	t.check(skipped.done() and skipped.camera() == D and skipped.caption() == "", "skip() lands it at once")
	t.near(IntroTour.new().setup(A, [], D).seconds(), move, 0.001, "with no stops it is one move")


static func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


static func _button(index: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = true
	return e


static func _skips(t) -> void:
	t.check(Mission.skips_tour(_key(KEY_SPACE)) and Mission.skips_tour(_key(KEY_ENTER))
		and Mission.skips_tour(_key(KEY_KP_ENTER)) and Mission.skips_tour(_button(MOUSE_BUTTON_LEFT)),
		"Space, Enter and a left click skip the tour")
	t.check(not Mission.skips_tour(_key(KEY_SPACE, true, true)) and not Mission.skips_tour(_key(KEY_SPACE, false))
		and not Mission.skips_tour(_key(KEY_ESCAPE)) and not Mission.skips_tour(_key(KEY_1))
		and not Mission.skips_tour(_button(MOUSE_BUTTON_RIGHT)) and not Mission.skips_tour(_button(MOUSE_BUTTON_WHEEL_UP))
		and not Mission.skips_tour(InputEventMouseMotion.new()),
		"a held key, a release, Esc, a slot's key, the right button, the wheel and a move do not (review focus 4)")


## A Night 2 mission's world, as its own tests build it.
static func _world(def: MissionDef) -> Dictionary:
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
	var rules := Rules.new().setup(def.default_loadout, null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := (def.director.new() as MissionDirector).setup(rules, crowd, town, null)
	rules.director = director
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director}


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


static func _stops(t) -> void:
	t.check(MissionDirector.new().tour().is_empty(), "a director tours nothing by default: the sweep plays")

	var s := _world(MissionBook.miras_house())
	var m: MirasHouseDirector = s.d
	var stops := m.tour()
	t.check(stops.size() == 3 and stops[0][0] == m.door and stops[1][0] == m.temple_door
		and stops[2][0] == m.venn.ground_pos and String(stops[0][1]) == "Mira's house. Her journal is inside."
		and String(stops[1][1]) == "The Temple. Faithful who see you run here."
		and String(stops[2][1]) == "Venn, the Inquisitor. She searches from 0:40.",
		"Mira's House tours her door, the Temple and the Inquisitor")
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	hud.set_caption("Mira's house. Her journal is inside.")
	t.check(hud.caption() == "Mira's house. Her journal is inside.", "the HUD holds the tour's caption")
	hud.set_caption("")
	t.check(hud.caption() == "", "and lets it go")
	hud.free()
	(s.crowd as Crowd)._field.kill(m.venn, &"doom")
	t.check(m.tour().size() == 2, "the Inquisitor dead, her stop is left out (review focus 3)")
	_done(s)

	var s2 := _world(MissionBook.broken_lanterns())
	var b: BrokenLanternsDirector = s2.d
	var bs := b.tour()
	t.check(bs.size() == 3 and bs[0][0] == b.standing_shrines()[0].center() and bs[1][0] == b.vigil.bearer.ground_pos
		and bs[2][0] == b.temple_door and String(bs[0][1]) == "A lantern. Break it, then let it drain."
		and String(bs[1][1]) == "The flame-bearer relights broken lanterns."
		and String(bs[2][1]) == "Lantern Knights come out at 1:30.",
		"Broken Lanterns tours a lantern, the flame-bearer and the Temple")
	_done(s2)

	var s3 := _world(MissionBook.vigil_flame())
	var v: VigilFlameDirector = s3.d
	var vs := v.tour()
	t.check(vs.size() == 3 and vs[0][0] == v.vigil.bearer.ground_pos and vs[1][0] == v.shrine and vs[2][0] == v.temple_door
		and String(vs[0][1]) == "Halcyon's flame, carried by the Vigil."
		and String(vs[1][1]) == "Mira's shrine. The flame must come here."
		and String(vs[2][1]) == "The Temple. The flame must not go home.",
		"the Vigil Flame tours the flame, Mira's shrine and the Temple")
	_done(s3)
```

  - Add `"res://tests/test_intro_tour.gd",` to `SUITES` after `"res://tests/test_mission_hints.gd",`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: a Parse Error naming `IntroTour`, `skips_tour`, `tour` or `set_caption`.

- [ ] **Step 3: Create `src/game/mission/intro_tour.gd`:**

```gdscript
class_name IntroTour
extends RefCounted
## The camera's tour of a mission's key places before its clock starts (v0.10 M6, spec §5): from where the intro opens to
## each stop in turn -- MOVE_SECONDS on the way, smoothed, then HOLD_SECONDS there under the stop's caption -- and on to
## where play begins. A pure timeline: Mission moves the camera, and the HUD shows the caption.

## Each move between points, and each hold at a stop.
const MOVE_SECONDS := 1.0
const HOLD_SECONDS := 1.6

## The tour's points in order -- where it opens, each stop, where play begins -- and each stop's caption.
var _points: Array[Vector2] = []
var _captions: Array[String] = []
## Seconds into the tour.
var _t := 0.0


## `stops`: [ground point, caption] pairs, in order.
func setup(from: Vector2, stops: Array, to: Vector2) -> IntroTour:
	_points.clear()
	_captions.clear()
	_points.append(from)
	for s: Array in stops:
		_points.append(s[0] as Vector2)
		_captions.append(String(s[1]))
	_points.append(to)
	_t = 0.0
	return self


## The whole tour: a move to each stop and one on to where play begins, and a hold at each stop.
func seconds() -> float:
	return float(_captions.size() + 1) * MOVE_SECONDS + float(_captions.size()) * HOLD_SECONDS


func step(delta: float) -> void:
	_t = minf(_t + delta, seconds())


## To the end at once.
func skip() -> void:
	_t = seconds()


func done() -> bool:
	return _t >= seconds()


## Where the camera looks now (ground units).
func camera() -> Vector2:
	var leg := _leg()
	var k := _leg_k()
	return _points[leg].lerp(_points[leg + 1], k * k * (3.0 - 2.0 * k))


## The caption of the stop the tour is moving to or holding at; "" on the way to where play begins.
func caption() -> String:
	var leg := _leg()
	return _captions[leg] if leg < _captions.size() else ""


## How far the zoom has come in, 0 to 1: over the first move, then held.
func zoom_k() -> float:
	var k := clampf(_t / MOVE_SECONDS, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## The leg under way: leg i runs from point i to point i + 1, a move and then (to a stop) a hold.
func _leg() -> int:
	return mini(floori(_t / (MOVE_SECONDS + HOLD_SECONDS)), _captions.size())


## How far along its move the leg under way is, 0 to 1 (1 while it holds).
func _leg_k() -> float:
	var into := _t - float(_leg()) * (MOVE_SECONDS + HOLD_SECONDS)
	return clampf(into / MOVE_SECONDS, 0.0, 1.0)
```

- [ ] **Step 4: The directors' tours.**
  - In `mission_director.gd`, add after `hint_phase()`:

```gdscript
## Virtual (v0.10 M6, spec §5): the stops of the camera's tour before the clock starts, as [ground point, caption] pairs;
## none by default, and then the intro is the sweep. A stop with no one to show is left out.
func tour() -> Array:
	return []
```

  - In `miras_house_director.gd`, add after `hint_phase()`:

```gdscript
## The tour (v0.10 M6, spec §5): her door, the Temple, the Inquisitor.
func tour() -> Array:
	var out := []
	if door != Vector2.INF:
		out.append([door, "Mira's house. Her journal is inside."])
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. Faithful who see you run here."])
	if _alive(venn):
		out.append([venn.ground_pos, "Venn, the Inquisitor. She searches from 0:40."])
	return out
```

  - In `broken_lanterns_director.gd`, add after `hint_phase()`:

```gdscript
## The tour (v0.10 M6, spec §5): a lantern, the flame-bearer, the Temple the Knights come out of.
func tour() -> Array:
	var out := []
	var standing := standing_shrines()
	if not standing.is_empty():
		out.append([standing[0].center(), "A lantern. Break it, then let it drain."])
	if vigil != null and _alive(vigil.bearer):
		out.append([vigil.bearer.ground_pos, "The flame-bearer relights broken lanterns."])
	if temple_door != Vector2.INF:
		out.append([temple_door, "Lantern Knights come out at 1:30."])
	return out
```

  - In `vigil_flame_director.gd`, add after `hint_phase()`:

```gdscript
## The tour (v0.10 M6, spec §5): the flame on its bearer, Mira's shrine, the Temple.
func tour() -> Array:
	var out := []
	if vigil != null and _alive(vigil.bearer):
		out.append([vigil.bearer.ground_pos, "Halcyon's flame, carried by the Vigil."])
	if shrine != Vector2.INF:
		out.append([shrine, "Mira's shrine. The flame must come here."])
	if temple_door != Vector2.INF:
		out.append([temple_door, "The Temple. The flame must not go home."])
	return out
```

- [ ] **Step 5: The HUD's caption.** In `hud.gd`:
  - Add after the `HINT_*` consts:

```gdscript
## The tour's caption (v0.10 M6, spec §5): its plate's top, above the slot row (SLOT_TOP), and the word under it.
const CAPTION_TOP := 262.0
const SKIP_TEXT := "SPACE TO SKIP"
```

  - Add after `_layout`:

```gdscript
## The tour's caption on screen (v0.10 M6); "" for none.
var _caption := ""
```

  - Add after `subtitle_width()`:

```gdscript
## The tour's caption (v0.10 M6): Mission sets it every frame of the tour, and clears it when the camera lands.
func set_caption(text: String) -> void:
	_caption = text


func caption() -> String:
	return _caption


## The tour's caption (v0.10 M6) on a dark plate centred above the slot row, with SKIP_TEXT dim under it.
func _draw_caption(w: float) -> void:
	if _caption == "":
		return
	var tw := UiTheme.width(_caption, UiTheme.SIZE_BODY)
	var sw := UiTheme.width(SKIP_TEXT, UiTheme.SIZE_SMALL)
	var plate_w := maxf(tw, sw) + 16.0
	draw_rect(Rect2(roundf((w - plate_w) * 0.5), CAPTION_TOP, plate_w, 32.0), Color(0.03, 0.03, 0.05, 0.78))
	UiTheme.text(self, Vector2(roundf((w - tw) * 0.5), CAPTION_TOP + 14.0), _caption, UiTheme.SIZE_BODY)
	UiTheme.text(self, Vector2(roundf((w - sw) * 0.5), CAPTION_TOP + 27.0), SKIP_TEXT, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
```

  - In `_draw()`, call `_draw_caption(w)` right after `_draw_subtitle(w)`.
  - In `_signature()`, add `out += "|" + _caption` next to the hint.

- [ ] **Step 6: The mission plays the tour.** In `src/game/mission.gd`:
  - Add after `var _intro_left`:

```gdscript
## The intro's tour of a Night 2 mission's key places (v0.10 M6, spec §5), played in place of the sweep; null for a
## sweep, or once the camera has landed.
var _tour: IntroTour
```

  - In `_begin_intro()`:
    - in the `_scripted` branch, add `_tour = null` first;
    - replace the `else:` branch with:

```gdscript
	else:
		_rules.set_process(false)  # the clock waits for the camera
		_bf.camera.zoom = Vector2.ONE * INTRO_FROM_ZOOM
		_bf.camera.position = Iso.ground_to_screen(play.intro_from).round()
		var stops: Array = _director.tour() if _director != null else []
		_tour = IntroTour.new().setup(play.intro_from, stops, play.camera_at) if not stops.is_empty() else null
		_intro_left = _tour.seconds() if _tour != null else INTRO_SECONDS
		if play.intro_banner != "":
			_rules.banner.emit(play.intro_banner)
```

    (Check that `_director` is the act's director by the time `_begin_intro()` runs: `_build_act()` makes it, and both `start()` and `next_act()` call `_build_act()` first.)

  - In `_process()`, replace the `if _intro_left > 0.0:` block with:

```gdscript
	if _intro_left > 0.0:
		_intro_left = maxf(0.0, _intro_left - delta)
		if _tour != null:
			_tour.step(delta)
			_bf.camera.position = Iso.ground_to_screen(_tour.camera()).round()
			_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, _tour.zoom_k())
			_hud.set_caption(_tour.caption())
		else:
			var k := 1.0 - _intro_left / INTRO_SECONDS
			var smooth := k * k * (3.0 - 2.0 * k)  # not "ease": that is a global function, and shadowing it warns
			var play: MissionDef = _act if _act != null else _def
			_bf.camera.position = Iso.ground_to_screen(play.intro_from.lerp(play.camera_at, smooth)).round()
			_bf.camera.zoom = Vector2.ONE * lerpf(INTRO_FROM_ZOOM, PLAY_ZOOM, smooth)
		if _intro_left <= 0.0:
			_land()
		return  # the camera is the intro's until it lands: no panning, no aiming
```

  - Add after `in_intro()`:

```gdscript
## The intro is a tour of the mission's key places (v0.10 M6), not the sweep.
func touring() -> bool:
	return in_intro() and _tour != null


## Ends the intro at once (v0.10 M6): the sweep or the tour lands, and the clock starts.
func skip_intro() -> void:
	if in_intro():
		_land()


## The intro is over (v0.10 M6): the camera rests on the mission's own spot, the tour's caption goes, and the clock starts.
func _land() -> void:
	var play: MissionDef = _act if _act != null else _def
	_intro_left = 0.0
	_tour = null
	_bf.camera.position = Iso.ground_to_screen(play.camera_at).round()
	_bf.camera.zoom = Vector2.ONE * PLAY_ZOOM
	if is_instance_valid(_hud):
		_hud.set_caption("")
	_rules.set_process(true)


## A press that skips the tour (v0.10 M6, spec §5): Space, Enter or a left click, pressed -- not an echo, nor a release.
static func skips_tour(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.pressed and not event.echo and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false
```

  - In `_unhandled_input()`, replace the line `if in_intro() and not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE):` and the `return` under it with the code below. The skipping click returns before `_aim.press()`, and its release finds `_pressing` false, so it casts nothing.

```gdscript
	if in_intro() and not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE):
		if touring() and skips_tour(event):
			get_viewport().set_input_as_handled()
			skip_intro()
		return
```

- [ ] **Step 7: The photos and FLOW.** In `src/game/game.gd`:
  - In the `match show:` block, add a case before `_:`:

```gdscript
		"tour":
			# Mira's House on its tour (v0.10 M6), for the photograph of a stop's caption among its tags.
			mission_id = MissionBook.MIRAS_HOUSE
			loadout = MissionBook.miras_house().default_loadout
			go_to(Screen.MISSION)
```

  - In the `if "--capture" in args:` branch, right after the `await _mission.prewarmed` lines, add:

```gdscript
		if show in ["miras", "cael", "lanterns", "flame", "flame-beams"] and is_instance_valid(_mission):
			# Their photographs are of play (v0.10 M6): the tour is skipped, as a player would.
			await _until(func() -> bool: return _mission.started(), 10.0)
			_mission.skip_intro()
```

  - Replace `await get_tree().create_timer(2.0 if show.begins_with("flame") else 1.0).timeout` with:

```gdscript
		var wait := 1.0
		if show.begins_with("flame"):
			wait = 2.0
		elif show == "tour":
			wait = IntroTour.MOVE_SECONDS * 2.0 + IntroTour.HOLD_SECONDS + 0.4  # held at the second stop
		await get_tree().create_timer(wait).timeout
```

  - Add after `_until()`:

```gdscript
## Waits out the mission's intro (FLOW). A Night 2 mission's tour (v0.10 M6) is skipped at once, as a player would.
func _past_intro() -> void:
	if is_instance_valid(_mission) and _mission.touring():
		_mission.skip_intro()
	await _until(func() -> bool: return not _mission.in_intro(), 5.0)
```

  - Replace every `await _until(func() -> bool: return not _mission.in_intro(), 5.0)` in `game.gd` with `await _past_intro()`. Use `grep -n "return not _mission.in_intro(), 5.0" src/game/game.gd`: about 19 lines, all becoming `await _past_intro()`.
  - Add `_flow_tour()` after `_flow_campaign()`:

```gdscript
## v0.10 M6 (spec §5; review focus 4 and 5): Mira's House opens on its tour -- the clock waiting, a caption up -- and a
## Space press lands it at once: the caption gone, nothing cast, the clock running. A restart tours again from the top.
func _flow_tour(step: Callable) -> void:
	_in_campaign = false
	mission_id = MissionBook.MIRAS_HOUSE
	loadout = MissionBook.miras_house().default_loadout
	go_to(Screen.MISSION)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await get_tree().process_frame
	var clock0 := _mission.rules().time_left
	step.call(_mission.touring() and _mission._hud.caption() != "", "Mira's House opens on its tour, a caption up")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	Input.parse_input_event(space)
	await get_tree().process_frame
	await get_tree().process_frame
	var cooling := false
	for i in _mission.rules().loadout.size():
		cooling = cooling or _mission.rules().cooldown_left(i) > 0.0
	step.call(not _mission.in_intro() and _mission._hud.caption() == "" and not cooling,
		"Space lands it: no caption, nothing cast")
	await get_tree().create_timer(0.5).timeout
	step.call(_mission.rules().time_left < clock0, "and the clock runs (%.2f)" % _mission.rules().time_left)
	var old := _mission
	_open_pause()
	on_action("pause:restart")
	await _until(func() -> bool: return _mission_up(old), 10.0)
	await get_tree().process_frame
	step.call(_mission.touring() and _mission._hud.caption() != "", "a restart tours again from the top")
	_mission.skip_intro()
	step.call(not _mission.in_intro() and _mission._hud.caption() == "", "and lands at once when skipped")
	_open_pause()
	on_action("pause:missions")
	await get_tree().process_frame
```

  - In `_flow_test()`, add `await _flow_tour(step)` right after `await _flow_campaign(step)`.

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`.

- [ ] **Step 9: FLOW.** Run FLOW. Expected: `FLOW result checks=91 failures=0` (86 + 5). Paste every `FLOW FAIL` line if there are any.

- [ ] **Step 10: The references.** Run the Mira's House reference (exact) and the Broken Lanterns reference (exact).

- [ ] **Step 11: The photos.**
  - Run `--show=tour` and `--show=miras`.
  - In `screen_tour.png`: the camera holds on the Temple with the caption "The Temple. Faithful who see you run here." and SPACE TO SKIP under it.
  - In `screen_miras.png`: play, with no caption. Report what you see.

- [ ] **Step 12: Commit.**

```bash
git add src/game/mission/intro_tour.gd src/game/mission/mission_director.gd src/game/mission/miras_house_director.gd src/game/mission/broken_lanterns_director.gd src/game/mission/vigil_flame_director.gd src/game/mission.gd src/game/ui/hud.gd src/game/game.gd tests/test_intro_tour.gd tests/run_all.gd
git commit -m "feat: the intro tour of each Night 2 mission, skippable (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(Add the new scripts' `.uid` files if Godot made them.)

---

### Task 7: The photos read clearly; the notes

**Files:**
- Modify (only if a photo shows a problem): the drawing constants `MapTag.PLACE_LIFT`, `Hud.LABEL_GAP`, `Hud.ARROW_REACH`, `Hud.CAPTION_TOP` and `Hud.HINT_COL`, and the tag colours in the three directors.
- Modify: `docs/KAK_Version_0.10_Summary.md`, `README.md`.

**Interfaces:**
- Consumes: everything above.
- Produces: the docs. No new code.

- [ ] **Step 1: Take the four photos.** Run `--show=miras`, `--show=lanterns`, `--show=flame` and `--show=tour`, and Read each `captures/screen_<name>.png`.

- [ ] **Step 2: Judge them against spec §2.3 and §4.** For each photo, answer in the report:
  - Is every on-screen label readable, inside the screen, and clear of the clock, the Gaze bar, the events plate, the objective rows and the slot row?
  - Is the how-to-win plate under the objectives without covering the Gaze bar?
  - Do the edge arrows sit at the edge with their labels inside?
  - In the tour photo, is the caption centred above the slots?

- [ ] **Step 3: Fix only what a photo shows.**
  - Change only the drawing constants listed under **Files**.
  - After any change, run Tests and the photo again.
  - Report each change with its old and new value and the photo that asked for it.
  - If nothing needs changing, say so.

- [ ] **Step 4: The notes.**
  - In `docs/KAK_Version_0.10_Summary.md`, add a section `## M6: Objective clarity` before its last section. It says, in the summary's own voice:
    - the map's tags: what each Night 2 mission shows, and that a label never hides another (the first kept);
    - the how-to-win line under the objectives, for every mission and act, changing with the mission's phase;
    - the tour: the three stops of each Night 2 mission, and Space, Enter or a click to skip;
    - for the board missions: `MissionDirector.tags()` replaces v0.10's `marks()`; a board mission's director can override `tags()`, `hint_phase()` and `tour()`;
    - Gates: the controller fills this line at landing; write `Gates: filled in at landing.`
  - In `README.md`'s KAK section, add one sentence: Night 2's missions now show their objectives on the map, say how to win under the objectives, and open on a short skippable tour.

- [ ] **Step 5: Run Tests** (a docs-only commit still runs them). Expected: `failures=0`.

- [ ] **Step 6: Commit.**

```bash
git add docs/KAK_Version_0.10_Summary.md README.md
git commit -m "docs: M6 objective clarity in the v0.10 summary and README (v0.10 M6)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

(If Step 3 changed drawing constants, add those files to the same commit and say so in its message.)
