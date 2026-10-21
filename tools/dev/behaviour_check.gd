extends SceneTree
## Scripted citizen-behaviour scenarios (v0.04), on the real mission at a fixed step (run with --fixed-fps 60), so
## each prints the same numbers every run. Each ends with a checksum of everyone's position and mind.
##
## usage: godot --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=calm
##   [--seconds=60] [--shots]
##   --case=toll (v0.11.2, a Lantern night, D32): the scripted player casts nothing until the bell tolls and the Lantern turns
##          (LanternWatch.tolled), then plays as `play` does -- the toll case's wins are judged, not its idle or median
##          (tools/dev/gate.sh --case=toll). A night's scenario function takes it through _scripted() or _acts() below.
##   calm   nothing cast: where citizens are, by kind of place, every 20 s; --shots saves captures at the end
##   strike after 20 s of calm, one Heaven Splitter in the market: intents by distance from it, over 30 s
##   escalate  three casts across town, 15 s apart: the alarm stage, the bell and everyone's intents every 5 s
##   gates  an evacuation called after 20 s of calm; --hazard puts a lasting danger on the Main Gate's approach at
##          5 s: evacuees by chosen exit, reroutes and queues over 40 s
##   bell   a strike in the west after 20 s of calm; --kill-keeper kills the bellkeeper first (quietly): the Bell
##          Tower's state, the stage and the alarm every 2 s over 30 s
##   fire   three houses set burning in the west quarter after 20 s of calm: fires, intensity, responders over 40 s
##   rite   (Prepared) City Emergency called after 20 s of calm: the Banishing Rite's state, the ring, its progress and
##          the manifestation's clock every 5 s over 90 s; --interrupt quietly kills three of the ring's clergy 10 s
##          into the chant (as Silent Doom will): the rite breaks, and the rest regather after the cooldown
##   engineers  (Prepared) City Emergency called after 20 s of calm, then a Heaven Splitter on the Citadel and the
##          bridge brought down: the Citadel's health, the bridge and each team's job every 5 s over 60 s
##   boats  (Prepared) an evacuation called after 20 s of calm: evacuees by chosen way out (south road, east road,
##          dock), the boats' state, load and crowd, and escapes, over 40 s; --cut-bridge brings the bridge down at 5 s
##   quiet  (loadout Silent Doom, Blight, Heaven Splitter, Nuclear Nova) after 20 s of calm: Silent Doom on the
##          bellkeeper, Blight on the Bell Tower and on the Main Gate, then at 30 s a Heaven Splitter in the west: the
##          alarm, the stage, the bell and the dead every 5 s over 60 s; --shots photographs the rot and the doom
##   opening  (v0.05 M7) stealth against loud: the same four loud casts from 30 s (Heaven Splitter in the west and the
##          north-west, Cinderfall Barrage, Heaven Splitter at the Citadel), and with --quiet a quiet opening first at 20 s
##          (Silent Doom on the bellkeeper, Blight on the Bell Tower and the Main Gate): the alarm, the stage, the bell
##          and the escapes every 5 s over 100 s, then the stage history
##   siege  (v0.05 M7) one scripted siege for comparing the difficulty tiers (--difficulty=): eight casts over 105 s
##          from 20 s (the first in the west, clear of the Bell Tower), then a report every 15 s to 150 s -- escapes, the Citadel, the clock, the rite, the boats, the
##          engineers ("fire" for a team at a fire), the fires burning, burned down and doused, the buildings down;
##          --burn (v0.08.2) makes it fire-heavy: BURN_HOUSES standing houses set burning at 30 s and again at 60 s
##          (the houses the casts leave whole only ever burn this way: every fire-kind hit kills a house outright)
##   clip   (v0.06) a power's preview clip for the draft, recorded in the town rather than the sandbox (whose dummy
##          troopers cannot be lured or confused): --power=<key> [--at=x,y] [--snap] [--seconds=s]
##          [--setup=rite|evac]; --snap aims at the citizen nearest --at (a whisper always does, and sends them
##          (2.2, -2.2) on, across the screen, the camera halfway: recorded with --at=0,11 --snap --seconds=8, the
##          open paving south of the market);
##          Prepared, the power in slot 1, cast after 20 s of calm (and the setup), PowerBook.CLIP_FRAMES frames over
##          its run into assets/clips/<key>.png
##   powers (v0.06) the new powers measured against doing without, Prepared, loadout wisp, thorns, discord,
##          pestilence; --case= one of:
##            plague / combo  Pestilence on the market crowd at 26 s, alone or after a Will-o'-Wisp there at 20 s:
##                            sick and dead every 10 s to 90 s
##            wall / nowall   an evacuation called at 20 s, and at 25 s a Thornwall across the Main Gate's mouth (or
##                            not): escapes by way out every 10 s to 60 s
##            discord / rite  City Emergency at 20 s, the rite chanting; at 35 s Discord on its ring (or not): the
##                            rite's state every 5 s to 90 s
##   soldiers (v0.07) each soldier role against doing without, --case= one of (Prepared):
##            each case first prints how many soldiers have the role (the "no" cases print 0: they prove themselves)
##            marshals / nomarshals  an evacuation called at 20 s: escapes by way out and the gates' queues every 10 s to 60 s
##            escort / noescort      the bellkeeper killed 3 s into its climb: the bell's state every 2 s to 50 s
##            rescue / norescue      the cathedral filled to its capacity, then it falls: trapped, saved, lost every 5 s to 80 s
##   judgement (v0.08) Last Judgement played greedily with the default loadout: from 5 s, each slot is cast the moment
##          its rules allow it, at the next of a fixed ring of targets closing on the Citadel; a report every 30 s,
##          then when the Citadel fell, the ending, escapes, buildings, the score and the DP left at the end (if any);
##          `--aim=rich` (v0.10 M5) aims each cast as Act III's caster does (_richest()); the start line prints the
##          loadout's cost against the campaign's Night 4 budget (12 DP, 6 slots).
##   miras  (v0.10 M2) Mira's House, --case=none (nothing cast) or play (whisper the grieving in when nobody of the
##          Faith watches the door; Discord on the nearest watcher).
##   lanterns  (v0.10 M3) Broken Lanterns, --case=none (nothing cast) or play (Heaven Splitter, Dragonfire Parade and
##          Silent Doom: lay the Splitter through two shrines where it can, else one, crossing the fewest people; doom
##          the called bellkeeper and the flame-bearer while a shrine drains; the Parade only when the Splitter would
##          come too late for dawn), or bonus (play, but the last shrine is struck only once ten kneel by it, or
##          when dawn would come too soon to wait). --seed= picks the town.
##   flame  (v0.10 M4) The Vigil Flame, --case=none (nothing cast) or play (Mind Whisper, Discord, Will-o'-Wisp: a wisp
##          to draw bystanders off the lantern, one Discord on the bearer and the acolytes, then Wren whispered to it;
##          with the flame, reading the beams' paths ahead, a wisp to draw off a beam coming at him, else a whisper
##          out of its way; Discord at the Temple's door in the last 20 s). --seed= picks the town.
##   feast  (v0.10 M5) the campaign's Night 3 alone, at its 4 slots and 10 DP: `--path=festival|procession` (the
##          Festival unless it says the Procession), `--bell=rang` for a town Night 1 warned, `--case=none` (nothing cast)
##          or `play` (the night's act policy, as `night --act2=play`). It drafts NIGHT_LOADOUTS[path], or `--loadout=`.
##          Prints the loadout's cost against the budget, then the result. --seed= picks the town.
##   warning (v0.08 M5) The Warning played against its messenger, one case per Authority, --case= one of:
##            none       nothing cast (the bell should ring at about 0:25)
##            doom       Silent Doom on the messenger whenever nobody would see it (now, nor where he falls)
##            whisper    Mind Whisper: the running messenger sent 8 units straight back toward the gate
##            discord    Discord on the running messenger
##            mix        Whisper, Discord and Silent Doom: Doom whenever he is alone, else Whisper and Discord in turn
##          each whenever its slot allows it (never forced), looked at every 0.1 s -- and Mind Whisper only while the
##          messenger is not shaking the last one off (v0.08.1: the aim rings him red); a line for every cast and every
##          change of phase or messenger, a report every 5 s, then the ending, the relays, Unseen and "Solved by".
##          v0.08.1 left Thornwall out of The Warning's pool, and its case with it; any other case is refused.
##   tax    (v0.11 M2) The Tax Collector (three collectors, one after another), --case=none (nothing cast) or play (Silent
##          Doom on the bellkeeper once called; else Silent Doom on the first collector in the street with nobody but those
##          who would fall with him near enough to see it; else Mind Whisper sends a lone onlooker away). --seed= picks the
##          town; --board plays the board's version (its wishes heard) and stops at the main objective.
##   harvest  (v0.11 M2) Spoiled Harvest, --case=none or play (the granaries with their grain in, fewest loads first: Silent
##          Doom on a watchman on guard, then Ember on the granary; spare time, Silent Doom on the watchmen of the next
##          granary when its grain is due within HARVEST_PRE; with nothing else, Silent Doom on a carter walking to a granary
##          with two loads or fewer left). --seed=, --board as tax.
##   lamb   (v0.11 M2) The Lost Lamb, --case=none or play (Discord frees him from a seizer, else Silent Doom on the seizer
##          once he is clear of its blast; Discord on a soldier about to see him; Mind Whisper leads him, re-aimed while he
##          walks, toward a spot four units short of the gate, then, once the watch is changing or gone, through it; the
##          result line gives the longest idle stretch). --seed=, --board as tax.
##   prayers  (v0.11 M2) First Prayers, --case=none or play (as miras, whose policy it shares: a report stopped first; a Faithful by
##          the door dealt with when it matters -- Silent Doom if unseen, else Discord, else a whisper sending him away; then Mind
##          Whisper sends the nearest of the poor toward the shrine's door, at most REACH at a time, the last hop only when the
##          prayer inside is nearly over and his own would not end in a window of Faithful at the door; the result line gives
##          the longest idle stretch, and a line says how long the door was watched). --seed=, --board as tax.
##   ringers  (v0.11 M3) The Bell-Ringers, --case=none (nothing cast) or play, as a player plays it (_ringers_act(): Silent
##          Doom on the town's bellkeeper once called; else on a carrier whose death would go unseen; else on his mates -- both at
##          once, or one -- where it takes no one else; else Mind Whisper sends a mate off, or one of one or two witnesses (none a
##          soldier); else Mind Whisper sends a carrier left without his mates to a quiet spot when Silent Doom will be ready; else
##          Discord on a carrier near the bell's foot or on the rope; between ringers, the next post's door cleared of watchers;
##          never a loud power; the result line gives the longest idle stretch).
##          --seed= picks the town; --board plays the board's version (its wishes heard) and stops at the main objective.
##   panic  (v0.11 M3) Market Panic, --case=none (nothing cast) or play, as a player plays it (_panic_act(): nothing while the
##          first crowd takes its places; Silent Doom on a warden on guard steadying four or more goers, the one nearest the
##          fountain first; else, once no crowd is still to come, Heaven Splitter through the fair with no warden on guard and
##          six or more goers, along the ground axis that takes more, or along five or more walkers no warden steadies; else Smite
##          on the densest knot of three or more unsteadied goers, or on the goer nearest the fountain; else Silent Doom on a
##          warden on guard, to clear the cover before the next crowd; the result line gives the longest idle stretch). Hit-stop is
##          off for it (Impact.hitstop_enabled), so two runs of a seed give the same checksum. --seed=, --board as ringers.
##   informer  (v0.11 M3) The Informer, --case=none (nothing cast) or play, as a player plays it (_informer_act(): Silent Doom on
##          the town's bellkeeper once called; once the informer is found and out of doors, Silent Doom on him when unseen, or
##          whatever the witnesses within 8 of the Temple's door, never with a contact beside him; with word at the contact: no
##          onlooker, Mind Whisper sends him three units off (and turns him); else, both ready, Discord where it holds every onlooker
##          but at most one a whisper can send off, the whisper following; else Mind Whisper sends one onlooker eight units off, his
##          company and those standing still first; in the 18 s before his visit, his company sent off one at a time while the
##          whisper will be ready again when word comes; never a Doom on a contact; the result line gives the longest idle
##          stretch). --seed=, --board as ringers.
##   bread  (v0.11 M4) The Crown's Bread, --case=none (nothing cast) or play, as a player plays it (_bread_act(): the target in use
##          with an engineer on guard: Smite one within Smite's reach of it (he falls and it takes the blow), else Silent Doom on one
##          alone (else any), else Mind Whisper sends one eight units off; none on guard: Ember a granary or mill not burning (Smite
##          it while Ember cools), Smite the bridge; else, the next target within 25 s of its time, its engineers cleared with Doom
##          and Whisper only (never a blow ahead of its time); else Silent Doom on a relief walking in; the result line gives the
##          longest idle stretch). Hit-stop is off for it. --seed=, --board as ringers.
##   prisoner  (v0.11 M4) The Prisoner, --case=none (nothing cast) or play, as a player plays it (_prisoner_act(): bound, a gaoler
##          within sight of her: Silent Doom on him, else Mind Whisper sends him eight units off; bound, none: Ember the stocks; held:
##          Discord on the seizer, or Doom him once she stands clear; free, a watcher (not the postern's watch) within 4 of her or of
##          her next stretch of road: whisper him off, else Doom, else Discord; Mind Whisper sends her up to 10 units along her road,
##          stopping short of the postern while it is watched; at the postern, watched, the change more than 10 s off: whisper one of
##          its watch off; never a loud power; the result line gives the longest idle stretch). --seed=, --board as ringers.
##   hunt  (v0.11 M4) The Heretic Hunt, --case=none (nothing cast) or play, as a player plays it (_hunt_act(): the captain out of
##          doors, Silent Doom on him; a raised standard unguarded, Smite on its far side from its guards; a raised standard guarded,
##          or the next sweep within 25 s: Discord where it holds two or more guards of a raised standard (the Smite follows while
##          they are held), else Silent Doom on a guard alone (else any), else Mind Whisper sends one eight units off; else Silent Doom
##          on a relief walking in; the result line gives the longest idle stretch). Hit-stop is off for it. --seed= as ringers.
##   bishop  (v0.11 M5) The Bishop, --case=none (nothing cast) or play, as a player plays it (_bishop_act(): the bishop out of doors,
##          Silent Doom on him, else Smite; a Knight on guard at his refuge, Silent Doom on one alone, else Smite one; none on guard,
##          Ember the refuge (Smite it while Ember cools); in his flight or 25 s before his first refuge, Silent Doom on the next
##          refuge's Knights; else Silent Doom on a relief walking in; the result line gives the longest idle stretch). Hit-stop is
##          off for it. --seed= as ringers.
##   armoury  (v0.11 M5) The Armoury, --case=none (nothing cast) or play, as a player plays it (_armoury_act(): the mustering target
##          with an armed man on guard: Smite one within Smite's reach of it (he falls and it takes the blow), else Silent Doom on one
##          alone (else the first); none on guard: Ember a barracks or the armoury not burning (Smite it while Ember cools), Heaven
##          Splitter through the gate barracks (Smite it while Heaven cools); the next horn within 25 s, its night watch cleared with
##          Silent Doom; else Silent Doom on a reinforcement or relief running in; the result line gives the longest idle stretch).
##          Hit-stop is off for it. --seed= as ringers.
##   sermon  (v0.11 M5) The Sermon, --case=none (nothing cast) or play, as a player plays it (_sermon_act(): the bellkeeper called,
##          Silent Doom on him, else The Bell Lies, a whisper or Discord; the preacher where his death goes unseen, Silent Doom on
##          him; preaching, Mind Whisper sends him to a quiet spot, else Discord on him; he and both acolytes held, Silent Doom on him;
##          a report running, Silent Doom on its runner where unseen, else a whisper aside or Discord; a Faithful seeing the god's door (a
##          sentry), Silent Doom on him with no one else within 2 and unseen, else Mind Whisper sends him to a quiet spot; the door
##          unwatched, Mind Whisper sends the unturned listener nearest the god's house, not rapt, to its door; else Silent Doom on a
##          sentry off his post where unseen; no Doom takes a listener; the result line gives the longest idle stretch). --seed= as
##          ringers.
##   relic  (v0.11 M5) The Relic Run, --case=none (nothing cast) or play, as a player plays it (_relic_act(): the bellkeeper called,
##          Silent Doom on him, else Discord; a report running, Silent Doom on its runner where unseen, else a whisper off or Discord;
##          with the relic, The Vigil Flame's carry (_flame_carry()); before a halt, Mind Whisper brings Pip to a place 3 short of its
##          checkpoint, and 10 s before it to the checkpoint; the first halt within 25 s, the second within 40 s, Silent Doom on each of
##          its wardens alone where unseen (else Mind Whisper sends him to a quiet spot); halted, Pip not by the cart nor aboard, Mind
##          Whisper sends him to it; halted and watched with Pip by, Discord holding every watcher, else a Will-o'-Wisp for passers-by,
##          else Discord on the escorts, else Silent Doom on a watcher alone and unseen, else Mind Whisper sends one off; aboard at the
##          first halt, nothing; the result line gives the longest idle stretch). --seed= as ringers.
##   exodus  (v0.11 M6) Exodus, --case=none (nothing cast) or play, as a player plays it (_exodus_act(): a believer seized -- Discord on his
##          seizer, else Mind Whisper sends the seizer off, else Silent Doom on him unseen; searchers within EXODUS_HOUNDS of a believer --
##          cleared, else Silent Doom on them unseen wherever they walk; a watcher within SIGHT + EXODUS_WARN of a believer -- cleared; a
##          believer left out of his file -- whispered to his lamp; each household out -- Mind Whisper sends its lamp up to 10 units along
##          its road to the nearest open gate, short of a watched gate and of the first watcher on the way, else that watcher cleared; the
##          next household within EXODUS_AHEAD -- the first watcher on its road cleared; "cleared" is Silent Doom unseen, else Discord, else
##          Mind Whisper; never a loud power, and every Doom unseen with room to spare and sparing the believers, so its Gaze stays 0-10%;
##          the result line gives the Gaze and the longest idle stretch). --seed= as ringers.
##   eye  (v0.11 M6) The Lantern's Eye, --case=none (nothing cast) or play, as a player plays it (_eye_act(), never casting where a lit pool
##          lies within POOL_R + EYE_LIT_MARGIN of the aim, every Silent Doom taken alone with room for walkers (_eye_unseen()): a
##          shattered mirror's wrights at work, Silent Doom on one, else Mind Whisper sends one off to a quiet spot; the current mirror
##          open and none of its guards walking back, Smite on its tower's outer face where it strikes no one, Heaven Splitter along the
##          face while Smite cools where nobody stands within its kill, a Will-o'-Wisp off the face while a beam lights it -- the shattering
##          blow waiting until Silent Doom and Mind Whisper are both ready, a Wisp first drawing onlookers off the wrights' posts; the
##          current mirror standing or the next due within EYE_AHEAD, Silent Doom on a guard, on guard or sent off, else a Wisp draws off
##          the passers-by who would see it, else Mind Whisper sends one to a quiet spot; a relief walking in, Silent Doom on him; the
##          result line gives the longest idle stretch). Hit-stop is off for it. --seed=, --board as ringers.
##   heart  (v0.11 M6) The Heart of Faith, --case=none (nothing cast) or play, as a player plays it (_heart_act(): Odran on foot out of
##          doors -- Silent Doom on him, else Smite (his death is the win, seen or not); his rite running with neither ready -- Mind
##          Whisper sends him HEART_OFF units off the steps; riding, or his bearers waiting -- a bearer struck; his last guard within
##          HEART_GUARD of him -- the same; the target in use guarded -- a Knight struck; unguarded and not burning -- Ember (Smite while
##          Ember cools); the next target within HEART_AHEAD of its time -- its standing Knights struck one at a time; a relief walking in
##          -- the same. A strike is Silent Doom where its death goes unseen, else Smite there, else Mind Whisper sends a lone citizen
##          witness HEART_HUSH units off; on a guard at the target in use, a bearer or the last guard, at last a seen Doom while the Gaze
##          stays within HEART_GAZE_CAP (a seen death adds 10, and 20 once the flame is out). It never fells a target ahead of its time;
##          the result line gives the Gaze and the longest idle stretch). Hit-stop is off for it. --seed= as ringers.
##   night  (v0.09) The Long Night forced through its acts: `--path=festival|procession`, `--act1=win|lose|skip`,
##          `--act2=…`, `--act3=…`; each act ends as asked (skip lets it run to its clock); prints each act's result, the
##          town's tier at each act's start, and the night's result. Before the first handover the time scale is dipped
##          to 0.3 and a Heaven Splitter is still falling: the next act must start at 1.0 with nothing credited,
##          every cooldown ready and no power still playing (a `handover` line). `--prince=unseen|seen|escaped` is a test aid (v0.09 Task 8):
##          it overwrites what the Procession decided, once Act II-B is over, so Act III's town can be raised by any
##          outcome even when the act was ended by force. `--festival=broken|held` is a test aid (v0.09): it
##          overwrites what the Festival decided, once Act II-A is over, so Act III's town can be raised by any outcome
##          even when the act was ended by force. `--shots` (v0.09
##          Task 13) photographs Act II-A's market at 30, 50 and 95 s into it (captures/behaviour_festival_<s>.png, and
##          the Mayor close up at 95 s; Task 16: Act II-B's blessing and dock at 65 and 125 s,
##          captures/behaviour_procession_<s>.png); `--calm-handover` skips the dipped time scale and the falling Heaven Splitter,
##          so Act II starts in a quiet town (for photographs). `--act1|2|3=play` (Task 18) plays that act with a scripted
##          policy instead of forcing it (see the NIGHT_LOADOUTS and _play_act()): Act I the Warning's mix, the Festival
##          Silent Doom on the Mayor at 95 s then Discord on the densest cluster, the Procession Doom on the Prince when
##          nobody would see it (`--doom-seen` also dooms him, seen, on the dock's leg), Act III the greedy Last Judgement
##          caster; each act is drafted its own loadout. A played night skips the handover aid (its Heaven Splitter would fall
##          on the Prince at the Citadel's door). Task 19: Act III's caster aims each cast where it takes the most of
##          what City Stability still counts (_richest(); `--act3-aim=fixed` keeps Task 18's eight fixed targets), and
##          `--act3-loadout=a,b,c` drafts Act III other powers; its reports carry stability's parts and the act's
##          escapes, and the Procession's end line counts the looks with no soldier, and nobody, within the witness
##          distance.
## --difficulty=<tier> plays any scenario at that tier (default Organized; rite, engineers and boats: Prepared).
## --route=b (v0.11.1, spec §7) plays a board mission's second route: it drafts RouteBook.loadout_b() and plays the scenario's B policy
##   (tools/dev/routes/tier<N>_b.gd: act_<scenario>(bc, ctx) and state_<scenario>(bc, ctx) through _scripted(); hit-stop is off for every
##   scenario; --board plays the board version, as for the ★ missions. `--scenario=feast --path=festival|procession --board` plays the
##   board's Festival or Procession (mission_id = the board id). ctx = {rules, slots, d (the director), crowd, memo, mission}.
##   `--scenario=night --route=b --board` (Task 12) plays the whole night, every act with its own loadout B (RouteBook.ACTS_B, drafted at each
##   handover; `--path=` picks the Festival or the Procession) and tier5_b.gd's act_night(); its result line gives the night's total time and
##   its longest idle stretch across the acts.

const SEED := 7
## How many houses `siege --burn` sets burning each time (v0.08.2).
const BURN_HOUSES := 6

## Seconds into Act II-A that `night --shots` photographs, and the ground point it looks at (the fountain).
const FESTIVAL_SHOTS := [30.0, 50.0, 95.0]
const FESTIVAL_LOOK_AT := Vector2(1.0, 4.0)
## Seconds into Act II-B that `night --shots` photographs (the blessing, the dock), the zoom, and how far from the Prince
## towards the boarding point the camera looks (0 on him, 1 at the ship).
const PROCESSION_SHOTS := [[65.0, 2.5, 0.0], [125.0, 1.6, 0.6]]

## What each act drafts when `night` plays it (v0.09 Task 18), simulating Prepare's re-draft between acts (each fits its
## act's slots and DP, v0.09.1: Act I 3 / 6, Act II 4 / 10, Act III 4 / 14). Act I's is the Warning's mix (3 DP); the
## Festival needs only the Mayor's Doom and a Discord (3 DP); the Procession adds a Mind Whisper (4 DP); Act III is the
## four heaviest it can afford (Task 19: Heaven Splitter, Nuclear Nova, Judgement of the Ancients, Cinderfall Barrage:
## 2 + 4 + 4 + 4 = 14 DP).
const NIGHT_LOADOUTS := {"omen": ["whisper", "doom", "discord"], "festival": ["doom", "discord"],
	"procession": ["whisper", "doom", "discord"], "judgement": ["heaven", "nova", "judgement", "cinder"]}
## The Festival's Silent Doom on the Mayor is cast from this second of the act (inside his address, 90 s to 120 s).
const FESTIVAL_DOOM_AT := 95.0
## How far Mind Whisper sends an attendant of the Prince's from him (the Procession's policy), in ground units.
const PROCESSION_SENT := 8.0
## Act III's aim (Task 19, _richest()): how far round a point counts (ground units).
const RICH_R := 3.0
## A policy looks at the town every this many frames (0.1 s at 60 fps), as the Warning's does.
const LOOK_FRAMES := 6
## The tax policy's margin beyond Crowd.DOOM_WITNESS for an onlooker's walk (v0.11 M2, _tax_unseen()).
const TAX_MARGIN := 0.2
## The harvest policy clears the next granary's watchmen when its grain is due within this many seconds (v0.11 M2): sooner, the relief
## (HarvestDirector.RELIEF_AFTER) walks in before the fire has burned its 10 s.
const HARVEST_PRE := 20.0
## The Lost Lamb policy (v0.11 M2): where it holds him for the watch's change, relative to the west gate's mouth, and how far
## beyond SIGHT it reads a soldier as about to see him.
const LAMB_WAIT := Vector2(0.0, -4.0)
const LAMB_WARN := 2.0
## The Lost Lamb policy sends the next whisper once he is within this of where the last sent him, and Silent Doom on his seizer
## only with him this much beyond its radius from the seizer, or the same cast would take him too (v0.11 M2).
const LAMB_AHEAD := 5.0
const LAMB_CLEAR := 0.4
## How far from the shrine's door one of the poor must still be for the prayers policy to send him while someone prays (v0.11 M2).
const PRAYERS_FAR := 6.0
## The prayers policy (v0.11 M2) guards the door from this many seconds before a prayer ends, allows PRAYERS_WALK for one of
## the poor to reach it, and waits PRAYERS_SLACK after a window of Faithful at the door for them to leave.
const PRAYERS_EXIT := 12.0
const PRAYERS_WALK := 8.0
const PRAYERS_SLACK := 4.0
## The Bell-Ringers' policy (v0.11 M3): how near two mates stand for one Silent Doom at their midpoint.
const RINGERS_PAIR := 1.6
## The Bell-Ringers' policy (v0.11 M3): how near the bell's foot a carrier draws Discord.
const RINGERS_DISCORD := 8.0
## The Bell-Ringers' policy (v0.11 M3): how far Mind Whisper sends a mate, a witness or a door's watcher off.
const RINGERS_SEND := 6.0
## The Bell-Ringers' policy (v0.11 M3): how many seconds before a post sends its ringer it clears that door of watchers.
const RINGERS_PREP := 20.0
## The Bell-Ringers' policy (v0.11 M3): how near a post's door a watcher counts, Crowd.DOOM_WITNESS and a margin.
const RINGERS_DOOR_R := 2.5
## The Bell-Ringers' policy (v0.11 M3): the rings searched for a quiet spot to whisper a lone carrier to.
const RINGERS_QUIET_R := [4.0, 7.0]
## The Bell-Ringers' policy (v0.11 M3): the directions searched on each of RINGERS_QUIET_R.
const RINGERS_QUIET_DIRS := 8
## The Bell-Ringers' policy (v0.11 M3): how far from anyone else a quiet spot must be.
const RINGERS_QUIET_CLEAR := 3.0
## The Bell-Ringers' policy (v0.11 M3): a lone carrier is whispered aside only if Silent Doom is ready within this many seconds.
const RINGERS_DOOM_SOON := 5.0
## Market Panic's policy (v0.11 M3): how many goers a warden must steady to draw Silent Doom.
const PANIC_WARD_CROWD := 4
## Market Panic's policy (v0.11 M3): how many goers round the fountain draw a Heaven Splitter.
const PANIC_PACK := 6
## Market Panic's policy (v0.11 M3): how many walkers in one strip draw a Heaven Splitter.
const PANIC_WALKERS := 5
## Market Panic's policy (v0.11 M3): how many goers in a knot draw Smite.
const PANIC_KNOT := 3
## Market Panic's policy (v0.11 M3): the directions tried for the walkers' strip.
const PANIC_DIRS := 8
## Market Panic's policy (v0.11 M3): seconds the first crowd is given to take its places before the player acts (mission spec §2:
## "there in about 10 s"); at the first look the goers stand in a clump round the fountain, where one Silent Doom takes ten of them.
const PANIC_SETTLE := 10.0
## The Informer's policy (v0.11 M3): how far a contact is whispered off unseen, and an onlooker away; how near the Temple's door a
## found informer is struck whatever the witnesses; how long before a visit his company is whispered off.
const INFORMER_OFF := 3.0
const INFORMER_AWAY := 8.0
const INFORMER_LAST := 8.0
const INFORMER_EARLY := 18.0
## The Crown's Bread's policy (v0.11 M4): how near its time the next target's crew is cleared; how far an engineer is whispered off.
const BREAD_AHEAD := 25.0
const BREAD_AWAY := 8.0
## The Prisoner's policy (v0.11 M4): how far past sight a gaoler counts; the margin a Doom or Discord keeps from her; how near her or her
## next stretch a watcher is dealt with; that stretch's length; how far a watcher is whispered off; where she waits short of a watched
## postern; how soon a change makes the watch worth waiting for.
const PRISONER_WARN := 2.0
const PRISONER_CLEAR := 0.4
const PRISONER_NEAR := 4.0
const PRISONER_STRETCH := 6.0
const PRISONER_AWAY := 8.0
const PRISONER_WAIT := Vector2(0.0, -3.0)
const PRISONER_SOON := 10.0
## The Heretic Hunt's policy (v0.11 M4): how near its time the next sweep's guards are cleared; how far a guard is whispered off; how
## far from a standard's centre, away from its guards, the Smite lands.
const HUNT_AHEAD := 25.0
const HUNT_AWAY := 8.0
const HUNT_FAR := 0.3
## The Bishop's policy (v0.11 M5): how near his first arrival the next refuge's Knights are cleared.
const BISHOP_AHEAD := 25.0
## The Armoury's policy (v0.11 M5): how near its horn the next target's night watch is cleared.
const ARMOURY_AHEAD := 25.0
## The Sermon's policy (v0.11 M5): how near a sentry no one else may stand for a Doom; how far one is whispered off.
const SERMON_ALONE := 2.0
const SERMON_AWAY := 8.0
## The Relic Run's policy (v0.11 M5): how near its time the first halt's wardens are cleared, and the second's from the leg (the
## controller's ruling: clearing the watch on Pip's road is work, and no stretch passes 45 s -- a relief walking in is cleared too); how
## near its time a warden whose death would be seen is taken all the same; how far from the next checkpoint Pip waits for the cart (out
## of sight of its wardens' deaths), and how much nearer than that counts as there; how near its time he is sent from there to the
## checkpoint itself, so he stands by the cart as it stops.
const RELIC_AHEAD := 25.0
const RELIC_LEG := 40.0
const RELIC_LATE := 10.0
const RELIC_PARK := 3.0
const RELIC_NEAR := 0.8
const RELIC_COME := 10.0
## The Relic Run's policy at a halt (v0.11 M5): how far beyond the cart from Pip a Will-o'-Wisp draws passers-by off it; how near the
## escorts' midpoint both must stand for one Discord, and the margin inside Discord's reach that every watcher must stand for one Discord
## to hold them all; how far a watcher is whispered off.
const RELIC_LURE := 4.0
const RELIC_PAIR := 1.2
const RELIC_MARGIN := 0.15
const RELIC_AWAY := 8.0
## Exodus's policy (v0.11 M6): how near a believer searchers are answered; how near the lamp's way or its gate a watcher counts; how far
## short of a watched gate the lamp waits, and the least step it is whispered on; how soon before the next household its road is
## cleared, and how soon by Mind Whisper too (sooner, the watcher is back at his post before it comes); how far beyond the witness reach
## of those Silent Doom takes no one may stand (a passer-by walks in while it falls); how far beyond SIGHT a watcher counts as about to
## see a believer.
const EXODUS_HOUNDS := 6.0
const EXODUS_NEAR := 4.0
const EXODUS_WAIT := 3.0
const EXODUS_STEP := 1.5
const EXODUS_AHEAD := 25.0
## The Lantern's Eye's policy (v0.11 M6): how far past a lit pool's edge it never casts; how far out from a tower its Wisp goes; how
## soon before the next mirror it clears that party; how far round its aim a Heaven Splitter kills (its fissures and their eruptions),
## where nobody may stand for the policy to lay one.
const EYE_LIT_MARGIN := 0.5
const EYE_WISP := 6.0
const EYE_AHEAD := 25.0
const EYE_HEAVEN_R := HEAVEN_FX.FISSURE_LENGTH + HEAVEN_FX.ERUPT_KILL
## How far along a tower's face the policy slides its Smite's aim when the face's middle is taken (v0.11 M6).
const EYE_AIM_SLIDE := 0.6
## The Lantern's Eye's timing (v0.11 M6): how soon Silent Doom and Mind Whisper must both be ready for the shattering blow (about a
## Smite's play, which holds every other cast); how near standing guard a guard walking back holds a blow; how much farther than
## Crowd.DOOM_WITNESS someone on the move must be for a Silent Doom to go unseen.
const EYE_CREW_WAIT := 2.0
const EYE_COMING := 1.0
const EYE_DOOM_MARGIN := 0.4
## How far beyond a guard, away from his tower, the policy's Will-o'-Wisp draws off the passers-by who would see him fall (v0.11 M6).
const EYE_LURE := 4.5
## The Heart of Faith's policy (v0.11 M6): how soon before the next target it clears that target's Knights; how far off the steps its
## whisper sends Odran; how near Odran his last guard is answered.
const HEART_AHEAD := 25.0
const HEART_OFF := 4.0
const HEART_GUARD := 3.0
## How far the policy whispers a lone witness off a Knight before it strikes; how long after that whisper before it will strike seen
## (v0.11 M6).
const HEART_HUSH := 8.0
const HEART_SETTLE := 3.0
## The Gaze the policy lets a seen strike bring it to (v0.11 M6): a player's budget, short of THE LANTERN LOOKS.
const HEART_GAZE_CAP := 60.0
const EXODUS_SOON := 8.0
const EXODUS_MARGIN := 0.5
const EXODUS_WARN := 1.5
## The Broken Lanterns policy (v0.10 M3): how far round a shrine counts the people a Dragonfire Parade there would burn.
const LANTERN_CROWD_R := 3.0
## The Heaven Splitter the policy lays (its line's reach and width, its core), the farthest apart two shrines may stand
## for one line to break both, and how many directions it weighs for a single shrine (over a half turn: the line runs
## both ways).
const HEAVEN_FX := preload("res://src/fx/set2/heaven_splitter.gd")
const LANTERN_PAIR_REACH := 9.0
const LANTERN_DIRS := 8
## The Dragonfire Parade burns a street, so the policy sends it only when the Splitter would come too late for the shrine
## it breaks to drain before dawn, with this many seconds to spare.
const LANTERN_DRAGON_SPARE := 5.0
## `bonus` waits for the kneelers only while the night still leaves this many seconds beyond a drain and that spare.
const LANTERN_BONUS_SPARE := 10.0
## The Vigil Flame policy (v0.10 M4): how near the lantern a Faithful counts as a watcher of the swap (Crowd.DOOM_WITNESS
## and a margin for his walk), how far from the Temple's door Wren must be for its Discord (its searching beam must not
## find him), and how far the policy moves him, or a wisp from a beam.
const FLAME_WATCH_R := 3.0
const FLAME_DANGER := 4.5
const FLAME_DODGE := 5.0
## Bystanders this near the lantern, going about their day, could wander into the swap: a wisp FLAME_STRAY_LURE beyond
## them (well within its reach of them all) draws them off first.
const FLAME_STRAY_R := 5.0
const FLAME_STRAY_LURE := 3.0
## The carry reads the beams' paths ahead: FLAME_LOOKAHEAD seconds for a beam coming onto Wren (within POOL_R and
## FLAME_MARGIN), FLAME_PLAN for where a whisper sends him (his walk there and his linger), in FLAME_STEP steps; it
## weighs FLAME_DIRS spots round him (or round the beam, for a wisp).
const FLAME_LOOKAHEAD := 3.0
const FLAME_MARGIN := 1.0
const FLAME_PLAN := 12.0
const FLAME_STEP := 0.5
const FLAME_DIRS := 8
## How far inside Discord's reach the policy keeps those it means to take, for their walk while the cast lands.
const FLAME_DISCORD_MARGIN := 0.2
## The campaign's Night 3 (v0.10 M5, spec §4.2): its slots, and the budget of a run that won Nights 1 and 2 with no bonus.
const FEAST_SLOTS := 4
const FEAST_DP := CampaignDef.START_DP + 2 * CampaignDef.WIN_DP
## Night 4, Last Judgement in the campaign (spec §4.3): its slots, and the budget of a run that won Nights 1-3, no bonus.
const FINALE_SLOTS := 6
const FINALE_DP := CampaignDef.START_DP + 3 * CampaignDef.WIN_DP

