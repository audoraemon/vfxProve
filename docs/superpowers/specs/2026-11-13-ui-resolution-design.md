# UI Resolution & Skill Tree Readability — design

Date: 2026-11-13. Branch `feat/ui-resolution` (cut from `feat/Develop-Main` 7eb1c6a0). Plan: `docs/superpowers/plans/2026-11-13-ui-resolution.md`.

## 1. Why

KAK renders everything — world, HUD and menus — into one 640×360 viewport and stretches it to the window
(`window/stretch/mode="viewport"`, `aspect="keep"`, fractional scale). Three problems follow:

1. **Uneven pixels.** At 1366×768 (2.13×) and 1600×900 (2.5×) the 640×360 frame is stretched by a fraction, so
   some art pixels are 2 screen pixels wide and some 3.
2. **Black bars** on any screen that is not 16:9 (16:10 laptops, 21:9 monitors).
3. **Unreadable UI.** All text and icons are drawn at 640×360 and then blown up. The skill tree shows this worst
   (user screenshot at 1920×1080 = 3×):
   - the 42×42 painted ability icons (`PowerBook.hud_icon`, `assets/pixellab/icons/hud/`) are shrunk to 14×14 on
     the wheel (`skill_tree_screen.gd:538`) and to 12×12 in the side panels (`:612`) with nearest filtering, so
     they come out as mush;
   - locked icons are tinted `Color(0.5, 0.5, 0.55, 0.55)` (`:534`) and disappear into the dark purple;
   - names are Pixelify Sans at 9 px. The font is drawn on an 11-px grid, so at 9 px whole strokes drop out
     ("Earthshatter" reads "Bor bhshobber");
   - grey labels are low contrast, and orbit lines run through the labels.

The user approved all of the following, done in one pass: integer scaling, filling any aspect ratio (capped at
21:9), full-resolution UI over a pixel-art world, and a skill tree polish pass.

## 2. What we found (probes run on this machine, Godot 4.7.2, GL Compatibility)

Throwaway probe scripts in the session scratchpad, run with `--path .` in this worktree:

| Probe | Result |
|---|---|
| Root `CANVAS_ITEMS` + stretch `INTEGER` + aspect `KEEP`, headless | root `size` (64,64) and window (0,0), but **visible rect 640×360**. A SubViewportContainer sized to it gives a 640×360 SubViewport. |
| Same with aspect `EXPAND`, headless | **visible rect 640×640**. Expand must never be on in headless runs. |
| Godot's own integer + expand at 1366×768 / 1600×900 | Godot still letterboxes: it keeps 640×360 at 2× with a (43,24) or (160,90) offset. It does not fill the window. |
| Setting `root.content_scale_size = floor(window / k)` at run time (integer, expand, canvas_items) | Fills exactly: 1366×768 → 683×384 at 2×; 1600×900 → 800×450 at 2×; 2560×1080 → 853×360 at 3× (1 px offset); 1024×600 → 1024×600 at 1×. |
| A SubViewport (world) inside a canvas_items root | It renders at its own size (640×360-class), and the root scales it by k with nearest filtering, so the world stays crisp pixel art. A 1×1 rect in it shows as a k×k block. |
| Text in a canvas_items root (default oversampling on) | Text is rasterised at size×k. Pixelify at 11 units is perfectly crisp at every k. 9 units at 3× (27 px) is readable but uneven. With oversampling off, 9 px is the mangled 9-px glyph blown up (the bug as it is today). |
| Pixelify Sans grid | Cap height = 7 font pixels; one font pixel = em/11. So **11·n px is grid-perfect**, and in units **11, 22, 33 and 66 are crisp at every integer k**. |
| `draw_rect(..., false, -1.0)` under canvas_items | Draws a 1 *device* px hairline: one third of a unit at 3×. Width `1.0` draws one unit (k px). |
| Manual input forwarding: root `_unhandled_input` → `sub.push_input(e, true)` | The world node gets keys and mouse events. Positions are unchanged when the world is at the origin at 1:1 units. `sub.is_input_handled()` reports the world's `set_input_as_handled()`, and the root can mark the event handled too. Order among root siblings is kept. |
| Borderless window resized past the 1536×864 desktop (125 % DPI of 1920×1080) | Works at 1920×1200 and 3440×1440. `root.get_texture().get_image()` returns the full size, so every proof size can be captured on this laptop. |
| `Viewport.oversampling` / `oversampling_override` | Both exist in 4.7. |

