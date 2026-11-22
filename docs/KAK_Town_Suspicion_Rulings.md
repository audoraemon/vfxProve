# KAK Town Suspicion — Rulings and Results

Discord idea "About alarm and alert on ability use" (2026-11-20). Spec: docs/superpowers/specs/2026-11-20-kak-town-suspicion-design.md;
plan: docs/superpowers/plans/2026-11-20-kak-town-suspicion.md. Collected from the milestone workspace (.sdd/rulings.md).

## What it does

A power that looks like weather or an accident (Smite, Ember, Tornado, Tempest, Shatter, Tsunami, Breath) no longer sends the
bellkeeper at once. Each witnessed cast is a sign; signs add up to a Suspicion value 0..100 (Uneasy at 40, the town knows at 100).
A natural-looking cast excuses its own kinds of death for 90 s; excused deaths still raise the alarm stage, but the keeper is sent
only once the town knows, or when a district reaches Local Emergency on deaths nothing excuses. Delay only: the keeper is never
sent sooner than before, and a run with no natural power plays exactly as before.

## Rulings

- R1: the user approved the design on 2026-11-20; the watched-target proposal (spec 5.5 item 3) stands as written: a seen kill of
  an excused kind adds `TARGET_SIGN` (40) and calls the keeper only if the town then knows.
- R2: per task only the focused suites ran; the whole suite, all references, the gates and FLOW ran at Task 9 and at landing.
- R3: a person inside the cast's own danger is its victim, not its witness. `Crowd.sign_witness(points, sight, clear)` skips anyone
  within `clear` of a point. A Smite on a lone man with nobody else in sight is no sign.
- R4: that clearance is `minf(radius, sight * 0.5)`, so a danger wider than half its own sight (Dragonfire, Tsunami) still has
  witnesses at its rim.
- R5: the machine was swamped by other sessions' runs, so per-task reference subsets were skipped; Task 9 checked every row once
  and explained every mover.
- R6: two implementers may work at once on different files, each staging only its own files by name.
- R7 (fix wave after the final review; amends spec 5.5 "Explained deaths"):
  1. An incident is explained only while a natural-looking cast excuses its kind: `Suspicion.EXCUSE_SECONDS := 90.0`,
     `EXCUSES := {lightning: [lightning], fire: [fire], storm: [wind, lightning], quake: [pit], flood: [water],
     miasma: [choke]}`, and every natural look also excuses `collapse`. The excuse starts at the cast, witnessed or not. An
     unnatural power's kills (Heaven Splitter's `lightning`, Dragonfire's `fire`) are never excused.
  2. `tools/dev/behaviour_check.gd`'s `soldiers` scenario calls the keeper directly after its forced Local Emergency.
  3. The keeper latch is spent once the bell has left idle by any route during an emergency, so there is no second call.
  4. The thought tag is shown only for a sign seen before the town knows.
  5. The "uneasy" banner is quiet (`Rules.quiet_banner`); the "knows" banner stays loud.
  6. `Suspicion.add()` multiplies by `wary`, so the watched-target sign is 40 x wary.
- R8 (user, 2026-11-22): Heart of Faith's gate median is 178 s against the 180 s floor (base 181 s). Accepted as it is; the gate
  is noted red. The bot's hush policy was fixed first (idle 65 -> 33 s).

## Numbers that differ from the first spec

- `EXCUSE_SECONDS` 90 and the `EXCUSES` table are new (R7).
- The witness clearance `minf(radius, sight * 0.5)` is new (R3, R4).
- `TARGET_SIGN` scales with the town's `wary` (R7 item 6).

## References

41 of 508 rows moved and were re-recorded (god_t1_harvest 3, god_t1_prayers 1, god_t1_tax 6, references 29, routes_t1 1,
routes_t2 1); 467 are unchanged. For every mover the base reproduces the old value, the run has 2-25 excused incidents and a
keeper sent later than the district emergency (or only at a watched target's seen kill once the town knows), and the bot still
wins.

## Gates, branch against base (19 pairs)

| Gate | Base | Branch |
|---|---|---|
| bishop | 211 s, idle 21, PASS | 209 s, idle 21, PASS |
| bread | 199 s, idle 26, PASS | 221 s, idle 27, PASS |
| break_hunt x Decree | 118 s, idle 44, PASS | 133 s, idle 44, PASS |
| break_hunt x Ruin | 123 s, idle 15, PASS | 126 s, idle 16, PASS |
| expel_inquisitor x Ruin | 157 s, idle 32, PASS | 160 s, idle 33, PASS |
| face_halcyon x Ruin | 2/3, 175 s, idle 65, FAIL | 2/3, 182 s, idle 65, FAIL |
| harvest x Ruin | 174 s, idle 40, PASS | 174 s, idle 40, PASS |
| prayers x Decree | 214 s, idle 86, FAIL | 214 s, idle 86, FAIL |
| tax x Decree | 89 s, idle 35, PASS | 101 s, idle 35, PASS |
| tax x Ruin | 130 s, idle 40, PASS | 144 s, idle 40, PASS |
| harvest | 182 s, idle 40, PASS | 182 s, idle 40, PASS |
| heart | 181 s, idle 42, PASS | 178 s, idle 33, FAIL (R8) |
| hide_faithful x Decree | 101 s, idle 31, PASS | 101 s, idle 31, PASS |
| hide_faithful x Ruin | 104 s, idle 55, FAIL | 104 s, idle 55, FAIL |
| panic route b | 222 s, idle 20, PASS | 224 s, idle 20, PASS |
| prisoner | 208 s, idle 36, PASS | 208 s, idle 36, PASS |
| silence_witness x Decree | 151 s, idle 34, PASS | 171 s, idle 45, PASS |
| silence_witness x Ruin | 140 s, idle 29, PASS | 159 s, idle 45, PASS |
| tax route b | 208 s, one run died under machine load (not rerun) | 244 s, idle 35, PASS |

Three gates were red on the base and are unchanged (face_halcyon x Ruin, prayers x Decree, hide_faithful x Ruin).

## Not covered

- The gauge's place at 640x360 and with the TAB panel open was not photographed.
- No play by hand.
