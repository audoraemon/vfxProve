class_name DreamlessFx
extends FxTimeline
## Dreamless (Veil, Tier 3): the nearest MOST within REACH (VeilRules: 1 within 1.0 light / 4 within 2.0 dark) are fixed at the click and,
## by T_SIT, sit down against the nearest wall as if to rest -- deep asleep (Person.sleep(.., true)), statuses[&"dreamless"] on them.
## For the next REST seconds the town sees only people resting: no witness reacts, no alarm. At T_SIT + REST each still-sleeping one
## dies with kind &"dreamless" (a body, found like any other dead; credited to the cast by Rules.POWER_KINDS). Anyone already asleep
## at T_SIT (Slumber, Curfew, a night sleeper) or a shadow's owner is taken at once, kind &"dreamt": no body, never found. Quiet: no
## danger, no fright, no alarm, no cue. Its dusk is laid at the cast (VeilParts.land(); VB0).
## Teardown: the status is lifted and the sit's sleep ends in _finish() AND in _exit_tree(); nobody dies after an early end.

const REST := 20.0
const T_SIT := 0.8
## Found by No One: a finder rests this share of REST (at its level) and 5 s more asleep, then is judged by the same search.
const REST_SHARE := 0.5
## How far someone walks to the nearest wall to sit against it.
const WALL_REACH := 2.0
## How far off the wall the sitter's back is.
const WALL_GAP := 0.3
const BREATH := [Color("3a2a55"), Color("1a1030"), Color("0b0716"), Color(0.03, 0.02, 0.06, 0.5)]

## The cast's look (Veil review): the dark breath sinking at the click.
const SINK := [Color("4a3470"), Color("2a1a48"), Color("140c24"), Color(0.05, 0.03, 0.09, 0.4)]

## The look's pieces while they play (tests): the breath on the ground, the threads.
var breath: Node2D
var threads: VeilCastLooks.Threads
## This cast's rest, at its level (REST at level 1).
var lv_rest := REST

var _victims: Array[Person] = []
var _sat: Array[Person] = []
var _undone := false
## Found by No One (level 5, Veil ability levels B3): the twist's gate; everyone it never lets name another (the sitters' and the
## resting finders' instance ids, VL9); the finders at rest, in the order they were set down; how many were set to rest.
var _twist := false
var _skip := {}
var _finders: Array[Person] = []
var finders := 0
## How many were taken at once (&"dreamt") and how many were set to rest.
var taken := 0
var resting := 0


## Who Dreamless would take at `at`: the nearest `most` living people in the open within `r`, by distance and then instance id (no luck).
static func victims_at(field: EnemyField, at: Vector2, r: float, most: int) -> Array[Person]:
	var out := DominionParts.near(field, at, r)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(at)
		var db := b.ground_pos.distance_squared_to(at)
		if is_equal_approx(da, db):
			return a.get_instance_id() < b.get_instance_id()
		return da < db)
	return out.slice(0, most)


func _build() -> void:
	lv_rest = PowerBook.stat(extra, "dreamless", "REST", REST)
	var r := VeilParts.size(self, "dreamless", "REACH")
	var most := int(VeilParts.size(self, "dreamless", "MOST"))
	_twist = PowerBook.twist_at(extra, "dreamless")
	duration = T_SIT + lv_rest + 1.0
	if _twist:
		duration = T_SIT + lv_rest + lv_rest * REST_SHARE + 1.0
	busy = T_SIT
	VeilParts.land(self, origin, r)
	ctx.play(&"v_dreamless", origin)
	if ctx.field != null:
		_victims = victims_at(ctx.field, origin, r, most)
	for p in _victims:
		var spot := _wall_spot(p)
		if spot != Vector2.INF:
			p.set_goal(spot)
	at(T_SIT, _sit)
	at(T_SIT + lv_rest, _found)
	if DominionParts.staged(self):
		_cast_look(r)


