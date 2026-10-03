class_name VoiceOfGodFx
extends FxTimeline
## Voice of God (Dominion, Tier 5): one command, and the whole town obeys -- citizen, soldier, clergy, engineer; rank
## gives no resistance. The command (the cast's mode; Targeting's Q and E) is laid on everyone out in the open as a wave
## sweeps out from the click at WAVE_SPEED, through the people's own generic pieces: a compulsion of absolute will
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
## other slots for 1.5 s.

## How long each command holds.
const COMMANDS := {"kneel": 12.0, "halt": 12.0, "flee": 10.0, "gather": 15.0, "return": 15.0, "silence": 15.0,
	"judge": 12.0}
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
const SH_SIGIL := preload("res://shaders/divine_sigil.gdshader")
const SIGIL_R := 12.0
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
var _reached: Array[Person] = []


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
	duration = seconds + 1.0
	busy = 1.5
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
		"silence":
			if ctx.crowd != null:
				ctx.crowd.hush(seconds)
	ctx.play(&"jg_rise", origin, -2.0)
	ctx.play(&"nova_swell", origin, -6.0)
	if ctx.impact != null and is_inside_tree():
		_show()


func _fx_process(_delta: float) -> void:
	var reach := t * WAVE_SPEED
	while not _pending.is_empty():
		var p := _pending[0]
		if is_instance_valid(p) and p.ground_pos.distance_to(origin) > reach:
			break
		_pending.remove_at(0)
		if is_instance_valid(p) and p.is_alive() and not p.inside:
			_command(p)


## The command reaches `p`.
func _command(p: Person) -> void:
	var left := maxf(seconds - t, 0.5)
	var glyph: Array[int] = []
	glyph.assign(GLYPHS[command])
	var will := Person.WILL_ABSOLUTE
	obeyed += 1
	_reached.append(p)
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

func _show() -> void:
	var sp := Iso.ground_to_screen(origin)
	ctx.flash.call(Color(1.0, 0.95, 0.75, 0.3), 0.5)
	ctx.impact.aberration(1.5, 0.4)
	ctx.shake.add_trauma(0.35)
	# The sigil over the town, and the wave of authority sweeping out from under it.
	var sigil := FxParts.quad(self, SH_SIGIL, Vector2.ONE * SIGIL_R * 2.0, ctx.ground)
	sigil.position = origin
	sigil.z_index = 3
	sigil.set_param("color", Color(1.0, 0.94, 0.7))
	sigil.set_param("px", FxParts.px_for_radius(SIGIL_R))
	sigil.tween_param("reveal", 0.0, 1.0, 0.6, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	sigil.tween_param("alpha", 1.0, 0.0, 2.0, 1.4, Tween.TRANS_QUAD, Tween.EASE_IN)
	sigil.life = 3.5
	var wave := FxParts.shockwave(self, origin, 34.0, SOLAR)
	wave.set_param("thickness", 0.03)
	wave.tween_param("progress", 0.02, 1.0, 34.0 / WAVE_SPEED, 0.0, Tween.TRANS_LINEAR)
	wave.tween_param("fade", 1.0, 0.0, 0.3, 34.0 / WAVE_SPEED - 0.3)
	wave.life = 34.0 / WAVE_SPEED + 0.05
	var rays := FxParts.ground_rays(self, origin, SIGIL_R * 1.4, GOLD, 48.0)
	rays.tween_param("reach", 0.1, 1.0, 0.5, 0.0, Tween.TRANS_EXPO, Tween.EASE_OUT)
	rays.tween_param("intensity", 1.0, 0.0, 1.6, 0.4)
	rays.life = 2.1
	var light := FxParts.ground_light(self, origin, SIGIL_R, GOLD, 0.5)
	light.tween_param("intensity", 0.5, 0.0, 2.5)
	light.life = 2.55
	var pillar := FxParts.beam(self, ctx.overhead, sp, 26.0, 420.0, SOLAR)
	pillar.set_param("flicker", 0.0)
	pillar.set_param("bands", 4.0)
	pillar.tween_param("intensity", 1.0, 0.0, 1.8, 0.3, Tween.TRANS_QUAD, Tween.EASE_IN)
	pillar.life = 2.15
	var word := Word.new()
	word.fx = self
	word.z_index = 9
	track(word, ctx.overhead)


## The threads from the sky to everyone the command has reached, and the command's word over the town, both soon gone.
class Word extends Node2D:
	var fx: VoiceOfGodFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var k := clampf(1.0 - (fx.t - 0.8) / 1.4, 0.0, 1.0)
		if k <= 0.0:
			return
		var cam := fx.ctx.shake
		var mid := cam.get_screen_center_position()
		var sky := Iso.ground_to_screen(fx.origin) + Vector2(0, -380)
		for p in fx._reached:
			if is_instance_valid(p) and p.is_alive():
				draw_line(sky, Iso.ground_to_screen(p.ground_pos) + Vector2(0, -16), Color(1.0, 0.94, 0.7, 0.22 * k), 1.0)
		var text := fx.command.to_upper()
		var size := UiTheme.SIZE_TITLE
		var w := UiTheme.width(text, size)
		var scale := 1.0 / maxf(cam.zoom.x, 0.01)
		draw_set_transform(mid, 0.0, Vector2.ONE * scale)
		UiTheme.text(self, Vector2(-w * 0.5, -40.0), text, size, Color(1.0, 0.96, 0.8, k))
		draw_set_transform(Vector2.ZERO)
