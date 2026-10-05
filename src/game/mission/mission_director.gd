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
## The night this act belongs to (v0.09), or null for a single mission.
var night: NightState
## The act's timed events (v0.09), or null.
var timeline: EventTimeline
## Halcyon's Gaze (v0.10), for the campaign's Night 2 missions; null elsewhere.
var gaze: GazeMeter


func setup(r: Rules, c: Crowd, t: Town, x: FxContext, n: NightState = null) -> MissionDirector:
	rules = r
	crowd = c
	town = t
	ctx = x
	night = n
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


## Ground points the HUD marks with a small coloured diamond over the head (v0.10: Mira's House's grieving and
## Believers), as [Vector2, Color] pairs; none by default.
func marks() -> Array:
	return []


## What the director adds to the results (The Warning's "solved_by").
func report() -> Dictionary:
	return {}


## Virtual: what this act hands the next one, written into the night before the director is let go (v0.09).
func carry(_n: NightState) -> void:
	pass


## Virtual: let go of the world's signals.
func teardown() -> void:
	pass
