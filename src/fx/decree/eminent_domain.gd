class_name EminentFx
extends FxTimeline
## Eminent Domain (Decree, Tier IV; spec 5.7): a road dragged through the town, claimed by the law of land. The strip runs
## LENGTH from the press in the drag's direction (extra "dir", else toward extra "to"; +x with neither), HALF_W either
## side of its line, whatever the drag's own length. Two stages, then what it leaves:
## 1. The claim (T_TEAR): the strip is ruled out in gilt from the press to its end, its stakes and letters of law laid
##    along it, and everything standing in it shakes.
## 2. The tear (at T_TEAR): every structure the strip overlaps -- house, wall, stall, tree, gate, bridge -- is torn down
##    (Structure.destroy; one whose health another owns, the Citadel's, is dealt the blow instead), and its ruins, with
##    any ruin already lying there, are taken away whole at once (_clear_ruins()). Only their look stays a moment
##    (review R5: a building never just vanishes): each is shoved out to the nearer side of the strip over T_SHOVE,
##    sliding, leaning outward and crumbling as it goes (its set's collapse frames when it has them), throwing dust and
##    debris (Shove, drawn by the effect). Every piece of decor in it is taken away (EnvironmentField.remove_decor, as
##    Heaven's Door takes the goods), its look flung spinning out to the nearer side (Flung). Whoever stands in it, or
##    shelters in a house it claims, is thrown clear to the nearer side over T_THROW, past where the rubble will lie,
##    knocked down, at half their health. Nobody dies of it.
## Leaves (at T_TEAR + T_SHOVE): a bare street, its cells open to walk (WalkGrid.open_street(), the river excepted), and
## law rubble (LawRubble.lay) along both long sides, outside its edges, closing the walk grid until the town's engineers
## clear it: where each building was shoved to, a heap of its own ruins (_plan()), and plain heaps filling the gaps
## between them (_lay()). No heap is laid on the water or in a standing building; anyone standing where one lands is
## pushed out first. Where the thrown land, what falls and where the heaps lie follow distance and order only, never a
## roll. Loud (PowerBook.REACH): its danger lands with the tear.

const LENGTH := 10.0
const HALF_W := 1.0
const T_TEAR := 0.8
const T_THROW := 0.35
## How long a torn building's look takes to be shoved out to where its heap is laid (and the decor's to be flung clear).
const T_SHOVE := 0.5
## How long the claimed strip's gilt lingers over the new street after the throw (look only).
const SCAR := 2.6
## The plain rubble: a heap every HEAP_EVERY at most along each long side, HEAP across at most (varied by order), GAP off
## the street's edge, so its walk-grid margin (WalkGrid.BODY) never closes a cell of the street.
const HEAP_EVERY := 1.0
const HEAP := 0.9
const GAP := 0.25
const HEAP_H := 9.0
## A building's own heap: HEAP across, HEAP_OF of the building's length along the street (HEAP .. HEAP_LONG), as tall as
## HEAP_H times its height over BUILD_H (HEAP_H_LO .. HEAP_H_HI). Heaps on one side keep HEAP_PAD apart; a gap too short
## for a plain heap HEAP_MIN across is left open.
const HEAP_LONG := 1.8
const HEAP_OF := 0.9
const BUILD_H := 30.0
const HEAP_H_LO := 0.8
const HEAP_H_HI := 1.4
const HEAP_PAD := 0.05
const HEAP_MIN := 0.4
## The thrown land this far past the rubble's outer edge; failing open ground there, up to LAND_TRIES half-steps farther,
## then the same on the far side.
const LAND_PAD := 0.3
const LAND_TRIES := 8
## The slide a thrown man lands with (look; the knock-down is what holds him).
const KNOCK := 1.2
## Decor counts as in the strip within this of it (EnvironmentField.damage_lane's own reach).
const DECOR_REACH := 0.15
## Decor laid out along the ground from its point: a run (to at + size) or a plot (at .. at + size). The rest stand on
## their point (a tree's size is its height).
const RUNS := [Decor.Kind.FENCE, Decor.Kind.BUNTING, Decor.Kind.BENCH]
const PLOTS := [Decor.Kind.GARDEN, Decor.Kind.DOCK]
## Debris colours for a building's timber and plaster and the decor flung off (wood).
const TIMBER := [Color("e0c8a0"), Color("9a7a58"), Color("5a4232"), Color(0.2, 0.15, 0.1, 0.6)]
## The shove's look: the most a building leans outward (radians), and the share of the shove after which it fades into
## its heap.
const TILT := 0.35
const FADE_FROM := 0.7
## A building without sprite art crumbles to this share of its height as it is shoved.
const CRUMBLE := 0.7
## Decor flung: this far past the strip's edge, arcing ARC px high, turning SPIN radians, fading after FLING_FADE of it.
const FLING := 1.4
const ARC := 22.0
const SPIN := 6.0
const FLING_FADE := 0.6
## A building drawn without sprite art (Shove.stand_in): [wall lit, wall in shade, roof or top]; stone for walls, gates,
## towers and the like; a tree's [trunk, leaves, leaves in shade].
const STAND_PLASTER := [Color("d8c4a0"), Color("a8916e"), Color("7a3a2e")]
const STAND_STONE := [Color("a6a39b"), Color("7e7b74"), Color("8f8c85")]
const STAND_TREE := [Color("5a4232"), Color("4a7a3c"), Color("2e5228")]
const STONY := [Structure.Kind.WALL, Structure.Kind.CASTLE_WALL, Structure.Kind.GATE, Structure.Kind.TOWER,
	Structure.Kind.KEEP, Structure.Kind.TEMPLE, Structure.Kind.BRIDGE, Structure.Kind.FOUNTAIN, Structure.Kind.BLOCK,
	Structure.Kind.SHRINE]

