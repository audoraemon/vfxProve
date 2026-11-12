class_name PaleSerpentFx
extends FxTimeline
## The Pale Serpent (Death, Tier V; spec 5.7): a drag, once a descent. A vast feathered serpent -- white feathers over dark
## green scales, the novel's Death Consul -- bursts up out of the ground at the press over T_RISE, glides along the drag
## (LENGTH at most, MIN_LENGTH at least) over GLIDE, then loops once through the end, a circle of CIRCLE_R turned to the
## drag's left (Vector2.orthogonal()) over CIRCLE, and climbs away into the dark over DEPART.
## - Its shadow kills: each step, everyone out in the open (not indoors, not guised -- Corpse Guise hides the faithful, as
##   The Gate Below and Pale Reign spare them) within BAND of the head's path swept that step dies at once, without a
##   sound or a mark, killed as &"shadow" (a whole body: it leaves a remain, ready to rise; a quiet kind,
##   DeathVoices.QUIET_KINDS). No luck: everyone in the band dies, in instance-id order. A long frame is swept in steps of
##   STEP at most, so nobody is skipped. Houses are left standing: nothing here touches a structure.
## - Its sight sickens: as it rises, everyone out in the open within SIGHT of it (not indoors, not guised) walks at
##   SICK_PACE for SICK (hold_pace under this effect's id), and catches the plague too (PlagueManager.PLAGUE_LIFE) when
##   Pestilence's is in town (plague_live(): anyone sick). Let go at SICK, at the end, and when freed without one.
## Loud (PowerBook.REACH): the danger counts from the head risen (IMPACT = T_RISE, the first shadow); every FRIGHT_EVERY
## while it glides the street within FRIGHT_R of the head runs. No hush.
## Drawn (staged only) in the stand layer, y-sorted: the head (the Task 1 sheet, picked for its heading on screen among eight
## ways, the west three the east three mirrored), a procedural chain of SEGMENTS scaled discs under a mantle of white
## feathers trailing the head's path GAP apart, and the tail sprite turned back along the path; their shadow on the ground
## below; and whatever house stands in front of any of it goes see-through (SeeThrough).

## The brief's numbers: the longest drag, the glide, the loop's radius and time, the shadow's half width, how far it is seen
## and how long the sight sickens.
const LENGTH := 14.0
const GLIDE := 10.0
const CIRCLE_R := 4.0
const CIRCLE := 3.0
const BAND := 1.0
const SIGHT := 12.0
const SICK := 20.0
## The burst out of the ground (the head up: the first shadow, the power's impact); the shortest run (a click with no drag).
const T_RISE := 1.0
const MIN_LENGTH := 4.0
## The pace the sight leaves.
const SICK_PACE := 0.6
## After the loop: it climbs away, fading, at DEPART_SPEED along the drag's way for DEPART.
const DEPART := 1.5
const DEPART_SPEED := 4.0
## The longest bit of path swept at once (ground units).
const STEP := 0.25
## The fright while it glides, renewed as a spirit's is: centred FRIGHT_BACK behind the head along its path (review
## IMPORTANT 2), so it scatters the street the serpent has passed, not the street ahead -- FRIGHT_R plus the town's own
## margin (Person.THREAT_MARGIN), so nobody ahead of the head is reached. None until the head is that far out.
const FRIGHT_R := BAND + 3.0
const FRIGHT_EVERY := 1.0
const FRIGHT_BACK := FRIGHT_R + Person.THREAT_MARGIN

## The art (Task 1, ruling R4): five heads (64 x 64) and the tail (64 x 48, pointing left).
const HEADS := {
	"east": preload("res://assets/pixellab/fx/pale_serpent/head_east.png"),
	"south-east": preload("res://assets/pixellab/fx/pale_serpent/head_south-east.png"),
	"north-east": preload("res://assets/pixellab/fx/pale_serpent/head_north-east.png"),
	"south": preload("res://assets/pixellab/fx/pale_serpent/head_south.png"),
	"north": preload("res://assets/pixellab/fx/pale_serpent/head_north.png")}
