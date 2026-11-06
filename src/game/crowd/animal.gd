class_name Animal
extends Node2D
## A town dog or cat (Discord idea "Animals"): it wanders near its home spot, sits a while, a dog may tag along behind
## a passer-by, and it runs from danger. It is not a Person and not in EnemyField, so no power that hits people hits
## it, and no reference changes while nothing targets it. The mind powers can (AnimalPack.cast()): Madness Bloom,
## Manufactured Hatred and Mob Verdict turn it on people (it bites; a soldier beside it kills it), Divine
## Congregation draws it to the gathering, Clear Mind makes it sit. It never lights a fire or harms a building.
## AnimalPack steps it (step()); it draws itself in code, in its own small pixel shape, at the ground point.

enum Breed { HOUND, SHEPHERD, TERRIER, TABBY, BLACK_CAT, GREY_CAT }
enum State { WANDER, SIT, FOLLOW, FLEE, ATTACK, GATHER, TRANCE, DEAD }
## What a power asks of it (cast()).
enum Spell { ATTACK, GATHER, TRANCE }

## Body, dark (ears, nose, saddle), light (muzzle, belly, eyes) per breed.
const PALETTE := {
	Breed.HOUND: [Color("8a5a32"), Color("4a2c18"), Color("d8b080")],
	Breed.SHEPHERD: [Color("a8743c"), Color("2a2018"), Color("d8b070")],
	Breed.TERRIER: [Color("e2dccb"), Color("6a5040"), Color("fff8e8")],
	Breed.TABBY: [Color("d08a3a"), Color("7a4a1a"), Color("f0c890")],
	Breed.BLACK_CAT: [Color("2c2832"), Color("18161c"), Color("4a4652")],
	Breed.GREY_CAT: [Color("8a8a92"), Color("4a4a52"), Color("d4d4dc")],
}
const OUTLINE := Color(0.08, 0.06, 0.06, 0.6)
## Pixel shapes facing right, the feet on the last row: B body, D dark (ears, underside), L light (back, muzzle), K eye
## and nose, S / s the saddle (a shepherd's dark back; else light / body). Two walking frames differ only in the legs.
const DOG_BODY := [
	"........DD...",
	"T.......BBBB.",
	"T.......BKBLK",
	".TSSSSSSBBLL.",
	"..sssssBBBB..",
	"..BBBBBBBB...",
	"..DDDDDDDD...",
]
const DOG_LEGS := [["..D.B...D.B..", "..D.B...D.B.."], ["...DB....DB..", "..D..B..D..B."]]
const DOG_SIT := [
	".....DD..",
	".....BBBB",
	".....BKLK",
	"....BBLL.",
	"...SBBB..",
	"..SsBBB..",
	"..BBBBB..",
	"TTBBDBB..",
	".DDDDDDD.",
]
const CAT_BODY := [
	"T......D.D.",
	"T......BBB.",
	".T.....BKBL",
	"..LLLLLBBB.",
	"..BBBBBBB..",
	"..DDDDDDD..",
]
const CAT_LEGS := [["..B.B..B.B."], ["...BB...BB."]]
const CAT_SIT := [
	"...D.D.",
	"...BBB.",
	"...KBK.",
	"...BLB.",
	"..LBBB.",
	"..BBBBB",
	"..BBBBB",
	"T.BDBDB",
	".TDD.DD",
]
const EYE := Color("1a1414")
## A black cat's eyes shine.
const CAT_EYE := Color("e8d040")

const DOG_SPEED := 0.75
const CAT_SPEED := 0.6
const RUN := 2.2
## A bite: a dog's takes a quarter of a citizen's health, a cat's scratch a sixth; one every BITE_EVERY.
const DOG_BITE := 0.25
const CAT_BITE := 0.16
const BITE_EVERY := 0.9
const REACH := 0.4
## How far a maddened animal looks for someone to go for.
const HUNT_SIGHT := 6.0

