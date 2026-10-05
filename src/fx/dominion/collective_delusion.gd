class_name CollectiveDelusionFx
extends FxTimeline
## Collective Delusion (Dominion, Tier IV): a district believes something that is not so, and its own judgement does the
## rest. The belief is the cast's mode:
##   FALSE DANGER  a disaster that is not there, at the click: the town knows of a danger of DANGER_R for DANGER_TIME
##                 (Crowd.fright()): those in it run clear, those who see or hear it stop and look, the alarm takes
##                 note, soldiers come to see -- and nothing is harmed. What shows is only a phantom of fire.
##   ALL IS WELL   everyone within RADIUS of the click is told there is nothing to fear (Person.reassure()) for
##                 CALM_TIME: the frightened, the fleeing and the watching go back to their day, nothing frightens them
##                 meanwhile, and the alarm falls by CALM_ALARM. Those who were leaving the town leave again after.
## The belief lands T_CAST after the cast. Quiet. The cast locks the other slots until it has landed.

const RADIUS := 7.0
const T_CAST := 1.2
const DANGER_R := 3.0
const DANGER_TIME := 12.0
## The false danger as the town takes it: severity, how far it is seen and heard.
const DANGER_REACH := [0.8, 10.0, 14.0]
const CALM_TIME := 20.0
const CALM_ALARM := 5.0
const SHIMMER := Color(0.55, 0.8, 1.0)
const PHANTOM := [Color(0.9, 0.95, 1.0, 0.8), Color(1.0, 0.85, 0.5, 0.7), Color(0.45, 0.7, 1.0, 0.6), Color(0.2, 0.35, 0.8, 0.35)]

var belief := "danger"
## Whom All Is Well reassured.
var reassured: Array[Person] = []


func _build() -> void:
	belief = String(extra.get("mode", "danger"))
	var hold := DANGER_TIME if belief == "danger" else 3.0
	duration = T_CAST + hold + 0.5
	busy = T_CAST + 0.5
	at(T_CAST, _believe)
	ctx.play(&"grav_field", origin, -8.0)
	if DominionParts.staged(self):
		# The eye opens over the district.
		DominionParts.sky_sigil(self, origin, 130.0, 130.0, SHIMMER.lerp(DominionParts.GOLD, 0.5), T_CAST, 2.0)
		var eye := DominionParts.icon(self, origin, DominionParts.EYE, Color("f4f8ff"), T_CAST + 2.5, 130.0)
		eye.px = 4


func _believe() -> void:
	if belief == "danger":
		if ctx.crowd != null:
			ctx.crowd.fright(origin, DANGER_R, float(DANGER_REACH[0]), DANGER_TIME, float(DANGER_REACH[1]), float(DANGER_REACH[2]),
				&"delusion")
	else:
		belief = "calm"
		for p in DominionParts.near(ctx.field, origin, RADIUS):
			if not p.soldier:
				p.reassure(CALM_TIME)
				p.set_badge(DominionParts.EYE, SHIMMER, 3.0)
				reassured.append(p)
		if ctx.crowd != null:
			ctx.crowd.add_alarm(-CALM_ALARM)
	ctx.play(&"grav_shimmer", origin, -6.0)
	if not DominionParts.staged(self):
		return
	var sp := Iso.ground_to_screen(origin)
	if belief == "danger":
		# The phantom: pale fire that burns nothing, and a light that is the wrong colour.
		var fire := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.PUFF, PHANTOM, 46.0, DANGER_TIME - 1.0, {
			"radius": FxParts.particle_radius(DANGER_R * 0.8), "speed": Vector2(2, 10), "alt": Vector2(0, 10),
			"alt_speed": Vector2(30, 80), "life": Vector2(0.6, 1.2), "size": Vector2(2, 5), "size_end_mul": 0.4})
		fire.gravity = -30.0
		var glow := FxParts.ground_light(self, origin, DANGER_R * 1.6, SHIMMER, 0.6)
		glow.set_param("flicker", 1.0)
		glow.tween_param("intensity", 0.6, 0.0, 1.5, DANGER_TIME - 1.5)
		var haze := FxParts.heat_haze(self, sp, FxParts.particle_radius(DANGER_R), 1.6)
		haze.tween_param("strength", 1.6, 0.0, 1.5, DANGER_TIME - 1.5)
		haze.life = DANGER_TIME + 0.1
	else:
		DominionParts.ground_sigil(self, origin, RADIUS, SHIMMER, 0.5, 1.5)
		DominionParts.pulse(self, origin, RADIUS, SHIMMER, 0.5, 2.5)
		var wave := FxParts.shockwave(self, origin, RADIUS, FxParts.ICE_WAVE)
		wave.set_param("thickness", 0.05)
		wave.tween_param("progress", 0.05, 1.0, 0.8, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		wave.tween_param("fade", 1.0, 0.0, 0.3, 0.55)
		wave.life = 0.9
