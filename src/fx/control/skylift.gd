class_name SkyliftFx
extends FxTimeline
## Skylift (Passage, Tier I): a beam takes what stands in one place and sets it down in another. Two clicks: where it
## takes from, and where it sets down (extra "to"). A bright blue light stands on the first place for T_TAKE; then
## everyone within RADIUS of it -- any role; those inside a building are not reached -- is gone from there and stands
## at the second place, each as far from its middle as they stood from the first's (DummyEnemy.fold(): a person keeps
## what it meant to do, and walks on toward it from where it was set down). A second, shorter light marks the arrival.
## Nobody is hurt and nothing is broken. Quiet, but for the book entry's "alarm": a light from the sky is seen.

const RADIUS := 1.5
const T_TAKE := 1.4
const T_SET := 0.6
const BLUE := Color(0.45, 0.75, 1.0)
const PALE := Color(0.8, 0.92, 1.0)

## Where it sets them down, and how many it took.
var to := Vector2.ZERO
var taken := 0


## Whom a lift at `at` would take.
static func lifted_at(field: EnemyField, at: Vector2) -> Array:
	var out: Array = []
	for e in field.in_radius(at, RADIUS):
		var p := e as Person
		if p != null and p.inside:
			continue
		out.append(e)
	return out


func _build() -> void:
	to = extra.get("to", origin + Vector2(4.0, 0.0))
	duration = T_TAKE + T_SET + 0.8
	busy = T_TAKE
	at(T_TAKE, _take)
	ctx.play(&"q_skylift", origin)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	# The light comes down on the place: a wide column, a bright core, rays off the sky, rings drawn in under it, the
	# ground lit, motes drawn up into it, and the air over it bent.
	var column := Set2Parts.glow_column(self, sp, 110.0, 520.0, BLUE, 0.0, T_TAKE + 0.3)
	column.tween_param("intensity", 0.2, 2.2, T_TAKE * 0.7, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	column.tween_param("intensity", 2.2, 0.0, 0.3, T_TAKE)
	var core := Set2Parts.glow_column(self, sp, 34.0, 520.0, PALE, 0.0, T_TAKE + 0.2)
	core.tween_param("intensity", 0.0, 2.6, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	core.tween_param("intensity", 2.6, 0.0, 0.2, T_TAKE)
	var white := FxParts.beam(self, ctx.overhead, sp, 12.0, 520.0, FxParts.ION)
	white.set_param("intensity", 0.0)
	white.tween_param("intensity", 0.0, 1.4, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	white.tween_param("intensity", 1.4, 0.0, 0.2, T_TAKE)
	white.life = T_TAKE + 0.22
	var rays := FxParts.screen_rays(self, sp + Vector2(0, -30), 120.0, PALE, 60.0, 0.0)
	rays.tween_param("intensity", 0.0, 0.5, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	rays.tween_param("intensity", 0.5, 0.0, 0.25, T_TAKE)
	rays.life = T_TAKE + 0.27
	var halo := FxParts.bloom(self, sp + Vector2(0, -10), 50.0, BLUE, 0.0, 0.7)
	halo.tween_param("intensity", 0.0, 0.8, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	halo.tween_param("intensity", 0.8, 0.0, 0.25, T_TAKE)
	halo.life = T_TAKE + 0.27
	var bend := FxParts.refract_ring(self, origin, RADIUS + 1.0, Color(0.7, 0.85, 1.0))
	bend.set_param("progress", 1.0)
	bend.tween_param("progress", 1.0, 0.1, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	bend.life = T_TAKE + 0.05
	for i in 3:
		var draw := FxParts.shockwave(self, origin, RADIUS + 1.6, FxParts.ION)
		draw.set_param("thickness", 0.06)
		draw.set_param("progress", 1.0)
		draw.set_param("fade", 0.0)
		draw.tween_param("progress", 1.0, 0.08, 0.6, 0.15 + 0.35 * float(i), Tween.TRANS_QUAD, Tween.EASE_IN)
		draw.tween_param("fade", 0.0, 0.8, 0.1, 0.15 + 0.35 * float(i))
		draw.tween_param("fade", 0.8, 0.0, 0.15, 0.6 + 0.35 * float(i))
		draw.life = 0.8 + 0.35 * float(i)
	var mark := FxParts.rings(self, origin, RADIUS, PALE, 2, 14.0)
	mark.set_param("scan", 0.0)
	mark.tween_param("reveal", 0.0, 1.0, T_TAKE * 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	mark.life = T_TAKE + 0.1
	var light := FxParts.ground_light(self, origin, RADIUS * 2.2, BLUE, 0.0)
	light.tween_param("intensity", 0.0, 2.0, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	light.tween_param("intensity", 2.0, 0.0, 0.3, T_TAKE)
	light.life = T_TAKE + 0.32
	var ground_rays := FxParts.ground_rays(self, origin, RADIUS * 2.5, PALE, 40.0)
	ground_rays.set_param("reach", 0.9)
	ground_rays.tween_param("intensity", 0.0, 0.8, T_TAKE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	ground_rays.tween_param("intensity", 0.8, 0.0, 0.3, T_TAKE)
	ground_rays.life = T_TAKE + 0.32
	var up := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, FxParts.ION_LIFE, 110.0, T_TAKE,
		{"radius": 26.0, "speed": Vector2(0, 6), "alt": Vector2(0, 10), "alt_speed": Vector2(140, 320), "life": Vector2(0.5, 1.0), "size": Vector2(1, 3)})
	up.gravity = -80.0
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 50.0, T_TAKE,
		{"radius": 40.0, "speed": Vector2(10, 40), "dir": PixelParticles.Dir.INWARD, "alt": Vector2(0, 30), "alt_speed": Vector2(20, 80), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	motes.drag = 0.5
	ctx.play(&"laser_scan", origin, -8.0)
	ctx.shake.add_trauma(0.1)


## They are taken, and set down.
func _take() -> void:
	for e in lifted_at(ctx.field, origin):
		if e.fold(to + (e.ground_pos - origin)):
			taken += 1
	ctx.play(&"grav_shimmer", to, -4.0)
	if not DominionParts.staged(self):
		return
	ctx.flash.call(Color(0.75, 0.9, 1.0, 0.22), 0.25)
	ctx.impact.hitstop(0.05)
	ctx.impact.aberration(2.0, 0.3)
	ctx.shake.add_trauma(0.35)
	var sp := Iso.ground_to_screen(origin)
	var dp := Iso.ground_to_screen(to)
	# Where they stood: the light snaps shut in a white flash, the air snaps back, a ring goes out, sparks fall.
	var snap := FxParts.bloom(self, sp + Vector2(0, -20), 60.0, Color(0.9, 0.96, 1.0), 1.1, 0.8)
	snap.tween_param("intensity", 1.1, 0.0, 0.3, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	snap.life = 0.37
	var back := FxParts.refract_ring(self, origin, RADIUS + 2.0, Color(0.7, 0.85, 1.0))
	back.tween_param("progress", 0.05, 1.0, 0.45, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	back.life = 0.47
	_ring(origin)
	var second := FxParts.shockwave(self, origin, RADIUS + 2.5, FxParts.ION)
	second.set_param("thickness", 0.05)
	second.tween_param("progress", 0.05, 1.0, 0.7, 0.1, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	second.tween_param("fade", 1.0, 0.0, 0.3, 0.5)
	second.life = 0.85
	FxParts.sparks(self, ctx.overhead, sp, 36, FxParts.ION_LIFE, Vector2(60, 260), Vector2(80, 320))
	var fall := FxParts.particles(self, ctx.overhead, sp + Vector2(0, -120), PixelParticles.Shape.STREAK, FxParts.ION_LIFE)
	fall.gravity = 220.0
	fall.burst(24, {"radius": 24.0, "speed": Vector2(0, 10), "alt": Vector2(0, 160), "alt_speed": Vector2(-40, 20), "life": Vector2(0.5, 0.9), "size": Vector2(1, 2)})
	# Where they are set down: the beam comes down once more, hard and short, and they stand in its light.
	var column := Set2Parts.glow_column(self, dp, 110.0, 520.0, BLUE, 2.2, T_SET)
	column.tween_param("intensity", 2.2, 0.0, T_SET, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	var core := Set2Parts.glow_column(self, dp, 34.0, 520.0, PALE, 2.6, T_SET * 0.7)
	core.tween_param("intensity", 2.6, 0.0, T_SET * 0.7)
	var white := FxParts.beam(self, ctx.overhead, dp, 12.0, 520.0, FxParts.ION)
	white.tween_param("intensity", 1.4, 0.0, T_SET * 0.6)
	white.life = T_SET * 0.6 + 0.02
	var rays := FxParts.screen_rays(self, dp + Vector2(0, -30), 120.0, PALE, 60.0, 0.5)
	rays.tween_param("intensity", 0.5, 0.0, T_SET + 0.2)
	rays.life = T_SET + 0.22
	var land := FxParts.bloom(self, dp + Vector2(0, -20), 60.0, Color(0.9, 0.96, 1.0), 1.0, 0.8)
	land.tween_param("intensity", 1.0, 0.0, 0.4, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	land.life = 0.42
	_ring(to)
	var out := FxParts.refract_ring(self, to, RADIUS + 2.0, Color(0.7, 0.85, 1.0))
	out.tween_param("progress", 0.05, 1.0, 0.5, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	out.life = 0.52
	var light := FxParts.ground_light(self, to, RADIUS * 2.2, BLUE, 2.0)
	light.tween_param("intensity", 2.0, 0.0, T_SET + 0.4)
	light.life = T_SET + 0.42
	var ground_rays := FxParts.ground_rays(self, to, RADIUS * 2.5, PALE, 40.0)
	ground_rays.set_param("reach", 0.9)
	ground_rays.tween_param("intensity", 0.8, 0.0, T_SET + 0.3)
	ground_rays.life = T_SET + 0.32
	FxParts.sparks(self, ctx.overhead, dp, 28, FxParts.ION_LIFE, Vector2(40, 200), Vector2(60, 240))
	var settle := FxParts.emitter(self, ctx.overhead, dp, PixelParticles.Shape.SQUARE, FxParts.ION_LIFE, 60.0, T_SET,
		{"radius": 28.0, "speed": Vector2(2, 8), "alt": Vector2(60, 160), "alt_speed": Vector2(-120, -40), "life": Vector2(0.4, 0.8), "size": Vector2(1, 2)})
	settle.gravity = 40.0


func _ring(at_ground: Vector2) -> void:
	var ring := FxParts.shockwave(self, at_ground, RADIUS + 1.0, FxParts.ION)
	ring.set_param("thickness", 0.14)
	ring.tween_param("progress", 0.05, 1.0, 0.35, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	ring.tween_param("fade", 1.0, 0.0, 0.2, 0.16)
	ring.life = 0.38
