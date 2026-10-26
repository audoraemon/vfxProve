# KAK: God Progression and Endless Night (design)

Date: 2026-10-26. Status: approved by the user (2026-10-26). Branch: `feat/god-progression` (worktree `vfxProve-god`), merged into `feat/Develop-Main` later.
Base: `feat/Develop-Main` at `a94db78f` (v0.12 "Many Towns").

Marks used below: **(user)** is the user's decision. **(my call)** is a choice made by the designer (Claude) that the
user has not ruled on; the user may overturn it. Numbers marked *first guess* are tuned once played.

## 1. Why

Today a god grows only through the board's believers shop (`DescendState`, the Upgrades screen): +DP, +1 slot, power
unlocks. Nothing about the god itself grows, and the god has no identity. The user wants a god you raise over many nights:

- you choose what **kind** of god you are;
- every night makes the god stronger (**Divine Power** as experience, **god level** 1-50);
- levels give **ability points** for a **skill tree**;
- abilities have **tiers**, and reaching a higher tier needs an **Awaken** night that is "different from any mission,
  harder, and much more meaningful to the god";
- every ability has **5 levels**, with a twist at level 5;
- **believers** give **Faith**, which buys the god's other upgrades (slots, carry maximum, descent time);
- the campaign becomes **Endless Night**: a random mission every night, carrying the god's growth.

## 2. Goals, non-goals, anti-goals

**Goals**
- One progression loop: night, rewards, level up, spend points and Faith, next night.
- A god type chosen at the start that shapes the whole run.
- A meaningful step at every 10 levels (the Awaken rites).
- A framework the user can fill: 60 tree spots that start empty and are filled by the user later.

**Non-goals (this design)**
- Filling the tree. The user chooses which powers go where, including which of Ruin's and Dominion's 14 powers make
  their 10 **(user)**.
- Writing each ability's level stats and level-5 twist. Those come with the tree's filling, one batch at a time.
- Designing the Hunt and Rite nights in mission detail. Each gets a short mission spec for approval, as v0.11's tiers did.
- Other towns. Endless Night is played in Aldermere (the Capital stays dev-only, per v0.12).

**Anti-goals (a failure even if it works)**
- A god that carries every strong ability at once. Might (§6) exists to stop this **(user)**.
- Progress that can be lost to luck. Nothing random decides a loss or a penalty.
- Grinding: no night where the player waits. The mission rules of §13 bind every new night.
- A hidden loss: every penalty is shown before and after it happens.

## 3. The modes

| Mode | What it is |
|---|---|
| **Missions board** | Becomes a **test mode** **(user)**. Every tier, every mission and every power is open. Nothing is saved but bests. The user may remove it later. |
| **Endless Night** | Replaces the Lantern campaign as the title's first button **(user)**. The only mode with god progression **(user)**. |

- **Board as test mode:**
  - All five tier tabs open; no padlocks; no unlock rule.
  - All powers open in the draft; no Upgrades button on the board; believers are not banked.
  - Slots and Might per tier as `TierBook` sets today.
  - Prepare gets an **ability level picker (1-5)** per drafted power, default 1, so any ability can be tested at any
    level **(my call)**.
  - Wishes still play (for testing), but pay nothing.
- **The Lantern campaign** leaves the title. Its code and missions stay; they are not deleted **(my call)**. Its missions
  stay on the board. An old save's `[campaign]` and `[descend]` sections are ignored, not erased **(my call)**.
- **Title buttons:** `Endless Night`, `Missions`, `Options`, `VFX Sandbox`, `Quit` **(my call: label)**.
- **Before the tree's Tier 1 is filled (user):** the user fills all 12 Tier 1 spots before Endless Night reaches the
  title. Until then Endless Night is reached only from the board's DEV tab, and the title keeps `Campaign` (the Lantern
  campaign) as today. P1 may land with an empty tree; the switch of the title button lands with the Tier 1 fill.

## 4. Save slots and the god

- **Save slots:** **3** slots **(my call: count)**. Each slot is one god. Starting a new god takes a free slot or
  overwrites one after a confirm **(user: multiple saves)**.
- **A slot holds:** god name *(optional, my call)*, god type, god level, Divine Power toward the next level, god tier,
  unspent ability points, each learned ability and its level, Faith and the Faith upgrades bought, the Lantern Notice,
  any sealed ability and nights left on the seal, the night counter, the last mission played, the stolen gifts (§11.4),
  and per-mission bests for this god.
