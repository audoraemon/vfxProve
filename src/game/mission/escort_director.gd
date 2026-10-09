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
## the start of its beat.
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
	var used: Array = [charge]
	watch = _free_soldiers(gate_at, watch_posts.size(), used)
	used.append_array(watch)
	for i in watch.size():
		watch[i].send_to_post(_walkable(watch_posts[i]))
	for b: PackedVector2Array in beats:
		var squad := _free_soldiers(b[0], patrol_size, used)
		used.append_array(squad)
		patrols.append(squad)
		_beat_at.append(0)
		for i in squad.size():
			squad[i].send_to_post(_ring_spot(b[0], 0.5, i, squad.size()))
	rules.banner.emit(_opening_banner())


## Virtual (v0.11 M2): the mission's places and numbers.
func _plan() -> void:
	pass


## Virtual (v0.11 M2): who the charge is (eligible: never reserved); null for none. The base takes the lay citizen nearest his start.
func _appoint_charge() -> Person:
	var near := _lay_near(charge_start, 1)
	return near[0] if not near.is_empty() else null


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


## One step (v0.11 M2): the timeline, the watch's change, then every TICK a look at him (free or held), the watch's posts, the
## patrols and the searchers.
func step(delta: float) -> void:
	timeline.step(delta)
	if escaped or taken or not _alive(charge):
		return
	_watch_step(delta)
	_tick_in -= delta
	if _tick_in > 0.0:
		return
	_tick_in = TICK
	if held:
		_step_held()
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
		if w.corps != Person.Corps.NONE or not w.mind in POST_MINDS:
			continue
		var spot := _ring_spot(guardhouse, 0.6, i, watch.size()) if watch_away else _walkable(watch_posts[i])
		if w.anchor.distance_to(spot) > MOVE:
			w.send_to_post(spot, false, watch_away)


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
				(v as Person).send_to_post(spot)


## `v` stands on his own post (v0.11 M2): alive, not reserved, of no corps, in a mind of POST_MINDS (a seizer, on duty, is not).
func _on_post(v: Variant) -> bool:
	return _alive(v) and not reserved.has(v) and (v as Person).corps == Person.Corps.NONE and (v as Person).mind in POST_MINDS


## The searchers set out (v0.11 M2, the controller's Task 4 fix ruling): the free soldiers nearest `return_to`, not already
## watching for him, and at their posts (POST_MINDS) -- never one on the rally's ring or under another town order, which the
## director leaves to the town.
func _hunt() -> void:
	hunters.clear()
	for p in _free_soldiers(return_to, crowd.soldiers.size(), _watchers()):
		if p.mind in POST_MINDS and hunters.size() < hunt_size:
			hunters.append(p)
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


## He is dead, and did not escape (v0.11 M2).
func charge_lost() -> bool:
	return not escaped and not _alive(charge)


## The map tags (v0.11 M2), most important first, while he is in the town:
## - him, pointed at from the edge (red and CAUGHT while held);
## - the way out, clear (green) or watched (red), pointed at from the edge (v0.11 M2, Task 8 fix: it lies out of sight of the charge);
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
	var clear := watch_away or not _watch_standing()
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


## The hint's phase (v0.11 M2): "caught" while held; near the gate, "clear" while the watch is away (or none stands) else "gate"; else "".
func hint_phase() -> String:
	if escaped or taken or not _alive(charge):
		return ""
	if held:
		return "caught"
	if charge.ground_pos.distance_to(gate_at) <= NEAR_GATE:
		return "clear" if watch_away or not _watch_standing() else "gate"
	return ""


## What the director adds to the results (v0.11 M2): how many times he was seized, and whether he got out.
func report() -> Dictionary:
	return {"seizures": seizures, "out": escaped}


## Lets go of the crowd's exits and the timeline (v0.11 M2).
func teardown() -> void:
	if is_instance_valid(crowd) and crowd.escaped.is_connected(_on_escaped):
		crowd.escaped.disconnect(_on_escaped)
	timeline = null  # its banner and guard lambdas hold this director: let both go
