class_name DiscordFx
extends FxTimeline
## Discord (v0.06): a violet swirl at the aim, and every citizen within DISCORD_R forgets what it was doing for
## DISCORD_TIME (Person.confuse()) -- clergy step out of the rite's ring, the bellkeeper drops the climb, engineers
## down tools, fire crews leave the fire, evacuees stop in the queue and wander. Then they pick up again. No danger and
## no alarm; soldiers keep their heads. The cast locks the other slots for 0.6 s.

const DISCORD_R := 1.2
const DISCORD_TIME := 15.0
const SWIRL := [Color("f0d8ff"), Color("c890ff"), Color("8a50d0"), Color("4a2a70")]


## Who it would take at `at`: the living citizens within reach.
static func taken(field: EnemyField, at: Vector2) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, DISCORD_R):
		var p := e as Person
		if p != null and not p.soldier and not p.inside:
			out.append(p)
	return out


func _build() -> void:
	duration = 1.2
	busy = 0.6
	ctx.play(&"grav_shimmer", origin, -8.0)
	var swirl := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(origin), PixelParticles.Shape.SQUARE, SWIRL)
	swirl.drag = 0.6
	swirl.gravity = -30.0
	swirl.burst(28, {"radius": 26.0, "speed": Vector2(20, 40), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(4, 18),
		"alt_speed": Vector2(4, 16), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	for p in taken(ctx.field, origin):
		p.confuse(DISCORD_TIME)
