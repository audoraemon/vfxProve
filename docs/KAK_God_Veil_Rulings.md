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
- V16 (amended by ruling C13): one read, `Person.veil_blind()` (a shadow or the dreaded; `statuses.is_empty()` first), says a person
  sees, seizes, finds, reports and delivers nothing. Read at: `Crowd.nearest_witness()` and `TempleReport._witness()` (no witness);
  `MissionDirector._sees()` (no Faithful sight) and `_report()` (no report sent); `TempleReport.step()` (no report delivered);
  `EscortDirector._seen_by()` (no seizure) and `_step_held()` (no charge handed over: the whole Escort family); the Harvest's called
  guard; `HuntDirector._found()` (the head finds nothing; Heretic Hunt and its kin inherit it); Break the Hunt's bearers (no house
  taken); `WarningDirector._run()` (no keeper told, no rope taken) and `_herald_tick()` (the Lantern hears nothing); the Witness's
  messenger (word does not reach the Temple); `LanternBearer.step()` (no flame brought to the vigil); `Person.on_watch()` (no watch kept:
  Heretic Hunt's, The Informer's and Heart of Faith's quiet doors), while `at_own_post()` still counts his post held; `BellNetwork`
  (no ring); `Crowd._voice()` (no shout); `Person.panic/observe/flee/fight` and `_fight_step()`; the walk: `Person.tick()` holds a
  dreaded non-shadow still, and `Person._step_blocked()` refuses a step from outside into dreaded ground.
- V21 (ruling C13's sweep): left unread on purpose -- The Informer's `_found()` (the god's turning of the contacts finds him, no
  person's act), The Lantern's Eye's `_found()` (the mirrors' Eye, no person), Break the Hunt's `_found()` (counts the houses taken,
  which a shadow bearer no longer takes), Face Halcyon's burn (the stake's clock; a shadowed escort keeps his place in the file, as
  spec 5.8 counts a shadow's post held), Mira's House Venn's knock (his search reports through `_report()`, which is read), and the
  director-placed and town-placed stands (`GuardJobs`, `at_own_post()`): the post looks manned.
- V17: `Crowd.take()` hides the taken at once (`visible = false`): no body is drawn; the power draws its own vanishing.
- V18: `Crowd.spared()` asks the director through `Crowd.mission_keeps` (registered in `MissionDirector.setup()` beside
  `mission_holds`, cleared with the mission hooks).
- V19: `LightField.mute(share)` touches only the static lights the field held when the muting began (a call with no muting on);
  lights added after it -- Evernight's torches -- are never muted, and `mute(1.0)` gives every muted light back as made and ends the
  muting.
- V20: `Rules.haste` is read per slot by `advance()` only while it is non-empty, and never for a slot whose `cooldown_of()` is 999 or
  more (`Rules.ONCE_COOLDOWN`); with no haste the cooldown arithmetic is exactly as before.
- VB0 (Task 5; was V21 in the track): Slumber lays its dusk at the cast (in _build), not when the hush lands at T_FALL -- test_veil_law (not this task's file) checks that every Veil effect lays its dusk at once, and the dusk only shortens sight; the sleep itself is at T_FALL.
- VB1 (Task 7): Dreamless fixes its victims at the cast (`victims_at(field, at, r, most)`: reach and count from VeilRules, nearest first, then instance id) and decides at T_SIT, not at the cast, who is already asleep: asleep or a shadow's owner -> `crowd.take(p, &"dreamt")` at once; the dead and anyone gone indoors are skipped; the rest sit deep asleep with `statuses[&"dreamless"]`. A sitter who is woken meanwhile (a hurt wakes a deep sleeper) is not killed at the end: the 20 s rest only kills those still sleeping it. Teardown (`_finish`, `_exit_tree`) lifts the status and wakes the sitters; once the kill has run nothing is left to undo.
- VB2 (Task 7): The walk to the wall is the person's own goal at the cast (`set_goal`), and at T_SIT the last steps are settled by placing him at the spot (nearest standing, non-walkable structure within 2.0, 0.3 off its footprint, on open ground, at most 2.0 from where he stood); with no such wall he sits where he stands. Dreamless lays its dusk at the cast (V21), radius its reach (floored at the dusk radius), and does not ask `Crowd.spared()`: the god's own chosen victims are taken as Silent Doom's are; only Evernight's automatic takes pass the kept by.
- VB3 (Task 9): Shadow Play's shadow is the person node itself, not a second body: `statuses[&"shadow"]` (its value the casting effect's instance id) and a flat BLACK `self_modulate` with a SILVER edge drawn behind; the person keeps walking with his own goal, post and mind, so posts stay held and every director counts him, and the Task 2 hooks make him see, report, shout, fight, chase and seize nothing. Who becomes a shadow is decided at T_RISE (the living in the open within 3.0 / 6.0, nearest first, then instance id). A later cast on a shadow takes it over (the value becomes its id); an earlier cast's end or teardown lifts only shadows whose value is still its own. Dusk is laid at the cast with the power's radius (V21); `busy = T_RISE` (C16).
- VB4 (Task 9): Shadow Play's end. Light: each shadow lies down where it stopped with `Person.knock_down(LIE 1.5, true)` -- a lie that does not touch the mind, so a guard is still POST and a citizen still CALM -- and the status and look are lifted. Dark: the soldiers are taken with `crowd.take(p, &"shade")` (C12), not asked `Crowd.spared()` (the god's own chosen, as VB2); the citizens lie down and wake as in the light. Anyone dead or taken meanwhile (Dreamless takes a shadow's owner with `&"dreamt"`) is let go at once and skipped at the end. Teardown (`_finish`, `_exit_tree`) lifts every status this cast still holds and gives every look back; it takes nobody.
- VC1: Dread of the Dark lays its dusk (VeilRules.DUSK_R at the click) when the dread lifts (at T_FALL + HOLD, or when cut short),
  not at the cast -- Crowd.dreaded() reads the dark live, so a patch laid at the cast would itself be dark ground in reach: every
  Dread would freeze its own click circle and "no dark ground in reach: refused" (spec 5.7) would mean nothing. The Swallowing Dark
  likewise lays its dusk at the end (C14). A Dread freed outside the tree lays none (the world may be going).
- VC2: who the Dread holds is read every frame while it lasts: the living out of doors within reach on dark ground, not a shadow,
  and not a sleeper it did not already hold. So one whose dark fades under him (a dusk patch running out) goes free, one who wakes
  inside freezes then (asleep beats frozen; "a sleeper is not frozen again" while he sleeps), and one a new patch covers freezes.
  Each person keeps the casts holding him as meta `dread_owners` ({instance id: true}); the status comes off with the last.
- VC3: DreadOfTheDarkFx.refusal() reads Dusk._patches and Crowd._veils (read only) to find a patch or veil reaching into the light
  reach: the ledgers have no public walk over their circles, and sampling points would miss a thin overlap. With no crowd it allows
  the cast (nothing to judge: the VFX Sandbox has no Rules either).
- VC4: Dread's `busy` is T_FALL (as Unseen Hour's): the other slots unlock once it falls, so Dreamless, Silent Doom and the
  Swallowing Dark can be cast into it (spec 5.7: it "sets them up").