What the code does today that matters here:

- `Battlefield` (Node2D) builds the world: GroundPlane, WorldLayer, Dim/Overhead/Distort layers, CameraShake,
  `glow_layer` (CanvasLayer 3, `glow_post.gdshader` reads the screen texture), `post_layer` 4 (Impact),
  `flash_layer` 5, and `hud_layer` 6. The town look adds `TownGrade` (layer 1) and `TownBloom` (screen-texture shaders).
  Battlefields are built in `mission.gd:216`, `title_screen.gd:41`, `town_debug.gd:207` and `sandbox.gd:122`.
- `Mission` (Node2D) holds the world (bf, town, crowd, rules, aim) **and** UI: Hud on `_bf.hud_layer`, legend on
  `_bf.hud_layer`, ZoomReadout (its own CanvasLayer), memory overlay (two CanvasLayers), behaviour overlay.
  Every world click and key goes through `Mission._unhandled_input`. Mission hit-tests HUD rects with
  `event.position` (`mission.gd:1209-1221`): today the world and the HUD share one coordinate space.
- `Hud` is a full-rect Control with `MOUSE_FILTER_IGNORE`. It maps world points with
  `get_viewport().get_canvas_transform()` (6 call sites) and reads `get_viewport().get_mouse_position()`
  (`hud.gd:811`). `Hud._view()` already uses its own size.
- **Things the simulation depends on:**
  `Battlefield._process` sets `Person.view = (visible rect / zoom)` round the camera centre. `Person._seen` picks
  the step rate (`OFFSCREEN_EVERY` 3, `CALM_EVERY` 2), so a different view size gives a different simulation.
  `Mission._pan` clamps with `get_viewport().get_visible_rect().size` (`mission.gd:1330`), and the camera centre
  moves `Person.view`. `sim_zoom` is set from `camera.zoom` on the wheel. Everything else that reads the view
  (ambience, sfx, fire sounds, impact UVs, ground fire sprite) is audio or visuals only.
- **Tools.** `behaviour_check.gd` and `profile_view.gd` add a Mission straight to the root. The references'
  digest, crowd_check and global rows run **windowed** (hit-stop is wall clock); the scenario rows run headless.
  `scenes/mission.tscn` is instanced as a `Mission` by `game.gd`, `test_night_rules.gd` and the tools.
  `Battlefield.save_capture` and `Game._capture` read `get_viewport()` (640×360 world+HUD) and scale it 2× to
  1280×720. `sandbox.gd:418` (clip capture) reads `get_viewport()` and crops the world.
- `game.gd --show=<screen> --capture` photographs every screen (`captures/screen_<show>.png`);
  `--flow-test` is FLOW; `_flow_click_ground` warps the mouse using the root canvas transform.

## 3. Decisions

Ruling: **Architecture = root at full resolution (canvas_items), world in a SubViewport.** The root window uses
`stretch/mode="canvas_items"` with integer scale, so every CanvasLayer the UI uses is scaled by k and its text
is rasterised at full resolution. The pixel world (Battlefield and everything its owner adds to the world) lives
in a `SubViewport` whose size is the UI area in units. Its texture is drawn at the root origin, filling the area
with nearest filtering. Rejected: (a) the whole game in canvas_items without a SubViewport — the world would
render at full resolution (mixels, sub-pixel camera, 9× fill for the screen-texture shaders, not the approved
look); (b) keeping viewport mode with a second full-resolution viewport for the UI — not possible in Godot, since a
viewport-stretched root renders all its CanvasLayers at the base size; (c) a SubViewport sharing the root's
World2D with cull masks — every world item would need a visibility layer, and CanvasLayers would not follow.

Ruling: **One integer scale k for world and UI.** `k = max(1, floor(min(W / 640, H / 360)))` in device px. No
fractional UI scale and no UI-size option in this milestone.

Ruling: **Identity mapping.** One UI unit = one world-viewport pixel = k device px. The world texture sits at the
UI origin and fills the UI area. Event positions, HUD rects and world screen points therefore share one space, as
they do today, and `Mission`'s `event.position` hit tests on HUD rects keep working with no conversion.

