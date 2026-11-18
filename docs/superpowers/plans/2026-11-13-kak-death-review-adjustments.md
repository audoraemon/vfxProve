# Death review adjustments: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the eight reviewed Death powers read clearly and feel dangerous: aim indicators, faster zombies, a haunting
(not possessing) spirit, two-point Gravecall with wraiths, a visible Corpse Guise, a controllable Walking Corpse, a rift
of arms for The Gate Below, a snowballing Pale Reign horde, a 2x seamless Pale Serpent with a soul aura, and a Grave Tide
giant that assembles, lands and slams.

**Architecture:**
- One new PixelLab **wraith** sheet, drawn by a new `Animal.Breed.WRAITH` (appended), is shared by Gravecall, The Gate
  Below and Pale Reign through `DeathParts`.
- Three new **Visitors traits** (`touch_kill`, `spent_on_kill`, `bounds`) carry the new kills; one new kill kind
  `&"grave"` carries Walking Corpse's silent kill.
- **Targeting** gets the Death aim marks, Gravecall's `"route"` preview, and a *subject* variant of the follow-up wheel
  (the wheel opens on a Visitor the live effect names, not on a person), which Walking Corpse uses.
- Each power's own change stays inside its `src/fx/death/*.gd` file and its suite, so Tasks 4-11 can run in separate
  worktrees once Tasks 1-3 have landed on the branch.

**Tech Stack:** Godot 4.7.2 GDScript; PixelLab MCP tools (`mcp__pixellab__*`).

**Spec:** `docs/superpowers/specs/2026-11-13-kak-death-review-adjustments-design.md` (binding). It amends
`docs/superpowers/specs/2026-11-12-kak-death-authority-powers-design.md` §5.1-5.8; where they disagree the review wins.
Read both. The rulings below are this plan's picks for what the review left to the builder.

**Worktree and branch:** `C:/BURIN_NITRO/Godot/GIT/vfxProve-death`, branch `god/death-review` (base 7f58732e). Lands on
`feat/god-progression`, never Develop-Main.

## Global Constraints

