class_name Person
extends DummyEnemy
## A citizen or a soldier of Aldermere: the same unit every effect already kills, knocks, pulls, freezes and
## lifts, with a brain that walks the town's paths. Citizens go calm -> panicked -> fleeing -> escaped, queueing
## at the gates on the way out. Soldiers hold a post, march to the Citadel when the rally sounds, and never flee.

enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD, OBSERVE, RECOVER, REGROUP, DUTY, ASSIST, SHELTER, CONFUSED, WHISPERED,
	COMPELLED, FIGHT }
## What a citizen is trying to do (v0.04), read from its mind: going about its day, stopping to look at something,
## running from danger nearby, evacuating through a gate, or cautiously returning once a danger has passed.
enum Intent { ROUTINE, OBSERVE, LOCAL_FLEE, REGROUP, EVACUATE, REROUTE, RECOVER, ASSIST, SHELTER, CONFUSED, WHISPERED,
	GATHER, FRENZY }
## How much a citizen knows of the danger (v0.04's awareness levels; Emergency and Collapse come with the staged
## alarm).
enum Awareness { UNAWARE, CONCERNED, THREATENED, EMERGENCY, COLLAPSE }
## A soldier's role (v0.07): none (the Citadel's guard and anyone over the profile's counts), marshal at a way out,
## escort for a responder, or rescue squad; v0.10 M3's Lantern Knight, Broken Lanterns' shrine guard.
enum Corps { NONE, MARSHAL, ESCORT, RESCUE, KNIGHT }

const PANIC_SPEED := 1.6
const FLEE_SPEED := 1.2
## How long a fright can last before it settles even if the person never reached safety (walled in, a path that
## keeps closing).
const PANIC_SECONDS := 12.0
## A local flight runs to this far beyond the threat's radius (plus up to LOCAL_FLEE_JITTER more).
const LOCAL_FLEE := 3.0
const LOCAL_FLEE_JITTER := 2.0
## A frightened person still inside the threat's radius plus this is not yet safe.
const THREAT_MARGIN := 1.5
## How long a person stops to look at something it saw or heard (seconds, min and max), and how long one waits where
## it ran to (or after looking) before going back to its day.
const OBSERVE_SECONDS := Vector2(1.0, 3.0)
const RECOVER_WAIT := Vector2(5.0, 10.0)
## Walking back after a fright, a little slower than a stroll.
const RECOVER_PACE := 0.8
## A fire responder hurries.
const ASSIST_PACE := 1.5
## Close enough to count as arrived.
const GOAL_REACH := 0.45
## Seconds before a person gives a stuck goal another try. Cinderfall repeatedly invalidates routes (fallen
## buildings, the bridge closing), so raised from 2.5 to spread the A* replanning out over fewer per-second calls.
const REPATH := 4.0
## Chance per frame that a calm citizen strolls to the market or back home.
const STROLL_CHANCE := 0.004
## How far a calm citizen drifts from home, and a posted soldier from its spot.
const CALM_SPREAD := 1.4
## How far a citizen with a routine mills about the place it is at (its anchor).
const PLACE_SPREAD := 0.6
const POST_SPREAD := 0.35
## How far around its feet (ground units) a person looks for buildings it might be drawn against. A building
## further away cannot overlap it on screen.
const SORT_REACH := 3.0
## How often a person re-reads its draw order. 160 people against the buildings around each of them is real
## work; ten times a second is plenty for someone walking under two units a second.
const SORT_HZ := 10.0
## A person's sprite on screen, relative to its feet: wide enough for a spear, tall enough for a helmet.
const SPRITE_BOX := Rect2(-6.0, -18.0, 12.0, 19.0)
## People sprites: rows above the feet that stay with the legs when a laser cuts a person in two.
const SPRITE_WAIST := 7.0
## Where the watchman's lantern hangs beside his sprite (v0.08), facing right: its iron cap, from his ground point,
## against the side of the coat at the leading hand; mirrored facing left. The sprite's arms swing within its frames
## (they do not rise as the procedural ones do when running), so the lantern stays put.
const SPRITE_LANTERN := Vector2i(3, -8)
## Where the Mayor's chain lies across the stand-in sprite's chest, and the noble's crown sits on its head, from the
## ground point: the chain's left pixel (3 across), and the crown's x and y for _draw_crown() (a 5x1 band under 3 points).
const SPRITE_CHAIN := Vector2i(-1, -10)
const SPRITE_CROWN := Vector2i(-1, -17)
## _sprite_signature()'s multipliers folded for its quiet case: past the frame, the tumble, lift, frost and flash terms
## (1024 * 97^3) and the state's 7; after the height, the swirl, cough, stage and whisper terms.
const SIG_SPRITE_QUIET := 1024 * 97 * 97 * 97 * 7
const SIG_SPRITE_OVERLAYS := 9 * 5 * (SICK_STAGES + 1) * 2
## A lightning hit's blue flash (DummyEnemy._tint's).
const COL_LIGHTNING_FLASH := Color("5aa8ff")
## Drawn above a building's footprint: its height plus a roof or battlements (HouseArt.RISE_MAX and a chimney).
const ROOF_MARGIN := 40.0
## Each person's speed is scaled by a pace drawn from this range, so a crowd is not a marching column.
const PACE_RANGE := Vector2(0.85, 1.2)
## One panicked dash: how far (ground units), and how far it may veer from straight away (radians).
const DASH := Vector2(1.6, 3.2)
const DASH_VEER := 0.6
## While its route out is being planned a fleeing person scurries in hops this long, without path-finding.
const SCURRY := 0.9
## Chance per think that a running person stumbles, and how long they are down for.
const STUMBLE_CHANCE := 0.006
const STUMBLE_SECONDS := 0.45

const CIT_SKIN := [Color("c89a72"), Color("b07a52"), Color("8a5a3a")]
const CIT_TUNIC := [Color("8a5a3a"), Color("6a6a4a"), Color("7a4a4a"), Color("4a5a6a"), Color("8a7a4a"), Color("6a5a7a")]
const CIT_HAIR := [Color("3a2a1a"), Color("5a4a2a"), Color("24201c"), Color("7a5a3a")]
const CIT_LEGS := Color("453c33")
## Minds a Will-o'-Wisp can draw (lure()).
const LURABLE := [Mind.CALM, Mind.RECOVER, Mind.OBSERVE, Mind.REGROUP]
## Discord (v0.06): a confused citizen ambles at this share of a walk, under a violet swirl.
const CONFUSED_PACE := 0.7
const COL_DISCORD := Color("b070ff")
## Mind Whisper (v0.08): the gold of the eye over a whispered citizen.
const COL_WHISPER := Color("f0d070")
## Mind Whisper (v0.08.1): seconds after a whisper wears off before the same person can be whispered to again. Counted
## from when it wore off: counted from the cast it changes nothing, as a messenger's whispers already come ~24 s apart.
const SHAKE_OFF := 20.0
## Pestilence (v0.06): the sick move at this share of their pace; SICK_MOTE is the green the targeting preview rings them in.
const SICK_PACE := 0.7
const SICK_MOTE := Color("a8d060")
## Pestilence (v0.07.1): the sick go through these colours as death nears, one for each of SICK_STAGES steps: bright
## green when caught, then yellow-green, amber, orange and red. Saturated, so they stay readable under the evening light.
const SICK_COLORS: Array[Color] = [Color("8ee04a"), Color("d8e040"), Color("f0b030"), Color("f07028"), Color("e8302c")]
const SICK_STAGES := 5
## How strongly the sickness colours the skin, and the clothes (and a soldier's mail).
const SICK_SKIN := 0.7
const SICK_CLOTH := 0.7
## A compulsion (Divine Congregation, and any Dominion power after it): one at least WILL_FIRM strong is not broken by
## an evacuation, a duty or a regrouping; one of WILL_ABSOLUTE or more is not broken even by a danger on top of it.
const WILL_FIRM := 0.75
const WILL_ABSOLUTE := 1.0
## Fighting (a maddened citizen's frenzy, a soldier engaging one): how far one looks for someone to go for, how near it
## must be to strike, how often it strikes and looks again, and a soldier's blow.
const FIGHT_SIGHT := 3.0
const FIGHT_REACH := 0.45
const FIGHT_SWING := 0.8
const FIGHT_RETARGET := 0.6
const SOLDIER_BLOW := 0.5
## Health, for blows (hurt()): a citizen falls to three frenzied blows, a soldier to twice as many.
const HEALTH_CITIZEN := 1.0
const HEALTH_SOLDIER := 2.0
## A Lantern Knight's (v0.10 M3): three times a soldier's.
const HEALTH_KNIGHT := HEALTH_SOLDIER * 3.0
## Whom a fighter may go for (fight()): anyone near (a maddened frenzy); only hostiles, the fighting citizens (a
## soldier engaging one); only its given target, the fight ending with it (Voice of God's Judge); only the other side
## (Divine Schism); only its own kind, soldier against soldiers and citizen against citizens (Turncoat); only those of
## one kind, `fight()`'s `kind` (Manufactured Hatred).
enum FightRule { ANYONE, HOSTILES, TARGET_ONLY, OTHER_SIDE, OWN_KIND, OF_KIND }
## A mark's glyph: five rows of five bits, the top row first. The diamond is a compulsion's own.
const GLYPH_DIAMOND: Array[int] = [0b00100, 0b01110, 0b11111, 0b01110, 0b00100]
const COL_MARK_EDGE := Color(0.12, 0.08, 0.02)
## The marks' place in the redraw signature: above the walk frames and the sickness (SIG_WALK * 64 clears both).
const SIG_MARK := SIG_WALK * 64
## The town's responders dress for their duty (v0.05), so the player can pick them out: clergy in a cream robe with a
## gold stole, engineers in a leather apron and cap with a hammer, the bellkeeper in a navy coat with a brass badge.
const CLERGY_ROBE := Color("e4dcc4")
const CLERGY_STOLE := Color("d8b23a")
const ENG_APRON := Color("5a3a22")
const ENG_CAP := Color("c08a3a")
const ENG_HAFT := Color("6b4428")
const ENG_IRON := Color("a0a6ae")
const KEEPER_COAT := Color("2c3a5c")
const KEEPER_BADGE := Color("e0b84a")
## The watchman (v0.08): a dark cloak, and a lit lantern in his leading hand.
const WATCH_CLOAK := Color("2a2630")
const WATCH_LANTERN := Color("ffd27a")
## The Mayor (v0.09): a dark red robe and a gold chain of office. The Prince's noble: a purple cape and a gold crown.
const MAYOR_ROBE := Color("7a1e22")
const MAYOR_CHAIN := Color("e0b84a")
const NOBLE_CAPE := Color("4a2a6a")
const NOBLE_CROWN := Color("e8c24a")
const SOL_MAIL := Color("6a6f78")
const SOL_MAIL_HI := Color("8d939c")
const SOL_HELM := Color("484d56")
const SOL_TABARD := Color("1f3f8a")
const SOL_SHIELD := Color("2f5cc0")
const SOL_GOLD := Color("d8b23a")
const SOL_HAFT := Color("5a4a3a")
const SOL_TIP := Color("b8bcc4")
## The roles' looks (v0.07): a red tabard for a marshal, a white one for an escort, and a shovel for a rescue squad.
const SOL_MARSHAL := Color("a02424")
const SOL_ESCORT := Color("e4e0d6")
const SOL_SHOVEL := Color("8a8e96")
## A Lantern Knight's gold tabard (v0.10 M3).
const SOL_KNIGHT := Color("e0b84a")

