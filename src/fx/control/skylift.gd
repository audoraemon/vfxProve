class_name SkyliftFx
extends FxTimeline
## Skylift (Passage, Tier I): a beam takes everything that stands in one place and sets it down in another. Two
## clicks: where it takes from, and where it sets down (extra "to"). A bright blue light stands on the first place for
## T_TAKE; then everything within RADIUS of it is gone from there:
##  - the people -- any role; those inside a building are not reached -- stand at the second place, each as far from
##    its middle as they stood from the first's (DummyEnemy.fold(): a person keeps what it meant to do, and walks on
##    toward it from where it was set down), unhurt;
##  - the goods -- the barrels, crates, tables, carts, logs, stone, benches and piles standing there (Decor, GOODS),
##    and the small things built there: a market stall, a stack of crates, a tree (Structure, TAKES; never a wall, a
##    gate or a tower) -- are lifted whole (not broken: no rubble, no fire) and come down at the second place as ONE
##    heap, HEAP across, that lands as a Windfall segment does: whoever stands within KILL_R of its middle is crushed
##    (damage kind stone; not those the beam itself just set down there), what stands within HIT_R takes DAMAGE
##    (stone: no fire), whoever lived on its footprint is pushed clear, and the heap bars the walk grid under it (a
##    structure, role windfall: the engineers' Clear job takes it, the town clears it) until it is cleared, or LIFE.
##    A heap does not land inside a building: it takes the nearest open spot within SHIFT, else the goods are lost.
## A second, shorter light marks the arrival. A lift with only people leaves nothing behind. Quiet, but for the book
## entry's "alarm": a light from the sky is seen.
## Levels (PowerBook "skylift" levels): the circle (RADIUS) grows and the take (T_TAKE) comes sooner, read once a cast
## (lv_radius, lv_t_take; the consts at level 1). Level 5's twist, Stay Put: everyone the beam sets down stands rooted
## where they landed for STAY -- no step of their own (Person.statuses "slow" 0: their pace is nothing), soldiers too;
## they can still be struck, bitten or moved by another power -- and then walks on to what they meant, their own pace
## back as it was (also when the beam is cut short). The heap lands as before.

const RADIUS := 2.5
const T_TAKE := 1.4
const T_SET := 0.6
const KILL_R := 0.5
const HIT_R := 0.8
const DAMAGE := 20.0
## The heap's footprint side, its height as an obstacle, how long it stands untended, and how far from the second
## click it may land when a building stands there.
const HEAP := 1.2
const HEIGHT := 8.0
const LIFE := 120.0
const SHIFT := 1.5
## Stay Put (level 5): how long those set down stand rooted.
const STAY := 10.0
## The decor kinds that are goods to lift, and the small structures.
const GOODS: Array[Decor.Kind] = [
	Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.TABLE, Decor.Kind.CART, Decor.Kind.LOGS, Decor.Kind.ROCK,
	Decor.Kind.BENCH, Decor.Kind.PILE,
]
const TAKES: Array[Structure.Kind] = [Structure.Kind.MARKET_STALL, Structure.Kind.CRATES, Structure.Kind.TREE]
const KEEP_ROLES: Array[StringName] = [&"wall", &"gate", &"tower"]
## What a lifted small structure comes down as: three pieces each.
const OF_STALL: Array[Decor.Kind] = [Decor.Kind.TABLE, Decor.Kind.CRATES, Decor.Kind.BARREL]
const OF_CRATES: Array[Decor.Kind] = [Decor.Kind.CRATES, Decor.Kind.CRATES, Decor.Kind.CRATES]
const OF_TREE: Array[Decor.Kind] = [Decor.Kind.LOGS, Decor.Kind.LOGS, Decor.Kind.LOGS]
## How many pieces lie flat before the rest are thrown on top (WindfallFx.heap_for's BASE).
const BASE := 4
## The fall of the goods, on screen: they tumble up into the first column over the last RISE s before the take, and
## come down out of the second from DROP_H px up, each FALL in the air, STAGGER apart.
const RISE := 0.5
const FALL := 0.35
const STAGGER := 0.02
const DROP_H := 260.0
const BLUE := Color(0.45, 0.75, 1.0)
const PALE := Color(0.8, 0.92, 1.0)

