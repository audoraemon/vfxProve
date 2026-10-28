# KAK god P3: The First Taste (rite mission spec)

Date: 2026-10-28. Status: **for the user's approval** before it is built. Branch `god/p3-rite` (from `feat/god-progression`
`a0185497`). Parent spec: `2026-10-26-kak-god-progression-design.md` (cited as §n). P1/P2 as shipped:
`docs/KAK_God_P1_Summary.md`, `docs/KAK_God_P2_Summary.md`.

P3 builds: the **Awaken** button at the cap (§9.3), the **Rite** mission type and its director, **Chain of the Forgotten**
(§11.2), the first rite **The First Taste** (§11.3, level 10), the win plate (§11.5) and **stolen gifts** (§11.4).
Numbers marked *fg* are first guesses, tuned with the scripted players. Coordinates are Aldermere ground units, snapped to
walkable ground by the director (`_walkable`).

## 0. Rules this spec must pass (§13, the mission-design lessons)

No wait over 60 s, an acting player idle 45 s at most; next item at most 45 s after the last; opposition spread more than
two Silent Doom radii (`2 x SilentDoom.RADIUS` = 1.6) apart; no luck (no street traffic); no hidden losses; the bell never
loses (`MissionDef.lantern`); moving targets edge-arrowed; tags count down; plates clear of the HUD stack, strip and slots.
The check is §6.

## 1. The Rite mission type (shared by all four rites)

