# KAK Fair Life: gate and references (2026-11-23)

Fair life = a burning person always runs (T1), fearless people flinch (T2), Market Panic's goers stand in talking groups and stroll (T3).
No rule number and no policy changed. FairLife tuned to GROUP_MAX 3 (was 4), APART 2.0 (was 1.6), RING 0.6 (was 0.45).
Timed runs shared the machine with 30-42 Godot processes of other sessions; headless fixed-fps runs are deterministic, only wall time suffers.

## Why the first gate was too easy
At 4 / 1.6 / 0.45, route A won at 187.3 s on all seeds and B at 169.6 / 168.3 / 279.8 s (before: A median 213, B 221). The A win is the one final
Heaven Splitter, cast only once no crowd is still to come; 187.3 s is its landing. Old tree, seed 1: the same splitter at 220.0 s. Grouped
goers broke faster, so the chain (45 s after the crowd before scatters) sent the last crowd out about 35 s earlier. Per cast, seed 1
(broken by the next 10 s sample): A, Smite on a knot at 75.1 s +11 (old Smite at 73.3 s +1), at 120.5 s +7; B, Ember at 27.1 s with 7 goers by
the house (old 4), 153.1 s 8 (old 6), 168.2 s 10.

## Gate table (win time s, seeds 1/2/3)
| GROUP_MAX / APART / RING | route A | route B | none |
|---|---|---|---|
| 4 / 1.6 / 0.45 (as built) | 187.3 x3 | 169.6, 168.3, 279.8 (169.6) | lost 3/3 |
| 3 / 2.2 / 0.45 | 198.0, 198.3, 207.3 | 164.0, 201.4, 261.2 (201.4) | lost 3/3 |
| 3 / 2.0 / 0.45 | 187.5, 208.2, 197.3 | 262.4, 241.1, 202.2 (241.1) | |
| 3 / 1.8 / 0.45 | 197.8, 178.5, 197.3 | 241.5, 245.6, 197.1 (241.5) | |
| 3 / 2.0 / 0.6 (first code) | 187.5, 221.4, 187.3 (187.5) | 200.9, 235.8, 241.1 (235.8) | |
| 3 / 2.0 / 0.7 | 187.3, 221.4, 187.3 (187.3) | 236.8, 238.4, 261.2 (238.4) | |
| 3 / 1.7 / 0.6 | 187.5, 207.7, 197.3 | 200.9, 228.6, 177.6 | |
| **3 / 2.0 / 0.6 (final code)** | **187.5, 221.4, 187.3 (187.5), idle 15/23/16** | **204.6, 235.8, 241.1 (235.8), idle 20 or less** | **lost 3/3 (market_closed, 0/36 broken)** |
Before: A median 213 (idle 25), B 221 (idle 20). Accepted: 3 / 2.0 / 0.6, both medians inside 180-240, all nine rows as expected.
RING 0.6 is well under APART/2 (1.0). B's third seed wins at 241.1 s; only the median is in the pass rule.

## What the tests needed
- APART 2.0 first failed test_fair_life "centres stay APART at each stroll (4 strolls under)" at RING 0.6 (10 under at RING 0.45): when 16 random
  tries found no room APART, the farthest try was taken even if closer than APART. I had gone to APART 1.7 to get it past; the ruling keeps APART
  at 2.0, so the placement was fixed instead: FairLife._scan() sweeps the centre disk on a 0.4 grid for the free point nearest the best try.
- test_market_panic "a first-crowd goer's spot within FAIR_R with a way to it" failed at RING 0.6 (APART 1.7): a ring slot nudged to walkable ground
  could land outside the fair or out of a member's reach. FairLife._spot_for() now pulls a slot toward the centre by quarters until it is inside
  FAIR_R and reachable, else the centre itself.
- test_fair_life "the lone survivor is in a group of 2+": it required another group below GROUP_MAX at the start; with GROUP_MAX 3 every other
  group can be full. It now breaks one member of the largest other group when none has room, then checks the survivor joins a group with room.
  The invariant is unchanged (a survivor with room joins a group); only the hardcoded precondition went.

## Non-panic rows
40 moved at HEAD; each matches its old checksum with only T1 (a burning person runs) on 7519cc08 and moves with T2 on (flinch). Outcomes
compared (won/reason/time) against the T1-only run:
- 39 keep their outcome (largest shifts: hide_faithful_veil_play_1 106.9 -> 205.1 s, prisoner_b_play_1 179.2 -> 233.9 s, prisoner_b_play_2 238.7 -> 211.2 s,
  hide_faithful_death_play_1 207.2 -> 185.4 s). These are re-recorded.
- 1 FLIPPED: god_decree_lamb_play_3 (--god=decree:1): was won, lamb_out at 87.2 s; now lost, lamb_taken at 61.6 s. NOT re-recorded (its old
  checksum -230395448 stays in god_t1_lamb.tsv, so it is red); a flinch bug to fix.
12 further rows timed out at 600 s under load in the first run and match their recorded checksums rerun alone.
Re-recorded rows:
- god_ruin_lamb_play_1
- god_ruin_lamb_play_2
- god_ruin_lamb_play_3
- god_death_lamb_play_2
- god_death_lamb_play_3
- prisoner_play_1
- prisoner_play_2
- armoury_play_2
- armoury_play_3
- sermon_play_1
- sermon_play_3
- first_taste_ruin_play_1
- first_taste_ruin_play_2
- first_taste_ruin_play_3
- first_taste_veil_play_2
- first_taste_veil_play_3
- first_taste_decree_play_1
- first_taste_decree_play_2
- first_taste_decree_play_3
- hide_faithful_ruin_play_1
- hide_faithful_ruin_play_2
- hide_faithful_ruin_play_3
- hide_faithful_death_play_1
- hide_faithful_death_play_2
- hide_faithful_death_play_3
- hide_faithful_veil_play_1
- hide_faithful_veil_play_2
- hide_faithful_decree_play_3
- face_halcyon_ruin_play_1
- face_halcyon_ruin_play_2
- face_halcyon_ruin_play_3
- face_halcyon_veil_play_1
- face_halcyon_veil_play_2
- face_halcyon_veil_play_3
- face_halcyon_passage_play_2
- prisoner_b_play_1
- prisoner_b_play_2
- prisoner_b_play_3
- prisoner_play_3
Panic rows re-recorded (all 9 reproduce under refs_check: ok=9 bad=0):
- panic_none_1: -899542793
- panic_none_2: -121522359
- panic_none_3: -400893264
- panic_play_1: -448373651
- panic_play_2: -82784894
- panic_play_3: -961653177
- panic_b_play_1: -871968472
- panic_b_play_2: -816928688
- panic_b_play_3: -143323611
