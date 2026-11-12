class_name HoundGateFx
extends FxTimeline
## Hound Gate (Passage, Tier II): a Hellgate climbs out of the ground where the click lands -- or where an open passage
## (EnemyField.through) carries it. The paving cracks red and the gate of black stone rises out of it over T_RISE; it
## stands a breath, then its two iron doors swing slowly open on the fire behind (DOORS), and at T_OPEN, the doors wide,
## HOUNDS hellhounds run out of its foot, one every OUT_EVERY. Its work done, the doors close behind the last (T_SHUT)
## and the gate sinks back into the ground (SINK): the hounds are left loose in the town. They are Visitors: each hunts
## whoever is nearest, citizen or soldier, out in the open within SEEK_R, runs at SPEED, and bites (within BITE_R, every
## BITE_EVERY) -- a citizen falls to one bite, a soldier to two (damage kind frenzy). They fear nothing: no danger,
## strike or fright turns them, and a blow does not make them flinch: a hound bites through it. The guard cuts them
## down: a soldier beside a hound lands a blow every Visitors.GUARD_SWING and at BLOWS blows it is gone in black smoke.
## So a lone soldier falls to a hound before his blows are done; two bring one down and lose one of their own; three
## kill it before it takes a second. Soldiers at their post within SEEK_R are drawn to the fight. The doors stand open
## while the hounds come (a danger the town sees, kind beast). HUNT after the last comes out, the hounds still on their
## feet burn away where they stand, back to the other side. Loud (PowerBook.REACH): the first bite is the first kill,
## OUT_EVERY after the doors open.
## Levels (PowerBook "houndgate"): HOUNDS, HUNT and BLOWS grow; level 1 is the numbers below. Level 5's twist, Quarry:
## while they hunt, a click on a person (the nearest living one out in the open within QUARRY_PICK of it) marks them,
## and every hound runs for that one -- any distance, by the streets (Visitors.mark()) -- until they fall or go inside,
## then hunts as before. A new mark replaces the old.

## The gate climbs out of the ground over T_RISE, stands a moment, and its doors take DOORS to open: wide at T_OPEN.
const T_RISE := 1.2
const DOORS := 1.2
const T_OPEN := 2.6
const HOUNDS := 4
const OUT_EVERY := 0.4
const HUNT := 30.0
const BLOWS := 4
const SPEED := 2.4
const SEEK_R := 8.0
const BITE_R := 0.5
const BITE_EVERY := 1.0
## Behind the last hound the doors close over T_SHUT, and the gate sinks over SINK.
const T_SHUT := 0.6
const SINK := 1.2
## At the hunt's end the hounds burn away over BURN.
const BURN := 0.5
## Quarry: how near the click a person must stand to be marked.
const QUARRY_PICK := 0.8
const MARK := Color(1.0, 0.16, 0.08)
## How the gate shows: its PixelLab sheet (the doors opening, frame 0 shut to the last wide on the fire), its cell, its
## foot in the cell, how large it is drawn, and the other side's colours.
const SHEET := "res://assets/pixellab/fx/hellgate.png"
const CELL := 96
const FRAMES := 9
const FOOT := Vector2(50, 88)
const SCALE := 0.85
## The hounds come out this far in front of the gate's foot (toward the viewer), spread across its doorway.
const OUT_AHEAD := 0.45
const RIM := Color(1.0, 0.42, 0.12)
const EMBER := Color(1.0, 0.45, 0.1)
const COAT := Color(0.22, 0.18, 0.24)
const PITCH := [Color("1a1418"), Color("16121a"), Color("120f14"), Color(0.07, 0.06, 0.08, 0.8), Color(0.05, 0.04, 0.06, 0.4)]
const ROCK := [Color("3a2a2a"), Color("2a1e20"), Color("1a1214"), Color(0.08, 0.05, 0.05, 0.6)]
## Dust thrown up by the stone as it comes and goes: low and pale, so the gate shows through it.
const DUST := [Color(0.62, 0.55, 0.48, 0.55), Color(0.5, 0.44, 0.38, 0.4), Color(0.4, 0.35, 0.3, 0.25), Color(0.3, 0.26, 0.22, 0.0)]

