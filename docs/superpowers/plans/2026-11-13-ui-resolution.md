# UI Resolution & Skill Tree Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A pixel-art world that is crisp at every window size (integer scale), fills any aspect ratio with the
visible world capped at 21:9, and HUD and menus drawn at full screen resolution. The skill tree is redrawn so that
every icon, name and state reads at a glance.

**Architecture:** The root window becomes `canvas_items` with integer scale k. `UiScale` sizes the content so it
fills the window, and every UI CanvasLayer then draws at full resolution in "UI units" (k device px each). The
world (Battlefield and its owner) moves into a `SubViewport` hosted by a `WorldView` node. Its size equals the UI
area, it is drawn at the origin with nearest filtering, and it gets input forwarded by hand from the root's
`_unhandled_input`. One UI unit = one world-viewport pixel (identity mapping), so HUD hit tests and event
positions keep working. The simulation reads a constant `SIM_VIEW` and the logical zoom, never the viewport size.

**Tech Stack:** Godot 4.7.2, GDScript, GL Compatibility, headless test suite (`tests/run_part.gd`), Pixelify Sans
(OFL, already committed).

**Spec:** `docs/superpowers/specs/2026-11-13-ui-resolution-design.md` (rulings in §3, exact skill tree numbers in
§7, size table in §5).

## Global Constraints

- Work only in `C:\BURIN_NITRO\Godot\GIT\vfxProve-ui` (branch `feat/ui-resolution`). `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- After a new `class_name` or an `--import`-relevant change: `timeout 900 "$G" --headless --editor --path . --import`.
- The exact references never move: `bash tools/dev/refs_check.sh --jobs=8` must print `bad=0`. Never re-record a
  reference without the user's yes. Gameplay does not change.
- The simulation never reads the window, the viewport size or the render zoom: `Battlefield.SIM_VIEW` and
  `CameraShake.logical_zoom()` only. Headless runs never host a WorldView, never expand, and have `fit = 1`.
- `project.godot` keeps `aspect="keep"`. Expand is applied at run time by `UiScale.install` and only when not headless.
- Suite: `bash tools/dev/run_suite_parallel.sh 8` → `failures=0`. FLOW alone:
  `timeout 900 "$G" --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep -a "FLOW result"` (quiet machine).
- Text: nothing below 11 units. Skill tree and HUD use only `UiTheme.TEXT_S/TEXT_L/TEXT_XL/TEXT_XXL` (11/22/33/66).
- No UI `draw_*` with width `-1.0` or a defaulted width (lint test). Icons drawn only at 42·m device px (`UiIcon`).
- No PixelLab, no new paid art. Drawn shapes and existing art only.
- Never kill a Godot process this session did not launch. Never bare `git stash`. Stage by name.
  Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Do not push.

## Review Focus

1. **Input order.** Esc opens and closes pause once; H opens the legend without turning a page; TAB hides the UI;
   a click on a HUD slot does not cast; the aim follows the mouse while it is over a STOP panel. Tests in Task 2;
   FLOW.
2. **Simulation independence.** `Person.view` size is `SIM_VIEW / zoom` whatever the viewport size; every
   `camera.zoom` write goes through `zoom_to`. Tests in Tasks 2 and 9; refs_check.
3. **Nothing UI left in the world viewport, nothing world left in the root.** Invariant test in Task 2; town
   capture by eye (grade, bloom, glow, flash still over the world and under the HUD).
4. **Crispness.** No hairlines, icons at 42·m px, text at crisp sizes on the skill tree and HUD. Lint tests in
   Task 3; proof captures in Task 10.
5. **Skill tree legibility.** Every label clear of every disc and of other labels for all six types with
   `dev_fill`; the refusal fits under RAISE. Tests in Task 4.

---

### Task 1: Integer scaling (lands alone) — *mechanical*

**Files:**
- Modify: `project.godot` (`[display]`: add `window/stretch/scale_mode="integer"`)
- Create: `tests/test_ui_scale.gd` (first check only); register it in `tests/run_all.gd` `SUITES`

**Interfaces:** none.

- [ ] Step 1: Test `_integer_setting(t)`: `ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer"`. Run the suite; it fails.
- [ ] Step 2: Add the setting. Suite → `failures=0`. `bash tools/dev/refs_check.sh --jobs=8` → `bad=0` (headless is unaffected; the rendered rows run at 1280×720 = 2× exact).
- [ ] Step 3: By eye: `"$G" --path . --resolution 1366x768` → a 1280×720 frame centred with a border, every pixel 2×2.
- [ ] Step 4: Commit `feat: integer scaling for the 640x360 frame (crisp at every window size)`.

