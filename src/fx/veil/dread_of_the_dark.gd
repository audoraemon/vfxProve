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
## This cast's hold, at its level (HOLD at level 1).
var lv_hold := HOLD
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
static func refusal(crowd: Crowd, ground: Vector2, dark: bool, level := 1) -> String:
	if crowd == null or dark:
		return ""
	return "" if dark_in_reach(crowd, ground, VeilRules.size("dread", "REACH", false, level)) else "no_dark"


## Whether any dark ground (Crowd.in_dark()) lies within `reach` of `at`: the whole town is dark (a NIGHT mission, Evernight), `at`
## itself is, or a live dusk patch or Unseen Hour veil reaches into the circle.
static func dark_in_reach(crowd: Crowd, at: Vector2, reach: float) -> bool:
	if crowd == null:
		return false
	if crowd.night_mission or (crowd.dusk != null and crowd.dusk.everywhere) or crowd.in_dark(at):
		return true
	return (crowd.dusk != null and crowd.dusk.reaches(at, reach)) or crowd.veil_reaches(at, reach)


func _build() -> void:
	lv_hold = PowerBook.stat(extra, "dread", "HOLD", HOLD)
	reach = VeilParts.size(self, "dread", "REACH")
	if ctx != null:
		ctx.play(&"v_dread", origin)
	if ctx == null or ctx.crowd == null:
		duration = 1.0  # the VFX Sandbox: nothing to dread, no dusk to lay
		_lifted = true
		return
	duration = T_FALL + lv_hold + T_FADE
	busy = T_FALL
	at(T_FALL, _fall)
	at(T_FALL + lv_hold, _lift)
	var parent: Node2D = ctx.overhead if ctx.overhead != null else ctx.world
	if parent != null:
		shade = DreadShade.new()
		shade.fx_id = get_instance_id()
		shade.center = origin
		shade.reach = reach
		track(shade, parent)
		# The far half of the wall stands on overhead_back (as the Cage and Fence do); in a bare context it all stays on the shade.
		if parent == ctx.overhead and ctx.overhead_back != null:
			var back := WallBack.new()
			back.shade = shade
			# Absolute 4 (VRF1): over the world, under the aim (Targeting, 5) and under the near half on the overhead layer (10).
			back.z_as_relative = false
			back.z_index = 4
			shade.back = track(back, ctx.overhead_back) as Node2D
		shade.refresh(ctx.crowd)


