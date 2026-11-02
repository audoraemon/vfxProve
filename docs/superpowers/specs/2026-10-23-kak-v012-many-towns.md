# KAK v0.12 "Many Towns": missions that read their town, and Tier 1 played in the Capital

Date: 2026-10-23. Status: for the user's approval. Plan: `docs/superpowers/plans/2026-10-23-kak-v012-many-towns.md`.

Builds on feat/Develop-Main `1c28dc0` (tag `kak-v0.11.2` + F1 hide-UI), worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-v012`, branch
`feat/v012`. The design brief approved in chat is `.superpowers/sdd/v012/design-brief.md`; this spec is that brief made exact and checked
against the code (both branches). Decisions are numbered from 1 (D1...); a `Ruling:` marks a choice the brief left to the plan, or a place
where the code said otherwise. Every ruling is also in `.superpowers/sdd/v012/rulings.md` as R1... (decision -- why -- cost if wrong).

The user asked whether the missions can be played in a new town such as the Capital. Today they cannot: 19 mission and descend scripts read
Aldermere's `TownLayout` directly, and some fifty director spots are Aldermere coordinates. This release answers in two milestones:

| Milestone | What it delivers | Tag |
|---|---|---|
| **M1** Merge and groundwork | `feat/capital-city` merged; missions read their places from the active town; each mission lists the places it needs; a town may override a mission's spots and numbers; any mission can be run in a chosen town (`--city=`, the DEV tab); Aldermere exactly as before | `kak-v012-m1` |
| **M2** Tier 1 in the Capital | The Warning (Starfall), The Tax Collector, Spoiled Harvest, The Lost Lamb and First Prayers each hostable in the Capital, with its own spots and gates; on the board's DEV tab only (`--dev`) | `kak-v012-m2` |

## 0. Binding rules and what this release shares

### 0.1 The mission design rules (memory `kak-mission-design-lessons`; binding on every M2 task)

- **No waiting.** Every timed wait is 60 s or less; doing nothing loses; an acting player idles 45 s at most; stages, not seals.
- **Chain pacing.** The next thing to do comes as the last one ends (or within 45 s of it), never on a far-off fixed time alone. A
  longer walk in a bigger town must not open a gap: the chain's numbers, not the player, absorb it.
- **Spread opposition.** A mission's own guards, watchmen, escorts and patrols stand more than two Silent Doom radii apart
  (`SilentDoom.RADIUS` 0.8: more than 1.6 units), so one quiet cast never clears a whole guard.
- **No luck.** No outcome depends on street traffic. The Capital's old town is busier than Aldermere's streets: a stage where an unseen
  kill depends on who happens to pass is moved to a quieter block before any number is touched.
- **No hidden losses.** Every instant loss is warned plainly with room to act; a death that loses is tagged DO NOT KILL; the winning strike
  never also loses. **The bell never loses outright**: the toll turns the Lantern (unchanged from v0.11.2).
- **Clarity.** Every moving target is edge-arrowed; tags count down like the strip; camera spots and plates keep clear of the HUD stack
  (`Kit.STACK` grown by `Hud.STACK_PAD`), the strip and the slots.

### 0.2 Aldermere stays exact

"Aldermere exact" means, at every task's commit and at both landings:

- `digest` `61267b7e90524d800bf1c3473a71146b` (state_digest) unchanged;
- every row of `tools/dev/refs/*.tsv` that exists at `1c28dc0` unchanged (233 rows: `references.tsv` 125, `routes_t1..t5` 75,
  `lantern_*` 33; `crowd_check` is `-935602679` since v0.11.2);
- FLOW `failures=0` (127 checks at `1c28dc0`; the count grows only by the steps this spec adds, §1.7, §2.7);
- the five-board bench within ~1 fps of `kak-v0.11.2` (memory `kak-m1-perf-debt`: noisy pairs, rerun on a quiet machine).

**Ruling (D1, R3):** the brief's `crowd_check` "-346732806" is the v0.11 value; v0.11.2's awareness change moved it to `-935602679`. The
TSV is the reference, never a remembered number.

### 0.3 What may move

| What | M1 | M2 |
|---|---|---|
| Aldermere's digest, references, mission numbers, spots, copy | **nothing** | **nothing** |
| The Capital sandbox references `capital_calm`, `capital_evac` | recorded once at the capital tip and once on the merged tree; re-recorded only with a reason (a v0.11.x shared change that legitimately touches them, e.g. the startle) | only with a reason, in the commit body |
| The Capital's own layout (`CapitalCity`) | nothing | nothing; a mission needing a place adds a **name** for an existing rect or point (§1.2), never moves a building |
| New rows `capital_<scenario>_...` | none | added per mission, one TSV each |

### 0.4 Keys, art, sound

No new key in a mission. The DEV tab keeps the capital branch's `D` (board only, `--dev` only). Text and drawn shapes only; no PixelLab;
no new sounds.

## 1. M1: merge and groundwork

### 1.1 The merge of `feat/capital-city`

Facts (checked): the capital branch's tip is `f7d74922` (2026-10-09), merge-base `3ff44f10` (before v0.11); it is 42 commits ahead, this
branch 178. `git merge-tree` reports exactly five textual conflicts:

| File | Resolution rule |
|---|---|
| `src/fx/dominion/divine_congregation.gd` | develop's file plus the capital's `&"monk": 0.35` in `RESISTANCE` |
| `src/game/mission.gd` | develop's file (F1 hide-UI, the Lantern, `--bench-toll`) plus every capital hunk: `PAN_MAP_WIDTH`, `city` var, `City.use(_def.city)` before `Town.new()`, `_bf.ctx.field.bounds = City.current().map()`, the city's own head count (`CityDef.citizens()` + `soldiers()`), `_bench_view()`, `clamp_view()` / `pan_limits()`, `_town.bridges`, `City.current().landmark(&"main_gate")` in the two banners, `Vector2.INF` in `TEST_CASTS` |
| `src/game/mission/mission_book.gd` | develop's file (pools removed in v0.11.2: no `VIGIL_POOL` / `RUIN_POOL`) plus the capital's `CAPITAL_SANDBOX`, `CAPITAL_INTRO_FROM`, `dev_missions()`, `is_dev()`, `capital_sandbox()` and the `dev_missions()` loop in `get_mission()` |
| `src/game/ui/mission_board.gd` | develop's board plus the capital's DEV tab (`DEV_TIER` 6, `DEV_RECT`, `dev`, `_missions_of()`, `_tier_of()`, `_is_open()`, `_draw_dev_tab()`, key `D`) |
| `tools/dev/behaviour_check.gd` | develop's file plus `capital_calm`, `capital_evac`, `CAPITAL_EVAC_SECONDS`, `CAPITAL_CUT_AT`, `_fps()`, and `_places()` reading `City.current().anchors()` |

Semantic work the textual merge does not show:

- **TownLayout in shared code added since `3ff44f10`:** one read only -- `src/game/descend/pressed_wish.gd` (`TownLayout.BARRACKS`, the
  barracks' door) -- and one comment (`ruin_wish.gd`). The capital's grep guard (`tests/test_city.gd::_no_hardcoded`, which already scans
  `src/fx`, `src/game/crowd`, `src/game/descend`, `src/game/town`, `src/environment`, `targeting.gd`, `mission.gd`) catches it; it becomes
  `City.current().landmark(&"barracks")` (Aldermere: the same rect). **Ruling (D2, R4):** the brief expected many; v0.11 and v0.11.2 put
  their place reads in `src/game/mission`, not in shared code.
- **A hard-coded Aldermere point the guard cannot see:** `RescueWish.GATE` (`Vector2(-10.5, -7.6)`, the Citadel's gate) and its copies
  `HarvestDirector.CITADEL_GATE` and `TaxCollectorDirector.CITADEL_GATE` (= `RescueWish.GATE`). They become the place `citadel_gate`
  (§1.2) in M1 (D3).
- **The Capital's monks.** The capital adds `CitizenProfile.Role.MONK` and `CitizenProfile.is_clergy()`. Code added since `3ff44f10`
  tests "is this person clergy" with `== Role.CLERGY` in `first_prayers_director.gd` (l. 145), `lantern_bearer.gd` (l. 235, 248),
  `neighbours_wish.gd`, `punish_wish.gd` and `banishing_rite.gd` (x2); the capital's own edits to `mission_director.gd`,
  `warning_director.gd`, `wish.gd` and `festival_director.gd` auto-merge. **Ruling (D4, R7):** those tests use
  `CitizenProfile.is_clergy()`; role tables (`routine_manager.gd`, `person.gd`'s look) and the exact role picks
  `_citizen_near(at, Role.CLERGY)` (Lamb, Bishop, Heart of Faith, Sermon) stay. Aldermere has no monks, so nothing moves.
- **Capital crowd rules that reach Aldermere** (the capital summary: no step from dry ground into the river; stranded people wade ashore
  from a fallen span; long steps land on their waypoint). The capital proved Aldermere's v0.10 rows unchanged; v0.11 added rows the capital
  never ran (The Crown's Bread brings a bridge down). **Ruling (D5, R8):** an Aldermere row that moves at the merge is a bug: the change that
  moves it is put behind a `CityDef` switch that is off for Aldermere (as `offscreen_every()` already is), never re-recorded.
- **The capital's references.** The brief and memory give `capital_calm -370675099`, `capital_evac -870513036`; the capital summary gives
  `-713901328` and `731230687` (60 fps). **Ruling (D6, R2):** neither is trusted. The merge task first records both at `f7d74922` (a
  throwaway detached worktree of its own), then on the merged tree; they go into `references.tsv` as seq rows
  (`capital_calm	--scenario=capital_calm --seconds=60`, `capital_evac	--scenario=capital_evac`). A difference is kept only with its
  cause named (e.g. v0.11.2's startle on a frightened person) in the commit body.
- **What the merge brings that this spec relies on:** `CityDef`, `City.use()/current()/by_id()`, `AldermereCity` (every method hands back
  `TownLayout`'s own data), `CapitalCity` (80x80 river port; `citizens()` 422-427 and `soldiers()` ~180 by its own tables),
  `MissionDef.city` (default `&"aldermere"`), the capital sandbox (`--mission=capital_sandbox`), `Game.dev` / `--dev`, the board's DEV
  tab, `Game.board_locked_for()`, `tests/test_city.gd` and the twelve capital test suites.

**Ruling (D7, R1; corrects the brief):** the Capital **has** a Citadel. `CapitalCity.citadel_origin()` returns `CITADEL_ORIGIN`
`(0, -25.5)` on the Royal Keep's hill, and `Town` builds a `Citadel` node there in every city (`town.gd`: `citadel.setup(env,
city.citadel_origin(), shake)`). The need `citadel` is therefore met in the Capital. The Citadel/Keep missions (Last Judgement, The Long
Night's Act III, The Armoury, ...) stay out of scope by decision (§4), not by geometry; The Tax Collector and Spoiled Harvest, whose goods go
to the Citadel's gate, can be ported.

### 1.2 The mission-facing place API

**On `CityDef`** (new methods; `AldermereCity` answers from `TownLayout` exactly, `CapitalCity` from its own constants):

| Method | Meaning | Aldermere | Capital |
|---|---|---|---|
| `landmark(name) -> Rect2` (exists) | a named rect; `Rect2()` unknown | `LANDMARKS` + **new** `fountain` (`TownLayout.FOUNTAIN`), `side_gate` (`SIDE_GATE`) | `_landmarks` + **new** `fountain` (`FOUNTAINS[0]`, the Great Market's), `side_gate` (the harbour gate, `inner[4]`) |
| `place(name) -> Vector2` **new** | a named point; `Vector2.INF` unknown | `citadel_gate` `Vector2(-10.5, -7.6)` (the literal), `postern` `POSTERN_AT`, `citadel` `CITADEL_ORIGIN` | `citadel_gate` `CITADEL_ORIGIN + Vector2(0, 2.9)` = `(0, -22.6)`, `citadel` `CITADEL_ORIGIN` |
| `gate_towers() -> Array[Rect2]` **new** | the main gate's towers | `TownLayout.GATE_TOWERS` | `[]` (none modelled; a mission needing them is not hostable) |
| `barns() -> Array[Rect2]` **new** | farm buildings | `TownLayout.BARNS` | `CapitalCity.BARNS` |
| `districts()`, `taverns()`, `wells()`, `fountains()`, `map()`, `citadel_origin()` | exist | unchanged | unchanged |
| `mission_overrides(mission_id) -> Dictionary` **new** | §1.5 | `{}` | loaded from `capital_missions/` |

**Ruling (D8, R9):** names live on `CityDef` (as the capital already does with `landmark()`), and missions reach them through one thin
static helper, **`Places`** (`src/game/mission/places.gd`), so a misspelt name fails loudly instead of answering `Rect2()` (whose centre is
the map's middle):

- `Places.rect(name: StringName) -> Rect2` -- `City.current().landmark(name)`; `push_error` and `Rect2()` when it has no area.
- `Places.point(name: StringName) -> Vector2` -- `City.current().place(name)`; `push_error` and `Vector2.INF` when unknown.
- `Places.at(name: StringName) -> Vector2` -- a landmark's centre, else a place's point.
- `Places.has(city: CityDef, need: StringName) -> bool` -- `&"citadel"`: `citadel_origin() != Vector2.INF`; the list needs `&"gate_towers"`,
  `&"barns"`, `&"taverns"`, `&"wells"`, `&"fountains"`, `&"districts"`: the list is not empty (and long enough where §1.4's table says
  `taverns:2` etc.); any other name: a landmark with area or a known place.
- `Places.can_host(id: String, city: CityDef) -> bool` -- every `MissionNeeds.of(id)` need met (§1.4).

**Exactness rule (D9):** a TownLayout read is replaced by the same expression on the city's value (`TownLayout.TEMPLE.get_center()` ->
`Places.rect(&"temple").get_center()`), never by a re-derived value. An Aldermere literal spot that happens to equal a computed one (e.g.
`LostLambDirector.TEMPLE_DOOR` `(0.8, -5.0)` and the Temple's door `TEMPLE.end.y + 0.6`) **stays a literal**: float sums can differ in the
last bit, and a checksum would move.

### 1.3 Missions off TownLayout

Facts (checked): 22 files under `src/game/mission` and `src/game/descend` mention `TownLayout.`; **19 read it in code** (the rest are
comments the guard ignores): `armoury_director` (TAVERNS[0..1], GATE_TOWERS[0..1], BARRACKS), `bell_ringers_director` (BELL_TOWER, MAP),
`broken_lanterns_director` (TEMPLE), `crowns_bread_director` (BARNS[3], GATE_TOWERS[0..1]), `festival_director` (MARKET_SQUARE x6,
FOUNTAIN x5), `heretic_hunt_director` (DISTRICTS x2), `lantern_eye_director` (MAP), `lantern_watch` (TEMPLE), `miras_house_director`
(TEMPLE), `mission_def` (CITADEL_ORIGIN, the default camera), `mission_director` (TEMPLE, the Temple's door), `procession_director`
(CITADEL_COURT, TEMPLE, MARKET_SQUARE, DOCK_WAIT, DOCK, CITADEL_ORIGIN x2), `relic_run_director` (TEMPLE x2), `sermon_director` (WELLS[2]),
`tax_collector_director` (WORKSHOP), `vigil_flame_director` (TEMPLE x2), `mission_book` (WORKSHOP, MAIN_GATE x4, BELL_TOWER x2,
MARKET_SQUARE x2, CITADEL_ORIGIN x3, DOCK), `mercy_wish` (resolved by the merge), `pressed_wish` (BARRACKS).

- Every one reads `Places` / `City.current()` instead (same expression, D9).
- **`MissionDef.camera_at`'s default** becomes `Vector2.INF`, read as "the city's `citadel_origin()`" where the intro uses it (`Mission`,
  the tour). **Ruling (D10, R25):** a var initialiser cannot ask the active city safely (defs are built before `City.use()`); `INF` resolved
  at start gives Aldermere `TownLayout.CITADEL_ORIGIN` exactly.
- **The guard** (`tests/test_city.gd::_no_hardcoded`) adds `res://src/game/mission` and `res://tools/dev/routes` to its folders (no
  exceptions), and a function-scoped scan of `tools/dev/behaviour_check.gd`: the Tier 1 policies (`_tax*`, `_harvest*`, `_lamb*`,
  `_faith_*`, `_prayers*`, `_warning*`, `_watch_bearer_act`, `_toll_*`, `_scripted`) read no `TownLayout.`. **Ruling (D11, R5):** the
  Aldermere-only scenarios in `behaviour_check.gd` (calm, gates, siege, boats, judgement ...) keep their `TownLayout` reads; they are
  Aldermere's tests by design. The three reads in `routes/tier3_b.gd` (MARKET_SQUARE x2) and `routes/tier4_b.gd` (BELL_TOWER) move to the
  city (exact).

### 1.4 Place requirements

**Ruling (D12, R12):** a mission's needs are one table, **`MissionNeeds`** (`src/game/mission/mission_needs.gd`, `const TABLE := {id:
PackedStringArray}`, `static func of(id) -> PackedStringArray`), read by **`MissionDef.needs()`** -- not a field set in 30 builders (one
reviewable file; no hunk in every mission builder). Every id in `MissionBook.all()`, `campaign_missions()`, `tier_missions()`,
`dev_missions()` and `TierBook.all()` has an entry.

- **What a need is:** a name `Places.has()` answers (§1.2).
- **The scan test** (`tests/test_mission_needs.gd::_reads_are_needs`): every name a director script (and its base scripts, through
  `get_base_script()`) passes to `Places.rect/at/point(&"...")` is in its mission's needs; and `Places.can_host(id, AldermereCity)` holds
  for every mission. So a director cannot read a place its table forgets.
- **Hostable in a town:** `MissionBook.hostable(id, city) -> bool` = `Places.can_host(id, city)` **and** (the city is the mission's home
  city -- `MissionDef.city` -- **or** the city has overrides for it, §1.5). **Ruling (D13, R12):** needs alone would offer The Tax
  Collector in the Capital in M1 with Aldermere's coordinates (debtors in the river); a town offers a mission only once its spots are set.

Tier 1's needs (the other 20 missions' rows are filled from their scans in M1's Task 3):

| Mission | Needs | Why |
|---|---|---|
| The Warning / Starfall (`warning`) | `temple`, `bell_tower` | the Herald's goal and the Lantern's beam; the bellkeeper's tower |
| The Tax Collector | `temple`, `bell_tower`, `citadel`, `citadel_gate`, `workshop` | the Lantern (watch night); the taxes' goal; the default counting-house |
| Spoiled Harvest | `citadel`, `citadel_gate`, `temple` | the carts' goal; the Temple, which every director reads (`MissionDirector.lantern_door_in`) -- pre-flight ruling, Task 3's scan demands it |
| The Lost Lamb | `temple` | where a seizer takes him (spots are the town's) |
| First Prayers | `temple`, `bell_tower`, `market_square` | Mira's Temple's door and reports; the Lantern (gaze night); the shrine by the market |

### 1.5 Per-town overrides

**Ruling (D14, R10):** a director's spots are **per-city data**, not re-derived from landmarks. Aldermere's `const` spots and numbers stay
the source of truth for Aldermere (exact, cheaper); a town that hosts a mission supplies its own values. Landmark-relative spots are kept
where the code already has them (the Temple's door, a door's `WATCH_OFFS`, `LINE_SPOTS`, `PRIEST_SPOTS`).

- **Where:** one file per (town, mission): `src/game/town/cities/<city>_missions/<mission_id>.gd`, a script with
  `static func overrides() -> Dictionary`. **Ruling (D15, R11):** a file each, loaded by path (`CityDef.mission_overrides()` in the base
  class: `ResourceLoader.exists(path)` then `load(path).overrides()`), so M2's five parallel tasks never edit one shared file; any future
  town gets the mechanism by having the folder.
- **Shape:** `{"def": {property: value}, "director": {property: value}}`. `def` keys are `MissionDef` properties (`camera_at`, `intro_from`,
  rarely copy: `brief`, `goal`, `lose`); `director` keys are the director's **town vars** (below).
- **Town vars.** A director that a town hosts reads its places and tunable numbers from vars seeded by its consts (`var set_out_at:
  Array = SET_OUT_AT`, ...), named as the const in lower case; Aldermere never sets them, so nothing moves. **Ruling (R31):** where the
  base class already has the var (`EscortDirector.charge_start`, `AssassinateDirector.visit_seconds`, `MirasHouseDirector.read_seconds`,
  ...), the director seeds it in `_init()` and its `_plan()`/`_begin()` stop assigning it, so an override set before setup survives;
  the plan's Task 6 table names every var (and maps this section's knob names to them: `pray_seconds` is `read_seconds`, the Lamb's
  `start` is `charge_start`, ...). M1 gives the five Tier 1 directors these vars; the scripted policies read `d.<var>` instead of
  `Director.CONST`.
- **Order:** `MissionDef.make_director()`: `stretch`, then the board's `tune` (v0.11), then the town's `director` overrides -- the town is
  the most specific (D16, R13). `def` overrides are applied when the def is put in its town (`MissionBook.in_city()`, §1.6).
- **Checked:** `Overrides.apply(target, values) -> PackedStringArray` (`src/game/mission/overrides.gd`) sets each key with `set()` and
  returns (and `push_error`s) every key the target has no property for; a test builds every override file's def and director and asserts
  none unknown and every value's type equals the seeded var's.
- **What may be overridden:** spots, tags (e.g. the counting-house's art tag), labels and names on tags and banners, and numbers that
  appear in no copy. **Ruling (D17, R14):** a number written into a hint, the tour's fixed text or the legend (Harvest's 10 s burn and 3 s
  smother, First Prayers' three) is not overridable in v0.12: a town must never make the game's words false. A tour line that names a time
  reads the var (Tax Collector's `tour()` already formats `SET_OUT_AT`; it reads `set_out_at`).

### 1.6 Running a mission in a chosen town

- **Ids.** A mission put in another town is `"<mission_id>@<city>"` (e.g. `tax_collector@capital`). `MissionBook.city_id(id, city)`,
  `MissionBook.split_city(id) -> [base_id, city]` (`&""` when none). **Ruling (D18, R15):** a composite id rides through Game, Prepare,
  the board, Restart and the save unchanged; it never collides with Aldermere's bests or the board's `cleared`.
- **The def.** `MissionBook.in_city(m: MissionDef, city: StringName) -> MissionDef`: sets `m.city`, applies the town's `def` overrides, and
  chains `m.tune` so the town's `director` overrides follow the board's tuning. `Mission.def_for(id, on_board, state)` splits a composite
  id and returns `in_city(def_for(base, on_board, state), city)`; `MissionBook.get_mission(composite)` likewise. **A DEV-tab town night is
  the board's version** of the mission (Starfall for `warning`, the tier's clock and budget) -- the same def Aldermere's board plays.
- **The CLI.** `Mission` reads `--city=<id>` itself when it starts on its own (`autostart`), so a scripted run's first automatic start and
  `behaviour_check`'s own start build the same town: `--scenario=tax --case=play --seed=1 --city=capital`. **Ruling (D19, R27):** the
  capital branch's `mission.city` var stays for its two scenarios; `--city` is ignored by `Game` (the DEV tab is the game's way).
- **No Descent off Aldermere.** **Ruling (D20, R15/R26):** in v0.12 a night played outside Aldermere has no Descent: no wishes, no
  believers, no banking, no tier progress (`Mission._descent` only when `_def.city == &"aldermere"`; `MissionBook.is_dev()` is true for a
  composite id, so `Game.board_locked_for()` opens every power, as for the sandbox). The wishes still read Aldermere's spots
  (`PressedWish`'s barracks aside); porting them is the player-facing town UX's work. Cost if wrong: Capital gates run without the wishes'
  extra people.
- **The gates' flags.** A Capital gate is Aldermere's gate command plus `--city=capital` (§1.8).

### 1.7 The DEV tab

With `--dev` the board's DEV tab (merged from the capital) lists, after `MissionBook.dev_missions()` (the Capital Sandbox), every
`MissionBook.town_missions(city)` for each town but Aldermere (`City.IDS`, new: `[&"aldermere", &"capital"]`): the composite ids of
`TierBook.all()` whose base is `hostable()` there, in tier order. In M1 that is the sandbox alone (no overrides yet); after M2, the sandbox
and the five Tier 1 missions.

- **Cards.** **Ruling (D21, R22):** six cards are 94 px wide on the 640 px board; a DEV card shows the mission's name, the town in gold
  (`CAPITAL`) and its type line (`TierBook.type_of(base)`), no brief. Every line fits its card (test).
- Picking one goes to Prepare and the mission like any board pick; Results go back to the board's DEV tab (`_tier_of()` knows composite
  ids); the save keeps its best under the composite id.
- Without `--dev` nothing of it shows (the capital's `_dev` test, kept and extended).
- **FLOW** (D22, R23): one step in M1 -- with `game.dev` set, the board's DEV tab picks the Capital Sandbox, the mission starts in the
  Capital (`City.current().id() == &"capital"`), Esc-to-board, a Tier 1 board pick starts in Aldermere with `City.current().structures() ==
  AldermereCity.new().structures()`. M2 adds one more (§2.7).

### 1.8 Tooling

- `tools/dev/gate.sh`: `--city=<id>` (appended to every run; the verdict line prints `city=<id>`) and `--with-none` (route b runs the three
  `none` cases too and judges `none_lost` 3/3). **Ruling (D23, R17):** Aldermere's ★ Starfall has no route-a policy (route a of `warning` is
  the campaign night); the Capital's Starfall is gated on route b with `--with-none` so "doing nothing loses" is still proved.
- `tools/dev/land.sh`: `--bench-only` (import and bench, no trial merge, suite, references or FLOW). **Ruling (D24, R21):** the Capital's
  bench has no v0.11.2 side to compare; it is recorded against the capital tip:
  `bash tools/dev/land.sh --bench-only --bench=f7d74922 --pairs="capital_sandbox:capital_sandbox"`.
- `tools/dev/refs_check.sh`: unchanged; Capital rows carry `--city=capital` in their `how` column, and their names end
  `_(none|play|toll)_<n>` so they run in parallel.

## 2. M2: Tier 1 in the Capital (dev-only)

### 2.0 What all five share

- **The stage is the old town.** **Ruling (D25, R20):** every Tier 1 night in the Capital is played inside the old town's wall ring
  (`INNER`, 42x34, about Aldermere's whole walled town): the Keep and its Citadel, the cathedral (the Temple) and its bell tower, the Great
  Market, the guild and noble quarters and the old town houses. No mission's route crosses the river: the bridges' gatehouses queue people
  one a second and would make walks a matter of traffic (no luck).
- **Walk parity first.** **Ruling (D26, R19):** each mission's key walks in the Capital (path length on the built `WalkGrid`, from the
  same `WalkGrid.path()` the people use) are within **0.75-1.35x** of Aldermere's, so its numbers -- tuned on Aldermere's walks -- hold.
  A test per mission (`tests/test_capital_<mission>.gd::_walk_parity`) prints both and asserts the band, except where a section below
  names a wider one. A gate miss is met first by the spot (parity), then by the scripted policy, then by the numbers in that mission's
  order: at most three rounds, else DONE_WITH_CONCERNS with the numbers.
- **The crowd.** The Capital deals ~420 citizens and ~180 soldiers; its street patrols (20 pairs) and wall loops are the town's, not the
  mission's opposition: they seize no one and guard nothing, but they see. The spread rule applies to the mission's own people. The
  policies' unseen-kill tests (`crowd_alone`, `_tax_unseen`) stay as they are; if one fails for traffic, the stage moves (D26).
- **Readiness, clock, budget:** the board's Tier 1 (Unaware, 5:00, 3 slots, 6 DP). Loadouts A and B are Aldermere's
  (`RouteBook.loadout_b`).
- **Camera:** each night's `camera_at` / `intro_from` is a `def` override; a test (pattern of `tests/test_exodus.gd`) checks that the
  first target's tag at the intro camera lies outside `Kit.STACK` grown by `Hud.STACK_PAD`.
- **References:** one TSV per mission, `tools/dev/refs/capital_<scenario>.tsv`, rows `capital_<scenario>_none_<n>`,
  `capital_<scenario>_play_<n>`, `capital_<scenario>_b_play_<n>`, `capital_<scenario>_toll_<n>` (seeds 1-3), each `how` ending
  `--city=capital`.
- **Gates** (seeds 1-3, the brief's): none loses 3/3; play wins ≥2/3; route a median 180-240 s; route b median 150-270 s; idle ≤45 s; no
  designed wait over 60 s; the toll case per v0.11.2's D32 and C12 (wins ≥2/3; idle and median reported; a Gaze stealth night's toll is
  reported, not binding, if under 2/3). Aldermere's v0.11.2 results for comparison: Tax A 3/3 201 38, B 2/3 238 35, toll 3/3; Harvest A
  3/3 189 40, B 3/3 150 30; Lamb A 3/3 194 32, B 3/3 222 30; Prayers A 3/3 219 35, B 3/3 262 42, toll 2/3; Starfall B 3/3 185 40, toll 2/3.

Coordinates below are **first guesses** from `CapitalCity`'s constants (ground cells, north = -y), to be snapped to walkable ground and to
dwellings `RuinWish.fits(s, "house")` accepts, and checked by the parity test.

### 2.1 The Warning on the board (Starfall) in the Capital

- **Needs:** `temple` (the cathedral `(-6.0, -20.8, 4.2, 6.2)`; door about `(-3.9, -14.0)`), `bell_tower` (`(-8.6, -20.6)`; the keeper's
  foot about `(-9.05, -20.05)`). Herald and Bearer walk tower <-> cathedral door: ~7.6 vs Aldermere's ~8.5 (in band).
- **Spots to set first:** `star_falls` (the town var of `STARS`: time, post, banner name). Aldermere's runs from post to the keeper's foot:
  postern 18.3, Main Gate 13.7, Side Gate 11.0 -- each later runner nearer. The old town has five gates, all at least 15 from the tower:
  the harbour gate (inside about `(16.4, -9.0)`, ~28), the river gates (inside about `(4.0, 2.4)` ~26 and `(-14.0, 2.4)` ~23) and the west
  gate (inside about `(-22.4, -13.0)`, ~15). First guess: **harbour gate -> west river gate -> west gate** (far to near), banners
  `THE HARBOUR GATE`, `THE RIVER GATE`, `THE WEST GATE`. **Ruling (D27):** Starfall's parity band is 0.75-**1.6x** (the old town's gates are
  where they are); a longer run is more room for the player, not a wait, since the next star follows the last stop by `STOP_WAIT`.
- **Tuning order:** (1) which gates (posts), (2) the fall times 10 / 90 / 180 (each ±30, every wait ≤60 s), (3) `STOP_WAIT` 30 (20-40).
  Never the warning's reflexes (`OMEN_AT`, `STARE`, the runner's pace): they are the campaign Warning's too.
- **Risks:** *no luck* -- the river-gate runner crosses the Great Market, the busiest square: the policy's unseen Doom may wait on
  traffic (watch idle); *chain pacing* -- a long first run must not leave the second star's window empty; *clarity* -- the camera
  (`gate.lerp(bell, 0.35)` as Aldermere's) must show the harbour gate's tag clear of the HUD stack.
- **Gate:** `gate.sh warning --route=b --board --city=capital --with-none` (★: wins ≥2/3, idle ≤45, median reported; none 3/3 lost);
  toll `gate.sh warning --route=b --board --city=capital --case=toll` (≥2/3, binding: a Herald night). TSV `capital_starfall.tsv`
  (`capital_starfall_none_*`, `capital_starfall_b_play_*`, `capital_starfall_toll_*`).

### 2.2 The Tax Collector in the Capital

- **Needs:** `temple`, `bell_tower` (watch night: the Lantern), `citadel`, `citadel_gate` `(0, -22.6)`, `workshop` (Aldermere's default
  counting-house; the Capital overrides it).
- **Spots to set first:** `counting_tag` -- **`&"gpt_weighhouse"`** (the Great Market's weigh-house, `(-6.2, -7.7)`), with
  `counting_spot` its fallback; `rounds` (three lists of debtor spots). Aldermere: counting-house door -> Citadel gate ~23; the three
  rounds' first legs ~12, ~22, ~22. First guess: rounds in the old town houses and the Great Market's back streets -- collector
  `[(8, 0), (-18, 1), (-20, -12)]`, first deputy `[(10, -14), (-14, -15)]`, second deputy `[(14, -3), (2, 1), (-16, -5)]` -- each leg and
  the last stop -> Citadel gate in band.
- **Tuning order:** (1) counting-house and rounds (parity), (2) `set_out_at` 35 / 95 / 155 (every wait ≤60 s), (3) `chain_wait` 45 (30-50),
  (4) `visit_seconds` 20 (15-25), (5) `flush_gap` 1.5 (≤3.0). Never `guards` or `alarm_reach` down to pass.
- **Risks:** *no luck* -- the weigh-house stands on the Great Market: a collector killed at its door is seen; the policy's `_tax_unseen()`
  waits for him to leave the square (watch idle); *chain pacing* -- the collectors' last legs climb to the Keep, past the cathedral square;
  *spread opposition* -- `GUARD_R` 0.6 keeps a collector's guards at his side (Aldermere's design, unchanged); the Capital's street
  patrols are witnesses only; *no hidden losses* -- "A collector reaches the Citadel" is the Keep's gate here: the `CITADEL` place tag must
  point at `(0, -22.6)`.
- **Gate:** `gate.sh tax --city=capital`, `gate.sh tax --route=b --city=capital`, toll `--case=toll` (binding). TSV `capital_tax.tsv`.

### 2.3 Spoiled Harvest in the Capital

- **Needs:** `citadel`, `citadel_gate`, `temple` (every director reads the Temple through `MissionDirector`).
- **Spots to set first:** `store_spots` and `store_names`. Aldermere's granaries from the Citadel's gate: 19.7 (south-west), 29.8
  (south-east), 22.9 (north-east). First guess, old town dwellings: **north-east `(15, -14)`** (~17), **south-east `(14, 0)`** (~27),
  **west `(-16, -4)`** (~25), names `north-east`, `south-east`, `west`. The carter walks gate <-> granary five times: parity on that walk
  is the one that matters most.
- **Tuning order:** (1) store spots (parity of the cart walk), (2) `grain_at` 60 / 120 / 180, (3) `chain_after` 45 (30-45), (4) `load_count` 5
  (4-6). Fixed (copy, D17): `SPOIL_SECONDS` 10, `SMOTHER_AFTER` 3, `WATCHMEN` 2 and `WATCH_OFFS` (more than 1.6 apart already).
- **Risks:** *chain pacing* -- a longer cart walk empties a granary later, so the player waits for grain: `grain_at` before `load_count`;
  *spread opposition* -- both watchmen per door must stay >1.6 apart on the Capital's narrower lanes (`WATCH_OFFS` is door-relative: check
  the snapped posts); *no luck* -- the relief watchman walks in from the nearest lay citizens: in the Capital's dense old town a relief
  arrives sooner; *clarity* -- the first granary's camera clear of the HUD (Aldermere's moved for that in v0.11 M2).
- **Gate:** `gate.sh harvest --city=capital`, `gate.sh harvest --route=b --city=capital`. No Lantern (no toll case). TSV
  `capital_harvest.tsv`.

### 2.4 The Lost Lamb in the Capital

- **Needs:** `temple`.
- **Spots to set first:** `start` (the cleric's hiding place: Aldermere's north-east fountain plaza `(11.4, -10.0)`; the Capital's civic
  square fountain `(5.5, -17.0)` -> about `(6.1, -16.0)`), `gate_mouth` / `exit` (the old town's **west gate**, the mission's own words:
  mouth about `(-22.4, -13.0)`, exit about `(-25.6, -13.0)`), `posts` (either side of the mouth along the wall, >1.6 apart: about
  `(-22.2, -13.9)` and `(-22.2, -12.1)`), `guardhouse` (6 along the wall: about `(-22.6, -7.0)`), `temple_door` (the cathedral's door,
  about `(-3.9, -14.0)`), `beats` (two: one across his way, about `(-14, -19) <-> (-14, -7)`, one along it, about `(-8, -11) <-> (4,
  -11)`). Aldermere's start -> gate mouth ~26-28; the Capital's ~29-31 (in band).
- **Policy:** `LAMB_WAIT` (Aldermere `(0, -4)`, "short of the gate", which assumes a gate facing south) becomes 4 units inward from the
  gate along `exit -> gate_mouth` (M1 makes it so; Aldermere exact, since `(0, -3.2).normalized() * 4.0 == (0, -4)`).
- **Tuning order:** (1) spots (parity; beats crossing his route), (2) `charge_pace` 0.385 (0.33-0.45), (3) `hunt_at` 150 (120-180). The
  watch's change times (`EscortDirector.WATCH_CHANGE/GAP/CYCLE`) are shared with The Prisoner and stay.
- **Risks:** *no hidden losses* -- the route passes the cathedral door, where a seizer delivers him: a seizure near the door loses in
  seconds (Aldermere moved a beat for this; keep beats ≥6 from `temple_door`); *spread opposition* -- the two posts and each patrol pair;
  *clarity* -- `WEST GATE` place tag and the camera `start.lerp(gate_mouth, 0.3)` clear of the HUD.
- **Gate:** `gate.sh lamb --city=capital`, `gate.sh lamb --route=b --city=capital`. No Lantern. TSV `capital_lamb.tsv`.

### 2.5 First Prayers in the Capital

- **Needs:** `temple`, `bell_tower`, `market_square` (the Great Market `(-12, -6, 9, 7)`).
- **Spots to set first:** `shrine_at` (Aldermere: the market's west edge `(-4.4, 2.8)`; the Capital: the Great Market's west edge, about
  `(-11.2, -2.5)`, on free ground), `poor_spot` (Aldermere's south-west quarter `(-11.0, 12.0)`, ~11.3 from the shrine; the Capital: the
  west market's back lanes, about `(-21, -5)`, ~10). Temple door -> shrine is ~13.6 vs Aldermere's 9.4 (1.45x): **Ruling (D28):** that run
  (a Faithful's report) is reported, not asserted -- a longer report run is room for the player, not a wait.
- **Tuning order:** (1) shrine and poor spot (parity of the poor's walk), (2) `pray_seconds` 32 (25-40), (3) `market_at` 75 / `priests_at`
  150 (windows, each ≤60 s apart from the last thing to do), (4) `faithful_lay` 3 (2-4). Fixed (copy): `NEED` 3.
- **Risks:** *no luck* -- the Great Market fills at `market_at` with a far bigger crowd than Aldermere's: the policy's "door unwatched"
  test may stay false (watch idle); *spread opposition* -- `PRIEST_SPOTS` and Mira's `LINE_SPOTS` are door-relative (2.0 and 2.4 apart);
  *no hidden losses* -- the Gaze and the Lantern's toll (+40) are unchanged.
- **Gate:** `gate.sh prayers --city=capital`, `gate.sh prayers --route=b --city=capital`, toll `--case=toll` (a Gaze stealth night:
  reported per C12 if under 2/3; the bell must still never lose outright). TSV `capital_prayers.tsv`.

### 2.6 Landing M2

All five on one tree, as landing sees it: every Capital row and gate again, every Aldermere row (none may move), FLOW alone, `land.sh
--bench=kak-v012-m1` (Aldermere's five boards; within ~1 fps), and the Capital's Starfall recorded once
(`--bench-only --bench=kak-v012-m1 --pairs="warning@capital:warning@capital"`, `--board`, for the record).

### 2.7 FLOW in M2

One step: with `game.dev`, the DEV tab lists the sandbox and the five `@capital` cards; picking `tax_collector@capital` starts The Tax
Collector in the Capital (`City.current().id() == &"capital"` and the director's `counting_tag == &"gpt_weighhouse"`), and Esc returns to
the DEV tab.

## 3. Gates

| When | Run |
|---|---|
| Per task | focused tests; `bash tools/dev/run_suite_parallel.sh 8` (3 in a parallel phase); `bash tools/dev/refs_check.sh --only='<touched>'` (`--jobs=2` in a parallel phase); the mission's gates; FLOW only where the task says, alone |
| M1 landing | `bash tools/dev/land.sh --bench=kak-v0.11.2` (trial merge, suite, every reference incl. `capital_calm` / `capital_evac`, FLOW alone, Aldermere bench); `bash tools/dev/land.sh --bench-only --bench=f7d74922 --pairs="capital_sandbox:capital_sandbox"` (recorded) |
| M2 landing | `bash tools/dev/land.sh --bench=kak-v012-m1`; every Capital gate and toll gate; the Capital Starfall bench (recorded) |

**Ruling (D29, R21):** the capital branch's summary measured Aldermere at 83.1 -> 80.6 fps across its polish 3 (the border band and its
trees, which Aldermere also draws: `AldermereCity.BORDER` 12). If M1's Aldermere pairs drop more than ~1 fps against `kak-v0.11.2`, the
pairs are rerun on a quiet machine; a drop that stays and is traced to the border band is reported with the numbers for the user, not fixed
in v0.12.

## 4. Out of scope

- Citadel/Keep missions in the Capital (Last Judgement, The Long Night, The Armoury, The Prisoner, ...): the Capital has a Citadel (D7),
  but their ports are later milestones; so are Tiers 2-5.
- The player-facing town choice (the DEV tab is the only door); wishes, believers and banking off Aldermere (D20).
- New art, new sounds, new powers; any change to the Capital's layout beyond naming existing rects and points.
- The campaign (always Aldermere).

## 5. Decisions

1. Ruling: `crowd_check` is `-935602679` (v0.11.2), not the brief's -346732806; the TSV is the reference -- cost if wrong: none.
2. Ruling: only `pressed_wish.gd` reads TownLayout in shared code added since `3ff44f10` -- cost if wrong: the guard finds another.
3. `RescueWish.GATE`, `HarvestDirector.CITADEL_GATE` and `TaxCollectorDirector.CITADEL_GATE` read the place `citadel_gate`.
4. Ruling: clergy tests use `CitizenProfile.is_clergy()` in mission, descend and the rite -- cost if wrong: a Capital monk is skipped
   where a cleric would be taken.
5. Ruling: a capital crowd rule that moves an Aldermere row goes behind a `CityDef` switch -- cost if wrong: one more city flag.
6. Ruling: the Capital's references are measured at its tip and on the merged tree, not taken from memory or its summary -- cost if
   wrong: none (measuring is cheap).
7. Ruling (corrects the brief): the Capital has a Citadel at `(0, -25.5)`; its missions are out of scope by decision -- cost if wrong:
   none for M1-M2.
8. Ruling: places are named on `CityDef`; missions read them through `Places`, which errors on an unknown name -- cost if wrong: a thin
   extra helper.
9. A TownLayout read becomes the same expression on the city; an Aldermere literal stays a literal.
10. Ruling: `MissionDef.camera_at` defaults to `Vector2.INF`, read as the city's Citadel -- cost if wrong: one more INF check.
11. Ruling: the guard adds `src/game/mission`, `tools/dev/routes` and the Tier 1 policies of `behaviour_check.gd`; Aldermere-only
    scenarios keep TownLayout -- cost if wrong: a policy reads Aldermere in the Capital unnoticed until its gate.
12. Ruling: needs are one table (`MissionNeeds`) checked against what each director reads -- cost if wrong: none.
13. Ruling: hostable = needs met and the town's spots set (or its home town) -- cost if wrong: none.
14. Ruling: spots are per-city data with town vars seeded by Aldermere's consts, not landmark-relative rewrites -- cost if wrong: each
    new town writes its own spots (data, not code).
15. Ruling: one overrides file per (town, mission), loaded by path -- cost if wrong: many small files.
16. Ruling: overrides apply after the board's tuning -- cost if wrong: a town cannot undo a board tune (none exists for Tier 1).
17. Ruling: numbers written in copy are not overridable -- cost if wrong: a town that needs another burn time waits for the copy to read
    the var.
18. Ruling: composite ids `<mission>@<city>` -- cost if wrong: a save keyed by them (dev only).
19. Ruling: `Mission` reads `--city` when it starts itself; `Game` ignores it -- cost if wrong: none.
20. Ruling: no Descent off Aldermere in v0.12 -- cost if wrong: Capital gates run without the wishes' extra people.
21. Ruling: DEV cards show name, town and type, no brief -- cost if wrong: a dev-only card is terse.
22. Ruling: FLOW gains one step per milestone (the DEV tab's town round trip) -- cost if wrong: a few seconds of FLOW.
23. Ruling: Capital Starfall is gated on route b with `--with-none` -- cost if wrong: none.
24. Ruling: `land.sh --bench-only`; the Capital's bench is recorded against its own tip -- cost if wrong: none.
25. Ruling: every Tier 1 night in the Capital is played inside the old town's ring -- cost if wrong: the Capital's new town and harbour
    stay unused by Tier 1.
26. Ruling: key walks within 0.75-1.35x of Aldermere's (parity test) before any number is tuned -- cost if wrong: a parity spot that
    plays badly; the gate still decides.
27. Ruling: Starfall's parity band is 0.75-1.6x -- cost if wrong: a slow first star.
28. Ruling: First Prayers' report run is reported, not asserted -- cost if wrong: an easier report chase.
29. Ruling: a bench drop traced to the capital's border band is reported, not fixed in v0.12 -- cost if wrong: Aldermere ~2 fps slower
    until a perf pass.
