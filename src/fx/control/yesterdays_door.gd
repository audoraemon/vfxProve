class_name YesterdaysDoorFx
extends FxTimeline
## Yesterday's Door (Passage, Tier IV): a door opens onto ten seconds ago. Everyone alive within RADIUS of the click when
## it is cast steps back BACK seconds: T_TURN after the cast each is put back where they stood BACK seconds before the
## cast and, where it is theirs to take up again, doing what they did then (Person.rewind(), from the town's memory,
## TimeTrail): the rescue nearly done is not done, the rally almost formed is scattered, whoever had just fled a strike
## is calm again where they stood, the soldier who had reached his post is back where he set out from and walks it
## again. Then each stands dazed DAZE seconds and carries on from there -- if danger is still about, they fear it again
## as usual. The dead stay dead, whoever has left the town stays gone, fires and buildings are untouched; one inside a
## building, at the cast or then, is left where it is, and so is anyone the god or the town holds (a duty, a whisper, a
## compulsion, sleep, a fight: only their bodies step back). One who came into the town less than BACK seconds ago goes
## back to the first moment it remembers them.
## Quiet: nothing is frightened and nobody sees a danger; the book's "alarm" is all the town hears of it.
## On the stage the circle washes sepia and amber like old paper, a clock's ticks round its rim turn backwards, and a
## pale ghost of each person walks backwards from where they stand to where they were; then they snap there.

const RADIUS := 6.0
const BACK := 10.0
## How often the town's memory writes everyone down (TimeTrail.EVERY: the record nearest BACK ago is at most half
## of this off).
const KEEP_EVERY := 0.5
const T_TURN := 1.2
const DAZE := 1.0
## The old paper's colours: its fill, its foxed edge, the ink of the clock, the ghosts.
const PAPER := Color(0.86, 0.68, 0.4)
const FOXED := Color(0.42, 0.26, 0.12)
const INK := Color(0.3, 0.18, 0.08)
const GHOST := Color(1.0, 0.93, 0.78)
const AMBER := Color("ffc56a")
const SEPIA_LIFE := [Color("fff4dc"), Color("f0d8a8"), Color("c89a5a"), Color(0.45, 0.3, 0.15, 0.5)]
## How long the paper takes to show, and to fade once they have stepped back.
const T_WASH := 0.35
const FADE := 1.0
## The clock face drawn on the ground at the click (ground units), and the brown the veil multiplies the circle by.
const FACE_R := 1.4
const SEPIA := Color(1.0, 0.8, 0.55)

## Those within RADIUS at the cast, how each was BACK seconds before it (TimeTrail.back()), and where each stood at the cast.
var chosen: Array[Person] = []
var records: Array[Dictionary] = []
## Those who stepped back at T_TURN.
var stepped: Array[Person] = []


func _build() -> void:
	duration = T_TURN + maxf(DAZE, FADE) + 0.2
	busy = T_TURN
	at(T_TURN, _turn)
	ctx.play(&"q_yesterday", origin, 0.0)
	_choose()
	if not DominionParts.staged(self):
		return
	var page := Page.new()
	page.fx = self
	page.position = origin
	page.z_index = 2
	page.grain = _grain(150)
	track(page, ctx.ground)
	# Over everything standing in the circle, multiplied in: the street turns the brown of an old photograph.
	var veil := Veil.new()
	veil.fx = self
	veil.position = Iso.ground_to_screen(origin)
	veil.z_index = 1
	var mul := CanvasItemMaterial.new()
	mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	veil.material = mul
	track(veil, ctx.overhead_back)
	var ghosts := Ghosts.new()
	ghosts.fx = self
	ghosts.z_index = 5
	track(ghosts, ctx.overhead)
	var glow := FxParts.ground_light(self, origin, FACE_R * 1.6, AMBER, 0.0)
	glow.tween_param("intensity", 0.0, 0.25, T_WASH, 0.0, Tween.TRANS_QUAD, Tween.EASE_OUT)
	glow.tween_param("intensity", 0.25, 0.0, FADE, T_TURN, Tween.TRANS_QUAD, Tween.EASE_IN)
	glow.life = T_TURN + FADE + 0.05
	# A ring drawn in from the rim to the middle: the moment closing back on itself.
	var ring := FxParts.shockwave(self, origin, RADIUS, [Color(0.35, 0.22, 0.1, 0.5), Color("8a5a2a"), Color("c8904a"),
		Color("f0c880"), Color("fff4dc")])
	ring.set_param("thickness", 0.06)
	ring.tween_param("progress", 1.0, 0.04, T_TURN - 0.3, 0.3, Tween.TRANS_CUBIC, Tween.EASE_IN)
	ring.tween_param("fade", 0.0, 0.9, 0.3, 0.3)
	ring.life = T_TURN + 0.02


