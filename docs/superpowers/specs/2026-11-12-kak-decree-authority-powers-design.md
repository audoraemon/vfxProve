# KAK Decree authority powers: design

Date: 2026-11-12. Status: waiting on the user's approval.
Picks: the user's Decree Tree Picker (https://claude.ai/artifact/LpTj2Cbnkxw6p5dcfjfxTZ, ArtifactData `picks/decree`).
Research: the Justiciar and Black Emperor (Lawyer) pathways of the novel *Lord of the Mysteries* (§8).
Sister spec: `2026-11-12-kak-death-authority-powers-design.md` (Death, built in parallel on `god/death-powers`).

## 1. Intent

The user's words: "the master of a word that can bend reality. Make the area or people what I wanted to be."
The Decree god speaks law, and the town becomes what the law says. Two kinds of power, from the novel's two pathways:

- **Order** (the Justiciar): a law spoken over a place or a person binds it. Amber, bars, verdicts, bans.
- **Loophole** (the Lawyer, who becomes the Black Emperor): words twisted, rules bent or turned inside out.

Across the picking sessions the user asked for: destruction, chained stages (one cast that plays out in two or three
steps), something left behind after it lands, and powers tied to the novel. The picks below are what they kept.

## 2. The tree (the user's picks)

| Tier | Spot 0 | Spot 1 |
|---|---|---|
| 1 | **Leaving Is Prohibited** `noleave` (built, reworked: the amber cell) | **Breathing Is Prohibited** `breath` (new) |
| 2 | **Redefine** `redefine` (new) | **Bound in Law** `bound` (new) |
| 3 | **Erasing Distance** `erase` (new) | **Disorder** `disorder` (new) |
| 4 | **Eminent Domain** `eminent` (new) | **Fenced Rule** `fenced` (new) |
| 5 | **The Closing Cage** `cage` (new) | **The Sealed Verdict** `sealed` (new) |

Nine new powers and one rework. **The Bell Lies leaves the tree** (it stays built and playable in the sandbox and as a
mission power). Magnify, Curfew and Abolition stay built, outside the tree. Might per tier: 1+2=3, 3+3=6, 4+3=7,
4+5=9, 6+6=12, all under the caps 6/8/10/13/16.

## 3. Goals, non-goals, anti-goals

**Goals**
- Build the nine new powers and the amber-cell rework at level 1, castable from the VFX Sandbox, `try/` launchers and
  the god's slots. Each gets its own look and its own sounds.
- Fill the Decree row of `GodTree.TABLE` with §2.
- Decree's laws read as law: gilt letters, black ink, amber, bars and brass, Decree's existing `DecreeParts` look.

**Non-goals (this phase)**
- Levels 1-5 and level-5 twists (a later spec, as with Passage).
- Rewriting the Decree bots for the new tree (phase 2, §7).

**Anti-goals: a failure even if it technically works**
- A law that silently does nothing. Every law shows where it holds (ring, fence, letters) while it holds.
- Luck. Who dies, who is pushed and who is cut follow rules (distance, order), never a roll.
- A silent power (Redefine, The Sealed Verdict before its stroke) that raises the alarm.
- A frame-rate cliff. The Closing Cage and Fenced Rule cover large districts and must hold the frame rate in the
  220-person town (Doors of the Dead's bar: its own cost 1-5 ms a frame).
- Hard-coding into `CitizenAgent`/`Person`. Each law is a reusable status or area rule that the systems consult (§4).

## 4. Shared pieces

**4.1 Law statuses on a person (`LawMark`).** One shared, timed per-person status with an owner id, like
`Person.hold_pace`. Values: `criminal`, `officer`, `nobody` (Redefine), `bound` (Bound in Law). One helper is asked by
every place that decides whether a guard sees, seizes, strikes or reports a person:
- `escort_director._seen_by` / `_watching`, `hide_faithful_director` (inquisitors), the seizure and march code,
  `Person._fightable`, the alarm's witnesses, the bell's reporters.
- The helper's answers: `nobody` is unseen by everyone; `officer` is unseen by guards as a suspect; `criminal` is a
  target every guard goes for (a `FightRule` TARGET_ONLY fight, as Saint or Sinner does).
- Claude's call on reach: **every** sight and witness check asks it, through one helper called from
  `MissionDirector._sees` and its overrides and from every director's `witnesses()` (assassinate, procession, ringer,
  warning, witness, `temple_report._witness`, first prayers, relic run and the rest). A law that works in some missions
  and not others would be the "silently does nothing" anti-goal.
