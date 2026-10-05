# Kingdoms Amid Kataclysm (KAK) — Version 0.09 Summary

*Engine: Godot 4.7.2 (gl_compatibility, 640×360 pixel art, iso view). Branch `feat/Develop-Main`, milestone tags `kak-v009-m1` … `kak-v009-m4`, release tag `kak-v0.09`. v0.09 is **The Long Night**: a mission played in **acts**, on one town, over one night. A choice between the acts picks the path, timed events give each act windows to seize or miss, and how an act ends shapes the town the next one meets. This version brings:
- **missions in acts:** an act has its own clock, objectives, bonuses, director and town; a new `Rules` is built per act on the same town and crowd;
- **the interlude** between acts: the act's result, a choice card, a re-draft of the loadout and BEGIN;
- **the town between acts:** its readiness only rises (`Crowd.raise_profile`), and the dead and the ruins stay;
- **timed events** (`EventTimeline`) with banners and a strip under the clock;
- a Tier 3 mission, **The Long Night**: Act I The Omen (The Warning), then **The Festival** or **The Procession**, then **Judgement**;
- two new people: the **Mayor** and the **Prince**;
- **the night's results and save:** a rank for the night, and which paths have been won.

It builds on v0.08's mission framework, v0.07's soldiers, v0.06's powers and v0.05's civilization responses. The Warning and Last Judgement are unchanged: every exact gate stayed identical through the whole version. Design: `docs/superpowers/specs/2026-10-04-kak-long-night-acts-design.md`; plan and measurements: `docs/superpowers/plans/2026-10-04-kak-long-night-acts.md` (its Execution notes).*

## 1. Concept

You are the god, awake now through a whole night over Aldermere. A star falls at dusk: first a whisper at the gate (Act I), then a blow at the town's heart (Act II), and by the end of the night the Citadel falls (Act III).

