# KAK v0.11: every controller ruling

v0.11 "The Tiers" was built straight through, subagent-driven, from 2026-10-08 to 2026-10-16. Wherever the spec, the plan and the code disagreed, or a reviewer raised a design call, the controller decided rather than stopping, and wrote the decision down as a ruling: what was decided, why, and what it costs if it proves wrong. This file collects every ruling, milestone by milestone, from the six SDD ledgers. The mission specs' and plans' own numbered decisions are in docs/KAK_Version_0.11_Summary.md.

## M1 Framework (kak-v011-m1)

1. the plan's 30 "Plan decisions" (plan lines 102-183) are accepted as rulings, each with the cost the plan states — they settle details the spec left open; any later conflict resolves against the spec.
1. the spec's "at least 5:00 everywhere" applies to a night, not to each act — The Long Night's acts run under 5:00 each but the night runs about 10 minutes — cost if wrong: its acts need longer clocks.
1. the board Festival's crowd rises to 120 so "80 needed" is not every goer — cost if wrong: a busier square (frame rate) on the board Festival.
1. slots are capped at 6 (Tier 5's 6 + the slot upgrade) — the HUD row and keys 1-6 hold six — cost if wrong: the slot upgrade is worthless at Tier 5.
1. the Rescue wish's "child" is a same-household citizen and "exit" means the three gates — the town has no ages and its map exits are beyond whisper reach — cost if wrong: the wish reads slightly off its words.
1. only "cleared" carries over from v0.10 board saves — they hold no best times — cost if wrong: none.
1. G1 every task stages its .uid files; G2 every task touching mission.gd/rules.gd/crowd/directors runs the full exact reference list — the plan staged .uid in Task 2 only and skipped references in Tasks 3/9 — cost if wrong: longer task runs.
1. Task 4's teardown check sets up a star first — it asserted nothing — cost: none.
1. Task 6 seeds the wish draw from hash([night, mission_id]) and keeps a MissionDirector.reserved list that mid-night appointers (StarfallDirector) skip — restarts re-seed the town, and a later star's watchman could be a wisher — cost if wrong: a restart can pick a different target person for the same wish.
1. Task 7's RescueWish judges engagement first; the god's own cast on the soldier engages and grants, any other death before engagement fails the wish — the plan granted on any early death — cost if wrong: one more way to fail a wish.
1. Task 9 adds `--board` to scripted runs (board version for --mission-test/--bench) — spec §9's per-tier bench and board scenarios had no harness — cost if wrong: one more argument.
1. Task 11 also calls save.record() for banked board nights — the title's best would freeze at v0.10 — cost: none.
1. Task 4's Important finding is fixed in Task 6 with the `reserved` list it already adds (earlier stars' live runners reserved; _appoint_watchman skips reserved; test at 88 s) instead of a separate fix round — the same mechanism, built one task later, before any path can play the board Warning (Task 9) — cost if wrong: none if Task 6 lands it; the final review checks.
1. wiring-order, Procession-skips-reserved and one-Descent-per-night go into Task 9, the wiring task — none is reachable until Descent is wired there — cost if wrong: none if Task 9 lands them; the final review checks.
1. the Warning's later stars fall at their time or 30 s after the previous warning is stopped, whichever is sooner — the spec's fixed 0:10/1:30/3:00 leave ~70-85 s idle, against the user's binding no-waiting rule — cost if wrong: a faster board Warning (main objective sooner, more time for wishes).
1. on the board Vigil Flame, Wren's arrival (50 s) and own-try wait (30 s) are not stretched — the ×2 stretch made 1:40 and a 60 s wait — cost if wrong: Wren comes earlier relative to the stretched Vigil events.
1. a Rescue wish's soldier is turned only by the god's own effects; town orders (rally, posts) send him back on his errand — the rally granted the wish for free — cost if wrong: none.
1. the per-tier frame bench runs at landing on the merged tree (controller) — spec §9 gate — cost if wrong: none.

## M2 Whisper (kak-v011-m2)

1. the M2 mission spec's 29 decisions and the plan's 4 are accepted as rulings (spec "Decisions", plan decisions), except Decision 4 — cost if wrong: per decision, as stated there.
1. The Tax Collector has three targets in sequence (collector + two deputies), each next one out at its time or 30 s after the previous dies (rulings.md "Task 2") — overrides Decision 4: a single target dies at ~1:00, against the user's 5-minute rule — cost if wrong: a longer, more repetitive mission.
1. the Main Gate stands in for the "west gate" and the stone shrine post at the market's west edge for the "old well shrine" — the town has neither — cost if wrong: a mission brief that names places loosely.
1. First Prayers' idle loss at dawn (5:00) is allowed — no win waits for dawn; only doing nothing loses late — cost if wrong: none.
1. Task 7 updates test_tiers.gd's open_tier checks (Whisper needs 3 clears) — the plan missed them (blocking) — cost: none.
1. Task 2's chain delay is tunable 30-50 s and the schedule may move later so the median clear is 180-240 s — the 30 s chain could clear in ~2:30 — cost if wrong: a slightly slower mission.
1. Task 3 spoils a store at 10 s burning or when it falls — 15 s was unreachable (a house burns down in ~13 s) — cost: none.
1. Task 4: only the director's seizers seize the acolyte; tests for searchers and a freed escaped body — Decision 20 / review focus — cost: none.
1. Task 5 shares Mira's scenario and tags code instead of copying — duplication — cost: a small refactor; miras play must stay exact.
1. Task 6 updates test_wishes.gd:135 to the new pool — cost: none.
1. flushing the counting-house brings out only collectors out or hiding, not those waiting to set out — otherwise one blow at the door ends a three-target night — cost if wrong: smoking them out is less of a shortcut.
1. AssassinateDirector._appoint_target excludes already-appointed targets — reuse by The Informer/The Bishop could give every quarry one Person — cost: none.
1. Spoiled Harvest drops the seal: all granaries spoilable from the start, each with a watchman who smothers fire while calm and present; carts empty them on a staggered schedule; tune to median 180-240 s with no idle stretch over 60 s — the user's no-waiting rule is about play, and the sealed design was mostly waiting — cost if wrong: a retune of the mission (one fix round).
1. Spoiled Harvest's grain arrives one granary at a time (0:30, then each next at its time or 30-45 s after the previous is spoiled), with two watchmen per granary present from the start — the chain removes idle, the extra watchmen fill the wait with work; target median 180-240 s — cost if wrong: one more tuning round.
1. every remaining mission gate includes "no idle stretch over 45 s for an acting player", paced by the chain rule — Spoiled Harvest's sealed design was mostly waiting — cost: none.
1. Task 4 fix round: searchers only from soldiers on post; crowd.escaped counts as his escape; hints gain "Discord, or strike from clear" and a chain-the-whispers clause; doc tags — the reviewer's items 1, 2, 4, 5 plus the Concern 3 hint — cost: none.
1. First Prayers' dawn only marks roof_fallen; plus a "PRAYING n s" countdown tag on the shrine — a human needs the countdown the scripted policy reads — cost: none.
1. BailiffWish MIN_WALK 20 and its HUD text drops the misleading 0:50 countdown (the cap stays) — done in Task 7 with the tax-collector tag wiring and an end-to-end exclusion test — cost if wrong: the wish is slightly easier.
1. Task 8 also lands Task 7's minors 1-3 and 8 (best-line wrap per part, level card rules, bailiff route-length bound, explicit M1-save test) and a release note on the v0.10 carry-over — they show in Task 8's photos anyway — cost: none.
1. fix round: gate tag edge arrow on, Harvest camera_at shifted clear of the left stack, summary reworded, small docs — the user's top priority is objective clarity — cost: none.
1. the tags' frame has a dead zone under the left HUD stack (objectives/hint/wishes, ~230x70 px top-left) in every mission — a structural fix touching all missions' tags and tests; recorded as an explicit follow-up for v0.11's last milestone (M6 Ascendance's polish task) — cost if wrong: until then some tags in the top-left corner are hidden under panels.
1. accept Spoiled Harvest's moved references — they are M2's own new references (not the global exact list), the camera shift fixes a clarity gap, and the outcomes hold — cost: none.
1. the final fix wave takes the Important and all five minors — minors 1 and 4 are traps for Exodus and The Armoury, cheaper now than later; minor 2 may move Spoiled Harvest's own references (re-recorded, gate must hold) — cost if wrong: one re-recording of six harvest references.
1. declined-to-judge items (empty granaries smitten early; a collector carried out in an evacuation counts as taxes in; FLEE mind kept after an evacuation) accepted as designed — evacuation-only edges in an Unaware town, and every wait stays ≤60 s — cost if wrong: a rare odd outcome.

