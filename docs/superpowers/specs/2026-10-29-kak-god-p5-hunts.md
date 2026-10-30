# KAK god P5: The Lantern Hunts (mission spec)

Date: 2026-10-29. Status: **the five Hunt sketches and eight answers approved by the user 2026-10-29**; this spec's open issues (§9)
answered by the user 2026-10-29: all nine recommended answers approved. Branch `god/p5-hunts` (from `feat/god-progression` `f130d4f5`: P3 First Taste + Tier 1 routes; tag `kak-god-t1r`).
Parent spec: `2026-10-26-kak-god-progression-design.md` (cited as §n). As shipped: `docs/KAK_God_P2_Summary.md` / `_Rulings.md` (the
Hunt draw, stand-ins, seal, Hunt copy), `docs/KAK_God_P3_Summary.md` / `_Rulings.md`, `docs/KAK_God_T1_Routes_Summary.md` /
`docs/KAK_God_T1R_Rulings.md` (the three shared Tier 1 rules, `god_gate.sh`, D10, D38).

P5 builds the five real Lantern Hunts (§10.2) that replace P2's stand-ins. Each is its own mission, a subclass of the existing
type's director, with new places and **one Hunt-only rule**: the Lantern comes for the god's own people. Eclipse is out of P5
(answer 8). Numbers marked *fg* are first guesses, tuned with the scripted players (§7). Coordinates are Aldermere ground units,
snapped to walkable ground by the director (`_walkable`). Copy marked *(my call)* may be rewritten by the user.

## 0. Rules every Hunt must pass (§13, memory `kak-mission-design-lessons`, the user's standing rules)

- **No waiting:** every timed wait 60 s at most; doing nothing loses (none loses 3/3); an acting player idles 45 s at most.
- **Chain pacing:** the next item comes at its time, or no more than 45 s after the one before is done. Three items give about
  150 s, so each Hunt has four items or real work per item, for a 180-240 s median.
- **Opposition is work:** guards, crews, escorts and mates stand more than two Silent Doom radii apart (`2 x SilentDoom.RADIUS` =
  1.6) **from each other**, so one strike never clears two of them. The rule binds between opposition members only: a target and his
  own guard, mate or escort may stand closer (0.9-1.5), and one Doom between them takes both.
- **No luck:** no success and no loss depends on street traffic. Only the director's own people carry word, seize, escort or march.
- **No hidden losses:** the director's people are held through an evacuation (`MissionDirector._hold_all`); anyone whose death
  loses is tagged DO NOT KILL; every instant loss is warned plainly with room to act; the winning strike never also loses
  (objectives are checked win first).
- **The bell never loses outright:** every Hunt sets `MissionDef.lantern`; a toll turns the Lantern (clock x1.5, x2.0 burning,
  the Bearer resets it); on the Gaze Hunt the toll adds `LanternWatch.GAZE_TOLL` (40) to the Gaze.
- **Every power open:** the Endless draft (learned abilities, seals apply). No pools.
- **Clarity:** every moving target edge-arrowed; tags count down like the strip; plates and camera spots clear of the HUD stack,
  strip and slots.
- **Freed bodies:** people are looped as `for v: Variant in ...` and checked `is_instance_valid()` / alive before any cast or order;
  filter lambdas untyped.
- **Where:** every Hunt is in Aldermere (Endless Night's town). No PixelLab: text, drawn shapes, existing icons. User-facing copy
  says **Might**.
- **Branch rules:** land on `feat/god-progression` only, never merge into or push `feat/Develop-Main`, tag `kak-god-p5` locally,
  push only with the user's yes. FLOW and the bench alone on a quiet machine. Never stop or kill a process this session did not
  launch. Never edit `GodTree.TABLE` or `GodTreeDev.TABLE`.
- **References:** no existing row of `tools/dev/refs/*.tsv` (403), no `digest` (`61267b7e90524d800bf1c3473a71146b`) and no
  `crowd_check` (`-935602679`) may move. Base directors are not edited, but for H11's same-valued `tune_` vars in `ExodusDirector`,
  `RingerDirector` and `BellRingersDirector` (their references rerun); `EscortDirector`, `WarningDirector`, `AssassinateDirector` and
  `HuntDirector` are not touched at all. A Hunt subclass never redeclares a parent's const name (H12).

## 1. The Hunts as a whole

| Tier | Id | Title (§10.2) | Built on | Its own rule | Lantern |
|---|---|---|---|---|---|
| 1 Whisper | `hide_faithful` | Hide the faithful | `ExodusDirector` (Escort, many charges) | The Inquisition searches house by house | watch |
| 2 Omen | `silence_witness` | Silence the witness | `BellRingersDirector` + `RingerDirector` (Intercept) | Only his own mates carry the word on | watch |
| 3 Wrath | `expel_inquisitor` | Expel the inquisitor | `AssassinateDirector` | Three frights drive the captain out | watch |
| 4 Reckoning | `break_hunt` | Break the hunt | `HuntDirector` (Hunt type) | The standards march; an escort takes one up | watch |
| 5 Ascendance | `face_halcyon` | Face Halcyon | `ExodusDirector` (Escort, its own Gaze) | Freed the moment his escort breaks | gaze |

Each is distinct from the board night of its type (answer 1): Lost Lamb / Exodus lead one charge or wait-and-lead households by
the god's hand; Bell Ringers' relay takes any witness and rings the bell; the Informer and Heretic Hunt captains are found or
hunted, never frightened out; Heretic Hunt's standards are planted; Heart of Faith razes and kills.

**Shared across the five (R1-R10):**
- **The draw.** The stand-ins are gone: `GodNight.hunt_for()` returns the god tier's own Hunt (the table above), with P2's titles
  and plates unchanged. A Hunt is played only at its own tier. The stand-in board missions and their references are untouched
  (answer 5); `TierBook.board()`'s `at_tier` stays (P2's tests) but nothing in the god code calls it.
- **The def.** A new `HuntBook` (`src/game/god/hunt_book.gd`, as `RiteBook`) holds the five rows (tier, id, title, plate). Each
  Hunt's frame is a `MissionBook` function on its tier's frame (`_tier1()`..`_tier5()`: readiness, slots, Might, clock), with
  `unaware_town` added at readiness 1 as `TierBook.board()` does. `GodNight.def_for()` builds a Hunt from that frame with the god's
  slots, Might, draft pool, gifts and the tier's clock plus the Faith clock (P3-3's shape).
- **The save.** `GodSlot.read()` keeps a Hunt id in `in_night` (a game closed mid-Hunt is still a lost Hunt) and in
  `last_mission`. No new key; `VERSION` stays 1.
- **Results unchanged (answer 5).** Won: Notice 0%, `50 x tier` Faith, Divine Power as any night. Lost or abandoned: the
  most-carried ability sealed 3 nights, Notice 50%. P2-6 to P2-10 and F4-F6 hold with the real ids.
- **The Descent stays (open issue 4).** A Hunt hears the tier's wishes, banks believers and has the ASCEND phase, as the stand-ins
  did: `Mission.has_descent()` is true for a Hunt id on a board night. The wish draw never picks the director's people.
