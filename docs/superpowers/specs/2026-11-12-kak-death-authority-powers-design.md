# KAK Death authority powers: design

Date: 2026-11-12. Status: draft, waiting on the user's word.
Picks: the user's Death Tree Picker (https://claude.ai/artifact/AxpvpmrePhvY8tjthTgEVA, ArtifactData `picks/death`).
Research: the Death Pathway of the novel *Lord of the Mysteries* (Claude's notes, summarized in §8).

## 1. Intent

The Death god rules the dead; it does not just kill. The user's words: control deaths, disease and the undead.
Every death in the town should feed the next power: a plague victim gets up as your zombie, and your zombie spreads the
plague further. A Death god left alone with a town snowballs.

But not every power needs a body. Some call spirits up out of the ground and send them to do the work: haunt,
terrify, possess. The tone follows the novel: cold, silent, pale and orderly. It uses bone, pale-white fire in eye
sockets and drained colour, not gore.

## 2. The tree (the user's picks)

| Tier | Spot 0 | Spot 1 |
|---|---|---|
| 1 | Death Mark `deathmark` (built) | **Raise the Dead** `raise` (new) |
| 2 | Pestilence `pestilence` (built, moved from Tier 1) | **Gravecall** `gravecall` (new) |
| 3 | **Corpse Guise** `guise` (new) | **Walking Corpse** `walker` (new) |
| 4 | **The Gate Below** `gatebelow` (new) | **Pale Reign** `pale` (new) |
| 5 | **The Pale Serpent** `serpent` (new) | **Grave Tide** `gravetide` (new) |

That is eight new powers. The other eleven candidates in the picker stay out.

## 3. Goals, non-goals, anti-goals

**Goals**
- Build the eight new powers at level 1, playable from the VFX Sandbox and the god's slots. Each gets its own look and
  its own sounds.
- Bodies become something Death can use: the remains of the town's dead stay usable for a while (§4).
- Death's undead and spirits feel like Death's own, not Passage's Doors of the Dead (hellhounds, demons, ghosts out of
  doors) and not Dominion's mind control. Possession borrows Mind Whisper's orders on purpose (the user asked) but is
  shorter and comes through a spirit.

**Non-goals (this phase)**
- Levels 1-5 and the level-5 twists. They come after the eight are built, as with Passage.
- Rewriting the Death bots for the new tree; that comes with the levels (§7).

**Anti-goals: these would make it a failure even if it technically works**
- Gore. The undead are pale and quiet, not bloody.
- Undead that look like Passage's ghosts and demons with a new tint.
- A silent power (Corpse Guise, Walking Corpse) that raises the town's alarm.
- Luck. Raised undead pick their targets by rule (the nearest, soldiers first where stated), never at random.
- A frame-rate cliff. Grave Tide and Pale Reign must hold the frame rate in the 220-person town, as the Doors of the
  Dead had to (its own cost was 1-5 ms a frame).

## 4. Shared piece: remains

Today most bodies fade within 1.6 s (`DummyEnemy.DEATH_FADE`). Only Death Mark's body lies for 20 s (`BODY_HOLD`).

- **Remains ledger.** Only a death that leaves the body whole records a remain (the user's rule, 2026-11-12). It records
  where, when, who (role, soldier or not), what killed them, and whether the soul is still near.
  - **Leaves a body:** Death Mark (`deathmark`), the plague (`plague`), fights (`mob`, `frenzy`), soldier blows,
    bites, and Death's own kills: zombie blows, Pale Reign and the Serpent's shadow.
  - **No body:** heavy impacts (Smite `lightning`, Tsunami `water`, Tornado `wind`); crushing (`stone`, `collapse`);
    burning (`fire`, `cinder`, `nova`, `orbital`, `laser`, `solaris`); and the taken (Door to the Deep and the Gate
    Below `pit`, `gone`, `gravity`, `ice`).
  - **Silent Doom (`doom`) leaves no body either:** it should stay silent and unnoticeable.
  - A kill kind not listed leaves no body until it is added to the list.
  - A remain is usable for **45 s** (the soul for the first 15 s), then lapses.
  - A remain is used up when a power raises or moves it.
- **Only with Death.** Claude's call: the ledger runs only when the night's loadout (or the VFX Sandbox) carries a
  Death power that uses bodies (`raise`, `walker`, `gravetide`). Other missions and schools look exactly as today.
- At most 60 remains are drawn; past that the oldest lapses first.
- **Drawing.** The ledger draws every unused remain as a lying body, the person's own death pose, in one cheap layer.
  The Person node can still free as today.
- **Must not change the simulation.** Nobody reacts to a remain unless a power says so. Death Mark's crowd draw stays
  as it is. `crowd_check` and the refs must not move from the ledger alone; if they do, that is a bug.
- **Click a body.** "Click a body" powers pick the nearest unused remain within 1.0 of the click. With none in reach the
  cast is refused with the message "NO DEAD THERE", not wasted. This follows the pattern of Dominion's "NOTHING THERE
  TO COMMAND" (`Rules.recast` refusal "missed").

## 5. The eight powers (level 1)

Numbers are first drafts, tunable. **Might** is the cost to carry at level 1. **Loud** means alarm and panic as the
town reacts; **quiet** means none.

### 5.1 Raise the Dead `raise`: Tier 1, 1 Might, 25 s, click a body, Q/E mode, loud
Click a remain. Q/E picks what rises.

**ZOMBIE**
- The body gets up for 30 s with pale-white fire in its eyes. It wears its own people sprite, greyed and shambling at
  0.6 pace.
- It walks to the nearest living person within 10 and attacks. A blow knocks down; a second within 3 s kills.
- Whoever it kills gets up as another zombie, up to 3 raised in all by this cast.
- A soldier puts one down with 3 blows. The town panics at it, like a hellhound.
- Pestilence link: a zombie raised from a plague body carries the plague, and its blows infect.
- Claude's call: a zombie is a Visitor (an `Animal` with a new draw that wears the dead person's people sprite). The
  Person stays dead, so mission objectives and death tallies never see a dead person come back. The plague a zombie
  carries lives on the Visitor and infects through its blows.

