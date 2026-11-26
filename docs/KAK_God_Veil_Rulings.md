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
  keys (and a check that a key leaves the list once its clip exists) -- the clips are Task 12's; Task 12 empties the list. (Done: the
  list is empty, VD3.)
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
  without their q_<key> cue) and counts 48 quiet powers: their sounds are Task 12's, which takes each key off the list. (Done: the
  list is empty and the seven cast with `v_<key>`, VD1; the count of 48 stands.)
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
- V17: `Crowd.take()` hides the taken at once (`visible = false`): no body is drawn; the power draws its own vanishing.
- V18: `Crowd.spared()` asks the director through `Crowd.mission_keeps` (registered in `MissionDirector.setup()` beside
  `mission_holds`, cleared with the mission hooks).
- V19: `LightField.mute(share)` touches only the static lights the field held when the muting began (a call with no muting on);
  lights added after it -- Evernight's torches -- are never muted, and `mute(1.0)` gives every muted light back as made and ends the
  muting.
- V20: `Rules.haste` is read per slot by `advance()` only while it is non-empty, and never for a slot whose `cooldown_of()` is 999 or
  more (`Rules.ONCE_COOLDOWN`); with no haste the cooldown arithmetic is exactly as before.
- V21 (ruling C13's sweep): left unread on purpose -- The Informer's `_found()` (the god's turning of the contacts finds him, no
  person's act), The Lantern's Eye's `_found()` (the mirrors' Eye, no person), Break the Hunt's `_found()` (counts the houses taken,
  which a shadow bearer no longer takes), Face Halcyon's burn (the stake's clock; a shadowed escort keeps his place in the file, as
  spec 5.8 counts a shadow's post held), Mira's House Venn's knock (his search reports through `_report()`, which is read), and the
  director-placed and town-placed stands (`GuardJobs`, `at_own_post()`): the post looks manned.
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
  cues): the fold is soundless. The bare dark earth is a node left on `ctx.ground` (not tracked) in the lasting-effects group
  (`SolarisPit.GROUP`, "fx_lasting"), so `Battlefield.clear_effects()` frees it on a restart as it frees Solaris's pit (VG2; the
  ground plane itself is the Battlefield's and outlives the mission).
