class_name EraseFx
extends FxTimeline
## Erasing Distance (Decree, Tier III; spec 5.5): the distance along a dragged line is erased. The line runs from the
## press along the drag (extra "dir"), as long as the drag (extra "to"), clamped to MIN_LEN..MAX_LEN; DEFAULT_LEN when no
## end is given (the sandbox, scripted casts). Three stages, then what it leaves:
## 1. The seam (T_SEAM): a gilt seam runs down the line and the ground on both sides puckers toward it.
## 2. The fold (T_FOLD): everyone within CRUSH_W of the line (indoors excepted) is caught and pulled to its middle like
##    cloth, and when the fold closes they are crushed there (kill kind collapse). Every building the line crosses falls
##    (EnvironmentField.damage_lane), every one within CRACK_W of it cracks, and what lies on the ground within CRUSH_W
##    (barrels, carts, lamps) is struck down.
## 3. The spring back (T_SNAP after the close): the fold snaps open. Whoever stands within THROW_W of the line is thrown
##    outward, harder the nearer, and knocked down.
## Leaves: law rubble (LawRubble.lay) in kinked heaps along the line, HEAP_EVERY apart, KINK off it at most, closing the
## walk grid until the town's engineers clear it. A heap is not laid where a standing building still is. Who is taken,
## what falls and where the heaps lie follow distance and order only, never a roll. Loud (PowerBook.REACH): its danger
## lands when the fold closes.

const MAX_LEN := 10.0
const MIN_LEN := 2.0
const DEFAULT_LEN := 6.0
const CRUSH_W := 1.0
const CRACK_W := 2.0
const THROW_W := 3.0
const T_SEAM := 0.6
const T_FOLD := 1.5
const T_SNAP := 0.15
## How long the scar of the seam shows after the spring back (look only).
const SCAR := 2.4
## The throw: speed at the line, and at THROW_W.
const KNOCK_NEAR := 3.2
const KNOCK_FAR := 1.4
## A cracked building is left below Structure.CRACK_AT by this much of its health.
const CRACK_BELOW := 0.05
## The rubble: a heap at least every HEAP_EVERY along the line, HEAP across (varied by order), KINK off the line at most.
const HEAP_EVERY := 0.9
const HEAP := 0.9
const KINK := 0.3
const HEAP_H := 9.0

## The line: its direction and length, and where it ends.
var dir := Vector2.RIGHT
var length := DEFAULT_LEN
var to := Vector2.ZERO
## Whoever the fold has caught: DummyEnemy -> [where it was caught, the fold's progress then].
var caught := {}
## What it took: people crushed, buildings felled and cracked, people thrown; the heaps it left.
var crushed := 0
var felled := 0
var cracked := 0
var thrown := 0
var heaps: Array[Structure] = []

var _closed := false
var _seam: Seam


func _build() -> void:
	var drag: Vector2 = extra.get("dir", Vector2.ZERO)
	var end: Vector2 = extra.get("to", Vector2.INF)
	if drag.length() < 0.01 and end != Vector2.INF:
		drag = end - origin
	dir = drag.normalized() if drag.length() >= 0.01 else Vector2.RIGHT
	length = clampf(origin.distance_to(end), MIN_LEN, MAX_LEN) if end != Vector2.INF else DEFAULT_LEN
	to = origin + dir * length
	duration = T_SEAM + T_FOLD + T_SNAP + SCAR
	busy = T_SEAM + T_FOLD + T_SNAP
	at(T_SEAM, _fold)
	at(T_SEAM + T_FOLD, _close)
	at(T_SEAM + T_FOLD + T_SNAP, _spring)
	ctx.play(&"er_tear", middle())
	if not DominionParts.staged(self):
		return
	DecreeParts.proclaim(self, middle(), 54.0, 70.0, T_SEAM, 0.8)
	_seam = Seam.new()
	_seam.fx = self
	_seam.z_index = 4
	track(_seam, ctx.ground)


## The middle of the line, where the fold gathers everything.
func middle() -> Vector2:
	return origin + dir * length * 0.5


## How far `g` is from the line (the segment, ends included).
func off_line(g: Vector2) -> float:
	return g.distance_to(_nearest(g))


func _nearest(g: Vector2) -> Vector2:
	return origin + dir * clampf((g - origin).dot(dir), 0.0, length)


## How far the fold has closed, 0..1 (eased: slow to start, fast to shut).
func fold_k() -> float:
	var k := clampf((t - T_SEAM) / T_FOLD, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k) if k < 0.5 else 1.0 - 2.0 * (1.0 - k) * (1.0 - k)


## The fold begins: the ground gives, the line starts to draw in.
func _fold() -> void:
	_catch()
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.25)
	var sp := Iso.ground_to_screen(middle())
	FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, DecreeParts.GILT_LIFE, 40.0, T_FOLD,
		{"radius": length * 14.0, "speed": Vector2(30, 90), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 4),
			"alt_speed": Vector2(4, 20), "life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})
	DominionParts.pulse(self, middle(), length * 0.5, DecreeParts.AMBER_LIGHT, 0.5, T_FOLD)


