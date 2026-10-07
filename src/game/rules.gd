class_name Rules
extends Node
## One mission's numbers (spec §4): the slots' cooldowns, the one-power-at-a-time lock, the clock, City Stability,
## chains, win and lose, score and rank. No Divine Power is spent in a mission (v0.08): the loadout's price was
## paid in the draft, and the Temple's fall is a Divine Surge that resets every cooldown, once. It learns what
## happened from the signals the world already emits and never reaches into the world itself, except to start a
## cast.

## A cast went out: the slot, its power key and where it landed.
signal cast_made(slot: int, key: String, at: Vector2)
## A cast could not go out: "cooldown", "busy", "empty", "over", "nobody" (v0.08: a Mind Whisper with no one to
## whisper to) or "shaken" (v0.08.1: a Mind Whisper on someone still shaking the last one off, Person.SHAKE_OFF).
signal cast_refused(slot: int, reason: String)
## The Temple fell and every cooldown was reset (v0.08's Divine Surge, once a mission).
signal surged
## A slot's cooldown ran out: it can be cast again. Not sent for the Divine Surge's reset, which is surged.
signal recharged(slot: int)
## One cast destroyed six buildings or killed twenty-five people.
signal chained(at: Vector2)
## Something worth a line across the middle of the screen.
signal banner(text: String)
## Cael speaks (v0.10 M5, spec §5.2): a line of his, shown under the banners (the HUD's subtitle).
signal subtitle(text: String)
## The mission ended. reason: "citadel" (won), "escapes" or "timeout".
signal over(won: bool, reason: String)

## The manifestation's length in seconds (spec §1 had 4:00; six minutes since the town scale upgrade tripled the town).
const MISSION_SECONDS := 360.0
## One cast that destroys this many buildings, or kills this many people, is a chain.
const CHAIN_BUILDINGS := 6
const CHAIN_KILLS := 25

## The damage kinds each power deals, so a destroyed building or a kill can be credited to the cast that did
## it. Two kinds are shared (Dragonfire Parade and the Barrage both burn with &"cinder"; the Barrage and
## Judgement both drop &"stone"), which the tie rule in _credit() settles.
const POWER_KINDS := {
	"doom": [&"doom"],
	"pestilence": [&"plague"],
	"heaven": [&"lightning"],
	"tornado": [&"wind"],
	"dragon": [&"fire", &"cinder"],
	"tsunami": [&"water"],
	"gravity": [&"gravity"],
	"laser": [&"laser"],
	"orbital": [&"orbital"],
	"cinder": [&"cinder", &"stone"],
	"judgement": [&"stone"],
	"glacial": [&"ice"],
	"solaris": [&"solaris", &"pit"],
	"madness": [&"frenzy"],
	"smite": [&"lightning", &"smite"],
	"ember": [&"fire"],
	"deathmark": [&"deathmark"],
	"noleave": [],
	"belllies": [],
	"magnify": [&"magnify"],
	"abolition": [],
	"voice": [&"frenzy"],
	"turncoat": [&"frenzy"],
	"hatred": [&"frenzy"],
	"verdict": [&"frenzy", &"mob"],
	"schism": [&"frenzy"],
	"nova": [&"nova"],
}
## The laws of a mission Abolition can void for a while (abolish()), and the Citadel's budget with its ward gone.
const LAW_CLOCK := &"clock"
const LAW_ESCAPE := &"escape"
const LAW_WARD := &"ward"
const LAWS := [LAW_CLOCK, LAW_ESCAPE, LAW_WARD]
const WARD_GONE := 1000.0
## The roles that count as a building for the tally, the chain and the score. Decor (trees, torch posts) does
## not, and the Citadel's nine parts are not nine buildings -- the Citadel is its own objective.
const BUILDING_ROLES := [&"house", &"wall", &"tower", &"gate", &"temple", &"barracks", &"market", &"farm", &"bridge",
	&"dock"]
## How long a cast with no effect behind it (a test's stub, an effect that has already finished) can still be
## credited for what it started.
const CAST_GRACE := 4.0

## This many citizens reaching an exit loses the mission (spec §4.4: 76; 50 since v0.04, whose evacuation comes
## late -- after the bell and a regroup -- and then lets out about 0.65 a second across both gates).
const ESCAPE_LIMIT := 50