| Part | Rule |
|---|---|
| Reached from | The hub's **Awaken** button (key A), shown beside Descend only while the god is capped (§8) and a rite exists for its tier. P3 has only level 10's; at 20/30/40 the button shows dim "Rite not yet written" (the `--dev` A hook stays for those). |
| Hunt first | While `hunt_due()`, Awaken leads to the Hunt, as Descend does (P2 summary, "not yet there"). |
| Prepare | Header `THE AWAKENING RITE` (gold). Rows: RITE (name, plate), WIN, LOSE, IF WON (tier, +2 points, gift), IF LOST (`Notice +25%`, "the god stays capped"). Draft = learned abilities at their levels, the god's slots and Might, seals apply (§9.1). The chain shows on its own row, "free". |
| Town and clock | The god tier's frame: Tier 1 = Unaware town, clock `TierBook.clock(tier)` (5:00) + the Faith clock. No wishes, no believers, no Faith *(ruling R1)*. |
| Director | `RiteDirector` (base): the shrine and its flame, the shard count, the marked victims, the chain, breakers, Halcyon's answer after each sacrifice, the replacement rule (§3.6). Each rite subclasses it (`FirstTasteDirector`). Data rows in a new `RiteBook` (level, id, name, victims, answer, gift). |
| Shrine | Mira's shrine, `VigilFlameDirector.MIRA_SHRINE` (-17.6, 5.0), outside the west wall at the forest edge. Its flame burns from 0:00 and grows one step per shard. Orange tag `MIRA'S SHRINE  n/3`. |
| Objectives | `Lantern shards n/3` (main); `The shrine's flame` (lost if cleansed); `Dawn`. |
| Win | The last shard. The night ends at once: no ASCEND phase, so no "caught". Plate §5. |
| Lose | The flame cleansed (§3.4), or dawn with fewer shards than needed. Nothing else. |
| The bell | `lantern = "watch"` (Tax Collector's kind): a toll turns the Lantern (clock x1.5, x2.0 burning; kill the Bearer to blind it). Never a loss. |
| Divine Power | None, won or lost (the bar is full; §11.5). |
| Leaving | P1's forfeit (§9.1): leaving Prepare is free; once the clock starts, Abandon (after a confirm that says so) or a closed game is a **lost rite**. |
| A lost rite | Night +1, a seal ticks, no Divine Power, Notice +25 (`GodNight.NOTICE_LOST_RITE`; it means exactly this, a lost or abandoned rite). The god stays capped; Awaken is offered again on the next night *(R2)*. |
| A won rite | Night +1, a seal ticks, `GodSlot.awaken()` (tier +1, +2 points, cap lifts), the gift added. Notice unchanged *(R3)*. |
| Draw and bests | A rite keeps no best and leaves `last_mission` / `before_hunt` untouched, so the next draw is as if the rite had not been played *(R4)*. Drafted abilities count as carried. |
| Rite timers | Chain, drag, muster and cleanse run in real seconds; the Lantern's rate speeds only dawn *(R5)*, so a toll never shortens a warning. |
| Board | Not on the tier tabs. On the board's DEV tab as "The First Taste (rite)" for testing and `behaviour_check` *(R6)*. |

## 2. Chain of the Forgotten (the rite power)

| Part | Value |
|---|---|
| Key, plate | **C** (free: the mission keys are 1-6, Tab, F, H, R, Q/E, Esc, F1). Its own plate, not a slot, granted by the rite, no Might. At 6 slots the row is 620 of 640 px, so the plate sits **above the slot row's right end**, 100 x 20 px *(R7)*: icon, `C CHAIN`, and `READY` / `DRAG 0:41` / `0:06`. |
| Aim | Click. Takes one **marked** victim (a lamplighter), anywhere on the map, panicking or not. Refused (slot flash, words on the HUD): `NOT A LAMPLIGHTER`, `ONE CHAIN AT A TIME`. |
| Charges, cooldown | One chain at a time. Ready again **8 s** *(fg)* after a chain ends (sacrificed, freed, died). |
| Noise | Quiet: no alarm, no danger. Only the director's people react to it (no luck: town traffic never breaks a chain). |
| The drag | The captive kneels 1 s ("the chain bites"), then walks the walk grid's path to the shrine at pace `max(0.6, path / 55 s)`: every drag takes **55 s or less** (Tier 1 paths are about 30-45 units, so 0.6-0.82 units/s, under a panic run's 1.6). The way out is the **Main Gate** (the postern is barred in an Unaware town), then west along the outside of the south wall and north to the shrine *(R8)*. |
| What breaks it | A **breaker** (the Watch, §3.3, or a marcher, §3.4) who reaches the captive (0.9, `EscortDirector.TAKE_REACH`) grips the chain: the captive stops and a red ring fills over him for **3 s** *(fg)*. A full ring breaks the chain. The grip resets if the breaker is killed, frightened, held by the god (Discord, Whisper, Leaving Is Prohibited, Death Mark's frailty), shoved off (Thornwall growing under him) or folded away (Mirrorfold). |
| Yank | While dragging, C again: the captive lurches 1.5 units on along his path, a grip resets and its breaker stands 1 s stunned. **Once per drag** *(R9; open question 1)*. |
| Freed captive | Runs in panic for the Temple's door. He stays marked and can be chained again (cooldown permitting). One who reaches the door is safe and unmarked. A setback, not a loss. |
| The god's own powers | A captive struck by them dies like anyone: wasted, never a loss (§11.2). Leaving Is Prohibited does not hold a chained captive: the chain is stronger *(R10)*. A Mirrorfold way in on his path folds him through like any walker (Passage's shortcut). |
| Sacrifice | A captive within 1.0 of the shrine (`SHRINE_REACH`) dies on its stone: +1 shard, banner `THE FIRST TASTE  n/3`, the flame grows. |

## 3. The First Taste (level 10)

Id `first_taste`. Plate: "Halcyon's lamplighters keep his light in the streets. Drag three to Mira's shrine." Lose line:
"The clergy cleanse the shrine, or dawn comes first."

### 3.1 Numbers

| What | Value |
|---|---|
| Shards needed | 3 |
| Marked victims | 5 lamplighters, all on their rounds from 0:00 |
| Clock | 5:00 + Faith clock (Tier 1) |
| The Watch | 4 soldiers at fixed posts |
| Halcyon's answer | A clergy march after shards 1 and 2: 2 clergy, then 3 |
| Muster, cleanse | 10 s at the Temple door; 12 s kneeling at the shrine |
| Cleanse needs | 2 marchers kneeling at once |

