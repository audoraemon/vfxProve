# People animations, phase 1 (madness): implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Madness and fights get their own people animations: a scream when madness breaks, a zombie lurch, a swing on each blow, a soldier thrust, and bystanders knocked down who then get back up.

**Architecture:**
- The atlas tool grows from 5 animation rows per design to 9. It mirrors each generated direction into its missing partner and builds `getup` from `death` reversed.
- `PeopleArt.ANIMS` grows to match.
- `Person` picks the new rows from four small timers: scream, swing, down and getup. The fight's madness kind chooses the lurch.
- Art comes from PixelLab on the existing character ids. A pilot on one design stops for the user's approval before the rest is spent.

**Tech stack:** Godot 4.7.2 GDScript; Python 3.12 + Pillow (`tools/dev`); PixelLab (MCP `animate_character`, `tools/dev/pixellab_api.py`).

**Spec:** `docs/superpowers/specs/2026-10-23-people-madness-animations-design.md`

## Global constraints

- **Where:** worktree `C:\BURIN_NITRO\Godot\GIT\vfxProve-people-anim`, branch `feat/people-anim`. Never edit other worktrees.
- **PixelLab budget:** 81 generations plus up to 20 daily bonus. Generate **2 directions** per animation (`south-east`, `north-east`) and mirror the other 2.
  - If the pilot bills more than **1.5× the estimate**, stop and report.
  - Never paste or print the PixelLab API key.
- **The pilot (Task 2) is a hard stop:** show the user, then wait for approval before Task 4.
- **References:** `tools/dev/refs/references.tsv` lists every exact checksum. Check them with `bash tools/dev/refs_check.sh --only='<regex>'`.
  - Exact: `digest`, `crowd_check`, `calm` and FLOW.
  - Allowed to change: fight and madness references only. Re-record each in `references.tsv` in the same commit, with the reason in the commit body.
  - Any other change is a regression to fix.