## M3 Omen (kak-v011-m3)

1. the M3 mission spec's 40 Decisions are accepted as rulings, with the four below — cost if wrong: per decision, as stated there.
1. the wish pool's growth (Decision 31) should leave Tier 1's seeded draws unchanged where the draw can filter before it draws; else update the pinned tests — draws that change silently cost re-checking M2's wish tests — cost: none.
1. Decision 16 shares Harvest's watchman record only if M2's harvest references as landed stay exact — cost: a copied rule.
1. Decision 24's Discord-then-Whisper step is kept only if the code lets a Whisper reach a confused person; the plan verifies — cost: a policy step.
1. Decision 26 (a contact killed before he is turned loses the night) stays, with a plain warning on the contact's tag, the hint and the tour ("turn him, do not kill him") — an instant loss is fair only if warned — cost if wrong: frustrating losses; playtest decides.
1. the plan's decisions 41-56 are accepted (Decision 31 replaced by ruling 3: Tier 1's draws unchanged via WishDef.min_tier / WishBook.pool_for) — cost if wrong: per decision.
1. M3 keeps TownLayout in its new code — feat/capital-city (City.current(), a grep guard for shared code) is not in Develop-Main; the capital session resolves mission_book.gd / mission_board.gd / behaviour_check.gd and any src/game/descend TownLayout use at its merge; M3's new wishes keep TownLayout reads to a few named lines — cost if wrong: a few more lines for that merge to convert.
1. (blocking) Task 3 — MarketPanicDirector clears a goer's fearless hold once no warden steadies him (Spoiled Harvest's _release way), so the warden test's last check can pass — cost: none.
1. Task 1 builds AssassinateObjective's running text from the director's safe label (M2's deferred minor); The Tax Collector's text stays "he runs for the Citadel" exactly; The Informer drops its HUD work-around if the base covers it — cost: none.
1. Task 2 — WATCH POST tags of waiting posts get edge arrows (spec and Task 7's photo check expect the south-west arrow at the start) — cost: none.
1. Task 2 — if the town calls its bellkeeper while a ringer holds the rope, the hand-back re-calls the keeper when the town is already at Local Emergency; a test pins it (review focus 2) — cost: none.
1. Task 2 — a relay never picks a carrier, ringer or mate of another warning (all RingerDirector-owned people are excluded as witnesses-to-carry); a test pins the climber killed in sight of the carrier waiting at the foot — one kill must not stop two warnings, and two directors must not fight over one man — cost if wrong: a relay slightly rarer.
1. Task 4 — all three contacts are tagged from the start ("CONTACT - DO NOT KILL" bright on the named one, "NO WORD YET - DO NOT KILL" pale on the others), so every contact whose death loses is warned; the hint and tour say so — clarity over mystery, per the user's priority — cost if wrong: a busier map.
1. Task 3 — the second-crowd walker test asserts the second crowd's own members, not a count that includes the first crowd's survivors — cost: none.
1. Tasks 1-4 run FLOW (alone, on a quiet machine: check Godot processes first) as M2 did — they change code FLOW exercises — cost: ~10 min a task.
1. baseline placeholders already filled: f05eda0 (tag kak-v011-m2, pushed), 5596 checks, FLOW 110 (the scan ran before landing) — cost: none.
1. refs24.sh runs six at a time (fixed-fps headless runs are deterministic under load) — 30 min to ~6 min a check — cost: none.
1. Task 1 fix round takes minors 1-3 (clamp the border point / grow DEAD, an off-screen NW negative check; labels() skips empty labels as M2's _labels(); _on_razed reuses i) — the kit is every later task's clarity guard — cost: none.
1. the post doors are each tower's town-side door (E inner door 18.9 units) — a ringer running outside the wall reads wrong and the tour must be true; moves this task's six (unlanded) references once — cost: none.
1. MATES back to 2 and CHAIN_WAIT back to 45 (Decision 6/8); the scripted policy removes a ringer's mates unseen before the kill (Doom from clear of others, or a fright/whisper to send one off), and acts elsewhere when a soldier watches a door, as a player would — tuning the opposition down to fit a weak policy cheapened the mission, and with 3 items capped by 45 s waits only work per item can reach 180 s — cost if wrong: one more tuning round, then a structural change ruled by the controller.
1. accepted deviations — mates stand beyond one Doom of the ringer at the door (Decision 6); WarningDirector._relay_witness() hook with a default that keeps The Warning exact; hint lines follow MATES (plural again at 2) — cost: none.
1. the landing gate runs ringers play seeds 4-5 too (the two wins straddle 180: 176.3 and 232.9) — evidence only; the gate stays seeds 1-3 — cost: ~5 min.
1. Impact gains a switch (default on) to skip hitstop; behaviour_check turns it off for the panic scenario (and later scenarios that cast Smite/Heaven), so their play checksums are exact references — hitstop is wall-clock time; no old scenario changes — cost: none.
1. Market Panic has four crowds of 12 (48 goers, need 36), the 4th from a new source, schedule 0:00 / 1:15 / 2:30 / 3:40 or 45 s after the previous is scattered; the guard closes the market at 5:00 (clock 5:30) — the clear is bound by crowds + 45 s chains, so only another crowd reaches 180 s without idle; the objective (scatter the fair) is unchanged — cost if wrong: a longer mission; playtest decides.
1. every crowd's goers are appointed at setup and kept on duty at their source until they walk in, so an evacuation (a loud cast, a seen kill) cannot silently empty a later crowd and make the night unwinnable — a player's natural Heaven Splitter must not be a hidden loss — cost: none.
1. the spec's §2 and its hint lines follow the tuned numbers (as M2's tasks did) — cost: none.
1. a goer of any crowd killed or scattered before he walks in counts toward the fair's need (the Festival counts any of its crowd), and the waiting crowd carries a tag saying so — otherwise 44 goers for 36 needed lets nine stray kills at a source make the night silently unwinnable; may move the six panic references (re-recorded) — cost if wrong: a player can work ahead on the sources, which is acting, not waiting.
1. before he sets out, only a waiting goer's death counts (held fearless, a fright does not break him) — counting danger would let one Smite clear a stand — cost if wrong: a stand is slightly harder to pre-clear.
1. Market Panic's crowds are 11 each (44 goers, need 36), not the 12 first ruled — with 12 the fourth crowd was never needed — cost: none.
1. the waiting crowds' gold pips plus the hint line meet the "tag saying so" ruling, with the hint's wording fixed in the final fix wave ("crowds still waiting count if struck down") — cost: none.
1. WAVE_AT's 70-75 s gaps are at-the-latest bounds while the waiting crowds stay strikable, so the player never waits; _waits pins WAVE_AT[0] and the 45 s chain — cost: none.
1. the contacts' doors are quiet ones (Decision 22's remedy) and the trail has a fourth contact (a fourth visit, chain 45 s), first visit at 45 s — waiting on street traffic for an unseen moment is waiting, against the user's rule; the clear is chain-bound, so only another item reaches 180 s (as Market Panic's fourth crowd); the objective (kill the informer before he reaches the Temple) is unchanged — cost if wrong: a longer trail; playtest decides.
1. the four unasked additions are accepted (the found informer held on duty; a contact leaving town loses at once; only a fresh whisper counts; the cold-trail banner once) — each closes a hidden loss or a lock — cost: none.
1. every mission task syncs its spec section to the tuned numbers (as Task 3 did) — cost: none.
1. the short, seen chase (the informer dies 8-10 s after he is found, seen near the Temple, so the bell is called) stands — the main objective is done by then, ASCEND banks the wishes, and an unseen kill is the skilled player's reward — cost if wrong: on the board a careless player loses his wish believers; playtest decides.
1. Task 5 starts while Task 4 is under review (different files: src/game/descend vs informer) — the user asked for speed; a Task 4 fix round would touch only informer files — cost if wrong: a suite rerun.
1. "unharmed" means unhurt — the wish's own name says so: FrightWish fails when the bully's health drops below a citizen's full health; plus the cheap test gaps (SHELTER once, a failed choose takes nobody, release() disconnects) and PressedWish's lead = the man who reached the son — cost: none.
1. TierBook.MISSION_TAGS gets "informer": ["hunts_informer"] in Task 6, with a test that The Informer's board night never draws the informer wish — the clash is declared but inert at HEAD — cost: none.
1. accept The Informer's moved references — its own new references, moved by a clarity fix, outcomes hold (M2's Spoiled Harvest precedent) — cost: none.
1. wish building tags (MONEYLENDER etc.) get edge arrows in the M3 final fix wave — nothing points at an off-screen wish house; tags are read-only, no checksum moves — cost: none.
1. the final fix wave takes the Important and all minors: walkers sent on duty (evacuation passes them, as waiting and arrived goers), held goers' _whisper_fled cleared / re-dutied before they wake to FLEE, the same for a whispered Informer contact; RingerDirector._relay_witness skips FLEE minds and reserved people, and a freed messenger with no fall marks the warning dead (RingerDirector only; base WarningDirector/StarfallDirector unchanged to keep the global references); StarsObjective reads a virtual on the director; plus every deferred minor in this ledger — cost if wrong: references of the M3 scenarios move (re-recorded, gates must hold).
1. M4-M6 adopt an evacuate-mid-mission test per mission (Kit.evacuate) and M4's MissionDirector hold/recall helper becomes the one shared rule — cost: none.
1. accept Market Panic's moved references (an evacuation-safety fix; outcomes hold, median 212.6) and leave the third WARDEN label and the wish tags under panels to M6's tag-frame dead-zone fix — cost: none.

