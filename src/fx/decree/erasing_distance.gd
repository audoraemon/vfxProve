class_name EraseFx
extends FxTimeline
## Erasing Distance (Decree, Tier III; spec 5.5; review R4): the distance along a dragged line is erased, and everything
## on it is folded back into where it starts. The line runs from the press (origin) along the drag (extra "dir"), as
## long as the drag (extra "to"), clamped to MIN_LEN..MAX_LEN; DEFAULT_LEN when no end is given (the sandbox, scripted
## casts). Three stages, then what it leaves:
## 1. The seam (T_SEAM): a gilt seam runs down the line and the ground on both sides puckers toward it.
## 2. The fold (T_FOLD): the line folds up into its start like cloth. Everyone within CRUSH_W of it (indoors excepted) is
##    caught and dragged along it to the press; every building the line crosses slides down it to the press too,
##    cracking, shrinking and crumbling as it goes with dust trailing; and the decor within CRUSH_W (barrels, carts,
##    lamps) slides with them. When the fold shuts the caught are crushed at the press (kill kind crushed) and their
##    bodies lie piled there; those sheltering in a building it took, or trapped under its ruins, die with it. Each
##    building is brought down and taken away whole when it arrives (EnvironmentField.remove's keep_node, as Eminent
##    Domain takes its ruins), and the decor is taken away (EnvironmentField.remove_decor). One the town's managers go on
##    using (a gate, a bridge, the postern, the dock, the fountain) or whose health another owns (the Citadel's) does not
##    slide: it is dealt the blow where it stands. Every building within CRACK_W of the line cracks where it stands.
## 3. The spring back (T_SNAP after the close): the fold snaps open. Whoever stands within THROW_W of the line is thrown
##    outward, harder the nearer, and knocked down.
## Leaves: the line bare, its cells open to walk (WalkGrid.open_street(), the river excepted), and everything it took
## merged at its start: one mound of law rubble (LawRubble.lay) clustered round the press -- 1 heap, 1 more per building
## taken and 1 per 3 pieces of decor, HEAP_CAP at most -- each building's heap wearing that building's own ruins art. The
## heaps close the walk grid until the town's engineers clear them; none is laid on the water or in a standing building,
## and anyone standing where one lands is pushed out first. Who is taken, what slides and where the heaps lie follow
## distance and order only, never a roll. Loud (PowerBook.REACH): its danger lands when the fold closes.

const MAX_LEN := 10.0
const MIN_LEN := 2.0
const DEFAULT_LEN := 6.0
## People and decor this near the line are folded into its start; buildings are taken when the line crosses them.
const CRUSH_W := 1.0
## Buildings this near the line (and not taken) crack where they stand.
const CRACK_W := 2.0
## The spring back throws whoever stands this near the line.
const THROW_W := 3.0
const T_SEAM := 0.6
const T_FOLD := 1.5
const T_SNAP := 0.15
## How long the scar of the seam shows after the spring back (look only).
const SCAR := 2.4
## The throw: speed at the line, and at THROW_W.
const KNOCK_NEAR := 3.2
const KNOCK_FAR := 1.4
## A cracked building is left below Structure.CRACK_AT by this much of its health.
const CRACK_BELOW := 0.05
## A building or piece of decor sliding to the start is drawn this much of its size when it arrives, and its height
## squashed by SQUASH of that (look only).
const SHRINK := 0.3
const SQUASH := 0.3
## The bodies lie piled at the press: the n-th crushed BODY_SPREAD * sqrt(n) from it, round a golden-angle spiral.
const BODY_SPREAD := 0.09
## The mound: its heaps on rings RING apart round a point MOUND_BACK behind the press (away from the line), so the bodies
## lie at its foot; none comes within FOOT of the press. HEAP_CAP heaps at most, RINGS rings of candidate spots.
const MOUND_BACK := 0.8
const RING := 0.8
const RINGS := 3
const FOOT := 0.25
const HEAP_CAP := 8
## A building's heap is HEAP_BIG across; a generic heap HEAP (varied by order). Heights the same way.
const HEAP := 0.9
const HEAP_BIG := 1.0
const HEAP_H := 9.0
const HEAP_BIG_H := 11.0
## Dust and crumbs trail the buildings sliding, a burst every DUST_EVERY seconds (look only).
const DUST_EVERY := 0.08

