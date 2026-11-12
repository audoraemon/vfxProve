class_name HeavensDoorFx
extends FxTimeline
## Heaven's Door (Passage, Tier V): a great door falls out of the sky, crushes where it lands, and then opens and draws in
## everyone and everything in the half circle before it. Aimed by a drag: the press is where it lands (or where an open
## passage, EnemyField.through, carries it), the drag the way it faces (extra "dir"); a click with no drag faces it
## down-right on screen, as the dragon does. It faces one of eight ways only (DIRS), 45 degrees apart on the ground: the
## drag turns to the nearest of them (facing_of), and the aim's half circle turns with it in the same steps. In this
## town's 2:1 iso the eight ground ways are exactly the eight ways the door is seen on screen (Iso.ground_to_screen):
## ground (1, 1) faces screen-down (the sheet's "south", its front to the viewer), (1, 0) screen down-right, (1, -1)
## screen-right ("east", edge on), (0, -1) up-right, (-1, -1) screen-up ("north", seen from behind), (-1, 0) up-left,
## (-1, 1) screen-left ("west") and (0, 1) down-left (ROW_OF).
##
## The fall: for T_FALL a shaft of light stands on the place and a shadow grows under a door of white marble and gold
## with wings over its arch, half again to twice as tall as a house, that comes down out of the sky shut and lands
## upright, facing the drag, runes cut in its stones. It is a PixelLab sheet (SHEET; object
## 8653883e-60ca-4576-8c76-15279b87004d, drawn in the style of b727b4fc-b1f8-46a5-bdca-8eb47a36bb48, 25 + 24
## generations): eight rows, one for each way it is seen, nine frames each from shut to wide open on the light. The
## rows "west" and "south-west" are the rows "east" and "south-east" mirrored. Three rows came out of PixelLab with
## broken last frames and hold their last good open frame to the end (the json's "frame_map", baked into the sheet):
## "south" frames 6-8 are its frame 6, "east" and "west" 5-8 are their frame 5, "north" 7-8 its frame 7; frame 8 is
## still "wide open" in every row. The sheet's "south-east" row shows its front turned screen down-LEFT (its base runs
## down to the right, as the "north-east" back view's does), so the two front diagonals are drawn crosswise: a door
## facing screen down-right draws the "south-west" row, one facing down-left the "south-east" row (ROW_OF; the test
## reads the slope off the sheet).
##
## The landing (at T_FALL, its first kill: PowerBook.IMPACT): everyone out in the open within CRUSH_R is crushed (kind
## stone; those inside a building are the building's to lose) and the town's dogs and cats there with them; everyone
## within SHOCK_R is thrown away from it -- KNOCK_NEAR at the crush's edge, easing to KNOCK_FAR at SHOCK_R -- and down;
## every building and the loose goods within SHOCK_R take LAND_DAMAGE (stone: nothing catches, nothing burns when it
## falls). The ground shakes, a ring of dust and broken paving goes out, and the town sees and hears it far off (loud:
## PowerBook.REACH).
##
## The opening: over T_OPEN its two leaves swing slowly open on a blinding white-gold light (the sheet's frames, shut to
## wide: frame_at()), and stand wide through the pull, the light breathing in them. Nothing is drawn in before it is
## fully open.
##
## The pull, SPAN from fully open: everything in front of the door -- within PULL_R of it and within HALF_ANGLE either
## side of its facing (the half circle before it) -- is drawn straight toward the doorway, hardest at the door and
## falling off evenly with distance: PULL_NEAR a second at the door, PULL_FAR at PULL_R (EnemyField.cone_speed). It is
## a carry, not a hold: the drawn keep their own minds and their own feet, and are carried as well; a wall or a
## building holds them where they stand against it (EnemyField.carry_toward), until it falls. Everyone it draws is
## terrified (a panic, looked for every TICK, soldiers too) and runs from the door: far out the pull is weaker than a run
## and a runner gets away; near the door it is stronger than anyone can run, and nobody does. There is no luck in it:
## who is taken follows from where they stand and how fast they go. Drawn in with them: the town's dogs and cats, the
## Visitors walking the town (Crowd.visitors: the hellhounds), the loose goods (barrels, crates, carts, logs, piles:
## GOODS), and the small things built there (a market stall, a stack of crates, a tree; never a wall's, a gate's or a
## tower's: SkyliftFx.TAKES, KEEP_ROLES), each torn loose once LOOSEN of pull has worked on it (cone_speed summed
## over the time it stands in the pull: at the door in under two seconds, at the rim in about seven) and drawn in whole.
## Whoever, and whatever, comes within DOOR_R of the doorway on its open side is gone through it: a person is counted
## among the dead (kind gone), with no body and no cry -- the figure pales into white-gold light at the threshold; an
## animal or a good is taken out of the town. Every bigger building in front (not one that can be walked over) takes
## STORM_DAMAGE a second at PULL_R, rising evenly to STORM_NEAR times that at the door (kind wind: no fire), so the
## nearest crack and fall first and the half circle is torn down over the span; what falls is drawn in as dust and
## splinters. Behind the door -- the other half -- nothing is drawn: the safe side. Nothing is drawn while time stands
## still (Crowd.is_frozen()).
##
## The end: the leaves slam shut over T_SHUT with a boom (the frames back to shut), and the door rises back into the sky
## over T_RISE, shut, and is gone.
## Once in a descent (the book's cooldown).

