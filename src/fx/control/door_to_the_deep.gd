class_name DoorToTheDeepFx
extends FxTimeline
## Door to the Deep (Passage, Tier II): a door opens in the ground and a whirlpool turns round it, drawing people in
## until the door takes them. The click is the door (`mouth`; a Mirrorfold way in carries it to its way out,
## EnemyField.through()). It takes T_OPEN to open; then black water runs out over a circle that grows from the mouth
## to RADIUS in SPREAD seconds, turns for SPAN, and drains back into the door over DRAIN.
##
## The torrent: every frame, everyone standing in the water -- citizen or soldier, walking, standing or lying; not
## those indoors -- is carried by it: slowly inward toward the door, PULL_RIM a second at the rim rising evenly to
## PULL_CORE at the mouth (pull_speed(): 0.75 - 0.15 * d, for one d from the door), and round the door at SWIRL a
## second, always the same way (clockwise on screen). Both are weaker while the water spreads and drains, by the
## share of RADIUS it reaches (force()). It is a carry, not a
## hold: they keep their mind and keep walking, and the water moves them as well. Nobody is carried through a wall or
## into a building: a step that would end in one is not taken -- the inward part alone is tried, then the turn alone,
## else they stay where they are, held against the wall by the water for as long as it stands (it is being soaked).
## Nothing is carried while time stands still (Crowd.is_frozen()).
##
## The maw: whoever is in the water within MAW of the mouth is dragged under and through the door (a death of kind
## pit, drawn down into it), from the moment it opens -- someone standing on the door when it opens is gone at once.
##
## Every TICK while there is water: everyone in it walks at SLOW of their pace (Person.statuses "slow"; their pace is
## theirs again the moment they are out of it, or when it drains, or when the act ends); every fire on a building in
## it is doused a bucket's worth (FireManager.douse: a fire goes out in a few ticks, and a puff of steam goes up);
## every building in it takes SOAK of water damage (damage kind water: nothing catches, nothing is scorched when it
## falls).
##
## Who gets out (at full flood): the pull has to be outwalked at SLOW of one's pace, so it depends on how far in one
## is and how fast one goes. A calm stroller (0.6 a second: 0.198 wading) can wade out only from the outer third of a
## unit (more than about 3.7 from the door); one fleeing (1.2: 0.40 wading) from more than about 2.3; one in a panic
## (1.6: 0.53 wading) from more than about 1.5. Within about 1.5 of the door nobody gets out. One standing still at
## the rim is under in about 10 seconds, one standing 2.0 from the door in about 2.4.
##
## The circle is a danger the town knows (a water threat on it from T_OPEN, for the span): people run from it and go
## round it. Loud: the door's crash is seen and heard (PowerBook.REACH), from the opening.
##
## Levels (PowerBook "deep"): the circle (RADIUS), the time it turns (SPAN) and the pull at the door (PULL_CORE) grow,
## read once at the cast into lv_radius, lv_span and lv_pull_core; level 1 is the constants. Level 5's twist, Standing
## Water: when the door has shut, its water does not run back into it -- the circle lies flooded STAND seconds more,
## calm (no torrent: nobody is drawn in or taken any more, no wall soaks), and soaks away over its last STAND_FADE.
## Whoever is in it walks at STAND_SLOW of their pace, and for SOAKED_FOR after they leave it (or it is gone); every
## fire on a building in it is still doused.