## The cast's look (Veil review, spec 5): a slow dark breath sinks at the click and spreads over the reach; the threads over the
## sitters are drawn by one node, fed at the sit.
func _cast_look(r: float) -> void:
	var screen := Iso.ground_to_screen(origin)
	var sink := VeilCastLooks.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, SINK,
		VeilCastLooks.seed_of(origin, 31))
	sink.drag = 0.7
	sink.burst(18, {"radius": 7.0, "speed": Vector2(4, 16), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(30, 46),
		"alt_speed": Vector2(-44, -24), "life": Vector2(0.8, 1.1), "size": Vector2(3, 5), "size_end_mul": 1.5})
	var wave := VeilCastLooks.Wave.new()
	wave.r = r
	wave.rim = Color(VeilParts.BLACK, 0.5)
	wave.fill = Color(VeilParts.BLACK, 0.2)
	wave.edge = Color(VeilParts.SILVER, 0.4)
	wave.grow = T_SIT
	wave.hold = 0.5
	wave.fade = 1.0
	wave.position = origin
	wave.z_index = 2
	breath = track(wave, ctx.ground) as Node2D
	var th := VeilCastLooks.Threads.new()
	th.fx_id = get_instance_id()
	threads = track(th, ctx.overhead) as VeilCastLooks.Threads


## Seconds of the rest still to run (0 once he is found).
func rest_left() -> float:
	return maxf(T_SIT + lv_rest - t, 0.0)


## Whether `p` rests under this cast now (sat, asleep, the status on him).
func rests(p: Person) -> bool:
	return p != null and _sat.has(p) and p.statuses.has(&"dreamless")


## Where `p` sits: against the nearest standing wall within WALL_REACH, else where he stands (Vector2.INF: stay).
func _wall_spot(p: Person) -> Vector2:
	if ctx.env == null:
		return Vector2.INF
	var best: Structure = null
	var best_d := INF
	for s in ctx.env.near(p.ground_pos, WALL_REACH):
		if s.destroyed or s.walkable:
			continue
		var d := s.distance_to(p.ground_pos)
		if d < best_d or (is_equal_approx(d, best_d) and s.get_instance_id() < best.get_instance_id()):
			best_d = d
			best = s
	if best == null or best_d > WALL_REACH:
		return Vector2.INF
	var edge := p.ground_pos.clamp(best.footprint.position, best.footprint.end)
	var out := p.ground_pos - edge
	if out.length() < 0.001:
		return Vector2.INF  # standing in the footprint's box: sit here
	var spot := edge + out.normalized() * WALL_GAP
	if ctx.env.blocked(spot, 0.0) or spot.distance_to(p.ground_pos) > WALL_REACH:
		return Vector2.INF
	return spot


func _sit() -> void:
	for p in _victims:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue  # died, boarded or went in since the cast
		if p.is_asleep() or p.is_shadow():
			if ctx.crowd != null and ctx.crowd.take(p, &"dreamt"):
				taken += 1
			continue
		var spot := _wall_spot(p)
		if spot != Vector2.INF:
			p.ground_pos = spot  # the last steps to the wall, settled
		if p.sleep(lv_rest + 5.0, true):
			p.statuses[&"dreamless"] = 1.0
			_sat.append(p)
			resting += 1
			_breath(p)


## A sitter who is awake again (a hurt wakes a deep sleeper) is no longer resting: his status goes and he leaves the sitters, so a later
## deep sleep (a dark Slumber) is a plain sleep and the find does not kill him (VB1).
func _fx_process(_delta: float) -> void:
	if _twist and not _finders.is_empty():
		_wake_check()
	if _sat.is_empty() or _undone:
		return
	var i := _sat.size() - 1
	while i >= 0:
		var p := _sat[i]
		if not is_instance_valid(p) or not p.is_alive() or not p.is_asleep():
			if is_instance_valid(p):
				p.statuses.erase(&"dreamless")
			_sat.remove_at(i)
		i -= 1


func _found() -> void:
	if _twist and ctx.crowd != null:
		_found_by_none()
		return
	var dying: Array[Person] = []
	for p in _sat:
		if is_instance_valid(p) and p.is_alive() and p.statuses.has(&"dreamless") and p.is_deep_asleep():
			dying.append(p)
	for p in dying:
		p.statuses.erase(&"dreamless")  # the status ends with the rest; the kill is the god's
		if p.is_alive():
			ctx.field.kill(p, &"dreamless")
	_undo()


