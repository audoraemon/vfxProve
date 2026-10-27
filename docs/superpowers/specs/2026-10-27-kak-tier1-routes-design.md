# KAK: Tier 1 routes for every god type (design)

Date: 2026-10-27. Status: written for the controller (rulings D1-D9 in `.superpowers/sdd/t1routes/rulings.md`); the routes table is
the user's (2026-10-27). Branch `god/t1routes` off `feat/god-progression` `420a4e37`; lands on `feat/god-progression` only (D1).

Marks: **(user)** the user's decision; **(D<n>)** a controller ruling; **(my call)** the designer's choice, open to a ruling;
*tunable* a first guess tuned in the order given. Code names are today's (read at `420a4e37`).

## 0. The user's mission rules, applied to this milestone

The binding rules (memory `kak-mission-design-lessons`, D4) and what each means here:

| Rule | How this milestone keeps it |
|---|---|
| Every timed wait ≤ 60 s | The Lamb bolts at 1:00 at the latest (§2.2); the poor set out by 1:00 (§2.3); carters set out before their grain (§6.1). No new seal. |
| Doing nothing loses 3/3 | Each mission's `none` rows still lose: the Lamb's bolt runs him into the watch; the first walking poor reaches a watched door; carters still empty a granary. Every mission task reruns its `none` case. |
| An acting player idles ≤ 45 s | Each type's policy must act every ≤ 45 s. The long cooldowns (Mirrorfold 54, The Bell Lies 60, Pestilence 48, Thornwall 42) are paired with a second power that does real work between them; the pairs where that is not yet true are Problems (§12). |
| Chain pacing | No chain is changed: stars (stop + 30 s), collectors (death or stop + 45 s), grain (spoil + 45 s). A stop by the new rules starts the chain exactly as a kill does. |
| Opposition is work | Guards, watchmen, patrols, the watch and the Faithful stay where they are. New routes go round none of them for free: Blight and the plague need an unguarded granary (§6.3, §6.4, Decision 29's precedent); the debtors' mob needs the collector's guards away (§5.2). |
| No luck | No new rule reads street traffic. The Tax mob is the stop's own debtors, not a passing crowd (§5.2). Plague spread is chance: no route needs it (the cast's own victims count), and the one hazard it makes (the Lamb catching it) is the mission's own "he dies" loss, kept 8 away by the Death policy (§7, Problem 11). |
| No hidden losses | A carter who dies is replaced (§6.6), so no route leaves a granary unspoilable; every instant loss keeps its warning; every new stop has a banner. |
| The bell never loses outright | Untouched: Herald, watch and Gaze nights keep `MissionDef.lantern`; The Bell Lies only lies. |
| Every moving target tagged and edge-arrowed; tags count down | New movers get edge-arrowed tags: carters (§6), the bolting acolyte (§7), the walking poor (§8). New countdowns: the lie on the bellkeeper's tag, the Lamb's bolt, the carter's grain. |
| Every power open on every mission | Unchanged. The per-type gate (§9) restricts only the scripted player. |

## 1. What exists and what this adds

- The real tree's Tier 1 is fixed (D2): ruin smite+ember, death deathmark+pestilence, veil doom+blight, passage thorns+mirror,
  decree noleave+belllies, dominion whisper+discord. Spec 2026-10-26 §5.2: every type must win every Tier 1 mission with only its two.
- The five Tier 1 missions and their directors: The Warning on the board (`StarfallDirector`, three `WarningDirector`s), The Tax
  Collector (`TaxCollectorDirector` < `AssassinateDirector`), Spoiled Harvest (`HarvestDirector` < `RazeDirector`), The Lost Lamb
  (`LostLambDirector` < `EscortDirector`), First Prayers (`FirstPrayersDirector` < `MirasHouseDirector`). Each runs in Aldermere and,
  through its overrides file, in the Capital (v0.12).
- `behaviour_check --god=<type>:<tier>` (P1, C6) only checks a loadout today; this milestone gives it a per-type policy (§9).
- **Shared directors are shared.** `WarningDirector` also runs the campaign Warning, the Omen and (as `RingerDirector`) The Bell-Ringers;
  `AssassinateDirector` runs The Informer and The Bishop; `EscortDirector` The Prisoner and Exodus; `MirasHouseDirector` Mira's House and
  The Sermon. **Every new rule is opt-in**: a flag or an override that only the Tier 1 director sets, default off, so no other row moves (D6).

## 2. The three shared rules

### 2.1 Out of the walls (rule 1, user)

**Who:** a warning's carrier (the board Warning's watchman, messenger, relay or Herald), a tax collector, a carter. (The Lost Lamb's
acolyte already wins by going out; §7.2.)

**The walls:** the ring the mission is played in, `City.current().town()` — Aldermere `TOWN` `(-16, -16, 32, 32)`, the Capital's old
town `INNER` `(-24, -30, 42, 34)` (v0.12: every Tier 1 mission is played inside it).

