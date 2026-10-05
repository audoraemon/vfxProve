class_name VoiceOfGodFx
extends FxTimeline
## Voice of God (Dominion, Tier 5): one command, and the whole town obeys -- citizen, soldier, clergy, engineer; rank
## gives no resistance. For T_SPEAK the sky darkens and the Dominion sigil draws itself over the town; then the Voice
## speaks, and the command (the cast's mode; Targeting's Q and E) is laid on everyone out in the open as a wave sweeps
## out from the click at WAVE_SPEED, through the people's own generic pieces: a compulsion of absolute will
## (Person.compel(), WILL_ABSOLUTE: no danger breaks it), a fight with one target (Person.fight(), TARGET_ONLY), or
## the town's hush (Crowd.hush()). When its seconds are up only that layer is lifted and each takes up its own
## judgement again.
##   KNEEL    everyone stops and kneels where they stand.
##   HALT     everyone stands where they are.
##   FLEE     everyone runs FLEE_RUN straight away from the click.
##   GATHER   everyone walks to the click's place (a building, or the ground), each to a spot of its own.
##   RETURN   everyone walks home (a soldier to its post).
##   SILENCE  nobody can shout, pass a fright on, call for help or ring the bell: what happens raises no alarm.
##   JUDGE    the person nearest the click is condemned, and up to JUDGE_MAX within JUDGE_REACH of them turn on them.
## The town knows a god spoke (the book entry's "alarm"), though it sees no danger to run from. The cast locks the
## other slots until a second after the Voice has spoken.

## How long each command holds, from the moment the Voice speaks.
const COMMANDS := {"kneel": 12.0, "halt": 12.0, "flee": 10.0, "gather": 15.0, "return": 15.0, "silence": 15.0,
	"judge": 12.0}
## Seconds the sigil takes to gather before the Voice speaks.
const T_SPEAK := 1.6
## How fast the command sweeps out from the click, in ground units a second (so the town's paths are not all asked for
## in one frame).
const WAVE_SPEED := 40.0
const FLEE_RUN := 9.0
const GATHER_CAPACITY := 150
## Judge: how near the click the condemned must be, who turns on them and how hard a citizen strikes.
const JUDGE_PICK := 2.0
const JUDGE_REACH := 12.0
const JUDGE_MAX := 60
const JUDGE_BLOW := 0.34
const GOLD := Color("fff2c0")
const CRIMSON := Color("ff4040")
const HUSH := Color("c8c0a8")
const SOLAR := [Color(0.9, 0.75, 0.4, 0.35), Color("e8c070"), Color("ffe09a"), Color("fff2c8"), Color("fffdf0")]
const GOLD_LIFE := [Color("fffdf0"), Color("fff2c8"), Color("ffe09a"), Color("e8c070"), Color(0.8, 0.6, 0.3, 0.5)]
const SH_SIGIL := preload("res://shaders/divine_sigil.gdshader")
## The sigil on the ground (ground units), and the one in the sky over it: how high (px), how wide, how flat.
const SIGIL_R := 12.0
const SKY_UP := 150.0
const SKY_R := 150.0
const SKY_SQUASH := 0.42
## Seconds a thread from the sky to someone the command has just reached takes to fade.
const THREAD_SECONDS := 0.8
## Each command's glyph over the head: kneel (a chevron down), halt (two bars), flee (an arrow), gather (the diamond),
## return (a house), silence (a cross), judge (a blade).
const GLYPHS := {
	"kneel": [0b10001, 0b01010, 0b00100, 0b00000, 0b11111],
	"halt": [0b11011, 0b11011, 0b11011, 0b11011, 0b11011],
	"flee": [0b00100, 0b00010, 0b11111, 0b00010, 0b00100],
	"gather": [0b00100, 0b01110, 0b11111, 0b01110, 0b00100],
	"return": [0b00100, 0b01110, 0b11111, 0b11011, 0b11011],
	"silence": [0b10001, 0b01010, 0b00100, 0b01010, 0b10001],
	"judge": [0b00100, 0b00100, 0b00100, 0b01110, 0b00100],
}

## The command given, and how long it holds.
var command := "kneel"
var seconds := 12.0
## How many it has reached, and (Judge) the condemned and how many turned on them.
var obeyed := 0
var judged: Person
var judges := 0

## Those the wave has not reached yet, nearest the click first.
var _pending: Array[Person] = []
var _place := {}
var _spots: Array[Vector2] = []
## Those it has reached, and when: [person, effect clock].
var _reached: Array = []
var _sparkle: PixelParticles
var _sky: QuadFx
var _halo: QuadFx