Ruling: **Fill by sizing the content ourselves.** `UiScale` sets `root.content_scale_size = floor(window / k)` on
every resize (aspect `EXPAND`, stretch `INTEGER`). Godot's built-in integer + expand letterboxes (probe), so we
do not rely on it. Expand is applied only at run time and never in headless runs. `project.godot` keeps
`aspect="keep"`, so headless and tool runs see exactly 640×360.

Ruling: **Fairness by camera fit, not curtains.** The visible world is never taller than 360 reference px nor
wider than 840 (21:9) reference px at a given zoom. Render zoom = logical zoom × `fit`, where
`fit = max(area.x / 840, area.y / 360)`. Every screen fills edge to edge, with no bars or curtains. A 16:10 player
sees a little less width, and a 32:9 player a little less height, never more than 21:9 × 360.
`fit` is 1 at 640×360, so headless, 1280×720 and 1920×1080 runs are unchanged.

Ruling: **Simulation pinned.** `Person.view` / `Structure.view` use the constant `Battlefield.SIM_VIEW =
Vector2(640, 360)` divided by the logical zoom (or `sim_zoom`), never the viewport size. The camera clamp
(`Mission.clamp_view`) keeps using the real view size and render zoom, because it is a drawing concern (no
ground gaps). At 640×360 these are bit-identical to today. At 21:9 the sim view (640/0.6 ≈ 1067 at play zoom) is
still wider than the visible 840/0.85 ≈ 988, so nobody on screen steps at the off-screen rate.

Ruling: **Input forwarding is manual.** `WorldView` is an ordinary `Node` in the root, at the tree position its
hosted node would have had. Its `_unhandled_input` pushes the event into the SubViewport
(`push_input(e, true)`) and marks the root's input handled when the world handled it. We do not use
SubViewportContainer: it forwards keys in the `_input` phase, before the root's GUI and pause menu, which would
change today's order. World mouse position is read from the root (`WorldView.mouse_in_view`), never from the
SubViewport's last pushed event, so the aim stays right while the mouse is over a STOP control.

Ruling: **UI never lives in the world viewport.** CanvasLayers and Controls created by world owners
(`Battlefield.hud_layer`, the ZoomReadout, memory/behaviour overlays, the legend) are parented to
`WorldView.ui` (in the root) when the world is hosted, and stay where they are today when it is not (headless
tests and tools). An invariant test walks the SubViewport: no `Control`, and only the world post layers
(TownGrade 1, TownBloom, glow 3, post 4, flash 5).

Ruling: **Hosting.** `Game` hosts missions, `TitleScreen` hosts its backdrop battlefield, and `Mission`,
`TownDebug` and `Sandbox` host themselves when they are the windowed main scene (`WorldView.self_host`:
`request_ready()`, deferred reparent, return early). `behaviour_check.gd` and `profile_view.gd` host explicitly
when not headless, so rendered references run on the game's render path. Headless runs never host.
`scenes/mission.tscn` is unchanged: its root is still a `Mission`.

Ruling: **Captures keep their size.** `Battlefield.save_capture` and `Game._capture` read the **root** texture
(world + full-resolution UI). At a 1280×720 window that is 1280×720, as today, with no 2× resize. Any other
window is saved at its own size. Sandbox clip capture reads the world viewport (unchanged 640×360 crop).

Ruling: **Text sizes.** No text below 11 units anywhere. The crisp sizes are `UiTheme.TEXT_S = 11`,
`TEXT_L = 22`, `TEXT_XL = 33`, `TEXT_XXL = 66` (grid-perfect at every k). The skill tree and the HUD use only
crisp sizes. Other screens move 8–10 → 11 and may keep 13/16 (rasterised at 39/48 px at 3×: legible, slightly
uneven) until a later pass. Old constants stay until nothing uses them.

Ruling: **Font = Pixelify Sans, kept.** It is OFL, and `assets/fonts/PixelifySans-OFL.txt` is already committed.
At 11·n px it is effectively a bitmap font. Antialiasing stays NONE, the liga/clig overrides are kept, and
oversampling stays on (default).

