class_name MadnessBloomFx
extends FxTimeline
## Madness Bloom (Disorder): a small circle of RADIUS. Everyone in it catches a madness that starts at SEED and grows
## on its own (MadnessManager: Uneasy, Disturbed, Unstable, Broken; the crowd steps it), unless they resist. Nothing
## happens to them now: the cast is almost nothing to see -- a shiver in the air, a breath of dark motes drawn in --
## and unsettles the town only by its book entry's "alarm". The chaos comes later, and the alarm with it. The cast
## locks the other slots for 0.8 s.

const RADIUS := 1.5
const SEED := 0.02
const DUSK := [Color("3a1838"), Color("6a2a58"), Color("a04060"), Color(0.2, 0.05, 0.15, 0.5)]
const DUSK_LIGHT := Color(0.45, 0.15, 0.35)

## Who caught it.
var afflicted: Array[Person] = []
var resisted := 0


## Who it would take at `at`: everyone living in the circle, out in the open, not yet mad.
static func victims_at(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p != null and not p.inside and not p.statuses.has(MadnessManager.STATUS):
			out.append(p)
	return out


func _build() -> void:
	duration = 1.8
	busy = 0.8
	for p in victims_at(ctx.field, origin):
		if MadnessManager.resists(p, ctx.rng):
			resisted += 1
			continue
		p.statuses[MadnessManager.STATUS] = SEED
		afflicted.append(p)
	ctx.play(&"grav_field", origin, -16.0)
	if ctx.impact == null or not is_inside_tree():
		return
	var sp := Iso.ground_to_screen(origin)
	var haze := FxParts.heat_haze(self, sp, FxParts.particle_radius(RADIUS), 1.2)
	haze.set_param("speed", 1.5)
	haze.tween_param("strength", 1.2, 0.0, 1.4, 0.3)
	haze.life = 1.75
	var dusk := FxParts.ground_light(self, origin, RADIUS * 1.2, DUSK_LIGHT, 0.5)
	dusk.tween_param("intensity", 0.5, 0.0, 1.5)
	var motes := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, DUSK)
	motes.drag = 0.6
	motes.gravity = -12.0
	motes.burst(26, {"radius": FxParts.particle_radius(RADIUS), "speed": Vector2(10, 30), "dir": PixelParticles.Dir.INWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(2, 10), "life": Vector2(0.7, 1.3), "size": Vector2(1, 2)})
