class_name VigilFlameDirector
extends MissionDirector
## The Vigil Flame (v0.10 M4, the Theft path's Night 2): Halcyon's eternal flame holds part of the power he gave the
## town, and a god cannot hold it: a mortal hand must take it.
## - The Vigil: the flame-bearer walks the six wayside shrines' route (Broken Lanterns' points; no shrines stand here)
##   with two acolytes, round and round at a solemn pace. The flame passes to an acolyte if he falls; with all three
##   dead the lantern lies where the last one fell.
## - Wren: at 0:50 a street urchin comes to watch the silver lantern. Whispered within SWAP_REACH of it, he takes hold
##   and swaps the real flame for a false one in SWAP_SECONDS. A Faithful other than the bearer (the one robbed) within
##   Crowd.DOOM_WITNESS of him as it is done, not held by the god, sees it (Silent Doom's witness rule) and runs to the
##   Temple to report it (TempleReport); a report reaching the Temple fills Halcyon's Gaze. Left WREN_OWN_AFTER seconds
##   without a whisper, Wren tries the swap himself.
## - 1:30: a suspicious priest sends the Vigil straight back to the Temple. The bearer reaching it with the real flame
##   keeps it, and the night is lost.
## - The flame home: Wren carries it to Mira's shrine at the west forest edge; there it relights with the god's own
##   flame and the night is won. Wren dead, or dawn first, loses it. A death someone sees adds to the Gaze, and the bell
##   fills it.
## - Phase 2: from the swap until the flame is home, Halcyon's Searchlight (Searchlight, drawn by SearchlightFx) sweeps
##   the town from the Temple's spire: one beam, a second 30 s on, a Will-o'-Wisp a decoy, and in the clock's last 20 s
##   a beam stopping to search at the latest noise (any cast but a whisper, any death). A beam touching Wren adds
##   TOUCH_GAZE (two fill the Gaze); a Faithful it touches stops and prays.

## Mira's shrine at the west forest edge, outside the west wall (ground units; moved to the nearest open ground), and how
## near Wren must bring the flame.
const MIRA_SHRINE := Vector2(-17.6, 5.0)
const SHRINE_REACH := 1.0
## How many Faithful there are besides the clergy (spec §4.1: about 20 devout citizens).
const FAITHFUL := 20
## The Vigil's solemn pace: the share of their own pace its three walk at. The bearer keeps BEARER_LEAD of his slowest
## acolyte's pace, so both keep beside him (each makes for his side again only every VigilRoute.TICK).
const VIGIL_PACE := 0.5
const BEARER_LEAD := 0.85
## 0:50 -- Wren comes to watch the lantern, keeping WATCH_DIST from it; left WREN_OWN_AFTER seconds without a whisper,
## he tries the swap himself.
const WREN_AT := 50.0
const WATCH_DIST := 3.0
const WREN_OWN_AFTER := 30.0
## The swap: begun within SWAP_REACH of the lantern (whispered there, or on his own try), it takes SWAP_SECONDS while
## Wren keeps within SWAP_HOLD of it on his duty; any farther, or Wren off his duty (frightened, held), breaks it.
const SWAP_REACH := 1.0
const SWAP_HOLD := 1.6
const SWAP_SECONDS := 3.0
## Wren with the flame walks carefully: the share of his own pace he keeps.
const WREN_PACE := 0.5
## 1:30 -- the route shortens, straight back to the Temple; the bearer within HOME_REACH of its door with the real flame
## keeps it.
const ROUTE_AT := 90.0
const HOME_REACH := 1.0
## Where the camera opens: by the Temple, where the Vigil sets out.
const CAMERA_AT := Vector2(1.5, -8.0)
## The marks: Wren, the real flame (in its lantern, or fallen), and Mira's shrine.
const MARK_WREN := Color("8fe0ff")
const MARK_FLAME := Color(0.95, 0.82, 0.42, 0.9)
const MARK_SHRINE := Color("ff9a3a")
## Seconds between the director's looks at Wren's errand.
const TICK := 0.5
## Minds Wren picks his errand up again from.
const RESUMABLE := [Person.Mind.CALM, Person.Mind.RECOVER, Person.Mind.OBSERVE, Person.Mind.REGROUP]
## A death someone sees adds this share of GazeMeter.SEEN_DEATH in this mission (FlameGaze): Task 7's lever, so the
## shared GazeMeter stays as Mira's House and Broken Lanterns have it.
const SEEN_DEATH_SCALE := 1.0
## Phase 2 (spec §4.1): a beam touching Wren adds TOUCH_GAZE, once each time he comes into the light (two fill the Gaze).
## A Faithful a beam touches stops and prays PRAY_SECONDS where he stands; on his duty within PRAY_REACH of that spot
## he prays, feeding the Gaze (GazeMeter.pray(), scaled by PRAYER_SCALE: Task 7's lever for this mission alone). The
## Vigil's walkers and report carriers never stop to pray.
const TOUCH_GAZE := GazeMeter.SEARCHLIGHT
const PRAY_SECONDS := 5.0
const PRAY_REACH := 0.6
const PRAYER_SCALE := 0.5
## Casts the light does not hear: a Mind Whisper speaks in the mind.
const UNHEARD := ["whisper"]