func _fx_process(delta: float) -> void:
	if t < T_SEAM or _closed:
		return
	_catch()
	var k := fold_k()
	var mid := middle()
	for e: Variant in caught:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var from: Vector2 = caught[e][0]
		var k0: float = caught[e][1]
		e.ground_pos = from.lerp(mid, clampf((k - k0) / maxf(1.0 - k0, 0.001), 0.0, 1.0))
	if DominionParts.staged(self):
		ctx.shake.add_trauma(minf(delta * 0.5, 0.05))


## Whoever stands within CRUSH_W of the line now and is not caught yet is caught where he stands (indoors excepted).
func _catch() -> void:
	var k := fold_k()
	for e in ctx.field.in_radius(middle(), length * 0.5 + CRUSH_W):
		if caught.has(e):
			continue
		var p := e as Person
		if p != null and p.inside:
			continue
		if off_line(e.ground_pos) <= CRUSH_W:
			caught[e] = [e.ground_pos, k]
			if p != null:
				p.scream(T_FOLD + 0.1)


## The fold shuts: the caught are crushed at the middle, the line's buildings fall and those near it crack.
func _close() -> void:
	_catch()
	_closed = true
	var mid := middle()
	for e: Variant in caught:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var p := e as Person
		if p != null and p.inside:
			continue
		e.ground_pos = mid
		if ctx.field.kill(e, &"collapse", mid):
			crushed += 1
	caught.clear()
	var side := dir.orthogonal()
	var standing: Array[Structure] = []
	for s in ctx.env.structures():
		if is_instance_valid(s) and not s.destroyed:
			standing.append(s)
	ctx.env.damage_lane(origin, dir, 0.0, 0.0, length, &"stone")
	for s in standing:
		if not is_instance_valid(s):
			continue
		if s.destroyed:
			felled += 1
			continue
		if not _within(s, CRACK_W) or s.role == LawRubble.ROLE:
			continue
		var keep := s.max_hp * (Structure.CRACK_AT - CRACK_BELOW)
		var rel := s.center() - origin
		var from := s.center() - side * signf(rel.dot(side) if absf(rel.dot(side)) > 0.001 else 1.0)
		if s.hp > keep:
			s.damage(s.hp - keep, from, &"stone")
		s.crack()
		s.shake(4.0)
		cracked += 1
	for d in ctx.env.decor():
		if is_instance_valid(d) and off_line(d.at) <= CRUSH_W:
			d.hit(99999.0, &"stone")
	ctx.play(&"er_crash", mid)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(mid)
	ctx.flash.call(Color(1.0, 0.9, 0.6, 0.35), 0.25)
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(2.5, 0.35)
	ctx.shake.add_trauma(0.7)
	ctx.shake.kick(Vector2(0, 5))
	FxParts.debris(self, sp, 26, 12.0, Vector2(40, 220), FxParts.ROCK, Vector2(2, 5), true)
	DecreeParts.scatter(self, mid, 24, 10.0)
	DecreeParts.wave(self, mid, CRUSH_W + 1.2, 0.35, 0.12)


## Whether `s`'s footprint comes within `w` of the line (the band [-w, length + w] along it, w across).
func _within(s: Structure, w: float) -> bool:
	var side := dir.orthogonal()
	var half := s.footprint.size * 0.5
	var rel := s.center() - origin
	var along := rel.dot(dir)
	var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
	var ext_side := absf(half.x * side.x) + absf(half.y * side.y)
	return along + ext_along >= -w and along - ext_along <= length + w and absf(rel.dot(side)) <= w + ext_side


## The fold snaps open: whoever stands within THROW_W of the line is thrown outward and knocked down; the rubble is left.
func _spring() -> void:
	var side := dir.orthogonal()
	for e in ctx.field.in_radius(middle(), length * 0.5 + THROW_W):
		var p := e as Person
		if p != null and p.inside:
			continue
		var d := off_line(e.ground_pos)
		if d > THROW_W:
			continue
		var away := e.ground_pos - _nearest(e.ground_pos)
		if away.length() < 0.01:
			away = side
		e.knock(away.normalized() * lerpf(KNOCK_NEAR, KNOCK_FAR, clampf(d / THROW_W, 0.0, 1.0)))
		if p != null:
			p.knock_down()
		thrown += 1
	_lay()
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.45)
	for k in 3:
		var at_g := origin + dir * length * (0.5 * float(k))
		DecreeParts.wave(self, at_g, THROW_W, 0.45, 0.06)
	for h in heaps:
		var puff := FxParts.particles(self, ctx.overhead_back, Iso.ground_to_screen(h.center()), PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
		puff.drag = 1.0
		puff.burst(6, {"radius": 12.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 6),
			"alt_speed": Vector2(10, 30), "life": Vector2(0.6, 1.2), "size": Vector2(2, 4), "size_end_mul": 1.6})


