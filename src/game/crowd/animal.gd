class_name Animal
extends Node2D
## A town dog or cat (Discord idea "Animals"): it wanders near its home spot, sits a while, a dog may tag along behind
## a passer-by, and it runs from danger. It is not a Person and not in EnemyField, so no power that hits people hits
## it, and no reference changes while nothing targets it. The mind powers can (AnimalPack.cast()): Madness Bloom,
## Manufactured Hatred and Mob Verdict turn it on people (it bites; a soldier beside it kills it), Divine
## Congregation draws it to the gathering, Clear Mind makes it sit. It never lights a fire or harms a building.
## AnimalPack steps it (step()); it draws itself in code, in its own small pixel shape, at the ground point.

## HELLHOUND is no town animal: a hound of the other side (Visitors, Hound Gate), half again a dog's size, never in
## DOGS and so never in the town's pack. DEMON (a horned brute a head taller than a man) and GHOST (a hooded shroud that
## hovers off the ground, half seen through) come from the same side (Visitors, Doors of the Dead): OTHER_SIDE, all
## three run at a dog's pace before their summoner's multiplier, and none is ever in the town's pack.
## Death's own dead (UNDEAD, Visitors via DeathParts) are of the same kind: ZOMBIE wears the dead person's own people sprite,
## greyed, with pale fire in its eyes (wear()); SPIRIT is a thin pale shape with a trailing wisp, drawn in code, no hood and
## half seen through, its face fading in and out (not Passage's GHOST); BONE_GIANT is the 96 px painted bone giant, drawn at
## its own size with a pale fire in its sockets. UNDEAD is kept apart from OTHER_SIDE so that list stays Passage's.
enum Breed { HOUND, SHEPHERD, TERRIER, TABBY, BLACK_CAT, GREY_CAT, WOLFHOUND, SPANIEL, WHITE_CAT, BROWN_CAT, HELLHOUND, DEMON, GHOST, ZOMBIE, SPIRIT, BONE_GIANT, WRAITH }
const OTHER_SIDE: Array[Breed] = [Breed.HELLHOUND, Breed.DEMON, Breed.GHOST]
const UNDEAD: Array[Breed] = [Breed.ZOMBIE, Breed.SPIRIT, Breed.BONE_GIANT, Breed.WRAITH]
const DOGS: Array[Breed] = [Breed.HOUND, Breed.SHEPHERD, Breed.TERRIER, Breed.WOLFHOUND, Breed.SPANIEL]
const CATS: Array[Breed] = [Breed.TABBY, Breed.BLACK_CAT, Breed.GREY_CAT, Breed.WHITE_CAT, Breed.BROWN_CAT]
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
	Breed.WOLFHOUND: [Color("8a8680"), Color("4a4844"), Color("c0bcb4")],
	Breed.SPANIEL: [Color("f0ece0"), Color("6a3a24"), Color("fffaf0")],
	Breed.WHITE_CAT: [Color("ecebe6"), Color("a8a6a0"), Color("ffffff")],
	Breed.BROWN_CAT: [Color("7a5a3a"), Color("3a2818"), Color("d8c0a0")],
	Breed.HELLHOUND: [Color("1c1a22"), Color("0c0a10"), Color("ff7a1a")],
	Breed.DEMON: [Color("2a1a1e"), Color("120a0c"), Color("ff6a1a")],
	Breed.GHOST: [Color("dfeeff"), Color("8aa8c8"), Color("ffffff")],
	Breed.ZOMBIE: [Color("8a8c86"), Color("4a4c48"), Color("d8d2bf")],
	Breed.SPIRIT: [Color("dfe6ea"), Color("9aa4aa"), Color("f4fbff")],
	Breed.BONE_GIANT: [Color("d8d2bf"), Color("5a5650"), Color("f2eedc")],
	Breed.WRAITH: [Color("dfe6ea"), Color("9aa4aa"), Color("f4fbff")],
}
## Death's dead (spec section 6): the palette is bone white, ash grey, pale-white fire, and grave green kept to eyes.
const SPIRIT_BODY := Color(0.86, 0.9, 0.94, 0.5)
const SPIRIT_HOVER := 5.0
const SPIRIT_BOB := 1.2
## The wraith's painted sheet (rows drift_se, drift_ne, strike_se; its json holds a [w, h] cell, so sheet() is not used).
const WRAITH_HOVER := 6.0
const WRAITH_BOB := 2.0
const WRAITH_SHEET := "res://assets/pixellab/fx/wraith/wraith.png"
## A wraith: the painted sheet (drift_ne with its back turned, strike_se while the bite pose plays, else drift_se), mirrored
## by `facing`, over a faint cold aura. Without the sheet on disk, the spirit shape at twice the size.
func _draw_wraith(flash: bool) -> void:
	var aura := DeathParts.GRAVE_GREEN
	draw_set_transform(Vector2(0, -8), 0.0, Vector2(1.0, 0.7))
	draw_circle(Vector2.ZERO, 9.0, Color(aura, 0.06))
	draw_circle(Vector2.ZERO, 6.0, Color(aura, 0.10))
	draw_set_transform(Vector2.ZERO)
	# It hovers 6 px with a 2 px bob (each wraith on its own phase), the aura staying on the ground.
	var lift := Vector2(0, -(WRAITH_HOVER + WRAITH_BOB * sin(_hover_t * 2.4 + float(get_instance_id() % 628) / 100.0)))
	var sh := _wraith_sheet()
	if sh.is_empty():
		draw_set_transform(lift.round(), 0.0, Vector2(2.0, 2.0))
		_draw_spirit(flash)
		draw_set_transform(Vector2.ZERO)
		return
	var row := 1 if back else 0
	var n: int = sh.frames[row]
	var f := int(_hover_t * float(sh.fps)) % n
	if _bite_t < 1.0:
		row = 2
		n = sh.frames[2]
		f = mini(int(_bite_t * float(sh.fps)), n - 1)
	var cell: Vector2 = sh.cell
	var foot: Vector2 = sh.foot
	var col := worn_tint * (Color(2.0, 2.0, 2.0) if flash else Color.WHITE)
	draw_set_transform(lift.round(), 0.0, Vector2(float(facing), 1.0))
	draw_texture_rect_region(sh.tex, Rect2(-foot, cell), Rect2(Vector2(f * cell.x, row * cell.y), cell), col)
	draw_set_transform(Vector2.ZERO)


