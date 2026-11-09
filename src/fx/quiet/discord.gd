class_name DiscordFx
extends FxTimeline
## Discord (v0.06): a violet swirl at the aim, and every citizen within DISCORD_R forgets what it was doing for
## DISCORD_TIME (Person.confuse()) -- clergy step out of the rite's ring, the bellkeeper drops the climb, engineers
## down tools, fire crews leave the fire, evacuees stop in the queue and wander. Then they pick up again. No danger and
## no alarm; soldiers lose theirs as citizens do (v0.11.1) and go back to their posts. The cast locks the other slots for 0.6 s.

const DISCORD_R := 1.2
const DISCORD_TIME := 15.0
## Tangled Threads (level 5): for TANGLE_TIME seconds after the cast, every TANGLE_EVERY seconds, anyone within TANGLE_R of a person this cast confused
## who is still confused is confused for the full forgetting too. The caught pass nothing on.
const TANGLE_TIME := 5.0
const TANGLE_EVERY := 0.1
const TANGLE_R := 1.0
const SWIRL := [Color("f0d8ff"), Color("c890ff"), Color("8a50d0"), Color("4a2a70")]


## Who it would take at `at`: the living within reach, soldiers too.
static func taken(field: EnemyField, at: Vector2, r := DISCORD_R) -> Array[Person]:
	var out: Array[Person] = []
	for e in field.in_radius(at, r):
		var p := e as Person
		if p != null and not p.resists_mind() and not p.inside:
			out.append(p)
	return out


## This cast's circle and forgetting at its ability level (DISCORD_R and DISCORD_TIME at level 1).
var lv_discord_r := DISCORD_R
var lv_discord_time := DISCORD_TIME
## Tangled Threads: those the cast itself confused, those the threads caught since, and when the threads last ran.
var confused: Array[Person] = []
var caught := {}
var _tangle := false
var _last_scan := 0.0


func _build() -> void:
	lv_discord_r = float(PowerBook.stat(extra, "discord", "DISCORD_R", DISCORD_R))
	lv_discord_time = float(PowerBook.stat(extra, "discord", "DISCORD_TIME", DISCORD_TIME))
	duration = 1.2
	busy = 0.6
	ctx.play(&"q_discord", origin)
	var swirl := FxParts.particles(self, ctx.overhead, Iso.ground_to_screen(origin), PixelParticles.Shape.SQUARE, SWIRL)
	swirl.drag = 0.6
	swirl.gravity = -30.0
	swirl.burst(28, {"radius": 26.0, "speed": Vector2(20, 40), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(4, 18),
		"alt_speed": Vector2(4, 16), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	# Confuses at once, in the cast's own frame -- before Rules.cast_made reaches the missions: The Informer's contacts read "confused with their
	# full DISCORD_TIME left" at that signal (InformerDirector._speaks_to()). A delay here would silently kill that route.
	confused = taken(ctx.field, origin, lv_discord_r)
	for p in confused:
		p.confuse(lv_discord_time)
	if PowerBook.twist_at(extra, "discord"):
		_tangle = true
		duration = TANGLE_TIME + 0.2


func _fx_process(_delta: float) -> void:
	if not _tangle or t >= TANGLE_TIME or t - _last_scan < TANGLE_EVERY - 0.0001:
		return
	_last_scan = t
	for src in confused:
		if not is_instance_valid(src) or src.mind != Person.Mind.CONFUSED:
			continue
		for p in taken(ctx.field, src.ground_pos, TANGLE_R):
			if p in confused or caught.has(p):
				continue
			p.confuse(lv_discord_time)
			caught[p] = true
