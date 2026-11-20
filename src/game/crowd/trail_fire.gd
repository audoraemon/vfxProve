class_name TrailFire
extends RefCounted
## Trail fire (Ember's level 5 Fire Trail, 2026-11-20): short-lived burning ground, a reusable hazard any power may lay
## (lay()), kept apart from the town's GroundFire. A patch lives LIFE, fading over its last FADE, and burns out by itself. It
## frightens nobody (no ThreatManager danger: people do not walk round it), calls no fire beaters and never catches a
## building -- it is fire on the ground and nothing else. Whoever stands on a patch (within RADIUS of its point; a person
## inside a building is safe) builds heat, HARM_TICK at a time, by the strength of the strongest patch under him: he flashes
## as he steps on it and shows soot (Person.scorched_left, SCORCH_SHOW, as GroundFire's scorch). At KILL_AFTER of heat in all,
## from lingering or crossing again, he dies where he stands as KIND, the town's fire kill: no body to raise. Off it, his heat
## leaves him slowly (COOL a second). A patch may spare the one who laid it (the burning man is not harmed by his own trail).
## The Crowd makes one on the first lay (Crowd.trail_fires(): a town that never lays any has none, so nothing in it moves),
## steps it every frame after the burning (Crowd._advance()) and clears it with the town. It draws no number from any rng.
## Its look is its own layer (TrailLayer) in the town's world, under the people: low flames and embers on a scorched strip.
##
## Numbers (the spec: "about"): LIFE 12 s, FADE 2 s, RADIUS 0.45 (a running man, PANIC_SPEED, crosses a patch's middle in
## about 0.56 s: hurt, not killed), KILL_AFTER 1.2 s, COOL 0.1 s of heat a second (a fifth of GroundFire's: a crossing is
## remembered for several seconds, so a second or third one kills).

const LIFE := 12.0
const FADE := 2.0
const RADIUS := 0.45
const KILL_AFTER := 1.2
const HARM_TICK := 0.1
const COOL := 0.1
## How long a scorched person shows soot (GroundFire's).
const SCORCH_SHOW := GroundFire.SCORCH_SHOW
## The town's fire kill (Burning's, GroundFire's): it leaves no body.
const KIND := Burning.KIND
## The flash as he steps on it (DummyEnemy.flash()).
const FLASH := 0.08
## The side of a cell of the patch index (ground units): a patch is filed under every cell its circle's box touches, so a
## person need only look at his own cell's patches. More than 2 * RADIUS, so a patch is in four cells at most.
const CELL := 1.0
## Float drift: the kill is taken this short of KILL_AFTER (GroundFire's).
const DUE := 0.001

## Where each patch lies, how long it has burned, whom it spares (an instance id, 0: nobody), and its number (a draw seed).
## Parallel packed arrays, in lay order, so a step allocates nothing.
var _at := PackedVector2Array()
var _age := PackedFloat64Array()
var _spare := PackedInt64Array()
var _num := PackedInt32Array()
## Cell (Vector2i) -> PackedInt32Array of the patches filed under it; rebuilt when a patch comes or goes (_dirty), never
## every frame. `_box`: the box round every patch, grown by RADIUS (who is outside it is never looked at).
var _cells := {}
var _box := Rect2()
var _dirty := false
## DummyEnemy -> Vector2(heat seconds, the harm tick he was last on fire). Insertion order.
var _heat := {}
var _tick := 0
var _harm_in := 0.0
## Counts the clears: a harm pass that sees it change (a death's callback ends the town) stops there.
var _clears := 0
var _field: EnemyField
var _env: EnvironmentField
## Seconds stepped, for the look only (the flames' flicker).
var clock := 0.0
## Patches laid so far, and how often the cell index was rebuilt (the tests count it).
var laid := 0
var rebuilds := 0
var layer: TrailLayer


func _init(field: EnemyField = null, env: EnvironmentField = null) -> void:
	_field = field
	_env = env


## The look, in `parent` (the town's world), just under the people; once.
func attach(parent: Node2D) -> void:
	if layer != null and is_instance_valid(layer):
		return
	layer = TrailLayer.new()
	layer.name = "TrailFire"
	layer.z_index = -2
	layer.trail = self
	parent.add_child(layer)


## Lays a patch at `at`, sparing the one whose instance id is `spare` (0: nobody). False (nothing laid) inside a building or
## on the water (City.rivers()).
func lay(at: Vector2, spare := 0) -> bool:
	if _env != null and _env.blocked(at, 0.0):
		return false
	for river: Rect2 in City.current().rivers():
		if river.has_point(at):
			return false
	_at.append(at)
	_age.append(0.0)
	_spare.append(spare)
	_num.append(laid)
	laid += 1
	_dirty = true
	_redraw()
	return true