## The wraith's sheet: {tex, cell, foot, fps, frames}; empty when it is not on disk or not imported.
static func _wraith_sheet() -> Dictionary:
	if _sheets.has(Breed.WRAITH):
		return _sheets[Breed.WRAITH]
	var out := {}
	var json := "res://assets/pixellab/fx/wraith/wraith.json"
	if ResourceLoader.exists(WRAITH_SHEET) and FileAccess.file_exists(json):
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(json))
		if meta is Dictionary:
			out = {"tex": load(WRAITH_SHEET), "cell": Vector2(meta.cell[0], meta.cell[1]),
				"foot": Vector2(meta.foot[0], meta.foot[1]), "fps": float(meta.fps), "frames": meta.frames}
	_sheets[Breed.WRAITH] = out
	return out


## The bone giant's eye sockets, from its feet, on the painted sheet (the skull faces the way it walks).
const GIANT_SOCKET := Vector2(13.0, -53.0)
const GIANT_FIRE := Color(0.92, 0.97, 1.0)
## A ghost hovers GHOST_HOVER px off the ground, bobbing GHOST_BOB px, and is drawn GHOST_TINT (the other side's green, a little seen through).
const GHOST_HOVER := 4.0
const GHOST_BOB := 1.5
const GHOST_TINT := Color(0.62, 1.0, 0.86, 0.85)
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
## A multiplier on its pace: 1.0 for the town's own animals; a power's beast (Visitors) runs at its own speed.
var speed_mul := 1.0
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
## What it does while it waits (AnimalPack picks one): sit, idle, sniff, scratch, bark or lie.
var idle := &"sit"
## Seconds since it last took a step: the walk shows only while it really moves.
var _since_move := 99.0
## A ghost's hover: seconds it has bobbed (a spirit's wisp and fading face, a zombie's sway, a giant's fire run on it too).
var _hover_t := 0.0
## A zombie's (wear()): the people design it wears, the tint that greys it, and its eyes (alpha 0: none, it passes for living).
var worn := ""
var worn_tint := Color.WHITE
## With prey in sight it runs at this multiple of its pace (a zombie chases faster than it walks).
var chase_mul := 1.0
var eyes := Color(0.5, 0.95, 0.7)
## Stuck check: the goal it is walking to, the nearest it has got, and how long it has got no nearer. `blocked` is set
## when the last walk gave up (a wall or no progress) rather than arrived.
var blocked := false
var _walk_goal := Vector2.INF
var _best_d := 0.0
var _stuck_t := 0.0
## Its route (route_to()): the walk grid's waypoints, the one it walks to, the goal they were planned for, seconds since
## the plan, and give-ups on this plan without a waypoint reached between them.
var _route := PackedVector2Array()
var _route_leg := 0
var _route_goal := Vector2.INF
var _route_age := 0.0
var _route_fails := 0
## Held off a place (hold_off()): the ground, seconds left, seconds since it was turned away, how long it runs on
## along its heading first, and where that run ends.
var _off_rect := Rect2()
var _off_left := 0.0
var _off_t := 0.0
var _off_away := 0.0
var _off_run := Vector2.INF
## When it next looks whether the goal is in plain sight (and for a waypoint further on), the goal it last looked at,
## and whether that one was in sight.
var _look_in := 0.0
var _look_goal := Vector2.INF
var _in_sight := false