const T_OPEN := 0.8
const RADIUS := 4.0
const SPREAD := 2.0
const SPAN := 25.0
const DRAIN := 2.0
const TICK := 0.5
const SLOW := 0.33
const SOAK := 1.5
## The torrent: how fast it carries people toward the door at the rim and at the mouth, how fast round it (ground
## units a second), and how near the mouth the door takes them.
const PULL_RIM := 0.15
const PULL_CORE := 0.75
const SWIRL := 0.8
const MAW := 0.7
## Standing Water (level 5): how long the flood lies after the door has shut, how long it takes to soak away at the
## end, how slow it makes those in it, and how long they stay soaked after they leave it.
const STAND := 20.0
const STAND_FADE := 2.0
const STAND_SLOW := 0.5
const SOAKED_FOR := 6.0
## The danger the town sees on the circle: how grave, and from how far it is seen and heard.
const THREAT := 0.6
const THREAT_SIGHT := 6.0
const THREAT_SOUND := 9.0
## The carry is taken in steps no longer than this, each with the water as it stood then, so a long frame (or a
## test's long step) carries people along the same path as many short ones.
const CARRY_STEP := 1.0 / 30.0
## The water as it first runs from the door, and the door's own size (ground units).
const FIRST_REACH := 0.8
const MOUTH_R := 0.9
## A ripple runs in to the door every RIPPLE_EVERY seconds; a drip is heard every DRIP_EVERY; the door is heard
## swallowing at most once every GULP_EVERY.
const RIPPLE_EVERY := 1.5
const DRIP_EVERY := 4.0
const GULP_EVERY := 0.6
## The look of the turning: the foam arms and flecks go round TURN radians a second at the rim and faster inside (as
## RADIUS / r); the screen is bent into the hole out to FUNNEL_R from the mouth.
const TURN := 0.6
const FUNNEL_R := 2.3
const SH_FLOOD := preload("res://shaders/flood_water.gdshader")
const DEEP := Color(0.02, 0.03, 0.08)
const PALE := Color(0.78, 0.9, 1.0)
const SKY := Color(0.45, 0.75, 1.0)
const WATER_DEEP := Color(0.02, 0.05, 0.12, 0.95)
const WATER_BODY := Color(0.05, 0.11, 0.24, 0.93)
const WATER_MID := Color(0.09, 0.2, 0.38, 0.9)
const WATER_FOAM := Color(0.72, 0.86, 0.96, 0.85)
const WATER_FOAM_SHADOW := Color(0.36, 0.56, 0.76, 0.8)
const WET := Color(0.05, 0.07, 0.11, 0.6)
const STEAM := [Color(0.96, 0.98, 1.0, 0.85), Color(0.86, 0.9, 0.95, 0.6), Color(0.75, 0.8, 0.88, 0.3), Color(0.7, 0.75, 0.82, 0.0)]
const GLINT := [Color("ffffff"), Color("eaf6ff"), Color(0.8, 0.9, 1.0, 0.6), Color(0.7, 0.85, 1.0, 0.0)]

## Where the door is: the click, or where a Mirrorfold carries it.
var mouth := Vector2.ZERO
## How many fires the water put out, and how much water damage it did to buildings.
var doused := 0
var soaked_damage := 0.0
## How many the torrent ever had hold of (distinct people), and how many the door took.
var caught := 0
var drowned := 0
## The level's numbers (PowerBook.stat(), read once at the cast), and whether the water stays (Standing Water).
var lv_radius := RADIUS
var lv_span := SPAN
var lv_pull_core := PULL_CORE
var standing := false

## Whoever is standing in the water, by instance id -> [Person, the "slow" they had before the water, if any, and --
## out of the standing water -- when their soaking wears off (INF while they are in it)].
var _soaked := {}
## Ticks run: the next is at T_OPEN + TICK * _ticks (counted, not summed, so the last lands on the drain's end).
var _ticks := 0
var _flooded := false
var _caught := {}
var _gulp_at := -INF
var _roar: Node
var _ripple_in := 0.0
var _glints: PixelParticles
var _spray: PixelParticles


## How far the water reaches from the door at `now`: nothing before the door is open, out to RADIUS over SPREAD,
## RADIUS for the span, and back to nothing over DRAIN. Standing Water: it stays at RADIUS once the door has shut, and
## soaks away over the last STAND_FADE of STAND.
func reach(now: float) -> float:
	if now < T_OPEN:
		return 0.0
	if now < T_OPEN + SPREAD:
		return lerpf(FIRST_REACH, lv_radius, (now - T_OPEN) / SPREAD)
	if now <= T_OPEN + lv_span:
		return lv_radius
	if standing:
		var left := stand_end() - now
		return lv_radius * clampf(left / STAND_FADE, 0.0, 1.0) if left > 0.0 else 0.0
	return lv_radius * maxf(1.0 - (now - T_OPEN - lv_span) / DRAIN, 0.0)


## When the door is shut: the end of the drain.
func shut_at() -> float:
	return T_OPEN + lv_span + DRAIN


## When the standing water is gone (Standing Water; else the door's shutting).
func stand_end() -> float:
	return shut_at() + (STAND if standing else 0.0)


## Whether the water stands still at `now`: the door shut, its flood left lying (Standing Water).
func stands(now: float) -> bool:
	return standing and now >= shut_at() and now < stand_end()


## Whether `g` is under water now.
func wet(g: Vector2) -> bool:
	return g.distance_to(mouth) <= reach(t)


## How hard the torrent runs at `now`, 0..1: the share of RADIUS the water reaches (weaker while it spreads and drains).
## Standing Water: the water stays as the door shuts, but the torrent dies with the door, over DRAIN.
func force(now: float) -> float:
	if standing and now > T_OPEN + lv_span:
		return clampf(1.0 - (now - T_OPEN - lv_span) / DRAIN, 0.0, 1.0)
	return clampf(reach(now) / lv_radius, 0.0, 1.0)


## How fast the torrent in full flood carries someone `d` from the door toward it: PULL_RIM at the rim, rising evenly
## to PULL_CORE at the mouth (a level's circle and pull: `radius`, `core`).
static func pull_speed(d: float, radius := RADIUS, core := PULL_CORE) -> float:
	return lerpf(PULL_RIM, core, clampf(1.0 - d / radius, 0.0, 1.0))


