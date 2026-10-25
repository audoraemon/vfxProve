extends RefCounted
## The natural light trial's nodes (DAY and NIGHT only): CURRENT creates none of them, and they sit in their layer order:
## the light map's buffer, the grade (1), the glow (2), then Battlefield's glow layer (3).


static func run(t) -> void:
	_current_creates_none(t)
	_bloom(t)


static func _build(look: Town.Look) -> Array:
	var env := EnvironmentField.new()
	env.lights = LightField.new()
	var ground := Node2D.new()
	var town := Town.new()
	town.look = look
	town.build(env, ground)
	return [town, env, ground]


static func _free(parts: Array) -> void:
	var town: Town = parts[0]
	var env: EnvironmentField = parts[1]
	var lights := env.lights
	town.teardown()
	town.free()
	env.clear()
	env.free()
	(parts[2] as Node).free()
	lights.free()


static func _find(town: Town, script: GDScript) -> Node:
	for n in town.look_nodes():
		if is_instance_of(n, script):
			return n
	return null


## Every node in the subtree of `n`, `n` included.
static func _count_all(n: Node, script: GDScript) -> int:
	var k := 1 if is_instance_of(n, script) else 0
	for c in n.get_children():
		k += _count_all(c, script)
	return k


static func _current_creates_none(t) -> void:
	var parts := _build(Town.Look.CURRENT)
	var town: Town = parts[0]
	var ground: Node2D = parts[2]
	t.check(town.look_nodes().is_empty(), "CURRENT adds no look nodes")
	var trial := 0
	for script: GDScript in [TownPools, TownGrade, TownBloom]:
		trial += _count_all(town, script) + _count_all(ground, script)
	t.check(trial == 0, "CURRENT builds no light map, grade or glow (%d)" % trial)
	_free(parts)


static func _bloom(t) -> void:
	for look: Town.Look in [Town.Look.DAY, Town.Look.NIGHT]:
		var parts := _build(look)
		var town: Town = parts[0]
		var grade := _find(town, TownGrade) as TownGrade
		var bloom := _find(town, TownBloom) as TownBloom
		t.check(bloom != null and grade != null, "%s has a glow" % Town.Look.keys()[look])
		if bloom != null and grade != null:
			t.check(grade.layer < bloom.layer and bloom.layer < Battlefield.GLOW_LAYER,
				"grade %d < glow %d < Battlefield glow %d" % [grade.layer, bloom.layer, Battlefield.GLOW_LAYER])
			t.check((bloom.mat.shader as Shader).code.contains("blend_add"), "the glow only adds light (the art under it stays sharp)")
		_free(parts)
	var day := TownLook.bloom(Town.Look.DAY)
	var night := TownLook.bloom(Town.Look.NIGHT)
	t.check(float(night.strength) > float(day.strength) and float(night.threshold) < float(day.threshold),
		"NIGHT glows more strongly, and from dimmer pixels, than DAY")
