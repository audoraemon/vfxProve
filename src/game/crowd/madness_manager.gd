class_name MadnessManager
extends RefCounted
## Madness Bloom's madness: a status (Person.statuses[STATUS], 0..1) laid on a few people by the cast, which grows on
## its own -- faster in a crowd of the maddened -- through four stages, Uneasy, Disturbed, Unstable and Broken, and
## passes to the people beside them (capped). What each stage asks of a person goes through the person's own generic
## actions (hesitate, confuse, stun, panic, fight); the person knows nothing of madness. Broken is drawn by weight:
## most turn on whoever is nearest (a frenzy, Person.fight()), some run, some wander, some freeze. A frenzy is a danger
## the town sees (Crowd.fright()), the alarm rises, and the nearest soldier at its post engages. After DURATION the
## madness ends. The crowd makes one (Crowd.spawn()) and steps it (Crowd.advance()).

const STATUS := &"madness"
## Stage floors: below the first is Uneasy; then Disturbed, Unstable, Broken.
const STAGES := [0.3, 0.65, 0.9]
enum Stage { UNEASY, DISTURBED, UNSTABLE, BROKEN }
const STAGE_NAMES := ["Uneasy", "Disturbed", "Unstable", "Broken"]
## Growth per second alone (8 s to Broken), and the bonus for each maddened neighbour within PROPAGATION_R, counted
## up to CROWD_CAP of them.
const GROWTH_RATE := 0.125
const CROWD_GROWTH_BONUS := 0.25
const CROWD_CAP := 4
## Spread: every PROPAGATE_EVERY, each of the Disturbed and worse gives it to each healthy neighbour within
## PROPAGATION_R with PROPAGATE_CHANCE, MAX_SECONDARY_TARGETS each in all, never past MAX_AFFLICTED at once.
const PROPAGATION_R := 1.2
const PROPAGATE_EVERY := 1.0
const PROPAGATE_CHANCE := 0.25
const MAX_SECONDARY_TARGETS := 2
const MAX_AFFLICTED := 40
## How long the madness runs from its start, Broken included; how long a frenzy lasts within it, and its blow.
const DURATION := 40.0
const FRENZY_DURATION := 15.0
const ATTACK_DAMAGE := 0.34
const TARGET_SELECTION_INTERVAL := Person.FIGHT_RETARGET
## Who may shrug it off, by what they are: the chance, times RESISTANCE_MULTIPLIER.
const RESISTANCE := {&"soldier": 0.8, &"clergy": 0.5, &"monk": 0.5, &"bellkeeper": 0.6, &"engineer": 0.5}
const RESISTANCE_MULTIPLIER := 1.0
## Alarm: what the cast is worth (PowerBook's "alarm"), and each one broken, times ALARM_MULTIPLIER.
const ALARM_BROKEN := 1.0
const ALARM_MULTIPLIER := 1.0
## Broken, by weight: frenzy, panic, erratic wandering, stunned.
const BROKEN_WEIGHTS := [0.55, 0.20, 0.15, 0.10]
enum Outcome { FRENZY, PANIC, ERRATIC, STUNNED }
const STUN_SECONDS := 6.0
const ERRATIC_SECONDS := 12.0
## Uneasy: a hesitation every so often. Disturbed: concern spread to those beside them every so often. Unstable: those
## within SHOVE_R shoved every SHOVE_EVERY.
const HESITATE_EVERY := Vector2(2.0, 4.0)
const CONCERN_EVERY := 3.0
const CONCERN_R := 1.5
const SHOVE_EVERY := 1.5
const SHOVE_R := 0.45
## A frenzy as the town sees it: the danger's radius, severity and seconds, how far it is seen and heard; and how far
## a soldier at its post comes to engage it.
const FRENZY_THREAT := [0.8, 0.5, 6.0, 4.0, 6.0]
const SOLDIER_ENGAGE_R := 5.0
const SOLDIER_FIGHT_SECONDS := 20.0
## How often the town is searched for the newly afflicted (the effect's).
const SCAN_EVERY := 0.1
## Looks: the colours of the stages, the tendrils under the Disturbed, the halo's cracks when one breaks.
const COL_STAGES: Array[Color] = [Color("4a2a5a"), Color("7a2a60"), Color("b02a4a"), Color("ff3838")]
const COL_TENDRIL := Color("5a1838")
const COL_EYE := Color("f0e8ff")
const COL_EDGE := Color(0.05, 0.02, 0.06)
const TENDRILS := 5
const HALO_SECONDS := 0.6
const WHISPER_MAX := 24