## How far the door is open, 0..1: it opens over T_OPEN and closes as the water drains.
func opening() -> float:
	var k := clampf(t / T_OPEN, 0.0, 1.0)
	var o := 1.0 - pow(1.0 - k, 3.0)
	if t > T_OPEN + lv_span:
		o *= 1.0 - clampf((t - T_OPEN - lv_span) / DRAIN, 0.0, 1.0)
	return o


## When the pieces drawn for the water are done with: the drain's end, or the standing water's.
func visuals_end() -> float:
	return stand_end() + 0.1


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "deep", "RADIUS", RADIUS))
	lv_span = float(PowerBook.stat(extra, "deep", "SPAN", SPAN))
	lv_pull_core = float(PowerBook.stat(extra, "deep", "PULL_CORE", PULL_CORE))
	standing = PowerBook.twist_at(extra, "deep")
	mouth = ctx.field.through(origin)
	duration = T_OPEN + lv_span + DRAIN + 0.3
	if standing:
		duration = stand_end() + SOAKED_FOR + 0.3
	busy = T_OPEN
	at(T_OPEN, _open)
	at(T_OPEN + 0.3, func(): ctx.play(&"ts_surge", mouth, -3.0))
	at(T_OPEN + 0.5, func(): _roar = ctx.play(&"tn_wind", mouth, -2.0))
	var drip := T_OPEN + DRIP_EVERY
	while drip < T_OPEN + lv_span:
		at(drip, func(): ctx.play(&"ts_drip", mouth, 0.0))
		drip += DRIP_EVERY
	if standing:
		# The flood lying still: a drip now and then, until it has soaked away.
		drip = shut_at() + DRIP_EVERY
		while drip < stand_end() - STAND_FADE:
			at(drip, func(): ctx.play(&"ts_drip", mouth, -4.0))
			drip += DRIP_EVERY
	at(T_OPEN + lv_span, _drain)
	ctx.play(&"hs_rumble", mouth, -2.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(mouth)
	# The street darkens and stays dark where the water will lie: the wet ground, under everything else.
	var wet_ground := FxParts.frost_ground(self, mouth, lv_radius + 0.2)
	wet_ground.z_index = 1
	wet_ground.set_param("plate", WET)
	wet_ground.set_param("crack", Color(0.2, 0.28, 0.4, 0.12))
	wet_ground.set_param("rim", Color(0.3, 0.4, 0.5, 0.3))
	wet_ground.set_param("progress", 0.0)
	wet_ground.tween_param("progress", 0.0, 1.0, SPREAD, T_OPEN, Tween.TRANS_QUAD, Tween.EASE_OUT)
	wet_ground.tween_param("fade", 1.0, 0.0, 0.3, duration - 0.3)
	var pool := Pool.new()
	pool.fx = self
	pool.position = mouth
	pool.z_index = 2
	track(pool, ctx.ground)
	var side := (lv_radius + 1.0) * 2.0
	var water := QuadFx.new().setup(SH_FLOOD, Vector2(side, side))
	water.set_param("length", side)
	water.set_param("width", side)
	water.set_param("settle", 0.55)
	water.set_param("seed", ctx.rng.randf() * 10.0)
	water.set_param("deep", WATER_DEEP)
	water.set_param("body", WATER_BODY)
	water.set_param("mid", WATER_MID)
	water.set_param("foam", WATER_FOAM)
	water.set_param("foam_shadow", WATER_FOAM_SHADOW)
	pool.add_child(water)
	if standing:
		# Left lying, the water settles calm, and fades as it soaks away.
		water.tween_param("settle", 0.55, 1.0, DRAIN + 1.0, T_OPEN + lv_span, Tween.TRANS_SINE, Tween.EASE_OUT)
		water.tween_param("fade", 1.0, 0.0, STAND_FADE, stand_end() - STAND_FADE, Tween.TRANS_QUAD, Tween.EASE_IN)
	var shore := Shore.new()
	shore.fx = self
	shore.position = mouth
	shore.z_index = 3
	track(shore, ctx.ground)
	# The turning: foam arms winding into the door, flecks riding them in, and the door itself over both.
	var arms := Arms.new()
	arms.fx = self
	arms.position = mouth
	arms.z_index = 3
	track(arms, ctx.ground)
	var flecks := Flecks.new()
	flecks.fx = self
	flecks.rng.seed = ctx.rng.randi()
	flecks.position = mouth
	flecks.z_index = 3
	track(flecks, ctx.ground)
	var door := Mouth.new()
	door.fx = self
	door.position = mouth
	# Over the sheen and the rings: light does not reach into the hole, and a ring closing on it is gone at its lip.
	door.z_index = 7
	track(door, ctx.ground)
	# The funnel: the screen itself is turned and drawn into the hole, harder as the water spreads, easing as it drains.
	var funnel := FxParts.singularity(self, mouth, FUNNEL_R, FxParts.ICE)
	funnel.set_param("strength", 0.0)
	funnel.set_param("pinch", 0.0)
	funnel.set_param("core_px", 0.0)
	funnel.set_param("arm_alpha", 0.0)
	funnel.set_param("rim_boost", 0.0)
	funnel.set_param("tint", 0.0)
	# A turn the other way round in the shader's own sense is clockwise on screen: the middle runs ahead of the rim.
	funnel.tween_param("strength", 0.0, -1.1, SPREAD, T_OPEN, Tween.TRANS_QUAD, Tween.EASE_OUT)
	funnel.tween_param("pinch", 0.0, 0.5, SPREAD, T_OPEN, Tween.TRANS_QUAD, Tween.EASE_OUT)
	funnel.tween_param("arm_alpha", 0.0, 0.2, SPREAD, T_OPEN)
	funnel.tween_param("strength", -1.1, 0.0, DRAIN, T_OPEN + lv_span, Tween.TRANS_QUAD, Tween.EASE_IN)
	funnel.tween_param("pinch", 0.5, 0.0, DRAIN, T_OPEN + lv_span, Tween.TRANS_QUAD, Tween.EASE_IN)
	funnel.tween_param("arm_alpha", 0.2, 0.0, DRAIN, T_OPEN + lv_span)
	funnel.tween_param("alpha", 1.0, 0.0, 0.1, T_OPEN + lv_span + DRAIN - 0.1)
	funnel.life = T_OPEN + lv_span + DRAIN + 0.05
	# A cold sheen on the ground about the water, and pale sky glints on its surface.
	var light := FxParts.ground_light(self, mouth, lv_radius * 1.1, SKY, 0.0)
	light.tween_param("intensity", 0.0, 0.22, SPREAD, T_OPEN)
	if standing:
		# The standing water keeps a fainter sheen of sky, gone as it soaks away.
		light.tween_param("intensity", 0.22, 0.1, DRAIN, T_OPEN + lv_span)
		light.tween_param("intensity", 0.1, 0.0, STAND_FADE, stand_end() - STAND_FADE)
	else:
		light.tween_param("intensity", 0.22, 0.0, DRAIN, T_OPEN + lv_span)
	_glints = FxParts.emitter(self, ctx.overhead_back, sp, PixelParticles.Shape.SQUARE, GLINT, 16.0, lv_span + DRAIN, {
		"radius": 0.0, "speed": Vector2(0, 3), "alt": Vector2(0, 1), "alt_speed": Vector2(0, 2), "life": Vector2(0.25, 0.6),
		"size": Vector2(1, 1)})
	_glints.emitting = false
	# Spray thrown up where the water goes over the door's lip.
	_spray = FxParts.emitter(self, ctx.overhead_back, sp, PixelParticles.Shape.SQUARE, Set2Parts.FOAM_LIFE, 22.0, lv_span + DRAIN, {
		"radius": FxParts.particle_radius(MOUTH_R), "speed": Vector2(4, 14), "dir": PixelParticles.Dir.INWARD,
		"alt": Vector2(0, 2), "alt_speed": Vector2(14, 42), "life": Vector2(0.25, 0.5), "size": Vector2(1, 1)})
	_spray.gravity = 220.0
	_spray.emitting = false
	_ripple_in = 0.3


## The door is open: the water bursts out of it and begins to turn, and the circle is a danger the town knows.
func _open() -> void:
	ctx.play(&"ts_crash", mouth, 0.0)
	if ctx.crowd != null:
		ctx.crowd.threats.register(mouth, lv_radius, THREAT, lv_span, THREAT_SIGHT, THREAT_SOUND, &"water")
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.3)
	ctx.flash.call(Color(0.1, 0.2, 0.4, 0.12), 0.2)
	if is_instance_valid(_glints):
		_glints.emitting = true
	if is_instance_valid(_spray):
		_spray.emitting = true
	var sp := Iso.ground_to_screen(mouth)
	var ring := FxParts.shockwave(self, mouth, FIRST_REACH + 1.2, FxParts.ICE_WAVE)
	ring.set_param("thickness", 0.14)
	ring.set_param("inner_heat", 0.0)
	ring.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.3, 0.25)
	ring.life = 0.6
	var spray := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, Set2Parts.WATER_LIFE)
	spray.gravity = 320.0
	spray.drag = 0.6
	spray.burst(70, {"radius": FxParts.particle_radius(MOUTH_R), "speed": Vector2(20, 90), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(60, 200), "life": Vector2(0.5, 1.1), "size": Vector2(1, 3)})
	var foam := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, Set2Parts.FOAM_LIFE)
	foam.gravity = 260.0
	foam.drag = 0.8
	foam.burst(24, {"radius": FxParts.particle_radius(MOUTH_R * 0.6), "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD,
		"alt": Vector2(0, 16), "alt_speed": Vector2(40, 140), "life": Vector2(0.5, 0.9), "size": Vector2(2, 4), "size_end_mul": 0.5})