## The strip: its direction, its side (dir.orthogonal()), its end.
var dir := Vector2.RIGHT
var side := Vector2.DOWN
var to := Vector2.ZERO
## How far off the line the thrown land (past the widest heap).
var land := 0.0
## What it took: structures torn down, decor taken away, people thrown; the heaps it left.
var claimed := 0
var removed := 0
var thrown := 0
## Ruins taken away whole, so the street is bare.
var cleared := 0
## Heaps laid of a building's own ruins (the rest of `heaps` are plain ones filling the gaps).
var shoved := 0
var heaps: Array[Structure] = []

## Whoever is in the air: DummyEnemy -> [where they were thrown from, where they land, the side's sign].
var _flying := {}
## What the tear brought down (and the ruins already standing in the strip), cleared away whole at once.
var _torn: Array[Structure] = []
## Where each cleared building goes, settled at the tear (_plan()), its heap laid at T_TEAR + T_SHOVE: {"from": the
## structure, "at": where its look stops (ground), "rect": its heap, "ok": whether the heap is laid, "h": its height,
## "sign": its side, "along": its middle along the line}.
var _plans: Array[Dictionary] = []
## Ground pairs of the seams the buildings tear free along (look only).
var _splits := PackedVector2Array()
var _strip: Strip
## The looks on their way out (staged only), index for index: the node, its SpriteView (null for a stand-in), where it
## starts and how far it goes (screen px), its lean (radians) and, for a sprite with no collapse frames, how deep it sinks
## (its anchor's height, px; 0 for none).
var _shoves: Array[Node2D] = []
var _shove_views: Array = []
var _shove_from := PackedVector2Array()
var _shove_by := PackedVector2Array()
var _shove_lean := PackedFloat32Array()
var _shove_sink := PackedFloat32Array()
## The decor's looks flung clear (staged only), index for index: the node, where it starts, how far it goes (screen px),
## how far it turns.
var _flung: Array[Node2D] = []
var _fling_from := PackedVector2Array()
var _fling_by := PackedVector2Array()
var _fling_spin := PackedFloat32Array()


