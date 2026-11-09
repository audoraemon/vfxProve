class_name WillOWisp
extends FxTimeline
## Will-o'-Wisp (v0.06): a pale light hovers at the aim for WISP_TIME. Up to LURE_MAX citizens within LURE_REACH who
## are going about their day, watching, recovering or regrouping -- nearest first -- walk to it and stand staring in
## a loose ring (Person.lure()), then go back to their day. No danger and no alarm: curiosity. Gather a crowd, then
## strike it. It locks the other slots only while it is cast (busy).
## Its second mode, ENTHRALL: the light burns brighter for ENTHRALL_TIME, and everyone living in the open within ENTHRALL_R of it --
## calm, frightened or fleeing, however many -- walks to a spot on a ring round it and stands there, held by a will nothing breaks
## (Person.compel(), as Voice of God's GATHER); every ENTHRALL_SCAN seconds those who have come within reach since join at once.
## A director's charge joins only within its lure reach, as in LURE, and never while a director has him staring at a light (Person.lured(),
## which would be his being pulled in from afar): one seen so is left alone for the whole of the burn; a soldier only at his post or
## holding, and not hurrying; the fighting, the sleeping and those indoors are left alone. When the light goes out the held are released and go back to their day.
## It waits 75 s (the mode's own cooldown). Quiet, like the lure.

const WISP_TIME := 12.0
const LURE_REACH := 6.0
const LURE_MAX := 25
## A director's charge (Person.answers_lure) answers only a Wisp cast this near him (v0.11.1, Decision 28): a Wisp cast to draw
## bystanders elsewhere does not pull him off his road.
const CHARGE_LURE_R := 3.0
## The ring the drawn stand in, round the light.
const RING := Vector2(0.8, 1.6)
## ENTHRALL: how far the light holds, how long it burns, how often it looks for newcomers.
const ENTHRALL_R := 4.0
const ENTHRALL_TIME := 30.0
const ENTHRALL_SCAN := 0.5
## ENTHRALL's ring spots: the first ring's radius, how much each next ring grows, and the room each held person takes on a ring.
const ENTHRALL_RING0 := 0.8
const ENTHRALL_RING_STEP := 0.6
const ENTHRALL_SPACING := 0.6
## Eight rings reach 5.0 from the light (ENTHRALL_R + 1); past them a person takes the nearest free ground to the edge of the circle on his side.
const ENTHRALL_RINGS := 8
const GLOW := [Color("e8fff4"), Color("9fe8d0"), Color("5cb8a8"), Color("2a6a6a")]
const LIGHT := Color(0.6, 1.0, 0.85)

var _light: QuadFx
var _enthrall := false
## ENTHRALL: the held, person -> ring spot; the seconds since the last look; the ring spots made so far (ring by ring).
var _held := {}
## ENTHRALL: those seen staring at a light (lured()) -- a director's pull, not a walk in on his own road -- and so never taken; person -> true.
var _skipped := {}
## ENTHRALL: where in `_spots` the take now under way looks next (everything before it is used or unwalkable).
var _cursor := 0
var _scan := 0.0
var _spots: Array[Vector2] = []
var _rings_made := 0
## This cast's lure cap, lure time and ENTHRALL hold at its ability level (LURE_MAX, WISP_TIME, ENTHRALL_TIME at level 1).
var lv_lure_max := LURE_MAX
var lv_wisp_time := WISP_TIME
var lv_enthrall_time := ENTHRALL_TIME


## Who it would draw from `at`: people within reach it can lure (v0.11.1: soldiers at their post too; a charge only within CHARGE_LURE_R), nearest first, LURE_MAX at most.
static func drawn(field: EnemyField, at: Vector2, cap := LURE_MAX) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, LURE_REACH):
		var p := e as Person
		if p == null or p.resists_mind() or p.inside:
			continue
		if p.answers_lure:
			if p.ground_pos.distance_to(at) <= p.lure_reach and (p.mind == Person.Mind.DUTY or p.mind in Person.LURABLE):
				out.append(p)
		elif p.mind in Person.LURABLE or (p.soldier and p.mind in Person.SOLDIER_LURABLE and not p.hurrying):
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, cap)


## Who ENTHRALL would take from `at` that is not in `skip` (a Dictionary keyed by person): the living in the open within ENTHRALL_R,
## nearest first (ties in field order). Not a fighter, a sleeper or one who resists; a charge only within its lure_reach; a soldier
## only at his post or holding, and not hurrying; not one staring at a light (Person.lured(): a director has pulled him in from afar,
## v0.11.1) -- such a one is put in `lured_out` (a Dictionary the caller keeps) and left out from then on, even when the lure ends.
static func enthralled(field: EnemyField, at: Vector2, skip := {}, lured_out := {}) -> Array[Person]:
	var found: Array = []
	var order := 0
	for e in field.in_radius(at, ENTHRALL_R):
		var p := e as Person
		if p == null or skip.has(p) or lured_out.has(p) or not p.is_alive() or p.inside or p.resists_mind() \
				or p.mind == Person.Mind.FIGHT or p.mind == Person.Mind.ASLEEP:
			continue
		if p.lured():
			lured_out[p] = true
			continue
		var d := p.ground_pos.distance_to(at)
		if p.answers_lure:
			if d > p.lure_reach:
				continue
		elif p.soldier and (p.hurrying or not p.mind in Person.SOLDIER_LURABLE):
			continue
		found.append([d, order, p])
		order += 1
	found.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var out: Array[Person] = []
	for f in found:
		out.append(f[2])
	return out


