class_name RazeDirector
extends MissionDirector
## The Raze type (v0.11 M2, spec §7.1), generalised from Last Judgement's director: destroy the named structures. A target
## counts as razed once destroyed or -- with `spoil_seconds` above 0 -- once it has burned that long in all, and stays razed.
## A subclass may seal a target (optional, off by default: nothing is sealed unless seal() is called): stone to every power
## (Structure.damage_filter: it only shakes) and any fire on it smothered at once, until unseal(). A subclass names the targets
## and runs the town's answer (HarvestDirector: the watchmen and the carts). Last Judgement keeps its own director: the
## Citadel's nine parts judge themselves.

## The map tags' colours (v0.11 M2): an open target gold, a burning one orange, a sealed one grey; danger red.
const MARK_TARGET := Color("d8b23a")
const MARK_BURNING := Color("ff9a3a")
const MARK_SEALED := Color("9a948a")
const MARK_WATCHED := Color("c8342a")
## How hard a blow shakes a sealed target (v0.11 M2).
const SEALED_SHAKE := 2.0

## The structures to raze, in order (v0.11 M2).
var targets: Array[Structure] = []
## Seconds of burning, in all, that raze a target; 0: only its fall does (v0.11 M2).
var spoil_seconds := 0.0
## Structure -> seconds it has burned (v0.11 M2).
var _burned := {}
## Structure -> true while sealed (v0.11 M2).
var _sealed := {}
## Structure -> true once razed (v0.11 M2).
var _razed := {}


## Seals `s` (v0.11 M2): every blow only shakes it, and any fire on it is smothered (_judge_targets()).
func seal(s: Structure) -> void:
	_sealed[s] = true
	s.damage_filter = _sealed_hit


## Opens `s` (v0.11 M2): it takes blows and fire as any building does.
func unseal(s: Structure) -> void:
	_sealed.erase(s)
	if is_instance_valid(s):
		s.damage_filter = Callable()


## Whether `s` stands sealed (v0.11 M2).
func is_sealed(s: Structure) -> bool:
	return _sealed.has(s)


## Structure.damage_filter for a sealed target (v0.11 M2): the blow only shakes it.
func _sealed_hit(s: Structure, _amount: float, _source: Vector2, _kind: StringName) -> void:
	s.shake(SEALED_SHAKE)


## `s`'s burning so far is forgotten (v0.11 M2): a fire beaten out for good (HarvestDirector's watchman) leaves nothing toward
## its spoiling.
func forget_burn(s: Structure) -> void:
	_burned.erase(s)


## Whether `s` has been razed (v0.11 M2).
func razed(s: Structure) -> bool:
	return _razed.has(s)


## How many targets have been razed (v0.11 M2).
func razed_count() -> int:
	return _razed.size()


## Whether every target is razed (v0.11 M2); false with none.
func all_razed() -> bool:
	return not targets.is_empty() and _razed.size() >= targets.size()


## Seconds `s` has burned toward its spoiling, in all (v0.11 M2).
func burned(s: Structure) -> float:
	return float(_burned.get(s, 0.0))


## Whether `s` is alight now (v0.11 M2).
func burning(s: Structure) -> bool:
	return crowd.fires != null and is_instance_valid(s) and crowd.fires.is_burning(s)


## Virtual (v0.11 M2): why the night is lost now ("" while it is not): HarvestDirector's "emptied".
func lost_reason() -> String:
	return ""


## Virtual (v0.11 M2): `s` has just been razed.
func _on_razed(_s: Structure) -> void:
	pass


## One step (v0.11 M2): the timeline, then each target judged.
func step(delta: float) -> void:
	if timeline != null:
		timeline.step(delta)
	_judge_targets(delta)


## Each target not yet razed (v0.11 M2): one fallen is razed (a sealed one is stone to every power, but the director leaves
## none to stand sealed with its building gone); a sealed one's fire is smothered; an open one is razed once it has burned
## `spoil_seconds` in all.
func _judge_targets(delta: float) -> void:
	for s in targets:
		if _razed.has(s):
			continue
		if not is_instance_valid(s) or s.destroyed:
			_raze(s)
		elif _sealed.has(s):
			if burning(s):
				crowd.fires._put_out(s, true)
		elif burning(s):
			_burned[s] = burned(s) + delta
			if spoil_seconds > 0.0 and burned(s) >= spoil_seconds:
				_raze(s)


## `s` is razed (v0.11 M2): it stays so.
func _raze(s: Structure) -> void:
	_razed[s] = true
	_on_razed(s)


## Lets go of the timeline (v0.11 M2).
func teardown() -> void:
	timeline = null  # its banner and guard lambdas hold this director: let both go
