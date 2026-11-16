# Death powers second review: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every reviewed Death power cover the area its ring shows and read at a glance: fights between the living
and the undead that look like fights; a Raise that lifts every body in a real ring; a Gate Below whose rift and hands
fill its reach and whose wraiths scatter and wither; Pale Reign ghosts with their own sprite that run the whole reign; a
Pale Serpent with a death wave ahead of it; and a city-wide Grave Tide at least the equal of Heaven's Door.

**Architecture:**
- Four PixelLab sheets come first (Task 1): the grasping hand (Gate Below), and three new `Animal.Breed`s appended after
  `WRAITH`: `PALE_GHOST` (17), `SKELETON` (18), `GHOUL` (19), drawn through the existing `Animal.SHEETS` path.
- Everything shared lives crowd-side and is power-blind: new `Visitors` traits (`sector`, `wither`, `touches_most`,
  `prefer`, `spare`), a crowd-owned **withering** status (`Withering`, `Crowd.wither()`, kill kind `&"wither"`), the
  **cornered / fight-back** rule inside `Visitors` with a `Crowd.cornered()` query, a draw-only recoil on `Animal`, and
  one rule for **mission buildings** (`MissionKeeps.spared()` + virtual `MissionDirector.needs_standing()`).
- Each power's own change stays in its `src/fx/death/*.gd` file and its suite, so Tasks 4-7 and 9 can run in separate
  worktrees once Tasks 1-3 (and 8 for Task 9) are on the branch.

**Tech Stack:** Godot 4.7.2 GDScript; PixelLab MCP tools (`mcp__pixellab__*`); Python 3 + PIL for packing.

**Spec:** `docs/superpowers/specs/2026-11-16-kak-death-second-review-design.md` (binding). It amends
`docs/superpowers/specs/2026-11-13-kak-death-review-adjustments-design.md` and rulings R1-R27 in
`docs/KAK_God_Death_Review_Rulings.md`; where they disagree the second review wins. Read both. The rulings below are this
plan's picks for what the spec left to the builder.

**Worktree and branch:** `C:/BURIN_NITRO/Godot/GIT/vfxProve-death`, branch `god/death-review-2` (cut from
`origin/feat/god-progression` 8e975fb6). Lands on `feat/god-progression`, never Develop-Main.

## Global Constraints

- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- One suite: `timeout 1500 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd -- --only=test_x`.
  Always grep its output for `SCRIPT ERROR|Parse Error` (a parse error hangs `run_part`).
- New `class_name` (`Withering`, `MissionKeeps`) or new imported asset: `$G --headless --editor --path . --import`
  **twice**, then `git checkout -- default_bus_layout.tres`.
- crowd_check: `timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/crowd_check.gd`
  (`--fixed-fps` is an engine arg, before `-s`; R23). Expected: `checksum=-535548941`. crowd_check casts no undead:
  if any task moves it, that is a bug in that task.
- Frame rate (spec anti-goal): on a quiet machine, the `--bench-cast` median `avg_ms` delta is at most **8 ms** for
  `gravetide` (the Tier 5 cataclysm only) and at most **5 ms** for `gatebelow`, `pale` and `serpent`.
- No luck: everything picks by rule (nearest, oldest, instance-id order, index order). Never `rng` for a target or a spot.
- No hidden losses: a mission lost to a power's side effect shows why; Grave Tide never damages a building a mission
  needs standing (R45).
- Silent powers stay silent (`guise`, `walker`): no alarm, no fright. Walking Corpse's pack is never stepped, so the
  fight change never reaches it.
- Palette: bone white, ash grey, pale-white fire; grave green only for eyes and glows. No blood, no gore.
- `Animal.Breed` is append-only (indices are saved): `PALE_GHOST` 17, `SKELETON` 18, `GHOUL` 19, in that order.
- A raised body stays dead: undead are Visitors, never a revived Person. Powers are reusable effects: no power logic in
  `Person`; `Person` only carries generic statuses and draws them (as `guised()` does).
- No change to `GodTree.TABLE`, costs (`dp`), cooldowns or levels. No new powers.
- `tools/dev/**` must stay parseable at every commit (tests preload the route scripts).
- PixelLab: about **150 generations** in all (Task 1). State the spend before spending; stop and report at the cap.
- Every task ends green on its own suites plus the listed neighbours. Commit messages end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. On any merge conflict: stop and tell the user.

## Rulings (the spec's "left to the builder")

Task 0 appends these to `docs/KAK_God_Death_Review_Rulings.md` (after R27, under a heading for this review). Task 10
reconciles any number a later task had to move, with the reason.

