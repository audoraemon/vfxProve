class_name Rules
extends Node
## One mission's numbers (spec §4): Divine Power and its recovery, the four slots' cooldowns, the four-minute
## clock, City Stability, chains, win and lose, score and rank. It learns what happened from the signals the
## world already emits and never reaches into the world itself, except to start a cast.

signal dp_changed(value: float)
## A cast went out: the slot, its power key and where it landed.
signal cast_made(slot: int, key: String, at: Vector2)
## A cast could not go out: "cooldown", "dp", "empty" or "over".
signal cast_refused(slot: int, reason: String)
## Divine Power came back from something that was destroyed, at the place it happened (for the popup).
signal dp_gained(amount: float, at: Vector2)
## One cast destroyed six buildings or killed twenty-five people.
signal chained(at: Vector2)
## Something worth a line across the middle of the screen.
signal banner(text: String)
## The mission ended. reason: "citadel" (won), "escapes" or "timeout".
signal over(won: bool, reason: String)

const DP_MAX := 100.0
## Divine Power comes back this fast on its own (spec §4.1).
const DP_REGEN := 0.5
## The manifestation's length in seconds (spec §1: 4:00).
const MISSION_SECONDS := 240.0
## What each destroyed thing pays back (spec §4.1). Citizens, houses, the market, the farms and the walls pay
## nothing: the player is not rewarded for shopping.
const DP_FOR_ROLE := {&"tower": 3.0, &"gate": 5.0, &"temple": 8.0, &"barracks": 10.0}
const DP_SOLDIER := 0.4
const CITADEL_DP := 15.0
## One cast that destroys this many buildings, or kills this many people, is a chain.
const CHAIN_BUILDINGS := 6
const CHAIN_KILLS := 25
const CHAIN_DP := 6.0

## The damage kinds each power deals, so a destroyed building or a kill can be credited to the cast that did
## it. Two kinds are shared (Dragonfire Parade and the Barrage both burn with &"cinder"; the Barrage and
## Judgement both drop &"stone"), which the tie rule in _credit() settles.
const POWER_KINDS := {
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
	"nova": [&"nova"],
}
## The roles that count as a building for the tally, the chain and the score. Decor (trees, torch posts) does
## not, and the Citadel's nine parts are not nine buildings -- the Citadel is worth its own CITADEL_DP.
const BUILDING_ROLES := [&"house", &"wall", &"tower", &"gate", &"temple", &"barracks", &"market", &"farm", &"bridge"]
## How long a cast with no effect behind it (a test's stub, an effect that has already finished) can still be
## credited for what it started.
const CAST_GRACE := 4.0

## This many citizens reaching an exit loses the mission (spec §4.4).
const ESCAPE_LIMIT := 38

const SCORE_WIN := 5000
const SCORE_PER_SECOND := 25
const SCORE_PER_BUILDING := 40
const SCORE_PER_CITIZEN := 10
const SCORE_PER_SOLDIER := 25
const SCORE_PER_CHAIN := 300
const SCORE_PER_DP := 10
## Score floors for each rank, best first; anything under the last one is a D.
const RANKS := [[12000, "S"], [9000, "A"], [6000, "B"], [3000, "C"]]

var dp := DP_MAX
var time_left := MISSION_SECONDS
## The four drafted power keys, in slot order.
var loadout := PackedStringArray()
## The mission is over: the clock ran out, the people got away, or the city fell.
var finished := false
## Buildings destroyed this mission, by BUILDING_ROLES.
var buildings_down := 0
## How many casts chained.
var chains := 0

## The five-part city health. Measured at most once a frame, and only after something changed it.
var stability: Stability
var won := false
## Which ending: "citadel", "escapes", "timeout", or "" while the mission runs.
var over_reason := ""

var _stability_dirty := true

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
## One entry per cast that may still be credited: {"key", "fx", "at", "buildings", "kills", "chained", "until"}.
var _casts: Array[Dictionary] = []
## Seconds since the mission started, for the casts' grace window.
var _elapsed := 0.0


func setup(powers: PackedStringArray, ctx: FxContext, env: EnvironmentField, field: EnemyField, crowd: Crowd,
		town: Town) -> Rules:
	loadout = powers
	_ctx = ctx
	_env = env
	_field = field
	_crowd = crowd
	_town = town
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
	stability.measure(_env, _crowd, _town.citadel)
	return self


func _process(delta: float) -> void:
	advance(delta)


## Drive the mission by hand (tests and scripted runs) or from _process.
func advance(delta: float) -> void:
	if finished:
		return
	for i in _cooldowns.size():
		_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
	_elapsed += delta
	_forget_old_casts()
	if dp < DP_MAX:
		dp = minf(DP_MAX, dp + DP_REGEN * delta)
		dp_changed.emit(dp)
	time_left = maxf(0.0, time_left - delta)
	if _stability_dirty:
		_stability_dirty = false
		stability.measure(_env, _crowd, _town.citadel)
	_check_end()


## The power in a slot, or an empty dictionary for a slot nothing was drafted into.
func power(slot: int) -> Dictionary:
	if slot < 0 or slot >= loadout.size():
		return {}
	return PowerBook.get_power(loadout[slot])


func key(slot: int) -> String:
	var p := power(slot)
	return String(p.get("key", ""))


func cost(slot: int) -> int:
	var p := power(slot)
	return int(p.get("dp", 0))


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
	if dp < float(cost(slot)):
		return "dp"
	return ""


