class_name WindfallFx
extends FxTimeline
## Windfall (Passage, Tier I): a load from somewhere else, dropped out of the sky. T_DROP after the cast a pile of
## crates and stone comes down on the click: whoever stands within KILL_R is crushed (damage kind stone), what stands
## within HIT_R takes DAMAGE (stone: no fire), and the pile stays where it fell -- a structure (role windfall) that
## closes the walk grid under it, so a street or a gate's mouth is blocked. It is the town's to clear, and it takes
## time: an engineer team cuts it away (EngineerManager's Clear job), and until then the nearest free people -- up to
## CLEARERS citizens or soldiers within CALL_R, called every CALL_EVERY -- come and work at it; every second each one
## at the pile (within WORK_R, not frightened) takes a second off the CLEAR_WORK it needs. Unattended it stands LIFE.
## It does not fall inside a building. Loud: the fall is seen and heard (PowerBook.REACH), from the drop.

const T_DROP := 0.8
const KILL_R := 0.6
const HIT_R := 0.9
const DAMAGE := 30.0
const SIZE := Vector2(1.2, 1.2)
const HEIGHT := 12.0
const LIFE := 120.0
const CLEAR_WORK := 24.0
const CLEARERS := 3
const CALL_R := 6.0
const CALL_EVERY := 3.0
const WORK_R := 1.5
const FALL := 380.0
const WOOD := [Color("b8894a"), Color("8a6234"), Color("5a3f22"), Color("33261a")]

## The pile, how many it crushed, and the work still needed to clear it.
var pile: Structure
var crushed := 0
var work_left := CLEAR_WORK
## Whether the town cleared it (by hand or by the engineers), and how many were called to it.
var cleared := false
var called := 0

var _call_in := 0.0
var _work_in := 0.0
var _heap: Heap


func _build() -> void:
	duration = T_DROP + LIFE + 0.5
	busy = T_DROP
	at(T_DROP, _land)
	ctx.play(&"cf_fall", origin, 6.0)
	if not DominionParts.staged(self):
		return
	var mark := FxParts.rings(self, origin, HIT_R, Color("ffb060"), 1, 8.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_DROP * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_DROP + 0.05
	var load := Load.new()
	load.fx = self
	load.z_index = 6
	track(load, ctx.overhead)


func _land() -> void:
	for e in ctx.field.in_radius(origin, KILL_R):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"stone", origin):
			crushed += 1
	ctx.env.damage_radius(origin, HIT_R, DAMAGE, &"stone")
	if not ctx.env.blocked(origin, 0.0):
		# Whoever stands where it lies (and lived) is pushed just clear of it.
		var r := Rect2(origin - SIZE * 0.5, SIZE)
		for e in ctx.field.in_radius(origin, SIZE.length()):
			if r.grow(0.15).has_point(e.ground_pos):
				var away := e.ground_pos - origin
				var dir := away.normalized() if away.length() > 0.01 else Vector2(0, 1)
				for d: float in [0.9, 1.2, 1.5]:
					if not ctx.env.blocked(origin + dir * d):
						e.ground_pos = origin + dir * d
						break
		pile = ctx.env.add_structure(r, HEIGHT, Structure.Kind.CRATES, &"windfall")
		if DominionParts.staged(self):
			# The structure is only the obstacle: the pile itself is drawn here, crates and stone as they fell.
			pile.visible = false
			_heap = Heap.new()
			_heap.at = origin
			_heap.rng.seed = ctx.rng.randi()
			_heap.position = Iso.ground_to_screen(origin)
			track(_heap, ctx.world)
	ctx.play(&"cf_impact", origin, 0.0)
	ctx.play(&"jg_crumble", origin, 2.0)
	if pile == null:
		duration = minf(duration, t + 1.5)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(1.0, 0.9, 0.7, 0.14), 0.2)
	ctx.impact.hitstop(0.04)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	var ring := FxParts.shockwave(self, origin, HIT_R + 0.8, FxParts.FIRE)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.32, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.8, 0.0, 0.2, 0.15)
	ring.life = 0.36
	FxParts.debris(self, sp, 14, 8.0, Vector2(40, 200), WOOD, Vector2(1.5, 4.0), true)
	FxParts.debris(self, sp, 8, 6.0, Vector2(30, 160), FxParts.ROCK, Vector2(1.5, 3.5), true)
	FxParts.smoke(self, sp, 9.0, 16.0, 0.6, Vector2(16, 44), Vector2(3, 6), Vector2(0.9, 1.6))