## v0.11.1 second routes (spec §7): the scenario's board mission id (feast: by --path, see _route_id()), and the tier files holding its B policy.
const ROUTE_IDS := {"warning": "warning", "tax": "tax_collector", "harvest": "spoiled_harvest", "lamb": "lost_lamb",
	"prayers": "first_prayers", "miras": "miras_house", "lanterns": "broken_lanterns", "ringers": "bell_ringers",
	"panic": "market_panic", "informer": "informer", "flame": "vigil_flame", "bread": "crowns_bread", "prisoner": "prisoner",
	"hunt": "heretic_hunt", "bishop": "bishop", "armoury": "armoury", "sermon": "sermon", "relic": "relic_run",
	"judgement": "last_judgement", "night": "long_night", "eye": "lantern_eye", "exodus": "exodus", "heart": "heart_of_faith"}
const TIER_B := [preload("res://tools/dev/routes/tier1_b.gd"), preload("res://tools/dev/routes/tier2_b.gd"),
	preload("res://tools/dev/routes/tier3_b.gd"), preload("res://tools/dev/routes/tier4_b.gd"), preload("res://tools/dev/routes/tier5_b.gd")]

var mission: Mission
## "b" under --route=b (v0.11.1), else "".
var route := ""


func _initialize() -> void:
	mission = load("res://scenes/mission.tscn").instantiate()
	root.add_child(mission)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scenario := Battlefield.arg_value(args, "--scenario")
	var seconds := float(Battlefield.arg_value(args, "--seconds")) if Battlefield.arg_value(args, "--seconds") != "" \
		else 60.0
	while not mission.is_prewarmed or not mission.started():
		await process_frame
	# A fixed seed (--seed=, default SEED): without a scripted flag the mission seeds itself from the clock.
	var seed_arg := Battlefield.arg_value(args, "--seed")
	var tier := Battlefield.arg_value(args, "--difficulty")
	if tier == "" and scenario in ["rite", "engineers", "boats", "clip", "powers", "soldiers"]:
		tier = "prepared"
	if tier != "":
		mission.difficulty = ResponseProfile.tier_named(tier)
	var powers := PackedStringArray()
	if scenario == "quiet":
		powers = PackedStringArray(["doom", "blight", "heaven", "nova"])
	elif scenario == "powers":
		powers = PackedStringArray(["wisp", "thorns", "discord", "pestilence"])
	elif scenario == "clip":
		powers = PackedStringArray([Battlefield.arg_value(args, "--power"), "heaven", "cinder", "nova"])
	elif scenario == "opening":
		powers = PackedStringArray(["doom", "blight", "heaven", "cinder"])
	elif scenario == "warning":
		var case_arg := Battlefield.arg_value(args, "--case")
		powers = PackedStringArray(WARNING_CASES.get(case_arg if case_arg != "" else "none", ["whisper"]))
		mission.mission_id = MissionBook.WARNING
	elif scenario == "miras":
		powers = PackedStringArray(["whisper", "doom", "discord"])
		mission.mission_id = MissionBook.MIRAS_HOUSE
	elif scenario == "lanterns":
		powers = PackedStringArray(["heaven", "dragon", "doom"])
		mission.mission_id = MissionBook.BROKEN_LANTERNS
	elif scenario == "flame":
		powers = PackedStringArray(["whisper", "discord", "wisp"])
		mission.mission_id = MissionBook.VIGIL_FLAME
	elif scenario == "feast":
		var wanted := Battlefield.arg_value(args, "--loadout")
		powers = PackedStringArray(wanted.split(",")) if wanted != "" else PackedStringArray(NIGHT_LOADOUTS[_feast_path()])
		mission.mission_id = "feast_" + _feast_path()
		mission.bell_rang = Battlefield.arg_value(args, "--bell") == "rang"
	elif scenario == "night":
		powers = PackedStringArray(["whisper", "doom", "discord"])
		mission.mission_id = MissionBook.LONG_NIGHT
	elif scenario == "tax":
		powers = PackedStringArray(["doom", "whisper", "discord"])
		mission.mission_id = MissionBook.TAX_COLLECTOR
	elif scenario == "harvest":
		powers = PackedStringArray(["ember", "doom", "discord"])
		mission.mission_id = MissionBook.SPOILED_HARVEST
	elif scenario == "lamb":
		powers = PackedStringArray(["whisper", "discord", "doom"])
		mission.mission_id = MissionBook.LOST_LAMB
	elif scenario == "prayers":
		powers = PackedStringArray(["whisper", "doom", "discord"])
		mission.mission_id = MissionBook.FIRST_PRAYERS
	elif scenario == "ringers":
		powers = PackedStringArray(["doom", "whisper", "discord"])
		mission.mission_id = MissionBook.BELL_RINGERS
	elif scenario == "panic":
		powers = PackedStringArray(["heaven", "doom", "smite"])
		mission.mission_id = MissionBook.MARKET_PANIC
	elif scenario == "informer":
		powers = PackedStringArray(["whisper", "discord", "doom"])
		mission.mission_id = MissionBook.INFORMER
	elif scenario == "bread":
		powers = PackedStringArray(["doom", "smite", "ember", "whisper"])
		mission.mission_id = MissionBook.CROWNS_BREAD
	elif scenario == "prisoner":
		powers = PackedStringArray(["whisper", "doom", "ember", "discord"])
		mission.mission_id = MissionBook.PRISONER
	elif scenario == "hunt":
		powers = PackedStringArray(["doom", "smite", "whisper", "discord"])
		mission.mission_id = MissionBook.HERETIC_HUNT
	elif scenario == "bishop":
		powers = PackedStringArray(["doom", "smite", "ember"])
		mission.mission_id = MissionBook.BISHOP
	elif scenario == "armoury":
		powers = PackedStringArray(["doom", "smite", "ember", "heaven"])
		mission.mission_id = MissionBook.ARMOURY
	elif scenario == "sermon":
		powers = PackedStringArray(["whisper", "discord", "doom", "belllies"])
		mission.mission_id = MissionBook.SERMON
	elif scenario == "relic":
		powers = PackedStringArray(["whisper", "discord", "doom", "wisp"])
		mission.mission_id = MissionBook.RELIC_RUN
	elif scenario == "eye":
		powers = PackedStringArray(["doom", "smite", "whisper", "wisp", "heaven"])
		mission.mission_id = MissionBook.LANTERN_EYE
	elif scenario == "exodus":
		powers = PackedStringArray(["whisper", "doom", "discord", "wisp"])
		mission.mission_id = MissionBook.EXODUS
	elif scenario == "heart":
		powers = PackedStringArray(["doom", "smite", "ember", "whisper", "heaven"])
		mission.mission_id = MissionBook.HEART_OF_FAITH
	route = Battlefield.arg_value(args, "--route")
	if not route in ["", "a", "b"]:
		push_error("behaviour_check: unknown --route=%s (a or b)" % route)
		quit(1)
		return
	if scenario == "feast" and "--board" in args:
		mission.mission_id = _route_id(scenario)  # v0.11.1: the board's Festival or Procession, not the campaign night
	if route == "b" and not RouteBook.loadout_b(_route_id(scenario)).is_empty():
		powers = RouteBook.loadout_b(_route_id(scenario))
	mission.start(powers, int(seed_arg) if seed_arg != "" else SEED)
	if route == "b" or scenario in ["panic", "bread", "hunt", "bishop", "armoury", "eye", "heart"]:
		mission._bf.ctx.impact.hitstop_enabled = false  # v0.11 M3-M6: Smite's and Heaven Splitter's hit-stop is wall clock; an exact replay needs none
	mission._intro_left = 0.0
	mission._rules.set_process(true)
	match scenario:
		_ when route == "b":
			await _route_b(scenario, Battlefield.arg_value(args, "--case"))
		"calm", "":
			await _calm(seconds, "--shots" in args)
		"strike":
			await _strike("--shots" in args)
		"escalate":
			await _escalate()
		"fire":
			await _fire("--shots" in args)
		"bell":
			await _bell("--kill-keeper" in args, "--shots" in args)
		"rite":
			await _rite("--interrupt" in args, "--shots" in args)
		"engineers":
			await _engineers("--shots" in args)
		"boats":
			await _boats("--cut-bridge" in args, "--shots" in args)
		"quiet":
			await _quiet("--shots" in args)
		"opening":
			await _opening("--quiet" in args)
		"powers":
			await _powers(Battlefield.arg_value(args, "--case"))
		"soldiers":
			await _soldiers(Battlefield.arg_value(args, "--case"))
		"clip":
			await _clip(Battlefield.arg_value(args, "--power"), Battlefield.arg_value(args, "--at"),
				Battlefield.arg_value(args, "--seconds"), Battlefield.arg_value(args, "--setup"))
		"siege":
			await _siege("--burn" in args)
		"gates":
			await _gates("--hazard" in args, "--shots" in args)
		"judgement":
			await _judgement()
		"miras":
			await _miras(Battlefield.arg_value(args, "--case"))
		"lanterns":
			await _lanterns(Battlefield.arg_value(args, "--case"))
		"flame":
			await _flame(Battlefield.arg_value(args, "--case"))
		"feast":
			await _feast(Battlefield.arg_value(args, "--case"))
		"night":
			await _night()
		"tax":
			await _tax(Battlefield.arg_value(args, "--case"))
		"harvest":
			await _harvest(Battlefield.arg_value(args, "--case"))
		"lamb":
			await _lamb(Battlefield.arg_value(args, "--case"))
		"prayers":
			await _prayers(Battlefield.arg_value(args, "--case"))
		"ringers":
			await _ringers(Battlefield.arg_value(args, "--case"))
		"panic":
			await _panic(Battlefield.arg_value(args, "--case"))
		"informer":
			await _informer(Battlefield.arg_value(args, "--case"))
		"bread":
			await _bread(Battlefield.arg_value(args, "--case"))
		"prisoner":
			await _prisoner(Battlefield.arg_value(args, "--case"))
		"hunt":
			await _hunt(Battlefield.arg_value(args, "--case"))
		"bishop":
			await _bishop(Battlefield.arg_value(args, "--case"))
		"armoury":
			await _armoury(Battlefield.arg_value(args, "--case"))
		"sermon":
			await _sermon(Battlefield.arg_value(args, "--case"))
		"relic":
			await _relic(Battlefield.arg_value(args, "--case"))
		"eye":
			await _eye(Battlefield.arg_value(args, "--case"))
		"exodus":
			await _exodus(Battlefield.arg_value(args, "--case"))
		"heart":
			await _heart(Battlefield.arg_value(args, "--case"))
		"warning":
			var case_arg := Battlefield.arg_value(args, "--case")
			if WARNING_CASES.has(case_arg if case_arg != "" else "none"):
				await _warning(case_arg if case_arg != "" else "none")
			else:
				print("BEHAVIOUR warning no case=%s (cases: %s; Thornwall is not in The Warning's pool since v0.08.1)"
					% [case_arg, ", ".join(WARNING_CASES.keys())])
	print("BEHAVIOUR checksum=%d" % _checksum())
	quit()


## The board mission a scenario plays (v0.11.1, ROUTE_IDS; feast by --path), "" for one that is not a board mission.
func _route_id(scenario: String) -> String:
	if scenario == "feast":
		return "procession" if _feast_path() == "procession" else "festival"
	return String(ROUTE_IDS.get(scenario, ""))


## `--route=b` (v0.11.1, spec §7): the scenario's B policy -- its tier file's act_<name>(bc, ctx) and state_<name>(bc, ctx) -- through
## _scripted(), which stops at the main objective on the board and prints the gate's result line. `name` is the scenario's, but the
## Festival's and the Procession's are named for the act (the board id). A tier file's functions are all a tier task writes: this gives them
## ctx = {rules, slots (key -> slot), d (the director), crowd, memo (the policy's own notes), mission} (rebuilt at every look), and `bc` (this script) with its helpers.
func _route_b(scenario: String, case_arg: String) -> void:
	var id := _route_id(scenario)
	if id == "":
		print("BEHAVIOUR route b: scenario=%s is not a board mission" % scenario)
		return
	if scenario == "night":
		await _night()  # v0.11.1 Task 12: The Long Night plays each act's B policy in its own loop
		return
	var label := id if scenario == "feast" else scenario
	var memo := {}
	var tier: GDScript = TIER_B[TierBook.tier_of(id) - 1]
	await _scripted(label, case_arg if case_arg != "" else "play",
		func() -> String: return String(tier.call("act_" + label, self, _route_ctx(memo))),
		func() -> String: return String(tier.call("state_" + label, self, _route_ctx(memo))))


## A B policy's ctx, built afresh at every look (v0.11.1): the rules, director and crowd change at a night's next_act, so a ctx kept
## across acts would hold a freed director. `memo` is the policy's own notes and lives the whole run.
func _route_ctx(memo: Dictionary) -> Dictionary:
	var rules: Rules = mission._rules
	return {"rules": rules, "slots": _slots(rules), "d": rules.director, "crowd": mission._crowd, "memo": memo, "mission": mission}


func _calm(seconds: float, shots: bool) -> void:
	var t := 0.0
	while t < seconds:
		await _frames(20 * 60)
		t += 20.0
		print("BEHAVIOUR calm t=%d %s" % [roundi(t), _places()])
	if shots:
		var bf: Battlefield = mission._bf
		for shot in [["behaviour_market.png", Vector2(0.8, 2.0), 1.0], ["behaviour_town.png", Vector2(0, 2), 0.3],
				["behaviour_farms.png", Vector2(2.0, 24.0), 0.5]]:
			bf.camera.zoom = Vector2.ONE * float(shot[2])
			bf.camera.position = Iso.ground_to_screen(shot[1]).round()
			await _frames(3)
			await bf.save_capture(shot[0])


func _strike(shots: bool) -> void:
	await _frames(20 * 60)
	var at := Vector2(0.8, 2.0)
	mission._rules.cast(0, at, {"dir": Vector2(1, 0)})
	var t := 0.0
	for mark in [0.5, 2.0, 5.0, 10.0, 20.0, 30.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		print("BEHAVIOUR strike t=%.1f %s" % [t, _bands(at)])
		if shots and is_equal_approx(mark, 2.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(at).round()
			await _frames(2)
			await bf.save_capture("behaviour_strike.png")


func _escalate() -> void:
	await _frames(20 * 60)
	var casts := [[0.0, 0, Vector2(0.8, 2.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 1, Vector2(7.0, -3.0)]]
	var t := 0.0
	var crowd: Crowd = mission._crowd
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			mission._rules._cooldowns[int(c[1])] = 0.0
			mission._rules._playing = null
			mission._rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0.3).normalized()})
		var intents := {}
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.state != DummyEnemy.State.DEAD:
				var k: String = Person.Intent.keys()[p.intent()]
				intents[k] = int(intents.get(k, 0)) + 1
		print("BEHAVIOUR escalate t=%d stage=%s alarm=%d bell=%s escaped=%d %s" % [roundi(t), crowd.alarms.stage_name(),
			roundi(crowd.alarm), crowd.alarms.bell_rung, crowd.escaped_count, intents])
		await _frames(5 * 60)
		t += 5.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _bell(kill_keeper: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if kill_keeper and crowd.bell.keeper != null:
		crowd._field.kill(crowd.bell.keeper, &"test")
	mission._rules.cast(0, Vector2(-10.0, 3.0), {"dir": Vector2(1, 0)})
	var t := 0.0
	var shot := false
	while t < 30.0:
		await _frames(2 * 60)
		t += 2.0
		var k: Person = crowd.bell.keeper
		var where := "-" if k == null or not is_instance_valid(k) else "%s mind=%s goal=%s foot=%.1f" % [k.ground_pos.round(),
			Person.Mind.keys()[k.mind], k.goal().round(), k.ground_pos.distance_to(crowd.bell.foot)]
		print("BEHAVIOUR bell t=%d state=%s progress=%.1f stage=%s alarm=%d rung=%s keeper %s" % [roundi(t),
			BellNetwork.State.keys()[crowd.bell.state], crowd.bell.progress, crowd.alarms.stage_name(), roundi(crowd.alarm),
			crowd.alarms.bell_rung, where])
		if shots and not shot and crowd.bell.state == BellNetwork.State.CLIMBING:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(TownLayout.BELL_TOWER.get_center()) + Vector2(0, -20)).round()
			await _frames(2)
			await bf.save_capture("behaviour_bell.png")