var breed := Breed.HOUND
var state := State.WANDER
var ground_pos := Vector2.ZERO
var home := Vector2.ZERO
var facing := 1
var health := 1.0
var spell_left := 0.0
## Who it goes for (ATTACK) or follows (FOLLOW); null for whoever is nearest.
var target: Person
## Where it walks (WANDER, GATHER) or runs from (FLEE).
var goal := Vector2.ZERO
var wait := 0.0
var _bite_in := 0.0
var _anim := 0.0
var _frame := 0
var _flash := 0.0
## Moving up the screen (the sprite shows its back view).
var back := false
## Sprite timing: seconds in the current pose, and since the last bite (a bite plays once).
var _pose := &""
var _pose_t := 0.0
var _bite_t := 99.0
var _shown := -1

## PixelLab sheets (tools/dev/make_animal_sheet.py) by breed; a breed without one keeps its drawn shape.
const SHEETS := {Breed.HOUND: "res://assets/pixellab/animals/hound.png"}
enum Row { STILL, WALK_SE, WALK_NE, SIT, BITE }
const WALK_FPS := 8.0
const SIT_FPS := 8.0
const BITE_FPS := 14.0
static var _sheets := {}


func is_dog() -> bool:
	return breed <= Breed.TERRIER


func is_alive() -> bool:
	return state != State.DEAD


func hypnotized() -> bool:
	return state in [State.ATTACK, State.GATHER, State.TRANCE] and spell_left > 0.0


func speed() -> float:
	var base := DOG_SPEED if is_dog() else CAT_SPEED
	if breed == Breed.TERRIER:
		base *= 0.85
	if state in [State.FLEE, State.ATTACK]:
		return base * RUN
	return base


func bite() -> float:
	return DOG_BITE if is_dog() else CAT_BITE


## A power's hold on it for `seconds`: go for `who` (or the nearest, ATTACK), walk to `to` and sit (GATHER), or sit
## still and calm (TRANCE). The dead do not hear it.
func cast(spell: Spell, seconds: float, who: Person = null, to := Vector2.INF) -> bool:
	if not is_alive():
		return false
	spell_left = seconds
	target = who
	match spell:
		Spell.ATTACK:
			state = State.ATTACK
			_bite_in = 0.3
		Spell.GATHER:
			state = State.GATHER
			goal = to if to != Vector2.INF else ground_pos
		Spell.TRANCE:
			state = State.TRANCE
	wait = 0.0
	queue_redraw()
	return true


## Free again: back to its day.
func release() -> void:
	if not is_alive():
		return
	spell_left = 0.0
	target = null
	state = State.WANDER
	wait = 0.5
	goal = ground_pos
	queue_redraw()


func die() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	spell_left = 0.0
	target = null
	z_index = -1  # a body lies under whoever walks past
	queue_redraw()


func hurt(amount: float) -> void:
	if not is_alive():
		return
	health -= amount
	_flash = 0.1
	if health <= 0.0:
		die()


func sync_position() -> void:
	position = Iso.ground_to_screen(ground_pos)


## One step of `delta` toward `to` at its speed, on walkable ground only: true when it got there.
func walk_to(to: Vector2, delta: float, grid: WalkGrid) -> bool:
	var d := to - ground_pos
	var dist := d.length()
	if dist < 0.05:
		return true
	var step := minf(speed() * delta, dist)
	var next := ground_pos + d / dist * step
	if grid != null and not grid.walkable(next):
		# Slide along whichever axis is open, else give up on this goal.
		var slid := false
		for alt in [Vector2(next.x, ground_pos.y), Vector2(ground_pos.x, next.y)]:
			if grid.walkable(alt):
				next = alt
				slid = true
				break
		if not slid:
			return true
	var screen_dx := (next.x - ground_pos.x) - (next.y - ground_pos.y)
	if absf(screen_dx) > 0.0005:
		facing = 1 if screen_dx > 0.0 else -1
	var screen_dy := (next.x - ground_pos.x) + (next.y - ground_pos.y)
	if absf(screen_dy) > 0.0005:
		back = screen_dy < 0.0
	ground_pos = next
	_anim += delta * speed() * 7.0
	var f := int(_anim) % 2
	if f != _frame:
		_frame = f
	sync_position()
	queue_redraw()
	return false


