class_name Person
extends DummyEnemy
## A citizen or a soldier of Aldermere: the same unit every effect already kills, knocks, pulls, freezes and
## lifts, with a brain that walks the town's paths. Citizens go calm -> panicked -> fleeing -> escaped, queueing
## at the gates on the way out. Soldiers hold a post, march to the Citadel when the rally sounds, and never flee.

enum Mind { CALM, PANIC, FLEE, POST, RALLY, HOLD }

const PANIC_SPEED := 0.9
const FLEE_SPEED := 1.2
## How long a fright lasts before it turns into flight.
const PANIC_SECONDS := 1.6
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
	if wait > 0.0:
		# Held in a gate queue: stand still, but keep the fright timer running.
		wait = maxf(wait - delta, 0.0)
		_panic_left = maxf(_panic_left - delta, 0.0)
		_idle = maxf(_idle, 0.05)
		return
	_repath_in = maxf(_repath_in - delta, 0.0)
	walk_speed = _mind_speed()
	if mind == Mind.PANIC:
		_panic_left -= delta
		if _panic_left <= 0.0:
			flee()
	# A path can run out short of the goal: the goal sits inside a building, the way changed under us (a
	# bridge fell), or an effect threw us off it. Whatever the mind, drop the goal so it can plan a new one.
	if _goal != Vector2.INF and _path.is_empty() and _repath_in <= 0.0 \
			and ground_pos.distance_to(_goal) > GOAL_REACH:
		_goal = Vector2.INF
		_repath_in = 0.3
	match mind:
		Mind.FLEE:
			if _goal == Vector2.INF:
				if _repath_in <= 0.0:
					_plan_exit()
				else:
					_idle = maxf(_idle, 0.05)
		Mind.POST, Mind.RALLY:
			if _goal == Vector2.INF and _repath_in <= 0.0 and ground_pos.distance_to(anchor) > GOAL_REACH * 2.0:
				set_goal(anchor)
		Mind.CALM:
			if _goal == Vector2.INF and rng.randf() < STROLL_CHANCE:
				set_goal(TownLayout.MARKET_SQUARE.get_center() if rng.randf() < 0.5 else anchor)
		Mind.HOLD:
			_idle = maxf(_idle, 0.2)


func _mind_speed() -> float:
	match mind:
		Mind.PANIC, Mind.RALLY:
			return PANIC_SPEED
		Mind.FLEE:
			return FLEE_SPEED
		_:
			return WALK_SPEED


## Walk to `g` along the grid's path. A goal inside a building routes to its doorstep.
func set_goal(g: Vector2) -> void:
	_goal = g
	_leg = 0
	_path = grid.path(ground_pos, g) if grid != null else PackedVector2Array()
	_repath_in = REPATH
	_idle = 0.0
	_pick_target()


## Next waypoint, or a drift around the anchor when there is nothing to walk to. DummyEnemy calls this
## whenever it reaches its current target.
func _pick_target() -> void:
	while _leg < _path.size():
		var p := _path[_leg]
		_leg += 1
		if ground_pos.distance_to(p) > 0.08:
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
	var away := ground_pos - from
	var to := ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 3.0
	if grid != null:
		var free := grid.nearest_walkable(to, 6)
		to = free if free != Vector2.INF else ground_pos
	set_goal(to)


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


# --- Drawing -----------------------------------------------------------------

func _draw_body(lift: int, top_only: int) -> void:
	if soldier:
		_draw_soldier(lift, top_only)
	else:
		_draw_citizen(lift, top_only)


## Townsfolk: bare head, tunic, no armour. Smaller than the soldiers so a crowd reads at a glance.
func _draw_citizen(lift: int, top_only: int) -> void:
	var step := int(_anim * 6.0) % 2 if state != State.DEAD and not is_frozen() else 0
	var f := _facing
	if top_only == 0:
		_px(-2, -4 + lift, 2, 4 - step, CIT_LEGS)
		_px(1, -4 + lift, 2, 3 + step, CIT_LEGS)
	_px(-3, -10 + lift, 6, 6, _tunic)
	_px(-3, -10 + lift, 6, 1, _tunic.lightened(0.18))
	_px(-4, -9 + lift, 1, 3, _skin)
	_px(3, -9 + lift, 1, 3, _skin)
	_px(-2, -13 + lift, 4, 3, _skin)
	_px(-2, -13 + lift, 4, 1, _hair)
	if state != State.DEAD or _char < 0.5:
		_px(0 if f > 0 else -1, -12 + lift, 1, 1, COL_DARK)


## Town guard: mail, royal blue tabard, helmet, spear and shield.
func _draw_soldier(lift: int, top_only: int) -> void:
	var step := int(_anim * 5.0) % 2 if state != State.DEAD and not is_frozen() else 0
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