func _rite(interrupt: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	var t := 0.0
	var struck := false
	var shot := false
	while t < 90.0:
		await _frames(5 * 60)
		t += 5.0
		var r := crowd.rite
		if interrupt and not struck and r.state == BanishingRite.State.CHANTING and r.progress >= 10.0:
			struck = true
			for e in r.circle.slice(0, 3):
				crowd._field.kill(e[0], &"test")
			r.step(0.0)
			print("BEHAVIOUR rite t=%d three of the clergy killed" % roundi(t))
		print("BEHAVIOUR rite t=%d state=%s ring=%d called=%d progress=%.1f clergy=%d cathedral=%d%% time_left=%.1f stage=%s" % [
			roundi(t), BanishingRite.State.keys()[r.state], r.in_ring(), r.circle.size(), r.progress, r.living_clergy(),
			roundi(100.0 * r.cathedral.hp / r.cathedral.max_hp) if is_instance_valid(r.cathedral) else 0, rules.time_left,
			crowd.alarms.stage_name()])
		if shots and not shot and r.state == BanishingRite.State.CHANTING and r.progress >= 5.0:
			shot = true
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(r.centre) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_rite.png")


func _engineers(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var town: Town = mission._town
	crowd.add_alarm(AlarmManager.CITY_ALARM)
	rules.cast(0, town.citadel.origin, {"dir": Vector2(1, 0)})
	var bridge := town.bridge
	bridge.destroy(bridge.center(), &"nova")
	var e := crowd.engineers
	var t := 0.0
	var shots_taken := {}
	while t < 60.0:
		await _frames(5 * 60)
		t += 5.0
		var parts := []
		for team: Dictionary in e.teams:
			var job: Dictionary = team.job
			parts.append("standby" if job.is_empty() else "%s%s %d%%%s" % ["rebuild " if job.rebuild else "",
				EngineerManager.Job.keys()[job.type], roundi(100.0 * e.job_fraction(team)), " working" if team.working else ""])
		print("BEHAVIOUR engineers t=%d citadel=%.1f%% cap=%.0f%% bridge=%s teams=%s stage=%s" % [roundi(t),
			100.0 * town.citadel.fraction(), 100.0 * town.citadel.repair_cap() / town.citadel.max_health,
			"down" if bridge.destroyed else "standing", parts, crowd.alarms.stage_name()])
		if shots:
			for team: Dictionary in e.teams:
				var job: Dictionary = team.job
				if not team.working or job.is_empty():
					continue
				var name := "behaviour_engineers_%s.png" % ("rebuild" if job.rebuild else String(EngineerManager.Job.keys()[job.type]).to_lower())
				if shots_taken.has(name):
					continue
				shots_taken[name] = true
				var bf: Battlefield = mission._bf
				bf.camera.zoom = Vector2.ONE * 1.0
				bf.camera.position = (Iso.ground_to_screen(job.site) + Vector2(0, -40)).round()
				await _frames(2)
				await bf.save_capture(name)
	if shots:
		var bf: Battlefield = mission._bf
		bf.camera.position = (Iso.ground_to_screen(bridge.center()) + Vector2(0, -40)).round()
		await _frames(2)
		await bf.save_capture("behaviour_engineers_after.png")


func _boats(cut_bridge: bool, shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var f := crowd.ferry
	var t := 0.0
	for mark in [1.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if cut_bridge and t == 5.0:
			mission._town.bridge.destroy(mission._town.bridge.center(), &"nova")
		var by_exit := {}
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE or p.inside:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
				else ("dock" if p.goal() == f.board_at else "none"))
			by_exit[k] = int(by_exit.get(k, 0)) + 1
		print("BEHAVIOUR boats t=%d by exit %s boats=%s aboard=%d waiting=%d trips=%d carried=%d escaped=%d bridge=%s" % [
			roundi(t), by_exit, RiverFerry.State.keys()[f.state], f.aboard.size(), f.waiting(), f.trips, f.carried,
			crowd.escaped_count, "down" if mission._town.bridge.destroyed else "up"])
		if shots and (t == 15.0 or t == 25.0):
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			var at := f.board_at if t == 15.0 else TownLayout.POSTERN_AT
			bf.camera.position = (Iso.ground_to_screen(at) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_boats.png" if t == 15.0 else "behaviour_postern.png")


func _quiet(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts := [[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO, "doom on the bellkeeper"],
		[2.0, 1, crowd.bell.tower.center(), "blight on the Bell Tower"],
		[4.0, 1, gate.center() - Vector2(0, 0.5), "blight on the Main Gate"],
		[10.0, 2, Vector2(-10.0, 3.0), "Heaven Splitter in the west"]]
	var t := 0.0
	var shot := {}
	var bf: Battlefield = mission._bf
	if shots:
		# The aim previews: Silent Doom rings who it would take, Blight outlines what it would ruin.
		for slot in [0, 1]:
			var aim_at: Vector2 = keeper.ground_pos if slot == 0 else crowd.bell.tower.center() + Vector2(0.6, 0.6)
			mission._aim.pick(slot)
			bf.camera.zoom = Vector2.ONE * 1.5
			bf.camera.position = (Iso.ground_to_screen(aim_at) + Vector2(0, -16)).round()
			await _frames(2)
			# The mission aims wherever the mouse is, every frame: put the mouse on the target.
			bf.get_viewport().warp_mouse(bf.get_viewport().get_canvas_transform() * Iso.ground_to_screen(aim_at))
			await _frames(3)
			await bf.save_capture("behaviour_aim_%s.png" % ["doom", "blight"][slot])
		mission._aim.unfocus()
	while t <= 60.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			rules._cooldowns[int(c[1])] = 0.0
			rules._playing = null
			rules.cast(int(c[1]), c[2], {"dir": Vector2(1, 0)})
			print("BEHAVIOUR quiet t=%.1f %s" % [t, c[3]])
			if shots and int(c[1]) == 0:
				bf.camera.zoom = Vector2.ONE * 1.5
				bf.camera.position = (Iso.ground_to_screen(c[2]) + Vector2(0, -16)).round()
				await _frames(roundi(SilentDoom.T_STRIKE * 60.0) - 6)
				await bf.save_capture("behaviour_doom.png")
		print("BEHAVIOUR quiet t=%.1f alarm=%.1f stage=%s bell=%s keeper=%s killed=%d threats=%d gate=%s" % [t,
			crowd.alarm, crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state],
			"alive" if is_instance_valid(keeper) and keeper.is_alive() else "dead", crowd.killed_citizens,
			crowd.threats.active_count(), "jammed" if gate.blighted else "open"])
		if shots and t >= 5.0 and not shot.has("rot"):
			shot["rot"] = true
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = (Iso.ground_to_screen(crowd.bell.tower.center()) + Vector2(0, -30)).round()
			await _frames(2)
			await bf.save_capture("behaviour_blight.png")
		var step := 2.0 if t < 4.0 else 5.0
		await _frames(roundi(step * 60.0))
		t += step


## Cast slot `slot` at `at` now, whatever its cooldown or another power still playing. `extra` joins the direction
## in the cast's extra (v0.08: a Mind Whisper's "to" and "target").
func _force_cast(slot: int, at: Vector2, dir := Vector2(1, 0), extra := {}) -> FxTimeline:
	var rules: Rules = mission._rules
	rules._cooldowns[slot] = 0.0
	rules._playing = null
	var all := {"dir": dir}
	all.merge(extra)
	return rules.cast(slot, at, all)


## A power's draft preview, recorded in the town: the camera close on the cast, the HUD hidden, CLIP_FRAMES frames
## spread over `seconds` (default: the effect's run), each the screen's middle at half size, as the sandbox's clips.
func _clip(key: String, at_arg: String, seconds_arg: String, setup: String) -> void:
	var at := Vector2(0.8, 2.0)
	if at_arg != "":
		var xy := at_arg.split(",")
		at = Vector2(float(xy[0]), float(xy[1]))
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	if setup == "rite":
		crowd.add_alarm(AlarmManager.CITY_ALARM)
		await _frames(20 * 60)
	elif setup == "evac":
		crowd.alarms.bell_rung = true
		crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
		crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
		crowd.add_alarm(100.0)
		await _frames(10 * 60)
	# A Mind Whisper (v0.08) always snaps: it is cast on someone.
	var whisper := key == "whisper"
	var who: Person = null
	if "--snap" in OS.get_cmdline_user_args() or whisper:
		# Aim at the citizen nearest the point asked for (a queue forms where it will, not where it was guessed).
		var best := INF
		var near := at
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best:
				best = p.ground_pos.distance_to(at)
				near = p.ground_pos
				who = p
		at = near
	var extra := {}
	# The camera's ground point: the cast, or for a whisper halfway along the walk, so the walk stays in frame.
	var look := at
	if whisper:
		var to := MindWhisperFx.clamp_to(crowd._grid, at, at + Vector2(2.2, -2.2))
		extra = {"to": to, "target": who}
		look = at.lerp(to, 0.5)
	var bf: Battlefield = mission._bf
	mission._hud.visible = false
	bf.camera.zoom = Vector2.ONE * 1.5
	bf.camera.position = (Iso.ground_to_screen(look) + Vector2(0, -10 if whisper else -16)).round()
	bf.camera.reset_smoothing()
	await _frames(2)
	var fx := _force_cast(0, at, Vector2(1, 0), extra)
	var run := float(seconds_arg) if seconds_arg != "" else (fx.duration if fx != null else 4.0)
	var crop := PowerBook.CLIP_SIZE * 2
	var rows := ceili(float(PowerBook.CLIP_FRAMES) / PowerBook.CLIP_COLUMNS)
	var sheet := Image.create(PowerBook.CLIP_SIZE.x * PowerBook.CLIP_COLUMNS, PowerBook.CLIP_SIZE.y * rows, false,
		Image.FORMAT_RGBA8)
	var t := 0.0
	for i in PowerBook.CLIP_FRAMES:
		var due := run * (float(i) + 0.5) / float(PowerBook.CLIP_FRAMES)
		await _frames(maxi(roundi((due - t) * 60.0), 0))
		t = due
		await RenderingServer.frame_post_draw
		var img := bf.get_viewport().get_texture().get_image()
		var from := Vector2i((img.get_width() - crop.x) / 2, (img.get_height() - crop.y) / 2)
		var frame := img.get_region(Rect2i(from, crop))
		frame.convert(Image.FORMAT_RGBA8)
		frame.resize(PowerBook.CLIP_SIZE.x, PowerBook.CLIP_SIZE.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, PowerBook.CLIP_SIZE), Vector2i(PowerBook.clip_frame(i).position))
		if i == PowerBook.CLIP_FRAMES / 2 or i == PowerBook.CLIP_FRAMES - 1:
			_clip_report(key, at, t)
	var out := ProjectSettings.globalize_path(PowerBook.clip_path(key))
	sheet.save_png(out)
	print("BEHAVIOUR clip ", out)


func _opening(quiet: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var gate: Structure = mission._town.gates[0]
	var keeper: Person = crowd.bell.keeper
	var casts: Array = []
	if quiet:
		casts.append_array([[0.0, 0, keeper.ground_pos if keeper != null else Vector2.ZERO],
			[2.0, 1, crowd.bell.tower.center()], [4.0, 1, gate.center() - Vector2(0, 0.5)]])
	casts.append_array([[10.0, 2, Vector2(-10.0, 3.0)], [25.0, 2, Vector2(-9.0, -11.0)], [40.0, 3, Vector2(-9.0, 9.0)],
		[55.0, 2, Vector2(-10.5, -8.0)]])
	var t := 0.0
	while t <= 100.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2])
		if int(t) % 5 == 0:
			print("BEHAVIOUR opening t=%d alarm=%.1f stage=%s bell=%s escaped=%d alive=%d" % [roundi(t), crowd.alarm,
				crowd.alarms.stage_name(), BellNetwork.State.keys()[crowd.bell.state], crowd.escaped_count,
				crowd.alive_citizens()])
		await _frames(60)
		t += 1.0
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _siege(burn: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var rules: Rules = mission._rules
	var citadel: Citadel = mission._town.citadel
	var o := TownLayout.CITADEL_ORIGIN
	# The default loadout: heaven, tsunami, cinder, nova.
	# The time now, for the rite's lines (a lambda keeps a copy of a local float, not the variable).
	var now := [0.0]
	var ended := false
	if crowd.rite != null:
		crowd.rite.broken.connect(func(why: String) -> void: print("BEHAVIOUR siege t=%d rite broken: %s" % [roundi(now[0]), why]))
		crowd.rite.ended.connect(func(why: String) -> void: print("BEHAVIOUR siege t=%d rite ended: %s" % [roundi(now[0]), why]))
		crowd.rite.completed.connect(func() -> void: print("BEHAVIOUR siege t=%d rite completed" % roundi(now[0])))
	var casts := [[0.0, 0, Vector2(-10.0, 3.0)], [15.0, 2, Vector2(-9.0, 5.0)], [30.0, 3, o], [45.0, 1, Vector2(5.0, -3.0)],
		[60.0, 0, o + Vector2(0.0, 2.5)], [75.0, 2, Vector2(10.0, 10.0)], [90.0, 3, o], [105.0, 0, Vector2(2.0, 12.0)]]
	var t := 0.0
	while t <= 130.0:
		while not casts.is_empty() and t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			_force_cast(int(c[1]), c[2], Vector2(1, 0.3).normalized())
		if burn and (t == 10.0 or t == 40.0):
			var lit := 0
			var k := 0
			for st in mission._bf.ctx.env.structures():
				if st.kind == Structure.Kind.HOUSE and st.role == &"house" and not st.destroyed \
						and not crowd.fires.is_burning(st):
					k += 1
					if k % 5 == 0 and lit < BURN_HOUSES:
						crowd.fires.ignite(st, 0.4)
						lit += 1
			print("BEHAVIOUR siege t=%d set %d houses burning" % [roundi(t), lit])
		if int(t) % 15 == 0:
			var teams := []
			if crowd.engineers != null:
				for team: Dictionary in crowd.engineers.teams:
					var at_fire := false
					for m in team.members:
						at_fire = at_fire or (is_instance_valid(m) and (m as Person).mind == Person.Mind.ASSIST)
					teams.append(("fire" if at_fire else "idle") if (team.job as Dictionary).is_empty()
						else String(EngineerManager.Job.keys()[team.job.type]).to_lower())
			print("BEHAVIOUR siege t=%d stage=%s alarm=%d escaped=%d alive=%d citadel=%.0f%% stability=%.0f%% clock=%s rite=%s boats=%d engineers=%s jobs=%d fires=%d burned=%d doused=%d buildings=%d over=%s" % [
				roundi(t), crowd.alarms.stage_name(), roundi(crowd.alarm), crowd.escaped_count, crowd.alive_citizens(),
				100.0 * citadel.fraction(), 100.0 * rules.stability.total(), UiTheme.clock(rules.time_left),
				BanishingRite.State.keys()[crowd.rite.state] if crowd.rite != null else "-",
				crowd.ferry.carried if crowd.ferry != null else 0, teams,
				crowd.engineers.jobs().size() if crowd.engineers != null and crowd.engineers.active else -1,
				crowd.fires.fires.size(), crowd.fires.burned_down, crowd.fires.doused_out, rules.buildings_down,
				rules.over_reason])
		if not ended and rules.over_reason != "":
			ended = true
			print("BEHAVIOUR siege over t=%d reason=%s escaped=%d citadel=%.0f%% clock=%s" % [roundi(t), rules.over_reason,
				crowd.escaped_count, 100.0 * citadel.fraction(), UiTheme.clock(rules.time_left)])
		await _frames(60)
		t += 1.0
		now[0] = t
	for h in crowd.alarms.history:
		print("BEHAVIOUR stage at %.1f: %s (%s)" % [float(h[0]), AlarmManager.NAMES[h[1]], h[2]])


func _powers(which: String) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var market := Vector2(0.8, 2.0)
	match which:
		"plague", "combo":
			if which == "combo":
				_force_cast(0, market)
			await _frames(6 * 60)
			var at := _nearest_citizen(market)
			_force_cast(3, at)
			print("BEHAVIOUR powers %s pestilence at %s" % [which, at.round()])
			for k in 7:
				await _frames(10 * 60)
				print("BEHAVIOUR powers %s t=%d sick=%d plague_dead=%d alarm=%.1f stage=%s" % [which, 26 + 10 * (k + 1),
					crowd.plague.sick.size(), crowd.plague.deaths, crowd.alarm, crowd.alarms.stage_name()])
		"wall", "nowall":
			var by_exit := {}
			crowd.escaped.connect(func(p: Person) -> void:
				var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
					else ("boat" if crowd.ferry != null and p.goal() == crowd.ferry.board_at else "other"))
				by_exit[k] = int(by_exit.get(k, 0)) + 1)
			crowd.alarms.bell_rung = true
			crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
			crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
			crowd.add_alarm(100.0)
			await _frames(5 * 60)
			if which == "wall":
				_force_cast(1, Vector2(2.7, 14.25), Vector2(1, 0))
			for k in 4:
				await _frames(10 * 60)
				var queues := []
				for g in mission._town.gates:
					queues.append(crowd.waiting_at(g) if g.walkable else -1)
				print("BEHAVIOUR powers %s t=%d escaped=%d by way out %s queues(main,side,postern)=%s" % [which,
					25 + 10 * (k + 1), crowd.escaped_count, by_exit, queues])
		"discord", "rite":
			crowd.add_alarm(AlarmManager.CITY_ALARM)
			for k in 14:
				await _frames(5 * 60)
				var t := 25 + 5 * k
				if which == "discord" and t == 35:
					_force_cast(2, crowd.rite.centre)
				print("BEHAVIOUR powers %s t=%d rite=%s in_ring=%d progress=%.1f clock=%s" % [which, t,
					BanishingRite.State.keys()[crowd.rite.state], crowd.rite.in_ring(), crowd.rite.progress,
					UiTheme.clock(mission._rules.time_left)])


func _soldiers(which: String) -> void:
	var crowd: Crowd = mission._crowd
	var roles := {"marshals": Person.Corps.MARSHAL, "nomarshals": Person.Corps.MARSHAL, "escort": Person.Corps.ESCORT,
		"noescort": Person.Corps.ESCORT, "rescue": Person.Corps.RESCUE, "norescue": Person.Corps.RESCUE}
	if not roles.has(which):
		print("BEHAVIOUR soldiers: --case= one of %s" % [roles.keys()])
		return
	# The "no" cases take the role away from its soldiers: they keep v0.06's ways.
	if which.begins_with("no"):
		for p in crowd.soldiers:
			if p.corps == roles[which]:
				p.corps = Person.Corps.NONE
		if which == "norescue":
			crowd.rescue.squads.clear()
	var in_role := 0
	for p in crowd.soldiers:
		if p.corps == roles[which]:
			in_role += 1
	print("BEHAVIOUR soldiers %s t=0 %s soldiers=%d%s" % [which, String(Person.Corps.keys()[roles[which]]).to_lower(),
		in_role, " squads=%d" % crowd.rescue.squads.size() if which.ends_with("rescue") else ""])
	await _frames(20 * 60)
	match which:
		"marshals", "nomarshals":
			# Escapes by the way out each took (as the powers scenario's wall case names them).
			var by_exit := {}
			crowd.escaped.connect(func(p: Person) -> void:
				var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1]
					else ("boat" if crowd.ferry != null and p.goal() == crowd.ferry.board_at else "other"))
				by_exit[k] = int(by_exit.get(k, 0)) + 1)
			crowd.alarms.bell_rung = true
			crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
			crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
			crowd.add_alarm(100.0)
			for k in 4:
				await _frames(10 * 60)
				var queues := []
				for g in mission._town.gates:
					queues.append(crowd.waiting_at(g) if g.walkable else -1)
				print("BEHAVIOUR soldiers %s t=%d escaped=%d by way out %s queues(main,side,postern)=%s" % [which,
					20 + 10 * (k + 1), crowd.escaped_count, by_exit, queues])
		"escort", "noescort":
			crowd.alarms.stage = AlarmManager.Stage.CONCERN
			crowd._on_stage(AlarmManager.Stage.LOCAL_EMERGENCY, "test")
			var killed := false
			# Stepped by half seconds so that the kill falls on a set point of the climb; a line every 2 s.
			for k in 60:
				await _frames(30)
				var bell := crowd.bell
				if not killed and bell.state == BellNetwork.State.CLIMBING and bell.progress >= 3.0:
					killed = true
					var near := INF
					for g in crowd.escorts.guards.get("bell", []):
						if is_instance_valid(g):
							near = minf(near, g.ground_pos.distance_to(bell.keeper.ground_pos))
					crowd._field.kill(bell.keeper, &"test")
					print("BEHAVIOUR soldiers %s t=%.1f the bellkeeper killed %.1f s into its climb, nearest escort %s" % [
						which, 20.0 + 0.5 * float(k + 1), bell.progress, ("%.1f away" % near) if near < INF else "none"])
				if k % 4 != 3:
					continue
				var who := "none"
				if is_instance_valid(bell.keeper):
					who = "dead" if not bell.keeper.is_alive() else ("soldier" if bell.keeper.soldier else "citizen")
				print("BEHAVIOUR soldiers %s t=%d bell=%s progress=%.1f keeper=%s rung=%s" % [which, 20 + 2 * ((k + 1) / 4),
					BellNetwork.State.keys()[bell.state], bell.progress, who, crowd.alarms.bell_rung])
			if not killed:
				print("BEHAVIOUR soldiers %s no kill: the bell never climbed" % which)
		"rescue", "norescue":
			var cathedral: Structure = null
			for s in crowd.shelters.shelters.keys():
				if s.role == &"temple" and s.art_tag == &"cathedral":
					cathedral = s
			# Citizens taken into the cathedral, up to its capacity, as if they had run there, then it falls (the
			# collapse's usual consequences follow). `crushed` counts those of them the collapse killed outright.
			var sheltered := []
			for p in crowd.citizens:
				if sheltered.size() < ShelterManager.capacity(cathedral) and p.is_alive() and not p.inside:
					crowd.shelters._enter(p, cathedral)
					(crowd.shelters.shelters[cathedral].inside as Array).append(p)
					sheltered.append(p)
			print("BEHAVIOUR soldiers %s t=20 %d sheltered in the cathedral, then it falls" % [which, sheltered.size()])
			cathedral.destroy(cathedral.center(), &"nova")
			for k in 12:
				await _frames(5 * 60)
				var dead := 0
				for p in sheltered:
					if not is_instance_valid(p) or not p.is_alive():
						dead += 1
				print("BEHAVIOUR soldiers %s t=%d trapped=%d saved=%d lost=%d crushed=%d" % [which, 20 + 5 * (k + 1),
					crowd.rescue.trapped.size(), crowd.rescue.rescued, crowd.rescue.died, dead - crowd.rescue.died])


func _nearest_citizen(at: Vector2) -> Vector2:
	var best := INF
	var near := at
	for p: Person in mission._crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) < best:
			best = p.ground_pos.distance_to(at)
			near = p.ground_pos
	return near


## What the power is doing halfway through its clip, for the record.
func _clip_report(key: String, at: Vector2, t: float) -> void:
	var crowd: Crowd = mission._crowd
	var near := 0
	var watching := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and p.ground_pos.distance_to(at) <= 2.5:
			near += 1
			if p.mind == Person.Mind.OBSERVE:
				watching += 1
	var queues := []
	for g in mission._town.gates:
		queues.append(crowd.waiting_at(g) if g.walkable else -1)
	var confused := 0
	for p: Person in crowd.citizens:
		if is_instance_valid(p) and p.mind == Person.Mind.CONFUSED:
			confused += 1
	print("BEHAVIOUR clip %s t=%.1f within 2.5: %d citizens, %d watching; confused=%d sick=%d plague_dead=%d alarm=%.1f threats=%d queues(main,side,postern)=%s escaped=%d" % [
		key, t, near, watching, confused, crowd.plague.sick.size() if crowd.plague != null else 0,
		crowd.plague.deaths if crowd.plague != null else 0, crowd.alarm, crowd.threats.active_count(), queues,
		crowd.escaped_count])


func _fire(shots: bool) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	var lit := 0
	for st in mission._bf.ctx.env.structures():
		if lit < 3 and st.kind == Structure.Kind.HOUSE and st.role == &"house" and st.center().distance_to(Vector2(-12, 3)) < 3.5:
			crowd.fires.ignite(st, 0.4)
			lit += 1
	var t := 0.0
	for mark in [2.0, 5.0, 10.0, 15.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		var parts := []
		var crew := 0
		for st in crowd.fires.fires.keys():
			parts.append("%.2f" % crowd.fires.intensity(st))
			crew += (crowd.fires.fires[st].responders as Array).size()
		var assisting := 0
		for p: Person in crowd.citizens:
			if is_instance_valid(p) and p.mind == Person.Mind.ASSIST:
				assisting += 1
		print("BEHAVIOUR fire t=%d fires=%d intensity=[%s] responders=%d stage=%s" % [roundi(t), crowd.fires.fires.size(),
			", ".join(parts), assisting, crowd.alarms.stage_name()])
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 1.0
			bf.camera.position = Iso.ground_to_screen(Vector2(-12, 2.5)).round()
			await _frames(2)
			await bf.save_capture("behaviour_fire.png")


func _gates(hazard: bool, shots := false) -> void:
	await _frames(20 * 60)
	var crowd: Crowd = mission._crowd
	crowd.alarms.bell_rung = true
	crowd.alarms.update(AlarmManager.CITY_ALARM, 0, crowd._clock)
	crowd.alarms._city_at = crowd._clock - AlarmManager.REGROUP_SECONDS
	crowd.add_alarm(100.0)
	var t := 0.0
	var placed := false
	for mark in [1.0, 5.0, 6.0, 10.0, 20.0, 30.0, 40.0]:
		await _frames(roundi((mark - t) * 60.0))
		t = mark
		if hazard and not placed and t >= 5.0:
			placed = true
			crowd.threats.register(Vector2(2.7, 11.5), 2.5, 0.8, 60.0, 8.0, 12.0, &"test")
		var by_exit := {}
		var rerouting := 0
		for p: Person in crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD or p.mind != Person.Mind.FLEE:
				continue
			var k := "south" if p.goal() == TownLayout.EXITS[0] else ("east" if p.goal() == TownLayout.EXITS[1] else "none")
			by_exit[k] = int(by_exit.get(k, 0)) + 1
			if p.intent() == Person.Intent.REROUTE:
				rerouting += 1
		var queues := []
		for g in crowd.evac.gates:
			queues.append(crowd.waiting_at(g))
		if shots and t == 10.0:
			var bf: Battlefield = mission._bf
			bf.camera.zoom = Vector2.ONE * 0.6
			bf.camera.position = Iso.ground_to_screen(Vector2(6.0, 9.0)).round()
			await _frames(2)
			await bf.save_capture("behaviour_gates.png")
		print("BEHAVIOUR gates t=%d by exit %s rerouting=%d queues(main,side)=%s escaped=%d" % [roundi(t), by_exit,
			rerouting, queues, crowd.escaped_count])


## The judgement scenario's targets, cast in turn (v0.08): a ring closing on the Citadel.
const JUDGEMENT_TARGETS := [Vector2(-9.0, -11.0), Vector2(0.8, 2.2), Vector2(-12.0, 1.0), Vector2(-4.0, -6.0),
	TownLayout.CITADEL_ORIGIN, Vector2(-6.0, -12.0), Vector2(4.0, -4.0), Vector2(-10.5, -8.0)]
## A cap on the judgement scenario's frames, so a run ends even if the mission does not: twice the mission's clock.
const JUDGEMENT_MAX_FRAMES := int(Rules.MISSION_SECONDS * 2.0 * 60.0)


## Written only against what exists both before and after v0.08 M2 (refusal(), cast(), loadout, an optional `dp`),
## so the same scenario measures both sides of the change. `t` is game time, the mission's own seconds: a hit's
## hit-stop slows Engine.time_scale, so counting frames alone would run ahead of the mission's clock.
func _judgement() -> void:
	var rules: Rules = mission._rules
	var town: Town = mission._town
	var fell_at := -1.0
	var next := 0
	var t := 0.0
	var frames := 0
	var report_at := 30.0
	var rich := Battlefield.arg_value(OS.get_cmdline_user_args(), "--aim") == "rich"
	var acts := _watch_idle(rules)
	print("BEHAVIOUR judgement start aim=%s %s" % ["rich" if rich else "ring", _budget(rules, FINALE_SLOTS, FINALE_DP)])
	while not rules.finished and frames < JUDGEMENT_MAX_FRAMES:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t < 5.0 or frames % 6 != 0:
			continue
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = _richest(rules, mission._bf.ctx.env, mission._crowd) if rich \
					else JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()]
				next += 1
				rules.cast(slot, at, {"dir": Vector2(0.2, 1.0).normalized()})
				break
		if fell_at < 0.0 and town.citadel.is_fallen():
			fell_at = t
		if t >= report_at:
			report_at += 30.0
			print("BEHAVIOUR judgement t=%d citadel=%d%% stability=%d%% escaped=%d buildings=%d stage=%s" % [
				roundi(t), roundi(town.citadel.fraction() * 100.0), roundi(rules.stability.total() * 100.0),
				mission._crowd.escaped_count, rules.buildings_down, mission._crowd.alarms.stage_name()])
	if fell_at < 0.0 and town.citadel.is_fallen():
		fell_at = t
	var dp_left: Variant = rules.get("dp")
	print("BEHAVIOUR judgement end t=%.1f citadel_fell=%.1f won=%s reason=%s time=%.1f escaped=%d buildings=%d score=%d rank=%s dp_left=%s idle=%.0f" % [
		t, fell_at, rules.won, rules.over_reason, t, mission._crowd.escaped_count, rules.buildings_down, rules.score(),
		rules.rank(), str(dp_left), _idle_now(rules, acts)])


## The warning scenario's loadout for each case (v0.08 M5). "none" drafts Mind Whisper and never casts it: an empty
## loadout would fall back to the mission's default, and the HUD has no look for an empty slot.
const WARNING_CASES := {"none": ["whisper"], "doom": ["doom"], "whisper": ["whisper"], "discord": ["discord"],
	"mix": ["whisper", "discord", "doom"], "toll": ["whisper", "discord", "doom"]}
## How far straight back toward the gate the whisper sends the messenger.
const WARNING_WHISPER_BACK := 8.0


## Nobody living would see `p` die (Silent Doom's witness rule), for the miras and prayers policies.
func crowd_alone(p: Person) -> bool:
	return mission._crowd.nearest_witness(p.ground_pos, p) == null


## Mira's House (v0.10 M2), played by a simple policy with Mind Whisper, Silent Doom and Discord: every tenth of a
## second, a report on its way is stopped first -- Silent Doom on a carrier nobody would see die, else a whisper sending
## them away from the Temple, else Discord on them --
## then Discord on the nearest Faithful within sight of the door (or walking up to it), else a whisper sending the
## nearest unread grieving citizen in reach to the door. `none` casts nothing. (v0.11 M2: the policy is _faith_night()'s,
## shared with First Prayers; Mira's own numbers are unchanged.)
func _miras(which: String) -> void:
	await _faith_night("miras", which, false)


## First Prayers (v0.11 M2), played as the miras policy plays Mira's House (_faith_night() with `fetch`): a report on its way
## stopped first; then, when the door matters (_prayers_door_matters()), a Faithful by it dealt with -- Silent Doom if no one
## would see him fall, else Discord, else a whisper sending him away; then, the door unwatched, a whisper sending the nearest of
## the poor (not praying, not a Believer, not shaking a whisper off) toward the door, at most REACH at a time: the last hop only
## when _prayers_ready(), and while someone prays only from PRAYERS_FAR off. `none` casts nothing.
func _prayers(which: String) -> void:
	await _faith_night("prayers", which, true)


## The Faith missions' shared scenario (v0.11 M2): the policy of Mira's House (v0.10 M2) played every LOOK_FRAMES by
## _faith_look(), with `fetch` for First Prayers' poor, who must be walked to the door from afar, one at a time. First Prayers
## prints each cast; the result line adds the longest stretch between two casts of the scripted player as `idle` (the
## no-waiting rule: 45 s or less).
func _faith_night(label: String, which: String, fetch: bool) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as MirasHouseDirector
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	var acts := {"last": 0.0, "longest": 0.0}
	var watched := 0
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		watched += 1 if d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) != null else 0
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR %s t=%d believers=%d inside=%d gaze=%d reports=%d" % [label, roundi(t), d.believers_outside(),
				d.inside().size(), roundi(d.gaze.value), d.reports_started])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		var did := _faith_look(rules, slots, d, fetch)
		if did == "":
			continue
		if fetch:
			print("BEHAVIOUR %s t=%.1f %s" % [label, t, did])
		acts.longest = maxf(float(acts.longest), t - float(acts.last))
		acts.last = t
	acts.longest = maxf(float(acts.longest), t - float(acts.last))
	if fetch:
		print("BEHAVIOUR %s the door was watched %d%% of the night" % [label, roundi(100.0 * float(watched) / float(maxi(frames, 1)))])
	print("BEHAVIOUR %s result %s believers=%d gaze=%d reports=%d idle=%.0f" % [label, _outcome(rules), d.believers_outside(),
		roundi(d.gaze.value), d.reports_started, float(acts.longest)])


## One look of the Faith policy (v0.11 M2, Mira's since v0.10): a report on its way stopped first (Silent Doom on a carrier
## nobody would see die, else a whisper sending them away from the Temple, else Discord); then the nearest Faithful within
## SIGHT + 1.5 of the door dealt with (_faith_guard()); then, the door unwatched, a whisper for the nearest of the grieving not yet
## read, to the door: within REACH of it (Mira's), or with `fetch` (First Prayers) from anywhere, at most REACH - 0.5 at a time,
## the whispered and those praying left alone, and the last hop only when _prayers_ready(). What it cast, or "" (a cast the rules
## refuse, or none, is "").
func _faith_look(rules: Rules, slots: Dictionary, d: MirasHouseDirector, fetch: bool) -> String:
	for r: TempleReport in d.reports:
		var c := r.carrier
		if not is_instance_valid(c) or not c.is_alive() or c.mind == Person.Mind.CONFUSED:
			continue
		if _slot_ready(rules, slots, "doom") and crowd_alone(c):
			return "doom a runner to the Temple" if rules.cast(slots.doom, c.ground_pos) != null else ""
		if _slot_ready(rules, slots, "whisper") and not c.shaken() and c.mind != Person.Mind.WHISPERED:
			var away := c.ground_pos + (c.ground_pos - d.temple_door).normalized() * MindWhisperFx.REACH
			return "whisper a runner away from the Temple" if rules.cast(slots.whisper, c.ground_pos, {"target": c, "to": away}) != null \
				else ""
		if _slot_ready(rules, slots, "discord"):
			return "discord a runner to the Temple" if rules.cast(slots.discord, c.ground_pos) != null else ""
	var watcher := d.faithful_seeing(d.door, MirasHouseDirector.SIGHT + 1.5)
	if watcher != null and (not fetch or _prayers_door_matters(d)):
		var guarded := _faith_guard(rules, slots, d, watcher, fetch)
		if guarded != "":
			return guarded
	if d.faithful_seeing(d.door, MirasHouseDirector.SIGHT) != null or not _slot_ready(rules, slots, "whisper"):
		return ""
	var best: Person = null
	for g in d.grieving:
		if not is_instance_valid(g) or not g.is_alive() or g.inside or d.believers.has(g) or g.shaken():
			continue
		if fetch and (g.mind == Person.Mind.WHISPERED or (not d.inside().is_empty() and g.ground_pos.distance_to(d.door) < PRAYERS_FAR)):
			continue
		if not fetch and g.ground_pos.distance_to(d.door) > MindWhisperFx.REACH:
			continue
		if best == null or g.ground_pos.distance_to(d.door) < best.ground_pos.distance_to(d.door):
			best = g
	if best == null:
		return ""
	var to := d.door
	var hop := to - best.ground_pos
	if fetch and hop.length() > MindWhisperFx.REACH - 0.5:
		to = d._walkable(best.ground_pos + hop.normalized() * (MindWhisperFx.REACH - 0.5))
	elif fetch and not _prayers_ready(d):
		return ""
	if rules.cast(slots.whisper, best.ground_pos, {"target": best, "to": to}) == null:
		return ""
	return "whisper one of the poor (%.1f, %.1f) to (%.1f, %.1f)" % [best.ground_pos.x, best.ground_pos.y, to.x, to.y]


## A Faithful `w` by the door, dealt with (v0.11 M2): Discord on him (Mira's). With `fetch` (First Prayers, whose Faithful stay
## few) Silent Doom first when nobody would see him fall, and a whisper sending him away when Discord is not ready. What it
## cast, or "".
func _faith_guard(rules: Rules, slots: Dictionary, d: MirasHouseDirector, w: Person, fetch: bool) -> String:
	if fetch and _slot_ready(rules, slots, "doom") and crowd_alone(w):
		return "doom a Faithful by the door" if rules.cast(slots.doom, w.ground_pos) != null else ""
	if _slot_ready(rules, slots, "discord"):
		return "discord a Faithful by the door" if rules.cast(slots.discord, w.ground_pos) != null else ""
	if fetch and _slot_ready(rules, slots, "whisper") and not w.shaken() and w.mind != Person.Mind.WHISPERED:
		var away := w.ground_pos + (w.ground_pos - d.door).normalized() * (MindWhisperFx.REACH - 0.5)
		return "whisper a Faithful away from the door" if rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": away}) != null \
			else ""
	return ""


## The door matters to the prayers policy (v0.11 M2): a Believer is about to come out (within PRAYERS_EXIT), or nobody prays and
## one of the poor stands within a hop of it, ready to go in. A Faithful by the door is worth a Discord only then.
func _prayers_door_matters(d: MirasHouseDirector) -> bool:
	var left := d.reading_left()
	if left != INF:
		return left <= PRAYERS_EXIT
	for g in d.grieving:
		if is_instance_valid(g) and g.is_alive() and not g.inside and not d.believers.has(g) \
				and g.ground_pos.distance_to(d.door) <= MindWhisperFx.REACH:
			return true
	return false


## The prayers policy sends one of the poor the last hop to the door only when the prayer inside is within PRAYERS_WALK of its end
## (the next waits there and his whisper wears off) and when his prayer would not end with Faithful crowding the door (v0.11 M2):
## in the market's window or the priests' (the director's), counting PRAYERS_WALK for his walk and PRAYERS_SLACK after the window
## for them to leave.
func _prayers_ready(d: MirasHouseDirector) -> bool:
	var left := d.reading_left()
	if left != INF and left > PRAYERS_WALK:
		return false
	var fp := d as FirstPrayersDirector
	if fp == null:
		return true
	var ends := fp.timeline.elapsed() + maxf(PRAYERS_WALK, left if left != INF else 0.0) + fp.read_seconds
	for w: Array in [[FirstPrayersDirector.MARKET_AT, FirstPrayersDirector.MARKET_SECONDS],
			[FirstPrayersDirector.PRIESTS_AT, FirstPrayersDirector.PRIESTS_SECONDS]]:
		if ends >= float(w[0]) and ends <= float(w[0]) + float(w[1]) + PRAYERS_SLACK:
			return false
	return true


## Broken Lanterns (v0.10 M3), played every LOOK_FRAMES the way a careful player would (Task 8). Silent Doom takes the
## bellkeeper once he is called; else, while a shrine drains, the flame-bearer, wherever he is (the flame passes to an
## acolyte, so up to three casts end the relighting). The Heaven Splitter's line breaks every unguarded shrine it
## crosses, so it is laid through two standing shrines when two stand within one line's reach (from their midpoint),
## else on one shrine's centre (its core kills the Knights beside it), turned whichever way crosses the fewest people:
## each seen death feeds the Gaze. The Dragonfire Parade burns a street, so it goes out only when the Splitter's
## cooldown would leave too little night for a shrine to drain, on the standing shrine with the fewest people near.
## `bonus` plays the same, but holds its Ruin off the kneelers' shrine until ten kneel by it (Through the faithful), or
## until dawn is too near to wait. `none` casts nothing.
func _lanterns(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BrokenLanternsDirector
	var crowd: Crowd = mission._crowd
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var acts := _watch_idle(rules)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR lanterns t=%d drained=%d broken=%d relit=%d praying=%d gaze=%d knights=%d" % [roundi(t),
				d.drained_count(), d.drain_left.size(), d.relit, d.praying_count(), roundi(d.gaze.value), d.living_knights()])
		if not which in ["play", "bonus"] or frames % LOOK_FRAMES != 0:
			continue
		if _slot_ready(rules, slots, "doom"):
			var mark := _lantern_doom_target(d, crowd)
			if mark != null:
				rules.cast(slots.doom, mark.ground_pos)
				continue
		if which == "bonus" and d.kneel_shrine != null and not d.kneel_shrine.destroyed \
				and d.kneeling_near() < ThroughFaithfulObjective.NEED and rules.time_left \
				> BrokenLanternsDirector.DRAIN_SECONDS + LANTERN_DRAGON_SPARE + LANTERN_BONUS_SPARE:
			continue
		if _slot_ready(rules, slots, "heaven"):
			var line := _lantern_line(d, crowd)
			if not line.is_empty():
				rules.cast(slots.heaven, line[0], {"dir": line[1]})
				continue
		if _slot_ready(rules, slots, "dragon") and slots.has("heaven") and rules.cooldown_left(int(slots.heaven)) \
				> rules.time_left - BrokenLanternsDirector.DRAIN_SECONDS - LANTERN_DRAGON_SPARE:
			var target := _lantern_target(d, crowd)
			if target != null:
				rules.cast(slots.dragon, target.center())
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR lanterns result won=%s reason=%s time=%.1f drained=%d relit=%d gaze=%d bonus=%s idle=%.0f" % [res.won,
		res.reason, float(res.time), d.drained_count(), d.relit, roundi(d.gaze.value), bonus, _idle_now(rules, acts)])


func _slot_ready(rules: Rules, slots: Dictionary, key: String) -> bool:
	return slots.has(key) and rules.refusal(int(slots[key])) == ""


## A scenario's outcome (v0.11 M2): off the board, how the mission ended; with --board, a held night's main objective counts
## as won, at its own time.
func _outcome(rules: Rules) -> String:
	if rules.main_done:
		return "won=true reason=%s time=%.1f" % [rules._main.reason, rules.main_time]
	var res := rules.result()
	return "won=%s reason=%s time=%.1f" % [res.won, res.reason, float(res.time)]


## The board's night (v0.11 M2, --board): its tier and the wishes heard, printed before the scripted player starts.
func _board_line() -> void:
	var night := mission.descent()
	if night == null:
		return
	var heard := PackedStringArray()
	for w in night.wishes:
		heard.append(w.def.id)
	print("BEHAVIOUR board tier=%d wishes=%s" % [night.tier, ",".join(heard)])


## The bell's state by name, or "none" for a town without one (v0.11 M2 reports).
func _bell_state(crowd: Crowd) -> String:
	return BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none"


## The longest stretch without a cast so far (v0.11.1, tools/dev/gate.sh's idle): `acts` {last, longest} as _scripted() keeps them; call
## before each cast at second `t`.
func _note_act(acts: Dictionary, t: float) -> void:
	acts.longest = maxf(float(acts.longest), t - float(acts.last))
	acts.last = t


