class_name ChamberSignature
extends RefCounted
## God's Chamber step 8: each station's signature as a press leads into its zoom, as data (GodChamber draws it on the wall's layer, over
## the desk). The Ability Tree's runes flare and a purple bloom rises; the Faith Altar's brazier flares and gold embers rise; the Rite
## Door's crack floods out white-gold; the World Table's map lights and its glow rises. Masks are ChamberLife's (assets/chamber/life/),
## blooms one soft radial texture made here, embers 1-unit pixels.
##
## `flare` (0..1) is GodChamber.signature(): one swell up going in, only down coming back, so every mask and bloom follows it one way.
## Embers each rise and fade once. Comfort limits (the life design's): no light changes faster than 3 times a second, a flare is one
## swell, never a strobe. The embers' scatter is hashed from their index (ChamberLife.hash01): their own random, never the game's.

## Embers off the brazier: how many, the gap between their births, how long each lives (EMBER_LIFE + up to EMBER_SPREAD), how far it rises.
const EMBERS := 22
const EMBER_GAP := 0.022
const EMBER_LIFE := 0.42
const EMBER_SPREAD := 0.25
const EMBER_RISE := Vector2(34.0, 76.0)
const EMBER_FROM := Vector2(600.0, 206.0)
const EMBER := Color(1.0, 0.8, 0.36)
## The share of an ember's life spent brightening before it fades.
const EMBER_RISE_SHARE := 0.15
## The Rite Door's crack (room units): where its light floods out from.
const CRACK := Vector2(178.0, 168.0)
## The flood's warm gold, capped (GodChamber.COVER_CAP): never near-white.
const FLOOD := Color(0.8, 0.72, 0.52)
## The Ability Tree's bloom: a lighter purple than its runes, so it reads over them.
const RUNE_BLOOM := Color(0.78, 0.52, 1.0)

static var _bloom: GradientTexture2D


## The pieces for `key` at `flare`; `t` is the seconds since the press (the embers' clock), or < 0 for none (the way back). Each piece is
## ChamberLife's shape ({"tex", "layer", "rect", "alpha"} or {"tex": "", "color"}) plus "id" (stable across frames) and "kind" ("mask",
## "bloom" or "ember"); a "bloom" is drawn with bloom_texture() in its colour.
static func pieces(key: String, flare: float, t := -1.0) -> Array:
	var f := clampf(flare, 0.0, 1.0)
	var out: Array = []
	match key:
		"tree":
			out.append(_mask("tree_glow", f))
			out.append(_bloom_at("bloom", Vector2(28.0, 215.0 - 70.0 * f), Vector2(130.0 + 110.0 * f, 190.0 + 130.0 * f), RUNE_BLOOM, 0.75 * f))
		"faith":
			out.append(_mask("brazier_glow", f))
			var r: Rect2 = ChamberLife.FILES.brazier_flame.rect
			var h := r.size.y * (1.0 + 0.6 * f)
			out.append(_mask("brazier_flame", 0.8 * f, Rect2(r.position.x, r.end.y - h, r.size.x, h)))
			out.append(_bloom_at("bloom", Vector2(600.0, 208.0), Vector2(60.0, 60.0) + Vector2(40.0, 40.0) * f, GodChamber.FADE_COLORS.faith, 0.45 * f))
			if t >= 0.0:
				_embers(out, t)
		"awaken":
			out.append(_mask("door_glow", f))
			out.append(_bloom_at("crack", CRACK, Vector2(20.0 + 40.0 * f, 180.0 + 100.0 * f), FLOOD, f))
			out.append(_bloom_at("bloom", CRACK, Vector2(60.0, 160.0) + Vector2(900.0, 600.0) * f * f, FLOOD, 0.85 * f))
		"descend":
			out.append(_mask("map_lit", 0.9 * f))
			out.append(_mask("map_pins_0", 0.8 * f))
			out.append(_mask("map_pins_1", 0.8 * f))
			out.append(_bloom_at("bloom", Vector2(316.0, 246.0), Vector2(240.0 + 120.0 * f, 50.0 + 60.0 * f), GodChamber.FADE_COLORS.descend, 0.5 * f))
	return out


static func _mask(name: String, alpha: float, rect := Rect2()) -> Dictionary:
	var row: Dictionary = ChamberLife.FILES[name]
	return {"id": name, "kind": "mask", "tex": name, "layer": row.layer, "rect": rect if rect.has_area() else row.rect, "alpha": alpha}


static func _bloom_at(id: String, centre: Vector2, size: Vector2, color: Color, alpha: float) -> Dictionary:
	return {"id": id, "kind": "bloom", "tex": "", "layer": "wall", "rect": Rect2(centre - size * 0.5, size), "color": color, "alpha": alpha}


## Gold embers rising off the brazier, one born every EMBER_GAP s from the press: each brightens quickly, then fades as it rises.
static func _embers(out: Array, t: float) -> void:
	for i in EMBERS:
		var age := t - EMBER_GAP * i
		var life := EMBER_LIFE + EMBER_SPREAD * ChamberLife.hash01(1100, i)
		if age < 0.0 or age > life:
			continue
		var p := age / life
		var x := EMBER_FROM.x + (ChamberLife.hash01(1200, i) - 0.5) * 22.0 + (ChamberLife.hash01(1500, i) - 0.5) * 24.0 * p + sin(p * 4.0 + i) * 3.0
		var y := EMBER_FROM.y - p * lerpf(EMBER_RISE.x, EMBER_RISE.y, ChamberLife.hash01(1300, i))
		var a := minf(p / EMBER_RISE_SHARE, 1.0) * (1.0 - p) * 0.95
		var big := 2.0 if ChamberLife.hash01(1400, i) > 0.55 else 1.0
		out.append({"id": "ember%d" % i, "kind": "ember", "tex": "", "layer": "wall", "rect": Rect2(roundf(x), roundf(y), big, big), "color": EMBER,
			"alpha": a})


## A soft round light: white at the centre to clear at the edge, tinted by the piece's colour when drawn. Made once.
static func bloom_texture() -> GradientTexture2D:
	if _bloom == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
		_bloom = GradientTexture2D.new()
		_bloom.gradient = g
		_bloom.width = 64
		_bloom.height = 64
		_bloom.fill = GradientTexture2D.FILL_RADIAL
		_bloom.fill_from = Vector2(0.5, 0.5)
		_bloom.fill_to = Vector2(1.0, 0.5)
	return _bloom
