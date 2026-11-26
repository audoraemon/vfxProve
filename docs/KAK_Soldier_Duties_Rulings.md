# KAK Soldier Duties — Rulings and Results

Discord idea "Soldier Behavior Adjust" (2026-11-20) plus the user's corpse-duty idea. Spec:
docs/superpowers/specs/2026-11-20-kak-soldier-duties-design.md; plan: docs/superpowers/plans/2026-11-20-kak-soldier-duties.md.
Collected from the milestone workspace (.sdd/rulings.md), shortened; the spec carries R18-R21 in full.

## What it does

Soldiers no longer all march to the Citadel at City Emergency. Every behaviour is a job kind on the board (`GuardJobs.Kind`:
CITADEL, FIRE, PILE, SHELTER, SWEEP, CORPSE, CORDON, GATE), each run by a `Duty`:

- **Citadel guard**: 20 men walk in and stand in ranks; everyone else keeps working the city. The guard refills while the board
  is open.
- **Street beats**: in the calm stages pairs of soldiers walk a beat instead of standing posted.
- **Corpse duty**: a body-leaving kill leaves a body for 45 s (blast and fire leave none). A pair on a beat inspects it ("FOUND IN
  n"), reports it, lifts it and carries it off the street. A found body whose death the town never counted is an incident.
- **Cordon**: after a fire put out or a collapse, men rope the road stretch for up to 40 s and turn citizens back.
- **Sweep**: a witnessed power brings a squad that sweeps the district for 30 s with far sight (4.0); a further seen power in a
  swept district costs an extra alarm.
- **Gate check**: from Local Emergency the gate guards step out, watch with far sight and see through a guise or the god's hold
  ("THE GATES ARE WATCHED", "GATE CHECK" tag). Dormant below Local Emergency.
- **Shelter escort**: at City Emergency a soldier walks a regrouping household to its shelter and steadies it.
- Soldiers do not repair. The investigators are gone; the sweep replaces them.

## Rulings

Decided by the user: the small Citadel guard; the six behaviours; no repairs; every behaviour a job kind on the existing board;
bodies lie 45 s, stand-in clips, no new art; a lifted body is lost to Death powers (the tags are the warning); **R17** a gate guard
sees through a guise or a hold only from Local Emergency.

Controller calls made during the run, **for the user's review** (each can be flipped):

- **R18 (corpse duty)**: a found body adds an incident, an alarm and a sweep request only when the death was never counted (a
  quiet, hushed or veiled kill). A seen death is not taxed twice; the "A BODY IS FOUND" banner still shows and the body is still
  carried. Evidence: two seen kills made a Local Emergency.
- **R19 (cordon, sweep)**: cordon and sweep men never walk into a live danger; a cordon waits until the danger has ended.
  Evidence: a cordon man walked into Decree's airless cell and died, a fourth event and a Local Emergency.
- **R20 (gate check)**: the gate check is wholly dormant below Local Emergency (no job, no stepping out, no far sight, no badge).
  Replaces R17's last sentence. Evidence: the calm-stage parts alone turned eight reference rows from won to lost; far sight with
  no tag is a hidden loss. The optional calm-stage "turn to a passing walker" was not built.
- **R21 (sweep)**: a man inside a power's danger radius calls a sweep only if he comes out of it alive (walks out, or is alive
  when the danger is over, or after `TELL_SECONDS` 20). A witness outside the radius within his own reach (2.0; a sweep or gate
  man 4.0) calls it at once. In line with Town Suspicion's `sign_witness()`: a cast's own victim is no witness.
- **R22 (sweep)**: a sweep takes no man while the danger that called it is still live where it was seen; the open job waits
  (its 20 s window does not run down) and forms when the danger ends. A power with no lingering danger is swept at the next
  board step as before. A sweep answers a cast; it does not judge the cast that called it. Evidence: Decree's cell landed
  seen, the sweep it called formed 2.7 s later and its far sight carried on the warning the same cast's breath had just
  stopped; Decree's First Warning fell from 3/3 to 1/3 and is back at 3/3.
- **R12.4 / R9.2**: a director's charge (`answers_lure`: the Lamb, the prisoner, First Prayers' people) is never spotted at a
  checked gate and never turned back by a cordon; those missions lead him out by a gate.
- **R9.4**: festival and Market Panic goers are plain citizens; a cordon may turn them back for up to 40 s.
- **R10.1**: one power, one charge: at most one extra alarm per swept district per frame.
- **R10.4**: one witness reach everywhere (`Crowd.witness_reach()`): a far-sighted soldier (sweep, live gate check) witnesses and
  carries to 4.0 in every director that judges a witness; nobody else changes.
