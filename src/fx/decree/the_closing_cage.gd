class_name CageFx
extends FxTimeline
## The Closing Cage (Decree, Tier V; spec 5.9; the user's idea, a bird cage made into law): a ring of brass bars carved
## with law rises round a district of RADIUS about the click, and from T_LAND, over CLOSE_TIME, slides in at an even pace
## toward the middle until it is END_R across the half (1.5 across). Nobody can pass the bars: they are one NO LEAVING law
## (LawZone) whose radius this effect shrinks each frame, so the zone's own clamp pushes everyone held -- people and
## visitors -- inward ahead of the bars. Walking in is free, and whoever walks in during the close is caged too. Whoever
## stood outside RADIUS at the cast is untouched.
##   Cut down  one whose inward step is blocked -- the point the bars would push him to lies in the footprint of a
##             building the bars have not yet felled -- is cut down where he stands (kill kind crushed), the frame the
##             ring reaches him. A visitor too.
##   Crushed   every building the bars reach cracks the frame they touch its footprint (Structure.crack) and falls when
##             they pass its middle (Structure.destroy; the Citadel's parts are dealt the blow through their owner);
##             whoever shelters in it dies with it. One the ring stands across at the cast cracks at once, and falls only
##             if its middle lies inside. Gates, bridges and fields (walkable) are passed through untouched: nobody is
##             pinned against them, and the town's crossings and queues keep them, as Eminent Domain keeps their ruins.
##   The end  at T_LAND + CLOSE_TIME everyone still inside END_R dies (kill kind crushed), and whatever still stands
##             there falls: only the centre point is left.
## Indoors and a rite's chained captive are left to the law as it holds them (LawZone): the one sheltering dies with his
## house; the chained one is not held, so the bars pass him by. Who dies follows distance and order only, never a roll.
## Level 5 (Dragged Cage): once while it closes a click drags the whole cage toward it, up to DRAG_MAX over DRAG_TIME. The
## people and visitors it holds are carried with it (each still held inside the bars), the ring's reach sweeps the
## buildings on its way (cracked as it touches them, felled as it crosses their middles), and the law's centre moves with it.
## Loud (PowerBook.REACH): its danger lands as the bars stand. Its frame is cheap: each building's distances are taken
## once at the landing and walked in order as the ring closes; only the buildings the ring is passing through are asked
## whether they pin anyone; no list is built per frame.

const RADIUS := 12.0
const END_R := 0.75
const CLOSE_TIME := 30.0
## The bars rise out of the ground, and the law holds from when they stand.
const T_LAND := 0.8
## The bars sink and fade this long after the end (look only).
const FADE := 1.0
## The kill kind of the bars: cut down, crushed with a house the bars fell, and crushed at the end. Its own kind, not
## the town's collapse (a house falling on its shelterers): the body is left whole and lies DummyEnemy.BODY_HOLD
## (Remains.BODY_KINDS), and the death is loud.
const KIND := &"crushed"
## Leeway on distances computed onto the ring.
const EPS := 0.0001
## Dragged Cage (level 5): the furthest the click moves the centre, and how long the move takes.
const DRAG_MAX := 6.0
const DRAG_TIME := 2.0

## The law on the place (LawZone, NO LEAVING), its radius the ring's: laid at T_LAND, lifted at the end. null before.
var law: LawZone
## The ring's radius now.
var radius := RADIUS
## How many the bars have cut down, how many died at the end, and how many buildings they cracked and felled.
var cut := 0
var crushed := 0
var cracked := 0
var felled := 0
## Whether the cage has shut (the end has come).
var shut := false

## Each building the ring reaches, taken once at the landing: the building, its footprint, and the ring's radius when it
## touches it (its farthest corner), passes its middle, and leaves it (its nearest point).
var _s: Array[Structure] = []
var _rect: Array[Rect2] = []
var _far := PackedFloat32Array()
var _mid := PackedFloat32Array()
var _near := PackedFloat32Array()
## The buildings in the order the ring touches them, and in the order it passes their middles (only those inside RADIUS);
## how far along each it has come.
var _by_far := PackedInt32Array()
var _by_mid := PackedInt32Array()
var _touched := 0
var _passed := 0
## The buildings the ring is passing through now (touched, still standing, not yet left): the only ones that can pin.
var _band := PackedInt32Array()
## Those to cut down this frame (kept, cleared after use).
var _doomed: Array = []
var _grind: Node
var _cage: Cage

