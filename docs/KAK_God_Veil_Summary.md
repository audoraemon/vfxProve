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
| 1 | **Blight** (reworked) | Click a building: it rots, its light goes out, and the ground round it stays dusk until the night ends (your foothold; at most 3, a fourth heals the oldest). A building with a use (well, bell, gate, dock, temple) loses it as before. Click a person: they fall ill without a sound and walk home to bed for the rest of the night. A mission's key person is only ill for 20 s (half pace); your own believers are passed over. Nothing in reach: refused (NOTHING HERE TO BLIGHT). | dusk 3 round the building; 1 person ill | dusk 5; the person and the 2 nearest within 2 |
| 2 | **Slumber** | Everyone in the circle sleeps where they stand for 20 s. | circle 1.5; a loud blow or a hurt wakes them | circle 3.5; deep sleep, only a hurt wakes them |
| 2 | **Cloak of Night** | The nearest few are hidden from the watch for 25 s: guards, searchers, inquisitors and witnesses look past them. They walk normally, under a dark shimmer. | 3 people within 2 | 8 people within 4 |
| 3 | **Unseen Hour** | Nothing in the circle is seen: no alarm, no fright, nobody comes. Its veil counts as dark ground. | circle 5 for 20 s | circle 7 for 30 s |
| 3 | **Dreamless** | The nearest sit down against a wall as if resting and never wake; for 20 s the town sees only people resting, then they are found dead. Anyone already asleep there is simply taken. | the nearest 1 within 1 | the nearest 4 within 2 |
| 4 | **Dread of the Dark** | For 25 s every piece of dark ground in reach becomes a wall: nobody steps in, and everyone inside freezes, silent (no walking, fleeing, shouting, ringing, fighting or seizing). No dark ground in reach: refused (NO DARK HERE TO DREAD). Its dusk is laid when the dread lifts. | reach 6 | reach 12 |
| 4 | **Shadow Play** | Everyone in the circle falls asleep for 30 s while their shadow carries on in their place: posts look manned, but a shadow sees, reports and seizes nothing. At the end the shadows lie down and the people wake. | circle 3 | circle 6; the soldiers' shadows fade where they stand and those soldiers are taken |
| 5 | **The Swallowing Dark** | A black circle grows unseen at 0.5 a second; when it is full size everyone and everything inside is taken, buildings too (bare dark ground is left). It spares what the mission needs, never takes what the night wants down (a target it must raze stays to be razed), and spares the town's gates, bridges, postern, dock and fountain. Once a descent. | grows from 0 to 10 | grows from its dusk patch to 14 |
| 5 | **Evernight** | Night rolls over the whole town: every Veil power is full size anywhere and cools twice as fast; the lone are taken one by one; up to 6 soldiers light torches and the people huddle round them (a Veil cast on a torch puts it out and takes everyone in its light); at dawn whoever shelters in a blighted building or sleeps in dusk never wakes. The town forgets the night. Once a descent. | 60 s, one taken every 2 s | cast in a NIGHT mission: 90 s, one every 1.5 s |

When states meet: taken beats everything; asleep beats frozen (a frozen person hit by Slumber sleeps; a sleeper is not frozen);
The Swallowing Dark and Evernight take sleepers, the frozen and shadows' owners alike.

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
  - Evernight's pale moon (new in the final fix wave, spec section 6): a faint disc with a fainter halo near the top corner of the
    map, in the night's wash beside the stars, drawn in code; it fades in with the night and out at dawn. Is it faint enough, and
    in the right place?
  - Shadow Play in the dark: the soldiers' shadows fade where they stand (they do not walk off, as the spec's 5.8 has it).
  - Evernight's night is mild: the ambient is eased to about 0.86 of the day's (ruling VC8), so the town reads as dusk, not night.
  - Dreamless's clip is subtle: people sitting down against a wall looks like people resting, which is the point, but the preview
    may not read as a power at all.
  - The seven new cues were measured (each within 3 LU over the quiet floor, VD1) but nobody has listened to them in play.
  - The dusk's own look (does it read at a glance where the dark is?) and the `LIGHT` / `DARK` ring tag have only been seen in
    captures.
- **Landing.** The whole suite, the reference rows (the Veil-casting rows re-recorded), FLOW on a quiet machine, and the landing on
  `feat/god-progression` wait for their own steps and for your word.
