# KAK: The Warning rework (design spec)

Date: 2026-11-26. Branch `feat/warning-rework`, off `origin/feat/Develop-Main` 0a293ea0.
Sources: `.superpowers/sdd/warning/design.md` (the user's approved design and binding answers; final), the GDD
(`gdd-mission-rework.md` §03 Mission Engine, §04 Tier I Mission 01), `starter-facts.md`, and the code as read on 0a293ea0.
Rulings and open questions: `.superpowers/sdd/warning/rulings.md` (W-R1 onwards). Plan: `docs/superpowers/plans/2026-11-26-kak-warning-rework.md`.

Every number marked **(g)** is a first guess. Tune it only in the order §11 gives, never past the gates of §0.

---

## §0 The gates (the design lessons, each a check)

Every task's work is judged against these. A gate that cannot be met is reported, never bent.

| # | Lesson | The gate, as a check |
|---|---|---|
| G1 | **No waiting** | Every target (the three watchmen, the bellkeeper, the bell tower, the Temple door) is tagged and can be acted on from 0:00 of play. No step or hint asks the player to wait. An acting player is never idle for more than 45 s: the per-type gate's `idle_max` is at most 45 for all six types. |
| G2 | **Spread opposition** | The three posts are at least 8 apart (they are 8.5 to 20 apart in Aldermere). No power at Tier 1 takes two watchmen with one cast. The largest reach is Skylift's 2.5, and every post's quiet ring (QUIET_R 3.0) holds nobody but its watchman. A test casts each of the 12 starters at each post and finds one watchman in reach at most. |
| G3 | **No luck** (quiet posts) | While a watchman holds his post, nobody living and out of doors stands within `Crowd.witness_reach(p, true)` of him. That reach is DOOM_WITNESS 2.0, or WATCH_SIGHT 4.0 times sight for a far-seeing gate checker. The check samples every 0.25 s from 0:00 until each set-off, on seeds 1-3, with the DAY and NIGHT looks (`NightRules.apply`). An unseen kill at a post never depends on who walks by. |
| G4 | **No hidden losses** | There is one instant loss: a Herald within TempleReport.REACH of the Temple door. Every Herald shows as a loss threat with a true ETA. That covers a warning's own Herald, a broken-bell carrier at BROKEN_PACE, and the Lantern's own Herald after a bell the town rings itself. A seen kill banners THE WARNING PASSES ON. A broken bell banners at once. Three unseen post kills by the loudest route (Smite) never raise Local Emergency and never call the bell (tested). |
| G5 | **Countdown tags** | Each watchman at his post wears `WATCHMAN - SETS OFF IN m:ss`. It counts down in mission seconds, as the strip does, and is edge-arrowed. Every later carrier is gold and edge-arrowed. The task line's `s` counter is the soonest set-off. |
| G6 | **Verb-only text** | Steps and hints use only MissionVerbs words (kill, banish, lead, confuse, rot, seal, ...) and never name a power. Every verb a line names is proved by a case (`test_clarity_intercept`, ClarityKit). Every colour word is a tag drawn in that phase. The lines fit the plates: a hint is at most `Hud.HINT_LINES` (3) lines of `Hud.HINT_W` (236 px) at TEXT_S, and a step is at most `MissionSteps.MAX_LABEL` (32) characters and fits with ` 00/00` and ` 10:00`. |
| G7 | **why_not read-only** | `why_not()` reads only. It draws no RNG and changes no state, so `ClarityKit.assert_read_only` passes for StarfallDirector in every phase. A cast that counted never also banners (pre-flight I6). |
| G8 | **Every god wins** | For each of the six types, a scripted bot plays only `GodTree.starting(type)` at level 1 on the board Warning at Tier 1. It wins 3/3 on seeds 1-3 (W-R5: stricter than gate.sh's 2/3). A no-action run loses 3/3. |
| G9 | **Others untouched** | No reference row outside the Warning's moves. The single-star Warning's rows (`warning_none`, `_doom`, `_whisper`, `_discord`, `_mix`) and The Bell-Ringers' rows (`ringers_*`, whose RingerDirector extends WarningDirector) do not move either. Every new rule is behind a WarningDirector flag that defaults off. FLOW passes. |

---

## §1 Scope

- **In scope.** The board's Warning at Tier 1: `TierBook._warning()`, StarfallDirector, its WarningDirector stars and the Capital's overrides of it. Also its steps, hints and why-nots, its six god policies, its gate and its references, plus the rename of two display names (§10).
- **Out of scope.** The other four Tier 1 missions and every higher tier. Also the single-star Warning (§9), The Omen act, The Bell-Ringers, the Lantern itself, BellNetwork, and any power's numbers.

---

## §2 The night at a glance

| Mission time | What happens |
|---|---|
| intro | Tour: the three posts (each "sets off at m:ss"), the bellkeeper, the bell tower and the Temple door. The clock starts after it. |
| 0:00 | Play begins. All three watchmen are appointed and stand at their posts. All six tags are up. |
| 0:01 | OMEN: one star falls over the Main Gate (one FallingStarFx), with the banners A STAR FALLS OVER THE TOWN and STOP THE WARNINGS. All three watchmen look up at it (STARE, 4 s, look only), then keep their posts facing out. |
| 0:20 **(g)** | The Postern's watchman sets off for the bellkeeper. |
| 0:40 **(g)** | The Main Gate's watchman sets off. |
| 1:00 **(g)** | The Side Gate's watchman sets off. |
| about 1:06 | With no action, the first Herald reaches the Temple and the night is lost (§2.1). |
| 5:00 | Dawn (Tier 1 clock): lost if a warning lives. |

### 2.1 The chain after a set-off (unchanged code; numbers are today's)

1. The watchman runs (DUTY, 1.6 u/s) to the bellkeeper, re-aimed every 0.5 s. He tells the keeper within 0.8.
2. The keeper walks to the tower's foot and climbs (`bell_climb` 8 s, Unaware). The bell tolls and the Lantern turns: the mission clock runs at 1.5 times.
3. The keeper comes down (HERALD_DESCEND 5 s), then walks as the Herald to the Temple door at HERALD_SLOW 0.4 (0.64 u/s).
4. A Herald within 1.0 of the door: the Lantern hears, and the night is lost (HeraldObjective).

After the first toll, every later carrier's errand is the Temple door at Herald pace (`heralding()` is latched).

The paths, measured on 0a293ea0 (seeds 1-3) from the walkable posts:

| Post | to keeper | to door |
|---|---|---|
| Postern | 21.0-22.1 | 25.8 |
| Main Gate | 15.3-15.5 | 21.1 |
| Side Gate | 19.0-21.0 | 25.9 |

The tower's foot to the door is 11.0.

Doing nothing means a set-off at 20 s, delivery at about 33 s, the toll at about 43 s, the walk from about 48 s, and the door at about **66 s**.

### 2.2 Timing numbers (first guesses)

| Name | Value | Where |
|---|---|---|
| `StarfallDirector.STARS` | `[[20.0, (-5.75, 14.9), "THE POSTERN"], [40.0, (2.7, 14.5), "THE MAIN GATE"], [60.0, (14.5, 9.0), "THE SIDE GATE"]]` **(g)** | Same shape as today. The first field now means **sets off at**, in mission seconds. The posts stay where they are, because §4 makes them quiet. |
| `StarfallDirector.OMEN_AT` | 1.0 **(g)** | The one star, in mission seconds. |
| `WarningDirector.STARE` | 4.0 (today's) | The look-up. It no longer starts the run. |
| `stop_wait`, `STOP_WAIT`, `fall_at()`, `next_star()`, `next_fall_in()` | retired | Nothing falls later. `TOWN_VARS` becomes `["star_falls"]`. |

The schedule is in mission seconds, as today: after a toll, the later set-offs come sooner in real time. The tags show mission seconds.

---

## §3 What stops a warning

A warning is **stopped for good** (`warning_dead`, `phase = OVER`, `stopped_how` set) when its carrier meets one of these:

| How | Rule | `stopped_how` | Phases |
|---|---|---|---|
| Killed, unseen | Any death: any power, a zombie bite, a crush, a burn, a choke. Judged by today's `_judge()` once the cast's victims have fallen. If nobody is within witness reach, the warning dies. | `kill` | any |
| Killed, seen | It is not stopped. It relays to the nearest witness, who runs on (THE WARNING PASSES ON), exactly as today (decision 3: stealth matters for lightning and fire too). | (relay) | any |
| Out of the walls (W1) | The carrier stands out of doors outside Walls however he got there: set down, led, or fled. He walks off the map (`send_off`). This is now the base rule on the board, as it already was there (`walls_stop`). | `out` | any |
| **Dreamt it (new, decision 1)** | The watchman is CONFUSED (`Person.Mind.CONFUSED`) while he still holds his post: phase OMEN or STARE, before his set-off. He decides he dreamt it, which is durable, and the banner THE WATCHMAN THINKS HE DREAMT IT shows. He goes back to his day once the confusion wears off. He is never appointed again and never carries a relay of this warning. | `dreamt` | post only |
| The bell lies (W2) | Kept unchanged: a carrier who reaches the keeper while ALL IS WELL is sent home. It is not a starter route and is not named in the hints. | `lie` | run, bell |
| A body at the gate (W3) | Kept unchanged: a death just outside his gate draws the staring watchman out, and the postern's watchman flees out through it with its key. The stare window is now his whole hold (up to 60 s). It is not named in the hints. | `out` | post |

Holds that are **not** a stop, each with a banner (§7):

- A Confuse on a carrier who has set off, a relay witness or the keeper only pauses him, as today.
- A whisper whose goal lies inside the walls.
- A fright, a lure, or a Seal (NO LEAVING): he stands, and the errand resumes when he is back on his feet.

### 3.1 The postern's key, for a lead (new rule K2)

The Postern is barred at night, so a watchman led "out through his own gate" (the Dominion route) cannot path through it. Today a whisper there walks round by the Main Gate in hops.

K2 makes the design's route work. The rule stays narrow: no other walker uses the postern, and the town's evacuation does not open it (D29 and D30 stand).

- **What it extends.** W3's key rule (`_use_key`, `gate_keeps`) now also takes a WHISPERED watchman of that gate, whose whisper goal lies beyond the wall, while he is within KEY_WALK 4.0 **(g)** of the postern's centre.
- **What happens.** He is walked to its inner face, unbars it, and is set down just beyond it (`fold`, KEY_STEP). It is barred behind him.

### 3.2 Win, lose, bonus

- **Win.** The instant all three warnings are stopped and no Herald runs or has been heard (StarsObjective, unchanged). It never waits for a clock: a stop at 0:25 that ends the last warning wins at 0:25.
- **Lose.** A Herald reaches the Temple door (HeraldObjective, unchanged), or dawn comes with a warning alive (ClockObjective, unchanged).
- **Bonus.** Unseen (UnseenObjective, unchanged: the town never reaches Local Emergency). `TierBook.board()` clears every board mission's bonuses, so `_warning()` sets `make_bonuses` back to `[UnseenObjective]` after it (ruling W-R6). It only reports, as today. Wishes are untouched.
- **Run length.** Decision 4 accepts a short run. The gate prints the median and never judges it.

---

## §4 Quiet posts (G3)

The probe on 0a293ea0 ran 70 s, seeds 1-3, with the posts above. Every post has soldiers at their POST within 2.0 from the first frame: 2 at the Main Gate, 2-5 at the Postern, and 10-16 at the Side Gate. Those are the wall guards and gate checkers, and checkers far-see 4.0. The Postern also has 1-2 CALM citizens anchored within 2.4. No walkable spot within 6 of any gate is naturally quiet. Counting citizens only, the Main and Side Gate posts are quiet over 70 s. So the fix is the director's, not a new spot.

**`StarfallDirector._quiet_posts()`, at setup** (no RNG: deterministic by position, then instance order):

1. **Soldiers.** Each soldier whose post anchor, or whose position, lies within QUIET_R 3.0 **(g)** of a post is moved out. His anchor (and `post`, if he has one) goes to the nearest walkable ground at least QUIET_R + QUIET_MARGIN 0.5 **(g)** from every post, along the line away from it, and he is placed there before the first frame. He is held by the director (`reserved` or `busy`, so `_holds_soldier` and `Crowd.held_by_mission()` keep every duty off him) until the post he left is no longer held.
2. **Gate checkers.** The gate checkers of the three gates are held the same way, so GateCheck never steps them to the mouth beside a held post.
3. **Citizens.** Each idle citizen (CALM, no goal, not reserved) anchored within QUIET_R of a post is re-anchored the same way. A wisher or a wish target is never moved, because his spot is the wish's. If one lies within QUIET_R, the post's literal spot moves (Task 4's probe) rather than the wisher.

**`_hush_step()`, each step while a post is held** (a watchman at his post, not yet set off, not stopped):

- Any other living, out-of-doors citizen or soldier within QUIET_R of the post is turned away, unless he is a carrier, reserved, held by the god, fleeing, or on a duty the director does not own.
- "Turned away" means one of two things. If his goal lies within QUIET_R, it is moved out past the ring. If he is idle inside the ring, he is walked out past it.
- Walkers on a gate lane further than QUIET_R from a post are never touched.
- A post stops being held, and its soldiers are released (`off_duty`, back to their town posts), when its warning is stopped or its watchman sets off.

**The quiet test** (Task 4) is the G3 check, plus a log line naming who breached, where and when.

- **If it still breaches:** first make `_hush_step()` cover the case. Then move the post's literal spot, at most 1.5 from today's, keeping it inside the walls, walkable, within 4.0 of its gate's mouth and, for the Postern, within KEY_WALK.
- **What the hush may not do:** touch anyone indoors, and change a building.

---

## §5 Blight on the bell buys time only (decision 2)

**Today**, Blight on an idle bell does nothing until the bell is called. The warning still reaches the keeper, the called bell is silenced, and the keeper walks to the Temple at Herald pace with no climb and no descent. That is 26 s from the Postern against 45 s for the intact bell: breaking the bell *costs* the player time. The current Veil policy says so: "Never Blight the tower".

**New, behind `bell_breaks`** (board only, default off; ruling W-R3):

- **When the bell is broken.** The bell tower is blighted or destroyed before the toll. The director treats the bell as broken from that frame, and `heralding()` reads it as well as `rules.lantern.bell_silenced`. The director shows THE BELL IS BROKEN once. The Lantern's own SILENT_BANNER follows when a carrier starts for the Temple.
- **Where the warnings go.** Every warning's errand becomes the Temple door. That covers a watchman who sets off later, one already running, and a relay. Carriers walk at BROKEN_PACE 0.25 **(g)** (0.4 u/s): it is the farther, slower way.
- **The keeper.** A keeper who already carries one (DELIVERED) walks too, at BROKEN_PACE, with no climb and no descent. The Lantern does not turn, so dawn keeps its rate.
- **Where the pace is read.** One accessor, `carrier_pace()`, replaces the bare HERALD_SLOW in `_herald_pace()`, `herald_eta()`, `herald_label()` and the threat. It returns BROKEN_PACE while the bell is broken and untolled, and HERALD_SLOW otherwise.
- **The set-off.** The countdown does not change. Breaking the bell never stops or delays a set-off and never wins by itself.
- **The gain test.** For each post, the walk to the door at BROKEN_PACE must take at least BROKEN_GAIN 10 s **(g)** longer than the intact chain. The intact chain is the run to the keeper, plus 2 s to the foot, the climb, the descent, and the walk from the foot to the door at HERALD_SLOW, all from `TempleReport.walk_seconds()`. Measured: Postern 64.5 against 45.1, Main 52.8 against 42.1, Side 64.8 against 45.1. If a post fails, lower BROKEN_PACE in 0.05 steps.

**Honest banner (why_not, §7).** Blight aimed at the bell tower (`BlightFx.target(env, at) == bell.tower`) gives one of three banners:

- **BROKEN BELL: IT ONLY BUYS TIME.** No warning would reach the Temple sooner than through the intact bell.
- **BROKEN BELL: HE RUNS SOONER.** Some live carrier's Temple ETA at BROKEN_PACE is shorter than his ETA by the intact bell. That happens when he is near the keeper, or is the keeper.
- **THE BELL HAS TOLLED ALREADY.** The bell has tolled.

All three are read-only, from `walk_seconds`.

---

## §6 Tags, phases, tour

### 6.1 Tags (StarfallDirector.tags(), most important first)

| Who | Colour | Label | Edge arrow | When |
|---|---|---|---|---|
| Each watchman at his post | gold `MARK_MESSENGER` | `WATCHMAN - SETS OFF IN m:ss` | yes | until his set-off or his stop |
| Each running carrier, relay or broken-bell walker | gold | `MESSENGER` (to the keeper); `TO THE TEMPLE m:ss` (broken bell, its ETA) | yes | while he carries |
| The keeper carrying it | gold | `BELLKEEPER` (or the lie's countdown, as today) | yes | DELIVERED |
| Herald | gold | today's `herald_label()` | yes | after the toll |
| Bellkeeper | blue `MARK_KEEPER` | `BELLKEEPER` | while a carrier runs to him | while the bell can be called |
| Bell tower | red `MARK_WATCHED` | `BELL TOWER` | no | until broken |
| Temple door | orange `LanternWatch.MARK_TEMPLE` | `TEMPLE` | no | from 0:00. Hidden while the Lantern draws its own Temple tag. |
| Witnesses | red diamond | none | no | from a carrier's run, as today. None at a quiet post. |

### 6.2 Phases (`hint_phase()`; StarfallDirector, the most urgent live warning first)

| Phase | Meaning |
|---|---|
| `herald` | A Herald runs: a toll, or the broken bell's walkers. The Lantern's own line takes the plate. |
| `bell` | The keeper carries a warning. |
| `relay` | A witness carries one. |
| `running` | A watchman has set off for the keeper. |
| `broken` | The bell is broken and only watchmen at their posts remain. |
| `posts` | Every live warning is at its post. |

The board never returns `""`, so the single-star Warning keeps its own default line and step. The phases `stars` and `waiting` are retired. `hint_phases()` lists `["herald", "bell", "relay", "running", "broken", "posts"]`. `step_seconds()` is the soonest set-off still to come, in mission seconds, and 0 when none is left.

### 6.3 Tour

There are five stops:

- Each post: "The Postern's watchman. He sets off for the bellkeeper at 0:20." The Main Gate and Side Gate stops follow, with their own times.
- The bellkeeper: today's words.
- The Temple door: "The Temple. A warning that reaches it loses the night."

---

## §7 why_not() table (read-only; StarfallDirector aggregates over its live warnings)

The rule stays: if any live warning the cast reaches could be stopped by it, the cast says `""`. Otherwise the first banner applies.

| Cast (by verb) | On whom / where | Banner |
|---|---|---|
| kill (`_may_kill`) | any carrier in reach, or the body just judged | `""` |
| banish | any carrier in reach (W1) | `""` |
| confuse | a watchman at his post, before his set-off | `""` (he dreams it) |
| confuse | a carrier who has set off, a relay, or the keeper | `HE STOPS, BUT KEEPS THE WARNING` (STOPS_BANNER) |
| lead | the whispered man (`_whispered_at(at)`) is a carrier whose goal lies outside the walls, or the postern's watchman led beyond the wall (K2) | `""` |
| lead | the whispered man is a carrier whose goal lies inside the walls | STOPS_BANNER |
| scare | a non-soldier carrier in reach | STOPS_BANNER, except the postern's watchman with its key (`""`: W3, as today) |
| lure | a carrier in reach | STOPS_BANNER |
| seal (new) | a carrier inside the cell's reach | STOPS_BANNER. It is not shown when the same cast could kill: the Decree pair is seal, then breath, and the breath is the kill. |
| calm | any carrier (W2) | `""` (as today) |
| rot | the cast's structure is the bell tower | `BROKEN BELL: IT ONLY BUYS TIME`, `BROKEN BELL: HE RUNS SOONER`, or `THE BELL HAS TOLLED ALREADY` (§5) |
| anything else | nothing in reach | `""` |

Read-only per pre-flight I8. No RNG is drawn: `_whispered_at`, `BlightFx.target` and `walk_seconds` read positions only.

---

## §8 Steps and hints (verb-only; G6)

### 8.1 Hints (`MissionHints.LINES`)

| Key | Line |
|---|---|
| `warning.posts` | "Each watchman (gold) sets off when his tag runs out. Kill him unseen, banish or lead him out of the walls, or confuse him." |
| `warning.running` | "The watchman (gold) runs for the bellkeeper (blue). Kill him unseen (red), or banish or lead him out of the walls." |
| `warning.broken` | "The bell is broken: a watchman (gold) who sets off walks to the Temple. Time only. Kill, banish, lead or confuse him." |
| `warning.relay` | unchanged (WARNING_RELAY, shared with the single-star Warning and The Omen) |
| `warning.bell` | unchanged (WARNING_BELL, shared) |
| `warning.stars`, `warning.waiting` | removed |
| `warning` (default, single-star only) | unchanged |

### 8.2 Steps (`MissionSteps.STEPS["warning"]`)

| Phases | Label | Counter |
|---|---|---|
| (default, single-star) | "Kill the messenger (gold) unseen" | none (unchanged) |
| `relay` | "Kill the witness (gold) unseen" | none (unchanged) |
| `posts`, `broken` | "Kill or confuse watchmen (gold)" (31) | `s` (the soonest set-off) |
| `running` | "Kill or banish him (gold) now" (29) | `n` |
| `bell` | "Kill the ringer (gold) unseen" | `n` (unchanged) |

### 8.3 The cases that prove the verbs

Each proof is a real cast through `Rules.cast()` (B2) in the board world:

- **posts:** kill (Silent Doom), banish (Skylift out), lead (whisper out, including the postern by K2), confuse (Discord at the post, giving `dreamt`).
- **running:** kill, banish, lead out.
- **broken:** each of the four posts verbs, with the bell blighted first.

**Fitting the plates.** If a line does not fit (test_mission_hints wraps with UiTheme.wrap at HINT_W), shorten its words and keep every verb. If it still does not fit, drop the colour word before any verb.

---

## §9 MissionBook.warning(), the single-star version: kept unchanged

It is still used by:

- **The campaign.** Night 1 (`CampaignDef.NIGHTS[0]`) plays `"warning"` off the board, through `MissionBook.get_mission()`.
- **FLOW.** It drives `(director as WarningDirector).warning_dead` in the campaign flow (game.gd ~3748, ~3996). It uses `MissionBook.warning().default_loadout` for the board picks (game.gd 2324-2536).
- **Shows.** The `duty-*`, `ascend`, `*-endless` and bar shows.
- **The intro.** The interlude's sample result.
- **The base of the board's def.** `TierBook.board("warning")` copies it and overrides the director.
- **The Long Night's Omen act**, which shares WarningDirector.
- **About 20 tests**, among them test_herald, test_herald_nights, test_law_mark, test_clarity_intercept, test_mission_book, test_hud and test_cael_lines.
- **Five references**: `warning_none`, `_doom`, `_whisper`, `_discord` and `_mix`.

**Decision.** It is kept as it is.

- **What stays the same.** Its director, rules, hints, steps and references do not change. Every new WarningDirector rule is a flag that defaults off. The single-star Warning, The Omen and The Bell-Ringers set none of them; StarfallDirector sets them all.
- **What the board still borrows.** It keeps borrowing the def's default loadout (whisper, doom, discord), so FLOW's board steps hold.
- **What changes for FLOW.** FLOW sets `w.warning_dead = true` on each of `StarfallDirector.stars` and expects the main objective. That still holds, because all three stars are set up at 0:00.
- **Later.** Whether the campaign's Night 1 becomes the reworked night is the user's call after play (open question W-Q1).

---

## §10 The rename (decision 4): display names only

| id (unchanged) | Old `name` | New `name` | Also changes, because it is derived |
|---|---|---|---|
| `tax_collector` | The Tax Collector | **The King's Tribute** | `intro_banner` (`_tier1()` upper-cases the name): THE KING'S TRIBUTE |
| `spoiled_harvest` | Spoiled Harvest | **The Broken Harvest** | `intro_banner`: THE BROKEN HARVEST |

- **The only edits.** The two `_tier1()` calls in `mission_book.gd`.
- **What does not change.** The people's tag labels (`TAX COLLECTOR`, `DEPUTY`), the director banners (THE TAX COLLECTOR SETS OUT), the wish label `TAX COLLECTOR`, the ids, the scenario names (`tax`, `harvest`), and the old docs. These name a person or a past record, not the mission (ruling W-R8).
- **The check.** The apostrophe must draw in the banner font: glyph_ascii or a test of `UiTheme` on "THE KING'S TRIBUTE".
- **References.** None move: no checksum reads `MissionDef.name`. Confirm that with `refs_check --only='^(tax|harvest)_'`.

---

## §11 Tuning order (if the gate misses)

1. Make the failing type's policy play the opposition as a player would (implementer.md).
2. The set-offs (20/40/60): spread or later, at most 10 s per step and at most 30/50/70.
3. QUIET_R, QUIET_MARGIN, KEY_WALK.
4. BROKEN_PACE (§5's gain test must still pass).

This is at most three rounds. Then report DONE_WITH_CONCERNS with the numbers.

---

## §12 The six god routes (each proven by its scripted bot, §13)

Might is 6 at Tier 1 and refills in 60 s. Set-offs are 20/40/60.

### Veil (doom, blight): Silent Doom on each watchman at his post

- Silent Doom costs 1 and cools in 10 s.
- **The timeline.** Casts at about 1, 11 and 21. The win comes at about 22.
- **What it needs.** Unseen kills need quiet posts (§4).
- **Blight.** It is never needed. The policy may rot the tower only to prove §5 (the policy does not).

### Ruin (smite, ember): Smite each watchman at his post

- Smite costs 1 and cools in 10 s.
- **The timeline.** Three Smites; the win comes at about 25.
- **Why the kills stay unseen.** Smite is loud: its fright reaches past the ring but frightens nobody into the ring. Quiet posts keep each kill unseen.
- **Ember.** It is a fallback for a runner (he burns and dies in 4 s). The policy keeps to Smite.
- **G4.** The test that three Smite kills never call the bell guards this route.

### Death (deathmark, raise): Death Mark each watchman at his post

- **The timeline.** Casts at 0, 20 and 40 (CD 20). Each marked man dies 10 s later, at his post: 10, 30 and 50, before his set-off. The win comes at about 50.
- **Raise the Dead.** It is the fallback on a body.
- **The constraint.** The mark must land at least 10 s before his set-off. The policy reads the tag.

### Passage (skylift, windfall): Skylift each watchman out of the walls

- **The timeline.** Casts at 0, 20 and 40 (CD 20; it takes 1.4 s). Each set-down outside the walls is W1. The win comes at about 42.
- **The ring.** QUIET_R 3.0 is more than the lift's 2.5, so one lift takes one man (G2).
- **Windfall.** It is the fallback: it bars a runner's road while the lift cools.

### Decree (noleave, breath): Leaving Is Prohibited, then Breathing Is Prohibited, on each watchman at his post

- **The code differs from the design here.** The design reads "Breath on a man standing still", but **breath alone does not kill a standing man**. BreathFx makes him clutch his throat and run straight out of its 2.5 circle (`Person.panic()`), about 1.9 s against CHOKE 3 s. Only a NO LEAVING cell holds him, and then it is a sure kill (BreathFx doc).
- **The route.** So the route is the pair on every watchman, at a cost of 3 Might each:
  - 0 s: the Postern (6 to 3 Might);
  - about 25 s: the Main Gate (Might about 5.5 to 2.5; breath cools in 25 s);
  - about 50 s: the Side Gate (Might about 5 to 2).
- **The win.** It comes at about 54. It is feasible, but Might and the 25 s breath cooldown leave little slack (risk R2).
- **The fallback.** Breath behind him as a fright that sends him out through his gate (W1; the postern's by its key, as today's policy).

### Dominion (whisper, discord): lead each watchman out through his own gate

- **The route.** Whisper costs 1 and cools in 8 s. Whispers at about 0, 8 and 16 lead them out; the Postern's goes through by K2. The win comes at about 25.
- **The alternative.** Discord at a post makes him dream it. Discord costs 2 and cools in 30 s, so casts at 0 and 30 cover the 20 s and 40 s watchmen. The 60 s watchman is on the cooldown edge, so he is led out. The design's note says the 20/40 pair is out of reach. In fact it is the third who must be led: still one led out of the three (W-R7). The bot plays Discord, then Discord, then a lead.

---

## §13 The gate (one run = god_gate.sh --only=warning)

- **The command.** `bash tools/dev/god_gate.sh --only=warning`. It runs `gate.sh warning --god=<type>:1 --board` for the six types, seeds 1-3, plus `--with-none` on the first type (ruin): six pairs and three none runs. Use `--jobs=2` when other sessions run Godot.
- **The binding verdict.** For each type: `wins=3/3` (W-R5) and `idle_max` at most 45. Overall: `none_lost=3/3`. The last line must be `god_gate tier=1 pass=6/6 none_lost=1/1 PASS`, and every pair's own line must show 3/3.
- **What is printed and not judged.** The median, the Capital pass (`--city=capital`: Tier 1 in the Capital is dev-only), and route b (`gate.sh warning --route=b --board --with-none`, the any-power player, tier1_b.gd).
- **The policies.** They live in `tools/dev/routes/god_t1/warning.gd`, one `act_<type>` per type. They use only `GodT1.loadout(type)` (that is `GodTree.keys_for(type, 1)`, which is `GodTree.starting(type)`), cast only through `cast_` pieces or `rules.cast`, and read only what a player sees: the tags' countdowns and positions. No filler casts.
- **What is reused.** The existing machinery: `behaviour_check --god`, `GodT1`, `gate.sh` and `god_gate.sh`. No parallel bot is built.

---

## §14 References

- **New rows**, 21 of them, recorded in the gate task's commit:
  - `warning_board_none_{1,2,3}`: `--scenario=warning --board --case=none --seed=N --god=ruin:1`
  - `warning_board_<type>_play_{1,2,3}`, for each type in ruin, death, veil, passage, decree, dominion: `--scenario=warning --board --case=play --seed=N --god=<type>:1`
- **Rows that must not move:** `warning_none`, `warning_doom`, `warning_whisper`, `warning_discord`, `warning_mix` (the single-star Warning, §9), `ringers_*`, `tax_*`, `harvest_*`, and every other row (G9).
- **If a protected row moves,** it is a flag leak and a bug, unless a shared change explains it in the commit body. The user approved re-recording Warning rows only.
- **Today** there is no board-Warning row, so "every Warning row moves" (design) means these new rows, and the single-star rows stand.
- **Each task's check:** `bash tools/dev/refs_check.sh --only='^(digest|crowd_check|calm|warning_|ringers_)'`, plus `^(tax|harvest)_` for the rename task.

---

## §15 Risks

- **R1.** The Side Gate's ring empties 10-16 soldiers: a big change to the wall guard there. Holding them may starve a duty, such as the gate check or beats, at that gate for up to 60 s. That is accepted while the post is held, and they are released after.
- **R2.** Decree's Might margin is thin. If a seed fails on Might or cooldown, first make the policy take the Postern pair at 0, then tune the set-offs (§11).
- **R3.** A loud route (Smite times 3, Breath times 3) might add incidents in one district. The Postern and the Main Gate are 8.5 apart. The G4 test guards the bell.
- **R4.** BROKEN_PACE also slows a keeper who carries one when the bell breaks. That is honest, because the banner says HE RUNS SOONER when it is shorter.
- **R5.** K2 adds a second key use. D29 and D30 (the evacuation and other walks go round) are kept and tested.
