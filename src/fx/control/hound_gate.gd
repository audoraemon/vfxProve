class_name HoundGateFx
extends FxTimeline
## Hound Gate (Passage, Tier II): a low door opens in the ground where the click lands -- or where an open passage
## (EnemyField.through) carries it -- over T_OPEN, and HOUNDS hounds of the other side come through it, one every
## OUT_EVERY. They are Visitors: each hunts whoever is nearest, citizen or soldier, out in the open within SEEK_R,
## runs at SPEED, and bites (within BITE_R, every BITE_EVERY) -- a citizen falls to one bite, a soldier to two (damage
## kind frenzy). They fear nothing: no danger, strike or fright turns them. The guard cuts them down: a soldier beside
## a hound lands a blow every Visitors.GUARD_SWING and at BLOWS blows it is gone in black smoke; a struck hound flinches
## and begins its bite again, so one guard holds one hound off and two hounds on one guard bring him down; soldiers at
## their post within SEEK_R are drawn to the fight. The door stands open while they come (a danger the town sees,
## kind beast), shuts behind the last, and HUNT after the last comes out it opens again: the hounds run back through it
## and it shuts for good. Loud (PowerBook.REACH): the first bite is the first kill, OUT_EVERY after the door opens.

const T_OPEN := 0.8
const HOUNDS := 4
const OUT_EVERY := 0.4
const HUNT := 30.0
const BLOWS := 3
const SPEED := 2.4
const SEEK_R := 8.0
const BITE_R := 0.5
const BITE_EVERY := 1.0
## The recall: how long the hounds have to get back through the door.
const RECALL := 3.5
## How the door shows: its width in ground units, its shut, and the other side's colours.
const DOOR_W := 1.2
const T_SHUT := 0.4
const RIM := Color(1.0, 0.42, 0.12)
const EMBER := Color(1.0, 0.45, 0.1)
const COAT := Color(0.22, 0.18, 0.24)
const PITCH := [Color("1a1418"), Color("16121a"), Color("120f14"), Color(0.07, 0.06, 0.08, 0.8), Color(0.05, 0.04, 0.06, 0.4)]

## The door, and the hounds: how many have come out.
var mouth := Vector2.ZERO
var visitors: Visitors
var out := 0

var _door: Door
var _glow: QuadFx
var _trails := {}


## When the last hound comes out, and when the hunt ends.
func last_out() -> float:
	return T_OPEN + float(HOUNDS - 1) * OUT_EVERY


func hunt_end() -> float:
	return T_OPEN + float(HOUNDS) * OUT_EVERY + HUNT


func _build() -> void:
	mouth = ctx.field.through(origin)
	duration = hunt_end() + 4.0
	busy = T_OPEN
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, _grid(), parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	ctx.play(&"hs_rumble", mouth, -2.0)
	at(T_OPEN, _open)
	for k in HOUNDS:
		at(T_OPEN + float(k) * OUT_EVERY, _release)
	at(last_out() + OUT_EVERY, _shut)
	at(hunt_end() - T_OPEN, _reopen)
	at(hunt_end(), func(): visitors.recall(RECALL))
	at(hunt_end() + RECALL, _shut)
	if not DominionParts.staged(self):
		return
	_door = Door.new()
	_door.fx = self
	_door.position = mouth
	_door.z_index = 5
	track(_door, ctx.ground)
	_glow = FxParts.ground_light(self, mouth, 1.8, RIM, 0.0)


## The walk grid the hounds keep to: the town's, by way of anyone in it.
func _grid() -> WalkGrid:
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and p.grid != null:
			return p.grid
	return null


## Whether hounds are still on the hunt.
func hunting() -> bool:
	return out > 0 and t < hunt_end() and not visitors.living().is_empty()


func kills() -> int:
	return visitors.kills


func slain() -> int:
	return visitors.slain


