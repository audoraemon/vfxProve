# God's Paths (god select restyle) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle the god select screen into "God's Paths": six pixel-art stone statues on a ruined night temple, ringed round a
turning swirl, with the selected god lit and the rest dimmed.

**Architecture:** `GodSelectScreen` keeps its public contract and its `_draw` approach. A new `GodSelectArt` loads the PixelLab
textures and answers `null` for any that are missing, so the screen falls back to today's boxes piece by piece. Motion is a
clock in `_process` that redraws; the ray position eases toward the selected statue.

**Tech Stack:** Godot 4.7.2, GDScript, PixelLab MCP tools (`mcp__pixellab__*`) and `tools/dev/pixellab_api.py`.

**Spec:** `docs/superpowers/specs/2026-11-11-kak-god-select-restyle-design.md` (reference image beside it in `assets/`).

## Global Constraints

- 640×360 screen; text only through `UiTheme` (`text`, `width`, `wrap`, `SIZE_*`, `COL_*`).
- Ring order is `GodTree.RING` unchanged: Ruin top, then clockwise Passage, Veil, Decree, Death, Dominion. No neighbour or rule change.
- Public contract kept: `ring_rect(i)`, `CHOOSE_RECT`, `BACK_RECT`, `INFO_RECT`, `hit()`, `click()`, `select()`, `confirm()`,
  `type_lines()`, signal `action`, `chosen_type`, `selected`.
- `tests/test_slot_screens.gd` checks stay: ring rects inside the frame, clear of `INFO_RECT` / `CHOOSE_RECT` / `BACK_RECT`, none
  overlapping, `ring_rect(0)` centre x == 320 and the ring clockwise. Only numbers change.
- Copy, exact: title "GOD'S PATHS", subtitle "CHOOSE YOUR AUTHORITY", buttons "‹ Back" and "Enter Path ›", rule note
  "A god's type is chosen once, for this slot.", keys hint "Left and Right look round the ring. Enter chooses. Esc goes back."
- Nameplate verbs, exact: ruin "Destroy · Collapse · Erase", passage "Open · Move · Close", veil "Conceal · Obscure · Displace",
  decree "Law · Bind · Enforce", death "Wither · Harvest · Release", dominion "Control · Command · Bend".
- God colours (aura, banner): ruin red-orange, passage blue, veil teal, decree warm white-gold, death pale green, dominion purple.
- Art: pixel art matching the town art, files under `assets/pixellab/god_select/`. PixelLab budget for this plan: under 150
  generations, re-rolls included. Check the balance before and log every spend.
- No frame-rate drop: one screen, redraw per frame is fine; no per-frame allocation of textures or images.
- Never stop Godot processes another session launched. Never `git stash` bare. Commits end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- After `--import` changes or a new `class_name`: run `"$G" --headless --path . --import` before headless runs
  (`G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`).
- Landing: fast-forward onto `feat/god-progression` and push only with the user's yes; then one dated bullet in #god-changelog.

## Review Focus

1. **Missing or broken art file** — the screen still opens, clicks and keys still work, and the missing piece draws as today's box.
   Test in Task 3 (`_art_missing`).
2. **Text over the busy background** — every text line sits on a dark backing. Checked by the screenshot review in Task 4 (no
   automated test can judge legibility).
3. **Clicking the art outside the hit area** (aura, rays) — selects nothing; only `ring_rect` areas select. Test in Task 1
   (`_hit_areas`).
4. **Fast key presses while the rays slide** — the rays always end on the last selected statue, never stuck between. Test in
   Task 3 (`_rays`).
