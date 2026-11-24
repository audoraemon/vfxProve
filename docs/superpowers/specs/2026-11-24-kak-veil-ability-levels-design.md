# KAK -- Veil ability levels

Status: **approved in conversation** by the user (2026-11-24: the shared line and the ten twists, "All's good let's
implement"). The numbers are first guesses, to tune in play; design choices the user did not state are marked (mine).

Scope: the ten powers in the Veil row of `GodTree.TABLE` on `god/veil-review` 9935bc91 (level 1 below is the shipped
numbers after the second review pass). Their build spec (`2026-11-19-kak-veil-authority-powers-design.md`) left levels
2-5 and the level-5 twists to this spec, as Death, Decree and Passage did. Branch: `god/veil-levels`, cut from 9935bc91.

## 1. Intent

The user's words: "I want Veil god in level 5 to be feel like a real master of darkness. No one will see or barely see
what's he doing or coming after for. If someone feel his presence he'll know immediately."

Two halves, and the design serves both:

1. **Unseen.** At level 5 the town sees almost nothing of what the god does or who he is after.
2. **He knows.** If anyone does sense him, the player knows at once.

The other five gods' twists each share one line (Ruin spreads, Dominion steers, Passage springs a surprise, Death
collects the debt, Decree adds a clause). The Veil's line is **"the dark watches back"**: whoever notices a Veil power is
shown to the player, and the power answers him.

## 2. Approaches

Three shared lines for the twists were laid out; the user picked A ("Go with A first").

- **A. The dark watches back** (chosen). Anyone who notices a Veil power gets a pale eye over his head for the player,
  and each power answers that person in its own way. Serves both halves. Costs one shared piece (the Pale Eye).
