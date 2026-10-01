class_name Person
extends DummyEnemy
## A citizen or a soldier of Aldermere: the same unit every effect already kills, knocks, pulls, freezes and
## lifts, with a brain that walks the town's paths. Citizens go calm -> panicked -> fleeing -> escaped, queueing
## at the gates on the way out. Soldiers hold a post, march to the Citadel when the rally sounds, and never flee.

enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD, OBSERVE, RECOVER, REGROUP, DUTY, ASSIST, SHELTER }
## What a citizen is trying to do (v0.04), read from its mind: going about its day, stopping to look at something,
## running from danger nearby, evacuating through a gate, or cautiously returning once a danger has passed.
enum Intent { ROUTINE, OBSERVE, LOCAL_FLEE, REGROUP, EVACUATE, REROUTE, RECOVER, ASSIST, SHELTER }
## How much a citizen knows of the danger (v0.04's awareness levels; Emergency and Collapse come with the staged
## alarm).
enum Awareness { UNAWARE, CONCERNED, THREATENED, EMERGENCY, COLLAPSE }

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
const SOL_MAIL := Color("6a6f78")
const SOL_MAIL_HI := Color("8d939c")
const SOL_HELM := Color("484d56")
const SOL_TABARD := Color("1f3f8a")
const SOL_SHIELD := Color("2f5cc0")
const SOL_GOLD := Color("d8b23a")
const SOL_HAFT := Color("5a4a3a")
const SOL_TIP := Color("b8bcc4")

var mind := Mind.CALM
var soldier := false
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
## Taking cover (v0.04 P2; ShelterManager runs it): the crowd's manager, the building sought or sheltered in, its
## door, and whether it is inside (hidden, out of every effect's reach, not stepped).
var shelters: ShelterManager
var shelter: Structure
var shelter_door := Vector2.INF
var inside := false
var route_since := -INF
var rerouting := 0.0
var grid: WalkGrid
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
## Seconds left face-down after a stumble; see is_stumbling().
var _stumble := 0.0

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
		every = OFFSCREEN_EVERY
	elif unhurried():
		every = CALM_EVERY
	if every > 1:
		_offscreen_delta += delta
		if (Engine.get_process_frames() + stagger_key()) % every != 0:
			return
		delta = _offscreen_delta
		_offscreen_delta = 0.0
	elif _offscreen_delta > 0.0:
		delta += _offscreen_delta
		_offscreen_delta = 0.0
	tick(delta)
	_refresh(delta)


## Calm or at a post, wandering, and nothing holding or tripping it: updated at CALM_EVERY on screen.
func unhurried() -> bool:
	var calm := mind == Mind.CALM or mind == Mind.POST or mind == Mind.OBSERVE or mind == Mind.RECOVER \
		or mind == Mind.REGROUP
	return calm and state == State.WANDER and not is_frozen() and _stumble <= 0.0 and wait <= 0.0


# --- Brain -------------------------------------------------------------------

func tick(delta: float) -> void:
	if state == State.WANDER and not is_frozen():
		_think_accum += delta
		if _think_due:
			_think(_think_accum)
			_think_accum = 0.0
		_think_due = not _think_due
	super(delta)


func _think(delta: float) -> void:
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
		_idle = maxf(_idle, 0.1)
		if _observe_left <= 0.0:
			_recover(rng.randf_range(1.0, 3.0))
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
				set_goal(TownLayout.MARKET_SQUARE.get_center() if rng.randf() < 0.5 else anchor)
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
	match mind:
		Mind.PANIC, Mind.RALLY:
			return PANIC_SPEED * pace
		Mind.RECOVER:
			return WALK_SPEED * RECOVER_PACE * pace
		Mind.ASSIST:
			return WALK_SPEED * ASSIST_PACE * pace
		Mind.SHELTER, Mind.DUTY:
			return PANIC_SPEED * pace
		Mind.FLEE:
			return FLEE_SPEED * pace
		_:
			return WALK_SPEED * pace


## Whether it is on its way somewhere (a goal it has not reached).
func has_goal() -> bool:
	return _goal != Vector2.INF


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
	if mind == Mind.OBSERVE or mind == Mind.ASSIST or mind == Mind.SHELTER or mind == Mind.DUTY:
		_target = ground_pos
		return
	if mind == Mind.FLEE:
		_scurry()
		return
	_drift()


