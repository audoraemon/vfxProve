class_name Dusk
extends Node2D
## The dusk ledger (Veil authority powers spec §4): the patches of dark every Veil cast leaves where it lands. A patch is a circle
## that lasts a while (VeilRules.DUSK_TIME) or until it is ended (a blighted building's lasting foothold). Off by default: with the
## ledger off nothing is laid, and an empty ledger changes nothing -- Crowd.in_dark() and Crowd.sight_scale_at() read it, and both
## answer as before with no patch. Dusk is quiet: no danger, no alarm, nobody frightened; it only shortens sight (to
## NightRules.NIGHT_SIGHT) and sizes Veil's powers. Drawn as soft violet-black discs on the ground, under the people.

## A patch was laid at `at` with radius `r`.
signal laid(at: Vector2, r: float)

## Colour of the ground's darkening (Unseen Hour's dusk) and its strength at a patch's middle.
const COLOR := Color("3b1470")
const ALPHA := 0.45
## A patch fades in and out over this many seconds (the drawing only).
const FADE := 1.0
## Rings in each soft-edged disc, from the edge in.
const RINGS := 4

var enabled := false
## Evernight: everywhere is dark (Crowd.in_dark()). Not a patch: covers() does not read it.
var everywhere := false

## The live patches: {"id", "at", "r", "left" (INF = until end()), "age"}.
var _patches: Array[Dictionary] = []
var _next_id := 1


func _init() -> void:
	name = "Dusk"
	transform = Iso.BASIS  # draws in ground units: a circle is the ground's iso ellipse
	z_index = -3  # on the ground, under the people (as the crowd's ground drawer)


## Lays a patch of `r` at `at` for `seconds` (< 0: until end(id)). Returns its id, 0 when the ledger is off.
func lay(at: Vector2, r: float, seconds: float) -> int:
	if not enabled:
		return 0
	var id := _next_id
	_next_id += 1
	_patches.append({"id": id, "at": at, "r": r, "left": seconds if seconds >= 0.0 else INF, "age": 0.0})
	laid.emit(at, r)
	_dirty()
	return id


func end(id: int) -> void:
	for i in _patches.size():
		if int(_patches[i].id) == id:
			_patches.remove_at(i)
			_dirty()
			return


## How many patches are live.
func count() -> int:
	return _patches.size()


## True when a live patch covers `at` (the everywhere flag is not a patch).
func covers(at: Vector2) -> bool:
	for p in _patches:
		if (p.at as Vector2).distance_to(at) <= float(p.r):
			return true
	return false


## True when the ground within `r` of `at` touches dusk: the everywhere flag is up, or a live patch's circle reaches into the circle.
func reaches(at: Vector2, r: float) -> bool:
	if everywhere:
		return true
	for p in _patches:
		if (p.at as Vector2).distance_to(at) <= r + float(p.r):
			return true
	return false


## The radius of the largest live patch covering `at`, else 0.0.
func r_at(at: Vector2) -> float:
	var best := 0.0
	for p in _patches:
		if (p.at as Vector2).distance_to(at) <= float(p.r):
			best = maxf(best, float(p.r))
	return best


## Ages the patches; one whose time is up is gone.
func step(delta: float) -> void:
	if _patches.is_empty():
		return
	var fading := false
	var i := _patches.size() - 1
	while i >= 0:
		var p := _patches[i]
		p.age = float(p.age) + delta
		p.left = float(p.left) - delta
		if float(p.left) <= 0.0:
			_patches.remove_at(i)
			fading = true
		elif float(p.age) < FADE or float(p.left) < FADE:
			fading = true
		i -= 1
	if fading:
		_dirty()


func clear() -> void:
	_patches.clear()
	everywhere = false
	_dirty()


func _dirty() -> void:
	if is_inside_tree():
		queue_redraw()


func _draw() -> void:
	for p in _patches:
		var shown := clampf(minf(float(p.age) / FADE, float(p.left) / FADE), 0.0, 1.0)
		if shown <= 0.0:
			continue
		var r := float(p.r)
		# Soft edge: RINGS discs, each a little smaller, so the dark deepens toward the middle, where the stack reaches ALPHA.
		var each := 1.0 - pow(1.0 - ALPHA, 1.0 / float(RINGS))
		for k in RINGS:
			draw_circle(p.at, r * (1.0 - 0.12 * float(k)), Color(COLOR, each * shown))
