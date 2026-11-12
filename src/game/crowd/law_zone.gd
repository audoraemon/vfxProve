class_name LawZone
extends RefCounted
## Decree's law on a place (spec §4.2): a law that holds inside a circle (circle()) or a strip (lane()) for `seconds`,
## built like FoldWard: a power builds one and lays it on the crowd (Crowd.add_law()), which steps it every frame and
## answers every choice that asks whether someone stands in a law of some kind (Crowd.in_law()). Kinds:
##   no_leaving  held by the zone itself (step()): whoever stands inside -- a person out in the open, or a visitor from
##               the other side -- cannot walk out. At the edge he is set back onto it each frame, and hesitates and
##               turns (Person.hesitate(HESITATE)) at most every TURN_EVERY. Walking in is free, and whoever walks in is
##               held too. One carried more than CARRIED past the edge by something greater (a blast, a Mirrorfold) is
##               let go. One indoors, or a rite's chained captive, is left alone (the chain is stronger than the law).
##   no_breath, disorder, no_running, no_arms, no_doors, no_sight
##               only asked (Crowd.in_law(), Crowd.law_of()): the powers and the choice points act on them (NO BREATH:
##               Breathing Is Prohibited chokes the people; Visitors run out of it).
## Each zone holds its own: two laid on the same ground both hold, and lifting one leaves the other. A zone ends when
## its seconds run out, when it is lifted (Crowd.remove_law()), or when the effect that laid it goes (add_law()'s
## holder). No number is drawn from any rng.

## How long one held at the edge stands and turns, and how often at most.
const HESITATE := 0.6
const TURN_EVERY := 1.2
## How far past the edge one must be carried to be free of NO LEAVING.
const CARRIED := 1.5
## Leeway on the edge, for points computed onto it.
const EPS := 0.0001

const NO_LEAVING := &"no_leaving"
const NO_BREATH := &"no_breath"

## The kinds of law it holds.
var kinds: Array[StringName] = []
## A circle's radius, or a lane's half width. Mutable: a power may shrink it while it holds (The Closing Cage).
var radius := 3.0
## A circle's centre (a == b), or a lane's two ends.
var a := Vector2.ZERO
var b := Vector2.ZERO
var is_lane := false
## Seconds left.
var left := 0.0
## The effect that laid it (Crowd.add_law(); hold_by()); the zone ends when it is freed. null for none.
var holder: Node
## Whether its holder steps it on its own clock (Crowd.step_law(), as the effect's frame runs) rather than the crowd's
## frame (Crowd.step_laws() then leaves it to the holder, and only drops it once it has ended). Leaving Is Prohibited's
## cell holds on the effect's clock.
var stepped_by_holder := false
## NO LEAVING: whoever it holds now (a Person or an Animal) -> seconds until it may be turned back again.
var members := {}
## How many times someone has been turned back at the edge (each hesitation), and what the last step() did: the
## [body, edge point] of each turned back, and the bodies let go (carried past CARRIED, or the law lifted on them).
var turned_back := 0
var turned: Array = []
var released: Array = []

var _lifted := false
## Whether a holder was given: a freed one compares equal to null, so this remembers there was one.
var _held := false


## A law of `kinds` on the circle of `r` round `at`, for `seconds`.
static func circle(at: Vector2, r: float, law_kinds: Array[StringName], seconds: float) -> LawZone:
	var z := LawZone.new()
	z.a = at
	z.b = at
	z.radius = r
	z.kinds = law_kinds.duplicate()
	z.left = seconds
	return z


## A law of `kinds` on the strip from `from` to `to`, `half_width` to each side (square ends), for `seconds`.
static func lane(from: Vector2, to: Vector2, half_width: float, law_kinds: Array[StringName], seconds: float) -> LawZone:
	var z := circle(from, half_width, law_kinds, seconds)
	z.b = to
	z.is_lane = true
	return z


## Whether the law still holds: its time not run out, not lifted, its effect not gone.
func alive() -> bool:
	return not _lifted and left > 0.0 and (not _held or is_instance_valid(holder))


