class_name VisitorVoices
extends RefCounted
## The hellhounds, demons and ghosts that Hound Gate and Doors of the Dead let into the town, heard while they roam
## (skill-tree sound audit, Passage). The power that owns the Visitors steps this beside them: each living visitor
## speaks on a clock of its own, EVERY[breed] seconds apart give or take -- a hellhound snarls and pants on the hunt, a
## demon grunts and sniggers, a ghost moans -- sooner (HUNT_SOONER) and louder when it has someone in its sights than
## when it wanders (WANDER_DB). Its bite (a demon's claws, also on a wall; a ghost's touch) has a sound of its own. It
## draws from its own rng and only reads where the visitors are and whom they chase, so the hunt is the same whether or
## not anyone listens. Token budgets (TOKENS and BITE_TOKENS, refilled REFILL and BITE_REFILL a second) keep a district
## full of the dead from drowning the town.

const ROAM := {Animal.Breed.HELLHOUND: &"hound_roam", Animal.Breed.DEMON: &"demon_roam", Animal.Breed.GHOST: &"ghost_roam"}
const BITE := {Animal.Breed.HELLHOUND: &"hound_bite", Animal.Breed.DEMON: &"demon_claw", Animal.Breed.GHOST: &"ghost_touch"}
## Seconds between one visitor's sounds, drawn between x and y.
const EVERY := {Animal.Breed.HELLHOUND: Vector2(2.0, 4.5), Animal.Breed.DEMON: Vector2(3.0, 6.0),
	Animal.Breed.GHOST: Vector2(3.5, 7.0)}
const HUNT_SOONER := 0.6
const WANDER_DB := -3.0
const TOKENS := 3.0
const REFILL := 1.2
const BITE_TOKENS := 4.0
const BITE_REFILL := 3.0
const SEED := 6160

var played := 0  ## roaming sounds handed out
var bites := 0  ## bite sounds handed out

var _rng := RandomNumberGenerator.new()
var _tokens := TOKENS
var _bite_tokens := BITE_TOKENS
var _next := {}  ## visitor instance id -> seconds until it speaks


func _init() -> void:
	_rng.seed = SEED


## One tick: every visitor in `living` whose clock has run out speaks through `play` (cue, ground position, dB
## offset -- an FxContext's play). A visitor new to the list waits a full clock first: it has just come through with a
## cry of its own.
func step(delta: float, living: Array, play: Callable) -> void:
	_tokens = minf(TOKENS, _tokens + REFILL * delta)
	_bite_tokens = minf(BITE_TOKENS, _bite_tokens + BITE_REFILL * delta)
	var seen := {}
	for a: Animal in living:
		if not is_instance_valid(a) or not ROAM.has(a.breed):
			continue
		var id := a.get_instance_id()
		seen[id] = true
		if not _next.has(id):
			_next[id] = _wait(a)
			continue
		_next[id] = float(_next[id]) - delta
		if float(_next[id]) > 0.0:
			continue
		_next[id] = _wait(a)
		if _tokens < 1.0:
			continue
		_tokens -= 1.0
		played += 1
		play.call(ROAM[a.breed], a.ground_pos, 0.0 if a.target != null else WANDER_DB)
	for id in _next.keys():
		if not seen.has(id):
			_next.erase(id)


## Visitor `a` bit someone (or a demon struck a wall): its bite's sound through `play`, when the budget allows.
func bite(a: Animal, play: Callable) -> void:
	if a == null or not is_instance_valid(a) or not BITE.has(a.breed) or _bite_tokens < 1.0:
		return
	_bite_tokens -= 1.0
	bites += 1
	play.call(BITE[a.breed], a.ground_pos, 0.0)


func _wait(a: Animal) -> float:
	var span: Vector2 = EVERY[a.breed]
	return _rng.randf_range(span.x, span.y) * (HUNT_SOONER if a.target != null else 1.0)