## This cast's circle and take time at its ability level (RADIUS and T_TAKE at level 1).
var lv_radius := RADIUS
var lv_t_take := T_TAKE
## Stay Put: whether this cast roots those it sets down, and until when (effect clock; -1 before the take).
var stay_put := false
var rooted_until := -1.0

## Where it sets them down; how many people it took; the goods it took ([{kind, at, seed, scale, lift}] as they lie
## at the second place, WindfallFx.heap_for's shape); how many the heap crushed; the heap itself (null when there
## were no goods, where it could not land, or once it is gone).
var to := Vector2.ZERO
var taken := 0
var goods: Array = []
var crushed := 0
var heap: Structure = null

var _land := Vector2.INF
var _seed := 0
var _heap_node: Node2D
## The goods seen rising, with their places at the first click (set before the take, for the drawing).
var _rising: Array = []
## Stay Put: those rooted now, by instance id -> [Person, the "slow" they had before (or null)].
var _rooted := {}


## Whom a lift at `at` would take (within `r`: RADIUS, or a cast's lv_radius).
static func lifted_at(field: EnemyField, at: Vector2, r := RADIUS) -> Array:
	var out: Array = []
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and p.inside:
			continue
		out.append(e)
	return out


## What a lift at `at` would take besides the people: the Decor goods (GOODS) standing within RADIUS, and the small
## structures (TAKES, standing, not a fortification's) whose footprint reaches into the circle (of `r`: RADIUS, or a
## cast's lv_radius).
static func goods_at(env: EnvironmentField, at: Vector2, r := RADIUS) -> Array:
	var out: Array = []
	for d in env.decor():
		if is_instance_valid(d) and not d.sprite_only and d.kind in GOODS and d.at.distance_to(at) <= r:
			out.append(d)
	for s in env.structures():
		if not is_instance_valid(s) or s.destroyed or not s.kind in TAKES or s.role in KEEP_ROLES:
			continue
		if s.distance_to(at) <= r:
			out.append(s)
	return out


