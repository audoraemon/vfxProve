# KAK UI Resolution & Skill Tree Readability — Rulings

Collected from the milestone workspace (.superpowers/sdd/2026-11-13-ui-resolution/rulings.md). Spec: docs/superpowers/specs/2026-11-13-ui-resolution-design.md; plan: docs/superpowers/plans/2026-11-13-ui-resolution.md.

# Rulings: UI Resolution & Skill Tree Readability

Copied from the spec §3 (2026-11-13). New rulings made during execution go below, dated, one line each.

- Architecture = root at full resolution (`canvas_items`), world in a SubViewport hosted by `WorldView` and drawn at the origin with nearest filtering. Rejected: canvas_items without a SubViewport; a second viewport for the UI; a shared World2D with cull masks.
- One integer scale k for world and UI: `k = max(1, floor(min(W/640, H/360)))`. No fractional UI scale and no UI-size option.
- Identity mapping: 1 UI unit = 1 world-viewport px = k device px. HUD hit tests on `event.position` keep working.
- Fill by sizing the content ourselves: `root.content_scale_size = floor(window/k)` on every resize (EXPAND, INTEGER). Never in headless; `project.godot` keeps `aspect="keep"`.
- Fairness by camera fit, not curtains: render zoom = logical zoom × `fit`, `fit = max(area.x/840, area.y/360)`. The visible world is never more than 840×360 reference px.
- Simulation pinned: `Person.view` / `Structure.view` = `Battlefield.SIM_VIEW` (640×360) / logical zoom (or `sim_zoom`). `Mission.clamp_view` keeps the real view size and render zoom.
- Input forwarded by hand: `WorldView._unhandled_input` → `viewport.push_input(e, true)`, propagating handled. No SubViewportContainer. World mouse is read from the root (`WorldView.mouse_in_view`).
- UI never lives in the world viewport: hud_layer, ZoomReadout, overlays and the legend are parented to `WorldView.ui` when hosted, as today when not. Invariant test.
- Hosting: Game hosts missions, TitleScreen its backdrop; Mission, TownDebug and Sandbox self-host as the windowed main scene; behaviour_check and profile_view host when not headless; headless never hosts. `scenes/mission.tscn` is unchanged.
- Captures read the root texture: 1280×720 at a 1280×720 window, as today; other windows at their own size. Sandbox clip capture reads the world viewport.
- Text: nothing under 11 units. Crisp sizes 11/22/33/66 (`TEXT_S/L/XL/XXL`). Skill tree and HUD use only crisp sizes; other screens may keep 13/16 for now.
- Font: keep Pixelify Sans (OFL, committed), antialiasing NONE, liga/clig off, oversampling on (default).
- Hairlines: every UI `draw_*` width is explicit and positive (1.0 = one unit). Lint test.
- Icons at native multiples: `UiIcon.native_rect`, m = max(1, floor(want·k/42)); 84-px source when m is even; never under 42 device px.
- Locked icons: grey copies built at load (luma ×0.85), cached; tint fallback when `get_image()` is null (headless).
- Integer scaling lands first and alone (Task 1: `scale_mode="integer"` with today's viewport mode).
- Skill tree: TreeWheel geometry unchanged (NODE_R 12); every label 11 u on a dark strip, placed by `label_layout` (radial → below → above → side); orbit segments under strips at alpha 0.12; detail name 22 u; one value column (old | arrow | new, only arrow + new green); the refusal wraps under RAISE (≤ 2 lines, 96 u).

## During execution
- 2026-11-13 (pre-flight) Ruling: Task 9 — `CameraShake.logical_zoom()` is derived, `zoom.x / view_fit`, not a separately stored value; `zoom_to(z)` sets `zoom = Vector2.ONE * z * view_fit`; `set_view_fit(f)` keeps the logical zoom and re-applies. Direct writers left in tools/dev (behaviour_check, profile_view; fit 1 there) then stay consistent. `_fit` test: exact at fit 1, within 1e-6 at fit 1.25.
- 2026-11-13 (pre-flight) Ruling: Task 2 — Game makes a fresh WorldView per mission at each add site (`add_child(wv)` where `add_child(mission)` was, then `wv.host(mission)`), so its `_unhandled_input` position equals the mission's old one; a WorldView frees itself (and its `ui` subtree: Hud, legend, ZoomReadout, overlays, FpsMeter) when its hosted node exits the tree. No persistent `_world`.
- 2026-11-13 (pre-flight) Ruling: Task 2 — the UI moved out of the Mission must freeze with it: `Mission.set_frozen` also sets the hosted `WorldView.ui` process_mode (DISABLED/INHERIT) when `_bf.ui_parent() != self`; LegendPanel stays PROCESS_MODE_ALWAYS. Today Hud/ZoomReadout `_process` stop while paused or the legend is open; keep that.
- 2026-11-13 (pre-flight) Ruling: Tasks 2, 3 and 9 — references gate is the 19 sequential rows (17 rendered via behaviour_check, now hosted): `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|gates|fire|rite|soldiers|warning_|miras_play|lanterns_none|flame_|feast_play|capital_calm|capital_evac)'`, plus the full `refs_check.sh --jobs=8` once in Task 9 and at Task 10. Other tasks: implementer.md's subset.
- 2026-11-13 (pre-flight) Ruling: task size — dispatch Task 2 as 2a (WorldView + Battlefield changes + tests `_hosting`, `_bf_layers`, `_keys`, `_mouse_identity`, `_sim_view_pinned`) then 2b (hosting call sites: mission self_host + UI parenting + set_frozen, game.gd, title, town_debug, sandbox, tools, Hud world_xf, FLOW click, `_no_ui_in_world`, refs, FLOW, captures). Task 3 as 3a (UiScale, notifier, UiIcon, UiTheme TEXT_* and tests, no project change) then 3b (canvas_items flip, install/--window, capture resize drop, hairline sweep + lint). Task 6 as 6a (title, menu, options, pause, board) and 6b (slots, god select + art, hub, faith, upgrades). Task 4 may split 4a (wheel: nodes, states, labels, orbit fade) / 4b (top bar, side panels, detail, refusal) if the first report runs long.
- 2026-11-13 (pre-flight) Ruling: Task 4 — `label_layout` is an open risk at 11 u: tier 1-3 nodes sit ~40 u apart round (320,132). If `_labels_clear` cannot pass for some type after `node_label`'s 84-u ellipsis, report DONE_WITH_CONCERNS with the failing (type, tier, i) rather than moving TreeWheel geometry.
- 2026-11-13 (pre-flight) Ruling: Task 2 — behaviour_check's clip-sheet capture (`:1407`) reads the hosted world viewport, so regenerated Remember clips lose the HUD; no clip is regenerated in this milestone.

## Carry-over after Task 2 (from task-2b-review.md)
- Ruling: FLOW alone + full suite + the 11 unfinished parallel ref rows (warning_toll_1/3, flame_toll_1/2/3, warning_b_play_*, flame_b_play_*) run on a quiet machine at Task 10 / landing; not blocking 3a.
- Ruling: Task 3a adds small tests for WorldView.add_hosted (hosted + headless fallback), title hosting, and Game's per-mission view freed with its mission; and a doc line on WorldView.ui that everything under it freezes with the mission.
- Ruling: Task 10 fixes battlefield.gd bench() to measure the root viewport RID (get_tree().root.get_viewport_rid()) so fps compares with recorded numbers; and does the positional-audio ear check.

## Carry-over after Task 3a (from task-3a-review.md)
- Ruling: Task 3b adds a doc line on UiScale.set_test_area (does not change fit()/k()), rewords/prewarms UiIcon.grey (lazy cache, not "at load"), and fixes test_ui_scale.gd:112 (detach without freeing, then assert no connection).
- Ruling: Tasks 4 and 6 draw locked icons with UiIcon.grey AND UiIcon.locked_tint (headless grey is a stand-in).
- Ruling: Task 4 capture checks UiIcon.draw_round by eye at k=2 and k=3.
- Ruling: full suite on a quiet machine is a hard landing gate (2b's test_night_rules regression went unseen).

## Carry-over after Task 3b
- Ruling: Task 6a fixes the pause screen "PAUSED" overlapping the mission-name plate (pre-existing, seen in task-3b captures).

## Carry-over after Task 3b fix round
- Ruling: Task 4 adds draw_circle to the hairline lint (tests/test_ui_scale.gd:205): width index 4, filled flag index 3 with the draw_rect-style literal rule. Do it first, before any new ring drawing.
- Ruling: Task 10 checks render_sprite_refs cottage_red + fountain (2 of 149 differ vs old stretch mode): run twice to tell noise from a real change.

## Task 4 fix round (2026-11-14, from task-4-review.md)
- Ruling: word spacing. `UiTheme.font_for(size)` returns a FontVariation (spacing_space = max(1, round(size/11)) px: +1 at 11, +2 at 22, +3 at 33, +6 at 66); `font()` is `font_for(11)`, `base_font()` the FontFile (antialias/hinting/feature overrides live there). `UiTheme.text` and `width` go through it, so every screen's text is a little wider.
- Ruling: orbit labels show the full power name, never "..."; a strip is sized to its text, and a name that finds no single-line place gets a two-line strip (25 u).
- Ruling: the detail panel's power name that does not fit the info column at 22 u is drawn whole at 11 u (not its first word at 22 u, which would cut the name). Two 22 u lines do not fit between the name baseline and the tags.
- Ruling: the level-5 twist moved out of the level column to the info column under the description (baselines 333 and 345, up to 2 lines, in full); INFO_X 172 and DESCRIPTION_W 210 so every blurb still fits 2 lines with the wider spaces.
- Ruling: affordable pulse alpha 0.14..0.32 (r 17 and r 19 filled, plus a lightened 2 u ring at r 16 at twice that alpha); the spec's 0.05..0.12 was invisible.
- Task 9 checklist: where the content size exceeds 640x360 (1366x768 at k=2 gives 683x384) the skill tree draws from the origin; confirm the host centres it (or that the extra width is dealt with), not left in the top-left corner.
- Ruling (fix round, after the suite): the wider spaces broke the text-fit tests of other screens (mission hints 228 px, board plates and tier boards, slot screens, armoury: 7 failures in 8 suites), so `UiTheme.word_spacing` defaults to false and the skill tree turns it on in `setup()` and off in `_exit_tree()`. Each of Tasks 5-8 re-fits its own screen's text and opts in; Task 8 flips the default to true. tests/run_part.gd resets it per suite.

## Carry-over after Task 4 fix round
- Ruling: UiTheme.word_spacing is a global toggle (skill tree only for now). Tasks 5-8 re-fit their screens with spacing on; Task 8 flips the default to true and removes the per-screen toggle. Final review checks no screen shows mixed spacing while the skill tree is open over other UI.

## Carry-over after Task 6a (controller look at captures)
- Ruling: Task 6b hides (or dims fully) world tags while the pause menu is up: pause_1920x1080 shows "INFORMER" and "WISH" tags poking out beside/under the pause buttons; and keeps Cael's subtitle plate off the pause buttons (campaign night 2).
- Ruling: Task 6b checks unselected board card text contrast (dim gold on black is borderline at 1920x1080); raise it if it reads poorly.

## Carry-over after Task 6b (controller look at captures)
- Ruling: 6b accepted without a separate review (mechanical); captures pause/god-select/upgrades-hover checked by the controller.
- Ruling (Task 8): digits are hard to read in Pixelify Sans at UI sizes: "8" reads as "S" (clock "8:30" -> "S:30"), "5" as "S", "7" as "?". Task 8 owns the fix. First try settings (weight axis, antialiasing off / subpixel off / hinting at TEXT_* sizes, the integer sizes). If digits still read wrong, add an OFL pixel digit fallback face already on disk, or redraw digits as a small FontVariation fallback. No downloads without the controller. Prove it with a capture of the clock, budgets ("48", "78", "90") and "Night 7".
- Ruling: upgrades cut names keep the ellipsis plus the full name on hover (accepted).

## Carry-over after Task 8 (controller)
- Ruling: bitmap digits 0-9 (5x7 / 6x9) in UiTheme accepted; results and HUD clock captures read correctly.
- Ruling: 16 u digits (9 rows vs 11-row letters) accepted for now; final review may ask for a third set.
- Ruling: the suite was not re-run in full after the legend fix; Task 9 runs the full suite anyway.

## Carry-over after final review (controller)
- Ruling (M-8): render_sprite_refs cottage_red differs by 629 px because pixel_root renders under canvas_items stretch. It is a dev tool that renders unhosted, game art is unaffected, and the output is deterministic across runs. Accepted, not restored.
- Ruling: the fix wave runs after the glyph/perf commit (task 11), on top of it: I-1, I-2, M-1..M-7.
- Ruling (task 11 perf): the remaining gap of about 1.5-4.5% (40-90 extra draw calls from atlas switches between the bitmap digit/letter face and Pixelify) is accepted for this milestone. A follow-up idea is to bake the whole UI font into one bitmap atlas. Report it to the user.
