# KAK: Town Suspicion (the bell waits until the town believes a god is here)

Date: 2026-11-20. Branch `feat/town-suspicion` (worktree `.claude/worktrees/town-suspicion`), cut from `feat/Develop-Main` a5825501.
Source: Discord #ideas "About alarm and alert on ability use" (id 1573203747956588564) and the conversation that followed.
Marks: **[user]** = decided by the user; **[call]** = my proposal, open to correction; **[open]** = waits for the user's answer.

## 1. Intent

Today the town concludes "a god is attacking" far too soon. One Smite, far from the Bell Tower, and the bellkeeper is
already running for the rope. The user wants the town to think like people: one bolt of lightning is weather; lightning
again and again is strange; only then do they call it a god and ring the bell. **[user]**

Why: the player is a hidden god. Choosing powers that look natural, and not striking too often, should be a skill the
game rewards. An instant alarm removes that choice.

## 2. How it works today (facts from the code)

- People near a cast react locally already: those inside the danger run, those within sight or earshot stop and look
  (`Crowd.on_cast` / `_land` / `_react`). This stays.
- The town's stage (`AlarmManager`, shown top right) rises on counts taken from the sky, with no belief involved:
  any danger gives Concern; 4 deaths or collapses in one district give Local Emergency; alarm 35 or 2 districts in
  emergency give City Emergency.
- **The fast path the user feels:** the first Local Emergency calls the bellkeeper (`Crowd._on_stage`, crowd.gd:1855 ->
  `BellNetwork.call_keeper()`). He climbs 8 s and rings; the ring adds 20 alarm, tells every citizen, and City Emergency
  then needs only 25. On Lantern nights the toll also stirs the Lantern and adds Gaze.
- **The second fast path:** in missions with a watched target (tax collector, informer, bishop, inquisitor), a witnessed
  kill calls the bellkeeper at once (`AssassinateDirector._judge`, assassinate_director.gd:570).
- No cast calls the bell by itself today, however unnatural it looks.
- 41 of the 77 powers are "quiet" already: the town sees nothing at the cast. 36 are loud.
- There is no weather in the game (rain exists only inside Wrath of the Sky), and nothing draws words over people
  (only `MapTag` labels and banners).

## 3. Goals, non-goals, anti-goals