var mind := Mind.CALM
var soldier := false
## A soldier's role (v0.07; Crowd._assign_corps()) and the post it was given at spawn, which it goes back to.
var corps := Corps.NONE
var post := Vector2.INF
## A soldier sent somewhere at a run (v0.07: escorts, marshals, rescue squads); send_to_post() sets it.
var hurrying := false
## Home for a citizen, posted spot for a soldier: where it drifts around when it has nowhere to be.
var anchor := Vector2.ZERO
## A citizen's role and the places of its day (Crowd sets it; null for soldiers and people made on their own).
var profile: CitizenProfile
## Its routine (RoutineManager): seconds left at the place it is at, and the kind of place it last went to.
var stay_left := 0.0
var last_place := -1
## Its way out (v0.04): the crowd's EvacuationManager (citizens only), when it last chose, and seconds left showing
## the reroute.
var evac: EvacuationManager
## Fighting a fire (v0.04 P1; FireManager runs the round): the burning building, whether it is at the water or
## carrying a full bucket, and seconds left filling or dousing.
var assist_fire: Structure
var assist_at_water := false
var assist_full := false
var assist_wait := 0.0
## Kept on its fire through the evacuation (v0.08.2): an engineer, who works on while the town leaves, unlike the
## fire brigade.
var assist_stays := false
## On an engineer team while the engineers are out (v0.09.1; EngineerManager sets it): a fright or a shelter never sends it
## to the gates for good, it goes back to its team once calm. Cleared when its team stands down (Crowd.off_duty()).
var engineer_duty := false
## Taking cover (v0.04 P2; ShelterManager runs it): the crowd's manager, the building sought or sheltered in, its
## door, and whether it is inside (hidden, out of every effect's reach, not stepped).
var shelters: ShelterManager
var shelter: Structure
var shelter_door := Vector2.INF
var inside := false
var route_since := -INF
var rerouting := 0.0
var grid: WalkGrid
## The city's water (CityDef.rivers()), read again whenever the city changes: nobody steps off dry ground into it
## (_step_blocked()).
static var _rivers: Array[Rect2] = []
static var _rivers_of: CityDef
## Seconds this person must stand still (a gate queue sets it every frame it holds someone back).
var wait := 0.0
## This person's spot in a gate's waiting crowd, or Vector2.INF. While set, it walks there and stands; the gate
## clears it (release_from_queue) when it lets the person through or the person leaves the crowd.
var queue_spot := Vector2.INF
## Crowd clock time this person joined its gate's queue, so _gates() can order the crowd by who has waited
## longest -- immune to the spots array's own distance-to-face ordering, which zig-zags between the two sides
## of a row and so is not itself a stable left-to-right order to sort by. Negative while not queued.
var queue_since := -1.0
## The gate this person was just released from and is walking to, or null. Set by the gate itself
## (release_from_queue() only clears queue_spot); cleared once it is through, dead, no longer fleeing, or has
## wandered too far off to still be "on its way out". While set, this person does not rejoin that gate's
## waiting crowd, even though it is not the only one with a pass any more.
var passing_gate: Structure = null
## The field of buildings, for sorting against them. Null in tests that build a person without a town.
var env: EnvironmentField
## This person's own speed multiplier, drawn from PACE_RANGE, so a crowd is not a marching column.
var pace := 1.0
## Seconds until the next draw-order reading, staggered by instance so a crowd does not all re-sort together.
var _sort_in := 0.0
## Where the last reading was taken, and the field's destroy_epoch then.
var _sort_feet := Vector2.INF
var _sort_epoch := -1
## Draw-order candidates per SORT_CELL cell (see _sort_candidates()), for the field and layout they were built from.
static var _sort_cells := {}
static var _sort_cells_env: EnvironmentField
static var _sort_cells_epoch := -1
const SORT_CELL := 0.5
## Where the fright came from, so a dash and a scurry run away from it, and its radius.
var _threat := Vector2.INF
var _threat_r := 1.0
var awareness := Awareness.UNAWARE
var _observe_left := 0.0
## Pestilence (v0.06): seconds left to live, sick; 0 is healthy (PlagueManager spreads it and ends it).
var sick_left := 0.0
## Pestilence (v0.07.1): the seconds the sickness ran in all, from infect(), to tell how far along it is.
var sick_total := 0.0
## Discord (v0.06): seconds of confusion left, and whether it was fleeing when it struck.
var _confused_left := 0.0
var _was_fleeing := false
## Discord's swirl is drawn over a confused head unless the confusion was given without it (a maddened wander).
var _confused_swirl := true
## A compulsion (Mind.COMPELLED, Intent.GATHER): seconds left, how strongly it holds (WILL_*), and the mark worn over
## the head. Generic: the power that lays it says where, how long and how firmly.
var _compel_left := 0.0
var compel_will := 0.0
var compel_mark := Color(1.0, 0.85, 0.4)
## Fighting (Mind.FIGHT, Intent.FRENZY): seconds left, the one gone for (null: whoever is nearest), the blow dealt, and
## the timers. A soldier engaging the maddened picks only among hostiles; a frenzied citizen goes for anyone.
var fight_target: Person
var _fight_left := 0.0
var _fight_blow := 0.34
var _swing_in := 0.0
var _retarget_in := 0.0
var _fight_rule := FightRule.ANYONE
var _fight_sight := FIGHT_SIGHT
var _fight_kind := &""
## Seconds left of fearing nothing (Rewrite Priority's Ignore, Collective Delusion's All Is Well): no danger frightens
## it, nothing makes it look, no evacuation calls it; and whether it was fleeing when reassured, to flee again after.
var fearless_left := 0.0
var _reassured_fled := false
## The side it has been set on (Divine Schism; 0: none): under FightRule.OTHER_SIDE a fighter goes for the other one.
var side := 0
## A compulsion's pace (a run: Voice of God's Flee), its pose (&"kneel") and its mark's glyph.
var _compel_run := false
var compel_pose := &""
var compel_glyph: Array[int] = GLYPH_DIAMOND
## A badge over the head (a side's mark, the silenced, the condemned): its glyph, its colour, the seconds it has left.
var badge_glyph: Array[int] = GLYPH_DIAMOND
var badge_color := Color.WHITE
var badge_left := 0.0
## Health, for blows (hurt()); set by setup_person().
var health := HEALTH_CITIZEN
## Named statuses a power lays on a person (a Disorder power's madness, 0..1), by name. The manager that lays one
## reads and steps it; the person only carries it, and responds to what the manager asks of it.
var statuses := {}
## The field this person is in, for blows that kill (null for one made on its own).
var field: EnemyField
## Mind Whisper (v0.08): seconds of lingering left once it has arrived, and whether it fled before (or must flee after).
var _whisper_left := 0.0
var _whisper_fled := false
## Mind Whisper (v0.08.1): seconds left of shaking the last whisper off (see SHAKE_OFF); 0 for anyone never whispered.
## Counted down in tick(), so it runs on at any thinking rate, off screen or held still.
var _shaken_left := 0.0
## Seconds left face-down after a stumble; see is_stumbling().
var _stumble := 0.0
## Drawing state for the people sprites (PeopleArt), never read by the brain: it stepped this tick, the step went
## toward the back of the screen (a back view), and which of a role's two looks it wears (hashed from its home or
## post, never drawn from rng; -1 until first drawn).
var _stride := false
var _back := false
var _look := -1.0
## The design _design() picked, its PeopleArt.info() table, and what it was picked for (manifest load, role, corps).
var _design_key := -1
var _design_name := ""
var _design_info: Array

var _path := PackedVector2Array()
var _leg := 0
var _goal := Vector2.INF
var _panic_left := 0.0
var _repath_in := 0.0
var _skin := Color.WHITE
var _tunic := Color.WHITE
var _hair := Color.WHITE
## Flips every eligible tick(): half the crowd starts true and half false (see setup_person), so _think()
## calls spread evenly across frames instead of the whole crowd thinking on the same frame and idling on the
## next. A per-instance toggle rather than a global frame count, so it alternates correctly however tick() is
## driven (real per-frame play, or a test calling it directly in a tight loop).
var _think_due := true
## Seconds since the last _think() call; handed to it as its delta so timers (wait, _panic_left, _repath_in)
## still decay in real time despite thinking at half rate.
var _think_accum := 0.0
## Time a person has not been updated for (off screen, or unhurried on it), handed to its next update (see frame()).
var _offscreen_delta := 0.0

## What the camera shows, in world (screen) pixels, grown by a margin; set every frame by the Battlefield. An
## empty rect (headless tests, before the first frame) counts everyone as seen.
static var view := Rect2()
## An off-screen person is updated every this many frames, with the time it skipped. Most of the town is off
## screen at play zoom, and nobody can see a stride or a light reading there.
const OFFSCREEN_EVERY := 3
## The rate in play: the city's (CityDef.offscreen_every(), set by Crowd.setup()); Aldermere's is OFFSCREEN_EVERY.
static var offscreen_every := OFFSCREEN_EVERY
## The frame count the LOD staggers by: the engine's (-1), or one a test sets, since the test runner never advances frames.
static var frame_no := -1

## On screen, a calm citizen or a soldier at his post is updated every this many frames, with the time it skipped:
## they amble or stand, and a step every other frame does not show. With ~100 people on screen at the market this
## halves most of the crowd's cost there. Anyone frightened, fleeing, knocked, pulled, stumbling or held at a gate
## is updated every frame.
const CALM_EVERY := 2
## DummyEnemy._art_signature()'s multipliers for its walk step and its state, when every term between is zero.
const SIG_WALK := 1024 * 97 * 97 * 97 * 97 * 131 * 7
const SIG_STATE := 131 * 7
## Whether the camera showed this person when its frame began (see view).
var _seen := true
## Stepped by its crowd's ticker (Crowd.step_people) rather than processing on its own: one engine call per
## person every frame was a measurable share of a person's cost.
var ticked := false
## This person's place in its crowd's spawn order (Crowd sets it; -1 for one made on its own). The crowd staggers
## its thinking, light readings and off-screen updates by it. By instance id they shifted with any unrelated change
## that made one object more or fewer, which made the crowd's runs impossible to compare across changes.
var stagger := -1


## What the crowd staggers by: the spawn order, or the instance id for a person made on its own.
func stagger_key() -> int:
	return stagger if stagger >= 0 else get_instance_id()


