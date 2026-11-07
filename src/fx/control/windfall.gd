class_name WindfallFx
extends FxTimeline
## Windfall (Passage, Tier I): a load from somewhere else, dropped out of the sky in a line. Aimed by a drag: the line
## is LENGTH long along it, centred on the press, SEG wide -- a low wall of junk, SEGMENTS heaps of it. A portal opens
## in the sky over the line (PORTAL_H px up) and the pieces come out of it one after another, GAP apart, each FLIGHT
## in the air: the first lands T_DROP after the cast, and at that moment whoever stands within KILL_R of a segment's
## middle is crushed (damage kind stone), what stands within HIT_R of one takes DAMAGE (stone: no fire), and the
## segments are set down where they fall -- structures (role windfall) that close the walk grid under them, so a
## street or a gate's mouth is barred. They are the town's to clear, and it takes time: an engineer team cuts a segment
## away (EngineerManager's Clear job, CLEAR_WEIGHT times a thorn segment's), and until then the nearest free people --
## up to CLEARERS citizens or soldiers within CALL_R, called every CALL_EVERY -- come and work at it: every second
## each one at the line (within WORK_R of a segment, not frightened; CLEARERS at most count) takes a second off the
## CLEAR_WORK it needs, and the line is taken down from its ends as the work goes. Unattended it stands LIFE. A
## segment does not fall inside a building. Loud: the fall is seen and heard (PowerBook.REACH), from the drop.
##
## The cargo is the cast's mode (Q/E; extra.mode, MODES; `cargo`), STONE when none:
## - STONE: the junk above.
## - OIL: barrels of oil that burst as they land. Whoever is under a segment dies by fire, what stands within HIT_R
##   catches (a fire blow), and nothing is set down: the line burns OIL_BURN instead. Every BURN_EVERY whoever stands
##   within BURN_R of a segment's middle burns to death (`burned`); every LIGHT_EVERY each segment lights every
##   burnable structure within LIGHT_R of it. The town keeps clear of it (a fire threat a segment, OIL_BURN long).
## - GOODS: silk and wine nobody can resist. Lands as STONE does, and then for LOOT_SPAN, every LOOT_EVERY, the nearest
##   citizens within LOOT_R (calm, outside; no soldier) are drawn to the line (`looters`), until LOOTERS stand at it.
##   Looters carry nothing away: the goods are cleared by the engineers only, or stand their LIFE.
## - PLAGUE: a grain cart from a dead village. Lands as STONE does, and every second of work each one at the line
##   catches the plague (`infected`; PlagueManager.PLAGUE_LIFE to live).
## A Mirrorfold way in under the line carries the load through to its way out (EnemyField.through()): the whole line
## lands shifted, keeping its direction, and the portal opens over where it lands (`landing_origin`).

const MODES := ["stone", "oil", "goods", "plague"]
const T_DROP := 0.8
const LENGTH := 3.6
const SEGMENTS := 6
const SEG := 0.6
const KILL_R := 0.45
const HIT_R := 0.7
const DAMAGE := 30.0
const HEIGHT := 8.0
const LIFE := 180.0
const CLEAR_WORK := 150.0
const CLEARERS := 3
## An engineer team's Clear job on one segment takes this many times a thorn segment's time.
const CLEAR_WEIGHT := 2.0
const CALL_R := 6.0
const CALL_EVERY := 3.0
const WORK_R := 1.3
## OIL: how long the line burns, how far from a segment's middle it kills (every BURN_EVERY) and lights buildings
## (every LIGHT_EVERY).
const OIL_BURN := 20.0
const BURN_R := 0.6
const BURN_EVERY := 0.25
const LIGHT_R := 0.9
const LIGHT_EVERY := 2.0
## GOODS: how many stand looting at once, from how far they are drawn, for how long and how often.
const LOOTERS := 15
const LOOT_R := 7.0
const LOOT_SPAN := 30.0
const LOOT_EVERY := 3.0
## The fall: one piece in the air FLIGHT, the next leaving the portal GAP later; the portal opens T_OPEN before the
## first leaves and closes T_CLOSE after the last, PORTAL_H px over the line's middle, PORTAL px across (half-size).
const FLIGHT := 0.42
const GAP := 0.028
const T_OPEN := 0.3
const T_CLOSE := 0.3
const PORTAL_H := 200.0
const PORTAL := Vector2(96.0, 42.0)
const WOOD := [Color("b8894a"), Color("8a6234"), Color("5a3f22"), Color("33261a")]
const SKY := Color(0.45, 0.75, 1.0)
const PALE := Color(0.8, 0.92, 1.0)
const DEEP := Color(0.03, 0.05, 0.12)
const FIRE_LIGHT := Color(1.0, 0.5, 0.18)
const GOLD := [Color("fff6c0"), Color("ffd870"), Color("e0a030"), Color(0.6, 0.4, 0.1, 0.0)]
## Person.SICK_MOTE (a8d060), fading.
const SICK := [Color("a8d060"), Color("86ab4d"), Color(0.45, 0.6, 0.25, 0.0)]

