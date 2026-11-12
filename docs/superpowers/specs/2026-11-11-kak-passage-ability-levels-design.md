# KAK -- Passage ability levels

Status: **proposed** (2026-11-11), second draft with the user's twists, waiting for the user's word. Numbers are
first guesses, to tune in play.

Scope: the ten powers the user placed in the Passage Tree Picker (2026-11-11). The tiers below are the tree's, not
the powers' DP: Hellmouth Spark sits in Tier 2 and Door to the Deep in Tier 3. Thornwall, Pilgrim Road, Yesterday's
Door, Every Door and The Far Gate are out of the tree and get levels later.

## Intent

Passage's line in the god select: "Every way is yours to open or to close." Every level makes the god's ways **wider,
open longer, and ready sooner**. Every level-5 twist springs **one more thing on the town** that nobody saw coming: a
crowd pinned where it lands, a meteor, standing water, a second door, glass twins, a last door, a square carried off,
the dead rising. No twist is a random roll. Skylift's, Windfall's, Door to the Deep's and Heaven's Door's twists are the
user's; Mirrorfold's, All Roads', the Folded Ward's and Doors of the Dead's were redesigned in the same spirit.

## Frame (same as Ruin's and Dominion's levels)

- Five levels per ability (`PowerBook.MAX_LEVEL`). Each level raises 2-4 of the ability's numbers.
- **Level 1 = today's numbers exactly.** Hunts, routes and references play at level 1, so none of them may move.
- Might cost: the base `dp` at levels 1-2, +1 at levels 3-4, +2 at level 5 (`PowerBook.MIGHT_STEPS`).
- Data: each power's `PowerBook` row gets a `levels` table (index 0 = level 1). The effect reads each number
  through `PowerBook.stat(extra, "<key>", "<STAT>", CONST)`; a twist is gated by `PowerBook.twist_at(extra, key)`.
  Level 5 carries `"twist": true` and `"twist_text"`.
- Stat names are the effect's own constants (Develop-Main d93228f2). **cd** is the cooldown in seconds. The Tier 5
  powers are once a night at every level, so they have no cd column.
- Might cap check: the Tier 5 pair at level 5 is Doors of the Dead 8 + Heaven's Door 8 = 16, at the cap of 16.

## The twists at a glance

| Tier | Power | Twist | |
|---|---|---|---|
| 1 | Skylift | Stay Put | your twist |
| 1 | Windfall | Heart of the Fall | your twist |
| 2 | Hound Gate | Quarry | first draft |
| 2 | Hellmouth Spark | Wandering Mouth | first draft |
| 3 | Door to the Deep | Standing Water | your twist |
| 3 | Mirrorfold Passage | Mirror Twins | redesigned |
| 4 | All Roads Lead Here | The Last Mile | redesigned |
| 4 | The Folded Ward | Pocket Square | redesigned |
| 5 | Doors of the Dead | Rise Again | redesigned |
| 5 | Heaven's Door | Twin Doors | your twist |

---

## Tier 1

### Skylift (`skylift`, 1 Might, quiet, `src/fx/control/skylift.gd`)
Grows: lift circle `RADIUS`, a quicker take `T_TAKE`, cooldown.

| Lv | RADIUS | T_TAKE | cd | Might |
|---|---|---|---|---|
| 1 | 2.5 | 1.4 | 20 | 1 |
| 2 | 2.7 | 1.3 | 19 | 1 |
| 3 | 2.9 | 1.2 | 18 | 2 |
| 4 | 3.1 | 1.1 | 17 | 2 |
| 5 | 3.3 | 1 | 16 | 3 |

**Twist -- Stay Put** (your twist): everyone and everything the beam sets down stays put at the second place for 10 s. The people stand rooted where they landed: they take no step of their own, but they can still be struck, bitten or carried by another power. Then they walk on to what they meant to do. Soldiers too. The heap lands as before.

### Windfall (`windfall`, 1 Might, loud, `src/fx/control/windfall.gd`; cargo STONE / OIL / GOODS / PLAGUE)
Grows: line length `LENGTH` (with `SEGMENTS`, each `SEG` wide), the work to clear it `CLEAR_WORK`, cooldown.

| Lv | LENGTH | SEGMENTS | CLEAR_WORK | cd | Might |
|---|---|---|---|---|---|
| 1 | 3.6 | 6 | 150 | 25 | 1 |
| 2 | 3.9 | 6 | 165 | 24 | 1 |
| 3 | 4.2 | 7 | 180 | 23 | 2 |
| 4 | 4.5 | 8 | 195 | 22 | 2 |
| 5 | 4.8 | 8 | 210 | 21 | 3 |

