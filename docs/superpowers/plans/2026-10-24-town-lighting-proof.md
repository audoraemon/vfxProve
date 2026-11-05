# Town lighting proof (day and night looks) implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two looks, DAY and NIGHT, beside today's CURRENT look as a proof:
- DAY: warm sunlight, cool cast shadows, mist and sunbeams.
- NIGHT: cool moonlight with warm lamp and window pools.

**Architecture:**
- `Town.look` is chosen at build time. CURRENT builds exactly as today, with no new nodes.
- DAY and NIGHT bake the ground neutral, then add four nodes:
  - a static world-space shadow layer: footprint plus height shear, drawn in one CanvasGroup so overlaps don't stack;
  - a screen-space colour grade over the world;
  - world-space additive light pools above the grade;
  - world-space mist and beam quads.
- Nothing touches gameplay, `LightField` registrations or RNG.

**Tech stack:** Godot 4.7.2 GDScript and canvas shaders, GL Compatibility.

**Spec:** `docs/superpowers/specs/2026-10-24-town-lighting-proof-design.md`. Read its "Rules settled after review" section; it is binding.

## Global constraints

- **Worktree:** `C:\BURIN_NITRO\Godot\GIT\vfxProve-lighting`, branch `feat/town-lighting`. Never edit other worktrees.
- **No gameplay change:** the look is CURRENT by default. Every reference in `tools/dev/refs/` stays exact (`bash tools/dev/refs_check.sh`). FLOW passes.
- **Pixel art stays crisp:**
  - no blur or smooth gradients;
  - falloffs, mist and beams are stepped (3–5 bands, or ordered dither);
  - textures use nearest filtering.
- **Layer order, bottom to top:**
  1. floor, plants, forest floor;
  2. the shadow layer;
  3. depth-sorted structures, people and trees;
  4. the grade;
  5. light pools;
  6. Battlefield glow, post and flash layers;
  7. HUD.
