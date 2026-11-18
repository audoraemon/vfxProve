# Death authority powers: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the user's eight new Death powers at level 1, the shared remains ledger and undead kit, the Death row
of the god tree, and the Death bots rewritten onto that tree. Land it all on `feat/god-progression`.

**Architecture:**
- **Remains** is a ledger owned by `Crowd`. It hears `EnemyField.enemy_killed`, keeps whole bodies for 45 s and draws
  them in one layer.
- **Undead** are Visitors (`Animal`) with three new breeds: ZOMBIE (wears the dead person's sprite), SPIRIT
  (procedural) and BONE_GIANT (PixelLab sheet). They are spawned through one helper class, `DeathParts`.
- **Each power** is an `FxTimeline` effect under `src/fx/death/`.
- **Possession** reuses Mind Whisper's order wheel through a follow-up, with no copy of the order logic.

**Tech stack:** Godot 4.7.2 GDScript; PixelLab through `tools/dev/pixellab_api.py`; foley via `tools/audio/foley.py`.

**Spec:** `docs/superpowers/specs/2026-11-12-kak-death-authority-powers-design.md`. Read it with this plan; the plan
argues from it.

**Worktree and branch:** `C:/BURIN_NITRO/Godot/GIT/vfxProve-death`, branch `god/death-powers`, cut from
`origin/feat/god-progression` daa0e5e5.

## Global constraints

- **Godot.** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
  - A new `class_name` needs `$G --headless --editor --path . --import` (run it twice), then
    `git checkout -- default_bus_layout.tres`.
- **One suite:** `$G --headless --path . --script res://tests/run_part.gd -- --only=test_x`. Wrap every Godot run in
  `timeout`, and grep for `SCRIPT ERROR|Parse Error`: a parse error hangs `run_part`.
- **No gore.** Palette is bone white, ash grey, pale-white fire and grave green (eyes and glows only).
- **Quiet powers** (`guise`, `walker`): `"quiet": true`, no `Crowd.add_alarm`, no fright, no panic.
- **No luck.** Undead and powers pick by rule (nearest, soldiers first where stated). Never `rng` for a target.
- **Bodies.** Only a whole-body death leaves a remain.
  - Body kinds: `deathmark, plague, mob, frenzy, pale, shadow`.
  - Everything else leaves none, including `doom`, `pit`, `gone`, `water`, `wind`, `lightning`, `stone`, `collapse`
    and all burning kinds.
- **Remains stay off** unless the loadout carries `raise`, `walker` or `gravetide`, or the VFX Sandbox does. With the
  ledger off, `crowd_check` must still print `checksum=-535548941`.
- **A raised body stays dead.** Undead are Visitors; never revive a Person.
- **Powers are reusable effects,** never hard-coded into `Person`/`CitizenAgent`. New person states are `statuses`
  entries or `hold_pace` holds.
- **Refusal banners:** `"no_dead"` shows `NO DEAD THERE`; `"soul_gone"` shows `THE SOUL HAS GONE`.
- **Merge conflicts:** on any conflict while merging or landing, stop and tell the user.
- **PixelLab budget:** 2000 generations a month, 8 job slots. Generate 2 directions and mirror the rest.
- **Sound:** every power has its own cue.
  - A quiet power plays `q_<key>`.
  - A loud power's loudest cue sits at or above `Sfx.QUIET_FLOOR` (-21.0).
  - Sources come from `C:\BURIN_NITRO\SoundLibrary` (never Sonniss in the repo).

## Review focus

1. **Possession refused:** a person who resists, is indoors, is shaken or is a soldier marked `resists_mind()`. The
   spirit keeps its charge, the cast is refused with "missed", and the spirit's 20 s keep running. Test in Task 5.
2. **A remain's person freed while a power still holds it:** the ledger keeps value copies, never node references,
   so a freed Person cannot crash a raise. Test in Task 2.
3. **Grave Tide with 0, 1 or 4 remains:** no crash. Fewer than 5 in a cluster means no giant; 0 remains is refused
   as "no_dead". Test in Task 12.
4. **Corpse Guise ending mid-seizure:** a guised believer whose guise ends next to an inquisitor is seized normally
   afterwards, not immune for the rest of the night. Test in Task 7.
5. **Pale Reign over a burning, ringing bell tower:** the bell stays silent for 12 s, then rings on if the night
   still calls for it, not permanently silenced. Use `Crowd.hush`, never `_silence`. Test in Task 10.

---

### Task 0: Worktree ready, baseline green

- [ ] **Step 1:** In the worktree, run the import twice, restore `default_bus_layout.tres`, and run
  `crowd_check.gd` (`--fixed-fps 60`).
  - Expected: `checksum=-535548941`.
- [ ] **Step 2:** Commit the spec copy and this plan: `docs: Death authority powers spec and plan`.

### Task 1: PixelLab sheets (controller runs this, not a subagent)

**Files:**
- Create `assets/pixellab/animals/bone_giant.png` and `.png.json`, in the 10-row animal sheet format.
- Create `assets/pixellab/fx/pale_serpent.png` and `.json`: 8 direction rows of a glide loop, a per-row foot, like
  `heavens_door.json`.
- Create `assets/pixellab/fx/gate_below.png` and `.json`: the pit opening and closing, plus a bone ring, one row.
- Create `assets/pixellab/fx/grave_arms.png` and `.json`: one pale arm reaching and dragging, one row.
- Keep the source downloads under `tools/dev/pixellab_src/death/` (as earlier rounds did), or the scratchpad if that
  folder isn't used.

**Steps:**
- [ ] **Step 1:** Check `python tools/dev/pixellab_api.py balance`, and say the cost before spending.
- [ ] **Step 2: Bone giant.**
  - `character --desc "giant skeleton of many fused human bones, pale-white fire in the eye sockets, hunched, towering, dark medieval pixel art, no blood" --size 96`.
  - Then `char-anim` for walk, attack (swat, into the BITE row) and death, 2 directions mirrored.
  - Pack it with `make_animal_sheet.py --src <dir> --out assets/pixellab/animals/bone_giant.png`.
- [ ] **Step 3: Pale serpent.** A vast feathered serpent with white feathers over dark green scales and a pale glow,
  seen from above at 3/4. Use `character` plus `char-anim` (slither or glide loop), 8 directions (2 generated plus
  mirrors where they read right). Pack the directions as rows.
- [ ] **Step 4: Gate below.** Use `generate` plus `animate`: a pit opening in cobbles, ringed in bone, dark inside
  with faint pale light, 6-9 frames. Then the arm: one pale grasping arm rising, reaching and pulling, 6 frames.
- [ ] **Step 5:** Look at every sheet. Re-roll any with gore, a hood (too like the GHOST breed), or broken frames.
- [ ] **Step 6:** Commit with the message `art: Death sheets -- bone giant, pale serpent, the gate below and its arms
  (PixelLab)`.

### Task 2: Remains ledger

**Files:**
- Create: `src/game/crowd/remains.gd`
- Modify: `src/game/crowd/crowd.gd` (owns it), `src/game/rules.gd` (turns it on, adds the body checks before a cast),
  `src/game/ui/hud.gd` (`_on_cast_refused`: the two new banners)
- Test: `tests/test_remains.gd`, registered in `tests/run_all.gd`

**Interfaces (produced):**
- `class_name Remains extends Node2D`. Constants: `LIFE := 45.0`, `SOUL := 15.0`, `MAX := 60`, `PICK_R := 1.0`,
  `BODY_KINDS: Array[StringName] = [&"deathmark", &"plague", &"mob", &"frenzy", &"pale", &"shadow"]`.
- `class Remain` (inner, values only, no node refs): `pos: Vector2`, `born: float`, `role: int`, `soldier: bool`,
  `kind: StringName`, `design: String`, `facing: int`, `sick: bool`, `hidden: bool`.
- `var enabled := false`
- `func setup(field: EnemyField) -> Remains` connects `enemy_killed`.
- `func step(delta: float) -> void` ages remains; one lapses after `LIFE`, or the oldest when over `MAX`.
- `func pick(at: Vector2, need_soul := false) -> Remain` returns the nearest unhidden remain within `PICK_R`, or null.
- `func near(at: Vector2, r: float) -> Array[Remain]`, `func all() -> Array[Remain]` (unhidden, nearest-free order by
  age).
- `func take(r: Remain) -> void` uses it up. `func move(r: Remain, to: Vector2, hidden: bool) -> void` moves it and
  restarts its clock.
- `func has_soul(r: Remain) -> bool` is age < `SOUL`.
- `static func wants(keys: Array) -> bool` is true if any key is in `["raise", "walker", "gravetide"]`.
- `Crowd.remains: Remains`, created in `Crowd.setup` and added to `world`; `Crowd` steps it.
- Rules turns `crowd.remains.enabled` on where the night's slots are set, if `Remains.wants(slot keys)`. Find that
  place in `rules.gd` and name it in the commit.
- Rules gets body checks before a cast. A row field `"needs": "body"` (or a mode with `"needs": "soul"`) whose ground
  has no remain is refused with `refuse(slot, "no_dead")` or `"soul_gone"`, and no cooldown is spent.
- **Drawing.** Each remain is drawn as the person's own `death` pose, last frame, from `PeopleArt` (design and facing
  captured at death). A hidden remain is not drawn. Draw only when `DominionParts.staged`-style visuals are on.