func _build() -> void:
	var drag: Vector2 = extra.get("dir", Vector2.ZERO)
	var end: Vector2 = extra.get("to", Vector2.INF)
	if drag.length() < 0.01 and end != Vector2.INF:
		drag = end - origin
	dir = drag.normalized() if drag.length() >= 0.01 else Vector2.RIGHT
	side = dir.orthogonal()
	to = origin + dir * LENGTH
	var long := _heap_size(HEAP_LONG, HEAP)
	land = HALF_W + GAP + 2.0 * maxf(_ext(HEAP), _ext(long.x, long.y)) + LAND_PAD
	duration = T_TEAR + T_THROW + SCAR
	busy = T_TEAR + maxf(T_THROW, T_SHOVE)
	at(T_TEAR, _tear)
	at(T_TEAR + T_THROW, _land)
	at(T_TEAR + T_SHOVE * 0.5, _mid_shove)
	at(T_TEAR + T_SHOVE, _settle)
	ctx.play(&"ed_roar", middle())
	if not DominionParts.staged(self):
		return
	DecreeParts.proclaim(self, middle(), 54.0, 70.0, T_TEAR, 0.6)
	_strip = Strip.new()
	_strip.fx = self
	_strip.z_index = 4
	track(_strip, ctx.ground)
	for s in ctx.env.structures():
		if is_instance_valid(s) and not s.destroyed and overlaps(s):
			s.shake(3.0)
	ctx.shake.add_trauma(0.2)
	# Gilt rising off both edges as they are ruled out (over the roofs: the ground's lines hide behind the houses).
	for k in 5:
		for sg in [1.0, -1.0]:
			var g: Vector2 = origin + dir * LENGTH * (0.1 + 0.2 * float(k)) + side * HALF_W * sg
			FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(g), PixelParticles.Shape.SQUARE, DecreeParts.GILT_LIFE, 14.0,
				T_TEAR, {"radius": 10.0, "speed": Vector2(2, 10), "alt": Vector2(0, 4), "alt_speed": Vector2(20, 55),
					"life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})


## The middle of the strip's line.
func middle() -> Vector2:
	return origin + dir * LENGTH * 0.5


## Whether ground point `g` lies in the strip, grown by `reach`.
func in_strip(g: Vector2, reach := 0.0) -> bool:
	var rel := g - origin
	var along := rel.dot(dir)
	return along >= -reach and along <= LENGTH + reach and absf(rel.dot(side)) <= HALF_W + reach


## Whether `s`'s footprint overlaps the strip.
func overlaps(s: Structure) -> bool:
	var half := s.footprint.size * 0.5
	var rel := s.center() - origin
	var along := rel.dot(dir)
	var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
	return along + ext_along >= 0.0 and along - ext_along <= LENGTH and absf(rel.dot(side)) <= HALF_W + _ext(s.footprint.size.x, s.footprint.size.y)


## Half the reach across the strip of an axis-aligned box `w` by `h` (`h` defaults to a square).
func _ext(w: float, h := -1.0) -> float:
	return 0.5 * (absf(w * side.x) + absf((w if h < 0.0 else h) * side.y))


## Half the reach along the strip of an axis-aligned box `size`.
func _reach(size: Vector2) -> float:
	return 0.5 * (absf(size.x * dir.x) + absf(size.y * dir.y))


## A heap `long` along the street and `across` over it, its long side on the ground axis nearer the street's.
func _heap_size(long: float, across: float) -> Vector2:
	return Vector2(long, across) if absf(dir.x) >= absf(dir.y) else Vector2(across, long)


## Which side of the line `g` is on: +1 or -1 (on the line: +1).
func _sign_of(g: Vector2) -> float:
	return 1.0 if (g - origin).dot(side) >= 0.0 else -1.0


## Whether decor `d` lies in the strip: its point, or for a run or plot any of its corners and its middle.
func _decor_in(d: Decor) -> bool:
	if in_strip(d.at, DECOR_REACH):
		return true
	if d.size == Vector2.ZERO:
		return false
	if d.kind in RUNS:
		return in_strip(d.at + d.size * 0.5, DECOR_REACH) or in_strip(d.at + d.size, DECOR_REACH)
	if d.kind in PLOTS:
		return in_strip(d.at + d.size * 0.5, DECOR_REACH) or in_strip(d.at + d.size, DECOR_REACH) \
			or in_strip(d.at + Vector2(d.size.x, 0.0), DECOR_REACH) or in_strip(d.at + Vector2(0.0, d.size.y), DECOR_REACH)
	return false


## The tear: the sheltering are brought out of the houses it claims, everything in the strip comes down and is taken
## away (its look shoved or flung aside), the street opens, and everyone in it goes up.
func _tear() -> void:
	var take: Array[Structure] = []
	for s in ctx.env.structures():
		if is_instance_valid(s) and overlaps(s):
			take.append(s)
	var people: Array[DummyEnemy] = []
	if ctx.crowd != null and ctx.crowd.rescue != null:
		# Anyone trapped under a ruin the strip clears is dug out by it, and thrown with the rest.
		for tr: Dictionary in ctx.crowd.rescue.trapped.duplicate():
			var site = tr.site
			if is_instance_valid(site) and take.has(site) and is_instance_valid(tr.p):
				ctx.crowd.rescue._free(tr, (site as Structure).center())
				people.append(tr.p)
	if ctx.crowd != null and ctx.crowd.shelters != null:
		for s in take:
			if not s.destroyed:
				for p in ctx.crowd.shelters.throw_out_of(s, 0.0):
					people.append(p)
	for e in ctx.field.in_radius(middle(), LENGTH * 0.5 + HALF_W + 0.1):
		var p := e as Person
		if p != null and p.inside:
			continue
		if in_strip(e.ground_pos) and not people.has(e):
			people.append(e)
	var staged := DominionParts.staged(self)
	# How charred each was before it fell (the fall chars it): its look leaves standing.
	var standing := {}
	for s in take:
		if not is_instance_valid(s):
			continue
		if s.destroyed:
			_torn.append(s)  # a ruin already: cleared with the rest
			continue
		standing[s] = s.scorch
		var sg := _sign_of(s.center())
		var from := s.center() - side * sg
		if s.damage_filter.is_valid():
			s.damage(99999.0, from, &"stone")  # the Citadel's own health decides
		else:
			s.destroy(from, &"stone")
		if not s.destroyed:
			continue
		claimed += 1
		_torn.append(s)
		if staged:
			_split(s)
	_plan(_clear_ruins())
	if staged:
		for pl in _plans:
			var s: Structure = pl.from
			_shove(pl, standing.has(s), float(standing.get(s, s.scorch)))
	for d: Decor in ctx.env.decor().duplicate():
		if not is_instance_valid(d) or d.sprite_only or not _decor_in(d):
			continue
		if staged:
			_fling(d)
		ctx.env.remove_decor(d)
		removed += 1
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	if grid != null:
		grid.open_street(origin, dir, LENGTH, HALF_W)
	for e in people:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var sg := _sign_of(e.ground_pos)
		var land_at := _landing(e.ground_pos, sg)
		_flying[e] = [e.ground_pos, land_at, _sign_of(land_at)]
		e.knock(side * _sign_of(land_at) * KNOCK)
		var p := e as Person
		if p != null:
			p.health *= 0.5
			p.flash(0.1)
		thrown += 1
	if not staged:
		return
	var mid := middle()
	ctx.flash.call(Color(1.0, 0.9, 0.6, 0.3), 0.22)
	ctx.impact.hitstop(0.06)
	ctx.impact.aberration(2.0, 0.3)
	ctx.shake.add_trauma(0.75)
	ctx.shake.kick(Vector2(0, 5))
	DecreeParts.wave(self, mid, LENGTH * 0.5, 0.45, 0.08)
	for k in 5:
		var g := origin + dir * LENGTH * (0.1 + 0.2 * float(k))
		DecreeParts.scatter(self, g, 6, 8.0)
		var puff := FxParts.particles(self, ctx.overhead_back, Iso.ground_to_screen(g), PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
		puff.drag = 1.2
		puff.burst(8, {"radius": 18.0, "speed": Vector2(20, 70), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 8),
			"alt_speed": Vector2(10, 40), "life": Vector2(0.7, 1.4), "size": Vector2(2, 5), "size_end_mul": 1.8})


## A building torn free (look): a gilt seam drawn through it along the line, and a burst of its timber and plaster thrown
## out to its side, ahead of its shove.
func _split(s: Structure) -> void:
	var c := s.center()
	var half_along := _reach(s.footprint.size)
	_splits.append(c - dir * half_along)
	_splits.append(c + dir * half_along)
	var away := Iso.ground_to_screen(c + side * _sign_of(c)) - Iso.ground_to_screen(c)
	var a := away.angle()
	var pieces := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(c), PixelParticles.Shape.CHUNK, TIMBER)
	pieces.gravity = 420.0
	pieces.bounce = true
	pieces.drag = 0.6
	pieces.shadows = true
	pieces.burst(14, {"radius": 8.0, "speed": Vector2(60, 180), "alt": Vector2(4, 16), "alt_speed": Vector2(60, 200),
		"life": Vector2(1.0, 2.0), "size": Vector2(1.5, 4.0), "dir": PixelParticles.Dir.ANGLE,
		"angle": Vector2(a - 0.5, a + 0.5)})


