# KAK -- Death and Decree ability levels

Status: **proposed** (2026-11-16), waiting for the user's word. The twists were picked with the user on 2026-11-16;
the numbers are first guesses, to tune in play.

Scope: the twenty powers in the Death and Decree rows of `GodTree.TABLE` (feat/god-progression 7de2f7cd, after the
Death second review: level 1 below is the shipped numbers of docs/KAK_God_Death_Review_Rulings.md R28-R49). Their build
specs (`2026-11-12-kak-death-authority-powers-design.md`, `2026-11-12-kak-decree-authority-powers-design.md`) left
levels 1-5 and the level-5 twists to this spec, as Passage did.

## Intent

The user had no twists in mind and asked for twists that feel like Ruin's, Dominion's and Passage's. Read together,
those thirty twists share one shape: **the twist adds one more beat to the power's own story**, never a random roll,
often leaving something on the map or giving the player one more click to steer. Each god bends it to its own line:
Ruin's destruction spreads, Dominion's gives a new way to steer, Passage's springs one more surprise on the town.

- **Death** -- "Every life is a loan." Its build spec wants every death to feed the next power, so the god snowballs.
  Every level reaches **more people, for longer, and comes back sooner**; every level-5 twist **collects the debt**:
  a death the power causes feeds something new (a rising, a spread, a grab, a borrowed life).
- **Decree** -- "Your word is law, and the law is yours." Every level makes the law **cover more ground, hold longer
  and come back sooner**; every level-5 twist **adds one more clause** the law did not have, or lets it outlive the
  cast. Several clauses chain the Decree powers into each other (the amber cell, the CRIMINAL mark), as the user's
  Decree picks asked for chained stages.

## Approaches

1. **Same frame as Ruin, Dominion and Passage** (chosen). Levels are data on the `PowerBook` row, read through
   `PowerBook.stat()`; one twist per power at level 5. Nothing new to learn for the player or the builder.
2. Twists chosen by the player at level 5 (two twists per power, pick one). Rejected: no other god has it, it doubles
   the twist work, and the skill tree has no place to show the pick.
3. Authority-wide twist (one Death twist that every Death power shares at level 5). Rejected: it flattens twenty
   powers into one effect and breaks the "each power's own story" shape the user liked.

## Goals, non-goals, anti-goals

**Goals**
- A `levels` table on all twenty rows, so none shows `NO_LEVELS` ("Levels to come") any more.
- The twenty twists below, each with its own code and test.