## Dragged Cage: whether this cast has the twist, the ring's centre now (the cast's point until a drag), whether the drag has been
## spent and whether it is under way, where it goes from and to and when it began (the effect's clock).
var _twist := false
var _c := Vector2.ZERO
var dragged := false
var _drag_on := false
var _drag_from := Vector2.ZERO
var _drag_to := Vector2.ZERO
var _drag_t0 := 0.0
## The buildings the drag can reach, taken when it begins (indices into these four), what each was to the ring last frame
## (0 wholly inside, 1 across the bars, 2 wholly outside), whether its middle was inside, and whether it has been cracked.
var _ds: Array[Structure] = []
var _dr: Array[Rect2] = []
var _dstate := PackedByteArray()
var _dmid := PackedByteArray()
var _dcrk := PackedByteArray()
## The footprints of the cracked, standing buildings the ring is passing through while it is dragged.
var _dband: Array[Rect2] = []
## Buildings cracked (by instance id) once a drag has begun, so the sorted walk after it never cracks one twice.
var _cracked_ids := {}


## The ring's radius at `time` on the effect's clock: RADIUS until the bars stand, END_R once they have closed, an even
## pace in between.
static func radius_at(time: float, start := RADIUS, close_time := CLOSE_TIME) -> float:
	return lerpf(start, END_R, clampf((time - T_LAND) / close_time, 0.0, 1.0))


## This cast's numbers at its ability level (the consts at level 1).
var lv_radius := RADIUS
var lv_close_time := CLOSE_TIME


func _build() -> void:
	_twist = PowerBook.twist_at(extra, "cage")
	_c = origin
	lv_radius = float(PowerBook.stat(extra, "cage", "RADIUS", RADIUS))
	lv_close_time = float(PowerBook.stat(extra, "cage", "CLOSE_TIME", CLOSE_TIME))
	radius = lv_radius
	duration = T_LAND + lv_close_time + FADE
	busy = T_LAND
	at(T_LAND, _land)
	at(T_LAND + lv_close_time, _shut)
	ctx.play(&"cg_rise", origin)
	if not DominionParts.staged(self):
		return
	DecreeParts.proclaim(self, origin, 90.0, 84.0, T_LAND, 0.7)
	_cage = Cage.new()
	_cage.fx = self
	_cage.position = Iso.ground_to_screen(origin).round()
	_cage.z_index = 4
	track(_cage, ctx.overhead_back)
	ctx.shake.add_trauma(0.25)


## The bars stand: the law holds, and every building the ring will reach is taken down in order.
func _land() -> void:
	_survey(lv_radius)
	law = LawZone.circle(_c, lv_radius, [LawZone.NO_LEAVING], lv_close_time)
	law.stepped_by_holder = true
	if ctx.crowd != null:
		ctx.crowd.add_law(law, self)
	else:
		law.hold_by(self)
	_close(lv_radius)
	_step_law(0.0)  # whoever stands inside is caged from this frame
	_grind = ctx.play(&"cg_grind", origin, -5.0)
	if not DominionParts.staged(self):
		return
	DecreeParts.wave(self, origin, lv_radius * 1.04, 0.7, 0.04)
	var plate := DecreeParts.seal(self, origin, DecreeParts.BARS, 2.4, 96.0, 4)
	plate.shrink_at = 1.6
	plate.shrink_px = 2
	ctx.shake.add_trauma(0.4)


## Every standing building (walkable ground excepted) some of whose footprint lies inside RADIUS: its distances, once.
func _survey(reach: float) -> void:
	var order_far: Array[int] = []
	var order_mid: Array[int] = []
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var f := s.footprint
		var near := _c.clamp(f.position, f.end).distance_to(_c)
		if near >= reach:
			continue
		var far := 0.0
		for corner in [f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)]:
			far = maxf(far, (corner as Vector2).distance_to(_c))
		var i := _s.size()
		_s.append(s)
		_rect.append(f)
		_far.append(far)
		_mid.append(f.get_center().distance_to(_c))
		_near.append(near)
		order_far.append(i)
		if _mid[i] < reach:
			order_mid.append(i)
	# Farthest first, and by the order the town lists them where two tie: no roll.
	order_far.sort_custom(func(x: int, y: int) -> bool: return _far[x] > _far[y] if _far[x] != _far[y] else x < y)
	order_mid.sort_custom(func(x: int, y: int) -> bool: return _mid[x] > _mid[y] if _mid[x] != _mid[y] else x < y)
	for i in order_far:
		_by_far.append(i)
	for i in order_mid:
		_by_mid.append(i)