## Where someone thrown from `g` toward side `sg` lands: straight out past the rubble, on open ground (the walk grid's;
## dry, standing nothing) -- farther out if the first spot is not, then the far side, failing all the first spot.
func _landing(g: Vector2, sg: float) -> Vector2:
	var along := clampf((g - origin).dot(dir), 0.0, LENGTH)
	var base := origin + dir * along
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	for way in [sg, -sg]:
		for k in LAND_TRIES:
			var at_g: Vector2 = base + side * float(way) * (land + 0.5 * float(k))
			if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.has_point(at_g):
				continue
			if grid == null or grid.walkable(at_g):
				return at_g
	return base + side * sg * land


## The looks in flight: the thrown eased out to where they land, the buildings shoved to their heaps (sliding, leaning,
## crumbling, fading into the heap), the decor flung spinning out. Nothing is made here.
func _fx_process(_delta: float) -> void:
	if t < T_TEAR:
		return
	if not _flying.is_empty():
		var k := clampf((t - T_TEAR) / T_THROW, 0.0, 1.0)
		k = 1.0 - (1.0 - k) * (1.0 - k)
		for e: Variant in _flying:
			if is_instance_valid(e) and e.is_alive():
				var fl: Array = _flying[e]
				e.ground_pos = (fl[0] as Vector2).lerp(fl[1], k)
	if _shoves.is_empty() and _flung.is_empty():
		return
	var u := clampf((t - T_TEAR) / T_SHOVE, 0.0, 1.0)
	var slide := 1.0 - (1.0 - u) * (1.0 - u)
	var fade := 1.0 - clampf((u - FADE_FROM) / (1.0 - FADE_FROM), 0.0, 1.0)
	for i in _shoves.size():
		var n := _shoves[i]
		if not is_instance_valid(n):
			continue
		n.position = _shove_from[i] + _shove_by[i] * slide
		n.rotation = _shove_lean[i] * u * u
		n.modulate.a = fade
		var v: SpriteView = _shove_views[i]
		if v == null:
			n.scale.y = 1.0 - CRUMBLE * u * u
		elif v.still == &"collapse":
			v.show_still(&"collapse", int(u * float(v.sprite.collapse_frames)))
		elif _shove_sink[i] > 0.0:
			var sink := roundf(u * u * _shove_sink[i] * 0.8)
			v.position.y = sink
			v.set_cut(SpriteView.KEEP_ABOVE, sink)
	var spin_fade := 1.0 - clampf((u - FLING_FADE) / (1.0 - FLING_FADE), 0.0, 1.0)
	for i in _flung.size():
		var n := _flung[i]
		if not is_instance_valid(n):
			continue
		n.position = _fling_from[i] + _fling_by[i] * slide + Vector2(0.0, -ARC * sin(PI * u))
		n.rotation = _fling_spin[i] * u
		n.modulate.a = spin_fade
	if u >= 1.0:
		for n in _shoves:
			if is_instance_valid(n):
				n.visible = false
		for n in _flung:
			if is_instance_valid(n):
				n.visible = false
		_shoves.clear()
		_flung.clear()