5. **Long flavour line** (Passage's is the longest) — wraps inside `INFO_RECT` and stays clear of the statues. Test in Task 1
   (`_info_fits`).

---

### Task 1: New layout, copy and nameplates (no art yet)

**Files:**
- Modify: `src/game/ui/god_select_screen.gd`
- Test: `tests/test_slot_screens.gd` (`_layout`, `_ring`, new `_hit_areas`, `_info_fits`)

**Interfaces:**
- Produces: `const VERBS := {type: String}` (exact strings above); `static func verbs(type: String) -> String` ("" for an unknown
  type); `static func statue_anchor(i: int) -> Vector2` (the ring point on the ellipse; the statue's feet stand here).
  Constants `CENTRE`, `RADIUS`, `BOX`, `INFO_RECT`, `CHOOSE_RECT`, `BACK_RECT` with new values.

Starting values (tune only if a check fails; the checks are the contract):
`CENTRE := Vector2(320, 178)`, `RADIUS := Vector2(220, 100)`, `BOX := Vector2(92, 84)` (statue body plus nameplate),
`INFO_RECT := Rect2(196, 124, 248, 108)`, `CHOOSE_RECT := Rect2(260, 330, 120, 22)`, `BACK_RECT := Rect2(8, 332, 90, 20)`.
Title and subtitle at top left; the rule note under the subtitle; the keys hint top right, right-aligned to x 620
(Ruling: the spec put the hint beside Back, but at 640 wide it would run into "Enter Path ›"; top right is free).

- [ ] **Step 1: Write the failing tests**

In `_ring`: `t.check(GodSelectScreen.verbs("passage") == "Open · Move · Close", ...)`, the same for all six exact strings, and
`t.check(GodSelectScreen.verbs("nonsense") == "", ...)`.
New `_hit_areas(t)`: a click at `ring_rect(1).position - Vector2(6, 6)` (outside any hit area, on the aura) leaves `selected`
unchanged and emits nothing; `hit()` of every `ring_rect(i).get_center()` is `"ring:%d" % i`.
New `_info_fits(t)`: with `GodTree.dev_fill = true` (real power names; reset to false after), for every type the flavour wraps to
at most 2 rows at `INFO_RECT.size.x - 16`, and the drawn height
`16 + 22 + flavour_rows × UiTheme.LINE_BODY + 12 + (tier_rows + neighbour_rows) × (UiTheme.LINE_SMALL + 2)` (rows from
`UiTheme.wrap` at the same width, `SIZE_BODY` for the flavour, `SIZE_SMALL` for lines 2 and 3) is `<= INFO_RECT.size.y`.
`_draw_info` must wrap at that same width.
Keep `_layout`'s ring checks as they are. Call the two new functions from `run`.

- [ ] **Step 2: Run to see them fail**

Run: `bash tools/dev/run_suite_parallel.sh 8`
Expected: failures in test_slot_screens (`verbs` not found / info height).

- [ ] **Step 3: Implement**

New constants and `verbs()` / `statue_anchor()`. `ring_rect(i)` = `BOX` centred on `statue_anchor(i)` (the statue stands in its
upper part, the nameplate in its lower ~22 px). `_draw_ui` draws: the title "GOD'S PATHS" (`SIZE_BIG`, gold) and
"CHOOSE YOUR AUTHORITY" (`SIZE_SMALL`, dim); the rule note; the keys hint top right; for each ring spot a nameplate box at the
bottom of `ring_rect(i)` with the god's title and its verbs (`SIZE_SMALL`, fit with `UiTheme.fit`), bright frame when selected or
hovered; the info lines on a translucent dark backing (`Color(0, 0, 0, 0.55)`) sized to the lines, not to all of `INFO_RECT`;
"‹ Back" and "Enter Path ›" in their rects. Keep a plain dark background for now (Task 3 adds the art).

- [ ] **Step 4: Run the suite**

Run: `bash tools/dev/run_suite_parallel.sh 8`
Expected: `failures=0`.

- [ ] **Step 5: Screenshot and commit**

Capture with a throwaway SceneTree script that adds `GodSelectScreen.new()`, calls `setup()`, waits 8 frames and saves
`root.get_texture().get_image()` (run without `--headless`). Check by eye: nothing overlaps, every line readable.

```bash
git add src/game/ui/god_select_screen.gd tests/test_slot_screens.gd
git commit -m "feat: God's Paths layout -- title, nameplates with verbs, centre backing, Enter Path"
```

### Task 2: PixelLab art

**Files:**
- Create: `assets/pixellab/god_select/` with `background.png` (640×360, or 320×180 drawn at 2× if that is the PixelLab size
  limit), `statue_<type>.png` ×6 (transparent, about 64×80, feet at the bottom centre), `swirl.png` (transparent, about
  120×120, turns well), `brazier_<n>.png` flame frames (2–4), `leaf.png` (a few px), `rays.png` (soft vertical light, transparent)
- Create: `assets/pixellab/god_select/README.md`: per file the tool, prompt, seed or id, and generations spent; the total.

**Interfaces:**
- Produces: the file names above, which Task 3's `GodSelectArt` loads.

- [ ] **Step 1: Check the balance**

Call `mcp__pixellab__get_balance`. Record it in the README. Stop and report if under 150 generations.

- [ ] **Step 2: Background**

A ruined temple at night, seen from the front, in KAK's town pixel style: a moon top right, broken stone arches and an aqueduct
behind, red autumn leaves at the left and right edges, wet stone floor with mist, six empty pedestal spots on an oval (where
Task 1's `statue_anchor` points sit), dim. No statues, no text, no swirl (those are separate). Keep the middle darker so the
centre text reads.

- [ ] **Step 3: Six statues**

Grey stone, each with its god's coloured aura ribbons and a small hanging banner with its sign (spec "Statues" list: Ruin crowned
muscular man reaching up with falling rocks, burst sign; Passage woman with orbs, hourglass; Veil hooded woman finger to lips,
eye; Decree bearded man with stone tablet, scales; Death hooded skeleton with hourglass, skull; Dominion crowned woman arms
spread, crown). Same scale, same light direction, front view. Each is its own generation. Fix small faults with the free
`mcp__pixellab__pixelart_workbench`, not re-rolls.

- [ ] **Step 4: Swirl, brazier flames, leaf, rays**

Glowing orange-gold swirl inside a thin gold ring (it is rotated in engine, so keep it round). Brazier flame frames, leaf and rays
may be drawn by hand with `pixelart_workbench` (free).

- [ ] **Step 5: Contact sheet for the user**

Compose all pieces over the background at their Task 1 positions into one PNG (a throwaway script or Pillow; Python is
`/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe`). Show it to the user and get a yes before Task 3. Re-roll
only what they reject, within the budget.

- [ ] **Step 6: Import and commit**

Run: `"$G" --headless --path . --import`, then:

```bash
git add assets/pixellab/god_select
git commit -m "art: God's Paths -- temple background, six god statues, swirl, flames, leaf, rays (PixelLab)"
```

### Task 3: Art and motion on the screen

**Files:**
- Create: `src/game/ui/god_select_art.gd`
- Modify: `src/game/ui/god_select_screen.gd`
- Create: `tests/test_god_select_art.gd`; Modify: `tests/run_all.gd` (add it to `SUITES` next to test_slot_screens)

**Interfaces:**
- Consumes: Task 1's `statue_anchor(i)`, `ring_rect(i)`, `INFO_RECT`; Task 2's file names.
- Produces: `class_name GodSelectArt`, `const DIR := "res://assets/pixellab/god_select/"`,
  `static func texture(name: String) -> Texture2D` (cached; `null` when `ResourceLoader.exists` is false or the load fails).
  On `GodSelectScreen`: `const RAY_TIME := 0.25`; `var ray_x: float` (the rays' current centre x);
  `func lit(i: int) -> float` (1.0 selected, 0.75 hovered, 0.45 otherwise; the statue's modulate value);
  `func advance(delta: float) -> void` (steps the clock and eases `ray_x` to `statue_anchor(selected).x`; `_process` calls it).

- [ ] **Step 1: Write the failing tests** (`tests/test_god_select_art.gd`, `static func run(t)`)

`_lit`: after `select(2)`, `lit(2) == 1.0` and `lit(i) < lit(2)` for every other i.
`_rays`: `select(1)`; `advance(RAY_TIME * 0.5)` leaves `ray_x` strictly between the old and new anchor x; after
`advance(RAY_TIME)` it equals `statue_anchor(1).x` (within 0.5). Then `select(3)`, `select(4)`, `select(5)` with
`advance(0.01)` between, then `advance(RAY_TIME)`: `ray_x` equals `statue_anchor(5).x`.
`_art_missing`: `GodSelectArt.texture("no_such_piece") == null`; a screen whose art lookups all fail (add
`static var art_off := false` on `GodSelectArt`, true makes `texture()` return null; reset it after) still draws (call
`_ui.queue_redraw()` and await one frame without an error), and `click(ring_rect(3).get_center())` then
`click(CHOOSE_RECT.get_center())` chooses decree.
`_art_present`: every Task 2 file name returns a non-null texture.

- [ ] **Step 2: Run to see them fail**

Run: `bash tools/dev/run_suite_parallel.sh 8`
Expected: test_god_select_art fails (class not found until the import).

- [ ] **Step 3: Implement**

`GodSelectArt.texture()` as specified. The screen draws, back to front: background (plain fill if null); rays at `ray_x`
(additive, soft); the swirl at `CENTRE`, rotated by the clock (slow, about one turn in 20 s); for each spot, its statue with its
feet on `statue_anchor(i)`, modulated by `lit(i)`, with a soft aura glow in the god's colour stronger when lit (fallback: today's
box); brazier flames beside each pedestal cycling their frames (about 8 fps, each a different phase); 6–10 leaves drifting down and
wrapping, positions from the clock (no random per frame; seed once in `setup`); then Task 1's nameplates, info backing and text,
and buttons on top. `_process(delta)` calls `advance(delta)` and `_redraw()`.

- [ ] **Step 4: Import, run the suite**

Run: `"$G" --headless --path . --import` then `bash tools/dev/run_suite_parallel.sh 8`
Expected: `failures=0`.

- [ ] **Step 5: Commit**

```bash
git add src/game/ui/god_select_art.gd src/game/ui/god_select_screen.gd tests/test_god_select_art.gd tests/run_all.gd
git commit -m "feat: God's Paths art and motion -- statues lit and dimmed, rays follow the pick, swirl, flames, leaves"
```

### Task 4: Check in the game and hand to the user

**Files:** none new (fixes, if any, in Task 1–3 files).

- [ ] **Step 1: Screenshots**

The Task 1 capture script at frames 8 and 60 (motion moved), with Ruin, then Veil selected. Check: every text line readable on
its backing, the selected statue obvious, rays on it, nothing clipped at the screen edges.

- [ ] **Step 2: Frame rate**

Run the game with `play_dev.bat`'s command plus `--disable-vsync`, open the god select (Endless Night, new slot) and read the fps
(the engine's monitor or a print in a throwaway local change). Compare with the old screen from `origin/feat/god-progression`.
Expected: no visible drop. Run alone (no other session's Godot benches running).

- [ ] **Step 3: Full checks**

Run: `bash tools/dev/run_suite_parallel.sh 8` → `failures=0`. FLOW only if a board or flow file changed (it should not).

- [ ] **Step 4: Show the user**

Send the screenshots and tell them to try it with `play_dev.bat` (Endless Night → New → the god select). Wait for their yes or
changes. Do not push.

- [ ] **Step 5: Land on the user's yes**

Fetch; check `origin/feat/god-progression` is an ancestor of this branch (rebase onto it if not, rerun the suite); fast-forward
`feat/god-progression` in `C:/BURIN_NITRO/Godot/GIT/vfxProve-god` to this branch; push only with the user's yes; post one dated
bullet in #god-changelog (channel id 1568235960448188522); update the Dev Ledger task.

---

## Round 2 (after the user's review of Tasks 1-3)

Spec: "Round 2" section of the design. Task 4 above is replaced by Task 8. Ring order, rules, controls, exact copy (except the
keys hint, now two lines: "Left / Right look round the ring" and "Enter chooses · Esc goes back") and the public contract names
stay. Global Constraints still bind.

### Task 5: Statues on the platforms, names on the fronts, top panel

**Files:**
- Modify: `src/game/ui/god_select_screen.gd`
- Test: `tests/test_slot_screens.gd`, `tests/test_god_select_art.gd`

**Interfaces:**
- Produces: `const FEET := [Vector2(324,151), Vector2(476,170), Vector2(521,253), Vector2(317,300), Vector2(118,253), Vector2(161,170)]`
  and `const NAME_AT := [Vector2(324,158), Vector2(476,177), Vector2(521,273), Vector2(317,321), Vector2(118,274), Vector2(161,177)]`
  (both in `GodTree.RING` order); `static func feet(i: int) -> Vector2` (replaces `statue_anchor`; keep `statue_anchor` as a thin
  alias only if a caller needs it); `ring_rect(i)` = the statue's body column, 40 wide centred on `feet(i).x`, from `feet(i).y - 79` down to
  `NAME_AT[i].y + 6` (the carved name). 40, not the sprite's 64: at 64 Death's and Dominion's boxes overlap (x 129-150, y 174-183). `INFO_RECT := Rect2(186, 2, 268, 66)`,
  `CHOOSE_RECT := Rect2(520, 334, 112, 18)`, `BACK_RECT := Rect2(8, 334, 90, 18)`. `const EMBLEM_AT := Vector2(320, 206)`.
- Removes: the ellipse (`CENTRE`, `RADIUS`, `BOX`, `PLATE_H`), the nameplates, the rays (`ray_x`, `ray_y`, `RAY_TIME`,
  `rays.png` use) and the swirl. `swirl.png` and `rays.png` stay on disk unused (delete them in this task's commit; update the art
  README).

- [ ] **Step 1: Update the tests**
  `_layout`: ring rects inside the frame, clear of `INFO_RECT`/`CHOOSE_RECT`/`BACK_RECT`, none overlapping (unchanged checks);
  replace the `top.x == 320` check with: `ring_rect(0)` is the highest (smallest centre y) and the six centres, by angle around
  `EMBLEM_AT`, run clockwise in `GodTree.RING` order. Add: `feet(i) == FEET[i]` for all six; the statue drawn for spot i has its
  plinth bottom centre at `feet(i)` (assert the computed draw rect: `Rect2(feet(i) - Vector2(32, 79), Vector2(64, 80))`).
  `_info_fits`: same rule against the new `INFO_RECT` (flavour at most 2 rows; Tier 1 and Neighbours each their own line).
  `test_god_select_art`: drop the ray tests; keep `_lit`, `_art_missing`, `_art_present` (without swirl/rays).
- [ ] **Step 2: Run, see the new checks fail** (`bash tools/dev/run_suite_parallel.sh 8`, or part 8 alone).
- [ ] **Step 3: Implement** the layout in mockup `docs/superpowers/specs/assets/2026-11-11-god-select-round2-mockup.png`:
  statues back to front by feet y; a small dark contact shadow under each plinth; carved names (light stone `#B2B8C8` letters
  with a 1 px dark outline, selected one gold `COL_GOLD`, size `SIZE_SMALL` or smaller if it overflows the front face); top
  panel as in the mockup (name `SIZE_BIG` gold, verbs small in the god's colour, flavour `SIZE_BODY`, Tier 1 and Neighbours small
  dim, each on its own line); title block top left with the rule note on two lines; keys hint two lines top right; Back bottom
  left; Enter Path bottom right. Dim unselected statues to about 0.72 (not 0.45); hover 0.86.
- [ ] **Step 4: Suite green, screenshots** (Ruin, Veil, Decree picked) compared with the mockup; nothing overlaps.
- [ ] **Step 5: Commit**.

### Task 6: Emblems and power effects (art)

**Files:**
- Create: `assets/pixellab/god_select/emblem_<type>.png` ×6 (transparent, about 56×56, the god's sign in its colour, pixel art
  that matches the statues' banner signs), and effect frames `fx_<type>_<n>.png` per god (transparent; the burst and the loop may be
  one strip of frames or two sets: `fx_<type>_burst_<n>` and `fx_<type>_loop_<n>`; size fits the statue plus its glow, about
  96×112, feet at the bottom centre).
- Modify: `assets/pixellab/god_select/README.md` (tool, prompt, generations per piece).

- [ ] **Step 1:** check the balance. Budget for this task: under 60 PixelLab generations; prefer the free `vfx_workbench` (animated
  effects) and `pixelart_workbench` for the effects.
- [ ] **Step 2:** six emblems (spec Round 2 list).
- [ ] **Step 3:** six effects, one per god, matching the spec's Round 2 description, readable at 1× on the dark scene.
- [ ] **Step 4:** contact sheet: the round 2 layout with each god picked in turn (six frames, or a strip) plus the emblems close
  up; save in the scratchpad and the plan workspace. The controller shows it to the user before Task 7.
- [ ] **Step 5:** import and commit.

### Task 7: Emblem and power effects on the screen

**Files:**
- Modify: `src/game/ui/god_select_screen.gd`, `src/game/ui/god_select_art.gd` (frame-set lookup)
- Test: `tests/test_god_select_art.gd`

**Interfaces:**
- Produces: `func emblem_type() -> String` (the type whose emblem shows; follows `selected`); `const EMBLEM_FADE := 0.2`;
  `var fx_age: float` (seconds since the current pick); `func fx_phase() -> String` (`"burst"` while `fx_age < BURST_TIME`, then
  `"loop"`); `const BURST_TIME := 0.6`; `GodSelectArt.frame_set(prefix: String) -> Array[Texture2D]` (probes `prefix + "_1"`… like
  the braziers; empty when missing).
- [ ] **Step 1: Tests**: after `select(2)`, `emblem_type() == "veil"`; `fx_age` resets to 0 on each new pick and a repeat
  `select(2)` does not restart it; `fx_phase()` is `"burst"` at `advance(BURST_TIME * 0.5)` and `"loop"` after `advance(BURST_TIME)`;
  quick picks (select 3, 4, 5 with tiny advances) end with the burst running for 5; with `art_off` the screen still draws
  (`_draws > 0`) and picks still choose.
- [ ] **Step 2:** see them fail.
- [ ] **Step 3: Implement**: the emblem at `EMBLEM_AT`, cross-fading (old out, new in, `EMBLEM_FADE`) with a slow soft pulse; the
  selected god's effect drawn at its feet, burst frames then loop frames (or one set played once fast then looping); the effect
  draws behind the carved names; others dimmed (Task 5). Missing frames: skip the effect, keep the lit statue.
- [ ] **Step 4:** suite green; screenshots of each god mid-burst and in the loop.
- [ ] **Step 5:** commit.

### Task 8: Check in the game and hand to the user (replaces Task 4)

As Task 4's steps 1-5: screenshots, frame rate (art on/off, 1200 frames, vsync off), full suite, show the user (they try it with this
worktree's `play_dev.bat`), land on their yes (fast-forward `feat/god-progression`, push, #god-changelog bullet, Dev Ledger).

### Task 6b: Living emblems (art) — amends Task 6 after the user's review

- Replace `emblem_<type>.png` with turn frames `emblem_<type>_1..N` (N = 16 suggested; one full turn; transparent; about 64-72 px;
  pre-rendered so pixels stay clean — no engine scaling for the turn), with the god's own touch (spec Round 2b) animated inside the
  same frames, and edge light that follows the turn. One shared or per-god entrance set `emblem_flash_1..M` (a flash the emblem
  bursts out of). Spark sprite(s) `emblem_spark_1..K` in each god's colour or white to tint. Record fps, sizes and centres in the
  README. Budget: PixelLab allowed, under 40 generations; hand-drawing by the existing script is fine.
- Contact sheet + one GIF per god of the emblem turning (with glow, sparks, ring and reflection mocked as Task 7 would draw them),
  for the user's review.

Task 7 amendments: the emblem draws behind the statues at about (320,200), playing its turn frames; the engine adds the bob
(a few px, slow), the pulsing glow, the orbiting sparks (half drawn behind the emblem, half in front, on an ellipse), the ring of
light and the faint flipped reflection on the pool, and the entrance (flash frames + a quick scale-in) on each new pick. Tests add:
`emblem_frame()` advances with time; a new pick restarts the entrance; sparks split behind/in front by their orbit angle.