## Whether the pile still lies there.
func standing() -> bool:
	return pile != null and is_instance_valid(pile) and not pile.destroyed and ctx.env.structures().has(pile)


func _fx_process(delta: float) -> void:
	if pile == null:
		return
	if _heap != null and is_instance_valid(_heap):
		_heap.left = clampf(work_left / CLEAR_WORK, 0.0, 1.0)
	if not standing():
		# Gone: cut away by the engineers, or smashed by something else.
		if _heap != null and is_instance_valid(_heap):
			_heap.queue_free()
		_heap = null
		cleared = cleared or t < T_DROP + LIFE
		pile = null
		duration = minf(duration, t + 0.5)
		return
	if t >= T_DROP + LIFE:
		_remove()
		return
	_work_in -= delta
	if _work_in <= 0.0:
		_work_in = 1.0
		work_left -= float(_workers().size())
		if work_left <= 0.0:
			cleared = true
			_remove()
			return
	_call_in -= delta
	if _call_in <= 0.0:
		_call_in = CALL_EVERY
		_call()


## Those at the pile and able to work: alive, outside, not frightened or fighting.
func _workers() -> Array[Person]:
	var out: Array[Person] = []
	for e in ctx.field.in_radius(pile.center(), WORK_R):
		var p := e as Person
		if p == null or p.inside or not p.is_alive():
			continue
		if p.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.FIGHT, Person.Mind.CONFUSED, Person.Mind.ASLEEP, Person.Mind.SHELTER]:
			continue
		out.append(p)
	return out


## The nearest free people are called to it, until CLEARERS are at it.
func _call() -> void:
	var need := CLEARERS - _workers().size()
	if need <= 0:
		return
	for p in DominionParts.near(ctx.field, pile.center(), CALL_R):
		if need <= 0:
			break
		if p.ground_pos.distance_to(pile.center()) <= WORK_R:
			continue
		var a := ctx.rng.randf() * TAU
		var spot := pile.center() + Vector2(cos(a), sin(a)) * (SIZE.x * 0.5 + 0.45)
		if p.grid != null:
			var w := p.grid.nearest_walkable(spot)
			if w != Vector2.INF:
				spot = w
		if p.lure(spot, CALL_EVERY * 2.0):
			called += 1
			need -= 1


func _remove() -> void:
	if _heap != null and is_instance_valid(_heap):
		_heap.queue_free()
	_heap = null
	if standing():
		var at_pile := pile.center()
		ctx.env.remove(pile)
		if DominionParts.staged(self):
			FxParts.debris(self, Iso.ground_to_screen(at_pile), 8, 6.0, Vector2(20, 90), WOOD, Vector2(1.5, 3.0), true)
	pile = null
	duration = minf(duration, t + 0.5)


## Cut short (FxTimeline.end_now()): the pile goes with it, or it would block the way for good.
func end_now() -> void:
	_remove()
	super()


## The load on its way down: a few crates and stones falling together onto the mark, with a shadow closing under them.
class Load extends Node2D:
	var fx: WindfallFx

	func _process(_delta: float) -> void:
		if fx.t >= T_DROP:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(fx.t / T_DROP, 0.0, 1.0)
		var to := Iso.ground_to_screen(fx.origin)
		var up := FALL * (1.0 - k * k)
		# The shadow, closing.
		draw_set_transform(to, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 6.0 + 14.0 * k, Color(0.0, 0.0, 0.0, 0.15 + 0.3 * k))
		draw_set_transform(Vector2.ZERO)
		var boxes := [[Vector2(-8, 0), 9.0, WOOD[1]], [Vector2(7, -3), 8.0, WOOD[0]], [Vector2(0, -11), 7.0, FxParts.ROCK[0]], [Vector2(-3, 6), 6.0, FxParts.ROCK[1]]]
		for b in boxes:
			var c: Vector2 = to + (b[0] as Vector2) + Vector2(0, -up - 8.0)
			var s: float = b[1]
			draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), b[2])
			draw_rect(Rect2(c - Vector2(s, s) * 0.5, Vector2(s, 2)), (b[2] as Color).lightened(0.25))
			draw_rect(Rect2(c - Vector2(s, s) * 0.5 + Vector2(0, s - 2), Vector2(s, 2)), (b[2] as Color).darkened(0.35))