**SPIRIT**
- The soul rises as a wailing spirit for 20 s. Everyone within 3 of it flees in terror, and it drifts after the
  nearest group.
- **Possession:** press a person within 4 of the spirit. The spirit enters them for **5 s** and they obey one Mind
  Whisper order: walk there, attack him, or burn that, using Whisper's own order wheel and rules.
- The possessed person's eyes glow pale green. When the 5 s end, the spirit leaves and can possess again, up to 3
  people in its 20 s.
- Possession needs a soul: a remain under 15 s old. Past that the cast is refused with the message "THE SOUL HAS GONE".

Tier 1 cap note: Death Mark 1 + Raise 1 = 2 Might, well under the cap of 6. Might 1 was picked so it pairs at Tier 1.

### 5.2 Gravecall `gravecall`: Tier 2, 2 Might, 30 s, two clicks, loud
- The first click calls three pale spirits up out of the ground, with no body needed. The second click sends them.
- They drift there through walls and haunt a circle of 3 for 20 s. People there drop what they are doing and flee.
- A soldier a spirit passes through stands frozen for 3 s.
- They look like Death's spirits (§6), not Passage's GHOST breed.

### 5.3 Corpse Guise `guise`: Tier 3, 3 Might, 50 s, click, quiet
- Mark up to 4 people in a circle of 2. For 25 s they look like the walking dead: grey, eyes down, a cold breath.
- Soldiers, watchmen and inquisitors do not see them. They are skipped as targets, witnesses and seizures, and nobody
  reports them.
- Death's own undead leave them alone.
- Made for hiding the faithful in a Hunt.
- Seed: the novel's Corpse Collector, whom mindless undead ignore.

### 5.4 Walking Corpse `walker`: Tier 3, 3 Might, 30 s, click a body then click, quiet
- Click a remain, then where it goes. It gets up and walks like anyone else, for up to 40 s, and nobody panics. It can
  go into a shelter, out at the gate, or into a crowd.
- When it arrives it lies down again. The remain moves with it and its clock restarts.
- A plague body that walks into a shelter brings the plague inside.
- A body walked indoors is hidden: its remain leaves the street drawing and stays usable only to Walking Corpse,
  which can walk it back out.
- Claude's call: there is no body-discovery system. "Hidden" means out of sight and out of reach of the other powers,
  nothing more. A body that lies down outdoors or in a crowd causes no reaction.