## The door, and the hounds: how many have come out.
var mouth := Vector2.ZERO
var visitors: Visitors
## The hounds heard while they hunt, and their bites.
var voices := VisitorVoices.new()
var out := 0

## This cast's numbers at its ability level (HOUNDS, HUNT and BLOWS at level 1).
var lv_hounds := HOUNDS
var lv_hunt := HUNT
var lv_blows := BLOWS
## Quarry (level 5): whether this cast has it, the one marked last (null when none), and how many marks were made.
var quarry: Person
var marks := 0
var _quarry_twist := false
var _mark_node: QuarryMark

var _gate: Gate
var _glow: QuadFx
var _trails := {}


## When the last hound comes out, and when the hunt ends.
func last_out() -> float:
	return T_OPEN + float(lv_hounds - 1) * OUT_EVERY


func hunt_end() -> float:
	return T_OPEN + float(lv_hounds) * OUT_EVERY + lv_hunt


## When the doors close, and when the gate is back under the ground: soon after the last hound is out.
func shut_at() -> float:
	return last_out() + OUT_EVERY


func gone() -> float:
	return shut_at() + T_SHUT + SINK


func _build() -> void:
	lv_hounds = int(PowerBook.stat(extra, "houndgate", "HOUNDS", HOUNDS))
	lv_hunt = float(PowerBook.stat(extra, "houndgate", "HUNT", HUNT))
	lv_blows = int(PowerBook.stat(extra, "houndgate", "BLOWS", BLOWS))
	_quarry_twist = PowerBook.twist_at(extra, "houndgate")
	mouth = ctx.field.through(origin)
	duration = hunt_end() + BURN + 0.1
	busy = T_OPEN
	var parent: Node2D = ctx.world if ctx.world != null else ctx.overhead
	visitors = Visitors.new().setup(ctx.field, ctx.crowd, _grid(), parent)
	visitors.bitten.connect(_on_bite)
	visitors.cut_down.connect(_on_cut_down)
	ctx.play(&"hg_rise", mouth, -2.0)
	at(T_RISE, _risen)
	at(T_OPEN - DOORS, func(): ctx.play(&"hg_doors", mouth, 0.0))
	at(T_OPEN, _open)
	for k in lv_hounds:
		at(T_OPEN + float(k) * OUT_EVERY, _release)
	at(shut_at(), _shut)
	at(shut_at() + T_SHUT, _sink)
	at(hunt_end(), _burn_away)
	if not DominionParts.staged(self):
		return
	_gate = Gate.new()
	_gate.fx = self
	_gate.position = Iso.ground_to_screen(mouth)
	track(_gate, ctx.world if ctx.world != null else ctx.overhead)
	_glow = FxParts.ground_light(self, mouth, 1.8, RIM, 0.0)
	_glow.tween_param("intensity", 0.0, 0.6, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	# The paving tears red under it and the stone comes up through it: a shaking ground, rock thrown, dust.
	var sp := Iso.ground_to_screen(mouth)
	ctx.shake.add_trauma(0.35)
	FxParts.debris(self, sp, 10, 7.0, Vector2(40, 140), ROCK, Vector2(1.5, 3.0), true)
	FxParts.smoke(self, sp, 26.0, 14.0, T_RISE, Vector2(4, 12), Vector2(2, 4), Vector2(0.5, 0.9), Color(RIM, 0.25), DUST)
	var heat := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 30.0, T_RISE,
		{"radius": 22.0, "speed": Vector2(4, 14), "alt": Vector2(0, 6), "alt_speed": Vector2(30, 80), "life": Vector2(0.4, 0.9),
			"size": Vector2(1, 2)})
	heat.gravity = -30.0


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