## `at` is where it stands and what it treats as home (or its post). Seed `rng` before calling this.
func setup_person(is_soldier: bool, at: Vector2, w: WalkGrid) -> Person:
	soldier = is_soldier
	grid = w
	anchor = at
	ground_pos = at
	mind = Mind.POST if is_soldier else Mind.CALM
	health = HEALTH_SOLDIER if is_soldier else HEALTH_CITIZEN
	_think_due = stagger_key() % 2 == 0
	_skin = CIT_SKIN[rng.randi() % CIT_SKIN.size()]
	_tunic = CIT_TUNIC[rng.randi() % CIT_TUNIC.size()]
	_hair = CIT_HAIR[rng.randi() % CIT_HAIR.size()]
	pace = rng.randf_range(PACE_RANGE.x, PACE_RANGE.y)
	_pick_target()
	return self


func _in_view() -> bool:
	return _seen


func _ready() -> void:
	super()
	if stagger >= 0:
		_light_in = float(stagger % 16) / (LIGHT_HZ * 16.0)
	if ticked:
		set_process(false)


func _process(delta: float) -> void:
	frame(delta)


## One frame of this person: the camera check, the off-screen throttle, the tick, then the light and the redraw
## check. A crowd's people are stepped by its ticker instead of processing one by one (see ticked).
func frame(delta: float) -> void:
	# Looked up once a frame: the base unit and the brain both ask.
	_seen = not view.has_area() or view.has_point(position)
	var every := 1
	if not _seen:
		# The city's slower rate is for the unhurried only: anyone fleeing, frightened or knocked off screen keeps
		# OFFSCREEN_EVERY (at 6 the capital's fleeing jammed at its gates, Task 14).
		every = offscreen_every if offscreen_every != OFFSCREEN_EVERY and unhurried() else OFFSCREEN_EVERY
	elif unhurried():
		every = CALM_EVERY
	if every > 1:
		_offscreen_delta += delta
		if ((frame_no if frame_no >= 0 else Engine.get_process_frames()) + stagger_key()) % every != 0:
			return
		delta = _offscreen_delta
		_offscreen_delta = 0.0
	elif _offscreen_delta > 0.0:
		delta += _offscreen_delta
		_offscreen_delta = 0.0
	BenchProf.count(&"people_ticked")
	tick(delta)
	_refresh(delta)


## Calm or at a post, wandering, and nothing holding or tripping it (a soldier hurrying to its post is not): updated at
## CALM_EVERY on screen.
func unhurried() -> bool:
	var calm := mind == Mind.CALM or mind == Mind.POST or mind == Mind.OBSERVE or mind == Mind.RECOVER \
		or mind == Mind.REGROUP or mind == Mind.COMPELLED
	return calm and state == State.WANDER and not is_frozen() and _stumble <= 0.0 and wait <= 0.0 and not hurrying


# --- Brain -------------------------------------------------------------------

func tick(delta: float) -> void:
	if _shaken_left > 0.0:
		_shaken_left = maxf(_shaken_left - delta, 0.0)
	if state == State.WANDER and not is_frozen():
		_think_accum += delta
		if _think_due:
			_think(_think_accum)
			_think_accum = 0.0
		_think_due = not _think_due
	var before := ground_pos
	super(delta)
	_track_stride(ground_pos - before)


## For the people sprites only: whether it stepped this tick, and whether toward the back of the screen.
func _track_stride(d: Vector2) -> void:
	_stride = d.length_squared() > 1e-10
	if _stride and absf(d.x + d.y) > 1e-6:
		_back = d.x + d.y < 0.0


func _think(delta: float) -> void:
	if badge_left > 0.0:
		badge_left = maxf(badge_left - delta, 0.0)
	if fearless_left > 0.0:
		fearless_left = maxf(fearless_left - delta, 0.0)
		if fearless_left <= 0.0 and _reassured_fled:
			# The false calm wears off, and the town is still leaving.
			_reassured_fled = false
			if mind == Mind.CALM or mind == Mind.RECOVER:
				mind = Mind.CALM
				flee()
	_repath_in = maxf(_repath_in - delta, 0.0)
	# A path can run out short of the goal: the goal sits inside a building, the way changed under us (a
	# bridge fell), or an effect threw us off it. Whatever the mind, drop the goal so it can plan a new one.
	# Checked even while held at a gate: otherwise a citizen whose path ran out inside gate range can only
	# recover by chance, when it happens to become that gate's leader.
	if _goal != Vector2.INF and _path.is_empty() and _repath_in <= 0.0 \
			and ground_pos.distance_to(_goal) > GOAL_REACH:
		_goal = Vector2.INF
		_repath_in = 0.3
	if wait > 0.0:
		# Held in a gate queue: stand still, but keep the fright timer running.
		wait = maxf(wait - delta, 0.0)
		_panic_left = maxf(_panic_left - delta, 0.0)
		_idle = maxf(_idle, 0.05)
		return
	if _stumble > 0.0:
		_stumble = maxf(_stumble - delta, 0.0)
		_idle = maxf(_idle, 0.05)
		return
	if is_running() and not soldier and rng.randf() < STUMBLE_CHANCE:
		_stumble = STUMBLE_SECONDS
		return
	if queue_spot != Vector2.INF:
		# Waiting at a gate: shuffle to this spot in the crowd and stand. The fright keeps ticking.
		_panic_left = maxf(_panic_left - delta, 0.0)
		walk_speed = WALK_SPEED * pace
		if ground_pos.distance_to(queue_spot) > 0.06:
			_target = queue_spot
			_idle = 0.0
		else:
			_idle = maxf(_idle, 0.1)
		return
	walk_speed = _mind_speed()
	rerouting = maxf(rerouting - delta, 0.0)
	if mind == Mind.PANIC:
		_panic_left -= delta
		if _panic_left <= 0.0:
			_settle()
	elif mind == Mind.OBSERVE:
		_observe_left -= delta
		if _goal == Vector2.INF:
			_idle = maxf(_idle, 0.1)  # stands and looks; one drawn by a wisp (lure()) walks there first
		if _observe_left <= 0.0:
			_recover(rng.randf_range(1.0, 3.0))
	elif mind == Mind.CONFUSED:
		_confused_left -= delta
		if _confused_left <= 0.0:
			_come_to()
	elif mind == Mind.COMPELLED:
		_compel_left -= delta
		if _goal == Vector2.INF:
			_idle = maxf(_idle, 0.1)  # gathered: stands where it was drawn to
		if _compel_left <= 0.0:
			release_compulsion()
	elif mind == Mind.FIGHT:
		_fight_left -= delta
		if _fight_left <= 0.0:
			stop_fighting()
		else:
			_fight_step(delta)
	elif mind == Mind.WHISPERED:
		if _goal == Vector2.INF:
			# There (or as near as the way allowed): stand and linger.
			_idle = maxf(_idle, 0.1)
			_whisper_left -= delta
			if _whisper_left <= 0.0:
				_wake()
	match mind:
		Mind.FLEE:
			if _goal == Vector2.INF:
				if _repath_in <= 0.0:
					_plan_exit()
				elif ground_pos.distance_to(_target) < 0.1:
					_scurry()
		Mind.POST, Mind.RALLY:
			if _goal == Vector2.INF and _repath_in <= 0.0 and ground_pos.distance_to(anchor) > GOAL_REACH * 2.0:
				set_goal(anchor)
		Mind.CALM:
			# A citizen with a day of its own goes where RoutineManager sends it; one made on its own strolls.
			if profile == null and _goal == Vector2.INF and rng.randf() < STROLL_CHANCE:
				set_goal(City.current().landmark(&"market_square").get_center() if rng.randf() < 0.5 else anchor)
		Mind.HOLD:
			_idle = maxf(_idle, 0.2)
	_sort_in -= delta
	# Off screen, who stands in front of whom shows nobody; the view's margin updates it before it can.
	if env != null and _sort_in <= 0.0 and _in_view():
		_sort_in = 1.0 / SORT_HZ + float(stagger_key() % 7) * 0.001
		# Standing where it stood, with no building fallen since, the answer cannot have changed.
		if ground_pos != _sort_feet or env.destroy_epoch != _sort_epoch:
			_sort_feet = ground_pos
			_sort_epoch = env.destroy_epoch
			sort_bias = sort_bias_for(ground_pos, _sort_candidates(), SORT_REACH)


func _mind_speed() -> float:
	# A status may slow it too (Death Mark's "slow": the share of its pace it keeps).
	return _base_speed() * (SICK_PACE if sick_left > 0.0 else 1.0) * float(statuses.get(&"slow", 1.0))


func _base_speed() -> float:
	match mind:
		Mind.PANIC, Mind.RALLY:
			return PANIC_SPEED * pace
		Mind.RECOVER:
			return WALK_SPEED * RECOVER_PACE * pace
		Mind.ASSIST:
			return WALK_SPEED * ASSIST_PACE * pace
		Mind.SHELTER, Mind.DUTY:
			return PANIC_SPEED * pace
		Mind.CONFUSED:
			return WALK_SPEED * CONFUSED_PACE * pace
		Mind.COMPELLED:
			return (FLEE_SPEED if _compel_run else WALK_SPEED) * pace
		Mind.FLEE, Mind.FIGHT:
			return FLEE_SPEED * pace
		_:
			return PANIC_SPEED * pace if mind == Mind.POST and hurrying else WALK_SPEED * pace


## Whether it is on its way somewhere (a goal it has not reached).
func has_goal() -> bool:
	return _goal != Vector2.INF


## Whether the path ahead (the waypoint it is walking to and the `ahead` after it) runs through `r`.
func path_crosses(r: Rect2, ahead: int) -> bool:
	for k in range(maxi(_leg - 1, 0), mini(_leg + ahead, _path.size())):
		if r.has_point(_path[k]):
			return true
	return false


## Walk to `g` along the grid's path. A goal inside a building routes to its doorstep.
func set_goal(g: Vector2) -> void:
	_goal = g
	_leg = 0
	_path = grid.path(ground_pos, g) if grid != null else PackedVector2Array()
	_repath_in = REPATH
	_idle = 0.0
	_pick_target()


## Let a waiting person go: leave its spot and pick its route up again from where it stands (the waypoint it
## was heading for when it joined the crowd may now be behind it).
func release_from_queue() -> void:
	if queue_spot == Vector2.INF:
		return
	queue_spot = Vector2.INF
	queue_since = -1.0
	if _goal != Vector2.INF:
		set_goal(_goal)