- **Screens.** Not on the tier tabs (answer 6). Prepare's Hunt rows (HUNT, WIN, LOSE, IF WON, IF LOST), the hub's Hunt line, the
  results' `Lantern Hunt: <title>  -  <tier>` and the pause stake stay P2's; WIN and LOSE now read the real Hunt's `goal` and
  `lose`, each no longer than the Informer's (91 and 96 characters), proven by P2's `_prepare_hunt_fits` at tiers 1-5.
- **The results' title line** (`ResultsScreen.ACT_TITLES`) gets each Hunt's won and lost reasons, so a won Hunt never reads
  "THE CITY HAS FALLEN" nor a lost one "MANIFESTATION ENDED" *(my call)*: `faithful_out` THE FAITHFUL ARE HIDDEN, `faithful_lost` THE
  INQUISITION TAKES THEM; `witnesses` THE WITNESSES ARE SILENT, `word` WORD REACHES THE TEMPLE; `expelled` THE INQUISITOR IS GONE,
  `captain_safe` THE CAPTAIN REACHES THE CITADEL; `standards` THE STANDARDS ARE BROKEN, `houses` THE HUNT TAKES THEIR HOUSES; `freed`
  THE PYRE STAYS COLD, `burned` THE PYRE BURNS. Dawn and the Gaze keep their titles.
- **The DEV tab (answer 6: a card per Hunt, as the rite's).** Its first row is unchanged (the sandbox, the towns' missions, the rite
  last), so every existing pin holds. The five Hunts are a **second row** of compact cards under it (title only, `UiTheme.SIZE_SMALL`,
  at most two lines), with the board's hint moved below them on the DEV tab only. A card's label is `"<title> (Hunt)"` when it fits its
  card in two lines, else the title alone (measured with `UiTheme.width`). `MissionBook.is_dev()` is true for them (every power open on
  the board).

## 2. Hunt 1: Hide the faithful (Tier 1, Escort)

`HideFaithfulDirector extends ExodusDirector`. Plate (P2): "Lead your believers out before the inquisitors reach them".
Built on the Tier 1 routes' shared rules where they apply (answer 7): **out of the walls** (a believer outside the walls is out)
and **he bolts** (only Dominion can move a man at Tier 1, so the households walk out on their own, as the Lost Lamb's acolyte does).

| Part | Rule |
|---|---|
| Brief | "The Inquisition searches house by house." / "Lead your believers out before it reaches them." *(my call)* |
| Goal / label / lose | "Lead five of your six believers out of the walls before the Inquisition takes them" / "The faithful are hidden" / "Two believers are taken or killed, or dawn comes" |
| Frame | `_tier1`: Unaware town (postern barred), clock 5:00, `lantern = watch`. Objectives `[EscortObjective("Lead them out", "faithful_out", "faithful_taken", "faithful_dead", 5), Dawn]`: with a need above 1 the objective FAILS only through `lost_reason()`, which returns `"faithful_lost"` (the taken/dead strings are never used). |
| Households | Two households of three believers each (6 in all, 5 needed). Each house: the dwelling nearest its point whose door the street reaches, quiet (no beat or post within `QUIET` 3.5 of the door), stone tonight (`ExodusDirector._quiet_house`). Believers: the 3 lay citizens nearest the door, inside until their time. North-west household *fg* (-11.0, -1.5), bound for the Main Gate; north household *fg* (5.5, -12.0), bound for the Side Gate. Each road 25-32 units of street. |
| Coming out | Household 1 at `OUT_AT[0]` 0:15 *fg*. Household 2 at the soonest of `OUT_AT[1]` 1:50 *fg*, `CHAIN` 45 s after household 1 is done (each of its three out, taken or dead), and `SLIP` 30 s *fg* before the search reaches its house. Banner `THE NORTH-WEST HOUSEHOLD SLIPS OUT`. |
| The walk (shared rule 2) | Out, a household walks itself in file behind its lamp-bearer (Exodus's file) to its gate's way out at `BELIEVER_PACE` 0.45 *fg*: past fear and deaf to the evacuation, as the bolting acolyte. A Mind Whisper on a believer sends him where the god chooses; after its linger he walks on to the nearest way out from there and his file follows the lamp. |
| Out (shared rule 1) | A believer anywhere out of the walls (`Walls.outside`) is out: through the Main or Side Gate, or set down past a wall by a Mirrorfold ("into the forest"). He is sent off the map and counted. Banner `A BELIEVER IS OUT  n/5`. Each look judges the watch's sight **before** the out check (T1R PF2's order): a believer set down within `SIGHT` of an outer post (outside the walls) is seen first. Neither shared rule is reusable code for an Exodus subclass (the bolt lives in `LostLambDirector`, the Escort type has no walls rule): Hunt 1 builds both. |
| The watch | Soldiers (as the Lost Lamb's, so The Bell Lies' CALL THE GUARD answers): 2 at each gate, the Main Gate's at the Lamb's posts (2.7, 14.6) and (2.7, 16.8), the Side Gate's at (14.6, 9.0) and (16.8, 9.0); 2 patrols of 2 on the Lamb's beats (the south street, the market street), its two walking 1.8 apart (not the Escort type's 0.5 ring). Seize on sight (`SIGHT` 2.5). **Not replaced** (Exodus's lay gate reliefs are off). |
| **The Hunt's rule: the search** | Two inquisitors (lay citizens made Inquisition, from the Temple's door at 0:00) visit `SEARCH_LIST` 6 *fg* houses in a fixed order, 4 empty dwellings and the two households' houses (household 1's second, household 2's last), standing `SEARCH_STOP` 6 s *fg* at each door, walking 1.8 apart. Each listed house's tag counts down to their arrival: blue for a household's, grey for the others. Reaching an emptied household's house they take up its trail (banner `THE INQUISITION FINDS THE TRAIL`): they walk after its lamp and seize on sight; when that household is done they go on down the list. Because of `SLIP`, the search never finds a household still inside. An inquisitor killed is replaced `RELIEF_AFTER` 30 s later from the Temple's door, at most `RELIEFS` 2 a night; held (a law, a whisper, Discord) or frightened, one stops. |
| Seized | Marched to the Temple's door (Exodus's seizure, about 20-30 s): tag `SEIZED - TEMPLE IN 0:24`, banner `A BELIEVER IS SEIZED - FREE HIM BEFORE THE TEMPLE`. The seizer felled, frightened, held or turned lets him go where he stands; he walks on. Delivered, he is taken: lost, not an instant loss (answer: "a seized believer is lost"). |
| Lose | Taken plus dead reach 2 (too few left to make five). After the first loss: banner `ONE BELIEVER LOST - ONE MORE AND THE HUNT FAILS`, and every believer's tag gains `DO NOT KILL`. |
| Tags | Lamp `BELIEVER - MAIN GATE IN 0:48` (blue, edge, eta); followers `BELIEVER` (blue, edge); waiting house `OUT IN 0:30`; listed houses `SEARCH IN 0:42`; inquisitors `INQUISITOR` (red, edge); watch and patrols `WATCH` (red; patrols edge). Strip rows: "The search reaches <household>", "The <household> comes out". |
| Hints *(my call)* | `hide_faithful`: "Your believers (blue) walk out by themselves. Clear the watch (red) from their road to the gate." `.trail`: "The Inquisition found the trail: keep its searchers off the household." `.seized`: "A believer is seized: strike his seizer before he reaches the Temple." |
| Overrides | `_plan()` (2 households, 2 gates), the base's `tune_` vars set in `setup()` from Hunt 1's own consts (H11, H12: no gate shuts, no hounds, 3 a household, need 5), `_watchman()`, `_appoint_watch()`/`_appoint_patrol()` (soldiers), `_post_to()` and `_takes_post()` re-implemented for soldiers (EscortDirector's `send_to_post` way: Exodus's are for lay watchmen and a subclass cannot reach past them), `_step_patrols()` and the patrols' first placement (1.8 apart), `_relieve_watch()` (a no-op: the watch is not replaced), `_come_out()` (no "The Temple sends searchers" strip row), `_step_free()` (the self-walk), `_exit_reached()` (out of the walls, after the sight check), `_chain()`/`out_due()` (`SLIP`), the searchers (the list, the trail, their reliefs) in place of the hounds, `lost_reason()`, `hud_line()`, `tags()`, `hint_phase()`, `strip_rows()`, `tour()`. No Gaze (Tier 1). |

