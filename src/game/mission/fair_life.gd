class_name FairLife
extends RefCounted
## The fair's talking groups (fair life, 2026-11-20): Market Panic's goers stand in knots of GROUP_MIN..GROUP_MAX round a centre,
## each on a ring of RING about it, and every so often (STROLL seconds) a knot drifts to a new centre and its people walk there
## together. This decides spot values only; the director's spots, arrival and hold (_hold_fair()) stay the mechanism. Its own
## RandomNumberGenerator: nothing is drawn from the crowd or any town stream.

## A group's size, the ring its people stand on round the centre, the least between two centres (centre to centre, a floor), and
## the seconds between a group's strolls.
const GROUP_MIN := 2
const GROUP_MAX := 3
const RING := 0.6
const APART := 2.0
const STROLL := Vector2(20.0, 40.0)
## Tries at a centre before the best of them is taken.
const TRIES := 16
## The grid step of the sweep that finds a centre APART when the tries did not (not a tuning knob: it only widens the search).
const SCAN := 0.4

## One group: its people (Variants: any may be a body freed after its death fade), its centre, each one's spot by instance id,
## and the seconds to its next stroll.
class Group:
	extends RefCounted
	var members: Array = []
	var centre := Vector2.INF
	var spots := {}
	var next_in := 0.0


var _rng := RandomNumberGenerator.new()
var _heart := Vector2.ZERO
var _radius := 0.0
## Callable(p: Person, at: Vector2) -> bool: whether p has a way on foot to `at`; Callable(at: Vector2) -> Vector2: the nearest
## walkable ground.
var _reaches: Callable
var _walkable: Callable
var _groups: Array[Group] = []
## True once the market has closed: nobody joins a group or is placed any more (fair life, 2026-11-20).
var closed := false


func _init(seed_value: int, heart: Vector2, radius: float, reaches: Callable, walkable: Callable) -> void:
	_rng.seed = seed_value
	_heart = heart
	_radius = radius
	_reaches = reaches
	_walkable = walkable


## Splits one crowd, in its order, into groups of GROUP_MIN..GROUP_MAX (a last single joins the group before: the size drawn
## never leaves one over), and draws each a centre.
func form(people: Array) -> void:
	var left := people.size()
	var at := 0
	while left > 0:
		var n := _rng.randi_range(GROUP_MIN, GROUP_MAX)
		if left <= GROUP_MAX:
			n = left
		elif left - n == 1:
			n += -1 if n > GROUP_MIN else 1
		var g := Group.new()
		g.members = people.slice(at, at + n)
		at += n
		left -= n
		g.next_in = _rng.randf_range(STROLL.x, STROLL.y)
		_groups.append(g)
		_place(g)


## A goer sent late (indoors as his crowd set out) joins the nearest group with room, else stands as a group of his own.
## Only a group whose centre he can walk to will do; none does, and he stands as a group of his own at a centre drawn for him.
## Returns the people whose spot changed (the group is spaced afresh); none once closed.
func join(p: Person) -> Array:
	if closed or spot_of(p) != Vector2.INF:
		return []
	var g := _nearest_with_room(p.ground_pos, null, [p])
	if g == null:
		g = Group.new()
		g.next_in = _rng.randf_range(STROLL.x, STROLL.y)
		g.members = [p]
		_groups.append(g)
		_place(g)
		return [p]
	g.members.append(p)
	_space(g)
	return g.members.duplicate()


## Where `p` stands (Vector2.INF if he is in no group).
func spot_of(p: Person) -> Vector2:
	var g := _group_of(p)
	return Vector2.INF if g == null else g.spots.get(p.get_instance_id(), Vector2.INF)


## The centre of the group `p` stands in (Vector2.INF if none).
func centre_of(p: Person) -> Vector2:
	var g := _group_of(p)
	return Vector2.INF if g == null else g.centre


## Time passes: the groups whose stroll has come draw a new centre (the freed and the dead are let go first; a group left with
## one is merged into the nearest group with room, or strolls alone if none has). Returns the people whose spot changed.
func step(delta: float) -> Array:
	var moved: Array = []
	for g in _groups.duplicate():
		_prune(g)
		if g.members.is_empty():
			_groups.erase(g)
			continue
		g.next_in -= delta
		if g.next_in > 0.0:
			continue
		g.next_in = _rng.randf_range(STROLL.x, STROLL.y)
		if g.members.size() < GROUP_MIN:
			var host := _nearest_with_room(g.centre, g, g.members)
			if host != null:
				host.members.append_array(g.members)
				_groups.erase(g)
				_space(host)
				for v: Variant in host.members:
					if not moved.has(v):
						moved.append(v)
				continue
		_place(g)
		for v: Variant in g.members:
			if not moved.has(v):
				moved.append(v)
	return moved


## The market has closed: the groups are let go and no one is placed again.
func close() -> void:
	closed = true
	_groups.clear()


