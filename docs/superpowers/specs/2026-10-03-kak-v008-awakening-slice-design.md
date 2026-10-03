# KAK v0.08 — Awakening slice — design

**Baseline:** `kak-v0.07.1`, branch `feat/Develop-Main`.

**Direction:** the user's design document *KAK_0.10 God Awakening, Authority Progression & Divine Loadout* (E:\Document\PROJECT\KAK). It turns KAK into a campaign:
- the god reawakens through five Tiers, from Whisper to Ascendance;
- Authorities are earned through outcomes;
- Divine Power becomes a loadout budget;
- the civilization adapts as the campaign goes on;
- it ends in a Last Judgement.

**This version is the first slice of that direction.** It covers:
- a mission framework;
- Divine Power as a loadout budget, with up to six slots;
- a new Tier 1 power, Mind Whisper;
- one Tier 1 mission, *The Warning*;
- today's mission kept as *Last Judgement*, a Tier 5 Skirmish.

Resonance, Awakening Trials, the campaign save and civilization memory come in later versions (v0.09 onward).

## Decisions (with the user, 2026-10-03)

| Topic | Decision |
|---|---|
| First Tier 1 mission | **The Warning:** a watchman runs from the Main Gate to raise the bell; stop the warning |
| Divine Power | **Loadout budget, in this slice:** no DP spent during a mission. Last Judgement moves to the new model too, with retuned cooldowns |
| Mind Whisper | **Drag "go there":** press on a person, release on a spot; they walk there, linger, then resume |
| The Warning's pool | **Five small powers:** Mind Whisper 1, Silent Doom 1, Will-o'-Wisp 2, Discord 2, Thornwall 2; 3 slots, 6 DP |
| Win rule | **The warning dies:** win if the messenger is killed unseen or the omen fades (2:00); lose if the bell rings; a witnessed death passes the warning to the witness |
| Choosing a mission | **Mission board** between Title and Prepare |
| Silent Doom | Cooldown **10 s** (2.5 s was safe only while each cast cost 8 DP) |
| Version | **v0.08**, with later steps as v0.09, v0.10 and so on |
| Architecture | **Mission definitions + objectives + a director per mission** (approach A) |

## 1. Mission framework

- **`MissionDef`** describes one mission:
  - id, name, Tier, brief (two lines), goal line;
  - slots, DP capacity, power pool, clock seconds;
  - town setup: response profile, or "chosen on Prepare" for Last Judgement; camera start;
  - primary and bonus objectives;
  - the director script.

  Missions are listed in a `MissionBook`, the way `PowerBook` lists powers.
- **`Objective`** reports `PENDING`, `DONE` or `FAILED` from `check(mission_state)`, and has a short label for the HUD and the results.
  - A failed primary objective loses the mission; all primaries done wins it.
  - Bonus objectives only report in the results.
  - Today's hard-wired checks become objectives:
    - `CitadelObjective`: the Citadel is down and stability broken;
    - `EscapeLimitObjective`: fails at 50 escaped;
    - `ClockObjective`: fails at 0:00 by default; a mission may set it to succeed at 0:00 instead (The Warning).
  - Last Judgement's evaluation order stays the same: the win is tested first, so a city that falls on the last tick counts.
- **`MissionDirector`**: per-mission setup and scripted actors, stepped with the mission.
  - Last Judgement has none.
  - The Warning's director runs the omen, the watchman and the relay.