**Steps:**
- [ ] **Step 1: Write `tests/test_remains.gd`** with the `test_deaddoors.gd` world setup and these checks:
  - `"off by default: a deathmark death records nothing"`
  - `"on: deathmark, plague, mob, frenzy record a remain; lightning, stone, pit, doom, water record none"`
  - `"a remain lapses at 45 s; its soul at 15 s"` (`has_soul` true at 14, false at 16)
  - `"over 60, the oldest lapses first"`
  - `"pick finds the nearest within 1.0, null beyond"`; `"a hidden remain is never picked"`
  - `"take uses it up; move restarts its clock"`
  - `"the person node freed: the remain still raises"` (free the Person, then `pick` returns a Remain with the design
    string intact)
  - `"Rules refuses a needs-body cast with no remain: no_dead, no cooldown spent"`
  - `"Remains.wants(['smite','raise']) is true, wants(['smite']) is false"`
- [ ] **Step 2:** Run it. Expected: FAIL (`Remains` not found).
- [ ] **Step 3:** Implement the interfaces above.
- [ ] **Step 4:** Run `test_remains` and `test_rules`. Expected: 0 failures. Run `crowd_check`. Expected:
  `checksum=-535548941` (the ledger is off).
- [ ] **Step 5:** Commit with the message `feat: remains -- whole bodies stay 45 s for Death's powers (only with
  Death)`.