## The door opens: a danger the town sees while it stands open.
func _open() -> void:
	ctx.play(&"jg_rise", mouth, 0.0)
	if ctx.crowd != null:
		ctx.crowd.threats.register(mouth, 1.2, 0.6, float(HOUNDS) * OUT_EVERY + 1.0, 6.0, 9.0, &"beast")
	if not DominionParts.staged(self):
		return
	_door.open(t)
	_glow.tween_param("intensity", 0.0, 0.9, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	ctx.shake.add_trauma(0.18)
	FxParts.smoke(self, Iso.ground_to_screen(mouth), 14.0, 24.0, T_OPEN, Vector2(14, 36), Vector2(3, 6),
		Vector2(0.8, 1.4), Color(RIM, 0.6), PITCH)


## The door opens again for the recall.
func _reopen() -> void:
	ctx.play(&"jg_rise", mouth, -4.0)
	if not DominionParts.staged(self):
		return
	_door.open(t)
	_glow.tween_param("intensity", 0.0, 0.9, T_OPEN, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)


func _shut() -> void:
	ctx.play(&"jg_crumble", mouth, -6.0)
	if not DominionParts.staged(self):
		return
	_door.shut(t)
	_glow.tween_param("intensity", 0.9, 0.0, T_SHUT, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	FxParts.smoke(self, Iso.ground_to_screen(mouth), 10.0, 20.0, T_SHUT, Vector2(10, 28), Vector2(2, 5),
		Vector2(0.6, 1.1), Color(0, 0, 0, 0), PITCH)


## One hound comes through, a step out of the door toward the open, in black smoke and sparks.
func _release() -> void:
	var k := out
	out += 1
	var step := Vector2(0.35, 0.0).rotated(float(k) * TAU / float(HOUNDS) + 0.4)
	var spot := mouth + step
	var grid := _grid()
	if grid != null and not grid.walkable(spot):
		var w := grid.nearest_walkable(spot, 4)
		if w != Vector2.INF:
			spot = w
	var speed_mul := SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := visitors.summon(spot, Animal.Breed.HOUND, BLOWS, speed_mul, SEEK_R, BITE_R, BITE_EVERY)
	a.facing = 1 if k % 2 == 0 else -1
	a.self_modulate = COAT
	var eyes := Eyes.new()
	eyes.hound = a
	a.add_child(eyes)
	ctx.play(&"dr_roar", spot, -3.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(spot)
	FxParts.smoke(self, sp, 6.0, 30.0, 0.25, Vector2(16, 40), Vector2(2, 5), Vector2(0.5, 1.0), Color(RIM, 0.5), PITCH)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -6), 10, FxParts.EMBER_LIFE, Vector2(40, 140), Vector2(30, 120))
	_door.flare = 1.0
	ctx.shake.kick(Vector2(0, 0.8))
	# Faint embers off its coat as it runs: one slow emitter a hound, moved with it.
	var trail := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 5.0, HUNT + 8.0,
		{"radius": 3.0, "speed": Vector2(2, 8), "alt": Vector2(2, 8), "alt_speed": Vector2(8, 22), "life": Vector2(0.3, 0.6),
			"size": Vector2(1, 1)})
	trail.gravity = -20.0
	trail.drag = 1.0
	_trails[a] = trail


## A bite: the first one's outcry is the town's (a danger there, the alarm up), every one a shout.
func _on_bite(a: Animal, victim: Person, first: bool) -> void:
	ctx.play(&"cit_shout", victim.ground_pos, 0.0)
	if first and ctx.crowd != null:
		ctx.crowd.fright(victim.ground_pos, 2.0, 0.6, 3.0, 6.0, 8.0, &"bite", true)
		ctx.crowd.add_alarm(0.6)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(a.ground_pos) + Vector2(0, -8)
	FxParts.sparks(self, ctx.overhead, sp, 5, FxParts.EMBER_LIFE, Vector2(30, 90), Vector2(20, 80))


## Cut down: it bursts into black smoke and embers (its node is freed by the Visitors).
func _on_cut_down(a: Animal, at_ground: Vector2) -> void:
	_stop_trail(a)
	ctx.play(&"dr_roar", at_ground, -7.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(at_ground)
	FxParts.smoke(self, sp, 7.0, 40.0, 0.2, Vector2(18, 44), Vector2(3, 6), Vector2(0.6, 1.2), Color(RIM, 0.5), PITCH)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -6), 14, FxParts.EMBER_LIFE, Vector2(50, 160), Vector2(30, 140))


func _stop_trail(a: Animal) -> void:
	if _trails.has(a):
		var e: PixelParticles = _trails[a]
		if is_instance_valid(e):
			e.emitting = false
		_trails.erase(a)


func _fx_process(delta: float) -> void:
	visitors.step(delta)
	if not DominionParts.staged(self):
		return
	# The trails follow the hounds; a hound gone takes its trail with it.
	for a in _trails.keys():
		if not is_instance_valid(a) or not a.is_alive():
			_stop_trail(a)
			continue
		var e: PixelParticles = _trails[a]
		if is_instance_valid(e):
			e.position = Iso.ground_to_screen(a.ground_pos) + Vector2(0, -6)
	# The door breathes while it stands open.
	if _door != null and is_instance_valid(_door) and _door.is_open(t) and is_instance_valid(_glow):
		_glow.set_param("intensity", 0.75 + 0.2 * sin(t * 5.0))