Goals
- A single natural-looking cast never sends the bellkeeper, however many it kills. **[user]** ("5 dead in the market
  from one Smite: still weather.")
- Repeated natural-looking casts in a short time do. **[user]**
- Disaster response stays: people flee and mourn, soldiers come to look, the fire brigade works. Only the bell and what
  follows it waits. **[call, agreed in conversation]**
- **The new rule only ever delays the bellkeeper compared with today; it never sends him sooner.** No power, tree or
  mission gets a harsher town than it has now. **[call]**
- The player can always see how suspicious the town is and why it changed. **[call]**

Non-goals (this round)
- A belief per person, spread by talk (approach B).
- A weather system (ambient storms that would hide a Smite).
- Any change for powers and deaths that have no natural look: Silent Doom, Death Mark, Pestilence, madness, the whole
  Dominion, Passage, Death and Decree kits. A witnessed death of those kinds calls the bell exactly as today.
- The Lantern and the Gaze: they keep reading witnessed deaths as today (the Lantern is no townsman; it knows).
- New audio files.

Anti-goals
- Luck: suspicion never rolls a die and never uses the crowd's random stream.
- A hidden loss: the town must never "know" without the gauge and a banner having shown it coming.
- Waiting as the best play: the fade is slow enough that sitting out the clock costs more than it gives (5.3).
- Missions tuned down to pass their gates.

## 4. Approaches

- **A. A suspicion gate in front of today's alarm (chosen by the user).** One number for the town. Witnessed casts raise
  it by how natural they look and how often they repeat; it fades. Deaths a natural-looking power explains do not call
  the bellkeeper until the town "knows". Everything after the bell is today's code.
- B. A belief per person, spread by talk; the bell rings when a believer reaches the keeper. Most lifelike; costly on
  200+ people, hard to read on screen, hard to tune, touches every director.
- C. Retune numbers only (more deaths for Local Emergency, a slower keeper). Cheap; has no "frequent = strange".

The user picked A.

## 5. The design

### 5.1 The town's suspicion

A new small class `Suspicion` (`src/game/crowd/suspicion.gd`), owned by `Crowd` beside `alarms`.

- `value` 0..100. `UNEASY_AT` 40. `KNOWN_AT` 100.
- `known`: a latch. Once true it stays true for as long as the crowd lives (a night's acts share one crowd, so a town
  that knows in Act I still knows in Act II). **[call]**
- A memory of the signs of the last `MEMORY` 60 s (look and time).
- No randomness. Advanced by the crowd's clock.

### 5.2 Signs: what raises it

A **sign** is one cast that at least one person witnessed. Deaths and collapses are not signs: body count alone proves
nothing **[user]**.

Each power has a **look** (`PowerBook`, new row field `"look"`, read through `PowerBook.look(key)`):

| Look | Base | Powers **[call: the user may move any row]** |
|---|---|---|
| lightning | 20 | Smite |
| fire | 20 | Ember |
| storm | 25 | Tornado Tempest, Wrath of the Sky |
| quake | 30 | Earthshatter |
| flood | 30 | Tsunami Breaker |
| miasma | 30 | Breathing Is Prohibited (a choking haze: "bad air") |
| none | 0 | every quiet power except Ember, and Disorder (a crooked toll is heard; it proves nothing) |
| unnatural | the town knows at once | every other loud power: Heaven Splitter, Scatter Strike, Dragonfire Parade, Light of Solaris, Cinderfall Barrage, Raise the Dead, Gravecall, Windfall, Hellmouth Spark, Hound Gate, Door to the Deep, Erasing Distance, Eminent Domain, Fenced Rule, The Gate Below, Pale Reign, Divine Schism, Heaven's Door, Doors of the Dead, The Closing Cage, The Pale Serpent, Grave Tide, and the loud powers outside the trees (Pilgrim Road, Gravity Distortion, Walking Laser Grid, Orbital Strike, Judgement of the Ancients, Glacial Cataclysm, Nuclear Nova) |

Rule for rows without the field: a loud power is `unnatural`, a quiet power is `none`.

What a natural sign adds:

`added = base x (1 + same) x (1 + 0.5 x others) x wary`

- `same`: signs of the same look still in memory. The second Smite inside a minute counts double, the third triple.
- `others`: how many different other looks are in memory. Lightning, then a quake, then a flood is a bad night.
- `wary`: the town's readiness (`ResponseProfile`, new field `wary`): Unprepared 0.8, Unaware 1.0, Organized 1.0,
  Prepared 1.25, God-Resistant 1.5. **[call]**

Worked examples (wary 1.0, fade as 5.3; these are test cases):
- One Smite at 0 s: 20. Calm.
- A second at 30 s: 20 - 6 + 40 = 54. Uneasy.
- A third at 59 s: 54 - 5.6 + 60 = 108.4. The town knows.
- A Smite every 61 s: 20, 21.6, 23.2, ... (the fade takes 18.4 between casts). Still calm after five minutes.
- Smite at 0 s, Tornado at 10 s, Earthshatter at 20 s: 20, +37.5 = 57.5, +60 = known.

Who is a witness: any living person, citizen or soldier, not inside a building, not asleep, within the cast's sight
reach (`PowerBook.REACH` sight x `Crowd.sight_scale`, so night shortens it) of any point the cast lands on. For Ember,
which has no reach row, `QUIET_SIGN_SIGHT` 5.0. A cast under the Unseen Hour is no sign (it already returns early). In
a hushed town nobody can tell anybody: no sign. **[call]**

When: a loud power's sign is counted when its danger lands (`Crowd._land`), Ember's at the cast.

### 5.3 The fade

After `CALM_DELAY` 15 s with no new sign, `value` falls 0.4 a second (100 to 0 in about four minutes). `known` never
unlatches. The fade is what "frequently" means; with mission clocks near five minutes, waiting a full minute to make
one more cast free is a real price. **[call]**

### 5.4 When the town knows

`known` becomes true when any of these happens (the first wins and names the reason for the banner and the overlay):
1. `value` reaches 100.
2. Someone witnesses an unnatural power.
3. The stage reaches City Emergency by today's rules (alarm 35, or two districts in emergency): the scale of the
   disaster convinces them without help.
4. The bell rings by any route (hooked in `Crowd.ring_bell`, which the keeper, a mission's ringer and the bench all reach).
5. The Citadel is hit.

On becoming known, `value` is set to 100. Knowing by itself sends nobody: it lifts the excuse of 5.5, and from then on
every rule is today's.

### 5.5 What changes in today's rules

**Explained deaths.** A death or collapse is *explained* while the town does not know and a natural-looking power
caused it: the kill kinds of the natural powers (`lightning`, Ember's `fire`, the tornado's `wind`, the tsunami's
`water`, the haze's `choke`, Earthshatter's and Wrath of the Sky's own kinds; the builder reads each natural power's FX
for the kind it kills with and lists them in one table in `Suspicion`), and any building's collapse. Every other death
is *unexplained*, as is every death once the town knows.

1. **The keeper's call at a district emergency.** Today: the first Local Emergency calls him. New: he is called when a
   district holds `LOCAL_EVENTS` (4) *unexplained* incidents, or when a district is in Local Emergency and the town
   knows, whichever comes first; the check runs at each incident and when the town comes to know. The stage itself
   counts every incident as today, so Local Emergency still shows, the two investigators still go and the fire brigade
   still turns out. Since every incident is unexplained once the town knows, and no explained incident exists without a
   natural power, a run with no natural power behaves exactly as today.
2. `RingerDirector` (ringer_director.gd:224: re-calls the keeper at Local Emergency after a stand-in gives the rope
   back) uses the same condition as item 1.
3. **[open, question 1]** The watched-target missions (`AssassinateDirector._judge`). Proposal: a witnessed kill of an
   *explained* kind no longer calls the keeper outright. It adds a flat `TARGET_SIGN` 40 to the suspicion ("the tax
   collector, struck by lightning, on tax day?"), and calls the keeper only if the town knows after that. The "seen"
   banner, the guards' cry and `q.unseen` (bonus objectives, results) keep meaning "somebody saw it". A witnessed kill
   of any other kind calls the keeper as today. So a Smite on the collector in plain sight is 20 + 40 = 60: uneasy,
   no bell. A second seen lightning kill inside the minute is caught.
4. Unchanged on purpose: The Warning's relay (a witness picks up the dead messenger's errand: that is about the
   message, not about a god) and its scripted `call_keeper()` (warning_director.gd:356), the Procession's quiet
   succession, Silent Doom's witness rule, every `nearest_witness` use of the Gaze and the Lantern, `UnseenObjective`
   (still fails at Local Emergency), the bench toll.
5. Texts that teach today's rule are corrected where a natural power now behaves differently: `mission_hints.gd` (:50
   "A seen kill rings the bell", :72 "The town calls its bellkeeper", :127 Relic Run), the Sermon tour's line about four
   seen deaths, the legend. The builder greps hints, tours and the legend for "bell".

### 5.6 What the player sees

Top right, left of the stage label, in the same plate style:

```
                              4:57                 Calm    [##--------|]  Normal
                              4:31                 Uneasy  [#####-----|]  Concern
                              4:02                 A GOD!  [##########|]  Local Emergency
```

- A bar about 48 x 5 units with a tick at 40. Fill: dim, gold from Uneasy, red when known. A word beside it: `Calm`,
  `Uneasy`, `A GOD!`. Hidden while the value is 0 and the town does not know, so a quiet night's HUD is as clean as
  today. **[call]** The value is part of `Hud._signature()`.
- A thought over the nearest witness for about 2.5 s, as a `MapTag` label: at a sign that leaves the town calm
  `JUST A STORM` (lightning, storm), `FIRE!`, `EARTHQUAKE!`, `THE RIVER!`, `BAD AIR`; at a sign that leaves it uneasy
  `AGAIN?`; at the sign that makes it know `THIS IS NO ACCIDENT`. **[call]**
- Banners (the existing banner bar): `THE TOWN GROWS UNEASY` when the value first passes 40 (quiet banner, once per
  rise), `THE TOWN KNOWS: A GOD IS HERE` when it knows. The keeper's own banners follow as today.
- Sound: existing cues only (a `cit_shout` from the witness when the town turns uneasy). No new files.
- Legend panel: one entry for the gauge. Debug overlay (`behaviour_overlay.gd`): one line with the value, the state,
  the reason it knows, and the signs in memory.

### 5.7 Where it applies

Everywhere a `Crowd` lives: board missions, the campaign, Endless Night, the Hunts, the sandbox. Remembrance needs
nothing special.

## 6. Constraints

- Deterministic: no call on any random stream; the same run gives the same checksum twice.
- **Which runs may move.** A reference row may change only if, on the base commit, its run called the keeper at a
  district emergency made of explained incidents, or at a witnessed target kill of an explained kind, before the town
  would know by 5.4. Every other row must keep its checksum: a run with no natural power, or one whose keeper was never
  called by those two paths. Each moved row is explained by that, then re-recorded.
- Bots (`tools/dev/behaviour_check.gd`, `tools/dev/routes/`): because the rule only delays the keeper, policies written
  for today's rule (`GodT1.deaths_left()`, the routes that blight the Bell Tower so a seen death rings nothing) stay
  valid, only cautious. A policy is changed only if its gate gets worse; the opposition is never weakened.
- Gates: the god gates (Tier 1 pairs, five Hunts) and each touched board mission's gate are compared with a baseline
  taken on the base commit: no pair may be worse than its baseline row. Several gates are already red on the base
  (Prayers x Passage and x Decree, all five Hunt gates); those are not this work's to fix.
- Shared files (`crowd.gd`, `hud.gd`, `mission.gd`, `alarm_manager.gd`): hooks only. The Might gauge (branch
  `feat/might-gauge`, landing now) changes `hud.gd`, `rules.gd`, `mission.gd`; this work merges `feat/Develop-Main` in
  again once that has landed, before its own landing.
- Project rules: tests first; `##` doc comments; windowed scripted runs write only `user://test_*`; real screen captures
  at 1280x720 and 1920x1080 for the HUD; no PixelLab.

## 7. Testing

- `tests/test_suspicion.gd` (new): the arithmetic of 5.2 and 5.3 with the worked examples as cases; the latch; each of
  the five ways to know; no sign without a witness, under the Unseen Hour, or in a hushed town; night shortens the
  witness reach.
- `tests/test_alarm.gd`, `tests/test_bell.gd`: four lightning deaths in a district give Local Emergency, investigators
  and no keeper; then the town comes to know and the keeper goes; four plague deaths call him at once as today; three
  lightning deaths and one plague death do not (three explained, one unexplained), a fourth unexplained one does not
  either until four are unexplained or the town knows.
- The directors' suites: a seen target kill by Smite adds 40 and calls nobody; by Silent Doom calls the keeper as today.
- HUD: the gauge hidden at 0, shown above 0, its three states; the thought tag; both banners once.
- References, gates and FLOW as section 6 says; the whole suite at landing.

## 8. Left to the builder

- Where the thought tags enter the HUD's tag list (today `Hud` collects the director's, the Lantern's and the descent's
  tags, hud.gd:749-754).
- How `AssassinateDirector` learns the kill's kind at `_judge`, and how an incident learns its kind for 5.5.
- The exact place of the gauge when the status line is expanded with TAB, and at 640x360.
- `Suspicion`'s signals and the names of its methods.

## 9. Numbers to tune (all in one place, `Suspicion` and `ResponseProfile`)

`UNEASY_AT` 40, `KNOWN_AT` 100, `MEMORY` 60 s, `CALM_DELAY` 15 s, fade 0.4/s, the base of each look, the 0.5 for other
looks, `TARGET_SIGN` 40, `QUIET_SIGN_SIGHT` 5.0, `wary` per profile. Tuning order if a gate that passed on the base
fails: fix the bot's policy; then `wary`; then the bases. Any number that ends different from this document is reported
to the user before landing.