- `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- One suite: `timeout 600 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd -- --only=test_x`.
  Always `timeout`; always grep the output for `SCRIPT ERROR|Parse Error` (a parse error hangs `run_part`).
- New `class_name` or new imported asset: `$G --headless --editor --path . --import` **twice**, then
  `git checkout -- default_bus_layout.tres`.
- `crowd_check` must print `checksum=-535548941`:
  `timeout 600 $G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`.
- Palette: bone white, ash grey, pale-white fire; grave green only for eyes and glows. No blood, no gore.
- No luck: every target is picked by rule (nearest; soldiers first where stated; ties to the lower instance id). Never `rng`
  for a target.
- Silent powers (`guise`, `walker`) never raise the alarm: no `Crowd.add_alarm`, no fright, `crowd.alarm` unchanged.
- Frame rate: Pale Reign's horde and Grave Tide each cost at most **5 ms a frame** of their own in the 220-person town.
- `Animal.Breed` is append-only (indices are saved). `WRAITH` goes after `BONE_GIANT`.
- A raised body stays dead: undead and ghosts are Visitors, never a revived Person.
- Powers are reusable effects; no power logic in `Person`/`CitizenAgent`.
- No change to `GodTree.TABLE`, costs (`dp`) or cooldowns.
- `tools/dev/**` must stay parseable at every commit: `tests/test_break_hunt.gd`, `tests/test_expel_inquisitor.gd` and
  others preload the route scripts.
- Every task ends green on its own suites plus the listed neighbours. Commit messages end with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- On any merge conflict: stop and tell the user.

## Rulings (the spec's "left to the builder")

Task 0 writes these into `docs/KAK_God_Death_Review_Rulings.md` verbatim. Task 12 reconciles any number a later task had
to move (with the reason).

| # | Power | Ruling |
|---|---|---|
| R1 | Raise | Aim mark on every unhidden remain within `Remains.PICK_R` (1.0) of the cursor. The one `Remains.pick()` takes is the *lead* (ring + skull marker); the others get the ring only. SPIRIT mode: a body with no soul is marked `COL_BAD`, and is never lead. Walking Corpse's first click uses the same mark (lead = `pick(at, false, true)`). |
| R2 | Raise | `DeathParts.ZOMBIE_PACE` 0.6 → **1.0** (a walk: 0.6 u/s). New `DeathParts.ZOMBIE_CHASE := 1.25` (0.75 u/s while it has a target). The gait animates at the speed-derived walk rate; `Animal.ZOMBIE_SHAMBLE` is removed. Applies to every `DeathParts.zombie()` (Raise, Pale's servants, Grave Tide's horde). |
| R3 | Raise | SPIRIT never possesses: `follow_up*`, `POSSESS_R`, `POSSESS`, `HOSTS` and `HostEyes` go. `FRIGHT_R` 3.0 → **4.0** (citizens only); `SPIRIT_LIFE` 20 s, the soul need, and the drift after the nearest group are unchanged. `MindWhisperFx.order()` stays (Mind Whisper uses it). |
| R4 | Gravecall | Aim stays `"two clicks"`. The preview is a new area shape `"route"`. Numbers unchanged: `SPIRITS 3, HAUNT_R 3.0, HAUNT 20.0, FREEZE 3.0` ("same effect on people"). Spirits become wraiths via `DeathParts.haunt()`. |
| R5 | Art | Wraith sheet `assets/pixellab/fx/wraith/wraith.png` + `wraith.json`: cell 64x64, foot (32, 60), rows `drift_se` (8 frames), `drift_ne` (8), `strike_se` (6), 8 fps. West is mirrored. Drawn 1:1 (about 44 px tall, twice a person). It hovers 6 px with a 2 px bob. The cold aura is code-drawn. |
| R6 | Guise | Each guised person carries a `GuiseMark` overlay for the whole `SPAN`: a grey shroud over the sprite and a closed-eye icon 8 px above the head. It is made whether staged or not, so tests can count it. Blurb copy is the spec's sentence. |
| R7 | Walker | Aim stays `"two clicks"`: the body, then the first order (a walk, or entering the building under the click, as today). In the open, on arrival it **stands and waits** instead of lying down. Wheel orders `["walk", "attack", "enter"]`. `ORDER_REACH 12.0`, `ATTACK_R 6.0`, `ATTACK_SECS 10.0`, `KILL_R 0.4`, `KILLS_MOST 2`, `ATTACK_PACE 1.6` (share of a walk while attacking). The kill is kind `&"grave"`. Enter ends it: it lies hidden inside, with plague as today. `WALK_LIFE 40` unchanged: at the end it lies down where it stands. A Death sigil hovers 26 px over it for its whole life. |
| R8 | Gate Below | The pit sheet is dropped and `gate_below.png/.json/.import` deleted. The rift is code-drawn on `ctx.ground`: a jagged polygon of `RIFT_POINTS 18` at radius `EDGE` (1.8) ± 25% (a fixed `sin` hash of the index, no rng), plus `CRACKS 9` hairline cracks out to `PIT_R` (3.0). `ARMS 24` ambient arms (`grave_arms.png`, uniform `ARM_SCALE 0.5`) stand on a golden-angle spiral between `EDGE + 0.3` and `REACH`, each looping rise / claw / sink over `ARM_LOOP 2.4` s, its phase offset by `index * 0.37` s. The grab, drag, `EDGE` and `DRAG` mechanics are unchanged. |
| R9 | Gate Below | Wraith kill rule: **kill on contact**. A wraith within `WRAITH_TOUCH 0.5` of a soldier kills him as `&"pit"` (no body, credited to The Gate Below) and is spent: it sinks with him. `WRAITH_SEEK` 8 → **12**. New `WRAITH_SPEED 1.0` (share of a dog's run: 1.65 u/s). Its slow on citizens it passes is kept. |
| R10 | Pale Reign | `SPAN` 12 → **16**, `EVERY` 2.0 → **1.5**, `MAX_RISEN` 12 → **16**, `SERVANT_LIFE 20` kept. Horde: `HORDE_START 4` ghosts pour out at `EVERY` (with the first drip death, so the first death stays at `IMPACT`). Every death inside the district during the span adds one ghost at the body, while living ghosts < `HORDE_CAP 24` and horde kills < `HORDE_KILLS 24`. Ghosts move through walls at `PALE_GHOST_PACE 2.2` x walk. A ghost's touch (`bite_r 0.4`, once every 0.8 s) kills as `&"pale"`. Ghosts never pick anyone outside `RADIUS`. They sink at `SPAN`. `PowerBook.IMPACT["pale"]` becomes 1.5; `REACH["pale"]` seconds become 16. |
| R11 | Serpent | `SCALE 2.0` (the head and tail sprites are drawn at 2x). `R_NECK` 14 → 28, `R_TAIL` 8 → 16, `SEGMENTS` 22 → 30, `GAP` 0.32 → 0.45, `LIFT` 34 → 60, `WAVE` 6 → 10, `BAND` 1.0 → **2.0** (a 4-wide kill lane). `CIRCLE_R 4.0`, `LENGTH 14.0`, `GLIDE`, `SIGHT` and `SICK` are kept. Seam: a measured `NECK_SOCKET` per head way, a collar disc under the head, and disc 1 placed at the socket. Soul aura: a cold glow and wisps; each kill's soul flies into the nearest body piece over `SOUL_FLY 0.7` s. |
| R12 | Grave Tide | `GIANT_LIFE 60.0` (zombies keep `LIFE 40`). Assembly: `BONES 18` bones fly one by one, from the cluster's remains, into the giant's spot over `ASSEMBLE 1.2` s; the giant stands at `T_RISE + ASSEMBLE`. The landing is the first slam. Then a slam every `SLAM_EVERY 4.0` s while it stands: soldiers within `SLAM_R 3.0` die as `&"frenzy"` (a body), and everyone else is knocked back (`field.knock_from(at, 0.0, SLAM_R, 5.5)`) and frightened (`Crowd.fright(at, SLAM_R + 1.0, 0.8, 3.0, 8.0, 12.0, &"beast")`). The slam plays `giant_step` at +4 dB. There is no new sound file. |
| R13 | Bench | Mission bench aid `--bench-cast=KEY` (optionally `--bench-bodies=N`). It passes when the effect's own cost is ≤ 5 ms: `avg_ms` with the cast minus without, the median of 3 alternating pairs on a quiet machine. Headless perf checks: horde (24 ghosts + 16 servants) and tide (30 zombies + giant + slams) under 5 ms, averaged over 200 frames. |
| R14 | Kit | New kill kind `&"grave"`: added to `Remains.BODY_KINDS` and `DeathVoices.QUIET_KINDS`, with `Rules.POWER_KINDS["walker"] = [&"grave"]`. `Crowd._on_killed` returns after the death voice and before `alarms.incident` / `_hear_alarm` for it, as it does for `&"gone"`. |
| R15 | Wheel | Effect hooks `follow_up_subject() -> Node2D` and `follow_up_orders() -> Array` (see Task 3). With a subject, a press within `Targeting.WHEEL_R` (1.2) of it opens the wheel on it; anywhere else is refused `"missed"`. |

## Review Focus

1. **The walker taken away while its wheel is open** (another power carries off a pack's walkers: Heaven's Door; or it
   times out): the wheel closes quietly, with no refusal banner, no crash and no order sent to a freed node. Test in
   Task 3 (freed stub subject) and Task 7.
2. **The walker's attack target goes indoors, dies, or becomes guised before it is reached:** the order ends, the walker
   stands, and nobody is killed. `KILLS_MOST` is not spent. Test in Task 7.
3. **Pale Reign at its caps, and cut short:** the 25th death spawns no ghost, a ghost never kills outside `RADIUS`, and
   freed mid-reign (`_exit_tree`) leaves no ghost, servant or pace hold. Test in Task 9.
4. **Grave Tide cut short during assembly, or the giant cut down:** no giant appears after `_finish`, and no slam fires
   once the giant is gone. Test in Task 11.
5. **A Raise preview with the ledger off or empty** (a non-Death night, or the sandbox before any death): no crash and
   no marks. In SPIRIT mode, soul-less bodies are red and none is lead. Test in Task 3.

---

### Task 0: Baseline and rulings doc

**Files:** Create `docs/KAK_God_Death_Review_Rulings.md`.

- [ ] **Step 1:** Import twice, restore `default_bus_layout.tres`, then run `crowd_check`. Expected: `checksum=-535548941`.
- [ ] **Step 2:** `bash tools/dev/refs_check.sh --only='death' --jobs=3`. Save the output to the scratchpad as
  `refs_base.txt`. Expected: all OK at base. Any row already failing at base is pre-existing: note it in the rulings
  doc, and do not count it against this branch.
- [ ] **Step 3:** Write the rulings doc: title, source spec, then R1-R15 copied from this plan.
- [ ] **Step 4:** Commit: `docs: Death review rulings (R1-R15)`.

### Task 1: Wraith sheet (PixelLab), FIRST

**Files:**
- Create: `assets/pixellab/fx/wraith/wraith.png`, `wraith.json`, `wraith.png.import`.
- Keep the sources and the prompts used in `tools/dev/pixellab_src/death_review/`.

**Interfaces (produced):** `wraith.json` =
`{"cell": [64, 64], "foot": [32, 60], "fps": 8, "rows": {"drift_se": 0, "drift_ne": 1, "strike_se": 2}, "frames": [8, 8, 6]}`.
The PNG is 512x192 (8 columns x 3 rows of 64x64). Unused cells are transparent.

- [ ] **Step 1:** `mcp__pixellab__get_balance`. State the expected spend (about 6-10 generations) before spending.
- [ ] **Step 2: Base image.** Use `mcp__pixellab__create_image_pixflux` (or `create_image_pro`) at 64x64, transparent
  background, prompt: *"tall dark shrouded wraith, floating, tattered black-grey shroud trailing into wisps below, no
  legs, hollow glowing pale eye sockets, thin bony hands, cold pale-green faint aura, top-down 3/4 view facing
  south-east, dark medieval pixel art, no blood"*. Make a second image of the same wraith seen from behind (facing
  north-east), using the first as a style reference.
  - Lesson from the last round: character mode gave plain humanoid skeletons. Use generate + animate image, not
    `create_character`.
- [ ] **Step 3: Animate.** `mcp__pixellab__animate_image` on each: a slow drift/float loop of 8 frames (the shroud
  sways, the hem trails). Then a strike of 6 frames on the SE image (it lunges, its arms reach forward). Use
  `mcp__pixellab__wait_for_jobs`.
- [ ] **Step 4: Pack.** Lay the frames into the 512x192 grid with Python (PIL). Bottom-centre each frame's lowest opaque
  pixel row on the foot (32, 60). Write the json.
- [ ] **Step 5: Look.** Read the PNG (the Read tool shows images). Re-roll any frame that has gore, a cute or round face,
  legs, a hood that reads like Passage's GHOST breed (`assets/pixellab/animals/ghost.png`), or broken frames. It must
  read as menacing at 1:1 beside a ~20 px person.
- [ ] **Step 6:** Import twice, restore `default_bus_layout.tres`, commit the PNG, the json and the `.import` with
  `art: the wraith (PixelLab) for Gravecall, the Gate Below and Pale Reign`.

### Task 2: Undead kit (breed, traits, kinds, paces)

**Files:**
- Modify: `src/game/crowd/animal.gd`, `src/game/crowd/visitors.gd`, `src/fx/death/death_parts.gd`,
  `src/game/crowd/remains.gd`, `src/audio/death_voices.gd`, `src/game/crowd/crowd.gd` (`_on_killed` only),
  `src/game/rules.gd` (`POWER_KINDS["walker"]` only).
- Test: `tests/test_death_kit.gd`. Update `tests/test_death_voices.gd:60` (the exact `QUIET_KINDS` list) and
  `tests/test_gravetide.gd:291,338` (they read `ZOMBIE_PACE`; they keep working, so only re-run them).

**Interfaces (produced):**
- `Animal.Breed` gains `WRAITH` (index 16). `Animal.UNDEAD` includes `WRAITH`. It is never in the town pack.
- `Animal.var chase_mul := 1.0`. `speed()` multiplies by `chase_mul` when `is_instance_valid(target)`.
- `Animal._draw_wraith(flash: bool)` draws the Task 1 sheet: `drift_ne` when `back`, `strike_se` while the bite pose
  plays, else `drift_se`, mirrored by `facing`, multiplied by `worn_tint`. Under it, a cold aura: two soft ellipses,
  `Color(DeathParts.GRAVE_GREEN, 0.10)` and `0.06`. With no sheet on disk it falls back to `_draw_spirit` at 2x (tests
  must not need the art).
- `Visitors.give()` traits:
  - `"touch_kill": StringName`: reaching the prey (`bite_r`, `bite_every`) kills it outright with
    `_field.kill(who, kind, a.ground_pos)`. No knock and no hurt. `kills += 1`, and `bitten` is emitted.
  - `"spent_on_kill": bool`: after a touch kill, the visitor is freed (after `bitten` is emitted).
  - `"bounds": Vector3(cx, cy, r)`: `_nearest` and the kept target only accept people within `r` of `(cx, cy)`.
- `DeathParts`:
  - `ZOMBIE_PACE := 1.0`, `ZOMBIE_CHASE := 1.25`; `zombie()` sets `a.chase_mul = ZOMBIE_CHASE`.
  - `WRAITH_SEEK := 12.0`, `WRAITH_SPEED := 1.0`, `WRAITH_TOUCH := 0.5`.
  - `PALE_GHOST_PACE := 2.2`, `PALE_GHOST_TINT := Color(0.92, 0.94, 0.97, 0.7)`, `PALE_GHOST_TOUCH := 0.4`,
    `PALE_GHOST_EVERY := 0.8`.
  - `static func wraith(v: Visitors, at: Vector2) -> Animal`: WRAITH breed, prey soldiers, seek `WRAITH_SEEK`, speed
    `WRAITH_SPEED`, `bite_r` `WRAITH_TOUCH`, `touch_kill &"pit"`, `spent_on_kill true`, phase, `spare_guise`, the
    existing slow traits, and `fright_r SPIRIT_FRIGHT_R`.
  - `static func haunt(v: Visitors, at: Vector2) -> Animal`: WRAITH breed, phase, seek 0, `no_bite`, no fright,
    `spare_guise`, blows `SPIRIT_BLOWS`, speed `SPIRIT_SPEED` (Gravecall's).
  - `static func pale_ghost(v: Visitors, at: Vector2, centre: Vector2, r: float) -> Animal`: WRAITH breed, tint
    `PALE_GHOST_TINT`, phase, seek `2.0 * r`, speed `PALE_GHOST_PACE * DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED *
    Animal.RUN)`, `bite_r PALE_GHOST_TOUCH`, `bite_every PALE_GHOST_EVERY`, `touch_kill &"pale"`,
    `bounds Vector3(centre.x, centre.y, r)`, `spare_guise`, blows `SPIRIT_BLOWS`.
  - `spirit()` (Raise's) is unchanged: procedural SPIRIT breed.
- R14: `&"grave"` in `Remains.BODY_KINDS` and `DeathVoices.QUIET_KINDS`; `Rules.POWER_KINDS["walker"] = [&"grave"]`;
  `Crowd._on_killed` returns before the alarm for `&"grave"`.

- [ ] **Step 1: Write the failing tests** in `tests/test_death_kit.gd`, using its existing fixtures:
  - `"zombie walks at a walk (0.6 u/s) with no prey"`: `z.target = null`;
    `t.check(is_equal_approx(z.speed(), 0.6), ...)`.
  - `"zombie chases at 1.25 x walk (0.75 u/s)"`: `z.target = <a citizen>`;
    `t.check(is_equal_approx(z.speed(), 0.75), ...)`.
  - `"WRAITH is appended (16), undead, never in the town pack"`:
    `Animal.Breed.WRAITH == 16 and Animal.UNDEAD.has(Animal.Breed.WRAITH)`, and the town pack's breeds have no WRAITH.
  - `"a wraith kills the soldier it reaches as pit, leaves no body, and is spent"`: one wraith 0.3 from a lone soldier,
    stepped 1 s. Capture `enemy_killed`: `[soldier, &"pit"]`. `remains.near(pos, 0.5).is_empty()`.
    `v.living().is_empty()`.
  - `"a wraith passes a nearer citizen for a soldier"`: a citizen at 1.0, a soldier at 4.0. After 3 s the citizen is
    alive and the soldier dead.
  - `"a pale ghost's touch kills as pale and leaves a remain"`: kind `&"pale"`; `remains.pick(pos) != null` (ledger on).
  - `"a pale ghost never picks anyone outside its bounds, even nearer"`: centre C, r 3. One citizen at C+(3.5,0) is 0.5
    from the ghost; another at C+(1,0) is 2.5 from it. After 4 s the outer one is alive and the inner one dead.
  - `"the grave kind: a body, quiet, no alarm"`: `crowd.alarm` before == after
    `field.kill(p, &"grave", p.ground_pos)`. `remains.pick(p.ground_pos) != null`.
    `DeathVoices.QUIET_KINDS.has(&"grave")`. `Rules.POWER_KINDS["walker"] == [&"grave"]`.
  - `"haunt: a wraith that hunts nobody, bites nobody, frightens nobody"`: a citizen 0.3 away for 3 s stays alive and
    `Person.Mind.CALM`.
- [ ] **Step 2:** Run `--only=test_death_kit`. Expected: FAIL (`WRAITH` not found).
- [ ] **Step 3:** Implement the interfaces above. In `_draw_zombie`, the grey zombie's frame rate uses the same
  speed-derived rate as the white walker. Delete `ZOMBIE_SHAMBLE`.
- [ ] **Step 4:** Run `test_death_kit`, `test_death_voices` (after the list edit), `test_remains`, `test_animals`,
  `test_deaddoors`, `test_houndgate`, `test_raise_dead`, `test_gravetide`, `test_gatebelow` and `test_pale`.
  Expected: 0 failures. `test_gatebelow` may fail on the wraith's new kill; that is Task 8's to update, so note it here
  and do not patch it. Run `crowd_check`. Expected: `checksum=-535548941`.
- [ ] **Step 5:** Commit: `feat: Death's kit -- the wraith breed, touch kills, bounded ghosts, faster zombies, the
  grave kind`.

### Task 3: Aim previews and the subject wheel (Targeting)

**Files:**
- Modify: `src/game/targeting.gd`.
- Test: create `tests/test_death_aims.gd` and register it in `tests/run_all.gd` next to `test_follow_up_wheel.gd`;
  extend `tests/test_follow_up_wheel.gd`.

**Interfaces:**
- Consumes: `Remains.pick/near/has_soul`, `CorpseGuiseFx.marked_at`, `GravecallFx.HAUNT_R` (all existing).
- Produces:
  - `const COL_BONE := Color(0.92, 0.9, 0.82, 0.9)` and `const COL_BONE_FILL := Color(0.92, 0.9, 0.82, 0.16)`.
  - `static func bodies_marked(remains: Remains, at: Vector2, need_soul: bool, hidden_too := false) -> Array[Dictionary]`:
    returns `{"pos": Vector2, "lead": bool, "ok": bool}` for each remain within `Remains.PICK_R` of `at` (R1). It is
    empty for a null or disabled ledger.
  - `func _death_mark(at: Vector2, col: Color, lead: bool) -> void`: draws a ring of r 0.32 plus a fill. When `lead`,
    it also draws a 5x5 skull glyph upright on screen, 18 px above the point, through the inverse basis like
    `_label()`.
  - `_draw()` cases:
    - `"raise"`: marks from `bodies_marked(..., mode == "spirit")`; `ok` false draws `COL_BAD`.
    - `"walker"` while not placed: marks from `bodies_marked(..., false, true)`.
    - `"guise"`: `_death_mark(p.ground_pos, COL_BONE, true)` for each of `CorpseGuiseFx.marked_at` (replaces today's
      plain ring).
  - `AREAS["gravecall"] = {"shape": "route", "r": GravecallFx.HAUNT_R}`. The `"route"` shape draws:
    - not placed: the start mark at the cursor;
    - placed: the start mark at `first`, a dashed line (`WHISPER_DASHES`) from `first` to the cursor, and
      `_ring(_press, r, edge)` there.
    `AREA_STATS["gravecall"]` is unchanged.
  - Effect hooks (R15), both optional and read with `has_method` on `_wheel_fx()`:
    - `follow_up_subject() -> Node2D`: an object with `ground_pos: Vector2` and `is_alive() -> bool` (an Animal). With
      one:
      - a press within `WHEEL_R` of it opens the wheel round it; `MindWhisperFx.pick` is not used;
      - a press elsewhere is refused `"missed"`;
      - "hears" means `is_instance_valid(subject) and subject.is_alive()`;
      - extras are built without `"target"`: walk `{"order": "walk", "to": MindWhisperFx.clamp_to(grid, subject.ground_pos, ground, reach)}`;
        attack `{"order": "attack", "foe": MindWhisperFx.foe_at(field, _pick_at)}` when a foe is there, else refused
        `"foe"`; the third order `{"order": <third word>, "to": _pick_at}`.
    - `follow_up_orders() -> Array`: the three slice words in `WHEEL_ORDERS` slot order (default `WHEEL_ORDERS`).
      Labels and tints follow them. Add `order_color("enter") == COL_BONE`.
  - Keep `_whisper_target: Person` as it is. Add `var _subject: Node2D` and route the wheel centre, held, hears and pick
    through one helper, `_wheel_centre() -> Vector2`. Mind Whisper's own path must not change.

- [ ] **Step 1: Write the failing tests** (`tests/test_death_aims.gd`, using the world setup from
  `test_follow_up_wheel.gd`):
  - `"raise marks every body within 1.0, the picked one lead"`: remains at C, C+(0.6,0) and C+(1.4,0), cursor at C.
    `bodies_marked(rem, C, false)` has 2 entries; exactly one has `lead`, and its `pos == rem.pick(C).pos`.
  - `"spirit mode: a soul-less body is not ok and never lead"`: one remain aged 16 s (`rem.step(16.0)`).
    `bodies_marked(rem, C, true)` gives `[{ok: false, lead: false}]`.
  - `"no ledger, no marks"`: `bodies_marked(null, C, false).is_empty()`, and the same with `rem.enabled = false`
    (Review Focus 5).
  - `"gravecall aims in two points and Esc drops the first"`:
    - `area().shape == "route"`;
    - `press`/`release` at A gives `placed and first == A`;
    - `cancel()` returns true and `not placed`;
    - pressing again at A, then B, casts once with `extra.to == B` at origin A (count the `caster` calls).
- [ ] **Step 2: Extend `test_follow_up_wheel.gd`** with a `SubjectStub` (a WheelStub whose `follow_up_subject()`
  returns an `Animal` placed on walkable ground, and whose `follow_up_orders()` returns `["walk", "attack", "enter"]`):
  - `"a press within 1.2 of the subject opens the wheel on it"`: `aim.wheel_open()`.
  - `"a press 2.0 from the subject is refused missed"`: the refusal list is `[[0, "missed"]]`.
  - `"release past the edge walks the subject"`: `stub.got[0][1] == {"order": "walk", "to": <clamped>}`, and it has no
    `"target"` key.
  - `"ATTACK then a click on a citizen gives the foe"`: `got.back()[1].order == "attack" and got.back()[1].foe == citizen`.
  - `"the third slice is ENTER and gives the click spot"`: `picking_order() == "enter"` after a release on that slice,
    then `got.back()[1] == {"order": "enter", "to": click}`.
  - `"the subject freed: the wheel closes quietly"`: free the Animal, call `hover()`; then `not aim.wheel_open()` and
    the refusal list gains nothing new (Review Focus 1).
- [ ] **Step 3:** Run both suites. Expected: FAIL.
- [ ] **Step 4:** Implement.
- [ ] **Step 5:** Run `test_death_aims`, `test_follow_up_wheel`, `test_targeting`, `test_whisper`, `test_whisper_wheel`,
  `test_dominion_twist_whisper`, `test_dominion_levels`, `test_gravecall` and `test_guise`. Expected: 0 failures.
- [ ] **Step 6:** Commit: `feat: Death's aim marks, Gravecall's two-point route, and the follow-up wheel on a
  subject`.

### Task 4: Raise the Dead

**Files:**
- Modify: `src/fx/death/raise_the_dead.gd`, `tests/test_raise_dead.gd`.
- Minimal and compile-safe only (Task 14 rewrites the policies): `tools/dev/routes/god_t1.gd` (delete `free_spirit`
  and `cast_possess`), plus the possession branches in `tools/dev/routes/god_t1/harvest.gd` and `prayers.gd` and in
  `tools/dev/routes/god_hunts/hide_faithful.gd` (`_spirit`, `_possess`, `POSSESS_PAD`).

**Interfaces:** R3. `RaiseTheDeadFx` keeps `visitors`, `raised`, `spirit`, `drift`, and `FRIGHT_R := 4.0`. It has no
`can_follow_up`/`follow_up*`, so `Rules.can_recast` is false for `raise`. Keep `test_raise_dead.gd`'s `_setup()`/`_done()`
helpers: `test_walker.gd` uses them as `RD`.

- [ ] **Step 1: Tests.** Delete the possession sections (`"possession: ..."`, `"3 hosts ..."`, the resisting host). Add:
  - `"spirit mode never possesses: raise has no follow-up"`: the live fx has neither `follow_up` nor `follow_up_wheel`
    (`has_method` is false), and `rules.can_recast(0) == false` while the spirit stands.
  - `"citizens within 4 of the spirit flee; one at 6 stays calm"`: replaces the 3/6 check.
  - `"a zombie closes on a walking citizen"`: a citizen walks away at `WALK_SPEED`, starting 3.0 off. Within 8 s the
    zombie has bitten them (they are `is_down()` or dead). At 0.6 pace it could not.
  - Book check: `RaiseTheDeadFx.FRIGHT_R == 4.0`.
- [ ] **Step 2:** Run. Expected: FAIL.
- [ ] **Step 3:** Remove possession (R3) and set `FRIGHT_R`. In the bot files, delete the possession branches only, so
  the policies fall through to their other casts. Run `grep -rn "POSSESS\|free_spirit\|cast_possess\|follow_up_from"
  tools src tests`. Expected: only `targeting.gd` and `test_follow_up_wheel.gd` (generic) remain.
- [ ] **Step 4:** Run `test_raise_dead`, `test_walker`, `test_death_kit`, `test_break_hunt`, `test_expel_inquisitor`
  and `test_god_routes`. Expected: 0 failures, no `Parse Error`.
- [ ] **Step 5:** Commit: `feat: Raise the Dead -- zombies keep pace, the spirit haunts instead of possessing`.

### Task 5: Gravecall

**Files:** Modify `src/fx/death/gravecall.gd`, `tests/test_gravecall.gd`.

**Interfaces:** Consumes `DeathParts.haunt()` (Task 2). R4: the numbers are unchanged.

- [ ] **Step 1: Tests:**
  - `"three wraiths rise with no body needed"`: `fx.spirits.size() == 3`, and each
    `breed == Animal.Breed.WRAITH`.
  - The existing flee, freeze, wall-crossing and gone-after-20 s checks stay as they are (the effect is unchanged).
- [ ] **Step 2:** FAIL. **Step 3:** Swap `DeathParts.spirit(visitors, at, false)` for `DeathParts.haunt(visitors, at)`.
  Add a cold ground glow under each wraith while haunting (`FxParts.ground_light`, `DeathParts.GRAVE_GREEN`, 0.35),
  staged only.
- [ ] **Step 4:** Run `test_gravecall` and `test_death_aims`. Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Gravecall -- wraiths answer, and the call is aimed from a marked start`.

### Task 6: Corpse Guise

**Files:** Modify `src/fx/death/corpse_guise.gd`, `tests/test_guise.gd`.

**Interfaces:** R6.
- `var shrouds: Array[Node2D]`, one `GuiseMark` per marked person, tracked in `ctx.overhead` (or `ctx.world` when
  there is no overhead).
- Inner `class GuiseMark extends Node2D` with `who: Person` and `fx: CorpseGuiseFx`. It follows `who` every frame and
  draws only while `fx._keeps(who)`:
  - the shroud: an ash polygon, `Color(DeathParts.ASH, 0.55)`, over the person's PeopleArt foot box, head to knee;
  - the icon: a 7x4 closed eye in `DeathParts.BONE`, with a 1 px dark lid line, 8 px above the head (the head height
    comes from `PeopleArt.info(design)[2].y`).
  It frees itself when the guise lifts.

- [ ] **Step 1: Tests:**
  - `"each guised person carries a shroud mark for the whole span"`: 4 marked gives `fx.shrouds.size() == 4`. At
    `SPAN - 0.5` all are valid and visible; at `SPAN + 0.1` none are valid.
  - `"a guise taken over by a second cast keeps one mark"`: the second cast on the same person. Count the valid
    `GuiseMark`s on that person across both fx: exactly 1 after the first fx stops keeping him.
  - `"no alarm, no fright from the cast"` stays (the marks are drawn only).
- [ ] **Steps 2-4:** FAIL, implement, then run `test_guise`, `test_hide_faithful`, `test_escorts` and
  `test_god_night`. Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Corpse Guise -- a grey shroud and a closed eye over each one hidden`.

### Task 7: Walking Corpse (controllable)

**Files:** Modify `src/fx/death/walking_corpse.gd`, `tests/test_walker.gd`.

**Interfaces:**
- Consumes `&"grave"` (Task 2), and the hooks contract (Task 3, R15). The test calls `follow_up()` directly.
- Produces, on `WalkingCorpseFx`:
  - Constants: `ORDER_REACH := 12.0`, `ATTACK_R := 6.0`, `ATTACK_SECS := 10.0`, `KILL_R := 0.4`, `KILLS_MOST := 2`,
    `ATTACK_PACE := 1.6`, `SIGIL_UP := 26.0`.
  - Vars: `var order := "walk"` (`"walk"`, `"attack"`, `"enter"` or `"wait"`), `var foe: Person`, `var kills := 0`,
    `var sigil: Node2D`.
  - `func can_follow_up() -> bool`: the walker is alive and `not laid`.
  - `func follow_up_wheel() -> bool`: true.
  - `func follow_up_subject() -> Node2D`: `walker`.
  - `func follow_up_from() -> Vector2`: `walker.ground_pos`.
  - `func follow_up_reach() -> float`: `ORDER_REACH`.
  - `func follow_up_orders() -> Array`: `["walk", "attack", "enter"]`.
  - `func follow_up(at_pos: Vector2, extra: Dictionary) -> bool`:
    - walk: walkable, within `ORDER_REACH` of the walker;
    - enter: `indoors_at()` is non-null and its door is within `ORDER_REACH`;
    - attack: the foe is alive, not inside, not guised, within `ATTACK_R`, and `kills < KILLS_MOST`.
    Anything else returns false (the HUD shows "missed").
  - Behaviour:
    - Arriving in the open: `order = "wait"`, it stands (idle anim), still `can_follow_up`.
    - Arriving at a door: it goes in hidden, brings the plague as today, and `laid = true`.
    - Attack: it routes to `foe.ground_pos` at `ATTACK_PACE` x its walk pace (repath 0.5 s). Within `KILL_R` it runs
      `ctx.field.kill(foe, &"grave", walker.ground_pos)`, then `kills += 1` and `order = "wait"`. If `ATTACK_SECS`
      pass, or the foe dies, goes in or is guised first, it gives up (`order = "wait"`, no kill).
    - At `WALK_LIFE` it lies down where it stands (`_lie_down()` as today).
  - The sigil: an inner `class Sigil extends Node2D`, `SIGIL_UP` px over the walker, a 7x7 bone skull with
    grave-green eye pixels and a soft glow (alpha 0.12). It is created whenever `ctx.overhead` exists and freed at lie
    down.

- [ ] **Step 1: Tests** (rewrite `"walks to the second click and lies down there"`; keep the rest):
  - `"arriving in the open it stands and waits, not lying down"`: after the walk, `not fx.laid`, `fx.order == "wait"`,
    `fx.can_follow_up()`, and `remains.pick(dest, false, true) == null` (the body is still up).
  - `"a walk order sends it on"`: `follow_up(p, {"order": "walk", "to": p})` is true, and it ends within `ARRIVE` of p.
  - `"a walk past 12 is refused"`: false.
  - `"an attack order kills quietly and leaves a body"`: the foe is 4.0 off. Within 10 s the foe is dead, with kind
    `&"grave"` (capture `enemy_killed`), `remains.pick(foe_pos) != null`, `crowd.alarm` unchanged, and a citizen 2.0
    from the kill still `Person.Mind.CALM`.
  - `"two kills, then attack is refused"`: `kills == 2`, and the third `follow_up(..attack..)` is false.
  - `"the foe goes indoors first: no kill, it waits"` (Review Focus 2): set `foe.inside = true` mid-chase. Then
    `fx.order == "wait" and kills == 0`.
  - `"enter a shelter: hidden, plague in, the walk over"`: the existing shelter check, reached by an enter order this
    time. `laid` and `remain.hidden`.
  - `"time out: lies down where it stands at 40 s"`: `laid`, and the remain is at the walker's last spot.
  - `"it carries a sigil all its life"`: `is_instance_valid(fx.sigil)` before 40 s; freed after `_lie_down`.
  - `"carried off by another power: the wheel's subject is gone"`: free the walker, step once. Then
    `not fx.can_follow_up()` (Review Focus 1).
- [ ] **Steps 2-4:** FAIL, implement, then run `test_walker`, `test_follow_up_wheel`, `test_remains` and
  `test_death_kit`. Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Walking Corpse takes orders -- walk, go in, or a quiet kill; its sigil marks it as
  yours`.

### Task 8: The Gate Below

**Files:**
- Modify: `src/fx/death/the_gate_below.gd`, `tests/test_gatebelow.gd`.
- Delete: `assets/pixellab/fx/gate_below.png`, `.json` and `.import`, after `grep -rn gate_below.png` shows no other
  user.

**Interfaces:** Consumes `DeathParts.wraith()` (Task 2, R9). R8:
- Drop `PIT_SHEET`, `PIT_CENTRE`, `PIT_SCALE` and `class Pit`.
- Add `class Rift extends Node2D`, drawn on `ctx.ground` in ground units: the jagged polygon (fill
  `Color(0.02, 0.02, 0.03, 0.92 * open_k)`, a 1 px inner edge `Color(DeathParts.GRAVE_GREEN, 0.35)`), the cracks, and
  scattered bone chips.
- Add `static func rift_points(centre: Vector2) -> PackedVector2Array` (pure: radius `EDGE * (1.0 + 0.25 * sin(i * 2.3
  + 0.7))`).
- Add `static func arm_spots(centre: Vector2) -> Array[Vector2]` (pure: `ARMS` points, golden angle `2.39996`,
  radius `lerp(EDGE + 0.3, REACH, sqrt((i + 0.5) / ARMS))`).
- Ambient arms reuse `class Arm` with `loop := true` and `phase := i * 0.37`, in `stand_layer()`. They appear from
  `T_OPEN` and sink over `CLOSE`.

- [ ] **Step 1: Tests:**
  - `"the rift: 18 points between 1.35 and 2.25 from the centre"`: over `rift_points(C)`, every distance is within
    `[EDGE * 0.75, EDGE * 1.25]`, and `size() == 18`.
  - `"24 arms spread over the whole reach"`: `arm_spots(C).size() == 24`; the min distance ≥ `EDGE + 0.3 - 0.01`, the
    max ≤ `REACH + 0.01`; at least 6 lie beyond `REACH * 0.75`.
  - `"no stretched pit sprite"`: `not ResourceLoader.exists("res://assets/pixellab/fx/gate_below.png")`, and the
    script source has no `"gate_below.png"`.
  - `"a wraith that reaches a soldier kills him and is spent"`: one soul taken, then the close. A soldier stands 2.0
    from the pit. Within 4 s of the close, the soldier is dead (kind `&"pit"`) and `fx.visitors.living().size() == 0`.
  - The existing grab, drag, edge, souls and loud checks keep passing (the mechanics are unchanged).
- [ ] **Steps 2-4:** FAIL, implement, then run `test_gatebelow`, `test_death_kit` and `test_awareness`. Expected: 0
  failures.
- [ ] **Step 5:** Commit: `feat: The Gate Below -- a rift of reaching arms; its wraiths take the soldiers they reach`.

### Task 9: Pale Reign (ghost horde)

**Files:**
- Modify: `src/fx/death/pale_reign.gd` and `tests/test_pale.gd`.
- Modify: `src/game/power_book.gd`, the `"pale"` entries of `REACH` (seconds 12 → 16) and `IMPACT` (2.0 → 1.5) only.

**Interfaces:** Consumes `DeathParts.pale_ghost()` (Task 2). R10:
- `const HORDE_START := 4`, `HORDE_CAP := 24`, `HORDE_KILLS := 24`.
- `var horde: Visitors` (its own pack), `var horde_kills := 0`, `var ghosts_made := 0`.
- `func _ghost_at(at: Vector2) -> void` spawns only if `horde.living().size() < HORDE_CAP and horde_kills < HORDE_KILLS
  and t < SPAN`.
- `_on_killed` (already hooked) calls `_ghost_at(e.ground_pos)` for a death within `RADIUS` during the span.
  `horde_kills` counts the horde's own touch kills (the `bitten` signal of `horde`).
- At `SPAN`: `horde.recall(FADE)`. `_finish`/`_exit_tree` clear both packs.

- [ ] **Step 1: Tests** (update the numbers: `"one death every 1.5 s"`, the span 16, `MAX_RISEN 16`):
  - `"the horde pours out at the first death: 4 ghosts"`: at `EVERY + 0.01`, `fx.horde.living().size() >= 4`, all
    WRAITH.
  - `"a ghost's touch kills as pale, the body rises a servant"`: kind `&"pale"`, and `fx.risen` grows.
  - `"every death adds a ghost"`: count deaths inside vs `ghosts_made - HORDE_START` (equal while under the caps).
  - `"the horde stops at 24 alive and 24 kills"` (Review Focus 3): 60 citizens packed inside. At the end
    `fx.horde_kills <= 24`, and the living-ghost count never exceeded 24 (sample it every step).
  - `"a ghost never kills outside the district"`: a citizen at `RADIUS + 0.5` all span is alive at the end.
  - `"at 16 s the ghosts sink; freed mid-reign leaves nothing"`: at `SPAN + FADE + 0.2`,
    `horde.living().is_empty()`. A second cast is freed at 5 s: no `Animal` of breed WRAITH or ZOMBIE is left in
    `crowd.visitors`' packs, and no person has a pace hold from it.
  - **Perf:** `"horde 24 + 16 servants: _fx_process + both packs under 5 ms a frame over 200 frames"`, in the full town
    (220 people), as `test_gravetide._perf`. Print `PALE perf: %.3f ms`.
- [ ] **Steps 2-4:** FAIL, implement, then run `test_pale`, `test_death_kit`, `test_awareness` and `test_power_book`.
  Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: Pale Reign -- a horde of pale ghosts runs the district; every death adds one` (put the
  perf number in the body).

### Task 10: The Pale Serpent

**Files:** Modify `src/fx/death/pale_serpent.gd`, `tests/test_serpent.gd`.

**Interfaces:** R11.
- `const SCALE := 2.0`.
- `const NECK_SOCKET := {"east": Vector2(?, ?), "south-east": ..., "south": ..., "north-east": ..., "north": ...}`:
  sprite px from `HEAD_PIVOT`. Measure each as the centre of the neck's cut edge, the opaque column/row nearest the
  back of the head, with a short PIL script over the five PNGs. Record the script output in the commit body.
- `const SOUL_FLY := 0.7`.
- `func pieces_at(time: float) -> Array[Dictionary]`: pure. Returns `{"sp": Vector2 (screen, alt applied), "r": float,
  "kind": int}` for head, collar, discs and tail, as `_pose` places them. `_pose` uses it.
- `func socket_at(time: float) -> Vector2`: the head's neck socket on screen (`SCALE`, mirror and alt applied). Disc 1
  is placed at it.
- `var souls_in := 0`: incremented when a kill's soul arrives (`SOUL_FLY` after the kill, on the effect clock, staged
  or not). Drawn as a `SoulWisp` only when staged.

- [ ] **Step 1: Tests:**
  - `"seamless: every joint overlaps through the glide and the loop"`: for `time` from `T_RISE + 0.1` to `glide_end()`,
    step 0.05, and for drags along all 8 ways:
    - `pieces_at(time)[1].sp.distance_to(socket_at(time)) <= 1.0`;
    - for each consecutive visible pair, `sp` distance `< (r_a + r_b) * 0.75`.
  - `"twice the size"`: `R_NECK == 28.0 and R_TAIL == 16.0 and SCALE == 2.0`.
  - `"the kill lane is 4 wide"`: `BAND == 2.0`. Someone 1.9 off the path dies; someone 2.4 off lives (replaces
    `"kills in the band, not 1.5 off it"`).
  - `"the loop is kept"`: `CIRCLE_R == 4.0 and LENGTH == 14.0`.
  - `"each kill's soul streams into it"`: after the glide, `fx.souls_in == fx.taken.size()` and `> 0`.
- [ ] **Steps 2-4:** FAIL, implement (the collar disc under the head sprite, scaled sprites, a cold `ground_light`
  following the head at intensity 0.4 with `DeathParts.PALE_FIRE`, and wisp smoke behind the tail every 0.15 s in
  `PALE` colours), then run `test_serpent`, `test_death_aims` and `test_targeting` (the lane preview reads `BAND`).
  Expected: 0 failures.
- [ ] **Step 5:** Commit: `feat: The Pale Serpent -- twice the size, one seamless body, a soul aura and the souls it
  takes`.

### Task 11: Grave Tide (assembly, landing, slam)

**Files:** Modify `src/fx/death/grave_tide.gd`, `tests/test_gravetide.gd`.

**Interfaces:** R12.
- Constants: `const GIANT_LIFE := 60.0`, `ASSEMBLE := 1.2`, `BONES := 18`, `SLAM_EVERY := 4.0`, `SLAM_R := 3.0`,
  `SLAM_KNOCK := 5.5`.
- Vars: `var bones_in := 0`, `var slams := 0`, `var landed_at := -1.0`.
- `func _slam(at: Vector2) -> void`:
  - soldiers out in the open within `SLAM_R`: `ctx.field.kill(s, &"frenzy", at)`, in instance-id order;
  - then `ctx.field.knock_from(at, 0.0, SLAM_R, SLAM_KNOCK)` and `ctx.crowd.fright(...)` as in R12;
  - staged: a ring expanding to `SLAM_R` over 0.35 s on `ctx.ground`, crack lines for 3 s, a dust burst capped at 16
    puffs, `ctx.impact` shake;
  - `slams += 1`.
- The giant is summoned at `T_RISE + ASSEMBLE` (`landed_at`), then `_slam` runs there. Then every `SLAM_EVERY` while
  `is_instance_valid(giant) and giant.is_alive()`. The giant is recalled at `landed_at + GIANT_LIFE`; the zombies at
  `LIFE`. `duration` covers the later of the two.

- [ ] **Step 1: Tests:**
  - `"bones fly in one by one, then the giant stands"`: at `T_RISE + ASSEMBLE * 0.5`, `fx.giant == null` and
    `0 < fx.bones_in < 18`. At `T_RISE + ASSEMBLE + 0.05`, `fx.giant != null and fx.bones_in == 18`.
  - `"the landing slams"`: `fx.slams == 1` right after landing. A soldier at 2.0 is dead (kind `&"frenzy"`, so a body
    lies there). A citizen at 2.0 is alive and frightened (`PANIC` or `FLEE`) and was moved ≥ 0.3.
  - `"a slam every 4 s"`: `fx.slams == 3` at `landed_at + 8.05`.
  - `"no slam once the giant falls"` (Review Focus 4): cut the giant down. `slams` stops rising.
  - `"cut short mid-assembly: no giant ever"`: `_finish()` at `T_RISE + 0.5`, then step 3 s. `fx.giant == null`.
  - `"the giant outlives the horde"`: at `T_RISE + LIFE + 1.0` the zombies are gone and the giant stands. At
    `landed_at + GIANT_LIFE + FADE + 0.2` it is gone.
  - **Perf:** extend `_perf` to include slams (run past `landed_at + 2 * SLAM_EVERY`). Same 5 ms ceiling.
- [ ] **Steps 2-4:** FAIL, implement, then run `test_gravetide`, `test_death_kit` and `test_awareness`. Expected: 0
  failures.
- [ ] **Step 5:** Commit: `feat: Grave Tide -- the giant assembles bone by bone, lands, and slams the ground` (put the
  perf number in the body).

### Task 12: Book text, rulings and launchers

**Files:**
- Modify: `src/game/power_book.gd` (the `blurb` and `shape` of `raise`, `gravecall`, `guise`, `walker`, `gatebelow`,
  `pale`, `serpent`, `gravetide`; nothing else).
- Modify: `try/try_{raise,gravecall,guise,walker,gatebelow,pale,serpent,gravetide}.bat` (their `rem` lines).
- Modify: `docs/KAK_God_Death_Review_Rulings.md`, and any test that asserts these strings
  (`grep -rn "possess" tests/`).

**Exact copy** (the spec fixes the guise blurb; the rest is this plan's ruling):
- `raise` blurb: `"A body rises to hunt the living, or its soul to haunt them."`
- `gravecall` blurb: `"Wraiths rise where you mark, and haunt where you send them."`
- `guise` blurb: `"Hide up to 4 of the faithful as the walking dead; guards, watchmen and inquisitors do not see them for 25 s."`
- `walker` blurb: `"A body gets up and does your bidding: walk, go in, or kill without a sound."`
- `gatebelow` blurb: `"The ground splits and the dead drag the living under; their souls come back for the soldiers."`
- `pale` blurb: `"A district goes grey; pale ghosts run its streets, and every death adds one."`
- `serpent` blurb: `"A vast serpent glides through town; its shadow kills and it drinks the souls. Once a descent."`
- `gravetide` blurb: `"Every body in town rises; a giant of bones assembles and slams the ground. Once a descent."`
- The `shape` strings restate each power's numbers from R1-R12.

- [ ] **Step 1:** Edit the text. Reconcile the rulings doc with the numbers the tasks actually shipped (grep each
  constant).
- [ ] **Step 2:** Run `test_power_book`, `test_power_sounds`, `test_awareness`, `test_raise_dead`, `test_guise`,
  `test_walker` and `test_skill_tree`. Expected: 0 failures.
- [ ] **Step 3:** Commit: `docs: Death's book text says what each power now does; rulings reconciled`.

### Task 13: Frame-rate bench (Pale Reign horde, Grave Tide)

**Files:** Modify `src/game/mission.gd` (a bench aid beside `_bench_beams`/`_bench_toll`).

**Interfaces:** `func _bench_cast(args: PackedStringArray) -> void`:
- `--bench-cast=KEY`: casts the slot whose `Rules.key(i) == KEY` at `TownLayout.MARKET_SQUARE.get_center()`;
- `--bench-bodies=N`: first kills the N citizens nearest the market as `&"deathmark"` (whole bodies, by distance then
  instance id), then waits 1 s;
- then waits `--bench-after` (default 4 s) before `_bf.bench()`. The label gains `-cast-KEY`.
- It is wired into the `--bench` branch, before `_bench_view`.

- [ ] **Step 1:** Implement. Check it parses by running one suite (`--only=test_god_night`, which loads
  `mission.gd`).
- [ ] **Step 2: Bench**, on a quiet machine (no other Godot; see the `land.sh` `busy()` check). Run 3 alternating pairs
  each:
  - Pale: `timeout 300 $G --path . --audio-driver Dummy --disable-vsync --scene res://scenes/mission.tscn -- --bench
    --loadout=pale` against the same with `--bench-cast=pale --bench-after=6` (the horde is at its peak by then).
  - Tide: `--loadout=gravetide --bench-bodies=30` against the same with `--bench-cast=gravetide --bench-after=8` (the
    giant has landed and slammed).
  - Expected: the median `avg_ms` delta ≤ 5.0 for each.
  - Over budget: profile with `--bench-prof`, cut the cost (fewer smoke puffs, `HORDE_CAP` to 20; record any cut as a
    ruling) and re-bench. Do not ship over budget.
- [ ] **Step 3:** Commit: `dev: bench aid --bench-cast; Pale Reign horde and Grave Tide within their 5 ms` (the six
  pairs' numbers go in the body and in the rulings doc).

### Task 14: Death bots and references

**Files:**
- Modify: `tools/dev/routes/god_t1/{warning,tax,harvest,lamb,prayers}.gd` (`act_death`), `tools/dev/routes/god_t1.gd`,
  `tools/dev/behaviour_check.gd` (`_first_taste_haunt` and the First Taste Death branch),
  `tools/dev/routes/god_hunts/{hide_faithful,silence_witness,expel_inquisitor}.gd` (`act_death`).
- Re-record: the Death rows of `tools/dev/refs/god_t1_{warning,tax,harvest,lamb,prayers}.tsv` and of
  `tools/dev/refs/references.tsv` (`first_taste_death_*`, `hide_faithful_death_*`, `silence_witness_death_*`,
  `expel_inquisitor_death_*`).

**Rules** (as in the Passage and Death bot briefs):
- A gate passes at wins ≥ 2/3 and idle ≤ 45 s (Prayers x Death: `--idle-max=60`, D34).
- No filler casts. No `src/` or director change to make Death pass.
- A night that cannot be won is reported to the controller with evidence (the run lines, what was tried), not tuned
  around.
- The possession lines Task 4 removed are replaced with the powers as they now are:
  - the SPIRIT's 4-unit fright, raised where the people to be scared off will walk (a march, a watcher's path, a
    granary's carters);
  - and/or faster ZOMBIEs.
- `break_hunt_death_*` and `face_halcyon_death_*` must **not** move (they cast none of the changed powers). If they do,
  that is a bug in Tasks 2-11: find it.

- [ ] **Step 1:** Rewrite the policies in three shares (they can run in parallel): the T1 nights; First Taste with
  Hide the Faithful; Silence the Witness with Expel the Inquisitor. Gate each with `--jobs=2`:
  - T1: `bash tools/dev/gate.sh <m> --god=death:1` (`warning` with `--board`; `prayers` with `--idle-max=60`).
  - First Taste: `bash tools/dev/gate.sh first_taste --god=death:1 --extra='--dev-tree'`.
  - Hunts: `bash tools/dev/hunt_gate.sh --only=<hunt> --type=death --jobs=2`.
  - Expected: `PASS` for each.
- [ ] **Step 2:** Re-record each row: `timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s
  tools/dev/behaviour_check.gd -- <the row's args>`, taking the last `checksum=`. Edit the tsv in place.
- [ ] **Step 3:** `bash tools/dev/refs_check.sh --only='death' --jobs=3`. Expected: `refs ok=K bad=0`, with
  `break_hunt_death_*` and `face_halcyon_death_*` unchanged from `refs_base.txt`.
- [ ] **Step 4:** Run `test_god_routes`, `test_break_hunt`, `test_expel_inquisitor`, `test_hide_faithful` and
  `test_first_taste`. Expected: 0 failures.
- [ ] **Step 5:** Commits:
  - `dev: the Death bots play the reviewed powers (no possession)`
  - `dev: Death refs re-recorded for the review` (the body lists every row that moved, and why: zombie pace, the
    spirit's haunt, Gravecall's wraiths).

### Task 15: Full gate and land

- [ ] **Step 1:** Import twice, restore `default_bus_layout.tres`.
- [ ] **Step 2:** The suite in 4 parts, in the background (a part can pass 10 minutes under load):
  `for N in 1 2 3 4; do timeout 3000 $G --headless --path . --audio-driver Dummy --script res://tests/run_part.gd --
  --part=$N --of=4 > <scratchpad>/part$N.log 2>&1 & done; wait`. Expected: every log ends `failures=0`, and
  `grep -l "SCRIPT ERROR\|Parse Error"` finds nothing.
- [ ] **Step 3:** `crowd_check`. Expected: `checksum=-535548941`. Then `bash tools/dev/refs_check.sh --jobs=4`.
  Expected: `bad=0`, or only the rows already failing in `refs_base.txt`.
- [ ] **Step 4:** Land (the `check-before-every-merge` procedure):
  - fetch `origin/feat/god-progression`;
  - trial-merge it into `god/death-review` (commits exist, so `merge-tree` is valid);
  - check for API clashes in `visitors.gd`, `animal.gd`, `targeting.gd`, `rules.gd`, `crowd.gd` and `power_book.gd`;
  - merge, re-run the gate on the merged tree, fast-forward `feat/god-progression`, and push.
  - **On any conflict, stop and tell the user.**
- [ ] **Step 5:** Post to #god-changelog. Update the Dev Ledger (a task for the review, and the #ideas post's idea set
  to done), then refresh #board. Mark the Discord #ideas post DONE and close it (`discord-idea-done-protocol`). Update
  memory (`kak-death`/`kak-god-progression`).

---

## Self-review notes

- **Spec coverage:**
  - Raise 1-3 → Tasks 3 and 4.
  - Gravecall 1-2 → Tasks 1, 2, 3 and 5.
  - Guise 1-3 → Tasks 3, 6 and 12.
  - Walker 1-3 → Tasks 2, 3 and 7.
  - Gate 1-2 → Tasks 1, 2 and 8.
  - Pale 1-3 → Tasks 2 and 9 (the drain and hush are untouched).
  - Serpent 1-3 → Task 10.
  - Tide 1-4 → Task 11.
  - Anti-goals → the Global Constraints, the perf checks in Tasks 9, 11 and 13, and the quiet checks in Tasks 2 and 7.
  - Checks → each task, plus Tasks 13-15.
- **Parallel worktrees:** after Tasks 1-3 land on the branch, Tasks 4-11 own disjoint files, except one-line
  `power_book.gd` IMPACT/REACH edits in Task 9 (Task 12 touches only blurbs and shapes there) and Task 4's deletions
  in `tools/dev` (Task 14 rewrites the same functions later, in sequence).
- **Spec ambiguities ruled:** see R1-R15. The main ones:
  - Raise's ring takes one body: everything in it is marked, the one that rises is lead.
  - Walker keeps two clicks; arriving it waits instead of lying down.
  - The wraith kills on contact and is spent.
  - "Every death adds a ghost" counts every death inside the district during the span.
  - The landing is the first slam.
  - The slam kills soldiers as a whole body.
