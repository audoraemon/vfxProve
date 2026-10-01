class_name BlightFx
extends FxTimeline
## Blight (v0.05): a quiet ruin. The nearest structure with a use within REACH of the aim -- a well or a fountain, the
## Bell Tower, a gate or the postern, the dock, the cathedral -- rots grey-green and its use is gone
## (EnvironmentField.blight(); the town's responses read Structure.blighted). Nothing falls and nobody runs: it only
## adds Crowd.BLIGHT_ALARM. With nothing of use in reach it fizzles.

const REACH := 1.0
const T_ROT := 0.8
const ROT := [Color("1c2416"), Color("3a4a2a"), Color("5c6a3a"), Color("8a9658")]


## Whether Blight has anything to ruin in `s`.
static func blightable(s: Structure) -> bool:
	return s.kind == Structure.Kind.FOUNTAIN or s.kind == Structure.Kind.GATE or s.art_tag == &"bell_tower" \
		or s.role == &"dock" or s.role == &"temple"


## What Blight would ruin at `at`: the nearest standing, unblighted structure it can, or null.
static func target(env: EnvironmentField, at: Vector2) -> Structure:
	var best: Structure = null
	var best_d := REACH
	for s in env.structures():
		if not is_instance_valid(s) or s.destroyed or s.blighted or not blightable(s):
			continue
		var d := s.distance_to(at)
		if d <= best_d:
			best_d = d
			best = s
	return best


func _build() -> void:
	duration = 1.6
	var s := target(ctx.env, origin)
	var where := s.center() if s != null else origin
	var screen := Iso.ground_to_screen(where)
	ctx.play(&"grav_field", where, -12.0)
	var gather := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, ROT)
	gather.drag = 1.0
	gather.gravity = -10.0
	gather.burst(22, {"radius": 26.0, "speed": Vector2(14, 34), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(2, 14),
		"alt_speed": Vector2(0, 10), "life": Vector2(0.6, 0.9), "size": Vector2(2, 4), "size_end_mul": 0.5})
	at(T_ROT, func() -> void:
		var spores := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.SQUARE, ROT)
		spores.gravity = -18.0
		spores.drag = 0.8
		spores.burst(16, {"radius": 18.0, "speed": Vector2(2, 8), "alt": Vector2(0, 20), "alt_speed": Vector2(4, 14),
			"life": Vector2(0.6, 0.8), "size": Vector2(1, 2)})
		if s != null and is_instance_valid(s) and not s.destroyed:
			ctx.env.blight(s))
