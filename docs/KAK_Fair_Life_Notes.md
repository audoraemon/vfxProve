# KAK Fair Life: gate and references (2026-11-22) -- gate NOT settled

Fair life = a burning person always runs (T1), fearless people flinch (T2), Market Panic's goers stand in talking groups and stroll (T3).
No rule number and no policy changed. The 9 `panic_*` rows are NOT re-recorded (the gate below is unsettled); the 40 non-panic rows are.

## Market Panic gate (seeds 1/2/3, win time s; before: A median 213 idle 25, B median 221 idle 20)
| GROUP_MAX / APART | route A | route B | none |
|---|---|---|---|
| 4 / 1.6 (as built) | 187.3, 187.3, 187.3 | 169.6, 168.3, 279.8 (median 169.6) | lost 3/3 |
| 3 / 2.2 | 198.0, 198.3, 207.3 (198.3) | 164.0, 201.4, 261.2 (201.4) | lost 3/3 |
| 3 / 2.0 | 187.5, 208.2, 197.3 (197.3) | 262.4, 241.1, 202.2 (241.1) | not run |
| 3 / 1.8 | 197.8, 178.5, 197.3 (197.3) | 241.5, 245.6, 197.1 (241.5) | not run |
| 4 / 2.0 (seed 1 only) | 187.3 | 241.1 | |
All wins; longest idle 12-27 s. Every setting with GROUP_MAX 3 brings A to about 197-198 s (GROUP_MAX 4 gives 187.3); route B moves
chaotically with APART (seed 1: 169.6 at 1.6, 241.5 at 1.8, 241.1 at 2.0, 164.0 at 2.2).
Only 3 / 2.2 puts both medians inside 180-240, but it fails two real invariants: tests/test_market_panic.gd (a first-crowd goer's spot
within FAIR_R with a way to it) and test_fair_life.gd (centres APART). 3 / 2.0 and 3 / 1.8 pass test_market_panic but B's median is 241 s;
GROUP_MAX 3 also fails test_fair_life's lone-survivor check (it expects a group with room below GROUP_MAX). Needs a controller decision.

Why all route A seeds end at exactly 187.3 s (GROUP_MAX 4): the win is the final Heaven Splitter. The policy casts it only once no crowd
is still to come; by 185.9 s 33 of 36 are broken, the splitter breaks the rest, 187.3 s is its landing. Old tree, seed 1: the same
splitter at 220.0 s (win 221.4 s), because the last crowd went out at 220 s; grouped goers fall faster so the chain (45 s after the crowd
before scatters) sends the last crowd out about 35 s earlier.
Per cast, seed 1 (goers broken, from the cast to the next 10 s sample): A, grouped, Smite on a knot at 75.1 s: +11 (old Smite at 73.3 s: +1);
Smite on a knot at 120.5 s: +7. B, Ember at 27.1 s: 7 goers by the house (old 4), at 153.1 s: 8 (old 6, at 160.4 s), at 168.2 s: 10.

## Non-panic rows that moved (40): cause T2, steadied people flinch
Each matches its old checksum with only T1 (a burning person runs) on 7519cc08 and moves with T2 on; FairLife (T3) touches only
Market Panic. Re-recorded in references.tsv, routes_t3.tsv and god_t1_lamb.tsv:
- god_ruin_lamb_play_1: -> -244048359
- god_ruin_lamb_play_2: -> -666921060
- god_ruin_lamb_play_3: -> -116704511
- god_death_lamb_play_2: -> -360216341
- god_death_lamb_play_3: -> -934827455
- god_decree_lamb_play_3: -> -621632321
- prisoner_play_1: -> -216214103
- prisoner_play_2: -> -907569215
- armoury_play_2: -> 316045299
- armoury_play_3: -> 517443532
- sermon_play_1: -> -65701642
- sermon_play_3: -> -988489857
- first_taste_ruin_play_1: -> -212365464
- first_taste_ruin_play_2: -> 651438161
- first_taste_ruin_play_3: -> -877873072
- first_taste_veil_play_2: -> -859703298
- first_taste_veil_play_3: -> -971171591
- first_taste_decree_play_1: -> -935641348
- first_taste_decree_play_2: -> -150856756
- first_taste_decree_play_3: -> -708887974
- hide_faithful_ruin_play_1: -> -169732903
- hide_faithful_ruin_play_2: -> -174309574
- hide_faithful_ruin_play_3: -> -777527260
- hide_faithful_death_play_1: -> -879005245
- hide_faithful_death_play_2: -> -67560178
- hide_faithful_death_play_3: -> 484854018
- hide_faithful_veil_play_1: -> -292562808
- hide_faithful_veil_play_2: -> -896302904
- hide_faithful_decree_play_3: -> -431741350
- face_halcyon_ruin_play_1: -> -124873676
- face_halcyon_ruin_play_2: -> -541716458
- face_halcyon_ruin_play_3: -> -90541593
- face_halcyon_veil_play_1: -> 275252805
- face_halcyon_veil_play_2: -> -163612811
- face_halcyon_veil_play_3: -> -991201175
- face_halcyon_passage_play_2: -> -76083869
- prisoner_b_play_1: -> -473416234
- prisoner_b_play_2: -> -79369831
- prisoner_b_play_3: -> 488453769
- prisoner_play_3: -> 988476786

12 more rows timed out at 600 s under load in the first run and match their recorded checksums when rerun alone (no move).
