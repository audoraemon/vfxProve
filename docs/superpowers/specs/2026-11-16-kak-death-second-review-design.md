# KAK Death powers: second review (2026-11-16)

Source: the user's Discord #ideas post "2nd Review on Death's Abilities" (2026-11-15), plus their answers to four
follow-up questions on 2026-11-16. This amends `docs/superpowers/specs/2026-11-13-kak-death-review-adjustments-design.md`
and the rulings in `docs/KAK_God_Death_Review_Rulings.md` (R1-R27). Where they disagree, this document wins.

Branch: `god/death-review-2`, cut from `origin/feat/god-progression` 8e975fb6. Lands on feat/god-progression, not
Develop-Main.

## Why

The user played the first review's build. Raise and Gate Below still read small. Soldiers hit zombies without a visible
blow. Pale Reign's ghosts look like the wraiths and vanish too soon. The Serpent is "just a serpent flying around". Grave
Tide is far too weak for Tier 5: the user names Heaven's Door, which tears apart everything in a half circle of 16, as
the bar Grave Tide must reach.

## Goals

- Every Death power covers the area its ring shows, and its effect reads at a glance.
- Fights between the living and the undead look like fights.
- Grave Tide is a city-scale cataclysm, at least the equal of Heaven's Door.

## Non-goals

- No change to the tree layout, costs, cooldowns or levels, except where a change below needs a new number.
- No new powers. Death Mark, Pestilence, Grave Call, Corpse Guise and Walking Corpse are not touched, except through the
  shared fight change.

## Anti-goals

- **No frame-rate cliff.** The town holds frame rate with Grave Tide's city-wide horde. The bench (`--bench-cast`) on a
  quiet machine: each changed big power's median `avg_ms` delta is at most **8 ms**. That is a ruling raise from 5 ms for
  the Tier 5 cataclysm only, the builder's call. Pale Reign and Gate Below stay at 5 ms.
- **No luck:** everything picks by rule (nearest, oldest, instance-id order).
- **No hidden losses:** a mission lost to a power's side effect shows why.
- **Silent powers stay silent.**

## Changes, per power

### Shared: fights look like fights (the user's choice: "Both fight")

1. **Soldiers swing.** A soldier who lands a blow on an undead visitor (`Visitors._guard`) plays the swing animation he
   already has (`Person.swing_at(target)`), facing it.
