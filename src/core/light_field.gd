class_name LightField
extends Node
## Dynamic effect lights in ground space. Effects' ground light pools register here automatically,
## so buildings and enemies can be lit by explosions, beams and void glow.

## Each light: {pos, radius, color, intensity, life, quad, getter}
var _lights: Array[Dictionary] = []
## World ambient 0..1 (1 = normal). Lowered while effects dim the scene; lit things multiply by it.
var ambient := 1.0
## Colour of the world's own light, multiplied into everything lit (the town's warm evening, Town.EVENING).
## White by default, so the sandbox looks as it always has.
var tint := Color.WHITE
var _next_id := 1
var _time := 0.0


## Follow a QuadFx light pool: intensity is read from its shader each frame; position from
## `center` or `getter` (Callable returning a ground Vector2) when the light moves.
func register_quad(quad: QuadFx, center: Vector2, radius: float, color: Color, getter := Callable()) -> void:
	_lights.append({"pos": center, "radius": radius, "color": color, "intensity": 0.0, "life": -1.0,
		"quad": quad, "getter": getter})


## Short light that fades out linearly over `seconds`.
func pulse(center: Vector2, radius: float, color: Color, intensity: float, seconds: float) -> void:
	_lights.append({"pos": center, "radius": radius, "color": color, "intensity": intensity,
		"life": seconds, "start": intensity, "duration": seconds, "quad": null, "getter": Callable()})


## Persistent light (torches, braziers) with optional flicker 0..1. Returns an id for remove().
func add_static(center: Vector2, radius: float, color: Color, intensity: float, flicker := 0.0) -> int:
	var id := _next_id
	_next_id += 1
	_lights.append({"pos": center, "radius": radius, "color": color, "intensity": intensity, "base": intensity,
		"life": -1.0, "static": true, "id": id, "flicker": flicker, "quad": null, "getter": Callable()})
	return id


func remove(id: int) -> void:
	_lights = _lights.filter(func(l): return l.get("id", 0) != id)


func clear() -> void:
	_lights.clear()


func _process(delta: float) -> void:
	_time += delta
	var keep: Array[Dictionary] = []
	for l in _lights:
		if l.get("static", false):
			var f: float = l.flicker
			l.intensity = l.base * (1.0 - f * 0.25 + f * 0.25 * sin(_time * 13.0 + l.id * 1.7) * sin(_time * 7.3 + l.id))
		elif l.quad != null:
			if not is_instance_valid(l.quad):
				continue
			var v = l.quad.mat.get_shader_parameter("intensity")
			l.intensity = float(v) if v != null else 0.0
			if l.getter.is_valid():
				l.pos = l.getter.call()
		else:
			l.life -= delta
			if l.life <= 0.0:
				continue
			l.intensity = l.start * l.life / l.duration
		keep.append(l)
	_lights = keep


## Summed light color at a ground point (quadratic falloff to zero at each light's radius).
func sample(g: Vector2) -> Color:
	var r := 0.0
	var gr := 0.0
	var b := 0.0
	for l in _lights:
		var w := _weight(l, g)
		if w > 0.0:
			r += l.color.r * w
			gr += l.color.g * w
			b += l.color.b * w
	return Color(r, gr, b, 1.0)


## Weighted ground direction from `g` toward the lights (not normalized; length ~ strength).
func sample_dir(g: Vector2) -> Vector2:
	var dir := Vector2.ZERO
	for l in _lights:
		var w := _weight(l, g)
		if w > 0.0:
			var to: Vector2 = l.pos - g
			dir += (to.normalized() if to.length() > 0.01 else Vector2.ZERO) * w
	return dir


## Quantized light color and direction at `g` folded into one int: equal values shade a Structure
## identically. One pass over the lights and no allocation, because every building asks every frame.
func sample_signature(g: Vector2, color_steps: float, dir_steps: float) -> int:
	var r := 0.0
	var gr := 0.0
	var b := 0.0
	var dir := Vector2.ZERO
	for l in _lights:
		var intensity: float = l.intensity
		if intensity <= 0.0:
			continue
		var to: Vector2 = l.pos - g
		var radius: float = l.radius
		var d2 := to.length_squared()
		if d2 >= radius * radius:
			continue
		var dist := sqrt(d2)
		var w := pow(1.0 - dist / radius, 1.4) * intensity
		var col: Color = l.color
		r += col.r * w
		gr += col.g * w
		b += col.b * w
		if dist > 0.01:
			dir += (to / dist) * w
	var sig := int(r * color_steps)
	sig = sig * 1021 + int(gr * color_steps)
	sig = sig * 1021 + int(b * color_steps)
	sig = sig * 1021 + int(dir.x * dir_steps)
	return sig * 1021 + int(dir.y * dir_steps)


func _weight(l: Dictionary, g: Vector2) -> float:
	var intensity: float = l.intensity
	if intensity <= 0.0:
		return 0.0
	var radius: float = l.radius
	# Compare squared distances first: most lights are out of range, and this skips their sqrt and pow.
	var d2 := g.distance_squared_to(l.pos)
	if d2 >= radius * radius:
		return 0.0
	return pow(1.0 - sqrt(d2) / radius, 1.4) * intensity