**Median clear** *fg*: household 1 out 0:15, walks ~65 s plus the work, done about 1:35; household 2 out about 1:50 (or 2:20 by the
chain), done about 3:10. Longest timed wait: 45 s (the chain). Passage's mirror from the door may clear in ~85 s (open issue 5).

**Every type (Tier 1, the real tree; 2 keys):**

| Type | Route |
|---|---|
| Ruin (Smite, Ember) | Smite the patrol pair on the road ahead (two casts), then the gate's inner watchman as the lamp nears; Ember a house by the gate plaza to draw the outer one |
| Death (Death Mark, Pestilence) | Death Mark the gate's two watchmen 10 s before the lamp arrives; Pestilence on a patrol pair; mark an inquisitor on the trail |
| Veil (Silent Doom, Blight) | Doom each watchman and patrolman unseen (one Doom each: 1.8 apart); Blight the bell at 0:00 (no toll) |
| Passage (Thornwall, Mirrorfold) | Mirrorfold in on the household's road, out past the wall: the file folds out; Thornwall across the inquisitors' trail |
| Decree (Leaving Is Prohibited, The Bell Lies) | The law pins a patrol or the inquisitors off the road; CALL THE GUARD draws the gate watch as the file reaches the gate (T1R Lamb route) |
| Dominion (Mind Whisper, Discord) | Whisper the lamp past a watchman; Discord the gate watch; whisper an inquisitor back |

## 3. Hunt 2: Silence the witness (Tier 2, Intercept)

`SilenceWitnessDirector extends BellRingersDirector`; each witness a `WitnessDirector extends RingerDirector`. Plate (P2): "Stop
the runner carrying word of you to the Lantern".