func tick_visual(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0:
			queue_redraw()
	var sh := sheet(breed)
	if sh.is_empty():
		return
	_pose_t += delta
	_bite_t += delta
	var pose := _pose_now()
	if pose != _pose:
		_pose = pose
		_pose_t = 0.0
	var f := _sprite_frame(sh)
	if f != _shown:
		_shown = f
		queue_redraw()


## A bite landed: the sprite plays its bite once.
func bit() -> void:
	_bite_t = 0.0


## The breed's sheet: {tex, cell, foot, frames}; empty when it has none (or it is not imported).
static func sheet(b: Breed) -> Dictionary:
	if _sheets.has(b):
		return _sheets[b]
	var out := {}
	var path: String = SHEETS.get(b, "")
	if path != "" and ResourceLoader.exists(path) and FileAccess.file_exists(path + ".json"):
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".json"))
		if meta is Dictionary:
			out = {"tex": load(path), "cell": int(meta.cell), "foot": Vector2(meta.foot[0], meta.foot[1]),
				"frames": meta.frames}
	_sheets[b] = out
	return out


func _pose_now() -> StringName:
	if state == State.DEAD:
		return &"dead"
	if _bite_t < 1.0:
		return &"bite"
	if _sitting():
		return &"sit"
	if moving():
		return &"walk"
	return &"still"


## The frame on show as row * 100 + column.
func _sprite_frame(sh: Dictionary) -> int:
	var frames: Array = sh.frames
	var row := Row.STILL
	var col := 1 if back else 0
	match _pose:
		&"bite":
			row = Row.BITE
			col = int(_bite_t * BITE_FPS)
			if col >= int(frames[row]):
				_bite_t = 99.0
				col = 0
				row = Row.STILL
		&"sit":
			row = Row.SIT
			col = mini(int(_pose_t * SIT_FPS), int(frames[row]) - 1)
		&"walk":
			row = Row.WALK_NE if back else Row.WALK_SE
			col = int(_anim * 1.2)
	if int(frames[row]) == 0:
		return Row.STILL * 100 + (1 if back else 0)
	return row * 100 + col % int(frames[row])


func moving() -> bool:
	return state in [State.WANDER, State.FOLLOW, State.FLEE, State.ATTACK, State.GATHER] and wait <= 0.0


func _draw() -> void:
	var pal: Array = PALETTE[breed]
	var shadow := Rect2(-5, -1, 10, 2) if is_dog() else Rect2(-4, -1, 8, 2)
	var sc := Color(0, 0, 0, 0.28)
	var look_shadow := Person.foot_shadow(shadow, sc)
	draw_rect(look_shadow[0], look_shadow[1])
	if state == State.DEAD:
		var dsh := sheet(breed)
		if not dsh.is_empty():
			# On its side: the still pose turned over, dull.
			var c: int = dsh.cell
			var ft: Vector2 = dsh.foot
			draw_set_transform(Vector2(0, -2), PI / 2.0 * facing, Vector2(0.8, 1.0))
			draw_texture_rect_region(dsh.tex, Rect2(-ft.x, -ft.y * 0.5, c, c), Rect2(0, 0, c, c),
					Color(0.6, 0.55, 0.55))
			draw_set_transform(Vector2.ZERO)
			return
		_draw_rows(_shape_body(), pal, true, Color(0.55, 0.5, 0.5))
		return
	var tint := Color.WHITE if _flash <= 0.0 else Color(2.0, 2.0, 2.0)
	var sh := sheet(breed)
	if not sh.is_empty():
		_draw_sheet(sh, tint)
	else:
		_draw_rows(_shape(), pal, false, tint)
	_draw_mark()


## The PixelLab frame, feet on the ground point, mirrored for the west-facing views.
func _draw_sheet(sh: Dictionary, tint: Color) -> void:
	var f := _sprite_frame(sh)
	var cell: int = sh.cell
	var foot: Vector2 = sh.foot
	var src := Rect2((f % 100) * cell, (f / 100) * cell, cell, cell)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(float(facing), 1.0))
	draw_texture_rect_region(sh.tex, Rect2(-foot.x, -foot.y, cell, cell), src, tint)
	draw_set_transform(Vector2.ZERO)