var vigil: VigilRoute
var temple_door := Vector2.INF
## Mira's shrine, on open ground.
var shrine := Vector2.INF
var searchlight: Searchlight
var wren: Person
var appeared := false
## Wren has been whispered (he never tries on his own then), or is trying the swap himself.
var whispered := false
var attempting := false
## The swap under way, and its seconds left.
var swapping := false
var swap_left := 0.0
## The real flame has left the lantern (Phase 2), and whether a Faithful saw it go.
var swapped := false
var swap_seen := false
## The flame is home at Mira's shrine (the win); the bearer kept it (a loss); nobody could be Wren (a loss).
var home := false
var kept := false
var no_wren := false
## The route has shortened: the Vigil is going home.
var homeward := false
## Where the real flame is while in its lantern: with its bearer, or where the last bearer fell.
var _lantern := Vector2.INF
var _appeared_at := 0.0
var _tick := 0.0
## Phase 2: how many times a beam has found Wren; the Faithful at prayer in the light -> [seconds left, where they
## kneel]; the bench's light, with no quarry (bench_beams()).
var touches := 0
var praying := {}
var benching := false
var _in_light := false
var _fx: SearchlightFx


func _begin() -> void:
	gaze = FlameGaze.new()
	temple_door = _walkable(Vector2(TownLayout.TEMPLE.get_center().x, TownLayout.TEMPLE.end.y + 0.6))
	shrine = _walkable(MIRA_SHRINE)
	searchlight = Searchlight.new().setup(TownLayout.TEMPLE.get_center())
	_choose_faithful(FAITHFUL)
	_start_vigil()
	crowd._field.enemy_killed.connect(_on_killed)
	_listen()
	timeline = EventTimeline.new()
	timeline.fired.connect(func(_id: String, label: String) -> void: rules.banner.emit(label.to_upper()))
	timeline.add(WREN_AT, "wren", "A boy watches the lantern", _wren_comes)
	timeline.add(ROUTE_AT, "route", "The route shortens", _route_home, func() -> bool: return vigil != null and vigil.active)
	_add_events()
	rules.banner.emit("STEAL HALCYON'S FLAME")


## The flame-bearer and his two acolytes are the clergy nearest the Temple's door (else any Faithful). They walk the six
## shrines' route round and round at VIGIL_PACE, the flame passing on if the bearer falls.
func _start_vigil() -> void:
	var walkers := _vigil_walkers(faithful.duplicate(), temple_door)
	if walkers.is_empty():
		return
	var route := PackedVector2Array()
	for spot: Vector2 in BrokenLanternsDirector.SHRINE_SPOTS:
		route.append(_walkable(_walkable(spot) + BrokenLanternsDirector.RELIGHT_OFF))
	var acolytes: Array[Person] = []
	acolytes.assign(walkers.slice(1))
	vigil = VigilRoute.new().setup(route, walkers[0], acolytes)
	vigil.loop = true
	vigil.pass_flame = true
	vigil.busy = _carrying
	vigil.flame_passed.connect(func(_to: Person) -> void: rules.banner.emit("AN ACOLYTE TAKES UP THE FLAME"))
	for p in vigil.walkers():
		p.pace *= VIGIL_PACE
	for a in acolytes:
		vigil.bearer.pace = minf(vigil.bearer.pace, a.pace * BEARER_LEAD)
	vigil.start()
	_lantern = vigil.bearer.ground_pos