## Next waypoint, or a drift around the anchor when there is nothing to walk to. DummyEnemy calls this
## whenever it reaches its current target.
func _pick_target() -> void:
	if queue_spot != Vector2.INF:
		_target = queue_spot
		return
	if is_running():
		# DummyEnemy.tick() just set _idle before calling us, to pause at every target it reaches. That
		# suits a calm stroll but not a sprint: cancel it so a runner never stops between waypoints.
		_idle = 0.0
	while _leg < _path.size():
		var p := _path[_leg]
		_leg += 1
		if grid != null and not grid.walkable(p):
			# The way closed under us (the bridge fell, a wall's rubble shifted the grid): drop the plan and
			# let the mind make a new one instead of walking through it.
			_goal = Vector2.INF
			_repath_in = 0.0
			break
		if ground_pos.distance_to(p) > 0.08:
			# The base unit's pause after every target, applied to a path of half-unit grid waypoints, turns
			# every walk into stop-and-go; nobody (calm or not) should stall mid-path, only on arrival.
			_idle = 0.0
			_target = p
			return
	_path = PackedVector2Array()
	_leg = 0
	if _goal != Vector2.INF and ground_pos.distance_to(_goal) > GOAL_REACH:
		# Out of waypoints but not there: hold position until the next plan.
		_target = ground_pos
		_repath_in = minf(_repath_in, 0.3)
		return
	_goal = Vector2.INF
	if mind == Mind.PANIC:
		_settle()
		return
	if mind == Mind.OBSERVE or mind == Mind.ASSIST or mind == Mind.SHELTER or mind == Mind.DUTY \
			or mind == Mind.WHISPERED or mind == Mind.COMPELLED or mind == Mind.FIGHT:
		_target = ground_pos
		return
	if mind == Mind.FLEE:
		_scurry()
		return
	if mind == Mind.POST and ground_pos.distance_to(anchor) <= GOAL_REACH * 2.0:
		# At its post (the reach _think() re-paths beyond): shifting about it is at a walk again. A goal dropped short of
		# the post (the way closed) is not an arrival: the re-path keeps the run.
		hurrying = false
	_drift()


## A small aimless step: citizens milling about their street, soldiers shifting at their post.
func _drift() -> void:
	var spread := POST_SPREAD
	if mind == Mind.CALM or mind == Mind.RECOVER or mind == Mind.REGROUP or mind == Mind.CONFUSED:
		spread = CALM_SPREAD if profile == null else PLACE_SPREAD
	var to := anchor + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
	if grid != null:
		var free := grid.nearest_walkable(to, 3)
		to = free if free != Vector2.INF else ground_pos
	_target = to


# --- What the town does to a person ------------------------------------------

## A danger of radius `radius` at `from` is on top of it: run clear of it, to LOCAL_FLEE beyond its edge, then
## wait and go back to its day (_settle()). Not to a gate: evacuation is the staged alarm's call. Soldiers do not.
func panic(from: Vector2, radius := 1.0, kind := &"") -> void:
	if soldier or mind == Mind.FLEE or mind == Mind.SHELTER or inside or state == State.DEAD or mind == Mind.FIGHT:
		return
	if held_by_will(WILL_ABSOLUTE) or fearless_left > 0.0:
		return  # a Dominion stronger than fear, or a mind that has been told there is nothing to fear
	# A sturdy building nearby may be better than running (ShelterManager).
	if shelters != null and mind != Mind.PANIC and shelters.try_shelter(self, from, radius, kind):
		awareness = Awareness.THREATENED
		return
	mind = Mind.PANIC
	awareness = Awareness.THREATENED
	# Set here, not left for the next _think(): that can be a frame away now that thinking is half-rate, and a
	# jolt should visibly speed someone up the instant it lands, not on a coin-flip frame.
	walk_speed = _mind_speed()
	_panic_left = PANIC_SECONDS
	_threat = from
	_threat_r = radius
	_flee_local()


## Something happened within sight or earshot at `from`: stop and look at it for a moment. Only a calm or recovering
## citizen does; the frightened and the fleeing are past looking. A positive `seconds` sets how long (v0.08: the
## watchman staring at the falling star), else it is OBSERVE_SECONDS at random.
func observe(from: Vector2, seconds := -1.0) -> void:
	if soldier or state == State.DEAD or not (mind == Mind.CALM or mind == Mind.RECOVER) or fearless_left > 0.0:
		return
	mind = Mind.OBSERVE
	awareness = maxi(awareness, Awareness.CONCERNED) as Awareness
	_threat = from
	_observe_left = seconds if seconds > 0.0 else rng.randf_range(OBSERVE_SECONDS.x, OBSERVE_SECONDS.y)
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_target = ground_pos
	walk_speed = _mind_speed()


## Pestilence (v0.06): catch the plague, with `seconds` to live. Soldiers too (v0.07.1); the dead and the already sick
## do not.
func infect(seconds: float) -> bool:
	if state == State.DEAD or sick_left > 0.0:
		return false
	sick_left = seconds
	sick_total = seconds
	walk_speed = _mind_speed()
	return true


## Pestilence (v0.07.1): 0 when healthy, else 1..SICK_STAGES by how much of the sickness has run.
func sick_stage() -> int:
	if sick_left <= 0.0 or state == State.DEAD:
		return 0
	var run := 1.0 - sick_left / maxf(sick_total, 0.001)
	return clampi(1 + int(run * float(SICK_STAGES)), 1, SICK_STAGES)


## Pestilence (v0.07.1): the sickness's colour now, green when caught to red near death; white when healthy.
func sick_color() -> Color:
	var stage := sick_stage()
	return SICK_COLORS[stage - 1] if stage > 0 else Color.WHITE


## Discord (v0.06): forget everything for `seconds` -- duty, the day, even the way out -- and amble about where it
## stands under a violet swirl; then pick up again (flee if it was fleeing, else back to its day, where a responder's
## manager takes it back). A fright still works on it.
func confuse(seconds: float, swirl := true) -> void:
	if soldier or inside or state == State.DEAD:
		return
	_was_fleeing = mind == Mind.FLEE
	_confused_swirl = swirl
	release_from_queue()
	passing_gate = null
	mind = Mind.CONFUSED
	_confused_left = seconds
	anchor = ground_pos
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	walk_speed = _mind_speed()
	_drift()


## The confusion lifts.
func _come_to() -> void:
	_confused_left = 0.0
	if _was_fleeing:
		mind = Mind.CALM
		flee()
	else:
		_recover(rng.randf_range(1.0, 2.0))


## Drawn by a Will-o'-Wisp (v0.06): walk to `at` and stand staring at the light for `seconds` (the watching mind,
## with a walk first), then back to its day. Only a citizen going about its day, watching, recovering or regrouping
## comes; true when it did.
func lure(at: Vector2, seconds: float) -> bool:
	if soldier or inside or state == State.DEAD or not mind in LURABLE:
		return false
	mind = Mind.OBSERVE
	awareness = maxi(awareness, Awareness.CONCERNED) as Awareness
	_threat = at
	_observe_left = seconds
	walk_speed = _mind_speed()
	set_goal(at)
	return true


## Mirrorfold Passage: set down at `to` (or the nearest ground to it) in mid-stride and none the wiser. Its mind is
## untouched; it walks on to wherever it was going -- its goal, or the step it was taking -- by a new path from where
## it now stands. A place held in a gate's queue is let go: the gate takes it back when it comes round again. False
## when it is inside somewhere or there is no ground there.
func fold(to: Vector2) -> bool:
	if inside or state == State.DEAD:
		return false
	if grid != null and not grid.walkable(to):
		to = grid.nearest_walkable(to, 4)
		if to == Vector2.INF:
			return false
	var bound := _goal if _goal != Vector2.INF else _target
	queue_spot = Vector2.INF
	queue_since = -1.0
	ground_pos = to
	_sync_position()
	set_goal(bound)
	return true


# --- Generic status and intent modifiers (Dominion, Disorder) ---------------------

## Whether a compulsion of at least `level` holds this person now.
func held_by_will(level: float) -> bool:
	return mind == Mind.COMPELLED and compel_will >= level


## A compulsion (Divine Congregation): walk, as if of its own mind, to `spot` and stay there `seconds`, held by
## `will` (WILL_FIRM keeps it through an evacuation; WILL_ABSOLUTE through a danger on top of it), with `mark` over
## the head (`glyph`). `run` makes it a run, `pose` (&"kneel") how it holds itself. A place in a gate's queue is given
## up, and a fight dropped. True when it took.
func compel(spot: Vector2, seconds: float, will: float, mark: Color, run := false, pose := &"",
		glyph: Array[int] = GLYPH_DIAMOND) -> bool:
	if inside or state == State.DEAD:
		return false
	fight_target = null
	_fight_left = 0.0
	_compel_run = run
	compel_pose = pose
	compel_glyph = glyph
	release_from_queue()
	passing_gate = null
	queue_spot = Vector2.INF
	queue_since = -1.0
	mind = Mind.COMPELLED
	_compel_left = seconds
	compel_will = will
	compel_mark = mark
	_panic_left = 0.0
	anchor = spot
	walk_speed = _mind_speed()
	set_goal(spot)
	return true


## The compulsion lifts: a soldier goes back to its post, anyone else looks about for a moment and then takes up
## its day again (the routine decides where; nothing of what it meant to do before is forced on it).
func release_compulsion() -> void:
	if mind != Mind.COMPELLED:
		return
	_compel_left = 0.0
	compel_will = 0.0
	_compel_run = false
	compel_pose = &""
	if soldier:
		send_to_post(post if post != Vector2.INF else ground_pos)
	else:
		_recover(rng.randf_range(1.0, 2.5))


## What it is, for the powers that tell people apart: a soldier, or its role's name (clergy, engineer, merchant...).
func kind() -> StringName:
	if soldier:
		return &"soldier"
	if profile != null:
		return StringName(CitizenProfile.Role.keys()[profile.role].to_lower())
	return &"citizen"


## Told there is nothing to fear, for `seconds` (Collective Delusion): whatever fright, flight or watching it was in is
## dropped and it goes back to its day; nothing frightens it meanwhile; and if it was leaving the town, it leaves again
## when the calm wears off.
func reassure(seconds: float) -> void:
	if inside or state == State.DEAD or soldier:
		return
	var fled := mind == Mind.FLEE
	fearless_left = maxf(fearless_left, seconds)
	_reassured_fled = _reassured_fled or fled
	if mind in [Mind.PANIC, Mind.FLEE, Mind.OBSERVE, Mind.REGROUP, Mind.RECOVER]:
		release_from_queue()
		passing_gate = null
		_recover(rng.randf_range(0.5, 1.5))


## Whatever holds this person now holds it `k` times as long (Magnify): confusion, a compulsion, a fight, fearing
## nothing, a whisper's linger, a panic, a badge; a sickness runs its course `k` times as fast. Generic: it knows no
## power by name. True when there was anything to magnify.
func magnify(k: float) -> bool:
	if inside or state == State.DEAD or k <= 0.0:
		return false
	var any := false
	if sick_left > 0.0:
		sick_left /= k
		any = true
	if _confused_left > 0.0:
		_confused_left *= k
		any = true
	if mind == Mind.COMPELLED and _compel_left > 0.0:
		_compel_left *= k
		any = true
	if mind == Mind.FIGHT and _fight_left > 0.0:
		_fight_left *= k
		any = true
	if fearless_left > 0.0:
		fearless_left *= k
		any = true
	if _whisper_left > 0.0:
		_whisper_left *= k
		any = true
	if _panic_left > 0.0:
		_panic_left *= k
		any = true
	if badge_left > 0.0:
		badge_left *= k
	return any