## PixelLab sheets (tools/dev/make_animal_sheet.py) by breed; a breed without one keeps its drawn shape.
const SHEETS := {Breed.HOUND: "res://assets/pixellab/animals/hound.png",
	Breed.SHEPHERD: "res://assets/pixellab/animals/shepherd.png",
	Breed.TERRIER: "res://assets/pixellab/animals/terrier.png",
	Breed.TABBY: "res://assets/pixellab/animals/tabby.png",
	Breed.BLACK_CAT: "res://assets/pixellab/animals/black_cat.png",
	Breed.GREY_CAT: "res://assets/pixellab/animals/grey_cat.png",
	Breed.WOLFHOUND: "res://assets/pixellab/animals/wolfhound.png",
	Breed.SPANIEL: "res://assets/pixellab/animals/spaniel.png",
	Breed.WHITE_CAT: "res://assets/pixellab/animals/white_cat.png",
	Breed.BROWN_CAT: "res://assets/pixellab/animals/brown_cat.png",
	Breed.HELLHOUND: "res://assets/pixellab/animals/hellhound.png",
	Breed.DEMON: "res://assets/pixellab/animals/demon.png",
	Breed.GHOST: "res://assets/pixellab/animals/ghost.png",
	Breed.BONE_GIANT: "res://assets/pixellab/animals/bone_giant.png"}
enum Row { STILL, WALK_SE, WALK_NE, SIT, BITE, IDLE, BARK, SNIFF, SCRATCH, LIE }
const WALK_FPS := 8.0
const BITE_FPS := 14.0
## Each wait pose: its row, frames a second, and whether it plays once and holds (sit, lie) or once and then idles
## (bark); the rest loop.
const IDLES := {&"sit": [Row.SIT, 8.0, &"hold"], &"lie": [Row.LIE, 6.0, &"hold"], &"bark": [Row.BARK, 10.0, &"once"],
	&"idle": [Row.IDLE, 6.0, &"loop"], &"sniff": [Row.SNIFF, 6.0, &"loop"], &"scratch": [Row.SCRATCH, 8.0, &"hold"]}