## Whom Judge would condemn at `at`: the person nearest it within JUDGE_PICK, or null.
static func judged_at(field: EnemyField, at: Vector2) -> Person:
	var best: Person = null
	var best_d := JUDGE_PICK
	for e in field.in_radius(at, JUDGE_PICK):
		var p := e as Person
		if p != null and not p.inside and p.ground_pos.distance_to(at) <= best_d:
			best = p
			best_d = p.ground_pos.distance_to(at)
	return best


func _build() -> void:
	command = String(extra.get("mode", "kneel"))
	if not COMMANDS.has(command):
		command = "kneel"
	seconds = float(COMMANDS[command])
	duration = T_SPEAK + seconds + 1.0
	busy = T_SPEAK + 1.0
	for e in ctx.field.alive():
		var p := e as Person
		if p != null and not p.inside:
			_pending.append(p)
	_pending.sort_custom(func(a: Person, b: Person) -> bool:
		return a.ground_pos.distance_squared_to(origin) < b.ground_pos.distance_squared_to(origin))
	match command:
		"gather":
			_place = CongregationFx.place_for(ctx.env, origin)
			var grid: WalkGrid = _pending[0].grid if not _pending.is_empty() else null
			_spots = CongregationFx.spots_for(grid, _place, mini(GATHER_CAPACITY, _pending.size()))
		"judge":
			judged = judged_at(ctx.field, origin)
	at(T_SPEAK, _speak)
	ctx.play(&"jg_rumble", origin, -4.0)
	ctx.play(&"hs_charge", origin, -6.0)
	if _staged():
		_gather_show()


func _staged() -> bool:
	return ctx.impact != null and is_inside_tree()


## The Voice speaks: from now the wave carries the command out.
func _speak() -> void:
	if command == "silence" and ctx.crowd != null:
		ctx.crowd.hush(seconds)
	ctx.play(&"jg_rise", origin, -2.0)
	ctx.play(&"nova_swell", origin, -4.0)
	if _staged():
		_speak_show()


func _fx_process(_delta: float) -> void:
	if t < T_SPEAK:
		return
	var reach := (t - T_SPEAK) * WAVE_SPEED
	while not _pending.is_empty():
		var p := _pending[0]
		if is_instance_valid(p) and p.ground_pos.distance_to(origin) > reach:
			break
		_pending.remove_at(0)
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			_command(p)
	if is_instance_valid(_halo):
		var k := curve([[0.0, 0.0], [T_SPEAK, 0.3], [T_SPEAK + 0.1, 0.55], [T_SPEAK + 1.2, 0.25], [T_SPEAK + 3.2, 0.18],
			[T_SPEAK + 4.6, 0.0]])
		_halo.set_param("intensity", k * (0.93 + 0.07 * sin(t * 6.0)))


## The command reaches `p`.
func _command(p: Person) -> void:
	var left := maxf(seconds - (t - T_SPEAK), 0.5)
	var glyph: Array[int] = []
	glyph.assign(GLYPHS[command])
	var will := Person.WILL_ABSOLUTE
	obeyed += 1
	_reached.append([p, t])
	if is_instance_valid(_sparkle):
		_sparkle.burst(3, {"offset": Iso.ground_to_screen(p.ground_pos) - _sparkle.position + Vector2(0, -8), "radius": 4.0,
			"speed": Vector2(4, 14), "alt": Vector2(0, 6), "alt_speed": Vector2(10, 30), "life": Vector2(0.4, 0.8),
			"size": Vector2(1, 1)})
	match command:
		"kneel":
			p.compel(p.ground_pos, left, will, GOLD, false, &"kneel", glyph)
		"halt":
			p.compel(p.ground_pos, left, will, GOLD, false, &"", glyph)
		"flee":
			var away := p.ground_pos - origin
			var dir := away.normalized() if away.length() > 0.05 else Vector2.RIGHT.rotated(ctx.rng.randf() * TAU)
			var to := (p.ground_pos + dir * FLEE_RUN).clamp(p.bounds.position, p.bounds.end)
			if p.grid != null:
				var free := p.grid.nearest_walkable(to, 8)
				to = free if free != Vector2.INF else p.ground_pos
			p.compel(to, left, will, GOLD, true, &"", glyph)
		"gather":
			var spot: Vector2 = _place.at
			if obeyed - 1 < _spots.size():
				spot = _spots[obeyed - 1]
			elif p.grid != null:
				var a := ctx.rng.randf() * TAU
				var free := p.grid.nearest_walkable(spot + Vector2(cos(a), sin(a)) * ctx.rng.randf_range(1.0, 4.0), 6)
				spot = free if free != Vector2.INF else spot
			p.compel(spot, left, will, GOLD, false, &"", glyph)
		"return":
			var home := p.anchor
			if p.soldier and p.post != Vector2.INF:
				home = p.post
			elif p.profile != null and p.profile.home != Vector2.INF:
				home = p.profile.home
			p.compel(home, left, will, GOLD, false, &"", glyph)
		"silence":
			p.set_badge(glyph, HUSH, left)
		"judge":
			if judged == null or not is_instance_valid(judged):
				return
			if p == judged:
				p.set_badge(glyph, CRIMSON, left)
			elif judges < JUDGE_MAX and p.ground_pos.distance_to(judged.ground_pos) <= JUDGE_REACH:
				judges += 1
				p.set_badge(glyph, GOLD, left)
				p.fight(judged, left, Person.SOLDIER_BLOW if p.soldier else JUDGE_BLOW, Person.FightRule.TARGET_ONLY)