### Task 3: Death's undead kit

**Files:**
- Modify: `src/game/crowd/animal.gd`:
  - Append `ZOMBIE, SPIRIT, BONE_GIANT` to `Breed`. Never reorder: indices are saved.
  - Add `func wear(design: String, facing: int, tint: Color) -> void` for ZOMBIE: draws `PeopleArt` walk frames
    greyed by `tint`, with two pale eye pixels.
  - Add a SPIRIT procedural draw: a thin pale shape with a trailing wisp, no hood, about 50% see-through, and a face
    that fades in and out. It must not reuse `GHOST_TINT` or the GHOST sheet.
  - BONE_GIANT uses `SHEETS` and the Task 1 sheet, drawn at a scale of about 1.6.
  - Also: `OTHER_SIDE` gets the three, and the town pack never spawns them.
- Modify: `src/game/crowd/visitors.gd`, new `give()` traits:
  - `"knock_first": true`: the first bite on a citizen is `knock_down()`, and a second within 3.0 s kills.
  - `"infect": true`: a bite also calls `infect(PlagueManager.PLAGUE_LIFE)`.
  - `"spare_guise": true`: `_nearest` skips a person with `statuses.has(&"guise")`.
  - `"prey": "soldiers"`: seek soldiers only.
  - `"fright_r": float`: `crowd.fright(...)` around it every 1 s, as the Doors of the Dead ghosts do.
- Create: `src/fx/death/death_parts.gd`, `class_name DeathParts`. All statics:
  - Colours: `BONE`, `ASH`, `PALE_FIRE`, `GRAVE_GREEN`.
  - `ZOMBIE_LIFE := 30.0`, `ZOMBIE_PACE := 0.6` (share of a walk), `ZOMBIE_BLOWS := 3`, `ZOMBIE_SEEK := 10.0`,
    `SPIRIT_FRIGHT_R := 3.0`.
  - `static func zombie(v: Visitors, r: Remains.Remain, plague: bool, eyes := GRAVE_GREEN) -> Animal`: summons at
    `r.pos`, wears `r.design`, and gives `knock_first`, `spare_guise` and `infect` (= `plague or r.sick`). The caller
    `take`s the remain.
  - `static func spirit(v: Visitors, at: Vector2, fright := true) -> Animal`: phase, cannot be cut down (blows 999),
    `fright_r` only if `fright`, `spare_guise`.
  - `static func wraith(v: Visitors, at: Vector2) -> Animal`: a spirit with `prey: "soldiers"`. When it passes through
    someone, `hold_pace(id, 0.5)` for 4 s.
  - `static func on_kill_rise(v: Visitors, remains: Remains, victim: Person, left: int) -> int`: if the victim left a
    remain, raise it as a zombie and return the new `left`. This is the chain.
