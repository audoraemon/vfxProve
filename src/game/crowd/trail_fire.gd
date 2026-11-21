class_name TrailFire
extends RefCounted
## Trail fire (Ember's level 5 Fire Trail, 2026-11-20): short-lived burning ground, a reusable hazard any power may lay
## (lay()), kept apart from the town's GroundFire. A patch lives LIFE, fading over its last FADE, and burns out by itself. It
## frightens nobody (no ThreatManager danger: people do not walk round it), calls no fire beaters and never catches a
## building -- it is fire on the ground and nothing else. Whoever stands on a patch (within RADIUS of its point; a person
## inside a building is safe) builds heat, HARM_TICK at a time, by the strength of the strongest patch under him (once,
## however many overlap: the heat is for being on trail fire, not for each patch): he flashes as he steps on it and shows soot
## (Person.scorched_left, SCORCH_SHOW, as GroundFire's scorch). A crossing -- one unbroken stay on trail fire, from the first
## patch he touches until he is off them all -- adds at most CROSS_MAX of heat, so a quick step over hurts and scorches him
## and no more; a stay longer than LINGER lifts that cap and he burns on. At KILL_AFTER of heat in all, from lingering or
## crossing again soon after, he dies where he stands as KIND, the town's fire kill: no body to raise. Off it, his heat leaves
## him slowly (COOL a second). A patch may spare the one who laid it (the burning man is not harmed by his own trail).
## The Crowd makes one on the first lay (Crowd.trail_fires(): a town that never lays any has none, so nothing in it moves),
## steps it every frame after the burning (Crowd._advance()) and clears it with the town. It draws no number from any rng.
## Its look is its own layer (TrailLayer) in the town's world, under the people: low flames and embers on a scorched strip.
##
## Numbers (the spec: "about"; the crossing cap is the user's rule of 2026-11-21, "a quick step over hurts and scorches
## him; lingering or crossing twice kills him"): LIFE 12 s, FADE 2 s, RADIUS 0.45, KILL_AFTER 1.2 s, COOL 0.08 s of heat a
## second (a sixth of GroundFire's: a crossing is remembered for several seconds). CROSS_MAX 0.75 s of heat a crossing: the
## slowest calm walker (WALK_SPEED 0.6 x pace 0.85, 0.51 u/s) is on a patch's middle (0.9 u) for about 1.76 s, past
## KILL_AFTER, but takes only 0.75 and lives, scorched; a runner (PANIC_SPEED 1.6) is on it about 0.56 s and takes that. A
## second crossing begun within about 3.7 s of leaving the first ((2 * CROSS_MAX - KILL_AFTER) / COOL) kills a walker; a
## runner takes about three. LINGER 2.0 s: a stay longer than that (no walker's crossing through a patch is) burns on past
## the cap, so standing on it kills after about 2.5 s (LINGER + KILL_AFTER - CROSS_MAX), and so does walking along the strip.

const LIFE := 12.0
const FADE := 2.0
const RADIUS := 0.45
const KILL_AFTER := 1.2
const HARM_TICK := 0.1
const COOL := 0.08
## The most heat one crossing adds (seconds), until it has lasted LINGER.
const CROSS_MAX := 0.75
## How long one unbroken stay on trail fire may last (seconds) before CROSS_MAX no longer holds and he burns on.
const LINGER := 2.0
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
## The look redraws at most this often a second (and when the view moves), as people redraw a few times a second: the
## flicker steps at this rate (flicker_clock()).
const REDRAW_HZ := 15.0
## Dev-only frame timers (the layer's draw is `trail_draw` in --bench --bench-prof).
const BenchProf := preload("res://src/core/bench_prof.gd")

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
## DummyEnemy -> Vector4(heat seconds, the harm tick he was last on fire, the heat this crossing has added, the seconds this
## crossing has lasted). Insertion order.
var _heat := {}
var _tick := 0
var _harm_in := 0.0
## Counts the clears: a harm pass that sees it change (a death's callback ends the town) stops there.
var _clears := 0
var _field: EnemyField
var _env: EnvironmentField
## Seconds stepped, for the look only (the flames' flicker).
var clock := 0.0
## The flicker step last redrawn for (step()).
var _drawn_q := -1
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
	if _at.size() == 1:
		_redraw()  # a fresh trail shows at once; the rest show at the next REDRAW_HZ step (step())
	return true


## How many patches are burning.
func count() -> int:
	return _at.size()


## Patch `i`'s point (lay order among those burning).
func spot(i: int) -> Vector2:
	return _at[i]


## Patch `i`'s number (its draw seed: the patches laid before it).
func number(i: int) -> int:
	return _num[i]


## Patch `i`'s strength: 1 until its last FADE, then down to 0 at LIFE.
func strength(i: int) -> float:
	return clampf((LIFE - _age[i]) / FADE, 0.0, 1.0)


