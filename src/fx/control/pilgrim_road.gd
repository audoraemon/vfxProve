class_name PilgrimRoadFx
extends FxTimeline
## Pilgrim Road (Passage, Tier II): the road itself travels. Aimed by a drag: a lane LENGTH long and HALF to either
## side runs from the press along the drag. The road wakes at the cast and T_FLOW later its paving begins to flow,
## for SPAN seconds, at SPEED along the drag: everyone standing on it -- walking, standing, fighting, lying knocked
## down, soldiers too -- is carried along it at a run, whatever they are doing, and keeps their own mind and errand
## (they re-path from wherever the road has taken them). Nothing else is carried: Windfall's heaps are structures and
## the town's decor is baked into the ground. One carried past the far end goes into whatever stands there: open
## ground, and they tumble off it, thrown a step on and knocked down; a wall or a building (THROW past the end), and
## they are thrown against it -- knocked down where the road ends, and the structure takes a blow of WALL_HIT (damage
## kind stone: no fire). Whoever stands up again on the road's end is thrown again, no sooner than AGAIN after the
## last. A pit, a fire, a flood or a strike at the end is that power's own business: those carried into it are in it.
## While it flows the lane is a danger the town walks round (a threat along it). Loud: the flow is seen and heard
## (PowerBook.REACH), from T_FLOW.

const LENGTH := 6.0
const HALF := 0.6
const T_FLOW := 0.8
const SPAN := 15.0
const SPEED := 3.0
const THROW := 0.8
const WALL_HIT := 8.0
## One person is thrown off the end or against a wall once a crossing: not again within this.
const AGAIN := 1.0
## The paving: a slat across the lane every SLAT, sliding at SPEED; the belt shows over FADE_IN and goes over FADE_OUT.
const SLAT := 0.5
const FADE_IN := 0.4
const FADE_OUT := 0.6
const STONE := Color(0.09, 0.08, 0.1)
const GOLD := Color("e8b848")
const PALE := Color("f4ecd8")
const GOLD_RAMP := [Color(0.3, 0.22, 0.08, 0.5), Color("8a6a20"), Color("d8a840"), Color("ffe08a"), Color("fff8e0")]

## How many it carried (distinct people), how many tumbled off its end, how many blows walls at its end took.
var carried := 0
var thrown := 0
var blows := 0

var _dir := Vector2(1, 0)
var _flowing := false
var _touched := {}
## instance id -> the clock when that person may be thrown again
var _again := {}
var _belt: Belt


## Whether `g` lies on a lane running from `origin` along `dir` (LENGTH long, HALF to each side).
static func on_lane(origin: Vector2, dir: Vector2, g: Vector2) -> bool:
	var rel := g - origin
	var along := rel.dot(dir)
	var across := rel.dot(dir.orthogonal())
	return along >= 0.0 and along <= LENGTH and absf(across) <= HALF


## Where the road ends.
func end() -> Vector2:
	return origin + _dir * LENGTH


## Whether the paving is moving now.
func flowing() -> bool:
	return _flowing


func _build() -> void:
	_dir = extra.get("dir", Vector2(1, 0))
	if _dir.length() < 0.01:
		_dir = Vector2(1, 0)
	_dir = _dir.normalized()
	duration = T_FLOW + SPAN + 0.6
	busy = T_FLOW
	at(T_FLOW, _start)
	at(T_FLOW + SPAN - 1.0, func(): ctx.play(&"grav_suction", end(), -3.0))
	at(T_FLOW + SPAN, _stop)
	ctx.play(&"laser_scan", origin, -4.0)
	if not DominionParts.staged(self):
		return
	_belt = Belt.new()
	_belt.fx = self
	_belt.position = origin
	_belt.z_index = 2
	track(_belt, ctx.ground)
	for g: Vector2 in [origin, end()]:
		var sp := Iso.ground_to_screen(g)
		var arch := Arch.new()
		arch.fx = self
		arch.position = sp
		arch.z_index = 6
		arch.glow = FxParts.bloom(self, sp + Vector2(0, -22), 44.0, GOLD, 0.0, 0.8)
		track(arch, ctx.overhead)


