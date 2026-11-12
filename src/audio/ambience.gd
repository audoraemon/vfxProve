class_name Ambience
extends Node
## The town's own sound between the events (natural sound pass 2): a looped bed for the time of day -- by day the town at
## a distance, birds and a breeze; by night crickets, wind and the town far off -- a fire bed that swells with how much
## of the town is burning, and now and then a call somewhere near the camera, a bird by day, by night a call or a
## creaking tree. Without it every sound starts from silence and sounds pasted on.
##
## The crowd in a panic is three beds too (pass 3): an uneasy murmur once the first people run, then running and
## yelling, then the whole town in chaos, each a long loop with no voice in it that stands out -- and on top of them
## single cries, a scream or a man's yell from a running citizen near the camera, more often the more the town panics,
## each heard at its own distance and side. Before, one short loop with the same screams in it played every few seconds.
## Pass 4 made the beds full range and drier, with the feet of the running crowd under them for weight.
## Pass 5 added the soldiers' march (_march()); their blows and orders are SoldierVoices, the animals AnimalVoices.
## Pass 6 lets a dog or cat near the camera call now and then (_animal_call()), by day and by night, and places fire
## where it burns (FireSounds): the town-wide fire bed is now the far-off part of it.
## The town's children (Children) are heard too: a frightened child's cry is its own (cry_cue()), and by day one at play
## near the camera laughs or shrieks now and then (_child_call()).
##
## It only listens: it reads the town's look (TownLook.active), the fires (Crowd.fires), who is running (Crowd.citizens)
## and how much the town panics (Crowd.panic_level()), and never touches the world; its numbers come from its own rng.
## Crowd makes it when the mission's sound starts, and pauses and stops it. The beds play on the Ambience bus, which
## feeds SFX, so the Sounds slider rules them too.

const BUS := &"Ambience"
## Gain a second the beds ease by, so a change of look or a fire dying swells or fades instead of jumping.
const EASE := 0.35
## The crowd's beds follow the panic faster: it already eases (Crowd.BED_EASE), and a stampede must be heard at once.
const CROWD_EASE := 1.5
## How far the time-of-day bed dips while the town panics: the panic bed takes over.
const PANIC_DIP := 0.6
## Summed fire intensity at which the fire bed is full (Crowd.fires: 1 is one building fully ablaze).
const FIRE_FULL := 3.0
## Panic level at which each crowd bed comes in and is full: the murmur first, the running crowd next, chaos last.
## The murmur thins as chaos takes over, by up to UNREST_DIP.
const UNREST_IN := Vector2(0.0, 0.3)
const PANIC_IN := Vector2(0.15, 0.65)
const CHAOS_IN := Vector2(0.55, 1.0)
const UNREST_DIP := 0.5
## Seconds between cries from the running crowd: CRY_SLOW when the panic has just begun (at CRY_FROM), CRY_FAST when
## the whole town runs; each gap varies by CRY_SPREAD either way. A cry comes from the nearest of CRY_PICKS running
## people drawn at random, so most are near the camera and some further off.
const CRY_FROM := 0.08
const CRY_SLOW := 2.6
const CRY_FAST := 0.35
const CRY_SPREAD := 0.4
const CRY_PICKS := 5
## Seconds between calls, by day and by night; none while the town panics past CALL_QUIET.
const DAY_CALLS := Vector2(5.0, 14.0)
const NIGHT_CALLS := Vector2(8.0, 20.0)
const CALL_QUIET := 0.35
## How far from the screen's centre a call can be, in screen pixels at zoom 1.
const CALL_SPREAD := Vector2(300.0, 170.0)
## The soldiers' march (natural sound pass 5): every MARCH_EVERY seconds one of the MARCH_PICKS soldiers nearest the
## screen's centre takes a step, in turn, so their feet fall one after another. Only those that walk at MARCH_SPEED
## (ground units a second) or more and stand within MARCH_REACH of the screen (a share of its centre-to-corner) count:
## a soldier at its post is silent. A calm town's patrols are silent too (march_heard()): the march is heard once the
## alarm has risen, when the soldiers move with purpose -- a patrol's steady tread was a clatter under every quiet day.
const MARCH_EVERY := 0.3
const MARCH_PICKS := 2
const MARCH_SPEED := 0.25
const MARCH_REACH := 0.9
## The town's dogs and cats (natural sound pass 6): every ANIMAL_DAY (by night ANIMAL_NIGHT) seconds one of the
## ANIMAL_PICKS animals nearest the screen's centre, at random, barks or meows (AnimalVoices.Act.CALL), if it is within
## ANIMAL_REACH of the screen (a share of its centre-to-corner; a little past the edge is heard far off, muffled). None
## while the town panics past CALL_QUIET: the animals have their own cries then.
const ANIMAL_DAY := Vector2(6.0, 15.0)
const ANIMAL_NIGHT := Vector2(8.0, 18.0)
const ANIMAL_PICKS := 3
const ANIMAL_REACH := 1.3
## The children at play (Children): by day only, every CHILD_EVERY seconds one of the CHILD_PICKS children at play nearest
## the screen's centre, at random, laughs or shrieks (child_play), if it is within CHILD_REACH of the screen. None while
## the town panics past CALL_QUIET.
const CHILD_EVERY := Vector2(7.0, 16.0)
const CHILD_PICKS := 3
const CHILD_REACH := 1.3

