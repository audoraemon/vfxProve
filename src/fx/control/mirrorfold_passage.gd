class_name MirrorfoldFx
extends FxTimeline
## Mirrorfold Passage: two mirrors laid on the ground, thin as a film, each a whole street long. The way in is laid by
## a drag: a lane from the press (origin) along the drag, MIN_LEN to MAX_LEN long and HALF wide to either side. The
## way out is the same lane laid at the click that follows (`to`, pushed clear if the two would overlap). Anyone who
## steps onto the way in -- citizen, soldier, responder, someone thrown onto it -- is that instant standing on the
## matching spot of the way out, as far along and as far across, still walking, still meaning to go where they were
## going (DummyEnemy.fold()). Loads cross it too: the passage sits in EnemyField.portals, so whatever a power drops
## onto the way in (field.through()) comes down on the way out. And fire crosses: every FIRE_EVERY, if anything within
## FIRE_R of the way in is burning, the nearest thing within FIRE_R of the way out that can burn is lit. Nobody in the
## town notices: no danger and no alarm. To the player each shows as a long glass with a hairline rim and glints
## drifting along its edges, a faint reflection, a slow ripple, a sheen crossing it now and then, and a few motes; a
## crossing flares both, with the walker drawn into the way in and let out of the way out in a scatter of light, and a
## fire crossing throws embers off the way out. It is one way: the way out takes nobody back. Those already standing on
## the way in when it is laid are left alone until they step off and back on. After MIRROR_TIME both are gone. It locks
## the other slots only while it is cast (busy).

const MIRROR_TIME := 30.0
## A lane's half-width (a street), and how long the drag may lay it.
const HALF := 0.6
const MIN_LEN := 2.0
const MAX_LEN := 6.0
## How far from a lane's edge a fire is seen, or lit, and how often fire is carried across.
const FIRE_R := 1.0
const FIRE_EVERY := 2.0
## The gap left between the two lanes when the click would have laid the way out over the way in.
const MIN_APART := 0.3
## Seconds the surface takes to settle when laid, and to lift at the end.
const LAY := 0.7
const LIFT := 0.9
## A sheen crosses each surface every SHEEN_EVERY seconds, taking SHEEN seconds.
const SHEEN_EVERY := 4.5
const SHEEN := 1.2
## Seconds a crossing's ripple runs, and its flare fades.
const PULSE := 0.6
const FLASH := 0.5
## Local pixels per ground unit the glass is drawn at before it is laid flat into the iso ground.
const QUAD_PX := 32.0
const SHADER := preload("res://shaders/mirror_fold.gdshader")
const GLASS := [Color("f0faff"), Color("b8e4ff"), Color("78b8e0"), Color(0.35, 0.6, 0.8, 0.5)]
const GLASS_LIGHT := Color(0.6, 0.85, 1.0)

## Which way the lanes run, how long they are, and where the way out starts.
var dir := Vector2(1, 0)
var length := 4.0
var exit := Vector2.ZERO
## How many have been folded through, and how many fires carried across.
var folded := 0
var fires_crossed := 0

## Who stood on the way in at the last step, by instance id: only stepping onto it folds.
var _within := {}
var _fire_in := FIRE_EVERY
var _faces: Array[QuadFx] = []
var _pulse_age: Array[float] = [PULSE, PULSE]
var _flash_age: Array[float] = [FLASH, FLASH]


## The first Mirrorfold's oval (before Passage's second draft), kept for the god branch's scripted routes
## (tools/dev/routes), which still plan their casts round it: HALF_WIDE across the screen (ACROSS) by HALF_DEEP down
## it (DOWN). The power itself no longer uses these; the routes' Passage plans are due a rewrite for the lane.
const HALF_WIDE := 2.4
const HALF_DEEP := 1.0
const ACROSS := Vector2(0.70710678, -0.70710678)
const DOWN := Vector2(0.70710678, 0.70710678)
## How far apart the old oval's way in and way out had to be (two ovals and a step): the routes' spacing.
const OVAL_MIN_APART := HALF_WIDE * 2.0 + 0.2