## The segments still lying there (in line order), how many it crushed, and the work still needed to clear them.
var piles: Array[Structure] = []
var crushed := 0
var work_left := CLEAR_WORK
## Whether the town cleared it (by hand or by the engineers), and how many were called to it.
var cleared := false
var called := 0
## The cargo (MODES), and where the line's middle lands (the origin, unless a passage carried it elsewhere).
var cargo := "stone"
var landing_origin := Vector2.INF
## OIL: how many the fire took; GOODS: how many were drawn to the line in all; PLAGUE: how many caught it.
var burned := 0
var looters := 0
var infected := 0

var _dir := Vector2(1, 0)
var _call_in := 0.0
var _work_in := 0.0
var _landed := false
var _seed := 0
## The heaps as planned, one Array of pieces (heap_for()) a segment of rects(); empty where a building stands.
var _heaps: Array = []
## Every piece of every heap in the order it lands, and the next one whose landing is still to be shown.
var _order: Array = []
var _next_down := 0
## The heaps as they lie: Structure -> [Heap] (one node a segment in the world layer).
var _goods := {}
## The middles of the segments that fell on open ground (OIL: the burning line).
var _line: Array[Vector2] = []
var _burn_in := 0.0
var _light_in := 0.0
var _loot_in := 0.0
var _mote_in := 0.0
var _flames: Array = []


## The segments' footprints for a line centred on `at` along `dir`.
static func rects(at: Vector2, dir: Vector2) -> Array[Rect2]:
	var unit := dir.normalized() if dir.length() > 0.01 else Vector2(1, 0)
	var out: Array[Rect2] = []
	for k in SEGMENTS:
		var c := at + unit * (-LENGTH * 0.5 + LENGTH * (float(k) + 0.5) / float(SEGMENTS))
		out.append(Rect2(c - Vector2(SEG, SEG) * 0.5, Vector2(SEG, SEG)))
	return out


## Where the portal hangs, on screen.
func portal_screen() -> Vector2:
	return Iso.ground_to_screen(landing_origin) + Vector2(0, -PORTAL_H)


## When the last piece lands.
func last_land() -> float:
	return T_DROP if _order.is_empty() else float(_order[_order.size() - 1].land_t)


## OIL: whether the line still burns.
func burning() -> bool:
	return cargo == "oil" and _landed and not _line.is_empty() and t < T_DROP + OIL_BURN


