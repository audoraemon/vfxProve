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

## Gate table (win time s, seeds 1/2/3) -- history: the T4 tuning runs; the final gate is in the last section
| GROUP_MAX / APART / RING | route A | route B | none |
|---|---|---|---|
| 4 / 1.6 / 0.45 (as built) | 187.3 x3 | 169.6, 168.3, 279.8 (169.6) | lost 3/3 |
| 3 / 2.2 / 0.45 | 198.0, 198.3, 207.3 | 164.0, 201.4, 261.2 (201.4) | lost 3/3 |
| 3 / 2.0 / 0.45 | 187.5, 208.2, 197.3 | 262.4, 241.1, 202.2 (241.1) | |
| 3 / 1.8 / 0.45 | 197.8, 178.5, 197.3 | 241.5, 245.6, 197.1 (241.5) | |
| 3 / 2.0 / 0.6 (first code) | 187.5, 221.4, 187.3 (187.5) | 200.9, 235.8, 241.1 (235.8) | |
| 3 / 2.0 / 0.7 | 187.3, 221.4, 187.3 (187.3) | 236.8, 238.4, 261.2 (238.4) | |
| 3 / 1.7 / 0.6 | 187.5, 207.7, 197.3 | 200.9, 228.6, 177.6 | |
| 3 / 2.0 / 0.6 (T4 code; A superseded by T5: 197.3, 221.4, 187.3, median 197.3) | 187.5, 221.4, 187.3 (187.5), idle 15/23/16 | 204.6, 235.8, 241.1 (235.8), idle 20 or less | lost 3/3 (market_closed, 0/36 broken) |
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

## Non-panic rows (T4 history; the T5 and final-review sections below supersede it)
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
Panic rows as T4 recorded them (history; the references now hold the values in the last section):
- panic_none_1 -899542793, panic_none_2 -121522359, panic_none_3 -400893264 (unchanged since)
- panic_play_1 -448373651, panic_play_2 -82784894, panic_play_3 -961653177 (T5 moved all three; play_3 is now -786045975)
- panic_b_play_1 -871968472, panic_b_play_2 -816928688, panic_b_play_3 -143323611 (unchanged since)

