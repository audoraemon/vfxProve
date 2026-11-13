class_name WalkingCorpseFx
extends FxTimeline
## Walking Corpse (Death, Tier III, quiet; spec 5.4): two clicks -- a body (the remain within Remains.PICK_R of `origin`, a
## hidden one too: Rules refuses a first click with none, "NO DEAD THERE", before any cooldown), then where it should go
## (extra["to"]). The remain is taken off the ground (Remains.take()) and the body gets up: a ZOMBIE-breed Visitor wearing the
## dead person's own design with no grey (Color.WHITE) and no eyes (alpha 0), so it passes for living. It walks there by the
## streets (Animal.route_to()) at a person's walk pace, for at most WALK_LIFE. It hunts nobody, bites nobody, frightens
## nobody and is no danger the town registers; its Visitors pack is never stepped, so no soldier is drawn to it or strikes
## it. It walks like anyone else.
## It is the player's to command (review R7) through Mind Whisper's order wheel, opened on the walker itself (the follow-up hooks,
## R15: follow_up_subject() and follow_up_orders() WALK / ATTACK / ENTER). The second click is its first order. In the open, getting
## there -- or getting no nearer -- it stands and waits (order "wait", its idle frames) for the next: a WALK to walkable ground within
## ORDER_REACH of it; an ATTACK on a person in the open, not guised, within ATTACK_R of it -- it goes for them at ATTACK_PACE x its
## walk and, within KILL_R, kills them quietly (&"grave": a body, no alarm, nobody stirs), KILLS_MOST times at most; a chase that runs
## ATTACK_SECS, or a foe that dies, goes in or is guised first, ends in a wait with no kill -- or an ENTER into a shelter or a house
## whose door (door_of()) is within ORDER_REACH. Anything else it refuses (the HUD says "missed"). A second click inside (or at the
## door of) a shelter or a house is an ENTER too. Getting to such a door it goes in and lies hidden (Remain.hidden): off the street
## drawing and out of every other power's reach, though Walking Corpse can walk it back out. A plague body that goes into a shelter
## brings the plague inside: up to INFECT_MOST of those sheltering there fall sick (Person.infect()), the nearest to the door first, a
## tie by instance id. At WALK_LIFE it lies down where it stands: Remains.move() puts the remain back on the ledger there with its
## clock restarted. A Death sigil (Sigil) hangs SIGIL_UP px over it all its life. No luck anywhere.
## Quiet: no alarm, no fright, no panic -- only q_walker, a shuffle of cloth and a joint's creak nobody turns at.

const WALK_LIFE := 40.0
const INFECT_MOST := 3
## The body takes this long to get up before it walks (it rises where it lay).
const T_RISE := 0.6
## Within this of where it was sent, it has got there and lies down.
const ARRIVE := 0.1
## Lying down within this of a building's door, it has gone in (hidden).
const IN_DOOR_R := 0.4
## A second click this near a shelter's or a house's footprint (inside it is 0) sends the body in at its door.
const DOOR_REACH := ShelterManager.DOOR_REACH
## The roles of the buildings it can go into (besides every shelter).
const INDOOR_ROLES: Array[StringName] = [&"house"]
## Lingering after it lies down: the effect ends this long after.
const SETTLE := 0.6
## Its orders (R7): how far from the walker a walk or a building's door may be; how near a foe must stand, how long it chases,
## how near is a kill, how many it kills at most, and its chase pace (a share of its walk).
const ORDER_REACH := 12.0
const ATTACK_R := 6.0
const ATTACK_SECS := 10.0
const KILL_R := 0.4
const KILLS_MOST := 2
const ATTACK_PACE := 1.6
## A chase plans its way to the foe again this often (the foe moves).
const REPATH := 0.5
## Slack on ORDER_REACH for a walk the wheel clamped to it exactly.
const REACH_EPS := 0.01
## The sigil hangs this many px over the walker's feet.
const SIGIL_UP := 26.0
## Ash and grave dust, cold to nothing (Death's palette).
const DUST := [Color(0.85, 0.82, 0.74, 0.4), Color(0.6, 0.6, 0.6, 0.28), Color(0.42, 0.42, 0.44, 0.14), Color(0.3, 0.3, 0.32, 0.0)]

## The walker's pack (never stepped: the effect drives it), the walker, the remain it carries, the building it goes into (null
## for the open street), whether it has lain down, and whom it infected.
var visitors: Visitors
var walker: Animal
var remain: Remains.Remain
var building: Structure
var shelter: Structure
var laid := false
var infected: Array[Person] = []
## What it is doing: "walk" (to dest), "enter" (to the building's door), "attack" (after foe) or "wait" (standing).
var order := "walk"
## Whom an attack goes for (null otherwise), and how many it has killed.
var foe: Person
var kills := 0
## Death's sigil over it while it walks (null without an overhead layer, and once it lies down or is gone).
var sigil: Node2D