## Idle tracking for a scenario that casts through Rules.cast() in its own loops (v0.11.1, lanterns, flame, warning, feast, judgement):
## the stretches between casts, read off Rules.cast_made against the mission clock. Printing only; `_watch_idle(rules)` once, then
## `_idle_now(rules, acts)` for the longest stretch (the last cast to now counts) at the result.
func _watch_idle(rules: Rules) -> Dictionary:
	var acts := {"last": 0.0, "longest": 0.0, "start": rules.time_left}
	rules.cast_made.connect(func(_slot: int, _key: String, _at: Vector2) -> void:
		_note_act(acts, float(acts.start) - rules.time_left))
	return acts


func _idle_now(rules: Rules, acts: Dictionary) -> float:
	return _idle_end(acts, float(acts.start) - rules.time_left)


## The longest idle stretch at the night's end `t` (v0.11.1): counts the stretch since the last cast.
func _idle_end(acts: Dictionary, t: float) -> float:
	return maxf(float(acts.longest), t - float(acts.last))


## Each collector's state by its initial (W waiting, A walking, V visiting, F fleeing, H hiding, S safe, D dead) and leg, in
## order (v0.11 M2 tax reports): "A1 W0 W0".
func _tax_states(d: AssassinateDirector) -> String:
	var out := PackedStringArray()
	for q in d.quarries:
		out.append("%s%d" % ["WAVFHSD"[q.state], q.leg])
	return " ".join(out)


## How long the tax policy waits at the door, since its last cast, before it smokes the next collector out (v0.11.1, R4; 42 s -> 30 s
## in v0.11.2 Task 6: with the awareness rules the third collector's round ended at 244-256 s; a player smokes the door out sooner).
const TAX_SMOKE_AFTER := 30.0


## Where a smoking-out cast lands (v0.11.1): within 3.0 of the counting-house's door (the director's alarm reach is 4), on the side
## with the fewest people within a Silent Doom of it, so the guards at the door are left standing.
func _tax_smoke_spot(d: AssassinateDirector, crowd: Crowd) -> Vector2:
	var best := d.hide_door
	var best_n := 1000
	for k in 8:
		var at := d.hide_door + Vector2.from_angle(TAU * float(k) / 8.0) * 3.0
		var n := 0
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= SilentDoom.RADIUS + 0.2:
					n += 1
		if n < best_n:
			best = at
			best_n = n
	return best


## A Silent Doom cast on `p` now would go unseen (v0.11 M2, the tax policy): everyone else out of doors either falls with him
## (within SilentDoom.RADIUS of him now) or stays beyond Crowd.DOOM_WITNESS (and TAX_MARGIN) of where he falls T_STRIKE later,
## both now and where they will be then (each read along his heading at his pace, as _warning_alone() reads the messenger).
func _tax_unseen(p: Person, crowd: Crowd) -> bool:
	var fall := p.ground_pos + _tax_lead(p)
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if not is_instance_valid(o) or o == p or not o.is_alive() or o.inside:
				continue
			if o.ground_pos.distance_to(p.ground_pos) <= SilentDoom.RADIUS:
				continue
			var reach := Crowd.DOOM_WITNESS + TAX_MARGIN
			if o.ground_pos.distance_to(fall) <= reach or (o.ground_pos + _tax_lead(o)).distance_to(fall) <= reach:
				return false
	return true


## How far `p` walks in a Silent Doom's T_STRIKE (v0.11 M2): along his heading at his pace while he has somewhere to go.
func _tax_lead(p: Person) -> Vector2:
	return _warning_heading(p) * p.walk_speed * SilentDoom.T_STRIKE if p.has_goal() else Vector2.ZERO


## A report suffix for a Lantern night (v0.11.2): the stage, the rate and the Bearer, or "" with no Lantern.
func _lantern_state(rules: Rules) -> String:
	var lw := rules.lantern
	if lw == null:
		return ""
	var who := "-"
	if lw.bearer != null:
		who = "%s%s" % ["WBVD"[lw.bearer.state], "+%d" % lw.bearer.relays if lw.bearer.relays > 0 else ""]
	return " lantern=%s x%.1f bearer=%s" % [LanternWatch.Stage.keys()[lw.stage], rules.clock_rate, who]


## The Tax Collector (v0.11 M2), played every LOOK_FRAMES: Silent Doom on the bellkeeper once he is called (a seen death
## elsewhere would ring the bell); else, for the first collector in the street with nobody but those within SilentDoom.RADIUS
## of him (who fall with him) near enough to see, Silent Doom on him; else, for the first with one lone onlooker -- a citizen,
## not shaking off a whisper -- that onlooker whispered six units away from him. `none` casts nothing.
func _tax(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as AssassinateDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	var acts := {"last": 0.0, "longest": 0.0}
	if which == "toll":
		crowd.bell.call_keeper()  # v0.11.2 (D32): the town's bellkeeper is called at the start and the bell tolls; the policy acts from the toll on
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR tax t=%d states=%s killed=%d witnesses=%d bell=%s%s" % [roundi(t), _tax_states(d), d.killed(),
				d.witnesses().size(), _bell_state(crowd), _lantern_state(rules)])
		if not _acts(which, rules) or frames % LOOK_FRAMES != 0:
			continue
		var held := _watch_bearer_act(rules, slots, crowd)
		if held != "":
			print("BEHAVIOUR tax t=%.1f %s" % [t, held])
			_note_act(acts, t)
			continue
		var bell := crowd.bell
		if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] \
				and WarningDirector._alive(bell.keeper) and _slot_ready(rules, slots, "doom"):
			_note_act(acts, t)
			rules.cast(slots.doom, bell.keeper.ground_pos)
			continue
		# v0.11.1 (R4, the no-waiting rule): between a death and the next collector's setting out, a power cast by the counting-house's
		# door smokes him out (the mission's own rule). A player does not stand watching a door, so the policy does it once
		# TAX_SMOKE_AFTER seconds have passed since its last cast.
		if d.killed() > 0 and not d._anyone_out() and d._next_waiting() != null and t - float(acts.last) >= TAX_SMOKE_AFTER \
				and _slot_ready(rules, slots, "doom"):
			var spot := _tax_smoke_spot(d, crowd)
			print("BEHAVIOUR tax t=%.1f doom at the door, smoking out %s" % [t, d._next_waiting().label])
			_note_act(acts, t)
			rules.cast(slots.doom, spot)
			continue
		for q in d.quarries:
			if q.dead or not WarningDirector._alive(q.target) or q.target.inside:
				continue
			var seeing := d.witnesses(q)
			if _tax_unseen(q.target, crowd):
				if _slot_ready(rules, slots, "doom"):
					print("BEHAVIOUR tax t=%.1f doom %s" % [t, q.label])
					_note_act(acts, t)
					rules.cast(slots.doom, q.target.ground_pos)
					break
				continue
			if seeing.size() == 1 and not seeing[0].soldier and not seeing[0].shaken() and _slot_ready(rules, slots, "whisper"):
				var lone := seeing[0]
				var away := lone.ground_pos + (lone.ground_pos - q.target.ground_pos).normalized() * 6.0
				_note_act(acts, t)
				rules.cast(slots.whisper, lone.ground_pos, {"target": lone, "to": away})
				break
	var r := d.report()
	print("BEHAVIOUR tax result %s states=%s killed=%d seen=%d alarms=%d target=%s idle=%.0f" % [_outcome(rules), _tax_states(d),
		int(r.killed), int(r.seen), int(r.alarms), String(r.target), _idle_end(acts, t)])


## Spoiled Harvest (v0.11 M2, Task 3 fix round 2: watchmen, grain arriving one granary at a time), played every LOOK_FRAMES.
## The granaries with their grain in, fewest loads first, the first that can be acted on: a watchman on guard, Silent Doom on
## him; none on guard and it not alight, Ember on it. With nothing else to do, the next granary whose grain is due within
## HARVEST_PRE: Silent Doom on a watchman of its on guard (cleared much earlier, a relief walks in). With nothing else, a granary
## down to two loads or fewer, Silent Doom on its carter nearest his door who is walking to it (empty-handed). `none` casts
## nothing.
func _harvest(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as HarvestDirector
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	var acts := {"last": 0.0, "longest": 0.0}
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR harvest t=%d granaries=%s spoiled=%d" % [roundi(t), _harvest_states(d), d.razed_count()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		var order := d.targets.duplicate()
		order.sort_custom(func(a: Structure, b: Structure) -> bool: return int(d.loads[a]) < int(d.loads[b]))
		var cast := false
		for s: Structure in order:
			if d.razed(s) or not d.has_grain(s):
				continue
			var name := String(HarvestDirector.STORE_NAMES[d.targets.find(s)])
			if d.guarding(s):
				if _slot_ready(rules, slots, "doom"):
					print("BEHAVIOUR harvest t=%.1f doom a watchman of the %s granary" % [t, name])
					_note_act(acts, t)
					rules.cast(slots.doom, d.guards(s)[0].ground_pos)
					cast = true
					break
			elif not d.burning(s) and _slot_ready(rules, slots, "ember"):
				print("BEHAVIOUR harvest t=%.1f ember the %s granary" % [t, name])
				_note_act(acts, t)
				rules.cast(slots.ember, s.center())
				cast = true
				break
		if not cast and _slot_ready(rules, slots, "doom"):
			for s: Structure in order:
				if not d.razed(s) and not d.has_grain(s) and d.grain_left(s) <= HARVEST_PRE and d.guarding(s):
					print("BEHAVIOUR harvest t=%.1f doom a watchman of the %s granary (grain in %.0f s)" % [t,
						HarvestDirector.STORE_NAMES[d.targets.find(s)], d.grain_left(s)])
					_note_act(acts, t)
					rules.cast(slots.doom, d.guards(s)[0].ground_pos)
					cast = true
					break
		if cast or not _slot_ready(rules, slots, "doom"):
			continue
		for s in order:
			if d.razed(s) or not d.has_grain(s) or int(d.loads[s]) > 2:
				continue
			var mark: Person = null
			for c: Variant in d.carters[s]:
				if WarningDirector._alive(c) and not d._hauling.has((c as Person).get_instance_id()) \
						and (mark == null or (c as Person).ground_pos.distance_to(d.doors[s]) < mark.ground_pos.distance_to(d.doors[s])):
					mark = c
			if mark != null:
				_note_act(acts, t)
				rules.cast(slots.doom, mark.ground_pos)
				break
	print("BEHAVIOUR harvest result %s spoiled=%d emptied=%s idle=%.0f" % [_outcome(rules), d.razed_count(), d.emptied != null, _idle_end(acts, t)])


## Each granary's state for the harvest reports (v0.11 M2): x spoiled; else its loads left (e for an empty one waiting for its
## grain), then how many watchmen are on guard and how many are away ("2" or "1+1"), then * while it burns: "5:2,e:1+1,e:2".
func _harvest_states(d: HarvestDirector) -> String:
	var out := PackedStringArray()
	for s in d.targets:
		if d.razed(s):
			out.append("x")
			continue
		var on := d.guards(s).size()
		var off := d.watchmen(s).size() - on
		out.append("%s:%d%s%s" % [str(int(d.loads[s])) if d.has_grain(s) else "e", on, "+%d" % off if off > 0 else "",
			"*" if d.burning(s) else ""])
	return ",".join(out)


## The Lost Lamb (v0.11 M2), played every LOOK_FRAMES: held, Discord on his seizer (turned, he lets go), else Silent Doom on
## him -- once he has fallen LAMB_CLEAR beyond its radius behind the seizer, or the cast would take him too; else Discord on the
## nearest soldier set to watch for him within SIGHT + LAMB_WARN; else, whenever Mind Whisper is ready and he is not shaking one
## off, a whisper (see _lamb_act()): through the gate once the watch is away or gone, else toward LAMB_WAIT short of the gate's
## mouth, at most REACH at a time. `none` casts nothing. The result line counts the longest stretch between two casts of the
## scripted player as `idle` (the no-waiting rule: 45 s or less), and each report says who seized him and where.
func _lamb(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as EscortDirector
	var slots := _slots(rules)
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	var wait_at := d._walkable(d.gate_at + LAMB_WAIT)
	var acts := {"last": 0.0, "longest": 0.0}
	var seized := 0
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if d.seizures != seized and WarningDirector._alive(d.seizer) and WarningDirector._alive(d.charge):
			seized = d.seizures
			print("BEHAVIOUR lamb t=%.1f seized by %s at (%.1f, %.1f), %.1f from the Temple" % [t, _lamb_who(d, d.seizer),
				d.charge.ground_pos.x, d.charge.ground_pos.y, d.charge.ground_pos.distance_to(d.return_to)])
		if t >= report_at:
			report_at += 10.0
			var gap := d.charge.ground_pos.distance_to(d.gate_at) if WarningDirector._alive(d.charge) else -1.0
			print("BEHAVIOUR lamb t=%d held=%s seizures=%d gate=%.1f watch_away=%s hunters=%d" % [roundi(t), d.held, d.seizures,
				gap, d.watch_away, d.hunters.size()])
		if which != "play" or frames % LOOK_FRAMES != 0 or not WarningDirector._alive(d.charge):
			continue
		var lamb := d.charge
		var did := ""
		if lamb.inside:
			continue
		if d.held and WarningDirector._alive(d.seizer):
			var s := d.seizer as Person
			if _slot_ready(rules, slots, "discord"):
				rules.cast(slots.discord, s.ground_pos)
				did = "discord his seizer"
			elif _slot_ready(rules, slots, "doom") and lamb.ground_pos.distance_to(s.ground_pos) > SilentDoom.RADIUS + LAMB_CLEAR:
				rules.cast(slots.doom, s.ground_pos)
				did = "doom his seizer"
		else:
			did = _lamb_act(rules, slots, d, lamb, wait_at)
		if did != "":
			print("BEHAVIOUR lamb t=%.1f %s (he is %.1f, %.1f)" % [t, did, lamb.ground_pos.x, lamb.ground_pos.y])
			acts.longest = maxf(float(acts.longest), t - float(acts.last))
			acts.last = t
	acts.longest = maxf(float(acts.longest), t - float(acts.last))
	print("BEHAVIOUR lamb result %s seizures=%d out=%s idle=%.0f" % [_outcome(rules), d.seizures, d.escaped, float(acts.longest)])


## Which of the director's soldiers `v` is, for the Lost Lamb reports (v0.11 M2): "watch", "patrol 1" (the first beat), "searcher".
func _lamb_who(d: EscortDirector, v: Variant) -> String:
	if d.watch.has(v):
		return "the watch"
	if d.hunters.has(v):
		return "a searcher"
	for k in d.patrols.size():
		if (d.patrols[k] as Array).has(v):
			return "patrol %d" % (k + 1)
	return "a soldier"


## One look of the Lost Lamb policy with him free (v0.11 M2): what it cast, or "". Discord on the nearest soldier about to see him,
## else a whisper for him: while he is whispered, only once he is within LAMB_AHEAD of where he was sent (so the next whisper
## carries him on without a stop, and without the shake-off that follows a whisper let run out). It sends him through the gate
## once the watch is away or gone, else toward LAMB_WAIT (`wait_at`) short of it.
func _lamb_act(rules: Rules, slots: Dictionary, d: EscortDirector, lamb: Person, wait_at: Vector2) -> String:
	var threat: Person = null
	for v: Variant in d._watchers():
		if not d._watching(v):
			continue
		var p := v as Person
		if d.watch.has(p) and d.watch_away:
			continue
		var gap := p.ground_pos.distance_to(lamb.ground_pos)
		if gap <= EscortDirector.SIGHT + LAMB_WARN and (threat == null or gap < threat.ground_pos.distance_to(lamb.ground_pos)):
			threat = p
	if threat != null and _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, threat.ground_pos)
		return "discord a soldier about to see him"
	if not _slot_ready(rules, slots, "whisper") or lamb.shaken():
		return ""
	if lamb.mind == Person.Mind.WHISPERED and lamb.goal() != Vector2.INF and lamb.ground_pos.distance_to(lamb.goal()) > LAMB_AHEAD:
		return ""
	var near_gate := lamb.ground_pos.distance_to(d.gate_at) <= EscortDirector.NEAR_GATE
	var to := wait_at
	if near_gate and (d.watch_away or not d._watch_standing()):
		to = d.exit_at
	elif lamb.ground_pos.distance_to(wait_at) <= 1.0:
		return ""
	var hop := to - lamb.ground_pos
	if hop.length() > MindWhisperFx.REACH - 0.5:
		to = d._walkable(lamb.ground_pos + hop.normalized() * (MindWhisperFx.REACH - 0.5))
	rules.cast(slots.whisper, lamb.ground_pos, {"target": lamb, "to": to})
	return "whisper him to (%.1f, %.1f)" % [to.x, to.y]


## Whether the scripted player acts this look under `which` (v0.11.2, D32): `play` always; `toll` from the toll on (LanternWatch.tolled), when
## it plays as `play` does -- the policy waits for the toll on purpose, so the toll case shows what a night is like after it; `none` never.
func _acts(which: String, rules: Rules) -> bool:
	if which == "play":
		return true
	return which == "toll" and rules.lantern != null and rules.lantern.tolled


## The Lantern-Bearer on a watch night (v0.11.2, Task 16): what the scripted player casts at the three on the errand, or "" for nothing. Kill the
## Bearer -- that blinds the Lantern -- but an escort living, unheld and within LanternBearer.ESCORT_SEE of him would take the flame up where he
## falls, so first hold that escort (Mind Whisper sends him off; else Discord holds him), else kill him (Silent Doom); once none stands near,
## Silent Doom on the Bearer. Never while the Lantern is Blind or the Bearer is not out. Loadout A's (tax, informer) policy; B's tax Smite is too
## scarce to spend on him (tried: seed 1 then loses a collector to the Citadel, seed 2 slips to 267 s), so route b plays on as before.
func _watch_bearer_act(rules: Rules, slots: Dictionary, crowd: Crowd) -> String:
	var lw := rules.lantern
	if lw == null or lw.stage == LanternWatch.Stage.BLIND or lw.bearer == null or lw.bearer.dead():
		return ""
	var b := lw.bearer
	if b.state != LanternBearer.State.WALKING and b.state != LanternBearer.State.VIGIL:
		return ""
	if not WarningDirector._alive(b.carrier):
		return ""
	var carrier := b.carrier
	var near: Person = null
	if b.state == LanternBearer.State.WALKING:
		for e: Variant in b.escorts:
			if not WarningDirector._alive(e):
				continue
			var p := e as Person
			if p.inside or p.held_by_god() or p.mind in LanternBearer.HELD:
				continue
			if p.ground_pos.distance_to(carrier.ground_pos) <= LanternBearer.ESCORT_SEE + 0.5 \
					and (near == null or p.ground_pos.distance_to(carrier.ground_pos) < near.ground_pos.distance_to(carrier.ground_pos)):
				near = p
	if near == null:
		if _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, carrier.ground_pos)
			return "doom the Lantern-Bearer"
		return ""
	if _slot_ready(rules, slots, "whisper") and not near.shaken():
		var away := near.ground_pos + (near.ground_pos - carrier.ground_pos).normalized() * 4.0
		rules.cast(slots.whisper, near.ground_pos, {"target": near, "to": MindWhisperFx.clamp_to(crowd._grid, near.ground_pos, away)})
		return "whisper an escort off"
	if _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, near.ground_pos)
		return "discord an escort"
	if _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, near.ground_pos)
		return "doom an escort"
	return ""


## A Tier 2 mission's scripted night (v0.11 M3, shared by ringers, panic and informer): its board line; then, until it ends or its
## main objective is done, every LOOK_FRAMES with `play` the policy's move (`act.call()`: what it cast, or ""), printed; a report
## every 10 s (`state.call()`); then the result, with the longest stretch between two casts as `idle` (the gate: 45 s or less).
## `none` casts nothing.
func _scripted(label: String, which: String, act: Callable, state: Callable) -> void:
	var rules: Rules = mission._rules
	_board_line()
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	var acts := {"last": 0.0, "longest": 0.0}
	while not rules.finished and not rules.main_done and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR %s t=%d %s" % [label, roundi(t), String(state.call())])
		if not _acts(which, rules) or frames % LOOK_FRAMES != 0:
			continue
		var did := String(act.call())
		if did != "":
			print("BEHAVIOUR %s t=%.1f %s" % [label, t, did])
			acts.longest = maxf(float(acts.longest), t - float(acts.last))
			acts.last = t
	acts.longest = maxf(float(acts.longest), t - float(acts.last))
	print("BEHAVIOUR %s result %s %s idle=%.0f" % [label, _outcome(rules), String(state.call()), float(acts.longest)])


## The Heart of Faith (v0.11 M6), with mission spec §3's policy (_heart_act()), through _scripted().
func _heart(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as HeartOfFaithDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	var memo := {"hush": -INF}
	await _scripted("heart", which, func() -> String: return _heart_act(rules, slots, d, crowd, memo),
		func() -> String: return "razed=%d flame_out=%s odran=%s riding=%s rite=%.0f gaze=%d phase=%s" % [d.razed_count(), d.flame_out,
			d.odran_out, d.riding, d.rite_left, roundi(d.gaze.value), d.hint_phase()])


## Strikes one of `who` (v0.11 M6, mission spec §3's "Its Gaze"): Silent Doom on the first whose death goes unseen (_doom_unseen()); else,
## with `smite_ok`, Smite on the first unseen; else Mind Whisper sends off the one citizen who would see a strike on one of them
## (_heart_hush(), its time kept in `memo`); else, with `seen_ok` (work that cannot wait: a Knight on guard at the target in use, a bearer,
## his last guard), HEART_SETTLE after the last hush and the Gaze kept within HEART_GAZE_CAP, Silent Doom on the one fewest would see,
## seen. "" when nothing serves.
func _heart_strike(rules: Rules, slots: Dictionary, crowd: Crowd, who: Array[Person], smite_ok: bool, what: String, memo: Dictionary,
		d: HeartOfFaithDirector, seen_ok := false) -> String:
	var now := d._clock
	if who.is_empty():
		return ""
	var doom := _slot_ready(rules, slots, "doom")
	var smite := smite_ok and _slot_ready(rules, slots, "smite")
	if doom or smite:
		for p in who:
			if _doom_unseen(crowd, p.ground_pos):
				rules.cast(slots.doom if doom else slots.smite, p.ground_pos)
				return "%s %s" % ["doom" if doom else "smite", what]
	if (doom or smite) and _slot_ready(rules, slots, "whisper"):
		var did := _heart_hush(rules, slots, crowd, who, what)
		if did != "":
			memo.hush = now
			return did
	var cost := HeartOfFaithDirector.FURY if d.flame_out else HeartOfFaithDirector.SEEN
	if seen_ok and doom and now - float(memo.hush) >= HEART_SETTLE and d.gaze.value + cost <= HEART_GAZE_CAP:
		var best: Person = null
		var fewest := 0
		for p in who:
			var n := _heart_seers(crowd, p).size()
			if best == null or n < fewest:
				best = p
				fewest = n
		rules.cast(slots.doom, best.ground_pos)
		return "doom %s, seen by %d" % [what, fewest]
	return ""


## Everyone alive out of doors but `p` within Crowd.DOOM_WITNESS of the edge of a Silent Doom on him (v0.11 M6): who would see it. Only
## reads.
func _heart_seers(crowd: Crowd, p: Person) -> Array[Person]:
	var out: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if is_instance_valid(o) and o.is_alive() and not o.inside and o != p \
					and o.ground_pos.distance_to(p.ground_pos) <= Crowd.DOOM_WITNESS + SilentDoom.RADIUS:
				out.append(o)
	return out


## Mind Whisper sends off the lone witness of one of `who` (v0.11 M6): the first of them with exactly one other person out of doors who
## would see a strike on him (_heart_seers()), a citizen not shaking off a whisper, sent HEART_HUSH units straight away. "" when none has
## one.
func _heart_hush(rules: Rules, slots: Dictionary, crowd: Crowd, who: Array[Person], what: String) -> String:
	for p in who:
		var seers := _heart_seers(crowd, p)
		if seers.size() != 1 or seers[0].soldier or seers[0].shaken():
			continue
		var w := seers[0]
		var away := w.ground_pos - p.ground_pos
		away = away.normalized() if away.length() > 0.01 else Vector2.RIGHT
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": MindWhisperFx.clamp_to(crowd._grid, w.ground_pos, w.ground_pos + away * HEART_HUSH)})
		return "whisper a witness off %s" % what
	return ""


## One look of The Heart of Faith's policy (v0.11 M6, mission spec §3): what was cast, or "". The first that applies: Odran on foot; his
## rite with no strike ready; his bearers; his last guard; the target in use guarded; the target in use open and not burning; the next
## target's standing Knights within HEART_AHEAD; a relief walking in. Never a blow on a target ahead of its time.
func _heart_act(rules: Rules, slots: Dictionary, d: HeartOfFaithDirector, crowd: Crowd, memo: Dictionary) -> String:
	var afoot := d.odran_out and not d.riding and not d.odran_down() and not (d.odran as Person).inside
	if afoot:
		var o := d.odran as Person
		if _slot_ready(rules, slots, "doom"):  # his death is the win: seen or not
			rules.cast(slots.doom, o.ground_pos)
			return "doom Odran"
		if _slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, o.ground_pos)
			return "smite Odran"
		if d.rite_on and _slot_ready(rules, slots, "whisper") and not o.shaken():
			var off := o.ground_pos + (o.ground_pos - d.temple.center()).normalized() * HEART_OFF
			rules.cast(slots.whisper, o.ground_pos, {"target": o, "to": MindWhisperFx.clamp_to(crowd._grid, o.ground_pos, off)})
			return "whisper Odran off the steps"
	if d.flame_out and (d.riding or not d.odran_out):
		var did := _heart_strike(rules, slots, crowd, d.bearers_standing(), true, "a bearer", memo, d, true)
		if did != "":
			return did
	if afoot:
		var near: Array[Person] = []
		for g in d.last_guards():
			if g.ground_pos.distance_to((d.odran as Person).ground_pos) <= HEART_GUARD:
				near.append(g)
		var did := _heart_strike(rules, slots, crowd, near, true, "his last guard", memo, d, true)
		if did != "":
			return did
	if d.flame_out:
		return ""
	var cur := d.current()
	if cur >= 0:
		var s := d.targets[cur]
		var on := d.guards_at(cur)
		if not on.is_empty():
			var did := _heart_strike(rules, slots, crowd, on, true, "a Knight at the %s" % HeartOfFaithDirector.WORDS[cur], memo, d,
				true)
			if did != "":
				return did
		elif is_instance_valid(s) and not s.destroyed and not d.burning(s):
			if _slot_ready(rules, slots, "ember"):
				rules.cast(slots.ember, s.center())
				return "ember the %s" % HeartOfFaithDirector.WORDS[cur]
			if _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the %s" % HeartOfFaithDirector.WORDS[cur]
	var n := d.next_target()
	if n >= 0 and n != cur and d.stage_due(n) - d._clock <= HEART_AHEAD:
		var did := _heart_strike(rules, slots, crowd, d.standing_at(n), false, "a Knight ahead at the %s" % HeartOfFaithDirector.WORDS[n],
			memo, d)
		if did != "":
			return did
	var walker := d.relief_walking()
	if walker != null:
		var one: Array[Person] = [walker]
		var did := _heart_strike(rules, slots, crowd, one, false, "a relief Knight", memo, d)
		if did != "":
			return did
	return ""


## The Bell-Ringers (v0.11 M3), with mission spec §1's policy (_ringers_act()).
func _ringers(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BellRingersDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("ringers", which, func() -> String: return _ringers_act(rules, slots, d, crowd),
		func() -> String: return "stopped=%d relays=%d running=%d phase=%s bell=%s" % [d.stopped(), int(d.report().relays),
			d.running().size(), d.hint_phase(), _bell_state(crowd)])


## One look of The Bell-Ringers' policy (v0.11 M3, as a player plays it): what was cast, or "" for nothing. The first
## that applies: Silent Doom on the town's bellkeeper once called; Silent Doom on a carrier whose death would go unseen; Silent Doom
## on his mates -- both at once, or one -- where it takes no one else; Mind Whisper sends a mate with him off, or one of one or two
## other witnesses (none a soldier); Mind Whisper sends a carrier left without his mates to a quiet spot (_ringers_quiet()) when
## Silent Doom will be ready as he gets there; Discord on a carrier near the bell's foot or on the rope; and between ringers, the
## next post's door cleared of watchers before its ringer comes out (_ringers_prep()). Never a loud power.
func _ringers_act(rules: Rules, slots: Dictionary, d: BellRingersDirector, crowd: Crowd) -> String:
	var bell := crowd.bell
	var doom := _slot_ready(rules, slots, "doom")
	var whisper := _slot_ready(rules, slots, "whisper")
	if d.called() and doom:
		rules.cast(slots.doom, bell.keeper.ground_pos)
		return "doom the bellkeeper"
	var going: Array[RingerDirector] = []
	for r in d.running():
		if WarningDirector._alive(r.messenger) and not r.messenger.inside:
			going.append(r)
	for r in going:
		if doom and _tax_unseen(r.messenger, crowd):
			rules.cast(slots.doom, r.messenger.ground_pos)
			return "doom the ringer"
	var held := _ringers_hold_herald(rules, slots, d, crowd, going)  # v0.11.2: the bell has tolled -- the ringer who rang has ~21 s, so he is held first
	if held != "":
		return held
	if doom:
		for r in going:
			var pair := r.mates_with()
			if pair.size() >= 2 and pair[0].ground_pos.distance_to(pair[1].ground_pos) <= RINGERS_PAIR:
				var mid := (pair[0].ground_pos + pair[1].ground_pos) * 0.5
				if _ringers_only(crowd, mid, [pair[0], pair[1]]):
					rules.cast(slots.doom, mid)
					return "doom both mates"
			for m in pair:
				if _ringers_only(crowd, m.ground_pos, [m]):
					rules.cast(slots.doom, m.ground_pos)
					return "doom a mate"
	if whisper:
		for r in going:
			for m in r.mates_with():
				if _whisperable(m):
					rules.cast(slots.whisper, m.ground_pos, {"target": m, "to": _ringers_off(d, m, r.messenger.ground_pos)})
					return "whisper a mate off"
		for r in going:
			var seeing := r.witnesses()
			var soldier := false
			var lone: Person = null
			for p in seeing:
				soldier = soldier or p.soldier
				if _whisperable(p) and (lone == null or p.ground_pos.distance_to(r.messenger.ground_pos)
						< lone.ground_pos.distance_to(r.messenger.ground_pos)):
					lone = p
			if seeing.size() <= 2 and not soldier and lone != null:
				rules.cast(slots.whisper, lone.ground_pos, {"target": lone, "to": _ringers_off(d, lone, r.messenger.ground_pos)})
				return "whisper a witness off"
		for r in going:
			if not r.mates_with().is_empty() or not _whisperable(r.messenger) or (bell != null and bell.keeper == r.messenger) \
					or _slot_wait(rules, slots, "doom") > RINGERS_DOOM_SOON:
				continue
			var quiet := _ringers_quiet(d, crowd, r.messenger)
			if quiet != Vector2.INF:
				rules.cast(slots.whisper, r.messenger.ground_pos, {"target": r.messenger, "to": quiet})
				return "whisper the ringer aside to (%.1f, %.1f)" % [quiet.x, quiet.y]
	for r in going:
		if bell != null and (r.messenger.ground_pos.distance_to(bell.foot) <= RINGERS_DISCORD or bell.keeper == r.messenger) \
				and _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, r.messenger.ground_pos)
			return "discord the ringer"
	return _ringers_prep(rules, slots, d, crowd, doom, whisper)


## A Herald running for the Temple (v0.11.2): too little time for the mates to be dealt with first, so he is held at once -- Mind Whisper leads him
## to a quiet spot (or, none within reach, away from the Temple), where it holds a man twice his run; Discord when it is cooling. What was cast, or "".
func _ringers_hold_herald(rules: Rules, slots: Dictionary, d: BellRingersDirector, crowd: Crowd, going: Array[RingerDirector]) -> String:
	for r in going:
		var m := r.messenger
		if not r.herald_open() or m.mind == Person.Mind.WHISPERED or m.mind == Person.Mind.CONFUSED:
			continue
		if _slot_ready(rules, slots, "whisper") and _whisperable(m) and not m.shaken():
			var quiet := _ringers_quiet(d, crowd, m)
			var to := quiet if quiet != Vector2.INF else _ringers_off(d, m, d.lantern_door())
			rules.cast(slots.whisper, m.ground_pos, {"target": m, "to": to})
			return "whisper the Herald to (%.1f, %.1f)" % [to.x, to.y]
		if _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, m.ground_pos)
			return "discord the Herald"
	return ""