const TAIL := preload("res://assets/pixellab/fx/pale_serpent/tail.png")
## The eight ways on screen from east, clockwise (screen y is down): [head, mirrored].
const WAYS := [["east", false], ["south-east", false], ["south", false], ["south-east", true], ["east", true],
	["north-east", true], ["north", false], ["north-east", false]]
## Its size: SEGMENTS discs GAP apart along the path (22 x 0.32 = 7 ground units of body, about 250 px), R_NECK px in
## radius behind the head (28 px across: half again a person's 18-21 px height) tapering to R_TAIL at the tail; it glides
## LIFT px over its shadow, rising and falling WAVE px down its length. The head and tail sprites are drawn 1:1 (a 64 px
## head is three people tall).
const SEGMENTS := 22
const GAP := 0.32
const R_NECK := 14.0
const R_TAIL := 8.0
const LIFT := 34.0
const WAVE := 6.0
## A disc this far along the path out of the hole has its full height (it pours up out of the ground).
const EMERGE := 1.2
const HEAD_PIVOT := Vector2(32, 36)
## Where the tail sprite meets the body: its right edge, halfway down.
const TAIL_ATTACH := Vector2(60, 24)
## Scales and feathers (the sheet's own colours).
const SCALE_DARK := Color("214d37")
const SCALE_LIGHT := Color("3b6748")
const FEATHER := Color("e2eeed")
const FEATHER_SHADE := Color("a4aeb7")
## Death's palette for the dust: bone and ash; no blood.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const FEATHERS := [Color("e2eeed"), Color("e2eeed"), Color("a4aeb7")]

## The dead, in the order the shadow took them; when the first fell (on the effect's clock).
var taken: Array[Person] = []
var first_kill_at := -1.0
## Everyone who saw it rise (sickened).
var sickened := 0

## Instance id -> Person: everyone this effect slows.
var _held := {}
## The run: start, way, length, end; the loop's centre, start angle and turn (+1 or -1).
var _dir := Vector2.RIGHT
var _len := LENGTH
var _end := Vector2.ZERO
var _centre := Vector2.ZERO
var _theta0 := 0.0
var _turn := 1.0
var _planned := false
## How far along the path the shadow has swept (on the effect's clock); whether the sight and the sickness are done.
var _swept_to := -1.0
var _seen := false
var _sick_over := false
var _next_fright := T_RISE
## Staged only: the pieces (head, discs, tail), the shadow, the see-through.
var _pieces: Array[Piece] = []
var _shade: Shade
var _see: SeeThrough
var _next_feather := T_RISE


## Where a cast at `at` ends: along the drag's way as Targeting reads it ("dir": Targeting.aim_dir(), DEFAULT_DIR for a drag
## under DRAG_MIN -- the way the preview showed, never a short drag's jitter), as far as the drag went ("to"), LENGTH at most,
## MIN_LENGTH at least; LENGTH with no "to" (a scripted cast). A cast with no "dir" takes the way to "to", else east.
static func end_of(at: Vector2, extra_data: Dictionary) -> Vector2:
	var to: Vector2 = extra_data.get("to", Vector2.INF)
	var dir: Vector2 = extra_data.get("dir", Vector2.ZERO)
	if dir.length() < 0.001 and to != Vector2.INF:
		dir = to - at
	if dir.length() < 0.001:
		dir = Vector2.RIGHT
	var length := LENGTH if to == Vector2.INF else clampf(to.distance_to(at), MIN_LENGTH, LENGTH)
	return at + dir.normalized() * length


## When the loop is done (the shadow's last).
static func glide_end() -> float:
	return T_RISE + GLIDE + CIRCLE


## The head drawn for a heading on screen: [sheet key, mirrored].
static func head_for(screen_dir: Vector2) -> Array:
	var d := screen_dir if screen_dir.length() > 0.001 else Vector2.RIGHT
	return WAYS[posmod(roundi(d.angle() / (PI * 0.25)), 8)]