## Legacy (routes only): `g` as the old oval at `center` sees it, each axis -1..1 inside.
static func oval_local(center: Vector2, g: Vector2) -> Vector2:
	var rel := g - center
	return Vector2(rel.dot(ACROSS) / HALF_WIDE, rel.dot(DOWN) / HALF_DEEP)


## Legacy (routes only): whether `g` lies on the old oval centred on `center`.
static func on_mirror(center: Vector2, g: Vector2) -> bool:
	return oval_local(center, g).length_squared() <= 1.0


## The lane's other axis: across it, to its left.
static func side_of(d: Vector2) -> Vector2:
	return Vector2(-d.y, d.x)


## `g` as a lane from `start` along `dir` sees it: (along, across) in ground units.
static func local(start: Vector2, d: Vector2, g: Vector2) -> Vector2:
	var rel := g - start
	return Vector2(rel.dot(d), rel.dot(side_of(d)))


## Whether `g` lies on a lane of `length` from `start` along `dir`: along it within [0, length], across it within HALF.
static func on_way(start: Vector2, d: Vector2, length_: float, g: Vector2) -> bool:
	var at := local(start, d, g)
	return at.x >= 0.0 and at.x <= length_ and absf(at.y) <= HALF


## Where the way out starts for a way in from `from` along `dir` and a click at `to`: at `to`, unless the way out would
## lie over the way in -- then `to` is pushed on along the click's own line from `from` (along the lane when the click
## is on its start) until the two lie MIN_APART clear.
static func exit_for(from: Vector2, d: Vector2, length_: float, to: Vector2) -> Vector2:
	var at := local(from, d, to)
	if absf(at.x) >= length_ or absf(at.y) >= HALF * 2.0:
		return to
	var line := to - from
	var push := local(Vector2.ZERO, d, line.normalized() if line.length() > 0.01 else d)
	# The first distance along the push at which either axis is clear.
	var k := INF
	if absf(push.x) > 0.0001:
		k = minf(k, ((length_ + MIN_APART) * signf(push.x) - at.x) / push.x)
	if absf(push.y) > 0.0001:
		k = minf(k, ((HALF * 2.0 + MIN_APART) * signf(push.y) - at.y) / push.y)
	return to + (line.normalized() if line.length() > 0.01 else d) * k


## The living out in the open standing on a lane of `length` from `start` along `dir` (the preview rings them).
static func standing_on(field: EnemyField, start: Vector2, d: Vector2, length_: float) -> Array:
	var out := []
	for e in field.alive():
		if on_way(start, d, length_, e.ground_pos) and not (e is Person and (e as Person).inside):
			out.append(e)
	return out


## The passage as a portal (EnemyField.portals): whether `p` is on the way in, and where on the way out it comes down.
func carries(p: Vector2) -> bool:
	return on_way(origin, dir, length, p)


func across(p: Vector2) -> Vector2:
	var at := local(origin, dir, p)
	return exit + dir * at.x + side_of(dir) * at.y