## Between ringers (v0.11 M3): the next post's door cleared of watchers in the last RINGERS_PREP seconds before its
## ringer comes out -- a citizen within RINGERS_DOOR_R of it whispered away, else a soldier there struck down by Silent Doom where
## no one sees him fall -- each power only while it will be ready again when he comes out. What was cast, or "".
func _ringers_prep(rules: Rules, slots: Dictionary, d: BellRingersDirector, crowd: Crowd, doom: bool, whisper: bool) -> String:
	var i := d.next_post()
	if i < 0 or not d.running().is_empty():
		return ""
	var due := d.timeline.seconds_to("out_%d" % i)
	if due > RINGERS_PREP:
		return ""
	whisper = whisper and due >= float(PowerBook.get_power("whisper").cooldown)
	doom = doom and due >= float(PowerBook.get_power("doom").cooldown)
	var door := d.doors[i]
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside or p.ground_pos.distance_to(door) > RINGERS_DOOR_R:
				continue
			if whisper and _whisperable(p):
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _ringers_off(d, p, door)})
				return "whisper a watcher off the %s door" % d.post_names[i]
			if doom and p.soldier and _tax_unseen(p, crowd):
				rules.cast(slots.doom, p.ground_pos)
				return "doom a soldier by the %s door" % d.post_names[i]
	return ""


## `p` would take a Mind Whisper now (v0.11 M3): a citizen out of doors, standing, not whispered nor shaking one off.
func _whisperable(p: Person) -> bool:
	return WarningDirector._alive(p) and not p.soldier and not p.inside and not p.shaken() and p.mind != Person.Mind.WHISPERED


## Where Mind Whisper sends `p` off (v0.11 M3): RINGERS_SEND further from `from`, on walkable ground.
func _ringers_off(d: BellRingersDirector, p: Person, from: Vector2) -> Vector2:
	var away := p.ground_pos - from
	return d._walkable(p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * RINGERS_SEND)


## A spot within Mind Whisper's reach of carrier `c` with nobody living out of doors within RINGERS_QUIET_CLEAR of it (v0.11 M3):
## of RINGERS_QUIET_DIRS directions at each of RINGERS_QUIET_R, one his walk reaches within the reach too (not round a wall), the
## one farthest from the bell's foot; Vector2.INF for none.
func _ringers_quiet(d: BellRingersDirector, crowd: Crowd, c: Person) -> Vector2:
	var best := Vector2.INF
	for rad: float in RINGERS_QUIET_R:
		for k in RINGERS_QUIET_DIRS:
			var g := d._walkable(c.ground_pos + Vector2.from_angle(TAU * float(k) / float(RINGERS_QUIET_DIRS)) * rad)
			if g.distance_to(c.ground_pos) > MindWhisperFx.REACH - 0.5 or not _ringers_empty(crowd, g, c) \
					or _walk_len(crowd, c.ground_pos, g) > MindWhisperFx.REACH:
				continue
			if best == Vector2.INF or g.distance_to(crowd.bell.foot) > best.distance_to(crowd.bell.foot):
				best = g
	return best


## The length of the walk grid's way from `from` to `to` (v0.11 M3); INF with no way.
func _walk_len(crowd: Crowd, from: Vector2, to: Vector2) -> float:
	var path := crowd._grid.path(from, to)
	if path.is_empty():
		return INF
	var n := 0.0
	var at := from
	for q in path:
		n += at.distance_to(q)
		at = q
	return n


## Nobody living out of doors but `c` stands within RINGERS_QUIET_CLEAR of `at` (v0.11 M3).
func _ringers_empty(crowd: Crowd, at: Vector2, c: Person) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p != c and p.is_alive() and not p.inside \
					and p.ground_pos.distance_to(at) <= RINGERS_QUIET_CLEAR:
				return false
	return true


## Seconds until the power `key` is ready again (v0.11 M3): 0 when ready, INF when not drafted.
func _slot_wait(rules: Rules, slots: Dictionary, key: String) -> float:
	if not slots.has(key):
		return INF
	return rules.cooldown_left(int(slots[key]))


## Everyone a Silent Doom at `at` would take is one of `who` (v0.11 M3: both mates, and no one else).
func _ringers_only(crowd: Crowd, at: Vector2, who: Array) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= SilentDoom.RADIUS \
					and not who.has(p):
				return false
	return true


## Market Panic (v0.11 M3), with mission spec §2's policy (_panic_act()), through _scripted().
func _panic(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as MarketPanicDirector
	var slots := _slots(rules)
	await _scripted("panic", which, func() -> String: return _panic_act(rules, slots, d),
		func() -> String: return "broken=%d/%d wardens=%d walkers=%d phase=%s" % [d.count(), d.need, d.on_guard().size(),
			d.walkers().size(), d.hint_phase()])


## One look of Market Panic's policy (v0.11 M3): what was cast, or "" for nothing. The first that applies: Silent Doom on a warden
## on guard who steadies PANIC_WARD_CROWD or more goers; Heaven Splitter through the fair, or along the walkers, but only once no
## crowd is still to come (Task 3's rule: a loud splitter into the first crowd brought the Organized town's evacuation, which then
## sent the goers off duty out of the town unbroken, and free of it the same runs lost at 35 of 36; the final review keeps every
## goer in the town, and the rule stands as tuned); Smite on the densest knot of PANIC_KNOT or more
## goers no warden steadies; Smite on the goer nearest the fountain (a bolt kills whoever it strikes, steadied or not); and Silent
## Doom on a warden on guard, to clear the cover before the next crowd.
func _panic_act(rules: Rules, slots: Dictionary, d: MarketPanicDirector) -> String:
	if d.timeline.elapsed() < PANIC_SETTLE:
		return ""
	var wardens := d.on_guard()
	if _slot_ready(rules, slots, "doom"):
		for w in wardens:
			if _panic_near(d, w.ground_pos, MarketPanicDirector.WARD_R).size() >= PANIC_WARD_CROWD:
				rules.cast(slots.doom, w.ground_pos)
				return "doom a warden"
	if d.next_wave() < 0 and _slot_ready(rules, slots, "heaven"):
		var best := -1
		var best_dir := Vector2.RIGHT
		if wardens.is_empty() and _panic_near(d, MarketPanicDirector.HEART, MarketPanicDirector.FAIR_R).size() >= PANIC_PACK:
			for dir: Vector2 in [Vector2.RIGHT, Vector2.DOWN]:
				var n := _panic_lane(d, d.unbroken(), MarketPanicDirector.HEART, dir)
				if n > best:
					best = n
					best_dir = dir
			rules.cast(slots.heaven, MarketPanicDirector.HEART, {"dir": best_dir})
			return "heaven through the fair (%d)" % best
		var walkers := d.walkers()
		if walkers.size() >= PANIC_WALKERS:
			var centre := Vector2.ZERO
			for p in walkers:
				centre += p.ground_pos
			centre /= float(walkers.size())
			for k in PANIC_DIRS:
				var dir := Vector2.RIGHT.rotated(TAU * float(k) / float(PANIC_DIRS))
				var n := _panic_lane(d, walkers, centre, dir)
				if n > best:
					best = n
					best_dir = dir
			if best >= PANIC_WALKERS:
				rules.cast(slots.heaven, centre, {"dir": best_dir})
				return "heaven on the walkers (%d)" % best
	if _slot_ready(rules, slots, "smite"):
		var at := _panic_knot(d)
		if at != Vector2.INF:
			rules.cast(slots.smite, at)
			return "smite a knot"
		var left := d.unbroken()
		if not left.is_empty():
			left.sort_custom(func(a: Person, b: Person) -> bool:
				return a.ground_pos.distance_to(MarketPanicDirector.HEART) < b.ground_pos.distance_to(MarketPanicDirector.HEART))
			rules.cast(slots.smite, left[0].ground_pos)
			return "smite a goer"
	if _slot_ready(rules, slots, "doom") and not wardens.is_empty():
		rules.cast(slots.doom, wardens[0].ground_pos)
		return "doom a warden to clear the way"
	return ""


## The goers still to break within `r` of `at` (v0.11 M3).
func _panic_near(d: MarketPanicDirector, at: Vector2, r: float) -> Array[Person]:
	var out: Array[Person] = []
	for p in d.unbroken():
		if p.ground_pos.distance_to(at) <= r:
			out.append(p)
	return out


## How many of `who` a Heaven Splitter laid at `origin` along `dir` would break (v0.11 M3): those no warden steadies, within its
## danger as FestivalDirector._on_danger() judges it (each lane point's Crowd._cast_radius() plus Person.THREAT_MARGIN).
func _panic_lane(d: MarketPanicDirector, who: Array[Person], origin: Vector2, dir: Vector2) -> int:
	var radius := Crowd._cast_radius("heaven")
	var a: Dictionary = Targeting.AREAS["heaven"]
	var points := Crowd.cast_points(Targeting.lane_start("heaven", origin, dir), dir, float(a.length), radius)
	var reach := radius + Person.THREAT_MARGIN
	var n := 0
	for p in who:
		if d.steadied(p):
			continue
		for point in points:
			if p.ground_pos.distance_to(point) <= reach:
				n += 1
				break
	return n


## The goer at the heart of the densest knot of PANIC_KNOT or more goers no warden steadies, all within Smite's danger of him (v0.11
## M3); Vector2.INF for none.
func _panic_knot(d: MarketPanicDirector) -> Vector2:
	var reach := Crowd._cast_radius("smite") + Person.THREAT_MARGIN
	var free: Array[Person] = []
	for p in d.unbroken():
		if not d.steadied(p):
			free.append(p)
	var best := Vector2.INF
	var best_n := PANIC_KNOT - 1
	for a in free:
		var n := 0
		for b in free:
			n += 1 if b.ground_pos.distance_to(a.ground_pos) <= reach else 0
		if n > best_n:
			best_n = n
			best = a.ground_pos
	return best


## The Informer (v0.11 M3), with mission spec §3's policy (_informer_act()), through _scripted().
func _informer(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as InformerDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	if which == "toll":
		crowd.bell.call_keeper()  # v0.11.2 (D32): the bellkeeper is called at the start and the bell tolls; the policy acts from the toll on
	await _scripted("informer", which, func() -> String:
			var held := _watch_bearer_act(rules, slots, crowd)
			return held if held != "" else _informer_act(rules, slots, d, crowd),
		func() -> String: return "turned=%d found=%s cold=%s phase=%s bell=%s%s" % [d.turned_count(), d.found, d.cold, d.hint_phase(),
			_bell_state(crowd), _lantern_state(rules)])


## One look of The Informer's policy (v0.11 M3): what was cast, or "" for nothing. The first that applies: Silent Doom on the town's
## bellkeeper once called; once the informer is found and out of doors, Silent Doom on him when the kill would go unseen (or
## whatever the witnesses within INFORMER_LAST of the Temple's door), never while a contact stands close enough to fall with him;
## with word at the contact: no onlooker, Mind Whisper on him (it turns him); else, with Mind Whisper and Discord both ready and one
## Discord holding every onlooker, Discord there (the whisper follows on the next look); else Mind Whisper sends one onlooker off
## (_informer_off()); and in the INFORMER_EARLY seconds before his visit, his company and those standing by him sent off one at a
## time while Mind Whisper will be ready again when word comes. It never strikes a contact.
func _informer_act(rules: Rules, slots: Dictionary, d: InformerDirector, crowd: Crowd) -> String:
	var bell := crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] and WarningDirector._alive(bell.keeper) \
			and bell.keeper.profile != null and bell.keeper.profile.role == CitizenProfile.Role.BELLKEEPER and _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, bell.keeper.ground_pos)
		return "doom the bellkeeper"
	if d.found:
		var q := d.quarries[0]
		if WarningDirector._alive(q.target) and not q.target.inside and _slot_ready(rules, slots, "doom") \
				and not _informer_takes_contact(d, q.target) \
				and (_tax_unseen(q.target, crowd) or q.target.ground_pos.distance_to(d.safe_at) <= INFORMER_LAST):
			rules.cast(slots.doom, q.target.ground_pos)
			return "doom the informer"
		return ""
	var c := d.contact_now()
	if c == null or not WarningDirector._alive(c.man) or (c.man as Person).inside:
		return ""
	var man := c.man as Person
	var seeing := d.onlookers(c)
	var whisper := _slot_ready(rules, slots, "whisper")
	if c.word:
		if seeing.is_empty():
			if man.shaken() or not whisper:
				return ""
			var to := MindWhisperFx.clamp_to(crowd._grid, man.ground_pos, man.ground_pos + Vector2(INFORMER_OFF, 0.0))
			rules.cast(slots.whisper, man.ground_pos, {"target": man, "to": to})
			return "whisper the %s" % c.trade
		if whisper and not man.shaken() and _slot_ready(rules, slots, "discord"):
			var best := _informer_discord(man, seeing)
			var left: Array[Person] = best[1]
			if left.is_empty():
				rules.cast(slots.discord, best[0])
				return "discord by the %s (%d held)" % [c.trade, seeing.size()]
			if left.size() == 1 and _whisperable(left[0]):
				rules.cast(slots.discord, best[0])
				return "discord by the %s (%d held, one to send off)" % [c.trade, seeing.size() - 1]
		return _informer_off(rules, slots, crowd, seeing, man)
	var due := d.visit_in(d.contacts.find(c))
	if due <= INFORMER_EARLY and due >= float(PowerBook.get_power("whisper").cooldown) and not seeing.is_empty():
		return _informer_off(rules, slots, crowd, seeing, man)
	return ""


## A Silent Doom on the informer now would take a contact with him (v0.11 M3): one stands within SilentDoom.RADIUS of him (and a
## margin for his walk). The policy never strikes a contact, turned or not.
func _informer_takes_contact(d: InformerDirector, at: Person) -> bool:
	for c in d.contacts:
		if WarningDirector._alive(c.man) and (c.man as Person).ground_pos.distance_to(at.ground_pos) <= SilentDoom.RADIUS + 0.3:
			return true
	return false


## Where a Discord holds the most of `seeing` (v0.11 M3): on `man`, on one of them, or midway between two of them; [the point, the
## ones it would leave seeing]. Soldiers keep their heads (DiscordFx.taken()); of two points leaving as many, the one leaving fewer
## a whisper cannot reach (a soldier, or one shaking off a whisper) wins.
func _informer_discord(man: Person, seeing: Array[Person]) -> Array:
	var best := man.ground_pos
	var best_left: Array[Person] = seeing.duplicate()
	var best_stuck := seeing.size() + 1
	var spots: Array[Vector2] = [man.ground_pos]
	for i in seeing.size():
		spots.append(seeing[i].ground_pos)
		for j in range(i + 1, seeing.size()):
			spots.append((seeing[i].ground_pos + seeing[j].ground_pos) * 0.5)
	for at in spots:
		var left: Array[Person] = []
		var stuck := 0
		for p in seeing:
			if p.soldier or p.ground_pos.distance_to(at) > DiscordFx.DISCORD_R - 0.1:
				left.append(p)
				stuck += 0 if _whisperable(p) else 1
		if left.size() < best_left.size() or (left.size() == best_left.size() and stuck < best_stuck):
			best_left = left
			best_stuck = stuck
			best = at
	return [best, best_left]


## Mind Whisper sends one of `seeing` -- not a soldier, not shaking off a whisper -- INFORMER_AWAY units straight away from `man`
## (v0.11 M3): one who stays (his company, or one standing still) before one passing by, the nearest first; "" when none can hear
## it or the slot is not ready.
func _informer_off(rules: Rules, slots: Dictionary, crowd: Crowd, seeing: Array[Person], man: Person) -> String:
	if not _slot_ready(rules, slots, "whisper"):
		return ""
	var lone: Person = null
	var lone_stays := false
	for p in seeing:
		if p.soldier or p.shaken():
			continue
		var stays := p.mind == Person.Mind.DUTY or not p.has_goal()
		var nearer := lone == null or p.ground_pos.distance_to(man.ground_pos) < lone.ground_pos.distance_to(man.ground_pos)
		if lone == null or (stays and not lone_stays) or (stays == lone_stays and nearer):
			lone = p
			lone_stays = stays
	if lone == null:
		return ""
	var off := lone.ground_pos - man.ground_pos
	var away := lone.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * INFORMER_AWAY
	rules.cast(slots.whisper, lone.ground_pos, {"target": lone, "to": MindWhisperFx.clamp_to(crowd._grid, lone.ground_pos, away)})
	return "whisper an onlooker off"


## The Crown's Bread (v0.11 M4), with mission spec §1's policy (_bread_act()), through _scripted().
func _bread(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as CrownsBreadDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("bread", which, func() -> String: return _bread_act(rules, slots, d, crowd),
		func() -> String: return "razed=%d current=%d guards=%d rebuilt=%d phase=%s" % [d.razed_count(), d.current(),
			d.guards(d.current()).size(), d.rebuilt, d.hint_phase()])


## One look of The Crown's Bread's policy (v0.11 M4): what was cast, or "". The first that applies: the target in use with an engineer
## on guard, clear him (_bread_clear(), a Smite allowed); with none on guard, Ember a granary or mill not burning (Smite it while Ember
## cools), or Smite the bridge; the next target within BREAD_AHEAD of its time, clear its crew with Doom and Whisper only (decision
## 103); a relief walking toward the target in use, Silent Doom on him. It never holds a target down ahead of its time.
func _bread_act(rules: Rules, slots: Dictionary, d: CrownsBreadDirector, crowd: Crowd) -> String:
	var cur := -1
	for i in d.targets.size():
		if d.in_use[i] and not d.razed(d.targets[i]):
			cur = i
			break
	if cur >= 0:
		var s := d.targets[cur]
		var on := d.guards(cur)
		if not on.is_empty():
			var did := _bread_clear(rules, slots, d, crowd, cur, on, true)
			if did != "":
				return did
		elif is_instance_valid(s) and not s.destroyed:
			if cur < 2 and not d.burning(s):
				if _slot_ready(rules, slots, "ember"):
					rules.cast(slots.ember, s.center())
					return "ember the %s" % CrownsBreadDirector.WORDS[cur]
				if _slot_ready(rules, slots, "smite"):
					rules.cast(slots.smite, s.center())
					return "smite the %s" % CrownsBreadDirector.WORDS[cur]
			elif cur == 2 and _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the bridge"
	var next := d.upcoming()
	if next >= 0 and next != cur and d.due_in(next) <= BREAD_AHEAD:
		var ahead := d.guards(next)
		if not ahead.is_empty():
			var did := _bread_clear(rules, slots, d, crowd, next, ahead, false)
			if did != "":
				return did
	if cur >= 0:
		var walker := d.relief_walking(cur)
		if walker != null and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, walker.ground_pos)
			return "doom a relief for the %s" % CrownsBreadDirector.WORDS[cur]
	return ""


## Clears an engineer of target `i` (v0.11 M4): with `smite_ok`, Smite one within Smite's reach of it; else Silent Doom on one no one
## else stands within its radius of (else the first); else Mind Whisper sends one not shaking a whisper off BREAD_AWAY from it.
func _bread_clear(rules: Rules, slots: Dictionary, d: CrownsBreadDirector, crowd: Crowd, i: int, on: Array[Person], smite_ok: bool) -> String:
	var s := d.targets[i]
	var word := String(CrownsBreadDirector.WORDS[i])
	if smite_ok and _slot_ready(rules, slots, "smite"):
		for p in on:
			if s.distance_to(p.ground_pos) <= SmiteFx.HIT_R:
				rules.cast(slots.smite, p.ground_pos)
				return "smite an engineer at the %s" % word
	if _slot_ready(rules, slots, "doom"):
		var pick := on[0]
		for p in on:
			if _bread_alone(crowd, p):
				pick = p
				break
		rules.cast(slots.doom, pick.ground_pos)
		return "doom an engineer at the %s" % word
	if _slot_ready(rules, slots, "whisper"):
		for p in on:
			if p.shaken():
				continue
			var off := p.ground_pos - s.center()
			var away := p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * BREAD_AWAY
			rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, away)})
			return "whisper an engineer off the %s" % word
	return ""


## No one else alive stands within Silent Doom's radius of `p` (v0.11 M4). Only reads.
func _bread_alone(crowd: Crowd, p: Person) -> bool:
	for q in crowd.citizens:
		if q != p and WarningDirector._alive(q) and not q.inside and q.ground_pos.distance_to(p.ground_pos) <= SilentDoom.RADIUS:
			return false
	return true


## The Prisoner (v0.11 M4), with mission spec §2's policy (_prisoner_act()), through _scripted().
func _prisoner(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as PrisonerDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("prisoner", which, func() -> String: return _prisoner_act(rules, slots, d, crowd),
		func() -> String: return "bound=%s held=%s seizures=%d gate=%.1f watch_away=%s hounds=%d phase=%s" % [d.bound, d.held,
			d.seizures, d.charge.ground_pos.distance_to(d.gate_at) if WarningDirector._alive(d.charge) else -1.0, d.watch_away,
			d.hunters.size(), d.hint_phase()])


## One look of The Prisoner's policy (v0.11 M4): what was cast, or "". The first that applies: bound, a gaoler within sight of her --
## Silent Doom on him (beyond its reach of her), else Mind Whisper sends him off; bound, no gaoler near -- Ember the stocks; held --
## Discord on her seizer, or Doom him once she stands clear; free -- a watcher (the postern's watch aside) near her or her next
## stretch, whisper him off, else Doom, else Discord; Mind Whisper sends her along her road, stopping short of a watched postern; at
## the postern, watched, its change more than PRISONER_SOON off -- whisper one of its watch off. Never a loud power.
func _prisoner_act(rules: Rules, slots: Dictionary, d: PrisonerDirector, crowd: Crowd) -> String:
	var her := d.charge
	if not WarningDirector._alive(her) or her.inside:
		return ""
	if d.bound:
		for v: Variant in d.gaolers:
			if not d._watching(v) or (v as Person).ground_pos.distance_to(her.ground_pos) > EscortDirector.SIGHT + PRISONER_WARN:
				continue
			var g := v as Person
			if _slot_ready(rules, slots, "doom") and g.ground_pos.distance_to(her.ground_pos) > SilentDoom.RADIUS + PRISONER_CLEAR:
				rules.cast(slots.doom, g.ground_pos)
				return "doom a gaoler"
			if _slot_ready(rules, slots, "whisper") and not g.shaken():
				rules.cast(slots.whisper, g.ground_pos, {"target": g, "to": _prisoner_away(crowd, g, her.ground_pos)})
				return "whisper a gaoler off"
			return ""
		if is_instance_valid(d.stocks) and not d.stocks.destroyed and not crowd.fires.is_burning(d.stocks) \
				and _slot_ready(rules, slots, "ember"):
			rules.cast(slots.ember, d.stocks.center())
			return "ember the stocks"
		return ""
	if d.held and WarningDirector._alive(d.seizer):
		var s := d.seizer as Person
		if _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord her seizer"
		if _slot_ready(rules, slots, "doom") and her.ground_pos.distance_to(s.ground_pos) > SilentDoom.RADIUS + PRISONER_CLEAR:
			rules.cast(slots.doom, s.ground_pos)
			return "doom her seizer"
		return ""
	var road: Array = PrisonerDirector.ROAD
	var ahead := _road_ahead(road, her.ground_pos, PRISONER_STRETCH)
	for v: Variant in d._watchers():
		if d.watch.has(v) or not d._watching(v):
			continue
		var p := v as Person
		if p.ground_pos.distance_to(her.ground_pos) > PRISONER_NEAR and _seg_dist(p.ground_pos, her.ground_pos, ahead) > PRISONER_NEAR:
			continue
		if _slot_ready(rules, slots, "whisper") and not p.shaken():
			rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _prisoner_away(crowd, p, her.ground_pos)})
			return "whisper a watcher off"
		if _slot_ready(rules, slots, "doom") and p.ground_pos.distance_to(her.ground_pos) > SilentDoom.RADIUS + PRISONER_CLEAR:
			rules.cast(slots.doom, p.ground_pos)
			return "doom a watcher"
		if _slot_ready(rules, slots, "discord") and p.ground_pos.distance_to(her.ground_pos) > DiscordFx.DISCORD_R + PRISONER_CLEAR:
			rules.cast(slots.discord, p.ground_pos)
			return "discord a watcher"
		break
	var watched := not d.watch_away and d._watch_standing()
	if _slot_ready(rules, slots, "whisper") and not her.shaken():
		var to := _road_ahead(road, her.ground_pos, MindWhisperFx.REACH - 0.5)
		var wait := d._walkable(d.gate_at + PRISONER_WAIT)
		if watched and _road_progress(road, to) > _road_progress(road, wait):
			to = wait
		to = MindWhisperFx.clamp_to(crowd._grid, her.ground_pos, d._walkable(to))
		var going := her.mind == Person.Mind.WHISPERED and her.goal() != Vector2.INF and her.ground_pos.distance_to(her.goal()) > LAMB_AHEAD
		if not going and her.ground_pos.distance_to(to) > 1.0:
			rules.cast(slots.whisper, her.ground_pos, {"target": her, "to": to})
			return "whisper her on to (%.1f, %.1f)" % [to.x, to.y]
	if watched and her.ground_pos.distance_to(d.gate_at) <= EscortDirector.NEAR_GATE and (d.change_in < 0.0 or d.change_in > PRISONER_SOON) \
			and _slot_ready(rules, slots, "whisper"):
		for v: Variant in d.watch:
			if d._watching(v) and not (v as Person).shaken():
				rules.cast(slots.whisper, (v as Person).ground_pos, {"target": v, "to": _prisoner_away(crowd, v as Person, d.gate_at)})
				return "whisper the postern's watch off"
	return ""


## Where Mind Whisper sends `p` (v0.11 M4): PRISONER_AWAY straight away from `from`, on ground the whisper can reach.
func _prisoner_away(crowd: Crowd, p: Person, from: Vector2) -> Vector2:
	var off := p.ground_pos - from
	return MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * PRISONER_AWAY)


## The point `dist` along polyline `road` beyond where `at` lies nearest it (v0.11 M4); its end if nearer.
func _road_ahead(road: Array, at: Vector2, dist: float) -> Vector2:
	var along := _road_progress(road, at) + dist
	var run := 0.0
	for k in range(road.size() - 1):
		var a: Vector2 = road[k]
		var b: Vector2 = road[k + 1]
		var seg := a.distance_to(b)
		if run + seg >= along:
			return a.lerp(b, (along - run) / maxf(seg, 0.001))
		run += seg
	return road.back()


## How far along polyline `road` the point nearest `at` lies (v0.11 M4).
func _road_progress(road: Array, at: Vector2) -> float:
	var best := INF
	var best_run := 0.0
	var run := 0.0
	for k in range(road.size() - 1):
		var a: Vector2 = road[k]
		var b: Vector2 = road[k + 1]
		var q := Geometry2D.get_closest_point_to_segment(at, a, b)
		if q.distance_to(at) < best:
			best = q.distance_to(at)
			best_run = run + a.distance_to(q)
		run += a.distance_to(b)
	return best_run


## How far `p` stands from the segment `a`-`b` (v0.11 M4).
func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


## The Heretic Hunt (v0.11 M4), with mission spec §3's policy (_hunt_act()), through _scripted().
func _hunt(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as HereticHuntDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("hunt", which, func() -> String: return _hunt_act(rules, slots, d, crowd),
		func() -> String: return "broken=%d current=%d next=%d captain=%s searching=%s phase=%s" % [d.broken_count(), d.current(),
			d.next_step(), d.head_out, d.searching, d.hint_phase()])


## One look of The Heretic Hunt's policy (v0.11 M4): what was cast, or "". The first that applies: the captain out of doors, Silent
## Doom on him; a raised standard unguarded, Smite on its far side from its guards; each raised standard guarded, then the next sweep
## within HUNT_AHEAD -- Discord where it holds two or more of a raised standard's guards, else Silent Doom on a guard alone (else any),
## else Mind Whisper sends one off; a relief walking in, Silent Doom on him.
func _hunt_act(rules: Rules, slots: Dictionary, d: HereticHuntDirector, crowd: Crowd) -> String:
	if d.head_out and WarningDirector._alive(d.head) and not (d.head as Person).inside and _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, (d.head as Person).ground_pos)
		return "doom the captain"
	for i in d.steps.size():
		var s := d.standard(i)
		if s == null or d.steps[i].broken or s.destroyed or d.guarded(i):
			continue
		if _slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, _hunt_far_side(d, i))
			return "smite the standard of %s" % d.steps[i].words
	var work: Array[int] = []
	for i in d.steps.size():
		if d.steps[i].raised and not d.steps[i].broken and d.guarded(i):
			work.append(i)
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= HUNT_AHEAD:
		work.append(n)
	for i in work:
		var on := d.party_on(i)
		if on.is_empty():
			continue
		var words := d.steps[i].words
		if on.size() >= 2 and d.steps[i].raised and _slot_ready(rules, slots, "discord"):
			var at := _hunt_pair(on)
			if at != Vector2.INF:
				rules.cast(slots.discord, at)
				return "discord the guards of %s" % words
		if _slot_ready(rules, slots, "doom"):
			var pick := on[0]
			for p in on:
				if _bread_alone(crowd, p):
					pick = p
					break
			rules.cast(slots.doom, pick.ground_pos)
			return "doom a guard of %s" % words
		if _slot_ready(rules, slots, "whisper"):
			for p in on:
				if p.shaken():
					continue
				var off := p.ground_pos - d.steps[i].spot
				var away := p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * HUNT_AWAY
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, away)})
				return "whisper a guard of %s off" % words
	for i in d.steps.size():
		if d.steps[i].broken:
			continue
		var r := d.relief_walking(i)
		if r != null and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, r.ground_pos)
			return "doom a relief"
	return ""


## Where one Discord holds the most of `on`, two at least (v0.11 M4): on one of them or midway between two; Vector2.INF for nowhere.
func _hunt_pair(on: Array[Person]) -> Vector2:
	var best := Vector2.INF
	var most := 1
	var spots: Array[Vector2] = []
	for a in on.size():
		spots.append(on[a].ground_pos)
		for b in range(a + 1, on.size()):
			spots.append((on[a].ground_pos + on[b].ground_pos) * 0.5)
	for at in spots:
		var held := 0
		for p in on:
			held += 1 if p.ground_pos.distance_to(at) <= DiscordFx.DISCORD_R - 0.1 else 0
		if held > most:
			most = held
			best = at
	return best


## A Smite's aim on standard `i` (v0.11 M4): HUNT_FAR from its centre, away from the nearest of its guards still standing.
func _hunt_far_side(d: HereticHuntDirector, i: int) -> Vector2:
	var s := d.standard(i)
	var near := Vector2.INF
	for g: HuntDirector.Guard in d.steps[i].party:
		if WarningDirector._alive(g.man) and (near == Vector2.INF
				or (g.man as Person).ground_pos.distance_to(s.center()) < near.distance_to(s.center())):
			near = (g.man as Person).ground_pos
	if near == Vector2.INF or near.distance_to(s.center()) < 0.01:
		return s.center()
	return s.center() + (s.center() - near).normalized() * HUNT_FAR


