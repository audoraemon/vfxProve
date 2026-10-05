class_name PlantLayer
extends Node2D
## The town's low plants, stirring in the wind: the floor's meadow shrubs and flowerbeds (TownFloor.shrub_spots) and
## the baked reeds, bushes and flowers (TownFloor.baked_decor). Like the forest (ForestLayer), nothing ever stands in
## front of them on screen (that is what made them bakeable), so they are drawn under the world with the plant wind
## material, in bands of the ground's x + y, back to front, one batch each (a draw call per plant atlas, see
## Band.queue()), and never redrawn but on F7.
## A piece is drawn here only while TownFloor.plant_in_layer() holds (sprites on, and it has a set); otherwise the
## floor bakes it as before. F7 redraws the bands as the floor re-bakes, so the plants move between the two.

## The pieces: shrub spots {base, at, seed} and baked plants {kind, at, size, seed, ...}, sorted back to front.
var plants: Array[Dictionary] = []
## Each band spans this much of x + y (ground units), as the forest's.
const BAND := ForestLayer.BAND


func _ready() -> void:
	# On the ground plane, under the iso basis: draw in screen pixels as the floor's texture does.
	transform = Iso.BASIS.affine_inverse()
	var bands := {}
	for d in plants:
		var at: Vector2 = d.at
		var k := floori((at.x + at.y) / BAND)
		if not bands.has(k):
			bands[k] = []
		bands[k].append(d)
	var keys := bands.keys()
	keys.sort()
	for k in keys:
		var band := Band.new()
		band.plants = bands[k]
		band.material = Decor.material_for(Decor.Kind.REEDS)
		add_child(band)


class Band extends Node2D:
	var plants: Array = []

	func _ready() -> void:
		add_to_group(&"decor_art")

	## F7 switched the art (ArtToggle): draw the band again; with sprites off it draws nothing (the floor bakes all).
	func art_changed() -> void:
		queue_redraw()

	func _draw() -> void:
		ArtKit.begin()
		queue()
		ArtKit.flush(self)

	## Queue the band's pieces into ArtKit, atlas by atlas (DecorSprites.PLANT_ATLASES order: the low plants, then the
	## bushes, then the reeds), each back to front: one textured segment, one draw call, per atlas. Interleaved down
	## the x + y order the atlases would switch a few hundred times over the town; drawn this way a taller plant
	## stands over a lower one it overlaps whichever is in front (a handful of pairs in the whole town).
	func queue() -> void:
		var by_atlas := {}
		for d: Dictionary in plants:
			if not TownFloor.plant_in_layer(d):
				continue
			var s := DecorSprites.plant_set(d)
			var a := DecorSprites.plant_atlas(s.name)
			if not by_atlas.has(a):
				by_atlas[a] = []
			by_atlas[a].append([d, s])
		var order: Array = DecorSprites.PLANT_ATLASES.keys()
		order.append("")
		for a: String in order:
			for e: Array in by_atlas.get(a, []):
				var d: Dictionary = e[0]
				if d.has("kind"):
					# The tuning the floor bake gives a baked piece: its size about its ground point, and its colour
					# (a piece from inside the walls keeps its live colour, see TownDecor._bake_low()).
					var key := String(Decor.Kind.keys()[d.kind]).to_lower()
					var sc := ArtTuning.scale(key)
					var at := Iso.ground_to_screen(d.at)
					ArtKit.tex_xform = Transform2D(0.0, Vector2(sc, sc), 0.0, at * (1.0 - sc))
					ArtKit.color_mul = ArtTuning.tint(key) * (d.get("tint", Color.WHITE) as Color)
				else:
					ArtKit.tex_xform = Transform2D.IDENTITY
					ArtKit.color_mul = Color.WHITE
				DecorSprites.paint_plant(d, e[1])
		ArtKit.tex_xform = Transform2D.IDENTITY
		ArtKit.color_mul = Color.WHITE