**Twist -- Heart of the Fall** (your twist): when the last piece of the line is down, one great meteor comes out of the portal and lands on the line's middle. Whoever stands within 1.2 of it is crushed, what stands within 2.5 takes 60 (stone: no fire), and it stays as a boulder 1.8 across that blocks the street around the line's middle, with twice a segment's clearing work. With OIL cargo the meteor burns as a segment does; with GOODS and PLAGUE it is stone.

## Tier 2

### Hound Gate (`houndgate`, 2 Might, loud, `src/fx/control/hound_gate.gd`)
Grows: hounds `HOUNDS`, hunt time `HUNT`, blows to cut one down `BLOWS`, cooldown.

| Lv | HOUNDS | HUNT | BLOWS | cd | Might |
|---|---|---|---|---|---|
| 1 | 4 | 30 | 4 | 40 | 2 |
| 2 | 4 | 32 | 4 | 38.5 | 2 |
| 3 | 5 | 34 | 4 | 37 | 3 |
| 4 | 6 | 36 | 5 | 35.5 | 3 |
| 5 | 6 | 38 | 5 | 34 | 4 |

**Twist -- Quarry** (first draft): while they hunt, a click on a person marks them: every hound runs for that one (any distance, by the streets) until they fall or go inside, then hunts as before. A new mark replaces the old.

### Hellmouth Spark (`hellspark`, 1 Might, loud, `src/fx/control/hellmouth_spark.gd`)
Grows: mouth `RADIUS`, time open `OPEN`, cooldown.

| Lv | RADIUS | OPEN | cd | Might |
|---|---|---|---|---|
| 1 | 1.5 | 6 | 20 | 1 |
| 2 | 1.65 | 6.5 | 19 | 1 |
| 3 | 1.8 | 7 | 18 | 2 |
| 4 | 1.95 | 7.5 | 17 | 2 |
| 5 | 2.1 | 8 | 16 | 3 |

**Twist -- Wandering Mouth** (first draft): while it is open, one click moves it: it shuts with a burst where it was and tears open at the click (within 4 of it) for the rest of its time. Once a cast.

## Tier 3

### Door to the Deep (`deep`, 2 Might, loud, `src/fx/control/door_to_the_deep.gd`)
Grows: whirlpool `RADIUS`, time open `SPAN`, inward pull at the middle `PULL_CORE`, cooldown.

| Lv | RADIUS | SPAN | PULL_CORE | cd | Might |
|---|---|---|---|---|---|
| 1 | 4 | 25 | 0.75 | 40 | 2 |
| 2 | 4.25 | 26 | 0.8 | 38.5 | 2 |
| 3 | 4.5 | 28 | 0.85 | 37 | 3 |
| 4 | 4.75 | 30 | 0.9 | 35.5 | 3 |
| 5 | 5 | 31 | 0.95 | 34 | 4 |

**Twist -- Standing Water** (your twist): when the door shuts, its water stays: the circle lies flooded for 20 s more, though nobody is drawn in or taken any more. Whoever walks into it is soaked and slowed: they walk at half pace while in it and for 6 s after they leave it. Fires in it stay out.

### Mirrorfold Passage (`mirror`, 3 Might, quiet, `src/fx/control/mirrorfold_passage.gd`)
Grows: longest fold `MAX_LEN`, time it stands `MIRROR_TIME`, cooldown.

| Lv | MAX_LEN | MIRROR_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 6 | 30 | 54 | 3 |
| 2 | 6.5 | 32 | 52 | 3 |
| 3 | 7 | 35 | 50 | 4 |
| 4 | 7.5 | 38 | 48 | 4 |
| 5 | 8 | 40 | 46 | 5 |

**Twist -- Mirror Twins** (redesigned): everyone who goes through leaves a glass twin at the way in, which walks on toward where they meant to go for 12 s. The town takes a twin for the real one: soldiers strike it, hounds and spirits bite it, people follow it or flee it as they would the person. A struck twin shatters, and its shards cut whoever stands within 0.6 (a citizen hurt, a soldier wounded).

## Tier 4

### All Roads Lead Here (`allroads`, 4 Might, quiet, `src/fx/control/all_roads_lead_here.gd`)
Grows: district `RADIUS`, people bent `MAX_PEOPLE`, time it holds `SPAN`, cooldown.

| Lv | RADIUS | MAX_PEOPLE | SPAN | cd | Might |
|---|---|---|---|---|---|
| 1 | 10 | 80 | 25 | 90 | 4 |
| 2 | 10.5 | 88 | 27 | 87 | 4 |
| 3 | 11 | 95 | 29 | 84 | 5 |
| 4 | 11.5 | 102 | 31 | 81 | 5 |
| 5 | 12 | 110 | 33 | 78 | 6 |

**Twist -- The Last Mile** (redesigned): in the last 3 s of the span, the end of every road opens: The Far Gate's door of stars stands at the click, and everyone the roads have brought within GATHER_R of it walks in and is gone for the night (kind gone, counted dead, no body). Those still on their way arrive too late and stand where they are when it shuts.

