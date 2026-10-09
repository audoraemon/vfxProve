class_name CongregationFx
extends FxTimeline
## Divine Congregation (Dominion): two clicks -- the first the gathering place (origin: a building, a plaza, any spot of
## ground), the second the middle of a district-wide circle of RADIUS. Every citizen in the circle, nearest first up to
## MAX_TARGETS and the place's TARGET_CAPACITY, is compelled (Person.compel(): Mind.COMPELLED, Intent.GATHER) to walk
## there as if of its own mind -- at a walk, no panic, no teleport, no harm -- and stand in a spot of its own round or
## inside the place (GATHER_SPACING apart) until DURATION is up, when each takes up its day again. A danger on top of
## them still frightens them (MOVEMENT_PRIORITY below Person.WILL_ABSOLUTE); an evacuation does not call them away
## (above WILL_FIRM). Soldiers and the important may resist (RESISTANCE). A place that falls lets everyone go at once.
## Quiet: the town sees nothing, and only ALARM_GENERATED (the book entry's "alarm") unsettles it. The cast locks the
## other slots for 1 s.

const RADIUS := 7.0
const DURATION := 25.0
const MAX_TARGETS := 60
const TARGET_CAPACITY := 40
const GATHER_SPACING := 0.45
## How firmly it holds (Person.WILL_FIRM .. WILL_ABSOLUTE).
const MOVEMENT_PRIORITY := 0.8
## Who may resist, by what they are (MadnessManager.kind_of()): the chance, times RESISTANCE_MULTIPLIER.
const RESISTANCE := {&"soldier": 1.0, &"clergy": 0.35, &"monk": 0.35, &"bellkeeper": 0.5, &"engineer": 0.5}
const RESISTANCE_MULTIPLIER := 1.0
## What the cast unsettles the town by (read by Crowd.on_cast() from the book entry).
const ALARM_GENERATED := 0.3
## How near a click must be to a building to gather at it, and how often the place is checked.
const PICK_REACH := 0.6
const CHECK_EVERY := 0.5
## The strands' life and the pillar's.
const STRAND_SECONDS := 1.6
const MARK := Color("ffd86a")
const GOLD := Color(1.0, 0.86, 0.5)
const SOLAR := [Color(0.9, 0.7, 0.35, 0.3), Color("e8b860"), Color("ffd98a"), Color("fff0c0"), Color("fffbe8")]
const GLOW_LIFE := [Color("fff6d0"), Color("ffd98a"), Color("e8b860"), Color(0.8, 0.6, 0.3, 0.5)]
const SH_SIGIL := preload("res://shaders/divine_sigil.gdshader")

## The gathering place: the building (null for open ground) and the point.
var place: Structure
var place_at := Vector2.ZERO
## The circle's middle.
var center := Vector2.ZERO
## Who was gathered, and how many resisted.
var gathered: Array[Person] = []
var resisted := 0

var _check_in := CHECK_EVERY
var _pillar: QuadFx
var _light: QuadFx
var _strands: Strands
var _debug: Debug


## The gathering place for a click at `at`: the standing building it is on or beside, else the ground there.
static func place_for(env: EnvironmentField, at: Vector2) -> Dictionary:
	var best: Structure = null
	var best_d := PICK_REACH
	for s in env.near(at, PICK_REACH):
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return {"structure": best, "at": best.center() if best != null else at}


## Who it would draw to `center`: the living in the circle, out in the open, nearest first, MAX_TARGETS at most.
static func drawn(field: EnemyField, center: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(center, RADIUS):
		var p := e as Person
		if p != null and not p.inside:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(center) < b.ground_pos.distance_squared_to(center))
	return out.slice(0, MAX_TARGETS)


## Whether `p` shrugs it off, by its kind's chance.
static func resists(p: Person, rng: RandomNumberGenerator) -> bool:
	var chance := float(RESISTANCE.get(MadnessManager.kind_of(p), 0.0)) * RESISTANCE_MULTIPLIER
	return chance >= 1.0 or (chance > 0.0 and rng.randf() < chance)