func _fx_process(delta: float) -> void:
	if law == null or shut or not law.alive():
		return
	if _drag_on:
		_drag_frame(clampf((t - _drag_t0) / DRAG_TIME, 0.0, 1.0), radius_at(t, lv_radius, lv_close_time))
	else:
		_close(radius_at(t, lv_radius, lv_close_time))
	# The law's clock starts when the bars stand.
	_step_law(minf(delta, t - T_LAND))


## The law steps with the ring's radius: the zone's own clamp pushes whoever it holds in ahead of the bars.
func _step_law(delta: float) -> void:
	law.radius = radius
	if ctx.crowd != null:
		ctx.crowd.step_law(law, delta)
	else:
		law.step(delta, ctx.field.in_rect(law.bounds()), [])


## The ring comes in to `r`: the buildings it touches crack, those whose middle it passes fall, and whoever it would push
## into a building still standing is cut down.
func _close(r: float) -> void:
	radius = r
	while _touched < _by_far.size() and _far[_by_far[_touched]] >= r - EPS:
		var i := _by_far[_touched]
		_touched += 1
		var s := _s[i]
		if not is_instance_valid(s) or s.destroyed:
			continue
		if _twist and _cracked_ids.has(s.get_instance_id()):
			_band.append(i)  # cracked on the drag: the walk keeps it in the band, no second crack
			continue
		s.crack()
		if _twist:
			_cracked_ids[s.get_instance_id()] = true
		s.shake(2.5)
		cracked += 1
		_band.append(i)
		_spark_at(_ring_point(s.center(), r), 6)
	while _passed < _by_mid.size() and _mid[_by_mid[_passed]] >= r - EPS:
		var i := _by_mid[_passed]
		_passed += 1
		_fell(i)
	# The band keeps only what the ring is passing through: left behind, or fallen, it pins nobody.
	for k in range(_band.size() - 1, -1, -1):
		var i := _band[k]
		if _near[i] > r or not is_instance_valid(_s[i]) or _s[i].destroyed:
			_band.remove_at(k)
	if law == null or _band.is_empty():
		return
	_cut_pinned(r)


## Whoever the ring would push into a building it is passing through (the band) is cut down where he stands.
func _cut_pinned(r: float) -> void:
	var r2 := r * r
	for body: Variant in law.members:
		if not is_instance_valid(body) or not body.is_alive():
			continue
		var p := body as Person
		if p != null and (p.inside or p.chained):
			continue
		var d: Vector2 = body.ground_pos - _c
		var d2 := d.length_squared()
		if d2 <= r2:
			continue
		var out := sqrt(d2)
		if out - r > LawZone.CARRIED:
			continue  # carried off by something greater: the law lets him go
		if _pinned(_c + d / out * r):
			_doomed.append(body)
	for body: Variant in _doomed:
		_cut(body)
	_doomed.clear()


## Whether ground point `g` lies in a building the ring is passing through.
func _pinned(g: Vector2) -> bool:
	if _drag_on:
		for f in _dband:
			if f.has_point(g):
				return true
		return false
	for i in _band:
		if _rect[i].has_point(g):
			return true
	return false


## The point on the ring of `r` nearest `g`.
func _ring_point(g: Vector2, r: float) -> Vector2:
	var d := g - _c
	return _c + (d.normalized() if d.length_squared() > EPS else Vector2.RIGHT) * r


## Cut down by the bars, where he stands.
func _cut(body: Variant) -> void:
	var at_g: Vector2 = body.ground_pos
	var p := body as Person
	if p != null:
		if not ctx.field.kill(p, KIND, _ring_point(at_g, radius + 1.0)):
			return
	else:
		(body as Animal).die()
	cut += 1
	_spark_at(at_g, 10)
	if DominionParts.staged(self):
		DecreeParts.scatter(self, at_g, 6, 6.0)


