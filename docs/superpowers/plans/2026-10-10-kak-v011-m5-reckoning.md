# KAK v0.11 M5: Reckoning (Tier 4 complete) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tier 4 (Reckoning) gets its four new missions:
- The Bishop (Assassinate, reused);
- The Armoury (Raze, reused, on M4's staged pattern);
- The Sermon (Convert, reused);
- The Relic Run (Steal, reused).

It also gets two new wishes (heard from Reckoning up). Each mission is on the board, has a behaviour scenario that passes the
user's gate, and is photographed.

**Architecture:**
- **Groundwork (Task 1):** every shared class gains only hooks or vars whose defaults are today's path, proven by the exact
  references:
  - `AssassinateDirector._appoint_guards()` and `_tends()` (The Tax Collector's and The Informer's twelve references);
  - `MirasHouseDirector.lost_reason()` and `BelieversObjective`'s label and reasons (Mira's House, First Prayers' six);
  - `VigilFlameDirector.hud_line()` and `FlameObjective`'s label and reasons (The Vigil Flame's outcome, and its play line
    recorded at the base);
  - `TempleReport.skip` (Mira's House, Broken Lanterns);
  - `RazeDirector.hud_line()` read by `RazeObjective` (Spoiled Harvest's six, The Crown's Bread's six; plan decision 182);
  - `MissionBook._tier4()`.
- **One director per mission, all new files:** `BishopDirector` (an `AssassinateDirector`), `ArmouryDirector` (a
  `RazeDirector`), `SermonDirector` (a `MirasHouseDirector`), `RelicRunDirector` (a `VigilFlameDirector`).
- **Wishes (Task 6):** `PressedWish` gains `"goal"`, `"son_label"`, `"guard_label"`; `MercyWish` gains `"count"`; the pool
  grows to sixteen.
- **Board and screens:** the four join Reckoning on the board in Task 7, once they all exist. Their behaviour scenarios run the
  `MissionBook` versions (the same director, clock and town, no wishes), so the checksums are exact references.

**Tech Stack:** Godot 4.7.2 GDScript. Headless test runner `tests/run_all.gd`. Behaviour scenarios in
`tools/dev/behaviour_check.gd`. The FLOW test in `src/game/game.gd`.

**Spec:** `docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md` (the mission spec, Decisions 121-168, accepted
as rulings, except Decision 137, which the controller replaced: The Armoury uses M4's staged pattern, not seals). It builds on
`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` (§2, §4, §5, §7.1, §8 rows 16-20), M3 as shipped, and M4 as
planned (`docs/superpowers/plans/2026-10-10-kak-v011-m4-wrath.md`, its rulings in
`.superpowers/sdd/2026-10-10-kak-v011-m4-wrath/rulings.md`). Executors read the mission spec and this plan. **M4 lands before
M5 starts:** where this plan names an M4 helper (`MissionDirector._recall_to(v, at, evacuating)`, `_lay_reaching()`,
`RECALL_MINDS`, `EngineerManager.hands_off`, `Kit.evacuate()`, `CrownsBreadDirector`, `_tier3()`, `_flow_tier3()`, the
`bread` / `prisoner` / `hunt` scenarios, `test_tier3_wishes.gd`), it means that helper as M4 lands it. If one differs from M4's
plan in a way a step here depends on, stop and report.

## Global Constraints

- **Baseline** (the controller fills these three in at M4's landing, here and nowhere else): branch
  `claude/lantern-campaign-spec` at `60be4cc` (tag `kak-v011-m4`).
  - Tests baseline **`6049`** (`checks=6049 failures=0`).
  - FLOW **112/0**.
- **Machine:** the BURIN_NITRO laptop.
  - Work in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` (Git Bash
    path `/c/BURIN_NITRO/...`) on `claude/lantern-campaign-spec`. Never `cd` to the repo root; never touch other sessions'
    worktrees.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands** (implementers run every long command in the FOREGROUND, never with a background monitor or polling):
  - **Import** (after a new `class_name` file or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests:** `timeout 1200 $G --headless --path . --script res://tests/run_all.gd 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`.
    - Expected: `checks=N failures=0`. Each task adds to it; report the count.
    - The `leaked` / `still in use` lines at exit are there at baseline too.
    - **The suite may pass the 10-minute foreground cap:** then run it in halves with the scratch runner
      `timeout 600 $G --headless --path . --script res://.superpowers/sdd/2026-10-10-kak-v011-m5-reckoning/run_half.gd -- --half=1`,
      then `--half=2`; add the two counts and report both. (The controller copies M4's `run_half.gd` there, beside `refs24.sh`,
      when it opens the M5 workspace; implementers never edit either.)
  - **FLOW:** `timeout 900 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`.
    - Expected: `FLOW result checks=N failures=0`. The counts by task: 112 through Task 6, 113 from Task 7.
    - **FLOW runs alone** (memory: it aborts under parallel Godot load, as restart-during-ending or a Festival draft Nil). Before
      it, check `tasklist | grep -i godot`: other sessions run Godot. If any runs, say so in the report and rerun when it is quiet.
  - **Behaviour:** `timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- <args>`.
  - **Scenario loop** (a scenario's six runs; paste the function and its call into one Bash command):

```bash
scen() { for c in none play; do for s in 1 2 3; do
  out=$(timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=$1 --case=$c --seed=$s 2>&1)
  echo "$1 $c $s: $(echo "$out" | grep -o 'checksum=-\?[0-9]*' | tail -1) $(echo "$out" | grep -o 'result won=.*' | tail -1)"
  echo "$out" | grep -q "SCRIPT ERROR" && echo "  SCRIPT ERROR in $1 $c $s"
done; done; }
G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe; scen bishop
```

  - **Photos:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture` (writes
    `captures/screen_<name>.png` at twice the 640x360 size).
- **The user's binding rules** (M2 ruling 55, M3's controller ruling 1). Every mission is finished by acting, never by waiting;
  every timed wait is 60 s or less, every chain wait 45 s or less. Each mission task ends with **the gate**, on seeds 1-3 of its
  scenario:
  - `none` (doing nothing) loses 3 of 3;
  - `play` (the scripted player) wins at least 2 of 3;
  - the median time of `play`'s wins is 180-240 s;
  - `play`'s longest stretch between two casts (`idle=` on its result line) is 45 s or less.
  - **The scripted policy works the opposition as a player would before any opposition is tuned down** (M3's Task 2 ruling): if
    the gate misses, first check the policy plays the spec's steps well (clears the next item's guards in the last 25 s, does
    not idle while a slot is ready and a step applies); only then tune the mission's knobs in the spec's order (each task lists
    them), re-run all six, and record each round in the commit body. After three rounds, stop and report to the controller.
    Never add protection or rules the spec and this plan do not have.
  - **Chain arithmetic** (M3's Task 3-4 rulings): with N chained items the clear is about `first wait + (N - 1) x chain + the work
    after each item comes`. Each mission task writes its measured sum next to the spec's in its commit body.
- **Exact references that must NOT move** (the **Reference check**: every task runs all of it before committing, in the foreground):
  - Digest `61267b7e90524d800bf1c3473a71146b` (`$G --headless --path . -s tools/dev/state_digest.gd`).
  - crowd_check `-346732806` (`$G --headless --path . --fixed-fps 60 -s tools/dev/crowd_check.gd`).
  - Behaviour checksums:
    - calm `--scenario=calm --seconds=60`: `-355092532`
    - gates `--scenario=gates`: `927388410`
    - fire `--scenario=fire`: `243410460`
    - rite `--scenario=rite --interrupt`: `-555358538`
    - soldiers `--scenario=soldiers --case=escort`: `-778609674`
    - warning `--scenario=warning --case=none|doom|whisper|discord|mix`: `-489775734` / `-905773030` / `-588314462` /
      `-997640091` / `-206935500`
    - Mira's House `--scenario=miras --case=play`: `-200101558` (`won=false reason=gaze time=94.9 believers=3`)
    - Broken Lanterns `--scenario=lanterns --case=none --seed=1`: `424350965`
  - Behaviour outcomes:
    - Vigil Flame `--scenario=flame --case=none --seed=1`: `won=false reason=gaze`; and, if Task 1 Step 1 finds it repeatable,
      `--scenario=flame --case=play --seed=1` exactly as recorded there (plan decision 204).
    - Feast `--scenario=feast --case=play --seed=1`: won festival.
  - **M2's 24 scenario references:** `bash .superpowers/sdd/2026-10-10-kak-v011-m5-reckoning/refs24.sh tax harvest lamb prayers`
    prints `OK` on all 24 lines (six at a time; fixed-fps headless runs are deterministic under load). The Tax Collector's six
    prove the Assassinate hooks; First Prayers' six prove `BelieversObjective` and Mira's hook; Spoiled Harvest's six prove
    `RazeDirector.hud_line()`. Never "fix" a mismatch by editing the table: report it.
  - **M3's 18 scenario references** (the Scenario loop for `ringers`, `panic` and `informer`, compared line by line; The
    Informer's six prove the Assassinate hooks too):

    | Scenario | `none` seeds 1 / 2 / 3 | `play` seeds 1 / 2 / 3 |
    |---|---|---|
    | ringers | `-275717420` / `-138070945` / `-370827666`, lost `bell` | `153399206` won 232.9 / `-667456881` won 176.3 / `-195878434` lost 173.3 |
    | panic | `-42444191` / `-831702796` / `49852883`, lost `market_closed` at 300.0 | `-102624718` won 220.0 / `-214853765` won 212.6 / `-575287130` won 195.6 |
    | informer | `-466238773` / `-645533123` / `-807294926`, lost `names` at 305.0 | `-597754669` won 200.2 / `-239928876` won 191.3 / `-328944037` won 191.1 |

  - **M4's 18 scenario references** (the Scenario loop for `bread`, `prisoner` and `hunt`, compared line by line; The Crown's
    Bread's six prove `RazeDirector.hud_line()` too). The controller fills this table at M4's landing:

    | Scenario | `none` seeds 1 / 2 / 3 | `play` seeds 1 / 2 / 3 |
    |---|---|---|
    | bread | `-707320795` / `644216709` / `-462416169`, lost `fed` at 300.0 | `-276094738` won 201.5 / `-59287158` won 234.5 / `-807789484` won 197.4 |
    | prisoner | `-375909400` / `-681839640` / `-196957329`, lost at 120.0 | `-731703837` won 203.0 / `-553130710` won 199.2 / `-934259560` won 181.9 |
    | hunt | `-597541405` / `-791635430` / `-892028599`, lost `cellar` | `-963589173` won 193.5 / `-868570277` won 183.2 / `-867462749` won 193.5 |

  - **M5's new references:** each mission task records its scenario's `none` and `play` checksums and result lines for seeds 1-3
    in its commit body. From the next task on they must not move: each later task runs the Scenario loop for every M5 scenario
    already recorded and compares line by line.
- **Text and drawn shapes only:** no PixelLab, no new image assets, no new fonts. The Lantern Knights wear Broken Lanterns' gold
  tabard (corps `KNIGHT`); the bishop, the preacher and the acolytes are clergy as they are; the garrison's armed men, the
  sermon's sentries, the relic's escorts and wardens are made `CitizenProfile.Role.WATCHMAN` (the watch cloak and lantern). The
  relic cart is its carter, tagged; no cart is drawn. Every other stand-in is an existing building or person named by a map tag.
- **Objective clarity** (M3's controller ruling 7): every moving target has a tag with an edge arrow; each `camera_at` keeps
  every key target, or its edge arrow, out of the left HUD stack's dead zone (the kit's `clear_of_stack()`, checked in each
  mission's tests and again in Task 8's photos); results titles use each mission's own reason keys in
  `ResultsScreen.ACT_TITLES`. Pip's tag reads "PIP - DO NOT KILL" from the start.
- **Colours** (mission spec §0): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's
  charges steel blue `8fb8e8`, not yet grey `9a948a`, clear green `7fc46a`. The Bishop's Knights are red, not steel blue.
- **The campaign and the existing missions:** the `[campaign]` save and flow stay as they are. Every M1-M4 mission plays exactly
  as before: every new var and hook defaults to today's behaviour. The Procession keeps its director, rules and stretch.
- **MissionBook's own missions** do not change. The four new ones are added in `tier_missions()`, never in `all()`.
- **Own people, held on duty** (M2-M4 lessons): every person a director uses is its own -- lay citizens appointed through
  `_eligible()` / `_lay_near()` / `_citizen_near()` / `_house_near()` (so no wisher, wish target or wish building is ever taken),
  and The Bishop's Knights added by `Crowd.add_soldier()`; no town soldier is ever borrowed. Everyone whose loss would change the
  night is put on duty at his place from setup (`Person.go_duty()`); people waiting for their time wait indoors
  (`_take_inside()`), on duty, untouchable.
- **The evacuation rule** (M3 final review, M4's rulings): each look, every M5 director runs
  `MissionDirector._keep_from_flight(p, evacuating)` over all its held people out of doors (`evacuating` from
  `_evacuation_began()`, true once), and `_recall_to(p, at)` is the one recall rule. Anyone the director brings out of a building
  after the evacuation may have begun is passed through `_keep_from_flight(p, true)` before he is given his duty (the evacuation
  sends the calm indoors running too; M4's head). Each mission has an **evacuate-mid-mission test** (`Kit.evacuate()` once the
  night is running): one held person recovering and one whispered when it begins, both at their places afterwards.
- **Relays:** The Sermon and The Relic Run set `TempleReport.skip` on every report they start, passing over anyone fleeing
  (`FLEE`) or reserved. Mira's House, The Vigil Flame and Broken Lanterns relay as before.
- **No hidden losses:** a stray kill or a stray power never makes a night silently unwinnable: it is counted with a plain loss
  reason (The Sermon's "THE FLOCK IS SCATTERED"), or the person's tag warns from the start (PIP - DO NOT KILL), or the place
  cannot fall (the god's house, the refuges ahead). A person leaving the town resolves at once.
- **Hit-stop:** scenarios that cast Smite or Heaven Splitter turn it off (`Impact.hitstop_enabled = false`): `bishop` and
  `armoury` join M4's list.
- **Quiet places:** a refuge, the god's house and the drop-off are chosen by rule (`_house_reached()` / `_open_door()`); if a
  photo or a gate shows a key door in a busy lane, the next nearest dwelling is used (the spec's costs), never a new rule.
- **TownLayout:** new reads only inside `src/game/mission/` (M3's controller ruling). The pyre wish finds the Temple by its role.
- **Style:**
  - Tabs. Static types. Match the neighbouring code.
  - A `##` doc comment on every new const, var and func, in full sentences, in the file's own voice, tagged "v0.11 M5".
  - Never name a member `seed` or `script`.
  - **Freed bodies:** a citizen's body is freed after its death fade, and an escaped one at once (`Crowd.escape()`). Every Person
    that may be freed is held or iterated as a `Variant` (or in an untyped `Array`) and guarded with `MissionDirector._alive()` /
    `is_instance_valid()` before any cast or member access.
- **Test style:**
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - M5's tests share M3's world kit, `const Kit := preload("res://tests/test_tier2_groundwork.gd")` (with M4's
    `Kit.evacuate()`). **Headless tests never think people:** nobody walks, a whisper never wears off and a confusion never
    lifts on its own, and `Person.tick()` (which wears `_shaken_left` down) never runs. Place people with `Kit.arrive()`; check
    anchors and minds, not arrival; end a confusion with `p._come_to()` and a whisper with `p._wake()` by hand; set
    `p._shaken_left = 0.0` by hand to show a hold has lapsed. ctx is null: no FX; a power is simulated by its effect
    (`Structure.damage()` / `destroy()` for a blow, `crowd.fires.ignite()` for an Ember, `crowd._field.kill()` or `Kit.free_body()`
    for a kill, `Person.whisper()` / `confuse()` / `panic()` for the minds).
- **Commits:** one per task, staging each new script's `.uid` too. End every message with the line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Spec sync** (M3's ruling): each mission task ends by syncing its section of the mission spec to its tuned numbers and words
  (the `Numbers` line, the timeline table, the clear's sum, the hint lines if they changed), in the same commit. The Armoury's
  sync also rewrites §2's barred text to the controller's staged ruling.
- **Controller's gates at landing:**
  - the Reference check, old and new (M3's 18, M4's 18 and M5's 24 included);
  - the full suite (in halves if need be), and FLOW 113/0 alone;
  - the four scenario gates of Task 7's Step 8;
  - a bench of The Bishop's board version (`--mission=bishop --board --bench`: the Temple's fire, up to 18 added Knights)
    against The Procession's, on a quiet machine.

## Review Focus

These are the cross-task risks: no single task's tests see them all.

1. **A shared class left alone must play exactly as before.**
   - The situation: Task 1 threads two hooks through `AssassinateDirector._begin()` / `_send_guards()` / `_release_guards()`,
     gives `BelieversObjective` and `FlameObjective` constructor arguments and a director read, adds `TempleReport.skip`, a
     `RazeObjective` read; Task 6 gives `PressedWish` and `MercyWish` parameters and grows the pool to sixteen.
   - Expected: The Tax Collector's, The Informer's, First Prayers', Spoiled Harvest's and The Crown's Bread's references, Mira's
     House, Broken Lanterns and The Vigil Flame exact; Free the pressed man and Lead my brother out as before; Tier 1-3 nights draw
     exactly what they drew (`pool_for()` filters before the shuffle).
   - Pinned by: Task 1 `_guard_hooks`, `_believers`, `_flame`, `_skip`, `_raze_line`; Task 6 `_draws`, `_pressed_kept`,
     `_brother_kept`; every task's Reference check.
2. **The town takes the crowd.**
   - The situation: City Emergency's rally and regroup, or the evacuation, while Knights stand, the bishop waits in a refuge or
     walks the square, armed men stand and a reserve waits in the armoury, listeners wait at their sources or stand rapt,
     Believers stand by the door, sentries and wardens watch, the cart walks with Pip aboard, Pip carries the relic.
   - Expected: everyone holds (on duty, or inside) until the god moves him; no Knight is rallied; a Believer is never carried out
     of the count; Pip never leaves the town by the evacuation.
   - Pinned by: each mission's `_hold` and `_evacuate`.
3. **The chain cannot be skipped.**
   - The situation: a player works ahead -- whispers a waiting wave to the god's house at 0:10, picks the lock and swaps at the
     first halt, fells the next barracks before its horn, burns the next refuge before the bishop is in it.
   - Expected: a waiting wave is held deaf until it walks in (plan decision 183); the swap happens only at the second halt (192);
     a barracks felled early counts at its horn, and the next horn still comes on the chain (177); a refuge ahead is stone (128).
   - Pinned by: Task 4 `_setup` (deaf at the source), Task 5 `_no_first_swap`, Task 3 `_ahead`, Task 2 `_stone`.
4. **A body freed mid-night, or a person gone from the town.**
   - The situation: a Knight, a relief, an armed man, a reinforcement, a listener, the preacher, an acolyte, a sentry, a warden,
     an escort, the carter or the bishop dies and fades; Pip escapes the town.
   - Expected: `tags()`, `hint_phase()`, `report()` and the objectives never touch a freed Person; Pip gone loses at once ("pip").
   - Pinned by: each mission's `_freed`; Task 5 `_pip`.
5. **A wish's people or buildings taken by the mission.**
   - The situation: wishes are heard before the director's setup; the watchtower wish may set aside the Main Gate's east tower;
     the moneylender's wish may set aside a refuge or the god's house; the heretic's march takes two free soldiers.
   - Expected: no wisher or wish target becomes the bishop, a listener, the preacher, an acolyte, a sentry, a warden, an escort,
     the carter, Pip or an armed man; no wish's building becomes a refuge, the god's house, the drop-off or a barracks (the west
     tower is used instead); no Knight is a wish's soldier.
   - Pinned by: Task 7 `_reserved`; Task 3 `_tower_reserved`.
6. **The town's own responders and a stray power.**
   - The situation: the fire brigade turns out to a burning refuge or barracks; the engineers look for a mending job; a stray
     Heaven Splitter falls on the god's house; the armoury falls with its reserve inside.
   - Expected: the engineers never take a refuge or a target (`hands_off`); the brigade fights fires as it always does (the gate
     measures it); the god's house only shakes and never burns; a fallen armoury spends its reserve (they come out and go home),
     so no armed man waits for ever inside rubble.
   - Pinned by: Task 2 `_setup`, Task 3 `_reserve`, Task 4 `_house`; the four gates.

## Plan decisions

The mission spec's Decisions 121-168 are this plan's decisions, with the controller's rulings (Decision 137 replaced). These
settle how the code meets them (numbered on from the spec's):

169. **Names:** `BishopDirector` (inner `Post`), `ArmouryDirector` (inner `Armed`), `SermonDirector` (inner `Listener`,
     `Sentry`), `RelicRunDirector` (inner `Warden`); the ids `MissionBook.BISHOP` / `ARMOURY` / `SERMON` / `RELIC_RUN`; the
     scenarios `--scenario=bishop|armoury|sermon|relic --case=none|play [--seed=N] [--board]`; the wish ids `heretic` and
     `family_out`; the tests `test_tier4_groundwork.gd`, `test_bishop.gd`, `test_armoury.gd`, `test_sermon.gd`,
     `test_relic_run.gd`, `test_tier4_wishes.gd`, `test_tier4_board.gd`, all on M3's kit (no new kit).
     Two of the spec's names are renamed, as GDScript refuses a constant a parent class declares: The Sermon's HEAR is
     `SermonDirector.VOICE` (`MirasHouseDirector` already has a `HEAR`), and The Relic Run's camera is
     `RelicRunDirector.CART_CAMERA` (`VigilFlameDirector` already has a `CAMERA_AT`).
170. **The Assassinate hooks:** `_appoint_guards(q, taken) -> Array[Person]` (default `_free_soldiers(hide_door, q.guard_count,
     taken)`) and `_tends(p) -> bool` (default `p.corps == Person.Corps.NONE and p.mind in GUARD_MINDS`), replacing the old
     inline code line for line.
171. **The Bishop rides the base's states:** he stays `State.WAITING` through the Citadel, his refuges and his flights, so the
     base's `_indoors()`, smoke-out and alarm stay idle (`smoke_out` false); in the square he is `WALKING` (his `leg` past his
     stops, so `_leg_goal()` is the Citadel's gate) and the base walks him, alarms him (`FLEEING`, no hideout), rings him
     (`_send_guards()` with `guard_r` RING_R) and loses at the gate (`_reach_safe()`). `BishopDirector` overrides `_set_out()`
     (into his house), `_send_guards()` (the base's only in the square), `_alarm()` (full pace when he runs) and the banners;
     its `step()` is the base's, then its refuge rules.
172. **On guard by the refuge, not the door:** a Knight is on guard within GUARD_REACH of the refuge's footprint
     (`Structure.distance_to()`, The Crown's Bread's rule). The spec's "within 2.5 of the refuge's door" would leave the escort,
     posted 2.7 along the face from the door, never on guard.
173. **The bishop waits on duty, inside** (The Informer's lodging rule), so the evacuation passes him by. Knights need no fear
     hold: `Person.panic()` returns at once for a soldier, and `whisper()` / `confuse()` refuse one.
174. **His flight is a timeline event** added when he is driven out ("The bishop reaches the chapter house", CHAIN on), whose
     callback is his arrival: the strip counts down to it, and its banner is his arrival's.
175. **The Bishop's policy Dooms him in the square before it Smites him** (the spec's step 1 Smites first): `Rules.cast_made`
     fires as a Smite is cast, so his alarm sends him running before its strike lands (`SmiteFx.T_STRIKE`), and a running bishop
     slips `KILL_R`. Silent Doom is quiet: no alarm.
176. **Knights going home** walk to the Citadel's gate and are taken inside there; "two more come out with him" is read
     literally: with fewer than two living Temple Knights, two more come out of its door.
177. **The Armoury's stages** (the controller's ruling replacing Decision 137): `_spoilable()` is "mustering"; before its horn a
     target takes blows but its fire is put out and its fall is judged only at its horn (razed at once then); while an armed man
     stands guard the target is sealed (`seal()` each look, `unseal()` once none is on guard), before or after its horn.
178. **Armed men are held** on guard: `_shaken_left` and `fearless_left` renewed to ARMED_HOLD each look (plan decision 94's
     hold), and set back on duty at their post every look, so Discord holds one for a look at most. "On guard" counts a confused
     man (alive, out of doors, within GUARD_REACH, not panicked, fleeing, sheltering or whispered).
179. **The reinforcement clock** restarts at each horn (the ruling: "the horn ... starts the reinforcement clock") at
     `REINFORCE[minute]` (40 / 40 / 30 / 20 / 12 by the clock's minute), stops while nothing musters, and sends each man to the
     first mustering target not razed, on posts in a second row (`_post()` k >= 4) within GUARD_REACH.
180. **The reserve** waits inside the armoury, on duty. Reliefs and reinforcements come from it, out of the armoury's door. The
     armoury felled or razed spends it (each comes out and goes home). A reinforcement still running when his target is razed
     walks back to the armoury's door and goes in again (back in the reserve).
181. **Posts:** the barracks' along the face the nearest town gate's street reaches (The Crown's Bread's `_face()`); the gate
     barracks' on its town side (its -y face), as The Crown's Bread's bridge crew stands at its town end.
182. **`RazeDirector.hud_line()`** ("" by default), read first by `RazeObjective.hud_text()`, carries "armed men every 30 s"
     in the main row ("Raze the garrison 1 / 3, armed men every 30 s") while a target musters and the reserve lasts. The spec's
     separate row would need a new objective class, which §7 rules out. Spoiled Harvest's and The Crown's Bread's twelve
     references prove the default.
183. **The Sermon's waiting waves are held deaf and fearless at their sources** (on duty, `_shaken_left` and `fearless_left`
     renewed each look) until their wave walks in: the spec's §3 has them wait on duty at their sources, and §0 wants waiting
     people untouchable; deaf keeps their diamonds and NEXT WAVE readable while nothing can be done with a wave before its time.
184. **The god's house only shakes tonight** (a damage filter, cleared at teardown), and any fire on it is put out: Mira's base
     flushes everyone inside and bars the door for good when its house falls, which would make the night silently unwinnable.
185. **Preaching and rapt:** the preacher preaches while alive, out of doors, on duty and within PREACH_REACH (1.0) of the pulpit;
     a listener is rapt while his wave is called, he is unturned and out of doors, and within VOICE (the spec's HEAR) of a preaching
     preacher. Held
     as plan decision 183 (HOLD 1.0, renewed each look); a silent preacher lets the hold lapse.
186. **"THEY HEAR ONLY HIM"** is the banner on `Rules.cast_refused` "shaken" for a whisper while any listener is rapt.
187. **The Believers are held by The Sermon's `_exit()` override** (super, then `_keep_from_flight(p, true)` and on duty to his
     place on the ring by the door). Mira's own rule in `_exit()` -- a Faithful who sees a Believer come out runs to the Temple --
     stays.
188. **A sentry is on guard while he sees the door** (`_sees(sentry, door, SIGHT)`): alive, out of doors, not held by the god,
     within SIGHT of it.
189. **The acolytes see the preacher die** only once the cast's other victims have fallen (`Crowd._doomed` empty); each acolyte
     not held who sees the fall within SIGHT runs to the Temple.
190. **`TempleReport.skip`** is set by an override of `_report()` in The Sermon and The Relic Run (super, then `skip` on each
     report it started); `MissionDirector._report()` is unchanged.
191. **The Relic Run replaces the base's `_begin()` and `step()`** (the order: the cart and its halts, the seen deaths, the
     reports, the swap, Pip, the held people, the wardens, phase 2, the bell). It keeps `_phase2_*`, the Searchlight, `FlameGaze`,
     the reports, `_pace_bearer()`, `_listen()`, `_add_events()` and `teardown()`; it does not reuse `_swap()` (its seer runs to the
     Temple and its banner names the flame) nor `_flame_home()` (its banner): `_take_relic()` and `_relic_home()` do their work.
192. **The swap happens only at the second (last) halt.** Boarding: at either halt, Pip within CART_REACH of the halted cart and
     the cart unwatched BOARD seconds in a row. The lock: picked while the cart rolls with him aboard, or at a halt while unwatched.
     So the spec's two steps and its one-halt fallback both stand, and the drop-off (some 8 units from the first halt) cannot be
     reached from it.
193. **Watched** is `faithful_seeing(cart, WATCH)`: the escorts and wardens are Faithful, the carter is not.
194. **The halt rides on `VigilRoute.busy`:** busy for the carter while a halt runs or he stands at the next checkpoint's point,
     so the route neither re-aims him nor moves past it; `VigilRoute` is unchanged.
195. **A seen death in The Relic Run sends a report:** a Faithful not held within `Crowd.DOOM_WITNESS` of a fall runs to the
     Temple, judged once the cast's victims have fallen (the spec's "a report runs only from a seen death near a Faithful's eyes";
     The Vigil Flame's base sends none).
196. **A stalled cart** (its three dead): RELIEF_AFTER later the resident nearest the Temple's door and two lay escorts walk on
     duty to the cart; at it, a new `VigilRoute` takes the rest of the route from the leg the cart stood on (`_leg_base`, so the
     halts keep their legs).
197. **The bell's warning** (spec §3, §4) is a `bell` hint phase in both Gaze missions, shown while the bell is called or climbing.
198. **`RelicRunDirector.halt_in()`** estimates the seconds to the next halt (the route still to walk at the carter's duty pace;
     before the set-out, its time too), for the policy only.
199. **The Relic Run's policy step 5 reuses `_flame_carry()`** (The Vigil Flame's carry: a Wisp decoy, a whisper out of a beam,
     Discord at the Temple in the last seconds), wrapped to report whether it cast.
200. **The pyre wish's parameters:** `"goal"` ("barracks" default, "temple"), `"guard_label"` and `"son_label"` (the spec names two;
     the son's HERETIC tag needs the third). The Temple's door is found by its role (`PressedWish.temple_door()`). `MercyWish`'s
     `"count"` above 1 chooses as `FamilyWish._household()` and tracks escapes by instance id (an escaped body is freed at once).
201. **Hit-stop:** `_run()`'s line becomes `if scenario in ["panic", "bread", "hunt", "bishop", "armoury"]:`.
202. **FLOW 113:** M4's Omen-locked step also opens Reckoning's tab and checks its five cards behind "Clear 3 Wrath missions"
     (the same step); a new `_flow_tier4()` (Reckoning opened as a fixture) plays The Armoury from the board, razes it by its
     public state (`_raze()` on each target), ascends, and reads "Reckoning 1 / 3 cleared: 2 more open Ascendance".
203. **Waits Task 7 pins:** the first arrival, the first horn and the set-out exactly at their tuned values; a Knight's relief; an
     armed man's return and relief; the slowest reinforcement; a reading; a sentry's return and relief; the longest halt and the
     count; a warden's return and relief; the flight, the horns' and the waves' chains.
204. **The Vigil Flame's play line** (`--scenario=flame --case=play --seed=1`) is run twice at the base in Task 1; if both
     checksums match, it joins the Reference check (the base's `step()` and `FlameObjective` are touched).
205. **The Bishop's hint phases cover every state** (waiting, guarded, open, burning, square, running); the mission's own line
     shows once he is dead or gone, as The Crown's Bread's does between items.
206. **The Armoury's barred words follow the ruling:** the `barred` phase reads "Not mustering yet (grey): fire goes out, and a fall
     counts when its horn sounds. Kill its night watch (red) shortly before."; a target not mustering is tagged "BARRACKS -
     MUSTERS BY 1:50", or "BARRACKS - DOWN, COUNTS AT 1:50" once it has fallen.

### Where the spec does not fit the code

- **§7 "RelicRunDirector ... reuses `_swap()`":** `_swap()` reports any Faithful within `DOOM_WITNESS` of Wren and banners "THE
  FLAME IS TAKEN"; the spec's theft sends no report. `_take_relic()` does the swap's work (decision 191).
- **§7 "`RazeDirector`: unchanged" and §2's HUD row "Armed men every 30 s":** objective rows come only from objectives; the rate
  rides in the main row through a new `hud_line()` hook (decision 182).
- **§2 / Decision 137 (seals):** replaced by the controller's staged ruling; the `barred` hint and tags are reworded (decision
  206) and §2 is rewritten at the spec sync.
- **§1 "On guard: ... within 2.5 of the refuge's door":** measured from the refuge (decision 172).
- **§1 policy step 1 "Smite him":** Doom first (decision 175).
- **§3 "wait on duty at their source" vs §0 "people waiting for their time wait indoors, untouchable":** held deaf at the source
  (decision 183).
- **§3 / §4 HUD "Gaze 30%":** `GazeObjective` reads "Halcyon's Gaze 30%" (unchanged shared code).
- **§4 "Report runners and the Temple, as The Vigil Flame's":** The Vigil Flame draws no runner; Mira's House's TO THE TEMPLE and
  TEMPLE are used.
- **§4 timeline "~0:50 / ~1:55 the cart halts":** the halts are not on the strip (their times move with the cart); their banners
  come at the real halts and the CHECKPOINT tag points the way.
- **§4 "Pip whispered to within 1.0 of the halted cart":** any Pip within reach of the halted cart counts (decision 192); he was
  brought there by the god.
- **§6 "`PressedWish` with `"goal"` ... `"guard_label"`":** a third parameter for the son's tag (decision 200).
- **§7 the override lists:** The Sermon also overrides `_begin()` (its numbers, as First Prayers), `_door_of()`, `_exit()`,
  `_on_killed()`, `_report()` and `lost_reason()`; The Relic Run also `step()`, `_on_killed()`, `_report()`; it does not need
  `wren_lost()` (the base's rule already covers a Pip dead or gone).
- **§0 "every M5 director runs `_keep_from_flight()` ...":** The Bishop's Knights are soldiers, whom the evacuation never moves;
  its rule covers the bishop alone.

---

## File Structure

- **Created:**
  - `src/game/mission/bishop_director.gd` (Task 2), `armoury_director.gd` (Task 3), `sermon_director.gd` (Task 4),
    `relic_run_director.gd` (Task 5).
  - Tests: `tests/test_tier4_groundwork.gd` (1), `test_bishop.gd` (2), `test_armoury.gd` (3), `test_sermon.gd` (4),
    `test_relic_run.gd` (5), `test_tier4_wishes.gd` (6), `test_tier4_board.gd` (7).
- **Modified:**
  - Task 1: `src/game/mission/assassinate_director.gd`, `miras_house_director.gd`, `believers_objective.gd`,
    `vigil_flame_director.gd`, `flame_objective.gd`, `temple_report.gd`, `raze_director.gd`, `raze_objective.gd`,
    `mission_book.gd`.
  - Tasks 2-5: `mission_book.gd`, `mission_hints.gd`, `src/game/ui/results_screen.gd`, `tools/dev/behaviour_check.gd`, the
    mission spec's own section; `tests/test_mission_hints.gd`.
  - Task 6: `src/game/descend/pressed_wish.gd`, `mercy_wish.gd`, `wish_book.gd`; `tests/test_wishes.gd`, `test_wish_kinds.gd`,
    `test_tier2_wishes.gd`, `test_tier3_wishes.gd` (the pool's pinned contents only).
  - Task 7: `src/game/descend/tier_book.gd`, `src/game/game.gd` (FLOW, the `tiers` photo's save); `tests/test_tiers.gd`.
  - Task 8: `src/game/game.gd` (`--show`), `docs/KAK_Version_0.11_Summary.md`, `README.md`.
  - `tests/run_all.gd` in each task that adds a suite.

### Task 1: The groundwork

**Files:**
- Modify: `src/game/mission/assassinate_director.gd` (new `_appoint_guards()`, `_tends()`; `_begin()`, `_send_guards()`, `_release_guards()`)
- Modify: `src/game/mission/miras_house_director.gd` (new `lost_reason()`), `src/game/mission/believers_objective.gd`
- Modify: `src/game/mission/vigil_flame_director.gd` (new `hud_line()`), `src/game/mission/flame_objective.gd`
- Modify: `src/game/mission/temple_report.gd` (new `skip`, `_witness()`; `_judge()`)
- Modify: `src/game/mission/raze_director.gd` (new `hud_line()`), `src/game/mission/raze_objective.gd` (`hud_text()`)
- Modify: `src/game/mission/mission_book.gd` (four ids, new `_tier4()`)
- Create: `tests/test_tier4_groundwork.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: the kit (`Kit.world()`, `Kit.done()`); `TaxCollectorDirector`, `HarvestDirector`, `MirasHouseDirector`,
  `VigilFlameDirector` as they are.
- Produces:
  - `AssassinateDirector._appoint_guards(q: Quarry, taken: Array) -> Array[Person]`, `_tends(p: Person) -> bool`.
  - `MirasHouseDirector.lost_reason() -> String`; `BelieversObjective._init(text := "Believers", won := "believers", few := "few")`.
  - `VigilFlameDirector.hud_line() -> String`; `FlameObjective._init(text := "The flame", won := "flame", kept := "kept", lost := "wren")`.
  - `TempleReport.skip: Callable` (`func(p: Person) -> bool`).
  - `RazeDirector.hud_line() -> String`.
  - `MissionBook.BISHOP`, `ARMOURY`, `SERMON`, `RELIC_RUN`; `MissionBook._tier4(id: String, name: String, brief: PackedStringArray) -> MissionDef`.

- [ ] **Step 1: The Vigil Flame's play line at the base** (plan decision 204). Before any edit, run
  `--scenario=flame --case=play --seed=1` twice. Write both `checksum=` and `result` lines in the report. If the two checksums
  match, that line is a reference from here on (the Reference check runs it); if not, only `--case=none`'s outcome stays.

- [ ] **Step 2: Write the failing test.** Create `tests/test_tier4_groundwork.gd`:

```gdscript
extends RefCounted
## v0.11 M5 the groundwork for Tier 4's new missions, each shared change shown to keep today's path when left alone (review focus 1):
## Tier 4's frame; AssassinateDirector's guard hooks (_appoint_guards(), _tends()); MirasHouseDirector.lost_reason() and
## BelieversObjective's label and reasons; VigilFlameDirector.hud_line() and FlameObjective's label and reasons; TempleReport.skip;
## RazeDirector.hud_line() read by RazeObjective.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


## The Tax Collector with a spy on its guard hooks (v0.11 M5): each records what it was handed, then does the base's work.
class GuardSpy:
	extends TaxCollectorDirector
	var appointed: Array = []
	var tended := 0

	func _appoint_guards(q: Quarry, taken: Array) -> Array[Person]:
		appointed.append([q.index, taken.size()])
		return super(q, taken)

	func _tends(p: Person) -> bool:
		tended += 1
		return super(p)


## The Tax Collector whose guards no one tends (v0.11 M5): _tends() says no, so none is ever sent to a place.
class Untended:
	extends TaxCollectorDirector

	func _tends(_p: Person) -> bool:
		return false


## Mira's House with a loss of its own (v0.11 M5): lost_reason() gives `why`.
class Lost:
	extends MirasHouseDirector
	var why := ""

	func lost_reason() -> String:
		return why


## The Vigil Flame with a HUD line of its own (v0.11 M5).
class Lined:
	extends VigilFlameDirector
	var line := ""

	func hud_line() -> String:
		return line


## Spoiled Harvest with a HUD line of its own (v0.11 M5).
class RazeLined:
	extends HarvestDirector
	var line := ""

	func hud_line() -> String:
		return line


static func run(t) -> void:
	_frame(t)
	_guard_hooks(t)
	_believers(t)
	_flame(t)
	_skip(t)
	_raze_line(t)


static func _frame(t) -> void:
	var m := MissionBook._tier4("x", "X", PackedStringArray(["a", "b"]))
	t.check(m.tier == 4 and m.slots == 5 and m.dp_capacity == 13 and is_equal_approx(m.clock, 390.0) and m.profile == ""
		and m.tier_floor == 4 and not m.chooses_difficulty()
		and m.response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant" and m.intro_banner == "X"
		and m.bonuses().is_empty() and m.pool.is_empty() and is_equal_approx(m.stretch, 1.0),
		"a Tier 4 mission's numbers: 6:30, 5 / 13, a God-Resistant town whatever is chosen, no bonuses")
	t.check(MissionBook.BISHOP == "bishop" and MissionBook.ARMOURY == "armoury" and MissionBook.SERMON == "sermon"
		and MissionBook.RELIC_RUN == "relic_run", "Reckoning's four new ids")


## Each target's guards as indices into the town's soldiers (v0.11 M5 tests).
static func _guard_ix(s: Dictionary) -> Array:
	var out := []
	for q: AssassinateDirector.Quarry in (s.d as AssassinateDirector).quarries:
		var ix := []
		for v: Variant in q.guards:
			ix.append((s.crowd as Crowd).soldiers.find(v))
		out.append(ix)
	return out


static func _guard_hooks(t) -> void:
	var plain := Kit.world(MissionBook.tax_collector())
	var want := _guard_ix(plain)
	Kit.done(plain)
	var s := Kit.world(MissionBook.tax_collector(), GuardSpy.new())
	var d: GuardSpy = s.d
	var calls := []
	var taken := 0
	for q: AssassinateDirector.Quarry in d.quarries:
		calls.append([q.index, taken])
		taken += q.guards.size()
	t.check(d.appointed == calls and _guard_ix(s) == want and taken > 0,
		"_appoint_guards() is handed each target and the guards taken before him, and appoints the soldiers the old code did (%s)" % [d.appointed])
	var sent := false
	for q: AssassinateDirector.Quarry in d.quarries:
		for v: Variant in q.guards:
			sent = sent or (v as Person).anchor.distance_to((v as Person).post) > 0.01
	t.check(d.tended > 0 and sent, "_tends() is asked for each guard, and by default they are sent to their places")
	Kit.done(s)
	var u := Kit.world(MissionBook.tax_collector(), Untended.new())
	Kit.run_for(u, 1.0)
	var kept := true
	for q: AssassinateDirector.Quarry in (u.d as AssassinateDirector).quarries:
		for v: Variant in q.guards:
			kept = kept and (v as Person).anchor.distance_to((v as Person).post) < 0.01
	t.check(kept, "a guard _tends() refuses is never sent (The Bishop's Knights are tended by its own rule)")
	Kit.done(u)


static func _believers(t) -> void:
	var s := Kit.world(MissionBook.miras_house())
	var o := BelieversObjective.new()
	t.check(o.label == "Believers" and o.reason == "believers" and o.hud_text(s.rules) == "Believers 0 / 4"
		and o.check(s.rules) == Objective.Status.PENDING and (s.d as MirasHouseDirector).lost_reason() == "",
		"BelieversObjective by default: Mira's House's label, reason and line; no loss of the director's")
	(s.rules as Rules).time_left = 0.0
	t.check(o.check(s.rules) == Objective.Status.FAILED and o.reason == "few", "dawn with too few: \"few\", as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.miras_house(), Lost.new())
	var d: Lost = l.d
	var c := BelieversObjective.new("Turn the crowd", "sermon", "sermon_over")
	t.check(c.label == "Turn the crowd" and c.reason == "sermon" and c.hud_text(l.rules) == "Turn the crowd 0 / 4"
		and c.check(l.rules) == Objective.Status.PENDING, "given its label and reasons")
	d.why = "flock"
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "flock", "the director's own loss fails it at once, with its reason")
	d.why = ""
	(l.rules as Rules).time_left = 0.0
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "sermon_over", "dawn with too few: its own reason")
	Kit.done(l)


static func _flame(t) -> void:
	var s := Kit.world(MissionBook.vigil_flame())
	var d: VigilFlameDirector = s.d
	var o := FlameObjective.new()
	t.check(o.label == "The flame" and o.reason == "flame" and d.hud_line() == "" and o.hud_text(s.rules) == "The flame: in its lantern",
		"FlameObjective by default: The Vigil Flame's label, reason and line")
	d.kept = true
	t.check(o.check(s.rules) == Objective.Status.FAILED and o.reason == "kept", "kept: \"kept\", as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.vigil_flame(), Lined.new())
	var ld: Lined = l.d
	var c := FlameObjective.new("The relic", "relic", "relic_kept", "pip")
	ld.line = "The relic: in its cart"
	t.check(c.label == "The relic" and c.reason == "relic" and c.hud_text(l.rules) == "The relic: in its cart",
		"the director's HUD line in place of its own")
	ld.no_wren = true
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "pip", "the boy lost: its own reason")
	ld.no_wren = false
	ld.kept = true
	t.check(c.check(l.rules) == Objective.Status.FAILED and c.reason == "relic_kept", "kept: its own reason")
	ld.kept = false
	ld.home = true
	t.check(c.check(l.rules) == Objective.Status.DONE and c.reason == "relic", "home: its own reason")
	Kit.done(l)


## Everyone but `keep` within `reach` of `at` moved well away (v0.11 M5 tests; test_temple_report's rule).
static func _clear_round(crowd: Crowd, at: Vector2, reach: float, keep: Array) -> void:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and not keep.has(p) and p.ground_pos.distance_to(at) <= reach:
				p.ground_pos = at + (p.ground_pos - at).normalized() * (reach + 6.0) if p.ground_pos != at \
					else at + Vector2(reach + 6.0, 0.0)


## A report carried by `c` whose carrier is killed with `near` fleeing 0.8 from him and `far` calm 1.5 from him (v0.11 M5 tests);
## `skip` set on it when given. The report, judged.
static func _relay(crowd: Crowd, c: Person, near: Person, far: Person, skip: Callable) -> TempleReport:
	var r := TempleReport.new(c, Vector2(0.8, -5.0))
	if skip.is_valid():
		r.skip = skip
	_clear_round(crowd, c.ground_pos, Crowd.DOOM_WITNESS + 1.0, [c])
	near.ground_pos = c.ground_pos + Vector2(0.8, 0.0)
	near.mind = Person.Mind.FLEE
	if far != null:
		far.ground_pos = c.ground_pos + Vector2(1.5, 0.0)
	crowd._field.kill(c, &"doom")
	r.on_killed(c)
	r.step(DT, crowd)
	return r


static func _skip(t) -> void:
	var s := Kit.world(MissionBook.miras_house(), MissionDirector.new())
	var crowd: Crowd = s.crowd
	var out: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside:
			out.append(p)
	var r := _relay(crowd, out[3], out[7], out[11], Callable())
	t.check(not r.skip.is_valid() and r.carrier == out[7] and r.relays == 1,
		"with no skip the nearest witness carries the report on, fleeing or not, as before")
	var fleeing := func(p: Person) -> bool: return p.mind == Person.Mind.FLEE
	var r2 := _relay(crowd, out[15], out[19], out[23], fleeing)
	t.check(r2.carrier == out[23] and r2.is_open(), "with skip the relay passes over the fleeing witness to the next")
	var r3 := _relay(crowd, out[27], out[31], null, fleeing)
	t.check(r3.dead and not r3.is_open(), "only a skipped witness saw it: the report ends")
	Kit.done(s)


static func _raze_line(t) -> void:
	var s := Kit.world(MissionBook.spoiled_harvest())
	var o: Objective = (s.rules as Rules).objectives[0]
	t.check((s.d as RazeDirector).hud_line() == "" and o.hud_text(s.rules) == "Granaries spoiled 0 / 3",
		"RazeObjective by default: its label and count, as before")
	Kit.done(s)
	var l := Kit.world(MissionBook.spoiled_harvest(), RazeLined.new())
	(l.d as RazeLined).line = "Raze the garrison 0 / 3, armed men every 40 s"
	var lo: Objective = (l.rules as Rules).objectives[0]
	t.check(lo.hud_text(l.rules) == "Raze the garrison 0 / 3, armed men every 40 s", "the director's HUD line in place of it")
	Kit.done(l)
```

  - In `tests/run_all.gd`, append `"res://tests/test_tier4_groundwork.gd",` at the end of `SUITES`.

- [ ] **Step 3: Run the test to verify it fails.** Run Import, then Tests. Expected: parse errors (`_tier4`, `_appoint_guards`,
  `hud_line` on `VigilFlameDirector`, `skip`, BelieversObjective's arguments).

- [ ] **Step 4: The Assassinate type's guard hooks** (plan decision 170). In `src/game/mission/assassinate_director.gd`:
  - In `_begin()`, `q.guards = _free_soldiers(hide_door, q.guard_count, taken)` becomes `q.guards = _appoint_guards(q, taken)`.
  - After `_appointed()` add:

```gdscript
## Virtual (v0.11 M5): the guards who walk with `q`, none of `taken` (the guards already appointed): the q.guard_count free soldiers
## nearest the hideout's door by default; The Bishop's escort, Lantern Knights it adds.
func _appoint_guards(q: Quarry, taken: Array) -> Array[Person]:
	return _free_soldiers(hide_door, q.guard_count, taken)


## Virtual (v0.11 M5): this director sends guard `p` to his place and home now -- one of no corps in a mind of his own (GUARD_MINDS)
## by default; in any other, the rally, a fight, the god's hold, he is left to the town. The Bishop's are its Knights at their posts.
func _tends(p: Person) -> bool:
	return p.corps == Person.Corps.NONE and p.mind in GUARD_MINDS
```

  - In `_send_guards()`, `if p.corps != Person.Corps.NONE or not p.mind in GUARD_MINDS:` becomes `if not _tends(p):`, and its doc's
    "A guard reserved, of a corps, or in a mind not his own (GUARD_MINDS) is left be" becomes "A guard reserved, or one this
    director does not tend (_tends()), is left be".
  - In `_release_guards()`, `if p.corps == Person.Corps.NONE and p.mind in GUARD_MINDS and p.post != Vector2.INF:` becomes
    `if _tends(p) and p.post != Vector2.INF:`, and its doc's "unless the town has them (GUARD_MINDS)" becomes "unless this director
    does not tend them (_tends())".

- [ ] **Step 5: Mira's loss hook and the Believers' words.**
  - In `src/game/mission/miras_house_director.gd`, after `_house_label()` add:

```gdscript
## Virtual (v0.11 M5): why the night is lost now besides the Gaze and dawn ("" while it is not), as RazeDirector.lost_reason():
## The Sermon's "flock", too few left to turn. BelieversObjective fails with it.
func lost_reason() -> String:
	return ""
```

  - Replace `src/game/mission/believers_objective.gd` with:

```gdscript
class_name BelieversObjective
extends Objective
## Mira's House (v0.10): NEED Believers alive and out of the house win the night ("believers"); fewer at dawn lose it
## ("few"). Four, not the spec's starting five (Task 7: a scripted policy reached 3-7 Believers, most often 4).
## v0.11 M1 (no waiting, spec §7.3): won the moment the fourth Believer walks out, not at dawn.
## v0.11 M2: the number is the director's (MirasHouseDirector.need): NEED at Mira's House, three at First Prayers.
## v0.11 M5: its label and reasons are given (The Sermon's "Turn the crowd", "sermon", "sermon_over"), and it fails at once with the
## director's own loss (MirasHouseDirector.lost_reason(): The Sermon's "flock") when there is one.

const NEED := 4

## The reasons for a win, and for dawn with too few (v0.11 M5).
var _won := "believers"
var _few := "few"


func _init(text := "Believers", won := "believers", few := "few") -> void:
	label = text
	_won = won
	_few = few
	reason = won


func check(rules: Rules) -> Status:
	var d := rules.director as MirasHouseDirector
	if d == null:
		return Status.PENDING
	if d.believers_outside() >= d.need:
		reason = _won
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	if rules.time_left > 0.0:
		return Status.PENDING
	reason = _few
	return Status.FAILED


## "Believers 3 / 4"; v0.11 M5: "<label> 3 / 8".
func hud_text(rules: Rules) -> String:
	var d := rules.director as MirasHouseDirector
	return "%s %d / %d" % [label, d.believers_outside() if d != null else 0, d.need if d != null else NEED]
```

- [ ] **Step 6: The Vigil Flame's HUD hook and the flame's words.**
  - In `src/game/mission/vigil_flame_director.gd`, after `going_home()` add:

```gdscript
## Virtual (v0.11 M5): the HUD's line for the main objective in place of FlameObjective's own ("" keeps its own): The Relic Run's
## "The relic: Pip at the lock".
func hud_line() -> String:
	return ""
```

  - In `src/game/mission/flame_objective.gd`: the class doc gains the line `## v0.11 M5: its label and reasons are given (The Relic Run's "The relic", "relic", "relic_kept", "pip"), and the director's own HUD line (VigilFlameDirector.hud_line()) shows in place of its own when there is one.`;
    after the doc add the vars, and replace `_init()` and `check()`:

```gdscript
## The reasons for the win, for the flame (or relic) kept, and for the boy lost (v0.11 M5).
var _won := "flame"
var _kept := "kept"
var _lost := "wren"


func _init(text := "The flame", won := "flame", kept := "kept", lost := "wren") -> void:
	label = text
	_won = won
	_kept = kept
	_lost = lost
	reason = won


func check(rules: Rules) -> Status:
	var d := rules.director as VigilFlameDirector
	if d == null:
		return Status.PENDING
	if d.home:
		reason = _won
		return Status.DONE
	if d.kept:
		reason = _kept
		return Status.FAILED
	if d.wren_lost():
		reason = _lost
		return Status.FAILED
	return Status.PENDING
```

    and in `hud_text()`, after `var d := rules.director as VigilFlameDirector` insert:

```gdscript
	var line := d.hud_line() if d != null else ""
	if line != "":
		return line
```

- [ ] **Step 7: The relay's skip** (plan decision 190). In `src/game/mission/temple_report.gd`:
  - After `var relays := 0` add:

```gdscript
## func(p: Person) -> bool (v0.11 M5): a witness a relay passes over -- The Sermon's and The Relic Run's: one fleeing the town or
## reserved. Empty: any witness carries it on, as before.
var skip: Callable
```

  - In `_judge()`, `var witness := crowd.nearest_witness(at)` becomes
    `var witness := crowd.nearest_witness(at) if not skip.is_valid() else _witness(crowd, at)`, and after `_judge()` add:

```gdscript
## The nearest witness to `at` a relay may take (v0.11 M5): as Crowd.nearest_witness() finds one, passing over everyone `skip` names;
## null for none, and the report ends.
func _witness(crowd: Crowd, at: Vector2) -> Person:
	var best: Person = null
	var best_d := Crowd.DOOM_WITNESS
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside or bool(skip.call(p)):
				continue
			var d := p.ground_pos.distance_to(at)
			if d <= best_d:
				best = p
				best_d = d
	return best
```

- [ ] **Step 8: The Raze type's HUD hook** (plan decision 182).
  - In `src/game/mission/raze_director.gd`, after `lost_reason()` add:

```gdscript
## Virtual (v0.11 M5): the HUD's line for the main objective in place of RazeObjective's own ("" keeps its own): The Armoury's
## "Raze the garrison 1 / 3, armed men every 30 s" while a target musters.
func hud_line() -> String:
	return ""
```

  - In `src/game/mission/raze_objective.gd`, `hud_text()` becomes:

```gdscript
## "Granaries spoiled 1 / 3" (v0.11 M2); v0.11 M5: the director's own line (RazeDirector.hud_line()) in its place when it has one.
func hud_text(rules: Rules) -> String:
	var d := rules.director as RazeDirector
	var line := d.hud_line() if d != null else ""
	if line != "":
		return line
	return "%s %d / %d" % [label, d.razed_count() if d != null else 0, d.targets.size() if d != null else 0]
```

- [ ] **Step 9: Tier 4's frame.** In `src/game/mission/mission_book.gd`:
  - After the M4 ids add:

```gdscript
## The new Tier 4 missions (v0.11 M5, mission spec §1-§4), built by tier_missions() at Tier 4's numbers.
const BISHOP := "bishop"
const ARMOURY := "armoury"
const SERMON := "sermon"
const RELIC_RUN := "relic_run"
```

  - After `_tier3()` add:

```gdscript
## A Tier 4 (Reckoning) mission's frame (v0.11 M5, mission spec §0, Decision 121): a God-Resistant town -- tier_floor 4 and no profile,
## so a scripted run meets the board's town -- 5 slots and 13 DP, a 6:30 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier4(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 4
	m.brief = brief
	m.slots = 5
	m.dp_capacity = 13
	m.clock = 390.0
	m.tier_floor = 4
	m.intro_banner = name.to_upper()
	return m
```

- [ ] **Step 10: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 17.
  `test_temple_report`, `test_tax_collector`, `test_informer`, `test_first_prayers`, `test_vigil_flame` unchanged.

- [ ] **Step 11: The Reference check, and FLOW.** Run all of it (Global Constraints). Expected: every value unchanged; `refs24.sh`
  24 x OK (The Tax Collector's six prove the guard hooks, First Prayers' six the Believers', Spoiled Harvest's six the Raze line);
  M3's 18 (The Informer's six) and M4's 18 (The Crown's Bread's six) as in the tables; The Vigil Flame's line(s) as Step 1 found;
  FLOW 112/0, run alone.

- [ ] **Step 12: Commit.**

```bash
git add src/game/mission/assassinate_director.gd src/game/mission/miras_house_director.gd src/game/mission/believers_objective.gd src/game/mission/vigil_flame_director.gd src/game/mission/flame_objective.gd src/game/mission/temple_report.gd src/game/mission/raze_director.gd src/game/mission/raze_objective.gd src/game/mission/mission_book.gd tests/test_tier4_groundwork.gd tests/test_tier4_groundwork.gd.uid tests/run_all.gd
git commit -m "feat: Tier 4 groundwork -- guard hooks, the Believers' and the flame's words, a relay that skips, the Raze line (v0.11 M5)" -m "<counts; The Vigil Flame's play line twice at the base; the Reference check; FLOW 112/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The Bishop (Assassinate, reused)

**Files:**
- Create: `src/game/mission/bishop_director.gd`, `tests/test_bishop.gd`
- Modify: `src/game/mission/mission_book.gd` (new `bishop()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd` (`LINES`), `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `tools/dev/behaviour_check.gd` (usage, consts, `_run()`, new `_bishop()` / `_bishop_act()` / `_knight_clear()` / `_none_within()`)
- Modify: `tests/test_mission_hints.gd` (`SPEC`), `tests/run_all.gd`
- Modify: `docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md` (§1 synced, Step 10)

**Interfaces:**
- Consumes: Task 1's `_appoint_guards()`, `_tends()`, `_tier4()`, `BISHOP`; `AssassinateDirector`'s `Quarry`, `State`, `quarries`,
  `hide_door`, `safe_at`, `guard_r`, `smoke_out`, `safe_label`, `_house_reached()`, `_add_quarry()`, `_appoint_target()`,
  `_set_out()`, `_send_guards()`, `_alarm()`, `_tick()`, `_judge()`, `_burning()`, `out_at()`, `witnesses()`, `all_fallen()`,
  `any_safe()`, `report()`, `MARK_*`, `TICK`, `ARRIVE`; `Crowd.add_soldier()`, `Person.HEALTH_KNIGHT`; `EngineerManager.hands_off`;
  the kit.
- Produces:
  - `BishopDirector`: inner `Post` (`man`, `refuge`, `spot`, `escort`, `fallen`, `relief`, `done`); `REFUGE_SPOTS`,
    `CITADEL_GATE`, `ARRIVE_AT`, `CHAIN`, `STANDING`, `ESCORT`, `POST_GAP`, `GUARD_REACH`, `SMOTHER_AFTER`, `DRIVE_OUT`,
    `DRIVE_OUT_TEMPLE`, `RELIEF_AFTER`, `RELIEFS`, `RING_R`, `BISHOP_PACE`, `TAKEN_AT`, `CAMERA_AT`; `refuges`, `doors`, `posts`,
    `at_refuge`, `in_flight`, `arrive_at`, `driven`, `in_square`, `reliefs`; `current_refuge()`, `next_refuge()`, `arrive_in()`,
    `guards_at(i)`, `standing_at(i)`, `relief_walking()`, `drive_out_after(i)`, `_reach_refuge(i)`, `_drive_out(i)`.
  - `MissionBook.bishop() -> MissionDef`; the scenario `--scenario=bishop`; six references.

- [ ] **Step 1: Write the failing test.** Create `tests/test_bishop.gd`:

```gdscript
extends RefCounted
## v0.11 M5 The Bishop (mission spec §1, BishopDirector, AssassinateDirector reused): the bishop waits in the Citadel, goes to ground
## in his house at 0:45, and moves refuge to refuge indoors, unseen, only when driven out by fire; a refuge ahead is stone; Knights
## (added soldiers, corps KNIGHT) stand at each door and beat out a fire while one is on guard; his escort comes with him; reliefs from
## the Citadel; driven from the Temple he walks the square for the Citadel's gate, ringed by its Knights. His death wins; the gate,
## leaving the town or the Knights at 5:00 lose. The rally and the evacuation pass the Knights and the bishop by (review focus 2);
## freed bodies are borne (review focus 4); the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_ground(t)
	_stone(t)
	_smother(t)
	_flight(t)
	_relief(t)
	_square(t)
	_ends(t)
	_evacuate(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.bishop())


## Every Knight of refuge `i` out of doors killed and freed (v0.11 M5 tests).
static func _clear(s: Dictionary, d: BishopDirector, i: int) -> void:
	for p: BishopDirector.Post in d.posts:
		if not p.done and p.refuge == i and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)


## The bishop in refuge `i` now (v0.11 M5 tests): his time brought on, and each refuge before it cleared and left.
static func _to_refuge(s: Dictionary, d: BishopDirector, i: int) -> void:
	d._set_out(d.quarries[0])
	for k in i:
		_clear(s, d, k)
		d._drive_out(k)
		d._reach_refuge(k + 1)


static func _setup(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	t.check(d.refuges.size() == 3 and RuinWish.fits(d.refuges[0], "house") and RuinWish.fits(d.refuges[1], "house")
		and d.refuges[2].role == &"temple" and d.refuges[0].center().distance_to(BishopDirector.REFUGE_SPOTS[0]) < 4.0
		and d.refuges[1].center().distance_to(BishopDirector.REFUGE_SPOTS[1]) < 4.0, "the refuges: his house, the chapter house, the Temple")
	t.check(MissionDirector._alive(q.target) and q.target.profile.role == CitizenProfile.Role.CLERGY and q.target.inside
		and q.target.mind == Person.Mind.DUTY and q.state == AssassinateDirector.State.WAITING and d.at_refuge == -1,
		"the bishop, a cleric, waits inside the Citadel, on duty")
	var ok := true
	var knights := 0
	for i in 3:
		var at := d.standing_at(i)
		knights += at.size()
		ok = ok and at.size() == BishopDirector.STANDING and at[0].ground_pos.distance_to(at[1].ground_pos) > 2.0 * SilentDoom.RADIUS
		for k in at:
			ok = ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
				and d.refuges[i].distance_to(k.ground_pos) <= BishopDirector.GUARD_REACH
	var escort := 0
	for p: BishopDirector.Post in d.posts:
		escort += 1 if p.escort and MissionDirector._alive(p.man) and (p.man as Person).inside else 0
	t.check(ok and knights == 6 and escort == BishopDirector.ESCORT and d.guards_at(0).size() == 2,
		"two Knights at each refuge's door, one Doom apart, on guard; his escort waits inside with him")
	var eng := (s.crowd as Crowd).engineers
	t.check(eng.hands_off.size() == 3 and eng.hands_off.has(d.refuges[2]), "the town's engineers never mend a refuge")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["out_0", "taken"], "the strip: he goes to ground, then the Knights take him (%s)" % [ids])
	var clear := true
	for st in d.refuges:
		clear = clear and Kit.clear_of_stack(st.center(), BishopDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the three refuges (or their arrows) clear of the left HUD stack")
	var m := MissionBook.bishop()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.dp_capacity == 13 and reasons == ["bishop", "bishop_taken", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember"] and MissionBook.get_mission("bishop").id == "bishop",
		"the mission: Tier 4's numbers; the bishop, the Knights, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := true
	for i in 3:
		for k in d.standing_at(i):
			held = held and k.mind == Person.Mind.POST and k.corps == Person.Corps.KNIGHT
	t.check(held and d.quarries[0].target.inside and d.quarries[0].target.mind == Person.Mind.DUTY,
		"the rally, the regroup and the evacuation take no Knight, and the bishop stays inside (review focus 2)")
	Kit.done(s)


static func _ground(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	Kit.run_for(s, BishopDirector.ARRIVE_AT + DT)
	var out := 0
	for p: BishopDirector.Post in d.posts:
		if p.escort and MissionDirector._alive(p.man) and not (p.man as Person).inside and (p.man as Person).anchor == p.spot:
			out += 1
	t.check(d.at_refuge == 0 and q.target.inside and q.target.ground_pos.is_equal_approx(d.refuges[0].center()) and out == 2
		and (s.banners as Array).has("THE BISHOP GOES TO GROUND") and q.state == AssassinateDirector.State.WAITING,
		"at 0:45 he goes to ground in his house, unseen; his escort comes out at its door to its posts")
	Kit.done(s)


static func _stone(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var chapter := d.refuges[1]
	var hp := chapter.hp
	chapter.damage(40.0, chapter.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(chapter, 0.5)
	Kit.run_for(s, 0.2)
	t.check(is_equal_approx(chapter.hp, hp) and not d._burning(chapter), "a refuge he is not yet in only shakes, and its fire is smothered")
	d.teardown()
	t.check(not chapter.damage_filter.is_valid(), "teardown lets the stone go: it takes blows again")
	Kit.done(s)


static func _smother(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	var house := d.refuges[0]
	(s.crowd as Crowd).fires.ignite(house, 0.5)
	Kit.run_for(s, 1.0)
	t.check(d._burning(house), "in his refuge a fire takes")
	Kit.run_for(s, BishopDirector.SMOTHER_AFTER)
	t.check(not d._burning(house) and d.driven == 0, "a Knight on guard beats it out after SMOTHER_AFTER")
	_clear(s, d, 0)
	(s.crowd as Crowd).fires.ignite(house, 0.5)
	Kit.run_for(s, BishopDirector.DRIVE_OUT + 0.5)
	t.check(d.driven == 1 and d.in_flight and d.at_refuge == 1 and d.quarries[0].target.inside
		and (s.banners as Array).has("THE BISHOP FLEES HIS HOUSE"), "with none on guard, DRIVE_OUT seconds alight drive him out, unseen")
	t.check(absf(d.timeline.seconds_to("arrive_1") - BishopDirector.CHAIN) < 1.0 and d.hint_phase() == "waiting",
		"the strip counts down to his next refuge, CHAIN on")
	Kit.done(s)


static func _flight(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	var standing: Array = d.standing_at(0)
	d.refuges[0].destroy(d.refuges[0].center(), &"smite")
	Kit.run_for(s, 0.1)
	var home := true
	for v: Variant in standing:
		home = home and (v as Person).anchor.is_equal_approx(d.hide_door)
	t.check(d.in_flight and d.driven == 1 and home, "his house down drives him out too; its Knights go home to the Citadel")
	Kit.run_for(s, BishopDirector.CHAIN - 1.0)
	t.check(d.in_flight and d.at_refuge == 1, "a second short of CHAIN he is still on his way")
	Kit.run_for(s, 1.0 + DT)
	var out := 0
	for p: BishopDirector.Post in d.posts:
		if p.escort and not p.done and p.refuge == 1 and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			out += 1
	t.check(not d.in_flight and d.at_refuge == 1 and out == BishopDirector.ESCORT and not d.refuges[1].damage_filter.is_valid()
		and (s.banners as Array).has("THE BISHOP REACHES THE CHAPTER HOUSE"),
		"CHAIN after he was driven out he reaches the chapter house, his escort beside him; it is stone no more")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var post: BishopDirector.Post = null
	for p: BishopDirector.Post in d.posts:
		if not p.escort and p.refuge == 1:
			post = p
			break
	var dead: Variant = post.man
	Kit.free_body(s, dead)
	Kit.run_for(s, BishopDirector.RELIEF_AFTER + 1.0)
	var k: Variant = post.man
	t.check(k != dead and MissionDirector._alive(k) and (k as Person).corps == Person.Corps.KNIGHT and (k as Person).anchor == post.spot
		and (k as Person).ground_pos.distance_to(d.hide_door) < 1.5 and post.relief and d.reliefs == 1
		and d.relief_walking() == k, "RELIEF_AFTER after a standing Knight falls, a new one walks from the Citadel's gate to his post")
	d.reliefs = BishopDirector.RELIEFS
	var other: Variant = null
	for p: BishopDirector.Post in d.posts:
		if not p.escort and p.refuge == 2:
			other = p.man
			break
	Kit.free_body(s, other)
	Kit.run_for(s, BishopDirector.RELIEF_AFTER + 1.0)
	t.check(d.reliefs == BishopDirector.RELIEFS and d.standing_at(2).size() == 1, "RELIEFS at most in a night")
	Kit.done(s)


static func _square(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 2)
	_clear(s, d, 2)
	(s.crowd as Crowd).fires.ignite(d.refuges[2], 0.5)
	Kit.run_for(s, BishopDirector.DRIVE_OUT_TEMPLE + 0.6)
	var ringed := q.guards.size() == 2
	for v: Variant in q.guards:
		var gap := (v as Person).anchor.distance_to(q.target.ground_pos)
		ringed = ringed and gap > SilentDoom.RADIUS and gap < Crowd.DOOM_WITNESS
	t.check(d.in_square and not q.target.inside and q.state == AssassinateDirector.State.WALKING and q.target.mind == Person.Mind.DUTY
		and q.target.anchor.is_equal_approx(d.safe_at) and ringed and d.hint_phase() == "square"
		and (s.banners as Array).has("THE BISHOP IS DRAWN INTO THE SQUARE"),
		"driven from the Temple he walks for the Citadel's gate, two Knights ringing him beyond one Doom")
	t.check(Kit.labels(d).slice(0, 2) == ["BISHOP", "CITADEL"] and Kit.edged(d, "BISHOP") and Kit.edged(d, "CITADEL")
		and ((s.rules as Rules).objectives[0] as Objective).hud_text(s.rules) == "Kill the bishop, he makes for the Citadel",
		"in the square: BISHOP and CITADEL, pointed at; the HUD says so")
	var walk := q.target.pace
	d._on_cast(1, "smite", q.target.ground_pos)
	t.check(q.state == AssassinateDirector.State.FLEEING and q.target.pace > walk and d.hint_phase() == "running"
		and Kit.labels(d)[0] == "BISHOP - RUNNING", "a loud power by him sends him running for it, at his own pace")
	Kit.arrive(q.target, d.safe_at)
	Kit.run_for(s, 0.6)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.any_safe() and main.check(s.rules) == Objective.Status.FAILED and main.reason == "bishop_safe"
		and (s.banners as Array).has("THE BISHOP REACHES THE CITADEL"), "the gate reached: the night is lost")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 2)
	d._drive_out(2)
	(s.crowd as Crowd)._field.kill(q.target, &"doom")
	Kit.run_for(s, 0.1)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.all_fallen() and main.check(s.rules) == Objective.Status.DONE and main.reason == "bishop"
		and (s.banners as Array).has("THE KNIGHTS CRY MURDER"), "his death wins, seen by his Knights: they cry murder")
	Kit.done(s)
	var n := _world()
	var taken: Objective = (n.rules as Rules).objectives[1]
	t.check(taken.hud_text(n.rules) == "Knights come 5:00", "the deadline row (%s)" % taken.hud_text(n.rules))
	(n.d as BishopDirector).timeline.step(BishopDirector.TAKEN_AT + DT)
	t.check(taken.check(n.rules) == Objective.Status.FAILED and taken.reason == "bishop_taken" and (n.banners as Array).has("THE KNIGHTS TAKE HIM AWAY"),
		"left alone, the Knights take him away at 5:00")
	Kit.done(n)
	var g := _world()
	var gq := (g.d as BishopDirector).quarries[0]
	(g.crowd as Crowd)._field.remove(gq.target)
	(g.crowd as Crowd).citizens.erase(gq.target)
	gq.target.free()
	Kit.run_for(g, 0.1)
	t.check((g.d as BishopDirector).any_safe(), "his body gone without his death (out of the town): he got away, at once")
	Kit.done(g)


static func _evacuate(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var q := d.quarries[0]
	_to_refuge(s, d, 0)
	d._drive_out(0)
	var due := d.arrive_at
	Kit.evacuate(s)
	Kit.run_for(s, 0.6)
	var posted := true
	for k in d.standing_at(1):
		posted = posted and k.mind == Person.Mind.POST
	t.check(posted and q.target.inside and d.in_flight, "the evacuation in his flight: the next refuge's Knights hold, he stays inside")
	Kit.run_for(s, due - d._clock + DT)
	t.check(d.at_refuge == 1 and not d.in_flight, "and he arrives on time")
	Kit.done(s)
	var w := _world()
	var wd: BishopDirector = w.d
	var wq := wd.quarries[0]
	_to_refuge(w, wd, 2)
	wd._drive_out(2)
	var bishop := wq.target
	bishop.whisper(bishop.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	var knight := wq.guards[0] as Person
	Kit.evacuate(w)
	t.check(bishop._whisper_fled, "(set-up) the evacuation owes the whispered bishop a flight")
	Kit.run_for(w, 0.6)
	t.check(not bishop._whisper_fled and bishop.mind == Person.Mind.WHISPERED and knight.mind == Person.Mind.POST,
		"at the first look after it his flight is ended; his ring holds")
	bishop._wake()
	bishop.mind = Person.Mind.RECOVER
	Kit.run_for(w, 0.6)
	t.check(bishop.mind == Person.Mind.DUTY and bishop.anchor.is_equal_approx(wd.safe_at),
		"back on his feet he walks for the Citadel again, not for the gates")
	Kit.done(w)


static func _tagged(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 2) == ["BISHOP - IN THE CITADEL", "NEXT REFUGE - HE COMES IN 0:45"] and labels.has("KNIGHT")
		and Kit.edged(d, "NEXT REFUGE - HE COMES IN 0:45") and not Kit.edged(d, "BISHOP - IN THE CITADEL") and d.hint_phase() == "waiting",
		"before 0:45: in the Citadel (grey, no arrow into the HUD's corner); his house next, pointed at (%s)" % [labels.slice(0, 2)])
	_to_refuge(s, d, 0)
	t.check(Kit.labels(d).slice(0, 2) == ["REFUGE - GUARDED", "NEXT REFUGE"] and d.hint_phase() == "guarded",
		"in his house: guarded, the chapter house next")
	_clear(s, d, 0)
	t.check(Kit.labels(d)[0] == "REFUGE - SET IT ALIGHT" and d.hint_phase() == "open", "none on guard: set it alight")
	(s.crowd as Crowd).fires.ignite(d.refuges[0], 0.5)
	Kit.run_for(s, 1.2)
	t.check(Kit.labels(d)[0] == "REFUGE - BURNING 7" and d.hint_phase() == "burning"
		and ((s.rules as Rules).objectives[0] as Objective).hud_text(s.rules) == "Kill the bishop: refuges 0 / 3",
		"burning, its seconds counted down; the HUD's count (%s)" % Kit.labels(d)[0])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("His house. The bishop goes to ground here at 0:45")
		and String(tour[2][1]).ends_with("draw him into the square."), "the tour: his house, the chapter house, the Temple")
	t.check(ResultsScreen.ACT_TITLES.get("bishop") == "THE BISHOP IS DEAD" and ResultsScreen.ACT_TITLES.get("bishop_safe") == "THE BISHOP REACHES THE CITADEL"
		and ResultsScreen.ACT_TITLES.get("bishop_taken") == "THE KNIGHTS TAKE HIM AWAY", "its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: BishopDirector = s.d
	_to_refuge(s, d, 0)
	for i in 3:
		_clear(s, d, i)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.guards_at(0).is_empty() and d.hint_phase() == "open" and int(d.report().refuges) == 0,
		"every Knight freed: the tags, hint and report bear it (review focus 4)")
	Kit.free_body(s, d.quarries[0].target)
	Kit.run_for(s, 0.1)
	d.tags()
	t.check(d.all_fallen() and d.hint_phase() == "" and d.tags().is_empty() and String(d.report().target) != "",
		"his body freed too: nothing touches it")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_bishop.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then Tests. Expected: parse errors (`BishopDirector`, `MissionBook.bishop`).

- [ ] **Step 3: Create `src/game/mission/bishop_director.gd`:**

```gdscript
class_name BishopDirector
extends AssassinateDirector
## The Bishop (v0.11 M5, Tier 4, mission spec §1; Assassinate, reused): the bishop hides behind his Lantern Knights. He waits in the
## Citadel, untouchable, and at ARRIVE_AT goes to ground in his house by the cellars. Between refuges he moves indoors, unseen; he
## never walks a street until the Temple drives him out. His refuges, in order: his house (the dwelling nearest REFUGE_SPOTS[0]), the
## chapter house (nearest REFUGE_SPOTS[1]) and the Temple. A refuge he is not yet in is stone tonight: a blow only shakes it and any
## fire on it is smothered. STANDING Knights hold each refuge's door from the start, POST_GAP apart along its open face; his escort of
## ESCORT comes with him and stands POST_GAP beyond them -- the last refuge's survivors, topped up from the Citadel through the
## cellars. A Knight on guard (alive, out of doors, within GUARD_REACH of the refuge) beats out a fire on it once it has burned
## SMOTHER_AFTER. The refuge he is in burning DRIVE_OUT seconds in all with none on guard (the Temple DRIVE_OUT_TEMPLE), or falling,
## drives him out: he reaches the next CHAIN later, unseen, his escort's survivors with him. A standing Knight who falls is replaced
## RELIEF_AFTER later by one walking from the Citadel's gate while the bishop has not passed his refuge (RELIEFS at most); a refuge
## he has left sends its Knights home. Driven from the Temple he comes out at its door ringed by its living Knights (two more if
## fewer than two live) at RING_R and walks on duty at BISHOP_PACE for the Citadel's gate; a loud power near him, a fallen Knight or
## a fright sends him running (the base's alarm, with no hideout). Reaching the gate, or leaving the town, loses; so does TAKEN_AT
## (EventObjective). His death wins, seen or not (a seen one calls the bellkeeper). The Knights are soldiers the director adds
## (Crowd.add_soldier(), corps KNIGHT): a whisper and Discord do not touch a soldier, a fright does not move one, and the rally, the
## marshals and the investigations never take a Knight (plan decisions 171-176).

## One Knight's post (v0.11 M5): a plain record, so the director holds no cycle.
class Post:
	extends RefCounted
	## The Knight, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## The refuge he holds (an index into `refuges`) and his place at its door.
	var refuge := 0
	var spot := Vector2.INF
	## He is of the bishop's escort (inside with him between refuges), not a standing Knight.
	var escort := false
	## Seconds since he fell; he is a relief walking in until he first stands guard; his post is given up (his refuge passed, or
	## he rings the bishop in the square).
	var fallen := 0.0
	var relief := false
	var done := false


## Where the bishop's house and the chapter house are (v0.11 M5, Decision 127): the dwellings nearest these points; and the Citadel's
## gate, where he waits and where he runs once drawn into the square.
const REFUGE_SPOTS := [Vector2(12.0, -6.8), Vector2(6.5, -13.0)]
const CITADEL_GATE := Vector2(-10.5, -7.6)
## The refuges in words, for the banners and the strip (v0.11 M5).
const REFUGE_WORDS := ["his house", "the chapter house", "the Temple"]
## Mission spec §1's numbers (v0.11 M5), first guesses, tuned by Step 7's gate in this order: CHAIN (30-45), ARRIVE_AT (30-60), ESCORT
## (1-3), DRIVE_OUT (6-12), RELIEF_AFTER (20-30). His first refuge; his flight; the Knights; their spacing and reach; the fire's
## rules; the reliefs; the square; the Knights' deadline.
const ARRIVE_AT := 45.0
const CHAIN := 45.0
const STANDING := 2
const ESCORT := 2
const POST_GAP := 1.8
const GUARD_REACH := 2.5
const SMOTHER_AFTER := 3.0
const DRIVE_OUT := 8.0
const DRIVE_OUT_TEMPLE := 10.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const RING_R := 1.4
const BISHOP_PACE := 0.5
const TAKEN_AT := 300.0
## Where the camera rests (v0.11 M5, Decision 159): his house at the right, the chapter house at the top right, the Temple's door at
## the left below the HUD stack; the Citadel's gate off screen to the west.
const CAMERA_AT := Vector2(6.0, -6.5)
## How hard a blow shakes a refuge he is not yet in; how far a Knight's place must move before he is sent again (v0.11 M5).
const STONE_SHAKE := 2.0
const MOVE := 0.3
## The tags' grey for what is not yet (v0.11 M5).
const MARK_GREY := Color("9a948a")

## The refuges in order and each one's door (v0.11 M5; the quarry's stops and their doors).
var refuges: Array[Structure] = []
var doors: Array[Vector2] = []
## Every Knight's Post, standing and escort (v0.11 M5).
var posts: Array = []
## The refuge he is in, or making for in a flight (-1 while he waits in the Citadel); he is on his way; the second he arrives; how
## many refuges he has been driven from; he is in the square; how many reliefs came (v0.11 M5).
var at_refuge := -1
var in_flight := false
var arrive_at := -1.0
var driven := 0
var in_square := false
var reliefs := 0
## Each refuge's seconds alight with none on guard, in all, and its fire's seconds with one on guard (v0.11 M5).
var _burned: Array[float] = []
var _alight: Array[float] = []
## Structure -> true while it is stone (v0.11 M5).
var _stoned := {}
## His own pace, before BISHOP_PACE; the Knights walking home; seconds to the next look (v0.11 M5).
var _own_pace := 1.0
var _homeward: Array = []
var _look_in := 0.0


## The places and numbers (v0.11 M5): no hideout (no smoke-out, the Citadel's gate as the safe place), the guards' ring RING_R, and
## the bishop's three refuges as his stops; ESCORT guards (his escort, _appoint_guards()).
func _plan() -> void:
	hideout = null
	safe_at = CITADEL_GATE
	smoke_out = false
	guard_r = RING_R
	safe_label = "CITADEL"
	var from := _walkable(CITADEL_GATE)
	var stops: Array[Structure] = []
	for spot: Vector2 in REFUGE_SPOTS:
		var h := _house_reached(spot, from, stops)
		if h != null:
			stops.append(h)
	var temple := _temple()
	if temple != null:
		stops.append(temple)
	_add_quarry("BISHOP", ARRIVE_AT, stops, ESCORT)


## The town's Temple, by its role (v0.11 M5); null for none.
func _temple() -> Structure:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple" and not s.destroyed:
			return s
	return null


## The night's setup (v0.11 M5): the Assassinate type's (the bishop appointed and set down at the Citadel's gate, his escort added and
## inside), then the refuges stone and kept from the town's engineers, two Knights at each door, the bishop inside on duty, and the
## Knights' deadline on the strip.
func _begin() -> void:
	super()
	var q := quarries[0]
	refuges = q.stops
	doors = q.stop_doors
	for i in refuges.size():
		_burned.append(0.0)
		_alight.append(0.0)
		_stone(refuges[i])
		for k in STANDING:
			var p := Post.new()
			p.refuge = i
			p.spot = _post(i, k, false)
			p.man = _knight(p.spot)
			posts.append(p)
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(refuges)
	if _alive(q.target):
		_own_pace = q.target.pace
		q.target.go_duty(q.target.ground_pos)
		_take_inside(q.target, null)
	timeline.add(TAKEN_AT, "taken", "The Knights take him away", Callable(), func() -> bool: return not all_fallen() and not any_safe())


## The bishop is the cleric nearest the Citadel's gate (v0.11 M5).
func _appoint_target(_q: Quarry) -> Person:
	return _citizen_near(hide_door, CitizenProfile.Role.CLERGY, _appointed())


## His escort (v0.11 M5, Task 1's hook): q.guard_count Knights added at the Citadel's gate and taken inside with him.
func _appoint_guards(q: Quarry, _taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for k in q.guard_count:
		var p := Post.new()
		p.escort = true
		p.man = _knight(hide_door)
		_take_inside(p.man as Person, null)
		posts.append(p)
		out.append(p.man as Person)
	return out


## The base sends and sends home only his Knights at their posts (v0.11 M5, Task 1's hook).
func _tends(p: Person) -> bool:
	return p.corps == Person.Corps.KNIGHT and p.mind == Person.Mind.POST


## A Lantern Knight added at `at` (v0.11 M5, Broken Lanterns' way): a soldier of corps KNIGHT, three times a soldier's health, at his post.
func _knight(at: Vector2) -> Person:
	var k := crowd.add_soldier(_walkable(at))
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT
	k.send_to_post(k.ground_pos)
	return k


## The `k`th Knight's post at refuge `i` (v0.11 M5): along its door's face, the standing pair POST_GAP apart about the door, the escort
## POST_GAP beyond them.
func _post(i: int, k: int, escort: bool) -> Vector2:
	var face := doors[i]
	var out := face - refuges[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	return _walkable(face + along * side * POST_GAP * (1.5 if escort else 0.5))


## `s` is stone tonight (v0.11 M5, Decision 128): a blow only shakes it, and its fire is smothered (_smother_stone()).
func _stone(s: Structure) -> void:
	_stoned[s] = true
	s.damage_filter = _stone_hit


## `s` is a building again (v0.11 M5): the bishop is in it.
func _unstone(s: Structure) -> void:
	_stoned.erase(s)
	if is_instance_valid(s):
		s.damage_filter = Callable()


## Structure.damage_filter for a stone refuge (v0.11 M5): the blow only shakes it.
func _stone_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(STONE_SHAKE)


## Every stone refuge's fire is put out (v0.11 M5).
func _smother_stone() -> void:
	for s: Variant in _stoned.keys():
		if is_instance_valid(s) and _burning(s as Structure):
			crowd.fires._put_out(s as Structure, true)


## The night's opening banner (v0.11 M5).
func _opening_banner() -> String:
	return "THE BISHOP"


## The strip's words for his first refuge (v0.11 M5).
func _set_out_label(_q: Quarry) -> String:
	return "The bishop goes to ground"


## The banner when he runs (v0.11 M5).
func _hide_banner(_q: Quarry) -> String:
	return "THE BISHOP RUNS FOR THE CITADEL"


## The banner when he reaches the gate, or leaves the town (v0.11 M5).
func _safe_banner() -> String:
	return "THE BISHOP REACHES THE CITADEL"


## The banner when his death is seen (v0.11 M5).
func _seen_banner() -> String:
	return "THE KNIGHTS CRY MURDER"


## His time (v0.11 M5, the timeline's "out_0"): he goes to ground in his house, unseen.
func _set_out(q: Quarry) -> void:
	if q.state != State.WAITING or not _alive(q.target) or at_refuge >= 0 or refuges.is_empty():
		return
	_reach_refuge(0)


## He reaches refuge `i` (v0.11 M5): indoors in it, unseen; it is a building again; his escort's survivors, topped up to ESCORT from
## the Citadel through the cellars, come out at its door to their posts.
func _reach_refuge(i: int) -> void:
	var q := quarries[0]
	if q.dead or in_square or not _alive(q.target):
		return
	at_refuge = i
	in_flight = false
	arrive_at = -1.0
	q.inside_of = refuges[i]
	q.target.ground_pos = refuges[i].center()
	_unstone(refuges[i])
	var living: Array[Person] = []
	for p: Post in posts:
		if p.escort and not p.done:
			if _alive(p.man):
				living.append(p.man as Person)
			else:
				p.done = true
	while living.size() < ESCORT:
		var np := Post.new()
		np.escort = true
		np.man = _knight(refuges[i].center())
		_take_inside(np.man as Person, null)
		posts.append(np)
		living.append(np.man as Person)
	var k := 0
	for p: Post in posts:
		if not p.escort or p.done:
			continue
		p.refuge = i
		p.spot = _post(i, k, true)
		k += 1
		var man := p.man as Person
		if man.inside:
			_bring_out(man, doors[i])
		man.send_to_post(p.spot, false, true)
	q.guards = living
	_guard_total = living.size()


## How long refuge `i` must burn with none on guard to drive him out (v0.11 M5).
func drive_out_after(i: int) -> float:
	return DRIVE_OUT_TEMPLE if refuges[i].role == &"temple" else DRIVE_OUT


## He is driven from refuge `i` (v0.11 M5): from the Temple into the square; else its Knights go home, his escort's survivors go in
## with him, unseen, and he reaches the next CHAIN later (the timeline's event, so the strip counts down to it).
func _drive_out(i: int) -> void:
	var q := quarries[0]
	driven += 1
	if i + 1 >= refuges.size():
		_into_square()
		return
	_send_home(i)
	rules.banner.emit("THE BISHOP FLEES %s" % String(REFUGE_WORDS[i]).to_upper())
	in_flight = true
	at_refuge = i + 1
	arrive_at = _clock + CHAIN
	q.inside_of = null
	q.target.ground_pos = refuges[i + 1].center()
	for p: Post in posts:
		if p.escort and not p.done and _alive(p.man) and not (p.man as Person).inside:
			_take_inside(p.man as Person, null)
	var next := i + 1
	timeline.add(timeline.elapsed() + CHAIN / timeline.stretch_factor(), "arrive_%d" % next,
		"The bishop reaches %s" % REFUGE_WORDS[next], _reach_refuge.bind(next),
		func() -> bool: return in_flight and at_refuge == next)


## Refuge `i`'s standing Knights go home to the Citadel (v0.11 M5): their posts are given up.
func _send_home(i: int) -> void:
	for p: Post in posts:
		if p.escort or p.done or p.refuge != i:
			continue
		p.done = true
		if _alive(p.man):
			(p.man as Person).send_to_post(hide_door)
			_homeward.append(p.man)


## Driven from the Temple (v0.11 M5): he comes out at its door with its living Knights -- two more if fewer than two live -- who ring
## him (the base's guards' ring), and walks on duty for the Citadel's gate at BISHOP_PACE (the base walks him from here).
func _into_square() -> void:
	var q := quarries[0]
	var last := refuges.size() - 1
	var door := doors[last]
	in_square = true
	in_flight = false
	q.inside_of = null
	var ring: Array[Person] = []
	for p: Post in posts:
		if p.done or p.refuge != last:
			continue
		p.done = true
		if not _alive(p.man):
			continue
		var man := p.man as Person
		if man.inside:
			_bring_out(man, door)
		ring.append(man)
	if ring.size() < 2:
		for k in 2:
			ring.append(_knight(door))
	_bring_out(q.target, door)
	_keep_from_flight(q.target, true)
	q.target.pace = _own_pace * BISHOP_PACE
	q.leg = q.stops.size()
	q.state = State.WALKING
	q.guards = ring
	_guard_total = ring.size()
	q.target.go_duty(safe_at)
	rules.banner.emit("THE BISHOP IS DRAWN INTO THE SQUARE")
	_send_guards()


## Alarmed in the square (v0.11 M5): the base's flight for the gate, at his own pace.
func _alarm(q: Quarry) -> void:
	var was := q.state
	super(q)
	if was == State.WALKING and q.state == State.FLEEING and _alive(q.target):
		q.target.pace = _own_pace
		q.target.go_duty(_hide_goal())


## The base's guards' ring, only in the square (v0.11 M5): before it the Knights keep their own posts (_tend()).
func _send_guards() -> void:
	if in_square:
		super()


## One step (v0.11 M5): the Assassinate type's (the strip, the judge, his walk in the square), then the evacuation rule for him, the
## refuge he is in, the Knights, and the stone refuges' fires.
func step(delta: float) -> void:
	super(delta)
	_look_in -= delta
	var looking := _look_in <= 0.0
	if looking:
		_look_in = TICK
	var q := quarries[0]
	var evacuating := looking and _evacuation_began()
	if looking and in_square and _alive(q.target) and not q.target.inside:
		_keep_from_flight(q.target, evacuating)
	if not q.dead and q.state == State.WAITING and at_refuge >= 0 and not in_flight and _alive(q.target):
		_refuge_step(at_refuge, delta)
	_tend(delta, looking)
	_smother_stone()


## The refuge he is in (v0.11 M5): fallen, he is driven out; alight with a Knight on guard, it is beaten out after SMOTHER_AFTER;
## alight with none, its seconds count, and drive_out_after(i) of them drive him out.
func _refuge_step(i: int, delta: float) -> void:
	var s := refuges[i]
	if not is_instance_valid(s) or s.destroyed:
		_drive_out(i)
		return
	if not _burning(s):
		_alight[i] = 0.0
		return
	if not guards_at(i).is_empty():
		_alight[i] += delta
		if _alight[i] >= SMOTHER_AFTER:
			_alight[i] = 0.0
			crowd.fires._put_out(s, true)
		return
	_alight[i] = 0.0
	_burned[i] += delta
	if _burned[i] >= drive_out_after(i):
		_drive_out(i)


## The Knights at their work (v0.11 M5): each out of doors kept at his post (Broken Lanterns' _tend_knights()); a standing one of a
## refuge not yet passed who fell is replaced RELIEF_AFTER later (_relieve()); those going home are taken in at the Citadel's gate.
func _tend(delta: float, looking: bool) -> void:
	for p: Post in posts:
		if p.done or (p.escort and in_flight):
			continue
		if not _alive(p.man):
			if p.escort:
				continue
			p.fallen += delta
			if looking and p.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
				_relieve(p)
			continue
		p.fallen = 0.0
		var man := p.man as Person
		if man.inside:
			continue
		if _on_guard(p):
			p.relief = false
		if looking and man.mind == Person.Mind.POST and man.anchor.distance_to(p.spot) > MOVE:
			man.send_to_post(p.spot, false, true)
	if not looking:
		return
	for v: Variant in _homeward.duplicate():
		if not _alive(v) or (v as Person).inside:
			_homeward.erase(v)
		elif (v as Person).ground_pos.distance_to(hide_door) <= ARRIVE:
			_take_inside(v as Person, null)
			_homeward.erase(v)


## A new Knight for post `p` (v0.11 M5): added at the Citadel's gate, walking to the post.
func _relieve(p: Post) -> void:
	var k := _knight(hide_door)
	k.send_to_post(p.spot, false, true)
	p.man = k
	p.fallen = 0.0
	p.relief = true
	reliefs += 1
	rules.banner.emit("A NEW KNIGHT COMES FROM THE CITADEL")


## Post `p`'s Knight is on guard now (v0.11 M5, plan decision 172): alive, out of doors, within GUARD_REACH of his refuge.
func _on_guard(p: Post) -> bool:
	if p.done or not _alive(p.man):
		return false
	var man := p.man as Person
	var s := refuges[p.refuge]
	return not man.inside and is_instance_valid(s) and s.distance_to(man.ground_pos) <= GUARD_REACH


## The Knights on guard at refuge `i` now (v0.11 M5). Only reads.
func guards_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.refuge == i and _on_guard(p):
			out.append(p.man as Person)
	return out


## Refuge `i`'s living Knights out of doors, on guard or not (v0.11 M5, for the policy and the tags). Only reads.
func standing_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if not p.done and p.refuge == i and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## A relief walking in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking() -> Person:
	for p: Post in posts:
		if p.relief and not p.done and _alive(p.man) and not (p.man as Person).inside and not _on_guard(p):
			return p.man as Person
	return null


## The refuge he is in now, or -1 (in the Citadel, in a flight, in the square) (v0.11 M5). Only reads.
func current_refuge() -> int:
	return at_refuge if at_refuge >= 0 and not in_flight and not in_square else -1


## The refuge he makes for next, or -1 (v0.11 M5): his house before 0:45, the one he flies to, or the one after his. Only reads.
func next_refuge() -> int:
	if in_square:
		return -1
	if at_refuge < 0:
		return 0
	if in_flight:
		return at_refuge
	return at_refuge + 1 if at_refuge + 1 < refuges.size() else -1


## Seconds until he reaches his next refuge (v0.11 M5): to 0:45 in the Citadel, the flight's end in one; 0 in a refuge or the square.
func arrive_in() -> float:
	if at_refuge < 0 and not in_square:
		return maxf(out_at(0) - _clock, 0.0)
	if in_flight:
		return maxf(arrive_at - _clock, 0.0)
	return 0.0


## The HUD's line (v0.11 M5): "Kill the bishop: refuges 1 / 3"; in the square, "Kill the bishop, he makes for the Citadel".
func hud_line() -> String:
	if in_square:
		return "Kill the bishop, he makes for the Citadel"
	return "Kill the bishop: refuges %d / %d" % [driven, refuges.size()]


## The map tags, most important first (v0.11 M5, mission spec §1): before 0:45 BISHOP - IN THE CITADEL (grey, no arrow: it would point
## into the HUD's corner); the refuge he is in, gold, guarded, open or burning; the next refuge, grey, with his arrival's time while
## he is on his way; KNIGHT on each Knight on guard at those two, a red diamond on a relief, a small red mark on one away. In the square:
## BISHOP (RUNNING once alarmed), CITADEL, and a red diamond on each who would see a Doom on him. None once he is dead or gone.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	var q := quarries[0]
	if q.dead or q.state == State.SAFE or not _alive(q.target):
		return out
	if in_square:
		var running := q.state == State.FLEEING
		out.append(MapTag.person(q.target.ground_pos, MARK_TARGET, "BISHOP - RUNNING" if running else "BISHOP", true))
		out.append(MapTag.place(safe_at, MARK_WATCHED, safe_label, 0.0, true))
		for p in witnesses(q):
			out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
		return out
	if at_refuge < 0:
		out.append(MapTag.place(hide_door, MARK_GREY, "BISHOP - IN THE CITADEL", 0.0, false))
	var cur := current_refuge()
	if cur >= 0:
		var s := refuges[cur]
		var label := "REFUGE - SET IT ALIGHT"
		if not guards_at(cur).is_empty():
			label = "REFUGE - GUARDED"
		elif _burning(s):
			label = "REFUGE - BURNING %d" % ceili(maxf(drive_out_after(cur) - _burned[cur], 0.0))
		out.append(MapTag.place(s.center(), MARK_TARGET, label, s.height, true))
	var nxt := next_refuge()
	if nxt >= 0 and nxt != cur:
		var n := refuges[nxt]
		var words := "NEXT REFUGE - HE COMES IN %s" % UiTheme.clock(arrive_in()) if cur < 0 else "NEXT REFUGE"
		out.append(MapTag.place(n.center(), MARK_GREY, words, n.height, true))
	for i: int in [cur, nxt]:
		if i < 0:
			continue
		for p: Post in posts:
			if p.done or p.refuge != i or not _alive(p.man) or (p.man as Person).inside:
				continue
			var man := p.man as Person
			if _on_guard(p):
				out.append(MapTag.person(man.ground_pos, MARK_WATCHED, "KNIGHT"))
			elif p.relief:
				out.append(MapTag.person(man.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(man.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5, plan decision 205): "square" / "running" in the square; "waiting" in the Citadel or a flight;
## "guarded", "burning" or "open" in a refuge; "" once he is dead or gone.
func hint_phase() -> String:
	var q := quarries[0]
	if q.dead or q.state == State.SAFE or not _alive(q.target):
		return ""
	if in_square:
		return "running" if q.state == State.FLEEING else "square"
	var cur := current_refuge()
	if cur < 0:
		return "waiting"
	if not guards_at(cur).is_empty():
		return "guarded"
	return "burning" if _burning(refuges[cur]) else "open"


## The tour (v0.11 M5, mission spec §1): his house, the chapter house, the Temple.
func tour() -> Array:
	var words := ["His house. The bishop goes to ground here at %s, his Knights at the door." % UiTheme.clock(ARRIVE_AT),
		"The chapter house, his next refuge. Burn each one to drive him on.",
		"The Temple, his last refuge. Set it alight to draw him into the square."]
	var out := []
	for i in refuges.size():
		out.append([doors[i], String(words[2 if refuges[i].role == &"temple" else mini(i, 1)])])
	return out


## What the results show (v0.11 M5): the Assassinate type's, the refuges he was driven from and the reliefs.
func report() -> Dictionary:
	var r := super()
	r["refuges"] = driven
	r["reliefs"] = reliefs
	return r


## Lets go of the stone and the engineers' list, then the Assassinate type's (v0.11 M5).
func teardown() -> void:
	for s: Variant in _stoned.keys():
		if is_instance_valid(s):
			(s as Structure).damage_filter = Callable()
	_stoned.clear()
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s: Variant in refuges:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
```

- [ ] **Step 4: The mission.**
  - In `src/game/mission/mission_book.gd`, `tier_missions()`'s list gains `bishop()` after M4's `heretic_hunt()`, and after
    `heretic_hunt()` add:

```gdscript
## The Bishop (v0.11 M5, Tier 4, mission spec §1 and §8 row 17): burn the bishop out of his three refuges -- each guarded by Lantern
## Knights -- and kill him in the square before the Knights take him away (BishopDirector, the Assassinate type reused).
static func bishop() -> MissionDef:
	var m := _tier4(BISHOP, "The Bishop", PackedStringArray(["The bishop hides behind his Knights.", "Smoke him out. Kill him."]))
	m.goal = "Burn the bishop out of his refuges, then kill him before the Knights take him away at %s" % UiTheme.clock(
		BishopDirector.TAKEN_AT)
	m.goal_label = "The bishop is dead"
	m.lose = "He reaches the Citadel, the Knights take him away, or dawn comes"
	m.camera_at = BishopDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember"])
	m.director = BishopDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [AssassinateObjective.new("Kill the bishop", "bishop", "bishop_safe"),
			EventObjective.new("taken", "Knights come", "bishop_taken"), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

  - In `mission_hints.gd` `LINES`, after M4's last entries, add (and the same seven rows, under `# The Bishop (v0.11 M5).`, in
    `tests/test_mission_hints.gd` `SPEC`):

```gdscript
	"bishop": "Burn each refuge the bishop hides in (gold), once its Knights (red) are dead. The Temple last: then kill him in the square.",
	"bishop.waiting": "The bishop goes to ground soon. Kill the next refuge's Knights (red) shortly before he comes.",
	"bishop.guarded": "His Knights (red) beat out fire. Kill every one. Whispers and Discord do not touch a Knight.",
	"bishop.open": "No Knight stands. Set the refuge (gold) alight before a new Knight comes.",
	"bishop.burning": "It burns. Keep it burning: his Knights (red) put out a fire they stand by.",
	"bishop.square": "He is in the square and makes for the Citadel (red). Kill him before he gets in.",
	"bishop.running": "Alarmed, he runs for the Citadel (red). Kill him now.",
```

    If `test_mission_hints`' fit check (HINT_LINES of HINT_W) refuses a line, shorten it in both places keeping its sense, and say
    so in the report (Step 10 syncs the spec).
  - In `results_screen.gd` `ACT_TITLES`, add `"bishop": "THE BISHOP IS DEAD", "bishop_safe": "THE BISHOP REACHES THE CITADEL",
    "bishop_taken": "THE KNIGHTS TAKE HIM AWAY"`, and its doc's last line gains `v0.11 M5: Reckoning's new missions' endings, each under the mission's own reason keys.`

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 35.

- [ ] **Step 6: The behaviour scenario.** In `tools/dev/behaviour_check.gd`:
  - In the header's usage, after M4's `hunt` entry, add:

```gdscript
##   bishop  (v0.11 M5) The Bishop, --case=none (nothing cast) or play, as a player plays it (_bishop_act(): the bishop out of doors,
##          Silent Doom on him, else Smite; a Knight on guard at his refuge, Silent Doom on one alone, else Smite one; none on guard,
##          Ember the refuge (Smite it while Ember cools); in his flight or 25 s before his first refuge, Silent Doom on the next
##          refuge's Knights; else Silent Doom on a relief walking in; the result line gives the longest idle stretch). Hit-stop is
##          off for it. --seed=, --board as ringers.
```

  - After M4's consts add:

```gdscript
## The Bishop's policy (v0.11 M5): how near his first arrival the next refuge's Knights are cleared.
const BISHOP_AHEAD := 25.0
```

  - In `_run()`, after M4's `hunt` branch add:

```gdscript
	elif scenario == "bishop":
		powers = PackedStringArray(["doom", "smite", "ember"])
		mission.mission_id = MissionBook.BISHOP
```

  - The hit-stop line after `mission.start(...)` becomes (plan decision 201):

```gdscript
	if scenario in ["panic", "bread", "hunt", "bishop", "armoury"]:
		mission._bf.ctx.impact.hitstop_enabled = false  # v0.11 M3-M5: Smite's and Heaven Splitter's hit-stop is wall clock; an exact replay needs none
```

  - In `_run()`'s `match scenario:`, before `"warning":`, add:

```gdscript
		"bishop":
			await _bishop(Battlefield.arg_value(args, "--case"))
```

  - After M4's last scenario functions add:

```gdscript
## The Bishop (v0.11 M5), with mission spec §1's policy (_bishop_act()), through _scripted().
func _bishop(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BishopDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("bishop", which, func() -> String: return _bishop_act(rules, slots, d, crowd),
		func() -> String: return "refuge=%d flight=%s square=%s driven=%d guards=%d reliefs=%d phase=%s" % [d.at_refuge, d.in_flight,
			d.in_square, d.driven, d.guards_at(d.current_refuge()).size(), d.reliefs, d.hint_phase()])


## One look of The Bishop's policy (v0.11 M5): what was cast, or "". The first that applies: the bishop out of doors, Silent Doom on him
## (quiet: no alarm before it lands, plan decision 175), else Smite; a Knight on guard at his refuge, clear one (_knight_clear(), a
## Smite allowed); none on guard, Ember the refuge (Smite it while Ember cools); in his flight, or BISHOP_AHEAD before his first refuge,
## Silent Doom on the next refuge's Knights; a relief walking in, Silent Doom on him.
func _bishop_act(rules: Rules, slots: Dictionary, d: BishopDirector, crowd: Crowd) -> String:
	var q := d.quarries[0]
	if q.dead or not WarningDirector._alive(q.target):
		return ""
	if d.in_square and not q.target.inside:
		if _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, q.target.ground_pos)
			return "doom the bishop"
		if _slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, q.target.ground_pos)
			return "smite the bishop"
		return ""
	var cur := d.current_refuge()
	if cur >= 0:
		var on := d.guards_at(cur)
		if not on.is_empty():
			var did := _knight_clear(rules, slots, crowd, on, true)
			if did != "":
				return did
		else:
			var s := d.refuges[cur]
			if is_instance_valid(s) and not s.destroyed and not d._burning(s):
				if _slot_ready(rules, slots, "ember"):
					rules.cast(slots.ember, s.center())
					return "ember refuge %d" % cur
				if _slot_ready(rules, slots, "smite"):
					rules.cast(slots.smite, s.center())
					return "smite refuge %d" % cur
	var nxt := d.next_refuge()
	if nxt >= 0 and nxt != cur and (d.in_flight or (d.at_refuge < 0 and d.arrive_in() <= BISHOP_AHEAD)):
		var ahead := d.standing_at(nxt)
		if not ahead.is_empty():
			var did := _knight_clear(rules, slots, crowd, ahead, false)
			if did != "":
				return did
	var walker := d.relief_walking()
	if walker != null and _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, walker.ground_pos)
		return "doom a relief knight"
	return ""


## Clears one of `on` (v0.11 M5, The Bishop and The Armoury): Silent Doom on one no one else stands within its radius of; else, with
## `smite_ok`, Smite the first; else (`smite_ok` false) Silent Doom on the first.
func _knight_clear(rules: Rules, slots: Dictionary, crowd: Crowd, on: Array[Person], smite_ok: bool) -> String:
	var alone: Person = null
	for p in on:
		if _none_within(crowd, p, SilentDoom.RADIUS):
			alone = p
			break
	if _slot_ready(rules, slots, "doom") and (alone != null or not smite_ok):
		rules.cast(slots.doom, (alone if alone != null else on[0]).ground_pos)
		return "doom a guard"
	if smite_ok and _slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, on[0].ground_pos)
		return "smite a guard"
	return ""


## No one else alive and out of doors, citizen or soldier, stands within `r` of `p` (v0.11 M5). Only reads.
func _none_within(crowd: Crowd, p: Person, r: float) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if o != p and is_instance_valid(o) and o.is_alive() and not o.inside and o.ground_pos.distance_to(p.ground_pos) <= r:
				return false
	return true
```

- [ ] **Step 7: The gate.** Run the Scenario loop for `bishop`.
  - Expected for `none`: `won=false reason=bishop_taken` in each, at 300.0.
  - For `play`: the gate. The spec expects about 3:25 (its sum: 45 + 20 + 45 + 20 + 45 + 22 + 8 ≈ 205 s). Write the measured clear
    and its sum (first wait + the two flights + the work at each refuge and in the square) in the commit body.
  - If it misses: first read the play log against the policy (does it clear the next refuge's Knights in the flight, does it idle
    with a slot ready while a step applies, does the fire brigade beat out the refuge's fire -- name it if so); then tune in this
    order: `CHAIN` (30-45), `ARRIVE_AT` (30-60), `ESCORT` (1-3), `DRIVE_OUT` (6-12), `RELIEF_AFTER` (20-30).
  - Run each seed twice for one case: the checksums must repeat (hit-stop is off).
  - Then the Scenario loop for `ringers`, `panic`, `informer` (M3's eighteen) and `bread`, `prisoner`, `hunt` (M4's eighteen). These
    six `bishop` lines are references from here on.

- [ ] **Step 8: The Reference check.** Expected: every value unchanged (The Tax Collector's and The Informer's twelve among them).

- [ ] **Step 9: Spec sync.** In the mission spec's §1, bring the `Numbers` line, the timeline table, `The clear`, the hint lines and
  the policy's step 1 (Doom before Smite, plan decision 175) to what landed. Change nothing else in the spec.

- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/bishop_director.gd src/game/mission/bishop_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd tests/test_bishop.gd tests/test_bishop.gd.uid tests/test_mission_hints.gd tests/run_all.gd docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md
git commit -m "feat: The Bishop -- three refuges guarded by Lantern Knights, burned in turn, the square last (v0.11 M5)" -m "<the six bishop lines and checksums, the gate's verdict, the measured clear and its sum, any tuning rounds; M3's and M4's 36 unchanged>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The Armoury (Raze, reused, staged)

**Files:**
- Create: `src/game/mission/armoury_director.gd`, `tests/test_armoury.gd`
- Modify: `src/game/mission/mission_book.gd` (new `armoury()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd` (`LINES`), `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `tools/dev/behaviour_check.gd` (usage, consts, `_run()`, new `_armoury()` / `_armoury_act()`)
- Modify: `tests/test_mission_hints.gd` (`SPEC`), `tests/run_all.gd`
- Modify: the mission spec's §2 (synced and rewritten to the staged ruling, Step 9)

**Interfaces:**
- Consumes: Task 1's `RazeDirector.hud_line()`, `_tier4()`, `ARMOURY`; Task 2's `_knight_clear()`, `_none_within()`; `RazeDirector`'s
  `targets`, `spoil_seconds`, `seal()`, `unseal()`, `is_sealed()`, `_spoilable()`, `_on_razed()`, `_raze()`, `razed()`,
  `razed_count()`, `all_razed()`, `burned()`, `burning()`, `MARK_*`; M4's `_recall_to()`, `EngineerManager.hands_off`;
  `HarvestDirector.GUARD_MINDS`; `FireManager.BURNABLE`; `MissionDirector._keep_from_flight()`, `_evacuation_began()`.
- Produces:
  - `ArmouryDirector`: inner `Armed` (`man`, `post`, `squad`, `reinforcement`, `away`, `fallen`, `relief`); `NAMES`, `WORDS`,
    `HORN_LABELS`, `STAGE_AT`, `CHAIN`, `NIGHT_WATCH`, `SQUAD`, `POST_GAP`, `GUARD_REACH`, `SPOIL_SECONDS`, `RETURN_AFTER`,
    `RELIEF_AFTER`, `REINFORCE`, `RESERVE`, `MARCH_AT`, `WORK_AHEAD`, `ARMED_HOLD`, `CAMERA_AT`; `armed`, `mustering`, `razed_at`,
    `faces`, `reserve`, `reinforced`, `reliefs`, `_next_arms`; `stage_due(i)`, `due_in(i)`, `guards(i)`, `current()`, `upcoming()`,
    `mustering_now()`, `relief_walking(i)`, `arms_every()`, `_muster(i)`.
  - `MissionBook.armoury() -> MissionDef`; the scenario `--scenario=armoury`; six references.

- [ ] **Step 1: Write the failing test.** Create `tests/test_armoury.gd`:

```gdscript
extends RefCounted
## v0.11 M5 The Armoury (mission spec §2 with the controller's staged ruling; ArmouryDirector, RazeDirector reused): the north barracks,
## the gate barracks (stone) and the armoury, each mustering at its horn on the chain; a night watch of armed men from the start, a
## squad indoors until the horn, both held deaf and fearless on their posts; guarded, a target is sealed; before its horn a blow lands,
## its fire goes out and its fall counts at the horn; seconds burned stay counted; return, relief and reinforcements from the armoury's
## reserve, faster each minute; the reserve spent sends none. All three razed wins; the march at 5:00 loses. Freed bodies are borne
## (review focus 4); the rally and the evacuation pass them by (review focus 2); the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_guarded(t)
	_ahead(t)
	_muster(t)
	_burn(t)
	_reinforce(t)
	_reserve(t)
	_relief(t)
	_chain(t)
	_ends(t)
	_evacuate(t)
	_tower_reserved(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.armoury())


## Every armed man of target `i` out of doors killed and freed (v0.11 M5 tests).
static func _clear(s: Dictionary, d: ArmouryDirector, i: int) -> void:
	for a: ArmouryDirector.Armed in d.armed[i]:
		if MissionDirector._alive(a.man) and not (a.man as Person).inside:
			Kit.free_body(s, a.man)


static func _setup(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	t.check(d.targets.size() == 3 and d.targets[0].art_tag == &"tavern"
		and d.targets[0].footprint.position.is_equal_approx(TownLayout.TAVERNS[0].position) and d.targets[1].role == &"tower"
		and d.targets[1].footprint.position.is_equal_approx(TownLayout.GATE_TOWERS[1].position) and d.targets[2].kind == Structure.Kind.BARRACKS,
		"the north barracks (the north tavern), the gate barracks (the Main Gate's east tower), the armoury (the barracks shed)")
	var seen := {}
	var ok := true
	for i in 3:
		var watch: Array = []
		for a: ArmouryDirector.Armed in d.armed[i]:
			var p := a.man as Person
			ok = ok and p != null and not seen.has(p) and p.profile.role == CitizenProfile.Role.WATCHMAN and not p.soldier \
				and p.mind == Person.Mind.DUTY
			seen[p] = true
			if a.squad:
				ok = ok and p.inside
			else:
				ok = ok and not p.inside and p.ground_pos.distance_to(a.post) < 0.1 \
					and d.targets[i].distance_to(p.ground_pos) <= ArmouryDirector.GUARD_REACH
				watch.append(p)
		ok = ok and watch.size() == ArmouryDirector.NIGHT_WATCH \
			and (watch[0] as Person).ground_pos.distance_to((watch[1] as Person).ground_pos) > 2.0 * SilentDoom.RADIUS
	for v: Variant in d.reserve:
		ok = ok and (v as Person).inside and not seen.has(v) and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN
	t.check(ok and seen.size() == 12 and d.reserve.size() == ArmouryDirector.RESERVE,
		"a night watch on its posts one Doom apart and a squad indoors at each target, a reserve of eight in the armoury: 20 lay watchmen")
	var eng := (s.crowd as Crowd).engineers
	t.check(eng.hands_off.size() == 3 and eng.hands_off.has(d.targets[1]) and not d.mustering[0], "the town's teams keep off the three; none musters yet")
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["horn_0", "horn_1", "horn_2", "march"], "the strip: three horns, then the march (%s)" % [ids])
	var clear := true
	for st in d.targets:
		clear = clear and Kit.clear_of_stack(st.center(), ArmouryDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the three targets (or their arrows) clear of the left HUD stack")
	var m := MissionBook.armoury()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.dp_capacity == 13 and reasons == ["garrison", "marches", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember", "heaven"] and MissionBook.get_mission("armoury").id == "armoury",
		"the mission: Tier 4's numbers; the garrison, the march, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := true
	for i in 3:
		for a: ArmouryDirector.Armed in d.armed[i]:
			var p := a.man as Person
			held = held and (p.inside if a.squad else p.mind == Person.Mind.DUTY)
	for v: Variant in d.reserve:
		held = held and (v as Person).inside
	t.check(held, "the rally, the regroup and the evacuation pass the night watches by; the squads and the reserve stay indoors (review focus 2)")
	Kit.done(s)


static func _guarded(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	Kit.run_for(s, 0.6)
	var hp := north.hp
	north.damage(30.0, north.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 0.1)
	t.check(d.is_sealed(north) and is_equal_approx(north.hp, hp) and not d.burning(north),
		"an armed man on guard: a blow only shakes it, its fire goes out")
	var a: ArmouryDirector.Armed = d.armed[0][0]
	var man := a.man as Person
	t.check(man.shaken() and man.fearless_left > 0.0 and not man.whisper(man.ground_pos + Vector2(4.0, 0.0), MindWhisperFx.LINGER),
		"an armed man on guard is deaf to a whisper and past fear")
	man.confuse(5.0)
	Kit.run_for(s, 0.6)
	t.check(man.mind == Person.Mind.DUTY and man.anchor == a.post, "Discord holds him a look at most: he is set back on his post")
	Kit.done(s)


static func _ahead(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	_clear(s, d, 0)
	Kit.run_for(s, 0.1)
	var hp := north.hp
	north.damage(20.0, north.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 0.1)
	t.check(not d.is_sealed(north) and north.hp < hp and not d.burning(north),
		"with none on guard a blow lands before its horn, but its fire goes out (the staged ruling)")
	north.destroy(north.center(), &"smite")
	Kit.run_for(s, 0.5)
	t.check(not d.razed(north) and d.hint_phase() == "barred" and String(Kit.labels(d)[0]).begins_with("BARRACKS - DOWN, COUNTS AT"),
		"a fall before its horn is not razed yet: DOWN, COUNTS AT its time")
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]))
	t.check(d.razed(north) and (s.banners as Array).has("THE NORTH BARRACKS IS RAZED"), "still down when its horn sounds: razed at once")
	Kit.done(s)


static func _muster(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) + DT)
	var out := true
	for a: ArmouryDirector.Armed in d.armed[0]:
		out = out and not (a.man as Person).inside and (a.man as Person).anchor == a.post
	t.check(d.mustering[0] and out and (s.banners as Array).has("THE MUSTER HORN: THE NORTH BARRACKS TURNS OUT") and not d.mustering[1],
		"at its horn the north barracks musters: its squad comes out to its posts")
	Kit.done(s)


static func _burn(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var north := d.targets[0]
	d._muster(0)
	var keep: ArmouryDirector.Armed = d.armed[0][0]
	for a: ArmouryDirector.Armed in d.armed[0]:
		if a != keep and MissionDirector._alive(a.man) and not (a.man as Person).inside:
			Kit.free_body(s, a.man)
	Kit.arrive(keep.man as Person, north.center() + Vector2(6.0, 6.0))
	Kit.run_for(s, 0.1)
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, 5.0)
	var five := d.burned(north)
	t.check(d.burning(north) and five > 4.5 and not d.is_sealed(north), "mustering with none on guard, it burns and its seconds count")
	Kit.arrive(keep.man as Person, keep.post)
	Kit.run_for(s, 0.2)
	t.check(not d.burning(north) and d.is_sealed(north) and absf(d.burned(north) - five) < 0.3,
		"an armed man back on guard seals it and puts its fire out; its seconds stay counted")
	Kit.free_body(s, keep.man)
	(s.crowd as Crowd).fires.ignite(north, 0.5)
	Kit.run_for(s, ArmouryDirector.SPOIL_SECONDS - five + 0.5)
	t.check(d.razed(north), "burned SPOIL_SECONDS in all while it musters: razed")
	Kit.done(s)


static func _reinforce(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	Kit.run_for(s, float(ArmouryDirector.REINFORCE[0]) + 0.6)
	var last: ArmouryDirector.Armed = d.armed[0].back()
	t.check(d.reinforced == 1 and last.reinforcement and last.relief and (last.man as Person).anchor == last.post
		and d.reserve.size() == ArmouryDirector.RESERVE - 1 and d.targets[0].distance_to(last.post) <= ArmouryDirector.GUARD_REACH,
		"REINFORCE after its horn an armed man runs from the armoury to a post within reach of it")
	var rates := []
	for at: float in [30.0, 125.0, 185.0, 250.0]:
		d._clock = at
		rates.append(d.arms_every())
	t.check(rates == [40.0, 30.0, 20.0, 12.0], "REINFORCE follows the clock's minute: 40, 30 in the third, 20 in the fourth, 12 from 4:00 (%s)" % [rates])
	Kit.done(s)


static func _reserve(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d.reserve.clear()
	d._muster(0)
	d._next_arms = 0.0
	Kit.free_body(s, (d.armed[0][0] as ArmouryDirector.Armed).man)
	Kit.run_for(s, ArmouryDirector.RELIEF_AFTER + 1.0)
	t.check(d.reinforced == 0 and d.reliefs == 0 and not MissionDirector._alive((d.armed[0][0] as ArmouryDirector.Armed).man),
		"the reserve spent: no reinforcement, no relief")
	Kit.done(s)
	var f := _world()
	var fd: ArmouryDirector = f.d
	var men := fd.reserve.duplicate()
	_clear(f, fd, 2)
	Kit.run_for(f, 0.1)
	fd.targets[2].destroy(fd.targets[2].center(), &"smite")
	Kit.run_for(f, 0.6)
	var out := true
	for v: Variant in men:
		out = out and (not MissionDirector._alive(v) or not (v as Person).inside)
	t.check(fd.reserve.is_empty() and out, "the armoury felled spends its reserve: they come out and go home (review focus 6)")
	Kit.done(f)


static func _relief(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var a: ArmouryDirector.Armed = d.armed[1][0]
	var dead: Variant = a.man
	Kit.free_body(s, dead)
	Kit.run_for(s, ArmouryDirector.RELIEF_AFTER + 1.0)
	var p: Variant = a.man
	t.check(p != dead and MissionDirector._alive(p) and not (p as Person).inside and (p as Person).anchor == a.post and a.relief
		and d.reserve.size() == ArmouryDirector.RESERVE - 1 and d.reliefs == 1 and (s.banners as Array).has("AN ARMED MAN RUNS FROM THE ARMOURY"),
		"RELIEF_AFTER after an armed man falls, one from the armoury's reserve runs to his post")
	var b: ArmouryDirector.Armed = d.armed[1][1]
	Kit.arrive(b.man as Person, d.targets[1].center() + Vector2(0.0, -7.0))
	(b.man as Person).mind = Person.Mind.CALM
	Kit.run_for(s, ArmouryDirector.RETURN_AFTER + 1.0)
	t.check((b.man as Person).mind == Person.Mind.DUTY and (b.man as Person).anchor == b.post,
		"one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	_clear(s, d, 0)
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	Kit.run_for(s, 0.1)
	var shown := d.timeline.seconds_to("horn_1")
	t.check(d.razed(d.targets[0]) and (s.banners as Array).has("THE NORTH BARRACKS IS RAZED") and shown <= ArmouryDirector.CHAIN + 0.1
		and String(Kit.labels(d)[0]).begins_with("BARRACKS - MUSTERS BY"), "razed while it musters; the next horn chained, CHAIN on (%.1f)" % shown)
	Kit.run_for(s, ArmouryDirector.CHAIN + DT)
	t.check(d.mustering[1] and (s.banners as Array).has("THE MUSTER HORN: THE GATE BARRACKS TURNS OUT"), "the gate barracks musters CHAIN after")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(main.hud_text(s.rules) == "Raze the garrison 0 / 3", "the main row before any horn")
	d._muster(0)
	t.check(main.hud_text(s.rules) == "Raze the garrison 0 / 3, armed men every 40 s", "while a target musters, the rate rides in the main row")
	for i in 3:
		d._muster(i)
		_clear(s, d, i)
		d.targets[i].destroy(d.targets[i].center(), &"smite")
	Kit.run_for(s, 0.1)
	t.check(d.all_razed() and main.check(s.rules) == Objective.Status.DONE and main.reason == "garrison"
		and main.hud_text(s.rules) == "Raze the garrison 3 / 3", "all three razed: the garrison is broken")
	Kit.done(s)
	var n := _world()
	var march: Objective = (n.rules as Rules).objectives[1]
	t.check(march.hud_text(n.rules) == "Garrison marches 5:00", "the deadline row (%s)" % march.hud_text(n.rules))
	(n.d as ArmouryDirector).timeline.step(ArmouryDirector.MARCH_AT + DT)
	t.check(march.check(n.rules) == Objective.Status.FAILED and march.reason == "marches" and (n.banners as Array).has("THE GARRISON MARCHES"),
		"left alone, the garrison marches at 5:00")
	Kit.done(n)


static func _evacuate(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(1)
	d._next_arms = 0.0
	Kit.run_for(s, 0.6)
	var runner: ArmouryDirector.Armed = d.armed[1].back()
	var rp := runner.man as Person
	var watch: ArmouryDirector.Armed = d.armed[1][0]
	var wp := watch.man as Person
	t.check(runner.reinforcement and rp.whisper(rp.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER),
		"(set-up) a reinforcement running in hears a whisper")
	wp.fearless_left = 0.0
	wp.mind = Person.Mind.RECOVER
	Kit.evacuate(s)
	t.check(wp.mind == Person.Mind.FLEE and rp._whisper_fled, "(set-up) the evacuation sends the recovering man running, and owes the whispered one a flight")
	Kit.run_for(s, 0.6)
	t.check(wp.mind == Person.Mind.DUTY and wp.anchor == watch.post and not rp._whisper_fled,
		"at the first look after it the night watch man is back on his post, the runner's flight ended")
	rp._wake()
	Kit.run_for(s, 0.6)
	var inside := true
	for v: Variant in d.reserve:
		inside = inside and (v as Person).inside
	t.check(rp.mind == Person.Mind.DUTY and rp.anchor == runner.post and inside and d.reserve.size() == ArmouryDirector.RESERVE - 1,
		"back on his feet the runner runs on to his post; the reserve stays inside the armoury")
	Kit.done(s)


static func _tower_reserved(t) -> void:
	var probe := _world()
	var ix := (probe.town as Town)._built.find((probe.d as ArmouryDirector).targets[1])
	Kit.done(probe)
	var s := Kit.world(MissionBook.armoury(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved_places.append(rules.town()._built[ix]))
	var d: ArmouryDirector = s.d
	t.check(ix >= 0 and d.targets[1].role == &"tower" and (s.town as Town)._built.find(d.targets[1]) != ix
		and d.targets[1].footprint.position.is_equal_approx(TownLayout.GATE_TOWERS[0].position),
		"a wish's east gate tower set aside: the gate barracks is the west one (review focus 5)")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 3) == ["BARRACKS - MUSTERS BY 0:40", "BARRACKS - MUSTERS BY 1:50", "ARMOURY - MUSTERS BY 3:00"]
		and Kit.edged(d, "ARMOURY - MUSTERS BY 3:00") and labels.has("ARMED") and d.hint_phase() == "",
		"before its horn each target is grey with its time, pointed at; ARMED on each man on guard (%s)" % [labels.slice(0, 3)])
	Kit.run_for(s, float(ArmouryDirector.STAGE_AT[0]) - ArmouryDirector.WORK_AHEAD + 1.0)
	t.check(d.hint_phase() == "barred", "within 25 s of its horn: barred")
	d._muster(0)
	t.check(Kit.labels(d)[0] == "BARRACKS - GUARDED" and d.hint_phase() == "guarded", "mustering, guarded")
	_clear(s, d, 0)
	Kit.run_for(s, 0.1)
	t.check(Kit.labels(d)[0] == "BARRACKS" and d.hint_phase() == "open", "none on guard: open")
	(s.crowd as Crowd).fires.ignite(d.targets[0], 0.5)
	Kit.run_for(s, 1.2)
	t.check(Kit.labels(d)[0] == "BARRACKS - BURNING 11", "burning, its seconds counted down (%s)" % Kit.labels(d)[0])
	d.targets[0].destroy(d.targets[0].center(), &"smite")
	d._muster(1)
	_clear(s, d, 1)
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "stone", "the gate barracks open: blows, not fire")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The north barracks. The muster horn calls it at 0:40."
		and String(tour[2][1]).begins_with("The armoury, last."), "the tour: the north barracks, the gate barracks, the armoury")
	t.check(ResultsScreen.ACT_TITLES.get("garrison") == "THE GARRISON IS BROKEN" and ResultsScreen.ACT_TITLES.get("marches") == "THE GARRISON MARCHES",
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: ArmouryDirector = s.d
	d._muster(0)
	for i in 3:
		_clear(s, d, i)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.guards(0).is_empty() and d.hint_phase() == "open" and int(d.report().razed) == 0,
		"every armed man out of doors freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_armoury.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then Tests. Expected: parse errors (`ArmouryDirector`, `MissionBook.armoury`).

- [ ] **Step 3: Create `src/game/mission/armoury_director.gd`:**

```gdscript
class_name ArmouryDirector
extends RazeDirector
## The Armoury (v0.11 M5, Tier 4, mission spec §2 with the controller's ruling replacing Decision 137; Raze, reused): the muster horn
## arms the garrison. Destroy the north barracks (the north tavern by the Citadel's lane, TownLayout.TAVERNS[0]), the gate barracks
## (the Main Gate's east tower, GATE_TOWERS[1]: stone, blows only) and the armoury (the barracks shed); a target a wish has set aside
## gives way to the west tavern or tower. Each musters on the chain (The Crown's Bread's stages, RazeDirector._spoilable()): the north
## barracks at STAGE_AT[0], each next at its own time or CHAIN after the one before is razed, whichever is sooner. Every blow lands
## from the start, but fire on a target not mustering is put out at once and its fall is judged only at its horn: one down then is
## razed at once. Two armed men -- lay citizens made watchmen -- stand each target's night watch from the start on posts along its
## face, POST_GAP apart; at its horn its squad of SQUAD comes out of its door to posts POST_GAP beyond them. An armed man on guard
## (alive, out of doors, within GUARD_REACH, not frightened or whispered) is held deaf to a whisper and past fear and set back on his
## post at every look; while one stands guard the target is sealed (RazeDirector.seal(): a blow only shakes it, its fire is put out),
## and the seconds it burned stay counted. One off his post walks back RETURN_AFTER after he left; a fallen one is replaced
## RELIEF_AFTER later from the armoury's reserve of RESERVE. From each horn, while a target musters, one armed man runs from the
## armoury every REINFORCE seconds (by the clock's minute) to the first mustering target. Razed -- fallen, or burned SPOIL_SECONDS in
## all while it musters -- its men go home. All three razed wins; the garrison marches at MARCH_AT (EventObjective) and loses
## (plan decisions 177-182).

## One armed man's post (v0.11 M5): a plain record, so the director holds no cycle.
class Armed:
	extends RefCounted
	## The man, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands on guard.
	var post := Vector2.INF
	## He is of the squad (indoors until his target's horn); a reinforcement from the armoury.
	var squad := false
	var reinforcement := false
	## Seconds since he was last on guard (alive but away), and since he fell.
	var away := 0.0
	var fallen := 0.0
	## He is running in (a relief or a reinforcement) until he first stands guard.
	var relief := false


## The targets' names on the tags, in words for the banners, and the strip's words at each horn (v0.11 M5, mission spec §2).
const NAMES := ["BARRACKS", "BARRACKS", "ARMOURY"]
const WORDS := ["north barracks", "gate barracks", "armoury"]
const HORN_LABELS := ["The muster horn: the north barracks turns out", "The muster horn: the gate barracks turns out",
	"The muster horn: the garrison arms"]
## Mission spec §2's numbers (v0.11 M5), first guesses, tuned by Step 7's gate in this order: SQUAD (1-3), STAGE_AT[0] (30-45), CHAIN
## (30-45), REINFORCE, SPOIL_SECONDS (10-15). The horns at the latest; the chain; the night watch and the squad; the posts; the reach;
## the burning; return and relief; reinforcements by the clock's minute; the reserve; the march.
const STAGE_AT := [40.0, 110.0, 180.0]
const CHAIN := 40.0
const NIGHT_WATCH := 2
const SQUAD := 2
const POST_GAP := 1.8
const GUARD_REACH := 2.5
const SPOIL_SECONDS := 12.0
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const REINFORCE := [40.0, 40.0, 30.0, 20.0, 12.0]
const RESERVE := 8
const MARCH_AT := 300.0
## How near its horn a target not mustering puts the hint on "barred" (v0.11 M5): the spec's "last 25 s".
const WORK_AHEAD := 25.0
## How long past each look an armed man on guard is kept deaf and fearless (v0.11 M5): more than a TICK, so neither lapses between looks.
const ARMED_HOLD := 1.0
## The minds that take an armed man off guard (v0.11 M5, plan decision 178): Discord's does not.
const OFF_GUARD := [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER, Person.Mind.WHISPERED]
## Where the camera rests (v0.11 M5, Decision 159): the north barracks just above the centre, the other two pointed at from the bottom.
const CAMERA_AT := Vector2(-5.5, -4.5)
## Seconds between looks at the armed men (v0.11 M5).
const TICK := 0.5

## Each target's Armed records, in the order of `targets` (v0.11 M5).
var armed: Array = []
## Each target musters yet; the second of the night it was razed (-1 until then); its face (v0.11 M5).
var mustering: Array[bool] = []
var razed_at: Array[float] = []
var faces: Array[Vector2] = []
## The armoury's reserve, waiting inside it (untyped: one may be freed); how many reinforcements and reliefs came (v0.11 M5).
var reserve: Array = []
var reinforced := 0
var reliefs := 0
## The second of the night the next reinforcement runs (-1 while nothing musters) (v0.11 M5).
var _next_arms := -1.0
## Reinforcements walking back into the armoury, their target razed (v0.11 M5).
var _returning: Array = []
## Seconds into the night, and to the next look (v0.11 M5).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M5): the three targets, kept from the town's teams; at each its night watch set down and kept on duty on
## its face and its squad taken indoors; the reserve inside the armoury; each horn and the march on the strip.
func _begin() -> void:
	targets.assign(_find_targets())
	spoil_seconds = SPOIL_SECONDS
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(targets)
	for i in targets.size():
		mustering.append(false)
		razed_at.append(-1.0)
		faces.append(_face(targets[i]))
		var list: Array = []
		armed.append(list)  # first, so _busy() leaves out the men this target has already
		for k in NIGHT_WATCH + SQUAD:
			list.append(_appoint(i, k, k >= NIGHT_WATCH))
	var store := _armoury()
	if store != null:
		for k in RESERVE:
			var near := _lay_near(faces[targets.find(store)], 1, _busy())
			if near.is_empty():
				break
			var p := near[0]
			p.profile.role = CitizenProfile.Role.WATCHMAN
			_set_down(p, p.ground_pos)
			p.go_duty(p.ground_pos)
			_take_inside(p, store)
			reserve.append(p)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		timeline.add(float(STAGE_AT[i]), "horn_%d" % i, String(HORN_LABELS[i]), _muster.bind(i),
			func() -> bool: return not mustering[i] and not razed(targets[i]))
	timeline.add(MARCH_AT, "march", "The garrison marches", Callable(), func() -> bool: return not all_razed())
	rules.banner.emit("THE ARMOURY")


## The north barracks, the gate barracks and the armoury (v0.11 M5, Decision 136), those the town has; a target a wish has set aside
## gives way to the next named.
func _find_targets() -> Array[Structure]:
	var out: Array[Structure] = []
	for rects: Array in [[TownLayout.TAVERNS[0], TownLayout.TAVERNS[1]], [TownLayout.GATE_TOWERS[1], TownLayout.GATE_TOWERS[0]],
			[TownLayout.BARRACKS]]:
		var s := _built_at(rects)
		if s != null:
			out.append(s)
	return out


## The first standing building whose footprint is one of `rects`, in order, not set aside by a wish (v0.11 M5); null for none.
func _built_at(rects: Array) -> Structure:
	for r: Rect2 in rects:
		for s: Structure in town._built:
			if is_instance_valid(s) and not s.destroyed and s.footprint.position.is_equal_approx(r.position) and not reserved_places.has(s):
				return s
	return null


## The armoury among the targets (v0.11 M5): the barracks shed; null for none.
func _armoury() -> Structure:
	for s in targets:
		if is_instance_valid(s) and s.kind == Structure.Kind.BARRACKS:
			return s
	return null


## Target `s`'s face (v0.11 M5, plan decision 181): a tower's town side (its -y face); else the door the nearest town gate's street
## reaches (The Crown's Bread's rule).
func _face(s: Structure) -> Vector2:
	if s.role == &"tower":
		return _walkable(s.center() - Vector2(0.0, s.footprint.size.y * 0.5 + 0.5))
	var gate := Vector2.INF
	for g: Structure in town.gates:
		if is_instance_valid(g) and (gate == Vector2.INF or g.center().distance_to(s.center()) < gate.distance_to(s.center())):
			gate = g.center()
	var door := _open_door(s, _walkable(gate)) if gate != Vector2.INF else Vector2.INF
	return door if door != Vector2.INF else _front_of(s)


## The `k`th post of target `i` (v0.11 M5): along its face, the night watch POST_GAP apart about its centre, the squad POST_GAP beyond
## them; reinforcements in a second row half POST_GAP out, the same spacing (within GUARD_REACH of it, beyond one Doom of the first row).
func _post(i: int, k: int) -> Vector2:
	var face := faces[i]
	var out := face - targets[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var wide := 0.5 if (k / 2) % 2 == 0 else 1.5
	var depth := 0.0 if k < NIGHT_WATCH + SQUAD else POST_GAP * 0.5
	return _walkable(face + out * depth + along * side * POST_GAP * wide)


## An armed man for target `i` at its `k`th post (v0.11 M5): the free lay citizen nearest it, made a watchman, set down and kept on duty
## there; a squad man goes indoors in the target until its horn.
func _appoint(i: int, k: int, squad: bool) -> Armed:
	var a := Armed.new()
	a.post = _post(i, k)
	a.squad = squad
	var near := _lay_near(a.post, 1, _busy())
	if near.is_empty():
		return a
	var p := near[0]
	p.profile.role = CitizenProfile.Role.WATCHMAN
	a.man = p
	_set_down(p, a.post)
	p.go_duty(a.post)
	if squad:
		_take_inside(p, targets[i])
	return a


## Everyone the director has armed (v0.11 M5), for a new one to leave out.
func _busy() -> Array:
	var out: Array = reserve.duplicate()
	out.append_array(_returning)
	for list: Array in armed:
		for a: Armed in list:
			if a.man != null:
				out.append(a.man)
	return out


## Target `s` can be razed: it musters (v0.11 M5; RazeDirector._spoilable()).
func _spoilable(s: Structure) -> bool:
	var i := targets.find(s)
	return i >= 0 and i < mustering.size() and mustering[i]


## The second of the night target `i` musters at the latest (v0.11 M5): its own time, or CHAIN after the one before is razed if sooner.
func stage_due(i: int) -> float:
	var at := float(STAGE_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and razed_at[i - 1] >= 0.0:
		at = minf(at, razed_at[i - 1] + CHAIN)
	return at


## Seconds until target `i` musters at the latest (v0.11 M5); 0 once it does.
func due_in(i: int) -> float:
	return 0.0 if mustering[i] else maxf(stage_due(i) - _clock, 0.0)


## Each target not mustering whose chained time has come musters (v0.11 M5); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		if not mustering[i] and not razed(targets[i]) and razed_at[i - 1] >= 0.0 and _clock >= stage_due(i):
			rules.banner.emit(String(HORN_LABELS[i]).to_upper())
			_muster(i)


## Target `i`'s horn (v0.11 M5): it musters, its squad comes out at its door to its posts, and the reinforcement clock starts anew.
func _muster(i: int) -> void:
	if mustering[i]:
		return
	mustering[i] = true
	for a: Armed in armed[i]:
		if a.squad and _alive(a.man) and (a.man as Person).inside:
			var p := a.man as Person
			var door := _open_door(targets[i], a.post) if is_instance_valid(targets[i]) else Vector2.INF
			_bring_out(p, door if door != Vector2.INF else faces[i])
			_keep_from_flight(p, true)
			p.go_duty(a.post)
	_next_arms = _clock + arms_every()


## Seconds between reinforcements now (v0.11 M5, plan decision 179): REINFORCE by the clock's minute.
func arms_every() -> float:
	return float(REINFORCE[mini(int(_clock / 60.0), REINFORCE.size() - 1)])


## One step (v0.11 M5): each target sealed while guarded, the Raze type's (the timeline, each target judged), the chain, then every
## frame each target's armed men at their work, and every TICK the reinforcements, the reserve and those walking back.
func step(delta: float) -> void:
	_clock += delta
	_guard_seals()
	super(delta)
	_chain()
	_tick_in -= delta
	var looking := _tick_in <= 0.0
	var evacuating := false
	if looking:
		_tick_in = TICK
		evacuating = _evacuation_began()
	for i in targets.size():
		if not razed(targets[i]):
			_work(i, delta, looking, evacuating)
	if looking:
		_arms()
		_keep_reserve()
		_back_inside(evacuating)


## Each standing target not razed is sealed while an armed man stands guard, and open while none does (v0.11 M5, plan decision 177).
func _guard_seals() -> void:
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s) or s.destroyed:
			continue
		var held := not guards(i).is_empty()
		if held and not is_sealed(s):
			seal(s)
		elif not held and is_sealed(s):
			unseal(s)


## Armed man `a` of target `i` stands guard now (v0.11 M5): alive, out of doors, not in OFF_GUARD, within GUARD_REACH of it.
func _on_guard(i: int, a: Armed) -> bool:
	if not _alive(a.man):
		return false
	var p := a.man as Person
	return not p.inside and not p.mind in OFF_GUARD and is_instance_valid(targets[i]) and targets[i].distance_to(p.ground_pos) <= GUARD_REACH


## Target `i`'s armed men on guard now (v0.11 M5). Only reads.
func guards(i: int) -> Array[Person]:
	var out: Array[Person] = []
	if i < 0 or i >= armed.size():
		return out
	for a: Armed in armed[i]:
		if _on_guard(i, a):
			out.append(a.man as Person)
	return out


## Target `i`'s armed men at their work (v0.11 M5): each out of doors kept out of the town's flight; one on guard held deaf and fearless
## and set back on his post; one off his post walks back RETURN_AFTER after he left (a man running in runs on at once); a fallen one is
## replaced RELIEF_AFTER after he fell, from the reserve.
func _work(i: int, delta: float, looking: bool, evacuating: bool) -> void:
	for a: Armed in armed[i]:
		if not _alive(a.man):
			a.fallen += delta
			if looking and a.fallen >= RELIEF_AFTER:
				_relieve(i, a)
			continue
		a.fallen = 0.0
		var p := a.man as Person
		if p.inside:
			continue
		if looking:
			_keep_from_flight(p, evacuating)
		if _on_guard(i, a):
			a.away = 0.0
			a.relief = false
			if looking:
				p._shaken_left = maxf(p._shaken_left, ARMED_HOLD)
				p.fearless_left = maxf(p.fearless_left, ARMED_HOLD)
				if p.mind != Person.Mind.DUTY or p.anchor.distance_to(a.post) > 0.3:
					p.go_duty(a.post)
		else:
			a.away += delta
			if looking and (a.relief or a.away >= RETURN_AFTER):
				_recall_to(p, a.post)


## A relief for fallen armed man `a` of target `i` from the reserve (v0.11 M5); none once it is spent.
func _relieve(i: int, a: Armed) -> void:
	var p := _from_reserve(a.post)
	if p == null:
		return
	a.man = p
	a.fallen = 0.0
	a.away = 0.0
	a.relief = true
	reliefs += 1
	rules.banner.emit("AN ARMED MAN RUNS FROM THE ARMOURY")


## The next of the reserve, out of the armoury's door and running on duty to `post` (v0.11 M5); null once it is spent.
func _from_reserve(post: Vector2) -> Person:
	var store := _armoury()
	while not reserve.is_empty():
		var v: Variant = reserve.pop_front()
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside:
			var door := _open_door(store, post) if store != null and is_instance_valid(store) else Vector2.INF
			_bring_out(p, door if door != Vector2.INF else faces[maxi(targets.find(store), 0)])
		_keep_from_flight(p, true)
		p.go_duty(post)
		return p
	return null


## The first target that musters and is not razed, or -1 (v0.11 M5).
func mustering_now() -> int:
	for i in targets.size():
		if mustering[i] and not razed(targets[i]):
			return i
	return -1


## A reinforcement when its time has come (v0.11 M5, plan decision 179): one man from the reserve to a new post of the first mustering
## target; the clock stops while nothing musters.
func _arms() -> void:
	if _next_arms < 0.0 or _clock < _next_arms:
		return
	var i := mustering_now()
	if i < 0:
		_next_arms = -1.0
		return
	_next_arms = _clock + arms_every()
	var a := Armed.new()
	a.reinforcement = true
	a.post = _post(i, armed[i].size())
	var p := _from_reserve(a.post)
	if p == null:
		return
	a.man = p
	a.relief = true
	armed[i].append(a)
	reinforced += 1


## The armoury down spends the reserve (v0.11 M5, plan decision 180): each comes out at its door and goes home.
func _keep_reserve() -> void:
	var store := _armoury()
	if reserve.is_empty() or (store != null and is_instance_valid(store) and not store.destroyed and not razed(store)):
		return
	for v: Variant in reserve:
		if not _alive(v):
			continue
		var p := v as Person
		if p.inside:
			_bring_out(p, faces[maxi(targets.find(store), 0)])
		_keep_from_flight(p, true)
		_release_man(p)
	reserve.clear()


## Reinforcements walking back (v0.11 M5): at the armoury's door one goes in again, back in the reserve; with the armoury down he goes
## home.
func _back_inside(evacuating: bool) -> void:
	var store := _armoury()
	for v: Variant in _returning.duplicate():
		if not _alive(v) or (v as Person).inside:
			_returning.erase(v)
			continue
		var p := v as Person
		_keep_from_flight(p, evacuating)
		if store == null or not is_instance_valid(store) or store.destroyed or razed(store):
			_returning.erase(v)
			_release_man(p)
			continue
		var door := faces[targets.find(store)]
		if p.ground_pos.distance_to(door) <= 0.6:
			_take_inside(p, store)
			reserve.append(p)
			_returning.erase(v)
		else:
			_recall_to(p, door)


## Razed (v0.11 M5): unsealed for good; the next horn chained and on the strip; its men go home, but a reinforcement still running in
## walks back into the armoury.
func _on_razed(s: Structure) -> void:
	var i := targets.find(s)
	unseal(s)
	rules.banner.emit("THE %s IS RAZED" % String(WORDS[i]).to_upper())
	razed_at[i] = _clock
	if timeline != null and i + 1 < targets.size():
		timeline.expect("horn_%d" % (i + 1), stage_due(i + 1))
	var store := _armoury()
	for a: Armed in armed[i]:
		if not _alive(a.man):
			continue
		var p := a.man as Person
		if a.reinforcement and a.relief and not p.inside and store != null and s != store:
			_returning.append(p)
			p.go_duty(faces[targets.find(store)])
			continue
		if p.inside:
			_bring_out(p, faces[i])
			_keep_from_flight(p, true)
		_release_man(p)
	if mustering_now() < 0:
		_next_arms = -1.0


## An armed man goes home (v0.11 M5, Spoiled Harvest's _release()): the hold ends; one on duty stood down, one calm sent home.
func _release_man(p: Person) -> void:
	if p.fearless_left <= ARMED_HOLD:
		p.fearless_left = 0.0
	if p.mind == Person.Mind.DUTY:
		crowd.off_duty(p)
	elif p.mind in HarvestDirector.GUARD_MINDS and p.profile != null:
		p.regroup(p.profile.home)


## The current target (v0.11 M5): the first not razed, or -1.
func current() -> int:
	for i in targets.size():
		if not razed(targets[i]):
			return i
	return -1


## The first target not razed and not mustering, or -1 (v0.11 M5).
func upcoming() -> int:
	for i in targets.size():
		if not razed(targets[i]) and not mustering[i]:
			return i
	return -1


## A relief or reinforcement of target `i` running in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking(i: int) -> Person:
	for a: Armed in armed[i]:
		if a.relief and _alive(a.man) and not (a.man as Person).inside and not _on_guard(i, a):
			return a.man as Person
	return null


## The HUD's main row while a target musters and the reserve lasts (v0.11 M5, plan decision 182); "" for RazeObjective's own.
func hud_line() -> String:
	if mustering_now() < 0 or reserve.is_empty():
		return ""
	return "Raze the garrison %d / %d, armed men every %d s" % [razed_count(), targets.size(), roundi(arms_every())]


## The map tags, most important first (v0.11 M5, mission spec §2, plan decision 206): each target not razed, pointed at -- not
## mustering, grey, "MUSTERS BY" its chained time or "DOWN, COUNTS AT" it; mustering, gold, GUARDED while one stands guard, orange
## and its seconds left while it burns -- then each armed man: ARMED on guard, a red diamond on one running in, a small red mark on
## one away.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s):
			continue
		var name := String(NAMES[i])
		if not mustering[i]:
			var when := UiTheme.clock(stage_due(i))
			var label := "%s - DOWN, COUNTS AT %s" % [name, when] if s.destroyed else "%s - MUSTERS BY %s" % [name, when]
			out.append(MapTag.place(s.center(), MARK_SEALED, label, s.height, true))
		elif not guards(i).is_empty():
			out.append(MapTag.place(s.center(), MARK_TARGET, "%s - GUARDED" % name, s.height, true))
		elif burning(s):
			var left := ceili(maxf(SPOIL_SECONDS - burned(s), 0.0))
			out.append(MapTag.place(s.center(), MARK_BURNING, "%s - BURNING %d" % [name, left], s.height, true))
		else:
			out.append(MapTag.place(s.center(), MARK_TARGET, name, s.height, true))
	for i in targets.size():
		if razed(targets[i]):
			continue
		for a: Armed in armed[i]:
			if not _alive(a.man) or (a.man as Person).inside:
				continue
			var p := a.man as Person
			if _on_guard(i, a):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, "ARMED"))
			elif a.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5), for the current target: not mustering, "barred" when down or WORK_AHEAD or less from its horn, else "";
## mustering, "guarded" while one stands guard, else "stone" for a target fire cannot take, else "open".
func hint_phase() -> String:
	var i := current()
	if i < 0:
		return ""
	var s := targets[i]
	if not mustering[i]:
		return "barred" if (is_instance_valid(s) and s.destroyed) or due_in(i) <= WORK_AHEAD else ""
	if not guards(i).is_empty():
		return "guarded"
	return "stone" if is_instance_valid(s) and not s.kind in FireManager.BURNABLE else "open"


## The tour (v0.11 M5, mission spec §2): the north barracks, the gate barracks, the armoury.
func tour() -> Array:
	var words := ["The north barracks. The muster horn calls it at %s.", "The gate barracks, by %s. It is stone: blows, not fire.",
		"The armoury, last. It arms the garrison, faster each minute."]
	var out := []
	for i in targets.size():
		var line := String(words[i]) % UiTheme.clock(float(STAGE_AT[i])) if i < 2 else String(words[i])
		out.append([faces[i], line])
	return out


## What the results show (v0.11 M5): the targets razed, the reinforcements and the reliefs.
func report() -> Dictionary:
	return {"razed": razed_count(), "reinforced": reinforced, "reliefs": reliefs}


## Lets go of the town's engineers' list, then the Raze type's (every seal) (v0.11 M5).
func teardown() -> void:
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s in targets:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
```

- [ ] **Step 4: The mission.**
  - In `src/game/mission/mission_book.gd`, `tier_missions()`'s list gains `armoury()` after `bishop()`, and after `bishop()` add:

```gdscript
## The Armoury (v0.11 M5, Tier 4, mission spec §2 and §8 row 18): raze the north barracks, the gate barracks and the armoury, each while
## it musters at its horn, guarded by armed men who come faster each minute, before the garrison marches (ArmouryDirector, the Raze
## type reused on M4's stages).
static func armoury() -> MissionDef:
	var m := _tier4(ARMOURY, "The Armoury", PackedStringArray(["The muster horn arms the garrison.",
		"Destroy the armoury and two barracks."]))
	m.goal = "Destroy the two barracks and the armoury, each while it musters, before the garrison marches at %s" % UiTheme.clock(
		ArmouryDirector.MARCH_AT)
	m.goal_label = "The garrison is broken"
	m.lose = "The garrison marches, or dawn comes"
	m.camera_at = ArmouryDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember", "heaven"])
	m.director = ArmouryDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [RazeObjective.new("Raze the garrison", "garrison"), EventObjective.new("march", "Garrison marches", "marches"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

  - In `mission_hints.gd` `LINES`, after the `bishop` entries, add (and the same five rows, under `# The Armoury (v0.11 M5).`, in
    `tests/test_mission_hints.gd` `SPEC`):

```gdscript
	"armoury": "Kill a target's armed men (red), then destroy it (gold) while it musters: the north barracks, the gate barracks, the armoury.",
	"armoury.barred": "Not mustering yet (grey): fire goes out, and a fall counts when its horn sounds. Kill its night watch (red) shortly before.",
	"armoury.guarded": "Armed men (red) guard it: it takes no harm. Kill every one. Whispers do not move an armed man.",
	"armoury.open": "No guard stands. Destroy it now: more armed men come from the armoury, faster each minute.",
	"armoury.stone": "The gate barracks is stone: blows, not fire.",
```

  - In `results_screen.gd` `ACT_TITLES`, add `"garrison": "THE GARRISON IS BROKEN", "marches": "THE GARRISON MARCHES"`.

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 35.

- [ ] **Step 6: The behaviour scenario.** In `tools/dev/behaviour_check.gd`:
  - In the header's usage, after the `bishop` entry, add:

```gdscript
##   armoury  (v0.11 M5) The Armoury, --case=none (nothing cast) or play, as a player plays it (_armoury_act(): the mustering target
##          with an armed man on guard: Smite one within Smite's reach of it (he falls and it takes the blow), else Silent Doom on one
##          alone (else the first); none on guard: Ember a barracks or the armoury not burning (Smite it while Ember cools), Heaven
##          Splitter through the gate barracks (Smite it while Heaven cools); the next horn within 25 s, its night watch cleared with
##          Silent Doom; else Silent Doom on a reinforcement or relief running in; the result line gives the longest idle stretch).
##          Hit-stop is off for it. --seed=, --board as ringers.
```

  - After `BISHOP_AHEAD` add:

```gdscript
## The Armoury's policy (v0.11 M5): how near its horn the next target's night watch is cleared.
const ARMOURY_AHEAD := 25.0
```

  - In `_run()`, after the `bishop` branch add:

```gdscript
	elif scenario == "armoury":
		powers = PackedStringArray(["doom", "smite", "ember", "heaven"])
		mission.mission_id = MissionBook.ARMOURY
```

  - In `_run()`'s `match scenario:`, before `"warning":`, add:

```gdscript
		"armoury":
			await _armoury(Battlefield.arg_value(args, "--case"))
```

  - After `_none_within()` add:

```gdscript
## The Armoury (v0.11 M5), with mission spec §2's policy (_armoury_act()), through _scripted().
func _armoury(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as ArmouryDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("armoury", which, func() -> String: return _armoury_act(rules, slots, d, crowd),
		func() -> String: return "razed=%d mustering=%d guards=%d reinforced=%d reserve=%d phase=%s" % [d.razed_count(), d.mustering_now(),
			d.guards(d.current()).size(), d.reinforced, d.reserve.size(), d.hint_phase()])


## One look of The Armoury's policy (v0.11 M5): what was cast, or "". The first that applies: the mustering target with an armed man on
## guard, Smite one within Smite's reach of it, else clear one with Silent Doom (_knight_clear(), no Smite); with none on guard, Ember a
## barracks or the armoury not burning (Smite it while Ember cools), or Heaven Splitter through the gate barracks (Smite it while
## Heaven cools); the next horn within ARMOURY_AHEAD, its night watch cleared with Silent Doom; a reinforcement or relief running in,
## Silent Doom on him.
func _armoury_act(rules: Rules, slots: Dictionary, d: ArmouryDirector, crowd: Crowd) -> String:
	var cur := d.mustering_now()
	if cur >= 0:
		var s := d.targets[cur]
		var word := String(ArmouryDirector.WORDS[cur])
		var on := d.guards(cur)
		if not on.is_empty():
			if _slot_ready(rules, slots, "smite"):
				for p in on:
					if is_instance_valid(s) and s.distance_to(p.ground_pos) <= SmiteFx.HIT_R:
						rules.cast(slots.smite, p.ground_pos)
						return "smite an armed man at the %s" % word
			var did := _knight_clear(rules, slots, crowd, on, false)
			if did != "":
				return did
		elif is_instance_valid(s) and not s.destroyed:
			if s.kind in FireManager.BURNABLE:
				if not d.burning(s):
					if _slot_ready(rules, slots, "ember"):
						rules.cast(slots.ember, s.center())
						return "ember the %s" % word
					if _slot_ready(rules, slots, "smite"):
						rules.cast(slots.smite, s.center())
						return "smite the %s" % word
			elif _slot_ready(rules, slots, "heaven"):
				rules.cast(slots.heaven, s.center(), {"dir": Vector2.RIGHT})
				return "heaven splitter through the %s" % word
			elif _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the %s" % word
	var next := d.upcoming()
	if next >= 0 and next != cur and d.due_in(next) <= ARMOURY_AHEAD:
		var ahead := d.guards(next)
		if not ahead.is_empty():
			var did := _knight_clear(rules, slots, crowd, ahead, false)
			if did != "":
				return did
	if cur >= 0:
		var walker := d.relief_walking(cur)
		if walker != null and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, walker.ground_pos)
			return "doom a man running in"
	return ""
```

- [ ] **Step 7: The gate.** Run the Scenario loop for `armoury`.
  - Expected for `none`: `won=false reason=marches` in each, at 300.0.
  - For `play`: the gate. The spec expects about 3:20 (its sum: 40 + 25 + 40 + 20 + 40 + 35 ≈ 200 s). Write the measured clear and
    its sum in the commit body.
  - If it misses: first read the play log against the policy (does it clear the next night watch in the last 25 s, does it idle with
    a slot ready, does the fire brigade beat out a barracks' fire -- name it if so); then tune in this order: `SQUAD` (1-3),
    `STAGE_AT[0]` (30-45), `CHAIN` (30-45), `REINFORCE`, `SPOIL_SECONDS` (10-15).
  - Run each seed twice for one case: the checksums must repeat (hit-stop is off).
  - Then the Scenario loop for `bishop` (Task 2's six), M3's eighteen and M4's eighteen. These six `armoury` lines are references
    from here on.

- [ ] **Step 8: The Reference check.** Expected: every value unchanged (Spoiled Harvest's six and The Crown's Bread's six among them).

- [ ] **Step 9: Spec sync.** In the mission spec's §2, bring the `Numbers` line, the timeline table, `The clear` and the hint lines to
  what landed; rewrite its seals text (the opening paragraph's "Seals, not stages", **Barred**, the `barred` hint, the tag "barred",
  the HUD row and "How it differs") to the controller's staged ruling and plan decisions 177, 182 and 206, and Decision 137's line to
  "replaced by the controller's ruling: M4's stages". Change nothing else in the spec.

- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/armoury_director.gd src/game/mission/armoury_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd tests/test_armoury.gd tests/test_armoury.gd.uid tests/test_mission_hints.gd tests/run_all.gd docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md
git commit -m "feat: The Armoury -- two barracks and an armoury mustering on the chain, armed men faster each minute (v0.11 M5)" -m "<the six armoury lines and checksums, the gate's verdict, the measured clear and its sum, any tuning rounds; bishop's six, M3's and M4's 36 unchanged>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: The Sermon (Convert, reused)

**Files:**
- Create: `src/game/mission/sermon_director.gd`, `tests/test_sermon.gd`
- Modify: `src/game/mission/mission_book.gd` (new `sermon()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd` (`LINES`), `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `tools/dev/behaviour_check.gd` (usage, consts, `_run()`, new `_sermon()` / `_sermon_act()`)
- Modify: `tests/test_mission_hints.gd` (`SPEC`), `tests/run_all.gd`
- Modify: the mission spec's §3 (synced, Step 9)

**Interfaces:**
- Consumes: Task 1's `MirasHouseDirector.lost_reason()`, `BelieversObjective._init(text, won, few)`, `TempleReport.skip`, `_tier4()`,
  `SERMON`; Task 2's `_none_within()`; `MirasHouseDirector`'s `house`, `door`, `temple_door`, `grieving`, `believers`, `need`,
  `read_seconds`, `venn`, `_turned`, `_find_house()`, `_door_of()`, `_choose_people()`, `_add_events()`, `_step_events()`,
  `_opening_banner()`, `_house_label()`, `_roof()`, `_exit()`, `_on_killed()`, `believers_outside()`, `MARK_*`, `SIGHT`;
  `MissionDirector`'s `faithful`, `reports`, `reports_started`, `_report()`, `_sees()`, `faithful_seeing()`, `_make_faithful()`,
  `_spread_faithful()`, `_sort_citizens()`, `_lay_near()`, `_citizen_near()`, `_house_near()`, `_open_door()`, `_ring_spot()`,
  `_set_down()`, `_recall_to()`, `_lay_reaching()`, `_keep_from_flight()`, `_evacuation_began()`; `Rules.cast_refused`.
- Produces:
  - `SermonDirector`: inner `Listener` (`man`, `wave`, `source`, `spot`), `Sentry` (`man`, `post`, `away`, `fallen`, `relief`);
    `HOUSE_SPOT`, `SOURCES`, `NEED`, `WAVE`, `WAVES`, `WAVE_AT`, `CHAIN`, `VOICE`, `RING`, `ACOLYTE_OFF`, `READ`, `SENTRIES`,
    `SENTRY_OFF`, `RETURN_AFTER`, `RELIEF_AFTER`, `RELIEFS`, `FAITHFUL_LAY`, `BELIEVER_RING`, `SERMON_ENDS`, `PREACH_REACH`, `HOLD`,
    `CAMERA_AT`; `pulpit`, `preacher`, `acolytes`, `listeners`, `sentries`, `called`, `spent_at`, `reliefs`; `preaching()`,
    `rapt(v)`, `held(v)`, `spent(w)`, `wave_due(w)`, `due_in(w)`, `next_wave()`, `unturned()`, `sentries_on_guard()`,
    `relief_walking()`, `lost_reason()`, `_believer_spot(p)`, `_call_wave(w)`, `_on_refused(slot, why)`.
  - `MissionBook.sermon() -> MissionDef`; the scenario `--scenario=sermon`; six references.

- [ ] **Step 1: Write the failing test.** Create `tests/test_sermon.gd`:

```gdscript
extends RefCounted
## v0.11 M5 The Sermon (mission spec §3, SermonDirector, MirasHouseDirector reused): a preacher at the south-west well holds his crowd
## rapt -- deaf to a whisper, past fear, on duty -- while he preaches; silenced (held, or dead) he frees them. Twelve listeners in four
## waves of three, the waiting ones held at their sources until their wave walks in on the chain. A listener whispered to the god's
## house goes in unseen, reads, and comes out a Believer who stands by the door; seen by a sentry he is turned away and reported, the
## relay passing over the fleeing. Sentries return and are relieved. Eight Believers win; too few left to turn, the Gaze or the sermon's
## end lose. The god's house only shakes. The evacuation passes them by (review focus 2); freed bodies are borne (review focus 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_house(t)
	_rapt(t)
	_silenced(t)
	_turned(t)
	_believe(t)
	_flock(t)
	_waves(t)
	_sentries(t)
	_evacuate(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.sermon())


## Wave `w`'s listeners in `d`, untyped (v0.11 M5 tests).
static func _wave(d: SermonDirector, w: int) -> Array:
	var out := []
	for l: SermonDirector.Listener in d.listeners:
		if l.wave == w:
			out.append(l)
	return out


## Wave `w`'s listeners set down at their places on the ring (v0.11 M5 tests: headless people never walk).
static func _seat(d: SermonDirector, w: int) -> void:
	for l: SermonDirector.Listener in _wave(d, w):
		if MissionDirector._alive(l.man) and not (l.man as Person).inside:
			Kit.arrive(l.man as Person, l.spot)


## The preacher held by Discord (it never lifts headless) and his crowd's hold let go by hand, as it lapses (v0.11 M5 tests).
static func _silence(d: SermonDirector) -> void:
	(d.preacher as Person).confuse(60.0)
	for l: SermonDirector.Listener in d.listeners:
		if MissionDirector._alive(l.man):
			(l.man as Person)._shaken_left = 0.0


## The two sentries killed and freed (v0.11 M5 tests).
static func _unwatch(s: Dictionary, d: SermonDirector) -> void:
	for st: SermonDirector.Sentry in d.sentries:
		if MissionDirector._alive(st.man):
			Kit.free_body(s, st.man)


static func _setup(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	t.check(d.house != null and RuinWish.fits(d.house, "house") and d.door.distance_to(d.pulpit) > SermonDirector.VOICE
		and d.house.damage_filter.is_valid() and d.house.center().distance_to(SermonDirector.HOUSE_SPOT) < 5.0,
		"the god's house: a dwelling by the west wall, beyond VOICE of the pulpit, its door reached by the street")
	var seen := {}
	var ok := d.listeners.size() == SermonDirector.WAVES * SermonDirector.WAVE
	for l: SermonDirector.Listener in d.listeners:
		var p := l.man as Person
		ok = ok and p != null and not seen.has(p) and p.mind == Person.Mind.DUTY and not d.faithful.has(p) \
			and p.anchor == (l.spot if l.wave == 0 else l.source)
		seen[p] = true
	t.check(ok and _wave(d, 3).size() == 3, "twelve listeners in four waves of three: the first walks in, the rest wait on duty at their sources")
	var pr := d.preacher as Person
	var near := true
	for a: Variant in d.acolytes:
		var gap := (a as Person).ground_pos.distance_to(pr.ground_pos)
		near = near and (a as Person).profile.role == CitizenProfile.Role.CLERGY and gap > SilentDoom.RADIUS and gap <= DiscordFx.DISCORD_R + 0.05
	t.check(pr.profile.role == CitizenProfile.Role.CLERGY and pr.mind == Person.Mind.DUTY and pr.ground_pos.distance_to(d.pulpit) < 0.1
		and d.preaching() and d.acolytes.size() == 2 and near and d.faithful.has(pr),
		"the preacher, a cleric, preaches at the well; his two acolytes beside him, within one Discord, beyond one Doom")
	var posted := d.sentries.size() == SermonDirector.SENTRIES
	for st: SermonDirector.Sentry in d.sentries:
		var p := st.man as Person
		posted = posted and p.profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p) and p.mind == Person.Mind.DUTY \
			and p.ground_pos.distance_to(st.post) < 0.1 and p.ground_pos.distance_to(d.door) <= MirasHouseDirector.SIGHT
	posted = posted and (d.sentries[0].man as Person).ground_pos.distance_to((d.sentries[1].man as Person).ground_pos) > Crowd.DOOM_WITNESS
	t.check(posted, "two sentries, Faithful watchmen, each seeing the door, beyond one witness of each other")
	var lay := 0
	for f in d.faithful:
		lay += 1 if f.profile.role != CitizenProfile.Role.CLERGY and f.profile.role != CitizenProfile.Role.WATCHMAN else 0
	t.check(lay == SermonDirector.FAITHFUL_LAY, "every cleric and eight lay of the rest are Faithful (%d lay)" % lay)
	var ids := []
	for e in d.timeline.upcoming(4):
		ids.append(e.id)
	t.check(ids == ["wave_1", "wave_2", "wave_3", "ends"], "the strip: three waves, then the sermon's end (%s)" % [ids])
	var clear := Kit.clear_of_stack(d.pulpit, SermonDirector.CAMERA_AT) and Kit.clear_of_stack(d.door, SermonDirector.CAMERA_AT) \
		and Kit.clear_of_stack(d.temple_door, SermonDirector.CAMERA_AT)
	for w in range(1, SermonDirector.WAVES):
		clear = clear and Kit.clear_of_stack(d._wave_source(w), SermonDirector.CAMERA_AT)
	t.check(clear, "the camera keeps the pulpit, the god's house, the Temple and the waves' sources (or their arrows) clear of the HUD stack")
	var m := MissionBook.sermon()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and reasons == ["gaze", "sermon", "sermon_over"] and d.need == SermonDirector.NEED
		and is_equal_approx(d.read_seconds, SermonDirector.READ) and Array(m.default_loadout) == ["whisper", "discord", "doom", "wisp"]
		and MissionBook.get_mission("sermon").id == "sermon", "the mission: Tier 4's numbers; the Gaze, the crowd, the sermon's end (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := (d.preacher as Person).mind == Person.Mind.DUTY
	for l: SermonDirector.Listener in d.listeners:
		held = held and (l.man as Person).mind == Person.Mind.DUTY
	for st: SermonDirector.Sentry in d.sentries:
		held = held and (st.man as Person).mind == Person.Mind.DUTY
	for a: Variant in d.acolytes:
		held = held and (a as Person).mind == Person.Mind.DUTY
	t.check(held, "the regroup and the evacuation pass the preacher, his acolytes, his crowd and the sentries by (review focus 2)")
	Kit.done(s)


static func _house(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var hp := d.house.hp
	d.house.damage(60.0, d.house.center(), &"smite")
	(s.crowd as Crowd).fires.ignite(d.house, 0.5)
	Kit.run_for(s, 0.1)
	t.check(is_equal_approx(d.house.hp, hp) and not d.house.destroyed and not (s.crowd as Crowd).fires.is_burning(d.house),
		"the god's house only shakes tonight, and its fire is put out (review focus 6)")
	var house := d.house
	d.teardown()
	t.check(not house.damage_filter.is_valid(), "teardown lets it go: it takes blows again")
	Kit.done(s)


static func _rapt(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var all := true
	for l: SermonDirector.Listener in _wave(d, 0):
		var p := l.man as Person
		all = all and d.rapt(p) and p.shaken() and p.fearless_left > 0.0 and p.mind == Person.Mind.DUTY \
			and not p.whisper(d.door, MindWhisperFx.LINGER)
	var w: SermonDirector.Listener = _wave(d, 1)[0]
	var wp := w.man as Person
	t.check(all, "within VOICE of the preaching preacher his crowd is rapt: deaf, fearless, on duty")
	t.check(not d.rapt(wp) and wp.shaken() and wp.mind == Person.Mind.DUTY and wp.anchor == w.source,
		"a waiting wave is held deaf at its source too: nothing is done with it before it walks in (plan decision 183)")
	d._on_refused(0, "shaken")
	t.check((s.banners as Array).has("THEY HEAR ONLY HIM"), "a whisper refused while they are rapt: THEY HEAR ONLY HIM")
	Kit.done(s)


static func _silenced(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var p := (_wave(d, 0)[0] as SermonDirector.Listener).man as Person
	var pr := d.preacher as Person
	pr.confuse(5.0)
	p._shaken_left = 0.0
	Kit.run_for(s, 0.6)
	t.check(not d.preaching() and not d.rapt(p) and not p.shaken(), "a confused preacher is silent: his crowd's hold lapses")
	pr._come_to()
	Kit.run_for(s, 1.2)
	t.check(d.preaching() and d.rapt(p) and p.shaken() and (s.banners as Array).has("THE PREACHER TAKES UP HIS SERMON"),
		"back on his feet he preaches again, and holds them again")
	Kit.free_body(s, pr)
	Kit.run_for(s, 0.1)
	t.check(not d.preaching() and (s.banners as Array).has("THE PREACHER IS SILENT") and d.reports_started >= 1,
		"killed, he is silent for good; his acolytes saw it and run to the Temple")
	Kit.done(s)


static func _turned(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	var l: SermonDirector.Listener = _wave(d, 0)[0]
	var p := l.man as Person
	t.check(p.whisper(d.door, MindWhisperFx.LINGER), "(set-up) with the preacher silent he hears a whisper")
	Kit.arrive(p, d.door)
	Kit.run_for(s, 0.1)
	t.check(not p.inside and d._turned.has(p) and d.reports_started == 1 and (s.banners as Array).has("A FAITHFUL RUNS TO THE TEMPLE")
		and d.reports[0].skip.is_valid() and d.hint_phase() == "report",
		"a sentry sees him at the door: turned away, and a Faithful runs to the Temple, its relay passing over the fleeing")
	p._wake()
	Kit.run_for(s, 0.6)
	t.check(p.mind == Person.Mind.DUTY and p.anchor == l.spot, "turned away and back on his feet, he walks back to the pulpit")
	Kit.done(s)


static func _believe(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	_unwatch(s, d)
	var p := (_wave(d, 0)[0] as SermonDirector.Listener).man as Person
	p.whisper(d.door, MindWhisperFx.LINGER)
	Kit.arrive(p, d.door)
	Kit.run_for(s, 0.1)
	t.check(p.inside, "unseen, he goes in to read")
	Kit.run_for(s, SermonDirector.READ + 0.2)
	t.check(d.believers.has(p) and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == d._believer_spot(p)
		and (s.banners as Array).has("1 BELIEVE") and ((s.rules as Rules).objectives[1] as Objective).hud_text(s.rules) == "Turn the crowd 1 / 8",
		"READ later he comes out a Believer and stands on duty by the door; the HUD counts him")
	Kit.done(s)


static func _flock(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[1]
	var gone := 0
	for l: SermonDirector.Listener in d.listeners:
		if gone < 4 and l.wave > 0:
			Kit.free_body(s, l.man)
			gone += 1
	Kit.run_for(s, 0.1)
	t.check(d.lost_reason() == "" and main.check(s.rules) == Objective.Status.PENDING, "eight left to turn: the night goes on")
	Kit.free_body(s, (_wave(d, 3)[2] as SermonDirector.Listener).man)
	Kit.run_for(s, 0.1)
	t.check(d.lost_reason() == "flock" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "flock",
		"too few left to turn: lost at once, with its own reason")
	Kit.done(s)


static func _waves(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	for l: SermonDirector.Listener in _wave(d, 0):
		Kit.free_body(s, l.man)
	Kit.run_for(s, 0.1)
	var shown := d.timeline.seconds_to("wave_1")
	t.check(d.spent(0) and d.spent_at[0] >= 0.0 and shown <= SermonDirector.CHAIN + 0.1 and not d.called[1],
		"the first wave spent: the second chained, CHAIN on (%.1f)" % shown)
	Kit.run_for(s, SermonDirector.CHAIN + DT)
	var walking := true
	for l: SermonDirector.Listener in _wave(d, 1):
		walking = walking and (l.man as Person).anchor == l.spot and (l.man as Person).mind == Person.Mind.DUTY
	t.check(d.called[1] and walking and (s.banners as Array).has("MORE COME TO HEAR HIM"), "CHAIN later the second wave walks in, on duty")
	Kit.done(s)


static func _sentries(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var st: SermonDirector.Sentry = d.sentries[0]
	var dead: Variant = st.man
	Kit.free_body(s, dead)
	Kit.run_for(s, SermonDirector.RELIEF_AFTER + 1.0)
	var p: Variant = st.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p)
		and (p as Person).anchor == st.post and st.relief and d.reliefs == 1 and (s.banners as Array).has("A NEW SENTRY WATCHES THE GOD'S HOUSE"),
		"RELIEF_AFTER after a sentry falls, the nearest lay citizen with a way there is made a Faithful watchman and walks to his post")
	var other: SermonDirector.Sentry = d.sentries[1]
	var op := other.man as Person
	Kit.arrive(op, d.door + Vector2(0.0, 8.0))
	op.mind = Person.Mind.CALM
	Kit.run_for(s, SermonDirector.RETURN_AFTER + 1.0)
	t.check(op.mind == Person.Mind.DUTY and op.anchor == other.post, "one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


static func _evacuate(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.1)
	_silence(d)
	Kit.free_body(s, d.sentries[0].man)
	var b: SermonDirector.Sentry = d.sentries[1]
	var bp := b.man as Person
	Kit.arrive(bp, d.door + Vector2(0.0, 8.0))
	bp.mind = Person.Mind.RECOVER
	var first := (_wave(d, 0)[0] as SermonDirector.Listener).man as Person
	first.whisper(d.door, MindWhisperFx.LINGER)
	Kit.arrive(first, d.door)
	Kit.run_for(s, SermonDirector.READ + 0.3)
	var walker := (_wave(d, 0)[1] as SermonDirector.Listener).man as Person
	walker.whisper(d.door, MindWhisperFx.LINGER)
	t.check(d.believers.has(first), "(set-up) one Believer stands by the door")
	Kit.evacuate(s)
	t.check(bp.mind == Person.Mind.FLEE and walker._whisper_fled, "(set-up) the evacuation sends the recovering sentry running, and owes the whispered listener a flight")
	Kit.run_for(s, 0.6)
	t.check(bp.mind != Person.Mind.FLEE and not walker._whisper_fled and walker.mind == Person.Mind.WHISPERED
		and first.mind == Person.Mind.DUTY and not first.inside, "at the first look after it: both kept from the flight; the Believer stays")
	Kit.arrive(walker, d.door)
	Kit.run_for(s, 0.1)
	t.check(walker.inside, "the whispered listener reaches the door and goes in")
	Kit.run_for(s, SermonDirector.RETURN_AFTER + 1.0)
	var waiting := true
	for l: SermonDirector.Listener in _wave(d, 3):
		waiting = waiting and (l.man as Person).mind == Person.Mind.DUTY and (l.man as Person).anchor == l.source
	t.check(bp.mind == Person.Mind.DUTY and bp.anchor == b.post and waiting and first.mind == Person.Mind.DUTY and d.believers_outside() >= 1,
		"the sentry walks back; the waiting waves and the Believer stay (review focus 2)")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	_seat(d, 0)
	Kit.run_for(s, 0.6)
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 3) == ["GOD'S HOUSE", "DOOR - WATCHED", "PREACHER"] and String(labels[3]).begins_with("NEXT WAVE ")
		and labels.has("SENTRY") and Kit.edged(d, "GOD'S HOUSE") and d.tags()[0].outline == d.house.footprint and d.hint_phase() == "rapt",
		"the god's house outlined and pointed at, its door watched, the preacher, the next wave's time; he preaches (%s)" % [labels])
	_silence(d)
	Kit.run_for(s, 0.1)
	t.check(Kit.labels(d).has("PREACHER - SILENT") and d.hint_phase() == "watched", "silent, grey; the sentries watch the door")
	_unwatch(s, d)
	Kit.run_for(s, 0.1)
	t.check(Kit.labels(d)[1] == "DOOR - CLEAR" and d.hint_phase() == "", "no sentry: the door is clear, the mission's own line")
	d._report(d.acolytes[0] as Person, d.temple_door)
	t.check(Kit.labels(d).has("TO THE TEMPLE") and Kit.labels(d).has("TEMPLE") and d.hint_phase() == "report", "a report runs: its runner and the Temple")
	(s.crowd as Crowd).bell.state = BellNetwork.State.CALLED
	t.check(d.hint_phase() == "bell", "the bell called: the bell's warning first")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The preacher at the south-west well.")
		and String(tour[1][1]).begins_with("The god's house."), "the tour: the preacher, the god's house, the Temple")
	t.check(ResultsScreen.ACT_TITLES.get("sermon") == "THE CROWD BELIEVES" and ResultsScreen.ACT_TITLES.get("sermon_over") == "THE SERMON ENDS"
		and ResultsScreen.ACT_TITLES.get("flock") == "THE FLOCK IS SCATTERED", "its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: SermonDirector = s.d
	var out: Array = [d.preacher] + d.acolytes
	for st: SermonDirector.Sentry in d.sentries:
		out.append(st.man)
	for l: SermonDirector.Listener in _wave(d, 0):
		out.append(l.man)
	for v: Variant in out:
		Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(not d.preaching() and d.lost_reason() == "" and int(d.report().believers) == 0 and d.sentries_on_guard().is_empty(),
		"the preacher, his acolytes, the sentries and a wave freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_sermon.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then Tests. Expected: parse errors (`SermonDirector`, `MissionBook.sermon`).

- [ ] **Step 3: Create `src/game/mission/sermon_director.gd`:**

```gdscript
class_name SermonDirector
extends MirasHouseDirector
## The Sermon (v0.11 M5, Tier 4, mission spec §3; Convert, reused): a preacher holds the poor quarter. He preaches at the south-west
## well (TownLayout.WELLS[2]), his two acolytes ACOLYTE_OFF either side. While he preaches -- alive, out of doors, on duty at the
## pulpit -- every listener within VOICE of him is rapt: held deaf to a whisper and past fear, on duty. Whispered off, confused or
## frightened he is silent while held and preaches again back on his feet; dead he is silent for good, and an acolyte not held who
## sees it runs to the Temple. His crowd is twelve listeners in four waves of WAVE, appointed at the start by their sources and held
## deaf at them until their wave walks in (plan decision 183): the first at once, each next at WAVE_AT or CHAIN after the wave before is
## spent (each believes, is dead or is gone), whichever is sooner; each walks in on duty to a place on a ring RING from the preacher.
## Mira's rules otherwise: a listener whispered to the god's house goes in unless a Faithful within SIGHT of its door sees (then he is
## turned away, the seer runs to the Temple, and he walks back), reads READ and comes out a Believer -- who stands on duty on a ring
## BELIEVER_RING from the door until the night is won. Two sentries, Faithful watchmen, watch the door SENTRY_OFF either side of it; one
## off his post walks back RETURN_AFTER after he left, a fallen one is replaced RELIEF_AFTER later (RELIEFS at most). A report
## delivered fills the Gaze; a seen death adds to it; the bell fills it. NEED Believers win; too few left to turn loses at once
## ("flock", lost_reason()); the sermon ends at SERMON_ENDS (EventObjective). The god's house only shakes tonight (plan decisions
## 183-190).

## One listener (v0.11 M5): a plain record, so the director holds no cycle.
class Listener:
	extends RefCounted
	## The listener, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## His wave (0 first), where he waits for it, and his place on the ring once it walks in.
	var wave := 0
	var source := Vector2.INF
	var spot := Vector2.INF


## One sentry's post (v0.11 M5): a plain record.
class Sentry:
	extends RefCounted
	## The sentry, a Variant read only through MissionDirector._alive().
	var man: Variant = null
	## Where he stands; seconds since he last saw the door (alive), and since he fell; he is a relief walking in.
	var post := Vector2.INF
	var away := 0.0
	var fallen := 0.0
	var relief := false


## The god's house is the dwelling nearest this point (v0.11 M5, Decision 143); the later waves' sources (the first is round the pulpit).
const HOUSE_SPOT := Vector2(-14.0, 10.4)
const SOURCES := [Vector2(-11.0, 3.0), Vector2(-2.0, 12.0), Vector2(-12.0, 6.0)]
## Mission spec §3's numbers (v0.11 M5), first guesses, tuned by Step 7's gate in this order: CHAIN (30-45), WAVE (3-4, NEED staying 8),
## WAVE_AT[1] (75-110), READ (6-10), VOICE (4-6). The need; the waves; their times and chain; the preacher's voice; the ring; the
## acolytes; the reading; the sentries; return and relief; the Faithful; the Believers' ring; the sermon's end.
const NEED := 8
const WAVE := 3
const WAVES := 4
const WAVE_AT := [0.0, 95.0, 185.0, 260.0]
const CHAIN := 45.0
const VOICE := 5.0
const RING := Vector2(2.5, 3.5)
const ACOLYTE_OFF := 1.0
const READ := 8.0
const SENTRIES := 2
const SENTRY_OFF := 1.5
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const FAITHFUL_LAY := 8
const BELIEVER_RING := 2.0
const SERMON_ENDS := 300.0
## How near the pulpit the preacher preaches; how long past each look a held listener stays deaf and fearless; how far round its
## source a waiting wave stands; how many dwellings _find_house() weighs; how hard a blow shakes the god's house (v0.11 M5).
const PREACH_REACH := 1.0
const HOLD := 1.0
const WAIT_R := 1.0
const HOUSE_TRIES := 12
const HOUSE_SHAKE := 2.0
## Where the camera rests (v0.11 M5, Decision 159): the pulpit below the centre, the god's house at the left below the HUD stack.
const CAMERA_AT := Vector2(-9.0, 9.5)
## Seconds between looks (v0.11 M5).
const TICK := 0.5
## The tags' gold for the crowd, grey for the silent preacher, orange for the next wave (v0.11 M5).
const MARK_GOLD := Color("d8b23a")
const MARK_GREY := Color("9a948a")
const MARK_NEXT := Color("ff9a3a")

## Where the preacher preaches (v0.11 M5).
var pulpit := Vector2.INF
## The preacher and his acolytes (Variants: any may be freed), and the acolytes' places (v0.11 M5).
var preacher: Variant = null
var acolytes: Array = []
var acolyte_spots: Array[Vector2] = []
## The twelve listeners and the sentries (v0.11 M5).
var listeners: Array = []
var sentries: Array = []
## Each wave has walked in; the second it was spent (-1 until then); how many sentries' reliefs came (v0.11 M5).
var called: Array[bool] = []
var spent_at: Array[float] = []
var reliefs := 0
## He preached at the last frame; where he fell, and it was judged (v0.11 M5).
var _was_preaching := true
var _preacher_fell := Vector2.INF
var _fall_judged := false
## Seconds into the night, and to the next look (v0.11 M5).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M5): its numbers (as First Prayers'), Mira's (the house, the people, the strip), the first wave walking in,
## and the refused whispers heard.
func _begin() -> void:
	need = NEED
	read_seconds = READ
	for w in WAVES:
		called.append(w == 0)
		spent_at.append(-1.0)
	super()
	rules.cast_refused.connect(_on_refused)
	for l: Listener in listeners:
		if l.wave == 0 and _alive(l.man):
			(l.man as Person).go_duty(l.spot)


## The night's opening banner (v0.11 M5).
func _opening_banner() -> String:
	return "THE SERMON"


## What the god's house's tag says (v0.11 M5).
func _house_label() -> String:
	return "GOD'S HOUSE"


## Dawn (v0.11 M5, as First Prayers): on the tier board a won night is held to dawn, so nobody is burned in; nobody goes in after it.
func _roof() -> void:
	roof_fallen = true


## The pulpit, and the god's house (v0.11 M5, Decision 143): the dwelling nearest HOUSE_SPOT, never set aside, whose door the street
## from the pulpit reaches beyond VOICE of it; it only shakes tonight (plan decision 184).
func _find_house() -> Structure:
	pulpit = _walkable(TownLayout.WELLS[2].get_center() + Vector2(0.0, -0.8))
	var skip: Array = []
	for i in HOUSE_TRIES:
		var h := _house_near(HOUSE_SPOT, skip)
		if h == null:
			return null
		var d := _open_door(h, pulpit)
		if d != Vector2.INF and d.distance_to(pulpit) > VOICE:
			h.damage_filter = _house_hit
			return h
		skip.append(h)
	return null


## Structure.damage_filter for the god's house (v0.11 M5): the blow only shakes it.
func _house_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(HOUSE_SHAKE)


## The god's house's door (v0.11 M5): the one the street from the pulpit reaches, else Mira's front.
func _door_of(s: Structure) -> Vector2:
	var d := _open_door(s, pulpit) if pulpit != Vector2.INF else Vector2.INF
	return d if d != Vector2.INF else super(s)


## The people (v0.11 M5): the WAVE lay citizens nearest each wave's source, set down at it (the first where they stand) and on duty;
## the preacher and his acolytes, the clergy nearest the pulpit; the sentries, made Faithful watchmen; then every cleric and
## FAITHFUL_LAY of the rest are Faithful. No Inquisitor.
func _choose_people() -> void:
	var taken: Array = []
	for w in WAVES:
		var src: Vector2 = pulpit if w == 0 else _wave_source(w)
		var crowd_of := _lay_near(src, WAVE, taken)
		for k in crowd_of.size():
			var p := crowd_of[k]
			var l := Listener.new()
			l.man = p
			l.wave = w
			l.source = p.ground_pos if w == 0 else _ring_spot(src, WAIT_R, k, WAVE)
			l.spot = _ring_place(listeners.size())
			p.profile.faith = CitizenProfile.Faith.GRIEVING
			grieving.append(p)
			listeners.append(l)
			taken.append(p)
			_set_down(p, l.source)
			p.go_duty(l.source)
	var pr := _citizen_near(pulpit, CitizenProfile.Role.CLERGY, taken)
	if pr != null:
		preacher = pr
		taken.append(pr)
		_set_down(pr, pulpit)
		pr.go_duty(pulpit)
	for k in 2:
		var a := _citizen_near(pulpit, CitizenProfile.Role.CLERGY, taken)
		if a == null:
			break
		var spot := _walkable(pulpit + Vector2(ACOLYTE_OFF * (-1.0 if k == 0 else 1.0), 0.0))
		taken.append(a)
		acolytes.append(a)
		acolyte_spots.append(spot)
		_set_down(a, spot)
		a.go_duty(spot)
	for k in SENTRIES:
		var st := Sentry.new()
		st.post = _sentry_post(k)
		var near := _lay_near(st.post, 1, taken)
		if not near.is_empty():
			var p := near[0]
			_make_sentry(p)
			st.man = p
			taken.append(p)
			_set_down(p, st.post)
			p.go_duty(st.post)
		sentries.append(st)
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in clergy:
		if not faithful.has(p):
			_make_faithful(p)
	var rest: Array[Person] = []
	for p in lay:
		if p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY and not taken.has(p):
			rest.append(p)
	_spread_faithful(rest, FAITHFUL_LAY)
	venn = null


## Wave `w`'s source (v0.11 M5): round the pulpit for the first, SOURCES[w - 1] for the rest.
func _wave_source(w: int) -> Vector2:
	return pulpit if w == 0 else _walkable(SOURCES[w - 1])


## The `k`th place on the preacher's ring (v0.11 M5): on its northern arc, RING.x and RING.y from him by turns (outside his witnesses'
## reach), the town's side of the well.
func _ring_place(k: int) -> Vector2:
	var n := WAVES * WAVE
	var angle := PI + 0.25 + (PI - 0.5) * float(k) / float(maxi(n - 1, 1))
	return _walkable(pulpit + Vector2.from_angle(angle) * (RING.x if k % 2 == 0 else RING.y))


## The `k`th sentry's post (v0.11 M5): SENTRY_OFF along the door's face, either side.
func _sentry_post(k: int) -> Vector2:
	var out := door - house.center() if house != null else Vector2.DOWN
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	return _walkable(door + along * SENTRY_OFF * (-1.0 if k == 0 else 1.0))


## `p` made a sentry (v0.11 M5): a watchman (the cloak and lantern) and one of Halcyon's Faithful.
func _make_sentry(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN
	_make_faithful(p)


## Everyone at the sermon's work (v0.11 M5), for a relief to leave out.
func _busy() -> Array:
	var out: Array = [preacher]
	out.append_array(acolytes)
	for l: Listener in listeners:
		out.append(l.man)
	for st: Sentry in sentries:
		out.append(st.man)
	return out


## The strip (v0.11 M5): each later wave at its time, and the sermon's end.
func _add_events() -> void:
	for w in range(1, WAVES):
		timeline.add(float(WAVE_AT[w]), "wave_%d" % w, "More come to hear him", _call_wave.bind(w), func() -> bool: return not called[w])
	timeline.add(SERMON_ENDS, "ends", "The sermon ends", Callable(), func() -> bool: return believers_outside() < need)


## Wave `w` walks in (v0.11 M5): each listener out of doors kept from the town's flight and on duty to his place on the ring.
func _call_wave(w: int) -> void:
	if called[w]:
		return
	called[w] = true
	for l: Listener in listeners:
		if l.wave == w and _alive(l.man) and not (l.man as Person).inside:
			_keep_from_flight(l.man as Person, true)
			(l.man as Person).go_duty(l.spot)


## Wave `w` is spent (v0.11 M5): each of its listeners believes, is dead or is gone.
func spent(w: int) -> bool:
	for l: Listener in listeners:
		if l.wave == w and _alive(l.man) and not believers.has(l.man):
			return false
	return true


## The second of the night wave `w` walks in at the latest (v0.11 M5): its own time, or CHAIN after the wave before is spent if sooner.
func wave_due(w: int) -> float:
	var at := float(WAVE_AT[w]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if w > 0 and spent_at[w - 1] >= 0.0:
		at = minf(at, spent_at[w - 1] + CHAIN)
	return at


## Seconds until wave `w` walks in at the latest (v0.11 M5); 0 once it has.
func due_in(w: int) -> float:
	return 0.0 if called[w] else maxf(wave_due(w) - _clock, 0.0)


## The first wave not yet walked in, or -1 (v0.11 M5).
func next_wave() -> int:
	for w in WAVES:
		if not called[w]:
			return w
	return -1


## Each wave newly spent is marked and the next one's chained time shown on the strip; each wave whose chained time has come walks in
## (v0.11 M5).
func _chain() -> void:
	for w in WAVES:
		if spent_at[w] < 0.0 and called[w] and spent(w):
			spent_at[w] = _clock
			if timeline != null and w + 1 < WAVES:
				timeline.expect("wave_%d" % (w + 1), wave_due(w + 1))
	for w in range(1, WAVES):
		if not called[w] and spent_at[w - 1] >= 0.0 and _clock >= wave_due(w):
			rules.banner.emit("MORE COME TO HEAR HIM")
			_call_wave(w)


## The preacher preaches now (v0.11 M5, plan decision 185): alive, out of doors, on duty within PREACH_REACH of the pulpit.
func preaching() -> bool:
	if not _alive(preacher):
		return false
	var p := preacher as Person
	return not p.inside and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(pulpit) <= PREACH_REACH


## The listener `v` is rapt now (v0.11 M5): his wave walked in, unturned and out of doors, within VOICE of the preaching preacher.
func rapt(v: Variant) -> bool:
	if not preaching() or not _alive(v) or believers.has(v):
		return false
	var p := v as Person
	var l := _listener_of(p)
	return l != null and called[l.wave] and not p.inside and p.ground_pos.distance_to((preacher as Person).ground_pos) <= VOICE


## `v` is held by the god (v0.11 M5): confused or whispered. Only reads.
func held(v: Variant) -> bool:
	return _alive(v) and (v as Person).mind in BLIND


## `p`'s Listener record, or null (v0.11 M5).
func _listener_of(p: Person) -> Listener:
	for l: Listener in listeners:
		if l.man == p:
			return l
	return null


## Every listener whose wave has walked in, alive, out of doors, not yet a Believer (v0.11 M5, for the policy and the tags).
func unturned() -> Array[Person]:
	var out: Array[Person] = []
	for l: Listener in listeners:
		if called[l.wave] and _alive(l.man) and not (l.man as Person).inside and not believers.has(l.man):
			out.append(l.man as Person)
	return out


## `p`'s place as a Believer (v0.11 M5): on a ring BELIEVER_RING round the god's door, by the order they came out.
func _believer_spot(p: Person) -> Vector2:
	return _ring_spot(door, BELIEVER_RING, maxi(believers.find(p), 0), NEED)


## Mira's step's events (v0.11 M5): the chain, the preacher's word, the acolytes' sight of his death, the god's house kept from fire,
## and every TICK the evacuation rule and each of the sermon's people at their places.
func _step_events(delta: float) -> void:
	_clock += delta
	_chain()
	var now := preaching()
	if now and not _was_preaching:
		rules.banner.emit("THE PREACHER TAKES UP HIS SERMON")
	_was_preaching = now
	if _preacher_fell != Vector2.INF and not _fall_judged and crowd._doomed.is_empty():
		_acolytes_see()
	if house != null and crowd.fires != null and crowd.fires.is_burning(house):
		crowd.fires._put_out(house, true)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	var evacuating := _evacuation_began()
	_keep_clergy(evacuating)
	for l: Listener in listeners:
		_keep_listener(l, now, evacuating)
	for v: Variant in believers:
		_keep_believer(v, evacuating)
	for st: Sentry in sentries:
		_keep_sentry(st, evacuating)


## The preacher and his acolytes kept at their places (v0.11 M5): back on his feet, each goes on duty there again.
func _keep_clergy(evacuating: bool) -> void:
	if _alive(preacher) and not (preacher as Person).inside:
		_keep_from_flight(preacher as Person, evacuating)
		_recall_to(preacher, pulpit)
	for k in acolytes.size():
		if _alive(acolytes[k]) and not (acolytes[k] as Person).inside:
			_keep_from_flight(acolytes[k] as Person, evacuating)
			_recall_to(acolytes[k], acolyte_spots[k])


## Listener `l` at his place (v0.11 M5): waiting, held deaf and fearless on duty at his source; walked in, on duty to his place on the
## ring (back on his feet after a whisper or a fright), and held while rapt.
func _keep_listener(l: Listener, preaching_now: bool, evacuating: bool) -> void:
	if not _alive(l.man) or believers.has(l.man):
		return
	var p := l.man as Person
	if p.inside:
		return
	_keep_from_flight(p, evacuating)
	if not called[l.wave]:
		_hold(p)
		_recall_to(p, l.source)
		return
	if preaching_now and p.ground_pos.distance_to((preacher as Person).ground_pos) <= VOICE:
		_hold(p)
	_recall_to(p, l.spot)


## `p` held deaf to a whisper and past fear past the next look (v0.11 M5, plan decision 94's hold).
static func _hold(p: Person) -> void:
	p._shaken_left = maxf(p._shaken_left, HOLD)
	p.fearless_left = maxf(p.fearless_left, HOLD)


## A Believer kept at his place by the door (v0.11 M5, Decision 147): out of the town's flight, on duty there.
func _keep_believer(v: Variant, evacuating: bool) -> void:
	if not _alive(v) or (v as Person).inside:
		return
	var p := v as Person
	_keep_from_flight(p, evacuating)
	_recall_to(p, _believer_spot(p))


## Sentry `st` is on guard (v0.11 M5, plan decision 188): he sees the door.
func _on_guard(st: Sentry) -> bool:
	return _alive(st.man) and _sees(st.man, door, SIGHT, null)


## Sentry `st` at his work, every TICK (v0.11 M5): on guard, kept on duty; off his post, sent back RETURN_AFTER after he left (a relief
## walks on at once); fallen, replaced RELIEF_AFTER later (RELIEFS at most).
func _keep_sentry(st: Sentry, evacuating: bool) -> void:
	if _on_guard(st):
		st.away = 0.0
		st.fallen = 0.0
		st.relief = false
		var g := st.man as Person
		_keep_from_flight(g, evacuating)
		if g.mind != Person.Mind.DUTY:
			_recall_to(g, st.post)
		return
	if _alive(st.man):
		st.fallen = 0.0
		var p := st.man as Person
		if p.inside:
			return
		_keep_from_flight(p, evacuating)
		st.away += TICK
		if st.relief or st.away >= RETURN_AFTER:
			_recall_to(p, st.post)
		return
	st.fallen += TICK
	if st.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
		_relieve(st)


## A relief for fallen sentry `st` (v0.11 M5): the nearest lay citizen with a way to the post (M4's _lay_reaching()), made a sentry.
func _relieve(st: Sentry) -> void:
	var p := _lay_reaching(st.post, _busy())
	if p == null:
		return
	_make_sentry(p)
	st.man = p
	st.fallen = 0.0
	st.away = 0.0
	st.relief = true
	reliefs += 1
	p.go_duty(st.post)
	rules.banner.emit("A NEW SENTRY WATCHES THE GOD'S HOUSE")


## The sentries on guard now (v0.11 M5). Only reads.
func sentries_on_guard() -> Array[Person]:
	var out: Array[Person] = []
	for st: Sentry in sentries:
		if _on_guard(st):
			out.append(st.man as Person)
	return out


## A sentry's relief walking in, or null (v0.11 M5, for the scripted player). Only reads.
func relief_walking() -> Person:
	for st: Sentry in sentries:
		if st.relief and _alive(st.man) and not (st.man as Person).inside and not _on_guard(st):
			return st.man as Person
	return null


## Out at the door (v0.11 M5): Mira's (a Faithful who sees runs to the Temple), then a Believer is kept from the flight and goes on duty
## to his place by the door (plan decision 187).
func _exit(p: Person) -> void:
	super(p)
	if _alive(p) and believers.has(p):
		_keep_from_flight(p, true)
		p.go_duty(_believer_spot(p))


## A death (v0.11 M5): Mira's (the Gaze's note, the reports' relay), and the preacher's fall, for his acolytes to see.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	var v: Variant = preacher
	if v == e and _preacher_fell == Vector2.INF:
		_preacher_fell = e.ground_pos
		rules.banner.emit("THE PREACHER IS SILENT")


## The preacher's death judged (v0.11 M5, plan decision 189): each acolyte not held who sees the fall within SIGHT runs to the Temple.
func _acolytes_see() -> void:
	_fall_judged = true
	for a: Variant in acolytes:
		if _sees(a, _preacher_fell, SIGHT, null):
			_report(a as Person, temple_door)


## A report (v0.11 M5, plan decision 190): Mira's, its relay passing over the fleeing and the reserved (TempleReport.skip).
func _report(seer: Person, at: Vector2) -> void:
	var before := reports.size()
	super(seer, at)
	for i in range(before, reports.size()):
		reports[i].skip = _passed_over


## A relay never picks `p` (v0.11 M5, the M3 final review's rule): one fleeing the town or reserved.
func _passed_over(p: Person) -> bool:
	return p.mind == Person.Mind.FLEE or reserved.has(p)


## Too few left to turn (v0.11 M5, Decision 148): the living listeners, Believers among them, below NEED -- "flock"; else "".
func lost_reason() -> String:
	var n := 0
	for l: Listener in listeners:
		n += 1 if _alive(l.man) else 0
	return "flock" if n < need else ""


## A refused cast (Rules.cast_refused, v0.11 M5, plan decision 186): a whisper refused while his crowd is rapt says why.
func _on_refused(slot: int, why: String) -> void:
	if why != "shaken" or rules.key(slot) != "whisper":
		return
	for l: Listener in listeners:
		if rapt(l.man):
			rules.banner.emit("THEY HEAR ONLY HIM")
			return


## The map tags, most important first (v0.11 M5, mission spec §3): the god's house, outlined and pointed at; its door, clear or
## watched; each report's runner and the Temple while one runs; the preacher (grey while silent); the next wave's source and time; each
## sentry on guard, a red diamond on a relief; the acolytes; a gold diamond on each listener not yet turned (a small red mark while rapt),
## green on each Believer.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if house != null:
		var h := MapTag.place(house.center(), MARK_HOUSE, _house_label(), house.height, true)
		h.outline = house.footprint
		out.append(h)
	var watched := faithful_seeing(door, SIGHT) != null
	out.append(MapTag.place(door, MARK_WATCHED if watched else MARK_CLEAR, "DOOR - WATCHED" if watched else "DOOR - CLEAR", 0.0, false))
	var running := false
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			out.append(MapTag.person(r.carrier.ground_pos, MARK_WATCHED, "TO THE TEMPLE", true))
			running = true
	if running:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	if _alive(preacher) and not (preacher as Person).inside:
		var on := preaching()
		out.append(MapTag.person((preacher as Person).ground_pos, MARK_WATCHED if on else MARK_GREY, "PREACHER" if on else "PREACHER - SILENT"))
	var w := next_wave()
	if w > 0:
		out.append(MapTag.place(_wave_source(w), MARK_NEXT, "NEXT WAVE %s" % UiTheme.clock(due_in(w)), 0.0, true))
	for st: Sentry in sentries:
		if not _alive(st.man) or (st.man as Person).inside:
			continue
		if _on_guard(st):
			out.append(MapTag.person((st.man as Person).ground_pos, MARK_WATCHED, "SENTRY"))
		elif st.relief:
			out.append(MapTag.person((st.man as Person).ground_pos, MARK_WATCHED))
	for a: Variant in acolytes:
		if _alive(a) and not (a as Person).inside:
			out.append(MapTag.person((a as Person).ground_pos, MARK_WATCHED))
	for l: Listener in listeners:
		if not _alive(l.man) or (l.man as Person).inside:
			continue
		var p := l.man as Person
		if believers.has(p):
			out.append(MapTag.person(p.ground_pos, MARK_CLEAR))
			continue
		out.append(MapTag.person(p.ground_pos, MARK_GOLD))
		if rapt(p):
			out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5): "bell" while the bell is called or climbing (plan decision 197); "report" while one runs; while he
## preaches, "coming" with a walked-in listener still on his way, else "rapt"; "watched" while a Faithful watches the door; else "".
func hint_phase() -> String:
	if crowd.bell != null and crowd.bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return "bell"
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			return "report"
	if preaching():
		for p in unturned():
			if p.mind == Person.Mind.DUTY and not rapt(p):
				return "coming"
		return "rapt"
	return "watched" if faithful_seeing(door, SIGHT) != null else ""


## The tour (v0.11 M5, mission spec §3): the preacher, the god's house, the Temple.
func tour() -> Array:
	return [[pulpit, "The preacher at the south-west well. While he preaches, his crowd hears only him."],
		[door, "The god's house. Lead eight of his crowd here, unseen by the Faithful."],
		[temple_door, "The Temple. A Faithful who sees you runs here."]]


## What the results show (v0.11 M5): the Believers, the reports, whether the preacher lives, the reliefs.
func report() -> Dictionary:
	return {"believers": believers_outside(), "reports": reports_started, "preacher": "alive" if _alive(preacher) else "silent",
		"reliefs": reliefs}


## Lets go of the god's house and the refused casts, then Mira's (v0.11 M5).
func teardown() -> void:
	if house != null and is_instance_valid(house):
		house.damage_filter = Callable()
	if is_instance_valid(rules) and rules.cast_refused.is_connected(_on_refused):
		rules.cast_refused.disconnect(_on_refused)
	super()
```

- [ ] **Step 4: The mission.**
  - In `src/game/mission/mission_book.gd`, `tier_missions()`'s list gains `sermon()` after `armoury()`, and after `armoury()` add:

```gdscript
## The Sermon (v0.11 M5, Tier 4, mission spec §3 and §8 row 19): silence a preacher who holds the poor quarter and lead eight of his
## crowd, in four waves, to the god's house unseen by the Faithful, before the sermon ends (SermonDirector, Mira's House's Convert).
static func sermon() -> MissionDef:
	var m := _tier4(SERMON, "The Sermon", PackedStringArray(["A preacher holds the poor quarter.", "Silence him. Turn eight of his crowd."]))
	m.goal = "Silence the preacher and lead eight of his crowd to the god's house, unseen, before the sermon ends at %s" % UiTheme.clock(
		SermonDirector.SERMON_ENDS)
	m.goal_label = "The crowd believes"
	m.lose = "The Lantern looks, the sermon ends, or too few are left to turn"
	m.camera_at = SermonDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom", "wisp"])
	m.director = SermonDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), BelieversObjective.new("Turn the crowd", "sermon", "sermon_over"),
			EventObjective.new("ends", "Sermon ends", "sermon_over")]
		return out
	return m
```

  - In `mission_hints.gd` `LINES`, after the `armoury` entries, add (and the same six rows, under `# The Sermon (v0.11 M5).`, in
    `tests/test_mission_hints.gd` `SPEC`):

```gdscript
	"sermon": "Silence the preacher (red), then whisper his crowd (gold) to the god's house unseen. Eight must believe. Do not kill them.",
	"sermon.rapt": "He preaches: his crowd hears only him. Discord, a whisper or a fright silences him for a while; death, for good.",
	"sermon.watched": "Sentries (red) watch the door: anyone seen going in is turned away and reported. Remove them first.",
	"sermon.report": "A Faithful runs to the Temple. Stop him before he gets there, unseen.",
	"sermon.coming": "More come to hear him (gold). Whisper them on the way, before they come within his voice.",
	"sermon.bell": "Four seen deaths in a district ring the bell, and the bell fills the Gaze. Stop the bellkeeper, unseen.",
```

  - In `results_screen.gd` `ACT_TITLES`, add `"sermon": "THE CROWD BELIEVES", "sermon_over": "THE SERMON ENDS", "flock": "THE FLOCK IS SCATTERED"`.

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 35;
  `test_miras_house`, `test_first_prayers` unchanged.

- [ ] **Step 6: The behaviour scenario.** In `tools/dev/behaviour_check.gd`:
  - In the header's usage, after the `armoury` entry, add:

```gdscript
##   sermon  (v0.11 M5) The Sermon, --case=none (nothing cast) or play, as a player plays it (_sermon_act(): the preacher preaching,
##          Discord on him (it holds his acolytes too); he and both acolytes held, Silent Doom on him; a report running, Silent Doom on
##          its runner where unseen; a sentry on guard, Silent Doom on him with no one else within 2, else Mind Whisper sends him eight
##          units off; no sentry on guard, Mind Whisper sends the unturned listener nearest the god's house, not rapt, to its door; else
##          Silent Doom on a sentry's relief; the result line gives the longest idle stretch). --seed=, --board as ringers.
```

  - After `ARMOURY_AHEAD` add:

```gdscript
## The Sermon's policy (v0.11 M5): how near a sentry no one else may stand for a Doom; how far one is whispered off.
const SERMON_ALONE := 2.0
const SERMON_AWAY := 8.0
```

  - In `_run()`, after the `armoury` branch add:

```gdscript
	elif scenario == "sermon":
		powers = PackedStringArray(["whisper", "discord", "doom", "wisp"])
		mission.mission_id = MissionBook.SERMON
```

  - In `_run()`'s `match scenario:`, before `"warning":`, add:

```gdscript
		"sermon":
			await _sermon(Battlefield.arg_value(args, "--case"))
```

  - After `_armoury_act()` add:

```gdscript
## The Sermon (v0.11 M5), with mission spec §3's policy (_sermon_act()), through _scripted().
func _sermon(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as SermonDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("sermon", which, func() -> String: return _sermon_act(rules, slots, d, crowd),
		func() -> String: return "believers=%d left=%d preaching=%s sentries=%d reports=%d gaze=%d phase=%s" % [d.believers_outside(),
			d.unturned().size(), d.preaching(), d.sentries_on_guard().size(), d.reports_started, roundi(d.gaze.value), d.hint_phase()])


## One look of The Sermon's policy (v0.11 M5): what was cast, or "". The first that applies: the preacher preaching, Discord on him; he
## and both acolytes held, Silent Doom on him (silenced for good); a report running, Silent Doom on its runner where the kill goes
## unseen; a sentry on guard, Silent Doom on him with no one else within SERMON_ALONE, else Mind Whisper sends one SERMON_AWAY off the
## door; no sentry on guard, Mind Whisper sends the unturned listener nearest the god's house, not rapt and able to hear, to its door;
## a sentry's relief walking in, Silent Doom on him. Will-o'-Wisp is a spare it does not use.
func _sermon_act(rules: Rules, slots: Dictionary, d: SermonDirector, crowd: Crowd) -> String:
	var pr: Variant = d.preacher
	if d.preaching() and _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, (pr as Person).ground_pos)
		return "discord the preacher"
	if WarningDirector._alive(pr) and not (pr as Person).inside and d.held(pr) and _slot_ready(rules, slots, "doom"):
		var all_held := true
		for a: Variant in d.acolytes:
			all_held = all_held and (not WarningDirector._alive(a) or d.held(a))
		if all_held:
			rules.cast(slots.doom, (pr as Person).ground_pos)
			return "doom the preacher"
	if _slot_ready(rules, slots, "doom"):
		for r in d.reports:
			if r.is_open() and WarningDirector._alive(r.carrier) and not r.carrier.inside and _tax_unseen(r.carrier, crowd):
				rules.cast(slots.doom, r.carrier.ground_pos)
				return "doom a report's runner"
	var on := d.sentries_on_guard()
	if not on.is_empty():
		if _slot_ready(rules, slots, "doom"):
			for p in on:
				if _none_within(crowd, p, SERMON_ALONE):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a sentry"
		if _slot_ready(rules, slots, "whisper"):
			for p in on:
				if p.shaken():
					continue
				var off := p.ground_pos - d.door
				var away := p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * SERMON_AWAY
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, away)})
				return "whisper a sentry off"
		return ""
	if _slot_ready(rules, slots, "whisper"):
		var best: Person = null
		for p in d.unturned():
			if d.rapt(p) or p.shaken() or p.mind == Person.Mind.WHISPERED:
				continue
			if best == null or p.ground_pos.distance_to(d.door) < best.ground_pos.distance_to(d.door):
				best = p
		if best != null:
			rules.cast(slots.whisper, best.ground_pos, {"target": best, "to": MindWhisperFx.clamp_to(crowd._grid, best.ground_pos, d.door)})
			return "whisper a listener to the house"
	var walker := d.relief_walking()
	if walker != null and _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, walker.ground_pos)
		return "doom a sentry's relief"
	return ""
```

- [ ] **Step 7: The gate.** Run the Scenario loop for `sermon`.
  - Expected for `none`: `won=false reason=sermon_over` in each, at 300.0.
  - For `play`: the gate. The spec expects about 3:35 (its sum: 10 + 45 + 45 + 15 + 30 + 45 + 15 + 20 ≈ 225 s). Write the measured
    clear and its sum (the first wave, then CHAIN after each wave spent, and the work on each) in the commit body; name any loss to the
    Gaze or the bell.
  - If it misses: first read the play log against the policy (does it silence him before whispering, does it Doom report runners
    unseen, does it idle with a slot ready while a listener can hear); then tune in this order: `CHAIN` (30-45), `WAVE` (3-4, NEED
    staying 8), `WAVE_AT[1]` (75-110), `READ` (6-10), `VOICE` (the spec's HEAR, 4-6).
  - Then the Scenario loop for `bishop` and `armoury` (Tasks 2-3), M3's eighteen and M4's eighteen. These six `sermon` lines are
    references from here on.

- [ ] **Step 8: The Reference check.** Expected: every value unchanged (Mira's House, and First Prayers' six among them).

- [ ] **Step 9: Spec sync.** In the mission spec's §3, bring the `Numbers` line, the timeline table, `The clear` and the hint lines (with
  the `bell` phase, plan decision 197) to what landed, and the waves' wait to plan decision 183 (held deaf at their sources). Change
  nothing else in the spec.

- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/sermon_director.gd src/game/mission/sermon_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd tests/test_sermon.gd tests/test_sermon.gd.uid tests/test_mission_hints.gd tests/run_all.gd docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md
git commit -m "feat: The Sermon -- a preacher who holds his crowd, four waves on the chain, sentries at the god's house (v0.11 M5)" -m "<the six sermon lines and checksums, the gate's verdict, the measured clear and its sum, any tuning rounds; the earlier M5 twelve, M3's and M4's 36 unchanged>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The Relic Run (Steal, reused)

**Files:**
- Create: `src/game/mission/relic_run_director.gd`, `tests/test_relic_run.gd`
- Modify: `src/game/mission/mission_book.gd` (new `relic_run()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd` (`LINES`), `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `tools/dev/behaviour_check.gd` (usage, consts, `_run()`, new `_relic()` / `_relic_act()` / `_relic_carry()`)
- Modify: `tests/test_mission_hints.gd` (`SPEC`), `tests/run_all.gd`
- Modify: the mission spec's §4 (synced, Step 9)

**Interfaces:**
- Consumes: Task 1's `VigilFlameDirector.hud_line()`, `FlameObjective._init(text, won, kept, lost)`, `TempleReport.skip`, `_tier4()`,
  `RELIC_RUN`; Task 2's `_none_within()`; `VigilFlameDirector`'s `vigil`, `temple_door`, `shrine`, `searchlight`, `wren`,
  `appeared`, `swapping`, `swap_left`, `swapped`, `home`, `kept`, `no_wren`, `touches`, `_lantern`, `_walk_pace`, `FlameGaze`,
  `_pace_bearer()`, `_listen()`, `_add_events()`, `_home_check()`, `_swap_step()`, `_wren_step()`, `_wren_goal()`, `_on_killed()`,
  `_phase2_begin()`, `_phase2_step()`, `_phase2_end()`, `wren_lost()`, `teardown()`, `RESUMABLE`, `SHRINE_REACH`, `TICK`;
  `VigilRoute` (`busy`, `pass_flame`, `flame_passed`, `leg`, `active`, `walkers()`, `ARRIVE`, `ACOLYTE_OFFSETS`); `Searchlight`;
  the behaviour tool's `_flame_carry()`.
- Produces:
  - `RelicRunDirector`: inner `Warden` (`man`, `post`, `checkpoint`, `slot`, `away`, `fallen`, `relief`); `ROUTE`, `HALT_LEGS`,
    `DROP_SPOT`, `PIP_SPOT`, `SET_OUT_AT`, `CART_PACE`, `COUNT`, `HALT_MAX`, `BOARD`, `LOCK`, `SWAP`, `CART_REACH`, `WATCH`,
    `PIP_PACE`, `ESCORTS`, `WARDENS`, `WARDEN_GAP`, `RETURN_AFTER`, `RELIEF_AFTER`, `RELIEFS`, `FAITHFUL_LAY`, `CART_CAMERA`;
    `route`, `checkpoints`, `drop_house`, `carter`, `escorts`, `wardens`, `set_out`, `halt`, `halts_done`, `halt_time`, `counted`,
    `aboard`, `lock_left`, `swap_spent`, `stalled`, `hands`, `reliefs`; `cart_at()`, `watched()`, `watchers_now()`, `next_halt()`,
    `halt_in()`, `wardens_at(k)`, `_set_out_cart()`, `_begin_halt(k)`, `_board()`, `_take_relic()`.
  - `MissionBook.relic_run() -> MissionDef`; the scenario `--scenario=relic`; six references.

- [ ] **Step 1: Write the failing test.** Create `tests/test_relic_run.gd`:

```gdscript
extends RefCounted
## v0.11 M5 The Relic Run (mission spec §4, RelicRunDirector, VigilFlameDirector reused): the relic cart -- its carter and two escorts,
## a VigilRoute -- sets out at 0:35 from the Temple for the Citadel, halting at two watch-houses for the watch's count; its reliquary
## opens only while it halts. Pip, from the start, slips aboard at a halt once no one watches, picks the lock on the way, and swaps the
## relic at the second halt only, unseen by rule (no report); then carries it to your believers' house under the Searchlight. A dead
## driver's reins pass on; all three dead stall the cart until new hands come, its reliquary locked. The relic at the Citadel, Pip dead
## or gone, or the Gaze lose. Wardens return and are relieved; a seen death sends a report. The evacuation passes them by (review focus
## 2); freed bodies are borne (review focus 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_halt(t)
	_moving(t)
	_board(t)
	_rolls_on(t)
	_swap(t)
	_no_first_swap(t)
	_stall(t)
	_ends(t)
	_seen(t)
	_wardens(t)
	_evacuate(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.relic_run())


## The cart at its `k`th checkpoint now (v0.11 M5 tests): set out if need be, its route's leg there, and its carter and escorts set
## down at it (headless people never walk).
static func _at_halt(s: Dictionary, d: RelicRunDirector, k: int) -> void:
	if not d.set_out:
		d._set_out_cart()
	d.vigil.leg = int(RelicRunDirector.HALT_LEGS[k]) - d._leg_base
	var at := d.checkpoints[k]
	Kit.arrive(d.vigil.bearer, at)
	for i in d.vigil.acolytes.size():
		Kit.arrive(d.vigil.acolytes[i], at + (VigilRoute.ACOLYTE_OFFSETS[i % 2] as Vector2))
	Kit.run_for(s, 0.1)


## Everyone who watches the cart now held by Discord (it never lifts headless) (v0.11 M5 tests).
static func _blind(d: RelicRunDirector) -> void:
	for p in d.watchers_now():
		p.confuse(60.0)


static func _setup(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	t.check(d.route.size() == 6 and d.checkpoints.size() == 2 and d.checkpoints[0].distance_to(Vector2(9.5, -5.1)) < 1.0
		and d.checkpoints[1].distance_to(Vector2(-6.0, 9.0)) < 1.0 and d.route[5].distance_to(Vector2(-10.5, -7.6)) < 1.0,
		"the route: the east and west watch-houses its checkpoints, the Citadel's gate its end")
	t.check(d.drop_house != null and RuinWish.fits(d.drop_house, "house") and d.drop_house.center().distance_to(RelicRunDirector.DROP_SPOT) < 5.0
		and d.shrine != Vector2.INF, "your believers' house: the dwelling by the north-east point, its door the drop-off")
	var pip := d.wren
	t.check(MissionDirector._alive(pip) and d.appeared and not d.faithful.has(pip) and pip.mind == Person.Mind.DUTY
		and pip.ground_pos.distance_to(RelicRunDirector.PIP_SPOT) < 1.5, "Pip, a lay citizen east of the market, on duty from the start, never Faithful")
	var c := d.carter as Person
	var ok := c != null and not d.faithful.has(c) and c.ground_pos.distance_to(d.temple_door) < 0.5 and d.escorts.size() == RelicRunDirector.ESCORTS
	for v: Variant in d.escorts:
		ok = ok and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(v)
	t.check(ok and d._lantern.distance_to(d.temple_door) < 0.5 and not d.set_out, "the cart waits at the Temple's door: its carter (no Faithful) and two Faithful escorts")
	var posted := d.wardens.size() == 2 * RelicRunDirector.WARDENS
	for k in 2:
		var at := d.wardens_at(k)
		posted = posted and at.size() == 2 and at[0].ground_pos.distance_to(at[1].ground_pos) > 2.0 * SilentDoom.RADIUS
		for p in at:
			posted = posted and p.profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p) and p.mind == Person.Mind.DUTY
	t.check(posted, "two wardens at each watch-house, one Doom apart, Faithful watchmen on duty")
	var ids := []
	for e in d.timeline.upcoming(2):
		ids.append(e.id)
	t.check(ids == ["set_out", "search"], "the strip: the relic sets out; the light's search (%s)" % [ids])
	t.check(Kit.clear_of_stack(d.temple_door, RelicRunDirector.CART_CAMERA) and Kit.clear_of_stack(pip.ground_pos, RelicRunDirector.CART_CAMERA)
		and Kit.clear_of_stack(d.checkpoints[0], RelicRunDirector.CART_CAMERA) and Kit.clear_of_stack(d.checkpoints[1], RelicRunDirector.CART_CAMERA)
		and Kit.clear_of_stack(d.shrine, RelicRunDirector.CART_CAMERA), "the camera keeps the cart, Pip, both checkpoints and the drop-off (or their arrows) clear of the HUD stack")
	var m := MissionBook.relic_run()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 4 and is_equal_approx(m.clock, 390.0) and reasons == ["gaze", "relic", "dawn"]
		and Array(m.default_loadout) == ["whisper", "discord", "doom", "wisp"] and MissionBook.get_mission("relic_run").id == "relic_run",
		"the mission: Tier 4's numbers; the Gaze, the relic, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var crowd: Crowd = s.crowd
	crowd.rally()
	crowd._regroup()
	crowd._evacuate()
	var held := d.wren.mind == Person.Mind.DUTY and (d.carter as Person).mind == Person.Mind.DUTY
	for w: RelicRunDirector.Warden in d.wardens:
		held = held and (w.man as Person).mind == Person.Mind.DUTY
	t.check(held, "the regroup and the evacuation pass Pip, the cart and the wardens by (review focus 2)")
	Kit.done(s)


static func _halt(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	Kit.run_for(s, RelicRunDirector.SET_OUT_AT + DT)
	t.check(d.set_out and d.vigil != null and d.vigil.active and (s.banners as Array).has("THE RELIC SETS OUT") and d.hint_phase() == "moving",
		"at 0:35 the relic sets out")
	_at_halt(s, d, 0)
	var stepped := true
	for p in d.wardens_at(0):
		stepped = stepped and p.anchor.distance_to(d.cart_at()) < 1.5
	t.check(d.halt == 0 and d.vigil.leg == 0 and stepped and (s.banners as Array).has("THE CART HALTS AT THE EAST WATCH-HOUSE"),
		"at the east watch-house the cart halts; its wardens step up for the count")
	Kit.run_for(s, RelicRunDirector.COUNT + 0.6)
	t.check(d.halt == -1 and d.halts_done[0] and (s.banners as Array).has("THE CART ROLLS ON") and d.vigil.leg == 1,
		"the count done with the watch at the cart, the reliquary closes and the cart rolls on")
	Kit.done(s)


static func _moving(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	Kit.arrive(d.wren, d.cart_at())
	d.wren.whisper(d.cart_at(), MindWhisperFx.LINGER)
	Kit.run_for(s, RelicRunDirector.BOARD + 1.0)
	t.check(not d.aboard and d.halt < 0, "no hand reaches the relic while the cart moves")
	Kit.done(s)


static func _board(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at() + Vector2(0.0, 0.6))
	Kit.run_for(s, RelicRunDirector.BOARD + 0.5)
	t.check(d.watched() and not d.aboard and Kit.labels(d).has("PIP - WAITING") and d.hint_phase() == "watched",
		"by a watched cart Pip waits: he never boards while watched")
	_blind(d)
	Kit.run_for(s, RelicRunDirector.BOARD + 0.2)
	t.check(not d.watched() and d.aboard and d.wren.inside and (s.banners as Array).has("PIP SLIPS ABOARD")
		and d.hud_line() == "The relic: Pip at the lock", "the watch held, BOARD seconds unwatched and he slips aboard, hidden")
	Kit.done(s)


static func _rolls_on(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at())
	d._board()
	Kit.run_for(s, RelicRunDirector.COUNT + 0.6)
	t.check(d.halts_done[0] and d.halt == -1 and d.aboard and d.wren.inside, "a cart with Pip aboard leaves the first halt once its count is done")
	Kit.run_for(s, RelicRunDirector.LOCK + 0.5)
	t.check(d.lock_left <= 0.0 and Kit.labels(d)[0] == "RELIC CART - PIP ABOARD" and d.hud_line() == "The relic: Pip aboard"
		and d.wren.ground_pos.is_equal_approx(d.cart_at()) and d.hint_phase() == "aboard", "he picks the lock on the way, carried with the cart")
	Kit.done(s)


static func _swap(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d._board()
	d.lock_left = 0.0
	_at_halt(s, d, 1)
	Kit.run_for(s, RelicRunDirector.SWAP + 0.5)
	t.check(d.halt == 1 and not d.swapped and d.watched(), "at the second halt, watched: no swap")
	_blind(d)
	Kit.run_for(s, RelicRunDirector.SWAP + 0.3)
	t.check(d.swapped and not d.aboard and not d.wren.inside and d.wren.anchor == d.shrine and d.searchlight.on and d.reports_started == 0
		and (s.banners as Array).has("THE RELIC IS TAKEN") and d.hint_phase() == "carry"
		and d.hud_line().begins_with("The relic to your believers: "), "SWAP seconds unwatched: he swaps it, slips out and makes for your believers' house; no report, the light wakes")
	Kit.arrive(d.wren, d.shrine)
	Kit.run_for(s, 0.1)
	var main: Objective = (s.rules as Rules).objectives[1]
	t.check(d.home and main.check(s.rules) == Objective.Status.DONE and main.reason == "relic" and (s.banners as Array).has("THE RELIC IS OURS"),
		"at your believers' door: the relic is ours")
	Kit.done(s)


static func _no_first_swap(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	_at_halt(s, d, 0)
	Kit.arrive(d.wren, d.cart_at())
	d._board()
	d.lock_left = 0.0
	_blind(d)
	Kit.run_for(s, RelicRunDirector.SWAP + 1.0)
	t.check(d.aboard and not d.swapped, "the swap waits for the second halt (plan decision 192): the drop-off is not reached from the first")
	Kit.done(s)


static func _stall(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	var at := d.cart_at()
	for v: Variant in d.vigil.walkers():
		Kit.free_body(s, v)
	Kit.run_for(s, 0.1)
	t.check(d.stalled and d.cart_at().is_equal_approx(at) and (s.banners as Array).has("THE CART STANDS"), "the three dead: the cart stands where the last fell")
	Kit.arrive(d.wren, at)
	Kit.run_for(s, RelicRunDirector.BOARD + 0.5)
	t.check(not d.aboard and d.halt < 0, "killing its people never opens the reliquary")
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER)
	t.check(d.hands.size() == 1 + RelicRunDirector.ESCORTS and (d.hands[0] as Person).anchor.is_equal_approx(at)
		and (s.banners as Array).has("NEW HANDS COME FROM THE TEMPLE"), "RELIEF_AFTER later new hands walk from the Temple to the cart")
	Kit.arrive(d.hands[0] as Person, at)
	Kit.run_for(s, 0.1)
	t.check(not d.stalled and d.vigil != null and d.vigil.active and d.vigil.route[0].is_equal_approx(d.route[d._leg_base]),
		"at the cart they take it on, along the rest of its route")
	Kit.done(s)


static func _ends(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d.halts_done[1] = true
	d.vigil.leg = d.route.size() - 1
	Kit.arrive(d.vigil.bearer, d.route[d.route.size() - 1])
	Kit.run_for(s, 0.6)
	var main: Objective = (s.rules as Rules).objectives[1]
	t.check(d.kept and main.check(s.rules) == Objective.Status.FAILED and main.reason == "relic_kept", "the cart at the Citadel's gate with the relic: lost")
	Kit.done(s)
	var p := _world()
	Kit.free_body(p, (p.d as RelicRunDirector).wren)
	var pm: Objective = (p.rules as Rules).objectives[1]
	t.check(pm.check(p.rules) == Objective.Status.FAILED and pm.reason == "pip", "Pip dead or gone: lost at once")
	Kit.done(p)


static func _seen(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var a := d.escorts[0] as Person
	var b := d.escorts[1] as Person
	Kit.arrive(b, a.ground_pos + Vector2(1.4, 0.0))
	Kit.free_body(s, a)
	Kit.run_for(s, 0.1)
	t.check(d.reports_started == 1 and d.reports[0].skip.is_valid(), "a death a Faithful sees sends him to the Temple, his relay passing over the fleeing")
	Kit.done(s)


static func _wardens(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var w: RelicRunDirector.Warden = d.wardens[2]
	var dead: Variant = w.man
	Kit.free_body(s, dead)
	Kit.run_for(s, RelicRunDirector.RELIEF_AFTER + 1.0)
	var p: Variant = w.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and d.faithful.has(p)
		and (p as Person).anchor == w.post and w.relief and d.reliefs == 1, "RELIEF_AFTER after a warden falls, a Faithful watchman walks to his post")
	var o: RelicRunDirector.Warden = d.wardens[3]
	var op := o.man as Person
	Kit.arrive(op, o.post + Vector2(6.0, 0.0))
	op.mind = Person.Mind.CALM
	Kit.run_for(s, RelicRunDirector.RETURN_AFTER + 1.0)
	t.check(op.mind == Person.Mind.DUTY and op.anchor == o.post, "one off his post and calm walks back RETURN_AFTER after he left")
	Kit.done(s)


static func _evacuate(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	d.halts_done[0] = true
	d.vigil.leg = 1
	d._board()
	var w: RelicRunDirector.Warden = d.wardens[2]
	var wp := w.man as Person
	wp.mind = Person.Mind.RECOVER
	var e := d.escorts[0] as Person
	e.whisper(e.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(s)
	t.check(wp.mind == Person.Mind.FLEE and e._whisper_fled, "(set-up) the evacuation sends the recovering warden running, and owes the whispered escort a flight")
	Kit.run_for(s, 0.6)
	t.check(wp.mind == Person.Mind.DUTY and wp.anchor == w.post and not e._whisper_fled and d.aboard and d.wren.inside
		and (d.carter as Person).mind == Person.Mind.DUTY and d.vigil.active,
		"in the cart's second leg: the second checkpoint's warden holds his post, the escort's flight is ended, Pip stays hidden, the cart walks on")
	Kit.done(s)
	var c := _world()
	var cd: RelicRunDirector = c.d
	cd._set_out_cart()
	cd.halts_done[0] = true
	cd._board()
	cd.lock_left = 0.0
	cd._take_relic()
	var pip := cd.wren
	pip.whisper(pip.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	Kit.evacuate(c)
	Kit.run_for(c, 0.6)
	pip._wake()
	Kit.run_for(c, 0.6)
	t.check(pip.mind == Person.Mind.DUTY and pip.anchor == cd.shrine and not pip._whisper_fled,
		"whispered with the relic when it begins, he takes up his walk to your believers' house, not the gates")
	Kit.done(c)


static func _tagged(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	var labels := Kit.labels(d)
	t.check(labels.slice(0, 4) == ["RELIC CART", "PIP - DO NOT KILL", "CHECKPOINT", "BELIEVERS' HOUSE"] and Kit.edged(d, "RELIC CART")
		and Kit.edged(d, "PIP - DO NOT KILL") and Kit.edged(d, "CHECKPOINT") and Kit.edged(d, "BELIEVERS' HOUSE") and labels.has("ESCORT")
		and labels.has("WARDEN") and not labels.has("CITADEL") and d.hint_phase() == "" and d.hud_line() == "The relic: in its cart",
		"the cart, Pip (DO NOT KILL), the first checkpoint, your believers' house, all pointed at; the escorts and wardens (%s)" % [labels])
	_at_halt(s, d, 0)
	t.check(Kit.labels(d)[0] == "RELIC CART - HALTED 50", "halted: its window's seconds (%s)" % Kit.labels(d)[0])
	d.halts_done[0] = true
	d.halt = -1
	d.vigil.leg = 1
	Kit.run_for(s, 0.1)
	t.check(d.hint_phase() == "citadel", "the first halt passed and Pip not aboard: the next halt is the last")
	_at_halt(s, d, 1)
	t.check(Kit.labels(d).has("CITADEL") and Kit.edged(d, "CITADEL"), "from the second halt on, the Citadel")
	(s.crowd as Crowd).bell.state = BellNetwork.State.CALLED
	t.check(d.hint_phase() == "bell", "the bell called: the bell's warning first")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]).begins_with("The relic cart at the Temple.") and String(tour[1][1]).begins_with("Pip."),
		"the tour: the cart, Pip, your believers' house")
	t.check(ResultsScreen.ACT_TITLES.get("relic") == "THE RELIC IS OURS" and ResultsScreen.ACT_TITLES.get("relic_kept") == "THE RELIC REACHES THE CITADEL"
		and ResultsScreen.ACT_TITLES.get("pip") == "THE BOY IS DEAD", "its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: RelicRunDirector = s.d
	d._set_out_cart()
	var out: Array = d.vigil.walkers()
	for w: RelicRunDirector.Warden in d.wardens:
		out.append(w.man)
	for v: Variant in out:
		Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.stalled and d.wardens_at(0).is_empty() and d.wardens_at(1).is_empty() and int(d.report().halts) == 0,
		"the cart's people and the wardens freed: the tags, hint and report bear it (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_relic_run.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then Tests. Expected: parse errors (`RelicRunDirector`, `MissionBook.relic_run`).

- [ ] **Step 3: Create `src/game/mission/relic_run_director.gd`:**

```gdscript
class_name RelicRunDirector
extends VigilFlameDirector
## The Relic Run (v0.11 M5, Tier 4, mission spec §4; Steal, reused): the Temple's relic rides to the Citadel. Its cart is its carter
## (a resident) and two escorts walking a VigilRoute at CART_PACE from the Temple's door at SET_OUT_AT, by ROUTE, to the Citadel's gate;
## a dead driver's reins pass to an escort, and with all three dead the cart stands until new hands come from the Temple RELIEF_AFTER
## later (plan decision 196). At each checkpoint (the east and west watch-houses, HALT_LEGS) it halts (VigilRoute.busy, plan decision
## 194) for the watch's count: COUNT seconds with one of the watch (the checkpoint's wardens or the escorts) at the cart and not held,
## HALT_MAX at most; its reliquary opens only then. The cart is watched while a Faithful not held stands within WATCH of it (the
## escorts and wardens are Faithful; the carter is not). Pip, a lay citizen east of the market from the start, holds where a whisper
## leaves him; within CART_REACH of a halted cart unwatched BOARD seconds in a row he slips aboard, hidden; aboard he picks the lock
## (LOCK seconds, rolling or unwatched at a halt); at the second halt, SWAP seconds unwatched in all, he swaps the relic and slips out
## (plan decision 192), unseen by rule -- no report. Then he carries it at PIP_PACE to your believers' house (the dwelling nearest
## DROP_SPOT) under The Vigil Flame's Searchlight. The relic at the Citadel's gate loses ("relic_kept"), so does Pip dead or gone
## ("pip") or the Gaze. Two wardens at each watch-house, Faithful watchmen: one off his post walks back RETURN_AFTER after he left, a
## fallen one is replaced RELIEF_AFTER later (RELIEFS at most). A seen death sends a Faithful to the Temple (plan decision 195); a
## report delivered fills the Gaze; the bell fills it (plan decisions 191-199).

## One warden's post (v0.11 M5): a plain record, so the director holds no cycle.
class Warden:
	extends RefCounted
	## The warden, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## Where he stands; his checkpoint (0 east, 1 west) and his place at the count (0 or 1).
	var post := Vector2.INF
	var checkpoint := 0
	var slot := 0
	## Seconds since he was last at his place (alive), and since he fell; he is a relief walking in.
	var away := 0.0
	var fallen := 0.0
	var relief := false


## The cart's route from the Temple's door (v0.11 M5, Decision 151): east along the cathedral street, south, west, north, to the
## Citadel's lane and its gate; the legs at which it halts (the east and west watch-houses), and their names.
const ROUTE := [Vector2(9.5, -5.1), Vector2(9.5, 9.0), Vector2(-6.0, 9.0), Vector2(-6.0, -5.1), Vector2(-10.5, -5.1), Vector2(-10.5, -7.6)]
const HALT_LEGS := [0, 2]
const CHECK_WORDS := ["the east watch-house", "the west watch-house"]
## Your believers' house is the dwelling nearest DROP_SPOT; Pip is the lay citizen nearest PIP_SPOT (v0.11 M5).
const DROP_SPOT := Vector2(12.5, -12.0)
const PIP_SPOT := Vector2(6.0, 2.5)
## Mission spec §4's numbers (v0.11 M5), first guesses, tuned by Step 7's gate in this order: the drop-off's point (25-35 units from the
## second halt), CART_PACE (0.35-0.5), COUNT (15-25), SET_OUT_AT (25-45); HALT_MAX stays under 60. The set-out; the cart's pace; the
## count and the halt's limit; boarding, the lock and the swap; how near the cart Pip must be and the watch sees; Pip's pace with the
## relic; the cart's people and the wardens; return and relief; the Faithful.
const SET_OUT_AT := 35.0
const CART_PACE := 0.42
const COUNT := 20.0
const HALT_MAX := 50.0
const BOARD := 2.0
const LOCK := 8.0
const SWAP := 4.0
const CART_REACH := 1.0
const WATCH := 2.0
const PIP_PACE := 0.5
const ESCORTS := 2
const WARDENS := 2
const WARDEN_GAP := 2.6
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const FAITHFUL_LAY := 12
## How far from the cart the wardens stand at the count; how near his place a warden is at it; how near the Citadel's gate the cart has
## it (v0.11 M5).
const COUNT_OFF := 1.0
const POST_REACH := 1.5
const CITADEL_REACH := 1.0
## Where the camera rests (v0.11 M5, Decision 159): the Temple's door above the centre, the east watch-house at the right, Pip below.
const CART_CAMERA := Vector2(4.0, -3.0)
## The tags' colours (v0.11 M5, mission spec §0): the cart gold, Pip steel blue, places orange.
const MARK_CART := Color("d8b23a")
const MARK_PIP := Color("8fb8e8")
const MARK_PLACE := Color("ff9a3a")

## The route on walkable ground, and its checkpoints (v0.11 M5).
var route := PackedVector2Array()
var checkpoints: Array[Vector2] = []
## Your believers' house (v0.11 M5); its door is `shrine`.
var drop_house: Structure
## The cart's carter and escorts now (Variants: any may be freed), and the wardens (v0.11 M5).
var carter: Variant = null
var escorts: Array = []
var wardens: Array = []
## It has set out; the checkpoint it halts at (-1 rolling); each halt done; the halt's seconds and the count's (v0.11 M5).
var set_out := false
var halt := -1
var halts_done: Array[bool] = [false, false]
var halt_time := 0.0
var counted := 0.0
## Pip is aboard; the lock's seconds left; the swap's seconds so far; the cart unwatched this long at a halt (v0.11 M5).
var aboard := false
var lock_left := LOCK
var swap_spent := 0.0
var unwatched_for := 0.0
## The cart stands, its people dead; seconds to new hands; the new hands walking to it (the carter first); reliefs come (v0.11 M5).
var stalled := false
var stall_left := 0.0
var hands: Array = []
var reliefs := 0
## The route's leg the cart's VigilRoute starts from (a new one, after a stall, walks the rest) (v0.11 M5).
var _leg_base := 0
## Where deaths fell, to be judged once the cast's victims have fallen (v0.11 M5).
var _falls: Array[Vector2] = []
## Seconds into the night, and to the next look (v0.11 M5).
var _clock := 0.0
var _look_in := 0.0


## The night's setup (v0.11 M5, in place of The Vigil Flame's): the Gaze, the Temple's door, the Searchlight (asleep), the route and its
## checkpoints, your believers' house, the people, the signals, the strip (the set-out, the light's search).
func _begin() -> void:
	gaze = VigilFlameDirector.FlameGaze.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	searchlight = Searchlight.new().setup(TownLayout.TEMPLE.get_center())
	for p: Vector2 in ROUTE:
		route.append(_walkable(p))
	for k: int in HALT_LEGS:
		checkpoints.append(route[k])
	drop_house = _house_near(DROP_SPOT)
	var door := _open_door(drop_house, checkpoints[checkpoints.size() - 1]) if drop_house != null else Vector2.INF
	shrine = door if door != Vector2.INF else (_front_of(drop_house) if drop_house != null else _walkable(DROP_SPOT))
	_choose_people()
	_lantern = (carter as Person).ground_pos if _alive(carter) else temple_door
	crowd._field.enemy_killed.connect(_on_killed)
	_listen()
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	timeline.add(SET_OUT_AT, "set_out", "The relic sets out", _set_out_cart)
	_add_events()
	rules.banner.emit("THE RELIC RUN")


## The people (v0.11 M5): Pip, set down on duty; the carter (the resident nearest the Temple's door) and two escorts at it; two wardens
## at each checkpoint; then every cleric and FAITHFUL_LAY of the rest are Faithful (never Pip or the carter).
func _choose_people() -> void:
	var taken: Array = []
	var pip := _lay_near(_walkable(PIP_SPOT), 1, taken)
	if pip.is_empty():
		no_wren = true
	else:
		wren = pip[0]
		taken.append(wren)
		_set_down(wren, _walkable(PIP_SPOT))
		wren.go_duty(wren.ground_pos)
		appeared = true
	var c := _citizen_near(temple_door, CitizenProfile.Role.RESIDENT, taken)
	if c == null:
		var any := _lay_near(temple_door, 1, taken)
		c = any[0] if not any.is_empty() else null
	if c != null:
		carter = c
		taken.append(c)
		_set_down(c, temple_door)
		c.go_duty(temple_door)
	for k in ESCORTS:
		var near := _lay_near(temple_door, 1, taken)
		if near.is_empty():
			break
		var e := near[0]
		_make_watch(e)
		taken.append(e)
		escorts.append(e)
		var spot := _walkable(temple_door + (VigilRoute.ACOLYTE_OFFSETS[k % 2] as Vector2))
		_set_down(e, spot)
		e.go_duty(spot)
	for k in checkpoints.size():
		for j in WARDENS:
			var w := Warden.new()
			w.checkpoint = k
			w.slot = j
			w.post = _walkable(checkpoints[k] + Vector2(WARDEN_GAP * (float(j) - 0.5), 0.0))
			var near := _lay_near(w.post, 1, taken)
			if not near.is_empty():
				var p := near[0]
				_make_watch(p)
				taken.append(p)
				w.man = p
				_set_down(p, w.post)
				p.go_duty(w.post)
			wardens.append(w)
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in clergy:
		if not faithful.has(p):
			_make_faithful(p)
	var rest: Array[Person] = []
	for p in lay:
		if p.profile.faith == CitizenProfile.Faith.NONE and not p.profile.role in Wish.NOT_LAY and not taken.has(p):
			rest.append(p)
	_spread_faithful(rest, FAITHFUL_LAY)


## `p` made one of the watch (v0.11 M5): a watchman (the cloak and lantern) and one of Halcyon's Faithful.
func _make_watch(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN
	_make_faithful(p)


## Everyone at the run's work (v0.11 M5), for a new one to leave out.
func _busy() -> Array:
	var out: Array = [wren, carter]
	out.append_array(escorts)
	out.append_array(hands)
	for w: Warden in wardens:
		out.append(w.man)
	return out


## The relic sets out (v0.11 M5, the timeline's event): the cart walks the route.
func _set_out_cart() -> void:
	if set_out:
		return
	set_out = true
	_start_route(route, carter, escorts)


## A VigilRoute for the cart along `points` (v0.11 M5): `bearer` the carter, `helpers` his escorts; the reins pass on a death; the
## halts ride on its busy callable (_cart_busy()); its walkers at CART_PACE, the carter keeping beside his escorts (_pace_bearer()).
func _start_route(points: PackedVector2Array, bearer: Variant, helpers: Array) -> void:
	if not _alive(bearer):
		return
	var by: Array[Person] = []
	for v: Variant in helpers:
		if _alive(v):
			by.append(v as Person)
	vigil = VigilRoute.new().setup(points, bearer as Person, by)
	vigil.pass_flame = true
	vigil.busy = _cart_busy
	vigil.flame_passed.connect(_on_reins)
	for p in vigil.walkers():
		_walk_pace[p] = p.pace
		p.pace *= CART_PACE
	_pace_bearer()
	vigil.start()


## The reins passed to an escort (v0.11 M5): the new carter keeps beside the one left.
func _on_reins(_to: Person) -> void:
	_pace_bearer()
	if not swapped:
		rules.banner.emit("AN ESCORT TAKES THE REINS")


## VigilRoute.busy for the cart (v0.11 M5, plan decision 194): a walker carrying a report; the carter while the cart halts or stands at
## the next checkpoint's point -- the walk waits for him.
func _cart_busy(p: Person) -> bool:
	if _carrying(p):
		return true
	return vigil != null and p == vigil.bearer and (halt >= 0 or _at_checkpoint())


## The cart stands at the next checkpoint's point (v0.11 M5): its leg is that checkpoint's, its carter within VigilRoute.ARRIVE of it.
func _at_checkpoint() -> bool:
	var k := next_halt()
	if k < 0 or vigil == null or not vigil.active or not _alive(vigil.bearer):
		return false
	var leg := _leg_base + vigil.leg
	return leg == int(HALT_LEGS[k]) and vigil.bearer.ground_pos.distance_to(route[leg]) <= VigilRoute.ARRIVE


## The next checkpoint not yet passed, or -1 (v0.11 M5).
func next_halt() -> int:
	for k in halts_done.size():
		if not halts_done[k]:
			return k
	return -1


## Where the cart (and the relic) is (v0.11 M5). Only reads.
func cart_at() -> Vector2:
	return _lantern


## One step (v0.11 M5, plan decision 191, in place of The Vigil Flame's): the strip and the Gaze; every TICK the evacuation rule; the
## cart and its halts; the seen deaths; the reports; the swap; Pip; the wardens; phase 2; the bell.
func step(delta: float) -> void:
	_clock += delta
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	_look_in -= delta
	var looking := _look_in <= 0.0
	if looking:
		_look_in = TICK
		_keep_held(_evacuation_began())
	_cart_step(delta)
	if not _falls.is_empty() and crowd._doomed.is_empty():
		_judge_falls()
	_step_reports(delta)
	if not swapped:
		_home_check()
		_swap_step(delta)
	_wren_step(delta)
	_wardens_step(delta, looking)
	_phase2_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


## The cart (v0.11 M5): its walk, the relic with its carter; all three dead, it stands (and waits for new hands); at the next checkpoint
## it halts; a halt ends once the count is done or after HALT_MAX.
func _cart_step(delta: float) -> void:
	if vigil != null:
		vigil.step(delta)
		if vigil.active and _alive(vigil.bearer):
			_lantern = vigil.bearer.ground_pos
		elif not vigil.active and vigil.walkers().is_empty() and not stalled and not kept:
			stalled = true
			stall_left = RELIEF_AFTER
			_leg_base += vigil.leg
			vigil = null
			rules.banner.emit("THE CART STANDS")
	if stalled:
		_stall_step(delta)
	if halt < 0:
		var k := next_halt()
		if k >= 0 and _at_checkpoint():
			_begin_halt(k)
		return
	halt_time += delta
	if _count_ok():
		counted += delta
	if counted >= COUNT or halt_time >= HALT_MAX:
		_end_halt()


## A stalled cart (v0.11 M5, plan decision 196): RELIEF_AFTER after it stood, new hands; at the cart, they take it on.
func _stall_step(delta: float) -> void:
	if hands.is_empty():
		stall_left -= delta
		if stall_left <= 0.0:
			_new_hands()
		return
	if not _alive(hands[0]):
		hands = hands.filter(func(v: Variant) -> bool: return _alive(v))
		if hands.is_empty():
			stall_left = RELIEF_AFTER
		return
	var lead := hands[0] as Person
	if lead.ground_pos.distance_to(_lantern) <= VigilRoute.ARRIVE + 0.3:
		stalled = false
		var rest: Array = hands.slice(1)
		hands = []
		_start_route(route.slice(_leg_base), lead, rest)
	elif lead.mind in RESUMABLE:
		lead.go_duty(_lantern)


## New hands for the cart (v0.11 M5): the resident nearest the Temple's door (else a lay citizen) and two lay escorts, made Faithful
## watchmen, walking on duty to the cart.
func _new_hands() -> void:
	var busy := _busy()
	var lead := _citizen_near(temple_door, CitizenProfile.Role.RESIDENT, busy)
	if lead == null:
		var any := _lay_near(temple_door, 1, busy)
		lead = any[0] if not any.is_empty() else null
	if lead == null:
		stall_left = RELIEF_AFTER
		return
	hands = [lead]
	lead.go_duty(_lantern)
	for k in ESCORTS:
		var near := _lay_near(temple_door, 1, busy + hands)
		if near.is_empty():
			break
		_make_watch(near[0])
		hands.append(near[0])
		near[0].go_duty(_walkable(_lantern + (VigilRoute.ACOLYTE_OFFSETS[k % 2] as Vector2)))
	carter = lead
	escorts = hands.slice(1)
	rules.banner.emit("NEW HANDS COME FROM THE TEMPLE")


## The cart halts at checkpoint `k` (v0.11 M5): the reliquary opens for the count; that checkpoint's wardens step up to the cart.
func _begin_halt(k: int) -> void:
	halt = k
	halt_time = 0.0
	counted = 0.0
	unwatched_for = 0.0
	rules.banner.emit("THE CART HALTS AT %s" % String(CHECK_WORDS[k]).to_upper())
	for w: Warden in wardens:
		if w.checkpoint == k and _alive(w.man) and not (w.man as Person).inside:
			(w.man as Person).go_duty(_count_spot(w))


## Warden `w`'s place at the count (v0.11 M5): COUNT_OFF from the cart, his slot's side.
func _count_spot(w: Warden) -> Vector2:
	return _ring_spot(_lantern, COUNT_OFF, w.slot, WARDENS, 0.5)


## The halt ends (v0.11 M5): the reliquary closes, the wardens go back to their posts, and the cart rolls on.
func _end_halt() -> void:
	var k := halt
	halts_done[k] = true
	halt = -1
	for w: Warden in wardens:
		if w.checkpoint == k:
			_recall_to(w.man, w.post)
	rules.banner.emit("THE CART ROLLS ON")


## The count runs (v0.11 M5): one of the watch -- the halt's wardens or the escorts -- alive, out of doors, not held, within WATCH of the
## cart.
func _count_ok() -> bool:
	var watch: Array = escorts.duplicate()
	for w: Warden in wardens:
		if w.checkpoint == halt:
			watch.append(w.man)
	for v: Variant in watch:
		if _alive(v):
			var p := v as Person
			if not p.inside and not p.mind in BLIND and p.ground_pos.distance_to(_lantern) <= WATCH:
				return true
	return false


## The cart is watched now (v0.11 M5, plan decision 193): a Faithful not held within WATCH of it. Only reads.
func watched() -> bool:
	return faithful_seeing(_lantern, WATCH) != null


## Every Faithful watching the cart now (v0.11 M5, for the policy and the tags). Only reads.
func watchers_now() -> Array[Person]:
	return watchers(_lantern, WATCH)


## Checkpoint `k`'s living wardens out of doors (v0.11 M5). Only reads.
func wardens_at(k: int) -> Array[Person]:
	var out: Array[Person] = []
	for w: Warden in wardens:
		if w.checkpoint == k and _alive(w.man) and not (w.man as Person).inside:
			out.append(w.man as Person)
	return out


## The heist at a halt, in place of the base's swap (v0.11 M5, plan decision 192): rolling, Pip aboard picks the lock; halted, Pip
## within CART_REACH boards after BOARD seconds unwatched in a row; aboard, the lock goes on while unwatched; at the last halt, the lock
## open, SWAP seconds unwatched in all swap the relic.
func _swap_step(delta: float) -> void:
	if not _alive(wren):
		return
	if halt < 0:
		unwatched_for = 0.0
		if aboard and vigil != null and vigil.active:
			lock_left = maxf(lock_left - delta, 0.0)
		return
	var seen := watched()
	unwatched_for = 0.0 if seen else unwatched_for + delta
	if not aboard:
		if not wren.inside and wren.ground_pos.distance_to(_lantern) <= CART_REACH and unwatched_for >= BOARD:
			_board()
		return
	if seen:
		return
	if lock_left > 0.0:
		lock_left = maxf(lock_left - delta, 0.0)
		return
	if halt != HALT_LEGS.size() - 1:
		return
	swapping = true
	swap_spent += delta
	swap_left = maxf(SWAP - swap_spent, 0.0)
	if swap_spent >= SWAP:
		_take_relic()


## Pip slips aboard (v0.11 M5): on duty where he stands, then hidden in the cart's straw, carried with it.
func _board() -> void:
	aboard = true
	wren.go_duty(wren.ground_pos)
	_take_inside(wren, null)
	rules.banner.emit("PIP SLIPS ABOARD")


## The relic swapped (v0.11 M5, plan decision 191): Pip slips out at the cart's side with it, unseen by rule (no report), and makes for
## your believers' house at PIP_PACE; the spire flares and the Searchlight wakes.
func _take_relic() -> void:
	swapping = false
	swapped = true
	aboard = false
	_bring_out(wren, _walkable(_lantern + Vector2(0.0, 0.8)))
	_keep_from_flight(wren, true)
	rules.banner.emit("THE RELIC IS TAKEN")
	wren.pace *= PIP_PACE
	wren.go_duty(shrine)
	_phase2_begin()


## The relic reaches the Citadel's gate with its cart (v0.11 M5, in place of the Temple): kept, and the night is lost.
func _home_check() -> void:
	if vigil == null or not _alive(vigil.bearer) or route.is_empty():
		return
	if vigil.bearer.ground_pos.distance_to(route[route.size() - 1]) <= CITADEL_REACH:
		kept = true


## Pip's errand, every frame (v0.11 M5, in place of Wren's): aboard he rides with the cart; with the relic at your believers' door it is
## home; back on his feet he holds where he stands, or, with the relic, walks on to the house. A whisper is the god's: he is left to it.
func _wren_step(_delta: float) -> void:
	if not appeared or not _alive(wren) or home:
		return
	if aboard:
		wren.ground_pos = _lantern
		return
	if swapped and not wren.inside and wren.ground_pos.distance_to(shrine) <= SHRINE_REACH:
		_relic_home()
		return
	if wren.inside or not (wren.mind == Person.Mind.DUTY or wren.mind in RESUMABLE):
		return
	var goal := _wren_goal()
	if wren.mind != Person.Mind.DUTY or wren.anchor.distance_to(goal) > 0.3:
		wren.go_duty(goal)


## Where Pip makes for (v0.11 M5): your believers' house with the relic; else where he stands (he holds where a whisper left him).
func _wren_goal() -> Vector2:
	if swapped:
		return shrine
	return wren.anchor if wren.mind == Person.Mind.DUTY else wren.ground_pos


## The relic home (v0.11 M5): the win, and the light dies.
func _relic_home() -> void:
	home = true
	rules.banner.emit("THE RELIC IS OURS")
	if wren.mind == Person.Mind.DUTY:
		wren.leave_shelter(false)
	_phase2_end()


## Everyone the run holds out of doors kept from the town's flight (v0.11 M5): Pip, the cart's people, the new hands, the wardens.
func _keep_held(evacuating: bool) -> void:
	for v: Variant in _busy():
		if _alive(v) and not (v as Person).inside:
			_keep_from_flight(v as Person, evacuating)


## The wardens at their work (v0.11 M5): at his place -- his post, or by the cart while it halts at his checkpoint -- kept on duty; away,
## sent back RETURN_AFTER after he left (a relief walks on at once); fallen, replaced RELIEF_AFTER later (RELIEFS at most).
func _wardens_step(delta: float, looking: bool) -> void:
	for w: Warden in wardens:
		var at := _count_spot(w) if halt == w.checkpoint else w.post
		if not _alive(w.man):
			w.fallen += delta
			if looking and w.fallen >= RELIEF_AFTER and reliefs < RELIEFS:
				_relieve(w, at)
			continue
		w.fallen = 0.0
		var p := w.man as Person
		if p.inside:
			continue
		if not p.mind in BLIND and p.ground_pos.distance_to(at) <= POST_REACH:
			w.away = 0.0
			w.relief = false
			if looking and p.mind != Person.Mind.DUTY:
				_recall_to(p, at)
		else:
			w.away += delta
			if looking and (w.relief or w.away >= RETURN_AFTER):
				_recall_to(p, at)


## A relief for fallen warden `w` (v0.11 M5): the nearest lay citizen with a way to his post (M4's _lay_reaching()), made one of the
## watch, walking on duty to `at`.
func _relieve(w: Warden, at: Vector2) -> void:
	var p := _lay_reaching(w.post, _busy())
	if p == null:
		return
	_make_watch(p)
	w.man = p
	w.fallen = 0.0
	w.away = 0.0
	w.relief = true
	reliefs += 1
	p.go_duty(at)
	rules.banner.emit("A NEW WARDEN TAKES THE WATCH-HOUSE")


## A death (v0.11 M5): The Vigil Flame's (the Gaze's note, the reports' relay, the light's noise), and its fall kept to be judged.
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	_falls.append(e.ground_pos)


## The deaths judged (v0.11 M5, plan decision 195): at each fall a Faithful not held within Crowd.DOOM_WITNESS runs to the Temple.
func _judge_falls() -> void:
	for at in _falls:
		var seer := faithful_seeing(at, Crowd.DOOM_WITNESS)
		if seer != null:
			_report(seer, temple_door)
	_falls.clear()


## A report (v0.11 M5, plan decision 190): MissionDirector's, its relay passing over the fleeing and the reserved (TempleReport.skip).
func _report(seer: Person, at: Vector2) -> void:
	var before := reports.size()
	super(seer, at)
	for i in range(before, reports.size()):
		reports[i].skip = _passed_over


## A relay never picks `p` (v0.11 M5): one fleeing the town or reserved.
func _passed_over(p: Person) -> bool:
	return p.mind == Person.Mind.FLEE or reserved.has(p)


## Seconds until the cart halts at the next checkpoint, about (v0.11 M5, plan decision 198, for the scripted player): the route still to
## walk at its carter's duty pace, and before the set-out its time too; 0 while it halts; INF with none to come or no cart walking.
func halt_in() -> float:
	if halt >= 0:
		return 0.0
	var k := next_halt()
	if k < 0:
		return INF
	var to := int(HALT_LEGS[k])
	var speed := Person.PANIC_SPEED * CART_PACE
	if not set_out:
		var d := _lantern.distance_to(route[0])
		for i in to:
			d += route[i].distance_to(route[i + 1])
		return maxf(SET_OUT_AT - _clock, 0.0) + d / speed
	if vigil == null or not vigil.active:
		return INF
	var at := _leg_base + vigil.leg
	if at > to:
		return INF
	var left := _lantern.distance_to(route[at])
	for i in range(at, to):
		left += route[i].distance_to(route[i + 1])
	return left / maxf(vigil.bearer.walk_speed if _alive(vigil.bearer) else speed, 0.05)


## The HUD's line (v0.11 M5, Task 1's hook): where the relic is.
func hud_line() -> String:
	if home:
		return "The relic: ours"
	if swapped:
		return "The relic to your believers: %d" % roundi(wren.ground_pos.distance_to(shrine)) if _alive(wren) else "The relic: lost"
	if swapping and swap_spent > 0.0:
		return "Swapping %d / %d s" % [floori(swap_spent), roundi(SWAP)]
	if aboard:
		return "The relic: Pip at the lock" if lock_left > 0.0 else "The relic: Pip aboard"
	return "The relic: in its cart"


## The cart's tag's words (v0.11 M5): Pip at the lock or aboard; halted, its window's seconds; else its name.
func _cart_label() -> String:
	if aboard:
		return "RELIC CART - PIP AT THE LOCK" if lock_left > 0.0 else "RELIC CART - PIP ABOARD"
	if halt >= 0:
		return "RELIC CART - HALTED %d" % ceili(maxf(HALT_MAX - halt_time, 0.0))
	return "RELIC CART"


## The map tags, most important first (v0.11 M5, mission spec §4): the cart (until the swap) and Pip, pointed at; the next checkpoint;
## your believers' house; the Citadel from the second halt on; each report's runner and the Temple; ESCORT and WARDEN; a red diamond on
## any other Faithful watching the cart.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if not swapped and not kept and _lantern != Vector2.INF:
		out.append(MapTag.person(_lantern, MARK_CART, _cart_label(), true))
	if appeared and _alive(wren) and not wren.inside and not home:
		var waiting := halt >= 0 and wren.ground_pos.distance_to(_lantern) <= CART_REACH and watched()
		var label := "PIP - THE RELIC" if swapped else ("PIP - WAITING" if waiting else "PIP - DO NOT KILL")
		out.append(MapTag.person(wren.ground_pos, MARK_PIP, label, true))
	if not swapped and next_halt() >= 0:
		out.append(MapTag.place(checkpoints[next_halt()], MARK_PLACE, "CHECKPOINT", 0.0, true))
	if not home:
		out.append(MapTag.place(shrine, MARK_PLACE, "BELIEVERS' HOUSE", 0.0, true))
	var last := HALT_LEGS.size() - 1
	if not swapped and (halt == last or halts_done[last]):
		out.append(MapTag.place(route[route.size() - 1], MARK_WATCHED, "CITADEL", 0.0, true))
	var running := false
	for r in reports:
		if r.is_open() and _alive(r.carrier):
			out.append(MapTag.person(r.carrier.ground_pos, MARK_WATCHED, "TO THE TEMPLE", true))
			running = true
	if running:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE"))
	var named: Array = []
	for v: Variant in escorts:
		if _alive(v) and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "ESCORT"))
			named.append(v)
	for w: Warden in wardens:
		if _alive(w.man) and not (w.man as Person).inside:
			out.append(MapTag.person((w.man as Person).ground_pos, MARK_WATCHED, "WARDEN"))
			named.append(w.man)
	if not swapped:
		for f in watchers_now():
			if not named.has(f):
				out.append(MapTag.person(f.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M5): "bell" while the bell is called or climbing (plan decision 197); "carry" once swapped; halted, "watched"
## while watched, else "aboard" with Pip aboard, else ""; rolling, "aboard" with Pip aboard, "citadel" once the first halt is passed,
## "moving" once set out; "" before.
func hint_phase() -> String:
	if crowd.bell != null and crowd.bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING]:
		return "bell"
	if swapped:
		return "carry"
	if halt >= 0:
		if watched():
			return "watched"
		return "aboard" if aboard else ""
	if aboard:
		return "aboard"
	if halts_done[0]:
		return "citadel"
	return "moving" if set_out else ""


## The tour (v0.11 M5, mission spec §4): the cart at the Temple, Pip, your believers' house.
func tour() -> Array:
	var out := [[temple_door, "The relic cart at the Temple. It halts at two checkpoints, where its reliquary opens."]]
	if _alive(wren):
		out.append([wren.ground_pos, "Pip. Bring him to the first halt: he slips aboard there and swaps the relic at the second."])
	out.append([shrine, "Your believers' house. Pip must bring the relic here."])
	return out


## What the results show (v0.11 M5): the swap, the halts passed, the Searchlight's touches, the reports, the relic home.
func report() -> Dictionary:
	var halts := 0
	for done in halts_done:
		halts += 1 if done else 0
	return {"swapped": swapped, "halts": halts, "touches": touches, "reports": reports_started, "home": home}
```

- [ ] **Step 4: The mission.**
  - In `src/game/mission/mission_book.gd`, `tier_missions()`'s list gains `relic_run()` after `sermon()`, and after `sermon()` add:

```gdscript
## The Relic Run (v0.11 M5, Tier 4, mission spec §4 and §8 row 20): Pip slips aboard the relic cart at one checkpoint's halt, picks the
## reliquary's lock on the way and swaps the relic at the next, then carries it to your believers' house under the Searchlight
## (RelicRunDirector, The Vigil Flame's Steal).
static func relic_run() -> MissionDef:
	var m := _tier4(RELIC_RUN, "The Relic Run", PackedStringArray(["The Temple's relic rides to the Citadel.", "Swap it while the cart halts."]))
	m.goal = "Have Pip slip aboard the relic cart at one halt and swap the relic at the next, then bring it to your believers' house"
	m.goal_label = "The relic is ours"
	m.lose = "The relic reaches the Citadel, Pip dies, the Lantern looks, or dawn comes"
	m.camera_at = RelicRunDirector.CART_CAMERA
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "discord", "doom", "wisp"])
	m.director = RelicRunDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [GazeObjective.new(), FlameObjective.new("The relic", "relic", "relic_kept", "pip"),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

  - In `mission_hints.gd` `LINES`, after the `sermon` entries, add (and the same seven rows, under `# The Relic Run (v0.11 M5).`, in
    `tests/test_mission_hints.gd` `SPEC`):

```gdscript
	"relic_run": "Bring Pip (blue) to the cart's first halt. He slips aboard there, and swaps the relic at the next.",
	"relic_run.moving": "The cart (gold) moves. Its reliquary opens only at a checkpoint. Clear the next one's wardens (red) shortly before.",
	"relic_run.watched": "The cart halts, watched (red). Hold or remove the watch: Pip only works unseen.",
	"relic_run.aboard": "Pip is aboard and picks the lock. At the next halt, clear the watch so he can swap the relic.",
	"relic_run.carry": "Pip has the relic. Keep him out of the light on his way to your believers' house (orange).",
	"relic_run.citadel": "The cart makes for the Citadel (red). This is the last halt.",
	"relic_run.bell": "Four seen deaths in a district ring the bell, and the bell fills the Gaze. Stop the bellkeeper, unseen.",
```

  - In `results_screen.gd` `ACT_TITLES`, add `"relic": "THE RELIC IS OURS", "relic_kept": "THE RELIC REACHES THE CITADEL", "pip": "THE BOY IS DEAD"`.

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 40;
  `test_vigil_flame`, `test_searchlight` unchanged.

- [ ] **Step 6: The behaviour scenario.** In `tools/dev/behaviour_check.gd`:
  - In the header's usage, after the `sermon` entry, add:

```gdscript
##   relic  (v0.11 M5) The Relic Run, --case=none (nothing cast) or play, as a player plays it (_relic_act(): before the first halt,
##          Mind Whisper brings Pip up to ten units at a time to its checkpoint; the next halt within 25 s, Silent Doom on each of its
##          wardens standing alone; halted with Pip by the cart or aboard and watched, Discord on the escorts' midpoint, else Silent
##          Doom on a warden alone, else Mind Whisper sends one watcher eight units off; halted, unwatched, Pip neither by it nor
##          aboard, Mind Whisper sends him to the cart; with the relic, The Vigil Flame's carry (_flame_carry()); the result line gives
##          the longest idle stretch). --seed=, --board as ringers.
```

  - After `SERMON_AWAY` add:

```gdscript
## The Relic Run's policy (v0.11 M5): how near its time the next halt's wardens are cleared; how near the first checkpoint Pip is brought;
## how near the escorts' midpoint both must stand for one Discord; how far a watcher is whispered off.
const RELIC_AHEAD := 25.0
const RELIC_NEAR := 1.5
const RELIC_PAIR := 1.2
const RELIC_AWAY := 8.0
```

  - In `_run()`, after the `sermon` branch add:

```gdscript
	elif scenario == "relic":
		powers = PackedStringArray(["whisper", "discord", "doom", "wisp"])
		mission.mission_id = MissionBook.RELIC_RUN
```

  - In `_run()`'s `match scenario:`, before `"warning":`, add:

```gdscript
		"relic":
			await _relic(Battlefield.arg_value(args, "--case"))
```

  - After `_sermon_act()` add:

```gdscript
## The Relic Run (v0.11 M5), with mission spec §4's policy (_relic_act()), through _scripted().
func _relic(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as RelicRunDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("relic", which, func() -> String: return _relic_act(rules, slots, d, crowd),
		func() -> String: return "halt=%d halts=%s aboard=%s lock=%.0f swapped=%s stalled=%s touches=%d gaze=%d phase=%s" % [d.halt,
			d.halts_done, d.aboard, d.lock_left, d.swapped, d.stalled, d.touches, roundi(d.gaze.value), d.hint_phase()])


## One look of The Relic Run's policy (v0.11 M5): what was cast, or "". The first that applies: before the first halt, Pip more than
## RELIC_NEAR from its checkpoint, whisper him toward it (up to Mind Whisper's reach); the next halt within RELIC_AHEAD, Silent Doom on a
## warden of it standing alone; halted with Pip by the cart or aboard and watched, Discord at the escorts' midpoint (both within
## RELIC_PAIR of it, neither held), else Silent Doom on a warden alone, else Mind Whisper sends one watcher RELIC_AWAY off; halted,
## unwatched, Pip neither by the cart nor aboard, whisper him to it; with the relic, The Vigil Flame's carry.
func _relic_act(rules: Rules, slots: Dictionary, d: RelicRunDirector, crowd: Crowd) -> String:
	var v: Variant = d.wren
	if not WarningDirector._alive(v) or d.home:
		return ""
	var pip := v as Person
	if d.swapped:
		return _relic_carry(rules, slots, d)
	var cart := d.cart_at()
	var whisper := _slot_ready(rules, slots, "whisper")
	if d.halt < 0 and not d.halts_done[0] and not d.aboard and not pip.inside and pip.ground_pos.distance_to(d.checkpoints[0]) > RELIC_NEAR \
			and whisper and pip.mind != Person.Mind.WHISPERED and not pip.shaken():
		rules.cast(slots.whisper, pip.ground_pos, {"target": pip, "to": MindWhisperFx.clamp_to(crowd._grid, pip.ground_pos, d.checkpoints[0])})
		return "whisper Pip toward the first halt"
	if d.halt < 0 and d.halt_in() <= RELIC_AHEAD and _slot_ready(rules, slots, "doom"):
		for p in d.wardens_at(d.next_halt()):
			if _none_within(crowd, p, SilentDoom.RADIUS):
				rules.cast(slots.doom, p.ground_pos)
				return "doom a warden ahead"
	if d.halt < 0:
		return ""
	var by := d.aboard or (not pip.inside and pip.ground_pos.distance_to(cart) <= RelicRunDirector.CART_REACH + 0.5)
	if by and d.watched():
		var pair: Array[Person] = []
		for v: Variant in d.escorts:
			if WarningDirector._alive(v) and not (v as Person).inside and not (v as Person).mind in MissionDirector.BLIND:
				pair.append(v as Person)
		if pair.size() == 2 and _slot_ready(rules, slots, "discord"):
			var mid := (pair[0].ground_pos + pair[1].ground_pos) * 0.5
			if pair[0].ground_pos.distance_to(mid) <= RELIC_PAIR and pair[1].ground_pos.distance_to(mid) <= RELIC_PAIR:
				rules.cast(slots.discord, mid)
				return "discord the escorts"
		if _slot_ready(rules, slots, "doom"):
			for p in d.wardens_at(d.halt):
				if _none_within(crowd, p, SilentDoom.RADIUS):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a warden at the cart"
		if whisper:
			for p in d.watchers_now():
				if p.shaken():
					continue
				var off := p.ground_pos - cart
				var away := p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * RELIC_AWAY
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, away)})
				return "whisper a watcher off the cart"
		return ""
	if not d.watched() and not by and whisper and not pip.inside and pip.mind != Person.Mind.WHISPERED and not pip.shaken():
		rules.cast(slots.whisper, pip.ground_pos, {"target": pip, "to": MindWhisperFx.clamp_to(crowd._grid, pip.ground_pos, cart)})
		return "whisper Pip to the cart"
	return ""


## The Vigil Flame's carry for Pip and the relic (v0.11 M5, plan decision 199): _flame_carry(), and what it cast, if anything.
func _relic_carry(rules: Rules, slots: Dictionary, d: RelicRunDirector) -> String:
	var before := rules._casts.size()
	_flame_carry(rules, d, slots)
	return "carry the relic" if rules._casts.size() > before else ""
```

- [ ] **Step 7: The gate.** Run the Scenario loop for `relic`.
  - Expected for `none`: `won=false reason=relic_kept` in each, some 170 s in (the cart at the Citadel's gate).
  - For `play`: the gate. The spec expects about 3:10 (its sum: 50 + 15 + 10 + 44 + 10 + 60 ≈ 190 s). Write the measured clear and its
    sum (the first halt, aboard, the leg, the swap, the carry) in the commit body; name any loss to the Gaze, the bell or the light.
  - If it misses: first read the play log against the policy (is Pip at the first halt when it comes, are the second halt's wardens
    cleared on the leg, does it idle with a slot ready while the cart is watched); then tune in this order: the drop-off's point
    (`DROP_SPOT`, 25-35 units from the second halt), `CART_PACE` (0.35-0.5), `COUNT` (15-25), `SET_OUT_AT` (25-45). `HALT_MAX` stays
    under 60. If the gate or the log shows the policy waiting out the first halt for the one-halt way, report it (the controller's
    ruling keeps Decision 153's fallback ready).
  - Then the Scenario loop for `bishop`, `armoury` and `sermon` (Tasks 2-4), M3's eighteen and M4's eighteen. These six `relic` lines
    are references from here on.

- [ ] **Step 8: The Reference check.** Expected: every value unchanged (The Vigil Flame's line(s) among them: its base's `step()` and
  `FlameObjective` serve it as before).

- [ ] **Step 9: Spec sync.** In the mission spec's §4, bring the `Numbers` line, the timeline table, `The clear` and the hint lines (with
  the `bell` phase) to what landed, the swap's rule to plan decision 192, and §7's `_swap()` line to plan decision 191. Change nothing
  else in the spec.

- [ ] **Step 10: Commit.**

```bash
git add src/game/mission/relic_run_director.gd src/game/mission/relic_run_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd tests/test_relic_run.gd tests/test_relic_run.gd.uid tests/test_mission_hints.gd tests/run_all.gd docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md
git commit -m "feat: The Relic Run -- a cart that halts at two checkpoints, Pip aboard at one and the swap at the next (v0.11 M5)" -m "<the six relic lines and checksums, the gate's verdict, the measured clear and its sum, any tuning rounds; the earlier M5 eighteen, M3's and M4's 36 unchanged>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Two new wishes for Reckoning

**Files:**
- Modify: `src/game/descend/pressed_wish.gd` (new `temple_door()`, `_param()`; `choose()`, `_target_tags()`),
  `src/game/descend/mercy_wish.gd` (new `count()`, `_choose_family()`, `_at_exit()`; `choose()`, `people()`, `step()`, `_act()`,
  `hud_text()`, `_target_tags()`), `src/game/descend/wish_book.gd` (`pool()`)
- Create: `tests/test_tier4_wishes.gd`; Modify: `tests/run_all.gd`
- Modify (the pool's pinned contents only, no draw): `tests/test_wishes.gd` (`_draw()`), `tests/test_wish_kinds.gd` (`_pool()`),
  `tests/test_tier2_wishes.gd` (`_pool()`), `tests/test_tier3_wishes.gd` (`_pool()`)

**Interfaces:**
- Consumes: `WishDef.make()`, `min_tier`, `WishBook.pool_for()`, `Wish.lay()`, `FamilyWish._household()`, `FamilyWish.REACH`,
  `RescueWish`, `PressedWish.barracks_door()`, `MercyWish.exits()`, the kit, `Descent`.
- Produces: `PressedWish.temple_door(crowd: Crowd, town: Town) -> Vector2`; the params `"goal"`, `"son_label"`, `"guard_label"`;
  `MercyWish.count() -> int`, `family`, the param `"count"`; the pool's `heretic` and `family_out` (`min_tier` 4); Free the pressed
  man's clashes `["unaware_town", "razes_barracks"]`; the pool of sixteen.

- [ ] **Step 1: Write the failing test.** Create `tests/test_tier4_wishes.gd`:

```gdscript
extends RefCounted
## v0.11 M5 Reckoning's two wishes (mission spec §6): the pool grows to sixteen, the two new ones heard from Reckoning up (min_tier 4), so
## Tier 1-3 nights shuffle exactly what they did. Save the heretic from the pyre: Free the pressed man's march to the Temple's door (found
## by its role), its son tagged HERETIC and its men TEMPLE GUARD; it keeps off burns_temple. Lead my family out: Lead my brother out for
## three of the household, each escaping by a gate. Free the pressed man gains the clash razes_barracks; it and Lead my brother out are
## as before (review focus 1).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_draws(t)
	_heretic(t)
	_pressed_kept(t)
	_family(t)
	_family_ends(t)
	_brother_kept(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.sermon(), MissionDirector.new())


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _ids(list: Array) -> Array:
	var out := []
	for x in list:
		out.append(x.id if x is WishDef else (x as Wish).def.id)
	return out


static func _pool(t) -> void:
	var all := _ids(WishBook.pool())
	t.check(all.size() == 16 and all.slice(14) == ["heretic", "family_out"], "the pool: M4's fourteen, then Reckoning's two (%s)" % [all])
	var h := _def("heretic")
	var f := _def("family_out")
	t.check(h.text == "Save the heretic from the pyre" and h.kind == "rescue" and h.reward == 15 and h.min_tier == 4 and h.runner == PressedWish
		and Array(h.clashes) == ["burns_temple", "unaware_town"] and String(h.params.goal) == "temple" and String(h.params.son_label) == "HERETIC"
		and String(h.params.guard_label) == "TEMPLE GUARD" and f.text == "Lead my family out" and f.kind == "mercy" and f.reward == 15
		and f.min_tier == 4 and f.runner == MercyWish and int(f.params.count) == 3 and f.clashes.is_empty(),
		"their words, kinds, rewards and parameters; heard from Reckoning up; the pyre keeps off burns_temple")
	t.check(Array(_def("pressed").clashes) == ["unaware_town", "razes_barracks"], "Free the pressed man keeps off The Armoury's night")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all.slice(0, 12)
		and _ids(WishBook.pool_for(3)) == all.slice(0, 14) and _ids(WishBook.pool_for(4)) == all,
		"Tier 1 draws from M2's ten, Tier 2 from twelve, Tier 3 from fourteen, each in its order; Reckoning from all sixteen")


static func _draws(t) -> void:
	var s := Kit.world(TierBook.board("vigil_flame"), MissionDirector.new())
	var fourteen: Array[WishDef] = []
	fourteen.assign(WishBook.pool().slice(0, 14))
	var same := true
	for n in 20:
		var a := Descent.new().setup(TierBook.board("vigil_flame"), Descent.seed_for(n, "vigil_flame"))
		a.hear(s.crowd, s.town)
		var r := RandomNumberGenerator.new()
		r.seed = Descent.seed_for(n, "vigil_flame")
		var b := WishBook.draw(fourteen, TierBook.wishes(3), TierBook.board("vigil_flame").mission_tags, s.crowd, s.town, r)
		same = same and _ids(a.wishes) == _ids(b)
		for w in a.wishes:
			w.release()
		for w in b:
			w.release()
	t.check(same, "twenty Tier 3 nights hear exactly what M4's fourteen gave them")
	Kit.done(s)
	var o := Kit.world(TierBook.board("procession"), MissionDirector.new())
	var heard := {}
	for n in 60:
		var d := Descent.new().setup(TierBook.board("procession"), Descent.seed_for(n, "procession"))
		d.hear(o.crowd, o.town)
		for w in d.wishes:
			heard[w.def.id] = true
			w.release()
	t.check(heard.has("heretic") and heard.has("family_out"), "Reckoning's nights can hear both new wishes (%s)" % [heard.keys()])
	Kit.done(o)


static func _heretic(t) -> void:
	var s := _world()
	var w := _wish(s, "heretic") as PressedWish
	var door := PressedWish.temple_door(s.crowd, s.town)
	t.check(w != null and w._gate.is_equal_approx(door) and door.distance_to(Vector2(0.8, -5.0)) < 1.0
		and w.child.ground_pos.distance_to(door) >= PressedWish.MIN_FROM and w.soldier.soldier and w.mate.soldier and w.people().size() == 4,
		"the heretic: a son of the household at least MIN_FROM from the Temple's door (found by its role); two free soldiers")
	var tags := w.tags()
	t.check(tags[0].label == "HERETIC" and tags[0].edge and tags[1].label == "TEMPLE GUARD" and not tags[1].edge,
		"HERETIC pointed at from the edge; TEMPLE GUARD on each man")
	w.engage()
	t.check(w.tags()[1].edge, "engaged: the Temple's guard pointed at")
	w.release()
	Kit.done(s)


static func _pressed_kept(t) -> void:
	var s := _world()
	var w := _wish(s, "pressed") as PressedWish
	t.check(w != null and w._gate.is_equal_approx(PressedWish.barracks_door(s.crowd)) and w.tags()[0].label == "PRESSED MAN"
		and w.tags()[1].label == "PRESS-GANG", "Free the pressed man marches to the barracks' door as before, its tags as they were")
	w.release()
	Kit.done(s)


static func _family(t) -> void:
	var s := _world()
	var w := _wish(s, "family_out") as MercyWish
	var near := w != null and w.count() == 3 and w.family.size() == 3 and w.people().size() == 4 and w.target == null
	for v: Variant in w.family:
		near = near and (v as Person).profile.home.distance_to(w.wisher.profile.home) <= FamilyWish.REACH
	t.check(near, "three of the wisher's household, living near his home, set aside with him")
	var labels := []
	for m in w.tags():
		if m.label == "FAMILY" and m.edge:
			labels.append(m.label)
	t.check(labels.size() == 3, "FAMILY on each, pointed at from the edge")
	var exit: Vector2 = MercyWish.exits()[0]
	for k in 2:
		var p := w.family[k] as Person
		p.whisper(exit, MindWhisperFx.LINGER)
		Kit.arrive(p, exit)
		w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.PENDING and w.hud_text(s.rules).ends_with("2 / 3"), "two escaped: still open (%s)" % w.hud_text(s.rules))
	var last := w.family[2] as Person
	last.whisper(exit, MindWhisperFx.LINGER)
	Kit.arrive(last, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "the third escapes: granted")
	Kit.done(s)


static func _family_ends(t) -> void:
	var s := _world()
	var w := _wish(s, "family_out", 5) as MercyWish
	Kit.free_body(s, w.family[1])
	t.check(w.check(s.rules) == Objective.Status.FAILED, "one dies before escaping: failed")
	var v := _wish(s, "family_out", 7) as MercyWish
	Kit.free_body(s, v.wisher)
	t.check(v.check(s.rules) == Objective.Status.FAILED, "the wisher dies first: failed")
	Kit.done(s)


static func _brother_kept(t) -> void:
	var s := _world()
	var w := _wish(s, "brother") as MercyWish
	t.check(w != null and w.count() == 1 and w.family.is_empty() and w.target != null and w.tags()[0].label == "BROTHER"
		and not w.tags()[0].edge and w.people().size() == 2, "Lead my brother out: one brother, his tag as it was")
	var exit: Vector2 = MercyWish.exits()[1]
	w.target.whisper(exit, MindWhisperFx.LINGER)
	Kit.arrive(w.target, exit)
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "whispered to a gate he escapes: granted, as before")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_tier4_wishes.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then Tests. Expected: FAILs in `test_tier4_wishes` (no `heretic`, no
  `family_out`, no `count()`), and a parse error for `temple_door`.

- [ ] **Step 3: The pyre** (plan decision 200). In `src/game/descend/pressed_wish.gd`:
  - The class doc gains: `## v0.11 M5 (mission spec §6): params "goal" -- "barracks" (the default, the barracks' door: Free the pressed man) or "temple" (the Temple's door, found by its role: Save the heretic from the pyre) -- and "son_label" / "guard_label", the son's and each man's tag words (PRESSED MAN and PRESS-GANG by default).`
  - After `barracks_door()` add:

```gdscript
## The Temple's door (v0.11 M5): the middle of the front of the town's structure of role temple, on walkable ground; Vector2.INF for none.
## Found by its role, not TownLayout (M3's controller ruling on shared code).
static func temple_door(crowd: Crowd, town: Town) -> Vector2:
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			var at := s.center() + Vector2(0.0, s.footprint.size.y * 0.5 + 0.5)
			var snap := crowd._grid.nearest_walkable(at) if crowd._grid != null else at
			return snap if snap != Vector2.INF else at
	return Vector2.INF


## This wish's parameter `key` (v0.11 M5), `fallback` with no def or no such parameter.
func _param(key: String, fallback: Variant) -> Variant:
	return def.params.get(key, fallback) if def != null else fallback
```

  - In `choose()`, the parameter `_town` becomes `town`, and `var door := barracks_door(crowd)` becomes:

```gdscript
	var door := temple_door(crowd, town) if String(_param("goal", "barracks")) == "temple" else barracks_door(crowd)
	if door == Vector2.INF:
		return false
```

  - In `_target_tags()`, `"PRESSED MAN"` becomes `String(_param("son_label", "PRESSED MAN"))` and `"PRESS-GANG"` becomes
    `String(_param("guard_label", "PRESS-GANG"))`; its doc names both parameters.

- [ ] **Step 4: The family.** In `src/game/descend/mercy_wish.gd`:
  - The class doc gains: `## v0.11 M5 (mission spec §6): "count" -- how many of the wisher's household are to be led out (1, the default: Lead my brother out, as before); more (Lead my family out) are chosen as Show yourself to my family chooses (FamilyWish._household()), each tagged FAMILY and pointed at from the edge, granted when the last escapes and failed when one dies first. An escaped body is freed at once, so escapes are kept by instance id.`
  - After `var _out := false` add:

```gdscript
## The household's tag (v0.11 M5).
const FAMILY_LABEL := "FAMILY"

## With "count" above 1 (v0.11 M5): the household to be led out (untyped: one may be freed), each one's instance id, and the ids of those
## who escaped.
var family := []
var _ids: Array[int] = []
var _escaped: Array[int] = []
```

  - Replace `choose()`, `people()`, `step()` and `_act()`, and add `count()`, `_choose_family()`, `_at_exit()`, `hud_text()`; `_target_tags()`
    gains the family's branch:

```gdscript
## How many are to be led out (v0.11 M5): "count", 1 by default.
func count() -> int:
	return int(def.params.get("count", 1)) if def != null else 1


func choose(crowd: Crowd, town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	if count() > 1:
		return _choose_family(crowd, rng, taken)
	# Two people or none: checked before either is taken, so a failed choose leaves nobody in `taken`.
	if Wish.lay(crowd, taken).size() < 2 or not super(crowd, town, rng, taken):
		return false
	target = Wish.pick_lay(crowd, rng, taken)
	return target != null


## The wisher and count() of his household (v0.11 M5): as Show yourself to my family chooses, from a random start; false when no household
## is big enough.
func _choose_family(crowd: Crowd, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		var near := FamilyWish._household(w, pool)
		if near.size() >= count():
			wisher = w
			for p in near.slice(0, count()):
				family.append(p)
				_ids.append(p.get_instance_id())
			taken.append(wisher)
			taken.append_array(family)
			return true
	return false


func people() -> Array[Person]:
	var out := super()
	if target != null:
		out.append(target)
	for v: Variant in family:
		if is_instance_valid(v):
			out.append(v as Person)
	return out


## `p` stands within EXIT_REACH of a way out (v0.11 M5, the old step's test).
static func _at_exit(p: Person) -> bool:
	for e in exits():
		if p.ground_pos.distance_to(e) <= EXIT_REACH:
			return true
	return false


## Whispered and at a gate: he escapes (Crowd.escape(), as a boat's passenger does; it counts as an escape). v0.11 M5: each of the family
## the same way.
func step(_rules: Rules, _delta: float) -> void:
	if count() > 1:
		for k in family.size():
			var v: Variant = family[k]
			if _escaped.has(_ids[k]) or not MissionDirector._alive(v) or (v as Person).mind != Person.Mind.WHISPERED:
				continue
			if _at_exit(v as Person):
				_escaped.append(_ids[k])
				_crowd._field.remove(v as Person)
				_crowd.escape(v as Person)
		return
	if _out or not MissionDirector._alive(target) or target.mind != Person.Mind.WHISPERED:
		return
	if _at_exit(target):
		_out = true
		_crowd._field.remove(target)
		_crowd.escape(target)


func _act(_rules: Rules) -> Status:
	if count() > 1:
		if _escaped.size() >= family.size():
			return Status.DONE
		for k in family.size():
			if not _escaped.has(_ids[k]) and not MissionDirector._alive(family[k]):
				return Status.FAILED
		return Status.PENDING
	if _out:
		return Status.DONE
	return Status.PENDING if MissionDirector._alive(target) else Status.FAILED


## "Lead my family out (+15) 1 / 3" (v0.11 M5); the brother's as before.
func hud_text(rules: Rules) -> String:
	if count() > 1:
		return "%s (+%d) %d / %d" % [def.text, reward, _escaped.size(), family.size()]
	return super(rules)
```

    and `_target_tags()` becomes:

```gdscript
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if count() > 1:
		for k in family.size():
			var v: Variant = family[k]
			if not _escaped.has(_ids[k]) and MissionDirector._alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, COLOR, FAMILY_LABEL, true))
		return out
	if not _out and MissionDirector._alive(target) and not target.inside:
		out.append(MapTag.person(target.ground_pos, COLOR, "BROTHER"))
	return out
```

- [ ] **Step 5: The pool.** In `src/game/descend/wish_book.gd`, `pool()`'s doc becomes `## The pool (spec §5.3): M1's eight in the spec's order, then v0.11 M2's two for Tier 1, v0.11 M3's two for Omen, v0.11 M4's two for Wrath and v0.11 M5's two for Reckoning (mission spec §6).`;
  the `pressed` row's clashes become `PackedStringArray(["unaware_town", "razes_barracks"])`; and after M4's `sergeant` row add:

```gdscript
		WishDef.make("heretic", "Save the heretic from the pyre", "rescue", 15, PressedWish,
			{"goal": "temple", "son_label": "HERETIC", "guard_label": "TEMPLE GUARD"}, PackedStringArray(["burns_temple", "unaware_town"]), 4),
		WishDef.make("family_out", "Lead my family out", "mercy", 15, MercyWish, {"count": 3}, PackedStringArray(), 4),
```

- [ ] **Step 6: The tests that pin the pool's contents** (no test pinning a Tier 1-3 draw changes):
  - `tests/test_wishes.gd` `_draw()`: `WishBook.pool().size() == 14` becomes `== 16`, its message's `v0.11 M4: fourteen in the pool`
    becomes `v0.11 M5: sixteen in the pool`.
  - `tests/test_wish_kinds.gd` `_pool()`: the ids list gains `"heretic", "family_out"` after `"sergeant"`, and its message ends
    `then M4's two, then M5's two (%s)`.
  - `tests/test_tier2_wishes.gd` `_pool()`: `all.size() == 14` becomes `all.size() == 16`; `Array(pressed.clashes) == ["unaware_town"]`
    becomes `Array(pressed.clashes) == ["unaware_town", "razes_barracks"]`.
  - `tests/test_tier3_wishes.gd` `_pool()`: `all.size() == 14 and all.slice(12) == ["barn", "sergeant"]` becomes
    `all.size() == 16 and all.slice(12, 14) == ["barn", "sergeant"]`, and `_ids(WishBook.pool_for(3)) == all` becomes
    `_ids(WishBook.pool_for(3)) == all.slice(0, 14)` (message: `"Tier 1 draws from M2's ten, Tier 2 from M3's twelve; Wrath from fourteen"`).
  - Grep `tests/` for a test that pins the exact wishes a Tier 4 or Tier 5 night hears (Decision 160). Any you find, re-pin to what
    the sixteen give and name each in the report; if none, say so.

- [ ] **Step 7: Run the tests to verify they pass.** Run Import, then Tests. Expected: `failures=0`, the count up by about 14.

- [ ] **Step 8: The Reference check, and FLOW.** Expected: every value unchanged (the scenarios hear no wishes; the board's draws below
  Tier 4 are pinned by Step 1 `_draws` and M3-M4's tests); `FLOW result checks=112 failures=0`, run alone.

- [ ] **Step 9: Commit.**

```bash
git add src/game/descend/pressed_wish.gd src/game/descend/mercy_wish.gd src/game/descend/wish_book.gd tests/test_tier4_wishes.gd tests/test_tier4_wishes.gd.uid tests/test_wishes.gd tests/test_wish_kinds.gd tests/test_tier2_wishes.gd tests/test_tier3_wishes.gd tests/run_all.gd
git commit -m "feat: two wishes for Reckoning -- Save the heretic from the pyre, Lead my family out; Tier 1-3 draws unchanged (v0.11 M5)" -m "<counts; any Tier 4-5 draw re-pinned, named; the Reference check; FLOW 112/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Tier 4 complete on the board

**Files:**
- Modify: `src/game/descend/tier_book.gd` (`MISSIONS`, `TYPES`, `MISSION_TAGS`, `NEED`'s doc)
- Modify: `src/game/game.gd` (`_flow_board()`, new `_flow_tier4()` and its call in `_flow_test()`, the `tiers` photo's save)
- Create: `tests/test_tier4_board.gd`
- Modify: `tests/test_tiers.gd` (`_table()`, `_unlock()`), `tests/run_all.gd`

**Interfaces:**
- Consumes: Tasks 1-6: `BishopDirector.quarries` / `refuges` / `ARRIVE_AT` / `CHAIN` / `RELIEF_AFTER`; `ArmouryDirector.armed` / `reserve` /
  `targets` / `STAGE_AT` / `CHAIN` / `RETURN_AFTER` / `RELIEF_AFTER` / `REINFORCE` / `_raze()`; `SermonDirector.listeners` / `preacher` /
  `acolytes` / `sentries` / `house` / `CHAIN` / `READ` / `RETURN_AFTER` / `RELIEF_AFTER`; `RelicRunDirector.wren` / `carter` / `escorts`
  / `wardens` / `drop_house` / `SET_OUT_AT` / `HALT_MAX` / `COUNT` / `RETURN_AFTER` / `RELIEF_AFTER`; `MissionBook.ARMOURY`, `armoury()`;
  the kit; `Descent.reserve()`; M4's `_flow_board()` and `_flow_tier3()`.
- Produces: `TierBook.missions(4) == ["procession", "bishop", "armoury", "sermon", "relic_run"]`, `TierBook.need(4) == 3`; the four types;
  `TierBook.mission_tags("bishop") == ["burns_temple"]`, `("armoury") == ["razes_barracks"]`; FLOW 113.

- [ ] **Step 1: Write the failing tests.**
  - Create `tests/test_tier4_board.gd`:

```gdscript
extends RefCounted
## v0.11 M5 Tier 4 complete on the board: The Procession and the four new missions, each new one at Tier 4's numbers (6:30, 5 / 13,
## God-Resistant, no unaware_town, no bonuses, no stretch); three of Reckoning's five open Ascendance, and a save that opened it on The
## Procession alone keeps it (Decision 122); no timed wait over 60 s, no chain over 45 s, the first waits pinned; a board night's wishes
## reserved before each director gathers its people (review focus 5); The Bishop never hears the pyre, The Armoury never the pressed
## man (Decision 161); five cards on Reckoning's tab.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The four new Tier 4 missions.
const NEW := ["bishop", "armoury", "sermon", "relic_run"]


static func run(t) -> void:
	_board(t)
	_open(t)
	_waits(t)
	_reserved(t)
	_wishes(t)
	_cards(t)


static func _board(t) -> void:
	for id: String in NEW:
		var m := TierBook.board(id)
		t.check(m != null and m.id == id and m.tier == 4 and is_equal_approx(m.clock, 390.0) and m.slots == 5 and m.dp_capacity == 13
			and m.tier_floor == 4 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "God-Resistant" and is_equal_approx(m.stretch, 1.0),
			"%s on the board: Tier 4, 6:30, 5 / 13, God-Resistant, no unaware_town, no bonuses, no stretch" % id)
	t.check(Array(TierBook.missions(4)) == ["procession"] + NEW and TierBook.need(4) == 3
		and DescendState.lock_text(5) == "Clear 3 Reckoning missions", "Reckoning: the ★ mission first, then the four new; three open Ascendance")
	t.check(TierBook.type_of("bishop") == "Kill" and TierBook.type_of("armoury") == "Destroy" and TierBook.type_of("sermon") == "Cult"
		and TierBook.type_of("relic_run") == "Cult" and Array(TierBook.board("bishop").mission_tags) == ["burns_temple"]
		and Array(TierBook.board("armoury").mission_tags) == ["razes_barracks"] and TierBook.board("sermon").mission_tags.is_empty()
		and TierBook.board("relic_run").mission_tags.is_empty(), "each card's type; The Bishop and The Armoury keep their clashing wishes away")


## Three cleared of each tier below Reckoning (v0.11 M5 tests).
const BELOW := ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers", "vigil_flame", "festival",
	"crowns_bread"]


static func _open(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(BELOW + ["procession", "bishop"])
	s.refresh_open()
	t.check(s.open_tier == 4 and s.progress_line(4) == "Reckoning 2 / 3 cleared: one more opens Ascendance",
		"two of Reckoning's five leave Ascendance shut (%s)" % s.progress_line(4))
	s.cleared.append("armoury")
	t.check(s.refresh_open() == 5 and s.open_tier == 5, "three of them open Ascendance")
	var path := "user://test_tier4_board.cfg"
	var old := ConfigFile.new()
	old.set_value("descend", "open_tier", 5)
	old.set_value("descend", "cleared", BELOW + ["procession"])
	old.save(path)
	var kept := SaveFile.new().load_from(path).descend
	kept.refresh_open()
	t.check(kept.open_tier == 5 and kept.is_open(5) and kept.progress_line(4) == "Reckoning 1 / 3 cleared: Ascendance is open",
		"a save that opened Ascendance on The Procession alone keeps it open: a tier never closes (Decision 122)")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _waits(t) -> void:
	var waits := {
		"the bishop goes to ground": BishopDirector.ARRIVE_AT,
		"a Knight's relief": BishopDirector.RELIEF_AFTER,
		"the first horn": ArmouryDirector.STAGE_AT[0],
		"an armed man's return": ArmouryDirector.RETURN_AFTER,
		"an armed man's relief": ArmouryDirector.RELIEF_AFTER,
		"the slowest reinforcement": (ArmouryDirector.REINFORCE as Array).max(),
		"a reading": SermonDirector.READ,
		"a sentry's return": SermonDirector.RETURN_AFTER,
		"a sentry's relief": SermonDirector.RELIEF_AFTER,
		"the relic sets out": RelicRunDirector.SET_OUT_AT,
		"the longest halt": RelicRunDirector.HALT_MAX,
		"the count": RelicRunDirector.COUNT,
		"a warden's return": RelicRunDirector.RETURN_AFTER,
		"a warden's relief": RelicRunDirector.RELIEF_AFTER,
	}
	var chains := {"his flight": BishopDirector.CHAIN, "the next horn": ArmouryDirector.CHAIN, "the next wave": SermonDirector.CHAIN}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Reckoning's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	# The first waits pinned exactly at their tuned values. Set each to the value Tasks 2, 3 and 5 landed if their gates tuned it.
	t.check(is_equal_approx(BishopDirector.ARRIVE_AT, 45.0) and is_equal_approx(float(ArmouryDirector.STAGE_AT[0]), 40.0)
		and is_equal_approx(RelicRunDirector.SET_OUT_AT, 35.0), "the first waits as tuned: the bishop 0:45, the first horn 0:40, the cart 0:35")


## The people and the buildings `d` has claimed (v0.11 M5).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is BishopDirector:
		var b := d as BishopDirector
		people.append(b.quarries[0].target)
		places.append_array(b.refuges.slice(0, 2))
	elif d is ArmouryDirector:
		var a := d as ArmouryDirector
		for list: Array in a.armed:
			for x: ArmouryDirector.Armed in list:
				people.append(x.man)
		people.append_array(a.reserve)
		places.append_array(a.targets.slice(0, 2))
	elif d is SermonDirector:
		var se := d as SermonDirector
		for l: SermonDirector.Listener in se.listeners:
			people.append(l.man)
		people.append(se.preacher)
		people.append_array(se.acolytes)
		for st: SermonDirector.Sentry in se.sentries:
			people.append(st.man)
		places.append(se.house)
	elif d is RelicRunDirector:
		var r := d as RelicRunDirector
		people.append_array([r.wren, r.carter])
		people.append_array(r.escorts)
		for w: RelicRunDirector.Warden in r.wardens:
			people.append(w.man)
		places.append(r.drop_house)
	return {"people": people, "places": places}


static func _reserved(t) -> void:
	for id: String in NEW:
		var a := Kit.world(TierBook.board(id))
		var first := _actors(a.d)
		var people_ix := []
		for p: Variant in first.people:
			people_ix.append((a.crowd as Crowd).citizens.find(p))
		var place_ix := []
		for s: Variant in first.places:
			place_ix.append((a.town as Town)._built.find(s))
		Kit.done(a)
		var hold := func(d: MissionDirector, rules: Rules) -> void:
			for i: int in people_ix:
				if i >= 0:
					d.reserved.append(rules.crowd().citizens[i])
			for i: int in place_ix:
				if i >= 0:
					d.reserved_places.append(rules.town()._built[i])
		var b := Kit.world(TierBook.board(id), null, hold)
		var second := _actors(b.d)
		var clash := []
		for p: Variant in second.people:
			if people_ix.has((b.crowd as Crowd).citizens.find(p)):
				clash.append(p)
		for s: Variant in second.places:
			if s != null and place_ix.has((b.town as Town)._built.find(s)):
				clash.append(s)
		t.check(clash.is_empty() and not second.people.is_empty(),
			"%s: the people and buildings a first night claimed, reserved, are never claimed again (%d clashes)" % [id, clash.size()])
		Kit.done(b)
		var heard := 0
		var hit := 0
		for night in 4:
			var descent := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			var n := Kit.world(TierBook.board(id), null, func(d: MissionDirector, rules: Rules) -> void: descent.reserve(rules, d))
			var mine := _actors(n.d)
			for w in descent.wishes:
				heard += 1
				for p in w.people():
					hit += 1 if (mine.people as Array).has(p) else 0
				for st in w.places():
					hit += 1 if (mine.places as Array).has(st) else 0
			descent.release()
			Kit.done(n)
		t.check(heard > 0 and hit == 0, "%s: four seeded board nights' wishes, reserved first, never become its people or buildings" % id)


static func _wishes(t) -> void:
	var worlds := {}
	for id: String in ["bishop", "armoury", "sermon"]:
		worlds[id] = Kit.world(TierBook.board(id))
	var heard := {"bishop": {}, "armoury": {}, "sermon": {}}
	for night in 60:
		for id: String in worlds:
			var d := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			d.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in d.wishes:
				(heard[id] as Dictionary)[w.def.id] = true
			d.release()
	t.check(not (heard.bishop as Dictionary).has("heretic") and not (heard.armoury as Dictionary).has("pressed")
		and (heard.sermon as Dictionary).has("heretic") and (heard.sermon as Dictionary).has("pressed") and (heard.sermon as Dictionary).has("family_out"),
		"sixty draws: The Bishop never hears the pyre, The Armoury never the pressed man; The Sermon hears all three (%s / %s / %s)" % [
		(heard.bishop as Dictionary).keys(), (heard.armoury as Dictionary).keys(), (heard.sermon as Dictionary).keys()])
	for id: String in worlds:
		Kit.done(worlds[id])


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 4
	var board := MissionBoard.new().setup(save, "bishop")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 4 and board.missions().size() == 5 and long.is_empty(),
		"Reckoning's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
```

  - `tests/test_tiers.gd` `_table()`: `Array(TierBook.missions(4)) == ["procession"]` becomes
    `Array(TierBook.missions(4)) == ["procession", "bishop", "armoury", "sermon", "relic_run"]` (message:
    `"Whisper, Omen, Wrath and Reckoning complete (v0.11 M2-M5); the ★ missions on theirs (spec §8)"`); `TierBook.all().size() == 18`
    becomes `== 22`; the needs become `[3, 3, 3, 3, 2]` (message `"Whisper, Omen, Wrath and Reckoning need three of their five (v0.11 M2-M5); Ascendance still needs both (%s)"`).
  - `tests/test_tiers.gd` `_unlock()`: the `far` list gains `"bishop", "armoury"` after `"procession"` (Reckoning now needs three).
  - In `tests/run_all.gd`, append `"res://tests/test_tier4_board.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then Tests. Expected: FAILs in `test_tier4_board` (the four are not
  on the board: `TierBook.board()` returns null) and `test_tiers`.

- [ ] **Step 3: Reckoning on the board.** In `src/game/descend/tier_book.gd`:
  - `MISSIONS`' fourth entry `["procession"]` becomes `["procession", "bishop", "armoury", "sermon", "relic_run"]`.
  - `TYPES` gains `"bishop": "Kill", "armoury": "Destroy", "sermon": "Cult", "relic_run": "Cult"`.
  - `MISSION_TAGS` gains `"bishop": ["burns_temple"], "armoury": ["razes_barracks"]`.
  - `NEED`'s doc gains: `Reckoning has five from v0.11 M5, so Ascendance takes the full three too.`

- [ ] **Step 4: Run the tests to verify they pass.** Run Tests. Expected: `failures=0`, the count up by about 18.
  `test_board_missions` now covers twenty-two board missions; if one of its checks refuses a new mission (a brief over its lines, a
  default loadout over the tier's DP), fix the mission's words, not the check, and say so.

- [ ] **Step 5: FLOW** (plan decision 202). In `src/game/game.gd`:
  - `_flow_board()`: its doc gains `v0.11 M5: Reckoning's tab shows its five cards behind three of Wrath.`; in M4's Omen-locked step,
    after M4's `wrath_ok` line and before its `step.call(...)`, add:

```gdscript
	board.open_tab(4)
	var reckoning_ok := Array(board.missions()) == Array(TierBook.missions(4)) and board.missions().size() == 5 \
		and board.lock_line() == "Clear 3 Wrath missions"
```

    and that `step.call()`'s condition gains `and reckoning_ok`, its message `; Reckoning's five behind three of Wrath`.
  - After M4's `_flow_tier3()` add:

```gdscript
## v0.11 M5: a Tier 4 mission from the board -- The Armoury, Reckoning opened as a fixture (Wrath's three clears need not be played). Its
## Prepare has Tier 4's DP plus the one bought; its night is the board's version, three targets; razed by its public state (each target
## razed, ArmouryDirector._raze()), F ascends to the results: won, The Armoury cleared, Reckoning 1 / 3. Ends on the board.
func _flow_tier4(step: Callable) -> void:
	save.descend.open_tier = maxi(save.descend.open_tier, 4)
	(_screen_node as MissionBoard).choose(MissionBook.ARMOURY)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.armoury().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as ArmouryDirector
	var up := d != null and d.targets.size() == 3 and dp == TierBook.dp(4) + 1 and _mission.rules().mission.tier == 4
	if d != null:
		for s in d.targets:
			d._raze(s)
	await _until(func() -> bool: return _mission.rules().main_done, 3.0)
	await get_tree().process_frame
	var f := InputEventKey.new()
	f.physical_keycode = KEY_F
	f.pressed = true
	Input.parse_input_event(f)
	var shown := await _until(func() -> bool: return screen == Screen.RESULTS, 6.0)
	var desc: Dictionary = result.get("descend", {})
	var bank: Dictionary = desc.get("bank", {})
	step.call(up and shown and bool(result.get("won", false)) and bool(desc.get("ascended", false))
		and save.descend.cleared.has(MissionBook.ARMOURY)
		and String(bank.get("progress", "")) == "Reckoning 1 / 3 cleared: 2 more open Ascendance",
		"The Armoury from the board: Tier 4's budget, three targets; razed and ascended, the results read Reckoning 1 / 3 (%s)" % String(
		bank.get("progress", "")))
	if shown and _screen_node is ResultsScreen:
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
```

  - In `_flow_test()`, after `await _flow_tier3(step)`, add `await _flow_tier4(step)`.
  - The `tiers` photo's save (in `_ready()`'s `match show:`): M4's cleared list gains `"procession", "bishop", "armoury"` at its end,
    and its comment reads `# The tier board part-way up (v0.11 M1-M5): three of Whisper, Omen, Wrath and Reckoning cleared, Ascendance open, for the photograph (SHOW_SAVE).`
    and its second comment line `... --mission=vigil_flame opens Wrath's instead, --mission=procession Reckoning's.`

- [ ] **Step 6: Run FLOW, alone.** Check `tasklist | grep -i godot` first. Expected: `FLOW result checks=113 failures=0`. Paste any
  `FLOW FAIL` line.

- [ ] **Step 7: Run the tests.** Expected: `failures=0` (in halves if the suite would pass the 10-minute cap).

- [ ] **Step 8: The scenario gates, and the board's versions.**
  - Run the Scenario loop for `bishop`, `armoury`, `sermon` and `relic` (24 runs). Expected: every checksum and result line as recorded
    in Tasks 2-5. Write each gate's verdict in the commit body:
    - `none` loses: bishop `bishop_taken`, armoury `marches`, sermon `sermon_over`, relic `relic_kept`;
    - `play` wins at least 2 of 3, its median won time 180-240 s, its `idle` 45 s or less.
  - Run each once more with `--case=play --seed=1 --board`. Expected per run: a `BEHAVIOUR board tier=4 wishes=...` line with three
    wishes, never `heretic` for The Bishop nor `pressed` for The Armoury; a result line; no `SCRIPT ERROR`. Paste the four pairs of lines.
  - Then the Scenario loop for M3's eighteen and M4's eighteen, compared with their tables.

- [ ] **Step 9: The Reference check,** and the board Warning's `--mission=warning --board --mission-test` (as at the baseline).
  Expected: unchanged.

- [ ] **Step 10: Commit.**

```bash
git add src/game/descend/tier_book.gd src/game/game.gd tests/test_tier4_board.gd tests/test_tier4_board.gd.uid tests/test_tiers.gd tests/run_all.gd
git commit -m "feat: Tier 4 complete on the board -- five Reckoning missions, three to open Ascendance, The Armoury in FLOW (v0.11 M5)" -m "<the 24 gate lines' verdicts and the four --board runs; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: The photos and the notes

**Files:**
- Modify: `src/game/game.gd` (`TIER4_SHOWS`, `--show=bishop|armoury|sermon|relic_run`, the capture conditions)
- Modify (only if a photo shows a problem): a director's tag label or `CAMERA_AT` and its test file; `SermonDirector.tags()` and
  `tests/test_sermon.gd` (the waiting waves' diamonds, Step 3); `MissionBoard`'s card constants
- Modify: `docs/KAK_Version_0.11_Summary.md` (a new `## M5: Reckoning` section), `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: five photographs and the notes. No new behaviour.

- [ ] **Step 1: The photographs' cases.** In `src/game/game.gd`:
  - After M4's `const TIER3_SHOWS := ...` add:

```gdscript
## The new Tier 4 missions' photographs (v0.11 M5): each its board night as the tour lands, its tags and HUD in view.
const TIER4_SHOWS := ["bishop", "armoury", "sermon", "relic_run"]
```

  - In `_ready()`'s `match show:`, the arm listing the Tier 1-3 missions gains `"bishop", "armoury", "sermon", "relic_run"`, and its
    comment reads `# A new Tier 1, 2, 3 or 4 mission's board night (v0.11 M2-M5), for the photograph of its tags, its how-to-win line and its wishes.`
  - In the `if "--capture" in args:` branch, both conditions that read `or show in TIER3_SHOWS` read
    `or show in TIER3_SHOWS or show in TIER4_SHOWS` (the tour skipped; the opening banners waited out).

- [ ] **Step 2: Take the photos.** `--show=bishop`, `--show=armoury`, `--show=sermon`, `--show=relic_run`, and
  `--show=tiers --mission=procession` (Reckoning's tab). Read each `captures/screen_<name>.png`.

- [ ] **Step 3: Judge them against the mission spec.** For each photo, answer in the report; in every mission photo, also: nothing
  key under the left HUD stack (its top-left ~230 x 70 px), and an edge arrow for each off-screen target named below.
  - **bishop:** BISHOP - IN THE CITADEL has no arrow into the corner; NEXT REFUGE - HE COMES IN 0:4x on his house at the right; KNIGHT
    on its standing pair; the chapter house and the Temple's Knights; "Kill the bishop: refuges 0 / 3", "Knights come 5:00"; the strip
    "0:45 The bishop goes to ground"; the three wishes' rows.
  - **armoury:** BARRACKS - MUSTERS BY 0:40 just above the centre; the gate barracks' and ARMOURY - MUSTERS BY 3:00's arrows on the
    bottom edge; ARMED on the night watches; "Raze the garrison 0 / 3", "Garrison marches 5:00"; the strip's first horn.
  - **sermon:** GOD'S HOUSE outlined at the left below the HUD stack, DOOR - WATCHED, PREACHER, SENTRY twice, NEXT WAVE with its arrow,
    the TEMPLE tag's arrow (none while no report runs); "Turn the crowd 0 / 8", the Gaze row, "Sermon ends 5:00". **Clutter** (the
    spec's photo check): if the waiting waves' gold diamonds hide or crowd a label, remove the waiting listeners' diamonds from
    `SermonDirector.tags()` (`called[l.wave]` only) and the NEXT WAVE tag carries them; adjust `_tagged`'s expectations, and say so.
  - **relic_run:** RELIC CART above the centre, PIP - DO NOT KILL below it, CHECKPOINT at the right; BELIEVERS' HOUSE's arrow on the right
    edge; WARDEN and ESCORT; "The relic: in its cart", the Gaze row; the strip "0:35 The relic sets out".
  - **tiers (Reckoning):** five cards, each with its name, type and brief inside it; The Procession, The Bishop and The Armoury ticked;
    Ascendance open.

- [ ] **Step 4: Fix only what a photo shows.**
  - Change only what **Files** lists. A `CAMERA_AT` (The Relic Run's `CART_CAMERA`) move moves that scenario's six references (Decision 159's cost): re-run its Scenario
    loop, check the gate still holds, and record the new values and the reason in the commit body.
  - After any change, run Tests, FLOW (alone) and the photo again. Report each change with its old and new value and the photo that
    asked for it. If nothing needs changing, say so.

- [ ] **Step 5: The notes.**
  - In `docs/KAK_Version_0.11_Summary.md`:
    - The header's italic line gains: `M5 (Reckoning): Tier 4's four new missions; mission spec docs/superpowers/specs/2026-10-10-kak-v011-m5-reckoning-missions.md, plan docs/superpowers/plans/2026-10-10-kak-v011-m5-reckoning.md.`
    - Before `## M4: Wrath`, add a section `## M5: Reckoning`, in M4's voice. It says:
      - **Reckoning's five:** a table of name, card type, main objective and twist, one row each for The Procession and the four new;
        Ascendance now opens at three cleared, and a save that opened it on The Procession alone keeps it.
      - **The types, one paragraph each:** Assassinate reused (refuges driven by fire, Lantern Knights, the guard hooks); Raze reused on
        M4's stages (the controller's ruling replacing seals; armed men held on their posts; reinforcements faster each minute; the Raze
        line); Convert reused (a preacher who holds his crowd rapt, waves on the chain held deaf until called, sentries, the flock);
        Steal reused (a cart that halts on VigilRoute.busy, two steps, the swap at the second halt only).
      - **Each mission's timeline** in a line, with its longest wait.
      - **The wishes:** the two new rows; heard from Reckoning up; Tier 1-3 draws unchanged; Free the pressed man keeps off The Armoury.
      - **References:** the 24 new scenario checksums with each `play` median and `idle`, from Tasks 2-5's commit bodies (and any Task 8
        re-recording). State that every M1-M4 reference is unchanged, and whether The Vigil Flame's play line joined them (Task 1).
      - **Rulings made in M5:** the mission spec's Decisions 121-168 (137 as replaced) and this plan's 169-206, numbered on from M4's last
        in this file, one line each, with the controller's rulings where they changed a decision.
      - The last line: `Gates: filled in at landing.`
  - In `README.md`'s KAK section, after the sentence on Wrath, add: `Reckoning, the fourth tier, is complete: The Procession, The Bishop, The Armoury, The Sermon and The Relic Run.`

- [ ] **Step 6: Run Tests and FLOW.** Expected: `failures=0`, and `FLOW result checks=113 failures=0` (alone).

- [ ] **Step 7: Commit.**

```bash
git add src/game/game.gd docs/KAK_Version_0.11_Summary.md README.md
git commit -m "docs: v0.11 M5 photos and notes -- Reckoning complete (v0.11 M5)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  - If Step 4 changed a constant or a label, add its file and its test file to the `git add`.