- Test: `tests/test_death_kit.gd`.

**Steps:**
- [ ] **Step 1: Write the tests:**
  - `"zombie wears the dead person's design"`
  - `"zombie pace is 0.6 of a walk"`
  - `"knock_first: first bite knocks down, second within 3 s kills, after 3 s it knocks again"`
  - `"infect trait: a bitten citizen is sick"`
  - `"spare_guise: a guised person is never chosen"`
  - `"prey soldiers: a citizen nearer is ignored"`
  - `"spirit cannot be cut down; frights within 3"`
  - `"wraith slows who it passes to 0.5 for 4 s"`
  - `"on_kill_rise raises a whole body and not a stone death"`
  - `"the town's pack never spawns ZOMBIE, SPIRIT, BONE_GIANT"`
- [ ] **Step 2:** Run the tests and see them fail.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Pass. Also run `test_animals`, `test_deaddoors`, `test_houndgate` and `test_passage_lv_e`, which use
  the shared Visitors.
- [ ] **Step 5:** Commit with the message `feat: Death's undead -- zombies wear the dead, pale spirits, the bone giant
  breed`.

### Task 4: Possession through Mind Whisper's wheel

**Files:**
- Modify: `src/fx/dominion/mind_whisper.gd`:
  - Extract `static func order(ctx: FxContext, who: Person, extra: Dictionary, seconds: float) -> bool`. It runs walk,
    attack or burn from `extra` (the keys `_order_extra` builds).
  - Mind Whisper itself calls it with its own seconds. Behaviour must not change: `test_mind_whisper` stays green
    unchanged.
- Modify: `src/game/targeting.gd`:
  - When `_rules.can_recast(slot)` and the live effect has `follow_up_wheel() -> bool` returning true, the recast
    uses the whisper press, drag and release interaction and its wheel. `_whisper_reach()` reads the live effect's
    `follow_up_reach()` instead of the `"whisper"` row.
  - On release it calls `_rules.recast(slot, at, _order_extra(who))`.
- Modify: `src/game/rules.gd`: the `"whisper"`-only special case reads `can_recast` live effects too, without
  changing Mind Whisper.
- Test: extend `tests/test_targeting.gd` (or a new `tests/test_follow_up_wheel.gd`).

**Steps:**
- [ ] **Step 1: Write the tests:**
  - `"a live effect with follow_up_wheel gets the whisper wheel on recast"`
  - `"release on a slice passes walk/attack/burn extra to follow_up"`
  - `"Mind Whisper unchanged"` (the existing suite)
- [ ] **Step 2:** Fail.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Pass. Also run `test_mind_whisper` and `test_targeting`.
- [ ] **Step 5:** Commit with the message `refactor: Mind Whisper's orders and wheel serve any follow-up (for
  possession)`.

### Task 5: Raise the Dead (`raise`)

**Files:**
- Create: `src/fx/death/raise_the_dead.gd`
- Modify:
  - `power_book.gd`: the row is `dp 1`, `cooldown 25.0`, `aim "click"`, `"needs": "body"`, `authority "death"`,
    `quiet false`, plus `REACH` and `IMPACT` like `houndgate`, and `FAMILY`. Modes:
    `[{"key": "zombie", "name": "ZOMBIE"}, {"key": "spirit", "name": "SPIRIT", "needs": "soul"}]`.
  - `rules.gd`: `POWER_KINDS["raise"] = [&"frenzy"]`.
  - `targeting.gd`: `AREAS` and `AREA_STATS` `{"r": "SEEK"}`.
- Create:
  - `try/try_raise.bat`
  - an icon line in `tools/dev/make_divine_icons.gd`
  - the cues `raise_rise` (a bone grind with a cold choir breath) and `raise_wail` (the spirit), via foley recipes
- Test: `tests/test_raise.gd`

**Interfaces:**
- Constants: `ZOMBIE_LIFE 30.0`, `CHAIN 3`, `SEEK 10.0`, `SPIRIT_LIFE 20.0`, `FRIGHT_R 3.0`, `POSSESS_R 4.0`,
  `POSSESS 5.0`, `HOSTS 3`.
- ZOMBIE mode:
  - Picks the remain (`ctx.crowd.remains.pick(origin)`), raises it with `DeathParts.zombie`, and chains with
    `on_kill_rise` from `bitten` up to `CHAIN` in all.
  - A soldier cuts one down in 3 blows.
  - Runs `visitors.step` and `recall` at `ZOMBIE_LIFE`.
