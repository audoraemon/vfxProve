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
## thickens, and its edge shows pale eyes. Its dusk is laid at the click when the dread lifts (ruling VC1).

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
## Whether the dread has lifted (and the dusk been laid).
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


func _finish() -> void:
	_lift()
	super()


func _exit_tree() -> void:
	_release()
	super()


## Freed without finishing (an effect layer torn down outside the tree): the dread still ends and everyone goes free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_release()


## The god's look of a Dread (screen space, the overhead layer): the dark ground inside the reach thickens, in rows of ground cells,
## and pale eyes open at its edge, blinking slowly; under each frozen person a hard dark mark, standing rigid. Drawn only (no
## simulation state). It re-reads the dark every REFRESH seconds while the dread holds.
class DreadShade extends Node2D:
	## Ground size of one cell of the thickened dark.
	const CELL := 0.5
	const REFRESH := 0.5
	## At most this many pairs of eyes along the edge.
	const EYES := 12

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
		queue_redraw()

	func _draw() -> void:
		if strength <= 0.0:
			return
		var thick := Color(VeilParts.BLACK, 0.38 * strength)
		var half := Vector2(0.0, CELL)
		for r: Array in runs:
			var a: Vector2 = r[0]
			var b: Vector2 = r[1]
			draw_colored_polygon(PackedVector2Array([Iso.ground_to_screen(a), Iso.ground_to_screen(b), Iso.ground_to_screen(b + half),
				Iso.ground_to_screen(a + half)]), thick)
		# Pale eyes at the edge of the dark, each pair blinking on its own slow beat.
		for k in eyes.size():
			var ph := fposmod(_clock * 0.35 + float(k) * 0.37, 1.0)
			if ph < 0.08:
				continue
			var s := Iso.ground_to_screen(eyes[k]) + Vector2(0, -3)
			var c := Color(VeilParts.SILVER, 0.85 * strength)
			draw_rect(Rect2(s + Vector2(-2, 0), Vector2(1, 1)), c)
			draw_rect(Rect2(s + Vector2(1, 0), Vector2(1, 1)), c)
		# The frozen stand rigid: a hard dark mark under each.
		for id in held:
			var p := instance_from_id(id) as Person
			if p == null or not p.is_alive() or p.inside:
				continue
			var f := Iso.ground_to_screen(p.ground_pos)
			draw_rect(Rect2(f + Vector2(-4, -1), Vector2(8, 2)), Color(VeilParts.BLACK, 0.7 * strength))
			draw_rect(Rect2(f + Vector2(-3, -2), Vector2(6, 1)), Color(VeilParts.VEIL, 0.35 * strength))