func step(delta: float) -> void:
	timeline.step(delta)
	gaze.judge_deaths(crowd)
	if vigil != null:
		vigil.step(delta)
		if vigil.active and _alive(vigil.bearer):
			_lantern = vigil.bearer.ground_pos
	_step_reports(delta)
	if not swapped:
		_home_check()
		_swap_step(delta)
	_wren_step(delta)
	_phase2_step(delta)
	if crowd.bell != null and crowd.bell.state == BellNetwork.State.RUNG:
		gaze.fill()


func _on_killed(e: DummyEnemy, _kind: StringName) -> void:
	gaze.note_death(e.ground_pos)
	for r in reports:
		r.on_killed(e)
	_noise(e.ground_pos)


## 0:50 -- the living lay citizen nearest the lantern who is not of the Faith becomes Wren and comes to watch it. With
## nobody left to be him, the night is lost.
func _wren_comes() -> void:
	var lay: Array[Person] = []
	var clergy: Array[Person] = []
	_sort_citizens(clergy, lay)
	for p in lay:
		if faithful.has(p):
			continue
		if wren == null or p.ground_pos.distance_to(_lantern) < wren.ground_pos.distance_to(_lantern):
			wren = p
	if wren == null:
		no_wren = true
		return
	appeared = true
	_appeared_at = timeline.elapsed()
	_tick = 0.0


## 1:30 -- a suspicious priest sends the Vigil straight back to the Temple.
func _route_home() -> void:
	homeward = true
	vigil.shorten_to(temple_door)


## The route shortened, the bearer at the Temple's door with the real flame keeps it: the night is lost.
func _home_check() -> void:
	if not homeward or vigil == null or not _alive(vigil.bearer):
		return
	if vigil.bearer.ground_pos.distance_to(temple_door) <= HOME_REACH:
		kept = true


## The swap: begun when Wren, whispered there or on his own try, comes within SWAP_REACH of the lantern. It runs while
## he keeps within SWAP_HOLD of it on his duty (keeping pace with the bearer), and is broken otherwise.
func _swap_step(delta: float) -> void:
	if not appeared or not _alive(wren) or wren.inside or _lantern == Vector2.INF:
		swapping = false
		return
	var gap := wren.ground_pos.distance_to(_lantern)
	if not swapping:
		if gap <= SWAP_REACH and (wren.mind == Person.Mind.WHISPERED or attempting):
			whispered = whispered or wren.mind == Person.Mind.WHISPERED
			swapping = true
			swap_left = SWAP_SECONDS
			wren.go_duty(_lantern)
		return
	if gap > SWAP_HOLD or wren.mind != Person.Mind.DUTY:
		swapping = false
		return
	if wren.anchor.distance_to(_lantern) > 0.3:
		wren.go_duty(_lantern)
	swap_left -= delta
	if swap_left <= 0.0:
		_swap()


## The real flame leaves the lantern: Wren has it, and a false one burns in its place. A Faithful who saw it (Silent
## Doom's witness rule, the bearer aside) runs to the Temple. Phase 2 begins either way.
func _swap() -> void:
	swapping = false
	swapped = true
	var seer := faithful_seeing(wren.ground_pos, Crowd.DOOM_WITNESS, vigil.bearer if vigil != null else null)
	if seer != null:
		swap_seen = true
		_report(seer, temple_door)
	rules.banner.emit("THE FLAME IS TAKEN")
	wren.pace *= WREN_PACE
	wren.go_duty(shrine)
	_tick = TICK
	_phase2_begin()