2. **Citizens fight back.** A citizen an undead has cornered fights with bare hands:
   - "cornered": an undead within reach is hunting him, and he cannot get away. The builder defines this by rule.
   - He swings (the same `swing` animation) and lands weaker blows than a soldier (fewer per second, or a fraction of a
     blow).
   - He keeps running whenever he can; fighting back is the last resort, not a new duty.
   - It is a reusable status/intent on the crowd side, not hard-coded per power (the user's standing rule).
3. Each blow on an undead plays the undead's existing flinch.

### Raise the Dead `raise` (Tier 1)

- **Every body in the ring rises**, not only the nearest. ZOMBIE mode raises each body as a zombie. SPIRIT mode raises
  each body that still has its soul as a spirit.
- The ring today is `Remains.PICK_R` (1.0). It grows to a real area: builder's call, about **3.0**. The cap is about
  **8 bodies** a cast, the oldest first (my call; it holds frame rate and keeps Tier 1 below Grave Tide).
- The aim marks every body that will rise; Task 3's `bodies_marked` already covers this.

### The Gate Below `gatebelow` (Tier 4)

1. **Real hands.** The arms read as poles today: a 48x64 sheet drawn at 0.5 scale. Make a new PixelLab sheet: a grasping
   hand and forearm rising from the ground, clawing, then closing and pulling down. Draw it big enough to read as a hand
   at every zoom.
2. **The rift covers the cast area.** Today the rift is `EDGE` 1.8 across inside a `REACH` 6 ring. The dark rift, its
   cracks and the arms fill the whole `REACH` ring: the rift spans most of it, and the arms grab everywhere inside it.
3. **Wraiths scatter and wither.**
   - The wraiths fly out in many directions, evenly spread round the pit. They do not move as one pack.
   - Each hunts the nearest living person in its own sector.
   - A wraith that reaches anyone, citizen or soldier, curses them with a **withering**: a new reusable status. The person
     greys, slows and panics, and dies after a few seconds (builder's call, about 6 s), leaving a body.
   - A wraith touches several people in its life, not only one.
   - It replaces today's touch kill on soldiers only (R9).

### Pale Reign `pale` (Tier 4)

The user's choice: the ghost horde is the "servant" they meant.

1. **A new sprite for the ghosts.** Make a new PixelLab sheet: pale, faceless, gaunt running figures with a trailing
   shroud. They must not be mistaken for the wraith.
2. **The ghosts last the whole reign.** They no longer sink at the 24th kill. They run until `SPAN` ends.
   - `HORDE_KILLS` changes meaning: past it, ghosts still run and frighten, but kill no more. Builder's call; the aim is
     to keep the cap on deaths while keeping the horde on screen.
   - `HORDE_CAP` (24 alive) holds.

### The Pale Serpent `serpent` (Tier 5)

The user's choice: "Death wave ahead".

- A cold fog bank rolls ahead of the head, along its path.
- The ground frosts where it is about to pass.
- The town's lights dim ahead of it.
- People ahead panic before it arrives: a fright cone ahead of the head, by rule.
- The kill lane, the loop and the soul aura are kept.

### Grave Tide `gravetide` (Tier 5)

The user's choice: "City-wide grave burst".

1. **Graves burst across the whole city**, not only where bodies lie.
   - Grave spots are picked by rule over the town's open ground (streets, squares, gardens), spread district by district.
   - Each spot bursts with soil and bone, and undead claw out.
   - The existing bodies still rise as zombies.
2. **A mixed horde, new PixelLab sprites:**
   - **skeleton warriors**: armed, faster, they fight soldiers;
   - **ghouls**: fast, low, leaping at people;
   - the existing zombies.
   - The builder picks the stats per kind and records them.
3. **They storm the streets.** The horde spreads through every district, hunting the living and clawing at buildings
   (the existing `wreck` trait).
4. **The giant wrecks the city.** Its slams knock down buildings in `SLAM_R`: they take wreck damage, so a slam can
   collapse a house. It walks a path through the town rather than standing at the cast point.
5. **Scale bar:** a cast must at least equal Heaven's Door in impact.
   - Heaven's Door pulls in everyone in a half circle of 16 and tears buildings there apart.
   - Grave Tide should, over its life, kill and break at least as much, spread across the whole city rather than one
     half circle.
   - The builder measures both (deaths and buildings destroyed in the 220-person town) and records the numbers.
6. **Caps hold frame rate:** a hard cap on living undead (builder's call, about 60) and the 8 ms bench above.
7. **Always castable; the giant always comes** (the user's answer).
   - No body is needed: the graves burst anyway, so the `any_body` need goes.
   - The giant assembles from a burst grave, chosen by rule: the grave nearest the cast point.
   - Bodies already in town rise as extra zombies on top of the grave horde.
8. **Mission buildings are spared** (the user's answer). The horde and the giant wreck houses, shops, towers and walls.
   Any building a mission needs standing is never damaged: the Citadel, granaries, the temple, hallowed buildings and
   mission goal buildings. A Death night is never lost to a hidden side effect.
9. **Frame rate wins** (the user's answer). If the Heaven's Door bar can't be met inside the cap and the 8 ms bench, the
   caps hold. Impact comes from stronger units (harder-hitting skeletons, slams that flatten more), not more units. The
   measured gap is recorded.
10. **Measuring the bar:** Grave Tide is cast at the market with no bodies in town. Heaven's Door is cast at level 1 at
    the market, aimed the same way the bench aims it. Both are counted over each power's full life in the 220-person
    town: deaths and buildings destroyed, each compared on its own.

## Calls made in writing this up (the controller's, not the user's)

- **Raise's chain stays 3 in total a cast**, however many bodies rise, so Tier 1 can't snowball past Tier 5.
- **A struck undead gets a recoil.** On top of today's 0.1 s white flash, it gets a 2-3 px recoil away from the blow.
  This is draw-only, with no knock-back in the simulation, so the references don't move for it.
- **A citizen's bare hands only hurt solid undead:** zombies, skeleton warriors and ghouls. They cannot hurt spirits,
  wraiths, pale ghosts or the giant. The fight-back status still runs from those (cornered means no blow).
- **Art:** the four PixelLab sheets are generated in the plan's first task. The controller checks each by eye and shows
  the user the previews at the end. The cap is about 150 generations (balance was about 1250).

## Left to the builder

- Exact numbers (radii, caps, times, blows, the withering's length, grave-spot count), each recorded as a ruling.
- How "cornered" is judged for a citizen, by rule.
- The art: PixelLab for the hand sheet, the pale ghost, the skeleton warrior and the ghoul (the user's standing choice
  for these effects). Code-drawn effects are fine for fog, frost, dimming, soil bursts and dust.

## Checks

- Every changed power keeps its tests passing; new behaviour gets tests:
  - soldier swing and citizen fight-back;
  - Raise every body in the ring, and its cap;
  - Gate Below rift covering REACH, scattering wraiths, withering;
  - Pale ghosts lasting SPAN, the kill cap;
  - Serpent fright ahead;
  - Grave Tide grave spots across the city, the mixed horde, the building wreck, the living-undead cap.
- The fight change touches every fight with an undead, so the bots and references that move are re-recorded with
  reasons. Death nights and Hunts still win.
- The full gate passes, and crowd_check prints `-535548941`. The fight change must not move it: crowd_check casts no
  undead. If it moves, that is a bug.
- The bench on a quiet machine: Gate Below, Pale Reign and Serpent within 5 ms; Grave Tide within 8 ms.