## No nearer to its goal for this long: it gives up on it.
const STUCK_AFTER := 1.2
## How far outside a place it is held off it waits (hold_off()).
const OFF_GAP := 0.5
## route_to(): a goal that has moved this far from where the route was planned to is planned for again; the route looks
## this many waypoints ahead for one it can run to straight (cutting the grid's corners).
const ROUTE_MOVED := 0.5
const ROUTE_AHEAD := 3
## How often route_to() looks again whether the goal is in plain sight and how far along its route it can cut, and how far
## the goal may move before it looks at once: a look is a line of grid samples, too dear for every animal every frame.
const ROUTE_LOOK := 0.2
const LOOK_MOVED := 0.25
static var _sheets := {}


func is_dog() -> bool:
	return breed in DOGS or breed == Breed.HELLHOUND


func is_alive() -> bool:
	return state != State.DEAD


func hypnotized() -> bool:
	return state in [State.ATTACK, State.GATHER, State.TRANCE] and spell_left > 0.0


func speed() -> float:
	var base := DOG_SPEED if is_dog() or breed in OTHER_SIDE or breed in UNDEAD else CAT_SPEED
	if breed == Breed.TERRIER:
		base *= 0.85
	elif breed == Breed.WOLFHOUND:
		base *= 1.15  # long legs
	if chase_mul != 1.0 and is_instance_valid(target):
		base *= chase_mul
	if state in [State.FLEE, State.ATTACK]:
		return base * RUN * speed_mul
	return base * speed_mul


func bite() -> float:
	return DOG_BITE if is_dog() else CAT_BITE


## A zombie puts on the dead person's own look: the PeopleArt `design_name`, turned as `face` (PeopleArt.Facing), its colours
## multiplied by `tint` (a grey greys it; white passes for living) and two pale pixels for `eye_color` (alpha 0: no eyes).
func wear(design_name: String, face: int, tint: Color, eye_color: Color) -> void:
	worn = design_name
	worn_tint = tint
	eyes = eye_color
	facing = -1 if face in [PeopleArt.Facing.SW, PeopleArt.Facing.NW] else 1
	back = face in [PeopleArt.Facing.NE, PeopleArt.Facing.NW]
	queue_redraw()


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


## Space folded under it (The Folded Ward): set down at `to` -- open ground its caller has chosen -- and it runs on to
## wherever it was running (its goal, its prey), its way there planned again from `to`; the stuck check starts over, the
## jump is not being stuck. With `walk_on` false it is only stopped at `to`: its run goes on from there as it was (and
## gives up on a goal it cannot get on toward, as any run does). False when it is dead, and it stays where it is.
func wrap_to(to: Vector2, walk_on := true) -> bool:
	if not is_alive():
		return false
	ground_pos = to
	if not walk_on:
		sync_position()
		return true
	_walk_goal = Vector2.INF
	_stuck_t = 0.0
	blocked = false
	_route = PackedVector2Array()
	_route_goal = Vector2.INF
	_route_leg = 0
	_look_in = 0.0
	sync_position()
	return true


## Turned away from a place (The Folded Ward's NO WAY IN): for `seconds`, whenever it runs for a goal inside `r`
## (route_to()) -- its own, or its prey's -- it runs on along `heading` for `walk_away` seconds first, then only to the
## point just outside `r`'s edge nearest that goal, and waits there (a hound circles the place as its prey moves inside
## it). A goal outside `r` it runs for as ever. When the time is up it runs for its goal again. Draws no number from any
## rng. False when it is dead.
func hold_off(r: Rect2, seconds: float, heading: Vector2, walk_away: float) -> bool:
	if not is_alive() or seconds <= 0.0:
		return false
	_off_rect = r
	_off_left = seconds
	_off_t = 0.0
	_off_away = walk_away
	var dir := heading.normalized() if heading.length() > 0.0001 else Vector2.ZERO
	_off_run = ground_pos + dir * speed() * walk_away
	_walk_goal = Vector2.INF
	_stuck_t = 0.0
	return true