var _crowd: Crowd
var _players := {}
var _gain := {"amb_day": 0.0, "amb_night": 0.0, "amb_fire": 0.0, "crowd_unrest": 0.0, "crowd_panic": 0.0, "crowd_chaos": 0.0}
var _rng := RandomNumberGenerator.new()
var _next_call := 3.0
var _next_cry := 0.0
var _next_march := 0.0
var _march_turn := 0
var _next_animal := 4.0
var _next_child := 6.0
var _last_at := {}  ## soldier instance id -> ground position at the last march tick
var _stopped := false
## Fire where it burns (pass 6): the nearest burning buildings' own crackle, catching, cracking and dousing.
var _fire: FireSounds


func setup(crowd: Crowd) -> Ambience:
	_crowd = crowd
	_rng.randomize()
	for cue: StringName in _gain:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		p.stream = Sfx.load_stream(cue)
		p.volume_db = -80.0
		add_child(p)
		_players[cue] = p
	_fire = FireSounds.new().setup(crowd)
	add_child(_fire)
	return self


## What each bed is heading for: the time of day's bed (dipped under panic), the fire bed, and the crowd's three.
static func targets(night: bool, panic: float, fire: float) -> Dictionary:
	panic = clampf(panic, 0.0, 1.0)
	var calm := 1.0 - PANIC_DIP * panic
	var chaos := smoothstep(CHAOS_IN.x, CHAOS_IN.y, panic)
	return {"amb_day": 0.0 if night else calm, "amb_night": calm if night else 0.0,
		"amb_fire": clampf(fire / FIRE_FULL, 0.0, 1.0),
		"crowd_unrest": smoothstep(UNREST_IN.x, UNREST_IN.y, panic) * (1.0 - UNREST_DIP * chaos),
		"crowd_panic": smoothstep(PANIC_IN.x, PANIC_IN.y, panic), "crowd_chaos": chaos}


## The cry of a running person: a child's own, or a grown-up's.
static func cry_cue(child: bool) -> StringName:
	return &"child_cry" if child else &"crowd_cry"


## Whether `p` is one of the town's children at play: alive, calm and out of doors where it can be seen.
static func at_play(p: Person) -> bool:
	return is_instance_valid(p) and p.is_alive() and p.is_child() and p.mind == Person.Mind.CALM and not p.inside and p.visible


## Seconds until the next cry at this panic level, before its random spread; none (INF) below CRY_FROM.
static func cry_gap(panic: float) -> float:
	if panic < CRY_FROM:
		return INF
	return lerpf(CRY_SLOW, CRY_FAST, inverse_lerp(CRY_FROM, 1.0, minf(panic, 1.0)))


func pause(paused: bool) -> void:
	for p: AudioStreamPlayer in _players.values():
		p.stream_paused = paused
	if _fire != null:
		_fire.pause(paused)


## Silence for good (the mission is quitting): nothing restarts it.
func stop() -> void:
	_stopped = true
	for p: AudioStreamPlayer in _players.values():
		p.stop()
	if _fire != null:
		_fire.stop()


func _process(delta: float) -> void:
	if _stopped or _crowd == null:
		return
	var night: bool = TownLook.active == Town.Look.NIGHT
	var fire := 0.0
	if _crowd.fires != null:
		for f: Dictionary in _crowd.fires.fires.values():
			fire += float(f.get("intensity", 0.0))
	var want := targets(night, _crowd.panic_level(), fire)
	for cue: StringName in _gain:
		_gain[cue] = move_toward(_gain[cue], want[cue], (CROWD_EASE if String(cue).begins_with("crowd_") else EASE) * delta)
		var p: AudioStreamPlayer = _players[cue]
		if _gain[cue] <= 0.001:
			if p.playing:
				p.stop()
			continue
		if not p.playing and not p.stream_paused:
			# Start somewhere in the loop, so a fresh mission does not always open on the same second of it.
			p.play(_rng.randf() * p.stream.get_length())
		p.volume_db = float(Sfx.CATALOG[cue].get("db", 0.0)) + linear_to_db(_gain[cue])
	_cries(delta, _crowd.panic_level())
	_march(delta)
	if _fire != null:
		_fire.step(delta)
	_animal_call(delta, night)
	_child_call(delta, night)
	_next_call -= delta
	if _next_call <= 0.0:
		var span := NIGHT_CALLS if night else DAY_CALLS
		_next_call = _rng.randf_range(span.x, span.y)
		if _crowd.panic_level() < CALL_QUIET and _crowd.sfx != null:
			_call(&"amb_night_call" if night else &"amb_bird")