# --- The show ----------------------------------------------------------------

## Where the sky sigil hangs, on screen.
func sky_point() -> Vector2:
	return Iso.ground_to_screen(origin) + Vector2(0, -SKY_UP)


## The gathering: the sky darkens, the sigil draws itself overhead ring by ring and again on the ground under it, and
## light is drawn up off the town toward it.
func _gather_show() -> void:
	var sp := Iso.ground_to_screen(origin)
	ctx.impact.dim(0.8, 0.7)
	_halo = FxParts.bloom(self, sky_point(), SKY_R * 1.3, GOLD, 0.0, SKY_SQUASH * 1.3)
	_sky = FxParts.quad(self, SH_SIGIL, Vector2(SKY_R * 2.0, SKY_R * 2.0 * SKY_SQUASH), ctx.overhead)
	_sky.position = sky_point()
	_sky.z_index = 6
	_sky.set_param("color", Color(1.0, 0.97, 0.82))
	_sky.set_param("px", 1.0 / (SKY_R * 0.62))
	_sky.tween_param("reveal", 0.0, 1.0, T_SPEAK * 0.95, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	_sky.tween_param("alpha", 1.0, 0.0, 1.4, T_SPEAK + 3.2, Tween.TRANS_QUAD, Tween.EASE_IN)
	_sky.life = T_SPEAK + 4.7
	var ground := FxParts.quad(self, SH_SIGIL, Vector2.ONE * SIGIL_R * 2.0, ctx.ground)
	ground.position = origin
	ground.z_index = 3
	ground.set_param("color", Color(1.0, 0.94, 0.7))
	ground.set_param("px", FxParts.px_for_radius(SIGIL_R))
	ground.set_param("alpha", 0.7)
	ground.tween_param("reveal", 0.0, 1.0, T_SPEAK, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	ground.tween_param("alpha", 1.0, 0.0, 2.4, T_SPEAK + 1.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	ground.life = T_SPEAK + 3.5
	var warm := FxParts.ground_light(self, origin, SIGIL_R, GOLD, 0.0)
	warm.tween_param("intensity", 0.0, 0.5, T_SPEAK, 0.0, Tween.TRANS_QUAD, Tween.EASE_IN)
	warm.tween_param("intensity", 0.6, 0.0, 3.0, T_SPEAK)
	warm.life = T_SPEAK + 3.1
	# Light drawn up off the town toward the sigil.
	var motes := FxParts.emitter(self, ctx.overhead, sp, PixelParticles.Shape.STREAK, GOLD_LIFE, 70.0, T_SPEAK, {
		"radius": FxParts.particle_radius(8.0), "speed": Vector2(20, 60), "dir": PixelParticles.Dir.INWARD,
		"alt": Vector2(0, 10), "alt_speed": Vector2(60, 150), "life": Vector2(0.7, 1.2), "size": Vector2(1, 2)})
	motes.gravity = -90.0
	motes.streak_len = 0.05
	_sparkle = FxParts.particles(self, ctx.overhead, sp, PixelParticles.Shape.SQUARE, GOLD_LIFE)
	_sparkle.gravity = -20.0
	_sparkle.auto_free = false
	_sparkle.z_index = 7


## The Voice: a pillar from the sigil to the ground, rays from the sky, the wave of authority across the town, the word
## itself, and gold dust falling after.
func _speak_show() -> void:
	var sp := Iso.ground_to_screen(origin)
	var sky := sky_point()
	ctx.flash.call(Color(1.0, 0.95, 0.75, 0.22), 0.45)
	ctx.impact.hitstop(0.05)
	ctx.impact.aberration(2.2, 0.45)
	ctx.shake.add_trauma(0.6)
	ctx.shake.kick(Vector2(0, 4))
	at(t + 1.4, func() -> void: ctx.impact.dim(0.0, 0.5))
	var pillar := FxParts.beam(self, ctx.overhead, sp, 34.0, SKY_UP + 30.0, SOLAR)
	pillar.set_param("flicker", 0.0)
	pillar.set_param("bands", 3.0)
	pillar.set_param("taper", 0.0)
	pillar.z_index = 5
	pillar.tween_param("intensity", 1.0, 0.0, 1.9, 0.25, Tween.TRANS_QUAD, Tween.EASE_IN)
	pillar.life = 2.2
	var foot := FxParts.bloom(self, sp, 70.0, GOLD, 0.45, 0.5)
	foot.tween_param("intensity", 0.45, 0.0, 2.0)
	foot.life = 2.05
	var sky_rays := FxParts.screen_rays(self, sky, 300.0, GOLD, 72.0, 0.75)
	sky_rays.set_param("inner", 0.3)
	sky_rays.tween_param("reach", 0.35, 1.0, 0.45, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	sky_rays.tween_param("intensity", 0.5, 0.0, 2.4, 0.4)
	sky_rays.life = 2.85
	var rays := FxParts.ground_rays(self, origin, SIGIL_R * 1.6, GOLD, 56.0)
	rays.tween_param("reach", 0.1, 1.0, 0.5, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rays.tween_param("intensity", 0.45, 0.0, 2.0, 0.4)
	rays.life = 2.45
	# The wave of authority: two rings across the town, the air bending under the first.
	for k in 2:
		var wave := FxParts.shockwave(self, origin, 34.0, SOLAR)
		wave.set_param("thickness", 0.035 if k == 0 else 0.015)
		wave.tween_param("progress", 0.02, 1.0, 34.0 / WAVE_SPEED, 0.22 * float(k), Tween.TRANS_LINEAR)
		wave.tween_param("fade", 1.0, 0.0, 0.3, 34.0 / WAVE_SPEED - 0.3 + 0.22 * float(k))
		wave.life = 34.0 / WAVE_SPEED + 0.3
		if k == 1:
			wave.set_param("progress", 0.0)
	var bend := FxParts.refract_ring(self, origin, 14.0, GOLD)
	bend.set_param("strength", 6.0)
	bend.tween_param("progress", 0.05, 1.0, 0.55, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	bend.life = 0.57
	# Gold dust falling from the sigil for a while after.
	var dust := FxParts.emitter(self, ctx.overhead, sky, PixelParticles.Shape.SQUARE, GOLD_LIFE, 60.0, 3.0, {
		"radius": SKY_R, "speed": Vector2(2, 10), "alt": Vector2(0, 4), "alt_speed": Vector2(-70, -25),
		"life": Vector2(1.4, 2.4), "size": Vector2(1, 1)})
	dust.drag = 0.4
	dust.z_index = 7
	var word := Word.new()
	word.fx = self
	word.z_index = 9
	track(word, ctx.overhead)


## A thread from the sky sigil to each one the command has just reached, each fading on its own; and the command's
## word under the sigil: it lands, holds, and fades.
class Word extends Node2D:
	var fx: VoiceOfGodFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var sky := fx.sky_point()
		for r: Array in fx._reached:
			var k := 1.0 - (fx.t - float(r[1])) / THREAD_SECONDS
			if k <= 0.0 or not is_instance_valid(r[0]):
				continue
			var p: Person = r[0]
			draw_line(sky, Iso.ground_to_screen(p.ground_pos) + Vector2(0, -16), Color(1.0, 0.95, 0.72, 0.5 * k), 1.0)
		var since := fx.t - T_SPEAK
		var a := clampf(minf(since / 0.12, 1.0 - (since - 1.8) / 0.9), 0.0, 1.0)
		if a <= 0.0:
			return
		var text := fx.command.to_upper()
		var size := UiTheme.SIZE_TITLE
		var w := UiTheme.width(text, size)
		# It lands a little large and settles.
		var pop := 1.0 + 0.35 * clampf(1.0 - since / 0.25, 0.0, 1.0)
		var scale := pop / maxf(fx.ctx.shake.zoom.x, 0.01)
		draw_set_transform(sky + Vector2(0, SKY_R * SKY_SQUASH + 26.0), 0.0, Vector2.ONE * scale)
		for off: Vector2 in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
			draw_string(UiTheme.font(), Vector2(-w * 0.5, 0.0) + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size,
				Color(0.9, 0.6, 0.2, 0.55 * a))
		UiTheme.text(self, Vector2(-w * 0.5, 0.0), text, size, Color(1.0, 0.98, 0.86, a))
		draw_set_transform(Vector2.ZERO)