## Let in again: it runs for its own goal as before.
func end_hold_off() -> void:
	_off_left = 0.0
	_off_run = Vector2.INF


## Whether it is held off a place now (hold_off()).
func held_off() -> bool:
	return _off_left > 0.0


## Where it means to run: its prey, else its goal.
func bound_for() -> Vector2:
	if target != null and is_instance_valid(target) and target.is_alive():
		return target.ground_pos
	return goal


## Where a run for `to` (inside the place it is held off) goes instead: on along its heading at first; then the point
## OFF_GAP outside the place's edge nearest `to`.
func _kept_off(to: Vector2) -> Vector2:
	if _off_t < _off_away and _off_run != Vector2.INF:
		return _off_run
	var r := _off_rect.grow(OFF_GAP)
	var c := to.clamp(r.position, r.end)
	var out := [c.x - r.position.x, r.end.x - c.x, c.y - r.position.y, r.end.y - c.y]
	var k := 0
	for i in range(1, 4):
		if out[i] < out[k]:
			k = i
	match k:
		0: c.x = r.position.x
		1: c.x = r.end.x
		2: c.y = r.position.y
		_: c.y = r.end.y
	return c


## One step of `delta` toward `to` at its speed, on walkable ground only: true when it got there.
func walk_to(to: Vector2, delta: float, grid: WalkGrid) -> bool:
	var d := to - ground_pos
	var dist := d.length()
	if dist < 0.05:
		blocked = false
		_walk_goal = Vector2.INF
		return true
	# A new goal (a chased person moves a little each frame; that is the same goal) restarts the stuck check.
	if _walk_goal == Vector2.INF or to.distance_to(_walk_goal) > 0.5:
		_best_d = dist
		_stuck_t = 0.0
	_walk_goal = to
	if dist < _best_d - 0.1:
		_best_d = dist
		_stuck_t = 0.0
	else:
		_stuck_t += delta
		if _stuck_t > STUCK_AFTER:
			# Sliding to and fro along a wall: give up on this goal.
			_give_up()
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
			_give_up()
			return true
	var screen_dx := (next.x - ground_pos.x) - (next.y - ground_pos.y)
	if absf(screen_dx) > 0.0005:
		facing = 1 if screen_dx > 0.0 else -1
	var screen_dy := (next.x - ground_pos.x) + (next.y - ground_pos.y)
	if absf(screen_dy) > 0.0005:
		back = screen_dy < 0.0
	ground_pos = next
	_since_move = 0.0
	_anim += delta * speed() * 7.0
	var f := int(_anim) % 2
	if f != _frame:
		_frame = f
	sync_position()
	queue_redraw()
	return false


func _give_up() -> void:
	blocked = true
	_walk_goal = Vector2.INF
	_stuck_t = 0.0


## One step of `delta` toward `goal` by the way the town's streets go: true on arrival, or (with `blocked` set) when there
## is no way there -- walk_to()'s contract, for a goal round a corner. With the goal in plain sight (the walk grid's
## clear_line()), or no grid, it is walk_to() itself, so open ground walks exactly as before. Otherwise it follows the
## grid's path (WalkGrid.path()), planned again when it has none, when the goal has moved ROUTE_MOVED from where it was
## planned to, every `repath_every` seconds (a chase passes less: the prey moves) and when a step gives up; it walks to
## the farthest of the next ROUTE_AHEAD waypoints it can run to straight, and from the last waypoint straight on to the
## goal. No path at all, or two give-ups with no waypoint reached between them, is "cannot get there". Whether the goal
## is in sight, and how far it can cut, it looks again every ROUTE_LOOK, at once when the goal moves LOOK_MOVED.
func route_to(goal: Vector2, delta: float, grid: WalkGrid, repath_every := 1.0) -> bool:
	if _off_left > 0.0 and _off_rect.has_point(goal):
		# Held off the place its goal lies in (hold_off()): it runs there no nearer than the place's edge, and waits.
		var done := _route_step(_kept_off(goal), delta, grid, repath_every)
		return done and blocked
	return _route_step(goal, delta, grid, repath_every)