## The thrown come down, knocked flat.
func _land() -> void:
	for e: Variant in _flying:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var fl: Array = _flying[e]
		e.ground_pos = fl[1]
		e.knock(side * float(fl[2]) * KNOCK)
		var p := e as Person
		if p != null:
			p.knock_down()
	_flying.clear()
	if DominionParts.staged(self):
		ctx.shake.add_trauma(0.2)


## Halfway out (look): each shoved building throws up dust where it scrapes along, and sheds chunks ahead of it.
func _mid_shove() -> void:
	if _shoves.is_empty():
		return
	for i in _shoves.size():
		var n := _shoves[i]
		if not is_instance_valid(n):
			continue
		var at_s := n.position
		var puff := FxParts.particles(self, ctx.overhead_back, at_s, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
		puff.drag = 1.2
		puff.burst(7, {"radius": 14.0, "speed": Vector2(15, 55), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 6),
			"alt_speed": Vector2(10, 35), "life": Vector2(0.6, 1.2), "size": Vector2(2, 5), "size_end_mul": 1.7})
		var a := _shove_by[i].angle()
		var chunks := FxParts.particles(self, ctx.overhead, at_s + Vector2(0.0, -10.0), PixelParticles.Shape.CHUNK, TIMBER)
		chunks.gravity = 420.0
		chunks.bounce = true
		chunks.drag = 0.6
		chunks.burst(8, {"radius": 6.0, "speed": Vector2(50, 150), "alt": Vector2(6, 18), "alt_speed": Vector2(40, 150),
			"life": Vector2(0.8, 1.6), "size": Vector2(1.0, 3.0), "dir": PixelParticles.Dir.ANGLE,
			"angle": Vector2(a - 0.6, a + 0.6)})


## Where the shoved stop: the rubble is piled along both sides.
func _settle() -> void:
	_lay()
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.35)
	for h in heaps:
		var puff := FxParts.particles(self, ctx.overhead_back, Iso.ground_to_screen(h.center()), PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
		puff.drag = 1.0
		puff.burst(5, {"radius": 10.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 6),
			"alt_speed": Vector2(10, 30), "life": Vector2(0.6, 1.2), "size": Vector2(2, 4), "size_end_mul": 1.6})


## The street is left bare: every ruin in the strip is taken away whole (EnvironmentField.remove, as Heaven's Door takes
## what it tears up), one only partly in it too. Its node is kept, hidden (remove()'s keep_node): a mission may hold that
## house, and holds a fallen one, never a freed object; a shelter forgets it. Kept as ruins where they stand: the town's
## own gates, bridges, postern, dock and fountain and the Citadel's parts, which the town's managers go on using
## (evacuation, the engineers' rebuilding, the river's crossings). Returns what it took, in order.
func _clear_ruins() -> Array[Structure]:
	var keep: Array = []
	var town: Town = ctx.crowd._town if ctx.crowd != null else null
	if is_instance_valid(town):
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
	var gone: Array[Structure] = []
	for s in _torn:
		if not is_instance_valid(s) or not s.destroyed or not ctx.env.structures().has(s) or keep.has(s) \
				or s.role == &"citadel":
			continue
		if ctx.crowd != null and ctx.crowd.shelters != null:
			ctx.crowd.shelters.shelters.erase(s)
		ctx.env.remove(s, true, true)
		cleared += 1
		gone.append(s)
	_torn.clear()
	return gone


## Where each building it took goes (one walked over, a field, has no heap and no look): to the nearer side, its own heap
## (HEAP across, its length along the street) laid GAP off the edge at its middle along the line, pushed along past the
## heap before it on that side when they would meet. A heap that would leave the strip's length, lie on the water, in a
## standing building or off the map is not laid; its look still goes to that spot.
func _plan(gone: Array[Structure]) -> void:
	for s in gone:
		if s.walkable:
			continue
		var sz := _heap_size(clampf(2.0 * _reach(s.footprint.size) * HEAP_OF, HEAP, HEAP_LONG), HEAP)
		var half := _reach(sz)
		_plans.append({"from": s, "sign": _sign_of(s.center()), "size": sz,
			"along": clampf((s.center() - origin).dot(dir), half, LENGTH - half),
			"h": HEAP_H * clampf(s.max_height / BUILD_H, HEAP_H_LO, HEAP_H_HI)})
	_plans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if not is_equal_approx(float(a.along), float(b.along)):
			return float(a.along) < float(b.along)
		var pa: Vector2 = (a.from as Structure).footprint.position
		var pb: Vector2 = (b.from as Structure).footprint.position
		return pa.x < pb.x if not is_equal_approx(pa.x, pb.x) else pa.y < pb.y)
	var reached := {1.0: -INF, -1.0: -INF}
	for pl in _plans:
		var sg: float = pl.sign
		var sz: Vector2 = pl.size
		var half := _reach(sz)
		var along := maxf(float(pl.along), float(reached[sg]) + HEAP_PAD + half)
		var fits := along + half <= LENGTH + 0.001
		along = minf(along, LENGTH - half)
		var c := origin + dir * along + side * sg * (HALF_W + GAP + _ext(sz.x, sz.y))
		var rect := Rect2(c - sz * 0.5, sz)
		var ok := fits and (ctx.field.bounds.size == Vector2.ZERO or ctx.field.bounds.encloses(rect)) \
			and not _wet(rect) and not _blocked(rect)
		if ok:
			reached[sg] = along + half
		pl.along = along
		pl.at = c
		pl.rect = rect
		pl.ok = ok