## Everyone alive out in the open within RADIUS now, and how the town remembers each BACK seconds ago.
func _choose() -> void:
	if ctx.crowd == null or ctx.crowd.trail == null:
		return
	for p in DominionParts.near(ctx.field, origin, RADIUS):
		var was := ctx.crowd.trail.back(p, BACK)
		if was.is_empty():
			continue
		chosen.append(p)
		records.append(was)


## The door turns: each steps back, dazed.
func _turn() -> void:
	var staged := DominionParts.staged(self)
	for i in chosen.size():
		var p := chosen[i]
		if not is_instance_valid(p) or not p.is_alive():
			continue
		if p.rewind(records[i], DAZE):
			stepped.append(p)
			if staged:
				DominionParts.motes(self, p.ground_pos, SEPIA_LIFE, 5)
	if staged:
		ctx.flash.call(Color(0.9, 0.7, 0.4, 0.14), 0.3)


## Where the ghost of `i` is headed: where it stood BACK seconds ago.
func ghost_to(i: int) -> Vector2:
	return records[i].get("pos", chosen[i].ground_pos)


## How much of the paper shows: in over T_WASH, held to the turn, out over FADE.
func shown() -> float:
	return clampf(minf(t / T_WASH, 1.0 - (t - T_TURN) / FADE), 0.0, 1.0)


## How far the clock has turned back (radians, negative: backwards), quickening to the turn and coasting after it.
func turned() -> float:
	var k := clampf(t / T_TURN, 0.0, 1.0)
	var after := maxf(t - T_TURN, 0.0)
	return -TAU * (1.4 * k * k + 0.5 * (1.0 - exp(-after * 3.0)))


## Specks of age on the paper: [ground offset, size, darkness], from the effect's rng (visuals only).
func _grain(n: int) -> Array:
	var out := []
	for i in n:
		var r := RADIUS * sqrt(ctx.rng.randf())
		var a := ctx.rng.randf() * TAU
		out.append([Vector2(cos(a), sin(a)) * r, ctx.rng.randf_range(0.04, 0.12), ctx.rng.randf_range(0.15, 0.45)])
	return out


## The circle on the ground: old paper, foxed at its edge, with a clock's dial whose ticks and hands turn backwards.
class Page extends Node2D:
	var fx: YesterdaysDoorFx
	var grain: Array = []

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var r := RADIUS
		draw_circle(Vector2.ZERO, r, Color(PAPER, 0.22 * a))
		draw_circle(Vector2.ZERO, r * 0.7, Color(PAPER.lightened(0.2), 0.12 * a))
		# The foxed edge: browner the nearer the rim.
		for k in 4:
			draw_arc(Vector2.ZERO, r - 0.12 - k * 0.16, 0.0, TAU, 96, Color(FOXED, (0.4 - k * 0.09) * a), 0.18)
		for g: Array in grain:
			var at: Vector2 = g[0]
			var s: float = g[1]
			draw_rect(Rect2(at - Vector2(s, s) * 0.5, Vector2(s, s)), Color(FOXED, float(g[2]) * a))
		# The dial: sixty ticks round the rim, every fifth long, turning backwards.
		var spin := fx.turned()
		for k in 60:
			var ang := spin + TAU * float(k) / 60.0
			var dir := Vector2(cos(ang), sin(ang))
			var long := k % 5 == 0
			var inner := r * (0.84 if long else 0.9)
			draw_line(dir * inner, dir * r * 0.95, Color(INK, (0.85 if long else 0.5) * a), 0.11 if long else 0.05)
		# Long hands sweeping the whole circle, running back.
		var hand_a := spin * 2.2 - PI * 0.5
		var hand_b := spin * 0.35 + PI * 0.15
		draw_line(Vector2.ZERO, Vector2(cos(hand_a), sin(hand_a)) * r * 0.8, Color(INK, 0.35 * a), 0.08)
		draw_line(Vector2.ZERO, Vector2(cos(hand_b), sin(hand_b)) * r * 0.55, Color(INK, 0.35 * a), 0.12)
		# The clock face at the click: a pale dial, twelve hours, and its hands running back.
		var f := FACE_R
		draw_circle(Vector2.ZERO, f, Color(PAPER.lightened(0.35), 0.75 * a))
		draw_arc(Vector2.ZERO, f, 0.0, TAU, 64, Color(INK, 0.9 * a), 0.1)
		draw_arc(Vector2.ZERO, f * 0.86, 0.0, TAU, 64, Color(INK, 0.5 * a), 0.04)
		for k in 12:
			var ang := TAU * float(k) / 12.0
			var dir := Vector2(cos(ang), sin(ang))
			draw_line(dir * f * (0.68 if k % 3 == 0 else 0.76), dir * f * 0.86, Color(INK, 0.9 * a), 0.1 if k % 3 == 0 else 0.05)
		var long_hand := spin * 3.0 - PI * 0.5
		var short_hand := spin * 0.5 + PI * 0.2
		draw_line(Vector2.ZERO, Vector2(cos(long_hand), sin(long_hand)) * f * 0.8, Color(INK, a), 0.09)
		draw_line(Vector2.ZERO, Vector2(cos(short_hand), sin(short_hand)) * f * 0.5, Color(INK, a), 0.15)
		draw_circle(Vector2.ZERO, 0.14, Color(INK, a))
		draw_circle(Vector2.ZERO, 0.06, Color(AMBER, a))