## The line: its direction and length, and where it ends.
var dir := Vector2.RIGHT
var length := DEFAULT_LEN
var to := Vector2.ZERO
## Whoever the fold has caught: DummyEnemy -> [where it was caught, the fold's progress then, its place in the pile].
var caught := {}
## What it took: people crushed, buildings taken whole, decor taken away, buildings dealt the blow where they stand and
## cracked, people thrown; the heaps it left.
var crushed := 0
var taken := 0
var removed := 0
var struck := 0
var cracked := 0
var thrown := 0
var heaps: Array[Structure] = []

var _closed := false
var _seam: Seam
## The buildings sliding to the start, nearest it first: [Structure, its centre, its node's resting place (its front
## corner on screen), that corner's offset to its centre on screen].
var _slides: Array = []
## The decor sliding to the start: [Decor, where it stood].
var _goods: Array = []
## The buildings the line crosses that do not slide (dealt the blow at the close).
var _blows: Array[Structure] = []
## Bodies laid in the pile so far.
var _bodies := 0
## The trail (look only): dust and crumbs, and the next burst's time.
var _dust: PixelParticles
var _crumbs: PixelParticles
var _next_dust := 0.0
var _dust_spec := {"radius": 5.0, "speed": Vector2(4, 16), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(0, 4),
	"alt_speed": Vector2(2, 10), "life": Vector2(0.35, 0.7), "size": Vector2(1.5, 3), "size_end_mul": 1.4,
	"offset": Vector2.ZERO}
var _crumb_spec := {"radius": 8.0, "speed": Vector2(10, 50), "alt": Vector2(4, 18), "alt_speed": Vector2(20, 70),
	"life": Vector2(0.5, 1.0), "size": Vector2(1.5, 3.0), "offset": Vector2.ZERO}


func _build() -> void:
	var drag: Vector2 = extra.get("dir", Vector2.ZERO)
	var end: Vector2 = extra.get("to", Vector2.INF)
	if drag.length() < 0.01 and end != Vector2.INF:
		drag = end - origin
	dir = drag.normalized() if drag.length() >= 0.01 else Vector2.RIGHT
	length = clampf(origin.distance_to(end), MIN_LEN, MAX_LEN) if end != Vector2.INF else DEFAULT_LEN
	to = origin + dir * length
	duration = T_SEAM + T_FOLD + T_SNAP + SCAR
	busy = T_SEAM + T_FOLD + T_SNAP
	at(T_SEAM, _fold)
	at(T_SEAM + T_FOLD, _close)
	at(T_SEAM + T_FOLD + T_SNAP, _spring)
	ctx.play(&"er_tear", middle())
	if not DominionParts.staged(self):
		return
	DecreeParts.proclaim(self, middle(), 54.0, 70.0, T_SEAM, 0.8)
	_seam = Seam.new()
	_seam.fx = self
	_seam.z_index = 4
	track(_seam, ctx.ground)


## The middle of the line (where its proclamation hangs).
func middle() -> Vector2:
	return origin + dir * length * 0.5


## How far `g` is from the line (the segment, ends included).
func off_line(g: Vector2) -> float:
	return g.distance_to(_nearest(g))


func _nearest(g: Vector2) -> Vector2:
	return origin + dir * clampf((g - origin).dot(dir), 0.0, length)


## How far the fold has closed, 0..1 (eased: slow to start, fast to shut).
func fold_k() -> float:
	var k := clampf((t - T_SEAM) / T_FOLD, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k) if k < 0.5 else 1.0 - 2.0 * (1.0 - k) * (1.0 - k)


