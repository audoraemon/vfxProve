# Veil Twists, Second Round, Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace three level-5 Veil twists: Dread of the Dark takes who stops at its edge, The Swallowing Dark leaves hurting moon craters, Evernight's torches are a false light that takes their huddles at the dawn.

**Architecture:** Each twist lives in its own power file and replaces the old twist code there; the craters are one new node (`MoonCraters`) laid on the ground at the fold. Everything reuses `PowerBook.twist_at`, the Pale Eye (`PaleEye.mark` / `mark_by`), `VeilParts.take_out` and `Crowd.spared`. Levels 1-4 run no twist code, so no reference row moves.

**Tech Stack:** Godot 4.7.2 GDScript; tests are `tests/test_*.gd` suites run by `tests/run_part.gd`.

**Spec:** `docs/superpowers/specs/2026-11-26-kak-veil-twists-2-design.md` (on top of `docs/superpowers/specs/2026-11-24-kak-veil-ability-levels-design.md`).

## Global Constraints

- Branch `god/veil-twists-2` in worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-veil`; never push, never merge.
- Powers are reusable effects, never hard-coded into `CitizenAgent` or `Person`.
- Levels 1-4 change nothing: no twist code runs unless `PowerBook.twist_at(extra, key)` is true; level tables' numbers unchanged.
- No luck: anything placed "at random" is seeded from the cast (same click, same result), never a per-run rng.
- Sparing: `Crowd.spared(p)` (the god's believers, whom the mission keeps alive) are eyed, never taken or hurt, in all three twists.
- Takes leave no body: `VeilParts.take_out(crowd, p, kind)` with a kind not in `Remains.BODY_KINDS`.
- Sounds: CC0 library / foley recipes only, never Sonniss (public repo). A new cue raises the counts in `tests/test_sfx_catalog.gd`.
- Twist lines in `src/game/power_book.gd` level-5 rows and `tests/test_veil_levels.gd` TWISTS, exactly:
  - dread: `The Dark Takes Who Looks: who stops is taken`
  - swallow: `The Moon's Face: craters eat who stays`
  - evernight: `The False Light: at dawn the torches take`
