extends RefCounted
## A test-only overrides file (v0.12 Task 4): the shape CityDef.mission_overrides() loads.


static func overrides() -> Dictionary:
	return {"def": {"camera_at": Vector2(1.0, 2.0)}, "director": {"hide_seconds": 31.0}}