func _route_step(goal: Vector2, delta: float, grid: WalkGrid, repath_every: float) -> bool:
	if grid == null:
		return walk_to(goal, delta, grid)
	_look_in -= delta
	var look := _look_in <= 0.0 or goal.distance_to(_look_goal) > LOOK_MOVED
	if look:
		_look_in = ROUTE_LOOK
		_look_goal = goal
		_in_sight = grid.clear_line(ground_pos, goal)
	if _in_sight:
		_route = PackedVector2Array()
		_route_goal = Vector2.INF
		var done := walk_to(goal, delta, grid)
		if done and blocked:
			_look_in = 0.0  # gave up on the straight walk: look again next time
		return done
	_route_age += delta
	if _route.is_empty() or goal.distance_to(_route_goal) > ROUTE_MOVED or _route_age >= repath_every:
		_plan_route(goal, grid)
		look = true
		if _route.is_empty():
			blocked = true
			_route_goal = Vector2.INF
			return true
	if _route_leg >= _route.size():
		# Past the last waypoint (the free cell nearest the goal): straight on, as walk_to() would.
		return walk_to(goal, delta, grid)
	if look:
		for k in range(mini(_route_leg + ROUTE_AHEAD, _route.size() - 1), _route_leg, -1):
			if grid.clear_line(ground_pos, _route[k]):
				_route_leg = k
				break
	if not walk_to(_route[_route_leg], delta, grid):
		return false
	if blocked:
		# The step gave up (a corner it could not slide round): plan again from here, or, a second time running, it
		# cannot get there.
		_route_fails += 1
		if _route_fails >= 2:
			_route = PackedVector2Array()
			_route_goal = Vector2.INF
			_route_fails = 0
			return true
		blocked = false
		_route = PackedVector2Array()
		return false
	# There: on to the next waypoint, looking at once how far along it can cut.
	_route_fails = 0
	_route_leg += 1
	_look_in = 0.0
	return false


func _plan_route(goal: Vector2, grid: WalkGrid) -> void:
	_route = grid.path(ground_pos, goal)
	_route_leg = 0
	_route_goal = goal
	_route_age = 0.0


func tick_visual(delta: float) -> void:
	_since_move += delta
	if breed == Breed.GHOST or breed in UNDEAD:
		_hover_t += delta
		queue_redraw()  # it bobs, sways and flickers every frame
	if _off_left > 0.0:
		_off_left -= delta
		_off_t += delta
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
	if _since_move < 0.2:
		return &"walk"
	if state in [State.TRANCE, State.GATHER]:
		return &"sit"
	if state == State.FOLLOW:
		return &"idle"
	if state in [State.WANDER, State.SIT]:
		return idle
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
		&"walk":
			row = Row.WALK_NE if back else Row.WALK_SE
			col = int(_anim * 1.2)
		&"still", &"dead":
			pass
		_:
			var spec: Array = IDLES.get(_pose, IDLES[&"sit"])
			row = spec[0]
			var n := int(frames[row]) if row < frames.size() else 0
			col = int(_pose_t * float(spec[1]))
			if n > 0 and spec[2] == &"hold":
				col = mini(col, n - 1)
			elif n > 0 and spec[2] == &"once" and col >= n:
				row = Row.IDLE
				col -= n
	if row >= frames.size() or int(frames[row]) == 0:
		return Row.STILL * 100 + (1 if back else 0)
	return row * 100 + col % int(frames[row])


func moving() -> bool:
	return state in [State.WANDER, State.FOLLOW, State.FLEE, State.ATTACK, State.GATHER] and wait <= 0.0