## How many patches are burning.
func count() -> int:
	return _at.size()


## Patch `i`'s point (lay order among those burning).
func spot(i: int) -> Vector2:
	return _at[i]


## Patch `i`'s strength: 1 until its last FADE, then down to 0 at LIFE.
func strength(i: int) -> float:
	return clampf((LIFE - _age[i]) / FADE, 0.0, 1.0)


## The heat `e` has taken (seconds), 0 when none.
func heat_of(e: DummyEnemy) -> float:
	var h = _heat.get(e)
	return (h as Vector2).x if h != null else 0.0


## One frame: the patches age and the spent ones go; every HARM_TICK who stands on one takes heat (and dies at KILL_AFTER),
## and who is off them cools.
func step(delta: float) -> void:
	if _at.is_empty() and _heat.is_empty():
		return
	clock += delta
	var spent := 0
	for i in _age.size():
		_age[i] += delta
		if _age[i] >= LIFE:
			spent += 1
	if spent > 0:
		_drop_spent()
	_harm_in = maxf(_harm_in - delta, -HARM_TICK)  # a stall leaves no catch-up debt
	if _harm_in <= 0.0:
		_harm_in += HARM_TICK
		_harm(HARM_TICK)
	if not _at.is_empty() or spent > 0:
		_redraw()


## Every patch and every heat gone at once (the town's end, the stage cleared): nobody dies of it.
func clear() -> void:
	_clears += 1
	_at.clear()
	_age.clear()
	_spare.clear()
	_num.clear()
	_cells.clear()
	_heat.clear()
	_dirty = false
	_redraw()


## The look goes (the town's end); a later lay in a new world attaches it again.
func free_layer() -> void:
	if layer != null and is_instance_valid(layer):
		if layer.is_inside_tree():
			layer.queue_free()
		else:
			layer.free()
	layer = null


func _drop_spent() -> void:
	var at := PackedVector2Array()
	var age := PackedFloat64Array()
	var spare := PackedInt64Array()
	var num := PackedInt32Array()
	for i in _age.size():
		if _age[i] < LIFE:
			at.append(_at[i])
			age.append(_age[i])
			spare.append(_spare[i])
			num.append(_num[i])
	_at = at
	_age = age
	_spare = spare
	_num = num
	_dirty = true


## The patch index: each patch under every cell its circle's box touches.
func _rebuild() -> void:
	_dirty = false
	rebuilds += 1
	_cells.clear()
	if _at.is_empty():
		_box = Rect2()
		return
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in _at.size():
		var g := _at[i]
		# Padded a little, so float rounding at the edge can never leave out one the exact test would take.
		var a := g - Vector2.ONE * (RADIUS + 0.01)
		var b := g + Vector2.ONE * (RADIUS + 0.01)
		lo = Vector2(minf(lo.x, a.x), minf(lo.y, a.y))
		hi = Vector2(maxf(hi.x, b.x), maxf(hi.y, b.y))
		for cx in range(floori(a.x / CELL), floori(b.x / CELL) + 1):
			for cy in range(floori(a.y / CELL), floori(b.y / CELL) + 1):
				var key := Vector2i(cx, cy)
				var list: PackedInt32Array = _cells.get(key, PackedInt32Array())
				list.append(i)
				_cells[key] = list
	_box = Rect2(lo, hi - lo)


## One harm tick: who stands on a patch (out in the open, not the one it spares) takes `dt` of heat times its strength --
## the strongest under him, once however many overlap -- a flash as he steps on and soot; at KILL_AFTER he dies as KIND. Who
## is off every patch cools by COOL * dt, and is forgotten at none. Walked in the field's order.
func _harm(dt: float) -> void:
	if _field == null:
		return
	if _dirty:
		_rebuild()
	_tick += 1
	var clears := _clears
	if not _at.is_empty():
		for e in _field.in_rect(_box):
			if _clears != clears:
				return
			if e is Person and (e as Person).inside:
				continue
			var g := e.ground_pos
			var list = _cells.get(Vector2i(floori(g.x / CELL), floori(g.y / CELL)))
			if list == null:
				continue
			var id := e.get_instance_id()
			var best := 0.0
			var from := Vector2.INF
			for i: int in list:
				if _spare[i] == id or g.distance_squared_to(_at[i]) > RADIUS * RADIUS:
					continue
				var s := strength(i)
				if s > best:
					best = s
					from = _at[i]
			if best <= 0.0:
				continue
			var was = _heat.get(e)
			var h := (was as Vector2).x if was != null else 0.0
			var entering := was == null or int((was as Vector2).y) != _tick - 1
			h += dt * best
			_heat[e] = Vector2(h, float(_tick))
			if entering:
				e.flash(FLASH)
			if e is Person:
				(e as Person).scorched_left = SCORCH_SHOW
			if h >= KILL_AFTER - DUE:
				_heat.erase(e)
				_field.kill(e, KIND, from)
	if _clears != clears or _heat.is_empty():
		return
	for e in _heat.keys():
		var entry: Vector2 = _heat[e]
		if int(entry.y) == _tick:
			continue
		if not is_instance_valid(e) or not (e as DummyEnemy).is_alive():
			_heat.erase(e)
			continue
		var h := entry.x - COOL * dt
		if h <= 0.0:
			_heat.erase(e)
		else:
			_heat[e] = Vector2(h, entry.y)


