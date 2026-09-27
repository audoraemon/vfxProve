# KAK town performance, second pass — plan

**Goal:** the town centre holds its frame rate. The profile (`tools/dev/profile_view.gd`, camera on the market at play zoom 0.6) ran ~82 fps there, against 102–113 at the town's edge, and ~64 fps zoomed out to 0.5.

**Where the centre's frame went:**

| What | Cost |
|---|---|
| The crowd's update (220 citizens, 100 soldiers) | ~3.6 ms |
| Buildings in view processing every frame | ~2.9 ms |
| Barrels, crates, tables and other goods | ~270 draw calls, ~1.5 ms |
| Drawing the people | ~170 draw calls, ~1.3 ms |
| Flowers, bushes, garden beds and rocks | ~100 draw calls |

**Chosen with the user:** tasks 1–3 below. Baking barrels and crates into the floor (people would be drawn over them) was declined.

**Tag first:** `kak-perf2-start`.

## Global constraints

- **Gates after every task:**
  - `bash tools/test.sh` passes;
  - the digest is unchanged (`61267b7e90524d800bf1c3473a71146b`);
  - FLOW 24/24.
- **crowd_check:** unchanged by Tasks 1 and 3; Task 2 changes it on purpose (baseline −245538477 before).
- **No visible change** beyond what each task names.
- **Measure** each task with `profile_view.gd` at the market (the category it targets, before and after).
- Commits end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never commit `captures/` or `default_bus_layout.tres`.

---

### Task 1: Idle buildings stop processing while in view

**Files:** `src/environment/structure.gd`, `src/environment/environment_field.gd`, a test.

- **Idle.** A structure in view goes *idle* when:
  - it is quiet (`_quiet()`), with nothing dirty or animating;
  - it has no stepped part: no banner, spin or flame;
  - it is not a torch, a tower or a block (their light signature steps with time).

  Idle means asleep, as off-screen sleepers are, but still in view.
- **The ticker.** EnvironmentField keeps the idle list and visits it round-robin, so each idle structure is looked at `Structure.LIGHT_HZ` times a second.
  - If its light signature changed, it redraws.
  - If it has left the view, it becomes an ordinary off-screen sleeper.
- **Waking.** Anything that happens to an idle structure wakes it, as now: a hit, a crack, a shake, a fire, a destroy.
  - The view-entry wake loop skips idle structures.
- **Test.** A quiet house in view goes idle after a frame. A light placed on it redraws it within 1/LIGHT_HZ. A hit wakes it.

### Task 2: Calm people update at half rate on screen

**Files:** `src/game/crowd/person.gd`, `tests/test_person.gd`.

- **Who.** On screen, a person steps every other frame (by stagger) with the time skipped when all of these hold:
  - their mind is CALM (a citizen) or POST (a soldier at his post);
  - they are wandering, not frozen, stumbling, or held at a gate.
- **Everyone else** steps every frame: the frightened, the fleeing, anyone knocked or pulled.
- **Test.** A calm person on screen moves every other frame, the same distance over two frames. A panicking one moves every frame.
- **Measure.** Record the new crowd_check baseline, and the crowd test's escapes.

### Task 3: Fewer decor nodes, same look

**Files:** `src/game/town/town_decor.gd`, `src/environment/decor.gd`, `src/environment/art/decor_art.gd`, `src/game/town/town_floor.gd`, the tests.

- **Low decor into the floor.** Flowers, bushes, garden beds and rocks inside the walls are painted into the floor.
  - A piece qualifies unless a building behind it (one that sorts before it) overlaps its drawn box. That building would draw over a floor-painted piece.
  - It keeps the colour it had as a live piece: the decor's light, not the ground's deeper gold.
  - **Side effect:** a blast no longer chars these pieces or knocks them flat.
- **Goods into piles.** Barrels, crates, tables, benches and log stacks inside the walls, within 0.6 of each other, become one `PILE` node of up to four parts.
  - Each part keeps its own colour tuning.
  - The pile sorts by its front part.
  - Parts are only merged when no building sorts between them.
- **Test.**
  - Every low piece inside the walls is either baked or overlapped by a building behind it.
  - Every pile's parts are within reach, and no building sorts between them.
  - The number of live decor nodes falls.

### Task 4: Wrap-up

1. Profile the market again and bench against `kak-density` in the same hour.
2. Append "Changes made while executing".
3. Tag `kak-perf2`, then push.

---

## Changes made while executing

- **The machine was busy.** Diablo IV ran through the whole pass (CPU at 99–100%, 1.2 GB of memory free). Timings from that time are depressed and noisy.
  - Progress was measured with numbers load cannot move: how many structures process, how many people update, and the draw calls.
  - The final bench compares against `kak-density` in alternating runs.
  - The test suite took over 120 s under the load and hit `tools/test.sh`'s timeout. It was run directly, with a longer timeout.
- **Task 1** also moved every permanent glow (a torch's pool, a wall flame's halo, a street lamp's) onto the shader's own clock: `QuadFx.run_on_shader_clock()`, with `light_glow.gdshader` using TIME offset by position.
  - Each glow had processed every frame only to feed its flicker.
  - The flicker no longer pauses during hitstop.
- **Task 1 result:** at the market, 228 of the 290 structures in view are idle. The 62 still processing are torches, towers, the keep, the mills and the fountain.
- **Task 2:** `crowd_check` −245538477 → −772255736.
  - Crowd test: 146 alive, 15 escaped (from 140 and 17).
  - All 249 people on screen at the market are unhurried until the first blow.
- **Task 3:**
  - **Structures:** a building's cover test uses its outline on screen (`_silhouette()`), not its bounding box. The box's empty corners blocked most pieces.
  - **Trees:** a trunk-and-crown shape.
  - **Other decor:** tight per-kind boxes (`DRAW_BOX`).
  - **Low pieces never keep each other live.** At ground level their order moves a pixel or two. Without this rule only 46 pieces qualified.
  - **Piles** grow by chain (within 0.6 of any piece already in them), up to 6.
  - **Totals:** 80 low pieces baked and 121 goods in 58 piles; live decor 1019 → 876.
  - **Build time:** `TownDecor.spots()` works out the layout's buildings once instead of four times, so the town builds no slower.
  - Captures before and after differ in 0.06–0.14% of pixels, all lamp flicker.

### Results

- **Draw calls at the market:** 1175 → 1056. Decor 516 → 411, of which low pieces 106 → 51 and goods 269 → 236.
- **Mission bench**, three alternating runs against `kak-density` under the same load:

  | | `kak-density` | Now |
  |---|---|---|
  | fps (the three runs) | 32.2, 32.2, 35.0 | 37.8, 42.7, 46.4 |
  | Frame time (average) | 30.2 ms | 23.8 ms |
  | Worst-frame fps | ~22 | ~29 |
  | Draw calls | 1201 | 1084 |

  That is about 21% less frame time. Unloaded, the market's ~82 fps should rise in proportion.
- **Tests:** 763 checks. The digest and FLOW are unchanged.
