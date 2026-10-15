# KAK v0.11 M6: Ascendance (Tier 5 complete, v0.11's close) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tier 5 (Ascendance) gets its three new missions:
- The Lantern's Eye (Anchors + Hunt);
- Exodus (Escort, twelve charges);
- The Heart of Faith (Raze + Assassinate).

It also gets two new wishes (heard on Tier 5 only), the board's end state once all 25 missions are cleared, the photos, the
whole-v0.11 notes and the release bench. Each mission is on the board, has a behaviour scenario that passes the user's gate, and is
photographed.

**Architecture:**
- **Three groundwork refactors first, each its own task, each proving every reference exact:**
  - Task 1: `EscortDirector`'s per-charge state moves into a `Charge` record; the old fields become accessors over `charges[0]`
    (The Lost Lamb's and The Prisoner's twelve references prove it); `EscortObjective` gains `need`.
  - Task 2: `HuntDirector._unguarded_blow()` and `shield_hits` (The Heretic Hunt's six prove them).
  - Task 3: the HUD's keepout: `Hud.stack_rect()` handed to `tag_layout()` and `frame_point()`, so no map tag or arrow sits under
    the left HUD stack in any mission; no camera moves, no reference moves. The kit gains `Kit.STACK`.
- **Tier 5 plumbing (Task 4):** `MissionBook._tier5()`, `StagesObjective`, `RazeDirector._spoil_for()`, the Searchlight's `hunt` and
  `hold`, `TierBook._with_gaze()` adding a Gaze objective only to a list that has none, and three `MissionDirector` virtuals
  (`stages_done()`, `lost_reason()`, `hud_line()`).
- **One director per mission, all new files:** `LanternEyeDirector` (a `HuntDirector`), `ExodusDirector` (an `EscortDirector` on the
  Charge record), `HeartOfFaithDirector` (a `RazeDirector`). Each keeps its own Gaze, a plain `GazeMeter` (the Heart's a subclass).
- **Wishes (Task 8):** `PunishWish` gains `"clergy"`; `NeighboursWish` gains `"count"`, `"clergy"`, `"label"`, `"edge"`, `"route"`;
  the pool grows to eighteen.
- **Board and screens:** the three join Ascendance on the board in Task 9 (FLOW 113 to 114, and the all-25 end state as a unit test).
  Their behaviour scenarios run the `MissionBook` versions (the same director, clock and town, no wishes), so the checksums are exact
  references.

**Tech Stack:** Godot 4.7.2 GDScript. Headless test runner `tests/run_all.gd`. Behaviour scenarios in
`tools/dev/behaviour_check.gd`. The FLOW test in `src/game/game.gd`.

**Spec:** `docs/superpowers/specs/2026-10-15-kak-v011-m6-ascendance-missions.md` (the mission spec, Decisions 207-262, accepted as
rulings with the controller's notes: each new mission keeps its own Gaze at 10 a seen death; Tier 5 wish draws may change, re-pinned
and named; the Heart's litter reuses M5's hidden ride, so M5 lands first). It builds on
`docs/superpowers/specs/2026-10-08-kak-v011-tiers-design.md` (§2, §4, §5, §7.1, §8 rows 21-25), M1-M4 as shipped, and M5 as planned
(`docs/superpowers/plans/2026-10-10-kak-v011-m5-reckoning.md`, its rulings in `.superpowers/sdd/2026-10-10-kak-v011-m5-reckoning/rulings.md`).
Executors read the mission spec and this plan. **M5 lands before M6 starts:** where this plan names an M5 helper (the Lantern Knights
as `BishopDirector._knight()` makes them with `Crowd.add_soldier()`, `RazeDirector.hud_line()`, `EngineerManager.hands_off`, Pip's
hidden ride, `_tier4()`, `_flow_tier4()`, the `bishop` / `armoury` / `sermon` / `relic` scenarios, behaviour_check's `_none_within()`,
`test_tier4_wishes.gd`, `test_tier4_board.gd`, the `heretic` and `family_out` wishes, `Kit.STACK` if M5 added it), it means that
helper as M5 lands it. If one differs from M5's plan in a way a step here depends on, stop and report.

## Global Constraints

- **Baseline** (the controller fills these two in at M5's landing, here and nowhere else): branch `claude/lantern-campaign-spec` at
  `b85b584` (tag `kak-v011-m5`).
  - Tests baseline **`6346`** (`checks=6346 failures=0`).
  - FLOW **113/0**.
- **Machine:** the BURIN_NITRO laptop.
  - Work in the worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve/.claude/worktrees/game-concept-story-review-636208` (Git Bash path
    `/c/BURIN_NITRO/...`) on `claude/lantern-campaign-spec`. Never `cd` to the repo root; never touch other sessions' worktrees.
  - **Godot:** `G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe`.
- **Commands** (implementers run every long command in the FOREGROUND, never with a background monitor or polling; every foreground
  command stays under 10 minutes):
  - **Import** (after a new `class_name` file or a new test file): `timeout 900 $G --headless --editor --path . --import >/dev/null 2>&1`.
  - **Tests, in parts:** the full suite passes the 10-minute cap, so it always runs in halves with the scratch runner:
    `timeout 600 $G --headless --path . --script res://.superpowers/sdd/2026-10-15-kak-v011-m6-ascendance/run_half.gd -- --half=1 2>&1 | grep -v '^\s*at:' | grep -n "FAIL\|SCRIPT ERROR\|Parse Error\|checks="`,
    then `--half=2`. Expected: each `checks=N failures=0`; add the two counts and report both. If a half nears 600 s, say so in the
    report: the controller splits it. Implementers never edit `run_half.gd` or `refs24.sh` (the controller copies M5's into
    `.superpowers/sdd/2026-10-15-kak-v011-m6-ascendance/` when it opens the M6 workspace). The `leaked` / `still in use` lines at exit
    are there at baseline too.
  - **FLOW:** `timeout 900 $G --path . --audio-driver Dummy --scene res://scenes/game.tscn -- --flow-test 2>&1 | grep "FLOW"`.
    - Expected: `FLOW result checks=N failures=0`. The counts by task: 113 through Task 8, 114 from Task 9.
    - **FLOW runs alone** (memory: it aborts under parallel Godot load, as restart-during-ending or a Festival draft Nil). Before it,
      check `tasklist | grep -i godot`: other sessions run Godot. If any runs, say so in the report and rerun when it is quiet.
  - **Behaviour:** `timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- <args>`.
  - **Scenario loop** (a scenario's six runs; paste the function and its call into one Bash command):

```bash
scen() { for c in none play; do for s in 1 2 3; do
  out=$(timeout 600 $G --headless --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=$1 --case=$c --seed=$s 2>&1)
  echo "$1 $c $s: $(echo "$out" | grep -o 'checksum=-\?[0-9]*' | tail -1) $(echo "$out" | grep -o 'result won=.*' | tail -1)"
  echo "$out" | grep -q "SCRIPT ERROR" && echo "  SCRIPT ERROR in $1 $c $s"
done; done; }
G=/c/BURIN_NITRO/Godot/Godot_v4.7.2-stable_win64_console.exe; scen eye
```

  - **Photos:** `GODOT=$G SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture` (writes
    `captures/screen_<name>.png` at twice the 640x360 size).
- **The user's binding rules** (M2 ruling 55, M3's controller ruling 1). Every mission is finished by acting, never by waiting; every
  timed wait is 60 s or less, every chain wait 45 s or less, and no wait before the last item is a pure 45 s with nothing to work on.
  Each mission task ends with **the gate**, on seeds 1-3 of its scenario:
  - `none` (doing nothing) loses 3 of 3;
  - `play` (the scripted player) wins at least 2 of 3;
  - the median time of `play`'s wins is 180-240 s;
  - `play`'s longest stretch between two casts (`idle=` on its result line) is 45 s or less.
  - **The scripted policy works the opposition as a player would before any opposition is tuned down** (M3's Task 2 ruling): if the
    gate misses, first check the policy plays the spec's steps well (clears the next item's people in the last 25 s, does not idle
    while a slot is ready and a step applies, takes its Dooms unseen); only then tune the mission's knobs in the spec's order (each
    task lists them), re-run all six, and record each round in the commit body. After three rounds, stop and report to the
    controller. Never add protection or rules the spec and this plan do not have.
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
    - Vigil Flame `--scenario=flame --case=none --seed=1`: `won=false reason=gaze`; and its play line
      `--scenario=flame --case=play --seed=1` exactly as M5's Task 1 recorded it: `checksum=-884746702 won=true reason=flame time=158.8` (the controller fills it in at M5's
      landing, or writes "not repeatable" if M5 found it so).
    - Feast `--scenario=feast --case=play --seed=1`: won festival.
  - **M2's 24 scenario references:** `bash .superpowers/sdd/2026-10-15-kak-v011-m6-ascendance/refs24.sh tax harvest lamb prayers`
    prints `OK` on all 24 lines (six at a time; fixed-fps headless runs are deterministic under load). The Lost Lamb's six prove the
    Charge record (Task 1); Spoiled Harvest's six prove `_spoil_for()` (Task 4). Never "fix" a mismatch by editing the table: report it.
  - **M3's 18 scenario references** (the Scenario loop for `ringers`, `panic` and `informer`, compared line by line):

    | Scenario | `none` seeds 1 / 2 / 3 | `play` seeds 1 / 2 / 3 |
    |---|---|---|
    | ringers | `-275717420` / `-138070945` / `-370827666`, lost `bell` | `153399206` won 232.9 / `-667456881` won 176.3 / `-195878434` lost 173.3 |
    | panic | `-42444191` / `-831702796` / `49852883`, lost `market_closed` at 300.0 | `-102624718` won 220.0 / `-214853765` won 212.6 / `-575287130` won 195.6 |
    | informer | `-466238773` / `-645533123` / `-807294926`, lost `names` at 305.0 | `-597754669` won 200.2 / `-239928876` won 191.3 / `-328944037` won 191.1 |

  - **M4's 18 scenario references** (the Scenario loop for `bread`, `prisoner` and `hunt`, compared line by line; The Prisoner's six
    prove the Charge record, The Heretic Hunt's six the Hunt hooks, The Crown's Bread's six `_spoil_for()`):

    | Scenario | `none` seeds 1 / 2 / 3 | `play` seeds 1 / 2 / 3 |
    |---|---|---|
    | bread | `-707320795` / `644216709` / `-462416169`, lost `fed` at 300.0 | `-276094738` won 201.5 / `-59287158` won 234.5 / `-807789484` won 197.4 |
    | prisoner | `-375909400` / `-681839640` / `-196957329`, lost at 120.0 | `-731703837` won 203.0 / `-553130710` won 199.2 / `-934259560` won 181.9 |
    | hunt | `-597541405` / `-791635430` / `-892028599`, lost `cellar` | `-963589173` won 193.5 / `-868570277` won 183.2 / `-867462749` won 193.5 |

  - **M5's 24 scenario references** (the Scenario loop for `bishop`, `armoury`, `sermon` and `relic`, compared line by line; The Relic
    Run's six prove the Searchlight's hooks, The Armoury's six `_spoil_for()`). The controller fills this table at M5's landing:

    | Scenario | `none` seeds 1 / 2 / 3 | `play` seeds 1 / 2 / 3 |
    |---|---|---|
    | bishop | `-692249829` / `-495139667` / `-471648012`, lost `bishop_taken` at 300.0 | `-943288237` won 212.9 / `-828404714` won 205.8 / `-463707580` won 212.3 |
    | armoury | `-380503721` / `-201418589` / `-267556886`, lost at 300.0 | `526047863` won 235.7 / `870572996` won 214.4 / `134901992` won 200.8 |
    | sermon | `-810117103` / `-207340657` / `-835687543`, lost `sermon_over` at 300.0 | `-281824173` won 195.4 / `-290466371` won 216.4 / `-230770975` won 200.2 |
    | relic | `-712680865` / `-157937293` / `-810842590`, lost `relic_kept` | `-421048858` won 189.5 / `-896877697` won 181.3 / `-118745191` won 182.6 |

  - **M6's new references:** each mission task records its scenario's `none` and `play` checksums and result lines for seeds 1-3 in
    its commit body. From the next task on they must not move: each later task runs the Scenario loop for every M6 scenario already
    recorded and compares line by line.
- **Text and drawn shapes only:** no PixelLab, no new image assets, no new fonts. The mirrors' guards and Exodus's Inquisitors are made
  `CitizenProfile.Role.WATCHMAN` (the watch cloak and lantern); the mirror-wrights `Role.ENGINEER` (the apron and cap); the Lantern
  Knights wear Broken Lanterns' gold tabard (corps `KNIGHT`); High Priest Odran is a cleric as he is. The mirrors are their wall
  towers, named by tags; the Searchlight is The Vigil Flame's (`SearchlightFx`). Odran's litter is its bearers, tagged; no litter is
  drawn. Every other stand-in is an existing building or person named by a map tag.
- **Objective clarity** (M3's controller ruling 7, M4's stack ruling): every moving target has a tag with an edge arrow; from Task 3 the
  HUD keeps every tag's label and every arrow off the live left stack (`Hud.stack_rect()`) in every mission, so no camera moves for the
  stack again; each new mission's tests check its key spots against the real stack depth (`Kit.clear_of_stack(g, cam, Kit.STACK)`);
  results titles use each mission's own reason keys in `ResultsScreen.ACT_TITLES`.
- **Colours** (mission spec §0): target gold `d8b23a`, places orange `ff9a3a`, watchers and danger red `c8342a`, the god's charges
  steel blue `8fb8e8`, not yet grey `9a948a`, clear green `7fc46a`, wishes soft blue `8fb8ff`. Lantern Knights are red, as The
  Bishop's.
- **The campaign and the existing missions:** the `[campaign]` save and flow stay as they are. Every M1-M5 mission plays exactly as
  before: every new var and hook defaults to today's behaviour. Last Judgement and The Long Night keep their directors, rules, board
  versions and their 0.5-a-death Tier 5 Gaze.
- **MissionBook's own missions** do not change. The three new ones are added in `tier_missions()`, never in `all()`.
- **Own people, held on duty** (M2-M5 lessons): every person a director uses is its own -- lay citizens appointed through
  `_eligible()` / `_lay_near()` / `_lay_reaching()` / `_citizen_near()` / `_house_near()` (so no wisher, wish target or wish building is
  ever taken), and The Heart of Faith's Knights added by `Crowd.add_soldier()`; no town soldier is ever borrowed. Everyone whose loss
  would change the night is put on duty at his place from setup (`Person.go_duty()`); people waiting for their time wait indoors
  (`_take_inside()`), on duty, untouchable.
- **The evacuation rule** (M4's final review, M5's rulings): at each look every M6 director runs **one** rule over everyone it holds,
  `MissionDirector._hold_all(people, evacuating)` (`evacuating` from `_evacuation_began()`, true once), then puts each on duty again by
  its own rules; one away from his post when the evacuation begins is recalled at once. No new copy of the flight rule. Anyone brought
  out of a building after the evacuation may have begun is passed through `_keep_from_flight(p, true)` before his duty. Each mission has
  an **evacuate-mid-mission test** (`Kit.evacuate()` once the night is running): one held person recovering and one whispered when it
  begins, both at their places afterwards.
- **Reliefs** are flight-proofed (`_keep_from_flight(p, true)` once `crowd._fled_all`) and back off RELIEF_AFTER when none can reach.
- **Relays:** none in M6 (no `TempleReport`, no runner).
- **No hidden losses:** a stray kill or a stray power never makes a night silently unwinnable: it is counted with a plain loss reason
  (Exodus's "TOO FEW ARE LEFT"), or the person's tag warns from the start (LAMP - DO NOT KILL), or the place cannot fall (the mirror
  towers, Exodus's houses: stone tonight). A person leaving the town resolves at once. Every quick loss has a tag, a hint and a
  countdown.
- **Hit-stop:** scenarios that cast Smite or Heaven Splitter turn it off (`Impact.hitstop_enabled = false`): `eye` and `heart` join the
  list.
- **Headless tests never think** (M4's pre-flight rulings): nobody walks, a whisper never wears off and a confusion never lifts on its
  own, and `Person.tick()` never runs. Place people with `Kit.arrive()`; check anchors and minds, not arrival; end a confusion with
  `p._come_to()` and a whisper with `p._wake()` by hand; `p._recover(1.0)` puts one back on his feet; set `p._shaken_left = 0.0` by
  hand. ctx is null: no FX; a power is simulated by its effect (`env.damage_radius()` for a Smite, `crowd.fires.ignite()` for an Ember,
  `crowd._field.kill()` or `Kit.free_body()` for a kill, `Person.whisper()` / `confuse()` / `panic()` for the minds,
  `rules.cast_made.emit(slot, key, at)` for a cast the director hears).
- **TownLayout:** new reads only inside `src/game/mission/` (M3's controller ruling), in a few named constants per director. The wishes
  read roles; the HUD reads only its own panels.
- **Style:**
  - Tabs. Static types. Match the neighbouring code.
  - A `##` doc comment on every new const, var and func, in full sentences, in the file's own voice, tagged "v0.11 M6".
  - Never name a member `seed` or `script`. Never redeclare a constant a parent class declares (GDScript refuses it).
  - **Freed bodies:** a citizen's body is freed after its death fade, and an escaped one at once (`Crowd.escape()`). Every Person that
    may be freed is held or iterated as a `Variant` (or in an untyped `Array`) and guarded with `MissionDirector._alive()` /
    `is_instance_valid()` before any cast or member access.
- **Test style:**
  - `extends RefCounted`, `static func run(t)`, `t.check` / `t.near`.
  - Register each new file at the end of `SUITES` in `tests/run_all.gd`.
  - M6's tests share M3's world kit, `const Kit := preload("res://tests/test_tier2_groundwork.gd")` (with M4's `Kit.evacuate()` and
    Task 3's `Kit.STACK`).
- **Commits:** one per task, staging each new script's `.uid` too. End every message with the line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Every `##` doc comment and every notes paragraph M6 writes is tagged
  "v0.11 M6".
- **Spec sync** (M3's ruling): each mission task ends by syncing its section of the mission spec to its tuned numbers and words (the
  `Numbers` line, the timeline table, the clear's sum, the hint lines if they changed), in the same commit. The mission spec is still
  uncommitted at this plan's writing: the controller commits it with this plan before Task 1.
- **Controller's gates at landing:**
  - the Reference check, old and new (M3's 18, M4's 18, M5's 24 and M6's 18 included);
  - the full suite in halves, and FLOW 114/0 alone;
  - the three scenario gates of Task 9's Step 8;
  - the benches of Task 10, on a quiet machine.

## Review Focus

These are the inputs the spec implies but no single task's tests see whole, most likely to bite a player first.

1. **A shared class left alone must play exactly as before.**
   - The situation: Task 1 moves `EscortDirector`'s state into a record and threads `_exit_reached()`, `watch_changes` and the marching
     rule through it; Task 2 re-routes `HuntDirector._shield()`; Task 3 adds a keepout to every tag layout; Task 4 adds three
     `MissionDirector` virtuals, `_spoil_for()`, the Searchlight's `hunt` / `hold` and the one-Gaze rule; Task 8 adds wish parameters
     and grows the pool to eighteen.
   - Expected: The Lost Lamb, The Prisoner, The Heretic Hunt, Spoiled Harvest, The Crown's Bread, The Armoury, The Relic Run, The Vigil
     Flame, Last Judgement and The Long Night exactly as before; Tier 1-4 nights draw exactly what they drew.
   - Pinned by: Task 1 `_charge_record`, `_charge_defaults`, `_need`; Task 2 `_hunt_hooks`; Task 3 `_keepout_empty`; Task 4
     `_spoil_default`, `_searchlight_hooks`, `_one_gaze`; Task 8 `_kept`; every task's Reference check.
2. **The town takes the crowd mid-night** (City Emergency's evacuation, the rally).
   - The situation: the evacuation while a mirror's party stands and its wrights work a drain; while a household walks behind its lamp
     and a gate watchman recovers; while the Temple's Knights stand and a relief walks in, the litter walks, or Odran walks on foot.
   - Expected: every held person holds, or walks back at once; no believer is carried out of the count by the flight (one the crowd
     does carry out counts out); Odran never leaves the town; no Knight is rallied.
   - Pinned by: each mission's `_evacuated`.
3. **A beam that swings onto an aim already cast, and a cast in the light while no mirror stands.**
   - The situation: The Lantern's Eye's light is lit all night; the player casts where a beam is passing, before 0:50 or between
     mirrors, or a beam swings onto a spot just struck.
   - Expected: a cast aimed inside a lit pool adds 20 to the Gaze whenever the light is on, heard or not (a whisper too); a cast made
     outside the light is never counted later, however a beam swings; a quiet light draws no beam.
   - Pinned by: Task 5 `_seen_cast` (quiet and hunting, and a beam arriving after the cast), `_light`.
4. **A body freed mid-night, or a person gone from the town.**
   - The situation: a guard, a wright, a relief, a believer, a gate watchman, a searcher, a Knight, a bearer or Odran dies and fades;
     a believer leaves by a boat or a gate the crowd took him to; Odran leaves the town.
   - Expected: `tags()`, `hint_phase()`, `hud_line()`, `report()` and the objectives never touch a freed Person; a believer gone counts
     out at once; Odran gone ends him as his death would.
   - Pinned by: each mission's `_freed`; Task 6 `_carried`; Task 7 `_leaves`.
5. **A wish's people or buildings, and a tag under a full night's rows.**
   - The situation: wishes are heard before each director's setup; the watchtower wish may set aside a mirror's tower; the
     moneylender's wish a household's house or the oil-house; the zealot wish a cleric who would be Odran; three wish rows push the
     stack down to about 165 px.
   - Expected: no wisher or wish target becomes a guard, wright, believer, Inquisitor, searcher or Odran; no wish's building becomes a
     mirror tower, a household's house or the oil-house (the next nearest is used); every arrow and label stays off the stack.
   - Pinned by: Task 9 `_reserved`; Task 5 `_reserved_tower`; Task 8 `_zealot_not_odran`; Task 3 `_keepout_stack`; Task 10's photos.

## Plan decisions

The mission spec's Decisions 207-262 are this plan's decisions, with the controller's notes. These settle how the code meets them
(numbered on from the spec's):

263. **Names:** `LanternEyeDirector`, `ExodusDirector` (inner `Household`, `Gate`), `HeartOfFaithDirector` (inner `Post`, `HeartGaze`),
     `StagesObjective`; the ids `MissionBook.LANTERN_EYE` / `EXODUS` / `HEART_OF_FAITH`; the scenarios
     `--scenario=eye|exodus|heart --case=none|play [--seed=N] [--board]`; the wish ids `zealot` and `priest`; the tests
     `test_tier5_groundwork.gd`, `test_lantern_eye.gd`, `test_exodus.gd`, `test_heart_of_faith.gd`, `test_tier5_wishes.gd`,
     `test_tier5_board.gd`, all on M3's kit. Spec constants a parent class already declares are not redeclared: Exodus uses
     `EscortDirector.SIGHT` (2.5, the spec's SIGHT) and names its gate posts' spacing `POST_GAP` (the base's `WATCH_GAP` is the guard
     change's seconds); the Eye uses `HuntDirector.SHAKE` for a stone tower's shake and `HuntDirector.TICK` for its looks.
264. **M4 Decision 67 reworded:** "the base gains the Charge record, its accessors gated on the Lamb's and the Prisoner's twelve".
265. **`Charge.man` is a `Variant`**, not the spec's `man: Person` (a charge's body is freed at once when he escapes; the freed-bodies
     rule). The `charge` accessor stays typed `Person` (tests write `var her := d.charge`) and gives `null` for a freed or missing man,
     which every caller already reads through `_alive()`.
266. **Per-charge setup is a hook,** `_place_charge(c)`: by default today's set-down at `charge_start`, pace, hold and duty, line for
     line; Exodus takes each believer into his household's house. `_in_use(c)` lists every charge's man (one charge: today's list).
267. **The guard change keys on the director's clock as today,** stored in the first record's `change_in` (the spec puts it in the
     record): `_step_free(c)` starts it when any charge nears the gate and `watch_changes` is on. One charge: today's order.
268. **The single-charge searchers stay single-charge:** `_hunt()` and `_step_hunters()` follow `charges[0]` as today; Exodus keeps its
     own searchers per household and overrides `_step_hunters()`. `_taken_inside(c)` is reached from the timeline through a lambda bound
     to `charges[0]`.
269. **`_unguarded_blow()` keeps today's order exactly** (hp, mark, destroy or crack); `shield_hits` emits `Structure.hit` only while the
     standard still stands, as `Structure.damage()` does. A standard's own filter is the one `_raise()` saved (`_filters`); The Heretic
     Hunt's posts saved an empty one, so its path is today's.
270. **The keepout:** `Hud.STACK_PAD` 4; `stack_rect()` is empty during the tour's caption and once the night is over; the objective and
     wishes plates' rects are factored out of `_draw_rows()` / `_draw_wishes()` (`objective_rect()`, `wishes_rect()`), drawing unchanged;
     an arrow sent to the stack's border lands where the line from the frame's centre first meets its right or bottom edge
     (`Hud._keepout_point()`), the stack sitting in the screen's top-left corner.
271. **`Kit.STACK`:** Task 3 adds it (`Rect2(0, 0, 240, 165)`) and `clear_of_stack(g, cam, zone := DEAD)` unless M5 already did; then it
     keeps M5's and says so.
272. **`StagesObjective` reads three `MissionDirector` virtuals** added in Task 4 -- `stages_done()` (false), `lost_reason()` ("") and
     `hud_line()` ("") -- which every existing `lost_reason()` / `hud_line()` (Raze, Escort, Hunt, Assassinate, Harvest, Informer,
     Prisoner, M5's) already overrides with the same signature. So the objective is generic without a cast to one director class.
273. **`_tier5()`:** tier 5, 7:00, 6 / 16, `tier_floor` 4, no profile, `intro_banner` the name in capitals; stretch 1 on the board.
274. **One Gaze objective:** `TierBook._with_gaze()` and `_with_gaze_for_night()` append a `GazeObjective` only when the made list has
     none (`TierBook._has_gaze()`).
275. **The Searchlight's hooks:** `hunt` (false) makes `searching` true whenever a noise is held; `hold` (INF) ends a search `hold`
     seconds after its noise was heard (`_noise_age`, reset by `hear()`). With the defaults the search rule is today's: `_noise_age <
     INF` is always true. The Eye clears `noise` when it goes quiet, so a quiet light never searches, even in the clock's last 20 s.
276. **The Eye's towers are stone from setup** (its own `_stone` filter: a blow only shakes), so before its time a tower only shakes;
     the base's `_raise()` saves that filter and puts `_shield` on; the Eye's teardown runs the base's (which puts `_stone` back) and
     then gives each tower its own filter.
277. **The Eye measures "on guard" from the tower** (`_guarding()` overridden): the tower stands all night, so its party guards it
     before its mirror goes up too (the base measures from the step's spot until the standard is raised).
278. **The Eye's countdown:** the director's own clock decides (`eye_left()`), loss and banner in its own step; the strip shows it
     through a display-only timeline event ("The Eye opens") whose guard drops it when its run ends or its time comes, so its banner
     never doubles the loss's.
279. **Seen casts are judged whenever the light is on,** quiet or hunting (the spec: "heard or not"); hearing is only while a mirror
     stands.
280. **The wrights** are `HuntDirector.Guard` records (no relief); hung again, they go back inside at once (they stand at the door);
     gone for good, they come out if inside and go home (`_release()`); their away clock moves at each look (`HuntDirector.TICK`).
281. **The Eye's HUD row** is `HuntObjective` as M4 made it, label "Blind the Eye", count word "mirrors": "Blind the Eye: mirrors 1 / 3"
     (the spec's "Shatter the mirrors 1 / 3" cannot be made without editing `HuntObjective`, which the spec keeps as it is).
282. **Exodus's file:** each household keeps a trail of its lamp's footsteps (a crumb every half FOLLOW_GAP, at most TRAIL_MAX); a
     follower in file is held on duty at the trail point `FOLLOW_GAP x (his place in the file)` behind the lamp, while within
     FOLLOW_REACH; whispered he leaves the file (`_in_file` false) and holds where he is left; within REJOIN (2) of his lamp he rejoins.
     Once the lamp gets out by a gate, every member still in file walks on to that way out.
283. **Exodus's taken believer** goes inside the Temple at once when his seizer delivers him (`_step_held()` override after the base's).
284. **Exodus's gates shut by timeline events,** each on the strip from 0:00; a shut gate's way out is no way out (`_exit_reached()`);
     the last shutting loses through `lost_reason()` ("gates_shut") only with fewer than ten out.
285. **Exodus's walk-back delay:** a lay watcher back on his feet (RECALL_MINDS) takes his post or beat again only RETURN_AFTER after he
     first stood calm (`_calm_since`), at once in the two looks after the evacuation began (`_recall_until`); on duty he is always on
     his post. A seizer and a searcher never take a post.
286. **Exodus's gate reliefs** come from the Temple's door: the lay citizen nearest it with a way to the post, made a watchman, at most
     RELIEFS a night; with none, the search backs off RELIEF_AFTER. Flight-proofed once the town runs.
287. **Exodus's lamp** is a household's first member in town who is alive, out of doors, not escaped, not taken and not held by a
     seizer (`lamp(i)`), computed at each read, so it passes on by itself.
288. **Exodus holds its believers** with `_hold_all()` (unlike The Lost Lamb, whose free charge the crowd may carry): the spec's
     evacuation test wants the household to walk on and none to flee. The crowd's own `escaped` signal still counts a believer out.
289. **The Heart's Knights** are made by its own `_knight()` (copied from M5's `BishopDirector._knight()`, not shared): a soldier of corps
     KNIGHT with three times a soldier's health, at his post. Its posts are placed by a copy of The Crown's Bread's `_spread()` with
     POST_APART 2.1, so every post stands within GUARD_REACH of a small oil-house and beyond a witness's 2.0 of every other.
290. **The litter** is a point: the mean of its living bearers' places less their corner offsets; Odran, hidden indoors, is carried on
     it every frame (Pip's ride). Each look the bearers walk on duty to the corners of a square LITTER_STEP further along Odran's road.
     Its square starts at the first point at or below the Citadel's gate where all four corners are walkable (`_litter_spot()`).
291. **The litter reaching the steps sets Odran down:** he steps out on foot within ALTAR_REACH and begins the rite; the living bearers
     stand where they are (the spec does not say; without this a rider at the steps could never rekindle).
292. **ODRAN_PACE on duty:** a man on duty walks at `Person.PANIC_SPEED x pace` (1.6), so 0.5 gives 0.8 units a second and his 14-unit
     road takes about 18 s, not the spec's "about 40 s" (written for walking speed). 0.5 is kept as the first guess; Task 7's gate tunes
     it (0.25-0.5).
293. **The Heart's Gaze** is `HeartOfFaithDirector.HeartGaze extends GazeMeter`: SEEN (10) a seen death, FURY (20) once `fury` is set
     when the flame goes out.
294. **The blessing** is a timeline event guarded by the flame still burning, whose callback sets `blessed` (`lost_reason()`);
     "Put out the flame 1 / 2: blessed in 2:10" reads `timeline.seconds_to("blessed")`.
295. **The Heart's oil-house** is the first dwelling nearest OIL_AT (`_house_near()`, so never a wish's) whose door the street from the
     Citadel's gate reaches, of HOUSE_TRIES.
296. **A fright stops Odran a moment:** at the next look a panicked Odran is put back on duty where he stands; the rite resets on the
     frame his mind leaves DUTY.
297. **The wishes' extra parameters:** `NeighboursWish` also takes `"label"` (default NEIGHBOUR), `"edge"` (false) and `"route"` (the
     longest street walk to the wisher, 0 for none); the priest is the cleric nearest the wisher by street within it. `PunishWish`'s
     zealot is a living cleric out of doors, at random.
298. **`shuts_gates`** is added to "Lead my brother out" (`brother`) and "Lead my family out" (M5's `family_out`) clashes.
299. **Tier 5 draws:** at this plan's writing no test pins a Tier 5 draw (`test_board_nights._wiring_order` counts clashes only). Task 8
     greps again (M5 may have added one) and re-pins and names any it finds.
300. **FLOW 114:** M4's Omen-locked step also opens Ascendance's tab and checks its five cards behind "Clear 3 Reckoning missions"; a new
     `_flow_tier5()` (Ascendance opened as a fixture) plays The Lantern's Eye from the board, gives each mirror up by its public state
     (`_raise(i)` then `_gone(i)`), ascends, and reads "Ascendance 1 / 5 cleared".
301. **The board complete:** `DescendState.all_cleared()` (every `TierBook.all()` id cleared); the last tier's line counts all its
     missions; "...: every tier is cleared" and the header's "All 25 cleared" (`TierBook.all().size()`).
302. **Photos:** `TIER5_SHOWS` = the three ids, `lantern_eye-hunt` and `heart_of_faith-odran`; `tiers --mission=last_judgement`; a new
     `tiers-all`. The keepout's proof retakes `--show=crowns_bread|informer|spoiled_harvest` as their board nights hear (three, two and
     two wishes): no flag forces a wish count.
303. **Hint phases** are listed most urgent first in each director: the Eye `eye`, `shattered`, `guarded` / `open`, `waiting`; Exodus
     `caught`, `hounds`, `shut`, `gate`, `waiting`; the Heart `coming`, `litter`, `rite`, `on_foot`, then `guarded`, `burning`, `open`,
     `not_yet`.
304. **Policies' quiet Doom:** every M6 policy Dooms only where the Doom is unseen by the witness rule (`_doom_unseen()`: nobody living
     outside the cast's radius stands within 2.0 of anyone inside it) and takes none of its own charges (`spare`); it generalises the
     spec's "no one else within 2" so one Doom on two searchers 1.0 apart counts as alone.

### Where the spec does not fit the code

- **§0 / §6.1 `man: Person`:** a `Variant` (decision 265).
- **§1 HUD "Shatter the mirrors 1 / 3":** `HuntObjective` reads "<label>: <count word> 1 / 3"; it shows "Blind the Eye: mirrors 1 / 3"
  (decision 281).
- **§1 "within GUARD_REACH (2.0) of the tower's footprint" before the mirror is up:** the base measures from the spot until the standard
  is raised; the Eye measures from the tower always (decision 277).
- **§1 "The strip shows" the Eye's countdown:** a display-only event (decision 278).
- **§2 SIGHT and the gate posts' 2.4:** the base's SIGHT; POST_GAP (decision 263).
- **§3 "Odran ... about 14 units ... +about 40 s":** about 18 s at ODRAN_PACE 0.5 on duty (decision 292).
- **§3 the litter at the steps:** not said; Odran steps out there (decision 291). The square "just outside the gate": the first spot below
  it with room for four corners (decision 290).
- **§6.2 "Reserved towers" under the Hunt groundwork:** the base reads no tower; the Eye's own `_tower_near()` (a copy of The
  Bell-Ringers') lands with the Eye in Task 5, and its test there.
- **§6.5 `StagesObjective` reads "the director's" `stages_done()`, `lost_reason()`, `hud_line()`:** three `MissionDirector` virtuals
  (decision 272).
- **§7 photos "with three wishes" for The Informer and Spoiled Harvest:** their board nights hear two (Tiers 1-2); decision 302.
- **§7 "`Kit.STACK` ... beside the old DEAD":** M5's pre-flight ruling may have added it already (decision 271).

---

## File Structure

- **Created:**
  - `src/game/mission/stages_objective.gd` (Task 4), `lantern_eye_director.gd` (Task 5), `exodus_director.gd` (Task 6),
    `heart_of_faith_director.gd` (Task 7).
  - Tests: `tests/test_tier5_groundwork.gd` (Task 1, grown by Tasks 2-4), `test_lantern_eye.gd` (5), `test_exodus.gd` (6),
    `test_heart_of_faith.gd` (7), `test_tier5_wishes.gd` (8), `test_tier5_board.gd` (9).
- **Modified:**
  - Task 1: `src/game/mission/escort_director.gd`, `escort_objective.gd`.
  - Task 2: `src/game/mission/hunt_director.gd`.
  - Task 3: `src/game/ui/hud.gd`; `tests/test_tier2_groundwork.gd` (the kit's `STACK`).
  - Task 4: `src/game/mission/mission_director.gd`, `raze_director.gd`, `searchlight.gd`, `mission_book.gd`; `src/game/descend/tier_book.gd`.
  - Tasks 5-7: `mission_book.gd`, `mission_hints.gd`, `src/game/ui/results_screen.gd`, `tools/dev/behaviour_check.gd`, the mission
    spec's own section.
  - Task 8: `src/game/descend/punish_wish.gd`, `neighbours_wish.gd`, `wish_book.gd`; the tests that pin the pool's contents.
  - Task 9: `src/game/descend/tier_book.gd`, `descend_state.gd`, `src/game/ui/mission_board.gd`, `src/game/game.gd` (FLOW, the `tiers`
    photo's save); `tests/test_tiers.gd`.
  - Task 10: `src/game/game.gd` (`--show`), `docs/KAK_Version_0.11_Summary.md`, `README.md`.
  - `tests/run_all.gd` in each task that adds a suite.

### Task 1: The Escort type's Charge record (groundwork, carried item 1)

**Files:**
- Modify: `src/game/mission/escort_director.gd` (new inner `Charge`, `charges`, `watch_changes`, accessors; `_begin()`, `_in_use()`,
  `step()`, every per-charge step; new `_appoint_charges()`, `_place_charge()`, `_exit_reached()`, `_resolved()`, `_all_resolved()`,
  `_charge_of()`, `_marching_other()`, `out_count()`, `left_count()`)
- Modify: `src/game/mission/escort_objective.gd` (`need`)
- Create: `tests/test_tier5_groundwork.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: the kit (`Kit.world()`, `Kit.done()`, `Kit.run_for()`, `Kit.arrive()`); `LostLambDirector`, `PrisonerDirector` as they are.
- Produces:
  - `EscortDirector.Charge` (inner, RefCounted): `man: Variant`, `held: bool`, `seizer: Variant`, `hold_at: Vector2`, `bound: bool`,
    `bound_lost: bool`, `freed_at: float`, `escaped: bool`, `taken: bool`, `change_in: float`.
  - `EscortDirector.charges: Array[Charge]`; `watch_changes := true`.
  - `EscortDirector._appoint_charges() -> Array[Person]`, `_place_charge(c: Charge) -> void`, `_exit_reached(c: Charge) -> bool`,
    `_resolved(c: Charge) -> bool`, `_all_resolved() -> bool`, `_charge_of(p: Variant) -> Charge`, `out_count() -> int`,
    `left_count() -> int`.
  - Per-charge steps: `_step_free(c: Charge)`, `_step_held(c: Charge)`, `_step_bound(c: Charge)`, `_unbind(c: Charge)`,
    `_seen_by(c: Charge) -> Person`, `_seize(c: Charge, by: Person)`, `_release(c: Charge)`, `_escape(c: Charge)`,
    `_taken_inside(c: Charge)`.
  - The old names `charge` (Person), `held`, `seizer`, `_hold_at`, `bound`, `bound_lost`, `freed_at`, `escaped`, `taken`, `change_in`
    read and write `charges[0]`, with today's defaults when there is none.
  - `EscortObjective._init(text := "Lead him out", out := "out", taken := "taken", dead := "dead", p_need := 1)`, `need: int`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_tier5_groundwork.gd`:

```gdscript
extends RefCounted
## v0.11 M6 the groundwork for Tier 5's new missions, each shared change shown to keep today's path when left alone (review focus 1):
## EscortDirector's Charge record and EscortObjective's need (Task 1); HuntDirector's _unguarded_blow() and shield_hits (Task 2); the
## HUD's keepout and the kit's real stack depth (Task 3); Tier 5's frame, StagesObjective, RazeDirector._spoil_for(), the
## Searchlight's hunt and hold, TierBook's one Gaze objective and a director's own Gaze (Task 4).

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## Where a pair of charges hides (v0.11 M6 tests): The Lost Lamb's fountain.
const PAIR_START := Vector2(11.4, -10.0)


## An escort of two charges (v0.11 M6 tests): The Lost Lamb's places, no watch and no patrols, the two lay citizens nearest its start;
## `changes` is the guard change's switch; with `exit_any` either escapes wherever he stands.
class Pair:
	extends EscortDirector
	var changes := true
	var exit_any := false

	func _plan() -> void:
		charge_start = PAIR_START
		gate_at = LostLambDirector.GATE_MOUTH
		exit_at = LostLambDirector.EXIT
		return_to = LostLambDirector.TEMPLE_DOOR
		guardhouse = LostLambDirector.GUARDHOUSE
		watch_changes = changes

	func _appoint_charges() -> Array[Person]:
		return _lay_near(charge_start, 2)

	func _exit_reached(c: Charge) -> bool:
		return exit_any or super(c)


static func run(t) -> void:
	_charge_record(t)
	_charge_defaults(t)
	_two_charges(t)
	_marching(t)
	_exit_hook(t)
	_need(t)
	_watch_switch(t)


## The Lost Lamb keeps one Charge record, and every old field reads and writes it (v0.11 M6, Task 1).
static func _charge_record(t) -> void:
	var s := Kit.world(MissionBook.lost_lamb())
	var d: LostLambDirector = s.d
	var c: EscortDirector.Charge = d.charges[0]
	t.check(d.charges.size() == 1 and c.man == d.charge and c.hold_at == d._hold_at and not c.held and not d.held and not c.bound
		and is_equal_approx(c.freed_at, -1.0) and is_equal_approx(c.change_in, -1.0) and d.out_count() == 0 and d.left_count() == 1,
		"The Lost Lamb: one Charge record, read through the old names")
	var w: Person = d.watch[0]
	d.held = true
	d.seizer = w
	d._hold_at = Vector2(1.0, 2.0)
	d.change_in = 12.0
	d.freed_at = 3.0
	t.check(c.held and c.seizer == w and c.hold_at == Vector2(1.0, 2.0) and is_equal_approx(c.change_in, 12.0)
		and is_equal_approx(c.freed_at, 3.0), "the old names write charges[0]")
	Kit.done(s)
	var p := Kit.world(MissionBook.prisoner())
	var pd: PrisonerDirector = p.d
	t.check(pd.charges.size() == 1 and pd.charges[0].man == pd.charge and pd.bound and pd.charges[0].bound and not pd.gaolers.is_empty(),
		"The Prisoner: her record bound, her gaolers appointed as before")
	Kit.done(p)


## An escort with no charge gives today's defaults (v0.11 M6).
static func _charge_defaults(t) -> void:
	var e := EscortDirector.new()
	t.check(e.charges.is_empty() and e.charge == null and not e.held and e.seizer == null and e._hold_at == Vector2.INF and not e.bound
		and not e.bound_lost and is_equal_approx(e.freed_at, -1.0) and not e.escaped and not e.taken and is_equal_approx(e.change_in, -1.0)
		and e.watch_changes and e.out_count() == 0 and e.left_count() == 0 and e._all_resolved(),
		"no charge: null, false, Vector2.INF and -1, as the old fields began")


## Two charges are both stepped (v0.11 M6): the one at the way out escapes, the other stays.
static func _two_charges(t) -> void:
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var a: EscortDirector.Charge = p.charges[0]
	var b: EscortDirector.Charge = p.charges[1]
	t.check(p.charges.size() == 2 and a.man != b.man and (a.man as Person).mind == Person.Mind.DUTY and (b.man as Person).mind == Person.Mind.DUTY
		and p.left_count() == 2 and p.out_count() == 0, "two charges, each set down and held where the god finds them")
	Kit.arrive(b.man as Person, p.exit_at)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(b.escaped and not a.escaped and p.out_count() == 1 and p.left_count() == 1 and not p._all_resolved() and p.charge == a.man,
		"each is stepped: the second at the way out escapes, the first stays (out 1, left 1)")
	Kit.done(s)


## A watcher marching one charge sees no other (v0.11 M6), though the other stands beside him.
static func _marching(t) -> void:
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var a: EscortDirector.Charge = p.charges[0]
	var b: EscortDirector.Charge = p.charges[1]
	var w: Person = p._free_soldiers(PAIR_START, 1)[0]
	p.watch.append(w)
	p.watch_posts.append(w.ground_pos)
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(8.0, 0.0))
	Kit.arrive(a.man as Person, w.ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and a.seizer == w and not b.held, "(set-up) the watchman seizes the first")
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(0.0, 1.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and not b.held and p.seizures == 1, "a watcher marching one charge sees no other")
	Kit.done(s)


## _exit_reached() is the way out's test (v0.11 M6): a subclass may widen it.
static func _exit_hook(t) -> void:
	var p := Pair.new()
	p.exit_any = true
	var s := Kit.world(MissionBook.lost_lamb(), p)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(p.out_count() == 2 and p._all_resolved(), "an _exit_reached() that says yes everywhere lets both out at once")
	Kit.done(s)


## EscortObjective's need (v0.11 M6): 1 by default, today's checks; above 1, done at that many out and failed only by the director.
static func _need(t) -> void:
	var lamb := Kit.world(MissionBook.lost_lamb())
	var o := (lamb.rules as Rules).objectives[0] as EscortObjective
	var d: LostLambDirector = lamb.d
	t.check(o.need == 1 and EscortObjective.new().need == 1 and o.check(lamb.rules) == Objective.Status.PENDING, "need 1 by default")
	d.escaped = true
	t.check(o.check(lamb.rules) == Objective.Status.DONE and o.reason == "lamb_out", "need 1: today's check, the charge out wins")
	Kit.done(lamb)
	var p := Pair.new()
	var s := Kit.world(MissionBook.lost_lamb(), p)
	var two := EscortObjective.new("Lead them out", "both_out", "one_taken", "one_dead", 2)
	p.charges[0].taken = true
	t.check(two.check(s.rules) == Objective.Status.PENDING, "need 2: one taken ends nothing by itself")
	p.charges[0].taken = false
	p.charges[1].escaped = true
	t.check(two.check(s.rules) == Objective.Status.PENDING, "one out of two needed: still open")
	p.charges[0].escaped = true
	t.check(two.check(s.rules) == Objective.Status.DONE and two.reason == "both_out", "two out: done, with its own reason")
	Kit.done(s)


## watch_changes (v0.11 M6): off, the guard change never starts; on (the default), it starts as The Lost Lamb's.
static func _watch_switch(t) -> void:
	var off := Pair.new()
	off.changes = false
	var s := Kit.world(MissionBook.lost_lamb(), off)
	Kit.arrive(off.charges[0].man as Person, off.gate_at + Vector2(0.0, -2.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(off.change_in < 0.0 and not off.watch_away, "watch_changes false: near the gate, the guard change never starts")
	Kit.done(s)
	var on := Pair.new()
	var s2 := Kit.world(MissionBook.lost_lamb(), on)
	Kit.arrive(on.charges[0].man as Person, on.gate_at + Vector2(0.0, -2.0))
	Kit.run_for(s2, EscortDirector.TICK + DT)
	t.check(on.change_in > EscortDirector.WATCH_CHANGE - 1.0, "watch_changes true: it starts")
	Kit.done(s2)
```

  - In `tests/run_all.gd`, append `"res://tests/test_tier5_groundwork.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then the halves. Expected: a parse error or FAILs in
  `test_tier5_groundwork` (no `Charge`, no `charges`, no `need`).

- [ ] **Step 3: The Charge record.** In `src/game/mission/escort_director.gd`:
  - In the class doc, after "A subclass names the charge and the places in _plan() (LostLambDirector).", add:
    `## v0.11 M6 (mission spec §6.1): each charge's state is a Charge record (charges); the old single-charge fields read and write the first,`
    `## so a subclass of one charge reads as before. Exodus has twelve.`
  - After `const BOUND_HOLD := 1.0` add the record:

```gdscript
## One charge's state (v0.11 M6, mission spec §6.1): a plain record, so the director holds no cycle. Its defaults are the old fields'.
class Charge:
	extends RefCounted
	## The charge, a Variant read only through MissionDirector._alive(): he is freed at once when he escapes.
	var man: Variant = null
	## He is held, and by whom (a Variant: the seizer may be freed); where he holds.
	var held := false
	var seizer: Variant = null
	var hold_at := Vector2.INF
	## He is bound; he was still bound at free_by; the second of the night he was freed (-1 until then).
	var bound := false
	var bound_lost := false
	var freed_at := -1.0
	## He got out; he was taken back.
	var escaped := false
	var taken := false
	## Seconds until the watch's next change (-1 until it starts). The director's clock lives in the first record (plan decision 267).
	var change_in := -1.0
```

  - Replace the block from `## The charge; the watch; each patrol (an Array[Person]); the searchers. Read only through _alive(): any may be`
    down to and including `var freed_at := -1.0` (the old `charge`, `held`, `seizer`, `escaped`, `taken`, `seizures`, `bound`,
    `bound_lost`, `freed_at` declarations) with:

```gdscript
## Every charge's record, in order (v0.11 M6): one for The Lost Lamb and The Prisoner, twelve for Exodus.
var charges: Array[Charge] = []
## The watch; each patrol (an Array[Person]); the searchers. Read only through _alive(): any may be freed.
var watch: Array[Person] = []
var patrols: Array = []
var hunters: Array[Person] = []
## How many seizures in all (v0.11 M2).
var seizures := 0
## v0.11 M6 (mission spec §6.1): false stops the watch's change ever starting (Exodus: a gate is cleared by acting, never waited out).
## True (the default) is The Lost Lamb's and The Prisoner's.
var watch_changes := true

## The first charge, typed (v0.11 M6: an accessor over charges[0], the old field): null with none, or once his body is freed.
var charge: Person:
	get:
		if charges.is_empty() or not is_instance_valid(charges[0].man):
			return null
		return charges[0].man as Person
	set(v):
		_first().man = v
## The first charge's state, as the old fields read it (v0.11 M6): each reads and writes charges[0], with the old default when there is none.
var held: bool:
	get:
		return charges[0].held if not charges.is_empty() else false
	set(v):
		_first().held = v
var seizer: Variant:
	get:
		return charges[0].seizer if not charges.is_empty() else null
	set(v):
		_first().seizer = v
var escaped: bool:
	get:
		return charges[0].escaped if not charges.is_empty() else false
	set(v):
		_first().escaped = v
var taken: bool:
	get:
		return charges[0].taken if not charges.is_empty() else false
	set(v):
		_first().taken = v
var bound: bool:
	get:
		return charges[0].bound if not charges.is_empty() else false
	set(v):
		_first().bound = v
var bound_lost: bool:
	get:
		return charges[0].bound_lost if not charges.is_empty() else false
	set(v):
		_first().bound_lost = v
var freed_at: float:
	get:
		return charges[0].freed_at if not charges.is_empty() else -1.0
	set(v):
		_first().freed_at = v
```

  - Replace `var change_in := -1.0` (under "The watch is away for its change; ...") with:

```gdscript
var change_in: float:
	get:
		return charges[0].change_in if not charges.is_empty() else -1.0
	set(v):
		_first().change_in = v
```

  - Replace `## Where he holds.` / `var _hold_at := Vector2.INF` with:

```gdscript
## Where the first charge holds (v0.11 M6: an accessor over charges[0].hold_at).
var _hold_at: Vector2:
	get:
		return charges[0].hold_at if not charges.is_empty() else Vector2.INF
	set(v):
		_first().hold_at = v
```

  - Replace `_begin()` with:

```gdscript
## The mission's setup (v0.11 M2): the plan, the charge set down where the god finds him, the watch at its posts and each patrol at
## the start of its beat. v0.11 M4: through the hooks, each handed the charge, and bound if bound_by is set. v0.11 M6: every charge
## _appoint_charges() names gets a record and is placed (_place_charge()); with one, today's order line for line.
func _begin() -> void:
	_plan()
	gate_at = _walkable(gate_at)
	exit_at = _walkable(exit_at)
	return_to = _walkable(return_to)
	guardhouse = _walkable(guardhouse)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	if hunt_at >= 0.0:
		timeline.add(hunt_at, "hunt", _hunt_label(), _hunt, func() -> bool: return not escaped and not taken and _alive(charge))
	for man in _appoint_charges():
		var c := Charge.new()
		c.man = man
		charges.append(c)
		_place_charge(c)
	if charges.is_empty():
		return
	crowd.escaped.connect(_on_escaped)
	if bound_by != null:
		for c in charges:
			c.bound = true
		if free_by >= 0.0:
			# Bound still, and by stocks still standing (v0.11 M4, the final review): stocks brought down in the last TICK before
			# free_by, which the next look would have answered by freeing him, never lose the night.
			timeline.add(free_by, "inside", _inside_label(), func() -> void: _taken_inside(charges[0]),
				func() -> bool: return bound and is_instance_valid(bound_by) and not bound_by.destroyed and not escaped and _alive(charge))
	watch = _appoint_watch(charge, watch_posts.size())
	for i in watch.size():
		_post_to(watch[i], _walkable(watch_posts[i]), false)
	for b: PackedVector2Array in beats:
		var squad := _appoint_patrol(charge, b, patrol_size)
		patrols.append(squad)
		_beat_at.append(0)
		for i in squad.size():
			_post_to(squad[i], _ring_spot(b[0], 0.5, i, squad.size()), false)
	rules.banner.emit(_opening_banner())


## Virtual (v0.11 M6, mission spec §6.1): every charge, in order (none for none) -- [_appoint_charge()] by default, The Lost Lamb's and
## The Prisoner's one; Exodus's twelve believers.
func _appoint_charges() -> Array[Person]:
	var out: Array[Person] = []
	var one := _appoint_charge()
	if one != null:
		out.append(one)
	return out


## Virtual (v0.11 M6): charge `c` set down where the god finds him, at his pace, held there on duty -- at charge_start by default
## (today's setup, line for line); Exodus takes each believer into his household's house.
func _place_charge(c: Charge) -> void:
	var p := c.man as Person
	var at := _walkable(charge_start)
	_set_down(p, at)
	p.pace *= charge_pace
	c.hold_at = at
	p.go_duty(at)


## The first record, made if there is none (v0.11 M6: for the old fields' setters).
func _first() -> Charge:
	if charges.is_empty():
		charges.append(Charge.new())
	return charges[0]


## The record whose man is `p`, or null (v0.11 M6). A Variant: `p` may be freed.
func _charge_of(p: Variant) -> Charge:
	for c in charges:
		if c.man == p:
			return c
	return null


## Charge `c` is resolved (v0.11 M6): out, taken back, lost bound, or dead.
func _resolved(c: Charge) -> bool:
	return c.escaped or c.taken or c.bound_lost or not _alive(c.man)


## Every charge is resolved, or there is none (v0.11 M6): the step's early return -- for one charge today's test.
func _all_resolved() -> bool:
	for c in charges:
		if not _resolved(c):
			return false
	return true


## How many charges are out (v0.11 M6).
func out_count() -> int:
	var n := 0
	for c in charges:
		n += 1 if c.escaped else 0
	return n


## How many charges are still in the town, alive and not taken back (v0.11 M6).
func left_count() -> int:
	var n := 0
	for c in charges:
		n += 1 if not c.escaped and not c.taken and _alive(c.man) else 0
	return n
```

  - In `_in_use(c: Person)`, after `var out: Array = [c]` add:

```gdscript
	for o in charges:
		if o.man != c:
			out.append(o.man)  # v0.11 M6: every charge's man (one charge: none added)
```

  - Replace `step()` with:

```gdscript
## One step (v0.11 M2): the timeline, the watch's change, then every TICK a look at each charge (held, bound or free), the watch's
## posts, the patrols and the searchers. v0.11 M4: the clock; a bound charge's look. v0.11 M6: each charge not resolved, in order.
func step(delta: float) -> void:
	_clock += delta
	timeline.step(delta)
	if _all_resolved():
		return
	_watch_step(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	for c in charges:
		if _resolved(c):
			continue
		if c.held:
			_step_held(c)
		elif c.bound:
			_step_bound(c)
		else:
			_step_free(c)
	if _all_resolved():
		return
	_step_watch_posts()
	_step_patrols()
	_step_hunters()
```

  - Replace `_step_free()` with:

```gdscript
## Free (v0.11 M2): sheltering indoors, nothing; at the way out he escapes; seen, he is seized; near the gate, the watch's change starts
## its clock; back on his feet he holds where he stands. v0.11 M6: charge `c`; the way out is _exit_reached(); the change only while
## watch_changes.
func _step_free(c: Charge) -> void:
	var p := c.man as Person
	if p.inside:
		return  # sheltering from a fright: hidden, unseen and unheard until he comes out
	if _exit_reached(c):
		_escape(c)
		return
	var by := _seen_by(c)
	if by != null:
		_seize(c, by)
		return
	if watch_changes and change_in < 0.0 and p.ground_pos.distance_to(gate_at) <= NEAR_GATE:
		change_in = WATCH_CHANGE
	if p.mind in HOLD_FROM:
		c.hold_at = p.ground_pos
		p.go_duty(c.hold_at)
	elif p.mind == Person.Mind.DUTY and p.anchor.distance_to(c.hold_at) > MOVE:
		p.go_duty(c.hold_at)


## Virtual (v0.11 M6): charge `c` has reached a way out -- within ESCAPE_REACH of exit_at by default; Exodus: any open gate's way out.
func _exit_reached(c: Charge) -> bool:
	return (c.man as Person).ground_pos.distance_to(exit_at) <= ESCAPE_REACH
```

  - Replace `_step_bound(c: Person)`, `_unbind(c: Person)` and `_taken_inside()` with:

```gdscript
## Bound (v0.11 M4, decision 94): `bound_by` down or gone, he is free; else he is held at his spot, kept shaking off a whisper and past
## fear, and set back on it should anything move him (Discord's confusion lasts a TICK at most). v0.11 M6: charge `c`.
func _step_bound(c: Charge) -> void:
	if not is_instance_valid(bound_by) or bound_by.destroyed:
		_unbind(c)
		return
	var p := c.man as Person
	p._shaken_left = maxf(p._shaken_left, BOUND_HOLD)
	p.fearless_left = maxf(p.fearless_left, BOUND_HOLD)
	if p.mind != Person.Mind.DUTY or p.anchor.distance_to(c.hold_at) > MOVE:
		p.go_duty(c.hold_at)


## He is freed (v0.11 M4): the holds let go so a whisper takes at once, he holds where he stands, and with hunt_after_free the
## searchers' event goes on the strip that long from now. v0.11 M6: charge `c`.
func _unbind(c: Charge) -> void:
	var p := c.man as Person
	c.bound = false
	c.freed_at = _clock
	p._shaken_left = 0.0
	if p.fearless_left <= BOUND_HOLD:
		p.fearless_left = 0.0
	c.hold_at = p.ground_pos
	rules.banner.emit(_unbound_banner())
	if hunt_after_free >= 0.0 and hunt_at < 0.0:
		timeline.add(timeline.elapsed() + hunt_after_free / timeline.stretch_factor(), "hunt", _hunt_label(), _hunt,
			func() -> bool: return not escaped and not taken and _alive(charge))


## Still bound at free_by (v0.11 M4): the night is lost (lost_reason()); the timeline's banner says so. v0.11 M6: charge `c`.
func _taken_inside(c: Charge) -> void:
	c.bound_lost = true
```

  - Replace `_step_held()`, `_seen_by()`, `_seize()`, `_release()`, `_escape()` and `_on_escaped()` with:

```gdscript
## Held (v0.11 M2): the seizer gone, turned or off his errand frees him; the seizer at `return_to` with him in tow, he is taken back;
## else the seizer walks on and he trails him (a whisper may pull him away a while; it does not free him). v0.11 M6: charge `c`.
func _step_held(c: Charge) -> void:
	if not _alive(c.seizer) or (c.seizer as Person).mind != Person.Mind.DUTY:
		_release(c)
		return
	var s := c.seizer as Person
	var p := c.man as Person
	if s.ground_pos.distance_to(return_to) <= RETURN_REACH and p.ground_pos.distance_to(s.ground_pos) <= TAKE_REACH * 2.0:
		c.taken = true
		c.held = false
		crowd.off_duty(s)
		rules.banner.emit(_taken_banner())
		return
	if s.anchor.distance_to(return_to) > MOVE:
		s.go_duty(return_to)
	if p.mind == Person.Mind.DUTY or p.mind in HOLD_FROM:
		if p.mind != Person.Mind.DUTY or p.anchor.distance_to(s.ground_pos) > TAKE_REACH:
			p.go_duty(s.ground_pos)


## The first soldier set to watch for charge `c` who sees him now (v0.11 M2): _watching() and within SIGHT; else null. v0.11 M6: a
## watcher marching another charge sees no other (vacuous with one).
func _seen_by(c: Charge) -> Person:
	var at := (c.man as Person).ground_pos
	for v: Variant in _watchers():
		if _watching(v) and not _marching_other(v, c) and (v as Person).ground_pos.distance_to(at) <= SIGHT:
			return v as Person
	return null


## `v` is marching a charge other than `c` (v0.11 M6).
func _marching_other(v: Variant, c: Charge) -> bool:
	for o in charges:
		if o != c and o.held and o.seizer == v:
			return true
	return false


## `by` seizes charge `c` (v0.11 M2): he is held, `by` is sent to march him to `return_to`, and he follows.
func _seize(c: Charge, by: Person) -> void:
	c.held = true
	c.seizer = by
	seizures += 1
	rules.banner.emit(_caught_banner())
	by.go_duty(return_to)
	(c.man as Person).go_duty(by.ground_pos)


## Charge `c`'s seizer lets go of him (v0.11 M2): the seizer goes back to the town's post if still on the errand, and he holds where he
## stands.
func _release(c: Charge) -> void:
	c.held = false
	if _alive(c.seizer) and (c.seizer as Person).mind == Person.Mind.DUTY:
		crowd.off_duty(c.seizer)
	c.seizer = null
	var p := c.man as Person
	c.hold_at = p.ground_pos
	if p.mind == Person.Mind.DUTY or p.mind in HOLD_FROM:
		p.go_duty(c.hold_at)
	rules.banner.emit(_freed_banner())


## Out (v0.11 M2): charge `c` leaves the town by the escape path (Crowd.escape() frees him at once).
func _escape(c: Charge) -> void:
	c.escaped = true
	rules.banner.emit(_escape_banner())
	crowd._field.remove(c.man)
	crowd.escape(c.man)


## However a charge left the town (v0.11 M2, the controller's Task 4 fix ruling) -- the way out, an exit he fled to, a river boat -- he
## has got away, as the Procession's Prince has: the crowd's own exit logic carries him off, and that is his escape, not his death. Not
## twice: _escape() has already said so. A seizer is let go. v0.11 M6: the record whose man he is.
func _on_escaped(p: Person) -> void:
	var c := _charge_of(p)
	if c == null or c.escaped or c.taken:
		return
	c.escaped = true
	if c.held:
		c.held = false
		if _alive(c.seizer) and (c.seizer as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(c.seizer)
		c.seizer = null
	rules.banner.emit(_escape_banner())
```

  - Leave every other function as it is: `_watch_step()`, `_step_watch_posts()`, `_step_patrols()`, `_on_post()`, `_hunt()`,
    `_step_hunters()`, `_watch_standing()`, `_gate_watched()`, `charge_lost()`, `tags()`, `hint_phase()`, `report()`, `teardown()`
    read and write the old names, now `charges[0]`. `_hunt()` and `_step_hunters()` stay single-charge (plan decision 268).
  - `PrisonerDirector` and `LostLambDirector` need no edit: they read `charge`, `held`, `seizer`, `bound`, `bound_lost`, `freed_at`,
    `escaped`, `taken`, `change_in` and override `_appoint_charge()`, `_in_use()`, `_appoint_watch()`, `_appoint_patrol()`,
    `_appoint_hunters()`, `_post_to()`, `_takes_post()`, `_watchers()` with today's signatures. If the parser objects to any of their
    reads, fix the base, never the subclass, and report it.

- [ ] **Step 4: `EscortObjective.need`.** In `src/game/mission/escort_objective.gd`:
  - The class doc gains: `## v0.11 M6 (mission spec §6.1): \`need\` -- with 1 (the default) today's checks; with more, DONE once that many are out`
    `## (EscortDirector.out_count()) and FAILED only through the director's lost_reason(), so a single seizure never ends a many-charge night.`
  - After `var _dead := ""` add:

```gdscript
## How many charges must get out (v0.11 M6): 1 by default.
var need := 1
```

  - `_init()` becomes:

```gdscript
## The label, the reasons for each ending, and how many must get out (v0.11 M2; v0.11 M6 `p_need`).
func _init(text := "Lead him out", out := "out", taken := "taken", dead := "dead", p_need := 1) -> void:
	label = text
	_out = out
	_taken = taken
	_dead = dead
	need = p_need
	reason = out
```

  - In `check()`, after the `if d == null: return Status.PENDING` lines, add:

```gdscript
	if need > 1:
		# v0.11 M6: many charges -- done at `need` out, failed only by the director's own loss (Exodus's count and its gates).
		if d.out_count() >= need:
			reason = _out
			return Status.DONE
		var why := d.lost_reason()
		if why != "":
			reason = why
			return Status.FAILED
		return Status.PENDING
```

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0` in both, the count up by
  about 14. `test_lost_lamb`, `test_prisoner` and `test_tier3_groundwork` unchanged.

- [ ] **Step 6: The Reference check, and FLOW.** Run all of it (Global Constraints). Expected: every value unchanged; `refs24.sh`
  24 x OK (**The Lost Lamb's six prove the Charge record**); M4's 18 as in the table (**The Prisoner's six prove it too**); M3's 18,
  M5's 24; FLOW 113/0, run alone. If any reference moves, stop and report (Decision 241's cost): never re-record one.

- [ ] **Step 7: Commit.**

```bash
git add src/game/mission/escort_director.gd src/game/mission/escort_objective.gd tests/test_tier5_groundwork.gd tests/test_tier5_groundwork.gd.uid tests/run_all.gd
git commit -m "refactor: the Escort type's Charge record -- per-charge state, the old fields as accessors, EscortObjective's need (v0.11 M6)" -m "<the halves' counts; refs24 24 x OK (the Lost Lamb's six), M4's 18 (the Prisoner's six), M3's 18, M5's 24, the global list; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: The Hunt type's unguarded blow (groundwork, carried item 2)

**Files:**
- Modify: `src/game/mission/hunt_director.gd` (new `shield_hits`, `_unguarded_blow()`; `_shield()`)
- Modify: `tests/test_tier5_groundwork.gd`

**Interfaces:**
- Consumes: `HereticHuntDirector` as it is; `HuntDirector._raise()`, `standard()`, `steps`, `Guard`, `_filters`.
- Produces: `HuntDirector.shield_hits := false`; `HuntDirector._unguarded_blow(s: Structure, amount: float, source: Vector2, kind: StringName) -> void`
  (virtual; The Lantern's Eye overrides it in Task 5).

- [ ] **Step 1: Write the failing test.** In `tests/test_tier5_groundwork.gd`:
  - After the `Pair` class add:

```gdscript
## The Heretic Hunt whose standards are heard when struck (v0.11 M6 tests): shield_hits on.
class Loud:
	extends HereticHuntDirector

	func _plan() -> void:
		super()
		shield_hits = true


## The Heretic Hunt whose first standard comes with an owner of its own (v0.11 M6 tests): the owner counts each blow handed to it and
## lowers nothing, as a borrowed tower's would.
class Borrowed:
	extends HereticHuntDirector
	var owned: Array = []
	var post: Structure

	func _raise_standard(i: int) -> Structure:
		var s := super(i)
		if i == 0:
			post = s
			s.damage_filter = func(_st: Structure, amount: float, _source: Vector2, _kind: StringName) -> void: owned.append(amount)
		return s
```

  - In `run()`, after `_watch_switch(t)` add `_hunt_hooks(t)`.
  - At the end of the file add:

```gdscript
## Step `i`'s guards moved well off their ring (v0.11 M6 tests): off guard, still alive.
static func _clear_party(d: HuntDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + Vector2(5.0, 5.0))


## HuntDirector._unguarded_blow() and shield_hits (v0.11 M6, Task 2): by default today's path, silent; heard when asked; a standard's
## own owner keeps its health, and gets it back at teardown.
static func _hunt_hooks(t) -> void:
	var s := Kit.world(MissionBook.heretic_hunt())
	var d: HereticHuntDirector = s.d
	d._raise(0)
	_clear_party(d, 0)
	var std := d.standard(0)
	var hits := [0]
	std.hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: hits[0] += 1)
	std.damage(10.0, std.center(), &"smite")
	t.check(not d.shield_hits and not d.guarded(0) and is_equal_approx(std.hp, std.max_hp - 10.0) and hits[0] == 0,
		"by default an unguarded blow lowers the standard's own health and is not heard (The Heretic Hunt's path)")
	Kit.done(s)
	var l := Loud.new()
	var s2 := Kit.world(MissionBook.heretic_hunt(), l)
	l._raise(0)
	_clear_party(l, 0)
	var loud := l.standard(0)
	var heard := [0]
	loud.hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: heard[0] += 1)
	loud.damage(10.0, loud.center(), &"smite")
	t.check(l.shield_hits and heard[0] == 1 and is_equal_approx(loud.hp, loud.max_hp - 10.0), "shield_hits on: the same blow, heard once")
	Kit.done(s2)
	var b := Borrowed.new()
	var s3 := Kit.world(MissionBook.heretic_hunt(), b)
	b._raise(0)
	_clear_party(b, 0)
	b.post.damage(10.0, b.post.center(), &"smite")
	t.check(b.owned == [10.0] and is_equal_approx(b.post.hp, b.post.max_hp), "a standard that came with an owner hands the blow to it")
	var post := b.post
	b.teardown()
	post.damage(5.0, post.center(), &"smite")
	t.check(b.owned == [10.0, 5.0] and is_equal_approx(post.hp, post.max_hp), "teardown gives the owner its building back")
	Kit.done(s3)
```

- [ ] **Step 2: Run the tests to verify they fail.** Expected: a parse error (no `shield_hits`).

- [ ] **Step 3: The hooks.** In `src/game/mission/hunt_director.gd`:
  - After `var head_chain := -1.0` add:

```gdscript
## v0.11 M6 (mission spec §6.2): an unguarded blow is heard as any struck building's is (Structure.hit: fire catching, windows) while the
## standard still stands. False (the default) keeps The Heretic Hunt's standards out of the fire manager's hearing; The Lantern's Eye
## sets it.
var shield_hits := false
```

  - Replace `_shield()` with:

```gdscript
## Structure.damage_filter for a standard (v0.11 M4, Broken Lanterns' guarded shrine): guarded, the blow only shakes it; else
## _unguarded_blow() takes it (v0.11 M6).
func _shield(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	var i := _step_of(s)
	if i >= 0 and _guarded(i):
		s.shake(SHAKE)
		return
	_unguarded_blow(s, amount, source, kind)


## Virtual (v0.11 M6, mission spec §6.2): a blow on a standard no one guards. A standard that came with a damage filter of its own -- a
## borrowed building's owner, saved by _raise() -- is handed the blow, and keeps its health; else today's path: its health lowered, the
## hit marked, then its fall, or its cracks below Structure.CRACK_AT (heard while it stands, with shield_hits). The Lantern's Eye
## overrides it: the mirror's glass.
func _unguarded_blow(s: Structure, amount: float, source: Vector2, kind: StringName) -> void:
	var own: Callable = _filters.get(s.get_instance_id(), Callable())
	if own.is_valid():
		own.call(s, amount, source, kind)
		return
	s.hp -= amount
	s.mark_hit(amount / s.max_hp, kind)
	if s.hp <= 0.0:
		s.destroy(source, kind)
	else:
		if shield_hits:
			s.hit.emit(s, amount, kind)
		if s.hp < s.max_hp * Structure.CRACK_AT:
			s.crack()
```

  - In the class doc, after "...overrides _found() and _quarry_point() for its Searchlight (decision 111).", add:
    `## v0.11 M6: an unguarded blow goes through _unguarded_blow() (a borrowed standard's owner keeps its health), heard with shield_hits.`
  - The base reads no tower: the reserved-tower rule (spec §6.2) is the Eye's own (Task 5).

- [ ] **Step 4: Run the tests to verify they pass.** Run the halves. Expected: `failures=0`, the count up by 4. `test_heretic_hunt`
  unchanged.

- [ ] **Step 5: The Reference check, and FLOW.** Expected: unchanged; **The Heretic Hunt's six** (`hunt` in M4's table) exact, which
  proves the hooks; FLOW 113/0, alone.

- [ ] **Step 6: Commit.**

```bash
git add src/game/mission/hunt_director.gd tests/test_tier5_groundwork.gd
git commit -m "refactor: the Hunt type's unguarded blow -- a borrowed standard's owner keeps its health, shield_hits (v0.11 M6)" -m "<the halves' counts; the Heretic Hunt's six and the whole Reference check exact; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: The HUD's keepout (groundwork, carried item 3)

**Files:**
- Modify: `src/game/ui/hud.gd` (new `STACK_PAD`, `objective_rect()`, `wishes_rect()`, `stack_rect()`, `_keepout_point()`;
  `tag_layout()`, `frame_point()`, `_draw_tags()`, `_draw_rows()`, `_draw_wishes()`)
- Modify: `tests/test_tier2_groundwork.gd` (the kit: `STACK`, `clear_of_stack()`'s zone), `tests/test_tier5_groundwork.gd`

**Interfaces:**
- Consumes: `Hud.tag_layout()`, `frame_point()`, `tag_frame()`, `tag_point()`, `label_rect()`, `hint_rect()`, `wishes_top()`,
  `objective_rows()`, `wish_rows()`; `Descent.attach()`.
- Produces:
  - `Hud.STACK_PAD := 4.0`; `Hud.stack_rect() -> Rect2`; `Hud.objective_rect() -> Rect2`; `Hud.wishes_rect() -> Rect2`.
  - `Hud.tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2, keepout := Rect2()) -> Array`.
  - `Hud.frame_point(point: Vector2, frame: Rect2, keepout := Rect2()) -> Vector2`; `Hud._keepout_point(mid: Vector2, d: Vector2, keepout: Rect2) -> Vector2`.
  - `Kit.STACK := Rect2(0.0, 0.0, 240.0, 165.0)`; `Kit.clear_of_stack(g: Vector2, cam: Vector2, zone := DEAD) -> bool`.

- [ ] **Step 1: The kit's real depth.** First `grep -n "STACK" tests/test_tier2_groundwork.gd`. If M5 added `STACK` and a zone argument
  to `clear_of_stack()`, keep them as they are, skip the rest of this step and say so in the report (plan decision 271). Otherwise, in
  `tests/test_tier2_groundwork.gd`:
  - After `const DEAD := Rect2(0.0, 0.0, 240.0, 100.0)` add:

```gdscript
## The left HUD stack at its real depth (v0.11 M6, mission spec §7; M4's ruling): the objectives, the hint and three wishes' rows, about
## 240 x 165 px. M6's missions check their spots against it; DEAD stays for the older checks.
const STACK := Rect2(0.0, 0.0, 240.0, 165.0)
```

  - `clear_of_stack()` becomes:

```gdscript
## Ground point `g`, or its edge arrow, is clear of the left HUD stack with the camera on `cam` (v0.11 M3, controller ruling 7); v0.11
## M6: of `zone` -- DEAD by default, Kit.STACK for M6's missions.
static func clear_of_stack(g: Vector2, cam: Vector2, zone := DEAD) -> bool:
	return not zone.has_point(shown_at(g, cam))
```

  - In the file's header comment, after "shown_at(), clear_of_stack().", add ` v0.11 M6: STACK, the real stack's depth.`

- [ ] **Step 2: Write the failing test.** In `tests/test_tier5_groundwork.gd`:
  - In `run()`, after `_hunt_hooks(t)` add `_keepout_empty(t)`, `_keepout_under(t)`, `_keepout_slide(t)`, `_keepout_labels(t)`,
    `_keepout_stack(t)`.
  - At the end of the file add:

```gdscript
## The screen's middle, and the stack as a full night draws it, for the keepout's unit checks (v0.11 M6 tests).
const MID := Vector2(320.0, 180.0)
const FULL_STACK := Rect2(0.0, 0.0, 244.0, 169.0)


## Tags as the layout takes them (v0.11 M6 tests).
static func _tags(list: Array) -> Array[MapTag]:
	var out: Array[MapTag] = []
	out.assign(list)
	return out


## A person's tag whose diamond lands on `screen` with the camera at MID (v0.11 M6 tests).
static func _tag_at(screen: Vector2, label: String, edge: bool) -> MapTag:
	var g := Iso.screen_to_ground(screen + Vector2(0.0, MapTag.PERSON_LIFT) - MID)
	return MapTag.person(g, Color.RED, label, edge)


## A spread of tags over the screen and off it, half with edge arrows (v0.11 M6 tests).
static func _spread_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for k in 16:
		out.append(MapTag.person(Vector2(-16.0 + 2.2 * float(k), -12.0 + 1.6 * float(k)), Color.RED, "TAG %d" % k, k % 2 == 0))
	return out


## An empty keepout lays every tag out exactly as before (v0.11 M6, Task 3).
static func _keepout_empty(t) -> void:
	var xf := Transform2D(0.0, MID)
	var tags := _spread_tags()
	var before := Hud.tag_layout(tags, xf, Kit.VIEW)
	var now := Hud.tag_layout(tags, xf, Kit.VIEW, Rect2())
	var same := before.size() == now.size()
	for i in mini(before.size(), now.size()):
		same = same and String(before[i].mode) == String(now[i].mode) and before[i].arrow == now[i].arrow \
			and before[i].label == now[i].label and bool(before[i].show) == bool(now[i].show)
	var frame := Hud.tag_frame(Kit.VIEW)
	var far := Vector2(-400.0, -100.0)
	t.check(same and Hud.frame_point(far, frame) == Hud.frame_point(far, frame, Rect2()),
		"an empty keepout: every tag and arrow where it was")


## An edge tag whose diamond the stack would hide becomes an arrow on the stack's border, its label beside it outside (v0.11 M6); a tag
## without an edge keeps its diamond under the stack but loses its label.
static func _keepout_under(t) -> void:
	var xf := Transform2D(0.0, MID)
	var lay := Hud.tag_layout(_tags([_tag_at(Vector2(100.0, 130.0), "UNDER", true)]), xf, Kit.VIEW, FULL_STACK)
	var tip: Vector2 = lay[0].arrow
	var on_border := is_equal_approx(tip.x, FULL_STACK.end.x) or is_equal_approx(tip.y, FULL_STACK.end.y)
	t.check(String(lay[0].mode) == "arrow" and on_border and not FULL_STACK.has_point(tip) and bool(lay[0].show)
		and not (lay[0].label as Rect2).intersects(FULL_STACK), "an edge tag under the stack: an arrow on its border (%s), its label outside" % tip)
	var plain := Hud.tag_layout(_tags([_tag_at(Vector2(100.0, 130.0), "PLAIN", false)]), xf, Kit.VIEW, FULL_STACK)
	t.check(String(plain[0].mode) == "map" and not bool(plain[0].show), "a tag without an edge keeps its diamond under the stack, not its label")


## An arrow bound for the frame's left or top edge inside the stack's span slides to where the same line meets the stack's border
## (v0.11 M6).
static func _keepout_slide(t) -> void:
	var frame := Hud.tag_frame(Kit.VIEW)
	var far := Vector2(-400.0, -100.0)
	var old := Hud.frame_point(far, frame)
	var tip := Hud.frame_point(far, frame, FULL_STACK)
	var mid := frame.get_center()
	var cross := (tip - mid).cross(far - mid)
	t.check(FULL_STACK.grow(0.5).has_point(old) and not FULL_STACK.has_point(tip) and absf(cross) < 1.0
		and (is_equal_approx(tip.x, FULL_STACK.end.x) or is_equal_approx(tip.y, FULL_STACK.end.y)),
		"an arrow that fell inside the stack's span (%s) now sits on its border on the same line (%s)" % [old, tip])
	var east := Vector2(900.0, 200.0)
	t.check(Hud.frame_point(east, frame, FULL_STACK) == Hud.frame_point(east, frame), "an arrow nowhere near the stack is where it was")


## No label plate is drawn over the stack: it counts as a label already placed (v0.11 M6).
static func _keepout_labels(t) -> void:
	var xf := Transform2D(0.0, MID)
	var clear := true
	var shown := 0
	for e: Dictionary in Hud.tag_layout(_spread_tags(), xf, Kit.VIEW, FULL_STACK):
		if bool(e.show):
			shown += 1
			clear = clear and not (e.label as Rect2).intersects(FULL_STACK)
	t.check(clear and shown > 0, "no shown label plate overlaps the stack (%d shown)" % shown)


## Hud.stack_rect() is the live stack as drawn (v0.11 M6): from the corner to the widest plate's right edge and the lowest's bottom,
## STACK_PAD beyond; empty during the tour's caption. A Tier 3 board night: three wishes' rows. The kit's STACK is the real depth.
static func _keepout_stack(t) -> void:
	var def := TierBook.board("crowns_bread")
	var s := Kit.world(def)
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	var hud := Hud.new().setup(s.rules, s.crowd, s.town, null)
	var r := hud.stack_rect()
	var hint := hud.hint_rect()
	var wishes := hud.wishes_rect()
	var rows := hud.objective_rect()
	var wide := maxf(rows.end.x, maxf(hint.end.x, wishes.end.x))
	t.check(r.position == Vector2.ZERO and is_equal_approx(r.end.x, wide + Hud.STACK_PAD) and is_equal_approx(r.end.y, wishes.end.y + Hud.STACK_PAD)
		and descent.wishes.size() == 3 and r.end.y > Kit.DEAD.end.y,
		"the stack: the objectives, the hint and three wishes' rows, padded (%s)" % r)
	t.check(Kit.STACK.size.y >= r.size.y - 12.0 and Kit.STACK.size.y > Kit.DEAD.size.y, "the kit's STACK is the real depth, deeper than DEAD")
	hud.set_caption("The tour")
	t.check(not hud.stack_rect().has_area(), "empty during the tour's caption")
	hud.free()
	descent.release()
	Kit.done(s)
```

- [ ] **Step 3: Run the tests to verify they fail.** Expected: a parse error (no `STACK_PAD`, `stack_rect()`, keepout arguments).

- [ ] **Step 4: The keepout.** In `src/game/ui/hud.gd`:
  - After `const TAG_TOP := 78.0` add:

```gdscript
## The keepout's margin round the left HUD stack (v0.11 M6, mission spec §6.4): screen pixels beyond its right and bottom edges.
const STACK_PAD := 4.0
```

  - After `hint_rect()` add:

```gdscript
## The objective plate as drawn (v0.11 M6, factored out of _draw_rows() so the keepout reads the same rectangle): a scored mission's
## OBJECTIVE_PANEL, else the rows' plate, Rect2() with no rows.
func objective_rect() -> Rect2:
	if _rules.mission.scored:
		return OBJECTIVE_PANEL
	var rows := objective_rows()
	if rows.is_empty():
		return Rect2()
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL) + (12.0 if String(row[1]) != "" else 0.0))
	return Rect2(2.0, 2.0, wide + 10.0, 5.0 + ROW_H * float(rows.size()))


## The wishes' plate as drawn (v0.11 M6, factored out of _draw_wishes()): Rect2() with no rows.
func wishes_rect() -> Rect2:
	var rows := wish_rows()
	if rows.is_empty():
		return Rect2()
	var wide := 0.0
	for row: Array in rows:
		wide = maxf(wide, UiTheme.width(String(row[0]), UiTheme.SIZE_SMALL))
	return Rect2(2.0, wishes_top(), wide + 22.0, 5.0 + ROW_H * float(rows.size()))


## The left HUD stack as drawn this frame (v0.11 M6, mission spec §6.4): from the screen's corner to the right edge of the widest of the
## objective plate, the hint plate and the wishes' plate, and down to the bottom of the lowest, STACK_PAD beyond both. Empty while none
## is drawn: during the tour's caption, and once the night is over. The tags' keepout (_draw_tags()).
func stack_rect() -> Rect2:
	if _rules == null or _rules.mission == null or _rules.finished or _caption != "":
		return Rect2()
	var right := 0.0
	var bottom := 0.0
	for r: Rect2 in [objective_rect(), hint_rect(), wishes_rect()]:
		if r.has_area():
			right = maxf(right, r.end.x)
			bottom = maxf(bottom, r.end.y)
	if right <= 0.0:
		return Rect2()
	return Rect2(0.0, 0.0, right + STACK_PAD, bottom + STACK_PAD)
```

  - In `_draw_tags()`, `_layout = tag_layout(all_tags(), xf, _view())` becomes `_layout = tag_layout(all_tags(), xf, _view(), stack_rect())`,
    and its doc gains: `## v0.11 M6: the live stack is the layout's keepout (stack_rect()), so no tag, label or arrow hides under it.`
  - Replace `tag_layout()` and `frame_point()` with:

```gdscript
## Where each tag goes this frame (v0.10 M6, spec §2.3), in the tags' order, as {tag, c, mode, arrow, dir, label, show}.
## - `c`: its diamond's centre on screen.
## - `mode`: "map" for its diamond where it is -- anywhere inside the screen for a tag without `edge`, and inside
##   tag_frame() for one with it; "arrow" for a tag with `edge` outside the frame (off screen, under the clock, or under
##   the slot row), an arrow on the frame's edge (`arrow` is its tip and `dir` its heading); "" for a tag without `edge`
##   off screen (only its outline may show).
## - `label`: its label's plate.
## - `show`: the label is drawn. Not when it has none, nor when its plate would overlap one placed before it: a director
##   lists its most important tags first, so a crowded view keeps their labels.
## A tag at no point is left out.
## v0.11 M6 (mission spec §6.4) `keepout`, the left HUD stack: empty, the layout of old exactly. Else (1) a tag with `edge` whose diamond
## lies inside it becomes an arrow on its border, where the line from the frame's centre to the diamond crosses it, its label beside the
## arrow toward the centre; (2) an arrow frame_point() would put on the frame's edge inside it slides to its border the same way; (3) it
## counts as a label already placed, so no plate is drawn over it; (4) a tag without `edge` inside it keeps its diamond, not its label.
static func tag_layout(tags: Array[MapTag], xf: Transform2D, view: Vector2, keepout := Rect2()) -> Array:
	var out := []
	var placed: Array[Rect2] = []
	var frame := tag_frame(view)
	var keep := keepout.has_area()
	if keep:
		placed.append(keepout)
	for t in tags:
		if not t.valid():
			continue
		var c := tag_point(t, xf)
		var e := {"tag": t, "c": c, "mode": "", "arrow": Vector2.INF, "dir": Vector2.ZERO, "label": Rect2(), "show": false}
		var hidden := keep and t.edge and keepout.has_point(c)
		if (frame.has_point(c) and not hidden) or (not t.edge and Rect2(Vector2.ZERO, view).has_point(c)):
			e.mode = "map"
			e.label = label_rect(t.label, c - Vector2(0.0, t.size + LABEL_GAP + PLATE_H * 0.5), view)
		elif t.edge:
			var tip := frame_point(c, frame, keepout)
			var d := (c - frame.get_center()).normalized()
			var reach := ARROW_REACH + absf(d.x) * plate_size(t.label).x * 0.5 \
				+ absf(d.y) * PLATE_H * 0.5
			e.mode = "arrow"
			e.arrow = tip
			e.dir = d
			e.label = label_rect(t.label, tip - d * reach, view)
		if String(e.mode) != "" and t.label != "":
			var r: Rect2 = e.label
			var clear := true
			for p in placed:
				clear = clear and not r.intersects(p)
			if clear:
				placed.append(r)
				e.show = true
		out.append(e)
	return out


## Where the arrow for a point outside `frame` sits (v0.10 M6): on the line from the frame's centre to it, on the frame's edge. v0.11
## M6: one that would land inside `keepout` -- or a point inside it -- sits where that line first meets the keepout's border instead.
static func frame_point(point: Vector2, frame: Rect2, keepout := Rect2()) -> Vector2:
	var mid := frame.get_center()
	var d := point - mid
	var half := frame.size * 0.5
	var k := 1.0
	if absf(d.x) > half.x:
		k = half.x / absf(d.x)
	if absf(d.y) * k > half.y:
		k = half.y / absf(d.y)
	var tip := mid + d * k
	if keepout.has_area() and (keepout.grow(0.5).has_point(tip) or keepout.has_point(point)):
		return _keepout_point(mid, d, keepout)
	return tip


## Where the line from `mid` along `d` first meets `keepout`'s border (v0.11 M6): its right edge or its bottom, whichever comes first --
## the stack sits in the screen's top-left corner, the frame's centre below and right of it; `mid` itself if it never does.
static func _keepout_point(mid: Vector2, d: Vector2, keepout: Rect2) -> Vector2:
	var best := INF
	if d.x < 0.0:
		var k := (keepout.end.x - mid.x) / d.x
		var y := mid.y + d.y * k
		if k > 0.0 and y >= keepout.position.y - 0.01 and y <= keepout.end.y + 0.01:
			best = minf(best, k)
	if d.y < 0.0:
		var k := (keepout.end.y - mid.y) / d.y
		var x := mid.x + d.x * k
		if k > 0.0 and x >= keepout.position.x - 0.01 and x <= keepout.end.x + 0.01:
			best = minf(best, k)
	return mid + d * best if best != INF else mid
```

  - In `_draw_rows()`, replace the lines from `var wide := 0.0` through
    `draw_rect(Rect2(2.0, 2.0, wide + 10.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)` with
    `draw_rect(objective_rect(), UiTheme.COL_PANEL)` (the rows and marks after it unchanged).
  - In `_draw_wishes()`, replace the lines from `var wide := 0.0` through
    `draw_rect(Rect2(2.0, top, wide + 22.0, 5.0 + ROW_H * float(rows.size())), UiTheme.COL_PANEL)` with:

```gdscript
	var top := wishes_top()
	draw_rect(wishes_rect(), UiTheme.COL_PANEL)
```

    (the rows after it unchanged; they still read `top`).

- [ ] **Step 5: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 11.
  Every existing tag-layout check (`test_map_tags`, `test_informer`'s and `test_prisoner`'s `Hud.tag_layout()` calls, `test_board_tags`,
  `test_descend_hud`, `test_hud`) passes unchanged: none passes a keepout. If one that pins a tag's mode at a mission's camera changes,
  name it in the report (none should: they call the layout without the keepout).

- [ ] **Step 6: Look at it.** Take `--show=crowns_bread`, `--show=informer` and `--show=spoiled_harvest` (their board nights, three, two and
  two wishes). Read each photo: no tag label or arrow under the left stack; an arrow that used to sit in the stack's corner sits on its
  right or bottom border with its label beside it. Write one line per photo in the report. Change nothing for a photo here (Task 10
  retakes them for the notes).

- [ ] **Step 7: The Reference check, and FLOW.** Expected: every value unchanged (tags are in no checksum; no camera moved); FLOW 113/0,
  alone.

- [ ] **Step 8: Commit.**

```bash
git add src/game/ui/hud.gd tests/test_tier2_groundwork.gd tests/test_tier5_groundwork.gd
git commit -m "feat: the HUD's keepout -- map tags and edge arrows keep off the live left stack in every mission (v0.11 M6)" -m "<the halves' counts; the three photos judged; the Reference check exact; FLOW 113/0 alone; whether Kit.STACK was M5's>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Tier 5's frame and plumbing

**Files:**
- Modify: `src/game/mission/mission_director.gd` (new `stages_done()`, `lost_reason()`, `hud_line()`)
- Create: `src/game/mission/stages_objective.gd`
- Modify: `src/game/mission/raze_director.gd` (new `_spoil_for()`; `_judge_targets()`)
- Modify: `src/game/mission/searchlight.gd` (new `hunt`, `hold`, `_noise_age`; `hear()`, `step()`)
- Modify: `src/game/mission/mission_book.gd` (three ids, new `_tier5()`)
- Modify: `src/game/descend/tier_book.gd` (`_with_gaze()`, `_with_gaze_for_night()`, new `_has_gaze()`)
- Modify: `tests/test_tier5_groundwork.gd`

**Interfaces:**
- Consumes: `HarvestDirector`, `RazeDirector`, `Searchlight`, `GazeMeter`, `GazeObjective`, `Descent.attach()`, `TierBook.board()`.
- Produces:
  - `MissionDirector.stages_done() -> bool`, `lost_reason() -> String`, `hud_line() -> String` (virtual, false / "" / "").
  - `StagesObjective._init(text := "Finish the night", done := "stages")`.
  - `RazeDirector._spoil_for(s: Structure) -> float` (virtual; `spoil_seconds`).
  - `Searchlight.hunt := false`, `Searchlight.hold := INF`.
  - `MissionBook.LANTERN_EYE`, `EXODUS`, `HEART_OF_FAITH`; `MissionBook._tier5(id: String, name: String, brief: PackedStringArray) -> MissionDef`.
  - `TierBook._has_gaze(list: Array[Objective]) -> bool`.

- [ ] **Step 1: Write the failing test.** In `tests/test_tier5_groundwork.gd`:
  - After the `Borrowed` class add:

```gdscript
## A director whose stages, loss and HUD line are set by hand (v0.11 M6 tests).
class Staged:
	extends MissionDirector
	var done := false
	var why := ""
	var line := ""

	func stages_done() -> bool:
		return done

	func lost_reason() -> String:
		return why

	func hud_line() -> String:
		return line


## A Raze of one house whose burning spoils it in 2 s, whatever spoil_seconds says (v0.11 M6 tests).
class QuickRaze:
	extends RazeDirector

	func _begin() -> void:
		targets.append(_house_near(Vector2(0.0, 8.0)))
		spoil_seconds = 50.0

	func _spoil_for(_s: Structure) -> float:
		return 2.0


## A director that keeps a Gaze of its own (v0.11 M6 tests, Decision 208).
class OwnGaze:
	extends MissionDirector

	func _begin() -> void:
		gaze = GazeMeter.new()
```

  - In `run()`, after `_keepout_stack(t)` add `_frame5(t)`, `_stages(t)`, `_spoil_default(t)`, `_searchlight_hooks(t)`, `_one_gaze(t)`,
    `_own_gaze(t)`.
  - At the end of the file add:

```gdscript
## Tier 5's frame (v0.11 M6, Decision 207).
static func _frame5(t) -> void:
	var m := MissionBook._tier5("x", "X", PackedStringArray(["a", "b"]))
	t.check(m.tier == 5 and m.slots == 6 and m.dp_capacity == 16 and is_equal_approx(m.clock, 420.0) and m.profile == ""
		and m.tier_floor == 4 and not m.chooses_difficulty()
		and m.response_profile(ResponseProfile.Tier.UNPREPARED).tier_name() == "God-Resistant" and m.intro_banner == "X"
		and m.bonuses().is_empty() and m.pool.is_empty() and is_equal_approx(m.stretch, 1.0),
		"a Tier 5 mission's numbers: 7:00, 6 / 16, a God-Resistant town whatever is chosen, no bonuses")
	t.check(MissionBook.LANTERN_EYE == "lantern_eye" and MissionBook.EXODUS == "exodus" and MissionBook.HEART_OF_FAITH == "heart_of_faith",
		"Ascendance's three new ids")


## StagesObjective (v0.11 M6, Decision 255): its label and win reason given; the director's stages, loss and line.
static func _stages(t) -> void:
	var s := Kit.world(MissionBook.warning(), Staged.new())
	var d: Staged = s.d
	var o := StagesObjective.new("Put out the flame", "heart")
	t.check(o.label == "Put out the flame" and o.reason == "heart" and o.check(s.rules) == Objective.Status.PENDING
		and o.hud_text(s.rules) == "Put out the flame" and StagesObjective.new().reason == "stages",
		"StagesObjective: its words given; pending; its label on the HUD while the director has no line")
	d.line = "Kill Odran"
	d.why = "kindled"
	t.check(o.hud_text(s.rules) == "Kill Odran" and o.check(s.rules) == Objective.Status.FAILED and o.reason == "kindled",
		"the director's line in its place; its loss fails it with its reason")
	d.why = ""
	d.done = true
	var won := StagesObjective.new("Put out the flame", "heart")
	t.check(won.check(s.rules) == Objective.Status.DONE and won.reason == "heart", "the stages done: won, with the win's reason")
	var base := MissionDirector.new()
	t.check(not base.stages_done() and base.lost_reason() == "" and base.hud_line() == "", "the base director: no stages, no loss, no line")
	Kit.done(s)


## RazeDirector._spoil_for() (v0.11 M6, Decision 256): spoil_seconds by default; a subclass's own seconds raze its target.
static func _spoil_default(t) -> void:
	var s := Kit.world(MissionBook.spoiled_harvest())
	var d: HarvestDirector = s.d
	t.check(is_equal_approx(d._spoil_for(d.targets[0]), d.spoil_seconds), "_spoil_for() is spoil_seconds by default (Spoiled Harvest)")
	Kit.done(s)
	var q := QuickRaze.new()
	var w := Kit.world(MissionBook.spoiled_harvest(), q)
	var house := q.targets[0]
	(w.crowd as Crowd).fires.ignite(house, 1.0)
	Kit.run_for(w, 2.5)
	t.check(q.razed(house) and q.burned(house) >= 2.0, "a subclass's _spoil_for() of 2 s razes its target after 2 s alight, not 50")
	Kit.done(w)


## The Searchlight's hunt and hold (v0.11 M6, Decision 244): by default a noise is searched only in the clock's last seconds and held
## for good; hunting, a noise draws the nearest beam at once, held `hold` seconds, and a newer noise draws one again.
static func _searchlight_hooks(t) -> void:
	var l := Searchlight.new().setup(Vector2.ZERO)
	t.check(not l.hunt and l.hold == INF, "the defaults: no hunt, held for good")
	l.light(Searchlight.SECOND_AFTER)
	l.hear(Vector2(10.0, 0.0))
	l.step(0.1, 300.0)
	var early := l.searching
	l.step(0.1, Searchlight.SEARCH_LAST - 1.0)
	var late := l.searching
	for i in 100:
		l.step(0.1, Searchlight.SEARCH_LAST - 2.0)
	t.check(not early and late and l.searching, "by default: searched only in the last seconds, and still held 10 s on")
	var h := Searchlight.new().setup(Vector2.ZERO)
	h.hunt = true
	h.hold = 8.0
	h.light(Searchlight.SECOND_AFTER)
	h.hear(Vector2(10.0, 0.0))
	h.step(0.1, 300.0)
	var beam := h.search_beam
	t.check(h.searching and beam >= 0, "hunting: a noise draws the nearest lit beam at once")
	for i in 30:
		h.step(0.1, 300.0)
	t.check(h.aim(beam).distance_to(Vector2(10.0, 0.0)) < 1.0, "the beam reaches the noise")
	for i in 60:
		h.step(0.1, 300.0)
	t.check(not h.searching and h.search_beam == -1, "after `hold` seconds the beam goes back to its sweep")
	h.hear(Vector2(10.0, 0.0))
	h.step(0.1, 300.0)
	t.check(h.searching, "a newer noise draws a beam again")


## TierBook adds the Gaze objective only to a list that has none (v0.11 M6, Decision 211): the ★ missions as before.
static func _one_gaze(t) -> void:
	var made := func() -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new(), GazeObjective.new()]
		return out
	var list: Array[Objective] = []
	list.assign(TierBook._with_gaze(made).call())
	var gazes := 0
	for o in list:
		gazes += 1 if o is GazeObjective else 0
	var lj := TierBook.board("last_judgement").objectives()
	var lj_gazes := 0
	for o in lj:
		lj_gazes += 1 if o is GazeObjective else 0
	t.check(list.size() == 2 and gazes == 1 and lj_gazes == 1 and lj.back() is GazeObjective,
		"a list with its own Gaze gets none added; Last Judgement's board version still ends with its one")


## A Tier 5 director that keeps its own Gaze keeps it (v0.11 M6, Decision 208): the night's goes only to one with none.
static func _own_gaze(t) -> void:
	var def := TierBook.board("last_judgement")
	var s := Kit.world(def, OwnGaze.new())
	var mine: GazeMeter = (s.d as MissionDirector).gaze
	var descent := Descent.new().setup(def, 7)
	descent.attach(s.rules, s.d)
	t.check(mine != null and (s.d as MissionDirector).gaze == mine and descent.gaze == null and not (mine is Descent.TierGaze),
		"Descent.attach() leaves a director's own Gaze")
	descent.release()
	Kit.done(s)
```

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then the halves. Expected: a parse error (no `StagesObjective`,
  `_tier5()`, `_spoil_for()`, `hunt`).

- [ ] **Step 3: The director virtuals.** In `src/game/mission/mission_director.gd`, after `stars_total()` add:

```gdscript
## Virtual (v0.11 M6, mission spec §6.5): the night's stages are done -- StagesObjective's win (The Heart of Faith: the flame out and its
## High Priest dead). False by default.
func stages_done() -> bool:
	return false


## Virtual (v0.11 M6): why the night is lost now, "" while it is not. RazeDirector, EscortDirector, HuntDirector, AssassinateDirector
## and their subclasses override it as before; named here so StagesObjective reads any director (plan decision 272).
func lost_reason() -> String:
	return ""


## Virtual (v0.11 M6): the HUD's line for the main objective in place of its own, "" for its own. Named here for StagesObjective, as
## lost_reason() is.
func hud_line() -> String:
	return ""
```

- [ ] **Step 4: StagesObjective.** Create `src/game/mission/stages_objective.gd`:

```gdscript
class_name StagesObjective
extends Objective
## A night of stages' main objective (v0.11 M6, mission spec §6.5; generic, M2 ruling 61): DONE the moment its director's stages are
## done (MissionDirector.stages_done(): The Heart of Faith's flame out and its High Priest dead), with the win's reason; FAILED with the
## director's own loss (MissionDirector.lost_reason(): The Heart's "blessed" and "kindled") when it has one. Its HUD row is the
## director's line (MissionDirector.hud_line()), else its label.

## The reason a win gives (v0.11 M6).
var _done := ""


## The label, and the win's reason (v0.11 M6).
func _init(text := "Finish the night", done := "stages") -> void:
	label = text
	_done = done
	reason = done


## DONE once the director's stages are done; FAILED once it names a loss (v0.11 M6).
func check(rules: Rules) -> Status:
	var d: MissionDirector = rules.director if rules != null else null
	if d == null:
		return Status.PENDING
	if d.stages_done():
		reason = _done
		return Status.DONE
	var lost := d.lost_reason()
	if lost != "":
		reason = lost
		return Status.FAILED
	return Status.PENDING


## The director's line, else the label (v0.11 M6).
func hud_text(rules: Rules) -> String:
	var d: MissionDirector = rules.director if rules != null else null
	var line := d.hud_line() if d != null else ""
	return line if line != "" else label
```

- [ ] **Step 5: `_spoil_for()`.** In `src/game/mission/raze_director.gd`:
  - After `hud_line()` add:

```gdscript
## Virtual (v0.11 M6, mission spec §6.5): the seconds of burning, in all, that raze `s` -- `spoil_seconds` by default. The Heart of
## Faith's oil-house 12 and its Temple 20.
func _spoil_for(_s: Structure) -> float:
	return spoil_seconds
```

  - In `_judge_targets()`, replace

```gdscript
			_burned[s] = burned(s) + delta
			if spoil_seconds > 0.0 and burned(s) >= spoil_seconds:
				_raze(s)
```

    with

```gdscript
			_burned[s] = burned(s) + delta
			var spoil := _spoil_for(s)
			if spoil > 0.0 and burned(s) >= spoil:
				_raze(s)
```

    and its doc's last clause `...razed once it has burned \`spoil_seconds\` in all.` becomes `...razed once it has burned _spoil_for() in all (v0.11 M6).`

- [ ] **Step 6: The Searchlight's hooks.** In `src/game/mission/searchlight.gd`:
  - The class doc gains: `## v0.11 M6: \`hunt\` searches every heard noise at once, not only in the clock's last seconds, and \`hold\` sends a beam back to`
    `## its sweep that long after its noise (The Lantern's Eye); the defaults are The Vigil Flame's and The Relic Run's light.`
  - After `var _searched := Vector2.INF` add:

```gdscript
## v0.11 M6 (mission spec §6.3): while true, every noise heard draws the nearest lit beam at once, not only in the clock's last
## SEARCH_LAST seconds (The Lantern's Eye, while a mirror stands). False by default.
var hunt := false
## v0.11 M6: how long a beam stays at its noise before it goes back to its sweep; INF (the default) stays until a newer noise.
var hold := INF
## Seconds since the latest noise was heard (v0.11 M6, for `hold`).
var _noise_age := 0.0
```

  - `hear()` becomes:

```gdscript
## A noise at `at` (a cast, a death): the latest is where a searching beam stops. v0.11 M6: its age starts again.
func hear(at: Vector2) -> void:
	noise = at
	_noise_age = 0.0
```

  - In `step()`, after `age += delta` add `_noise_age += delta`, and replace
    `searching = time_left <= SEARCH_LAST and noise != Vector2.INF` with
    `searching = (hunt or time_left <= SEARCH_LAST) and noise != Vector2.INF and _noise_age < hold  # v0.11 M6: hunt, hold`.

- [ ] **Step 7: Tier 5's frame.** In `src/game/mission/mission_book.gd`:
  - After M5's four Tier 4 ids add:

```gdscript
## The new Tier 5 missions (v0.11 M6, mission spec §1-§3), built by tier_missions() at Tier 5's numbers.
const LANTERN_EYE := "lantern_eye"
const EXODUS := "exodus"
const HEART_OF_FAITH := "heart_of_faith"
```

  - After `_tier4()` add:

```gdscript
## A Tier 5 (Ascendance) mission's frame (v0.11 M6, mission spec §0, Decision 207): a God-Resistant town -- tier_floor 4 and no profile,
## so a scripted run meets the board's town -- 6 slots and 16 DP, a 7:00 clock, no bonuses, every power allowed unless the mission
## narrows its pool.
static func _tier5(id: String, name: String, brief: PackedStringArray) -> MissionDef:
	var m := MissionDef.new()
	m.id = id
	m.name = name
	m.tier = 5
	m.brief = brief
	m.slots = 6
	m.dp_capacity = 16
	m.clock = 420.0
	m.tier_floor = 4
	m.intro_banner = name.to_upper()
	return m
```

- [ ] **Step 8: One Gaze objective.** In `src/game/descend/tier_book.gd`, replace `_with_gaze()` and `_with_gaze_for_night()` with:

```gdscript
## `make`'s objectives with a GazeObjective after them, unless they have one already (v0.11 M6, Decision 211: each new Tier 5 mission
## lists its own; Last Judgement and The Long Night list none, so theirs are as before).
static func _with_gaze(make: Callable) -> Callable:
	return func() -> Array[Objective]:
		var out: Array[Objective] = []
		if make.is_valid():
			out.assign(make.call())
		if not _has_gaze(out):
			out.append(GazeObjective.new())
		return out


## As _with_gaze(), for an act's objectives made for the night (v0.11 M6).
static func _with_gaze_for_night(make: Callable) -> Callable:
	return func(n: NightState) -> Array[Objective]:
		var out: Array[Objective] = []
		out.assign(make.call(n))
		if not _has_gaze(out):
			out.append(GazeObjective.new())
		return out


## `list` already holds a GazeObjective (v0.11 M6).
static func _has_gaze(list: Array[Objective]) -> bool:
	for o in list:
		if o is GazeObjective:
			return true
	return false
```

- [ ] **Step 9: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 16.
  `test_descent`, `test_board_missions`, `test_vigil_flame`, M5's `test_relic_run` and `test_armoury` unchanged.

- [ ] **Step 10: The Reference check, and FLOW.** Expected: every value unchanged: **Spoiled Harvest's six** (refs24 `harvest`), **The
  Crown's Bread's six** and **The Armoury's six** prove `_spoil_for()`; **The Relic Run's six**, The Vigil Flame's outcome and its play
  line prove the Searchlight's hooks; FLOW 113/0, alone.

- [ ] **Step 11: Commit.**

```bash
git add src/game/mission/mission_director.gd src/game/mission/stages_objective.gd src/game/mission/stages_objective.gd.uid src/game/mission/raze_director.gd src/game/mission/searchlight.gd src/game/mission/mission_book.gd src/game/descend/tier_book.gd tests/test_tier5_groundwork.gd
git commit -m "feat: Tier 5's frame -- StagesObjective, a Raze's own spoil, a hunting Searchlight, one Gaze objective (v0.11 M6)" -m "<the halves' counts; the Reference check exact (Spoiled Harvest, the Crown's Bread, the Armoury, the Relic Run, the Vigil Flame); FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: The Lantern's Eye (Anchors + Hunt)

**Files:**
- Create: `src/game/mission/lantern_eye_director.gd`
- Modify: `src/game/mission/mission_book.gd` (`lantern_eye()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd` (the `lantern_eye` lines), `src/game/ui/results_screen.gd` (`ACT_TITLES`)
- Modify: `tools/dev/behaviour_check.gd` (`--scenario=eye`, `_eye()`, `_eye_act()`, `_eye_lit()`, `_eye_clear()`, `_doom_unseen()`)
- Modify: the mission spec's §1 (spec sync)
- Create: `tests/test_lantern_eye.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: Task 2's `HuntDirector.shield_hits`, `_unguarded_blow()`; Task 4's `Searchlight.hunt` / `hold`, `_tier5()`; the Hunt type
  (`steps`, `HuntStep`, `Guard`, `_step()`, `_raise()`, `_break()`, `_release()`, `_keep_held()`, `_in_use()`, `_party_post()`,
  `_guarding()`, `current()`, `next_step()`, `due_in()`, `guarded()`, `party_on()`, `relief_walking()`, `broken()`, `broken_all()`,
  `standard()`, `found`, `_clock`, `TICK`, `SHAKE`, `MARK_*`); `MissionDirector._hold_all()`, `_tower`-free helpers; `SearchlightFx`;
  behaviour_check's `_scripted()`, `_slots()`, `_slot_ready()`, `_prisoner_away()`.
- Produces: `LanternEyeDirector` with `towers: Array[Structure]`, `feet: Array[Vector2]`, `glass: Array[float]`, `shattered: Array[bool]`,
  `drain_left: Array[float]`, `hang_work: Array[float]`, `wrights: Array` (per step, `HuntDirector.Guard` records), `searchlight`,
  `last_cast`, `eye_open`, `seen_casts`; `eye_left() -> float`, `outer_face(i) -> Vector2`, `along(i) -> Vector2`,
  `shattered_now() -> int`, `_working(w: HuntDirector.Guard) -> bool`, `_shatter(i)`, `_rehang(i)`, `_gone(i)`, `_hunting() -> bool`,
  `_all_standing() -> bool`, `_tower_near(spot: Vector2, exclude: Array) -> Structure`; the constants of mission spec §1;
  `MissionBook.lantern_eye()`; behaviour_check's `_doom_unseen(crowd: Crowd, at: Vector2, spare: Array = []) -> bool` (Tasks 6-7 reuse it).

- [ ] **Step 1: Write the failing test.** Create `tests/test_lantern_eye.gd`:

```gdscript
extends RefCounted
## v0.11 M6 The Lantern's Eye (mission spec §1, LanternEyeDirector on the Hunt type): three mirror towers -- the standing wall towers
## nearest the north, east and south-west points, never the bell tower, a wish's or another's -- each with a party of three watchmen
## on posts along its town-side face and two wrights waiting inside; the mirrors go up on the chain (0:50, then each at its time or
## CHAIN after the one before is gone for good); a guarded mirror only shakes its tower, an open one takes two Smites on its glass and
## shatters; its wrights come out and hang a new glass in 10 s of one wright's work, or it is gone for good after DRAIN; the
## Searchlight lit from 0:00 hunts the god's casts only while a mirror stands, and a cast in a lit pool adds 20 to the Gaze; all three
## standing together for EYE_OPENS loses. The town's regroup and evacuation pass everyone by, at the start and mid-mission; freed
## bodies are borne; the towers' own filters come back at teardown; the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_not_yet(t)
	_guarded(t)
	_shatter(t)
	_rehang(t)
	_gone(t)
	_light(t)
	_seen_cast(t)
	_seen_death(t)
	_eye(t)
	_won(t)
	_relief(t)
	_reserved_tower(t)
	_evacuated(t)
	_tagged(t)
	_teardown(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.lantern_eye())


## Step `i`'s guards moved well off the tower (v0.11 M6 tests): off guard, still alive.
static func _clear(d: LanternEyeDirector, i: int) -> void:
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man):
			Kit.arrive(g.man as Person, g.post + (g.post - d.towers[i].center()).normalized() * 6.0)


## A Smite on tower `i`'s outer face (v0.11 M6 tests).
static func _smite(s: Dictionary, d: LanternEyeDirector, i: int) -> void:
	(s.env as EnvironmentField).damage_radius(d.outer_face(i), SmiteFx.HIT_R, SmiteFx.DAMAGE, &"smite")


static func _setup(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var ok := d.towers.size() == 3 and d.steps.size() == 3 and d.standards.is_empty() and d.wrights.size() == 3
	var people := {}
	for i in 3:
		var tw := d.towers[i]
		ok = ok and RuinWish.fits(tw, "tower") and tw.damage_filter.is_valid() and d.steps[i].party.size() == LanternEyeDirector.PARTY
		for j in range(i + 1, 3):
			var gap := tw.center().distance_to(d.towers[j].center())
			ok = ok and gap >= 20.0 and gap <= 35.0
		for k in d.steps[i].party.size():
			var g: HuntDirector.Guard = d.steps[i].party[k]
			var p := g.man as Person
			ok = ok and p.mind == Person.Mind.DUTY and p.profile.role == CitizenProfile.Role.WATCHMAN and not p.soldier
			people[p] = true
			for m in range(k + 1, d.steps[i].party.size()):
				ok = ok and g.post.distance_to((d.steps[i].party[m] as HuntDirector.Guard).post) > Crowd.DOOM_WITNESS
		ok = ok and d.party_on(i).size() == LanternEyeDirector.PARTY
		for w: HuntDirector.Guard in d.wrights[i]:
			var p := w.man as Person
			ok = ok and p.inside and p.mind == Person.Mind.DUTY and p.profile.role == CitizenProfile.Role.ENGINEER
			people[p] = true
		var a: HuntDirector.Guard = d.wrights[i][0]
		var b: HuntDirector.Guard = d.wrights[i][1]
		ok = ok and a.post.distance_to(b.post) > Crowd.DOOM_WITNESS
	t.check(ok and people.size() == 15, "three towers 20-35 apart, stone tonight; three watchmen on guard at each, one witness apart; two wrights inside each; fifteen lay citizens")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["step_0", "step_1", "step_2"] and d.searchlight.on and d.searchlight.beams() == 2 and d.searchlight.hold == LanternEyeDirector.HOLD
		and not d.searchlight.hunt and d.gaze != null and not (d.gaze is Descent.TierGaze),
		"the strip: three mirrors; the light lit, both beams, quiet; its own Gaze (%s)" % [ids])
	var cam := LanternEyeDirector.CAMERA_AT
	var clear := Kit.clear_of_stack(LanternEyeDirector.SPIRE, cam, Kit.STACK)
	for i in 3:
		clear = clear and Kit.clear_of_stack(d.feet[i], cam, Kit.STACK)
	t.check(clear, "the camera keeps the spire and the three towers (or their arrows) clear of the real HUD stack")
	var m := MissionBook.lantern_eye()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["eye_blind", "gaze", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "whisper", "wisp", "heaven"] and MissionBook.get_mission("lantern_eye").id == "lantern_eye",
		"the mission: Tier 5's numbers; the Eye blind, the Gaze, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := true
	for i in 3:
		for g: HuntDirector.Guard in d.steps[i].party:
			held = held and (g.man as Person).mind == Person.Mind.DUTY
		for w: HuntDirector.Guard in d.wrights[i]:
			held = held and (w.man as Person).inside
	t.check(held, "the town's regroup and evacuation pass the parties by; the wrights stay inside (review focus 2)")
	Kit.done(s)


static func _not_yet(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	_clear(d, 0)
	_smite(s, d, 0)
	var tw := d.towers[0]
	t.check(not d.steps[0].raised and is_equal_approx(tw.hp, tw.max_hp) and is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP),
		"before its time a mirror does not exist: a Smite on its unguarded tower only shakes it")
	Kit.done(s)


static func _guarded(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	Kit.run_for(s, float(LanternEyeDirector.STEP_AT[0]) + DT)
	t.check(d.steps[0].raised and d.standard(0) == d.towers[0] and (s.banners as Array).has("A MIRROR GOES UP ON THE NORTH TOWER")
		and d.guarded(0) and d.hint_phase() == "guarded" and d.searchlight.hunt,
		"at %s the first mirror goes up on the north tower, guarded; the light hunts" % UiTheme.clock(float(LanternEyeDirector.STEP_AT[0])))
	_smite(s, d, 0)
	var tw := d.towers[0]
	t.check(is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP) and is_equal_approx(tw.hp, tw.max_hp),
		"guarded, a Smite only shakes the tower: the glass whole, the tower's health unmoved")
	Kit.done(s)


static func _shatter(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	var hits := [0]
	d.towers[0].hit.connect(func(_s: Structure, _a: float, _k: StringName) -> void: hits[0] += 1)
	_smite(s, d, 0)
	t.check(is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP - SmiteFx.DAMAGE) and not d.shattered[0] and d.hint_phase() == "open"
		and hits[0] == 1 and is_equal_approx(d.towers[0].hp, d.towers[0].max_hp), "open, a Smite strikes the glass; the tower is heard but its health never moves")
	_smite(s, d, 0)
	var out := true
	for w: HuntDirector.Guard in d.wrights[0]:
		var p := w.man as Person
		out = out and not p.inside and p.mind == Person.Mind.DUTY and p.anchor == w.post
	t.check(d.shattered[0] and is_equal_approx(d.drain_left[0], LanternEyeDirector.DRAIN) and out and (s.banners as Array).has("THE MIRROR SHATTERS")
		and d.hint_phase() == "shattered" and not d.searchlight.hunt, "two Smites shatter it; its two wrights come out to their posts; the light goes quiet")
	Kit.done(s)


static func _rehang(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	d._shatter(0)
	Kit.run_for(s, LanternEyeDirector.REHANG * 0.5 + 0.2)
	var inside := true
	for w: HuntDirector.Guard in d.wrights[0]:
		inside = inside and (w.man as Person).inside
	t.check(not d.shattered[0] and not d.broken(0) and is_equal_approx(d.glass[0], LanternEyeDirector.MIRROR_HP) and inside
		and (s.banners as Array).has("THE MIRROR IS HUNG AGAIN"), "two wrights at work hang a new glass in 5 s: the mirror stands again, its wrights back inside")
	Kit.done(s)


static func _gone(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	_clear(d, 0)
	d._shatter(0)
	for w: HuntDirector.Guard in d.wrights[0]:
		Kit.free_body(s, w.man)
	Kit.run_for(s, LanternEyeDirector.DRAIN + DT)
	var released := true
	for g: HuntDirector.Guard in d.steps[0].party:
		released = released and (g.man as Person).mind != Person.Mind.DUTY
	var left := d.timeline.seconds_to("step_1")
	t.check(d.broken(0) and (s.banners as Array).has("THE MIRROR IS GONE") and released and not d.steps[1].raised
		and absf(left - LanternEyeDirector.CHAIN) < 1.0, "left shattered %d s it is gone for good; its party goes home; the strip shows the next at the chain (%.1f s)" % [roundi(LanternEyeDirector.DRAIN), left])
	Kit.done(s)


static func _light(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var rules: Rules = s.rules
	var far := Vector2(10.0, 10.0)
	rules.cast_made.emit(0, "smite", far)
	Kit.run_for(s, DT)
	t.check(not d.searchlight.hunt and not d.searchlight.searching and d.last_cast == Vector2.INF, "quiet: a cast before any mirror stands draws no beam")
	d._raise(0)
	Kit.run_for(s, DT)
	rules.cast_made.emit(0, "smite", far)
	Kit.run_for(s, DT)
	t.check(d.searchlight.hunt and d.searchlight.searching and d.last_cast == far, "a mirror standing, a heard cast draws the nearest beam")
	Kit.run_for(s, LanternEyeDirector.HOLD + 0.5)
	t.check(not d.searchlight.searching, "the beam goes back to its sweep after %d s" % roundi(LanternEyeDirector.HOLD))
	rules.cast_made.emit(0, "whisper", Vector2(-10.0, 5.0))
	t.check(d.last_cast == far, "a whisper is not heard")
	rules.cast_made.emit(0, "wisp", Vector2(-10.0, 5.0))
	t.check(d.searchlight.decoy == Vector2(-10.0, 5.0) and d.searchlight.decoy_beam >= 0, "a Wisp is a decoy")
	Kit.done(s)


static func _seen_cast(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var rules: Rules = s.rules
	rules.cast_made.emit(0, "doom", d.searchlight.aim(0))
	t.check(is_equal_approx(d.gaze.value, LanternEyeDirector.SEEN_CAST) and (s.banners as Array).has("THE EYE SEES YOUR HAND"),
		"a cast aimed inside a lit pool adds %d, the light quiet or not" % roundi(LanternEyeDirector.SEEN_CAST))
	rules.cast_made.emit(0, "whisper", d.searchlight.aim(1))
	t.check(is_equal_approx(d.gaze.value, 2.0 * LanternEyeDirector.SEEN_CAST), "a whisper in the light too, though it is not heard")
	d._raise(0)
	Kit.run_for(s, DT)
	var dark := d.searchlight.aim(0) + Vector2(3.0 * Searchlight.POOL_R + 6.0, 0.0)
	if d.searchlight.touches(dark):
		dark = d.searchlight.aim(0) - Vector2(3.0 * Searchlight.POOL_R + 6.0, 0.0)
	rules.cast_made.emit(0, "smite", dark)
	Kit.run_for(s, 5.0)
	t.check(is_equal_approx(d.gaze.value, 2.0 * LanternEyeDirector.SEEN_CAST) and d.searchlight.touches(dark),
		"a cast made in the dark is not counted when the beam it draws arrives on it (review focus 3)")
	Kit.done(s)


static func _seen_death(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var crowd: Crowd = s.crowd
	var victim: Person = null
	var witness: Person = null
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p.profile.role != CitizenProfile.Role.WATCHMAN:
			if victim == null:
				victim = p
			elif witness == null:
				witness = p
	Kit.arrive(witness, victim.ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(victim, &"doom")
	Kit.run_for(s, DT)
	t.check(is_equal_approx(d.gaze.value, GazeMeter.SEEN_DEATH), "a seen death adds 10 of 100 to the Eye's own Gaze (Decision 208)")
	Kit.done(s)


static func _eye(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
	Kit.run_for(s, DT)
	var first: String = Kit.labels(d)[0]
	t.check(d.hint_phase() == "eye" and first.begins_with("THE EYE OPENS IN") and Kit.edged(d, first)
		and String(d.timeline.upcoming(1)[0].id).begins_with("eye_"), "all three standing: the countdown on the spire's tag, the hint and the strip (%s)" % first)
	Kit.run_for(s, LanternEyeDirector.EYE_OPENS - 2.0)
	t.check(not d.found and d.eye_left() > 1.0, "not yet open two seconds short")
	d._shatter(2)
	Kit.run_for(s, DT)
	t.check(d.hint_phase() == "shattered" and is_equal_approx(d.eye_left(), LanternEyeDirector.EYE_OPENS), "a mirror shattered stops it")
	d._rehang(2)
	Kit.run_for(s, LanternEyeDirector.EYE_OPENS - 2.0)
	t.check(not d.found, "hung again, the count starts afresh")
	Kit.run_for(s, 2.5)
	var main: Objective = (s.rules as Rules).objectives[0]
	var opens := 0
	for b: String in s.banners:
		opens += 1 if b == "THE EYE OPENS" else 0
	t.check(d.found and d.eye_open and d.lost_reason() == "eye_open" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "eye_open"
		and opens == 1, "thirty seconds all standing: THE EYE OPENS, once; the night is lost")
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
		d._gone(i)
	Kit.run_for(s, DT)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.broken_all() and main.check(s.rules) == Objective.Status.DONE and main.reason == "eye_blind" and not d.searchlight.on
		and d.tags().is_empty() and d.hint_phase() == "" and main.hud_text(s.rules) == "Blind the Eye: mirrors 3 / 3",
		"the third gone for good: the Eye is blind, the light out")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var g: HuntDirector.Guard = d.steps[0].party[0]
	var dead: Variant = g.man
	Kit.free_body(s, dead)
	Kit.run_for(s, LanternEyeDirector.RELIEF_AFTER + HuntDirector.TICK + DT)
	var p: Variant = g.man
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and (p as Person).anchor == g.post
		and g.relief and (s.banners as Array).has("A NEW GUARD TAKES THE POST"), "a fallen guard is replaced %d s later by a lay citizen made a watchman" % roundi(LanternEyeDirector.RELIEF_AFTER))
	Kit.done(s)


static func _reserved_tower(t) -> void:
	var a := _world()
	var north_ix := (a.town as Town)._built.find((a.d as LanternEyeDirector).towers[0])
	Kit.done(a)
	var b := Kit.world(MissionBook.lantern_eye(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved_places.append(rules.town()._built[north_ix]))
	var d: LanternEyeDirector = b.d
	var north := (b.town as Town)._built[north_ix]
	t.check(d.towers.size() == 3 and not d.towers.has(north) and RuinWish.fits(d.towers[0], "tower")
		and d.towers[0].art_tag != &"bell_tower", "a watchtower wish's tower is passed over: the mirror takes the next nearest (Decision 214)")
	Kit.done(b)


static func _evacuated(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	d._gone(0)
	d._raise(1)
	Kit.run_for(s, 1.0)
	var g1: HuntDirector.Guard = d.steps[1].party[0]
	var g2: HuntDirector.Guard = d.steps[1].party[1]
	var whispered := g1.man as Person
	var recovering := g2.man as Person
	whispered.whisper(whispered.ground_pos + Vector2(1.0, 0.0), MindWhisperFx.LINGER)
	recovering._recover(1.0)
	Kit.evacuate(s)
	t.check(recovering.mind == Person.Mind.FLEE and whispered._whisper_fled, "(set-up) the evacuation runs the recovering guard and owes the whispered one a flight")
	Kit.run_for(s, 2.0 * HuntDirector.TICK + DT)
	var inside := true
	for i in [1, 2]:
		for w: HuntDirector.Guard in d.wrights[i]:
			inside = inside and (w.man as Person).inside
	t.check(recovering.mind == Person.Mind.DUTY and recovering.anchor == g2.post and whispered.mind == Person.Mind.WHISPERED
		and not whispered._whisper_fled and inside, "the second mirror standing: both guards kept at their posts; the wrights inside stay inside")
	Kit.done(s)
	var s2 := _world()
	var d2: LanternEyeDirector = s2.d
	d2._raise(0)
	_clear(d2, 0)
	d2._shatter(0)
	var w0: HuntDirector.Guard = d2.wrights[0][0]
	var w1: HuntDirector.Guard = d2.wrights[0][1]
	(w1.man as Person)._recover(1.0)
	Kit.evacuate(s2)
	Kit.run_for(s2, 2.0 * HuntDirector.TICK + DT)
	t.check((w0.man as Person).mind == Person.Mind.DUTY and (w1.man as Person).mind == Person.Mind.DUTY and (w1.man as Person).anchor == w1.post
		and d2.hang_work[0] > 0.0 and (s2.crowd as Crowd).citizens.has(w1.man), "during a drain: the wrights hold their posts and work on")
	Kit.done(s2)


static func _tagged(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	var labels := Kit.labels(d)
	var next := "NEXT MIRROR %s" % UiTheme.clock(float(LanternEyeDirector.STEP_AT[0]))
	t.check(labels[0] == next and Kit.edged(d, next) and labels.has("GUARD") and d.hint_phase() == "",
		"at the start: the next mirror's tower with its time, pointed at; GUARD on each guard (%s)" % [labels])
	d._raise(0)
	t.check(Kit.labels(d)[0] == "MIRROR - GUARDED" and Kit.edged(d, "MIRROR - GUARDED"), "the current mirror, guarded, gold, pointed at")
	_clear(d, 0)
	d._shatter(0)
	labels = Kit.labels(d)
	t.check(labels[0] == "MIRROR - SHATTERED %d" % roundi(LanternEyeDirector.DRAIN) and labels.has("WRIGHT") and absf(d.hint_seconds() - LanternEyeDirector.DRAIN) < 0.1,
		"shattered: its drain on its tag and in the hint's seconds; WRIGHT on each wright (%s)" % [labels])
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The north tower. A mirror goes up here at %s: shatter it and keep it shattered %d s." % [
		UiTheme.clock(float(LanternEyeDirector.STEP_AT[0])), roundi(LanternEyeDirector.DRAIN)]
		and String(tour[1][1]) == "Halcyon's Searchlight. While a mirror stands, its beams hunt your casts. A cast in the light is seen."
		and String(tour[2][1]) == "The east and south-west towers: the next mirrors. If all three stand at once, the Eye opens.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("eye_blind") == "THE LANTERN'S EYE IS BLIND" and ResultsScreen.ACT_TITLES.get("eye_open") == "THE EYE OPENS"
		and MissionHints.line("lantern_eye", "eye").contains(MissionHints.SECONDS) and MissionHints.line("lantern_eye", "shattered").contains(MissionHints.SECONDS),
		"its results under its own keys; its counting hints carry the seconds' mark")
	Kit.done(s)


static func _teardown(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	d._raise(0)
	var towers := d.towers.duplicate()
	var own := d._own_filters.duplicate()
	d.teardown()
	var back := true
	for i in towers.size():
		back = back and (towers[i] as Structure).damage_filter == own[i]
	t.check(back and not d.searchlight.on, "teardown gives every tower its own filter back and puts the light out")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: LanternEyeDirector = s.d
	for i in 3:
		d._raise(i)
	_clear(d, 0)
	d._shatter(0)
	Kit.run_for(s, 0.2)
	for i in 3:
		for g: HuntDirector.Guard in d.steps[i].party:
			if MissionDirector._alive(g.man):
				Kit.free_body(s, g.man)
		for w: HuntDirector.Guard in d.wrights[i]:
			if MissionDirector._alive(w.man) and not (w.man as Person).inside:
				Kit.free_body(s, w.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.shattered[0] and d.hang_work[0] < LanternEyeDirector.REHANG and d.hint_phase() == "shattered", "every guard and the working wrights freed: borne (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_lantern_eye.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Run Import, then the halves. Expected: a parse error or FAILs in `test_lantern_eye`
  (no `LanternEyeDirector`, no `MissionBook.lantern_eye()`).

- [ ] **Step 3: The director.** Create `src/game/mission/lantern_eye_director.gd`:

```gdscript
class_name LanternEyeDirector
extends HuntDirector
## The Lantern's Eye (v0.11 M6, Tier 5, mission spec §1; Anchors + Hunt): Halcyon's Searchlight sweeps the town from the Temple's spire
## all night, both beams lit from 0:00. The Inquisition hangs three great mirrors on the wall towers to aim it, one at a time on the Hunt
## type's chain (STEP_AT, CHAIN): each tower is a step's standard (Decision 213), the standing wall tower nearest its point, never the
## bell tower, a wish's or another mirror's (_tower_near(), Decision 214). The towers are stone tonight (_stone()): their own health
## never moves. A party of PARTY watchmen stands on posts POST_GAP apart along each tower's town-side face from the start, on guard
## within GUARD_REACH of the tower (plan decision 277). While one stands guard a blow only shakes the tower; unguarded it strikes the
## mirror's glass (MIRROR_HP, held here; _unguarded_blow()) and is heard (shield_hits). At 0 the mirror shatters and its WRIGHTS, waiting
## inside the tower, come out to posts at its foot: REHANG seconds of one wright's work hangs a new glass at full health, and they go back
## in. Left shattered DRAIN seconds it is gone for good -- the Hunt's _break(): its party goes home and the next mirror comes on the
## chain. While a mirror stands unshattered the light hunts: every cast it hears (not a whisper, UNHEARD) draws the nearest beam, held
## HOLD seconds (Searchlight.hunt, hold); a Will-o'-Wisp is a decoy. A cast aimed inside a lit pool adds SEEN_CAST to the director's own
## Gaze, quiet or hunting (plan decision 279); a seen death adds GazeMeter.SEEN_DEATH. All three standing unshattered together for
## EYE_OPENS loses ("THE EYE OPENS", _found()); the third gone wins (HuntObjective). Every held person is kept from the town's flight by
## MissionDirector._hold_all().

## The Searchlight's spire: the Temple's centre (v0.11 M6, TownLayout.TEMPLE's), as The Vigil Flame's.
const SPIRE := Vector2(0.8, -8.7)
## Each mirror tower is the standing wall tower nearest its point, in the order the mirrors go up; their words (v0.11 M6, Decision 214).
const TOWER_POINTS := [Vector2(0.0, -15.65), Vector2(15.65, 0.0), Vector2(-8.0, 15.65)]
const TOWER_WORDS := ["the north tower", "the east tower", "the south-west tower"]
## Mission spec §1's numbers (v0.11 M6), first guesses, tuned by Step 9's gate in this order: CHAIN (30-45), STEP_AT[0] (40-60), DRAIN
## (15-20), MIRROR_HP (90-135), PARTY (2-3); EYE_OPENS (20-30) if doing nothing does not lose. The steps: each mirror's time at the
## latest, the chain, a party, its posts' spacing and how far out from the face, its reach, return and relief.
const STEP_AT := [50.0, 115.0, 180.0]
const CHAIN := 35.0
const PARTY := 3
const POST_GAP := 2.4
const POST_OUT := 1.0
const GUARD_REACH := 2.0
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
## The glass (v0.11 M6): its health, the drain, the wrights and their spacing and reach, the re-hanging's seconds, the Eye's countdown.
const MIRROR_HP := 90.0
const DRAIN := 20.0
const WRIGHTS := 2
const WRIGHT_GAP := 2.4
const WRIGHT_REACH := 1.2
const REHANG := 10.0
const EYE_OPENS := 30.0
## The light (v0.11 M6): how long a drawn beam holds its noise; what a seen cast adds to the Gaze; the casts it does not hear.
const HOLD := 8.0
const SEEN_CAST := 20.0
const UNHEARD := ["whisper"]
## How near zero the Eye's countdown counts as run out (v0.11 M6, plan decision 278).
const EYE_EPS := 0.001
## Where the camera rests (v0.11 M6, Decision 247): the spire just above the centre, the north tower at the upper right.
const CAMERA_AT := Vector2(0.0, -6.0)
## A shattered mirror's tag, orange (v0.11 M6).
const MARK_PLACE := Color("ff9a3a")

## The three towers, in order; each one's foot (1.0 out from the middle of its town-side face, walkable); each tower's own damage filter
## before tonight (v0.11 M6).
var towers: Array[Structure] = []
var feet: Array[Vector2] = []
var _own_filters: Array[Callable] = []
## Each mirror's glass; shattered now; seconds of its drain left; seconds of one wright's work toward its new glass (v0.11 M6).
var glass: Array[float] = []
var shattered: Array[bool] = []
var drain_left: Array[float] = []
var hang_work: Array[float] = []
## Each mirror's wrights, HuntDirector.Guard records (v0.11 M6, plan decision 280).
var wrights: Array = []
## The light; the last cast it heard (the Hunt's quarry, never tagged); how many casts it saw (v0.11 M6).
var searchlight: Searchlight
var last_cast := Vector2.INF
var seen_casts := 0
## The Eye opened (the loss); the night's second the three stood together (-1 when not); which countdown runs (v0.11 M6).
var eye_open := false
var _eye_since := -1.0
var _eye_run := 0
## The Temple, for the spire's tag; everyone the director made a wright, kept off the workshop's hiring (v0.11 M6).
var temple: Structure
var _hired: Array = []
var _fx: SearchlightFx


## The plan (v0.11 M6): the Eye's own Gaze; the Hunt's knobs and words; each tower chosen, stone tonight, and its step; the light.
func _plan() -> void:
	gaze = GazeMeter.new()
	has_head = false
	chain = CHAIN
	guard_reach = GUARD_REACH
	return_after = RETURN_AFTER
	relief_after = RELIEF_AFTER
	shield_hits = true
	standard_label = "MIRROR"
	guard_label = "GUARD"
	next_label = "NEXT MIRROR"
	count_word = "mirrors"
	lost_word = "eye_open"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	var taken: Array = []
	for i in TOWER_POINTS.size():
		var tw := _tower_near(TOWER_POINTS[i], taken)
		if tw == null:
			push_warning("LanternEyeDirector: no tower for %s" % TOWER_WORDS[i])
			continue
		taken.append(tw)
		towers.append(tw)
		feet.append(_foot(tw))
		_own_filters.append(tw.damage_filter)
		tw.damage_filter = _stone
		steps.append(_step(String(TOWER_WORDS[i]), feet.back(), Rect2(), float(STEP_AT[i]), PARTY))
		glass.append(MIRROR_HP)
		shattered.append(false)
		drain_left.append(0.0)
		hang_work.append(0.0)
	searchlight = Searchlight.new().setup(SPIRE)
	searchlight.hold = HOLD


## The Hunt's setup, then each tower's wrights indoors, the light lit with both beams and the casts heard (v0.11 M6).
func _begin() -> void:
	super()
	for i in steps.size():
		var crew: Array = []
		for k in WRIGHTS:
			var w := Guard.new()
			w.post = _wright_post(i, k)
			var near := _lay_near(w.post, 1, _in_use())
			if not near.is_empty():
				var p := near[0]
				_make_wright(p)
				w.man = p
				_set_down(p, w.post)
				p.go_duty(w.post)
				_take_inside(p, towers[i])
			crew.append(w)
		wrights.append(crew)
	searchlight.light(Searchlight.SECOND_AFTER)
	_show_light()
	rules.cast_made.connect(_on_cast)


## The standing wall tower nearest `spot` (v0.11 M6, a copy of The Bell-Ringers' _tower_near(), not shared): RuinWish.fits(s, "tower")
## -- never the bell tower -- not a wish's (reserved_places) and none of `exclude`; null for none.
func _tower_near(spot: Vector2, exclude: Array) -> Structure:
	var best: Structure = null
	for s: Structure in town._built:
		if not is_instance_valid(s) or s.destroyed or not RuinWish.fits(s, "tower") or reserved_places.has(s) or exclude.has(s):
			continue
		if best == null or s.center().distance_squared_to(spot) < best.center().distance_squared_to(spot):
			best = s
	return best


## Tower `tw`'s foot (v0.11 M6): POST_OUT beyond the middle of the face turned most toward the town's middle, on walkable ground.
func _foot(tw: Structure) -> Vector2:
	var half := tw.footprint.size * 0.5
	var inward := tw.center().direction_to(TownLayout.MAP.get_center())
	var best := Vector2.ZERO
	for dir: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		if best == Vector2.ZERO or dir.dot(inward) > best.dot(inward):
			best = dir
	var depth := absf(best.x) * half.x + absf(best.y) * half.y
	return _walkable(tw.center() + best * (depth + POST_OUT))


## The way along tower `i`'s town-side face (v0.11 M6): square to the line from the tower to its foot.
func along(i: int) -> Vector2:
	var out := feet[i] - towers[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	return Vector2(-out.y, out.x)


## A point just off tower `i`'s outer face, away from the town (v0.11 M6, for the scripted player's Smite): within a Smite's reach of it.
func outer_face(i: int) -> Vector2:
	var out := towers[i].center() - feet[i]
	out = out.normalized() if out.length() > 0.01 else Vector2.UP
	var half := towers[i].footprint.size * 0.5
	return towers[i].center() + out * (absf(out.x) * half.x + absf(out.y) * half.y + 0.3)


## The `k`th guard's post of tower `i` (v0.11 M6): the foot, then POST_GAP to either side of it along the face.
func _party_post(i: int, k: int) -> Vector2:
	var side := 0.0 if k == 0 else (-1.0 if k % 2 == 1 else 1.0) * POST_GAP * float((k + 1) / 2)
	return _walkable(feet[i] + along(i) * side)


## The `k`th wright's post of tower `i` (v0.11 M6): at its foot, WRIGHT_GAP apart.
func _wright_post(i: int, k: int) -> Vector2:
	return _walkable(feet[i] + along(i) * WRIGHT_GAP * (float(k) - 0.5 * float(WRIGHTS - 1)))


## `p` in the apron and cap, kept from the town's workshop (v0.11 M6, The Crown's Bread's way).
func _make_wright(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.ENGINEER
	_hired.append(p)
	if crowd.engineers != null and not crowd.engineers.not_hired.has(p):
		crowd.engineers.not_hired.append(p)


## Everyone at the night's work (v0.11 M6): the Hunt's, and every wright.
func _in_use() -> Array:
	var out := super()
	for crew: Array in wrights:
		for w: Guard in crew:
			out.append(w.man)
	return out


## Guard `g` of tower `i` stands guard (v0.11 M6, plan decision 277): alive, out of doors, not held by the god, within guard_reach of the
## tower -- before its mirror goes up too.
func _guarding(i: int, g: Guard) -> bool:
	if not _alive(g.man) or i >= towers.size() or not is_instance_valid(towers[i]):
		return false
	var p := g.man as Person
	return not p.inside and not p.mind in BLIND and towers[i].distance_to(p.ground_pos) <= guard_reach


## Step `i`'s standard is its tower (v0.11 M6); null without one (the step then counts broken).
func _raise_standard(i: int) -> Structure:
	return towers[i] if i < towers.size() else null


## Structure.damage_filter for a tower tonight (v0.11 M6): stone, a blow only shakes it.
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(SHAKE)


## An unguarded blow on a tower (v0.11 M6, mission spec §6.2): with its mirror up and whole it strikes the glass -- the tower scorched,
## shaken and heard as any struck building, its own health unmoved -- and at 0 the mirror shatters; else it only shakes the tower.
func _unguarded_blow(s: Structure, amount: float, _source: Vector2, kind: StringName) -> void:
	var i := _step_of(s)
	if i < 0 or steps[i].broken or shattered[i]:
		s.shake(SHAKE)
		return
	glass[i] = maxf(glass[i] - amount, 0.0)
	s.mark_hit(amount / s.max_hp, kind)
	if shield_hits:
		s.hit.emit(s, amount, kind)
	if glass[i] <= 0.0:
		_shatter(i)


## Mirror `i` shatters (v0.11 M6): its drain starts, and its wrights come out of the tower to their posts on duty.
func _shatter(i: int) -> void:
	if shattered[i] or steps[i].broken:
		return
	shattered[i] = true
	glass[i] = 0.0
	drain_left[i] = DRAIN
	hang_work[i] = 0.0
	rules.banner.emit("THE MIRROR SHATTERS")
	for w: Guard in wrights[i]:
		w.away = 0.0
		if _alive(w.man) and (w.man as Person).inside:
			_bring_out(w.man as Person, w.post)
			_keep_from_flight(w.man as Person, true)  # Crowd._evacuate() runs the indoors too, if he was not on duty
			(w.man as Person).go_duty(w.post)


## Mirror `i` is hung again (v0.11 M6): full glass, standing, its wrights back inside the tower for the next time.
func _rehang(i: int) -> void:
	shattered[i] = false
	glass[i] = MIRROR_HP
	hang_work[i] = 0.0
	drain_left[i] = 0.0
	rules.banner.emit("THE MIRROR IS HUNG AGAIN")
	for w: Guard in wrights[i]:
		if _alive(w.man) and not (w.man as Person).inside:
			(w.man as Person).go_duty(w.post)
			_take_inside(w.man as Person, towers[i])


## Mirror `i` is gone for good (v0.11 M6): its wrights go home (out first if inside), and the Hunt breaks its step -- its party home, the
## next on the chain; the third gone puts the light out.
func _gone(i: int) -> void:
	if steps[i].broken:
		return
	shattered[i] = false
	for w: Guard in wrights[i]:
		if _alive(w.man) and (w.man as Person).inside:
			_bring_out(w.man as Person, w.post)
			_keep_from_flight(w.man as Person, true)
		_release(w)
	_break(i)
	if broken_all():
		searchlight.put_out()


## Wright `w` is at work (v0.11 M6): alive, out of doors, not held by the god, within WRIGHT_REACH of his post.
func _working(w: Guard) -> bool:
	if not _alive(w.man):
		return false
	var p := w.man as Person
	return not p.inside and not p.mind in BLIND and p.ground_pos.distance_to(w.post) <= WRIGHT_REACH


## Some mirror stands raised and whole (v0.11 M6): the light hunts.
func _hunting() -> bool:
	for i in steps.size():
		if steps[i].raised and not steps[i].broken and not shattered[i]:
			return true
	return false


## All three mirrors stand raised and whole together (v0.11 M6): the Eye's countdown runs.
func _all_standing() -> bool:
	if steps.size() < TOWER_POINTS.size():
		return false
	for i in steps.size():
		if not steps[i].raised or steps[i].broken or shattered[i]:
			return false
	return true


## How many mirrors are shattered now (v0.11 M6). Only reads.
func shattered_now() -> int:
	var n := 0
	for i in steps.size():
		n += 1 if shattered[i] and not steps[i].broken else 0
	return n


## Seconds until the Eye opens while the three stand together; EYE_OPENS while they do not (v0.11 M6).
func eye_left() -> float:
	return maxf(EYE_OPENS - (_clock - _eye_since), 0.0) if _eye_since >= 0.0 else EYE_OPENS


## One step (v0.11 M6): the Hunt's (the timeline, the chain, the parties), the Gaze's deaths, then every frame the mirrors' drains and
## glass, the Eye's countdown and the light.
func step(delta: float) -> void:
	super(delta)
	gaze.judge_deaths(crowd)
	if found or broken_all():
		return
	_step_mirrors(delta)
	_step_eye()
	_step_light(delta)


## Each shattered mirror (v0.11 M6): its wrights at work add to the new glass, REHANG of one wright's work hanging it; else its drain
## runs, and at 0 it is gone for good.
func _step_mirrors(delta: float) -> void:
	for i in steps.size():
		if not shattered[i] or steps[i].broken:
			continue
		var working := 0
		for w: Guard in wrights[i]:
			working += 1 if _working(w) else 0
		hang_work[i] += delta * float(working)
		if hang_work[i] >= REHANG:
			_rehang(i)
			continue
		drain_left[i] -= delta
		if drain_left[i] <= 0.0:
			_gone(i)


## The Eye's countdown (v0.11 M6, plan decision 278): starts when the three stand together, its run shown on the strip; stops when one
## falls; at 0 the Eye opens -- found, its banner once.
func _step_eye() -> void:
	if not _all_standing():
		_eye_since = -1.0
		return
	if _eye_since < 0.0:
		_eye_since = _clock
		_eye_run += 1
		var run := _eye_run
		timeline.add(timeline.elapsed() + EYE_OPENS / timeline.stretch_factor(), "eye_%d" % run, "The Eye opens", Callable(),
			func() -> bool: return _eye_run == run and _eye_since >= 0.0 and eye_left() > EYE_EPS)
	if eye_left() <= EYE_EPS and not found:
		eye_open = true
		found = true
		rules.banner.emit(_found_banner())


## The light (v0.11 M6): hunting while a mirror stands, its noise forgotten when it goes quiet; swept on.
func _step_light(delta: float) -> void:
	if not searchlight.on:
		return
	var now := _hunting()
	if now != searchlight.hunt:
		searchlight.hunt = now
		if not now:
			searchlight.noise = Vector2.INF
	searchlight.step(delta, rules.time_left)


## A cast (Rules.cast_made, v0.11 M6): aimed in a lit pool it is seen -- SEEN_CAST on the Gaze, heard or not; a Wisp is a decoy; while a
## mirror stands, a heard cast is the light's noise.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if not searchlight.on:
		return
	if searchlight.touches(at):
		seen_casts += 1
		gaze.add(SEEN_CAST)
		rules.banner.emit("THE EYE SEES YOUR HAND")
	if key in UNHEARD or not _hunting():
		if key == "wisp":
			searchlight.lure(at)
		return
	last_cast = at
	searchlight.hear(at)
	if key == "wisp":
		searchlight.lure(at)


## A death (v0.11 M6): the Hunt's, and noted for the Gaze (seen or not, Crowd.nearest_witness() decides).
func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	super(e, kind)
	gaze.note_death(e.ground_pos)


## Every held person kept from the town's flight by the one rule (v0.11 M6): the Hunt's, and the wrights of every mirror not gone; then
## the wrights at their posts by their own rule.
func _keep_held(evacuating: bool) -> void:
	super(evacuating)
	var people: Array = []
	for i in wrights.size():
		if steps[i].broken:
			continue
		for w: Guard in wrights[i]:
			people.append(w.man)
	_hold_all(people, evacuating)
	_keep_wrights(evacuating)


## A shattered mirror's wrights at their work (v0.11 M6): one at work is kept on duty there; one off his post but alive walks back
## RETURN_AFTER after he left (his away clock moves a TICK a look), or at once at the first look after the evacuation began.
func _keep_wrights(evacuating: bool) -> void:
	for i in wrights.size():
		if not shattered[i] or steps[i].broken:
			continue
		for w: Guard in wrights[i]:
			if not _alive(w.man) or (w.man as Person).inside:
				continue
			if _working(w):
				w.away = 0.0
				if (w.man as Person).mind != Person.Mind.DUTY:
					_recall_to(w.man, w.post, evacuating)
				continue
			w.away += TICK
			if w.away >= RETURN_AFTER or evacuating:
				_recall_to(w.man, w.post, evacuating)


## The light drawn, when the director has the battlefield's effects (v0.11 M6; never in tests).
func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, searchlight.spire, {"light": searchlight}) as SearchlightFx


## The Eye's quarry: the god's last heard cast (v0.11 M6); never tagged.
func _quarry_point() -> Vector2:
	return last_cast


## The hunt has found its quarry: the Eye opened (v0.11 M6).
func _found() -> bool:
	return eye_open


## The banners (v0.11 M6).
func _opening_banner() -> String:
	return "THE LANTERN'S EYE"


func _step_label(i: int) -> String:
	return "A mirror goes up on %s" % steps[i].words


func _broken_banner(_i: int) -> String:
	return "THE MIRROR IS GONE"


func _found_banner() -> String:
	return "THE EYE OPENS"


## The map tags, most important first (v0.11 M6, mission spec §1): the Eye's countdown on the spire while it runs; the current mirror,
## gold and pointed at ("- GUARDED", or "- SHATTERED n" orange); each other standing mirror, gold; the next mirror's tower with its
## sooner time, grey, pointed at; GUARD on each guard on guard, a red diamond on a relief walking in, a small red mark on one away;
## WRIGHT on each wright out of doors. The beams are drawn, not tagged.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if found or broken_all():
		return out
	if _eye_since >= 0.0:
		out.append(MapTag.place(SPIRE, MARK_WATCHED, "THE EYE OPENS IN %d" % ceili(eye_left()), temple.height if temple != null else 0.0, true))
	var cur := current()
	for i in steps.size():
		if not steps[i].raised or steps[i].broken:
			continue
		var tw := towers[i]
		if shattered[i]:
			out.append(MapTag.place(tw.center(), MARK_PLACE, "MIRROR - SHATTERED %d" % ceili(maxf(drain_left[i], 0.0)), tw.height, i == cur))
		else:
			out.append(MapTag.place(tw.center(), MARK_TARGET, "MIRROR - GUARDED" if i == cur and guarded(i) else "MIRROR", tw.height, i == cur))
	var n := next_step()
	if n >= 0:
		out.append(MapTag.place(towers[n].center(), MARK_NOT_YET, "%s %s" % [next_label, UiTheme.clock(due_in(n))], towers[n].height, true))
	for i in steps.size():
		if steps[i].broken:
			continue
		for g: Guard in steps[i].party:
			if not _alive(g.man) or (g.man as Person).inside:
				continue
			var p := g.man as Person
			if _guarding(i, g):
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED, guard_label))
			elif g.relief:
				out.append(MapTag.person(p.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(p.ground_pos, MARK_WATCHED))
		for w: Guard in wrights[i]:
			if _alive(w.man) and not (w.man as Person).inside:
				out.append(MapTag.person((w.man as Person).ground_pos, MARK_WATCHED, "WRIGHT"))
	return out


## The hint's phase (v0.11 M6, plan decision 303): "eye" while the countdown runs; "shattered" while a mirror drains; "guarded" or
## "open" for the current mirror; "waiting" once one is gone and the next is still to go up; else "".
func hint_phase() -> String:
	if found or broken_all():
		return ""
	if _eye_since >= 0.0:
		return "eye"
	if shattered_now() > 0:
		return "shattered"
	var cur := current()
	if cur >= 0:
		return "guarded" if guarded(cur) else "open"
	if broken_count() > 0 and next_step() >= 0:
		return "waiting"
	return ""


## The seconds the hint counts down (v0.11 M6): the Eye's in "eye", the first draining mirror's in "shattered"; else 0.
func hint_seconds() -> float:
	match hint_phase():
		"eye":
			return eye_left()
		"shattered":
			for i in steps.size():
				if shattered[i] and not steps[i].broken:
					return maxf(drain_left[i], 0.0)
	return 0.0


## The tour (v0.11 M6, mission spec §1): the north tower, the spire, the east tower.
func tour() -> Array:
	var out := []
	if not towers.is_empty():
		out.append([towers[0].center(), "The north tower. A mirror goes up here at %s: shatter it and keep it shattered %d s." % [
			UiTheme.clock(float(STEP_AT[0])), roundi(DRAIN)]])
	out.append([SPIRE, "Halcyon's Searchlight. While a mirror stands, its beams hunt your casts. A cast in the light is seen."])
	if towers.size() > 1:
		out.append([towers[1].center(), "The east and south-west towers: the next mirrors. If all three stand at once, the Eye opens."])
	return out


## What the results show (v0.11 M6): the Hunt's, the casts the light saw and the Gaze.
func report() -> Dictionary:
	var out := super()
	out["seen_casts"] = seen_casts
	out["gaze"] = gaze.value
	return out


## Lets go of the casts, the light and its drawing, then the Hunt's (which puts the stone filter back), then each tower's own filter and
## the workshop's list (v0.11 M6). Safe to call twice.
func teardown() -> void:
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	if searchlight != null:
		searchlight.put_out()
	if is_instance_valid(_fx):
		_fx.end_now()
	_fx = null
	if ctx != null and ctx.impact != null:
		ctx.impact.dim(0.0, 4.0)
	super()
	for i in towers.size():
		if is_instance_valid(towers[i]):
			towers[i].damage_filter = _own_filters[i]
	if is_instance_valid(crowd) and crowd.engineers != null:
		for v: Variant in _hired:
			crowd.engineers.not_hired.erase(v)
```

- [ ] **Step 4: The mission.** In `src/game/mission/mission_book.gd`:
  - `tier_missions()`'s list gains `lantern_eye()` at its end.
  - After M5's last mission function add:

```gdscript
## The Lantern's Eye (v0.11 M6, Tier 5, mission spec §1 and §8 row 23): shatter the three mirrors the Inquisition hangs on the wall
## towers to aim Halcyon's Searchlight, each kept shattered 20 s, before all three stand together (LanternEyeDirector, the Hunt type
## with an Anchors drain).
static func lantern_eye() -> MissionDef:
	var m := _tier5(LANTERN_EYE, "The Lantern's Eye", PackedStringArray(["Halcyon hangs mirrors to aim his light.",
		"Shatter all three before the Eye opens."]))
	m.goal = "Shatter the three mirrors on the wall towers, each kept shattered %d s, before all three stand together for %d s" % [
		roundi(LanternEyeDirector.DRAIN), roundi(LanternEyeDirector.EYE_OPENS)]
	m.goal_label = "The Eye is blind"
	m.lose = "All three mirrors stand together for %d s, Halcyon's Gaze fills, or dawn comes" % roundi(LanternEyeDirector.EYE_OPENS)
	m.camera_at = LanternEyeDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "whisper", "wisp", "heaven"])
	m.director = LanternEyeDirector
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [HuntObjective.new("Blind the Eye", "eye_blind"), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

- [ ] **Step 5: The hints and the titles.**
  - In `src/game/mission/mission_hints.gd`'s `LINES`, after M5's lines add:

```gdscript
	"lantern_eye": "Clear a mirror's guards (red), then shatter it (gold) and keep it shattered 20 s. While a mirror stands, the light hunts your casts: never cast where it shines.",
	"lantern_eye.guarded": "Its guards (red) hold the mirror: blows only shake the tower. Remove every one.",
	"lantern_eye.open": "The mirror (gold) stands unguarded. Two blows shatter it: strike where no beam shines.",
	"lantern_eye.shattered": "Its wrights (red) hang a new glass. Stop them for {n} s and it is gone for good.",
	"lantern_eye.waiting": "The next mirror goes up soon, and the light is quiet till then. Clear its guards (red) shortly before.",
	"lantern_eye.eye": "All three mirrors stand: the Eye opens in {n} s. Shatter one now.",
```

  - In `src/game/ui/results_screen.gd`, `ACT_TITLES` gains `"eye_blind": "THE LANTERN'S EYE IS BLIND", "eye_open": "THE EYE OPENS"`, and its
    doc gains `## v0.11 M6: Ascendance's new missions' endings, each under the mission's own reason keys.`

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 45.
  If a placement check fails (posts too close where `_walkable()` snapped two together, a tower's side post off guard), report the
  measured numbers before changing anything; the fix is in `_party_post()` / `_wright_post()`, never in the test's thresholds.

- [ ] **Step 7: The scenario.** In `tools/dev/behaviour_check.gd`:
  - In the header comment, after M5's scenarios add:

```gdscript
##   eye  (v0.11 M6) The Lantern's Eye, --case=none (nothing cast) or play, as a player plays it (_eye_act(), never casting where a lit pool
##          lies within POOL_R + EYE_LIT_MARGIN of the aim: a shattered mirror's wright at work, Silent Doom on him unseen, else Mind Whisper
##          sends him eight units off; the current mirror open, Smite on its tower's outer face where it strikes no one, Heaven Splitter
##          along the face while Smite cools; a beam on the current tower, a Will-o'-Wisp six units out from it; the current mirror guarded
##          or the next due within EYE_AHEAD, Silent Doom on a guard unseen, else Mind Whisper sends one off; a relief walking in, Silent
##          Doom on him unseen; the result line gives the longest idle stretch). Hit-stop is off for it. --seed=, --board as ringers.
```

  - After M5's constants add:

```gdscript
## The Lantern's Eye's policy (v0.11 M6): how far past a lit pool's edge it never casts; how far out from a tower its Wisp goes; how
## soon before the next mirror it clears that party.
const EYE_LIT_MARGIN := 0.5
const EYE_WISP := 6.0
const EYE_AHEAD := 25.0
```

  - In `_run()`'s scenario chain, after M5's last branch add:

```gdscript
	elif scenario == "eye":
		powers = PackedStringArray(["doom", "smite", "whisper", "wisp", "heaven"])
		mission.mission_id = MissionBook.LANTERN_EYE
```

  - The hit-stop line's list gains `"eye"` (after M5's `"armoury"`).
  - In `_run()`'s `match scenario:`, after M5's arms add:

```gdscript
		"eye":
			await _eye(Battlefield.arg_value(args, "--case"))
```

  - After M5's last policy add:

```gdscript
## Silent Doom at `at` would go unseen and take none of `spare` (v0.11 M6, plan decision 304): it takes someone; nobody living out of
## doors beyond its radius stands within Crowd.DOOM_WITNESS of anyone within it; none within it is one of `spare`. Only reads.
func _doom_unseen(crowd: Crowd, at: Vector2, spare: Array = []) -> bool:
	var victims: Array[Person] = []
	var others: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside:
				continue
			if p.ground_pos.distance_to(at) <= SilentDoom.RADIUS:
				victims.append(p)
			else:
				others.append(p)
	if victims.is_empty():
		return false
	for v in victims:
		if spare.has(v):
			return false
		for o in others:
			if o.ground_pos.distance_to(v.ground_pos) <= Crowd.DOOM_WITNESS:
				return false
	return true


## The Lantern's Eye (v0.11 M6), with mission spec §1's policy (_eye_act()), through _scripted().
func _eye(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as LanternEyeDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("eye", which, func() -> String: return _eye_act(rules, slots, d, crowd),
		func() -> String: return "gone=%d current=%d next=%d shattered=%d eye=%.0f gaze=%d phase=%s" % [d.broken_count(), d.current(),
			d.next_step(), d.shattered_now(), d.eye_left(), roundi(d.gaze.value), d.hint_phase()])


## A lit pool lies within Searchlight.POOL_R + EYE_LIT_MARGIN of `at` (v0.11 M6): the policy never casts there. Only reads.
func _eye_lit(d: LanternEyeDirector, at: Vector2) -> bool:
	for i in d.searchlight.beams():
		var a := d.searchlight.aim(i)
		if a != Vector2.INF and a.distance_to(at) <= Searchlight.POOL_R + EYE_LIT_MARGIN:
			return true
	return false


## Nobody alive and out of doors stands within `r` of `at` (v0.11 M6): a Smite's aim that strikes down no one. Only reads.
func _eye_clear(crowd: Crowd, at: Vector2, r: float) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= r:
				return false
	return true


## One look of The Lantern's Eye's policy (v0.11 M6, mission spec §1): what was cast, or "". Never where a beam shines. The first that
## applies: a shattered mirror's wright at work -- Silent Doom on him unseen, else Mind Whisper sends him off; the current mirror open --
## Smite its tower's outer face, else Heaven Splitter along it; a beam on the current tower -- a Will-o'-Wisp six units out; the current
## mirror guarded, or the next due within EYE_AHEAD -- Silent Doom on a guard unseen, else Mind Whisper sends one off; a relief walking
## toward a standing mirror -- Silent Doom on him unseen.
func _eye_act(rules: Rules, slots: Dictionary, d: LanternEyeDirector, crowd: Crowd) -> String:
	for i in d.steps.size():
		if not d.shattered[i] or d.steps[i].broken:
			continue
		for w: HuntDirector.Guard in d.wrights[i]:
			if not d._working(w):
				continue
			var p := w.man as Person
			if _eye_lit(d, p.ground_pos):
				continue
			if _slot_ready(rules, slots, "doom") and _doom_unseen(crowd, p.ground_pos):
				rules.cast(slots.doom, p.ground_pos)
				return "doom a wright at %s" % d.steps[i].words
			if _slot_ready(rules, slots, "whisper") and not p.shaken():
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _prisoner_away(crowd, p, d.towers[i].center())})
				return "whisper a wright off %s" % d.steps[i].words
	var cur := d.current()
	if cur >= 0 and not d.shattered[cur] and not d.guarded(cur):
		var aim := d.outer_face(cur)
		if not _eye_lit(d, aim) and _eye_clear(crowd, aim, SmiteFx.HIT_R):
			if _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, aim)
				return "smite the mirror on %s" % d.steps[cur].words
			if _slot_ready(rules, slots, "heaven"):
				rules.cast(slots.heaven, aim, {"dir": d.along(cur)})
				return "heaven along %s" % d.steps[cur].words
	if cur >= 0 and _slot_ready(rules, slots, "wisp") and _eye_lit(d, d.towers[cur].center()):
		var lure := d.towers[cur].center() + (d.towers[cur].center() - d.feet[cur]).normalized() * EYE_WISP
		if not _eye_lit(d, lure):
			rules.cast(slots.wisp, lure)
			return "wisp off %s" % d.steps[cur].words
	var work: Array[int] = []
	if cur >= 0 and d.guarded(cur):
		work.append(cur)
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= EYE_AHEAD:
		work.append(n)
	for i in work:
		var on := d.party_on(i)
		if _slot_ready(rules, slots, "doom"):
			for p in on:
				if not _eye_lit(d, p.ground_pos) and _doom_unseen(crowd, p.ground_pos):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a guard of %s" % d.steps[i].words
		if _slot_ready(rules, slots, "whisper"):
			for p in on:
				if not _eye_lit(d, p.ground_pos) and not p.shaken():
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _prisoner_away(crowd, p, d.towers[i].center())})
					return "whisper a guard of %s off" % d.steps[i].words
	for i in d.steps.size():
		if d.steps[i].broken:
			continue
		var r := d.relief_walking(i)
		if r != null and not _eye_lit(d, r.ground_pos) and _slot_ready(rules, slots, "doom") and _doom_unseen(crowd, r.ground_pos):
			rules.cast(slots.doom, r.ground_pos)
			return "doom a relief at %s" % d.steps[i].words
	return ""
```

- [ ] **Step 8: Run it once.** `--scenario=eye --case=play --seed=1`. Expected: a `BEHAVIOUR eye t=...` line every 10 s, cast lines, a result
  line, no `SCRIPT ERROR`. Read the cast lines: the policy clears each party before its mirror (in the 25 s before it), Smites only an
  open mirror, never casts in a beam, Dooms only unseen. Fix the policy (never the director) until it plays the spec's steps.

- [ ] **Step 9: The gate.** Run the Scenario loop for `eye`.
  - Expected for `none`: `won=false reason=eye_open` in each, near 210 (3:30). If not 3 of 3: EYE_OPENS (20-30).
  - Expected for `play`: at least 2 of 3 won, the median won time 180-240 s, `idle` 45 s or less. The Gaze on its state line 0-20% (the
    spec's expectation: write the three values in the commit body; a policy that sees itself more than once a night is a policy bug).
  - If it misses, tune in the order CHAIN (30-45), STEP_AT[0] (40-60), DRAIN (15-20), MIRROR_HP (90-135), PARTY (2-3) -- after first
    checking the policy plays the steps well (Global Constraints). Re-run all six after each change; record each round in the commit
    body; stop after three rounds and report.
  - Write the measured clear's sum next to the spec's (≈ 216 s; ≈ 212 s on the schedule) in the commit body.

- [ ] **Step 10: Spec sync.** In the mission spec's §1, set the `Numbers` line, the timeline table, the clear's sum and any hint line to the
  tuned values and words; add the HUD row's real words ("Blind the Eye: mirrors 1 / 3", plan decision 281).

- [ ] **Step 11: The Reference check, and FLOW.** Expected: every old value unchanged; FLOW 113/0, alone.

- [ ] **Step 12: Commit.**

```bash
git add src/game/mission/lantern_eye_director.gd src/game/mission/lantern_eye_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd docs/superpowers/specs/2026-10-15-kak-v011-m6-ascendance-missions.md tests/test_lantern_eye.gd tests/test_lantern_eye.gd.uid tests/run_all.gd
git commit -m "feat: The Lantern's Eye -- three mirrors on the wall towers, a light that hunts your casts, a drain under it (v0.11 M6)" -m "<eye none/play seeds 1-3: checksums and result lines (the six new references); the gate's verdict; tuning rounds; the clear's sum; the Gaze per run; the halves' counts; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Exodus (Escort, twelve charges)

**Files:**
- Create: `src/game/mission/exodus_director.gd`
- Modify: `src/game/mission/mission_book.gd` (`exodus()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd`, `src/game/ui/results_screen.gd`
- Modify: `tools/dev/behaviour_check.gd` (`--scenario=exodus`, `_exodus()`, `_exodus_act()`, `_exodus_off()`)
- Modify: the mission spec's §2 (spec sync)
- Create: `tests/test_exodus.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: Task 1's Charge record (`Charge`, `charges`, `watch_changes`, `_appoint_charges()`, `_place_charge()`, `_exit_reached()`,
  `_resolved()`, `_all_resolved()`, `_charge_of()`, `out_count()`, `left_count()`, the per-charge steps, `EscortObjective`'s `need`);
  the Escort type (`watch`, `watch_posts`, `patrols`, `beats`, `_watching()`, `_watchers()`, `_takes_post()`, `_post_to()`,
  `_appoint_watch()`, `_appoint_patrol()`, `_step_hunters()`, `_in_use()`, `return_to`, `TICK`, `SIGHT`, `ESCAPE_REACH`, `NEAR_GATE`,
  `MARK_*`); Task 4's `_tier5()`; `MissionDirector._hold_all()`; Task 5's `_doom_unseen()`; behaviour_check's `_road_ahead()`,
  `_road_progress()`, `_seg_dist()`, `_prisoner_away()`.
- Produces: `ExodusDirector` with `households: Array` (`Household`: `words`, `name`, `house`, `door`, `gate`, `members`, `out`, `out_at`,
  `done`, `done_at`, `trail`, `out_to`, `searchers`, `sent`), `gates: Array` (`Gate`: `label`, `words`, `mouth`, `way_out`, `shut_at`,
  `shut`), `temple`, `temple_door`, `reliefs`; `current() -> int`, `upcoming() -> int`, `out_due(i) -> float`, `due_in(i) -> float`,
  `lamp(i) -> Charge`, `followers(i) -> Array`, `gate_watched(g) -> bool`, `road(i) -> Array`, `searchers_out(i) -> Array[Person]`,
  `_come_out(i)`, `_send(i)`, `_shut(g)`, `_file_spot(c) -> Vector2`; the constants of mission spec §2; `MissionBook.exodus()`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_exodus.gd`:

```gdscript
extends RefCounted
## v0.11 M6 Exodus (mission spec §2, ExodusDirector on the Escort type's Charge record): twelve believers in three households, each
## waiting inside its quiet, stone-tonight house until its time on the chain (0:15, then each at its time or CHAIN after the one before
## is done); a household follows its lamp in file, the lamp passing on; watchmen -- two patrols, two at each gate, two searchers per
## household sent 30 s after it comes out -- seize a believer on sight and march him to the Temple's door, where he is taken inside; a
## watcher marching one sees no other; the gates shut one by one and a shut gate lets no one out; ten out wins; too few left, or the
## last gate shut with fewer than ten out, loses at once. The town's evacuation passes everyone by and a believer the crowd carries out
## counts out; freed bodies are borne; the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_inside(t)
	_come_out(t)
	_chain(t)
	_file(t)
	_lamp_passes(t)
	_seized(t)
	_marching(t)
	_gates(t)
	_shut(t)
	_few(t)
	_won(t)
	_carried(t)
	_searchers(t)
	_relief(t)
	_stone(t)
	_evacuated(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.exodus())


## Every watcher moved well away and held there (v0.11 M6 tests): no one sees the believers.
static func _clear_watch(d: ExodusDirector) -> void:
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))
	for h: ExodusDirector.Household in d.households:
		for v: Variant in h.searchers:
			if MissionDirector._alive(v) and not (v as Person).inside:
				Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))


static func _setup(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var ok := d.charges.size() == ExodusDirector.BELIEVERS and d.households.size() == 3 and d.gates.size() == 3
	var people := {}
	for i in 3:
		var h: ExodusDirector.Household = d.households[i]
		ok = ok and RuinWish.fits(h.house, "house") and h.members.size() == ExodusDirector.PER_HOUSE and h.house.damage_filter.is_valid() \
			and h.gate == i and not h.out
		for c: EscortDirector.Charge in h.members:
			var p := c.man as Person
			ok = ok and p.inside and p.mind == Person.Mind.DUTY and not p.soldier
			people[p] = true
		for v: Variant in h.searchers:
			ok = ok and (v as Person).inside and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN
			people[v] = true
		for b: PackedVector2Array in d.beats:
			for k in range(b.size() - 1):
				ok = ok and Geometry2D.get_closest_point_to_segment(h.door, b[k], b[k + 1]).distance_to(h.door) > ExodusDirector.QUIET - 0.01
	for v: Variant in d.watch:
		ok = ok and (v as Person).profile.role == CitizenProfile.Role.WATCHMAN and (v as Person).mind == Person.Mind.DUTY
		people[v] = true
	for squad: Array in d.patrols:
		for v: Variant in squad:
			people[v] = true
	t.check(ok and d.watch.size() == 6 and people.size() == ExodusDirector.BELIEVERS + 6 + 4 + 6 and not d.watch_changes,
		"twelve believers, four inside each quiet stone house; two at each gate; two patrols of two; two searchers per household inside the Temple; no guard change")
	for i in 3:
		var a: Vector2 = d.watch_posts[2 * i]
		var b: Vector2 = d.watch_posts[2 * i + 1]
		ok = ok and absf(a.distance_to(b) - ExodusDirector.POST_GAP) < 0.5
	t.check(ok, "each gate's two posts about %.1f apart" % ExodusDirector.POST_GAP)
	var ids := []
	for e in d.timeline.upcoming(6):
		ids.append(e.id)
	t.check(ids == ["out_0", "out_1", "shut_0", "out_2", "shut_1", "shut_2"], "the strip: the households and the shuttings from 0:00 (%s)" % [ids])
	var cam := ExodusDirector.CAMERA_AT
	var clear := Kit.clear_of_stack(d.temple_door, cam, Kit.STACK)
	for h: ExodusDirector.Household in d.households:
		clear = clear and Kit.clear_of_stack(h.door, cam, Kit.STACK)
	for g: ExodusDirector.Gate in d.gates:
		clear = clear and Kit.clear_of_stack(g.mouth, cam, Kit.STACK)
	t.check(clear, "the camera keeps the three doors, the three gates and the Temple's door (or their arrows) clear of the real stack")
	var m := MissionBook.exodus()
	var reasons := []
	for o in m.objectives():
		reasons.append(o.reason)
	var main := m.objectives()[0] as EscortObjective
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["exodus", "gaze", "dawn"] and main.need == ExodusDirector.NEED
		and Array(m.default_loadout) == ["whisper", "doom", "discord", "wisp"] and d.gaze != null and not (d.gaze is Descent.TierGaze),
		"the mission: Tier 5's numbers; ten out, the Gaze, dawn; its own Gaze (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := true
	for c in d.charges:
		held = held and (c.man as Person).inside
	for v: Variant in d.watch:
		held = held and (v as Person).mind == Person.Mind.DUTY
	t.check(held, "the town's regroup and evacuation pass the gates' watch by; the households stay inside (review focus 2)")
	Kit.done(s)


static func _inside(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var h: ExodusDirector.Household = d.households[0]
	var p := (h.members[0] as EscortDirector.Charge).man as Person
	var reach := (s.field as EnemyField).in_radius(h.house.center(), 3.0)
	h.house.damage(500.0, h.house.center(), &"smite")
	t.check(MissionDirector._alive(p) and p.inside and not reach.has(p) and not h.house.destroyed,
		"a household inside is out of every power's reach (out of the field), its house stone tonight")
	Kit.done(s)


static func _come_out(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	Kit.run_for(s, float(ExodusDirector.OUT_AT[0]) + DT)
	var h: ExodusDirector.Household = d.households[0]
	var out := true
	for c: EscortDirector.Charge in h.members:
		out = out and not (c.man as Person).inside and (c.man as Person).mind == Person.Mind.DUTY
	t.check(h.out and out and (s.banners as Array).has("THE WEST HOUSEHOLD COMES OUT") and d.lamp(0) == h.members[0]
		and not (d.households[1] as ExodusDirector.Household).out, "at %s the west household comes out and holds at its door; its first carries the lamp" % UiTheme.clock(float(ExodusDirector.OUT_AT[0])))
	Kit.done(s)


static func _chain(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	Kit.run_for(s, 1.0)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members:
		c.escaped = true
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var left := d.timeline.seconds_to("out_1")
	t.check((d.households[0] as ExodusDirector.Household).done and absf(left - ExodusDirector.CHAIN) < 1.0,
		"a household done (each out, taken or dead): the strip shows the next at the chain (%.1f s)" % left)
	Kit.run_for(s, ExodusDirector.CHAIN + DT)
	t.check((d.households[1] as ExodusDirector.Household).out, "and it comes out %d s later, long before its own time" % roundi(ExodusDirector.CHAIN))
	Kit.done(s)


static func _file(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var lead := d.lamp(0)
	var lp := lead.man as Person
	for k in 6:
		Kit.arrive(lp, h.door + Vector2(0.0, 0.6 * float(k + 1)))
		Kit.run_for(s, ExodusDirector.TICK + DT)
	var follower: EscortDirector.Charge = h.members[1]
	var fp := follower.man as Person
	var spot := d._file_spot(follower)
	t.check(spot != Vector2.INF and fp.mind == Person.Mind.DUTY and fp.anchor.distance_to(spot) < 0.8
		and spot.distance_to(lp.ground_pos) <= 2.0 * ExodusDirector.FOLLOW_GAP + 0.3, "a follower in file walks on duty to his place behind the lamp")
	fp.whisper(fp.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) == Vector2.INF, "whispered on his own, he leaves the file")
	fp._wake()
	Kit.arrive(fp, lp.ground_pos + Vector2(6.0, 0.0))
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) == Vector2.INF and fp.mind == Person.Mind.DUTY, "back on his feet away from his lamp, he holds where he was left")
	Kit.arrive(fp, lp.ground_pos + Vector2(1.0, 0.0))
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(d._file_spot(follower) != Vector2.INF, "within %d of his lamp he rejoins the file" % roundi(ExodusDirector.REJOIN))
	Kit.done(s)


static func _lamp_passes(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var first: EscortDirector.Charge = h.members[0]
	Kit.free_body(s, first.man)
	t.check(d.lamp(0) == h.members[1], "the lamp passes to the next when its bearer dies")
	var second: EscortDirector.Charge = h.members[1]
	Kit.arrive(second.man as Person, (d.gates[0] as ExodusDirector.Gate).way_out)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(second.escaped and d.lamp(0) == h.members[2] and h.out_to.distance_to((d.gates[0] as ExodusDirector.Gate).way_out) < 1.0
		and d._file_spot(h.members[2]) == h.out_to, "when the bearer gets out, the lamp passes on and the file walks on to his way out")
	Kit.done(s)


static func _seized(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[0]
	var w := d.watch[0]
	Kit.arrive(w, (c.man as Person).ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.held and c.seizer == w and (s.banners as Array).has("A BELIEVER IS TAKEN") and d.hint_phase() == "caught"
		and Kit.labels(d).has("TAKEN TO THE TEMPLE") and Kit.edged(d, "TAKEN TO THE TEMPLE") and Kit.edged(d, "TAKING HIM IN"),
		"a watchman within sight seizes a believer: TAKEN TO THE TEMPLE and TAKING HIM IN, pointed at")
	Kit.arrive(w, d.return_to)
	Kit.arrive(c.man as Person, d.return_to + Vector2(0.3, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.taken and (c.man as Person).inside and (s.banners as Array).has("THE INQUISITION TAKES A BELIEVER") and d.left_count() == 11,
		"marched to the Temple's door he is taken inside, lost to the count")
	var march := INF
	for h: ExodusDirector.Household in d.households:
		march = minf(march, h.door.distance_to(d.temple_door))
	t.check(march >= 12.0, "every household's door is 12 units or more from the Temple's door: a march to answer (%.1f)" % march)
	Kit.done(s)


static func _marching(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var a: EscortDirector.Charge = h.members[0]
	var b: EscortDirector.Charge = h.members[1]
	var w := d.watch[0]
	Kit.arrive(b.man as Person, (a.man as Person).ground_pos + Vector2(-8.0, 0.0))
	Kit.arrive(w, (a.man as Person).ground_pos + Vector2(EscortDirector.SIGHT - 0.5, 0.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	Kit.arrive(b.man as Person, w.ground_pos + Vector2(0.0, 1.0))
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(a.held and not b.held and d.seizures == 1, "a watcher marching one believer seizes no other")
	Kit.done(s)


static func _gates(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var c: EscortDirector.Charge = h.members[1]
	Kit.arrive(c.man as Person, (d.gates[1] as ExodusDirector.Gate).way_out)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(c.escaped and d.out_count() == 1, "any open gate's way out counts, not only the household's own")
	Kit.done(s)


static func _shut(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	d._shut(0)
	var g: ExodusDirector.Gate = d.gates[0]
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[1]
	Kit.arrive(c.man as Person, g.way_out)
	Kit.run_for(s, EscortDirector.TICK + DT)
	t.check(g.shut and not c.escaped and d.lost_reason() == "" and Kit.labels(d).has("POSTERN - SHUT"),
		"the postern shut: a believer at its way out does not get out; its tag reads SHUT")
	for gate: ExodusDirector.Gate in d.gates:
		d._shut(d.gates.find(gate))
	t.check(d.lost_reason() == "gates_shut", "the last gate shut with fewer than ten out: lost (THE GATES ARE SHUT)")
	Kit.done(s)


static func _few(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	d._come_out(0)
	d._come_out(1)
	Kit.free_body(s, d.charges[0].man)
	Kit.free_body(s, d.charges[5].man)
	t.check(d.lost_reason() == "" and d.left_count() == 10 and main.check(s.rules) == Objective.Status.PENDING
		and main.hud_text(s.rules) == "Lead them out 0 / 10, 0 to spare", "two lost: none to spare, still open (%s)" % main.hud_text(s.rules))
	d.charges[9].taken = true
	t.check(d.lost_reason() == "exodus_few" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "exodus_few",
		"the third: out plus left below ten, lost at once (TOO FEW ARE LEFT)")
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var main: Objective = (s.rules as Rules).objectives[0]
	for k in ExodusDirector.NEED:
		d.charges[k].escaped = true
	t.check(main.check(s.rules) == Objective.Status.DONE and main.reason == "exodus" and d.hint_phase() == "" and d.tags().is_empty(),
		"the tenth out: the faithful are out")
	Kit.done(s)


static func _carried(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	var c: EscortDirector.Charge = (d.households[0] as ExodusDirector.Household).members[2]
	(s.crowd as Crowd).escaped.emit(c.man)
	t.check(c.escaped and d.out_count() == 1, "the crowd carrying a believer out counts him out at once (review focus 4)")
	Kit.done(s)


static func _searchers(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	var h: ExodusDirector.Household = d.households[0]
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	Kit.run_for(s, ExodusDirector.HUNT_AFTER + DT)
	var out := h.sent
	var lead := (d.lamp(0).man as Person).ground_pos
	for v: Variant in h.searchers:
		var p := v as Person
		out = out and not p.inside and p.mind == Person.Mind.DUTY and p.anchor.distance_to(lead) < 1.5
	t.check(ids.has("hunt_0") and out and (s.banners as Array).has("THE TEMPLE SENDS SEARCHERS") and Kit.edged(d, "SEARCHER"),
		"%d s after the household comes out its two searchers leave the Temple for its lamp, pointed at" % roundi(ExodusDirector.HUNT_AFTER))
	for c: EscortDirector.Charge in h.members:
		c.escaped = true
	Kit.run_for(s, ExodusDirector.TICK + DT)
	var home := true
	for v: Variant in h.searchers:
		home = home and (v as Person).mind != Person.Mind.DUTY
	t.check(h.done and home and not d._watchers().has(h.searchers[0]), "the household done sends its searchers home: they watch no more")
	Kit.done(s)


static func _relief(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var dead: Variant = d.watch[1]
	var post := d._walkable(d.watch_posts[1])
	Kit.free_body(s, dead)
	Kit.run_for(s, ExodusDirector.RELIEF_AFTER + 2.0 * ExodusDirector.TICK + DT)
	var p: Variant = d.watch[1]
	t.check(p != dead and MissionDirector._alive(p) and (p as Person).profile.role == CitizenProfile.Role.WATCHMAN and (p as Person).anchor == post
		and d.reliefs == 1 and (s.banners as Array).has("A NEW WATCHMAN COMES FROM THE TEMPLE"),
		"a fallen gate watchman is replaced %d s later from the Temple's door" % roundi(ExodusDirector.RELIEF_AFTER))
	var w := d.watch[0]
	w.whisper(w.ground_pos + Vector2(3.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	w._wake()
	Kit.run_for(s, 2.0)
	var waited := w.mind != Person.Mind.DUTY
	Kit.run_for(s, ExodusDirector.RETURN_AFTER)
	t.check(waited and w.mind == Person.Mind.DUTY and w.anchor == d._walkable(d.watch_posts[0]),
		"a whispered watchman walks back %d s after he is calm, not before" % roundi(ExodusDirector.RETURN_AFTER))
	Kit.done(s)


static func _stone(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var house: Structure = (d.households[0] as ExodusDirector.Household).house
	(s.crowd as Crowd).fires.ignite(house, 1.0)
	Kit.run_for(s, ExodusDirector.TICK + DT)
	t.check(not (s.crowd as Crowd).fires.is_burning(house) and is_equal_approx(house.hp, house.max_hp), "a household's house only shakes and its fire goes out")
	var own := d._own_filters.duplicate()
	d.teardown()
	t.check(house.damage_filter == own[0], "teardown gives each house its own filter back")
	Kit.done(s)


static func _evacuated(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	_clear_watch(d)
	d._come_out(0)
	d._come_out(1)
	Kit.run_for(s, 1.0)
	var lead := d.lamp(1).man as Person
	lead.whisper(lead.ground_pos + Vector2(2.0, 0.0), MindWhisperFx.LINGER)
	var w := d.watch[2]
	w._recover(1.0)
	Kit.evacuate(s)
	Kit.run_for(s, 2.0 * ExodusDirector.TICK + DT)
	var none_fled := true
	for c: EscortDirector.Charge in (d.households[1] as ExodusDirector.Household).members:
		none_fled = none_fled and (c.man as Person).mind != Person.Mind.FLEE
	var south_in := true
	for c: EscortDirector.Charge in (d.households[2] as ExodusDirector.Household).members:
		south_in = south_in and (c.man as Person).inside
	t.check(none_fled and lead.mind == Person.Mind.WHISPERED and not lead._whisper_fled and w.mind == Person.Mind.DUTY
		and w.anchor == d._walkable(d.watch_posts[2]) and south_in,
		"the evacuation: the east household walks on, none flees; the recovering watchman walks back at once; the south household stays inside")
	Kit.done(s)


static func _tagged(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	var labels := Kit.labels(d)
	var waiting := "HOUSEHOLD - OUT BY %s" % UiTheme.clock(float(ExodusDirector.OUT_AT[0]))
	t.check(labels.has(waiting) and Kit.edged(d, waiting) and labels.has("POSTERN - WATCHED") and Kit.edged(d, "POSTERN - WATCHED")
		and labels.has("PATROL") and d.hint_phase() == "", "at the start: each household's time over its door, the gates watched, pointed at (%s)" % [labels])
	d._come_out(0)
	labels = Kit.labels(d)
	t.check(labels[0] == "LAMP - DO NOT KILL" and Kit.edged(d, "LAMP - DO NOT KILL"), "the lamp, steel blue, DO NOT KILL, pointed at")
	for v: Variant in d.watch.slice(0, 2):
		Kit.arrive(v as Person, (v as Person).ground_pos + Vector2(40.0, 40.0))
	t.check(Kit.labels(d).has("POSTERN - CLEAR"), "its watch gone, the postern reads clear")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The west household hides here. It comes out at %s: whisper its lamp to the postern, and the rest follow." % UiTheme.clock(float(ExodusDirector.OUT_AT[0]))
		and String(tour[1][1]) == "The gates. The Inquisition shuts the postern at %s, the Side Gate at %s and the Main Gate at %s." % [
			UiTheme.clock(float(ExodusDirector.SHUT_AT[0])), UiTheme.clock(float(ExodusDirector.SHUT_AT[1])), UiTheme.clock(float(ExodusDirector.SHUT_AT[2]))]
		and String(tour[2][1]) == "The Temple. Inquisitors take any believer they catch here. Ten must get out.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("exodus") == "THE FAITHFUL ARE OUT" and ResultsScreen.ACT_TITLES.get("exodus_few") == "TOO FEW ARE LEFT"
		and ResultsScreen.ACT_TITLES.get("gates_shut") == "THE GATES ARE SHUT" and MissionHints.line("exodus", "waiting").contains(MissionHints.SECONDS),
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: ExodusDirector = s.d
	d._come_out(0)
	d._send(0)
	Kit.run_for(s, 0.2)
	for c: EscortDirector.Charge in (d.households[0] as ExodusDirector.Household).members.slice(0, 2):
		Kit.free_body(s, c.man)
	for v: Variant in d._watchers():
		if MissionDirector._alive(v):
			Kit.free_body(s, v)
	d.tags()
	d.hint_phase()
	d.hud_line()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(d.left_count() == 10 and d.lost_reason() == "", "two believers and every watcher freed: borne, the count right (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_exodus.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Expected: a parse error or FAILs in `test_exodus`.

- [ ] **Step 3: The director.** Create `src/game/mission/exodus_director.gd`:

```gdscript
class_name ExodusDirector
extends EscortDirector
## Exodus (v0.11 M6, Tier 5, mission spec §2; Escort with many charges, Decision 222): the god leads three households of believers out of
## Aldermere while the Inquisition shuts the gates one by one. Twelve believers (BELIEVERS), four to a household, wait inside their
## house -- the dwelling nearest its point whose door the street reaches, quiet (no beat or gate post within QUIET of its door), stone
## tonight -- until their time on the chain (OUT_AT, or CHAIN after the one before is done: each of its four out, taken or dead). Out,
## they hold at the door and move by the god's hand alone at BELIEVER_PACE; a household follows its lamp-bearer in file (plan decision
## 282), the lamp passing on (lamp()). Each is a charge on the Escort type's Charge record. The watchers -- two patrols, two watchmen at
## each gate's mouth (no guard change: watch_changes false), and HOUNDS searchers per household sent HUNT_AFTER after it comes out --
## are lay citizens made watchmen: a watcher within SIGHT seizes a believer and marches him to the Temple's door, where he is taken
## inside; a watcher held by the god, frightened or indoors sees nothing, and one marching a believer sees no other. The gates shut at
## SHUT_AT; a shut gate is no way out. Ten out wins (EscortObjective, need NEED); too few left, or the last gate shut with fewer than ten
## out, loses at once (lost_reason()). Every held person is kept from the town's flight by MissionDirector._hold_all().

## One household (v0.11 M6): a plain record, so the director holds no cycle.
class Household:
	extends RefCounted
	## Its words ("the west household") and its name on the tags ("WEST").
	var words := ""
	var name := ""
	## Its house, and the door the street reaches.
	var house: Structure
	var door := Vector2.INF
	## The gate it is bound for (an index into gates).
	var gate := 0
	## Its four believers' Charge records, in order.
	var members: Array = []
	## Out, and when; done, and when (the night's real seconds, -1 until then).
	var out := false
	var out_at := -1.0
	var done := false
	var done_at := -1.0
	## Its lamp's footsteps, oldest first (plan decision 282).
	var trail: Array[Vector2] = []
	## The way out its lamp got out by, where the file walks on to; Vector2.INF until then.
	var out_to := Vector2.INF
	## Its searchers (Variants: any may be freed), and whether they were sent.
	var searchers: Array = []
	var sent := false


## One gate (v0.11 M6): a plain record.
class Gate:
	extends RefCounted
	## Its name on the tags ("POSTERN") and in words ("the postern").
	var label := ""
	var words := ""
	## Its mouth inside the wall, and its way out beyond it.
	var mouth := Vector2.INF
	var way_out := Vector2.INF
	## When it shuts (the timeline's seconds), and whether it has.
	var shut_at := 0.0
	var shut := false


## The households, in the order they come out: each house is the dwelling nearest its point; its words, its name, its gate (v0.11 M6).
const HOUSE_POINTS := [Vector2(-10.5, 7.0), Vector2(7.5, 4.5), Vector2(-2.5, 10.5)]
const HOUSE_WORDS := ["the west household", "the east household", "the south household"]
const HOUSE_NAMES := ["WEST", "EAST", "SOUTH"]
## The gates: the postern, the Side Gate, the Main Gate -- their mouths, ways out, names, words, and the way along the wall at each.
const GATE_MOUTHS := [Vector2(-5.75, 14.6), Vector2(14.4, 9.0), Vector2(2.7, 14.4)]
const GATE_EXITS := [Vector2(-5.75, 17.4), Vector2(17.6, 9.0), Vector2(2.7, 17.6)]
const GATE_LABELS := ["POSTERN", "SIDE GATE", "MAIN GATE"]
const GATE_WORDS := ["the postern", "the Side Gate", "the Main Gate"]
const GATE_ALONG := [Vector2.RIGHT, Vector2.DOWN, Vector2.RIGHT]
## The Temple's door, where a seized believer is taken and the searchers and reliefs come from (v0.11 M6).
const TEMPLE_DOOR := LostLambDirector.TEMPLE_DOOR
## The patrols' beats (v0.11 M6): the long west street; the east-west street short of the south household's door.
const BEATS := [[Vector2(-6.25, 0.0), Vector2(-6.25, 12.0)], [Vector2(1.0, 9.0), Vector2(12.0, 9.0)]]
## Mission spec §2's numbers (v0.11 M6), first guesses, tuned by Step 9's gate in this order: CHAIN (20-30), BELIEVER_PACE (0.4-0.55),
## the houses (12-16 units of street from their gates), OUT_AT[0] (10-30), HUNT_AFTER (20-45); HUNT_AFTER down if doing nothing does not
## lose. The households; how many must get out; their times and chain; their pace; the file.
const BELIEVERS := 12
const PER_HOUSE := 4
const NEED := 10
const OUT_AT := [15.0, 105.0, 195.0]
const CHAIN := 25.0
const BELIEVER_PACE := 0.45
const FOLLOW_GAP := 0.9
const FOLLOW_REACH := 4.0
const REJOIN := 2.0
const TRAIL_MAX := 40
## The watch (v0.11 M6): a patrol's size; each gate's two posts, POST_GAP apart; return, relief and the reliefs in a night; the searchers'
## delay and number; how quiet a household's door is.
const PATROL_SIZE := 2
const GATE_WATCH := 2
const POST_GAP := 2.4
const RETURN_AFTER := 20.0
const RELIEF_AFTER := 30.0
const RELIEFS := 6
const HUNT_AFTER := 30.0
const HOUNDS := 2
const QUIET := 3.5
## The gates' shutting (v0.11 M6), and how long before it a gate's tag warns of it.
const SHUT_AT := [150.0, 225.0, 300.0]
const SHUT_WARN := 60.0
## How far round its door a household stands when it comes out; how many dwellings a house's choice weighs; how near a believer the
## searchers count as on his household (the "hounds" hint) (v0.11 M6).
const OUT_RING := 0.6
const HOUSE_TRIES := 12
const HOUNDS_NEAR := 6.0
## Where the camera rests (v0.11 M6, Decision 247): the west household's door and the postern left of the centre, the Main Gate at the
## bottom.
const CAMERA_AT := Vector2(-7.0, 9.0)
## The map tags' colours a believer's base does not name (v0.11 M6): not yet grey, a shutting gate orange.
const MARK_NOT_YET := Color("9a948a")
const MARK_PLACE := Color("ff9a3a")

## The households and the gates (v0.11 M6).
var households: Array = []
var gates: Array = []
## The Temple and its door (v0.11 M6).
var temple: Structure
var temple_door := Vector2.INF
## How many gate reliefs came this night (v0.11 M6).
var reliefs := 0
## Each house's own damage filter before tonight (v0.11 M6).
var _own_filters: Array[Callable] = []
## Charge -> its household's index; instance id -> household index while appointing; Charge -> in the file (v0.11 M6).
var _home := {}
var _home_of := {}
var _in_file := {}
## Instance id -> the second a watcher first stood back on his feet (plan decision 285); the second the recall at once ends.
var _calm_since := {}
var _recall_until := -1.0
## Each gate post's watchman's fall, the second (-1 while he stands) (v0.11 M6).
var _fallen_since: Array[float] = []
## Each household's road to its gate's way out, cached by gate (v0.11 M6, for the scripted player).
var _roads := {}
## Seconds to the next look (v0.11 M6).
var _keep_in := 0.0


## The plan (v0.11 M6): the Gaze, no guard change, the Temple, the gates and their posts, the beats, the households' houses.
func _plan() -> void:
	gaze = GazeMeter.new()
	watch_changes = false
	temple_door = _walkable(TEMPLE_DOOR)
	return_to = TEMPLE_DOOR
	guardhouse = TEMPLE_DOOR
	gate_at = GATE_MOUTHS[2]
	exit_at = GATE_EXITS[2]
	hunt_at = -1.0
	charge_label = "LAMP"
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple":
			temple = s
			break
	for g in GATE_MOUTHS.size():
		var gate := Gate.new()
		gate.label = String(GATE_LABELS[g])
		gate.words = String(GATE_WORDS[g])
		gate.mouth = _walkable(GATE_MOUTHS[g])
		gate.way_out = _walkable(GATE_EXITS[g])
		gate.shut_at = float(SHUT_AT[g])
		gates.append(gate)
		for k in GATE_WATCH:
			watch_posts.append(_walkable(gate.mouth + (GATE_ALONG[g] as Vector2) * POST_GAP * (float(k) - 0.5)))
	for b: Array in BEATS:
		var line := PackedVector2Array()
		for at: Vector2 in b:
			line.append(_walkable(at))
		beats.append(line)
	patrol_size = PATROL_SIZE
	var skip: Array = []
	for i in HOUSE_POINTS.size():
		var h := Household.new()
		h.words = String(HOUSE_WORDS[i])
		h.name = String(HOUSE_NAMES[i])
		h.gate = i
		h.house = _quiet_house(HOUSE_POINTS[i], gates[i].mouth, skip)
		if h.house == null:
			push_warning("ExodusDirector: no house for %s" % h.words)
			continue
		skip.append(h.house)
		h.door = _open_door(h.house, (gates[i] as Gate).mouth)
		households.append(h)


## The dwelling nearest `at` for a household bound for `mouth` (v0.11 M6): its door the street reaches from the gate, quiet (no beat and
## no gate post within QUIET of the door), none of `skip`, never a wish's (_house_near()); the first reachable one when none tried is
## quiet; null for none.
func _quiet_house(at: Vector2, mouth: Vector2, skip: Array) -> Structure:
	var tried := skip.duplicate()
	var first: Structure = null
	for k in HOUSE_TRIES:
		var h := _house_near(at, tried)
		if h == null:
			break
		tried.append(h)
		var door := _open_door(h, mouth)
		if door == Vector2.INF:
			continue
		if first == null:
			first = h
		if _quiet(door):
			return h
	return first


## No beat passes and no gate post stands within QUIET of `door` (v0.11 M6). Only reads.
func _quiet(door: Vector2) -> bool:
	for p: Vector2 in watch_posts:
		if p.distance_to(door) <= QUIET:
			return false
	for b: Array in BEATS:
		if Geometry2D.get_closest_point_to_segment(door, b[0], b[1]).distance_to(door) <= QUIET:
			return false
	return true


## The Escort type's setup, then the searchers inside the Temple, the houses stone, the households and the shuttings on the strip
## (v0.11 M6).
func _begin() -> void:
	super()
	for h: Household in households:
		for k in HOUNDS:
			var near := _lay_near(temple_door, 1, _in_use(charge))
			if near.is_empty():
				break
			var p := near[0]
			_watchman(p)
			_set_down(p, temple_door)
			p.go_duty(temple_door)
			_take_inside(p, temple)
			h.searchers.append(p)
		_own_filters.append(h.house.damage_filter)
		h.house.damage_filter = _stone
	for i in watch.size():
		_fallen_since.append(-1.0)
	for i in households.size():
		timeline.add(float(OUT_AT[i]), "out_%d" % i, "The %s comes out" % (households[i] as Household).words.trim_prefix("the "),
			_come_out.bind(i), func() -> bool: return not (households[i] as Household).out)
	for g in gates.size():
		timeline.add(float(SHUT_AT[g]), "shut_%d" % g, "The Inquisition shuts %s" % (gates[g] as Gate).words, _shut.bind(g))


## The twelve believers (v0.11 M6): the four lay citizens nearest each household's door.
func _appoint_charges() -> Array[Person]:
	var out: Array[Person] = []
	for i in households.size():
		for p in _lay_near((households[i] as Household).door, PER_HOUSE, out):
			out.append(p)
			_home_of[p.get_instance_id()] = i
	return out


## Believer `c` set down at his household's door at BELIEVER_PACE, on duty, and taken inside its house (v0.11 M6).
func _place_charge(c: Charge) -> void:
	var p := c.man as Person
	var i := int(_home_of.get(p.get_instance_id(), 0))
	var h: Household = households[i]
	_home[c] = i
	h.members.append(c)
	_set_down(p, h.door)
	p.pace *= BELIEVER_PACE
	c.hold_at = h.door
	p.go_duty(h.door)
	_take_inside(p, h.house)


## `p` in the watch cloak and lantern (v0.11 M6).
func _watchman(p: Person) -> void:
	p.profile.role = CitizenProfile.Role.WATCHMAN


## Everyone at the night's work (v0.11 M6): the Escort type's (every believer, the watch, the patrols), and the searchers.
func _in_use(c: Person) -> Array:
	var out := super(c)
	for h: Household in households:
		out.append_array(h.searchers)
	return out


## Each gate's watch (v0.11 M6): the lay citizens nearest its posts, made watchmen and set down there.
func _appoint_watch(c: Person, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var post := _walkable(watch_posts[i])
		var crew := _lay_near(post, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_watchman(crew[0])
		_set_down(crew[0], post)
		out.append(crew[0])
	return out


## A patrol (v0.11 M6): the lay citizens nearest its beat's first point, made watchmen and set down there.
func _appoint_patrol(c: Person, beat: PackedVector2Array, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for i in n:
		var spot := _ring_spot(beat[0], 0.5, i, n)
		var crew := _lay_near(spot, 1, _in_use(c) + out)
		if crew.is_empty():
			break
		_watchman(crew[0])
		_set_down(crew[0], spot)
		out.append(crew[0])
	return out


## A lay watchman goes on duty at his post (v0.11 M6, The Prisoner's way).
func _post_to(p: Person, at: Vector2, _hurry: bool) -> void:
	p.go_duty(at)


## A lay watchman takes his post or beat again (v0.11 M6, plan decision 285): on duty, always; back on his feet, RETURN_AFTER after he
## first stood so -- at once in the two looks after the evacuation began; never a seizer, a searcher or one indoors.
func _takes_post(p: Person) -> bool:
	if p.inside or _seizing(p) or _is_searcher(p):
		return false
	var id := p.get_instance_id()
	if p.mind == Person.Mind.DUTY:
		_calm_since.erase(id)
		return true
	if not p.mind in RECALL_MINDS:
		_calm_since.erase(id)
		return false
	if _clock <= _recall_until:
		return true
	if not _calm_since.has(id):
		_calm_since[id] = _clock
	return _clock - float(_calm_since[id]) >= RETURN_AFTER


## `v` marches a believer now (v0.11 M6).
func _seizing(v: Variant) -> bool:
	for c in charges:
		if c.held and c.seizer == v:
			return true
	return false


## `v` is one of the searchers (v0.11 M6).
func _is_searcher(v: Variant) -> bool:
	for h: Household in households:
		if h.searchers.has(v):
			return true
	return false


## Every watcher (v0.11 M6): the gates' watch, the patrols, and the searchers sent out by a household not yet done. Untyped: any may be
## freed.
func _watchers() -> Array:
	var out: Array = []
	out.append_array(watch)
	for squad: Array in patrols:
		out.append_array(squad)
	for h: Household in households:
		if h.sent and not h.done:
			out.append_array(h.searchers)
	return out


## A believer has reached a way out (v0.11 M6, Decision 228): any open gate's.
func _exit_reached(c: Charge) -> bool:
	var at := (c.man as Person).ground_pos
	for g: Gate in gates:
		if not g.shut and at.distance_to(g.way_out) <= ESCAPE_REACH:
			return true
	return false


## The nearest open gate's way out to `at`, or Vector2.INF with every gate shut (v0.11 M6).
func _open_exit_near(at: Vector2) -> Vector2:
	var best := Vector2.INF
	for g: Gate in gates:
		if not g.shut and (best == Vector2.INF or g.way_out.distance_to(at) < best.distance_to(at)):
			best = g.way_out
	return best


## Free (v0.11 M6): a follower in file holds at his place in it (_file_spot()); then the Escort type's rule.
func _step_free(c: Charge) -> void:
	if (c.man as Person).inside:
		return
	var spot := _file_spot(c)
	if spot != Vector2.INF:
		c.hold_at = spot
	super(c)


## Held (v0.11 M6): the Escort type's march; delivered, he goes inside the Temple (plan decision 283).
func _step_held(c: Charge) -> void:
	super(c)
	if c.taken and _alive(c.man) and not (c.man as Person).inside:
		_take_inside(c.man as Person, temple)


## Out (v0.11 M6): a household's lamp getting out sends its file on to his way out (plan decision 282); then the Escort type's.
func _escape(c: Charge) -> void:
	var i := int(_home.get(c, -1))
	if i >= 0 and lamp(i) == c:
		(households[i] as Household).out_to = _open_exit_near((c.man as Person).ground_pos)
	super(c)


## Household `i`'s lamp-bearer (v0.11 M6, plan decision 287): its first member in town, alive, out of doors, not out, not taken and not
## held by a seizer; null for none.
func lamp(i: int) -> Charge:
	for c: Charge in (households[i] as Household).members:
		if not _resolved(c) and not c.held and not (c.man as Person).inside:
			return c
	return null


## Household `i`'s followers in file now (v0.11 M6), in order. Only reads.
func followers(i: int) -> Array:
	var out := []
	var lead := lamp(i)
	for c: Charge in (households[i] as Household).members:
		if c != lead and bool(_in_file.get(c, false)) and not _resolved(c) and not c.held and not (c.man as Person).inside:
			out.append(c)
	return out


## Where believer `c` holds in his household's file (v0.11 M6, plan decision 282): its lamp's way out once he got out; else his place
## FOLLOW_GAP x (his place) back along the lamp's trail while within FOLLOW_REACH of it; Vector2.INF when he is not in file, is the lamp,
## or is too far.
func _file_spot(c: Charge) -> Vector2:
	if not bool(_in_file.get(c, false)):
		return Vector2.INF
	var i := int(_home.get(c, -1))
	if i < 0:
		return Vector2.INF
	var h: Household = households[i]
	if h.out_to != Vector2.INF:
		return h.out_to
	var lead := lamp(i)
	if lead == null or lead == c:
		return Vector2.INF
	var lp := (lead.man as Person).ground_pos
	if (c.man as Person).ground_pos.distance_to(lp) > FOLLOW_REACH:
		return Vector2.INF
	var place := followers(i).find(c)
	return _trail_point(h, lp, FOLLOW_GAP * float(maxi(place, 0) + 1))


## The point `back` along household `h`'s trail behind `from` (v0.11 M6), on walkable ground; the trail's oldest point if it is shorter.
func _trail_point(h: Household, from: Vector2, back: float) -> Vector2:
	var at := from
	var left := back
	for k in range(h.trail.size() - 1, -1, -1):
		var nxt: Vector2 = h.trail[k]
		var seg := at.distance_to(nxt)
		if seg >= left:
			return _walkable(at.move_toward(nxt, left))
		left -= seg
		at = nxt
	return _walkable(at)


## Household `i` comes out (v0.11 M6): its four on a ring round the door, on duty, in file; its searchers on the strip HUNT_AFTER on.
func _come_out(i: int) -> void:
	var h: Household = households[i]
	if h.out:
		return
	h.out = true
	h.out_at = _clock
	h.trail.clear()
	for k in h.members.size():
		var c: Charge = h.members[k]
		if not _alive(c.man) or not (c.man as Person).inside or c.taken:
			continue
		var p := c.man as Person
		var spot := _ring_spot(h.door, OUT_RING, k, h.members.size())
		_bring_out(p, spot)
		_keep_from_flight(p, true)
		p.go_duty(spot)
		c.hold_at = spot
		_in_file[c] = true
	timeline.add(timeline.elapsed() + HUNT_AFTER / timeline.stretch_factor(), "hunt_%d" % i, "The Temple sends searchers", _send.bind(i),
		func() -> bool: return not (households[i] as Household).done)


## Household `i`'s searchers leave the Temple's door for its lamp (v0.11 M6).
func _send(i: int) -> void:
	var h: Household = households[i]
	if h.sent or h.done:
		return
	h.sent = true
	for v: Variant in h.searchers:
		if _alive(v) and (v as Person).inside:
			_bring_out(v as Person, temple_door)
			_keep_from_flight(v as Person, true)
	_step_hunters()


## Gate `g` shuts (v0.11 M6): no way out from now on.
func _shut(g: int) -> void:
	(gates[g] as Gate).shut = true


## The second household `i` comes out at the latest (v0.11 M6): its own time, or CHAIN after the one before is done if that is sooner.
func out_due(i: int) -> float:
	var at := float(OUT_AT[i]) * timeline.stretch_factor()
	if i > 0 and (households[i - 1] as Household).done:
		at = minf(at, (households[i - 1] as Household).done_at + CHAIN)
	return at


## Seconds until household `i` comes out at the latest (v0.11 M6); 0 once it has.
func due_in(i: int) -> float:
	return 0.0 if (households[i] as Household).out else maxf(out_due(i) - _clock, 0.0)


## The current household: the first out and not done, or -1 (v0.11 M6).
func current() -> int:
	for i in households.size():
		var h: Household = households[i]
		if h.out and not h.done:
			return i
	return -1


## The next household still inside, or -1 (v0.11 M6).
func upcoming() -> int:
	for i in households.size():
		if not (households[i] as Household).out:
			return i
	return -1


## Gate `g` is watched (v0.11 M6): one of its watchmen would see a believer at its mouth. Only reads.
func gate_watched(g: int) -> bool:
	for k in watch.size():
		if k / GATE_WATCH == g and _watching(watch[k]) and (watch[k] as Person).ground_pos.distance_to((gates[g] as Gate).mouth) <= SIGHT + 1.0:
			return true
	return false


## Household `i`'s searchers out of doors and watching (v0.11 M6). Only reads.
func searchers_out(i: int) -> Array[Person]:
	var out: Array[Person] = []
	var h: Household = households[i]
	if not h.sent or h.done:
		return out
	for v: Variant in h.searchers:
		if _watching(v):
			out.append(v as Person)
	return out


## Household `i`'s road from its door to the nearest open gate's way out (v0.11 M6, for the scripted player): the walk grid's path,
## cached per gate; door, mouth and way out with no grid.
func road(i: int) -> Array:
	var h: Household = households[i]
	var exit := _open_exit_near(h.door)
	if exit == Vector2.INF:
		return [h.door]
	var key := "%d:%s" % [i, exit]
	if not _roads.has(key):
		var line: Array = [h.door]
		var path := crowd._grid.path(h.door, exit) if crowd._grid != null else PackedVector2Array()
		if path.is_empty():
			for g: Gate in gates:
				if g.way_out == exit:
					line.append(g.mouth)
		else:
			line.append_array(Array(path))
		line.append(exit)
		_roads[key] = line
	return _roads[key]


## One step (v0.11 M6): the Escort type's (each believer, the watch's posts, the patrols, the searchers), the Gaze's deaths, the
## households' chain, then every TICK a look of its own: everyone held kept from the flight, the households and their files, the gate
## reliefs, the houses' fires.
func step(delta: float) -> void:
	super(delta)
	gaze.judge_deaths(crowd)
	_chain()
	_keep_in -= delta
	if _keep_in > 0.0:
		return
	_keep_in = TICK
	var evacuating := _evacuation_began()
	if evacuating:
		_recall_until = _clock + 2.0 * TICK
	_keep_held(evacuating)
	_households()
	_relieve_watch()
	_quench()


## Each household still inside whose chained time has come comes out (v0.11 M6); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, households.size()):
		var h: Household = households[i]
		if not h.out and (households[i - 1] as Household).done and _clock >= out_due(i):
			rules.banner.emit(("The %s comes out" % h.words.trim_prefix("the ")).to_upper())
			_come_out(i)


## Everyone held is kept from the town's flight by the one rule (v0.11 M6, plan decision 288): every watcher and searcher, and every
## believer still in the town; the base and _takes_post() then put each on duty again.
func _keep_held(evacuating: bool) -> void:
	var people: Array = _watchers()
	for h: Household in households:
		for v: Variant in h.searchers:
			if not people.has(v):
				people.append(v)
	for c in charges:
		if not _resolved(c):
			people.append(c.man)
	_hold_all(people, evacuating)


## Each household out (v0.11 M6): done once each of its four is out, taken or dead -- its searchers home, the next one's chained time on
## the strip; else its lamp's trail grows, a follower whispered on his own leaves the file and one within REJOIN of the lamp rejoins it.
func _households() -> void:
	for i in households.size():
		var h: Household = households[i]
		if not h.out or h.done:
			continue
		var all := true
		for c: Charge in h.members:
			all = all and _resolved(c)
		if all:
			h.done = true
			h.done_at = _clock
			for v: Variant in h.searchers:
				if _alive(v) and not (v as Person).inside and (v as Person).mind == Person.Mind.DUTY and not _seizing(v):
					crowd.off_duty(v as Person)
			if i + 1 < households.size():
				timeline.expect("out_%d" % (i + 1), out_due(i + 1))
			continue
		var lead := lamp(i)
		if lead != null:
			var at := (lead.man as Person).ground_pos
			if h.trail.is_empty() or h.trail.back().distance_to(at) >= FOLLOW_GAP * 0.5:
				h.trail.append(at)
				if h.trail.size() > TRAIL_MAX:
					h.trail.remove_at(0)
		for c: Charge in h.members:
			if _resolved(c) or c.held or c == lead or (c.man as Person).inside:
				continue
			var p := c.man as Person
			if p.mind == Person.Mind.WHISPERED:
				_in_file[c] = false
			elif not bool(_in_file.get(c, false)) and lead != null and p.ground_pos.distance_to((lead.man as Person).ground_pos) <= REJOIN:
				_in_file[c] = true


## Each household's searchers sent and not done keep walking to its lamp, a step apart (v0.11 M6, in place of the Escort type's single
## charge's): one back on his feet goes after it again; a seizer, one held by the god or frightened is left be.
func _step_hunters() -> void:
	for i in households.size():
		var h: Household = households[i]
		if not h.sent or h.done:
			continue
		var lead := lamp(i)
		if lead == null:
			continue
		var to := (lead.man as Person).ground_pos
		for k in h.searchers.size():
			var v: Variant = h.searchers[k]
			if not _alive(v) or _seizing(v) or (v as Person).inside:
				continue
			var p := v as Person
			var spot := to + Vector2(0.5 * (-1.0 if k % 2 == 0 else 1.0), 0.0)
			if p.mind == Person.Mind.DUTY or p.mind in RECALL_MINDS:
				if p.mind != Person.Mind.DUTY or p.anchor.distance_to(spot) > 1.0:
					p.go_duty(spot)


## A fallen gate watchman is replaced RELIEF_AFTER after he fell by one from the Temple's door, at most RELIEFS in a night; with none who
## can reach the post the search backs off RELIEF_AFTER (v0.11 M6, plan decision 286).
func _relieve_watch() -> void:
	for i in watch.size():
		var v: Variant = watch[i]
		if _alive(v):
			_fallen_since[i] = -1.0
			continue
		if _fallen_since[i] < 0.0:
			_fallen_since[i] = _clock
			continue
		if _clock - _fallen_since[i] < RELIEF_AFTER or reliefs >= RELIEFS:
			continue
		var post := _walkable(watch_posts[i])
		var p := _relief_from_temple(post)
		if p == null:
			_fallen_since[i] = _clock
			continue
		_watchman(p)
		if crowd._fled_all:
			_keep_from_flight(p, true)  # chosen once the town is running: never one of the flight
		watch[i] = p
		p.go_duty(post)
		reliefs += 1
		_fallen_since[i] = -1.0
		rules.banner.emit("A NEW WATCHMAN COMES FROM THE TEMPLE")


## The lay citizen nearest the Temple's door with a way on foot to `post`, of the REACH_PICKS nearest, none at the night's work; null for
## none (v0.11 M6).
func _relief_from_temple(post: Vector2) -> Person:
	for p in _lay_near(temple_door, REACH_PICKS, _in_use(charge)):
		if crowd._grid == null or not crowd._grid.path(p.ground_pos, post).is_empty():
			return p
	return null


## Structure.damage_filter for a household's house tonight (v0.11 M6): stone, a blow only shakes it.
func _stone(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(HuntDirector.SHAKE)


## Any fire on a household's house is put out (v0.11 M6): no stray power empties a household.
func _quench() -> void:
	if crowd.fires == null:
		return
	for h: Household in households:
		if is_instance_valid(h.house) and crowd.fires.is_burning(h.house):
			crowd.fires._put_out(h.house, true)


## Why the night is lost now (v0.11 M6, Decisions 223 and 228): "exodus_few" once the believers out and those left fall below NEED;
## "gates_shut" once every gate is shut with fewer than NEED out; else "".
func lost_reason() -> String:
	if out_count() + left_count() < NEED:
		return "exodus_few"
	var all_shut := not gates.is_empty()
	for g: Gate in gates:
		all_shut = all_shut and g.shut
	if all_shut and out_count() < NEED:
		return "gates_shut"
	return ""


## "Lead them out 3 / 10, 2 to spare" (v0.11 M6).
func hud_line() -> String:
	return "Lead them out %d / %d, %d to spare" % [out_count(), NEED, maxi(out_count() + left_count() - NEED, 0)]


## The banners (v0.11 M6).
func _opening_banner() -> String:
	return "EXODUS"


func _caught_banner() -> String:
	return "A BELIEVER IS TAKEN"


func _freed_banner() -> String:
	return "THE BELIEVER IS FREE"


func _taken_banner() -> String:
	return "THE INQUISITION TAKES A BELIEVER"


func _escape_banner() -> String:
	return "A BELIEVER GETS OUT"


## The map tags, most important first (v0.11 M6, mission spec §2): each believer seized, TAKEN TO THE TEMPLE, his seizer TAKING HIM IN and
## the Temple's door, red, pointed at; each lamp, LAMP - DO NOT KILL, steel blue, pointed at, and a steel-blue diamond on each other
## believer out; each household still inside, HOUSEHOLD - OUT BY its sooner time, grey, pointed at; each gate, watched, clear, shutting or
## shut, pointed at; SEARCHER on each searcher out, pointed at; PATROL on each patrol's first watchman and a red diamond on the rest and
## on each gate's watch.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or out_count() >= NEED:
		return out
	var marched := false
	for c in charges:
		if not c.held or _resolved(c):
			continue
		out.append(MapTag.person((c.man as Person).ground_pos, MARK_WATCHED, "TAKEN TO THE TEMPLE", true))
		if _alive(c.seizer):
			out.append(MapTag.person((c.seizer as Person).ground_pos, MARK_WATCHED, "TAKING HIM IN", true))
		marched = true
	for i in households.size():
		var h: Household = households[i]
		if not h.out:
			out.append(MapTag.place(h.door, MARK_NOT_YET, "HOUSEHOLD - OUT BY %s" % UiTheme.clock(out_due(i)), h.house.height, true))
			continue
		var lead := lamp(i)
		for c: Charge in h.members:
			if _resolved(c) or c.held or (c.man as Person).inside:
				continue
			var p := c.man as Person
			out.append(MapTag.person(p.ground_pos, MARK_CHARGE, "LAMP - DO NOT KILL" if c == lead else "", c == lead))
	if marched:
		out.append(MapTag.place(temple_door, MARK_WATCHED, "TEMPLE", 0.0, true))
	for g in gates.size():
		var gate: Gate = gates[g]
		var shut_at := gate.shut_at * timeline.stretch_factor()
		if gate.shut:
			out.append(MapTag.place(gate.mouth, MARK_NOT_YET, "%s - SHUT" % gate.label, 0.0, true))
		elif shut_at - _clock <= SHUT_WARN:
			out.append(MapTag.place(gate.mouth, MARK_PLACE, "%s - SHUT AT %s" % [gate.label, UiTheme.clock(shut_at)], 0.0, true))
		elif gate_watched(g):
			out.append(MapTag.place(gate.mouth, MARK_WATCHED, "%s - WATCHED" % gate.label, 0.0, true))
		else:
			out.append(MapTag.place(gate.mouth, MARK_CLEAR, "%s - CLEAR" % gate.label, 0.0, true))
	for h: Household in households:
		if not h.sent or h.done:
			continue
		for v: Variant in h.searchers:
			if _alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "SEARCHER", true))
	for squad: Array in patrols:
		var named := false
		for v: Variant in squad:
			if _alive(v) and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "" if named else "PATROL"))
				named = true
	for v: Variant in watch:
		if _alive(v) and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M6, plan decision 303): "caught" while a believer is marched; for the current household, "hounds" while its
## searchers are within HOUNDS_NEAR of one of its own, "shut" once its gate is shut, "gate" while its lamp nears its watched gate;
## "waiting" between households (not before the first); else "".
func hint_phase() -> String:
	if lost_reason() != "" or out_count() >= NEED:
		return ""
	for c in charges:
		if c.held and not _resolved(c):
			return "caught"
	var cur := current()
	if cur < 0:
		return "waiting" if upcoming() > 0 else ""
	var h: Household = households[cur]
	for p in searchers_out(cur):
		for c: Charge in h.members:
			if not _resolved(c) and not (c.man as Person).inside and (c.man as Person).ground_pos.distance_to(p.ground_pos) <= HOUNDS_NEAR:
				return "hounds"
	if (gates[h.gate] as Gate).shut:
		return "shut"
	var lead := lamp(cur)
	if lead != null and (lead.man as Person).ground_pos.distance_to((gates[h.gate] as Gate).mouth) <= NEAR_GATE and gate_watched(h.gate):
		return "gate"
	return ""


## The seconds the hint counts down (v0.11 M6): in "waiting", until the next household comes out at the latest; else 0.
func hint_seconds() -> float:
	return due_in(upcoming()) if hint_phase() == "waiting" else 0.0


## The tour (v0.11 M6, mission spec §2): the west household's door, the postern, the Temple's door.
func tour() -> Array:
	var out := []
	if not households.is_empty():
		out.append([(households[0] as Household).door, "The west household hides here. It comes out at %s: whisper its lamp to the postern, and the rest follow." % UiTheme.clock(float(OUT_AT[0]))])
	if not gates.is_empty():
		out.append([(gates[0] as Gate).mouth, "The gates. The Inquisition shuts the postern at %s, the Side Gate at %s and the Main Gate at %s." % [
			UiTheme.clock(float(SHUT_AT[0])), UiTheme.clock(float(SHUT_AT[1])), UiTheme.clock(float(SHUT_AT[2]))]])
	out.append([temple_door, "The Temple. Inquisitors take any believer they catch here. Ten must get out."])
	return out


## What the results show (v0.11 M6): the believers out and taken, the seizures, the reliefs, the Gaze.
func report() -> Dictionary:
	var taken_n := 0
	for c in charges:
		taken_n += 1 if c.taken else 0
	return {"out": out_count(), "taken": taken_n, "seizures": seizures, "reliefs": reliefs, "gaze": gaze.value}


## Each house's own filter back, then the Escort type's (v0.11 M6).
func teardown() -> void:
	for i in mini(households.size(), _own_filters.size()):
		var h: Household = households[i]
		if is_instance_valid(h.house):
			h.house.damage_filter = _own_filters[i]
	super()
```

- [ ] **Step 4: The mission.** In `src/game/mission/mission_book.gd`, `tier_missions()` gains `exodus()` at its end, and after
  `lantern_eye()` add:

```gdscript
## Exodus (v0.11 M6, Tier 5, mission spec §2 and §8 row 24): lead ten of twelve believers, in three households that come out one at a time,
## out of the town before the Inquisition shuts the last gate (ExodusDirector, the Escort type with many charges).
static func exodus() -> MissionDef:
	var m := _tier5(EXODUS, "Exodus", PackedStringArray(["The Inquisition comes for your believers tonight.",
		"Lead ten out before the gates are shut."]))
	m.goal = "Lead ten of your twelve believers out of Aldermere before the Inquisition shuts the last gate at %s" % UiTheme.clock(
		float(ExodusDirector.SHUT_AT[2]))
	m.goal_label = "The faithful are out"
	m.lose = "Too few are left to make ten, the last gate shuts, Halcyon's Gaze fills, or dawn comes"
	m.camera_at = ExodusDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["whisper", "doom", "discord", "wisp"])
	m.director = ExodusDirector
	m.mission_tags = PackedStringArray(["shuts_gates"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [EscortObjective.new("Lead them out", "exodus", "exodus_taken", "exodus_dead", ExodusDirector.NEED),
			GazeObjective.new(), ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

  (`mission_tags` here only matters off the board; `TierBook.board()` sets the board's from `MISSION_TAGS` in Task 9.)

- [ ] **Step 5: The hints and the titles.**
  - In `mission_hints.gd`'s `LINES` add:

```gdscript
	"exodus": "Whisper each household's lamp (blue) to an open gate: the rest follow. Inquisitors (red) seize believers on sight. Ten must get out. Do not kill them.",
	"exodus.caught": "A believer is taken to the Temple. Whisper, Discord or strike the man taking him (red).",
	"exodus.hounds": "The Temple's searchers (red) follow the household. Strike them or turn them before they see it.",
	"exodus.gate": "Inquisitors (red) watch the gate. Whisper them off or strike them, then send the household through.",
	"exodus.shut": "That gate is shut. Lead the household to another open gate.",
	"exodus.waiting": "The next household comes out in {n} s. Clear its road and its gate of Inquisitors (red).",
```

  - `ACT_TITLES` gains `"exodus": "THE FAITHFUL ARE OUT", "exodus_few": "TOO FEW ARE LEFT", "gates_shut": "THE GATES ARE SHUT"`.

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 45. A
  house choice that fails `_setup`'s quiet check is reported with the measured distances before anything changes (the houses are a
  tuning knob, Decision 229; never loosen QUIET in the test).

- [ ] **Step 7: The scenario.** In `tools/dev/behaviour_check.gd`:
  - The header comment gains:

```gdscript
##   exodus  (v0.11 M6) Exodus, --case=none (nothing cast) or play, as a player plays it (_exodus_act(): a believer seized -- Discord on his
##          seizer, else Silent Doom on him unseen; searchers within EXODUS_HOUNDS of a believer -- Silent Doom unseen, else Mind Whisper
##          sends one off; the current household's lamp free and its next stretch and its gate clear of watchers within EXODUS_NEAR -- Mind
##          Whisper sends it up to 10 units along its road to the nearest open gate, short of a watched gate; a watcher within EXODUS_NEAR of
##          that stretch or the gate -- Silent Doom unseen, else Discord where it holds two, else Mind Whisper; the next household within
##          EXODUS_AHEAD -- its road's first watcher cleared the same way; a follower beyond FOLLOW_REACH -- whispered to his lamp; never a
##          loud power; the result line gives the longest idle stretch). --seed=, --board as ringers.
```

  - Constants:

```gdscript
## Exodus's policy (v0.11 M6): how near a believer searchers are answered; how near the lamp's next stretch or its gate a watcher is
## cleared; how far ahead it looks along the road; how far short of a watched gate the lamp waits; how soon before the next household
## its road is cleared.
const EXODUS_HOUNDS := 6.0
const EXODUS_NEAR := 4.0
const EXODUS_STRETCH := 6.0
const EXODUS_WAIT := 3.0
const EXODUS_AHEAD := 25.0
```

  - `_run()`: `elif scenario == "exodus":` with `powers = PackedStringArray(["whisper", "doom", "discord", "wisp"])` and
    `mission.mission_id = MissionBook.EXODUS`; `match scenario:` gains `"exodus": await _exodus(Battlefield.arg_value(args, "--case"))`.
    Not on the hit-stop list (no loud power).
  - After `_eye_act()` add:

```gdscript
## Exodus (v0.11 M6), with mission spec §2's policy (_exodus_act()), through _scripted().
func _exodus(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as ExodusDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("exodus", which, func() -> String: return _exodus_act(rules, slots, d, crowd),
		func() -> String: return "out=%d left=%d current=%d seizures=%d gaze=%d phase=%s" % [d.out_count(), d.left_count(), d.current(),
			d.seizures, roundi(d.gaze.value), d.hint_phase()])


## The believers still in the town and out of doors (v0.11 M6): the Dooms' spare list.
func _exodus_flock(d: ExodusDirector) -> Array:
	var out := []
	for c in d.charges:
		if not d._resolved(c) and not (c.man as Person).inside:
			out.append(c.man)
	return out


## Clears watcher `p` (v0.11 M6): Silent Doom unseen and sparing every believer; else Discord where it holds two watchers and no
## believer; else Mind Whisper sends him EIGHT units off `from`. "" when no slot serves.
func _exodus_off(rules: Rules, slots: Dictionary, d: ExodusDirector, crowd: Crowd, p: Person, from: Vector2) -> String:
	var flock := _exodus_flock(d)
	if _slot_ready(rules, slots, "doom") and _doom_unseen(crowd, p.ground_pos, flock):
		rules.cast(slots.doom, p.ground_pos)
		return "doom an Inquisitor"
	if _slot_ready(rules, slots, "discord"):
		var held := 0
		var near_flock := false
		for v: Variant in d._watchers():
			if d._watching(v) and (v as Person).ground_pos.distance_to(p.ground_pos) <= DiscordFx.DISCORD_R - 0.1:
				held += 1
		for b: Variant in flock:
			near_flock = near_flock or (b as Person).ground_pos.distance_to(p.ground_pos) <= DiscordFx.DISCORD_R + 0.2
		if held >= 2 and not near_flock:
			rules.cast(slots.discord, p.ground_pos)
			return "discord the Inquisitors"
	if _slot_ready(rules, slots, "whisper") and not p.shaken():
		rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _prisoner_away(crowd, p, from)})
		return "whisper an Inquisitor off"
	return ""


## One look of Exodus's policy (v0.11 M6, mission spec §2): what was cast, or "". The first that applies: a believer seized -- Discord on
## his seizer, else Silent Doom on him unseen; searchers near a believer -- cleared; the current household's lamp free and its way clear
## -- Mind Whisper sends it along its road, short of a watched gate; a watcher near the lamp's next stretch or its gate -- cleared; the
## next household within EXODUS_AHEAD -- the first watcher on its road cleared; a follower out of the file -- whispered to his lamp.
func _exodus_act(rules: Rules, slots: Dictionary, d: ExodusDirector, crowd: Crowd) -> String:
	for c in d.charges:
		if not c.held or d._resolved(c) or not WarningDirector._alive(c.seizer):
			continue
		var s := c.seizer as Person
		if _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord a seizer"
		if _slot_ready(rules, slots, "doom") and _doom_unseen(crowd, s.ground_pos, _exodus_flock(d)):
			rules.cast(slots.doom, s.ground_pos)
			return "doom a seizer"
	for i in d.households.size():
		for p in d.searchers_out(i):
			var near := false
			for b: Variant in _exodus_flock(d):
				near = near or (b as Person).ground_pos.distance_to(p.ground_pos) <= EXODUS_HOUNDS
			if near:
				var from := (d.lamp(i).man as Person).ground_pos if d.lamp(i) != null else p.ground_pos + Vector2.LEFT
				var did := _exodus_off(rules, slots, d, crowd, p, from)
				if did != "":
					return did
	var cur := d.current()
	if cur >= 0:
		var lead := d.lamp(cur)
		if lead != null:
			var lp := lead.man as Person
			var road := d.road(cur)
			var ahead := _road_ahead(road, lp.ground_pos, EXODUS_STRETCH)
			var exit: Vector2 = road.back()
			var g := -1
			for k in d.gates.size():
				if (d.gates[k] as ExodusDirector.Gate).way_out == exit:
					g = k
			var mouth := (d.gates[g] as ExodusDirector.Gate).mouth if g >= 0 else exit
			var blocker: Person = null
			for v: Variant in d._watchers():
				if not d._watching(v):
					continue
				var p := v as Person
				if p.ground_pos.distance_to(lp.ground_pos) <= EXODUS_NEAR or _seg_dist(p.ground_pos, lp.ground_pos, ahead) <= EXODUS_NEAR \
						or p.ground_pos.distance_to(mouth) <= EXODUS_NEAR:
					blocker = p
					break
			var going := lp.mind == Person.Mind.WHISPERED and lp.goal() != Vector2.INF and lp.ground_pos.distance_to(lp.goal()) > LAMB_AHEAD
			if blocker == null and not going and _slot_ready(rules, slots, "whisper") and not lp.shaken():
				var to := _road_ahead(road, lp.ground_pos, MindWhisperFx.REACH - 0.5)
				var stop := _road_progress(road, mouth) - EXODUS_WAIT
				if g >= 0 and d.gate_watched(g) and _road_progress(road, to) > stop:
					to = _road_ahead(road, road[0], maxf(stop, 0.0))
				to = MindWhisperFx.clamp_to(crowd._grid, lp.ground_pos, d._walkable(to))
				if lp.ground_pos.distance_to(to) > 1.0:
					rules.cast(slots.whisper, lp.ground_pos, {"target": lp, "to": to})
					return "whisper the %s lamp on" % (d.households[cur] as ExodusDirector.Household).name.to_lower()
			if blocker != null:
				var did := _exodus_off(rules, slots, d, crowd, blocker, lp.ground_pos)
				if did != "":
					return did
	var nxt := d.upcoming()
	if nxt >= 0 and d.due_in(nxt) <= EXODUS_AHEAD:
		var road := d.road(nxt)
		for v: Variant in d._watchers():
			if not d._watching(v):
				continue
			var p := v as Person
			for k in range(road.size() - 1):
				if _seg_dist(p.ground_pos, road[k], road[k + 1]) <= EXODUS_NEAR:
					var did := _exodus_off(rules, slots, d, crowd, p, road[k])
					if did != "":
						return did
					break
	if cur >= 0 and d.lamp(cur) != null and _slot_ready(rules, slots, "whisper"):
		var lp := d.lamp(cur).man as Person
		for c: EscortDirector.Charge in (d.households[cur] as ExodusDirector.Household).members:
			if d._resolved(c) or c.held or c == d.lamp(cur) or (c.man as Person).inside or (c.man as Person).shaken():
				continue
			var p := c.man as Person
			if p.ground_pos.distance_to(lp.ground_pos) > ExodusDirector.FOLLOW_REACH and p.mind != Person.Mind.WHISPERED:
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, lp.ground_pos)})
				return "whisper a believer back to his lamp"
	return ""
```

  - `_road_ahead()`, `_road_progress()`, `_seg_dist()` and `_prisoner_away()` are M4's helpers, used as they are.

- [ ] **Step 8: Run it once.** `--scenario=exodus --case=play --seed=1`. Expected: lines every 10 s, cast lines, a result line, no
  `SCRIPT ERROR`. Read them: the policy whispers each lamp out along its road, answers each seizure inside its march, clears the road and
  gate ahead of the household, and never Dooms a believer. Fix the policy until it plays the spec's steps.

- [ ] **Step 9: The gate.** Run the Scenario loop for `exodus`.
  - Expected for `none`: `won=false reason=exodus_few` in each (the spec's "about 2:40"). If not 3 of 3: HUNT_AFTER comes down.
  - Expected for `play`: at least 2 of 3 won, the median won time 180-240 s, `idle` 45 s or less; the Gaze 0-10% (write the values).
  - Tuning order: CHAIN (20-30), BELIEVER_PACE (0.4-0.55), the houses (12-16 units of street from their gates), OUT_AT[0] (10-30),
    HUNT_AFTER (20-45) -- after checking the policy. Three rounds at most; record each.
  - Write the measured clear's sum next to the spec's (≈ 225 s) in the commit body.

- [ ] **Step 10: Spec sync.** §2's `Numbers`, timeline, clear and hint lines to the tuned values.

- [ ] **Step 11: The Reference check, and FLOW.** Every old value unchanged, and the `eye` six exactly as Task 5 recorded them; FLOW
  113/0, alone.

- [ ] **Step 12: Commit.**

```bash
git add src/game/mission/exodus_director.gd src/game/mission/exodus_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd docs/superpowers/specs/2026-10-15-kak-v011-m6-ascendance-missions.md tests/test_exodus.gd tests/test_exodus.gd.uid tests/run_all.gd
git commit -m "feat: Exodus -- twelve believers in three households, each following its lamp out before the gates shut (v0.11 M6)" -m "<exodus none/play seeds 1-3 (the six new references); the eye six unchanged; the gate's verdict; tuning rounds; the clear's sum; the Gaze per run; the halves' counts; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: The Heart of Faith (Raze + Assassinate)

**Files:**
- Create: `src/game/mission/heart_of_faith_director.gd`
- Modify: `src/game/mission/mission_book.gd` (`heart_of_faith()`, `tier_missions()`)
- Modify: `src/game/mission/mission_hints.gd`, `src/game/ui/results_screen.gd`
- Modify: `tools/dev/behaviour_check.gd` (`--scenario=heart`, `_heart()`, `_heart_act()`, `_heart_strike()`)
- Modify: the mission spec's §3 (spec sync)
- Create: `tests/test_heart_of_faith.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: Task 4's `_spoil_for()`, `StagesObjective`, `MissionDirector.stages_done()` / `lost_reason()` / `hud_line()`, `_tier5()`; the
  Raze type (`targets`, `seal()`, `unseal()`, `is_sealed()`, `razed()`, `razed_count()`, `burned()`, `burning()`, `_spoilable()`,
  `_on_razed()`, `_raze()`, `_judge_targets()`, `MARK_*`); M5's Lantern Knights (`Crowd.add_soldier()`, `Person.Corps.KNIGHT`,
  `Person.HEALTH_KNIGHT`), `EngineerManager.hands_off`; `MissionDirector._hold_all()`; Task 5's `_doom_unseen()`.
- Produces: `HeartOfFaithDirector` with `oil_house`, `temple`, `doors`, `citadel_door`, `steps_at`, `in_use`, `razed_at`, `posts`,
  `bearers`, `guards`, `reliefs`, `odran`, `flame_out`, `odran_out`, `riding`, `odran_dead`, `blessed`, `kindled`, `rite_on`, `rite_left`,
  `litter_at`; `current() -> int`, `next_target() -> int`, `stage_due(i) -> float`, `guards_at(i) -> Array[Person]`,
  `standing_at(i) -> Array[Person]`, `bearers_standing() -> Array[Person]`, `last_guards() -> Array[Person]`,
  `relief_walking() -> Person`, `odran_down() -> bool`, `_open(i)`, `_odran_comes()`, `_bless()`; inner `Post`, `HeartGaze`; the
  constants of mission spec §3; `MissionBook.heart_of_faith()`.

- [ ] **Step 1: Write the failing test.** Create `tests/test_heart_of_faith.gd`:

```gdscript
extends RefCounted
## v0.11 M6 The Heart of Faith (mission spec §3, HeartOfFaithDirector on the Raze type): stage one, the oil-house (the dwelling nearest its
## point) then the Great Temple, staged on the chain (0:45, 1:50 or CHAIN after the oil-house is razed), each under Lantern Knights -- two
## standing from the start, two coming out of its door at its time -- who seal it while one stands guard; a target not in use puts its fire
## out and a fall counts at its time; burned 12 s (the oil-house) or 20 s (the Temple) in use, or fallen, it is razed; a fallen Knight is
## replaced from the Citadel's gate. The Temple razed puts the Great Flame out: four bearers come out at the Citadel's gate and High Priest
## Odran follows ODRAN_CHAIN later, hidden in his litter while two bearers live, on foot below two; at the Temple's steps he rekindles for
## RITE, started again by any interruption. His death wins; the flame blessed at 5:00 or rekindled loses; once the flame is out a seen
## death adds 20. The town's evacuation passes everyone by; freed bodies are borne; the tags, hints, tour, titles, camera and numbers.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_setup(t)
	_hold(t)
	_sealed(t)
	_not_yet(t)
	_burn(t)
	_flame_out(t)
	_litter(t)
	_on_foot(t)
	_rite(t)
	_fury(t)
	_won(t)
	_leaves(t)
	_blessed(t)
	_relief(t)
	_evacuated(t)
	_tagged(t)
	_freed(t)


static func _world() -> Dictionary:
	return Kit.world(MissionBook.heart_of_faith())


## Every Knight of target `i` out of doors killed and freed (v0.11 M6 tests).
static func _kill_knights(s: Dictionary, d: HeartOfFaithDirector, i: int) -> void:
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == i and MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)


## Both targets razed in turn by hand (v0.11 M6 tests): the flame goes out.
static func _put_out(d: HeartOfFaithDirector) -> void:
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	d._raze(d.targets[1])


static func _setup(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var eng := (s.crowd as Crowd).engineers
	t.check(d.targets.size() == 2 and d.targets[0] == d.oil_house and d.targets[1] == d.temple and RuinWish.fits(d.oil_house, "house")
		and d.temple.role == &"temple" and eng.hands_off.has(d.oil_house) and eng.hands_off.has(d.temple) and not d.in_use[0],
		"the oil-house (a dwelling) then the Great Temple, kept from the town's engineers, neither in use yet")
	var ok := d.posts.size() == 8
	for p: HeartOfFaithDirector.Post in d.posts:
		var k := p.man as Person
		ok = ok and k.soldier and k.corps == Person.Corps.KNIGHT and is_equal_approx(k.health, Person.HEALTH_KNIGHT) \
			and d.targets[p.target].distance_to(p.spot) <= HeartOfFaithDirector.GUARD_REACH + 0.01 and k.inside == p.arriving
		for q: HeartOfFaithDirector.Post in d.posts:
			if q != p and q.target == p.target:
				ok = ok and p.spot.distance_to(q.spot) > Crowd.DOOM_WITNESS
	t.check(ok and d.guards_at(0).size() == 2 and d.guards_at(1).size() == 2,
		"two Knights stand at each, two wait inside it, every post within reach and a witness apart")
	var o := d.odran as Person
	t.check(o.profile.role == CitizenProfile.Role.CLERGY and o.inside and o.mind == Person.Mind.DUTY and d.gaze is HeartOfFaithDirector.HeartGaze,
		"Odran, a cleric, waits inside the Citadel on duty; the Heart keeps its own Gaze")
	var ids := []
	for e in d.timeline.upcoming(3):
		ids.append(e.id)
	t.check(ids == ["stage_0", "stage_1", "blessed"], "the strip: the oil-house, the Temple, the blessing (%s)" % [ids])
	var cam := HeartOfFaithDirector.CAMERA_AT
	t.check(Kit.clear_of_stack(d.oil_house.center(), cam, Kit.STACK) and Kit.clear_of_stack(d.temple.center(), cam, Kit.STACK)
		and Kit.clear_of_stack(d.steps_at, cam, Kit.STACK) and Kit.clear_of_stack(d.citadel_door, cam, Kit.STACK),
		"the camera keeps the oil-house, the Temple, its steps and the Citadel's gate (or their arrows) clear of the real stack")
	var m := MissionBook.heart_of_faith()
	var reasons := []
	for obj in m.objectives():
		reasons.append(obj.reason)
	t.check(m.tier == 5 and is_equal_approx(m.clock, 420.0) and reasons == ["heart", "gaze", "dawn"]
		and Array(m.default_loadout) == ["doom", "smite", "ember", "whisper", "heaven"], "the mission: Tier 5's numbers; the Heart, the Gaze, dawn (%s)" % [reasons])
	Kit.done(s)


static func _hold(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var crowd: Crowd = s.crowd
	crowd._regroup()
	crowd._evacuate()
	Kit.run_for(s, 1.0)
	var held := (d.odran as Person).inside
	for p: HeartOfFaithDirector.Post in d.posts:
		var k := p.man as Person
		held = held and k.corps == Person.Corps.KNIGHT and (k.inside or k.mind == Person.Mind.POST)
	t.check(held, "the town's regroup and evacuation take no Knight; Odran stays in the Citadel (review focus 2)")
	Kit.done(s)


static func _sealed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	Kit.run_for(s, DT)
	d.oil_house.damage(40.0, d.oil_house.center(), &"smite")
	t.check(d.is_sealed(d.oil_house) and is_equal_approx(d.oil_house.hp, d.oil_house.max_hp) and d.hint_phase() == "guarded",
		"a Knight on guard seals the target in use: a blow only shakes it")
	Kit.done(s)


static func _not_yet(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_kill_knights(s, d, 0)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd).fires.ignite(d.oil_house, 1.0)
	Kit.run_for(s, DT)
	t.check(not d.is_sealed(d.oil_house) and not d.burning(d.oil_house) and is_equal_approx(d.burned(d.oil_house), 0.0),
		"not in use and unguarded: its fire goes out at once and nothing it burns counts")
	d.oil_house.destroy(d.oil_house.center(), &"smite")
	Kit.run_for(s, DT)
	t.check(not d.razed(d.oil_house) and Kit.labels(d).has("OIL-HOUSE - DOWN, COUNTS AT %s" % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0]))),
		"felled ahead of its time: not razed yet, and its tag says when it counts")
	d._open(0)
	Kit.run_for(s, DT)
	t.check(d.razed(d.oil_house) and absf(d.timeline.seconds_to("stage_1") - HeartOfFaithDirector.CHAIN) < 1.0,
		"at its time a fallen oil-house is razed at once, and the Temple comes on the chain")
	Kit.done(s)


static func _burn(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	_kill_knights(s, d, 0)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd).fires.ignite(d.oil_house, 1.0)
	Kit.run_for(s, float(HeartOfFaithDirector.SPOIL[0]) + 0.5)
	t.check(d.razed(d.oil_house) and not d.flame_out and (s.banners as Array).has("THE OIL-HOUSE IS RAZED")
		and absf(d.timeline.seconds_to("stage_1") - HeartOfFaithDirector.CHAIN) < 1.0,
		"in use and unguarded, burned %d s in all the oil-house is razed; the Temple comes on the chain" % roundi(float(HeartOfFaithDirector.SPOIL[0])))
	Kit.done(s)


static func _flame_out(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	var ok := d.flame_out and d.bearers.size() == HeartOfFaithDirector.BEARERS and (d.gaze as HeartOfFaithDirector.HeartGaze).fury
	for a: HeartOfFaithDirector.Post in d.bearers:
		ok = ok and MissionDirector._alive(a.man) and (a.man as Person).corps == Person.Corps.KNIGHT
		for b: HeartOfFaithDirector.Post in d.bearers:
			if a != b:
				ok = ok and a.spot.distance_to(b.spot) > Crowd.DOOM_WITNESS
	var banners: Array = s.banners
	t.check(ok and banners.has("THE GREAT FLAME GOES OUT") and banners.has("HALCYON LOOKS HARDER") and banners.has("THE HIGH PRIEST'S LITTER WAITS")
		and (d.odran as Person).inside and d.hint_phase() == "coming" and absf(d.hint_seconds() - HeartOfFaithDirector.ODRAN_CHAIN) < 0.5
		and d.hud_line() == "Kill Odran" and d.stages_done() == false,
		"the Temple razed: the flame out, four bearers a witness apart at the Citadel's gate, Odran %d s off" % roundi(HeartOfFaithDirector.ODRAN_CHAIN))
	Kit.done(s)


static func _litter(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	d._odran_comes()
	Kit.run_for(s, 1.0)
	var o := d.odran as Person
	var carried := true
	for b in d.bearers_standing():
		carried = carried and b.mind == Person.Mind.DUTY
	t.check(d.riding and o.inside and o.ground_pos.distance_to(d.litter_at) < 0.01 and carried and d.hint_phase() == "litter"
		and d.hud_line() == "Kill Odran: in his litter" and Kit.labels(d).has("ODRAN - IN HIS LITTER") and Kit.edged(d, "ODRAN - IN HIS LITTER"),
		"he rides hidden in his litter, carried on duty; untouchable")
	for k in 3:
		Kit.free_body(s, (d.bearers[k] as HeartOfFaithDirector.Post).man)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	t.check(not d.riding and not o.inside and o.mind == Person.Mind.DUTY and (s.banners as Array).has("THE LITTER FALLS")
		and d.hint_phase() == "on_foot" and d.last_guards().size() == 1, "below two bearers the litter falls: he walks on, killable, the last bearer behind him")
	Kit.done(s)


static func _on_foot(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for k in 3:
		Kit.free_body(s, (d.bearers[k] as HeartOfFaithDirector.Post).man)
	d._odran_comes()
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	var o := d.odran as Person
	var guard: Array[Person] = d.last_guards()
	t.check(not d.riding and not o.inside and o.mind == Person.Mind.DUTY and guard.size() == 2 and d.hint_phase() == "on_foot",
		"with fewer than two bearers he sets out on foot, one more Knight as his last guard and the bearer left behind him")
	Kit.done(s)


static func _rite(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	var o := d.odran as Person
	Kit.arrive(o, d.steps_at)
	d._road_at = d._road.size() - 1
	o.go_duty(d.steps_at)
	Kit.run_for(s, 1.0)
	t.check(d.rite_on and d.rite_left < HeartOfFaithDirector.RITE and (s.banners as Array).has("ODRAN REKINDLES THE FLAME") and d.hint_phase() == "rite"
		and Kit.labels(d).has("ODRAN - REKINDLING %d" % ceili(d.rite_left)), "at the Temple's steps, on foot, he rekindles the flame")
	o.whisper(o.ground_pos + Vector2(4.0, 0.0), MindWhisperFx.LINGER)
	Kit.run_for(s, DT)
	t.check(not d.rite_on and is_equal_approx(d.rite_left, HeartOfFaithDirector.RITE), "a whisper on him starts it again from %d" % roundi(HeartOfFaithDirector.RITE))
	o._wake()
	Kit.arrive(o, d.steps_at)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	Kit.run_for(s, HeartOfFaithDirector.RITE + 0.5)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.kindled and d.lost_reason() == "kindled" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "kindled",
		"left to finish, the flame is kindled anew: lost")
	Kit.done(s)


static func _fury(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var crowd: Crowd = s.crowd
	var people: Array[Person] = []
	for p in crowd.citizens:
		if MissionDirector._alive(p) and not p.inside and p != d.odran and people.size() < 4:
			people.append(p)
	Kit.arrive(people[1], people[0].ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(people[0], &"doom")
	Kit.run_for(s, DT)
	var before := d.gaze.value
	_put_out(d)
	Kit.arrive(people[3], people[2].ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(people[2], &"doom")
	Kit.run_for(s, DT)
	t.check(is_equal_approx(before, HeartOfFaithDirector.SEEN) and is_equal_approx(d.gaze.value - before, HeartOfFaithDirector.FURY),
		"a seen death adds %d, and %d once the flame is out" % [roundi(HeartOfFaithDirector.SEEN), roundi(HeartOfFaithDirector.FURY)])
	Kit.done(s)


static func _won(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	(s.crowd as Crowd)._field.kill(d.odran, &"doom")
	Kit.run_for(s, DT)
	var main: Objective = (s.rules as Rules).objectives[0]
	var home := true
	for p: HeartOfFaithDirector.Post in d.posts + d.guards:
		home = home and p.done
	t.check(d.odran_dead and d.stages_done() and main.check(s.rules) == Objective.Status.DONE and main.reason == "heart" and home,
		"Odran dead once the flame is out: the Heart of Faith is broken; his Knights go home")
	Kit.done(s)


static func _leaves(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	_put_out(d)
	Kit.run_for(s, DT)
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	d._odran_comes()
	(s.crowd as Crowd).escaped.emit(d.odran)
	t.check(d.odran_down() and d.stages_done(), "Odran leaving the town ends him as his death would: at once (review focus 4)")
	Kit.done(s)


static func _blessed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d.timeline.step(HeartOfFaithDirector.BLESSED_AT + 1.0)
	var main: Objective = (s.rules as Rules).objectives[0]
	t.check(d.blessed and d.lost_reason() == "blessed" and main.check(s.rules) == Objective.Status.FAILED and main.reason == "blessed",
		"the flame still burning at %s: blessed, lost" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT))
	Kit.done(s)
	var o := _world()
	var od: HeartOfFaithDirector = o.d
	_put_out(od)
	od.timeline.step(HeartOfFaithDirector.BLESSED_AT + 1.0)
	t.check(not od.blessed and od.lost_reason() == "", "with the flame out, the blessing is dropped")
	Kit.done(o)


static func _relief(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var post: HeartOfFaithDirector.Post = d.posts[0]
	var dead: Variant = post.man
	Kit.free_body(s, dead)
	Kit.run_for(s, HeartOfFaithDirector.RELIEF_AFTER + HeartOfFaithDirector.TICK + DT)
	var k: Variant = post.man
	t.check(k != dead and MissionDirector._alive(k) and (k as Person).corps == Person.Corps.KNIGHT and (k as Person).anchor == post.spot
		and post.relief and d.reliefs == 1 and d.relief_walking() == k and (s.banners as Array).has("A NEW KNIGHT COMES FROM THE CITADEL"),
		"a fallen Knight is replaced %d s later by one walking from the Citadel's gate" % roundi(HeartOfFaithDirector.RELIEF_AFTER))
	Kit.done(s)


static func _evacuated(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	d._raze(d.targets[0])
	d._open(1)
	var post: HeartOfFaithDirector.Post = null
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == 1 and not p.arriving:
			post = p
			break
	Kit.free_body(s, post.man)
	Kit.run_for(s, HeartOfFaithDirector.RELIEF_AFTER + HeartOfFaithDirector.TICK + DT)
	var relief := post.man as Person
	Kit.evacuate(s)
	Kit.run_for(s, 2.0 * HeartOfFaithDirector.TICK + DT)
	var held := true
	for p: HeartOfFaithDirector.Post in d.posts:
		if p.target == 1 and MissionDirector._alive(p.man):
			held = held and (p.man as Person).mind == Person.Mind.POST and (p.man as Person).anchor == p.spot
	t.check(post.relief and relief.mind == Person.Mind.POST and relief.anchor == post.spot and held,
		"the evacuation while the Temple is in use and a relief walks in: he walks on to his post, the Knights hold")
	Kit.done(s)
	var s2 := _world()
	var d2: HeartOfFaithDirector = s2.d
	_put_out(d2)
	Kit.run_for(s2, DT)
	d2._odran_comes()
	Kit.run_for(s2, 1.0)
	Kit.evacuate(s2)
	Kit.run_for(s2, 2.0 * HeartOfFaithDirector.TICK + DT)
	var square := true
	for b in d2.bearers_standing():
		square = square and b.mind == Person.Mind.DUTY
	t.check(d2.riding and (d2.odran as Person).inside and square, "again while the litter walks: the bearers keep their square, Odran hidden in it")
	for k in 3:
		Kit.free_body(s2, (d2.bearers[k] as HeartOfFaithDirector.Post).man)
	Kit.run_for(s2, HeartOfFaithDirector.TICK + DT)
	var o := d2.odran as Person
	o._recover(1.0)
	Kit.evacuate(s2)
	d2._saw_evacuation = false
	Kit.run_for(s2, 2.0 * HeartOfFaithDirector.TICK + DT)
	t.check(o.mind == Person.Mind.DUTY and (s2.crowd as Crowd).citizens.has(o) and not o.inside,
		"on foot, recovering when the town runs, he keeps his road; he never leaves the town")
	Kit.done(s2)


static func _tagged(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	var labels := Kit.labels(d)
	var next := "OIL-HOUSE - IN USE BY %s" % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0]))
	t.check(labels[0] == next and Kit.edged(d, next) and labels.has("ODRAN - IN THE CITADEL") and labels.has("KNIGHT")
		and d.hud_line() == "Put out the flame 0 / 2: blessed in %s" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT),
		"at the start: the oil-house's time, grey, pointed at; Odran in the Citadel; KNIGHT on each; the blessing's countdown (%s)" % [labels])
	d._open(0)
	t.check(Kit.labels(d)[0] == "OIL-HOUSE - GUARDED" and Kit.edged(d, "OIL-HOUSE - GUARDED"), "in use and guarded, gold, pointed at")
	var tour := d.tour()
	t.check(tour.size() == 3 and String(tour[0][1]) == "The oil-house. Its Knights guard it. It feeds the flame from %s: burn it." % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[0]))
		and String(tour[1][1]) == "The Great Temple. The flame blazes here by %s. Burn it down to put the flame out." % UiTheme.clock(float(HeartOfFaithDirector.STAGE_AT[1]))
		and String(tour[2][1]) == "The Citadel. High Priest Odran waits here. Once the flame is out he comes to rekindle it: kill him.", "the tour")
	t.check(ResultsScreen.ACT_TITLES.get("heart") == "THE HEART OF FAITH IS BROKEN" and ResultsScreen.ACT_TITLES.get("blessed") == "THE GREAT FLAME IS BLESSED"
		and ResultsScreen.ACT_TITLES.get("kindled") == "THE FLAME IS KINDLED ANEW" and MissionHints.line("heart_of_faith", "coming").contains(MissionHints.SECONDS),
		"its results under its own keys")
	Kit.done(s)


static func _freed(t) -> void:
	var s := _world()
	var d: HeartOfFaithDirector = s.d
	d._open(0)
	Kit.run_for(s, 0.2)
	for p: HeartOfFaithDirector.Post in d.posts:
		if MissionDirector._alive(p.man) and not (p.man as Person).inside:
			Kit.free_body(s, p.man)
	d.tags()
	d.hint_phase()
	d.hud_line()
	d.report()
	_put_out(d)
	Kit.run_for(s, DT)
	d._odran_comes()
	for p: HeartOfFaithDirector.Post in d.bearers:
		Kit.free_body(s, p.man)
	Kit.run_for(s, HeartOfFaithDirector.TICK + DT)
	for p: HeartOfFaithDirector.Post in d.guards:
		if MissionDirector._alive(p.man):
			Kit.free_body(s, p.man)
	d.tags()
	d.hint_phase()
	d.report()
	Kit.run_for(s, 1.0)
	t.check(not d.odran_down() and d.hint_phase() == "on_foot", "every Knight and bearer freed: borne; Odran walks on (review focus 4)")
	Kit.done(s)
```

  - In `tests/run_all.gd`, append `"res://tests/test_heart_of_faith.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the test to verify it fails.** Expected: a parse error or FAILs in `test_heart_of_faith`.

- [ ] **Step 3: The director.** Create `src/game/mission/heart_of_faith_director.gd`:

```gdscript
class_name HeartOfFaithDirector
extends RazeDirector
## The Heart of Faith (v0.11 M6, Tier 5, mission spec §3; Raze + Assassinate, Decision 231): put out Halcyon's Great Flame, then kill the
## High Priest who comes to rekindle it. Stage one is the Raze type's staged rule (M4's, as The Armoury's ruling has it): the oil-house
## (the dwelling nearest OIL_AT whose door the street reaches) and the Great Temple come into use on the chain (STAGE_AT, or CHAIN after
## the one before is razed, _spoilable()); before its time a target's fire goes out and its fall counts only at its time; in use it is
## razed burned _spoil_for() seconds in all (SPOIL) or fallen. Lantern Knights -- soldiers this director adds, corps KNIGHT -- stand
## STANDING at each from the start and ARRIVING come out of its door at its time; while one stands guard (within GUARD_REACH) the target is
## sealed (seal()). A fallen Knight is replaced RELIEF_AFTER later from the Citadel's gate (RELIEFS a night). The Temple razed puts the
## flame out: Halcyon looks harder (FURY a seen death, HeartGaze), BEARERS Knights come out at the Citadel's gate as a litter's bearers and
## Odran -- the cleric nearest the Citadel's gate, waiting inside it -- follows ODRAN_CHAIN later: hidden in his litter while two bearers
## live (Pip's ride, plan decision 290), on foot below two with LAST_GUARD behind him. At the Temple's steps, on foot and not held, he
## rekindles for RITE, started again by a whisper, Discord or a fright. His death, any way, wins once the flame is out (StagesObjective);
## the flame still burning at BLESSED_AT, or rekindled, loses. Odran is kept from the town's flight by MissionDirector._hold_all(); the
## Knights are soldiers, whom the evacuation and the rally never take.

## One Knight's post (v0.11 M6): a plain record, so the director holds no cycle.
class Post:
	extends RefCounted
	## The Knight, a Variant read only through MissionDirector._alive(): he may be a body freed after his death fade.
	var man: Variant = null
	## The target he guards (0 the oil-house, 1 the Temple), or -1 for a bearer or a last guard.
	var target := -1
	## Where he stands.
	var spot := Vector2.INF
	## Of the pair that comes out at the target's time.
	var arriving := false
	## Seconds since he fell; he is a relief walking in, until he first stands guard; he has gone home.
	var fallen := 0.0
	var relief := false
	var done := false


## Halcyon's Gaze at the Heart (v0.11 M6, plan decision 293): SEEN a seen death, FURY once the flame is out.
class HeartGaze:
	extends GazeMeter
	## Halcyon looks harder: the flame is out.
	var fury := false

	func seen_death() -> void:
		add(FURY if fury else SEEN)


## The oil-house's point; the Citadel's gate; the foot of its lane; the Temple's steps (v0.11 M6, mission spec §3).
const OIL_AT := Vector2(-3.5, -9.5)
const CITADEL_GATE := HarvestDirector.CITADEL_GATE
const LANE_FOOT := Vector2(-10.5, -5.1)
const STEPS_AT := Vector2(0.8, -5.0)
## The targets' names on the tags and in words; the strip's words as each comes into use; the next target's tag's words (v0.11 M6).
const NAMES := ["OIL-HOUSE", "TEMPLE"]
const WORDS := ["oil-house", "Temple"]
const STAGE_LABELS := ["The keepers draw the flame's oil", "The Great Flame blazes"]
const NEXT_WORDS := ["IN USE BY", "THE FLAME BLAZES BY"]
## Mission spec §3's numbers (v0.11 M6), first guesses, tuned by Step 9's gate in this order: CHAIN (35-45), STAGE_AT[0] (40-60),
## SPOIL[1] (15-25), ODRAN_CHAIN (20-30), ARRIVING (1-3); ODRAN_PACE (0.25-0.5, plan decision 292). Stage one: each target's time at
## the latest, the chain, the Knights standing and arriving, their spacing (wanted, and the least, beyond a witness's 2.0), their reach,
## each target's burning, reliefs, the blessing.
const STAGE_AT := [45.0, 110.0]
const CHAIN := 45.0
const STANDING := 2
const ARRIVING := 2
const POST_GAP := 2.4
const POST_APART := 2.1
const GUARD_REACH := 2.5
const SPOIL := [12.0, 20.0]
const RELIEF_AFTER := 30.0
const RELIEFS := 4
const BLESSED_AT := 300.0
## Stage two (v0.11 M6): the bearers and their square; the last guard and his gap; Odran's chain, pace, rite and the altar's reach.
const BEARERS := 4
const LITTER_SIDE := 2.1
const LAST_GUARD := 1
const GUARD_GAP := 2.5
const ODRAN_CHAIN := 30.0
const ODRAN_PACE := 0.5
const RITE := 20.0
const ALTAR_REACH := 1.5
## The Gaze (v0.11 M6): a seen death, and once the flame is out.
const SEEN := 10.0
const FURY := 20.0
## How near its time a target not yet in use puts the hint on "not_yet" (the spec's last 25 s); how many dwellings the oil-house's choice
## weighs; seconds between looks; how near a point counts as reached; how far a place must move before someone is sent again; how far
## the litter goes each look; how far to the side of Odran's track each guard behind him walks (v0.11 M6).
const WORK_AHEAD := 25.0
const HOUSE_TRIES := 12
const TICK := 0.5
const ARRIVE := 0.8
const MOVE := 0.3
const LITTER_STEP := 1.5
const SIDE_STEP := 1.2
## Where the camera rests (v0.11 M6, Decision 247): the oil-house up and right of the centre, the Temple at the right, the Citadel's gate
## above the centre.
const CAMERA_AT := Vector2(-6.0, -4.0)
## The map tags' colours the Raze type does not name (v0.11 M6): not yet grey, the altar orange.
const MARK_NOT_YET := Color("9a948a")
const MARK_PLACE := Color("ff9a3a")

## The oil-house, the Temple and each one's door; the Citadel's gate and the Temple's steps on walkable ground (v0.11 M6).
var oil_house: Structure
var temple: Structure
var doors: Array[Vector2] = []
var citadel_door := Vector2.INF
var steps_at := Vector2.INF
## Each target in use yet; the second it was razed (-1 until then) (v0.11 M6).
var in_use: Array[bool] = []
var razed_at: Array[float] = []
## Stage one's Knights, the bearers, and the guards walking behind Odran (Post records); reliefs this night (v0.11 M6).
var posts: Array = []
var bearers: Array = []
var guards: Array = []
var reliefs := 0
## Odran (a Variant: he may be freed); the flame is out, and when; Odran out of the Citadel; riding his litter; dead or gone; the
## blessing came; the flame rekindled; his rite runs, and its seconds left; the litter's middle (v0.11 M6).
var odran: Variant = null
var flame_out := false
var flame_out_at := -1.0
var odran_out := false
var riding := false
var odran_dead := false
var blessed := false
var kindled := false
var rite_on := false
var rite_left := RITE
var litter_at := Vector2.INF
## Odran's road (the Citadel's gate, the lane's foot, the Temple's steps) and the point of it he makes for; Knights walking home
## (v0.11 M6).
var _road: Array[Vector2] = []
var _road_at := 1
var _homeward: Array = []
## Seconds into the night, and to the next look (v0.11 M6).
var _clock := 0.0
var _tick_in := 0.0


## The night's setup (v0.11 M6): the Heart's Gaze; the two targets, kept from the town's engineers; at each, its standing Knights at
## their posts and its arriving pair inside it; Odran inside the Citadel; the stages and the blessing on the strip.
func _begin() -> void:
	gaze = HeartGaze.new()
	citadel_door = _walkable(CITADEL_GATE)
	steps_at = _walkable(STEPS_AT)
	for at: Vector2 in [CITADEL_GATE, LANE_FOOT, STEPS_AT]:
		_road.append(_walkable(at))
	for s: Structure in town._built:
		if is_instance_valid(s) and s.role == &"temple" and not s.destroyed:
			temple = s
			break
	oil_house = _oil_house()
	if oil_house == null or temple == null:
		push_warning("HeartOfFaithDirector: no oil-house or Temple")
	for s: Variant in [oil_house, temple]:
		if s != null:
			targets.append(s as Structure)
	if crowd.engineers != null:
		crowd.engineers.hands_off.append_array(targets)
	for i in targets.size():
		in_use.append(false)
		razed_at.append(-1.0)
		var door := _open_door(targets[i], citadel_door)
		doors.append(door if door != Vector2.INF else _front_of(targets[i]))
		var mates: Array = []
		for k in STANDING + ARRIVING:
			var p := Post.new()
			p.target = i
			p.arriving = k >= STANDING
			p.spot = _post(i, k, mates)
			mates.append(p)
			if p.arriving:
				p.man = _knight(doors[i])
				_take_inside(p.man as Person, targets[i])
			else:
				p.man = _knight(p.spot)
			posts.append(p)
	odran = _citizen_near(citadel_door, CitizenProfile.Role.CLERGY)
	if _alive(odran):
		var o := odran as Person
		_set_down(o, citadel_door)
		o.go_duty(citadel_door)
		_take_inside(o, null)
	crowd._field.enemy_killed.connect(_on_killed)
	crowd.escaped.connect(_on_escaped)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	for i in targets.size():
		timeline.add(float(STAGE_AT[i]), "stage_%d" % i, String(STAGE_LABELS[i]), _open.bind(i),
			func() -> bool: return not in_use[i] and not razed(targets[i]))
	timeline.add(BLESSED_AT, "blessed", "The Great Flame is blessed", _bless, func() -> bool: return not flame_out)
	rules.banner.emit("THE HEART OF FAITH")


## The oil-house (v0.11 M6, plan decision 295): the dwelling nearest OIL_AT whose door the street from the Citadel's gate reaches, never a
## wish's; null for none.
func _oil_house() -> Structure:
	var skip: Array = []
	for k in HOUSE_TRIES:
		var h := _house_near(OIL_AT, skip)
		if h == null:
			return null
		skip.append(h)
		if _open_door(h, citadel_door) != Vector2.INF:
			return h
	return null


## A Lantern Knight added at `at` (v0.11 M6, plan decision 289; M5's BishopDirector._knight(), copied): a soldier of corps KNIGHT, three
## times a soldier's health, at his post.
func _knight(at: Vector2) -> Person:
	var k := crowd.add_soldier(_walkable(at))
	k.corps = Person.Corps.KNIGHT
	k.health = Person.HEALTH_KNIGHT
	k.send_to_post(k.ground_pos)
	return k


## The `k`th Knight's post at target `i` (v0.11 M6): along its door's face, the standing pair POST_GAP apart about the door, the arriving
## pair POST_GAP beyond them -- each spread (_spread()) within GUARD_REACH of the target and beyond POST_APART of every post in `mates`.
func _post(i: int, k: int, mates: Array) -> Vector2:
	var face := doors[i]
	var out := face - targets[i].center()
	out = out.normalized() if out.length() > 0.01 else Vector2.DOWN
	var along := Vector2(-out.y, out.x)
	var side := -1.0 if k % 2 == 0 else 1.0
	var want := face + along * side * POST_GAP * (1.5 if k >= STANDING else 0.5)
	return _spread(i, want, mates)


## A post at or near `want` for target `i` (v0.11 M6, a copy of The Crown's Bread's _spread() with POST_APART): walkable, within
## GUARD_REACH of the target, reached on foot from its door, and beyond POST_APART of every post in `mates`; the nearest such point on
## rings of POST_GAP / 2 steps round `want`; `want` made walkable when there is none.
func _spread(i: int, want: Vector2, mates: Array) -> Vector2:
	var first := _walkable(want)
	for ring in 5:
		var r := POST_GAP * 0.5 * float(ring)
		var n := 1 if ring == 0 else 12
		for k in n:
			var at := first if ring == 0 else _walkable(want + Vector2.from_angle(TAU * float(k) / float(n)) * r)
			if targets[i].distance_to(at) > GUARD_REACH or (crowd._grid != null and (not crowd._grid.walkable(at)
					or (at.distance_to(doors[i]) > 0.1 and crowd._grid.path(doors[i], at).is_empty()))):
				continue
			var clear := true
			for m: Post in mates:
				clear = clear and m.spot.distance_to(at) > POST_APART
			if clear:
				return at
	return first


## Target `s` can be razed: it is in use (v0.11 M6; RazeDirector._spoilable()).
func _spoilable(s: Structure) -> bool:
	var i := targets.find(s)
	return i >= 0 and in_use[i]


## The seconds of burning that raze `s` (v0.11 M6, Task 4's hook): the oil-house's SPOIL[0], the Temple's SPOIL[1].
func _spoil_for(s: Structure) -> float:
	var i := targets.find(s)
	return float(SPOIL[clampi(i, 0, SPOIL.size() - 1)]) if i >= 0 else spoil_seconds


## The second target `i` comes into use at the latest (v0.11 M6): its own time, or CHAIN after the one before is razed if sooner.
func stage_due(i: int) -> float:
	var at := float(STAGE_AT[i]) * (timeline.stretch_factor() if timeline != null else 1.0)
	if i > 0 and razed_at[i - 1] >= 0.0:
		at = minf(at, razed_at[i - 1] + CHAIN)
	return at


## Target `i` comes into use (v0.11 M6): its arriving pair comes out of its door to their posts.
func _open(i: int) -> void:
	if in_use[i]:
		return
	in_use[i] = true
	for p: Post in posts:
		if p.target == i and p.arriving and not p.done and _alive(p.man) and (p.man as Person).inside:
			_bring_out(p.man as Person, p.spot)
			(p.man as Person).send_to_post(p.spot)


## Each target not in use whose chained time has come comes into use (v0.11 M6); its own time is the timeline's.
func _chain() -> void:
	for i in range(1, targets.size()):
		if not in_use[i] and not razed(targets[i]) and razed_at[i - 1] >= 0.0 and _clock >= stage_due(i):
			rules.banner.emit(String(STAGE_LABELS[i]).to_upper())
			_open(i)


## One step (v0.11 M6): each target sealed while guarded, the Raze type's (the timeline, each target judged), the Gaze's deaths, the chain,
## Odran's rite every frame, and every TICK a look: Odran kept from the flight, the Knights tended, the litter or his walk.
func step(delta: float) -> void:
	_clock += delta
	_guard_seals()
	super(delta)
	gaze.judge_deaths(crowd)
	_chain()
	if riding:
		_carry()
	elif odran_out and not odran_down():
		_step_rite(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	var evacuating := _evacuation_began()
	_hold_all([odran], evacuating)
	_tend()
	if not odran_out or odran_down():
		return
	if riding:
		_step_litter()
	else:
		_step_on_foot()


## Each standing target not razed is sealed while a Knight stands guard, open while none does (v0.11 M6, The Armoury's ruling).
func _guard_seals() -> void:
	for i in targets.size():
		var s := targets[i]
		if razed(s) or not is_instance_valid(s) or s.destroyed:
			continue
		var held := not guards_at(i).is_empty()
		if held and not is_sealed(s):
			seal(s)
		elif not held and is_sealed(s):
			unseal(s)


## Post `p`'s Knight stands guard (v0.11 M6): not gone home, alive, out of doors, within GUARD_REACH of his target.
func _on_guard(p: Post) -> bool:
	if p.done or p.target < 0 or not _alive(p.man):
		return false
	var k := p.man as Person
	var s := targets[p.target]
	return not k.inside and is_instance_valid(s) and s.distance_to(k.ground_pos) <= GUARD_REACH


## Target `i`'s Knights on guard now (v0.11 M6). Only reads.
func guards_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.target == i and _on_guard(p):
			out.append(p.man as Person)
	return out


## Target `i`'s living Knights out of doors, on guard or not (v0.11 M6, for the scripted player). Only reads.
func standing_at(i: int) -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in posts:
		if p.target == i and not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## A relief walking in to a target not razed, or null (v0.11 M6, for the scripted player). Only reads.
func relief_walking() -> Person:
	for p: Post in posts:
		if p.relief and not p.done and _alive(p.man) and not _on_guard(p) and not (p.man as Person).inside:
			return p.man as Person
	return null


## Stage one's Knights at their posts (v0.11 M6): a fallen one replaced RELIEF_AFTER after he fell from the Citadel's gate while his
## target stands unrazed (RELIEFS at most); one off his post sent back to it; those going home taken in at the Citadel's gate.
func _tend() -> void:
	for p: Post in posts:
		if p.done:
			continue
		if not _alive(p.man):
			p.fallen += TICK
			if p.fallen >= RELIEF_AFTER and reliefs < RELIEFS and not razed(targets[p.target]):
				_relieve(p)
			continue
		p.fallen = 0.0
		var k := p.man as Person
		if k.inside:
			continue
		if _on_guard(p):
			p.relief = false
		if k.mind == Person.Mind.POST and k.anchor.distance_to(p.spot) > MOVE:
			k.send_to_post(p.spot, false, true)
	for v: Variant in _homeward.duplicate():
		if not _alive(v) or (v as Person).inside:
			_homeward.erase(v)
		elif (v as Person).ground_pos.distance_to(citadel_door) <= ARRIVE:
			_take_inside(v as Person, null)
			_homeward.erase(v)


## A new Knight for post `p` (v0.11 M6): added at the Citadel's gate, walking to the post.
func _relieve(p: Post) -> void:
	var k := _knight(citadel_door)
	k.send_to_post(p.spot, false, true)
	p.man = k
	p.fallen = 0.0
	p.relief = true
	reliefs += 1
	rules.banner.emit("A NEW KNIGHT COMES FROM THE CITADEL")


## Post `p`'s Knight goes home (v0.11 M6): to the Citadel's gate, taken in there; one still inside stays inside.
func _go_home(p: Post) -> void:
	p.done = true
	if _alive(p.man) and not (p.man as Person).inside:
		(p.man as Person).send_to_post(citadel_door, false, false)
		_homeward.append(p.man)


## Razed (v0.11 M6): unsealed for good, its Knights home; the oil-house brings the Temple on the chain; the Temple puts the flame out.
func _on_razed(s: Structure) -> void:
	var i := targets.find(s)
	unseal(s)
	razed_at[i] = _clock
	for p: Post in posts:
		if p.target == i and not p.done:
			_go_home(p)
	if i + 1 < targets.size():
		rules.banner.emit("THE %s IS RAZED" % String(NAMES[i]))
		if timeline != null:
			timeline.expect("stage_%d" % (i + 1), stage_due(i + 1))
	else:
		_flame_goes_out()


## The Great Flame goes out (v0.11 M6): Halcyon looks harder; the litter's four bearers come out at its square below the Citadel's gate;
## Odran's chain on the strip.
func _flame_goes_out() -> void:
	if flame_out:
		return
	flame_out = true
	flame_out_at = _clock
	(gaze as HeartGaze).fury = true
	rules.banner.emit("THE GREAT FLAME GOES OUT")
	rules.banner.emit("HALCYON LOOKS HARDER")
	litter_at = _litter_spot()
	for k in BEARERS:
		var p := Post.new()
		p.spot = _walkable(litter_at + _corner(k))
		p.man = _knight(p.spot)
		bearers.append(p)
	rules.banner.emit("THE HIGH PRIEST'S LITTER WAITS")
	if timeline != null:
		timeline.add(timeline.elapsed() + ODRAN_CHAIN / timeline.stretch_factor(), "odran", "The High Priest comes to rekindle the flame",
			_odran_comes, func() -> bool: return not odran_out and not odran_down())


## The `k`th corner of the litter's square, from its middle (v0.11 M6): LITTER_SIDE a side.
func _corner(k: int) -> Vector2:
	var h := LITTER_SIDE * 0.5
	return [Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)][k % 4]


## The litter's first middle (v0.11 M6, plan decision 290): the first point down Odran's road from the Citadel's gate where all four
## corners are walkable; the lane's foot when none is.
func _litter_spot() -> Vector2:
	for at: Vector2 in [citadel_door + Vector2(0.0, LITTER_SIDE), _road[1], _road[1] + Vector2(LITTER_SIDE, 0.0)]:
		var ok := true
		for k in 4:
			ok = ok and (crowd._grid == null or crowd._grid.walkable(at + _corner(k)))
		if ok:
			return at
	return _road[1]


## Odran comes out (v0.11 M6): with two or more bearers alive he climbs into the litter, hidden; else he walks his road on foot, LAST_GUARD
## more Knights behind him.
func _odran_comes() -> void:
	if odran_out:
		return
	odran_out = true
	if not _alive(odran):
		return
	var o := odran as Person
	o.pace *= ODRAN_PACE
	_road_at = 1
	if bearers_standing().size() >= 2:
		riding = true
		for b in bearers_standing():
			b.pace *= ODRAN_PACE
		o.ground_pos = litter_at
		return
	_set_on_foot(citadel_door)
	for k in LAST_GUARD:
		var p := Post.new()
		p.man = _knight(citadel_door)
		guards.append(p)
	for p: Post in bearers:
		if _alive(p.man):
			guards.append(p)


## Odran steps out at `at` (v0.11 M6): on foot, killable, on duty down his road.
func _set_on_foot(at: Vector2) -> void:
	riding = false
	var o := odran as Person
	if o.inside:
		_bring_out(o, _walkable(at))
		_keep_from_flight(o, true)
	o.go_duty(_road[mini(_road_at, _road.size() - 1)])


## The litter's bearers standing (v0.11 M6). Only reads.
func bearers_standing() -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in bearers:
		if not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## The Knights walking behind Odran (v0.11 M6). Only reads.
func last_guards() -> Array[Person]:
	var out: Array[Person] = []
	for p: Post in guards:
		if not p.done and _alive(p.man) and not (p.man as Person).inside:
			out.append(p.man as Person)
	return out


## The litter's middle, every frame while he rides (v0.11 M6): its bearers' places less their corners, averaged; Odran carried on it.
func _carry() -> void:
	var sum := Vector2.ZERO
	var n := 0
	for k in bearers.size():
		var p: Post = bearers[k]
		if not p.done and _alive(p.man):
			sum += (p.man as Person).ground_pos - _corner(k)
			n += 1
	if n > 0:
		litter_at = sum / float(n)
	if _alive(odran):
		(odran as Person).ground_pos = litter_at


## The litter, each look (v0.11 M6): below two bearers it falls; at the Temple's steps it sets him down; else its bearers walk on duty to
## the corners of a square LITTER_STEP further down his road.
func _step_litter() -> void:
	var alive := bearers_standing()
	if alive.size() < 2:
		rules.banner.emit("THE LITTER FALLS")
		_set_on_foot(litter_at)
		for p: Post in bearers:
			if _alive(p.man):
				guards.append(p)
		return
	if _road_at < _road.size() and litter_at.distance_to(_road[_road_at]) <= ARRIVE:
		_road_at += 1
	if _road_at >= _road.size() or litter_at.distance_to(steps_at) <= ALTAR_REACH:
		_road_at = _road.size() - 1
		_set_on_foot(litter_at)  # plan decision 291: set down at the steps, he rekindles on foot; the bearers stand
		return
	var to := litter_at.move_toward(_road[_road_at], LITTER_STEP)
	for k in bearers.size():
		var p: Post = bearers[k]
		if p.done or not _alive(p.man):
			continue
		var b := p.man as Person
		p.spot = _walkable(to + _corner(k))
		if b.mind != Person.Mind.DUTY or b.anchor.distance_to(p.spot) > MOVE:
			b.go_duty(p.spot)


## Odran on foot, each look (v0.11 M6): a fright stops him a moment (plan decision 296); on duty he walks his road point by point and holds
## at the Temple's steps; back on his feet he takes his road up again; a whisper is the god's. His guards walk GUARD_GAP behind him.
func _step_on_foot() -> void:
	var o := odran as Person
	if o.inside:
		return
	if o.mind == Person.Mind.PANIC:
		o.go_duty(o.ground_pos)
		return
	var goal := _road[mini(_road_at, _road.size() - 1)]
	if o.mind == Person.Mind.DUTY:
		if _road_at < _road.size() - 1 and o.ground_pos.distance_to(goal) <= ARRIVE:
			_road_at += 1
			o.go_duty(_road[_road_at])
		elif o.anchor.distance_to(goal) > MOVE:
			o.go_duty(goal)
	elif o.mind in RECALL_MINDS:
		o.go_duty(goal)
	var dir := goal - o.ground_pos
	dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var side := Vector2(-dir.y, dir.x)
	var k := 0
	for p: Post in guards:
		if p.done or not _alive(p.man) or (p.man as Person).inside:
			continue
		var g := p.man as Person
		var off := 0.0 if k == 0 else SIDE_STEP * (-1.0 if k % 2 == 1 else 1.0) * float((k + 1) / 2)
		var spot := _walkable(o.ground_pos - dir * GUARD_GAP + side * off)
		if g.mind != Person.Mind.POST or g.anchor.distance_to(spot) > 0.5:
			g.send_to_post(spot, false, false)
		k += 1


## The rekindling, every frame (v0.11 M6, Decision 237): on foot, on duty and within ALTAR_REACH of the steps, its seconds run; anything
## else starts it again from RITE; finished, the flame is kindled anew.
func _step_rite(delta: float) -> void:
	var o := odran as Person
	var at_altar := not o.inside and o.mind == Person.Mind.DUTY and o.ground_pos.distance_to(steps_at) <= ALTAR_REACH
	if not at_altar:
		if rite_on:
			rite_on = false
			rite_left = RITE
			rules.banner.emit("THE REKINDLING IS BROKEN")
		return
	if not rite_on:
		rite_on = true
		rite_left = RITE
		rules.banner.emit("ODRAN REKINDLES THE FLAME")
	rite_left -= delta
	if rite_left <= 0.0:
		kindled = true


## The flame still burning at BLESSED_AT (v0.11 M6, plan decision 294): blessed, the night lost.
func _bless() -> void:
	blessed = true


## A death (v0.11 M6): noted for the Gaze; Odran's ends him -- his Knights go home.
func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)
	if odran != null and is_instance_valid(odran) and e == odran and not odran_dead:
		odran_dead = true
		_knights_home()


## Odran leaving the town ends him as his death would (v0.11 M6): at once.
func _on_escaped(p: Person) -> void:
	if odran != null and is_instance_valid(odran) and p == odran and not odran_dead:
		odran_dead = true
		_knights_home()


## Every Knight still at work goes home (v0.11 M6).
func _knights_home() -> void:
	riding = false
	for list: Array in [posts, bearers, guards]:
		for p: Post in list:
			if not p.done:
				_go_home(p)


## Odran is down (v0.11 M6): killed, gone, or his body freed.
func odran_down() -> bool:
	return odran_dead or not _alive(odran)


## The stages are done (v0.11 M6): the flame out and Odran down -- StagesObjective's win.
func stages_done() -> bool:
	return flame_out and odran_down()


## Why the night is lost now (v0.11 M6): the flame kindled anew; the flame blessed; else "".
func lost_reason() -> String:
	if kindled:
		return "kindled"
	if blessed:
		return "blessed"
	return ""


## The HUD's main row (v0.11 M6): "Put out the flame 1 / 2: blessed in 2:10"; once it is out "Kill Odran", or "Kill Odran: in his litter".
func hud_line() -> String:
	if not flame_out:
		return "Put out the flame %d / %d: blessed in %s" % [razed_count(), targets.size(),
			UiTheme.clock(timeline.seconds_to("blessed") if timeline != null else 0.0)]
	return "Kill Odran: in his litter" if riding else "Kill Odran"


## The current target: the first in use and not razed, or -1 (v0.11 M6).
func current() -> int:
	for i in targets.size():
		if in_use[i] and not razed(targets[i]):
			return i
	return -1


## The next target: the first not razed and not yet in use, or -1 (v0.11 M6).
func next_target() -> int:
	for i in targets.size():
		if not razed(targets[i]) and not in_use[i]:
			return i
	return -1


## The map tags, most important first (v0.11 M6, mission spec §3). Stage one: the target in use, gold and pointed at ("- GUARDED",
## "- SET IT ALIGHT", or "- BURNING n" orange); the next one, grey and pointed at, with its sooner time; KNIGHT on each Knight on guard, a
## red diamond on a relief walking in, a small red mark on one away. Stage two: Odran in the Citadel (grey, his chain's seconds once the
## flame is out), in his litter, on foot or rekindling (gold, pointed at); BEARER on each bearer; KNIGHT on his guards; the ALTAR at the
## steps, orange, pointed at, once he is out.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if lost_reason() != "" or stages_done():
		return out
	if not flame_out:
		var cur := current()
		if cur >= 0 and is_instance_valid(targets[cur]) and not targets[cur].destroyed:
			var s := targets[cur]
			var label := "%s - SET IT ALIGHT" % NAMES[cur]
			var col := MARK_TARGET
			if not guards_at(cur).is_empty():
				label = "%s - GUARDED" % NAMES[cur]
			elif burning(s):
				label = "%s - BURNING %d" % [NAMES[cur], ceili(maxf(_spoil_for(s) - burned(s), 0.0))]
				col = MARK_BURNING
			out.append(MapTag.place(s.center(), col, label, s.height, true))
		var n := next_target()
		if n >= 0 and is_instance_valid(targets[n]):
			var s := targets[n]
			var when := UiTheme.clock(stage_due(n))
			var label := ("%s - DOWN, COUNTS AT %s" % [NAMES[n], when]) if s.destroyed else ("%s - %s %s" % [NAMES[n], NEXT_WORDS[n], when])
			out.append(MapTag.place(s.center(), MARK_NOT_YET, label, 0.0 if s.destroyed else s.height, true))
	if not odran_out:
		var words := "ODRAN - COMES OUT IN %d" % ceili(timeline.seconds_to("odran")) if flame_out and timeline != null else "ODRAN - IN THE CITADEL"
		out.append(MapTag.place(citadel_door, MARK_NOT_YET, words, 0.0, false))
	elif riding:
		out.append(MapTag.person(litter_at, MARK_TARGET, "ODRAN - IN HIS LITTER", true))
	elif _alive(odran) and not (odran as Person).inside:
		out.append(MapTag.person((odran as Person).ground_pos, MARK_TARGET, "ODRAN - REKINDLING %d" % ceili(rite_left) if rite_on else "ODRAN", true))
	if odran_out:
		out.append(MapTag.place(steps_at, MARK_PLACE, "ALTAR", 0.0, true))
	if flame_out and (riding or not odran_out):
		for b in bearers_standing():
			out.append(MapTag.person(b.ground_pos, MARK_WATCHED, "BEARER"))
	for g in last_guards():
		out.append(MapTag.person(g.ground_pos, MARK_WATCHED, "KNIGHT"))
	if not flame_out:
		for p: Post in posts:
			if p.done or not _alive(p.man) or (p.man as Person).inside:
				continue
			var k := p.man as Person
			if _on_guard(p):
				out.append(MapTag.person(k.ground_pos, MARK_WATCHED, "KNIGHT"))
			elif p.relief:
				out.append(MapTag.person(k.ground_pos, MARK_WATCHED))
			else:
				out.append(MapTag.pip(k.ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M6, plan decision 303): stage two "coming", "litter", "rite", "on_foot"; stage one "guarded", "burning", "open"
## for the target in use, "not_yet" within WORK_AHEAD of the next one's time; else "".
func hint_phase() -> String:
	if lost_reason() != "" or stages_done():
		return ""
	if flame_out:
		if not odran_out:
			return "coming"
		if riding:
			return "litter"
		return "rite" if rite_on else "on_foot"
	var cur := current()
	if cur >= 0:
		if not guards_at(cur).is_empty():
			return "guarded"
		return "burning" if burning(targets[cur]) else "open"
	var n := next_target()
	if n >= 0 and stage_due(n) - _clock <= WORK_AHEAD:
		return "not_yet"
	return ""


## The seconds the hint counts down (v0.11 M6): Odran's chain in "coming", the rite's in "rite"; else 0.
func hint_seconds() -> float:
	match hint_phase():
		"coming":
			return timeline.seconds_to("odran") if timeline != null else 0.0
		"rite":
			return maxf(rite_left, 0.0)
	return 0.0


## The tour (v0.11 M6, mission spec §3): the oil-house, the Temple, the Citadel.
func tour() -> Array:
	var out := []
	if oil_house != null:
		out.append([oil_house.center(), "The oil-house. Its Knights guard it. It feeds the flame from %s: burn it." % UiTheme.clock(float(STAGE_AT[0]))])
	if temple != null:
		out.append([temple.center(), "The Great Temple. The flame blazes here by %s. Burn it down to put the flame out." % UiTheme.clock(float(STAGE_AT[1]))])
	out.append([citadel_door, "The Citadel. High Priest Odran waits here. Once the flame is out he comes to rekindle it: kill him."])
	return out


## What the results show (v0.11 M6): targets razed, the flame out, Odran down, the losses, the reliefs, the Gaze.
func report() -> Dictionary:
	return {"razed": razed_count(), "flame_out": flame_out, "odran_dead": odran_down(), "kindled": kindled, "blessed": blessed,
		"reliefs": reliefs, "gaze": gaze.value}


## Lets go of the kills, the crowd's exits, the targets on the engineers' list, then the Raze type's (every seal, the timeline) (v0.11 M6).
## Safe to call twice.
func teardown() -> void:
	_unhook_kills(_on_killed)
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	if is_instance_valid(crowd) and crowd.engineers != null:
		for s in targets:
			if is_instance_valid(s):
				crowd.engineers.hands_off.erase(s)
	super()
```

- [ ] **Step 4: The mission.** In `mission_book.gd`, `tier_missions()` gains `heart_of_faith()` at its end, and after `exodus()` add:

```gdscript
## The Heart of Faith (v0.11 M6, Tier 5, mission spec §3 and §8 row 25): burn the oil-house and the Great Temple under their Lantern
## Knights to put out Halcyon's Great Flame, then kill High Priest Odran, borne to the Temple's steps in his litter, before he rekindles it
## (HeartOfFaithDirector, a staged Raze and an Assassinate of its own).
static func heart_of_faith() -> MissionDef:
	var m := _tier5(HEART_OF_FAITH, "The Heart of Faith", PackedStringArray(["Halcyon's Great Flame burns in his Temple.",
		"Put it out. Then kill his High Priest."]))
	m.goal = "Burn the oil-house and the Great Temple to put out the Great Flame by %s, then kill High Priest Odran before he rekindles it" % UiTheme.clock(
		HeartOfFaithDirector.BLESSED_AT)
	m.goal_label = "The Heart of Faith is broken"
	m.lose = "The flame is blessed at %s, Odran rekindles it, Halcyon's Gaze fills, or dawn comes" % UiTheme.clock(HeartOfFaithDirector.BLESSED_AT)
	m.camera_at = HeartOfFaithDirector.CAMERA_AT
	m.intro_from = m.camera_at + Vector2(0.0, 6.0)
	m.default_loadout = PackedStringArray(["doom", "smite", "ember", "whisper", "heaven"])
	m.director = HeartOfFaithDirector
	m.mission_tags = PackedStringArray(["burns_temple"])
	m.make_objectives = func() -> Array[Objective]:
		var out: Array[Objective] = [StagesObjective.new("Put out the flame", "heart"), GazeObjective.new(),
			ClockObjective.new(false, "Dawn", "dawn")]
		return out
	return m
```

- [ ] **Step 5: The hints and the titles.**
  - `LINES` gains:

```gdscript
	"heart_of_faith": "Burn the oil-house, then the Temple (gold), once their Knights (red) are dead: the Great Flame goes out. Then kill High Priest Odran.",
	"heart_of_faith.not_yet": "Not in use yet (grey): fire there goes out, but a fall counts when its time comes. Kill its Knights (red) shortly before.",
	"heart_of_faith.guarded": "Lantern Knights (red) guard it: it takes no harm and its fire goes out. Kill every one: whispers and Discord do not touch a Knight.",
	"heart_of_faith.open": "No Knight stands. Set it alight (gold) and keep it burning.",
	"heart_of_faith.burning": "It burns. Keep it burning: a new Knight comes from the Citadel.",
	"heart_of_faith.coming": "The flame is out. Odran comes out in {n} s: kill his bearers (red) at the Citadel's gate first. Halcyon looks harder now. Each seen death now adds 20 to the Gaze.",
	"heart_of_faith.litter": "Odran rides in his litter, untouchable. Kill his bearers (red): with fewer than two, it falls. Each seen death now adds 20 to the Gaze.",
	"heart_of_faith.on_foot": "Odran walks to the Temple's steps (orange). Kill him before he rekindles the flame. Each seen death now adds 20 to the Gaze.",
	"heart_of_faith.rite": "Odran rekindles the flame. Kill him now, or whisper him off the steps to start it again. Each seen death now adds 20 to the Gaze.",
```

    (the stage-two lines carry the Gaze's sentence last; `Hud.hint_lines()` keeps at most HINT_LINES lines, so it shows "while room
    allows", as the spec asks).
  - `ACT_TITLES` gains `"heart": "THE HEART OF FAITH IS BROKEN", "blessed": "THE GREAT FLAME IS BLESSED", "kindled": "THE FLAME IS KINDLED ANEW"`.
    First `grep -n '"heart"\|"blessed"\|"kindled"' src/game/ui/results_screen.gd`: if M5 already used one of these keys, stop and report
    (the keys are the mission's own, M2 decision 63).

- [ ] **Step 6: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 40.

- [ ] **Step 7: The scenario.** In `tools/dev/behaviour_check.gd`:
  - The header comment gains:

```gdscript
##   heart  (v0.11 M6) The Heart of Faith, --case=none (nothing cast) or play, as a player plays it (_heart_act(): Odran on foot out of
##          doors -- Silent Doom on him unseen, else Smite; his rite running with neither ready -- Mind Whisper sends him four units off the
##          steps; riding, or his bearers waiting -- a bearer Doomed unseen, else Smitten; his last guard within 3 of him -- the same; the
##          target in use guarded -- a Knight Doomed unseen, else Smitten; unguarded and not burning -- Ember (Smite while Ember cools); the
##          next target within HEART_AHEAD of its time -- its standing Knights Doomed one at a time; a relief walking in -- Silent Doom; it
##          never fells a target ahead of its time; the result line gives the longest idle stretch). Hit-stop is off for it. --seed=,
##          --board as ringers.
```

  - Constants:

```gdscript
## The Heart of Faith's policy (v0.11 M6): how soon before the next target it clears that target's Knights; how far off the steps its
## whisper sends Odran; how near Odran his last guard is answered.
const HEART_AHEAD := 25.0
const HEART_OFF := 4.0
const HEART_GUARD := 3.0
```

  - `_run()`: `elif scenario == "heart":` with `powers = PackedStringArray(["doom", "smite", "ember", "whisper", "heaven"])` and
    `mission.mission_id = MissionBook.HEART_OF_FAITH`; the hit-stop list gains `"heart"`; `match scenario:` gains
    `"heart": await _heart(Battlefield.arg_value(args, "--case"))`.
  - After `_exodus_act()` add:

```gdscript
## The Heart of Faith (v0.11 M6), with mission spec §3's policy (_heart_act()), through _scripted().
func _heart(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as HeartOfFaithDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("heart", which, func() -> String: return _heart_act(rules, slots, d, crowd),
		func() -> String: return "razed=%d flame_out=%s odran=%s riding=%s rite=%.0f gaze=%d phase=%s" % [d.razed_count(), d.flame_out,
			d.odran_out, d.riding, d.rite_left, roundi(d.gaze.value), d.hint_phase()])


## Strikes one of `who` (v0.11 M6): Silent Doom on the first whose Doom goes unseen; else, with `smite_ok`, Smite the first. "" when no slot
## serves.
func _heart_strike(rules: Rules, slots: Dictionary, crowd: Crowd, who: Array[Person], smite_ok: bool, what: String) -> String:
	if who.is_empty():
		return ""
	if _slot_ready(rules, slots, "doom"):
		for p in who:
			if _doom_unseen(crowd, p.ground_pos):
				rules.cast(slots.doom, p.ground_pos)
				return "doom %s" % what
	if smite_ok and _slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, who[0].ground_pos)
		return "smite %s" % what
	return ""


## One look of The Heart of Faith's policy (v0.11 M6, mission spec §3): what was cast, or "". The first that applies: Odran on foot; his
## rite with no strike ready; his bearers; his last guard; the target in use guarded; the target in use open and not burning; the next
## target's standing Knights within HEART_AHEAD; a relief walking in. Never a blow on a target ahead of its time.
func _heart_act(rules: Rules, slots: Dictionary, d: HeartOfFaithDirector, crowd: Crowd) -> String:
	if d.odran_out and not d.riding and not d.odran_down() and not (d.odran as Person).inside:
		var o := d.odran as Person
		var only: Array[Person] = [o]
		var did := _heart_strike(rules, slots, crowd, only, true, "Odran")
		if did != "":
			return did
		if d.rite_on and _slot_ready(rules, slots, "whisper") and not o.shaken():
			var off := o.ground_pos + (o.ground_pos - d.temple.center()).normalized() * HEART_OFF
			rules.cast(slots.whisper, o.ground_pos, {"target": o, "to": MindWhisperFx.clamp_to(crowd._grid, o.ground_pos, off)})
			return "whisper Odran off the steps"
	if d.flame_out and (d.riding or not d.odran_out):
		var did := _heart_strike(rules, slots, crowd, d.bearers_standing(), true, "a bearer")
		if did != "":
			return did
	if d.odran_out and not d.odran_down() and not (d.odran as Person).inside:
		var near: Array[Person] = []
		for g in d.last_guards():
			if g.ground_pos.distance_to((d.odran as Person).ground_pos) <= HEART_GUARD:
				near.append(g)
		var did := _heart_strike(rules, slots, crowd, near, true, "his last guard")
		if did != "":
			return did
	if d.flame_out:
		return ""
	var cur := d.current()
	if cur >= 0:
		var s := d.targets[cur]
		var on := d.guards_at(cur)
		if not on.is_empty():
			var did := _heart_strike(rules, slots, crowd, on, true, "a Knight at the %s" % HeartOfFaithDirector.WORDS[cur])
			if did != "":
				return did
		elif is_instance_valid(s) and not s.destroyed and not d.burning(s):
			if _slot_ready(rules, slots, "ember"):
				rules.cast(slots.ember, s.center())
				return "ember the %s" % HeartOfFaithDirector.WORDS[cur]
			if _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the %s" % HeartOfFaithDirector.WORDS[cur]
	var n := d.next_target()
	if n >= 0 and n != cur and d.stage_due(n) - d._clock <= HEART_AHEAD:
		var did := _heart_strike(rules, slots, crowd, d.standing_at(n), false, "a Knight ahead at the %s" % HeartOfFaithDirector.WORDS[n])
		if did != "":
			return did
	var walker := d.relief_walking()
	if walker != null:
		var one: Array[Person] = [walker]
		var did := _heart_strike(rules, slots, crowd, one, false, "a relief Knight")
		if did != "":
			return did
	return ""
```

    (A Smite on a Knight at a target in use hits the sealed target too, which only shakes; the policy never casts on a target before its
    time, as the spec asks.)

- [ ] **Step 8: Run it once.** `--scenario=heart --case=play --seed=1`. Expected: lines every 10 s, cast lines, a result line, no
  `SCRIPT ERROR`. Read them: the standing Knights of each target cleared in the 25 s before its time; Ember on an open target; the bearers
  Doomed one at a time inside Odran's chain; Odran killed on foot. Fix the policy until it plays the spec's steps.

- [ ] **Step 9: The gate.** Run the Scenario loop for `heart`.
  - Expected for `none`: `won=false reason=blessed` at 300.0 in each.
  - Expected for `play`: at least 2 of 3 won, the median won time 180-240 s, `idle` 45 s or less; the Gaze 0-30% (write the values).
  - Tuning order: CHAIN (35-45), STAGE_AT[0] (40-60), SPOIL[1] (15-25), ODRAN_CHAIN (20-30), ARRIVING (1-3); ODRAN_PACE (0.25-0.5) if Odran
    reaches the steps before the policy can act (plan decision 292). After checking the policy; three rounds at most; record each.
  - Write the measured clear's sum next to the spec's (≈ 197 s) in the commit body.

- [ ] **Step 10: Spec sync.** §3's `Numbers`, timeline (Odran's walk at its measured seconds, plan decision 292), clear and hint lines; add
  the litter set down at the steps (plan decision 291).

- [ ] **Step 11: The Reference check, and FLOW.** Every old value unchanged, the `eye` and `exodus` twelve as recorded; FLOW 113/0, alone.

- [ ] **Step 12: Commit.**

```bash
git add src/game/mission/heart_of_faith_director.gd src/game/mission/heart_of_faith_director.gd.uid src/game/mission/mission_book.gd src/game/mission/mission_hints.gd src/game/ui/results_screen.gd tools/dev/behaviour_check.gd docs/superpowers/specs/2026-10-15-kak-v011-m6-ascendance-missions.md tests/test_heart_of_faith.gd tests/test_heart_of_faith.gd.uid tests/run_all.gd
git commit -m "feat: The Heart of Faith -- burn the oil-house and the Temple under Lantern Knights, then kill Odran before he rekindles the flame (v0.11 M6)" -m "<heart none/play seeds 1-3 (the six new references); the eye and exodus twelve unchanged; the gate's verdict; tuning rounds; the clear's sum; the Gaze per run; the halves' counts; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Two new wishes for Ascendance

**Files:**
- Modify: `src/game/descend/punish_wish.gd` (`"clergy"`, new `clergy()`)
- Modify: `src/game/descend/neighbours_wish.gd` (`"count"`, `"clergy"`, `"label"`, `"edge"`, `"route"`; new `_count()`, `_label()`,
  `_priest_for()`)
- Modify: `src/game/descend/wish_book.gd` (the two wishes; `shuts_gates` on `brother` and `family_out`)
- Modify: the tests that pin the pool's contents (found in Step 1)
- Create: `tests/test_tier5_wishes.gd`; Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `PunishWish`, `NeighboursWish`, `Wish.lay()`, `WishBook.pool()` / `pool_for()` / `draw()` / `clashes()`; M5's `heretic` and
  `family_out` wishes; Task 7's `HeartOfFaithDirector.odran`; the kit.
- Produces: `PunishWish.clergy(crowd: Crowd, taken: Array) -> Array[Person]`; `NeighboursWish._count() -> int`, `_label() -> String`,
  `_priest_for(w: Person, crowd: Crowd, taken: Array) -> Person`; the wish ids `zealot` and `priest` (`min_tier` 5).

- [ ] **Step 1: Find the pins.** Run `grep -rn "pool().size()\|pool_for(\|all.slice\|\"family_out\"\|\"brother\"" tests/`. Write the list in the
  report. Expected: the pool-content pins in `test_wishes.gd`, `test_wish_kinds.gd` (`_pool`'s id list), `test_tier2_wishes.gd`,
  `test_tier3_wishes.gd`, M5's `test_tier4_wishes.gd`, and any check of `brother`'s or `family_out`'s clashes. Then
  `grep -rn "seed_for\|Descent.new" tests/ | grep -i "last_judgement\|long_night\|tier5\|TierBook.board(\"\(last\|long\)"` for a pinned Tier 5
  draw (plan decision 299): at this plan's writing there is none; name any M5 added.

- [ ] **Step 2: Write the failing test.** Create `tests/test_tier5_wishes.gd`:

```gdscript
extends RefCounted
## v0.11 M6 Ascendance's two new wishes (mission spec §5): "Strike down the zealot, unseen" (PunishWish with clergy and unseen) and "Turn the
## doubting priest" (NeighboursWish with count 1 and clergy), both heard from Tier 5 only, so Tier 1-4 nights shuffle what they always did;
## the old wishes' defaults exact; the shuts_gates clash keeps both escape wishes off Exodus; the pyre keeps off burns_temple; a reserved
## cleric is never Odran.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")


static func run(t) -> void:
	_pool(t)
	_kept(t)
	_zealot(t)
	_priest(t)
	_clashes(t)
	_zealot_not_odran(t)


static func _ids(defs: Array[WishDef]) -> Array:
	var out := []
	for d in defs:
		out.append(d.id)
	return out


static func _def(id: String) -> WishDef:
	for d in WishBook.pool():
		if d.id == id:
			return d
	return null


## A wish chosen in `s`'s town with the given seed (v0.11 M6 tests); null when its town cannot give it.
static func _wish(s: Dictionary, id: String, seed_n := 3) -> Wish:
	var r := RandomNumberGenerator.new()
	r.seed = seed_n
	var w := _def(id).instance()
	return w if w.choose(s.crowd, s.town, r, []) else null


static func _pool(t) -> void:
	var all := _ids(WishBook.pool())
	t.check(all.size() == 18 and all.slice(16) == ["zealot", "priest"], "the pool: M5's sixteen, then Ascendance's two (%s)" % [all])
	var z := _def("zealot")
	var p := _def("priest")
	t.check(z.text == "Strike down the zealot, unseen" and z.kind == "punish" and z.reward == 15 and z.min_tier == 5 and z.runner == PunishWish
		and bool(z.params.clergy) and bool(z.params.unseen) and bool(z.params.edge) and String(z.params.label) == "ZEALOT" and z.clashes.is_empty()
		and p.text == "Turn the doubting priest" and p.kind == "faith" and p.reward == 15 and p.min_tier == 5 and p.runner == NeighboursWish
		and int(p.params.count) == 1 and bool(p.params.clergy) and String(p.params.label) == "DOUBTING PRIEST" and is_equal_approx(float(p.params.route), 30.0),
		"their words, kinds, rewards and parameters; heard from Ascendance up")
	t.check(_ids(WishBook.pool_for(1)) == all.slice(0, 10) and _ids(WishBook.pool_for(2)) == all.slice(0, 12)
		and _ids(WishBook.pool_for(3)) == all.slice(0, 14) and _ids(WishBook.pool_for(4)) == all.slice(0, 16) and _ids(WishBook.pool_for(5)) == all,
		"Tiers 1-4 draw from exactly the pools they did (pool_for() filters before the shuffle); Ascendance from all eighteen")


static func _kept(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var tax := _wish(s, "tax_collector") as PunishWish
	t.check(tax != null and tax.target.profile.role != CitizenProfile.Role.CLERGY and not tax.target.soldier, "the tax collector is still a lay citizen")
	var n := _wish(s, "neighbours") as NeighboursWish
	t.check(n != null and n.neighbours.size() == NeighboursWish.COUNT and n._count() == 3 and n._label() == NeighboursWish.LABEL
		and n.hud_text(s.rules).ends_with("0 / 3"), "Let my neighbours believe: still three neighbours, NEIGHBOUR, 0 / 3")
	tax.release()
	Kit.done(s)


static func _zealot(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var w := _wish(s, "zealot") as PunishWish
	var z := w.target
	t.check(w != null and z.profile.role == CitizenProfile.Role.CLERGY and not z.inside and w.wisher.profile.role != CitizenProfile.Role.CLERGY
		and w.tags()[0].label == "ZEALOT" and w.tags()[0].edge, "a cleric out of doors, marked ZEALOT and pointed at; a lay wisher")
	var crowd: Crowd = s.crowd
	for p in crowd.citizens:
		if MissionDirector._alive(p) and p != z and p.ground_pos.distance_to(z.ground_pos) <= Crowd.DOOM_WITNESS + 0.2:
			Kit.arrive(p, p.ground_pos + Vector2(8.0, 8.0))
	crowd._field.kill(z, &"fire")
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE, "killed with no living witness: granted")
	w.release()
	var seen := _wish(s, "zealot", 5) as PunishWish
	var witness := seen.wisher
	Kit.arrive(witness, seen.target.ground_pos + Vector2(1.0, 0.0))
	crowd._field.kill(seen.target, &"fire")
	seen.step(s.rules, DT)
	t.check(seen.check(s.rules) == Objective.Status.FAILED, "killed before a witness: failed")
	seen.release()
	Kit.done(s)


static func _priest(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var w := _wish(s, "priest") as NeighboursWish
	var priest := w.neighbours[0] as Person
	var path := (s.crowd as Crowd)._grid.path(priest.ground_pos, w.wisher.ground_pos)
	var walk := 0.0
	for k in range(path.size() - 1):
		walk += path[k].distance_to(path[k + 1])
	t.check(w != null and w.neighbours.size() == 1 and priest.profile.role == CitizenProfile.Role.CLERGY and walk <= 30.0
		and w.tags()[0].label == "DOUBTING PRIEST" and w.tags()[0].edge and w.hud_text(s.rules).ends_with("0 / 1"),
		"one cleric within 30 units of street of the wisher, DOUBTING PRIEST, pointed at (%.1f units)" % walk)
	priest.whisper(w.wisher.ground_pos, MindWhisperFx.LINGER)
	Kit.arrive(priest, w.wisher.ground_pos + Vector2(1.0, 0.0))
	w.step(s.rules, DT)
	t.check(w.check(s.rules) == Objective.Status.DONE and priest.profile.faith == CitizenProfile.Faith.BELIEVER,
		"whispered to within 2 of the wisher he believes: granted")
	var dies := _wish(s, "priest", 9) as NeighboursWish
	Kit.free_body(s, dies.neighbours[0])
	t.check(dies.check(s.rules) == Objective.Status.FAILED, "the priest dead before believing: failed")
	Kit.done(s)


static func _clashes(t) -> void:
	var s := Kit.world(MissionBook.warning(), MissionDirector.new())
	var heard := {}
	var near_temple := {}
	for n in 60:
		var r := RandomNumberGenerator.new()
		r.seed = 1000 + n
		for w in WishBook.draw(WishBook.pool_for(5), 3, PackedStringArray(["shuts_gates"]), s.crowd, s.town, r):
			heard[w.def.id] = true
			w.release()
		var r2 := RandomNumberGenerator.new()
		r2.seed = 2000 + n
		for w in WishBook.draw(WishBook.pool_for(5), 3, PackedStringArray(["burns_temple"]), s.crowd, s.town, r2):
			near_temple[w.def.id] = true
			w.release()
	t.check(not heard.has("brother") and not heard.has("family_out") and WishBook.clashes(_def("brother"), PackedStringArray(["shuts_gates"]))
		and WishBook.clashes(_def("family_out"), PackedStringArray(["shuts_gates"])) and not near_temple.has("heretic")
		and (heard.has("zealot") or heard.has("priest")), "sixty draws: shuts_gates keeps both escape wishes away, burns_temple the pyre (%s)" % [heard.keys()])
	Kit.done(s)


static func _zealot_not_odran(t) -> void:
	var a := Kit.world(MissionBook.heart_of_faith())
	var ix := (a.crowd as Crowd).citizens.find((a.d as HeartOfFaithDirector).odran)
	Kit.done(a)
	var b := Kit.world(MissionBook.heart_of_faith(), null, func(d: MissionDirector, rules: Rules) -> void:
		d.reserved.append(rules.crowd().citizens[ix]))
	var odran: Variant = (b.d as HeartOfFaithDirector).odran
	t.check(ix >= 0 and MissionDirector._alive(odran) and odran != (b.crowd as Crowd).citizens[ix] and (odran as Person).profile.role == CitizenProfile.Role.CLERGY,
		"a cleric a wish has taken (the zealot, drawn before Odran is chosen) is passed over: Odran is the next")
	Kit.done(b)
```

  - In `tests/run_all.gd`, append `"res://tests/test_tier5_wishes.gd",` at the end of `SUITES`.

- [ ] **Step 3: Run the test to verify it fails.** Expected: FAILs in `test_tier5_wishes` (no `zealot`, no `priest`, the pool sixteen).

- [ ] **Step 4: The zealot.** In `src/game/descend/punish_wish.gd`:
  - The class doc gains: `## v0.11 M6: "clergy" -- the target is a living cleric out of doors, not taken (clergy()), at random: "Strike down the zealot,`
    `## unseen". Its default, false, keeps the tax collector, the informer and the sergeant exact.`
  - In `choose()`, before `if bool(def.params.get("soldier", false)):` add:

```gdscript
	if bool(def.params.get("clergy", false)):
		# v0.11 M6: a cleric and a lay wisher, both checked before either is taken.
		var priests := clergy(crowd, taken)
		if priests.is_empty() or Wish.lay(crowd, taken).is_empty() or not super(crowd, town, rng, taken):
			return false
		target = priests[rng.randi_range(0, priests.size() - 1)]
		taken.append(target)
		crowd._field.enemy_killed.connect(_on_killed)
		return true
```

  - After `soldiers()` add:

```gdscript
## The clerics a zealot may be (v0.11 M6, mission spec §5): living, out of doors, of the clergy, none of `taken`, in the crowd's order. Each
## read as a Variant and through MissionDirector._alive() before any member.
static func clergy(crowd: Crowd, taken: Array) -> Array[Person]:
	var out: Array[Person] = []
	for v: Variant in crowd.citizens:
		if not MissionDirector._alive(v):
			continue
		var p := v as Person
		if not p.inside and p.profile != null and p.profile.role == CitizenProfile.Role.CLERGY and not taken.has(p):
			out.append(p)
	return out
```

- [ ] **Step 5: The priest.** In `src/game/descend/neighbours_wish.gd`:
  - The class doc gains: `## v0.11 M6: params "count" (COUNT by default), "clergy" -- the one brought is a cleric out of doors whose street walk to`
    `## the wisher is at most "route" units, the nearest so ("Turn the doubting priest") -- "label" (LABEL) and "edge" (false). The defaults keep`
    `## Let my neighbours believe exact.`
  - Replace `choose()` with:

```gdscript
## A lay wisher with a home and _count() neighbours -- or, with "clergy", a cleric within "route" of street (v0.11 M6) -- false when no
## one in the town has them (v0.11 M2). Wishers are tried from a random start.
func choose(crowd: Crowd, _town: Town, rng: RandomNumberGenerator, taken: Array) -> bool:
	_crowd = crowd
	var pool := Wish.lay(crowd, taken)
	if pool.is_empty():
		return false
	var start := rng.randi_range(0, pool.size() - 1)
	var clergy := bool(def.params.get("clergy", false))
	for k in pool.size():
		var w := pool[(start + k) % pool.size()]
		if clergy:
			var priest := _priest_for(w, crowd, taken)
			if priest == null:
				continue
			wisher = w
			neighbours = [priest]
			taken.append(wisher)
			taken.append(priest)
			return true
		if w.profile.home == Vector2.INF:
			continue
		var near := _neighbours_of(w, pool, crowd._grid)
		if near.size() >= _count():
			wisher = w
			neighbours = near.slice(0, _count())
			taken.append(wisher)
			taken.append_array(neighbours)
			return true
	return false


## How many must believe (v0.11 M6): the "count" param, COUNT by default.
func _count() -> int:
	return int(def.params.get("count", COUNT)) if def != null else COUNT


## The tag on each who has yet to believe (v0.11 M6): the "label" param, LABEL by default.
func _label() -> String:
	return String(def.params.get("label", LABEL)) if def != null else LABEL


## The cleric for wisher `w` (v0.11 M6): living, out of doors, none of `taken`, whose street walk to `w` is the shortest and at most the
## "route" param; null for none. With no walk grid, the straight distance.
func _priest_for(w: Person, crowd: Crowd, taken: Array) -> Person:
	var reach := float(def.params.get("route", 0.0))
	var best: Person = null
	var best_walk := INF
	for v: Variant in crowd.citizens:
		if not MissionDirector._alive(v) or v == w:
			continue
		var p := v as Person
		if p.inside or p.profile == null or p.profile.role != CitizenProfile.Role.CLERGY or taken.has(p):
			continue
		var walk := p.ground_pos.distance_to(w.ground_pos)
		if crowd._grid != null:
			var path := crowd._grid.path(p.ground_pos, w.ground_pos)
			if path.is_empty():
				continue
			walk = 0.0
			for k in range(path.size() - 1):
				walk += path[k].distance_to(path[k + 1])
		if (reach <= 0.0 or walk <= reach) and walk < best_walk:
			best = p
			best_walk = walk
	return best
```

  - In `_act()`, `COUNT` becomes `_count()`; in `hud_text()`, the last `COUNT` becomes `_count()`; `_target_tags()` becomes:

```gdscript
## The label on each who has yet to believe (v0.11 M2: NEIGHBOUR; v0.11 M6: _label(), pointed at from the edge with "edge").
func _target_tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	for p: Variant in neighbours:
		if MissionDirector._alive(p) and not (p as Person).inside and not believing.has(p):
			out.append(MapTag.person((p as Person).ground_pos, COLOR, _label(), bool(def.params.get("edge", false))))
	return out
```

- [ ] **Step 6: The pool.** In `src/game/descend/wish_book.gd`:
  - `pool()`'s doc gains `, and v0.11 M6's two for Ascendance`; `WishDef.make("brother", "Lead my brother out", "mercy", 10, MercyWish)` becomes
    `WishDef.make("brother", "Lead my brother out", "mercy", 10, MercyWish, {}, PackedStringArray(["shuts_gates"]))`; M5's `family_out`
    line's `PackedStringArray()` becomes `PackedStringArray(["shuts_gates"])`; at the end of the list add:

```gdscript
		WishDef.make("zealot", "Strike down the zealot, unseen", "punish", 15, PunishWish,
			{"label": "ZEALOT", "unseen": true, "clergy": true, "edge": true}, PackedStringArray(), 5),
		WishDef.make("priest", "Turn the doubting priest", "faith", 15, NeighboursWish,
			{"count": 1, "clergy": true, "label": "DOUBTING PRIEST", "edge": true, "route": 30.0}, PackedStringArray(), 5),
```

- [ ] **Step 7: Re-pin the pool's contents.** In each file Step 1 found, the pinned pool grows by the two new ids at the end
  (`pool().size()` 16 to 18; `test_wish_kinds._pool`'s list gains `"zealot", "priest"`; a `pool_for(4) == all` becomes
  `pool_for(4) == all.slice(0, 16)`); a pinned empty clash list for `brother` or `family_out` becomes `["shuts_gates"]`; and any Tier 5
  draw pin (plan decision 299) is re-pinned to what the new pool draws. Change nothing else, and name every edited check in the commit
  body.

- [ ] **Step 8: Run the tests to verify they pass.** Run Import, then the halves. Expected: `failures=0`, the count up by about 12.

- [ ] **Step 9: The Reference check, and FLOW.** Every value unchanged (the scenarios hear no wishes; the board's Tier 1-4 draws are
  unchanged), the M6 eighteen as recorded; FLOW 113/0, alone.

- [ ] **Step 10: Commit.**

```bash
git add src/game/descend/punish_wish.gd src/game/descend/neighbours_wish.gd src/game/descend/wish_book.gd tests/test_tier5_wishes.gd tests/test_tier5_wishes.gd.uid tests/run_all.gd <the re-pinned test files>
git commit -m "feat: two wishes for Ascendance -- strike down the zealot unseen, turn the doubting priest (v0.11 M6)" -m "<the re-pinned checks by name; whether any Tier 5 draw was pinned; the halves' counts; the Reference check; FLOW 113/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9: Tier 5 complete on the board, and the board complete

**Files:**
- Modify: `src/game/descend/tier_book.gd` (`MISSIONS`, `TYPES`, `MISSION_TAGS`, `NEED`'s doc)
- Modify: `src/game/descend/descend_state.gd` (`progress_line()`, new `all_cleared()`)
- Modify: `src/game/ui/mission_board.gd` (`header_text()`)
- Modify: `src/game/game.gd` (`_flow_board()`, new `_flow_tier5()` and its call in `_flow_test()`, the `tiers` photo's save)
- Create: `tests/test_tier5_board.gd`
- Modify: `tests/test_tiers.gd` (`_table()`, `_unlock()`), `tests/run_all.gd`

**Interfaces:**
- Consumes: Tasks 4-8 (`LanternEyeDirector.towers` / `steps` / `wrights` / `_raise()` / `_gone()` / `STEP_AT` / `CHAIN` / `DRAIN` / `REHANG` /
  `EYE_OPENS` / `RETURN_AFTER` / `RELIEF_AFTER`; `ExodusDirector.households` / `watch` / `patrols` / `OUT_AT` / `CHAIN` / `HUNT_AFTER` /
  `SHUT_AT` / `RETURN_AFTER` / `RELIEF_AFTER`; `HeartOfFaithDirector.posts` / `odran` / `oil_house` / `STAGE_AT` / `CHAIN` / `ODRAN_CHAIN` /
  `RITE` / `RELIEF_AFTER` / `BLESSED_AT`; `MissionBook.LANTERN_EYE`, `lantern_eye()`); the kit; `Descent.reserve()`; M5's `_flow_board()`
  and `_flow_tier4()`.
- Produces: `TierBook.missions(5) == ["last_judgement", "long_night", "lantern_eye", "exodus", "heart_of_faith"]`, `TierBook.need(5) == 3`;
  the three types; `TierBook.mission_tags("exodus") == ["shuts_gates"]`, `("heart_of_faith") == ["burns_temple"]`;
  `DescendState.all_cleared() -> bool`; "All 25 cleared"; FLOW 114.

- [ ] **Step 1: Write the failing tests.**
  - Create `tests/test_tier5_board.gd`:

```gdscript
extends RefCounted
## v0.11 M6 Tier 5 complete on the board, and the board complete: the ★ missions and the three new, each new one at Tier 5's numbers (7:00,
## 6 / 16, God-Resistant, no unaware_town, no bonuses, no stretch) with its one Gaze objective; Ascendance counts its five; with all 25
## cleared the results read "every tier is cleared" and the header "All 25 cleared"; no timed wait over 60 s, no chain over 45 s, the first
## waits pinned; a board night's wishes reserved before each director gathers its people (review focus 5); Exodus never hears the escape
## wishes, the Heart never the pyre; five cards on Ascendance's tab.

const DT := 0.05
const Kit := preload("res://tests/test_tier2_groundwork.gd")
## The three new Tier 5 missions.
const NEW := ["lantern_eye", "exodus", "heart_of_faith"]


static func run(t) -> void:
	_board(t)
	_lines(t)
	_complete(t)
	_waits(t)
	_reserved(t)
	_wishes(t)
	_cards(t)


static func _gazes(m: MissionDef) -> int:
	var n := 0
	for o in m.objectives():
		n += 1 if o is GazeObjective else 0
	return n


static func _board(t) -> void:
	for id: String in NEW:
		var m := TierBook.board(id)
		t.check(m != null and m.id == id and m.tier == 5 and is_equal_approx(m.clock, 420.0) and m.slots == 6 and m.dp_capacity == 16
			and m.tier_floor == 4 and not m.mission_tags.has(TierBook.UNAWARE_TAG) and m.bonuses().is_empty()
			and m.response_profile(ResponseProfile.DEFAULT).tier_name() == "God-Resistant" and is_equal_approx(m.stretch, 1.0) and _gazes(m) == 1,
			"%s on the board: Tier 5, 7:00, 6 / 16, God-Resistant, no unaware_town, no bonuses, no stretch, one Gaze objective" % id)
	t.check(Array(TierBook.missions(5)) == ["last_judgement", "long_night"] + NEW and TierBook.need(5) == 3 and TierBook.all().size() == 25
		and _gazes(TierBook.board("last_judgement")) == 1, "Ascendance: the ★ missions first, then the three new; 25 board missions; Last Judgement keeps its one Gaze")
	t.check(TierBook.type_of("lantern_eye") == "Anchors" and TierBook.type_of("exodus") == "Protect" and TierBook.type_of("heart_of_faith") == "Kill"
		and Array(TierBook.board("exodus").mission_tags) == ["shuts_gates"] and Array(TierBook.board("heart_of_faith").mission_tags) == ["burns_temple"]
		and TierBook.board("lantern_eye").mission_tags.is_empty(), "each card's type; Exodus and the Heart keep their clashing wishes away")


## Three cleared of each tier below Ascendance (v0.11 M6 tests).
const BELOW := ["warning", "tax_collector", "lost_lamb", "miras_house", "broken_lanterns", "bell_ringers", "vigil_flame", "festival",
	"crowns_bread", "procession", "bishop", "armoury"]


static func _lines(t) -> void:
	var s := DescendState.new()
	s.cleared = PackedStringArray(BELOW + ["last_judgement", "lantern_eye"])
	s.refresh_open()
	t.check(s.open_tier == 5 and s.progress_line(5) == "Ascendance 2 / 5 cleared" and s.progress_line(4) == "Reckoning 3 / 3 cleared: Ascendance is open"
		and not s.all_cleared(), "the last tier counts its five; the tier below reads as before (%s)" % s.progress_line(5))


static func _complete(t) -> void:
	var s := DescendState.new()
	s.cleared = TierBook.all()
	s.refresh_open()
	s.night = 41
	s.believers = 990
	t.check(s.all_cleared() and s.progress_line(5) == "Ascendance 5 / 5 cleared: every tier is cleared"
		and s.progress_line(1) == "Whisper 3 / 3 cleared: Omen is open", "all 25 cleared: every tier is cleared (%s)" % s.progress_line(5))
	var save := SaveFile.new()
	save.descend = s
	var board := MissionBoard.new().setup(save, "last_judgement")
	t.check(board.header_text() == "Night 42   Believers 990   All 25 cleared", "the board's header says so (%s)" % board.header_text())
	board.free()
	var short := SaveFile.new()
	short.descend.night = 3
	var b2 := MissionBoard.new().setup(short, "warning")
	t.check(b2.header_text() == "Night 4   Believers 0", "until then the header is as before")
	b2.free()


static func _waits(t) -> void:
	var waits := {
		"the first mirror": LanternEyeDirector.STEP_AT[0],
		"a drain": LanternEyeDirector.DRAIN,
		"a re-hanging": LanternEyeDirector.REHANG,
		"the Eye's countdown": LanternEyeDirector.EYE_OPENS,
		"a guard's return": LanternEyeDirector.RETURN_AFTER,
		"a guard's relief": LanternEyeDirector.RELIEF_AFTER,
		"the first household": ExodusDirector.OUT_AT[0],
		"the searchers": ExodusDirector.HUNT_AFTER,
		"a watchman's return": ExodusDirector.RETURN_AFTER,
		"a watchman's relief": ExodusDirector.RELIEF_AFTER,
		"the first stage": HeartOfFaithDirector.STAGE_AT[0],
		"a Knight's relief": HeartOfFaithDirector.RELIEF_AFTER,
		"the rite": HeartOfFaithDirector.RITE,
	}
	var chains := {"the next mirror": LanternEyeDirector.CHAIN, "the next household": ExodusDirector.CHAIN,
		"the Temple": HeartOfFaithDirector.CHAIN, "Odran": HeartOfFaithDirector.ODRAN_CHAIN}
	var long := []
	for k: String in waits:
		if float(waits[k]) > 60.0:
			long.append(k)
	for k: String in chains:
		if float(chains[k]) > 45.0:
			long.append(k)
	t.check(long.is_empty(), "no timed wait in Ascendance's new missions runs over 60 s, and no chain over 45 s (over: %s)" % [long])
	t.check(HeartOfFaithDirector.ODRAN_CHAIN < 45.0, "Odran's chain is never a pure 45 s (M4's captain ruling)")
	# The first waits pinned at their tuned values. Set each to the value Tasks 5-7 landed if their gates tuned it.
	t.check(is_equal_approx(float(LanternEyeDirector.STEP_AT[0]), 50.0), "the first mirror at 0:50")
	t.check(is_equal_approx(float(ExodusDirector.OUT_AT[0]), 15.0), "the first household at 0:15")
	t.check(is_equal_approx(float(HeartOfFaithDirector.STAGE_AT[0]), 45.0), "the oil-house in use at 0:45")


## The people and the buildings `d` has claimed (v0.11 M6).
static func _actors(d: MissionDirector) -> Dictionary:
	var people: Array = []
	var places: Array = []
	if d is LanternEyeDirector:
		var e := d as LanternEyeDirector
		for st in e.steps:
			for g: HuntDirector.Guard in st.party:
				people.append(g.man)
		for crew: Array in e.wrights:
			for w: HuntDirector.Guard in crew:
				people.append(w.man)
		places.append_array(e.towers)
	elif d is ExodusDirector:
		var x := d as ExodusDirector
		for c in x.charges:
			people.append(c.man)
		people.append_array(x.watch)
		for squad: Array in x.patrols:
			people.append_array(squad)
		for h: ExodusDirector.Household in x.households:
			people.append_array(h.searchers)
			places.append(h.house)
	elif d is HeartOfFaithDirector:
		var h := d as HeartOfFaithDirector
		people.append(h.odran)
		places.append(h.oil_house)
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
	for id: String in ["exodus", "heart_of_faith", "lantern_eye"]:
		worlds[id] = Kit.world(TierBook.board(id))
	var heard := {"exodus": {}, "heart_of_faith": {}, "lantern_eye": {}}
	for night in 60:
		for id: String in worlds:
			var d := Descent.new().setup(TierBook.board(id), Descent.seed_for(night, id))
			d.hear((worlds[id] as Dictionary).crowd, (worlds[id] as Dictionary).town)
			for w in d.wishes:
				(heard[id] as Dictionary)[w.def.id] = true
			d.release()
	t.check(not (heard.exodus as Dictionary).has("brother") and not (heard.exodus as Dictionary).has("family_out")
		and not (heard.heart_of_faith as Dictionary).has("heretic") and (heard.lantern_eye as Dictionary).has("brother"),
		"sixty draws: Exodus never hears the escape wishes, the Heart never the pyre; The Lantern's Eye hears them (%s / %s / %s)" % [
		(heard.exodus as Dictionary).keys(), (heard.heart_of_faith as Dictionary).keys(), (heard.lantern_eye as Dictionary).keys()])
	for id: String in worlds:
		Kit.done(worlds[id])


static func _cards(t) -> void:
	var save := SaveFile.new()
	save.descend.open_tier = 5
	var board := MissionBoard.new().setup(save, "lantern_eye")
	var room := MissionBoard.card_rect(0, 5).size.x - MissionBoard.PAD * 2.0
	var long := {}
	for id in board.missions():
		if board.brief_lines(id, room).size() > MissionBoard.BRIEF_LINES:
			long[id] = board.brief_lines(id, room).size()
	t.check(board.tier == 5 and board.missions().size() == 5 and long.is_empty(),
		"Ascendance's tab: five cards, each brief wrapped to %d lines or fewer (over: %s)" % [MissionBoard.BRIEF_LINES, long])
	board.free()
```

  - `tests/test_tiers.gd` `_table()`: `Array(TierBook.missions(5)) == ["last_judgement", "long_night"]` becomes
    `Array(TierBook.missions(5)) == ["last_judgement", "long_night", "lantern_eye", "exodus", "heart_of_faith"]` (message:
    `"every tier complete (v0.11 M2-M6); the ★ missions first on theirs (spec §8)"`); `TierBook.all().size() == 22` becomes `== 25`; the
    needs `[3, 3, 3, 3, 2]` become `[3, 3, 3, 3, 3]` (message `"every tier needs three of its five (v0.11 M2-M6); Ascendance opens nothing (%s)"`).
  - `tests/test_tiers.gd` `_unlock()`: `far.progress_line(5) == "Ascendance 0 / 2 cleared"` becomes `== "Ascendance 0 / 5 cleared"`.
  - In `tests/run_all.gd`, append `"res://tests/test_tier5_board.gd",` at the end of `SUITES`.

- [ ] **Step 2: Run the tests to verify they fail.** Run Import, then the halves. Expected: FAILs in `test_tier5_board` (the three are
  not on the board: `TierBook.board()` returns null) and `test_tiers`.

- [ ] **Step 3: Ascendance on the board.** In `src/game/descend/tier_book.gd`:
  - `MISSIONS`' fifth entry `["last_judgement", "long_night"]` becomes `["last_judgement", "long_night", "lantern_eye", "exodus", "heart_of_faith"]`.
  - `TYPES` gains `"lantern_eye": "Anchors", "exodus": "Protect", "heart_of_faith": "Kill"`.
  - `MISSION_TAGS` gains `"exodus": ["shuts_gates"], "heart_of_faith": ["burns_temple"]`.
  - `NEED`'s doc gains: `Ascendance has five from v0.11 M6; it is the last tier and opens nothing.`

- [ ] **Step 4: The board complete.**
  - In `src/game/descend/descend_state.gd`, replace `progress_line()` with:

```gdscript
## The results' tier line (spec §6): "Omen 1 / 2 cleared: one more opens Wrath", "...: Wrath is open". v0.11 M6 (Decision 251): the last
## tier counts all its missions, "Ascendance 2 / 5 cleared", and with every board mission cleared "...: every tier is cleared".
func progress_line(tier: int) -> String:
	var n := cleared_in(tier)
	if tier >= TierBook.NAMES.size():
		var head := "%s %d / %d cleared" % [TierBook.tier_name(tier), n, TierBook.missions(tier).size()]
		return head + (": every tier is cleared" if all_cleared() else "")
	var need := TierBook.need(tier)
	var head := "%s %d / %d cleared" % [TierBook.tier_name(tier), mini(n, need), need]
	var next := TierBook.tier_name(tier + 1)
	if is_open(tier + 1):
		return "%s: %s is open" % [head, next]
	var left := need - n
	return "%s: %s" % [head, ("one more opens " + next) if left == 1 else ("%d more open %s" % [left, next])]


## Every board mission is cleared (v0.11 M6, mission spec §4, Decision 252): the board complete.
func all_cleared() -> bool:
	for id in TierBook.all():
		if not cleared.has(id):
			return false
	return true
```

  - In `src/game/ui/mission_board.gd`, `header_text()` becomes:

```gdscript
## The header's line (spec §3.1): the night about to be played, and the believers. v0.11 M6 (Decision 252): "All 25 cleared" once every
## board mission is.
func header_text() -> String:
	var line := "Night %d   Believers %d" % [_state().night + 1, _state().believers]
	return line + ("   All %d cleared" % TierBook.all().size() if _state().all_cleared() else "")
```

- [ ] **Step 5: Run the tests to verify they pass.** Run Tests (halves). Expected: `failures=0`, the count up by about 18.
  `test_board_missions` now covers twenty-five board missions; if one of its checks refuses a new mission (a brief over its lines, a default
  loadout over the tier's DP), fix the mission's words, not the check, and say so.

- [ ] **Step 6: FLOW** (plan decision 300). In `src/game/game.gd`:
  - `_flow_board()`: its doc gains `v0.11 M6: Ascendance's tab shows its five cards behind three of Reckoning.`; after M5's `reckoning_ok`
    lines and before the `step.call(...)`, add:

```gdscript
	board.open_tab(5)
	var ascendance_ok := Array(board.missions()) == Array(TierBook.missions(5)) and board.missions().size() == 5 \
		and board.lock_line() == "Clear 3 Reckoning missions"
```

    and that `step.call()`'s condition gains `and ascendance_ok`, its message `; Ascendance's five behind three of Reckoning`.
  - After M5's `_flow_tier4()` add:

```gdscript
## v0.11 M6: a Tier 5 mission from the board -- The Lantern's Eye, Ascendance opened as a fixture (Reckoning's three clears need not be
## played). Its Prepare has Tier 5's DP plus the one bought; its night is the board's version, three mirror towers; each mirror given up by
## its public state (LanternEyeDirector._raise(), then _gone()), F ascends to the results: won, The Lantern's Eye cleared, Ascendance 1 / 5.
## Ends on the board.
func _flow_tier5(step: Callable) -> void:
	save.descend.open_tier = maxi(save.descend.open_tier, 5)
	(_screen_node as MissionBoard).choose(MissionBook.LANTERN_EYE)
	var prep := _screen_node as PrepareScreen
	var dp := prep.draft.capacity if prep != null else 0
	prep.draft.preselect(MissionBook.lantern_eye().default_loadout)
	_on_prepare_action("manifest", prep)
	await _until(func() -> bool: return _mission_up(null), 10.0)
	await _past_intro()
	var d := _mission.rules().director as LanternEyeDirector
	var up := d != null and d.towers.size() == 3 and dp == TierBook.dp(5) + 1 and _mission.rules().mission.tier == 5
	if d != null:
		for i in d.steps.size():
			d._raise(i)
			d._gone(i)
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
		and save.descend.cleared.has(MissionBook.LANTERN_EYE) and String(bank.get("progress", "")) == "Ascendance 1 / 5 cleared",
		"The Lantern's Eye from the board: Tier 5's budget, three towers; its mirrors gone and ascended, the results read Ascendance 1 / 5 (%s)" % String(
		bank.get("progress", "")))
	if shown and _screen_node is ResultsScreen:
		(_screen_node as ResultsScreen).action.emit("missions")
		await _until(func() -> bool: return screen == Screen.BOARD, 5.0)
```

  - In `_flow_test()`, after `await _flow_tier4(step)`, add `await _flow_tier5(step)`.
  - The `tiers` photo's save (in `_ready()`'s `match show:`): M5's cleared list gains `"last_judgement", "lantern_eye", "exodus"` at its end;
    its comment reads `# The tier board near its top (v0.11 M1-M6): three of every tier cleared, for the photograph (SHOW_SAVE).` and its
    second comment line `... --mission=vigil_flame opens Wrath's instead, --mission=procession Reckoning's, --mission=last_judgement Ascendance's.`

- [ ] **Step 7: Run FLOW, alone.** Check `tasklist | grep -i godot` first. Expected: `FLOW result checks=114 failures=0`. Paste any
  `FLOW FAIL` line.

- [ ] **Step 8: The scenario gates, and the board's versions.**
  - Run the Scenario loop for `eye`, `exodus` and `heart` (18 runs). Expected: every checksum and result line as recorded in Tasks 5-7.
    Write each gate's verdict in the commit body:
    - `none` loses: eye `eye_open`, exodus `exodus_few`, heart `blessed`;
    - `play` wins at least 2 of 3, its median won time 180-240 s, its `idle` 45 s or less.
  - Run each once more with `--case=play --seed=1 --board`. Expected per run: a `BEHAVIOUR board tier=5 wishes=...` line with three
    wishes, never `brother` or `family_out` for Exodus nor `heretic` for the Heart; a result line; no `SCRIPT ERROR`. Paste the three pairs
    of lines.
  - Then the Scenario loop for M3's eighteen, M4's eighteen and M5's twenty-four, compared with their tables.

- [ ] **Step 9: The Reference check,** and the board Warning's `--mission=warning --board --mission-test` (as at the baseline). Expected:
  unchanged.

- [ ] **Step 10: Commit.**

```bash
git add src/game/descend/tier_book.gd src/game/descend/descend_state.gd src/game/ui/mission_board.gd src/game/game.gd tests/test_tier5_board.gd tests/test_tier5_board.gd.uid tests/test_tiers.gd tests/run_all.gd
git commit -m "feat: Tier 5 complete on the board -- Ascendance's five, the board complete at 25, The Lantern's Eye in FLOW (v0.11 M6)" -m "<the 18 gate lines' verdicts and the three --board runs; M3/M4/M5 tables exact; FLOW 114/0 alone>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10: The photos, the notes and v0.11's close

**Files:**
- Modify: `src/game/game.gd` (`TIER5_SHOWS`, `--show=lantern_eye|exodus|heart_of_faith|lantern_eye-hunt|heart_of_faith-odran|tiers-all`,
  the capture conditions)
- Modify (only if a photo shows a problem): a director's tag label or `CAMERA_AT` and its test file; `MissionBoard`'s card constants
- Modify: `docs/KAK_Version_0.11_Summary.md` (a new `## M6: Ascendance` section and a v0.11 close above it), `README.md`

**Interfaces:**
- Consumes: everything above.
- Produces: the photographs and the notes. No new behaviour.

- [ ] **Step 1: The photographs' cases.** In `src/game/game.gd`:
  - After M5's `const TIER4_SHOWS := ...` add:

```gdscript
## The new Tier 5 missions' photographs (v0.11 M6): each its board night as the tour lands, its tags and HUD in view; lantern_eye-hunt has
## its first mirror up at once and a beam drawn to a cast; heart_of_faith-odran has the flame out and the litter on its road.
const TIER5_SHOWS := ["lantern_eye", "exodus", "heart_of_faith", "lantern_eye-hunt", "heart_of_faith-odran"]
```

  - In `_ready()`'s `match show:`, the arm listing the Tier 1-4 missions gains `"lantern_eye", "exodus", "heart_of_faith"`, and its comment
    reads `# A new Tier 1-5 mission's board night (v0.11 M2-M6), for the photograph of its tags, its how-to-win line and its wishes.` After
    M4's `"heretic_hunt-sweep"` arm add:

```gdscript
		"lantern_eye-hunt", "heart_of_faith-odran":
			# The Lantern's Eye with its first mirror up and a beam drawn, The Heart of Faith with its litter walking (v0.11 M6).
			mission_id = show.get_slice("-", 0)
			loadout = MissionBook.get_mission(mission_id).default_loadout
			go_to(Screen.MISSION)
		"tiers-all":
			# The board complete (v0.11 M6): every board mission cleared, the header's "All 25 cleared", for the photograph (SHOW_SAVE).
			save.descend = DescendState.new()
			save.descend.cleared = TierBook.all()
			save.descend.believers = 990
			save.descend.night = 41
			save.descend.refresh_open()
			mission_id = MissionBook.LAST_JUDGEMENT
			go_to(Screen.BOARD)
```

  - In the `if "--capture" in args:` branch, both conditions that read `... or show in TIER4_SHOWS` read
    `... or show in TIER4_SHOWS or show in TIER5_SHOWS`, and after M4's `heretic_hunt-sweep` line add:

```gdscript
			if show == "lantern_eye-hunt" and _mission.rules().director is LanternEyeDirector:
				var eye := _mission.rules().director as LanternEyeDirector
				eye._raise(0)
				eye._on_cast(0, "smite", eye.outer_face(0))
			if show == "heart_of_faith-odran" and _mission.rules().director is HeartOfFaithDirector:
				var heart := _mission.rules().director as HeartOfFaithDirector
				heart._open(0)
				heart._raze(heart.targets[0])
				heart._open(1)
				heart._raze(heart.targets[1])
				heart._odran_comes()
```

- [ ] **Step 2: Take the photos.** `--show=lantern_eye`, `--show=exodus`, `--show=heart_of_faith`, `--show=lantern_eye-hunt`,
  `--show=heart_of_faith-odran`, `--show=tiers --mission=last_judgement`, `--show=tiers-all`, and the keepout's proof
  `--show=crowns_bread`, `--show=informer`, `--show=spoiled_harvest`. Read each `captures/screen_<name>.png`.

- [ ] **Step 3: Judge them against the mission spec.** For each photo, answer in the report; in every mission photo, also: no tag label
  or arrow under the left HUD stack (the keepout), and an edge arrow for each off-screen target named below.
  - **lantern_eye:** NEXT MIRROR 0:50 on the north tower at the upper right; the east tower's arrow from the bottom-right edge and the
    south-west tower's from the left edge below the stack; GUARD on the parties; the beams drawn; "Blind the Eye: mirrors 0 / 3", the Gaze
    row; the strip's first mirror.
  - **lantern_eye-hunt:** MIRROR - GUARDED on the north tower; a beam pulled onto its outer face; **the beams' glare over the tags**: if the
    drawn light washes a tag out, say so with the photo -- the spec's fix is the tag's plate, never the light, and `Hud._plate()` is outside
    this task's Files, so the controller rules on it.
  - **exodus:** HOUSEHOLD - OUT BY 0:15 over the west door left of the centre below the stack; POSTERN - WATCHED; the Main Gate at the
    bottom; the east household's, the Side Gate's and the Temple's arrows from the right edge; PATROL; "Lead them out 0 / 10, 2 to spare",
    the Gaze row; the strip's shuttings.
  - **heart_of_faith:** OIL-HOUSE - IN USE BY 0:45 up and right of the centre; the Temple at the right with its next-stage tag; ODRAN - IN
    THE CITADEL above the centre, clear of the stack; KNIGHT on each; "Put out the flame 0 / 2: blessed in 5:00", the Gaze row.
  - **heart_of_faith-odran:** ODRAN - IN HIS LITTER, gold, with BEARER on four Knights round it; ALTAR at the steps, pointed at; the hint's
    "litter" line with the Gaze's sentence while room allows.
  - **tiers (Ascendance):** five cards, each with its name, type and brief inside it; Last Judgement, The Lantern's Eye and Exodus ticked.
  - **tiers-all:** every tab ticked; the header reads "Night 42   Believers 990   All 25 cleared".
  - **crowns_bread / informer / spoiled_harvest:** against their M4 / M3 / M2 photographs: their old trouble spots (an arrow or label
    under the stack's corner) now sit on the stack's border, labels beside them; nothing else moved.

- [ ] **Step 4: Fix only what a photo shows.**
  - Change only what **Files** lists. A `CAMERA_AT` move moves that scenario's six references (Decision 247's cost): re-run its Scenario
    loop, check the gate still holds, and record the new values and the reason in the commit body.
  - After any change, run Tests (halves), FLOW (alone) and the photo again. Report each change with its old and new value and the photo
    that asked for it. If nothing needs changing, say so.

- [ ] **Step 5: The notes.** In `docs/KAK_Version_0.11_Summary.md`:
  - The header's italic line gains: `M5 (Reckoning) ... M6 (Ascendance): Tier 5's three new missions and v0.11's close; mission spec docs/superpowers/specs/2026-10-15-kak-v011-m6-ascendance-missions.md, plan docs/superpowers/plans/2026-10-15-kak-v011-m6-ascendance.md.`
  - At the top, under the header, add a section `## v0.11: The Tiers, complete`, short, in the file's voice. It says:
    - **The board:** all 25 missions by tier with their card types, one table (Whisper, Omen, Wrath, Reckoning, Ascendance; five rows each
      from `TierBook.MISSIONS` and `TierBook.TYPES`), each tier's numbers (clock, town, slots and DP, wishes, multiplier) from
      `TierBook`'s tables, three cleared opening the next, and the board complete at 25 ("All 25 cleared").
    - **The wish pool of eighteen:** one line each (text, kind, reward, the tier it is heard from, its clashes), from `WishBook.pool()`.
    - **The shared types and hooks the milestones built:** Raze, Assassinate, Escort (the Charge record), Convert, Steal, Hunt, StagesObjective;
      the chain and `EventTimeline.expect()`; `MissionDirector._hold_all()`; the keepout; the Searchlight's hunt and hold; each in a line,
      with the milestone that made it.
    - **The final gates:** `Gates: filled in at landing.`
  - Below it, before `## M5: Reckoning`, add a section `## M6: Ascendance`, in M5's voice. It says:
    - **Ascendance's five:** a table of name, card type, main objective and twist, one row each for Last Judgement, The Long Night and the
      three new; Ascendance opens nothing; its line counts its five.
    - **The groundwork, one paragraph each:** the Charge record (gated on The Lost Lamb's and The Prisoner's twelve; M4 Decision 67
      reworded), the Hunt's unguarded blow, the keepout (no camera or reference moved), the Tier 5 frame (StagesObjective, `_spoil_for()`,
      the hunting Searchlight, one Gaze objective, each mission's own Gaze at 10 a seen death).
    - **Each mission's timeline** in a line, with its longest wait.
    - **The wishes:** the two new rows; heard from Ascendance only; Tier 1-4 draws unchanged; `shuts_gates` keeps the escape wishes off
      Exodus.
    - **References:** the 18 new scenario checksums with each `play` median, `idle` and Gaze, from Tasks 5-7's commit bodies (and any Task 10
      re-recording). State that every M1-M5 reference is unchanged.
    - **Rulings made in M6:** the mission spec's Decisions 207-262 and this plan's 263-304, numbered on from M5's last in this file, one
      line each, with the controller's rulings where they changed a decision.
    - **The photographs:** one line each for the ten taken in Step 2, the keepout's three against their old photographs.
    - The last line: `Gates: filled in at landing.`
  - In `README.md`:
    - In the KAK section, after the sentence on Reckoning, add: `Ascendance, the fifth and last tier, is complete: Last Judgement, The Long Night, The Lantern's Eye, Exodus and The Heart of Faith; with all 25 cleared the board says so.`
      and change `v0.11 (in progress, ...)` to `v0.11 (\`docs/KAK_Version_0.11_Summary.md\`)`.
    - The `--show` list (the line naming `heretic_hunt|heretic_hunt-sweep` and M5's names) gains
      `|lantern_eye|exodus|heart_of_faith|lantern_eye-hunt|heart_of_faith-odran|tiers-all`, and its tail `; add --mission=warning for The Warning`
      becomes `; add --mission=<id> to tiers for that tier's tab`.

- [ ] **Step 6: Run Tests and FLOW.** Expected: `failures=0` in both halves, and `FLOW result checks=114 failures=0` (alone).

- [ ] **Step 7: Commit.**

```bash
git add src/game/game.gd docs/KAK_Version_0.11_Summary.md README.md
git commit -m "docs: v0.11 M6 photos and notes -- Ascendance complete, v0.11 closed (v0.11 M6)" -m "<the ten photos judged; any change and its re-recorded references>" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

  - If Step 4 changed a constant or a label, add its file and its test file to the `git add`.

- [ ] **Step 8: The benches (the controller's, at landing, on a quiet machine; the implementer only checks that the commands run).**
  - The Lantern's Eye's board version against Last Judgement's, medians of three:
    `$G --path . --audio-driver Dummy --disable-vsync --max-fps 0 --scene res://scenes/mission.tscn -- --mission=lantern_eye --board --bench`
    and the same with `--mission=last_judgement` (the Searchlight lit and drawn all night, both beams).
  - v0.11's release bench: the board versions of `warning`, `miras_house`, `vigil_flame`, `procession` and `last_judgement`, medians of
    three, on this tree, on `kak-v011-m5` and on v0.10's release tag (`kak-v0.10`), each in its own temporary worktree, never this one.
  - The numbers go into the notes' two `Gates:` lines at landing.

---

## Self-review notes (for the controller)

- **Spec coverage:** §0 (frame, Gaze, held people, unseen spacing, no bell loss, keepout, colours) -- Global Constraints, Tasks 3-7; §1 --
  Task 5; §2 -- Task 6; §3 -- Task 7; §4 -- Task 9; §5 -- Task 8; §6.1 -- Task 1; §6.2 -- Task 2 (the tower choice in Task 5); §6.3 and
  §6.5 -- Task 4; §6.4 -- Task 3; §7 (tests, kit, references, FLOW, photos, bench, notes, spec sync) -- every task's last steps and Task 10.
- **Placeholders by design:** `<M5_SHA>`, `<M5_TESTS>`, `<M5_REFS>` and `<FLAME_PLAY>` are the controller's, filled at M5's landing, in the
  Global Constraints only. Every gate-tuned number is a first guess tuned by its task's gate step, in the spec's order.