## The ring passes building `i`'s middle: whoever shelters in it dies with it, and it falls.
func _fell(i: int) -> void:
	_fell_s(_s[i], _mid[i])


## The same for building `s`, whose middle lies `mid` from the ring's centre.
func _fell_s(s: Structure, mid: float) -> void:
	if not is_instance_valid(s) or s.destroyed:
		return
	if ctx.crowd != null and ctx.crowd.shelters != null:
		for p in ctx.crowd.shelters.throw_out_of(s, 0.0):
			if ctx.field.kill(p, KIND, s.center()):
				crushed += 1
	var from := _ring_point(s.center(), mid + 1.0)
	if s.damage_filter.is_valid():
		s.damage(99999.0, from, &"stone")  # the Citadel's own health decides
	else:
		s.destroy(from, &"stone")
	if s.destroyed:
		felled += 1
	_spark_at(_ring_point(s.center(), radius), 12)


## The cage shuts, END_R across the half: everyone still inside dies, whatever still stands there falls, and the law lifts.
func _shut() -> void:
	if law == null or shut:
		return
	# Everyone the bars still hold is inside the last ring they stood at; the law brings them in to END_R.
	var reach := maxf(radius, END_R) + EPS
	if _drag_on:
		_drag_frame(1.0, radius)  # the drag is done where it was going
	_close(END_R)
	_step_law(0.0)
	shut = true
	while _passed < _by_mid.size():
		_fell(_by_mid[_passed])
		_passed += 1
	for e in ctx.field.in_radius(_c, reach):
		if ctx.field.kill(e, KIND, _c):
			crushed += 1
	if ctx.crowd != null:
		for pack: Visitors in ctx.crowd.visitors:
			for a in pack.living():
				if a.ground_pos.distance_to(_c) <= reach:
					a.die()
					crushed += 1
	for body: Variant in law.members:
		if is_instance_valid(body) and body is Animal and body.is_alive() and body.ground_pos.distance_to(_c) <= reach:
			body.die()
			crushed += 1
	_lift()
	if _grind != null:
		ctx.fade_out(_grind, 0.3)
		_grind = null
	ctx.play(&"cg_shut", _c)
	if not DominionParts.staged(self):
		return
	_spark_at(_c, 24)
	ctx.flash.call(Color(1.0, 0.85, 0.5, 0.35), 0.25)
	ctx.impact.hitstop(0.05)
	ctx.shake.add_trauma(0.7)
	DecreeParts.scatter(self, _c, 18, 14.0)
	DecreeParts.wave(self, _c, 2.4, 0.5, 0.1)


func _lift() -> void:
	if law != null and law.alive():
		if ctx.crowd != null:
			ctx.crowd.remove_law(law)
		else:
			law.lift()


## Dragged Cage: whether the click can still drag the cage (the bars stand, it has not shut, and it has not been dragged yet).
func can_follow_up() -> bool:
	return _twist and not dragged and law != null and law.alive() and not shut and not finished


## Dragged Cage: the cage's centre moves up to DRAG_MAX toward `at_pos` over DRAG_TIME. False when it cannot be dragged, or the
## click lies on the centre.
func follow_up(at_pos: Vector2, _extra: Dictionary) -> bool:
	if not can_follow_up():
		return false
	var d := at_pos - _c
	var dist := d.length()
	if dist <= EPS:
		return false
	dragged = true
	_drag_on = true
	_drag_from = _c
	_drag_to = _c + d / dist * minf(DRAG_MAX, dist)
	_drag_t0 = t
	_drag_begin()
	return true


## Dragged Cage's preview: the ring as it stands now.
func follow_up_area() -> Dictionary:
	return {"shape": "circle", "r": radius}


## The buildings the drag can reach, and how each stands to the ring now.
func _drag_begin() -> void:
	_cracked_ids.clear()
	for k in _touched:
		var s := _s[_by_far[k]]
		if is_instance_valid(s):
			_cracked_ids[s.get_instance_id()] = true
	_ds.clear()
	_dr.clear()
	_dstate.clear()
	_dmid.clear()
	_dcrk.clear()
	var reach := radius + DRAG_MAX + EPS
	for s in ctx.env.structures():
		if not is_instance_valid(s) or s.destroyed or s.walkable:
			continue
		var f := s.footprint
		if _c.clamp(f.position, f.end).distance_to(_c) >= reach:
			continue
		_ds.append(s)
		_dr.append(f)
		_dstate.append(_state_of(f, _c, radius))
		_dmid.append(1 if f.get_center().distance_to(_c) < radius - EPS else 0)
		_dcrk.append(1 if _cracked_ids.has(s.get_instance_id()) else 0)
	_dband.clear()