## `p` is out of his group (broken, dead, left).
func drop(p: Person) -> void:
	var g := _group_of(p)
	if g != null:
		g.members.erase(p)
		g.spots.erase(p.get_instance_id())
		if g.members.is_empty():
			_groups.erase(g)


## The groups, each an Array of Person (the live ones).
func groups() -> Array:
	var out: Array = []
	for g in _groups:
		_prune(g)
		if not g.members.is_empty():
			out.append(g.members.duplicate())
	return out


func _group_of(p: Person) -> Group:
	for g in _groups:
		if g.members.has(p):
			return g
	return null


func _prune(g: Group) -> void:
	for v: Variant in g.members.duplicate():
		if not is_instance_valid(v) or not (v as Person).is_alive():
			g.members.erase(v)


func _nearest_with_room(at: Vector2, except: Group, newcomers: Array) -> Group:
	var best: Group = null
	for g in _groups:
		if g == except or g.members.size() + newcomers.size() > GROUP_MAX or g.centre == Vector2.INF:
			continue
		var reach := true
		for v: Variant in newcomers:
			reach = reach and is_instance_valid(v) and _reaches.call(v, g.centre)
		if not reach:
			continue
		_prune(g)
		if g.members.is_empty():
			continue
		if best == null or g.centre.distance_to(at) < best.centre.distance_to(at):
			best = g
	return best


## Draws `g` a centre (the disk about the heart shrunk by RING, so the ring's spots stay within the fair's radius too; walkable,
## reachable by every member, APART from every other group's centre; the try farthest from them if none of TRIES fits), and sets
## its people's spots on the ring round it.
func _place(g: Group) -> void:
	var best := Vector2.INF
	var best_gap := -1.0
	var best_ok := false
	for attempt in TRIES:
		var c := _heart + Vector2.from_angle(_rng.randf() * TAU) * (_radius - RING) * sqrt(_rng.randf())
		var ground: Vector2 = _walkable.call(c)
		if ground.distance_to(c) > 0.05 or not _all_reach(g, c):
			continue
		var gap := _gap(c, g)
		var ok := gap >= APART
		if ok or best == Vector2.INF or (not best_ok and gap > best_gap):
			best = c
			best_gap = gap
			best_ok = ok
		if ok:
			break
	if not best_ok:
		best = _scan(g, best)
	if best == Vector2.INF:
		best = _walkable.call(_heart)
	g.centre = best
	_space(g)


## When the random tries found no room APART from the other centres: a sweep of the centre disk on a SCAN grid for a walkable point
## reachable by all of `g` that is APART from every other centre, the one nearest `near` (the best try, or the heart). `near` itself
## if none fits (a full fair). No random draws.
func _scan(g: Group, near: Vector2) -> Vector2:
	var from := near if near != Vector2.INF else _heart
	var found := Vector2.INF
	var reach := _radius - RING
	var steps := int(ceil(reach / SCAN))
	for ix in range(-steps, steps + 1):
		for iy in range(-steps, steps + 1):
			var c := _heart + Vector2(ix, iy) * SCAN
			if c.distance_to(_heart) > reach or _gap(c, g) < APART:
				continue
			if found != Vector2.INF and c.distance_to(from) >= found.distance_to(from):
				continue
			var ground: Vector2 = _walkable.call(c)
			if ground.distance_to(c) > 0.05 or not _all_reach(g, c):
				continue
			found = c
	return found if found != Vector2.INF else near


## The least distance from `c` to any other group's centre.
func _gap(c: Vector2, except: Group) -> float:
	var gap := INF
	for o in _groups:
		if o != except and o.centre != Vector2.INF:
			gap = minf(gap, o.centre.distance_to(c))
	return gap


func _all_reach(g: Group, at: Vector2) -> bool:
	for v: Variant in g.members:
		if is_instance_valid(v) and not _reaches.call(v, at):
			return false
	return true


## Spaces `g`'s people evenly on the ring about its centre, each slot nudged to walkable ground.
func _space(g: Group) -> void:
	g.spots.clear()
	_prune(g)
	var n := g.members.size()
	var turn := _rng.randf() * TAU
	for k in n:
		var slot: Vector2 = g.centre + Vector2.from_angle(turn + TAU * float(k) / float(n)) * RING
		g.spots[(g.members[k] as Person).get_instance_id()] = _spot_for(g.members[k], g.centre, slot)


## `who`'s spot for a ring slot: the slot nudged to walkable ground, but only if that is inside the fair's radius and he has a way
## to it; else the slot pulled toward the centre by a quarter at a time, down to the centre itself (which _place() chose walkable and
## reachable by all). A wide RING never puts a spot outside the fair or out of reach.
func _spot_for(who: Variant, centre: Vector2, slot: Vector2) -> Vector2:
	for f: float in [1.0, 0.75, 0.5, 0.25]:
		var w: Vector2 = _walkable.call(centre + (slot - centre) * f)
		if w.distance_to(_heart) <= _radius + 0.005 and (not is_instance_valid(who) or _reaches.call(who, w)):
			return w
	return centre
