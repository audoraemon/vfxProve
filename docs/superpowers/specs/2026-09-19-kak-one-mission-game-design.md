# Kingdoms Amid Kataclysm (KAK) — One-Mission Game — Design

Date: 2026-09-19
Status: All sections approved in brainstorming; pending review of this written spec.
Source: `docs/HUM_Game_Design_Document_v1.docx` (the GDD; it still calls the game "KWAI" and the file "HUM" — both are
old names for KAK).

## Goal

Turn the approved VFX sandbox into a short, replayable game slice of the GDD's prototype (GDD §28): the player is an
ancient god who manifests for 4:00 over one walled medieval town, drafts 4 of the 11 approved powers, and must destroy the
Royal Citadel and collapse City Stability before the manifestation ends, while stopping too many citizens from escaping.

**Success test (GDD §29):** players want to replay the same town because they believe a better sequence of powers would
destroy it faster or with less Divine Power.

## Scope

In: one town map; title, prepare/draft, mission, results and pause screens; Divine Power, cooldowns, manifestation timer;
City Stability; citizens that panic and flee; soldiers that guard and rally; a fortified Citadel that crumbles part by part;
win/lose; score, rank and saved best score; the 11 approved powers unchanged.

Out (later, only once the slice is fun): world map, progression and upgrades, civilization ages, building materials,
elemental combos and statuses, enemy heroes, defenses that fight back, repair crews, more maps, persistent scorch marks
beyond what effects already leave (rubble and ruined buildings already persist).

## Decisions (from brainstorming)

| Topic | Decision |
|---|---|
| Size | One-mission slice of the GDD prototype |
| Power pool | All 11 approved powers are draftable; pick exactly 4 |
| Escapes | Escaped citizens leave the city (they lower stability) but give no score or DP; 35% escaping fails the mission |
| City art | Procedural, in the current pixel-box building and pixel-people style |
| Defenders | Soldiers guard and rally but cannot hurt the god |
| Code approach | New game scene in `src/game/`, reusing all effects and systems; the sandbox stays as the VFX tool |
| Title | Kingdoms Amid Kataclysm, short KAK |
| Citadel | Fortified (at most 25% health lost per second) and shown by parts collapsing, not a health bar |
| Icons | PixelLab-painted scene icons in the style of the user's Cinderfall icon concept (done, committed) |
| Font | Pixelify Sans (SIL OFL 1.1), in `assets/fonts/` (done, committed) |

## 1. Flow, screens and controls

Flow: **Title → Prepare → Mission → Results**, with **Pause** over the mission.

| Screen | Content | Leads to |
|---|---|---|
| Title | "KINGDOMS AMID KATACLYSM" with "KAK" small, over the town slowly panning | Play → Prepare; VFX Sandbox → the existing sandbox scene; Quit |
| Prepare | Briefing (target, objectives, city facts, DP rules) and the draft of 11 power cards; pick exactly 4 in order (slots 1–4); last loadout is preselected | Manifest (enabled at 4/4) → Mission |
| Mission | 2 s intro: camera sweeps to the Citadel, "MANIFEST" banner; then the 4:00 timer runs | Win or lose → Results; Esc → Pause |
| Pause | Game frozen; Resume, Restart, Change powers, Title | as named |
| Results | Victory or defeat title, stats with points per line, score, rank S–D, "NEW BEST!" | Replay (same 4) → Mission; Change powers → Prepare; Title |

Controls:

| Action | Input |
|---|---|
| Pan camera | WASD or arrow keys; hold middle mouse and drag |
| Zoom | Mouse wheel, from the whole town to close-up |
| Pick a power | Keys 1–4 or click its slot |
| Cast a point power | Left-click the ground |
| Cast a line power (Tsunami Breaker, Heaven Splitter, Walking Laser Grid) | Hold left button at the start point, drag to aim, release |
| Cancel aiming | Right-click or Esc |
| Pause | Esc when not aiming |

Casting rules:

- While a power is picked, its **area shows on the ground** under the mouse, drawn from the effect's own area constants:
  circle (most powers), lane (line powers), cone facing down-right on screen (Dragonfire Parade, whose dragon is locked
  to that facing), the formation point and suction ring (Tornado Tempest).
- A slot is **greyed out** while on cooldown (seconds left shown) or when DP is short (cost shown red). Trying to cast
  it plays a buzz and flashes the slot red.
