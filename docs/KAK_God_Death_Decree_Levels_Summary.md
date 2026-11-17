# Kingdoms Amid Kataclysm (KAK) - Death and Decree Ability Levels Summary

*Engine: Godot 4.7.2. Branch `god/dd-levels` (base `76c03af1`, plan commit `4efcc819`, head `cf1a1a62`), landing on `feat/god-progression`. Each of Death's ten powers and Decree's ten powers now has five levels and a level-5 twist. Built 2026-11-17, subagent-driven: a groundwork task in two halves, twenty twist tasks in three parallel tracks, an opus final review that said "with fixes", one fix wave plus one small residual fix, and this note. Spec: `docs/superpowers/specs/2026-11-16-kak-death-decree-ability-levels-design.md` (approved 2026-11-17; the user said "Go"). Plan: `docs/superpowers/plans/2026-11-17-kak-death-decree-ability-levels.md`. Every ruling is in `docs/KAK_God_Death_Decree_Levels_Rulings.md`. The frame is the same as Ruin, Dominion and Passage: `docs/KAK_God_Dominion_Levels_Summary.md`.*

Death is "every life is a loan". Every level reaches more people, for longer, and comes back sooner. Every Death twist collects the debt: a death the power causes feeds something new. Decree is "your word is law". Every level covers more ground and holds longer. Every Decree twist adds one more clause, or lets the law outlive the cast. No twist is a random roll.

## What levels do

- Each power has **five levels**. Each level raises two to four of its numbers by a few percent (tables below), and most raise the cooldown too.
- **Level 5 adds a twist**: one more beat in the power's own story. A level-4 cast never shows it.
- **Level 1 is today, exactly.** Hunts, routes and the reference set play at level 1. `digest` `61267b7e90524d800bf1c3473a71146b` stayed the same at every task. `crowd_check` was OK at every task (`-535548941` at the groundwork).
- **Might** is not in the tables. It is the existing rule (base cost at levels 1-2, +1 at levels 3-4, +2 at level 5). Tier 5 pairs at level 5: Serpent 8 + Grave Tide 8 = 16, Cage 8 + Verdict 8 = 16. Both sit at the cap.
- Tier 5 powers are once a descent at every level, so they have no cooldown column.
- The skill tree prints what the next level changes, and level 5 prints the twist line. The Prepare card shows it for a level-5 draft.

## The twenty tables

Level 1 / 2 / 3 / 4 / 5. Names are the effect's own constants. Cooldown is in seconds.

### Death

| Tier | Power | Stat | Values | Cooldown |
|---|---|---|---|---|
| 1 | Death Mark | `MARK_TIME` (quicker death) | 10 / 9.5 / 9 / 8.5 / 8 | 20 / 19 / 18 / 17 / 16 |
| | | `GAWKERS` (who look) | 8 / 9 / 10 / 11 / 12 | |
| | | `LOOK_R` (look reach) | 4 / 4.25 / 4.5 / 4.75 / 5 | |
| 1 | Raise the Dead | `ZOMBIE_LIFE` | 30 / 32 / 34 / 36 / 38 | 25 / 24 / 23 / 22 / 21 |
| | | `CHAIN` (whole cast) | 3 / 3 / 4 / 4 / 5 | |
| | | `SPIRIT_LIFE` | 20 / 21 / 22 / 23 / 24 | |
| 2 | Pestilence | `INFECT_MAX` | 3 / 3 / 4 / 4 / 5 | 48 / 46 / 44 / 42 / 40 |
| | | `INFECT_R` | 1.2 / 1.3 / 1.4 / 1.5 / 1.6 | |
| 2 | Gravecall | `SPIRITS` (wraiths) | 3 / 3 / 4 / 4 / 5 | 30 / 29 / 28 / 27 / 26 |
| | | `HAUNT` | 20 / 21 / 22 / 23 / 24 | |
| | | `FREEZE` (soldier) | 3 / 3.25 / 3.5 / 3.75 / 4 | |
| 3 | Corpse Guise | `MOST` (hidden) | 4 / 4 / 5 / 5 / 6 | 50 / 48 / 46 / 44 / 42 |
| | | `MARK_R` | 2 / 2.1 / 2.2 / 2.3 / 2.4 | |
| | | `SPAN` | 25 / 27 / 29 / 31 / 33 | |
| 3 | Walking Corpse | `WALK_LIFE` | 40 / 42 / 44 / 46 / 48 | 30 / 29 / 28 / 27 / 26 |
| | | `KILLS_MOST` | 2 / 2 / 3 / 3 / 4 | |
| | | `ATTACK_R` | 6 / 6.25 / 6.5 / 6.75 / 7 | |
| 4 | The Gate Below | `REACH` (arms) | 6 / 6.25 / 6.5 / 6.75 / 7 | 90 / 87 / 84 / 81 / 78 |
| | | `EDGE` (lip, 0.7 of reach) | 4.2 / 4.375 / 4.55 / 4.725 / 4.9 | |
| | | `SPAN` | 12 / 12.5 / 13 / 13.5 / 14 | |
| | | `WRAITH_TOUCHES` | 3 / 3 / 4 / 4 / 5 | |
| 4 | Pale Reign | `RADIUS` | 10 / 10.25 / 10.5 / 10.75 / 11 | 120 / 116 / 112 / 108 / 104 |
| | | `SPAN` | 16 / 17 / 18 / 19 / 20 | |
| | | `HORDE_KILLS` | 24 / 26 / 28 / 30 / 32 | |
| 5 | The Pale Serpent | `LENGTH` | 14 / 14.5 / 15 / 15.5 / 16 | once a descent |
| | | `BAND` (half width) | 2 / 2.1 / 2.2 / 2.3 / 2.4 | |
| | | `SIGHT` | 12 / 12.5 / 13 / 13.5 / 14 | |
| | | `SICK` | 20 / 21 / 22 / 23 / 24 | |
| 5 | Grave Tide (giant only) | `GIANT_LIFE` | 60 / 63 / 66 / 69 / 72 | once a descent |
| | | `GIANT_BLOWS` | 12 / 13 / 14 / 15 / 16 | |
| | | `SLAM_R` | 3.5 / 3.6 / 3.7 / 3.8 / 4 | |
| | | `SLAM_WRECK` | 60 / 65 / 70 / 75 / 80 | |