- **B. No trace.** Each twist erases evidence (bodies never found, the sick not missed). Serves half 1 only, and adds no
  new play. Parts of it live on inside A (Dreamless's Found by No One).
- **C. The dark walks.** Each twist lets the player move the power after the cast. Rejected for now: it is Dominion's
  and Decree's line already.

For the numbers, three things could grow (the Veil is the only god with two sizes): the light size, the dark size, or
the dusk a cast leaves. Chosen (mine, shown to the user): **the dark grows, the light barely moves.** A master is not
stronger in daylight; he makes more dark and owns it. Growing the light size toward the dark size was rejected: it
erases the law of the Veil.

## 3. Goals, non-goals, anti-goals

**Goals**
- A `levels` table on all ten Veil rows, so none shows `NO_LEVELS` ("Levels to come") any more.
- The Pale Eye (section 6) and the ten twists (section 7), each with its own code and tests.
- The aim ring, the people preview and the `LIGHT` / `DARK` tag show the size of the level being cast.

**Non-goals**
- No new art by PixelLab. A twist reuses its power's parts; the Pale Eye is code-drawn.
- No change to the law of the Veil itself (which ground is dark, sight 0.6 in dusk, who is a witness).
- No tuning of Hunts, routes or bots: they play at level 1.
- Town Suspicion and LevelSound (both on feat/Develop-Main, not on this branch) are met when the Veil is merged with
  Develop-Main, not here.

**Anti-goals**
- **Level 1 must change nothing.** Every level-1 row equals today's constants and `VeilRules.SIZES`; no reference row,
  Hunt, route or FLOW check may move. Scripts keep Blight's 36 s pace (`Rules.pace`).
- No twist is a random roll. Who notices and who is answered is always decided by distance, then a fixed order.
- No twist raises the alarm, frightens anyone or makes a sound the town hears. The Veil stays quiet.
- No twist touches the god's own believers or whoever the mission keeps alive (`Crowd.spared()`), beyond what its power
  already does at level 1.
- Powers stay reusable effects: nothing of a twist is hard-coded into `CitizenAgent` or `Person` (a shared, named hook
  another power could use is fine).

## 4. Frame (same as the other gods' levels)

- Five levels per ability (`PowerBook.MAX_LEVEL`). **Level 1 = today's numbers exactly.**
- Might: the base `dp` at levels 1-2, +1 at levels 3-4, +2 at level 5 (`PowerBook.MIGHT_STEPS`). At level 5: Tier 5
  The Swallowing Dark 8 + Evernight 8 = 16, the god's cap; Tier 4 Dread 6 + Shadow Play 7 = 13.
- Data: each row gets a `levels` table (index 0 = level 1), read through `PowerBook.stat(extra, key, stat, CONST)`; a
  twist is gated by `PowerBook.twist_at(extra, key)` before it schedules or measures anything. Level 5 carries
  `"twist": true` and `"twist_text"`.
- **New for the Veil: a sized stat holds a pair, light then dark** (written `light / dark` below). `VeilRules.size()`
  and `VeilParts.size()` gain the level; `VeilRules.SIZES` stays as the level-1 pairs and a test holds the two equal.
  How the pair is stored in the table (an Array, a Vector2, two stat names) is the builder's call; the skill tree's
  level rows must print it readably ("1.6 / 3.5" style, light then dark).
- The Tier 5 powers are once a descent at every level: no cooldown column.

## 5. The numbers

**cd** = cooldown in seconds. Sizes are `light / dark`. Stat names are the effects' own constants.

### 5.1 The dusk every Veil cast leaves (one rule for all, by the casting power's level)

| Level | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Least radius (`VeilRules.DUSK_R`) | 3.0 | 3.25 | 3.5 | 3.75 | 4.0 |
| Lasts (`VeilRules.DUSK_TIME`), s | 20 | 22 | 24 | 26 | 28 |

It applies wherever a cast lays dusk today (`VeilParts.land()`): at the cast for most, when the dread lifts for Dread of
the Dark, on the emptied ground for The Swallowing Dark. A power whose own area is larger still lays its own area.
Evernight lays none. A blighted building's foothold still lasts the whole night (its radius is in 5.2). Whether these
two numbers live in `VeilRules` by level or in each row's table is the builder's call; the tree should show them.

### 5.2 Tier 1

**Silent Doom** (dp 1)

| Level | RADIUS | cd |
|---|---|---|
| 1 | 0.8 / 1.6 | 10 |
| 2 | 0.8 / 1.75 | 9.5 |
| 3 | 0.85 / 1.9 | 9 |
| 4 | 0.85 / 2.05 | 8.5 |
| 5 | 0.9 / 2.2 | 8 |

**Blight** (dp 2). `DUSK_R` is the foothold's dusk round a blighted building; `ILL_MOST` how many fall ill from one
person cast; `ILL_REACH` how far the dark's extra sick are sought. `VeilRules.BLIGHT_MAX` stays 3.

| Level | DUSK_R | ILL_MOST | ILL_REACH | cd |
|---|---|---|---|---|
| 1 | 3.0 / 5.0 | 1 / 3 | 2.0 | 20 |
| 2 | 3.1 / 5.3 | 1 / 3 | 2.2 | 19 |
| 3 | 3.2 / 5.6 | 1 / 4 | 2.4 | 18 |
| 4 | 3.3 / 5.9 | 1 / 4 | 2.6 | 17 |
| 5 | 3.4 / 6.2 | 1 / 5 | 2.8 | 16 |

### 5.3 Tier 2

**Slumber** (dp 3)

| Level | RADIUS | SLEEP_TIME | cd |
|---|---|---|---|
| 1 | 1.5 / 3.5 | 20 | 40 |
| 2 | 1.55 / 3.75 | 22 | 38 |
| 3 | 1.6 / 4.0 | 24 | 36 |
| 4 | 1.65 / 4.25 | 26 | 34 |
| 5 | 1.7 / 4.5 | 28 | 32 |

**Cloak of Night** (dp 3)

| Level | MARK_R | MOST | SPAN | cd |
|---|---|---|---|---|
| 1 | 2.0 / 4.0 | 3 / 8 | 25 | 45 |
| 2 | 2.05 / 4.25 | 3 / 9 | 27 | 43 |
| 3 | 2.1 / 4.5 | 3 / 10 | 29 | 41 |
| 4 | 2.15 / 4.75 | 4 / 11 | 31 | 39 |
| 5 | 2.2 / 5.0 | 4 / 12 | 33 | 37 |

### 5.4 Tier 3

**Unseen Hour** (dp 3)

| Level | RADIUS | VEIL_TIME | cd |
|---|---|---|---|
| 1 | 5.0 / 7.0 | 20 / 30 | 60 |
| 2 | 5.1 / 7.4 | 20.5 / 32 | 58 |
| 3 | 5.2 / 7.8 | 21 / 34 | 56 |
| 4 | 5.3 / 8.2 | 21.5 / 36 | 54 |
| 5 | 5.4 / 8.6 | 22 / 38 | 52 |

**Dreamless** (dp 3). A longer `REST` is a longer time before anyone is found.

| Level | REACH | MOST | REST | cd |
|---|---|---|---|---|
| 1 | 1.0 / 2.0 | 1 / 4 | 20 | 35 |
| 2 | 1.05 / 2.25 | 1 / 5 | 22 | 33.5 |
| 3 | 1.1 / 2.5 | 1 / 6 | 24 | 32 |
| 4 | 1.15 / 2.75 | 2 / 7 | 26 | 30.5 |
| 5 | 1.2 / 3.0 | 2 / 8 | 28 | 29 |

### 5.5 Tier 4

**Dread of the Dark** (dp 4). Its dark reach does **not** grow (mine): at its dark size it is already the Veil's most
costly power (first review round: about +15 ms a frame cast inside Evernight on a loaded machine). It grows by time, and
its light reach grows so a cast in the light finds dark ground more easily.

| Level | REACH | HOLD | cd |
|---|---|---|---|
| 1 | 6.0 / 12.0 | 25 | 70 |
| 2 | 6.25 / 12.0 | 27.5 | 67 |
| 3 | 6.5 / 12.0 | 30 | 64 |
| 4 | 6.75 / 12.0 | 32.5 | 61 |
| 5 | 7.0 / 12.0 | 35 | 58 |

**Shadow Play** (dp 5)

| Level | RADIUS | SPAN | cd |
|---|---|---|---|
| 1 | 3.0 / 6.0 | 30 | 90 |
| 2 | 3.1 / 6.3 | 32 | 87 |
| 3 | 3.15 / 6.6 | 34 | 84 |
| 4 | 3.25 / 6.9 | 36 | 81 |
| 5 | 3.3 / 7.2 | 38 | 78 |

### 5.6 Tier 5 (once a descent)

**The Swallowing Dark** (dp 6). A faster `GROW` is less waiting; the sound and the look already read their times from
the growth, so they follow.

| Level | FULL_R | GROW |
|---|---|---|
| 1 | 10.0 / 14.0 | 0.5 |
| 2 | 10.2 / 14.5 | 0.55 |
| 3 | 10.4 / 15.0 | 0.6 |
| 4 | 10.6 / 15.5 | 0.65 |
| 5 | 10.8 / 16.0 | 0.7 |

**Evernight** (dp 6). `NIGHT_TIME`'s pair is by day / in a NIGHT mission, as today. `TAKE_FIRST` stays 5 and
`TAKE_EVERY` stays 2.0 / 1.5. The user has not yet said whether 214 taken a night (level 1, by day, test town) is too
many, so the growth here is small: about 280 at level 5 by day. Fewer torches is less light for the town.

| Level | NIGHT_TIME | TAKE_LAST | TORCHES |
|---|---|---|---|
| 1 | 60 / 90 | 10 | 6 |
| 2 | 62 / 93 | 10 | 6 |
| 3 | 64 / 96 | 11 | 6 |
| 4 | 66 / 99 | 11 | 5 |
| 5 | 68 / 102 | 12 | 5 |

## 6. The Pale Eye (the shared piece)

At level 5, whoever notices a Veil power is **eyed**: a pale eye opens over his head. One named, reusable piece that all
ten twists call (as Decree's twists share `LawMark`); it holds no power's rule itself.

- **For the player only.** It is a drawing and a list; it changes nothing the town does. No alarm, no fright.
- **Seen at once, anywhere.** If the eyed person is off screen, a small eye sits at the screen's edge, pointing to him.
  A soft cue plays for the player (one sound, at most once a second however many are eyed at once; CC0 library, a
  foley recipe like the other Veil cues; never Sonniss). The town does not hear it.
- **How long.** An eye stays for the time its twist names, 4 s when the twist names none, and goes at once, for good,
  when the person is taken, dies or goes indoors (he does not get it back on coming out; being eyed again later is a
  new entry in the record).
- **One piece on screen.** All eyes are one drawn node over the heads (not a node a person), above people and below
  the aim ring; it does not use `Person.set_badge` (Blight's glyph, a Decree cell's bars and a Death Mark own that), so
  an eyed person keeps whatever badge he has.
- **A record.** It keeps who was eyed, by which power and when, so tests can read it.
- **"The watch"** in the twists below is one shared test, `is_watch(person)`, used by all of them (mine): every
  soldier of every corps (guards, searchers, inquisitors are soldiers), plus whoever the night's director names as
  its witnesses where it has such a list. Ordinary citizens are not the watch (else Unseen Hour would eye the town).
- **"Blind"** (Unseen Hour's twist) is a new timed state on a person, shared and named (mine): while it lasts he is
  no witness and reports and seizes nothing, exactly as if he stood in the veil; he still walks, flees and fights as
  usual. Every reader that skips the veiled, the shadows or the dreaded as witnesses skips the blind too (the copies
  of that skip list in `Crowd.nearest_witness()`, `TempleReport` and the directors).
- Only a level-5 Veil cast ever eyes anyone: a night with no level-5 Veil power builds nothing and draws nothing.

## 7. The twists

Each: who notices, then how the power answers. Every pick is by distance, a tie to the lower instance id.

### Tier 1

**Silent Doom -- No Witness.** "The nearest one who saw it falls too."
When a level-5 cast's deaths are judged (`Crowd._settle_doom()`, the same step as today, no added delay), each death
that has a witness (`Crowd.nearest_witness()`, today's rule and reach) names its nearest witness. Each named witness is
eyed and falls dead at once, credited to the cast (one witness named by several deaths falls once). Then the cast's
first deaths are judged as today with the silenced gone: a death that still has another living witness is seen and
raises the alarm as it does now. The witnesses' own deaths are
judged by today's rule with **no second hop**. A witness the power may not kill (a believer, one the mission keeps
alive) is eyed and not silenced, so that death is seen.

**Blight -- Watchful Rot.** "The watch falls ill in your rot."
A building blighted by a level-5 cast watches its dusk. One of the watch, or a soldier, who steps into that dusk is
eyed. The first to step in falls ill as a Blight person cast makes him ill (without a sound; home or to his quarters
for the night; a mission's quarry only for `ILL_TIME`); then the building rests 15 s, during which those who step in
are eyed only. A foothold healed (a fourth Blight) stops watching.

### Tier 2

**Slumber -- Heavy Air.** "Who walks in sleeps too."
For as long as a level-5 cast's sleep lasts, its circle stays. Anyone who walks into it (he was not in it at the cast)
is eyed and falls asleep for the rest of that time, as deeply as the cast's own sleepers (light size: a blow or a hurt
wakes him; dark: only a hurt). Each person once a cast.

**Cloak of Night -- Averted Eyes.** "The watch near them turns away."
One of the watch who comes within 2.0 of a person cloaked by a level-5 cast is eyed, drops whatever he is pursuing or
searching for, walks back to his post or round, and takes up no new pursuit for 6 s. Each watcher once a cast.

### Tier 3

**Unseen Hour -- Eyes Within.** "You see the watch; leavers stay blind."
While a level-5 veil hangs, every one of the watch within its radius + 4 is eyed for as long as he is there (who is
coming, at a glance). Anyone who steps inside the veil and leaves it stays blind for 6 s after: he is no witness and
reports and seizes nothing, as inside the veil.

**Dreamless -- Found by No One.** "Never found; a finder rests too."
When a level-5 cast's rest ends, each sitter is judged where he sits, by his nearest witness:
- nobody would witness him: the sitter is taken (no body, never found);
- his nearest witness may be killed: the sitter is taken (no body), and that witness is eyed, sits down where he
  stands and rests half the cast's `REST`; then the witness is judged with **no second hop**: nobody near, taken;
  somebody near, found dead as a level-1 sitter is today (a body);
- his nearest witness may not be killed (a believer, one the mission keeps alive): the witness is eyed only, and the
  sitter is found dead as today (a body).

### Tier 4

**Dread of the Dark -- The Dark Looks Back.** "Who stops to look is held too."
Anyone the dreaded ground stops at its edge (today he waits there, `Person._step_blocked`), or who stands within 1.0
of its edge for 2 s, is eyed and frozen where he stands, silent, until the dread lifts (the same hold as those inside,
under the cast's own id, so it lifts with the cast). At most 16 a cast (cost), nearest the click
first.

**Shadow Play -- The Shadows Keep Watch.** "Who comes close joins the play."
Anyone awake who comes within 1.0 of a shadow of a level-5 cast is eyed and joins the play exactly as the cast's own
people did: he becomes a shadow under the cast's id (the same one node, as at level 1) until the play ends, then wakes
with the rest. At the dark size a soldier caught so is treated as the cast treats soldiers (his shadow fades, he is
taken). At most 12 more a cast (cost).

### Tier 5

**The Swallowing Dark -- Nothing Leaves.** "Who walks out is taken too."
From the cast to the fold, anyone who has stood inside the growing circle and then walks out of it is eyed and marked
(a thin dark thread on him until the fold). At the fold, after those inside, every marked person still alive is taken
wherever he is, indoors too. The power's own sparing holds (what the mission needs, the believers as today).

**Evernight -- The Light Gives Way.** "The torchlight shrinks all night."
Each torch's light shrinks evenly through a level-5 night, from `TORCH_R` 2.5 at the fall to 1.2 as the dawn begins
(less than the huddle's 1.8), so the outer ring of every huddle falls into the dark and can be claimed like anyone.
Everything that asks "is he in a torch's light" (a claim, a take's re-check, the torch put out, the light field, the
warm island's look) reads the light's radius at that moment; a person already claimed stays claimed. Where the people
huddle does not shrink: they stand where they would at level 1, which is what leaves the outer ones in the dark. Each
torch bearer is eyed from the fall to the dawn (he is the one who sees the night).

## 8. Text and tools

- Each level-5 row's `twist_text` is the name and the short line above (the quoted words), in the style of the other
  gods' rows, short enough for the skill tree's panel.
- The `"shape"` lines stay level 1's (as the other gods').
- The tree's level rows, Remembrance's level keys 1-5 and `--bench-level=N` already work off the table.
- The aim (`Targeting`) reads the slot's level for the ring's size and the people preview, so what is ringed is what
  the cast at that level takes.
- `docs/KAK_God_Veil_Summary.md` gains a "Levels" section (tables, twists, what only the user can judge);
  `docs/KAK_God_Veil_Rulings.md` gains the build's rulings (prefix `VL`).

## 9. Checks before this is called done

- Each twist: its own checks in its power's suite (who is eyed, who is answered, the one-hop limits, the caps, the
  spared, level 4 and below do nothing, teardown when the cast ends early or is freed, a bare context).
- The Pale Eye: its own suite (mark, time out, gone when taken or indoors, the record, nothing built without a level-5
  Veil cast).
- A table check: every Veil row has five levels; level 1 equals the constants and `VeilRules.SIZES`; values never get
  worse with level; Might at level 5 within the cap.
- No reference row moves (the Veil rows, `digest`, `crowd_check`, the no-Veil controls); FLOW 209/0; the whole suite
  with no functional failure.
- Bench at level 5 (`--bench-level=5`), cast / base at most 1.55: each Tier 4-5 power alone, Evernight with Unseen
  Hour, Evernight with Dread. A level-5 cast over the bar is a finding to tell the user, with its number.
- Skill-tree clips are level 1 and are not recorded again.

## 10. Left to the builder

Where the pair lives in the table; where the dusk-by-level numbers live; the Pale Eye's file, its drawing and its cue's
recipe; how each twist finds "walks in" cheaply (a tick, not every frame for every person); how a watcher "drops his
pursuit" (reuse what an existing power does); the thread on The Swallowing Dark's marked. Every such choice goes in the
rulings as a `VL` line.

## 11. Open, for the user after play

- The numbers (all first guesses).
- Evernight's twist is the weakest fit to "the dark watches back" (it is about those who resist, not those who
  notice); the user accepted it with the rest.
- Evernight's size: 214 a night at level 1 was not yet judged; level 5 is about 280.
- Lines B and C were set aside "first", not for ever.