func _draw() -> void:
	var pal: Array = PALETTE[breed]
	var shadow := Rect2(-5, -1, 10, 2) if is_dog() else Rect2(-4, -1, 8, 2)
	if breed == Breed.HELLHOUND:
		shadow = Rect2(-9, -1, 18, 3)
	elif breed == Breed.DEMON:
		shadow = Rect2(-8, -1, 16, 3)
	elif breed == Breed.GHOST:
		shadow = Rect2(-5, -1, 10, 2)
	elif breed == Breed.BONE_GIANT:
		shadow = Rect2(-14, -2, 28, 5)
	elif breed == Breed.ZOMBIE:
		shadow = Rect2(-4, -1, 8, 2)
	elif breed == Breed.SPIRIT or breed == Breed.WRAITH:
		shadow = Rect2(-3, -1, 6, 2)
	var sc := Color(0, 0, 0, 0.28 if not breed in [Breed.GHOST, Breed.SPIRIT, Breed.WRAITH] else 0.14)
	var look_shadow := Person.foot_shadow(shadow, sc)
	draw_rect(look_shadow[0], look_shadow[1])
	if state == State.DEAD and breed in [Breed.ZOMBIE, Breed.SPIRIT, Breed.WRAITH]:
		return  # cut down, it is freed at once: only its shadow shows
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
	var lift := Vector2.ZERO
	if breed == Breed.GHOST:
		tint *= GHOST_TINT
		lift = Vector2(0, -GHOST_HOVER - GHOST_BOB * sin(_hover_t * 3.0))
	var sh := sheet(breed)
	if breed == Breed.ZOMBIE:
		_draw_zombie(tint)
		return
	if breed == Breed.SPIRIT:
		_draw_spirit(_flash > 0.0)
		return
	if breed == Breed.WRAITH:
		_draw_wraith(_flash > 0.0)
		return
	if not sh.is_empty():
		_draw_sheet(sh, tint, lift)
		if breed == Breed.BONE_GIANT:
			_draw_giant_fire()
	else:
		_draw_rows(_shape(), pal, false, tint)
	_draw_mark()


## The PixelLab frame, feet on the ground point, mirrored for the west-facing views.
func _draw_sheet(sh: Dictionary, tint: Color, lift := Vector2.ZERO) -> void:
	var f := _sprite_frame(sh)
	var cell: int = sh.cell
	var foot: Vector2 = sh.foot
	var src := Rect2((f % 100) * cell, (f / 100) * cell, cell, cell)
	draw_set_transform(lift.round(), 0.0, Vector2(float(facing), 1.0))
	draw_texture_rect_region(sh.tex, Rect2(-foot.x, -foot.y, cell, cell), src, tint)
	draw_set_transform(Vector2.ZERO)


## The PeopleArt facing it shows now (SE, SW, NE, NW).
func _people_facing() -> int:
	return (2 if back else 0) + (0 if facing > 0 else 1)


## A zombie: the dead person's own walk frames (idle while it stands), greyed by worn_tint, with two pale eye pixels
## unless the eyes have alpha 0 or it has its back turned. Without the people atlas, a plain grey figure.
func _draw_zombie(tint: Color) -> void:
	var col := worn_tint * tint
	if SpriteArt.on() and PeopleArt.ready() and PeopleArt.has(worn):
		var info := PeopleArt.info(worn)
		var anim := 1 if _since_move < 0.2 else 0  # walk, else idle
		var f := _people_facing()
		var n: int = maxi(1, info[4][anim * 4 + f])
		# Every zombie, grey or white, steps at the rate its own speed asks (PeopleArt's walk FPS).
		var rate := PeopleArt.FPS_AT[1] / maxf(7.0 * speed(), 0.001)
		var frame := int(_anim * rate) % n if anim == 1 else int(_hover_t * 3.0) % n
		var cell: Vector2 = info[3]
		var src := Rect2(info[0] + Vector2(frame * cell.x, (anim * 4 + f) * cell.y), cell)
		var foot: Vector2 = info[2]
		draw_texture_rect_region(PeopleArt.atlas(), Rect2(-foot, cell), src, col)
		if not back and eyes.a > 0.0:
			var ey := -(foot.y - 6.0)
			draw_rect(Rect2(-1, ey, 1, 1), eyes)
			draw_rect(Rect2(1, ey, 1, 1), eyes)
		return
	draw_rect(Rect2(-2, -14, 4, 14), (PALETTE[breed] as Array)[0] * col)
	if not back and eyes.a > 0.0:
		draw_rect(Rect2(-1, -12, 1, 1), eyes)
		draw_rect(Rect2(1, -12, 1, 1), eyes)


