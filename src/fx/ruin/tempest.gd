class_name TempestFx
extends FxTimeline
## Wrath of the Sky (Ruin, Tier V; key tempest): a storm over the whole town. It gathers for T_GATHER -- clouds roll in, the light goes, the
## wind rises, sheet lightning flickers in the ceiling, and the calm look up (the cast's danger lands at the first
## bolt) -- then for STORM_TIME it rains, and every VOLLEY_EVERY a volley of VOLLEY bolts falls, VOLLEY_GAP apart,
## somewhere in the town: a drumbeat, each volley's first bolt the hardest (hitstop, the screen torn, the camera kicked).
## Every bolt is told LEAD before it falls: a ring and a rising light mark the ground where it will strike, so the
## eye is there when it lands. Each bolt is a Smite, bigger: whoever stands within its kill radius is
## struck down (damage kind lightning; HARD_R / LIGHT_R: a volley's first bolt is the thickest and reaches farthest),
## what stands within its hit radius takes DAMAGE
## (damage kind tempest, never a fire of itself), and every FIRE_EVERY-th bolt sets what it struck alight (the town's
## fire from there). Where the bolts fall is drawn, weighted, from the god's rng: tall things draw them (a structure
## weighs 1 + (height / HEIGHT_PER)^2, so the Bell Tower, the spire and the keep far most), people in the open weigh PERSON_W
## plus CROWD_W for every neighbour within CROWD_R (a knot of people draws the bolt, a straggler less),
## bare ground a share of GROUND_SHARE, and never twice within NO_REPEAT of the last. The rain sends the calm indoors
## (ShelterManager: a RAIN_CHANCE try every RAIN_EVERY for each calm citizen in the open), so the streets empty and the
## storm hunts those who must stay out. Then it breaks: T_BREAK of thinning rain and returning light. Loud: the cast
## itself frightens nobody but is seen by all (PowerBook.REACH); every bolt frightens those near it (Crowd.fright()).

const T_GATHER := 5.0
const STORM_TIME := 25.0
const T_BREAK := 5.0
const VOLLEY_EVERY := 1.3
const VOLLEY := Vector2i(5, 7)
const VOLLEY_GAP := 0.09
const LEAD := 0.5
## [kill radius, hit radius] of a volley's first bolt and of the rest: the bolt reaches people farther than walls.
const HARD_R := Vector2(1.6, 1.0)
const LIGHT_R := Vector2(1.1, 0.7)
const DAMAGE := 45.0
const FIRE_EVERY := 4
const FIRE_LEVEL := 0.4
const HEIGHT_PER := 15.0
const PERSON_W := 4.0
## Each neighbour within CROWD_R of a person adds this much more: the storm hunts the knot, not the straggler.
const CROWD_R := 1.0
const CROWD_W := 1.5
const GROUND_SHARE := 0.05
const NO_REPEAT := 2.0
## Level 5 twist, Called Bolts: the player may call a hard bolt exactly where they click, once in CALL_EVERY, while the storm rains.
const CALL_EVERY := 3.0
const RAIN_EVERY := 1.0
const RAIN_TRIES := 40
const BOLT := Color("9fd0ff")
const LIGHT := Color(0.7, 0.85, 1.0)
const STORM_DIM := Color(0.04, 0.06, 0.14, 0.26)
const RAIN := [Color(0.75, 0.82, 0.95, 0.8), Color(0.6, 0.7, 0.9, 0.7), Color(0.5, 0.6, 0.8, 0.5), Color(0.4, 0.5, 0.7, 0.3)]
## Fright of one bolt: radius, severity, seconds, sight, sound.
const BOLT_FRIGHT := [1.0, 0.6, 3.0, 6.0, 12.0]

## What the storm has done.
var bolts := 0
var struck := 0
var fires := 0
var sent_in := 0
## Where the last bolt fell.
var last_at := Vector2.INF
## How many bolts the player called (level 5), and when the last was.
var called := 0
var _last_called := -INF