## Spend the slot's DP, start its cooldown and put its effect in the world. Returns the running effect, or
## null when the cast was refused (and when a test's caster hands nothing back).
func cast(slot: int, ground: Vector2, extra := {}) -> FxTimeline:
	var reason := refusal(slot)
	if reason != "":
		cast_refused.emit(slot, reason)
		return null
	var p := power(slot)
	dp -= float(cost(slot))
	dp_changed.emit(dp)
	_cooldowns[slot] = float(p.cooldown)
	var fx: FxTimeline = caster.call(load(String(p.path)) as GDScript, ground, extra)
	_casts.append({"key": String(p.key), "fx": fx, "at": ground, "buildings": 0, "kills": 0, "chained": false,
		"until": _elapsed + CAST_GRACE})
	cast_made.emit(slot, String(p.key), ground)
	return fx


## The power key credited with this damage kind: among the casts still running, the one whose power deals it,
## latest first (spec §4.1). "" when nothing running claims it -- a building that falls to a stray fire after
## its cast is gone still pays its DP, it just has nobody to chain for.
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
		var fx: FxTimeline = c.fx
		var running: bool = is_instance_valid(fx) and not fx.finished
		if running or _elapsed < float(c.until):
			keep.append(c)
	_casts = keep


func _on_structure_destroyed(s: Structure, kind: StringName) -> void:
	_stability_dirty = true
	if not BUILDING_ROLES.has(s.role):
		return
	buildings_down += 1
	var pay: float = DP_FOR_ROLE.get(s.role, 0.0)
	if pay > 0.0:
		_gain(pay, s.center())
	var c := _credit(kind)
	if c.is_empty():
		return
	c.buildings = int(c.buildings) + 1
	_check_chain(c)


func _on_killed(e: DummyEnemy, kind: StringName) -> void:
	_stability_dirty = true
	var p := e as Person
	if p != null and p.soldier:
		_gain(DP_SOLDIER, p.ground_pos)
	var c := _credit(kind)
	if c.is_empty():
		return
	c.kills = int(c.kills) + 1
	_check_chain(c)


func _on_citadel_fallen() -> void:
	var at: Vector2 = _town.citadel.origin if is_instance_valid(_town.citadel) else Vector2.ZERO
	_gain(CITADEL_DP, at)
	banner.emit("THE CITADEL FALLS")


func _check_chain(c: Dictionary) -> void:
	if bool(c.chained) or (int(c.buildings) < CHAIN_BUILDINGS and int(c.kills) < CHAIN_KILLS):
		return
	c.chained = true
	chains += 1
	_gain(CHAIN_DP, c.at)
	chained.emit(c.at)
	banner.emit("CHAIN!")


func _gain(amount: float, at: Vector2) -> void:
	dp = minf(DP_MAX, dp + amount)
	dp_changed.emit(dp)
	dp_gained.emit(amount, at)


func _on_escaped(_p: Person) -> void:
	_stability_dirty = true


func _on_citadel_health(_fraction: float) -> void:
	_stability_dirty = true


## Win: the Citadel is down and the city's stability has reached zero. Lose: the people got away, or the
## manifestation ran out. The win is tested first, so a city that falls on the last tick of the clock counts.
func _check_end() -> void:
	if finished:
		return
	if is_instance_valid(_town.citadel) and _town.citadel.is_fallen() and stability.is_broken():
		_finish(true, "citadel")
	elif _crowd.escaped_count >= ESCAPE_LIMIT:
		_finish(false, "escapes")
	elif time_left <= 0.0:
		_finish(false, "timeout")


func _finish(win: bool, reason: String) -> void:
	finished = true
	won = win
	over_reason = reason
	over.emit(won, reason)


## The mission's points (spec §4.4). The victory bonus, the seconds left and the DP left are a winner's only:
## a mission lost to the escape would otherwise pay the player for losing it quickly.
func score() -> int:
	var total := buildings_down * SCORE_PER_BUILDING + _crowd.killed_citizens * SCORE_PER_CITIZEN \
		+ _crowd.killed_soldiers * SCORE_PER_SOLDIER + chains * SCORE_PER_CHAIN
	if won:
		total += SCORE_WIN + int(roundf(time_left)) * SCORE_PER_SECOND + int(floorf(dp)) * SCORE_PER_DP
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
		lines.append({"label": "Time left", "value": "%d:%02d" % [int(time_left) / 60, int(time_left) % 60], "points": int(roundf(time_left)) * SCORE_PER_SECOND})
		lines.append({"label": "Divine Power left", "value": "%d" % int(floorf(dp)), "points": int(floorf(dp)) * SCORE_PER_DP})
	lines.append({"label": "Buildings destroyed", "value": "%d" % buildings_down, "points": buildings_down * SCORE_PER_BUILDING})
	lines.append({"label": "Citizens killed", "value": "%d" % _crowd.killed_citizens, "points": _crowd.killed_citizens * SCORE_PER_CITIZEN})
	lines.append({"label": "Soldiers killed", "value": "%d" % _crowd.killed_soldiers, "points": _crowd.killed_soldiers * SCORE_PER_SOLDIER})
	lines.append({"label": "Citizens escaped", "value": "%d" % _crowd.escaped_count, "points": 0})
	lines.append({"label": "Chains", "value": "%d" % chains, "points": chains * SCORE_PER_CHAIN})
	return lines