| Part | Rule |
|---|---|
| Brief | "Four witnesses saw you work." / "Stop them before they reach the Temple." *(my call)* |
| Goal / label / lose | "Stop all four witnesses before word of you reaches the Temple" / "The witnesses are silent" / "A witness reaches the Temple, or dawn comes" |
| Frame | `_tier2`: Organized town, clock 5:30, `lantern = watch` (not herald: the toll only turns the Lantern; no second way to lose). Objectives `[WitnessObjective("Silence the witnesses", "witnesses", "Witnesses silenced"), Dawn]`: a `StarsObjective` that FAILS `word` when the director's `lost_reason()` says so. |
| Houses | One per district (answer: "one per district"), **in the order they send their witness: west *fg* (-11.5, 2.0), north-east (12.5, -11.0), south-west (-11.0, 12.5), south-east (12.5, 12.0)** (Ruling P5-T10-R1: the spec's first order was west, south-west, south-east, north-east; the move is an easier-direction change outside the §7 levers, accepted because the last witness is then the one 7 units from a gate and the north-east's short road comes before the Lantern burns the clock). Each the dwelling nearest its point whose door the street reaches, quiet (no beat within 3.5), 22-32 units of street from the Temple's door (0.8, -5.0) (measured: west 31.2, south-west 27.0, south-east 29.2; Aldermere has no north-east dwelling that far: the closest is 19.8), stone tonight. In place of Bell Ringers' wall towers. |
| People | Each house: a witness and his `MATES` 2, the lay citizens nearest the door, inside (hidden, untouchable) until their time. |
| Setting out | `OUT_AT` *fg* 0:20, 1:15, 2:10, 3:05; each next at its time or `CHAIN` 45 s after the witness before is stopped, whichever is sooner; a loud power within `POST_SIGHT` 6 of a waiting house sends it at once (Bell Ringers' rule, bannered). They stand `OUT_PAUSE` 3 s at the door, then the witness walks for the Temple's door at `WITNESS_PACE` 0.65 *fg* (the streets take 19-31 s at 1.04 units a second; the first draft's "35-50 s" was arithmetic that no street of Aldermere offers), his mates in file on the ground he walks (Ruling P5-T10-R3): the first `SW_HEEL_BEHIND` 1.6 back on his trail, the second `SW_HEEL_AHEAD` 1.0 ahead of him on the street, 2.6 apart and each within sight of him, so one Silent Doom never takes both (more than 1.6 apart on every walk but at the turns of the road, at most 5 % of the steps; measured by a stepped-body test on all four streets). They walk at twice the witness's pace so they keep up. |
| **The Hunt's rule: his mates carry it** | The witness's death seen by one of his own mates (alive, out of doors, within `Crowd.DOOM_WITNESS` 2.0, not held by the god) sends that mate on as the witness: banner `THE MATE RUNS ON`. Seen by anyone else, the word dies with him: the town's people never carry it (`_relay_witness()` picks only from `mates`). A mate's death changes nothing but the town's alarm. A whispered, confused or frightened witness drops the walk and takes it up again on his feet (WarningDirector's RESUMABLE). |
| Stopped | Dead with no mate to carry it on, or out of the walls (`walls_stop`, shared rule 1). Banner `THE WITNESS IS SILENT  n/4`. |
| Lose | A witness within `TempleReport.REACH` of the Temple's door: word reaches the Temple. Warned by his countdown tag, a strip row "Word reaches the Temple", and at 15 s out the banner `A WITNESS NEARS THE TEMPLE`. |
| Tags | Waiting house `WITNESS OUT IN 0:40` (orange); witness `WITNESS - TEMPLE IN 0:38` (gold, edge, eta); mates `MATE` (red, edge); the Temple's door `TEMPLE` (orange). |
| Hints *(my call)* | `silence_witness`: "A witness (gold) walks to the Temple with two mates (red). Kill him where his mates cannot see." `.relay`: "His mate saw it and runs on: stop him too." `.near`: "The witness nears the Temple: stop him now." |
| The bell, never the witness's | The witness tells no keeper and never takes the rope (B3 of the pre-flight): `_rings_himself()` stays **true** (RingerDirector's: so `_run()` never calls `_deliver()` near the living bellkeeper), `_take_rope()` is a **no-op** (he never rings, at the bell's foot or anywhere), `_give_back()` is a no-op (he never held the rope), and `_deliver()` is never reached. The loss is the witness's **own** check each step: the messenger alive, out of doors, within `TempleReport.REACH` (1.0) of `lantern_door()` -> word in (as `_herald_tick`). Other bell paths checked: `heralding()` and `on_toll()` are inert on a watch night; `lie_stops` and `gate_keeps` (T1R's W2, W3) stay false, so ALL IS WELL never "sends him home" and no gate key is used; `_call_off()` needs DELIVERED, which no witness reaches; the base's `hold_on_death` on the town's bell is kept (the bell is never a loss). The town's own bellkeeper may still ring after a seen death: that toll turns the Lantern. |
| Overrides | Coordinator (`_begin()` replaced, not `super()`, as it builds `RingerDirector.new()`): the houses, stone tonight, each `WitnessDirector.new()` with `tower` = its house, `own_keeper` = the bell's keeper and `claimed` = `claimed_besides.bind(i)`, the base's `tune_set_out_at` / `tune_chain_wait` set from Hunt 2's consts; `_send()`, `out_at()`, `tags()`, `hint_phase()`, `strip_rows()`, `report()`, `lost_reason()` (`"word"`). Witness: `_goal()` (the Temple's door), `_take_rope()`, `_give_back()` (no-ops), `step()` (super, then the word-in check), `_relay_witness()` (his own able mates only), `_judge()` (the base's, with the banner `THE MATE RUNS ON`), `witnesses()` (his mates only), `tags()` (no bellkeeper or bell-tower tag), `hint_phase()`, the base's `tune_mates` / `tune_mate_gap` / `tune_mate_side` / `tune_out_pause` set from Hunt 2's consts, the walk at `SW_WITNESS_PACE`, `walls_stop = true`. |

**Median clear** *fg*: four items, about 45 s apart: a quick player clears about 3:15, a slower one 3:50.

**Every type (Tier 2 dev kit; 3 slots, 8 Might):**

| Type | Plays | Route |
|---|---|---|
| Ruin | Smite, Heaven Splitter, Tornado | Heaven Splitter along the file: all three at once, nobody left to carry it; else Smite the witness and each mate who runs on (10 s cooldown) |
| Death | Death Mark, Pestilence, Glacial | Pestilence on the file; Glacial the three at once; Death Mark the witness once his mates are down |
| Veil | Silent Doom, Blight, Tsunami | Doom each mate (1.7 apart: one each), then the witness unseen; Blight the bell at 0:00 |
| Passage | Thornwall, Mirrorfold | Mirrorfold the file out past the wall (shared rule 1); Thornwall across the next street to hold a witness for the mirror's cooldown |
| Decree | Law, The Bell Lies, Magnify | **No route** (open issue 1): the law holds 15 s of every 20, The Bell Lies and Magnify stop no one; nothing stops a witness for good |
| Dominion | Mind Whisper, Discord, Madness Bloom | Whisper the witness out of the walls from the outer houses (one or two 10-unit hops); Discord the file; Madness Bloom on a mate |

## 4. Hunt 3: Expel the inquisitor (Tier 3, Assassinate)

`ExpelInquisitorDirector extends AssassinateDirector`, `walls_stop = true`. Plate (P2): "Drive out or kill the Lantern's captain
in the town".

| Part | Rule |
|---|---|
| Brief | "The Lantern's captain walks your town." / "Break his wardens, then kill him or drive him out." *(my call)* |
| Goal / label / lose | "Stop his three wardens, then kill the captain or drive him out of the town" / "The inquisitor is gone" / "The captain reaches the Citadel, or dawn comes" |
| Frame | `_tier3`: Prepared town, clock 6:00, `lantern = watch`. Objectives `[AssassinateObjective("Expel the inquisitor", "expelled", "captain_safe"), Dawn]`. |
| Wardens | 3 lantern-wardens (the resident nearest each round's first stop, made a warden for the night; gold tag), each with 1 guard (a soldier, the Assassinate type's default `_appoint_guards()` / `_tends()`, 0.9 off him; whisper and Discord hold soldiers as they do the Lamb's watch). Each waits inside his round's first house until his time, then walks a 4-stop round along the wall side of his quarter, `VISIT` 6 s *fg* indoors (untouchable) at each, round and round: the west quarter *fg* (-14.0, -3.0), (-14.0, 5.0), (-9.0, 5.0), (-9.0, -3.0); the south-east (11.0, 11.0), (14.0, 11.0), (14.0, 14.0), (11.0, 14.0); the north-east (11.0, -14.0), (14.0, -14.0), (14.0, -7.0), (11.0, -7.0). A warden has no safe place: he never escapes. |
| Chain | Wardens at `WARDEN_AT` 0:20, 1:10, 2:00 *fg*, each next at its time or `CHAIN` 45 s after the warden before is stopped. The captain at `CAPTAIN_AT` 3:10 *fg*, or 45 s after the third warden is stopped, whichever is sooner. |
| The captain | The cleric nearest the Temple's door, inside the Temple until his time, with 2 guards (soldiers 0.9 off him, 1.8 apart). His round: 4 stops, `VISIT` 6 s each (the bell tower's door, the market's south end, the Main Gate's plaza, the east quarter's well, *fg*), then his safe place, the Citadel's gate: about 115 s from the Temple's door to the Citadel. |
| Alarms | The Assassinate type's (`_alarm()`, acting only while he WALKS): a loud power within `alarm_reach` 4, a guard felled, or his mind turned afraid (any fright, the town's panic included: the god's work sets it going) send a target to hide `EI_HIDE` 12 s *fg*, then on with his round where he left it. **Where he hides (pre-flight B5):** the captain in the Temple; a warden in his own waiting house. With that house (or the Temple) down, burning or spent, he hides in the nearest standing, unburnt house of his round instead; **no target ever flees to the Citadel's gate**. The only way to the Citadel is the captain's walk at the end of his round, warned. |
| **The Hunt's rule: three frights** | Each `_alarm()` on the captain counts once (at most one count per `EI_FRIGHT_GAP` 8 s *fg*; alarms while he flees, hides or visits do not count, as the base's): tag `CAPTAIN - SHAKEN 1/3`. The first two send him to hide; the **third** sends him fleeing for the nearest gate, banner `THE CAPTAIN FLEES ALDERMERE`: he is stopped for the night at once (counted with the dead, as one out of the walls) and sent off the map. A route for gods without a killing power. |
| Stopped | Dead, out of the walls (shared rule 1), or (the captain) fled. |
| Win / lose | Win: all four stopped. Lose: the captain within reach of the Citadel's gate. Warned by his tag `CAPTAIN - CITADEL IN 1:12` once his last stop is done, a strip row "The captain reaches the Citadel" and, 20 s out, `THE CAPTAIN NEARS THE CITADEL`. No one's death loses: no DO NOT KILL. |
| Tags | Waiting warden `WARDEN OUT IN 0:30` (grey, place); warden `WARDEN` (gold, edge); guards `GUARD` (red, edge); captain `CAPTAIN - SHAKEN n/3` then the Citadel countdown (gold, edge); the Citadel's gate `CITADEL` (orange). |
| Hints *(my call)* | `expel_inquisitor`: "Stop each lantern-warden (gold): kill him, or put him out of the walls." `.captain`: "The captain walks his rounds: kill him, or frighten him three times." `.near`: "The captain nears the Citadel: stop him now." |
| Overrides | `_plan()` (the targets, rounds, the Temple as hideout, the Citadel's gate as `safe_at`, `walls_stop`), `_begin()` (super, then each warden moved into his own waiting house, untouchable, and given its door), `_set_out()` (a warden out of his own door), `_alarm()` (super, then the count and the third fright's flight), `_hide_goal()` (the captain: the Temple, else the nearest standing house of his round; a warden: his waiting house, else the nearest standing house of his round; never `safe_at`), `_arrive()` (fleeing: hide there; a warden past his last stop starts his round again; only the captain past his last stop walks to `safe_at`), `fleeing_to_safe()` (always false), `tags()`, `hint_phase()`, `strip_rows()`, `report()` (`frights`). |

**Median clear** *fg*: a fast killer waits up to 45 s for each warden and meets the captain at 3:10: about 3:20; a slower route
about 3:50. Doing nothing: the captain reaches the Citadel about 5:05 (dawn 6:00).

**Every type (Tier 3 dev kit; 3 slots, 10 Might):**

| Type | Plays | Route |
|---|---|---|
| Ruin | Smite, Heaven Splitter, Tornado | Smite each warden; three Smites near the captain (or one on him) |
| Death | Death Mark, Pestilence, Glacial | Death Mark each warden; Death Mark a captain's guard (a guard felled is a fright) or the captain |
| Veil | Silent Doom, Blight, Nuclear Nova | Doom the guard, then the warden unseen; Doom the captain's guards (two frights) and him |
| Passage | Thornwall, Mirrorfold | Mirrorfold each warden out past the wall (the rounds run on the wall side); the captain likewise at the Main Gate's plaza |
| Decree | Law, The Bell Lies, Magnify | **No route** (open issue 1): nothing kills, frightens or moves a man |
| Dominion | Mind Whisper, Discord, Madness Bloom | Whisper each warden out of the walls; Whisper the captain out from the gate plaza, or Madness Bloom by him (a guard felled in the frenzy frightens) |

## 5. Hunt 4: Break the hunt (Tier 4, Hunt type)

`BreakHuntDirector extends HuntDirector`, `has_head = false`. Plate (P2): "Smash their standards before they reach your believers".

| Part | Rule |
|---|---|
| Brief | "Four standards march on your believers' houses." / "Break every standard before they plant them." *(my call)* |
| Goal / label / lose | "Break the four standards before they take two of your believers' houses" / "The hunt is broken" / "Two believers' houses are taken, or dawn comes" |
| Frame | `_tier4`: God-Resistant town, clock 6:30, `lantern = watch`. Objectives `[HuntObjective("Break the hunt", "standards"), Dawn]`; `lost_word` / `lost_reason()` `houses`. |
| Houses | 3 believers' houses: the dwellings nearest (-4.0, 4.0), (7.0, 6.0), (-2.0, 12.5) *fg* whose door the street reaches, stone tonight; their believers inside, never seen. |
| Musters | 4, one per side, inside the walls, each 25-35 units of street from the nearest house: north *fg* (6.0, -13.5), west (-14.0, 0.0), east (14.0, -2.0), south-west (-11.0, 14.0). |
| Bearers | At each muster from 0:00: a standard-bearer (a lay citizen made one: a drawn pole and pennant over him, no art) and 2 escorts (the Hunt type's lay party, 0.9 to either side of him, 1.8 apart). Grey tag `RAISED IN 0:20` until his time. Escorts walk at his sides (their posts move with him, every look); a fallen escort is **not replaced** (each standard grows easier, as P3's Watch). |
| Chain | `BEARER_AT` 0:20, 1:10, 2:00, 2:50 *fg*; each next at its time or `CHAIN` 45 s after the standard before is broken. |
| The march | To the nearest untaken house's door on the walk grid at `BEARER_PACE` 0.5 *fg* (50-70 s). Held (a whisper, Discord, a law, a wall) he stops and takes it up again (HuntDirector's resume). |
| **The Hunt's rule: the standards march** | The standard is carried, not planted (no Structure: raising it appoints and marks the bearer, never breaks the step). A fright counts whoever set it going (the town's panic included). The bearer killed or frightened while **unguarded** (no escort within `guard_reach` 1.5 who is alive, out of doors, not held by the god, not frail, not afraid): the standard is broken, banner `THE STANDARD IS BROKEN  n/4`. While **guarded**, that escort takes it up and marches on as the bearer: banner `THE STANDARD IS TAKEN UP` (the Hunt type's "a guarded standard only shakes", on the move). The bearer out of the walls: broken (shared rule 1). |
| Taken | A bearer within `TAKE_REACH` 1.0 of a house's door plants the standard there: the house is taken (a setback), banner `A HOUSE IS TAKEN - ONE MORE AND THE HUNT IS LOST`. He stands planted at the door, still breakable; his standard still counts for the win. Later bearers march on the houses left. |
| Win / lose | Win: all four broken. Lose: two houses taken. Warned by each house's tag `BELIEVERS - STANDARD IN 0:40` (the nearest bearer's eta), a strip row "A standard reaches a house" and, 15 s out, `A STANDARD NEARS A HOUSE`. No DO NOT KILL (no death loses). |
| Tags | Bearer `STANDARD - HOUSE IN 0:42` (gold, edge, eta); escorts `ESCORT` (red, edge); houses (blue); musters (grey until raised). |
| Hints *(my call)* | `break_hunt`: "Standards (gold) march on your believers' houses (blue). Strike a bearer when no escort (red) stands by him." `.carried`: "An escort took up the standard: strike him too." `.taken`: "A house is taken: one more and the hunt has won." |
| Overrides (pre-flight B4: every path that assumes a Structure) | `_plan()` (4 steps from the musters, `has_head = false`, `lost_word`), `_raise(i)` (replaces the base's: appoint and mark the bearer, start the march, add the strip row; **never `_break()`**, no `damage_filter`, no `broken` signal), `_raise_standard()` (returns null and is never called by the override), `_guarding(i, g)` (distance to the bearer, not to `st.standard` or `st.spot`; adds not frail and not afraid), `_guarded()`, `_keep_party()` (posts beside the bearer each look, not the fixed `g.post`), `_relieve()` (a no-op), `_in_use()` / `_keep_held()` (the bearers too), `standard(i)` and `tags()` (the bearer's tag; no Structure tag), the march, the take-up, the break (the base's `_break(i)`: banner, release, the next step's time), `_found()` (two taken), `_quarry_point()`, `hint_phase()`, `strip_rows()`, `tour()`. Left unused, harmless with no Structure: `_shield()`, `_unguarded_blow()`, `_on_broken()`, `_step_of()`, `teardown()`'s loop over the empty `standards`. |