## Where the `n`-th body lies in the pile at the press.
func pile_spot(n: int) -> Vector2:
	if n <= 0:
		return origin
	return origin + Vector2.from_angle(float(n) * 2.39996) * BODY_SPREAD * sqrt(float(n))


## The middle of the mound: MOUND_BACK behind the press, away from the line.
func mound() -> Vector2:
	return origin - dir * MOUND_BACK


## The fold begins: the ground gives, the line starts to draw in, and what stands on it starts to slide.
func _fold() -> void:
	_catch()
	_take_hold()
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.25)
	var sp := Iso.ground_to_screen(origin)
	FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, DecreeParts.GILT_LIFE, 30.0, T_FOLD,
		{"radius": 28.0, "speed": Vector2(20, 60), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 4),
			"alt_speed": Vector2(4, 20), "life": Vector2(0.3, 0.7), "size": Vector2(1, 2)})
	DominionParts.pulse(self, origin, 1.2, DecreeParts.AMBER_LIGHT, 0.5, T_FOLD)
	_dust = FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, FxParts.DUST_LIFE)
	_dust.drag = 1.2
	_dust.auto_free = false
	_crumbs = FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.CHUNK, FxParts.ROCK)
	_crumbs.gravity = 420.0
	_crumbs.bounce = true
	_crumbs.drag = 0.6
	_crumbs.shadows = true
	_crumbs.auto_free = false


## What the line takes hold of as the fold begins: every building it crosses (nearest the press first) -- to slide, or,
## for one the town's managers use or whose health another owns, to be struck where it stands -- and the decor within
## CRUSH_W of it (none that belongs on the water).
func _take_hold() -> void:
	var keep := _kept()
	var slides: Array[Structure] = []
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.taken or not _within(s, 0.0):
			continue
		if keep.has(s) or s.role == &"citadel" or s.damage_filter.is_valid():
			_blows.append(s)
		else:
			slides.append(s)
	slides.sort_custom(func(a: Structure, b: Structure) -> bool:
		var da := (a.center() - origin).dot(dir)
		var db := (b.center() - origin).dot(dir)
		if not is_equal_approx(da, db):
			return da < db
		return a.center().x < b.center().x if not is_equal_approx(a.center().x, b.center().x) else a.center().y < b.center().y)
	for s in slides:
		var base := s.base_position()
		_slides.append([s, s.center(), base, Iso.ground_to_screen(s.center()) - base])
		s.crack()
	for d in ctx.env.decor():
		if is_instance_valid(d) and not d.sprite_only and not d.kind in Decor.ON_WATER and off_line(d.at) <= CRUSH_W:
			_goods.append([d, d.at])


## The town's structures its managers go on using (evacuation, the engineers' rebuilding, the river's crossings): the
## gates, the bridges, the postern, the dock and the fountain. None slides; a blow brings them down as ruins.
func _kept() -> Array:
	var keep: Array = []
	var town: Town = ctx.crowd._town if ctx.crowd != null else null
	if is_instance_valid(town):
		keep.append_array(town.gates)
		keep.append_array(town.bridges)
		keep.append_array([town.bridge, town.postern, town.dock, town.fountain])
	return keep


func _fx_process(delta: float) -> void:
	if t < T_SEAM or _closed:
		return
	_catch()
	var k := fold_k()
	for e: Variant in caught:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var from: Vector2 = caught[e][0]
		var k0: float = caught[e][1]
		e.ground_pos = from.lerp(pile_spot(caught[e][2]), clampf((k - k0) / maxf(1.0 - k0, 0.001), 0.0, 1.0))
	for sl: Array in _slides:
		_place(sl, k)
	var sc := lerpf(1.0, SHRINK, k)
	for gd: Array in _goods:
		var d: Decor = gd[0]
		if not is_instance_valid(d):
			continue
		var want := (gd[1] as Vector2).lerp(origin, k)
		if not want.is_equal_approx(d.at):
			d.shift(want - d.at)
		d.scale = Vector2(sc, sc * (1.0 - SQUASH * k))
		for f in d.followers:
			if is_instance_valid(f):
				f.scale = d.scale
	if DominionParts.staged(self):
		ctx.shake.add_trauma(minf(delta * 0.5, 0.05))
		if t >= _next_dust:
			_next_dust = t + DUST_EVERY
			_trail(k)