## Quarry: true at level 5 while the hounds hunt.
func can_follow_up() -> bool:
	return _quarry_twist and not finished and hunting()


## Quarry: the nearest living person out in the open within QUARRY_PICK of the click is marked, and every hound goes for
## them (replacing any earlier mark). False -- the click not taken -- when nobody stands there.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var best: Person = null
	var best_d := INF
	for e in ctx.field.in_radius(at_pos, QUARRY_PICK):
		var p := e as Person
		if p == null or p.inside or not p.is_alive():
			continue
		var d := p.ground_pos.distance_squared_to(at_pos)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return false
	quarry = best
	marks += 1
	visitors.mark(best)
	ctx.play(&"dr_roar", best.ground_pos, -6.0)
	if DominionParts.staged(self):
		if _mark_node != null and is_instance_valid(_mark_node):
			_mark_node.queue_free()
		_mark_node = QuarryMark.new()
		_mark_node.fx = self
		_mark_node.prey = best
		_mark_node.position = Iso.ground_to_screen(best.ground_pos)
		track(_mark_node, ctx.overhead)
	return true


## Quarry's preview: the reach about the click a person is picked from.
func follow_up_area() -> Dictionary:
	return {"shape": "circle", "r": QUARRY_PICK}


func slain() -> int:
	return visitors.slain


## The gate is up: it settles with a thud and a ring of dust, and its doors begin to part (the gate draws them).
func _risen() -> void:
	ctx.play(&"hg_settle", mouth, -6.0)
	if not DominionParts.staged(self):
		return
	ctx.shake.kick(Vector2(0, 2.5))
	var sp := Iso.ground_to_screen(mouth)
	var ring := FxParts.shockwave(self, mouth, 1.6, FxParts.FIRE)
	ring.set_param("thickness", 0.08)
	ring.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.35, 0.0, 0.25, 0.15)
	ring.life = 0.5
	FxParts.smoke(self, sp, 30.0, 30.0, 0.25, Vector2(4, 10), Vector2(2, 4), Vector2(0.4, 0.8), Color(0, 0, 0, 0), DUST)


## The doors are wide: the fire behind them lights the street, and the town sees a danger while they stand open.
func _open() -> void:
	if ctx.crowd != null:
		ctx.crowd.threats.register(mouth, 1.2, 0.6, float(lv_hounds) * OUT_EVERY + 1.0, 6.0, 9.0, &"beast")
	if not DominionParts.staged(self):
		return
	_glow.tween_param("intensity", 0.6, 1.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	ctx.shake.add_trauma(0.2)
	var sp := Iso.ground_to_screen(mouth) + Vector2(0, -CELL * SCALE * 0.35)
	var blast := FxParts.bloom(self, sp, 60.0, RIM, 1.0, 0.8)
	blast.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	blast.life = 0.65
	FxParts.sparks(self, ctx.overhead, sp, 22, FxParts.EMBER_LIFE, Vector2(60, 200), Vector2(40, 160))


## The hunt is over: every hound still on its feet burns away where it stands, back to the other side.
func _burn_away() -> void:
	var left := visitors.living()
	for a in left:
		_stop_trail(a)
		if DominionParts.staged(self):
			var sp := Iso.ground_to_screen(a.ground_pos)
			FxParts.smoke(self, sp, 6.0, 30.0, BURN, Vector2(16, 40), Vector2(2, 5), Vector2(0.5, 1.0), Color(RIM, 0.6), PITCH)
			FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -6), 12, FxParts.EMBER_LIFE, Vector2(30, 120), Vector2(40, 140))
	if not left.is_empty():
		ctx.play(&"hound_burn", left[0].ground_pos, -9.0)
	visitors.clear()


## The doors close behind the last hound (the gate draws them shut).
func _shut() -> void:
	ctx.play(&"hg_shut", mouth, -6.0)
	if not DominionParts.staged(self):
		return
	_glow.tween_param("intensity", 1.0, 0.3, T_SHUT, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)