func _build() -> void:
	duration = MIRROR_TIME
	busy = 1.0
	var d: Vector2 = extra.get("dir", Vector2(1, 0))
	dir = d.normalized() if d.length() > 0.001 else Vector2(1, 0)
	length = clampf(float(extra.get("length", 4.0)), MIN_LEN, MAX_LEN)
	exit = exit_for(origin, dir, length, extra.get("to", origin + dir * (length + MIN_APART)))
	for e in ctx.field.alive():
		if carries(e.ground_pos):
			_within[e.get_instance_id()] = true
	ctx.field.portals.append(self)
	ctx.play(&"q_mirror", origin)
	if not DominionParts.staged(self):
		return
	var side := side_of(dir)
	var sx := Iso.ground_to_screen(dir)
	var sy := Iso.ground_to_screen(side)
	var size := Vector2(length, HALF * 2.0) * QUAD_PX
	var size_px := Vector2(length * sx.length(), HALF * 2.0 * sy.length())
	for start: Vector2 in [origin, exit]:
		var centre := start + dir * length * 0.5
		# The glass is drawn as a flat rectangle and laid into the ground by the iso basis, so it lies exactly on the lane.
		var q := FxParts.quad(self, SHADER, size, ctx.distort)
		q.transform = Transform2D(sx / QUAD_PX, sy / QUAD_PX, Iso.ground_to_screen(centre))
		q.set_param("size_px", size_px)
		q.set_param("presence", 0.0)
		_faces.append(q)
		# A few motes drifting up off the glass along its length, so an eye can find it; a soft light under it as it is laid.
		var steps := maxi(ceili(length / 1.2), 1)
		for i in steps:
			var g := start + dir * length * (float(i) + 0.5) / float(steps)
			var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(g), PixelParticles.Shape.SQUARE, GLASS,
				1.6, MIRROR_TIME - LIFT, {"radius": FxParts.particle_radius(HALF) * 0.9, "speed": Vector2(1, 4),
				"alt": Vector2(0, 3), "alt_speed": Vector2(5, 12), "life": Vector2(1.0, 1.8), "size": Vector2(1, 1)})
			motes.gravity = -4.0
			var light := FxParts.ground_light(self, g, HALF * 1.6, GLASS_LIGHT, 0.0)
			light.tween_param("intensity", 0.5, 0.0, LAY + 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
			light.life = LAY + 0.65


func _fx_process(delta: float) -> void:
	_fold_step()
	_fire_in -= delta
	if _fire_in <= 0.0:
		_fire_in += FIRE_EVERY
		_fire_step()
	var presence := clampf(minf(t / LAY, (duration - t) / LIFT), 0.0, 1.0)
	# The sheen crosses once as it is laid, once as it lifts, and now and then between.
	var shimmer := 0.0
	if t < LAY:
		shimmer = t / LAY
	elif duration - t < LIFT:
		shimmer = clampf(1.0 - (duration - t) / LIFT, 0.0, 1.0)
	else:
		var cycle := fmod(t - LAY, SHEEN_EVERY)
		shimmer = cycle / SHEEN if cycle < SHEEN else 0.0
	for i in _faces.size():
		_pulse_age[i] = minf(_pulse_age[i] + delta, PULSE)
		_flash_age[i] = minf(_flash_age[i] + delta, FLASH)
		var q := _faces[i]
		if not is_instance_valid(q):
			continue
		q.set_param("presence", presence)
		q.set_param("shimmer", shimmer)
		q.set_param("pulse", _pulse_age[i] / PULSE)
		q.set_param("flash", 1.0 - _flash_age[i] / FLASH)


## Everyone who has stepped onto the way in since the last step comes out of the way out, as far along and across.
func _fold_step() -> void:
	var now := {}
	for e in ctx.field.alive():
		if not carries(e.ground_pos):
			continue
		var id := e.get_instance_id()
		if _within.has(id):
			now[id] = true
			continue
		var at := local(origin, dir, e.ground_pos)
		var from := e.ground_pos
		if e.fold(across(e.ground_pos)):
			folded += 1
			_crossing(at, from, e.ground_pos)
		else:
			now[id] = true  # nowhere to set it down: it walks on across, as if nothing lay there
	_within = now


## Fire crosses: something burning within FIRE_R of the way in lights the nearest thing within FIRE_R of the way out
## that can burn and is not burning yet.
func _fire_step() -> void:
	if ctx.crowd == null or ctx.env == null:
		return
	var burning := false
	for s: Structure in _beside(origin):
		if ctx.crowd.fires.is_burning(s):
			burning = true
			break
	if not burning:
		return
	var best: Structure = null
	var best_d := INF
	for s: Structure in _beside(exit):
		if s.destroyed or ctx.crowd.fires.is_burning(s) or not FireManager.burns(s):
			continue
		var d := _lane_distance(exit, s)
		if d < best_d:
			best_d = d
			best = s
	if best == null:
		return
	ctx.crowd.fires.ignite(best, 0.5)
	fires_crossed += 1
	_fire_crossing(_lane_point_nearest(exit, best))


## The structures whose footprint comes within FIRE_R of a lane's edge.
func _beside(start: Vector2) -> Array:
	var out := []
	var centre := start + dir * length * 0.5
	for s: Structure in ctx.env.near(centre, length * 0.5 + HALF + FIRE_R):
		if _lane_distance(start, s) <= FIRE_R:
			out.append(s)
	return out


## How far `s` stands from a lane's edge: the nearest of the lane's centre line to its footprint, less the half-width.
func _lane_distance(start: Vector2, s: Structure) -> float:
	return maxf(s.distance_to(_lane_point_nearest(start, s)) - HALF, 0.0)


## The point of a lane's centre line nearest `s`, sampled every quarter unit.
func _lane_point_nearest(start: Vector2, s: Structure) -> Vector2:
	var best := start
	var best_d := INF
	var samples := maxi(ceili(length / 0.25), 1)
	for i in samples + 1:
		var g := start + dir * length * float(i) / float(samples)
		var d := s.distance_to(g)
		if d < best_d:
			best_d = d
			best = g
	return best


## A crossing: both faces flare and ripple from where they stepped; light is drawn into the way in after the walker
## and scatters off the way out ahead of it.
func _crossing(at: Vector2, from: Vector2, to: Vector2) -> void:
	# Where on the glass, -1..1 along and across.
	var on := Vector2(at.x / length * 2.0 - 1.0, at.y / HALF)
	for i in _faces.size():
		if is_instance_valid(_faces[i]):
			_faces[i].set_param("pulse_at", on)
			_pulse_age[i] = 0.0
			_flash_age[i] = 0.0
	ctx.play(&"q_mirror_hit", to)
	if not DominionParts.staged(self):
		return
	var sink := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(from) + Vector2(0, -8), PixelParticles.Shape.STREAK, GLASS)
	sink.drag = 1.0
	sink.burst(14, {"radius": 12.0, "speed": Vector2(40, 90), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 14),
		"alt_speed": Vector2(-30, -8), "life": Vector2(0.25, 0.45), "size": Vector2(1, 2)})
	var rise := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(to), PixelParticles.Shape.SQUARE, GLASS)
	rise.gravity = -30.0
	rise.drag = 1.4
	rise.burst(18, {"radius": 5.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 16),
		"alt_speed": Vector2(10, 40), "life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	var glow := FxParts.bloom(self, Iso.ground_to_screen(to) + Vector2(0, -8), 18.0, GLASS_LIGHT, 0.8, 0.8)
	glow.tween_param("intensity", 0.8, 0.0, 0.45, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.5


## Fire crossing: the way out flares and throws embers at `at`, where the fire comes out.
func _fire_crossing(at: Vector2) -> void:
	if _faces.size() > 1 and is_instance_valid(_faces[1]):
		var on := local(exit, dir, at)
		_faces[1].set_param("pulse_at", Vector2(on.x / length * 2.0 - 1.0, 0.0))
		_pulse_age[1] = 0.0
		_flash_age[1] = 0.0
	ctx.play(&"q_mirror_hit", at)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at) + Vector2(0, -4)
	FxParts.sparks(self, ctx.overhead, sp, 22, FxParts.FIRE_LIFE, Vector2(60, 220), Vector2(40, 160))
	var glow := FxParts.bloom(self, sp, 22.0, Color("ff8a3a"), 0.9, 0.8)
	glow.tween_param("intensity", 0.9, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.65


## The span ends (at MIRROR_TIME, or cut short): the passage leaves the portals.
func _finish() -> void:
	_unregister()
	super()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_unregister()


func _unregister() -> void:
	if ctx != null and is_instance_valid(ctx.field):
		ctx.field.portals.erase(self)
