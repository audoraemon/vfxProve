class_name DreadOfTheDarkFx
extends FxTimeline
## Dread of the Dark (Veil, Tier 4; spec 5.7): T_FALL after the click, and for HOLD seconds, every piece of dark ground
## (Crowd.in_dark(): dusk, Unseen Hour's veil, a NIGHT mission, Evernight) within REACH of the click (6 in the light, 12 in the
## dark: VeilRules.SIZES) is dreaded (Crowd.dread()). Nobody outside steps into it (Person._step_blocked() reads the dread), so the
## dark works as a wall: who walks toward it waits at its edge until the dread ends. Everyone already standing in it freezes where he
## stands, silent: this effect lays Person.statuses[&"dread"] on him (Person.is_dreaded(): he cannot walk, flee, shout, ring, fight
## or seize, and he is no witness) and lifts it when the dread ends, when the dark under him fades, or when he is gone. Lit ground in
## reach is not dreaded. A shadow (Shadow Play) is not afraid of the dark: never frozen. Asleep beats frozen: a sleeper is not frozen
## (one who wakes inside while the dread lasts is); one frozen and then put to sleep sleeps, and wakes free if the dread has ended.
## With no dark ground in reach the cast is refused ("no_dark", refusal(); Rules.cast() spends no cooldown).
## Each person carries the instance ids of the casts holding him (meta OWNERS; no statics), so two Dreads never undo each other.
## Silent: no danger, no alarm, no fright, no voice. Drawn for the god only (the overhead layer): the dark ground inside the reach
## thickens, spreading from the click outwards as a visible front, and at its border rises a wall of shifting pillars of darkness with
## pale eyes in it (review round, ruling VRC2), standing for the whole dread and sinking when it lifts. Its dusk is laid at the
## click when the dread lifts (ruling VC1); a Dread cut short (end_now(), an act change, a freed node) lays none, and its wall
## drops at once with the shade.

## How long the dread holds, from the fall.
const HOLD := 25.0
## The dark gathers for this long after the click; then the dread falls.
const T_FALL := 0.8
## The thickened dark fades for this long after the dread lifts.
const T_FADE := 0.6
## The status this lays (Person.is_dreaded() reads the same key). Its value is not read; the key is the dread.
const KEY := &"dread"
## The person's meta that holds the casts keeping the dread on him: {instance id: true}.
const OWNERS := &"dread_owners"

## The cast's reach (light or dark size).
var reach := 6.0
## The instance ids of the people this cast holds now (they may be freed meanwhile).
var _ids: Array[int] = []
## The crowd's dread this cast laid (Crowd.dread()), 0 when none is on.
var _dread := 0
## Whether the dread has lifted (its dusk laid if it ran its course; none when cut short).
var _lifted := false
## The god's look: the thickened dark and the eyes at its edge.
var shade: DreadShade


## Why a Dread cast at `ground` must be refused: "no_dark" when no dark ground lies within its reach, else "" (Rules.cast() asks;
## a refused cast spends no cooldown). `dark` is the cast's own stamp: a cast made in the dark stands on dark ground already. With
## no crowd (the VFX Sandbox) nothing can be judged and the cast goes.
static func refusal(crowd: Crowd, ground: Vector2, dark: bool) -> String:
	if crowd == null or dark:
		return ""
	return "" if dark_in_reach(crowd, ground, VeilRules.size("dread", "REACH", false)) else "no_dark"


## Whether any dark ground (Crowd.in_dark()) lies within `reach` of `at`: the whole town is dark (a NIGHT mission, Evernight), `at`
## itself is, or a live dusk patch or Unseen Hour veil reaches into the circle.
static func dark_in_reach(crowd: Crowd, at: Vector2, reach: float) -> bool:
	if crowd == null:
		return false
	if crowd.night_mission or (crowd.dusk != null and crowd.dusk.everywhere) or crowd.in_dark(at):
		return true
	return (crowd.dusk != null and crowd.dusk.reaches(at, reach)) or crowd.veil_reaches(at, reach)


