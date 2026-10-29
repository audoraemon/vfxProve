# Kingdoms Amid Kataclysm (KAK) - God Progression P3 Summary

*Engine: Godot 4.7.2. Branch `god/p3-rite`, landing on `feat/god-progression` (base `a0185497`, tag `kak-god-p2`). P3 is the "First Rite" row of spec §14: the Awaken button at the cap, the Rite mission type, the Chain of the Forgotten, the first rite (The First Taste, level 10), the win plate and the first stolen gift. Built 2026-10-28 and 2026-10-29, straight through and subagent-driven: 8 build tasks (five with a review and a fix round), a landing task, this note, an opus milestone review, one fix wave and one Passage policy round (tip `183c8781`). Mission spec: `docs/superpowers/specs/2026-10-28-kak-god-p3-first-taste.md` (cited MS §n). Parent spec: `docs/superpowers/specs/2026-10-26-kak-god-progression-design.md` (cited as section numbers). Plan: `docs/superpowers/plans/2026-10-28-kak-god-progression-p3.md`. Every ruling is in `docs/KAK_God_P3_Rulings.md`. P1 and P2 are in `docs/KAK_God_P1_Summary.md` and `docs/KAK_God_P2_Summary.md`.*

## What you asked

When a god reaches the level cap (10 at Tier 1) it cannot grow until it Awakens. P3 builds the first Awakening. A capped god gets an **Awaken** button beside Descend. It opens a rite: a short mission with its own rules, played with the abilities you learned, plus one new power that only a rite grants. Win it and the god crosses into Tier 2, gains 2 ability points and steals a gift from Halcyon. Lose it and the Lantern Notice rises 25% and you try again the next night. P3 changes no existing mission rule and moves no reference.

## What P3 adds