## T5 (history of the walking-goer fix; counts as at f82e0041): nobody on his way somewhere freezes in a flinch (2026-11-23)
Cause: god_decree_lamb_play_3 lost (lamb_taken 61.6 s) because the Decree breath called panic() on the bolting lamb's seizer's neighbourhood and the
lamb, a DUTY citizen walking to the exit (LostLambDirector._run_for_it, go_duty), flinched: _think returned for FLINCH_SECONDS, he stood, patrol re-seized
him. Same cause for escorted and bound walkers (hide_faithful_veil_play_1, prisoner_b_play_1) and the fair's own DUTY goers walking to the fair.
Fix: Person.flinch() refuses a DUTY citizen with a goal he has not reached (has_goal()). Standing goers, calm people and soldiers at their post flinch as before.
Result: god_decree_lamb_play_3 wins again at 87.2 s (lamb_out) with its old checksum -230395448. 26 of the 49 rows reach their exact pre-flinch
(641e5fe4) checksum again; 22 differ but keep the pre-flinch outcome; no row flips. Rows re-recorded: the 36 that no longer match the recording made on top of f82e0041 (T4's).
Pre-flinch times are 641e5fe4 runs; T5 times are this tree. Gate (final 3 / 2.0 / 0.6 unchanged): A 197.3, 221.4, 187.3 (median 197.3, idle 14/33/14);
B 204.6, 235.8, 241.1 (median 235.8, idle 20); none lost 3/3 (market_closed). Walking goers change panic timings only: panic_play_1 187.5 -> 197.3 s,
panic_b_play_1 204.6 unchanged.

| row | pre-flinch (641e5fe4) | T5 | note |
|---|---|---|---|
| armoury_play_2 | true 214.1 | true 214.1 | different checksum, same outcome (re-recorded) |
| armoury_play_3 | true 214.1 | true 214.1 | different checksum, same outcome (re-recorded) |
| face_halcyon_passage_play_2 | true 194.2 | true 194.2 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| face_halcyon_ruin_play_1 | true 186.2 | true 186.2 | different checksum, same outcome (re-recorded) |
| face_halcyon_ruin_play_2 | true 163.0 | true 163.0 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| face_halcyon_ruin_play_3 | false 286.4 | false 286.4 | different checksum, same outcome (re-recorded) |
| face_halcyon_veil_play_1 | true 194.7 | true 194.7 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| face_halcyon_veil_play_2 | true 195.8 | true 195.8 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| face_halcyon_veil_play_3 | true 199.2 | true 199.2 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_decree_play_1 | true 183.9 | true 183.9 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_decree_play_2 | true 185.5 | true 185.5 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_decree_play_3 | true 184.1 | true 184.1 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_ruin_play_1 | true 207.0 | true 207.0 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_ruin_play_2 | true 183.3 | true 183.3 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_ruin_play_3 | true 224.9 | true 224.9 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_veil_play_2 | true 201.1 | true 201.1 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| first_taste_veil_play_3 | true 201.2 | true 201.2 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_death_lamb_play_2 | true 121.6 | true 121.6 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_death_lamb_play_3 | true 120.3 | true 120.3 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_decree_lamb_play_3 | true 87.2 | true 87.2 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_ruin_lamb_play_1 | true 53.3 | true 53.3 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_ruin_lamb_play_2 | true 49.9 | true 49.9 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| god_ruin_lamb_play_3 | true 44.0 | true 44.0 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_death_play_1 | true 207.2 | true 207.2 | different checksum, same outcome (re-recorded); final review: back at its pre-flinch checksum |
| hide_faithful_death_play_2 | true 203.2 | true 203.2 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_death_play_3 | true 205.9 | true 205.9 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_decree_play_3 | true 102.1 | true 102.1 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_ruin_play_1 | true 98.1 | true 98.1 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_ruin_play_2 | true 187.8 | true 187.8 | checksum equals the pre-flinch reference at T5; final review: moved, same outcome (re-recorded) |
| hide_faithful_ruin_play_3 | true 104.3 | true 104.3 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_veil_play_1 | true 106.9 | true 106.9 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| hide_faithful_veil_play_2 | true 189.6 | true 189.6 | checksum equals the pre-flinch reference (flinch no longer touches him) |
| panic_b_play_1 | true 224.0 | true 204.6 | different checksum, same outcome (re-recorded) |
| panic_b_play_2 | true 222.4 | true 235.8 | different checksum, same outcome (re-recorded) |
| panic_b_play_3 | true 221.5 | true 241.1 | different checksum, same outcome (re-recorded) |
| panic_none_1 | false 300.0 | false 300.0 | different checksum, same outcome (re-recorded) |
| panic_none_2 | false 300.0 | false 300.0 | different checksum, same outcome (re-recorded) |
| panic_none_3 | false 300.0 | false 300.0 | different checksum, same outcome (re-recorded) |
| panic_play_1 | true 221.4 | true 197.3 | different checksum, same outcome (re-recorded) |
| panic_play_2 | true 197.3 | true 221.4 | different checksum, same outcome (re-recorded) |
| panic_play_3 | true 187.3 | true 187.3 | different checksum, same outcome (re-recorded) |
| prisoner_b_play_1 | true 179.2 | true 270.2 | different checksum, same outcome (re-recorded) |
| prisoner_b_play_2 | true 238.7 | true 236.3 | different checksum, same outcome (re-recorded) |
| prisoner_b_play_3 | true 207.2 | true 207.8 | different checksum, same outcome (re-recorded) |
| prisoner_play_1 | true 208.3 | true 192.6 | different checksum, same outcome (re-recorded) |
| prisoner_play_2 | true 202.4 | true 207.0 | different checksum, same outcome (re-recorded) |
| prisoner_play_3 | true 219.8 | true 196.3 | different checksum, same outcome (re-recorded) |
| sermon_play_1 | true 230.5 | true 230.5 | different checksum, same outcome (re-recorded) |
| sermon_play_3 | true 222.7 | true 222.7 | different checksum, same outcome (re-recorded) |

## Final review fix wave (2026-11-23)
Review findings fixed on top of T5:
- I1: a running flinch was never cancelled by whisper(), compel(), confuse(), fight() or go_duty() (a later god hold or director order waited
  up to 2 s: whisper 0.98 -> 0.03 tiles in 1.5 s, go_duty 2.19 -> 0.10). Person._flinch_end() now runs in _hold_begin() (whisper, compel,
  confuse and the other holds), go_duty() and fight(), and _flinch_think() ends the flinch itself when the mind is no longer eligible
  (citizen not CALM/RECOVER/OBSERVE/DUTY; soldier not at POST or hurrying), when held_by_will(WILL_ABSOLUTE) or resists_mind(), or when a
  DUTY citizen has a goal (the flinch never sets _goal, so a goal is always someone else's order).
- M5: flinch() also refuses a soldier with a goal (walking back to his post), as it does a DUTY citizen.
- (History, gone with the step on 2026-11-24: see the last section.) The flinch's step back (FLINCH_STEP 0.5) can carry a goer across WARD_R. steadied() reads position, so a goer standing
  near the edge can be unsteadied for a look. It is part of why the difficulty moved (panic A/B and the prisoner times); no code change.

Re-measure (49 rows of the T5 table, against the pre-flinch tree 641e5fe4): no outcome flips. Moved checksums re-recorded:
- panic_play_1 -414808058 (197.3 s), panic_play_2 -418723233 (221.4 s)
- prisoner_play_1 -17556210 (178.4 s), prisoner_play_2 -674301658 (200.6 s), prisoner_play_3 569348637 (196.3 s)
- hide_faithful_ruin_play_2 -418018406 (187.8 s), hide_faithful_death_play_1 -661230196 (207.2 s)
The other 42 rows reproduce their T5 recordings. Gate (3 / 2.0 / 0.6 unchanged): A 197.3, 221.4, 187.3 (median 197.3); B 204.6, 235.8, 241.1 (median 235.8);
none lost 3/3 (market_closed).

Prisoner times (s), seeds 1 / 2 / 3, median in brackets:
| route | pre-flinch (641e5fe4) | T5 | now |
|---|---|---|---|
| A (prisoner_play) | 208.3, 202.4, 219.8 (208.3) | 192.6, 207.0, 196.3 (196.3) | 178.4, 200.6, 196.3 (196.3) |
| B (prisoner_b_play) | 179.2, 238.7, 207.2 (207.2) | 270.2, 236.3, 207.8 (236.3) | 270.2, 236.3, 207.8 (236.3) |

## Step dropped (2026-11-24)
User ruling: "Drop the step". A flinch is turn, freeze, stare, carry on, and nobody moves. Person.FLINCH_STEP, _flinch_step_to and the step branch of
_flinch_think are gone; the freeze, the facing, the stare, the carry-on and the cancel rules of the final review stay. The step had carried goers across
WARD_R and the guard reaches (the M4 note above): with it gone the difficulty is back where it was. test_flinch now asserts a flinched person moves less
than 0.05 tiles through the flinch (checked to 0.2 s before its end) and keeps facing the danger; the warden and soldier test asserts they did not move.

Re-measure (49 rows against 641e5fe4): no outcome flips. 15 checksums re-recorded (panic_play_1/2/3, panic_b_play_1/2/3, prisoner_play_1/2/3,
prisoner_b_play_1/2/3, hide_faithful_ruin_play_2, face_halcyon_ruin_play_1 and _3); the other 34 reproduce. Gate (3 / 2.0 / 0.6): A median 207.5,
B median 221.6, both inside 180-240; none still loses (the three none rows reproduce, market_closed).

Times (s), seeds 1 / 2 / 3, median in brackets:
| run | pre-flinch (641e5fe4) | final review | now (no step) |
|---|---|---|---|
| prisoner A | 208.3, 202.4, 219.8 (208.3) | 178.4, 200.6, 196.3 (196.3) | 176.3, 217.4, 196.3 (196.3) |
| prisoner B | 179.2, 238.7, 207.2 (207.2) | 270.2, 236.3, 207.8 (236.3) | 215.5, 201.4, 183.8 (201.4) |
| panic A | 221.4, 197.3, 187.3 (197.3) | 197.3, 221.4, 187.3 (197.3) | 187.3, 216.1, 207.5 (207.5) |
| panic B | 224.0, 222.4, 221.5 (222.4) | 204.6, 235.8, 241.1 (235.8) | 204.6, 221.6, 241.1 (221.6) |