## The gate goes back under the ground it came from.
func _sink() -> void:
	ctx.play(&"hg_sink", mouth, 0.0)
	if not DominionParts.staged(self):
		return
	_glow.tween_param("intensity", 0.3, 0.0, SINK, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	ctx.shake.add_trauma(0.25)
	var sp := Iso.ground_to_screen(mouth)
	FxParts.smoke(self, sp, 26.0, 14.0, SINK, Vector2(4, 12), Vector2(2, 4), Vector2(0.5, 0.9), Color(0, 0, 0, 0), DUST)
	FxParts.debris(self, sp, 8, 6.0, Vector2(30, 110), ROCK, Vector2(1.5, 3.0), true)


## One hound comes through, a step out of the door toward the open, in black smoke and sparks.
func _release() -> void:
	var k := out
	out += 1
	# Out of the doorway toward the viewer (ground (+1, +1) is down the screen), spread across it.
	var across := Vector2(0.7071, -0.7071) * (float(k) - float(lv_hounds - 1) * 0.5) * 0.22
	var spot := mouth + Vector2(OUT_AHEAD, OUT_AHEAD) * 0.7071 + across
	var grid := _grid()
	if grid != null and not grid.walkable(spot):
		var w := grid.nearest_walkable(spot, 4)
		if w != Vector2.INF:
			spot = w
	var speed_mul := SPEED / (Animal.DOG_SPEED * Animal.RUN)
	var a := visitors.summon(spot, Animal.Breed.HELLHOUND, lv_blows, speed_mul, SEEK_R, BITE_R, BITE_EVERY, false)
	a.facing = 1 if k % 2 == 0 else -1
	if Animal.sheet(Animal.Breed.HELLHOUND).is_empty():
		# No painted sheet (not imported): the drawn dog shape, darkened, with ember eyes laid over it.
		a.self_modulate = COAT
		var eyes := Eyes.new()
		eyes.hound = a
		a.add_child(eyes)
	ctx.play(&"hound_howl", spot, -3.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(spot)
	FxParts.smoke(self, sp, 5.0, 18.0, 0.2, Vector2(10, 26), Vector2(2, 4), Vector2(0.35, 0.7), Color(RIM, 0.5), PITCH)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -6), 10, FxParts.EMBER_LIFE, Vector2(40, 140), Vector2(30, 120))
	_gate.flare = 1.0
	ctx.shake.kick(Vector2(0, 0.8))
	# Faint embers off its coat as it runs: one slow emitter a hound, moved with it.
	var trail := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE, 5.0, lv_hunt + 8.0,
		{"radius": 3.0, "speed": Vector2(2, 8), "alt": Vector2(2, 8), "alt_speed": Vector2(8, 22), "life": Vector2(0.3, 0.6),
			"size": Vector2(1, 1)})
	trail.gravity = -20.0
	trail.drag = 1.0
	_trails[a] = trail


## A bite: the first one's outcry is the town's (a danger there, the alarm up), every one a shout.
func _on_bite(a: Animal, victim: Person, first: bool) -> void:
	voices.bite(a, ctx.play)
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
	ctx.play(&"hound_die", at_ground, -7.0)
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
	voices.step(delta, visitors.living(), ctx.play)
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
	# The fire breathes while the doors stand open.
	if _gate != null and is_instance_valid(_gate) and _gate.doors(t) >= 0.99 and is_instance_valid(_glow):
		_glow.set_param("intensity", 0.8 + 0.2 * sin(t * 5.0))


## Over, or cut short (end_now()): the hounds go with it.
func _finish() -> void:
	if visitors != null:
		visitors.clear()
	super()


