class_name MagnifyFx
extends FxTimeline
## Magnify (Decree, Tier III): what is already there is made greater. T_SWELL after the cast, within RADIUS of the
## click, everything a power or the town has already started is multiplied by FACTOR, and nothing new is made:
##   people     whatever holds each one holds FACTOR times as long (Person.magnify(): confusion, a compulsion, a
##              fight, a panic, fearing nothing), a sickness runs FACTOR times as fast, a madness is FACTOR times as deep;
##   fires      each burning building burns FACTOR times as hard (FireManager);
##   buildings  each damaged one takes the damage it has already taken once more, FACTOR - 1 times (damage kind
##              magnify; never a fire, and never the Citadel, which keeps its own ward).
## On untouched ground it does nothing at all: it is the second stroke, not the first. Quiet when cast, but for the
## book entry's "alarm"; what it makes worse is seen for what it is. The cast locks the other slots until it lands.

const RADIUS := 4.0
const FACTOR := 2.0
const T_SWELL := 0.9
const MAX_PEOPLE := 60

## What it found to magnify.
var people := 0
var fires := 0
var cracked := 0


func _build() -> void:
	duration = T_SWELL + 2.2
	busy = T_SWELL + 0.3
	at(T_SWELL, _swell)
	ctx.play(&"grav_suction", origin, -8.0)
	if DominionParts.staged(self):
		DecreeParts.proclaim(self, origin, 80.0, 90.0, T_SWELL, 1.4)
		DecreeParts.seal(self, origin, DecreeParts.LENS, T_SWELL + 1.8, 90.0)
		# The lens gathers: a ring drawn in to the middle.
		var draw := FxParts.shockwave(self, origin, RADIUS, DecreeParts.GILT_RAMP)
		draw.set_param("thickness", 0.05)
		draw.tween_param("progress", 1.0, 0.08, T_SWELL, 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		draw.tween_param("fade", 0.3, 1.0, T_SWELL)
		draw.life = T_SWELL


func _swell() -> void:
	var staged := DominionParts.staged(self)
	for p in DominionParts.near(ctx.field, origin, RADIUS, MAX_PEOPLE):
		var took := p.magnify(FACTOR)
		if ctx.crowd != null and p.statuses.has(MadnessManager.STATUS):
			p.statuses[MadnessManager.STATUS] = minf(float(p.statuses[MadnessManager.STATUS]) * FACTOR, 1.0)
			took = true
		if took:
			people += 1
			if staged:
				DominionParts.motes(self, p.ground_pos, DecreeParts.GILT_LIFE, 6)
	for s in ctx.env.near(origin, RADIUS):
		if not is_instance_valid(s) or s.destroyed:
			continue
		if ctx.crowd != null and ctx.crowd.fires.is_burning(s):
			ctx.crowd.fires.ignite(s, minf(ctx.crowd.fires.intensity(s) * FACTOR, 1.0))
			fires += 1
			if staged:
				s.ignite(Vector2(0, -s.height * 0.5), 2.5)
		var taken := s.max_hp - s.hp
		if taken > 0.5 and s.role != &"citadel":
			s.damage(taken * (FACTOR - 1.0), s.center(), &"magnify")
			cracked += 1
			if staged:
				DecreeParts.scatter(self, s.center(), 8, s.height * 0.4)
	ctx.play(&"jg_rise", origin, -6.0)
	if not staged:
		return
	# It lets go: the screen swells over the place, and two rings go out where one would do.
	var lens := FxParts.refract_ring(self, origin, RADIUS, Color(1.0, 0.92, 0.7))
	lens.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	lens.life = 0.72
	DecreeParts.wave(self, origin, RADIUS, 0.5, 0.08)
	var again := DecreeParts.wave(self, origin, RADIUS * 1.25, 0.6, 0.05)
	again.visible = false
	at(T_SWELL + 0.18, func() -> void:
		if is_instance_valid(again):
			again.visible = true)
	DominionParts.pulse(self, origin, RADIUS, DecreeParts.GILT, 0.8 if people + fires + cracked > 0 else 0.3, 1.2)
	if people + fires + cracked > 0:
		ctx.shake.add_trauma(0.25)
		ctx.impact.aberration(1.2, 0.25)
