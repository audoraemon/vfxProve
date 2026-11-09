# Soldier jobs: fire buckets and street rubble (design)

Date: 2026-11-10. Branch: `feat/soldier-jobs` (from feat/people-anim-2 52006c24, which carries the talk/work/dig/douse
clips and is landing on feat/Develop-Main). Build with the kak-milestone skill.

## Why

Soldiers only escort and stand today. The user wants them to do real town work when it is needed: fight fires and clear
rubble. For the player (the god) this turns fires and falling buildings into **lures**: a blaze or a collapse pulls
guards off their posts, and the empty post is a chance to act.

## The decisions (the user's)

1. During a fire, **some** ordinary guards leave their posts and join the bucket work; **a few stay behind**.
2. An empty post is a chance the god can use.
3. **Ordinary guards only** for now: soldiers a mission placed (escort charges, festival guards, procession escorts,
   knights, wish soldiers, director-reserved soldiers) keep their jobs.
4. A fallen building's **ruin stays blocked ground** (stone and timber) until it is rebuilt. Today a fall opens its
   cells; that changes.
5. A fall also drops a **pile into the street** in front of it that **blocks the street until soldiers clear it**.
6. Soldiers clear **only the street pile**; the ruin stays until engineers or a mission restore the building.
7. Approved gap fixes (2026-11-10):
   - Missions that judge "watched" from a soldier's spawn `post` (Heretic Hunt, Informer, Heart of Faith) use where the
     soldier is now, so a lured guard really leaves his post empty.
   - A gap rule: no ruin or pile may cut the last walking route to an exit, a gate or a mission target.
   - Anyone standing (not trapped) in a footprint when it falls is moved to the nearest open cell.
   - The exact references move; re-record them with the reason, list every win/loss flip for the user.
8. **Jobs stop at the rally** (2026-11-10): guards take jobs only until City Emergency's rally (`Crowd.rally()`, also
   fired by the first hit on the Citadel). Then they go to the Citadel ring as today and the defence is unchanged.
   Piles left then, or dropped later, are cleared by **idle rescue squads** instead. On the Unprepared tier
   (`fire_from` = City Emergency) guards join fires from City Emergency until the rally takes them, which in practice
   is the same moment, so Unprepared guards rarely help: accepted.
9. **Only buildings** leave a blocked ruin and a street pile (houses, shops, temples, barracks and other building
   kinds). Walls, gates, towers, Citadel pieces, market stalls, crates, trees, thorn walls and bridges keep today's
   rule on falling (a broken gate stays a free exit).

## Calls made by the designer (not the user's; change them freely)

- A pile may slow a mission's route (a detour or the slow crossing): that is the god's tool. The gap rule still stops
  it sealing a route, so it is never a hidden loss.
- No marker for an empty post; seeing the guards walk off is enough for now.
- About half the nearby guards go; two diggers per pile; about 20 s per pile; slow crossing about 0.3 of walking speed.

## Goals

- Guards visibly join fire work (fill at the fountain with the `work` clip, throw with `douse`) and walk back after.
- A collapse cuts streets for a while; guards come and dig (`dig` clip) until the street opens.
- Both are readable lures: the player can see a post empty and use it.

## Non-goals

- Mission-placed soldiers joining any job (later, separately).
- Clearing ruins (only rebuilding removes a ruin).
- A real passing-buckets chain; responders keep the current fetch-and-throw loop.
- New art (no PixelLab): piles reuse the existing rubble look.

## Anti-goals (a failure even if it works)

- A pile or ruin quietly makes a mission impossible, or loses it without warning (memory: no hidden losses).
- One fire or one collapse empties a whole wall, yard or Citadel group: a few always stay.
- A lured guard who still "sees" from his empty post.
- Success depending on luck (who happens to be nearby is deterministic from the layout and seed, which is fine).

## How it behaves

### A. Guards at a fire

- **Who:** soldiers with corps NONE, alive, at their post (mind POST, or the HOLD-at-post state; not RALLY, DUTY,
  FIGHT, not held by a god power, not reserved by a MissionDirector, not on a wall-patrol loop leg if that would break
  the loop), within the brigade's `RECRUIT_REACH` (10) of the fire.
- **When:** under the same rules as the citizen brigade (alarm stage ≥ `profile.fire_from`, a fightable fire below
  `ABANDON`, a water point, not veiled) **and** before the rally (decision 8). At the rally, guards on fire duty drop
  it and go to the ring.
