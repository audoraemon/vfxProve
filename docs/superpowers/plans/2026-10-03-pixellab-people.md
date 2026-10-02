# PixelLab People Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** citizens and soldiers drawn from PixelLab character sprites (17 designs; idle, walk, run, stumble and death in 4 diagonals), with every engine effect still on top, switchable live against the procedural people.

**Architecture:**
- `tools/dev/make_people_atlas.py` packs every design's frames into `assets/pixellab/people/atlas.png`, with a white silhouette copy of each frame, and writes `manifest.json`.
- `PeopleArt` (static) maps a person to a design and an animation frame to its atlas rect.
- `Person._draw_body()` draws that frame instead of the procedural body. Tints (char, ice, flash, sickness) are the silhouette drawn over it at the tint's strength, so one texture and the default shader keep all people in one batch. Light stays in the node's modulate.
- The person's movement each tick picks walk or run against idle, and front against back.

**Tech Stack:** Godot 4.7.2 GDScript; PixelLab REST (`tools/dev/pixellab_api.py` `character` / `char-anim` / `char-get`); Python + Pillow.

**Spec:** `docs/superpowers/specs/2026-10-03-pixellab-people-design.md`. As built, the silhouette overlay replaces the spec's shared shader: it needs no shader, and keeps the light in the node's modulate.

## Global Constraints

- Worktree `F:\Godot\Git\vfxProve-pixellab`, branch `feat/pixellab-structures`. Stage files by name, never `-a`.
- Sizes: characters are created at PixelLab **size 16**, which gives a 24×24 canvas and an 18–19 px figure. Native 1:1, no scaling.
- Directions: south-east, south-west, north-east and north-west, in that order everywhere (atlas rows, `PeopleArt.Facing`).
- Animations: these templates, with their frames per direction; the states' order is the atlas order.
  - idle: `breathing-idle`, 4 frames;
  - walk: `walking-4-frames`, 4;
  - run: `running-4-frames`, 4;
  - stumble: `crouching`, 5;
  - death: `falling-back-death`, 7.
- The people path must never draw from `Person.rng`, nor change `ground_pos`, minds or states. A test proves it.
- Sprites follow `SpriteArt.on()`: F7 and `-- --art=procedural` switch the buildings and the people together.
- Commit messages end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Designs

| Design | Role | Prompt (size 16, standard mode, low top-down) |
|---|---|---|
| resident_a | RESIDENT | medieval peasant townsman, plain brown wool tunic, dark trousers, simple leather shoes, short brown hair *(pilot, done)* |
| resident_b | RESIDENT | medieval peasant townswoman, plain green wool dress, white kerchief on the head, leather shoes |
| merchant_a | MERCHANT | medieval market merchant man, red tunic, leather apron with a coin purse at the belt, flat cap |
| merchant_b | MERCHANT | medieval market merchant woman, yellow dress, white apron, coin purse at the belt, headscarf |
| craft_a | CRAFT | medieval craftsman, grey shirt with rolled sleeves, long brown leather work apron, tools at the belt |
| craft_b | CRAFT | medieval craftswoman, blue dress, long brown leather work apron, tools at the belt, hair tied back |
| laborer | LABORER | medieval laborer, rough beige tunic with rolled sleeves, carrying a sack on the shoulder |
| clergy | CLERGY | medieval priest, long cream robe down to the ground, gold stole, bald tonsure |
| caregiver_a | CAREGIVER | medieval caregiver woman, long brown dress, white apron, white headscarf |
| caregiver_b | CAREGIVER | medieval caregiver man, plain blue tunic, white apron, grey hair |
| farmer | FARMER | medieval farmer, straw hat, beige smock, holding a pitchfork |
| bellkeeper | BELLKEEPER | medieval bellkeeper, long navy blue coat with a brass badge on the chest |
| engineer | ENGINEER | medieval engineer, leather apron, tan leather cap, holding a hammer |
| guard | Corps.NONE | medieval town guard soldier, grey chainmail, royal blue tabard, steel helmet, holding a tall spear upright in the right hand, a blue shield on the left arm *(pilot, done)* |
| marshal | Corps.MARSHAL | the guard, with a **red** tabard |
| escort | Corps.ESCORT | the guard, with a **white** tabard |
| rescue | Corps.RESCUE | the guard, with a royal blue tabard and **a shovel over the shoulder instead of the spear** |

---

### Task 1: The atlas packer and PeopleArt