**Median clear** *fg*: four items, the chain at 45 s: about 3:10-3:50. Doing nothing: the first two bearers take two houses by
about 2:20.

**Every type (Tier 4 dev kit; 3 slots, 13 Might):**

| Type | Plays | Route |
|---|---|---|
| Ruin | Smite, Heaven Splitter, Orbital Strike | Heaven Splitter across the file; or Smite one escort, the other, then the bearer |
| Death | Death Mark, Pestilence, Glacial | Death Mark both escorts (frail at once: unguarded), then the bearer; Pestilence on the file |
| Veil | Silent Doom, Blight, Nuclear Nova | Doom each escort (one each), then the bearer |
| Passage | Thornwall, Mirrorfold | Mirrorfold the file out past the wall from its muster (all inside, near the walls); Thornwall delays the next |
| Decree | Law, The Bell Lies, Magnify | **No route** (open issue 1): the law and a call delay a bearer; nothing breaks a standard |
| Dominion | Mind Whisper, Discord, Turncoat | Turncoat an escort (he fights his own); Whisper the bearer out of the walls from the muster; Discord the file |

## 6. Hunt 5: Face Halcyon (Tier 5, the Gaze)

`FaceHalcyonDirector extends ExodusDirector` (the Escort type's seizure march, read backwards: each believer starts seized; its
own Gaze). Plate (P2): "His Gaze is on the whole town, and a seen death fills it".

