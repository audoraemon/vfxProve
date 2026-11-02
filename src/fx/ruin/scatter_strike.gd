class_name ScatterStrikeFx
extends FxTimeline
## Scatter Strike (Ruin, Tier II): a wide circle, and BLASTS bursts thrown into it at random. The circle is marked at
## the cast; T_FIRST later the first burst goes, and the rest follow every BLAST_GAP, each on a point of its own drawn
## from the god's rng anywhere within RADIUS -- scattered, clumped where chance clumps them, never the carpet Orbital
## Strike lays. Nothing comes from above: each burst is a small Nova. For COMPRESS the air is drawn in over the point
## (the screen pinched, dust and light pulled to the middle, a ring shrinking to it), then it lets go: a fireball out
## of the ground, a shockwave, the air thrown back. Whoever stands within KILL_R is struck down (damage kind orbital:
## thrown as that strike throws), whoever stands within KNOCK_R is knocked off their feet, and what stands within
## HIT_R takes DAMAGE (damage kind scatter; fire may take). Cheap and wide where Orbital is dear and sure: cover a
## square, break a crowd's run, soften a district for what comes next.

const RADIUS := 6.5
const BLASTS := 12
const T_FIRST := 0.9
const BLAST_GAP := 0.35
const COMPRESS := 0.35
const KILL_R := 0.9
const KNOCK_R := 1.6
const HIT_R := 1.1
## Level 5, Seeking Bursts: as a burst draws the air in, its point moves to the nearest person in the open within SEEK_R of it.
const SEEK_R := 1.5
const DAMAGE := 40.0
const FIRE_LIGHT := Color(1.0, 0.6, 0.25)
const HOT := Color(1.0, 0.85, 0.55)
const PULL := [Color(0.9, 0.85, 0.75, 0.9), Color(0.7, 0.62, 0.5, 0.8), Color(0.5, 0.42, 0.35, 0.6), Color(0.3, 0.25, 0.2, 0.3)]

## How many have gone, where, and how many they struck down.
var blasts := 0
var points: Array[Vector2] = []
var struck := 0
## This cast's burst count and kill radius: the ability level's (PowerBook.stat()), the consts at level 1.
var lv_blasts := BLASTS
var lv_kill_r := KILL_R