### 3.2 The lamplighters

- **Built from:** no lamplighter role exists. Each is the resident or labourer nearest his round's first lamp, made a
  lamplighter for the night (as the Tax Collector's director makes nobles), Faith set to FAITHFUL. No new art: a gold
  `LAMPLIGHTER` tag, edge-arrowed, and a small lantern glow drawn by the director.
- **Rounds:** a loop of 4 street torches/lamps in his own quarter, 4 s at each to light it, round and round all night.
  Held on his round through an evacuation (`_hold_all`). All five rounds lie in the south and west half, so every drag
  path stays under about 45 units:

| # | Quarter | Round (first guesses, snapped to the nearest torch) |
|---|---|---|
| 1 | South-west, by the postern | (-6.0, 13.5), (-6.0, 10.0), (-10.0, 9.0), (-10.0, 13.0) |
| 2 | West street | (-14.5, 9.0), (-6.5, 4.0), (-6.5, 0.0), (-12.0, 2.5) |
| 3 | Market's south end | (0.0, 7.5), (2.7, 10.5), (5.0, 7.5), (2.7, 4.0) |
| 4 | Gate plaza east | (5.5, 12.5), (9.5, 12.0), (9.5, 8.8), (6.0, 9.0) |
| 5 | Inner west | (-6.5, -4.0), (-2.0, -5.0), (-3.0, 0.5), (-6.5, 2.0) |

### 3.3 The Watch (breakers)

Four soldiers at posts on the way out, each seeing 2.5 units (`EscortDirector.SIGHT`). One who sees a captive walks to grip
him; with no captive in sight he goes back to his post. Only these four and the marchers break chains. Not replaced
when killed: each drag is a little easier.

| Post | Where | Nearest other post |
|---|---|---|
| Gate, west | (1.6, 13.6), inside the Main Gate | 2.2 (gate, east) |
| Gate, east | (3.8, 13.6), inside the Main Gate | 2.2 |
| Shrine road | (-8.0, 17.6), outside the south wall | 9.7 |
| Shrine approach | (-17.2, 10.0), outside the west wall | 12.0 |

All more than 1.6 apart: one Silent Doom takes one man.

### 3.4 Halcyon answers: the clergy march

- **When:** 10 s after shard 1 (2 clergy) and after shard 2 (3 clergy). No march after shard 3 (the night is won).
- **Muster:** the clergy nearest the Temple door gather there. Tag `CLERGY MARCH IN 0:10`, banner
  `HALCYON ANSWERS - CLERGY MARCH ON THE SHRINE`.
- **The walk:** Temple door (0.8, -5.0), down the market street, out the Main Gate, the outside path to the shrine: about
  53 units at their own pace (0.6 x 0.85-1.2), **about 90 s**. In file, kept 1.8 apart by the director (more than 1.6).
  Red tags, edge-arrowed; the leader's reads `CLERGY - SHRINE IN 1:12`. A strip row `The clergy reach the shrine` counts down.
- **The cleanse:** 2 marchers kneeling at the shrine for 12 s. Banner `THE CLERGY CLEANSE THE SHRINE`, a ring on the shrine
  and its tag counting down `CLEANSING 0:12`. Full: the flame is out, the rite is lost. A kneeler killed, frightened or
  held stops the ring (it resets when fewer than 2 kneel).
- **Stopping it:** a march with fewer than 2 marchers left who can still walk (the rest dead or fled in panic) breaks:
  banner `THE MARCH BREAKS`, the survivor goes home. A held marcher (Discord, Whisper, Leaving Is Prohibited, Thornwall,
  Mirrorfold) stays on the march and walks on afterwards: delay, not a stop.
- Marchers are breakers too: a drag that meets them can be gripped.

### 3.5 Losses and warnings

| Loss | Warning, with room to act |
|---|---|
| The flame cleansed | Muster tag 10 s; the leader's countdown tag and strip row for about 90 s; the cleanse banner, ring and `CLEANSING 0:12` tag. Never sooner than ~110 s after the shard that sent it. |
| Dawn with fewer than 3 shards | The clock, red under 30 s (`HURRY_AT`); the Lantern's rings when it turns. |
| The bell | Not a loss: turns the Lantern. |

No one's death loses, so no DO NOT KILL tag is needed. A captive's tag warns instead: `CAPTIVE - SHRINE IN 0:38`.

### 3.6 Never a dead end (the replacement rule)

If marked lamplighters left (not dead, not safe) fall below the shards still needed + 1, a new lamplighter sets out at
once from the Temple door on the round whose lamplighter is gone: banner `A NEW LAMPLIGHTER SETS OUT`. There are always
more victims than shards needed (§11.2), whatever the god kills.

### 3.7 Timeline (a median clear)

| Time | What happens | Longest wait |
|---|---|---|
| 0:00 | Intro ends. Five lamplighters on rounds, the Watch at posts. Banner `THE FIRST TASTE`. Chain ready. | 0 s |
| 0:00-0:05 | Clear the gate pair or chain at once (nearest lamplighter: #3 or #4, about 35 units out) | 0 s |
| 0:05-1:00 | Drag 1 (55 s at most); answer the Watch on the way | 0 s (acting) |
| 1:00 | Shard 1. March 1 musters (2 clergy) | - |
| 1:08 | Chain ready (8 s). Chain #1 or #4 | 8 s |
| 1:10 | March 1 sets out; at the shrine about 2:40, flame out about 2:52 unless stopped | - |
| 1:08-2:05 | Drag 2, and break or delay march 1 on the gate or the shrine road | 0 s (acting) |
| 2:05 | Shard 2. March 2 musters (3 clergy); out 2:15, at the shrine about 3:45 | - |
| 2:13 | Chain ready. Chain the third | 8 s |
| 2:13-3:10 | Drag 3; march 1 must be stopped or still delayed | 0 s |
| ~3:10 | Shard 3: the rite is won (median target 3:00-4:00 = 180-240 s) | - |
| 5:00 | Dawn (stirring Lantern after a toll at 0:40: about 3:33 real; burning: about 2:50) | - |

The longest timed wait is the 10 s muster; the longest idle gap for an acting player is the 8 s cooldown.

### 3.8 Every type can win with its Tier 1 abilities (`GodTree.TABLE` Tier 1, level 1)

| Type | Abilities (Might) | Answers the Watch | Answers a march |
|---|---|---|---|
| Ruin | Smite (1, 10 s), Ember (1, 15 s) | Smite each watchman as the drag nears him; Ember a house by the gate plaza to draw the town | Smite one: the seen kill frightens the other; the march breaks. Loud: expect a toll (x1.5) |
| Death | Death Mark (1, 20 s), Pestilence (3, 48 s) | Mark the gate pair at 0:00 and 0:20 (dead by 0:30, slow at once); mark ahead of each drag | Pestilence at the muster (sick walk slowly and die); Death Mark a marcher |
| Veil | Silent Doom (1, 10 s), Blight (2, 36 s) | Doom one watchman per cast, unseen | Doom two marchers; Blight the bell at 0:00: no toll all night |
| Passage | Thornwall (2, 42 s), Mirrorfold (3, 54 s) | Mirror in on the gate plaza path, out on the shrine road past the outside post (halves a drag, skips two posts); Thornwall shoves off a gripping breaker or walls a post off | Delay only: Thornwall across the gate mouth (25 s), Mirror the march back inside (in on the shrine road, out at the market: about +40 s). Wins by speed: march 1 must not finish before shard 3 |
| Decree | Leaving Is Prohibited (1, 20 s), The Bell Lies (2, 60 s) | Circle the gate pair as the drag passes (15 s); CALL THE GUARD pulls the shrine-road post away *(R11: the Watch answers it)* | Circle the march every 20 s (held 15 of 20): it crawls. ALL IS WELL keeps the bell quiet |
| Dominion | Mind Whisper (1, 8 s), Discord (2, 30 s) | Whisper each watchman away ahead of the drag; Discord the gate pair | Whisper marchers back toward the Temple (long delay each); Discord the file |

How I know: these are the twelve Tier 1 keys in `GodTree.TABLE` and their `PowerBook` rows; no type needs a neighbour.
Ruin, Death and Veil stop marches for good; **Passage, Decree and Dominion only delay them**, so they win by speed and the
Yank. That is the risk the scripted check must clear (§6, open question 1).

### 3.9 The scripted test player (`behaviour_check --scenario=first_taste --god=<type>:1`)

- Shared plan: chain the marked lamplighter with the shortest path to the shrine; answer every breaker within 4 units of the
  drag before he grips; Yank when a grip passes 1.5 s; after each shard, deal with the march before chaining again only if
  it is within 45 s of the shrine.
- Per type: the "answers" columns of §3.8, in that order of priority.
- Bar: for each of the six types, wins at least 2 of 3 seeds, idle at most 45 s, median clear 180-240 s. Tune in this order
  if it misses: Yank (on/off), break seconds 3 to 4, Watch 4 to 3, march 2 count 3 to 2, muster 10 to 15 s.

## 4. Stolen gifts

| Part | Rule |
|---|---|
| Stored | `GodSlot.gifts` (exists, saved, read back): the id `watchful_bell` appended on the win. Once each; never removed. |
| Reaches a night | `GodNight.def_for()` copies the slot's gifts onto a new `MissionDef.gifts` for every later Endless night: ordinary nights, Hunts and later rites. The board, the old campaign and the references never set it, so it is empty there and nothing moves. |
| The Watchful Bell | Every bell climb takes x1.2: the bellkeeper's 8 s becomes 9.6 s (God-Resistant's 5 s, 6 s); a stand-in's x1.5 stacks on it. Applied as a `climb_scale` read wherever `BellNetwork.climb` is set from a profile (setup, `raise_profile`, the reset), 1.0 by default, so a night without the gift is byte-identical *(R12)*. It touches the climb only, not the Herald's descent. |
| Shown | Hub: `Stolen gifts: The Watchful Bell`. Prepare (Endless only): a `GIFTS` row, "The bell takes 20% longer to ring". The rite's results: the plate's gift line. |

## 5. Winning and losing

- **The plate (§11.5):** the shard's light rises from the shrine to the god in slow motion (the ascend effect, larger), then
  `AWAKENED - OMEN`, `+2 ability points`, `Stolen: The Watchful Bell - a bell ringer takes 20% longer to start the toll`.
  Clear of the HUD stack and slots (it replaces them, as the ending does).
- **Results:** the rite line (won), Divine Power `none - the rite feeds no bar`, `Tier 2: Omen`, `+2 ability points`, the gift,
  the Notice (unchanged), `Night N`. Continue, Skill Tree, Faith.
- **After:** tier 2, the cap lifts to 20, the bar re-levelled at the new need (`awaken()`, Ruling P6), Tier 2 spots open in the
  tree, Might 8, Tier 2 missions drawn.
- **Lost:** results show the loss, `Lantern Notice +25%`, "The god is still capped. Awaken again when ready." The next night
  offers Awaken again (or the Hunt first if the Notice reached 100%).

## 6. Design check

| Rule | Verdict | Why |
|---|---|---|
| Every type can win with its own Tier 1 (§5.2) | **GAP** | Argued in §3.8, not proven. Passage, Decree and Dominion only delay marches; needs the scripted check per type. |
| Plates clear of HUD stack, strip, slots | **GAP** | §11.2 says "beside the slots", but six slots leave no room (620/640 px). Proposed above the row's right end; prove with photographs at 3 and 6 slots. |
| Timed wait at most 60 s | PASS | Longest is the 10 s muster; the drag is capped at 55 s by its pace. |
| Doing nothing loses | PASS | No shards by dawn loses. |
| Acting player idle at most 45 s | PASS | Chain from 0:00; 8 s cooldown between drags. |
| Chain pacing at most 45 s | PASS | The next chain is ready 8 s after a shard. |
| Median 180-240 s | PASS (to verify) | Three drags of up to 55 s plus work: about 190 s. |
| Opposition spread over 1.6 | PASS | Posts 2.2-12 apart; marchers kept 1.8 apart in file. |
| No luck | PASS | Only the director's Watch and marchers break chains; rounds are fixed loops; town traffic is ignored. |
| Hold the director's people through an evacuation | PASS | Lamplighters, the Watch and marchers are held (`_hold_all`). |
| DO NOT KILL tags | PASS | Nobody's death loses; the replacement rule keeps victims above need. |
| Instant losses warned | PASS | The only sudden loss, the cleanse, has a ~110 s countdown and a 12 s ring. |
| The winning strike never also loses | PASS | The last shard ends the night; a cleanse finishing in the same frame is checked after it. |
| The bell never loses | PASS | `lantern = "watch"`. |
| Every power open | PASS | The Endless draft (learned abilities); the chain is extra. |
| Moving targets edge-arrowed, tags count down | PASS | Lamplighters, captive, marchers; captive, march and cleanse tags count down. |
| No progress lost to luck, no hidden loss (§2) | PASS | A lost rite's cost (+25 Notice) is on Prepare and the pause confirm. |

### Open questions for the user

1. **The Yank** (C again, once per drag). *Recommend yes:* it gives every type the same floor and keeps Passage and Decree winnable.
2. **The way out:** the Main Gate (watched, drag pace scaled up to about 0.82) or open the postern for rites. *Recommend the Main Gate:* opening the postern changes the evacuation.
3. **Rites pay no Faith** (no wishes heard). *Recommend yes:* the rite is about the tier, and it keeps the director simple.
4. **A lost rite is retried the very next night** with no extra cost beyond +25 Notice. *Recommend yes.*
5. **A won rite leaves the Notice unchanged.** *Recommend yes;* the alternative is -5, as a clean win.
6. **The Watchful Bell touches the bell's climb only** (not the Herald's descent or the Lantern-Bearer). *Recommend yes.*