## The heaps, side by side: each building's own where it was shoved to (_plan()), then plain heaps in the gaps between
## them and the street's ends, each gap split evenly into heaps about HEAP_EVERY apart, sized by order (and
## never past the gap's ends), each GAP off the street's edge. None on the water, none in a standing building; whoever
## stands where one lands is moved out past it first (as the thrown are).
func _lay() -> void:
	for way in [1.0, -1.0]:
		var held: Array[Vector2] = []
		for pl in _plans:
			if float(pl.sign) != way or not pl.ok:
				continue
			var rect: Rect2 = pl.rect
			_clear_under(rect, way)
			var from: Structure = pl.from if is_instance_valid(pl.from) else null
			heaps.append(LawRubble.lay(ctx.env, rect, float(pl.h), from))
			shoved += 1
			var half := _reach(rect.size)
			held.append(Vector2(float(pl.along) - half, float(pl.along) + half))
		held.append(Vector2(LENGTH + HEAP_PAD, INF))
		var start := 0.0
		for span in held:
			_fill(start, span.x - HEAP_PAD, way)
			start = maxf(start, span.y + HEAP_PAD)


## Plain heaps between `a` and `b` along the line, on side `way`.
func _fill(a: float, b: float, way: float) -> void:
	var span := b - a
	if span < HEAP_MIN:
		return
	var n := maxi(1, roundi(span / HEAP_EVERY))
	var step := span / float(n)
	# A square heap's length along the line per unit of its side.
	var wide := absf(dir.x) + absf(dir.y)
	for j in n:
		var along := a + (float(j) + 0.5) * step
		var k := floori(along / HEAP_EVERY)
		var size := minf(HEAP * (0.8 + 0.2 * fposmod(float(k) * 0.618034 + (0.0 if way > 0.0 else 0.5), 1.0)), step / wide)
		if size < HEAP_MIN:
			continue
		var c: Vector2 = origin + dir * along + side * way * (HALF_W + GAP + _ext(size))
		var rect := Rect2(c - Vector2(size, size) * 0.5, Vector2(size, size))
		if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.encloses(rect):
			continue
		if _wet(rect) or _blocked(rect):
			continue
		_clear_under(rect, way)
		heaps.append(LawRubble.lay(ctx.env, rect, HEAP_H * (0.8 + 0.4 * fposmod(float(k) * 0.381966, 1.0))))


## Whoever stands where heap `rect` lands (out of doors) is moved out past the rubble on side `way`.
func _clear_under(rect: Rect2, way: float) -> void:
	for e in ctx.field.in_rect(rect.grow(WalkGrid.BODY)):
		var p := e as Person
		if p == null or not p.inside:
			e.ground_pos = _landing(e.ground_pos, way)


## Some of `rect` lies on the water.
func _wet(rect: Rect2) -> bool:
	for r: Rect2 in City.current().rivers():
		if r.intersects(rect):
			return true
	return false


## A standing building (not a pile of law rubble, not ground one walks on) covers some of `rect`.
func _blocked(rect: Rect2) -> bool:
	for s in ctx.env.near(rect.get_center(), rect.size.x):
		if is_instance_valid(s) and not s.destroyed and not s.walkable and s.role != LawRubble.ROLE and s.footprint.intersects(rect):
			return true
	return false