- SPIRIT mode:
  - Uses `DeathParts.spirit` at the remain, which drifts after the nearest group.
  - `can_follow_up()` is true while it lives and has hosts left. `follow_up_wheel()` is true. `follow_up_reach()` is
    `POSSESS_R` from the spirit.
  - `follow_up(at, extra)` picks a person with `MindWhisperFx.pick` within `POSSESS_R` of the spirit, then runs
    `MindWhisperFx.order(ctx, who, extra, POSSESS)` with `hold_string()`.
    - On success: the spirit hides inside the host for `POSSESS`, then reappears; one host is spent.
    - On failure it returns false, so the HUD shows "missed".
  - The possessed person has pale green eyes, drawn by this effect over the host.

**Steps:**
- [ ] **Step 1: Write the tests:**
  - `"zombie mode raises the clicked remain and uses it up"`
  - `"no remain: refused no_dead, cooldown untouched"`
  - `"zombie kills chain to 3 raised in all, not 4"`
  - `"a zombie from a plague body infects with its bite"`
  - `"spirit mode needs a soul: a 16 s old remain is refused soul_gone"`
  - `"citizens within 3 of the spirit flee"`
  - `"possession: walk order moves the host for 5 s then frees them"`
  - `"possession: attack order sets the host on the foe"`
  - `"3 hosts then can_follow_up is false"`
  - `"a resisting or indoor host is refused (missed) and the spirit keeps its hosts"` (Review focus 1)
  - `"everything recalled by 30 s / 20 s"`
- [ ] **Step 2:** Fail.
- [ ] **Step 3:** Implement the effect, row, tables, icon, launcher and cues. Run `python tools/audio/loudness.py
  --check`.
- [ ] **Step 4:** Pass `test_raise`. Update the counts in `test_power_book` (`POWERS.size()`, the loud list),
  `test_power_sounds` (`loud`), and `test_awareness` (IMPACT). Run them.
- [ ] **Step 5:** Commit with the message `feat: Raise the Dead -- a body rises as a zombie, or its spirit terrifies
  and possesses (5 s, Mind Whisper's orders)`.

### Task 6: Gravecall (`gravecall`)

- **Files:**
  - Create `src/fx/death/gravecall.gd` and the row (`dp 2`, `cooldown 30.0`, `aim "two clicks"`, loud).
  - Tables as in Task 5: `REACH`, `IMPACT`, `FAMILY`, `AREAS`, `AREA_STATS {"r": "HAUNT_R"}`.
  - `POWER_KINDS["gravecall"] = []` (it kills nobody).
  - `try/try_gravecall.bat`, an icon, and the cue `gravecall_rise`.
  - Test: `tests/test_gravecall.gd`.
- **Constants:** `SPIRITS 3`, `HAUNT_R 3.0`, `HAUNT 20.0`, `FREEZE 3.0`.
- **Behaviour:**
  - Three `DeathParts.spirit` rise at `origin`, then drift through walls to `extra.to`.
  - There they haunt for `HAUNT`: `fright` within `HAUNT_R` each second.
  - A soldier a spirit passes through gets `stun(FREEZE)`, once per soldier per spirit.
- [ ] **Step 1: Write the tests:**
  - `"three spirits rise with no body needed"`
  - `"they cross a wall to the second click"`
  - `"people within 3 of the haunt flee"`
  - `"a soldier passed through is stunned 3 s once"`
  - `"gone after 20 s at the spot"`
- [ ] **Steps 2-5:** Fail, implement, pass, update the counts (Task 5 list), commit with the message
  `feat: Gravecall -- three spirits rise and haunt where you send them`.

### Task 7: Corpse Guise (`guise`)

- **Files:**
  - Create `src/fx/death/corpse_guise.gd` and the row (`dp 3`, `cooldown 50.0`, `aim "click"`, `quiet true`).
  - `AREA_STATS {"r": "MARK_R"}`, the cue `q_guise` (a near-inaudible cold breath), launcher and icon.