## A sliding building drawn where the fold has brought it (`k` of the way to the press), shrunk and squashed, shaking:
## its node moved and scaled so that its footprint's centre is drawn there. Its footprint (what blocks the walk grid)
## stays where it stood until it is taken at the close.
func _place(sl: Array, k: float) -> void:
	var s: Structure = sl[0]
	if not is_instance_valid(s) or s.taken:
		return
	var sc := Vector2(lerpf(1.0, SHRINK, k), lerpf(1.0, SHRINK, k) * (1.0 - SQUASH * k))
	var at := Iso.ground_to_screen((sl[1] as Vector2).lerp(origin, k)) - (sl[3] as Vector2) * sc
	at = at.round()
	s.scale = sc
	# Structure's shudder puts its node back on _base (its resting corner): moved with it, the shudder shakes it here.
	s._base = at
	s.position = at
	if k > 0.0:
		s.shake(1.0 + 2.0 * k)


## The node of a building that slid back where it rests, at its own size (it is hidden once taken; a cut-short fold
## leaves it standing where it stood).
func _unplace(sl: Array) -> void:
	var s: Structure = sl[0]
	if not is_instance_valid(s):
		return
	s.scale = Vector2.ONE
	s._base = sl[2]
	s.position = sl[2]


## Dust and crumbs off the buildings sliding (look only).
func _trail(k: float) -> void:
	var o := Iso.ground_to_screen(origin)
	for sl: Array in _slides:
		var s: Structure = sl[0]
		if not is_instance_valid(s) or s.taken:
			continue
		var off := Iso.ground_to_screen((sl[1] as Vector2).lerp(origin, k)) - o
		_dust_spec["offset"] = off
		_dust.burst(2, _dust_spec)
		_crumb_spec["offset"] = off + Vector2(0.0, -s.height * 0.4 * lerpf(1.0, SHRINK, k))
		_crumbs.burst(2, _crumb_spec)


## Whoever stands within CRUSH_W of the line now and is not caught yet is caught where he stands (indoors excepted),
## and given his place in the pile.
func _catch() -> void:
	var k := fold_k()
	for e in ctx.field.in_radius(middle(), length * 0.5 + CRUSH_W):
		if caught.has(e):
			continue
		var p := e as Person
		if p != null and p.inside:
			continue
		if off_line(e.ground_pos) <= CRUSH_W:
			caught[e] = [e.ground_pos, k, _bodies]
			_bodies += 1
			if p != null:
				p.scream(T_FOLD + 0.1)


