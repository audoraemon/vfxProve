class_name Suspicion
extends RefCounted
## How strange the town finds this night (Town Suspicion). One value, 0..100: witnessed casts that look like weather or
## accident raise it, more when they repeat or differ, and it fades while the town is left in peace. At 100, or when
## something unnatural is seen, the town KNOWS a god is here (a latch). No randomness: the same run gives the same value.

## The value or the state moved.
signal changed
## The value passed UNEASY_AT on its way up (once per rise).
signal uneasy
## The town came to know, once, with the reason.
signal became_known(reason: String)

## A power no weather explains: the town knows at once.
const UNNATURAL := &"unnatural"
## A power with no look at all: it proves nothing.
const NONE := &""
## What a first sign of each natural look adds (wary 1.0, nothing else in memory).
const BASE := {&"lightning": 20.0, &"fire": 20.0, &"storm": 25.0, &"quake": 30.0, &"flood": 30.0, &"miasma": 30.0}
## The kinds of death a natural-looking power explains while the town does not know (the kills of Smite, Ember, the
## tornado, the tsunami, the haze, Earthshatter; the collapse of any building).
const EXPLAINED: Array[StringName] = [&"lightning", &"fire", &"wind", &"water", &"choke", &"pit", &"collapse"]
## The value from which the town is uneasy.
const UNEASY_AT := 40.0
## The value at which the town knows.
const KNOWN_AT := 100.0
## Seconds a sign stays in memory (it counts for "again" and "different").
const MEMORY := 60.0
## Seconds after the last sign before the value starts to fall.
const CALM_DELAY := 15.0
## How fast the value falls, per second.
const FADE := 0.4
## Extra weight of each distinct other look in memory.
const OTHER_LOOKS := 0.5
## What a watched target's death by an explained kind adds (AssassinateDirector).
const TARGET_SIGN := 40.0
## How far a quiet power's sign (Ember) is seen.
const QUIET_SIGN_SIGHT := 5.0
## The reason given when the value itself reaches KNOWN_AT.
const REASON_SIGNS := "too many strange signs"

## 0..100.
var value := 0.0
## The town knows a god is here; latched until reset().
var known := false
## Why the town knows; "" until it does.
var reason := ""
## The town's readiness (ResponseProfile.wary): how much every rise is multiplied by.
var wary := 1.0

## Signs in memory: [look, time], oldest first.
var _memory: Array = []
## The clock, in seconds of advance().
var _clock := 0.0
## Seconds since the last sign or add.
var _idle := 0.0
## True while the value is at or past UNEASY_AT, so the uneasy signal fires once per rise.
var _is_uneasy := false


## One witnessed cast of `look`. Returns what it added to the value (0 for NONE; UNNATURAL knows at once and returns
## the rise to 100).
func sign(look: StringName) -> float:
	if known or look == NONE:
		return 0.0
	if look == UNNATURAL:
		var rise := KNOWN_AT - value
		know("an unnatural power")
		return rise
	if not BASE.has(look):
		return 0.0
	var same := 0
	var others := {}
	for e in _memory:
		if e[0] == look:
			same += 1
		else:
			others[e[0]] = true
	var added: float = BASE[look] * (1 + same) * (1.0 + OTHER_LOOKS * others.size()) * wary
	_memory.append([look, _clock])
	_rise(added)
	return added


## A flat rise of `points` (x wary), with no memory entry. The town knows at KNOWN_AT.
func add(points: float) -> void:
	if known:
		return
	_rise(points * wary)


## The town knows, now: value 100, the first reason wins.
func know(why: String) -> void:
	if known:
		return
	known = true
	reason = why
	value = KNOWN_AT
	_is_uneasy = true
	changed.emit()
	became_known.emit(why)


## The clock: memory forgets, and the value falls once the town has been left alone for CALM_DELAY.
func advance(delta: float) -> void:
	_clock += delta
	while not _memory.is_empty() and _clock - _memory[0][1] > MEMORY:
		_memory.pop_front()
	if known or value <= 0.0:
		return
	var before := _idle
	_idle += delta
	var fading := _idle - maxf(before, CALM_DELAY)
	if fading <= 0.0:
		return
	var was := int(value)
	value = maxf(0.0, value - fading * FADE)
	if value < UNEASY_AT:
		_is_uneasy = false
	if int(value) != was:
		changed.emit()


## &"calm", &"uneasy" (value at UNEASY_AT or more), or &"known".
func state() -> StringName:
	if known:
		return &"known"
	return &"uneasy" if value >= UNEASY_AT else &"calm"


## The signs in memory, newest last: [[look, seconds ago]].
func recent() -> Array:
	var out := []
	for e in _memory:
		out.append([e[0], _clock - e[1]])
	return out


## True when a death of `kind` is explained by weather or accident: the town does not know and the kind is in EXPLAINED.
func explains(kind: StringName) -> bool:
	return not known and EXPLAINED.has(kind)


## Back to a calm town that knows nothing (R restart, Crowd.clear()).
func reset() -> void:
	value = 0.0
	known = false
	reason = ""
	_memory.clear()
	_clock = 0.0
	_idle = 0.0
	_is_uneasy = false
	changed.emit()


## Raises the value by `points` and restarts the fade's wait; the town knows if that reaches KNOWN_AT.
func _rise(points: float) -> void:
	_idle = 0.0
	if value + points >= KNOWN_AT:
		know(REASON_SIGNS)
		return
	value += points
	if value >= UNEASY_AT and not _is_uneasy:
		_is_uneasy = true
		changed.emit()
		uneasy.emit()
		return
	changed.emit()