func _redraw() -> void:
	if layer != null and is_instance_valid(layer):
		layer.queue_redraw()


## The look of the trail fire: under each patch a scorched strip and an ember glow, over it a few low flames and rising
## embers, all fading with its strength. Only the patches on screen are drawn. Drawing only: its flicker comes from the
## trail's clock and each patch's number, never a random number.
class TrailLayer extends Node2D:
	const CHAR := Color(0.1, 0.05, 0.03, 0.42)
	const GLOW := Color(1.0, 0.45, 0.12, 0.28)
	const FLAME := Color("ff5a1a")
	const FLAME_MID := Color("ffa030")
	const FLAME_HOT := Color("fff0a0")
	## A ground circle of RADIUS on screen: Iso's 64 x 32 cell, so this many pixels across each way per ground unit.
	const ISO_X := 45.25
	const ISO_Y := 22.63
	## Low flames a patch, and how tall the tallest stands (screen pixels).
	const TONGUES := 5
	const TONGUE_TALL := 10.0
	## Screen pixels round a patch's point within which it counts as on screen.
	const CULL := 48.0

	var trail: TrailFire
	## Patches drawn so far (the tests count them).
	var patches_drawn := 0
	## The view it last drew for: a camera moved while the town stands still (paused) redraws it, so no patch stays culled.
	var _drawn_for := Transform2D()

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _process(_delta: float) -> void:
		if trail != null and trail.count() > 0 and get_global_transform_with_canvas() != _drawn_for:
			queue_redraw()

	func _draw() -> void:
		_drawn_for = get_global_transform_with_canvas()
		if trail == null or trail.count() == 0:
			return
		var view := Rect2()
		var vp := get_viewport()
		if vp != null:
			view = (_drawn_for.affine_inverse() * vp.get_visible_rect()).grow(CULL)
		var rx := RADIUS * ISO_X
		var ry := RADIUS * ISO_Y
		var t := trail.clock
		for i in trail.count():
			var c := Iso.ground_to_screen(trail.spot(i)).round()
			if vp != null and not view.has_point(c):
				continue
			patches_drawn += 1
			var s := trail.strength(i)
			var seed := trail._num[i]
			draw_set_transform(c, 0.0, Vector2(1.0, ry / rx))
			draw_circle(Vector2.ZERO, rx, Color(CHAR, CHAR.a * (0.4 + 0.6 * s)))
			draw_circle(Vector2.ZERO, rx * 0.7, Color(GLOW, GLOW.a * s))
			draw_set_transform(Vector2.ZERO)
			if s <= 0.0:
				continue
			for k in TONGUES:
				# Scattered over the patch by its number, each licking up and down on its own phase: a wide red root, an
				# orange tongue narrowing to its tip, a pale heart low down.
				var ph := float((seed * 7 + k * 13) % 17)
				var x := roundf(c.x + float((seed * 13 + k * 29) % 33 - 16) / 16.0 * rx * 0.7)
				var y := roundf(c.y + float((seed * 7 + k * 11) % 9 - 4) / 4.0 * ry * 0.55)
				var h := roundf(TONGUE_TALL * s * (0.35 + 0.65 * absf(sin(t * 5.0 + ph))))
				if h < 2.0:
					continue
				var root := maxf(roundf(h * 0.45), 1.0)
				draw_rect(Rect2(x - 1.0, y - root, 3.0, root), Color(FLAME, 0.85))
				draw_rect(Rect2(x, y - h, 1.0, h), FLAME_MID)
				draw_rect(Rect2(x, y - maxf(roundf(h * 0.3), 1.0), 1.0, maxf(roundf(h * 0.3), 1.0)), FLAME_HOT)
			for k in 2:
				var rise := fmod(t * 14.0 + float((seed * 11 + k * 23) % 29), 22.0)
				var ex := c.x + float((seed * 5 + k * 17) % 21) - 10.0 + sin(t * 3.0 + float(k)) * 2.0
				draw_rect(Rect2(roundf(ex), roundf(c.y - 4.0 - rise), 1.0, 1.0),
					Color(FLAME_HOT if k == 0 else FLAME_MID, s * (1.0 - rise / 22.0)))