## The fold shuts: the caught are crushed at the press, the buildings that slid there are brought down and taken away
## whole with whoever was in them, the decor is taken, those the line crosses that did not slide are struck, those near
## it crack; the line opens to walk and the mound is laid round the press.
func _close() -> void:
	_catch()
	_closed = true
	for e: Variant in caught:
		if not is_instance_valid(e) or not e.is_alive():
			continue
		var p := e as Person
		if p != null and p.inside:
			continue
		e.ground_pos = pile_spot(caught[e][2])
		if ctx.field.kill(e, &"crushed", origin):
			crushed += 1
	caught.clear()
	var froms: Array[Structure] = []
	for sl: Array in _slides:
		var s: Structure = sl[0]
		if not is_instance_valid(s):
			continue
		_place(sl, 1.0)
		if s.taken or not ctx.env.structures().has(s):
			_unplace(sl)
			continue
		_take_people(s)
		if not s.destroyed:
			s.destroy(s.center() + dir, &"stone")
		if ctx.crowd != null and ctx.crowd.shelters != null:
			ctx.crowd.shelters.shelters.erase(s)
		ctx.env.remove(s, true, true)
		_unplace(sl)
		taken += 1
		froms.append(s)
	_slides.clear()
	for s in _blows:
		if is_instance_valid(s) and not s.destroyed:
			s.damage(99999.0, s.center() + dir, &"stone")
			struck += 1
	_crack()
	for gd: Array in _goods:
		var d: Decor = gd[0]
		if is_instance_valid(d) and ctx.env.decor().has(d):
			ctx.env.remove_decor(d)
			removed += 1
	_goods.clear()
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	if grid != null:
		grid.open_street(origin, dir, length, CRUSH_W)
	_lay(froms)
	ctx.play(&"er_crash", origin)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(1.0, 0.9, 0.6, 0.35), 0.25)
	ctx.impact.hitstop(0.07)
	ctx.impact.aberration(2.5, 0.35)
	ctx.shake.add_trauma(0.7)
	ctx.shake.kick(Vector2(0, 5))
	FxParts.debris(self, sp, 26, 12.0, Vector2(40, 220), FxParts.ROCK, Vector2(2, 5), true)
	DecreeParts.scatter(self, origin, 24, 10.0)
	DecreeParts.wave(self, origin, CRUSH_W + 1.2, 0.35, 0.12)


## Those sheltering in `s`, or trapped under it (its ruins), go into the fold with it: crushed at the press.
func _take_people(s: Structure) -> void:
	if ctx.crowd == null:
		return
	if ctx.crowd.rescue != null:
		for tr: Dictionary in ctx.crowd.rescue.trapped.duplicate():
			if tr.site != s:
				continue
			ctx.crowd.rescue.trapped.erase(tr)
			var q = tr.p
			if not is_instance_valid(q):
				continue
			var p: Person = q
			p.inside = false
			p.visible = true
			ctx.field.add(p)
			_crush(p)
	if ctx.crowd.shelters != null:
		for p in ctx.crowd.shelters.throw_out_of(s, 0.0):
			_crush(p)


func _crush(e: DummyEnemy) -> void:
	e.ground_pos = pile_spot(_bodies)
	_bodies += 1
	if ctx.field.kill(e, &"crushed", origin):
		crushed += 1


## Every building within CRACK_W of the line that still stands (not law rubble, not one the line struck) cracks.
func _crack() -> void:
	var side := dir.orthogonal()
	for s: Structure in ctx.env.structures().duplicate():
		if not is_instance_valid(s) or s.destroyed or s.role == LawRubble.ROLE or _blows.has(s) or not _within(s, CRACK_W):
			continue
		var keep := s.max_hp * (Structure.CRACK_AT - CRACK_BELOW)
		var rel := s.center() - origin
		var from := s.center() - side * signf(rel.dot(side) if absf(rel.dot(side)) > 0.001 else 1.0)
		if s.hp > keep:
			s.damage(s.hp - keep, from, &"stone")
		s.crack()
		s.shake(4.0)
		cracked += 1


## Whether `s`'s footprint comes within `w` of the line (the band [-w, length + w] along it, w across).
func _within(s: Structure, w: float) -> bool:
	var side := dir.orthogonal()
	var half := s.footprint.size * 0.5
	var rel := s.center() - origin
	var along := rel.dot(dir)
	var ext_along := absf(half.x * dir.x) + absf(half.y * dir.y)
	var ext_side := absf(half.x * side.x) + absf(half.y * side.y)
	return along + ext_along >= -w and along - ext_along <= length + w and absf(rel.dot(side)) <= w + ext_side