**Non-goals**
- Windfall and the Folded Ward (Passage) still have no table; they are not part of this spec.
- No new art or sounds beyond what a twist needs to read on screen (a twist may reuse its power's parts).
- No change to the shared plague (`PlagueManager`): Pestilence's levels move only the cast's own numbers.

**Anti-goals**
- **Level 1 must change nothing.** Hunts, routes, references and FLOW play at level 1; none of them may move.
- No twist is a random roll (`kak-mission-design-lessons`: no luck).
- No twist may turn the god's own faithful into the town's target without the player choosing it.

## Frame (same as Ruin's, Dominion's and Passage's levels)

- Five levels per ability (`PowerBook.MAX_LEVEL`). Each level raises 2-4 of the ability's numbers.
- **Level 1 = today's numbers exactly.**
- Might cost: the base `dp` at levels 1-2, +1 at levels 3-4, +2 at level 5 (`PowerBook.MIGHT_STEPS`).
- Data: each row gets a `levels` table (index 0 = level 1). The effect reads each number through
  `PowerBook.stat(extra, "<key>", "<STAT>", CONST)`; a twist is gated by `PowerBook.twist_at(extra, key)`. Level 5
  carries `"twist": true` and `"twist_text"`.
- Stat names are the effect's own constants (feat/god-progression 7de2f7cd). **cd** is the cooldown in seconds. The
  Tier 5 powers are once a descent at every level, so they have no cd column.
- Might check at level 5 (the god's top budget is 16): Death Tier 5 Serpent 8 + Grave Tide 8 = 16; Decree Tier 5
  Cage 8 + Verdict 8 = 16; both at the cap. Death Tier 4 Gate 7 + Pale Reign 8 = 15 and Decree Tier 4 Eminent 6 +
  Fenced 7 = 13 fit too.
- Twists that need a click keep the slot live for the follow-up, as Dominion's Procession and Passage's Wandering
  Mouth do: Precedent, Further Claim, Third Clause, Dragged Cage.

## The twists at a glance

| Tier | Death | Twist | Decree | Twist |
|---|---|---|---|---|
| 1 | Death Mark | The Wake | Leaving Is Prohibited | Held for Trial |
| 1 | Raise the Dead | Body and Soul | Breathing Is Prohibited | And None May Leave |
| 2 | Pestilence | Foul Dead | Redefine | Precedent |
| 2 | Gravecall | Swelling Host | Bound in Law | Party to the Bond |
| 3 | Corpse Guise | Deathless | Erasing Distance | Shortcut |
| 3 | Walking Corpse | Borrowed Life | Disorder | Bad Counsel |
| 4 | The Gate Below | Graves Answer | Eminent Domain | Further Claim |
| 4 | Pale Reign | The Pall Grows | Fenced Rule | Third Clause |
| 5 | The Pale Serpent | Shed Skin | The Closing Cage | Dragged Cage |
| 5 | Grave Tide | Scattered Bones | The Sealed Verdict | The Ledger Remembers |

---

# Death

## Tier 1

### Death Mark (`deathmark`, 1 Might, quiet, `src/fx/death/death_mark.gd`)
Grows: a quicker death `MARK_TIME`, more who come to look `GAWKERS`, from farther `LOOK_R`, cooldown.

| Lv | MARK_TIME | GAWKERS | LOOK_R | cd | Might |
|---|---|---|---|---|---|
| 1 | 10 | 8 | 4 | 20 | 1 |
| 2 | 9.5 | 9 | 4.25 | 19 | 1 |
| 3 | 9 | 10 | 4.5 | 18 | 2 |
| 4 | 8.5 | 11 | 4.75 | 17 | 2 |
| 5 | 8 | 12 | 5 | 16 | 3 |

**Twist -- The Wake:** when the first gawker reaches the body, it gets up as a zombie in the middle of the crowd it drew:
a Raise the Dead ZOMBIE (`ZOMBIE_LIFE` 30 s, hunts the nearest, whoever it kills gets up too, `CHAIN` 3 in all), at
level 1 numbers. The body is used up as Raise uses it.

### Raise the Dead (`raise`, 1 Might, `src/fx/death/raise_the_dead.gd`; ZOMBIE / SPIRIT)
Grows: the zombies' time `ZOMBIE_LIFE`, the cast's chain `CHAIN` (R29: it counts the whole cast), the spirits' time
`SPIRIT_LIFE`, cooldown. The ring `RING_R` 3.0 and `MOST` 8 bodies stay at every level (the frame's cost, R28).

| Lv | ZOMBIE_LIFE | CHAIN | SPIRIT_LIFE | cd | Might |
|---|---|---|---|---|---|
| 1 | 30 | 3 | 20 | 25 | 1 |
| 2 | 32 | 3 | 21 | 24 | 1 |
| 3 | 34 | 4 | 22 | 23 | 2 |
| 4 | 36 | 4 | 23 | 22 | 2 |
| 5 | 38 | 5 | 24 | 21 | 3 |

**Twist -- Body and Soul:** one cast gives both halves, for every body the ring raised. ZOMBIE: when one of the ring's
zombies is cut down or its time ends, its soul rises out of it as a spirit of this cast (`SPIRIT_LIFE`, drifting after
its own nearest group as R28's spirits do); a body with no soul gives none. SPIRIT: when one of the ring's spirits
fades, it sinks back into its body and the body gets up as a zombie of this cast (`ZOMBIE_LIFE`, counted in the cast's
`CHAIN`). Once for each body: the second half never brings back the first, and the chain's risers give no spirit.

## Tier 2

### Pestilence (`pestilence`, 3 Might, quiet, `src/fx/curse/pestilence.gd`)
Grows: people infected `INFECT_MAX`, reach `INFECT_R`, cooldown. The plague itself (`PlagueManager`) does not change.

| Lv | INFECT_MAX | INFECT_R | cd | Might |
|---|---|---|---|---|
| 1 | 3 | 1.2 | 48 | 3 |
| 2 | 3 | 1.3 | 46 | 3 |
| 3 | 4 | 1.4 | 44 | 4 |
| 4 | 4 | 1.5 | 42 | 4 |
| 5 | 5 | 1.6 | 40 | 5 |

**Twist -- Foul Dead:** everyone this cast's plague kills (the ones it infected, and everyone the plague spread to from
them) leaves a body that breathes green miasma for 15 s: anyone healthy who comes within 1.2 of it catches the plague.
Each body infects 3 at most. Needs the infection to carry its source (the cast) as it spreads.

### Gravecall (`gravecall`, 2 Might, `src/fx/death/gravecall.gd`)
Grows: wraiths `SPIRITS`, haunt time `HAUNT`, a soldier's freeze `FREEZE`, cooldown.

| Lv | SPIRITS | HAUNT | FREEZE | cd | Might |
|---|---|---|---|---|---|
| 1 | 3 | 20 | 3 | 30 | 2 |
| 2 | 3 | 21 | 3.25 | 29 | 2 |
| 3 | 4 | 22 | 3.5 | 28 | 3 |
| 4 | 4 | 23 | 3.75 | 27 | 3 |
| 5 | 5 | 24 | 4 | 26 | 4 |

**Twist -- Swelling Host:** anyone who dies inside the haunt circle while the wraiths haunt it rises out of the body as
one more wraith and haunts with them for the rest of the haunt (4 more at most). The body stays.

## Tier 3

### Corpse Guise (`guise`, 3 Might, quiet, `src/fx/death/corpse_guise.gd`)
Grows: the faithful hidden `MOST`, reach `MARK_R`, time `SPAN`, cooldown.

| Lv | MOST | MARK_R | SPAN | cd | Might |
|---|---|---|---|---|---|
| 1 | 4 | 2 | 25 | 50 | 3 |
| 2 | 4 | 2.1 | 27 | 48 | 3 |
| 3 | 5 | 2.2 | 29 | 46 | 4 |
| 4 | 5 | 2.3 | 31 | 44 | 4 |
| 5 | 6 | 2.4 | 33 | 42 | 5 |

**Twist -- Deathless:** a guised faithful who would die (struck, crushed, bitten, choked; not taken whole, as by the
Gate) falls and lies as a body instead, unhurt. 5 s later they get up at full health and the guise holds 10 s more from
then. Once for each guised person a cast. (Claude's call: the fall is not a death: no kill is counted, no alarm
rises, and nothing can raise or take the "body", which is the living person lying still.)

### Walking Corpse (`walker`, 3 Might, quiet, `src/fx/death/walking_corpse.gd`)
Grows: its time `WALK_LIFE`, kills `KILLS_MOST`, the reach of an ATTACK order `ATTACK_R`, cooldown.

| Lv | WALK_LIFE | KILLS_MOST | ATTACK_R | cd | Might |
|---|---|---|---|---|---|
| 1 | 40 | 2 | 6 | 30 | 3 |
| 2 | 42 | 2 | 6.25 | 29 | 3 |
| 3 | 44 | 3 | 6.5 | 28 | 4 |
| 4 | 46 | 3 | 6.75 | 27 | 4 |
| 5 | 48 | 4 | 7 | 26 | 5 |

**Twist -- Borrowed Life:** after each ATTACK kill, the corpse takes the victim's face and clothes, and the victim
leaves no body: nobody gathers, no alarm rises, and the town sees that person still walking about (counted dead).
When the corpse lies down at the end, it lies as the last victim's body, where it stands. (Claude's call: the
victims die as `&"pit"` does, a kind that leaves no body but counts as a death for the mission and the tally; the
corpse takes the last victim's sprite set and keeps its Death sigil, which only the player reads.)

## Tier 4

### The Gate Below (`gatebelow`, 5 Might, `src/fx/death/the_gate_below.gd`)
Grows: the arms' reach `REACH` (the lip `EDGE` follows it at 0.7 of it, R33's 4.2 of 6), time open `SPAN`, the
touches a wraith has before it sinks `WRAITH_TOUCHES` (R37), cooldown. `ARMS` 36 stays at every level (the frame's
cost). The wraiths get stronger, not more of them: `SPAN` grows little, since every grab is one more wraith.

| Lv | REACH | EDGE | SPAN | WRAITH_TOUCHES | cd | Might |
|---|---|---|---|---|---|---|
| 1 | 6 | 4.2 | 12 | 3 | 90 | 5 |
| 2 | 6.25 | 4.375 | 12.5 | 3 | 87 | 5 |
| 3 | 6.5 | 4.55 | 13 | 4 | 84 | 6 |
| 4 | 6.75 | 4.725 | 13.5 | 4 | 81 | 6 |
| 5 | 7 | 4.9 | 14 | 5 | 78 | 7 |

**Twist -- Graves Answer:** while the rift is open, the 8 bodies nearest the rift within 12 of it each sprout a grave
hand (R34's sheet). Each drags the nearest living person within 1.5 of it down into the ground, once, leaving no body,
and its own body sinks with them. Each one taken is a soul: it climbs out of the rift as a wraith when it closes and
scatters with the rift's own (R35), withering what it touches (R37).

### Pale Reign (`pale`, 6 Might, `src/fx/death/pale_reign.gd`)
Grows: district `RADIUS`, time `SPAN` (the horde runs it all, R39), the horde's kill cap `HORDE_KILLS`, cooldown.
`HORDE_CAP` 24 ghosts up and `MAX_RISEN` 16 servants stay at every level: the reign gets deadlier, not more crowded
(Pale's cast/base ratio is 1.46 against the 1.55 ceiling).

| Lv | RADIUS | SPAN | HORDE_KILLS | cd | Might |
|---|---|---|---|---|---|
| 1 | 10 | 16 | 24 | 120 | 6 |
| 2 | 10.25 | 17 | 26 | 116 | 6 |
| 3 | 10.5 | 18 | 28 | 112 | 7 |
| 4 | 10.75 | 19 | 30 | 108 | 7 |
| 5 | 11 | 20 | 32 | 104 | 8 |

**Twist -- The Pall Grows:** every death in the district widens the grey by 0.25, up to 3 wider than the level's
`RADIUS` (12 deaths; up to 14 at level 5). Whoever the new edge reaches crawls with the rest; its fires gutter. The span
does not change. The ghosts run in the grown district.

## Tier 5 (once a descent)

### The Pale Serpent (`serpent`, 6 Might, once a descent, `src/fx/death/pale_serpent.gd`)
Grows: longest drag `LENGTH`, shadow half width `BAND` (R40's fog spreads across it), how far its rising is seen
`SIGHT`, the sickness `SICK`. R40's fog, frost, dim and fright cone keep their numbers and caps (`FOG_MOST` 40,
`FROST_MOST` 48) at every level.

| Lv | LENGTH | BAND | SIGHT | SICK | Might |
|---|---|---|---|---|---|
| 1 | 14 | 2 | 12 | 20 | 6 |
| 2 | 14.5 | 2.1 | 12.5 | 21 | 6 |
| 3 | 15 | 2.2 | 13 | 22 | 7 |
| 4 | 15.5 | 2.3 | 13.5 | 23 | 7 |
| 5 | 16 | 2.4 | 14 | 24 | 8 |

**Twist -- Shed Skin:** as it departs it sheds its skin, which lies along the whole path (the drag and the loop) for
30 s, a pale band 1 wide drawn with the Serpent's disc texture (one draw per segment, as 3d3f309d's cut). Whoever walks
onto it sickens as those who saw it rise do (`SICK_PACE` for `SICK`, and the plague when it is in town). Each person
once.

### Grave Tide (`gravetide`, 6 Might, once a descent, `src/fx/death/grave_tide.gd`)
Grows: the giant only, as the user ruled for the tide (stronger effects, not more units): its time `GIANT_LIFE`, its
blows `GIANT_BLOWS`, the slam's reach `SLAM_R` and its blow on buildings `SLAM_WRECK`. `GRAVES_MOST` 24, `LIVING_CAP`
60, `MOST` 30 and the undead's `LIFE` stay at every level (the tide is near its 8 ms ceiling: cast/base 1.55).

| Lv | GIANT_LIFE | GIANT_BLOWS | SLAM_R | SLAM_WRECK | Might |
|---|---|---|---|---|---|
| 1 | 60 | 12 | 3.5 | 60 | 6 |
| 2 | 63 | 13 | 3.6 | 65 | 6 |
| 3 | 66 | 14 | 3.7 | 70 | 7 |
| 4 | 69 | 15 | 3.8 | 75 | 7 |
| 5 | 72 | 16 | 4 | 80 | 8 |

**Twist -- Scattered Bones:** when the giant falls (cut down or its time ends), its 18 bones burst outward and each
lands as a SKELETON (R42's numbers) that hunts for 20 s. They count in `LIVING_CAP` 60: none rise while it is full. The
skeletons' kills do not rise.

---

# Decree

## Tier 1

### Leaving Is Prohibited (`noleave`, 1 Might, quiet, `src/fx/decree/leaving_is_prohibited.gd`)
Grows: the cell `RADIUS`, its hold `HOLD_TIME`, cooldown.

| Lv | RADIUS | HOLD_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 3 | 15 | 20 | 1 |
| 2 | 3.15 | 16 | 19 | 1 |
| 3 | 3.3 | 17 | 18 | 2 |
| 4 | 3.45 | 18 | 17 | 2 |
| 5 | 3.6 | 19 | 16 | 3 |

**Twist -- Held for Trial:** when the cell breaks, everyone still inside it is named CRIMINAL for 15 s (Redefine's
`LawMark.CRIMINAL`): the guards hunt them. The god's faithful are not named (the law is yours).

### Breathing Is Prohibited (`breath`, 2 Might, `src/fx/decree/breathing_is_prohibited.gd`)
Grows: circle `RADIUS`, time without air `HOLD_TIME`, cooldown. `CHOKE` stays 3 at every level: "3 s inside kills" is
the power.

| Lv | RADIUS | HOLD_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 2.5 | 8 | 25 | 2 |
| 2 | 2.65 | 8.5 | 24 | 2 |
| 3 | 2.8 | 9 | 23 | 3 |
| 4 | 2.95 | 9.5 | 22 | 3 |
| 5 | 3.1 | 10 | 21 | 4 |

**Twist -- And None May Leave:** a second law on the first. For its first 2 s the circle is sealed as the amber cell
is (`LawZone`: nobody inside may leave, the god's faithful too). Then leaving saves again: only those who reach the
edge between 2 s and 3 s get out.

## Tier 2

### Redefine (`redefine`, 3 Might, quiet, `src/fx/decree/redefine.gd`; CRIMINAL / OFFICER / NOBODY)
Grows: people named `MAX_NAMED`, time `SPAN`, cooldown.

| Lv | MAX_NAMED | SPAN | cd | Might |
|---|---|---|---|---|
| 1 | 3 | 25 | 45 | 3 |
| 2 | 3 | 27 | 43 | 3 |
| 3 | 4 | 29 | 41 | 4 |
| 4 | 4 | 31 | 39 | 4 |
| 5 | 5 | 33 | 37 | 5 |

**Twist -- Precedent:** while the names hold, a click on a person within 2 of a named one names them too, with the
same name, for the rest of that name's time. 3 more names at most.

### Bound in Law (`bound`, 3 Might, quiet, `src/fx/decree/bound_in_law.gd`)
Grows: how far apart the two may stand `REACH`, the bond's time `SPAN`, cooldown.

| Lv | REACH | SPAN | cd | Might |
|---|---|---|---|---|
| 1 | 10 | 20 | 45 | 3 |
| 2 | 10.5 | 22 | 43 | 3 |
| 3 | 11 | 24 | 41 | 4 |
| 4 | 11.5 | 26 | 39 | 4 |
| 5 | 12 | 28 | 37 | 5 |

**Twist -- Party to the Bond:** whoever strikes, seizes or stuns one of the bound joins the bond (2 more at most) and
shares its fate from then on, the blow they struck included: a guard who strikes one strikes himself.

## Tier 3

### Erasing Distance (`erase`, 4 Might, `src/fx/decree/erasing_distance.gd`)
Grows: longest line `MAX_LEN`, the crush band `CRUSH_W`, the throw band `THROW_W`, cooldown.

| Lv | MAX_LEN | CRUSH_W | THROW_W | cd | Might |
|---|---|---|---|---|---|
| 1 | 10 | 1 | 3 | 60 | 4 |
| 2 | 10.5 | 1.05 | 3.15 | 58 | 4 |
| 3 | 11 | 1.1 | 3.3 | 56 | 5 |
| 4 | 11.5 | 1.15 | 3.45 | 54 | 5 |
| 5 | 12 | 1.2 | 3.6 | 52 | 6 |

**Twist -- Shortcut:** when the line springs back, its two ends stay joined for 15 s, each marked by a gilt seam. Whoever
steps within 0.6 of one end comes out at the other (people, soldiers, pets, spirits), as through a door.

### Disorder (`disorder`, 3 Might, `src/fx/decree/disorder.gd`)
Grows: circle `RADIUS`, time `HOLD_TIME`, cooldown.

| Lv | RADIUS | HOLD_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 5 | 15 | 45 | 3 |
| 2 | 5.25 | 16 | 43 | 3 |
| 3 | 5.5 | 17 | 41 | 4 |
| 4 | 5.75 | 18 | 39 | 4 |
| 5 | 6 | 19 | 37 | 5 |

**Twist -- Bad Counsel:** whoever leaves the circle while it holds carries the disorder with them for 8 s: their
choices stay wrong wherever they go. It does not spread from them.

## Tier 4

### Eminent Domain (`eminent`, 4 Might, `src/fx/decree/eminent_domain.gd`)
Grows: strip `LENGTH`, half width `HALF_W`, cooldown.

| Lv | LENGTH | HALF_W | cd | Might |
|---|---|---|---|---|
| 1 | 10 | 1 | 80 | 4 |
| 2 | 10.5 | 1.05 | 77 | 4 |
| 3 | 11 | 1.1 | 74 | 5 |
| 4 | 11.5 | 1.15 | 71 | 5 |
| 5 | 12 | 1.2 | 68 | 6 |

**Twist -- Further Claim:** within 5 s of the first strip, a second drag that starts at the first strip's end claims a
second strip (6 long at most, the same width) in any direction, so the road can turn a corner. Once a cast.

### Fenced Rule (`fenced`, 5 Might, `src/fx/decree/fenced_rule.gd`; ten rule pairs)
Grows: circle `RADIUS`, time `HOLD_TIME`, cooldown.

| Lv | RADIUS | HOLD_TIME | cd | Might |
|---|---|---|---|---|
| 1 | 7 | 30 | 80 | 5 |
| 2 | 7.25 | 32 | 77 | 5 |
| 3 | 7.5 | 34 | 74 | 6 |
| 4 | 7.75 | 36 | 71 | 6 |
| 5 | 8 | 38 | 68 | 7 |

**Twist -- Third Clause:** once while it holds, Q/E picks one of the three rules of `RULES` not yet in force and a click inside
the fence adds it for the rest of the time.

## Tier 5 (once a descent)

### The Closing Cage (`cage`, 6 Might, once a descent, `src/fx/decree/the_closing_cage.gd`)
Grows: the ring `RADIUS`, and a quicker sentence `CLOSE_TIME` (less time for the town to answer).

| Lv | RADIUS | CLOSE_TIME | Might |
|---|---|---|---|
| 1 | 12 | 30 | 6 |
| 2 | 12.5 | 29 | 6 |
| 3 | 13 | 28 | 7 |
| 4 | 13.5 | 27 | 7 |
| 5 | 14 | 26 | 8 |

**Twist -- Dragged Cage:** once while it closes, a click moves its centre up to 6 toward the click over 2 s. Everyone
inside is dragged along with it, and every building the bars cross is crushed as the closing ring crushes them.

### The Sealed Verdict (`sealed`, 6 Might, quiet, once a descent, `src/fx/decree/the_sealed_verdict.gd`)
Grows: district `RADIUS`, and a quicker bell `COUNTDOWN`.

| Lv | RADIUS | COUNTDOWN | Might |
|---|---|---|---|
| 1 | 10 | 30 | 6 |
| 2 | 10.5 | 29 | 6 |
| 3 | 11 | 28 | 7 |
| 4 | 11.5 | 27 | 7 |
| 5 | 12 | 26 | 8 |

**Twist -- The Ledger Remembers:** the ledger keeps names, not a place: everyone who stood in the district at any
moment of the countdown dies at the bell wherever they are, indoors too. (Claude's call: even one frame inside
counts; the faithful die as the base verdict kills them.)

---

## Notes for the builder

- Level 1 must change nothing: suite, all references and FLOW must be what they were.
- Every listed stat is read through `PowerBook.stat()` instead of the constant. A stat that sizes something at cast
  (a radius, a count) is read once at cast time.
- Player input: Precedent, Further Claim, Third Clause and Dragged Cage need a follow-up click while the power runs.
  The other sixteen twists need no input.
- New pieces the twists need:
  - The Wake, Body and Soul, Scattered Bones: reuse Raise the Dead's zombie and spirit (`DeathParts`).
  - Foul Dead: an infection that carries its source as it spreads, and a miasma hazard on a body.
  - Swelling Host, Graves Answer: a wraith raised from a death or a grab, joining the cast's own.
  - Deathless: a death caught and turned into a 5 s fall for a guised person.
  - Borrowed Life: a kill that leaves no body, and the corpse wearing the victim's look.
  - The Pall Grows: a district radius that grows during the span.
  - Shed Skin: a lasting band along the path that sickens.
  - Held for Trial, Precedent: Redefine's `LawMark` names given by other powers.
  - And None May Leave: the amber cell's `LawZone` hold for 2 s.
  - Party to the Bond: the bond grows past two.
  - Shortcut: two linked ends that move whoever steps on them (Skylift's fold per person).
  - Bad Counsel: the disorder carried as a short status on a person.
  - Further Claim, Dragged Cage: a second aim within the cast.
  - Third Clause: a third rule added to a live `LawZone`.
  - The Ledger Remembers: the verdict keeps a list of everyone who entered.
- A twist needs its own code and test. The stat rows are data.
- Claude's calls (2026-11-16, after a builder read):
  - Who the twists hit follows the power's own rules: a zombie, wraith or skeleton a twist raises hunts as its
    power's own do (the faithful too, unless Corpse Guise hides them), and a Decree twist binds as its law does. The
    one exception is the anti-goal: a twist never names the faithful CRIMINAL (Held for Trial).
  - The per-key area, danger-time and alarm tables in `power_book.gd` stay at their level 1 values, as for Passage.
  - The Might column is for reading only: Might comes from `PowerBook.might()` (`MIGHT_STEPS`), not the table.
  - Tests copy the Passage twists' level-5 test pattern.
- Frame budgets (docs/KAK_God_Death_Review_Rulings.md, R13/R47 and the frame-cost table): at level 5 with its twist,
  the Gate Below, Pale Reign and the Serpent stay within 5 ms (cast/base ratio 1.55 on a loaded machine) and Grave Tide
  within 8 ms (1.9). Bench each at level 5 with the twist firing; if one is over, cut its twist's draw first, then its
  growth, never the level 1 numbers.
- Refs: the Death and Decree reference rows play at level 1 and must not move. Add one level-5 sandbox check per twist.