- **Constants:** `MARK_R 2.0`, `MOST 4`, `SPAN 25.0`.
- **Status:** `statuses[&"guise"] = <seconds left>`. Add `Person.guised() -> bool`.
- **Checked in every watcher:**
  - `EscortDirector._seen_by` and `_watching`
  - `MissionDirector._sees` (a guised target is not seen)
  - `Crowd.nearest_witness`
  - `HideFaithfulDirector._watchers` and `_search_near` (an inquisitor does not search out or seize a guised believer)
  - `Visitors._nearest` (Task 3's `spare_guise`)
  - Soldiers' citizen-target choice
- **Look:** the guised are drawn greyed with eyes down (a modulate and a frame choice), not a new sheet.
- **Tests** (`tests/test_guise.gd`):
  - `"marks the 4 nearest within 2, not 5"`
  - `"an inquisitor beside a guised believer does not seize him"`
  - `"a watcher does not see a guised believer"`
  - `"Death's zombies pass a guised person by"`
  - `"no alarm, no fright from the cast"`
  - `"when the guise ends he can be seized again"` (Review focus 4)
  - Also run `test_hide_faithful`, `test_escort` and `test_mission_director`, unchanged.
- [ ] **Steps 1-5:** TDD as above, update the counts (the quiet lists in `test_power_book`, and `test_power_sounds`
  quiet), commit with the message `feat: Corpse Guise -- the faithful pass as the walking dead; the watch looks past
  them`.

### Task 8: Walking Corpse (`walker`)

- **Files:**
  - Create `src/fx/death/walking_corpse.gd` and the row (`dp 3`, `cooldown 30.0`, `aim "two clicks"`,
    `"needs": "body"`, `quiet true`).
  - The cue `q_walker`, launcher and icon.
- **Constants:** `WALK_LIFE 40.0`, `INFECT_MOST 3`.
- **Behaviour:**
  - Picks the remain at `origin` (the first click) and `take`s it.
  - A ZOMBIE-breed visitor wears the person's design with no grey and no eyes ("passes for living"), walks by roads at
    a person's walk pace to `extra.to`, and never frights.
  - On arrival, or at `WALK_LIFE`, it lies down: the ledger adds the remain back via `move(r, at, hidden)`.
  - `hidden` is true when `to` is inside a shelter or house door. Then, if `r.sick`, it calls `infect` on up to
    `INFECT_MOST` people sheltering there, nearest first. Find the shelter occupant API in
    `src/game/crowd/shelter_manager.gd`.
- **Tests** (`tests/test_walker.gd`):
  - `"no remain: refused no_dead"`
  - `"walks to the second click and lies down there, clock restarted"`
  - `"nobody flees and alarm is unchanged"`
  - `"a plague body walked into a shelter infects up to 3 inside"`
  - `"a hidden remain is not picked by Raise"`
- [ ] **Steps 1-5:** TDD, update the counts, commit with the message `feat: Walking Corpse -- a body gets up and walks
  where you send it, unseen; plague into a shelter`.

### Task 9: The Gate Below (`gatebelow`)

- **Files:**
  - Create `src/fx/death/the_gate_below.gd` and the row (`dp 5`, `cooldown 90.0`, `aim "click"`, loud).
  - `POWER_KINDS["gatebelow"] = [&"pit"]`, `AREA_STATS {"r": "REACH"}`.
  - The cues `gatebelow_open` and `gatebelow_close`, launcher and icon.
  - The sheets from Task 1.
- **Constants:** `PIT_R 3.0`, `REACH 6.0`, `SPAN 12.0`, `GRAB_EVERY 0.5`, `DRAG 1.5`, `WRAITH_LIFE 20.0`.
- **Behaviour:**
  - Every `GRAB_EVERY`, the nearest person within `REACH` who isn't caught yet (out in the open, not guised) is
    grabbed. An arm sprite reaches them; they are `hold_pace(id, 0.0)` and pulled to the pit edge over `DRAG`, then
    killed with `field.kill(p, &"pit", origin)`. That leaves no remain.
  - Each soul is counted.
  - At `SPAN` the pit closes and every counted soul climbs out as `DeathParts.wraith` for `WRAITH_LIFE`.
  - The pit sheet is drawn on `ctx.ground`, and the arms in `stand_layer()`.
- **Tests:**
  - `"grabs the nearest each 0.5 s, never a guised one"`
  - `"a grabbed person dies as pit, no remain"`
  - `"at 12 s one wraith per soul taken"`
  - `"wraiths go for soldiers, not a nearer citizen"`
  - `"loud: the town panics"`
- [ ] **Steps 1-5:** TDD, update the counts, commit with the message `feat: The Gate Below -- pale arms drag the
  living under; their souls climb back out as wraiths`.

### Task 10: Pale Reign (`pale`)

- **Files:**
  - Create `src/fx/death/pale_reign.gd` and the row (`dp 6`, `cooldown 120.0`, `aim "click"`, loud).
  - `POWER_KINDS["pale"] = [&"pale"]`, `AREA_STATS {"r": "RADIUS"}`, the cue `pale_drone` (a low choir and bell
    drone), launcher and icon.
- **Constants:** `RADIUS 10.0`, `SPAN 12.0`, `CRAWL 0.3`, `EVERY 2.0`, `SERVANT_LIFE 20.0`.
- **Behaviour:**
  - A grey multiply veil over the circle, the Yesterday's Door `Veil` pattern with a grey colour, plus a desaturating
    modulate on the people inside.
  - Each step, every person inside gets `hold_pace(id, CRAWL)`; they are freed as they leave and at the end.
  - Each 1 s, burning buildings within `RADIUS` are `douse`d.
  - `ctx.crowd.hush(SPAN)` at the start.
  - Every `EVERY`, the weakest still inside dies as `&"pale"`. Order: sick (`sick_left > 0`) first, then hurt
    (`health` below max), then `statuses.frail`, then nearest the centre. Ties go to the lowest instance id; never rng.
  - Each `pale` death's remain rises as `DeathParts.zombie(..., eyes = DeathParts.ASH)` for `SERVANT_LIFE`.
- **Tests:**
  - `"inside walk at 0.3, freed outside and at the end"`
  - `"the sick die first, then the hurt, then the nearest"`
  - `"one death every 2 s, 6 in 12 s at most"`
  - `"each pale death rises grey-eyed"`
  - `"fires inside are doused"`
  - `"the bell is hushed 12 s, then can ring"` (Review focus 5)
- [ ] **Steps 1-5:** TDD, update the counts, commit with the message `feat: Pale Reign -- a district drains of colour
  and life; its dead rise pale`.

### Task 11: The Pale Serpent (`serpent`)

- **Files:**
  - Create `src/fx/death/pale_serpent.gd` and the row (`dp 6`, `cooldown 999.0`, once a descent like `deaddoors`,
    `aim "drag"`, loud).
  - `POWER_KINDS["serpent"] = [&"shadow"]`, `AREA_STATS {"length": "LENGTH"}`.
  - The cues `serpent_rise` and `serpent_glide` (wind and feathers), launcher and icon.
  - The Task 1 sheet, drawn in `stand_layer()` with `SeeThrough` for the houses it passes behind.
- **Constants:** `LENGTH 14.0` (max drag), `GLIDE 10.0`, `CIRCLE_R 4.0`, `CIRCLE 3.0`, `BAND 1.0` (half width),
  `SIGHT 12.0`, `SICK 20.0`.
- **Behaviour:**
  - The head runs along the drag over `GLIDE`, then circles the end once over `CIRCLE`. The body trails the head's
    path.
  - Anyone out in the open within `BAND` of the head's path as it passes is killed as `&"shadow"`. That is a whole
    body, so it leaves a remain. Houses are untouched.
  - Anyone out in the open within `SIGHT` of the head at its rise and not indoors gets `hold_pace(id, 0.6)` for `SICK`.
    If any plague is live in town (`PlagueManager` has a sick person), they are also `infect`ed.
- **Tests:**
  - `"kills in the band, not 1.5 off it"`
  - `"leaves remains (shadow is a body kind)"`
  - `"no structure damaged"`
  - `"seen within 12: slowed 20 s"`
  - `"once a descent"`
- [ ] **Steps 1-5:** TDD, update the counts, commit with the message `feat: The Pale Serpent -- a feathered serpent
  glides through the town; its shadow kills`.

### Task 12: Grave Tide (`gravetide`)

- **Files:**
  - Create `src/fx/death/grave_tide.gd` and the row (`dp 6`, `cooldown 999.0`, once a descent, `aim "click"`,
    `"needs": "body"`, loud). "Needs body" here means any remain in town, not one at the click.
  - `POWER_KINDS["gravetide"] = [&"frenzy"]`, `AREA_STATS {"r": "GIANT_AURA"}`.
  - The cues `gravetide_rise` and `giant_step`, launcher and icon.
- **Constants:** `MOST 30`, `LIFE 40.0`, `CLUSTER_R 4.0`, `CLUSTER_MIN 5`, `GIANT_BLOWS 12`, `GIANT_AURA 6.0`,
  `AURA_SPEED 1.2`.
- **Behaviour:**
  - Every unhidden remain, oldest first, up to `MOST`, rises as a zombie and walks toward `origin` before hunting.
  - Clusters are found by a deterministic sweep over the remains positions. If the biggest cluster within
    `CLUSTER_R` has at least `CLUSTER_MIN`, one BONE_GIANT bursts up at its centroid: a fountain of bone particles,
    blows `GIANT_BLOWS`, `give` with `wreck`, and its bite kills soldiers outright.
  - Undead within `GIANT_AURA` of the giant get speed ×`AURA_SPEED`.
  - Everything is recalled at `LIFE`.
- **Tests:**
  - `"0 remains in town: refused no_dead"`
  - `"4 remains: 4 zombies, no giant"`
  - `"5 within 4: a giant at their centre"`
  - `"30 cap: 40 remains raise 30, oldest first"`
  - `"aura speeds undead near the giant"`
  - `"the giant wrecks a wall in its way"`
  - **Perf:** `"30 zombies + giant: _fx_process + visitors.step under 5 ms a frame averaged over 200 frames"` (measure
    with `Time.get_ticks_usec`, as the Doors of the Dead perf check did; report the number in the commit).
- [ ] **Steps 1-5:** TDD, update the counts, commit with the message `feat: Grave Tide -- every body in town rises;
  where the most lie, a giant of bones`.

### Task 13: The Death row and the Death bots

- **Files:**
  - Modify: `src/game/god/god_tree.gd`. The Death row is
    `[["deathmark", "raise"], ["pestilence", "gravecall"], ["guise", "walker"], ["gatebelow", "pale"],
    ["serpent", "gravetide"]]`, with a doc line naming the user's Death Tree Picker (2026-11-12).
  - Modify: `src/game/god/god_tree_dev.gd`: a comment that Death's dev keys now sit under the real picks.
  - Modify these tests:
    - `test_god_tree`: Tier 1 picks, Tiers 2-5 incl. Death.
    - `test_god_slot` and `test_skill_tree`, if they use Death keys.
    - `test_hunt_tools` (`TIER1_ONLY`, `PLAYS`, `LACKS` for Death).
    - `test_board_nights` `LOCKED`, if it moves.
  - Modify the Death policies, onto Death Mark and Raise the Dead at Tier 1:
    - `tools/dev/routes/god_t1/{warning,tax,harvest,lamb,prayers}.gd` `act_death`.
    - `tools/dev/behaviour_check.gd` `FT_USES["death"]` and the First Taste Death branches.
    - `tools/dev/routes/god_hunts/*.gd` `LOADOUT["death"]` and `act_death`. Hunts 2-5 may draft Pestilence (Tier 2)
      and the tier keys.
  - Re-record only the Death rows of `tools/dev/refs/*.tsv`.
- **Rules:** as in the Passage bot brief (scratchpad `passage_bots_brief.md`):
  - A gate passes at wins >= 2/3 and idle <= 45 s.
  - No filler casts. No changes to directors or src/ to make Death pass.
  - A night that can't be won is reported with evidence, not tuned around.
- [ ] **Step 1:** Fill the row and update the tree tests. Run `test_god_tree`, `test_god_slot`, `test_skill_tree` and
  `test_power_levels`.
- [ ] **Step 2:** Rewrite the policies, in three parallel shares like the Passage bots: the Tier 1 nights; First
  Taste with Hunts 1-2; Hunts 3-5. Gate each with `god_gate.sh --only=<m>` or `hunt_gate.sh --only=<h>
  --type=death --jobs=2`.
- [ ] **Step 3:** Re-record the Death refs, then run `refs_check.sh` on them.
- [ ] **Step 4:** Commit with two messages:
  - `feat: the Death tree is the user's picks`
  - `dev: the Death bots play the real Death tree; refs re-recorded`

### Task 14: Land

- [ ] **Step 1:** Fetch. Trial-merge `origin/feat/god-progression` into `god/death-powers` (a commit exists, so
  `merge-tree` is valid). Check for API clashes in Visitors, Targeting, Rules and Animal. Merge.
  - **On a conflict, stop and tell the user.**
- [ ] **Step 2:** Run the full gate:
  - import twice
  - 4 parallel parts of `run_part.gd --part=N --of=4`, uncapped
  - `crowd_check` (`checksum=-535548941`)
  - `refs_check`
  - FLOW alone on a quiet machine, if the session allows
- [ ] **Step 3:** Fast-forward `feat/god-progression` and push.
  - Post to #god-changelog.
  - Update the Ledger (a task, and the Death picks idea) and refresh #board.
  - Tell the other god sessions to merge.
  - Update memory.

---

## Self-review notes

- **Spec coverage:**
  - §4 is Task 2.
  - §5.1-5.8 are Tasks 5-12.
  - §6 look and sound sit in each task and Task 1; §7 is Tasks 13-14.
  - §3 perf is Task 12's perf check. The other loud powers are capped by their constants.
- **Changed from the spec:** the spec's Walking Corpse aim "click a body then click" maps to the existing
  `"two clicks"` aim; no new aim kind is added.