func _build() -> void:
	reach = VeilParts.size(self, "dread", "REACH")
	if ctx != null:
		ctx.play(&"v_dread", origin)
	if ctx == null or ctx.crowd == null:
		duration = 1.0  # the VFX Sandbox: nothing to dread, no dusk to lay
		_lifted = true
		return
	duration = T_FALL + HOLD + T_FADE
	busy = T_FALL
	at(T_FALL, _fall)
	at(T_FALL + HOLD, _lift)
	var parent: Node2D = ctx.overhead if ctx.overhead != null else ctx.world
	if parent != null:
		shade = DreadShade.new()
		shade.fx_id = get_instance_id()
		shade.center = origin
		shade.reach = reach
		track(shade, parent)
		shade.refresh(ctx.crowd)


func _fall() -> void:
	if not _live_crowd():
		return
	_dread = ctx.crowd.dread(origin, reach, HOLD)
	_hold_all()
	if shade != null and is_instance_valid(shade):
		shade.refresh(ctx.crowd)


func _lift() -> void:
	if _lifted:
		return
	_lifted = true
	_release()
	VeilParts.land(self, origin)


func _fx_process(delta: float) -> void:
	if _dread != 0:
		_hold_all()
	if shade != null and is_instance_valid(shade):
		shade.strength = _strength()
		shade.lifted = _lifted
		shade.held = _ids
		shade.tick(ctx.crowd if _dread != 0 and _live_crowd() else null, delta)


## The look's strength: gathers over T_FALL, full while the dread holds, fades over T_FADE.
func _strength() -> float:
	if not _lifted:
		return clampf(t / T_FALL, 0.0, 1.0)
	return clampf(1.0 - (t - T_FALL - HOLD) / T_FADE, 0.0, 1.0) if t >= T_FALL + HOLD else 0.0


func _live_crowd() -> bool:
	return ctx != null and ctx.crowd != null and is_instance_valid(ctx.crowd)


## Who stands frozen now: the living out of doors within reach on dark ground, not a shadow, and not asleep unless this cast already
## held him (asleep beats frozen; a sleeper is not frozen until he wakes). Whoever no longer qualifies is let go.
func _hold_all() -> void:
	var now := {}
	if ctx.field != null and _live_crowd():
		for e in ctx.field.in_radius(origin, reach):
			var p := e as Person
			if p == null or not p.is_alive() or p.inside or p.is_shadow():
				continue
			var id := p.get_instance_id()
			if p.is_asleep() and not _ids.has(id):
				continue
			if not ctx.crowd.in_dark(p.ground_pos):
				continue
			now[id] = true
			if not _ids.has(id):
				_hold(p)
				_ids.append(id)
	var i := _ids.size() - 1
	while i >= 0:
		if not now.has(_ids[i]):
			_let_go(_person(_ids[i]))
			_ids.remove_at(i)
		i -= 1


func _hold(p: Person) -> void:
	var owners: Dictionary = p.get_meta(OWNERS, {})
	owners[get_instance_id()] = true
	p.set_meta(OWNERS, owners)
	p.statuses[KEY] = maxf(float(p.statuses.get(KEY, 0.0)), maxf(T_FALL + HOLD - t, 0.0))


## Takes this cast off `p`; the dread leaves him only when no other cast holds him.
func _let_go(p: Person) -> void:
	if p == null or not p.has_meta(OWNERS):
		return
	var owners: Dictionary = p.get_meta(OWNERS, {})
	owners.erase(get_instance_id())
	if owners.is_empty():
		p.statuses.erase(KEY)
		p.remove_meta(OWNERS)
	else:
		p.set_meta(OWNERS, owners)


## The person with this instance id, or null if freed.
static func _person(id: int) -> Person:
	return instance_from_id(id) as Person


## Everyone this cast holds is let go and its dread ends. Safe to call twice, and with people or the crowd freed meanwhile.
func _release() -> void:
	for id in _ids:
		_let_go(_person(id))
	_ids.clear()
	if _dread != 0 and _live_crowd():
		ctx.crowd.end_dread(_dread)
	_dread = 0


