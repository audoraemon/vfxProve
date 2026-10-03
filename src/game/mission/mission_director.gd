class_name MissionDirector
extends RefCounted
## A mission's own actors and setup (v0.08): Rules steps it every frame of the mission, just before the objectives are
## checked, so it pauses and freezes with the mission. Last Judgement has none; The Warning's runs the omen, the
## watchman and the relay (WarningDirector).

var rules: Rules
var crowd: Crowd
var town: Town
## The battlefield's effect context, for the director's own effects (null in tests).
var ctx: FxContext


func setup(r: Rules, c: Crowd, t: Town, x: FxContext) -> MissionDirector:
	rules = r
	crowd = c
	town = t
	ctx = x
	_begin()
	return self


## Virtual: the mission's setup, once the town and its people exist.
func _begin() -> void:
	pass


## Virtual: one step of the mission.
func step(_delta: float) -> void:
	pass


## The ground point the HUD marks (The Warning's messenger), or Vector2.INF for none.
func marker() -> Vector2:
	return Vector2.INF


## What the director adds to the results (The Warning's "solved_by").
func report() -> Dictionary:
	return {}


## Virtual: let go of the world's signals.
func teardown() -> void:
	pass
