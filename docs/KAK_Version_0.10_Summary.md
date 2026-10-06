# Kingdoms Amid Kataclysm (KAK) — Version 0.10 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `claude/lantern-campaign-spec` (from `feat/Develop-Main` at `kak-v0.09`), milestone tags `kak-v010-m1` … `kak-v010-m5`, release tag `kak-v0.10`. v0.10 is **The Lantern campaign**: four nights in Aldermere, with a story. A forgotten god wakes weak over the town, and Halcyon, the god of the Church, will eat it if he finds it. Each night is a mission. A won night grows the god's Divine Power, a lost one is a bite, and how the player regains strength (Faith, Theft or Ruin) decides the god's title and the ending. This version brings:
- **the campaign:** a Campaign button on the title, a night screen with Cael's memory and a choice card, Divine Power that grows and is bitten, a path tally, four endings, and a `[campaign]` section in the save;
- **Halcyon's Gaze:** a 0–100 meter in the three Night 2 missions; when it is full the night is lost;
- **the Faithful and their reports:** citizens who run to the Temple when they see the god at work;
- **three Night 2 missions, one per path:** **Mira's House** (Faith), **Broken Lanterns** (Ruin) and **The Vigil Flame** (Theft), with **Halcyon's Searchlight**;
- **Night 3:** The Festival or The Procession, played as a single act at the campaign's budget; **Night 4:** Last Judgement, on the Ruin path;
- **Cael's voice:** four memory fragments, six lines spoken during missions, a line on each Night 2 choice card and four epilogues;
- **new HUD pieces:** the Gaze bar, marks over people and places, and Cael's subtitle.

It builds on v0.09's acts, v0.08's missions and loadout budget, and v0.07's soldiers. The Warning, The Long Night and Last Judgement, played from the board, are unchanged: every exact gate stayed identical through the version, except one move when the VFX branch was merged in M2 (§9). Design: `docs/superpowers/specs/2026-10-05-kak-v010-lantern-campaign-design.md`. Plans: `docs/superpowers/plans/2026-10-05-kak-v010-m1-campaign-spine.md`, `2026-10-05-kak-v010-m2-gaze-miras-house.md`, `2026-10-06-kak-v010-m3-broken-lanterns.md`, `2026-10-06-kak-v010-m4-vigil-flame.md` and `2026-10-06-kak-v010-m5-story-balance.md`.*

## 1. Concept

You are a god whose name has been forgotten for centuries, awake over one walled town. You are weak and you remember nothing of yourself. You are not alone: the soul of the man who woke you is inside you.

**The world.** Before the Church came, the people of this land prayed to many small gods. One of them was the player's. Its nature is lost, and the path the player takes decides what it becomes. The god never speaks: the player is the god, and Cael and the townspeople speak.

**Halcyon, the Lantern.** The god of the Church. He takes in his people's faith and gives back protection: good harvests, plagues that stay away, walls that hold. He never speaks and never appears as a figure. His priests speak for him and rule Aldermere through the Temple. The Feast of Lanterns is his festival, and every lantern lit is a prayer to him. He is not cruel. He simply never looks at what is done in his name. The player sees him as the Temple spire, the Gaze and the searchlight.

**Mira.** A healer who lived in the west quarter. Her grandmother taught her the old name, and she kept the god's last broken shrine at the forest edge. The Church called her a witch. Archprelate Odran signed the order and Sister Venn lit her pyre in the market square. Her prayers were the only voice that reached the sleeping god. She is dead before the game starts.

**Brother Cael.** The Temple's oracle and Mira's secret lover. His visions served the Church for years. After the burning he had one last vision: a forgotten god waking over Aldermere, and his own death as the price. He took up Mira's faith, climbed to her shrine at dusk and gave his life to finish the prayer she never could. His soul went into the god, so the god wakes with his memories. He is the game's narrator and its conscience, and he is biased.

**The awakening.** The sacrifice pulls the god out of the dark as a star falling over the Main Gate. That is the opening of Night 1.

**The danger.** If the town cries out to Halcyon (the bell, mass prayer), he turns his gaze on Aldermere, finds the god weak and eats part of it. This is why the god must stay hidden while it is weak, and why its first night is about stopping a warning. Each lost night is a **bite**; three bites and the god is gone.

**The hidden truth.** Cael's memories are biased. His vision named "a heretic who keeps the old shrine", and when Odran asked who, Cael told him. His sacrifice is atonement as much as faith. The player learns this in the last memory fragment, *The Vision*.

**The question the player carries:** Halcyon let this happen. Is the god any better?

**The cast**, as the build shows them:

| Character | Role | Where the build shows them |
|---|---|---|
| Mira | The burned healer, the god's last believer | The fragments; her house (Mira's House); her shrine (The Vigil Flame's goal) |
| Brother Cael | The oracle whose soul is in the god | Every fragment and ending; six lines during Night 2 missions |
| Halcyon | The Church's god, never seen | The Gaze bar, the searchlight, the Temple, "THE LANTERN LOOKS" |
| Archprelate Odran | High priest; signed Mira's order | Named in two fragments and in Cael's line about the Knights |
| Sister Venn | The Inquisitor; lit the pyre | Mira's House, in the clergy look; the second fragment |
| Wren | A street urchin, the god's first unwilling servant | The Vigil Flame: a lay citizen the director picks; not named on screen |
| Bram | The watchman (The Warning's messenger) | Night 1; not named on screen |
| Mayor Hollis | The Festival's Mayor | Night 3's Festival; not named on screen |

Every name is a placeholder the user may change. "Halcyon" is an ordinary English word, and the spec marks it as worth replacing with an invented name before release.

**Design goals:**
- **A story the play decides.** One shared strength (Divine Power) and a path tally that decides the god's title and the ending.
- **Fail forward, with a cost.** A lost night is a bite and the campaign goes on. Only the third bite ends it.
- **Reuse what is built.** Night 1 is The Warning, Night 3 is one of The Long Night's middle acts and Night 4 is Last Judgement, all as they play today.
- **One Gaze, three ways to meet it.** Mira's House is stealth, The Vigil Flame is stealth and timing under the searchlight, and Broken Lanterns is loud destruction that must outrun the prayer.
- **A prototype:** one town and four nights. The holy city, the capital and more Tiers come once this is fun.

## 2. The campaign

```
Night 1  The Warning                     (Tier 1, 3 slots)
   └─ Night 2  choice card ─┬─ Mira's House     (Faith)   (Tier 2, 3 slots)
                            ├─ The Vigil Flame  (Theft)
                            └─ Broken Lanterns  (Ruin)
        └─ Night 3  The Festival or The Procession          (Tier 3, 4 slots)
             ├─ Faith or Theft path: The Vision, then the ending
             └─ Ruin path: Night 4  Last Judgement           (Tier 5, 6 slots) ─ The Kataclysm
   Three bites, at any night: Eaten
```

| Night | Tier | Slots | Mission | Memory before it | Path |
|---|---|---|---|---|---|
| 1 | 1 | 3 | **The Warning** (unchanged) | F1 *The Shrine* | none |
| 2 | 2 | 3 | **A choice card:** Mira's House, The Vigil Flame or Broken Lanterns | F2 *The Pyre* | the card's own |
| 3 | 3 | 4 | **The Feast:** The Festival or The Procession, The Long Night's middle acts, each played alone | F3 *The Lanterns* | none |
| 4 | 5 | 6 | **Last Judgement** (unchanged), Ruin path only | F4 *The Vision* | none |

**The way through the screens.**
- **Title:** four buttons: **Campaign**, **Missions** (the board of single missions, also Enter), VFX Sandbox and Quit. Campaign continues the saved campaign, or begins one when there is none. If the saved campaign reached an ending the player has not seen (the game was quit on the last Results), that ending shows first. A campaign whose ending has been seen starts afresh.
- **The night screen** (`CampaignScreen`): "NIGHT 2 - TIER 2", a status line ("8 DP   3 slots   Bites 1 / 3   The Deceiver"), Cael's memory for the night, and tonight's mission: one line with its brief, or a choice card per mission. A card shows the mission's name, its path, its goal and a line at its foot in gold (Cael's, for Night 2). Left and Right (or hover) pick a card, Enter or a click chooses it, and **Choose powers** (or Enter again) goes on to Prepare once a card is chosen. **New campaign** asks twice ("Press New campaign again to start over"; a second click within 0.4 s is ignored, so a double-click cannot wipe a campaign). **Title**, or Esc, leaves. The chosen card is kept across Back from Prepare and Pause, Campaign.
- **Prepare:** the night's pool, the night's slots and the campaign's current Divine Power. Picks that no longer fit after a bite are dropped, in order, with no error.
- **The night:** the mission as it plays. Pause offers Resume, Restart, Change powers and **Campaign** (in place of Missions).
- **Results:** the mission's own results, one **Continue**, and a line on what the night did to the god: "The god grows: +3 DP, 11 DP now." / "Halcyon bites: 7 DP now. Bites 1 / 3." / "Halcyon has eaten you." Continue leads to the next night's screen, or to the ending once the campaign has one.
- **The ending screen:** see §7 and §8.

**What carries over:** the Divine Power budget, the bites, the path tally and Night 1's bell. **Each night starts a fresh Aldermere:** ruins and the dead do not carry over, only the campaign state does. If the bell rang in Night 1 (the night was lost), Night 3's act meets a warned town through `Mission.bell_rang`: The Long Night's own "bell rang" row, an Organized town with six soldiers watching the Festival's square.

**The board is left alone.** A campaign night never touches the board's bests or last loadouts: The Warning and Last Judgement share their ids with the board missions, so a campaign result goes to the campaign only. Leaving the campaign puts the board's last mission and loadout back, so Missions opens on the last board pick. A board mission played afterwards uses its own slots and DP.

## 3. Strength, bites and paths

**Divine Power is a loadout budget, as since v0.08.** Nothing is spent during a mission; the budget sets what can be drafted.

| | Night 1 | Night 2 | Night 3 | Night 4 | After the finale |
|---|---|---|---|---|---|
| Slots | 3 | 3 | 4 | 6 | |
| DP, every night won with no bonus | 6 | 8 | 10 | 12 | 14 |
| DP, a bonus earned every night | 6 | 9 | 12 | 15 | 17 |

- **Start:** 6 DP (`START_DP`).
- **A won night:** +2 DP (`WIN_DP`). **A bonus objective:** +1 more (`BONUS_DP`). At most one bonus counts per night, however many are earned. Last Judgement has no bonus objective, so a real campaign tops out at 17.
- **A lost night is a bite:** −1 DP for the rest of the campaign (`BITE_DP`), never below 4 DP (`MIN_DP`). A Night 1 loss leaves 5 DP for Night 2, which is exactly what each Night 2 default loadout costs.
- **The campaign goes on after a loss** (fail forward). After Night 3 on the Faith or Theft path it reaches that path's ending even if Night 3 was lost.
- **Three bites** (`MAX_BITES`): Halcyon has eaten the god and the campaign ends with *Eaten*. This holds at any night, Night 3 included.
- **Losing the finale** is a bite, and Last Judgement is played again until it is won or the god is eaten.
- **`MAX_DP` is 18:** `START_DP + 4 × (WIN_DP + BONUS_DP)`, the formula's ceiling if the finale had a bonus. It is what a hand-edited save is pulled back to. (M5 first set it at 15, which clamped a won finale's saved 17 back to 15; the final review's tidy-up raised it.)

**The three paths.**

| Path | Title | Strength comes from | Night 2 mission |
|---|---|---|---|
| **Faith** | The Prophet's God | Converting the Grieving into Believers | Mira's House |
| **Theft** | The Deceiver | Stealing what Halcyon gave the town | The Vigil Flame |
| **Ruin** | The Kataclysm | Destroying Halcyon's anchors and draining their power | Broken Lanterns |

- **The path tally:** each night that belongs to a path adds 1 to it when played, won or lost. In the prototype only Night 2 belongs to a path, so the path is the Night 2 mission chosen. The tally is kept as a count so later Tiers can add path nights. A tie goes to the most recent path night.
- **Before any path night** the god's title is *The Forgotten*.
- **The path decides:** the title shown on the night screen and the ending screen; what follows Night 3 (the Ruin path plays Night 4, Faith and Theft go to their ending); and the ending.
- The spec also tied each path to Authorities (Faith: Dominion; Theft: Veil and Disorder; Ruin: Ruin and Life/Death). Nothing in the build reads that. The paths differ by mission and pool, and the VFX merge has since folded Disorder into Dominion and renamed Life/Death to Death.

| Ending | Reached | The Vision first? | A playable last night? |
|---|---|---|---|
| **The New Faith** | Faith path, after Night 3 | yes | no: the ending screen only |
| **The False Lantern** | Theft path, after Night 3 | yes | no: the ending screen only |
| **The Kataclysm** | Ruin path, Night 4 won | no (it was shown before Night 4) | Last Judgement |
| **Eaten** | the third bite | no | no |

## 4. Halcyon's Gaze

- **The meter** runs from 0 to 100 and never falls during a night. A HUD bar under the clock shows it, and the objective panel reads "Halcyon's Gaze 40%". **A full Gaze loses the night** (the act-end title is THE LANTERN LOOKS).
- **Only the three Night 2 missions have one.** The Warning, The Long Night's acts and Last Judgement keep their own rules and show no Gaze.
- **Who sees a death:** any living person, citizen or soldier, not inside, within 2.0 of the body (`Crowd.DOOM_WITNESS`, Silent Doom's own witness rule), judged once a cast's other victims have fallen, so a cast's victims never witness each other.

| Source | Spec | Mira's House | Broken Lanterns | The Vigil Flame |
|---|---|---|---|---|
| A death someone sees | +10 | +10 | **+0.5** (×0.05) | +10 |
| Each Faithful praying | +1 a second each, at most +6 a second | no prayer | **×0.05**: 0.05 a second each, at most 0.3 | **×0.5**: 0.5 a second each, at most 3 |
| A report reaching the Temple | fills it | fills it | no reports | fills it |
| The bell ringing | fills it | fills it | fills it | fills it |
| A beam touching Wren | +50 | none | none | +50, once each time he comes into a beam |

**The Faithful and their reports.**
- **The Faithful** are Halcyon's priests (every cleric in the town) and devout lay citizens spread through it, marked by a new `CitizenProfile.Faith` flag (`NONE`, `FAITHFUL`, `GRIEVING`, `BELIEVER`): 12 besides the clergy in Mira's House, 20 in the other two.
- **A report** (`TempleReport`) is one Faithful running, as a duty, to the Temple's door, re-aimed every 0.5 s. Within 1.0 of the door it is delivered and fills the Gaze.
- **Killing the carrier** with nobody living within 2.0 of the body ends the report. A death that is seen passes it to the nearest witness, who runs on. This is The Warning's messenger-and-relay logic, written fresh so The Warning's exact checksums could not move.
- **A carrier who is frightened, confused or whispered** drops the run and takes it up again once back on his feet. Only a relay overrides a fright.
- **A Faithful held by the god** (Discord's confusion, or a Mind Whisper) sees nothing. This gives Discord its work in the Vigil missions.

## 5. Night 2: the Vigil

All three missions take place on the night of the **Vigil**. A priest, the **flame-bearer**, carries the Temple's eternal flame in a silver lantern, walking with two acolytes (the clergy nearest the Temple's door, else any Faithful). They are a moving obstacle in each mission.
- **The town** is Unaware, as in The Warning: Organized's bell and fire brigade, but no escorts.
- **Pools:** Mira's House and The Vigil Flame: Mind Whisper, Silent Doom, Will-o'-Wisp, Discord, Thornwall. Broken Lanterns: those five plus Heaven Splitter, Tornado Tempest, Dragonfire Parade and Gravity Distortion.
- **Default loadouts**, 5 DP each, so each fits a Night 2 played after a bite: Mira's House Mind Whisper, Will-o'-Wisp, Discord; The Vigil Flame Mind Whisper, Discord, Will-o'-Wisp; Broken Lanterns Heaven Splitter, Silent Doom, Discord.
- **`VigilRoute`** walks the bearer point by point with the acolytes keeping beside him. A fright stops him, and he takes the route up again where he left it. It has opt-in switches, all off by default: `loop` (round again), `divert()` (turn aside to one place), `pass_flame` (a dead bearer's flame goes to the first living acolyte) and `shorten_to()` (straight to one place, where it ends).

### 5.1 Mira's House (Faith), 2:30

**Premise.** Mira's house, the house nearest (−12, 2) in the west quarter, has been shut since the burning. Inside are her hidden shrine and Cael's journal of his last vision. Lead the right people there without the Faithful noticing.

- **The Grieving:** **12** citizens, the lay citizens nearest her door, with a faint gold mark. Only they can be converted.
- **Conversion.** A Grieving citizen brought to the door goes in and reads for **8 s**, then comes out a **Believer** (an ember-orange mark) and goes back to their day. They are brought by a **Mind Whisper** (whispered to within 0.7 of the door or any face of the house) or lured by a **Will-o'-Wisp**'s light that stands by the house. A citizen who merely stops by the house to look at something else is not brought.
- **A seen entry.** A Faithful within 3.0 of the door when a Grieving citizen would go in turns them away and runs to the Temple with a report. A Faithful who sees a Believer come out reports too. A Faithful held by Discord or a whisper sees nothing.
- **Win:** at dawn (2:30), at least **4** Believers are alive and outside the house. The night is always judged at dawn: it never ends early on a win. **Lose:** the Gaze fills, or dawn finds fewer than 4 ("TOO FEW BELIEVE").
- **Bonuses** (one counts): **Pure faith**, nobody dies; **The journal**, the last Believer to finish reading carries Cael's journal, saved if they are alive and outside at dawn.

| Time | Event |
|---|---|
| 0:40 | **The Inquisitor.** Sister Venn, the cleric nearest the Temple, searches the west quarter house by house: 3 s at each of the six houses nearest Mira's door (the farthest first), then at Mira's door. If anyone is inside when she arrives, a report starts at once. Cael: "Venn. She lit Mira's pyre." (not said if she is dead, or already carrying a report, when it fires) |
| 1:15 | **A believer cries out.** The newest Believer outside runs 3 units into the street crying. For 15 s whisper them back into the house, or silence them. If a Faithful is within 6.0 when the 15 s end, it is reported. The HUD's arrow follows them |
| 1:45 | **The Vigil passes.** The bearer and two acolytes walk past the door along a short route, and up to four more Faithful line the street within sight of the door, for 30 s |
| 2:00 | **They burn her house.** The priests set it alight. Everyone inside runs out into the street in a fright, unconverted if their reading was not done, and nobody can go in after. Cael: "They're burning her again. Get them out." The roof falls at dawn and kills anyone still inside (normally nobody) |

### 5.2 Broken Lanterns (Ruin), 3:00

**Premise.** Halcyon's six wayside shrines anchor his protection over the town. Break them before the Vigil relights them, and drink what was in them.

- **The shrines:** a new structure kind, `Structure.Kind.SHRINE` (last in the enum): a stone post with a lantern niche, 40 health, drawn by the procedural art on both art paths. Six stand at fixed spots on the Vigil's route. Its role is `shrine`, which is not one of `Rules.BUILDING_ROLES`, so a shrine is never a building in the tally, the chain or the score. They are placed only by this mission's director, never in the town layout, so every other mission's town and the digest are unchanged.
- **Draining.** A broken shrine is **drained** once it has stayed broken for **20 s**. A drained shrine is gone for good and cannot be relit.
- **Relighting.** The Vigil loops round the six shrines. The bearer turns aside for the nearest broken shrine not yet drained, and reaching it within 1.2 before it drains, he relights it: it stands again, whole. A shrine relit and broken again starts its drain over from 20 s. When the bearer dies, the first living acolyte takes the flame up ("AN ACOLYTE TAKES UP THE FLAME"); only with all three dead does relighting stop.
- **Prayer.** Each shrine broken tops every standing shrine up to **3** Faithful sent to pray on a ring round it. Their prayer feeds the Gaze (at the scale in §4).
- **1:30, the Lantern Knights.** Four **Lantern Knights** come from the Temple and guard the standing shrines, two places to a shrine. A Knight is a soldier with three times a soldier's health (`Person.Corps.KNIGHT`, last in the enum): a gold tabard on the procedural art, the escort's sprite on the sprite path, and no other corps' work (the rally, the marshals, the escorts) takes a Knight. A shrine with a living Knight within 1.5 **takes no damage**: it only shakes. A Knight cannot be confused, whispered, lured or frightened, so he has to be killed first, and a Heaven Splitter's line strikes people before stones. Cael: "Odran's knights. He's frightened."
- **The last shrine.** When five are drained, up to **15** Faithful kneel round the sixth on two rings (6 and 9), and the ring is topped up every half second from the Faithful who are free: the dead are replaced and those back on their feet come. Strike through them (faster, more Gaze from witnessed deaths) or draw them away first (safer, slower).
- **Win:** all six drained (the night ends at once). **Lose:** the bell rings; the Gaze fills; or dawn finds a shrine standing ("THE LANTERNS BURN ON"). The Faithful make no reports here: Ruin is loud, and their answer to a broken shrine is prayer.
- **Bonus, Through the faithful:** the last shrine breaks with at least 10 of its kneelers within 2.0 of it, counted the step before the blow so a strike that kills kneelers as it breaks the shrine still counts them. **Unreachable in live play** (decision (b)).
- **Cael:** "Feel that? That was his." at the first shrine drained, once a night.

### 5.3 The Vigil Flame (Theft) and Halcyon's Searchlight, 3:00

**Premise.** Halcyon's eternal flame holds part of the power he gave the town. A god cannot hold it: a mortal hand must take it.

**Phase 1, the swap.**
- **The Vigil** walks the six shrines' route (their points, with no shrines placed), looping, at half the walkers' own pace. The bearer walks at most 0.85 of his slowest acolyte's pace, so both acolytes keep beside him. The flame passes on if he falls. With all three dead, the lantern lies where the last fell.
- **Wren.** At **0:50** the living lay citizen nearest the lantern who is not of the Faith becomes Wren and comes to watch it from 3 units. A pale blue diamond and the HUD's arrow mark him. If nobody is left to be him, the night is lost at once ("THE BOY IS DEAD"). Cael: "The boy wants that lantern. Let him have it."
- **The swap.** Whisper Wren to within 1.0 of the lantern and he takes hold. The swap takes **3 s**, while he keeps within 1.6 of the lantern on his duty (so a walking bearer does not break it; a fright, a hold or distance does, and it then starts again from 3 s). It is judged as it completes by Silent Doom's witness rule: a Faithful other than the bearer within 2.0 of Wren, not held by the god, sees it and reports it. The acolytes walk 0.7 from the bearer, so they must be drawn off, held or killed first. Left **30 s** without a whisper (until 1:20), Wren tries the swap himself.
- **1:30, the route shortens.** While the flame is still in its lantern, a suspicious priest sends the Vigil straight back to the Temple. The bearer within 1.0 of its door with the real flame keeps it, and the night is lost ("THE FLAME IS KEPT"). Swapped before 1:30, the event is dropped and the Vigil keeps circling.
- A seen swap starts a report. Phase 2 begins either way.

**Phase 2, the flame home, under the Searchlight.**
- **Wren carries the flame to Mira's shrine**, a marked spot outside the west wall (the ground at (−17.6, 5), not a structure), at half his pace. Within 1.0 of it the shrine relights with the god's own flame ("MIRA'S SHRINE BURNS AGAIN"), the beams die and the night is won.
- **The swap wakes the light.** The Temple's spire flares ("THE SPIRE FLARES"). Cael: "He's looking. Don't let him see the boy."
- **A beam** is a pool of light, radius 2, on the ground, swept round the spire. It turns once in 40 s while reaching in and out between 5 and 26 units over 30 s, so at its farthest it lights ground 28 units from the spire, past the walls. It moves at most 8 units a second, so it slides rather than jumps. Only the pool touches; the cone is drawn down to it.
- **One beam first, a second 30 s after the swap** ("A SECOND BEAM"), turning the other way.
- **A Will-o'-Wisp is a decoy:** the beam nearest it goes there and stays 5 s.
- **In the clock's last 20 s** a beam stops to search at the latest noise. Every cast but Mind Whisper (it speaks in the mind) and every death is a noise, a newer noise moves the beam, and the latest counts even if it was made before the light woke.
- **A touch** on Wren adds +50 Gaze, once each time he comes into the light (two fill the Gaze). A Faithful a beam touches stops and prays 5 s where he stands. The Vigil's walkers and report carriers never stop.
- **Tools:** Mind Whisper steers Wren; Discord makes noise that pulls a searching beam, and blinds the acolytes; Will-o'-Wisp is the decoy; Thornwall's existing wall blocks walkers, so it keeps Faithful off his route.
- **Look** (`SearchlightFx`): the spire glows like a lighthouse (a lamp 140 px up), each beam is an additive gold cone falling onto its pool with dust drifting in it, each pool is registered with the `LightField` so building faces and people in a beam light up, and the town is dimmed under it. Each beam fades in and out over 1 s on its own.
- **Win:** the flame home. **Lose:** the Gaze fills, Wren dies or never comes, the bearer keeps the flame, or dawn comes first ("DAWN FINDS THE FLAME"). **Bonus, Unseen hands:** no beam ever touches Wren.
- **Results titles** (also the banner as the night ends) for the three: THEY BELIEVE, TOO FEW BELIEVE, THE LANTERNS ARE DARK, THE LANTERNS BURN ON, THE FLAME IS STOLEN, THE FLAME IS KEPT, THE BOY IS DEAD, DAWN FINDS THE FLAME, THE LANTERN LOOKS.

## 6. Night 3 and Night 4

**Night 3, the Feast of Lanterns.** The night screen's card offers **The Festival** or **The Procession**, The Long Night's two middle acts, played alone as a night of one act with their current rules, timed events and bonuses (v0.09 §2).
- **The Festival (2:30):** 80 citizens fill the market square; the bonfire lights at 0:45, the Mayor speaks at 1:30, the guard closes the square at 2:30. Win: 50 of the 80 dead or fled. Bonus: **Before the bell**.
- **The Procession (2:30):** the Prince, four escorts and six attendants walk from the Citadel to the dock; the blessing is at 1:00, the ship docks at 2:00. Win: the Prince dead before he boards. Bonus: **A quiet succession**.
- **The town** comes from Night 1: Unaware, or Organized after a lost Night 1 (six soldiers watch the Festival's square). The card's line says which: "The bell rang: soldiers watch the square." / "The town suspects nothing." / "The bell rang: his escort is wary." / "The Prince travels light."
- **The budget:** 4 slots and the campaign's current DP, not The Long Night's 14. A run that won Nights 1 and 2 with no bonus has 10.
- **An unscored night.** The Feast's results are its own: its goal, its bonus and its time, with no rank (M5). A one-act night cannot reach The Long Night's three-act thresholds, and the campaign never used the score. The Long Night on the board is untouched.
- **Measured at 10 DP:** both acts are won 3 of 3 (§10).

**Night 4, Last Judgement** (Ruin path only). The mission as it plays today (v0.08): destroy the Citadel and break City Stability before the 6:00 clock, or lose to 50 escapes. It has 6 slots and the campaign's DP, 12 on a run with no bonus, and its town is the difficulty chosen on Prepare (Organized by default). Winning it is the Kataclysm; losing it is a bite and the finale is played again. **Whether it can be won at 12 DP is not shown by the scripted casters** (§10, decision (h)).

## 7. How the story is told

All text, no voice acting, and in M5 by the user's decision no new art: no PixelLab portraits or panels, no new images or fonts. Every word the player reads in the story lives in `CampaignText`, so a writing change never touches logic.

**Memory fragments** (the night screen shows the night's fragment; F4 also opens the Faith and Theft endings):

| | Title | Text |
|---|---|---|
| F1, before Night 1 | The Shrine | "I climbed to her shrine with the dusk bells behind me. Mira kept it for a god no one remembered. I never learned your name. She knew it. Take what's left of me. Wake." |
| F2, before Night 2 | The Pyre | "Odran read the order. Venn lit the wood. I stood on the Temple steps and said nothing. She looked for me in the crowd. Tonight they carry his flame through the streets as if nothing happened." |
| F3, before Night 3 | The Lanterns | "She hated the Feast. Every lantern is a prayer to him, she said, and he never looks at who lights them. Tomorrow the whole town lights one." |
| F4, before Night 4, or before the Faith and Theft endings | The Vision | "My vision said a heretic kept the old shrine. Odran asked me who. I told him. That is why I gave you my life. Not faith. Debt." |

**Cael's lines during missions** (a subtitle on the HUD, §8):

| Mission | Event | Line |
|---|---|---|
| Mira's House | Venn sets out (0:40) | "Venn. She lit Mira's pyre." |
| Mira's House | The house burns (2:00) | "They're burning her again. Get them out." |
| The Vigil Flame | Wren comes (0:50) | "The boy wants that lantern. Let him have it." |
| The Vigil Flame | The swap wakes the light | "He's looking. Don't let him see the boy." |
| Broken Lanterns | The first shrine drained | "Feel that? That was his." |
| Broken Lanterns | The Knights come (1:30) | "Odran's knights. He's frightened." |

Each line comes after its event's own guard, so a line whose moment never comes is never spoken: no Venn line if she is dead or carrying a report, no Wren line if nobody can be Wren, no fire line if the house is already down. The first-drained line is said once a night.

**Choice cards** show the mission's goal and a line at the foot. Night 2: Mira's House, "She'd want them to know you. Let them find her words."; The Vigil Flame, "He gave this town his light. Take it back."; Broken Lanterns, "Break his lanterns. Let him feel how small his town is." Night 3's cards use The Long Night's town lines (§6).

**Endings** (a title, a page and Cael's epilogue; the last page closes with "The Deceiver   Nights won 2   Bites 1 / 3"):

| Ending | Epilogue |
|---|---|
| The New Faith | "They pray at her shrine now, quietly, in the dark. They don't know your name either. They call you hers." (a note: "A playable last night for this path comes later.") |
| The False Lantern | "The lanterns still burn and they still pray to him. But it's you who hears them now, and he hasn't noticed yet." (the same note) |
| The Kataclysm | "There's no one left to light a lantern. He's starving. So are you. Was this what she prayed for?" |
| Eaten | "He found us. I'm sorry, Mira." |

## 8. The HUD, the screens and the save

**The HUD** (`ui/hud.gd`), all new in v0.10:
- **The Gaze bar:** 120×4 px under the clock, on a dark plate, filled from gold to red as it fills. Drawn only when the mission's director keeps a Gaze (`Hud.gaze_of()` returns −1 otherwise). The objective panel adds "Halcyon's Gaze 40%".
- **Marks:** a small diamond over each marked person or place (`MissionDirector.marks()`), 4 px half size with a dark 1-px edge, 22 px above the feet, following the person and the camera. They are drawn first, so every other HUD element covers them and none is hidden. M2 drew them 2 px; M5 doubled them and gave them an edge (they read too small, and were lost on the cobbles), then moved them under every element.

| Mission | Marks |
|---|---|
| Mira's House | The Grieving (faint gold), Believers (ember orange) |
| Broken Lanterns | A standing shrine (Halcyon's gold), a broken shrine not yet drained (ember) |
| The Vigil Flame | Wren (pale blue), the real flame in its lantern or where the last bearer fell (gold), Mira's shrine (ember) |

- **The arrow** (v0.08's messenger marker) also follows the crying Believer, the bearer on his way to relight a shrine, and Wren.
- **Cael's subtitle:** a dark plate under the banner's bar (y 140), his name ("CAEL") small in gold, then the line in the body's light text. It stays up 4 s (a banner stays 2.2 s), comes up over 0.2 s and fades over its last 0.4 s, text shadow included. It has a queue of its own: lines wait their turn, only the one on screen ages, and banners keep their own pace. `Rules.subtitle(text)` is the signal; `MissionDirector._say(event)` looks the line up in `CampaignText.CAEL_LINES` by the mission's id and speaks it.
- **Objective lines:** "Believers 2 / 4"; "Shrines drained 3 / 6"; the flame's "The flame: swap it", "Swapping 2 / 3 s", "The flame to Mira's shrine: 14", "The flame: home".
- **The Night 2 missions' results** no longer show a "Solved by" row (only The Warning has one).

**The screens:** the title's Campaign button; the night screen (§2); the ending screen: the pages turn with Enter or a click, Esc leaves, the last page's button says Title. Cael's name stands under his words, a second gold rule runs inside the panel's with a diamond at each corner, and a short rule sits under the title. The campaign's Results carry one Continue and the god's line. Pause's last button is Campaign.

**The save** (`user://kak_save.cfg`) gains a `[campaign]` section: `night`, `dp`, `bites`, `tally_faith`, `tally_theft`, `tally_ruin`, `last_path`, `bell_rang`, `nights_won`, `ending`, `ending_seen` (M5).
- **Reading is forgiving:** no section means no campaign. A night is held between 0 and 3, `dp` between 4 and `MAX_DP`, bites between 0 and 3, tallies at 0 or more, `last_path` one of the three paths or empty, `ending` one of the four or empty. Three bites with no ending read as Eaten.
- **`ending_seen`** is true only when there is an ending and the key says so. A save from before M5 that had reached its ending has no key, so it reads as not seen and shows its ending once more, then starts afresh.
- **The board's sections are untouched** by campaign nights. An older build ignores the new section, and its next save drops it (it writes only the sections it knows).
- **`--show` runs never write the real save.** Every `--show=<screen>` run opens on the player's own save but writes `user://test_show.cfg` (`Game.save_path_for`), so a key pressed on a photographed sample cannot replace a real campaign.

## 9. The gates

Measured on the BURIN_NITRO laptop at each milestone. "Exact" checksums are the deterministic behaviour scenarios.

| Gate | `kak-v0.09` | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|---|
| Tests | 2087 / 0 failures | 2858 | 3140 | 3469 | 3567 | **3625 / 0** |
| State digest | `61267b7e…146b` | = | = | = | = | **=** |
| crowd_check | −346732806 | = | = | = | = | **=** |
| FLOW | 62 checks | 82 | 82 | 82 | 82 | **86 / 0** |
| Exact checksums (10) | v0.09's list | = | **moved** (VFX merge) | = | = | **=** |

**Gates (final code tree `b7aa1fb`, M5 plus the art polish merged):** tests `checks=3626 failures=0`; FLOW `checks=86 failures=0`; digest `61267b7e90524d800bf1c3473a71146b`, crowd_check `-346732806` and the ten exact checksums unchanged from the VFX-merge baseline; mission test buildings 53 / citizens 191 / escaped 1 / stability 70% / citadel 50%, and `--mission=warning` `won=false reason=bell time=24.1`.

The M5 column is the final tidy-up commit `f0e75d1`, before the last merge of `feat/Develop-Main`'s art polish. The tests, digest, crowd_check, FLOW, Mira's House and Broken Lanterns references were run there; the ten exact checksums and the forced nights were run at `f95991c`, and no code that could move them changed after it. The tests of the merged art and VFX work are in these counts, so the campaign's share is not the difference from 2087.

**The ten exact checksums.** Through M1 they were `kak-v0.09`'s: `calm --seconds=60` −695580348, `gates` 619520995, `fire` −16560442, `rite --interrupt` −129298221, `soldiers --case=escort` −935015846, and The Warning's `none` −446012507, `doom` −999129915, `whisper` 442055066, `discord` −909358062, `mix` −430643507. **They moved once**, with the VFX merge (M2), to a new baseline that held through M5: `calm` −355092532, `gates` 589794389, `fire` 250399241, `rite --interrupt` −948525703, `soldiers --case=escort` −778609674, `warning` `none` −489775734, `doom` −905773030, `whisper` −588314462, `discord` −997640091, `mix` −206935500. The state digest and crowd_check did not move.

**The campaign's own references** (exact):
- **Mira's House** `--scenario=miras --case=play`: `won=false reason=gaze time=94.9 believers=3 gaze=100 reports=3`, checksum −200101558. M2's merged-tree gate read `time=143.0 believers=5`, but that run used `--seed=2`; this line is the default seed's, recorded from M3's first task, and it held unchanged through M5.
- **Broken Lanterns** `--scenario=lanterns --case=none --seed=1`: `won=false reason=relit time=180.0 drained=0`, checksum 424350965. Its `play` runs vary from run to run (the hit-stop runs on the wall clock), so they are judged on the outcome: won, six drained.
- **The Vigil Flame** `--scenario=flame`: outcomes only. `none` loses to the Gaze on seeds 1–3; `play` wins at least 2 of 3.
- **The forced nights** `--scenario=night --path=festival|procession --act1=win --act2=win --act3=win`: −139363489 and −441164656.
- **Last Judgement's seed-7 `judgement` checksum is not an exact gate** (see §15): the unchanged tool gives a new checksum every run.

**By milestone** (each tagged `kak-v010-mN`; the tags sit on `cba4649`, `140a240`, `5a41ff6` and `ec247e4` for M1 to M4):
- **M1 (the spine):** `CampaignDef`, `CampaignState`, `CampaignText`, the save section, the night and ending screens, the campaign in the game's flow (Title, Pause, Results, Prepare), and a FLOW test that plays a whole campaign. Night 2's three cards led to a placeholder ("Hold until dawn", 2:00) tagged with the card's path. Origin's PixelLab art (reference batch 3, decor batch 4) was merged in. All exact gates identical to `kak-v0.09`. FLOW 62 to 82.
- **M2 (the Gaze and Mira's House):** `GazeMeter`, its objective and bar; the Faithful and `TempleReport`; `VigilRoute`; Mira's House with its four events; the `miras` scenario. The VFX branch (Tier I powers, Death, Dominion with Disorder, the Decree Authority; 38 powers in all) was merged in, which moved the ten checksums.
- **M3 (Broken Lanterns):** the wayside shrine, the Lantern Knight, `VigilRoute`'s loop, divert and pass-the-flame, the director, prayer, the kneelers; the `lanterns` scenario. The Gaze took over judging seen deaths. The art animation round was merged in.
- **M4 (The Vigil Flame):** the reports and sight shared in `MissionDirector`, `Searchlight` and `SearchlightFx`, the director, the `flame` scenario, the `--show=flame` photographs, the `--bench-beams` hook and the bench.
- **M5 (story and balance):** Cael's lines and subtitle, the cards' goals, the ending frame, the campaign flow mended, the unscored Feast, bigger marks, the loose ends in Mira's House and the Vigil Flame, the `feast` scenario and the finale measured at 12 DP. A final review (opus, 0 Critical, 0 Important) and its tidy-up `f0e75d1` followed; the art polish was merged last. FLOW 82 to 86.

**The mission test** (Last Judgement, Organized; not exact, because hit-stop runs on the wall clock): M1 gave buildings 53, citizens 184, escaped 1, stability 69%, the Citadel at 50%; M2 53, 186, 1, 69%; M3 55, 189, 1, 69%; M4 53, 188, 1, 70%.

**The Warning, unhindered** (`--mission=warning --mission-test`): lost to the bell at 24.1 s (M1), 24.0 s (M2), 24.2 s (M3) and 24.1 s (M4). The five `warning` cases are exact and identical from M2 on (above).

## 10. Balance — beyond the spec's starting numbers

The spec gave starting numbers to be tuned. Each mission was tuned in its own milestone, with scripted policies playing it (the `miras`, `lanterns` and `flame` scenarios) and doing nothing as the control. **These go beyond the spec's starting numbers**: please look at them.

At Mira's House's starting numbers (20 Faithful, sight 4, a 10-s reading, 10 Grieving, 5 Believers needed) the quiet policy lost to the Gaze on 3 of 3 seeds (44.8, 36.6 and 121.2 s) and doing nothing lost "few" on 3 of 3. Each change below was measured on seeds 1–3:

| Mission | Number | Spec's start | Chosen | Measured |
|---|---|---|---|---|
| Mira's House | Faithful besides the clergy | about 20 | **12** | With sight 3: 3, 3, 5 Believers, all lost to the Gaze late |
| | Sight at the door | 4 (the plan's start) | **3** | (the same step) |
| | Reading time | 10 s | **8 s** | 4, 4, 5 Believers, no Gaze loss |
| | The Grieving | 10 | **12** | 3, 7, 4 Believers |
| | Believers needed | 5 | **4** | The policy reached 3 to 7, most often 4 |
| Broken Lanterns | A death someone sees | +10 | **+0.5** (`SEEN_DEATH_SCALE` 0.05) | One Heaven Splitter kills 3–20 people, nearly all seen: at the spec's rates the Gaze filled at 1.5 / 7.5 / 8.2 s |
| | Prayer | 1 a second each, at most 6 | **×0.05** (`PRAYER_SCALE`) | At 1.0, three praying at each of two standing shrines reach the cap: prayer alone fills the Gaze about 17 s after the first break. At 0.2 and 0.1, with the seen deaths, it still filled before the sixth shrine could drain |
| | Faithful | about 20 | 20 | 32 was tried: still only 3–4 kneeled, so reverted |
| The Vigil Flame | Prayer | 1 a second each, at most 6 | **×0.5** (`PRAYER_SCALE`) | At 1.0 the policy's winning runs ended with the Gaze at 70–90: prayer is the wall, and one touch would lose. At 0.5 they end at 30–38 |
| | The bearer's pace | the Vigil's half pace | at most **0.85** of his slowest acolyte's (`BEARER_LEAD`, new) | The acolytes trailed the bearer by 4–7 units, so the swap went unwatched and doing nothing could win |
| | Wren's carry | | **half his pace** (0.75 at first) | The carry was too short |
| | The beams' reach | | `FAR` 26 (18 at first), beam speed 8 (6) | Wren leaves by the south gate and walks 25–31 units from the spire, outside the walls, out of every beam |
| | Mira's shrine | the forest edge | **(−17.6, 5)** (it was (−17.6, 12)), the sweep period 30 s (26) | The beams then reach Wren on his last stretch along the wall |

**Unchanged from the spec:** the shrines' drain (20 s), the Knights (4, at 1:30, three times the health), the kneelers (15, the bonus at 10 within 2), the swap (3 s), Wren at 0:50 and his own try at 30 s, the second beam at 30 s, the search in the last 20 s, a touch at +50, the Night 2 clocks (2:30, 3:00, 3:00), the Gaze's own numbers (`GazeMeter` is shared), and every number of the DP growth (§3).

**Night 2 as measured** (seeds 1–3, the scenarios' scripted policies):

| Mission | Case | Result |
|---|---|---|
| Mira's House | none | lost "few", 0 Believers, at 150.0 s, 3 of 3 |
| | play (whisper, Silent Doom, Discord; 4 DP), before the VFX merge | 3 Believers (lost "few"), 7 (won), 4 (won), all at dawn |
| | play, the default seed, since the merge | lost to the Gaze at 94.9 s with 3 Believers and 3 reports (decision (g)) |
| Broken Lanterns | none | lost "relit" at 180.0 s, nothing drained, 3 of 3 |
| | play (Heaven Splitter, Dragonfire Parade, Silent Doom; 6 DP) | won 6 of 6 in two batches, at 141.6 to 171.7 s, the Gaze at 66–83 at the end, 1–3 shrines relit on the way; no win before 2:20 (the Knights of 1:30 are killed by the late strikes) |
| | bonus (as play, holding the last blow until ten kneel) | won at 166.5 to 171.6 s, bonus never earned (decision (b)) |
| The Vigil Flame | none | lost to the Gaze at 97.1 / 98.1 / 99.7 s: the swap is seen (Wren tries it himself at 1:20, and a Faithful's report reaches the Temple) |
| | play (Mind Whisper, Discord, Will-o'-Wisp; 5 DP) | won at 158.8 s (bonus, Gaze 38); lost to the Gaze at 68.8 s (an onlooker walked in during the swap and saw it); won at 121.1 s (bonus, Gaze 30) |

- **Before the campaign's tuning** Broken Lanterns' policy lost to the Gaze at 1.5 / 7.5 / 8.2 s, and The Vigil Flame's `none` case won on seed 1 (the acolytes were not beside the bearer).
- **After M5's loose-end fix** the seen swap's report runs at the carrier's own pace, so The Vigil Flame's `none` cases lose 10–13 s sooner (107.8 / 110.1 / 112.4 s before).
- **The Vigil Flame's play policy:** a Will-o'-Wisp first draws bystanders off the lantern, one Discord takes the bearer and the acolytes (only once one cast can take them all), then Wren is whispered to the lantern. With the flame it reads the beams' paths ahead: a wisp beyond the beam where the fewest Faithful stand, else a whisper out of its way. A Discord at the Temple's door covers the last 20 s. Without that beam-dodging carry, both winning seeds were touched once by a beam and lost the bonus.
- **The policies' loadouts** cost 4, 6 and 5 DP, inside spec §7's 8 DP. The default Mira's House loadout (Mind Whisper, Will-o'-Wisp, Discord) was not what was measured.

**Night 3 at 10 DP** (`--scenario=feast`, each act alone in a fresh town; the policy is The Long Night's):

| Act | Town | Case | Seeds 1 / 2 / 3 | Bonus |
|---|---|---|---|---|
| The Festival (Silent Doom, Discord: 3 DP, 2 slots) | Unaware | play | won 95.6 / 95.6 / 95.6 s | Before the bell, all three |
| | Unaware | none (seed 1) | lost, the square closed, 150.0 s | |
| | Organized (the bell rang) | play | won 95.6 s each | Before the bell, all three |
| The Procession (Mind Whisper, Silent Doom, Discord: 4 DP, 3 slots) | Unaware | play | won 130.8 / 129.6 / 138.2 s | A quiet succession, all three |
| | Unaware | none (seed 1) | lost, he sailed, 138.5 s | |
| | Organized (the bell rang) | play | won 130.8 / 129.6 / 138.2 s | A quiet succession, all three |

- **Met:** both acts are won 3 of 3 at 10 DP. The policies' loadouts cost 3 and 4 DP, so they fit even the 4-DP floor.
- **The Festival is won by the Mayor's Silent Doom** at 95.6 s (v0.09's decision (e) still stands). The policy's loadout costs 3 of the 10 DP, and only the Doom is needed.
- **A warned Procession is identical to an unwarned one:** each seed has the same checksum, since `ProcessionDirector` never reads the bell (decision (i)). The warned Festival differs (soldiers are posted) but is won the same.

**Night 4 at 12 DP** (`--scenario=judgement`, three seeds each; "ring" is a fixed ring of targets closing on the Citadel, "rich" aims each cast as Act III's caster does):

| Loadout | DP | ring | rich |
|---|---|---|---|
| Heaven Splitter, Tsunami Breaker, Cinderfall Barrage, Nuclear Nova (the default) | 14 | 0 of 3, ends at 75.9–80.3 s | 0 of 3, 68.0–115.8 s |
| L1: Heaven Splitter, Nuclear Nova, Cinderfall Barrage, Smite, Ember | 12 | 0 of 3, 73.7–77.5 s | 0 of 3, 68.6–84.3 s |
| L2: Heaven Splitter, Nuclear Nova, Judgement of the Ancients, Blight | 12 | 0 of 3, 76.3–80.0 s | 0 of 3, 68.1–88.4 s |
| L3: Heaven Splitter, Tsunami Breaker, Nuclear Nova, Silent Doom, Smite | 12 | 0 of 3, 75.5–81.7 s | 0 of 3, 70.1–108.4 s |
| L4: Heaven Splitter, Tornado Tempest, Dragonfire Parade, Nuclear Nova | 12 | 0 of 3, 90.4–94.9 s | 0 of 3, 71.0–75.2 s |
| X1: The Long Night's Act III set | 14 | | 0 of 3, 71.2–78.1 s |
| X2: six powers | 19 | | 0 of 3, 71.8–112.8 s |
| X3: Nuclear Nova, Cinderfall Barrage, Judgement of the Ancients | 12 | | 0 of 3, 70.6–79.0 s |

- **No run won, at 12, 14 or 19 DP; every loss was to the escape limit** (50 escapes). The nearest run was L3 rich on seed 1: the Citadel down at 74.0 s, City Stability at 11% at 90 s, the escape limit at 108.4 s. The 14-DP default (12% at 90 s) and the 19-DP set (11%) came as near. More DP does not change the outcome, because the scripted casters only destroy and nothing holds the exits. v0.08 already recorded 0 of 5 wins at 14 DP.
- **So spec §7's "Last Judgement winnable at 12 DP" is not shown.** M5 did not grant the finale +2 DP (decision (h)).
- **Last Judgement itself is unchanged:** the greedy `judgement` run still ends in escapes at about 85 s with the Citadel down at 47 s and 77 or 84 buildings (two modes, both seen in v0.08).

## 11. Departures from the spec

Taken during the build, reported to you at each gate. Each is cheap to overrule.

| Spec | Built | Where |
|---|---|---|
| Memory fragments on the interlude screen, a still panel, 20–40 s, with portraits | Text on the new night screen, shown until the player moves on; no panel art and no portraits (your M5 decision) | M1, M5 |
| The title's "Campaign (Continue / New)" | One Campaign button; **New campaign** on the night screen, asking twice. The old Play button is now "Missions" | M1 |
| A `campaign` behaviour scenario with forced outcomes (`--n1=` and so on) | A headless test (`test_campaign.gd`'s `_branches()` walks all 24 combinations) and the FLOW test; one scenario per Night 2 mission, plus `feast` | M1 |
| Night 3's card lines | The Long Night's own town lines; the spec gives Cael lines only for Night 2's cards | M1 |
| Mira's House: 10 Grieving, 10 s reading, 5 Believers, about 20 Faithful | 12, 8 s, 4, 12 (§10) | M2 |
| "Anyone inside when the roof falls at 2:30 dies" | At 2:00 everyone inside runs out into the street in a fright, unconverted if the reading was not done; the roof still falls at dawn. A reading takes 8 s, so otherwise everyone would be out long before the roof and the twist would never bite | M2 |
| A conversion under way fails when its reader is seen entering | A seen entry turns the reader away at the door, and the Faithful who saw it reports | M2 |
| The Vigil walks the same route in all three missions | Mira's House's Vigil walks a short route past her door at 1:45; the other two walk the six shrines | M2 |
| New roles `INQUISITOR` and `URCHIN`, a `BELIEVER` look with an ember above the head | No new roles: Venn wears the clergy look, Wren is a lay citizen with his own look, and a Believer is an ember-orange HUD mark. Each needs art on both art paths | M2, M4 |
| Reports reuse The Warning's messenger-and-relay logic | `TempleReport` is a fresh copy of it, so The Warning's exact checksums cannot move | M2 |
| "Guard" the shrines | A Knight within 1.5 is a shield: the shrine takes no damage | M3 |
| The Faithful report in Broken Lanterns | They do not: the spec lists no reports there, and prayer is their answer | M3 |
| Silent on a dead flame-bearer | The flame passes to the first living acolyte, in Broken Lanterns and The Vigil Flame; otherwise one Silent Doom would end the night's only threat to the plan | M3 |
| Each shrine broken sends 3 Faithful to each standing shrine | Each break tops every standing shrine up to 3, not 3 more each time | M3 |
| The swap takes 3 s and follows Silent Doom's witness rule | Judged as it completes. Wren takes hold within 1.0 of the lantern and keeps within 1.6 of it, so a walking bearer does not break it; the bearer, who is robbed, never sees it | M4 |
| Mira's shrine at the west forest edge | A marked spot at (−17.6, 5) outside the west wall, not a structure | M4 |
| The searchlight's cone | A beam is a pool of light, radius 2, swept round the spire; only the pool touches, and the cone is drawn down to it | M4 |
| What the light hears | Every cast but Mind Whisper and every death is a noise; the latest counts, even from before the light woke | M4 |
| The 1:30 route shortening | Only while the flame is still in its lantern; swapped earlier, the Vigil keeps circling | M4, M5 |
| Short subtitles on the existing banner system | A second HUD queue: a plate under the banner bar, 4 s | M5 |
| Each ending has one panel | A drawn frame in its place, with Cael's name under his words and a closing line on the campaign | M5 |
| A card shows the goal and a line from Cael | As the spec says (M1 showed the brief; M5 corrected it); the brief stays on Prepare | M5 |
| The Feast scores like The Long Night | An unscored night: its goal, bonus and time, no rank | M5 |
| Balance at the spec's rates | Far from them in Broken Lanterns and The Vigil Flame (§10, decision (c)) | M3, M4 |

## 12. Decisions for you

The build found these outside what it was allowed to change. Each is an exploit, an oddity or a measurement that misses the spec. **Nothing was decided for you.**

**(a) Free retries dodge bites.** Pause, Restart, or Pause, Campaign, leaves a night unplayed at no cost: no bite, no DP change, the same night next time (by design: leaving a night unfinished records nothing). A player can retry a night until it is won and never take a bite. Options: keep it; count leaving a started night as a loss after its first minute; allow one free retry a night.

**(b) Broken Lanterns' bonus, Through the faithful, is unreachable in live play.** When the fifth shrine drains, of 15 living Faithful 11 are evacuating by the gates (the town's own flight, outside this mission's rules), and the kneeler call reaches only the free ones: 3–4 kneel, and the bonus needs 10 within 2.0. Raising the Faithful from 20 to 32 changed nothing. A policy that held the last blow until ten knelt won at 166.5–171.6 s with the bonus never earned. It is proven headless that a night that keeps the town from evacuating can face a full ring. Options: the Faithful turn back to kneel (a director rule over their flight); lower `KNEELERS`, `ThroughFaithfulObjective.NEED` or `BONUS_REACH`; replace the bonus.

**(c) The balance scales sit far from the spec's.** Broken Lanterns: prayer at 1/20 of the spec's rate (`PRAYER_SCALE` 0.05) and a seen death at 0.5 Gaze instead of 10 (`SEEN_DEATH_SCALE` 0.05). The Vigil Flame: prayer at 0.5. Without them Broken Lanterns' Gaze filled in seconds (one Heaven Splitter kills 3–20 people, nearly all seen) and The Vigil Flame's winning runs ended at 70–90 Gaze, where one touch would lose. Options: accept the scales as the design; or ask for a rethink of the sources (fewer Faithful, slower beams) so the spec's rates can stand.

**(d) Last Judgement lost about 5.7 fps and gained 64 draw calls since `kak-v0.09`,** through the merged art and VFX work (132.6 fps on this tree against 138.3, and 1072 draw calls against 1008; §13). The Searchlight itself costs 3.7 fps against this tree's Last Judgement. The regression is outside the campaign. Should a perf pass come before v0.10's release, or after it?

**(e) Venn's search loops all night.** After Mira's door she starts the round again (her house index wraps). The code's own doc says the search ends at Mira's. Confirm the loop is intended, or end it at the door.

**(f) The 2:00 fire might ring the bell.** The priests' fire in Mira's House can draw the town's alarm. A rung bell fills the Gaze and loses the night with no act of the player's. It was not seen in six runs. Options: hush the town for the fire's duration (`crowd.hush()`), or leave it as a risk.

**(g) Mira's House's scripted policy loses since the VFX merge.** Before it, seeds 1–3 gave 3, 7 and 4 Believers (one short, two won). Since, the default seed loses to the Gaze at 94.9 s with 3 Believers. Its balance was measured with Mind Whisper, Silent Doom and Discord, not the default Mind Whisper, Will-o'-Wisp and Discord, so the policy is also not the loadout a player starts with. Retuning it (`FAITHFUL`, `SIGHT`, `READ_SECONDS`, `GRIEVING`, `NEED`, the levers M2 used) would move the exact Mira's House reference. Options: judge it in the hand playtest first; or retune it at the default loadout.

**(h) Last Judgement at 12 DP cannot be verified with scripted casters.** They lose at 12, 14 and 19 DP alike, every time to the escape limit (§10). Options: keep 12 DP and judge in the hand playtest; give the finale +2 DP (it departs from the spec's §3.1, and would not by itself make the finale measurably winnable, since the 14-DP default already loses 6 of 6); or commission a Last Judgement caster that holds the exits (Thornwall, Leaving Is Prohibited at the gates, the boats) so 12 and 14 can be compared.

**(i) A warned Procession plays like an unwarned one.** Night 3's card says "The bell rang: his escort is wary", but `ProcessionDirector` ignores the bell, as it has since v0.09. Options: accept it; change the card's line; make the escort wary only in `MissionBook.feast()`'s own copy of the act.

**Open items from the spec, unchanged:** every name is a placeholder (and "Halcyon" is worth replacing); every number was a starting value, now tuned (§10); the playable last nights for The New Faith and The False Lantern come after the prototype.

## 13. Performance

**The Searchlight bench** (spec §7: two beams over the full town stay within 5 fps of Last Judgement's bench at `kak-v0.09`). `--mission=vigil_flame --bench --bench-beams` lights both beams at once under the mission's opening camera, lets them sweep 5 s so the dim, the cones and the pools are up, and then times the frames. It was measured in M4 against `kak-v0.09`'s Last Judgement bench and this tree's own:

| Build and bench | fps | Draw calls |
|---|---|---|
| `kak-v0.09`, Last Judgement | 138.3 | 1008 |
| This tree, Last Judgement | 132.6 | 1072 |
| This tree, two beams | 128.9 | not recorded in the ledger |

- **Against this tree's Last Judgement the beams cost 3.7 fps: inside the 5-fps budget.** Against `kak-v0.09` literally the beams are 9.4 fps lower, which misses. The rest, 5.7 fps and 64 draw calls, is Last Judgement itself, drifted since `kak-v0.09` through the art and VFX merges, outside the campaign. The ruling was to read the spec line against the current tree and to surface the drift (decision (d)).
- **Nothing was profiled or changed** for the beams: the bench passed against the current tree. The frame is CPU- and draw-call-bound, so any perf pass should profile first and bench on a quiet machine.

## 14. Tools and tests

- **Behaviour scenarios** (`tools/dev/behaviour_check.gd`; `--seed=` picks the town in each):
  - **miras** (M2): `--case=none|play`. The policy whispers the grieving in when nobody of the Faith watches the door, uses Discord on the nearest watcher, and stops reports with Silent Doom (unseen), a whisper or Discord.
  - **lanterns** (M3): `--case=none|play|bonus`. `play` dooms the called bellkeeper and the flame-bearer while a shrine drains, lays the Heaven Splitter through two standing unguarded shrines where it can (else one, crossing the fewest people), and uses Dragonfire only when the Splitter would come too late for dawn. `bonus` holds its Ruin off the kneelers' shrine until ten kneel.
  - **flame** (M4): `--case=none|play` (§10).
  - **feast** (M5): the campaign's Night 3 alone, at 4 slots and 10 DP. `--path=festival|procession`, `--bell=rang` for a warned town, `--case=none|play`, `--loadout=a,b,c`. It prints the loadout's cost against the budget, then the result.
  - **judgement** (extended in M5): `--aim=rich` aims each cast as Act III's caster does, and the start line prints the loadout's cost against the finale's 12 DP and 6 slots.
- **Photographs** (`SCENE=res://scenes/game.tscn bash tools/capture.sh --show=<name> --capture`): the new names are `campaign`, `campaign-choice` (Night 2's three cards), `ending`, `results-feast`, `miras`, `cael` (Venn's banner with Cael's line under it), `lanterns`, `flame` and `flame-beams` (both Searchlight beams lit at once). **A `--show` run reads the player's save but writes `user://test_show.cfg`, never the real one.**
- **A campaign night on its own:** `-- --mission=miras_house|vigil_flame|broken_lanterns|feast_festival|feast_procession`.
- **`--bench-beams`** (`Mission._bench_beams`, M4): `--mission=vigil_flame --bench --bench-beams [--bench-after=SECONDS]` (default 5). The Vigil Flame only: every other bench is untouched.
- **FLOW** now plays a whole campaign from the title: Night 1 won on its clock, Night 2's three cards and The Vigil Flame won with its flame home, Night 3's Festival lost on its clock (a bite, and the Theft ending), the ending's two pages and the title again; then a fresh campaign, nights left unfinished (Restart, and Pause, Campaign, record nothing), the board after the campaign using its own numbers, and an ending left unseen opening from Campaign. 62 checks at `kak-v0.09`, 82 from M1, **86** from M5.
- **Tests:** 12 new suites: `test_campaign`, `test_campaign_screens`, `test_gaze`, `test_temple_report`, `test_vigil_route`, `test_miras_house`, `test_shrine`, `test_lantern_knight`, `test_broken_lanterns`, `test_searchlight`, `test_vigil_flame` and `test_cael_lines`, with new checks in `test_flow`, `test_hud`, `test_mission_book` and `test_night`. They cover the campaign's DP, bites, floor, ties, finale and save round trip, the Gaze's sources, the reports and their relay, the conversion timing, Venn's search, the fire, shrines and their drain and relight, the Knights, the kneelers, the swap's witness rule, the beams' sweep, decoy, search and `touches()`, Cael's lines and the layout of cards and the HUD. 2087 at `kak-v0.09`, 3625 at M5 (§9).

## 15. Rulings made during the build

Rulings the controller made while the build ran, with what it costs if one was wrong:

| # | Ruling | Cost if wrong |
|---|---|---|
| M3 | An implementer's commit trailer names the model that wrote it ("Claude Sonnet 5.5"), not the plan's Opus line | cosmetic history line |
| M3 T4 | A reviewer's Important was fixed although the plan mandated it: `_take_flame` now keeps a busy acolyte's errand (one condition) | none |
| M3 T5 | Mira's House's helpers, which the plan had copied into Broken Lanterns, moved into `MissionDirector`, since a third director was coming; the Mira's House reference guarded it | one refactor round |
| M3 T8 | The balance scales stay far from the spec (decision (c)) | a feel the spec did not draw |
| M3 T8 | The Through-the-faithful bonus stays unreachable in live play (decision (b)) | an unobtainable bonus until decided |
| M3 final | The final fixer reported a test check done that never reached the tree (`81159f7` held only the `_spread_faithful` guard); the same fixer was resumed to finish the same wave, not a second wave | one extra resume |
| M4 | The plan's stale test baseline (3235, before the merge) was replaced for the executors by the merged tree's 3469 | none |
| M4 | Broken Lanterns' play runs vary from run to run, so they are gated on the outcome (won, six drained), not on time or Gaze; FLOW, the tests and the `none` case stay exact | a subtle Broken Lanterns change could slip past the play runs |
| M4 T3 | The plan cut the cones and pools at once when the light went out and popped the second beam in at full strength; a per-beam fade replaced it, as the class doc promised | one small FX change |
| M4 T4 | The plan's third copy of the Vigil-walker choice and `_choose_faithful` was lifted into `MissionDirector`, as in M3 | one refactor round, guarded by the references |
| M4 T5 | Thornwall keeps Faithful off Wren's route through the existing wall; no beam rule was added | none |
| M4 T6 | Look and placement tuning beyond the brief (the lamp 140 px up, cone alphas 0.4 and 0.12, the camera at (1.5, −8)) and a 2-s `--show=flame` wait were accepted | cosmetic |
| M4 T7 | The `BEARER_LEAD` code fix (the bearer walks slower than his slowest acolyte, this mission only) was accepted although the task was numbers-only | small |
| M4 T8 | Spec §7's bench was read against the current tree's Last Judgement, not literally against `kak-v0.09`'s (decision (d)) | the spec line read literally fails |
| M5 T6 | Marks are drawn first in `Hud._draw()`, under every HUD element, beyond the brief's "under the banners and the slots" (the top strip and panels were still overdrawn) | one line |
| M5 T7 | An existing `_route` test was reordered (the route shortens before the swap) because the new rule made the old order unreachable; its assertions kept | none |
| M5 T7 | `_pace_bearer` is guarded so a report carrier is not slowed, the same rule as the seen-swap runner | one line |
| M5 T8 | The finale's +2 DP grant (plan Step 7) was not applied: the 14-DP default already loses 6 of 6, so the grant would break §3.1 without making the finale winnable (decision (h)) | the finale may be harder than intended at 12 DP until the playtest |
| M5 T8 | `judgement`'s seed-7 checksum left the exact gates: the unchanged tool gives a new checksum every run (hit-stop wall clock; 77 or 84 buildings), so it is judged on outcome | a Last Judgement change could slip past this one scenario (the ten checksums and FLOW still guard) |
| M5 final | Any non-empty `--show` redirects writes to `user://test_show.cfg`, not a list of campaign samples, so a sample added later is covered | a manual `--show` play session no longer records bests or loadouts to the real save |
| M5 final | `MAX_DP` was raised to 18 rather than clamped on read only, because a won finale's saved 17 was being read back as 15 | none |
| M5 final | A campaign that ended before M5 shows its ending once more, the plan's choice | a player who saw their ending sees it once more |

**Fixes in the milestones:**
- **M1:** campaign nights leave the board's saves alone (a campaign Warning shares its id with the board's); New campaign ignores the second click of a double-click.
- **M2:** the marks follow people, not fixed points; the door counts any face of the house; a Will-o'-Wisp's ring counts for a lure; a busy Vigil walker (carrying a report) is not pulled back.
- **M3:** patrols' investigations leave a Lantern Knight alone once pruning slides him into their range; a busy acolyte takes the flame but keeps his errand; the kneelers are topped up every half second (the call was one-shot, so only the 3–4 Faithful free at the fifth drain ever knelt); the final wave added tests that the bearer can relight every shrine, and a guard in `_spread_faithful`.
- **M4:** each beam fades in and out on its own; the acolytes keep beside the bearer; the new bearer of a passed flame keeps beside his acolyte; the light's reach is documented; a beam is tested to outrun its own sweep.
- **M5:** Mira's House's test wording (ten Grieving, 10 s, five Believers) follows the tuned numbers; Venn is not turned to her search while she carries a report; the Vigil's banner does not fire when nobody can walk it; no route or acolyte banners after the swap; the seen swap's runner and a report-carrying acolyte who takes up the flame keep their own pace; the board's mission comes back whenever the campaign is left; an unseen ending is shown from Campaign; the night screen remembers its card; the saved DP is clamped above; the final review's tidy-up (`f0e75d1`): `--show` never writes the real save, the `--show=cael` photograph waits out the mission's own two banners, the subtitle's shadow fades with its words, a pace test that could not fail now can, the 1:30 docs and `MAX_DP`.

## 16. Known issues

- **FLOW is load-sensitive,** as in v0.09 (§14 there): its waits for a fresh mission can run out on a busy machine and print one failure. Run it on a quiet machine, and rerun before calling it a fault.
- The restart steps print "Lambda capture ... was freed" noise (pre-existing).
- **The campaign does not remember loadouts.** Each campaign night's Prepare opens with the mission's default loadout, or for The Warning and Last Judgement the loadout last drafted on the board. The title's Campaign does not keep the night screen's card either, only Back and Pause, Campaign do.
- **After an unseen swap before 1:30,** The Vigil Flame's Vigil keeps circling the rest of the night instead of going home. The walkers are exempt from prayer either way.
- **Kneelers and prayer in Broken Lanterns:** a kneeler who later flees keeps a place, and the prayer call may put non-kneelers at the kneel shrine (both tied to decision (b)).
- **Small, unfixed:** a one-frame entry or conversion is possible in the frame Mira's house is destroyed; Mira's House's readers leave with `leave_shelter(false)`, ignoring an evacuation with no bell; a report relayed to a Vigil walker keeps the Vigil's pace; a failed guard drops its timed event for good, and the code does not say so; a Discord at the Temple's door can park a beam on Wren; the beams sweep about 6.7 units past the map's north edge, off screen; the Searchlight's "The light searches" strip entry shows from the start at a fixed 160 s; the banners' text shadow still ghosts on fade-out; `_say` keys lines on the act's id, so a future line for a Feast act keyed by `feast_*` would never be spoken; Broken Lanterns' dawn-loss wording was left as it is; the `--show=cael` wait is bounded in frames, not seconds; a few wiring lines in `game.gd` are pinned only by throwaway probes, not by tests; literal tab runs inside a line remain in older files (`src/environment/decor.gd`, `tests/test_sprite_art.gd`, `tools/dev/behaviour_check.gd`).
- **The `feast` tool** re-parses `--loadout` (a typo gives a 0-DP slot and `fits=true`), and its Festival policy's Heaven Splitter branch has never cast in a run.
- Further minors from the per-task and final reviews are recorded in the milestones' ledgers. M5's final review triaged its 35 deferred minors and found none a player can reach.

## 17. What comes next

**Objective clarity (M6)** is built: see the section above. Anything it leaves is in its milestone ledger.

Also open:
- **Art for the story:** panels for the fragments and endings, portraits for Mira, Cael, Halcyon and Odran, the sprites and looks the build stands in for (Venn, Wren, the Believer, the wayside shrine, the Knight's own sprite).
- **Playable last nights** for The New Faith and The False Lantern.
- **Ruins and the dead carried between nights,** the holy city and capital maps, and Tier 4.
- **Resonance and the Awakening Trials,** which v0.09's summary expected in v0.10 and the v0.10 spec moved later; the campaign save they were to share is now in.
- **A name for Halcyon.**

## M6: Objective clarity

M6 makes a night's goal readable on screen: the map says where, a line under the objectives says how, and Night 2 opens on a short tour. It is text and drawn shapes only, and read-only: no rule, number or timing of any mission changed, and the behaviour checksums are as they were.

- **The map's tags.** Each Night 2 mission shows its objectives on the map as small coloured diamonds with a label, and an arrow at the screen's edge for anything out of view. A label never hides another: when two would overlap, the first listed is kept, and a director lists its most important first.
  - *Mira's House:* her house (outlined, with its door "WATCHED" in red or "CLEAR" in green), the Temple while a report runs, the running reporter ("TO THE TEMPLE"), the one crying out, Venn ("INQUISITOR", with an arrow while she searches), a red diamond on each Faithful watching the door, and the grieving and the Believers among them.
  - *Broken Lanterns:* each shrine ("LANTERN", or "GUARDED" while a Knight stands over it, or "DRAINING" with its seconds left, all with an arrow), the flame-bearer while he goes to relight one, and each living Knight.
  - *The Vigil Flame:* Wren, Halcyon's flame wherever it is carried, Mira's shrine, the Temple while the Vigil takes the flame home, and a red diamond on each Faithful close enough to see Wren take it.
  - The arrows keep to a frame: in from the screen's sides, below the clock, the Gaze bar and the events plate, and above the slot row. So a tag under the clock or the events plate, or under a slot, is pointed at, not hidden, and no arrow is covered. Arrows are drawn under the HUD's panels, so the objective rows, the hint and the status stay readable; each arrow is drawn before any label, so no arrow clips one. The Warning's own messenger arrow is unchanged.
- **How to win.** Under the objectives, a pale-gold line (at most three lines) says how to win, for every mission and every act of The Long Night. It follows the mission's phase: Mira's House changes it once four believe and again when her house burns; Broken Lanterns once a Knight is out; The Vigil Flame when Wren comes, when the Vigil turns for home and once the flame is swapped. It names the tag colours it speaks of ("gold", "red", "blue", "orange").
- **The tour.** Each Night 2 mission opens on three stops, each with a one-line caption centred above the slots and a "Space to skip" word under it: Mira's House shows her door, the Temple and Venn; Broken Lanterns a lantern, the flame-bearer and the Temple the Knights come out of; The Vigil Flame the flame on its bearer, Mira's shrine and the Temple. A stop with no one to show is left out, and a mission with no stops plays the old sweep. Space, Enter or a click skips it; that press casts nothing and opens nothing, and Esc still pauses. A restart plays the tour again.
- **For the board missions.** `MissionDirector.tags()` replaces v0.10's `marks()`. A board mission's director can override `tags()`, `hint_phase()` and `tour()`; the defaults are no tags, no phase and no stops.
- **Photos.** `--show=miras`, `--show=lanterns`, `--show=flame` and `--show=tour` photograph the tags, the plate and the tour caption; the play photos skip the tour and wait out the opening banners.

Gates: filled in at landing.

## 18. Pushed

The tags `kak-v010-m1` … `kak-v010-m4` are on GitHub. The branch `claude/lantern-campaign-spec`, the milestone tag `kak-v010-m5` and the release tag `kak-v0.10` are the controller's, with the push.