## Wren's errand, looked at every TICK: to watch the lantern, to try for it himself, or to carry the flame to Mira's
## shrine. A whisper is the god's: he is left to it, and picks his errand up again once back on his feet.
func _wren_step(delta: float) -> void:
	if not appeared or not _alive(wren) or home:
		return
	if wren.mind == Person.Mind.WHISPERED:
		whispered = true
	if swapped and not wren.inside and wren.ground_pos.distance_to(shrine) <= SHRINE_REACH:
		_flame_home()
		return
	if not swapped and not whispered and not attempting and timeline.elapsed() - _appeared_at >= WREN_OWN_AFTER:
		attempting = true
		_tick = 0.0
		rules.banner.emit("THE BOY TRIES FOR THE LANTERN")
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	if swapping or wren.inside or not (wren.mind == Person.Mind.DUTY or wren.mind in RESUMABLE):
		return
	var goal := _wren_goal()
	if wren.mind != Person.Mind.DUTY or wren.anchor.distance_to(goal) > 0.3:
		wren.go_duty(goal)


## Where Wren is making for: Mira's shrine with the flame; else the lantern on his own try; else a place WATCH_DIST from
## the lantern on his side of it.
func _wren_goal() -> Vector2:
	if swapped:
		return shrine
	if _lantern == Vector2.INF:
		return wren.ground_pos
	if attempting:
		return _lantern
	var away := wren.ground_pos - _lantern
	var dir := away.normalized() if away.length() > 0.01 else Vector2.DOWN
	return _walkable(_lantern + dir * WATCH_DIST)


## The flame reaches Mira's shrine: it relights with the god's own flame (the win), and the light dies.
func _flame_home() -> void:
	home = true
	rules.banner.emit("MIRA'S SHRINE BURNS AGAIN")
	if wren.mind == Person.Mind.DUTY:
		wren.leave_shelter(false)
	_phase2_end()


## Where the real flame is: with Wren once swapped; else in its lantern (with its bearer, or where the last bearer
## fell); Vector2.INF when it is nowhere (Wren dead with it, or no Vigil at all).
func flame_at() -> Vector2:
	if swapped:
		return wren.ground_pos if _alive(wren) else Vector2.INF
	return _lantern


## Wren is gone: dead once he came, or nobody could be him.
func wren_lost() -> bool:
	return no_wren or (appeared and not _alive(wren))


func marks() -> Array:
	var out := [[shrine, MARK_SHRINE]]
	if not swapped and _lantern != Vector2.INF:
		out.append([_lantern, MARK_FLAME])
	if appeared and _alive(wren) and not wren.inside:
		out.append([wren.ground_pos, MARK_WREN])
	return out


## The HUD's arrow: Wren, once he has come, until the flame is home.
func marker() -> Vector2:
	return wren.ground_pos if appeared and _alive(wren) and not home else Vector2.INF


func report() -> Dictionary:
	return {"swapped": swapped, "seen": swap_seen, "reports": reports_started, "home": home, "touches": touches}


func teardown() -> void:
	_unhook_kills(_on_killed)
	if is_instance_valid(rules) and rules.cast_made.is_connected(_on_cast):
		rules.cast_made.disconnect(_on_cast)
	_phase2_end()
	if is_instance_valid(_fx):
		_fx.end_now()
	_fx = null
	if ctx != null and ctx.impact != null:
		ctx.impact.dim(0.0, 4.0)
	vigil = null
	timeline = null


func _listen() -> void:
	rules.cast_made.connect(_on_cast)


## The strip's search: in the clock's last Searchlight.SEARCH_LAST seconds, while the light is awake.
func _add_events() -> void:
	timeline.add(maxf(rules.time_left - Searchlight.SEARCH_LAST, 0.0), "search", "The light searches", Callable(),
		func() -> bool: return searchlight.on)


## The real flame leaves the lantern: the spire flares and the Searchlight wakes, one beam.
func _phase2_begin() -> void:
	searchlight.light()
	rules.banner.emit("THE SPIRE FLARES")
	_show_light()


