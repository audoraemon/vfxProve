# KAK: The Capital at Every Tier (design)

Date: 2026-11-21. Branch `feat/god-chamber` (worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-chamber`).
Follows `docs/superpowers/specs/2026-10-23-kak-v012-many-towns.md` (how Tier 1 came to the Capital: overrides files, town vars,
walk parity, gates) and `docs/superpowers/specs/2026-11-20-kak-world-map-conquer-design.md` section 4.6 (nights in the Capital).

## 1. Goal

A god night in the Capital works at every tier. Today `MissionBook.hostable(id, capital)` is true only for the five Tier 1
missions, so a god at Tier 2 or higher who picks the Capital on the World Map gets "No night waits there yet". After this work
the Capital hosts all twenty missions of Tiers 2 to 5 (`TierBook.MISSIONS`):

| Tier | Missions |
|---|---|
| 2 | miras_house, broken_lanterns, bell_ringers, market_panic, informer |
| 3 | vigil_flame, festival, crowns_bread, prisoner, heretic_hunt |
| 4 | procession, bishop, armoury, sermon, relic_run |
| 5 | last_judgement, long_night, lantern_eye, exodus, heart_of_faith |

A tier is usable in the Capital when all five of its missions are hostable there and pass their gates. Work goes tier by tier,
Tier 2 first.

## 2. Binding rules (unchanged from v0.12)

### 2.1 Mission design rules

- **No waiting.** Every timed wait is 60 s or less. Doing nothing loses. An acting player idles 45 s at most.
- **Chain pacing.** The next thing to do comes as the last one ends, or within 45 s of it. A longer walk in the Capital is
  absorbed by the mission's numbers, never by the player waiting. The chain must be reachable by arithmetic: each stage's time is
  at most the previous stage's time plus its CHAIN.
- **Spread opposition.** A mission's own guards, watchmen, escorts and patrols stand more than 1.6 apart (two Silent Doom radii).
- **No luck.** No outcome depends on street traffic. The Capital's old town is busier than Aldermere. A stage where an unseen kill
  depends on who passes moves to a quieter block before any number changes.
- **No hidden losses.** Every instant loss is warned plainly with room to act. A death that loses is tagged DO NOT KILL. The
  winning strike never also loses. **The bell never loses outright**: the toll turns the Lantern.
- **Clarity.** Every moving target is edge-arrowed. Tags count down. The intro camera keeps the first target's tag clear of the
  HUD stack (`Kit.STACK` grown by `Hud.STACK_PAD`).

### 2.2 Aldermere stays exact

- No Aldermere reference row moves (`bash tools/dev/refs_check.sh` prints `bad=0`; `ok` grows only by the new `capital_*` rows).
- `state_digest` unchanged. FLOW unchanged apart from the known headless music checks.
- Every new town var is seeded from the existing const, so Aldermere reads the same value it reads today.
- Where a director switches from a const to a town lookup (`Places`, `City.current()`), the plan's test proves the Aldermere
  value is bit-equal to the old const (for example `Places.point(&"citadel_gate") == HarvestDirector.CITADEL_GATE`).

### 2.3 What may move

- New files: one overrides file per mission in `src/game/town/cities/capital_missions/`, one test per mission
  `tests/test_capital_<scenario>.gd`, one reference file per mission `tools/dev/refs/capital_<scenario>.tsv`.
- Directors: consts become town vars (section 4), and the few code changes section 5 lists.
- `CapitalCity`: only `gate_towers()` (section 3). No building moves. No new art.
- Policies (`tools/dev/behaviour_check.gd`, `tools/dev/routes/tier<N>_b.gd`): a read of a director const that is now a town var
  becomes `d.<var>`; a read of a `TownLayout` coordinate becomes a town lookup. Aldermere's rows prove nothing moved.

### 2.4 The stage

As in v0.12 (D25): every night is played inside the old town's wall ring (`CapitalCity.INNER`, x -24..18, y -30..4), unless a
mission's own words need the river or the harbour (the Procession's dock, the Crown's Bread's bridge). A mission's own people
never queue at a bridge gatehouse on the way to a stage. Leaving the old town ring counts as leaving the town
(`Walls.outside()` reads `City.town()`, which is `INNER` in the Capital), so a river gate is a way out.

### 2.5 Walk parity

Each mission's key walks (path length on the built `WalkGrid`) are within **0.75-1.35x** of Aldermere's. The test of each mission
prints both and asserts the band. A miss is met first by the spot, then by the policy, then by the numbers, at most three rounds.
Coordinates in section 6 are first guesses from `CapitalCity`'s constants: the directors snap them to walkable ground, and the
parity and spot tests decide.

## 3. The gate towers

**Decision:** `CapitalCity.gate_towers()` returns the two towers of the old town's **west river gate** (`INNER_GATES[1]`,
`(-14, 4)`), west tower first, as Aldermere lists the Main Gate's west tower then its east tower.

- The towers already exist. Every Capital gatehouse is built by `TownLayout.ring_gatehouse()` with two `WALL_TOWER` towers, and
  `_ring_structures()` adds them as `Structure.Kind.KEEP`, role `&"tower"`. `gate_towers()` only names them:
  `_gatehouses(INNER, [INNER_GATES[1]]).towers`. No layout change, no art.
- Why this gate: both missions that read gate towers use them with targets near the Great Market and the west stone bridge. The
  Crown's Bread's bridge shift waits in the west tower beside its bridge (section 6.3.3). The Armoury's "gate barracks" is the
  east tower, about 10 from the market tavern and on the west bridge avenue (section 6.4.3).
- Rejected: the south barbican (the Capital's `main_gate` landmark). It stands 34 south of the river, across a bridge, and both
  missions would cross the river. Rejected: the west gate. It is the Lost Lamb's way out and Starfall's third post.
- `MissionNeeds` keeps `gate_towers:2`. `Places.can_host("crowns_bread"|"armoury", capital)` becomes true. The test line in
  `tests/test_mission_needs.gd` (`_unknown_and_counts`, "the Capital models no gate towers") flips to assert the Capital has
  two.
- Nothing else reads `gate_towers()` (only `CrownsBreadDirector._gate_tower()` and `ArmouryDirector._find_targets()`), so
  `capital_calm` and `capital_evac` do not move.

## 4. Town vars

Each of the twenty directors (and the Long Night's acts) gets `const TOWN_VARS := [...]`, as the Tier 1 directors have. Two kinds,
as v0.12 ruling R31:

- A var the director lacks: `var <name>: <type> = <CONST>`; every read of the const in code (not in `const` lines) reads the var.
- A var the base class already has and `_plan()`/`setup()` assigns (EscortDirector's `charge_start`, `gate_at`, `exit_at`,
  `return_to`, `guardhouse`, `watch_posts`, `patrol_size`, `hunt_at`, `hunt_size`, `charge_pace`; AssassinateDirector's
  `safe_at`, `visit_seconds`, `hide_seconds`, `alarm_reach`, `chain_wait`): seeded in `_init()`, and setup stops assigning it.
  `LostLambDirector` and `TaxCollectorDirector` are the pattern.

Copy: a tour line, banner, map tag or hint that names a place reads a town var of words (for example `post_names`,
`source_names`). A number in copy is never overridable (v0.12 D17). Shared reflexes (`EscortDirector.WATCH_*`, `SIGHT`,
`Crowd.DOOM_WITNESS`) are never town vars.

Shared bases. Town vars are declared on the class that reads the const. A subclass's `TOWN_VARS` lists its own and the base's it
needs overridden (Overrides reads the subclass's constant map only):

| Base | Subclasses in scope | Base change |
|---|---|---|
| `MissionDirector` | all | none |
| `FestivalDirector` | market_panic, festival, Long Night Act II-A | none: it reads `Places` only |
| `MirasHouseDirector` | miras_house, sermon | `mira_spot` town var (sermon never reads it) |
| `VigilFlameDirector` | vigil_flame, relic_run | `mira_shrine`, `route_spots` town vars |
| `AssassinateDirector` | informer, bishop (tax_collector already done) | none: subclasses seed its vars in `_init()` |
| `EscortDirector` | prisoner, exodus (lost_lamb already done) | none: subclasses seed its vars in `_init()` |
| `RazeDirector` | crowns_bread, armoury, heart_of_faith | none |
| `HuntDirector` | heretic_hunt, lantern_eye | none |
| `WarningDirector` | Long Night Act I (and `RingerDirector`, `WitnessDirector`) | `gate_spot` town var |

## 5. Code changes beyond overrides files

Every director gets town vars (section 4). These are the changes beyond that, one line each:

1. **`CapitalCity.gate_towers()`** (section 3).
2. **Inward direction** in `BellRingersDirector._town_door()` and `LanternEyeDirector` (line 204): `City.current().map().get_center()`
   becomes `City.current().town().get_center()`. Aldermere exact: `TownLayout.MAP` and `TownLayout.TOWN` share the centre (0, 0).
   In the Capital the map centre (0, 0) lies south of the old town's south wall, so a south wall tower's door would face out.
3. **Temple door** in `InformerDirector`, `HereticHuntDirector`, `ExodusDirector`: `const TEMPLE_DOOR := LostLambDirector.TEMPLE_DOOR`
   (Aldermere's `(0.8, -5.0)`) becomes a town var `temple_door_at`, seeded with it.
4. **Citadel gate** in `PrisonerDirector`, `BishopDirector`, `ArmouryDirector`, `HeartOfFaithDirector`: the Aldermere const
   `(-10.5, -7.6)` becomes `Places.point(&"citadel_gate")` (bit-equal in Aldermere: `AldermereCity.PLACES`), and `citadel_gate`
   joins those four rows of `MissionNeeds.TABLE` (the needs test scans `Places.point` reads).
5. **`VigilFlameDirector`** builds the Vigil's route from `BrokenLanternsDirector.SHRINE_SPOTS`: it reads its own town var
   `route_spots` (seeded with that const) instead.
6. **`CrownsBreadDirector._find_targets()`** finds the granary as `barns()[3]`, the mill by art tag `&"watermill"`, the bridge as
   `town.bridge`. The Capital's `barns()[3]` is a farm at (-38.4, 37.9), it has no watermill, and its `town.bridge` is the east
   lane bridge. New town vars: `granary_tag`, `mill_tag` (`&""`: Aldermere's rule) and `bridge_at` (`Vector2.INF`:
   `town.bridge`; else the bridge structure nearest it).
7. **`HereticHuntDirector`** indexes `City.current().districts()` with `SWEEP_DISTRICTS [1, 4, 7]` and `CELLAR_DISTRICT 6`.
   In the Capital `districts()` is a list of house blocks in another order. New town vars: `sweep_areas: Array` and
   `cellar_area: Rect2` (empty: Aldermere's indices).
8. **`ProcessionDirector._route()`** builds its five points from landmarks (court, Temple steps, market's south side, dock_wait,
   dock). New town var `route_spots: Array` (empty: the landmark points), so the Capital's Prince does not walk via the Great
   Market (section 6.4.1).
9. **`SermonDirector`** puts the pulpit at `City.current().wells()[2]`. The Capital's `wells()[2]` is in the road quarter across
   the river. New town var `pulpit_well: int = 2`.
10. **`LanternEyeDirector.SPIRE`** `(0.8, -8.7)` becomes `Places.at(&"temple")` at setup (bit-equal: Aldermere's Temple centre).
11. **Long Night per-act overrides.** `MissionBook.in_city()` applies the overrides to the root def only, and each act builds its
    own director (`Mission._build_act()` calls `play.make_director()` on the act). New overrides section `"acts"`:
    `{"acts": {"<act id>": {"def": {...}, "director": {...}}}}`. `Overrides.KEYS` gains `"acts"`; `in_city()` applies each act's
    `def` to `m.act(id)` and chains its `director` onto that act's `tune`. An unknown act id is an error, as an unknown section is.
12. **`WarningDirector.GATE_SPOT`** (the Main Gate watchman's post, `(2.7, 14.5)`) becomes the town var `gate_spot`. In the
    Capital the Omen's star falls over the west gate.
13. **Policies.** `behaviour_check.gd`: `MarketPanicDirector.HEART` (line ~3073), `PrisonerDirector.ROAD` (~3391), the Exodus
    reads of `HOUSE_*`/`GATE_*` (~4585-4686), `TownLayout.BELL_TOWER` in `_sermon_act` and `_relic_act` (~3753, ~3928),
    `JUDGEMENT_TARGETS` and `TownLayout.CITADEL_ORIGIN` in `_judgement`, `_night`, `_play_judgement`, `_richest`, and
    `FESTIVAL_LOOK_AT`; and in `routes/tier2_b.gd` to `tier5_b.gd` the same consts (`MarketPanicDirector.HEART/SOURCES/FAIR_R`,
    `PrisonerDirector.ROAD`, `ExodusDirector` house and gate consts, the `WORDS` of the Raze directors where they become vars).
    A coordinate list a town needs its own copy of (`JUDGEMENT_TARGETS`) becomes a per-city table chosen by
    `City.current().id()`, never an offset sum (float sums are not bit-equal).

## 6. Per mission

Columns: what is Aldermere-specific; where it goes in the Capital; code change (section 5 number); risks against the rules.
Distances are straight-line first guesses (A = Aldermere, C = Capital); the parity test measures paths.

### 6.1 Tier 2

#### 6.1.1 Mira's House (`miras_house`, MirasHouseDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `mira_spot` (her house is the dwelling nearest) | (-12.0, 2.0), west quarter | (-18.0, -15.5), noble quarter (patrician houses) |
| `camera_at` / `intro_from` (def) | `MIRA_SPOT` / +(0, 6) | `mira_spot` / +(0, 6) |
| Temple door, `SHOUT_OFF`, `LINE_SPOTS`, `VIGIL_ROUTE` | landmark- or door-relative | move by themselves |

- Key walk: Mira's door to the Temple door (a Faithful's report run). A about 14.6; C about 14.4 (0.99x).
- Code: town vars only (`mira_spot`). Policy: `miras` (`--case=play`); toll case `miras_toll` (Lantern).
- Risks: *no luck*: the noble quarter's door is quieter than the Great Market, which is why it is chosen. *Clarity*: the door's
  tag at the intro camera clear of the HUD. *Hidden losses*: the report run is shorter if the house is nearer the cathedral; keep
  it in band, not shorter.

#### 6.1.2 Broken Lanterns (`broken_lanterns`, BrokenLanternsDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `shrine_spots` (six shrines, the Vigil's round) | (5.5,-4.8) (10.2,-8.8) (12.0,9.2) (0.5,13.0) (-7.0,10.0) (-7.5,-4.0) | (1.5,-12.6) (7.0,-16.0) (14.0,-11.0) (12.0,-1.0) (-2.5,-1.0) (-14.5,-11.5) |
| `camera_at` | (1.0, 2.0) | (-1.0, -9.0) |

- Key walks: the flame-bearer's round. A about 79 (six legs); C about 71 (0.89x). Each shrine to the Temple door (Knights at 1:30).
- Code: town vars only (`shrine_spots`). `RELIGHT_OFF`, `GUARD_OFFSETS`, `KNEEL_RINGS` are shrine-relative.
- Policy: `lanterns` (`--case=play|bonus`); toll `lanterns_toll`.
- Risks: *spread*: two Knights per shrine at `GUARD_OFFSETS` (1.6 apart exactly: unchanged from Aldermere). *No luck*: the
  Heaven Splitter line through two shrines must not cross the busy pilgrim plaza; the (1.5, -12.6) shrine sits at its east end.
  The shrine spots must not stand on an avenue (they become structures).

#### 6.1.3 The Bell-Ringers (`bell_ringers`, BellRingersDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `post_spots` (the wall tower nearest each) | (6.6,-15.65) (-8.0,15.65) (15.65,-8.0) | (-19.0,-30.0) (-24.0,-5.0) (-24.0,-21.0) |
| `post_names` (copy) | north-east, south-west, east | north-west, south-west, west |
| `camera_at` | (6.0, -5.0) | (-14.0, -20.0) |
| `set_out_at`, `CHAIN_WAIT` | 40/110/180, 45 | unchanged first |

- Key walks: each post's door to the bell's foot (`bell.foot`, about (-9.05, -20.05)). A about 17.0 / 20.6 / 12.4; C about
  14.8 / 21.9 / 16.0 (0.87x / 1.06x / 1.29x).
- Code: town vars; section 5 item 2 (inward direction).
- Policy: `ringers`; toll `ringers_toll` (the Herald).
- Risks: *no luck*: the west wall's loop patrol walks past both west posts; a carrier's unseen kill there waits on the loop. Move
  a post to the north wall (-11, -30) if the idle stretch exceeds 45 s. *Bell never loses*: unchanged (the toll turns the Lantern).

#### 6.1.4 Market Panic (`market_panic`, MarketPanicDirector extends FestivalDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `heart` (the fair's centre, the north-east fountain) | (11.4, -10.0) | (6.1, -16.4), the civic square fountain (`FOUNTAINS[1]`) |
| `sources` (the four crowds; [0] is the heart) | (11.4,-10.0) (4.5,-4.0) (12.0,1.0) (8.75,2.75) | (6.1,-16.4) (-3.0,-11.0) (8.0,-5.0) (0.2,-5.7) |
| `source_names` (copy) | the north-east quarter, the cathedral's street, the workshops, the east tavern | the guild quarter, the cathedral's plaza, the bathhouse street, the market tavern |
| `camera_at` | (10.0, -8.0) | (5.0, -14.0) |

- Key walks: each source to the heart. A 0 / 9.1 / 11.0 / 13.0; C 0 / 10.6 / 11.6 / 12.6.
- Code: town vars (`heart`, `sources`, `source_names`); policy reads `d.heart`, `d.sources` (section 5 item 13).
- Policy: `panic`. No Lantern.
- Risks: *no luck*: the south road (x = 4) runs past the civic square; through traffic enters `FAIR_R` 5.5. The policy's Heaven
  Splitter counts goers, not passers, so traffic adds kills but not wins; check the "no warden steadies five walkers" branch does
  not fire on passers. *Spread*: three wardens on a ring `WARD_SIDE` 1.5 about the heart (unchanged geometry).

#### 6.1.5 The Informer (`informer`, InformerDirector extends AssassinateDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `contact_spots` (chandler, weaver, potter, carpenter) | (6.0,-12.4) (-13.7,12.6) (-1.4,13.8) (6.2,13.8) | (12.4,-12.5) (14.0,-3.0) (-20.0,-2.0) (6.0,0.0) |
| `lodging_at` | (-3.5, -12.0) | (-11.0, -19.5) |
| `temple_door_at` (also `safe_at`) | (0.8, -5.0) | (-3.9, -14.0) |
| `camera_at` | (3.0, -5.5) | (2.0, -10.0) |

- Key walk: the carpenter's door to the Temple door (the chase). A about 19.5; C about 17.2 (0.88x). Lodging to the door: A 8.1,
  C 10.4.
- Code: section 5 item 3; town vars seeded in `_init()` for AssassinateDirector's `safe_at`.
- Policy: `informer`; toll `informer_toll`.
- Risks: *no luck*: the Mind Whisper on a contact needs no one within `SPEAK_SEEN` 2.0; the potter at the west market is the
  busiest. If idle exceeds 45 s, move him into the patrician row (-15.0, -11.0). *Hidden losses*: `FOUND_LIMIT` 60 s after the
  last visit is in copy; unchanged.

### 6.2 Tier 3

#### 6.2.1 The Vigil Flame (`vigil_flame`, VigilFlameDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `route_spots` (the Vigil's round) | Broken Lanterns' six spots | the Capital's Broken Lanterns spots (6.1.2) |
| `mira_shrine` (where Wren takes the flame) | (-17.6, 5.0) | (-18.0, -14.0), by Mira's house |
| `camera_at` | (1.5, -8.0) | (-3.0, -12.0) |

- Key walks: the round (as 6.1.2); the swap point to Mira's shrine (Wren's carry). A about 14-20 from the round's west side; C
  about 4-8 from (-14.5, -11.5). Move `mira_shrine` to (-21.0, -18.0) if the carry is under 0.75x.
- Code: section 5 item 5. Searchlight from `Places.at(&"temple")` already.
- Policy: `flame`; toll `flame_toll`.
- Risks: *no luck*: the Searchlight beams (FAR 26) from the cathedral cover the whole old town; a carry through the pilgrim plaza
  is lit more often. *Clarity*: Wren's arrow and the bearer's at the camera.

#### 6.2.2 The Festival (`festival`, FestivalDirector; the board builds it from the Long Night's act)

- Every place is town-relative: `Places.at(&"market_square")` (Great Market, centre (-7.5, -2.5)) and `Places.at(&"fountain")`
  (its fountain, (-4.4, -2.4)). The bonfires are market-relative.
- Overrides: def `camera_at` (-7.5, -2.5), `intro_from` (-7.5, 5.5). Director: none (an empty `"director"` section is fine; the
  def section makes it hostable).
- Code: none.
- Policy: `feast --path=festival --board`.
- Risks: *no luck*: the Great Market is the busiest square; the crowd count (`FESTIVAL_CROWD`) is the director's own, so passers
  add to breakable people but not to the need. Stalls fill much of the square: check that 80 goers find spots within `PACK_R`.

#### 6.2.3 The Crown's Bread (`crowns_bread`, CrownsBreadDirector extends RazeDirector)

| Item | Aldermere | Capital |
|---|---|---|
| Granary | `barns()[3]`, farmhouse by the east road (19.5, 17.2) | `granary_tag` `&"gpt_markethall"`, the market hall (-12.0, -7.7) |
| Mill | art tag `&"watermill"` (-6.9, 25.0) | `mill_tag` `&"gpt_bakery"`, the bakery (-12.5, 17.0) |
| Bridge | `town.bridge` (south road) | `bridge_at` (-14.0, 8.0), the west stone bridge |
| Bridge shift's tower | `gate_towers()[0]` (Main Gate west) | the west river gate's west tower (section 3) |
| `names`, `words`, `stage_labels` (copy) | GRANARY, MILL, BRIDGE | MARKET HALL, BAKERY, BRIDGE; "The grain carts fill the market hall", "The bakers bake the Crown's bread", "The bread carts gather at the bridge" |
| `camera_at` | (-5.0, 21.0) | (-13.0, -2.0) |

- Key distances (the player's travel between stages): A granary to mill 27.5, mill to bridge 8; C 24.7 and 9.0.
- Code: section 5 items 1 and 6; town vars of words (the policy reads `d.words`).
- Policy: `bread`.
- Risks: *spread*: the night crew posts `POST_GAP` 1.8 along each face (unchanged). *No luck*: the market hall faces the Great
  Market; its face posts are seen by shoppers; the policy's Doom waits on them. *River*: the bakery is in the new town, across
  the west bridge; its shift waits indoors and its crew stands at its door, so nobody of the mission's queues at the gatehouse,
  but the player's casts follow the stages across the river. Allowed: the Aldermere mission is itself at the river.
- Open question: is a market hall an acceptable "granary" and the bakery a "mill"? The Capital has no watermill and its only
  granary set stands in the Keep's yard, 47 from the bakery.

#### 6.2.4 The Prisoner (`prisoner`, PrisonerDirector extends EscortDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `stocks_at` | (-6.25, -7.4) | (4.0, -19.0), the south road's head below the Keep |
| `lane_foot` | (-10.5, -5.1) | (4.0, -21.0) |
| `gate_at` / `exit_at` (postern) | (-5.75, 14.6) / (-5.75, 17.4) | harbour gate (16.4, -9.0) / (19.6, -9.0) |
| `watch_posts` | (-6.45,14.6) (-5.05,14.6) | (16.4,-9.9) (16.4,-8.1) |
| `guardhouse` | (-11.75, 14.4) | (16.0, -4.0) |
| `beat_spots` | [(-14,-5.1),(-7,-5.1)] [(-14,9),(-2,9)] | [(0.0,-16.5),(8.0,-16.5)] [(10.0,-13.0),(10.0,-4.0)] |
| `road` | stocks, (-6.25,13.5), mouth, exit | stocks, (4.0,-9.0), mouth, exit |
| `return_to` | Citadel gate | `Places.point(&"citadel_gate")` (0, -22.6) |
| copy (`gate_words`) | "The postern, down to the dock." | "The harbour gate, out to the quays." |
| `camera_at` | (-5.0, -1.0) | (8.0, -15.0) |

- Key walks: her road. A about 22.4; C about 25.1 (1.12x). Citadel gate to the stocks (`LANE_DOWN` 4): C about 4.3.
- Code: section 5 item 4; EscortDirector vars seeded in `_init()` (Lost Lamb's pattern).
- Policy: `prisoner` (reads `d.road`).
- Risks: *spread*: Aldermere's postern posts are 1.4 apart, under the rule; the Capital's are 1.8 apart. *No luck*: her road
  runs the south road and the cross avenue, both busy; the policy stops her short of watchers within 4, so traffic adds idle.
  *Hidden losses*: a seizure marches her back to the Citadel gate; keep the beats 6 or more from the gate.

#### 6.2.5 The Heretic Hunt (`heretic_hunt`, HereticHuntDirector extends HuntDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `sweep_spots` | (-6,-10) (-12,3) (-1.5,12) | (-6.0,-12.0) (-18.0,-15.0) (-20.0,-6.0) |
| `sweep_words` (copy) | the north quarter, the west quarter, the south quarter | the cathedral quarter, the noble quarter, the west market |
| `sweep_areas` | `districts()[1, 4, 7]` | `CapitalCity` district rects: cathedral_square, noble_quarter, great_market |
| `cellar_at` / `cellar_area` | (-11.0, 12.5) / `districts()[6]` | (-21.0, 1.0) / great_market |
| `temple_door_at` | (0.8, -5.0) | (-3.9, -14.0) |
| `camera_at` | (-10.5, -1.5) | (-14.0, -8.0) |

- Key walks: each sweep spot to the cellar (the closing net). A 23.4 / 9.6 / 9.6; C 19.8 / 16.3 / 7.1. The captain's walk from
  the Temple door to the cellar: A about 20.5; C about 22.6.
- Code: section 5 items 3 and 7.
- Policy: `hunt`.
- Risks: *no luck*: the cellar must be a dwelling no soldier post watches; the west gate's posts are near (-22, -13), 14 away.
  *Chain*: the second sweep is farther from the cellar than Aldermere's (1.7x); this is the net's shape, not a walk anyone
  makes on the clock, so it is printed, not asserted.

### 6.3 Tier 4

#### 6.3.1 The Procession (`procession`, ProcessionDirector; also the Long Night's Act II-B)

| Item | Aldermere | Capital |
|---|---|---|
| `route_spots` | court, Temple steps, market's south side, dock_wait, dock (from landmarks) | court's south (0.0,-22.4), cathedral door (-3.9,-14.1), harbour gate inside (16.4,-9.0), dock_wait (31.0,-4.1), boarding (31.0,-2.8) |
| `camera_at` / `intro_from` | Citadel.lerp(dock, 0.3) / Citadel | the same formula: about (9.3, -18.6) / (0, -25.5) |

- Key walk: the Prince's whole route. A about 37.6; C with the landmark route about 64.7 (1.72x, out of band); with
  `route_spots` about 47.2 (1.26x). The blessing leg (`STEPS_LEG` 1) and the dock leg (`DOCK_LEG` 3) keep their indices.
- Code: section 5 item 8.
- Policy: `feast --path=procession --board` (reads `ProcessionDirector.DOCK_LEG`: a count, unchanged).
- Risks: *no luck*: the Prince's party passes the harbour gatehouse; check that the escort is not held by the gate's queue
  (`gate_interval` applies to queued evacuees). *Chain*: `SHIP_AT` 120 and `TIDE_AT` 150 assume the walk; with parity they hold.
  *Clarity*: the Capital has no ship decor (`ship_at()` is INF): the ship docks with nothing drawn. New art is out of scope.

#### 6.3.2 The Bishop (`bishop`, BishopDirector extends AssassinateDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `refuge_spots` (his house, the chapter house; the Temple is third) | (12.0,-6.8) (7.9,-12.3) | (12.4,-12.5) (6.5,-18.0) |
| `safe_at` / the start | Citadel gate | `Places.point(&"citadel_gate")` |
| `camera_at` | (1.0, -2.5) | (4.0, -14.0) |

- Key walks: his house to the chapter house to the Temple door. A 6.9 / 10.1; C 7.8 / 11.0 (1.13x / 1.09x).
- Code: section 5 item 4; AssassinateDirector vars seeded in `_init()`.
- Policy: `bishop`.
- Risks: *spread*: Knights `POST_GAP` 1.8 (unchanged). *No luck*: the chapter house by the civic square is on the south road;
  the Doom on a Knight alone waits on traffic.

#### 6.3.3 The Armoury (`armoury`, ArmouryDirector extends RazeDirector)

| Item | Aldermere | Capital |
|---|---|---|
| North barracks | `taverns()[0]` (-9.6,-7.6) | `taverns()[0]` (-21.8,-7.7), the west market tavern |
| Gate barracks | `gate_towers()[1]` (Main Gate east) | the west river gate's east tower (section 3) |
| Armoury | `Places.rect(&"barracks")` | the Keep's barracks (-7.8,-28.2) |
| Citadel gate | const | `Places.point(&"citadel_gate")` |
| `words` (copy) | north barracks, gate barracks, armoury | west barracks, gate barracks, armoury |
| `camera_at` | (-5.5, -4.5) | (-16.0, -6.0) |

- Key distances between targets: A tavern to gate tower about 21, gate to barracks about 13; C about 13.5 and 32.
- Code: section 5 items 1 and 4; `words` town var.
- Policy: `armoury`.
- Risks: *chain*: the armoury in the Keep is 32 from the gate tower; the garrison's reinforcements (`REINFORCE`) run from the
  barracks, so the third stage's reinforcements arrive later than Aldermere's. Measure; if play misses, the first knob is
  `STAGE_AT[2]` (each stage within the previous plus `CHAIN` 40). Note `taverns()[1]` is listed as the first target's fallback;
  in the Capital it is the market tavern (-1.0, -7.6), fine.

#### 6.3.4 The Sermon (`sermon`, SermonDirector extends MirasHouseDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `pulpit_well` | 2 (-9.1, 13.5) | 3 (9.0, 0.6), the old town houses' well |
| `house_spot` (the god's house) | (-14.0, 10.4) | (13.0, -2.5) |
| `sources` (listener waves) | (-11,3) (-2,12) (-12,6) | (0.0,-5.0) (14.0,-5.5) (2.0,-1.0) |
| `camera_at` | (-13.5, 9.0) | (11.0, -1.0) |

- Key walks: pulpit to the god's house: A 6.1, C 5.2 (0.85x). Each source to the pulpit: A 11.6 / 7.1 / 8.1; C 10.8 / 7.9 / 7.5.
  The Faithful's report run, the god's house to the Temple door: A about 18; C about 20.
- Code: section 5 item 9; policy `_sermon_act` reads `Places.at(&"bell_tower")` (item 13).
- Policy: `sermon`; toll `sermon_toll`.
- Risks: *no luck*: the cross avenue (y = -9) is 9 north; the well sits near the east river gate's plaza (4, 4), which queues
  people; keep the house and pulpit east of x = 8.

#### 6.3.5 The Relic Run (`relic_run`, RelicRunDirector extends VigilFlameDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `route` (the cart; halts on legs 0 and 2) | (9.5,-5.1) (9.5,9.0) (-6.0,9.0) (-6.0,-5.1) (-10.5,-5.1) (-10.5,-7.6) | (14.0,1.5) (14.0,-9.0) (-2.0,-9.0) (-2.0,-13.0) (4.0,-13.0) (0.0,-22.6) |
| `check_words` (copy) | the east watch-house, the west watch-house | the harbour watch-house, the plaza watch-house |
| `drop_spot` | (12.5, -12.0) | (16.0, -14.0) |
| `pip_spot` | (6.0, 2.5) | (10.0, 0.0) |
| `cart_camera` | (4.0, -3.0) | (8.0, -6.0) |

- Key walk: the cart's route. A about 50.7; C about 46.9 (0.92x). Pip's walk to the first halt: A about 8.7; C about 9.8.
- Code: town vars (its own and VigilFlameDirector's it reads); policy `_relic_act` bell tower read (item 13).
- Policy: `relic`; toll `relic_toll`.
- Risks: *no luck*: the second halt (end of leg 2) is at (-2, -13), by the pilgrim plaza, the old town's busiest corner after the
  market. If idle exceeds 45 s, move leg 2's end east to (2.0, -9.0) and re-measure. *Clarity*: the cart's arrow when it is under
  the cathedral's sprite.

### 6.4 Tier 5

#### 6.4.1 Last Judgement (`last_judgement`, LastJudgementDirector)

- No Aldermere coordinates in the director: it tags the Citadel (`citadel_origin()`), the town's exits, the rite and the boats.
  The Capital has all of them.
- Overrides: def `brief` ("The Capital and its Royal Keep.", "Bring the whole kingdom down."), `intro_from` (16.4, -9.0) (the
  harbour gate); `camera_at` stays unset (the active city's Citadel).
- Code: policy only (item 13: `JUDGEMENT_TARGETS` per-city table; `_richest` starts from `City.current().citadel_origin()`).
- Policy: `judgement --board`.
- **Design risk (may need a redesign).** City Stability is counted over the whole town. The Capital has about 600 people and
  about three times Aldermere's buildings, with the same DP, slots, clock and `Rules.ESCAPE_LIMIT` (both in copy, so not
  overridable, D17). Aldermere's greedy policy needed 4 to 4.5 of its 5 minutes. The task measures first (`judgement` play,
  seeds 1-3). If it wins fewer than 2 of 3, it stops and asks the user (section 9 question 2). It does not tune by itself.

#### 6.4.2 The Long Night (`long_night`, four acts)

| Act | Director | Capital |
|---|---|---|
| Root def | | `camera_at` = west gate inside.lerp(bell tower, 0.35), about (-17.4, -15.5); `intro_from` = west gate + (6, 0) |
| omen | WarningDirector | `gate_spot` (-22.4, -13.0), the west gate inside; act `brief` "A star falls over the west gate."; act camera as the root's |
| festival | FestivalDirector | act `camera_at` (-7.5, -2.5), `intro_from` (-7.5, 5.5) |
| procession | ProcessionDirector | act `camera_at`/`intro_from` as 6.3.1; director `route_spots` as 6.3.1 |
| judgement | JudgementDirector | act `intro_from` (16.4, -9.0); `camera_at` the Citadel |

- Key walks: the Omen's watchman to the bell's foot: A 13.7, C about 15.1 (1.10x). The others as 6.2.2, 6.3.1.
- Code: section 5 items 11 and 12; policy `_night` and `_play_judgement` (item 13). Depends on the Festival, Procession and Last
  Judgement tasks.
- Policy: `night --board` (`--path=festival|procession`, `--act1/2/3=play`); route b `night --route=b --board`.
- Risks: as each act's mission; Act III carries Last Judgement's design risk. *Bell never loses*: the Omen is a Herald night
  (unchanged).

#### 6.4.3 The Lantern's Eye (`lantern_eye`, LanternEyeDirector extends HuntDirector)

| Item | Aldermere | Capital |
|---|---|---|
| Spire | `SPIRE` (0.8, -8.7) | `Places.at(&"temple")` (-3.9, -17.7) |
| `tower_points` (mirror towers, nearest wall tower) | (0,-15.65) (15.65,0) (-8,15.65) | (-11.0,-30.0) (18.0,-21.0) (-11.0,4.0) |
| `tower_words` (copy) | the north tower, the east tower, the south-west tower | the north tower, the east tower, the south tower |
| `camera_at` | (0.0, -6.0) | (-4.0, -14.0) |

- Key distances, spire to each tower: A 7.0 / 17.3 / 26.1; C 14.2 / 22.1 / 22.8. All within `Searchlight.FAR` 26.
- Code: section 5 items 2 and 10.
- Policy: `eye --board`.
- Risks: *no luck*: the policy never casts within a lit pool; the beams sweep a bigger area at the same speed, so the town is lit
  less often per cell, which helps the player; check the mirror order still reads near to far. *Spread*: party posts
  `POST_GAP` 2.4 (unchanged). The south tower faces the river gates' plazas; its wrights' quiet side (`QUIET_SIDE[2]`) must be
  inside the wall.

#### 6.4.4 Exodus (`exodus`, ExodusDirector extends EscortDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `house_points` | (-10.5,7.0) (7.5,4.5) (7.7,13.8) | (-16.0,-18.0) (12.0,-4.0) (6.0,-1.5) |
| `house_words`, `house_names` (copy) | west, east, south households | unchanged words (west, east, south) |
| `gate_mouths` | postern, Side Gate, Main Gate | west gate (-22.4,-13.0), harbour gate (16.4,-9.0), east river gate (4.0,2.4) |
| `gate_exits` | | (-25.6,-13.0), (19.6,-9.0), (4.0,5.6) |
| `gate_labels`, `gate_words` (copy) | POSTERN, SIDE GATE, MAIN GATE | WEST GATE, HARBOUR GATE, BRIDGE GATE |
| `gate_along` | RIGHT, DOWN, RIGHT | DOWN, DOWN, RIGHT |
| `beat_spots` | [(-6.25,0),(-6.25,12)] [(1,9),(12,9)] | [(-12.0,-20.0),(-12.0,-10.0)] [(2.0,-6.0),(12.0,-6.0)] |
| `temple_door_at` | (0.8, -5.0) | (-3.9, -14.0) |
| `camera_at` | (-7.0, 9.0) | (-4.0, -8.0) |

- Key walks: each household to its nearest gate. A 9.0 / 8.2 / 5.0; C 8.1 / 6.7 / 4.4 (0.90x / 0.82x / 0.88x).
- Code: section 5 item 3; EscortDirector vars seeded in `_init()`; policy reads (item 13).
- Policy: `exodus --board`.
- Risks: *no luck*: the bridge gate's exit lies on the east stone bridge's approach, where the gatehouse queues evacuees one a
  second; a believer must not be held by that queue. The test asserts a believer at the mouth reaches `exit_at` without
  queueing (or the third gate moves to the harbour side). *Hidden losses*: `SHUT_AT` 150/225/300 with `SHUT_WARN` 60 are in copy;
  unchanged.

#### 6.4.5 The Heart of Faith (`heart_of_faith`, HeartOfFaithDirector extends RazeDirector)

| Item | Aldermere | Capital |
|---|---|---|
| `oil_at` (the oil-house is the dwelling nearest) | (-2.5, -12.5) | (-11.0, -20.0), patrician row |
| `steps_at` (the Temple steps, the altar) | (0.8, -5.0) | (-3.9, -14.0) |
| `lane_foot` (Odran's litter route) | (-10.5, -5.1) | (2.0, -13.0) |
| `quiet_at` (Knights' quiet faces) | (-3.5,-14.0) (2.0,-14.0) | (-7.0,-19.0) (-7.0,-16.4) |
| Citadel gate | const | `Places.point(&"citadel_gate")` |
| `camera_at` | (-6.0, -4.0) | (-6.0, -16.0) |

- Key walks: the oil-house to the steps: A 8.2, C 9.3. Odran's route, Citadel gate to lane foot to steps: A 13.8; C 15.8 (1.14x).
- Code: section 5 item 4; `words` town var if the policy reads it.
- Policy: `heart --board`.
- Risks: *spread*: `quiet_at` points 2.6 apart; each Knight post more than 1.6 apart (`POST_APART` 2.1). *No luck*: the cathedral
  front is the pilgrim plaza; a seen Doom raises the Gaze; the policy already caps it (`HEART_GAZE_CAP`). *Hidden losses*: Odran's
  death is the win, seen or not (unchanged).

## 7. Out of scope

- Tuning by play test (the numbers the gates do not force). The World Map spec 4.6 puts it in the play test step.
- New art, new sounds, new keys. The missing ship at the Capital's dock stays missing.
- Moving any Capital building. The only `CapitalCity` change is `gate_towers()`.
- The Lantern Hunts, the rites and the Awaken in the Capital (the Hunt stays Aldermere's).
- The campaign (always Aldermere), and the board's Feast nights.
- Wishes that need a place the Capital lacks (already not offered there).

## 8. Tests

Per mission, `tests/test_capital_<scenario>.gd`, added to `SUITES` in `tests/run_all.gd`, built on a shared helper
`tests/capital_kit.gd` (factored from `tests/test_capital_lamb.gd`):

- `_overrides_valid`: `Overrides.apply()` on a fresh def and director returns no bad keys; every key is in the director's
  `TOWN_VARS`; every value's type matches the seeded var.
- `_hostable`: `MissionBook.hostable("<id>", City.by_id(&"capital"))`; `MissionBook.town_missions(&"capital").has("<id>@capital")`;
  `GodNight.can_host("capital", "<id>")`.
- `_starts`: `GodNight.def_for(slot, "<id>", "capital")` builds a def with `city == &"capital"`; a Kit world in the Capital runs the
  director's `setup()` with no error and every overridden value still set after setup.
- `_walk_parity`: each key walk of section 6, path length on a built Capital and a built Aldermere, printed, in the band.
- `_spots_land`: every overridden spot snaps within 0.6; house spots resolve to distinct dwellings; the mission's own people more
  than 1.6 apart; no spot outside `INNER` unless section 6 names it.
- `_camera_clear`: the first target's tag at the intro camera outside the padded HUD stack.
- `_words_true`: the tour and tags name the Capital's words (`post_names`, `gate_words`, ...), never an Aldermere place name.
- Gates (`tools/dev/gate.sh <scenario> --city=capital`, route a and b, `--with-none`, `--case=toll` where the mission has a Lantern):
  play wins at least 2 of 3; none loses 3 of 3; idle at most 45 s; no designed wait over 60 s.
- References: `tools/dev/refs/capital_<scenario>.tsv` (none, play, b_play, toll rows, seeds 1-3, `how` ending `--city=capital`);
  `refs_check.sh --only='^(capital_<scenario>|<scenario>)_'` OK, so Aldermere's rows of that mission are unmoved.

Groundwork tests: `tests/test_mission_needs.gd` (the Capital now has two gate towers); `tests/test_capital_gate_towers.gd` (the two
rects are standing tower structures of the west river gate, west first); `tests/test_town_vars_t2_5.gd` (every new town var equals
its const on a fresh director; source scan: no listed const read outside `const`/`var`/`_init` lines; the Aldermere lookups that
replace consts are bit-equal: citadel gate, Temple centre, map centre equals town centre).

`tests/test_capital_god_night.gd::_draw_none` assumes a tier the Capital hosts nothing of. Once Tier 5 is done no such tier exists:
the last task replaces it with `_draw_every_tier` (each tier 1-5 draws a Capital night) and keeps the empty-draw path through
`_hunt_aldermere_only`.

## 9. Decisions (the user, 2026-11-22: "go with your picks")

1. The Crown's Bread in the Capital: the market hall is the granary and the bakery is the mill (section 6.2.3). Both are in the
   old town.
2. Last Judgement and the Long Night's Act III: the task measures first. If the scripted play cannot break the whole Capital in
   time (fewer than 2 wins of 3), City Stability in the Capital counts the old town only. Aldermere's rule does not change.
3. The gate towers are the old town's west river gate (section 3).
4. The Procession's ship: the Capital gets a `ship_at()` value at its harbour dock and draws the existing ship sprite. No new art.

## 10. Order of work

1. Groundwork: gate towers, the shared test helper, the needs test flip.
2. Tier 2 (five missions, any order), then the Tier 2 close (gates re-run together, references checked, FLOW alone). Tier 2 is
   usable in the Capital.
3. Tier 3: Vigil Flame, Festival, Crown's Bread, Prisoner, Heretic Hunt; close.
4. Tier 4: Procession, Bishop, Armoury, Sermon, Relic Run; close.
5. Tier 5: Last Judgement, Lantern's Eye, Exodus, Heart of Faith, then the Long Night (it needs the Festival, Procession and Last
   Judgement tasks); close, with the god night test rewrite.

Missions of one tier share no file except `tests/run_all.gd` (one line each) and the policy files (each mission edits only its own
functions), so they can run in parallel worktrees off the tier's base.
