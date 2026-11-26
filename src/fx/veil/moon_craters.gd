class_name MoonCraters
extends Node2D
## The Moon's Face, The Swallowing Dark's level-5 twist (Veil twists, round 2): where the dark closed the ground is left pitted with
## craters, about a third of the circle. Who stays in one is hurt a quarter of his health a second, quietly (the health only: no panic,
## no enemy_struck, nobody woken, a sleeper or a shadow's owner hurt all the same) and taken at nought (VeilParts.take_out, no body);
## who only walks through lives. The god's spared (Crowd.spared) are eyed and never hurt, whoever is indoors is passed over.
##
## A lasting ground node (SolarisPit.GROUP), kept for the mission like BareEarth: Battlefield.clear_effects() frees it. Its placement
## is a pure function of the cast (place(): seeded, never the run's rng). Not an FxTimeline, so its eyes are PaleEye.mark_by() ones,
## closed when it leaves the tree.

const R_MIN := 1.2
const R_MAX := 2.8
## How many craters at the light and the dark size (about a third of the circle either way).
const COUNT := [9, 20]
## Health lost a second in a crater (a citizen's 1.0 lasts 4 s, a soldier's 2.0 lasts 8).
const CRATER_HURT := 0.25
const TICK := 0.25
const EYE_KEY := "crater"
const TRIES := 60
const GAP := 0.15
const SPIN := 0.35
const RIM_COL := Color(0.17, 0.12, 0.19, 0.92)
const LIP_COL := Color(0.30, 0.23, 0.30, 0.85)
const SWIRL_COL := Color(0.725, 0.549, 1.0, 0.22)

## [[centre: Vector2, radius: float], ...], in ground units.
var circles: Array = []
## Instance ids of the people a crater took.
var taken: Array[int] = []
var crowd: Crowd
var field: EnemyField
## Where the eyes are drawn (the cast's overhead layer).
var eye_layer: Node
var _acc := 0.0
var _eyed := {}  # instance id -> Person, eyed at the last tick
var _swirls: Array[Swirl] = []


## The craters of a cast at `origin`: `count` of them, each of radius R_MIN..R_MAX, inside `full_r`, clear of one another and of every
## `keep_out` entry (a Rect2 or a Vector2 point of the ground). Up to TRIES tries each; one that finds no room is left out. The same
## inputs give the same craters.
static func place(origin: Vector2, full_r: float, count: int, seed_value: int, keep_out: Array) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	for i in count:
		for attempt in TRIES:
			var r := rng.randf_range(R_MIN, R_MAX)
			var room := full_r - r
			if room <= 0.0:
				continue
			var centre := origin + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * room
			if _clear(centre, r, out, keep_out):
				out.append([centre, r])
				break
	return out


static func _clear(centre: Vector2, r: float, placed: Array, keep_out: Array) -> bool:
	for c: Array in placed:
		if centre.distance_to(c[0]) < r + float(c[1]) + GAP:
			return false
	for k in keep_out:
		if k is Rect2:
			var rect: Rect2 = k
			var near := Vector2(clampf(centre.x, rect.position.x, rect.end.x), clampf(centre.y, rect.position.y, rect.end.y))
			if near.distance_to(centre) < r + GAP:
				return false
		elif k is Vector2:
			if centre.distance_to(k) < r + GAP:
				return false
	return true


func _init() -> void:
	z_index = 1
	add_to_group(SolarisPit.GROUP)


func _ready() -> void:
	for i in circles.size():
		var s := Swirl.new()
		s.position = circles[i][0]
		s.r = float(circles[i][1])
		s.k = i
		s.z_index = 1
		add_child(s)
		_swirls.append(s)
	queue_redraw()


func covers(at: Vector2) -> bool:
	for c: Array in circles:
		if at.distance_squared_to(c[0]) <= float(c[1]) * float(c[1]):
			return true
	return false


func _physics_process(delta: float) -> void:
	step(delta)


## Advances the craters' clock; every TICK the hurt is dealt.
func step(delta: float) -> void:
	for s in _swirls:
		if is_instance_valid(s):
			s.rotation += delta * SPIN * (1.0 if s.k % 2 == 0 else -1.0)
	_drop_leavers()
	_acc += delta
	if _acc < TICK - 0.001:
		return
	var span := _acc
	_acc = 0.0
	_hurt(span)


