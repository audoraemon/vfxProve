class_name WindfallFx
extends FxTimeline
## Windfall (Passage, Tier I): a load from somewhere else, dropped out of the sky in a line. Aimed by a drag: the line
## is LENGTH long along it, centred on the press, SEG wide -- a low wall of crates and stone, SEGMENTS of them. T_DROP
## after the cast they come down: whoever stands within KILL_R of a segment's middle is crushed (damage kind stone),
## what stands within HIT_R of one takes DAMAGE (stone: no fire), and the segments stay where they fell -- structures
## (role windfall) that close the walk grid under them, so a street or a gate's mouth is barred. They are the town's to
## clear, and it takes time: an engineer team cuts a segment away (EngineerManager's Clear job, CLEAR_WEIGHT times a
## thorn segment's), and until then the nearest free people -- up to CLEARERS citizens or soldiers within CALL_R, called
## every CALL_EVERY -- come and work at it: every second each one at the line (within WORK_R of a segment, not
## frightened; CLEARERS at most count) takes a second off the CLEAR_WORK it needs, and the line is taken down from
## its ends as the work goes. Unattended it stands LIFE. A segment does not fall inside a building. Loud: the fall is
## seen and heard (PowerBook.REACH), from the drop.

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
const FALL := 380.0
const WOOD := [Color("b8894a"), Color("8a6234"), Color("5a3f22"), Color("33261a")]

## The segments still lying there (in line order), how many it crushed, and the work still needed to clear them.
var piles: Array[Structure] = []
var crushed := 0
var work_left := CLEAR_WORK
## Whether the town cleared it (by hand or by the engineers), and how many were called to it.
var cleared := false
var called := 0

var _dir := Vector2(1, 0)
var _call_in := 0.0
var _work_in := 0.0
var _landed := false
var _seed := 0
## The goods as they lie: Structure -> [Decor] (the town's own decor, drawn from its sprites, in the world layer).
var _goods := {}


## The segments' footprints for a line centred on `at` along `dir`.
static func rects(at: Vector2, dir: Vector2) -> Array[Rect2]:
	var unit := dir.normalized() if dir.length() > 0.01 else Vector2(1, 0)
	var out: Array[Rect2] = []
	for k in SEGMENTS:
		var c := at + unit * (-LENGTH * 0.5 + LENGTH * (float(k) + 0.5) / float(SEGMENTS))
		out.append(Rect2(c - Vector2(SEG, SEG) * 0.5, Vector2(SEG, SEG)))
	return out


func _build() -> void:
	_dir = extra.get("dir", Vector2(1, 0))
	if _dir.length() < 0.01:
		_dir = Vector2(1, 0)
	_dir = _dir.normalized()
	_seed = int(ctx.rng.randi() % 100000)
	duration = T_DROP + LIFE + 0.5
	busy = T_DROP
	at(T_DROP, _land)
	ctx.play(&"cf_fall", origin, 6.0)
	if not DominionParts.staged(self):
		return
	for r in rects(origin, _dir):
		var mark := FxParts.rings(self, r.get_center(), HIT_R, Color("ffb060"), 1, 6.0)
		mark.set_param("scan", 0.0)
		mark.tween_param("reveal", 0.0, 1.0, T_DROP * 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		mark.life = T_DROP + 0.05
	var load := Load.new()
	load.fx = self
	load.z_index = 6
	track(load, ctx.overhead)


func _land() -> void:
	_landed = true
	var centres: Array[Vector2] = []
	var all := rects(origin, _dir)
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
	for r in all:
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
		centres.append(c)
	ctx.play(&"cf_impact", origin, 0.0)
	ctx.play(&"jg_crumble", origin, 2.0)
	if piles.is_empty():
		duration = minf(duration, t + 1.5)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(1.0, 0.9, 0.7, 0.14), 0.2)
	ctx.impact.hitstop(0.04)
	ctx.shake.add_trauma(0.4)
	ctx.shake.kick(Vector2(0, 3))
	for c in centres:
		var sp := Iso.ground_to_screen(c)
		FxParts.debris(self, sp, 6, 6.0, Vector2(40, 180), WOOD, Vector2(1.5, 3.5), true)
		FxParts.debris(self, sp, 3, 5.0, Vector2(30, 140), FxParts.ROCK, Vector2(1.5, 3.0), true)
		FxParts.smoke(self, sp, 6.0, 10.0, 0.5, Vector2(14, 36), Vector2(2, 5), Vector2(0.8, 1.4))
	var ring := FxParts.shockwave(self, origin, LENGTH * 0.5 + 0.8, FxParts.FIRE)
	ring.set_param("thickness", 0.1)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 0.8, 0.0, 0.2, 0.15)
	ring.life = 0.38
	# The structures are only the obstacle: the goods themselves are a heap a segment -- crates, barrels, logs and
	# stone from the town's decor sprites, thrown down on each other -- standing in the world layer.
	for i in piles.size():
		var s := piles[i]
		s.visible = false
		var h := Heap.new()
		h.pieces = heap_for(i, s.center(), _dir, _seed + i * 97)
		h.position = Iso.ground_to_screen(s.center())
		track(h, ctx.world)
		_goods[s] = [h]


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
		work_left -= float(mini(_workers().size(), CLEARERS))  # only so many hands fit along it
		# The line comes down from its ends as the work goes: as many segments stand as the work left warrants.
		var keep := int(ceil(float(SEGMENTS) * clampf(work_left / CLEAR_WORK, 0.0, 1.0)))
		while piles.size() > keep:
			var s: Structure = piles.pop_back() if piles.size() % 2 == 0 else piles.pop_front()
			_take_away(s)
		if piles.is_empty():
			cleared = true
			duration = minf(duration, t + 0.5)
			return
	_call_in -= delta
	if _call_in <= 0.0:
		_call_in = CALL_EVERY
		_call()