**Design goals:**
- **A mission with a shape.** One goal on one clock becomes three short acts with a choice in the middle.
- **Fail forward.** Only the last act can lose the night. A lost act makes the town harder, never the night over.
- **Windows, not just goals.** Each act has two or three timed events (the bonfire, the Mayor's address, the blessing, the last ferry), so there is a *when* as well as a *what*.
- **Your own choices shape the town you face:** the path you take, and how each act ended.

## 2. The night

```
Act I  The Omen (2:00)
   └─ choice card ─┬─ Act II-A  The Festival   (2:30)
                   └─ Act II-B  The Procession (2:30)
                                   └─ Act III  Judgement (5:00)
```

**Board card:** *The Long Night*, Tier 3, "Three acts, one night. Your choices shape the town you face." 4 slots and **14 DP** for the night (see §9). Every power is in the pool. The default loadout is Mind Whisper, Silent Doom and Discord.

| | Act I: The Omen | Act II-A: The Festival | Act II-B: The Procession | Act III: Judgement |
|---|---|---|---|---|
| Clock | 2:00 | 2:30 | 2:30 | **5:00** |
| Premise | The Warning, as in v0.08, on an Unaware town | The market fills for the Feast of Lanterns | The Prince leaves the Citadel on foot for the ship | Last Judgement in the town the night has made |
| Win | The warning dies: its messenger killed unseen, or the omen fades | **The festival is broken:** 50 of the 80 goers dead or fled | **The Prince is dead** before he boards | The Citadel down and City Stability broken |
| Lose | The bell tolls | The square closes (150 s) with the festival standing | He boards (about 136 s unhindered), or the last tide comes | Escapes reach the limit (**90**, or **72** after the Prince escaped), or the clock runs out |
| Bonus | **Unseen:** the town never reaches Local Emergency | **Before the bell:** the bell does not ring during the act | **A quiet succession:** he dies with no witness (Silent Doom's rule) | **Dawn never comes:** win with 30 s left |
| Timed events | — | 0:45 the bonfire lights, 1:30 the Mayor's address (30 s), 2:30 the guard closes the square | 1:00 the blessing (20 s at the cathedral steps), 2:00 the ship docks, 2:30 the last tide | 1:30 the clergy gather, 2:00 the boats sail, 2:30 the last ferry leaves (each only if the town has that response) |

**An act ends as soon as an objective decides it** (the existing 3 s slow-motion ending is the beat), so a sharp player shortens the night. A night played well runs about 6–7 minutes.

**Act I** is `WarningDirector` and The Warning's objectives, run as an act on an Unaware town. It carries forward: the bell rang or not, the alarm stage, the dead.

**Act II-A, the Festival.** 80 citizens come to the market square and stay (the responders, the Mayor and the Prince do not). Two bonfires light it (light only, no damage). At **0:45** the crowd packs in round the fountain. At **1:30** the Mayor, a named citizen with a dark red robe and a gold chain, stands by the fountain and speaks for 30 s. **Killing him spreads the panic:** every festival-goer flees, or runs for cover (a goer sent to shelter counts as broken). If the bell rang in Act I, 6 soldiers watch the square.

**Act II-B, the Procession.** The Prince (a resident made a `NOBLE`: a purple cape and a gold crown), 4 escort soldiers and 6 attendants walk a route from the Citadel to the dock, at a walking pace. He never runs. At **1:00** the procession holds 20 s at the cathedral steps and up to 10 onlookers gather. At **2:00** the ship docks and he boards when he reaches it. A fright stops the walk and the escort **closes in** to within 0.8; he takes the route up again when he recovers. His death is judged as The Warning's messenger's is: seen or unseen. **An escape is not a death:** if he boards, he is not dead, and a seen doom kill can't earn the bonus.

**Act III, Judgement** is Last Judgement compressed, with Act II's carry-overs (§4) and its own events. Only escapes during Act III count.

## 3. The interlude

When an act ends, the mission freezes and an **interlude screen** comes up over the town:
1. **The act's result:** its goal and each bonus ticked or crossed, and the time it took.
2. **After Act I, the choice card:** one card per path, with its brief, its timed events and a line on how the town will meet you given what just happened ("The bell rang: soldiers watch the square.", "The Prince travels light."). After Act II, a single line naming the last act ("The Prince escaped: the kingdom rallies and is ready.").
3. **Choose powers** goes on to the **re-draft**: Prepare with the night's pool, slots and DP, preselected with your last loadout. Every cooldown is ready in the new act.
4. **BEGIN** continues the same town into the next act, with a short camera sweep and the act's banner. Esc on the interlude leaves the night for the board.

The act's own HUD is rebuilt per act. Pause, Restart and Change powers work during the night: a restart is a fresh night from Act I, and no old `Rules` or director stays connected.

## 4. The town between acts (spec §2, as measured)

The town's readiness rises with the night and **never falls**. The dead stay dead and the ruins stay ruined; escapes only count toward the act they happen in. Measured with `--scenario=night` and forced outcomes (`--act1=`, `--act2=`, `--prince=`, `--festival=`); each run lists the town at the start of Acts I, II and III:

| After | Outcome | Next act's town, as run |
|---|---|---|
| Act I | warning stopped | Unaware: Unaware, Unaware, Organized |
| Act I | bell rang | Organized: Unaware, Organized, Organized; soldiers watch the square |
| Act II-A | festival broken | Act III Organized; the gates jammed for 40 s by those still fleeing |
| Act II-A | festival held | Act III Organized; marshals at the gates from the start |
| Act II-B | Prince killed unseen | Act III Organized; no rally at the Citadel |
| Act II-B | Prince killed seen | Act III Prepared (rite, boats, engineers) |
| Act II-B | Prince escaped | Act III Prepared; the Citadel's guard rallied; **escape limit 72** (was 40 in the spec's numbers) |
| Act II-B | Prince escaped, Act III left to run | Lost on escapes (the limit), a D |

**Raising the town mid-night** (`Crowd.raise_profile`) turns on what the new profile has: the Banishing Rite, the boats, more marshals, rallied soldiers. Each is announced ("THE TOWN PREPARES: ..."). A response whose building is already ruined is skipped.

**Every power still running when an act ends is ended with it** (a Heaven Splitter from Act I must not fall on the Prince during Act II's intro); fires and ruins stay as town state. The time scale returns to 1.0 and the new act's cooldowns are all ready.

## 5. Timed events

An act's events live in an `EventTimeline`: each fires once when the act's clock reaches it, with a banner, and the HUD shows the next two in a small strip under the clock ("0:23  The bonfire lights"). An event can carry a **guard**: if the guard is false when its time comes (the Mayor is dead; the rite or boats are already running; the town has no cathedral) the event is dropped quietly, with no banner, and it leaves the strip. An actor dead or missing before its event is skipped with no error, and the act still ends by its objectives.

## 6. The night's results, rank and save

- **Results:** each act's row (its name, ticked or crossed, its bonuses), the path taken, the night's total and the **rank**.
- **Score:** Act III's score + 2000 per act won + 500 per bonus earned. **Ranks:** S ≥ 30,000, A ≥ 24,000, B ≥ 15,000, C ≥ 7,000, else D (tuned in Task 19: a night that wins all three acts scores about 26,700–28,000, an A).
- **The night is won or lost on Act III** (the last act decides won and the reason).
- **The save:** the best night score and rank, and which paths have been won; the board card shows "Festival ✔ Procession ✘". A save with no night section, or a night never played, shows "Not yet played"; the first Prepare preselects the night's default loadout.
- **Act banners:** the act-ending banner names the outcome: THE FEAST IS BROKEN, THE SQUARE IS CLOSED, THE PRINCE IS DEAD, THE PRINCE HAS SAILED, THE TIDE HAS TURNED.

## 7. The new people

- **The Mayor** (`Role.MAYOR`): the merchant living nearest the market square is the Mayor tonight. A dark red robe and a gold chain of office, on both art paths (the drawn people and the PixelLab sprites). He stands by the fountain for the address; if he is dead or there is no merchant, his events are skipped.
- **The Prince** (`Role.NOBLE`): the resident nearest the Citadel. A purple cape and a gold crown (a 5×1 band under 3 points on the sprite). Escorts are soldiers of the Citadel's own posts.
- Both enum values are appended last (`int(p.mind)` and the roles are hashed by the checksums).

## 8. The gates

Measured on the BURIN_NITRO laptop at each milestone. "Exact" checksums are the deterministic behaviour scenarios.

| Gate | v0.08.2 baseline | M1 | M2 | M3 | M4 | Final (v0.09) |
|---|---|---|---|---|---|---|
| Tests | 1755 / 0 failures | 1833 | 1924 | 1996 | 2060 | **2087 / 0** |
| State digest | `61267b7e…146b` | = | = | = | = | **=** |
| crowd_check | −346732806 | = | = | = | = | **=** |
| FLOW | 35 checks | 54 | 54 | 54 | 54 | **62 / 0** (see §14) |
| Exact checksums (10) | see below | = | = | = | = | **=** |

The ten exact checksums, unchanged throughout: `calm --seconds=60` −695580348, `gates` 619520995, `fire` −16560442, `rite --interrupt` −129298221, `soldiers --case=escort` −935015846, and The Warning's `none` −446012507, `doom` −999129915, `whisper` 442055066, `discord` −909358062, `mix` −430643507.

**By milestone** (each tagged `kak-v009-mN`):
- **M1 (acts):** the board card, the interlude, a new `Rules` per act, the night's results and save. `--scenario=night`, 8 forced runs, no SCRIPT ERROR: the festival path won/won A (16620), lost Act III C (5120), lost Act I won Act III B (14120), lost/lost D (2645); the Procession path A (16560), C, B, D.
- **M2 (the town between acts, events):** `raise_profile`, the §2 rows, `EventTimeline` and the HUD strip, Act III's events.
- **M3 (the Festival):** the crowd, the bonfires, the Mayor, the closing. Left to run it is lost to the clock (reason `closed`, 150.0 s), three runs identical; live run with real effects captured and checked.
- **M4 (the Procession):** the Prince and escort, the route, the blessing, the ship, the quiet succession. Left to run: lost, `sailed` at 136.4 s, the Prince `escaped`.
- **M5 (wrap-up):** the `night` scenario plays an act with a policy (`--act1|2|3=play`), balance (§9), the final whole-branch review and its fix wave, the bench.

**The mission test** (Last Judgement, Organized; not exact, because hit-stop runs on the wall clock): M1 gave buildings 57/55/53, citizens 180/189/190, escaped 0/1/1; Task 19 gave buildings 55/51/52, citizens 191/186/194, escaped 1, stability 70/70/71%, the Citadel at 50%. **Final** (a quiet machine, three runs): buildings 57/55/55, citizens 186/188/191, escaped 1/1/1, stability 69/69/70%, the Citadel at 50%. Three earlier runs while other sessions loaded the machine gave citizens 182–183 and stability 67–68%: hit-stop's wall clock again.

**The Warning, unhindered** (`--mission=warning --mission-test`): lost to the bell at **24.1 s** from M1 to Task 19 and in the final run (three of three on a quiet machine; 25.5–26.2 s in three runs taken while other sessions loaded it, because that test runs at the real frame rate). The five `warning` cases are exact and identical (above).

**Played nights, final tree** (`--scenario=night --path=… --act1=play --act2=play --act3=play`): 
- **Festival path:** Act I won at 13.8 s, the Festival won at 95.6 s, Act III won (the Citadel): **won, A, 26,820**. No SCRIPT ERROR.
- **Procession path:** Act I won at 13.8 s, the Prince killed unseen at 134.8 s, Act III won: **won, A, 27,690**. No SCRIPT ERROR.

## 9. Balance (Task 19) — beyond the spec's starting numbers

The spec gave starting numbers to be tuned in the last milestone. Measured with the `night` scenario's act policies (a scripted caster per act), the following changed. **These go beyond the spec's starting numbers**, within the list the plan allowed; please look at them:

| Number | Spec's start | Chosen | Why |
|---|---|---|---|
| Act III clock | 3:00 | **5:00** | Breaking stability to 0% took a measured policy 243–272 s |
| Night DP | 10 | **14** (4 slots kept) | Act III needs the heavy powers. Acts I and II are bound by their 4 slots: four quiet powers cost at most 9 DP |
| Act III escape limit | 50 | **90** (`NightState.ESCAPE_LIMIT`; Last Judgement keeps 50) | Won Act III runs ended with 56–75 escapes (86 after a held festival) |
| After the Prince escaped | 40 | **72** (`PRINCE_ESCAPED_LIMIT`) | Keeps the spec's 4:5 ratio |
| `ESCORT_R` (a calm escort's distance) | 1.6 | **2.5** | A calm escort now stands past Silent Doom's witness range (2.0), so the quiet succession turns on the attendants, who can be whispered away. At 1.6, Doom won in 0 of 6 runs |
| Night ranks | S 20000 / A 15000 / B 10000 / C 5000 | **S 30000 / A 24000 / B 15000 / C 7000** | Policy nights that win all three acts score 26,700–28,000 |

Unchanged: `ESCORT_CLOSE`, `FESTIVAL_CROWD` 80, `FESTIVAL_NEED` 50, `JAM_SECONDS`, every event time, the Act I and II clocks, and the points for acts and bonuses.

**Measured, played** (a policy for each act):
- **Festival path**, 3 runs: Act I won at 13.8 s, the Festival won at 95.6 s, Act III won at 242.8 / 242.8 / 243.0 s with 70 escaped. Night 26965 / 27045 / 27045, an A. About 5.9 minutes.
- **Procession path**, 3 runs: the Prince killed unseen at 134.8 s, Act III won at 272.3 / 267.9 / 252.6 s. Night 26730 / 27990 / 27490, an A; Dawn earned in 2 of 3. About 6.7–7.0 minutes (worst 9.5).
- **Fail forward:**

| Case | Act II | Act III | Night |
|---|---|---|---|
| Festival held | lost at 150 s | won at 224.9 s, 86 escaped | 25425, an A |
| Prince escaped, played | lost `sailed` | lost on escapes at 120.6 s (75 of 72) | 13795, a C |
| Prince escaped, forced | — | lost on time: the rite took 40 s | 16290, a B |
| Prince seen, forced | — | lost on time: the rite took 40 s | 16175, a B |

- **Doing nothing:** Act I is lost to the bell at 24.8 s; the Procession is lost `sailed` at 142.8 s; Act III is lost on time or on escapes. The Festival is the exception (decision (a) below).

## 10. Decisions for you

The balance pass found these outside what it was allowed to change. Each is an exploit or an oddity, known and not fixed. **Nothing was decided for you.**

**(a) After a lost Act I the Festival breaks by itself.** With the bell rung (an Organized town) and the festival left to run (`--act2=skip`), it is won at 16–20 s: the crowd frightens itself. Failing Act I helps. Options: start the crowd calm; count only goers who break after the act starts; accept it.

**(b) A Prepared Act III is lost by the policy,** because the Banishing Rite completes and takes 40 s off the clock. A player can Discord or Blight the clergy. Options: an Act III clock of 330–360 s; a later `RITE_AT`; keep it.

**(c) 14 DP applies to Acts I and II too.** Four slots bind them, but the heavy powers are allowed there, which the night's shape did not intend. Per-act DP would need a design call.

**(d) A night that loses Act II can still rank A.** Held festival: won Act III, 25425, an A. The ranks count points, not acts lost. Options: raise the floor for A, or weight lost acts.

**(e) Silent Doom on the Mayor alone breaks the Festival.** One 1-DP cast panics all 80 of 80 goers. Options: only a *seen* death panics the crowd; a higher `FESTIVAL_NEED` does not help (the Doom still breaks all 80); keep it as the intended window.

Smaller points, also unchanged:
- Act III's win needs stability at 0%, and the farm fields and barns outside the walls take the last 60–110 s of every run (a night-only threshold of 5% would shorten it).
- `ESCORT_CLOSE` 0.8 equals Silent Doom's radius, so a Doom on a frightened Prince can take his closed-in escort with him (option: 1.0). Not measured.
- The quiet Prince kill needs the player to find a window: it succeeded in 4 of 8 policy runs, all on the `--act1=play` branch.

### Assumed open points

The spec's §6 asked for these; you did not answer before the build, so the defaults were used. Each is cheap to change:
1. **Version:** v0.09. Resonance, Trials and the campaign save move to v0.10.
2. **Early end:** an act ends as soon as an objective decides it; the 3 s slow-motion ending is the beat.
3. **The Procession is on foot:** there is no carriage.
4. **Starting numbers** (4 slots, 10 DP, festival 50 of 80, limits 50/40, clocks 2:00/2:30/2:30/3:00): used, then tuned in Task 19 (§9).

## 11. Performance

**Last Judgement, mission bench** (`--bench`, Organized), `kak-v0.08.2` against v0.09, alternating builds in a scratch worktree with `.godot` copied, 2026-10-05. **The machine was not quiet:** other sessions' Godot windows, Chrome, Edge and screen sharing were running, and after a minute or two of continuous load every run slowed to 25–35 fps whichever build it was. Eighteen alternating pairs were attempted (three sets of six, a fourth with 25-s rests); **six pairs ran with both builds quiet** (above 100 fps), the rest are machine noise:

| Pair | `kak-v0.08.2` fps | v0.09 fps |
|---|---|---|
| 1 | 135.3 | 139.9 |
| 2 | 129.8 | 120.5 |
| 3 | 128.3 | 125.0 |
| 4 | 126.3 | 127.7 |
| 5 | 136.2 | 133.3 |
| 6 | 137.9 | 139.3 |
| **Mean** | **132.3** | **131.0** |

- **−1.3 fps over six quiet pairs: within the 5-fps budget.** The old build ran first in each of these pairs, so any warm-up favours the old one. In the four fully noisy pairs of the first set (old against new: 33.0 / 35.1, 31.3 / 34.7, 29.6 / 31.0, 30.0 / 31.8) v0.09 read higher each time. Nothing was profiled or changed.
- v0.09 draws **1008 calls** against 1050 and 214,900 primitives against 237,300. `kak-v0.08.2` is the code before the PixelLab art (merged at `c09141b`, the plan's baseline), so the comparison includes the art as well as the night.
- **The Festival's crowd packed** (`--mission=long_night --bench --bench-act=festival`): 50 s into the act, so the bonfire has lit and the 80 goers are round the fountain; then the 9-s bench. **118.6 / 117.3 / 124.9 fps** (mean 120.3), worst frames 25.1 / 45.4 / 15.2 ms, **1071 draw calls**, 206k primitives. Last Judgement, run right after each on the same quiet machine: 137.1 / 137.6 / 140.3. So the packed Festival costs about 17 fps against Last Judgement, with 63 more calls from the goers and the bonfires.
- **The bench hook** (`Mission._bench_jump`): `--bench-act=festival|procession|judgement` skips the acts before the one named, and `--bench-after=SECONDS` (default 50) lets it run before timing starts. Night only: the bench of every other mission is untouched.

## 12. Tools and tests

- **Behaviour scenario `night`** (`tools/dev/behaviour_check.gd`): `--path=festival|procession`, `--act1|2|3=win|lose|skip|play`. Forced outcomes cover every §4 row; `play` plays that act with a scripted policy (the Warning's mix, the Festival's Doom on the Mayor or Discord, the Procession's whisper and Doom, Act III's richest-stability caster). `--prince=unseen|seen|escaped` and `--festival=broken|held` overwrite what an act decided, so any Act III town can be reached; `--shots` photographs the market and the procession; the `handover` line proves the time scale is 1.0, the cooldowns ready and no power playing after an act.
- **FLOW** plays a whole night through the interlude, with a restart from Act I and from Act II, Esc on the interlude, Change powers in Act II, and Esc, Restart and a vanished night during BEGIN's fade.
- **Tests:** **2087** automated checks (1755 at the baseline): acts and the night's state, every §4 row, `raise_profile`, `EventTimeline`, the Festival's crowd and success, the Procession's route, blessing, boarding and escorts, Act III's events, the results and the save.
- **The bench hook** is documented in §11.

## 13. Rulings made during the build

Rulings the controller made while the build ran, with what it costs if one was wrong:

| # | Ruling | Cost if wrong |
|---|---|---|
| T1 | A Sonnet implementer's commit trailer "Claude Sonnet 5.5" was accepted (constraints said Opus 5.5): the trailer names the model that wrote it | cosmetic history line |
| T3 | A building or kill caused later by an old act's still-running effect counts in the new act's deltas (not credited, no chain): the town's world is continuous between acts | an act's score inflated by a few buildings |
| T6 | The night's Results shows the night total, not Act III's score lines (they don't fit under the act rows) | the player can't see the building/kill breakdown; the left column under the rank is free |
| T8 | `raise_profile` skips a response whose building is gone (a `_standing` guard: exists, not destroyed, not blighted), beyond the plan's code | none known |
| T8 | Marshals promoted by a raise after the evacuation began are not posted | a few idle wall soldiers in Act III (not reachable in current paths) |
| T10 | `EventTimeline.add` has an optional guard; a false guard drops the event silently and hides it from the strip. Judgement guards: rite idle, ferry moored, last ferry not ended | an event the player expected silently doesn't show |
| T13 | After the Mayor's death a goer sent to shelter (not panic) counts as broken: "flees" reads as fleeing to cover | test/brief wording only |
| T15 | The escorts' and attendants' ring spots are deterministic ring points snapped to walkable ground, not `crowd._spot_near`, which keeps the crowd's RNG untouched | escorts slightly looser than the spec beside buildings |
| T18 | The procession policy whispers the nearest citizen near the Prince, not an escort (Whisper and Discord refuse soldiers) | none (dev policy) |
| T19 | Tuning went beyond the spec's starting numbers (§9): Act III 5:00, 14 DP, limits 90/72, `ESCORT_R` 2.5, ranks | a looser night than the spec sketched |
| T19 | Three balance issues were routed to you, not changed: (a), (b) and (c) in §10 | known exploits stay until decided |
| Final | `next_act` ends every power still running from the previous act before the new act is built (fires and ruins persist) | a big effect's tail is cut at the act boundary, hidden behind the interlude |
| Final, parked | `Rules.result()` evaluates bonuses after the 3 s ending, so a bell rung during the ending fails "Before the bell" | a bonus lost to a ring in the ending |
| Final, parked | The Mayor's event banners still show when he is frightened and does not speak (hiding them makes the strip flicker) | a banner for an address that doesn't happen |

**Fixes and rulings in the milestones:**
- **M1:** `SaveFile` appended to a copy of `paths_won` (it now reassigns); the first Prepare of a never-played night used to open empty (`Game.starting_loadout()` falls back to the night's default); Prepare between acts showed Unaware (`ActDef.response_profile()` returns the act's town); a stale `_play_ending` could emit for the wrong act (guarded).
- **M2:** `raise_profile` skips a gone building; `EventTimeline` has a `when` guard; marshals promoted after the evacuation began are not posted.
- **M4:** an escape of the Prince is not his death; the act is won only once his death is judged; `WarningDirector._alive(p: Variant)` no longer errors on a freed person; the `--prince` and `--festival` aids apply on `act_over`.
- **Final review (opus):** the BEGIN-fade Esc soft-lock; the act-end banner titles for Act II; an Act I effect killing the Prince or Mayor during Act II's intro; FLOW's missing Esc-on-interlude and Change-powers steps. All four, with seven smaller points, were fixed in `8c7f049`.

## 14. Known issues

- **FLOW under load.** The two waits for a fresh mission after a MANIFEST or Restart at the end of the night's FLOW allow 10 s. With the machine busy (other sessions running Godot) they can run out and FLOW prints one failure, "and then restarts the night from Act I (… fading true …)": a slow shader prewarm, not a logic fault. Run FLOW on a quiet machine. In the final gates the first FLOW run failed this way in two of three runs while the machine was busy; the next three runs, on the same tree, gave `checks=62 failures=0` each.
- The restart steps print "Lambda capture ... was freed" noise (pre-existing).
- `Banishing Rite` can cost the Dawn bonus by taking 40 s off the clock (§10 (b)).
- Smaller deferred points from the reviews are in the plan's Execution notes and the ledger.

## 15. What moves to v0.10

- **Resonance:** Authorities earned through how missions are solved ("Solved by" previews it; the night's acts could each grant one).
- **Awakening Trials:** the steps between Tiers.
- **The campaign save:** progress through the Tiers, beyond each mission's best and the night's paths.
- **Civilization memory:** a town that adapts to how it was struck before (the night's carry-overs are a first, single-night form).
- More Tier 1–4 missions, and §10's decisions.

**The VFX branch.** `claude/vfx-ability-effects-964aca` is still unmerged and still has its one conflict with `feat/Develop-Main`, in `src/game/crowd/person.gd` (a trial merge of `HEAD` and of `kak-v0.08.2` each gave that single conflict, so it is older than v0.09; v0.09 adds 41 lines to the file). Everything else in the merge is automatic. It needs a hand resolution.

## 16. Pushed

`feat/Develop-Main` and the tags `kak-v009-m1` … `m4` are on GitHub. The release tag `kak-v0.09` is the controller's, with the push.
