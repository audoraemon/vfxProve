class_name WindfallFx
extends FxTimeline
## Windfall (Passage, Tier I): a load from somewhere else, dropped out of the sky in a line. Aimed by a drag: the line
## is LENGTH long along it, centred on the press, SEG wide -- a low wall of crates and stone, SEGMENTS of them. T_DROP
## after the cast they come down: whoever stands within KILL_R of a segment's middle is crushed (damage kind stone),
## what stands within HIT_R of one takes DAMAGE (stone: no fire), and the segments stay where they fell -- structures
## (role windfall) that close the walk grid under them, so a street or a gate's mouth is barred. They are the town's to
## clear, and it takes time: an engineer team cuts a segment away (EngineerManager's Clear job, CLEAR_WEIGHT times a
## thorn segment's), and until then the nearest free people -- up to CLEARERS citizens or soldiers within CALL_R, called
## every CALL_EVERY -- come and work at it: every second each one at the line (within WORK_R of a segment, not
## frightened; CLEARERS at most count) takes a second off the CLEAR_WORK it needs, and the line is taken down from
## its ends as the work goes. Unattended it stands LIFE. A segment does not fall inside a building. Loud: the fall is
## seen and heard (PowerBook.REACH), from the drop.

const T_DROP := 0.8
const LENGTH := 3.6
const SEGMENTS := 6
const SEG := 0.6
const KILL_R := 0.45
const HIT_R := 0.7
const DAMAGE := 30.0
const HEIGHT := 8.0
const LIFE := 180.0
const CLEAR_WORK := 150.0
const CLEARERS := 3
## An engineer team's Clear job on one segment takes this many times a thorn segment's time.
const CLEAR_WEIGHT := 2.0
const CALL_R := 6.0
const CALL_EVERY := 3.0
const WORK_R := 1.3
const FALL := 380.0
const WOOD := [Color("b8894a"), Color("8a6234"), Color("5a3f22"), Color("33261a")]

## The segments still lying there (in line order), how many it crushed, and the work still needed to clear them.
var piles: Array[Structure] = []
var crushed := 0
var work_left := CLEAR_WORK
## Whether the town cleared it (by hand or by the engineers), and how many were called to it.
var cleared := false
var called := 0

var _dir := Vector2(1, 0)
var _call_in := 0.0
var _work_in := 0.0
var _heap: Heap
var _landed := false


## The segments' footprints for a line centred on `at` along `dir`.
static func rects(at: Vector2, dir: Vector2) -> Array[Rect2]:
	var unit := dir.normalized() if dir.length() > 0.01 else Vector2(1, 0)
	var out: Array[Rect2] = []
	for k in SEGMENTS:
		var c := at + unit * (-LENGTH * 0.5 + LENGTH * (float(k) + 0.5) / float(SEGMENTS))
		out.append(Rect2(c - Vector2(SEG, SEG) * 0.5, Vector2(SEG, SEG)))
	return out


func _build() -> void:
	_dir = extra.get("dir", Vector2(1, 0))
	if _dir.length() < 0.01:
		_dir = Vector2(1, 0)
	_dir = _dir.normalized()
	duration = T_DROP + LIFE + 0.5
	busy = T_DROP
	at(T_DROP, _land)
	ctx.play(&"cf_fall", origin, 6.0)
	if not DominionParts.staged(self):
		return
	for r in rects(origin, _dir):
		var mark := FxParts.rings(self, r.get_center(), HIT_R, Color("ffb060"), 1, 6.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_DROP * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_DROP + 0.05
	var load := Load.new()
	load.fx = self
	load.z_index = 6
	track(load, ctx.overhead)


func _land() -> void:
	_landed = true
	var centres: Array[Vector2] = []
	var all := rects(origin, _dir)
	# The blows first, the whole line at once, then the segments: a segment's own blow must not break the one before.
	for r in all:
		var c := r.get_center()
		for e in ctx.field.in_radius(c, KILL_R):
			var p := e as Person
			if p != null and p.inside:
				continue
			if ctx.field.kill(e, &"stone", c):
				crushed += 1
		ctx.env.damage_radius(c, HIT_R, DAMAGE, &"stone")
	for r in all:
		var c := r.get_center()
		if ctx.env.blocked(c, 0.0):
			continue  # not inside a building
		# Whoever stands where it lies (and lived) is pushed just clear of the line.
		for e in ctx.field.in_radius(c, SEG):
			if r.grow(0.15).has_point(e.ground_pos):
				var side := Vector2(-_dir.y, _dir.x)
				var away := (e.ground_pos - c).dot(side)
				var out := side * (1.0 if away >= 0.0 else -1.0)
				for d: float in [0.7, 1.0, 1.3]:
					if not ctx.env.blocked(c + out * d):
						e.ground_pos = c + out * d
						break
		var s := ctx.env.add_structure(r, HEIGHT, Structure.Kind.CRATES, &"windfall")
		piles.append(s)
		centres.append(c)
	ctx.play(&"cf_impact", origin, 0.0)
	ctx.play(&"jg_crumble", origin, 2.0)
	if piles.is_empty():
		duration = minf(duration, t + 1.5)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(1.0, 0.9, 0.7, 0.14), 0.2)
	ctx.impact.hitstop(0.04)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	for c in centres:
		var sp := Iso.ground_to_screen(c)
		FxParts.debris(self, sp, 6, 6.0, Vector2(40, 180), WOOD, Vector2(1.5, 3.5), true)
		FxParts.debris(self, sp, 3, 5.0, Vector2(30, 140), FxParts.ROCK, Vector2(1.5, 3.0), true)
		FxParts.smoke(self, sp, 6.0, 10.0, 0.5, Vector2(14, 36), Vector2(2, 5), Vector2(0.8, 1.4))
	var ring := FxParts.shockwave(self, origin, LENGTH * 0.5 + 0.8, FxParts.FIRE)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.8, 0.0, 0.2, 0.15)
	ring.life = 0.38
	if not piles.is_empty():
		# The structures are only the obstacle: the line itself is drawn here, crates and stone as they fell.
		for s in piles:
			s.visible = false
		_heap = Heap.new()
		_heap.fx = self
		_heap.rng.seed = ctx.rng.randi()
		_heap.position = Iso.ground_to_screen(origin)
		track(_heap, ctx.world)


