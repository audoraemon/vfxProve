class_name PlagueManager
extends RefCounted
## Pestilence (v0.06): the sick (Person.sick_left) die PLAGUE_LIFE after they caught it, and every SPREAD_EVERY seconds
## each one gives it to each healthy person within SPREAD_R with SPREAD_CHANCE -- so a packed gate queue, the dock's
## crowd or a full shelter spreads it fast -- up to PLAGUE_MAX sick at once. People sheltering together pass it on
## inside; one who dies in there is carried out first, to be seen. Soldiers catch it too (v0.07.1). A plague death is an
## ordinary death (damage kind plague): it counts, raises the alarm and is an incident.
## Looks (v0.07.1): the sick are tinted by stage (Person.sick_color()), a glow pulses under each (draw_ground()), and
## each infection passed on raises a green puff.

const PLAGUE_LIFE := 5.0
const SPREAD_EVERY := 1.0
const SPREAD_R := 1.0
const SPREAD_CHANCE := 0.3
const PLAGUE_MAX := 60
## How often the town is searched for the newly sick (the effect's infections); the sick list itself is kept every frame.
## Short, because someone the cast infects only starts their PLAGUE_LIFE once a scan adds them to the list.
const SCAN_EVERY := 0.1
## The sick's glow (v0.07.1): a filled ellipse this many ground units round under each, with a rim, of so many segments,
## pulsing so many times a second.
const GLOW_R := 0.42
const GLOW_SEGMENTS := 12
const GLOW_PULSE_HZ := 3.0
## The glow's alpha at the pulse's trough (x) and crest (y): the fill, and the brighter rim round it.
const GLOW_FILL_ALPHA := Vector2(0.30, 0.50)
const GLOW_RIM_ALPHA := Vector2(0.65, 1.0)
## The rim's width, in canvas units.
const GLOW_RIM_WIDTH := 2.0
## Spread puffs (v0.07.1): this many particles each, and at most PUFF_MAX alive at once.
const PUFF_PARTICLES := 6
const PUFF_MAX := 40

var sick: Array[Person] = []
var deaths := 0
var _crowd: Crowd
var _field: EnemyField
var _rng := RandomNumberGenerator.new()
var _spread_in := SPREAD_EVERY
var _scan_in := 0.0
var _puffs: Array = []
## The puffs' own randomness, so drawing them never changes who catches it.
var _fx_rng := RandomNumberGenerator.new()


func setup(crowd: Crowd, field: EnemyField, seed_value: int) -> PlagueManager:
	_crowd = crowd
	_field = field
	_rng.seed = seed_value
	_fx_rng.seed = seed_value + 1
	return self


func step(delta: float) -> void:
	_scan_in -= delta
	_collect(_scan_in <= 0.0)
	if _scan_in <= 0.0:
		_scan_in = SCAN_EVERY
	if sick.is_empty():
		_spread_in = SPREAD_EVERY
		return
	var dying: Array[Person] = []
	for p in sick:
		if _crowd.rescue != null and _crowd.rescue.holds(p):
			continue  # the sickness waits under the rubble (v0.07): it neither runs down nor is cured
		p.sick_left -= delta
		if p.sick_left <= 0.0:
			dying.append(p)
	for p in dying:
		sick.erase(p)
		p.sick_left = 0.0
		if p.inside and _crowd.shelters != null:
			_crowd.shelters.release(p)
		if p.inside:
			continue  # aboard a boat: it sails away with the others
		if _field.kill(p, &"plague"):
			deaths += 1
	_spread_in -= delta
	if _spread_in <= 0.0:
		_spread_in = SPREAD_EVERY
		_spread()


## The sick list: the dead, the freed and the escaped leave it; on a scan, the effect's newly infected join it.
func _collect(scan: bool) -> void:
	var kept: Array[Person] = []
	for p in sick:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0:
			kept.append(p)
	sick = kept
	if not scan or sick.size() >= PLAGUE_MAX:
		return
	for p in _crowd.citizens + _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0 and not sick.has(p):
			sick.append(p)


func _spread() -> void:
	var fresh: Array[Person] = []
	for p in sick:
		var near: Array = []
		if p.inside:
			if _crowd.shelters != null:
				near = _crowd.shelters.occupants_with(p)
		else:
			near = _field.in_radius(p.ground_pos, SPREAD_R)
		for e in near:
			if sick.size() + fresh.size() >= PLAGUE_MAX:
				break
			var q := e as Person
			if q != null and q != p and q.is_alive() and q.sick_left <= 0.0 and not fresh.has(q) \
					and _rng.randf() < SPREAD_CHANCE:
				fresh.append(q)
	if not fresh.is_empty():
		_puffs = _puffs.filter(func(x) -> bool: return is_instance_valid(x))  # the finished ones, once for all of them
	for q in fresh:
		q.infect(PLAGUE_LIFE)
		sick.append(q)
		_puff(q)


