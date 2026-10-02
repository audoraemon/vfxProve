class_name SilentDoom
extends FxTimeline
## Silent Doom (v0.05): a quiet death. A dark wisp gathers over everyone within RADIUS of the aim (v0.07.1; before,
## the nearest three), and they fall without a sound past a whisper and with no danger for the town to see -- no threat
## is registered and no alarm raised (Crowd.on_cast() skips quiet powers). The victims are fixed at the cast and fall
## T_STRIKE later, except anyone who has gone inside by then (a boat, a shelter). Whether anyone saw it, Crowd decides
## once they have all fallen (Crowd.DOOM_WITNESS): a witness panics, and then each death counts like any other.

const RADIUS := 0.8
const T_STRIKE := 0.45
const WISP := [Color("0e0b12"), Color("231c2c"), Color("3a3048"), Color("4d4060")]


## Who the doom would take at `at`: every living person within RADIUS (v0.07.1: no cap), nearest first.
static func victims_at(field: EnemyField, at: Vector2) -> Array[DummyEnemy]:
	var near := field.in_radius(at, RADIUS)
	near.sort_custom(func(a: DummyEnemy, b: DummyEnemy) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return near


func _build() -> void:
	duration = 1.4
	var victims := victims_at(ctx.field, origin)
	ctx.play(&"grav_shimmer", origin, -10.0)
	for v in victims:
		_wisp(Iso.ground_to_screen(v.ground_pos))
	if victims.is_empty():
		_wisp(Iso.ground_to_screen(origin))
	at(T_STRIKE, func() -> void:
		for v in victims:
			if not is_instance_valid(v):
				continue
			var person := v as Person
			if person != null and person.inside:
				continue  # boarded a boat or took shelter since the cast: out of reach, hidden away
			ctx.field.kill(v, &"doom", origin))


## A dark wisp: smoke that curls down onto the spot, then a faint puff as it takes them.
func _wisp(screen: Vector2) -> void:
	var down := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, WISP)
	down.drag = 1.2
	down.gravity = 60.0
	down.burst(14, {"radius": 7.0, "speed": Vector2(4, 14), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(18, 30),
		"alt_speed": Vector2(-30, -10), "life": Vector2(0.4, 0.7), "size": Vector2(2, 4), "size_end_mul": 0.4})
	at(T_STRIKE, func() -> void:
		var puff := FxParts.particles(self, ctx.overhead, screen, PixelParticles.Shape.PUFF, WISP)
		puff.drag = 2.0
		puff.gravity = -25.0
		puff.burst(10, {"radius": 3.0, "speed": Vector2(6, 20), "dir": PixelParticles.Dir.OUTWARD, "alt": Vector2(2, 8),
			"alt_speed": Vector2(4, 16), "life": Vector2(0.5, 0.9), "size": Vector2(2, 3), "size_end_mul": 1.6}))
