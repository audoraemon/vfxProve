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

const DP_MAX := 100.0
## Divine Power comes back this fast on its own (spec §4.1).
const DP_REGEN := 0.5
## The manifestation's length in seconds (spec §1: 4:00).
const MISSION_SECONDS := 240.0

var dp := DP_MAX
var time_left := MISSION_SECONDS
## The four drafted power keys, in slot order.
var loadout := PackedStringArray()
## The mission is over: the clock ran out, the people got away, or the city fell.
var finished := false

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
	return self


func _process(delta: float) -> void:
	advance(delta)


## Drive the mission by hand (tests and scripted runs) or from _process.
func advance(delta: float) -> void:
	if finished:
		return
	for i in _cooldowns.size():
		_cooldowns[i] = maxf(0.0, _cooldowns[i] - delta)
	if dp < DP_MAX:
		dp = minf(DP_MAX, dp + DP_REGEN * delta)
		dp_changed.emit(dp)
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		finished = true


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
	cast_made.emit(slot, String(p.key), ground)
	return fx