const T_FALL := 1.2
const CRUSH_R := 3.0
const SHOCK_R := 7.0
const LAND_DAMAGE := 40.0
## Thrown at the edge of the crush, and at SHOCK_R (ground units a second at the start of the slide).
const KNOCK_NEAR := 5.0
const KNOCK_FAR := 3.0
const T_OPEN := 3.0
const SPAN := 12.0
const PULL_R := 16.0
## Either side of its facing: a half circle.
const HALF_ANGLE := PI * 0.5
const PULL_NEAR := 3.0
const PULL_FAR := 0.6
const DOOR_R := 1.5
## Wind damage a second to a bigger building at PULL_R, and how many times that at the door (evenly between).
const STORM_DAMAGE := 6.0
const STORM_NEAR := 2.0
## A small structure is torn loose once this much pull (ground units: cone_speed over the seconds) has worked on it.
const LOOSEN := 4.0
const T_SHUT := 1.0
const T_RISE := 1.5
## The storm's damage and the fright are dealt every TICK of the span (counted, so a long frame misses none).
const TICK := 0.25
## The carry is taken in steps no longer than this, so a long frame carries along the same path as many short ones.
const CARRY_STEP := 1.0 / 30.0
## A click with no drag: the door faces down-right on screen.
const DEFAULT_DIR := Vector2(1, 0)
const GOODS: Array[Decor.Kind] = [Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.CART, Decor.Kind.LOGS, Decor.Kind.PILE]
## The doorway is heard swallowing at most once every GULP_EVERY.
const GULP_EVERY := 0.4

## The eight ways it faces (ground units, 45 degrees apart: index k is the ground angle k * 45 degrees), and for each the
## sheet's row that shows it so (see the doc block: the front diagonals are drawn crosswise).
const DIRS: Array[Vector2] = [Vector2(1, 0), Vector2(0.7071067811865476, 0.7071067811865476), Vector2(0, 1),
	Vector2(-0.7071067811865476, 0.7071067811865476), Vector2(-1, 0), Vector2(-0.7071067811865476, -0.7071067811865476),
	Vector2(0, -1), Vector2(0.7071067811865476, -0.7071067811865476)]
const ROW_OF: Array[int] = [7, 0, 1, 6, 5, 4, 3, 2]
## How the door shows: its PixelLab sheet (a row per way it is seen, in ROWS' order; frame 0 shut to the last wide open
## on the light), its cell, the bottom middle of its base in each row's cell, and how large it is drawn (the sprite stands
## about 100 px of its 170: SCALE makes it some 170 px, against a cottage's 70 and a townhouse's 90).
const SHEET := "res://assets/pixellab/fx/heavens_door.png"
const CELL := 170
const FRAMES := 9
const ROWS: Array[String] = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
const FOOT: Array[Vector2] = [Vector2(85, 135), Vector2(84, 137), Vector2(88, 138), Vector2(85, 141), Vector2(85, 134),
	Vector2(84, 139), Vector2(81, 138), Vector2(86, 137)]
const SCALE := 1.7
## Its height on screen (px), where its light is lit, and how wide it stands on the ground (ground units, for its
## shadow); how far up it falls from and rises to (px).
const DOOR_H := 100.0 * SCALE
const OPEN_W := 2.6
const FALL_PX := 560.0
const RISE_PX := 620.0
const LIGHT := Color(1.0, 0.97, 0.86)
const WARM := Color(1.0, 0.86, 0.5)
## The light one gone through it pales into.
const GONE_LIGHT := Color(1.0, 0.92, 0.66)
const GOLD_WAVE := [Color(0.35, 0.27, 0.1, 0.5), Color("b08a3a"), Color("e8c060"), Color("ffe8a0"), Color("fffbea")]
const GOLD_LIFE := [Color("fffbea"), Color("ffe8a0"), Color("e8c060"), Color("b08a3a"), Color(0.4, 0.3, 0.1, 0.5)]
const PAVING := [Color("8a8478"), Color("6e685e"), Color("57524a"), Color("403c36")]
const DUST := [Color(0.86, 0.8, 0.7, 0.55), Color(0.76, 0.7, 0.62, 0.4), Color(0.64, 0.6, 0.54, 0.25), Color(0.5, 0.47, 0.42, 0.0)]

## Where it stands and which way it faces (a unit vector on the ground); what it has done.
var door := Vector2.ZERO
var facing := DEFAULT_DIR
var landed := false
var pulling := false
var shut := false
var crushed := 0
var knocked := 0
var taken_people: Array[Person] = []
var taken_animals := 0
var taken_goods := 0
## Small structures torn loose, and of those how many went through; bigger buildings the storm brought down.
var torn := 0
var torn_gone := 0
var felled := 0
## Everyone the pull ever had hold of (distinct, by instance id).
var drawn := 0

