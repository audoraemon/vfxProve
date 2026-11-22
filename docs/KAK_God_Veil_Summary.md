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

- **Levels 2-5** and their level-5 twists for all ten powers (only level 1 is built; the skill tree shows level 1).
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