## The fold snaps open: whoever stands within THROW_W of the line is thrown outward and knocked down.
func _spring() -> void:
	var side := dir.orthogonal()
	for e in ctx.field.in_radius(middle(), length * 0.5 + THROW_W):
		var p := e as Person
		if p != null and p.inside:
			continue
		var d := off_line(e.ground_pos)
		if d > THROW_W:
			continue
		var away := e.ground_pos - _nearest(e.ground_pos)
		if away.length() < 0.01:
			away = side
		e.knock(away.normalized() * lerpf(KNOCK_NEAR, KNOCK_FAR, clampf(d / THROW_W, 0.0, 1.0)))
		if p != null:
			p.knock_down()
		thrown += 1
	if not DominionParts.staged(self):
		return
	ctx.shake.add_trauma(0.45)
	for k in 3:
		var at_g := origin + dir * length * (0.5 * float(k))
		DecreeParts.wave(self, at_g, THROW_W, 0.45, 0.06)


## The candidate spots of the mound, in the order they are filled: its middle (mound()), then ring after ring RING
## apart round it, each ring from straight back from the line round both ways in turn to the front.
func mound_spots() -> Array[Vector2]:
	var c := mound()
	var out: Array[Vector2] = [c]
	var back := (-dir).angle()
	for r in range(1, RINGS + 1):
		var n := 6 * r
		for j in n:
			var step := ((j + 1) / 2) * (1 if j % 2 == 1 else -1)
			out.append(c + Vector2.from_angle(back + TAU * float(step) / float(n)) * RING * float(r))
	return out


## The mound: one heap for the fold, one per building taken (`froms`, nearest the press first, each wearing its own
## ruins) and one per 3 pieces of decor, HEAP_CAP at most -- the buildings' first. Each goes on the next spot of
## mound_spots() that is in the map, dry, clear of standing buildings and not within FOOT of the press (the bodies' pile);
## whoever stands where one lands is pushed out first.
func _lay(froms: Array[Structure]) -> void:
	var want: Array = []
	for s in froms:
		want.append(s)
	for k in 1 + removed / 3:
		want.append(null)
	want.resize(mini(want.size(), HEAP_CAP))
	var spots := mound_spots()
	var next := 0
	for k in want.size():
		var from: Structure = want[k]
		var size := HEAP_BIG if from != null else HEAP * (0.85 + 0.15 * fposmod(float(k) * 0.618034, 1.0))
		var h := (HEAP_BIG_H if from != null else HEAP_H) * (0.85 + 0.3 * fposmod(float(k) * 0.381966, 1.0))
		while next < spots.size():
			var rect := Rect2(spots[next] - Vector2(size, size) * 0.5, Vector2(size, size))
			next += 1
			if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.encloses(rect):
				continue
			if rect.grow(FOOT).has_point(origin) or _wet(rect) or _blocked(rect):
				continue
			for e in ctx.field.in_rect(rect.grow(WalkGrid.BODY)):
				var p := e as Person
				if p == null or not p.inside:
					_push_out(e, rect)
			heaps.append(LawRubble.lay(ctx.env, rect, h, from))
			break


## Moves `e` out of `rect` (and its walk-grid margin), straight away from the mound's middle, onto open ground (the walk
## grid's) when there is some within reach.
func _push_out(e: DummyEnemy, rect: Rect2) -> void:
	var way := e.ground_pos - mound()
	way = way.normalized() if way.length() > 0.01 else -dir
	var clear := rect.grow(WalkGrid.BODY + 0.05)
	var grid: WalkGrid = ctx.crowd._grid if ctx.crowd != null else null
	var first := Vector2.INF
	for k in 12:
		var at_g := e.ground_pos + way * 0.25 * float(k + 1)
		if clear.has_point(at_g):
			continue
		if first == Vector2.INF:
			first = at_g
		if ctx.field.bounds.size != Vector2.ZERO and not ctx.field.bounds.has_point(at_g):
			continue
		if grid == null or grid.walkable(at_g):
			e.ground_pos = at_g
			return
	if first != Vector2.INF:
		e.ground_pos = first


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


