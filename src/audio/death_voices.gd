class_name DeathVoices
extends RefCounted
## A death you can hear (v0.11.2, spec 2.2). Crowd asks heard() once for every body that falls and plays what comes back.
## Pure logic: it draws no random number, reads no person and changes nothing the simulation reads, so the digest and
## every checksum stand whether or not anyone listens. Headless it only counts (voiced, waves).
##
## A cue is a cry and a fall (cit_death), a grunt, mail and a fall (sol_death), or -- for the quiet kinds -- a body's
## slump with no cry (cit_fall): an unseen death must not shout. Deaths within WAVE_WINDOW of a wave's first are one
## wave: the first WAVE_VOICES of them are voiced, in the order they fall, and the MASS_AT-th loud one adds one
## crowd_death_wave at the mean of the deaths so far. A token budget (TOKENS, refilled REFILL a second) caps the rate
## across waves.

## The kinds of death nobody should hear cry out (Silent Doom, the Death Mark, the plague).
const QUIET_KINDS := [&"doom", &"deathmark", &"plague"]
## Deaths this close after a wave's first belong to it, seconds.
const WAVE_WINDOW := 0.25
## How many bodies of one wave are voiced.
const WAVE_VOICES := 3
## Loud deaths in one wave that make the crowd's roar.
const MASS_AT := 6
## The rate cap across waves: a budget of this many cues, refilled this many a second.
const TOKENS := 4.0
const REFILL := 3.0

var voiced := 0  ## cues handed out for a body (cries, grunts and falls; not the roar)
var waves := 0  ## mass waves seen (MASS_AT loud deaths inside one window)

var _tokens := TOKENS
var _wave_at := -INF  ## the clock of the wave's first death
var _wave_voiced := 0
var _wave_loud := 0
var _wave_sum := Vector2.ZERO  ## ground positions of the loud deaths so far


## The cues to play for a death at `at` (ground position) of damage `kind`, at crowd clock `now`: [[cue, position], ...],
## often empty.
func heard(at: Vector2, kind: StringName, soldier: bool, now: float) -> Array:
	var out := []
	if now - _wave_at > WAVE_WINDOW or now < _wave_at:
		_wave_at = now
		_wave_voiced = 0
		_wave_loud = 0
		_wave_sum = Vector2.ZERO
	var quiet := QUIET_KINDS.has(kind)
	if _wave_voiced < WAVE_VOICES and _tokens >= 1.0:
		_tokens -= 1.0
		_wave_voiced += 1
		voiced += 1
		var cue := &"cit_fall" if quiet else (&"sol_death" if soldier else &"cit_death")
		out.append([cue, at])
	if not quiet:
		_wave_loud += 1
		_wave_sum += at
		if _wave_loud == MASS_AT:
			waves += 1
			if _tokens >= 1.0:
				_tokens -= 1.0
				out.append([&"crowd_death_wave", _wave_sum / float(_wave_loud)])
	return out


## Refills the budget; `delta` is crowd time.
func step(delta: float) -> void:
	_tokens = minf(TOKENS, _tokens + REFILL * delta)


func reset() -> void:
	voiced = 0
	waves = 0
	_tokens = TOKENS
	_wave_at = -INF
	_wave_voiced = 0
	_wave_loud = 0
	_wave_sum = Vector2.ZERO