- **R10.7**: for 30 s a sweep makes an unseen kill in its district much harder. Counters: break the squad, another district, a
  hush, a veil, waiting.
- **R13.5**: a power's own fright (Divine Schism, Law Mark) is never steadied away by an escort.
- **R14.1-2**: a mission director takes only the men it keeps, and a man it takes leaves his duty cleanly.

Process rulings (R1-R8, R11, R15, R16): fix waves after each task review; the baseline of gates and reference outcomes was taken on
the branch base and, after the merge of Town Suspicion, on feat/Develop-Main e78af8e2 for its 41 moved rows.

## References

499 of 508 rows move (every board row: the crowd stands differently from the first second); re-recorded in
`tools/dev/refs/*.tsv`. Outcomes against feat/Develop-Main, row by row: 469 the same result, 9 gained, 11 lost.

Gained (lost on Develop-Main, won here): `sermon_b_play_1`, `sermon_b_play_2`, `silence_witness_death_play_2`,
`expel_inquisitor_dominion_play_2`, `starfall_toll_2`, `tax_toll_2`, `tax_toll_3`, `warning_toll_1`, `warning_toll_3`.

Lost (won on Develop-Main, lost here), each with its cause:

| Row | Before | Now | Cause |
|---|---|---|---|
| `tax_play_2` | won 229.4 | taxes 262.0 | A street patrol pair walks up the first collector's street in his only unseen moment; the loadout cannot clear a soldier witness. |
| `tax_b_play_2` | won 265.6 | dawn 300.0 | Same patrol. |
| `exodus_b_play_1` | won 245.4 | exodus_few 239.0 | Same as before to 111 s; then the gate check goes live at Local Emergency and a sweep comes to the main gate; a kill there tips City Emergency. Diagnosis partial. |
| `expel_inquisitor_dominion_play_1` | won 207.7 | dawn 352.4 | From Local Emergency the gate check ends a whisper at a gate's mouth; the captain is walked back three times. Two checkers stand 3.6 apart, one Discord (1.2) cannot take both. |
| `god_decree_prayers_play_3` | won 239.8 | gaze 94.7 | Town Suspicion allows one early kill, so four Faithful line the market door; the cell that stops the runner kills seven more, seen by townsfolk. |
| `god_ruin_prayers_play_2` | won 197.8 | gaze 170.7 | A shelter escort takes two Faithful indoors, Ruin's usual targets; the fire holding the last liner goes out 6 s before the prayer ends, Ember still cooling. |
| `god_passage_prayers_play_1` | won 195.6 | few 231.4 | The first walker, frightened at the door, no longer shelters in the shrine (which counted as a prayer) but recovers and walks home. |
| `relic_toll_2`, `starfall_toll_3`, `informer_toll_3`, `capital_prayers_toll_3` | won | lost | Toll scripts (fixed scripts that show the bell, not players): they pick targets by who stands around, and the crowd stands differently. The first two were diagnosed (not broken by the duties); the last two moved after R22 and were not diagnosed. |

Bot routes changed so honest play wins again in the new town: Death's and Decree's First Prayers, Ringers, Relic route B,
Dominion's Expel the Inquisitor (tools/dev/behaviour_check.gd, tools/dev/routes/).

## Gates, branch against base (wins / median / worst idle)

Base = the branch base a5825501 (R11: the three starred cells are from the Might gauge's baseline, the base runs timed out under
machine load). The last column is the gate's own count of passing pairs (a pair fails on too few wins or on idle over 45 s).