## Building `pl.from`'s look shoved out to where its heap lies (look only; the structure is already taken away): a Shove
## in the building's own layer at its front corner, wearing its own sprite (`fell`: it stood until the tear, so it
## crumbles through its set's collapse frames, or sinks as the engine sinks one without them; a ruin already slides as
## its ruins), else a stand-in in its colours. `scorch`: how charred it was.
func _shove(pl: Dictionary, fell: bool, scorch: float) -> void:
	var s: Structure = pl.from
	if not is_instance_valid(s):
		return
	var parent: Node = s.get_parent()
	if parent == null:
		parent = ctx.world if ctx.world != null else ctx.overhead
	var n := Shove.new()
	n.position = s._base
	n.z_index = s.z_index
	var view: SpriteView = null
	var sink := 0.0
	if not s.sprite.is_empty():
		view = SpriteView.new().setup(s.sprite, s._s[3], s._s[1])
		view.set_light(s._sprite_light[0], s._sprite_light[1], scorch, s.frost, s._sprite_light[2])
		n.add_child(view)
		if not fell:
			view.show_still(&"ruins")
		elif s.sprite.collapse != null:
			view.show_still(&"collapse", 0)
		else:
			view.show_still(&"damaged")
			sink = (s.sprite.anchor as Vector2).y
	else:
		n.stand_in(s, fell)
		var lights: LightField = ctx.env.lights
		if lights != null:
			n.modulate = Color(lights.ambient * lights.tint.r, lights.ambient * lights.tint.g, lights.ambient * lights.tint.b)
	track(n, parent)
	var sg: float = pl.sign
	var away := Iso.ground_to_screen(side * sg)
	_shoves.append(n)
	_shove_views.append(view)
	_shove_from.append(s._base)
	_shove_by.append(Iso.ground_to_screen(pl.at as Vector2) - Iso.ground_to_screen(s.center()))
	_shove_lean.append(TILT * (signf(away.x) if absf(away.x) > 0.5 else sg))
	_shove_sink.append(sink)
	var puff := FxParts.particles(self, ctx.overhead_back, Iso.ground_to_screen(s.center()), PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
	puff.drag = 1.2
	puff.burst(9, {"radius": 16.0, "speed": Vector2(20, 70), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 10),
		"alt_speed": Vector2(15, 45), "life": Vector2(0.7, 1.4), "size": Vector2(2, 6), "size_end_mul": 1.8})


## Decor `d`'s look flung out to the nearer side, spinning, then gone (look only; `d` itself is taken away): a Flung in
## its own layer, drawn as it is (DecorArt, its tuning, its material and tint), moved off the strip's edge by FLING.
func _fling(d: Decor) -> void:
	var mid := d.at + (d.size * 0.5 if d.kind in RUNS or d.kind in PLOTS else Vector2.ZERO)
	var sg := _sign_of(mid)
	var out := maxf(HALF_W - (mid - origin).dot(side) * sg, 0.0) + FLING
	var parent: Node = d.get_parent() if d.is_inside_tree() else null
	if parent == null:
		parent = ctx.world if ctx.world != null else ctx.overhead
	var n := Flung.new()
	n.kind = d.kind
	n.at = d.at
	n.size = d.size
	n.seed_value = d.seed_value
	n.parts = d.pile_parts_drawn() if d.kind == Decor.Kind.PILE else []
	n.sc = ArtTuning.scale(d.tuning_key()) * d.scale_mul
	n.material = d.material
	n.self_modulate = d.self_modulate
	n.z_index = d.z_index
	n.position = Iso.ground_to_screen(d.at)
	track(n, parent)
	var by := Iso.ground_to_screen(side * sg * out)
	_flung.append(n)
	_fling_from.append(n.position)
	_fling_by.append(by)
	_fling_spin.append(SPIN * (signf(by.x) if absf(by.x) > 0.5 else sg))
	FxParts.debris(self, Iso.ground_to_screen(d.at), 5, 4.0, Vector2(40, 140), TIMBER, Vector2(1, 3), true)


## A torn building's look on its way out (Eminent Domain's shove), pivoting on its footprint's front corner: its
## SpriteView child, or a stand-in drawn once from its footprint and height (stand_in()); the effect moves, leans,
## squashes and fades the node, so nothing is drawn again.
class Shove extends Node2D:
	var faces: Array[PackedVector2Array] = []
	var colors := PackedColorArray()

	func _draw() -> void:
		for i in faces.size():
			draw_colored_polygon(faces[i], colors[i])

	## A building without sprite art: a box on its footprint (its corners Structure._s, relative to its front corner),
	## roofed in a house's colours, flat-topped in stone for walls, gates and towers; a tree a trunk under its leaves. A
	## ruin already (`fell` false) is a low stump of it.
	func stand_in(s: Structure, fell: bool) -> void:
		var h := maxf(s.max_height * (1.0 if fell else 0.25), 4.0)
		var b: Vector2 = s._s[0]
		var r: Vector2 = s._s[1]
		var l: Vector2 = s._s[3]
		var f := Vector2.ZERO
		var mid := (l + r) * 0.5
		if s.kind == Structure.Kind.TREE:
			var top := mid + Vector2(0.0, -h * 0.4)
			faces.append(PackedVector2Array([mid + Vector2(-1.5, 0.0), mid + Vector2(1.5, 0.0), top + Vector2(1.5, 0.0),
				top + Vector2(-1.5, 0.0)]))
			colors.append(STAND_TREE[0])
			if fell:
				var c := mid + Vector2(0.0, -h * 0.65)
				var rad := maxf(6.0, h * 0.3)
				for half in 2:
					var leaves := PackedVector2Array()
					for k in 5:
						var ang := PI * (float(half) + float(k) / 4.0)
						leaves.append(c + Vector2(cos(ang), sin(ang) * 0.85) * rad)
					faces.append(leaves)
					colors.append(STAND_TREE[1 + half])
			return
		var pal: Array = STAND_STONE if s.kind in STONY else STAND_PLASTER
		var roofed := fell and pal == STAND_PLASTER
		var up := Vector2(0.0, -h * (0.6 if roofed else 1.0))
		faces.append(PackedVector2Array([l, f, f + up, l + up]))
		colors.append(pal[0])
		faces.append(PackedVector2Array([f, r, r + up, f + up]))
		colors.append(pal[1])
		if roofed:
			var apex := mid + Vector2(0.0, -h)
			faces.append(PackedVector2Array([l + up, f + up, apex]))
			colors.append(pal[2])
			faces.append(PackedVector2Array([f + up, r + up, apex]))
			colors.append((pal[2] as Color).darkened(0.25))
		else:
			faces.append(PackedVector2Array([b + up, r + up, f + up, l + up]))
			colors.append(pal[2])


