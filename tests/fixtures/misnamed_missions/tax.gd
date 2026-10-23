extends RefCounted
## A deliberately misnamed overrides file (C6): the Tax Collector's id is tax_collector, so nothing finds this one.


static func overrides() -> Dictionary:
	return {"def": {"camera_at": Vector2(1.0, 2.0)}}