## The Bishop (v0.11 M5), with mission spec §1's policy (_bishop_act()), through _scripted().
func _bishop(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as BishopDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("bishop", which, func() -> String: return _bishop_act(rules, slots, d, crowd),
		func() -> String: return "refuge=%d flight=%s square=%s driven=%d guards=%d reliefs=%d phase=%s" % [d.at_refuge, d.in_flight,
			d.in_square, d.driven, d.guards_at(d.current_refuge()).size() if d.current_refuge() >= 0 else 0, d.reliefs, d.hint_phase()])


## One look of The Bishop's policy (v0.11 M5): what was cast, or "". The first that applies: the bishop out of doors, Silent Doom on him
## (quiet: no alarm before it lands, plan decision 175), else Smite; a Knight on guard at his refuge, clear one (_knight_clear(), a
## Smite allowed); none on guard, Ember the refuge (Smite it while Ember cools); in his flight, or BISHOP_AHEAD before his first refuge,
## Silent Doom on the next refuge's Knights; a relief walking in, Silent Doom on him.
func _bishop_act(rules: Rules, slots: Dictionary, d: BishopDirector, crowd: Crowd) -> String:
	var q := d.quarries[0]
	if q.dead or not WarningDirector._alive(q.target):
		return ""
	if d.in_square and not q.target.inside:
		if _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, q.target.ground_pos)
			return "doom the bishop"
		if _slot_ready(rules, slots, "smite"):
			rules.cast(slots.smite, q.target.ground_pos)
			return "smite the bishop"
		return ""
	var cur := d.current_refuge()
	if cur >= 0:
		var on := d.guards_at(cur)
		if not on.is_empty():
			var did := _knight_clear(rules, slots, crowd, on, true)
			if did != "":
				return did
		else:
			var s := d.refuges[cur]
			if is_instance_valid(s) and not s.destroyed and not d._burning(s):
				if _slot_ready(rules, slots, "ember"):
					rules.cast(slots.ember, s.center())
					return "ember refuge %d" % cur
				if _slot_ready(rules, slots, "smite"):
					rules.cast(slots.smite, s.center())
					return "smite refuge %d" % cur
	var nxt := d.next_refuge()
	if nxt >= 0 and nxt != cur and (d.in_flight or (d.at_refuge < 0 and d.arrive_in() <= BISHOP_AHEAD)):
		var ahead := d.standing_at(nxt)
		if not ahead.is_empty():
			var did := _knight_clear(rules, slots, crowd, ahead, false)
			if did != "":
				return did
	var walker := d.relief_walking()
	if walker != null and _slot_ready(rules, slots, "doom"):
		rules.cast(slots.doom, walker.ground_pos)
		return "doom a relief knight"
	return ""


## Clears one of `on` (v0.11 M5, The Bishop and The Armoury): Silent Doom on one no one else stands within its radius of; else, with
## `smite_ok`, Smite the first; else (`smite_ok` false) Silent Doom on the first.
func _knight_clear(rules: Rules, slots: Dictionary, crowd: Crowd, on: Array[Person], smite_ok: bool) -> String:
	var alone: Person = null
	for p in on:
		if _none_within(crowd, p, SilentDoom.RADIUS):
			alone = p
			break
	if _slot_ready(rules, slots, "doom") and (alone != null or not smite_ok):
		rules.cast(slots.doom, (alone if alone != null else on[0]).ground_pos)
		return "doom a guard"
	if smite_ok and _slot_ready(rules, slots, "smite"):
		rules.cast(slots.smite, on[0].ground_pos)
		return "smite a guard"
	return ""


## No one else alive and out of doors, citizen or soldier, stands within `r` of `p` (v0.11 M5). Only reads.
func _none_within(crowd: Crowd, p: Person, r: float) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if o != p and is_instance_valid(o) and o.is_alive() and not o.inside and o.ground_pos.distance_to(p.ground_pos) <= r:
				return false
	return true


## The Armoury (v0.11 M5), with mission spec §2's policy (_armoury_act()), through _scripted().
func _armoury(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as ArmouryDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("armoury", which, func() -> String: return _armoury_act(rules, slots, d, crowd),
		func() -> String: return "razed=%d mustering=%d guards=%d reinforced=%d reliefs=%d reserve=%d phase=%s" % [d.razed_count(),
			d.mustering_now(), d.guards(d.current()).size(), d.reinforced, d.reliefs, d.reserve.size(), d.hint_phase()])


## One look of The Armoury's policy (v0.11 M5): what was cast, or "". The first that applies: the mustering target with an armed man on
## guard, Smite one within Smite's reach of it, else clear one with Silent Doom (_knight_clear(), no Smite); with none on guard, Ember a
## barracks or the armoury not burning (Smite it while Ember cools), or Heaven Splitter through the gate barracks (Smite it while
## Heaven cools); the next horn within ARMOURY_AHEAD, its night watch cleared with Silent Doom; a reinforcement or relief running in,
## Silent Doom on him.
func _armoury_act(rules: Rules, slots: Dictionary, d: ArmouryDirector, crowd: Crowd) -> String:
	var cur := d.mustering_now()
	if cur >= 0:
		var s := d.targets[cur]
		var word := String(ArmouryDirector.WORDS[cur])
		var on := d.guards(cur)
		if not on.is_empty():
			if _slot_ready(rules, slots, "smite"):
				for p in on:
					if is_instance_valid(s) and s.distance_to(p.ground_pos) <= SmiteFx.HIT_R:
						rules.cast(slots.smite, p.ground_pos)
						return "smite an armed man at the %s" % word
			var did := _knight_clear(rules, slots, crowd, on, false)
			if did != "":
				return did
		elif is_instance_valid(s) and not s.destroyed:
			if s.kind in FireManager.BURNABLE:
				if not d.burning(s):
					if _slot_ready(rules, slots, "ember"):
						rules.cast(slots.ember, s.center())
						return "ember the %s" % word
					if _slot_ready(rules, slots, "smite"):
						rules.cast(slots.smite, s.center())
						return "smite the %s" % word
			elif _slot_ready(rules, slots, "heaven"):
				rules.cast(slots.heaven, s.center(), {"dir": Vector2.RIGHT})
				return "heaven splitter through the %s" % word
			elif _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, s.center())
				return "smite the %s" % word
	var next := d.upcoming()
	if next >= 0 and next != cur and d.due_in(next) <= ARMOURY_AHEAD:
		var ahead := d.guards(next)
		if not ahead.is_empty():
			var did := _knight_clear(rules, slots, crowd, ahead, false)
			if did != "":
				return did
	if cur >= 0:
		var walker := d.relief_walking(cur)
		if walker != null and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, walker.ground_pos)
			return "doom a man running in"
	return ""


## The Sermon (v0.11 M5), with mission spec §3's policy (_sermon_act()), through _scripted().
func _sermon(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as SermonDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("sermon", which, func() -> String: return _sermon_act(rules, slots, d, crowd),
		func() -> String: return "believers=%d left=%d preaching=%s sentries=%d reports=%d gaze=%d phase=%s bell=%s" % [d.believers_outside(),
			d.unturned().size(), d.preaching(), d.sentries_on_guard().size(), d.reports_started, roundi(d.gaze.value), d.hint_phase(),
			_bell_state(crowd)])


## One look of The Sermon's policy (v0.11 M5, mission spec §3's, worked as a player works the opposition): what was cast, or "". The
## first that applies:
## 1. the bellkeeper called (the BELLKEEPER tag's man): Silent Doom on him, else The Bell Lies (all is well: rung within 45 s, the
##    bell tolls a lie and fills no Gaze), else Mind Whisper sends him aside, else Discord (either drops the climb);
## 2. the preacher out of doors where his death goes unseen (no acolyte not held within SermonDirector's SIGHT, _sermon_unseen()):
##    Silent Doom on him (silenced for good);
## 3. the preacher preaching: Mind Whisper sends him to a quiet spot (_sermon_quiet(): the well's crowd would see him die there),
##    else Discord on him (it holds his acolytes too);
## 4. he and both acolytes held and none of his crowd within its radius: Silent Doom on him;
## 5. a report running: Silent Doom on its runner where the kill goes unseen, else Mind Whisper sends him to a quiet spot, else
##    Discord on him (a held runner drops the run);
## 6. a Faithful who would see the god's door (a sentry on guard, or any other -- the red marks): Silent Doom on him with no one else
##    within SERMON_ALONE and the kill unseen, else Mind Whisper sends him to a quiet spot (else SERMON_AWAY off the door);
## 7. the door unwatched: Mind Whisper sends the unturned listener nearest the god's house, not rapt and able to hear, to its door;
## 8. a sentry off his post (one whispered off, a relief walking in) where his death goes unseen: Silent Doom on him.
## Every Silent Doom but the bellkeeper's spares the crowd (_sermon_spares()). The loadout carries The Bell Lies, not Will-o'-Wisp:
## every listener is on duty, and a lure takes no one on duty.
func _sermon_act(rules: Rules, slots: Dictionary, d: SermonDirector, crowd: Crowd) -> String:
	var doom := _slot_ready(rules, slots, "doom")
	var whisper := _slot_ready(rules, slots, "whisper")
	var keeper := d.bellkeeper()
	if keeper != null:
		if doom:
			rules.cast(slots.doom, keeper.ground_pos)
			return "doom the bellkeeper"
		if not crowd.is_bell_lying() and _slot_ready(rules, slots, "belllies"):
			rules.cast(slots.belllies, TownLayout.BELL_TOWER.get_center(), {"mode": "well"})
			return "the bell lies"
		if whisper and _whisperable(keeper):
			var aside := _sermon_quiet(d, crowd, keeper)
			if aside != Vector2.INF:
				rules.cast(slots.whisper, keeper.ground_pos, {"target": keeper, "to": aside})
				return "whisper the bellkeeper aside"
		if not d.held(keeper) and _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, keeper.ground_pos)
			return "discord the bellkeeper"
	var pr: Variant = d.preacher
	var out := WarningDirector._alive(pr) and not (pr as Person).inside
	if out and doom and _sermon_unseen(d, crowd, pr as Person) and _sermon_spares(d, pr as Person):
		rules.cast(slots.doom, (pr as Person).ground_pos)
		return "doom the preacher"
	if d.preaching():
		if whisper and _whisperable(pr as Person):
			var quiet := _sermon_quiet(d, crowd, pr as Person)
			if quiet != Vector2.INF:
				rules.cast(slots.whisper, (pr as Person).ground_pos, {"target": pr, "to": quiet})
				return "whisper the preacher aside"
		if _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, (pr as Person).ground_pos)
			return "discord the preacher"
	if out and d.held(pr) and doom and _none_within(crowd, pr as Person, SilentDoom.RADIUS):
		var all_held := true
		for a: Variant in d.acolytes:
			all_held = all_held and (not WarningDirector._alive(a) or d.held(a))
		if all_held:
			rules.cast(slots.doom, (pr as Person).ground_pos)
			return "doom the held preacher"
	for r in d.reports:
		if not r.is_open() or not WarningDirector._alive(r.carrier) or r.carrier.inside \
				or _walk_len(crowd, r.carrier.ground_pos, d.temple_door) == INF:
			continue  # one shut in where no street leads to the Temple never gets there
		if doom and _tax_unseen(r.carrier, crowd) and _sermon_spares(d, r.carrier):
			rules.cast(slots.doom, r.carrier.ground_pos)
			return "doom a report's runner"
		if whisper and _whisperable(r.carrier):
			var quiet := _sermon_quiet(d, crowd, r.carrier)
			if quiet != Vector2.INF:
				rules.cast(slots.whisper, r.carrier.ground_pos, {"target": r.carrier, "to": quiet})
				return "whisper a report's runner aside"
		if not d.held(r.carrier) and _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, r.carrier.ground_pos)
			return "discord a report's runner"
	var on := d.watchers(d.door, MirasHouseDirector.SIGHT)
	if not on.is_empty():
		if doom:
			for p in on:
				if _none_within(crowd, p, SERMON_ALONE) and _tax_unseen(p, crowd) and _sermon_spares(d, p):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a watcher of the door"
		if whisper:
			for p in on:
				if not _whisperable(p):
					continue
				var to := _sermon_quiet(d, crowd, p)
				if to == Vector2.INF:
					var off := p.ground_pos - d.door
					to = MindWhisperFx.clamp_to(crowd._grid, p.ground_pos,
						p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * SERMON_AWAY)
				rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": to})
				return "whisper a watcher off"
		return ""
	if whisper:
		var best: Person = null
		for p in d.unturned():
			if d.rapt(p) or not _whisperable(p):
				continue
			if best == null or p.ground_pos.distance_to(d.door) < best.ground_pos.distance_to(d.door):
				best = p
		if best != null:
			rules.cast(slots.whisper, best.ground_pos, {"target": best, "to": MindWhisperFx.clamp_to(crowd._grid, best.ground_pos, d.door)})
			return "whisper a listener to the house"
	if doom:
		for p in d.sentries_off():
			if _tax_unseen(p, crowd) and _sermon_spares(d, p):
				rules.cast(slots.doom, p.ground_pos)
				return "doom a sentry off his post"
	return ""


## A Silent Doom on `p` would spare the preacher's crowd (v0.11 M5, the main hint's "Do not kill them"): no listener, Believers among
## them, stands within its radius (and a hair) of him -- _tax_unseen() lets those fall with him.
func _sermon_spares(d: SermonDirector, p: Person) -> bool:
	for l: SermonDirector.Listener in d.listeners:
		if WarningDirector._alive(l.man) and l.man != p and not (l.man as Person).inside \
				and (l.man as Person).ground_pos.distance_to(p.ground_pos) <= SilentDoom.RADIUS + 0.3:
			return false
	return true


## A Silent Doom on the preacher `p` now would go unseen (v0.11 M5): no one would witness it (_tax_unseen()), and no acolyte not held
## stands within SermonDirector's SIGHT (an acolyte who sees the fall runs to the Temple).
func _sermon_unseen(d: SermonDirector, crowd: Crowd, p: Person) -> bool:
	if not _tax_unseen(p, crowd):
		return false
	for a: Variant in d.acolytes:
		if WarningDirector._alive(a) and not d.held(a) and (a as Person).ground_pos.distance_to(p.ground_pos) <= MirasHouseDirector.SIGHT + 0.5:
			return false
	return true


## The quietest spot within Mind Whisper's reach of `c` (v0.11 M5, The Bell-Ringers' search, loosened for a crowded quarter): of
## RINGERS_QUIET_DIRS directions at each of RINGERS_QUIET_R, one his walk reaches within the reach, with the fewest living people out
## of doors within RINGERS_QUIET_CLEAR of it, then the farthest from the pulpit and the god's door (the crowd, the acolytes and the
## sentries); Vector2.INF for none.
func _sermon_quiet(d: SermonDirector, crowd: Crowd, c: Person) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	var best_gap := -1.0
	for rad: float in RINGERS_QUIET_R:
		for k in RINGERS_QUIET_DIRS:
			var g := d._walkable(c.ground_pos + Vector2.from_angle(TAU * float(k) / float(RINGERS_QUIET_DIRS)) * rad)
			if g.distance_to(c.ground_pos) > MindWhisperFx.REACH - 0.5 or _walk_len(crowd, c.ground_pos, g) > MindWhisperFx.REACH:
				continue
			var n := 0
			for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
				for p in group:
					if is_instance_valid(p) and p != c and p.is_alive() and not p.inside \
							and p.ground_pos.distance_to(g) <= RINGERS_QUIET_CLEAR:
						n += 1
			var gap := minf(g.distance_to(d.pulpit), g.distance_to(d.door))
			if best == Vector2.INF or n < best_n or (n == best_n and gap > best_gap):
				best = g
				best_n = n
				best_gap = gap
	return best


## The Relic Run (v0.11 M5), with mission spec §4's policy (_relic_act()), through _scripted().
func _relic(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as RelicRunDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("relic", which, func() -> String: return _relic_act(rules, slots, d, crowd),
		func() -> String: return "halt=%d halts=%s aboard=%s lock=%.0f swapped=%s stalled=%s touches=%d gaze=%d reports=%d phase=%s bell=%s" % [
			d.halt, d.halts_done, d.aboard, d.lock_left, d.swapped, d.stalled, d.touches, roundi(d.gaze.value), d.reports_started,
			d.hint_phase(), _bell_state(crowd)])


## One look of The Relic Run's policy (v0.11 M5, mission spec §4's, worked as a player works the opposition): what was cast, or "". The
## first that applies:
## 1. the bellkeeper called (the BELLKEEPER tag's man): Silent Doom on him, else Discord (either drops the climb);
## 2. a report running: Silent Doom on its runner where the kill goes unseen and spares Pip, else Mind Whisper sends him RELIC_AWAY off
##    from the Temple, else Discord on him (a held runner drops the run);
## 3. with the relic, The Vigil Flame's carry (_relic_carry());
## 4. before a halt, Pip not aboard: within RELIC_COME of it, Mind Whisper sends him to its checkpoint; earlier, more than RELIC_NEAR
##    from his waiting place RELIC_PARK short of it on his side, toward that place (up to its reach);
## 5. the next halt within RELIC_AHEAD (the first) or RELIC_LEG (the second): Silent Doom on a warden of it with no one else within its
##    radius whose death goes unseen, or in its last RELIC_LATE seconds on one seen; else Mind Whisper sends one still at his post to
##    a quiet spot (_relic_quiet()), where his death will go unseen;
## (aboard at the first halt, nothing more: the count runs and the cart rolls on);
## 6. halted, Pip neither within the cart's reach nor aboard: Mind Whisper sends him to the cart;
## 7. halted and watched, Pip by the cart or within RELIC_PARK of it: Discord where it holds every watcher (all within
##    DiscordFx.DISCORD_R - RELIC_MARGIN of their midpoint), unless one stands alone whom a whisper takes; else, a passer-by among them
##    (Person.LURABLE), a Will-o'-Wisp RELIC_LURE beyond the cart from Pip; else Discord at the escorts' midpoint (both within RELIC_PAIR
##    of it, neither held); else Silent Doom on a watcher with no one else within its radius and the kill unseen -- or, Pip aboard, seen
##    by no Faithful (no report runs); else Mind Whisper sends one watcher RELIC_AWAY off the cart.
func _relic_act(rules: Rules, slots: Dictionary, d: RelicRunDirector, crowd: Crowd) -> String:
	var v: Variant = d.wren
	if not WarningDirector._alive(v) or d.home:
		return ""
	var pip := v as Person
	var doom := _slot_ready(rules, slots, "doom")
	var whisper := _slot_ready(rules, slots, "whisper")
	var discord := _slot_ready(rules, slots, "discord")
	var keeper := d.bellkeeper()
	if keeper != null:
		if doom:
			rules.cast(slots.doom, keeper.ground_pos)
			return "doom the bellkeeper"
		if not crowd.is_bell_lying() and _slot_ready(rules, slots, "belllies"):
			rules.cast(slots.belllies, TownLayout.BELL_TOWER.get_center(), {"mode": "well"})
			return "the bell lies"
		if discord and not keeper.mind in MissionDirector.BLIND:
			rules.cast(slots.discord, keeper.ground_pos)
			return "discord the bellkeeper"
	for r in d.reports:
		if not r.is_open() or not WarningDirector._alive(r.carrier) or r.carrier.inside:
			continue
		var c := r.carrier
		var spares := pip.inside or pip.ground_pos.distance_to(c.ground_pos) > SilentDoom.RADIUS + 0.3
		if doom and spares and _tax_unseen(c, crowd):
			rules.cast(slots.doom, c.ground_pos)
			return "doom a report's runner"
		if whisper and _whisperable(c):
			var off := c.ground_pos - d.temple_door
			rules.cast(slots.whisper, c.ground_pos, {"target": c, "to": MindWhisperFx.clamp_to(crowd._grid, c.ground_pos,
				c.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * RELIC_AWAY)})
			return "whisper a report's runner off"
		if discord and not c.mind in MissionDirector.BLIND:
			rules.cast(slots.discord, c.ground_pos)
			return "discord a report's runner"
	if d.swapped:
		return _relic_carry(rules, slots, d)
	var cart := d.cart_at()
	var pip_free := not pip.inside and pip.mind != Person.Mind.WHISPERED and not pip.shaken()
	var k := d.next_halt()
	var due := d.halt_in()
	if d.halt < 0 and k >= 0 and not d.aboard and pip_free and whisper:
		var at := d.checkpoints[k]
		if due <= RELIC_COME and pip.ground_pos.distance_to(at) > RelicRunDirector.CART_REACH * 0.5:
			rules.cast(slots.whisper, pip.ground_pos, {"target": pip, "to": MindWhisperFx.clamp_to(crowd._grid, pip.ground_pos, at)})
			return "whisper Pip to the halt"
		var from := pip.ground_pos - at
		var park := d._walkable(at + (from.normalized() if from.length() > 0.01 else Vector2.DOWN) * RELIC_PARK)
		if due > RELIC_COME and pip.ground_pos.distance_to(park) > RELIC_NEAR and pip.ground_pos.distance_to(at) > RELIC_PARK:
			rules.cast(slots.whisper, pip.ground_pos, {"target": pip, "to": MindWhisperFx.clamp_to(crowd._grid, pip.ground_pos, park)})
			return "whisper Pip toward the next halt"
	if d.halt < 0 and k >= 0 and due <= (RELIC_AHEAD if k == 0 else RELIC_LEG):
		if doom:
			for p in d.wardens_at(k):
				if _none_within(crowd, p, SilentDoom.RADIUS) and (due <= RELIC_LATE or _tax_unseen(p, crowd)):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a warden ahead"
		if whisper:
			for p in d.wardens_at(k):
				if not _whisperable(p) or p.ground_pos.distance_to(d.checkpoints[k]) > RelicRunDirector.WARDEN_GAP:
					continue
				var quiet := _relic_quiet(d, crowd, p, d.checkpoints[k])
				if quiet != Vector2.INF:
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": quiet})
					return "whisper a warden ahead aside"
	if d.halt < 0 or (d.aboard and d.halt != RelicRunDirector.HALT_LEGS.size() - 1):
		return ""  # aboard at the first halt: the count may run, and the cart rolls on sooner
	var by := d.aboard or (not pip.inside and pip.ground_pos.distance_to(cart) <= RelicRunDirector.CART_REACH)
	if not by and pip_free and whisper:
		rules.cast(slots.whisper, pip.ground_pos, {"target": pip, "to": MindWhisperFx.clamp_to(crowd._grid, pip.ground_pos, cart)})
		return "whisper Pip to the cart"
	if not by and (pip.inside or pip.ground_pos.distance_to(cart) > RELIC_PARK):
		return ""  # the watch is held only once Pip is by the cart or nearly there
	var seen := d.watchers_now()
	if seen.is_empty():
		return ""
	var lone := seen.size() == 1 and _whisperable(seen[0])  # one watcher: a whisper (soon ready), not the slow Discord
	if discord and not lone:
		var mid := Vector2.ZERO
		for p in seen:
			mid += p.ground_pos / float(seen.size())
		var one := true
		for p in seen:
			one = one and p.ground_pos.distance_to(mid) <= DiscordFx.DISCORD_R - RELIC_MARGIN
		if one:
			rules.cast(slots.discord, mid)
			return "discord the watch"
	if _slot_ready(rules, slots, "wisp"):
		for p in seen:
			if not p.mind in Person.LURABLE:
				continue
			var off := cart - pip.ground_pos if not pip.inside else p.ground_pos - cart
			var lure := d._walkable(cart + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * RELIC_LURE)
			rules.cast(slots.wisp, lure)
			return "wisp the passers-by off the cart"
	if discord and not lone:
		var pair: Array[Person] = []
		for e: Variant in d.escorts:
			if WarningDirector._alive(e) and not (e as Person).inside and not (e as Person).mind in MissionDirector.BLIND:
				pair.append(e as Person)
		if pair.size() == 2:
			var at := (pair[0].ground_pos + pair[1].ground_pos) * 0.5
			if pair[0].ground_pos.distance_to(at) <= RELIC_PAIR and pair[1].ground_pos.distance_to(at) <= RELIC_PAIR:
				rules.cast(slots.discord, at)
				return "discord the escorts"
	if doom:
		var steady := pip.inside  # aboard, Pip takes no fright from a death by the cart (a whisper does not hold off a fright)
		for p in seen:
			if _none_within(crowd, p, SilentDoom.RADIUS) and (_tax_unseen(p, crowd) or steady and d.faithful_seeing(p.ground_pos,
					Crowd.DOOM_WITNESS + TAX_MARGIN, p) == null):
				rules.cast(slots.doom, p.ground_pos)
				return "doom a watcher of the cart"
	if whisper:
		for p in seen:
			if not _whisperable(p):
				continue
			var off := p.ground_pos - cart
			var away := p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * RELIC_AWAY
			rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, away)})
			return "whisper a watcher off the cart"
	return ""


## The Vigil Flame's carry for Pip and the relic (v0.11 M5, plan decision 199): _flame_carry(), and what it cast, if anything.
func _relic_carry(rules: Rules, slots: Dictionary, d: RelicRunDirector) -> String:
	var before := rules._casts.size()
	_flame_carry(rules, d, slots)
	return "carry the relic" if rules._casts.size() > before else ""


## The quietest spot within Mind Whisper's reach of warden `c` (v0.11 M5, The Sermon's search): of RINGERS_QUIET_DIRS directions at each
## of RINGERS_QUIET_R, one his walk reaches within the reach, with the fewest living people out of doors within RINGERS_QUIET_CLEAR of
## it, then the farthest from his checkpoint `from` and Pip; Vector2.INF for none.
func _relic_quiet(d: RelicRunDirector, crowd: Crowd, c: Person, from: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	var best_gap := -1.0
	for rad: float in RINGERS_QUIET_R:
		for k in RINGERS_QUIET_DIRS:
			var g := d._walkable(c.ground_pos + Vector2.from_angle(TAU * float(k) / float(RINGERS_QUIET_DIRS)) * rad)
			if g.distance_to(c.ground_pos) > MindWhisperFx.REACH - 0.5 or _walk_len(crowd, c.ground_pos, g) > MindWhisperFx.REACH:
				continue
			var n := 0
			for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
				for p in group:
					if is_instance_valid(p) and p != c and p.is_alive() and not p.inside \
							and p.ground_pos.distance_to(g) <= RINGERS_QUIET_CLEAR:
						n += 1
			var gap := g.distance_to(from)
			if WarningDirector._alive(d.wren) and not d.wren.inside:
				gap = minf(gap, g.distance_to(d.wren.ground_pos))
			if best == Vector2.INF or n < best_n or (n == best_n and gap > best_gap):
				best = g
				best_n = n
				best_gap = gap
	return best


## The Lantern's Eye (v0.11 M6), with mission spec §1's policy (_eye_act()), through _scripted().
func _eye(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as LanternEyeDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("eye", which, func() -> String: return _eye_act(rules, slots, d, crowd),
		func() -> String: return "gone=%d current=%d next=%d shattered=%d eye=%.0f gaze=%d phase=%s" % [d.broken_count(), d.current(),
			d.next_step(), d.shattered_now(), d.eye_left(), roundi(d.gaze.value), d.hint_phase()])


## A lit pool lies within Searchlight.POOL_R + EYE_LIT_MARGIN of `at` (v0.11 M6): the policy never casts there. Only reads.
func _eye_lit(d: LanternEyeDirector, at: Vector2) -> bool:
	for i in d.searchlight.beams():
		var a := d.searchlight.aim(i)
		if a != Vector2.INF and a.distance_to(at) <= Searchlight.POOL_R + EYE_LIT_MARGIN:
			return true
	return false


## Where the policy strikes tower `i` (v0.11 M6): the first of points just off its outer face -- the middle, then toward either end --
## then off its two sides, each within a Smite's reach of the tower, that no lit pool lies near (_eye_lit()) and where the bolt strikes
## no one (_eye_clear()); Vector2.INF for none. Only reads.
func _eye_aim(d: LanternEyeDirector, crowd: Crowd, i: int) -> Vector2:
	var tw := d.towers[i]
	var out := (d.outer_face(i) - tw.center()).normalized()
	var side := d.along(i)
	var depth := tw.footprint.size.x * 0.5
	for at: Vector2 in [d.outer_face(i), d.outer_face(i) + side * EYE_AIM_SLIDE, d.outer_face(i) - side * EYE_AIM_SLIDE,
			tw.center() + side * (depth + 0.3) + out * EYE_AIM_SLIDE, tw.center() - side * (depth + 0.3) + out * EYE_AIM_SLIDE]:
		if tw.distance_to(at) <= SmiteFx.HIT_R and not _eye_lit(d, at) and _eye_clear(crowd, at, SmiteFx.HIT_R):
			return at
	return Vector2.INF


## Nobody alive and out of doors stands within `r` of `at` (v0.11 M6): a Smite's aim that strikes down no one. Only reads.
func _eye_clear(crowd: Crowd, at: Vector2, r: float) -> bool:
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if is_instance_valid(p) and p.is_alive() and not p.inside and p.ground_pos.distance_to(at) <= r:
				return false
	return true


## One look of The Lantern's Eye's policy (v0.11 M6, mission spec §1): what was cast, or "". Never where a beam shines, and every Silent
## Doom taken alone (_eye_unseen()). The first that applies: a shattered mirror's wrights at work -- Silent Doom on one alone, else Mind
## Whisper sends one off, one Silent Doom cannot take first; the current mirror open, none of its party walking back to it -- Smite its tower's outer face (_eye_aim()), else Heaven
## Splitter along it where nobody stands within its kill (EYE_HEAVEN_R), else, a beam on that face, a Will-o'-Wisp six units beyond it,
## out of the town; the current mirror standing, or the next due within EYE_AHEAD -- Silent Doom on a guard of its party, on guard or
## sent off his post (_eye_away()), else a Will-o'-Wisp draws off the passers-by who would see it (_eye_lure()), else Mind Whisper
## sends one on guard off; a relief walking in -- Silent Doom on him. Once the current
## mirror's glass is struck the wrights come next: the shattering blow waits until Silent Doom and Mind Whisper will both be ready as
## the Smite ends (EYE_CREW_WAIT: two wrights hang a glass in 5 s), a Will-o'-Wisp first draws off the onlookers standing at the
## wrights' posts (_eye_onlookers()), and the next party waits.
func _eye_act(rules: Rules, slots: Dictionary, d: LanternEyeDirector, crowd: Crowd) -> String:
	for i in d.steps.size():
		if not d.shattered[i] or d.steps[i].broken:
			continue
		var crew: Array[Person] = []
		var alone: Array[Person] = []
		for w: HuntDirector.Guard in d.wrights[i]:
			if d._working(w) and not _eye_lit(d, (w.man as Person).ground_pos):
				crew.append(w.man as Person)
				if _eye_unseen(crowd, (w.man as Person).ground_pos):
					alone.append(w.man as Person)
		if not alone.is_empty() and _slot_ready(rules, slots, "doom"):
			rules.cast(slots.doom, alone[0].ground_pos)
			return "doom a wright at %s" % d.steps[i].words
		if _slot_ready(rules, slots, "whisper"):
			var pick: Person = null
			for p in crew:
				if not p.shaken() and (pick == null or alone.has(pick)):
					pick = p
			if pick != null:
				rules.cast(slots.whisper, pick.ground_pos, {"target": pick, "to": _eye_off(d, crowd, pick, d.towers[i].center())})
				return "whisper a wright off %s" % d.steps[i].words
	var cur := d.current()
	var struck := cur >= 0 and not d.shattered[cur] and d.glass[cur] < LanternEyeDirector.MIRROR_HP
	var crew_ready := slots.has("doom") and slots.has("whisper") and rules.cooldown_left(int(slots.doom)) <= EYE_CREW_WAIT \
		and rules.cooldown_left(int(slots.whisper)) <= EYE_CREW_WAIT
	if cur >= 0 and not d.shattered[cur] and not d.guarded(cur) and not _eye_coming(d, cur) \
			and (d.glass[cur] > LanternEyeDirector.BLOW_MAX or crew_ready):
		var aim := _eye_aim(d, crowd, cur)
		var off := _eye_onlookers(d, crowd, cur) if d.glass[cur] <= LanternEyeDirector.BLOW_MAX else Vector2.INF
		if aim != Vector2.INF and off != Vector2.INF and _slot_ready(rules, slots, "smite") and _slot_ready(rules, slots, "wisp"):
			rules.cast(slots.wisp, off)
			return "wisp the onlookers off the wrights' door at %s" % d.steps[cur].words
		if aim != Vector2.INF:
			if _slot_ready(rules, slots, "smite"):
				rules.cast(slots.smite, aim)
				return "smite the mirror on %s" % d.steps[cur].words
			if _slot_ready(rules, slots, "heaven") and _eye_clear(crowd, aim, EYE_HEAVEN_R):
				rules.cast(slots.heaven, aim, {"dir": d.along(cur)})
				return "heaven along %s" % d.steps[cur].words
		elif _eye_lit(d, d.outer_face(cur)) and _slot_ready(rules, slots, "wisp"):
			var lure := d.outer_face(cur) + (d.outer_face(cur) - d.towers[cur].center()).normalized() * EYE_WISP
			if not _eye_lit(d, lure):
				rules.cast(slots.wisp, lure)
				return "wisp off %s" % d.steps[cur].words
	var work: Array[int] = []
	if cur >= 0 and not d.shattered[cur]:
		work.append(cur)
	var n := d.next_step()
	if n >= 0 and d.due_in(n) <= EYE_AHEAD and not struck:
		work.append(n)
	for i in work:
		var on := d.party_on(i)
		if _slot_ready(rules, slots, "doom"):
			for p in on + _eye_away(d, i):
				if not _eye_lit(d, p.ground_pos) and _eye_unseen(crowd, p.ground_pos):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a guard of %s" % d.steps[i].words
			if _slot_ready(rules, slots, "wisp"):
				for p in on:
					var lure := _eye_lure(d, crowd, i, p)
					if lure != Vector2.INF:
						rules.cast(slots.wisp, lure)
						return "wisp the passers-by off a guard of %s" % d.steps[i].words
		if _slot_ready(rules, slots, "whisper"):
			for p in on:
				if not _eye_lit(d, p.ground_pos) and not p.shaken():
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _eye_off(d, crowd, p, d.towers[i].center())})
					return "whisper a guard of %s off" % d.steps[i].words
	for i in d.steps.size():
		if d.steps[i].broken:
			continue
		var r := d.relief_walking(i)
		if r != null and not _eye_lit(d, r.ground_pos) and _slot_ready(rules, slots, "doom") and _eye_unseen(crowd, r.ground_pos):
			rules.cast(slots.doom, r.ground_pos)
			return "doom a relief at %s" % d.steps[i].words
	return ""