## The Hellgate: the PixelLab sheet drawn standing on the mouth, its foot on the ground point, in the world layer so
## the town sorts round it. It climbs out of the ground over T_RISE (the top of the sprite shows first, cut off at the
## ground line, shaking as it comes), its doors open over DOORS to T_OPEN and close over T_SHUT behind the last hound
## (the sheet's frames forward and back), the fire behind them flickers while they stand wide, it flares (`flare`) as
## a hound comes through, and it sinks back the way it came. Without the sheet (not imported) it draws nothing: the light, smoke and
## sparks still show where it stands.
class Gate extends Node2D:
	var fx: HoundGateFx
	var flare := 0.0
	var _tex: Texture2D

	func _ready() -> void:
		if ResourceLoader.exists(SHEET):
			_tex = load(SHEET)

	## 0..1 how far out of the ground.
	func risen(now: float) -> float:
		var up := clampf(now / T_RISE, 0.0, 1.0)
		var down := clampf((now - (fx.gone() - SINK)) / SINK, 0.0, 1.0)
		return ease_out(up) * (1.0 - ease_in(down))

	## 0..1 how far open the doors are.
	func doors(now: float) -> float:
		if now < fx.shut_at():
			return clampf((now - (T_OPEN - DOORS)) / DOORS, 0.0, 1.0)
		return 1.0 - clampf((now - fx.shut_at()) / T_SHUT, 0.0, 1.0)

	static func ease_out(k: float) -> float:
		return 1.0 - pow(1.0 - k, 3.0)

	static func ease_in(k: float) -> float:
		return k * k * k

	func _process(delta: float) -> void:
		flare = maxf(flare - delta * 3.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		if _tex == null:
			return
		var now := fx.t
		var up := risen(now)
		if up <= 0.0:
			if now > fx.gone():
				queue_free()  # sunk for good
			return
		var open := doors(now)
		var frame := int(round(open * float(FRAMES - 1)))
		if open >= 0.99:
			# The fire behind the doors flickers: the last three frames, back and forth.
			frame = FRAMES - 1 - [0, 1, 2, 1][int(now * 8.0) % 4]
		var shown := float(CELL) * up  # rows of the sprite above the ground, from its top
		var shake := Vector2(sin(now * 70.0), 0.0) * (1.0 - up) * 1.5 if up < 1.0 else Vector2.ZERO
		var tint := Color(1.0 + 0.6 * flare, 1.0 + 0.3 * flare, 1.0 + 0.2 * flare)
		draw_set_transform(shake, 0.0, Vector2(SCALE, SCALE))
		# Pushed down by what is still under the ground, and cut off at its own foot line: only the top `shown` rows.
		draw_texture_rect_region(_tex, Rect2(-FOOT.x, -FOOT.y + (float(CELL) - shown), CELL, shown),
			Rect2(frame * CELL, 0, CELL, shown), tint)
		draw_set_transform(Vector2.ZERO)


## Quarry's mark: a red ring at the marked one's feet, pulsing, and a red hook over their head, following them; gone
## when the mark is (they fell, went inside, or another was marked).
class QuarryMark extends Node2D:
	var fx: HoundGateFx
	var prey: Person
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(fx) or fx.visitors == null or fx.visitors.marked() != prey:
			queue_free()
			return
		position = Iso.ground_to_screen(prey.ground_pos)
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.65 + 0.35 * sin(_t * 6.0)
		var ring := PackedVector2Array()
		for i in 17:
			var a := TAU * float(i) / 16.0
			ring.append(Iso.ground_to_screen(Vector2(cos(a), sin(a)) * (0.35 + 0.04 * pulse)) - Iso.ground_to_screen(Vector2.ZERO))
		draw_polyline(ring, Color(MARK, 0.85 * pulse), 1.0)
		# The hook over the head: a small downward chevron.
		var top := Vector2(0, -26 - 2.0 * pulse)
		var c := Color(MARK, pulse)
		draw_line(top + Vector2(-3, -3), top, c, 1.0)
		draw_line(top + Vector2(3, -3), top, c, 1.0)
		draw_rect(Rect2(top + Vector2(-0.5, -7), Vector2(1, 3)), c)


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