- VC5: Cloak of Night's `marked_at` skips people indoors (`Person.inside`), as Corpse Guise's does: the watch's sight is out of doors, a
  person inside the nearest to the click is not spent on one of the 3 / 8 places, and the next one out of doors is marked instead.
- VC6: Cloak of Night's `busy` is T_LAND (0.5 s; ruling C16): the other slots unlock once it has landed while the cloak runs its 25 s.
- VC7: Evernight lays no dusk patch of its own (C14: it uses `dusk.everywhere`): the whole town is its dark while it lasts, and a patch
  at the click would only put out the torches near it. Its night's rules (the dark, the town-wide veil, the haste, the sight) hold from
  the end of the wave (WAVE) to the start of the dawn (WAVE + 60 / 90); the dawn's takes run at that moment, the torches are put away
  then (nobody taken) and the bearers sent back to their posts; the look (ambient, tint, lamp mute, the wash) eases back over DAWN.
- VC8: Evernight's ambient is eased as a share of what the light field holds each frame (the night's 0.86 of it), not set: the
  Battlefield writes `LightField.ambient` afresh every frame (its dim), so a set value would be lost and a saved one would undo the dim.
  The town-wide state is kept in owner ledgers (crowd meta `evernight_night`, light-field meta `evernight_look`): the first owner saves
  the town as it was, only the lowest-id owner eases the look, the last owner puts everything back (two casts never undo each other).
- VC9: Evernight's torch is fixed where its bearer stood at nightfall (he is posted there); "a Veil cast whose area touches a torch" is
  read as a dusk patch laid over its light (`Dusk.laid`, centre distance <= patch r + TORCH_R): every Veil cast leaves its dusk where
  it lands. The dawn's takes, like the lone's and a torch's, pass over the spared (`Crowd.spared()`). Citizens called to a torch are the
  calm, awake ones out of doors (`walk_to` a huddle slot inside TORCH_R, nearest first, ties by instance id).