- Claude's call on what a law changes: **perception only**. Objective counts never change: a NOBODY believer still
  counts as a believer, an escort charge is still the charge, a quarry is still the quarry.
- Claude's call: one class (`src/game/crowd/law_mark.gd`), not a field per law, so later laws add a value, not a hook.

**4.2 Area laws (`LawZone`).** A law that holds inside a circle or a strip for N seconds, built like `FoldWard`
(`src/game/crowd/fold_ward.gd`): a RefCounted object the effect builds and steps each frame, registered with the crowd so
the choice code can ask `in_law(p, kind)`. Kinds: `no_leaving`, `no_breath`, `disorder`, `no_running`,
`no_arms`, `no_doors`, `no_sight`. Leaving Is Prohibited, Breathing Is Prohibited, Disorder and Fenced Rule all use it,
so Fenced Rule's NO LEAVING is the same code as Leaving Is Prohibited.

**4.3 Law rubble.** A new blocking role `&"decree"` added with `env.add_structure`, closing walk cells, and added to
the engineers' `CLEARABLE` so they can clear it like Windfall's stones. Erasing Distance and Eminent Domain leave it.

**4.4 Look.** Decree's `DecreeParts`: GILT, INK, STRUCK red, the proclamation sigil, seals, gilt waves. Amber is new:
a warm translucent gold (the Judge's resin), used by the cell and the Cage. Letters of law are drawn in gilt on the
ground where a law holds.

## 5. The ten powers (level 1)

Numbers are first drafts, tunable. **Might** is the cost to carry at level 1. **Loud** means the town notices
(alarm, panic as it reacts); **quiet** means no alarm from the cast itself.

### 5.1 Leaving Is Prohibited `noleave`: Tier 1, 1 Might, 20 s, click, quiet (rework)
- A cell of golden amber closes over a circle of 3 for 15 s.
- Inside, people still move, but nobody and nothing leaves: walkers, runners, a captor and his prisoner, hounds and
  other Visitors. Today's ring clamp stays and now holds Visitors too.
- **Walking in is free** (the user's call, 2026-11-12): the amber lets anyone in and nobody out. A guard can still step
  in to seize a trapped carter (Harvest), and debtors can still mob a trapped collector (Tax). Whoever walks in is
  trapped too.
- At 15 s the amber cracks and falls away in shards (look only, no harm).
- It stays quiet, as built today (`quiet`, `alarm` 0.5, its `q_noleave` cue): Decree keeps a quiet Tier 1 power.
- Claude's call: the old hooks stay (BARS badge, `law_held()` blinding a badged inquisitor), so the Hunt rulings that
  depend on them do not move.

### 5.2 Breathing Is Prohibited `breath`: Tier 1, 2 Might, 25 s, click, loud
- The air goes out of a circle of 2.5 for 8 s: it shimmers grey-gold and sound dies inside it.
- Whoever is inside, or walks in, starts to choke: they clutch their throats and run for the nearest edge.
- Three seconds inside kills (kill kind `choke`, a quiet collapse). Leaving saves them; stepping back in starts the 3 s
  again. Claude's call, settling the card's two readings.
- Soldiers and inquisitors choke too. Hounds and other Visitors flee it.
- **The combo is meant** (the user's call): inside Leaving Is Prohibited's cell nobody can run, so the two together
  are a sure kill.

### 5.3 Redefine `redefine`: Tier 2, 3 Might, 45 s, click, Q/E mode, quiet
Say what a person is and, for 25 s, the law agrees. Up to 3 people within 1.5 of the click. A gilt word floats over each.
- **CRIMINAL:** every guard, watchman and inquisitor who sees him goes for him (a TARGET_ONLY fight). A soldier named
  criminal is hunted by his own.
- **OFFICER:** he counts as one of the garrison. Guards do not see him as a suspect: he walks through a search and
  past a guard unchallenged. Claude's call: gates, locks and escape limits are unchanged; a closed gate stays closed
  to him.
- **NOBODY:** nobody sees, counts or reports him. Guards skip him for sight, seizure and witness.
- Seed: the Prince of Abolition, who redefines who counts as a criminal.

### 5.4 Bound in Law `bound`: Tier 2, 3 Might, 45 s, two clicks, quiet
- Click one person, then another, within 10 of each other. For 20 s a thin brass chain of light joins them and they
  share one fate.
- **Struck:** each hurt on one is dealt to the other. **Knocked down, stunned, asleep:** the other is too. **Seized:**
  the other is held where he stands while the first is held. **Dead:** both die.
- Claude's call: there is no event for stun, sleep or seizure today, so Bound polls both people every frame and mirrors
  the *onset* of each state once. A mirrored state never mirrors back (no ping-pong).
- Use: bind a soldier to a man you can reach, or an inquisitor to a marked one.
- Seed: the Mentor of Disorder, whose linked target shares damage.

### 5.5 Erasing Distance `erase`: Tier 3, 4 Might, 60 s, drag (up to 10), loud
Three stages, then what it leaves:
1. Drag a line. The distance along it is erased: a gilt seam runs down the line and the town on both sides puckers.
2. **Fold:** over 1.5 s everything within 1 of the line is pulled to the line's middle like cloth. People there are
   crushed (kill kind `collapse`). Every building the line crosses is destroyed; buildings within 2 of it crack.
3. **Spring back:** the fold snaps open. People within 3 of the line are thrown outward and knocked down.
- **Leaves:** law rubble (§4.3) in kinked heaps along the line, blocking the street until cleared.
- Seed: the Imperative Mage, who travels by erasing distance.

### 5.6 Disorder `disorder`: Tier 3, 3 Might, 45 s, click, loud
For 15 s, in a circle of 5, every choice goes wrong. Nobody is pushed or controlled: each one decides, and decides wrongly.
- The frightened flee toward the danger: `_flee_local` picks the worst direction.
- Soldiers chase the wrong man: a guard's chosen target is swapped for the farthest one in his sight.
- A shelter's door leads back out: `try_shelter` fails for people inside the circle.
- A turn for the gate leads to a dead end: `EvacuationManager.choose` picks the gate farthest away.
- Claude's call: all four read the same `LawZone` kind `disorder` (§4.2) at the choice point; there is no randomness.
- Seed: the Mentor of Disorder, whose choices go wrong and distances fold.

### 5.7 Eminent Domain `eminent`: Tier 4, 4 Might, 80 s, drag (10 long, 2 wide), loud
- Drag a road through the town. Every building, wall, stall, tree and piece of decor along the strip is claimed and torn
  down: houses split down the middle and fall to either side, walls part, stalls fly.
- People in the strip are thrown clear to the nearer side, hurt (knocked down, half their health).
- **Leaves:** a straight, clear new street, with law rubble (§4.3) piled along both sides of it.
- Seed: the Lawyer, finding a loophole in the town's own law of land.

### 5.8 Fenced Rule `fenced`: Tier 4, 5 Might, 80 s, click, Q/E mode, loud
- A fence of iron posts rises round a district of 7 for 30 s, and you write two of its rules from five:
  - **NO RUNNING:** everyone walks (`hold_pace` at walking pace).
  - **NO ARMS:** no soldier can strike or seize.
  - **NO DOORS:** nobody goes into or out of a building.
  - **NO SIGHT:** nobody sees farther than 2 (guards' sight, witnesses).
  - **NO LEAVING:** as Leaving Is Prohibited, at the fence.
- Both rules hold for everyone inside, your faithful too.
- Claude's call on the controls: the ten pairs are ten modes, cycled with Q/E, so the existing mode UI works unchanged.
- Seed: the Earl of the Fallen, who fences an area and rigs its rules.

### 5.9 The Closing Cage `cage`: Tier 5, 6 Might, once a descent, click, loud
- A ring of brass bars carved with law rises round a district of 12. Nobody can pass the bars.
- Over 30 s the bars slide in toward the centre:
  - People at the bars are pushed inward ahead of them. Someone who cannot be pushed (pinned against a wall the bars
    have not reached) is cut down.
  - Every building the bars reach is crushed and cut: cracked as the bars touch it, destroyed when they pass its middle.
- At the end, when the ring is 1.5 across, everyone still inside is crushed. Only the centre point is left standing.
- The user's idea (One Piece's bird cage), made into law.
- Seed: the Judge's Confinement, an invisible cell round an area, made to close.

### 5.10 The Sealed Verdict `sealed`: Tier 5, 6 Might, once a descent, click, quiet until the stroke
- Write a district of 10 into the brass ledger. Only you see the circle and its countdown; the town sees nothing.
- The town goes on; people walk in and out.
- At 60 s the bell strikes once, and everyone inside at that moment dies where they stands, without a sound (kill kind
  `verdict`).
- After the stroke the bodies are found like any other dead; the town reacts as usual.
- Seed: the Judge's death verdict; laws that hold once written.

## 6. Look and sound

- **Look:** gilt and ink (`DecreeParts`), plus amber (5.1, 5.9) and brass (5.4, 5.9, 5.10). Letters of law in gilt on
  the ground where a law holds. No new sprite sheets are needed: everything is procedural or particles.
- **Sound:** every power gets its own cues from `C:\BURIN_NITRO\SoundLibrary`, following
  `ability-sounds-skill-tree-first`. A quiet power plays its own `q_<key>` cue (Redefine, Bound in Law, the Sealed
  Verdict's ledger), so `test_power_sounds`'s quiet count rises. Every new catalog file gets a `loudness.tsv` row.
- Cues: amber cracking (5.1), a hollow airless hush (5.2), a gilt scratch of a quill (5.3), a chain's ring (5.4), a cloth
  tear and crash (5.5), a crooked bell (5.6), a demolition roar (5.7), iron posts driven in (5.8), grinding bars (5.9),
  one bell stroke (5.10).

## 7. Where it is built, in order

1. **Decree powers** on `god/decree-powers` (worktree `C:/BURIN_NITRO/Godot/GIT/vfxProve-decree`), cut from
   `origin/feat/god-progression` at daa0e5e5. Claude's call: it follows the user's call for Death (build on the god
   branch, where seizures, inquisitors, the Whisper wheel, recast and `AREA_STATS` live).
   - The shared pieces (§4), the nine powers and the rework, with tests, PowerBook rows, `FAMILY`, `POWER_KINDS`,
     `Targeting.AREAS`, sandbox entries, icons, `try/try_decree.bat`, sounds.
   - **The Decree bots are rewritten on the same branch, before it lands** (Claude's call, as Passage's were): The
     Bell Lies leaves Tier 1 and the cell changes, so the Tier 1 Decree bots (`god_t1.gd`, the five nights, First
     Taste, Hide the faithful) are rewritten onto Leaving + Breathing Is Prohibited, and the Decree refs re-recorded.
     A night that cannot be won is reported to the user, not tuned around.
   - Lands on `feat/god-progression` after a fetch, a trial merge (Death lands there too: both edit
     `power_book.gd`, `god_tree.gd`, `run_all.gd`), and the full gate. Post to #god-changelog.
2. **Levels.** 5 levels and a twist for all ten, a separate spec.

Rules carried over: powers are reusable effects, never hard-coded into `CitizenAgent`/`Person`; stop and tell the user at
once on any merge conflict; check before every merge.

## 8. Seeds from the novel

| Power | Seed |
|---|---|
| Leaving Is Prohibited | Judge: Imprison (amber resin) and Confinement |
| Breathing Is Prohibited | Judge: "this place prohibits" |
| Redefine | Prince of Abolition: redefines who counts as a criminal |
| Bound in Law | Mentor of Disorder: shared fate with a linked target |
| Erasing Distance | Imperative Mage: travels by erasing distance |
| Disorder | Mentor of Disorder: choices go wrong |
| Eminent Domain | Lawyer: a loophole in the law of land |
| Fenced Rule | Earl of the Fallen: fences an area and rigs its rules |
| The Closing Cage | Judge: Confinement, made to close (the user's bird-cage idea) |
| The Sealed Verdict | Judge: the death verdict, written |

## 9. Left to the builder, and open points

**Left to the builder:** exact numbers within the drafts, particle and shader technique, file layout under
`src/fx/decree/`, test shapes, and kill-kind death animations (map `choke` and `verdict` onto existing ones).

**Open:** nothing. The builder check's questions are answered in §4.1, §5.1, §5.3 and §7.