Ruling: **Hairlines.** Every UI `draw_*` with width `-1.0`, or with the width left out (`draw_line`,
`draw_polyline`, `draw_arc` and outline `draw_rect` default to -1), gets an explicit `1.0`. A lint test enforces it.

Ruling: **Icons at native multiples.** `UiIcon.native_rect(centre, want_units)` returns a square of
`42·m / k` units with `m = max(1, floor(want_units · k / 42))`, snapped to device pixels. The 84-px big icon is
used when `m` is even. An icon is never drawn below 42 device px.

Ruling: **Locked icons are grey copies, built at load.** `UiIcon.grey(tex)` makes a desaturated image once
(luma, ×0.85), cached by resource path. When `get_image()` is null (headless dummy renderer), it falls back to
the old tint. The rule is pure on an `Image`, so it can be tested.

Ruling: **Integer scaling lands first, alone.** Task 1 only adds `window/stretch/scale_mode="integer"` to the
current viewport mode. It is crisp everywhere, with black borders at in-between sizes until the expand task.

## 4. Architecture

```
Window (root, canvas_items, integer k, content_scale_size = area)        <- UiScale.apply()
├── Game / TitleScreen / … (Nodes, as today)
│   ├── WorldView (Node)                                    <- hosts the world, forwards input
│   │   ├── SubViewport "World" (size = area units, UPDATE_ALWAYS,
│   │   │   snap_2d_vertices_to_pixel = true, default clear color)
│   │   │   └── Mission | Battlefield (+ town) …            <- world only: GroundPlane, layers, camera,
│   │   │                                                       TownGrade 1, glow 3, post 4, flash 5
│   │   ├── TextureRect "Display" (root canvas layer 0, pos 0,0, size = area,
│   │   │   texture = World.get_texture(), nearest, MOUSE_FILTER_IGNORE)
│   │   └── Node "Ui"                                         <- hud_layer 6, ZoomReadout, overlays, legend
│   └── screens' CanvasLayers (10, …) as today
```

`WorldView` (new, `src/game/ui/world_view.gd`, `class_name WorldView extends Node`):
- `var viewport: SubViewport`, `var display: TextureRect`, `var ui: Node`
- `func host(node: Node) -> void` — adds `node` under `viewport`
- `static func of(node: Node) -> WorldView` — the WorldView whose viewport holds `node`, else null
- `static func ui_parent(node: Node) -> Node` — `of(node).ui` if hosted, else `node`
- `static func self_host(node: Node) -> bool` — main-scene, windowed, unhosted: defers hosting and returns true
- `static func world_xf(ui_node: Node, world: Viewport) -> Transform2D` — the world's canvas transform (identity mapping)
- `static func mouse_in_view(world_node: Node) -> Vector2` — root mouse in world-viewport px when hosted, else
  the node's own viewport mouse
- `_unhandled_input(e)`: `viewport.push_input(e, true)`; if `viewport.is_input_handled()`, mark the root handled
- follows `UiScale.changed`: resizes `viewport` and `display` to the area and sets `CameraShake.view_fit` on the
  hosted camera (the expand task)

`UiScale` (new, `src/game/ui/ui_scale.gd`, `class_name UiScale extends RefCounted`, statics only):
- `const DESIGN := Vector2i(640, 360)`, `const MAX_WORLD_W := 840.0`, `const REF_H := 360.0`
- `static func layout(window: Vector2i) -> Dictionary` (pure) → `{k: int, area: Vector2i, offset: Vector2i, fit: float}`
- `static func install(tree: SceneTree) -> void` — idempotent; no-op in headless; connects `root.size_changed`; applies `--window=WxH`
- `static func k() -> int`, `static func area() -> Vector2` (640×360 when not installed)
- `static func design_offset() -> Vector2` — `floor((area - DESIGN) / 2)`
- `static func anchor(design_rect: Rect2, where: int) -> Rect2` — moves a 640×360-designed rect to the area by edge
  (`TOP_LEFT, TOP, TOP_RIGHT, LEFT, CENTRE, RIGHT, BOTTOM_LEFT, BOTTOM, BOTTOM_RIGHT`); identity when the area is 640×360