## The paving starts to flow: the lane is a danger the town walks round, a ripple runs it, the dust starts to stream.
func _start() -> void:
	_flowing = true
	if ctx.crowd != null:
		ctx.crowd.threats.register(origin + _dir * LENGTH * 0.5, LENGTH * 0.5 + 0.4, 0.4, SPAN, 6.0, 9.0, &"wind")
	ctx.play(&"grav_field", origin + _dir * LENGTH * 0.5, 0.0)
	if not DominionParts.staged(self):
		return
	ctx.shake.kick(Vector2(0, 1.2))
	for g: Vector2 in [origin, end()]:
		var ring := FxParts.shockwave(self, g, HALF * 2.2, GOLD_RAMP)
		ring.set_param("thickness", 0.14)
		ring.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
		ring.tween_param("fade", 0.7, 0.0, 0.25, 0.2)
		ring.life = 0.5
	# Dust streaming the way the road runs: a few sources along it, each blowing down the screen direction of the drag.
	var screen_dir := (Iso.ground_to_screen(_dir) - Iso.ground_to_screen(Vector2.ZERO)).normalized()
	var n := int(LENGTH / 1.5)
	for i in n:
		var g := origin + _dir * (LENGTH * (float(i) + 0.5) / float(n))
		var dust := FxParts.emitter(self, ctx.overhead_back, Iso.ground_to_screen(g), PixelParticles.Shape.STREAK,
			FxParts.DUST_LIFE, 14.0, SPAN - FADE_OUT, {
				"radius": FxParts.particle_radius(HALF * 0.8), "velocity": screen_dir * SPEED * 26.0,
				"alt": Vector2(1, 6), "alt_speed": Vector2(4, 14), "life": Vector2(0.4, 0.9), "size": Vector2(1, 2),
			})
		dust.drag = 0.2
		dust.streak_len = 0.06


func _stop() -> void:
	_flowing = false


func _fx_process(delta: float) -> void:
	if not _flowing:
		return
	if ctx.crowd != null and ctx.crowd.is_frozen():
		return  # time stands still: the road with it
	var side := _dir.orthogonal()
	for e in ctx.field.alive():
		var p := e as Person
		if p == null or p.inside or p.is_frozen():
			continue
		if not on_lane(origin, _dir, p.ground_pos):
			continue
		var id := p.get_instance_id()
		if not _touched.has(id):
			_touched[id] = true
			carried += 1
		var across := (p.ground_pos - origin).dot(side)
		var next := p.ground_pos + _dir * SPEED * delta
		var along := (next - origin).dot(_dir)
		if along > LENGTH:
			p.ground_pos = next
			_off_the_end(p, across)
		elif ctx.env.blocked(next):
			# A building standing on the road: for whoever reaches it, that is where the road ends.
			_slam(p, next + _dir * 0.3, p.ground_pos)
		else:
			p.ground_pos = next
		p._sync_position()


## Carried past the end: into whatever stands THROW beyond it.
func _off_the_end(p: Person, across: float) -> void:
	var spot := end() + _dir * THROW
	if ctx.env.blocked(spot):
		_slam(p, spot, origin + _dir * (LENGTH - 0.1) + _dir.orthogonal() * across)
		return
	if float(_again.get(p.get_instance_id(), -INF)) > t:
		return
	_again[p.get_instance_id()] = t + AGAIN
	p.knock(_dir * 2.5)
	p.knock_down()
	thrown += 1


