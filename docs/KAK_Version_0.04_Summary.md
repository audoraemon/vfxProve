# Kingdoms Amid Kataclysm (KAK) — Version 0.04 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `feat/vfx-proof`, tag `kak-v0.04`. v0.04 is the living-town release: citizen routines, local awareness, a staged alarm and gate routing.*

## 1. Concept

You are an ancient god who **manifests over one walled medieval town, Aldermere**. You draft 4 of 11 cataclysm powers and, before the manifestation ends, must **destroy the Royal Citadel and collapse City Stability** while keeping too many citizens from escaping.

**Design goal:** players replay the same town because they believe a better sequence of powers would level it faster or with less Divine Power.

## 2. Game flow

**Title → Prepare (draft) → Mission → Results**, with **Pause** over the mission.

| Screen | What it does |
|---|---|
| Title | Game name over a slowly panning town; Play, VFX Sandbox, Quit |
| Prepare | Briefing (target, objectives, city facts, DP rules, Temple note) and the draft: pick exactly 4 of 11 power cards into slots 1–4; the last loadout is preselected |
| Mission | 2 s intro (camera sweeps to the Citadel, "MANIFEST" banner), then the 6:00 clock runs |
| Pause (Esc) | Resume, Restart, Change powers, Title |
| Results | Victory/defeat, stat lines with points, score, rank S–D, "NEW BEST!" (saved) |

## 3. Controls