## Whether Pestilence's plague is in town: anyone alive is sick (Person.sick_left).
static func plague_live(crowd: Crowd) -> bool:
	if crowd == null:
		return false
	if crowd.plague != null:
		for q in crowd.plague.sick:
			if is_instance_valid(q) and q.is_alive() and q.sick_left > 0.0:
				return true
	for p in crowd.citizens + crowd.soldiers:
		if is_instance_valid(p) and p.is_alive() and p.sick_left > 0.0:
			return true
	return false


## The run from the cast (origin, extra): the end, and the loop through it.
func plan() -> void:
	_end = end_of(origin, extra)
	_len = origin.distance_to(_end)
	_dir = (_end - origin) / _len
	_centre = _end + _dir.orthogonal() * CIRCLE_R
	_theta0 = (_end - _centre).angle()
	_turn = 1.0 if Vector2(-sin(_theta0), cos(_theta0)).dot(_dir) > 0.0 else -1.0
	_planned = true


## How far along its path the head is at `time` (ground units).
func s_at(time: float) -> float:
	if time <= T_RISE:
		return 0.0
	if time <= T_RISE + GLIDE:
		return _len * (time - T_RISE) / GLIDE
	var loop := TAU * CIRCLE_R
	if time <= glide_end():
		return _len + loop * (time - T_RISE - GLIDE) / CIRCLE
	return _len + loop + DEPART_SPEED * (time - glide_end())


## The ground point `s` along the path: the glide, the loop, then on along the drag's way.
func path_at(s: float) -> Vector2:
	if s <= 0.0:
		return origin
	if s <= _len:
		return origin + _dir * s
	var loop := TAU * CIRCLE_R
	if s <= _len + loop:
		return _centre + Vector2.from_angle(_theta0 + _turn * (s - _len) / CIRCLE_R) * CIRCLE_R
	return _end + _dir * (s - _len - loop)


## Where the head is at `time`.
func head_at(time: float) -> Vector2:
	return path_at(s_at(time))


func _build() -> void:
	plan()
	duration = maxf(glide_end() + DEPART, T_RISE + SICK) + 0.05
	busy = T_RISE
	ctx.play(&"serpent_rise", origin, 0.0)
	at(T_RISE, func(): ctx.play(&"serpent_glide", origin, 0.0))
	at(T_RISE + GLIDE * 0.5, func(): ctx.play(&"serpent_glide", head_at(t), -2.0))
	at(T_RISE + GLIDE, func(): ctx.play(&"serpent_glide", _end, 0.0))
	if not DominionParts.staged(self):
		return
	_see = SeeThrough.new()
	_shade = Shade.new()
	_shade.fx = self
	_shade.z_index = 3
	track(_shade, ctx.ground)
	var layer := stand_layer()
	for i in SEGMENTS + 2:
		var piece := Piece.new()
		piece.kind = Piece.K_HEAD if i == 0 else (Piece.K_TAIL if i == SEGMENTS + 1 else Piece.K_BODY)
		piece.index = i
		piece.visible = false
		_pieces.append(piece)
		track(piece, layer)
	# The burst out of the ground: bone dust and chips, a flurry of feathers, the ground shaking.
	var sp := Iso.ground_to_screen(origin)
	FxParts.smoke(self, sp, 40.0, 30.0, T_RISE, Vector2(10, 30), Vector2(3, 6), Vector2(0.8, 1.6), Color(0, 0, 0, 0), DUST)
	FxParts.debris(self, sp, 16, 30.0, Vector2(30, 110), BONE_CHIPS, Vector2(1.0, 2.5), true)
	FxParts.debris(self, sp + Vector2(0, -LIFT), 14, 20.0, Vector2(20, 70), FEATHERS, Vector2(1.0, 2.0), true)
	if ctx.shake != null:
		ctx.shake.add_trauma(0.3)