## 0 when footprint `f` lies wholly inside the ring of `r` about `c`, 2 wholly outside it, 1 when the bars cross it.
static func _state_of(f: Rect2, c: Vector2, r: float) -> int:
	if c.clamp(f.position, f.end).distance_to(c) >= r:
		return 2
	var far := 0.0
	for corner in [f.position, Vector2(f.end.x, f.position.y), f.end, Vector2(f.position.x, f.end.y)]:
		far = maxf(far, (corner as Vector2).distance_to(c))
	return 1 if far >= r - EPS else 0


## One frame of the drag, `k` (0..1) of the way: the centre moves, those the law holds are carried with it, and the ring (of `r`) cracks
## and fells what it sweeps, then cuts down whoever it pins against a building it is passing through. At k = 1 the drag ends and the
## sorted walk of the closing is taken again for where the cage now stands.
func _drag_frame(k: float, r: float) -> void:
	var to := _drag_from.lerp(_drag_to, k)
	var move := to - _c
	_c = to
	law.a = _c
	law.b = _c
	radius = r
	if _cage != null and is_instance_valid(_cage):
		_cage.position = Iso.ground_to_screen(_c).round()
	if move.length_squared() > 0.0:
		for body: Variant in law.members:
			if not is_instance_valid(body) or not body.is_alive():
				continue
			var p := body as Person
			if p != null and (p.inside or p.chained):
				continue
			body.ground_pos += move
			if p == null:
				(body as Animal).sync_position()
	_dband.clear()
	for j in _ds.size():
		var s := _ds[j]
		if not is_instance_valid(s) or s.destroyed:
			continue
		var f := _dr[j]
		var st := _state_of(f, _c, r)
		if _dcrk[j] == 0 and (st == 1 or st != _dstate[j]):
			_dcrk[j] = 1
			_cracked_ids[s.get_instance_id()] = true
			s.crack()
			s.shake(2.5)
			cracked += 1
			_spark_at(_ring_point(s.center(), r), 6)
		_dstate[j] = st
		var mid := f.get_center().distance_to(_c)
		var inside_mid := 1 if mid < r - EPS else 0
		if inside_mid != _dmid[j]:
			_dmid[j] = inside_mid
			_fell_s(s, mid)
			if s.destroyed:
				continue
		if _dcrk[j] == 1 and _c.clamp(f.position, f.end).distance_to(_c) <= r:
			_dband.append(f)
	if not _dband.is_empty():
		# Carried into a building the bars are passing through: crushed against it.
		var r2 := r * r
		for body: Variant in law.members:
			if not is_instance_valid(body) or not body.is_alive():
				continue
			var p := body as Person
			if p != null and (p.inside or p.chained):
				continue
			if (body.ground_pos - _c).length_squared() <= r2 and _pinned(body.ground_pos):
				_doomed.append(body)
		for body: Variant in _doomed:
			_cut(body)
		_doomed.clear()
		_cut_pinned(r)
	if k >= 1.0:
		_drag_on = false
		_ds.clear()
		_dr.clear()
		_dband.clear()
		_resurvey(r)


## The closing's sorted walk, taken again for the cage's new place: every standing building the bars still reach, farthest first.
func _resurvey(r: float) -> void:
	_s.clear()
	_rect.clear()
	_far.clear()
	_mid.clear()
	_near.clear()
	_by_far.clear()
	_by_mid.clear()
	_band.clear()
	_touched = 0
	_passed = 0
	_survey(r)


## Cut short (an act of the night ends): the law is lifted, and nobody more dies of it.
func end_now() -> void:
	if not finished:
		shut = true
		_drag_on = false
		_lift()
		if _grind != null:
			ctx.fade_out(_grind, 0.3)
			_grind = null
	super()