- **`Rules`** keeps casting, cooldowns, the cast lock, kill and chain credit, stability and scoring. Its `_check_end()` becomes a loop over the mission's objectives.
- **Screen flow:** Title → **Mission board** → Prepare (that mission's pool, slots and DP) → Mission → Results.
  - Results offers Replay, Change powers and Missions; Pause offers the same set.
  - The flow test (FLOW) covers the board.
- **Save file:** per mission, the best result and the last loadout:
  - Last Judgement: best score and rank;
  - The Warning: won, and the bonus earned.

  The difficulty choice stays global.
- **M1 is a pure refactor.** Last Judgement must pass every gate unchanged before M2 changes any rule: digest, crowd_check, FLOW, the mission test, and the behaviour scenarios that cast.

## 2. Divine Power as a loadout budget

- **Before the mission:** each power has a **DP price**. The player fills up to the mission's **slots** without going over its **DP capacity**. Empty slots are allowed.
  - The Warning: 3 slots, 6 DP.
  - Last Judgement: 6 slots, 14 DP.
- **During the mission:** no DP is spent. Cooldowns, the one-power-at-a-time cast lock, the clock, the alarm and the town's response are the limits.
- **Removed:**
  - the DP bar;
  - `DP_REGEN`;
  - the Temple's 70% refund;
  - DP from buildings, soldiers, the Citadel and chains (`DP_RECOVERY`);
  - `SCORE_PER_DP`.
- **Divine Surge:** destroying the Temple (the cathedral) resets every cooldown once, with the banner "DIVINE SURGE".
- **Score:** the rank thresholds are retuned so a typical winning run keeps its rank without the DP term. The values come from measured runs.
- **Prices and starting cooldowns:**
  - The rule of thumb: new cooldown = the larger of the old cooldown and 3 × the old DP cost.
  - Last Judgement is then tuned so the mission test (default loadout, Organized) plays about as at `kak-v0.07.1`. "About" means: the Citadel falls in the same half-minute, and escapes stay within ±5.

| Power | Authority | Loadout DP | Cooldown (s) |
|---|---|---|---|
| Mind Whisper (new) | Dominion | 1 | 8 |
| Silent Doom | Veil | 1 | 10 |
| Will-o'-Wisp | Dominion | 2 | 30 |
| Discord | Disorder | 2 | 30 |
| Blight | Veil | 2 | 36 |
| Thornwall | Passage | 2 | 42 |
| Heaven Splitter | Ruin | 2 | 30 |
| Tornado Tempest | Ruin | 3 | 45 |
| Pestilence | Life/Death | 3 | 48 |
| Dragonfire Parade | Ruin | 3 | 54 |
| Gravity Distortion | Ruin | 3 | 60 |
| Walking Laser Grid | Ruin | 3 | 66 |
| Orbital Strike | Ruin | 3 | 66 |
| Tsunami Breaker | Ruin | 4 | 60 |
| Cinderfall Barrage | Ruin | 4 | 75 |
| Judgement of the Ancients | Ruin | 4 | 90 |
| Glacial Cataclysm | Ruin | 4 | 90 |
| Nuclear Nova | Ruin | 4 | 120 |

- **Authorities replace kinds.** `PowerBook` gains `authority` (Ruin, Veil, Dominion, Passage, Disorder, Life/Death), and the draft's tabs follow it. `quiet` stays a separate flag.

## 3. The Warning (Tier 1)

**Premise.** The god's first stirring: a star falls over the Main Gate. A watchman sees it and runs to the bellkeeper. If the bell rings, the town is warned before the god has any strength.

**Setup**
- **Town:** the whole of Aldermere in its evening routine. The camera starts on the Main Gate, framing the route to the Bell Tower.
- **Town profile:** **Unaware** (a new Tier 1 profile).
  - the Bell Network with an 8 s climb, and the fire brigade as at Organized;
  - **no escorts** (`escorts_per_duty` 0);
  - marshals and rescue squads as at Organized; they rarely matter here.
- **Loadout:** 3 slots and 6 DP, from Mind Whisper, Silent Doom, Will-o'-Wisp, Discord and Thornwall.
- **Clock:** 2:00, shown as "Omen fades". The `ClockObjective` succeeds at 0:00.

**The watchman**
- A citizen with a new role, `WATCHMAN`, and a new look: a lantern and a dark cloak.
  - He is affected like any citizen: Doom, Whisper, Discord, fright.
  - He ignores the Wisp while on his errand.
- **The omen:** at 0:02 a falling star lands at the Main Gate, with a flash and a banner. The watchman stares at it for 4 s.
- **The errand:**
  - He runs at `PANIC_SPEED`, in the existing `DUTY` mind, to the bellkeeper's **current** position. The director re-targets him every 0.5 s, so if the keeper moves, he follows. `DUTY` already gives the right behaviour: the Wisp's lure skips it, Discord confuses it, and a fright breaks it.
  - Reaching the keeper within 0.8, he delivers the warning: `BellNetwork.call_keeper()`. The keeper runs to the tower and climbs as today.
  - If the keeper is dead, the watchman climbs himself, 1.5× slower (`BellNetwork.replace_keeper`).
- **Unhindered,** the bell rings at about 0:25.
- **Interruptions:**
  - **Fright:** a frightened watchman drops the errand and picks it up again once he recovers.
  - **Discord:** he forgets it for 15 s, then remembers.
  - **Mind Whisper:** he walks where he is sent, lingers 8 s, then runs on.
  - **Thornwall:** he paths round it.

**Win and lose**
- **Lose:** the bell rings (`BellSilentObjective` fails).
- **Win:** the warning dies (`WarningObjective`):
  - the current messenger is killed and **no living person witnessed it** (the existing doom witness rule: within `Crowd.DOOM_WITNESS` of the body);
  - or the omen fades (0:00) with the bell silent.
- **Relay:** if the messenger's death is witnessed, the nearest witness becomes the new messenger. They take the marker, adopt the errand and run on.
- **Bonus, "Unseen":** the town never reaches Local Emergency.

**How each Authority can solve it**

| Authority | Power | Effect on the warning |
|---|---|---|
| Veil | Silent Doom | Kills the messenger; clean only with no witnesses near |
| Dominion | Mind Whisper | Sends the messenger or the keeper elsewhere for about 8 s |
| Dominion | Will-o'-Wisp | The messenger ignores it; it pulls the keeper and onlookers away |
| Disorder | Discord | The messenger forgets for 15 s |
| Passage | Thornwall | Blocks his street for 25 s; forces a detour |

**On screen**
- A marker over the current messenger. When he is off screen, an arrow at the screen edge points to him.
- An objective panel showing "Stop the warning", "Omen fades m:ss" and "Unseen ✔/✘".
- Banners:
  - "A STAR FALLS OVER THE MAIN GATE"
  - "STOP THE WARNING"
  - "THE WARNING PASSES ON" (on a relay)
  - "THE WARNING DIES" (a win)
  - "THE BELL TOLLS" (a loss)

**Results**
- Win or loss, the bonus, and the time.
- **Solved by:**
  - for a kill: the Authority of the power that made it;
  - for an omen-fade win: the Authorities of the powers that delayed a messenger during the mission.

  This is shown only, not saved: it previews Resonance (v0.09).

## 4. Mind Whisper

**Basics:** Dominion, Tier 1, 1 DP, 8 s cooldown, quiet (no threat, no alarm). Aimed by dragging.

**Aim**
- The press snaps to the nearest living **citizen** within `PICK_R` 0.6 who is out in the open.
- The release snaps to walkable ground at most `REACH` 10 from that citizen.
- If the press finds nobody, the cast is refused with "no one to whisper to". The slot is not spent and no cooldown starts.

**Preview**
- A ring on the person and a dotted line to the spot. The line turns red past `REACH`, and the release clamps to it.

**Effect**
- The person drops whatever they are doing, whether routine, duty, errand or flight.
- They **walk** (`WALK_SPEED`) to the spot, in a new `WHISPERED` mind, then linger `LINGER` 8 s.
- **Then they resume:**
  - flight becomes flight again;
  - an errand becomes the errand again;
  - a duty is picked up again by its manager (the bell, the rite, the engineers);
  - anything else returns to their day.
- **Who is immune:** soldiers, anyone inside, and the dead. The cast is refused for them too.

**Look**
- A faint gold glyph over the person while whispered, and a soft gold ring at the destination.
- An icon (`tools/dev/make_power_icons.py`) and a draft preview clip, recorded with `behaviour_check --scenario=clip`.

## 5. Screens

- **Mission board** (new, 640×360 pixel UI, `UiTheme`):
  - one card per mission, showing its name, a Tier badge, the brief, the goal, "N slots · M DP" and the best result;
  - click or Enter chooses it; Esc goes back to the Title.
- **Prepare:**
  - the pool is limited to the mission's powers;
  - the tabs are Authorities;
  - cards show the DP price and the cooldown;
  - the loadout bar has the mission's number of slots, plus a budget meter ("4 / 6 DP");
  - cards that would go over the budget, or that have no free slot, are dimmed and refuse with a short reason;
  - the difficulty selector shows only when the mission lets the player choose it (Last Judgement).
- **In-mission bar:**
  - the DP bar is gone;
  - the slots are compact so six fit across 640 px (icon, key, name cut to fit, cooldown);
  - the objective panel shows at the top left when the mission has objectives to show.
- **Results:**
  - The Warning: its objectives ✔/✘ and "Solved by";
  - Last Judgement: score and rank as today, without the DP line.

## 6. Measures

- **Tests:**
  - **Objectives:** every class, including evaluation order and the clock's two modes.
  - **Mission flow:** `MissionBook`, plus the board in FLOW.
  - **Loadout rules:** prices, budget, slots, empty slots.
  - **Casting and the Surge:** no DP spent on a cast; the Surge resets cooldowns.
  - **Mind Whisper:** aim snapping and refusal, walk and linger, resume for each mind, and immunities.
  - **The Warning:** route, arrival and call, keeper dead (the watchman climbs), relay on a witnessed death, win on an unseen kill, win at 0:00, loss on the ring, and the Unseen bonus.
- **Behaviour scenario `warning`:** `--case=` none / doom / whisper / discord / thornwall / mix, each reporting the result and the time.
- **Gates:**
  - tests, digest, crowd_check, FLOW;
  - the mission test before and after M2, compared as in §2;
  - the bench against `kak-v0.07.1`, within 5 fps.

## Milestones (each tagged)

1. **M1 — Mission framework:** MissionDef, MissionBook, objectives, the director hook, Last Judgement migrated, the mission board, per-mission saves. No change to how Last Judgement plays.
2. **M2 — Divine loadout:**
   - prices, slots, the budget meter;
   - Authority tabs;
   - the in-mission bar without DP;
   - the cooldown retune, the Divine Surge, the score retune.
3. **M3 — Mind Whisper.**
4. **M4 — The Warning:**
   - the Unaware profile;
   - the watchman and the omen, the director, the relay;
   - objectives, the marker and panel;
   - "Solved by".
5. **M5 — Wrap-up:** the `warning` scenario, balance, the bench, `docs/KAK_Version_0.08_Summary.md`, tag `kak-v0.08`.