- **How many:** about half the eligible guards near that fire, nearest first, **on top of** the citizen crew
  (`fire_crew` is unchanged). At least one guard stays at each post group (yard, walls, Citadel, patrol, and a city's
  own groups) counting all fires at once.
- **What:** the same responder loop as citizens (Mind.ASSIST; water → fill `ACT` → fire edge → douse). The new clips
  already play for anyone in that loop.
- **End:** fire out, building fallen, fire past `ABANDON`, or evacuation (soldiers have no `assist_stays`): the guard
  walks back to his own post (`stand_down()` already sends a soldier to `post`).
- **Tests to change:** `test_corps.gd:119` ("a soldier is not sent to a fire unasked") becomes the opposite for
  ordinary guards and stays true for every other corps and for mission-held soldiers.

### B. Ruins stay blocked

- Buildings only (decision 9); every other kind keeps opening its ground through `_on_destroyed` / `_reopen`.
- On collapse the building's walk-grid cells stay closed (today `walk_grid.gd` `_on_destroyed` opens them, and
  `EnvironmentField.blocked()` treats rubble as walkable). A restore (`Structure.restore()`) opens nothing new: the
  standing building blocks as before.
- Fallen bridges keep their current rule (river closed).
- People in the footprint when it falls: trapped ones stay for RescueManager (dug out from the edge as now, then
  placed on the nearest open cell); everyone else is moved to the nearest open cell at once.

### C. Street piles

- **Shape:** 1-3 cells of the street directly in front of the fallen building (its door side if it has one, else the
  side facing the widest street), drawn with the existing rubble look.
- **Blocks:** walking only. People path around; a pile that fills the street's width cuts it.
- **Cleared by:** ordinary guards under the same eligibility and "a few stay" rule as fires. Two diggers per pile; a
  pile takes about 20 s with two (builder may scale per cell). Diggers stand at the pile's edge and play `dig`
  (`Person.dig_shown`). When clear, the cells open and the guards walk back to their posts.
- **Priority:** fires before piles when the same guard could do both; rescue squads still dig trapped people first
  and help with piles only when idle.
- **When:** guards clear from `profile.fire_from` until the rally (decision 8). From the rally on, idle rescue squads
  clear remaining and new piles (after trapped people and their fire duty), including during EVACUATION if they are
  still in town. Alarm stages never go down, so nothing waits for a "resume".

### D. The gap rule (no sealed routes)

When a ruin or a pile would close cells, check whether it cuts the last walking route between the town's exits, gates,
the Citadel and any active mission's targets/places. If it would, leave one cell open as a **slow crossing** (people
cross at a fraction of walking speed; builder picks the factor, about 0.3). A pile's gap cell clears with the pile; a
ruin's gap cell stays as long as the ruin.

### E. Missions see the empty post

Heretic Hunt (`heretic_hunt_director.gd:116`), Informer (`informer_director.gd:180`) and Heart of Faith (`_quiet`,
`heart_of_faith_director.gd:373`) judge watching from where each soldier is now and whether he is at his post (POST
or HOLD near `anchor`), like EscortDirector's `_watching`. A guard away at a fire or a pile does not watch there.

## Constraints

- Godot 4.7.2, GDScript; deterministic at fixed fps (references must be reproducible).
- Memory rules: kak-mission-design-lessons (no hidden losses, no luck), check-before-every-merge, milestone run
  preferences (subagent-driven, full landing checks, no PixelLab).
- Performance: the gap check runs once per collapse, not per frame (KAK is CPU/draw-call bound).
- Both towns: Aldermere (100 soldiers, groups 30/30/20/20) and the Capital (~180, its own posting).

## Left to the builder

- Exact eligibility code and where the "a few stay" count lives (FireManager, a small shared job board, or Crowd).
- Pile cell choice and how piles are stored and drawn.
- The connectivity check's method and the slow-crossing factor.
- Dig time per cell; how many guards per large pile.
- Scripted-player route fixes if a reference mission now fails because of a block (fix the policy, not the rule).

## Checks

- Focused tests: guards join a fire and some stay per group; mission-held and corps soldiers do not; guards return to
  post; ruin cells stay blocked after a fall and open on restore; a pile blocks and is cleared by two diggers; the gap
  rule leaves a crossing when a pile would seal an exit; the three missions treat a lured guard as gone; people in a
  footprint end on open cells.
- Landing: `bash tools/dev/land.sh` (suite, all references re-recorded with reasons, FLOW alone). Report every
  reference win/loss flip.
