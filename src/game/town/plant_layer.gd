class_name PlantLayer
extends Node2D
## The town's low plants, stirring in the wind: the floor's meadow shrubs and flowerbeds (TownFloor.shrub_spots) and
## the baked reeds, bushes and flowers (TownFloor.baked_decor). Like the forest (ForestLayer), nothing ever stands in
## front of them on screen (that is what made them bakeable), so they are drawn under the world with the plant wind
## material, in bands of the ground's x + y, back to front, one batch each (a few draw calls: painter_order()), and
## never redrawn but on F7.
## A piece is drawn here only while TownFloor.plant_in_layer() holds (sprites on, and it has a set); otherwise the
## floor bakes it as before. F7 redraws the bands as the floor re-bakes, so the plants move between the two.

## The pieces: shrub spots {base, at, seed} and baked plants {kind, at, size, seed, ...}, sorted back to front.
var plants: Array[Dictionary] = []
## Each band spans this much of x + y (ground units): four forest bands. The layer lies wholly under the world, so
## bands buy only culling, no sorting; coarse ones let painter_order() batch across more pieces (fewer draw calls).
const BAND := ForestLayer.BAND * 4.0


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
		band.plants = painter_order(bands[k])
		band.material = Decor.material_for(Decor.Kind.REEDS)
		add_child(band)


## `pieces` (back to front by x + y) in an order that draws each overlapping pair back to front, yet switches plant
## atlas (DecorSprites.PLANT_ATLASES) as seldom as it can: each switch is another textured segment, another draw call.
## Greedy: keep taking the backmost piece on the current atlas whose overlapping pieces behind it are all drawn; when
## none is free, move to the atlas of the backmost piece left (always free). Atlases and boxes are the sprites' while
## sprites are on, whatever F7 says, so the order is worked out once.
static func painter_order(pieces: Array) -> Array:
	var n := pieces.size()
	var atlas: Array[String] = []
	var boxes: Array[Rect2] = []
	for d: Dictionary in pieces:
		var s := DecorSprites.plant_set(d, true)
		atlas.append(DecorSprites.plant_atlas(s.name) if not s.is_empty() else "")
		boxes.append(TownFloor._plant_box(d))
	# Per piece, the earlier pieces (behind it, or level with it and before it in `pieces`) that overlap it.
	var behind: Array = []
	for i in n:
		var b: Array[int] = []
		for j in i:
			if boxes[i].intersects(boxes[j]):
				b.append(j)
		behind.append(b)
	var done: Array[bool] = []
	done.resize(n)
	done.fill(false)
	var out := []
	var cur := atlas[0] if n > 0 else ""
	var first := 0
	while out.size() < n:
		while done[first]:
			first += 1
		var pick := -1
		for i in range(first, n):
			if done[i] or atlas[i] != cur:
				continue
			var free := true
			for j: int in behind[i]:
				if not done[j]:
					free = false
					break
			if free:
				pick = i
				break
		if pick < 0:
			cur = atlas[first]
			continue
		done[pick] = true
		out.append(pieces[pick])
	return out


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

	## Queue the band's pieces into ArtKit in their stored order (painter_order()), those the layer draws
	## (TownFloor.plant_in_layer): runs of one atlas are one textured segment each.
	func queue() -> void:
		for d: Dictionary in plants:
			if not TownFloor.plant_in_layer(d):
				continue
			if d.has("kind"):
				# The tuning the floor bake gives a baked piece: its size about its ground point, and its colour (a
				# piece from inside the walls keeps its live colour, see TownDecor._bake_low()).
				var key := String(Decor.Kind.keys()[d.kind]).to_lower()
				var sc := ArtTuning.scale(key)
				var at := Iso.ground_to_screen(d.at)
				ArtKit.tex_xform = Transform2D(0.0, Vector2(sc, sc), 0.0, at * (1.0 - sc))
				ArtKit.color_mul = ArtTuning.tint(key) * (d.get("tint", Color.WHITE) as Color)
			else:
				ArtKit.tex_xform = Transform2D.IDENTITY
				ArtKit.color_mul = Color.WHITE
			DecorSprites.paint_plant(d, DecorSprites.plant_set(d))
		ArtKit.tex_xform = Transform2D.IDENTITY
		ArtKit.color_mul = Color.WHITE