func _exit_tree() -> void:
	if not shut and law != null:
		shut = true
		_drag_on = false
		if ctx.crowd == null or is_instance_valid(ctx.crowd):
			_lift()
	super()


## Sparks where the bars cut, at ground point `g` (look only).
func _spark_at(g: Vector2, count: int) -> void:
	if _cage != null and is_instance_valid(_cage):
		_cage.spark(Iso.ground_to_screen(g) - _cage.position, count)


## How high the bars stand (0..1): rising out of the ground, standing through the close, sinking once it has shut.
func standing() -> float:
	if t < T_LAND:
		var k := clampf(t / T_LAND, 0.0, 1.0)
		return 1.0 - (1.0 - k) * (1.0 - k)
	if t < T_LAND + lv_close_time:
		return 1.0
	return clampf(1.0 - (t - T_LAND - lv_close_time) / FADE, 0.0, 1.0)


## The cage, drawn in screen space round its middle (over the town, as every Decree mark is), thin so the town shows
## through: a ring of tall brass bars on the ring's ground circle, leaning in a little at the top like a bird cage's,
## each carved with gilt marks of law and joined by a brass rail at the top and an amber one on the ground; the far bars
## drawn first, dimmer. As the ring closes the bars are drawn sparser, so they never become a wall. They grind: each
## shivers in place, and sparks fly from their feet in turn, and wherever they crack a building or cut someone down.
## Everything is laid out once; each frame only moves and draws it.
class Cage extends Node2D:
	const BARS := 96
	## A bar's height and the share of its foot's offset its top keeps (the lean in), in screen pixels.
	const HIGH := 56.0
	const LEAN := 0.93
	## Bars are drawn no closer together than this on screen (every 2nd, 4th ... when the ring is small).
	const SPACING := 9.0
	const BRASS := Color("c8963c")
	const BRASS_DARK := Color("6e4a1c")
	const BRASS_LIGHT := Color("ffe39a")
	const WASH := Color(1.0, 0.72, 0.2, 0.05)
	## Sparks: how many at once at most, how long each lives, how hard it falls, how often the bars throw one off.
	const SPARKS := 96
	const SPARK_LIFE := 0.4
	const SPARK_G := 260.0
	const GRIND_EVERY := 0.09
	var fx: CageFx
	var _unit := PackedVector2Array()
	var _disc := PackedVector2Array()
	var _ground := PackedVector2Array()
	var _tops := PackedVector2Array()
	## Each bar's two carved marks, as shares of its height.
	var _marks := PackedFloat32Array()
	var _sp_pos := PackedVector2Array()
	var _sp_vel := PackedVector2Array()
	var _sp_age := PackedFloat32Array()
	var _sp_next := 0
	var _grind_in := 0.0
	var _grind_k := 0

	## The ground circle of `r`'s half width and half height on screen.
	static func half_axes(r: float) -> Vector2:
		return Vector2(r * 32.0 * sqrt(2.0), r * 16.0 * sqrt(2.0))

	func _ready() -> void:
		for i in BARS:
			var a := TAU * float(i) / float(BARS)
			_unit.append(Vector2(cos(a), sin(a)))
			_marks.append(0.25 + 0.3 * fposmod(float(i) * 0.618034, 1.0))
			_marks.append(0.62 + 0.25 * fposmod(float(i) * 0.381966 + 0.3, 1.0))
		for i in 48:
			_disc.append(Vector2.from_angle(TAU * float(i) / 48.0))
		_ground.resize(BARS + 1)
		_tops.resize(BARS + 1)
		_sp_pos.resize(SPARKS)
		_sp_vel.resize(SPARKS)
		_sp_age.resize(SPARKS)
		_sp_age.fill(SPARK_LIFE)

	## `count` sparks thrown from `at` (screen pixels from the middle), up and out, by order (no roll).
	func spark(at: Vector2, count: int) -> void:
		for k in count:
			var i := _sp_next
			_sp_next = (_sp_next + 1) % SPARKS
			var a := -PI * (0.1 + 0.8 * fposmod(float(k + _sp_next) * 0.618034, 1.0))
			var speed := 50.0 + 70.0 * fposmod(float(k) * 0.381966 + 0.2, 1.0)
			_sp_pos[i] = at
			_sp_vel[i] = Vector2(cos(a), sin(a)) * speed
			_sp_age[i] = 0.0

	func _process(delta: float) -> void:
		if fx.t > fx.duration:
			queue_free()
			return
		for i in SPARKS:
			if _sp_age[i] < SPARK_LIFE:
				_sp_age[i] += delta
				_sp_vel[i] += Vector2(0.0, SPARK_G * delta)
				_sp_pos[i] += _sp_vel[i] * delta
		# The grind: the bars' feet throw sparks in turn while they close.
		if fx.t >= T_LAND and not fx.shut:
			_grind_in -= delta
			if _grind_in <= 0.0:
				_grind_in = GRIND_EVERY
				_grind_k += 1
				var h := half_axes(fx.radius)
				spark(_unit[(_grind_k * 37) % BARS] * h, 2)
		queue_redraw()

	func _draw() -> void:
		var up := fx.standing()
		var h := half_axes(fx.radius)
		var now := fx.t
		if up > 0.0:
			# Every bar's foot and top, the rails closed round.
			var step := 1
			var round_px := TAU * sqrt((h.x * h.x + h.y * h.y) * 0.5)
			while step < 16 and round_px / float(BARS / step) < SPACING:
				step *= 2
			for i in BARS:
				var foot := _unit[i] * h
				# The grind: each bar shivers a pixel in place while the ring closes.
				if now >= T_LAND and not fx.shut:
					foot.x += 0.6 * sin(now * 37.0 + float(i) * 1.7)
				_ground[i] = foot
				_tops[i] = foot * LEAN + Vector2(0.0, -HIGH * up)
			_ground[BARS] = _ground[0]
			_tops[BARS] = _tops[0]
			# The ground inside: a faint amber wash; the ground rail, ink under amber.
			draw_set_transform(Vector2.ZERO, 0.0, h)
			draw_colored_polygon(_disc, Color(WASH, WASH.a * up))
			draw_set_transform(Vector2.ZERO)
			draw_polyline(_ground, Color(1.0, 0.72, 0.2, 0.22 * up), 10.0)
			draw_polyline(_ground, Color(DecreeParts.INK, 0.55 * up), 5.0)
			draw_polyline(_ground, Color(DecreeParts.AMBER_LIGHT, 0.85 * up), 2.0)
			# The far bars first (behind the middle), dimmer; then the near ones.
			for side in 2:
				for i in range(0, BARS, step):
					var far := _unit[i].y < 0.0
					if far != (side == 0):
						continue
					_draw_bar(i, 0.6 if far else 1.0, up)
			draw_polyline(_tops, Color(DecreeParts.INK, 0.5 * up), 4.0)
			draw_polyline(_tops, Color(BRASS, 0.95 * up), 2.0)
		# The sparks: short gilt streaks along their flight, fading to amber.
		for i in SPARKS:
			var age := _sp_age[i]
			if age >= SPARK_LIFE:
				continue
			var k := age / SPARK_LIFE
			var c := DecreeParts.GILT.lerp(DecreeParts.AMBER_DEEP, k)
			draw_line(_sp_pos[i], _sp_pos[i] - _sp_vel[i] * 0.035, Color(c, 1.0 - k), 2.0)

	## Bar `i`: a thin brass rod from its foot up to its top, lit down one side, two gilt marks of law carved on it.
	func _draw_bar(i: int, light: float, up: float) -> void:
		var foot := _ground[i]
		var top := _tops[i]
		var a := up * light
		draw_line(foot, top, Color(DecreeParts.INK, 0.55 * a), 4.0)
		draw_line(foot, top, Color(BRASS_DARK, a), 3.0)
		draw_line(foot + Vector2(-0.5, 0.0), top + Vector2(-0.5, 0.0), Color(BRASS, a), 2.0)
		draw_line(foot + Vector2(-1.0, 0.0), top + Vector2(-1.0, 0.0), Color(BRASS_LIGHT, 0.7 * a), 1.0)
		for m in 2:
			var at := foot.lerp(top, _marks[i * 2 + m]).round()
			draw_rect(Rect2(at + Vector2(-1.5, 0.0), Vector2(3.0, 1.0)), Color(DecreeParts.GILT, a))
		draw_rect(Rect2(top.round() + Vector2(-1.5, -1.5), Vector2(3.0, 3.0)), Color(BRASS_LIGHT, a))
