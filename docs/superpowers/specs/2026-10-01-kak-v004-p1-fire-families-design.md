# KAK v0.04 P1 — Fire response and families — design and plan

**Baseline:** `kak-v0.04`. P1 of `docs/superpowers/specs/2026-09-30-kak-v004-citizens-design.md`.

## Decisions (with the user, 2026-10-01)

| Topic | Decision |
|---|---|
| Fire | A burning state with intensity. Fire damages its building and can spread to neighbours; wind and the Tornado spread it faster. |
| Responders | Nearby calm adults, up to 4 per fire: calm or recovering citizens within 10 units, and only before the Evacuation stage. They fetch water from the nearest fountain or well and douse the fire. |
| Families | Households by home. At City Emergency a household regroups at home; when the Evacuation comes, it leaves together once every regrouping member is home, or after 20 s. |

## Fire (FireManager, owned by the crowd)

- **Catching fire:**
  - Burnable kinds: houses, stalls, trees, the barracks and the cathedral.
  - Fire-kind hits set a building burning: `fire`, `cinder`, `nova`, `orbital` and `lightning`.
  - Starting intensity is 0.35, plus the hit's share of the building's health.
  - Hits come through a new `EnvironmentField.structure_hit` signal.
- **Burning** (stepped at 4 Hz):
  - Intensity grows 0.03 a second, three times as fast with an active tornado within 6 units.
  - The fire deals `6 × intensity` hp a second as `fire` damage; its own damage never re-ignites.
  - Each second, a fire has an `intensity × 0.08` chance to ignite a burnable neighbour within 1.5 units (0.24 in wind).
  - Every 3 s it renews its flames and smoke, and a short `fire` threat, so people near a fire run from it and routes avoid it.
  - A building destroyed by fire ends its fire.
- **Dousing:** a delivered bucket takes 0.15 off the intensity. At 0 the fire is out.
- **Responders:**
  - Once a second, a fire with fewer than 4 responders, intensity under 0.85, and the alarm below Evacuation recruits the nearest calm or recovering citizens within 10 units (Mind.ASSIST, Intent ASSIST).
  - Each responder walks to the nearest standing water point (fountain or well), fills (1 s), walks to the fire's edge, douses (1 s), and repeats.
  - A responder gives up and goes back to its day — or runs, if frightened — when the fire is out or its building has fallen, when the intensity passes 0.85, when the water point is destroyed (it switches to the next nearest if there is one), or when the Evacuation stage begins.

## Families

- **Households:** citizens who share a home (a house, or a farmhouse for farmers) are a household (`CitizenProfile.family`).
- **Regrouping:** at City Emergency, merchants and 30% of households (whole households, chosen by family id) go home and wait (Mind.REGROUP).
- **Leaving together:** at the Evacuation, regrouping households do not bolt one by one. Each leaves together once every member still regrouping is at home, or after 20 s. Everyone else evacuates at once, as before.

## Tasks

1. **Fire state:** the structure hit signal, FireManager (ignite, grow, damage, spread, visuals, threats), and tests.
2. **Responders:** recruitment, the water trip, dousing and abandoning; Intent ASSIST; the overlay; tests; a `fire` scenario in `behaviour_check.gd` (a Dragonfire cast on the west quarter: fires lit, responders, fires out).
3. **Families:** household ids, household regrouping, leaving together; tests.
4. **Gates:**
   - tests, digest, FLOW, crowd_check;
   - bench against `kak-v0.04` (market view and wear, at most a 5-fps loss);
   - commit, and tag `kak-v0.04-p1`.

## Changes made while executing

- **Shared home points:** households share one exact home point. Each member's home had been jittered separately, so a household's members stood at slightly different points.
- **Fire scenario** (three houses lit in the west quarter): 12 responders turned out from the west well, two fires were out by 10 s and the last by 15 s. The alarm stayed at Concern.
- **Checksums:** crowd_check −805209164; fire scenario 282895529.
- **Mission test:** `citizens=192 escaped=2`.
- **Bench, same hour:**

  | | `kak-v0.04` | P1 |
  |---|---|---|
  | Market view | 103.1 fps | 104.5 fps |
  | Wear, start | 83.4 fps | 100.1 fps |
  | Wear, round 1 | 76.1 fps | 77.4 fps |
  | Wear, round 4 | 116.2 fps | 131.3 fps |

- **Tests:** 824 checks.

## P2 — Shelter (added 2026-10-01)

**Decisions (with the user):** sturdy buildings nearby; a collapse kills those inside and heavy damage flushes them out; they stay until the danger clears.

**What was built:** ShelterManager (`src/game/crowd/shelter_manager.gd`).
- **Shelters:** the cathedral, the taverns, the barracks, the workshop and the townhouses. Capacity is 6 people per unit of floor, from 4 to 20.
- **Who takes cover:** a frightened citizen within 5 units, with a chance of 0.8 for severe dangers (tornado, cinder, judgement, nova, orbital, collapse) and 0.3 otherwise.
- **Inside:** people are removed from EnemyField, hidden and not stepped.
- **Coming out:** after 5 s with no danger within 8 units, or at the evacuation (then to the gates).
- **Hit:** under half health, or burning, flushes them out running; destroyed kills them inside (`collapse`).

**Results:**
- **Escalate scenario:** up to 28 people in shelter at once.
- **Mission test:** `citizens=168 escaped=1` (P1: 192, 2); the scripted strikes flatten occupied shelters.
- **crowd_check:** −193622645.
- **Bench, same hour** (vs `kak-v0.04-p1`):

  | | `kak-v0.04-p1` | P2 |
  |---|---|---|
  | Market view | 96.5 fps | 105.6 fps |
  | Wear, start | 102.6 fps | 109.2 fps |
  | Wear, round 1 | 73.2 fps | 95.1 fps |
  | Wear, round 4 | 115.7 fps | 140.2 fps |

- **Tests:** 829 checks.