| # | Power | Ruling |
|---|---|---|
| R28 | Raise | Ring `RaiseTheDeadFx.RING_R 3.0`; at most `MOST 8` bodies a cast, the oldest first (`Remains.ring()`: born ascending, a tie in ledger order). ZOMBIE: each rises as a zombie. SPIRIT: each with its soul rises as a spirit; each spirit drifts after its own nearest group (R16's `FRIGHT_R 4.0` each). The cast needs a body (or, SPIRIT, a soul) within `RING_R` (PowerBook `"pick_r": 3.0`, read by `Rules.body_check`). Aim: every remain in the ring is marked; the ones that will rise carry the skull (`lead`), the rest (past the cap, or soul-less in SPIRIT) are `COL_BAD`. `Targeting.AREAS["raise"].r` = `RING_R`. Walking Corpse's marks (R1) are unchanged. |
| R29 | Raise | `CHAIN 3` counts the whole cast: its zombies' kills raise `CHAIN - 1` = 2 more in all, shared by every zombie of the cast, however many rose from the ring. One body behaves exactly as before. |
| R30 | Fight | **Cornered** (crowd-side, any power): a citizen (not a soldier), alive, out in the open and not down, is cornered while one `Animal.UNDEAD` visitor whose `target` is him has stayed within `Visitors.CORNER_R 1.0` of him for `CORNER_HOLD 0.5` s without a break (each pack's own timer); it lapses the step that stops. `Crowd.cornered(p)` asks every pack. A cornered citizen strikes the nearest undead visitor within `GUARD_REACH 0.6` every `CITIZEN_SWING 1.2` s (the first after one swing's wait), `CITIZEN_BLOW 0.5` a blow: a zombie falls to 6, a ghoul to 4, a skeleton warrior to 8. Only `Animal.SOLID_UNDEAD` (`ZOMBIE`, `SKELETON`, `GHOUL`) take the blow; at a spirit, wraith, pale ghost or the giant he swings and lands nothing. No brain change: he keeps his own flight; the blow only lands while the undead is in reach. |
| R31 | Fight | Every `Visitors._guard` blow on an `Animal.UNDEAD` visitor calls `soldier.swing_at(a.ground_pos)`; a citizen's blow (or swing at air) does the same. Every blow on an undead plays its flinch: `Animal.hurt()`'s 0.1 s flash and the R32 recoil. Only a soldier's blow resets a flinching visitor's bite (as today); a citizen's never does (else a citizen at 1.2 s would hold a zombie off for ever). Hellhounds, demons and Passage's ghosts are untouched. |
| R32 | Fight | Recoil, draw-only: `Animal.struck_from(from: Vector2)` pushes the drawing `RECOIL_PX 3.0` screen px away from the blow, easing to 0 over `RECOIL_FOR 0.12` s. `ground_pos`, speed and every rule are untouched, so no reference moves for it. |
| R33 | Gate Below | The rift fills the reach: `EDGE` 1.8 → **4.2** (the lip's mean; jagged ±20%, so 3.36-5.04, inside `REACH 6`); `PIT_R` 3.0 → `REACH` (cracks and bone out to 6); `RIFT_POINTS` 18 → 28, `CRACKS` 9 → 16, `BONES` 22 → 40, the jag 0.25 → 0.20. Drags end at the new `EDGE` (one already inside it is held where he stands and goes under there after `DRAG`). `REACH`, `SPAN`, `GRAB_EVERY`, `DRAG`, the grab rule and `FRIGHT_R` are unchanged. |
| R34 | Gate Below | Hands: sheet `assets/pixellab/fx/grave_hand/grave_hand.png` + `grave_hand.json` = `{"cell": [64, 64], "frames": 6, "foot": [32, 62]}` (frames 0-1 rising, 2-3 clawing, 4-5 closing and pulling down), drawn **1:1** (`ARM_SCALE 1.0`): the hand and forearm about 48 px tall, the hand about 20 px across. `ARMS` 24 → **36** ambient hands on the golden spiral from `ARM_IN 0.6` out to `REACH` (over the rift too), walkable ground only (R19). `ARM_SIDE` 6 → 10 px. `grave_arms.png/.json/.import` are deleted once nothing loads them. |
| R35 | Gate Below | Wraith scatter: with `n` souls, wraith `k` owns sector `k`: centre the pit, from angle `0.4 + TAU * (k - 0.5) / n`, width `TAU / n` (n = 1: the whole circle). It climbs out at `origin + dir_k * WRAITH_SPREAD`, flies out along `dir_k` to `origin + dir_k * (REACH + 2.0)` (`march`, through walls, `WRAITH_OUT 3.0` s at most), then hunts the nearest living person, citizen or soldier, out in the open, within `WRAITH_SEEK 12` of it **whose bearing from the pit lies in its sector** (`Visitors` trait `sector`). |
| R36 | Kit | Withering (`Withering`, owned by `Crowd`, stepped in `Crowd._advance` after `remains.step`): `Crowd.wither(p, seconds, from)` lays it for `WITHER 6.0` s: the person is drawn grey (`Person.withered()`, `Withering.TINT`), keeps `WITHER_PACE 0.5` of his pace (`hold_pace` under the Withering's id) and panics from `from` (`Person.panic(from, 2.0, &"wither")`). At the end, alive and out in the open, he dies where he stands as **`&"wither"`**: a new kind, in `Remains.BODY_KINDS` (a body, ready to rise), **not** in `DeathVoices.QUIET_KINDS` (a cry and the alarm, as any seen death), `Rules.POWER_KINDS["gatebelow"] = [&"pit", &"wither"]`. Indoors at the end, dead of something else, or freed: it lapses, every hold freed (Death Mark's rule). Laid on one already withering: nothing (the first runs on). |
| R37 | Gate Below | A wraith's touch withers (it replaces R9's touch kill on soldiers): `Visitors` trait `wither 6.0`; `WRAITH_TOUCHES 3`, then it sinks (spent, `touches_most`). A withering person is never its prey again. `WRAITH_SLOW` on those it passes, `WRAITH_LIFE 20`, `WRAITH_SPEED`, `WRAITH_TOUCH 0.5` kept. |
| R38 | Pale Reign | Pale ghost sprite: breed `PALE_GHOST`, sheet `assets/pixellab/animals/pale_ghost.png` (+ `.json`, the `make_animal_sheet.py` format: still, walk_se, walk_ne, bite rows), canvas 48, a gaunt faceless runner with a trailing shroud about 28 px tall, on the ground (no hover: not the wraith), no hood (not Passage's GHOST). Drawn 1:1, multiplied by `worn_tint` = `PALE_GHOST_TINT`. With no sheet on disk it falls back to the wraith draw (tests need no art). |
| R39 | Pale Reign | The horde lasts the reign: no sink at `HORDE_KILLS` (R20's sink-at-24 is withdrawn). At the `HORDE_KILLS`-th kill every ghost up is given `touch_kill &""`, `no_bite true`, `fright_r PALE_GHOST_FRIGHT_R 2.0`: they hunt on inside the district, frighten, and kill no more; no ghost is made past it. All sink at `SPAN` (`FADE`). `HORDE_CAP 24` holds. |
| R40 | Serpent | Death wave ahead (staged parts code-drawn): **fog** at the point `FOG_LEAD 1.0` s ahead of the head along its path, `FOG_EVERY 0.1` s, 2 puffs spread ±`BAND` across, life 1.6 s, at most 40 live; **frost** patches of radius `BAND` at the point `FROST_LEAD 1.5` s ahead every `FROST_EVERY 0.25` s, fading over `FROST_LIFE 6.0` s, at most 48, on `ctx.ground`; **dim**: `TownPools.dim(id, ahead_at(t, DIM_LEAD 1.0), DIM_R 6.0, DIM 0.75)` every frame while it glides and loops, `TownPools.undim(id)` at the end, `_finish` and `_exit_tree` (a pool keeps `1 - DIM * (1 - d / DIM_R)` of its strength); **fright cone**: every `CONE_EVERY 0.5` s from `T_RISE` to the loop's end, everyone out in the open, not guised, not a decoy, within `CONE_R 8.0` of the head and within `CONE_HALF 30°` of its heading panics from the head (`Person.panic(head, CONE_R, &"beast")`). The fright behind (`FRIGHT_BACK`), the kill lane, the loop and the soul aura are kept. |
| R41 | Grave Tide | Grave spots, pure `GraveTideFx.grave_spots(grid, districts) -> Array[Vector2]`: candidates are every district's centre (in `City.current().districts()` order), then every district's points at (0.25, 0.25) and (0.75, 0.75) of its rect; each snapped with `grid.nearest_walkable(p, 6)` (INF skipped) and kept only `GRAVE_GAP 2.5` from every spot kept before; past `GRAVES_MOST 24`, keep index `floor(i * n / 24)` for `i` in 0..23. Grave `i` bursts at `T_RISE + i * BURST_STEP 0.08` (soil, bone chips, dust, a dark pit mark, staged only) and raises one skeleton warrior and one ghoul. |
| R42 | Grave Tide | Kinds (factories in `DeathParts`; paces in walks, as the zombie's): **SKELETON** blows 4, pace 1.3, chase 1.25, seek 12, reach 0.6, every 1.0, bite 1.0 (a citizen falls to one, a soldier to two), no flinch, `prefer "soldiers"` (the nearest soldier within seek, else the nearest anyone); **GHOUL** blows 2, pace 2.0, chase 1.2, seek 12, reach 0.8 (the leap), every 0.9, `knock_first`, flinch; **ZOMBIE** (the town's bodies) as `DeathParts.zombie()`. All `spare_guise`. In the tide each also claws (`wreck_idle` true, `spare` = R45): skeleton 6 every 1.5 s, ghoul 3 every 1.0 s, zombie 3 every 1.5 s. Nobody marches to the click: each hunts from where it rose. `LIFE 40` kept. Art: `assets/pixellab/animals/skeleton.png` and `ghoul.png` (+ `.json`), canvas 48, the animal format; the skeleton a person-sized armed skeleton (rusted sword, broken round shield), the ghoul low and long (about 16 px tall), its bite row a leap. |
| R43 | Grave Tide | The giant always comes: it assembles at the grave nearest the click (a tie to the lower index; R12's assembly, its `BONES` flying up out of that grave), stands at `T_RISE + ASSEMBLE`, and lands with the first slam. Its path: by the streets to the nearest grave it has not visited (`march`, `GIANT_LEG 25.0` s at most), then the next; all visited, the tour starts again; a soldier within `GIANT_SEEK` it hunts (prey soldiers, as now). Each slam (R12) also gives every wreckable building within `SLAM_R` not spared by R45 `SLAM_WRECK 60` (`&"frenzy"`; a house's 50 hp falls to one slam), counted in `slam_wrecks`. `CLUSTER_R`, `CLUSTER_MIN`, `cluster()`, the march to the click and the soldier-anywhere search go. |
| R44 | Grave Tide | At most `LIVING_CAP 60` living undead in the tide's pack, the giant not counted: graves rise first in order (a grave whose two would pass the cap raises none), then the town's bodies (`Remains.all()`, oldest first, `MOST 30` at most) as zombies up to the cap. Always castable: `"needs": "any_body"` leaves its PowerBook row; Rules' `any_body` branch goes if nothing else uses it. |
| R45 | Kit | Mission buildings, one rule: `MissionKeeps.spared(s, crowd, director) -> bool` is true for role `&"citadel"` or `&"temple"`, a structure whose `Crowd.structure_mark()` is `&"hallowed"`, one with a `damage_filter` (the Citadel's budget, a director's stone or refuge), one in `director.reserved_places`, or `director.needs_standing(s)`. `MissionDirector.needs_standing(s) -> bool` (virtual, false) is overridden by every director that keeps goal buildings in its own members (Task 8's list), Raze's targets (Spoiled Harvest's granaries) among them. A null director: the generic rules only. Grave Tide's horde (`Visitors` trait `spare`) and slams obey it. |
| R46 | Bar | Measured with the bench aid `--bench-tally=SECONDS` (headless, `--fixed-fps 60`, seed 1, Aldermere, 220 people): deaths (`killed_citizens + killed_soldiers` since the cast) and buildings destroyed (`structure_destroyed` since the cast). Grave Tide: cast at the market with no bodies in town, tallied 70 s. Heaven's Door: level 1, cast at the market with no drag (it faces down-right, as the bench aims it), tallied 30 s. Met when Grave Tide's count is at least Heaven's Door's on each measure. Short of it: stronger units (skeleton bite and blows, `SLAM_WRECK`, the claws), never more units, then measure again; the caps and the 8 ms win, and the gap is recorded. Numbers go in the rulings doc ("Bar") and the Task 11 commit body. |
| R47 | Bench | R13's rule (the median `avg_ms` delta of 3 alternating pairs on a quiet machine), with the ceilings in the Global Constraints. Headless perf checks: `test_gravetide` (24 graves' horde at the cap: 60 undead, the giant, slams) `PERF_MS 8.0`; `test_pale` stays 5.0. |
| R48 | Checks | crowd_check stays `-535548941` after Tasks 2, 3, 7, 8, 9 and 13. Rows that must not move (they cast no changed power; the haunt wraiths never target): every `god_t1_warning`/`god_t1_tax` Death row, and `silence_witness_death_*`, `expel_inquisitor_death_*`, `break_hunt_death_*`, `face_halcyon_death_*`. |

## Review Focus

1. **A withering cut short:** the person goes indoors, dies of something else, or is carried off and freed (Heaven's
   Door) before `WITHER` is up: no kill, no crash, the pace hold freed, the status gone. Test in Task 2.
2. **A cornered citizen knocked down, or his undead freed mid-swing** (cut down by a soldier the same step, recalled,
   carried off): no blow from a down person, no blow on a freed node, no crash. Test in Task 3.
3. **The Serpent cut short** (`_finish` early, or freed by a restart, `_exit_tree`): no town light is left dimmed and
   no frost or fog node outlives it. Test in Task 7.
4. **The spared-building rule with no director** (the sandbox), and a hallowed mark that runs out mid-tide: the rule
   reads live; a building is spared while the mark holds and wreckable after. Test in Task 8.
5. **Grave Tide in a town whose districts do not fit the rule** (a district wholly built over, so its snap fails; or a
   plan with more than 24 districts, the Capital): spots skip the unsnappable, stay walkable, at most 24, spread by
   index, and the same call gives the same spots. Test in Task 9.

---

### Task 0: Baseline and rulings

**Files:** Modify `docs/KAK_God_Death_Review_Rulings.md`.

- [ ] **Step 1:** Import twice, restore `default_bus_layout.tres`, run crowd_check. Expected: `checksum=-535548941`.
- [ ] **Step 2:** `bash tools/dev/refs_check.sh --only='death' --jobs=3`; save the output to the scratchpad as
  `refs_base.txt`. Expected: `ok=33 bad=0` (a row already failing is pre-existing: note it in the doc).
- [ ] **Step 3:** Append a section "Second review (2026-11-16)" naming the spec and this plan, then R28-R48 verbatim.
- [ ] **Step 4:** Commit: `docs: Death second review rulings (R28-R48)`.

### Task 1: Art (PixelLab), FIRST

**Files:**
- Create: `assets/pixellab/fx/grave_hand/grave_hand.png` + `.json` + `.import`;
  `assets/pixellab/animals/{pale_ghost,skeleton,ghoul}.png` + `.png.json` + `.png.import`.
- Keep every source frame, the packing script and `prompts.txt` (USED / REJECTED, as
  `tools/dev/pixellab_src/death_review/prompts.txt`) in `tools/dev/pixellab_src/death_review_2/`.

**Interfaces (produced):** the four files above in the formats of R34, R38 and R42. The animal sheets come out of
`python tools/dev/make_animal_sheet.py --src <dir> --out assets/pixellab/animals/<name>.png` (rows: still SE/NE,
walk SE, walk NE, bite SE; other rows empty), as the bone giant's did (commit 5c2fa9a8).

- [ ] **Step 1:** `mcp__pixellab__get_balance`. Plan the spend: hand ~20, pale ghost ~35, skeleton ~40, ghoul ~40,
  re-rolls ~15 (cap 150).
- [ ] **Step 2: Hand** (the wraith's pipeline: generate + `animate_image`, not `create_character`).
  `create_image_pixflux` 64x64, no background, low top-down: *"a gaunt pale grey-white hand and forearm rising out of
  cracked dark earth, long bony fingers clawed upward, torn grave-cloth at the wrist, dark medieval pixel art, no blood"*.
  `animate_image` 6 frames: *"rises up out of the ground, the fingers claw at the air, then close into a fist and pull
  down into the earth"*. Pack 6 x 1 cells of 64x64 with a `pack_hand.py` modelled on `pack_wraith.py` (one offset per
  row, the lowest opaque row on foot y 62, frame 0's bbox centre on x 32).
- [ ] **Step 3: Pale ghost, skeleton warrior, ghoul** (character mode suits these humanoid shapes). Per figure:
  `create_character` (canvas 48, 8 directions), then `animate_character` for `walk` (a run for the ghost and the ghoul)
  and `bite` (ghost: a reaching grab; skeleton: a sword cut; ghoul: a leap forward), `wait_for_jobs`, download to
  `tools/dev/pixellab_src/death_review_2/<name>/` laid out as `rot_<dir>.png` and `<anim>/<dir>_<i>.png`, pack with
  `make_animal_sheet.py`. Prompts:
  - pale ghost: *"gaunt faceless pale figure, ash-white skin, tattered grey shroud trailing behind it, long thin arms,
    no hood, no legs visible under the shroud hem, dark medieval pixel art, no blood"*;
  - skeleton: *"skeleton warrior, bone white, rusted short sword, broken round wooden shield, scraps of mail, pale green
    eye glow, dark medieval pixel art, no blood"*;
  - ghoul: *"crouching ghoul, grey-green mottled skin, long arms, low on all fours, hollow eyes, ragged loincloth, dark
    medieval pixel art, no blood"*.
- [ ] **Step 4: Look.** Read each PNG. Re-roll gore, a cute or round face, a pale ghost that reads as the wraith or
  Passage's GHOST (`assets/pixellab/animals/ghost.png`), a hand that reads as a pole, broken frames. Each must read at
  1:1 beside a ~20 px person.
- [ ] **Step 5:** Import twice, restore `default_bus_layout.tres`. Commit the sheets, jsons, imports and sources:
  `art: grasping hands, pale ghosts, skeleton warriors and ghouls (PixelLab) for Death's second review`.

### Task 2: Undead kit (breeds, traits, withering)

**Files:**
- Modify: `src/game/crowd/animal.gd`, `src/game/crowd/visitors.gd`, `src/fx/death/death_parts.gd`,
  `src/game/crowd/remains.gd` (`BODY_KINDS`), `src/game/crowd/crowd.gd` (own and step the withering, `wither()`,
  clear it with `_struct_marks`), `src/game/crowd/person.gd` (`withered()` and its grey only), `src/game/rules.gd`
  (`POWER_KINDS["gatebelow"]` only).
- Create: `src/game/crowd/withering.gd`.
- Test: `tests/test_death_kit.gd`; update `tests/test_remains.gd` if it pins `BODY_KINDS` exactly.

**Interfaces (produced):**
- `Animal.Breed` gains `PALE_GHOST, SKELETON, GHOUL` (17, 18, 19). `UNDEAD` gains all three;
  `const SOLID_UNDEAD: Array[Breed] = [Breed.ZOMBIE, Breed.SKELETON, Breed.GHOUL]`. `PALETTE`, the shadow rect and the
  "freed at once" dead list cover them; `SHEETS` maps them to their Task 1 sheets. `PALE_GHOST` draws its sheet times
  `worn_tint`; with no sheet, `_draw_wraith`.
- `class_name Withering extends RefCounted`: `const WITHER := 6.0`, `WITHER_PACE := 0.5`, `TINT := Color(0.62, 0.64,
  0.66)`, `KIND := &"wither"`; `func lay(p: Person, seconds: float, from: Vector2) -> bool`; `func step(delta: float)
  -> void`; `func clear() -> void`; `func count() -> int`. `p.statuses[&"wither"]` holds the seconds left.
- `Crowd.withering: Withering`; `func wither(p: Person, seconds: float, from: Vector2) -> bool`.
- `Person.withered() -> bool` (`statuses.has(&"wither")`); drawn with `Withering.TINT` the way `guised()` draws
  `ZOMBIE_TINT`, and folded into the same draw signatures.
- `Visitors.give()` traits (all default off):
  - `"sector": Vector4(cx, cy, from_angle, width)`: `_within` also asks that the bearing of `p` from `(cx, cy)` lies in
    `[from, from + width)` (mod TAU); width ≤ 0 or ≥ TAU: anywhere;
  - `"wither": float`: reaching the prey lays `_crowd.wither(who, wither, a.ground_pos)` instead of a bite or kill,
    emits `bitten`; `_fair` skips `p.withered()` for such a rule;
  - `"touches_most": int`: after that many touches (wither or touch kill) the visitor is freed, deferred;
  - `"prefer": "soldiers"`: `_nearest` takes the nearest soldier within reach, else the nearest anyone;
  - `"spare": Callable` (`func(s: Structure) -> bool`): a spared structure is never this visitor's to wreck
    (`_wreckable` becomes per rule).
- `DeathParts`:
  - `wraith(v: Visitors, at: Vector2, sector: Vector4, out_to: Vector2) -> Animal` (R35, R37): breed WRAITH, phase,
    `spare_guise`, prey anyone, seek `WRAITH_SEEK`, `wither Withering.WITHER`, `touches_most WRAITH_TOUCHES`, the slow
    traits, `fright_r SPIRIT_FRIGHT_R`, `sector`, `march out_to`, `march_for WRAITH_OUT`. New consts `WRAITH_TOUCHES := 3`,
    `WRAITH_OUT := 3.0`. `touch_kill`/`spent_on_kill` remain as traits (no Death power uses them for the wraith now).
  - `pale_ghost()` summons `PALE_GHOST`; new const `PALE_GHOST_FRIGHT_R := 2.0`.
  - `skeleton(v: Visitors, at: Vector2) -> Animal` and `ghoul(v: Visitors, at: Vector2) -> Animal` with R42's numbers
    as consts (`SKELETON_BLOWS 4`, `SKELETON_PACE 1.3`, `SKELETON_CHASE 1.25`, `SKELETON_SEEK 12.0`,
    `SKELETON_REACH 0.6`, `SKELETON_EVERY 1.0`; `GHOUL_BLOWS 2`, `GHOUL_PACE 2.0`, `GHOUL_CHASE 1.2`, `GHOUL_SEEK 12.0`,
    `GHOUL_REACH 0.8`, `GHOUL_EVERY 0.9`). The wreck traits are the caller's.
- R36: `&"wither"` in `Remains.BODY_KINDS`; `Rules.POWER_KINDS["gatebelow"] = [&"pit", &"wither"]`.

- [ ] **Step 1: Write the failing tests** in `tests/test_death_kit.gd`:
  - `"three breeds appended, undead, never in the town pack"`: `Breed.PALE_GHOST == 17 and SKELETON == 18 and GHOUL ==
    19`; each in `UNDEAD`; `SOLID_UNDEAD == [ZOMBIE, SKELETON, GHOUL]`; no town-pack animal has them.
  - `"withering: grey, slowed, panicked, dead at 6 s as wither, a body"`: `crowd.wither(c, 6.0, c.ground_pos +
    Vector2(1, 0))` is true; at once `c.withered()`, `c.walk_speed` ≤ half its own, `c.mind` PANIC or FLEE (or
    startled); at 5.9 s alive; at 6.1 s dead, captured kind `&"wither"`, `remains.pick(pos) != null`, `crowd.alarm`
    raised.
  - `"withering lapses indoors, on another death, or freed"` (Review Focus 1): three citizens: one `inside = true` at
    3 s (alive at 6.1 s, status and pace hold gone), one killed `&"frenzy"` at 2 s (one kill only, the frenzy), one
    `free()`d at 2 s (no error; `crowd.withering.count() == 0` at 6.1 s).
  - `"a second withering on the withering runs nothing new"`: second `wither()` is false; death at the first's 6 s.
  - `"a wraith withers whoever it reaches, three, then sinks"`: one wraith (`sector` the whole circle, `out_to` its own
    spot, so no march), four citizens 1.5 apart on its line. After 15 s: three `withered()` or dead `&"wither"`, the fourth untouched, `v.living().is_empty()`.
  - `"a sector keeps a wraith to its own"`: sector `(C, 0, PI/2)`; a citizen at C+(0,-2) (bearing −90°, outside) 1.0
    from the wraith, one at C+(3,0.5) (inside) 3.0 from it: after 1 s its `target` is the inside one.
  - `"prefer soldiers: a skeleton passes a nearer citizen"`: citizen at 1.0, soldier at 4.0: `target` is the soldier;
    with no soldier in seek, the citizen.
  - `"spare: a spared building is never clawed"`: a wrecker beside two houses, `spare` true for one: after 10 s its hp
    is full, the other's is not.
  - `"skeleton and ghoul stats"`: `skeleton()` breed SKELETON, `health == 4.0`, `_rules[a].flinch == false`, bite 1.0;
    `ghoul()` health 2.0, `knock_first`; speeds `0.78` / `1.2` u/s with no prey (`is_equal_approx`).
  - `"the wither kind"`: `Remains.BODY_KINDS.has(&"wither")`, `not DeathVoices.QUIET_KINDS.has(&"wither")`,
    `Rules.POWER_KINDS["gatebelow"] == [&"pit", &"wither"]`.
  - Update the existing wraith checks (`test_death_kit.gd:148-258`) to the new `wraith()` signature and to withering
    in place of the pit kill.
- [ ] **Step 2:** Import twice, restore `default_bus_layout.tres`; run `--only=test_death_kit`. Expected: FAIL.
- [ ] **Step 3:** Implement the interfaces.
- [ ] **Step 4:** Run `test_death_kit`, `test_remains`, `test_death_voices`, `test_animals`, `test_deaddoors`,
  `test_houndgate`, `test_raise_dead`, `test_gravecall`, `test_pale`, `test_gravetide`. Expected: 0 failures, except
  `test_gatebelow` (Task 5 owns the wraith's new call; note, do not patch). Run crowd_check. Expected:
  `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: Death's kit -- pale ghosts, skeleton warriors, ghouls, the withering, scattering wraiths`.

### Task 3: Fights look like fights

**Files:** Modify `src/game/crowd/visitors.gd`, `src/game/crowd/animal.gd` (recoil), `src/game/crowd/crowd.gd`
(`cornered()` only). Test: create `tests/test_fight_back.gd`, register it in `tests/run_all.gd` beside
`test_death_kit.gd`.

**Interfaces:**
- Consumes: `Animal.SOLID_UNDEAD`, `skeleton()`, `ghoul()` (Task 2); `Person.swing_at()` (existing).
- Produces:
  - `Visitors`: `const CORNER_R := 1.0`, `CORNER_HOLD := 0.5`, `CITIZEN_SWING := 1.2`, `CITIZEN_BLOW := 0.5`;
    `func corners(p: Person) -> bool`; `_guard()` calls `p.swing_at(a.ground_pos)` and `a.struck_from(p.ground_pos)`
    on every blow on an UNDEAD visitor; a new `_fight_back(delta)` after `_guard()` (R30, R31). A cut-down by a
    citizen's blow counts in `slain` and emits `cut_down`, as a soldier's.
  - `Crowd.cornered(p: Person) -> bool`: any pack in `visitors` `corners(p)`.
  - `Animal`: `const RECOIL_PX := 3.0`, `RECOIL_FOR := 0.12`; `func struck_from(from: Vector2) -> void`;
    `func recoil_offset() -> Vector2` (screen px; every draw path offsets by it); eased down in `tick_visual`.

- [ ] **Step 1: Write the failing tests** (`tests/test_fight_back.gd`, world setup as `test_death_kit.gd`):
  - `"a soldier's blow on a zombie shows his swing"`: soldier 0.4 from a zombie; after `GUARD_SWING + 0.05` the zombie's
    health is 2.0 and `soldier._swing_left > 0`, facing it.
  - `"each blow flinches the undead: a flash and a 2-3 px recoil, and nothing moves"`: right after the blow,
    `recoil_offset().length()` in [2.0, 3.0], pointing away from the soldier on screen; `ground_pos` unchanged by the
    blow; after 0.2 s `recoil_offset() == Vector2.ZERO`.
  (The undead in these checks are given `{"no_bite": true}` unless a check says otherwise, so a bite cannot knock the
  citizen down before he swings.)
  - `"a citizen a zombie holds in reach is cornered and fights back"`: a citizen pinned (`hold_pace(id, 0.0)`), a
    zombie 0.4 off hunting him: `crowd.cornered(c)` true by 0.55 s; within `CORNER_HOLD + CITIZEN_SWING + 0.05` the
    zombie's health is 2.5 and `c._swing_left > 0`.
  - `"a citizen's blow is weaker and never resets the bite"`: over 5 s the zombie takes at most
    `ceil(5 / 1.2) * 0.5`; at each citizen's blow `_rules[z].bite_in` is no higher than the step before.
  - `"one who outruns it is never cornered"`: a citizen fleeing at full pace from a zombie 0.9 off (biting allowed):
    `cornered` false every step for 3 s.
  - `"bare hands do not hurt a pale ghost"`: cornered by a pale ghost (`touch_kill &""`, `no_bite`): he swings, its
    health stays `SPIRIT_BLOWS`.
  - `"a ghoul falls to four bare-hand blows"`: two pinned citizens on one ghoul: it is cut down, `slain == 1`.
  - `"down or freed: no blow"` (Review Focus 2): the cornered citizen `knock_down()` mid-hold: no blow while down; the
    zombie freed between steps: the next step runs without error and lands nothing.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `test_fight_back`, `test_death_kit`, `test_houndgate`, `test_deaddoors`, `test_raise_dead`,
  `test_gravetide`, `test_walker`, `test_gravecall`. Expected: 0 failures. Run crowd_check. Expected:
  `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: fights with the dead look like fights -- soldiers swing, the cornered fight back, the
  struck recoil`.

### Task 4: Raise the Dead (the ring)

**Files:** Modify `src/fx/death/raise_the_dead.gd`, `src/game/crowd/remains.gd` (`ring()`, `pick()`'s radius),
`src/game/rules.gd` (`body_check` radius), `src/game/power_book.gd` (raise `"pick_r"` only), `src/game/targeting.gd`
(`ring_marked()`, the `"raise"` draw case, `AREAS`/`AREA_STATS` raise). Test: `tests/test_raise_dead.gd`,
`tests/test_death_aims.gd`.

**Interfaces (R28, R29):**
- `RaiseTheDeadFx`: `const RING_R := 3.0`, `MOST := 8`; `var spirits: Array[Animal]` replaces `spirit` (each with its
  own drift target and look timer); `raised` counts the ring's and the chain's. `_left = CHAIN - 1` for the cast.
  Keep `_setup()`/`_done()` in the test (Walking Corpse's test uses them).
- `Remains.ring(at: Vector2, r: float, need_soul: bool, most: int) -> Array[Remain]`;
  `Remains.pick(at, need_soul := false, hidden_too := false, r := PICK_R)`.
- `Rules.body_check(needs, ground, hidden_too := false, r := Remains.PICK_R)`; `body_refusal` passes the row's
  `"pick_r"` (default `Remains.PICK_R`).
- `static func Targeting.ring_marked(remains: Remains, at: Vector2, r: float, need_soul: bool, most: int) ->
  Array[Dictionary]` (`{"pos", "lead", "ok"}`; empty for a null or disabled ledger).

- [ ] **Step 1: Tests:**
  - `"every body in the ring rises"`: remains at C, C+(1.5,0), C+(2.8,0) and C+(3.4,0); ZOMBIE cast at C: 3 zombies at
    T_RISE + 0.05, the 3.4 one still in the ledger.
  - `"at most 8, the oldest first"`: 10 bodies within 2.0, born in order: 8 rise; the two youngest stay.
  - `"spirit mode: each soul rises, the soul-less stay"`: 3 with souls and one aged 16 s: `fx.spirits.size() == 3`.
  - `"the chain stays 3 in all"`: 4 zombies rise among a packed crowd; over the life, `raised - 4 <= 2`.
  - `"a body 2.5 off makes the cast valid"`: `rules.body_refusal("raise", "zombie", C) == ""` with the only body at
    C+(2.5,0); at C+(3.2,0): `"no_dead"`.
  - In `test_death_aims.gd`: `"raise marks the whole ring, the risers with the skull"`: 10 bodies within 3.0:
    `ring_marked(...)` has 10 entries, 8 `lead and ok`, 2 `not ok`; SPIRIT, a soul-less one is `not ok`; null ledger:
    empty. Rewrite the 1.0-ring raise check there; leave the walker's.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `test_raise_dead`, `test_death_aims`, `test_walker`, `test_targeting`, `test_remains`,
  `test_power_book`, `test_fight_back`. Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Raise the Dead -- every body in a 3-wide ring rises, eight at most`.

### Task 5: The Gate Below

**Files:** Modify `src/fx/death/the_gate_below.gd`, `tests/test_gatebelow.gd`. Delete
`assets/pixellab/fx/grave_arms.png/.json/.import` after `grep -rn grave_arms src tests tools` shows no other user.

**Interfaces:** Consumes `DeathParts.wraith(v, at, sector, out_to)` and the withering (Task 2), the hand sheet
(Task 1). R33-R35, R37:
- Consts as R33/R34 (`EDGE 4.2`, `PIT_R := REACH`, `RIFT_POINTS 28`, `CRACKS 16`, `BONES 40`, `JAG := 0.20`,
  `ARMS 36`, `ARM_IN 0.6`, `ARM_SCALE 1.0`, `ARM_SIDE 10.0`, `ARM_SHEET`/`ARM_CELL`/`ARM_FOOT` from the hand json).
- `static func sector_of(k: int, n: int, centre: Vector2) -> Vector4` (R35); `_close()` summons wraith `k` with it.
- `var withered := 0`: the wraiths' curses, counted from `visitors.bitten`.

- [ ] **Step 1: Tests:**
  - `"the rift spans the reach"`: every `rift_points(C)` distance within `[EDGE * 0.8, EDGE * 1.2]` and the largest
    ≤ `REACH`; 28 points; every crack's last point beyond `REACH * 0.8` and within `REACH + 0.01`.
  - `"36 hands over the whole ring"`: `arm_spots(C).size() == 36`, min ≤ `ARM_IN + 0.05`, max ≤ `REACH + 0.01`, at
    least 8 beyond `REACH * 0.75`.
  - `"the hand sheet, no pole arms"`: the hand PNG and json exist; `not ResourceLoader.exists(".../grave_arms.png")`.
  - `"one inside the lip goes under where he stands"`: a citizen 2.0 from the middle is grabbed and dies `&"pit"` within
    0.1 of where he stood.
  - `"wraiths scatter, one to a sector"`: four souls taken, then the close: 4 wraiths, each rule's sector width
    `TAU / 4`; at close + 2.0 s their bearings from the pit are pairwise ≥ `TAU / 8` apart.
  - `"a wraith withers a citizen or a soldier, and they die as wither"`: a soldier and a citizen in sector 0 out past
    the reach: both `withered()` within 8 s of the close; dead `&"wither"` 6 s after each touch; `fx.withered >= 2`.
  - Replace R9's `"a wraith that reaches a soldier kills him and is spent"` with the above; the grab, drag, souls and
    loud checks keep passing (move any distance they read to the new `EDGE`).
- [ ] **Steps 2-4:** FAIL, implement, then run `test_gatebelow`, `test_death_kit`, `test_fight_back`,
  `test_awareness`. Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: The Gate Below -- the rift fills its ring, real hands reach out, the wraiths scatter
  and wither`.

### Task 6: Pale Reign

**Files:** Modify `src/fx/death/pale_reign.gd`, `tests/test_pale.gd`.

**Interfaces:** Consumes `PALE_GHOST` and `PALE_GHOST_FRIGHT_R` (Task 2). R38, R39:
- `var spent := false`: the horde has made its `HORDE_KILLS`; `func _spend() -> void` gives every living ghost R39's
  traits. `_on_touch` calls `_spend()` instead of `_sink()`; `_sink()` runs only from `_lift()` (SPAN).

- [ ] **Step 1: Tests:**
  - `"the ghosts are pale ghosts"`: every `fx.horde.living()` has `breed == Animal.Breed.PALE_GHOST`.
  - `"past 24 kills they run on to the end of the reign, frighten, and kill no more"`:
    `horde.kills = HORDE_KILLS - 1`, the next touch lands: `fx.spent`, `not fx._sunk`, the living count unchanged,
    no ghost made after it; a citizen reached by a ghost for 3 s after is alive; one within 2.0 of a ghost goes PANIC
    or FLEE; at `SPAN + FADE + 0.2` the horde is empty.
  - Rewrite "Final review 8" (`test_pale.gd:529-545`): the 24th kill adds no ghost and the horde does **not** sink.
  - `"the horde stops at 24 alive and 24 kills"` keeps passing; perf stays under 5 ms.
- [ ] **Steps 2-4:** FAIL, implement, then run `test_pale`, `test_death_kit`, `test_awareness`, `test_fight_back`.
  Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Pale Reign -- its own pale runners, on the streets the whole reign`.

### Task 7: The Pale Serpent (death wave ahead)

**Files:** Modify `src/fx/death/pale_serpent.gd`, `src/game/town/town_pools.gd` (the dim registry), and
`tests/test_serpent.gd`.

**Interfaces:** R40.
- `TownPools`: `static func dim(source: int, at: Vector2, radius: float, amount: float) -> void`, `static func
  undim(source: int) -> void`, `static func dim_factor(g: Vector2) -> float` (pure over the registry: the product of
  every dim's `1 - amount * (1 - d / radius)` within radius, else 1). `_strength()` multiplies by `dim_factor` at the
  pool's ground point (keep the pool's ground point when pools are built), and `_process` refreshes while any dim is
  registered. The registry is static: nothing but drawing reads it.
- `PaleSerpentFx`: the R40 consts; `func ahead_at(time: float, lead: float) -> Vector2` (pure: `path_at(s_at(time +
  lead))`); `func cone_holds(p: Vector2, time: float) -> bool` (pure); `var frightened_ahead := 0`.

- [ ] **Step 1: Tests:**
  - `"people ahead panic before it arrives"`: a citizen on the drag line 7.0 ahead of the press: PANIC or FLEE (or
    startled) while the head is still ≥ 3.0 from him; `fx.frightened_ahead >= 1`.
  - `"one off to the side is not sent running by the cone"`: a citizen 5.0 off the line at the press's side, 90° off
    the heading: `CALM` until the head has passed him. Replaces `test_serpent.gd:498-509`.
  - `"the cone is 30 degrees either side, 8 long"`: `cone_holds` at 7.9 on the heading, true; 8.1, false; at 29° true,
    at 31° false.
  - `"the town's lights dim ahead and come back"`: during the glide `TownPools.dim_factor(fx.ahead_at(t, 1.0)) <= 0.3`;
    after the end, 1.0.
  - `"cut short: nothing stays dimmed or frosted"` (Review Focus 3): `_finish()` mid-glide, and a second cast freed
    (`_exit_tree`): `dim_factor` back to 1.0 everywhere tested; no frost node left in `ctx.ground`.
  - The kill-lane, loop, soul and seam checks keep passing.
- [ ] **Steps 2-4:** FAIL, implement, then run `test_serpent`, `test_death_aims`, `test_targeting`, `test_awareness`,
  and the town-look suites that load `TownPools` (`grep -ln TownPools tests/`). Expected: 0 failures. Run crowd_check.
  Expected: `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: The Pale Serpent -- a death wave ahead: fog, frost, the lights going out, the street
  running`.

### Task 8: Mission buildings are spared

**Files:**
- Create: `src/game/crowd/mission_keeps.gd`.
- Modify: `src/game/mission/mission_director.gd` (virtual `needs_standing`), and an override in each director that
  keeps goal buildings in its own members: `raze_director.gd` (`targets`: Raze, Spoiled Harvest's granaries),
  `crowns_bread_director.gd`, `bishop_director.gd` (`refuges`), `bell_ringers_director.gd` (`posts`, `_stone`),
  `broken_lanterns_director.gd` (`shrines`), `heart_of_faith_director.gd` (`oil_house`, `temple`),
  `heretic_hunt_director.gd` (`cellar`, `temple`), `lantern_eye_director.gd` (`towers`, `temple`),
  `lost_lamb_director.gd` (`fountain`), `miras_house_director.gd` (`house`), `prisoner_director.gd` (`stocks`),
  `assassinate_director.gd` (`hideout`), `escort_director.gd` (`bound_by`), `warning_director.gd` (`_key_gate`). The
  rule for any other: a `Structure` member whose `destroyed` the director reads for a loss, a star or an objective.
- Test: create `tests/test_mission_keeps.gd`, register it in `tests/run_all.gd`.

**Interfaces (R45):** `class_name MissionKeeps extends RefCounted`; `static func spared(s: Structure, crowd: Crowd,
director: MissionDirector) -> bool`; `func MissionDirector.needs_standing(s: Structure) -> bool` (base: false).

- [ ] **Step 1: Tests:**
  - `"the Citadel and the temple are spared, a house is not"` (role `&"citadel"`, `&"temple"`, `&"house"`).
  - `"a hallowed building is spared while the mark holds"` (Review Focus 4): `crowd.mark_structure(s, &"hallowed",
    2.0)`: spared at 1.0 s, not at 2.5 s; `&"cursed"`: not spared.
  - `"a building with a damage filter, or set aside, is spared"`.
  - `"no director: the generic rules only"`: `spared(house, crowd, null) == false`, `spared(temple, crowd, null)`.
  - `"each director names its goal buildings"`: per overridden director, a bare instance with its member set to a stub
    structure: `needs_standing(stub)` true, a stranger false.
- [ ] **Steps 2-4:** FAIL; implement; import twice, restore `default_bus_layout.tres`; run `test_mission_keeps` and the
  suites of the edited directors (`test_harvest`, `test_raze`, `test_crowns_bread`, `test_bishop`, `test_bell_ringers`,
  `test_broken_lanterns`, `test_heart_of_faith`, `test_heretic_hunt`, `test_lantern_eye`, `test_lost_lamb`,
  `test_miras_house`, `test_prisoner`, `test_assassinate`, `test_escort`, `test_warning`, whichever exist:
  `ls tests/`). Expected: 0 failures. Run crowd_check. Expected: `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: one rule for the buildings a night needs standing (the Citadel, the temple, the
  hallowed, each mission's own)`.

### Task 9: Grave Tide (city-wide grave burst)

**Files:** Modify `src/fx/death/grave_tide.gd`, `src/game/power_book.gd` (`gravetide` `needs` only),
`src/game/rules.gd` (drop `any_body` if unused), `src/game/targeting.gd` (`AREAS["gravetide"]` preview),
`tests/test_gravetide.gd`.

**Interfaces:** Consumes `DeathParts.skeleton/ghoul/zombie`, the `spare` and `prefer` traits (Task 2),
`MissionKeeps.spared` (Task 8). R41-R44:
- Consts: `GRAVES_MOST 24`, `GRAVE_GAP 2.5`, `BURST_STEP 0.08`, `LIVING_CAP 60`, `GIANT_LEG 25.0`, `SLAM_WRECK 60.0`,
  `ZOMBIE_WRECK 3.0`, `ZOMBIE_WRECK_EVERY 1.5`, `SKELETON_WRECK 6.0`, `SKELETON_WRECK_EVERY 1.5`, `GHOUL_WRECK 3.0`,
  `GHOUL_WRECK_EVERY 1.0`. Drop `CLUSTER_R`, `CLUSTER_MIN`, `cluster()`, `MARCH_FOR`, `_nearest_soldier()`.
- `static func grave_spots(grid: WalkGrid, districts: Array) -> Array[Vector2]` (R41).
- Vars: `graves: Array[Vector2]`, `burst := 0`, `giant_grave := -1`, `visited: Array[int]`, `slam_wrecks := 0`;
  `func undead_up() -> int` (living, the giant not counted).
- The aim: `AREAS["gravetide"] = {"shape": "graves", "r": GIANT_AURA}`: a bone mark (`_death_mark`, `COL_BONE`) on
  every grave spot and the ring round the one nearest the cursor (spots cached per grid).

- [ ] **Step 1: Tests** (drop the cluster, `any_body` and march-to-click checks; keep assembly, landing, slam cadence,
  cut-short and aura checks, moved to the grave):
  - `"graves across every district"`: Aldermere's districts: every district has a spot within it or within 2.5 of it;
    all walkable; ≤ 24; pairwise ≥ 2.5; two calls equal.
  - `"a district built over is skipped; 40 districts keep 24, spread"` (Review Focus 5): a stub grid where one district
    has no walkable cell within 6: no spot from it; 40 stub districts: 24 spots, taken by `floor(i * n / 24)`.
  - `"always castable, the giant always comes"`: no remains: `rules.cast()` refuses nothing; `fx.graves.size() > 0`;
    the giant stands at `T_RISE + ASSEMBLE + 0.05` at the grave nearest the click (or its snap).
  - `"each grave raises a skeleton warrior and a ghoul"`: after the last burst, breed counts SKELETON == GHOUL ==
    `graves.size()` (while under the cap).
  - `"the town's bodies rise on top, the cap holds at 60"`: 30 bodies: zombies == `mini(30, 60 - 2 * graves.size())`,
    and `undead_up() <= 60` sampled every step.
  - `"the giant walks the graves"`: at landing + 30 s `fx.visited.size() >= 2` and it stands ≥ 4.0 from its grave.
  - `"a slam knocks a house down"`: a house (hp 50) 2.0 from the landing: destroyed by the landing slam;
    `slam_wrecks >= 1`.
  - `"a building the night needs is never damaged"`: a temple and a director-held house (stub `needs_standing`) within
    `SLAM_R` and beside skeletons for 20 s: hp unchanged; a plain house beside them is clawed.
  - `"cut short mid-burst: no more graves, no giant"`: `_finish()` at `T_RISE + 0.3`: `burst` stops rising, `giant ==
    null`, `visitors.living().is_empty()`.
  - **Perf:** `_perf` with every grave and 30 bodies (60 undead + the giant), run past two slams: `PERF_MS 8.0`. Print
    `TIDE perf: %.3f ms`.
- [ ] **Steps 2-4:** FAIL, implement, then run `test_gravetide`, `test_death_kit`, `test_fight_back`,
  `test_mission_keeps`, `test_awareness`, `test_targeting`, `test_power_book`. Expected: 0 failures. Run crowd_check.
  Expected: `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: Grave Tide -- the graves of the whole city burst, the dead storm every district, the
  giant walks the town` (perf number in the body).

### Task 10: Book text, launchers and rulings reconciled

**Files:** Modify `src/game/power_book.gd` (`blurb` and `shape` of `raise`, `gatebelow`, `pale`, `serpent`,
`gravetide`; nothing else), `try/try_{raise,gatebelow,pale,serpent,gravetide}.bat` (`rem` lines),
`docs/KAK_God_Death_Review_Rulings.md`, and any test asserting these strings.

**Exact copy** (this plan's ruling):
- `raise`: `"Every body in the ring rises to hunt the living, or its soul to haunt them."`
- `gatebelow`: `"The ground splits wide and grasping hands drag the living under; their souls come back to wither the town."`
- `pale`: unchanged.
- `serpent`: `"A vast serpent glides through town on a wave of cold fog and frost; its shadow kills and it drinks the souls. Once a descent."`
- `gravetide`: `"The graves of the whole city burst; the dead storm the streets and a giant of bones walks the town, slamming it flat. Once a descent."`
- The `shape` strings restate each power's numbers from R28-R44 (Grave Tide's loses "needs a body somewhere in town").

- [ ] **Step 1:** Edit the text; reconcile the rulings doc with the numbers shipped (grep each constant).
- [ ] **Step 2:** Run `test_power_book`, `test_power_sounds`, `test_awareness`, `test_skill_tree`, `test_raise_dead`,
  `test_gravetide`. Expected: 0 failures.
- [ ] **Step 3:** Commit: `docs: Death's book text says what the reviewed powers now do; rulings reconciled`.

### Task 11: Bench and the Heaven's Door bar

**Files:** Modify `src/game/mission.gd` (`_bench_cast`), `docs/KAK_God_Death_Review_Rulings.md` ("Bench" and "Bar").

**Interfaces:** `--bench-tally=SECONDS` in `_bench_cast`: after the cast it counts deaths and `structure_destroyed`
for SECONDS, prints `TALLY key=<key> seconds=<S> deaths=<D> citizens=<C> soldiers=<X> destroyed=<B>`, then quits
before `_bf.bench()`. Only under `--bench`.

- [ ] **Step 1:** Implement; check it parses (`--only=test_god_night`).
- [ ] **Step 2: Bar (R46).** Run each once (deterministic):
  `timeout 900 $G --headless --path . --fixed-fps 60 --audio-driver Dummy --scene res://scenes/mission.tscn -- --bench
  --seed=1 --loadout=gravetide --bench-cast=gravetide --bench-tally=70` and the same with `--loadout=heavendoor
  --bench-cast=heavendoor --bench-tally=30`. (If the bench path will not start headless, run it windowed with the
  same `--fixed-fps 60`: these are counts, not times.) Expected: Grave Tide's `deaths` ≥ Heaven's Door's and
  `destroyed` ≥ Heaven's Door's. Short: strengthen units per R46 within the caps, re-run Task 9's suite and this step;
  record every pass and the final gap.
- [ ] **Step 3: Bench (R47)**, on a quiet machine (no other Godot), 3 alternating pairs each:
  `timeout 300 $G --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench
  --loadout=<key>` against the same with `--bench-cast=<key> --bench-after=<A>`: `gatebelow` A 8 (wraiths out),
  `pale` A 6, `serpent` A 4, `gravetide` A 10 (graves burst, giant landed; no `--bench-bodies`). Expected: median
  delta ≤ 5.0 ms (`gatebelow`, `pale`, `serpent`) and ≤ 8.0 ms (`gravetide`). Over: `--bench-prof`, cut cost (fog and
  frost caps, hands, `BURST_STEP` spread), record the cut as a ruling, re-bench. Never ship over.
- [ ] **Step 4:** Commit: `dev: --bench-tally; Grave Tide against Heaven's Door, and the reviewed powers within their
  frame budgets` (the tallies and the twelve pairs in the body and the doc).

### Task 12: Death bots and references

**Files:**
- Modify only if a gate fails: `tools/dev/routes/god_t1/{harvest,lamb,prayers}.gd` (`act_death`),
  `tools/dev/behaviour_check.gd` (`_first_taste_haunt`), `tools/dev/routes/god_hunts/hide_faithful.gd` (`act_death`).
- Re-record: the Death rows of `tools/dev/refs/god_t1_{harvest,lamb,prayers}.tsv`, and `first_taste_death_play_1-3`
  and `hide_faithful_death_play_1-3` in `tools/dev/refs/references.tsv`. These cast Raise (the ring: R28) and Lamb's
  zombies meet the fight-back (R30).

**Rules** (as last round):
- A gate passes at wins ≥ 2/3 and idle ≤ 45 s; the user's exceptions only: Prayers x Death and Lamb x Death
  `--idle-max=60` (D34, R25).
- No filler casts. No `src/` or director change to make Death pass.
- A night that cannot be won is reported to the controller with evidence (the run lines, what was tried), not tuned
  around.
- R48: the rows that must not move (they cast no changed power) are checked against `refs_base.txt`; if one moves,
  that is a bug in Tasks 2-9: find it. `break_hunt_death_*` casts `deathmark`/`pestilence`, `face_halcyon_death_*`
  casts `deathmark` only, so neither may move.

- [ ] **Step 1: Gates**, `--jobs=2` each:
  - `bash tools/dev/gate.sh harvest --god=death:1`; `bash tools/dev/gate.sh lamb --god=death:1 --idle-max=60`;
    `bash tools/dev/gate.sh prayers --god=death:1 --idle-max=60`;
  - `bash tools/dev/gate.sh first_taste --god=death:1 --extra='--dev-tree'`;
  - `bash tools/dev/hunt_gate.sh --only=hide_faithful --type=death --jobs=2`.
  - Expected: `PASS` for each. On a FAIL, adjust only that policy (a spirit cast where the ring now lifts more than
    one body is fine as long as the cast still answers the night), and gate again.
- [ ] **Step 2:** Re-record each moving row: `timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy
  -s tools/dev/behaviour_check.gd -- <the row's args>`, the last `checksum=`; edit the tsv in place.
- [ ] **Step 3:** `bash tools/dev/refs_check.sh --only='death' --jobs=3`. Expected: `refs ok=33 bad=0`; the R48 rows
  equal `refs_base.txt`.
- [ ] **Step 4:** Run `test_god_routes`, `test_break_hunt`, `test_expel_inquisitor`, `test_hide_faithful`,
  `test_first_taste`. Expected: 0 failures.
- [ ] **Step 5:** Commits: `dev: the Death bots play the second review` (only if a policy changed) and `dev: Death refs
  re-recorded for the second review` (the body lists every row that moved and why: the ring, the fight-back).

### Task 13: Full gate and land

- [ ] **Step 1:** Import twice, restore `default_bus_layout.tres`.
- [ ] **Step 2:** The suite in 5 parts, in the background:
  `for N in 1 2 3 4 5; do timeout 3000 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd --
  --part=$N --of=5 > <scratchpad>/part$N.log 2>&1 & done; wait`. Expected: every log ends `failures=0`;
  `grep -l "SCRIPT ERROR\|Parse Error"` finds nothing. A timing check that fails only under parallel load is re-run
  alone before it counts.
- [ ] **Step 3:** crowd_check. Expected: `checksum=-535548941`. Then `bash tools/dev/refs_check.sh --jobs=4`. Expected:
  `bad=0`, or only rows already failing in `refs_base.txt`.
- [ ] **Step 4:** Land (check-before-every-merge): fetch `origin/feat/god-progression`; trial-merge into
  `god/death-review-2` (commits exist, so `merge-tree` is valid); check API clashes in `visitors.gd`, `animal.gd`,
  `crowd.gd`, `person.gd`, `targeting.gd`, `rules.gd`, `power_book.gd`, `mission_director.gd`, `town_pools.gd`; merge,
  re-run Steps 2-3 on the merged tree, fast-forward `feat/god-progression`, push. **On any conflict, stop and tell the
  user.**
- [ ] **Step 5:** Show the user the four sheets (Task 1) and the bar numbers (R46). Post to #god-changelog. Update the
  Dev Ledger (a task for the second review; the #ideas idea done), refresh #board, mark the #ideas post "2nd Review on
  Death's Abilities" DONE and close it (discord-idea-done-protocol). Update memory (`kak-god-progression`).

---

## Self-review notes

- **Spec coverage:**
  - Shared fight 1-3 → Task 3 (R30-R32), the kinds from Task 2.
  - Raise → Task 4 (R28, R29), its aim marks included.
  - Gate Below 1-3 → Tasks 1, 2 and 5 (R33-R37).
  - Pale Reign 1-2 → Tasks 1, 2 and 6 (R38, R39).
  - Serpent → Task 7 (R40).
  - Grave Tide 1-9 → Tasks 1, 2, 8 and 9 (R41-R45); 5 and 10 (the bar and how it is measured) → Task 11 (R46).
  - Anti-goals → the Global Constraints, Task 9's perf check and Task 11's bench; no luck in R35/R41/R43/R44; no
    hidden losses in R45; silent powers untouched (Walking Corpse's pack is never stepped).
  - Controller's calls: chain 3 → R29; recoil → R32; bare hands on solid undead only → R30; art first, ~150
    generations, previews shown at the end → Tasks 1 and 13.
  - Checks → each task's tests; refs in Task 12; full gate, crowd_check and the bench in Tasks 11 and 13.
- **Determinism:** crowd_check is pinned in Tasks 2, 3, 7, 8, 9 and 13 (each touches a class crowd_check loads).
  The soldier's swing, the recoil, the dim and the art are draw-only; the fight-back, the ring and the withering move
  only nights that raise solid undead or cast the changed powers (R48).
- **Parallel worktrees:** after Tasks 1-3, Tasks 4, 5, 6 and 7 own disjoint files (Task 4 alone touches
  `remains.gd`/`rules.gd`/`targeting.gd` among them); Task 9 needs Task 8 and touches `targeting.gd` after Task 4.
  Task 10 edits only blurbs and shapes in `power_book.gd`; Tasks 4 and 9 edit only `pick_r` and `needs` there.
- **Calls made here that the spec left open** (the least sure first): the cornered rule (R30: a timed hold in reach,
  not pathfinding); a withering lapsing indoors (R36); Raise's chain shared at 2 (R29); the rift lip at 4.2 so the
  drag still ends at a lip (R33); Raze's targets spared too (R45); graves raising skeletons and ghouls only, zombies
  coming from the town's bodies (R42).
