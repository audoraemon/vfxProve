extends SceneTree
## Dev check: a machine-independent digest of what a fixed script of hits does to the sandbox castle. Refactors
## of Structure or EnvironmentField must leave the digest untouched — it covers hp, scorch, frost, cracks, rubble
## shapes, collapse state, each building's random-number stream and what blocks walking. Unlike screenshots it
## does not depend on frame timing, so it is the gate for "the sandbox still behaves exactly as before".
## Usage: godot --headless --path . -s tools/dev/state_digest.gd

## Fixed hits: [kind of query, args...]. Mixed damage kinds, both queries, partial and lethal amounts.
func _init() -> void:
	var fx := Node2D.new()
	var env := EnvironmentField.new()
	env.fx_parent = fx
	env.fx_back = fx
	env.rng.seed = 7
	env.build_castle()
	env.damage_radius(Vector2(-5.5, -5.5), 2.0, 40.0, &"orbital")
	env.damage_radius(Vector2(0.0, 0.0), 4.0, 30.0, &"nova")
	env.damage_lane(Vector2(-6.0, 0.0), Vector2(1, 0), 1.2, 0.0, 6.0, &"laser")
	env.damage_radius(Vector2(-6.6, -6.6), 1.5, 99999.0, &"stone")
	env.damage_radius(Vector2(2.0, 2.0), 3.0, 55.0, &"ice")
	env.shake_radius(Vector2(0.0, 0.0), 8.0, 3.0)
	env.damage_radius(Vector2(4.8, 2.0), 1.0, 99999.0, &"gravity")
	env.damage_radius(Vector2(0.0, 0.0), 9.0, 10.0, &"wind")

	var rows := PackedStringArray()
	for s in env.structures():
		var rubble := 0.0
		for r in s._rubble:
			for p in r[0]:
				rubble += p.x * 1.7 + p.y * 2.3
		var cracks := 0.0
		for c in s._cracks:
			for p in c:
				cracks += p.x * 3.1 + p.y * 5.3
		rows.append("%d/%s/%.4f/%.4f/%.4f/%d/%.4f/%d/%.4f/%.4f/%s/%d" % [
			s.kind, s.destroyed, s.hp, s.scorch, s.frost, s._cracks.size(), cracks, s._rubble.size(), rubble,
			s._collapse, s._top_piece.is_empty(), s.rng.state % 1000000007])
	# Walkability map: 0/1 per probe point, so any change in blocked() shows up.
	var blocked := ""
	for i in 60:
		var p := Vector2(fposmod(i * 0.731, 14.0) - 7.0, fposmod(i * 0.377, 14.0) - 7.0)
		blocked += "1" if env.blocked(p) else "0"
	print("rows=", rows.size())
	print("digest=", "|".join(rows).md5_text())
	print("blocked=", blocked)
	print("emitters=", fx.get_child_count())
	env.clear()
	env.free()
	fx.free()
	quit()