## Step `i`'s guards alive and out of doors but off guard (v0.11 M6): sent off by the god, to be taken alone where they stand. Only reads.
func _eye_away(d: LanternEyeDirector, i: int) -> Array[Person]:
	var out: Array[Person] = []
	for g: HuntDirector.Guard in d.steps[i].party:
		if MissionDirector._alive(g.man) and not (g.man as Person).inside and not d._guarding(i, g):
			out.append(g.man as Person)
	return out


## A guard of step `i`, off guard and free of the god's hold, is within EYE_COMING of standing guard again (v0.11 M6): a blow now would
## land as he takes his post, and only shake the tower. Only reads.
func _eye_coming(d: LanternEyeDirector, i: int) -> bool:
	for p in _eye_away(d, i):
		if not p.mind in MissionDirector.BLIND and d.towers[i].distance_to(p.ground_pos) <= d.guard_reach + EYE_COMING:
			return true
	return false


## Silent Doom at `at` goes unseen (v0.11 M6): _doom_unseen(), and nobody on the move -- neither on duty nor at a post -- within
## Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN of its victims, as he could walk up in the doom's SilentDoom.T_STRIKE. Only reads.
func _eye_unseen(crowd: Crowd, at: Vector2) -> bool:
	if not _doom_unseen(crowd, at):
		return false
	var victims: Array[Person] = []
	var moving: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside:
				continue
			if p.ground_pos.distance_to(at) <= SilentDoom.RADIUS:
				victims.append(p)
			elif not p.mind in [Person.Mind.DUTY, Person.Mind.POST]:
				moving.append(p)
	for v in victims:
		for o in moving:
			if o.ground_pos.distance_to(v.ground_pos) <= Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN:
				return false
	return true


## Where Mind Whisper sends `p` off tower `from` (v0.11 M6): the quietest spot -- fewest living out of doors within RINGERS_QUIET_CLEAR
## -- of RINGERS_QUIET_DIRS directions at each of RINGERS_QUIET_R that his walk reaches within the whisper's reach, the farthest from
## the tower of those, so a Silent Doom can take him there alone; else PRISONER_AWAY straight off (_prisoner_away()). Only reads.
func _eye_off(d: LanternEyeDirector, crowd: Crowd, p: Person, from: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	for rad: float in RINGERS_QUIET_R:
		for k in RINGERS_QUIET_DIRS:
			var g := d._walkable(p.ground_pos + Vector2.from_angle(TAU * float(k) / float(RINGERS_QUIET_DIRS)) * rad)
			if g.distance_to(p.ground_pos) > MindWhisperFx.REACH - 0.5 or _walk_len(crowd, p.ground_pos, g) > MindWhisperFx.REACH:
				continue
			var n := 0
			for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
				for o in group:
					if is_instance_valid(o) and o != p and o.is_alive() and not o.inside and o.ground_pos.distance_to(g) <= RINGERS_QUIET_CLEAR:
						n += 1
			if best == Vector2.INF or n < best_n or (n == best_n and g.distance_to(from) > best.distance_to(from)):
				best = g
				best_n = n
	return best if best != Vector2.INF else _prisoner_away(crowd, p, from)


## Where a Will-o'-Wisp draws off the passers-by who alone stop a Silent Doom on `p`, of step `i`'s party, going unseen (v0.11 M6):
## everyone within Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN of him is one the Wisp lures (Person.LURABLE, no soldier) and none stands
## within his doom; then EYE_LURE beyond him from his tower, on walkable ground out of the light; else Vector2.INF. Only reads.
func _eye_lure(d: LanternEyeDirector, crowd: Crowd, i: int, p: Person) -> Vector2:
	var any := false
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if not is_instance_valid(o) or o == p or not o.is_alive() or o.inside:
				continue
			var gap := o.ground_pos.distance_to(p.ground_pos)
			if gap > Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN:
				continue
			if gap <= SilentDoom.RADIUS or o.soldier or not o.mind in Person.LURABLE:
				return Vector2.INF
			any = true
	if not any:
		return Vector2.INF
	var off := p.ground_pos - d.towers[i].center()
	var at := d._walkable(p.ground_pos + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * EYE_LURE)
	return at if not _eye_lit(d, at) else Vector2.INF


## Where a Will-o'-Wisp draws off the onlookers who would see a Silent Doom on mirror `i`'s wrights as they come out (v0.11 M6): when
## someone living out of doors stands within Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN of every wright's post and all of them are ones the
## Wisp lures, EYE_LURE beyond the nearest post from the tower, on walkable ground out of the light; else Vector2.INF. Only reads.
func _eye_onlookers(d: LanternEyeDirector, crowd: Crowd, i: int) -> Vector2:
	var posts: Array[Vector2] = []
	for w: HuntDirector.Guard in d.wrights[i]:
		posts.append(w.post)
	for at in posts:
		if _eye_clear(crowd, at, Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN):
			return Vector2.INF
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for o in group:
			if not is_instance_valid(o) or not o.is_alive() or o.inside:
				continue
			for at in posts:
				if o.ground_pos.distance_to(at) <= Crowd.DOOM_WITNESS + EYE_DOOM_MARGIN and (o.soldier or not o.mind in Person.LURABLE):
					return Vector2.INF
	if posts.is_empty():
		return Vector2.INF
	var off := posts[0] - d.towers[i].center()
	var at := d._walkable(posts[0] + (off.normalized() if off.length() > 0.01 else Vector2.RIGHT) * EYE_LURE)
	return at if not _eye_lit(d, at) else Vector2.INF


## Whom the Broken Lanterns policy strikes down quietly: the bellkeeper once called, or the flame-bearer while he is
## turned aside for a draining shrine; else null.
func _lantern_doom_target(d: BrokenLanternsDirector, crowd: Crowd) -> Person:
	var bell := crowd.bell
	if bell != null and bell.state in [BellNetwork.State.CALLED, BellNetwork.State.CLIMBING] \
			and is_instance_valid(bell.keeper) and bell.keeper.is_alive():
		return bell.keeper
	var v := d.vigil
	if v != null and v.active and v.detour != Vector2.INF and is_instance_valid(v.bearer) and v.bearer.is_alive():
		return v.bearer
	return null


## Where the Broken Lanterns policy lays its Heaven Splitter: [origin, direction], or [] with no shrine standing. A pair
## of unguarded standing shrines within LANTERN_PAIR_REACH is struck from their midpoint along the line between them;
## a single shrine from its centre, turned to the LANTERN_DIRS direction crossing the fewest people. The most shrines
## win, then the fewest people in the line.
func _lantern_line(d: BrokenLanternsDirector, crowd: Crowd) -> Array:
	var standing := d.standing_shrines()
	var best := []
	var best_n := 0
	var best_people := 0
	for i in standing.size():
		var a := standing[i]
		for j in range(i + 1, standing.size()):
			var b := standing[j]
			if d.guarded(a) or d.guarded(b) or a.center().distance_to(b.center()) > LANTERN_PAIR_REACH:
				continue
			var mid := (a.center() + b.center()) * 0.5
			var dir := (b.center() - a.center()).normalized()
			var people := _lane_people(crowd, mid, dir)
			if best.is_empty() or best_n < 2 or people < best_people:
				best = [mid, dir]
				best_n = 2
				best_people = people
		if best_n >= 2:
			continue
		for k in LANTERN_DIRS:
			var dir := Vector2.from_angle(PI * float(k) / float(LANTERN_DIRS))
			var people := _lane_people(crowd, a.center(), dir)
			if best.is_empty() or people < best_people:
				best = [a.center(), dir]
				best_n = 1
				best_people = people
	return best


## The living people out in the open that a Heaven Splitter from `origin` along `dir` strikes with its core and line.
func _lane_people(crowd: Crowd, origin: Vector2, dir: Vector2) -> int:
	var n := 0
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside:
				continue
			var rel := p.ground_pos - origin
			if rel.length() <= HEAVEN_FX.CORE_KILL or (absf(rel.dot(dir)) <= HEAVEN_FX.LINE_LENGTH * 0.5
					and absf(rel.dot(dir.orthogonal())) <= HEAVEN_FX.LINE_HALF_WIDTH + 0.2):
				n += 1
	return n


## The shrine the Dragonfire Parade takes: the standing one with the fewest people within LANTERN_CROWD_R; else null.
func _lantern_target(d: BrokenLanternsDirector, crowd: Crowd) -> Structure:
	var best: Structure = null
	var best_n := 0
	for s in d.standing_shrines():
		var n := 0
		for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
			for p in group:
				if is_instance_valid(p) and p.is_alive() and not p.inside \
						and p.ground_pos.distance_to(s.center()) <= LANTERN_CROWD_R:
					n += 1
		if best == null or n < best_n:
			best = s
			best_n = n
	return best


## The Vigil Flame (v0.10 M4), played every LOOK_FRAMES by a simple policy with Mind Whisper, Discord and Will-o'-Wisp.
## Before the swap (_flame_swap): bystanders drawn off by a wisp, the bearer and his acolytes held by one Discord, then
## Wren whispered to the lantern. With the flame (_flame_carry): a beam due to come onto Wren drawn off by a wisp, else
## Wren whispered out of its way; in the clock's last 20 s, Discord at the Temple's door gives the searching beam a
## noise far from him. `none` casts nothing.
func _flame(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as VigilFlameDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var acts := _watch_idle(rules)
	var t := 0.0
	var frames := 0
	var report_at := 10.0
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if t >= report_at:
			report_at += 10.0
			print("BEHAVIOUR flame t=%d phase=%s touches=%d praying=%d reports=%d gaze=%d beams=%d" % [roundi(t),
				_flame_phase(d), d.touches, d.praying_count(), d.reports_started, roundi(d.gaze.value), d.searchlight.beams()])
		if which != "play" or frames % LOOK_FRAMES != 0:
			continue
		if not d.appeared or not is_instance_valid(d.wren) or not d.wren.is_alive() or d.home:
			continue
		if not d.swapped:
			_flame_swap(rules, d, slots)
		else:
			_flame_carry(rules, d, slots)
	var res := rules.result()
	var bonus: bool = not res.bonuses.is_empty() and bool(res.bonuses[0].earned)
	print("BEHAVIOUR flame result won=%s reason=%s time=%.1f swapped=%s seen=%s touches=%d gaze=%d bonus=%s idle=%.0f" % [res.won,
		res.reason, float(res.time), d.swapped, d.swap_seen, d.touches, roundi(d.gaze.value), bonus, _idle_now(rules, acts)])


func _flame_phase(d: VigilFlameDirector) -> String:
	if d.home:
		return "home"
	if d.swapped:
		return "carry"
	if d.swapping:
		return "swap"
	return "watch" if d.appeared else "wait"


## Before the swap: the Faithful who could see it are the acolytes (wherever they are: they walk back to the bearer's
## side) and anyone else within FLAME_WATCH_R of the lantern. Bystanders going about their day within FLAME_STRAY_R
## are drawn off by a Will-o'-Wisp beyond them; once one Discord can take the watchers and, while he walks on, the
## bearer, it does (it blinds them and holds the lantern still); with nobody left to see, Wren is whispered to the
## lantern.
func _flame_swap(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var lantern := d.flame_at()
	if lantern == Vector2.INF or d.swapping:
		return
	var bearer: Person = d.vigil.bearer if d.vigil != null and MissionDirector._alive(d.vigil.bearer) else null
	var walking: Array[Person] = d.vigil.walkers() if d.vigil != null and d.vigil.active else ([] as Array[Person])
	var watchers: Array[Person] = []
	var strays := Vector2.ZERO
	var n_strays := 0
	for f in d.faithful:
		if f == bearer or d.faithful_seeing(f.ground_pos, 0.01, bearer) != f:
			continue
		var gap := f.ground_pos.distance_to(lantern)
		if walking.has(f) or gap <= FLAME_WATCH_R:
			watchers.append(f)
		if not walking.has(f) and f.mind in Person.LURABLE and gap <= FLAME_STRAY_R:
			strays += f.ground_pos
			n_strays += 1
	var w := d.wren
	if n_strays > 0 and _slot_ready(rules, slots, "wisp"):
		strays /= float(n_strays)
		var from := strays - lantern if strays.distance_to(lantern) > 0.5 else lantern - w.ground_pos
		var away := from.normalized() if from.length() > 0.01 else Vector2.RIGHT
		var lure := mission._crowd._grid.nearest_walkable(strays + away * FLAME_STRAY_LURE)
		rules.cast(slots.wisp, lure if lure != Vector2.INF else strays + away * FLAME_STRAY_LURE)
		return
	var held := bearer == null or bearer.mind in MissionDirector.BLIND
	if not watchers.is_empty() or not held:
		var take: Array[Vector2] = []
		if not held:
			take.append(lantern)
		for f in watchers:
			take.append(f.ground_pos)
		var mid := Vector2.ZERO
		for at in take:
			mid += at / float(take.size())
		var one := true
		for at in take:
			one = one and at.distance_to(mid) <= DiscordFx.DISCORD_R - FLAME_DISCORD_MARGIN
		if one and _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, mid)
			return
		if not watchers.is_empty():
			return
	if w.mind != Person.Mind.WHISPERED and not w.shaken() and _slot_ready(rules, slots, "whisper"):
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": lantern})


## Silent Doom at `at` would go unseen and take none of `spare` (v0.11 M6, plan decision 304): it takes someone; nobody living out of
## doors beyond its radius stands within Crowd.DOOM_WITNESS (and `margin` more, the final review: Exodus's EXODUS_MARGIN, room to spare
## so no one walking in while it falls sees it) of anyone within it; none within it is one of `spare`. Only reads.
func _doom_unseen(crowd: Crowd, at: Vector2, spare: Array = [], margin := 0.0) -> bool:
	var victims: Array[Person] = []
	var others: Array[Person] = []
	for group: Array[Person] in [crowd.citizens, crowd.soldiers]:
		for p in group:
			if not is_instance_valid(p) or not p.is_alive() or p.inside:
				continue
			if p.ground_pos.distance_to(at) <= SilentDoom.RADIUS:
				victims.append(p)
			else:
				others.append(p)
	if victims.is_empty():
		return false
	for v in victims:
		if spare.has(v):
			return false
		for o in others:
			if o.ground_pos.distance_to(v.ground_pos) <= Crowd.DOOM_WITNESS + margin:
				return false
	return true


## Exodus (v0.11 M6), with mission spec §2's policy (_exodus_act()), through _scripted().
func _exodus(which: String) -> void:
	var rules: Rules = mission._rules
	var d := rules.director as ExodusDirector
	var crowd: Crowd = mission._crowd
	var slots := _slots(rules)
	await _scripted("exodus", which, func() -> String: return _exodus_act(rules, slots, d, crowd),
		func() -> String: return "out=%d left=%d current=%d seizures=%d gaze=%d phase=%s" % [d.out_count(), d.left_count(), d.current(),
			d.seizures, roundi(d.gaze.value), d.hint_phase()])


## The believers still in the town and out of doors (v0.11 M6): the Dooms' spare list.
func _exodus_flock(d: ExodusDirector) -> Array:
	var out := []
	for c in d.charges:
		if not d._resolved(c) and not (c.man as Person).inside:
			out.append(c.man)
	return out


## Clears watcher `p` (v0.11 M6): Silent Doom unseen with EXODUS_MARGIN to spare (_doom_unseen()) on him and the nearest other watcher
## with him, else on him alone; else Discord where it holds two watchers (or him, with no whisper to send) and no believer; else, with
## `whisper`, Mind Whisper sends him EIGHT units off `from`. "" when no slot serves.
func _exodus_off(rules: Rules, slots: Dictionary, d: ExodusDirector, crowd: Crowd, p: Person, from: Vector2, whisper := true) -> String:
	var flock := _exodus_flock(d)
	if _slot_ready(rules, slots, "doom"):
		for v: Variant in d._watchers():
			if v != p and d._watching(v) and (v as Person).ground_pos.distance_to(p.ground_pos) <= 2.0 * SilentDoom.RADIUS - 0.1:
				var mid := ((v as Person).ground_pos + p.ground_pos) * 0.5
				if _doom_unseen(crowd, mid, flock, EXODUS_MARGIN):
					rules.cast(slots.doom, mid)
					return "doom two Inquisitors"
		if _doom_unseen(crowd, p.ground_pos, flock, EXODUS_MARGIN):
			rules.cast(slots.doom, p.ground_pos)
			return "doom an Inquisitor"
	if _slot_ready(rules, slots, "discord"):
		var held := 0
		var near_flock := false
		for v: Variant in d._watchers():
			if d._watching(v) and (v as Person).ground_pos.distance_to(p.ground_pos) <= DiscordFx.DISCORD_R - 0.1:
				held += 1
		for b: Variant in flock:
			near_flock = near_flock or (b as Person).ground_pos.distance_to(p.ground_pos) <= DiscordFx.DISCORD_R + 0.2
		if (held >= 2 or not (whisper and _slot_ready(rules, slots, "whisper"))) and held >= 1 and not near_flock:
			rules.cast(slots.discord, p.ground_pos)
			return "discord the Inquisitors"
	if whisper and _slot_ready(rules, slots, "whisper") and not p.shaken() and p.mind != Person.Mind.WHISPERED:
		rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": _prisoner_away(crowd, p, from)})
		return "whisper an Inquisitor off"
	return ""


## Household `i`'s look (v0.11 M6): its lamp free and not already walking, Mind Whisper sends it up to 10 units along its road to the
## nearest open gate -- stopping EXODUS_WAIT short of the gate while it is watched, and EXODUS_NEAR short of the first watcher on the
## way -- when that is more than EXODUS_STEP on; else the watcher nearest it on the way, or at its gate, is cleared (_exodus_off()).
## "" for nothing.
func _exodus_lead(rules: Rules, slots: Dictionary, d: ExodusDirector, crowd: Crowd, i: int) -> String:
	var lead := d.lamp(i)
	if lead == null:
		return ""
	var lp := lead.man as Person
	var road := d.road(i)
	var here := _road_progress(road, lp.ground_pos)
	var limit := here + MindWhisperFx.REACH - 0.5
	var exit: Vector2 = road.back()
	var g := -1
	for k in d.gates.size():
		if (d.gates[k] as ExodusDirector.Gate).way_out == exit:
			g = k
	var mouth := (d.gates[g] as ExodusDirector.Gate).mouth if g >= 0 else exit
	var at_gate := _road_progress(road, mouth)
	if g >= 0 and d.gate_watched(g):
		limit = minf(limit, at_gate - EXODUS_WAIT)
	var blocker: Person = null
	var block_at := INF
	for v: Variant in d._watchers():
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		var on := _road_progress(road, p.ground_pos)
		var off_road := p.ground_pos.distance_to(_road_ahead(road, road[0], on))
		var near_gate := p.ground_pos.distance_to(mouth) <= EXODUS_NEAR
		if not near_gate and (off_road > EXODUS_NEAR or on < here - EXODUS_NEAR or on > here + MindWhisperFx.REACH + EXODUS_NEAR):
			continue
		if not near_gate:
			limit = minf(limit, on - EXODUS_NEAR)
		var at := on if not near_gate else at_gate
		if at < block_at:
			block_at = at
			blocker = p
	var going := lp.mind == Person.Mind.WHISPERED and lp.goal() != Vector2.INF and lp.ground_pos.distance_to(lp.goal()) > LAMB_AHEAD
	if not going and _slot_ready(rules, slots, "whisper") and not lp.shaken() and limit - here > EXODUS_STEP:
		var to := MindWhisperFx.clamp_to(crowd._grid, lp.ground_pos, d._walkable(_road_ahead(road, road[0], limit)))
		if lp.ground_pos.distance_to(to) > 1.0:
			rules.cast(slots.whisper, lp.ground_pos, {"target": lp, "to": to})
			return "whisper the %s lamp on" % (d.households[i] as ExodusDirector.Household).name.to_lower()
	if blocker != null:
		return _exodus_off(rules, slots, d, crowd, blocker, lp.ground_pos)
	return ""


## One look of Exodus's policy (v0.11 M6, mission spec §2): what was cast, or "". The first that applies: a believer seized -- Discord on
## his seizer, else Mind Whisper sends the seizer off, else Silent Doom on him unseen; searchers out -- within EXODUS_HOUNDS of a
## believer, cleared (_exodus_off()), else Silent Doom on them unseen wherever they walk; a watcher about to see a believer (within
## SIGHT + EXODUS_WARN) -- cleared; a believer left out of his household's file -- whispered to his lamp; each household out, in order
## -- its lamp's way cleared and the lamp whispered on (_exodus_lead()); the next household within EXODUS_AHEAD -- the first watcher on
## its road or at its gate cleared by Silent Doom or Discord, and by Mind Whisper only within EXODUS_SOON. Never a loud power; every
## Doom unseen and sparing the believers.
func _exodus_act(rules: Rules, slots: Dictionary, d: ExodusDirector, crowd: Crowd) -> String:
	var flock := _exodus_flock(d)
	for c in d.charges:
		if not c.held or d._resolved(c) or not WarningDirector._alive(c.seizer):
			continue
		var s := c.seizer as Person
		if _slot_ready(rules, slots, "discord"):
			rules.cast(slots.discord, s.ground_pos)
			return "discord a seizer"
		if _slot_ready(rules, slots, "whisper") and not s.shaken():
			rules.cast(slots.whisper, s.ground_pos, {"target": s, "to": _prisoner_away(crowd, s, (c.man as Person).ground_pos)})
			return "whisper a seizer off"
		if _slot_ready(rules, slots, "doom") and _doom_unseen(crowd, s.ground_pos, flock, EXODUS_MARGIN):
			rules.cast(slots.doom, s.ground_pos)
			return "doom a seizer"
	for i in d.households.size():
		for p in d.searchers_out(i):
			var near := false
			for b: Variant in flock:
				near = near or (b as Person).ground_pos.distance_to(p.ground_pos) <= EXODUS_HOUNDS
			var from := (d.lamp(i).man as Person).ground_pos if d.lamp(i) != null else p.ground_pos + Vector2.LEFT
			if near:
				var did := _exodus_off(rules, slots, d, crowd, p, from)
				if did != "":
					return did
			elif _slot_ready(rules, slots, "doom"):
				for q in d.searchers_out(i):
					var mid := (p.ground_pos + q.ground_pos) * 0.5
					if q != p and p.ground_pos.distance_to(q.ground_pos) <= 2.0 * SilentDoom.RADIUS - 0.1 \
							and _doom_unseen(crowd, mid, flock, EXODUS_MARGIN):
						rules.cast(slots.doom, mid)
						return "doom the searchers"
				if _doom_unseen(crowd, p.ground_pos, flock, EXODUS_MARGIN):
					rules.cast(slots.doom, p.ground_pos)
					return "doom a searcher"
	for v: Variant in d._watchers():
		if not d._watching(v) or d._seizing(v):
			continue
		var p := v as Person
		for b: Variant in flock:
			if (b as Person).ground_pos.distance_to(p.ground_pos) <= EscortDirector.SIGHT + EXODUS_WARN:
				var did := _exodus_off(rules, slots, d, crowd, p, (b as Person).ground_pos)
				if did != "":
					return did
				break
	if _slot_ready(rules, slots, "whisper"):
		for i in d.households.size():
			var lead := d.lamp(i)
			if lead == null:
				continue
			var lp := lead.man as Person
			for c: EscortDirector.Charge in (d.households[i] as ExodusDirector.Household).members:
				if d._resolved(c) or c.held or c == lead or (c.man as Person).inside or (c.man as Person).shaken():
					continue
				var p := c.man as Person
				if p.ground_pos.distance_to(lp.ground_pos) > ExodusDirector.FOLLOW_REACH and p.mind != Person.Mind.WHISPERED \
						and d._file_spot(c) == Vector2.INF:
					rules.cast(slots.whisper, p.ground_pos, {"target": p, "to": MindWhisperFx.clamp_to(crowd._grid, p.ground_pos, lp.ground_pos)})
					return "whisper a believer back to his lamp"
	for i in d.households.size():
		var h: ExodusDirector.Household = d.households[i]
		if h.out and not h.done:
			var did := _exodus_lead(rules, slots, d, crowd, i)
			if did != "":
				return did
	var nxt := d.upcoming()
	if nxt >= 0 and d.due_in(nxt) <= EXODUS_AHEAD:
		var road := d.road(nxt)
		for v: Variant in d._watchers():
			if not d._watching(v):
				continue
			var p := v as Person
			for k in range(road.size() - 1):
				if _seg_dist(p.ground_pos, road[k], road[k + 1]) <= EXODUS_NEAR:
					var did := _exodus_off(rules, slots, d, crowd, p, road[k], d.due_in(nxt) <= EXODUS_SOON)
					if did != "":
						return did
					break
	return ""


## With the flame: Discord at the Temple's door in the last 20 s (the searching beam's noise, far from Wren); else, a
## beam due to come within FLAME_MARGIN of Wren on his way in the next FLAME_LOOKAHEAD seconds (its sweep is slow and
## plain to see) is drawn off by a Will-o'-Wisp beyond it where the fewest Faithful stand (the drawn kneel in its
## light), or Wren is whispered out of its way, if that is safer than walking on over FLAME_PLAN seconds (a whispered
## boy strolls there, then lingers): where he stands, or one of FLAME_DIRS spots half FLAME_DODGE or FLAME_DODGE round
## him; of those the beams keep clear of him, the one that costs him the least time to Mira's shrine, else the clearest.
func _flame_carry(rules: Rules, d: VigilFlameDirector, slots: Dictionary) -> void:
	var w := d.wren
	var light := d.searchlight
	if rules.time_left <= Searchlight.SEARCH_LAST + 1.0 and w.ground_pos.distance_to(d.temple_door) > FLAME_DANGER \
			and _slot_ready(rules, slots, "discord"):
		rules.cast(slots.discord, d.temple_door)
		return
	if _flame_clear(light, w, Vector2.INF, FLAME_LOOKAHEAD) > Searchlight.POOL_R + FLAME_MARGIN:
		return
	var grid := mission._crowd._grid
	if light.decoy_beam < 0 and _slot_ready(rules, slots, "wisp"):
		var beam := light.aim(_flame_threat(light, w))
		var lure := Vector2.INF
		var fewest := 0
		for k in FLAME_DIRS:
			var at := grid.nearest_walkable(beam + Vector2.from_angle(TAU * float(k) / float(FLAME_DIRS)) * FLAME_DODGE)
			if at == Vector2.INF or at.distance_to(w.ground_pos) < FLAME_DODGE + Searchlight.POOL_R:
				continue
			var n := 0
			for f in d.faithful:
				if MissionDirector._alive(f) and f.ground_pos.distance_to(at) <= WillOWisp.LURE_REACH:
					n += 1
			if lure == Vector2.INF or n < fewest:
				lure = at
				fewest = n
		if lure != Vector2.INF:
			rules.cast(slots.wisp, lure)
			return
	if w.mind == Person.Mind.WHISPERED or w.shaken() or not _slot_ready(rules, slots, "whisper"):
		return
	var walk_on := _flame_clear(light, w, Vector2.INF, FLAME_PLAN)
	var spots: Array[Vector2] = [w.ground_pos]
	for reach: float in [FLAME_DODGE * 0.5, FLAME_DODGE]:
		for k in FLAME_DIRS:
			var to := grid.nearest_walkable(w.ground_pos + Vector2.from_angle(TAU * float(k) / float(FLAME_DIRS)) * reach)
			if to != Vector2.INF:
				spots.append(to)
	var stroll := DummyEnemy.WALK_SPEED * w.pace
	var run := Person.PANIC_SPEED * w.pace
	var best := Vector2.INF
	var best_clear := 0.0
	var best_cost := 0.0
	for to in spots:
		var clear := _flame_clear(light, w, to, FLAME_PLAN)
		if clear <= walk_on:
			continue
		var cost := w.ground_pos.distance_to(to) / stroll + MindWhisperFx.LINGER + to.distance_to(d.shrine) / run
		var safe := clear > Searchlight.POOL_R + FLAME_MARGIN
		var was_safe := best_clear > Searchlight.POOL_R + FLAME_MARGIN
		var better := (not was_safe and clear > best_clear) if not safe else (not was_safe or cost < best_cost)
		if best == Vector2.INF or better:
			best = to
			best_clear = clear
			best_cost = cost
	if best != Vector2.INF:
		rules.cast(slots.whisper, w.ground_pos, {"target": w, "to": best})


## Where Wren will be `ahead` seconds on: whispered to `to` (Vector2.INF: not), strolling straight there; else walking
## his own path at his duty's pace, or standing while off his duty.
func _flame_wren_at(w: Person, to: Vector2, ahead: float) -> Vector2:
	if to != Vector2.INF:
		var stroll := DummyEnemy.WALK_SPEED * w.pace * ahead
		return w.ground_pos.move_toward(to, stroll)
	if w.mind != Person.Mind.DUTY:
		return w.ground_pos
	var left := w.walk_speed * ahead
	var at := w.ground_pos
	for k in range(w._leg, w._path.size()):
		var leg := at.distance_to(w._path[k])
		if leg >= left:
			return at.move_toward(w._path[k], left)
		left -= leg
		at = w._path[k]
	return at


## Where beam i's pool will be `ahead` seconds on, read off its plain path: on its decoy while that holds it, at the
## searched noise, else on its sweep; Vector2.INF while it is not yet lit.
func _flame_beam_at(light: Searchlight, i: int, ahead: float) -> Vector2:
	if ahead <= 0.0:
		return light.aim(i)
	if i == light.decoy_beam and ahead < light.decoy_left:
		return light.decoy
	if i == light.search_beam:
		return light.noise
	var t := light.beam_age(i) + ahead
	return light.sweep_point(i, t) if light.on and t >= 0.0 else Vector2.INF


## How near any beam's pool comes to Wren over the next `ahead` seconds, whispered to `to` or (Vector2.INF) not.
func _flame_clear(light: Searchlight, w: Person, to: Vector2, ahead: float) -> float:
	var out := INF
	var t := 0.0
	while t <= ahead:
		var at := _flame_wren_at(w, to, t)
		for i in Searchlight.MAX_BEAMS:
			var p := _flame_beam_at(light, i, t)
			if p != Vector2.INF:
				out = minf(out, p.distance_to(at))
		t += FLAME_STEP
	return out


## The lit beam that comes nearest Wren on his way over the next FLAME_LOOKAHEAD seconds.
func _flame_threat(light: Searchlight, w: Person) -> int:
	var best := 0
	var best_gap := INF
	for i in light.beams():
		var t := 0.0
		while t <= FLAME_LOOKAHEAD:
			var p := _flame_beam_at(light, i, t)
			var gap := p.distance_to(_flame_wren_at(w, Vector2.INF, t)) if p != Vector2.INF else INF
			if gap < best_gap:
				best = i
				best_gap = gap
			t += FLAME_STEP
	return best


## The Warning, played by one policy against the director's messenger (whoever carries the warning now: the
## watchman, a relay's witness, or the keeper once told). Every cast goes through Rules.cast() with what the real aim
## would give it, and only when the slot allows it. `t` is game time, as in _judgement().
func _warning(which: String) -> void:
	var rules: Rules = mission._rules
	var crowd: Crowd = mission._crowd
	var director := rules.director as WarningDirector
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var casts := {}
	var acts := _watch_idle(rules)
	var last_delay := ""  # mix: the power that last held him, so the other goes next
	var t := 0.0
	var frames := 0
	var report_at := 5.0
	var seen_phase := -1
	var seen_messenger: Person = null
	while not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		t += mission.get_process_delta_time()
		if director.phase != seen_phase or director.messenger != seen_messenger:
			seen_phase = director.phase
			seen_messenger = director.messenger
			print("BEHAVIOUR warning t=%.1f event phase=%s messenger=%s relays=%d" % [t,
				WarningDirector.Phase.keys()[director.phase], _warning_who(director.messenger, crowd), director.relays])
		if t >= report_at:
			report_at += 5.0
			print("BEHAVIOUR warning t=%d phase=%s messenger_mind=%s relays=%d bell=%s stage=%s" % [roundi(t),
				WarningDirector.Phase.keys()[director.phase], _warning_mind(director.messenger), director.relays,
				BellNetwork.State.keys()[crowd.bell.state] if crowd.bell != null else "none",
				crowd.alarms.stage_name()])
		if frames % 6 != 0 or which == "none" or (which == "toll" and not (rules.lantern != null and rules.lantern.tolled)):
			continue  # v0.11.2, D32: the toll case lets the bell toll, then plays `mix` against the Herald
		var m := director.messenger
		if not is_instance_valid(m) or not m.is_alive() or director.warning_dead:
			continue
		var running := m.mind == Person.Mind.DUTY
		var key := ""
		var at := m.ground_pos
		var extra := {}
		if slots.has("doom") and rules.refusal(slots.doom) == "" and _warning_alone(m, crowd):
			key = "doom"
		elif running:
			var order := ["whisper", "discord"]
			if (which == "mix" or which == "toll") and last_delay == "whisper":
				order = ["discord", "whisper"]
			for k: String in order:
				if k == "whisper" and m.shaken():
					continue  # v0.08.1: he shakes it off; the aim shows him in red
				if slots.has(k) and rules.refusal(slots[k]) == "":
					key = k
					break
		if key == "":
			continue
		match key:
			"whisper":
				var back := director.gate_spot - m.ground_pos
				if back.length() < 0.5:
					back = -_warning_heading(m)
				var to := MindWhisperFx.clamp_to(crowd._grid, m.ground_pos,
					m.ground_pos + back.normalized() * WARNING_WHISPER_BACK)
				extra = {"to": to, "target": m}
		if rules.cast(slots[key], at, extra) != null:
			casts[key] = int(casts.get(key, 0)) + 1
			if key in ["whisper", "discord"]:
				last_delay = key
			var sent := (" to %s" % (extra.to as Vector2).snapped(Vector2(0.1, 0.1))) if extra.has("to") else ""
			print("BEHAVIOUR warning t=%.1f cast %s at %s on %s (%s)%s" % [t, key, at.snapped(Vector2(0.1, 0.1)),
				_warning_who(m, crowd), _warning_mind(m), sent])
	var res := rules.result()
	var unseen := false
	for b: Dictionary in res.bonuses:
		unseen = unseen or bool(b.earned)
	print("BEHAVIOUR warning end case=%s won=%s reason=%s time=%.1f relays=%d unseen=%s solved_by=%s casts=%s idle=%.0f" % [
		which, rules.won, rules.over_reason, float(res.time), int(res.get("relays", 0)), unseen,
		",".join(res.get("solved_by", PackedStringArray())), casts, _idle_now(rules, acts)])


## Nobody would see Silent Doom take the person: nobody within Crowd.DOOM_WITNESS of them now, nor of where they will
## have run to when it strikes (SilentDoom.T_STRIKE on, along their way) -- the victims are fixed at the cast, but the
## witnesses are judged where they fall.
func _warning_alone(p: Person, crowd: Crowd) -> bool:
	var lead := _warning_heading(p) * p.walk_speed * SilentDoom.T_STRIKE if p.has_goal() else Vector2.ZERO
	return crowd.nearest_witness(p.ground_pos, p) == null and crowd.nearest_witness(p.ground_pos + lead, p) == null


## Who carries the warning, for the scenario's lines: the watchman, the keeper, or a citizen's (soldier's) index.
func _warning_who(p: Person, crowd: Crowd) -> String:
	if not is_instance_valid(p):
		return "none"
	if crowd.bell != null and p == crowd.bell.keeper:
		return "keeper"
	if p.profile != null and p.profile.role == CitizenProfile.Role.WATCHMAN:
		return "watchman"
	return ("soldier#%d" % crowd.soldiers.find(p)) if p.soldier else ("citizen#%d" % crowd.citizens.find(p))


func _warning_mind(p: Variant) -> String:
	if not is_instance_valid(p) or not p.is_alive():
		return "DEAD"
	return Person.Mind.keys()[p.mind]


## Which way the person is heading: toward the waypoint it is walking to, else its goal, else (1, 0).
func _warning_heading(p: Person) -> Vector2:
	var next := p._target if p._target.distance_to(p.ground_pos) > 0.05 else p.goal()
	var h := next - p.ground_pos if next != Vector2.INF else Vector2.ZERO
	return h.normalized() if h.length() > 0.01 else Vector2(1, 0)


## Living citizens' intents, by distance band (ground units) from `at`.
func _bands(at: Vector2) -> String:
	var bands := [[0.0, 6.0], [6.0, 12.0], [12.0, 20.0], [20.0, 999.0]]
	var parts := []
	for b in bands:
		var counts := {}
		for p: Person in mission._crowd.citizens:
			if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
				continue
			var d := p.ground_pos.distance_to(at)
			if d >= float(b[0]) and d < float(b[1]):
				var k: String = Person.Intent.keys()[p.intent()]
				counts[k] = int(counts.get(k, 0)) + 1
		parts.append("%d-%d:%s" % [b[0], mini(int(b[1]), 99), counts])
	return " ".join(parts)


## The Feast's act (`--path=`): the Festival unless it says the Procession.
func _feast_path() -> String:
	return "procession" if Battlefield.arg_value(OS.get_cmdline_user_args(), "--path") == "procession" else "festival"


## The campaign's Night 3 alone (v0.10 M5): nothing cast, or the act played by the night's policy; then its result.
func _feast(which: String) -> void:
	var path := _feast_path()
	print("BEHAVIOUR feast start path=%s bell=%s town=%s %s" % [path, mission.bell_rang, mission._crowd.profile.tier_name(),
		_budget(mission._rules, FEAST_SLOTS, FEAST_DP)])
	var done := [false]
	var feast_rules: Rules = mission._rules
	var acts := _watch_idle(feast_rules)
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR feast result won=%s reason=%s time=%.1f bonuses=%s idle=%.0f main=%.1f" % [r.won, r.reason, float(r.time), _earned(r),
			_idle_now(feast_rules, acts), feast_rules.main_time if feast_rules.main_done else -1.0])  # main: a board night's time to its main objective (held open to dawn)
		done[0] = true)
	if which == "play":
		_play_act(path)  # a coroutine left running beside the loop, until the act is over
	while not done[0]:
		await _frames(1)