- `static func snap(p: Vector2) -> Vector2` — `round(p·k)/k`
- `static func design_frame(layer: CanvasLayer, filter: int) -> Control` — a full-area blocker Control with a
  640×360 child Control centred at `design_offset()`. The child gets the screen's draw and `gui_input`, so its
  local coordinates are today's 640×360 coordinates.
- `static func backdrop(frame: Control) -> Rect2` — the full area in the frame's local coordinates (replaces `Rect2(0,0,640,360)` fills)
- `static var notifier: UiScaleNotifier`: a RefCounted object with `signal changed(layout: Dictionary)`, emitted
  after every apply. A static class cannot own a signal, so the object carries it.

`UiIcon` (new, `src/game/ui/ui_icon.gd`, statics): `native_rect(centre, want_units) -> Rect2`,
`texture_for(key, m) -> Texture2D` (42 or 84 px), `grey(tex) -> Texture2D`, `grey_image(img) -> Image`,
`draw_round(on: CanvasItem, tex, rect: Rect2, tint := Color.WHITE)` (icon clipped to a circle with
`draw_colored_polygon(pts, tint, uvs, tex)`, 32 segments).

`CameraShake` gains `var view_fit := 1.0`, `func zoom_to(z: float)` (stores the logical zoom and sets
`zoom = Vector2.ONE * z * view_fit`) and `func logical_zoom() -> float`. Every writer of `camera.zoom` outside
CameraShake goes through `zoom_to`, and every reader that is simulation or game logic uses `logical_zoom()`
(lint test).

`Battlefield` gains `const SIM_VIEW := Vector2(640, 360)`, `func sim_view_size() -> Vector2`,
`func ui_parent() -> Node`, `func mouse_screen() -> Vector2`. `mouse_ground()` uses `mouse_screen()`.
`hud_layer` is created under `ui_parent()`.

## 5. Coordinate model

| Space | Unit | Size | Who uses it |
|---|---|---|---|
| device | window pixel | W×H | OS, captures |
| UI unit | k device px | area = floor(W/k)×floor(H/k) (640×360 before the expand task, and in headless) | every CanvasLayer in the root; `event.position` |
| world view | 1 world-framebuffer px = 1 UI unit | area | camera, Person.view math, clamp, picking |
| design frame | UI unit | 640×360 rect at `design_offset()` | menu screens' local coords (unchanged constants) |
| reference world | world px at zoom 1 | ≤ 840×360 visible (fit) | fairness |

Size table (k, area in units, fit, visible world at zoom 1 in reference px):

| Window | k | Area | fit | Visible world |
|---|---|---|---|---|
| 1280×720 | 2 | 640×360 | 1.0 | 640×360 |
| 1366×768 | 2 | 683×384 | 1.0667 | 640×360 |
| 1600×900 | 2 | 800×450 | 1.25 | 640×360 |
| 1920×1080 | 3 | 640×360 | 1.0 | 640×360 |
| 1920×1200 | 3 | 640×400 | 1.1111 | 576×360 |
| 2560×1080 | 3 | 853×360 | 1.0155 | 840×354 |
| 3440×1440 | 4 | 860×360 | 1.0238 | 840×352 |
| 2560×1440 | 4 | 640×360 | 1.0 | 640×360 |
| 1024×600 | 1 | 1024×600 | 1.6667 | 614×360 |

## 6. Anchoring rules

- **HUD** (Hud, ZoomReadout, legend button and plates, FPS meter): each block anchors to its nearest edge of the
  area with `UiScale.anchor` (slots bottom centre, status top right, objective/hint stack top left, chain/ascend
  next to the slots, banners top centre). Nothing is placed by `640`/`360` literals. `Hud._view()` is the area.
- **World-anchored marks** (map tags, edge arrows, hint plates over people, wish tags): world point →
  `WorldView.world_xf` → UI units (identity mapping). Edge arrows clamp to `Hud._view()` minus `STACK_PAD`, as today.
- **Menus and full screens**: layout constants stay in the 640×360 design frame, centred. Backdrops and dimmers
  fill the whole area (`UiScale.backdrop`). The blocker Control behind the frame takes `MOUSE_FILTER_STOP` for
  modal screens (pause, options, results), so clicks never reach the world.