const SCORE_WIN := 5000
const SCORE_PER_SECOND := 25
const SCORE_PER_BUILDING := 40
const SCORE_PER_CITIZEN := 10
const SCORE_PER_SOLDIER := 25
const SCORE_PER_CHAIN := 300
## Score floors for each rank, best first; anything under the last one is a D. v0.08 lowered each by 200, the Divine
## Power term (floor(dp_left) x 10) a v0.07 run still held at its end.
const RANKS := [[19000, "S"], [14200, "A"], [9400, "B"], [4600, "C"]]

var time_left := MISSION_SECONDS
## The drafted power keys, in slot order.
var loadout := PackedStringArray()
## The mission is over: the clock ran out, the people got away, or the city fell.
var finished := false
## Buildings destroyed this mission, by BUILDING_ROLES.
var buildings_down := 0
## How many casts chained.
var chains := 0
## The Divine Surge has happened: the Temple's fall resets the cooldowns only once a mission.
var surged_once := false

## The five-part city health. Measured at most once a frame, and only after something changed it.
var stability: Stability
var won := false
## Which ending: "citadel", "escapes", "timeout", or "" while the mission runs.
var over_reason := ""

var _stability_dirty := true

## The mission being played (v0.08), its objectives -- decided in list order, see Objective -- and its director.
var mission: MissionDef
var objectives: Array[Objective] = []
var bonuses: Array[Objective] = []
var director: MissionDirector

## How a cast reaches the world: func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline.
## Set in setup() to go through FxTimeline.cast; tests replace it so they need no effects.
var caster := Callable()

var _ctx: FxContext
var _env: EnvironmentField
var _field: EnemyField
var _crowd: Crowd
var _town: Town
## Seconds of cooldown left per slot.
var _cooldowns := PackedFloat32Array()
## The power now playing; no other can be cast until it finishes (busy_left()).
var _playing: FxTimeline
## One entry per cast that may still be credited: {"key", "fx", "at", "buildings", "kills", "chained", "until"}.
var _casts: Array[Dictionary] = []
## Seconds since the mission started, for the casts' grace window.
var _elapsed := 0.0
## The crowd's counts when this act began (v0.09): an act counts from its own start; a single mission starts from 0.
var _escaped0 := 0
## The laws abolished for now (abolish()): law -> seconds left. And the Citadel's ward as it was, to put back.
var _abolished := {}
var _ward_budget := -1.0
var _citizens0 := 0
var _soldiers0 := 0