- VA9 (Task 10): bench (`--bench --loadout=swallow` against `--bench-cast=swallow --bench-after=4`, the market square, light: r 10;
  machine loaded by other sessions). avg_ms base / cast: 16.22 / 16.11, 15.56 / 15.91, 15.87 / 16.37; ratios 0.993, 1.022, 1.032;
  median 1.02 (bar 1.55). Worst frame in those cast windows (t 4-13 s, the growing disc): 34.1 ms (bases 33.8-39.9). The fold itself
  (`--bench-after=17`, t 17-26 s: full size at 20 s, 75 buildings and about 390 removals): worst 92.3 ms with only PER_FRAME; each
  `EnvironmentField.remove()` rebuilds the field's whole spatial index (`_reindex()`, about 10 ms a building here, measured), so
  BUILDINGS_PER_FRAME = 2 caps it: worst 56.4 / 59.5 ms (one a frame: 50.2 ms, and the fold takes 2.8 s), and the fold there takes about
  1.9 s, not 1 s (the suite's own site finishes within 1 s). Under 50 ms needs one index rebuild per frame for several buildings, a batch
  remove in environment_field.gd (not this task's file). (Done in Task 10b: VA10 replaces BUILDINGS_PER_FRAME 2 and these numbers.)
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
- VB0 (Task 5; was V21 in the track): Slumber lays its dusk at the cast (in _build), not when the hush lands at T_FALL -- the dusk only
  shortens sight; the sleep itself is at T_FALL. (Written when test_veil_law's `_stubs` still checked every Veil effect's dusk at the cast;
  ruling C14 dropped that check, each power's own suite says when its dusk lands, and Slumber's stays at the cast.)
- VB1 (Task 7): Dreamless fixes its victims at the cast (`victims_at(field, at, r, most)`: reach and count from VeilRules, nearest first, then instance id) and decides at T_SIT, not at the cast, who is already asleep: asleep or a shadow's owner -> `crowd.take(p, &"dreamt")` at once; the dead and anyone gone indoors are skipped; the rest sit deep asleep with `statuses[&"dreamless"]`. A sitter who is woken meanwhile (a hurt wakes a deep sleeper) is not killed at the end: the 20 s rest only kills those still sleeping it. Teardown (`_finish`, `_exit_tree`) lifts the status and wakes the sitters; once the kill has run nothing is left to undo.
- VB2 (Task 7): The walk to the wall is the person's own goal at the cast (`set_goal`), and at T_SIT the last steps are settled by placing him at the spot (nearest standing, non-walkable structure within 2.0, 0.3 off its footprint, on open ground, at most 2.0 from where he stood); with no such wall he sits where he stands. Dreamless lays its dusk at the cast (V21), radius its reach (floored at the dusk radius), and does not ask `Crowd.spared()`: the god's own chosen victims are taken as Silent Doom's are; only Evernight's automatic takes pass the kept by.
- VB3 (Task 9): Shadow Play's shadow is the person node itself, not a second body: `statuses[&"shadow"]` (its value the casting effect's instance id) and a flat BLACK `self_modulate` with a SILVER edge drawn behind; the person keeps walking with his own goal, post and mind, so posts stay held and every director counts him, and the Task 2 hooks make him see, report, shout, fight, chase and seize nothing. Who becomes a shadow is decided at T_RISE (the living in the open within 3.0 / 6.0, nearest first, then instance id). A later cast on a shadow takes it over (the value becomes its id); an earlier cast's end or teardown lifts only shadows whose value is still its own. Dusk is laid at the cast with the power's radius (V21); `busy = T_RISE` (C16).
- VB4 (Task 9): Shadow Play's end. Light: each shadow lies down where it stopped with `Person.knock_down(LIE 1.5, true)` -- a lie that does not touch the mind, so a guard is still POST and a citizen still CALM -- and the status and look are lifted. Dark: the soldiers are taken with `crowd.take(p, &"shade")` (C12), not asked `Crowd.spared()` (the god's own chosen, as VB2); the citizens lie down and wake as in the light. Anyone dead or taken meanwhile (Dreamless takes a shadow's owner with `&"dreamt"`) is let go at once and skipped at the end. Teardown (`_finish`, `_exit_tree`) lifts every status this cast still holds and gives every look back; it takes nobody.
- VC1: Dread of the Dark lays its dusk (VeilRules.DUSK_R at the click) when the dread lifts (at T_FALL + HOLD, or when cut short),
  not at the cast -- Crowd.dreaded() reads the dark live, so a patch laid at the cast would itself be dark ground in reach: every
  Dread would freeze its own click circle and "no dark ground in reach: refused" (spec 5.7) would mean nothing. The Swallowing Dark
  likewise lays its dusk at the end (C14). A Dread freed outside the tree lays none (the world may be going).
  Amended (final fix wave, VG6): only a Dread that runs its course lays its dusk, when it lifts at T_FALL + HOLD. One ended before
  that (end_now(), an act change through Battlefield.end_powers(), a freed node) lets everyone go and lays none: "or when cut short"
  above no longer holds.
- VC2: who the Dread holds is read every frame while it lasts: the living out of doors within reach on dark ground, not a shadow,
  and not a sleeper it did not already hold. So one whose dark fades under him (a dusk patch running out) goes free, one who wakes
  inside freezes then (asleep beats frozen; "a sleeper is not frozen again" while he sleeps), and one a new patch covers freezes.
  Each person keeps the casts holding him as meta `dread_owners` ({instance id: true}); the status comes off with the last.
- VC3: DreadOfTheDarkFx.refusal() reads Dusk._patches and Crowd._veils (read only) to find a patch or veil reaching into the light
  reach: the ledgers have no public walk over their circles, and sampling points would miss a thin overlap. With no crowd it allows
  the cast (nothing to judge: the VFX Sandbox has no Rules either).
  Note (Task 13c, VF3): the private reads are gone; the refusal uses Dusk.reaches() and Crowd.veil_reaches().
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
  it lands. The dawn's takes, like the lone's and a torch's, pass over the spared (`Crowd.spared()`); sleepers indoors are passed over
  at dawn (only one sheltering in a blighted building is taken indoors). Citizens called to a torch are the
  calm, awake ones out of doors (`walk_to` a huddle slot inside TORCH_R, nearest first, ties by instance id).
- VC10: Evernight bench (Task 11 Step 5; Aldermere mission, `--loadout=evernight` against `--bench-cast=evernight --bench-after=4`, three
  alternating pairs on a loaded machine): avg_ms 15.75 / 18.88, 15.58 / 18.68, 15.71 / 18.77, cast/base 1.199, 1.199, 1.195: median
  1.20 (bar 1.55). Worst frame of the cast runs 31.03, 25.21, 54.23 ms (base 35.92, 43.64, 42.39).
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

## Task 13a: the Veil's Tier 1 nights and Hunts (VE)

- VE1 (Task 13a): a Veil bot sizes a Silent Doom by the ground under its aim, as the cast will: `GOD_T1.doom_r(crowd, at)`
  (tools/dev/routes/god_t1.gd: `VeilRules.size("doom", "RADIUS", crowd.in_dark(at))`, the question Rules.cast() stamps), and
  behaviour_check's `_doom_unseen()` takes the reach as an optional last argument (default `SilentDoom.RADIUS`: every other caller is
  unchanged). First Prayers' `_doom_aim()` counts its victims and its witnesses at that reach, so a Doom laid on an earlier Doom's dusk
  (full size, 1.6) is never thought to take only the Faithful when it would take a bystander too. On its own it moved no gate run
  (seed 1's checksum was the same); it is kept because the light count is wrong in the dark.
- VE2 (Task 13a): First Prayers x Veil failed on idle (`gate prayers route=god:veil wins=3/3 median=116 idle_max=46 FAIL`; seed 1
  116.5 s, idle 46: the last Faithful fell at 70.7 s and the poor took 46 s to go in). The cause is the dusk alone: seed 1 with the
  ledger switched off (a local experiment, not committed) gave the reference row's own checksum (-901602410, 93.7 s, idle 39). In the
  dusk the Dooms leave, more of them go unseen; an unseen death frightens nobody, so the street stays full round the Faithful, and
  the policy, which Dooms a Faithful only when nobody else stands in its reach, waited 10-19 s for each clean shot (22.2 -> 41.6,
  53.3 -> 70.7). Fix in the bot, with the law: Blight now has a use here. When Doom is ready but every Faithful has someone else in its
  reach, Blight sends that one home sick (`_blight_blocker()`: the only other person within the Doom's reach of a Faithful, the nearest
  the door first, on lit ground so Blight takes him alone, not one of the grieving, and one Blight's own pick takes), and a later look
  Dooms the Faithful alone. After: `gate prayers route=god:veil none_lost=- wins=3/3 median=118 idle_max=39 PASS`. Tried and dropped:
  Blight on a Faithful (he lives on, sick at home, and while a Faithful lives the poor do not hurry in: seed 1 won at 224 s, idle 182);
  a foothold over the shrine's door (it is a well shrine, and no plain house stands within 2.5 of its door).
- VE3 (Task 13a, fix round 1): Hide the Faithful (Hunt 1) x Veil fell from 3/3 (140 / 126 / 182 s, idle 45,
  docs/KAK_God_P5_Summary.md) to `gate hide_faithful route=god:veil none_lost=- wins=1/3 median=128 idle_max=57 FAIL` (seed 1 lost
  at 103.5 s, seed 2 at 184.4 s). The cause is the dusk alone: seed 1 with the ledger switched off (local experiment) gave its
  reference row's checksum (-802237474, won at 106.9 s). With it, the Doom on a patrol's seizer at 59.5 s was cast on the dusk an
  earlier Doom left, so it was full size (1.6) and took the marched believer with his seizer; the policy measured the believer's room
  with the light reach. What stands in the bot: every Veil Doom here is sized by the ground under its aim (`GOD_T1.doom_r()`, VE1)
  for the believers' room (`_seizer_aim`, `_flock_clear`) and for who it takes (`_doom_ok`'s `r`), and `_doom_ok` judges a death in
  the dusk as seen from 0.6 as far (NightRules.NIGHT_SIGHT). No believer is lost now, but the gate fails on idle:
  `gate hide_faithful route=god:veil none_lost=- wins=3/3 median=205 idle_max=80 FAIL` (205.6 s idle 80, 204.6 s idle 57,
  127.7 s idle 44). The wait is the night's own: once the first household is done the policy has no watcher in its Doom's lead, and
  the second household sets out only on the chain or at 2:20, not on a broken watch. Likely why the old night broke its watch early
  (inferred, not measured: the reference run cast only four Dooms by 60 s, fewer than the watch's eight soldiers, yet the second
  household set out about then): its seen deaths raised the alarm and the watch rallied to the Citadel, which counts as broken
  (P5-T17-R1); in the dusk the same Dooms go unseen, so nothing rallies. **Gate stopped here (not forced):** Hunt 1 x Veil misses the
  45 s idle bar. Passing it needs a change to the Hunt (its pacing: P5 summary's "the empty stretch is the shape of the night") or a
  Veil play this task did not find; that is the user's call.
  Withdrawn in fix round 1: a "break the watch" Doom (once the first household was out and nothing was to answer, Doom a watchman so
  watch_broken() sets the second household out). It made the gate pass (idle 44), but it is the idle lead P5-T17-R3 retired: a kill
  that answers no watcher in its power's lead. tests/test_hide_faithful.gd's idle night did not see it only because its spy never
  rots the Bell Tower, so every Veil look went to Blight; the idle night now starts with the tower blighted for Veil, and with the
  branch in place it fails (`FAIL: veil: on the idle night, with the watch 60 s from its sight, it casts nothing (6 casts)`).
- VE4 (Task 13a, ruling C9): the four other Veil Hunts, gated with the loadout Task 2 left (doom, blight, slumber), win as they are,
  so nothing in their bots changes but stale comments. Before this build (docs/KAK_God_P5_Summary.md, the third key then Tsunami
  Breaker or Nuclear Nova) and now:
  Silence the witness 3/3, 193 s, idle 44 -> `gate silence_witness route=god:veil none_lost=- wins=3/3 median=206 idle_max=45 PASS`
  (its policy casts Slumber over the file where Nova fell, C9; seed 2 cast it once, at 86.5 s);
  Expel the inquisitor 3/3, 181 s, idle 39 -> `gate expel_inquisitor route=god:veil none_lost=- wins=3/3 median=181 idle_max=39 PASS`;
  Break the hunt 3/3, 177 s, idle 24 -> `gate break_hunt route=god:veil none_lost=- wins=3/3 median=177 idle_max=24 PASS`;
  Face Halcyon 3/3, 196 s, idle 45 -> `gate face_halcyon route=god:veil none_lost=- wins=3/3 median=196 idle_max=45 PASS`.
  Expel, Break and Face win with Silent Doom and Blight alone (their policies never cast a third key, before or now); Slumber stays
  drafted in their LOADOUT, as Task 2 left it, so the loadout the reference rows and test_hunt_tools' PLAYS name does not move. Their
  Dooms are still measured with the light reach and their gates lost no one by it; were a believer ever to fall with an escort
  there, VE1's `doom_r()` is the fix, as in Hunt 1.
- VF1 (Task 13c): the VFX Sandbox's number keys reach only the first seven entries of a set, so entries 8 and up of Set2 were never
  pickable. The Veil gets its own "Set4 Veil" (values of Set2) holding the ten powers in tree order on the keys 1-9 and 0 (the HUD
  numbers the tenth 0); Silent Doom and Blight left Set2 for it. The widened key handler (keys 1-9 and 0) is every set's: keys 8, 9
  and 0 now also pick the entries 8-10 of a set that has them, Set2's entries 8-10 among them (corrected in the final fix wave: this
  line once said no other set's picking changed). The Sandbox shows the light size only
  (C10). CAPTURES gets no entry for the new keys (a missing entry is skipped, not an error).
- VF2 (Task 13c): the HUD shape lines of Silent Doom (VeilRules doom RADIUS 0.8 / 1.6), Blight (blight DUSK_R 3 / 5, BLIGHT_MAX 3,
  PICK 0.5, ILL_REACH 2 with ILL_MOST 1 / 3) and Unseen Hour (RADIUS 5 / 7, VEIL_TIME 20 / 30) give both sizes, as the seven new
  powers' do. Blight's blurb now says what the rework does (a building rots, a person is sickened).
- VF3 (Task 13c): VC3's private reads are gone: Dread's refusal asks Dusk.reaches(at, r) and Crowd.veil_reaches(at, r), and Shadow
  Play's edge asks Person.silhouette_src(). Nothing outside src/game/crowd reads _patches, _veils or _design_info.

## Final fix wave (VG; controller ruling C23)
- VG1 (Critical 1): The Swallowing Dark never takes a building the night wants down (`director.wants_down(s)`): `_inside()` skips it
  beside `MissionKeeps.spared()`. MissionKeeps lets a power that destroys fell such a building (a fall there is the god's work), but
  the dark only takes it (`EnvironmentField.remove(..)` sets `taken`, never `destroyed`), and the directors raze only a destroyed or
  freed target: a swallowed granary, refuge, shrine, standard, stocks or Citadel would leave the night unwinnable. Spec 5.9's "a
  mission's own object" is read as both: what the mission keeps and what it wants down.
- VG2 (Critical 2): The Swallowing Dark's `BareEarth` joins `SolarisPit.GROUP` ("fx_lasting") in its `_init()`, so
  `Battlefield.clear_effects()` frees it on a restart (R, the Sandbox's R/TAB). VA8 is corrected to match.
- VG3 (Critical 3): Blight passes over everyone `Crowd.spared()` names (the god's BELIEVER and every director's `keeps_alive`), in the
  pick (`_nearest_person()`) and when the sick are made (`_make_ill()`): a click on a kept charge takes the next thing in Blight's order
  (or is refused "no_blight" with nothing else there), and the dark's others are the next nearest. No rng: distance, then instance id.
- VG4 (Important 1): Turncoat (Dominion) keeps its alarm: it adds `Crowd.BLIGHT_ALARM` itself right after its
  `EnvironmentField.blight()` (a null crowd guarded). `Crowd._on_blighted()` stays alarm-free, as spec 11.1 wants for Blight; before
  the Veil rework that handler raised the alarm for every blight, Turncoat's included, so Turncoat's own effect now does what the
  handler did for it. No reference row casts Turncoat.
- VG5 (Important 2; ruling C23): Evernight's dawn lets a shelterer out of his shelter before it takes him, with the one release The
  Swallowing Dark uses, now written once as `VeilParts.take_out(crowd, p, kind)` (`ShelterManager.release()`, a no-op for one not
  sheltering, then `Crowd.take()`). `Crowd.take()` is not changed: every power's kills pass through it. A shelter's later flush can
  no longer set a taken person visible and put him back in the field.
- VG6 (Important 3): a Dread ended before T_FALL + HOLD releases its hold and lays no dusk (VC1 amended). At an act change
  `Battlefield.end_powers()` ends effects in cast order, and a Dread's dusk laid there would put out a running Evernight's torches
  and take their huddles in teardown.
- VG7 (minors, C23): Evernight's dawn treats a shadow's owner as asleep (`is_asleep() or is_shadow()`, spec 5.8: "the owner counts as
  asleep"), out of doors in a dusk patch only, as any sleeper. `bearers()` and `_call_to_torches()` pass over anyone
  `Crowd.held_by_mission()` names (the `mission_holds` hooks): a seizer keeps his charge, a mission's citizen keeps his errand.
  `loneliest()` passes over one `Crowd.take()` cannot take: take() goes through `Person.die()`, which asks `Person.deathless` (Corpse
  Guise, level 5); calling that hook spends the guise, so the read is "has a hook" (`EvernightFx.takeable()`); he still counts as
  someone's neighbour.
- VG8 (minors, C23): Dreamless lets a sitter go the frame he is awake again (a hurt wakes a deep sleeper): `statuses[&"dreamless"]` is
  erased and he leaves the sitters, so a later deep sleep (a dark Slumber) is a plain sleep and the find does not kill him (VB1).
- VG9 (minors, C23; spec section 6): Evernight's wash draws a pale moon in code (no art file): a child node "Moon" of the wash, upright
  on screen at a fixed share of the map (MOON_AT, near its top corner), a faint disc with a fainter halo, eased with the night's
  strength; it is freed with the wash. The stars were already drawn. By eye for the user.
- VG10 (documents): Shadow Play's dark end. Spec 5.8 says the soldiers' shadows "walk off and fade"; the code has them fade where they
  stand (motes at the spot, then the take). The code is what is true: the summary, the power book's shape line and the effect's
  comments now say "fade" (no walk was built). VF1 and VC9 corrected above; EnvironmentField's batch-remove comment says why a skipped
  closing reindex() is safe.
- VH1 (reference rows, Task 13b): the 113 moved rows are recorded as the controller's run of 1f6b11c0 gave them (cbae059f differs only
  in a no-city fallback no real town takes). A row that moved but whose family would now miss its gate band is recorded all the same
  (it casts a Veil power); the bands are not repaired here (see the Summary's "Reference rows" and "What is left").
- VRA1 (Task A, previews): the kill colour is Targeting.COL_MAD (Death Mark's "this one is marked to die"); Silent Doom's own ring
  colour COL_INNER is the normal ring, so the two read apart. The preview is pure (Targeting.veil_ringed, Targeting.blight_ill): it asks
  the power's own pick with VeilRules.size at Crowd.in_dark(press), the dark Rules.cast() stamps. Blight keeps no ring radius and no tag.

## Veil review, Task B: stronger casts and Blight's mark (VRB)

- VRB1: Shadow Play's lying outline (ShadowPlayFx.Mark) was never seen: it sat on ctx.ground, which carries Iso.BASIS, at a screen
  position, so it was drawn far off. It now undoes the basis (transform = BASIS^-1 * the screen point), so it lies at the feet in
  screen pixels, under the people; at z 3 and alpha 0.34 (was 0.22) so the god can find it on lit stone.
- VRB2: The new looks live in a new file, src/fx/veil/veil_cast_looks.gd (VeilCastLooks), not in veil_parts.gd: the shared file is
  untouched, so the other review tasks cannot clash with it.
- VRB3: Every new particle system takes its own seed (VeilCastLooks.seed_of: the cast point and a constant), never ctx.rng; the
  particles the powers already had keep their FxParts.particles() calls in the same order, so ctx.rng is drawn exactly as before.
- VRB4: Blight's mark is the person's own badge (Person.set_badge), renewed every frame for HOLD 0.5 s while he is ill out of doors,
  so it never outlives its mark by more than HOLD even when the mark is freed off the tree. A badge another power set when he is struck
  is left alone (only the rot motes show); one that comes over ours later ends our claim and stays. Another power's badge can be rule
  state, not only drawing: Decree's BARS are read by the rite, hide-the-faithful and Halcyon directors (a man in a cell is passed
  over), which is why Blight never overwrites or clears a badge that is not its own (test_veil_blight: bars up before the strike and
  after it, and the mark ending). The glyph is a drop of sickness,
  in BlightFx.ROT's lightest lightened to a7b46e so it reads on the badge's dark plate. It is laid with or without a staged context
  (it is the person's drawn state, as the Death Mark's skull).
- VRB5: Dreamless's thread snaps when the sitter is found, woken by a hurt, or otherwise no longer rests under the cast
  (DreamlessFx.rests()); its length and fraying read DreamlessFx.rest_left(). Cut short (end_now, a freed cast) it goes with the
  cast, without a snap.
- VRB6: Shadow Play's dark fade of a soldier's shadow (VeilCastLooks.ShadeFade) is a lasting piece in SolarisPit.GROUP: the end and the
  cast's finish fall on the same frame, so it cannot be one of the cast's tracked nodes. It frees itself after 1.4 s.
- VRB7: A blighted building gets no new mark this round. By day it reads only through the dusk round it and the rot's puff at the cast;
  the dimmed windows show at night. Left for the user's eye (see the Task B report).
- VRB8 (polish, fix round 2): Blight's glyph colour is a deep rot green 3c9646 (a7b46e and then 8fd04a were lifted and warmed
  by the town's day grade into a yellow, gold-looking token). The badge is drawn through the same light and grade as the body (no
  hue-keeping path), so the base is chosen dark and low in red: measured after the grade, day (108,197,65), dusk (93,179,62).
  VRB4's colour line is superseded.
- VRB9 (polish): two Blight marks on one man share his SICK glyph (a count of live marks per person, drawing only); only the last mark
  standing lets it go, so freeing one cast's mark never drops the glyph while he is still ill. Another power's glyph is still never
  touched, and one that comes over ours ends that mark's share. A mark freed off the tree gives its share up too (PREDELETE).
- VRB10 (polish): a mission's quarry keeps his mark while ill_left() runs: hidden while he is indoors (the badge cleared), shown again
  when he comes out, gone when the illness ends. A citizen sent home sick keeps it until indoors, as before.
- VRB11 (polish): Slumber's eye is an almond outline with a violet pupil, every lit pixel outlined in black, 13 x 7 at 2 px: it reads
  as an eye that half-closes and shuts (lid curve with lashes) on dusk and on lit stone. Dreamless's thread is a silver pixel line with
  a dark pixel either side, alpha at least 0.8 x the fray, 16-28 px tall, so it reads on bright cobbles.
- VRC1 (review round, Unseen Hour's blanket): the blanket is a screen-space sheet on overhead_back (z 4, as the Decree fences), its
  middle raised 30 px above the ground ring and its edge drooping 16 px in nine scallops, so it reads as hung over the town rather
  than laid on it; it is thrown from the click over T_FALL + 0.6 (it lands just after the veil falls) and lifts away over the last
  second of the cast (the cast's own duration, T_FALL + VEIL_TIME + 1). The Hem stays at the ground ring as the line it hangs over,
  and now also lays the blanket's soft shadow; the Hem is built at the cast (not at the fall) so the shadow follows the throw.
  Opacity 0.3 in the middle to 0.5 at the edge: a veil, not a lid.
- VRC2 (review round, Dread of the Dark's wall): the front crosses the dreaded ground over 1.2 s from the click (from the nearest
  dark ground to the farthest), running past T_FALL: the look keeps spreading after the rules have fallen, as the brief's "during the
  fall" is 0.8 s, too short to see a front cross 12 ground units. The wall stands on the shade's edge cells (the border of the dark
  within reach, which is the reach itself where the dark runs on), at most 72 pillars evenly round it; far pillars (high on screen) are
  58 px tall, near ones a 0.28 share of that, so the frozen inside stay in sight. The eyes (still at most 12, on the same edge cells)
  open in the wall at half its height. The shade reads the dark once at the click (it read it first at the fall before) so the
  spread has ground to cross; it stays on the overhead layer (the tests pin it there).
- VRC3 (fix round 1, Dread's wall and the held): the wall is drawn in two halves. The far half (pillars above the dreaded patch's
  middle on screen, 0.55 to 1.0 of HIGH) stands on overhead_back (a WallBack node the shade draws, tracked and torn down with the
  cast); the near half (NEAR share) stays on the shade on overhead, under the frozen's marks, which now draw last. As built in this
  round the far half drew at absolute 12, above the overhead layer (10), so over the near half too; the held stayed clear by the cut
  below alone, not by any layer. VRF1 moved it to absolute 4 (under the aim and under the near half). In a bare context
  (no overhead_back) the shade draws both. Whatever its half, a pillar whose shape could cover a held person's screen rect (14 x 32
  px at his feet) is cut to the NEAR share and thinned to 0.45 of its alpha; this is re-run at every read of the dark and whenever
  the held change. Eye heights are cached then too.
- VRD1 (review round, Evernight's front): the look's front runs out from the click as (t / WAVE)^1.7 of the way to the map's farthest
  corner (EvernightFx.FRONT_EASE), slow by the click and fast across the town, so the god sees the wall of night rise and stand before
  it runs; at dawn it rolls back to the click the same way. Linear (map-width / WAVE) it crossed the screen in under half a second.
  The wash's own `front` (pinned by test_veil_evernight: map-width / WAVE * t) is kept as it was and draws nothing now. Looks only:
  the night still falls everywhere at WAVE.
- VRD2 (review round, Evernight's dark): the night over the town is a shade multiplied over everything in view (ground, houses,
  people) on the overhead_back layer (absolute z 2 since VRF1: over the world, under the aim, every effect over the town and the
  HUD), with a vignette, a lift under the moon and a warm island round
  each burning torch (EvernightSky.View, evernight_shade.gdshader). The LightField ambient and tint keep their numbers (TownLook's
  NIGHT): no pinned number moved. A town already in its NIGHT look gets a lighter shade (it is graded dark once already). Frame means:
  day 98 -> 48, night look 65 -> 50; people, torches and the HUD read.
- VRD3 (review round, Evernight's wash): NightWash set its own Iso.BASIS inside ctx.ground, which carries it already: it was drawn a
  basis too far, off the town (the before frames show no wash at all). It now has no transform of its own and draws only the silver
  rings round the burning torches on the ground; the stars moved into the air shader (fixed to the town, glittering), and the moon
  (still the wash's child "Moon") is top-level and hangs at a fixed place in the camera's view, the same size at any zoom, between the
  shade and the drifting mist.
- VRD4 (review round, The Swallowing Dark's fold; replaced by VRD7 in fix round 1): the heave and a dome rising before full size,
  so the dark stood over the circle when the fold's first removals go. Look timing only: GROW, T_OPEN, FOLD and the removals are
  untouched, and the fold carries nothing per building.
- VRD5 (review round, The Swallowing Dark's hole): the hole draws at ground z 7 (absolute -3), above the town's lamp pools (absolute
  -4): a lamp's light no longer lies on a hole. Its tendrils stand in the y-sorted world, so the houses before the far rim hide their
  feet.
- VRD6 (review round, The Swallowing Dark only; "both" meant its two beats): the heave and the fold give the camera a small shake
  (trauma 0.35, then 0.3): the player feels the ground move; the town still sees nothing (no danger, alarm or fright). Evernight does
  not shake the camera. The shake moves the camera's view by a pixel or so for a few frames, and Person.view (read from the
  camera's screen centre) moves with it, so a tick cadence at the view's edge can change as on any pan; no scripted row casts The
  Swallowing Dark, so no row can see it. A cast freed off the tree (no _exit_tree()) frees its look's pieces
  as it goes (NOTIFICATION_PREDELETE).
- VRD7 (fix round 1, controller's ruling: the fold must read at zoom 1.0, where the circle fills the view): the dome is gone (seen
  from inside it was a flat tint). The dark rises from the ground: for HEAVE (now 1.4 s) before full size a rim of darkness stands up
  at the circle's edge (the wall Evernight's front uses, RIM_H 210 px) and closes in to the middle, everything behind it, ground,
  houses and people, going black (swallow_under.gdshader over the town, the ground point under each pixel worked out, so it reads at
  any zoom), the tendrils pulled down with it. At full size the whole circle is under, so the fold's removals go unseen; from
  DRAIN_FROM (0.4) of FOLD the black drains back into the ground from the edge inward, leaving the bowl. Look timing only.
- VRD8 (fix round 1, the moon): the moon stays screen-anchored (a fixed place in the view, any zoom), but it is part of the sky now:
  a wide glow falling off in many faint steps, a face painted once into a small texture (soft edge, no rim, mottled seas, a waning
  crescent of the night's own colour), only a little brighter than its glow. The NIGHT-town check reads TownLook.active (the public
  read music, ambience and the animals use), not the crowd's private town.
- VRD9 (fix round 1, the wall of night): the wall is no longer a strip of quads (its crown broke at every join: per-quad UVs, then an
  8-bit vertex colour, could not carry the place along the ring). It is one quad over the ring's bounds and the shader works out the
  near and far walls at each pixel, its noise running by the pixel's x along the wall and as wide as it is tall on screen. The shared
  value noise (common.gdshaderinc fbm) still drew straight upright and diagonal cuts through it on the GPU, though a CPU copy of the
  same shader is smooth and a sine-built crown drew none; the wall now uses its own smooth noise of warped sines (wn()), and the cuts
  are gone at both zooms. Coverage follows the body alone, the colour steps are dithered, and the wall thins out toward the ring's
  ends. The night's shade and air quads cover a fixed rect far past any town (EvernightSky.COVER) instead of the camera's view.
- VRD10 (fix round 2): the hole's falling motes are removed (keyed to a whole terrace and an angle wedge, each lit a flat silver quad
  in the black); the funnel's depth `s` is interpolated between rings (stepped, it drew stair edges); the going-under dark uses the
  Veil's own smooth noise (shaders/veil_noise.gdshaderinc, shared with the wall), never the shared fbm.

## Review round, Task E: the skill-tree clips (VRE)

All recorded with `timeout 1200 $G --path . --fixed-fps 60 --audio-driver Dummy -s tools/dev/behaviour_check.gd -- --scenario=clip --power=<key> --at=0.8,2.0 --snap <flags>` (no --no-sheet).

- VRE1: doom: not re-recorded (its look did not change).
- VRE2: blight: `--setup=dark --zoom=2.2` (the glyph shows over the sick in the dark).
- VRE3: unseen: the light size (no --setup), `--whole --zoom=1.0 --fx-clock --times=0.3,0.6,0.9,2,4,6,8,10,12,14,16,18,19.5,20.5,21.0,21.5` (the whole blanket over the market as a violet ellipse: the throw, the hang, the lift in the last frames; the clip tool's `--whole` and `--times` flags).
- VRE4: slumber: `--setup=dark --zoom=2.2 --seconds=4`.
- VRE5: cloak: `--setup=dark --zoom=2.2 --seconds=6`.
- VRE6: dreamless: `--zoom=2.2 --seconds=20` (lit size, the whole rest to the find). Its thread is too thin to read at 152 x 86, and `--whole` only shrinks it more; left as it is.
- VRE7: dread: `--setup=dusk --zoom=1.2 --cam=1,0 --fx-clock --times=0.2,0.4,0.6,1.5,3,5,7,9,11,13,15,17,19,21,23,25.5` (three frames of the front crossing the dusk, the wall and its eyes, the wall sinking and the ground lit again at the end; `--whole` at 1.0 made the wall too small to read, so the centre crop stays). The wall stands round the dusk patch east of the cast; at the dark size the whole frame is dreaded and the wall is off screen.
- VRE8: shadowplay: `--setup=dark --zoom=2.2 --seconds=8`.
- VRE9: swallow: `--whole --zoom=1.0 --fx-clock --times=2,4,6,8,10,12,14,16,18.2,18.8,19.2,19.6,20.0,20.4,21.0,22.0` (eight frames of the hole growing, six on the last 2 s before full size: the rim closing in and the town going under, then the black, then two of the bare bowl).
- VRE10: evernight: by day, `--whole --zoom=0.8 --fx-clock --times=0.3,0.6,1.0,1.4,5,8,12,18,24,30,38,46,54,60,64,65.5` (four frames of the wall of night crossing the lit town, ten of the night with its torch islands, stars and the moon in the corner, and the last, at 65.5 s, the dawn rolling back).

## Final review fixes (2026-11-22, prefix VRF)

- VRF1 (the aim over the night): Targeting draws at absolute z 5 (over the world, under the overhead layers). Evernight's night now
  sits between: the multiplied shade at absolute 2 (EvernightSky.Z_SHADE; the world's pieces are at 1 or lower), the moon, the air
  and the wall at 3 (Z_AIR; the moon and the air at one z as before, the wall after the air in the tree). The aim ring, the previews,
  the kill colour and the DARK / LIGHT tag are never multiplied; the HUD's tags and banners are a CanvasLayer over all of it. The
  relative order of the night's pieces is kept, except that the moon may now draw over the wall of night while the wall runs (it was
  under it). test_veil_evernight reads Targeting's and every piece's absolute z on a real Battlefield. Unseen Hour's blanket and
  Dread's far wall were lowered too, to absolute 4, as their looks survive it: the blanket still hangs over the roofs and the people
  (the world, 0-1) and over Evernight's night, as before; Dread's far half still stands behind the held by the cut alone, and now
  also behind its near half (frames/_final/unseen, frames/_final/dread). Dread's darkened ground and near half stay on the overhead
  layer (they were there before this round) and still draw over the ring: a "For your eye" line.
- VRF2 (one sky): every Evernight builds its own shade, air, wall and moon, but only the sky's owner shows them: the first owner of
  the light look's ledger (LOOK_KEY, the one that already eases the light); with no light field a cast is alone and shows its own.
  The owner draws the night of every cast sharing the look: the farthest front (that cast's centre and its wall), every burning
  torch's island (at most TORCHES, the same spot once), and the moon at the darkest night's strength; the light's ease follows that
  darkest strength too, so one night's dawn under another's night eases nothing. When the owner leaves, the next takes the sky over
  at once (before the frame is drawn): no frame without a sky, never two. Each cast still frees only what it built.
- VRF3 (Unseen Hour's cost): the blanket draws nothing when the game runs headless, and from 5 s after the throw (the landing's
  ripple under 0.15 px) until it lifts it is redrawn 12 times a second, not every frame (the slow breath moves under 0.2 px a step);
  each ring's heights are kept for the next ring's folds (half the height() calls). No rule reads it.
- VRF4 (the stack's bench): `--bench-cast` takes a comma list (`--bench-cast=evernight,unseen,dread`), cast in turn at the same
  spot 4 s apart; one key is as before. On a loaded machine (base 15.1 ms): Evernight 1.11, Unseen Hour 1.11-1.13, both 1.16-1.18,
  Evernight with Dread 2.05, all three 2.11-2.14: over the 1.55 bar, and Dread at its dark size is nearly all of it (about +15 ms).
  Not fixed in this wave (the brief's cheap cut was the blanket's); for the controller.
- VRF5 (minors): the shade's `torches[6]` and EvernightSky.SHADE_TORCHES are named on both sides and the effect asserts TORCHES fits;
  at dawn the torches are out for the rules at once (as before), but their glows, islands and rings fade with the night over DAWN
  (look_lit(); the rules read lit()).
- VRG1 (Dread's cost, Task G): each half of the wall is one MultiMesh of tongues (shaders/dread_wall.gdshader moves every vertex
  from the shade's clock: the rise, the breath, the sway, the taper, the fade and the middle tongue's rim, as the per-frame GDScript
  did), laid out only on a read of the dark that changed it or a change of the held; the eyes, wisps and the frozen's marks stay
  drawn by hand, over the wall (a WallTop child of the shade; the back node draws its own over its MultiMesh, which stands behind
  it). The dark rows are redrawn only while the front moves or the strength changes. A read of the dark asks in_dark() nothing when
  the whole town is dark (night_mission or dusk.everywhere: in_dark() is true everywhere then) and keeps the wall when its runs are
  the same. Nothing of the wall is made or drawn headless. Evernight + Dread on the stack bench: 2.10 to 1.22 of base.

## Veil review, second pass, Task S: The Swallowing Dark's sound (VR2S)

- VR2S1: one take of the fold (no variants): the Tier 5 doomsdays' main hits (sky_clap, quake_open, ts_rise / ts_crash, gravetide_rise, dead_door, cg_shut) are single files, and the power is cast once a descent.
- VR2S2: "at least as loud as the other Tier 5 doomsdays' main hits as played" reads as at least the loudest of the six (Doors of the Dead's dead_door, -13.5): the fold plays at -13.0 (file LUFS + catalog db), at most 2 LU over the loudest (test_power_sounds). The cast plays at -15.0 (the doomsdays' openings sit at -15 to -17), the heave's rush at -15.5, the held rumble at -18.5 at full and 12 dB under that at the cast.
- VR2S3: the quiet Veil band (within VEIL_BAND over the quiet floor) and "no Veil cue ducks the music" no longer bind the Swallowing Dark's four cues (spec 4: the sound is the player's): test_power_sounds checks them against the doomsdays instead. The power stays `quiet` (no danger, alarm or fright: none of it goes through anything the town hears).
- VR2S4: the fold ducks the music and ambience by -6 dB (the doomsdays' hits that duck use -5 to -6; Heaven's Door's -8 is the outlier). No AFTERMATH: the aftermath cues rain rubble back down, and the dark leaves none; the earth falling in is inside the fold's 5 s cue.
- VR2S5: the rumble (v_swallow_loop, one voice) swells linearly in dB with the cast's growth time, from RUMBLE_FROM_DB (-12) under its catalog level at the cast to full at the fold, set on the voice each frame only while the pool voice is still this cast's (its cue meta and the cast's own owner meta). It fades out over RUMBLE_FADE (0.25 s) at the fold and on every end (_finish(), _exit_tree(), freed). Sfx.fade_out() now stops a voice at once when the Sfx is off the tree (it cannot tween there), so the effect always hands its voices to the Sfx.
- VR2S6: the heave's rush (v_swallow_heave) is asked for at max(t_full - HEAVE, 0) from the effect's own HEAVE and t_full, its rise ending 1.4 s into the cue; started late (a growth shorter than the heave, a slow frame over 20 ms) it seeks that far in (`rush_from`), so it still ends on the fold. A cast already at full size (t_full 0) gets no rush. Ended before the fold, the rush goes with the rumble; after the fold it rings on into the hit.
- VR2S7: LevelSound and tests/test_level_sound.gd are not on this branch (it was cut before Develop-Main's LevelSound, d57337d1): no row to add here. When it merges, v_swallow stays the power's main cue as the brief names it.
- VR2S8: the blurb's "gone without a sound" is now untrue: "A black circle grows unseen, then the dark swallows all inside." (61 characters, was 70).
- VR2S9: sources are CC0 or public domain only (OpenGameArt CC0 packs, Kenney, VSCO-2-CE, Wikimedia Commons public domain), none from Sonniss or a model, Sonatina (CC Sampling Plus) left out. The one creature source, OpenGameArt's "CC0 Deep Monster Roar", is wordless: reversed for the cast's in-drawn breath and pitched an octave down under the fold's tail.

## Veil review, second pass: Evernight (2026-11-22, prefix VR2N)

- VR2N1 (the takes): take k of K collects `take_count(k)` = TAKE_FIRST 5 rising evenly to TAKE_LAST 10 (rounded half up; K = 29 by day,
  59 in a NIGHT mission; K = 1 gives 5). Each group is claimed one take ahead (at the fall, after the torches and the call; then after
  every take but the last) by `loneliest_n()`: one pass that measures every candidate's nearest neighbour and sorts. `loneliest()` is
  `loneliest_n(.., 1, {})`'s first, so the two always agree. At his take a claimed one is taken only if he is still alive, out of
  doors, outside every burning torch's light, unspared and takeable; failing any of these he is let go and may be claimed again. A whole night in the bench town (seed 7, cast on
  the market square by day) takes 214 people (182 citizens, 32 soldiers), against about 30 before.
- VR2N2 (who leaves a shadow): every take by the claim and every take by a torch put out leaves a shadow where he stood; the dawn's
  takes (blighted shelterers, dusk sleepers) leave none: they are taken as the shadows fade, and a shelterer stands in a building.
- VR2N3 (the claim's layer): each claimed person's dark (EvernightMarks.Claim: a pool under his feet, his own outline filled from the
  feet up to a licking violet rim, his pale eyes last) is drawn at absolute z 4: over the night's shade and air (the multiply would
  swallow a black on black) and under the aim (5). So it also draws over a wall or a roof in front of him: the god finds the claimed
  even behind a house, which reads as the Veil's mark rather than a fault. Built only where ctx.overhead_back is (nothing headless).
- VR2N4 (the shadows' layer): all of the night's shadows are one EvernightMarks.Stains node on ctx.ground (z 2, under the wash's torch
  rings), one triangle list, rebuilt only when one is added, while one fades in (0.45 s) or over the dawn. A faint violet rim keeps
  each readable under the night's multiply. They are tracked by the cast and go with it however it ends.
- VR2N5 (the wisp): one wisp per person taken, as before, but each wisp is 7 puffs now (was 11; the torch put-out wisps too), for the cost (the cost holds, see the report's bench).

## Veil review, second pass: Blight and the scripted nights (2026-11-22, prefix VR2B)

- VR2B1: Blight's cooldown is 20 s (was 36): the user's word "too long for Tier 1"; the other Tier 1 powers run 10 to 20 s. Blight
  leaves the v0.07 floor table of tests/test_power_book.gd (floor 25): the Veil build remade it into another power.
- VR2B2: the scripted nights keep Blight's recorded pace of 36 s (static `Rules.pace`, set by tools/dev/behaviour_check.gd `BOT_PACE`;
  empty in the game; never for a once-a-descent power). At 20 s without it, 8 of the 50 rows that cast Blight moved:
  god_veil_prayers_play_1 lost to the Gaze and _3 moved; judgement_b_play_1-3 and night_b_play_1-3 moved (lost before and after).
  With the pace no row moves. A play that waits longer than it must is still a play; the next bot pass may drop the pace and
  record the rows again.
- VR2B3: Evernight takes 5 rising to 10 a take (the user's "5 - 10" read as a rise, no luck); the claimed are not held in place.
- VR2B4: no sound for Evernight's takes in this pass (not asked; a cue every 2 s for 60 s needs the user's ear).

## Levels (prefix VL)

The Veil's ability levels (branch god/veil-levels; spec 2026-11-24-kak-veil-ability-levels-design.md). Each line: what was decided --
why -- what it costs if wrong. VL1-VL16 are the plan's decisions; VL17-VL30 the controller's rulings R1-R14; VL31 on are the
implementers' `Ruling:` lines (G1, G2, then tracks A, B, C, D). Note: the tracks' commits end with "Claude Sonnet 5.5" where the
plan says "Claude Fable 5.2" (the dispatch's reminder named Sonnet); a trailer amend is the only cost.

### The plan's decisions

- VL1 Pair storage: a sized stat's table value is `[light, dark]` (an Array, ints for counts). `VeilRules.SIZES` stays the level-1
  pairs; `VeilRules.size()` reads the row's table at the level and falls back to `SIZES` for a stat the table does not name
  (Evernight's `TAKE_EVERY`). Printed `0.8 / 1.6` by `PowerBook._stat_text()`. -- level 1 must equal today's constants -- a table
  Array of the wrong type would shift a reference row.
- VL2 Dusk by level lives once, in `VeilRules` (`DUSK_RS`, `DUSK_TIMES`); the tree shows it as one extra row "dusk" (`3.0 for 20 s ->
  3.25 for 22 s`) on every Veil row but Evernight's; `VeilParts.land()` reads the cast's level. -- one rule for all ten, not ten
  copies -- a power wanting its own dusk later needs a table column.
- VL3 The watch is `Crowd.is_watch(p)`: every soldier, plus whoever a mission director's `watches(p)` names (default: its `faithful`).
  `assassinate`'s and `procession`'s `witnesses()` are "anyone near", not the watch. -- Unseen Hour would otherwise eye the whole town
  -- a mission whose watch is not its faithful needs its own `watches()`.
- VL4 Blind is `Person.blind_for(seconds)`: `statuses[&"blind"]`, run down in `Person.tick()`. It joins `veil_blind()` (sees, seizes,
  finds, reports, delivers nothing), the two copied witness skip lists (`Crowd.nearest_witness()`, `TempleReport._witness()`) and the
  bell keeper. He still walks, flees and fights. Standing inside a veil does not blind (the law of the Veil is unchanged): only
  Unseen Hour's leavers and Cloak's turned watch are blind. -- the spec's non-goal -- a blind fighter may surprise you.
- VL5 Pale Eye life: one `(person, cast)` entry with `seconds` (default 4.0, INF = until `unmark`/`release`). It closes on time, on
  `unmark`, on `release` (open-ended ones only), and for good for that cast when the person is taken, dies or goes inside; another
  cast may eye him again. Timed eyes outlive their cast; `release(fx)` in a twist's teardown closes the cast's open-ended ones. --
  each cast owns its eyes, so two casts never close each other's -- a forgotten `release` leaves an eye until the town clears.
- VL6 Pale Eye place: one `PaleEye` node per crowd (`crowd.pale_eye`), made on the first `mark()`, on `ctx.overhead_back` (else
  `ctx.overhead`), absolute `z_index 4` (under Targeting's 5), kept the layer's last child so an Unseen Hour blanket or a Dread wall
  at the same z never covers it. Headless: the ledger works, nothing is drawn. -- one drawing, cheap -- an eye hidden under some
  layer you have not seen yet.
- VL7 Pale Eye cue `&"v_pale_eye"`: when an eye opens, at most once per `CUE_GAP 1.0` s (eye clock), through the context's play at the
  eyed man when on screen, else at the screen centre's ground point; quiet band (`test_power_sounds` VEIL_MOMENTS). -- it is the one
  new sound -- too soft or too sharp to your ear.
- VL8 Silent Doom's witnesses are named and answered inside `Crowd._settle_doom()` through `answer_doom()`: the effect stays out of
  `crowd.gd`. A silenced witness is killed `&"doom"`, so his own death is judged at the next settle by today's rule. -- the witness
  must be the one today's rule finds -- a hook in the shared crowd file.
- VL9 Dreamless judges with `nearest_witness(at, null, skip)`, `skip` = every sitter and resting finder of this cast. -- a sitter or a
  finder must not count as a witness of the sitter -- a finder judged by a fellow finder.
- VL10 Cloak's "drop the pursuit" is `Person.turn_away(6.0)`: stop fighting, out of a queue, back to post (a soldier) or calm with no
  goal (one of the watch who is not a soldier), and blind 6 s. A director's own errand stops through `_sees()`/`veil_blind()`. --
  reuses nothing that exists; one named, reusable state -- a soldier turned away can be ordered to fight at once (VL37).
- VL11 Dread's "stopped at its edge" is `Person.dread_balked_at` (crowd clock of his last step refused by a dread), set in
  `_step_blocked()`; Track C counts it only within 1.0 of its own dreaded ground. -- the walker's own refusal is the only truth -- a
  man blocked by something else near the edge is held.
- VL12 Blight's watch outlives the cast. It is the foothold's (a node in `SolarisPit.GROUP`, its id in the foothold meta), ended by
  `BlightFx.heal()`, by its building freed, destroyed or taken, by its crowd freed and by `Battlefield.clear_effects()`. -- the rot
  lasts the night, the cast only 1.6 s -- a watch that is not freed on some exit goes on ticking.
- VL13 The Swallowing Dark's marked spared (believers, the mission-kept) are eyed and marked but not taken outside the circle at the
  fold; inside it the power takes them as today. -- the anti-goal over "as today" -- a believer who walked out lives.
- VL14 Evernight's huddle keeps level 1's slots (`TORCH_R - 0.3`); only the light shrinks. The static light is re-added when its
  radius has shrunk by `LIGHT_STEP 0.05` (no `LightField` change). -- the claims must be able to grow -- a few extra light updates.
- VL15 Slumber's "not in it at the cast" is anyone within its circle at `T_FALL`, slept or not. Unseen Hour's leavers include anyone
  inside at the fall; the veil lifting blinds nobody. -- simple, testable -- a man inside who was not slept is never slept by the twist.
- VL16 Twist texts (they fit the tree's detail line; shorten words, never the name, if the fit check fails): doom "No Witness: the
  nearest who saw it falls too"; blight "Watchful Rot: the watch falls ill in your rot"; slumber "Heavy Air: who walks in sleeps
  too"; cloak "Averted Eyes: the watch near them turns away"; unseen "Eyes Within: see the watch; leavers stay blind"; dreamless
  "Found by No One: never found; a finder rests"; dread "The Dark Looks Back: who stops to look is held"; shadowplay "The Shadows
  Keep Watch: who comes close joins"; swallow "Nothing Leaves: who walks out is taken too"; evernight "The Light Gives Way: the
  torchlight shrinks". -- the tree's line is short -- a word you would change.

### The controller's rulings (R1-R14 of the pre-flight scan and G2's review)

- VL17 (R1, G2 and Track A) `PaleEye` gains an owner-id form beside the cast form: `mark_by(crowd, owner_id, p, key, seconds, layer)`
  and `release_by(crowd, owner_id)`; `mark(fx, ..)` and `release(fx)` call them with the cast's instance id. Blight's rot watch
  (which outlives its 1.6 s cast, VL12) uses them with its own id. -- the watch has no cast to pass -- one small API.
- VL18 (R2, G1) `veil_cast_looks.gd` joins G1's files: wherever a look divides by or reads a constant that now has a level (the
  Dreamless Threads look read `DreamlessFx.REST`), it reads the cast's level value. Level 1 draws exactly as today. -- else the look is
  wrong above level 1 and no track may edit that file -- none.
- VL19 (R3, G2 and Track B) A blind man still fights. `Person.turn_away(seconds)` carries its own timer: for those seconds he takes up
  no new pursuit, search or fight target (one check beside `hidden_from_watch()`), and he is blind for the same seconds. Cloak's
  test "may fight again after 6.1 s" tests `turn_away`, not blind. -- VL4 and VL10 disagreed -- one more timer on Person, named and
  reusable.
- VL20 (R4, Tracks A and B) The "skip anyone `VeilParts.held(p)` names" rule covers answers to people who walk in or come near
  (Slumber, Cloak, Dread, Shadow Play, Blight, Swallow). It does not shield a witness named by today's witness rule
  (`Crowd.nearest_witness()`): Silent Doom silences him and Dreamless rests him even if he is asleep (shadows and the dreaded are never
  witnesses today, so they are never named). -- a sleeper who counts as a witness today must be answerable, or the twist fails exactly
  where the alarm would rise -- a sleeping witness dies to No Witness.
- VL21 (R5, Track C) Dread's twist holds anyone "not asleep and not a shadow" (not "not `held()`"): a man already frozen by another
  Dread cast is held by this cast too, per cast id, and stays frozen until both lift. -- the brief's rule made its own two-casts test
  impossible -- none.
- VL22 (R6, G2) `Crowd.answer_doom()` names the nearest witness of every registered victim first, then answers each distinct named
  witness once. Never alternate naming and answering. -- else the second victim names a farther witness after the first is killed (a
  chain the spec forbids: one hop) -- none.
- VL23 (R7, G1 and F) G1 does not run all 508 reference rows: every task runs the 36 `veil` rows and `digest|crowd_check|warning_doom`,
  G1 also nine families of play rows that cast Silent Doom or Blight outside the god rows. All 508 run at Task F, machine load
  allowing. -- 508 rows took 19 h under load -- a moved non-Veil row is found at F, not G1.
- VL24 (R8, G2 and F) A stub twist suite's placeholder check must fail the gate if left: Task F runs
  `grep -l "pending (Track" tests/test_veil_twist_*.gd` and it must print nothing. -- a stub `check(true)` asserts nothing -- none.
- VL25 (R9, Track A) Blight's test reads "no cue but `v_pale_eye`" for the rot's sick. -- eyeing plays the Pale Eye's cue -- none.
- VL26 (R10, Track A) The callback given to `Crowd.answer_doom()` checks `is_instance_valid(w) and w.is_alive()` before it answers a
  witness. -- one answer may already have killed a witness another was handed, and tracks may not edit crowd.gd -- none.
- VL27 (R11, all tracks) The first `PaleEye.mark`/`mark_by` in a crowd with no eye node needs a layer to build on: the cast's
  `ctx.overhead_back` (else `ctx.overhead`). An open-ended (INF) eye is closed by the twist's own teardown (`release`/`release_by`);
  the hook does not close it when its owner is freed. -- the hook has no owner to watch -- a leaked eye until the town clears.
- VL28 (R12, all tracks) G2's report is the interface reference: every shared hook's exact signature. No track edits a file G1 or G2
  own; a missing or wrong hook is NEEDS_CONTEXT with the signature needed. -- keeps the merge conflict-free -- none.
- VL29 (R13, tracks A-D) Four tracks at once on a loaded machine run only `digest|crowd_check|warning_doom` and
  `god_veil_(prayers|tax|lamb|harvest|warning)_play_1` (8 rows); the controller runs all 36 `veil` rows and the play rows once on the
  merged head. -- 4 x 39 rows at once would take many hours -- a moved row is found at the merge and bisected by track.
- VL30 (R14, tracks A-D) Each track works in `vfxProve-veil-<a|b|c|d>` on `god/veil-levels-<a|b|c|d>` (import first); the workspace
  stays in the main veil worktree, each track writing only its own report; other tracks' twist suites are stubs there: left alone.
  -- no shared writes -- none.

### G1: tables, sizes and dusk by level, the aim, the tree

- VL31 Blight's `lv_ill_reach` is a local in `_build()`, not a member. -- Blight's cast has no member state for it and only
  `sick_with` reads it -- none (a test reads the effect through `sick_with`/`blight_ill`).
- VL32 `VeilRules.dusk_row()` returns `{}` for any key not in `SIZES` (the ten Veil keys). -- "non-Veil key" per the brief -- none.
- VL33 `Rules.cast()` moves the `told` build (level and dark stamp) wholly above `veil_refusal`; the dark stamp is only made for a Veil
  key with a crowd, as before. -- Dread's refusal needs the level -- same stamp, none.
- VL34 `_gate_builds` compares child-count deltas of `ctx.overhead`, `ctx.ground` and the world, not absolute counts. -- casts leave
  nodes until freed -- stable under repeat; none.

### G2: the Pale Eye and the shared hooks

- VL35 `HarvestDirector.watches` (a dict of watch posts) clashed with the mandated `MissionDirector.watches(p)` method (a subclass
  member may not shadow a parent member): the dict is renamed `watch_posts`, with its readers in four tests. -- the method name is
  fixed by the brief, the dict was an internal -- a rename back plus a differently named hook.
- VL36 `turn_away()` leaves a sleeper asleep (blind and turned only) and does not calm a fleeing, panicking or sheltering non-soldier
  (it drops fights, queues and goals and sets CALM for the rest); a soldier goes `send_to_post(post)` regardless. -- VL10 names "stop
  fighting, out of a queue, back to post / calm" and the twist skips held men anyway -- a sleeper woken or a runner calmed by a Cloak.
- VL37 `_fightable()` refuses new targets while turned only under the HOSTILES and OWN_KIND rules (the watch's own choice, like the
  cloak check beside it); a frenzy or power's ordered target (TARGET_ONLY, ANYONE, OF_KIND, OTHER_SIDE) still stands. -- R3 says
  "beside `hidden_from_watch()`" -- a turned soldier may be ordered to fight.
- VL38 `answer_doom` registrations of victims who did not die (Deathless) stay until `unanswer_doom` or the town clears; those in
  `dead` are forgotten after naming. -- the brief says the registered victims are then forgotten -- a stale entry answering a later
  death of the same man.
- VL39 The Pale Eye's cue goes through the crowd's `sfx` (a `FxContext` is not at hand in `mark_by`) at the positions VL7 names. --
  same sound -- none.
- VL40 `Crowd.clear()` `queue_free()`s the eye node (VL6: cleared with the town). -- none.

### Track A: Silent Doom, Blight, Unseen Hour

- VL41 Blight's watch, when its first-in-order man is spared (or cannot fall ill), lets the next man who stepped in fall ill the same
  tick (the brief says only that a spared one starts no rest). -- reads "the first while not resting falls ill" as the first who can --
  if wrong, a `break` after the first stepped-in.
- VL42 The watch's ill man gets the same `BlightMark` glyph the cast's `_make_ill` gives, but no `q_blight_ill` cue. -- the glyph is the
  existing sickness look, not a cue -- drop the mark in `RotWatch._tick`.
- VL43 Blight's eyes are timed (`PaleEye.TIME`), so a watch has nothing open-ended; its teardown test reads `held_by(cast) == 0` at
  once and `held_by(watch)` after the eye clock runs 4.1 s. -- a timed eye outlives its owner by design (VL5) -- none.
- VL44 Unseen Hour does not blind a leaver the town spares (believers, mission-kept); held leavers (asleep, shadow, dreaded) are
  blinded. -- the "Spared" global rule; VS names leavers -- if wrong, drop the `spared` test in `_tick`.
- VL45 Unseen Hour's `_rise()` (which was never called) is called at `T_FALL + veil_time`, under the twist only, so `veiled` goes false
  at the lift at level 5; levels 1-4 keep `veiled == true` as today. -- the twist needs a lift to stop its eyes -- none below level 5.
- VL46 Doom registers an answer only for victims actually struck (not those gone indoors); an insider who walks back in after being
  blinded rejoins Unseen Hour's list and can be blinded again on leaving. -- "who saw it" needs a strike -- a victim gone indoors names
  no witness.
- VL47 The "freed building" Blight test uses a stand-in `Structure` outside the town's list. -- freeing one of the town's own
  structures leaves `EnvironmentField.structures()` holding a dead node and breaks later callers -- none.

### Track B: Slumber, Cloak of Night, Dreamless

- VL48 "One standing in the circle at the fall but awake (a shadow) is never slept" is tested as "in the circle at the fall, woken,
  standing in it: not slept by the twist, not eyed". -- today's `_fall` sleeps everyone in the circle, a shadow too (`Person.sleep()`
  does not refuse one) -- if wrong: `_fall` should skip shadows, a level-1 change that was not made.
- VL49 `held_by(fx_id) == 0` after teardown is checked after `PaleEye.step(TIME + 0.1)`. -- the twists' eyes are timed (VL5), only INF
  eyes are closed by `release` -- a twist would have to `unmark` its eyes at teardown, against VL5.
- VL50 Cloak skips the hidden man himself as an object of his own cloak, but a hidden soldier next to another hidden man is turned by
  that other. -- the spec says "the watch within 2.0 of a person this cast keeps" -- one extra `turn_away` on a hidden soldier.
- VL51 Cloak's turn counts and eyes a man only when `turn_away()` returns true (the dead and the indoors return false, already
  excluded). -- consistent -- none.
- VL52 Dreamless sitters' status `&"dreamless"` is erased as the sitter is taken or killed in `_found_by_none` (as `_found` does before
  killing). -- same as today -- none.
- VL53 Dreamless finder judgement uses `skip` = all sitters plus all finders and excludes the finder himself; a finder who died or woke
  before the judgement is not judged. -- VL9 -- a finder woken by a hurt is left unjudged (he is awake and was not "found").
- VL54 Slumber's ring is a new inner class `HeavyRing` (violet arc and faint dusk disc, breathing) in `slumber.gd`. -- the shared looks
  file is G1/G2's -- untested on a real screen.
- VL55 Dreamless's `NOTIFICATION_PREDELETE` releases only the twist's finders (not the sitters). -- level 1 stays unchanged -- none.

### Track C: Dread of the Dark, Shadow Play

- VL56 Shadow Play's joined are eyed open-ended (released in `_undo()`), like Dread's. -- the brief says only "eyed" and the teardown
  contract needs `held_by(fx_id) == 0` -- if wrong, a timed 4 s eye.
- VL57 Joined shadows count as "a shadow this cast owns", so joining can chain from a joined man (capped by `JOIN_MOST` 12). -- a
  reading of the brief's wording -- if wrong, poll from the original shadows only.
- VL58 Polls run every `TICK 0.25` s (the "Cheap" rule) with a 0.001 tolerance on the accumulator and the 2.0 s stand, so 8 ticks reach
  exactly 2.0 s; "within one tick" is up to 0.25 s. -- the cheap-poll rule -- a hold arrives up to 0.25 s late.
- VL59 `ShadowPlayFx.shadows` stays counting only the rise; the new `joined` counts joiners. -- keeps level-1 tests unchanged -- none.
- VL60 One commit for both of Track C's twists, not one each. -- they share one test round -- a bisect between them is not possible.

### Track D: The Swallowing Dark, Evernight

- VL61 A marked man who is spared (believer or mission-kept) is eyed and marked but skipped at the fold only when beyond `full_r`;
  inside he is taken as today. -- VL13 -- none.
- VL62 Marked men are taken even if `VeilParts.held()` (asleep, shadow, dreaded). -- the spec names every marked man alive; "held" is
  for answers to people who walk in or come near -- a sleeping marked man is taken too.
- VL63 "Stood inside" and "marked" ignore people who are indoors; leaving is judged on `ground_pos` distance to the click. -- an indoor
  man cannot walk out -- none.
- VL64 The brief's "claimable by WAVE + 27" is tested as "claimed by WAVE + 28". -- claims happen on the take beat (every 2 s) and the
  light is 1.965 then -- off by one beat.
- VL65 The `put_out` late test places the bystander at 1.8 and calls it at WAVE + 37. -- at 2.0 the normal claim and take already
  remove him before WAVE + 60, so the brief's scenario cannot isolate `put_out()` -- none.
- VL66 The shared shade takes the smallest `torch_r()` among the sharing level-5 casts (one uniform for all islands), and keeps the dawn
  fade at `END_R`. -- one uniform serves the whole sky -- a level-1 night's islands sharing the sky with a level-5 night are drawn
  as small as the level-5 one (a look only).

### Final review fix wave

- VL67 Averted Eyes never breaks a hold or an errand: a watcher held by the god's Dominion power (`held_by_god()`), held by the mission
  (`Crowd.held_by_mission()`, a seizer with his charge) or on a duty (`Mind.DUTY`) is eyed only (once per cast), not turned, not
  counted, not blind; if his hold ends while the cast lasts he may be turned then. -- Evernight's bearers skip the mission-held for
  the same reason -- if wrong, one line in `_eyed_only()`.
- VL68 In the four walk-in twists the spared are eyed only -- the spec's anti-goal allows a twist to do to the spared "what its power
  already does at level 1", but a walk-in is not an aimed act, and a mission-kept soldier taken by a dark Shadow Play or a believer
  put to sleep by walking into Heavy Air can lose a night the player did not choose to risk; the plan's Global rule says "eyed, never
  answered" -- cost if wrong: the owner wants Heavy Air to sleep everyone; one line per power to revert. Slumber's walker is eyed, not
  slept, not caught; Dread's edge man is eyed (timed), not frozen, uses none of the 16; Shadow Play's near man is eyed (timed), does
  not join, is never taken, uses none of the 12; Cloak's watcher is eyed only. Each is eyed once per cast. Level 1 of each power
  still does to the spared what it does today.
- VL69 The Pale Eye lingers on the dead: an eye whose man died or was taken stays where he last stood for `FADE` (0.4 s), drawn
  fading (the edge marker too), then closes for good. `is_eyed()`, `eyed()` and `held_by()` count it closed at once (no existing check
  changed); going indoors still closes at once. A man eyed by two casts is drawn once, with the larger alpha (`PaleEye.drawn()`). --
  Silent Doom's silenced witness is eyed and killed in one call and would never show an eye -- a look only, if wrong.

### Bench

Measured 2026-11-25 on `961a9046` with `--bench --seed=7 --loadout=<cast>`, then the same with `--bench-cast=<cast>
--bench-after=4` (17 for the Swallowing Dark) at `--bench-level=1` and `--bench-level=5`. Mean frame time in ms; two or three
runs per cell. The machine was loaded (a second check run ran beside this one), so read the ratios, not the absolute times.
The bar is level 5 against the base at 1.55 or under.

| Cast | Base | Level 1 | Level 5 | Level 5 : base |
|---|---|---|---|---|
| Dread of the Dark | 26.70 | 27.04 | 26.35 | 0.99 |
| Shadow Play | 26.06 | 27.03 | 32.14 | 1.23 |
| The Swallowing Dark | 26.70 | 20.32 | 13.79 | 0.52 |
| Evernight | 26.40 | 33.08 | 32.96 | 1.25 |
| Evernight + Unseen Hour | 27.32 | 34.54 | 37.79 | 1.38 |
| Evernight + Dread of the Dark | 26.27 | 33.43 | 39.70 | 1.51 |

Every pair is under the bar. The closest is Evernight with Dread of the Dark: 1.51 on the means, 1.53 on its worst single
pair (42.05 against 27.45). The Swallowing Dark runs faster than the base, most likely because the people it has taken are no
longer drawn or stepped (cause not measured). No run logged a script error. A bench on a quiet machine is still owed.

## Twists, second round (prefix VT)

Branch `god/veil-twists-2`, cut from `god/veil-levels` `850e22de`; spec `docs/superpowers/specs/2026-11-26-kak-veil-twists-2-design.md`.
Form: what -- why -- cost if wrong.

### The controller's decisions

- VT1 Dread's take kind is `&"void"` (the kind The Swallowing Dark uses: no body). -- the spec says "no body, gone for good"; a kind
  outside `Remains.BODY_KINDS` is how a take leaves none -- if wrong, one constant changes and a body is left.
- VT2 Crater numbers: radius 1.2 to 2.8, 9 craters at the light size, 20 at the dark size (the spec's guess was 9/15 and 0.8 to 2.2). --
  the spec states "about a third of the circle" as the intent and marks its numbers as first guesses; 0.8 to 2.2 covered only about
  15 percent; the tests pin a cover of 0.22 to 0.40 -- if wrong, the user wanted fewer, smaller pits: two constants.
- VT3 A crater's hurt does not call `Person.hurt()`. It lowers `health` by `CRATER_HURT` (0.25) times the step, flashes, and at 0 or
  less takes him with `VeilParts.take_out(crowd, p, &"void")`. A sleeper or a shadow's owner is hurt and not woken. -- `hurt()` emits
  `enemy_struck`, wakes and kills as `&"frenzy"` leaving a body; the spec wants a silent hurt and no body -- if wrong, a later reader
  expecting `hurt()`'s hooks (`struck_by`) sees none.
- VT4 Evernight's level-5 torch colour is `FALSE_COLOR` (0.55, 0.75, 1.0). `END_R`, the shrink in `torch_r()` and `_shrink_lights()`
  go, and every reader of the light's radius reads `TORCH_R`. -- the spec's "pale blue" and "the shrinking is removed" -- if wrong,
  one colour constant; the shrink is back only by revert.

### Task rulings and parked minors

- VT5 The craters' placement is seeded from the cast (`hash(origin.round())`): the same click lays the same craters; there is no per-run
  rng. -- the spec's anti-goal "a twist that needs luck" -- cost if wrong: none; a seed is cheaper to reason about than a random
  stream.
- VT6 Craters may lie where ordinary buildings stood; only gates, bridges, the postern, the dock, the fountain and buildings the
  mission needs are kept clear. The fold takes the ordinary ones, so the ground is bare. -- the brief names the keep-out list --
  if wrong, the keep-out list grows by one source.
- VT7 The keep-out source is extracted (`_kept_structures()`, `_needed(s)` in The Swallowing Dark) and used by both the fold's
  `_inside()` and the craters. -- one list for both, so they cannot drift -- none.
- VT8 The craters are laid under `ctx.ground`, untracked, in the group `SolarisPit.GROUP`, so `clear_effects()` frees them; their eyes
  are closed in `_exit_tree` and on predelete. -- they last the rest of the mission and the teardown contract needs
  `held_by(fx_id) == 0` -- if wrong, an eye outlives a crater until the town clears.
- VT9 A person indoors is passed over by the craters and by Evernight's flare. -- an indoor man is not on the ground the pit lies on, and
  VL63 already passes the indoors over -- if wrong, one line per twist.
- VT10 Dread's pull eye is open-ended and released with the cast. -- a timed eye is not closed by `PaleEye.release` (only open-ended
  ones are), and the teardown contract needs none left open -- if wrong, a timed eye shows after the cast has ended.
- VT11 The pull moves the man with `ground_pos` and `p._sync_position()`, a private method inherited from `DummyEnemy`. -- no public
  per-frame move exists, and `fold()` re-paths -- cost if wrong: a rename breaks the pull; parked (see VT19).
- VT12 The pull's saved alpha is always 1.0, never read from `modulate.a`, so overlapping casts cannot save a faded value; a man
  dropped mid-pull (dead, or gone indoors and out again) has it restored. -- fix round 1 of Task 1 -- none.
- VT13 A held or on-duty soldier is taken at Dread's edge like anyone. -- the spec: he is eaten, not turned; the duty rule of VL67 was
  about Cloak re-posting him -- if wrong, one skip in the poll, and a soldier is eyed only.
- VT14 Dread's spared are eyed once (timed), never taken, and use none of the 16. -- VL68 -- none.
- VT15 Evernight's huddlers and bearers who are spared are left out of `huddle_of()`; they are never taken at the flare. -- the spec's
  sparing -- if wrong, a believer is lost at the dawn.
- VT16 Evernight's flare runs only from `_dawn()`; a teardown through `_end_night()` flares nothing and the eyes are released as they
  were already. -- the spec: "if the mission ends before the dawn, nothing flares" -- none.
- VT17 Two Evernights at once (one sky): a huddler near both torches is taken once; the second take returns false and nothing breaks.
  -- review focus 2 -- none.
- VT18 The shared sky is drawn with the false (blue) island if any sharing cast is level 5. This replaces VL66's shrunken island. -- one
  uniform serves the whole sky -- cost if wrong: a level-1 night sharing the sky with a level-5 night looks blue (look only; parked).
- VT19 Parked minors, none functional: Dread's pull calls the private `_sync_position()` and some of its comment lines are long; no
  regression test for overlapping Dreads' alpha (VT12); the craters recompute their middle and reach on every tick instead of caching
  them; an Evernight leaver who was eyed stays eyed until the dawn; the flare reuses its seed when the huddle is empty. -- polish only
  -- cost if wrong: a tiny per-tick cost, or a misleading eye.
- VT20 The look of the pull, the craters (and their swirl) and the black flare is unseen on a real screen. -- every check was headless;
  the summary's "For your eye and ear (second round)" asks for it -- cost if wrong: a look the user has to ask to change.
- VT21 Task 3 (Evernight) began while Task 2's review ran. -- the files are disjoint (evernight against the swallow) and a Task 2 fix
  would touch only its own files -- cost if wrong: a fix commit lands between Task 3's commits; the reviews used explicit commit ids.
- VT22 No new sound cue: the pull, the crater's hurt and the flare use no new sound, so `tests/test_sfx_catalog.gd`'s counts are
  unchanged. -- the spec: a crater's hurt makes no sound the town hears -- if wrong, a cue with CC0 recipes is added and the counts rise.

### Bench

Bench: filled in by the controller.