### The Folded Ward (`foldward`, 4 Might, quiet, `src/fx/control/the_folded_ward.gd`; NO WAY OUT / NO WAY IN)
Grows: square half-width `HALF`, time it holds `SPAN`, cooldown.

| Lv | HALF | SPAN | cd | Might |
|---|---|---|---|---|
| 1 | 3 | 25 | 90 | 4 |
| 2 | 3.25 | 27 | 87 | 4 |
| 3 | 3.5 | 29 | 84 | 5 |
| 4 | 3.75 | 31 | 81 | 5 |
| 5 | 4 | 33 | 78 | 6 |

**Twist -- Pocket Square** (redesigned): when the span ends, the square folds shut like paper and the god sets it down again: a click within 4 s picks where, anywhere in town. Everyone inside it (people, soldiers, pets, spirits) is unfolded into a square of the same size there, each where they stood in it, dazed 1 s. With NO WAY OUT, that is everyone the ward caught. With no click, it opens where it was.

## Tier 5 (once a night)

### Doors of the Dead (`deaddoors`, 6 Might, loud, once a night, `src/fx/control/doors_of_the_dead.gd`)
Grows: district `RADIUS`, doors `MAX_DOORS`, the horde's time `SPAN`, spirits in all `MAX_SPIRITS`. `LIVE_CAP` stays 70 at every level (the frame's cost).

| Lv | RADIUS | MAX_DOORS | SPAN | MAX_SPIRITS | Might |
|---|---|---|---|---|---|
| 1 | 12 | 18 | 45 | 160 | 6 |
| 2 | 12.5 | 20 | 49 | 175 | 6 |
| 3 | 13 | 21 | 52 | 190 | 7 |
| 4 | 13.5 | 22 | 56 | 205 | 7 |
| 5 | 14 | 24 | 60 | 220 | 8 |

**Twist -- Rise Again** (redesigned): whoever the horde kills rises 2 s later where they fell, as a ghost of the other side, and joins the hunt (a ghost's numbers, counted in the shared LIVE_CAP; none rise while it is full). Those they kill rise too, until the span ends and the doors call every one of them back.

### Heaven's Door (`heavendoor`, 6 Might, loud, once a night, `src/fx/control/heavens_door.gd`)
Grows: pull reach `PULL_R`, pull time `SPAN`, pull at the rim `PULL_FAR` (runners escape less), the landing's blow `LAND_DAMAGE`.

| Lv | PULL_R | SPAN | PULL_FAR | LAND_DAMAGE | Might |
|---|---|---|---|---|---|
| 1 | 16 | 12 | 0.6 | 40 | 6 |
| 2 | 17 | 13 | 0.68 | 45 | 6 |
| 3 | 18 | 14 | 0.75 | 50 | 7 |
| 4 | 19 | 15 | 0.82 | 55 | 7 |
| 5 | 20 | 16 | 0.9 | 60 | 8 |

**Twist -- Twin Doors** (your twist): two doors fall together, back to back, one facing the drag and one facing the other way, so the pull covers the whole circle of PULL_R instead of the half before one door. Each door takes whoever reaches it. The landing blow is struck once.

---

## Notes for the builder

- Level 1 must change nothing: suite, all references and FLOW must be what they were.
- Every listed stat is read through `PowerBook.stat()` instead of the constant. A stat that sizes something else
  (Windfall's segments) is read once at cast time; Windfall's segment count follows its length (LENGTH / SEG, rounded).
- Player input: Pocket Square needs one follow-up click within 4 s of the span's end; Quarry and Wandering Mouth need
  a click while the power runs. The slot stays live for the follow-up, as Dominion's Procession and Sleepwalk do. The
  other seven twists need no input.
- New pieces each twist needs:
  - Stay Put: a rooted hold on the people set down (reuse Person's hold pieces).
  - Heart of the Fall: a meteor drop and a 1.8 boulder structure (role windfall, twice the clear weight).
  - Standing Water: a lasting flood area after the door shuts, and a soak status that slows for 6 s.
  - Twin Doors: a second door node turned the other way, and the cone pull widened to the full circle.
  - Mirror Twins: glass decoys the guard, hounds, spirits and crowd treat as people (a Visitors-like pack of
    walkers that are struck and shatter); shards are a small hurt radius.
  - The Last Mile: The Far Gate's door and its take reused at the end point.
  - Pocket Square: everyone inside moved square to square (Skylift's fold() per person), with a click to aim it.
  - Rise Again: a ghost summoned on each horde kill, under the shared LIVE_CAP.
- A twist needs its own code and test. The stat rows are data.
- Hound Gate (Quarry) and Hellmouth Spark (Wandering Mouth) keep the first draft's twists; say if they should get the
  same surprise treatment.
