# KAK Veil authority powers: summary

Branch `god/veil-merge` (the three tracks and the follow-ups merged). Spec:
`docs/superpowers/specs/2026-11-19-kak-veil-authority-powers-design.md`; every decision the spec did not settle is a line in
`docs/KAK_God_Veil_Rulings.md`.

The Veil is the god of the dark and the quiet. None of its powers raises the alarm, frightens anyone or makes anyone scream, and
nothing is left to luck: who is taken is always the nearest (or the loneliest), ties broken by a fixed order.

## The law of the Veil: small in the light, full in the dark

Every Veil power has two sizes. The ground under your click decides which one you get, once, when you cast:

- **Dark ground** is a dusk patch, Unseen Hour's veil, anywhere in a NIGHT mission, or anywhere while Evernight is up.
- **Every Veil cast leaves dusk** where it lands: a violet-black circle of 3 (or the power's own area, when larger) for 20 s.
  Cast again inside it and that cast is full size, and leaves its own dusk. Let the dusk fade and you start small again.
  Four keep their own timing: Dread of the Dark lays its dusk when the dread lifts, The Swallowing Dark on the emptied ground when it
  has taken everything, a blighted building's dusk lasts the whole night, and Evernight lays none (the whole town is dark while it
  lasts).
- People in dusk see only 0.6 as far, and a death inside dusk is seen from only 0.6 as far. Dusk raises no alarm and frightens
  nobody; people walk through it as usual.
- While you aim, the ring shows the size you would get there, with a small `LIGHT` or `DARK` tag under it.
- Only a night that carries a Veil power has dusk. A god with no Veil power plays exactly as before.

## The ten powers at level 1

Sizes are written light / dark. "Taken" means gone: no body, no sound, nothing left behind.

| Tier | Power | What it does | Light | Dark |
|---|---|---|---|---|
| 1 | **Silent Doom** | Everyone within reach falls dead a moment later, unseen. | reach 0.8 | reach 1.6 |
| 1 | **Blight** (reworked) | Click a building: it rots, its light goes out, and the ground round it stays dusk until the night ends (your foothold; at most 3, a fourth heals the oldest). A building with a use (well, bell, gate, dock, temple) loses it as before. Click a person: they fall ill without a sound, carry a small green rot glyph over their head, and walk home to bed for the rest of the night. A mission's key person is only ill for 20 s (half pace); your own believers are passed over. Nothing in reach: refused (NOTHING HERE TO BLIGHT). Cooldown 20 s. | dusk 3 round the building; 1 person ill | dusk 5; the person and the 2 nearest within 2 |
| 2 | **Slumber** | Everyone in the circle sleeps where they stand for 20 s. | circle 1.5; a loud blow or a hurt wakes them | circle 3.5; deep sleep, only a hurt wakes them |
| 2 | **Cloak of Night** | The nearest few are hidden from the watch for 25 s: guards, searchers, inquisitors and witnesses look past them. They walk normally, under a dark shimmer. | 3 people within 2 | 8 people within 4 |
| 3 | **Unseen Hour** | Nothing in the circle is seen: no alarm, no fright, nobody comes. Its veil counts as dark ground. | circle 5 for 20 s | circle 7 for 30 s |
| 3 | **Dreamless** | The nearest sit down against a wall as if resting and never wake; for 20 s the town sees only people resting, then they are found dead. Anyone already asleep there is simply taken. | the nearest 1 within 1 | the nearest 4 within 2 |
| 4 | **Dread of the Dark** | For 25 s every piece of dark ground in reach becomes a wall: nobody steps in, and everyone inside freezes, silent (no walking, fleeing, shouting, ringing, fighting or seizing). No dark ground in reach: refused (NO DARK HERE TO DREAD). Its dusk is laid when the dread lifts. | reach 6 | reach 12 |
| 4 | **Shadow Play** | Everyone in the circle falls asleep for 30 s while their shadow carries on in their place: posts look manned, but a shadow sees, reports and seizes nothing. At the end the shadows lie down and the people wake. | circle 3 | circle 6; the soldiers' shadows fade where they stand and those soldiers are taken |
| 5 | **The Swallowing Dark** | A hole in the ground opens and grows at 0.5 a second (a funnel of terraces, a swirl, dark tendrils curling in); when it is full size everyone and everything inside is taken, buildings too (bare dark ground is left). It spares what the mission needs, never takes what the night wants down (a target it must raze stays to be razed), and spares the town's gates, bridges, postern, dock and fountain. Once a descent. | grows from 0 to 10 | grows from its dusk patch to 14 |
| 5 | **Evernight** | Night rolls over the whole town: every Veil power is full size anywhere and cools twice as fast; the lone are taken in groups, 5 at a time rising to 10 by the end of the night, each group claimed one take ahead (the dark climbs them; their shadows stay on the ground); up to 6 soldiers light torches and the people huddle round them (a Veil cast on a torch puts it out and takes everyone in its light); at dawn whoever shelters in a blighted building or sleeps in dusk never wakes. The town forgets the night. Once a descent. | 60 s, a group taken every 2 s | cast in a NIGHT mission: 90 s, a group every 1.5 s |