func _build() -> void:
	_dir = extra.get("dir", Vector2(1, 0))
	if _dir.length() < 0.01:
		_dir = Vector2(1, 0)
	_dir = _dir.normalized()
	cargo = String(extra.get("mode", "stone"))
	if not cargo in MODES:
		cargo = "stone"
	_seed = int(ctx.rng.randi() % 100000)
	landing_origin = _resolve_landing()
	_plan()
	duration = T_DROP + (OIL_BURN if cargo == "oil" else LIFE) + 0.5
	busy = T_DROP
	at(T_DROP, _land)
	var opens := T_DROP - FLIGHT - T_OPEN
	at(opens, func(): ctx.play(&"cf_fall", landing_origin, 6.0))
	if not DominionParts.staged(self):
		return
	for r in rects(landing_origin, _dir):
		var mark := FxParts.rings(self, r.get_center(), HIT_R, Color("ffb060"), 1, 6.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_DROP * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_DROP + 0.05
	var closes := last_land() - FLIGHT + T_CLOSE
	var sp := portal_screen()
	# The hole in the sky: the screen swirled into it, a glow about it, and the drawn mouth over both.
	var swirl := FxParts.singularity(self, landing_origin, 1.9, FxParts.ICE)
	swirl.position = sp
	swirl.set_param("strength", 0.0)
	swirl.set_param("pinch", 0.0)
	swirl.set_param("core_px", 0.0)
	swirl.set_param("arm_alpha", 0.0)
	swirl.set_param("rim_boost", 0.0)
	swirl.set_param("tint", 0.4)
	swirl.tween_param("strength", 0.0, 1.0, T_OPEN, opens, Tween.TRANS_QUAD, Tween.EASE_OUT)
	swirl.tween_param("pinch", 0.0, 0.5, T_OPEN, opens, Tween.TRANS_QUAD, Tween.EASE_OUT)
	swirl.tween_param("arm_alpha", 0.0, 0.6, T_OPEN, opens)
	swirl.tween_param("strength", 1.0, 0.0, T_CLOSE, closes, Tween.TRANS_QUAD, Tween.EASE_IN)
	swirl.tween_param("arm_alpha", 0.6, 0.0, T_CLOSE, closes)
	swirl.tween_param("alpha", 1.0, 0.0, 0.1, closes + T_CLOSE - 0.1)
	swirl.life = closes + T_CLOSE + 0.05
	var glow := FxParts.bloom(self, sp, 130.0, SKY, 0.0, 0.6)
	glow.z_index = 4
	glow.tween_param("intensity", 0.0, 0.9, T_OPEN, opens, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.tween_param("intensity", 0.9, 0.0, T_CLOSE, closes, Tween.TRANS_QUAD, Tween.EASE_IN)
	glow.life = closes + T_CLOSE + 0.05
	var mouth := Portal.new()
	mouth.fx = self
	mouth.opens = opens
	mouth.closes = closes
	mouth.position = sp
	mouth.z_index = 5
	track(mouth, ctx.overhead)
	var load := Load.new()
	load.fx = self
	load.z_index = 6
	track(load, ctx.overhead)


## Where the line's middle comes down: the origin, unless an open passage (EnemyField.through()) carries the origin
## -- or, failing that, one of the segments' middles -- somewhere else; then the whole line goes by the same shift.
func _resolve_landing() -> Vector2:
	var across := ctx.field.through(origin)
	if across != origin:
		return across
	for r in rects(origin, _dir):
		var c := r.get_center()
		var out := ctx.field.through(c)
		if out != c:
			return origin + (out - c)
	return origin


## The heap planned for segment `k` at `c`: the cargo's kinds and tints.
func _heap(k: int, c: Vector2) -> Array:
	match cargo:
		"oil":
			return heap_for(k, c, _dir, _seed + k * 97, OIL_KINDS)
		"goods":
			return heap_for(k, c, _dir, _seed + k * 97, WARES, WARE_TINTS)
		"plague":
			return heap_for(k, c, _dir, _seed + k * 97, KINDS, PLAGUE_TINTS)
	return heap_for(k, c, _dir, _seed + k * 97)


## Lay out every heap and the order its pieces come down: the ground layer of all the heaps first, then what lies on
## top of it, each layer in a shuffled order along the line, GAP apart.
func _plan() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	_heaps = []
	var all := rects(landing_origin, _dir)
	var base := []
	var top := []
	for k in all.size():
		var c := all[k].get_center()
		if ctx.env.blocked(c, 0.0):
			_heaps.append([])
			continue
		var heap := _heap(k, c)
		_heaps.append(heap)
		for g in heap:
			(base if float(g.lift) == 0.0 else top).append(g)
	_shuffle(base, rng)
	_shuffle(top, rng)
	_order = base + top
	for i in _order.size():
		var g: Dictionary = _order[i]
		g.land_t = T_DROP + GAP * float(i)
		g.leave_t = g.land_t - FLIGHT
		g.spin = rng.randf_range(2.0, 4.5) * (1.0 if rng.randf() < 0.5 else -1.0)
	_next_down = 0


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var held = a[i]
		a[i] = a[j]
		a[j] = held


func _land() -> void:
	_landed = true
	# A passage opened since the cast carries the load elsewhere: the line is laid out again where it comes down.
	var moved := _resolve_landing()
	if moved != landing_origin:
		landing_origin = moved
		_plan()
	var all := rects(landing_origin, _dir)
	_line = []
	for r in all:
		if not ctx.env.blocked(r.get_center(), 0.0):
			_line.append(r.get_center())
	if cargo == "oil":
		_burst()
		return
	# The blows first, the whole line at once, then the segments: a segment's own blow must not break the one before.
	for r in all:
		var c := r.get_center()
		for e in ctx.field.in_radius(c, KILL_R):
			var p := e as Person
			if p != null and p.inside:
				continue
			if ctx.field.kill(e, &"stone", c):
				crushed += 1
		ctx.env.damage_radius(c, HIT_R, DAMAGE, &"stone")
	var placed: Array[int] = []
	for k in all.size():
		var r := all[k]
		var c := r.get_center()
		if ctx.env.blocked(c, 0.0):
			continue  # not inside a building
		# Whoever stands where it lies (and lived) is pushed just clear of the line.
		for e in ctx.field.in_radius(c, SEG):
			if r.grow(0.15).has_point(e.ground_pos):
				var side := Vector2(-_dir.y, _dir.x)
				var away := (e.ground_pos - c).dot(side)
				var out := side * (1.0 if away >= 0.0 else -1.0)
				for d: float in [0.7, 1.0, 1.3]:
					if not ctx.env.blocked(c + out * d):
						e.ground_pos = c + out * d
						break
		var s := ctx.env.add_structure(r, HEIGHT, Structure.Kind.CRATES, &"windfall")
		piles.append(s)
		placed.append(k)
	ctx.play(&"cf_impact", landing_origin, 0.0)
	ctx.play(&"jg_crumble", landing_origin, 2.0)
	if piles.is_empty():
		duration = minf(duration, t + 1.5)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(1.0, 0.9, 0.7, 0.14), 0.2)
	ctx.impact.hitstop(0.04)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	var ring := FxParts.shockwave(self, landing_origin, LENGTH * 0.5 + 0.8, FxParts.FIRE)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.8, 0.0, 0.2, 0.15)
	ring.life = 0.38
	# The structures are only the obstacle: the goods themselves are a heap a segment -- crates, barrels, logs, stone,
	# a cart, a table from the town's decor sprites, thrown down on each other -- standing in the world layer. A heap
	# shows each piece as it lands.
	for i in piles.size():
		var s := piles[i]
		s.visible = false
		var k := placed[i]
		var h := Heap.new()
		h.fx = self
		h.pieces = _heaps[k] if k < _heaps.size() else _heap(k, s.center())
		h.position = Iso.ground_to_screen(s.center())
		track(h, ctx.world)
		_goods[s] = [h]