- **Fader and full-screen flashes** cover the area.
- At area 640×360, every anchor is the identity, so today's 1280×720 and 1920×1080 layouts are pixel-for-pixel the
  same (apart from the deliberate text and icon changes).

## 7. Skill tree redesign (exact)

Geometry stays in the 640×360 design frame (`TreeWheel` unchanged: CENTER (320,132), NODE_R 12, RY0 22,
RY_STEP 20, RX_SCALE 1.45, the same ANGLES). Sizes are in units, with 3× device px in brackets.

**Text:** everything is 11 u [33 px] except the selected power's name in the detail panel, which is 22 u [66 px].
`NODE_NAME_PX` and `SMALL_PX` go from 9 to 11, `SIZE_CHIP` from 12 to 11, and sizes 8 (`SMALL_PX - 1`) go to 11.

**Nodes (wheel):**
| Part | Size |
|---|---|
| disc | r 12 u [36 px], fill `COL_NODE` 0.95 |
| icon | native: k2 21 u [42 px], **k3 14 u [42 px]**, k4 21 u [84 px], k6 21 u [126 px]; clipped round (`UiIcon.draw_round`), centred and snapped |
| state ring | 2 u [6 px] stroke at r 11 |
| owned | ring `COL_GOLD`, outer glow arc r 12.5 3 u alpha 0.25, level pips 3×2 u [9×6] under the disc (as now) |
| affordable ("can") | ring `hue.lightened(0.2)` + pulse: 3 filled circles r 15/17/19 u, alpha `0.05 + 0.07·(0.5+0.5·sin(2π·t/1.6 s))`. Redraw each frame only while a `can` node is shown |
| poor (open, not enough points) | ring `hue.darkened(0.35)`, icon full colour, no glow |
| locked (tier above) | grey icon at full opacity (`UiIcon.grey`), ring `#4a4358` alpha 0.8, lock badge: disc r 5 u [15 px] `#120e1a` at node + (8, 8) with a 1 u ring `#8a8090`, padlock body 5×4 u + shackle arc r 1.5 u in `#b8b0c4` |
| selected | `COL_SELECT` ring 2 u at r 14, halo 2 u at r 16 alpha 0.25 |
| hover | ring `lightened(0.3)` |
| empty | dashed circle as now |

**Labels:** 11 u cream `#f3e7c0` (selected `COL_SELECT`, locked `#8a8296`) on a strip of text width + 6 u ×
13 u, `Color(0.03, 0.02, 0.06, 0.82)`. Placement is `SkillTreeScreen.label_layout(col) -> Dictionary`
(`Vector2i(tier, i) -> Rect2`), cached per centred column, placed outermost tier first. Candidates in order:
radial outward (strip centre at node + dir·(r + 4 + half the strip extent)), below, above, the outer side. The
first that clears every disc grown 3 u, every earlier strip grown 2 u, the ring numeral plates and the top bar,
stays inside `Rect2(124, 28, 392, 218)` and does not touch the side panels or `DETAIL`. If none clears, the
radial spot is used and a test fails.
**Orbit fade:** each ring is drawn as 72 segments. A segment whose midpoint lies in any strip grown 3 u is drawn
at alpha 0.12. Ring numeral plates: 16×12 u, numeral 11 u.

**Top bar** (`TOP_BAR` 640×26): BACK_RECT (6, 4, 52, 18), "< BACK" 11 u. "SKILL TREE" 11 u gold at x 64, with
"Tier n · level n" 11 u dim after it. Chips: 11 u; the centred chip has the hue border, a 2 u outer halo and a
brighter fill; a neighbour chip shows " x2" 11 u `#c07a4a`. Points box right-aligned to x 632: diamond, "Ability
points" 11 u dim, the value 11 u `#f3d36a`.

**Side panels** (`SIDE_L` 8,34,112,198; `SIDE_R` 520,34,112,198): title 11 u hue at +24; "your nature" or
"neighbour" 11 u dim at +37; pill "x2 cost" 52×13 u at +42. Mini cells 22 u [66 px], 2 columns centred at
mid ± 13, rows at y + 60 + 24·(tier-1) (the last row ends at +178). The roman tier numeral is 11 u dim at mid − 40.
The mini icon is native with want 18 u (k2 21 u, k3 14 u [42 px], k4 10.5 u [42 px], k6 14 u [84 px]), clipped
round in a disc r 11. The bottom line (baseline panel.end.y − 8) shows the hovered mini's name (cream, `fit` to
104 u), else "click to centre" (dim). Lock and states as on the wheel, with the badge scaled to r 4.

