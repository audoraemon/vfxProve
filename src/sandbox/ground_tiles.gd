extends Node2D
## Battlefield floor. Lives under the iso-basis GroundPlane, so it draws in ground units.
## Theme "scifi": metal deck panels. Theme "fantasy": worn stone flags with moss and dirt.

## Ground extends past the play area so zoomed or panned views never show void.
const HALF := 7
const FILL := 13

const COL_BASE := [Color("1a1e29"), Color("1d2230"), Color("171b25")]
const COL_PANEL := Color("232937")
const COL_SEAM := Color("0e1017")
const COL_EDGE := Color("2e3648")
const COL_LIGHT := Color("2fd0ff")
const COL_WARN := Color("5a3a1a")

# Daylight courtyard: warm grey flagstones, green moss and grass, packed dirt.
const STONE := [Color("8a8274"), Color("958c7d"), Color("7f786c"), Color("8f887c"), Color("777064")]
const STONE_HI := Color("aaa190")
const MORTAR := Color("4e4840")
const MOSS := [Color("5c7a36"), Color("6d8c40")]
const DIRT := [Color("7e6a50"), Color("6e5c44")]
const GRASS := [Color("587a30"), Color("6a8e3a"), Color("4a6a2a")]

var theme := "scifi":
	set(value):
		theme = value
		queue_redraw()


func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 997


func _draw() -> void:
	if theme == "fantasy":
		_draw_fantasy()
	else:
		_draw_scifi()


func _draw_scifi() -> void:
	for y in range(-FILL, FILL):
		for x in range(-FILL, FILL):
			var h := _hash(x, y)
			draw_rect(Rect2(x, y, 1, 1), COL_BASE[h % 3])
			if h % 4 == 0:
				draw_rect(Rect2(x + 0.18, y + 0.18, 0.64, 0.64), COL_PANEL)
			if h % 29 == 0:
				draw_rect(Rect2(x + 0.1, y + 0.45, 0.8, 0.1), COL_WARN)
	for i in range(-FILL, FILL + 1):
		draw_line(Vector2(i, -FILL), Vector2(i, FILL), COL_SEAM, -1.0)
		draw_line(Vector2(-FILL, i), Vector2(FILL, i), COL_SEAM, -1.0)
	for y in range(-HALF, HALF):
		for x in range(-HALF, HALF):
			if _hash(x, y) % 17 == 0:
				draw_rect(Rect2(x + 0.02, y + 0.02, 0.05, 0.05), COL_LIGHT)
	draw_rect(Rect2(-HALF, -HALF, HALF * 2, HALF * 2), COL_EDGE, false, -1.0)


## Flagstones: each cell split into 2 or 3 irregular slabs, mortar gaps, worn highlights,
## moss creeping along seams and trampled dirt patches.
func _draw_fantasy() -> void:
	draw_rect(Rect2(-FILL, -FILL, FILL * 2, FILL * 2), MORTAR)
	var gap := 0.045
	for y in range(-FILL, FILL):
		for x in range(-FILL, FILL):
			var h := _hash(x, y)
			var slabs: Array[Rect2] = []
			match h % 3:
				0:
					slabs = [Rect2(x, y, 1, 1)]
				1:
					var s := 0.35 + float(h % 30) / 100.0
					slabs = [Rect2(x, y, s, 1), Rect2(x + s, y, 1 - s, 1)]
				_:
					var s := 0.35 + float(h % 30) / 100.0
					slabs = [Rect2(x, y, 1, s), Rect2(x, y + s, 0.5, 1 - s), Rect2(x + 0.5, y + s, 0.5, 1 - s)]
			for i in slabs.size():
				var r: Rect2 = slabs[i].grow(-gap)
				var c: Color = STONE[(h + i * 7) % STONE.size()]
				draw_rect(r, c)
				# Worn top edge catches light.
				draw_rect(Rect2(r.position, Vector2(r.size.x, 0.05)), STONE_HI)
				if (h + i) % 5 == 0:
					draw_rect(Rect2(r.position + r.size * 0.3, Vector2(0.12, 0.08)), c.darkened(0.15))
	# Moss and dirt patches, drawn as clusters of small squares so edges stay pixel-ragged.
	for y in range(-FILL, FILL):
		for x in range(-FILL, FILL):
			var h := _hash(x * 3 + 11, y * 5 - 7)
			if h % 9 == 0 or h % 13 == 0:
				var pal: Array = MOSS if h % 9 == 0 else DIRT
				for k in 14:
					var hk := _hash(x * 31 + k, y * 17 - k)
					var p := Vector2(x + float(hk % 97) / 97.0, y + float((hk / 97) % 89) / 89.0)
					draw_rect(Rect2(p, Vector2(0.14, 0.1)), pal[hk % 2])
	# Grass verges outside the courtyard and tufts in the seams.
	for y in range(-FILL, FILL):
		for x in range(-FILL, FILL):
			var outside := absi(x) >= HALF + 1 or absi(y) >= HALF + 1
			var h := _hash(x * 7 - 3, y * 11 + 5)
			if outside and h % 3 != 0:
				draw_rect(Rect2(x, y, 1, 1), GRASS[h % 3])
			var tufts := 10 if outside else (3 if h % 5 == 0 else 0)
			for k in tufts:
				var hk := _hash(x * 13 + k, y * 29 - k)
				var p := Vector2(x + float(hk % 89) / 89.0, y + float((hk / 89) % 83) / 83.0)
				draw_rect(Rect2(p, Vector2(0.06, 0.12)), GRASS[(hk + 1) % 3].lightened(0.12))