## Cut short mid-fold (an act of the night ends with it playing): what was sliding is put back where it stands, at its
## own size; the decor stays where the fold had brought it.
func end_now() -> void:
	if not finished and not _closed:
		for sl: Array in _slides:
			_unplace(sl)
		for gd: Array in _goods:
			if is_instance_valid(gd[0]):
				(gd[0] as Decor).scale = Vector2.ONE
				for f in (gd[0] as Decor).followers:
					if is_instance_valid(f):
						f.scale = Vector2.ONE
	super.end_now()


## The seam on the ground, drawn in ground units: an ink-and-gilt line run down from the press while the seam opens,
## the ground's creases puckering toward it on both sides and leaning back to the press; through the fold the whole of
## it draws in to the press; after the spring back a gilt scar down the bare line that fades. Its creases are laid out
## once.
class Seam extends Node2D:
	const CREASE_EVERY := 0.42
	var fx: EraseFx
	## Along, and a lean back toward the press, of each crease.
	var _creases: Array[Vector2] = []
	var _band := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])

	func _ready() -> void:
		var along := CREASE_EVERY * 0.5
		var k := 0
		while along < fx.length:
			_creases.append(Vector2(along, 0.12 + 0.12 * fposmod(float(k) * 0.618034, 1.0)))
			along += CREASE_EVERY
			k += 1

	func _process(_delta: float) -> void:
		queue_redraw()

	## Where a ground point of the line (`along`, `across`) is drawn while the fold is `k` shut: drawn in to the press.
	func _at(along: float, across: float, k: float) -> Vector2:
		return fx.origin + fx.dir * along * (1.0 - k) + fx.dir.orthogonal() * across * (1.0 - 0.7 * k)

	func _draw() -> void:
		var now := fx.t
		var open := clampf(now / (T_SEAM * 0.85), 0.0, 1.0)
		var shut := now >= T_SEAM + T_FOLD
		if not shut:
			var k := fx.fold_k()
			# The ground drawn in: an ink band where the cloth gathers.
			var w := CRUSH_W * (0.35 + 0.65 * open)
			_band[0] = _at(0.0, w, k)
			_band[1] = _at(fx.length * open, w, k)
			_band[2] = _at(fx.length * open, -w, k)
			_band[3] = _at(0.0, -w, k)
			draw_colored_polygon(_band, Color(DecreeParts.INK, 0.16 + 0.22 * k))
			# The creases, puckering toward the seam from both sides, leaning back to the press, gathering in with the fold.
			for c in _creases:
				if c.x > fx.length * open:
					break
				for si in 2:
					var s := -1.0 if si == 0 else 1.0
					var near_p := _at(c.x, s * 0.12, k)
					var far_p := _at(c.x + c.y, s * (CRUSH_W + 0.45) * open, k)
					draw_line(near_p, far_p, Color(DecreeParts.INK, 0.75 * open), 0.1)
					draw_line(near_p, near_p.lerp(far_p, 0.6), Color(DecreeParts.GILT, 0.5 * open), 0.04)
			# The seam: ink under gilt, a bright core that pulses as the fold pulls.
			var a := _at(0.0, 0.0, k)
			var b := _at(fx.length * open, 0.0, k)
			var pulse := 0.75 + 0.25 * sin(now * 18.0)
			draw_line(a, b, Color(DecreeParts.INK, 0.9), 0.3)
			draw_line(a, b, Color(DecreeParts.GILT, 0.95), 0.15)
			draw_line(a, b, Color(1.0, 0.97, 0.85, pulse), 0.05)
			return
		# The scar: the line back at its length, bare, fading from its far end to the press.
		var fade := clampf(1.0 - (now - T_SEAM - T_FOLD - T_SNAP) / SCAR, 0.0, 1.0)
		if fade <= 0.0:
			return
		var a := fx.origin
		var b := fx.origin + fx.dir * fx.length * clampf(fade * 1.4, 0.0, 1.0)
		draw_line(a, b, Color(DecreeParts.INK, 0.8 * fade), 0.22)
		draw_line(a, b, Color(DecreeParts.GILT, 0.9 * fade), 0.1)
