# Kingdoms Amid Kataclysm (KAK) — Version 0.08 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `feat/Develop-Main`, milestone tags `kak-v008-m1` … `kak-v008-m4`, release tag `kak-v0.08`. v0.08 is the **Awakening slice**: the first step of the "God Awakening" direction, in which the god reawakens through five Tiers, from Whisper to Ascendance, in a campaign that ends in a Last Judgement. This slice brings:
- **missions**, chosen on a new **mission board**: a mission framework of definitions, objectives and a director per mission;
- **Divine Power as a loadout budget**: up to six slots, a DP price per power, and no DP spent during a mission;
- a new Tier 1 power, **Mind Whisper**;
- a Tier 1 mission, **The Warning**;
- v0.07's mission, kept as **Last Judgement**, a Tier 5 Skirmish.

It builds on v0.07's soldiers, v0.06's powers and v0.05's civilization responses. Design: `docs/superpowers/specs/2026-10-03-kak-v008-awakening-slice-design.md`; plan and measurements: `docs/superpowers/plans/2026-10-03-kak-v008-awakening-slice.md`.*

## 1. Concept

You are an ancient god stirring over one walled medieval town, **Aldermere**. You now pick a **mission** from a board, draft a loadout within its Divine Power, and play it out.

**Design goals:**
- v0.08: **a god who grows.** The first mission asks for subtlety, not destruction: a single watchman must not reach the bell. The last asks for the whole kingdom. In between (later versions) the god earns its Authorities.
- **Divine Power is a choice made before the mission**, not a bar to manage during it. Cooldowns, the one-power-at-a-time cast lock, the clock and the town's response are the limits in play.
- **Each Authority should be able to solve a mission its own way**: kill quietly (Veil), steer minds (Dominion), confuse (Disorder), block the way (Passage).

## 2. Game flow

**Title → Mission board → Prepare (draft) → Mission → Results**, with **Pause** over the mission.

