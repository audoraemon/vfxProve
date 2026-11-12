class_name SacredSanctuaryFx
extends FxTimeline
## Sacred Sanctuary (Dominion, Tier IV): a wall of the town's own people round a place. Two clicks: the first on the
## people -- everyone within PICK_R, any role, nearest first up to MAX_GUARDS, is hypnotized -- the second on the place
## (extra "to"); the shape is the cast's mode (right-click switches it while the place is aimed): a CIRCLE of CIRCLE_R
## or a RECTANGLE of RECT. T_CAST later the hypnotized walk there and stand evenly along its edge, shoulder to
## shoulder (a compulsion of WILL: an evacuation does not call them away), for SPAN. Whoever and whatever stood inside
## when the wall was raised is under its protection; whoever comes in afterwards -- a citizen, a soldier, the brigade, a
## rescue squad -- is set on by the nearest GUARDS_PER_INTRUDER guards (Person.fight(), TARGET_ONLY) until they are down
## or out (a guard drives an intruder out and no farther, then goes back to its place, and no more than MAX_OFF of the
## wall is off its places at once); one who was inside and left is an intruder if they come back. Nothing is done to a building, and nothing can
## be done for one: a fire or a collapse inside is beyond the town's reach while the wall stands. Quiet, but for the
## book entry's "alarm". The cast locks the other slots until the wall is raised.

const PICK_R := 5.0
const MAX_GUARDS := 40
const CIRCLE_R := 4.0
const RECT := Vector2(8.0, 5.0)
const SPAN := 40.0
const T_CAST := 1.0
const WILL := 0.8
const RETHINK := 0.4
const GUARDS_PER_INTRUDER := 2
## The share of the wall that may be off its places at once, driving intruders out.
const MAX_OFF := 0.34
const CIVIL_BLOW := 0.34
const GUARD_SIGHT := 12.0
const HALLOW := Color("ffe9a8")
const SHIELD: Array[int] = [0b11111, 0b11111, 0b11111, 0b01110, 0b00100]

var shape := "circle"
## Where the sanctuary stands.
var site := Vector2.ZERO
## The wall: each guard and its place on the edge.
var guards: Array[Person] = []
var places: Array[Vector2] = []
## Those under its protection: Person -> true.
var sheltered := {}
## How many intruders the wall has been set on.
var repelled := 0
var raised := false

var _rethink_in := 0.0


## Whether `g` lies inside a sanctuary of `kind` at `centre`.
static func inside(kind: String, centre: Vector2, g: Vector2) -> bool:
	if kind == "rect":
		var d := g - centre
		return absf(d.x) <= RECT.x * 0.5 and absf(d.y) <= RECT.y * 0.5
	return g.distance_to(centre) <= CIRCLE_R


