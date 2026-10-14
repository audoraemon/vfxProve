class_name EscortDirector
extends MissionDirector
## The Escort type (v0.11 M2, spec §7.1): lead a charge out past the watch. The charge holds where the god last left him -- he
## moves by the god's hand alone, Mind Whisper or a Will-o'-Wisp's lure -- and escapes at the way out. Soldiers set to watch
## for him seize him on sight (SIGHT): the patrols walking their beats, the watch at the gate and, from `hunt_at`, searchers
## walking to wherever he is. Only those three groups are the director's: a soldier the town has taken (the rally, a marshal's post, a
## fight -- his mind not his post's nor the errand's, or a corps) is left to it and sees nothing, and so is one held by the god
## (MissionDirector.BLIND) or turned (RescueWish.TURNED). A seizer marches him back to `return_to`, and reaching it loses the
## night; the seizer felled, turned, or taken off the errand by the town lets him go where he stands. The watch at the gate
## changes WATCH_CHANGE seconds after he first comes within NEAR_GATE of it, walks to the guardhouse for WATCH_GAP, and changes
## again every WATCH_CYCLE: no wait runs over a minute. A subclass names the charge and the places in _plan() (LostLambDirector).

## Seconds between looks; how far a soldier sees him; how near the way out he escapes; how near `return_to` the seizer
## delivers him; how far he trails his seizer; how near a beat's point a patrol has arrived; how far a place must move before
## someone is sent again.
const TICK := 0.25
const SIGHT := 2.5
const ESCAPE_REACH := 1.2
const RETURN_REACH := 1.0
const TAKE_REACH := 0.9
const ARRIVE := 0.8
const MOVE := 0.3
## The watch at the gate: how near it he starts the change's clock, and its seconds (spec §3; WATCH_GAP tuned from 15 to 25 so
## that a charge at his slow pace can pass the gate while the watch is away).
const NEAR_GATE := 6.0
const WATCH_CHANGE := 30.0
const WATCH_GAP := 25.0
const WATCH_CYCLE := 45.0
## Minds the charge is held in place from: back on his feet. A lure (OBSERVE) or the god's whisper is let run.
const HOLD_FROM := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.REGROUP]
## Minds a soldier takes his post or beat again from. In any other -- the rally, a fight, the god's hold -- he is left to it.
const POST_MINDS := [Person.Mind.POST, Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## The map tags' colours: the charge steel blue, a clear way out green, every soldier who would seize him red.
const MARK_CHARGE := Color("8fb8e8")
const MARK_CLEAR := Color("7fc46a")
const MARK_WATCHED := Color("c8342a")
## How long past each look a bound charge is kept shaking off a whisper and past fear (v0.11 M4): more than a TICK, so neither lapses
## between looks.
const BOUND_HOLD := 1.0

## Set by _plan(): where he starts, the gate's mouth, the way out past it, where a seizer takes him, where the watch goes for
## the change, the watch's posts, each patrol's beat (PackedVector2Array), the patrols' size, when the searchers set out (-1
## for none) and how many, his pace, and the tags' words.
var charge_start := Vector2.INF
var gate_at := Vector2.INF
var exit_at := Vector2.INF
var return_to := Vector2.INF
var guardhouse := Vector2.INF
var watch_posts: Array[Vector2] = []
var beats: Array = []
var patrol_size := 2
var hunt_at := -1.0
var hunt_size := 2
var charge_pace := 1.0
var charge_label := "CHARGE"
var exit_label := "WAY OUT"
var return_label := "BACK"
## v0.11 M4 (mission spec §6, decision 94): a structure the charge starts bound to (The Prisoner's stocks) -- null: free from the
## start, The Lost Lamb's way. While bound he is held at his spot, seen by no one, deaf to a whisper and past fear; its fall frees him.
var bound_by: Structure = null
## Seconds into the night (the timeline's) by which he must be freed, or the night is lost; -1 for no such deadline (v0.11 M4).
var free_by := -1.0
## Seconds after he is freed that the searchers set out (v0.11 M4); -1: at hunt_at on the clock, The Lost Lamb's way. Only one sets
## them out: hunt_at when it is set (>= 0), and hunt_after_free is then ignored.
var hunt_after_free := -1.0

## The charge; the watch; each patrol (an Array[Person]); the searchers. Read only through _alive(): any may be freed (the
## charge at once when he escapes).
var charge: Person
var watch: Array[Person] = []
var patrols: Array = []
var hunters: Array[Person] = []
## He is held, and by whom (a Variant: the seizer may be freed).
var held := false
var seizer: Variant = null
var escaped := false
var taken := false
var seizures := 0
## He is bound now; he was still bound at free_by (the night is lost); the second of the night he was freed, -1 until then (v0.11 M4).
var bound := false
var bound_lost := false
var freed_at := -1.0
## Seconds into the night (v0.11 M4), for the freeing.
var _clock := 0.0
## The watch is away for its change; seconds until the next change (-1 until he first nears the gate); seconds of it left.
var watch_away := false
var change_in := -1.0
var away_left := 0.0
## Each patrol's next point on its beat.
var _beat_at: Array[int] = []
## Where he holds.
var _hold_at := Vector2.INF
var _tick_in := 0.0


## The mission's setup (v0.11 M2): the plan, the charge set down where the god finds him, the watch at its posts and each patrol at
## the start of its beat. v0.11 M4: through the hooks, each handed the charge, and bound if bound_by is set.
func _begin() -> void:
	_plan()
	gate_at = _walkable(gate_at)
	exit_at = _walkable(exit_at)
	return_to = _walkable(return_to)
	guardhouse = _walkable(guardhouse)
	timeline = _new_timeline()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	if hunt_at >= 0.0:
		timeline.add(hunt_at, "hunt", _hunt_label(), _hunt, func() -> bool: return not escaped and not taken and _alive(charge))
	charge = _appoint_charge()
	if charge == null:
		return
	var at := _walkable(charge_start)
	_set_down(charge, at)
	charge.pace *= charge_pace
	_hold_at = at
	charge.go_duty(at)
	crowd.escaped.connect(_on_escaped)
	if bound_by != null:
		bound = true
		if free_by >= 0.0:
			# Bound still, and by stocks still standing (v0.11 M4, the final review): stocks brought down in the last TICK before
			# free_by, which the next look would have answered by freeing him, never lose the night.
			timeline.add(free_by, "inside", _inside_label(), _taken_inside,
				func() -> bool: return bound and is_instance_valid(bound_by) and not bound_by.destroyed and not escaped and _alive(charge))
	watch = _appoint_watch(charge, watch_posts.size())
	for i in watch.size():
		_post_to(watch[i], _walkable(watch_posts[i]), false)
	for b: PackedVector2Array in beats:
		var squad := _appoint_patrol(charge, b, patrol_size)
		patrols.append(squad)
		_beat_at.append(0)
		for i in squad.size():
			_post_to(squad[i], _ring_spot(b[0], 0.5, i, squad.size()), false)
	rules.banner.emit(_opening_banner())


## Virtual (v0.11 M2): the mission's places and numbers.
func _plan() -> void:
	pass


## Virtual (v0.11 M2): who the charge is (eligible: never reserved); null for none. The base takes the lay citizen nearest his start.
func _appoint_charge() -> Person:
	var near := _lay_near(charge_start, 1)
	return near[0] if not near.is_empty() else null


## Everyone already at the night's work for the charge `c` (v0.11 M4, decision 93): `c` himself, the watch, every patrol and the
## searchers -- the list a new appointment leaves out (the old `used`). Virtual: The Prisoner adds her gaolers and searchers. Untyped:
## any may be a freed body.
func _in_use(c: Person) -> Array:
	var out: Array = [c]
	out.append_array(watch)
	for squad: Array in patrols:
		out.append_array(squad)
	out.append_array(hunters)
	return out


## Virtual (v0.11 M4): the `n` watchmen for the gate, set to watch for `c`: the free soldiers nearest the gate's mouth by default.
func _appoint_watch(c: Person, n: int) -> Array[Person]:
	return _free_soldiers(gate_at, n, _in_use(c))


## Virtual (v0.11 M4): the `n` of a patrol walking `beat`, set to watch for `c`: the free soldiers nearest its first point by default.
func _appoint_patrol(c: Person, beat: PackedVector2Array, n: int) -> Array[Person]:
	return _free_soldiers(beat[0], n, _in_use(c))


## Virtual (v0.11 M4): the `n` searchers sent after `c`: by default the free soldiers nearest `return_to`, not already watching for
## him, and at their posts -- never one on the rally's ring or under another town order (the controller's M2 Task 4 fix ruling).
func _appoint_hunters(_c: Person, n: int) -> Array[Person]:
	var out: Array[Person] = []
	for p in _free_soldiers(return_to, crowd.soldiers.size(), _watchers()):
		if p.mind in POST_MINDS and out.size() < n:
			out.append(p)
	return out


## Virtual (v0.11 M4): `p` is sent to his post at `at` (`hurry`: running, as the watch going for its change) -- a soldier's post by
## default (Person.send_to_post()); The Prisoner's lay watchmen go on duty there.
func _post_to(p: Person, at: Vector2, hurry: bool) -> void:
	p.send_to_post(at, false, hurry)


## Virtual (v0.11 M4): `p` takes his post or beat again now -- a soldier of no corps in a POST_MIND by default (in any other, the
## rally, a fight, the god's hold, he is left to the town); The Prisoner's lay watchmen on duty or back on their feet.
func _takes_post(p: Person) -> bool:
	return p.corps == Person.Corps.NONE and p.mind in POST_MINDS


## Virtual: the banners and the timeline's words (v0.11 M2): the opening banner.
func _opening_banner() -> String:
	return "LEAD HIM OUT"


## Virtual (v0.11 M2): the timeline's words when the searchers set out.
func _hunt_label() -> String:
	return "Searchers set out"


## Virtual (v0.11 M2): the banner when a soldier seizes him.
func _caught_banner() -> String:
	return "HE IS CAUGHT"


## Virtual (v0.11 M2): the banner when he is freed of his seizer.
func _freed_banner() -> String:
	return "HE IS FREE"


## Virtual (v0.11 M2): the banner when he is taken back.
func _taken_banner() -> String:
	return "HE IS TAKEN BACK"


## Virtual (v0.11 M2): the banner when he gets out.
func _escape_banner() -> String:
	return "HE IS OUT"


## Virtual (v0.11 M2): the banner when the watch goes for its change.
func _change_banner() -> String:
	return "THE WATCH CHANGES"


## Virtual (v0.11 M4): the timeline's words when a bound charge, still bound, is lost (free_by).
func _inside_label() -> String:
	return "Taken inside"


## Virtual (v0.11 M4): the banner when a bound charge is freed.
func _unbound_banner() -> String:
	return "HE BREAKS FREE"


## Virtual (v0.11 M4, as RazeDirector's and AssassinateDirector's): why the night is lost now, "" while it is not. EscortObjective
## fails with it; The Prisoner's "prisoner_inside".
func lost_reason() -> String:
	return ""


## Virtual (v0.11 M4): the HUD's row in place of the objective's label, "" for the label (The Prisoner's while she is bound).
func hud_line() -> String:
	return ""


## One step (v0.11 M2): the timeline, the watch's change, then every TICK a look at him (free or held), the watch's posts, the
## patrols and the searchers. v0.11 M4: the clock; a bound charge's look.
func step(delta: float) -> void:
	_clock += delta
	timeline.step(delta)
	if escaped or taken or bound_lost or not _alive(charge):
		return
	_watch_step(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	if held:
		_step_held()
	elif bound:
		_step_bound(charge)
	else:
		_step_free()
	if escaped or taken:
		return
	_step_watch_posts()
	_step_patrols()
	_step_hunters()


## Free (v0.11 M2): sheltering indoors, nothing; at the way out he escapes; seen, he is seized; near the gate, the watch's change starts
## its clock; back on his feet he holds where he stands.
func _step_free() -> void:
	if charge.inside:
		return  # sheltering from a fright: hidden, unseen and unheard until he comes out
	if charge.ground_pos.distance_to(exit_at) <= ESCAPE_REACH:
		_escape()
		return
	var by := _seen_by()
	if by != null:
		_seize(by)
		return
	if change_in < 0.0 and charge.ground_pos.distance_to(gate_at) <= NEAR_GATE:
		change_in = WATCH_CHANGE
	if charge.mind in HOLD_FROM:
		_hold_at = charge.ground_pos
		charge.go_duty(_hold_at)
	elif charge.mind == Person.Mind.DUTY and charge.anchor.distance_to(_hold_at) > MOVE:
		charge.go_duty(_hold_at)


## Bound (v0.11 M4, decision 94): `bound_by` down or gone, he is free; else he is held at his spot, kept shaking off a whisper and past
## fear, and set back on it should anything move him (Discord's confusion lasts a TICK at most).
func _step_bound(c: Person) -> void:
	if not is_instance_valid(bound_by) or bound_by.destroyed:
		_unbind(c)
		return
	c._shaken_left = maxf(c._shaken_left, BOUND_HOLD)
	c.fearless_left = maxf(c.fearless_left, BOUND_HOLD)
	if c.mind != Person.Mind.DUTY or c.anchor.distance_to(_hold_at) > MOVE:
		c.go_duty(_hold_at)


## He is freed (v0.11 M4): the holds let go so a whisper takes at once, he holds where he stands, and with hunt_after_free the
## searchers' event goes on the strip that long from now.
func _unbind(c: Person) -> void:
	bound = false
	freed_at = _clock
	c._shaken_left = 0.0
	if c.fearless_left <= BOUND_HOLD:
		c.fearless_left = 0.0
	_hold_at = c.ground_pos
	rules.banner.emit(_unbound_banner())
	if hunt_after_free >= 0.0 and hunt_at < 0.0:
		timeline.add(timeline.elapsed() + hunt_after_free / timeline.stretch_factor(), "hunt", _hunt_label(), _hunt,
			func() -> bool: return not escaped and not taken and _alive(charge))


## Still bound at free_by (v0.11 M4): the night is lost (lost_reason()); the timeline's banner says so.
func _taken_inside() -> void:
	bound_lost = true


## Held (v0.11 M2): the seizer gone, turned or off his errand frees him; the seizer at `return_to` with him in tow, he is taken back;
## else the seizer walks on and he trails him (a whisper may pull him away a while; it does not free him).
func _step_held() -> void:
	if not _alive(seizer) or (seizer as Person).mind != Person.Mind.DUTY:
		_release()
		return
	var s := seizer as Person
	if s.ground_pos.distance_to(return_to) <= RETURN_REACH and charge.ground_pos.distance_to(s.ground_pos) <= TAKE_REACH * 2.0:
		taken = true
		held = false
		crowd.off_duty(s)
		rules.banner.emit(_taken_banner())
		return
	if s.anchor.distance_to(return_to) > MOVE:
		s.go_duty(return_to)
	if charge.mind == Person.Mind.DUTY or charge.mind in HOLD_FROM:
		if charge.mind != Person.Mind.DUTY or charge.anchor.distance_to(s.ground_pos) > TAKE_REACH:
			charge.go_duty(s.ground_pos)


## The first soldier set to watch for him who sees him now (v0.11 M2): _watching() and within SIGHT; else null.
func _seen_by() -> Person:
	for v: Variant in _watchers():
		if _watching(v) and (v as Person).ground_pos.distance_to(charge.ground_pos) <= SIGHT:
			return v as Person
	return null


## `v` is on the director's errand and looking (v0.11 M2, the controller's Task 4 ruling and Decision 20): alive, out of doors,
## of no corps, and at his post or beat (POST_MINDS) or sent after him (DUTY). A soldier held by the god (BLIND), turned
## (RescueWish.TURNED), rallied, marshalled or fighting is in none of those minds: he sees nothing and seizes no one. A Variant,
## as the soldier may be a body already freed.
func _watching(v: Variant) -> bool:
	if not _alive(v):
		return false
	var p := v as Person
	return not p.inside and p.corps == Person.Corps.NONE and (p.mind == Person.Mind.DUTY or p.mind in POST_MINDS)


## Every soldier set to watch for him (v0.11 M2): the watch, the patrols, the searchers (untyped: any may be freed).
func _watchers() -> Array:
	var out: Array = watch.duplicate()
	for squad: Array in patrols:
		out.append_array(squad)
	out.append_array(hunters)
	return out


## `by` seizes him (v0.11 M2): he is held, `by` is sent to march him to `return_to`, and he follows.
func _seize(by: Person) -> void:
	held = true
	seizer = by
	seizures += 1
	rules.banner.emit(_caught_banner())
	by.go_duty(return_to)
	charge.go_duty(by.ground_pos)


## His seizer lets go of him (v0.11 M2): the seizer goes back to the town's post if still on the errand, and he holds where he stands.
func _release() -> void:
	held = false
	if _alive(seizer) and (seizer as Person).mind == Person.Mind.DUTY:
		crowd.off_duty(seizer)
	seizer = null
	_hold_at = charge.ground_pos
	if charge.mind == Person.Mind.DUTY or charge.mind in HOLD_FROM:
		charge.go_duty(_hold_at)
	rules.banner.emit(_freed_banner())


## Out (v0.11 M2): he leaves the town by the escape path (Crowd.escape() frees him at once).
func _escape() -> void:
	escaped = true
	rules.banner.emit(_escape_banner())
	crowd._field.remove(charge)
	crowd.escape(charge)


## However he left the town (v0.11 M2, the controller's Task 4 fix ruling) -- the way out, an exit he fled to, a river boat --
## he has got away, as the Procession's Prince has: the crowd's own exit logic carries him off, and that is his escape, not his
## death. Not twice: _escape() has already said so. A seizer is let go.
func _on_escaped(p: Person) -> void:
	if p != charge or escaped or taken:
		return
	escaped = true
	if held:
		held = false
		if _alive(seizer) and (seizer as Person).mind == Person.Mind.DUTY:
			crowd.off_duty(seizer)
		seizer = null
	rules.banner.emit(_escape_banner())


## The watch's change (v0.11 M2), once its clock has started: away WATCH_GAP, then back, the next change WATCH_CYCLE after this one.
func _watch_step(delta: float) -> void:
	if change_in < 0.0:
		return
	if watch_away:
		away_left -= delta
		if away_left <= 0.0:
			watch_away = false
			change_in = WATCH_CYCLE - WATCH_GAP
		return
	change_in -= delta
	if change_in <= 0.0:
		watch_away = true
		away_left = WATCH_GAP
		rules.banner.emit(_change_banner())


## Each watchman (v0.11 M2) to his post, or to the guardhouse while the watch is away; one reserved, of a corps, or in a mind not his own
## is left be.
func _step_watch_posts() -> void:
	for i in watch.size():
		var v: Variant = watch[i]
		if not _alive(v) or reserved.has(v):
			continue
		var w := v as Person
		if not _takes_post(w):
			continue
		var spot := _ring_spot(guardhouse, 0.6, i, watch.size()) if watch_away else _walkable(watch_posts[i])
		if w.anchor.distance_to(spot) > MOVE:
			_post_to(w, spot, watch_away)


## Each patrol along its beat (v0.11 M2): its first soldier on his own post leads; at a beat's point, on to the next (round and round).
func _step_patrols() -> void:
	for k in patrols.size():
		var squad: Array = patrols[k]
		var beat: PackedVector2Array = beats[k]
		var lead: Variant = null
		for v: Variant in squad:
			if _on_post(v):
				lead = v
				break
		if lead == null:
			continue
		if (lead as Person).ground_pos.distance_to(beat[_beat_at[k]]) <= ARRIVE:
			_beat_at[k] = (_beat_at[k] + 1) % beat.size()
		var to := beat[_beat_at[k]]
		for i in squad.size():
			var v: Variant = squad[i]
			if not _on_post(v):
				continue
			var spot := _ring_spot(to, 0.5, i, squad.size())
			if (v as Person).anchor.distance_to(spot) > MOVE:
				_post_to(v as Person, spot, false)


## `v` stands on his own post (v0.11 M2): alive, not reserved, of no corps, in a mind of POST_MINDS (a seizer, on duty, is not).
func _on_post(v: Variant) -> bool:
	return _alive(v) and not reserved.has(v) and _takes_post(v as Person)


## The searchers set out (v0.11 M2, the controller's Task 4 fix ruling): the free soldiers nearest `return_to`, not already
## watching for him, and at their posts (POST_MINDS) -- never one on the rally's ring or under another town order, which the
## director leaves to the town. v0.11 M4: through _appoint_hunters().
func _hunt() -> void:
	hunters.clear()
	hunters = _appoint_hunters(charge, hunt_size)
	for h in hunters:
		h.go_duty(charge.ground_pos)


## Each searcher kept walking to where he is now (v0.11 M2; one in a mind not his own is left be).
func _step_hunters() -> void:
	for v: Variant in hunters:
		if not _alive(v) or v == seizer:
			continue
		var h := v as Person
		if h.mind == Person.Mind.DUTY or h.mind in POST_MINDS:
			if h.mind != Person.Mind.DUTY or h.anchor.distance_to(charge.ground_pos) > 1.0:
				h.go_duty(charge.ground_pos)


## A watchman stands at the gate who would see him (v0.11 M2): _watching() and within SIGHT + 1 of its mouth.
func _watch_standing() -> bool:
	for v: Variant in watch:
		if _watching(v) and (v as Person).ground_pos.distance_to(gate_at) <= SIGHT + 1.0:
			return true
	return false


## The gate is watched, as the map tag and the hint say it (v0.11 M2, final review): a watchman stands at it (_watch_standing()),
## or the watch's change is over and one who would see him is walking back to his post from the guardhouse -- his goal is the
## post -- so the gate does not read clear while the watch is on its way. One drawn off elsewhere (a lure, a fright) is not
## counted. Only reads; the seizing rule is _seen_by()'s alone.
func _gate_watched() -> bool:
	if _watch_standing():
		return true
	if watch_away:
		return false
	for i in watch.size():
		var v: Variant = watch[i]
		if _watching(v) and (v as Person).goal().distance_to(_walkable(watch_posts[i])) <= MOVE:
			return true
	return false


## He is dead, and did not escape (v0.11 M2).
func charge_lost() -> bool:
	return not escaped and not _alive(charge)


## The map tags (v0.11 M2), most important first, while he is in the town:
## - him, pointed at from the edge (red and CAUGHT while held);
## - the way out, clear (green) or watched (red: _gate_watched()), pointed at from the edge (v0.11 M2, Task 8 fix: it lies out of sight of
##   the charge);
## - his seizer, pointed at, and the Temple, while he is held;
## - each searcher, pointed at;
## - a red diamond on each patrol soldier (the first labelled PATROL) and each watchman at the gate.
func tags() -> Array[MapTag]:
	var out: Array[MapTag] = []
	if escaped or taken or not _alive(charge):
		return out
	if held:
		out.append(MapTag.person(charge.ground_pos, MARK_WATCHED, charge_label + " - CAUGHT", true))
	else:
		out.append(MapTag.person(charge.ground_pos, MARK_CHARGE, charge_label, true))
	var clear := watch_away or not _gate_watched()
	out.append(MapTag.place(exit_at, MARK_CLEAR if clear else MARK_WATCHED, exit_label + (" - CLEAR" if clear else " - WATCHED"),
		0.0, true))
	if held and _alive(seizer):
		out.append(MapTag.person((seizer as Person).ground_pos, MARK_WATCHED, "TAKING HIM BACK", true))
		out.append(MapTag.place(return_to, MARK_WATCHED, return_label))
	for v: Variant in hunters:
		if _alive(v) and v != seizer and not (v as Person).inside:
			out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "SEARCHER", true))
	for squad: Array in patrols:
		var named := false
		for v: Variant in squad:
			if _alive(v) and v != seizer and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED, "" if named else "PATROL"))
				named = true
	if not watch_away:
		for v: Variant in watch:
			if _alive(v) and v != seizer and not (v as Person).inside:
				out.append(MapTag.person((v as Person).ground_pos, MARK_WATCHED))
	return out


## The hint's phase (v0.11 M2): "caught" while held; near the gate, "gate" while it is watched (_gate_watched(): a watchman stands there, or the
## watch is walking back to its posts), "clear" while the watch is away or none would see him; else "".
func hint_phase() -> String:
	if escaped or taken or not _alive(charge):
		return ""
	if held:
		return "caught"
	if charge.ground_pos.distance_to(gate_at) <= NEAR_GATE:
		return "clear" if watch_away or not _gate_watched() else "gate"
	return ""


## What the director adds to the results (v0.11 M2): how many times he was seized, and whether he got out.
func report() -> Dictionary:
	return {"seizures": seizures, "out": escaped}


## Lets go of the crowd's exits and the timeline (v0.11 M2).
func teardown() -> void:
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	timeline = null  # its banner and guard lambdas hold this director: let both go