| Part | Rule |
|---|---|
| Brief | "Halcyon's Gaze is on the whole town." / "Free your believers from the pyre unseen." *(my call)* |
| Goal / label / lose | "Free three of the four believers led to the pyre, unseen by Halcyon" / "The pyre stays cold" / "Two believers burn, Halcyon's Gaze fills, or dawn comes" |
| Frame | `_tier5`: God-Resistant town, clock 7:00, `lantern = gaze`. Objectives `[EscortObjective("Free the believers", "freed", "burned", "burned", 3), GazeObjective, Dawn]` (the win first). The director keeps its own Gaze: every seen death adds `GazeMeter.SEEN_DEATH` (10 of 100); the toll adds 40. |
| The pyre | Before the Temple's steps: `lantern_door() + (0, 2.5)` snapped; drawn as a stacked pile and a stake (no art); tag `PYRE` (orange). |
| Processions | 4, one per district house: west *fg* (-11.5, 2.0), north-east (12.5, -11.0), south-east (12.0, 12.0), south-west (-11.0, 12.5) (dwellings with a quiet door, 25-32 units of street from the pyre). Each: a believer (a lay citizen of the house, bound: deaf to whisper and fright, as The Prisoner) and `ESCORT` 3 *fg* soldiers (`_free_soldiers`: so CALL THE GUARD, Whisper and Discord work on them) on a ring 1.0 round him (1.7 apart). |
| Chain | `PROC_AT` 0:30, 1:35, 2:40, 3:45 *fg*, each next at its time or `CHAIN` 45 s after the one before is freed or burned. Each forms up at its door `FORM` 8 s *fg* (visible, strikable), then walks to the pyre at `PROC_PACE` 0.5 *fg* (50-64 s). |
| **The Hunt's rule: free him by breaking his escort** | The believer goes free the moment fewer than `ESCORT_HOLD` 2 *fg* of his escort are **able** by him (alive, out of doors, within `ESCORT_REACH` 1.6, not held by the god, not frail, not afraid): banner `A BELIEVER IS FREED  n/3`. Counted at once; he runs for the nearest way out and is sent off. A believer set down out of the walls is freed too (shared rule 1); an escort out of the walls is sent off. |
| The burning | Within `PYRE_REACH` 1.2 he is bound to the stake: `BURN` 12 s *fg*, a ring and `BURNING 0:12` on the pyre's tag; freeing still works until it ends. Burned: banner `A BELIEVER BURNS - ONE MORE AND THE HUNT IS LOST`. A believer the god kills counts as burned. |
| Win / lose | Win: three freed. Lose: two burned, or the Gaze full. Warned: each procession's tag `PYRE IN 0:40`, the strip row "A believer reaches the pyre", the burning ring, the HUD's Gaze meter. Believers' tags read `BELIEVER - DO NOT KILL` from the start (strikes land beside them). |
| Tags | Waiting house `PROCESSION IN 0:30` (grey); believer (blue, edge, DO NOT KILL); escorts `ESCORT` (red, edge); the leader's `PYRE IN 0:40` countdown. |
| Hints *(my call)* | `face_halcyon`: "Break a believer's escort (red) without a seen death: frighten, hold or turn them." `.pyre`: "A believer is at the pyre: break his escort before the fire takes him." `.gaze`: "Halcyon's Gaze is filling: free them quietly." |
| Overrides | `_plan()` (houses, the pyre, no gates, no watch, no patrols), the base's `tune_` vars set in `setup()` from Hunt 5's own consts (no gate shuts, no hounds, need 3), `_appoint_charges()` / `_place_charge()` (bound in the escort), **`_step_held()`** (replaces the Escort type's single-seizer march, which frees him the moment one `c.seizer` leaves DUTY and "takes" him at `return_to`: here the escort marches him to the pyre and he is freed only by the fewer-than-2-able rule), the free, the burning, `_relieve_watch()` (a no-op), `_come_out()` (no searchers' strip row), `lost_reason()` (`burned`), `hud_line()`, `tags()`, `hint_phase()`, `strip_rows()`, `tour()`. |

**Median clear** *fg*: three items needed; the chain and the forming-up give about 3:00-3:40 (at risk of short for Dominion's
one-Discord frees: open issue 5). Doing nothing: the first two burn by about 3:10.

**Every type (Tier 5 dev kit; 3 slots, 16 Might):**

| Type | Plays | Route |
|---|---|---|
| Ruin | Smite, Ember, Heaven Splitter | Smite a house beside the procession: the blow frightens the escort with no death (no Gaze); Ember a house on the route ahead. Risk: soldiers in a God-Resistant town rarely panic (tuning: §7) |
| Death | Death Mark, Pestilence, Glacial | Death Mark two escorts (frail at once: freed at once); each death later is seen (+10). Six seen deaths are 60: **no toll allowed** (open issue 7) |
| Veil | Silent Doom, Blight, Tsunami | Blight the bell at 0:00 (no toll all night); Doom one escort, then another (seen by the believer: +20 a procession, 60 in all) |
| Passage | Thornwall, Mirrorfold | Mirrorfold on the route, out past the wall: the procession folds out, he is free, the escort sent off; Thornwall holds the next for the cooldown |
| Decree | Law, The Bell Lies, Magnify | CALL THE GUARD on the procession itself: the call takes the soldiers nearest its click (up to its count), so his escort are compelled to stand there (held by the god: not able) and he is free; a call away from him would draw other soldiers first. The law holds a procession short of the pyre while The Bell Lies cools (60 s); Magnify a compulsion |
| Dominion | Mind Whisper, Discord, Rewrite Priority | Discord the procession (the escort forgets its task: held, he is free); Whisper an escort away |

## 7. The scripted check, the gate and the bar

