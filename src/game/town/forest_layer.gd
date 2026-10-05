class_name ForestLayer
extends Node2D
## The forest round the town, swaying in the wind. These are the trees the floor used to bake into its texture:
## nothing ever stands in front of or behind them on screen (that is what made them bakeable, see TownDecor), so they
## are drawn together under the world with the wind shader, and never redrawn: the shader moves them.
## They are drawn in bands of the ground's x + y (which is screen height), back to front, one batch each: a band off
## screen is culled whole, so the GPU only shades the forest in view.

## The baked decor pieces this layer draws (Decor.Kind.OAK and PINE), sorted back to front.
var trees: Array[Dictionary] = []
## Each band spans this much of x + y (ground units, BAND * 16 px of screen height).
const BAND := 6.0
## Leaf clusters on a forest oak's crown (the town's own oaks have PropArt.OAK_CLUSTERS or TOWN_OAK_CLUSTERS).
const FOREST_CLUSTERS := 14


func _ready() -> void:
	# It sits on the ground plane, which is under the iso basis; draw in screen pixels as the floor's texture does.
	transform = Iso.BASIS.affine_inverse()
	var bands := {}
	for d in trees:
		var at: Vector2 = d.at
		var k := floori((at.x + at.y) / BAND)
		if not bands.has(k):
			bands[k] = []
		bands[k].append(d)
	var keys := bands.keys()
	keys.sort()
	for k in keys:
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
			# The tuning's colour; a tree's size is not tuned (a single batch takes no per-tree transform).
			ArtKit.color_mul = ArtTuning.tint(String(Decor.Kind.keys()[d.kind]).to_lower())
			DecorArt.tree(d.kind, d.at, d.size, d.seed, Vector2.ZERO, FOREST_CLUSTERS)
		ArtKit.color_mul = Color.WHITE
		ArtKit.flush(self)