- **Several powers can run at once.**
- **The camera stays the player's**: no automatic zooms or follows during the mission (the sandbox's per-effect camera
  moves are not used); impacts still shake and flash the screen.

## 2. The town map ("Aldermere", placeholder name)

One walled medieval town with land around it, about 28×28 ground units. Coordinates below are ground units with the
origin at the town centre, plan north = −y (in the isometric view the Citadel sits upper right, the south gate lower left).
Layout per the approved top-down mockup; sizes are approximate and may shift by a unit when built.

| Landmark | Approx. area (x, y) | Notes |
|---|---|---|
| Map | x −12..16, y −12..16 | forest west/north/east edges, river and farms south |
| Town walls | square −9..9 (0.6 thick) | 4 corner towers (1.5×1.5) and 2 towers on the east wall at y ≈ −5 and ≈ +4.6 |
| Main Gate | x −1.4..1.4, y 8..9.4 | south wall, on the north–south road |
| Side Gate | x 8..9.4, y −1.3..1.3 | east wall, on the east–west road |
| Royal Citadel | x −2.7..2.7, y −8.2..−3.6 | 9 parts (see §4.5); the objective |
| Temple | x 3.5..6.2, y −7.6..−4.5 | big building |
| Market | x −2.7..2.7, y −2.2..2.4 | ~7 stalls round the crossroads |
| Barracks | x 3.9..8.1, y −2.5..−0.6 | training yard x 3.9..8.1, y 0.7..3.1 |
| Residential | west x −8..−3 (north and south of the road); south x −2.5..8 (y 3.7..6.8) | ~40 houses |
| Roads | N–S x −0.4..0.4 from y −3.5 to the south edge; E–W y −0.4..0.4 from x −8.4 to the east edge | walkable |
| River | y 11.4..13, full width | impassable except the bridge |
| Bridge | x −1..1, y 11..13.4 | destructible; its fall closes the south route |
| Farms | y 13.6..15.6: west x −10.5..−2, east x 2.5..14.5 | low destructible fields and two barns |
| Exits | south: the road at the map's south edge; east: the forest road at the map's east edge | reaching one = escaped |

Evacuation routes: south (Main Gate → road → Bridge → south exit) and east (Side Gate → forest road → east exit).
Destroying the Bridge closes the south route. Rubble of destroyed buildings stays and is walkable.

## 3. People

About **110 citizens** and **50 soldiers** (160 total), small procedural pixel people in the style of today's units.
Every power already kills, knocks back, pulls, freezes, lifts and sweeps them.

Citizens:

| State | Behaviour |
|---|---|
| Calm | Wander their district; walk between home and the market |
| Panic | Triggered when a power is cast within ~7 units, a building is destroyed within ~4 units, or by the town alarm |
| Flee | Shortest path to the nearest open exit; they queue at gates |
| Escaped | Removed from the town; counts toward the escape limit |

Soldiers never flee and cannot hurt the god. Starting posts: 20 drilling in the barracks yard, 12 on wall towers and
gates, 10 guarding the Citadel, 8 patrolling the streets in pairs. When the alarm reaches 25% or the Citadel is first
hit, **all soldiers rally** to ring the Citadel. After the Citadel falls they hold their ground in its rubble.

Numbers (starting values, tuned in playtests):

- Escape limit: 35% of citizens (38) escaped = mission failed.
- Alarm (0–100%): +2 per building destroyed, +0.5 per person killed, +10 on the first hit on the Citadel. At 25% the
  soldiers rally; at 50% every citizen flees.
- Gates let about one person through every 0.6 s, so crowds pile up in front of them. A destroyed gate becomes rubble
  and stops being a bottleneck.
- Pathing: a grid path around standing buildings (rubble walkable); re-planned when a route closes (the Bridge falls) or
  the path is blocked.
- Fleeing speed about 1.2 units/s.

Measured cost: 160 people vs today's 40 cost about 3–4 ms per frame (idle 156 → 99 fps; Cinderfall 60 → 50 fps on the
user's PC).

## 4. Rules and numbers

### 4.1 Divine Power (DP)

Max 100, the mission starts full, regeneration +0.5/s. Destroying things that matter gives DP back; ordinary civilian
targets give none.

| Destroyed | DP |
|---|---|
| Soldier | +0.4 each (20 total) |
| Wall tower (6) | +3 each |
| Gate (2) | +5 each |
| Temple | +8 |
| Barracks | +10 |
| Royal Citadel | +15 |
| Chain (one cast destroys 6+ buildings or kills 25+ people) | +6, "CHAIN!" banner |
| Citizens, houses, market, farms, walls | 0 |