## Where a heap aimed at `to` lands: `to` itself on open ground, else the nearest open spot within SHIFT (rings of
## twelve), else nowhere (INF).
static func landing_for(env: EnvironmentField, to: Vector2) -> Vector2:
	if not env.blocked(to, 0.0):
		return to
	var ring := 0.5
	while ring <= SHIFT + 0.001:
		for i in 12:
			var cand := to + Vector2.from_angle(TAU * float(i) / 12.0) * ring
			if not env.blocked(cand, 0.0):
				return cand
		ring += 0.5
	return Vector2.INF


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "skylift", "RADIUS", RADIUS))
	lv_t_take = float(PowerBook.stat(extra, "skylift", "T_TAKE", T_TAKE))
	stay_put = PowerBook.twist_at(extra, "skylift")
	to = extra.get("to", origin + Vector2(4.0, 0.0))
	_seed = int(ctx.rng.randi() % 100000)
	_land = landing_for(ctx.env, to)
	duration = lv_t_take + T_SET + 0.8
	busy = lv_t_take
	at(lv_t_take, _take)
	ctx.play(&"q_skylift", origin)
	if not DominionParts.staged(self):
		return
	at(lv_t_take - RISE, _show_rise)
	var sp := Iso.ground_to_screen(origin)
	# The light comes down on the place: a wide column, a bright core, rays off the sky, rings drawn in under it, the
	# ground lit, motes drawn up into it, and the air over it bent.
	var column := Set2Parts.glow_column(self, sp, 110.0, 520.0, BLUE, 0.0, lv_t_take + 0.3)
	column.tween_param("intensity", 0.2, 2.2, lv_t_take * 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.tween_param("intensity", 2.2, 0.0, 0.3, lv_t_take)
	var core := Set2Parts.glow_column(self, sp, 34.0, 520.0, PALE, 0.0, lv_t_take + 0.2)
	core.tween_param("intensity", 0.0, 2.6, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	core.tween_param("intensity", 2.6, 0.0, 0.2, lv_t_take)
	var white := FxParts.beam(self, ctx.overhead, sp, 12.0, 520.0, FxParts.ION)
	white.set_param("intensity", 0.0)
	white.tween_param("intensity", 0.0, 1.4, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	white.tween_param("intensity", 1.4, 0.0, 0.2, lv_t_take)
	white.life = lv_t_take + 0.22
	var rays := FxParts.screen_rays(self, sp + Vector2(0, -30), 120.0, PALE, 60.0, 0.0)
	rays.tween_param("intensity", 0.0, 0.5, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	rays.tween_param("intensity", 0.5, 0.0, 0.25, lv_t_take)
	rays.life = lv_t_take + 0.27
	var halo := FxParts.bloom(self, sp + Vector2(0, -10), 50.0, BLUE, 0.0, 0.7)
	halo.tween_param("intensity", 0.0, 0.8, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	halo.tween_param("intensity", 0.8, 0.0, 0.25, lv_t_take)
	halo.life = lv_t_take + 0.27
	var bend := FxParts.refract_ring(self, origin, lv_radius + 1.0, Color(0.7, 0.85, 1.0))
	bend.set_param("progress", 1.0)
	bend.tween_param("progress", 1.0, 0.1, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	bend.life = lv_t_take + 0.05
	for i in 3:
		var draw := FxParts.shockwave(self, origin, lv_radius + 1.6, FxParts.ION)
		draw.set_param("thickness", 0.06)
		draw.set_param("progress", 1.0)
		draw.set_param("fade", 0.0)
		draw.tween_param("progress", 1.0, 0.08, 0.6, 0.15 + 0.35 * float(i), Tween.TRANS_QUAD, Tween.EASE_IN)
		draw.tween_param("fade", 0.0, 0.8, 0.1, 0.15 + 0.35 * float(i))
		draw.tween_param("fade", 0.8, 0.0, 0.15, 0.6 + 0.35 * float(i))
		draw.life = 0.8 + 0.35 * float(i)
	var mark := FxParts.rings(self, origin, lv_radius, PALE, 2, 14.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, lv_t_take * 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = lv_t_take + 0.1
	var light := FxParts.ground_light(self, origin, lv_radius * 2.2, BLUE, 0.0)
	light.tween_param("intensity", 0.0, 2.0, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.tween_param("intensity", 2.0, 0.0, 0.3, lv_t_take)
	light.life = lv_t_take + 0.32
	var ground_rays := FxParts.ground_rays(self, origin, lv_radius * 2.5, PALE, 40.0)
	ground_rays.set_param("reach", 0.9)
	ground_rays.tween_param("intensity", 0.0, 0.8, lv_t_take, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	ground_rays.tween_param("intensity", 0.8, 0.0, 0.3, lv_t_take)
	ground_rays.life = lv_t_take + 0.32
	var up := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, FxParts.ION_LIFE, 110.0, lv_t_take,
		{"radius": 26.0, "speed": Vector2(0, 6), "alt": Vector2(0, 10), "alt_speed": Vector2(140, 320), "life": Vector2(0.5, 1.0), "size": Vector2(1, 3)})
	up.gravity = -80.0
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 50.0, lv_t_take,
		{"radius": 40.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 30), "alt_speed": Vector2(20, 80), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	motes.drag = 0.5
	ctx.play(&"laser_scan", origin, -8.0)
	ctx.shake.add_trauma(0.1)


## The goods begin to rise into the column (what stands there now; the take itself reads the place again).
func _show_rise() -> void:
	_rising = _pieces_of(goods_at(ctx.env, origin, lv_radius), origin)
	if _rising.is_empty():
		return
	var rise := Rise.new()
	rise.fx = self
	rise.pieces = _rising
	rise.z_index = 6
	track(rise, ctx.overhead)


## Everything is taken, and set down.
func _take() -> void:
	var set_down: Array = []
	for e in lifted_at(ctx.field, origin, lv_radius):
		if e.fold(to + (e.ground_pos - origin)):
			taken += 1
			set_down.append(e)
	var things := goods_at(ctx.env, origin, lv_radius)
	var lifted := _pieces_of(things, origin)
	for thing in things:
		if thing is Decor:
			ctx.env.remove_decor(thing)
		elif thing is Structure:
			ctx.env.remove(thing)  # lifted whole, not broken: no rubble, no incident
	ctx.play(&"grav_shimmer", to, -4.0)
	if not lifted.is_empty() and _land != Vector2.INF:
		goods = _heap_of(lifted, _land)
		_drop(set_down)
	if stay_put:
		_root(set_down)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(0.75, 0.9, 1.0, 0.22), 0.25)
	ctx.impact.hitstop(0.05)
	ctx.impact.aberration(2.0, 0.3)
	ctx.shake.add_trauma(0.35)
	var sp := Iso.ground_to_screen(origin)
	var dp := Iso.ground_to_screen(to)
	# Where they stood: the light snaps shut in a white flash, the air snaps back, a ring goes out, sparks fall.
	var snap := FxParts.bloom(self, sp + Vector2(0, -20), 60.0, Color(0.9, 0.96, 1.0), 1.1, 0.8)
	snap.tween_param("intensity", 1.1, 0.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	snap.life = 0.37
	var back := FxParts.refract_ring(self, origin, lv_radius + 2.0, Color(0.7, 0.85, 1.0))
	back.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	back.life = 0.47
	_ring(origin)
	var second := FxParts.shockwave(self, origin, lv_radius + 2.5, FxParts.ION)
	second.set_param("thickness", 0.05)
	second.tween_param("progress", 0.05, 1.0, 0.7, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	second.tween_param("fade", 1.0, 0.0, 0.3, 0.5)
	second.life = 0.85
	FxParts.sparks(self, ctx.overhead, sp, 36, FxParts.ION_LIFE, Vector2(60, 260), Vector2(80, 320))
	var fall := FxParts.particles(self, ctx.overhead, sp + Vector2(0, -120), PixelParticles.Shape.STREAK, FxParts.ION_LIFE)
	fall.gravity = 220.0
	fall.burst(24, {"radius": 24.0, "speed": Vector2(0, 10), "alt": Vector2(0, 160), "alt_speed": Vector2(-40, 20), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	# Where they are set down: the beam comes down once more, hard and short, and they stand in its light.
	var column := Set2Parts.glow_column(self, dp, 110.0, 520.0, BLUE, 2.2, T_SET)
	column.tween_param("intensity", 2.2, 0.0, T_SET, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var core := Set2Parts.glow_column(self, dp, 34.0, 520.0, PALE, 2.6, T_SET * 0.7)
	core.tween_param("intensity", 2.6, 0.0, T_SET * 0.7)
	var white := FxParts.beam(self, ctx.overhead, dp, 12.0, 520.0, FxParts.ION)
	white.tween_param("intensity", 1.4, 0.0, T_SET * 0.6)
	white.life = T_SET * 0.6 + 0.02
	var rays := FxParts.screen_rays(self, dp + Vector2(0, -30), 120.0, PALE, 60.0, 0.5)
	rays.tween_param("intensity", 0.5, 0.0, T_SET + 0.2)
	rays.life = T_SET + 0.22
	var land := FxParts.bloom(self, dp + Vector2(0, -20), 60.0, Color(0.9, 0.96, 1.0), 1.0, 0.8)
	land.tween_param("intensity", 1.0, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	land.life = 0.42
	_ring(to)
	var out := FxParts.refract_ring(self, to, lv_radius + 2.0, Color(0.7, 0.85, 1.0))
	out.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	out.life = 0.52
	var light := FxParts.ground_light(self, to, lv_radius * 2.2, BLUE, 2.0)
	light.tween_param("intensity", 2.0, 0.0, T_SET + 0.4)
	light.life = T_SET + 0.42
	var ground_rays := FxParts.ground_rays(self, to, lv_radius * 2.5, PALE, 40.0)
	ground_rays.set_param("reach", 0.9)
	ground_rays.tween_param("intensity", 0.8, 0.0, T_SET + 0.3)
	ground_rays.life = T_SET + 0.32
	FxParts.sparks(self, ctx.overhead, dp, 28, FxParts.ION_LIFE, Vector2(40, 200), Vector2(60, 240))
	var settle := FxParts.emitter(self, ctx.overhead, dp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 60.0, T_SET,
		{"radius": 28.0, "speed": Vector2(2, 8), "alt": Vector2(60, 160), "alt_speed": Vector2(-120, -40), "life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	settle.gravity = 40.0
	# The goods come down out of the second column onto the heap, one after another, and land in dust and splinters.
	if heap != null:
		var load := Fall.new()
		load.fx = self
		load.z_index = 6
		track(load, ctx.overhead)
		at(t + FALL + STAGGER * float(goods.size()), _show_landed)


## The heap lands at `_land`: the blows, then the pile that bars the way. Those the beam set down are not crushed by
## what came with them (`set_down`), but they are pushed clear like anyone else on its footprint.
func _drop(set_down: Array) -> void:
	for e in ctx.field.in_radius(_land, KILL_R):
		var p := e as Person
		if (p != null and p.inside) or set_down.has(e):
			continue
		if ctx.field.kill(e, &"stone", _land):
			crushed += 1
	ctx.env.damage_radius(_land, HIT_R, DAMAGE, &"stone")
	for e in ctx.field.in_radius(_land, HEAP * 0.5 + 0.15):
		var p := e as Person
		if (p != null and p.inside) or not e.is_alive():
			continue
		var off: Vector2 = e.ground_pos - _land
		var out := off.normalized() if off.length() > 0.01 else Vector2(1, 0)
		for d: float in [0.9, 1.2, 1.5]:
			if not ctx.env.blocked(_land + out * d):
				e.ground_pos = _land + out * d
				break
	heap = ctx.env.add_structure(Rect2(_land - Vector2(HEAP, HEAP) * 0.5, Vector2(HEAP, HEAP)), HEIGHT, Structure.Kind.CRATES, &"windfall")
	heap.visible = false
	duration = lv_t_take + LIFE + 0.5
	ctx.play(&"jg_crumble", _land, -4.0)


## The last piece is down: the heap lies there (WindfallFx.Heap in the world layer, so people sort round it), in a
## burst of dust and splinters, and the ground jolts.
func _show_landed() -> void:
	if heap == null or not is_instance_valid(heap):
		return
	var h := WindfallFx.Heap.new()
	h.pieces = goods
	h.position = Iso.ground_to_screen(_land)
	_heap_node = track(h, ctx.world)
	var sp := Iso.ground_to_screen(_land)
	FxParts.debris(self, sp, 10, 8.0, Vector2(30, 140), WindfallFx.WOOD, Vector2(1.5, 3.0), true)
	FxParts.debris(self, sp, 6, 6.0, Vector2(20, 90), FxParts.ROCK, Vector2(1.5, 2.5), true)
	FxParts.smoke(self, sp, 10.0, 24.0, 0.3, Vector2(14, 34), Vector2(3, 6), Vector2(0.6, 1.1))
	ctx.shake.add_trauma(0.3)
	ctx.shake.kick(Vector2(0, 3))


func _fx_process(_delta: float) -> void:
	if not _rooted.is_empty() and t >= rooted_until:
		_unroot_all()
	if heap == null:
		return
	# Gone by other hands (the engineers' Clear job, a blast): the goods go with it, and the beam is done.
	if not is_instance_valid(heap) or heap.destroyed or not ctx.env.structures().has(heap):
		heap = null
		_drop_goods()
		_end_by(t + 0.5)
		return
	if t >= lv_t_take + LIFE:
		_remove_heap()


## The heap is taken away (its time is up, or the night ends): the way is open again.
func _remove_heap() -> void:
	if heap != null and is_instance_valid(heap) and ctx.env.structures().has(heap):
		ctx.env.remove(heap)
	heap = null
	_drop_goods()
	_end_by(t + 0.5)


## The beam is done by `time` -- but not before those it rooted walk again.
func _end_by(time: float) -> void:
	duration = minf(duration, time)
	if not _rooted.is_empty():
		duration = maxf(duration, rooted_until + 0.1)


## Stay Put: those set down (people only; the dead and those indoors are not) stand rooted for STAY. Their pace is
## nothing ("slow" 0) until then; what slowed them before is kept, and given back when they walk again.
func _root(set_down: Array) -> void:
	for e in set_down:
		var p := e as Person
		if p == null or not is_instance_valid(p) or p.inside or not p.is_alive():
			continue
		var id := p.get_instance_id()
		if _rooted.has(id):
			continue
		_rooted[id] = [p, null]
		p.hold_pace(get_instance_id(), 0.0)
	if _rooted.is_empty():
		return
	rooted_until = t + STAY
	duration = maxf(duration, rooted_until + 0.1)
	if not DominionParts.staged(self):
		return
	# The place is held: a faint ring of the beam's light stays on the ground where they stand, pulsing, and fades
	# as the hold wears off (one ring for them all, however many were set down).
	var pin := FxParts.rings(self, to, lv_radius, PALE, 2, 22.0)
	pin.set_param("scan", 0.0)
	pin.set_param("crosshair", 0.0)
	pin.set_param("fill", 0.05)
	pin.tween_param("reveal", 0.0, 1.0, 0.4, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	pin.tween_param("alpha", 1.0, 0.0, 1.2, STAY - 1.2)
	pin.life = STAY + 0.05
	var glow := FxParts.ground_light(self, to, lv_radius * 1.4, BLUE, 0.6)
	glow.tween_param("intensity", 0.6, 0.0, 1.2, STAY - 1.2)
	glow.life = STAY + 0.05


## The hold is over (STAY is up, or the beam is cut short): each walks again at the pace they had.
func _unroot_all() -> void:
	for id in _rooted.keys():
		var held: Array = _rooted[id]
		var p: Person = held[0]
		if not is_instance_valid(p):
			continue
		p.free_pace(get_instance_id())
	_rooted.clear()


func _drop_goods() -> void:
	if is_instance_valid(_heap_node):
		_heap_node.queue_free()
	_heap_node = null


## Cut short (FxTimeline.end_now()): the heap goes with it, or it would block the way for good.
func end_now() -> void:
	_unroot_all()
	_remove_heap()
	super()


## Freed with the hold still on (the scene torn down): nobody is left rooted.
func _exit_tree() -> void:
	_unroot_all()
	super()


## The heap pieces the lifted things ([Decor | Structure]) make, lying where they stand about `centre`: a decor piece
## is itself (a pile, its parts), a stall a table, crates and a barrel (OF_STALL), a stack of crates three (OF_CRATES),
## a tree its logs (OF_TREE).
func _pieces_of(things: Array, centre: Vector2) -> Array:
	var out := []
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for thing in things:
		if thing is Decor:
			var d: Decor = thing
			if d.kind == Decor.Kind.PILE:
				if d.parts.is_empty():
					out.append(_piece(Decor.Kind.CRATES, d.at, d.seed_value))
				for p: Dictionary in d.parts:
					out.append(_piece(p.kind, p.at, int(p.seed)))
			else:
				out.append(_piece(d.kind, d.at, d.seed_value))
		elif thing is Structure:
			var s: Structure = thing
			var kinds: Array[Decor.Kind] = OF_TREE if s.kind == Structure.Kind.TREE \
				else (OF_CRATES if s.kind == Structure.Kind.CRATES else OF_STALL)
			for i in kinds.size():
				var spread := Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
				out.append(_piece(kinds[i], s.center() + spread, _seed + i * 13 + out.size()))
	return out


static func _piece(kind: Decor.Kind, at: Vector2, seed_value: int) -> Dictionary:
	return {"kind": kind, "at": at, "seed": seed_value, "scale": float(WindfallFx.SIZE.get(kind, 1.0)) * 0.8, "lift": 0.0}


## The pieces as they come down about `centre`: each where it stood about the first click, drawn in to the heap's
## footprint; the first BASE lie flat, the rest are thrown on top, each at its own size; back to front (seeded: the
## same heap is drawn falling and lying).
func _heap_of(pieces: Array, centre: Vector2) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + 7
	var out := []
	var squeeze := HEAP * 0.42 / lv_radius
	for i in pieces.size():
		var g: Dictionary = pieces[i].duplicate()
		var base := i < BASE
		g.at = centre + ((g.at as Vector2) - origin) * squeeze + Vector2(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.05))
		g.scale = float(WindfallFx.SIZE.get(g.kind, 1.0)) * (rng.randf_range(0.6, 0.9) if base else rng.randf_range(0.42, 0.7))
		g.lift = 0.0 if base else rng.randf_range(4.0, 14.0)
		g.spin = rng.randf_range(2.0, 4.5) * (1.0 if rng.randf() < 0.5 else -1.0)
		out.append(g)
	out.sort_custom(func(a, b) -> bool:
		var da: Vector2 = a.at
		var db: Vector2 = b.at
		return da.x + da.y + float(a.lift) * 0.05 < db.x + db.y + float(b.lift) * 0.05)
	for i in out.size():
		out[i].leave_t = lv_t_take + STAGGER * float(i)
		out[i].land_t = out[i].leave_t + FALL
	return out


func _ring(at_ground: Vector2) -> void:
	var ring := FxParts.shockwave(self, at_ground, lv_radius + 1.0, FxParts.ION)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.16)
	ring.life = 0.38


## The goods tumbling up into the first column: over the last RISE before the take each piece leaves its foot,
## turning, drawn in to the beam and up it, smaller as it goes, until the take swallows them.
class Rise extends Node2D:
	var fx: SkyliftFx
	var pieces: Array = []

	func _process(_delta: float) -> void:
		if fx.t >= fx.lv_t_take:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf((fx.t - (fx.lv_t_take - RISE)) / RISE, 0.0, 1.0)
		var top := Iso.ground_to_screen(fx.origin) + Vector2(0, -300)
		var i := 0
		for g in pieces:
			var own := clampf(k * 1.3 - 0.3 * ArtKit.hash01(i, 3), 0.0, 1.0)  # each leaves the ground in its own moment
			var foot := Iso.ground_to_screen(g.at)
			var p := Vector2(lerpf(foot.x, top.x, own * own), lerpf(foot.y, top.y, own * own * own))
			var rot := own * (2.5 + 2.0 * ArtKit.hash01(i, 5)) * (1.0 if i % 2 == 0 else -1.0)
			WindfallFx.paint_piece(self, g, p, rot, 1.0 - 0.7 * own)
			i += 1
		draw_set_transform(Vector2.ZERO)


## The goods on their way down out of the second column: every piece from the moment it leaves (leave_t) to the
## moment it lands (land_t), falling faster as it comes, turning less, a shadow closing under it.
class Fall extends Node2D:
	var fx: SkyliftFx

	func _process(_delta: float) -> void:
		if fx.goods.is_empty() or fx.t >= float(fx.goods[fx.goods.size() - 1].land_t) + 0.05:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var from := Iso.ground_to_screen(fx._land) + Vector2(0, -DROP_H)
		var flying := []
		for g in fx.goods:
			if fx.t < float(g.leave_t) or fx.t >= float(g.land_t):
				continue
			flying.append(g)
		for g in flying:
			var k := clampf((fx.t - float(g.leave_t)) / FALL, 0.0, 1.0)
			var to := Iso.ground_to_screen(g.at)
			draw_set_transform(to, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 3.0 + 5.0 * k, Color(0.0, 0.0, 0.0, 0.08 + 0.3 * k))
		draw_set_transform(Vector2.ZERO)
		for g in flying:
			var k := clampf((fx.t - float(g.leave_t)) / FALL, 0.0, 1.0)
			var to := Iso.ground_to_screen(g.at) + Vector2(0, -float(g.lift))
			var p := Vector2(lerpf(from.x, to.x, k), lerpf(from.y, to.y, k * k))
			var rot := float(g.spin) * (1.0 - k) * (1.0 - k)
			WindfallFx.paint_piece(self, g, p, rot, 0.5 + 0.5 * smoothstep(0.0, 0.3, k))
		draw_set_transform(Vector2.ZERO)