func _phase2_step(delta: float) -> void:
	if not searchlight.on:
		return
	var had := searchlight.beams()
	searchlight.step(delta, rules.time_left)
	if searchlight.beams() > had:
		rules.banner.emit("A SECOND BEAM")
	if benching:
		return
	_touch()
	_pray(delta)


## A noise at `at` (any cast but a whisper, any death): where a searching beam stops in the clock's last seconds.
func _noise(at: Vector2) -> void:
	searchlight.hear(at)


## The light put out (the flame home, or the director let go): the beams die, the Faithful at prayer get up, and the
## drawing fades the dim away (SearchlightFx).
func _phase2_end() -> void:
	searchlight.put_out()
	for k: Variant in praying.keys():
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	praying.clear()
	_in_light = false


## A cast the light hears (Rules.cast_made): a noise, unless UNHEARD; a Will-o'-Wisp a decoy too.
func _on_cast(_slot: int, key: String, at: Vector2) -> void:
	if key in UNHEARD:
		return
	_noise(at)
	if key == "wisp":
		searchlight.lure(at)


## The Searchlight drawn, when the director has the battlefield's effects (never in tests).
func _show_light() -> void:
	if ctx != null and ctx.overhead != null and not is_instance_valid(_fx):
		_fx = FxTimeline.cast(SearchlightFx, ctx, searchlight.spire, {"light": searchlight}) as SearchlightFx


## A beam coming onto Wren adds TOUCH_GAZE, once each time he comes into the light.
func _touch() -> void:
	var lit := _alive(wren) and not wren.inside and searchlight.touches(wren.ground_pos)
	if lit and not _in_light:
		touches += 1
		gaze.add(TOUCH_GAZE)
		rules.banner.emit("THE LIGHT FINDS THE BOY")
	_in_light = lit


## The Faithful a beam touches stop and pray where they stand for PRAY_SECONDS; at prayer they feed the Gaze. The Vigil's
## walkers, report carriers and anyone held, frightened or busy elsewhere do not stop.
func _pray(delta: float) -> void:
	var walking: Array[Person] = vigil.walkers() if vigil != null else ([] as Array[Person])
	for f in faithful:
		if praying.has(f) or not _alive(f) or f.inside or f.mind in BLIND or walking.has(f) or _carrying(f):
			continue
		if not (f.mind in RESUMABLE or f.mind == Person.Mind.DUTY):
			continue
		if searchlight.touches(f.ground_pos):
			praying[f] = [PRAY_SECONDS, f.ground_pos]
			f.go_duty(f.ground_pos)
	for k: Variant in praying.keys():
		var e: Array = praying[k]
		e[0] = float(e[0]) - delta
		if _alive(k) and float(e[0]) > 0.0:
			continue
		praying.erase(k)
		if _alive(k) and (k as Person).mind == Person.Mind.DUTY:
			(k as Person).leave_shelter(false)
	gaze.pray(praying_count(), delta * PRAYER_SCALE)


## The Faithful at prayer now: alive and out, on their duty within PRAY_REACH of where they knelt.
func praying_count() -> int:
	var n := 0
	for k: Variant in praying.keys():
		if not _alive(k):
			continue
		var p := k as Person
		var spot: Vector2 = praying[k][1]
		if not p.inside and p.mind == Person.Mind.DUTY and p.ground_pos.distance_to(spot) <= PRAY_REACH:
			n += 1
	return n


## The bench and the photograph (v0.10 M4, spec §7): the Searchlight lit at once with both beams, sweeping with no
## quarry. Nothing it touches counts and no Faithful prays, so the night runs on.
func bench_beams() -> void:
	benching = true
	searchlight.light(Searchlight.SECOND_AFTER)
	_show_light()


## The Vigil Flame's Gaze: a seen death adds SEEN_DEATH_SCALE of GazeMeter.SEEN_DEATH; all else is GazeMeter's.
class FlameGaze extends GazeMeter:
	func seen_death() -> void:
		add(GazeMeter.SEEN_DEATH * SEEN_DEATH_SCALE)
