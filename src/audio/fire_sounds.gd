class_name FireSounds
extends Node
## Fire where it burns (natural sound pass 6). Ambience owns and steps it. The VOICES burning buildings nearest the
## screen's centre (within REACH, a share of its centre-to-corner) each get a crackling loop (fire_burn) at the building,
## from QUIET_DB when the fire has just caught up to full as it grows. A building that catches near the camera whumps
## (fire_catch), a big fire's timbers crack now and then (fire_crack), and a bucket thrown on a fire hisses
## (fire_douse) -- seen as its intensity dropping by DOUSE_DROP or more, or the fire going out with its building still
## standing. The town-wide fire bed (amb_fire) stays under it all, far off. It only reads FireManager and changes
## nothing, so behaviour is the same with or without it.

const VOICES := 4
const TICK := 0.4
const REACH := 1.3
const CATCH_REACH := 1.0
## A fire just caught, against one at full intensity.
const QUIET_DB := -14.0
## How fast a voice fades in or out (linear gain a second).
const EASE := 2.0
const CRACK_GAP := Vector2(2.0, 5.0)
const CRACK_FROM := 0.5
const DOUSE_DROP := 0.1

var _crowd: Crowd
var _voices: Array[AudioStreamPlayer2D] = []
var _on: Array = []  ## per voice: the Structure it follows, or null
var _gain: Array[float] = []
var _want: Array[float] = []
var _db: Array[float] = []
var _last := {}  ## structure instance id -> its fire's intensity at the last tick
var _tick := 0.0
var _next_crack := 3.0
var _rng := RandomNumberGenerator.new()


func setup(crowd: Crowd) -> FireSounds:
	_crowd = crowd
	name = "FireSounds"
	_rng.randomize()
	for i in VOICES:
		var p := AudioStreamPlayer2D.new()
		p.bus = Sfx.BUS
		p.max_distance = Sfx.MAX_DISTANCE
		p.attenuation = 1.0
		p.stream = Sfx.load_stream(&"fire_burn", _rng)
		add_child(p)
		_voices.append(p)
		_on.append(null)
		_gain.append(0.0)
		_want.append(0.0)
		_db.append(QUIET_DB)
	return self


## A burning building's loop level for its fire's intensity (0..1), with the catalog's level.
static func voice_db(intensity: float) -> float:
	return lerpf(QUIET_DB, 0.0, clampf(intensity, 0.0, 1.0)) + float(Sfx.CATALOG[&"fire_burn"].get("db", 0.0))


## Whether a fire whose intensity went from `before` to `now` in one tick was doused.
static func doused(before: float, now: float) -> bool:
	return before - now >= DOUSE_DROP


func step(delta: float) -> void:
	var fm: FireManager = _crowd.fires if _crowd != null else null
	_tick -= delta
	if _tick <= 0.0:
		_tick = TICK
		_assign(fm)
	for i in VOICES:
		_gain[i] = move_toward(_gain[i], _want[i], EASE * delta)
		var p := _voices[i]
		if _gain[i] <= 0.001:
			if p.playing:
				p.stop()
			if _want[i] <= 0.0:
				_on[i] = null
			continue
		p.volume_db = _db[i] + linear_to_db(_gain[i])
		if not p.playing:
			p.play(_rng.randf() * p.stream.get_length())
	_crack(delta, fm)


func stop() -> void:
	for i in VOICES:
		_voices[i].stop()
		_gain[i] = 0.0
		_want[i] = 0.0
		_on[i] = null


func pause(paused: bool) -> void:
	for p in _voices:
		p.stream_paused = paused


func _assign(fm: FireManager) -> void:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	var sfx: Node = _crowd.sfx if _crowd != null else null
	if fm == null or cam == null or sfx == null:
		for i in VOICES:
			_want[i] = 0.0
		return
	var centre := cam.get_screen_center_position()
	var reach := maxf((get_viewport().get_visible_rect().size * 0.5 / cam.zoom).length(), 1.0)
	var now := {}
	var near: Array = []  # [screen distance, structure, intensity]
	for k: Variant in fm.fires.keys():
		if not is_instance_valid(k):
			continue
		var s := k as Structure
		if s == null or s.destroyed:
			continue
		var it := fm.intensity(s)
		var id := s.get_instance_id()
		now[id] = it
		var d := (Iso.ground_to_screen(s.center()) - centre).length() / reach
		if not _last.has(id):
			if d < CATCH_REACH:
				sfx.play(&"fire_catch", s.center())
		elif doused(float(_last[id]), it) and d < REACH:
			sfx.play(&"fire_douse", s.center())
		if d < REACH:
			near.append([d, s, it])
	# Out with its building still standing: the water won.
	for id in _last:
		if not now.has(id):
			var o := instance_from_id(id) as Structure
			if o != null and is_instance_valid(o) and not o.destroyed:
				var d := (Iso.ground_to_screen(o.center()) - centre).length() / reach
				if d < REACH:
					sfx.play(&"fire_douse", o.center())
	_last = now
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var chosen := {}
	for k in mini(VOICES, near.size()):
		chosen[near[k][1]] = float(near[k][2])
	for i in VOICES:
		var s: Variant = _on[i]
		if s != null and is_instance_valid(s) and chosen.has(s):
			_want[i] = 1.0
			_db[i] = voice_db(chosen[s])
			chosen.erase(s)
		else:
			_want[i] = 0.0
	for s: Structure in chosen:
		for i in VOICES:
			if _on[i] == null and _gain[i] <= 0.001:
				_on[i] = s
				_want[i] = 1.0
				_db[i] = voice_db(chosen[s])
				_voices[i].position = Iso.ground_to_screen(s.center())
				_voices[i].bus = sfx.bus_for(_voices[i].position)
				break


## Now and then a big fire's timbers crack.
func _crack(delta: float, fm: FireManager) -> void:
	_next_crack -= delta
	if _next_crack > 0.0:
		return
	_next_crack = _rng.randf_range(CRACK_GAP.x, CRACK_GAP.y)
	if fm == null or _crowd.sfx == null:
		return
	var big: Array = []
	for i in VOICES:
		var s: Variant = _on[i]
		if s != null and is_instance_valid(s) and _want[i] > 0.0 and fm.intensity(s) >= CRACK_FROM:
			big.append(s)
	if not big.is_empty():
		var s: Structure = big[_rng.randi() % big.size()]
		_crowd.sfx.play(&"fire_crack", s.center())
