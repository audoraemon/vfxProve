# PixelLab people — design

**Branch:** `feat/pixellab-structures`, after the structures proof (`docs/PixelLab_Structures_Proof.md`).

**Goal:** draw every citizen and soldier from PixelLab character sprites, with every animation state the procedural people have, and a look for every citizen role, without changing how the crowd behaves.

## Decisions (with the user, 2026-10-03)

| Topic | Decision |
|---|---|
| Size | **Native, as now.** Citizens about 15 px tall and soldiers about 19 px, on a small canvas, in proportion to the buildings |
| Directions | **4 diagonals:** front-right (south-east), front-left (south-west), back-right (north-east), back-left (north-west) |
| Variety | **2 looks for the big roles:** resident, merchant, craftsman and caregiver. One for the others. 17 designs |
| Animations | **Today's states only:** idle, walk, run, stumble, death. The engine keeps every effect on top |
| Order | **Pilot first:** 1 citizen and 1 soldier with a 4-direction walk, judged in-game at native size before the rest |

## 1. Designs

| Who | Role (code) | Looks | Outfit (today's colours where the game relies on them) |
|---|---|---|---|
| Citizen | RESIDENT | 2 | plain tunic, a man and a woman |
| | MERCHANT | 2 | apron and coin purse; a man and a woman |
| | CRAFT | 2 | leather work apron, tools at the belt |
| | LABORER | 1 | rough tunic, rolled sleeves, a sack on the shoulder |
| | CLERGY | 1 | cream robe to the ground, gold stole |
| | CAREGIVER | 2 | long dress and white apron, a headscarf |
| | FARMER | 1 | straw hat, smock, a pitchfork |
| | BELLKEEPER | 1 | navy coat, brass badge |
| | ENGINEER | 1 | leather apron, tan cap, a hammer |
| Soldier | NONE (guard) | 1 | mail, royal blue tabard, helmet, spear, blue shield |
| | MARSHAL | 1 | as the guard, red tabard |
| | ESCORT | 1 | as the guard, white tabard |
| | RESCUE | 1 | as the guard, a shovel instead of the spear |

The 2-look roles pick a look from the person's seed. Picking it must not draw from the person's random stream.

## 2. Animations

Each design has these in 4 diagonal directions. The frame counts are the templates', settled by the pilot.

| State | PixelLab template | When it plays |
|---|---|---|
| idle | `breathing-idle` | standing: waiting in a queue, posted, observing, inside a stay |
| walk | a walking template | moving at a walk: calm, recovering, confused, assisting |
| run | a running template | panic, flight, rally, a hurrying soldier |
| stumble | `crouching` | a stumble: down on one knee |
| death | `falling-back-death` | killed. Plays once, then holds its last frame as the corpse |

Unchanged in the engine, now on the sprite:
- **Deaths by type** draw the body under their transform:
  - thrown: the body tumbles, holding the death animation's mid frame;
  - gravity: stretched toward the core;
  - laser: the sprite split at the waist, the top sliding off the legs;
  - fire: charred and sinking;
  - ice: a frozen frame, then shards.
- **Effects on the living:** freeze shell and ice tint, lift and tumble, knockback and pull, sick tint and cough mote, Discord's swirl.
- **Light and colour:** the hit flash, the light on units, ambient dim and death fade.

## 3. Engine

- **`PeopleArt`** (new, static): reads `assets/pixellab/people/manifest.json`, which maps each design to its frames in **one shared atlas texture**. Each design × state × direction maps to a frame list and an fps. It also chooses a person's design from its role, corps and seed.
- **One shared people shader material:**
  - each draw's colour carries a target colour and a mix amount (char, ice, flash, sick);
  - the node's modulate keeps carrying the light and the fade.
  - One atlas plus one material keeps every person in the same draw batch.
- **`Person._draw_body()`** draws the frame for its design, state, direction and time when people sprites are on. Otherwise it draws today's procedural body.
- **Facing:** `_facing` stays (left/right). A new back/front flag comes from screen-y movement. Together they pick the diagonal.
- **Box:** `SPRITE_BOX` grows to the sprite's bounds, for culling and sort.
- **Toggles:** F7 (`ArtToggle`) and `-- --art=procedural` switch the people too.
- **Tools:** `tools/dev/pixellab_api.py` gains character creation, animation and export. A new `tools/dev/make_people_atlas.py` packs the frames.

## 4. Proof criteria

1. **Behaviour unchanged.** A test runs the same crowd scenario with people sprites on and off and compares positions, minds, states and random streams. The existing crowd and plague tests stay green.
2. **Look.** Captures of a calm crowd, a panic, a gate queue, soldiers rallying, deaths of each type, and a freeze, sprites against procedural.
3. **Speed.** Mission bench within 5 fps of the procedural people, with draw calls not up by more than ~10.

## 5. Cost

- **Pilot:** about 10–20 generations.
- **Full set:** creation about 17–150 generations (standard or v3 mode, chosen after the pilot), plus 17 × 5 × 4 = 340 for the animations.
- **Total:** about 400–500 of the 1322 left.