| Mission | ruin | death | veil | passage | decree | dominion | Gate |
|---|---|---|---|---|---|---|---|
| First Warning, base | 3/3 74 | 3/3 78 | 3/3 175 | 3/3 68 | 3/3 74 | 3/3 101 | 6/6 |
| First Warning, now | 3/3 74 | 3/3 78 | 3/3 199 | 3/3 68 | 3/3 79 | 3/3 101 | 6/6 |
| Tax, base | 3/3 130 | 3/3 152 | 3/3 132 | 3/3 160 | 3/3 89 | 3/3 181 | 6/6 |
| Tax, now | 3/3 141 | 3/3 152 | 3/3 132 | 3/3 160 | 3/3 98 | 3/3 181 | 6/6 |
| Harvest, base and now | 3/3 174 | 3/3 153 | 3/3 152 | 3/3 72 | 3/3 80 | 3/3 195 | 6/6 |
| Lamb, base | 3/3 50 | 3/3 122 | 3/3 50 | 3/3 22 | 3/3 72 | 2/3 111 | 6/6 |
| Lamb, now | 3/3 50 | 3/3 139 | 3/3 50 | 3/3 22 | 3/3 72 | 2/3 111 | 6/6 |
| First Prayers, base | 3/3 202 | 3/3 153 idle 52 | 3/3 102 | 3/3 259 idle 78 | 3/3 214 idle 86 | 3/3 260 | 4/6 |
| First Prayers, now | 2/3 204 | 3/3 175 idle 51 | 3/3 102 | 2/3 267 idle 78 | 2/3 274 idle 101 | 3/3 253 | 4/6 |
| Hide the Faithful, base | 3/3 104 idle 55 | 3/3 206 | 3/3 128 idle 68 | 3/3 62 idle 47 | 3/3 101 | 3/3 184 | 3/6 |
| Hide the Faithful, now | 3/3 111 idle 61 | 3/3 193 | 3/3 144 idle 68 | 3/3 62 idle 47 | 3/3 101 | 3/3 184 | 3/6 |
| Silence the Witness, base | 3/3 140 | 2/3 150 | 3/3 193 | 3/3 145 | excepted | 3/3 216 | 5/5 |
| Silence the Witness, now | 3/3 159 | 3/3 154 | 3/3 193 | 3/3 145 | excepted | 3/3 216 | 5/5 PASS |
| Expel the Inquisitor, base | 3/3 157 | 3/3 139 | 3/3 181 | 3/3 124 | excepted | 2/3 243* | 3/5 |
| Expel the Inquisitor, now | 3/3 160 | 3/3 139 | 3/3 181 | 3/3 135 | excepted | 2/3 282 idle 48 | 4/5 |
| Break the Hunt, base | 3/3 123 | 3/3 211 | 3/3 177 | 3/3 112 | excepted | 3/3 298 idle 115* | 4/5 |
| Break the Hunt, now | 3/3 126 | 3/3 211 | 3/3 177 | 3/3 112 | excepted | 3/3 298 idle 115 | 4/5 |
| Face Halcyon, base | 2/3 175 idle 65* | 3/3 194 | 3/3 196 | 3/3 194 | 3/3 134 | 3/3 136 | 5/6 |
| Face Halcyon, now | 2/3 211 idle 67 | 3/3 194 | 3/3 199 | 3/3 194 | 3/3 134 | 3/3 136 | 5/6 |

No gate is worse than its base; Silence the Witness now passes. First Prayers keeps 4/6 but with other pairs: Death, Passage and
Decree failed on idle before; now Ruin, Passage and Decree each lose one seed of three.

## Landing checks (2026-11-25, merged with feat/Develop-Main: Town Suspicion, Might gauge, Mission clarity, march sound removed)

- Suite: 25,520 checks, 4 failures, all frame-time checks that fail under this machine's load (two Pale Reign horde checks pass
  when run alone; the two Decree Cage level checks fail the same way on feat/Develop-Main).
- References: all 508 exact after the re-record (422 in the landing run; the 86 that hit its 600 s limit under load pass with a
  longer limit).
- FLOW 211 / 0.
- Frame rate (board bench, medians of 3, alternating, on a loaded machine; A = feat/Develop-Main, B = this branch): Warning
  61.0 / 57.8, Mira's House 52.4 / 44.2, Vigil Flame 53.7 / 53.0, Procession 45.8 / 43.8, Last Judgement 50.7 / 50.7; an earlier
  set gave 47.7 / 46.0, 37.0 / 35.7, 42.8 / 42.4, 33.2 / 30.8, 40.4 / 38.7. The branch is 0 to 2 fps lower in nine of ten pairs
  (one noisy outlier): a small real cost, most likely the soldiers who now walk beats instead of standing. Not measured on a
  quiet machine.

## Open questions for the user

1. **First Prayers** is harder for Ruin, Passage and Decree (2/3 each, 3/3 before). Causes above. Options: accept (the town
   answers), or let a shelter escort leave the mission's Faithful alone (as R9.2 / R12.4 already spare a director's charge).
2. **Tax** seed 2 (both routes): the street patrol takes the collector's only unseen moment. Options: accept, or keep beats off a
   mission's marked street.
3. **Expel the Inquisitor x Dominion**: a whisper ends at a checked gate from Local Emergency (R17, the user's choice); with two
   checkers 3.6 apart one Discord cannot blind the gate.
4. Frame rate: about 2 fps lower on a loaded machine; a quiet-machine bench is still owed.
5. Rulings R18-R22 above are controller calls; each can be flipped.

## Not covered

- New art: the duties use stand-in clips (walk, stand, talk, carry as a slow walk). No PixelLab.
- The optional calm-stage "gate guard turns to a walker" of R20.
- The toll scripts were not rewritten for the new town.