## The span is over: the water runs back into the door, and the torrent's roar dies with it.
func _drain() -> void:
	ctx.play(&"ts_roar", mouth, -4.0)
	_hush(DRAIN)
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.12)
	if is_instance_valid(_glints):
		_glints.emitting = false
	if is_instance_valid(_spray):
		_spray.emitting = false


## The roar (a looping cue) fades over `seconds`, if it is still this door's to fade.
func _hush(seconds: float) -> void:
	if _roar != null and is_instance_valid(_roar) and _roar.get_meta(&"cue", &"") == &"tn_wind":
		ctx.fade_out(_roar, seconds)
	_roar = null


func _fx_process(delta: float) -> void:
	# The rules run on their own clock, a tick at a time, so a long frame (or a test's long step) misses none.
	while t >= T_OPEN + TICK * float(_ticks):
		_tick(T_OPEN + TICK * float(_ticks))
		_ticks += 1
	# Time stands still: the torrent with it.
	if delta > 0.0 and not (ctx.crowd != null and ctx.crowd.is_frozen()):
		var steps := maxi(ceili(delta / CARRY_STEP - 0.001), 1)
		var h := delta / float(steps)
		for k in steps:
			_carry(t - delta + h * float(k + 1), h)
	if not DominionParts.staged(self):
		return
	var r := reach(t)
	if is_instance_valid(_glints):
		_glints.spec["radius"] = FxParts.particle_radius(maxf(r - 0.3, 0.0))
	_ripple_in -= delta
	if r > MOUTH_R + 0.6 and t < T_OPEN + lv_span and _ripple_in <= 0.0:
		# A ring of foam closing on the door: the water is going in, not out.
		_ripple_in = RIPPLE_EVERY
		var ripple := FxParts.shockwave(self, mouth, r, FxParts.ICE)
		ripple.set_param("thickness", 0.05)
		ripple.set_param("inner_heat", 0.0)
		ripple.tween_param("progress", 0.95, MOUTH_R / r, 1.4, 0.0, Tween.TRANS_SINE, Tween.EASE_IN)
		ripple.tween_param("fade", 0.0, 0.5, 0.5)
		ripple.tween_param("fade", 0.5, 0.0, 0.3, 1.1)
		ripple.life = 1.45


