class_name PaleSerpentFx
extends FxTimeline
## The Pale Serpent (Death, Tier V; spec 5.7): a drag, once a descent. A vast feathered serpent -- white feathers over dark
## green scales, the novel's Death Consul -- bursts up out of the ground at the press over T_RISE, glides along the drag
## (LENGTH at most, MIN_LENGTH at least) over GLIDE, then loops once through the end, a circle of CIRCLE_R turned to the
## drag's left (Vector2.orthogonal()) over CIRCLE, and climbs away into the dark over DEPART.
## - Its shadow kills: each step, everyone out in the open (not indoors, not guised -- Corpse Guise hides the faithful, as
##   The Gate Below and Pale Reign spare them -- and no decoy, Mirrorfold's glass twin) within BAND of the head's path swept that step dies at once, without a
##   sound or a mark, killed as &"shadow" (a whole body: it leaves a remain, ready to rise; a quiet kind,
##   DeathVoices.QUIET_KINDS). No luck: everyone in the band dies, in instance-id order. A long frame is swept in steps of
##   STEP at most, so nobody is skipped. Houses are left standing: nothing here touches a structure.
## - Its sight sickens: as it rises, everyone out in the open within SIGHT of it (not indoors, not guised) walks at
##   SICK_PACE for SICK (hold_pace under this effect's id), and catches the plague too (PlagueManager.PLAGUE_LIFE) when
##   Pestilence's is in town (plague_live(): anyone sick). Let go at SICK, at the end, and when freed without one.
## Loud (PowerBook.REACH): the danger counts from the head risen (IMPACT = T_RISE, the first shadow); every FRIGHT_EVERY
## while it glides the street within FRIGHT_R of the head runs. No hush.
## Its souls (R11): each one the shadow takes gives up a soul that streams into its body, arriving SOUL_FLY after the kill
## (souls_in, on the effect's clock, staged or not; drawn as a SoulWisp only when staged).
## Drawn (staged only) in the stand layer, y-sorted, at SCALE: the head (the Task 1 sheet, picked for its heading on screen
## among eight ways, the west three the east three mirrored), raised on its neck so that the sheet's neck socket
## (NECK_SOCKET) sits on the collar, a disc under the head that the body runs on from -- one seamless body; a procedural
## chain of SEGMENTS scaled discs under a mantle of white feathers trailing the head's path GAP apart (the part still in the
## hole a column pouring up out of it), and the tail sprite turned back along the path; their shadow on the ground below; a
## cold light under the head and pale wisps of souls trailing off the tail; and whatever house stands in front of any of it
## goes see-through (SeeThrough). pieces_at() places every piece; _pose() only draws what it says.

## The brief's numbers: the longest drag, the glide, the loop's radius and time, the shadow's half width, how far it is seen
## and how long the sight sickens.
const LENGTH := 14.0
const GLIDE := 10.0
const CIRCLE_R := 4.0
const CIRCLE := 3.0
## A 4-wide kill lane (R11).
const BAND := 2.0
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
## Its size (R11, twice the first cut): the head and tail sprites drawn at SCALE (a 128 px head, six people tall);
## SEGMENTS discs GAP apart along the path (30 x 0.45 = 13.5 ground units of body), R_NECK px in radius at the collar
## (56 px across) tapering to R_TAIL at the tail; the body glides LIFT px over its shadow, rising and falling WAVE px down
## its length, the head raised over it on its neck.
const SCALE := 2.0
const SEGMENTS := 30
const GAP := 0.45
const R_NECK := 28.0
const R_TAIL := 16.0
const LIFT := 60.0
const WAVE := 10.0
## The part of the body still in the hole stands up out of it as a column: COLUMN px of height per ground unit of body
## (a disc GAP behind another is GAP * COLUMN px lower), so it pours up out of the ground without a break.
const COLUMN := 40.0
const HEAD_PIVOT := Vector2(32, 36)
## The head as a piece of the body: half the drawn sprite (for the joint check, pieces_at()).
const HEAD_R := 32.0 * SCALE
## Where each head's neck is cut off on its sheet (sprite px from HEAD_PIVOT): the centre of the lowest opaque row, where
## the neck leaves the sheet (measured by tools/dev/serpent_neck_socket.py). The collar disc sits here, under the head.
const NECK_SOCKET := {
	"east": Vector2(3.5, 27.0),
	"south-east": Vector2(-9.0, 28.0),
	"south": Vector2(0.0, 28.0),
	"north-east": Vector2(3.5, 28.0),
	"north": Vector2(0.0, 28.0)}