**The rule (exact):** a tracked person whose `ground_pos` lies outside `town().grow(Walls.MARGIN)` while he is out of doors and alive
is **out of the walls**. *However* he got there counts: walking through a gate, whispered, frightened along a flight path, or set down
by a Mirrorfold's way out beyond the wall. A carter or collector who has never been inside does not count (none starts outside).
`Walls.MARGIN` = 0.5 *(tunable, 0.3-1.0; my call)*: past the wall's band (`WALL_T` 0.7 inside the edge) and a gate's passage
(the Main Gate ends at y 16.2).

**What it does:**
- He is **stopped for the night**: a warning dies (as an unseen kill does, `stopped_how = "out"`); a collector counts with the dead
  (state `OUT`); a carter's granary counts spoiled at once (razed), before or after its grain.
- His director lets him go (off duty, no tags, no errand, no relay to or from him) and sends him on to the nearest map exit
  (`City.current().exits()`); within 1.2 of it he is taken off the map (`crowd._field.remove`, `crowd.escape`). *(my call: "gone for
  the night" is seen; he never walks back into town.)*
- The chain starts from the second he went out, as from a death.
- Banners *(copy my call)*: `THE WARNING LEAVES TOWN`, `A COLLECTOR LEAVES TOWN - HIS TAXES ARE LOST`, `THE CARTER LEAVES TOWN - THE
  GRAIN ROTS`.

**One shared piece:** `Walls` (`src/game/mission/walls.gd`, static): `outside(at, city = null) -> bool`, `way_off(at) -> Vector2`
(nearest map exit) and the leaver bookkeeping on `MissionDirector` (`send_off(p)`, `_step_leaving()`), which no other director calls.

**In the Capital** the old town's river gates (`INNER_GATES[1..3]`) lead onto the bridges, still inside the outer ring: they count as
ways out of *the mission's* walls (Problem 9).

**Mirrorfold needs no change:** its way out has no reach limit and `Person.fold()` sets the walker down on walkable ground outside the
wall (fields, roads); he keeps meaning to go where he was going, and the next look finds him out of the walls. Checked in Task 1's
test (`_fold_outside`).

### 2.2 He bolts (rule 2, user) — The Lost Lamb

The acolyte hides at his fountain as today. He **bolts** — sets out for the west gate on his own — at the first of:
1. **a startle within `BOLT_REACH`** of him while he is free and out of doors: a loud power's danger landing (`Crowd.danger_landed`:
   Smite), a building catching fire (a structure that starts burning), a death (`enemy_killed`: anyone dying, of any cause), or his
   hiding place's fountain blighted (the fountain structure nearest `charge_start` turning `blighted`);
2. **`BOLT_AT` (1:00)**, if the god has not led him yet.

