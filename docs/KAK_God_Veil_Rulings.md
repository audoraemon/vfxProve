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
- VRD1 (review round, Evernight's front): the look's front runs out from the click as (t / WAVE)^1.7 of the way to the map's farthest
  corner (EvernightFx.FRONT_EASE), slow by the click and fast across the town, so the god sees the wall of night rise and stand before
  it runs; at dawn it rolls back to the click the same way. Linear (map-width / WAVE) it crossed the screen in under half a second.
  The wash's own `front` (pinned by test_veil_evernight: map-width / WAVE * t) is kept as it was and draws nothing now. Looks only:
  the night still falls everywhere at WAVE.
- VRD2 (review round, Evernight's dark): the night over the town is a shade multiplied over everything in view (ground, houses,
  people) on the overhead_back layer, under every effect and the HUD, with a vignette, a lift under the moon and a warm island round
  each burning torch (EvernightSky.View, evernight_shade.gdshader). The LightField ambient and tint keep their numbers (TownLook's
  NIGHT): no pinned number moved. A town already in its NIGHT look gets a lighter shade (it is graded dark once already). Frame means:
  day 98 -> 48, night look 65 -> 50; people, torches and the HUD read.
- VRD3 (review round, Evernight's wash): NightWash set its own Iso.BASIS inside ctx.ground, which carries it already: it was drawn a
  basis too far, off the town (the before frames show no wash at all). It now has no transform of its own and draws only the silver
  rings round the burning torches on the ground; the stars moved into the air shader (fixed to the town, glittering), and the moon
  (still the wash's child "Moon") is top-level and hangs at a fixed place in the camera's view, the same size at any zoom, between the
  shade and the drifting mist.
- VRD4 (review round, The Swallowing Dark's fold): the ground heaves HEAVE (0.8 s) and the dome rises RISE (0.4 s) before full size,
  so the dome stands over the whole circle when the fold's first removals go (they go in the fold's first frames); it closes down over
  FOLD. Look timing only: GROW, T_OPEN, FOLD and the removals are untouched, and the fold carries nothing per building.
- VRD5 (review round, The Swallowing Dark's hole): the hole draws at ground z 7 (absolute -3), above the town's lamp pools (absolute
  -4): a lamp's light no longer lies on a hole. Its tendrils stand in the y-sorted world, so the houses before the far rim hide their
  feet.
- VRD6 (review round, both): the heave and the fold give the camera a small shake (trauma 0.35, then 0.3): the player feels the ground
  move; the town still sees nothing (no danger, alarm or fright). A cast freed off the tree (no _exit_tree()) frees its look's pieces
  as it goes (NOTIFICATION_PREDELETE).