## One step of the torrent, `h` seconds ending at `now`: everyone in the water is carried toward the door and round
## it, and whoever is within MAW of the mouth -- there already, or carried there -- goes under.
func _carry(now: float, h: float) -> void:
	var r := reach(now)
	if r <= 0.001:
		return
	var share := force(now)
	if share <= 0.0:
		return  # Standing Water: the door is shut; the water lies still
	for e in ctx.field.in_radius(mouth, r):
		var p := e as Person
		if p == null or p.inside or p.is_frozen():
			continue
		var id := p.get_instance_id()
		if not _caught.has(id):
			_caught[id] = true
			caught += 1
		var rel := p.ground_pos - mouth
		var d := rel.length()
		if d <= MAW:
			_take(p)
			continue
		# Nearer by the pull, and turned by the swirl (a turn about the door keeps the distance: clockwise on screen
		# is the positive way round on the ground).
		var nearer := rel * ((d - minf(pull_speed(d, lv_radius, lv_pull_core) * share * h, d)) / d)
		var turn := SWIRL * share * h / d
		for spot: Vector2 in [mouth + nearer.rotated(turn), mouth + nearer, mouth + rel.rotated(turn)]:
			if _open_ground(spot):
				p.ground_pos = spot
				break
		p._sync_position()
		if p.ground_pos.distance_to(mouth) <= MAW:
			_take(p)


## Whether the water may set someone down at `g`: on the map, and not in a wall or a building.
func _open_ground(g: Vector2) -> bool:
	return ctx.field.bounds.has_point(g) and not ctx.env.blocked(g)


## The door takes `p`: dragged under and through it.
func _take(p: Person) -> void:
	var from := p.ground_pos
	if not ctx.field.kill(p, &"pit", mouth):
		return
	drowned += 1
	if t >= _gulp_at:
		_gulp_at = t + GULP_EVERY
		ctx.play(&"grav_suction", mouth, -3.0)
	if not DominionParts.staged(self):
		return
	# Where they went over the lip: a splash, and a ring closing on the hole.
	var sp := Iso.ground_to_screen(from)
	var ring := FxParts.shockwave(self, mouth, MOUTH_R + 0.5, FxParts.ICE_WAVE)
	ring.set_param("thickness", 0.1)
	ring.set_param("inner_heat", 0.0)
	ring.tween_param("progress", 1.0, 0.3, 0.45, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	ring.tween_param("fade", 0.75, 0.0, 0.2, 0.25)
	ring.life = 0.5
	var splash := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, Set2Parts.FOAM_LIFE)
	splash.gravity = 300.0
	splash.drag = 0.5
	splash.burst(26, {"radius": 3.0, "speed": Vector2(8, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 4),
		"alt_speed": Vector2(50, 150), "life": Vector2(0.35, 0.8), "size": Vector2(1, 2)})
	ctx.shake.add_trauma(0.08)