**Detail panel** (`DETAIL` 8,250,624,102): `CLIP_BOX` (15,258,152,86) unchanged. Info column x 176, w 202:
name 22 u `#f3e7c0` at baseline 278 (`fit` to 202 at 22 u, falling back to 11 u when even the first word does
not fit); tags 11 u in 13-u pills at y 283; description 11 u, 2 lines at baselines 309 and 321.
**Level column** x 387..519: head 11 u dim at baseline 268, rows every 12 u. **One right-aligned value
column:** old values right-aligned to `right − new_w_max − 10`, a drawn chevron arrow 6×5 u at
`right − new_w_max − 8`, new values right-aligned to `right` (`right = 513`). Only the arrow and the new value
are `COL_GREEN`; labels `#bfb49a`, old values `#c8c0ac`. An unchanged row shows its value alone, right-aligned in
`#c8c0ac`. The Might row and the twist follow (twist 11 u `COL_TWIST`, at most 2 lines). Rows that do not fit
are dropped, as now.
**Buttons:** REMEMBER_RECT (528, 256, 96, 26), BUY_RECT (528, 286, 96, 26), each with label and sub-line at
11 u (baselines +11 and +22). **Refusal next to RAISE:** the fresh refusal (`refused_reason`, `COL_BAD`) or the
standing reason (`button.reason`, `COL_BAD` 0.75) is wrapped to 96 u at 11 u, at most 2 lines, centred under
BUY_RECT at baselines 325 and 337. "Not enough ability points" fits as "Not enough ability" / "points". The old
reason line at (INFO_X, 340) is removed.
**Keys hint:** "Esc back    Q / E switch Authority" 11 u dim 0.7 at (10, 246).

Contract kept for `tests/test_skill_tree.gd` and `tests/test_tree_wheel.gd`: `hit()`, `click()`, `select()`,
`learn_at()`, `state()`, `node_state()`, `chip_rect()`, `side_col()`, `mini_rect()` (new numbers),
`points_rect()`, signal `action`, `REFUSALS`. `node_label_rect(tier, i, text)` is replaced by
`label_layout(col)[Vector2i(tier, i)]`; its tests move to the new function.

## 8. Per-screen migration list

| Group | Files | Work |
|---|---|---|
| Foundation | `ui_theme.gd`, `ui_scale.gd` (new), `ui_icon.gd` (new), `world_view.gd` (new), `fader.gd`, `fps_meter.gd`, `art_toggle.gd` | crisp sizes, hairline sweep, area-aware full-rect |
| Skill tree | `skill_tree_screen.gd`, `tree_wheel.gd`, `tree_detail.gd` | §7 |
| HUD & in-mission | `hud.gd`, `legend_panel.gd`, `memory_overlay.gd`, `behaviour_overlay.gd` (panel to UI; world lines stay in the world), `zoom_readout.gd`, `mission.gd` (UI parenting, HUD hit tests unchanged), `battlefield.gd` | edge anchors, world_xf, text ≥ 11 (HUD crisp only), hairlines |
| Menus | `title_screen.gd` (hosts its backdrop), `menu.gd`, `options_panel.gd`, `pause_menu.gd`, `mission_board.gd`, `slot_screen.gd`, `god_select_screen.gd` (+`god_select_art.gd`), `god_hub.gd`, `faith_screen.gd`, `upgrades_screen.gd` | design frame + backdrop, text ≥ 11, hairlines, icons native |
| Flow screens | `prepare_screen.gd`, `results_screen.gd`, `ending_screen.gd`, `interlude_screen.gd`, `campaign_screen.gd` | same |
| Tools and scenes | `game.gd` (hosting, `_capture`, FLOW click), `town_debug.gd`, `sandbox.gd`, `tools/dev/behaviour_check.gd`, `tools/dev/profile_view.gd`, `tools/capture.sh` (`--window`) | hosting, captures |

## 9. Test and proof plan

