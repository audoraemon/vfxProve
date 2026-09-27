class_name ForestLayer
extends Node2D
## The forest round the town, swaying in the wind. These are the trees the floor used to bake into its texture:
## nothing ever stands in front of or behind them on screen (that is what made them bakeable, see TownDecor), so they
## are drawn all together under the world, as one batch in back-to-front order, with the wind shader. One draw call,
## and no redraws: the shader moves them.

## The baked decor pieces this layer draws (Decor.Kind.OAK and PINE), sorted back to front.
var trees: Array[Dictionary] = []


func _ready() -> void:
	# It sits on the ground plane, which is under the iso basis; draw in screen pixels as the floor's texture does.
	transform = Iso.BASIS.affine_inverse()
	material = Decor.wind_material()


func _draw() -> void:
	ArtKit.begin()
	for d in trees:
		# The tuning's colour; a tree's size is not tuned (a single batch takes no per-tree transform).
		ArtKit.color_mul = ArtTuning.tint(String(Decor.Kind.keys()[d.kind]).to_lower())
		DecorArt.paint(d.kind, d.at, d.size, d.seed, Vector2.ZERO)
	ArtKit.color_mul = Color.WHITE
	ArtKit.flush(self)