- Every Godot run is wrapped in `timeout` and grepped for `SCRIPT ERROR` (a parse error hangs run_part).
- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`; a new `class_name` needs `"$G" --headless --editor --path . --import` first.
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Decisions (controller's, from the spec)

- VT1 Dread's take kind is `&"void"` (The Swallowing Dark's, no body).
- VT2 Crater numbers (spec "about a third"; the spec's 0.8-2.2 radii covered only ~15%): radius 1.2 to 2.8, 9 craters at the light size, 20 at the dark size, so they cover about a third of the circle.
- VT3 A crater's hurt does not call `Person.hurt()` (it emits `enemy_struck`, wakes, and kills as `&"frenzy"` leaving a body): it lowers `health` by `CRATER_HURT * step`, flashes, and at 0 or less takes him with `VeilParts.take_out(crowd, p, &"void")`. A sleeper or a shadow's owner is hurt and not woken.
- VT4 Evernight's level-5 torch colour `FALSE_COLOR := Color(0.55, 0.75, 1.0)`; `END_R`, `torch_r()`'s shrink and `_shrink_lights()` go; every reader of the light's radius reads `TORCH_R`.

## Review Focus

1. The mission or act ends during a pull, while craters stand, or before the dawn: nothing is taken after teardown, no eye stays open (`PaleEye` released by owner).
2. Two Evernights at once (one sky): a huddler near both torches is taken once; the second take returns false and nothing breaks.
3. A person the mission needs walks into a crater or stops at the dread's edge: he is eyed, never hurt or taken.
4. A crater laid over a spared gate, bridge, postern, dock, fountain or a building the mission needs: never placed there.
5. Someone indoors (`p.inside`) at the dawn near a false torch, or inside a crater's circle: passed over.

---

### Task 1: Dread of the Dark -- The Dark Takes Who Looks

**Files:**
- Modify: `src/fx/veil/dread_of_the_dark.gd` (the twist: `_edge_poll`, `_edge_ids`, `_release`, header comments)
- Modify: `src/game/power_book.gd:375` (twist_text), `tests/test_veil_levels.gd:48` (TWISTS dread)
- Test: `tests/test_veil_twist_dread.gd` (rewrite)

**Interfaces:**
- Consumes: `PaleEye.mark(fx, p, key, seconds)`, `PaleEye.release(fx)`, `VeilParts.take_out(crowd, p, kind) -> bool`, `Crowd.spared(p)`.
- Produces: `const PULL := 0.6`, `const PULL_DRIFT := 1.0`, `var taken_at_edge: Array[int]` (instance ids taken by the twist, in order).

- [ ] **Step 1: Rewrite the failing tests** in `tests/test_veil_twist_dread.gd` (keep the suite's existing set-up helpers):
  - `_t_edge_stopper_taken`: a level-5 cast; a citizen walks into the edge and is stopped (`dread_balked_at`); within `PULL + TICK + 0.1` s after the stop he is not alive, `taken_at_edge` holds his id, `Remains` laid no body for him, and he was eyed (`PaleEye.record` has key `"dread"`).
  - `_t_stander_taken`: a citizen standing 0.8 from the dreaded ground for `EDGE_STAND` is taken the same way.
  - `_t_cap_16`: 20 stoppers -> exactly `EDGE_MOST` (16) taken, nearest the click first; the other 4 alive and not frozen by the twist.
  - `_t_spared_eyed_never_taken`: a `spared()` citizen at the edge is eyed and alive after `EDGE_STAND + PULL + 1` s.
  - `_t_held_soldier_taken`: a soldier on a duty at the edge is taken.
  - `_t_pull_drifts_and_fades`: halfway through the pull he is nearer the origin by about `PULL_DRIFT * 0.5` (+/- 0.15) and his alpha is below 1.
  - `_t_teardown_mid_pull`: `end_now()` mid-pull -> he is alive, let go, no eye open for the cast.
  - `_t_level4_no_twist`: level 4, a stopper waits at the edge and is never taken.
- [ ] **Step 2: Run, expect failures**: `timeout 600 "$G" --headless --path . --script res://tests/run_part.gd -- --part=<i> --of=<N>` for the dread twist suite (index from `tests/run_all.gd`); expect FAIL lines, no SCRIPT ERROR.
- [ ] **Step 3: Implement.** In `_edge_poll`, a ready man (not spared, under `EDGE_MOST`) is eyed (`PaleEye.mark(self, p, EYE_KEY, PULL + 0.4)`), held (existing `_hold`) and starts a pull entry; each frame a pull slides him `PULL_DRIFT` toward `origin` over `PULL` with his alpha going 1 -> 0, then `VeilParts.take_out(ctx.crowd, p, &"void")` and his id goes to `taken_at_edge`. `_release` lets go anyone still being pulled. The old "frozen at the edge until the lift" code goes. Twist text line as Global Constraints.
- [ ] **Step 4: Run the dread twist suite, `test_veil_dread`, `test_veil_levels`**: failures=0, no SCRIPT ERROR.
- [ ] **Step 5: Commit** `feat: Dread's level-5 twist takes who stops at the edge (The Dark Takes Who Looks)`.

### Task 2: The Swallowing Dark -- The Moon's Face

**Files:**
- Create: `src/fx/veil/moon_craters.gd` (`class_name MoonCraters extends Node2D`: rules and look of the craters)
- Modify: `src/fx/veil/the_swallowing_dark.gd` (remove `_watch_leavers`, `_marked`, `_queue_marked`, `MarkThreads`, the `&"marked"` queue entry; lay `MoonCraters` in `_swallow()` when `_twist`)
- Modify: `src/game/power_book.gd:397`, `tests/test_veil_levels.gd:49`
- Test: `tests/test_veil_twist_swallow.gd` (rewrite)

