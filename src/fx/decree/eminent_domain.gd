class_name EminentFx
extends FxTimeline
## Eminent Domain (Decree, Tier IV; spec 5.7): a road dragged through the town, claimed by the law of land. The strip runs
## LENGTH from the press in the drag's direction (extra "dir", else toward extra "to"; +x with neither), HALF_W either
## side of its line, whatever the drag's own length. Two stages, then what it leaves:
## 1. The claim (T_TEAR): the strip is ruled out in gilt from the press to its end, its stakes and letters of law laid
##    along it, and everything standing in it shakes.
## 2. The tear (T_TEAR): every structure the strip overlaps -- house, wall, stall, tree, gate, bridge -- is torn down
##    (Structure.destroy; one whose health another owns, the Citadel's, is dealt the blow instead), houses split down the
##    middle and falling to either side; every piece of decor in it is taken away (EnvironmentField.remove_decor, as
##    Heaven's Door takes the goods). Whoever stands in it, or shelters in a house it claims, is thrown clear to the
##    nearer side over T_THROW, past where the rubble will lie, knocked down, at half their health. Nobody dies of it.
## Leaves: a bare street -- when the thrown land, the ruins of all it tore down (and any ruin already there) are taken
## away whole (_clear_ruins()) -- its cells open to walk (WalkGrid.open_street(), the river excepted), and law rubble
## (LawRubble.lay) piled along both long sides, outside its edges, closing the walk grid until the town's engineers clear
## it. No heap is laid on the water or in a standing building; anyone standing where one lands is pushed out first.
## Where the thrown land, what falls and where the heaps lie follow distance and order only, never a roll. Loud
## (PowerBook.REACH): its danger lands with the tear.

const LENGTH := 10.0
const HALF_W := 1.0
const T_TEAR := 0.8
const T_THROW := 0.35
## How long the claimed strip's gilt lingers over the new street after the throw (look only).
const SCAR := 2.6
## The rubble: a heap every HEAP_EVERY along each long side, HEAP across at most (varied by order), GAP off the street's
## edge, so its walk-grid margin (WalkGrid.BODY) never closes a cell of the street.
const HEAP_EVERY := 1.0
const HEAP := 0.9
const GAP := 0.25
const HEAP_H := 9.0
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
## Debris colours for a house's two halves (warm timber and plaster) and the decor flung off (wood).
const TIMBER := [Color("e0c8a0"), Color("9a7a58"), Color("5a4232"), Color(0.2, 0.15, 0.1, 0.6)]

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
var heaps: Array[Structure] = []

## Whoever is in the air: DummyEnemy -> [where they were thrown from, where they land, the side's sign].
var _flying := {}
## What the tear brought down (and the ruins already standing in the strip), cleared away whole when the thrown land.
var _torn: Array[Structure] = []
## Ground pairs of the seams the houses split along (look only).
var _splits := PackedVector2Array()
var _strip: Strip


func _build() -> void:
	var drag: Vector2 = extra.get("dir", Vector2.ZERO)
	var end: Vector2 = extra.get("to", Vector2.INF)
	if drag.length() < 0.01 and end != Vector2.INF:
		drag = end - origin
	dir = drag.normalized() if drag.length() >= 0.01 else Vector2.RIGHT
	side = dir.orthogonal()
	to = origin + dir * LENGTH
	land = HALF_W + GAP + 2.0 * _ext(HEAP) + LAND_PAD
	duration = T_TEAR + T_THROW + SCAR
	busy = T_TEAR + T_THROW
	at(T_TEAR, _tear)
	at(T_TEAR + T_THROW, _land)
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