func _build() -> void:
	lv_blasts = int(PowerBook.stat(extra, "scatter", "BLASTS", BLASTS))
	lv_kill_r = float(PowerBook.stat(extra, "scatter", "KILL_R", KILL_R))
	duration = T_FIRST + BLAST_GAP * float(lv_blasts) + 2.6
	busy = T_FIRST + BLAST_GAP * float(lv_blasts)
	for i in lv_blasts:
		var a := ctx.rng.randf() * TAU
		var r := RADIUS * sqrt(ctx.rng.randf())
		points.append(origin + Vector2(cos(a), sin(a)) * r)
	for i in lv_blasts:
		at(T_FIRST + BLAST_GAP * float(i) - COMPRESS, _compress.bind(i))
		at(T_FIRST + BLAST_GAP * float(i), _blast.bind(i))
	ctx.play(&"orb_target", origin, -2.0)
	if not DominionParts.staged(self):
		return
	var zone := FxParts.rings(self, origin, RADIUS, Color("ff7a3a"), 2, 28.0)
	zone.set_param("scan", 0.0)
	zone.tween_param("reveal", 0.0, 1.0, T_FIRST * 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	zone.tween_param("fade", 1.0, 0.0, 0.6, T_FIRST + BLAST_GAP * float(lv_blasts))
	zone.life = T_FIRST + BLAST_GAP * float(lv_blasts) + 0.65


## Where a seeking burst bound for `p` falls: on the nearest living person in the open within SEEK_R of it (a tie goes to the field's order), else `p`.
func seek(p: Vector2) -> Vector2:
	var best := p
	var best_d := INF
	for e in ctx.field.in_radius(p, SEEK_R):
		var person := e as Person
		if person != null and person.inside:
			continue
		var d := e.ground_pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = e.ground_pos
	return best


## The air drawn in over the point: COMPRESS of pinch, pull and a ring closing on it.
func _compress(i: int) -> void:
	if PowerBook.twist_at(extra, "scatter"):
		points[i] = seek(points[i])
	var p := points[i]
	ctx.play(&"grav_compress", p, 0.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(p)
	var pinch := FxParts.singularity(self, p, KNOCK_R, FxParts.FIRE)
	pinch.set_param("strength", 0.0)
	pinch.set_param("pinch", 0.0)
	pinch.tween_param("strength", 0.0, 1.4, COMPRESS, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	pinch.tween_param("pinch", 0.0, 0.8, COMPRESS, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	pinch.tween_param("alpha", 1.0, 0.0, 0.08, COMPRESS)
	pinch.life = COMPRESS + 0.1
	var ring := FxParts.shockwave(self, p, KNOCK_R + 0.4, FxParts.FIRE)
	ring.set_param("thickness", 0.08)
	ring.tween_param("progress", 1.0, 0.06, COMPRESS, 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
	ring.tween_param("fade", 0.5, 1.0, COMPRESS)
	ring.life = COMPRESS
	var light := FxParts.ground_light(self, p, 1.2, HOT, 0.0)
	light.tween_param("intensity", 0.0, 1.2, COMPRESS, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.life = COMPRESS + 0.02
	var dust := FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, PULL)
	dust.drag = 0.4
	dust.burst(16, {"radius": 34.0, "speed": Vector2(90, 160), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 10),
		"alt_speed": Vector2(-10, 10), "life": Vector2(0.2, COMPRESS), "size": Vector2(1, 2)})


## It lets go.
func _blast(i: int) -> void:
	var p := points[i]
	blasts += 1
	for e in ctx.field.in_radius(p, KNOCK_R):
		var person := e as Person
		if person != null and person.inside:
			continue
		if e.ground_pos.distance_to(p) <= lv_kill_r:
			if ctx.field.kill(e, &"orbital", p):
				struck += 1
		else:
			var away := e.ground_pos - p
			e.knock((away.normalized() if away.length() > 0.01 else Vector2.RIGHT) * 1.8)
	ctx.env.damage_radius(p, HIT_R, DAMAGE, &"scatter")
	ctx.play(&"cf_impact", p, 0.0)
	if i % 3 == 0:
		ctx.play(&"orb_hit", p, -1.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(p)
	ctx.flash.call(Color(1.0, 0.85, 0.6, 0.14), 0.18)
	ctx.shake.add_trauma(0.22)
	if i % 3 == 0:
		ctx.impact.hitstop(0.025)
		ctx.impact.aberration(1.0, 0.15)
	# The fireball out of the ground, the ring, the air thrown back, and what it leaves.
	var ball := FxParts.dome(self, sp, FxParts.PX_PER_UNIT_MAJOR * 0.75)
	ball.set_param("grow", 0.1)
	ball.tween_param("grow", 0.1, 1.0, 0.45, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ball.tween_param("heat", 1.0, 0.2, 0.7)
	ball.tween_param("dissolve", 0.0, 1.0, 0.5, 0.35)
	ball.life = 0.9
	var halo := FxParts.bloom(self, sp + Vector2(0, -10), 34.0, FIRE_LIGHT, 1.2, 0.8)
	halo.tween_param("intensity", 1.2, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	halo.life = 0.42
	var light := FxParts.ground_light(self, p, 2.0, FIRE_LIGHT, 1.2)
	light.tween_param("intensity", 1.2, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	light.life = 0.62
	var ring := FxParts.shockwave(self, p, KNOCK_R + 0.3, FxParts.FIRE)
	ring.set_param("thickness", 0.16)
	ring.tween_param("progress", 0.05, 1.0, 0.32, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.18, 0.18)
	ring.life = 0.38
	var air := FxParts.refract_ring(self, p, KNOCK_R + 0.6, Color(1.0, 0.85, 0.6))
	air.tween_param("progress", 0.05, 1.0, 0.4, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	air.life = 0.42
	var crater := FxParts.decal(self, p, 0.85)
	crater.tween_param("heat", 1.0, 0.0, 1.8)
	crater.tween_param("fade", 1.0, 0.0, 0.8, 1.8)
	FxParts.debris(self, sp, 12, 6.0, Vector2(50, 190), FxParts.HOT_ROCK, Vector2(1.5, 3.5), true)
	FxParts.sparks(self, ctx.overhead, sp, 16, FxParts.FIRE_LIFE, Vector2(70, 240), Vector2(40, 220))
	FxParts.smoke(self, sp, 7.0, 16.0, 0.7, Vector2(20, 55), Vector2(3, 5), Vector2(1.0, 1.8), Color("ff7a2a"))