### Decree

| Tier | Power | Stat | Values | Cooldown |
|---|---|---|---|---|
| 1 | Leaving Is Prohibited | `RADIUS` | 3 / 3.15 / 3.3 / 3.45 / 3.6 | 20 / 19 / 18 / 17 / 16 |
| | | `HOLD_TIME` | 15 / 16 / 17 / 18 / 19 | |
| 1 | Breathing Is Prohibited | `RADIUS` | 2.5 / 2.65 / 2.8 / 2.95 / 3.1 | 25 / 24 / 23 / 22 / 21 |
| | | `HOLD_TIME` | 8 / 8.5 / 9 / 9.5 / 10 | |
| 2 | Redefine | `MAX_NAMED` | 3 / 3 / 4 / 4 / 5 | 45 / 43 / 41 / 39 / 37 |
| | | `SPAN` | 25 / 27 / 29 / 31 / 33 | |
| 2 | Bound in Law | `REACH` | 10 / 10.5 / 11 / 11.5 / 12 | 45 / 43 / 41 / 39 / 37 |
| | | `SPAN` | 20 / 22 / 24 / 26 / 28 | |
| 3 | Erasing Distance | `MAX_LEN` | 10 / 10.5 / 11 / 11.5 / 12 | 60 / 58 / 56 / 54 / 52 |
| | | `CRUSH_W` | 1 / 1.05 / 1.1 / 1.15 / 1.2 | |
| | | `THROW_W` | 3 / 3.15 / 3.3 / 3.45 / 3.6 | |
| 3 | Disorder | `RADIUS` | 5 / 5.25 / 5.5 / 5.75 / 6 | 45 / 43 / 41 / 39 / 37 |
| | | `HOLD_TIME` | 15 / 16 / 17 / 18 / 19 | |
| 4 | Eminent Domain | `LENGTH` | 10 / 10.5 / 11 / 11.5 / 12 | 80 / 77 / 74 / 71 / 68 |
| | | `HALF_W` | 1 / 1.05 / 1.1 / 1.15 / 1.2 | |
| 4 | Fenced Rule | `RADIUS` | 7 / 7.25 / 7.5 / 7.75 / 8 | 80 / 77 / 74 / 71 / 68 |
| | | `HOLD_TIME` | 30 / 32 / 34 / 36 / 38 | |
| 5 | The Closing Cage | `RADIUS` | 12 / 12.5 / 13 / 13.5 / 14 | once a descent |
| | | `CLOSE_TIME` (shorter is harder) | 30 / 29 / 28 / 27 / 26 | |
| 5 | The Sealed Verdict | `RADIUS` | 10 / 10.5 / 11 / 11.5 / 12 | once a descent |
| | | `COUNTDOWN` (shorter is harder) | 30 / 29 / 28 / 27 / 26 | |

