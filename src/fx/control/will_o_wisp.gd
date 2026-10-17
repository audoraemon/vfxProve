class_name WillOWisp
extends FxTimeline
## Will-o'-Wisp (v0.06): a pale light hovers at the aim for WISP_TIME. Up to LURE_MAX citizens within LURE_REACH who
## are going about their day, watching, recovering or regrouping -- nearest first -- walk to it and stand staring in
## a loose ring (Person.lure()), then go back to their day. No danger and no alarm: curiosity. Gather a crowd, then
## strike it. It locks the other slots only while it is cast (busy).

const WISP_TIME := 12.0
const LURE_REACH := 6.0
const LURE_MAX := 25
## A director's charge (Person.answers_lure) answers only a Wisp cast this near him (v0.11.1, Decision 28): a Wisp cast to draw
## bystanders elsewhere does not pull him off his road.
const CHARGE_LURE_R := 3.0
## The ring the drawn stand in, round the light.
const RING := Vector2(0.8, 1.6)
const GLOW := [Color("e8fff4"), Color("9fe8d0"), Color("5cb8a8"), Color("2a6a6a")]
const LIGHT := Color(0.6, 1.0, 0.85)

var _light: QuadFx


## Who it would draw from `at`: people within reach it can lure (v0.11.1: soldiers at their post too; a charge only within CHARGE_LURE_R), nearest first, LURE_MAX at most.
static func drawn(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, LURE_REACH):
		var p := e as Person
		if p == null or p.resists_mind() or p.inside:
			continue
		if p.answers_lure:
			if p.ground_pos.distance_to(at) <= CHARGE_LURE_R and (p.mind == Person.Mind.DUTY or p.mind in Person.LURABLE):
				out.append(p)
		elif p.mind in Person.LURABLE or (p.soldier and p.mind in Person.SOLDIER_LURABLE and not p.hurrying):
			out.append(p)
	out.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(at) < b.ground_pos.distance_squared_to(at))
	return out.slice(0, LURE_MAX)


func _build() -> void:
	duration = WISP_TIME
	busy = 1.0
	var rng := ctx.rng
	for p in drawn(ctx.field, origin):
		var a := rng.randf() * TAU
		p.lure(origin + Vector2(cos(a), sin(a)) * rng.randf_range(RING.x, RING.y), WISP_TIME - 0.5, origin)
	ctx.play(&"grav_shimmer", origin, -12.0)
	_light = FxParts.ground_light(self, origin, 1.4, LIGHT, 0.0)
	var motes := FxParts.emitter(self, ctx.overhead, Iso.ground_to_screen(origin) + Vector2(0, -14),
		PixelParticles.Shape.SQUARE, GLOW, 6.0, WISP_TIME - 1.0,
		{"radius": 4.0, "speed": Vector2(2, 8), "alt": Vector2(0, 4), "alt_speed": Vector2(6, 14),
		"life": Vector2(0.8, 1.4), "size": Vector2(1, 1)})
	motes.gravity = -8.0


func _fade() -> float:
	return clampf(minf(t / 0.5, (duration - t) / 1.0), 0.0, 1.0)


## The light breathes with the orb, and the orb bobs and flickers.
func _fx_process(_delta: float) -> void:
	if is_instance_valid(_light):
		_light.set_param("intensity", 0.4 * _fade() * (0.85 + 0.15 * sin(t * 6.0)))
	queue_redraw()


func _draw() -> void:
	var fade := _fade()
	var at := Iso.ground_to_screen(origin) + Vector2(0, -14.0 + sin(t * 2.2) * 2.0)
	var flick := 0.85 + 0.15 * sin(t * 17.0) * sin(t * 5.3)
	for k in 4:
		var c: Color = GLOW[3 - k]
		c.a = fade * flick * (0.25 + 0.25 * k)
		draw_circle(at.round(), 7.0 - 1.6 * k, c)
