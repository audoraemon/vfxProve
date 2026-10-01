class_name PestilenceFx
extends FxTimeline
## Pestilence (v0.06): a green miasma settles on up to INFECT_MAX citizens within INFECT_R of the aim, nearest first,
## and they catch the plague (Person.infect(); PlagueManager spreads it and ends it). Quiet when cast: the sickness is
## not seen as a danger, though every death it brings is an ordinary death. Soldiers do not catch it. The cast locks
## the other slots for 0.8 s.

const INFECT_MAX := 3
const INFECT_R := 1.2
const MIASMA := [Color("d0f090"), Color("90b050"), Color("5a7a30"), Color("2a3a18")]


## Who it would infect at `at`: the nearest healthy citizens within reach, INFECT_MAX at most.
static func victims_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, INFECT_R):
		var p := e as Person
		if p != null and not p.soldier and not p.inside and p.sick_left <= 0.0:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, INFECT_MAX)


func _build() -> void:
	duration = 1.4
	busy = 0.8
	ctx.play(&"grav_suction", origin, -12.0)
	var victims := victims_at(ctx.field, origin)
	var spots: Array[Vector2] = [origin]
	for p in victims:
		spots.append(p.ground_pos)
	for g in spots:
		var puff := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(g), PixelParticles.Shape.PUFF, MIASMA)
		puff.drag = 1.4
		puff.gravity = -14.0
		puff.burst(10, {"radius": 5.0, "speed": Vector2(4, 14), "alt": Vector2(2, 12), "alt_speed": Vector2(2, 10),
			"life": Vector2(0.7, 1.2), "size": Vector2(2, 4), "size_end_mul": 1.8})
	at(0.4, func() -> void:
		for p in victims:
			if is_instance_valid(p):
				p.infect(PlagueManager.PLAGUE_LIFE))