**Interfaces:**
- Consumes: `PaleEye.mark_by(crowd, owner_id, p, key, seconds)`, `PaleEye.release_by(crowd, owner_id)`, `VeilParts.take_out`, `Crowd.spared`, the cast's keep-out list (gates, bridge, postern, dock, fountain, buildings the mission needs: the same list `_inside()` spares, line ~509).
- Produces:
  - `static func place(origin: Vector2, full_r: float, count: int, seed: int, keep_out: Array) -> Array` -- `[[centre: Vector2, r: float], ...]`, non-overlapping, inside `full_r`, clear of every keep-out rect/point; same inputs, same output.
  - `const R_MIN := 1.2`, `const R_MAX := 2.8`, `const COUNT := [9, 20]` (light, dark), `const CRATER_HURT := 0.25`, `const TICK := 0.25`, `const EYE_KEY := "crater"`.
  - `var circles: Array`, `func covers(at: Vector2) -> bool`, `var taken: Array[int]`.

- [ ] **Step 1: Write the failing tests** (`tests/test_veil_twist_swallow.gd`):
  - `_t_place_seeded`: `place()` twice with the same inputs -> equal arrays; a different origin -> different.
  - `_t_place_count_and_cover`: light 9 / dark 20 circles, none overlapping, all inside `full_r`; covered area between 0.22 and 0.40 of the circle's.
  - `_t_place_keep_out`: a keep-out point at the origin -> no circle covers it.
  - `_t_laid_at_fold_level5_only`: level 5 cast -> one `MoonCraters` under `ctx.ground` after the fold; level 4 -> none.
  - `_t_hurt_over_time`: a citizen (health 1.0) placed in a crater: alive after 3.0 s, taken (not alive, no body) by 4.5 s; eyed while inside; a soldier (2.0) alive at 7.0 s, taken by 8.5 s.
  - `_t_walk_through_survives`: a citizen inside for 1.0 s then out -> alive, health about 0.75, no longer eyed after the eye's time.
  - `_t_silent`: hurt causes no panic (`mind` unchanged), no `enemy_struck` emission, a sleeper stays asleep.
  - `_t_spared_never_hurt`, `_t_indoors_passed_over`.
  - `_t_stay_for_mission`: craters still standing 120 s after the fold; freed by `Battlefield.clear_effects()`.
- [ ] **Step 2: Import (new class_name), run the suite, expect failures.**
- [ ] **Step 3: Implement `MoonCraters`.** `place()`: `RandomNumberGenerator` seeded with `seed`; up to 60 tries per crater, radius `rng.randf_range(R_MIN, R_MAX)`, centre within `full_r - r`, rejected if overlapping another or a keep-out. The node's `_physics_process` every `TICK`: for living people in `field.in_radius` of each circle, not `inside`, not spared: health falls by `CRATER_HURT * step`, `flash(0.08)`, eyed `PaleEye.mark_by(crowd, get_instance_id(), p, EYE_KEY, TICK + 0.6)`; at `health <= 0` `VeilParts.take_out(crowd, p, &"void")`. Look: dark pits with slumped rims and a faint swirl, Veil palette, drawn once (no per-frame cost beyond the swirl). `_exit_tree` releases its eyes. In `_swallow()`, when `_twist`, seed = `hash(origin.round())`, count = `COUNT[1 if dark else 0]`, add to `ctx.ground` untracked (as `BareEarth`). Twist text line.
- [ ] **Step 4: Run the swallow twist suite, `test_veil_swallow`, `test_veil_levels`, `test_pale_eye`**: failures=0.
- [ ] **Step 5: Commit** `feat: The Swallowing Dark leaves moon craters that eat who stays (The Moon's Face)`.

### Task 3: Evernight -- The False Light

**Files:**
- Modify: `src/fx/veil/evernight.gd` (remove `END_R`, the shrink in `torch_r()`, `_shrink_lights()`; add the false light, the last-seconds eyes, the flare in `_dawn()`)
- Modify: `src/fx/veil/evernight_sky.gd` only if the torch glow's colour is read there
- Modify: `src/game/power_book.gd:408`, `tests/test_veil_levels.gd:49`
- Test: `tests/test_veil_twist_evernight.gd` (rewrite)