func _fx_process(delta: float) -> void:
	if not _planned:
		return
	if not _seen and t >= T_RISE:
		_sight()
	if t >= T_RISE and _swept_to < glide_end():
		var from := maxf(_swept_to, T_RISE)
		var to := minf(t, glide_end())
		_sweep(from, to)
		_swept_to = to
	while _next_fright < glide_end() and t >= _next_fright:
		var back := s_at(_next_fright) - FRIGHT_BACK
		if ctx.crowd != null and back >= 0.0:
			ctx.crowd.fright(path_at(back), FRIGHT_R, 0.9, 2.0, SIGHT, 16.0, &"beast")
		_next_fright += FRIGHT_EVERY
	if not _sick_over and t >= T_RISE + SICK:
		_sick_over = true
		_let_all_go()
	if t >= glide_end() + DEPART and _held.is_empty():
		duration = minf(duration, t + 0.05)  # nobody left slowed: nothing more to do
	if not _pieces.is_empty():
		_pose(delta)


## As it rises: everyone out in the open within SIGHT of it is slowed for SICK, and sickened if the plague is in town.
func _sight() -> void:
	_seen = true
	var plague := plague_live(ctx.crowd)
	for e in ctx.field.in_radius(origin, SIGHT):
		var p := e as Person
		if p == null or p.inside or p.guised():
			continue
		var id := p.get_instance_id()
		if not _held.has(id):
			_held[id] = p
			p.hold_pace(get_instance_id(), SICK_PACE)
			sickened += 1
		if plague:
			p.infect(PlagueManager.PLAGUE_LIFE)


## The shadow over the head's path from `t0` to `t1` (the effect's clock), in bits of STEP at most.
func _sweep(t0: float, t1: float) -> void:
	var s0 := s_at(t0)
	var s1 := s_at(t1)
	var n := maxi(1, ceili((s1 - s0) / STEP))
	for k in n:
		var a := path_at(lerpf(s0, s1, float(k) / float(n)))
		var b := path_at(lerpf(s0, s1, float(k + 1) / float(n)))
		_shadow(a, b, lerpf(t0, t1, float(k) / float(n)), (t1 - t0) / float(n))


## Everyone out in the open within BAND of the bit of path a..b dies, in instance-id order; `when` and `span` place each
## death on the clock where the head passed nearest them.
func _shadow(a: Vector2, b: Vector2, when: float, span: float) -> void:
	var near: Array[Person] = []
	for e in ctx.field.in_radius((a + b) * 0.5, a.distance_to(b) * 0.5 + BAND + 0.01):
		var p := e as Person
		if p == null or p.inside or p.guised():
			continue
		if Geometry2D.get_closest_point_to_segment(p.ground_pos, a, b).distance_to(p.ground_pos) <= BAND:
			near.append(p)
	near.sort_custom(func(x: Person, y: Person) -> bool: return x.get_instance_id() < y.get_instance_id())
	for p in near:
		var at_pt := Geometry2D.get_closest_point_to_segment(p.ground_pos, a, b)
		var u := at_pt.distance_to(a) / a.distance_to(b) if a.distance_to(b) > 0.0001 else 0.0
		_let_go(p.get_instance_id())
		if not ctx.field.kill(p, &"shadow", at_pt):
			continue
		taken.append(p)
		if first_kill_at < 0.0:
			first_kill_at = when + span * u


func _let_go(id: int) -> void:
	# Untyped until checked: one who left the town (Crowd.escape) is freed, and assigning a freed one to a Person errors.
	var p = _held.get(id)
	_held.erase(id)
	if is_instance_valid(p):
		(p as Person).free_pace(get_instance_id())


func _let_all_go() -> void:
	for id in _held.keys():
		_let_go(id)


## Over or cut short: every pace let go, every house its own look back.
func _finish() -> void:
	_let_all_go()
	if _see != null:
		_see.release()
	super()


## Freed without _finish (a mission torn down mid-glide): the same.
func _exit_tree() -> void:
	_let_all_go()
	if _see != null:
		_see.release()
	super()


## 0..1 how much of it shows: in over the rise's first part, out as it climbs away.
func shown() -> float:
	var k := clampf(t / (T_RISE * 0.5), 0.0, 1.0)
	return k * (1.0 - clampf((t - glide_end()) / DEPART, 0.0, 1.0))


