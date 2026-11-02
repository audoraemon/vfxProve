class_name ScatterStrikeFx
extends FxTimeline
## Scatter Strike (Ruin, Tier II): a wide circle, and BLASTS small strikes thrown into it at random. The circle is marked
## at the cast; T_FIRST later the first strike falls, and the rest follow every BLAST_GAP, each on a point of its own
## drawn from the god's rng anywhere within RADIUS -- scattered, clumped where chance clumps them, never the carpet
## Orbital Strike lays. Each strike: a streak out of the sky, a small fireball; whoever stands within KILL_R is struck
## down (damage kind orbital: thrown as that strike throws), whoever stands within KNOCK_R is knocked off their feet, and
## what stands within HIT_R takes DAMAGE (damage kind scatter; fire may take). Cheap and wide where Orbital is dear and
## sure: cover a square, break a crowd's run, soften a district for what comes next.

const RADIUS := 6.5
const BLASTS := 10
const T_FIRST := 0.9
const BLAST_GAP := 0.2
const KILL_R := 0.9
const KNOCK_R := 1.6
const HIT_R := 1.1
const DAMAGE := 40.0
const FIRE_LIGHT := Color(1.0, 0.6, 0.25)
const HOT := Color(1.0, 0.85, 0.55)

## How many have fallen, where, and how many they struck down.
var blasts := 0
var points: Array[Vector2] = []
var struck := 0


func _build() -> void:
	duration = T_FIRST + BLAST_GAP * float(BLASTS) + 2.4
	busy = T_FIRST + BLAST_GAP * float(BLASTS)
	for i in BLASTS:
		var a := ctx.rng.randf() * TAU
		var r := RADIUS * sqrt(ctx.rng.randf())
		points.append(origin + Vector2(cos(a), sin(a)) * r)
	for i in BLASTS:
		at(T_FIRST + BLAST_GAP * float(i) - 0.25, _aim.bind(i))
		at(T_FIRST + BLAST_GAP * float(i), _blast.bind(i))
	ctx.play(&"orb_target", origin, -2.0)
	if not DominionParts.staged(self):
		return
	var zone := FxParts.rings(self, origin, RADIUS, Color("ff7a3a"), 2, 28.0)
	zone.set_param("scan", 0.0)
	zone.tween_param("reveal", 0.0, 1.0, T_FIRST * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	zone.tween_param("fade", 1.0, 0.0, 0.6, T_FIRST + BLAST_GAP * float(BLASTS))
	zone.life = T_FIRST + BLAST_GAP * float(BLASTS) + 0.65


## The mark where the next one lands.
func _aim(i: int) -> void:
	if not DominionParts.staged(self):
		return
	var p := points[i]
	var reticle := FxParts.rings(self, p, KILL_R, Color("ff5a3a"), 1, 6.0)
	reticle.set_param("scan", 0.0)
	reticle.tween_param("reveal", 0.0, 1.0, 0.2, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	reticle.life = 0.26


func _blast(i: int) -> void:
	var p := points[i]
	blasts += 1
	for e in ctx.field.in_radius(p, KNOCK_R):
		var person := e as Person
		if person != null and person.inside:
			continue
		if e.ground_pos.distance_to(p) <= KILL_R:
			if ctx.field.kill(e, &"orbital", p):
				struck += 1
		else:
			var away := e.ground_pos - p
			e.knock((away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 1.6)
	ctx.env.damage_radius(p, HIT_R, DAMAGE, &"scatter")
	ctx.play(&"cf_impact", p, 0.0)
	if i % 3 == 0:
		ctx.play(&"orb_hit", p, -1.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(p)
	ctx.flash.call(Color(1.0, 0.85, 0.6, 0.1), 0.15)
	ctx.shake.add_trauma(0.18)
	if i % 3 == 0:
		ctx.impact.hitstop(0.02)
	# The streak down, the ball, the ring, and what it throws.
	var streak := FxParts.beam(self, ctx.overhead, sp, 3.0, 360.0, FxParts.FIRE)
	streak.tween_param("intensity", 1.2, 0.0, 0.14)
	streak.life = 0.15
	var ball := FxParts.dome(self, sp, FxParts.PX_PER_UNIT_MAJOR * 0.6)
	ball.tween_param("progress", 0.0, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ball.life = 0.52
	var halo := FxParts.bloom(self, sp + Vector2(0, -8), 28.0, FIRE_LIGHT, 1.0, 0.8)
	halo.tween_param("intensity", 1.0, 0.0, 0.35, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.life = 0.37
	var light := FxParts.ground_light(self, p, 1.6, FIRE_LIGHT, 1.0)
	light.tween_param("intensity", 1.0, 0.0, 0.5, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.52
	var ring := FxParts.shockwave(self, p, KNOCK_R, FxParts.FIRE)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.3, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.18, 0.15)
	ring.life = 0.36
	var crater := FxParts.decal(self, p, 0.8)
	crater.tween_param("heat", 1.0, 0.0, 1.6)
	crater.tween_param("fade", 1.0, 0.0, 0.8, 1.6)
	FxParts.debris(self, sp, 10, 6.0, Vector2(40, 170), FxParts.HOT_ROCK, Vector2(1.5, 3.5), true)
	FxParts.sparks(self, ctx.overhead, sp, 14, FxParts.FIRE_LIFE, Vector2(60, 220), Vector2(30, 200))
	FxParts.smoke(self, sp, 6.0, 14.0, 0.6, Vector2(18, 50), Vector2(2, 5), Vector2(0.9, 1.6), Color("ff7a2a"))