## It lasts no longer than `node` (null: no holder): freed, it holds no more.
func hold_by(node: Node) -> void:
	holder = node
	_held = node != null


## Whether it holds a law of `kind`.
func holds(kind: StringName) -> bool:
	return kinds.has(kind)


## Whether `g` stands inside (the edge counts as inside).
func contains(g: Vector2) -> bool:
	if not is_lane:
		return g.distance_squared_to(a) <= (radius + EPS) * (radius + EPS)
	var along := b - a
	var length := along.length()
	var u := along / length if length > 0.0 else Vector2.RIGHT
	var d := g - a
	var s := d.dot(u)
	return s >= -EPS and s <= length + EPS and absf(d.dot(u.orthogonal())) <= radius + EPS


## The nearest point to `g` inside the zone: `g` itself when it is inside, else the nearest point on the edge.
func nearest_inside(g: Vector2) -> Vector2:
	if not is_lane:
		var d := g - a
		var far := d.length()
		return g if far <= radius or far == 0.0 else a + d / far * radius
	var along := b - a
	var length := along.length()
	var u := along / length if length > 0.0 else Vector2.RIGHT
	var n := u.orthogonal()
	var d := g - a
	return a + u * clampf(d.dot(u), 0.0, length) + n * clampf(d.dot(n), -radius, radius)


## The nearest point to `g` outside the zone, `beyond` past its edge: straight out from a circle's middle (from its
## middle itself: towards +x), or out of a lane's nearest side or end. Where one choking runs, or a visitor flees to.
func nearest_outside(g: Vector2, beyond := 0.0) -> Vector2:
	if not is_lane:
		var d := g - a
		var far := d.length()
		var dir := d / far if far > EPS else Vector2.RIGHT
		return a + dir * (radius + beyond)
	var along := b - a
	var length := along.length()
	var u := along / length if length > 0.0 else Vector2.RIGHT
	var n := u.orthogonal()
	var d := g - a
	var s := d.dot(u)
	var w := d.dot(n)
	var side := radius - absf(w)
	if side <= s and side <= length - s:
		return g + n * (signf(w) if w != 0.0 else 1.0) * (side + beyond)
	if s <= length - s:
		return g - u * (s + beyond)
	return g + u * (length - s + beyond)


## The ground it covers, edges included.
func bounds() -> Rect2:
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(radius, radius)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(radius, radius)
	return Rect2(lo, hi - lo)


## Lifted (Crowd.remove_law()): it holds no more, and lets go of everyone.
func lift() -> void:
	_lifted = true
	released = members.keys()
	members.clear()


## One frame. Time runs; under NO LEAVING, the people and visitors standing inside join it (from `people` and `beasts`,
## the crowd's list of who stands about its laws this frame, taken once for all of them) and every one held who has
## walked past the edge is set back onto it.
func step(delta: float, people: Array, beasts: Array) -> void:
	left -= delta
	turned.clear()
	released.clear()
	if not holds(NO_LEAVING) or not alive():
		return
	for e in people:
		var p := e as Person
		if p != null and not p.inside and not members.has(p) and contains(p.ground_pos):
			members[p] = 0.0
	for beast in beasts:
		if not members.has(beast) and contains((beast as Animal).ground_pos):
			members[beast] = 0.0
	for body: Variant in members.keys():
		if not is_instance_valid(body) or not body.is_alive():
			members.erase(body)
			continue
		var p := body as Person
		if p != null and (p.inside or p.chained):
			continue
		members[body] = maxf(float(members[body]) - delta, 0.0)
		var at: Vector2 = body.ground_pos
		var edge := nearest_inside(at)
		var out := at.distance_to(edge)
		if out <= EPS:
			continue
		if out > CARRIED:
			members.erase(body)
			released.append(body)
			continue
		body.ground_pos = edge
		if p == null:
			(body as Animal).sync_position()
		if float(members[body]) <= 0.0:
			members[body] = TURN_EVERY
			turned_back += 1
			turned.append([body, edge])
			if p != null:
				p.hesitate(HESITATE)