### Task 2: WorldView: the world in a SubViewport (still viewport mode)

The root stays in `viewport` mode for this task, so the output must look the same as before. This isolates the
hosting and input change from the resolution change.

**Files:**
- Create: `src/game/ui/world_view.gd` (`class_name WorldView extends Node`)
- Modify: `src/game/battlefield.gd` (hud_layer, `FpsMeter` (a CanvasLayer, F3 in `_input`) and `ArtToggle` (F7 in `_input`) under `ui_parent()`; `SIM_VIEW`, `sim_view_size()`, `mouse_screen()`, `mouse_ground()` (= `Iso.screen_to_ground(get_canvas_transform().affine_inverse() * mouse_screen())`); `save_capture` reads the root, **keeping the 2x resize in this task** (in viewport mode the root texture is still 640x360; Task 3 drops the resize))
- Modify: `src/game/mission.gd` (ZoomReadout, memory overlay, the BehaviourOverlay node (it already adds its World lines to the battlefield itself) and legend under `_bf.ui_parent()`; `_hud.world_viewport = _bf.get_viewport()` after the Hud is made; `self_host` at the top of `_ready`; `world_xf()` for Game)
- Modify: `src/game/ui/hud.gd` (`var world_viewport: Viewport`; `_world_xf()` replaces the 5 `get_viewport().get_canvas_transform()` calls (hud.gd 667, 748, 773, 1216, 1516); `_hover_point` uses `WorldView.mouse_in_view`)
- Modify: `src/game/game.gd` (missions hosted with `_world.host(mission)` at both add sites 978/1004; `_capture` reads the root; `_flow_click_ground` uses the mission's world transform)
- Modify: `src/game/ui/title_screen.gd` (hosts `_bf` and `_town` in a WorldView), `src/game/town_debug.gd` (`self_host`; its ZoomReadout under `_bf.ui_parent()`), `src/sandbox/sandbox.gd` (`self_host`; `_mouse_ground()` uses `_bf.mouse_ground()`, not `get_global_mouse_position()`)
- Modify: `tools/dev/behaviour_check.gd`, `tools/dev/profile_view.gd`, `tools/dev/profile_wear.gd` (host when `DisplayServer.get_name() != "headless"`); `behaviour_check.gd:1285` warps the **root** mouse with `WorldView.world_xf(bf.get_viewport()) * point` (a SubViewport's own `warp_mouse` has no container transform)
- Create: `tests/test_world_view.gd`; register it in `SUITES`

**Interfaces (produces):**
- `WorldView`: `var viewport: SubViewport`, `var display: TextureRect`, `var ui: Node`, `func host(node: Node) -> void`,
  `static func of(node: Node) -> WorldView`, `static func ui_parent(node: Node) -> Node`,
  `static func self_host(node: Node) -> bool`, `static func world_xf(world: Viewport) -> Transform2D`,
  `static func mouse_in_view(world_node: Node) -> Vector2`, `func resize(area: Vector2i) -> void`
- `Battlefield`: `const SIM_VIEW := Vector2(640, 360)`, `func sim_view_size() -> Vector2`, `func ui_parent() -> Node`, `func mouse_screen() -> Vector2`
- `Hud`: `var world_viewport: Viewport` (null → own viewport), `func _world_xf() -> Transform2D`
- `Mission`: `func world_xf() -> Transform2D` (camera canvas transform of its battlefield)

Key snippets:
```gdscript
# WorldView._unhandled_input
viewport.push_input(event, true)
if viewport.is_input_handled():
	get_viewport().set_input_as_handled()
```
```gdscript
# Battlefield._process (the only sim-facing line that changes)
var size := sim_view_size()   # SIM_VIEW / (sim_zoom if sim_zoom > 0 else camera.zoom.x)  (logical_zoom() from Task 9)
```
SubViewport setup: `render_target_update_mode = UPDATE_ALWAYS`, `snap_2d_vertices_to_pixel = true` (match
project), `size = UiScale.area()` (640×360 for now). Display: `TextureRect` at (0,0), `size = area`,
`texture_filter = TEXTURE_FILTER_NEAREST`, `stretch_mode = STRETCH_SCALE`, `mouse_filter = IGNORE`.
`self_host`: `if node.get_parent() == node.get_tree().root and node.get_tree().current_scene == node and
DisplayServer.get_name() != "headless" and WorldView.of(node) == null:` request_ready, deferred reparent into a
new WorldView added to the root, return true.

- [ ] Step 1: Write the failing tests in `tests/test_world_view.gd` (headless; a SubViewport works without drawing):
  `_hosting` (`host()` puts a Node2D under `viewport`; `of()` finds it; `ui_parent` is `ui` when hosted and the node itself when not);
  `_bf_layers` (a hosted Battlefield's `hud_layer.get_parent() == wv.ui`; an unhosted one's is the battlefield);
  `_no_ui_in_world` (host a Mission with `autostart = false` on the Warning, start it, walk `wv.viewport`: every `Control` is a full-rect `MOUSE_FILTER_IGNORE` `ColorRect` directly under a world post CanvasLayer (glow, Impact post, flash, TownGrade and TownBloom are ColorRects), none anywhere else; the CanvasLayers' `layer` values ⊆ {1, 2, 3, 4, 5}; no `FpsMeter`, `ZoomReadout`, `LegendPanel` or `Hud` in it);
  `_keys` (a world node sets a key as handled → `wv._unhandled_input(key)` leaves the root handled; a key the world ignores leaves it unhandled);
  `_mouse_identity` (an `InputEventMouseButton` at (123, 45) reaches the world node with `position == (123, 45)`);
  `_sim_view_pinned` (with the hosted SubViewport resized to 853×360 and `sim_zoom = 0.6`, after one `_process`, `Person.view.size == SIM_VIEW / 0.6 + 2·VIEW_MARGIN`).
- [ ] Step 2: Run the suite; the new tests fail (WorldView missing).
- [ ] Step 3: Implement. Import (new class_name).
- [ ] Step 4: Suite `failures=0`; refs_check `bad=0`; FLOW alone passes.
- [ ] Step 5: By eye, same as before: `SCENE=res://scenes/game.tscn GODOT=$G bash tools/capture.sh --show=tax_collector --capture` (`warning` is not a show name: it falls through to the title), and
  `SCENE=res://scenes/town_debug.tscn GODOT=$G bash tools/capture.sh --capture-town --only=<first shot>`. Grade, bloom,
  glow and flash are over the world and under the HUD; output 1280×720.
- [ ] Step 6: Commit `feat: the world renders in a WorldView SubViewport; UI layers stay in the root; sim view pinned`.

### Task 3: Full-resolution UI: canvas_items, UiScale, crisp text, hairlines, icons

**Files:**
- Modify: `project.godot` (`window/stretch/mode="canvas_items"`; keep `aspect="keep"`, `scale_mode="integer"`)
- Create: `src/game/ui/ui_scale.gd` (`class_name UiScale`), `src/game/ui/ui_scale_notifier.gd` (`class_name UiScaleNotifier`, `signal changed(layout: Dictionary)`), `src/game/ui/ui_icon.gd` (`class_name UiIcon`)
- Modify: `src/game/ui/ui_theme.gd` (`TEXT_S := 11`, `TEXT_L := 22`, `TEXT_XL := 33`, `TEXT_XXL := 66`, `LINE_S := 12.0`, `LINE_L := 24.0`; `frame()` and `mark()` widths `1.0`)
- Modify: every UI file with hairlines (count today: 25 explicit `-1.0` plus about 20 calls with the width left out, in `hud.gd`, `ui_theme.gd`, `god_select_screen.gd`, `legend_panel.gd`, `mission_board.gd`, `prepare_screen.gd`, `results_screen.gd`, `skill_tree_screen.gd`, `title_screen.gd`, `ending_screen.gd`, `behaviour_overlay.gd`) → explicit `1.0`
- Modify: `src/game/game.gd` (`UiScale.install(get_tree())` first in `_ready`; `_capture` drops the 2x resize), `src/game/battlefield.gd` (`save_capture` drops the 2x resize: under canvas_items the root texture is already window-sized), `src/game/ui/world_view.gd` (`self_host` installs too), `tools/capture.sh` (passes `--window=WxH` through; no change needed: args after `--` reach the game)
- Test: `tests/test_ui_scale.gd`

**Interfaces (produces):** as spec §4. `UiScale.layout(window: Vector2i) -> Dictionary {k, area, offset, fit}`;
`install(tree)`; `k()`; `area()`; `design_offset()`; `anchor(design_rect: Rect2, where: int) -> Rect2` with
`enum Anchor { TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTRE, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT }`;
`snap(p: Vector2) -> Vector2`; `design_frame(layer: CanvasLayer, filter: int) -> Control`;
`backdrop(frame: Control) -> Rect2`; `static var notifier: UiScaleNotifier`; `anchor` takes an optional third argument `area: Vector2` (default `area()`), so `Hud` anchors to its own `_view()`; test hook `static func set_test_area(a: Vector2i) -> void` / `clear_test_area()` for headless tests of 800x450 layouts (`area()`, `design_offset()`, `anchor()` and `design_frame()` use it; every test that sets it clears it). `UiIcon.native_rect(centre: Vector2,
want_units: float) -> Rect2`; `UiIcon.multiple(want_units: float) -> int`; `UiIcon.texture_for(key: String,
m: int) -> Texture2D`; `UiIcon.grey(tex: Texture2D) -> Texture2D`; `UiIcon.grey_image(img: Image) -> Image`;
`UiIcon.draw_round(on: CanvasItem, tex: Texture2D, rect: Rect2, tint := Color.WHITE) -> void`.
`--window=WxH` (user arg): `install` makes the window borderless at (0,0) and that size, before the first frame.

In this task `install` sets `content_scale_size` to `DESIGN` (aspect keep). `layout()` already computes `area`
and `fit` for the expand task, but the expand is not applied until Task 9 (`UiScale.EXPAND_ON := false`).

- [ ] Step 1: Failing tests in `test_ui_scale.gd`:
  `_layout_table` — `layout()` for the 9 windows in spec §5 equals the table exactly (k, area, fit to 1e-4);
  `_anchor` — at area 640×360 every anchor is the identity; at 800×450 `anchor(Rect2(600,316,40,20), BOTTOM_RIGHT) == Rect2(760,406,40,20)` and `CENTRE` shifts by (80, 45);
  `_icons` — `multiple(21)` with k 1..6 = 1,1,1,2,2,3 and `native_rect` sizes 42·m/k; `grey_image` of a 2×1 red/green image gives equal r=g=b, alpha kept;
  `_crisp` — `TEXT_* % 11 == 0`;
  `_hairline_lint` — for every `src/game/ui/*.gd`, every whole `draw_line(`/`draw_polyline(`/`draw_arc(`/`draw_rect(..., false` call (joined across lines up to its closing paren) has a last width argument that is a positive literal or a named constant, never `-1.0` and never missing.
  Use a `RegEx` over the file text.
- [ ] Step 2: Run; the tests fail.
- [ ] Step 3: Implement `UiScale`, `UiIcon` and the notifier; flip `project.godot`; sweep the hairlines. Import.
- [ ] Step 4: Headless sanity: `"$G" --headless --path . -s` a throwaway script printing `root.get_visible_rect().size` → `(640, 360)`.
- [ ] Step 5: Suite `failures=0`; refs_check `bad=0`; FLOW.
- [ ] Step 6: Captures at `--window=1920x1080` and `--window=1366x768` of `--show=tree`, `--show=pause` and `--show=tax_collector`: text sharp, world in 3×/2× blocks, lines one unit thick.
- [ ] Step 7: Commit `feat: full-resolution UI over the pixel world (canvas_items, UiScale, crisp text sizes, no hairlines)`.

### Task 4: Skill tree redesign (spec §7)

**Files:**
- Modify: `src/game/ui/skill_tree_screen.gd`, `src/game/ui/tree_detail.gd` (level rows return old/new separately, already so; `REFUSALS` unchanged), `src/game/ui/tree_wheel.gd` (constants only if a test demands; geometry unchanged)
- Test: `tests/test_skill_tree.gd`, `tests/test_tree_wheel.gd`

**Interfaces:**
- Changes: `NODE_NAME_PX := 11`, `SMALL_PX := 11`, `SIZE_CHIP := 11`, `BACK_RECT := Rect2(6, 4, 52, 18)`, `REMEMBER_RECT := Rect2(528, 256, 96, 26)`, `BUY_RECT := Rect2(528, 286, 96, 26)`, `MINI_PX := 22.0`, `mini_rect()` per §7, `const LABEL_AREA := Rect2(124, 28, 392, 218)`, `const LABEL_STRIP_H := 13.0`, `const PULSE_SECONDS := 1.6`
- Produces: `func label_layout(col: int) -> Dictionary` (Vector2i → Rect2, cached by col; cleared on `centre()`), `static func refusal_lines(reason: String) -> PackedStringArray` (wrap at 96 u, `TEXT_S`, ≤ 2 lines), `func value_columns(rows: Array) -> Dictionary` (`{new_w: float, arrow_x: float, old_right: float}` for `right = LEVEL_X + LEVEL_W - 6`), `func pulse_alpha(t: float) -> float`
- Removes: `node_label_rect()` (tests move to `label_layout`), the reason line at `(INFO_X, 340)`
- Uses: `UiIcon.native_rect/draw_round/grey`, `UiTheme.TEXT_S/TEXT_L`

- [ ] Step 1: Failing tests in `test_skill_tree.gd`:
  `_labels_clear` — with `GodTree.dev_fill = true` for every type and column: every strip in `label_layout(col)` lies inside `LABEL_AREA`, clears every node disc grown 3 u and the ring numeral plates, and no two strips intersect;
  `_refusal_fits` — `refusal_lines(x)` has ≤ 2 lines and each is ≤ 96 u at `TEXT_S`, for every `REFUSALS` value (tier formatted with 5) and "Not enough ability points";
  `_value_columns` — on a fixture row set, the new values' right edges are all equal to `right`, the old values' right edges are all equal to `old_right`, and `arrow_x` is between them;
  `_crisp_only` — the source of `skill_tree_screen.gd` has no `SIZE_SMALL`, `SIZE_BODY`, `SIZE_BIG` or numeric font size other than via `TEXT_*`/`NODE_NAME_PX`/`SMALL_PX`/`SIZE_CHIP` (RegEx), and no `UiTheme.text/width/wrap/fit` call that leaves the size out (`text`/`width`/`wrap` default to `SIZE_BODY` 13);
  `_pulse` — `pulse_alpha` stays in [0.05, 0.12] and repeats after 1.6 s;
  `_mini_cells` — 10 mini rects per panel, inside the panel, none overlapping, all above the bottom line's baseline − 9.
  Update `_layout` and `_texts_fit` for the new numbers (only where §7 moved them).
- [ ] Step 2: Run; they fail.
- [ ] Step 3: Implement §7 (states, grey and badge, pulse redraw in `_process` only while a `can` node is visible, label strips, orbit fade, side panels with hover name, detail column, refusal under BUY).
- [ ] Step 4: Suite `failures=0`.
- [ ] Step 5: Captures `--show=tree` at 1280×720, 1920×1080 and 2560×1440 (`--window`). Check by eye: no label touches a ring or disc; locked icons grey but visible with the badge; owned gold; affordable pulsing; numbers in one column; "Not enough ability points" under RAISE after a refused buy (`--show=tree` with 0 points, click RAISE in a throwaway script, or check the test).
- [ ] Step 6: Commit `feat: skill tree readability: native icons, crisp 11/22 text, clear states, fanned labels, one value column, refusal by RAISE`.

### Task 5: HUD and in-mission overlays

**Files:**
- Modify: `src/game/ui/hud.gd` (anchors via `UiScale.anchor` for slots, status, objective/hint stack, chain/ascend, banners, wish boxes; `SCREEN_W/H` uses removed in favour of `_view()`; text below 11 raised to `TEXT_S`; HUD text only `TEXT_*`; slot icons stay 42 u = k×42 px)
- Modify: `src/game/ui/legend_panel.gd` (`VIEW` → design frame centred, backdrop full area), `src/game/ui/memory_overlay.gd` (`Vector2(640, 360)` → `UiScale.area()`), `src/game/ui/behaviour_overlay.gd` (panel in the UI, world lines in the world), `src/game/ui/zoom_readout.gd` (right-edge anchor), `src/game/ui/fps_meter.gd`, `src/game/ui/fader.gd`, `src/game/ui/art_toggle.gd`
- Test: `tests/test_hud.gd`, `tests/test_legend.gd`, `tests/test_hide_ui.gd`, `tests/test_map_tags.gd`, `tests/test_descend_hud.gd`

**Interfaces:**
- `Hud.anchor_slots(area: Vector2) -> Rect2` and the like are not needed: `slot_rect(i)`, `chain_rect()`, `ascend_rect()`, `wish_at()` and `slot_at()` keep their signatures and return area-anchored rects.
- Mission's `event.position` hit tests stay unchanged (identity mapping).

- [ ] Step 1: Failing tests: in `test_hud.gd`, `_anchors_800x450` — a Hud sized 800×450 puts the slot row's bottom at `450 - (360 - SLOT_TOP - SLOT_SIZE)`, centred on x 400, and the status line's right edge at 800 − its 640-design margin; at 640×360 every rect equals today's. A source lint: no `SIZE_SMALL|SIZE_BODY|SIZE_BIG` or numeric font size under 11 in `hud.gd`, and no `UiTheme.text/width/wrap/fit` call with the size left out (the default is `SIZE_BODY` 13).
- [ ] Step 2: Run; they fail.
- [ ] Step 3: Implement.
- [ ] Step 4: Suite; refs_check (HUD code is drawing only, but `mission.gd` hit tests are in reach); FLOW.
- [ ] Step 5: Captures `--show=tax_collector`, `--show=pause` and `--show=sermon` at 1366×768 and 1920×1080. The HUD hugs the edges, and tags and arrows sit on their people.
- [ ] Step 6: Commit `feat: HUD and mission overlays anchored to the screen edges at full resolution`.

### Task 6: Menus: title, menu, options, pause, board, slots, god select, hub, faith, upgrades — *mechanical*

**Files:** `src/game/ui/title_screen.gd`, `menu.gd`, `options_panel.gd`, `pause_menu.gd`, `mission_board.gd`,
`slot_screen.gd`, `god_select_screen.gd`, `god_select_art.gd`, `god_hub.gd`, `faith_screen.gd`, `upgrades_screen.gd`.
Tests: `tests/test_menu.gd`, `test_options.gd`, `test_slot_screens.gd`, `test_god_select_art.gd`, `test_faith_hub.gd`,
`test_descend_screens.gd`.

Recipe per file (no design changes):
1. `_ui` = `UiScale.design_frame(layer, <the filter it had>)` instead of a full-rect Control. Its local coordinates are today's 640×360, so `hit()`/`click()` and tests are unchanged.
2. Every `Rect2(0, 0, 640, 360)` fill → `UiScale.backdrop(_ui)`. The god select background texture stays 640×360 in the frame, and the area outside is filled with its darkest colour (`Color(0.03, 0.03, 0.05)`).
3. Font sizes below 11 → `UiTheme.TEXT_S`. Leave 13/16.
4. `draw_texture_rect` of an ability icon → `UiIcon.native_rect` (prepare, board, hub).
5. `mission_board.gd`: `640.0 - BOARD_MARGIN * 2` stays design-frame math (the board is centred, not stretched).

- [ ] Step 1: Add one test per file group to `test_menu.gd`: at area 800×450, the screen's frame is at offset (80, 45) and a click at frame-local `CHOOSE`/`BACK` centres still hits.
- [ ] Step 2: Apply the recipe file by file. Suite after each pair of files.
- [ ] Step 3: Suite `failures=0`; captures of `--show=title`, `--show=pause-options`, `--show=board-dev-hunts`, `--show=slots`, `--show=god-select`, `--show=hub`, `--show=faith` and `--show=upgrades` at 1920×1080 and 1600×900 (the 1600×900 ones once Task 9 lands; at this point they are letterboxed).
- [ ] Step 4: Commit `feat: menus on the full-resolution UI (design frame, full backdrops, no text under 11)`.

### Task 7: Flow screens: prepare, results, ending, interlude, campaign — *mechanical*

**Files:** `src/game/ui/prepare_screen.gd`, `results_screen.gd`, `ending_screen.gd`, `interlude_screen.gd`,
`campaign_screen.gd`. Tests: `test_endless_screens.gd`, `test_campaign_screens.gd`, `test_descend_screens.gd`.

Same recipe as Task 6. `results_screen.gd`'s rank letter at `SIZE_HUGE` 64 → `TEXT_XXL` 66 (check it still fits its box).

- [ ] Step 1: The same offset test for prepare and results at 800×450.
- [ ] Step 2: Apply the recipe; suite; captures of `--show=prepare`, `--show=results`, `--show=ending`, `--show=interlude` and `--show=campaign-choice` at 1920×1080.
- [ ] Step 3: Commit `feat: prepare, results, ending, interlude and campaign on the full-resolution UI`.

### Task 8: Old text constants and leftovers — *mechanical*

**Files:** `src/game/ui/ui_theme.gd` plus any caller still using a size under 11.

- [ ] Step 1: `grep -rnE "SMALL_PX - 1|, (8|9|10)\)" src/game/ui` → zero hits. Extend `_hairline_lint` with a "no font size under 11" lint over `src/game/ui/*.gd` (numeric literal arguments to `UiTheme.text`/`width`/`wrap`/`fit`).
- [ ] Step 2: Suite; commit `chore: no UI text under 11 units (lint)`.

### Task 9: Fill any aspect: expand, view fit, 21:9 cap, resize

**Files:**
- Modify: `src/game/ui/ui_scale.gd` (`EXPAND_ON := true`: `apply()` sets aspect `EXPAND` and `content_scale_size = area`; headless never)
- Modify: `src/core/camera_shake.gd` (`var view_fit := 1.0`, `func zoom_to(z: float)`, `func logical_zoom() -> float`, `func set_view_fit(f: float)` re-applies the zoom)
- Modify: `src/game/ui/world_view.gd` (on `UiScale.notifier.changed`: `resize(area)`, `set_view_fit(fit)` on the hosted camera)
- Modify: every `camera.zoom` writer and simulation reader: `src/game/mission.gd` (14), `src/game/town_debug.gd` (15), `src/game/battlefield.gd` (1, reader: `logical_zoom()`), `src/core/impact.gd` (1, visual: keep render zoom), `src/game/ui/title_screen.gd` (1), `src/sandbox/sandbox.gd` (writes at 158 and 409 → `zoom_to`; the two `tween_property(_camera, "zoom", ...)` at 204 and 217 → `tween_method(_camera.zoom_to, ...)` on the logical zoom). Render readers that stay on `zoom`: `src/fx/dominion/voice_of_god.gd:415`, `src/audio/{ambience,fire_sounds,sfx}.gd`. `tools/dev/*` writers (behaviour_check 16, profile_view 1) are outside the lint and run at fit 1 (see rulings on `logical_zoom()`). `Mission` re-clamps on `get_viewport().size_changed` (`_pan(Vector2.ZERO)`)
- Test: `tests/test_ui_scale.gd`, `tests/test_world_view.gd`

**Interfaces:** `CameraShake.zoom_to(z: float) -> void`, `CameraShake.logical_zoom() -> float`,
`CameraShake.set_view_fit(f: float) -> void`; `Battlefield.sim_view_size()` uses `logical_zoom()`; on the wheel,
`_bf.sim_zoom = _bf.camera.logical_zoom() * SIM_PLAY_ZOOM / PLAY_ZOOM`.

Classification (write it into the commit message): pan by `event.relative / camera.zoom.x` = render (screen
pixels to world); `clamp_view(..., camera.zoom.x, view_size)` = render; `sim_zoom` = logical; town_debug shot
zooms = `zoom_to`; bench zooms = `zoom_to`; the wheel's new zoom is `logical_zoom() * 1.1` (or `/ 1.1`) clamped to ZOOM_MIN..MAX, then `zoom_to` (never from `camera.zoom.x`, which would compound `fit`); `_zoom_readout.show_zoom(logical_zoom())`; the bench box fit at `mission.gd:286` is a render zoom: `zoom_to(that / view_fit)`.

- [ ] Step 1: Failing tests:
  `_zoom_lint` — no `camera.zoom =` / `cam.zoom =` / `.zoom = Vector2` outside `camera_shake.gd` in `src/` (RegEx);
  `_fit` — a CameraShake with `set_view_fit(1.25)` and `zoom_to(0.85)` has `zoom.x == 0.85 * 1.25` and `logical_zoom() == 0.85` exactly; with fit 1, `zoom.x == 0.85` exactly;
  `_sim_independent` — a hosted Battlefield at area 860×360 with fit 1.0238 gives the same `Person.view` as at 640×360 with fit 1 (same logical zoom and camera position);
  `_visible_capped` — for each window in the §5 table, `area / (fit)` ≤ (840, 360) + 1e-3;
  `_headless_keeps` — `UiScale.install` in headless leaves `root.content_scale_aspect == KEEP` and the visible rect at 640×360.
- [ ] Step 2: Run; they fail.
- [ ] Step 3: Implement.
- [ ] Step 4: Suite; **refs_check `bad=0`** (this task touches the camera); FLOW alone.
- [ ] Step 5: Captures at 1366×768, 1600×900, 1920×1200 and 2560×1080 of `--show=tax_collector` and `--show=tree`: no bars; the world framing matches 1920×1080 in height; the HUD at the edges. Drag the window edge by hand once (resize works, the camera re-clamps).
- [ ] Step 6: Commit `feat: fill any aspect ratio (expand) with the visible world capped at 21:9 x 360 by camera fit`.

### Task 10: Proof captures, bench, final gates — *mechanical (verification only)*

**Files:** none in `src/`. Writes `captures/ui_resolution/` (ignored by git) and a short proof table in the final
report.

- [ ] Step 1: For W×H in 1280x720, 1366x768, 1600x900, 1920x1080, 1920x1200, 2560x1080 and 3440x1440, and each show in
  `tree hub pause results board-dev-hunts title prepare tax_collector`:
  `SCENE=res://scenes/game.tscn GODOT=$G bash tools/capture.sh --show=<s> --capture --window=<W>x<H>`, then move
  `captures/screen_<s>.png` to `captures/ui_resolution/<s>_<W>x<H>.png`. Plus
  `SCENE=res://scenes/town_debug.tscn GODOT=$G bash tools/capture.sh --capture-town --only=<first shot> --window=<W>x<H>`.
- [ ] Step 2: Script check (throwaway Python, PIL): image size == W×H; the four 8×8 corners are not all pure black;
  in a 40×40 patch of world (centre of `tax_collector`), horizontal run lengths of equal colour are multiples of k
  (allow the 1-px offset at 2560×1080).
- [ ] Step 3: Read every `tree_*` capture and the 3440×1440 and 1920×1200 ones by eye (labels, icons, states, the HUD at the edges).
- [ ] Step 4: `bash tools/dev/land.sh --bench=7eb1c6a0` on a quiet machine (suite, refs, FLOW, bench pairs). The frame rate must stay within the machine's noise (about 1 fps).
- [ ] Step 5: Report: the proof table (size × show → OK, with the issue if any), bench medians, gate lines. No commit unless a fix was needed (fixes go back to the owning task's files with a `fix:` commit).

## Numbers to tune (only if a test or capture fails)

- `UiScale.MAX_WORLD_W` 840 (21:9 at 360). Do not raise it.
- Label strip 13 u high, padding 3 u; candidate order radial → below → above → side.
- Pulse 1.6 s, alpha 0.05–0.12; grey luma ×0.85; badge offset (8, 8).
- Mini cell 22 u, row pitch 24, columns mid ± 13.
- Refusal baselines 325/337; BUY_RECT y 286.
- Level value gap 10 u; arrow 6×5 u.