## A faint sepia over everything standing in the circle (people, walls), as on an old photograph.
class Veil extends Node2D:
	var fx: YesterdaysDoorFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		# Multiplied in (the node's material): white changes nothing, SEPIA browns it. Stacked discs, so the brown
		# deepens toward the middle and fades out at the rim.
		var major := RADIUS * FxParts.PX_PER_UNIT_MAJOR
		var step := Color.WHITE.lerp(SEPIA, a * 0.4)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
		for k in 4:
			draw_circle(Vector2.ZERO, major * (1.0 - k * 0.18), step)
		draw_set_transform(Vector2.ZERO)


## The ghosts: a pale figure peels off each one and walks backwards to where it stood BACK seconds ago, leaving faint
## steps; after the turn, a little ring of amber circles each dazed head.
class Ghosts extends Node2D:
	var fx: YesterdaysDoorFx

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var walk := clampf((fx.t - 0.15) / (T_TURN - 0.15), 0.0, 1.0)
		if fx.t < T_TURN:
			var e := walk * walk * (3.0 - 2.0 * walk)
			for i in fx.chosen.size():
				var p := fx.chosen[i]
				if not is_instance_valid(p) or not p.is_alive():
					continue
				var from := Iso.ground_to_screen(p.ground_pos)
				var to := Iso.ground_to_screen(fx.ghost_to(i))
				if from.distance_to(to) < 2.0:
					continue
				var at := from.lerp(to, e)
				var steps := int(from.distance_to(at) / 5.0)
				for s in steps:
					var q := from.lerp(at, (float(s) + 0.5) / float(maxi(steps, 1)))
					draw_rect(Rect2(q - Vector2(1, 0), Vector2(2, 1)), Color(GHOST, 0.45))
				for echo in 2:
					var back := from.lerp(to, maxf(e - 0.08 * float(echo + 1), 0.0))
					_figure(back, fx.t, Color(GHOST, 0.16 / float(echo + 1)))
				_figure(at, fx.t, Color(GHOST, 0.85 * minf(walk * 4.0, 1.0)))
		elif fx.t < T_TURN + DAZE:
			var k := (fx.t - T_TURN) / DAZE
			for p in fx.stepped:
				if not is_instance_valid(p) or not p.is_alive():
					continue
				var head := p.position + Vector2(0, -21)
				for d in 3:
					var ang := fx.t * 7.0 + TAU * float(d) / 3.0
					var c := Color(AMBER, 0.9 * (1.0 - k))
					draw_rect(Rect2(head + Vector2(cos(ang) * 5.0, sin(ang) * 2.0) - Vector2.ONE, Vector2(2, 2)), c)

	## A plain figure, feet at `at`, stepping backwards: a dark edge behind a pale body, to read on any ground.
	func _figure(at: Vector2, time: float, c: Color) -> void:
		var stride := 1.0 if fmod(time * 6.0, 2.0) < 1.0 else -1.0
		var edge := Color(FOXED, c.a * 0.6)
		draw_rect(Rect2(at + Vector2(-2.5, -17), Vector2(5, 5)), edge)
		draw_rect(Rect2(at + Vector2(-3.5, -13), Vector2(7, 9)), edge)
		draw_rect(Rect2(at + Vector2(-3.0, -5), Vector2(6, 5)), edge)
		draw_rect(Rect2(at + Vector2(-1.5, -16), Vector2(3, 3)), c)
		draw_rect(Rect2(at + Vector2(-2.5, -12), Vector2(5, 7)), c)
		draw_rect(Rect2(at + Vector2(-2.0 + stride, -5), Vector2(1.5, 4)), c)
		draw_rect(Rect2(at + Vector2(0.5 - stride, -5), Vector2(1.5, 4)), c)
