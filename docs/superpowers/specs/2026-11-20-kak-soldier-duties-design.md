# Soldier duties: a Citadel guard, patrols, corpses, cordons, sweeps, gate checks, shelter escorts (design)

Date: 2026-11-20. Branch: `feat/soldier-duties` (from origin/feat/Develop-Main a5825501). Build with the kak-milestone
skill, one slice at a time. Source: Discord idea "Soldier Behavior Adjust". Every choice is marked `[user]` (the user
decided it) or `[call]` (the designer's; change it freely, the reason is given).

## Why

At City Emergency every free soldier runs to the Citadel and shuffles round it at a run. The user: "I want them to
behave more like soldier. patrol around the city, repair some building, escort citizen etc. I don't want them to gather
around citadel and panic around it like today." Later: "inspect some corpse around city and remove them off the street."
For the player (the god) soldiers become readable opposition spread over the town: each duty costs something and each
can be broken, lured or used.

## What the code does today (checked on a5825501)

- A soldier is a `Person` with `soldier = true`. `Crowd.rally()` (crowd.gd:2071) sends **every** living corps-NONE
  soldier, mission-placed ones too, to a slot on a ring of `RING_RADIUS` 3.4 as `Mind.RALLY`. It is never undone. It
  closes the job board (`GuardJobs.close()`, guard_jobs.gd:130). It fires at City Emergency (`_on_stage`, crowd.gd:1853),
  on the first Citadel hit (crowd.gd:2560) and from `JudgementDirector` (judgement_director.gd:31).
- The "panic" look: `Mind.RALLY` moves at `PANIC_SPEED` (person.gd:882), draws the `run` clip (person.gd:3178) and at
  its slot falls through `_pick_target()` to `_drift()` (person.gd:1007), so he keeps running small steps for ever.
- The ring is the garrison: `Crowd.ring_count()` (crowd.gd:2101) feeds `Citadel.garrison_cut()`: 2% per man, cap 30%
  (citadel.gd:31). So **15 men give the full cut**. The ring is also the reserve: `_refill()` (crowd.gd:2115) replaces
  a dead marshal, escort or rescuer from it.
- Posts: yard, walls, Citadel, patrol (`post_group` 0-3; Aldermere 30/30/20/20, the Capital its own, about 180).
  Street pairs stand still in both towns. Only the Capital has walkers: wall loops (`CityDef.patrol_loops()`,
  walked by `Crowd._walk_loops()`, crowd.gd:852). The Capital's last yard men drill (`drill_face`).
- The job board `GuardJobs` hands fires and street piles to ordinary guards: `at_post()` (who is free),
  `pick()` (`SHARE` 0.5 of the guards near, `GROUP_KEEP` 1 stays per post group), `take()`, `prune()`, `close()`.
  FireManager and PileManager call it about once a second. A soldier a director re-posted (`post != town_post`) or
  holds (`Crowd.held_by_mission()`, crowd.gd:2234) is never taken.
- `_investigate()` (crowd.gd:2035): at a district's first Local Emergency the 2 nearest patrol men look for 20 s.
- Bodies: a corpse fades in 1.6 s (`DummyEnemy.DEATH_FADE`), 20 s for five kinds (`HELD_KINDS`). Only with a Death
  power in the loadout (`Remains.wants()`, rules.gd:247) does the ledger `Remains` keep whole bodies 45 s
  (`BODY_KINDS`: mark, plague, mob, frenzy, choke and so on; a blast or a fire leaves none).
- Gate queues exist only for fleeing citizens (`Crowd._gates()`, crowd.gd:1286). A calm town has no queue.
- Soldier art (design `guard`, manifest `own` mask): idle, walk, run, stumble (PixelLab "crouching", held on its last
  frame), death, swing, getup, talk, dig, douse. **No kneel, carry, point, lookup or work clip.**

## Decided with the user [user]

1. City Emergency no longer sends every free soldier to the Citadel. A small Citadel guard (15-20) marches in and
   stands still in ranks facing out. The Citadel's protection stays as today. The rest keep working the city.
2. Calm: street pairs walk real patrol routes; wall walkers; yard drills as today.
3. Gate check: gate guards look over each person in the gate queue. A gate guard counts as a watcher; a possessed or
   guised person passing a checked gate can be spotted, only when the town is alarmed (Local Emergency or higher).
4. Cordon: after a fire or a collapse 2 soldiers block that street; citizens turn back. Fewer witnesses near the
   ruin, but a lure through a cordon fails.
5. Sweep: after a power is seen a 4-man squad walks that district door to door for about 30 s. More watchers there
   for a while; a second power seen during a sweep adds extra alarm.
6. Corpse duty: a patrol that comes on a body: one kneels about 4 s and looks it over, the other keeps watch. Finding
   it adds alarm in that district. Then they carry it off the street; a carried body is lost to Death powers. It must
   change play, not only looks.
7. Shelter escort (City Emergency): squads lead regrouped households to shelters. An escorted group is harder to
   panic; if the squad dies the group scatters.
8. Soldiers do not repair. Citizen engineers do (EngineerManager); soldiers guard them (EscortManager) and clear
   rubble, both as today. Nothing is built for this.
9. Every behaviour is a new job kind on the existing board `src/game/crowd/guard_jobs.gd`. The rally becomes one job.
10. Build order: (a) Citadel guard + calm patrol routes, (b) corpse duty, (c) cordon, (d) sweep, (e) gate check,
    (f) shelter escort. Each slice has its own tests; references are re-recorded per slice.

## Goals, non-goals, anti-goals

Goals: soldiers look like soldiers in calm and in emergency; each duty changes play in a way the player can see
before it costs him; every mission keeps working; both towns.

Non-goals: soldiers repairing; mission-placed soldiers taking town duties; a bucket chain; new PixelLab art (answer 1 at the
end); changing how a seen power raises alarm (another branch owns that); wall walkers for Aldermere
`[call: "as today" read as no new wall loop; its wall men are needed at gates and towers]`.

Anti-goals (a failure even if it works):
- Soldiers as a wall: a patrol, cordon, sweep or checked gate that leaves the player no move. Every duty below lists
  its counter, and every kind has a cap.
- A hidden loss: a body found, a guise seen through or extra alarm the player could not see coming.
- A mission that now depends on street traffic or on where a patrol happens to be.
- Loud play made invalid. Sweeps and corpses add small, capped alarm only.
- A duty that empties a post group (`GROUP_KEEP` stays) or a soldier who still "watches" from a post he left.

## Constraints

- Godot 4.7.2, GDScript, deterministic at fixed fps. No number may be drawn from a shared rng for a duty.
- Frame rate: CPU bound at 100 soldiers plus crowd. The board ticks once a second (`EVERY` 1.0, as PileManager). One
  path search per man per order, never per frame.
- Both towns: every number below is for Aldermere; caps scale as `ceil(cap * soldiers / 100)` `[call: the Capital has
  about 180 soldiers]`. The Citadel guard does **not** scale: 20 slots and a floor of 15 in any town `[call: the
  garrison cap is 15 men in any town]`.
- Alarm: this design only **calls** `Crowd._hear_alarm()` (crowd.gd:1690; half before the bell, nothing when hushed)
  and `AlarmManager.incident()` (alarm_manager.gd:60), **reads** `AlarmManager.district_of()`, `alarms.stage`,
  `is_hushed()`, `is_veiled()`, and **listens** to `Crowd.danger_landed` (crowd.gd:18, emitted in `_land()`,
  crowd.gd:1536), the seen branch of `_settle_doom()` (crowd.gd:2517) and the three `_investigate()` call sites
  (crowd.gd:2420, 2475, 2523). It does not touch `on_cast()`, `add_alarm()`, thresholds or `UNWARNED_ALARM`. The
  "alarm and alert on ability use" branch can be merged by checking these names only.

## Approaches

1. **Job kinds on the one board (picked) [user].** Any free man can be handed any duty, the keep-one rule and the
   mission holds are written once, and the Citadel guard is just the job with the highest priority.
2. One Corps role and one manager per behaviour, like marshals, escorts and rescuers. Files stay isolated, but a cordon
   man never carries a body, there would be six managers, and the Citadel reserve logic tangles across them. Rejected.
3. A per-soldier priority brain that scores every duty. Most lifelike, but it rewrites person.gd and is the hardest to
   keep missions and bots exact. Rejected.

## The job board

- **Kinds**, highest priority first `[call: defence, then lives, then the god's trail, then tidying]`:
  `CITADEL`, `FIRE`, `PILE`, `SHELTER`, `SWEEP`, `CORPSE`, `CORDON`, `GATE`. FIRE and PILE keep today's code and callers.
- **One tick** (`GuardJobs.step()`, every 1.0 s, called where `prune()` is today, crowd.gd:1167): prune, post new
  jobs, then fill open jobs in priority order, oldest first, nearest free man first (ties by `stagger`, as
  `free_near()`). `[call: one loop, so priority is one sorted list]`
- **Who is free:** `at_post()` as today, plus a patrol man walking a leg of his beat `[call: else walkers are free
  only 2 s in 7]`. Never a mission man (defined under "Missions").
- **Keep-one:** `GROUP_KEEP` 1 per post group counts over all kinds. `SHARE` 0.5 stays for FIRE and PILE. The new kinds
  have a fixed crew: they start only with a full crew and then run short-handed `[call: no half cordon]`.
- **Pulling:** only CITADEL may pull a man off another job, and only while the guard is under 15. It never pulls a
  shelter escort or a man carrying a body `[call: protection first, but never drop people or a body mid-street]`.
- **Common interrupts:** the man dies; he fights (`Mind.FIGHT`); a director sends him elsewhere (the director wins,
  as today); the Citadel falls (below). A man the god holds (`held_by_god()`, person.gd:1868) keeps his record but
  does not count as standing his duty while held, as today.
- **The board no longer closes at the rally.** It closes when the Citadel falls. At Evacuation FIRE, PILE and SHELTER
  stop as today (fire_manager.gd:321, pile_manager.gd:579). Idle rescue squads help with piles from the call-up on;
  rescue_manager.gd:159 reads `Crowd._rallied` instead of the closed board `[call: keeps their help]`.
- Each kind's steps may live in its own small file; the board alone decides who goes where `[call: keeps
  guard_jobs.gd readable without becoming approach 2]`.
- **What the player sees:** `GuardJobs.tags()` returns `MapTag`s, added in `Hud.all_tags()` (hud.gd:745) after the
  mission's own. Banners go through a new signal `Crowd.duty_event(kind, text, at)` that `Mission` turns into
  `banner.emit`, as it does for `rallied` (mission.gd:670).

## Slice (a1): the Citadel guard

- **Trigger:** `Crowd.rally()`, its three triggers, the `rallied` signal and `_rallied` all stay. Call it the
  **call-up**. The banner becomes "THE CITADEL GUARD FORMS" `[call: nobody rallies now]`.
- **Slots:** `GUARD_SLOTS` 20, `GUARD_MIN` 15 `[call: 15 is exactly the garrison cap, 0.30 / 0.02; five spare so the
  first deaths cost nothing]`. Four ranks of five, one per side of the Citadel, each a straight line 0.6 apart, centred
  on its side, `RING_RADIUS` 3.4 from the centre, snapped to open ground. Slots are dealt round the sides in turn
  (south, the gateway, first), centre out, so 15 men still cover all four sides. Each man faces straight out from his
  side; the four ground axes map onto the four sprite facings (as the drill branch does, person.gd:1000).
- **Who:** every mission man first (see "Missions"; if there are more than 20 the extra stand in a rear rank). Then
  town men up to 20: the Citadel post group first, then the nearest free. Men of the Citadel group not chosen (the
  Capital has 30 there; Aldermere one per mission man) are **stood down to the yard**: at the call-up their `post` and
  `town_post` move to the nearest free yard spots and they walk there as ordinary free guards `[call: a spare man
  standing among the ranks would refill a dead guard at once and remove the counter below]`.
- **What they do:** march to the slot as `Mind.RALLY` at `WALK_SPEED * ASSIST_PACE` (0.9) with the `walk` clip
  `[call: the run is half of the panic look]`. At the slot: stand on it, face out, `idle` clip, no `_drift()`, no talk.
  Change `_base_speed()` (person.gd:882), the pose (person.gd:3178) and add a stand-still branch in `_pick_target()`.
- **Garrison:** `on_ring(p)` keeps its name and means "a living corps-NONE man on the CITADEL job, `Mind.RALLY`, within
  `RING_REACH` 1.0 of his own slot". `ring_count()` and `GARRISON_STEP`/`GARRISON_CAP` are unchanged.
- **Refill of the guard:** while under 20 the board sends the nearest free town man; under 15 it pulls. The cut dips
  while he marches. Long-run protection equals today's (the player still has to kill through the town's soldiers).
- **`_refill()`** (dead marshal, escort, rescuer): the nearest free board man takes the role; with none free, the
  nearest guard man does and his slot is refilled `[call: keeps the 15]`. One replacement per death, as today.
- **Citadel fallen:** `_on_citadel_fallen()` (crowd.gd:2576) stays: order collapses, every corps-NONE soldier holds
  his ground where he is. The board closes here.
- **`forgo_rally()`** (the leaderless town) stays: no guard ever forms; the board stays open.
- **Counter:** kill the guard faster than men can march in; lure free men away first so nobody refills.
- **Ends / interrupts:** never ends for a mission man. A town man leaves only by `_refill()` or death.

## Slice (a2): calm patrol routes

- Every street pair walks a **beat**: the centre line of the street it is posted on, a point about every 3.0
  (`LOOP_STEP`), there and back, starting at its post. Beats are **generated** from `CityDef.roads()` in both towns by
  the same formula that places the pairs today (crowd.gd:915, capital_city.gd:1401), through a new
  `CityDef.street_beats()` `[call: generated, not authored; Aldermere's streets are plain rects and a table would rot]`.
- They are walked by the existing loop code (`_start_loops()`, `_walk_loops()`): pause `LOOP_PAUSE` 2 s at each point,
  `talk` clip in the pause as any posted guard. Escort-corps patrol men do not walk (as today). The `_rallied` test in
  `_walk_loops()` goes: beats continue after the call-up `[user 1]`.
- **A man on a beat is not a posted watch:** `Person.on_watch()` (person.gd:2866) is false for him `[call: no waiting,
  no luck; Heretic Hunt, Informer and Heart of Faith judge doors by `on_watch()`, and a door must not flip watched and
  unwatched with traffic]`. He is still a witness within `DOOM_WITNESS` 2.0 (`nearest_witness()`, crowd.gd:2489).
- Yard drills and the Capital's wall loops are unchanged.
- **Counter:** a beat is fixed and visible; act behind the pair, lure it, or start a fire (a man at a pause is free).

## Slice (b): corpse duty

- **Bodies:** the ledger `Remains` is turned on for every loadout `[user, answer 2: otherwise only Death
  and Decree gods ever leave a body to find]`. It stays simulation-neutral by itself.
- **Trigger:** a free street pair, both men, on its beat within `CORPSE_NOTICE` 4.0 of an unhidden remain nobody is
  assigned to (`Remains.near()`, remains.gd:148). 4.0 sits beside `COLLAPSE_SIGHT` and Death Mark's `LOOK_R`. The
  reach is capped by `Crowd.sight()` (crowd.gd:1060), and a body on veiled ground is never noticed `[call: the Unseen
  Hour, NO SIGHT and the dark are counters here as they are for the sweep and the gate check]`.
- **Crew:** that pair. One pair per body, one body per pair.
- **Steps:** both walk to the body. The nearer man crouches over it for `INSPECT` 4.0 s (`stumble` clip held: the
  crouch `[user, answer 1: stand-in]`); the other stands 0.8 away facing out. When the 4 s end the body is
  **found**. Then both lift it: `Remains.take()` (remains.gd:171), the body is drawn between the two as they walk
  (`walk` clip) to the nearest open ground off every road within `CARRY_REACH` 4.0, lay it down, and it fades over
  `DEATH_FADE`. They walk back to the beat.
- **Play:** on found: a death the town already counted (a seen, loud one, or a doom judged seen: `Remain.counted`) writes no incident,
  no alarm and no sweep request, though the banner shows and the body is lifted; a death never counted (a quiet, hushed or veiled
  kill, or a doom judged unseen) writes one `alarms.incident(body)` (a sweep if it tips the district) and `_hear_alarm(ALARM_KILL)`
  (0.5) `[ruling R18]` `[call: a seen death is not taxed twice, in count or alarm; loud play stays valid]`. From the lift on no Death
  power can use the body.
- **What the player sees:** from assignment the body carries a tag "FOUND IN n" counting down the walk plus the 4 s.
  At zero the banner "A BODY IS FOUND". The lift shows the tag "TAKEN" for 2 s and the body visibly leaves.
- **Counter:** use or move the body before the count ends (it stays on the ledger until the lift); kill, hold or lure
  either man before the 4 s end (the job drops, nothing is found, the tag goes); kill or hold a carrier and the body is
  dropped back onto the ledger with a fresh clock (`Remains.move()`, remains.gd:182); kill off the beats; a body
  lapses by itself after 45 s.
- **Ends / interrupts:** the body is used, lapses or is laid down; either man dies, fights or is taken by CITADEL.

## Slice (c): cordon

- **Trigger:** a building's fire goes out with the building standing, or a building falls (`leaves_ruin()`). Not
  veiled, stage below Evacuation. A new site inside a live cordon only restarts that cordon's clock.
- **Crew:** 2, the nearest free men within 10.0 (`PileManager.REACH`). At most `CORDONS` 2 at once.
- **Shape:** the stretch of the street in front of the site (the pile's street for a fall), `CORDON_HALF` 3.0 each
  way along the road's centre line, joined with the footprint grown by 0.5. One man stands at each end, facing out.
- **Steps:** walk to the ends (`walk`), stand (`idle`), `talk` when turning someone back. Once a second every citizen
  going about his day (`Mind.CALM` or `RECOVER`, not held by a mission) whose goal lies in the rect or whose path
  crosses it (`Person.path_crosses()`, person.gd:908) is turned back with `Person.hold_off()` (person.gd:1562; the
  call FoldWard uses, fold_ward.gd:166). `hold_off()` today only keeps goals inside the rect; the builder adds the path
  case. **Nobody fleeing, panicking, on duty, assisting, or a soldier is ever turned back**, so no route is sealed.
- **Danger:** a cordon is not formed, and a man whose end lies inside a live danger stands off outside it (and goes back to his end when it is over), while a lingering power (`ThreatManager`: an airless cell, a fire, a storm; not the ruin's own collapse) is live there; an open job waits out its window and forms if the danger ends in it; a sweep's door in a live danger is held off the same way `[ruling R19]`.
- **Play:** fewer witnesses and no gawkers at the ruin; the two men face out and see only `DOOM_WITNESS` 2.0, so the
  inside of a cordon is unwatched `[call: else "fewer witnesses" would not hold]`. `Person.lure()` (person.gd:1458)
  returns false for a citizen when the line from him to the lure crosses a live cordon. Will-o'-Wisp's preview ring
  (`WillOWisp.drawn()`, targeting.gd:1310) applies the same test so the player sees who will not come.
- **What the player sees:** a rope between two posts at each end (drawn by code in ResponseDrawer, no new art) and a
  tag "CORDON n" counting down.
- **Ends:** after `CORDON_SECONDS` 40 `[call: beside the pile's 20 s and a body's 45 s]`, at Evacuation, or when no
  crew man stands at an end. **Counter:** kill or lure the two men; work inside it unseen; the two posts they left
  are empty.

## Slice (d): sweep

- **Trigger:** a power is **seen** in a district: `danger_landed` with a living witness (citizen or soldier, awake,
  not held by the god) within `DOOM_WITNESS` 2.0 of the landing or inside the danger's own radius, or the seen
  branch of `_settle_doom()` `[call: [user 5] says "seen"; `danger_landed` alone fires on every loud landing, even in
  an empty district]`. The same witness test gates the extra alarm below (a sweep man's 4.0 counts). Also every
  place `_investigate()` is called today: **the sweep replaces `_investigate()`** `[call: same idea, one system]`.
  Never when hushed or veiled. Not while that district is already swept. At most `SWEEPS` 2 at once.
- **Crew:** 4, the nearest free men of any group.
- **Steps:** run to the district (`hurried`). The clock starts when the first man is inside its rect. They visit up to
  `SWEEP_DOORS` 6 house doors nearest the seen point, nearest next, standing `SWEEP_STAND` 3.0 s at each (`talk`),
  for `SWEEP_SECONDS` 30 `[user]`, then walk back to their posts.
- **Play:** a sweeping man witnesses to `WATCH_SIGHT` 4.0 (a **new** constant, beside `COLLAPSE_SIGHT`) instead of 2.0 (`nearest_witness()`; TempleReport keeps a
  copy of that search, temple_report.gd:164: change both). Each further power seen in that district while a squad
  man is inside it adds `_hear_alarm(SWEEP_ALARM)` 2.0 (= `ALARM_BUILDING`), at most 6.0 per sweep `[call: capped so
  loud play is taxed, not ended]`. Sweep men do not count for `on_watch()` (they are on a job).
- **What the player sees:** banner "SOLDIERS SWEEP THE DISTRICT", a tag "SWEEP n" over the lead man, an eye badge
  over each (`set_badge()`), and a banner "THE SWEEP HEARS IT" on each extra alarm.
- **Ends / counter:** the 30 s end, Evacuation, or no squad man left in the district (dead, held, lured): banner
  "THE SWEEP IS BROKEN". Act in another district, break the squad, or wait it out by choice. Four posts stand empty.

## Slice (e): gate check

- **Who:** wall-group men whose town post lies within 2.5 of a standing, open gate, corps NONE **or MARSHAL**. Up to
  2 per gate `[call: `_assign_corps()` makes the in-gate guards marshals (crowd.gd:806; every Capital gate, most
  Aldermere gates at high tiers), so without them no gate would be checked; a marshal checks while he stands at his
  gate and while he works its queue; nobody is re-posted]`. It is their standing duty at their own post, lowest
  priority: a fire or a sweep may take a corps-NONE checker `[call: the lure stays]`; a marshal leaves only as he does
  today.
- **Only when the town is alarmed:** a guard sees through a guise or the god's hold only while `alarms.stage` is Local
  Emergency or higher; below it nobody is spotted (no unmask, incident, alarm, "!" badge or banner), and the "GATE CHECK"
  tag stays down. `[ruling R20]` Below Local Emergency the whole duty sleeps: no GATE job or record, nobody steps out to a spot,
  no far sight, no eye badge and no tag, so a wall guard near a gate is the plain soldier he was; when the stage falls back below
  it the jobs end, the flags come off and a man out on his spot walks back to his post. The first time the stage is at or above Local Emergency with a gate checked, one banner "THE GATES ARE WATCHED"
  warns the player (once a night; not while the town is hushed) `[user, 2026-11-22: all Dominion pairs lost with
  spotting in a calm town; from Local Emergency they return to baseline]`.
- **A gate is checked** while at least one of them stands his spot beside the mouth, free and not held by the god.
- **Steps:** when a queue forms or anyone walks within `GATE_LOOK` 2.5 of the mouth, the checkers step to spots
  behind the marshals' (`MarshalManager._spot()`) and face the nearest person (`talk`). A calm town has no queue, so
  the check covers **everyone who walks through the gate, queued or not** `[call: else [user 3] only exists in flight]`.
  The check never slows the gate `[call: gate pace drives escape counts and loss limits]`.
- **Play:** a person crossing the door line of a checked gate, within the checker's sight (`Crowd.sight()`,
  crowd.gd:1060, so NO SIGHT caps it; nothing when veiled), who is `guised()` (person.gd:1843) or `held_by_god()` is
  **spotted**: the god's hand comes off him (the guise or the hold ends), `alarms.incident(gate)` and
  `_hear_alarm(GATE_SPOT_ALARM)` 2.0. A checker also witnesses to `WATCH_SIGHT` 4.0 `[call: the "watcher" of user 3]`.
- **What the player sees:** a tag "GATE CHECK" on every checked gate, an eye badge on each checker, and on a spot a
  "!" badge on the checker plus the banner "THE GATE GUARD SEES THROUGH IT".
- **Counter:** an unchecked gate (lure, hold or kill the checkers; a fire nearby); another gate; NO SIGHT, a veil.
- Checked once a second over the people near each gate; the queue's own release (crowd.gd:1368) is the other hook.

## Slice (f): shelter escort

- **Trigger:** from City Emergency until Evacuation: a household in `Mind.REGROUP` waiting at home (`HOME_REACH` 1.2)
  with a usable shelter with room within 12.0. At most `ESCORT_SQUADS` 3 at once, nearest household first.
- **Crew:** 2, the nearest free men.
- **Steps:** the squad runs to the home. The members then walk to the shelter's door still in `Mind.REGROUP`
  (`regroup(door)`, walking pace) `[call: a slow, visible group; `Mind.SHELTER` would make them fright-proof]`. The
  squad keeps within `EscortManager.REACH` 1.5 of the group, re-anchored at most once a second. At the door each
  member goes in (`ShelterManager.send_in()`, shelter_manager.gd:123). The squad walks back.
- **Play:** a member within `STEADY_R` 2.0 of a living, unheld squad man refuses `panic()` (person.gd:1329) unless he
  stands inside the danger's own radius: a near miss no longer breaks the group, a direct hit does. When the last
  squad man dies every member still outside panics from that spot (they scatter) and the banner "A HOUSEHOLD
  SCATTERS" shows. A full shelter is a bigger target, as today.
- **What the player sees:** a shield badge over each escorted member, a tag "ESCORT" over the squad.
- **Ends:** all members inside or dead; Evacuation (the members flee as today, the squad is freed).
  **Counter:** kill the squad; hold it (the group is unsteadied); hit the group itself; hit the shelter.

## Missions: what "rallied" means now

**Rallied = in the Citadel guard** (`Mind.RALLY`, on the CITADEL job). Only guard men ever have `Mind.RALLY`.

**A mission man** is a corps-NONE soldier a director has taken: `post != town_post`, or `Crowd.held_by_mission(p)`,
or on a director's duty (`Mind.DUTY`), or anchored away from his post with no board job (a director's
`send_to_post()`). At the call-up **every mission man goes to the Citadel guard and never comes back**, exactly as
today `[call: every mission was tuned on "going loud takes my watch away"; this keeps each director's mind tests
unchanged]`. The acceptance check: the mission tests that assert `Mind.RALLY` after `crowd.rally()` pass unedited,
with two known exceptions that assert the old all-rally and are rewritten in slice a1: tests/test_crowd.gd:116-123
(every corps-NONE soldier rallies on the first Citadel hit) and tests/test_lost_lamb.gd:402-426 (its man put back on
his post must be one who answered the call-up).

- `hide_faithful_director.gd` `watch_broken()` (:503) and its tags (:1413, :1418): unchanged code and meaning.
- `escort_director.gd` `_watching()` (:546) and `POST_MINDS`: unchanged. Its watch still leaves at the call-up.
- `procession_director.gd` (:178): takes its escorts from the Citadel post range at the start; unchanged.
- `festival_director.gd` `_post_guards()` (:144): its square guards are mission men and still leave at the call-up.
- `MissionDirector._free_soldiers()` (:314): before the call-up it works as today, and releases any board job the man
  holds (the director wins). **After the call-up it hands out no town man**: only a man who answered the call-up (a
  guard man, marked at the call-up) and stands at his post again can be taken `[call: today a late appointment
  (`EscortDirector._appoint_hunters()`, escort_director.gd:312, Lost Lamb at 150 s; watch changes, quarry guards,
  Halcyon escorts) finds nobody because everyone is on the ring; this keeps "going loud takes my watch away" for
  late appointments too, so no mission is retuned]`.
- `heretic_hunt_director.gd` (:119), `informer_director.gd` (:184), `heart_of_faith_director.gd` (:376): they read
  `on_watch()`. Beat men and men on a job do not count. **Change:** posted guards now stay in the streets after City
  Emergency, so going loud no longer un-watches a door `[call: accepted, it follows from user 1; a fire or a collapse
  still pulls them. Report every win/loss flip to the user]`.
- `judgement_director.gd` (:32): `rally()` forms the guard at the act's start; `forgo_rally()` as today.
- `armoury_director.gd` (its own `reserve`), `bishop_director.gd` and Lantern Knights (corps KNIGHT),
  `lantern_bearer.gd` (its escorts are mission men): no change.
- No mission may place its win on a town patrol, cordon or sweep. A director that needs a soldier holds him.

## References, tests and gates per slice

Before slice (a): record the baseline on a5825501: `tools/dev/refs/*.tsv` as they are, and every row of
`bash tools/dev/god_gate.sh` and `bash tools/dev/hunt_gate.sh` (partly red already). The bar after each slice: suite
green, references re-recorded with the reason, **no gate pair worse than its baseline row**, FLOW alone, frame rate
within noise on a quiet machine. A reference that moves outside the "may move" column is a bug.

| Slice | References that may move | Must not move | Tests |
|---|---|---|---|
| a1 guard | rows that reach the call-up | rows that never reach it | test_crowd (:116), test_corps, test_citadel, test_guard_jobs (close moves), test_alarm, test_soldier_minds, test_person, test_lost_lamb, test_judgement, test_escorts/marshals/rescue (refill), test_piles |
| a2 beats | every row (crowd_check hashes each soldier) | none; judge by the gates | test_watch_posts (beat men off watch), test_capital_evac, new test_beats |
| b corpse | rows with a whole body near a beat | `none` cases; rows with no body kind | test_remains, new test_corpse_duty |
| c cordon | rows with a fire put out or a fall | `none` cases; quiet rows | test_piles, new test_cordon |
| d sweep | rows with a seen power or a Local Emergency | `none` cases with no incident | test_alarm (investigators become a sweep), test_lantern_knight, new test_sweep |
| e gate | rows where someone held or guised passes a manned gate, or a queue forms | calm rows with nobody at a gate | test_marshals, new test_gate_check |
| f escort | rows that reach City Emergency | rows that never reach it | test_shelter, new test_shelter_escort |

Each new test covers: the trigger, the crew and the keep-one rule, a mission man is never taken, each end and each
interrupt, the play numbers, and both towns. `tools/dev/behaviour_check.gd` policies already treat soldiers as
witnesses; fix a policy, never the rule, if a bot now stalls.

## Risks

- Slice a2 moves every reference at once. Land a1 and a2 as separate re-records so a1 can be checked row by row.
- Bots that wait for a street to be clear may idle longer with walking pairs (the gates judge idle time).
- `Remains` always on: Pale Reign and Death Mark's Wake turn the ledger on and off themselves (pale_reign.gd:126,
  :469); they must not switch it off under corpse duty. More bodies are drawn (at most `Remains.MAX` 60).
- Gate check weakens Corpse Guise at manned gates; Death rows of the escort-type missions may flip.
- Loud rows of the three `on_watch()` missions may flip (see above).
- The Citadel's cut now dips while a replacement marches; it is a little easier to burst.
- `Person.panic()`, `lure()` and `hold_off()` each gain one test; all three are hot paths. Keep them O(1) with no cordon
  or escort live.
- The mission-man definition is inferred, not marked. If a director's soldier slips through, add an explicit mark.

## Left to the builder

- The board's record shape and where each kind's steps live; exact slot and spot geometry on blocked ground.
- How `hold_off()` learns the path case; how the cordon rope and the carried body are drawn.
- Where "off the street" is when a town names a better place (a temple yard), and the door order of a sweep.
- Tag colours and badge glyphs; banner wording; sounds (reuse `sol_order`, `sol_rally`).
- Scaling of each cap in the Capital if `ceil(cap * soldiers / 100)` reads wrong on screen.
- Scripted-player policy fixes when a gate pair drops below its baseline.

## Answered by the user (2026-11-20)

1. **Art [user]:** ship with the stand-ins. The crouch (`stumble` clip held) for looking a body over; two walking
   soldiers with the body drawn between them for the carry; `talk` for gate checks and door knocks. No PixelLab work
   in this build; new clips only later, if the stand-ins look poor in play.
2. **Bodies for every god [user]:** whole bodies stay 45 s in every mission for every kill that leaves one today
   (`Remains.BODY_KINDS`: quiet kills, plague, mob, frenzy, choke and the like). Streets will show more dead; that is
   wanted. A blast or a fire still leaves no body, so corpse duty never touches a Ruin god's loud kills.