## Where it walks: the second click on walkable ground, a walk order's spot, or the building's door.
var dest := Vector2.INF
var _grid: WalkGrid
## Its walk pace (its speed_mul), and when the current attack began.
var _pace := 1.0
var _attack_t := 0.0


## The shelter or house a second click at `to` sends the body into: the nearest standing one within DOOR_REACH of it (a tie
## by instance id), or null for the open street.
static func indoors_at(env: EnvironmentField, crowd: Crowd, to: Vector2) -> Structure:
	if env == null:
		return null
	var best: Structure = null
	var best_d := INF
	for s in env.near(to, DOOR_REACH + 4.0):
		if not is_instance_valid(s) or s.destroyed or not _enterable(s, crowd):
			continue
		var d := s.distance_to(to)
		if d > DOOR_REACH:
			continue
		if d < best_d or (d == best_d and best != null and s.get_instance_id() < best.get_instance_id()):
			best = s
			best_d = d
	return best


static func _enterable(s: Structure, crowd: Crowd) -> bool:
	if s.role in INDOOR_ROLES:
		return true
	if crowd != null and crowd.shelters != null:
		return crowd.shelters.shelters.has(s)
	return ShelterManager.is_shelter(s)


## Where the body goes in at building `s`: its door (EveryDoorFx.door_of(): the first face opening onto the street), on
## walkable ground; Vector2.INF when there is none.
static func door_of(s: Structure, grid: WalkGrid) -> Vector2:
	var door := EveryDoorFx.door_of(s, grid)
	if grid == null:
		return door
	return grid.nearest_walkable(door)


func _build() -> void:
	busy = T_RISE
	var rem: Remains = ctx.crowd.remains if ctx.crowd != null else null
	# The row's "reaches_hidden": a body walked indoors can be walked back out (Rules lets the cast through on the same flag).
	var reach_hidden := bool(PowerBook.get_power("walker").get("reaches_hidden", false))
	remain = rem.pick(origin, false, reach_hidden) if rem != null else null
	if remain == null:
		duration = 0.1  # no body there: Rules refuses such a click before it comes here
		return
	rem.take(remain)
	duration = WALK_LIFE + SETTLE
	_grid = ctx.crowd._grid
	# The second click is its first order: into the building under it (as an ENTER), else a walk there (no reach on this one).
	var to: Vector2 = extra.get("to", remain.pos)
	var b := indoors_at(ctx.env, ctx.crowd, to)
	if b == null or not _go_in(b):
		order = "walk"
		dest = _grid.nearest_walkable(to) if _grid != null else to
		if dest == Vector2.INF:
			dest = remain.pos  # nowhere to walk to: it gets up and stands where it was
	# It gets up where it lay, in its own look: no grey, no eyes. It hunts nobody (seek 0) and bites nobody.
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, _grid, parent)
	_pace = DummyEnemy.WALK_SPEED / (Animal.DOG_SPEED * Animal.RUN)
	walker = visitors.summon(remain.pos, Animal.Breed.ZOMBIE, 1, _pace, 0.0, 0.0, 1.0, false)
	walker.wear(remain.design, remain.facing, Color.WHITE, Color(0, 0, 0, 0))
	visitors.give(walker, {"no_bite": true})
	if is_instance_valid(ctx.overhead):
		# Death's sigil over it, so the player knows it for theirs.
		var s := Sigil.new()
		s.walker = walker
		s.sync()
		sigil = track(s, ctx.overhead) as Node2D
	ctx.play(&"q_walker", remain.pos)
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(remain.pos), 5.0, 10.0, T_RISE, Vector2(6, 14), Vector2(1, 3), Vector2(0.5, 1.0),
			Color(0, 0, 0, 0), DUST)


func _fx_process(delta: float) -> void:
	if laid or remain == null:
		return
	if not is_instance_valid(walker) or not walker.is_alive():
		# Carried off by another power (Heaven's Door takes a pack's walkers): the body is gone with it, and its sigil.
		laid = true
		walker = null
		foe = null
		_drop_sigil()
		duration = minf(duration, t + SETTLE)
		return
	walker.tick_visual(delta)
	if t >= WALK_LIFE:
		_lie_down()
		return
	if t >= T_RISE:
		match order:
			"walk", "enter":
				_walk(delta)
			"attack":
				_chase(delta)
			# "wait": it stands where it is (its idle frames), for the next order.
	if is_instance_valid(sigil):
		(sigil as Sigil).sync()  # over where it has got to this frame