## Those at the line and able to work: alive, outside, not frightened or fighting.
func _workers() -> Array[Person]:
	var out: Array[Person] = []
	for c in centres():
		for e in ctx.field.in_radius(c, WORK_R):
			var p := e as Person
			if p == null or p.inside or not p.is_alive() or out.has(p):
				continue
			if p.mind in [Person.Mind.PANIC, Person.Mind.FLEE, Person.Mind.FIGHT, Person.Mind.CONFUSED, Person.Mind.ASLEEP, Person.Mind.SHELTER]:
				continue
			out.append(p)
	return out


## The nearest free people are called to it, until CLEARERS are at it.
func _call() -> void:
	var need := CLEARERS - _workers().size()
	if need <= 0 or piles.is_empty():
		return
	for p in DominionParts.near(ctx.field, origin, CALL_R):
		if need <= 0:
			break
		var nearest := Vector2.INF
		for c in centres():
			if nearest == Vector2.INF or c.distance_to(p.ground_pos) < nearest.distance_to(p.ground_pos):
				nearest = c
		if nearest.distance_to(p.ground_pos) <= WORK_R:
			continue
		var side := Vector2(-_dir.y, _dir.x) * (1.0 if ctx.rng.randf() < 0.5 else -1.0)
		var spot := nearest + side * (SEG * 0.5 + 0.45)
		if p.grid != null:
			var w := p.grid.nearest_walkable(spot)
			if w != Vector2.INF:
				spot = w
		if p.lure(spot, CALL_EVERY * 2.0):
			called += 1
			need -= 1


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


## The heap on segment `k` of the line, at its middle `c` along `dir`: [{kind, at, seed, scale, lift}], back to front.
## PIECES_PER of them, thrown down on each other: crates, barrels, logs and stone (KINDS), each at its own spot within
## the segment, its own size, and the later ones lifted onto the earlier -- a jumble, not a row. Seeded: the same heap
## is drawn falling and lying.
const PIECES_PER := Vector2i(4, 6)
const KINDS: Array[Decor.Kind] = [Decor.Kind.CRATES, Decor.Kind.BARREL, Decor.Kind.BARREL, Decor.Kind.ROCK, Decor.Kind.LOGS, Decor.Kind.CRATES, Decor.Kind.ROCK]

static func heap_for(k: int, c: Vector2, dir: Vector2, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var side := Vector2(-dir.y, dir.x)
	var out := []
	var n := rng.randi_range(PIECES_PER.x, PIECES_PER.y)
	for i in n:
		var kind: Decor.Kind = KINDS[rng.randi() % KINDS.size()]
		var along := rng.randf_range(-0.26, 0.26)
		var across := rng.randf_range(-0.2, 0.2)
		var base := i < 3
		out.append({
			"kind": kind,
			"at": c + dir * along + side * across,
			"seed": seed_value + i * 13 + k,
			"scale": rng.randf_range(0.55, 0.9) if base else rng.randf_range(0.45, 0.7),
			"lift": 0.0 if base else rng.randf_range(5.0, 11.0),
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


## Cut short (FxTimeline.end_now()): the line goes with it, or it would block the way for good.
func end_now() -> void:
	_remove_all()
	super()


## One segment's heap, lying: its pieces painted from the decor sprites, each at its own spot and size, the later ones
## lifted onto the earlier. One node a segment in the world layer, so people sort round it.
class Heap extends Node2D:
	var pieces: Array = []

	func _draw() -> void:
		WindfallFx.paint_pieces(self, pieces, position, 0.0)


## Paint `pieces` (heap_for()) on `ci`, whose node sits at screen `origin`, lifted a further `up` pixels (the fall).
static func paint_pieces(ci: CanvasItem, pieces: Array, origin: Vector2, up: float) -> void:
	for g in pieces:
		var foot := Iso.ground_to_screen(g.at) - origin + Vector2(0, -float(g.lift) - up)
		var sc: float = g.scale * ArtTuning.scale(String(Decor.Kind.keys()[g.kind]).to_lower())
		# Scaled about its own foot: the painter is told its foot is the origin, and the transform puts it there.
		ci.draw_set_transform(foot.round(), 0.0, Vector2(sc, sc))
		ArtKit.begin()
		ArtKit.color_mul = ArtTuning.tint(String(Decor.Kind.keys()[g.kind]).to_lower())
		DecorArt.paint(g.kind, g.at, Vector2.ZERO, g.seed, Iso.ground_to_screen(g.at))
		ArtKit.color_mul = Color.WHITE
		ArtKit.flush(ci)
	ci.draw_set_transform(Vector2.ZERO)


## The load on its way down: the segments' heaps -- the same pieces they will lie as -- falling together onto the
## marks, each with a shadow closing under it.
class Load extends Node2D:
	var fx: WindfallFx

	func _process(_delta: float) -> void:
		if fx.t >= T_DROP:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(fx.t / T_DROP, 0.0, 1.0)
		var up := FALL * (1.0 - k * k)
		var rects := WindfallFx.rects(fx.origin, fx._dir)
		for r in rects:
			var to := Iso.ground_to_screen(r.get_center())
			draw_set_transform(to, 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 5.0 + 9.0 * k, Color(0.0, 0.0, 0.0, 0.15 + 0.3 * k))
		draw_set_transform(Vector2.ZERO)
		for i in rects.size():
			WindfallFx.paint_pieces(self, WindfallFx.heap_for(i, rects[i].get_center(), fx._dir, fx._seed + i * 97), Vector2.ZERO, up + float(i % 2) * 6.0)