## The heat `e` has taken (seconds), 0 when none.
func heat_of(e: DummyEnemy) -> float:
	var h = _heat.get(e)
	return (h as Vector4).x if h != null else 0.0


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
	# The look redraws at REDRAW_HZ (its flicker clock's step), not every frame: patches laid or burnt out in between show
	# at the next step. The last one out is drawn gone at once (no step may follow), and the layer redraws when the view moves.
	var q := floori(clock * REDRAW_HZ)
	if (spent > 0 and _at.is_empty()) or (q != _drawn_q and not _at.is_empty()):
		_drawn_q = q
		_redraw()


## The trail's clock as the look shows it: stepped at REDRAW_HZ, so a redraw in between draws the same flames.
func flicker_clock() -> float:
	return float(floori(clock * REDRAW_HZ)) / REDRAW_HZ


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
			if not e.is_alive() or (e is Person and (e as Person).inside):
				continue  # (one dead earlier in this pass, of another kill's callback, is not scorched)
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
			var w: Vector4 = was if was != null else Vector4.ZERO
			var entering := was == null or int(w.y) != _tick - 1
			# A crossing starts as he steps onto trail fire from off it, and adds at most CROSS_MAX until it has lasted LINGER.
			var crossed := 0.0 if entering else w.z
			var lasted := (0.0 if entering else w.w) + dt
			var gain := dt * best
			if lasted <= LINGER + DUE:
				gain = clampf(CROSS_MAX - crossed, 0.0, gain)
			var h := w.x + gain
			_heat[e] = Vector4(h, float(_tick), crossed + gain, lasted)
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
		var entry: Vector4 = _heat[e]
		if int(entry.y) == _tick:
			continue
		if not is_instance_valid(e) or not (e as DummyEnemy).is_alive():
			_heat.erase(e)
			continue
		var h := entry.x - COOL * dt
		if h <= 0.0:
			_heat.erase(e)
		else:
			_heat[e] = Vector4(h, entry.y, entry.z, entry.w)


func _redraw() -> void:
	if layer != null and is_instance_valid(layer):
		layer.queue_redraw()