- **Storage:** one file per slot, `user://kak_god_<n>.cfg` **(my call)**. Settings and the board's bests stay in
  `user://kak_save.cfg`.
- **Choosing a type:** once, when the slot is made. It never changes for that god **(user)**. To try another type, start
  another slot.
- **Starting abilities:** the chosen type's two Tier 1 abilities, learned at level 1, for free **(user)**.

## 5. God types and the skill tree

### 5.1 The six types

The six existing Authorities (`PowerBook.AUTHORITIES`) are the god types, set on a ring **(my call: the order)**:

```
Ruin - Death - Veil - Passage - Decree - Dominion - (back to Ruin)
```

- Every type has two **neighbours** on the ring. Ruin's are Death and Dominion.
- **Own type:** costs 1× **(user)**.
- **Neighbours:** cost 2× **(user)**.
- **The three far types:** cannot be learned **(my call)**.

### 5.2 The tree

- **60 spots:** 6 types × 5 tiers × 2 abilities **(user: 60 is fine)**.
- **Empty at first (user):** every spot starts as a placeholder. The user fills spots later by naming a power key.
- **The data:** one table, `GodTree`, maps each spot (type, tier, index 0-1) to a power key or to empty. Filling the tree
  is editing this table only; no other code changes.
- **An empty spot** shows as a dim frame with "Not yet chosen". It cannot be learned and costs nothing.
- **Tier gate:** an ability in a Tier T spot can be learned only once the god is Tier T or higher **(user)**.
- **Levels are not tier-gated:** an ability already learned can be raised to level 5 at any god tier **(my call)**.
- **The spot decides the type, not the power (my call):** a spot may hold a power of any Authority, because Veil, Death and
  Passage have only 2 powers today against 10 spots. In Endless Night the spot's type sets the 1×/2× cost and the Prepare
  tab. On the board, powers keep their own Authority. The `GodTree` test checks keys exist and appear once, not that a
  key's Authority matches its spot.
- **A power in no spot** cannot be learned in Endless Night. It stays usable on the board.
- **Every type can win every mission of its tier (user).** This is a rule for filling the tree: a god of any type, holding
  only its own type's abilities of Tier T and below, must be able to win every Tier T mission that Endless Night draws.
  The draw never skips a mission. It is checked with the scripted test players: for each type and tier, a policy using
  only that type's abilities wins every mission of the tier (the board's bar: wins ≥ 2/3, idle ≤ 45 s). A tree fill that
  fails it is not landed. A type whose Tier T spots are not all filled yet is not checked at Tier T.
- **A power in two spots:** not allowed; a test checks every key appears at most once.

### 5.3 Ability points

| Action | Own type | Neighbour type |
|---|---|---|
| Learn (to level 1) | 1 point | 2 points |
| Each level after (2, 3, 4, 5) | 1 point | 2 points |
| One ability to level 5 | 5 points | 10 points |

- **Points earned:** 1 per god level gained (levels 2-50: 49), plus 2 per Awaken rite won (4 rites: 8). Total **57**
  **(my call)**.
- The two free starting abilities cost nothing.
- **Respec:** resetting every point is bought with Faith (§7). The two free starting abilities stay at level 1
  **(my call)**.

### 5.4 Ability levels

- **5 levels per ability (user).** Each level raises 2-3 of the ability's stats: radius, duration, count, damage, spread
  rate, cooldown, and so on **(user)**. A first guess is +10-15% per level per stat.
- **Level 5 adds a twist (user):** a new behaviour, not a bigger number. Example: Ember at level 5 jumps to the next house.
- **Data:** each power's entry gets a `levels` table: per level, the stat values its effect reads, plus a `twist` flag
  and its one-line description at level 5. The effect is told its level the same way it is told its mode today
  (`extra["level"]`).
- **A power without a `levels` table** plays at its current stats at every level and shows "Level effects not set" in the
  tree. This keeps the framework playable before the tables are written.

## 6. Might (the old DP budget, renamed)

The draft's Divine Power budget keeps its job but takes a new name, **Might** **(user: keep it, rename it; my call: the
name)**. "Divine Power" now means experience (§8).

- **Each ability's Might cost:** its current `dp` value from `PowerBook` at level 1 (a placeholder spot has none).
- **Rising with level (user):** +1 Might at level 3 and +1 more at level 5 **(my call: the steps)**. A level-5 ability
  costs its base +2.