## Up to `count` places to stand, GATHER_SPACING apart, in rings round `at` -- round the building's walls when there
## is one -- on walkable ground only.
static func spots_for(grid: WalkGrid, place: Dictionary, count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var s: Structure = place.structure
	var at: Vector2 = place.at
	var ring := 0
	while out.size() < count and ring < 8:
		var pts: Array[Vector2] = []
		if s != null:
			var r := s.footprint.grow(0.35 + GATHER_SPACING * float(ring))
			var along := 0.0
			var perimeter := 2.0 * (r.size.x + r.size.y)
			while along < perimeter:
				pts.append(_perimeter_point(r, along))
				along += GATHER_SPACING
		else:
			var radius := GATHER_SPACING * float(ring + 1)
			var n := maxi(int(TAU * radius / GATHER_SPACING), 1)
			for i in n:
				var a := TAU * float(i) / float(n)
				pts.append(at + Vector2(cos(a), sin(a)) * radius)
			if ring == 0:
				pts.insert(0, at)
		for g in pts:
			if out.size() >= count:
				break
			if grid != null and not grid.walkable(g):
				continue
			out.append(g)
		ring += 1
	return out


static func _perimeter_point(r: Rect2, along: float) -> Vector2:
	var w := r.size.x
	var h := r.size.y
	if along < w:
		return r.position + Vector2(along, 0.0)
	if along < w + h:
		return Vector2(r.end.x, r.position.y + along - w)
	if along < 2.0 * w + h:
		return Vector2(r.end.x - (along - w - h), r.end.y)
	return Vector2(r.position.x, r.end.y - (along - 2.0 * w - h))


func _build() -> void:
	duration = DURATION
	busy = 1.0
	var found := place_for(ctx.env, origin)
	place = found.structure
	place_at = found.at
	center = extra.get("to", origin)
	var grid: WalkGrid = null
	var candidates := drawn(ctx.field, center)
	if not candidates.is_empty() and candidates[0].grid != null:
		grid = candidates[0].grid
	var spots := spots_for(grid, found, mini(TARGET_CAPACITY, candidates.size()))
	for p in candidates:
		if gathered.size() >= spots.size():
			break
		if resists(p, ctx.rng):
			resisted += 1
			continue
		if p.compel(spots[gathered.size()], DURATION - 0.5, MOVEMENT_PRIORITY, MARK):
			gathered.append(p)
	ctx.play(&"grav_shimmer", place_at, -8.0)
	if _staged():
		_show()


func _staged() -> bool:
	return ctx.impact != null and is_inside_tree()


## Let everyone go now (the place fell).
func release() -> void:
	for p in gathered:
		if is_instance_valid(p):
			p.release_compulsion()
	gathered.clear()
	duration = minf(duration, t + 1.0)


## How many are still on their way or gathered.
func gathering() -> int:
	var n := 0
	for p in gathered:
		if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED:
			n += 1
	return n


func _fx_process(delta: float) -> void:
	_check_in -= delta
	if _check_in <= 0.0:
		_check_in = CHECK_EVERY
		if place != null and (not is_instance_valid(place) or place.destroyed):
			release()
	if is_instance_valid(_pillar):
		var k := curve([[0.0, 0.0], [0.4, 1.0], [2.5, 0.35], [duration - 1.0, 0.3], [duration, 0.0]])
		_pillar.set_param("intensity", k * (0.94 + 0.06 * sin(t * 5.0)))
	if is_instance_valid(_light):
		_light.set_param("intensity", curve([[0.0, 0.0], [0.5, 0.8], [3.0, 0.15], [duration - 1.0, 0.12], [duration, 0.0]]))
	if is_instance_valid(_debug):
		_debug.visible = BehaviourOverlay.shown
		if _debug.visible:
			_debug.queue_redraw()


# --- The show ----------------------------------------------------------------

func _show() -> void:
	var sp := Iso.ground_to_screen(place_at)
	# The sigil over the district, drawn out from the middle and gone in a few seconds.
	var sigil := FxParts.quad(self, SH_SIGIL, Vector2.ONE * RADIUS * 2.0, ctx.ground)
	sigil.position = center
	sigil.z_index = 3
	sigil.set_param("color", GOLD)
	sigil.set_param("px", FxParts.px_for_radius(RADIUS))
	sigil.tween_param("reveal", 0.0, 1.0, 0.9, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	sigil.tween_param("alpha", 1.0, 0.0, 2.2, 1.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	sigil.life = 3.5
	_light = FxParts.ground_light(self, place_at, 2.2, GOLD, 0.0)
	# The pillar of light over the place, soft and tall, with a small halo at its foot.
	_pillar = FxParts.beam(self, ctx.overhead, sp, 18.0, 360.0, SOLAR)
	_pillar.set_param("band_speed", 2.0)
	_pillar.set_param("bands", 4.0)
	_pillar.set_param("flicker", 0.0)
	_pillar.z_index = 2
	var halo := FxParts.bloom(self, sp + Vector2(0, -6), 26.0, GOLD, 0.7, 0.5)
	halo.tween_param("intensity", 0.7, 0.2, 2.5)
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GLOW_LIFE, 5.0, DURATION - 1.0,
		{"radius": 10.0, "speed": Vector2(1, 4), "alt": Vector2(0, 10), "alt_speed": Vector2(8, 22),
		"life": Vector2(1.0, 1.8), "size": Vector2(1, 1)})
	motes.gravity = -6.0
	# The icon over the pillar: a ring and a point of light, and the strands from each of the gathered.
	_strands = Strands.new()
	_strands.fx = self
	_strands.z_index = 3
	track(_strands, ctx.overhead)
	_debug = Debug.new()
	_debug.fx = self
	_debug.visible = BehaviourOverlay.shown
	track(_debug, ctx.overhead)


## The strands: thin lines of light from each of the gathered to the place, for STRAND_SECONDS; and the icon over the
## pillar for the whole run.
class Strands extends Node2D:
	var fx: CongregationFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var sp := Iso.ground_to_screen(fx.place_at)
		var k := clampf(1.0 - fx.t / STRAND_SECONDS, 0.0, 1.0)
		if k > 0.0:
			for p in fx.gathered:
				if is_instance_valid(p) and p.is_alive():
					draw_line(Iso.ground_to_screen(p.ground_pos) + Vector2(0, -14), sp + Vector2(0, -40), Color(GOLD, 0.45 * k), 1.0)
		var fade := clampf(minf(fx.t / 0.6, (fx.duration - fx.t) / 1.0), 0.0, 1.0)
		var at := sp + Vector2(0, -52.0 + sin(fx.t * 1.8) * 2.0)
		draw_arc(at, 5.0, 0.0, TAU, 16, Color(GOLD, 0.8 * fade), 1.0)
		draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.98, 0.9, fade))
		draw_line(at + Vector2(0, -8), at + Vector2(0, -6), Color(GOLD, 0.7 * fade), 1.0)
		draw_line(at + Vector2(0, 6), at + Vector2(0, 8), Color(GOLD, 0.7 * fade), 1.0)


