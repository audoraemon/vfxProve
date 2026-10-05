class_name AbolitionFx
extends FxTimeline
## Abolition (Decree, Tier V): one law of the night is struck out. The decree is spoken for T_DECREE; then, for
## ABOLISH_TIME, the law the cast's mode names does not hold (Rules.abolish()), and comes back by itself:
##   CLOCK   the mission's clock does not run.
##   ESCAPE  whoever escapes the town is not counted against the act's limit.
##   WARD    the Citadel's ward is gone: nothing caps what it can lose in a second.
## It touches nobody and breaks nothing itself; it only changes what the night allows. Quiet, but for the book
## entry's "alarm" -- the town feels the law go. Once in a descent (the book's cooldown). The cast locks the other
## slots until the law is struck.

const ABOLISH_TIME := 15.0
const T_DECREE := 1.8
const UP := 120.0
const SIGNS := {"clock": DecreeParts.HOURGLASS, "escape": DominionParts.ARROW, "ward": DecreeParts.SHIELD}
const WORDS := {"clock": "THE CLOCK IS ABOLISHED", "escape": "THE ESCAPE LIMIT IS ABOLISHED", "ward": "THE CITADEL'S WARD IS ABOLISHED"}

## The law struck out, and whether it is out now.
var law := "clock"
var abolished := false

var _sign: DecreeParts.Seal
var _pulse_in := 0.0


func _build() -> void:
	law = String(extra.get("mode", "clock"))
	if not SIGNS.has(law):
		law = "clock"
	duration = T_DECREE + ABOLISH_TIME + 1.5
	busy = T_DECREE + 0.4
	at(T_DECREE, _strike)
	at(T_DECREE + ABOLISH_TIME, _restore)
	ctx.play(&"hs_charge", origin, -4.0)
	if not DominionParts.staged(self):
		return
	# The world dims while the decree is spoken; the crown gathers over the place, and the law's sign under it.
	ctx.flash.call(Color(0.02, 0.0, 0.05, 0.45), T_DECREE + 0.3)
	DecreeParts.proclaim(self, origin, 150.0, UP + 30.0, T_DECREE, 2.5)
	DominionParts.ground_sigil(self, origin, 6.0, DecreeParts.GILT, T_DECREE, 1.5)
	DecreeParts.seal(self, origin, DecreeParts.CROWN, T_DECREE + 2.0, UP + 44.0, 4)
	var glyph: Array[int] = []
	glyph.assign(SIGNS[law])
	_sign = DecreeParts.seal(self, origin, glyph, T_DECREE + ABOLISH_TIME + 1.2, UP, 5)
	_sign.shrink_at = T_DECREE + 2.5
	_sign.shrink_px = 3
	var rays := FxParts.ground_rays(self, origin, 7.0, DecreeParts.GILT, 48.0)
	rays.tween_param("reach", 0.1, 1.0, T_DECREE, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	rays.tween_param("intensity", 0.0, 0.7, T_DECREE, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	rays.tween_param("intensity", 0.7, 0.0, 0.5, T_DECREE)
	rays.life = T_DECREE + 0.55


func _strike() -> void:
	abolished = true
	if ctx.rules != null:
		ctx.rules.abolish(StringName(law), ABOLISH_TIME)
		ctx.rules.banner.emit(String(WORDS[law]))
	ctx.play(&"hs_strike", origin, -2.0)
	if not DominionParts.staged(self):
		return
	if _sign != null and is_instance_valid(_sign):
		_sign.strike()
	var sp := Iso.ground_to_screen(origin) + Vector2(0, -UP)
	ctx.flash.call(Color(1.0, 0.85, 0.45, 0.35), 0.4)
	ctx.impact.hitstop(0.06)
	ctx.impact.aberration(2.2, 0.4)
	ctx.shake.add_trauma(0.55)
	# The stroke: a bolt of gilt across the sign, the light off it, and the law going out over the whole town.
	Set2Parts.bolt(self, ctx.overhead, sp + Vector2(-90, 70), sp + Vector2(90, -70), 0.3, 2.0, 2, DecreeParts.STRUCK)
	var glow := FxParts.bloom(self, sp, 46.0, Color(1.0, 0.8, 0.4), 1.0, 0.8)
	glow.tween_param("intensity", 1.0, 0.0, 0.6, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.life = 0.62
	DecreeParts.scatter(self, origin, 30, UP)
	DecreeParts.wave(self, origin, 9.0, 0.6, 0.1)
	DecreeParts.wave(self, origin, 26.0, 1.6, 0.04)
	var lens := FxParts.refract_ring(self, origin, 12.0, Color(1.0, 0.9, 0.7))
	lens.tween_param("progress", 0.05, 1.0, 0.9, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	lens.life = 0.92
	DominionParts.pulse(self, origin, 9.0, DecreeParts.GILT, 0.9, 1.6)
	_pulse_in = 3.0


func _restore() -> void:
	abolished = false
	if DominionParts.staged(self):
		# The law comes back: a ring drawn in, quietly.
		var back := FxParts.shockwave(self, origin, 9.0, DecreeParts.GILT_RAMP)
		back.set_param("thickness", 0.04)
		back.tween_param("progress", 1.0, 0.05, 0.9, 0.0, Tween.TRANS_CUBIC, Tween.EASE_IN)
		back.tween_param("fade", 0.8, 0.0, 0.3, 0.6)
		back.life = 0.92


func _fx_process(delta: float) -> void:
	if not abolished or not DominionParts.staged(self):
		return
	# While the law is out, the ground under the sign beats, slow.
	_pulse_in -= delta
	if _pulse_in <= 0.0:
		_pulse_in = 3.0
		DominionParts.pulse(self, origin, 5.0, DecreeParts.GILT, 0.35, 1.4)
		DecreeParts.wave(self, origin, 5.0, 0.9, 0.03)