- VC10: Evernight bench (Task 11 Step 5; Aldermere mission, `--loadout=evernight` against `--bench-cast=evernight --bench-after=4`, three
  alternating pairs on a loaded machine): avg_ms 15.75 / 18.88, 15.58 / 18.68, 15.71 / 18.77, cast/base 1.199, 1.199, 1.195: median
  1.20 (bar 1.55). Worst frame of the cast runs 31.03, 25.21, 54.23 ms (base 35.92, 43.64, 42.39).
- VA1 (Task 4): a blighted building's "light" is its pool in the town's light map: `TownPools.dim(<the structure's instance id>,
  footprint.end, BlightFx.LIGHT_R, 1.0)` puts its window pool out (drawing only, the registry Pale Serpent uses) and `undim()` gives it
  back when the foothold heals; `BlightFx.lit(s)` reads it. The sprite's painted windows are left as drawn (the rot tint covers them).
  Why: houses register no LightField light, and the task may edit only its effect file.
- VA2 (Task 4): a Blight "building" is a standing, untaken, unblighted structure that has a use (`blightable()`, as today) or walls and
  windows (`Structure.WINDOWED`). One with no use is rotted by `Structure.set_blighted(true)`, not `EnvironmentField.blight()`, so
  `structure_blighted` is not sent: `Mission.blight_banner()` would name a house "THE FOUNTAIN" and nothing in the town reads a house's
  use. Healing goes through `EnvironmentField.unblight()` for both.
- VA3 (Task 4): a foothold keeps its lasting dusk patch's id on its structure (meta `blight_foothold`, with the ledger's instance id so
  a patch of an earlier ledger is never ended). A gate's 30 s jam still frees it (`Crowd._free_jams()`), but its foothold (dusk, light)
  stays until the cap heals it; Blight on a gate that is already a foothold jams it again and plants no second foothold.
- VA4 (Task 4): who falls ill is fixed at the cast (the picked person, then in the dark the nearest others within ILL_REACH of them, by
  distance then instance id) and made ill at T_ROT; the picked person dead by then: nobody. A cast on a person or a director's thing
  leaves the usual 20 s dusk patch (VeilParts.land); a building's lasting patch is its only one.