| Action | Input |
|---|---|
| Pan | WASD / arrows, or middle-mouse drag |
| Zoom | Mouse wheel (0.5–1.6; capped at 0.5 so the pixel art stays crisp) |
| Pick power | Keys 1–4 or click the slot |
| Cast | Click (point powers) or press-drag-release (line/lane powers) |
| Cancel / unfocus / pause | Esc |
| Restart | R |
| FPS meter | F3 (fps, frame ms, slowest frame, draw calls) |
| Behaviour overlay | F4 (citizens' intents, alarm stage and timeline, gate queues, the citizen under the mouse) |

## 4. Rules and resources

- **Divine Power (DP):** a 100-point bar with slow regeneration (0.5 a second). Each power costs DP and has a cooldown.
- **DP from destruction:**
  - towers +3, gates +5, barracks +10;
  - soldiers +0.4 each;
  - the Citadel's fall +15;
  - **chains** (6 buildings or 25 kills from one cast) +6 and a "CHAIN!" banner.
- **The Temple (cathedral):** destroying it restores **70% of the DP bar**, a deliberate refill for when DP runs dry.
- **City Stability:** five parts (Population, Infrastructure, Leadership, Military, Resources), measured from what still stands and lives.
- **Citadel:** fortified, losing at most 25% of its health a second. Its damage shows as parts collapsing, not as a health bar.
- **Losing:** 50 citizens escaping through the gates (76 in v0.03), or the manifestation clock running out.
- **Score:**
  - win bonus 5000;
  - 25 per second left, 40 per building, 10 per citizen, 25 per soldier, 300 per chain, 10 per DP left;
  - ranks S ≥ 19,200, A ≥ 14,400, B ≥ 9,600, C ≥ 4,800, else D.
- **HUD:** clock, objectives, stability bar, status line (citizens, soldiers, destroyed, alarm stage), banners, DP bar, 4 power slots with cooldowns, floating DP gains.

## 5. The 11 powers

| Power | DP | Cooldown | Aim | Effect |
|---|---|---|---|---|
| Heaven Splitter | 10 | 20 s | drag | Line strike with 8 fissures |
| Tornado Tempest | 15 | 30 s | click | 10 s vortex that softly locks onto the nearest building in its ring |
| Dragonfire Parade | 18 | 35 s | click | Cone of dragonfire |
| Tsunami Breaker | 20 | 40 s | drag | Moving wall of water |
| Gravity Distortion | 20 | 45 s | click | Pull field |
| Walking Laser Grid | 22 | 45 s | drag | Moving laser lane |
| Orbital Strike | 22 | 45 s | click | Random bombardment |
| Cinderfall Barrage | 25 | 50 s | click | Volcano and stone rain |
| Judgement of the Ancients | 30 | 60 s | click | 8 punches and a slam |
| Glacial Cataclysm | 30 | 60 s | click | Burst, freeze, ice |
| Nuclear Nova | 40 | 120 s | click | Huge blast circle |

The default loadout is Heaven Splitter, Tsunami Breaker, Cinderfall Barrage and Nuclear Nova. Effects scorch, freeze, crack, burn and collapse buildings, and kill, knock, pull, freeze and lift people.

## 6. The town of Aldermere

- **Layout:** walls with towers, and two gatehouses:
  - Main Gate (south, over the river bridge);
  - Side Gate (east road).
- **Landmarks:**
  - the Royal Citadel (9 parts);
  - the cathedral (the Temple);
  - the barracks and its drill yard;
  - a workshop, a smithy, 3 taverns, and a carpenter's yard;
  - the market square with a fountain, and a second fountain plaza.
- **Density (v0.03):**
  - 81 houses: cottages plus two-storey townhouses, with a south quarter along the wall;
  - 30 tightly packed market stalls, with tables, crates and a cart;
  - 48 street props: carts, benches, crates, barrels, lamp posts;
  - street and yard trees, fenced gardens and shrubs;
  - paved rosettes and cart ruts in the gate plazas.
- **Countryside:**
  - a river with a west branch and waterfall, the bridge, a dock with a ship;
  - farms and fields, a windmill and a watermill;
  - pastures with sheep and cows;
  - a forest ring and rocky outcrops.
- **Look:**
  - a warm evening light;
  - procedural pixel art matched against the reference images with measurement tools;
  - things that move: the fountain water, windmill and watermill, trees in the wind, rippling awnings and bunting, cathedral banners, torch and lamp flicker, chimney smoke and river glints.
- **Sound:** synthesized effects, including collapse sounds (stone, timber, tree), crowd voices and a running-crowd bed. Music intensity follows how far the city has fallen.

## 7. People (v0.04: a living town)

- **220 citizens, each with a role:**
  - Resident 30%, Caregiver 18%, Merchant 15%, Craft Worker 15%, Farmer 10%, Laborer 8%, Clergy 4%;
  - a home, a workplace (stalls, taverns, craft yards, the cathedral, fields and mills, the dock), and leisure spots (plazas, fountains, wells, taverns);
  - farmers live at the farmhouses by their fields; about a tenth of the town works outside the walls.
- **Daily routine:** people go between home, work, leisure and market errands, staying 5–60 s at each. The market fills, workshops have workers, and the fields have farmers.
- **Local awareness:** every cast and collapse is a danger with its own radius, sight and sound reach, and duration.
  - Inside the danger, people run to just beyond its edge (not to a gate), wait, then go back to their day, avoiding the ground that was just hit.
  - Within earshot, people stop and look.
  - Further away, nobody notices.
  - Fright spreads to neighbours after a moment. Walking into a lasting danger (a tornado) also frightens.
- **Staged alarm**, which only ever rises:

  | Stage | Reached when | What happens |
  |---|---|---|
  | Normal | — | Routines as usual |
  | Concern | Any danger | People nearby look or flee locally |
  | Local Emergency | 4 incidents in one district | Two patrol soldiers investigate |
  | City Emergency | Alarm 35, or 2 districts in emergency | Soldiers rally at the Citadel; the market closes; 30% of citizens regroup at home; a clergy member rings the cathedral bell (destroy the cathedral first and no one can) |
  | Evacuation | 15 s after City Emergency, then alarm 75 with the bell or 90 without | Citizens make for the gates |
  | Collapse | The Citadel falls, or stability drops to 25% | Route choices grow erratic |

- **Gate routing:** evacuees score each exit by route length, queue at its gate, and known danger along the way and at the gate. They re-check about 1.5 times a second and switch when another way is at least 25% better. Danger also makes ground costlier to walk, so everyone's paths bend around it.
- **Gates:** the Main Gate and the Side Gate each let one person through every 2 s.
- **100 soldiers:** drill, guard, patrol; investigate local emergencies; rally at the Citadel at City Emergency.
- **Water points:** 2 fountains and 3 wells (the wells are for fire response, planned next).

## 8. Tools and dev features

- **VFX Sandbox scene:** try every power freely.
- **Town debug scene:** captures and scripted tests.
- **Scripted runs:**
  - `--mission-test`, `--crowd-test`, `--flow-test`, `--bench`;
  - `tools/dev/crowd_check.gd` (exact crowd checksum);
  - `state_digest.gd`.
- **Profilers:**
  - `profile_view.gd` (per-category frame cost at any view);
  - `profile_wear.gd` (late-game slowdown after rounds of destruction).
- **Art measurement:** `match_components.py`, `match_interior.py`, `match_density.py`, `match_layout.py`.
- **Tests:** 811 automated checks (`tools/test.sh`).
- **Behaviour scenarios:** `tools/dev/behaviour_check.gd` runs calm, strike, escalate and gates scenarios, each with a deterministic checksum.

## 9. Performance (v0.04: the citizen AI costs nothing measurable against v0.03, in same-hour benches)

- **Idle work:**
  - idle buildings in view stop per-frame work;
  - glows run on the shader clock;
  - calm people update every other frame on screen;
  - off-screen buildings and people are throttled or asleep.
- **Fewer draw calls:**
  - low decor is baked into the ground, and goods standing together are merged into piles;
  - rubble settles and is drawn in 3 batches.
- **Late-game slowdown fixed.** Before, the frame rate fell to ~32 fps after heavy destruction; now it holds ~150 fps once effects end.
- **Measured (idle machine, market view):**
  - ~100+ fps at the start;
  - 64+ fps zoomed fully out.

## 10. Not yet in (later)

**Next (v0.04 P1):**
- fire response: citizens fetch water from fountains and wells to fight fires;
- family groups.

**Then (P2):** shelter in buildings.

**Later:** world map, progression and upgrades, more maps, civilization ages, building materials, elemental combos, enemy heroes and defenses that fight back, repair crews.