## A walk (or the way to a building's door): there, or no nearer, it stands and waits -- or, at the door, goes in.
func _walk(delta: float) -> void:
	var done := walker.route_to(dest, delta, _grid)
	if not done and walker.ground_pos.distance_to(dest) > ARRIVE:
		return
	if order == "enter" and is_instance_valid(building) and walker.ground_pos.distance_to(dest) <= IN_DOOR_R:
		_lie_down()
		return
	_set_order("wait")


## An attack: after the foe at ATTACK_PACE (the way planned again every REPATH), and within KILL_R the quiet kill. A foe gone unfair
## (dead, in, guised), or ATTACK_SECS run, ends it in a wait with no kill.
func _chase(delta: float) -> void:
	if not _fair(foe) or t - _attack_t >= ATTACK_SECS:
		_set_order("wait")
		return
	if walker.ground_pos.distance_to(foe.ground_pos) > KILL_R:
		walker.route_to(foe.ground_pos, delta, _grid, REPATH)
	if walker.ground_pos.distance_to(foe.ground_pos) > KILL_R:
		return
	var who := foe
	_set_order("wait")
	kills += 1
	if ctx.field != null:
		ctx.field.kill(who, &"grave", walker.ground_pos)


## Whether `p` may be gone for: a living person out in the open, not guised. A Variant: `p` may be freed.
static func _fair(p: Variant) -> bool:
	return is_instance_valid(p) and p is Person and (p as Person).is_alive() and not (p as Person).inside \
		and not (p as Person).guised()


## Into building `b`: it walks to its door (an ENTER); false, nothing changed, when it has no door on walkable ground.
func _go_in(b: Structure) -> bool:
	var door := door_of(b, _grid)
	if door == Vector2.INF:
		return false
	_set_order("enter")
	building = b
	dest = door
	shelter = b if ctx.crowd.shelters != null and ctx.crowd.shelters.shelters.has(b) else null
	return true


## A new order: the last one's foe and building let go, its walk pace back.
func _set_order(o: String) -> void:
	order = o
	foe = null
	building = null
	shelter = null
	if is_instance_valid(walker):
		walker.speed_mul = _pace
		walker.blocked = false


## --- Orders: a follow-up through Mind Whisper's wheel, opened on the walker (Targeting, Rules.recast(); review R7, R15).

## While it walks, waits or chases: up and not lain down.
func can_follow_up() -> bool:
	return not laid and not finished and is_instance_valid(walker) and walker.is_alive()


func follow_up_wheel() -> bool:
	return true


## The wheel opens on the walker itself, wherever it stands.
func follow_up_subject() -> Node2D:
	return walker if is_instance_valid(walker) else null


## Its reach is measured from the walker.
func follow_up_from() -> Vector2:
	return walker.ground_pos if is_instance_valid(walker) else origin


func follow_up_reach() -> float:
	return ORDER_REACH


func follow_up_orders() -> Array:
	return ["walk", "attack", "enter"]