## Whoever went indoors or left every crater since the last look is unmarked at once: PaleEye would close his eye for good once he
## is indoors, and a later stay would never be eyed again.
func _drop_leavers() -> void:
	if _eyed.is_empty():
		return
	for id: int in _eyed.keys():
		var p: Person = _eyed[id] if is_instance_valid(_eyed[id]) else null
		if p == null:
			_eyed.erase(id)
		elif not p.is_alive() or p.inside or not covers(p.ground_pos):
			if is_instance_valid(crowd):
				PaleEye.unmark_by(crowd, get_instance_id(), p)
			_eyed.erase(id)


func _hurt(span: float) -> void:
	if circles.is_empty() or field == null or not is_instance_valid(field):
		return
	var reach := 0.0
	var mid := Vector2.ZERO
	for c: Array in circles:
		mid += c[0] as Vector2
	mid /= float(circles.size())
	for c: Array in circles:
		reach = maxf(reach, mid.distance_to(c[0]) + float(c[1]))
	var now := {}
	for e in field.in_radius(mid, reach):
		var p := e as Person
		if p == null or not is_instance_valid(p) or not p.is_alive() or p.inside or not covers(p.ground_pos):
			continue
		now[p.get_instance_id()] = p
		if is_instance_valid(crowd):
			PaleEye.mark_by(crowd, get_instance_id(), p, EYE_KEY, TICK + 0.6, eye_layer)
		if is_instance_valid(crowd) and crowd.spared(p):
			continue
		p.health -= CRATER_HURT * span
		p.flash(0.08)
		if p.health <= 0.0:
			if VeilParts.take_out(crowd, p, &"void"):
				taken.append(p.get_instance_id())
			PaleEye.unmark_by(crowd, get_instance_id(), p)
	for id: int in _eyed:
		if not now.has(id) and is_instance_valid(_eyed[id]):
			PaleEye.unmark_by(crowd, get_instance_id(), _eyed[id])
	_eyed = now


func _exit_tree() -> void:
	_close_eyes()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_close_eyes()


func _close_eyes() -> void:
	if crowd != null and is_instance_valid(crowd):
		for id: int in _eyed:
			if is_instance_valid(_eyed[id]):
				PaleEye.unmark_by(crowd, get_instance_id(), _eyed[id])
		PaleEye.release_by(crowd, get_instance_id())
	_eyed.clear()


## The pits and their slumped rims, drawn once (no per-frame cost: only the swirls turn).
func _draw() -> void:
	for i in circles.size():
		var centre: Vector2 = circles[i][0]
		var r: float = circles[i][1]
		var rng := RandomNumberGenerator.new()
		rng.seed = i * 7919 + 13
		var lip := PackedVector2Array()
		var rim := PackedVector2Array()
		var pit := PackedVector2Array()
		var n := 28
		for j in n:
			var a := float(j) / float(n) * TAU
			var slump := 1.0 + rng.randf_range(-0.07, 0.10)
			var dir := Vector2.from_angle(a)
			lip.append(centre + dir * r * 1.16 * slump)
			rim.append(centre + dir * r * 1.02 * slump)
			pit.append(centre + dir * r * 0.82 * (1.0 + rng.randf_range(-0.05, 0.05)))
		draw_colored_polygon(lip, LIP_COL)
		draw_colored_polygon(rim, RIM_COL)
		draw_colored_polygon(pit, Color(VeilParts.BLACK, 0.96))
		var deep := PackedVector2Array()
		for q in pit:
			deep.append(centre + (q - centre) * 0.55)
		draw_colored_polygon(deep, Color(VeilParts.DUSK, 0.35))


## A faint swirl turning in a pit (look only; the node's rotation is all that moves).
class Swirl extends Node2D:
	var r := 1.0
	var k := 0

	func _draw() -> void:
		for arm in 2:
			var pts := PackedVector2Array()
			var base := float(arm) * PI
			for j in 13:
				var u := float(j) / 12.0
				pts.append(Vector2.from_angle(base + u * 3.2) * r * (0.12 + 0.62 * u))
			draw_polyline(pts, SWIRL_COL, 0.14)