## One tick of the water at `now`: who is in it is slowed, who has left it has their pace back, every fire in it is
## doused a bucket's worth, every building in it takes SOAK. Once the door has shut over standing water, the
## standing water's tick instead.
func _tick(now: float) -> void:
	if standing and now >= shut_at():
		_tick_standing(now)
		return
	var r := reach(now)
	if r <= 0.001:
		if _flooded:
			_dry_all()
			_flooded = false
		return
	_flooded = true
	var in_water := {}
	for e in ctx.field.in_radius(mouth, r):
		var p := e as Person
		if p == null or p.inside or not p.is_alive():
			continue
		var id := p.get_instance_id()
		in_water[id] = true
		if not _soaked.has(id):
			_soaked[id] = [p, null]
			p.hold_pace(get_instance_id(), SLOW)
	for id in _soaked.keys():
		if not in_water.has(id):
			_dry(id)
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	for s in ctx.env.near(mouth, r):
		if not is_instance_valid(s) or s.destroyed or s.distance_to(mouth) > r:
			continue
		if fires != null and fires.is_burning(s):
			fires.douse(s)
			if not fires.is_burning(s):
				doused += 1
				_steam(s)
		s.damage(SOAK, mouth, &"water")
		soaked_damage += SOAK


## One tick of the standing water at `now` (Standing Water): whoever is in it walks at STAND_SLOW; whoever has left it
## (or whom it has soaked away from) is soaked SOAKED_FOR more, then has their pace back; every fire in it is doused.
## Nobody is carried and no wall takes water any more.
func _tick_standing(now: float) -> void:
	var r := reach(now)
	var in_water := {}
	if r > 0.001:
		_flooded = true
		for e in ctx.field.in_radius(mouth, r):
			var p := e as Person
			if p == null or p.inside or not p.is_alive():
				continue
			var id := p.get_instance_id()
			in_water[id] = true
			if not _soaked.has(id):
				_soaked[id] = [p, null, INF]
			var held: Array = _soaked[id]
			if held.size() < 3:
				held.append(INF)
			held[2] = INF
			if not is_equal_approx(float(p.pace_holds.get(get_instance_id(), -1.0)), STAND_SLOW):
				p.hold_pace(get_instance_id(), STAND_SLOW)
	for id in _soaked.keys():
		if in_water.has(id):
			continue
		var held: Array = _soaked[id]
		if held.size() < 3:
			held.append(INF)
		if held[2] == INF:
			held[2] = now + SOAKED_FOR
		elif now >= float(held[2]) - 0.001:
			_dry(id)
	if r <= 0.001:
		_flooded = false
		return
	var fires: FireManager = ctx.crowd.fires if ctx.crowd != null else null
	if fires == null:
		return
	for s in ctx.env.near(mouth, r):
		if not is_instance_valid(s) or s.destroyed or s.distance_to(mouth) > r or not fires.is_burning(s):
			continue
		fires.douse(s)
		if not fires.is_burning(s):
			doused += 1
			_steam(s)


## Whether `p` is soaked by the water now: in it, or out of the standing water but not yet dry.
func soaks(p: Person) -> bool:
	return _soaked.has(p.get_instance_id())


## The one remembered under `id` is out of the water: their pace is theirs again.
func _dry(id: int) -> void:
	var held: Array = _soaked[id]
	_soaked.erase(id)
	var p: Person = held[0]
	if not is_instance_valid(p):
		return
	p.free_pace(get_instance_id())


func _dry_all() -> void:
	for id in _soaked.keys():
		_dry(id)


## A fire put out: steam off the building.
func _steam(s: Structure) -> void:
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(s.center()) + Vector2(0, -s.height * 0.4)
	FxParts.smoke(self, sp, 10.0, 22.0, 0.9, Vector2(25, 60), Vector2(3, 6), Vector2(0.8, 1.5), Color(0, 0, 0, 0), STEAM)


## Cut short (the act ends): nobody is left slowed, and the roar stops.
func end_now() -> void:
	_dry_all()
	_hush(0.3)
	super.end_now()


## Over (its time run out, or cut short): nobody it soaked is left slowed.
func _finish() -> void:
	_dry_all()
	super()