var _goods: Array[Decor] = []
## Small structure -> the pull that has worked on it so far.
var _strain := {}
## Torn loose and on its way in: [{at: Vector2, kind: Structure.Kind, size: Vector2, seed: int}].
var _loose: Array = []
var _ticks := 0
var _drawn_ids := {}
var _gulp_at := -INF
var _roar: Node
var _door_node: Door
var _flyers: Flyers
var _glow: QuadFx
var _front: QuadFx


## When it is fully open, when it shuts, and when it is gone.
func open_at() -> float:
	return T_FALL + T_OPEN


func shut_at() -> float:
	return open_at() + SPAN


func gone_at() -> float:
	return shut_at() + T_SHUT + T_RISE


## How fast the pull draws something `d` from the doorway.
static func pull_speed(d: float) -> float:
	return EnemyField.cone_speed(d, PULL_R, PULL_NEAR, PULL_FAR)


## Wind damage a second to a building whose nearest wall is `d` from the doorway.
static func storm_rate(d: float) -> float:
	return STORM_DAMAGE * lerpf(STORM_NEAR, 1.0, clampf(d / PULL_R, 0.0, 1.0))


## Whether `g` is in front of a door at `at` facing `dir`, within `r` of it.
static func before(g: Vector2, at: Vector2, dir: Vector2, r := PULL_R) -> bool:
	return EnemyField.cone_has(g, at, dir, r, HALF_ANGLE)


## Which way a cast faces: the drag, else DEFAULT_DIR, turned to the nearest of the eight DIRS.
static func facing_of(extra_data: Dictionary) -> Vector2:
	var d: Vector2 = extra_data.get("dir", DEFAULT_DIR)
	return DIRS[way_of(d if d.length() > 0.001 else DEFAULT_DIR)]


## Which of the eight DIRS lies nearest `dir` (its index).
static func way_of(dir: Vector2) -> int:
	return posmod(roundi(dir.angle() / (PI * 0.25)), DIRS.size())


## The sheet's row that shows a door facing `dir`.
static func row_of(dir: Vector2) -> int:
	return ROW_OF[way_of(dir)]


## The sheet's frame at `now`: shut (0) through the fall, opening to wide (FRAMES - 1) over T_OPEN, wide through the
## pull, closing back to shut over T_SHUT, and shut as it rises.
func frame_at(now: float) -> int:
	return roundi(leaves(now) * float(FRAMES - 1))


## 0..1 how far the leaves stand open at `now`: shut through the fall, opening over T_OPEN, wide for the span, slammed
## over T_SHUT.
func leaves(now: float) -> float:
	if now < T_FALL:
		return 0.0
	if now < open_at():
		return smoothstep(0.0, 1.0, (now - T_FALL) / T_OPEN)
	if now < shut_at():
		return 1.0
	var k := clampf((now - shut_at()) / T_SHUT, 0.0, 1.0)
	return 1.0 - k * k


