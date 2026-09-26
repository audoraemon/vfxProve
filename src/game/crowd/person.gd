class_name Person
extends DummyEnemy
## A citizen or a soldier of Aldermere: the same unit every effect already kills, knocks, pulls, freezes and
## lifts, with a brain that walks the town's paths. Citizens go calm -> panicked -> fleeing -> escaped, queueing
## at the gates on the way out. Soldiers hold a post, march to the Citadel when the rally sounds, and never flee.

enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD }

const PANIC_SPEED := 1.6
const FLEE_SPEED := 1.2
## How long a fright lasts before it turns into flight.
const PANIC_SECONDS := 3.0
## Close enough to count as arrived.
const GOAL_REACH := 0.45
## Seconds before a person gives a stuck goal another try. Cinderfall repeatedly invalidates routes (fallen
## buildings, the bridge closing), so raised from 2.5 to spread the A* replanning out over fewer per-second calls.
const REPATH := 4.0
## Chance per frame that a calm citizen strolls to the market or back home.
const STROLL_CHANCE := 0.004
## How far a calm citizen drifts from home, and a posted soldier from its spot.
const CALM_SPREAD := 1.4
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
## Where the fright came from, so a dash and a scurry run away from it.
var _threat := Vector2.INF
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


## `at` is where it stands and what it treats as home (or its post). Seed `rng` before calling this.
func setup_person(is_soldier: bool, at: Vector2, w: WalkGrid) -> Person:
	soldier = is_soldier
	grid = w
	anchor = at
	ground_pos = at
	mind = Mind.POST if is_soldier else Mind.CALM
	_think_due = get_instance_id() % 2 == 0
	_skin = CIT_SKIN[rng.randi() % CIT_SKIN.size()]
	_tunic = CIT_TUNIC[rng.randi() % CIT_TUNIC.size()]
	_hair = CIT_HAIR[rng.randi() % CIT_HAIR.size()]
	pace = rng.randf_range(PACE_RANGE.x, PACE_RANGE.y)
	_pick_target()
	return self


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
	if mind == Mind.PANIC:
		_panic_left -= delta
		if _panic_left <= 0.0:
			flee()
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
			if _goal == Vector2.INF and rng.randf() < STROLL_CHANCE:
				set_goal(TownLayout.MARKET_SQUARE.get_center() if rng.randf() < 0.5 else anchor)
		Mind.HOLD:
			_idle = maxf(_idle, 0.2)
	_sort_in -= delta
	if env != null and _sort_in <= 0.0:
		_sort_in = 1.0 / SORT_HZ + float(get_instance_id() % 7) * 0.001
		sort_bias = sort_bias_for(ground_pos, env.near(ground_pos, SORT_REACH))


func _mind_speed() -> float:
	match mind:
		Mind.PANIC, Mind.RALLY:
			return PANIC_SPEED * pace
		Mind.FLEE:
			return FLEE_SPEED * pace
		_:
			return WALK_SPEED * pace


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
		_dash()
		return
	if mind == Mind.FLEE:
		_scurry()
		return
	_drift()


## A small aimless step: citizens milling about their street, soldiers shifting at their post.
func _drift() -> void:
	var spread := CALM_SPREAD if mind == Mind.CALM else POST_SPREAD
	var to := anchor + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
	if grid != null:
		var free := grid.nearest_walkable(to, 3)
		to = free if free != Vector2.INF else ground_pos
	_target = to


# --- What the town does to a person ------------------------------------------

## A power landed, or a building fell, at `from`: bolt away from it, then flee for good. Soldiers do not.
func panic(from: Vector2) -> void:
	if soldier or mind == Mind.FLEE or state == State.DEAD:
		return
	mind = Mind.PANIC
	# Set here, not left for the next _think(): that can be a frame away now that thinking is half-rate, and a
	# jolt should visibly speed someone up the instant it lands, not on a coin-flip frame.
	walk_speed = _mind_speed()
	_panic_left = PANIC_SECONDS
	_threat = from
	_dash()


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
	var exit := grid.nearest_exit(ground_pos) if grid != null else Vector2.INF
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
	return mind == Mind.FLEE and _goal != Vector2.INF and ground_pos.distance_to(_goal) <= GOAL_REACH


# --- Draw order ----------------------------------------------------------------

## The sort-key shift (screen px) that draws a person at `feet` after every building in `near` it stands in
## front of and before every one it stands behind, counting only buildings that overlap it on screen. 0 when
## its own feet already do that, or when nothing can (it would have to be before and after the same key).
static func sort_bias_for(feet: Vector2, near: Array[Structure]) -> float:
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
		var key := s.position.y
		if feet.x >= fp.end.x or feet.y >= fp.end.y:
			lo = maxf(lo, key + 1.0)
		else:
			hi = minf(hi, key - 1.0)
	if (own >= lo and own <= hi) or lo > hi:
		return 0.0
	return (lo if own < lo else hi) - own


## A footprint's box on screen, raised by its height and a roof.
static func _screen_box(fp: Rect2, h: float) -> Rect2:
	var box := Rect2(Iso.ground_to_screen(fp.position), Vector2.ZERO)
	for corner in [Vector2(fp.end.x, fp.position.y), fp.end, Vector2(fp.position.x, fp.end.y)]:
		box = box.expand(Iso.ground_to_screen(corner))
	box.position.y -= h + ROOF_MARGIN
	box.size.y += h + ROOF_MARGIN
	return box


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
	if top_only == 0:
		_px(-2, -4 + lift, 2, 4 - step, CIT_LEGS)
		_px(1, -4 + lift, 2, 3 + step, CIT_LEGS)
	_px(-3, -10 + lift, 6, 6, _tunic)
	_px(-3, -10 + lift, 6, 1, _tunic.lightened(0.18))
	var arm_y := -12 if running else -9
	_px(-4, arm_y + lift, 1, 3, _skin)
	_px(3, arm_y + lift, 1, 3, _skin)
	_px(-2, -13 + lift, 4, 3, _skin)
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


func _walk_rate() -> float:
	if is_running():
		return 8.0 if soldier else 10.0
	return 5.0 if soldier else 6.0