Some numbers stay put on purpose, to hold the frame cost: Raise's ring and body count, Pestilence's plague, Breathing's 3 s choke, the Gate's 36 arms, Pale's 24 ghosts and 16 servants, the Serpent's fog and frost caps, the tide's graves, cap and undead life. The area, danger-time and alarm tables in `power_book.gd` stay at level 1.

## The twenty twists (level 5 only)

Four take a follow-up order and are marked **(click again)**. Where the build departs from the spec text, the line says so.

### Death

- **Death Mark, The Wake.** When the first person to stop and look reaches the body (within 1.0), it gets up as a zombie among the crowd it drew. Raise's own zombie at level 1 numbers, chain of 3 for this cast alone. The body is used up. The plague carries over if the body was sick.
- **Raise the Dead, Body and Soul.** One cast gives both halves for the ring's own bodies. A zombie that falls or times out lets its soul rise as a spirit. A spirit that fades sinks back and the body rises as a zombie (it spends the cast's chain). Once per body. Chain risers give no spirit.
- **Pestilence, Foul Dead.** Everyone the cast's plague kills (and everyone it spread to from them) leaves a body that breathes green miasma for 15 s. Healthy people within 1.2 catch the plague. Each body infects 3 at most. A source id travels with the infection to tell the casts apart.
- **Gravecall, Swelling Host.** Anyone who dies in the haunt circle while the wraiths haunt it rises as one more wraith (4 more at most). The body stays.
- **Corpse Guise, Deathless.** A guised person whose death comes (struck, crushed, bitten, choked; never taken whole, and never the rite's kill) falls and lies as a body for 5 s, unhurt. They get up at full health and the guise holds 10 s more. Once per person. No kill is counted and no alarm rises.
- **Walking Corpse, Borrowed Life.** After each ATTACK kill the corpse takes the victim's face and clothes, and the victim leaves no body (no gathering, no alarm). The kill counts as a death and is credited to the power. At the end it lies down as the last victim.
- **The Gate Below, Graves Answer.** While the rift is open, the 8 nearest bodies within 12 sprout a grave hand. Each holds the nearest living person within 1.5 for a moment, then drags them under (no body), and sinks its own body with them. Each one taken climbs out as a wraith when the rift closes.
- **Pale Reign, The Pall Grows.** Every death in the district widens it by 0.25, up to 3 wider (12 deaths). Whoever the new edge reaches crawls with the rest, and its fires gutter. The span does not change. The cast's danger stays at the cast-time radius.
- **The Pale Serpent, Shed Skin.** The skin lies along the whole path for 30 s, a pale band 1 wide. Whoever walks onto it sickens like those who saw it rise. Each person once.
- **Grave Tide, Scattered Bones.** When the giant falls, 18 bones burst out and land as the tide's own clawed skeletons (departs from the spec's bare skeletons: they claw buildings as the tide's skeletons do, C8). They hunt for 20 s, count in the living cap of 60, and their kills do not rise. They survive a late fall.

### Decree

- **Leaving Is Prohibited, Held for Trial.** When the cell breaks, everyone still held inside it is named CRIMINAL for 15 s and the guards hunt them. The god's faithful are never named.
- **Breathing Is Prohibited, And None May Leave.** For the first 2 s the circle is sealed as the amber cell is (nobody leaves, the faithful too). Then leaving saves again: only those who reach the edge between 2 s and 3 s get out.
- **Redefine, Precedent (click again).** While the names hold, click a person within 2 of a named one to give them the same name for the rest of that name's time. 3 more names at most.
- **Bound in Law, Party to the Bond.** Whoever strikes one of the bound joins the bond (2 more at most) and shares its fate, the blow they struck included. Joiners come by strike or seize, not stun (departs from the spec: no stun source exists, DL13). The director has no seizer lookup today, so in practice only strikes add a joiner.
- **Erasing Distance, Shortcut.** When the line springs back, its two ends stay joined for 15 s, each with a gilt seam. Whoever steps within 0.6 of one end comes out at the other. An arrival stands where it landed until it steps away from that end (departs from the plan's 1 s rest, C9).
- **Disorder, Bad Counsel.** Whoever crosses out of the circle carries the disorder for 8 s: their choices stay wrong wherever they go. It does not spread from them.
- **Eminent Domain, Further Claim (click again).** Within 5 s of the first strip, click to claim a second strip from the first strip's end toward the click, up to 6 long, same width. The preview during the window is a small ring, not a lane (departs from the spec).
- **Fenced Rule, Third Clause (click again, by wheel).** Once while the fence holds, an order wheel on the fence's centre sigil adds a third rule of its own. The wheel words are NO RUN, NO ARMS, NO DOORS, NO SIGHT and NO EXIT (departs from the spec's Q/E keys: the wheel is the same input Walking Corpse uses, DL12).
- **The Closing Cage, Dragged Cage (click again).** Once while it closes, click to move the centre up to 6 toward the click over 2 s. Everyone inside is dragged along, and every building the bars cross is crushed.
- **The Sealed Verdict, The Ledger Remembers.** Everyone who stood in the district at any moment of the countdown (one frame counts, indoors in district houses too) dies at the bell wherever they are, indoors too. Shelterers are released before the kill.

## The follow-up inputs

The shared follow-up mechanism came from the Dominion milestone and is reused.

- **Precedent, Further Claim, Dragged Cage:** select the power's slot again (number key or card; allowed while it cools), then click the ground. Free. It starts no cooldown and sends no `cast_made`.
- **Third Clause:** select the Fenced Rule slot again. The order wheel opens on the fence's centre sigil. Pick a word on the wheel, then click to take it.
- A click that finds nothing (a Precedent click near no named one, a click on the cage's centre) is refused, never cast.
- While an order can be given, the HUD slot card turns gold and the tree and Prepare card say "click again".

## How to try them

- **Board:** the Prepare screen's level picker (1-5) per drafted power feeds the mission.
- **Bench:** `--bench-cast=KEY --bench-level=5` casts one power at that level in the sandbox (`--bench-level` defaults to 1).
- **Tree:** the detail line shows the next level's changes, and the level-5 line shows the twist.
- **The four follow-ups need real input:** cast, wait out the busy lock, select the slot again, click.

## What the groundwork added

- Tables and stat reads on all twenty rows, previews that follow the level (the Serpent's frighten radius and frost patch follow `BAND`; the Sealed Verdict's rune count follows the countdown). `NO_LEVELS` is gone from every Death and Decree row.
- Shared hooks, inert until a twist calls them: `Person.plague_src` and `PlagueManager.foul_from`, `Person.carried_laws` with `Crowd.in_law`, `Person.struck_by` and `Crowd.clock()`, the `&"borrowed"` kill kind, `Person.deathless`, and `--bench-level`.
- The final fix wave added `Person.knock_down(lie, force)`, `deathless_lie`, `stand_up()` and `_down_total`, all inert at level 1.

## Commits (`4efcc819..cf1a1a62`, branch `god/dd-levels`)

- `4efcc819` plan. `6bdc5f7f` tables and stat reads. `94a609ae` shared hooks.
- Death twists: `94cb2062` Mark, `db4b3bcf` Raise, `bc1a2985` Pestilence, `19c02244` Gravecall, `5d4a0f79` Guise, `cc54b4c7` Walker, `85caa50d` Gate, `73d10353` Pale, `7b67914d` Serpent, `df542c8f` Tide.
- Decree twists: `ce4806cc` Leaving, `ebad833a` Breathing, `45bd61c8` Redefine, `de6b66e1` Bound, `45def175` Erase, `8f67cfa5` Disorder, `b11b7b68` Eminent, `cc02827d` Fenced, `5724b03f` Cage, `8821e8a1` Sealed.
- Fix rounds: `0465200e` and `294da137` (Wake), `5772bd93` (Graves Answer), `1778bc79` and `137fa8bc` (Held for Trial tests), `5af7fb77` (Foul Dead), `4462da06` (Scattered Bones), `f1c4328f` (Shortcut), `68c97b33` (Ledger), `4f45257b` and `3a061639` (Third Clause wheel words).
- Merges: `f8ef912b` track B and `c60497c4` track C (track A fast-forwarded to `cc54b4c7`).
- Final review fixes: `2907492c`, residual `cf1a1a62`.

## Tests

- New: `tests/test_death_levels.gd` and `tests/test_decree_levels.gd` (tables, level one, Might, cooldown, tree text), `tests/test_dd_hooks.gd` (the shared hooks), ten `tests/test_death_twist_<key>.gd` (deathmark, raise, pestilence, gravecall, guise, walker, gatebelow, pale, serpent, gravetide) and ten `tests/test_decree_twist_<key>.gd` (noleave, breath, redefine, bound, erase, disorder, eminent, fenced, cage, sealed). Each twist has a level-4 case that shows nothing, and most have a teardown case.
- Every focused suite ended `failures=0`. Digest and crowd_check were OK at every task.
- **Not judged on the whole:** the full suite, all 546 reference rows and FLOW were not run to a clean result, because other sessions kept the machine loaded. They are owed at landing (see the rulings note).

## Not done, on purpose

- Numbers are first guesses, to tune in play. No twist has been looked at in a real window: the suites run headless.
- Windfall and the Folded Ward (Passage) still have no table.
- Deferred minors are listed in the rulings note.