## A small aimless step: citizens milling about their street, soldiers shifting at their post.
func _drift() -> void:
	var spread := POST_SPREAD
	if mind == Mind.CALM or mind == Mind.RECOVER or mind == Mind.REGROUP:
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
	if soldier or mind == Mind.FLEE or mind == Mind.SHELTER or inside or state == State.DEAD:
		return
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
## citizen does; the frightened and the fleeing are past looking.
func observe(from: Vector2) -> void:
	if soldier or state == State.DEAD or not (mind == Mind.CALM or mind == Mind.RECOVER):
		return
	mind = Mind.OBSERVE
	awareness = maxi(awareness, Awareness.CONCERNED) as Awareness
	_threat = from
	_observe_left = rng.randf_range(OBSERVE_SECONDS.x, OBSERVE_SECONDS.y)
	_goal = Vector2.INF
	_path = PackedVector2Array()
	_leg = 0
	_target = ground_pos
	walk_speed = _mind_speed()


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
	return Intent.ROUTINE


## Run to the door of `s` to take cover inside.
func seek_shelter(s: Structure, door: Vector2) -> void:
	mind = Mind.SHELTER
	shelter = s
	shelter_door = door
	walk_speed = PANIC_SPEED * pace
	set_goal(door)


## Out of cover (or giving up on it): to the gates if the town is evacuating, else back to its day.
func leave_shelter(evacuate: bool) -> void:
	shelter = null
	if evacuate:
		mind = Mind.CALM
		flee()
	else:
		_recover(rng.randf_range(2.0, 4.0))


## Turn out to fight the fire on `s` (FireManager sends it for water).
func assist(s: Structure) -> void:
	if soldier or state == State.DEAD or mind == Mind.FLEE:
		return
	mind = Mind.ASSIST
	assist_fire = s
	assist_at_water = false
	assist_full = false
	assist_wait = 0.0
	walk_speed = _mind_speed()


## Stop fighting a fire: wait a moment, then back to its day.
func stand_down() -> void:
	assist_fire = null
	assist_full = false
	assist_at_water = false
	if mind == Mind.ASSIST:
		_recover(rng.randf_range(2.0, 4.0))


## Walk to `g` and stand there (a responder's round).
func walk_to(g: Vector2) -> void:
	anchor = g
	set_goal(g)


## City Emergency (v0.04): go home to `home` and wait there with the family until the evacuation or the danger.
func regroup(home: Vector2) -> void:
	if soldier or state == State.DEAD or mind == Mind.FLEE:
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
func go_duty(at: Vector2) -> void:
	if soldier or state == State.DEAD or mind == Mind.FLEE:
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
	return state != State.DEAD and (mind == Mind.PANIC or mind == Mind.FLEE or mind == Mind.RALLY)


func is_stumbling() -> bool:
	return _stumble > 0.0


## Head for the nearest exit there is still a route to. The plan itself is staggered, so a town-wide panic
## does not ask for a hundred paths in the same frame.
func flee() -> void:
	if soldier or mind == Mind.FLEE or state == State.DEAD:
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
		# Sealed in: mill about and try again shortly.
		_repath_in = 1.5
		_drift()
		return
	set_goal(exit)


## Soldiers only: stand at `at` (its starting post, or a slot on the Citadel's rally ring).
func send_to_post(at: Vector2, rally := false) -> void:
	if state == State.DEAD:
		return
	anchor = at
	mind = Mind.RALLY if rally else Mind.POST
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
	if soldier:
		_draw_soldier(lift, top_only)
	else:
		_draw_citizen(lift, top_only)