## Whether any of the line still lies there.
func standing() -> bool:
	_prune()
	return not piles.is_empty()


## Forget segments gone by other hands (the engineers, a blast).
func _prune() -> void:
	var kept: Array[Structure] = []
	for s in piles:
		if is_instance_valid(s) and not s.destroyed and ctx.env.structures().has(s):
			kept.append(s)
	piles = kept


## The segments' middles, in line order.
func centres() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for s in piles:
		if is_instance_valid(s):
			out.append(s.center())
	return out


func _fx_process(delta: float) -> void:
	if not _landed:
		return
	if not standing():
		cleared = cleared or t < T_DROP + LIFE
		if _heap != null and is_instance_valid(_heap):
			_heap.queue_free()
		_heap = null
		duration = minf(duration, t + 0.5)
		return
	if t >= T_DROP + LIFE:
		_remove_all()
		return
	_work_in -= delta
	if _work_in <= 0.0:
		_work_in = 1.0
		work_left -= float(mini(_workers().size(), CLEARERS))  # only so many hands fit along it
		# The line comes down from its ends as the work goes: as many segments stand as the work left warrants.
		var keep := int(ceil(float(SEGMENTS) * clampf(work_left / CLEAR_WORK, 0.0, 1.0)))
		while piles.size() > keep:
			var s: Structure = piles.pop_back() if piles.size() % 2 == 0 else piles.pop_front()
			_take_away(s)
		if piles.is_empty():
			cleared = true
			duration = minf(duration, t + 0.5)
			return
	_call_in -= delta
	if _call_in <= 0.0:
		_call_in = CALL_EVERY
		_call()


## Those at the line and able to work: alive, outside, not frightened or fighting.
func _workers() -> Array[Person]:
	var out: Array[Person] = []
	for c in centres():
		for e in ctx.field.in_radius(c, WORK_R):
			var p := e as Person
			if p == null or p.inside or not p.is_alive() or out.has(p):
				continue
			if p.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.FIGHT, Person.Mind.CONFUSED, Person.Mind.ASLEEP, Person.Mind.SHELTER]:
				continue
			out.append(p)
	return out


## The nearest free people are called to it, until CLEARERS are at it.
func _call() -> void:
	var need := CLEARERS - _workers().size()
	if need <= 0 or piles.is_empty():
		return
	for p in DominionParts.near(ctx.field, origin, CALL_R):
		if need <= 0:
			break
		var nearest := Vector2.INF
		for c in centres():
			if nearest == Vector2.INF or c.distance_to(p.ground_pos) < nearest.distance_to(p.ground_pos):
				nearest = c
		if nearest.distance_to(p.ground_pos) <= WORK_R:
			continue
		var side := Vector2(-_dir.y, _dir.x) * (1.0 if ctx.rng.randf() < 0.5 else -1.0)
		var spot := nearest + side * (SEG * 0.5 + 0.45)
		if p.grid != null:
			var w := p.grid.nearest_walkable(spot)
			if w != Vector2.INF:
				spot = w
		if p.lure(spot, CALL_EVERY * 2.0):
			called += 1
			need -= 1


func _take_away(s: Structure) -> void:
	if is_instance_valid(s) and ctx.env.structures().has(s):
		var at_pile := s.center()
		ctx.env.remove(s)
		if DominionParts.staged(self):
			FxParts.debris(self, Iso.ground_to_screen(at_pile), 6, 5.0, Vector2(20, 90), WOOD, Vector2(1.5, 3.0), true)