var _next_volley := 0.0
## How many volleys have fallen.
var volleys := 0
var _rain_in := 0.0
var _clouds: QuadFx
var _rain: PixelParticles
var _flicker := 0.0
## This cast's storm length, bolts per volley and time between volleys: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_storm_time := STORM_TIME
var lv_volley := VOLLEY
var lv_volley_every := VOLLEY_EVERY


## The storm's hours: gathering, storm, breaking.
func storming() -> bool:
	return t >= T_GATHER and t < T_GATHER + lv_storm_time


## Whether a click would call a bolt now (the Called Bolts twist, level 5): the storm is raining and the last call is CALL_EVERY behind.
func can_call() -> bool:
	return PowerBook.twist_at(extra, "tempest") and storming() and t - _last_called >= CALL_EVERY


## The player calls a bolt down at `where`: told LEAD ahead as any bolt is, then a hard one exactly there (no pick, no rng). It counts in
## `bolts` (so in FIRE_EVERY). False -- and nothing happens -- when the twist is not this cast's or it is not the time.
func call_bolt(where: Vector2) -> bool:
	if not can_call():
		return false
	called += 1
	_last_called = t
	_omen(where, LEAD, true)
	at(t + LEAD, _bolt.bind(where, true))
	return true


## The shared follow-up (Rules.recast): a click is a call while Called Bolts can be had.
func can_follow_up() -> bool:
	return can_call()


## The shared follow-up (Rules.recast): the click calls a bolt.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	return call_bolt(at_pos)


