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
- V11: Shadow Play's silent kill kind is `&"shade"`, not `&"shadow"`: `&"shadow"` is already the Pale Serpent's kind (a whole body
  in `Remains.BODY_KINDS`, a quiet slump in `DeathVoices.QUIET_KINDS`, the alarm path in `Crowd._on_killed`); making it silent and
  bodiless would move every Serpent row. `Rules.POWER_KINDS["shadowplay"] = [&"shade"]`; the person's status key stays
  `statuses[&"shadow"]` (`Person.is_shadow()`). Task 9 takes its soldiers with `crowd.take(p, &"shade")`.
- V12: `&"dreamless"` (Dreamless's found body) joins `DeathVoices.QUIET_KINDS` as `&"doom"` is there: its fall is a slump, never a
  cry (no Veil power makes a death voice). The four silent kinds are listed there too, though `Crowd._on_killed` returns before any
  voice for them.
- V13: `FaceHalcyonDirector` has no inquisitors (the brief's "face_halcyon (inquisitors)"): nobody seizes there, the escorts march the
  believers to the pyre and breaking them is the win. Its `quarry()` is its escorts (`escort_lists`), so Blight on one makes him ill,
  not gone; `keeps_alive()` is the households' believers (Exodus) and `believers`.
- V14: Directors that extend a listed one answer as it does: Bishop, Expel the Inquisitor, The Informer, The Tax Collector
  (Assassinate's quarries); Heretic Hunt, Lantern Eye, Break the Hunt (Hunt's head); Ringer and Witness (the Warning's watchman and
  messenger, plus the Ringer's own keeper); Silence the Witness (each Bell-Ringers post's); First Prayers (Mira's shouter and
  believers); Market Panic (the Festival's mayor); First Taste (the Rite's captive); The Relic Run (its carter; Vigil Flame's `wren`,
  null there); The Prisoner and The Lost Lamb (the Escort's charges kept alive). The Lost Lamb has no shepherd field (spec 5.2's
  "the lamb's shepherd"): no quarry there.
- V15: `Person.send_home_sick()`: the sick walk in CALM (a soldier in POST, anchor his yard), and `_think()`'s sick branch takes the
  walk up again every look, whatever took the mind meanwhile; no fright, look, flight, fight or duty takes him (`can_take_duty()`
  false). Indoors within 0.9 of the home point (snapped walkable; a soldier's barracks yard; no home: the nearest house); with no path
  he walks straight. A sick soldier indoors is not stepped (`frame()` returns). A Harvest carter sent home sick drops his load by
  H7's path (`HarvestDirector._dropped_look()` counts `home_sick` as fright).
- V16: The shadow and the dreaded are read at: `Crowd.nearest_witness()` and `TempleReport._witness()` (no witness),
  `MissionDirector._sees()` (no Faithful sight, no report), `EscortDirector._seen_by()` (no seizure, the whole Escort family), the
  Harvest's called guard, `BellNetwork` (the climb holds: no ring), `Crowd._voice()` (no shout), `Person.panic/observe/flee/fight` and
  `_fight_step()`; the walk: `Person.tick()` holds a dreaded non-shadow still, and `Person._step_blocked()` refuses a step from outside
  into dreaded ground (he waits at the edge). Every check is behind `statuses.is_empty()` / `dreads.is_empty()`: nothing changes
  without a Veil status.
- V17: `Crowd.take()` hides the taken at once (`visible = false`): no body is drawn; the power draws its own vanishing.
- V18: `Crowd.spared()` asks the director through `Crowd.mission_keeps` (registered in `MissionDirector.setup()` beside
  `mission_holds`, cleared with the mission hooks).
- V19: `LightField.mute(share)` touches only the static lights the field held when the muting began (a call with no muting on);
  lights added after it -- Evernight's torches -- are never muted, and `mute(1.0)` gives every muted light back as made and ends the
  muting.
- V20: `Rules.haste` is read per slot by `advance()` only while it is non-empty, and never for a slot whose `cooldown_of()` is 999 or
  more (`Rules.ONCE_COOLDOWN`); with no haste the cooldown arithmetic is exactly as before.
- V21 (Task 5): Slumber lays its dusk at the cast (in _build), not when the hush lands at T_FALL -- test_veil_law (not this task's file) checks that every Veil effect lays its dusk at once, and the dusk only shortens sight; the sleep itself is at T_FALL.
- VB1 (Task 7): Dreamless fixes its victims at the cast (`victims_at(field, at, r, most)`: reach and count from VeilRules, nearest first, then instance id) and decides at T_SIT, not at the cast, who is already asleep: asleep or a shadow's owner -> `crowd.take(p, &"dreamt")` at once; the dead and anyone gone indoors are skipped; the rest sit deep asleep with `statuses[&"dreamless"]`. A sitter who is woken meanwhile (a hurt wakes a deep sleeper) is not killed at the end: the 20 s rest only kills those still sleeping it. Teardown (`_finish`, `_exit_tree`) lifts the status and wakes the sitters; once the kill has run nothing is left to undo.
- VB2 (Task 7): The walk to the wall is the person's own goal at the cast (`set_goal`), and at T_SIT the last steps are settled by placing him at the spot (nearest standing, non-walkable structure within 2.0, 0.3 off its footprint, on open ground, at most 2.0 from where he stood); with no such wall he sits where he stands. Dreamless lays its dusk at the cast (V21), radius its reach (floored at the dusk radius), and does not ask `Crowd.spared()`: the god's own chosen victims are taken as Silent Doom's are; only Evernight's automatic takes pass the kept by.
- VB3 (Task 9): Shadow Play's shadow is the person node itself, not a second body: `statuses[&"shadow"]` (its value the casting effect's instance id) and a flat BLACK `self_modulate` with a SILVER edge drawn behind; the person keeps walking with his own goal, post and mind, so posts stay held and every director counts him, and the Task 2 hooks make him see, report, shout, fight, chase and seize nothing. Who becomes a shadow is decided at T_RISE (the living in the open within 3.0 / 6.0, nearest first, then instance id). A later cast on a shadow takes it over (the value becomes its id); an earlier cast's end or teardown lifts only shadows whose value is still its own. Dusk is laid at the cast with the power's radius (V21); `busy = T_RISE` (C16).
- VB4 (Task 9): Shadow Play's end. Light: each shadow lies down where it stopped with `Person.knock_down(LIE 1.5, true)` -- a lie that does not touch the mind, so a guard is still POST and a citizen still CALM -- and the status and look are lifted. Dark: the soldiers are taken with `crowd.take(p, &"shade")` (C12), not asked `Crowd.spared()` (the god's own chosen, as VB2); the citizens lie down and wake as in the light. Anyone dead or taken meanwhile (Dreamless takes a shadow's owner with `&"dreamt"`) is let go at once and skipped at the end. Teardown (`_finish`, `_exit_tree`) lifts every status this cast still holds and gives every look back; it takes nobody.
