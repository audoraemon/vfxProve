# KAK -- Ruin ability levels

Status: **approved by the user** (2026-11-03: "All look good"). Numbers are first guesses, to tune in play.

## Frame (from the god progression spec, §5.4 and §6)

- Five levels per ability. Each level raises 2-3 of the ability's stats, about +10-15% per level.
- Level 5 adds a **twist**: a new behaviour, not a bigger number.
- **Level 1 = today's stats exactly.** So Hunts, routes and references (which play at level 1) do not move.
- Might cost: the base `dp` at levels 1-2, +1 at levels 3-4, +2 at level 5.
- Data: each power's `PowerBook` row gets a `levels` table (index 0 = level 1). The effect reads each number through
  `PowerBook.stat(extra, "<key>", "<STAT>", CONST)`. Level 5 also carries `"twist": true` and `"twist_text"`.

Below, each power has one row per level. **cd** is the cooldown in seconds. Stat names are the effect's own constants.

---

## Tier 1

### Smite (`smite`, 1 Might, `src/fx/ruin/smite.gd`)
Grows: kill radius `KILL_R`, building `DAMAGE`, cooldown.

| Lv | KILL_R | DAMAGE | cd | Might |
|---|---|---|---|---|
| 1 | 0.6 | 45 | 10 | 1 |
| 2 | 0.65 | 50 | 9.5 | 1 |
| 3 | 0.7 | 55 | 9 | 2 |
| 4 | 0.75 | 60 | 8.5 | 2 |
| 5 | 0.8 | 65 | 8 | 3 |

**Twist -- Forked Bolt:** the bolt leaps once to the nearest other person within 2.5 and strikes them too.

### Ember (`ember`, 1 Might, quiet, `src/fx/ruin/ember.gd`)
Grows: the fire's starting strength `START_LEVEL`, reach to a building `REACH`, cooldown.

| Lv | START_LEVEL | REACH | cd | Might |
|---|---|---|---|---|
| 1 | 0.45 | 1.0 | 15 | 1 |
| 2 | 0.5 | 1.0 | 14 | 1 |
| 3 | 0.55 | 1.2 | 13 | 2 |
| 4 | 0.6 | 1.2 | 12 | 2 |
| 5 | 0.65 | 1.4 | 11 | 3 |