## F4: the circle, the place, who is gathering and their paths, and the seconds left.
class Debug extends Node2D:
	var fx: CongregationFx

	func _draw() -> void:
		var c := Iso.ground_to_screen(fx.center)
		var axes := Iso.radius_to_screen(RADIUS)
		var pts := PackedVector2Array()
		for i in 49:
			var a := TAU * float(i) / 48.0
			pts.append(c + Vector2(cos(a) * axes.x, sin(a) * axes.y))
		draw_polyline(pts, Color(1.0, 0.86, 0.5, 0.7), 1.0)
		var sp := Iso.ground_to_screen(fx.place_at)
		draw_arc(sp, 6.0, 0.0, TAU, 12, Color.WHITE, 1.0)
		for p in fx.gathered:
			if is_instance_valid(p) and p.is_alive() and p.mind == Person.Mind.COMPELLED:
				var at := Iso.ground_to_screen(p.ground_pos)
				draw_arc(at, 5.0, 0.0, TAU, 10, MARK, 1.0)
				if p.goal() != Vector2.INF:
					draw_line(at, Iso.ground_to_screen(p.goal()), Color(MARK, 0.5), 1.0)
		UiTheme.text(self, sp + Vector2(10, -60), "Congregation: %d gathering, %d resisted, %.0f s" % [fx.gathering(),
			fx.resisted, maxf(fx.duration - fx.t, 0.0)], UiTheme.SIZE_SMALL, MARK)