- **Test gods (answer 2):** each type at the Hunt's own tier with the dev tree: `behaviour_check --scenario=<id> --case=play
  --seed=N --god=<type>:<tier> --dev-tree`. With the user's Tier 1 fill and `GodTreeDev`, the merged tree gives:

  | Type | Tier 1 | Tier 2 | Tier 3 | Tier 4 | Tier 5 |
  |---|---|---|---|---|---|
  | Ruin | Smite, Ember | Heaven Splitter, Tornado | Dragonfire, Gravity | Laser Grid, Orbital | Cinderfall, Judgement |
  | Death | Death Mark, Pestilence | Glacial, Solaris | - | - | - |
  | Veil | Silent Doom, Blight | Tsunami, Nova | - | - | - |
  | Passage | Thornwall, Mirrorfold | - | - | - | - |
  | Decree | Law, The Bell Lies | Magnify, Abolition | - | - | - |
  | Dominion | Mind Whisper, Discord | Madness Bloom (Discord is real Tier 1) | Oathbound, Command Echo | Turncoat, Hatred | Rewrite Priority, Mob Verdict |

  The scripted loadout is the floor a god of that tier has: at most 3 keys (no Faith slot bought), within `TierBook.dp(tier)`
  Might, every key at level 1, chosen per type (the "Plays" columns), from `GodTree.keys_for(type, tier)` at run time.
- **Tooling found missing (the plan adds it in `tools/dev`, never in the tables):** `behaviour_check` accepts `--god=<type>:<tier>`
  at tiers 1-5 and refuses keys outside the type, but plays a type's own policy only for the five Tier 1 board scenarios
  (`god_route`); the Hunts need their own arms and a per-type policy dispatcher (`tools/dev/routes/god_hunts.gd`, one file per
  Hunt, as `god_t1.gd`). `gate.sh` already takes `--god=<type>:<tier>` (route `god`, plays only, `--with-none` adds the none
  runs); `god_gate.sh` is Tier 1 only, so a `tools/dev/hunt_gate.sh` runs one Hunt's six types.
- **The gate, per Hunt:** `tools/dev/hunt_gate.sh` runs `bash tools/dev/gate.sh <id> --god=<type>:<tier> --extra='--dev-tree'
  [--with-none] --jobs=N` for one type (`--type=<type>`: its 3 seeds, plus the 3 none runs only with `--with-none`; each call under
  10 minutes) and saves the lines (`--save=<dir>`); `--judge=<dir>` reads the six saved types and prints the 6-row table and
  `hunt_gate <id> tier=N pass=K/6 none_lost=K/3 median=S PASS|FAIL` without running anything.
- **The bar (answers 3 and 4):** every type wins at least 2 of 3 seeds with idle at most 45 s (D38's real idle); none loses 3/3;
  the Hunt's median (all winning per-type runs pooled) is 180-240 s. A type's own median is reported, never judged (T1R D10).
- **Tuning order (each Hunt, at most three rounds, all six types rerun after each):** first make the type's policy work the
  opposition as a player would (aim ahead of the walk, answer escorts before they close). Then the opposition's numbers, easier
  when a type misses on wins, harder when the pooled median is under 180 s:
  - Hunt 1: `BELIEVER_PACE` 0.45 -> 0.5, the outer gate posts, `SEARCH_STOP` 6 -> 8, `OUT_AT[1]` 110 -> 90.
  - Hunt 2: `WITNESS_PACE` 0.65 -> 0.55, `OUT_PAUSE` 3 -> 5, `MATE_SIDE` 0.85 -> 1.0.
  - Hunt 3: `FRIGHT_GAP` 8 -> 6, `HIDE` 12 -> 18, the captain's guards 2 -> 1, `VISIT` 6 -> 8.
  - Hunt 4: `BEARER_PACE` 0.5 -> 0.45, `guard_reach` 1.5 -> 1.2, escorts 2 -> 1.
  - Hunt 5: `ESCORT` 3 -> 2 (two disabled still free him; one then suffices), `BURN` 12 -> 15, `FORM` 8 -> 12.
  The chain (45 s), every wait under 60 s and the Gaze's weights are rules, not knobs. (Number names in this spec are labels; in the
  code each is its Hunt's prefixed const, H12, e.g. `SW_WITNESS_PACE`, `HF_OUT_AT`.)
- **Done with concerns:** a type that still misses after three rounds, and the three Decree gaps (open issue 1, not tuned around),
  are reported with their numbers as `DONE_WITH_CONCERNS`; the controller takes them to the user.
- **References (answer 6, its second half: "their own reference rows"):** per Hunt, `<id>_none_1..3` and `<id>_<type>_play_1..3` for the six types (21 a Hunt, 105 in all;
  403 -> 508), recorded once after tuning, in their own commented blocks at the end of `tools/dev/refs/references.tsv`. A losing
  run is recorded as it falls.
- **Re-gate (answer 2):** when the user fills a tier of the real tree, its Hunt is gated again with the real keys (a follow-up,
  not P5).

## 8. Requirements

**Shared**
- R1. `HuntBook` holds the five rows (tier, id, title, plate); `has(id)`, `row(id)`, `at_tier(tier)`, `def(id)`, `ids()`.
- R2. `GodNight.hunt_for()` returns the god tier's real Hunt; `draw()` returns its id at Notice 100; no stand-in is drawn.
- R3. `GodNight.def_for()` builds a Hunt from its frame with the god's slots, Might, pool, gifts and clock plus Faith clock.
- R4. `GodSlot.read()` keeps a Hunt id in `in_night` and `last_mission`; a game closed mid-Hunt reads back as a lost Hunt.
- R5. Bank and forfeit of a Hunt are P2's exactly (Notice, Faith bonus, seal, Divine Power, no best, `before_hunt`).
- R6. A Hunt has the Descent on a board night (`Mission.has_descent`), its wishes never on the director's people.
- R7. The five are a second row of the DEV tab (row 1 unchanged, the rite last on it), labelled `"<title> (Hunt)"` or the title
  where that does not fit; never on a tier tab; `is_dev()` true.
- R8. Prepare, hub, results and pause Hunt copy is P2's; every Hunt's WIN and LOSE fit (`_prepare_hunt_fits`, tiers 1-5).
- R9. Each Hunt is on its tier's frame, in Aldermere, with `lantern` set and its objectives in win-first order.
- R10. No existing reference, `digest` or `crowd_check` moves; base directors unedited but for H11's `tune_` vars in three bases.
- R43. The results' title line names each Hunt's win and loss (§1); no Hunt ends on a generic title.

**Hunt 1** R11. Two households of three in quiet houses, out at their time, the chain (45 s) or `SLIP` before the search.
R12. Households walk out on their own (shared rule 2); a believer out of the walls is out (shared rule 1); five out wins.
R13. The search: two inquisitors visit the list in order, each listed house counting down; an emptied household's house gives
them its trail; replaced 30 s after a fall, at most 2. R14. The watch (soldiers) seizes on sight and marches to the Temple's
door; a delivered believer is lost; two lost loses, warned at the first, DO NOT KILL after it. R15. Tags, strip rows, banners
and hints as §2. R16. Every type has its route (§2 table).

**Hunt 2** R17. Four quiet district houses, a witness and two mates each, out on the chain (45 s) or a loud cast nearby.
R18. Only a witness's own mate who saw his death carries the word on; the town never does. R19. A witness dead with no mate to
carry it, or out of the walls, is stopped; four stopped wins. R20. A witness at the Temple's door loses, warned by tag, strip and
banner; `lantern = watch`. R21. Mates walk 1.7 apart; tags, banners, hints as §3.

**Hunt 3** R22. Three wardens on looping rounds along the walls, each with a guard; the chain (45 s). R23. The captain at his
time or 45 s after the third warden; his round, then the Citadel's gate. R24. Each alarm on the captain counts once per 8 s; the
third makes him flee and stops him at once. R25. Any target dead or out of the walls is stopped; all four stopped wins; the
captain at the Citadel loses, warned. R26. Tags, banners, hints as §4.

**Hunt 4** R27. Four bearers with two escorts each at four musters; the chain (45 s). R28. Bearers march on the nearest untaken
house. R29. Unguarded, a bearer's death or fright breaks the standard; guarded, an escort takes it up; out of the walls breaks
it. R30. A house reached is taken (a setback, the bearer planted and still breakable); two taken loses, warned. R31. Tags,
banners, hints as §5.

**Hunt 5** R32. Four processions (a bound believer, three soldier escorts 1.7 apart) on the chain (45 s), forming 8 s. R33. A
believer is freed the moment fewer than two of his escort are able, or out of the walls. R34. At the pyre he burns after 12 s
unless freed; two burned loses; a believer the god kills counts as burned; DO NOT KILL tags. R35. The director's own Gaze:
+10 a seen death, +40 a toll; full loses. R36. Tags, banners, hints as §6.

**Tools and proof** R37. `behaviour_check` plays each Hunt (`--scenario=<id>`, `none` / `play`, `--god=<type>:<tier>
--dev-tree`) through per-type policies in `tools/dev/routes/god_hunts.gd`; the loadout is at most 3 keys within the tier's
Might from `keys_for(type, tier)`, refused with a clear line if a key is missing. R38. `tools/dev/hunt_gate.sh` prints a
Hunt's six gates, its table, the pooled median and a verdict. R39. 105 new reference rows in five commented blocks; 508 in all.
R40. The bar of §7 per Hunt, Decree's gaps excepted only by the user. R41. Photographs: each Hunt's start and its rule in play,
Prepare's Hunt at tiers 1-5, the DEV tab. R42. FLOW's Lantern walk plays the real Tier 1 Hunt (its director, its name, lost
through the real ending) and passes alone.

## 9. Open issues (each with my recommended answer)

1. **Decree has no route on Hunts 2, 3 and 4.** Its kit at tiers 2-5 is Leaving Is Prohibited, The Bell Lies, Magnify and
   Abolition: nothing kills, frightens or moves a man out of the walls, and these three Hunts are won only by stopping people for
   good. (Hunt 5 works through CALL THE GUARD on soldier escorts; Hunt 1 through the T1R Lamb route.) *Recommend:* accept them as
   reported gaps in P5 (rows recorded as they fall, the gate `DONE_WITH_CONCERNS` for those three pairs), and re-gate when you
   fill Decree's Tiers 2-4. I add no Decree-only rule. If you want one now, say which (e.g. "a Lantern man held by a law, with
   none of his own able beside him for 5 s, is taken by the town", as T1R's debtors' mob) and it becomes its own small task.
2. **Passage plays only Thornwall and Mirrorfold at every tier**, so all its routes rest on shared rule 1 (out of the walls)
   applied to every Hunt's targets: believers out, witnesses and wardens and bearers stopped, a procession freed. *Recommend:*
   yes, apply rule 1 on all five Hunts, as written.
3. **Hunt 1's households walk out on their own** (shared rule 2 read for households) rather than by the god's hand alone, since
   at Tier 1 only Dominion can move a man. *Recommend:* yes.
4. **Hunts keep the Descent** (wishes at the tier's count, believers, ASCEND), as the stand-ins did, so "Divine Power as any
   night" holds. *Recommend:* yes. Cost: one line in `Mission.has_descent`; a test that no wish lands on the director's people.
   The alternative (no Descent, as a rite) pays only `MAIN_DP x tier` and the Faith bonus.
5. **"Board median" read as the pooled median** of each Hunt's winning per-type runs (180-240 s), each type's own reported (D10).
   Likely short pairs: Passage x Hide the faithful (~85 s, a mirror from the door), Ruin and Dominion on Hunts 3 and 5 (the chain
   floor). *Recommend:* accept the pooled reading; short pairs are reported, as T1R's were.
6. **The scripted loadout is the floor** (3 slots, the tier's Might, level 1), not what a well-fed god at that tier carries.
   *Recommend:* yes: a Hunt any god of that tier can win is the bar.
7. **Death on Face Halcyon:** every escort it kills is seen (+10 each); six for three frees is 60, and one toll on top fills the
   Gaze. *Recommend:* keep the Gaze's weights (they are the Hunt's point) and tune `ESCORT_HOLD` / `ESCORT` first; if Death still
   misses, report it.
8. **The captain's third fright wins at once** (he is sent off; there is no chase to the gate). *Recommend:* yes: no waiting,
   and the winning strike can never also lose.
9. **The plates stay P2's.** Tier 2's says "the runner" though four witnesses walk. *Recommend:* keep (you approved them); a
   one-word change to "the witnesses" is yours to ask for.

## 10. Rulings (my calls the sketches leave open)

| # | Ruling | Cost if wrong |
|---|---|---|
| H1 | `HuntBook` in `src/game/god/` (as `RiteBook`), the frames in `MissionBook` | A file move |
| H2 | A Hunt is played only at its own tier (`hunt_for` indexes by tier) | None: one tier per Hunt |
| H3 | Hunt 1 and 5 subclass `ExodusDirector` (households, file, seizure march, own Gaze) | Medium: overriding much of a 947-line base |
| H4 | Hunt 1's watch, Hunt 3's guards and Hunt 5's escorts are soldiers (CALL THE GUARD answers; whisper and Discord hold soldiers); Hunt 2's mates, Hunt 1's inquisitors and Hunt 4's escorts are lay (the bases' own kinds) | Small: Decree's one route |
| H5 | Hunt 2 uses `lantern = watch`, not herald (one way to lose) | Small: a Herald could be added |
| H6 | Hunt 3's frights are the Assassinate type's `_alarm()` calls (only while he walks), one per 8 s, overridden in the subclass: no base hook | Small: a constant |
| H7 | Hunt 4's taken house keeps its planted bearer breakable (it counts for the win) | Small: one condition |
| H8 | Hunt 5's freed believer counts at once and is sent off (no re-seizure) | Small: no chase to play |
| H9 | Scenario names are the mission ids; rows `<id>_none_<n>`, `<id>_<type>_play_<n>` | None |
| H10 | `TierBook.board(at_tier)` stays, unused by the god code | None |
| H11 | The bases read their numbers as constants (GDScript cannot shadow a parent's `const`), so one groundwork task gives the constants a Hunt changes, and that are read outside the `_plan()` / `_begin()` the Hunts replace, a same-valued instance var named `tune_<const in lower case>` (a prefix grep-checked unused in `src`, `tools` and `tests`), read in the const's place: Exodus `tune_out_at`, `tune_shut_at`, `tune_hounds`, `tune_per_house`, `tune_believer_pace`, `tune_need`, `tune_chain`, `tune_gate_watch`, `tune_quiet`, `tune_beats`; Ringer `tune_mates`, `tune_mate_gap`, `tune_mate_side`, `tune_out_pause`; BellRingers `tune_set_out_at`, `tune_chain_wait`. Byte-identical by default; those bases' references rerun. No other base edit | Medium: a base's references move if a read is missed (the rerun catches it) |
| H12 | A Hunt's own numbers are consts with its prefix (`HF_` Hunt 1, `SW_` 2, `EI_` 3, `BH_` 4, `FH_` 5; grep-checked unused), never a parent's const name; `setup()` copies them into the base's `tune_` vars (and the bases' existing vars: `patrol_size`, `chain`, `guard_reach`, `visit_seconds`, ...) | None |
| H13 | The DEV tab's Hunts are a second row; row 1 and its pins are unchanged | Small: layout only |
| H14 | A fright counts whoever set it going (Hunt 3's count, Hunt 4's break): town panic follows the god's own work | Small: a god-only filter later |
| H15 | Each Hunt's win and loss reasons get results titles (`ResultsScreen.ACT_TITLES`) | Copy only |
