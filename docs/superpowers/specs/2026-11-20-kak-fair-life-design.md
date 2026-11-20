# Fair life: a natural crowd at Market Panic (Scatter the Fair)

Date: 2026-11-20. Source: Discord #ideas "Mission Adjust" (2026-11-20). Size: a small change.

## Why

The user: the fair's crowd "looks unnatural. They stand still like nothing happened; even when Ember burns them they
still stand. I want them to be more natural like others in the city."

Today (MarketPanicDirector): each goer walks on duty to one fixed spot within FAIR_R of the fountain and stands there.
Every goer within WARD_R of a warden on guard is held fearless (_steady()). Fearless blocks Person.panic() and
Person.observe(), and Burning._free_to_run(), so a steadied goer set alight stands burning BURN_FOR seconds and dies on his
spot, and nobody round him looks.

## Goals

1. A man on fire always runs and screams, steadied or not, in every mission (a god's absolute hold still wins).
2. Steadied goers react to what happens near them: they turn to it, step back, stare a moment, then go back to talking.
   They do not break: the warden rule is unchanged.
3. Goers at the fair stand in small groups, face each other and talk (the existing talk art, anim 13), and every so often a
   group strolls to another spot at the fair.

## Non-goals

- No rule change: the warden rule (steadied goers never break from a fright), FAIR_NEED, WAVE, WAVE_AT, CHAIN, WARD_R,
  FAIR_R, MARKET_CLOSE stay. A death counts as before.
- Soldiers ("Soldier Behavior Adjust" post) are a separate project.
- No new art: talk (13) and the existing facing/idle frames only.

## Anti-goals

- A warden must never be moved off his post by a reaction (that would drop his guard and change the rule).
- The mission must not get easier or harder: groups must not clump so tight that one Heaven Splitter takes more than today.
- The town's alarm and evacuation must still pass goers by (they stay on duty: v0.11 final review).

## Approaches

- **A (chosen): a fair-life layer in MarketPanicDirector**, with a burning fix in Burning. Goers stay on duty; the director
  forms groups, moves their spots, and asks steadied goers in sight of a danger to flinch. Keeps every rule; local.
- B: make goers calm leisure strollers held only by the wardens. Rejected: the town's regroup/evacuation would take them
  (the bug the v0.11 final review fixed).
- C: a general "crowd at an event" behaviour for all gathering missions. Rejected for now: larger, touches missions the
  user did not ask about (the Long Night festival crowd already strolls and talks as calm leisure goers).

## Design

1. **Burning beats fearless.** A burning person's own fear cannot be held: Burning.lay() and _keep_running() let him panic
   even when fearless_left > 0 (WILL_ABSOLUTE and resists_mind() still win). Directors that hold people on duty or fearless
   (Market Panic's _steady/_hold_fair/_hold_waiting; the other holders: harvest, escort, armoury, crowns_bread, face_halcyon,
   hide_faithful, lost_lamb, prisoner, rite, sermon) skip anyone burning(), so they do not pull him back. Witnesses he
   frightens (Burning._frighten) are unchanged: a fearless witness still does not panic, he flinches (2).
   At the fair a burning goer panics, so he counts as broken a few seconds before his fire death would have counted him.
2. **Flinch.** A new Person reaction for a fearless or on-duty person who would otherwise have been frightened or looked:
   freeze STARTLE, face the danger, take one short step straight away from it (about 0.5, only on open ground), stare a
   moment, then walk back to his spot and carry on. No mind change, so no rule reads it. Wardens and anyone at a post turn
   and stare only (no step). Triggered where panic()/observe() now return early for fearlessness.
3. **Groups and talk.** When a goer arrives at the fair the director puts him in a group of 2 to 4 of his crowd. A group's
   members stand on a small ring round a shared point (about 0.45 from it), face its centre, and show the talk art while
   they stand (Person._interact_anim(): an on-duty person with a chat point set, standing, talks).
4. **Strolls.** Every 20 to 40 s a group walks together to a new shared point within FAIR_R (a stall, the bonfire side, the
   fountain rim), on duty, and talks there. Group points keep at least today's average spacing between goers, so a cast
   takes about as many as today. Draws come from a director-own RandomNumberGenerator seeded from the night, never the
   crowd's or the town's streams.

## Checks

- New focused tests: burning-while-fearless runs; flinch keeps mind and fearless; a warden never leaves GUARD_REACH from a
  flinch; groups form, talk and stroll inside FAIR_R; no clump tighter than the spacing floor.
- Market Panic's gate (behaviour_check panic: none/play/b_play) wins and loses as before.
- References: the panic_* rows (9) move and are re-recorded; any other row that moves is checked for a burning-while-held
  cause and re-recorded with that reason, else it is a bug.

## Left to the builder

Exact numbers (step size, stare seconds, group ring, stroll timing within the ranges above), and where the flinch lives in
Person (one helper both panic() and observe() call).