## A badge over the head for `seconds`: `glyph` in `color` (a side's mark, the silenced, the condemned).
func set_badge(glyph: Array[int], color: Color, seconds: float) -> void:
	badge_glyph = glyph
	badge_color = color
	badge_left = seconds


func clear_badge() -> void:
	badge_left = 0.0


## A moment's hesitation: stand, and turn to look the other way.
func hesitate(seconds: float) -> void:
	if state == State.DEAD:
		return
	_idle = maxf(_idle, seconds)
	_facing = -_facing


## Rooted to the spot for `seconds`, whatever it was doing (the gate queue's hold, used by a stun).
func stun(seconds: float) -> void:
	if state == State.DEAD:
		return
	wait = maxf(wait, seconds)


## Go for someone (Mind.FIGHT) for `seconds`, striking `blow` of their health each swing: `target` or, when null,
## whoever `rule` allows (FightRule) within `sight`. Ends on its own (stop_fighting()).
func fight(target: Person, seconds: float, blow: float, rule := FightRule.ANYONE, sight := FIGHT_SIGHT, kind := &"") -> void:
	if inside or state == State.DEAD:
		return
	release_from_queue()
	passing_gate = null
	mind = Mind.FIGHT
	fight_target = target
	_fight_left = seconds
	_fight_blow = blow
	_fight_rule = rule
	_fight_sight = sight
	_fight_kind = kind
	_swing_in = 0.0
	_retarget_in = 0.0
	_panic_left = 0.0
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	walk_speed = _mind_speed()


## The fight is over: a soldier back to its post, a citizen to come round where it stands.
func stop_fighting() -> void:
	if mind != Mind.FIGHT:
		return
	fight_target = null
	_fight_left = 0.0
	if soldier:
		send_to_post(post if post != Vector2.INF else ground_pos)
	else:
		_recover(rng.randf_range(2.0, 4.0))


## Whether `p` is someone a fighter may go for.
func _fightable(p: Person) -> bool:
	if p == null or p == self or not is_instance_valid(p) or not p.is_alive() or p.inside or not p.visible:
		return false
	match _fight_rule:
		FightRule.HOSTILES:
			# A fighting citizen, or a fighter set on another side (a soldier turned).
			return p.mind == Mind.FIGHT and (not p.soldier or p.side != side)
		FightRule.OWN_KIND:
			return p.soldier == soldier
		FightRule.OF_KIND:
			return p.kind() == _fight_kind
		FightRule.TARGET_ONLY:
			return p == fight_target
		FightRule.OTHER_SIDE:
			return p.side != 0 and p.side != side
	return true


## One frame of fighting: look again for someone every FIGHT_RETARGET, go to them, strike within FIGHT_REACH every
## FIGHT_SWING.
func _fight_step(delta: float) -> void:
	_retarget_in -= delta
	_swing_in -= delta
	if not _fightable(fight_target):
		if _fight_rule == FightRule.TARGET_ONLY:
			stop_fighting()  # the one it was set on is gone: nothing more to do
			return
		fight_target = null
	if fight_target == null or _retarget_in <= 0.0:
		_retarget_in = FIGHT_RETARGET
		# A frenzy turns on whoever is nearest now; the rest keep the one they have until it is gone.
		if field != null and (fight_target == null or _fight_rule == FightRule.ANYONE):
			var best: Person = fight_target
			var best_d := best.ground_pos.distance_to(ground_pos) if best != null else INF
			for e in field.in_radius(ground_pos, _fight_sight):
				var q := e as Person
				if _fightable(q) and q.ground_pos.distance_to(ground_pos) < best_d:
					best = q
					best_d = q.ground_pos.distance_to(ground_pos)
			fight_target = best
		if fight_target != null:
			# A new path only when they have moved: a street of fighters must not all ask for one every look.
			if _goal == Vector2.INF or _goal.distance_to(fight_target.ground_pos) > 0.75:
				set_goal(fight_target.ground_pos)
		elif _goal == Vector2.INF:
			_drift()
	if fight_target == null:
		return
	if ground_pos.distance_to(fight_target.ground_pos) <= FIGHT_REACH:
		_goal = Vector2.INF
		_path = PackedVector2Array()
		_leg = 0
		_target = ground_pos
		_facing = 1 if fight_target.ground_pos.x - fight_target.ground_pos.y > ground_pos.x - ground_pos.y else -1
		if _swing_in <= 0.0:
			_swing_in = FIGHT_SWING
			fight_target.hurt(_fight_blow, self)