## Staged: every piece where the path puts it, its height and its look; the shadow; the houses in front see-through.
func _pose(delta: float) -> void:
	var a := shown()
	var s_head := s_at(t)
	var climb := 0.0
	if t > glide_end():
		var k := clampf((t - glide_end()) / DEPART, 0.0, 1.0)
		climb = k * k * 90.0
	var rise := clampf(t / T_RISE, 0.0, 1.0)
	rise = 1.0 - (1.0 - rise) * (1.0 - rise)
	var rects: Array[Rect2] = []
	var feet: Array[float] = []
	var shade: Array = []
	var prev_sp := Vector2.INF
	var prev_alt := 0.0
	for piece in _pieces:
		var i := piece.index
		var s := s_head - float(i) * GAP if piece.kind != Piece.K_TAIL else s_head - (float(SEGMENTS) + 0.6) * GAP
		if a <= 0.0 or (i > 0 and s < 0.0):
			piece.visible = false
			continue
		var g := path_at(s)
		var sp := Iso.ground_to_screen(g).round()
		var out := rise if i == 0 else clampf(s / EMERGE, 0.0, 1.0)
		var alt := (LIFT + WAVE * sin(t * 2.4 - float(i) * 0.6)) * (1.0 - pow(1.0 - out, 2.0)) + climb
		piece.position = sp
		piece.alt = roundf(alt)
		piece.alpha = a * clampf(out * 3.0, 0.0, 1.0)
		piece.r = lerpf(R_NECK, R_TAIL, pow(float(maxi(i - 1, 0)) / float(SEGMENTS - 1), 1.3))
		piece.visible = true
		if piece.kind == Piece.K_HEAD:
			var ahead := Iso.ground_to_screen(path_at(s + 0.1)) - Iso.ground_to_screen(path_at(maxf(s - 0.1, 0.0)))
			if s <= 0.0:
				ahead = Iso.ground_to_screen(origin + _dir) - Iso.ground_to_screen(origin)
			var way: Array = head_for(ahead)
			piece.head = String(way[0])
			piece.mirror = bool(way[1])
			rects.append(Rect2(sp.x - HEAD_PIVOT.x, sp.y - piece.alt - HEAD_PIVOT.y, 64.0, 64.0))
		elif piece.kind == Piece.K_TAIL:
			piece.back = (sp + Vector2(0, -piece.alt)) - (prev_sp + Vector2(0, -prev_alt)) if prev_sp != Vector2.INF else -_dir
			rects.append(Rect2(sp.x - 64.0, sp.y - piece.alt - 32.0, 128.0, 64.0))
		else:
			rects.append(Rect2(sp.x - piece.r, sp.y - piece.alt - piece.r * 1.3, piece.r * 2.0, piece.r * 2.3))
		feet.append(sp.y)
		piece.queue_redraw()
		prev_sp = sp
		prev_alt = piece.alt
		if piece.kind != Piece.K_TAIL:
			var w := BAND if i == 0 else BAND * (0.5 + 0.4 * piece.r / R_NECK)
			shade.append([g, w, piece.alpha * (0.14 if i == 0 else 0.07)])
	_shade.pts = shade
	_shade.hole = 0.0 if s_head > float(SEGMENTS + 1) * GAP + EMERGE else a
	_shade.queue_redraw()
	# A white feather shed now and then as it goes.
	if a > 0.0 and t >= _next_feather and t < glide_end():
		_next_feather = t + 0.4
		var hp := _pieces[0].position + Vector2(0, -_pieces[0].alt)
		FxParts.debris(self, hp, 2, 10.0, Vector2(10, 40), FEATHERS, Vector2(1.0, 2.0), true)
	_see_through(rects, feet, delta)


## Whatever house stands in front of any piece (it overlaps that piece and its base sorts below the piece's foot) fades.
func _see_through(rects: Array[Rect2], feet: Array[float], delta: float) -> void:
	if ctx.env == null:
		return
	var front: Array = []
	if not rects.is_empty():
		var all := rects[0]
		for r in rects:
			all = all.merge(r)
		for s in ctx.env.structures():
			if not is_instance_valid(s) or s.destroyed:
				continue
			var box: Rect2 = s.view_box()
			if not box.intersects(all):
				continue
			var base: float = s.base_position().y
			for k in rects.size():
				if base > feet[k] and box.intersects(rects[k]):
					front.append(s)
					break
		_see.step(front, all, -1.0e9, delta)
	else:
		_see.step([], Rect2(), 0.0, delta)