func _build() -> void:
	lv_lure_max = int(PowerBook.stat(extra, "wisp", "LURE_MAX", LURE_MAX))
	lv_wisp_time = float(PowerBook.stat(extra, "wisp", "WISP_TIME", WISP_TIME))
	lv_enthrall_time = float(PowerBook.stat(extra, "wisp", "ENTHRALL_TIME", ENTHRALL_TIME))
	_enthrall = String(extra.get("mode", "")) == "enthrall"
	if _enthrall:
		_build_enthrall()
		return
	duration = lv_wisp_time
	busy = 1.0
	var rng := ctx.rng
	for p in drawn(ctx.field, origin, lv_lure_max):
		var a := rng.randf() * TAU
		p.lure(origin + Vector2(cos(a), sin(a)) * rng.randf_range(RING.x, RING.y), lv_wisp_time - 0.5, origin, p.lure_reach)
	ctx.play(&"q_wisp", origin)
	_light = FxParts.ground_light(self, origin, 1.4, LIGHT, 0.0)
	var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -14),
		PixelParticles.Shape.SQUARE, GLOW, 6.0, lv_wisp_time - 1.0,
		{"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(6, 14),
		"life": Vector2(0.8, 1.4), "size": Vector2(1, 1)})
	motes.gravity = -8.0


## ENTHRALL: the light burns brighter and longer, a faint ring marks how far it holds, and everyone near is taken at once.
func _build_enthrall() -> void:
	duration = lv_enthrall_time
	busy = 1.0
	_take()
	ctx.play(&"q_wisp", origin)
	_light = FxParts.ground_light(self, origin, 2.2, LIGHT, 0.0)
	var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -14),
		PixelParticles.Shape.SQUARE, GLOW, 10.0, lv_enthrall_time - 1.0,
		{"radius": 5.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(6, 14),
		"life": Vector2(0.8, 1.4), "size": Vector2(1, 1)})
	motes.gravity = -8.0


## Take everyone newly within reach: each walks to the next free ring spot and stands there for as long as the light burns.
func _take() -> void:
	var left := maxf(duration - t, 0.5)
	var used := {}
	for q in _held:
		if is_instance_valid(q) and q.mind == Person.Mind.COMPELLED:
			used[_held[q]] = true
	_cursor = 0
	for p in enthralled(ctx.field, origin, _held, _skipped):
		var spot := _next_spot(p, used)
		if spot == Vector2.INF:
			continue
		if p.compel(spot, left, Person.WILL_ABSOLUTE, GLOW[1], false, &""):
			_held[p] = spot
			used[spot] = true


## The nearest free spot on the rings round the light that `p` can stand on: rings grow outward, each spot used once (`used`); the
## rings are made only as they are needed and the look goes on from where the last one left off. With the rings full, the nearest
## free ground to the circle's edge on his side of the light (else nothing: he is tried again at the next look).
func _next_spot(p: Person, used: Dictionary) -> Vector2:
	while true:
		while _cursor >= _spots.size():
			if _rings_made >= ENTHRALL_RINGS:
				return _edge_spot(p, used)
			_make_ring()
		var spot := _spots[_cursor]
		if used.has(spot) or (p.grid != null and not p.grid.walkable(spot)):
			_cursor += 1
			continue
		return spot
	return Vector2.INF


func _edge_spot(p: Person, used: Dictionary) -> Vector2:
	if p.grid == null:
		return Vector2.INF
	var dir := (p.ground_pos - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var spot: Vector2 = p.grid.nearest_walkable(origin + dir * ENTHRALL_R, 6)
	return Vector2.INF if spot == Vector2.INF or used.has(spot) else spot


func _make_ring() -> void:
	var radius := ENTHRALL_RING0 + ENTHRALL_RING_STEP * float(_rings_made)
	var n := maxi(floori(TAU * radius / ENTHRALL_SPACING), 6)
	var offset := 0.5 * float(_rings_made)
	for k in n:
		var a := offset + TAU * float(k) / float(n)
		_spots.append(origin + Vector2(cos(a), sin(a)) * radius)
	_rings_made += 1


## The light goes out (or is cut short): everyone still held by it is released; the dead stay dead.
func _release_all() -> void:
	for p in _held:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED and p.anchor == _held[p]:
			p.release_compulsion()
	_held.clear()


func end_now() -> void:
	if _enthrall and not finished:
		_release_all()
	super.end_now()


func _fade() -> float:
	return clampf(minf(t / 0.5, (duration - t) / 1.0), 0.0, 1.0)


## The light breathes with the orb, and the orb bobs and flickers.
func _fx_process(delta: float) -> void:
	if _enthrall:
		_scan += delta
		if t >= duration:
			_release_all()
		elif _scan >= ENTHRALL_SCAN:
			_scan = fmod(_scan, ENTHRALL_SCAN)
			_take()
	if is_instance_valid(_light):
		_light.set_param("intensity", (0.65 if _enthrall else 0.4) * _fade() * (0.85 + 0.15 * sin(t * 6.0)))
	queue_redraw()


func _draw() -> void:
	var fade := _fade()
	var at := Iso.ground_to_screen(origin) + Vector2(0, -14.0 + sin(t * 2.2) * 2.0)
	var flick := 0.85 + 0.15 * sin(t * 17.0) * sin(t * 5.3)
	for k in 4:
		var c: Color = GLOW[3 - k]
		c.a = fade * flick * (0.25 + 0.25 * k)
		draw_circle(at.round(), (9.0 if _enthrall else 7.0) - 1.6 * k, c)
	if _enthrall:
		# A faint ring on the ground where the light holds.
		var ring := PackedVector2Array()
		for k in 49:
			var a := TAU * float(k) / 48.0
			ring.append(Iso.ground_to_screen(origin + Vector2(cos(a), sin(a)) * ENTHRALL_R))
		var rc: Color = GLOW[1]
		rc.a = fade * 0.22
		draw_polyline(ring, rc, 1.0)