func _sitting() -> bool:
	return state in [State.SIT, State.TRANCE] or (state == State.GATHER and wait > 0.0) \
			or (not moving() and state != State.ATTACK)


func _shape() -> Array:
	if _sitting():
		return DOG_SIT if is_dog() else CAT_SIT
	var legs: Array = (DOG_LEGS if is_dog() else CAT_LEGS)[_frame]
	var rows: Array = _shape_body().duplicate()
	rows.append_array(legs)
	return rows


func _shape_body() -> Array:
	var rows: Array = (DOG_BODY if is_dog() else CAT_BODY).duplicate()
	if breed == Breed.TERRIER:
		rows.remove_at(5)  # a short, small dog
	return rows


## The rows centred on the feet, mirrored by facing; lying (dead) on its side, flat and dull.
func _draw_rows(rows: Array, pal: Array, lying: bool, tint: Color) -> void:
	var h := rows.size()
	var w: int = (rows[0] as String).length()
	var ox := -w / 2
	var saddle: Color = pal[1] if breed == Breed.SHEPHERD else pal[2]
	if lying:
		# On its side: the body rows only, squashed to every other row, lying on the ground.
		for y in h:
			if y % 2 == 1:
				continue
			_row(rows[y], ox, -2 + y / 2, pal, saddle, tint, true)
		return
	# A thin outline: an empty pixel beside (not diagonal to) a filled one, in a dark tint of its own coat, so the
	# gaps between the legs stay open.
	var line: Color = (pal[1] as Color).darkened(0.55)
	line.a = OUTLINE.a
	for y in range(-1, h + 1):
		for x in range(-1, w + 1):
			if _filled(rows, x, y):
				continue
			if _filled(rows, x - 1, y) or _filled(rows, x + 1, y) or _filled(rows, x, y - 1) or _filled(rows, x, y + 1):
				draw_rect(Rect2(_px(ox + x), y - h, 1, 1), line)
	for y in h:
		_row(rows[y], ox, y - h, pal, saddle, tint, false)


func _filled(rows: Array, x: int, y: int) -> bool:
	if y < 0 or y >= rows.size():
		return false
	var s: String = rows[y]
	return x >= 0 and x < s.length() and s[x] != "."


func _row(s: String, ox: int, y: int, pal: Array, saddle: Color, tint: Color, dull: bool) -> void:
	for x in s.length():
		var ch := s[x]
		if ch == ".":
			continue
		var c: Color
		match ch:
			"D":
				c = pal[1]
			"L":
				c = pal[2]
			"S":
				c = saddle
			"s":
				c = pal[1] if breed == Breed.SHEPHERD else pal[0]
			"K":
				c = CAT_EYE if breed == Breed.BLACK_CAT else EYE
			_:
				c = pal[0]
		c = c * tint if not dull else c.lerp(Color(0.25, 0.2, 0.2), 0.45)
		c.a = 1.0
		draw_rect(Rect2(_px(ox + x), y, 1, 1), c)


func _px(x: int) -> int:
	return x if facing > 0 else -x - 1


## Under a power: a ring at its feet and a small glyph over it, red going for someone, gold gathering, pale in a trance.
func _draw_mark() -> void:
	if not hypnotized():
		return
	var c := Color("e04040")
	if state == State.GATHER:
		c = Color("ffd86a")
	elif state == State.TRANCE:
		c = Color("c8d8ff")
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.5))
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 14, c, 1.0)
	draw_set_transform(Vector2.ZERO)
	var top := -13 if is_dog() else -12
	draw_rect(Rect2(-2, top - 3, 5, 3), Color(0.05, 0.03, 0.06, 0.8))
	draw_rect(Rect2(-1, top - 2, 3, 1), c)
	draw_rect(Rect2(0, top - 3, 1, 3), c)