- VA5 (Task 10): The Swallowing Dark spares, besides what `MissionKeeps.spared()` names (the Citadel and Temple, the hallowed, a damage
  filter, the director's `reserved_places` and `needs_standing()`), the town's own gates, bridges, postern, dock and fountain, as Eminent
  Domain's `_clear_ruins()` keeps them -- the town's managers go on using them (evacuation, the river's crossings) and a bridge taken out
  of the walk grid would close the river. A ruin wholly inside is taken like a standing building (no rubble is left either way).
- VA6 (Task 10): who is "inside" is fixed at full size: every living person whose point lies within the full radius -- out in the open,
  or indoors at home (a NIGHT mission's citizens, the home-sick) -- plus every animal and visitor, every lying remain (its corpse hidden)
  and every decor piece whose `at` is inside. One sheltering in a shelter is taken only with his building (released, then taken) and is
  out of reach in a standing one. Each person is checked again when his turn comes: one who has walked out by then lives.
- VA7 (Task 10): a blighted foothold (`Crowd.footholds`) the dark takes is healed first (`BlightFx.heal()`: its lasting dusk ended, its
  light-map pool given back, unblighted, dropped from `Crowd.footholds`), then removed, so no foothold ever points at a removed building;
  the emptied ground carries the swallow's own 20 s dusk instead.
- VA8 (Task 10): the circle grows from the cast (radius `start_r` at t = 0) and `busy = T_OPEN` (0.5 s, the rim fading in), so the other
  slots unlock while it grows (C16). In the dark with no patch under the click (a NIGHT mission, the veil) it starts at 0. The removals go
  outermost first (an inward fold), then by instance id, PER_FRAME a frame, of which at most BUILDINGS_PER_FRAME (2) buildings (VA9);
  the effect stays up until the last is made. Ended or freed
  before full size it takes nothing and lays no dusk; ended after, the removals not yet made are dropped. No cast sound here (Task 12's
  cues): the fold is soundless. The bare dark earth is a node left on `ctx.ground` (not tracked), freed with the mission's ground layer.
- VA9 (Task 10): bench (`--bench --loadout=swallow` against `--bench-cast=swallow --bench-after=4`, the market square, light: r 10;
  machine loaded by other sessions). avg_ms base / cast: 16.22 / 16.11, 15.56 / 15.91, 15.87 / 16.37; ratios 0.993, 1.022, 1.032;
  median 1.02 (bar 1.55). Worst frame in those cast windows (t 4-13 s, the growing disc): 34.1 ms (bases 33.8-39.9). The fold itself
  (`--bench-after=17`, t 17-26 s: full size at 20 s, 75 buildings and about 390 removals): worst 92.3 ms with only PER_FRAME; each
  `EnvironmentField.remove()` rebuilds the field's whole spatial index (`_reindex()`, about 10 ms a building here, measured), so
  BUILDINGS_PER_FRAME = 2 caps it: worst 56.4 / 59.5 ms (one a frame: 50.2 ms, and the fold takes 2.8 s), and the fold there takes about
  1.9 s, not 1 s (the suite's own site finishes within 1 s). Under 50 ms needs one index rebuild per frame for several buildings, a batch
  remove in environment_field.gd (not this task's file).
- VA10 (Task 10b, C19 item 1): `EnvironmentField.remove(s, announce, keep_node, reindex := true)`. The default (true) is today's path
  unchanged (a full `_reindex()`). `reindex = false` strikes `s` from just the index cells its footprint covers (`_unindex()`, before any
  free; an emptied cell is dropped; `layout_epoch` bumped), so the deferred index is never stale: it is what a full rebuild without `s`
  gives, read at any point of the batch (exact because a footprint never changes once indexed and walkability changes are followed
  by `reindex()`, town.gd's postern). The caller ends a batch with one `reindex()`. The Swallowing Dark removes its buildings that
  way and calls `reindex()` once, when its queue is empty; PER_FRAME 12 -> 24, BUILDINGS_PER_FRAME 2 -> 8. Per building: 7-14 ms ->
  about 0.45 ms (headless, market square); one rebuild 6-9 ms. Test town, market square (75 buildings, 364 removals): the fold
  takes 40 -> 15 frames (within 1 s even at 30 fps). Game bench (`--bench --loadout=swallow --bench-cast=swallow --bench-after=17`,
  t 17-26 s, the fold; machine loaded): worst frame 60.3 ms before, 39.9 / 37.0 ms after, against 36.9 / 35.9 ms in the same
  session's runs without the cast.
- VD1 (Task 12): the Veil's seven new powers cast with `v_<key>` (the brief's names: v_slumber, v_cloak, v_dreamless, v_dread,
  v_shadowplay, v_swallow, v_evernight), not the `q_<key>` every other quiet power has; tests/test_power_sounds.gd's own-cue rule
  (`own_cue()`) reads `v_` for those seven and checks that no two q_ or v_ cues share a file. PENDING_QUIET (V10) is empty. The
  cues are quiet, low and close (a breath, cloth, a held low note, a lamp guttering): each plays within 3 LU over the quiet floor
  (VEIL_BAND), Evernight's held night (`v_evernight_loop`) under its cast and faded out at the end of the night, and no Veil cue
  ducks the music or calls an aftermath -- a sound only, never a danger or a fright.
- VD2 (Task 12): the Veil's clips are recorded in the town (`tools/dev/behaviour_check.gd --scenario=clip`, as Unseen Hour's and the
  other quiet powers' were), not by `tools/capture.sh --capture-clip`: the sandbox has no crowd, so Slumber, Cloak, Dreamless, Dread
  and Shadow Play would show nobody, and Dread with no crowd builds nothing. The clip scenario instantiates mission.tscn on its own and
  reads and writes no save file (no user:// file at all). Dread is refused with no dark in reach, so the clip scenario gets one more
  setup, `--setup=dusk` (a dusk patch 3.5 east of the cast, the cast itself on lit ground); a dev tool change, reachable only by that
  flag. Commands: slumber --seconds=4; cloak --seconds=6; dreamless (its run); dread --setup=dusk --seconds=10 --zoom=0.8
  --look=2.5,0; shadowplay --seconds=8; swallow --zoom=0.4 --seconds=24 (past the fold); evernight --seconds=15 --zoom=0.8.
- VD3 (Task 12): test_draft's AWAITING_CLIPS (V1) is empty: every power has its preview clip. The seven flat placeholder icons
  were already made in Task 1 (`tools/dev/make_power_icons.py` veil_glyph); Task 12 leaves them as they are.