## An order from the wheel: {"order": "walk", "to"} (walkable, within ORDER_REACH of the walker), {"order": "attack", "foe"} (a fair
## foe within ATTACK_R, fewer than KILLS_MOST killed) or {"order": "enter", "to"} (a shelter or a house there whose door is within
## ORDER_REACH). False -- nothing changed, the HUD says "missed" -- for anything else, or when it can take no order now. Rules hands
## a subject's orders on unread, so every one is judged here.
func follow_up(at_pos: Vector2, extra_data: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var from := walker.ground_pos
	var to_v: Variant = extra_data.get("to", at_pos)
	var to: Vector2 = to_v if to_v is Vector2 else Vector2.INF
	match String(extra_data.get("order", "")):
		"walk":
			if to == Vector2.INF or _grid == null or not _grid.walkable(to) or from.distance_to(to) > ORDER_REACH + REACH_EPS:
				return false
			_set_order("walk")
			dest = to
		"enter":
			if to == Vector2.INF:
				return false
			var b := indoors_at(ctx.env, ctx.crowd, to)
			var door := door_of(b, _grid) if b != null else Vector2.INF
			if door == Vector2.INF or from.distance_to(door) > ORDER_REACH:
				return false
			_go_in(b)
		"attack":
			var given: Variant = extra_data.get("foe")
			if kills >= KILLS_MOST or not _fair(given) or (given as Person).ground_pos.distance_to(from) > ATTACK_R:
				return false
			_set_order("attack")
			foe = given as Person
			_attack_t = t
			walker.speed_mul = _pace * ATTACK_PACE
		_:
			return false
	return true


## It lies down where it stands: the remain goes back on the ledger there, its clock restarted. At the building's door it goes
## in, hidden, and a plague body infects those sheltering there. `torn_down` (the effect freed without its end): the body is
## only put back -- no plague brought in, no dust raised, the pack only queued for freeing.
func _lie_down(torn_down := false) -> void:
	if laid:
		return
	laid = true
	_drop_sigil(torn_down)
	var at := walker.ground_pos if is_instance_valid(walker) else remain.pos
	var inside := is_instance_valid(building) and at.distance_to(dest) <= IN_DOOR_R
	if inside:
		at = dest
	var rem: Remains = ctx.crowd.remains if is_instance_valid(ctx.crowd) else null
	if is_instance_valid(rem):
		rem.move(remain, at, inside)
	if torn_down:
		visitors.clear(true)
		walker = null
		return
	if inside and remain.sick and shelter != null:
		_bring_plague()
	if DominionParts.staged(self):
		FxParts.smoke(self, Iso.ground_to_screen(at), 5.0, 10.0, 0.3, Vector2(6, 14), Vector2(1, 3), Vector2(0.5, 1.0),
			Color(0, 0, 0, 0), DUST)
	visitors.clear()
	walker = null
	duration = minf(duration, t + SETTLE)


## Up to INFECT_MOST of those sheltering in `shelter` who are not sick yet fall sick, the nearest to the door first (a tie by
## instance id).
func _bring_plague() -> void:
	var near: Array[Person] = []
	for e in (ctx.crowd.shelters.shelters[shelter].inside as Array):
		var p := e as Person
		if is_instance_valid(p) and p.is_alive() and p.sick_left <= 0.0:
			near.append(p)
	near.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(dest)
		var db := b.ground_pos.distance_squared_to(dest)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	for p in near:
		if infected.size() >= INFECT_MOST:
			break
		if p.infect(PlagueManager.PLAGUE_LIFE):
			infected.append(p)


## Cut short while it walks (the act ends): it lies down where it is, so the body is never lost.
func _finish() -> void:
	if _can_lie_down():
		_lie_down()
	if visitors != null:
		visitors.clear()
	super()


## Freed without _finish (Battlefield.clear_effects() on a restart): the body is put back down where it had got to, as when cut
## short, so it is never lost while the ledger is still there (a ledger already freed with its crowd takes it with it); the
## walker is gone, the pack only queued for freeing (its parents may be mid-teardown). After _finish there is nothing left to do.
func _exit_tree() -> void:
	if _can_lie_down():
		_lie_down(true)
	if visitors != null:
		visitors.clear(true)
	walker = null
	_drop_sigil(true)
	super()


## Still walking, with a ledger to put the body back on. A walker already gone (another power carried it off) took the body.
func _can_lie_down() -> bool:
	return not laid and remain != null and is_instance_valid(ctx.crowd) and is_instance_valid(ctx.crowd.remains) \
		and is_instance_valid(walker)


## Its sigil goes (it lies down, is carried off, or the effect is torn down). `deferred`: only queued for freeing, for an
## _exit_tree whose parents may be mid-teardown; one in the tree is always queued.
func _drop_sigil(deferred := false) -> void:
	if is_instance_valid(sigil):
		if deferred or sigil.is_inside_tree():
			sigil.queue_free()
		else:
			sigil.free()
	sigil = null


## Death's sigil over the walker (R7): a 7x7 bone skull with grave-green eyes in a soft green glow, SIGIL_UP px over its feet, so the
## player knows it for theirs. Drawn only (no simulation state); it frees itself if the walker is gone without it.
class Sigil extends Node2D:
	const SKULL := [".#####.", "#######", "#ee#ee#", "#######", ".##.##.", "..###..", "..#.#.."]
	const GLOW_R := 6.0
	const GLOW_A := 0.12
	var walker: Animal

	func sync() -> void:
		if is_instance_valid(walker):
			position = Iso.ground_to_screen(walker.ground_pos) + Vector2(0.0, -WalkingCorpseFx.SIGIL_UP)

	func _process(_delta: float) -> void:
		if not is_instance_valid(walker):
			queue_free()
			return
		sync()

	func _draw() -> void:
		draw_circle(Vector2(0.5, 0.5), GLOW_R, Color(DeathParts.GRAVE_GREEN, GLOW_A))
		for y in SKULL.size():
			var row: String = SKULL[y]
			for x in row.length():
				if row[x] == ".":
					continue
				draw_rect(Rect2(float(x - 3), float(y - 3), 1.0, 1.0), DeathParts.GRAVE_GREEN if row[x] == "e" else DeathParts.BONE)