func _fall() -> void:
	if not _live_crowd():
		return
	_dread = ctx.crowd.dread(origin, reach, lv_hold)
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
	return clampf(1.0 - (t - T_FALL - lv_hold) / T_FADE, 0.0, 1.0) if t >= T_FALL + lv_hold else 0.0


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
	p.statuses[KEY] = maxf(float(p.statuses.get(KEY, 0.0)), maxf(T_FALL + lv_hold - t, 0.0))


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
	## A tongue's rungs (the shader's unit strip has these plus the soft foot below the ground line).
	const TONGUE_STEPS := 6
	const FOOT := 6.0
	## The wall's shader and its unit tongue (VRG1): each half of the wall is one MultiMesh of tongues, laid out on each read of the dark
	## or change of the held, and moved by the shader from the shade's clock. Made once.
	const WALL_SHADER := preload("res://shaders/dread_wall.gdshader")
	static var _tongue_mesh: ArrayMesh
	## 1 when the game runs headless (nothing is drawn), 0 when not, -1 not asked yet.
	static var _headless := -1
	## A held person's screen rect round his feet (half width, height), which no pillar taller than NEAR may cover.
	const PERSON := Vector2(7.0, 30.0)
	## The node on overhead_back that draws the wall's far half (null in a bare context: the shade draws it all).
	var back: Node2D
	## The near half's (or the whole wall's, with no back node) MultiMesh, and the node over it that draws its eyes and wisps and the
	## frozen's marks; the wall's shader material, shared by both halves. Made in the tree only, never headless.
	var _near_mm: MultiMeshInstance2D
	var _near_top: WallTop
	var _mat: ShaderMaterial
	## What the dark rows were last drawn with (the front and the strength): they are redrawn only when one moves.
	var _rows_key := Vector2(-1.0, -1.0)

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
	## Far (back half, high on screen) or near; each pillar's height share after the held are kept clear (`_recut()`), and whether it
	## was thinned for one; each eye's height and half.
	var _p_far: Array[bool] = []
	var _p_cap := PackedFloat32Array()
	var _p_thin: Array[bool] = []
	var _eye_h := PackedFloat32Array()
	var _eye_far: Array[bool] = []
	var _held_key := 0
	var _held_n := -1
	## The dark cells of the last read (Vector2i -> true), for the front's line; a signature of its runs, and the eyes laid for it.
	var _dark := {}
	var _dark_sig := 0
	var _eyes_kept := PackedVector2Array()
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
		elif held.size() != _held_n or hash(held) != _held_key:
			_recut()
		if not is_inside_tree() or headless():
			return
		var k := _shown()
		if _mat != null:
			_mat.set_shader_parameter(&"clock", _clock)
			_mat.set_shader_parameter(&"shown", k)
		var key := Vector2(minf(front(), _d_max + CELL * 2.0), k)
		if key != _rows_key:
			_rows_key = key
			queue_redraw()
		if _near_top != null:
			_near_top.queue_redraw()
		if is_instance_valid(back):
			back.queue_redraw()

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
		# A NIGHT mission or Evernight: in_dark() is true everywhere (VRG1: the same cells, without 2,300 calls).
		var everywhere := crowd.night_mission or (crowd.dusk != null and crowd.dusk.everywhere)
		for j in range(-n, n + 1):
			for i in range(-n, n + 1):
				var g := center + Vector2((float(i) + 0.5) * CELL, (float(j) + 0.5) * CELL)
				if g.distance_to(center) <= reach and (everywhere or crowd.in_dark(g)):
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
		# The same dark ground as last time (the usual case: a dread over a lasting dark): the wall, the eyes and the cut stand as
		# they are.
		var sig := hash(runs)
		if sig == _dark_sig and not pillars.is_empty():
			eyes = _eyes_kept
			if held.size() != _held_n or hash(held) != _held_key:
				_recut()
			return
		_dark_sig = sig
		_eyes_kept = eyes
		_dark = dark
		_lay_wall(dark, edge)
		_recut()
		_rows_key = Vector2(-1.0, -1.0)
		queue_redraw()

	## The front's span and the wall's pillars, from the dark cells and their edge (sorted round the click).
	func _lay_wall(dark: Dictionary, edge: Array[Vector2]) -> void:
		pillars = PackedVector2Array()
		_p_wide = PackedFloat32Array()
		_p_high = PackedFloat32Array()
		_p_phase = PackedFloat32Array()
		_p_order = PackedInt32Array()
		_p_far.clear()
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
			# The far half (high on screen) stands tall, tallest at the back; the near half stays low, so the frozen inside are never
			# hidden by it.
			var v := (Iso.ground_to_screen(g).y - mid) / half
			_p_far.append(v < 0.0)
			_p_high.append(lerpf(1.0, 0.55, smoothstep(-1.0, 0.0, v)) if v < 0.0 else NEAR)
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

	static func headless() -> bool:
		if _headless < 0:
			_headless = 1 if DisplayServer.get_name() == "headless" else 0
		return _headless == 1

	## The unit tongue: TONGUE_STEPS + 1 rungs and the soft foot, two vertices each (UV.x -1 / 1, UV.y the rung's share, -1 the foot),
	## as a strip of triangles. The shader places every vertex.
	static func tongue_mesh() -> ArrayMesh:
		if _tongue_mesh != null:
			return _tongue_mesh
		var verts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var idx := PackedInt32Array()
		for n in TONGUE_STEPS + 2:
			var q := -1.0 if n == 0 else float(n - 1) / float(TONGUE_STEPS)
			verts.append_array([Vector2(-1.0, -q), Vector2(1.0, -q)])
			uvs.append_array([Vector2(-1.0, q), Vector2(1.0, q)])
		for n in TONGUE_STEPS + 1:
			var b := n * 2
			idx.append_array([b, b + 1, b + 3, b, b + 3, b + 2])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = idx
		_tongue_mesh = ArrayMesh.new()
		_tongue_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		# The shader moves every vertex far from its rest place: never cull it by the rest shape.
		_tongue_mesh.custom_aabb = AABB(Vector3(-4096.0, -4096.0, -1.0), Vector3(8192.0, 8192.0, 2.0))
		return _tongue_mesh

	## A MultiMeshInstance2D for one half of the wall, with the shared material.
	func _wall_node() -> MultiMeshInstance2D:
		if _mat == null:
			_mat = ShaderMaterial.new()
			_mat.shader = WALL_SHADER
			_mat.set_shader_parameter(&"rim_color", VeilParts.VEIL)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = tongue_mesh()
		var node := MultiMeshInstance2D.new()
		node.multimesh = mm
		node.material = _mat
		return node

	func _ready() -> void:
		if headless():
			return
		_near_mm = _wall_node()
		add_child(_near_mm)
		_near_top = WallTop.new()
		_near_top.shade = self
		add_child(_near_top)
		_rebuild_wall()

	## Lays the wall's tongues into its MultiMeshes (far pillars first, each pillar's haze then its three tongues): which half, where,
	## how tall (after the cut), how wide, when it rises, its phases and colours. The shader does the rest every frame.
	func _rebuild_wall() -> void:
		if _near_mm == null:
			return
		var split := is_instance_valid(back) and back is WallBack and (back as WallBack).mm != null
		var near_buf := PackedFloat32Array()
		var far_buf := PackedFloat32Array()
		var span := maxf(_d_max - _d_min + CELL * 2.0, 0.01)
		var haze := VeilParts.DUSK.lerp(VeilParts.VEIL, 0.35)
		for i in _p_order:
			var far := _p_far[i]
			var a := 0.85 if far else 0.62
			if i < _p_thin.size() and _p_thin[i]:
				a *= 0.45
			var foot := Iso.ground_to_screen(pillars[i])
			var at := SPREAD * (pillars[i].distance_to(center) - _d_min) / span
			var tall := HIGH * share(i)
			var ph := _p_phase[i]
			var buf := far_buf if split and far else near_buf
			_instance(buf, foot, Color(haze, 0.34 * a), ph + 1.3, at, tall, _p_wide[i], 0)
			for t in 3:
				_instance(buf, foot, Color(VeilParts.BLACK, a), ph + float(t) * 2.1, at, tall, _p_wide[i], t + 1)
		_fill(_near_mm.multimesh, near_buf)
		if split:
			_fill((back as WallBack).mm.multimesh, far_buf)

	## One tongue's 16 floats: a 2D transform (the pillar's foot), its colour, its custom data (phase, rise time, height, width + kind).
	static func _instance(buf: PackedFloat32Array, foot: Vector2, c: Color, ph: float, at: float, tall: float, wide: float,
			kind: int) -> void:
		buf.append_array([1.0, 0.0, 0.0, foot.x, 0.0, 1.0, 0.0, foot.y, c.r, c.g, c.b, c.a, ph, at, tall, wide + 1000.0 * float(kind)])

	static func _fill(mm: MultiMesh, buf: PackedFloat32Array) -> void:
		mm.instance_count = buf.size() / 16
		if mm.instance_count > 0:
			mm.buffer = buf

	## Keeps the held clear of the wall: a pillar whose shape could cover a held person's rect is cut to the NEAR share and thinned.
	## Then each eye takes its nearest pillar's height and half. Run on every read of the dark and whenever the held change.
	func _recut() -> void:
		_held_key = hash(held)
		_p_cap = _p_high.duplicate()
		_p_thin.clear()
		_p_thin.resize(pillars.size())
		_p_thin.fill(false)
		var rects: Array[Rect2] = []
		for id in held:
			var p := instance_from_id(id) as Person
			if p != null and p.is_alive() and not p.inside:
				rects.append(person_rect(p.ground_pos))
		for i in pillars.size():
			for r in rects:
				if r.intersects(pillar_rect(i, _p_high[i])):
					_p_cap[i] = minf(_p_cap[i], NEAR)
					_p_thin[i] = true
					break
		_eye_h = PackedFloat32Array()
		_eye_far.clear()
		for g in eyes:
			var best := -1
			var near := INF
			for i in pillars.size():
				var d := pillars[i].distance_squared_to(g)
				if d < near:
					near = d
					best = i
			_eye_h.append(HIGH * (_p_cap[best] if best >= 0 else 1.0) * 0.55)
			_eye_far.append(_p_far[best] if best >= 0 else false)
		_held_n = held.size()
		_rebuild_wall()

	## A held person's screen rect, standing at ground `g`.
	static func person_rect(g: Vector2) -> Rect2:
		var f := Iso.ground_to_screen(g)
		return Rect2(f.x - PERSON.x, f.y - PERSON.y, PERSON.x * 2.0, PERSON.y + 2.0)

	## The most pillar `i` can cover at height share `sh`: its haze's width with sway, from its soft foot to its wisps.
	func pillar_rect(i: int, sh: float) -> Rect2:
		var foot := Iso.ground_to_screen(pillars[i])
		var half := _p_wide[i] * 0.75 + 4.0
		var top := HIGH * sh * 1.05 + 16.0
		return Rect2(foot.x - half, foot.y - top, half * 2.0, top + FOOT)

	## Pillar `i`'s height share now (after the held are kept clear).
	func share(i: int) -> float:
		return _p_cap[i] if i < _p_cap.size() else _p_high[i]

	func _draw() -> void:
		var k := _shown()
		if k <= 0.0:
			return
		# The dark rows here; over them (children, in order) the near half of the wall (all of it with no back node), then its eyes and
		# wisps and the frozen's marks (WallTop).
		_draw_ground(k)

	## The frozen stand rigid: a hard dark mark under each (drawn over the near wall).
	func draw_marks(on: CanvasItem, k: float) -> void:
		for id in held:
			var p := instance_from_id(id) as Person
			if p == null or not p.is_alive() or p.inside:
				continue
			var f := Iso.ground_to_screen(p.ground_pos)
			on.draw_rect(Rect2(f + Vector2(-4, -1), Vector2(8, 2)), Color(VeilParts.BLACK, 0.7 * k))
			on.draw_rect(Rect2(f + Vector2(-3, -2), Vector2(6, 1)), Color(VeilParts.VEIL, 0.35 * k))

	## Spreading and holding at full strength; sinking with it once the dread has lifted.
	func _shown() -> float:
		return strength if lifted else 1.0

	## Over one half of the wall (`which` 0 the far half, 1 the near half, 2 both): the wisps leaving its pillars' tops, then its eyes,
	## each pair blinking on its own slow beat at half the wall's height there. The pillars themselves are the MultiMeshes'.
	func draw_wall(on: CanvasItem, which: int, k: float) -> void:
		var span := maxf(_d_max - _d_min + CELL * 2.0, 0.01)
		for i in _p_order:
			if not (which == 2 or _p_far[i] == (which == 0)):
				continue
			var up := smoothstep(0.0, 1.0, (_clock - SPREAD * (pillars[i].distance_to(center) - _d_min) / span) / RISE) * k
			if up <= 0.0:
				continue
			var ph := _p_phase[i]
			var a := (0.85 if _p_far[i] else 0.62) * (0.45 if i < _p_thin.size() and _p_thin[i] else 1.0)
			var tip := Iso.ground_to_screen(pillars[i]) + Vector2(3.0 * sin(_clock * 2.2 + ph + 2.7), -HIGH * share(i) * up)
			for m in 2:
				var c := fposmod(_clock * 0.5 + ph * 0.3 + float(m) * 0.5, 1.0)
				var wp := tip + Vector2(2.5 * sin(_clock * 1.7 + ph + float(m) * 2.0), -c * 16.0)
				on.draw_rect(Rect2(wp - Vector2(1.5, 1.5), Vector2(3, 3)), Color(VeilParts.BLACK, (1.0 - c) * 0.5 * a * up))
		for e in eyes.size():
			if e >= _eye_h.size() or not (which == 2 or _eye_far[e] == (which == 0)):
				continue
			var ph := fposmod(_clock * 0.35 + float(e) * 0.37, 1.0)
			var up := _risen(eyes[e], k)
			if ph < 0.08 or up <= 0.2:
				continue
			var s := (Iso.ground_to_screen(eyes[e]) + Vector2(0.0, -_eye_h[e] * up)).round()
			var c := Color(VeilParts.SILVER, 0.9 * up)
			on.draw_rect(Rect2(s + Vector2(-4, -1), Vector2(8, 3)), Color(VeilParts.VEIL, 0.18 * up))
			on.draw_rect(Rect2(s + Vector2(-3, 0), Vector2(2, 1)), c)
			on.draw_rect(Rect2(s + Vector2(1, 0), Vector2(2, 1)), c)

	## The thickened dark: each run cut to the front's circle. While it spreads, the front is a soft band (three steps of fading dusk
	## on half rows, strongest at the leading edge) with a faint pale line along the circle wherever it crosses dark ground.
	func _draw_ground(k: float) -> void:
		var f := front()
		var band := CELL * 2.0
		var spreading := f < _d_max + band
		var thick := Color(VeilParts.BLACK, THICK * k)
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
			_strip(x0, x1, a.y, CELL, thick)
			if not spreading:
				continue
			for h in 2:
				var y := a.y + CELL * 0.5 * float(h)
				var dh := y + CELL * 0.25 - center.y
				for j in 3:
					var outer := f - band * float(j) / 3.0
					var inner := f - band * float(j + 1) / 3.0
					if absf(dh) >= outer:
						continue
					var wo := sqrt(outer * outer - dh * dh)
					var wi := sqrt(inner * inner - dh * dh) if absf(dh) < inner else 0.0
					var col := Color(VeilParts.DUSK, (0.5 - 0.15 * float(j)) * k)
					for side in 2:
						var s0 := center.x - wo if side == 0 else center.x + wi
						var s1 := center.x - wi if side == 0 else center.x + wo
						s0 = maxf(s0, a.x)
						s1 = minf(s1, b.x)
						if s0 < s1:
							_strip(s0, s1, y, CELL * 0.5, col)
		if not spreading:
			return
		var seg := PackedVector2Array()
		var line := Color(VeilParts.VEIL, 0.35 * k)
		for n in 97:
			var g := center + Vector2.from_angle(TAU * float(n) / 96.0) * f
			var on := _dark.has(Vector2i(floori((g.x - center.x) / CELL), floori((g.y - center.y) / CELL)))
			if on:
				seg.append(Iso.ground_to_screen(g))
			if (not on or n == 96) and seg.size() > 1:
				draw_polyline(seg, line, 2.0)
			if not on:
				seg = PackedVector2Array()

	func _strip(x0: float, x1: float, y: float, tall: float, c: Color) -> void:
		draw_primitive(PackedVector2Array([Iso.ground_to_screen(Vector2(x0, y)), Iso.ground_to_screen(Vector2(x1, y)),
			Iso.ground_to_screen(Vector2(x1, y + tall)), Iso.ground_to_screen(Vector2(x0, y + tall))]), PackedColorArray([c]), PackedVector2Array())


## The far half of a Dread's wall (screen space, overhead_back, as the Cage and Fence stand): its pillars are a MultiMesh child drawn
## behind it, its eyes and wisps its own drawing; laid and moved by its shade, gone with it.
class WallBack extends Node2D:
	var shade: DreadShade
	var mm: MultiMeshInstance2D

	func _ready() -> void:
		if DreadShade.headless() or not is_instance_valid(shade):
			return
		mm = shade._wall_node()
		mm.show_behind_parent = true
		add_child(mm)
		shade._rebuild_wall()

	func _process(_delta: float) -> void:
		if not is_instance_valid(shade) or shade.is_queued_for_deletion():
			queue_free()

	func _draw() -> void:
		if is_instance_valid(shade):
			var k := shade._shown()
			if k > 0.0:
				shade.draw_wall(self, 0, k)


## Over the shade's near MultiMesh: the near half's wisps and eyes (all of them with no back node), then the frozen's marks.
class WallTop extends Node2D:
	var shade: DreadShade

	func _draw() -> void:
		if is_instance_valid(shade):
			var k := shade._shown()
			if k > 0.0:
				shade.draw_wall(self, 1 if is_instance_valid(shade.back) else 2, k)
				shade.draw_marks(self, k)