## The pile as it lies: crates and blocks of stone heaped where they fell, drawn in the world layer so people sort
## round it. As it is cleared (`left` 1..0) the top of the heap goes first.
class Heap extends Node2D:
	const STONE := [Color("8a8f9c"), Color("6a6f7c"), Color("4c505c")]
	var at := Vector2.ZERO
	var left := 1.0
	var rng := RandomNumberGenerator.new()
	## The pieces: [ground offset, ground size, height px, lift px, is stone], back to front.
	var _pieces: Array = []

	func _ready() -> void:
		var spots := [[Vector2(-0.3, -0.3), 0.5, 11.0, 0.0, false], [Vector2(0.28, -0.26), 0.42, 8.0, 0.0, true],
			[Vector2(-0.28, 0.3), 0.4, 7.0, 0.0, true], [Vector2(0.3, 0.3), 0.5, 10.0, 0.0, false],
			[Vector2(0.0, 0.0), 0.46, 9.0, 0.0, false], [Vector2(-0.05, -0.08), 0.36, 8.0, 10.0, false],
			[Vector2(0.2, 0.12), 0.3, 6.0, 9.0, true]]
		for sp in spots:
			var jitter := Vector2(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05))
			_pieces.append([(sp[0] as Vector2) + jitter, float(sp[1]) * rng.randf_range(0.9, 1.1), sp[2], sp[3], sp[4]])
		_pieces.sort_custom(func(a, b) -> bool:
			var da: Vector2 = a[0]
			var db: Vector2 = b[0]
			return da.x + da.y + float(a[3]) * 0.01 < db.x + db.y + float(b[3]) * 0.01)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		# Dust and splinters on the ground under it.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		draw_circle(Vector2.ZERO, 30.0, Color(0.0, 0.0, 0.0, 0.22))
		draw_set_transform(Vector2.ZERO)
		var shown := maxi(int(ceil(float(_pieces.size()) * (0.35 + 0.65 * left))), 2)
		var drawn := 0
		for pc in _pieces:
			# The lifted pieces (the top of the heap) are the first to go.
			if float(pc[3]) > 0.0 and drawn >= shown - 1 and left < 0.6:
				continue
			if drawn >= shown:
				break
			drawn += 1
			_box(pc[0], float(pc[1]), float(pc[2]), float(pc[3]), bool(pc[4]))

	## One crate or block: a ground square of `size` at `off`, `tall` pixels high, `lift` pixels off the ground.
	func _box(off: Vector2, size: float, tall: float, lift: float, stone: bool) -> void:
		var h := size * 0.5
		var c := Iso.ground_to_screen(at + off) - position + Vector2(0, -lift)
		var e := Iso.ground_to_screen(at + off + Vector2(h, -h)) - position + Vector2(0, -lift)  # right corner
		var sth := Iso.ground_to_screen(at + off + Vector2(h, h)) - position + Vector2(0, -lift)  # near corner
		var w := Iso.ground_to_screen(at + off + Vector2(-h, h)) - position + Vector2(0, -lift)  # left corner
		var n := Iso.ground_to_screen(at + off + Vector2(-h, -h)) - position + Vector2(0, -lift)  # far corner
		var up := Vector2(0, -tall)
		var top: Color = STONE[0] if stone else WOOD[0]
		var lf: Color = STONE[1] if stone else WOOD[1]
		var rf: Color = STONE[2] if stone else WOOD[2]
		draw_colored_polygon(PackedVector2Array([w, sth, sth + up, w + up]), lf)
		draw_colored_polygon(PackedVector2Array([sth, e, e + up, sth + up]), rf)
		draw_colored_polygon(PackedVector2Array([n + up, e + up, sth + up, w + up]), top)
		if not stone:
			# Planks: a band round the crate and a brace across the near faces.
			draw_line(w + up * 0.5, sth + up * 0.5, WOOD[3], 1.0)
			draw_line(sth + up * 0.5, e + up * 0.5, WOOD[3], 1.0)
			draw_line(w + up, sth, Color(WOOD[3], 0.7), 1.0)
		draw_polyline(PackedVector2Array([n + up, e + up, sth + up, w + up, n + up]), Color(0.1, 0.07, 0.05, 0.55), 1.0)
		draw_line(sth, sth + up, Color(0.1, 0.07, 0.05, 0.45), 1.0)
		var _c := c