## Ended before the dread lifts (end_now(), an act change): everyone goes free and no dusk is laid -- a patch laid in teardown would
## put out a running Evernight's torches and take their huddles at the act change (final review, Important 3; VC1 as amended). One
## that ran its course has lifted already and laid its dusk then.
func _finish() -> void:
	if not _lifted:
		_lifted = true
		_release()
	super()


func _exit_tree() -> void:
	_release()
	super()


## Freed without finishing (an effect layer torn down outside the tree): the dread still ends and everyone goes free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release()


## The god's look of a Dread (screen space, the overhead layer): the dark ground inside the reach thickens, in rows of ground cells,
## spreading from the click as a front over SPREAD; behind the front, at the border of the dreaded ground (its edge cells: where the
## dark ends, or the reach), a wall of tall shifting pillars of darkness rises, the far ones tall and the near ones low so the frozen
## inside stay in sight, with pale eyes blinking slowly in it; under each frozen person a hard dark mark, standing rigid. It sinks as
## the dread lifts. Drawn only (no simulation state, no rolls). It re-reads the dark every REFRESH seconds while the dread holds.
class DreadShade extends Node2D:
	## Ground size of one cell of the thickened dark.
	const CELL := 0.5
	const REFRESH := 0.5
	## At most this many pairs of eyes along the edge.
	const EYES := 12
	## The dark's front crosses the dreaded ground in this long from the click; a pillar rises over RISE once the front reaches it.
	const SPREAD := 1.2
	const RISE := 0.45
	## The pillars: at most this many round the border; a far one's height and a near one's share of it (screen pixels).
	const PILLARS := 72
	const HIGH := 58.0
	const NEAR := 0.28
	const THICK := 0.42
	## A tongue's rungs, and its triangle strip's indices (two per rung).
	const TONGUE_STEPS := 6
	const FOOT := 6.0
	var _tongue_idx := PackedInt32Array()

	var fx_id := 0
	var center := Vector2.ZERO
	var reach := 6.0
	## 0..1, set by the cast each frame.
	var strength := 0.0
	## The instance ids the cast holds (its own list, read only).
	var held: Array[int] = []
	## Runs of dark cells, each [ground start, ground end] along a row (x), one row per CELL of y.
	var runs: Array = []
	## The ground points where eyes open.
	var eyes: PackedVector2Array = PackedVector2Array()
	## Whether the dread has lifted (set by the cast): the look sinks with `strength` then; before, it spreads at full strength.
	var lifted := false
	## The wall's pillars: their feet (ground), widths (screen pixels), height shares (far 1 .. near NEAR) and phases; and the order
	## to draw them in, far first.
	var pillars: PackedVector2Array = PackedVector2Array()
	var _p_wide := PackedFloat32Array()
	var _p_high := PackedFloat32Array()
	var _p_phase := PackedFloat32Array()
	var _p_order := PackedInt32Array()
	## The front's nearest and farthest dark ground from the click.
	var _d_min := 0.0
	var _d_max := 0.0
	var _clock := 0.0
	var _since := 0.0

	## One frame of the cast: the eyes' clock, and the dark re-read every REFRESH while `crowd` is given (the dread holds).
	func tick(crowd: Crowd, delta: float) -> void:
		_clock += delta
		_since += delta
		if crowd != null and _since >= REFRESH:
			refresh(crowd)
		queue_redraw()

	## Its cast freed without finishing (outside the tree): it goes too.
	func _process(_delta: float) -> void:
		if instance_from_id(fx_id) == null:
			queue_free()

	## Re-reads which cells inside the reach are dark, joins them into runs, and picks the edge cells where the eyes open.
	func refresh(crowd: Crowd) -> void:
		_since = 0.0
		runs.clear()
		var edge: Array[Vector2] = []
		var n := int(ceil(reach / CELL))
		var dark := {}
		for j in range(-n, n + 1):
			for i in range(-n, n + 1):
				var g := center + Vector2((float(i) + 0.5) * CELL, (float(j) + 0.5) * CELL)
				if g.distance_to(center) <= reach and crowd.in_dark(g):
					dark[Vector2i(i, j)] = true
		for j in range(-n, n + 1):
			var start := -1000
			for i in range(-n, n + 2):
				var on := dark.has(Vector2i(i, j))
				if on and start == -1000:
					start = i
				elif not on and start != -1000:
					runs.append([center + Vector2(float(start) * CELL, float(j) * CELL), center + Vector2(float(i) * CELL, float(j) * CELL)])
					start = -1000
				if on and not (dark.has(Vector2i(i + 1, j)) and dark.has(Vector2i(i - 1, j)) and dark.has(Vector2i(i, j + 1))
						and dark.has(Vector2i(i, j - 1))):
					edge.append(center + Vector2((float(i) + 0.5) * CELL, (float(j) + 0.5) * CELL))
		# Evenly spaced around the click (by angle, then by distance: no luck).
		edge.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			var aa := (a - center).angle()
			var ab := (b - center).angle()
			return aa < ab if aa != ab else a.distance_squared_to(center) < b.distance_squared_to(center))
		eyes = PackedVector2Array()
		if not edge.is_empty():
			var count := mini(EYES, edge.size())
			for k in count:
				eyes.append(edge[int(float(k) * float(edge.size()) / float(count))])
		_lay_wall(dark, edge)
		queue_redraw()

	## The front's span and the wall's pillars, from the dark cells and their edge (sorted round the click).
	func _lay_wall(dark: Dictionary, edge: Array[Vector2]) -> void:
		pillars = PackedVector2Array()
		_p_wide = PackedFloat32Array()
		_p_high = PackedFloat32Array()
		_p_phase = PackedFloat32Array()
		_p_order = PackedInt32Array()
		if dark.is_empty():
			return
		_d_min = INF
		_d_max = 0.0
		var top := INF
		var bottom := -INF
		for c: Vector2i in dark:
			var g := center + Vector2((float(c.x) + 0.5) * CELL, (float(c.y) + 0.5) * CELL)
			var d := g.distance_to(center)
			_d_min = minf(_d_min, d)
			_d_max = maxf(_d_max, d)
			var y := Iso.ground_to_screen(g).y
			top = minf(top, y)
			bottom = maxf(bottom, y)
		if edge.is_empty():
			return
		# Evenly spaced round the border; wide enough to stand shoulder to shoulder (an edge cell is about 18 px of border).
		var count := mini(PILLARS, edge.size())
		var wide := clampf(18.0 * float(edge.size()) / float(count) * 1.15, 14.0, 34.0)
		var mid := (top + bottom) * 0.5
		var half := maxf((bottom - top) * 0.5, 8.0)
		var order: Array[int] = []
		for k in count:
			var g := edge[int(float(k) * float(edge.size()) / float(count))]
			pillars.append(g)
			_p_wide.append(wide)
			# Far (high on screen) stands tall; near (low on screen) stays low, so the frozen inside are never hidden.
			var v := (Iso.ground_to_screen(g).y - mid) / half
			_p_high.append(lerpf(1.0, NEAR, smoothstep(-0.35, 0.45, v)))
			# Its phase from where it stands (no roll; the same spot keeps its beat across refreshes).
			_p_phase.append(fposmod(g.x * 1.618034 + g.y * 2.414214, TAU))
			order.append(k)
		order.sort_custom(func(a: int, b: int) -> bool: return pillars[a].x + pillars[a].y < pillars[b].x + pillars[b].y)
		for k in order:
			_p_order.append(k)

	## How far from the click the dark's front has come.
	func front() -> float:
		return _d_min + (_d_max - _d_min + CELL * 2.0) * clampf(_clock / SPREAD, 0.0, 1.0)

	## 0..1: how far the pillar at `g` has risen (once the front has passed it), times how much of the look shows.
	func _risen(g: Vector2, k: float) -> float:
		var span := maxf(_d_max - _d_min + CELL * 2.0, 0.01)
		var at := SPREAD * (g.distance_to(center) - _d_min) / span
		return smoothstep(0.0, 1.0, (_clock - at) / RISE) * k

	func _ready() -> void:
		for n in TONGUE_STEPS + 1:
			var b := n * 2
			_tongue_idx.append_array([b, b + 1, b + 3, b, b + 3, b + 2])

	func _draw() -> void:
		# Spreading and holding at full strength; sinking with it once the dread has lifted.
		var k := strength if lifted else 1.0
		if k <= 0.0:
			return
		_draw_ground(k)
		# The frozen stand rigid: a hard dark mark under each.
		for id in held:
			var p := instance_from_id(id) as Person
			if p == null or not p.is_alive() or p.inside:
				continue
			var f := Iso.ground_to_screen(p.ground_pos)
			draw_rect(Rect2(f + Vector2(-4, -1), Vector2(8, 2)), Color(VeilParts.BLACK, 0.7 * k))
			draw_rect(Rect2(f + Vector2(-3, -2), Vector2(6, 1)), Color(VeilParts.VEIL, 0.35 * k))
		# The wall, far pillars first.
		for i in _p_order:
			_draw_pillar(i, k)
		# Pale eyes in the wall, each pair blinking on its own slow beat, at the height of the wall where they open.
		for e in eyes.size():
			var ph := fposmod(_clock * 0.35 + float(e) * 0.37, 1.0)
			var up := _risen(eyes[e], k)
			if ph < 0.08 or up <= 0.2:
				continue
			var s := (Iso.ground_to_screen(eyes[e]) + Vector2(0.0, -_eye_height(eyes[e]) * up)).round()
			var c := Color(VeilParts.SILVER, 0.9 * up)
			draw_rect(Rect2(s + Vector2(-4, -1), Vector2(8, 3)), Color(VeilParts.VEIL, 0.18 * up))
			draw_rect(Rect2(s + Vector2(-3, 0), Vector2(2, 1)), c)
			draw_rect(Rect2(s + Vector2(1, 0), Vector2(2, 1)), c)

	## The thickened dark: each run cut to the front's circle; a band of deeper dusk rides the front while it spreads.
	func _draw_ground(k: float) -> void:
		var f := front()
		var band := CELL * 2.0
		var spreading := f < _d_max + band
		var thick := Color(VeilParts.BLACK, THICK * k)
		var rim := Color(VeilParts.DUSK, 0.55 * k)
		for r: Array in runs:
			var a: Vector2 = r[0]
			var b: Vector2 = r[1]
			var dy := a.y + CELL * 0.5 - center.y
			if absf(dy) >= f:
				continue
			var w := sqrt(f * f - dy * dy)
			var x0 := maxf(a.x, center.x - w)
			var x1 := minf(b.x, center.x + w)
			if x0 >= x1:
				continue
			_strip(x0, x1, a.y, thick)
			if not spreading:
				continue
			# The front: the outer `band` of the circle, on both sides of the row.
			var fi := f - band
			var wi := sqrt(maxf(fi * fi - dy * dy, 0.0)) if absf(dy) < fi else 0.0
			if wi <= 0.0:
				_strip(x0, x1, a.y, rim)
			else:
				if x0 < center.x - wi:
					_strip(x0, minf(x1, center.x - wi), a.y, rim)
				if x1 > center.x + wi:
					_strip(maxf(x0, center.x + wi), x1, a.y, rim)

	func _strip(x0: float, x1: float, y: float, c: Color) -> void:
		draw_primitive(PackedVector2Array([Iso.ground_to_screen(Vector2(x0, y)), Iso.ground_to_screen(Vector2(x1, y)),
			Iso.ground_to_screen(Vector2(x1, y + CELL)), Iso.ground_to_screen(Vector2(x0, y + CELL))]), PackedColorArray([c]), PackedVector2Array())

	## How high on its pillar an eye at `g` opens: half the wall's height there.
	func _eye_height(g: Vector2) -> float:
		var best := 0
		var near := INF
		for i in pillars.size():
			var d := pillars[i].distance_squared_to(g)
			if d < near:
				near = d
				best = i
		return HIGH * (_p_high[best] if not _p_high.is_empty() else 1.0) * 0.55

	## One pillar of darkness: three tongues of dark rising from one foot, each swaying and breathing on its own beat, dense at the
	## ground and thinning to nothing at its point (vertex colours), in a dusk haze; a pale rim on the tallest; wisps leaving the top.
	func _draw_pillar(i: int, k: float) -> void:
		var up := _risen(pillars[i], k)
		if up <= 0.0:
			return
		var ph := _p_phase[i]
		var foot := Iso.ground_to_screen(pillars[i])
		var tall := HIGH * _p_high[i] * up
		var w := _p_wide[i] * (0.7 + 0.3 * up)
		var a := 0.62 if _p_high[i] < 0.6 else 0.85
		# The haze: one wide soft violet tongue behind the three, so the wall reads on night ground too.
		_tongue(foot, w * 1.5, tall * 1.05, ph + 1.3, Color(VeilParts.DUSK.lerp(VeilParts.VEIL, 0.35), 0.34 * a * up), false)
		for s in 3:
			var sp := ph + float(s) * 2.1
			var hi := tall * (0.62 + 0.38 * (0.5 + 0.5 * sin(_clock * (0.9 + 0.3 * float(s)) + sp)))
			if s == 1:
				hi = tall * (0.9 + 0.1 * sin(_clock * 1.3 + ph))
			_tongue(foot + Vector2((float(s) - 1.0) * w * 0.28, 0.0), w * (0.62 if s == 1 else 0.5), hi, sp, Color(VeilParts.BLACK, a * up),
				s == 1)
		# Wisps leaving the top, each on its own slow loop.
		var tip := foot + Vector2(3.0 * sin(_clock * 2.2 + ph + 2.7), -tall)
		for m in 2:
			var c := fposmod(_clock * 0.5 + ph * 0.3 + float(m) * 0.5, 1.0)
			var wp := tip + Vector2(2.5 * sin(_clock * 1.7 + ph + float(m) * 2.0), -c * 16.0)
			draw_rect(Rect2(wp - Vector2(1.5, 1.5), Vector2(3, 3)), Color(VeilParts.BLACK, (1.0 - c) * 0.5 * a * up))

	## One tongue: `wide` at its foot, `high` tall, tapering to a swaying point, `col` at the ground fading out toward the point; with
	## `rim`, a pale line up its left side. A strip of triangles (no triangulation: a tongue just rising is all but flat).
	func _tongue(foot: Vector2, wide: float, high: float, ph: float, col: Color, rim: bool) -> void:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var left := PackedVector2Array()
		# A soft foot: a rung a little below the ground line with nothing in it, so the tongue fades into the ground, not cut off.
		var foot_w := wide * 0.55
		pts.append(foot + Vector2(-foot_w, FOOT))
		pts.append(foot + Vector2(foot_w, FOOT))
		cols.append(Color(col, 0.0))
		cols.append(Color(col, 0.0))
		for n in TONGUE_STEPS + 1:
			var q := float(n) / float(TONGUE_STEPS)
			var sway := 4.0 * sin(_clock * 2.0 + ph + q * 2.7) * q * q
			var hw := wide * 0.5 * (1.0 - pow(q, 1.2)) * (1.0 + 0.1 * sin(_clock * 3.7 + ph + q * 5.0))
			var c := Color(col, col.a * (1.0 - 0.85 * q * q))
			var l := foot + Vector2(-hw + sway, -high * q)
			pts.append(l)
			pts.append(foot + Vector2(hw + sway, -high * q))
			cols.append(c)
			cols.append(c)
			left.append(l)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _tongue_idx, pts, cols)
		if rim:
			draw_polyline(left, Color(VeilParts.VEIL, col.a * 0.22), 1.0)