## The afflicted: Person -> {"stage", "since", "outcome", "broken_at", "secondary", "tic", "concern", "shove"}.
var afflicted := {}
## Debug: the last spreads, [from, to, until clock]; alarm this madness has raised; how many have broken.
var links: Array = []
var alarm_generated := 0.0
var broken := 0

var _crowd: Crowd
var _field: EnemyField
var _rng := RandomNumberGenerator.new()
var _fx_rng := RandomNumberGenerator.new()
var _clock := 0.0
var _scan_in := 0.0
var _propagate_in := PROPAGATE_EVERY
var _whispers: Array = []


func setup(crowd: Crowd, field: EnemyField, seed_value: int) -> MadnessManager:
	_crowd = crowd
	_field = field
	_rng.seed = seed_value
	_fx_rng.seed = seed_value + 1
	return self


## The stage of a madness value.
static func stage_of(value: float) -> Stage:
	for i in STAGES.size():
		if value < float(STAGES[i]):
			return i as Stage
	return Stage.BROKEN


## What `p` is, for resistance: a soldier, or its role.
static func kind_of(p: Person) -> StringName:
	return p.kind()


## Whether `p` shrugs it off, by its kind's chance; rolled on `rng`.
static func resists(p: Person, rng: RandomNumberGenerator) -> bool:
	var chance := float(RESISTANCE.get(kind_of(p), 0.0)) * RESISTANCE_MULTIPLIER
	return chance > 0.0 and rng.randf() < chance


## Lay the madness on `p` at `value` (the cast's seed, a spread), unless it resists or is already mad; true when it
## took. The manager takes it up on its next step.
func afflict(p: Person, value: float, rng: RandomNumberGenerator = null) -> bool:
	if not is_instance_valid(p) or not p.is_alive() or p.inside or p.statuses.has(STATUS):
		return false
	if afflicted.size() >= MAX_AFFLICTED:
		return false
	if resists(p, rng if rng != null else _rng):
		return false
	p.statuses[STATUS] = clampf(value, 0.001, 1.0)
	return true


func value_of(p: Person) -> float:
	return float(p.statuses.get(STATUS, 0.0))


func step(delta: float) -> void:
	_clock += delta
	_scan_in -= delta
	if _scan_in <= 0.0:
		_scan_in = SCAN_EVERY
		_collect()
	if afflicted.is_empty():
		return
	var gone: Array[Person] = []
	for p: Person in afflicted:
		var rec: Dictionary = afflicted[p]
		if not is_instance_valid(p) or not p.is_alive():
			gone.append(p)
			continue
		if _clock - float(rec.since) >= DURATION:
			_end(p)
			gone.append(p)
			continue
		if p.inside:
			continue  # under cover, the madness waits
		var v := value_of(p)
		if v < 1.0:
			var near := _maddened_near(p)
			v = minf(v + GROWTH_RATE * (1.0 + CROWD_GROWTH_BONUS * float(mini(near, CROWD_CAP))) * delta, 1.0)
			p.statuses[STATUS] = v
		var stage := stage_of(v)
		while int(rec.stage) < stage:
			rec.stage = int(rec.stage) + 1
			_enter(p, rec, rec.stage as Stage)
		_tick(p, rec, stage, delta)
	for p in gone:
		afflicted.erase(p)
	_propagate_in -= delta
	if _propagate_in <= 0.0:
		_propagate_in = PROPAGATE_EVERY
		_propagate()
	links = links.filter(func(l: Array) -> bool: return float(l[2]) > _clock)


## Take up anyone newly given the status (the effect's seeds).
func _collect() -> void:
	for p in _crowd.citizens + _crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.statuses.has(STATUS) and not afflicted.has(p):
			afflicted[p] = {"stage": -1, "since": _clock, "outcome": -1, "broken_at": -INF, "secondary": 0,
				"tic": _rng.randf_range(HESITATE_EVERY.x, HESITATE_EVERY.y), "concern": CONCERN_EVERY, "shove": SHOVE_EVERY}


func _maddened_near(p: Person) -> int:
	var n := 0
	for q: Person in afflicted:
		if q != p and is_instance_valid(q) and q.is_alive() and not q.inside \
				and q.ground_pos.distance_to(p.ground_pos) <= PROPAGATION_R:
			n += 1
	return n


