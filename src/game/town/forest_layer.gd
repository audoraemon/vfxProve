class_name ForestLayer
extends Node2D
## The forest round the town, swaying in the wind. These are the trees the floor used to bake into its texture:
## nothing ever stands in front of or behind them on screen (that is what made them bakeable, see TownDecor), so they
## are drawn together under the world with the wind shader, and never redrawn: the shader moves them.
## They are drawn in bands of the ground's x + y (which is screen height), back to front, one batch each: a band off
## screen is culled whole, so the GPU only shades the forest in view.

## The baked decor pieces this layer draws (Decor.Kind.OAK and PINE), sorted back to front.
var trees: Array[Dictionary] = []
## Whether to add the border band's trees (TownDecor.border_trees(), polish 3): in bands of their own,
## TownFloor.BAND_DELAY after the town's, as the floor paints the band, so the town's first frames do not draw them.
## They stand past the floor's fill, so no town tree stands in front of or behind one.
var border := false
## Each band spans this much of x + y (ground units, BAND * 16 px of screen height).
const BAND := 6.0
## Leaf clusters on a forest oak's crown (the town's own oaks have PropArt.OAK_CLUSTERS or TOWN_OAK_CLUSTERS).
const FOREST_CLUSTERS := 14


func _ready() -> void:
	# It sits on the ground plane, which is under the iso basis; draw in screen pixels as the floor's texture does.
	transform = Iso.BASIS.affine_inverse()
	_add_bands(trees)
	if border:
		_add_border()



func _add_border() -> void:
	await get_tree().create_timer(TownFloor.BAND_DELAY).timeout
	if not is_inside_tree():
		return
	var band := TownDecor.border_trees()
	band.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return (a.at as Vector2).x + (a.at as Vector2).y < (b.at as Vector2).x + (b.at as Vector2).y)
	await _add_bands(band, true)


## `list` (back to front) as bands of BAND, one batch each; `spread`: one band a frame.
func _add_bands(list: Array, spread := false) -> void:
	var bands := {}
	for d in list:
		var at: Vector2 = d.at
		var k := floori((at.x + at.y) / BAND)
		if not bands.has(k):
			bands[k] = []
		bands[k].append(d)
	var keys := bands.keys()
	keys.sort()
	for k in keys:
		if spread:
			await get_tree().process_frame
			if not is_inside_tree():
				return
		var band := Band.new()
		band.trees = bands[k]
		band.material = Decor.wind_material()
		add_child(band)


class Band extends Node2D:
	var trees: Array = []

	func _ready() -> void:
		add_to_group(&"decor_art")

	## F7 switched the art (ArtToggle): draw the band again, from the tree sets or the polygons.
	func art_changed() -> void:
		queue_redraw()

	func _draw() -> void:
		ArtKit.begin()
		for d in trees:
			# A tree painted over a live animated piece is drawn by a live stand-in instead (TownFloor.mark_live).
			if TownFloor.live_now(d):
				continue
			# The tuning's colour, times a border band tree's fade ("tint": TownDecor.border_trees()); a tree's size is not
			# tuned (a single batch takes no per-tree transform).
			ArtKit.color_mul = ArtTuning.tint(String(Decor.Kind.keys()[d.kind]).to_lower())
			if d.has("tint"):
				ArtKit.color_mul *= d.tint as Color
			DecorArt.tree(d.kind, d.at, d.size, d.seed, Vector2.ZERO, FOREST_CLUSTERS)
		ArtKit.color_mul = Color.WHITE
		ArtKit.flush(self)