## The heaps: one every length / n (n the fewest that keeps them HEAP_EVERY apart), each off the line by KINK times the
## sine of its index's golden angle and sized by its index, so the line of them kinks without a roll. None where a
## standing building is.
func _lay() -> void:
	var side := dir.orthogonal()
	var n := maxi(1, ceili(length / HEAP_EVERY))
	for k in n:
		var along := (float(k) + 0.5) * length / float(n)
		var c := origin + dir * along + side * KINK * sin(float(k) * 2.39996)
		var size := HEAP * (0.85 + 0.3 * fposmod(float(k) * 0.618034, 1.0))
		var rect := Rect2(c - Vector2(size, size) * 0.5, Vector2(size, size))
		if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.encloses(rect):
			continue
		if _blocked(rect):
			continue
		heaps.append(LawRubble.lay(ctx.env, rect, HEAP_H * (0.8 + 0.4 * fposmod(float(k) * 0.381966, 1.0))))


## A standing building (not a pile of law rubble, not ground one walks on) covers some of `rect`.
func _blocked(rect: Rect2) -> bool:
	for s in ctx.env.near(rect.get_center(), rect.size.x):
		if is_instance_valid(s) and not s.destroyed and not s.walkable and s.role != LawRubble.ROLE and s.footprint.intersects(rect):
			return true
	return false


## The seam on the ground, drawn in ground units: an ink-and-gilt line run down from the press while the seam opens,
## the ground's creases puckering toward it on both sides; through the fold the whole of it draws in to the middle;
## after the spring back a kinked gilt scar along the line that fades. Its creases are laid out once.
class Seam extends Node2D:
	const CREASE_EVERY := 0.42
	var fx: EraseFx
	## Along, and a tilt toward the middle, of each crease.
	var _creases: Array[Vector2] = []
	var _band := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	func _ready() -> void:
		var along := CREASE_EVERY * 0.5
		var k := 0
		while along < fx.length:
			_creases.append(Vector2(along, 0.12 + 0.12 * fposmod(float(k) * 0.618034, 1.0)))
			along += CREASE_EVERY
			k += 1

	func _process(_delta: float) -> void:
		queue_redraw()

	## Where a ground point of the line (`along`, `across`) is drawn while the fold is `k` shut.
	func _at(along: float, across: float, k: float) -> Vector2:
		var half := fx.length * 0.5
		return fx.origin + fx.dir * (half + (along - half) * (1.0 - k)) + fx.dir.orthogonal() * across * (1.0 - 0.7 * k)

	func _draw() -> void:
		var now := fx.t
		var open := clampf(now / (T_SEAM * 0.85), 0.0, 1.0)
		var shut := now >= T_SEAM + T_FOLD
		var side := fx.dir.orthogonal()
		if not shut:
			var k := fx.fold_k()
			# The ground drawn in: an ink band where the cloth gathers.
			var w := CRUSH_W * (0.35 + 0.65 * open)
			_band[0] = _at(0.0, w, k)
			_band[1] = _at(fx.length * open, w, k)
			_band[2] = _at(fx.length * open, -w, k)
			_band[3] = _at(0.0, -w, k)
			draw_colored_polygon(_band, Color(DecreeParts.INK, 0.16 + 0.22 * k))
			# The creases, puckering toward the seam from both sides, gathering in with the fold.
			for c in _creases:
				if c.x > fx.length * open:
					break
				var tilt := c.y * signf(fx.length * 0.5 - c.x)
				for si in 2:
					var s := -1.0 if si == 0 else 1.0
					var near_p := _at(c.x, s * 0.12, k)
					var far_p := _at(c.x - tilt, s * (CRUSH_W + 0.45) * open, k)
					draw_line(near_p, far_p, Color(DecreeParts.INK, 0.75 * open), 0.1)
					draw_line(near_p, near_p.lerp(far_p, 0.6), Color(DecreeParts.GILT, 0.5 * open), 0.04)
			# The seam: ink under gilt, a bright core that pulses as the fold pulls.
			var a := _at(0.0, 0.0, k)
			var b := _at(fx.length * open, 0.0, k)
			var pulse := 0.75 + 0.25 * sin(now * 18.0)
			draw_line(a, b, Color(DecreeParts.INK, 0.9), 0.3)
			draw_line(a, b, Color(DecreeParts.GILT, 0.95), 0.15)
			draw_line(a, b, Color(1.0, 0.97, 0.85, pulse), 0.05)
			return
		# The scar: the line back at its length, kinked as the rubble lies, fading.
		var fade := clampf(1.0 - (now - T_SEAM - T_FOLD - T_SNAP) / SCAR, 0.0, 1.0)
		if fade <= 0.0:
			return
		var n := maxi(1, ceili(fx.length / HEAP_EVERY))
		var prev := fx.origin
		for k in n + 1:
			var along := minf((float(k) + 0.5) * fx.length / float(n), fx.length)
			var p := fx.origin + fx.dir * along + side * KINK * sin(float(k) * 2.39996) * (1.0 if k < n else 0.0)
			draw_line(prev, p, Color(DecreeParts.INK, 0.8 * fade), 0.22)
			draw_line(prev, p, Color(DecreeParts.GILT, 0.9 * fade), 0.1)
			prev = p