func _remove_all() -> void:
	for s in piles.duplicate():
		_take_away(s)
	piles.clear()
	if _heap != null and is_instance_valid(_heap):
		_heap.queue_free()
	_heap = null
	duration = minf(duration, t + 0.5)


## Cut short (FxTimeline.end_now()): the line goes with it, or it would block the way for good.
func end_now() -> void:
	_remove_all()
	super()


## The load on its way down: a crate or a stone over each segment, falling together onto the marks, each with a
## shadow closing under it.
class Load extends Node2D:
	var fx: WindfallFx

	func _process(_delta: float) -> void:
		if fx.t >= T_DROP:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(fx.t / T_DROP, 0.0, 1.0)
		var up := FALL * (1.0 - k * k)
		var i := 0
		for r in WindfallFx.rects(fx.origin, fx._dir):
			var to := Iso.ground_to_screen(r.get_center())
			draw_set_transform(to, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 4.0 + 8.0 * k, Color(0.0, 0.0, 0.0, 0.15 + 0.3 * k))
			draw_set_transform(Vector2.ZERO)
			var stone := i % 3 == 1
			var col: Color = FxParts.ROCK[0] if stone else WOOD[i % 2]
			var s := 7.0 if stone else 8.0
			var c := to + Vector2(0, -up - 6.0 - float(i % 2) * 3.0)
			draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), col)
			draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, 2)), col.lightened(0.25))
			draw_rect(Rect2(c - Vector2(s, s) * 0.5 + Vector2(0, s - 2), Vector2(s, 2)), col.darkened(0.35))
			i += 1


## The line as it lies: a low wall of crates and blocks along the segments that still stand, drawn in the world layer
## so people sort round it.
class Heap extends Node2D:
	const STONE := [Color("8a8f9c"), Color("6a6f7c"), Color("4c505c")]
	var fx: WindfallFx
	var rng := RandomNumberGenerator.new()
	var _jitter: Array = []

	func _ready() -> void:
		for i in SEGMENTS * 2:
			_jitter.append(Vector2(rng.randf_range(-0.06, 0.06), rng.randf_range(-0.06, 0.06)))

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var cs := fx.centres()
		if cs.is_empty():
			return
		# Dust under the whole line.
		for c in cs:
			var sp := Iso.ground_to_screen(c) - position
			draw_set_transform(sp, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 16.0, Color(0.0, 0.0, 0.0, 0.2))
			draw_set_transform(Vector2.ZERO)
		# Back to front: the segments sorted by screen depth, two pieces each.
		var order := cs.duplicate()
		order.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x + a.y < b.x + b.y)
		for c in order:
			var i := cs.find(c)
			var j0: Vector2 = _jitter[(i * 2) % _jitter.size()]
			var j1: Vector2 = _jitter[(i * 2 + 1) % _jitter.size()]
			var stone := i % 3 == 1
			_box(c + Vector2(-0.12, 0.1) + j0, 0.42, 7.0, 0.0, stone)
			_box(c + Vector2(0.14, -0.1) + j1, 0.36, 6.0, 0.0, not stone and i % 2 == 0)
			if i % 2 == 1:
				_box(c + j0 * 0.5, 0.3, 5.0, 7.0, stone)

	## One crate or block: a ground square of `size` at `at`, `tall` pixels high, `lift` pixels off the ground.
	func _box(at: Vector2, size: float, tall: float, lift: float, stone: bool) -> void:
		var h := size * 0.5
		var e := Iso.ground_to_screen(at + Vector2(h, -h)) - position + Vector2(0, -lift)
		var sth := Iso.ground_to_screen(at + Vector2(h, h)) - position + Vector2(0, -lift)
		var w := Iso.ground_to_screen(at + Vector2(-h, h)) - position + Vector2(0, -lift)
		var n := Iso.ground_to_screen(at + Vector2(-h, -h)) - position + Vector2(0, -lift)
		var up := Vector2(0, -tall)
		var top: Color = STONE[0] if stone else WOOD[0]
		var lf: Color = STONE[1] if stone else WOOD[1]
		var rf: Color = STONE[2] if stone else WOOD[2]
		draw_colored_polygon(PackedVector2Array([w, sth, sth + up, w + up]), lf)
		draw_colored_polygon(PackedVector2Array([sth, e, e + up, sth + up]), rf)
		draw_colored_polygon(PackedVector2Array([n + up, e + up, sth + up, w + up]), top)
		if not stone:
			draw_line(w + up * 0.5, sth + up * 0.5, WOOD[3], 1.0)
			draw_line(sth + up * 0.5, e + up * 0.5, WOOD[3], 1.0)
		draw_polyline(PackedVector2Array([n + up, e + up, sth + up, w + up, n + up]), Color(0.1, 0.07, 0.05, 0.55), 1.0)
		draw_line(sth, sth + up, Color(0.1, 0.07, 0.05, 0.45), 1.0)