## Struck for `amount` of health by `by`: a flash and a shove, and death (damage kind frenzy) at none left. A struck
## soldier turns on its attacker; a struck citizen runs from it.
func hurt(amount: float, by: Person) -> void:
	if state == State.DEAD:
		return
	health -= amount
	if statuses.has(&"frail"):
		health = 0.0  # the frail fall to any blow (Death Mark)
	flash(0.08)
	if by != null and is_instance_valid(by):
		var away := ground_pos - by.ground_pos
		knock((away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 1.2)
	if health <= 0.0:
		if field != null:
			field.kill(self, &"frenzy", by.ground_pos if by != null and is_instance_valid(by) else Vector2.INF)
		return
	if by == null or not is_instance_valid(by) or mind == Mind.FIGHT:
		return
	if soldier:
		fight(by, 20.0, SOLDIER_BLOW, FightRule.HOSTILES)
	else:
		panic(by.ground_pos, 0.5, &"frenzy")
## Mind Whisper (v0.08): drop whatever it was doing -- its day, a duty, an errand, even flight -- walk to `to` and
## linger there `linger` seconds under a gold glyph, then pick up again: flight if it was fleeing, else back to its day,
## where a duty's manager takes it back. Soldiers, anyone inside and the dead do not hear it, nor (v0.08.1) anyone still
## shaking the last one off; true when it did. One still under a whisper hears a new one -- the shake-off starts when
## it wears off -- and keeps the flight it owes.
func whisper(to: Vector2, linger: float) -> bool:
	if soldier or inside or state == State.DEAD or shaken():
		return false
	if mind != Mind.WHISPERED:
		_whisper_fled = mind == Mind.FLEE or (mind == Mind.CONFUSED and _was_fleeing)
	release_from_queue()
	passing_gate = null
	mind = Mind.WHISPERED
	_whisper_left = linger
	_confused_left = 0.0
	_panic_left = 0.0
	# Up from a stumble too: a whispered person never runs, so never stumbles, and the pose signatures count on it.
	_stumble = 0.0
	anchor = to
	walk_speed = _mind_speed()
	set_goal(to)
	return true


## Seconds of lingering left while whispered, else 0.
func whispered_left() -> float:
	return _whisper_left if mind == Mind.WHISPERED else 0.0


## Mind Whisper (v0.08.1): a whisper let it go less than SHAKE_OFF seconds ago, and another would not take.
func shaken() -> bool:
	return _shaken_left > 0.0


## The town is evacuating while it is whispered: it flees once the whisper wears off.
func whisper_resume_flee() -> void:
	_whisper_fled = true


## The whisper wears off: flight again if it fled before (or the town evacuated meanwhile), else back to its day. It
## shakes the whisper off for SHAKE_OFF seconds (v0.08.1).
func _wake() -> void:
	_whisper_left = 0.0
	_shaken_left = SHAKE_OFF
	if _whisper_fled:
		_whisper_fled = false
		mind = Mind.CALM
		flee()
	else:
		_recover(rng.randf_range(1.0, 2.0))


## Run to a walkable point LOCAL_FLEE beyond the threat's edge, straight away from it (or a dash when none is
## found).
func _flee_local() -> void:
	var away := ground_pos - _threat
	var dir := away.normalized() if away.length() > 0.01 else Vector2.RIGHT.rotated(rng.randf() * TAU)
	dir = dir.rotated(rng.randf_range(-DASH_VEER, DASH_VEER) * 0.5)
	var to := _threat + dir * (_threat_r + LOCAL_FLEE + rng.randf_range(0.0, LOCAL_FLEE_JITTER))
	if grid != null:
		var free := grid.nearest_walkable(to, 8)
		to = free if free != Vector2.INF else ground_pos
	if to.distance_to(ground_pos) <= GOAL_REACH:
		_dash()
		return
	set_goal(to)


## The flight is over: still inside the danger, run on; clear of it, wait where it is and then go back to its day.
func _settle() -> void:
	if ground_pos.distance_to(_threat) < _threat_r + THREAT_MARGIN and _panic_left > 0.0:
		_flee_local()
		return
	_recover(rng.randf_range(RECOVER_WAIT.x, RECOVER_WAIT.y))


## Wait `wait` seconds where it stands, then its routine picks up again (RoutineManager), steering clear of the
## ground the danger left.
func _recover(wait: float) -> void:
	mind = Mind.RECOVER
	_panic_left = 0.0
	anchor = ground_pos
	stay_left = wait
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	walk_speed = _mind_speed()
	_drift()


## Where it is walking to (Vector2.INF when nowhere).
func goal() -> Vector2:
	return _goal


## A better way out: head for `exit` instead (EvacuationManager, at its clock `now`).
func reroute(exit: Vector2, now: float) -> void:
	route_since = now
	rerouting = 1.0
	set_goal(exit)


## What it is trying to do (Intent), read from its mind.
func intent() -> Intent:
	if mind == Mind.FLEE and rerouting > 0.0:
		return Intent.REROUTE
	match mind:
		Mind.OBSERVE:
			return Intent.OBSERVE
		Mind.PANIC:
			return Intent.LOCAL_FLEE
		Mind.FLEE:
			return Intent.EVACUATE
		Mind.RECOVER:
			return Intent.RECOVER
		Mind.REGROUP:
			return Intent.REGROUP
		Mind.ASSIST:
			return Intent.ASSIST
		Mind.SHELTER:
			return Intent.SHELTER
		Mind.CONFUSED:
			return Intent.CONFUSED
		Mind.COMPELLED:
			return Intent.GATHER
		Mind.FIGHT:
			return Intent.FRENZY
		Mind.WHISPERED:
			return Intent.WHISPERED
	return Intent.ROUTINE


## Run to the door of `s` to take cover inside.
func seek_shelter(s: Structure, door: Vector2) -> void:
	mind = Mind.SHELTER
	shelter = s
	shelter_door = door
	walk_speed = PANIC_SPEED * pace
	set_goal(door)


## Out of cover (or giving up on it): to the gates if the town is evacuating, else back to its day. An engineer on its
## team goes back to it either way (v0.09.1).
func leave_shelter(evacuate: bool) -> void:
	shelter = null
	if evacuate and not engineer_duty:
		mind = Mind.CALM
		flee()
	else:
		_recover(rng.randf_range(2.0, 4.0))


## Turn out to fight the fire on `s` (FireManager sends it for water). A soldier only when sent by its rescue squad
## or its engineer team (force); `stays` keeps it on through the evacuation (an engineer, v0.08.2).
func assist(s: Structure, force := false, stays := false) -> void:
	if (soldier and not force) or state == State.DEAD or mind == Mind.FLEE or mind == Mind.FIGHT \
			or held_by_will(WILL_FIRM):
		return
	mind = Mind.ASSIST
	assist_fire = s
	assist_stays = stays
	assist_at_water = false
	assist_full = false
	assist_wait = 0.0
	walk_speed = _mind_speed()


## Stop fighting a fire: wait a moment, then back to its day (a soldier goes back to its post).
func stand_down() -> void:
	assist_fire = null
	assist_full = false
	assist_at_water = false
	assist_stays = false
	if mind == Mind.ASSIST:
		if soldier:
			send_to_post(post if post != Vector2.INF else ground_pos)  # a rescue squad back to its post (v0.07)
		else:
			_recover(rng.randf_range(2.0, 4.0))


## Walk to `g` and stand there (a responder's round).
func walk_to(g: Vector2) -> void:
	anchor = g
	set_goal(g)


## City Emergency (v0.04): go home to `home` and wait there with the family until the evacuation or the danger.
func regroup(home: Vector2) -> void:
	if soldier or state == State.DEAD or mind == Mind.FLEE or mind == Mind.FIGHT or held_by_will(WILL_FIRM) or fearless_left > 0.0:
		return
	mind = Mind.REGROUP
	awareness = maxi(awareness, Awareness.EMERGENCY) as Awareness
	anchor = home
	walk_speed = _mind_speed()
	set_goal(home)


## The bellkeeper's duty: walk to the Bell Tower's foot `steps` to climb it and ring the bell (BellNetwork).
func go_ring(steps: Vector2) -> void:
	go_duty(steps)


## A duty for the town (v0.05): run to `at` and stand there -- the bellkeeper at the tower's foot, a cleric at
## its place in the Banishing Rite's ring. A fright still breaks it (panic()); Crowd.off_duty() ends it.
## Soldiers take duties too (v0.07): an escort taking over the bell or an engineer's place.
func go_duty(at: Vector2) -> void:
	if state == State.DEAD or mind == Mind.FLEE or mind == Mind.FIGHT or held_by_will(WILL_FIRM):
		return
	mind = Mind.DUTY
	anchor = at
	walk_speed = _mind_speed()
	set_goal(at)


## A panicked dash: away from the danger, veering, to the nearest walkable point.
func _dash() -> void:
	var away := ground_pos - _threat if _threat != Vector2.INF else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var dir := (away.normalized() if away.length() > 0.01 else Vector2.RIGHT).rotated(rng.randf_range(-DASH_VEER, DASH_VEER))
	var to := ground_pos + dir * rng.randf_range(DASH.x, DASH.y)
	if grid != null:
		var free := grid.nearest_walkable(to, 6)
		to = free if free != Vector2.INF else ground_pos
	if to.distance_to(ground_pos) <= GOAL_REACH:
		# Nowhere to dash (hemmed in by walls): scurry instead. set_goal() on a point already reached would
		# arrive at once, dash again, and recurse forever.
		_scurry()
		return
	set_goal(to)


## Keep running while the route out is still being planned: a short straight hop away from the danger. No
## path-finding -- the stagger exists so a whole town does not path-find in one frame.
func _scurry() -> void:
	var away := ground_pos - _threat if _threat != Vector2.INF else Vector2.RIGHT.rotated(rng.randf() * TAU)
	var dir := (away.normalized() if away.length() > 0.01 else Vector2.RIGHT).rotated(rng.randf_range(-0.8, 0.8))
	for turn in [0.0, PI * 0.5, -PI * 0.5]:
		var to := ground_pos + dir.rotated(turn) * SCURRY
		if grid == null or grid.walkable(to):
			_target = to
			return


func is_running() -> bool:
	return state != State.DEAD and (mind == Mind.PANIC or mind == Mind.FLEE or mind == Mind.RALLY or mind == Mind.FIGHT
		or (mind == Mind.COMPELLED and _compel_run))


func is_stumbling() -> bool:
	return _stumble > 0.0


## Head for the nearest exit there is still a route to. The plan itself is staggered, so a town-wide panic
## does not ask for a hundred paths in the same frame.
func flee() -> void:
	if soldier or mind == Mind.FLEE or state == State.DEAD or mind == Mind.FIGHT or held_by_will(WILL_FIRM):
		return
	if fearless_left > 0.0:
		_reassured_fled = true  # it will go when the calm wears off
		return
	mind = Mind.FLEE
	walk_speed = _mind_speed()
	_panic_left = 0.0
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_repath_in = rng.randf_range(0.05, 2.4)


## The map changed under everyone (a bridge fell): throw this plan away so the mind makes a new one. The
## retry is staggered, like flight's, so a hundred people do not all ask for a route in the same frame.
func replan() -> void:
	_path = PackedVector2Array()
	_leg = 0
	_goal = Vector2.INF
	_repath_in = rng.randf_range(0.05, 0.8)


func _plan_exit() -> void:
	var exit := Vector2.INF
	if evac != null:
		exit = evac.choose(self)
		route_since = evac._clock
	elif grid != null:
		exit = grid.nearest_exit(ground_pos)
	if exit == Vector2.INF:
		# Sealed in: mill about and try again shortly -- or, stranded in the river (a bridge fell under it), first make
		# for the nearest dry ground.
		_repath_in = 1.5
		if grid != null and not grid.walkable(ground_pos) and _in_river(ground_pos):
			var land := grid.nearest_walkable(ground_pos)
			if land != Vector2.INF:
				_target = land
				return
		_drift()
		return
	set_goal(exit)


static func _in_river(g: Vector2) -> bool:
	if City.active != _rivers_of:
		_rivers_of = City.current()
		_rivers = _rivers_of.rivers()
	for r: Rect2 in _rivers:
		if r.has_point(g):
			return true
	return false


## The base unit's rule (a building's margin), and never off dry ground into the water -- a river cell the walk grid
## keeps closed: a straight walk to a target (a scurry, a drift, a queue spot) can cut a bank's corner. One standing in
## the water (a bridge fell under it) may step anyway, and wades out.
func _step_blocked(step: Vector2) -> bool:
	if super(step):
		return true
	if grid == null:
		return false
	var to := ground_pos + step
	return not grid.walkable(to) and _in_river(to) and grid.walkable(ground_pos)


## Soldiers only: stand at `at` (its starting post, or a slot on the Citadel's rally ring), at a walk or, `hurried`
## (escorts, marshals, rescue squads), at a run.
func send_to_post(at: Vector2, rally := false, hurried := false) -> void:
	if state == State.DEAD:
		return
	anchor = at
	mind = Mind.RALLY if rally else Mind.POST
	hurrying = hurried
	walk_speed = _mind_speed()
	set_goal(at)


## Stop caring: soldiers hold the Citadel's rubble once it has fallen.
func hold_ground() -> void:
	if state == State.DEAD:
		return
	mind = Mind.HOLD
	walk_speed = _mind_speed()
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_target = ground_pos


## True once a fleeing citizen has reached the exit it was walking to; the Crowd then removes it.
func has_escaped() -> bool:
	if mind != Mind.FLEE or _goal == Vector2.INF or ground_pos.distance_to(_goal) > GOAL_REACH:
		return false
	# At the dock it waits for the boat (RiverFerry), which carries it off. Asked last: every citizen is asked every
	# frame, and the call costs more than the checks above.
	return evac == null or not evac.is_boat_exit(_goal)


# --- Draw order ----------------------------------------------------------------

## The sort-key shift (screen px) that draws a person at `feet` after every building in `near` it stands in
## front of and before every one it stands behind, counting only buildings that overlap it on screen. 0 when
## its own feet already do that, or when nothing can (it would have to be before and after the same key).
static func sort_bias_for(feet: Vector2, near: Array[Structure], reach := INF) -> float:
	var own := (feet.x + feet.y) * 16.0
	var me := Rect2(Iso.ground_to_screen(feet) + SPRITE_BOX.position, SPRITE_BOX.size)
	var lo := -INF
	var hi := INF
	for s in near:
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var fp := s.footprint
		if fp.has_point(feet) or not _screen_box(fp, s.height).intersects(me):
			continue
		if reach < INF and not fp.grow(reach).has_point(feet):
			continue
		# Where it stands when still: a shudder moves the node a pixel or two, and the draw order should not.
		var key := s.base_position().y
		if feet.x >= fp.end.x or feet.y >= fp.end.y:
			lo = maxf(lo, key + 1.0)
		else:
			hi = minf(hi, key - 1.0)
	if (own >= lo and own <= hi) or lo > hi:
		return 0.0
	return (lo if own < lo else hi) - own


## The buildings someone standing anywhere in this person's half-unit cell could be drawn against: within
## SORT_REACH of it, and with a screen box (at full height) that can meet the sprite there. A handful instead of
## the dozens within reach, cached per cell until the town changes; sort_bias_for() still checks each exactly.
func _sort_candidates() -> Array[Structure]:
	if _sort_cells_env != env or _sort_cells_epoch != env.layout_epoch:
		_sort_cells.clear()
		_sort_cells_env = env
		_sort_cells_epoch = env.layout_epoch
	var c := Vector2i(floori(ground_pos.x / SORT_CELL), floori(ground_pos.y / SORT_CELL))
	if _sort_cells.has(c):
		return _sort_cells[c]
	var x0 := c.x * SORT_CELL
	var y0 := c.y * SORT_CELL
	var x1 := x0 + SORT_CELL
	var y1 := y0 + SORT_CELL
	# Every sprite box whose feet fall in the cell: the cell's diamond on screen, widened by the sprite.
	var region := Rect2((x0 - y1) * 32.0 + SPRITE_BOX.position.x, (x0 + y0) * 16.0 + SPRITE_BOX.position.y,
		(x1 - y0 - x0 + y1) * 32.0 + SPRITE_BOX.size.x, (x1 + y1 - x0 - y0) * 16.0 + SPRITE_BOX.size.y)
	var list: Array[Structure] = []
	for s in env.near(Vector2(x0, y0) + Vector2(SORT_CELL, SORT_CELL) * 0.5, SORT_REACH + SORT_CELL * 0.7072):
		if not s.walkable and _screen_box(s.footprint, s.max_height).intersects(region):
			list.append(s)
	_sort_cells[c] = list
	return list


## A footprint's box on screen, raised by its height and a roof. Its corners' iso extremes, written out: this
## runs for every building near every person ten times a second, and building it from a corner list allocated.
static func _screen_box(fp: Rect2, h: float) -> Rect2:
	var x0 := (fp.position.x - fp.end.y) * 32.0
	var x1 := (fp.end.x - fp.position.y) * 32.0
	var y0 := (fp.position.x + fp.position.y) * 16.0 - h - ROOF_MARGIN
	var y1 := (fp.end.x + fp.end.y) * 16.0
	return Rect2(x0, y0, x1 - x0, y1 - y0)


# --- Drawing -----------------------------------------------------------------

func _draw_body(lift: int, top_only: int) -> void:
	if mind == Mind.COMPELLED and compel_pose == &"kneel" and state != State.DEAD:
		# On its knees: the body down, no legs under it.
		lift += 3
		top_only = 1
	if SpriteArt.on() and PeopleArt.ready():
		_draw_sprite(lift, top_only)
	elif soldier:
		_draw_soldier(lift, top_only)
	else:
		_draw_citizen(lift, top_only)
	if state != State.DEAD:
		_draw_marks(lift)


## What a power has laid on it, over the head: a compulsion's mark (its glyph, drifting up and down with its steps,
## and a ring of the same light at the feet) and, above that, a badge. Each on a dark plate, to read on any ground.
func _draw_marks(lift: int) -> void:
	var y := (-25 if soldier else -22) + lift - (int(_anim * 2.0) % 2)
	if mind == Mind.COMPELLED:
		_glyph(compel_glyph, y, compel_mark)
		draw_set_transform(_draw_origin, 0.0, Vector2(1.0, 0.5))
		draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 12, Color(compel_mark, 0.85), 1.0)
		draw_set_transform(_draw_origin)
		y -= 8
	if badge_left > 0.0:
		_glyph(badge_glyph, y, badge_color)