## Now and then one of the running people cries out, more often the more the town panics.
func _cries(delta: float, panic: float) -> void:
	var gap := cry_gap(panic)
	if gap == INF or _crowd.sfx == null:
		_next_cry = 0.0
		return
	_next_cry -= delta
	if _next_cry > 0.0:
		return
	_next_cry = gap * _rng.randf_range(1.0 - CRY_SPREAD, 1.0 + CRY_SPREAD)
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var centre := Iso.screen_to_ground(cam.get_screen_center_position())
	var running: Array[Person] = []
	for p in _crowd.citizens:
		if is_instance_valid(p) and p.is_alive() and (p.mind == Person.Mind.PANIC or p.mind == Person.Mind.FLEE):
			running.append(p)
	if running.is_empty():
		return
	var who: Person = null
	for i in CRY_PICKS:
		var p: Person = running[_rng.randi() % running.size()]
		if who == null or p.ground_pos.distance_squared_to(centre) < who.ground_pos.distance_squared_to(centre):
			who = p
	_crowd.sfx.play(cry_cue(who.is_child()), who.ground_pos)


## By day, now and then a child at play near the camera laughs or shrieks.
func _child_call(delta: float, night: bool) -> void:
	_next_child -= delta
	if _next_child > 0.0:
		return
	_next_child = _rng.randf_range(CHILD_EVERY.x, CHILD_EVERY.y)
	if night or _crowd.sfx == null or _crowd.panic_level() >= CALL_QUIET:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var centre := cam.get_screen_center_position()
	var reach := maxf((get_viewport().get_visible_rect().size * 0.5 / cam.zoom).length(), 1.0)
	var near: Array = []  # [screen distance, child]
	for p in _crowd.citizens:
		if not at_play(p):
			continue
		var d := (Iso.ground_to_screen(p.ground_pos) - centre).length() / reach
		if d < CHILD_REACH:
			near.append([d, p])
	if near.is_empty():
		return
	near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var who: Person = near[_rng.randi() % mini(CHILD_PICKS, near.size())][1]
	_crowd.sfx.play(&"child_play", who.ground_pos)


## Now and then a dog barks or a cat meows near the camera.
func _animal_call(delta: float, night: bool) -> void:
	_next_animal -= delta
	if _next_animal > 0.0:
		return
	var span := ANIMAL_NIGHT if night else ANIMAL_DAY
	_next_animal = _rng.randf_range(span.x, span.y)
	if _crowd.sfx == null or _crowd.animals == null or _crowd.panic_level() >= CALL_QUIET:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var pool := _crowd.animals.living()
	if pool.is_empty():
		return
	var centre := cam.get_screen_center_position()
	var reach := maxf((get_viewport().get_visible_rect().size * 0.5 / cam.zoom).length(), 1.0)
	var near: Array = []  # [screen distance, animal]
	for a in pool:
		var d := (Iso.ground_to_screen(a.ground_pos) - centre).length() / reach
		if d < ANIMAL_REACH and not a.hypnotized():
			near.append([d, a])
	if near.is_empty():
		return
	near.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	var who: Animal = near[_rng.randi() % mini(ANIMAL_PICKS, near.size())][1]
	_crowd.animals.voices.say(_crowd.sfx, who, AnimalVoices.Act.CALL)


## Whether the soldiers' march is heard at all at this alarm stage: not in a calm town.
static func march_heard(stage: AlarmManager.Stage) -> bool:
	return stage != AlarmManager.Stage.NORMAL


## Whether a soldier that moved `moved` ground units in `seconds` is marching.
static func marching(moved: float, seconds: float) -> bool:
	return seconds > 0.0 and moved / seconds >= MARCH_SPEED


## The nearest marching soldiers to the screen's centre take a step in mail.
func _march(delta: float) -> void:
	_next_march -= delta
	if _next_march > 0.0 or _crowd.sfx == null:
		return
	if not march_heard(_crowd.alarms.stage):
		_last_at.clear()
		return
	_next_march = MARCH_EVERY
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var centre := cam.get_screen_center_position()
	var reach := maxf((get_viewport().get_visible_rect().size * 0.5 / cam.zoom).length(), 1.0)
	var near: Array = []  # [screen distance, soldier]
	var seen := {}
	for p in _crowd.soldiers:
		if not is_instance_valid(p) or not p.is_alive() or p.inside:
			continue
		var id := p.get_instance_id()
		seen[id] = true
		var moved := p.ground_pos.distance_to(_last_at.get(id, p.ground_pos))
		_last_at[id] = p.ground_pos
		var d := (Iso.ground_to_screen(p.ground_pos) - centre).length() / reach
		if marching(moved, MARCH_EVERY) and d < MARCH_REACH:
			near.append([d, p])
	for id in _last_at.keys():
		if not seen.has(id):
			_last_at.erase(id)
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	if near.is_empty():
		return
	_march_turn += 1
	_crowd.sfx.play(&"sol_step", near[_march_turn % mini(MARCH_PICKS, near.size())][1].ground_pos)


## A call somewhere near the camera, so it is heard at its distance and side.
func _call(cue: StringName) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var off := Vector2(_rng.randf_range(-1.0, 1.0) * CALL_SPREAD.x, _rng.randf_range(-1.0, 1.0) * CALL_SPREAD.y) / cam.zoom
	_crowd.sfx.play(cue, Iso.screen_to_ground(cam.get_screen_center_position() + off))