## Where the tail sprite meets the body: its right edge, halfway down.
const TAIL_ATTACH := Vector2(60, 24)
## A soul's flight from the one who fell into the body (seconds).
const SOUL_FLY := 0.7
## The cold light under the head: its radius (ground units) and strength; a wisp of souls off the tail this often.
const GLOW_R := 2.6
const GLOW := 0.4
const WISP_EVERY := 0.15
## The hole it bursts out of (ground units).
const HOLE := 1.4
## Scales and feathers (the sheet's own colours).
const SCALE_DARK := Color("214d37")
const SCALE_LIGHT := Color("3b6748")
const FEATHER := Color("e2eeed")
const FEATHER_SHADE := Color("a4aeb7")
## Death's palette for the dust: bone and ash; no blood.
const DUST := [Color(0.85, 0.82, 0.74, 0.5), Color(0.6, 0.6, 0.6, 0.38), Color(0.42, 0.42, 0.44, 0.2), Color(0.3, 0.3, 0.32, 0.0)]
const BONE_CHIPS := [Color("d8d2bf"), Color("b8b2a0"), Color("8a8a8c")]
const FEATHERS := [Color("e2eeed"), Color("e2eeed"), Color("a4aeb7")]
## Death's pale soul-light (the colours of Raise the Dead's and The Gate Below's spirits).
const PALE := [Color("eaf4ff"), Color("c8f0dc"), Color(0.5, 0.9, 0.7, 0.5), Color(0.2, 0.4, 0.35, 0.0)]
## The soul-smoke trailing off it: the same pale hues, see-through.
const WISP := [Color(0.92, 0.96, 1.0, 0.55), Color(0.78, 0.94, 0.86, 0.42), Color(0.5, 0.9, 0.7, 0.25), Color(0.2, 0.4, 0.35, 0.0)]

## The dead, in the order the shadow took them; when the first fell (on the effect's clock).
var taken: Array[Person] = []
var first_kill_at := -1.0
## Everyone who saw it rise (sickened).
var sickened := 0
## The souls that have streamed into it (one per kill, SOUL_FLY after it).
var souls_in := 0

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
## When each soul still on its way arrives (the effect's clock).
var _souls: Array[float] = []
## Staged only: the pieces (head, collar, discs, tail), the shadow, the see-through, the cold light, the souls in flight.
var _pieces: Array[Piece] = []
var _shade: Shade
var _see: SeeThrough
var _glow: QuadFx
var _glow_at := Vector2.ZERO
var _wisps: Array[SoulWisp] = []
var _next_feather := T_RISE
var _next_wisp := T_RISE
## The pieces as last posed (souls fly to the nearest).
var _posed: Array[Dictionary] = []


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
	# The cold soul-light under the head, following it.
	_glow_at = origin
	_glow = FxParts.ground_light(self, origin, GLOW_R, DeathParts.PALE_FIRE, 0.0, func() -> Vector2: return _glow_at)
	# The burst out of the ground: bone dust and chips, a flurry of feathers, the ground shaking.
	var sp := Iso.ground_to_screen(origin)
	FxParts.smoke(self, sp, 60.0, 40.0, T_RISE, Vector2(10, 40), Vector2(4, 8), Vector2(0.8, 1.6), Color(0, 0, 0, 0), DUST)
	FxParts.debris(self, sp, 24, 50.0, Vector2(40, 140), BONE_CHIPS, Vector2(1.5, 3.0), true)
	FxParts.debris(self, sp + Vector2(0, -LIFT), 20, 36.0, Vector2(20, 90), FEATHERS, Vector2(1.5, 2.5), true)
	if ctx.shake != null:
		ctx.shake.add_trauma(0.4)


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
	_souls_arrive()
	while _next_fright < glide_end() and t >= _next_fright:
		var back := s_at(_next_fright) - FRIGHT_BACK
		if ctx.crowd != null and back >= 0.0:
			ctx.crowd.fright(path_at(back), FRIGHT_R, 0.9, 2.0, SIGHT, 16.0, &"beast")
		_next_fright += FRIGHT_EVERY
	if not _sick_over and t >= T_RISE + SICK:
		_sick_over = true
		_let_all_go()
	if t >= glide_end() + DEPART and _held.is_empty() and _souls.is_empty():
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
		if p == null or p.inside or p.guised() or p.has_meta(&"decoy"):
			continue  # a decoy (Mirrorfold's glass twin) is no one: the shadow passes over it, as Pale Reign's does
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
		var fell := when + span * u
		if first_kill_at < 0.0:
			first_kill_at = fell
		_souls.append(fell + SOUL_FLY)
		if not _pieces.is_empty():
			_soul_from(at_pt, fell)