## Townsfolk: bare head, tunic, no armour. Smaller than the soldiers so a crowd reads at a glance.
func _draw_citizen(lift: int, top_only: int) -> void:
	var running := is_running()
	var step := int(_anim * _walk_rate()) % 2 if state != State.DEAD and not is_frozen() and not is_stumbling() else 0
	if is_stumbling():
		lift += 2  # down on one knee
	var f := _facing
	var role := profile.role if profile != null else -1
	if role == CitizenProfile.Role.CLERGY:
		# A robe to the ground (no legs showing), a gold stole down its front.
		if top_only == 0:
			_px(-3, -4 + lift, 6, 4, CLERGY_ROBE.darkened(0.14))
		_px(-3, -10 + lift, 6, 6, CLERGY_ROBE)
		_px(-3, -10 + lift, 6, 1, CLERGY_ROBE.lightened(0.2))
		_px(-1, -10 + lift, 1, 8, CLERGY_STOLE)
	else:
		var coat := KEEPER_COAT if role == CitizenProfile.Role.BELLKEEPER else _tunic
		if top_only == 0:
			_px(-2, -4 + lift, 2, 4 - step, CIT_LEGS)
			_px(1, -4 + lift, 2, 3 + step, CIT_LEGS)
		_px(-3, -10 + lift, 6, 6, coat)
		_px(-3, -10 + lift, 6, 1, coat.lightened(0.18))
		if role == CitizenProfile.Role.ENGINEER:
			_px(-2, -8 + lift, 4, 4, ENG_APRON)
		elif role == CitizenProfile.Role.BELLKEEPER:
			_px(1, -8 + lift, 1, 1, KEEPER_BADGE)
	var arm_y := -12 if running else -9
	_px(-4, arm_y + lift, 1, 3, _skin)
	_px(3, arm_y + lift, 1, 3, _skin)
	_px(-2, -13 + lift, 4, 3, _skin)
	if role == CitizenProfile.Role.ENGINEER:
		# A leather cap, and a hammer in the leading hand.
		_px(-2, -14 + lift, 4, 2, ENG_CAP)
		var hx := 4 if f > 0 else -5
		_px(hx, arm_y - 1 + lift, 1, 4, ENG_HAFT)
		_px(hx - 1, arm_y - 2 + lift, 3, 1, ENG_IRON)
	else:
		_px(-2, -13 + lift, 4, 1, _hair)
	if state != State.DEAD or _char < 0.5:
		_px(0 if f > 0 else -1, -12 + lift, 1, 1, COL_DARK)


## Town guard: mail, royal blue tabard, helmet, spear and shield.
func _draw_soldier(lift: int, top_only: int) -> void:
	var step := int(_anim * _walk_rate()) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-3, -5 + lift, 2, 5 - step, SOL_HELM)
		_px(1, -5 + lift, 2, 4 + step, SOL_HELM)
	_px(-4, -11 + lift, 8, 6, SOL_MAIL)
	_px(-4, -11 + lift, 8, 1, SOL_MAIL_HI)
	_px(-2, -9 + lift, 4, 4, SOL_TABARD)
	_px(-5, -10 + lift, 1, 3, _skin)
	_px(4, -10 + lift, 1, 3, _skin)
	_px(-3, -15 + lift, 6, 4, SOL_HELM)
	_px(-3, -15 + lift, 6, 1, SOL_MAIL_HI)
	if state != State.DEAD or _char < 0.5:
		_px(-1 if f > 0 else -2, -13 + lift, 3, 1, COL_DARK)
	# Spear in the leading hand, shield on the other arm.
	_px(5 * f, -17 + lift, 1, 12, SOL_HAFT)
	_px(5 * f, -18 + lift, 1, 2, SOL_TIP)
	_px(-5 * f, -10 + lift, 2 * f, 5, SOL_SHIELD)
	_px(-4 * f, -8 + lift, 1, 1, SOL_GOLD)


func _pose_signature() -> int:
	return (1 if is_running() else 0) + (2 if is_stumbling() else 0)


## DummyEnemy._art_signature(), folded ahead of time for a person on its feet with nothing lifting, freezing or
## flashing it: the same integer, so it redraws exactly when it did, for a fraction of the work. Every person
## on screen asks this every frame.
func _art_signature() -> int:
	if state != State.WANDER or _lift != 0.0 or _frozen > 0.0 or _flash > 0.0:
		return super()
	var running := mind == Mind.PANIC or mind == Mind.FLEE or mind == Mind.RALLY
	var rate: float
	if running:
		rate = 8.0 if soldier else 10.0
	else:
		rate = 5.0 if soldier else 6.0
	var walk := int(_anim * rate) % 2 * 2 + (1 if _facing > 0 else 0)
	var pose := (1 if running else 0) + (2 if _stumble > 0.0 else 0)
	return walk * SIG_WALK + int(state) * SIG_STATE + (int(_draw_origin.y) + 64) * 7 + pose


func _walk_rate() -> float:
	if is_running():
		return 8.0 if soldier else 10.0
	return 5.0 if soldier else 6.0
