class_name EveryDoorFx
extends FxTimeline
## Every Door (Passage, Tier V): the god takes every door in town in hand at once. One click anywhere -- the click is
## only where the door of light opens in the sky -- and T_FLASH later, for SPAN, every door obeys the cast's mode (Q/E;
## extra.mode, SHUT when none). It is the town's own rule, read wherever someone goes in or out (Crowd.set_doors()):
##   SHUT  no door or gate opens. Nobody goes into a building and nobody inside one comes out -- shelter, tavern,
##         townhouse, temple, barracks -- whatever happens to it: struck, burning, the town evacuating. Whoever was on
##         the way to a shelter finds it shut and turns away. Nobody can climb the bell tower, so nobody can start the
##         bell (a climb under way stands where it is; a bell already rung rings on). And nobody leaves the town: no
##         gate lets anyone through (its crowd waits at it), nobody gets away by any road, nobody boards the boat.
##   OPEN  every door bursts open: everyone inside every building is thrown THROW out into the street in front of its
##         door, knocked down (ShelterManager.throw_out()), the bell's climber put out at the tower's foot; and for SPAN
##         no building takes anyone in -- shelter, home, barracks or tower. The ways out of town are not touched.
## When it ends, everything goes on as it would have. Those a mission keeps indoors for its own story are its own. The
## god touches nobody and breaks nothing: no danger comes of the cast. Quiet, but for the book entry's "alarm". Once in
## a descent (the book's cooldown). The cast locks the other slots until the doors obey.

const SPAN := 20.0
const T_FLASH := 0.6
const THROW := 1.2
const SHUT := &"shut"
const OPEN := &"open"
## The buildings whose doors show the rule (and every gate and the dock).
const DOOR_ROLES := [&"house", &"temple", &"barracks", &"tower"]
## The door in the sky: how high over the click (px), and its size (px).
const UP := 150.0
const SKY_W := 60.0
const SKY_H := 104.0
## Cold white-blue for SHUT, warm gold for OPEN.
const COLD := Color("cfe6ff")
const COLD_DEEP := Color(0.16, 0.24, 0.42)
const WARM := Color("ffd27a")
const WARM_HOT := Color("fff6d8")
const ICE_RAMP := [Color(0.1, 0.16, 0.32, 0.5), Color("3a68b0"), Color("8cc0f0"), Color("dff0ff"), Color("ffffff")]
const GOLD_RAMP := [Color(0.4, 0.25, 0.05, 0.5), Color("b07a20"), Color("ffc14a"), Color("ffe9a8"), Color("fffdf0")]
const GOLD_LIFE := [Color("fffdf0"), Color("ffe9a8"), Color("ffc14a"), Color(0.75, 0.45, 0.12, 0.5)]
## Bursts drawn for the thrown-out at most (the rule takes them all; the eye needs only these).
const BURSTS := 40

var mode := SHUT
## Whether the rule holds now, and who was thrown out of doors (OPEN).
var holding := false
var thrown: Array[Person] = []

var _doors: Doors


