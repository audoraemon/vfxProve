# KAK -- Veil twists, second round (Dread, The Swallowing Dark, Evernight)

Short design (a small change: three level-5 twists replaced). Builds on `god/veil-levels` 850e22de and its spec
`docs/superpowers/specs/2026-11-24-kak-veil-ability-levels-design.md`; everything there holds except the three twists below.

## Intent

The user, after reading the level-5 twists (2026-11-26): Dread's twist "is too much like Slumber's twist", and the Tier 5
twists "don't feel different from the ability". A twist must add a new kind of effect, not more of what the power already does.
The user's asks: Dread eats whoever comes in, gone forever; The Swallowing Dark leaves something behind that hurts people,
not the whole circle but many random circles "like a moon surface"; Evernight: the user picked **The False Light** from eight
proposals.

Goals: three twists that each read as their own new thing on screen. Non-goals: no change at levels 1-4, no number in the
level tables changes, the Pale Eye and the shared hooks stay. Anti-goals: a twist that needs luck to work (the craters'
placement is seeded, never random per run); a twist that breaks a mission (the power's sparing holds in all three).

## Approaches

- **A (picked by the user):** new branch `god/veil-twists-2` cut from `god/veil-levels` 850e22de; the three old twists are
  removed and the new ones take their place, reusing the Pale Eye, `Crowd.take` and `Person.hurt()`.
- B: A plus a switch keeping the old twists -- twice the code and tests for twists the user said feel wrong.
- C: commit onto `god/veil-levels` -- the branch the user is testing would change under them.

## Dread of the Dark -- "The Dark Takes Who Looks" (replaces The Dark Looks Back)

The user picked "pull in the ones who stop at the edge" over "the edge stops blocking".

- The edge still blocks, as at levels 1-4. Whoever it stops (`_step_blocked`), or who stands within `EDGE_NEAR` 1.0 of the
  dreaded ground for `EDGE_STAND` 2 s, is eyed, then **pulled into the dark and taken**: no body, gone for good (the town's
  take, as The Swallowing Dark's; never counted as a death anyone saw).
- The pull is a short slide toward the dread's middle (about 0.6 s) while he fades; then the take.
- `EDGE_MOST` 16 a cast stays (cost), nearest the click first.
- The god's believers and whom the mission keeps alive are eyed and never taken (as VL68). A held or on-duty soldier is taken
  like anyone (he is not turned, he is eaten; my call -- the duty rule was about Cloak re-posting him).

## The Swallowing Dark -- "The Moon's Face" (replaces Nothing Leaves)

The user picked "hurt over time" over "one step kills".

- At the fold, after the take, the emptied ground is left pitted with **craters**: dark round pits, rims of slumped earth,
  a faint swirl at the bottom, like the face of the moon. Not the whole circle: they cover about a third of it.
- Count and size (mine, first guesses): 9 craters at the light size, 15 at the dark size; each radius 0.8 to 2.2. Placed by a
  seed from the cast's origin (same click, same craters), never overlapping one another, the spared gates, bridges, postern,
  dock, fountain, or a building the mission needs.
- Whoever stands in a crater is hurt `CRATER_HURT` 0.25 health a second (a citizen, health 1.0, dies in 4 s; a soldier,
  2.0, in 8 s). A quick walk through survives. The hurt is silent: no attacker, no fright, no alarm (`hurt(amount, null)`).
  Whoever it kills is **taken**, not left as a body (the dark eats him). Each one hurt is eyed while he stands in it.
- The town does not avoid the craters (it does not see the dark).
- They last the rest of the mission.
- Sparing: believers and whom the mission keeps alive are never hurt.
- The old marks and threads are removed.

## Evernight -- "The False Light" (replaces The Light Gives Way)

- At level 5 the torches burn **pale blue** instead of warm. The town does not notice: people huddle round them all night
  and the takes still skip the light, so the huddles grow (the torchlight keeps `TORCH_R` 2.5 all night; the shrinking is
  removed).
- In the last 5 s before the dawn every huddler and bearer is eyed, so the player sees who is about to go.
- **At the dawn each torch flares black and takes its whole huddle**, the bearer too: no bodies, the torch goes out. Then the
  dawn's own rules run as today.
- Sparing: believers and whom the mission keeps alive are never taken.
- If the mission ends before the dawn, nothing flares.

## Checks

As the levels' build: each twist's suite rewritten for the new rule; levels 1-4 inert (the level-1 reference rows do not
move); the whole suite, FLOW alone, the Veil rows; a level-5 bench for Dread, The Swallowing Dark (craters standing) and
Evernight (the flare), bar 1.55 of the base.

## Left to the builder

The pull's slide and fade, the craters' and the black flare's looks within the Veil's palette, sounds (CC0, foley recipes,
never Sonniss; a crater's hurt makes no sound the town hears), the docs' rulings (prefix VT).