| Screen | What it does |
|---|---|
| Title | Game name over a slowly panning town; Play, VFX Sandbox, Quit |
| **Mission board** (new) | One card per mission: its name, a Tier badge (the digits drawn as bitmaps, since the font's 5 reads as S), the two-line brief, the goal, "N slots · M DP" and the best result. Hovering a card selects it; click or Enter chooses it; a key-hint line along the bottom |
| Prepare | The mission's pool only, in **tabs by Authority**. Cards show the DP price and the cooldown. The loadout bar has the mission's number of slots and a **budget meter** ("4 / 6 DP"). Cards that would go over the budget, or that have no free slot, are dimmed and refuse with a short reason ("Not enough Divine Power"). The difficulty selector shows only for Last Judgement; The Warning's town strip reads UNAWARE |
| Mission | Intro (camera sweep and banner), then the clock. Six compact slots on the bar (icon, key, name cut to fit, cooldown); **no DP bar**. The Warning adds an objective panel top left |
| Pause (Esc) | Resume, Restart, Change powers, **Missions** |
| Results | Last Judgement: victory/defeat, the stat lines with points, score, rank S–D, NEW BEST!. The Warning: its goal and bonus ticked or crossed, the time, and "Solved by". Replay, Change powers, **Missions** |

The Title is reached from the board, with Esc.

**Saves:** one section per mission (`[mission.<id>]`: the best score and rank, or won and the bonus; and the last loadout). A pre-v0.08 save's best and loadout are read as Last Judgement's. The difficulty stays global.

## 3. Controls

| Action | Input |
|---|---|
| Pan | WASD / arrows, or middle-mouse drag |
| Zoom | Mouse wheel (0.5–1.6) |
| Choose a mission (board) | Left/Right or hover, then Enter or click; Esc back to the Title |
| Pick power | **Keys 1–6** or click the slot |
| Cast | Click (point powers), press-drag-release (line powers), or **press on a person, release on a spot** (Mind Whisper) |
| Cancel / unfocus / pause | Esc |
| Restart | R |
| Difficulty (Prepare, Last Judgement) | Left/Right, or the arrows |
| Draft tab (Prepare) | Click a tab, or Tab / Shift-Tab; click a loadout slot to give its pick back |
| FPS meter / behaviour overlay | F3 / F4 |

## 4. The missions

| | The Warning | Last Judgement |
|---|---|---|
| Tier | 1 | 5 (a Skirmish) |
| Brief | A star falls over the Main Gate. A watchman runs to wake the bell. | Aldermere and its Royal Citadel. Bring the whole kingdom down. |
| Win | The warning dies: its messenger killed unseen, or the omen fades (2:00) with the bell silent | The Citadel down and City Stability broken |
| Lose | The bell tolls | 50 citizens escape, or the 6:00 clock runs out |
| Slots, DP | 3 slots, 6 DP | 6 slots, 14 DP |
| Pool | Mind Whisper, Silent Doom, Will-o'-Wisp, Discord, Thornwall | All 18 powers |
| Default loadout | Mind Whisper, Silent Doom, Discord (4 DP) | Heaven Splitter, Tsunami Breaker, Cinderfall Barrage, Nuclear Nova (14 DP) |
| Town | **Unaware** (fixed) | Chosen on Prepare (Organized by default) |
| Bonus | **Unseen:** the town never reaches Local Emergency | — (scored and ranked) |

**How a mission is decided** (the framework): each mission lists **objectives** that report pending, done or failed. They are judged in list order; the first primary objective to report done wins, and the first to report failed loses. This keeps Last Judgement's old order exactly (the Citadel first, so a city that falls on the last tick counts) and expresses The Warning's either-or win. Bonus objectives only report in the results. A **director** per mission runs its scripted actors and is stepped with the mission, so it freezes and pauses with it; Last Judgement has none.

## 5. Divine Power as a loadout budget

- **Before the mission:** each power has a **DP price**. Fill up to the mission's slots without going over its DP. Empty slots are allowed; MANIFEST needs at least one pick.
- **During the mission no DP is spent.** Removed: the DP bar, its regeneration, the Temple's 70% refund, the DP recovered from buildings, soldiers, the Citadel and chains, and the score's DP term.
- **Divine Surge:** destroying the Temple (the cathedral) resets every cooldown, once, with the banner "DIVINE SURGE".
- **Authorities replace kinds:** Ruin, Veil, Dominion, Passage, Disorder, Life/Death. Prepare's tabs follow them; "quiet" stays a separate flag.

**Prices and cooldowns.** The rule of thumb: new cooldown = the larger of the old cooldown and 3 × the old DP cost.

| Power | Authority | v0.07 DP | v0.07 cooldown | **Loadout DP** | **Cooldown** |
|---|---|---|---|---|---|
| Mind Whisper (new) | Dominion | — | — | 1 | 8 s |
| Silent Doom | Veil | 8 | 2.5 s | 1 | 10 s |
| Will-o'-Wisp | Dominion | 10 | 25 s | 2 | 30 s |
| Discord | Disorder | 10 | 20 s | 2 | 30 s |
| Heaven Splitter | Ruin | 10 | 20 s | 2 | 30 s |
| Blight | Veil | 12 | 25 s | 2 | 36 s |
| Thornwall | Passage | 14 | 30 s | 2 | 42 s |
| Tornado Tempest | Ruin | 15 | 30 s | 3 | 45 s |
| Pestilence | Life/Death | 16 | 40 s | 3 | 48 s |
| Dragonfire Parade | Ruin | 18 | 35 s | 3 | 54 s |
| Gravity Distortion | Ruin | 20 | 45 s | 3 | 60 s |
| Walking Laser Grid | Ruin | 22 | 45 s | 3 | 66 s |
| Orbital Strike | Ruin | 22 | 45 s | 3 | 66 s |
| Tsunami Breaker | Ruin | 20 | 40 s | 4 | 60 s |
| Cinderfall Barrage | Ruin | 25 | 50 s | 4 | 75 s |
| Judgement of the Ancients | Ruin | 30 | 60 s | 4 | 90 s |
| Glacial Cataclysm | Ruin | 30 | 60 s | 4 | 90 s |
| Nuclear Nova | Ruin | 40 | 120 s | 4 | 120 s |

**Last Judgement under the new model** (`judgement` scenario: five runs each, Organized, the default loadout, a greedy bot that casts whatever is ready):

| Median | v0.07.1 rules (Task 7) | v0.08 rules (Task 13) |
|---|---|---|
| Citadel falls | 47.2 s | 47.0 s |
| Run ends | 87.0 s | 85.6 s |
| Ending | escapes (50) | escapes (50) |
| Buildings destroyed | 79 | 77 |
| Score, rank | 6965, C | 6850, C |

- **No run wins under either rule set.** The Citadel falls at about 47 s, but stability stays near 47–49% and every run is lost to escapes at 84–89 s. So "about as before" was judged on the Citadel's half-minute and the ending, both unchanged. **No cooldown was tuned** beyond the rule of thumb.
- **Ranks −200:** each threshold was lowered by the median DP term the old runs still held at their end (17 DP × 10 = 170, rounded to 200): **S ≥ 19,000, A ≥ 14,200, B ≥ 9,400, C ≥ 4,600** (were 19,200 / 14,400 / 9,600 / 4,800). This comes from losing runs, which never had the win's DP term; a winning v0.07 run's term may differ. Worth a look in a playtest.
- **Silent Doom** goes from 2.5 s to **10 s**: 2.5 s was safe only while each cast cost 8 DP.

## 6. Mind Whisper (new, Dominion, Tier 1)

**1 DP, 8 s cooldown, quiet** (no threat, no alarm). Aimed by dragging.

- **Aim:** the press snaps to the nearest living citizen out in the open within 0.6; the release snaps to walkable ground at most **10** (`REACH`) from them, and never past it.
- **Preview:** a ring on the person and a dotted line to the spot, red past the reach.
- **Refusals** (the slot is not spent and no cooldown starts): nobody to whisper to; a soldier, someone inside, or the dead (they are immune); a target that dies during the drag. The slot's own reason (cooling, locked) comes first.
- **Effect:** the person drops whatever they were doing (their day, a duty, an errand, even flight), **walks** to the spot in a new `WHISPERED` mind, and **lingers 8 s** under a faint gold glyph. Then they resume: flight becomes flight again, an errand the errand, a duty is taken back by its manager (the bell, the rite, the engineers), anything else returns to their day.
- **Look:** a soft gold ring at the destination while they are on their way and lingering (strengthened after the first clip did not read: alpha 0.9, a fill, a halo and a pulse); a painted icon and a draft preview clip.

## 7. The Warning (new, Tier 1)

**The premise.** The god's first stirring: at **0:02** a falling star lands at the Main Gate ("A STAR FALLS OVER THE MAIN GATE", "STOP THE WARNING"). The **watchman** — a citizen with a new role, in a dark cloak with a lit lantern — stares at it for 4 s, then runs (a duty, at panic speed) to the bellkeeper, wherever the keeper is now, re-aimed every 0.5 s. Within 0.8 of the keeper he tells them; the keeper runs to the Bell Tower and climbs (8 s). **If the bell rings, the mission is lost** ("THE BELL TOLLS"). Unhindered, the bell rings at about **0:25** (the watchman delivers at about 0:16).

**The town is Unaware:** Organized's bell and fire brigade, but **no escorts**, so nobody guards the bell or takes the rope.

**The messenger:**
- whoever carries the warning has a marker over them, and an arrow at the screen's edge when they are off screen;
- a fright, Discord or Mind Whisper interrupts the errand, and he picks it up again when he recovers;
- he ignores the Wisp while on his errand; he paths round a Thornwall;
- if the keeper is dead, the messenger climbs the tower himself, 1.5× slower;
- once the keeper is told, the keeper is the messenger.

**Win:** kill the messenger with **no living person within 2** of the body (Silent Doom's witness rule), or hold the warning off until the **omen fades at 2:00** ("THE WARNING DIES"). A **witnessed** death passes the warning to the nearest witness, who runs on with it ("THE WARNING PASSES ON"). The bell holds for the relay rather than falling silent when its keeper dies.

**Results:** won or lost, the **Unseen** bonus, the time, and **"Solved by"**: the Authority of the killing power, or for an omen-fade win the Authorities of every power cast within 3 of the messenger or the keeper while the warning lived. It is shown, not saved: it previews Resonance (v0.09).

### 7.1 Measured: one case per Authority

The `warning` scenario (seed 7): each case drafts its power and plays a simple policy against the messenger every 0.1 s. Every cast goes through the real `Rules.cast()` when its refusal allows it. The quiet powers have no hit-stop, so the runs are exact: three runs of each case gave identical lines, and the final-gate run below gave them again.

| Case | Policy | Result | Time | Solved by |
|---|---|---|---|---|
| none | cast nothing | **lost**, the bell | 0:24.8 | — |
| doom | Silent Doom when nobody would see where he falls | **won**, unseen kill | 0:13.6 | Veil |
| whisper | whisper him 8 back toward the gate whenever ready | **won**, the omen fades (5 whispers) | 2:00 | Dominion |
| discord | Discord whenever ready, once he runs | **lost**, the bell | 0:59.4 | Disorder |
| thornwall | a wall 3 ahead, across his street | **lost**, the bell | 0:25.4 | Passage |
| mix | whisper, Discord when he resumes, Doom when he is alone | **won**, unseen kill | 0:13.8 | Veil |

- **none:** the bell at 24.8 (seeds 1–4: 26.9 / 24.3 / 24.3 / 23.8), inside the spec's 0:20–0:35 window, so the omen's time, the stare and the watchman's post were not changed.
- **doom:** the watchman is never alone at his post (two gate soldiers stand 0.4–1.9 from him through the stare). On his run he is alone at 6.9 for 0.1 s, and again from 13.1 to 14.3. Cast in the first window, he runs on 0.7 before he falls, into a soldier's sight: the soldier relays it, and the bell rings at 23.1, *faster* than doing nothing. Judged where he will fall, Doom wins. On seeds 1–4 one cast won by 0:08 in three of four.
- **whisper:** each whisper holds him about 24 s (an 8-unit walk, the 8-s linger, a recovery) against an 8-s cooldown, so he never runs again.
- **discord:** about 35 s of delay (15 s confused on the watchman, a second Discord on the keeper); it cannot win alone, a 30-s cooldown against a 15-s hold.
- **thornwall:** +0.5 s. He paths round the 3-unit wall, and the 42-s cooldown allows one cast before the bell.
- **Unseen** was earned in every win.

## 8. Balance findings — decisions for you

No gameplay number was changed in the balance pass. These need your call:

**1. Mind Whisper alone wins The Warning every run.** Measured with temporary edits (reverted), the `whisper` case on seeds 7 and 1:

| Change | Result |
|---|---|
| Cooldown 15 s | still wins both (the ~24-s hold outlasts it) |
| `REACH` 6 | still wins both (a 10-s walk plus the linger outlasts 8 s) |
| Cooldown 30 s | still wins both (he runs back 8 units in 5 s of his ~6 s free) |
| Cooldown starting only when the whisper wears off | still wins both |
| **Someone just released ignores another whisper for 20 s** (from when it wore off) | **loses: the bell at 1:27 / 1:23** (one whisper on the watchman, one on the keeper: about 60 s of delay) |

Options:
1. **Shake-off (recommended):** someone a whisper has just released cannot be whispered again for 20 s ("they shake it off"; the cooldown is not spent). Whisper alone then delays about 60 s and loses; it still wins with Doom or Discord.
2. **A long cooldown:** 45 s or more (only past ~33 s does the messenger gain ground between whispers). Estimated, not run: a loss at about 0:50–1:20; but Mind Whisper stops being a quick 1-DP tool in Last Judgement too.
3. **The messenger does not linger:** he walks to the spot and runs on at once. Alone this still locks him (a 13-s walk outlasts 8 s); it needs option 1 or 2 with it.

**2. Thornwall barely delays the messenger:** at most +1.5 s, once a mission (walls 1, 2, 5 and 8 units ahead: +0.5 / +0.5 / +1.5 / 0 s; a wall in front of the keeper: 0 s). Placed 5 or more ahead, the cast is out of "Solved by"'s reach (3). Options:
- (a) leave it out of The Warning's pool (it is a Last Judgement tool: gates and evacuees);
- (b) a longer wall in this mission, long enough to close a street on the route (not measured);
- (c) a messenger whose path is blocked stops and pushes through the brambles for a fixed few seconds, making it a small, real delay tool.

**3. Silent Doom** wins by 0:14 in four of five seeds for a bot that reads the witness rule exactly. A player has 0.1–1.2-s windows to find, and the gate soldiers make the watchman's post a trap. It reads as the intended skill solution; no change proposed.

## 9. Tools and tests

- **Behaviour scenarios** (`tools/dev/behaviour_check.gd`):
  - **judgement** (M2): a greedy Last Judgement bot, for the DP-to-loadout comparison;
  - **warning** (M5): `--case=` none / doom / whisper / discord / thornwall / mix;
  - **clip** records Mind Whisper's draft preview in the real town.
- **Scripted runs:** `--mission=<id>` with `--mission-test`, `--bench` and the screen photographs (`--show=board|prepare|results|results-warning|pause`); FLOW now also walks the board, and plays The Warning to an omen-fade win and back through Missions.
- **Art:** `tools/dev/make_power_icons.py` paints Mind Whisper's icon (needs numpy and Pillow).
- **Tests:** **1263** automated checks (1065 in v0.07): objectives and their order, the mission book and board, loadout prices, budget and slots, casting without DP and the Surge, Mind Whisper's aim, walk, linger, resume and immunities, and The Warning's route, call, keeper-dead climb, relay, wins, loss and bonus.

## 10. The gates

Measured on the BURIN_NITRO laptop at each milestone. "Exact" checksums are the deterministic behaviour scenarios that cast no hit-stop power.

| Gate | v0.07.1 baseline | M1 | M2 | M3 | M4 | Final (v0.08) |
|---|---|---|---|---|---|---|
| Tests | 1065 / 0 failures | 1120 | 1140 | 1181 | 1263 | **1263 / 0** |
| State digest | `61267b7e…146b` | = | = | = | = | **=** |
| crowd_check | −346732806 | = | = | = | = | **=** |
| FLOW | 24 checks | 30 | 30 | 30 | 34 | **34 / 0** |
| Exact checksums (5) | see below | = | = | = | = | **=** |

The five exact checksums, unchanged throughout: `calm --seconds=60` −695580348, `gates` 619520995, `fire` −16560442, `rite --interrupt` −129298221, `soldiers --case=escort` −935015846.

**The mission test** (Last Judgement, Organized, the default loadout; not exact, because hit-stop runs on the wall clock): Task 0 gave buildings 52–57, citizens 175–181, escaped 0, stability 66–69%, the Citadel at 50% when it ends at 34 s. Every milestone since gave buildings 51–56, citizens 179–192, escaped 0–1, stability 67–70%, the Citadel at 50%. The ~8 extra citizens appeared in M1, a pure refactor, and also in the unchanged a875fd1 run the same day: machine timing, not the code. Final: buildings 51, citizens 188, escaped 1, stability 70%, the Citadel at 50%.

**The Warning, unhindered** (`--mission=warning --mission-test`): lost to the bell at **24.2 s**, no relay (M4: 24.1 s).

**The `warning` cases** (one run each, final): identical to Task 23's end lines (§7.1).

## 11. Performance

**Market view, mission bench** (`--bench`, Organized), alternating builds, 2026-10-03. The machine was not quiet: Chrome, Edge and another Godot instance (a town debug scene from the pixellab worktree) were running, and the same build swung from 98 to 120 fps. So three more alternating pairs were run in the reverse order:

| Build | fps (runs 1–3) | fps (runs 4–6) | Mean of six | Worst frame | Draw calls |
|---|---|---|---|---|---|
| `kak-v0.07.1` | 109.6 / 120.4 / 101.8 | 107.5 / 102.2 / 98.6 | **106.7** | 19.8–26.8 ms | 1052 |
| v0.08 | 109.2 / 102.0 / 101.8 | 98.2 / 112.2 / 113.0 | **106.1** | 18.4–25.9 ms | 1050 |

- **−0.6 fps over six pairs: within the 5-fps budget.** The first three alone read −6.3; the second three +5.0. That is machine noise, not the build, so nothing was profiled or changed. v0.08 draws 2 fewer calls.
- **The Warning** (`--mission=warning --bench`, the Unaware town): **130.0 fps**, worst frame 16.0 ms, 867 draw calls.
- For reference, the bench earlier the same day (Task 0, `kak-v0.07.1` code): 122.7 / 123.9 / 125.1 fps.

## 12. Known issues

- **A MANIFEST pressed during a fade-in is ignored** (small; left for later).
- **Pushes are pending a GitHub sign-in on this laptop:** the branch and tags are committed locally.

## 13. To confirm with you

1. **How a mission is decided:** in list order, the first primary objective done wins and the first failed loses (spec: "all primaries done wins").
2. **The messenger after delivery:** the told keeper is the messenger; killing them unseen still wins; a witnessed death passes the rope on.
3. **"Delayed a messenger"** for Solved by: a cast within 3 of the messenger or the keeper while the warning lives.
4. **Pause and Results** offer Missions in place of Title; the Title is reached from the board.

## 14. Not yet in (v0.09 and later)

- **Resonance:** Authorities earned through how missions are solved ("Solved by" previews it).
- **Awakening Trials:** the steps between Tiers.
- **The campaign save:** progress through the Tiers, beyond each mission's best.
- **Civilization memory:** a town that adapts to how it was struck before.
- More Tier 1–4 missions, and the balance decisions in §8.