## A five-by-five glyph centred over the head at height `y`, on a dark plate.
func _glyph(rows: Array[int], y: int, col: Color) -> void:
	_px(-3, y - 3, 7, 7, COL_MARK_EDGE)
	for r in 5:
		var bits := rows[r]
		for c in 5:
			if bits & (1 << (4 - c)):
				_px(c - 2, y - 2 + r, 1, 1, col)


## What the marks add to the redraw signature.
func _mark_signature() -> int:
	var marked := mind == Mind.COMPELLED or badge_left > 0.0
	return (1 if mind == Mind.COMPELLED else 0) + (2 if mind == Mind.FIGHT else 0) + (4 if badge_left > 0.0 else 0) \
		+ (8 if compel_pose == &"kneel" else 0) + 16 * (side % 3) + (64 if marked and int(_anim * 2.0) % 2 == 1 else 0)


## With the people sprites, the shadow comes from the atlas's white square: an untextured rect between two atlas draws
## would split the crowd into a draw batch a person (+~190 calls in the mission bench).
func _draw_shadow(r: Rect2, c: Color) -> void:
	if SpriteArt.on() and PeopleArt.ready():
		draw_texture_rect_region(PeopleArt.atlas(), r, PeopleArt.white_rect(), c)
	else:
		super(r, c)


## A death with no effect of its own (the quiet powers, the plague): with the people sprites, the body falls and lies
## (its death animation) where the procedural one left a dark smear.
func _draw_corpse() -> void:
	if SpriteArt.on() and PeopleArt.ready():
		_draw_body(0, 0)
	else:
		super()


## The design it wears (PeopleArt): its role's or its corps', the look hashed once from where it lives.
func _design() -> String:
	if _look < 0.0:
		_look = ArtKit.hash01(int(anchor.x * 64.0) * 73856093 ^ int(anchor.y * 64.0) * 19349663, 7)
	var role := profile.role if profile != null else 0
	var key := ((PeopleArt.generation * 64 + role) * 16 + corps) * 2 + (1 if soldier else 0)
	if key != _design_key:
		_design_key = key
		_design_name = PeopleArt.design_for(soldier, role, corps, _look)
		_design_info = PeopleArt.info(_design_name)
	return _design_name


## The people sprite's [animation, facing, frame] for what it is doing: its fall when dead, still while frozen, on one
## knee in a stumble, running when lifted, knocked or frightened, walking when it stepped, else idle; facing the way it
## last stepped. Stumble and death hold their last frame.
func _sprite_pose() -> Array:
	var code := _sprite_pose_code()
	return [PeopleArt.ANIMS[code >> 2 & 7], code & 3, code >> 5]


## _sprite_pose() folded into one int, frame << 5 | ANIMS index << 2 | facing: every person on screen asks for it every
## frame (_sprite_signature()), so it allocates nothing and reads its frame counts from the cached design table.
func _sprite_pose_code() -> int:
	var facing: int
	if _back:
		facing = PeopleArt.Facing.NE if _facing > 0 else PeopleArt.Facing.NW
	else:
		facing = PeopleArt.Facing.SE if _facing > 0 else PeopleArt.Facing.SW
	var anim := 0
	var t := _anim
	if state == State.DEAD:
		anim = 4
		t = _dead_time
	elif _frozen > 0.0:
		return facing
	elif _stumble > 0.0:
		anim = 3
		t = STUMBLE_SECONDS - _stumble
	elif _lift > 8.0 or state == State.PULLED or state == State.KNOCKBACK:
		anim = 2
	elif _stride:
		# is_frozen() and is_running(), inline: it is not dead here.
		anim = 2 if mind == Mind.PANIC or mind == Mind.FLEE or mind == Mind.RALLY else 1
	var frame := int(t * PeopleArt.FPS_AT[anim])
	if anim >= 3:
		_design()
		frame = mini(frame, _design_info[4][anim * 4 + facing] - 1)
	return frame << 5 | anim << 2 | facing


## What colours the sprite now, as the colour to draw its silhouette in over it (alpha: how strongly): the way
## DummyEnemy._tint() colours the procedural body — a hit's flash, ice, gravity's void, a char, sickness (v0.07.1: the
## stage's colour, sick_color(), as strongly as _draw_citizen() lerps the clothes and skin to it).
func _sprite_tint() -> Color:
	if _flash > 0.0:
		if _kind == &"lightning" and int(_flash * 40.0) % 2 == 0:
			return Color(COL_LIGHTNING_FLASH, 1.0)
		return Color(1.0, 1.0, 1.0, 1.0)
	if is_frozen():
		return Color(COL_ICE, 0.6 * clampf(_frozen, 0.0, 1.0))
	if _kind == &"gravity" and state == State.DEAD:
		return Color(COL_VOID, _char * 0.8)
	if _char > 0.0:
		return Color(COL_CHAR, _char * 0.85)
	if sick_left > 0.0 and state != State.DEAD:
		return Color(sick_color(), SICK_CLOTH)
	return Color(0.0, 0.0, 0.0, 0.0)


## The person drawn from the people atlas: the frame for what it does (_sprite_pose()) with its feet on its ground
## point, its white silhouette over it at the strength of whatever tints it, then the cough, the watchman's lantern,
## Discord's swirl and Mind Whisper's eye, placed for the sprite's taller body.
## The atlas and the default shader are every person's, so the whole crowd stays one draw batch.
func _draw_sprite(lift: int, top_only: int) -> void:
	# PeopleArt.frame_rect(), silhouette_rect() and foot(), from the design's cached table (PeopleArt.info()).
	_design()
	var code := _sprite_pose_code()
	var row := (code >> 2 & 7) * 4 + (code & 3)
	var n: int = _design_info[4][row]
	var cell: Vector2 = _design_info[3]
	var off := Vector2(((code >> 5) % n) * cell.x, row * cell.y)
	var src := Rect2(_design_info[0] + off, cell)
	var sil := Rect2(_design_info[1] + off, cell)
	var foot: Vector2 = _design_info[2]
	var dst := Rect2(Vector2(-foot.x, -foot.y + lift), src.size)
	if top_only != 0:
		# The laser's cut: only what is above the waist slides off; DummyEnemy draws the legs left standing.
		var keep := maxf(foot.y - SPRITE_WAIST, 1.0)
		src.size.y = keep
		sil.size.y = keep
		dst.size.y = keep
	var atlas := PeopleArt.atlas()
	draw_texture_rect_region(atlas, dst, src)
	var tint := _sprite_tint()
	if tint.a > 0.01:
		draw_texture_rect_region(atlas, dst, sil, tint)
	if state == State.DEAD:
		return
	if sick_left > 0.0:
		_px(2 if _facing > 0 else -3, -16 - int(_anim * 2.0) % 4 + lift, 1, 1, sick_color().lightened(0.35))
	if _is_watchman():
		# His lantern (v0.08), hanging from the leading hand beside the sprite: an iron cap over a 1x2 glow.
		var at := _sprite_lantern()
		_px(at.x, at.y + lift, 1, 1, COL_DARK)
		_px(at.x, at.y + 1 + lift, 1, 2, WATCH_LANTERN)
	elif _is_mayor():
		# His chain of office (v0.09) over the merchant standing in for him: 3 px across the chest, dipping in the middle.
		_px(SPRITE_CHAIN.x, SPRITE_CHAIN.y + lift, 3, 1, MAYOR_CHAIN)
		_px(SPRITE_CHAIN.x + 1, SPRITE_CHAIN.y + 1 + lift, 1, 1, MAYOR_CHAIN)
	elif _is_noble():
		_draw_crown(SPRITE_CROWN.x, SPRITE_CROWN.y + lift)
	if mind == Mind.CONFUSED:
		var turn := int(_anim * 3.0)
		for k in 4:
			var a := float((turn + k) % 8) * TAU / 8.0
			_px(roundi(cos(a) * 3.0), -22 + roundi(sin(a) * 1.0) + lift, 1, 1, COL_DISCORD)
	if mind == Mind.WHISPERED:
		# Mind Whisper's glyph (v0.08): a small gold eye over the head.
		_px(-1, -22 + lift, 3, 1, COL_WHISPER)
		_px(0, -23 + lift, 1, 3, COL_WHISPER)