### The Awaken button (spec §9.3)
- The hub shows five buttons (`Descend, Awaken, Skill Tree, Faith, Title`, 108 px each) while the god is capped and below level 50; otherwise P1's four. Key A does the same.
- Three states, by `GodNight.awaken_state()`: hidden (not capped, or level 50); `rite` (a rite is written for this level: lit); `unwritten` (levels 20, 30 and 40 in P3: dim, and a click buzzes and says `Rite not yet written`). Under `--dev` the A key still opens P2's dev hook for the unwritten levels.
- **The Hunt comes first.** While the Notice is 100% the button opens the Hunt exactly as Descend does, whether a rite is written or not; the rite waits for the next night. A god with nothing to draft (every learned ability sealed) sees the button dim and buzzing, as Descend does.
- `Game.awaken_target(slot)` is the one decision (a rite id, the Hunt's id, or nothing) and is unit-tested.

### The Rite mission type (MS §1)
A rite is a night that is not an ordinary night. Its Prepare screen has the gold header `THE AWAKENING RITE` and six rows: RITE (the name), WIN, LOSE, IF WON (`Tier 2: Omen, +2 ability points, the gift`), IF LOST (the real Notice rise and the coming Hunt when it applies; `Lantern Notice +25%; the god stays capped` at Notice 0) and CHAIN (`Chain of the Forgotten (C): free`). The draft is the god's learned abilities at their levels, its slots and Might; seals apply.

| Part | Rule |
|---|---|
| Town and clock | The god tier's frame: an Unaware Tier 1 town, 5:00 plus the Faith clock. No wishes, no believers, no Faith. |
| Objectives | `Lantern shards n/3` (main), the shrine's flame (lost if cleansed), Dawn. |
| The bell | `lantern = "watch"`: a toll turns the Lantern but never loses the rite. |
| Win | The last shard ends the night at once; no ASCEND phase, so nothing to be caught at. |
| Won | Night +1, a seal ticks, the god Awakens (tier +1, +2 points, the cap lifts, the bar re-levelled), the gift is stolen. The Notice does not move. No Divine Power. |
| Lost | The flame cleansed, dawn with fewer than 3 shards, an abandoned rite, or a game closed after the clock started. Night +1, a seal ticks, Notice +25% (the real rise after the limit), the god stays capped, no Divine Power. |
| Draw and bests | A rite keeps no best and leaves the last mission and the night before a Hunt as they were, so the next draw is as if it had not been played. Its draft counts as carried. |
| Timers | Chain, drag, muster and cleanse run in real seconds; a toll speeds only dawn. |
| Where else | The Missions board's DEV tab lists `The First Taste (rite)` last, for testing and the scripted player. |

A rite abandoned from the pause menu, from the interlude, or by closing the game after the clock started is charged like a lost rite. The pause confirm says so first (`Abandon the rite and it is lost: Lantern Notice +25%. The god stays capped.`, with the Hunt named when the rise fills the meter, and a full-meter variant that promises no rise).

### Chain of the Forgotten (MS §2)
The rite's power. Key **C**, a plate above the slot row's right end (100 x 20 px: `C CHAIN` over `READY`, `DRAG 0:41` or the cooldown). Granted by the rite, costs no Might, and is never in the loadout.

| Part | Rule |
|---|---|
| Aim | C, then click a **marked** victim anywhere on the map. A second C, Esc, right-click, or a slot key lets the aim go. Refused with `NOT A LAMPLIGHTER` or `ONE CHAIN AT A TIME`; a victim indoors or with no walk path says `THE CHAIN CANNOT REACH HIM`. |
| Cooldown | One chain at a time; ready again **8 s** after a chain ends. |
| The drag | The captive kneels 1 s, then walks the path to the shrine at pace `max(0.6, path / 55 s)`: a drag never takes more than 55 s. He leaves by the Main Gate. He shakes off fear and Whisper while chained, and no town traffic can stop him. |
| What breaks it | A **breaker** (the Watch or a marching cleric) that reaches him grips the chain; a red ring fills over him for 3 s and then the chain breaks. The grip resets if the breaker is killed, frightened, held by the god (Whisper, Discord, Leaving Is Prohibited, The Bell Lies' call, Death Mark's frailty), shoved off or folded away. |
| Yank | C again during a drag: the captive lurches 1.5 units on, a grip resets and its breaker is stunned 1 s. Once per drag. |
| Freed captive | Runs for the Temple's door. He stays marked and can be chained again; one who gets in is safe. |
| Never stuck | A captive whose walk finds no way is sent on again every tick; one who stands still 8 s with nobody gripping him is let go like a broken chain, and does not count as a victim left. |
| Sacrifice | A captive within 1 unit of the shrine dies on its stone: +1 shard. The sacrifice is quiet: no alarm, no incident, no kill the Lantern's death judging hears. |
| The god's own powers | A captive struck by them dies like anyone (wasted, never a loss). Leaving Is Prohibited never holds a chained captive. A Mirrorfold way in on his path folds him through. |

### The First Taste (MS §3)
*"Halcyon's lamplighters keep his light in the streets. Drag three to Mira's shrine."* Mira's shrine stands outside the west wall at (-17.6, 5.0); its flame burns from 0:00 and grows one step per shard.

| What | Value |
|---|---|
| Victims | 5 lamplighters, each the resident or labourer nearest his round's first lamp, on a loop of 4 lamps (4 s at each) from 0:00. A gold `LAMPLIGHTER` tag with a lantern glow, edge-arrowed. No new art. |
| The Watch | 4 soldiers at fixed posts (Main Gate west and east, the shrine road, the shrine approach), each seeing 2.5 units, all over 1.6 apart. They are breakers; they are not replaced when killed. |
| Halcyon answers | After shard 1 a march of 2 clergy, after shard 2 a march of 3. 10 s muster at the Temple door (tag `CLERGY MARCH IN 0:10`, banner `HALCYON ANSWERS - CLERGY MARCH ON THE SHRINE`), then they walk in file 1.8 apart. Marchers are breakers too. |
| The march | Each marcher walks the way to the shrine in **at least 88 s** (a floor on his speed), so the flame is never out sooner than about 110 s after the shard that sent them (10 + 88 + 12). Measured: 120 s for the quickest clergy, 124 s usual, 140 s slowest. |
| The cleanse | 2 marchers kneeling at the shrine for 12 s (`THE CLERGY CLEANSE THE SHRINE`, a ring on the shrine, `CLEANSING 0:12`). A kneeler killed, frightened or held resets the ring. The flame out loses the rite. |
| Stopping a march | Fewer than 2 able marchers (dead or fled) and it breaks (`THE MARCH BREAKS`). A held marcher walks on afterwards: a delay, not a stop. |
| Never a dead end | If the lamplighters left (not dead, not safe, not stranded) fall below the shards still needed plus one, a new lamplighter sets out from near the Temple door on the round whose man is gone (`A NEW LAMPLIGHTER SETS OUT`). |
| Warnings | The march has a countdown tag, a strip row (`The clergy reach the shrine`) and a hint; the captive's tag counts down (`CAPTIVE - SHRINE IN 0:38`); the clock goes red under 30 s. Nobody's death loses, so no DO NOT KILL tag. |

### Stolen gifts (MS §4)
A won rite appends the gift `watchful_bell` to the god (once each, never removed). Every later Endless night (ordinary, Hunt or rite) carries it onto its `MissionDef`. **The Watchful Bell** multiplies every bell climb by 1.2: the bellkeeper's 8 s becomes 9.6 s; a stand-in's x1.5 stacks on it (9.6 becomes 14.4). It touches the climb only, not the Herald's descent. `Crowd.climb_scale` is 1.0 on the board, the campaign and every reference, so those nights are byte-identical. It shows on the hub (`Stolen gifts: The Watchful Bell`), on an ordinary night's Prepare (a GIFTS row in place of CITY) and on the rite's win.

### The win and the screens (MS §5)
- **The win plate.** The shard's light rises from the shrine in slow motion for 4 s at twice the ascend effect's size, with a plate at y 164-244 (below the banner bar and Cael's line): `AWAKENED - OMEN`, `+2 ability points`, `Stolen: The Watchful Bell`. The slots, the stack and the chain plate are hidden while it shows. The win is banked the moment it is decided, so a window closed during the plate keeps the Awakening.
- **Results.** `THE RITE IS DONE` (won) or `THE SHRINE IS CLEANSED` (lost, red); the goal row ticked from the result; `Tier 2: Omen`, `+2 ability points` and the `Stolen:` line in gold; or `Lantern shards 2/3` and the red `The god is still capped. Awaken again when ready.`; Divine Power `none - the rite feeds no bar`; the Notice and `Night N`.
- **HUD.** Rings: a red ring fills clockwise over a gripped captive and over the shrine while it is cleansed. The strip merges the director's rows with the timeline's. Edge arrows and diamonds keep clear of the chain plate; a repeated refusal queues one banner.

### Tools and tests
- Scenario: `--scenario=first_taste` (with `--god=<type>:1` it plays that type's two Tier 1 abilities at level 1). The per-type scripted player lives in `tools/dev/behaviour_check.gd` (`_first_taste_*`, the `FT_*` consts documented in place). Its state line shows `captive=`, `flame_in=`.
- Photographs (`tools/capture.sh --show=<name>`): `hub-awaken`, `hub-unwritten`, `hub-gifts`, `prepare-rite`, `prepare-gifts`, `results-rite-won`, `results-rite-lost`, `pause-rite`, and the mission shots `first_taste-start`, `-six`, `-modes`, `-drag`, `-march`, `-walk`, `-cleanse`, `-win`. All were looked at.
- New suites: `test_god_rite` (84), `test_watchful_bell` (21), `test_rite_director` (103), `test_first_taste` (122), `test_rite_hud` (91). Additions to `test_faith_hub` (82), `test_endless_screens` (192), `test_endless_flow` (69), `test_board_test_mode`, `test_tier_board`, `test_mission_hints` and `test_mission_needs` (29 missions).
- FLOW gained a rite walk (`_flow_rite`, 25 checks): Awaken routes to the Hunt when due, the rite's Prepare, a real C and a real click, an Esc that ends the aim, three wins through `offer()` with the march banners, the Awakening on the results and the hub, a lost rite, and the board's save bytes.

## How to see it

1. The DEV path: run with `--dev` (`& $godot --path . --scene res://scenes/game.tscn -- --dev`), open the Missions board, `ENDLESS`, New, choose a type, Choose. Bring the god to its cap (level 10): either play it there, or set `level = 10` in the slot's file `user://kak_god_<n>.cfg` (the cap clamps it). The hub then shows five buttons; Awaken (or A) opens the rite's Prepare.
2. Quicker for looking only: the board's DEV tab, `The First Taste (rite)` card (every power open, no Descent).
3. In the rite: C, click a gold lamplighter, answer the Watch with your powers, press C again to Yank. After a shard watch the strip for the march. Three shards win.
4. The scripted player: `bash tools/dev/gate.sh first_taste --extra='--god=ruin:1 --dev-tree' --jobs=6` (see the numbers below).
5. Photographs: `tools/capture.sh --show=prepare-rite` and the others above.

## The numbers in play

| Number | Value | |
|---|---|---|
| Shards, victims, Watch posts | 3, 5, 4 | exact (MS §3.1) |
| Marches | 2 clergy after shard 1, 3 after shard 2; muster 10 s | exact; muster *tunable* |
| Cleanse | 2 kneeling for 12 s | exact |
| March walk floor | 88 s per marcher; flame never out before about 110 s | exact (controller ruling) |
| Chain | cooldown 8 s, bite 1 s, drag at most 55 s at pace 0.6 or more, grip 3 s, Yank 1.5 units and 1 s stun, one per drag | *tunable* (`RiteDirector` consts) |
| Stuck captive | let go after 8 s standing still, 0.3 units | exact |
| Rite stakes | won: Tier +1, +2 points, the gift, Notice unchanged; lost: Notice +25%, still capped | exact |
| Watchful Bell | bell climb x1.2 | *tunable* (`RiteBook.GIFTS`) |
| Save format | unchanged (`VERSION` 1); a rite is `in_night`'s id, the gift is in the existing `gifts` list | exact |

### Every type clears The First Taste with its own Tier 1 abilities

The scripted player (shared plan: chain the lamplighter with the shortest way, answer a breaker within 4 units, Yank past 1.5 s of a grip, answer a march first when it is within 45 s of the shrine; each type adds its own answers from MS §3.8) played every type on seeds 1-3 (Decree and Passage on 10). The bar is MS §3.9: none loses 3/3, play wins at least 2 of 3, idle at most 45 s, median clear 180-240 s. In every case `none` (nothing cast) lost to dawn on all three seeds.

| Type | Tier 1 abilities | Wins | Median clear | Idle max | Verdict |
|---|---|---|---|---|---|
| Ruin | Smite, Ember | 3/3 | **207 s** | 21 s | pass |
| Death | Death Mark, Pestilence | 3/3 | **205 s** | 20 s | pass |
| Veil | Silent Doom, Blight | 3/3 | **201 s** | 20 s | pass |
| Dominion | Mind Whisper, Discord | 3/3 | **183 s** | 21 s | pass |
| Decree | Leaving Is Prohibited, The Bell Lies | **10/10** seeds | **184 s** (183.9-184.3), flame margin 19-34 s | 24 s | pass |
| Passage | Thornwall, Mirrorfold | **10/10** seeds | **112 s** (111.3-115.6), flame margin 87-123 s | 43 s | median under the band; **accepted** (C11) |

Times by seed for the three-seed types: Ruin 207.0 / 183.3 / 224.1; Death 205.3 / 219.4 / 204.0; Veil 201.2 / 201.1 / 201.1; Dominion 183.4 / 183.4 / 186.5. Dominion and Decree sit close to the bar's floor because three drags of up to 55 s plus bites and cooldowns are 184 s by themselves.

**Passage clears fast, and you accepted it (C11, 2026-10-29).** Its only way past the shrine's approach post (5 units from the stone, in the lane) is a deep Mirrorfold that lands beyond it; a Thornwall and one Yank cannot take a captive 5 units past a gripping watchman. So Passage wins by speed: a fold per drag, paced by the mirror's 54 s cooldown (shards at about 7, 61 and 115 s). The 180-240 s band guards pacing and a fast clear hides no loss, so Passage's rows are final and `gate.sh` still prints FAIL on its median. Even the spec's own line ("halves a drag, skips two posts") lands under 180 s. Levers, if you ever reopen it: a distance limit on the fold's exit, a stiffer approach post, or barring the fold of a chained captive. Its idle (43 s of 45) is the cooldown wait with no action available, which a human would meet too.

### Tuning

No rule constant was tuned (Yank, grip seconds, the Watch, march 2's count and the muster are all as the spec). Everything that missed was fixed in the scripted player first, as a player would: Decree went from 0/3 to winning when the circle went to the gate pair and CALL THE GUARD to the posts beyond it; Passage's policy delays its seal on the Main Gate until no captive is about to walk through it and picks the victim with the most room.

## Landing

Landing follows Ruling C1 and the plan's P3-24: fetch, trial-merge the then-current `feat/god-progression`, gate the merged tree, fast-forward `feat/god-progression`, tag `kak-god-p3` locally. Nothing is pushed without your yes and `feat/Develop-Main` is untouched.

| Gate | Result |
|---|---|
| Import | exit 0 |
| Suite | `checks=11488 failures=0` (P2 ended at 10928) |
| References, every row | <<REFS>> |
| `digest` | `61267b7e90524d800bf1c3473a71146b` (unchanged) |
| `crowd_check` | `-935602679` (unchanged) |
| FLOW alone | <<FLOW>> (the rite walk adds 25 checks; 200 at Task 8) |
| Bench vs `kak-god-p2` | <<BENCH>> |
| Landed commit | <<COMMIT>> |

**References: 286 to 307.** The 21 new rows are `first_taste_none_1..3` and `first_taste_<type>_play_1..3` for the six types, all added in a commented block at the end of `tools/dev/refs/references.tsv`. No pre-P3 row moved (digest, `crowd_check` and `calm` are unchanged at every task). Three of the rite's own rows were re-recorded after they were first recorded: the 17 `_play_` rows that moved when the muster spacing was fixed (the milestone fix wave), then Decree's three (the policy round of Task 7's review), then Passage's three (the Passage policy round); the `none` rows never moved (`-862607621`, `-634128792`, `-483087079`, the same for every type because nothing is cast). The only code that could reach an old reference is `Crowd.climb_scale` (1.0 by default, `x * 1.0` is exact), `Person.chained` (false) and the `chained` skip in `NoLeaveFx`; the references prove none of them moves anything.

**The gate command keeps its full form.** After the coming `god/t1routes` merge `gate.sh` has its own `--god=` (route "god"), which drops the `none` cases and never judges the median. So the rite's bar is always:

`bash tools/dev/gate.sh first_taste --extra='--god=<type>:1 --dev-tree' --jobs=6`

with `<type>` one of `ruin`, `death`, `veil`, `passage`, `decree`, `dominion`. Never pass `--god` to `gate.sh` itself. (`first_taste` is not in t1routes' `GOD_T1.SCENARIOS`, so a `behaviour_check` run of it does not enter t1routes' `god_route`; its own first line switches hit-stop off, as t1routes now does for every `--god` run.)

**Landing notes for the coming `god/t1routes` merge** (tip `6b179077` when reviewed; it lands on `feat/god-progression` too):
- Trial-merge and read the clashes the review found: none semantic. `test_mission_needs` stays 29 (t1routes adds no mission), `test_mission_hints` appends match (P3's four rows are at the end of `LINES` and `SPEC`), `tests/run_all.gd` lines are three apart, `mission_director.gd` appends are at different places, `references.tsv` blocks are apart.
- After the merge the "307 rows" bar becomes 307 plus t1routes' new rows (`god_t1_*`), and t1routes' own re-records of `harvest_*` and `lamb_*` stand (Ruling C3 covers P3's hunks only).
- **Run t1routes' `god_t1_*` Decree rows on the merged tree.** They cast Leaving Is Prohibited and are the only real-play proof that P3's `chained` skip in `NoLeaveFx` moves nothing (no pre-merge reference casts it).
- **Run FLOW alone on the merged tree** (`tasklist | grep -i godot` first). t1routes adds `_flow_title_endless` before `_flow_endless` and changes `_flow_endless`; `_flow_rite` starts from `_flow_lantern`'s slot, so it should be unaffected, but nothing has run them together.
- The stray `%` at `tests/test_endless_screens.gd:568` (P2's line, prints an engine "String formatting error") is fixed by t1routes (`+5%%`); P3 left it so the merge brings the fix.
- The six per-type gates and the 21 `first_taste_` rows run again on the merged tree (`bash tools/dev/refs_check.sh --only='^first_taste_' --jobs=6`).

## The reviews

- **Per task.** Tasks 1, 3, 4, 5 and 7 were reviewed; Task 2 (4 lines, read by the controller) and Task 6 (screens) were not, and Task 8 was covered by the milestone review. Each review found real defects, all fixed: Task 1's by the controller inline, Tasks 3, 4 and 5's re-reviewed and approved, Task 7's covered by the milestone review. The defects were: Task 1 (the rite def's slot and Might checks could not fail), Task 3 (loops over people that can be freed mid-loop, no freed-person test, the sacrifice raised an alarm against MS §2), Task 4 (the same freed-person defects, kneel spots 0.93 apart at the real shrine, the march's ETA counted the muster twice, the 110 s warning unasserted), Task 5 (edge arrows under the chain plate, the win plate over the banner bar, refusal banner spam), Task 7 (see Known issues).
- **Milestone review (opus)** of `568da1d5..ca61c534`: fix wave, 0 critical, 1 important, 8 minor. The important one: Task 7's fix that stops a stranded captive counting as a victim never fired in the real rite, because The First Taste's replacement rule only filled the rounds of dead or safe men. The wave fixed it on the real director with a test that fails without the fix, and took minors 1, 2, 3, 5 and 6 (the musterers over 1.6 apart after the grid snap, Prepare's IF LOST showing the real rise and the Hunt, Awaken dim with nothing to draft). Minors 4 and 8 were settled by ruling. A sonnet re-review approved the wave.
- **Passage policy round.** After the wave moved who leads the marches, Passage seed 3 became a loss (the policy's own Thornwall sealed the gate on its captive). Fixed in the scripted player; Passage now wins 10 of 10.

## Known small issues

Left on purpose; each has a short fix or waits for a later task.

**From the milestone review and the last rounds:**
- **The marchers' edge arrows clump at the top edge** (two overlap by a third, three stack). Legible as a group; cosmetic. Left for the art and animation round: spread arrows apart on one edge.
- **A replaced stranded man keeps his victim tag.** When a stranded captive is not counted and a new lamplighter replaces his round, the stranded man stays marked (so a later `chain()` of him still works) and keeps his gold tag. Cosmetic.
- **FLOW wins through `offer()`** (Ruling P3-22): the real click is only for the first chain; the grip and the Yank are not walked in FLOW. They are unit-tested (`_grip_breaks`, `_grip_resets`, `_yank_once`) and played by the 21 per-type references.
- **`Person.fold()` has no path test.** A Mirrorfold exit can land a captive in a pocket with no way to the shrine; the 8 s stuck rule frees him and the replacement rule sends a new man. A fold check belongs in Mirrorfold (P4 or later).
- **The quiet sacrifice leaves `Rules._stability_dirty` unset**, so the stability figure counts the dead lamplighter as standing until the next kill or fall (milestone minor 8, optional, not done). Nothing on a rite reads it.
- **A freed-by-stuck captive shows `THE CHAIN BREAKS`**, the same banner as a gripped one. A player whose own Thornwall sealed the lane gets no distinct reason. A copy decision.
- **The cleanse ring is not seen on the shrine** from the rite's camera spot (the shrine is off screen); the player sees it as an edge arrow with a ring, plus the banner and the hint.
- **The scripted players use some knowledge a player lacks:** Passage reads the walk grid for a pocket test and searches landings (a mild oracle); Decree calls the guard at a spot 6 units behind the watchman so he is among the soldiers the call takes (the 12 nearest). Both are plausible for a human who sees the walls and the effect.
- **Decree and Passage margins.** Decree's flame margin is 19-34 s and Passage's idle is 43 of 45 s; neither is luck-dependent over ten seeds, but neither has slack.

**From the tasks' deferred minors:**
- Task 3: `_release` zeroes a shorter Reassure (harmless at 1 s values); `drag_eta()` is not scaled by Death Mark or Pestilence slowdowns; `YANKS == 0 -> ONE_CHAIN` is untested because `YANKS` is a const.
- Task 4: the three kneelers of the `final-frame` check are hand-placed; the comment "every path stays under about 45 units" is only enforced as the 30-60 band (paths run 39-59).
- Task 5: the plate's two-line text and the rings are drawn but never asserted headless (the photographs are the check); a bare Esc cannot be tested outside the tree, so only the aim-up Esc is; `modes_rect()` keeps `_view().x`.
- Task 6: `test_endless_screens.gd:568` stray `%` (above); Prepare's RITE row shows the name only (six rows with the plate ran 2 px past the hint).
- Task 7: a real sealed-lane test (the repath and the stuck timer together) needs a wall in the test world; each is tested alone.
- Task 8: the pause menu's PAUSED header overlaps the mission-name line; the same overlap is in P2's `pause-hunt` photograph. The older FLOW walks print "Lambda capture ... freed" engine lines from `_until()`; none fails a check.
- The `first_taste` hint rows share the Hunt's fixed-width briefing; any longer text breaks `_prepare_rite` fits, which is the alarm.

## What is not yet there

- **Rites at levels 20, 30 and 40 (P4).** The button shows dim `Rite not yet written` there. Each rite will subclass `RiteDirector` and add a `RiteBook` row.
- **More gifts (P4).** Only the Watchful Bell exists. Gifts are generic on the def (`MissionDef.gifts`), so each new one is a row and its effect.
- **The five real Hunt nights (P5)**, still P2's stand-ins.
- A second, distinct banner for a stuck captive, the arrows' spread, and a camera spot that shows the shrine's ring (above).
- Gifts (beyond the first), the level tables, god names, and the title switch (see Needs you).

## Needs you

- **Passage's fast clear is final** (your C11). Say so if you want it reopened; the three levers are in the Passage paragraph.
- **The copy.** The spec's quoted strings are exact. Every other line (the refusals, `THE CAPTIVE IS LOST`, `THE CHAIN CANNOT REACH HIM`, `A NEW LAMPLIGHTER SETS OUT`, the results and confirm lines, `THE RITE IS DONE`, `THE SHRINE IS CLEANSED`) is my call.
- **The tunable numbers:** the Watchful Bell's x1.2, the Yank, the grip seconds, the muster. None was moved from the spec.
- **Pushing.** After landing, local `feat/god-progression` holds P3 and its tag `kak-god-p3` (and whatever `god/t1routes` brings). Nothing is pushed without your yes; `feat/Develop-Main` is untouched.
- Still open from P2: the title switch to Endless Night (M5, "say yes and it is next"), the five real Hunt nights, and whether a clean win should also need no seen death. Still open from P1: the level tables for the first powers, the god names and flavour lines, and whether to delete the Missions board.