## A stage entered.
func _enter(p: Person, rec: Dictionary, stage: Stage) -> void:
	match stage:
		Stage.DISTURBED:
			# Some drop what they were doing and wander.
			if not p.soldier and _rng.randf() < 0.5:
				p.confuse(ERRATIC_SECONDS, false)
		Stage.UNSTABLE:
			_crowd._voice(p, &"cit_shout")
			if not p.soldier and _rng.randf() < 0.3:
				p.panic(p.ground_pos + Vector2(0.1, 0.1), 0.3, STATUS)
		Stage.BROKEN:
			broken += 1
			rec.broken_at = _clock
			var outcome := _draw_outcome()
			rec.outcome = outcome
			match outcome:
				Outcome.FRENZY:
					p.fight(null, FRENZY_DURATION, ATTACK_DAMAGE)
					_outbreak(p)
				Outcome.PANIC:
					p.mind = Person.Mind.CALM
					p.panic(p.ground_pos + Vector2(0.1, -0.1), 0.3, STATUS)
				Outcome.ERRATIC:
					p.confuse(ERRATIC_SECONDS, false)
				Outcome.STUNNED:
					p.stun(STUN_SECONDS)
			_whisper(p, 10)


func _draw_outcome() -> Outcome:
	var roll := _rng.randf()
	for i in BROKEN_WEIGHTS.size():
		roll -= float(BROKEN_WEIGHTS[i])
		if roll < 0.0:
			return i as Outcome
	return Outcome.FRENZY


## A frenzy breaks out: the town sees a danger, the alarm rises, and the nearest soldier at its post comes for them.
func _outbreak(p: Person) -> void:
	var t: Array = FRENZY_THREAT
	_crowd.fright(p.ground_pos, float(t[0]), float(t[1]), float(t[2]), float(t[3]), float(t[4]), &"frenzy")
	var points := ALARM_BROKEN * ALARM_MULTIPLIER
	alarm_generated += points
	_crowd.add_alarm(points)
	var best: Person = null
	var best_d := SOLDIER_ENGAGE_R
	for s in _crowd.soldiers:
		if is_instance_valid(s) and s.is_alive() and s.mind == Person.Mind.POST and not s.hurrying \
				and s.ground_pos.distance_to(p.ground_pos) < best_d:
			best = s
			best_d = s.ground_pos.distance_to(p.ground_pos)
	if best != null:
		best.fight(p, SOLDIER_FIGHT_SECONDS, Person.SOLDIER_BLOW, Person.FightRule.HOSTILES)