## Townsfolk: bare head, tunic, no armour. Smaller than the soldiers so a crowd reads at a glance.
func _draw_citizen(lift: int, top_only: int) -> void:
	var running := is_running()
	var step := int(_anim * _walk_rate()) % 2 if state != State.DEAD and not is_frozen() and not is_stumbling() else 0
	if is_stumbling():
		lift += 2  # down on one knee
	var f := _facing
	var role := profile.role if profile != null else -1
	# The plague (v0.06) greens the skin and the clothes, going red as death nears (v0.07.1).
	var sick := sick_left > 0.0 and state != State.DEAD
	var tint := sick_color() if sick else Color.WHITE
	var skin := _skin.lerp(tint, SICK_SKIN) if sick else _skin
	var legs := CIT_LEGS.lerp(tint, SICK_CLOTH) if sick else CIT_LEGS
	if role == CitizenProfile.Role.CLERGY or role == CitizenProfile.Role.MONK:
		# A robe to the ground (no legs showing), a gold stole down its front.
		var robe := CLERGY_ROBE.lerp(tint, SICK_CLOTH) if sick else CLERGY_ROBE
		if top_only == 0:
			_px(-3, -4 + lift, 6, 4, robe.darkened(0.14))
		_px(-3, -10 + lift, 6, 6, robe)
		_px(-3, -10 + lift, 6, 1, robe.lightened(0.2))
		_px(-1, -10 + lift, 1, 8, CLERGY_STOLE)
	else:
		var coat := KEEPER_COAT if role == CitizenProfile.Role.BELLKEEPER else (
			WATCH_CLOAK if role == CitizenProfile.Role.WATCHMAN else (
			MAYOR_ROBE if role == CitizenProfile.Role.MAYOR else (
			NOBLE_CAPE if role == CitizenProfile.Role.NOBLE else _tunic)))
		if sick:
			coat = coat.lerp(tint, SICK_CLOTH)
		if top_only == 0:
			_px(-2, -4 + lift, 2, 4 - step, legs)
			_px(1, -4 + lift, 2, 3 + step, legs)
		_px(-3, -10 + lift, 6, 6, coat)
		_px(-3, -10 + lift, 6, 1, coat.lightened(0.18))
		if role == CitizenProfile.Role.ENGINEER:
			_px(-2, -8 + lift, 4, 4, ENG_APRON)
		elif role == CitizenProfile.Role.BELLKEEPER:
			_px(1, -8 + lift, 1, 1, KEEPER_BADGE)
		elif role == CitizenProfile.Role.MAYOR:
			# The chain of office (v0.09): 3 px across the chest, dipping in the middle.
			_px(-1, -9 + lift, 3, 1, MAYOR_CHAIN)
			_px(0, -8 + lift, 1, 1, MAYOR_CHAIN)
	var arm_y := -12 if running else -9
	_px(-4, arm_y + lift, 1, 3, skin)
	_px(3, arm_y + lift, 1, 3, skin)
	_px(-2, -13 + lift, 4, 3, skin)
	if sick:
		# A cough: a green mote drifting up from the mouth with its steps.
		_px(2 if f > 0 else -3, -14 - int(_anim * 2.0) % 4 + lift, 1, 1, tint.lightened(0.35))
	if role == CitizenProfile.Role.ENGINEER:
		# A leather cap, and a hammer in the leading hand.
		_px(-2, -14 + lift, 4, 2, ENG_CAP)
		var hx := 4 if f > 0 else -5
		_px(hx, arm_y - 1 + lift, 1, 4, ENG_HAFT)
		_px(hx - 1, arm_y - 2 + lift, 3, 1, ENG_IRON)
	else:
		_px(-2, -13 + lift, 4, 1, _hair)
	if role == CitizenProfile.Role.NOBLE:
		_draw_crown(-1, -14 + lift)
	if role == CitizenProfile.Role.WATCHMAN and state != State.DEAD:
		# His lantern, hanging from the leading hand: an iron cap over a 1x2 glow.
		var lx := 3 if f > 0 else -4
		_px(lx, arm_y + 3 + lift, 1, 1, COL_DARK)
		_px(lx, arm_y + 4 + lift, 1, 2, WATCH_LANTERN)
	if state != State.DEAD or _char < 0.5:
		_px(0 if f > 0 else -1, -12 + lift, 1, 1, COL_DARK)
	if mind == Mind.FIGHT and state != State.DEAD:
		# Frenzy: the arms thrown up, a red eye.
		_px(-4, -15 + lift, 1, 2, skin)
		_px(3, -15 + lift, 1, 2, skin)
		_px(0 if f > 0 else -1, -12 + lift, 1, 1, Color("ff3030"))
	if mind == Mind.CONFUSED and _confused_swirl and state != State.DEAD:
		# Discord's swirl over the head: four violet motes turning with its steps.
		var turn := int(_anim * 3.0)
		for k in 4:
			var a := float((turn + k) % 8) * TAU / 8.0
			_px(roundi(cos(a) * 3.0), -17 + roundi(sin(a) * 1.0) + lift, 1, 1, COL_DISCORD)
	if mind == Mind.WHISPERED and state != State.DEAD:
		# Mind Whisper's glyph: a small gold eye over the head.
		_px(-1, -17 + lift, 3, 1, COL_WHISPER)
		_px(0, -18 + lift, 1, 3, COL_WHISPER)


## Town guard: mail, royal blue tabard, helmet, spear and shield.
func _draw_soldier(lift: int, top_only: int) -> void:
	var step := int(_anim * _walk_rate()) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	# The plague (v0.07.1) colours a soldier too.
	var sick := sick_left > 0.0 and state != State.DEAD
	var tint := sick_color() if sick else Color.WHITE
	var mail := SOL_MAIL.lerp(tint, SICK_CLOTH) if sick else SOL_MAIL
	var skin := _skin.lerp(tint, SICK_SKIN) if sick else _skin
	if top_only == 0:
		_px(-3, -5 + lift, 2, 5 - step, SOL_HELM)
		_px(1, -5 + lift, 2, 4 + step, SOL_HELM)
	_px(-4, -11 + lift, 8, 6, mail)
	_px(-4, -11 + lift, 8, 1, SOL_MAIL_HI)
	var tabard := SOL_MARSHAL if corps == Corps.MARSHAL else (SOL_ESCORT if corps == Corps.ESCORT
		else (SOL_KNIGHT if corps == Corps.KNIGHT else SOL_TABARD))
	if sick:
		tabard = tabard.lerp(tint, SICK_CLOTH)
	_px(-2, -9 + lift, 4, 4, tabard)
	_px(-5, -10 + lift, 1, 3, skin)
	_px(4, -10 + lift, 1, 3, skin)
	_px(-3, -15 + lift, 6, 4, SOL_HELM)
	_px(-3, -15 + lift, 6, 1, SOL_MAIL_HI)
	if state != State.DEAD or _char < 0.5:
		_px(-1 if f > 0 else -2, -13 + lift, 3, 1, COL_DARK)
	# Spear in the leading hand, shield on the other arm.
	if corps == Corps.RESCUE:
		# A shovel, blade up over the shoulder.
		_px(5 * f, -14 + lift, 1, 9, SOL_HAFT)
		_px(5 * f - 1, -17 + lift, 3, 3, SOL_SHOVEL)
	else:
		_px(5 * f, -17 + lift, 1, 12, SOL_HAFT)
		_px(5 * f, -18 + lift, 1, 2, SOL_TIP)
	_px(-5 * f, -10 + lift, 2 * f, 5, SOL_SHIELD)
	_px(-4 * f, -8 + lift, 1, 1, SOL_GOLD)
	if sick:
		# A cough from under the helm.
		_px(2 if f > 0 else -3, -16 - int(_anim * 2.0) % 4 + lift, 1, 1, tint.lightened(0.35))


func _pose_signature() -> int:
	return (1 if is_running() else 0) + (2 if is_stumbling() else 0) + (4 if mind == Mind.CONFUSED and _confused_swirl else 0) \
		+ (5 if mind == Mind.WHISPERED else 0)


## DummyEnemy._art_signature(), folded ahead of time for a person on its feet with nothing lifting, freezing or
## flashing it: the same integer, so it redraws exactly when it did, for a fraction of the work. Every person
## on screen asks this every frame.
func _art_signature() -> int:
	if SpriteArt.on() and PeopleArt.ready():
		return _sprite_signature()
	if state != State.WANDER or _lift != 0.0 or _frozen > 0.0 or _flash > 0.0:
		return super() + _mark_signature() * SIG_MARK
	var running := is_running()
	var rate: float
	if running:
		rate = 8.0 if soldier else 10.0
	else:
		rate = 5.0 if soldier else 6.0
	var walk := int(_anim * rate) % 2 * 2 + (1 if _facing > 0 else 0)
	# A confused citizen is never running, so 4 never adds to the others' 3: pose stays under the next term's 7. A
	# whispered one (v0.08) neither runs nor stumbles (whisper() stands it up), so 5 is free too.
	var pose := (1 if running else 0) + (2 if _stumble > 0.0 else 0) + (4 if mind == Mind.CONFUSED else 0) \
		+ (5 if mind == Mind.WHISPERED else 0)
	# Sickness (v0.06) above the walk frames, by stage (v0.07.1), so the sprite redraws as it turns from green to red.
	return (walk + 4 * (sick_stage() if sick_left > 0.0 else 0)) * SIG_WALK + int(state) * SIG_STATE + (int(_draw_origin.y) + 64) * 7 + pose \
		+ _mark_signature() * SIG_MARK


## _art_signature() for the people sprites: the frame (_sprite_pose()) and everything drawn over or around it, so a
## person redraws exactly when its picture changes. Folded with multiplies, like the procedural one.
func _sprite_signature() -> int:
	if state == State.DEAD:
		return super._art_signature()
	var code := _sprite_pose_code()
	var sig: int = (code >> 2 & 7) * 4 + (code & 3)
	sig = sig * 16 + (code >> 5) % 16
	if _lift == 0.0 and _frozen <= 0.0 and _flash <= 0.0 and sick_left <= 0.0 and mind != Mind.CONFUSED:
		# The common case, nothing lifting, freezing, flashing, sickening or confusing it: the fold below with its
		# zero terms multiplied out ahead of time, the same integer (int arithmetic wraps the same either way).
		return ((sig * SIG_SPRITE_QUIET + int(state)) * 131 + int(_draw_origin.y) + 64) * SIG_SPRITE_OVERLAYS \
			+ (1 if mind == Mind.WHISPERED else 0)
	sig = sig * 1024 + (int(_anim * 1.4 * 8.0) % 1024 if _lift > 8.0 else 0)
	sig = sig * 97 + int(round(_lift))
	sig = sig * 97 + int(_frozen * 8.0)
	sig = sig * 97 + int(_flash * 40.0)
	sig = sig * 7 + int(state)
	sig = sig * 131 + int(_draw_origin.y) + 64
	# The overlays, each its own term: Discord's swirl, the cough, the sickness's stage (v0.07.1: its tint goes green
	# to red) and Mind Whisper's eye (v0.08). The watchman's lantern goes with the facing, already in.
	sig = sig * 9 + (1 + int(_anim * 3.0) % 8 if mind == Mind.CONFUSED else 0)
	sig = sig * 5 + (1 + int(_anim * 2.0) % 4 if sick_left > 0.0 else 0)
	sig = sig * (SICK_STAGES + 1) + sick_stage()
	return sig * 2 + (1 if mind == Mind.WHISPERED else 0)


## Where the watchman's lantern cap sits beside his sprite now (SPRITE_LANTERN, by facing), from his feet.
func _sprite_lantern() -> Vector2i:
	return Vector2i(SPRITE_LANTERN.x if _facing > 0 else -SPRITE_LANTERN.x - 1, SPRITE_LANTERN.y)


func _is_watchman() -> bool:
	return not soldier and profile != null and profile.role == CitizenProfile.Role.WATCHMAN


func _is_mayor() -> bool:
	return not soldier and profile != null and profile.role == CitizenProfile.Role.MAYOR


func _is_noble() -> bool:
	return not soldier and profile != null and profile.role == CitizenProfile.Role.NOBLE


## The Prince's gold crown (v0.09): a 5x1 band centred on x + 1, with three points over it a pixel apart, so they read
## as points and not a block (the band's left pixel is at x - 1, y).
func _draw_crown(x: int, y: int) -> void:
	_px(x - 1, y, 5, 1, NOBLE_CROWN)
	_px(x - 1, y - 1, 1, 1, NOBLE_CROWN)
	_px(x + 1, y - 1, 1, 1, NOBLE_CROWN)
	_px(x + 3, y - 1, 1, 1, NOBLE_CROWN)


func _walk_rate() -> float:
	if is_running():
		return 8.0 if soldier else 10.0
	return 5.0 if soldier else 6.0