## One piece of the serpent in the stand layer, at its ground point (so the layer sorts it), drawn `alt` px up: the head
## sprite, a scaled disc under its mantle of feathers, or the tail sprite turned back along the path.
class Piece extends Node2D:
	const K_HEAD := 0
	const K_BODY := 1
	const K_TAIL := 2
	var kind := K_BODY
	var index := 0
	var alt := 0.0
	var r := R_NECK
	var alpha := 1.0
	var head := "east"
	var mirror := false
	## The tail: the way it points on screen, from the body to its tip.
	var back := Vector2.LEFT

	func _draw() -> void:
		if alpha <= 0.0:
			return
		var tint := Color(1.0, 1.0, 1.0, alpha)
		match kind:
			K_HEAD:
				var tex: Texture2D = HEADS.get(head)
				if tex == null:
					return
				draw_set_transform(Vector2(0.0, -alt), 0.0, Vector2(-1.0 if mirror else 1.0, 1.0))
				draw_texture(tex, -HEAD_PIVOT, tint)
				draw_set_transform(Vector2.ZERO)
			K_TAIL:
				var b := back if back.length() > 0.001 else Vector2.LEFT
				# Pointing left as drawn: turned to `back`, mirrored when it points right so the feathers stay on top.
				var flip := b.x > 0.0
				draw_set_transform(Vector2(0.0, -alt), b.angle() if flip else b.angle() - PI, Vector2(-1.0 if flip else 1.0, 1.0))
				draw_texture(TAIL, -TAIL_ATTACH, tint)
				draw_set_transform(Vector2.ZERO)
			_:
				_disc(tint)

	## A disc of dark green scales, a lighter sheen low on it, and over its top a mantle of white feathers with grey tips.
	func _disc(tint: Color) -> void:
		var c := Vector2(0.0, -alt)
		draw_circle(c + Vector2(0.0, 1.0), r, (SCALE_DARK * 0.7) * tint)
		draw_circle(c, r, SCALE_DARK * tint)
		draw_circle(c + Vector2(-r * 0.1, r * 0.25), r * 0.62, SCALE_LIGHT * tint)
		for k in 3:
			var dot := c + Vector2(-r * 0.4 + r * 0.4 * float(k), r * (0.45 + 0.1 * float(k % 2)))
			draw_rect(Rect2(dot.round(), Vector2(1, 1)), SCALE_DARK * tint)
		draw_circle(c + Vector2(0.0, -r * 0.3), r * 0.84, FEATHER_SHADE * tint)
		draw_circle(c + Vector2(0.0, -r * 0.45), r * 0.66, FEATHER * tint)
		# The feathers' ragged lower edge, pointing down and back.
		for k in 4:
			var x := -r * 0.6 + r * 0.4 * float(k)
			var top := c + Vector2(x, r * 0.15)
			var tri := PackedVector2Array([top + Vector2(-r * 0.18, 0.0), top + Vector2(r * 0.18, 0.0),
				top + Vector2(r * 0.05, r * 0.32)])
			draw_colored_polygon(tri, (FEATHER if k % 2 == 0 else FEATHER_SHADE) * tint)


## The serpent's shadow on the ground (ground units, ground layer): a soft dark band under the head and body, and the hole it
## came out of while its body is still pouring out.
class Shade extends Node2D:
	var fx: PaleSerpentFx
	## [ground point, radius, alpha] per piece.
	var pts: Array = []
	var hole := 0.0

	func _draw() -> void:
		if not is_instance_valid(fx):
			return
		if hole > 0.0:
			draw_circle(fx.origin, 0.9, Color(0.02, 0.03, 0.03, 0.45 * hole))
			draw_circle(fx.origin, 0.6, Color(0.0, 0.0, 0.0, 0.35 * hole))
		for p in pts:
			draw_circle(p[0], float(p[1]), Color(0.0, 0.0, 0.03, float(p[2])))