func setup(powers: PackedStringArray, ctx: FxContext, env: EnvironmentField, field: EnemyField, crowd: Crowd,
		town: Town, mission_def: MissionDef = null) -> Rules:
	loadout = powers
	mission = mission_def if mission_def != null else MissionBook.last_judgement()
	time_left = mission.clock
	objectives = mission.objectives()
	bonuses = mission.bonuses()
	_ctx = ctx
	_env = env
	_field = field
	_crowd = crowd
	_town = town
	_escaped0 = crowd.escaped_count
	_citizens0 = crowd.killed_citizens
	_soldiers0 = crowd.killed_soldiers
	_cooldowns.resize(loadout.size())
	_cooldowns.fill(0.0)
	caster = func(script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		return FxTimeline.cast(script, _ctx, ground, extra)
	stability = Stability.new().setup(_env)
	_env.structure_destroyed.connect(_on_structure_destroyed)
	_field.enemy_killed.connect(_on_killed)
	_crowd.escaped.connect(_on_escaped)
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		_town.citadel.fallen.connect(_on_citadel_fallen)
		_town.citadel.health_changed.connect(_on_citadel_health)
	_env.structure_restored.connect(_on_structure_restored)
	stability.measure(_env, _crowd, _town.citadel)
	_stability_dirty = false
	for o in objectives + bonuses:
		o.begin(self)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Drive the mission by hand (tests and scripted runs) or from _process.
func advance(delta: float) -> void:
	if finished:
		return
	for i in _cooldowns.size():
		var was := _cooldowns[i]
		_cooldowns[i] = maxf(0.0, was - delta)
		if was > 0.0 and _cooldowns[i] == 0.0:
			recharged.emit(i)
	_elapsed += delta
	_forget_old_casts()
	_step_abolished(delta)
	if not is_abolished(LAW_CLOCK):
		time_left = maxf(0.0, time_left - delta)
	if _stability_dirty:
		_stability_dirty = false
		stability.measure(_env, _crowd, _town.citadel)
		# Order breaks down in the town once stability has fallen this far (v0.04's last alarm stage).
		if stability.total() <= AlarmManager.COLLAPSE_STABILITY and is_instance_valid(_crowd):
			_crowd.order_collapses()
	if director != null:
		director.step(delta)
	_check_end()


## Abolish a law of the mission for `seconds` (Abolition). LAW_CLOCK: the clock does not run, and time stands still
## in the town (Crowd.freeze()). LAW_ESCAPE: whoever
## escapes meanwhile is not counted against the act's limit. LAW_WARD: the Citadel's ward -- the cap on what it can
## lose in a second -- is gone. The law comes back by itself when the time is up.
func abolish(law: StringName, seconds: float) -> void:
	if not law in LAWS or seconds <= 0.0:
		return
	_abolished[law] = maxf(float(_abolished.get(law, 0.0)), seconds)
	if law == LAW_CLOCK and is_instance_valid(_crowd):
		_crowd.freeze(seconds)  # with no clock, time itself stands still in the town
	if law == LAW_WARD and _ward_budget < 0.0 and is_instance_valid(_town) and is_instance_valid(_town.citadel):
		_ward_budget = _town.citadel.budget_per_second
		_town.citadel.budget_per_second = WARD_GONE


func is_abolished(law: StringName) -> bool:
	return _abolished.has(law)


func _step_abolished(delta: float) -> void:
	for law: StringName in _abolished.keys():
		_abolished[law] = float(_abolished[law]) - delta
		if float(_abolished[law]) > 0.0:
			continue
		_abolished.erase(law)
		if law == LAW_WARD and _ward_budget >= 0.0:
			if is_instance_valid(_town) and is_instance_valid(_town.citadel):
				_town.citadel.budget_per_second = _ward_budget
			_ward_budget = -1.0


## The manifestation is cut short by `seconds` (the clergy's Banishing Rite, v0.05). The clock never goes below
## zero; the next advance() ends a mission it ran out on.
func lose_time(seconds: float) -> void:
	time_left = maxf(0.0, time_left - seconds)


## The clergy's Banishing Rite is complete: the clock loses the mission's rite_penalty (v0.09.1: 20 s in The Long Night's
## acts, BanishingRite.PENALTY elsewhere). Returns the seconds lost, for the banner.
func banish() -> float:
	var seconds := mission.rite_penalty if mission != null else BanishingRite.PENALTY
	lose_time(seconds)
	return seconds


## The mission's crowd and town, for its objectives and its director (v0.08).
func crowd() -> Crowd:
	return _crowd


func town() -> Town:
	return _town


## Citizens who reached an exit, and the people killed, since this act began (v0.09).
func escaped_this_act() -> int:
	return _crowd.escaped_count - _escaped0


func citizens_killed_this_act() -> int:
	return _crowd.killed_citizens - _citizens0


func soldiers_killed_this_act() -> int:
	return _crowd.killed_soldiers - _soldiers0


## The power in a slot, or an empty dictionary for a slot nothing was drafted into.
func power(slot: int) -> Dictionary:
	if slot < 0 or slot >= loadout.size():
		return {}
	return PowerBook.get_power(loadout[slot])


func key(slot: int) -> String:
	var p := power(slot)
	return String(p.get("key", ""))


func cooldown_left(slot: int) -> float:
	if slot < 0 or slot >= _cooldowns.size():
		return 0.0
	return _cooldowns[slot]


## Why this slot cannot cast right now, or "" when it can. The cooldown is named first: it is the wait the
## player can do nothing about, and the HUD shows its seconds.
func refusal(slot: int) -> String:
	if finished:
		return "over"
	if power(slot).is_empty():
		return "empty"
	if cooldown_left(slot) > 0.0:
		return "cooldown"
	if busy_left() > 0.0:
		return "busy"
	return ""


## Seconds until the power now playing has finished (0 when none is): one cataclysm at a time, so a player cannot
## stack every power at once -- the town reads each one, and the frame keeps up. A lingering effect sets
## FxTimeline.busy to lock only while it is cast.
func busy_left() -> float:
	if not is_instance_valid(_playing) or _playing.finished:
		return 0.0
	var lock := _playing.busy if _playing.busy >= 0.0 else _playing.duration
	return maxf(lock - _playing.t, 0.0)


## Refuse a cast for the slot before it reaches cast() (v0.08: Targeting, when a Mind Whisper's press finds nobody, or
## v0.08.1 someone shaken).
func refuse(slot: int, reason: String) -> void:
	cast_refused.emit(slot, reason)


## Start the slot's cooldown and put its effect in the world. Returns the running effect, or
## null when the cast was refused (and when a test's caster hands nothing back).
func cast(slot: int, ground: Vector2, extra := {}) -> FxTimeline:
	var reason := refusal(slot)
	if reason != "":
		cast_refused.emit(slot, reason)
		return null
	var p := power(slot)
	if String(p.key) == "whisper":
		# Mind Whisper (v0.08) with no one to whisper to, or (v0.08.1) to someone still shaking the last one off:
		# refused, and no cooldown starts.
		var given: Variant = extra.get("target")
		var heard := is_instance_valid(given) and given is Person and (given as Person).is_alive() \
			and not (given as Person).inside and not (given as Person).soldier
		var who: Person = (given as Person) if heard else MindWhisperFx.pick(_field, ground)
		if who == null:
			cast_refused.emit(slot, "nobody")
			return null
		if who.shaken():
			cast_refused.emit(slot, "shaken")
			return null
	_cooldowns[slot] = float(p.cooldown)
	var fx: FxTimeline = caster.call(load(String(p.path)) as GDScript, ground, extra)
	_playing = fx
	_casts.append({"key": String(p.key), "fx": fx, "at": ground, "buildings": 0, "kills": 0, "chained": false,
		"until": _elapsed + CAST_GRACE})
	cast_made.emit(slot, String(p.key), ground)
	return fx


## The power key credited with this damage kind: among the casts still running, the one whose power deals it,
## latest first (spec §4.1). "" when nothing running claims it -- a building that falls to a stray fire after
## its cast is gone still counts, it just has nobody to chain for.
func credited_key(kind: StringName) -> String:
	var c := _credit(kind)
	return String(c.get("key", "")) if not c.is_empty() else ""


func _credit(kind: StringName) -> Dictionary:
	for i in range(_casts.size() - 1, -1, -1):
		var c: Dictionary = _casts[i]
		var kinds: Array = POWER_KINDS.get(c.key, [])
		if kinds.has(kind):
			return c
	return {}


## Drop casts whose effect has finished and whose grace has run out, so a four-minute mission does not credit
## a kill to a volcano that went cold three minutes ago.
func _forget_old_casts() -> void:
	var keep: Array[Dictionary] = []
	for c in _casts:
		# Read untyped first: an effect can be freed without finishing (its layer cleared), and assigning a freed
		# object to a typed variable raises and aborts this loop -- after which old casts were never forgotten.
		var ref: Variant = c.fx
		var running: bool = is_instance_valid(ref) and not (ref as FxTimeline).finished
		if running or _elapsed < float(c.until):
			keep.append(c)
	_casts = keep


func _on_structure_destroyed(s: Structure, kind: StringName) -> void:
	_stability_dirty = true
	if not BUILDING_ROLES.has(s.role):
		return
	buildings_down += 1
	if s.role == &"temple" and not surged_once:
		# The Divine Surge (v0.08): the Temple's fall resets every cooldown, once.
		surged_once = true
		_cooldowns.fill(0.0)
		surged.emit()
		banner.emit("DIVINE SURGE")
	var c := _credit(kind)
	if c.is_empty():
		return
	c.buildings = int(c.buildings) + 1
	_check_chain(c)


## A gate or the bridge rebuilt (v0.05's engineers): the town's infrastructure is back.
func _on_structure_restored(_s: Structure) -> void:
	_stability_dirty = true


func _on_killed(_e: DummyEnemy, kind: StringName) -> void:
	_stability_dirty = true
	var c := _credit(kind)
	if c.is_empty():
		return
	c.kills = int(c.kills) + 1
	_check_chain(c)


func _on_citadel_fallen() -> void:
	banner.emit("THE CITADEL FALLS")


func _check_chain(c: Dictionary) -> void:
	if bool(c.chained) or (int(c.buildings) < CHAIN_BUILDINGS and int(c.kills) < CHAIN_KILLS):
		return
	c.chained = true
	chains += 1
	chained.emit(c.at)
	banner.emit("CHAIN!")


func _on_escaped(_p: Person) -> void:
	if is_abolished(LAW_ESCAPE):
		_escaped0 += 1  # not counted against the act
	_stability_dirty = true


func _on_citadel_health(_fraction: float) -> void:
	_stability_dirty = true


## The mission's primary objectives decide it, in their order (v0.08): the first DONE wins, the first FAILED loses.
## Last Judgement lists the Citadel first, so a city that falls on the last tick of the clock still counts.
func _check_end() -> void:
	if finished:
		return
	for o in objectives:
		match o.check(self):
			Objective.Status.DONE:
				_finish(true, o.reason)
				return
			Objective.Status.FAILED:
				_finish(false, o.reason)
				return


## End the act now, as a tool or a test asks (v0.09); an act already over stays as it ended.
func force_end(win: bool, reason: String) -> void:
	if not finished:
		_finish(win, reason)


func _finish(win: bool, reason: String) -> void:
	finished = true
	won = win
	over_reason = reason
	over.emit(won, reason)


## The mission's points (spec §4.4). The victory bonus and the seconds left are a winner's only:
## a mission lost to the escape would otherwise pay the player for losing it quickly.
func score() -> int:
	var total := buildings_down * SCORE_PER_BUILDING + citizens_killed_this_act() * SCORE_PER_CITIZEN \
		+ soldiers_killed_this_act() * SCORE_PER_SOLDIER + chains * SCORE_PER_CHAIN
	if won:
		total += SCORE_WIN + int(roundf(time_left)) * SCORE_PER_SECOND
	return total


func rank() -> String:
	var s := score()
	for r: Array in RANKS:
		if s >= int(r[0]):
			return String(r[1])
	return "D"


## The results table: one line per scoring rule, with what it was worth. Milestone 4's Results screen draws
## these; Task 7 prints them at the end of a scripted run.
func stat_lines() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if won:
		lines.append({"label": "The city has fallen", "value": "", "points": SCORE_WIN})
		lines.append({"label": "Time left", "value": UiTheme.clock(time_left), "points": int(roundf(time_left)) * SCORE_PER_SECOND})
	lines.append({"label": "Buildings destroyed", "value": "%d" % buildings_down, "points": buildings_down * SCORE_PER_BUILDING})
	lines.append({"label": "Citizens killed", "value": "%d" % citizens_killed_this_act(), "points": citizens_killed_this_act() * SCORE_PER_CITIZEN})
	lines.append({"label": "Soldiers killed", "value": "%d" % soldiers_killed_this_act(), "points": soldiers_killed_this_act() * SCORE_PER_SOLDIER})
	lines.append({"label": "Citizens escaped", "value": "%d" % escaped_this_act(), "points": 0})
	lines.append({"label": "Chains", "value": "%d" % chains, "points": chains * SCORE_PER_CHAIN})
	return lines


## Everything the Results screen and the save need (v0.08): the mission, the ending, the time it took, the goal and
## each bonus as earned or not, a scored mission's score, rank and table, and the director's own report.
func result() -> Dictionary:
	var out := {"mission": mission.id, "won": won, "reason": over_reason, "time": _elapsed,
		"goal": {"label": mission.goal_label, "done": won}, "bonuses": []}
	for b in bonuses:
		out.bonuses.append({"label": b.label, "earned": won and b.check(self) != Objective.Status.FAILED})
	if mission.scored:
		out["score"] = score()
		out["rank"] = rank()
		out["lines"] = stat_lines()
	if director != null:
		out.merge(director.report())
	return out


## Let the world go. A mission that is finished stops counting, and a restart never has two Rules adding up the
## same destroyed building -- freeing a node disconnects it eventually, but queue_free() is deferred and the
## overlap is a whole frame wide.
func teardown() -> void:
	if director != null:
		director.teardown()
		director = null
	if is_instance_valid(_env) and _env.structure_destroyed.is_connected(_on_structure_destroyed):
		_env.structure_destroyed.disconnect(_on_structure_destroyed)
	if is_instance_valid(_env) and _env.structure_restored.is_connected(_on_structure_restored):
		_env.structure_restored.disconnect(_on_structure_restored)
	if is_instance_valid(_field) and _field.enemy_killed.is_connected(_on_killed):
		_field.enemy_killed.disconnect(_on_killed)
	if is_instance_valid(_crowd) and _crowd.escaped.is_connected(_on_escaped):
		_crowd.escaped.disconnect(_on_escaped)
	if is_instance_valid(_town) and is_instance_valid(_town.citadel):
		if _town.citadel.fallen.is_connected(_on_citadel_fallen):
			_town.citadel.fallen.disconnect(_on_citadel_fallen)
		if _town.citadel.health_changed.is_connected(_on_citadel_health):
			_town.citadel.health_changed.disconnect(_on_citadel_health)