### 5.5 The Gate Below `gatebelow`: Tier 4, 5 Might, 90 s, click, loud
- The ground opens into a pit of 3 for 12 s, ringed in bone.
- Pale arms reach out to 6 and drag whoever they catch to the edge and under. No body is left.
- When it closes, every soul it took climbs back out as a wraith (Death's spirit, §6). The wraiths hunt soldiers for
  20 s, and one passing through a person leaves them at half pace for 4 s.
- It is the ground itself taking them down, not a door to elsewhere. That is the line between it and Passage.

### 5.6 Pale Reign `pale`: Tier 4, 6 Might, 120 s, click, loud
- The colour drains out of a district of 10 for 12 s; it turns grey and silent.
- Everyone inside slows to a crawl (0.3 pace), fires gutter, and a bell inside stops.
- Every 2 s the weakest one still inside dies without a sound. Weakest means the sick first, then the hurt, then the
  frail, then the nearest the middle.
- Every death inside rises as a pale servant (a ZOMBIE as in §5.1, grey not green-eyed) for 20 s.
- Claude's call: the picker drafted it as a Tier 5 "once a descent" with a district of 14 for 15 s. At Tier 4 it is
  smaller and has a 120 s cooldown, like the other Tier 4s.

### 5.7 The Pale Serpent `serpent`: Tier 5, 6 Might, once a descent, drag, loud
- A vast feathered serpent rises out of the ground and glides along the drag over 10 s, then circles once. It has
  white feathers over dark green scales.
- Whoever its shadow crosses dies at once, silently, with no mark. The shadow is a band about 2 wide. Houses are left
  standing.
- Whoever has a line of sight to it within 12 falls sick for 20 s: slowed, and the plague if Pestilence's is in town.
- The bodies it leaves are whole remains, ready to rise.
- Seed: the novel's Death Consul, a feathered serpent angel.

### 5.8 Grave Tide `gravetide`: Tier 5, 6 Might, once a descent, click, loud
- Every unused remain in town gets up at once, up to 30, for 40 s, and walks toward the click as zombies.
- Where the most remains lie within 4 of each other (at least 5), a giant of bones bursts up like a fountain. It walks
  the streets for 40 s, takes 12 blows, smashes walls in its way and swats soldiers.
- Death's undead within 6 of the giant move 20% faster.
- The more the town has lost tonight, the bigger the tide. With fewer than 3 remains it still raises them, but no giant.

## 6. Look and sound

**Palette:** bone white, ash grey, pale-white fire, and a cold grave-green kept to eyes and glows. No blood.

**Death's own undead and spirits**
- Zombies wear their own people sprite, desaturated and greyed, with pale fire in the eyes and a shambling gait. Use
  `PeopleArt`; no new sheets.
- Death's spirit is a thin pale shape trailing a wisp, drawn procedurally. It must read differently from Passage's
  hooded GHOST sprite: no hood, more see-through, and a face that fades in and out.
- The bone giant, the serpent and the Gate Below's arms and bone ring are the big new art.
  - The user's call: **PixelLab sheets**, as with the hellhound, demon and ghost, made before the code that animates them.
- Pale Reign is a desaturation of the ground and the people inside the circle, a shader or modulate pass.

**Sound:** every power gets its own cues from `C:\BURIN_NITRO\SoundLibrary`, and `test_power_sounds` must stay green.
- Silent powers get only a near-inaudible cold breath.
- Loud powers: a low choir or bell drone for Pale Reign; bone grinding for Grave Tide, the giant and the Gate; wind and
  feathers for the serpent.
- Sound work follows the `ability-sounds-skill-tree-first` rule.

## 7. Where it is built, in order

The user's call (2026-11-12): build on the god branch. The pieces the powers need live only there:
- Mind Whisper's order wheel and `Person.whisper_fight()`.
- `Person.hold_pace`.
- `Rules.recast`/`can_recast`.
- `Targeting.AREA_STATS`.
- The god's slots, Hunts, inquisitors and seizures.

1. **Death powers.**
   - A new branch `god/death-powers` cut from `origin/feat/god-progression`, in its own worktree
     (`C:/BURIN_NITRO/Godot/GIT/vfxProve-death`).
   - Build the remains ledger and the eight powers, with tests, sandbox entries, icons, `try/` launchers and sounds.
   - Fill the Death row of `GodTree.TABLE` with §2.
   - Lands on `feat/god-progression` after a fetch, a trial merge and the full gate. Post to #god-changelog.
   - Death reaches Develop-Main when the god branch does, on the user's word.
2. **Death bots and levels**, the same branch or the next.
   - Pestilence leaves Tier 1, so all seven Tier 1 Death bots stop working: five nights, First Taste, and Hide the
     faithful (they draft `deathmark` + `pestilence`). They are rewritten onto Death Mark + Raise the Dead.
   - The Hunt loadouts at Tiers 2-5 may keep Pestilence. Re-record the Death refs.
   - Then 5 levels and a twist for all ten, a separate spec as with Passage.

Rules carried over from the project:
- Powers are reusable effects, never hard-coded into `CitizenAgent`/`Person`; statuses and intents go through shared
  modifiers.
- Reuse what exists:
  - Visitors (summon, traits, `mark`), for the zombies and wraiths that hunt.
  - Mind Whisper's order wheel and `Person.whisper()`, for possession.
  - `Person.hold_pace`/`free_pace`, for Pale Reign's crawl.
  - `SeeThrough`, if the giant stands behind houses.
  - `Targeting.AREA_STATS`, for previews.
- Stop and tell the user at once on any merge conflict.

## 8. Seeds from the novel

| Power | Seed |
|---|---|
| Raise the Dead | Gravedigger and Spirit Guide: commanding spirits, raising servants |
| Gravecall | Gravedigger: simple orders to the spirits around |
| Corpse Guise | Corpse Collector: a corpse-cold body; mindless undead ignore it |
| Walking Corpse | Gravedigger: orders to the dead |
| The Gate Below | Gatekeeper: the Underworld Gate, grasping undead arms |
| Pale Reign | Pale Emperor: the Pale World, colour drained |
| The Pale Serpent | Death Consul: the feathered serpent angel |
| Grave Tide | The giant skeleton messenger; undead kneel to rank |

## 9. Left to the builder, and open points

**Left to the builder:** exact numbers within the drafts above, particle and shader technique, file layout under
`src/fx/death/`, and the test shapes.

**Open:** nothing; the branch and the art were the user's calls (§6, §7).