**Twist -- Leaping Spark:** once the house has caught, a second spark jumps to the nearest other building within 3.
Still quiet (the spec's own example).

## Tier 2

### Tornado (`tornado`, 3 Might, `src/fx/set2/tornado_tempest.gd`)
Grows: pull radius `PULL_RADIUS`, life `LIFETIME`, cooldown.

| Lv | PULL_RADIUS | LIFETIME | cd | Might |
|---|---|---|---|---|
| 1 | 3.2 | 10 | 45 | 3 |
| 2 | 3.4 | 11 | 45 | 3 |
| 3 | 3.6 | 12 | 42 | 4 |
| 4 | 3.8 | 13 | 40 | 4 |
| 5 | 4.0 | 14 | 38 | 5 |

**Twist -- Twin Funnels:** when it dies it splits into two small twisters (pull 1.8, 4 s) that run apart.

### Scatter Strike (`scatter`, 2 Might, `src/fx/ruin/scatter_strike.gd`)
Grows: bursts `BLASTS`, kill radius `KILL_R`, cooldown.

| Lv | BLASTS | KILL_R | cd | Might |
|---|---|---|---|---|
| 1 | 12 | 0.9 | 30 | 2 |
| 2 | 13 | 0.9 | 29 | 2 |
| 3 | 14 | 1.0 | 28 | 3 |
| 4 | 15 | 1.0 | 27 | 3 |
| 5 | 16 | 1.1 | 25 | 4 |

**Twist -- Seeking Bursts:** each burst moves to the nearest person within 1.5 of its random point. The spread stays wide,
but it finds people.

## Tier 3

### Light of Solaris (`solaris`, 4 Might, `src/fx/solaris/light_of_solaris.gd`)
Grows: pillar radius `RADIUS`, burn time `BEAM_TIME`, cooldown.

| Lv | RADIUS | BEAM_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 2.2 | 5.0 | 105 | 4 |
| 2 | 2.4 | 5.0 | 100 | 4 |
| 3 | 2.6 | 5.5 | 100 | 5 |
| 4 | 2.8 | 6.0 | 95 | 5 |
| 5 | 3.0 | 6.5 | 90 | 6 |

**Twist -- Wandering Sun:** while it burns, the pillar drifts (0.8 units/s) toward the thickest knot of people within 4.

### Dragonfire (`dragon`, 3 Might, `src/fx/set2/dragonfire_parade.gd`)
Grows: breath time `BREATH_TIME`, sweep arc `SWEEP_ARC` (radians), cooldown.

| Lv | BREATH_TIME | SWEEP_ARC | cd | Might |
|---|---|---|---|---|
| 1 | 2.4 | 1.0 | 54 | 3 |
| 2 | 2.6 | 1.0 | 52 | 3 |
| 3 | 2.8 | 1.1 | 50 | 4 |
| 4 | 3.0 | 1.2 | 48 | 4 |
| 5 | 3.2 | 1.3 | 46 | 5 |

**Twist -- Second Breath:** 2 s after the first breath, the dragon breathes again, sweeping back the other way.

## Tier 4

### Tsunami Breaker (`tsunami`, 4 Might, `src/fx/set2/tsunami_breaker.gd`)
Grows: wall length `LENGTH`, travel `WIDTH`, cooldown.

| Lv | LENGTH | WIDTH | cd | Might |
|---|---|---|---|---|
| 1 | 6.5 | 8.0 | 60 | 4 |
| 2 | 7.0 | 8.5 | 58 | 4 |
| 3 | 7.5 | 9.0 | 55 | 5 |
| 4 | 8.0 | 10.0 | 53 | 5 |
| 5 | 8.5 | 11.0 | 50 | 6 |

**Twist -- Backwash:** after the wave breaks, the water draws back over the same ground and drags whoever is still
standing toward where it started.

### Cinderfall (`cinder`, 4 Might, `src/fx/set2/cinderfall_barrage.gd`)
Grows: stones `STONES`, rain radius `RADIUS`, cooldown.

| Lv | STONES | RADIUS | cd | Might |
|---|---|---|---|---|
| 1 | 20 | 5.8 | 75 | 4 |
| 2 | 22 | 5.8 | 72 | 4 |
| 3 | 24 | 6.2 | 70 | 5 |
| 4 | 26 | 6.6 | 66 | 5 |
| 5 | 28 | 7.0 | 62 | 6 |

**Twist -- Lava Pool:** the volcano leaves a lava pool (radius 1.5) that burns for 15 s. It takes whoever walks in and
sets the buildings beside it alight.

## Tier 5 (once a night)

### Wrath of the Sky (`tempest`, 5 Might, `src/fx/ruin/tempest.gd`)
Grows: storm length `STORM_TIME`, bolts per volley `VOLLEY`, time between volleys `VOLLEY_EVERY`.

| Lv | STORM_TIME | VOLLEY | VOLLEY_EVERY | Might |
|---|---|---|---|---|
| 1 | 25 | 5-7 | 1.3 | 5 |
| 2 | 27 | 5-7 | 1.3 | 5 |
| 3 | 29 | 6-8 | 1.3 | 6 |
| 4 | 31 | 6-8 | 1.2 | 6 |
| 5 | 33 | 7-9 | 1.2 | 7 |

**Twist -- Called Bolts:** while the storm lasts, a click drops one sure, hard bolt where you point, once every 3 s.

### Earthshatter (`shatter`, 5 Might, `src/fx/ruin/earthshatter.gd`)
Grows: longest crack `MAX_LENGTH`, fall width `HALF`, crawl `SPEED`.

| Lv | MAX_LENGTH | HALF | SPEED | Might |
|---|---|---|---|---|
| 1 | 18 | 1.1 | 2.0 | 5 |
| 2 | 20 | 1.2 | 2.0 | 5 |
| 3 | 22 | 1.2 | 2.2 | 6 |
| 4 | 24 | 1.3 | 2.2 | 6 |
| 5 | 26 | 1.4 | 2.5 | 7 |

**Twist -- Fault Lines:** the crack forks twice along its way, into two side cracks of 5 units each that stay open too.

---

## Notes for the builder

- The Might cap at Tier 5 is 16, so two level-5 Tier 5 powers (7 + 7) still leave 2 for a third pick.
- Each effect must read every listed stat through `PowerBook.stat()` instead of its constant. A stat used in derived
  constants (for example Solaris's `T_END = T_CHARGE + BEAM_TIME`) must be derived at cast time.
- A twist needs its own code and test. Twists are the costly part; the stat rows are data.
- Hunts and references stay at level 1, so none of them should move. The board's level picker (1-5) tests each level.