## A green smoke puff where the plague was just passed on (v0.07.1), in the cast's colours, on the crowd's overlay.
func _puff(p: Person) -> void:
	var layer := _crowd.overlay()
	if _puffs.size() >= PUFF_MAX or layer == null or p.inside:
		return
	var puff := PixelParticles.new()
	puff.rng.seed = _fx_rng.randi()
	puff.shape = PixelParticles.Shape.PUFF
	puff.ramp = PackedColorArray(PestilenceFx.MIASMA)
	puff.position = Iso.ground_to_screen(p.ground_pos)
	puff.drag = 1.4
	puff.gravity = -14.0
	layer.add_child(puff)
	puff.burst(PUFF_PARTICLES, {"radius": 4.0, "speed": Vector2(4, 12), "alt": Vector2(2, 10),
		"alt_speed": Vector2(2, 8), "life": Vector2(0.5, 0.9), "size": Vector2(2, 3), "size_end_mul": 1.8})
	_puffs.append(puff)


## The sick's glow (v0.07.1): a pulsing filled ellipse with a rim under each sick person out in the open, in its
## sickness's colour. Into `ci` (the crowd's ground drawer, under the people), world space, in two canvas commands in
## all, however many are sick: every fill as one triangle array, every rim as one multiline.
func draw_ground(ci: CanvasItem) -> void:
	if sick.is_empty():
		return
	var glow := build_glow(0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.001 * TAU * GLOW_PULSE_HZ))
	var fill_pts: PackedVector2Array = glow.fill_pts
	if fill_pts.is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), glow.fill_idx, fill_pts, glow.fill_cols)
	ci.draw_multiline_colors(glow.rim_pts, glow.rim_cols, GLOW_RIM_WIDTH)


## The glow's rim points in screen space, relative to its centre: Iso.ground_to_screen() is linear, so one ellipse is
## worked out once and moved to each person. Built on first use.
static var _ring_offsets := PackedVector2Array()


static func _glow_ring() -> PackedVector2Array:
	if _ring_offsets.is_empty():
		for k in GLOW_SEGMENTS:
			var a := TAU * float(k) / float(GLOW_SEGMENTS)
			_ring_offsets.append(Iso.ground_to_screen(Vector2(cos(a), sin(a)) * GLOW_R))
	return _ring_offsets


## The geometry of draw_ground() at pulse `pulse` (0 the trough, 1 the crest): `fill_pts`/`fill_cols`/`fill_idx`, a
## triangle fan (centre, then GLOW_SEGMENTS rim points) for each of the sick in the open, all in one array, and
## `rim_pts`/`rim_cols`, the rim's segments as point pairs with a colour each.
func build_glow(pulse: float) -> Dictionary:
	var fill_pts := PackedVector2Array()
	var fill_cols := PackedColorArray()
	var fill_idx := PackedInt32Array()
	var rim_pts := PackedVector2Array()
	var rim_cols := PackedColorArray()
	var fill_a := lerpf(GLOW_FILL_ALPHA.x, GLOW_FILL_ALPHA.y, pulse)
	var rim_a := lerpf(GLOW_RIM_ALPHA.x, GLOW_RIM_ALPHA.y, pulse)
	var ring := _glow_ring()
	for p in sick:
		if not is_instance_valid(p) or p.inside or not p.visible:
			continue
		var c := p.sick_color()
		var base := fill_pts.size()
		var centre := Iso.ground_to_screen(p.ground_pos)
		fill_pts.append(centre)
		fill_cols.append(Color(c, fill_a))
		for k in GLOW_SEGMENTS:
			fill_pts.append(centre + ring[k])
			fill_cols.append(Color(c, fill_a))
			fill_idx.append(base)
			fill_idx.append(base + 1 + k)
			fill_idx.append(base + 1 + (k + 1) % GLOW_SEGMENTS)
		# The rim is the fan's outer edge, each segment ending where the next begins.
		for k in GLOW_SEGMENTS:
			rim_pts.append(fill_pts[base + 1 + k])
			rim_pts.append(fill_pts[base + 1 + (k + 1) % GLOW_SEGMENTS])
			rim_cols.append(Color(c, rim_a))
	return {"fill_pts": fill_pts, "fill_cols": fill_cols, "fill_idx": fill_idx, "rim_pts": rim_pts, "rim_cols": rim_cols}


func clear() -> void:
	sick.clear()
	_puffs.clear()
	deaths = 0
	_spread_in = SPREAD_EVERY
	_scan_in = 0.0