## A piece of decor's look flung clear (Eminent Domain), drawn once about its ground point as the piece draws itself
## (Decor._draw: DecorArt at its tuning's scale, a pile's parts each in its own tint); the effect moves, turns and fades
## the node.
class Flung extends Node2D:
	var kind := 0
	var at := Vector2.ZERO
	var size := Vector2.ZERO
	var seed_value := 0
	var parts: Array = []
	var sc := 1.0

	func _draw() -> void:
		if sc != 1.0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
		var o := Iso.ground_to_screen(at)
		ArtKit.begin()
		if kind == Decor.Kind.PILE:
			for p: Dictionary in parts:
				ArtKit.color_mul = ArtTuning.tint(String(Decor.Kind.keys()[p.kind]).to_lower())
				DecorArt.paint(p.kind, p.at, p.size, p.seed, o)
			ArtKit.color_mul = Color.WHITE
		else:
			DecorArt.paint(kind, at, size, seed_value, o)
		ArtKit.flush(self)


## The strip on the ground, drawn in ground units: through the claim an ink wash run out from the press with gilt edges,
## survey stakes across them and letters of law down the middle; at the tear a white-gold flash over it and gilt seams
## through every building it tears free; then the gilt edges of the new street, fading. Laid out once.
class Strip extends Node2D:
	const STAKE_EVERY := 1.0
	const LETTER_EVERY := 0.6
	var fx: EminentFx
	var _band := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var now := fx.t
		var o := fx.origin
		var d := fx.dir
		var s := fx.side * HALF_W
		var torn := now >= T_TEAR
		var run := clampf(now / (T_TEAR * 0.75), 0.0, 1.0)
		var run_len := LENGTH * run
		var fade := 1.0
		if torn:
			run_len = LENGTH
			fade = clampf(1.0 - (now - T_TEAR - T_THROW) / SCAR, 0.0, 1.0) if now > T_TEAR + T_THROW else 1.0
		if fade <= 0.0 or run_len < 0.05:
			return
		_band[0] = o + s
		_band[1] = o + d * run_len + s
		_band[2] = o + d * run_len - s
		_band[3] = o - s
		if not torn:
			draw_colored_polygon(_band, Color(DecreeParts.INK, 0.18 + 0.22 * run))
		else:
			var flash := clampf(1.0 - (now - T_TEAR) / 0.3, 0.0, 1.0)
			draw_colored_polygon(_band, Color(1.0, 0.95, 0.8, 0.45 * flash) if flash > 0.0 else Color(DecreeParts.GILT, 0.07 * fade))
		# The edges: ink under gilt.
		for sg in 2:
			var e := s if sg == 0 else -s
			draw_line(o + e, o + d * run_len + e, Color(DecreeParts.INK, 0.85 * fade), 0.24)
			draw_line(o + e, o + d * run_len + e, Color(DecreeParts.GILT, 0.95 * fade), 0.11)
			draw_line(o + e, o + d * run_len + e, Color(1.0, 0.97, 0.85, 0.8 * fade), 0.04)
		# The stakes: short gilt bars across each edge, every STAKE_EVERY.
		var along := 0.0
		while along <= run_len + 0.001:
			for sg in 2:
				var e := s if sg == 0 else -s
				var at_g := o + d * along + e
				draw_line(at_g - fx.side * 0.24, at_g + fx.side * 0.24, Color(DecreeParts.GILT, 0.9 * fade), 0.08)
			along += STAKE_EVERY
		if not torn:
			# Letters of law down the middle: short gilt strokes, each tilted by its order.
			along = LETTER_EVERY * 0.5
			var k := 0
			while along < run_len:
				var tilt := 0.25 * sin(float(k) * 2.39996)
				var w := (d * 0.16).rotated(tilt)
				var c := o + d * along
				draw_line(c - w, c + w, Color(DecreeParts.GILT, 0.8 * run), 0.05)
				along += LETTER_EVERY
				k += 1
			return
		# The seams the houses split along, bright at the tear and fading.
		var seam := clampf(1.0 - (now - T_TEAR) / 0.6, 0.0, 1.0)
		if seam > 0.0:
			for i in range(0, fx._splits.size(), 2):
				draw_line(fx._splits[i], fx._splits[i + 1], Color(DecreeParts.INK, 0.8 * seam), 0.14)
				draw_line(fx._splits[i], fx._splits[i + 1], Color(1.0, 0.97, 0.85, seam), 0.06)