## Thrown against what stands at `spot`: knocked down at `hold` (the nearest ground to stand on), the structure struck.
## One who is still down there is only held; one up again is thrown again, AGAIN after the last.
func _slam(p: Person, spot: Vector2, hold: Vector2) -> void:
	if p.grid != null:
		var w := p.grid.nearest_walkable(hold)
		if w != Vector2.INF:
			hold = w
	p.ground_pos = hold
	var id := p.get_instance_id()
	if float(_again.get(id, -INF)) > t or p.is_down():
		return
	_again[id] = t + AGAIN
	p.knock_down()
	ctx.env.damage_radius(spot, 0.4, WALL_HIT, &"stone")
	blows += 1
	ctx.play(&"jg_crumble", spot, -8.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(spot)
	FxParts.debris(self, sp, 6, 4.0, Vector2(30, 120), FxParts.ROCK, Vector2(1.5, 3.0), true)
	FxParts.smoke(self, sp, 4.0, 10.0, 0.2, Vector2(10, 24), Vector2(2, 4), Vector2(0.4, 0.8), Color(0, 0, 0, 0), FxParts.DUST_LIFE)
	ctx.shake.kick(Vector2(0, 1.5))


## How much of the belt shows: in over FADE_IN from T_FLOW, out over the last FADE_OUT of the flow.
func belt_alpha() -> float:
	return curve([[T_FLOW, 0.0], [T_FLOW + FADE_IN, 1.0], [T_FLOW + SPAN - FADE_OUT, 1.0], [T_FLOW + SPAN, 0.0]])


## How much the arches show: up over T_FLOW from the cast, gone with the belt.
func arch_alpha() -> float:
	return curve([[0.0, 0.0], [T_FLOW, 1.0], [T_FLOW + SPAN - FADE_OUT, 1.0], [T_FLOW + SPAN, 0.0]])


## The paving as a belt: the lane dark, a stone slat across it every SLAT sliding along the drag at SPEED, a faint gold
## glow between the slats, pale edges. Drawn in ground units on the ground plane, at the road's start.
class Belt extends Node2D:
	var fx: PilgrimRoadFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.belt_alpha()
		if a <= 0.0:
			return
		var d := fx._dir
		var s := d.orthogonal()
		var edge := PackedVector2Array([-s * HALF, d * LENGTH - s * HALF, d * LENGTH + s * HALF, s * HALF])
		draw_colored_polygon(edge, Color(STONE, 0.6 * a))
		var shift := fmod(fx.t * SPEED, SLAT)
		var x := shift
		while x < LENGTH:
			# The glow lies in the gap behind each slat, the slat a dark line on top of it.
			var gl := maxf(x - SLAT * 0.55, 0.0)
			if x > gl:
				draw_line(d * gl, d * x, Color(GOLD, 0.22 * a), HALF * 1.9)
			draw_line(d * x - s * HALF, d * x + s * HALF, Color(0.02, 0.02, 0.03, 0.85 * a), 0.07)
			x += SLAT
		draw_line(-s * HALF, d * LENGTH - s * HALF, Color(PALE, 0.5 * a), 0.05)
		draw_line(s * HALF, d * LENGTH + s * HALF, Color(PALE, 0.5 * a), 0.05)


## A door of pale light standing at an end of the road: a thin door-shaped outline in screen space, its bloom pulsing.
class Arch extends Node2D:
	const W := 30.0
	const H := 48.0
	var fx: PilgrimRoadFx
	var glow: QuadFx

	func _process(_delta: float) -> void:
		queue_redraw()
		if glow != null and is_instance_valid(glow):
			glow.set_param("intensity", fx.arch_alpha() * (0.55 + 0.25 * sin(fx.t * 5.0)))

	func _draw() -> void:
		var a := fx.arch_alpha()
		if a <= 0.0:
			return
		var pulse := 0.8 + 0.2 * sin(fx.t * 5.0)
		var r := W * 0.5
		var top := Vector2(0, -H + r)
		draw_colored_polygon(PackedVector2Array([Vector2(-r, 0), Vector2(-r, top.y), Vector2(r, top.y), Vector2(r, 0)]),
			Color(GOLD, 0.1 * a))
		draw_circle(top, r, Color(GOLD, 0.1 * a))
		draw_line(Vector2(-r, 0), Vector2(-r, top.y), Color(PALE, 0.9 * a * pulse), 1.5)
		draw_line(Vector2(r, 0), Vector2(r, top.y), Color(PALE, 0.9 * a * pulse), 1.5)
		draw_arc(top, r, PI, TAU, 16, Color(PALE, 0.9 * a * pulse), 1.5)
		draw_line(Vector2(-r - 4, 0), Vector2(r + 4, 0), Color(GOLD, 0.7 * a), 1.0)