## What a stage asks of a person while it lasts.
func _tick(p: Person, rec: Dictionary, stage: Stage, delta: float) -> void:
	match stage:
		Stage.UNEASY:
			rec.tic = float(rec.tic) - delta
			if float(rec.tic) <= 0.0:
				rec.tic = _rng.randf_range(HESITATE_EVERY.x, HESITATE_EVERY.y)
				p.hesitate(0.6)
				if _rng.randf() < 0.5:
					_whisper(p, 3)
		Stage.DISTURBED:
			rec.concern = float(rec.concern) - delta
			if float(rec.concern) <= 0.0:
				rec.concern = CONCERN_EVERY
				for q in _crowd.citizens:
					if is_instance_valid(q) and q != p and q.is_alive() and q.ground_pos.distance_to(p.ground_pos) <= CONCERN_R:
						q.observe(p.ground_pos)
				p.hesitate(0.4)
		Stage.UNSTABLE:
			rec.shove = float(rec.shove) - delta
			if float(rec.shove) <= 0.0:
				rec.shove = SHOVE_EVERY
				for e in _field.in_radius(p.ground_pos, SHOVE_R):
					var q := e as Person
					if q != null and q != p and not q.inside:
						var away := q.ground_pos - p.ground_pos
						q.knock((away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 1.5)
		Stage.BROKEN:
			pass  # its outcome runs on the person's own timers


## The madness ends for `p`.
func _end(p: Person) -> void:
	p.statuses.erase(STATUS)
	if p.mind == Person.Mind.FIGHT and not p.soldier:
		p.stop_fighting()


func _propagate() -> void:
	var fresh: Array = []
	for p: Person in afflicted:
		var rec: Dictionary = afflicted[p]
		if not is_instance_valid(p) or not p.is_alive() or p.inside or int(rec.stage) < Stage.DISTURBED:
			continue
		for e in _field.in_radius(p.ground_pos, PROPAGATION_R):
			if int(rec.secondary) >= MAX_SECONDARY_TARGETS or afflicted.size() + fresh.size() >= MAX_AFFLICTED:
				break
			var q := e as Person
			if q == null or q == p or q.statuses.has(STATUS) or _rng.randf() >= PROPAGATE_CHANCE:
				continue
			if afflict(q, 0.05):
				rec.secondary = int(rec.secondary) + 1
				fresh.append([p.ground_pos, q.ground_pos, _clock + 1.2])
	links.append_array(fresh)


# --- Looks -------------------------------------------------------------------

## Whether any of the afflicted is out in the open to be seen.
func any_in_open() -> bool:
	for p: Person in afflicted:
		if is_instance_valid(p) and p.is_alive() and not p.inside and p.visible:
			return true
	return false


## A few dark motes rising off someone (whispers).
func _whisper(p: Person, count: int) -> void:
	var layer := _crowd.overlay()
	_whispers = _whispers.filter(func(x) -> bool: return is_instance_valid(x))
	if layer == null or p.inside or _whispers.size() >= WHISPER_MAX:
		return
	var puff := PixelParticles.new()
	puff.rng.seed = _fx_rng.randi()
	puff.shape = PixelParticles.Shape.SQUARE
	puff.ramp = PackedColorArray([Color("b080c8"), Color("6a3a7a"), Color(0.25, 0.1, 0.3, 0.6)])
	puff.position = Iso.ground_to_screen(p.ground_pos) + Vector2(0, -14)
	puff.gravity = -10.0
	puff.drag = 1.0
	layer.add_child(puff)
	puff.burst(count, {"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(4, 12),
		"life": Vector2(0.6, 1.1), "size": Vector2(1, 1)})
	_whispers.append(puff)


## Under the people (the crowd's ground drawer): a ring in the stage's colour under each, the Disturbed and worse on
## thin dark tendrils that flicker, and one just broken on a cracked halo.
func draw_ground(ci: CanvasItem) -> void:
	var now := float(Time.get_ticks_msec()) * 0.001
	for p: Person in afflicted:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or not p.visible:
			continue
		var rec: Dictionary = afflicted[p]
		var stage := int(rec.stage)
		var at := Iso.ground_to_screen(p.ground_pos)
		var k := float(p.stagger_key() % 11)
		ci.draw_set_transform(at, 0.0, Vector2(1.0, 0.5))
		ci.draw_arc(Vector2.ZERO, 7.0, 0.0, TAU, 12, Color(COL_STAGES[stage], 0.4 + 0.15 * float(stage)), 1.0)
		ci.draw_set_transform(Vector2.ZERO)
		if stage < Stage.DISTURBED:
			continue
		for i in TENDRILS:
			var a := TAU * (float(i) + 0.5 * sin(now * 0.7 + k)) / float(TENDRILS)
			var len := 6.0 + 3.0 * sin(now * 2.3 + k + float(i))
			var flick := 0.35 + 0.35 * step_hash(now * 6.0 + k + float(i) * 1.7)
			var c := COL_TENDRIL if stage < Stage.UNSTABLE else COL_STAGES[stage]
			ci.draw_line(at, at + Vector2(cos(a) * len, sin(a) * len * 0.5), Color(c, flick), 1.0)
		var since_broken := _clock - float(rec.broken_at)
		if since_broken >= 0.0 and since_broken < HALO_SECONDS:
			var r := 8.0 + since_broken * 14.0
			var alpha := 1.0 - since_broken / HALO_SECONDS
			for i in 7:
				var a0 := TAU * float(i) / 7.0 + k
				ci.draw_arc(at, r, a0, a0 + 0.55, 4, Color(COL_STAGES[Stage.BROKEN], alpha), 1.0)


## Over the people (the crowd's overlay): eyes that come and go over the Disturbed, a pulsing mark over the Unstable,
## a red flash then a red point over the Broken.
func draw_over(ci: CanvasItem) -> void:
	var now := float(Time.get_ticks_msec()) * 0.001
	for p: Person in afflicted:
		if not is_instance_valid(p) or not p.is_alive() or p.inside or not p.visible:
			continue
		var rec: Dictionary = afflicted[p]
		var stage := int(rec.stage)
		var k := float(p.stagger_key() % 13)
		var at := Iso.ground_to_screen(p.ground_pos) + Vector2(0, -23 - float(int(now * 2.0 + k) % 2))
		var col: Color = COL_STAGES[stage]
		match stage:
			Stage.UNEASY:
				# A dim point that comes and goes.
				if fmod(now * 0.8 + k * 0.37, 1.0) < 0.6:
					_edged(ci, at, Vector2i(3, 3), col)
			Stage.DISTURBED:
				# An eye, open, that blinks now and then.
				if fmod(now * 0.6 + k * 0.37, 1.0) < 0.08:
					ci.draw_rect(Rect2(at + Vector2(-4, 0), Vector2(9, 1)), COL_EDGE)
					ci.draw_rect(Rect2(at + Vector2(-3, 0), Vector2(7, 1)), COL_EYE)
				else:
					_eye(ci, at, COL_EYE, col)
			Stage.UNSTABLE:
				# A diamond pulsing red, with the eye below it.
				var big := fmod(now * 3.5 + k, 1.0) < 0.5
				_diamond(ci, at + Vector2(0, -3), 3 if big else 2, col)
				_eye(ci, at + Vector2(0, 3), COL_EYE, col)
			Stage.BROKEN:
				var since := _clock - float(rec.broken_at)
				if since < HALO_SECONDS:
					# The halo cracks open: a burst of lines, and a flash of the eye.
					var r := 6.0 + since * 18.0
					for i in 8:
						var a := TAU * float(i) / 8.0 + k
						ci.draw_line(at + Vector2(cos(a), sin(a) * 0.6) * (r * 0.5), at + Vector2(cos(a), sin(a) * 0.6) * r,
							Color(col, 1.0 - since / HALO_SECONDS), 1.0)
					ci.draw_rect(Rect2(at + Vector2(-4, -1), Vector2(9, 3)), COL_EYE)
				else:
					# Then a red eye, wide open, over a red diamond.
					_diamond(ci, at + Vector2(0, -3), 2, col)
					_eye(ci, at + Vector2(0, 3), Color("ffb0b0"), col, Color("ff2020"))


## A filled block edged dark, so a symbol reads on any ground.
static func _edged(ci: CanvasItem, at: Vector2, size: Vector2i, col: Color) -> void:
	var half := Vector2(size) * 0.5
	ci.draw_rect(Rect2(at - half - Vector2.ONE, Vector2(size) + Vector2(2, 2)), COL_EDGE)
	ci.draw_rect(Rect2(at - half, Vector2(size)), col)


## An eye: a pale almond 7 wide, edged dark, with a pupil.
static func _eye(ci: CanvasItem, at: Vector2, white: Color, pupil: Color, glow := Color(0, 0, 0, 0)) -> void:
	if glow.a > 0.0:
		ci.draw_rect(Rect2(at + Vector2(-5, -2), Vector2(11, 5)), Color(glow, 0.45))
	ci.draw_rect(Rect2(at + Vector2(-4, -1), Vector2(9, 3)), COL_EDGE)
	ci.draw_rect(Rect2(at + Vector2(-3, -1), Vector2(7, 1)), white.darkened(0.3))
	ci.draw_rect(Rect2(at + Vector2(-3, 0), Vector2(7, 1)), white)
	ci.draw_rect(Rect2(at + Vector2(-2, 1), Vector2(5, 1)), white.darkened(0.3))
	ci.draw_rect(Rect2(at + Vector2(0, 0), Vector2(1, 1)), pupil)


## A diamond of `half` steps, edged dark.
static func _diamond(ci: CanvasItem, at: Vector2, half: int, col: Color) -> void:
	for row in range(-half - 1, half + 2):
		var w := half + 1 - absi(row)
		if w >= 0:
			ci.draw_rect(Rect2(at + Vector2(-w, row), Vector2(w * 2 + 1, 1)), COL_EDGE)
	for row in range(-half, half + 1):
		var w := half - absi(row)
		ci.draw_rect(Rect2(at + Vector2(-w, row), Vector2(w * 2 + 1, 1)), col)


static func step_hash(x: float) -> float:
	return 1.0 if fmod(absf(sin(floor(x) * 12.9898) * 43758.5453), 1.0) > 0.5 else 0.0


func clear() -> void:
	afflicted.clear()
	links.clear()
	_whispers.clear()
	alarm_generated = 0.0
	broken = 0
	_clock = 0.0
	_scan_in = 0.0
	_propagate_in = PROPAGATE_EVERY