func _build() -> void:
	lv_storm_time = float(PowerBook.stat(extra, "tempest", "STORM_TIME", STORM_TIME))
	lv_volley = PowerBook.stat(extra, "tempest", "VOLLEY", VOLLEY) as Vector2i
	lv_volley_every = float(PowerBook.stat(extra, "tempest", "VOLLEY_EVERY", VOLLEY_EVERY))
	duration = T_GATHER + lv_storm_time + T_BREAK
	busy = T_GATHER
	_next_volley = T_GATHER + 0.2
	at(T_GATHER, _storm)
	at(T_GATHER + lv_storm_time, _break)
	ctx.play(&"hs_rumble", origin, 4.0)
	ctx.play(&"tn_form", origin, -2.0)
	if not DominionParts.staged(self):
		return
	var centre := Iso.ground_to_screen(ctx.field.bounds.get_center())
	var dim := Dim.new()
	dim.fx = self
	dim.z_index = 9
	track(dim, ctx.overhead)
	_clouds = FxParts.quad(self, preload("res://shaders/storm_clouds.gdshader"), Vector2(3400.0, 2000.0), ctx.overhead)
	_clouds.position = centre + Vector2(0, -120)
	_clouds.z_index = 10
	_clouds.set_param("cover", 0.0)
	_clouds.set_param("scale", 9.0)
	_clouds.set_param("drift", 0.08)
	_clouds.tween_param("cover", 0.0, 1.0, T_GATHER, 0.0, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_clouds.tween_param("cover", 1.0, 0.0, T_BREAK, T_GATHER + lv_storm_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	_clouds.life = duration + 0.1
	# The wind rises: dust blown across the town, low.
	var dust := FxParts.emitter(self, ctx.overhead_back, centre, PixelParticles.Shape.STREAK, FxParts.FIRE_LIFE, 60.0, T_GATHER + lv_storm_time,
		{"radius": 900.0, "velocity": Vector2(90, 0), "life": Vector2(0.6, 1.4), "size": Vector2(1, 1), "alt": Vector2(0, 8)})
	dust.drag = 0.2


func _storm() -> void:
	ctx.play(&"nova_crack", origin, -3.0)
	if not DominionParts.staged(self):
		return
	var centre := Iso.ground_to_screen(ctx.field.bounds.get_center())
	_rain = FxParts.emitter(self, ctx.overhead, centre + Vector2(0, -200), PixelParticles.Shape.STREAK, RAIN, 700.0, lv_storm_time,
		{"radius": 1100.0, "velocity": Vector2(-50, 340), "life": Vector2(0.7, 1.1), "size": Vector2(1, 3)})
	_rain.z_index = 11
	_rain.iso_squash = 0.55
	ctx.shake.add_trauma(0.2)


func _break() -> void:
	ctx.play(&"hs_rumble", origin, 2.0)
	ctx.play(&"tn_dissipate", origin, -2.0)


func _fx_process(delta: float) -> void:
	# Sheet lightning in the ceiling while it gathers and storms.
	if _clouds != null and is_instance_valid(_clouds):
		_flicker = maxf(_flicker - delta * 6.0, 0.0)
		if t < T_GATHER + lv_storm_time and ctx.rng.randf() < delta * (0.5 if t < T_GATHER else 0.25):
			_flicker = ctx.rng.randf_range(0.4, 0.9)
		_clouds.set_param("flicker", _flicker)
	if not storming():
		return
	if t >= _next_volley:
		_next_volley = t + lv_volley_every
		_volley()
	_rain_in -= delta
	if _rain_in <= 0.0:
		_rain_in = RAIN_EVERY
		_send_in()


## Where the next bolt falls: a structure by its height, a person in the open, or bare ground.
func _pick() -> Vector2:
	var targets: Array = []
	var weights: Array[float] = []
	var total := 0.0
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed or s.role == &"thorns":
			continue
		var w := 1.0 + (s.height / HEIGHT_PER) * (s.height / HEIGHT_PER)
		targets.append(s.center())
		weights.append(w)
		total += w
	for p in DominionParts.near(ctx.field, ctx.field.bounds.get_center(), ctx.field.bounds.size.length()):
		var w := PERSON_W + CROWD_W * float(ctx.field.in_radius(p.ground_pos, CROWD_R).size() - 1)
		targets.append(p.ground_pos)
		weights.append(w)
		total += w
	var ground := total * GROUND_SHARE
	total += ground
	for tries in 8:
		var roll := ctx.rng.randf() * total
		var at := Vector2.INF
		if roll >= total - ground:
			at = Vector2(ctx.rng.randf_range(ctx.field.bounds.position.x + 4.0, ctx.field.bounds.end.x - 4.0),
				ctx.rng.randf_range(ctx.field.bounds.position.y + 4.0, ctx.field.bounds.end.y - 4.0))
		else:
			for i in targets.size():
				roll -= weights[i]
				if roll <= 0.0:
					at = targets[i]
					break
			if at == Vector2.INF:
				at = targets[-1]
		if last_at == Vector2.INF or at.distance_to(last_at) > NO_REPEAT:
			return at
	return origin


## A volley: the first bolt now and hard, the rest on its heels.
func _volley() -> void:
	var n := ctx.rng.randi_range(lv_volley.x, lv_volley.y)
	if t + LEAD + VOLLEY_GAP * float(n - 1) > T_GATHER + lv_storm_time:
		return  # too late in the storm for a whole volley
	volleys += 1
	for i in n:
		var where := _pick()
		var hard := i == 0
		var lead := LEAD + VOLLEY_GAP * float(i)
		_omen(where, lead, hard)
		at(t + lead, func() -> void:
			_bolt(where, hard))


## The warning at `at`, `lead` seconds ahead of the bolt: a ring on the ground where it will strike, lit from above.
func _omen(at: Vector2, lead: float, hard: bool) -> void:
	if not DominionParts.staged(self):
		return
	var r := (HARD_R if hard else LIGHT_R).y
	var mark := FxParts.rings(self, at, r, Color("e8f4ff"), 2, 10.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, lead * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = lead + 0.05
	# The ground under it lit from the cloud, brighter as the bolt nears.
	var under := FxParts.ground_light(self, at, r * 1.6, LIGHT, 0.0)
	under.tween_param("intensity", 0.0, 0.9, lead, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	under.life = lead + 0.05


## One bolt at `at`; `hard` for a volley's first: the blow the player feels.
func _bolt(at: Vector2, hard: bool) -> void:
	bolts += 1
	last_at = at
	var kill_r := (HARD_R if hard else LIGHT_R).x
	var hit_r := (HARD_R if hard else LIGHT_R).y
	for e in ctx.field.in_radius(at, kill_r):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"lightning", at):
			struck += 1
	ctx.env.damage_radius(at, hit_r, DAMAGE, &"tempest")
	if bolts % FIRE_EVERY == 0 and ctx.crowd != null:
		for s in ctx.env.near(at, hit_r):
			if is_instance_valid(s) and not s.destroyed and s.kind in FireManager.BURNABLE:
				ctx.crowd.fires.ignite(s, FIRE_LEVEL)
				fires += 1
				break
	if ctx.crowd != null:
		ctx.crowd.fright(at, hit_r + 0.3, BOLT_FRIGHT[1], BOLT_FRIGHT[2], BOLT_FRIGHT[3], BOLT_FRIGHT[4], &"lightning")
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at)
	ctx.flash.call(Color(0.85, 0.92, 1.0, 0.3 if hard else 0.14), 0.22)
	ctx.shake.add_trauma(0.45 if hard else 0.2)
	if hard:
		ctx.impact.hitstop(0.04)
		ctx.impact.aberration(1.6, 0.2)
		ctx.shake.kick(Vector2(0, 3))
	var b := Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-30.0, 30.0), -460.0), sp, 0.3, 2.8 if hard else 1.8, 3, BOLT)
	b.z_index = 12
	var b2 := Set2Parts.bolt(self, ctx.overhead, sp + Vector2(ctx.rng.randf_range(-12.0, 12.0), -460.0), sp, 0.18, 1.2, 1, Color("f0f8ff"))
	b2.z_index = 12
	var glow := FxParts.bloom(self, sp + Vector2(0, -6), 34.0 if hard else 28.0, LIGHT, 1.2, 0.8)
	glow.tween_param("intensity", 1.2, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.42
	# The blow on the ground: Smite's ring, out and gone.
	var ring := FxParts.shockwave(self, at, hit_r + 0.5, FxParts.ION)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.28, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.18, 0.14)
	ring.life = 0.36
	var light := FxParts.ground_light(self, at, hit_r * 2.0, LIGHT, 1.3)
	light.tween_param("intensity", 1.3, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.52
	var scorch := FxParts.decal(self, at, hit_r * 0.9, Color("6aa8ff"), Color("e8f4ff"))
	scorch.tween_param("heat", 1.0, 0.0, 1.0)
	scorch.tween_param("fade", 1.0, 0.0, 0.6, 1.0)
	FxParts.sparks(self, ctx.overhead, sp, 18 if hard else 10, FxParts.ION_LIFE, Vector2(60, 220), Vector2(30, 200))
	if hard:
		FxParts.smoke(self, sp, 5.0, 12.0, 0.5, Vector2(14, 36), Vector2(2, 4), Vector2(0.6, 1.1))
	# Thunder: the nearer the bolt to the cast, the sooner and the louder.
	var delay := clampf(at.distance_to(origin) / 14.0, 0.05, 1.2)
	at(t + delay, func() -> void:
		ctx.play(&"hs_strike", at, 0.0 if hard else -6.0)
		if hard:
			ctx.play(&"nova_crack", at, -3.0))


## The rain sends the calm indoors.
func _send_in() -> void:
	if ctx.crowd == null or ctx.crowd.shelters == null:
		return
	var tries := 0
	for p in ctx.crowd.citizens:
		if tries >= RAIN_TRIES:
			break
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		if not (p.mind == Person.Mind.CALM or p.mind == Person.Mind.RECOVER or p.mind == Person.Mind.OBSERVE):
			continue
		tries += 1
		if ctx.crowd.shelters.try_shelter(p, p.ground_pos, 0.0, &"rain"):
			sent_in += 1


## How dark the storm has made the day.
func darkness() -> float:
	return clampf(minf(t / T_GATHER, (duration - t) / T_BREAK), 0.0, 1.0)


## The storm's light: the whole town under a cold cast while the clouds hold, lit white for a frame when a bolt falls
## (the flash is the camera's; this is the sky's).
class Dim extends Node2D:
	var fx: TempestFx

	func _process(_delta: float) -> void:
		if fx.t >= fx.duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.darkness()
		if a <= 0.0:
			return
		draw_rect(Rect2(-6000, -6000, 12000, 12000), Color(STORM_DIM, STORM_DIM.a * a * (1.0 - fx._flicker * 0.5)))