## A spirit: a thin pale shape hovering off the ground with a wisp trailing behind it (the way it faces), about half seen
## through, no hood; its face -- two dark hollows and a mouth -- fades in and out, never fully gone and never full.
func _draw_spirit(flash: bool) -> void:
	var t := _hover_t
	var hover := SPIRIT_HOVER + SPIRIT_BOB * sin(t * 2.4)
	var body := SPIRIT_BODY
	if flash:
		body = Color(1, 1, 1, 0.8)
	var top := -hover - 13.0
	# Head and a narrowing body: 3 wide at the head, 2 at the shoulders, a pixel at the waist.
	for i in 13:
		var w := 3 if i < 3 else (2 if i < 7 else 1)
		var sway := roundi(sin(t * 3.0 + float(i) * 0.5) * (0.4 + float(i) * 0.06))
		draw_rect(Rect2(-(w / 2) + sway, top + float(i), w, 1), body)
	# The wisp: it trails behind, drifting, thinning and fading.
	var back_dir := -float(facing)
	for k in 9:
		var kf := float(k)
		var a := body.a * (1.0 - kf / 9.0) * 0.8
		var wx := back_dir * (1.0 + kf * 0.9) + sin(t * 4.0 + kf * 0.7) * 1.2
		var wy := -hover - 4.0 + kf * 0.6 + sin(t * 3.0 + kf) * 0.4
		draw_rect(Rect2(roundf(wx), roundf(wy), 1, 1), Color(body.r, body.g, body.b, a))
	# The face fades in and out.
	var fade := 0.5 + 0.5 * sin(t * 1.7)
	fade = fade * fade
	var hollow := Color(0.16, 0.18, 0.2, 0.15 + 0.7 * fade)
	draw_rect(Rect2(-1, top + 1, 1, 1), hollow)
	draw_rect(Rect2(1, top + 1, 1, 1), hollow)
	draw_rect(Rect2(0, top + 2, 1, 1), Color(hollow.r, hollow.g, hollow.b, hollow.a * 0.6))


## The bone giant's eye sockets: a pale-white fire, two pixels flickering and a soft glow round them (with its back to
## us the skull shows none).
func _draw_giant_fire() -> void:
	if back:
		return
	var flick := 0.6 + 0.4 * sin(_hover_t * 11.0) * sin(_hover_t * 7.3 + 1.0)
	var c := Vector2(GIANT_SOCKET.x * float(facing), GIANT_SOCKET.y)
	draw_circle(c, 4.0, Color(GIANT_FIRE.r, GIANT_FIRE.g, GIANT_FIRE.b, 0.12 * flick))
	draw_circle(c, 2.5, Color(GIANT_FIRE.r, GIANT_FIRE.g, GIANT_FIRE.b, 0.16 * flick))
	var px := Color(GIANT_FIRE.r, GIANT_FIRE.g, GIANT_FIRE.b, 0.5 + 0.5 * flick)
	draw_rect(Rect2(c.x - 2.0, c.y, 1, 1), px)
	draw_rect(Rect2(c.x + 1.0, c.y, 1, 1), px)


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