func _build() -> void:
	door = ctx.field.through(origin)
	facing = facing_of(extra)
	duration = gone_at() + 0.2
	busy = T_FALL
	at(T_FALL, _land)
	at(T_FALL + 0.4, func(): ctx.play(&"hd_swell", door, -3.0))
	at(open_at(), _open)
	at(shut_at(), _shut)
	at(shut_at() + T_SHUT, _rise)
	ctx.play(&"hd_fall", door, -3.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door)
	_door_node = Door.new()
	_door_node.fx = self
	_door_node.position = sp
	track(_door_node, ctx.world if ctx.world != null else ctx.overhead)
	var shadow := Shadow.new()
	shadow.fx = self
	shadow.position = door
	shadow.z_index = 3
	track(shadow, ctx.ground)
	# The shaft of light it falls down: wide and soft, a white core, the sky's rays round it.
	var column := Set2Parts.glow_column(self, sp, 190.0, 640.0, WARM, 0.0, T_FALL + 0.35)
	column.tween_param("intensity", 0.3, 2.0, T_FALL, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.tween_param("intensity", 2.0, 0.0, 0.35, T_FALL)
	var core := Set2Parts.glow_column(self, sp, 40.0, 640.0, LIGHT, 0.0, T_FALL + 0.2)
	core.tween_param("intensity", 0.0, 2.6, T_FALL, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	core.tween_param("intensity", 2.6, 0.0, 0.2, T_FALL)
	var rays := FxParts.screen_rays(self, sp + Vector2(0, -260), 220.0, WARM, 40.0, 1.6)
	rays.tween_param("intensity", 0.0, 0.45, T_FALL, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	rays.tween_param("intensity", 0.45, 0.0, 0.3, T_FALL)
	rays.life = T_FALL + 0.32
	_glow = FxParts.ground_light(self, door, SHOCK_R, WARM, 0.0)
	_glow.tween_param("intensity", 0.0, 0.6, T_FALL, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GOLD_LIFE, 30.0, T_FALL,
		{"radius": 60.0, "speed": Vector2(2, 10), "alt": Vector2(0, 200), "alt_speed": Vector2(-60, -20), "life": Vector2(0.5, 1.0),
			"size": Vector2(1, 1)})
	motes.gravity = 30.0


## It lands: the crush, the throw, the blow to every building about it.
func _land() -> void:
	landed = true
	for e in ctx.field.in_radius(door, CRUSH_R):
		var p := e as Person
		if p != null and p.inside:
			continue
		if ctx.field.kill(e, &"stone", door):
			crushed += 1
	for a in _animals():
		if a.ground_pos.distance_to(door) <= CRUSH_R:
			a.die()
	for e in ctx.field.in_radius(door, SHOCK_R):
		var p := e as Person
		if p != null and p.inside:
			continue
		var rel := e.ground_pos - door
		var d := rel.length()
		var away := rel / d if d > 0.001 else facing
		e.knock(away * lerpf(KNOCK_NEAR, KNOCK_FAR, clampf((d - CRUSH_R) / (SHOCK_R - CRUSH_R), 0.0, 1.0)))
		if p != null:
			p.knock_down()
		knocked += 1
	ctx.env.damage_radius(door, SHOCK_R, LAND_DAMAGE, &"stone")
	ctx.play(&"hd_land", door, 0.0)
	ctx.play(&"collapse_stone", door, -2.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door)
	ctx.flash.call(Color(1.0, 0.96, 0.82, 0.55), 0.3)
	ctx.impact.hitstop(0.08)
	ctx.impact.aberration(3.0, 0.4)
	ctx.shake.add_trauma(1.0)
	ctx.shake.kick(Vector2(0, 6))
	# The paving breaks under it: a crater of cracked stone, gold at its torn edge.
	var crater := FxParts.decal(self, door, CRUSH_R + 0.6, Color(0.9, 0.7, 0.3), Color(1.0, 0.95, 0.75),
		Color(0.16, 0.14, 0.12, 0.85), 0.4)
	crater.z_index = 2
	crater.tween_param("heat", 1.0, 0.15, 2.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	crater.tween_param("fade", 1.0, 0.0, 1.0, gone_at() - T_FALL - 1.0)
	_glow.tween_param("intensity", 1.6, 0.25, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var wave := FxParts.shockwave(self, door, SHOCK_R + 1.0, GOLD_WAVE)
	wave.set_param("thickness", 0.07)
	wave.tween_param("progress", 0.05, 1.0, 0.6, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.35, 0.3)
	wave.life = 0.7
	var dust_wave := FxParts.shockwave(self, door, SHOCK_R + 3.0, [Color(0.3, 0.27, 0.22, 0.4), Color("6e685e"), Color("8a8478"), Color("b8b0a0"), Color("e0d8c8")])
	dust_wave.set_param("thickness", 0.12)
	dust_wave.tween_param("progress", 0.05, 1.0, 1.1, 0.05, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	dust_wave.tween_param("fade", 0.8, 0.0, 0.6, 0.6)
	dust_wave.life = 1.25
	var bend := FxParts.refract_ring(self, door, SHOCK_R + 3.0, Color(1.0, 0.92, 0.75))
	bend.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	bend.life = 0.72
	var burst := FxParts.bloom(self, sp + Vector2(0, -40), 140.0, LIGHT, 1.4, 0.7)
	burst.tween_param("intensity", 1.4, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	burst.life = 0.52
	FxParts.debris(self, sp, 30, 46.0, Vector2(80, 300), PAVING, Vector2(1.5, 4.5), true)
	FxParts.debris(self, sp, 12, 30.0, Vector2(40, 160), FxParts.ROCK, Vector2(2.0, 5.0), true)
	FxParts.sparks(self, ctx.overhead, sp + Vector2(0, -10), 40, GOLD_LIFE, Vector2(80, 320), Vector2(40, 220))
	# The ring of dust rolling out over the street, and a pall hanging over the place.
	var roll := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, DUST)
	roll.drag = 1.4
	roll.burst(60, {"radius": 40.0, "speed": Vector2(140, 280), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 4),
		"alt_speed": Vector2(2, 16), "life": Vector2(0.7, 1.4), "size": Vector2(3, 6), "size_end_mul": 2.0})
	FxParts.smoke(self, sp, 70.0, 24.0, 0.5, Vector2(10, 30), Vector2(3, 6), Vector2(1.0, 2.0), Color(0, 0, 0, 0), DUST)


## Fully open: the light pours out over the half circle, and the pull begins.
func _open() -> void:
	pulling = true
	_goods.clear()
	for d in ctx.env.decor():
		if is_instance_valid(d) and not d.sprite_only and d.kind in GOODS and before(d.at, door, facing):
			_goods.append(d)
	_roar = ctx.play(&"hd_draw", door, -1.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door) + Vector2(0, -DOOR_H * 0.45)
	ctx.shake.add_trauma(0.3)
	var flare := FxParts.bloom(self, sp, 80.0, WARM, 0.7, 1.6)
	flare.tween_param("intensity", 0.7, 0.18, 0.8, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	flare.tween_param("intensity", 0.18, 0.0, T_SHUT, SPAN, Tween.TRANS_QUAD, Tween.EASE_IN)
	flare.life = SPAN + T_SHUT + 0.05
	_front = FxParts.ground_light(self, door + facing * PULL_R * 0.35, PULL_R * 0.55, WARM, 0.0)
	_front.tween_param("intensity", 0.0, 0.55, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	_front.tween_param("intensity", 0.55, 0.0, T_SHUT, SPAN, Tween.TRANS_QUAD, Tween.EASE_IN)
	_front.life = SPAN + T_SHUT + 0.05
	var fan := Fan.new()
	fan.fx = self
	fan.position = door
	fan.z_index = 7
	track(fan, ctx.ground)
	var wind := Wind.new()
	wind.fx = self
	wind.position = door
	wind.z_index = 4
	track(wind, ctx.ground)
	_flyers = Flyers.new()
	_flyers.fx = self
	_flyers.z_index = 6
	track(_flyers, ctx.overhead)
	var funnel := FxParts.singularity(self, door + facing * 0.6, 3.0, GOLD_WAVE)
	funnel.set_param("strength", 0.0)
	funnel.set_param("pinch", 0.0)
	funnel.set_param("core_px", 0.0)
	funnel.set_param("arm_alpha", 0.0)
	funnel.set_param("rim_boost", 0.0)
	funnel.set_param("tint", 0.0)
	funnel.tween_param("pinch", 0.0, 0.35, 1.0)
	funnel.tween_param("pinch", 0.35, 0.0, T_SHUT, SPAN)
	funnel.life = SPAN + T_SHUT + 0.05
	var drift := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GOLD_LIFE, 24.0, SPAN, {
		"radius": 30.0, "speed": Vector2(4, 16), "alt": Vector2(0, 40), "alt_speed": Vector2(10, 40), "life": Vector2(0.6, 1.2),
		"size": Vector2(1, 1)})
	drift.gravity = -20.0


func _animals() -> Array[Animal]:
	var out: Array[Animal] = []
	if ctx.crowd == null:
		return out
	if ctx.crowd.animals != null:
		out.append_array(ctx.crowd.animals.living())
	for v in ctx.crowd.visitors:
		if is_instance_valid(v):
			out.append_array(v.living())
	return out


func _fx_process(delta: float) -> void:
	if pulling and not shut:
		while _ticks < roundi(SPAN / TICK) and t >= open_at() + TICK * float(_ticks):
			_ticks += 1
			_tick()
		var from := maxf(t - delta, open_at())
		var to := minf(t, shut_at())
		if to > from and not (ctx.crowd != null and ctx.crowd.is_frozen()):
			var steps := maxi(ceili((to - from) / CARRY_STEP - 0.001), 1)
			for k in steps:
				_carry((to - from) / float(steps))


## One step of the pull, `h` seconds: people, animals, goods, small structures, and what is already loose.
func _carry(h: float) -> void:
	var moved := ctx.field.pull_cone(door, facing, PULL_R, HALF_ANGLE, PULL_NEAR, PULL_FAR, h, _sheltered)
	for e in moved:
		var id := e.get_instance_id()
		if not _drawn_ids.has(id):
			_drawn_ids[id] = true
			drawn += 1
		if before(e.ground_pos, door, facing, DOOR_R):
			_take_person(e)
	for a in _animals():
		if not before(a.ground_pos, door, facing):
			continue
		a.ground_pos = ctx.field.carry_toward(a.ground_pos, door, pull_speed(a.ground_pos.distance_to(door)) * h)
		a.sync_position()
		if before(a.ground_pos, door, facing, DOOR_R):
			_take_animal(a)
	var k := _goods.size() - 1
	while k >= 0:
		var d := _goods[k]
		k -= 1
		if not is_instance_valid(d):
			_goods.erase(d)
			continue
		var next := ctx.field.carry_toward(d.at, door, pull_speed(d.at.distance_to(door)) * h)
		if next != d.at:
			d.shift(next - d.at)
		if d.at.distance_to(door) <= DOOR_R:
			_goods.erase(d)
			var at_ground := d.at
			ctx.env.remove_decor(d)
			taken_goods += 1
			_through(at_ground)
	_tear(h)
	var i := _loose.size() - 1
	while i >= 0:
		var piece: Dictionary = _loose[i]
		i -= 1
		var at_ground: Vector2 = piece.at
		# Torn loose, it is in the air: nothing holds it.
		var rel := door - at_ground
		var step := pull_speed(rel.length()) * h
		piece.at = at_ground + rel.limit_length(step)
		if Vector2(piece.at).distance_to(door) <= DOOR_R:
			_loose.erase(piece)
			torn_gone += 1
			_through(piece.at)


## Those inside a building are not reached.
func _sheltered(e: DummyEnemy) -> bool:
	var p := e as Person
	return p != null and p.inside


## The small structures in front give way, one by one, as the pull works on them.
func _tear(h: float) -> void:
	for s in ctx.env.near(door, PULL_R + 2.0):
		if not is_instance_valid(s) or s.destroyed or not s.kind in SkyliftFx.TAKES or s.role in SkyliftFx.KEEP_ROLES:
			continue
		var c := s.center()
		if not before(c, door, facing):
			continue
		var strain := float(_strain.get(s, 0.0)) + pull_speed(c.distance_to(door)) * h
		if strain < LOOSEN:
			_strain[s] = strain
			continue
		_strain.erase(s)
		torn += 1
		_loose.append({"at": c, "kind": s.kind, "size": s.footprint.size, "seed": torn})
		ctx.env.remove(s)  # torn up whole: no rubble, no fire, no incident
		ctx.play(&"collapse_timber", c, -4.0)
		if DominionParts.staged(self):
			var sp := Iso.ground_to_screen(c)
			FxParts.debris(self, sp, 10, 10.0, Vector2(30, 90), PAVING, Vector2(1.0, 3.0), true)


## One TICK of the span: the storm on the bigger buildings, and the fright of everyone it has hold of.
func _tick() -> void:
	for s in ctx.env.near(door, PULL_R + 2.0):
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		if s.kind in SkyliftFx.TAKES and not s.role in SkyliftFx.KEEP_ROLES:
			continue  # torn up whole instead (_tear())
		var d := s.distance_to(door)
		if d > PULL_R or (s.center() - door).dot(facing) < 0.0:
			continue
		s.damage(storm_rate(d) * TICK, door, &"wind")
		if s.destroyed:
			felled += 1
			_felled(s)
	for e in ctx.field.in_cone(door, facing, PULL_R, HALF_ANGLE):
		var p := e as Person
		if p == null or p.inside:
			continue
		if p.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.SHELTER, Person.Mind.FIGHT]:
			continue
		p.panic(door, PULL_R, &"wind")


## A building the storm brought down: its dust and splinters go in through the door.
func _felled(s: Structure) -> void:
	if not DominionParts.staged(self) or _flyers == null:
		return
	var c := s.center()
	for i in 9:
		var off := Vector2(ctx.rng.randf_range(-0.5, 0.5) * s.footprint.size.x, ctx.rng.randf_range(-0.5, 0.5) * s.footprint.size.y)
		_flyers.add(c + off, ctx.rng.randf_range(10.0, 40.0), 0)
	var sp := Iso.ground_to_screen(c)
	FxParts.smoke(self, sp, 30.0, 30.0, 0.4, Vector2(10, 30), Vector2(4, 8), Vector2(1.0, 2.0), Color(0, 0, 0, 0), DUST)


func _take_person(e: DummyEnemy) -> void:
	e.gone_light = GONE_LIGHT
	var at_ground := e.ground_pos
	if ctx.field.kill(e, &"gone", door):
		var p := e as Person
		if p != null:
			taken_people.append(p)
		_through(at_ground)


func _take_animal(a: Animal) -> void:
	var at_ground := a.ground_pos
	var pack: AnimalPack = ctx.crowd.animals if ctx.crowd != null else null
	if pack != null and pack.animals.has(a):
		pack.take(a)
	else:
		for v in ctx.crowd.visitors:
			if is_instance_valid(v) and v.living().has(a):
				v.take(a)
				break
	taken_animals += 1
	_through(at_ground)


## Something went through: the doorway flares and swallows it in a burst of white-gold.
func _through(at_ground: Vector2) -> void:
	if t >= _gulp_at:
		_gulp_at = t + GULP_EVERY
		ctx.play(&"hd_take", door, -4.0)
	if not DominionParts.staged(self):
		return
	if _door_node != null and is_instance_valid(_door_node):
		_door_node.flare = 1.0
	var sp := Iso.ground_to_screen(at_ground) + Vector2(0, -8)
	var p := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GOLD_LIFE)
	p.gravity = -40.0
	p.drag = 1.2
	p.burst(10, {"radius": 5.0, "speed": Vector2(4, 18), "alt": Vector2(0, 14), "alt_speed": Vector2(10, 40),
		"life": Vector2(0.4, 0.9), "size": Vector2(1, 1)})


## The span is over: the leaves slam shut.
func _shut() -> void:
	shut = true
	pulling = false
	_goods.clear()
	_strain.clear()
	_loose.clear()
	_hush(T_SHUT)
	at(shut_at() + T_SHUT * 0.9, _slam)


func _slam() -> void:
	ctx.play(&"hd_shut", door, 0.0)
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.55)
	ctx.flash.call(Color(1.0, 0.95, 0.8, 0.3), 0.18)
	var sp := Iso.ground_to_screen(door)
	var pop := FxParts.bloom(self, sp + Vector2(0, -DOOR_H * 0.45), 70.0, LIGHT, 1.2, 1.4)
	pop.tween_param("intensity", 1.2, 0.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	pop.life = 0.32
	var ring := FxParts.shockwave(self, door, 3.5, GOLD_WAVE)
	ring.set_param("thickness", 0.08)
	ring.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.25, 0.15)
	ring.life = 0.45
	FxParts.smoke(self, sp, 40.0, 30.0, 0.3, Vector2(6, 20), Vector2(4, 7), Vector2(0.8, 1.6), Color(0, 0, 0, 0), DUST)


## It goes back up into the sky in its shaft of light.
func _rise() -> void:
	ctx.play(&"hd_rise", door, -2.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(door)
	var column := Set2Parts.glow_column(self, sp, 170.0, 640.0, WARM, 1.6, T_RISE)
	column.life = T_RISE + 0.02
	if is_instance_valid(_glow):
		_glow.tween_param("intensity", 0.25, 0.0, T_RISE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)


## The roar (a looping cue) fades over `seconds`, if it is still this door's to fade.
func _hush(seconds: float) -> void:
	if _roar != null and is_instance_valid(_roar) and _roar.get_meta(&"cue", &"") == &"hd_draw":
		ctx.fade_out(_roar, seconds)
	_roar = null


## Over, or cut short (end_now()): the roar goes with it; what was torn loose and not yet through is lost with it.
func _finish() -> void:
	_hush(0.3)
	super()


## The door: the PixelLab sheet drawn standing on the landing point, its foot (FOOT, per row) on the ground point, in
## the world layer so the town sorts round it -- and whatever building stands in front of it and would hide it goes
## see-through (SeeThrough) from just before it lands until it has risen away; the row for its facing (row_of), the
## frame for the hour (frame_at). It
## comes down out of the sky through the fall and goes back up as it rises, fading; while it stands wide its light
## breathes, and it flares (`flare`) as something goes through. Without the sheet (not imported) it draws nothing: the
## light, the shadow and the dust still show where it stands.
class Door extends Node2D:
	var fx: HeavensDoorFx
	var flare := 0.0
	var row := 0
	var _tex: Texture2D
	var _see := SeeThrough.new()

	func _ready() -> void:
		row = HeavensDoorFx.row_of(fx.facing)
		if ResourceLoader.exists(SHEET):
			_tex = load(SHEET)

	func _process(delta: float) -> void:
		flare = maxf(flare - delta * 2.5, 0.0)
		# Fading as it rises away.
		var k := clampf((fx.t - fx.shut_at() - T_SHUT) / T_RISE, 0.0, 1.0)
		modulate = Color(1.0, 1.0, 1.0, 1.0 - k * k)
		queue_redraw()
		# The houses before it see-through while it stands (from just before it lands until it is half risen away).
		var standing := fx.t >= T_FALL - 0.3 and k < 0.5
		var rect := see_rect() if standing else Rect2()
		_see.step(fx.ctx.env.structures() if fx.ctx.env != null else [], rect, position.y, delta)

	## What it covers on screen standing (world px): its sprite's body, a little inside the cell.
	func see_rect() -> Rect2:
		return Rect2(position.x - DOOR_H * 0.4, position.y - DOOR_H * 1.05, DOOR_H * 0.8, DOOR_H * 1.05)

	func _exit_tree() -> void:
		_see.release()

	func _draw() -> void:
		var now := fx.t
		if _tex == null or now >= fx.gone_at():
			return
		var lift := 0.0
		if now < T_FALL:
			var k := now / T_FALL
			lift = FALL_PX * (1.0 - k * k)
		elif now > fx.shut_at() + T_SHUT:
			var k := clampf((now - fx.shut_at() - T_SHUT) / T_RISE, 0.0, 1.0)
			lift = RISE_PX * k * k
		elif now < T_FALL + 0.25:
			# The jolt of landing.
			lift = -sin((now - T_FALL) / 0.25 * PI) * 3.0
		var frame := fx.frame_at(now)
		# Wide open, the light in it breathes; it flares as something goes through.
		# (Gently: the canvas is not HDR, so much over 1 bleaches the marble white.)
		var glow := 1.0 + 0.1 * flare
		if frame == FRAMES - 1:
			glow += 0.03 + 0.03 * sin(now * 2.6)
		var foot: Vector2 = FOOT[row]
		draw_set_transform(Vector2(0.0, -lift), 0.0, Vector2(SCALE, SCALE))
		draw_texture_rect_region(_tex, Rect2(-foot, Vector2(CELL, CELL)), Rect2(frame * CELL, row * CELL, CELL, CELL),
			Color(glow, glow, glow * 0.96))
		draw_set_transform(Vector2.ZERO)


## A hash in 0..1 for drawing (no rng drawn).
static func hash01(i: int, salt: int) -> float:
	var h := (i * 73856093) ^ (salt * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	return float(absi(h) % 10007) / 10007.0


## The door's shadow on the ground as it falls: a soft dark spot growing and darkening as it comes down; once it has
## landed, the scorch of its foot under it. Ground units, ground layer.
class Shadow extends Node2D:
	var fx: HeavensDoorFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		if now >= fx.gone_at():
			return
		var k := 1.0
		if now < T_FALL:
			k = clampf(now / T_FALL, 0.0, 1.0)
		elif now > fx.shut_at() + T_SHUT:
			k = 1.0 - clampf((now - fx.shut_at() - T_SHUT) / T_RISE, 0.0, 1.0)
		var r := lerpf(OPEN_W * 2.5, OPEN_W * 0.9, k)
		for i in 4:
			draw_circle(Vector2.ZERO, r * (1.0 - 0.2 * float(i)), Color(0.0, 0.0, 0.02, 0.1 * k))


## The light poured out over the half circle in front: god rays fanning out from the doorway to PULL_R, turning slowly
## and breathing. Ground units, ground layer, added onto the street.
class Fan extends Node2D:
	const RAYS := 13
	var fx: HeavensDoorFx

	func _ready() -> void:
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = add

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		var a := fx.leaves(now)
		if a <= 0.0 or now >= fx.shut_at() + T_SHUT:
			return
		var base := fx.facing.angle()
		for i in RAYS:
			var u := (float(i) + 0.5) / float(RAYS)
			var ang := base + (u - 0.5) * PI * 0.94 + sin(now * 0.3 + float(i) * 1.7) * 0.04
			var width := 0.05 + 0.04 * HeavensDoorFx.hash01(i, 11)
			var reach := PULL_R * (0.75 + 0.25 * HeavensDoorFx.hash01(i, 13)) * clampf(a * 1.4, 0.0, 1.0)
			var breath := 0.5 + 0.5 * sin(now * (0.8 + HeavensDoorFx.hash01(i, 17)) + float(i))
			var c := Color(WARM.r, WARM.g, WARM.b, (0.06 + 0.06 * breath) * a)
			var tip := Vector2.from_angle(ang)
			if reach < 0.5:
				continue
			# From a narrow foot at the doorway out to a wide end, round one side and back down the other.
			var foot := tip.orthogonal() * 0.3
			draw_colored_polygon(PackedVector2Array([foot, tip.rotated(-width) * reach, tip.rotated(width) * reach, -foot]), c)
		draw_circle(Vector2.ZERO, 2.0 * a, Color(LIGHT, 0.12 * a))


## The wind drawn into the door: streaks running in over the half circle, faster near the door, and dust motes
## riding them. Ground units, ground layer, under everyone.
class Wind extends Node2D:
	const STREAKS := 110
	var fx: HeavensDoorFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		if not fx.pulling or now >= fx.shut_at():
			return
		var a := clampf((now - fx.open_at()) / 0.8, 0.0, 1.0) * clampf((fx.shut_at() - now) / 0.5, 0.0, 1.0)
		var base := fx.facing.angle()
		for i in STREAKS:
			var ang := base + (HeavensDoorFx.hash01(i, 21) - 0.5) * PI
			# Each streak runs in from the rim to the door, round and round; the pull's speed sets its pace.
			var phase := fposmod(HeavensDoorFx.hash01(i, 23) + now * 0.16 * (1.0 + HeavensDoorFx.hash01(i, 25)), 1.0)
			var d := PULL_R * (1.0 - phase * phase)
			if d < DOOR_R:
				continue
			var dir := Vector2.from_angle(ang)
			var run := 0.4 + HeavensDoorFx.pull_speed(d) * 0.35
			var from := dir * d
			var c := Color(0.95, 0.9, 0.8, 0.22 * a * (1.0 - d / PULL_R * 0.6))
			draw_line(from, from - dir * run, c, 0.06)
			if i % 3 == 0:
				draw_circle(from, 0.06, Color(0.75, 0.68, 0.58, 0.5 * a))


## What is drawn in through the air: the small structures torn loose (fx._loose, drawn as their timbers and cloth) and
## the splinters of what the storm brought down, flying in to the door, turning, smaller as they go in. Screen space.
class Flyers extends Node2D:
	var fx: HeavensDoorFx
	## [ground at, lift px, ground start distance]
	var _bits: Array = []

	func add(at_ground: Vector2, lift: float, _kind: int) -> void:
		_bits.append([at_ground, lift, at_ground.distance_to(fx.door)])

	func _process(delta: float) -> void:
		if fx.pulling:
			var k := _bits.size() - 1
			while k >= 0:
				var b: Array = _bits[k]
				k -= 1
				var rel: Vector2 = fx.door - b[0]
				b[0] = b[0] + rel.limit_length(HeavensDoorFx.pull_speed(rel.length()) * 1.4 * delta)
				if Vector2(b[0]).distance_to(fx.door) <= DOOR_R * 0.6:
					_bits.erase(b)
		else:
			_bits.clear()
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		for i in _bits.size():
			var b: Array = _bits[i]
			var d := Vector2(b[0]).distance_to(fx.door)
			var k := clampf(d / maxf(float(b[2]), 0.1), 0.0, 1.0)
			var sp := Iso.ground_to_screen(b[0]) + Vector2(0, -float(b[1]) * k - 30.0 * (1.0 - k))
			var r := 1.5 + 1.5 * k
			draw_set_transform(sp, now * 6.0 + float(i), Vector2.ONE)
			draw_rect(Rect2(-r, -r * 0.5, r * 2.0, r), Color(0.55, 0.42, 0.3))
			draw_set_transform(Vector2.ZERO)
		for i in fx._loose.size():
			var piece: Dictionary = fx._loose[i]
			var g: Vector2 = piece.at
			var d := g.distance_to(fx.door)
			var lift := 10.0 + 20.0 * clampf(1.0 - d / PULL_R, 0.0, 1.0)
			var sp := Iso.ground_to_screen(g) + Vector2(0, -lift)
			var size: Vector2 = piece.size
			var w := clampf(size.x * 14.0, 6.0, 18.0) * clampf(d / 3.0, 0.35, 1.0)
			draw_set_transform(sp, now * 2.5 + float(piece.seed), Vector2.ONE)
			# A stall's boards and its striped awning, or a stack's crates, or a trunk: a few planks turning over.
			draw_rect(Rect2(-w * 0.5, -2.0, w, 4.0), Color(0.5, 0.36, 0.22))
			draw_rect(Rect2(-w * 0.4, -5.0, w * 0.8, 2.0), Color(0.75, 0.25, 0.2) if int(piece.kind) == Structure.Kind.MARKET_STALL else Color(0.62, 0.46, 0.28))
			draw_rect(Rect2(-w * 0.3, 2.0, w * 0.25, 4.0), Color(0.42, 0.3, 0.18))
			draw_set_transform(Vector2.ZERO)