## M4 Wrath (kak-v011-m4)

1. the M4 mission spec's Decisions 57-90 are accepted as rulings — cost if wrong: per decision, as stated there.
1. Decision 62 (stages instead of seals) is the right reading of Spoiled Harvest's lesson — every blow lands from 0:00, a target down when its time comes counts, so the player can work ahead; only fire on an unused target is put out — cost if wrong: a stage reads like a seal; playtest decides.
1. Decision 60 — the plan verifies Structure.restore() on the barn and the mill; if it fails, those two are mended only and the bridge alone is rebuilt — cost: a weaker rebuild threat.
1. the plan's decisions 91-120 are accepted — cost if wrong: per decision.
1. carried from M3 — every M4 mission gets an evacuate-mid-mission test (Kit.evacuate or equivalent); held people use the M3 fix wave's MissionDirector._keep_from_flight/_evacuation_began with M4's _recall_to as the one shared rule; relays skip FLEE and reserved people; the scripted policy works the opposition; chain-bound clears show the arithmetic — cost: none.
1. (blocking) Task 2 _relief and Task 4 _search_dropped call _come_to() by hand (headless people never think) after moving the man off post, then check the recall — cost: none.
1. (blocking) Task 3 _seized_at_once places the seizer with Kit.arrive, as The Lost Lamb's _taken does — cost: none.
1. (blocking) Task 5 leaves RuinWish as it is (its tags are already edged since M3's final wave); the barn wish drops its `edge` param and _barn expects the arrow — cost: none.
1. _recall_to() takes an `evacuating` flag and every M4 director runs _keep_from_flight() over all its held people each look (The Prisoner in its own step(), so The Lost Lamb stays exact); a captain whispered or recovering at the evacuation must not leave town and win the hunt by his absence — cost: none.
1. every M4 mission adds an evacuate-mid-mission test (one held person recovering, one whispered at the evacuation), not only at 0:00 — cost: none.
1. The Prisoner's stocks stand at least 4 units down the lane from the Citadel's gate, and the GAOLER tag and the hint warn plainly that a seizure takes her inside — a 1 s loss can't be acted on — cost: re-placed stocks; tuned by the gate.
1. The Heretic Hunt's captain chain is 30 s (his escorts may come out with him), so an acting player never waits a pure 45 s; the 45 s printed idle passed only by rounding — cost: a slightly quicker last item.
1. Tasks 2-4 drop their --board steps (missions join TierBook in Task 6, whose Step 8 runs each --board) — cost: none.
1. _flow_tier3 copies HEAD's _flow_tier2 shape (ascended check; guard before the ResultsScreen cast) — cost: none.
1. the controller adds run_half.gd to the workspace (the plan names it); Task 2 starts in parallel with Task 1's review (different files; a Task 1 fix would touch groundwork files only) — cost if wrong: a suite rerun.
1. Task 1 fix round takes Important 1-3 and the cheap minors (relief during an evacuation kept from flight; borrowed tower's damage_filter saved and restored; bound steps take the charge c; push_warning noise; weak checks (size, DUTY); both hunt timers set → assert or document one wins) — they are M6 reuse hazards — cost: none.
1. each shift man comes out to his own post (spread like the night crew), so one strike never clears a stage and the work per stage is real; retune with the first stage back toward 45 s if the gate allows — opposition is work, and a gate held up by a longer first wait is the waiting the user ruled out — may move bread's six references (unlanded) — cost: one tuning round.
1. fix round 2 adds _keep_from_flight before go_duty in _relieve, a test, and the cheap minors (rebuild pause pinned; whisper-after-evacuation check; a never-filled shift slot not relieved before its stage) — cost: none.
1. the stocks stand in the yard at the head of the west street (-6.25, -7.4), 4.25 from the Citadel's gate (the lane is ~2 units long), so a seizure is a ~10 s march with the GAOLER - SEIZES HER warning; PACE 0.33 at the bottom of the spec's range — cost if wrong: seed 3 sits near the 180 floor; playtest decides.
1. accept the hunt's tuning (first standard at 1:00 with measured idle 35 s — the parties give work before it) and the three test-forced placements — cost if wrong: median near the 180 floor; playtest decides.
1. the 30 s between the third standard and the captain gets its own hint phase ("the captain comes out in n s — set on his road") in the final fix wave — cost: none.
1. accept the two camera moves and their re-recorded references (clarity fixes; gates hold) — cost: none.
1. M5 and M6 camera checks use the real HUD stack depth (~240×165 px with the hint and three wish rows), not the kit's 240×100; the structural tag-frame fix stays M6's — cost: none.
1. (1) goes to M6 as a planned groundwork refactor — a Charge record holding the per-charge fields, current fields as accessors over charges[0], gated on the Lamb's and the Prisoner's six; Decision 67's "no base edits" is reworded in M6's plan — cost: an M6 task.
1. the final fix wave hoists one MissionDirector._hold_all(people, evacuating) (_keep_from_flight + _reassured_fled cleared) used by Hunt, Bread and Prisoner, with one policy: men away on an evacuation are recalled at once; plus minors 3 (free_by guard), 5 (document no chained time without head_at), 6 (relief back-off), 7 (hint: a standing standard first), 8, the 30 s captain hint (ruled earlier), and every deferred minor in this ledger — may move M4 references (re-recorded, gates must hold) — cost if wrong: re-recording.
1. minor 4 (HuntDirector._shield skips hit.emit; borrowed filters while standing; skip reserved towers) is recorded for M6's The Lantern's Eye groundwork — cost: none.

## M5 Reckoning (kak-v011-m5)

1. the M5 mission spec's Decisions 121-168 are accepted as rulings, except Decision 137 — cost if wrong: per decision, as stated there.
1. The Armoury does not bar its targets behind the horns (Decision 137 replaced): M4's staged pattern — every blow lands from 0:00, a target down when its horn sounds counts as razed, the night watch stands from the start; the horn brings that target's squad and starts the reinforcement clock — sealing targets behind a timer is the waiting Spoiled Harvest's sealed granaries taught us to avoid — cost if wrong: a skilled player can raze early; the chain still paces the reinforcements.
1. The Relic Run keeps its two-step design with Decision 153's one-halt fallback if the gate or playtest shows players waiting out the first halt; the halt windows (20-50 s) are the Steal type's own pressure, under the 60 s rule — cost: possibly the fallback.
1. the M5 plan's decisions 169-206 are accepted, except 177's "a target can only be razed while it musters": every blow lands from 0:00, armed men seal a target only while one stands guard, and a target down when its horn sounds counts as razed (the staged ruling) — cost: none.
1. (from M4) camera checks use the real HUD stack depth (~240x165 px with hint and three wish rows), not the kit's 240x100 — cost: none.
1. carried from M3/M4 — held people via MissionDirector._hold_all(people, evacuating) (one rule, recall away men at once); an evacuate-mid-mission test per mission; relays skip FLEE and reserved people; the scripted policy works the opposition; headless tests call _come_to()/_wake() by hand and place walkers with Kit.arrive; a relief no one can reach backs off; hitstop off in scenarios casting Smite/Heaven — cost: none.
1. (blocking) Task 5's _relic_act loop variable renamed (`e`) so behaviour_check.gd parses — cost: none.
1. all four M5 directors hold their people with MissionDirector._hold_all(people, evacuating) and recall away men at once on an evacuation (no fifth copy); a held listener lost to flight can never trigger THE FLOCK IS SCATTERED — cost: none.
1. The Sermon's and The Relic Run's reliefs (incl. _new_hands) copy The Crown's Bread's _relieve: flight-proofed after an evacuation and backed off when no one can reach — cost: none.
1. M5 camera checks use the real HUD stack (Kit.STACK 240x165 or equivalent); cameras move as needed (Bishop ~(2,-3), Sermon ~(-11,10.5)), re-recorded in the mission task; the Citadel-corner arrows are left to M6's HUD keepout — cost: none.
1. in The Sermon and The Relic Run the bell warning shows before the bell is called (a hint line while a witness runs / the Gaze rises), and a called bellkeeper gets a red BELLKEEPER tag with an edge arrow — clarity on a loss — cost: none.
1. Pip's tag keeps "DO NOT KILL" in every state (WAITING, THE RELIC) — cost: none.
1. The Armoury's reinforcements and reserve march from the Citadel's gate, not the armoury, so felling the armoury early razes a target but never cancels the reinforcement clock (the chain still paces them) — cost: none.
1. idle ≤45 s for an acting player: The Sermon's next wave comes at its time or ≤45 s after the last Believer is turned (not walked out); The Relic Run's carry is tuned so the policy keeps working (clearing watchers on Pip's road counts as work) and no stretch passes 45 s — cost: one tuning round.
1. The Sermon's _unwatch confuses anyone who sees the god's door (First Prayers' _blind), so its tests don't depend on stray Faithful — cost: none.
1. run_half.gd takes --part=N --of=M (quarters) — the second half nears the 10-minute cap — cost: none.
1. the bishop's escort Knights come out to their own posts spread more than two Doom radii apart (The Crown's Bread's shift ruling), so one strike never clears a refuge; retune with ARRIVE_AT back toward 45 s — a gate held up by a longer first wait is waiting — moves the six bishop references (unlanded) — cost: one tuning round.
1. accept The Armoury's spread squad, no relief for a downed target, and the not_yet phase — cost if wrong: seed 1 near the 240 ceiling; playtest decides.
1. Task 3 fix round: assert every post pair per target > 2 Doom radii; sweep the spec's stale bars/armoury-reserve text (684, 731, 795, 803, 805); _arms checks _reaches(post) and backs off; Kit.edged on GUARDED/plain/BURNING tags; the opening hint no longer says gold before a horn — cost: none.
1. Task 2 fix round 2: loop the spread test over all three refuges; restore the usage lines and the test's line continuation; drop _look_in (derive looking from _tick_in); Kit.edged on the REFUGE states; spec §1 CITADEL wording — cost: none.
1. accept The Sermon's rewritten policy (the brief's lost every seed: a Doom at the well killed listeners) and camera (-13,9.5); seed 1's idle 44 s stands (under the cap) — cost if wrong: thin idle margin; playtest decides.
1. Task 4 fix round: the rapt/coming hints say plainly not to kill his crowd (within the plate), and a banner on each listener death once the spare is 1 or 0 ("1 MORE LOST ENDS IT" / last); red marks on every living out-of-doors sentry not on guard; _bell asserts a keeper first; the camera check adds the sentry posts; spec §3 sentry-return wording; Will-o'-Wisp leaves The Sermon's default loadout (no lure takes a listener on duty) — replaced by a power the policy uses, spec synced; may move the sermon references only if the loadout change alters the scripted runs (re-record; gate must hold) — cost: none.
1. accept The Relic Run's tuning and its additions (the halted cart stays put; the win banner; the 40 s look-ahead as work on Pip's road) — cost if wrong: wins near the 180 floor and Gaze near full on some carries; playtest decides.
1. accept the photo-round tag wording (HORN for MUSTERS BY) over a camera move that would re-record six references — cost: none.
1. a family member (and the brother) who leaves town alive counts as escaped — the wish listens to crowd.escaped and records the id (spec's fail rule is "dies before escaping") — cost: none.
1. the Bishop's waiting tag becomes an edge tag; M6's keepout re-photographs The Bishop, The Sermon and The Relic Run — cost: none.
1. a target already down when the one before is razed sounds its horn at once (The Armoury; The Crown's Bread too if its references hold — else Armoury only, Bread noted for M6) — a very fast player must never wait 120 s — cost if wrong: re-recorded references.
1. before M6, MissionDirector._knight() hoisted (Bishop and Broken Lanterns use it; references exact) and the Relic Run's hidden ride named (_ride_in/_ride_step/_ride_out; references exact) for M6's Heart of Faith — cost: none.
1. the far-stall new-hands wait cap is left uncapped (measured 38-42 s against the 60 s rule) — cost if wrong: a rare far stall waits longer; M6 may cap it.

## M6 Ascendance (kak-v011-m6)

1. (1) goes to M6 as a planned groundwork refactor — a Charge record holding the per-charge fields, current fields as accessors over charges[0], gated on the Lamb's and the Prisoner's six; Decision 67's "no base edits" is reworded in M6's plan — cost: an M6 task.
1. minor 4 (HuntDirector._shield skips hit.emit; borrowed filters while standing; skip reserved towers) is recorded for M6's The Lantern's Eye groundwork — cost: none.
1. M6 also does the structural tag-frame dead-zone fix (left HUD stack ~240x165 with hint and three wish rows).
1. the M6 mission spec's Decisions 207-262 are accepted as rulings (own Gaze meter per new mission at 10 a seen death; Tier 5 wish draws may change, re-pinned and named; the Heart's litter reuses M5's Relic Run hidden ride, so M5 lands first) — cost if wrong: per decision.
1. the M6 plan's decisions 263-304 are accepted; Eye HUD row reads 'Blind the Eye: mirrors n / 3' (HuntObjective's fixed format) — cost: none.
1. (from M5 final review) Tier 5 board nights now hear the pyre/family wishes; Last Judgement and The Long Night declare no burns_temple — the M6 plan rules on that tag; bench The Sermon and The Relic Run in the v0.11 release bench — cost: none.
1. carried rules — MissionDirector._hold_all for held people (no copies), _knight() and the hidden ride (_ride_in/_ride_step/_ride_out) shared since M5's final wave; an evacuate-mid-mission test per mission; reliefs flight-proofed and backed off; camera checks Kit.STACK; the scripted policy works the opposition; a far wait never passes 60 s; FLOW alone; suite in quarters — cost: none.
1. (blocking) The Heart uses the inherited MissionDirector._knight(at, post) — no override (a different signature won't load; a copy is forbidden) — cost: none.
1. (blocking) Tasks 5-7 add their hint lines to tests/test_mission_hints.gd's SPEC table and keep every line within the three-line plate (shorten; never cut off) — cost: none.
1. The Heart's litter rides with the shared _ride_in/_ride_step/_ride_out — cost: none.
1. Exodus hooks enemy_killed so seen deaths fill its Gaze (and the loss is tested) — cost: none.
1. a household whose lamp got out by a gate that has since shut re-routes to the next open gate (the lamp passes on); never a silent loss — cost: none.
1. The Heart takes M5's horn rule (a target already down when the one before is razed comes into use at once) — cost: none.
1. a mirror needs Heaven Splitter and a Smite (the spec): glass hp tuned so one Heaven Splitter alone does not shatter it — cost: none.
1. The Eye shows a banner on every Gaze rise (spec §1) — cost: none.
1. the HUD keepout redraws the tag layer when the stack's size changes, and stack_rect() covers the stack whenever it is drawn (the tour too) — cost: none.
1. the HUD keepout task re-photographs The Bishop, The Sermon and The Relic Run (M5's ruling) — cost: none.
1. neither Last Judgement nor The Long Night declares burns_temple — their Temple is not a mission target, so the pyre and family wishes fit there — cost if wrong: a wish at a burning Temple; playtest decides.
1. the release bench includes The Sermon and The Relic Run — cost: none.
1. Task 6 (Exodus) carries Task 1's multi-charge minors: a test where charges[0] resolves first and the others keep stepping (own hold_at kept); a need>1 lost_reason() case; the base _step_hunters guards `not _alive(charge)` (one line) and Exodus overrides it per plan decision 268; a doc line that binding assumes one charge — cost: none.
1. accept Hud._label_beside() (a slid arrow's label moves beside its disc, outside the stack) — the keepout must never drop a label — cost: none.
1. the suite runs in eighths (`run_half.gd -- --part=N --of=8`) — quarter 4 nears 600 s under load — cost: none.
1. Task 3 fix round: a redraw test that changes only the stack (tags identical); stack_rect computed once per frame (cache hint_rect) to keep the signature cheap; a beside-the-diamond label fallback for edge map tags whose label would overlap the stack; STACK_PAD 8-10 so a slid arrow's disc never sits behind a plate; tighten _keepout_stack's tolerance — tags are read-only, no reference moves — cost: none.
1. M6 mission camera checks use the padded keepout (Kit.STACK grown by Hud.STACK_PAD, ~250×175) — the live keepout is padded — cost: none.
1. Tasks 5, 6 and 7 (the three missions) run in parallel — different director files; shared hunks staged by hand as before — cost if wrong: a suite rerun.
1. accept Exodus at 2/3 (the gate) and the south household's move — cost if wrong: the hardest mission at the floor; playtest decides.
1. Exodus fix round: tests for hounds/gate/shut/waiting phases and hint_seconds; the "shut" phase keyed to the gate the lamp is heading for; the last gate's tag/tour says it loses unless ten are out; BEATS doc comment — clarity on a loss — cost: none. The _doom_unseen margin refactor waits for the final fix wave (Task 5 owns the helper).
1. the kill that ends Odran wins the night before the Gaze is judged (the main objective is done first, as the board's rules hold the night after it) — a winning strike must not also lose — may move the heart references (re-record; gate must hold) — cost: none.
1. accept the oil-house's move to the quiet row behind the Temple and the Knights on each target's quiet side (the old spot was never free of a witness) — cost: none.
1. the Heart's Gaze pressure (50-70% before Odran) stands as Tier 5's finale; the policy's 60% seen-kill limit is its own choice — cost if wrong: a harsh last mission; playtest decides.
1. the tour line carries "lost unless ten are out"; the Main Gate tag stays "SHUT AT 5:00" (tag width) — the tour + spec state the loss — cost if wrong: a player who skips the tour learns it from the hint/results; final wave may add it if a tag fits.
1. the south-west mirror's wrights (and guards) work from the tower's quiet side — or a quieter wall tower is picked — so its last wright can be removed unseen; a busy street at a tower's foot is traffic luck (The Informer's lesson); retune with at most three rounds if needed; may move the eye references (re-record; gate must hold, median 180-240) — cost: one tuning round.
1. accept BLOW_MAX/HEAVEN_GAP (Heaven Splitter + a Smite to shatter), the re-planned posts and the careful policy — cost: none.
1. Heart fix round 2: tag every in-use unrazed target with its own state label (edge arrows), hint_phase prefers an unguarded one, a test with both in use; GazeMeter.drop_pending() replaces the private _deaths.clear(); reflow two joined lines; the recovering-Odran evacuation check asserts FLEE first; Kit.edged on the four KNIGHT tags — cost: none.
1. the MISSION_TAGS rows (exodus shuts_gates, heart_of_faith burns_temple) and board-night tests through Descent.hear land in Task 9 (in progress), which also fixes test_tier5_wishes:626 and test_heart_of_faith:120 to assert TierBook.board — cost: none.
1. the final fix wave extends tag_layout's placed rects to the timeline strip and the slot bar (as the keepout does for the stack) so plates avoid them — clarity — cost: none (read-only rendering).
1. the Eye's hint lines say plainly never to cast into the light at any time (SPEC table, spec lines) — cost: none.
1. every map tag that shows an event time counts down ("IN 0:45", "SHUT IN 0:45", "OUT IN 0:10") like the strip and clock, across v0.11's missions (Crown's Bread, Prisoner, Armoury, Bishop, Exodus, Heart, and any other absolute-time tag) — tags are read-only, no reference moves; label tests and spec lines follow — cost: none.
1. the final fix wave also takes: tag_layout's placed rects extended to the timeline strip and the slot bar (labels only; edge rules unchanged); hint lines and objective rows cached once per advance so stack_rect is cheap; the Heart spares the whole winning cast's strokes from the Gaze once stages_done; Exodus's hint follows the household that is acting (a lamp out of doors) before the first unfinished one; a guard on _keepout_point's centre fallback; docs (spec 328 "strip row", summary FURY wording); every deferred minor in this ledger — cost if wrong: re-recorded references if any move (they should not).
1. the clock area and arrow-disc overlap stay as recorded v0.11 follow-ups (no key target hidden) — cost if wrong: a cosmetic overlap until a later HUD pass.

1. accept v0.11's frame cost (~0.35 ms against v0.10, 0.3-0.5 ms against M5 — the HUD keepout's per-frame layout; every mission above 100 fps except the board Festival at 67, 70 at M5) and record a profile/caching pass as a follow-up — cost if wrong: a few fps until then.


## Merged v0.11.1 rulings (kak-v0.11.1)

v0.11.1 "Playtest round 1" was built straight through, subagent-driven, on 2026-10-17 and 2026-10-18; the controller's R0-R7 bind over the plan and spec text, and every `Ruling:` line of the task reports and commit bodies follows. Context, gates and open playtest notes are in `docs/KAK_Version_0.11_Summary.md`, "v0.11.1: Playtest round 1".

### Controller rulings (R0-R7, `.superpowers/sdd/v0111/rulings.md`)

1. R0: the pre-flight (4 blocking, 15 important, 20 minor findings) is accepted; every `Ruling:` in `.superpowers/sdd/v0111/preflight.md` (B1-B4, I1-I15, M1-M20) binds, except where R1-R3 choose.
1. R1 (M9): `resists_mind()` is also asked in `Person.compel()` and at every power-set `fight()` entry point now (it returns false, so nothing moves); its doc comment says it covers every god's hold, so the later "strong ones" are one override — cost if wrong: none today.
1. R1 (M11): no change to `MindWhisperFx.pick()` (nearest within PICK_R); noted as a playtest watch item, aim is the player's — cost if wrong: an annoyed player; the next playtest decides.
1. R1 (I10): Pip answers a lure only away from the halted cart, not aboard; loadout A's Wisp policy is unchanged — cost if wrong: none.
1. R2: Tasks 1-4 ran at once in four worktrees (suite `run_suite_parallel.sh 3`, references `--jobs=2`, no FLOW); Tasks 2 and 3 wrote their FLOW edits, the controller ran FLOW alone after merging 1→2→3→4; Task 4 created `tools/dev/gate.sh` (I15), Task 6 extended it — cost if wrong: a rerun.
1. R3: Routes keys are TierBook ids (M7); the tag is `kak-v0.11.1`.
1. R4: `gate.sh tax` (loadout A) idled 48-49 s at the start; Task 6 fixes it, policy first, else `SET_OUT_AT[0]` ≤ 35 s with the tax rows re-recorded — the user's no-waiting rule — cost if wrong: a 45 s empty open.
1. R5: CONFUSED joins the Armoury's `OFF_GUARD`, so Discord holds an armed man like a whisper (armed men stand fast against blows only, D21); a released soldier walks back at once; a hurrying soldier refuses lure/observe; citizens unchanged — cost if wrong: Armoury Discord route dead, B narrower.
1. R6: a tier mission's loadout B (not a ★) must have a median of 150-270 s, and `gate.sh` enforces it (no `--board`); a fast B is fixed by making the B power's work on the objective real (more casts, a guard, the target's own timing), never by touching A's knobs; A's gate is re-run after any director change. A ★ B main step under 90 s needs a reason in the report — cost if wrong: a trivial mission with that loadout.
1. R7: Last Judgement, The Long Night and Mira's House have no scripted loadout-A win in the references (`miras_play` is a gaze loss; judgement and night have no A rows); their B rows are recorded and reported like A's with no win required, and the playtest judges them — B is held to A's standard, not a stricter one — cost if wrong: a ★ B route may be unwinnable for a human.

### Task 1: the HUD collapses, edge arrows go bare

1. Ruling: the cue of an unscored mission lives inside the objective plate (the plate widens to first row + cue), a scored mission's on its Escaped line with the Gaze readout moved left of it — keeps `hint_top` = panel end + 4 and adds no keepout area — cost if wrong: a cue slightly off where the spec pictured it; a one-line move.
1. Ruling: the wish summary row shows a ticked box only when all N are granted, otherwise an open box (failed wishes just count in N) — cost if wrong: copy tweak.
1. Ruling: `Hud.reset_session()` clears `details` only; the flash is per-Hud instance state, so nothing else is static — cost: none.
1. Ruling: a hovered bare arrow shows its label even if it overlaps another plate and does not join `placed` (no flicker for others) — cost: an occasional overlap while hovering.

### Task 2: the opening shows one thing at a time

1. Ruling: the prayers hold also waits for the opening banners (a sweep intro and a tour alike) and `praying` is false while any banner shows — because Last Judgement's MANIFEST banner outlasts its 2.0 s sweep — cost if wrong: the board night's intro runs about 0.2-2 s longer than 2.0 + 3.0 (FLOW waits on the state, not a fixed time).
1. Ruling: while a banner is up during the tour the caption is blanked by Mission (`_hud.caption()` reads ""), not only hidden by the HUD, because FLOW and tests read `caption()` — cost: none.
1. Ruling: `_hud.intro`/`praying` are synced from `_intro_left` at the top of `_process()` (and in `start()`/`next_act()`), so behaviour_check, which zeroes `_intro_left` after start, never leaves the HUD in intro — cost if wrong: its captures would miss the stack.
1. Ruling (fix round): `Mission._unhandled_input` skip no longer needs a tree (an `is_inside_tree` guard), so the stub Mission in the suite can test it; any intro (a sweep, the prayers hold) skips on Space/Enter/click — cost if wrong: none.

### Task 3: the H legend

1. Ruling: Mission-level legend tests use a stub Mission (the suite has no scene tree) — cost if wrong: `start()`'s own call to `_close_legend()` and the real Esc routing are only proved by FLOW.
1. Ruling: while the legend is open the mission ignores every event except H (page turn) — spec §4 — cost if wrong: none (the mission is also frozen).
1. Ruling: `Hud.paint_arrow()` (static, on any canvas) next to M5's `arrow_shape()`, because the legend needs the disc and ring as well as the triangle — cost if wrong: one small extra function in hud.gd.
1. Ruling: opening the legend cancels a held press (`_aim.cancel()`, `_pressing = false`), otherwise its release after the panel casts — cost if wrong: none visible.

### Task 4: the Tax Collector's burning counting-house empties

1. Ruling (M1): The Heart of Faith is not an `AssassinateDirector` subclass; one check each in test_bishop and test_informer that only the Tax Collector flushes — cost: none.
1. Ruling: a quarry flushed while HIDING or VISITING-in-hideout also becomes `flushed` and raises the same single banner — the spec says "everyone still inside", and a hider flushed into a re-lit fire must not turn back (M19) — cost if wrong: a hiding collector's flushed run raises no "A DEPUTY HIDES" banner.
1. Ruling: once the flush begins (`burst_in` set) it completes though the fire is put out — the building's occupants were told to run — cost if wrong: only matters with FLUSH_GAP > 0.
1. Ruling: the idle in tax and harvest counts the stretch from t=0 to the first cast and from the last cast to the end, as `_scripted()` does — the same definition for every gate.
1. Ruling: `gate.sh` takes `--jobs` (default 6) so the parallel phase can use 3 — cost: none.

### Task 5: soldiers hear the god (code)

1. Ruling: a soldier let go goes back at once (no RECOVER wait) — the saved state is the post — cost if wrong: none seen.
1. Ruling: lure/observe refuse a hurrying soldier (an escort or rescuer running) — cost if wrong: a running man can't be lured.
1. Ruling: soldiers panicked or looking via `_react` do not yelp or pass a fright on — keeps the citizens' RNG stream and voices — cost if wrong: quieter soldiers.
1. Ruling: `held_by_god()` guards use `p.soldier and ...` at shared sites so lured citizens are retaken as before (references) — cost if wrong: a lured citizen watchman is retaken (as today).
1. Ruling (original text, overruled by R5): armoury CONFUSED left out of `OFF_GUARD` — armed men are lay watchmen — R5 then added it.
1. M9 (R1): `resists_mind()` also in `compel()` and the power-set `fight()` entry points. M10: a maddened soldier's PANIC/ERRATIC outcomes now act (only where Madness is cast, which no A policy does). M11: `MindWhisperFx.pick` unchanged — a playtest watch item.
1. Ruling (fix round): `forget_hold_duty()` also resets a saved ASSIST — same stale-state reason — cost if wrong: none.

### Task 6: every moved reference re-recorded; every gate re-run

1. Ruling: tax `SET_OUT_AT` 35/95/155 and `VISIT_SECONDS` 20, the policy smokes the next collector out after 42 s idle — the 45 s opening and the 45 s chain wait made idle 48-49 and nothing useful exists to do before 0:45 (guards 2,2,1 and a 38 s smoke were tried and dropped) — cost if wrong: a slightly tighter opening; seed 1 wins at 243.7 s (> 240) though the median is 199.
1. Ruling: `RescueWish.turned_man()` is applied to PressedWish and BailiffWish too (they copy `_turned`) — same bug, same soldiers — cost if wrong: a lured press-ganger or bailiff counts as turned and grants the wish.
1. Ruling: scripted policies are not changed to whisper/Discord soldiers (the ringers and eye "none a soldier" filters stay) — every gate passes with them — cost if wrong: B policies write their own.
1. Ruling (commit): armoury CONFUSED joins `OFF_GUARD` (R5); no Armoury checksum moves.
1. Task 5 leftovers done: `EscortDirector._on_escaped` uses the same seizer release (`_let_go_seizer`); a lured soldier on a Rescue wish ends it as granted.

### Task 7: second-route groundwork

1. Ruling: `answers_lure` persons are drawn only within `CHARGE_LURE_R` whatever their mind (not only on DUTY) — Decision 28: a charge answers a Wisp near him only — cost if wrong: a calm charge walking elsewhere is drawn by a distant Wisp.
1. Ruling: the director's Blight banner is emitted by BlightFx (`ctx.rules.banner`), not Mission — cost if wrong: a second place says "BLIGHT - ...".
1. Ruling: `blight_target` is asked first; a hit blights no structure even when one is also in reach — cost if wrong: a standard beside a well ruins nothing else.
1. Ruling: feast `--board` sets mission_id to the board id for route a too — cost if wrong: none.
1. Ruling (commit): `lamb_play_1..3` mismatch on the Task 7 branch exactly as on its base (Task 5's soldier rule); Task 6 re-records them.
1. Fix round: a charge obeys `CHARGE_LURE_R` in `lure()` for every source (Death Mark's gawkers too) and returns to his duty; a guarded Blight costs no alarm (`blight_takes`); `--route=` other than a or b is an error; `refs_check.sh` refuses duplicate row names.

### Task 8: Tier 1 second routes

1. Ruling: Warning B is deathmark, whisper, discord; the runner is led (Whisper) to the quietest spot within 40 u of walking (outside the walls) and marked there when nobody is within 3.5 — the street round every gate is never clear for ten seconds — cost if wrong: a longer first star.
1. Ruling: Tax B does not kill the bellkeeper (Smite cooldown 10 s > the bell's 8 s climb after a seen kill), so seen Smite kills are forced only for the last collector (the win comes first) — cost if wrong: median 217 relies on that.
1. Ruling: Lost Lamb — the audit's "a Wisp's lure draws him" was wrong (he holds on DUTY); the acolyte now answers a Wisp from `WillOWisp.LURE_REACH` (6.0) and his lure lasts his slow walk + 5 s — cost if wrong: a Wisp cast for bystanders within 6 pulls him.
1. Ruling: Harvest B fells a granary (Heaven, Whisper on its watchmen beforehand) at 45/30/15 s before its grain; a fall before grain is judged when the grain comes — cost if wrong: none.
1. Ruling: lamb B uses Silent Doom regardless of witnesses (a death seen does not lose the Lamb) — cost if wrong: more alarm.
1. Ruling (fix round): the First Prayers fetch reaches only from a light at the shrine (`FirstPrayersDirector._on_light`, FETCH_R 16, stare 6 s), not from a Wisp cast anywhere — cost if wrong: none today.
1. First knob: `TaxCollectorDirector.FLUSH_GAP` 0.0 → 1.5 (at 0 a Smite on the burst cluster took 2 of 3).

### Task 9: Tier 2 second routes

1. Ruling: Bell-Ringers B is Death Mark, whisper, wisp (not Smite) — Smite is dodged by anyone free to run (threat registered at cast, bolt 0.35 s later, KILL_R 0.6) — cost if wrong: B's main power differs from the spec row.
1. Ruling: the ringers' mates answer a Wisp's lure (`answers_lure`, left staring) — the spec's "the Wisp clears his mates" was false for men on duty — cost if wrong: none for A.
1. Ruling: The Informer's company are spotted within 1.0 of the door (one Discord must hold contact and company) — cost if wrong: informer A rows moved (re-recorded, A gate still 3/3, 189 s).
1. Ruling: Broken Lanterns B first casts the Parade on the bell tower (Dragonfire is loud, the keeper rings within 12 s, B has no Doom) — cost if wrong: one 54 s cast spent; wins at 199-253 s.
1. Ruling: Market Panic B plays Ember on a house by the next crowd's road 12 s before it sets out (fire frightens walkers; no warden steadies the road) — cost if wrong: one ember.
1. Ruling (fix round): the Informer's B kill is Death Mark, not Smite — a free runner dodges the bolt — cost if wrong: loadout differs from spec row 10.
1. Ruling (fix round): Market Panic B drops Discord for Death Mark — fire alone left a coin flip at 35 of 36 — cost if wrong: loadout differs from row 9.
1. Ruling (fix round): a lured man is passed over by the Bell-Ringers' relay (`Person.lured()`) — the Wisp's draw must clear witnesses for the second family to be real — cost if wrong: Death Mark's gawkers (lured) pass over too, after the body.

### Task 10: Tier 3 second routes

1. Ruling: Festival B's main step is under 90 s (45 s median) — the board Festival's need is 80 of 120 and Heaven Splitter along a Wisp-drawn knot breaks about 50 per cast (A's pool allows Heaven; A's own win waits for the Mayor at 95 s); the policy casts from t=0 to keep idle under 45 s — cost if wrong: a quick ★ Festival; a playtest note, no knob.
1. Ruling: Mob Verdict judges the stone bridge (`CongregationFx.place_for(bridge_ok)`) — the row 13 failure was a walkable-structure skip, not a damage filter; no `mob` kind change in CrownsBreadDirector — cost if wrong: Verdict also judges the bridge in the Armoury and Last Judgement (harmless).
1. Ruling: Bread B does the Mob Verdict's work on the granary and the bridge and Heaven on the mill, with a Wisp ahead of each stage — Heaven alone razes every stage at its opening and the chain fixes a floor of about 140 s, under R6's 150 — cost if wrong: with Heaven in an A-like draft the Crown's Bread is a 140 s mission; the chain was not touched.
1. Ruling: The Prisoner — a freed charge on duty is deaf to a Wisp, so she answers a Wisp within `WISP_R` 5.0, hurries to it while drawn, holds where it leaves her (director-only, A unaffected) — cost if wrong: the Lamb and Exodus charges have the same gap and need their own answer.
1. Ruling: Vigil Flame — Wren `answers_lure` from when he comes; a lure counts as the god's hand (whispered, left be); a drawn Wren starts the swap within `LURE_SWAP_REACH` 2.4; a Wisp within `CHARGE_LURE_R` of Wren is no noise or decoy to the light — cost if wrong: flame A rows move (they did not).
1. Ruling: Hunt B kills guards with Death Mark (one per sweep, 25 s ahead), Discord holds the last, Blight breaks the standard; Blight rots an unguarded standard through a blow (a guarded one costs no alarm; targeting rings it red) — cost if wrong: Blight's route is louder than "quiet".
1. Ruling: Flame B uses Silent Doom on bystanders about the lantern instead of A's Wisp draw-off, because the Wisp is also the lure that draws Wren (30 s cooldown) — cost if wrong: Faithful die for it.

### Task 11: Tier 4 second routes

1. Ruling: Procession B's main step is Death Mark (RouteBook `b` smite → deathmark) — Smite on the Prince is a gamble (the cast frightens him and he runs against KILL_R 0.6) — cost if wrong: the "strike" family has no route on the Procession.
1. Ruling: Sermon listeners draw a Wisp from `WillOWisp.LURE_REACH` (new `Person.lure_reach`), not `CHARGE_LURE_R` — with 3.0 only wave 0 (3 of 12) can be reached and 8 Believers are impossible — cost if wrong: Sermon B unwinnable.
1. Ruling: a waiting wave and a Believer do not answer a lure — cost: B slightly slower.
1. Ruling: Relic Pip's anchor follows him while lured and a lured Pip boards from the Wisp's ring; a Wisp at a halted cart cannot draw him (R1/I10), so B sends him by Oathbound's hold-a-place — cost: none.
1. Ruling (fix round): Bishop and Armoury pace is made by the guards (a blow-sealed refuge while a Knight stands guard; a stone target before its horn), not by timers — the B power's work must be real (R6) and A never meets either rule — cost if wrong: A hints or behaviour drift (none seen).
1. Ruling (fix round): the Relic watch lure is keyed on `pip_led` (Pip COMPELLED or Wisp-lured, never whispered), so A (whisper) is untouched — cost: a B-only mechanic.
1. Ruling (fix round): the Procession's carriage (the Prince waits inside until `EMERGE_AT`, ~83 s) is on the board only; the Long Night's act is unchanged.

### Task 12: Tier 5 second routes

1. Ruling: Exodus B is led by Oathbound HOLD A PLACE, not the Wisp — a held charge is on duty and no Wisp draws him, and a cast moves a household about 4 units against a 12-16 unit road — cost if wrong: B's main step reads as the lead family, not draw (the one same-family exception; commit 04c52d0).
1. Ruling: Heart B never uses Discord (a Knight guards by position, not by mind) and never fells a target ahead of its time — cost: none.
1. Ruling: Heart bearers are struck only where the Smite goes unseen or after a one-witness hush, with a Death Mark within a Gaze cap of 60 as last resort — a loud fall made every seen death 20 Gaze.
1. Ruling: the Night's idle is counted across acts from `Rules.cast_made` at the night's clock; the night result's `time` is the night's own sum.