When states meet: taken beats everything; asleep beats frozen (a frozen person hit by Slumber sleeps; a sleeper is not frozen);
The Swallowing Dark and Evernight take sleepers, the frozen and shadows' owners alike.

## Review round (2026-11-21)

You played the Veil's powers and asked for seven things. All of it is looks only: no rule, size, timing, cooldown or sound cue
changed, and nothing new frightens anyone or raises an alarm. Nine skill-tree preview clips were re-recorded to show the new looks
(Silent Doom's look did not change, so its clip, the tenth, is kept).

1. **Target preview on Slumber, Cloak of Night, Dreamless and Shadow Play.** While you aim, each person the cast would take (at the
   size the ground under the ring gives) gets a small ring. Anyone the cast would kill outright (Dreamless's sleepers and shadows,
   a dark Shadow Play's soldiers) is ringed in the kill colour. The preview is the set the real cast takes, checked line for line.
   Blight's person preview likewise follows the size: 1 person in the light, 3 in the dark.
2. **More vfx on casting.** Slumber: a violet mist rolls out to the true edge of the reach, an eye opens over the click and shuts as
   they fall, silver dust settles on each sleeper. Cloak of Night: a dark cloth unfurls over the click, a strand flies to each person
   it hides and wraps them, and the cloaked carry a violet hem. Unseen Hour: see 4. Dreamless: a dark breath spreads over the reach,
   a silver thread rises over each sitter, thins as the rest runs out and snaps when they are found. Shadow Play: dark bands ripple
   out, then each shadow peels up from its owner's feet; in the dark a soldier's shadow stretches thin and fades with a ring and motes.
   Dread of the Dark: see 5.
3. **Blight's indicator.** A person made ill carries a green rot glyph above their head from the strike until they are indoors (and
   again if they come out while still ill), with a few drifting motes, unless another mark is already over his head (a Decree cell's
   bars, a Death Mark, a Hunt bearer's pennant), which Blight leaves alone. Two Blights on one person share it.
4. **Unseen Hour's blanket.** A thin violet-black sheet is thrown from the click, opens and hangs over the whole veil, its middle
   raised and its edge drooping in scallops with a fringe, a faint weave, a dark seam and a shadow on the ground; people and roofs
   under it stay readable. In the last second it lifts and fades.
5. **Dread of the Dark as a spreading wall.** A front of darkness crosses the dark ground, and as it passes, a wall of dark tongues
   rises along the border of the dreaded ground in a violet haze, with pairs of eyes opening in it. The far side stands tall; the near
   side is low and faint so the frozen people inside stay in plain sight. At the end the wall sinks.
6. **The Swallowing Dark from the ground.** It is a hole now: a funnel of slumped terraces with a swirl, tendrils of darkness curling
   in, dust falling. Just before it is full the dark rises from the ground at its rim and closes inward, taking the town black; then it
   drains back into the earth and leaves a scorched bowl of bare ground. The camera shakes a little, at the heave and at the fold
   (the only Veil power that shakes it).
7. **Evernight over the city.** A tall wall of night rises at the click and runs across the town, near-black at its foot with a ragged,
   violet-edged crown. Behind it the whole view is a violet-black night, deeper at the edges, with warm islands round each torch, a slow
   mist over the roofs, silver stars, a falling star now and then, motes of dark rising, and a pale moon in the upper right. Each person
   taken raises a small dark wisp. At dawn the wall comes back and rolls the night away, and the torches' glows fade with it. The
   night lies under your aim: the ring, the previews and the DARK / LIGHT tag stay bright. Two Evernights at once show one night,
   not a doubled dark.

Also corrected: Shadow Play's lying outline under its peeling shadows and Evernight's night wash were drawn off the town (a doubled
screen basis) and had never shown; both show now.

### For your eye

Things only you can judge in play:

- The kill colour of the target previews (Dreamless, a dark Shadow Play): does it read on lit ground, and are many rings in a crowd
  too dense at the dark sizes?
- The Cloak's violet hem: it is strong; is it too strong?
- The busy second of a dark Shadow Play (about 40 short-lived pieces as the soldiers' shadows fade).
- No mark on a blighted building (ruling VRB7): only people carry the glyph.
- The camera shake on The Swallowing Dark, at the heave and at the fold: a new thing for a Veil power (a small shake only, no sound,
  no fright). Evernight does not shake.
- Evernight's wall of night hides the town for about 2 s while it crosses.
- Evernight's night multiplies the town under it (ground, houses, people, and effects that stand among them), so those effects dim;
  effects drawn over the town, the aim and the HUD do not.
- The moon is fixed to the screen (upper right, the same size at any zoom): does that read as sky?
- Dread's wall at night: black on dark ground, it reads mainly by its violet haze and its eyes, which are small at far zoom; and
  people standing behind its far side, outside the patch, are covered by it.
- Dread's wall can shift a little on its 0.5 s refresh (it re-reads the dark), and its darkened ground and near half still draw over
  your aim ring (only its far half was moved under the aim).
- The cost of the Veil's end-game stack (final review): on a loaded machine (base 15.1 ms, about 66 fps, against about 124 quiet),
  Evernight alone 1.11 of the base, Unseen Hour alone 1.11-1.13, both 1.16-1.18; Dread cast inside Evernight (its dark size)
  2.05, and all three 2.11-2.14: over the 1.55 bar. Dread at its dark size is nearly all of it (about +15 ms); Unseen Hour's sheet
  was made cheaper this round (about -1.6 ms). Dread at its dark size needs a cost pass before this lands (not profiled yet:
  its wall, its darkened ground and its hold all grow with the reach; draw calls rise by about 430).
- Dreamless's silver thread is thin and does not show in its skill-tree clip.
- At close zoom The Swallowing Dark's fold comes in from the frame's edges (the rim is wider than the view).
- Evernight's wall of night has soft, feathered ends at the two sides of its ring, where it thins out.

## Second pass (2026-11-22)

You played the review round on the other PC and wrote three points. Spec: `docs/superpowers/specs/2026-11-22-kak-veil-review-2-design.md`;
rulings VR2S, VR2N and VR2B in `docs/KAK_God_Veil_Rulings.md`.

1. **Blight's cooldown: 36 s to 20 s.** The other Tier 1 powers run 10 to 20 s (Silent Doom 10, Smite 10, Ember 15, Death Mark 20,
   Leaving Is Prohibited 20, Skylift 20). The scripted nights were written and recorded at 36 s and keep that pace (they wait longer
   than they must), so no reference row moved. Run at 20 s, the First Prayers script casts Blight more often and loses one seed in
   three to the Gaze; the route B scripts of Last Judgement and of the night in acts (`judgement_b`, `night_b`) (which lost before) also play differently.
   A script matter, not the game's, left for the next bot pass.
2. **The Swallowing Dark's sound.** Four sounds instead of two breaths with 20 s of silence between: a deep opening at the cast (a
   sub drop, stone grinding open, a long inhale); a low rumble that swells while the circle grows; a rising rush over the 1.4 s of
   the heave; and the fold, a sub boom with an implosion, earth falling in and a 4 s tail, the loudest Tier 5 hit as played (-13.0
   against Doors of the Dead's -13.5), under which the music and the town's ambience duck by 6 dB. The town still hears nothing.
   The blurb reads "A black circle grows unseen, then the dark swallows all inside." All sources are CC0 or public domain.
3. **Evernight eats in groups.** A take every 2 s (1.5 in a NIGHT mission) as before, but each take collects a group: 5 at the
   first take, rising evenly to 10 at the last. Each group is claimed one take ahead: a pool of shadow opens under each claimed
   person and the dark climbs his body from the feet to the head, reaching it as his take comes. Where he is taken a fallen figure's
   shadow stays on the ground until the dawn fades it. A claimed person is not held: one who reaches a torch's light, goes indoors
   or is spared before his take is let go at his take: the dark stays on him until then and then falls away (indoors it falls
   away at once). One whole night by day in the test town now takes 214 people
   (182 citizens, 32 soldiers), against about 30 before.

Cost (mission bench on a machine shared with 14 to 20 other Godot runs, so read the ratios loosely; the bar is 1.55 of the base):
Evernight 1.19 to 1.46, with Dread inside it 1.36 to 1.50. Against the first pass's Evernight in the same minutes the claims,
wisps and shadows add about 2.5 ms a frame (17.2-18.8 ms to 19.7-21.7 ms). Evernight's skill-tree clip is recorded again (the
same flags, VRE10); at that size the claims are too small to show.

### For your eye and ear (second pass)

- Blight at 20 s: say if you want 15 or 25.
- Evernight's "5 - 10" is read as a rise over the night, not a random number each take. 214 people a night is most of a district:
  say if the rise should stop lower.
- The claimed keep walking and can escape into torchlight or indoors. Say if the dark should hold them where they stand.
- A claimed person's dark is drawn over walls and roofs in front of him, so you can always find him (VR2N3).
- At close zoom the pool under a claimed person can read as a small portal; the dark hides who is being eaten.
- A claimed person who reaches torchlight keeps his dark until his take, though he is already safe. A claim made before an
  Unseen Hour draws under its blanket, a later one over it (they share a layer).
- Evernight costs about 2.5 ms a frame more than before (under the bar; a cost pass can cut it if you feel it).
- No sound for each of Evernight's takes (60 s of a cue every 2 s needs your ear first).
- The Swallowing Dark's sounds were only measured, never heard: the reversed roar in the opening, the rush's hard end, whether
  the rumble carries on small speakers (it is mostly low), and whether the fold is too loud.

## How to try them

**Remembrance** (the full law, both sizes). Open the Skill Tree, pick the Veil wheel, select a power and press REMEMBRANCE ("try it,
free"). You play the capital with that one power and no cooldown. To see both sizes:
1. Cast on open, lit ground: the ring says `LIGHT`, you get the small size, and a dusk patch is left.
2. Aim inside that dusk: the ring grows and says `DARK`. Cast: full size.
3. Or press N (the DAY/NIGHT toggle): in the NIGHT memory every cast is full size.
Dread of the Dark is refused where no dark lies in reach, and in the DAY memory it is the only power you hold, so nothing has laid any
dusk yet: press N for the NIGHT memory to try it.
Blight shows both of its targets: click a house, then a person in the street.

**VFX Sandbox** (light size only; it has no people and no rules, so nothing is dark there). All ten Veil powers are in their own
"Set4 Veil" list (TAB to reach the set), in tree order, on the keys 1-9 and 0. Silent Doom and Blight moved there from Set2. Without a
crowd some show little (Slumber, Cloak, Dreamless and Shadow Play need people; Dread builds and ends at once), so their preview clips
were recorded in the town (ruling VD2); every one builds and ends cleanly with no crowd and no rules.

## The Tier 1 nights and the Veil Hunts

(Since the second pass, 2026-11-22: every result below is of scripts that pace Blight at its old 36 s; the game's cooldown is
20 s.)

The bar: Veil wins at least 2 of 3 seeds, with no stretch of more than 45 s without a cast. Each line below is the gate's own
verdict on this branch. The five Tier 1 nights were run as `bash tools/dev/gate.sh <mission> --god=veil:1 --jobs=2` (with `--board`
for The Warning); `god_gate.sh` itself, which runs all six god types, was not run. The Hunts were run as
`bash tools/dev/hunt_gate.sh --only=<hunt> --type=veil --jobs=2`, which calls `gate.sh <hunt> --god=veil:<tier> --extra=--dev-tree`.

| Night | Veil plays | Before this build | Now | Changed |
|---|---|---|---|---|
| The Warning (board) | Silent Doom, Blight | 3/3, 162 s, idle 42 | 3/3, median 158 s, idle 44: PASS | nothing |
| The Tax Collector | Silent Doom, Blight | 3/3, 132 s, idle 30 | 3/3, 132 s, idle 30: PASS | nothing |
| The Spoiled Harvest | Silent Doom, Blight | 3/3, 152 s, idle 40 | 3/3, 152 s, idle 40: PASS | nothing |
| The Lost Lamb | Silent Doom, Blight | 3/3, 50 s, idle 32 | 3/3, 50 s, idle 32: PASS | nothing |
| First Prayers | Silent Doom, Blight | 3/3, 91 s, idle 39 | 3/3, 118 s, idle 39: PASS | the bot (VE1, VE2) |
| Hunt 1, Hide the faithful | Silent Doom, Blight | 3/3, 140 / 126 / 182 s, idle 45 | 3/3, 205 s, idle 80: **FAIL** (idle) | the bot (VE3); stopped, see below |
| Hunt 2, Silence the witness | Silent Doom, Blight, Slumber | 3/3, 193 s, idle 44 (with Tsunami, later Nova) | 3/3, 206 s, idle 45: PASS | nothing (Slumber is cast) |
| Hunt 3, Expel the inquisitor | Silent Doom, Blight (Slumber drafted) | 3/3, 181 s, idle 39 (with Nova) | 3/3, 181 s, idle 39: PASS | nothing |
| Hunt 4, Break the hunt | Silent Doom, Blight (Slumber drafted) | 3/3, 177 s, idle 24 (with Nova) | 3/3, 177 s, idle 24: PASS | nothing |
| Hunt 5, Face Halcyon | Silent Doom, Blight (Slumber drafted) | 3/3, 196 s, idle 45 (with Tsunami) | 3/3, 196 s, idle 45: PASS | nothing |

Two bots needed the law. In First Prayers the dusk made the Dooms unseen, so nobody fled and the street stayed full round the
Faithful; the bot now Blights the one bystander who stands in a Doom's way (he walks home sick) and then Dooms the Faithful alone. In
Hide the faithful a Doom cast on an earlier Doom's dusk was full size and took a believer with his seizer; the bot now sizes every
Doom by the ground under it and loses no one, but the night then misses the idle bar (80 s): most likely, with its Dooms unseen, nothing rallies the
watch, and the second household waits for the chain or 2:20 with nothing to answer. That gate is stopped, not forced (ruling VE3):
passing it needs a change to the Hunt's pacing or a Veil play not yet found. No power, mission or bar was changed. "Before" is the last gate recorded in docs/KAK_God_T1_Routes_Summary.md and
docs/KAK_God_P5_Summary.md; the Hunts' third key then was Tsunami Breaker or Nuclear Nova, which the Veil tree no longer reaches.

## Reference rows

113 of the 508 reference rows were re-recorded (commit "test: re-record the 113 reference rows that cast a Veil power"); 395 are
unchanged. Each moved because its scripted night casts a Veil power (Silent Doom or Blight). Name patterns: `<mission>_play_*` and
`<mission>_b_play_*` for the Tier 1 nights, `<mission>_toll_*` for the toll nights, `hunt_play_*`, `god_veil_<mission>_play_*`,
`{first_taste,hide_faithful,silence_witness,expel_inquisitor,break_hunt,face_halcyon}_veil_play_*`, and the `capital_*` play, b_play
and toll rows of the same missions (see `git show` for the exact rows). No row of a family that casts no Veil power moved (336 rows
in 122 families, the `none` cases, the other gods' rows, the calm/fire/rite/soldiers/digest/crowd rows among them).

- **Lost rows.** Four recorded rows are losses: warning_toll_3, flame_toll_3, prayers_play_2, prayers_b_play_3. All four were
  losses on the base (acb82b96, before the Veil build) with the same reason (dawn, gaze, gaze, gaze); no win turned into a loss.
- **Families that now sit outside the gate bands** (recorded all the same; their rows cast a Veil power; gates were not run, the
  medians are those of the three recorded rows): route a (180-240 s) heart 170.4, lamb 175.8, ringers 177.3, tax 172.2, procession
  (2 wins of 3, median 390.0); route b (150-270 s) flame_b 129.7 (2 wins); capital: capital_lamb_play 246.4; night_b has no win
  (0 of 3, timeout; ruled DM-side before). Prayers' route b has no floor and passes. Toll families are reported only.

## What is left

- ~~Levels 2-5 and their level-5 twists~~: built; see "Levels (2026-11-24)" below.
- **Veil bots for Tiers 2-5.** The Tier 1 nights play Silent Doom and Blight; the Hunts' Veil bots are listed above. No bot plays
  Slumber, Cloak of Night, Unseen Hour, Dreamless, Dread, Shadow Play, The Swallowing Dark or Evernight in a tier mission yet.
- **Hunt 1 x Veil's idle** (80 s against 45; ruling VE3): a pacing change to Hide the faithful, or a Veil play for its empty stretch.
- **Painted icons** for the seven new powers. They have flat generated placeholders; the painted-icon recipe is its own task.
- **Dread near a torch during Evernight: yours to rule.** A Dread cast near a burning torch does nothing to that torch until the
  Dread lifts 25 s later; then its dusk lands on the torch, puts it out and takes the huddle in its light (VC1 with VC9). The spec
  (5.10) reads "the cast puts it out", i.e. at once. Left as built; a Dread cut short (an act change) lays no dusk at all (VG6).
- **The look and listen checks nobody has done by eye or ear:**
  - Evernight's moon: now fixed to the screen (upper right, the same size at any zoom); see the review round above.
  - Shadow Play in the dark: the soldiers' shadows fade where they stand (they do not walk off, as the spec's 5.8 has it).
  - Evernight's night is no longer mild: a violet-black shade multiplies the whole view (day frame mean 98 to 48) with warm islands round the torches; see the review round above.
  - Dreamless's clip is still subtle: the silver thread over each sitter is too thin to read at the clip's 152 x 86 size; the dark breath at the cast does.
  - The seven new cues were measured (each within 3 LU over the quiet floor, VD1) but nobody has listened to them in play.
  - The dusk's own look (does it read at a glance where the dark is?) and the `LIGHT` / `DARK` ring tag have only been seen in
    captures.
- **Gate bands (Reference rows above):** these would fail `tools/dev/gate.sh` now (times of seeds 1/2/3, s): heart_play 161.3 /
  170.4 / 173.8 (median 170.4, floor 180); lamb_play 208.0 / 175.8 / 173.1 (175.8); ringers_play 177.3 / 193.6 / 169.6 (177.3);
  tax_play 172.2 / 207.8 / 157.8 (172.2); procession_play lost / 390.0 / 390.0 (2 wins, median 390.0, ceiling 240);
  flame_b_play 126.0 / 133.4 / lost (129.7, B floor 150); capital_lamb_play 286.7 / 218.2 / 246.4 (246.4, ceiling 240);
  night_b_play lost 405.5 / 357.2 / 315.2 (0 wins; timeouts, DM-side before). The idle stretch was not measured here.
- **Landing.** The whole suite, the reference rows (the Veil-casting rows re-recorded), FLOW on a quiet machine, and the landing on
  `feat/god-progression` wait for their own steps and for your word.

## Levels (2026-11-24)

The Veil's ten powers now have five levels, and each has a twist at level 5. This settles the first line of "What is left" above:
levels 2-5 and the twists are built. The Veil bots, the painted icons and the other items there are not. Level 1 is exactly what it
was: no number and no reference row moved.

### The idea

Your words: "I want Veil god in level 5 to be feel like a real master of darkness. No one will see or barely see what's he doing or
coming after for. If someone feel his presence he'll know immediately."

So there are two halves. The god stays unseen. And if anyone does sense him, you know at once. The line all ten twists share is
**"the dark watches back"**: whoever notices a Veil power is shown to you with a Pale Eye, and the power answers him.

### What grows with level

- **The dark size grows the most.** Each power's size in the dark rises at every level. The size in the light barely moves, so the
  law of the Veil stays: small in the light, full size in the dark.
- **The dusk a cast leaves grows.** One rule for every Veil cast (it lives in `VeilRules`). The skill tree shows it as one extra row,
  "dusk", on every Veil power except Evernight, which lays none:

  | Level | 1 | 2 | 3 | 4 | 5 |
  |---|---|---|---|---|---|
  | Least dusk radius | 3.0 | 3.25 | 3.5 | 3.75 | 4.0 |
  | Dusk lasts, s | 20 | 22 | 24 | 26 | 28 |

- **Cooldowns fall** at every level. The two once-a-descent powers have none.
- **Times grow** where a power has one: sleep, hiding, rest, dread, the veil, the growth of the Swallowing Dark, the night.
- **Might.** Levels 1-2 cost the power's own Might, levels 3-4 one more, level 5 two more. At level 5: The Swallowing Dark 8 and
  Evernight 8 (16, your cap), Dread of the Dark 6 and Shadow Play 7 (13).

### The numbers, level 1 and level 5

Written light / dark. Read from `src/game/power_book.gd` as built. They match the spec's tables exactly: nothing differs. Levels 2-4
sit in between in even steps (see the tree or the book).

**Tier 1**

| Power | Stat | Level 1 | Level 5 |
|---|---|---|---|
| Silent Doom | radius | 0.8 / 1.6 | 0.9 / 2.2 |
| | cooldown, s | 10 | 8 |
| Blight | dusk round a rotted building | 3.0 / 5.0 | 3.4 / 6.2 |
| | fall ill from one person cast | 1 / 3 | 1 / 5 |
| | reach for the extra sick | 2.0 | 2.8 |
| | cooldown, s | 20 | 16 |

**Tier 2**

| Power | Stat | Level 1 | Level 5 |
|---|---|---|---|
| Slumber | radius | 1.5 / 3.5 | 1.7 / 4.5 |
| | sleep, s | 20 | 28 |
| | cooldown, s | 40 | 32 |
| Cloak of Night | reach to the first | 2.0 / 4.0 | 2.2 / 5.0 |
| | hidden at most | 3 / 8 | 4 / 12 |
| | hidden for, s | 25 | 33 |
| | cooldown, s | 45 | 37 |

**Tier 3**

| Power | Stat | Level 1 | Level 5 |
|---|---|---|---|
| Unseen Hour | radius | 5.0 / 7.0 | 5.4 / 8.6 |
| | veil lasts, s | 20 / 30 | 22 / 38 |
| | cooldown, s | 60 | 52 |
| Dreamless | reach | 1.0 / 2.0 | 1.2 / 3.0 |
| | sit down at most | 1 / 4 | 2 / 8 |
| | found after, s | 20 | 28 |
| | cooldown, s | 35 | 29 |

**Tier 4**

| Power | Stat | Level 1 | Level 5 |
|---|---|---|---|
| Dread of the Dark | reach | 6.0 / 12.0 | 7.0 / 12.0 |
| | holds, s | 25 | 35 |
| | cooldown, s | 70 | 58 |
| Shadow Play | radius | 3.0 / 6.0 | 3.3 / 7.2 |
| | lasts, s | 30 | 38 |
| | cooldown, s | 90 | 78 |

Dread's dark reach stays 12 at every level: it is already the Veil's costliest power to draw. It grows by time, and its light reach
grows so a cast in the light finds dark ground more easily.

**Tier 5** (once a descent, no cooldown)

| Power | Stat | Level 1 | Level 5 |
|---|---|---|---|
| The Swallowing Dark | final radius | 10.0 / 14.0 | 10.8 / 16.0 |
| | grows, per second | 0.5 | 0.7 |
| Evernight | night, s (day / NIGHT mission) | 60 / 90 | 68 / 102 |
| | the last take | 10 | 12 |
| | torches | 6 | 5 |

Fewer torches is less light for the town. Evernight's level-5 night takes about 280 by day (level 1 about 214).

### The Pale Eye

A pale eye opens over the head of whoever a level-5 Veil power notices. It is **for you only**: a drawing and a list. It changes
nothing the town does: no alarm, no fright, nobody hears it.

- **Edge marker.** If the eyed person is off screen, a small eye sits at the screen's edge with an arrow toward him.
- **The cue.** One soft sound, `v_pale_eye`, in the quiet band, at most once a second however many eyes open. Only you hear it.
- **How long.** 4 s unless the twist names another time (some stay open until their power ends). It closes at once, for good for that
  cast, when the person is taken, dies or goes indoors; the drawing of a dead or taken man's eye lingers where he last stood for 0.4 s and
  fades (VL69), so the one Silent Doom silences is still seen. Being eyed again later by another cast is a new entry.
- **One drawing.** One node per town, over the heads and under the aim ring. It does not use the person's badge, so Blight's glyph,
  a Decree bar or a Death Mark stay.
- **A night with no level-5 Veil power builds and draws nothing.** A test holds this for every Veil power at level 4.
- **"The watch"** in the twists means every soldier, plus whoever the night's director names (by default its faithful).
- **"Blind"** is a new timed state: a blind man is no witness and reports and seizes nothing, as if he stood in the veil. He still
  walks, flees and fights. Standing inside a veil does not blind him: only the leavers and the turned watch below are blind.

### The ten twists (level 5), as built

Each runs only at level 5 and answers only the people the twist names. None raises an alarm or a fright, none draws on luck (every
pick is the nearest, a tie to the lower id), and the town's spared are eyed at most, never answered (except where noted).

- **Silent Doom, No Witness.** When the doom strikes, the nearest witness of each victim (by today's witness rule) falls too, and is
  eyed. One hop only: that second death names nobody. A sleeping witness is answered too (VL20).
- **Blight, Watchful Rot.** A rotted building gets a rot watch that outlives the cast (it stops when the rot heals, the building is
  lost, or the town clears). The first of the watch to step into the dusk round it falls ill (home to bed; a quarry man is ill for
  20 s), then the watch rests 15 s. All who step in are eyed. A man the town spares is eyed only, and the next may fall ill (VL41).
- **Unseen Hour, Eyes Within.** The watch within the veil's radius plus 4 is eyed while it is there. Anyone who walks out of the veil is
  blind for 6 s. The veil lifting blinds nobody. Narrower than the spec in one place: the town's spared are not blinded (VL44).
- **Slumber, Heavy Air.** Anyone who walks into the circle in the open after the fall sleeps for the rest of the sleep, and is eyed.
  Those held already (asleep, a shadow, dreaded) are skipped. Your own believers and whoever the mission keeps alive are eyed but never
  slept (VL68). A violet ring marks the circle (a new look).
- **Cloak of Night, Averted Eyes.** The watch within 2.0 of a hidden person turns away for 6 s: it drops the chase, stops fighting, is
  blind for those 6 s, and is eyed. A soldier goes back to his post. A soldier you hold (Dominion) or the mission holds, and one on a
  duty, is eyed only: his hold or errand is never broken (VL67). Your believers and whoever the mission keeps alive are eyed only too (VL68).
- **Dreamless, Found by No One.** A sitter is never found: he is taken instead. The nearest witness (who would have found him) rests
  asleep for half the rest, eyed; when he has rested, the next nearest witness judges him: none near, he is taken too, else he falls.
  If that first witness is one the town spares, the sitter is killed as today.
- **Dread of the Dark, The Dark Looks Back.** Anyone who stops at the edge of the dreaded ground (he balked at it, or stood within 1 of
  it for 2 s) is held frozen until the dread lifts, eyed. Up to 16, the nearest first. Your believers and whoever the mission keeps alive
  are eyed for 4 s but never frozen, and use up none of the 16 (VL68). (Replaced 2026-11-26, see Twists, second round.)
- **Shadow Play, The Shadows Keep Watch.** Anyone who comes within 1.0 of one of the cast's shadows joins them as a shadow too (up to
  12; a joined man can draw in the next), eyed until the cast ends. Your believers and whoever the mission keeps alive are eyed for 4 s
  but never join, are never taken, and use up none of the 12 (VL68).
- **The Swallowing Dark, Nothing Leaves.** Anyone who stood inside the growing circle and walks out of it is marked (a thin dark thread
  to him, and eyed) and is taken at the fold wherever he has gone, even into a shelter. The spared are eyed and marked but only taken
  if they are inside at the fold, as today (VL13). (Replaced 2026-11-26, see Twists, second round.)
- **Evernight, The Light Gives Way.** Each torch's light shrinks over the night, from 2.5 to 1.2 round it. The huddle's slots stay where
  they were, so the dark claims more. Every torch-bearer is eyed. One wider effect than you might expect: the sky's shade is shared,
  so a level-1 night's islands sharing the sky with a level-5 night are drawn as small as the level-5 ones (look only, VL66). (Replaced 2026-11-26, see Twists, second round.)

### How to try them

- **Remembrance:** open the Skill Tree, the Veil wheel, pick a power, press REMEMBRANCE. The level keys 1-5 set the level of the
  power you try; level 5 has the twist. See "How to try them" above for both sizes.
- **One cast on the bench:** `--bench-cast=KEY --bench-level=5`, for example
  `--scene res://scenes/mission.tscn -- --bench --loadout=dread --bench-cast=dread --bench-level=5 --bench-after=4`
  (the Swallowing Dark wants `--bench-after=17`).

### For your eye and ear (levels)

What only you can judge:

- **The numbers.** All first guesses.
- **The Pale Eye's drawing and its edge arrow.** Code-drawn, tested headless only: never seen on a real screen.
- **Heavy Air's ring** (Slumber): the violet arc and faint disc. Never seen on a real screen.
- **Joined shadows** (Shadow Play): the peel, edge and marks of a joined man. Never seen on a real screen.
- **The marked's threads** (The Swallowing Dark): the thin dark thread to each marked man. Never seen on a real screen.
- **The shrinking torch glow** (Evernight): the light field, the ring, the shade's islands and the halo shrinking together. Never seen
  on a real screen.
- **The Pale Eye's cue.** Measured into the quiet band; nobody has listened to it in play.
- **Evernight's twist is the weakest fit** to "the dark watches back": it is about those who resist, not those who notice. You
  accepted it with the rest.
- **Evernight's size.** 214 a night at level 1 was not yet judged; level 5 is about 280.
- **Evernight's cost.** About 2.5 ms a frame more than before, under the bar; a cost pass can cut it.
- **No sound for each of Evernight's takes.** A cue every 2 s for 60 s needs your ear first.
- **The Swallowing Dark's sounds.** Only measured, never heard: the reversed roar, the rush's hard end, the low rumble on small
  speakers, and whether the fold is too loud.
- **Lines B and C** (other twist lines) were set aside "first", not for ever.
- **Readings an implementer made that you may want otherwise** (each is a VL line in the rulings):
  - Silent Doom's No Witness answers a sleeping witness too (VL20).
  - Blight's watch lets the next man fall ill when the first is spared (VL41).
  - Unseen Hour does not blind a spared leaver (VL44).
  - Shadow Play's joined are eyed until the cast ends, and can draw in others (VL56, VL57).
  - Slumber's twist leaves a shadow standing in the circle at the fall asleep as today (VL48).
  - Cloak turns a soldier who stands next to another hidden man (VL50).
  - The Swallowing Dark takes a sleeping marked man (VL62).
  - A turned man still obeys an ordered fight (VL37).

### Bench and checks

Bench (2026-11-25, `961a9046`, loaded machine, level 5 against the base, bar 1.55): Dread of the Dark 0.99, Shadow Play 1.23,
The Swallowing Dark 0.52, Evernight 1.25, Evernight + Unseen Hour 1.38, Evernight + Dread of the Dark 1.51 (worst single
pair 1.53). The table is in `docs/KAK_God_Veil_Rulings.md`, section "Bench". A bench on a quiet machine is still owed.

Check results on `961a9046` (2026-11-25):

- Whole suite: 360 suites in 16 parts, 24,029 checks, 0 failures, 0 script errors.
- Reference rows: 508 of 508 OK (73 Veil and mission rows, 435 others), none re-recorded.
- FLOW: 209 checks, 0 failures, run alone.
- The 36 suites of the levels (the level tables, the Pale Eye, the shared hooks, the ten twists, the ten powers) also pass
  one by one.

## Twists, second round (2026-11-26)

### Why

After reading the level-5 twists you said Dread's twist "is too much like Slumber's twist", and that the Tier 5 twists "don't feel
different from the ability". So a twist now has to add a new kind of effect, not more of what the power already does. Three
twists are replaced, on their own branch (`god/veil-twists-2`, cut from `god/veil-levels` `850e22de`). Levels 1-4 change nothing,
no number in the level tables moves, and the other seven twists stand. The full design is
`docs/superpowers/specs/2026-11-26-kak-veil-twists-2-design.md`; rulings are in `docs/KAK_God_Veil_Rulings.md` (prefix VT).

### The three new twists, as built

All three run only at level 5. In all three the town's spared (your believers and whoever the mission keeps alive) are eyed, never
taken or hurt. Whoever is taken leaves no body (the town's take, as The Swallowing Dark's: no one saw a death).

- **Dread of the Dark, The Dark Takes Who Looks.** The edge still blocks, as at levels 1-4. Anyone it stops, or who stands within 1.0
  of the dreaded ground for 2 s, is eyed and pulled into the dark: he slides 1.0 toward the dread's middle over 0.6 s while he fades
  out, then he is taken (kind `void`, no body). Up to 16 a cast, nearest the click first, a poll every 0.25 s. A soldier on duty or
  held is taken like anyone (he is eaten, not turned). The spared are eyed once, never pulled, and use up none of the 16. If the dread
  ends mid-pull the man is let go, fully visible again.
- **The Swallowing Dark, The Moon's Face.** After the fold has taken everyone inside, the emptied ground is left pitted with
  craters: dark round pits with a rim of slumped earth and a faint violet swirl at the bottom, like the face of the moon. They cover
  about a third of the circle (checked as 22 to 40 percent): 9 craters at the light size, 20 at the dark size, each radius 1.2 to 2.8.
  Placed from a seed taken from the click (the same click, the same craters), never overlapping one another, never on a gate, bridge,
  postern, dock, fountain or a building the mission needs. Whoever stands in one loses 0.25 health a second (a citizen of health 1.0
  dies in 4 s, a soldier of 2.0 in 8 s), so a quick walk through is survived. The hurt is silent: no attacker, no fright, no alarm,
  no waking; a sleeper is hurt but stays asleep. Whoever it kills is taken, no body. Each one hurt is eyed while he stands in it. People
  indoors are passed over. The craters last the rest of the mission and the town does not avoid them.
- **Evernight, The False Light.** The torches burn pale blue (0.55, 0.75, 1.0) instead of warm, with a pale halo and sparks. The
  town does not notice: people huddle round them all night. The torchlight keeps its 2.5 radius all night (the shrinking is gone), so
  the huddles grow and the takes still skip the light. In the last 5 s before the dawn every huddler and bearer is eyed, so you see who
  is about to go. At the dawn each torch flares black (14 sparks) and takes its whole huddle, the bearer too, with no bodies; the torch
  goes out; then the dawn's own rules run as today. If the mission ends before the dawn nothing flares. Two Evernights at once take a
  huddler once.

### What was removed

- Dread's old hold ("held frozen until the dread lifts") and its edge-stand freeze.
- The Swallowing Dark's marks and threads: the leavers' watch, the marked list and the take of the marked at the fold.
- Evernight's shrinking light: the end radius `END_R` 1.2, the shrink steps and the lights' resizing. Everything that read the light's
  radius now reads `TORCH_R`.

No new sound was made. The ruling about the shared sky's small islands (VL66) no longer applies, as nothing shrinks.

### For your eye and ear (second round)

Nothing here has been seen on a real screen; every check was headless. Please look at:

- The pull: the slide (1.0 over 0.6 s) and the fade of the man being taken. Is it readable, too quick, too slow?
- The craters' look: the rim, the pit, the faint swirl, how a third of the circle looks like a moon face, and whether the swirl
  spinning is noticeable or too faint.
- The pace: 0.25 health a second. Is dying in 4 s (citizen) right, or should it be slower or faster?
- The crater count and size: 9 and 20, radius 1.2 to 2.8. Too many, too big, too small?
- The pale-blue torches: is the blue clear against the night, and does it read as "wrong" rather than just cold?
- The black flare at the dawn, and the eyes opening in the last 5 s: do they warn you in time to see who is about to go?

### Bench and checks

Bench and check results: filled in by the controller.
