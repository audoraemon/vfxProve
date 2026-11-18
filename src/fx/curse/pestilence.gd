class_name PestilenceFx
extends FxTimeline
## Pestilence (v0.06): a green miasma settles on up to INFECT_MAX people within INFECT_R of the aim, nearest first,
## and they catch the plague (Person.infect(); PlagueManager spreads it and ends it). Quiet when cast: the sickness is
## not seen as a danger, though every death it brings is an ordinary death. Soldiers catch it too (v0.07.1). The cast
## locks the other slots for 0.8 s.

const INFECT_MAX := 3
const INFECT_R := 1.2
const MIASMA := [Color("d0f090"), Color("90b050"), Color("5a7a30"), Color("2a3a18")]


## Who it would infect at `at`: the nearest healthy people within reach, soldiers too, INFECT_MAX at most.
static func victims_at(field: EnemyField, at: Vector2, r := INFECT_R, most := INFECT_MAX) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and not p.inside and p.sick_left <= 0.0:
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, most)


## This cast's reach and count at its ability level (INFECT_R and INFECT_MAX at level 1).
var lv_infect_r := INFECT_R
var lv_infect_max := INFECT_MAX
## Level 5, Foul Dead: whether this cast's plague leaves a foul spot where its sick die (PlagueManager.foul_from).
var _twist := false


func _build() -> void:
	_twist = PowerBook.twist_at(extra, "pestilence")
	lv_infect_r = float(PowerBook.stat(extra, "pestilence", "INFECT_R", INFECT_R))
	lv_infect_max = int(PowerBook.stat(extra, "pestilence", "INFECT_MAX", INFECT_MAX))
	duration = 1.4
	busy = 0.8
	ctx.play(&"q_pestilence", origin)
	var victims := victims_at(ctx.field, origin, lv_infect_r, lv_infect_max)
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
			if is_instance_valid(p) and p.infect(PlagueManager.PLAGUE_LIFE) and _twist:
				p.plague_src = get_instance_id()
		if _twist and ctx.crowd != null and ctx.crowd.plague != null:
			# The plague outlives this node by design: the line stays foul in PlagueManager.foul (one id per level-5 cast).
			ctx.crowd.plague.foul_from(get_instance_id()))