## `n` places evenly spaced along the edge of a sanctuary of `kind` at `centre`.
static func spots(kind: String, centre: Vector2, n: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if n <= 0:
		return out
	if kind == "rect":
		var w := RECT.x
		var h := RECT.y
		var around := 2.0 * (w + h)
		for i in n:
			var s := around * (float(i) + 0.5) / float(n)
			var p: Vector2
			if s < w:
				p = Vector2(-w * 0.5 + s, -h * 0.5)
			elif s < w + h:
				p = Vector2(w * 0.5, -h * 0.5 + (s - w))
			elif s < 2.0 * w + h:
				p = Vector2(w * 0.5 - (s - w - h), h * 0.5)
			else:
				p = Vector2(-w * 0.5, h * 0.5 - (s - 2.0 * w - h))
			out.append(centre + p)
		return out
	for i in n:
		out.append(centre + Vector2.from_angle(TAU * float(i) / float(n)) * CIRCLE_R)
	return out


## Whom a first click at `at` would hypnotize.
static func picked_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for p in DominionParts.near(field, at, PICK_R, MAX_GUARDS * 2):
		if out.size() >= MAX_GUARDS:
			break
		if not p.resists_mind():
			out.append(p)
	return out


func _build() -> void:
	shape = String(extra.get("mode", "circle"))
	if not shape in ["circle", "rect"]:
		shape = "circle"
	site = extra.get("to", origin)
	duration = T_CAST + SPAN + 0.5
	busy = T_CAST
	guards = picked_at(ctx.field, origin)
	if guards.is_empty():
		duration = 1.0
		return
	at(T_CAST, _raise)
	ctx.play(&"q_sanctuary", site)
	if not DominionParts.staged(self):
		return
	DominionParts.sky_sigil(self, site, 120.0, 120.0, HALLOW, T_CAST, 2.0)
	DominionParts.ground_sigil(self, origin, PICK_R, HALLOW, T_CAST * 0.8, 0.6)
	var glyph: Array[int] = []
	glyph.assign(SHIELD)
	var icon := DominionParts.icon(self, site, glyph, Color("fff6d8"), T_CAST + 2.5, 120.0)
	icon.px = 4


## The wall is raised: the places are set, the hypnotized sent to them, and who stands inside is taken under it.
func _raise() -> void:
	raised = true
	var alive: Array[Person] = []
	for p in guards:
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			alive.append(p)
	guards = alive
	places = spots(shape, site, guards.size())
	# Each to the nearest free place, so the wall forms without everyone crossing it.
	var free := places.duplicate()
	var assigned: Array[Vector2] = []
	for p in guards:
		var best := 0
		for i in free.size():
			if p.ground_pos.distance_squared_to(free[i]) < p.ground_pos.distance_squared_to(free[best]):
				best = i
		assigned.append(free[best])
		free.remove_at(best)
	places = assigned
	for i in guards.size():
		_post(guards[i], places[i])
	for e in ctx.field.in_radius(site, maxf(CIRCLE_R, RECT.length() * 0.5) + 0.5):
		var p := e as Person
		if p != null and not guards.has(p) and inside(shape, site, p.ground_pos):
			sheltered[p] = true
	ctx.play(&"dom_wall", site)
	if not DominionParts.staged(self):
		return
	var ground := Ground.new()
	ground.fx = self
	ground.position = site
	ground.z_index = 3
	track(ground, ctx.ground)
	var links := DominionParts.links(self)
	for p in guards:
		links.add(p, Iso.ground_to_screen(site) + Vector2(0, -120), HALLOW)
	DominionParts.pulse(self, site, CIRCLE_R + 1.0, HALLOW, 0.7, 1.5)


## A guard is sent to its place (or sent back to it).
func _post(p: Person, place: Vector2) -> void:
	var spot := place
	if p.grid != null:
		var w := p.grid.nearest_walkable(place)
		if w != Vector2.INF:
			spot = w
	var glyph: Array[int] = []
	glyph.assign(SHIELD)
	p.compel(spot, maxf(T_CAST + SPAN - t, 0.5), WILL, HALLOW, true, &"", glyph)


func _fx_process(delta: float) -> void:
	if not raised or t >= T_CAST + SPAN:
		return
	_rethink_in -= delta
	if _rethink_in > 0.0:
		return
	_rethink_in = RETHINK
	# Those under it who have left are under it no longer: coming back, they are strangers.
	for p: Person in sheltered.keys():
		if not is_instance_valid(p) or not p.is_alive() or not inside(shape, site, p.ground_pos):
			sheltered.erase(p)
	# A guard drives an intruder out, no farther: once its quarry is outside (or down) it lets go. And a guard that
	# has finished (or was shaken out of the wall) goes back to its place.
	var off := 0
	for i in guards.size():
		var g := guards[i]
		if not is_instance_valid(g) or not g.is_alive() or g.inside:
			continue
		if g.mind == Person.Mind.FIGHT:
			var quarry := g.fight_target
			if quarry == null or not is_instance_valid(quarry) or not quarry.is_alive() or not inside(shape, site, quarry.ground_pos):
				g.stop_fighting()
			else:
				off += 1
		if g.mind != Person.Mind.FIGHT and g.mind != Person.Mind.COMPELLED:
			_post(g, places[i])
	# The wall holds its shape: no more than a share of it leaves its places at once.
	var spare := maxi(int(float(guards.size()) * MAX_OFF) - off, 0)
	# Who is inside that the wall does not know?
	for e in ctx.field.in_radius(site, maxf(CIRCLE_R, RECT.length() * 0.5) + 1.0):
		var p := e as Person
		if p == null or not p.is_alive() or p.inside or guards.has(p):
			continue
		if sheltered.has(p) or not inside(shape, site, p.ground_pos):
			continue
		var set := 0
		var order := guards.duplicate()
		order.sort_custom(func(a: Person, b: Person) -> bool:
			return a.ground_pos.distance_squared_to(p.ground_pos) < b.ground_pos.distance_squared_to(p.ground_pos))
		var already := 0
		for g in order:
			if is_instance_valid(g) and g.mind == Person.Mind.FIGHT and g.fight_target == p:
				already += 1
		for g in order:
			if set + already >= GUARDS_PER_INTRUDER or spare <= 0:
				break
			if not is_instance_valid(g) or not g.is_alive() or g.inside or g.mind == Person.Mind.FIGHT:
				continue
			g.fight(p, 8.0, Person.SOLDIER_BLOW if g.soldier else CIVIL_BLOW, Person.FightRule.TARGET_ONLY, GUARD_SIGHT, &"sanctuary")
			set += 1
			spare -= 1
		if set > 0:
			repelled += 1
			if DominionParts.staged(self):
				DominionParts.pulse(self, p.ground_pos, 1.0, Color("ff4040"), 0.5, 0.8)


## How much of the sanctuary shows: in as the wall is raised, out as it falls.
func shown() -> float:
	return clampf(minf((t - T_CAST) / 0.6, (T_CAST + SPAN + 0.4 - t) / 0.8), 0.0, 1.0)


## The hallowed ground: the shape filled soft and edged in light, breathing; drawn in ground units.
class Ground extends Node2D:
	var fx: SacredSanctuaryFx

	func _process(_delta: float) -> void:
		if fx.t > T_CAST + SPAN + 0.5:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var breathe := 0.85 + 0.15 * sin(fx.t * 1.4)
		if fx.shape == "rect":
			var r := Rect2(-RECT * 0.5, RECT)
			draw_rect(r, Color(HALLOW, 0.1 * a * breathe))
			draw_rect(r, Color(0.05, 0.04, 0.02, 0.6 * a), false, 0.22)
			draw_rect(r, Color(HALLOW, 0.9 * a), false, 0.09)
			draw_rect(r.grow(-0.35), Color(HALLOW, 0.3 * a * breathe), false, 0.05)
		else:
			draw_circle(Vector2.ZERO, CIRCLE_R, Color(HALLOW, 0.1 * a * breathe))
			draw_arc(Vector2.ZERO, CIRCLE_R, 0.0, TAU, 72, Color(0.05, 0.04, 0.02, 0.6 * a), 0.22)
			draw_arc(Vector2.ZERO, CIRCLE_R, 0.0, TAU, 72, Color(HALLOW, 0.9 * a), 0.09)
			draw_arc(Vector2.ZERO, CIRCLE_R - 0.35, 0.0, TAU, 72, Color(HALLOW, 0.3 * a * breathe), 0.05)