- **Sun direction:** shadows fall down-right on screen. Tune the shear vector by eye; the existing contact-shadow lean is `Vector2(6, -3)` per unit.
- **Performance:** within about 3 fps of CURRENT on Aldermere, on a quiet machine.
- **Tests:** run `bash tools/dev/run_suite_parallel.sh 8` before each commit. Expect `failures=0` and 0 `SCRIPT ERROR`.
- **Commits:** stage files by name, including `.uid`, `.import` and `.gdshader`. End the message with a blank line, then `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No art generation, no PixelLab. Don't push until Task 5.
- **v0.12 M1:** tag `kak-v012-m1` may land on Develop-Main mid-way. It brings `City.current()` and touches town code. Task 5 merges it before landing. Earlier tasks keep to `TownLayout` and `town.gd`'s existing data.

## Review focus

1. **Destroying a building in DAY/NIGHT.** Its tall shadow must go and a ruin shadow (or none) take its place. Test in Task 2.
2. **Zooming and panning.** Shadows, pools and mist stay locked to the ground at every zoom from 0.5 to 1.6, with pixel steps in world pixels. Test in Task 3: a pool node's global transform follows the camera, not the screen.
3. **The L key rebuild in town debug.** Cycling CURRENT, DAY, NIGHT, CURRENT must leave no stray nodes and give a CURRENT build identical to a fresh one. Test in Task 1.
4. **Spell glows and flashes at night stay bright.** They sit above the grade. Test in Task 3: the grade layer index is below the Battlefield glow layer's.
5. **Headless and CURRENT create nothing.** Test in Task 1: a CURRENT town has no nodes in the `town_look` group.

---

### Task 1: The look switch and the neutral bake

**Files:**
- Modify:
  - `src/game/town/town.gd`
  - `src/game/town_debug.gd` (`--look`, L key)
  - `src/game/mission.gd` (`--look` passthrough to Town before build)
  - `src/environment/structure.gd` (contact shadow only in CURRENT)
- Create: `src/game/town/town_look.gd` (`class_name TownLook`)
- Test: `tests/test_town_look.gd`, registered in `tests/run_all.gd`

**Interfaces (produces):**
- In `town.gd`:
  - `enum Look { CURRENT, DAY, NIGHT }`
  - `var look: Look = Look.CURRENT`, set before `build()`.
  - `static func look_from_args(args: PackedStringArray) -> Look`: reads `--look=day|night|current`; anything else gives CURRENT.
- `TownLook` holds the per-look constants:
  - `static func ground_tint(look) -> Color`: CURRENT returns `Town.GROUND_EVENING`; DAY and NIGHT return `Color.WHITE`.
  - `static func light_tint(look) -> Color`
  - `static func ambient(look) -> float`
- Group `&"town_look"`: every node a non-CURRENT look adds joins it.
- `Structure.cast_shadows: bool`: static, default true. When false, the contact shadow is skipped, because the Task 2 layer replaces it.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `_parse`: `look_from_args(["--look=day"]) == DAY`, `["--look=night"] == NIGHT`, `[] == CURRENT`, `["--look=x"] == CURRENT`.
  - `_current_untouched`: a CURRENT town has 0 nodes in `town_look`, its floor tint equals `GROUND_EVENING`, and `Structure.cast_shadows` is true.
  - `_neutral_bake`: a DAY town's floor, plant and forest tints are WHITE, and `lights.tint == TownLook.light_tint(DAY)`.
  - `_cycle`: build CURRENT, then DAY, then NIGHT, then CURRENT in one town_debug-like harness (`Town.new()` and free). The final CURRENT has 0 `town_look` nodes, and its structure count equals a fresh build's.
- [ ] **Step 2:** Run the tests and see them fail.
- [ ] **Step 3: Implement.**
  - In DAY and NIGHT, `Town.build()` uses `TownLook.ground_tint` wherever it uses `GROUND_EVENING` / `EVENING` today (`town.gd:152-177`, `town_decor.gd:549`).
  - It sets `lights.tint` and `lights.ambient`, sets `Structure.cast_shadows = false`, and leaves hooks (empty for now) to add the Task 2–4 nodes.
  - In CURRENT the code paths are byte-identical to today.
  - In town debug, L cycles the look and calls the existing rebuild.
  - `mission.gd` sets `town.look` from the args before building.
- [ ] **Step 4:** Run the tests, the suite, and `refs_check.sh --only='^(digest|crowd_check|calm)'`. All must be exact.
- [ ] **Step 5:** Commit `feat: town looks CURRENT, DAY, NIGHT chosen at build; DAY and NIGHT bake the ground neutral`.

### Task 2: Cast shadows

**Files:**
- Create: `src/game/town/town_shadows.gd` (`class_name TownShadows extends Node2D`)
- Modify:
  - `src/game/town/town.gd` (add it between ground and `env` when the look is not CURRENT)
  - `src/game/crowd/person.gd` (foot shadow in DAY and NIGHT)
  - the forest layer (tree blobs)
- Test: `tests/test_town_shadows.gd`

**Interfaces (produces):**
- `static func cast_polygon(diamond: PackedVector2Array, height: float, shear: Vector2) -> PackedVector2Array`: the convex hull of the four footprint corners and those corners plus `shear * height`, in screen pixels.
- `const SHEAR := Vector2(...)`: tune by eye so shadows fall down-right.
- `func rebuild() -> void`: redraws every standing structure's shadow.
  - Flat or walkable kinds (`BuildingTypes` walkable/flat, FARM_FIELD, BRIDGE) cast none.
  - Destroyed structures cast a ruin-height shadow (height × 0.15).
- All shadow polygons are children of one `CanvasGroup` with an opaque colour. The group's `self_modulate` holds the look's shadow colour and alpha, so overlaps never stack.
  - DAY: cool blue-grey, about 0.35 alpha.
  - NIGHT: darker and fainter.
- It reconnects to each structure's destroyed or state-change signal and calls `rebuild()` deferred. It never rebuilds per frame.
- `Person` draws a small ellipse at its feet when `Structure.cast_shadows == false`. Reuse that flag, or `TownLook.active()`.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `_direction`: for a unit diamond at height 20, every hull point's centroid is right of and below the diamond's centroid (screen x+ and y+).
  - `_length`: shadow area grows with height (h=40 area > h=20 area).
  - `_flat`: a FARM_FIELD and a BRIDGE structure add no polygon.
  - `_destroy` (Review focus 1): in a DAY town, destroying the town hall shrinks its polygon to the ruin height on the next idle frame.
  - `_no_stack`: all polygons share one CanvasGroup parent.
  - `_current_none`: a CURRENT town has no `TownShadows`.
- [ ] **Step 2:** Run the tests and see them fail.
- [ ] **Step 3: Implement.** The Citadel parts and towers each cast their own. Forest trees add a blob per tree to the same group.
- [ ] **Step 4:** Run the tests and the suite. Capture DAY town_debug `town_overview` and `town_market`, read them, and tune `SHEAR`.
- [ ] **Step 5:** Commit `feat: DAY and NIGHT cast shadows from footprint and height, one unstacked layer`.

### Task 3: Colour grade and light pools

**Files:**
- Create:
  - `src/game/town/town_grade.gd` (`class_name TownGrade extends CanvasLayer`)
  - `src/game/town/town_grade.gdshader`
  - `src/game/town/town_pools.gd` (`class_name TownPools extends CanvasLayer`, `follow_viewport_enabled = true`)
- Modify: `src/game/town/town.gd` (adds both when the look is not CURRENT; layer indices below Battlefield's `glow_layer`)
- Test: `tests/test_town_grade.gd`

**Interfaces (produces):**
- `TownGrade`:
  - a full-screen `ColorRect` with the grade shader, reading `SCREEN_TEXTURE` via `hint_screen_texture`;
  - uniforms `lift`, `gain` (Color), `warm` (Color), `cool` (Color), `split` (float);
  - DAY: warm highlights, cool darks. NIGHT: darken toward moonlight blue.
- `TownPools`:
  - one additive `Sprite2D` or quad per pool, using a shared stepped radial texture with 4 bands, nearest filtering, generated once in code;
  - `static func pools_for(town: Town) -> Array[Dictionary]`: `{pos: Vector2 screen-world, radius: float, color: Color, flicker: float}`. Built from `lights._lights` entries flagged `static`, read-only, plus one window pool per standing structure whose sprite set has a `glow_mask` (front edge of its footprint, radius from the mask's lit pixel count).
  - Flicker modulates alpha per frame from the light's `flicker`.
  - NIGHT only. DAY gets no pools.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `_pool_count`: in a NIGHT Aldermere, `pools_for(town).size() == static_light_count + lit_window_buildings`.
  - `_lightfield_untouched`: `LightField.sample()` at 5 fixed points is equal in CURRENT and NIGHT before any effect, apart from the look's tint/ambient, which is compared separately. No lights were added.
  - `_layers` (Review focus 4): the grade layer index < the pools layer index < Battlefield's `glow_layer` index.
  - `_world_space` (Review focus 2): after moving the camera by (100, 0), a pool's on-screen position moves by -100 × zoom.
  - `_day_no_pools`: DAY has a grade and no pools.
- [ ] **Step 2:** Run the tests and see them fail.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Run the tests and the suite. Capture NIGHT `town_overview`, `town_market` and a torch street, then read them. Tune the colours.
- [ ] **Step 5:** Commit `feat: DAY and NIGHT colour grade; warm lamp and window pools at night`.

### Task 4: Mist and sunbeams

**Files:**
- Create:
  - `src/game/town/town_mist.gd` (`class_name TownMist extends Node2D`)
  - `src/game/town/town_mist.gdshader`
- Modify: `src/game/town/town.gd`
- Test: `tests/test_town_mist.gd`

**Interfaces (produces):**
- `static func zones(town: Town) -> Array[Rect2]`: ground rects for the forest ring, river or harbour bands, and the border band. They come from town data: `TownLayout` now, `City.current()` after the merge. They never include the town rect (`TownLayout.town()` / `City.current().town()`).
- Mist is drawn as one quad per zone. The shader uses drifting value noise quantised to 3–4 alpha steps, and a world-pixel grid snap. It sits above the grade at night, so it catches the pools' warm light only through the pools layer.
- Sunbeams are 3–5 slanted additive stripes from the top-left. They appear in DAY only, at low alpha, with stepped edges.
- NIGHT mist is thinner and grey-blue.

**Steps:**
- [ ] **Step 1: Write the failing tests.**
  - `_outside_town`: no zone intersects the town rect.
  - `_current_none`: a CURRENT town has no `TownMist`.
  - `_beams_day_only`: there are beam nodes in DAY and none in NIGHT.
- [ ] **Step 2:** Run the tests and see them fail.
- [ ] **Step 3: Implement.**
- [ ] **Step 4:** Run the tests and the suite. Capture DAY `town_overview` and the forest edge. Read the shots and tune them until they never hide people or tags.
- [ ] **Step 5:** Commit `feat: DAY mist and sunbeams, NIGHT mist`.

### Task 5: Proof captures, bench, landing gate

- [ ] **Step 1: Merge v0.12 M1 if it has landed.** If `kak-v012-m1` is on `origin/feat/Develop-Main`, merge it in and resolve conflicts. Move `TownMist.zones` and any town data onto `City.current()`. Re-run the suite.
- [ ] **Step 2: Captures.** For each look (CURRENT, DAY, NIGHT), take the same town_debug shots: `town_overview`, `town_market`, `town_citadel`, the river and bridge, the forest edge, a night torch street. Also take Last Judgement with `--look=day` and `--look=night`, 2 shots each.
  - Make one comparison sheet per spot (CURRENT | DAY | NIGHT) in scratch `lighting\`.
  - Read every shot.
- [ ] **Step 3: Landing checks.** Run `bash tools/dev/land.sh --bench=<latest kak-v* tag>`: suite, all references exact, FLOW alone, trial merge.
  - Bench: Aldermere with `--look=day` and `--look=night` against CURRENT, 3 pairs each, quiet machine. Each must be within about 3 fps.
- [ ] **Step 4: Commit** any capture-shot additions to `town_debug.gd`.
- [ ] **Step 5: Show the user.** The controller shows the comparison sheets. Pushing and merging need the user's yes.
