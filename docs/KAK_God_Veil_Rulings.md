# KAK Veil authority powers: rulings

Decisions the plan and spec (docs/superpowers/specs/2026-11-19-kak-veil-authority-powers-design.md) do not settle, one line
each (`V<n>: what -- why`), and the baseline every task compares against.

## Baseline (Task 1, Step 0: branch god/veil-powers at 37d1ec38, before any Veil code)

Machine heavily shared (about 60 Godot processes from other sessions), so timing checks and part timeouts are load, not code.

| part | checks | failures | note |
|---|---|---|---|
| 1 | 4772 | 0 | |
| 2 | 1104 | 0 | |
| 3 | 987 | 0 | |
| 4 | 501 | 0 | |
| 5 | 896 | 0 | |
| 6 | 455 | 2 | test_decree_cage frame-time checks (p99.5 66-96 ms frames under load); same 2 when rerun alone |
| 7 | 871 | 2 | frame-time checks only (horde + servants under 5 ms: 8.7 ms) |
| 8 | 761 | 2 | frame-time checks only (Grave Tide pack under 8 ms: 10.4 / 12.1 ms) |
| 9 | 928 | 0 | |
| 10 | 1125 | 0 | |
| 11 | - | - | timed out at 2400 s under load (4-way) |
| 12 | - | - | timed out at 2400 s under load (4-way) |
| 13 | 1726 | 0 | |
| 14 | 1491 | 0 | |
| 15 | 1007 | 0 | |
| 16 | - | - | timed out at 2400 s under load (4-way) |

Reruns at the base commit (one at a time, though other sessions kept loading the machine): part 6 the same 2 cage timing checks;
part 7 the same 2 timing checks (6.5 / 9.8 ms); part 8 761/0; part 11 timed out again at 2400 s at the same place (after
test_capital_lamb's parity beats: pre-existing, not load alone); parts 12 and 16 not rerun (ruling C8). See task-1-report.md.

References at the base commit (`refs_check.sh --jobs=2 --only='^(digest|crowd_check)$'`):
`digest: 61267b7e90524d800bf1c3473a71146b OK`, `crowd_check: -535548941 OK`.

## Rulings

- V1: tests/test_draft.gd keeps "every power has a preview clip" honest with a named allow-list, `AWAITING_CLIPS`, of the seven new
  keys (and a check that a key leaves the list once its clip exists) -- the clips are Task 12's; Task 12 empties the list.
- V2: the Upgrades grid holds 59 locked powers by lowering `UpgradesScreen.MIN_CELL_H` from 12 to 11 (20 rows of 3 fit above
  GRID_BOTTOM, up to 60 powers), not by a fourth column -- four columns leave cells about 102 px wide, which cut far more names than
  test_descend_screens' "only a few names need a cut" allows; one pixel off a row is the smallest change that keeps its tests green.
- V3: the dusk ledger (`Dusk`, a Node2D) is made in `Crowd.setup()` beside the remains, as the brief says, drawn in ground units
  (transform `Iso.BASIS`, z -3, under the people) on the crowd's parent. It adds one object before the people; people stagger by
  spawn order, not instance id, and the digest, crowd_check and 40 non-Veil rows were checked unchanged with it.
- V4: `Crowd.night_mission` is set in `NightRules.apply()` (the one place a mission's look is applied: true for NIGHT, false
  otherwise) and cleared in `Crowd.clear()`.
- V5: `Crowd.sight_scale_at()` reads dusk patches only (`Dusk.covers()`), not Unseen Hour's veil (which hides everything already)
  nor `Dusk.everywhere`; Evernight's own sight, if it wants one, is its task's.
- V6: `Crowd.doom_witness()` gains an optional point (`doom_witness(at := Vector2.INF)`): the danger a seen Silent Doom death
  registers and a collapse's sight are scaled at the death or fall (the seen end; the viewer is the threat manager's). With no
  point, or an empty ledger, it is exactly `DOOM_WITNESS * sight_scale`. `nearest_witness()` checks each witness's own line only
  while a patch is live; with an empty ledger it runs the old search unchanged.
- V7: the aim ring's size follows the ground under the cursor (`Targeting._press`, as `hover()` sets it), and its tag is drawn by
  the ring's lower edge (`Targeting.ring_tag()`: "DARK" / "LIGHT", "" for a power not in `VeilRules.RING`).
- V8: Curfew's private inner class `Dusk` (src/fx/decree/curfew.gd, its drawn disc) is renamed `CurfewDusk`: the brief names the
  ledger `class_name Dusk`, and a global class of that name made curfew.gd fail to parse ("hides a global script class"). Nothing
  outside curfew.gd named the inner class; Curfew draws and behaves as before (test_unseen_curfew 22/22).
- V9: Evernight gets `Targeting.AREAS["evernight"] = {"shape": "circle", "r": 0.6}`, a mark where the click lands (as Tempest's and
  Voice of God's), not "none": test_targeting requires an area for every power, and the mark is no area of effect. It is not in
  `VeilRules.RING`, so it never changes size.
- V10: tests/test_power_sounds.gd takes the seven new keys onto its own `PENDING_QUIET` list (the list made for quiet powers still
  without their q_<key> cue) and counts 48 quiet powers: their sounds are Task 12's, which takes each key off the list.