## The water's shape at `r` from the door: a circle whose edge laps, in ground units.
static func shore(r: float, time: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 72:
		var a := float(i) / 72.0 * TAU
		var w := r * (1.0 + 0.025 * sin(a * 5.0 + time * 2.1) + 0.018 * sin(a * 9.0 - time * 1.3) + 0.012 * sin(a * 3.0 + time * 0.7))
		pts.append(Vector2(cos(a), sin(a)) * w)
	return pts


## The water's body on the ground: the circle of reach, lapping at its edge, with the flood drawn inside it (its
## children are clipped to the shape).
class Pool extends Node2D:
	var fx: DoorToTheDeepFx

	func _ready() -> void:
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		visible = false

	func _process(_delta: float) -> void:
		if fx.t > fx.visuals_end():
			queue_free()
			return
		# No water, no pool: a clipping parent that draws nothing would let the flood through whole.
		visible = fx.reach(fx.t) > 0.02
		queue_redraw()

	func _draw() -> void:
		var r := fx.reach(fx.t)
		if r <= 0.02:
			return
		draw_colored_polygon(DoorToTheDeepFx.shore(r, fx.t), Color.WHITE)


## The water's edge: a pale line lapping round the pool.
class Shore extends Node2D:
	var fx: DoorToTheDeepFx

	func _process(_delta: float) -> void:
		if fx.t > fx.visuals_end():
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var r := fx.reach(fx.t)
		if r <= 0.05:
			return
		var pts := DoorToTheDeepFx.shore(r, fx.t)
		pts.append(pts[0])
		draw_polyline(pts, Color(PALE, 0.4), 0.05)
		draw_polyline(pts, Color(WATER_FOAM_SHADOW, 0.3), 0.1)


## The torrent's foam arms: COUNT spirals of pale foam winding from the rim into the door, the way the water runs --
## following one inward goes clockwise on screen. They turn TURN a second at the rim and the faster the nearer the
## door (as RADIUS / r), so each arm winds itself tighter as it ages; before it is wound to nothing it fades, and a
## fresh one, loosely wound, has faded in between its neighbours (two sets, half a LAP apart). Beads of brighter foam
## run down each arm into the hole. Drawn in ground units about the mouth, out to the water's reach.
class Arms extends Node2D:
	const COUNT := 4
	const SEGMENTS := 30
	## How far an arm winds round the door for each e-fold nearer it, when half its age.
	const WIND := 1.25
	const LAP := 2.6
	## The most the inside may run ahead of the rim, as a multiple of the rim's turn (it would be endless at the middle).
	const LEAD_MOST := 3.5
	var fx: DoorToTheDeepFx

	func _process(_delta: float) -> void:
		if fx.t > fx.visuals_end():
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var outer := fx.reach(fx.t) - 0.08
		var inner := MOUTH_R * fx.opening() * 0.8
		if outer <= inner + 0.3:
			return
		var force := fx.force(fx.t)
		for set_i in 2:
			var age := fposmod(fx.t / LAP + 0.5 * float(set_i), 1.0)
			var show := sin(PI * age)
			show *= show * force
			if show <= 0.02:
				continue
			for k in COUNT:
				var a0 := TAU * (float(k) + 0.5 * float(set_i)) / float(COUNT) + TURN * fx.t
				var pts := PackedVector2Array()
				var cols := PackedColorArray()
				var band := PackedColorArray()
				for i in SEGMENTS + 1:
					# Even steps in the logarithm: as many points to a turn near the door as at the rim.
					var r := outer * pow(inner / outer, float(i) / float(SEGMENTS))
					var lead := minf(fx.lv_radius / r - 1.0, LEAD_MOST)
					var a := a0 + WIND * log(fx.lv_radius / r) + TURN * lead * (age - 0.5) * LAP
					pts.append(Vector2(cos(a), sin(a)) * r)
					# Faint at the rim, bright by the door; beads of foam running in along it.
					var depth := clampf(1.0 - (r - inner) / (fx.lv_radius - inner), 0.0, 1.0)
					var bead := 0.6 + 0.4 * sin(7.0 * log(fx.lv_radius / r) - 4.0 * fx.t + float(k) * 1.7)
					var a_core := show * bead * lerpf(0.14, 0.95, depth)
					cols.append(Color(PALE, a_core))
					band.append(Color(WATER_FOAM_SHADOW, a_core * 0.4))
				# A soft band of churned water, and the bright foam line along it.
				draw_polyline_colors(pts, band, 0.17)
				draw_polyline_colors(pts, cols, 0.06)


## Flecks of foam riding the torrent: each goes round the door (TURN a second at the rim, faster inside, as the arms)
## and in toward it, leaving a short streak behind along its way; at the door it is gone, and another starts at the
## rim. They show the water's motion frame by frame; they follow the same way round as the people it carries.
class Flecks extends Node2D:
	const COUNT := 56
	## How fast a fleck runs in, at the rim and at the mouth (ground units a second): quicker than the people, to be read.
	const IN_RIM := 0.45
	const IN_CORE := 1.7
	## The streak behind a fleck: this many seconds of its way.
	const TAIL := 0.16
	var fx: DoorToTheDeepFx
	var rng := RandomNumberGenerator.new()
	var _r := PackedFloat32Array()
	var _a := PackedFloat32Array()
	var _age := PackedFloat32Array()

	func _ready() -> void:
		for i in COUNT:
			_r.append(rng.randf_range(MOUTH_R * 0.6, fx.lv_radius))
			_a.append(rng.randf() * TAU)
			_age.append(1.0)

	func _process(delta: float) -> void:
		if fx.t > fx.visuals_end():
			queue_free()
			return
		var reach := fx.reach(fx.t)
		var force := fx.force(fx.t)
		var gone := MOUTH_R * 0.55
		for i in COUNT:
			var r := _r[i] - _in(_r[i]) * force * delta
			_age[i] += delta
			if r < gone and reach > gone + 0.2:
				r = reach * rng.randf_range(0.82, 1.0)
				_a[i] = rng.randf() * TAU
				_age[i] = 0.0
			_r[i] = r
			_a[i] = fposmod(_a[i] + _spin(r) * force * delta, TAU)
		queue_redraw()

	func _in(r: float) -> float:
		return lerpf(IN_RIM, IN_CORE, clampf(1.0 - r / fx.lv_radius, 0.0, 1.0))

	func _spin(r: float) -> float:
		return TURN * fx.lv_radius / maxf(r, 0.45)

	func _draw() -> void:
		var reach := fx.reach(fx.t) - 0.1
		var force := fx.force(fx.t)
		if reach <= 0.2:
			return
		for i in COUNT:
			var r := _r[i]
			if r > reach:
				continue
			var a := _a[i]
			var depth := clampf(1.0 - r / fx.lv_radius, 0.0, 1.0)
			var alpha := clampf(_age[i] * 3.0, 0.0, 1.0) * force * lerpf(0.45, 0.95, depth)
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			for j in 4:
				var back := TAIL * float(j) / 3.0
				var rj := minf(r + _in(r) * back, reach)
				var aj := a - _spin(r) * back
				pts.append(Vector2(cos(aj), sin(aj)) * rj)
				cols.append(Color(1.0, 1.0, 1.0, alpha * (1.0 - float(j) / 3.0)))
			draw_polyline_colors(pts, cols, 0.05)


## The door in the street, the middle of the whirlpool: the water darkens as it slopes in to it, then a round black
## hole MOUTH_R across each way, blacker to the middle, water going over its lip in turning streaks, a pale foam rim
## with bright glints running round it the way the torrent turns.
class Mouth extends Node2D:
	var fx: DoorToTheDeepFx

	func _process(_delta: float) -> void:
		if fx.t > fx.visuals_end():
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var o := fx.opening()
		if o <= 0.01:
			return
		var r := MOUTH_R * o
		var spin := fx.t * 2.4
		# The slope: the water darker and darker toward the hole, no farther out than the water itself.
		var slope := minf(fx.reach(fx.t), FUNNEL_R * 0.8)
		for i in 5:
			var sr := lerpf(slope, r * 1.1, float(i) / 4.0)
			if sr > r:
				draw_circle(Vector2.ZERO, sr, Color(DEEP, 0.09))
		# The hole.
		draw_circle(Vector2.ZERO, r, Color(0.005, 0.01, 0.03, 0.98))
		draw_circle(Vector2.ZERO, r * 0.8, Color(0.0, 0.0, 0.01, 1.0))
		draw_circle(Vector2.ZERO, r * 0.5, Color(0.0, 0.0, 0.0, 1.0))
		# Water going over the lip and down: streaks turning in the throat, quicker the deeper.
		for j in 5:
			var a0 := spin * (1.0 + 0.35 * float(j)) + float(j) * 2.1
			var rr := r * (0.92 - 0.14 * float(j))
			draw_arc(Vector2.ZERO, rr, a0, a0 + 1.5 - 0.15 * float(j), 14, Color(SKY, 0.3 - 0.06 * float(j)), 0.04)
		# The rim of foam, and the glints running round it.
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(PALE, 0.6), 0.06)
		draw_arc(Vector2.ZERO, r + 0.09, 0.0, TAU, 48, Color(SKY, 0.25), 0.04)
		for j in 3:
			var ga := spin * 0.9 + float(j) * TAU / 3.0
			draw_arc(Vector2.ZERO, r, ga, ga + 0.75, 10, Color(1, 1, 1, 0.92), 0.085)
			draw_arc(Vector2.ZERO, r + 0.12, ga - 0.5, ga + 0.2, 8, Color(PALE, 0.5), 0.05)