## The look of the trail fire: under each patch a scorched strip and an ember glow, over it a few low flames and rising
## embers, all fading with its strength. Only the patches on screen are drawn. Drawing only: its flicker comes from the
## trail's clock and each patch's number, never a random number. The flames and embers are baked once into a small atlas
## (atlas(): FRAMES flicker frames of VARIANTS patterns, each drawn mirrored too) and the scorch is one baked ellipse
## (disc()), so a patch is three textured rects -- its scorch, its ember glow and one frame of flames -- where it was two
## draw_circle polygons and some twenty rects (the fix wave's measure is in the report). It redraws TrailFire.REDRAW_HZ a
## second.
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
	## The atlas: FRAMES frames over one flicker (LOOP seconds) across, VARIANTS patterns down; a cell is CELL_W x CELL_H
	## pixels with the patch's point at ORIGIN (the embers rise about 26 up, the flames reach about 16 either side).
	const FRAMES := 16
	const VARIANTS := 4
	const LOOP := TAU / 5.0
	const CELL_W := 34
	const CELL_H := 36
	const ORIGIN := Vector2i(17, 28)

	## Baked once for every town (drawing only).
	static var _atlas: Texture2D
	static var _disc: Texture2D

	var trail: TrailFire
	## Patches drawn so far, and how many times it has drawn (the tests count them).
	var patches_drawn := 0
	var draws := 0
	## The view it last drew for: a camera moved while the town stands still (paused) redraws it, so no patch stays culled.
	var _drawn_for := Transform2D()

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _process(_delta: float) -> void:
		if trail != null and trail.count() > 0 and get_global_transform_with_canvas() != _drawn_for:
			queue_redraw()

	## The flames' atlas: for each pattern (v) and frame (f), TONGUES low tongues scattered over the patch, each licking up
	## and down on its own phase (a wide red root, an orange tongue to its tip, a pale heart low down), and two embers
	## rising and fading. Made once.
	static func atlas() -> Texture2D:
		if _atlas != null:
			return _atlas
		var img := Image.create(CELL_W * FRAMES, CELL_H * VARIANTS, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.0, 0.0, 0.0, 0.0))
		var rx := RADIUS * ISO_X
		var ry := RADIUS * ISO_Y
		for v in VARIANTS:
			for f in FRAMES:
				var t := LOOP * float(f) / float(FRAMES)
				var cell := Rect2i(f * CELL_W, v * CELL_H, CELL_W, CELL_H)
				var o := cell.position + ORIGIN
				for k in TONGUES:
					var ph := float((v * 7 + k * 13) % 17)
					var x := o.x + roundi(float((v * 13 + k * 29) % 33 - 16) / 16.0 * rx * 0.7)
					var y := o.y + roundi(float((v * 7 + k * 11) % 9 - 4) / 4.0 * ry * 0.55)
					var h := roundi(TONGUE_TALL * (0.35 + 0.65 * absf(sin(t * 5.0 + ph))))
					if h < 2:
						continue
					var root := maxi(roundi(float(h) * 0.45), 1)
					var hot := maxi(roundi(float(h) * 0.3), 1)
					_blend(img, cell, Rect2i(x - 1, y - root, 3, root), Color(FLAME, 0.85))
					_blend(img, cell, Rect2i(x, y - h, 1, h), FLAME_MID)
					_blend(img, cell, Rect2i(x, y - hot, 1, hot), FLAME_HOT)
				for k in 2:
					var rise := fmod(t / LOOP * 22.0 + float((v * 11 + k * 23) % 29), 22.0)
					var ex := o.x + roundi(float((v * 5 + k * 17) % 21) - 10.0 + sin(TAU * t / LOOP + float(k)) * 2.0)
					_blend(img, cell, Rect2i(ex, o.y - 4 - roundi(rise), 1, 1),
						Color(FLAME_HOT if k == 0 else FLAME_MID, 1.0 - rise / 22.0))
		_atlas = ImageTexture.create_from_image(img)
		return _atlas

	## A white ellipse the size of a patch on the ground (2 RADIUS across, iso-squashed), hard-edged as draw_circle: tinted,
	## it is the scorch and the ember glow. Made once.
	static func disc() -> Texture2D:
		if _disc != null:
			return _disc
		var w := roundi(2.0 * RADIUS * ISO_X)
		var h := roundi(2.0 * RADIUS * ISO_Y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.fill(Color(1.0, 1.0, 1.0, 0.0))
		for x in w:
			for y in h:
				var u := (float(x) + 0.5) / (float(w) * 0.5) - 1.0
				var v := (float(y) + 0.5) / (float(h) * 0.5) - 1.0
				if u * u + v * v <= 1.0:
					img.set_pixel(x, y, Color.WHITE)
		_disc = ImageTexture.create_from_image(img)
		return _disc

	## `c` laid over `r` of `img` (alpha blended, as drawing would), kept inside `cell`.
	static func _blend(img: Image, cell: Rect2i, r: Rect2i, c: Color) -> void:
		var a := r.intersection(cell)
		for px in range(a.position.x, a.end.x):
			for py in range(a.position.y, a.end.y):
				img.set_pixel(px, py, img.get_pixel(px, py).blend(c))

	func _draw() -> void:
		var t0 := BenchProf.begin()
		_draw_patches()
		BenchProf.add(&"trail_draw", t0)

	func _draw_patches() -> void:
		draws += 1
		_drawn_for = get_global_transform_with_canvas()
		if trail == null or trail.count() == 0:
			return
		var view := Rect2()
		var vp := get_viewport()
		if vp != null:
			view = (_drawn_for.affine_inverse() * vp.get_visible_rect()).grow(CULL)
		var rx := RADIUS * ISO_X
		var ry := RADIUS * ISO_Y
		var tex := atlas()
		var dsc := disc()
		var q := floori(trail.flicker_clock() / LOOP * float(FRAMES))
		for i in trail.count():
			var c := Iso.ground_to_screen(trail.spot(i)).round()
			if vp != null and not view.has_point(c):
				continue
			patches_drawn += 1
			var s := trail.strength(i)
			# The scorch and the ember glow: the ground ellipse, and one 0.7 its size.
			draw_texture_rect(dsc, Rect2(c.x - rx, c.y - ry, rx * 2.0, ry * 2.0), false, Color(CHAR, CHAR.a * (0.4 + 0.6 * s)))
			draw_texture_rect(dsc, Rect2(c.x - rx * 0.7, c.y - ry * 0.7, rx * 1.4, ry * 1.4), false, Color(GLOW, GLOW.a * s))
			if s <= 0.0:
				continue
			# The flames: one atlas frame, its pattern and phase by its number, mirrored every other round of patterns,
			# shrinking and fading with its strength.
			var seed := trail.number(i)
			var v := seed % VARIANTS
			var f := (q + seed * 5) % FRAMES
			var flip := -1.0 if (seed / VARIANTS) % 2 == 1 else 1.0
			var src := Rect2(f * CELL_W, v * CELL_H, CELL_W, CELL_H)
			var dst := Rect2(c.x - float(ORIGIN.x) * flip, c.y - float(ORIGIN.y) * s, float(CELL_W) * flip, float(CELL_H) * s)
			draw_texture_rect_region(tex, dst, src, Color(1.0, 1.0, 1.0, s))