**Interfaces:**
- Consumes: `PaleEye.mark`, `VeilParts.take_out(_crowd, p, KIND)`, `Crowd.spared`, the cast's `torches` (dicts with `at`, `bearer`, `out`, `light`).
- Produces: `const FALSE_COLOR := Color(0.55, 0.75, 1.0)`, `const FLARE_EYE := 5.0`, `var flared: Array[int]` (ids taken by the flare), `func huddle_of(tc: Dictionary) -> Array[Person]` (living, out of doors, not spared, within `TORCH_R` of `tc.at`, plus the bearer).

- [ ] **Step 1: Write the failing tests:**
  - `_t_torch_r_constant`: at level 5 `torch_r()` == `TORCH_R` at the fall, mid-night and just before the dawn.
  - `_t_false_colour`: level-5 torches light with `FALSE_COLOR`; level 4 with `TORCH_COLOR`.
  - `_t_huddle_safe_all_night`: a huddler in a torch's light is never claimed or taken before the dawn.
  - `_t_eyed_last_seconds`: no huddler eyed at `FLARE_EYE + 1` s before the dawn; every huddler and bearer eyed at `FLARE_EYE - 0.5` s before it.
  - `_t_flare_takes_huddle`: at the dawn every huddler and the bearer of each burning torch is taken (no body), ids in `flared`; the torch is out.
  - `_t_flare_spares`: a spared huddler and one indoors are alive after the dawn.
  - `_t_two_evernights`: two level-5 casts with torches 1.0 apart -> a huddler in both lights is taken once, no SCRIPT ERROR.
  - `_t_no_flare_on_teardown`: `end_now()` before the dawn -> no one taken, no eye left open.
  - `_t_level4_unchanged`: level 4 dawn takes only what it took before (blighted shelterers, sleepers in dusk).
- [ ] **Step 2: Run the suite, expect failures.**
- [ ] **Step 3: Implement.** Torches at level 5 light with `FALSE_COLOR` (light, glow, island look). From `FLARE_EYE` before the dawn, each huddler and bearer is eyed (`PaleEye.mark(self, p, KEY, INF)`, refreshed for newcomers). In `_dawn()`, when `_twist`, before the existing dawn takes: for each burning torch, take `huddle_of(tc)` with `VeilParts.take_out`, append to `taken` and `flared`, show a black flare (short burst at the torch, Veil palette), put the torch out. Teardown (`_end_night` without `_dawn`) never flares. Twist text line.
- [ ] **Step 4: Run the evernight twist suite, `test_veil_evernight`, `test_veil_levels`**: failures=0.
- [ ] **Step 5: Commit** `feat: Evernight's torches are a false light that takes their huddles at the dawn (The False Light)`.

### Task 4: Docs, final checks

**Files:**
- Modify: `docs/KAK_God_Veil_Summary.md` (section "Twists, second round (2026-11-26)": the three twists, "For your eye and ear"), `docs/KAK_God_Veil_Rulings.md` (section prefix VT: VT1-VT4 + task rulings), `docs/superpowers/specs/2026-11-24-kak-veil-ability-levels-design.md` section 7 (a line under each replaced twist pointing to the new spec).

- [ ] **Step 1: Grep** for the old names (`The Dark Looks Back`, `Nothing Leaves`, `The Light Gives Way`, `END_R`, `_marked`, `MarkThreads`) outside docs history: none left.
- [ ] **Step 2: Write the docs.**
- [ ] **Step 3: Final checks (controller):** the whole suite, FLOW alone, the Veil reference rows (unchanged: levels 1-4 inert), a level-5 bench (dread, swallow with craters standing, evernight to the dawn) bar 1.55 of the base.
- [ ] **Step 4: Commit** `docs: the second round of Veil twists`.