## Over, or cut short (end_now()): the hounds go with it.
func _finish() -> void:
	if visitors != null:
		visitors.clear()
	super()


## The door: a low dark mouth lying in the ground, DOOR_W across when open, a red-orange rim that breathes, a glow
## from below and embers drifting up out of it. Drawn in the ground layer (ground units: a circle lies as an iso
## ellipse). open(now) tears it open over T_OPEN, shut(now) closes it over T_SHUT; `flare` is kicked when a hound
## comes through.
class Door extends Node2D:
	var fx: HoundGateFx
	var flare := 0.0
	var _opens := INF
	var _shuts := INF

	func open(now: float) -> void:
		_opens = now
		_shuts = INF
		visible = true

	func shut(now: float) -> void:
		_shuts = now

	func is_open(now: float) -> bool:
		return now >= _opens and now < _shuts + T_SHUT

	## 0..1 how far open.
	func span(now: float) -> float:
		if now < _opens:
			return 0.0
		var k := clampf((now - _opens) / T_OPEN, 0.0, 1.0)
		var p := 1.0 - pow(1.0 - k, 3.0)
		if now > _shuts:
			p *= 1.0 - clampf((now - _shuts) / T_SHUT, 0.0, 1.0)
		return p

	func _process(delta: float) -> void:
		flare = maxf(flare - delta * 3.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		var p := span(now)
		if p <= 0.01:
			return
		var w := DOOR_W * 0.5 * p
		var breathe := 0.5 + 0.5 * sin(now * 5.0)
		# The mouth: pitch dark, deepest in the middle; a fissure's rough edge in a few rays.
		draw_circle(Vector2.ZERO, w, Color(0.05, 0.03, 0.05, 0.92))
		draw_circle(Vector2.ZERO, w * 0.6, Color(0.0, 0.0, 0.0, 0.98))
		# A red glow from below, strongest at the rim.
		draw_arc(Vector2.ZERO, w * 0.8, 0.0, TAU, 40, Color(RIM, 0.18 + 0.12 * breathe + 0.3 * flare), w * 0.3)
		# The rim, breathing, and brighter as a hound comes through.
		draw_arc(Vector2.ZERO, w, 0.0, TAU, 48, Color(RIM, 0.75 + 0.25 * breathe), 0.05 + 0.03 * breathe + 0.05 * flare)
		draw_arc(Vector2.ZERO, w + 0.06, 0.0, TAU, 48, Color(RIM.r, RIM.g * 0.6, RIM.b, 0.25 + 0.2 * flare), 0.04)
		# Embers drifting up out of it (drawn, cheap): a dozen points at their own times.
		var tick := int(now * 20.0)
		for i in 12:
			var h := ArtKit.hash01(i, tick / 6)
			var h2 := ArtKit.hash01(i + 31, tick / 6)
			var ang := h * TAU
			var r := w * (0.2 + 0.7 * h2)
			var rise := fmod(now * (0.6 + 0.6 * h) + h2 * 3.0, 1.0)
			var at := Vector2(cos(ang), sin(ang)) * r + Vector2(-rise * 0.5, -rise * 0.5)  # up the screen is (-x, -y) in ground
			draw_rect(Rect2(at, Vector2(0.04, 0.04)), Color(EMBER, (1.0 - rise) * 0.9 * p))


## A hound's ember eyes: two pulsing points at the head, where the hound sheet puts the eye (SE view, or the NE view
## when it shows its back), mirrored with its facing. A child of the hound, over its coat.
class Eyes extends Node2D:
	var hound: Animal
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if hound == null or not is_instance_valid(hound) or not hound.is_alive():
			return
		var at := Vector2(4, -12) if hound.back else Vector2(2, -10)
		var pulse := 0.7 + 0.3 * sin(_t * 7.0)
		var c := Color(EMBER, pulse)
		var fx := float(hound.facing)
		draw_rect(Rect2(Vector2(at.x * fx, at.y), Vector2(1, 1)), c)
		draw_rect(Rect2(Vector2((at.x + 2.0) * fx, at.y), Vector2(1, 1)), c)
		draw_rect(Rect2(Vector2(at.x * fx - 1.0, at.y), Vector2(4, 1)), Color(EMBER, 0.25 * pulse))