## Found by No One (level 5): at the find, in order (nearest the click, then id), each sitter still resting is looked for by the witness
## search with every sitter and resting finder skipped. Nobody near: taken (&"dreamt"). A finder who is not the god's own: the sitter is
## taken, the finder is eyed and rests deep for half the REST (+5 s of sleep), then is judged by the same search (nobody near: taken;
## somebody: killed &"dreamless", a body for today's settle). A finder who is spared: eyed only, the sitter dies a body as today.
## One finder rests once.
func _found_by_none() -> void:
	var order: Array[Person] = []
	for p in _sat:
		if is_instance_valid(p) and p.is_alive():
			_skip[p.get_instance_id()] = true
			order.append(p)
	order.sort_custom(func(a: Person, b: Person) -> bool:
		var da := a.ground_pos.distance_squared_to(origin)
		var db := b.ground_pos.distance_squared_to(origin)
		return da < db if da != db else a.get_instance_id() < b.get_instance_id())
	var judged := false
	for s in order:
		if not (s.is_alive() and s.statuses.has(&"dreamless") and s.is_deep_asleep()):
			continue
		var w := ctx.crowd.nearest_witness(s.ground_pos, null, _skip)
		if w == null:
			s.statuses.erase(&"dreamless")
			if ctx.crowd.take(s, &"dreamt"):
				taken += 1
			continue
		PaleEye.mark(self, w, "dreamless")
		s.statuses.erase(&"dreamless")
		if ctx.crowd.spared(w):
			ctx.field.kill(s, &"dreamless")
			continue
		if ctx.crowd.take(s, &"dreamt"):
			taken += 1
		if w.sleep(lv_rest * REST_SHARE + 5.0, true):
			w.statuses[&"dreamless"] = 1.0
			_skip[w.get_instance_id()] = true
			_finders.append(w)
			finders += 1
			judged = true
			_breath(w)
	if judged:
		at(t + lv_rest * REST_SHARE, _judge_finders)
	_undo()


## A finder who is awake again (a hurt) is no longer resting: his status goes and he is not judged.
func _wake_check() -> void:
	var i := _finders.size() - 1
	while i >= 0:
		var w := _finders[i]
		if not is_instance_valid(w) or not w.is_alive() or not w.is_asleep():
			if is_instance_valid(w):
				w.statuses.erase(&"dreamless")
			_finders.remove_at(i)
		i -= 1


## The finders' rest is over: each who still rests is looked for by the same search (the sitters and the finders skipped). Nobody near:
## taken (&"dreamt"). Somebody: killed &"dreamless", and today's settle judges the body.
func _judge_finders() -> void:
	_wake_check()
	var rest := _finders.duplicate()
	_finders.clear()
	for w in rest:
		w.statuses.erase(&"dreamless")
		if not w.is_deep_asleep():
			continue
		if ctx.crowd.nearest_witness(w.ground_pos, w, _skip) == null:
			if ctx.crowd.take(w, &"dreamt"):
				taken += 1
		else:
			ctx.field.kill(w, &"dreamless")


## One dark breath leaving the sitter, nothing more.
func _breath(p: Person) -> void:
	if not DominionParts.staged(self):
		return
	if threads != null and is_instance_valid(threads):
		threads.add(p)  # his thread rises
	var m := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(p.ground_pos) + Vector2(0, -10), PixelParticles.Shape.PUFF, BREATH)
	m.gravity = -14.0
	m.drag = 1.6
	m.burst(5, {"radius": 2.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(4, 10),
		"life": Vector2(0.7, 1.1), "size": Vector2(2, 3), "size_end_mul": 1.8})


## Lifts the status and ends the rest of everyone still resting (whoever the effect set down; a hurt may have woken them already).
func _undo() -> void:
	if _undone:
		return
	_undone = true
	for p in _sat:
		if not is_instance_valid(p):
			continue
		p.statuses.erase(&"dreamless")
		if p.is_alive() and p.is_asleep():
			p.wake()
	_sat.clear()


## The finders' rest ends with the cast: the status goes and anyone still asleep by it wakes (nobody is taken or killed by an early end).
func _release_finders() -> void:
	for w in _finders:
		if not is_instance_valid(w):
			continue
		w.statuses.erase(&"dreamless")
		if w.is_alive() and w.is_asleep():
			w.wake()
	_finders.clear()


func _finish() -> void:
	_undo()
	_release_finders()
	super._finish()


func _exit_tree() -> void:
	_undo()
	_release_finders()
	super._exit_tree()


## Freed without finishing and off the tree (no _exit_tree): the finders at rest still wake.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _twist:
		_release_finders()