## Every soul whose flight is over is in (the effect's clock: staged or not).
func _souls_arrive() -> void:
	var i := 0
	while i < _souls.size():
		if t >= _souls[i]:
			souls_in += 1
			_souls.remove_at(i)
		else:
			i += 1


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


## 0..1 how much of it shows at `time` (the effect's clock if none): in over the rise's first part, out as it climbs away.
func shown(time := -1.0) -> float:
	var x := t if time < 0.0 else time
	var k := clampf(x / (T_RISE * 0.5), 0.0, 1.0)
	return k * (1.0 - clampf((x - glide_end()) / DEPART, 0.0, 1.0))


## The head's neck socket off its pivot on screen (px) for a sheet [key, mirrored] from head_for(): NECK_SOCKET at SCALE.
static func socket_px(way: Array) -> Vector2:
	var sk: Vector2 = NECK_SOCKET.get(String(way[0]), Vector2.ZERO)
	return Vector2(-sk.x if bool(way[1]) else sk.x, sk.y) * SCALE


## Where every piece is at `time` (pure: nothing is touched): the head, the collar, the discs and the tail, in that order,
## each {"sp": its centre on screen, its height applied; "r": its radius (px); "kind": Piece.K_*; "g": its ground point;
## "alt": its height (px); "alpha"; "vis": drawn at all}; the head with its sheet ("head", "mirror"), the tail with the way
## it points on screen ("back"). The collar is the head's own point on the path at the body's height, and the head is
## raised over it so that its neck socket sits on it (socket_at()); the discs follow GAP apart along the path, the tail
## half a GAP past the last; whatever is still in the hole stands up out of it, COLUMN px lower per ground unit.
func pieces_at(time: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var a := shown(time)
	var s_head := s_at(time)
	var climb := 0.0
	if time > glide_end():
		var k := clampf((time - glide_end()) / DEPART, 0.0, 1.0)
		climb = k * k * 90.0
	var rise := clampf(time / T_RISE, 0.0, 1.0)
	rise = 1.0 - (1.0 - rise) * (1.0 - rise)
	for i in range(1, SEGMENTS + 2):
		var tail := i == SEGMENTS + 1
		var s := s_head - ((float(SEGMENTS) - 0.5) if tail else float(i - 1)) * GAP
		var g := path_at(s)
		var alt := (LIFT + WAVE * sin(time * 2.4 - float(i) * 0.6)) * rise + COLUMN * minf(s, 0.0) + climb
		var r := R_TAIL if tail else lerpf(R_NECK, R_TAIL, pow(float(i - 1) / float(SEGMENTS - 1), 1.3))
		# Still in the hole: hidden until its top clears the ground. The collar shows with the head.
		var alpha := a if i == 1 else a * clampf(alt / r, 0.0, 1.0)
		out.append({"sp": Iso.ground_to_screen(g) - Vector2(0.0, alt), "r": r, "kind": Piece.K_TAIL if tail else Piece.K_BODY,
			"g": g, "alt": alt, "alpha": alpha, "vis": alpha > 0.0})
	var back: Vector2 = out[SEGMENTS].sp - out[SEGMENTS - 1].sp
	out[SEGMENTS]["back"] = back if back.length() > 0.5 else Vector2.DOWN
	var ahead := Iso.ground_to_screen(path_at(s_head + 0.1)) - Iso.ground_to_screen(path_at(maxf(s_head - 0.1, 0.0)))
	if s_head <= 0.0:
		ahead = Iso.ground_to_screen(origin + _dir) - Iso.ground_to_screen(origin)
	var way: Array = head_for(ahead)
	var collar: Dictionary = out[0]
	out.push_front({"sp": (collar.sp as Vector2) - socket_px(way), "r": HEAD_R, "kind": Piece.K_HEAD, "g": collar.g,
		"alt": collar.alt, "alpha": a, "vis": a > 0.0, "head": String(way[0]), "mirror": bool(way[1])})
	return out


## The head's neck socket on screen at `time` (SCALE, mirror and height applied): where the collar, disc 1, is placed.
func socket_at(time: float) -> Vector2:
	var h: Dictionary = pieces_at(time)[0]
	return (h.sp as Vector2) + socket_px([h.head, h.mirror])


## Staged: every piece where pieces_at() puts it (in whole px; the head drawn off its collar, so the joint never slips);
## the shadow; the cold light; feathers and soul wisps trailing; the souls in flight; the houses in front see-through.
func _pose(delta: float) -> void:
	var a := shown()
	var ps := pieces_at(t)
	_posed = ps
	var rects: Array[Rect2] = []
	var feet: Array[float] = []
	var shade: Array = []
	for k in ps.size():
		var q: Dictionary = ps[k]
		var piece := _pieces[k]
		if not bool(q.vis):
			piece.visible = false
			continue
		var foot := Iso.ground_to_screen(q.g).round()
		var alt := roundf(float(q.alt))
		var top := foot + Vector2(0.0, -alt)
		piece.visible = true
		piece.alpha = float(q.alpha)
		piece.r = float(q.r)
		piece.position = foot
		piece.lift = Vector2(0.0, -alt)
		match piece.kind:
			Piece.K_HEAD:
				piece.head = String(q.head)
				piece.mirror = bool(q.mirror)
				# A pixel in front of its collar, so the layer always draws the collar under the head.
				piece.position = foot + Vector2(0.0, 1.0)
				var pivot := top - socket_px([q.head, q.mirror])
				piece.lift = pivot - piece.position
				rects.append(Rect2(pivot - HEAD_PIVOT * SCALE, Vector2(64.0, 64.0) * SCALE))
			Piece.K_TAIL:
				piece.back = q.back
				rects.append(Rect2(top.x - 64.0 * SCALE, top.y - 32.0 * SCALE, 128.0 * SCALE, 64.0 * SCALE))
			_:
				rects.append(Rect2(top.x - piece.r, top.y - piece.r * 1.3, piece.r * 2.0, piece.r * 2.3))
		feet.append(foot.y)
		piece.queue_redraw()
		if piece.kind != Piece.K_TAIL:
			var w := BAND if k == 0 else BAND * (0.5 + 0.4 * piece.r / R_NECK)
			shade.append([q.g, w, piece.alpha * (0.14 if k == 0 else 0.07)])
	_shade.pts = shade
	var s_tail := s_at(t) - (float(SEGMENTS) - 0.5) * GAP
	_shade.hole = a * clampf(1.0 - s_tail, 0.0, 1.0)
	_shade.queue_redraw()
	# The cold light under the head.
	_glow_at = ps[0].g
	if is_instance_valid(_glow):
		_glow.position = _glow_at
		_glow.set_param("intensity", GLOW * a)
	# A white feather shed now and then as it goes.
	if a > 0.0 and t >= _next_feather and t < glide_end():
		_next_feather = t + 0.4
		FxParts.debris(self, (ps[0].sp as Vector2) + Vector2(0.0, 20.0), 2, 16.0, Vector2(10, 40), FEATHERS, Vector2(1.5, 2.5), true)
	# Pale wisps of souls trailing off the tail's tip, and off the body here and there.
	var tl: Dictionary = ps[ps.size() - 1]
	if bool(tl.vis) and t >= _next_wisp and t < glide_end() + DEPART * 0.6:
		_next_wisp = t + WISP_EVERY
		var tip: Vector2 = (tl.sp as Vector2) + (tl.back as Vector2).normalized() * (TAIL_ATTACH.x - 8.0) * SCALE
		_wisp(tip, 3, 8.0)
		var mid: Dictionary = ps[2 + posmod(roundi(t / WISP_EVERY) * 7, SEGMENTS - 1)]
		if bool(mid.vis):
			_wisp((mid.sp as Vector2) + Vector2(0.0, -float(mid.r) * 0.4), 2, float(mid.r) * 0.6)
	_fly_souls()
	_see_through(rects, feet, delta)


## A puff of pale soul-smoke at `sp` (screen), drifting up and fading.
func _wisp(sp: Vector2, count: int, radius_px: float) -> void:
	var p := FxParts.particles(self, ctx.overhead_back, sp, PixelParticles.Shape.PUFF, WISP)
	p.drag = 0.5
	p.burst(count, {"radius": radius_px, "speed": Vector2(4, 16), "alt": Vector2(0, 6), "alt_speed": Vector2(8, 26),
		"life": Vector2(0.7, 1.3), "size": Vector2(2, 4), "size_end_mul": 1.8})


## Staged: a soul rises from one the shadow took (at `at_ground`, fallen at `fell`) and flies into the body.
func _soul_from(at_ground: Vector2, fell: float) -> void:
	var w := SoulWisp.new()
	w.from = Iso.ground_to_screen(at_ground) + Vector2(0.0, -10.0)
	w.position = w.from
	w.born = fell
	_wisps.append(w)
	track(w, ctx.overhead)
	FxParts.sparks(self, ctx.overhead, w.from, 6, PALE, Vector2(10, 40), Vector2(30, 90))


## Every soul in flight on its way into the nearest piece of the body; one there sparks and is gone (souls_in counts it on
## the clock, staged or not: _souls_arrive()).
func _fly_souls() -> void:
	var i := 0
	while i < _wisps.size():
		var w := _wisps[i]
		if not is_instance_valid(w):
			_wisps.remove_at(i)
			continue
		var k := (t - w.born) / SOUL_FLY
		if k >= 1.0:
			FxParts.sparks(self, ctx.overhead, w.position, 5, PALE, Vector2(10, 50), Vector2(10, 60))
			w.queue_free()
			_wisps.remove_at(i)
			continue
		w.fly(clampf(k, 0.0, 1.0), _nearest(w.position))
		i += 1


## The nearest piece of the body drawn (screen), or `sp` itself if none is.
func _nearest(sp: Vector2) -> Vector2:
	var best := sp
	var d := INF
	for q in _posed:
		if bool(q.vis) and (q.sp as Vector2).distance_to(sp) < d:
			d = (q.sp as Vector2).distance_to(sp)
			best = q.sp
	return best


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


## One piece of the serpent in the stand layer, at its ground point (so the layer sorts it), drawn `lift` px off it: the head
## sprite (at SCALE, its pivot off its collar), a scaled disc under its mantle of feathers, or the tail sprite (at SCALE)
## turned back along the path.
class Piece extends Node2D:
	const K_HEAD := 0
	const K_BODY := 1
	const K_TAIL := 2
	var kind := K_BODY
	var index := 0
	## Where it is drawn from its ground point (px): straight up its height; for the head, its pivot.
	var lift := Vector2.ZERO
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
				draw_set_transform(lift, 0.0, Vector2(-SCALE if mirror else SCALE, SCALE))
				draw_texture(tex, -HEAD_PIVOT, tint)
				draw_set_transform(Vector2.ZERO)
			K_TAIL:
				var b := back if back.length() > 0.001 else Vector2.LEFT
				# Pointing left as drawn: turned to `back`, mirrored when it points right so the feathers stay on top.
				var flip := b.x > 0.0
				draw_set_transform(lift, b.angle() if flip else b.angle() - PI, Vector2(-SCALE if flip else SCALE, SCALE))
				draw_texture(TAIL, -TAIL_ATTACH, tint)
				draw_set_transform(Vector2.ZERO)
			_:
				_disc(tint)

	## The collar under the head: bare green scales in the neck's own colours, no feathers, so the neck runs on into it
	## (its upper half under the head; the lower a rounded end the body leaves from).
	func _collar(tint: Color) -> void:
		var c := lift
		draw_circle(c + Vector2(0.0, SCALE), r, (SCALE_DARK * 0.55) * tint)
		draw_circle(c, r, SCALE_DARK * tint)
		draw_circle(c + Vector2(0.0, -r * 0.08), r - 2.0 * SCALE, SCALE_LIGHT * tint)
		# The belly's scale bands, as on the neck.
		for k in 3:
			var y := r * (-0.1 + 0.3 * float(k))
			var half := sqrt(maxf(r * r - y * y, 0.0)) * 0.8
			draw_line(c + Vector2(-half, y), c + Vector2(half, y), SCALE_DARK * tint, SCALE)

	## A disc of dark green scales, a lighter sheen low on it, and over its top a mantle of white feathers with grey tips.
	func _disc(tint: Color) -> void:
		if index == 1:
			_collar(tint)
			return
		var c := lift
		draw_circle(c + Vector2(0.0, SCALE), r, (SCALE_DARK * 0.7) * tint)
		draw_circle(c, r, SCALE_DARK * tint)
		draw_circle(c + Vector2(-r * 0.1, r * 0.25), r * 0.62, SCALE_LIGHT * tint)
		for k in 3:
			var dot := c + Vector2(-r * 0.4 + r * 0.4 * float(k), r * (0.45 + 0.1 * float(k % 2)))
			draw_rect(Rect2(dot.round(), Vector2(SCALE, SCALE)), SCALE_DARK * tint)
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
			draw_circle(fx.origin, HOLE, Color(0.02, 0.03, 0.03, 0.45 * hole))
			draw_circle(fx.origin, HOLE * 0.67, Color(0.0, 0.0, 0.0, 0.35 * hole))
		for p in pts:
			draw_circle(p[0], float(p[1]), Color(0.0, 0.0, 0.03, float(p[2])))


## A soul flying (staged only, screen px in the overhead layer): a bright pale mote with a fading tail, rising from one the
## shadow took and swooping on an arc into the body.
class SoulWisp extends Node2D:
	var from := Vector2.ZERO
	var born := 0.0
	var _trail: Array[Vector2] = []
	var _k := 0.0

	## `k` 0..1 of the way from where they fell, up and over, into `to` (the nearest piece of the body).
	func fly(k: float, to: Vector2) -> void:
		_k = k
		var e := k * k * (3.0 - 2.0 * k)
		var mid := (from + to) * 0.5 + Vector2(0.0, -40.0 - from.distance_to(to) * 0.25)
		var p := from.lerp(mid, e).lerp(mid.lerp(to, e), e)
		var side := (to - from).orthogonal().normalized() if from.distance_to(to) > 0.5 else Vector2.RIGHT
		p += side * sin(k * PI * 3.0) * 5.0 * (1.0 - k)
		_trail.push_front(p)
		if _trail.size() > 9:
			_trail.pop_back()
		position = p
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(_k * 6.0, 0.0, 1.0)
		var n := _trail.size()
		for j in range(n - 1, 0, -1):
			var f := 1.0 - float(j) / float(n)
			draw_circle(_trail[j] - position, 1.0 + 2.5 * f, Color(0.78, 0.94, 0.86, 0.4 * f * fade))
		draw_circle(Vector2.ZERO, 7.0, Color(0.92, 0.96, 1.0, 0.16 * fade))
		draw_circle(Vector2.ZERO, 4.0, Color(0.92, 0.96, 1.0, 0.5 * fade))
		draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 0.95 * fade))