**Files:**
- Create: `tools/dev/make_people_atlas.py`
- Create: `src/environment/art/people_art.gd`
- Create (generated): `assets/pixellab/people/atlas.png`, `assets/pixellab/people/manifest.json`, `assets/pixellab/people/frames/<design>/<anim>/<dir>_<i>.png` (the raw PixelLab frames, kept so the atlas can be rebuilt)
- Create: `tests/test_people_art.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `PeopleArt.ready() -> bool`, `PeopleArt.atlas() -> Texture2D`, `PeopleArt.design_for(soldier: bool, role: int, corps: int, look: float) -> String`, `PeopleArt.frame_count(design: String, anim: StringName, facing: int) -> int`, `PeopleArt.frame_rect(design, anim, facing, frame) -> Rect2`, `PeopleArt.silhouette_rect(design, anim, facing, frame) -> Rect2`, `PeopleArt.foot(design) -> Vector2`, `PeopleArt.FPS`, `PeopleArt.Facing`, `PeopleArt.ANIMS`.

- [ ] **Step 1: Packer.** `make_people_atlas.py` reads `assets/pixellab/people/frames/<design>/<template>/<dir>_<i>.png`. It maps the templates to the states: `breathing-idle` → idle, `walking-4-frames` → walk, `running-4-frames` → run, `crouching` → stumble, `falling-back-death` → death.
  - **Layout:** one block per design, 8 columns × 20 rows of 24×24 cells. Row = state × 4 + direction; column = frame. Blocks go 6 across; the silhouette blocks follow the design blocks.
  - **Foot:** the bottom centre of the south-east idle frame 0's figure.
  - **Manifest:** `{"cell": [24, 24], "designs": {name: {"block": [x, y], "sil": [x, y], "foot": [fx, fy], "frames": {state: {dir: n}}}}}`.
  - **Missing states:** a design that lacks a state takes its idle (or its rotation) for that state, so the engine never misses a frame.
  - **Copying in:** `--import <design>=<pixellab char dir>` copies a downloaded character's animation folders into `frames/<design>/`.
- [ ] **Step 2: Failing test** `tests/test_people_art.gd`:
  - every role and corps maps to a design present in the manifest, or to its fallback;
  - `look` picks the second design only for the 2-look roles;
  - each frame rect is a 24×24 cell inside the atlas, and its silhouette rect sits in the silhouette block;
  - the foot lies inside the cell.
- [ ] **Step 3: `PeopleArt`.** Reads the manifest and atlas lazily (as `SpriteArt` does). `design_for` falls back to the role's first look, then `resident_a` for citizens and `guard` for soldiers, so a partly generated set still runs.
- [ ] **Step 4:** Pack the pilot (`resident_a`, `guard`), run `bash tools/test.sh` → `failures=0`. Commit.

### Task 2: People drawn from the atlas

**Files:** Modify: `src/game/crowd/person.gd`; Modify: `tests/test_people_art.gd`.

- [ ] **Step 1: Failing test.**
  - **Behaviour:** a crowd scenario (a `Crowd` on the town, a blast, a laser and a freeze, 300 ticks) run twice, with `SpriteArt.set_enabled(true)` then `false`. It compares every person's `ground_pos`, `mind`, `state`, `rng.state`, `_stumble` and `sick_left`, which must be identical.
  - **Frame choice:**
    - a person standing shows idle;
    - one moving right and down the screen shows walk south-east, and moving up-left, walk north-west;
    - a running one shows run;
    - a stumbling one shows stumble;
    - a dead one shows death, holding its last frame after 1 s.
- [ ] **Step 2: Person.**
  - **Movement tracking:** `tick()` keeps `before := ground_pos` around `super(delta)`, then sets `_stride` (it moved) and `_back` (screen-y went up: `d.x + d.y < 0`). Pure drawing state.
  - **`_sprite_pose() -> Array [anim, facing, frame]`**, chosen in this order:
    - dead → death by `_dead_time`;
    - frozen → idle 0;
    - stumbling → stumble by `STUMBLE_SECONDS - _stumble`;
    - lifted or pulled → run by `_anim`;
    - moving → run if `is_running()`, else walk, by `_anim`;
    - otherwise → idle by `_anim`.
  - **`_draw_body()`:** when `SpriteArt.on() and PeopleArt.ready()`, draw the frame at `-foot + (0, lift)`. `top_only` (the laser cut) draws only the rows above the waist (foot.y − 7). Then:
    - the silhouette at `_sprite_tint()` (char toward `COL_CHAR` × 0.85, gravity toward `COL_VOID`, frozen toward ice × 0.75, flash white or lightning blue, sickness toward `SICK_TINT` × 0.35);
    - the confused swirl and the cough mote, as today.
  - **Look:** `_look` comes from a hash of `anchor`, made once (never `rng`).
  - **Signature:** `_art_signature()` in sprite mode folds anim, facing, frame, lift, frozen, flash, state, draw origin, sickness, confusion and the char bucket, so frames redraw exactly when they change.
- [ ] **Step 3:** Tests green; the existing crowd, plague, rescue and escort suites unchanged. Commit.

### Task 3: Pilot in-game

- [ ] Captures with every citizen as resident_a and every soldier as guard, through the fallback:
  - `town_crowd` and `town_market`, sprites against procedural;
  - a scripted panic: `SCENE=res://scenes/town_debug.tscn bash tools/capture.sh --crowd-test` frames;
  - the deaths: the sandbox's `--capture-all` frames near people.
- [ ] Show the user. Check the size, the facing and the motion before generating the other 15.

### Task 4: The other 15 designs

- [ ] Create each (`character --size 16`, 1 generation), then animate the 5 states in the 4 diagonals (20 generations each). Batch it with `batch.py` (4 at a time). About 315 generations.
- [ ] Review sheets per design: the 4 rotations and each state. Re-roll a design whose outfit misses the role, or whose directions disagree. Clean stray pixels by hand where a frame has them.
- [ ] Import every design into `frames/`, pack the atlas, run the tests, capture, and commit per batch of designs.

### Task 5: Proof

- [ ] Tests; `state_digest`; the Task 2 behaviour test.
- [ ] Captures: a calm crowd, a panic, a gate queue, a soldier rally, and a death of each type (blast, fire, gravity, laser, ice), sprites against procedural.
- [ ] Bench (mission, alternating, 3 runs each): within 5 fps, and draw calls not up by more than ~10.
- [ ] Append to `docs/PixelLab_Structures_Proof.md` a "People" section, and to the log a people table: designs, calls, cost.