## OIL: the barrels burst where they land. Whoever is under a segment burns, what stands within HIT_R of one takes a
## fire blow (and catches, FireManager), nothing is set down, and the line burns from here (_burn()). A fire threat a
## segment keeps the town clear of it.
func _burst() -> void:
	for c in _line:
		for e in ctx.field.in_radius(c, KILL_R):
			var p := e as Person
			if p != null and p.inside:
				continue
			if ctx.field.kill(e, &"fire", c):
				burned += 1
		ctx.env.damage_radius(c, HIT_R, DAMAGE, &"fire")
		if ctx.crowd != null:
			ctx.crowd.threats.register(c, BURN_R + 0.4, 0.6, OIL_BURN, 5.0, 7.0, &"fire")
	_burn_in = BURN_EVERY
	_light_in = LIGHT_EVERY
	ctx.play(&"cf_erupt", landing_origin, 0.0)
	if _line.is_empty():
		duration = minf(duration, t + 1.5)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(1.0, 0.6, 0.3, 0.18), 0.25)
	ctx.impact.hitstop(0.04)
	ctx.shake.add_trauma(0.45)
	ctx.shake.kick(Vector2(0, 3))
	var ring := FxParts.shockwave(self, landing_origin, LENGTH * 0.5 + 0.8, FxParts.FIRE)
	ring.set_param("thickness", 0.12)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.9, 0.0, 0.2, 0.15)
	ring.life = 0.38
	var fade_at := OIL_BURN - 3.0
	for c in _line:
		var sp := Iso.ground_to_screen(c)
		# The burst: a flare, sparks thrown up and out, and the ground lit.
		var flare := FxParts.bloom(self, sp + Vector2(0, -10), 46.0, Color("ff7a24"), 1.3, 0.7)
		flare.tween_param("intensity", 1.3, 0.0, 0.45, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
		flare.life = 0.5
		FxParts.sparks(self, ctx.overhead, sp, 22, FxParts.FIRE_LIFE, Vector2(50, 200), Vector2(60, 240))
		FxParts.smoke(self, sp, 8.0, 30.0, 0.3, Vector2(30, 70), Vector2(4, 7), Vector2(0.8, 1.4), Color("ff5a1a"))
		var light := FxParts.ground_light(self, c, 1.3, FIRE_LIGHT, 1.0)
		light.set_param("flicker", 1.0)
		light.tween_param("intensity", 1.0, 0.0, 3.0, fade_at, Tween.TRANS_QUAD, Tween.EASE_IN)
		light.life = OIL_BURN + 0.1
		# The fire line: tongues of flame on the ground, streaks of fire and embers off them, and smoke over it all,
		# dying down over the last three seconds.
		for j in 2:
			var flame := FlameSprite.new()
			flame.size = ctx.rng.randf_range(0.7, 1.1)
			flame.setup(ctx.rng, ctx.rng.randi_range(3, 5))
			flame.position = (sp + Vector2(ctx.rng.randf_range(-8.0, 8.0), ctx.rng.randf_range(-3.0, 3.0))).round()
			track(flame, stand_layer())
			var tw := flame.create_tween()
			tw.tween_property(flame, "strength", 1.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(fade_at - 0.3 + ctx.rng.randf_range(-0.4, 0.4))
			tw.tween_property(flame, "strength", 0.0, 2.6)
			_flames.append(flame)
		var tongues := FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -3), PixelParticles.Shape.STREAK, FxParts.FIRE,
			16.0, fade_at + 1.5, {"radius": 9.0, "speed": Vector2(2, 9), "alt_speed": Vector2(26, 64),
			"life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})
		tongues.gravity = -40.0
		tongues.drag = 1.2
		var embers := FxParts.emitter(self, ctx.overhead, sp + Vector2(0, -12), PixelParticles.Shape.SQUARE, FxParts.EMBER_LIFE,
			6.0, fade_at + 2.0, {"radius": 8.0, "alt_speed": Vector2(20, 55), "life": Vector2(0.4, 1.0), "size": Vector2(1, 1)})
		embers.gravity = -10.0
		FxParts.smoke(self, sp, 7.0, 1.6, OIL_BURN - 1.5, Vector2(14, 34), Vector2(3, 5), Vector2(1.2, 2.2), Color("c04a18"))
	var half := Iso.radius_to_screen(LENGTH * 0.5 + 0.4)
	var haze := FxParts.heat_haze(self, Iso.ground_to_screen(landing_origin) + Vector2(0, -16), half.x, 1.6)
	haze.tween_param("strength", 1.6, 0.0, 3.0, fade_at)
	haze.life = OIL_BURN + 0.1


## OIL, after the burst: every BURN_EVERY the fire takes whoever stands within BURN_R of a segment; every LIGHT_EVERY it
## lights every burnable structure within LIGHT_R of one. Out after OIL_BURN.
func _burn(delta: float) -> void:
	if t >= T_DROP + OIL_BURN or _line.is_empty():
		duration = minf(duration, t + 0.5)
		return
	_burn_in -= delta
	if _burn_in <= 0.0:
		_burn_in = BURN_EVERY
		for c in _line:
			for e in ctx.field.in_radius(c, BURN_R):
				var p := e as Person
				if p != null and p.inside:
					continue
				if ctx.field.kill(e, &"fire", c):
					burned += 1
	_light_in -= delta
	if _light_in <= 0.0:
		_light_in = LIGHT_EVERY
		if ctx.crowd != null:
			for c in _line:
				for s in ctx.env.near(c, LIGHT_R):
					if s.distance_to(c) <= LIGHT_R:
						ctx.crowd.fires.ignite(s, 0.5)


## Whether any of the line still lies there.
func standing() -> bool:
	_prune()
	return not piles.is_empty()


## Forget segments gone by other hands (the engineers, a blast).
func _prune() -> void:
	var kept: Array[Structure] = []
	for s in piles:
		if is_instance_valid(s) and not s.destroyed and ctx.env.structures().has(s):
			kept.append(s)
	piles = kept


## The segments' middles, in line order.
func centres() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for s in piles:
		if is_instance_valid(s):
			out.append(s.center())
	return out


func _fx_process(delta: float) -> void:
	if not _landed:
		return
	_show_landings()
	if cargo == "oil":
		_burn(delta)
		return
	if not standing():
		cleared = cleared or t < T_DROP + LIFE
		_drop_goods_of_gone()
		duration = minf(duration, t + 0.5)
		return
	_drop_goods_of_gone()
	if t >= T_DROP + LIFE:
		_remove_all()
		return
	_work_in -= delta
	if _work_in <= 0.0:
		_work_in = 1.0
		var hands := _workers()
		if cargo == "plague":
			_sicken(hands)
		work_left -= float(mini(hands.size(), CLEARERS))  # only so many hands fit along it
		# The line comes down from its ends as the work goes: as many segments stand as the work left warrants.
		var keep := int(ceil(float(SEGMENTS) * clampf(work_left / CLEAR_WORK, 0.0, 1.0)))
		while piles.size() > keep:
			var s: Structure = piles.pop_back() if piles.size() % 2 == 0 else piles.pop_front()
			_take_away(s)
		if piles.is_empty():
			cleared = true
			duration = minf(duration, t + 0.5)
			return
	if cargo == "goods":
		# Nobody is called to clear silk and wine: they are drawn to it, while the lure lasts.
		if t < T_DROP + LOOT_SPAN:
			_loot_in -= delta
			if _loot_in <= 0.0:
				_loot_in = LOOT_EVERY
				_loot()
			_glitter(delta)
		return
	if cargo == "plague":
		_reek(delta)
	_call_in -= delta
	if _call_in <= 0.0:
		_call_in = CALL_EVERY
		_call()


## Each piece as it hits: a puff of dust and splinters at its foot, a thud for every fourth, a nudge of the ground.
func _show_landings() -> void:
	if not DominionParts.staged(self):
		_next_down = _order.size()
		return
	while _next_down < _order.size() and float(_order[_next_down].land_t) <= t:
		var g: Dictionary = _order[_next_down]
		var sp := Iso.ground_to_screen(g.at)
		var bits: Array = FxParts.ROCK if g.kind == Decor.Kind.ROCK else WOOD
		FxParts.debris(self, sp, 3, 4.0, Vector2(30, 120), bits, Vector2(1.5, 3.0), true)
		FxParts.smoke(self, sp, 5.0, 8.0, 0.25, Vector2(10, 26), Vector2(2, 4), Vector2(0.5, 0.9))
		ctx.shake.kick(Vector2(0, 0.6))
		if _next_down % 4 == 0:
			ctx.play(&"jg_crumble", g.at, -8.0)
		_next_down += 1


## Those at the line and able to work: alive, outside, not frightened or fighting. Nobody works at GOODS: looters
## carry nothing away.
func _workers() -> Array[Person]:
	var out: Array[Person] = []
	if cargo == "goods":
		return out
	for c in centres():
		for e in ctx.field.in_radius(c, WORK_R):
			var p := e as Person
			if p == null or p.inside or not p.is_alive() or out.has(p):
				continue
			if p.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.FIGHT, Person.Mind.CONFUSED, Person.Mind.ASLEEP, Person.Mind.SHELTER]:
				continue
			out.append(p)
	return out


## The segment's middle nearest `p`, and a spot to stand beside it (just off the line, on walkable ground).
func _nearest_centre(p: Person) -> Vector2:
	var nearest := Vector2.INF
	for c in centres():
		if nearest == Vector2.INF or c.distance_to(p.ground_pos) < nearest.distance_to(p.ground_pos):
			nearest = c
	return nearest


func _spot_beside(c: Vector2, p: Person) -> Vector2:
	var side := Vector2(-_dir.y, _dir.x) * (1.0 if ctx.rng.randf() < 0.5 else -1.0)
	var spot := c + side * (SEG * 0.5 + 0.45)
	if p.grid != null:
		var w := p.grid.nearest_walkable(spot)
		if w != Vector2.INF:
			spot = w
	return spot


## The nearest free people are called to it, until CLEARERS are at it.
func _call() -> void:
	var need := CLEARERS - _workers().size()
	if need <= 0 or piles.is_empty():
		return
	for p in DominionParts.near(ctx.field, landing_origin, CALL_R):
		if need <= 0:
			break
		var nearest := _nearest_centre(p)
		if nearest.distance_to(p.ground_pos) <= WORK_R:
			continue
		if p.lure(_spot_beside(nearest, p), CALL_EVERY * 2.0):
			called += 1
			need -= 1


## GOODS: the nearest calm citizens within LOOT_R are drawn to the line, until LOOTERS stand at it.
func _loot() -> void:
	var cs := centres()
	if cs.is_empty():
		return
	var at_line: Array[Person] = []
	for c in cs:
		for e in ctx.field.in_radius(c, WORK_R):
			var p := e as Person
			if p != null and not p.inside and p.is_alive() and not at_line.has(p):
				at_line.append(p)
	var need := LOOTERS - at_line.size()
	for p in DominionParts.near(ctx.field, landing_origin, LOOT_R):
		if need <= 0:
			break
		if p.soldier or not p.is_alive() or not p.mind in Person.LURABLE or at_line.has(p):
			continue
		var nearest := _nearest_centre(p)
		if nearest.distance_to(p.ground_pos) <= WORK_R:
			continue
		if p.lure(_spot_beside(nearest, p), LOOT_EVERY * 2.0):
			looters += 1
			need -= 1
	ctx.play(&"q_wisp", landing_origin, -2.0)
	if DominionParts.staged(self):
		DominionParts.pulse(self, landing_origin, LENGTH * 0.5 + 0.6, Color("ffd870"), 0.45, 1.2)


## PLAGUE: every second of work, each one at the line catches it.
func _sicken(hands: Array[Person]) -> void:
	for p in hands:
		if p.infect(PlagueManager.PLAGUE_LIFE):
			if infected == 0:
				ctx.play(&"q_pestilence", landing_origin, -3.0)
			infected += 1
			if DominionParts.staged(self):
				DominionParts.motes(self, p.ground_pos, SICK, 10)


## GOODS: gold motes drift up off the heaps while the lure runs.
func _glitter(delta: float) -> void:
	if not DominionParts.staged(self):
		return
	_mote_in -= delta
	if _mote_in <= 0.0:
		_mote_in = 0.45
		for c in centres():
			DominionParts.motes(self, c, GOLD, 3)


## PLAGUE: a sickly green haze of motes off the grain.
func _reek(delta: float) -> void:
	if not DominionParts.staged(self):
		return
	_mote_in -= delta
	if _mote_in <= 0.0:
		_mote_in = 0.7
		for c in centres():
			DominionParts.motes(self, c, SICK, 2)


## The goods of a segment that is gone (cleared, cut away, smashed) go with it.
func _drop_goods_of_gone() -> void:
	for s in _goods.keys():
		# Checked before the typed lookup: a segment the engineers cut away is freed, and a freed key errors in has().
		if is_instance_valid(s) and piles.has(s):
			continue
		for d in _goods[s]:
			if is_instance_valid(d):
				d.queue_free()
		_goods.erase(s)


## The heap on segment `k` of the line, at its middle `c` along `dir`: [{kind, at, seed, scale, lift, tint}], back to
## front. PIECES_PER of them, a junk yard's worth thrown down on each other: crates, barrels, logs, stone, a cart, a
## table (KINDS, SIZE each), each at its own spot within the segment, its own size, and all past the first BASE lifted
## onto the earlier -- a jumble, not a row. Seeded: the same heap is drawn falling and lying. Another cargo passes its
## own `kinds` (OIL_KINDS, WARES) and `tints` (one a piece, drawn from the list; WHITE when none).
const PIECES_PER := Vector2i(8, 12)
const BASE := 4
const KINDS: Array[Decor.Kind] = [
	Decor.Kind.CRATES, Decor.Kind.BARREL, Decor.Kind.ROCK, Decor.Kind.LOGS, Decor.Kind.CRATES, Decor.Kind.BARREL,
	Decor.Kind.CART, Decor.Kind.TABLE, Decor.Kind.ROCK, Decor.Kind.CRATES, Decor.Kind.BARREL, Decor.Kind.LOGS,
]
const OIL_KINDS: Array[Decor.Kind] = [Decor.Kind.BARREL]
const WARES: Array[Decor.Kind] = [Decor.Kind.BARREL, Decor.Kind.CRATES, Decor.Kind.TABLE, Decor.Kind.BARREL, Decor.Kind.CRATES]
## Bolts of silk (purples) and wine (reds); grain gone bad (greens).
const WARE_TINTS := [Color("c080d8"), Color("b04060"), Color("9050b8"), Color("d06080"), Color("e0a0e8")]
const PLAGUE_TINTS := [Color("b8d890"), Color("a0c070"), Color("c8d8a0")]
## How large a kind is drawn against the others (a cart is a big thing).
const SIZE := {Decor.Kind.CART: 0.55, Decor.Kind.TABLE: 0.75, Decor.Kind.LOGS: 0.85}

static func heap_for(k: int, c: Vector2, dir: Vector2, seed_value: int, kinds: Array = KINDS, tints: Array = []) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var side := Vector2(-dir.y, dir.x)
	var out := []
	var n := rng.randi_range(PIECES_PER.x, PIECES_PER.y)
	for i in n:
		var kind: Decor.Kind = kinds[rng.randi() % kinds.size()]
		var along := rng.randf_range(-0.28, 0.28)
		var across := rng.randf_range(-0.22, 0.22)
		var base := i < BASE
		var size: float = SIZE.get(kind, 1.0)
		out.append({
			"kind": kind,
			"at": c + dir * along + side * across,
			"seed": seed_value + i * 13 + k,
			"scale": size * (rng.randf_range(0.6, 0.9) if base else rng.randf_range(0.42, 0.7)),
			"lift": 0.0 if base else rng.randf_range(4.0, 14.0),
			"tint": tints[rng.randi() % tints.size()] if not tints.is_empty() else Color.WHITE,
		})
	# Back to front, the lifted ones last so they sit on top.
	out.sort_custom(func(a, b) -> bool:
		var da: Vector2 = a.at
		var db: Vector2 = b.at
		return da.x + da.y + float(a.lift) * 0.05 < db.x + db.y + float(b.lift) * 0.05)
	return out


func _take_away(s: Structure) -> void:
	if is_instance_valid(s) and ctx.env.structures().has(s):
		var at_pile := s.center()
		ctx.env.remove(s)
		if DominionParts.staged(self):
			FxParts.debris(self, Iso.ground_to_screen(at_pile), 6, 5.0, Vector2(20, 90), WOOD, Vector2(1.5, 3.0), true)
			FxParts.debris(self, Iso.ground_to_screen(at_pile), 4, 4.0, Vector2(20, 70), FxParts.ROCK, Vector2(1.5, 2.5), true)


func _remove_all() -> void:
	for s in piles.duplicate():
		_take_away(s)
	piles.clear()
	_drop_goods_of_gone()
	duration = minf(duration, t + 0.5)


## Cut short (FxTimeline.end_now()): the line goes with it, or it would block the way for good; a burning line is out.
func end_now() -> void:
	_remove_all()
	_line = []
	super()


## One segment's heap, lying: its pieces painted from the decor sprites, each at its own spot and size, the later ones
## lifted onto the earlier, each shown from the moment it lands. One node a segment in the world layer, so people
## sort round it.
class Heap extends Node2D:
	var fx: WindfallFx
	var pieces: Array = []

	func _process(_delta: float) -> void:
		if fx != null and fx.t <= fx.last_land() + 0.1:
			queue_redraw()

	func _draw() -> void:
		var now := fx.t if fx != null else INF
		for g in pieces:
			if float(g.get("land_t", 0.0)) <= now:
				WindfallFx.paint_piece(self, g, Iso.ground_to_screen(g.at) - position + Vector2(0, -float(g.lift)), 0.0, 1.0)
		draw_set_transform(Vector2.ZERO)


## Paint one piece (heap_for()) on `ci` with its foot at `foot` (in ci's space), turned `rot` and scaled a further
## `mul` about the foot, in the piece's tint (WHITE when it has none).
static func paint_piece(ci: CanvasItem, g: Dictionary, foot: Vector2, rot: float, mul: float) -> void:
	var key := String(Decor.Kind.keys()[g.kind]).to_lower()
	var sc: float = g.scale * mul * ArtTuning.scale(key)
	# Scaled about its own foot: the painter is told its foot is the origin, and the transform puts it there.
	ci.draw_set_transform(foot.round(), rot, Vector2(sc, sc))
	ArtKit.begin()
	ArtKit.color_mul = ArtTuning.tint(key) * (g.get("tint", Color.WHITE) as Color)
	DecorArt.paint(g.kind, g.at, Vector2.ZERO, g.seed, Iso.ground_to_screen(g.at))
	ArtKit.color_mul = Color.WHITE
	ArtKit.flush(ci)


## The load on its way down: every piece from the moment it leaves the portal to the moment it lands, tumbling out
## of the mouth small and growing as it comes, sliding across to its own foot and falling faster as it goes, a shadow
## closing under it.
class Load extends Node2D:
	var fx: WindfallFx

	func _process(_delta: float) -> void:
		if fx.t >= fx.last_land() + 0.05:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var from := fx.portal_screen()
		var flying := []
		for g in fx._order:
			if fx.t < float(g.leave_t) or fx.t >= float(g.land_t):
				continue
			flying.append(g)
		for g in flying:
			var k := clampf((fx.t - float(g.leave_t)) / FLIGHT, 0.0, 1.0)
			var to := Iso.ground_to_screen(g.at)
			draw_set_transform(to, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 3.0 + 5.0 * k, Color(0.0, 0.0, 0.0, 0.08 + 0.3 * k))
		draw_set_transform(Vector2.ZERO)
		for g in flying:
			var k := clampf((fx.t - float(g.leave_t)) / FLIGHT, 0.0, 1.0)
			var to := Iso.ground_to_screen(g.at) + Vector2(0, -float(g.lift))
			var p := Vector2(lerpf(from.x, to.x, k), lerpf(from.y, to.y, k * k))
			var grow := smoothstep(0.0, 0.18, k)
			var rot := float(g.spin) * (1.0 - k) * (1.0 - k)
			WindfallFx.paint_piece(self, g, p, rot, 0.35 + 0.65 * grow)
		draw_set_transform(Vector2.ZERO)


## The hole in the sky the load comes out of: a dark mouth, PORTAL half-size when open, with a pale rim, a glint
## running round it, arcs of light turning inside, and sparks off its edge. Opens over T_OPEN from `opens`, closes
## over T_CLOSE from `closes`.
class Portal extends Node2D:
	var fx: WindfallFx
	var opens := 0.0
	var closes := 1.0

	func _process(_delta: float) -> void:
		if fx.t >= closes + T_CLOSE:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var age := fx.t - opens
		if age < 0.0:
			return
		var k := clampf(age / T_OPEN, 0.0, 1.0)
		var p := 1.0 - pow(1.0 - k, 3.0)
		p *= 1.0 + 0.12 * sin(k * PI)  # a touch of overshoot as it tears open
		if fx.t > closes:
			p *= 1.0 - clampf((fx.t - closes) / T_CLOSE, 0.0, 1.0)
		if p <= 0.01:
			return
		var w := PORTAL.x * p
		var squash := PORTAL.y / PORTAL.x
		var spin := age * 2.4
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, squash))
		# The mouth: dark, deepening to the middle.
		draw_circle(Vector2.ZERO, w, Color(DEEP, 0.85))
		draw_circle(Vector2.ZERO, w * 0.55, Color(0.0, 0.0, 0.02, 0.95))
		# Arcs of light turning inside.
		for j in 4:
			var a0 := spin * (1.0 + 0.3 * float(j)) + float(j) * 1.7
			var r := w * (0.35 + 0.15 * float(j))
			draw_arc(Vector2.ZERO, r, a0, a0 + 1.6 + 0.4 * float(j % 2), 20, Color(SKY, 0.35 + 0.15 * float(j % 2)), 2.0)
		# The rim and its glint.
		draw_arc(Vector2.ZERO, w, 0.0, TAU, 48, Color(PALE, 0.95), 3.0)
		draw_arc(Vector2.ZERO, w + 3.0, 0.0, TAU, 48, Color(SKY, 0.35), 2.0)
		var ga := -spin * 1.6
		draw_arc(Vector2.ZERO, w, ga, ga + 0.9, 12, Color(1, 1, 1, 0.9), 4.0)
		# Sparks off the edge, flickering.
		var tick := int(age * 24.0)
		for i in 14:
			var a := float(i) / 14.0 * TAU + spin * 0.3
			var h := ArtKit.hash01(i, tick)
			if h < 0.35:
				continue
			var d := Vector2(cos(a), sin(a))
			draw_line(d * (w + 2.0), d * (w + 5.0 + 10.0 * h), Color(PALE, 0.5 + 0.4 * h), 1.0)
		draw_set_transform(Vector2.ZERO)
