class_name ChamberSound
extends Node
## The God's Chamber's own sound (step 7, design section 9): a quiet room loop on the Ambience bus while the room is shown -- the
## brazier's crackle over a soft room tone -- fading in with the room and out when a page opens; now and then, one every GAP seconds,
## a room sound panned to where it happens (a candle sputters, a log settles in the brazier, wind against the window or, under the
## Hunt's red sky, a low moan, the hourglass's sand, a page, a quill, the lantern's chain), never the same kind or take twice in a row;
## and once, on entering, a soft chime when a cup gleams for the first time and a low swell when the Hunt is due.
##
## Its numbers come from its own RandomNumberGenerator, never the game's, so it cannot touch a night. Off (no node) in FLOW, --capture
## and headless runs: Game sets `enabled` as it sets GodChamber.transitions.

static var enabled := true
## Tests only: make the node even headless, so the bed's start and stop can be checked.
static var force := false
## State sounds already heard this session (who + what -> true): each is heard once.
static var heard := {}

const BED := &"chamber_bed"
const CHIME := &"chamber_chime"
const SWELL := &"chamber_swell"
## The occasional sounds, with how often each is picked (the wind and the moan are one slot: the moan under the Hunt's sky).
const KINDS := {&"chamber_sputter": 2.0, &"chamber_log": 2.0, &"chamber_wind": 2.0, &"chamber_moan": 2.0, &"chamber_sand": 1.0,
	&"chamber_page": 1.5, &"chamber_quill": 1.0, &"chamber_chain": 1.0}
const CUES := [&"chamber_bed", &"chamber_chime", &"chamber_swell", &"chamber_sputter", &"chamber_log", &"chamber_wind", &"chamber_moan",
	&"chamber_sand", &"chamber_page", &"chamber_quill", &"chamber_chain"]
## Seconds between occasional sounds, and before the first; at most MAX_PER_MINUTE in any minute (the calm-minute probe).
const GAP := Vector2(10.0, 20.0)
const FIRST := Vector2(4.0, 9.0)
const MAX_PER_MINUTE := 6
## Where each sound happens (room x): the pan follows it, PAN_WIDTH at the frame's edges.
const WHERE := {&"chamber_log": 600.0, &"chamber_wind": 318.0, &"chamber_moan": 318.0, &"chamber_sand": 620.0, &"chamber_page": 300.0,
	&"chamber_quill": 150.0, &"chamber_chain": 315.0}
const CANDLE_X := [559.0, 568.0, 578.0, 624.0, 634.0]
const PAN_WIDTH := 0.8
## A log settles louder while the brazier burns high.
const HIGH_DB := 3.0
## Seconds the bed takes to fade in with the room and out as a page opens; when the state sounds come after entering.
const FADE_IN := 1.5
const FADE_OUT := 0.35
const STATE_AT := 0.8
const BUS := &"Ambience"
const POOL := 3

var _st := {}
var _rng := RandomNumberGenerator.new()
var _clock := 0.0
var _next := 0.0
var _last_kind := &""
var _last_take := {}
var _pending: Array = []  ## state sounds still to come: [cue, pan]
var _gain := 0.0
var _target := 1.0
var _bed: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer2D] = []
var _turn := 0


## `st` is ChamberLife.state(); `seed` < 0 picks one at random (in play); `who` names the god for the state sounds' once-only memory.
func setup(st: Dictionary, seed := -1, who := "", night := 0) -> ChamberSound:
	_st = st
	if seed >= 0:
		_rng.seed = seed
	else:
		_rng.randomize()
	_next = _rng.randf_range(FIRST.x, FIRST.y)
	var cups: Array = st.get("cups", [])
	for i in cups.size():
		if cups[i] and _first("%s:cup%d" % [who, i]):
			_pending.append([CHIME, _pan(505.0 + 32.0 * i)])
			break  # one chime, however many cups gleam for the first time
	if st.get("hunt", false) and _first("%s:hunt%d" % [who, night]):
		_pending.append([SWELL, _pan(318.0)])
	return self


static func _first(key: String) -> bool:
	if heard.has(key):
		return false
	heard[key] = true
	return true


## Where the bed is heading: 1 with the room, 0 once a page opens.
func bed_target() -> float:
	return _target


## A page is opening: the bed fades out with the zoom.
func leave() -> void:
	_target = 0.0