func _build() -> void:
	mode = OPEN if String(extra.get("mode", "shut")) == "open" else SHUT
	duration = T_FLASH + SPAN + 1.0
	busy = T_FLASH
	at(T_FLASH, _obey)
	at(T_FLASH + SPAN, _lift)
	ctx.play(&"q_everydoor", origin, 0.0)
	if not DominionParts.staged(self):
		return
	var col := COLD if mode == SHUT else WARM
	var sky := SkyDoor.new()
	sky.fx = self
	sky.position = Iso.ground_to_screen(origin) + Vector2(0, -UP)
	sky.z_index = 7
	track(sky, ctx.overhead)
	var glow := FxParts.bloom(self, sky.position, SKY_H * 0.9, col, 0.0, 1.2)
	glow.tween_param("intensity", 0.0, 1.1, T_FLASH, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	glow.tween_param("intensity", 1.1, 0.0, 1.6, T_FLASH + 0.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = T_FLASH + 2.3
	DominionParts.ground_sigil(self, origin, 3.0, col, T_FLASH, 1.0)
	_doors = Doors.new()
	_doors.fx = self
	_doors.spots = _door_spots()
	_doors.z_index = 6
	track(_doors, ctx.overhead)


## The doors obey: the rule is laid on the town, and with OPEN everyone indoors is thrown out.
func _obey() -> void:
	holding = true
	if ctx.crowd != null:
		ctx.crowd.set_doors(mode, SPAN)
		if mode == OPEN:
			if ctx.crowd.shelters != null:
				thrown = ctx.crowd.shelters.throw_out(THROW)
			var bell := ctx.crowd.bell
			if bell != null and bell.state == BellNetwork.State.CLIMBING and is_instance_valid(bell.keeper) and bell.keeper.is_alive():
				bell.keeper.knock_down()  # put out of the tower at its foot (BellNetwork starts the climb over)
				thrown.append(bell.keeper)
	if ctx.rules != null:
		ctx.rules.banner.emit("EVERY DOOR IS SHUT" if mode == SHUT else "EVERY DOOR BURSTS OPEN")
	if mode == SHUT:
		ctx.play(&"jg_slam", origin, -3.0)
	else:
		ctx.play(&"jg_rise", origin, -8.0)
	if not DominionParts.staged(self):
		return
	var col := COLD if mode == SHUT else WARM
	ctx.flash.call(Color(col, 0.22), 0.35)
	ctx.shake.add_trauma(0.25 if mode == SHUT else 0.35)
	var sp := Iso.ground_to_screen(origin)
	# The light pours down from the door in the sky onto the click, and goes out over the town.
	var shaft := FxParts.beam(self, ctx.overhead, sp, 34.0, UP - SKY_H * 0.5, ICE_RAMP if mode == SHUT else GOLD_RAMP)
	shaft.z_index = 5
	shaft.tween_param("intensity", 1.4, 0.0, 1.0, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	shaft.life = 1.05
	DominionParts.pulse(self, origin, 4.0, col, 0.9, 1.2)
	var wave := FxParts.shockwave(self, origin, 9.0, ICE_RAMP if mode == SHUT else GOLD_RAMP)
	wave.set_param("thickness", 0.05)
	wave.tween_param("progress", 0.05, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.35, 0.5)
	wave.life = 0.9
	if mode == OPEN:
		var rays := FxParts.screen_rays(self, sp + Vector2(0, -UP), SKY_H * 1.2, WARM, 40.0, 1.0)
		rays.tween_param("intensity", 1.0, 0.0, 1.2, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		rays.life = 1.25
		for i in mini(thrown.size(), BURSTS):
			var p := thrown[i]
			if not is_instance_valid(p):
				continue
			var at_px := Iso.ground_to_screen(p.ground_pos)
			FxParts.sparks(self, ctx.overhead, at_px + Vector2(0, -6), 7, GOLD_LIFE, Vector2(30, 110), Vector2(20, 90))
			DominionParts.motes(self, p.ground_pos, GOLD_LIFE, 4)


## The span is over: the doors are the town's again.
func _lift() -> void:
	holding = false
	if ctx.crowd != null and ctx.crowd.doors() == mode:
		ctx.crowd.set_doors(&"", 0.0)
	if DominionParts.staged(self):
		ctx.play(&"jg_rise", origin, -12.0)


## Where each door shows, in screen pixels, with its size: a building's door on the face it opens to the street (a
## face the eye sees first), every gate across its mouth, the dock at its pier.
func _door_spots() -> Array:
	var out: Array = []
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed:
			continue
		if s.kind == Structure.Kind.GATE or s.role == &"gate" or s.role == &"dock":
			out.append([Iso.ground_to_screen(s.center()), 2.2])
			continue
		if not (s.role in DOOR_ROLES):
			continue
		out.append([Iso.ground_to_screen(door_of(s, grid)), 1.0 if s.role == &"house" else 1.5])
	return out


## Where building `s`'s door is, on the ground: the middle of the first face (front, right, back, left -- the faces the
## eye sees first) that opens onto walkable ground on `grid`; the front face without a grid.
static func door_of(s: Structure, grid: WalkGrid) -> Vector2:
	var half := s.footprint.size * 0.5
	var c := s.center()
	for off: Vector2 in [Vector2(0.0, half.y), Vector2(half.x, 0.0), Vector2(0.0, -half.y), Vector2(-half.x, 0.0)]:
		if grid == null or grid.walkable(c + off + off.normalized() * 0.3):
			return c + off
	return c + Vector2(0.0, half.y)


## How much of the doors' light shows: in at the flash, out as the span ends.
func shown() -> float:
	return clampf(minf((t - T_FLASH) / 0.25, (T_FLASH + SPAN + 0.8 - t) / 0.8), 0.0, 1.0)


## The flare every doorway gives at once as the rule lands, and a smaller one as it lifts.
func flare() -> float:
	var on := clampf(1.0 - (t - T_FLASH) / 0.6, 0.0, 1.0) if t >= T_FLASH else 0.0
	var off := clampf(1.0 - absf(t - T_FLASH - SPAN) / 0.4, 0.0, 1.0) * 0.6
	return maxf(on, off)


## Every door in town at once: SHUT, a closed slab of cold light with a bar across it; OPEN, a dark frame round a bright
## gap of gold that spills on the street. Breathing, all flaring together as the rule lands.
class Doors extends Node2D:
	var fx: EveryDoorFx
	## [screen position (the door's foot), size]
	var spots: Array = []

	func _process(_delta: float) -> void:
		if fx.t > T_FLASH + SPAN + 0.9:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		var fl := fx.flare()
		if a <= 0.0 and fl <= 0.0:
			return
		var shut := fx.mode == SHUT
		for sp: Array in spots:
			var b: Vector2 = sp[0]
			var k: float = sp[1]
			var w := 6.0 * k
			var h := 12.0 * k
			var breathe := 0.85 + 0.15 * sin(fx.t * 2.2 + b.x * 0.05)
			var door := Rect2(b.x - w * 0.5, b.y - h, w, h)
			if shut:
				draw_rect(door.grow(2.0 * k), Color(COLD, 0.14 * a * breathe))
				draw_rect(door, Color(COLD_DEEP, 0.8 * a))
				draw_rect(door, Color(COLD, 0.95 * a), false, 1.0)
				draw_rect(Rect2(b.x - w * 0.85, b.y - h * 0.58, w * 1.7, maxf(1.5 * k, 1.0)), Color(1, 1, 1, a * breathe))
			else:
				_spill(b, w * 1.6, Color(WARM, 0.22 * a * breathe))
				draw_rect(door.grow(1.5 * k), Color(WARM, 0.16 * a * breathe))
				draw_rect(door, Color(0.16, 0.08, 0.02, 0.75 * a), false, 1.0)
				draw_rect(Rect2(b.x - w * 0.3, b.y - h, w * 0.6, h), Color(WARM_HOT, 0.95 * a * breathe))
			if fl > 0.0:
				draw_rect(door.grow(3.0 * k * fl), Color(COLD if shut else WARM, 0.5 * fl))
				draw_rect(door, Color(1, 1, 1, 0.8 * fl))

	## Light on the street in front of an open door: a flat ellipse.
	func _spill(at_px: Vector2, r: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in 16:
			var ang := TAU * float(i) / 16.0
			pts.append(at_px + Vector2(cos(ang) * r, sin(ang) * r * 0.5))
		draw_colored_polygon(pts, col)


## The door in the sky: an arched frame of light whose leaves swing open over T_FLASH. SHUT: they open part way and
## slam, and a bar falls across; OPEN: they open wide on a blaze of gold. It fades as the rule settles.
class SkyDoor extends Node2D:
	var fx: EveryDoorFx

	func _process(_delta: float) -> void:
		if fx.t > T_FLASH + 2.6:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t := fx.t
		var a := clampf(minf(t / 0.15, (T_FLASH + 2.5 - t) / 1.2), 0.0, 1.0)
		if a <= 0.0:
			return
		var shut := fx.mode == SHUT
		var opened: float
		if shut:
			opened = fx.curve([[0.0, 0.0], [T_FLASH * 0.6, 0.75], [T_FLASH, 0.0]])
		else:
			opened = fx.curve([[0.0, 0.0], [T_FLASH, 1.0]])
		var col := COLD if shut else WARM
		var hot := Color(1, 1, 1) if shut else WARM_HOT
		var w := SKY_W
		var h := SKY_H
		draw_colored_polygon(_arch(w * 1.3, h * 1.15, Vector2(0, h * 0.075)), Color(col, 0.16 * a))
		# The light beyond the door, brighter the wider it stands.
		draw_colored_polygon(_arch(w, h), Color(hot, a * (0.25 + 0.75 * opened)))
		# The leaves, hinged at the jambs: each narrows as it swings in.
		var spring := h - w * 0.5
		var leaf := w * 0.5 * (1.0 - opened)
		var panel := Color(COLD_DEEP, 0.92 * a) if shut else Color(0.3, 0.16, 0.04, 0.9 * a)
		if leaf > 0.5:
			draw_rect(Rect2(-w * 0.5, -spring, leaf, spring), panel)
			draw_rect(Rect2(w * 0.5 - leaf, -spring, leaf, spring), panel)
			draw_rect(Rect2(-w * 0.5, -spring, leaf, spring), Color(col, 0.8 * a), false, 1.0)
			draw_rect(Rect2(w * 0.5 - leaf, -spring, leaf, spring), Color(col, 0.8 * a), false, 1.0)
		draw_polyline(_arch(w, h), Color(col, a), 2.5)
		if shut and t >= T_FLASH:
			draw_rect(Rect2(-w * 0.62, -spring * 0.55, w * 1.24, 5.0), Color(1, 1, 1, a))
			draw_rect(Rect2(-w * 0.62, -spring * 0.55, w * 1.24, 5.0), Color(col, a), false, 1.0)

	## An arched doorway `w` wide and `h` tall standing on (0, 0) (+ `shift`): its outline, open at the sill.
	func _arch(w: float, h: float, shift := Vector2.ZERO) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var r := w * 0.5
		pts.append(Vector2(-r, 0) + shift)
		for i in 17:
			var ang := PI + PI * float(i) / 16.0
			pts.append(Vector2(cos(ang) * r, -(h - r) + sin(ang) * r) + shift)
		pts.append(Vector2(r, 0) + shift)
		return pts