- **Tests:** before each commit, `bash tools/dev/run_suite_parallel.sh 8` must give `failures=0` and 0 `SCRIPT ERROR`.
- **Landing:** the full references, FLOW alone and the bench run in Task 5 through `bash tools/dev/land.sh --bench=<last tag>`.
- **Commits:** stage by name, including `.uid` and `.import` files. End each message with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never `git commit -a`. Don't push until Task 5.
- **Shell:**
  - `G=C:/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`
  - `PY=/c/Users/dorae/AppData/Local/Programs/Python/Python312/python.exe`
  - Scratch: `C:\Users\dorae\AppData\Local\Temp\claude\C--BURIN-NITRO-Godot-GIT-vfxProve-pixellab\64321455-71f5-4ef9-84ed-ba260def80dc\scratchpad\people\`

## Review focus

1. **Mirrored frames that face the wrong way.** A south-west person must look south-west. Test in Task 1: the mirrored south-west frame equals the south-east frame flipped, and it is used when `_facing < 0`.
2. **A downed person targeted again or fleeing while down.** They must lie still and nobody may strike them. Test in Task 3.
3. **Designs with no new art** (phase 2 designs, stand-ins, a run out of budget). They fall back to idle or walk, with no hole and no error. Test in Task 1: a design missing a row gets idle frames.
4. **The scream cut short by death or freeze.** A person who dies or freezes mid-scream doesn't scream on. Test in Task 3.
5. **The pose-code packing overflowing** once there are 9 animations. Frame, animation and facing must round-trip for every animation. Test in Task 1.

---

### Task 1: Atlas and engine rows (no new art yet)

**Files:**
- Modify:
  - `tools/dev/make_people_atlas.py`
  - `src/environment/art/people_art.gd`
  - `src/game/crowd/person.gd` (only the pose-code packing at about line 1701, plus its unpack in `_sprite_pose()` and `_draw_sprite()`)
- Test: `tests/test_people_art.gd`

**Interfaces:**
- Produces:
  - `PeopleArt.ANIMS := [&"idle", &"walk", &"run", &"stumble", &"death", &"scream", &"lurch", &"swing", &"getup"]`, with `FPS` / `FPS_AT` entries for each.
  - `PeopleArt.ONCE: Array[StringName] = [&"stumble", &"death", &"scream", &"swing", &"getup"]`: animations that hold their last frame.
  - Pose code: `frame << 6 | anim << 2 | facing`, so the animation takes 4 bits.
  - Atlas tool:
    - `STATES` gains `("scream","scream")`, `("lurch","scary-walk")`, `("swing","swing")` and `("getup", None)`. `getup` is derived.
    - `--import` mirrors each missing direction left-right from its partner: SE↔SW, NE↔NW.
    - `getup` is always written as `death` reversed.

- [ ] **Step 1: Write the failing tests** in `tests/test_people_art.gd`.
  - `_rows`: `PeopleArt.ANIMS.size() == 9`.
  - `_info`: for every design, `info(design)[4]` has 36 frame counts.
  - `_getup`: `getup` frame `i` equals `death` frame `n-1-i` (compare the atlas image regions).
  - `_fallback`: a design lacking `scream` returns idle-sized frames, so `frame_count(d, &"scream", 0) >= 1`.
  - `_pack`: for every animation index 0–8, facing 0–3 and frame 0–20, the packed code unpacks to the same values.
- [ ] **Step 2: Run the tests.** Expect a FAIL on the row count.
- [ ] **Step 3: Implement the atlas tool changes.**
  - Add the rows, the mirror-on-import and the derived `getup`.
  - The block becomes `9 * 4` rows.
  - Rebuild the atlas: `$PY tools/dev/make_people_atlas.py`, then run `--import`.
- [ ] **Step 4: Implement `PeopleArt.ANIMS`, `ONCE`, `FPS`/`FPS_AT` and the 6-bit frame shift.** In `_sprite_pose_code()`, clamp every `ONCE` animation to its last frame. Today that is done with `anim >= 3`; check membership instead.
- [ ] **Step 5: Run the tests and the checks.**
  - `test_people_art` passes.
  - Run `run_suite_parallel.sh 8`.
  - Run `refs_check.sh --only='^(digest|crowd_check|calm|madness|fight|powers|soldiers)'`. Every reference listed must be **unchanged**: nothing picks the new rows yet.
- [ ] **Step 6: Commit** `feat: people atlas has scream, lurch, swing and getup rows; mirrored directions; getup from the fall`.

### Task 2: Pilot art on resident_a and guard (hard stop for the user)

**Files:**
- Modify: `tools/dev/pixellab_api.py` (`char-anim` gains `--mode v3 --action TEXT --frames N`, sending `mode: "v3"` and `action_description`)
- Create: `assets/pixellab/people/frames/{resident_a,guard}/{scream,scary-walk,swing}/...` (PNG frames)
- Modify: `assets/pixellab/people/atlas.png` and its manifest

- [ ] **Step 1: Check the balance** (MCP `get_balance`) and record it.
- [ ] **Step 2: Generate for resident_a (id from `characters.json`), directions `south-east` and `north-east` only.**
  1. **Scream:** v3 custom, action `"clutching head with both hands and screaming, staggering in place"`, 8 frames, folder name `scream`.
  2. **Lurch:** template `scary-walk`.
  3. **Swing:** template `cross-punch`, folder name `swing`.
- [ ] **Step 3: Generate for guard:** v3, action `"thrusting a spear forward then pulling it back"`, 8 frames, folder `swing`. Use the same two directions.
- [ ] **Step 4: Check the cost.** Record the balance. If more than 1.5× of 8 generations was spent, stop and report.
- [ ] **Step 5: Import and rebuild the atlas.** Write a scratch preview sheet at 4× showing every new row in all 4 directions, mirrored ones included, for both designs. Name it `pilot_sheet.png`. A small PIL script over the atlas is fine.
- [ ] **Step 6: Read the sheet.** Check:
  - the facing is right;
  - the character is the same one, not a different person;
  - each frame fits its 24 px cell with no clipping;
  - the outline is consistent.

  If a clip is clearly broken, delete it and re-roll once.
- [ ] **Step 7: Commit** the frames, the atlas and the tool change: `feat: pilot people animations on resident_a and guard`.
- [ ] **Step 8: STOP.** Show the user the pilot sheet and wait for their approval. Do not start Task 4 without it. Task 3 may run meanwhile, because it needs no new art.

### Task 3: Behaviour: scream, lurch, swing, knock down, get up

**Files:**
- Modify: `src/game/crowd/person.gd`, `src/game/crowd/madness_manager.gd`
- Test: `tests/test_person.gd` (knock down, get up, swing); `tests/test_madness.gd` (scream, lurch)

**Interfaces:**
- Consumes: `PeopleArt.ANIMS` indices from Task 1.
- Produces on `Person`:
  - `const SCREAM_SECONDS := 1.0`
  - `const DOWN_SECONDS := 1.0`
  - `const GETUP_SECONDS := 0.6`
  - `const SWING_SHOW := 0.35`
  - `var fight_kind: StringName`: set by `fight(..., kind)`. `MadnessManager` passes `&"madness"`.
  - `func scream(seconds: float) -> void`
  - `func knock_down() -> void`
  - `func is_down() -> bool`: true while down or getting up.

- [ ] **Step 1: Write the failing tests.**
  - `_knock_down`:
    - A citizen with mind CALM, struck by `hurt(1.0, attacker)`, ends its knock-back slide.
    - Then `is_down()` is true.
    - Its `ground_pos` doesn't change for `DOWN_SECONDS`.
    - After `DOWN_SECONDS + GETUP_SECONDS` it is fleeing (mind FLEE or PANIC).
  - `_fighter_stays_up`: a citizen in mind FIGHT, when struck, never has `is_down()` true.
  - `_soldier_stays_up`: a soldier, when struck, never has `is_down()` true.
  - `_not_targeted_down`: a frenzy attacker beside a downed person and one standing person picks the standing one.
  - `_scream_then_frenzy`:
    - `MadnessManager` breaks someone with outcome FRENZY.
    - For `SCREAM_SECONDS` the pose is `scream` and they don't move.
    - Then mind is FIGHT with `fight_kind == &"madness"`.
    - The pose while striding is `lurch`.
  - `_scream_cut`: the person freezes or dies mid-scream, and the pose is no longer `scream`.
  - `_swing_pose`: right after a blow, the attacker's pose is `swing` for `SWING_SHOW`.
- [ ] **Step 2: Run the tests.** Expect a FAIL.
- [ ] **Step 3: Implement.**
  - `knock_down()` arms the down timer. It is called from `hurt()` only for a non-soldier citizen whose mind isn't FIGHT and who survives.
  - The down timer starts after the KNOCKBACK slide ends. Movement and pathing are skipped while down. The citizen's existing flee reaction runs when getup ends.
  - `_fightable` and target picking skip `is_down()` people.
  - `MadnessManager._enter` at FRENZY calls `p.scream(SCREAM_SECONDS)` and starts the fight when it ends. The frenzy still lasts 15 s from then.
  - `_sprite_pose_code()` priority: dead, frozen, scream, down (held `death` frames), getup, stumble, swing, run/knock, then lurch (fight_kind madness and striding), walk, idle.
- [ ] **Step 4: Run the tests and the full reference list.** This task changes shared behaviour.
  - Run `run_suite_parallel.sh 8`.
  - Run `refs_check.sh` with no `--only`.
  - `digest`, `crowd_check` and `calm` must be exact.
  - Each fight or madness reference that moved is run twice. If both runs match, re-record it in `references.tsv` and give the reason in the commit body.
  - Any other moved reference is a regression to fix.
  - Run FLOW alone, because this changes shared crowd code.
- [ ] **Step 5: Commit** `feat: madness scream and lurch; blows knock bystanders down and they get up`.

### Task 4: All designs (after the user approves the pilot)

- [ ] **Step 1:** For the 12 remaining citizen designs (`resident_b merchant_a merchant_b craft_a craft_b laborer clergy caregiver_a caregiver_b farmer bellkeeper engineer`), generate scream, lurch and swing exactly as in Task 2, south-east and north-east only. For `marshal escort rescue`, generate the spear thrust.
  - Check the balance after every 3 designs.
  - If generations run out, stop. The finished designs ship and the rest fall back.
  - List which designs were done.
- [ ] **Step 2:** Import, rebuild the atlas, make a full contact sheet and read it. Re-roll only clearly broken clips while budget allows.
- [ ] **Step 3:** Run `test_people_art`, then the full suite.
- [ ] **Step 4: Commit** `feat: madness animations for every people design`, listing any designs that fell back.

### Task 5: Sound, captures, bench, wrap-up

- [ ] **Step 1: Scream sound.** Find a scream in `C:\BURIN_NITRO\SoundLibrary` (`index.json`), honouring the licence rules in memory: no Sonniss in the public repo. Otherwise use an existing crowd sound.
  - Play it on the scream through `_crowd.sfx`, as `q_madness_hit` is played.
  - A test checks the sound key exists.
- [ ] **Step 2: Captures.** A madness sequence in Aldermere through `behaviour_check` or `town_debug`, showing the scream, the lurch, a swing, a knocked-down victim and the get-up. Read the shots.
- [ ] **Step 3: Landing checks.** Run `bash tools/dev/land.sh --bench=<latest kak-v* tag>`. It covers a trial merge, the suite, every reference, FLOW alone and the bench. The bench must stay within about 3 fps of Develop-Main.
- [ ] **Step 5: Wrap-up.**
  - Write a short summary doc.
  - Push `feat/people-anim`.
  - Update the Dev Ledger.
  - Merging into Develop-Main follows check-before-every-merge and needs the user's yes.