A kill or destruction is credited to the cast that caused it: among the casts still running, the one whose power deals
that damage kind; the latest cast wins a tie.

### 4.2 Powers

The GDD's costs and cooldowns are kept; the three the GDD does not give are marked NEW. Areas and damage are the effects'
own, unchanged.

| Power | DP | Cooldown | Aim | Shape |
|---|---|---|---|---|
| Heaven Splitter | 10 | 20 s | drag | line + 8 fissures |
| Tornado Tempest | 15 | 30 s | click | roaming vortex, 10 s |
| Dragonfire Parade | 18 | 35 s | click | cone, faces down-right on screen |
| Tsunami Breaker | 20 | 40 s | drag | moving wall |
| Gravity Distortion | 20 | 45 s | click | pull field |
| Walking Laser Grid (NEW) | 22 | 45 s | drag | moving lane |
| Orbital Strike (NEW) | 22 | 45 s | click | random bombardment |
| Cinderfall Barrage | 25 | 50 s | click | volcano + stone rain |
| Judgement of the Ancients | 30 | 60 s | click | 8 punches + slam |
| Glacial Cataclysm (NEW) | 30 | 60 s | click | burst + freeze + ice |
| Nuclear Nova | 40 | 120 s | click | huge circle |

### 4.3 City Stability

Stability = 30% Population + 25% Infrastructure + 20% Leadership + 15% Military + 10% Resources. Each part falls
linearly from 1 (untouched) to 0 (broken), so the player never has to hunt the last survivor:

| Part | Broken when |
|---|---|
| Population | 75% of citizens are dead or escaped |
| Infrastructure | 70% (by footprint) of houses, walls, towers, gates, the Bridge and the Temple are destroyed |
| Leadership | the Royal Citadel's health (0 when it falls) |
| Military | soldiers 2/3 (broken at 80% dead) + Barracks 1/3 (broken when destroyed) |
| Resources | 80% of market stalls and farm fields are destroyed |

### 4.4 Win, lose, score

- **Win:** the Royal Citadel is destroyed **and** City Stability reaches 0% before the timer ends.
- **Lose:** the 4:00 manifestation runs out first, **or** 38 citizens escape.
- **Score:** victory +5,000; +25 per second left; +40 per building destroyed; +10 per citizen killed; +25 per soldier
  killed; escaped citizens 0; +300 per chain; +10 per DP left when winning.
- **Rank:** S ≥ 12,000, A ≥ 9,000, B ≥ 6,000, C ≥ 3,000, D below. The best score (and its rank) is saved.

### 4.5 The fortified Royal Citadel

- Hidden health 1,000. It can lose **at most 25% of its health per second** (a rolling one-second budget), so no single
  strike flattens it; other buildings keep falling instantly.
- It is a fortress of **9 real parts**: 4 corner towers, 4 curtain walls, the central keep. Each outer part is worth 10%
  of the health, the keep the last 20%.
- Every time health crosses the next 10% mark, the **standing part nearest to the hit** collapses with the existing
  building collapse (dust, debris, rubble that stays). The keep always falls last.
- Every hit shows even before a part falls: parts shake, crack and scorch. Fires start in the courtyard at 40% and the
  keep's banner falls at 20%.
- At 0% the keep collapses in a big dust cloud: shake, "THE CITADEL FALLS" banner, +15 DP.
- No health bar over it; the objective line reads "Destroy the Royal Citadel — 60% left".

## 5. Screens (all at 640×360, pixel UI)

- **Font:** Pixelify Sans in `assets/fonts/PixelifySans-Variable.ttf` (license beside it), antialiasing off.
- **Icons:** `assets/pixellab/icons/<key>.png` (84×84, cards), `icons/hud/<key>.png` (42×42, HUD), originals in
  `icons/src/`. Keys: heaven, tornado, dragon, tsunami, gravity, laser, orbital, cinder, judgement, glacial, nova. The game
  draws one shared gold frame (bevel, corner studs, a small diamond on top) around every icon.
- **Prepare:** briefing panel on the left; 11 cards (icon, name, DP, cooldown, shape) in a grid on the right; picked cards
  get a gold border and a 1–4 badge; a description bar for the hovered card; the MANIFEST button (shows "loadout n / 4").