## 7. Rulings (my calls the parent spec leaves open)

| # | Ruling | Cost if wrong |
|---|---|---|
| R1 | No wishes, believers or Faith on a rite | Small: add wishes later, but the director must reserve their people |
| R2 | A lost rite is retried the next night | Small: one check in the hub |
| R3 | A won rite leaves the Notice unchanged | Small: one constant |
| R4 | A rite keeps no best and leaves `last_mission` | Small: a draw may repeat the night before the rite |
| R5 | Rite timers are real seconds; the Lantern speeds only dawn | Medium: if rite timers should speed up, the warnings shrink under a toll |
| R6 | Rites only on the board's DEV tab | Small: a board row later |
| R7 | The chain plate sits above the slot row's right end | Small: layout only |
| R8 | The drag goes out the Main Gate at a pace scaled to 55 s | Medium: a fast-looking haul on long paths; the postern instead changes the evacuation |
| R9 | One Yank per drag | Medium: the rite may be too easy for Ruin and Veil; tune break seconds |
| R10 | Leaving Is Prohibited never holds a chained captive | Small: Decree would block its own drags |
| R11 | The Watch answers The Bell Lies' CALL THE GUARD | Medium: without it Decree has no answer on the shrine road |
| R12 | The gift is a `climb_scale` (1.0 by default) on the bell's climb | Small: references stay byte-identical; check `digest` and `crowd_check` |
| R13 | Lamplighters are residents made lamplighters for the night; no new art | Small: art later |
| R14 | Freed captives run for the Temple and can be chained again; one who gets in is safe | Small: the replacement rule covers it |