## The drafted loadout against a budget: "loadout=a,b dp=3/10 slots=2/4 fits=true".
func _budget(rules: Rules, slots: int, dp: int) -> String:
	var keys := PackedStringArray()
	var cost := 0
	for i in rules.loadout.size():
		keys.append(rules.key(i))
		cost += int(rules.power(i).get("dp", 0))
	return "loadout=%s dp=%d/%d slots=%d/%d fits=%s" % [",".join(keys), cost, dp, keys.size(), slots,
		cost <= dp and keys.size() <= slots]


## Each bonus of a result and whether it was earned: "Before the bell:yes".
func _earned(r: Dictionary) -> String:
	var out := PackedStringArray()
	for b: Dictionary in r.get("bonuses", []):
		out.append("%s:%s" % [b.get("label", ""), "yes" if bool(b.get("earned", false)) else "no"])
	return ",".join(out)


## The Long Night (v0.09) forced through its acts, each ended as the command line asks (see the usage).
func _night() -> void:
	var args := OS.get_cmdline_user_args()
	var path := Battlefield.arg_value(args, "--path")
	path = path if path != "" else "festival"
	var outcome := {"omen": Battlefield.arg_value(args, "--act1"), "festival": Battlefield.arg_value(args, "--act2"),
		"procession": Battlefield.arg_value(args, "--act2"), "judgement": Battlefield.arg_value(args, "--act3")}
	if route == "b":
		for k in outcome:
			outcome[k] = "play"  # v0.11.1: every act plays its loadout B (RouteBook.ACTS_B) with tier5_b.gd's act_night()
	# A played night has its own casts to hand over, and the aid's Heaven Splitter would fall on the Prince in his first second.
	var calm_handover := "--calm-handover" in OS.get_cmdline_user_args() or "play" in outcome.values()
	var done := [false]
	var acts := [0]
	# v0.11.1 (route b): the night's clock and its longest stretch between two casts, across the acts.
	var night_clock := [0.0]
	var night_idle := {"last": 0.0, "longest": 0.0}
	mission.act_over.connect(func(r: Dictionary) -> void:
		night_clock[0] += float(r.time)
		print("BEHAVIOUR night act=%s won=%s reason=%s time=%.1f prince=%s" % [mission.act().id, r.won, r.reason, float(r.time),
			mission.night().prince])
		# Test aid: the Procession decides the Prince's outcome itself now; this forces it, over what it decided.
		var prince := Battlefield.arg_value(OS.get_cmdline_user_args(), "--prince")
		if prince != "" and mission.act().id == "procession":
			mission.night().prince = prince
			print("BEHAVIOUR night prince forced to %s" % prince)
		var festival := Battlefield.arg_value(OS.get_cmdline_user_args(), "--festival")
		if festival != "" and mission.act().id == "festival":
			mission.night().festival = festival
			print("BEHAVIOUR night festival forced to %s" % festival)
		acts[0] += 1)
	mission.finished.connect(func(r: Dictionary) -> void:
		print("BEHAVIOUR night end won=%s reason=%s time=%.1f path=%s acts=%d score=%d rank=%s" % [r.won, r.reason,
			float(r.get("time", 0.0)), r.path, (r.acts as Array).size(), int(r.score), r.rank])
		if route == "b":
			var total: float = float(r.get("time", 0.0))  # the night's own result already sums its acts
			print("BEHAVIOUR night result won=%s reason=%s time=%.1f idle=%.0f" % [r.won, r.reason, total, _idle_end(night_idle, total)])
		done[0] = true)
	if route == "b":
		_watch_night_idle(mission._rules, night_idle, night_clock)
	var seen := -1
	while not done[0]:
		if acts[0] != seen:
			seen = acts[0]
			if seen > 0:
				await _frames(10)
				if seen == 1 and not calm_handover:
					# Review focus 4: the act ends with the time scale dipped and a power still falling. Put in the
					# world by the old act's caster: its Rules is over and refuses a cast, and the night has no Heaven.
					Engine.time_scale = 0.3
					var heaven := load(String(PowerBook.get_power("heaven").path)) as GDScript
					mission._rules.caster.call(heaven, TownLayout.CITADEL_ORIGIN, {"dir": Vector2(1, 0)})
				mission.next_act(_loadout_for_next(outcome, path), path)
				if seen == 1:
					var rules: Rules = mission._rules
					var ready := true
					for i in rules.loadout.size():
						ready = ready and rules.cooldown_left(i) == 0.0
					# The old act's powers end with it (v0.09 final review): none of its effects is still playing.
					var playing := 0
					for c in mission._bf.ctx.overhead.get_children():
						playing += 1 if c is FxTimeline and not (c as FxTimeline).finished else 0
					print("BEHAVIOUR night handover time_scale=%.2f buildings=%d cooldowns=%s powers=%d" % [Engine.time_scale,
						rules.buildings_down, "ready" if ready else "waiting", playing])
				mission._intro_left = 0.0
				mission._rules.set_process(true)
			print("BEHAVIOUR night start act=%s town=%s" % [mission.act().id, mission._crowd.profile.tier_name()])
			if "--shots" in OS.get_cmdline_user_args() and mission.act().id == "festival":
				_festival_shots()  # a coroutine left running beside the loop
			if "--shots" in OS.get_cmdline_user_args() and mission.act().id == "procession":
				_procession_shots()
			var how := String(outcome.get(mission.act().id, ""))
			if route == "b":
				if seen > 0:
					_watch_night_idle(mission._rules, night_idle, night_clock)
				_play_act_b(mission.act().id)  # a coroutine left running beside the loop, until the act is over
			elif how == "play":
				_play_act(mission.act().id)  # a coroutine left running beside the loop, until the act is over
			await _frames(60)
			_force_act(how)
		await _frames(1)


## The loadout the next act is drafted when the policy plays it (Prepare's re-draft, simulated), else none: the act's own
## default stands, as it did before the policies.
func _loadout_for_next(outcome: Dictionary, path: String) -> PackedStringArray:
	var ids := mission.act().next
	var id := path if path != "" and ids.has(path) else String(ids[0])
	if route == "b":
		return RouteBook.loadout_b_for_act(MissionBook.LONG_NIGHT, id)
	if String(outcome.get(id, "")) != "play":
		return PackedStringArray()
	var asked := Battlefield.arg_value(OS.get_cmdline_user_args(), "--act3-loadout")
	if id == "judgement" and asked != "":
		return PackedStringArray(asked.split(","))
	return PackedStringArray(NIGHT_LOADOUTS[id])


## v0.11.1 (route b): the night's idle stretches, from `rules`' casts: each noted at the night's clock (the acts before it, then the act's own).
func _watch_night_idle(rules: Rules, acts: Dictionary, clock: Array) -> void:
	var offset: float = clock[0]
	rules.cast_made.connect(func(_slot: int, _key: String, _at: Vector2) -> void:
		_note_act(acts, offset + rules.elapsed()))


## v0.11.1 (route b): the act that is running played with loadout B (tier5_b.gd's act_night()), a look every LOOK_FRAMES, until it is over.
func _play_act_b(id: String) -> void:
	var rules: Rules = mission._rules
	var memo := {"act": id}
	var tier: GDScript = TIER_B[4]
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	var frames := 0
	var report_at := 15.0
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := rules.elapsed()
		if t >= report_at:
			report_at += 15.0
			print("BEHAVIOUR night play %s t=%d %s" % [id, roundi(t), String(tier.call("state_night", self, _route_ctx(memo)))])
		if frames % LOOK_FRAMES != 0:
			continue
		var did := String(tier.call("act_night", self, _route_ctx(memo)))
		if did != "":
			print("BEHAVIOUR night play %s t=%.1f %s" % [id, t, did])
	print("BEHAVIOUR night play %s end t=%.1f %s" % [id, rules.elapsed() if is_instance_valid(rules) else 0.0,
		String(tier.call("state_night", self, _route_ctx(memo))) if is_instance_valid(rules) and rules == mission._rules else ""])


## Play the act that is running with its scripted policy (`--actN=play`), until it is over.
func _play_act(id: String) -> void:
	match id:
		"omen":
			await _warning("mix")
		"festival":
			await _play_festival()
		"procession":
			await _play_procession()
		"judgement":
			await _play_judgement()


## The act's powers by key, to their slots.
func _slots(rules: Rules) -> Dictionary:
	var slots := {}
	for slot in rules.loadout.size():
		if rules.key(slot) != "":
			slots[rules.key(slot)] = slot
	return slots


## The Festival (Act II-A): from FESTIVAL_DOOM_AT, Silent Doom on the Mayor (a death the crowd panics at whether it is
## seen or not); then Discord on the densest cluster of goers, whenever it is ready. `t` is the act's own clock.
func _play_festival() -> void:
	var rules: Rules = mission._rules
	var d := rules.director as FestivalDirector
	var slots := _slots(rules)
	var casts := {}
	var doom_done := false
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed()
		if t >= report_at:
			report_at += 15.0
			print("BEHAVIOUR night play festival t=%d lost=%d/%d mayor=%s" % [roundi(t), d.count(), d.need,
				_warning_mind(d.mayor)])
		if frames % LOOK_FRAMES != 0 or t < FESTIVAL_DOOM_AT:
			continue
		if not doom_done:
			if not WarningDirector._alive(d.mayor):
				doom_done = true  # nobody to doom (or the Mayor is dead already): on to the Discord
			elif slots.has("doom") and rules.refusal(slots.doom) == "":
				var at := d.mayor.ground_pos
				if rules.cast(slots.doom, at, {}) != null:
					doom_done = true
					casts["doom"] = int(casts.get("doom", 0)) + 1
					print("BEHAVIOUR night play festival t=%.1f cast doom at %s on the Mayor" % [t, at.snapped(Vector2(0.1, 0.1))])
			continue
		if slots.has("discord") and rules.refusal(slots.discord) == "":
			var at := _densest(d.goers)
			if at != Vector2.INF and rules.cast(slots.discord, at, {}) != null:
				casts["discord"] = int(casts.get("discord", 0)) + 1
				print("BEHAVIOUR night play festival t=%.1f cast discord at %s" % [t, at.snapped(Vector2(0.1, 0.1))])
		# A Heaven Splitter, when the draft has one (v0.10 M5: the Feast's richer policy within 10 DP), at the densest knot
		# of goers. The night's own Festival loadout has none, so `night` plays as before.
		if slots.has("heaven") and rules.refusal(slots.heaven) == "":
			var hat := _densest(d.goers)
			if hat != Vector2.INF and rules.cast(slots.heaven, hat, {"dir": Vector2(1, 0)}) != null:
				casts["heaven"] = int(casts.get("heaven", 0)) + 1
				print("BEHAVIOUR night play festival t=%.1f cast heaven at %s" % [t, hat.snapped(Vector2(0.1, 0.1))])
	print("BEHAVIOUR night play festival end lost=%d/%d casts=%s" % [d.count(), d.need, casts])


## The centre of the thickest knot of these living people (those within DiscordFx.DISCORD_R of one of them), or INF.
func _densest(people: Array[Person]) -> Vector2:
	var best := Vector2.INF
	var best_n := 0
	for a in people:
		if not WarningDirector._alive(a) or a.inside:
			continue
		var sum := Vector2.ZERO
		var n := 0
		for b in people:
			if WarningDirector._alive(b) and not b.inside and b.ground_pos.distance_to(a.ground_pos) <= DiscordFx.DISCORD_R:
				sum += b.ground_pos
				n += 1
		if n > best_n:
			best_n = n
			best = sum / float(n)
	return best


## The Procession (Act II-B): Silent Doom on the Prince whenever nobody would see it (now, nor where he will have walked
## to), else Mind Whisper to send off whoever near him can hear it. His escort are soldiers, who hear neither Mind Whisper
## nor Discord, so the nearest attendant or onlooker (a citizen) within sight of him is the one sent, PROCESSION_SENT
## units straight away from him. `--doom-seen` (an aid for measuring the act's other end) also dooms him, seen, once he is
## on the dock's leg.
func _play_procession() -> void:
	var rules: Rules = mission._rules
	var crowd: Crowd = mission._crowd
	var d := rules.director as ProcessionDirector
	var slots := _slots(rules)
	var seen_ok := "--doom-seen" in OS.get_cmdline_user_args()
	var casts := {}
	# Looks taken while he walked; of them, with no soldier within Crowd.DOOM_WITNESS of him; with nobody (alone).
	var looks := [0, 0, 0]
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed()
		var p: Variant = d.prince
		var alive := WarningDirector._alive(p) and not d.boarded
		if t >= report_at:
			report_at += 15.0
			var w: Person = crowd.nearest_witness(p.ground_pos, p) if alive else null
			var near_now := _witnesses(crowd, p) if alive else Vector2i.ZERO
			var seen_by := "none"
			if w != null:
				seen_by = "%s %.1f" % [_warning_who(w, crowd), w.ground_pos.distance_to(p.ground_pos)]
			print("BEHAVIOUR night play procession t=%d leg=%d prince=%s witness=%s soldiers=%d citizens=%d" % [roundi(t),
				d.leg, _warning_mind(p), seen_by, near_now.x, near_now.y])
		if frames % LOOK_FRAMES != 0 or not alive:
			continue
		var alone: bool = _warning_alone(p, crowd)
		var near := _witnesses(crowd, p)
		looks[0] += 1
		looks[1] += 1 if near.x == 0 else 0
		looks[2] += 1 if alone else 0
		if slots.has("doom") and rules.refusal(slots.doom) == "" and (alone or (seen_ok and d.leg >= ProcessionDirector.DOCK_LEG)):
			if rules.cast(slots.doom, p.ground_pos, {}) != null:
				casts["doom"] = int(casts.get("doom", 0)) + 1
				print("BEHAVIOUR night play procession t=%.1f cast doom at %s on the Prince (%s, %s)" % [t,
					p.ground_pos.snapped(Vector2(0.1, 0.1)), _warning_mind(p), "alone" if alone else "seen"])
			continue
		if alone or not slots.has("whisper") or rules.refusal(slots.whisper) != "":
			continue
		var who := _nearest_hearer(crowd, p)
		if who == null:
			continue  # only soldiers about him: nobody to send
		var away: Vector2 = who.ground_pos - p.ground_pos
		if away.length() < 0.1:
			away = Vector2(1, 0)
		var to := MindWhisperFx.clamp_to(crowd._grid, who.ground_pos, who.ground_pos + away.normalized() * PROCESSION_SENT)
		if rules.cast(slots.whisper, who.ground_pos, {"to": to, "target": who}) != null:
			casts["whisper"] = int(casts.get("whisper", 0)) + 1
			print("BEHAVIOUR night play procession t=%.1f cast whisper on %s to %s" % [t, _warning_who(who, crowd),
				to.snapped(Vector2(0.1, 0.1))])
	print("BEHAVIOUR night play procession end prince=%s casts=%s looks=%d no_soldier=%d alone=%d" % [d.report().prince,
		casts, looks[0], looks[1], looks[2]])


## How many soldiers (x) and citizens (y) are within Crowd.DOOM_WITNESS of `of`, out of doors and alive.
func _witnesses(crowd: Crowd, of: Person) -> Vector2i:
	var n := Vector2i.ZERO
	for p in crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and not p.inside \
				and p.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS:
			n.x += 1
	for p in crowd.citizens:
		if is_instance_valid(p) and p != of and p.is_alive() and not p.inside \
				and p.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS:
			n.y += 1
	return n


## The nearest living citizen out of doors within Crowd.DOOM_WITNESS of `of` who is not shaking off a whisper, or null.
func _nearest_hearer(crowd: Crowd, of: Person) -> Person:
	var best: Person = null
	for c in crowd.citizens:
		if is_instance_valid(c) and c != of and c.is_alive() and not c.inside and not c.shaken() \
				and c.ground_pos.distance_to(of.ground_pos) <= Crowd.DOOM_WITNESS \
				and (best == null or c.ground_pos.distance_squared_to(of.ground_pos) < best.ground_pos.distance_squared_to(of.ground_pos)):
			best = c
	return best


## Act III: the Last Judgement's greedy caster, with this act's loadout (see _judgement()).
func _play_judgement() -> void:
	var rules: Rules = mission._rules
	var town: Town = mission._town
	var d := rules.director
	var casts := {}
	var fixed := Battlefield.arg_value(OS.get_cmdline_user_args(), "--act3-aim") == "fixed"
	var next := 0
	var frames := 0
	var report_at := 15.0
	var max_frames := int(rules.time_left * 2.0 * 60.0)
	while is_instance_valid(rules) and rules == mission._rules and not rules.finished and frames < max_frames:
		await process_frame
		frames += 1
		var t := d.timeline.elapsed() if d != null else 0.0
		if t >= report_at:
			report_at += 15.0
			print("BEHAVIOUR night play judgement t=%d citadel=%d%% stability=%s escaped=%d buildings=%d stage=%s" % [
				roundi(t), roundi(town.citadel.fraction() * 100.0), _stability(rules), rules.escaped_this_act(),
				rules.buildings_down, mission._crowd.alarms.stage_name()])
		if t < 5.0 or frames % LOOK_FRAMES != 0:
			continue
		for slot in rules.loadout.size():
			if rules.refusal(slot) == "":
				var at: Vector2 = JUDGEMENT_TARGETS[next % JUDGEMENT_TARGETS.size()] if fixed \
					else _richest(rules, mission._bf.ctx.env, mission._crowd)
				next += 1
				if rules.cast(slot, at, {"dir": Vector2(0.2, 1.0).normalized()}) != null:
					casts[rules.key(slot)] = int(casts.get(rules.key(slot), 0)) + 1
					print("BEHAVIOUR night play judgement t=%.1f cast %s at %s" % [t, rules.key(slot),
						at.snapped(Vector2(0.1, 0.1))])
				break
	print("BEHAVIOUR night play judgement end t=%.1f citadel_fell=%s stability=%s escaped=%d casts=%s" % [
		d.timeline.elapsed() if d != null else 0.0, town.citadel.is_fallen(), _stability(rules),
		rules.escaped_this_act(), casts])


## Where a cast would take the most of what City Stability still counts (Act III's policy, Task 19): each standing
## building and each living person out of doors weighs its share of its part's breaking point (Stability's own weights),
## and a part already broken weighs nothing. The point is a building's centre or a person, whichever has the most within
## RICH_R.
func _richest(rules: Rules, env: EnvironmentField, crowd: Crowd) -> Vector2:
	var st := rules.stability
	var pts: Array[Vector2] = []
	var ws: Array[float] = []
	for b in env.structures():
		if b.destroyed:
			continue
		var w := 0.0
		if Stability.INFRA_ROLES.has(b.role) and st.infrastructure > 0.0:
			w = Stability.W_INFRASTRUCTURE * b.footprint.get_area() / (st._infra_area * Stability.INFRASTRUCTURE_BROKEN)
		elif Stability.RESOURCE_ROLES.has(b.role) and st.resources > 0.0:
			w = Stability.W_RESOURCES / (float(st._resource_count) * Stability.RESOURCES_BROKEN)
		elif b.role == &"barracks" and st._barracks_count > 0:
			w = Stability.W_MILITARY * (1.0 - Stability.MILITARY_SOLDIER_SHARE) / float(st._barracks_count)
		elif b.role == &"citadel" and st.leadership > 0.0:
			w = Stability.W_LEADERSHIP * st.leadership
		if w > 0.0:
			pts.append(b.footprint.get_center())
			ws.append(w)
	var per_citizen := 0.0
	if st.population > 0.0 and crowd.spawned_citizens > 0:
		per_citizen = Stability.W_POPULATION / (float(crowd.spawned_citizens) * Stability.POPULATION_BROKEN)
	var per_soldier := 0.0
	if float(crowd.killed_soldiers) < float(crowd.spawned_soldiers) * Stability.SOLDIERS_BROKEN:
		per_soldier = Stability.W_MILITARY * Stability.MILITARY_SOLDIER_SHARE \
			/ (float(crowd.spawned_soldiers) * Stability.SOLDIERS_BROKEN)
	for p in crowd.citizens + crowd.soldiers:
		var w := per_soldier if is_instance_valid(p) and p.soldier else per_citizen
		if w > 0.0 and is_instance_valid(p) and p.is_alive() and not p.inside:
			pts.append(p.ground_pos)
			ws.append(w)
	var best := TownLayout.CITADEL_ORIGIN
	var best_w := -1.0
	for c in pts:
		var sum := 0.0
		for j in pts.size():
			if pts[j].distance_squared_to(c) <= RICH_R * RICH_R:
				sum += ws[j]
		if sum > best_w:
			best_w = sum
			best = c
	return best


## City stability and its five parts, in percent: total (population, infrastructure, leadership, military, resources).
func _stability(rules: Rules) -> String:
	var s := rules.stability
	return "%d%%(p%d i%d l%d m%d r%d)" % [roundi(s.total() * 100.0), roundi(s.population * 100.0),
		roundi(s.infrastructure * 100.0), roundi(s.leadership * 100.0), roundi(s.military * 100.0),
		roundi(s.resources * 100.0)]


## Act II-A's capture aid (v0.09 Task 13): a frame of the market at FESTIVAL_SHOTS' marks of the act -- the bonfires lit
## and the crowd packing (0:30, 0:50), the Mayor on the fountain (1:35) -- and the festival's count at each.
func _festival_shots() -> void:
	var bf: Battlefield = mission._bf
	var rules: Rules = mission._rules
	for mark: float in FESTIVAL_SHOTS:
		while is_instance_valid(rules) and not rules.finished and rules.director != null and rules.director.timeline.elapsed() < mark:
			await process_frame
		if not is_instance_valid(rules) or rules.finished:
			return
		bf.camera.zoom = Vector2.ONE * 1.5
		bf.camera.position = Iso.ground_to_screen(FESTIVAL_LOOK_AT).round()
		await _frames(3)
		await bf.save_capture("behaviour_festival_%d.png" % roundi(mark))
		var mayor := (rules.director as FestivalDirector).mayor
		if mark == FESTIVAL_SHOTS[-1] and mayor != null:
			# The address: a close-up of the Mayor himself, alone (the others hidden for the frame), to see his chain sit
			# on the chest.
			var hidden: Array[Person] = []
			for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
				if is_instance_valid(p) and p != mayor and p.visible:
					p.visible = false
					hidden.append(p)
			bf.camera.zoom = Vector2.ONE * 8.0
			bf.camera.position = Iso.ground_to_screen(mayor.ground_pos).round() + Vector2(0.0, -10.0)
			await _frames(3)
			await bf.save_capture("behaviour_festival_%d_mayor.png" % roundi(mark))
			for p in hidden:
				if is_instance_valid(p):
					p.visible = true
		var d := rules.director as FestivalDirector
		print("BEHAVIOUR night festival shot t=%d count=%d need=%d mayor=%s" % [roundi(mark), d.count(), d.need,
			d.mayor.mind if d.mayor != null else "none"])


## Act II-B's capture aid (v0.09 Task 16): a frame at PROCESSION_SHOTS' marks of the act, the camera near the Prince -- at the
## steps for the blessing, at the dock for the ship -- with his leg and the onlookers at each.
func _procession_shots() -> void:
	var bf: Battlefield = mission._bf
	var rules: Rules = mission._rules
	for shot: Array in PROCESSION_SHOTS:
		var mark: float = shot[0]
		while is_instance_valid(rules) and not rules.finished and rules.director != null and rules.director.timeline.elapsed() < mark:
			await process_frame
		if not is_instance_valid(rules) or rules.finished:
			return
		var d := rules.director as ProcessionDirector
		var look: Vector2 = d.route[d.route.size() - 1]
		if is_instance_valid(d.prince):
			look = d.prince.ground_pos.lerp(look, float(shot[2]))
		bf.camera.zoom = Vector2.ONE * float(shot[1])
		bf.camera.position = Iso.ground_to_screen(look).round()
		await _frames(3)
		await bf.save_capture("behaviour_procession_%d.png" % roundi(mark))
		print("BEHAVIOUR night procession shot t=%d leg=%d prince=%s to_look=%.1f onlookers=%d escorts=%d" % [roundi(mark), d.leg,
			d.prince.ground_pos if is_instance_valid(d.prince) else "gone", d.prince.ground_pos.distance_to(look) \
			if is_instance_valid(d.prince) else -1.0, d.onlookers.size(), d.escorts.size()])


## End the current act as asked: "win", "lose", or anything else to let it run.
func _force_act(how: String) -> void:
	var rules: Rules = mission._rules
	if how == "win":
		rules.force_end(true, "forced")
	elif how == "lose":
		if mission.act().id == "omen":
			mission._crowd.ring_bell()  # a lost Act I is a rung bell, as the night reads it
		rules.force_end(false, "forced")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


## Citizens by the kind of place they are nearest (within 1.5 units), or "walking"/"elsewhere".
func _places() -> Dictionary:
	var anchors := TownLayout.anchors()
	var out := {}
	for p: Person in mission._crowd.citizens:
		if not is_instance_valid(p) or p.state == DummyEnemy.State.DEAD:
			continue
		var kind := "walking" if p.has_goal() else "elsewhere"
		if kind == "elsewhere":
			var best := 1.5
			for k in anchors:
				for g: Vector2 in anchors[k]:
					var d := g.distance_to(p.ground_pos)
					if d < best:
						best = d
						kind = k
		out[kind] = int(out.get(kind, 0)) + 1
	return out


func _checksum() -> int:
	var h := 17
	for p: Person in mission._crowd.citizens + mission._crowd.soldiers:
		if is_instance_valid(p):
			h = (h * 31 + roundi(p.ground_pos.x * 100.0)) % 1000000007
			h = (h * 31 + roundi(p.ground_pos.y * 100.0)) % 1000000007
			h = (h * 31 + int(p.mind)) % 1000000007
	return h