- **The god's maximum Might:** by god tier, `6 / 8 / 10 / 13 / 16` (today's `TierBook.DP`), plus Faith upgrades.
- **Slots:** a base of 3 at every god tier, plus Faith upgrades, never above `TierBook.MAX_SLOTS` (6) **(my call: slots
  come only from Faith, as the user listed them as a Faith upgrade)**.
- Every UI string, save key and code name that says DP for the budget is renamed to Might. The rename is mechanical.

## 7. Faith

- **Earned from believers (user):** every believer banked in Endless Night gives **1 Faith** **(my call: 1:1)**.
  Believers are earned exactly as on today's board: the main objective, each wish, and the tier's multiplier.
- **Spent on the Faith screen** (today's Upgrades screen, reworked):

| Upgrade | Price (*first guess*) | Limit |
|---|---|---|
| +1 slot | 150, 300, 450 | 3 (to 6) |
| +1 maximum Might | 25 × n for the n-th | 6 |
| +15 s on the descent clock | 40 × n for the n-th | 4 (+60 s) |
| Respec all ability points | 100 × n for the n-th | none |

- **More Faith upgrades later (user: "etc.").** The screen is a list, so new rows are data.

## 8. Divine Power and god level

- **Divine Power is experience (user).** It fills a bar; a full bar is one god level.
- **Earned per night *(first guess)*:** main objective `80 × tier`, each granted wish `20 × tier`, where tier is the
  night's mission tier. A lost night earns **none** **(user)**.
- **Caught after the main objective:** the main objective's Divine Power is kept; the wishes' is lost, as with believers.
- **Each level:** `50 × god tier` Divine Power *(first guess)*. With two wishes a won night is ~2.5 levels at Tier 1, so a
  tier's ten levels take ~5-6 nights including losses.
- **The cap (user):** god level 10, 20, 30 and 40 end a god tier. The bar stops at full until that tier's Awaken rite is
  won. Divine Power earned while capped is lost **(my call: simple and visible; the bar reads "AWAKEN TO GROW")**.
- **Maximum level 50 (user).**

| God tier | Levels | Name (today's tier names) |
|---|---|---|
| 1 | 1-10 | Whisper |
| 2 | 11-20 | Omen |
| 3 | 21-30 | Wrath |
| 4 | 31-40 | Reckoning |
| 5 | 41-50 | Ascendance |

## 9. Endless Night

### 9.1 A night

- **Endless Night hub** (the screen between nights): god type and level, the Divine Power bar, Faith, the Lantern Notice
  meter, `Night N`, and buttons **Descend**, **Skill Tree**, **Faith**, **Title**.
- **Descend picks the night:** a random mission from the god tier's five (`TierBook.MISSIONS`), never the one played last
  night **(user: random; my call: no repeat)**. The draw uses the slot's night seed, so quitting and coming back gives the
  same night.
- **What the night sets:** the mission's tier sets readiness, wishes heard and multiplier, as on today's board. The god's
  Might and slots come from §6; the clock is the tier's plus the Faith upgrade.
- **Prepare** drafts from learned abilities only, each at its learned level. A sealed ability (§10.3) shows a seal and
  cannot be drafted.
- **During the night:** today's descent rules: wishes, `THE NIGHT IS YOURS`, ASCEND, the bell and the Gaze as the mission
  sets them.
- **Every night played to its end counts** (won or lost).
- **No escape by quitting (my call):** in Endless Night, once the clock starts, abandoning or restarting from the pause
  menu counts as a **lost night**: no Divine Power, Notice +25%, a lost Hunt seals, a lost rite counts. The pause menu
  says so before it confirms. Leaving from Prepare, before the descent, is free. Otherwise the Notice and the Hunt would
  mean nothing.

### 9.2 The results screen

Shows, in order: the main objective and each wish; Divine Power earned and the bar filling, with a flash and
"+1 ability point" for each level gained; believers and Faith earned; the Lantern Notice change; `Night N`. Buttons:
**Continue** (to the hub), **Skill Tree**, **Faith**.

### 9.3 At the level cap

Once the god is capped (§8), the hub offers a second button beside Descend: **Awaken** (§11). Descend still plays a normal
night, which earns Faith but no Divine Power. The player chooses when to try the rite **(my call)**.

## 10. The Lantern Notice and the Lantern Hunt

### 10.1 The Notice (user: a meter in percent)

| Event | Notice |
|---|---|
| A lost night | +25% |
| Caught after the main objective (won, but Halcyon saw) | +10% |
| A clean win (ascended, no seen death) | −5% |
| A lost Awaken rite | +25% |

All amounts **(my call; user approved the recommendation)**. The meter shows on the hub and the results screen; it never
changes unseen. It does not go below 0% or above 100%.

### 10.2 The Hunt (user: an urgent night at 100%)

When the Notice reaches 100%, the next night is a **Lantern Hunt**. It cannot be skipped; Descend and Awaken both lead to
it. Its shape follows the god tier:

| God tier | Hunt night | Mission type |
|---|---|---|
| 1 | **Hide the faithful**: lead your believers out before the inquisitors reach them | Escort |
| 2 | **Silence the witness**: stop the runner carrying word of you to the Lantern | Intercept |
| 3 | **Expel the inquisitor**: drive out or kill the Lantern's captain in the town | Assassinate |
| 4 | **Break the hunt**: smash their standards before they reach your believers | Hunt |
| 5 | **Face Halcyon**: his Gaze is on the whole town, and a seen death fills it | Gaze rules |

- The five Hunt nights are new missions, each with its own short spec. Until those are written, each Hunt is played by
  a **stand-in** with the Hunt's title and plate, played at the god tier's settings **(my call)**:

  | God tier | Stand-in |
  |---|---|
  | 1 | Lost Lamb (Protect) |
  | 2 | Bell Ringers (Intercept) |
  | 3 | Informer (Kill), at Tier 3 settings |
  | 4 | Armoury (Destroy) |
  | 5 | Heart of Faith (Kill; the Gaze as every Tier 5 night) |

### 10.3 The Hunt's result

- **Won:** the Notice resets to 0%, plus bonus Faith (`50 × tier`, *first guess*). Divine Power as a normal night.
- **Lost:** the Lantern **seals** the god's **most-carried ability** for the next 3 nights, and the Notice resets to 50%.
  Level and points are kept.
  - Most-carried: the ability drafted on the most nights in this slot. Ties go to the higher Might cost, then the earlier
    tree spot. Nothing is random **(my call)**.
  - The hub and Prepare show the seal and the nights left.

## 11. The Awaken rites

### 11.1 The idea

Halcyon, the Lantern, feeds on his worshippers' faith. On an Awaken night the god captures Lantern worshippers, drags them
to its old shrine (Mira's shrine at the forest edge) and sacrifices them. Each death there takes a piece of Halcyon's
light. Halcyon answers, and the town fights harder after every sacrifice **(user: the idea; my call: the details)**.

### 11.2 The Rite (a new mission type)

- **Chain of the Forgotten:** the night grants this rite power at no Might. It is **not a slot** (the god may already
  have 6, the HUD's limit): it is its own plate beside the slots with its own key, C (R is restart) **(my call)**. Click a marked
  worshipper to chain them; they are dragged toward the shrine. Every god type gets the same chain, and its own abilities
  keep the drag safe, so every type can win.
- **The drag** takes 60 s or less. Guards and clergy try to break the chain. Where the rite has Halcyon's searchlight, a
  captive it touches goes free. A freed captive is a setback, not a loss.
- **Sacrifice:** a captive who reaches the shrine gives one **Lantern shard**. The rite needs 3-4 shards. There are always
  more marked worshippers than shards needed.
- **Losing:** the clergy put out the shrine's flame (they march on it after each sacrifice), or dawn. The bell never loses
  on its own; a toll turns the Lantern as on every mission (§13).
- **A captive who dies away from the shrine** is wasted, never a loss.

### 11.3 The four rites

| At level | Rite | Victims | Halcyon answers with | Stolen gift |
|---|---|---|---|---|
| 10 | The First Taste | 3 of 5 lamplighters | Clergy marching to cleanse the shrine | The Watchful Bell |
| 20 | The Inquisitor's Light | 3 inquisitors, then Sister Venn | The searchlight | Walls that Hold |
| 30 | The Hollow Saint | A living saint carrying Halcyon's blessing | Halcyon's Gaze fills with each sacrifice | Plagues Stay Away |
| 40 | The Voice Silenced | Archprelate Odran, Halcyon's voice on earth | Gaze, searchlight and clergy together | Halcyon's Voice |

Each rite gets its own short mission spec (numbers, spots, events) for the user's approval before it is built.

### 11.4 Stolen gifts

Each won rite takes one of Halcyon's protections for good. It makes every later Endless Night town weaker in one way
(*first guesses*):

| Gift | Effect in every later night |
|---|---|
| The Watchful Bell | A bell ringer takes +20% longer to start the toll |
| Walls that Hold | Buildings take +20% damage |
| Plagues Stay Away | Sickness, curses and madness spread 25% faster |
| Halcyon's Voice | Guards and clergy panic 20% sooner |

### 11.5 Winning a rite

A rise of light from the shrine into the god in slow motion (the ascend effect, larger), then a plate with the new tier's
name, **+2 ability points**, and the stolen gift's name and effect. The level cap lifts. Divine Power for the rite: none
(the bar was full).

### 11.6 Eclipse (optional, at level 50)

At level 50 the hub offers **Eclipse**: put out the Temple's great lantern and eat Halcyon. Winning it plays a true ending.
Afterwards the slot keeps playing nights for Faith and the Notice; the god is complete **(my call; the user accepted it
as optional)**. Its mission spec comes last.

## 12. Screens

| Screen | New or changed | Holds |
|---|---|---|
| Slot select | New | 3 slots: type, level, tier, night; New / Continue / Delete (with a confirm) |
| God select | New | The ring of six types; each shows its name, one line of flavour, its two Tier 1 spots (or "Not yet chosen"), and its neighbours |
| Endless Night hub | New (replaces the campaign screen) | §9.1 |
| Skill Tree | New | Own type in the middle with its neighbours on each side marked ×2; far types hidden. Rows are tiers 1-5; locked tiers dim with "Awaken to Tier T". Each spot: icon, name, level pips 1-5, Might cost, next level's cost in points and what it changes; level 5 shows the twist. |
| Faith | Reworked Upgrades screen | §7 |
| Prepare | Changed | Endless Night: learned abilities only, levels shown, seals shown; Board: everything plus the level picker |
| Results | Changed | §9.2 |

The exact layout is the builder's, within today's UI theme and the 640×360 frame the other screens use.

## 13. Mission rules that bind every new night (Hunts, Rites, Eclipse)

From the user's standing rules (v0.11, v0.11.2):

- **No waiting:** every timed wait is 60 s at most; doing nothing loses; an acting player is idle for 45 s at most.
- **Chain pacing:** the next item comes at its time, or no more than 45 s after the last one is done.
- **Opposition is work:** guards and crews are spread more than two Silent Doom radii apart.
- **No luck:** success never depends on street traffic.
- **No hidden losses:** hold the director's people through an evacuation; anyone whose death loses is tagged DO NOT KILL;
  every instant loss is warned plainly, with room to act.
- **The bell never loses outright:** a toll turns the Lantern instead (`MissionDef.lantern`).
- **Clarity:** every moving target is edge-arrowed; tags count down.

## 14. Suggested order (my call)

| Milestone | Builds | Playable at its end |
|---|---|---|
| **P1 Framework** | Slots and save, god select, `GodTree` (60 empty spots), points and the tree screen, ability levels plumbed (`extra["level"]`, Might rising), Divine Power and levels with the cap, Faith and the Faith screen, Might rename, Endless Night hub and night loop, results, board as test mode with the level picker | Endless Night loop from the DEV tab, with a dev fill of the tree (§15); on the title once the user's Tier 1 fill lands (§3) |
| **P2 Lantern** | The Notice, the Hunt with stand-ins, seals | The Notice and its penalty |
| **P3 First Rite** | The Rite director, Chain of the Forgotten, The First Taste, stolen gifts | Tier 1 to Tier 2 |
| **P4 Rites 2-4** | The other three rites | Tiers 2-5 |
| **P5 Hunts and Eclipse** | The five Hunt nights to replace the stand-ins, then Eclipse | All of it |

The tree's filling and each batch of ability levels and twists run alongside, as the user decides them. Each fill
batch runs the per-type win check (§5.2) before it lands, and may need new powers for the small types.

## 15. Left to the builder

- Layouts, colours and icons inside the existing UI theme.
- The XP and Faith numbers, within the first guesses above, tuned with the scripted test players.
- How `extra["level"]` reaches each effect, as long as an effect without a `levels` table plays as today.
- Test fixtures: a **dev fill** of `GodTree` for tests and scripted play, kept out of the real table, so an empty tree
  never blocks testing.
- Save keys and file structure inside §4's list.