## One step of the room's clock: the sounds due in it, as {"cue", "path", "pan", "db"} (pure: nothing plays here).
func step(delta: float) -> Array:
	var out: Array = []
	var was := _clock
	_clock += delta
	if was < STATE_AT and _clock >= STATE_AT:
		for p: Array in _pending:
			out.append(_event(p[0], p[1], 0.0))
		_pending.clear()
	_next -= delta
	if _next <= 0.0:
		_next = _rng.randf_range(GAP.x, GAP.y)
		var kind := _pick_kind()
		if kind != &"":
			var x: float = WHERE.get(kind, 320.0)
			if kind == &"chamber_sputter":
				x = CANDLE_X[_rng.randi() % clampi(int(_st.get("lit", 1)), 1, CANDLE_X.size())]
			out.append(_event(kind, _pan(x), HIGH_DB if kind == &"chamber_log" and _st.get("high", false) else 0.0))
	return out


## The occasional sounds a calm minute from now would play (the probe; it moves this plan's clock on by 60 s).
func calm_minute() -> Array:
	var out: Array = []
	for i in 3600:
		for e: Dictionary in step(1.0 / 60.0):
			if KINDS.has(e.cue):
				out.append(e)
	return out


## The kinds that can sound now: the wind or, under the Hunt's sky, the moan; the sand only while it runs; never the last kind.
func _choices() -> Dictionary:
	var out := {}
	var hunt: bool = _st.get("hunt", false)
	var sand: float = _st.get("sand", 0.0)
	for kind: StringName in KINDS:
		if kind == _last_kind:
			continue
		if kind == &"chamber_wind" and hunt or kind == &"chamber_moan" and not hunt:
			continue
		if kind == &"chamber_sand" and (sand <= 0.0 or sand >= 1.0):
			continue
		var w: float = KINDS[kind]
		if kind == &"chamber_log" and _st.get("high", false):
			w *= 1.5
		out[kind] = w
	return out


func _pick_kind() -> StringName:
	var choices := _choices()
	var total := 0.0
	for w: float in choices.values():
		total += w
	var r := _rng.randf() * total
	for kind: StringName in choices:
		r -= float(choices[kind])
		if r <= 0.0:
			_last_kind = kind
			return kind
	return &""


func _event(cue: StringName, pan: float, db: float) -> Dictionary:
	var paths := Sfx.paths_for(cue)
	var i := 0
	if paths.size() > 1:
		var last := int(_last_take.get(cue, -1))
		i = _rng.randi() % (paths.size() - (1 if last >= 0 else 0))
		if last >= 0 and i >= last:
			i += 1
	_last_take[cue] = i
	return {"cue": cue, "path": paths[i], "pan": pan, "db": float(Sfx.CATALOG[cue].get("db", 0.0)) + db}


static func _pan(room_x: float) -> float:
	return clampf((room_x - 320.0) / 320.0, -1.0, 1.0) * PAN_WIDTH


func _ready() -> void:
	_bed = AudioStreamPlayer.new()
	_bed.bus = BUS
	_bed.stream = Sfx.load_stream(BED)
	_bed.volume_db = -80.0
	add_child(_bed)
	for i in POOL:
		var p := AudioStreamPlayer2D.new()
		p.bus = BUS
		p.max_distance = 100000.0
		p.attenuation = 0.0
		add_child(p)
		_pool.append(p)
	if _bed.stream != null:
		_bed.play(_rng.randf() * _bed.stream.get_length())


func _process(delta: float) -> void:
	_gain = move_toward(_gain, _target, delta / (FADE_IN if _target > _gain else FADE_OUT))
	if _bed != null:
		_bed.volume_db = float(Sfx.CATALOG[BED].get("db", 0.0)) + linear_to_db(maxf(_gain, 0.0001))
	if _target <= 0.0:
		return
	for e: Dictionary in step(delta):
		_play(e)


func _play(e: Dictionary) -> void:
	var p := _pool[_turn % _pool.size()]
	_turn += 1
	p.stop()
	p.stream = load(e.path)
	p.volume_db = e.db
	var view := get_viewport().get_visible_rect()
	p.global_position = view.get_center() + Vector2(float(e.pan) * view.size.x * 0.5, 0.0)
	p.play()


func _exit_tree() -> void:
	if _bed != null:
		_bed.stop()
	for p in _pool:
		p.stop()