- **HUD:** top centre the timer (red and pulsing under 0:30); top left objectives (Citadel as text, stability with a small
  five-colour bar, escaped n / 38); top right city status (citizens, soldiers, buildings down, alarm); centre banners
  (CHAIN!, SOLDIERS RALLY, THE BRIDGE HAS FALLEN, THE CITADEL FALLS); bottom centre the DP bar with +DP popups and the
  4 slots (hotkey, icon, DP cost, cooldown sweep and seconds, greyed when unusable, gold when picked).
- **Results:** title (gold "THE CITY HAS FALLEN", or red "MANIFESTATION ENDED" / "THE PEOPLE ESCAPED"), big rank letter,
  score, "NEW BEST!", stat table with points per line; Replay, Change powers, Title.

## 6. Architecture

New code lives in `src/game/`; the 11 effects and the effect toolkit (`src/fx/`) do not change.

| Unit | Responsibility | Depends on |
|---|---|---|
| Game (`game.gd`, main scene) | Screen flow, save data (`user://kak_save.cfg`: best score, best rank, last loadout) | UI screens, Mission |
| Mission | One run: builds Battlefield and Town, spawns Crowd, runs Rules, owns Targeting and HUD | all below |
| Battlefield (shared) | Ground plane, draw layers, camera, lights, sound, impact/dim, screen flash, `FxContext` | core, fx, audio |
| Town | Aldermere layout, structures with roles, exits, walk grid, river and bridge | Environment |
| Citadel | 9-part fortified compound: damage budget, collapse order, stage visuals | Environment |
| Crowd | Citizens and soldiers: brains, pathfinding (`AStarGrid2D`), gate queues, panic, rally, escapes | Enemies, Town |
| Rules | Power book, DP, cooldowns, timer, alarm, stability, chains, win/lose, score | signals from Environment and Enemies |
| Targeting | Area previews per power, click/drag/cancel input, casting through `FxTimeline.cast` | Rules, fx |
| UI | Title, Prepare, HUD, Results, Pause; theme, icon frame, banners | Rules (read-only) |

Data flow: input → Targeting → Rules (spend DP, start cooldown) → `FxTimeline.cast(effect, ctx, point, extra)` → the
effect kills and destroys through `EnemyField` and `EnvironmentField` → their signals feed Rules (DP recovery, chain
credit, stability, alarm, score) and Crowd (panic) → UI reads Rules.

Changes to existing code:

- **Sandbox:** its world setup (ground plane, layers, camera, lights, sound, impact, flash, `FxContext` wiring) moves into
  the shared Battlefield; the sandbox keeps its effect list, capture and bench tools and looks and works as today.
- **Structures:** new kinds drawn in the current style — Citadel tower/wall/keep parts, Temple, Barracks, market stall,
  gate, bridge, farm field, barn — plus a role tag (for stability, DP and score) and a `destroyed` signal on the field.
- **People:** `EnemyField` bounds come from the map instead of the fixed 13×13 square; citizens and soldiers are new looks
  and brains on the existing unit, so every death, knock, pull, freeze and lift reaction keeps working.
- **Project:** the main scene becomes the game; `play.bat` opens the title screen; the sandbox is reached from its button.

## 7. Testing and performance

- The existing 217 headless checks (`bash tools/test.sh`) keep passing.
- New headless checks: DP regen, costs and recovery; cooldowns; stability parts and total; win and lose; score and
  rank; the Citadel's 25%-per-second budget and nearest-part collapse order with the keep last; citizens reach an exit;
  re-route when the Bridge falls; gate throughput; alarm thresholds.
- Screenshots of scripted missions with the existing capture tool at each milestone; the user playtests with `play.bat`.
- Performance: full town with 160 people must average 50+ fps on the user's PC during the heaviest effect (Cinderfall),
  measured with the bench tool.

## 8. Build order (each step playable and shown to the user)

1. **Battlefield + town:** shared world; the Aldermere map with every building and the fortified Citadel; a debug way
   to cast any power on the town.
2. **People:** citizens and soldiers with panic, fleeing, gate queues, the bridge re-route and the rally.
3. **Rules + HUD:** DP, cooldowns, timer, stability, alarm, win and lose, the in-mission HUD with icons.
4. **Screens:** Title, Prepare/draft, Results with score and rank, Pause, saved best score and loadout.
5. **Polish + balance:** banners, UI sounds (synthesized like the effect audio), numbers tuned from playtests.

## Open items

- Town name "Aldermere" is a placeholder.
- All numbers are starting values to tune in playtests.
