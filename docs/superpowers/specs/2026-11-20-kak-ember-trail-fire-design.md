# KAK Ember: a clearer burning man and a real Fire Trail (2026-11-20)

Source: the user's playtest of Develop-Main a5825501 (2026-11-20): "I barely see the burning effect on people. Also I
don't see any fire trail on the ground. I want to have fire trail drop on the ground while burning people running. Fire
trail damage whoever walking cross it. Fire trail have its own period for like 10-15 seconds." Their answers the same
day: the trail stays Ember's level 5 twist; crossing it hurts, then kills; people do not avoid it. Design approved in
chat. Branch `god/ember-trail`, cut from `origin/feat/Develop-Main` a5825501. It merges into Develop-Main only on the
user's word.

## Why

- The burning man is drawn as five 1-pixel flame lines (`Person._draw_flames`). He does not read as on fire.
- The level 5 trail lays the town's `GroundFire` (40 s, frightens the town, calls fire beaters). People walk round it,
  so no one is ever hurt by it, and its patches read as unrelated fires.

## Burning man, clearer (all levels; draw only)

- Big flickering flame tongues over his whole body, rising to about twice his height at the top.
- A warm glow on the ground under him, a few sparks, and a thin smoke wisp.
- Draw only: no simulation change, so crowd_check and the refs do not move for it.
- Must hold frame rate with many burners (the Burning perf check: 12 burners in the 220 town).

## Trail fire (Ember level 5, "Fire Trail")

A new kind of fire, `TrailFire`, separate from the town's `GroundFire`. It is not hard-coded into Person (the user's
standing rule): a reusable ground hazard any power may lay.

- **Life:** about 12 s (`LIFE`), fading over its last 2 s. It burns out by itself.
- **No fright, no beaters, no spread:** it frightens no one, calls no fire beaters, and never catches buildings. The
  burning man stays the only way Ember's fire reaches a house.
- **Harm:** a person standing on a patch (within its radius, about 0.45, the builder's call) builds heat. A quick step
  across hurts and scorches him (soot, as `GroundFire`'s scorch). About 1.2 s on trail fire in total (`KILL_AFTER`),
  from lingering or crossing twice, kills him as the fire kind (no raisable body). Heat leaves him slowly once he is off
  it (the builder's call). Soldiers and citizens alike; people inside are never touched; the burning man himself is not
  harmed by his own trail.
- **Drawn as:** low flames and embers on a scorched strip, fading at the end.

## Where it is laid

- **Behind the burning man:** one patch each time he has moved `TRAIL_STEP` (0.6, was 1.0) since the last,
  `TRAIL_MOST` (14, was 8) at most; the first where he caught fire. Never inside a building or on water.
- **Round a lit house:** the existing ring (about 0.6 outside the footprint, one patch every `TRAIL_STEP`, on walkable
  dry ground, capped) now lays trail fire instead of `GroundFire` (the controller's call, for one consistent trail).
- Levels 1-4: no trail, unchanged.

## Unchanged

Burning itself (4 s, panic with no shelter, spreading to houses within 0.8, the fright of those who see him, the fire
death), Ember's targeting, the quiet cast, and Smite.

## Checks

- Tests: a patch lives about LIFE and is gone after; it frightens no one and calls no beater; a quick crossing hurts but
  does not kill; KILL_AFTER on it kills as the fire kind; heat cools off it; it never lights a building; the burning man
  is not harmed by his own trail; trail spacing and cap at TRAIL_STEP / TRAIL_MOST; the ring is trail fire; levels 1-4
  lay none. Perf: many patches (e.g. 12 burners x 14) step under budget with no per-frame allocation storm.
- Refs: rows that cast Ember at level 5 (if any) are re-run and re-recorded with reasons. The flames are draw only.
- The full gate, and crowd_check prints `-535548941`.