**New suites:** `tests/test_ui_scale.gd` (layout table §5 exactly, anchors, `design_offset`, snap, crisp sizes,
icon native rects for k 1..6, hairline lint over `src/game/ui/*.gd`, `camera.zoom =` lint);
`tests/test_world_view.gd` (headless SubViewport hosting, `ui_parent`, invariant "no Control in the world",
key and mouse forwarding and handled propagation, `Person.view` size = `SIM_VIEW / zoom` for any viewport size,
unhosted Battlefield keeps `hud_layer` as a child, `mouse_in_view` identity). The existing `test_skill_tree.gd`,
`test_tree_wheel.gd`, `test_hud.gd`, `test_menu.gd`, `test_legend.gd`, `test_slot_screens.gd`,
`test_options.gd`, `test_descend_screens.gd`, `test_endless_screens.gd`, `test_campaign_screens.gd` and
`test_hide_ui.gd` keep passing, with numbers moved only where §7 says. New fit tests are run at the design size,
which is the largest text can get.

**Gates per task:** `bash tools/dev/run_suite_parallel.sh 8` (failures=0), and for any task that touches
`battlefield.gd`, `mission.gd`, `game.gd`, camera or hosting: `bash tools/dev/refs_check.sh --jobs=8` (all OK) and
FLOW alone.

**Proof captures** (Task 10): `--show=tree`, `--show=hub`, `--show=pause`, `--show=results`, `--show=board`
(TIER1 show), `--show=title`, `--show=prepare`, a mission show (`--show=warning`), and
`town_debug --capture-town --only=<one>`, each at **1280×720, 1366×768, 1600×900, 1920×1080, 1920×1200,
2560×1080, 3440×1440** via `--window=WxH` (borderless). Checked by eye and by script: no black bars (corner
pixels are not pure black, except where the art is black), world pixels are k×k blocks (sample a 40×40 world
patch: every run length is a multiple of k), text present at crisp sizes, and the HUD touches the edges. Captures
are evidence, not diffs (capture diffs are unreliable).

## 10. What stays exact

- Every reference in `tools/dev/refs/*.tsv` (digest, crowd_check, the global behaviour rows rendered, every
  scenario row headless) — unchanged values, no re-recording.
- The simulation never reads the window or viewport size (`SIM_VIEW`, logical zoom). Headless runs never host,
  never expand, `fit = 1`.
- Captures at a 1280×720 window are still 1280×720 files with the same world framing.
- Gameplay, input meaning and key bindings. The order of `_unhandled_input` among the root's nodes.
- The UI's look at 640×360 apart from the deliberate changes (text ≥ 11, hairlines one unit, skill tree §7).

## 11. Out of scope

A user UI-size option or fractional UI scale; repainting or new icon art (no PixelLab); converting `_draw` UI into
Control/Theme nodes; new screens or layout redesigns beyond anchoring (except the skill tree); making 13/16-unit
text crisp outside the skill tree and HUD (later pass); gamepad; the VFX sandbox's own debug UI look; a curtain
or border art for ultrawide; changes to world zoom limits.

## 12. Risks

1. **Input order** after moving the world into a SubViewport (Esc and pause, H legend, TAB hide-UI, FLOW clicks).
   Mitigation: forwarding from the hosted node's old tree position; `test_world_view` key tests; FLOW; `test_hide_ui`.
2. **Rendered references and wall-clock hit-stop**: the hosted render path costs a little differently. Mitigation:
   tools host like the game. If a rendered row moves, investigate hit-stop timing; never re-record without the
   user's yes.
3. **Hairlines and thin shapes** missed by the lint (multi-line calls). Mitigation: the lint parses whole calls,
   plus proof captures at k = 3 and 4.
4. **Label fan-out at 11 u** may not find a clear spot for long names on tier I/II. Mitigation: `node_label`
   ellipsis at 84 u, a fit test over every type with `GodTree.dev_fill`.
5. **Screen-texture shaders inside a SubViewport (GL Compatibility)**: TownGrade/TownBloom/glow/impact read the
   SubViewport's own screen texture. Mitigation: Task 2 town capture before/after at 1280×720 (by eye).
6. **Frame rate**: one extra full-window textured quad and UI fill at full resolution. Mitigation: bench pairs
   against 7eb1c6a0 in the final task, on a quiet machine.