**Led** = whispered or drawn by a Wisp's lure at least once before he bolts. A led acolyte never bolts (so route A's whisper and route B's
Wisp play as they did); a startle after he was led does not start him either *(my call: the led charge is the player's)*.

**Bolting:** on duty for `exit_at` (through the gate) at `BOLT_PACE`, re-sent every look once back on his feet; he does not shelter from
a fright while bolting (he keeps his run; held fearless as a bound charge is, `BOUND_HOLD`). Seized: as today (marched to the Temple);
freed: he bolts on at once. A whisper or a lure while bolting ends the bolt: he holds where the god leaves him (today's rule) and is led.

**Doing nothing:** he bolts at 1:00, walks into the patrols or, at the latest, into the gate's watch (posts at the mouth, `SIGHT` 2.5;
the change clock starts only within 6 and runs 30 s), is seized and taken back: lost, 3/3.

### 2.3 They come to pray (rule 3, user) — First Prayers

From the start, the poor not yet Believers **walk to the shrine on their own, one at a time**:
- The k-th walker sets out at `POOR_OUT_AT[k]` or `POOR_CHAIN` after the one before him went in or was turned away, whichever is sooner.
  He is the unbelieving poor nearest the shrine who is alive, out of doors and free (not held by the god, not inside, not reporting).
- He walks on duty to the door. At the door he is **brought** (Mira's rules: a Faithful seeing the door turns him away and runs to
  report; otherwise he goes in; if another prays, he waits at the door, one at a time).
- Whispered, lured, confused or frightened, he is off his walk; back on his feet he takes it up again, unless the god brought him in.
  A turned-away walker goes home and goes to the back of the line.
- **Doing nothing loses:** the first walker's set-out puts him at the door as the market fills (1:15): the Faithful lining it see him, a
  report reaches the Temple, the Gaze fills. 3/3.
- Problem 1 explains why the walkers are timed into the windows rather than a standing door watch being added.

## 3. Shared powers: what changes, and what keeps other rows still

| Power | Route that needs it | Change to the power | How other missions' rows are kept |
|---|---|---|---|
| **Blight** | Harvest Veil: rots a full granary | **None.** `HarvestDirector` overrides the existing hooks `blight_target()`, `blight_takes()`, `blighted()`, `blight_words()` (v0.11.1's standard/mirror hook, used by The Heretic Hunt and The Lantern's Eye) | Only `HarvestDirector` answers; `BlightFx` is untouched, so no non-Tier 1 row can move (D6's last line) |
| **The Bell Lies, ALL IS WELL** | Warning Decree (the keeper ignores him), Prayers Decree | **None.** The directors read `Crowd.is_bell_lying()` (true for `LIE_TIME` 45 s after the lie's toll) | Read only by `WarningDirector` with `lie_stops` on (set by `StarfallDirector` only) and by `FirstPrayersDirector` |
| **The Bell Lies, CALL THE GUARD** | Harvest Decree (seize the cart), Tax Decree (draw the guards), Lamb Decree (draw the watch) | **None.** Tax and Lamb use today's compulsion (a compelled soldier is off his post and sees nothing). Harvest reads the cast's mode from the effect: a new read-only `Rules.last_fx()` | `last_fx()` is a getter on `Rules`; no caller exists before this milestone |
| **Leaving Is Prohibited** | Tax Decree (the mob), Lamb, Prayers, Warning (holds) | **None.** The Tax director keeps the cast's `NoLeaveFx` (`last_fx()`) and reads its `sealed` and `bound` | Read only by `TaxCollectorDirector` |
| **Mirrorfold** | Warning, Tax, Harvest Passage (out-points outside the walls); Lamb, Prayers | **None** (§2.1) | No director other than the five reads a fold |
| **Pestilence** | Harvest Death (plague reaching a carter) | **None.** `HarvestDirector` reads `Person.sick_left` | Read only by `HarvestDirector` |
| **Thornwall** | Prayers Passage (blocks sight) | **None.** `FirstPrayersDirector` overrides `_sees()` | The override is in the subclass; Mira's House and The Sermon keep the base |
| **Ember / fire** | Prayers Ruin (pulls the Faithful) | **None.** `FirstPrayersDirector` reads `crowd.fires.is_burning()` near its door | Subclass only |

Other shared code touched: `MissionDirector` (leaver bookkeeping, unused elsewhere), `Rules.last_fx()`, `TempleReport.drop()` (§8.5;
a new method nothing else calls), `AssassinateDirector` (`walls_stop`, state `OUT`, off by default), `WarningDirector` (`walls_stop`,
`lie_stops`, off by default). Each mission task proves the protected rows of its shared base still match (§10).

## 4. The Warning (the board's Starfall)

Today: three stars at 0:10, by 1:30 and by 3:00 (each no later than 30 s after the warning before was stopped); each star's watchman
stares 4 s then runs (on duty, 1.6 u/s) to the bellkeeper; told, the keeper rings; on this Herald night the toll turns the Lantern and the
keeper comes down as the Herald for the Temple. A warning dies only by an unseen kill; a seen one passes to the nearest witness.

### 4.1 New rules (StarfallDirector sets both on each WarningDirector; both default off)
- **W1 Out of the walls** (`walls_stop`): §2.1 for every carrier, at every phase (staring watchman, runner, relay, keeper, Herald). A
  relay witness standing outside the walls is out at once.
- **W2 The keeper who heard ALL IS WELL** (`lie_stops`, NEW, user): while `crowd.is_bell_lying()`, a carrier who reaches the keeper
  (`DELIVER_REACH`) is not believed: the warning dies (`stopped_how = "lie"`), the bell is not called, the carrier goes home (off duty).
  The same for a carrier who takes the rope with the keeper dead. On a Herald night after the toll the Herald's errand is the Temple:
  the lie does not stop a Herald *(my call: the Temple is not fooled)*. Banner `ALL IS WELL - THE KEEPER SENDS HIM HOME`.

### 4.2 Routes (D3)
| Type | Powers (mode) | What counts | Policy outline | Proven / new |
|---|---|---|---|---|
| Ruin | Smite, Ember | Unseen kill (no one within `DOOM_WITNESS` 2.0 but those the bolt takes) | Smite led half a step ahead (as tier1_b's `_tax_fall`); Ember a house beside his road ahead to draw the street to the fire (the town's responders) so the bolt falls unseen; a relay: again | New kit, old rule |
| Death | Death Mark, Pestilence | Unseen death | Death Mark during the stare at the post (he dies 10 s on, slowed to 0.6, ~6 u from the gate) where the street is clear; Pestilence on him when everyone within 2.0 is within its 1.2 and falls with him | **Proven** (B's Death Mark) |
| Veil | Silent Doom, Blight | Unseen kill | Doom where nobody else is within 2.0. Never Blight the tower (a silenced bell sends the warning to the Temple at once) | **Proven** (A's Doom) |
| Passage | Thornwall, Mirrorfold | W1 | Lay each way in 19-30 s ahead of its runner, far along his road, way out beyond the nearest wall; Thornwall across his street to lengthen a run (real delay) between mirrors | NEW (W1); tight, Problem 4 |
| Decree | Leaving Is Prohibited, The Bell Lies (ALL IS WELL) | W2 | ALL IS WELL so each delivery falls inside a lie; LIP pins a runner at his post (15 s) to hold him until the lie is up | NEW (W2); tight, Problem 5 |
| Dominion | Mind Whisper, Discord | W1 | Whisper him from his post through his gate to a spot outside within `REACH` 10; Discord holds him if a whisper is refused | NEW (W1) |

### 4.3 What the player sees
- Hint `warning` *(copy my call; must fit 3 lines of `Hud.HINT_W`)*: "Stop the messenger (gold): kill him with no one near (red), send him
  out of the walls, or let him find the bell lying."
- The BELLKEEPER tag reads `BELLKEEPER - ALL IS WELL m:ss` while the bell lies (the lie's seconds left, in mission seconds).
- Banners as §2.1 and W2. The results report adds `out` and `lies` counts beside `stopped` and `relays`.

### 4.4 Numbers
No mission number changes: `star_falls`, `stop_wait` 30 (not a knob: route B's idle is 40-44 against 45), `STARE` 4. `Walls.MARGIN`
0.5 *tunable*. Tuning order if a per-type gate misses: (1) the policy; (2) `Walls.MARGIN` (Passage, Dominion only); (3) a ruling
(Problems 4, 5).

## 5. The Tax Collector

Today: three collectors (2, 1, 1 guards at 0.6) set out at 0:35, by 1:35 and by 2:35 (or 45 s after the one before dies); 20 s indoors at
each debtor; then to the Citadel's gate (loss). A kill counts, seen or not; a seen one calls the bell (watch night: the toll turns the
Lantern). The counting-house alight empties (all run for the Citadel).

### 5.1 T1 Out of the walls (`AssassinateDirector.walls_stop`, set by TaxCollectorDirector only)
§2.1. The collector's state becomes `OUT` (appended to `State`, so the old values keep their numbers); `stopped()` = dead + out;
`all_fallen()` counts stopped (out is 0 with `walls_stop` off, so The Informer and The Bishop read as before); `out_at()` chains from his
stop; `_lost()` (a body gone = SAFE, a loss) never fires for one already `OUT`; his guards go back to their posts. The objective's label
becomes "Stop the collectors" and the goal "Stop the tax collector and his two deputies before the taxes reach the Citadel" (reason
`collector` unchanged).

### 5.2 T2 The debtors mob the collector (NEW, user; "weakest", built honestly)
A collector **bound** by Leaving Is Prohibited (in a sealed `NoLeaveFx`'s `bound`) within `MOB_DOOR_R` of the door of a debtor he has
visited tonight or is visiting, with **no guard of his** (alive, out of doors) within `MOB_GUARD_R` of him, for `MOB_AFTER` seconds, is
mobbed by that house's debtors: he dies (kind `&"mob"`, credited to `noleave`), judged **unseen** (the debtors raise no cry; the bell is
not called). Up to three lay citizens nearest that door are sent to stand round him for the mob (the sight of it; the kill does not depend
on them). Banner `THE DEBTORS MOB THE COLLECTOR`. *Problem 7: "in a crowd" as written would depend on street traffic.*
- His guards walk at 0.6 and stand at 1.0 round a door, so the mob needs them drawn off: The Bell Lies' CALL THE GUARD (compelled 20 s,
  off their target, `_tends()` false) first, then LIP as he comes out.

### 5.3 Routes (D3)
| Type | Powers | What counts | Policy outline | Proven / new |
|---|---|---|---|---|
| Ruin | Smite, Ember | Kill | B's Smite (led, unseen where it can; a last chance seen); Ember the counting-house to flush the last one hiding | **Proven** (B) |
| Death | Death Mark, Pestilence | Kill | Death Mark ≥ 10 s before his next door (a marked man indoors at the fuse lives); Pestilence on him with his guards within 1.2, so all fall together | New kit, old rule |
| Veil | Silent Doom, Blight | Kill | A's Doom | **Proven** (A) |
| Passage | Thornwall, Mirrorfold | T1 | A way in across his road between stops, way out beyond the nearest wall; Thornwall across his road to turn him onto the mirror's line or keep him in the street | NEW (T1) |
| Decree | LIP, The Bell Lies (CALL THE GUARD) | T2 | CALL THE GUARD on a spot ≥ 8 from his door as his visit runs out; LIP over the door as he comes out | NEW (T2) |
| Dominion | Mind Whisper, Discord | T1 | Whisper him to a spot beyond the wall within `REACH` (from the stops by the Main Gate, the postern and the east quarter; the west stop's way round is long); Discord holds him in the street while a whisper cools | NEW (T1) |

### 5.4 What the player sees
- Hint `tax_collector` *(my call)*: "Stop each collector (gold): kill him, unseen if you can (red), or send him out of the walls. A seen
  kill rings the bell." Other phases unchanged.
- While a LIP circle holds a collector at a debtor's door with a guard near, his tag reads `TAX COLLECTOR - GUARDED`, so the missing step
  is shown, not hidden.
- Banners as §2.1, T2.

### 5.5 Numbers
`MOB_DOOR_R` 3.0 (LIP's radius), `MOB_GUARD_R` 1.5, `MOB_AFTER` 3.0 — all *tunable*; schedule, visits, guards unchanged (A's and B's
gates hold on them). Tuning order: (1) policy; (2) `MOB_GUARD_R` 1.5 → 1.0; (3) `MOB_AFTER` 3 → 2; (4) a ruling.

## 6. Spoiled Harvest

Today: three granaries' grain at 1:00, by 2:00, by 3:00 (or 45 s after the one before is spoiled); when grain is in, a carter sets out
from the Citadel's gate and carries 5 loads to it (the last empties it: a loss). Two watchmen (2.8 apart) at each door beat out a fire in
3 s; a fallen one is replaced in 30 s. Spoiled = 10 s alight or fallen, once grain is in.

### 6.1 H0 Carters set out early (my call; Problem 2)
Each granary's carter sets out from the Citadel's gate `CARTER_LEAD` before its grain is due (`grain_due(i) − CARTER_LEAD`, at once if
that is past) and waits on duty at the granary's door until the grain is in; then he carts as today. Tag: `CARTER - GRAIN IN m:ss`
(blue, edge-arrowed) while he walks or waits, `CARTER - n LEFT` once he carts (today an unlabelled diamond).

### 6.2 H1 Out of the walls
§2.1: the carter out → his granary spoiled at once (razed, the chain starts).

### 6.3 H2 Plague reaching a carter spoils his granary (NEW, user)
A carter who falls sick (`sick_left > 0`: Pestilence's own victims, or the plague passed to him) spoils his granary at once — **if no
watchman of it stands on guard** at that moment (my call; Problem 3). Guarded, the watch turns the sick cart away: banner `THE WATCH
TURNS THE SICK CART AWAY` and nothing is spoiled (he dies of it and is replaced, H5). Spoiled: `THE PLAGUE SPOILS THE GRAIN`.

### 6.4 H3 Blight rots a full granary (NEW, user)
`HarvestDirector.blight_target(at)`: the centre of a granary not yet razed within `BlightFx.REACH` (1.0) of the aim. `blight_takes(at)`:
its grain is in and no watchman of it is on guard (the v0.11.1 guarded-standard precedent, Decision 29). Taken: the granary is razed;
words `BLIGHT - THE GRAIN ROTS`. Not taken: `NO GRAIN TO ROT YET` (empty) or `THEIR WATCH KEEPS IT` (guarded); no alarm (the base's
rule).

### 6.5 H4 The guard seize the cart (NEW, user; "weakest", built honestly)
The Bell Lies cast in CALL THE GUARD at `at` (read from `Rules.last_fx()`: `BellLiesFx.mode == "guard"`, its `origin`): once its first
called soldier stands within 0.8 of his ring spot, every carter alive and out of doors within `SEIZE_R` of `at` is seized: his granary
counts spoiled at once, he is marched off (off duty, sent home). Banner `THE GUARD SEIZE THE CART`. No watchman condition (Decree has no
power that moves a lay watchman). LIP over the carter holds him on the spot while the guard run there.

### 6.6 H5 A dead carter is replaced (my call; Problem 8)
A carter who dies (any death; a plague death after H2 has already spoiled the grain changes nothing) is replaced `RELIEF_AFTER` (30 s)
later from the Citadel's gate (`A NEW CARTER SETS OUT`); the loads stay as they were. Killing a carter is never a spoil (else every killer
has a two-minute route round the watchmen).

### 6.7 Routes (D3)
| Type | Powers | What counts | Policy outline | Proven / new |
|---|---|---|---|---|
| Ruin | Smite, Ember | Fire 10 s / fall | Smite each watchman (one bolt each; 2.8 apart) ≤ 30 s before the grain, Ember as it comes in | **Proven** (A's Ember) |
| Death | Death Mark, Pestilence | H2 | Death Mark both watchmen 10-30 s before (20 s cooldown), Pestilence on the carter once neither is on guard | NEW (H2) |
| Veil | Silent Doom, Blight | H3 | Doom both watchmen, Blight within 30 s once grain is in | NEW (H3) |
| Passage | Thornwall, Mirrorfold | H1 | A way in on the carter's road (to his door, or a load trip), way out beyond the wall; Thornwall across his road between mirrors | NEW (H1) |
| Decree | LIP, The Bell Lies (CALL THE GUARD) | H4 | LIP on the carter, then CALL THE GUARD on him | NEW (H4); idle, Problem 6 |
| Dominion | Mind Whisper, Discord | H1 | Whisper the carter to a spot beyond the nearest wall within `REACH`; from the north-east granary (21 u from the Side Gate) he walks round by it (~40 s); Discord holds him in between | NEW (H1) |

### 6.8 What the player sees
- Hint `spoiled_harvest` *(my call)*: "Spoil each granary (gold) before its carter (blue) empties it: burn it, or stop its carter. Its
  watchmen (red) guard it." `spoiled_harvest.empty` keeps its line; the H2/H3 refusals are the banners.
- Carter tags (§6.1); the strip's grain events unchanged.

### 6.9 Numbers
`CARTER_LEAD` 30 (*tunable* 20-40), `SEIZE_R` 2.5 (*tunable* 2.0-3.0); `grain_at`, `chain_after`, `load_count`, watchmen unchanged
(route A runs at 182 s against the 180 s floor: nothing may speed it). Tuning order: (1) policy; (2) `CARTER_LEAD`; (3) `SEIZE_R`;
(4) a ruling.

## 7. The Lost Lamb

Today: the acolyte holds where the god last left him (Mind Whisper, a Wisp); two patrols (2 each), the gate's watch (2 at the mouth,
1.4 apart; changes 30 s after he comes within 6, away 25 s, every 45 s) and two searchers from 2:30 seize him on sight (2.5); a seizer
marches him to the Temple (loss). He escapes within 1.2 of `exit_at`.

### 7.1 L1 He bolts (§2.2, LostLambDirector only; EscortDirector untouched)
Tags: `ACOLYTE - BOLTS IN m:ss` before (to `BOLT_AT`, mission seconds), `ACOLYTE - RUNNING` while bolting; the strip's event "He bolts
for the gate" at `BOLT_AT` (cancelled once led or bolted). Banner `HE BOLTS FOR THE WEST GATE`.

### 7.2 L2 Out of the walls
`_exit_reached()` (an existing hook) is also true outside the walls (§2.1): a fold past the wall is out, as the user's win is.
Problem 10: this makes the Passage route a one-mirror win.

### 7.3 Routes (D3)
| Type | Powers | Starts his run | Clears his way | Proven / new |
|---|---|---|---|---|
| Ruin | Smite, Ember | Smite (≥ 1.5 from him) or Ember on a house within `BOLT_REACH` | Smite each patrol pair at its centre (both within 0.6), the watch (two bolts), a seizer (frees him), searchers | NEW (L1) |
| Death | Death Mark, Pestilence | Death Mark a citizen within `BOLT_REACH` (dies 10 s on) | Death Mark patrolmen and the watch; Pestilence on a patrol pair ≥ `PLAGUE_CLEAR` (8) from him (the spread could reach him: a loss) | NEW (L1) |
| Veil | Silent Doom, Blight | Blight his fountain | Doom each patrol pair, the watch (one Doom at its midpoint takes both), a seizer | NEW (L1) |
| Passage | Thornwall, Mirrorfold | 1:00 | Thornwall across a patrol's beat ahead of him (from ~0:30, real work before the bolt); a way in on his road, way out near the gate | NEW (L1); Problem 10 |
| Decree | LIP, The Bell Lies (CALL THE GUARD) | 1:00 | LIP pins a patrol off his road (from ~0:30); CALL THE GUARD on a spot away from his road as he nears the gate: the watch and the nearest patrol run there 20 s and see nothing | NEW (L1) |
| Dominion | Mind Whisper, Discord | (led from the start: never bolts) | A's policy | **Proven** (A) |

### 7.4 What the player sees
- Hint `lost_lamb` *(my call)*: "Get the acolyte (blue) out by the west gate. Frightened, or at 1:00, he runs for it: clear the soldiers
  (red) from his way." New phase `lost_lamb.running`: "He runs for the west gate. Clear the patrols and the watch (red) ahead of him, or
  draw them off." Hints are per mission, not per type, so the plague hazard (Problem 11) is not in the copy; a plague that kills him is
  an ordinary death of the charge, already warned by `lost_lamb`'s lose line ("he dies").

### 7.5 Numbers
`BOLT_AT` 60 (*tunable*, ≤ 60 only), `BOLT_REACH` 6.0 (*tunable* 4-8), `BOLT_PACE` = `charge_pace` 0.385 (*tunable* to 0.6, the bolt
only), `PLAGUE_CLEAR` 8 (policy constant). Patrols, watch, searchers unchanged. Tuning order: (1) policy; (2) `BOLT_PACE`; (3)
`BOLT_REACH`; (4) `BOLT_AT` down, never up; (5) a ruling.

## 8. First Prayers

Today: lead three of the poor (8, south-west quarter) to the old well shrine unseen; one prays at a time (32 s). Six Faithful (3 clergy,
3 lay); at 1:15 the market fills (free Faithful line the door 40 s), at 2:30 the priests come (40 s). A Faithful seeing the door turns the
poor away and runs to report; a report delivered fills the Gaze (loss); a seen death adds 10; the toll adds 40.

### 8.1 F1 They come to pray (§2.3)
Tags: each walker `POOR - TO THE SHRINE` (gold, edge-arrowed); the strip's events "One of the poor sets out" at each `POOR_OUT_AT`
(moved forward with `timeline.expect()` when the chain is sooner). Banner `ONE OF THE POOR SETS OUT FOR THE SHRINE`.

### 8.2 F2 Fire pulls the Faithful (Ruin's route; NEW rule for D3's "Ember a building pulls the Faithful away")
A building burning within `FIRE_PULL` of the shrine's door pulls every Faithful lining the door and every free Faithful within
`FIRE_PULL` of it to the fire (on duty to a spot 1.5 off it) for as long as it burns; when it is out, a liner whose window is still open
goes back to his spot. Banner `THE FAITHFUL RUN TO THE FIRE`.

### 8.3 F3 Thornwall blocks sight (Passage)
A Faithful does not see the door when the straight line from him to it crosses a Thornwall segment (`role == &"thorns"`):
`FirstPrayersDirector._sees()` override.

### 8.4 F4 Mirrorfold brings a walker (Passage)
No new rule: a walker who folds keeps his goal (the door); a way out by the door brings him there at once.

### 8.5 F5 ALL IS WELL (Decree)
While `crowd.is_bell_lying()`: every liner is stood down at once (their window's line ends), no window's line forms (a window that comes
due during the lie forms when it ends, for the seconds it has left), and every running report is dropped (`TempleReport.drop()`: the
carrier goes back to his day; nothing is delivered). Banner `ALL IS WELL - THE FAITHFUL GO HOME`.

### 8.6 Routes (D3)
| Type | Powers | Clears the door | Proven / new |
|---|---|---|---|
| Ruin | Smite, Ember | Ember a house within `FIRE_PULL` as a line forms (a house burns ~13 s; Ember every 15 s); Smite a report's runner | NEW (F2) |
| Death | Death Mark, Pestilence | Death Mark the Faithful one by one from the start (six in all; each one fewer to line the door; seen +10); Pestilence on two liners within 1.2, or a runner | New kit, old rules |
| Veil | Silent Doom, Blight | Doom liners and runners unseen (B's filler, as the main act) | **Proven** (A/B's Doom) |
| Passage | Thornwall, Mirrorfold | Thornwall between the line and the door; a way in on a walker's road, way out by the door when it is clear | NEW (F3, F4) |
| Decree | LIP, The Bell Lies (ALL IS WELL) | ALL IS WELL at each window (1:15, 2:30: 75 s apart); LIP pins Faithful on their way to the door or a runner between | NEW (F5) |
| Dominion | Mind Whisper, Discord | A's policy | **Proven** (A) |

### 8.7 What the player sees
- Hint `first_prayers` *(my call)*: "The poor (gold) walk to the old well shrine, one at a time. Keep the Faithful (red) from its door:
  three must pray." `first_prayers.watched` unchanged.

### 8.8 Numbers
`POOR_OUT_AT` [60, 135, 200] (*tunable*; [0] must land the first arrival in the market window, so the `none` rows lose), `POOR_CHAIN` 35
(*tunable* 30-45), `FIRE_PULL` 6.0 (*tunable* 5-8). Windows, prayer, Faithful unchanged. Tuning order: (1) policy; (2) `POOR_CHAIN`;
(3) `POOR_OUT_AT[1..2]`; (4) `FIRE_PULL`; (5) a ruling. Route A's median (Aldermere 219, Capital 202) can only fall with walkers
helping: if it drops under 180, the first knob is `POOR_OUT_AT[1..2]` later.

## 9. The per-type gate (D5)

- **Command:** `bash tools/dev/gate.sh <scenario> --god=<type>:1` (`--board` for `warning`). `--god=<type>:1` with no `--route` drafts
  `GodTree.keys_for(type, 1)` and plays `tools/dev/routes/god_t1.gd`'s policy for that type and mission (§9 plumbing, Task 1).
- **Bar:** wins ≥ 2/3 seeds (D5); idle ≤ 45 s in every play run (D4); median reported, and for a tier mission (not `--board`) judged
  150-270 s like a route B *(my call; ruling needed)*. The mission's `none` case is run once per mission (`--with-none`) and must lose 3/3.
- **30 pairs:** six types × five missions, in Aldermere (Endless Night's town). In the Capital the same 30 run and are **reported**, not
  binding *(my call; ruling needed)*.
- **Proven vs new:** "proven" (D3) means the route's rule and main power already win a gate today (route A or B); its per-type policy is
  new and gated the same way. "New" means the rule is added here: it gets unit tests (RED then GREEN) before the policy is written.
- **A and B keep their results:** every existing route A, route B, toll and `none` gate of the five missions keeps its verdict (win/loss,
  PASS) in both towns; checksums may move (D6). If a new rule breaks one, its policy answers the rule first (as a player would); a rule is
  not bent for A or B.

## 10. References (D6)

- **May move** (re-recorded in the commit that moves them, the reason in the body): the 99 rows of the five missions — `tax_*`,
  `harvest_*`, `lamb_*`, `prayers_*` (with `tax_toll_*`, `prayers_toll_*`), `warning_b_play_*`, `starfall_toll_*`,
  `capital_{starfall,tax,harvest,lamb,prayers}_*`.
- **Must not move:** the other 187 rows (among them the campaign Warning's `warning_none|doom|whisper|discord|mix`, `warning_toll_*`,
  `ringers_*`, `night_b_*`, `informer_*`, `bishop_*`, `prisoner_*`, `exodus_*`, `miras_*`, `sermon_*`), `digest`
  `61267b7e90524d800bf1c3473a71146b`, `crowd_check` `-935602679`. Blight's granary target touches no structure-blight path, so no non-Tier
  1 row can move by it.
- **New:** 90 rows `god_<type>_<scenario>_play_<n>` (seeds 1-3, Aldermere), one TSV per mission `tools/dev/refs/god_t1_<scenario>.tsv`.

## 11. The title switch (D7)

Once the 30-pair gate passes: the title's rows become `Endless Night`, `Missions`, `Options`, `VFX Sandbox`, `Quit` (spec 2026-10-26 §3).
Endless Night from the title opens the slot select with the **real** tree (`GodTree.dev_fill` false); its Back returns to the title (from
the board's DEV ENDLESS it returns to the board, dev fill on, as today). The Lantern campaign leaves the title; its handler (`"campaign"`)
stays in `Game` for FLOW and a later change of mind; its code, missions and save sections stay. The board stays the test mode.

## 12. Problems found

1. **Rule 3 vs doing nothing loses.** The shrine's door is watched only in the two windows (1:15-1:55, 2:30-3:10); a walker arriving
   outside them prays unseen, so walkers on a free schedule could win a night with nothing done. **Fix:** the first walker is timed to
   arrive as the market fills (§2.3); later ones run on the chain. Rejected: a standing door watch (it would remake A's and B's nights).
2. **Spoiled Harvest: no early work for carter routes.** The carter appears only when the grain arrives (1:00), so Death, Decree,
   Passage and Dominion (and Veil, whose Blight needs grain) would first act at ≥ 1:00: idle > 45 s. **Fix:** H0, carters set out
   `CARTER_LEAD` (30 s) early and are targets on the road.
3. **Spoiled Harvest Death: Pestilence alone.** Its 48 s cooldown makes gaps ≥ 48 s and a ~130 s night (three casts). **Fix (my call):**
   the plague and Blight spoil only an unguarded granary (H2, H3), so Death Marks (Dooms) work the watchmen between casts — the opposition
   Ruin already works. This is a condition the user's table did not state.
4. **Warning Passage is tight.** Mirrorfold cools 54 s; a star's runner starts ~35 s after the last stop. Feasible only by laying each way
   in 19-30 s ahead and far along the runner's road (δ₂ + δ₃ ≥ 14 s, worked in Task 2). **Fallback (ruling):** an out-of-walls stop starts
   the next star's chain when he leaves the map (~8 s later), not when he passes the wall.
5. **Warning Decree is tight.** The lie holds 45 s per 60 s; deliveries ~45-55 s apart need LIP holds to fall inside lies; the first gap
   (to star 2) may exceed 45 s idle without a holding LIP. Policy work; no rule change proposed.
6. **Harvest Decree idle.** The Bell Lies' 60 s cooldown is the only spoiling act; LIP only times it, so the gap between seizures is
   ~55-60 s, over 45. **Options (ruling):** (a) accept a reported idle ≤ 60 s for this pair (the user's "weakest" route); (b) no shared
   change is possible (The Sermon's rows use The Bell Lies). I recommend (a).
7. **Tax Decree "in a crowd" is luck.** A crowd in the street is traffic. **Fix:** the stop's own debtors are the mob, at its door (§5.2).
8. **A dead carter blocks a granary for good** (today: not replaced; only fire can then spoil it) — a hidden loss for every non-fire
   type. **Fix:** H5, replaced after 30 s.
9. **Capital river gates.** Out through a river gate is onto a bridge, still in the city. **Proposal:** it counts (the mission's walls
   are the old town's), stated in the hint's words only as "out of the walls".
10. **Lost Lamb Passage is a one-mirror win.** Once he bolts at 1:00, a way out past the gate lands him out (L2): a ~70-90 s night,
    under the 150 s band. **Options (ruling):** (a) one of the two watchmen stands just outside the gate on the road (posts
    `(2.7, 16.8)` and the inner `(2.7, 14.6)`; Capital likewise), so a way out past the gate lands in his sight unless the watch is
    changed or drawn off — A and B pass the gate during the change, so they should hold; (b) accept and report. I recommend (a).
11. **Plague is chance.** Spread (`SPREAD_CHANCE` 0.3) is seeded but luck to a player: no route needs it (casts count by their own
    victims), and the Lamb policy keeps casts 8 from him. Noted, not fixed.
12. **Tax Death Mark indoors.** A marked collector who goes indoors before the fuse lives (Death Mark's rule): the policy marks him
    ≥ 10 s before his next door. Noted.
13. **Lamb watch geometry.** The two watchmen stand 1.4 apart: one Silent Doom at the midpoint takes both (against "spread more than two
    Doom radii"). Existing; not changed here (A and B are tuned on it).

## 13. Rulings needed before Task 1
- R-a: the per-type bar (idle binding; median 150-270 judged for tier missions; Capital reported) — §9.
- R-b: Problems 2, 3, 8 (H0 lead, the guarded condition, H5) — §6.
- R-c: Problem 6 (Decree × Harvest idle) and Problem 10 (Lamb outer post).
- R-d: Problem 7's debtors and §2.1's "walks off and leaves the map" (my calls).