## The tear: the sheltering are brought out of the houses it claims, everything in the strip comes down or is taken, the
## street opens, and everyone in it goes up.
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
	for s in take:
		if not is_instance_valid(s):
			continue
		if s.destroyed:
			_torn.append(s)  # a ruin already: cleared with the rest
			continue
		var sg := _sign_of(s.center())
		# Split down the middle: its own debris falls away to its side of the line, the other half (look) to the other.
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
	for d: Decor in ctx.env.decor().duplicate():
		if not is_instance_valid(d) or d.sprite_only or not _decor_in(d):
			continue
		var at_g: Vector2 = d.at
		ctx.env.remove_decor(d)
		removed += 1
		if staged:
			FxParts.debris(self, Iso.ground_to_screen(at_g), 5, 4.0, Vector2(40, 140), TIMBER, Vector2(1, 3), true)
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


## A house torn in two (look): a gilt seam drawn through it along the line, and a second half of debris thrown to the
## other side of the line from its own.
func _split(s: Structure) -> void:
	var c := s.center()
	var half_along := 0.5 * (absf(s.footprint.size.x * dir.x) + absf(s.footprint.size.y * dir.y))
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


## The thrown in the air, eased out to where they land.
func _fx_process(_delta: float) -> void:
	if _flying.is_empty() or t < T_TEAR:
		return
	var k := clampf((t - T_TEAR) / T_THROW, 0.0, 1.0)
	k = 1.0 - (1.0 - k) * (1.0 - k)
	for e: Variant in _flying:
		if is_instance_valid(e) and e.is_alive():
			var fl: Array = _flying[e]
			e.ground_pos = (fl[0] as Vector2).lerp(fl[1], k)


## The thrown come down, knocked flat; the rubble is piled along both sides.
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
	_clear_ruins()
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
## what it tears up), one only partly in it too -- its halves fell to either side, into the rubble lines. Its node is
## kept, hidden (remove()'s keep_node): a mission may hold that house, and holds a fallen one, never a freed object; a
## shelter forgets it. Kept as ruins: the town's own gates, bridges, postern, dock and fountain and the Citadel's parts,
## which the town's managers go on using (evacuation, the engineers' rebuilding, the river's crossings).
func _clear_ruins() -> void:
	var keep: Array = []
	var town: Town = ctx.crowd._town if ctx.crowd != null else null
	if is_instance_valid(town):
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
	for s in _torn:
		if not is_instance_valid(s) or not s.destroyed or not ctx.env.structures().has(s) or keep.has(s) \
				or s.role == &"citadel":
			continue
		if ctx.crowd != null and ctx.crowd.shelters != null:
			ctx.crowd.shelters.shelters.erase(s)
		ctx.env.remove(s, true, true)
		cleared += 1
	_torn.clear()


## The heaps: along each long side one every LENGTH / n (n the fewest that keeps them HEAP_EVERY apart), sized by index,
## each GAP off the street's edge. None on the water, none in a standing building; whoever stands where one lands is
## moved out past it first (as the thrown are).
func _lay() -> void:
	var n := maxi(1, ceili(LENGTH / HEAP_EVERY))
	for way in [1.0, -1.0]:
		for k in n:
			var along := (float(k) + 0.5) * LENGTH / float(n)
			var size := HEAP * (0.8 + 0.2 * fposmod(float(k) * 0.618034 + (0.0 if way > 0.0 else 0.5), 1.0))
			var c: Vector2 = origin + dir * along + side * float(way) * (HALF_W + GAP + _ext(size))
			var rect := Rect2(c - Vector2(size, size) * 0.5, Vector2(size, size))
			if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.encloses(rect):
				continue
			if _wet(rect) or _blocked(rect):
				continue
			for e in ctx.field.in_rect(rect.grow(WalkGrid.BODY)):
				var p := e as Person
				if p == null or not p.inside:
					e.ground_pos = _landing(e.ground_pos, way)
			heaps.append(LawRubble.lay(ctx.env, rect, HEAP_H * (0.8 + 0.4 * fposmod(float(k) * 0.381966, 1.0))))


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


## The strip on the ground, drawn in ground units: through the claim an ink wash run out from the press with gilt edges,
## survey stakes across them and letters of law down the middle; at the tear a white-gold flash over it and gilt seams
## through every house it splits; then the gilt edges of the new street, fading. Laid out once.
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
