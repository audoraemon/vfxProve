class_name Decor
extends Node2D
## One small thing in town (a barrel, a garden, a tree...) standing in the y-sorted world. It has no per-frame
## work: it draws once through DecorArt and again only when a blast chars it or knocks it down. Its layer is dimmed
## with the ambient light (see Town), so it needs no lighting of its own. EnvironmentField hands it hits.

enum Kind {
	BARREL, CRATES, BENCH, FENCE, GARDEN, BUSH, ROCK, OAK, PINE, LAMP, BUNTING, SCARECROW, SIGNPOST, REEDS, FLOWERS,
	TABLE, SHIP, BOAT, DOCK, SHEEP, COW, CART, LOGS, PILE,
}
## Decor that belongs on the water, not the land.
const ON_WATER := [Kind.SHIP, Kind.BOAT, Kind.DOCK]

## A hit this strong (or any falling stone) knocks decor down; weaker hits char it by amount / CHAR_PER.
const KNOCK_AT := 30.0
const CHAR_PER := 60.0

var kind := Kind.BARREL
## Ground point it stands on (its sort corner), and its extent (a run's direction and length, a plot's size).
var at := Vector2.ZERO
var size := Vector2.ZERO
var seed_value := 0
## 0..1 how burnt it is.
var char_amount := 0.0
var down := false
## A PILE's pieces, back to front: {"kind", "at", "size", "seed"} each (TownDecor merges goods standing together
## into one node, one draw call instead of one each).
var parts: Array = []
## A stand-in for a piece drawn elsewhere while sprites are off: a baked piece (TownFloor) or a pile's part whose set
## is animated (DecorSprites.animated). It shows only while that set is drawn, and is no gameplay decor (the town
## never hands it to EnvironmentField: a blast reaches it only through the pile it belongs to, see `followers`).
var sprite_only := false
## A pile's animated parts, drawn by sprite_only nodes of their own: they char and fall with the pile.
var followers: Array[Decor] = []
## Multiplies the colour tuning: a baked piece's stand-in takes the floor's light (Town: GROUND_EVENING over the decor
## layer's EVENING, times the piece's own bake tint), so it matches the bake around it.
var tint_mul := Color.WHITE:
	set(v):
		tint_mul = v
		self_modulate = _tint()
var _glow: QuadFx

## Decor that moves in the wind (trees sway, bunting flutters, reeds and bushes stir; see ArtKit.wind_gain), and
## decor that rides the water (rises and falls a whole pixel; its sprite only, see wind.gdshader).
const SWAYS := [Kind.OAK, Kind.PINE, Kind.BUNTING, Kind.REEDS, Kind.BUSH, Kind.FLOWERS]
const BOBS := [Kind.SHIP, Kind.BOAT]
## Motion classes on the one wind shader: a sprite's top sways `sprite_sway` px; `bob` > 0 lifts the whole sprite
## instead (px, overrides the sway). Trees sway as the forest does; plants stand lower and sway less.
const MOTION := {
	"tree": {"sprite_sway": 1.5, "bob": 0.0},
	"plant": {"sprite_sway": 1.0, "bob": 0.0},
	"bob": {"sprite_sway": 0.0, "bob": 1.0},
}
const PLANTS := [Kind.REEDS, Kind.BUSH, Kind.FLOWERS]
## One shared material per motion class (MOTION's keys), made on first use; and per (class, frames, fps, frame width)
## for an animated set ("<class>|<frames>|<fps>|<frame_u>"; class "still" for kinds that do not move otherwise).
static var _motion: Dictionary = {}


## The wind shader every swaying tree, the bunting and the forest layer share (the "tree" class).
static func wind_material() -> ShaderMaterial:
	return _material("tree")


## The shared material for a decor kind's motion class, or null for decor that stands still. With `s`, the decor set
## the piece draws (DecorSprites.decor_set): an animated one (frames > 1) gets the class's motion plus frame stepping
## (wind.gdshader: anim_frames, anim_fps, frame_u, on the idle clock), one material per class, frames, fps and frame
## width; a still set changes nothing.
static func material_for(k: int, s: Dictionary = {}) -> ShaderMaterial:
	var c := _class(k)
	var frames := int(s.get("frames", 1))
	if frames <= 1 or s.get("tex") == null:
		return null if c == "" else _material(c)
	var fps := float(s.get("fps", 0.0))
	var frame_u: float = (s.size as Vector2).x / float((s.tex as Texture2D).get_width())
	var key := "%s|%d|%s|%s" % [c if c != "" else "still", frames, fps, frame_u]
	if not _motion.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/wind.gdshader")
		var still := {"sprite_sway": 0.0, "bob": 0.0}
		var motion: Dictionary = MOTION.get(c, still)
		for p: String in motion:
			m.set_shader_parameter(p, motion[p])
		m.set_shader_parameter("anim_frames", frames)
		m.set_shader_parameter("anim_fps", fps)
		m.set_shader_parameter("frame_u", frame_u)
		_motion[key] = m
	return _motion[key]


## A kind's motion class (MOTION's keys), or "" for one that stands still.
static func _class(k: int) -> String:
	if k in BOBS:
		return "bob"
	if k in PLANTS:
		return "plant"
	if k in SWAYS:
		return "tree"
	return ""


## Every motion class's material; set their `wind` to 0 to still all decor and the forest.
static func motion_materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for c: String in MOTION:
		out.append(_material(c))
	for key: String in _motion:
		if not MOTION.has(key):
			out.append(_motion[key])
	return out


static func _material(c: String) -> ShaderMaterial:
	if not _motion.has(c):
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/wind.gdshader")
		for p: String in MOTION[c]:
			m.set_shader_parameter(p, MOTION[c][p])
		_motion[c] = m
	return _motion[c]


func setup(k: Kind, at_point: Vector2, extent: Vector2, s: int) -> Decor:
	kind = k
	at = at_point
	size = extent
	seed_value = s
	position = Iso.ground_to_screen(at)
	if kind == Kind.BUNTING:
		# Strung high over the street: above the people walking under it.
		z_index = 1
	return self


## This decor's key in ArtTuning ("barrel", "oak").
func tuning_key() -> String:
	return String(Kind.keys()[kind]).to_lower()


func _ready() -> void:
	add_to_group(&"decor_art")
	self_modulate = _tint()
	_art_state()
	if kind == Kind.LAMP:
		_glow = QuadFx.new().setup(FxParts.SH_LIGHT, Vector2(46, 23))
		_glow.set_param("color", Structure.TORCH_LIGHT)
		_glow.set_param("falloff", 1.6)
		_glow.set_param("intensity", 0.4)
		_glow.set_param("flicker", 0.6)
		_glow.run_on_shader_clock()
		_glow.z_as_relative = false
		_glow.z_index = -4
		add_child(_glow)
		_place_glow()


## The lamp's light pool: under its sprite's lantern ("glow" in its decor set) while it draws from one, else at its
## ground point; scaled with the drawing (ArtTuning).
func _place_glow() -> void:
	if is_instance_valid(_glow):
		_glow.position = DecorSprites.glow_offset(kind, seed_value, size) * ArtTuning.scale(tuning_key())


## F7 switched the art (ArtToggle): draw again from the sprite or the polygons.
func art_changed() -> void:
	_art_state()
	self_modulate = _tint()
	_place_glow()
	queue_redraw()


## The material and, for a sprite_only stand-in, whether it shows (while sprites are on): both follow the art now.
## Trees and piles take their class material (a tree set is packed in an atlas: never a strip).
func _art_state() -> void:
	var n := DecorSprites.name_for(kind, seed_value, size, at) if not kind in [Kind.PILE, Kind.OAK, Kind.PINE] else ""
	material = material_for(kind, DecorSprites.decor_set(n) if n != "" else {})
	if sprite_only:
		visible = SpriteArt.on()


## Its colour now: its tuning, times tint_mul, charred by char_amount.
func _tint() -> Color:
	return (ArtTuning.tint(tuning_key()) * tint_mul).lerp(Structure.COL_CHAR, char_amount * 0.7)


## Whether a piece ({kind, at, size, seed}) is drawn by a live node of its own now, not by the floor bake or a pile:
## sprites are on and its set is animated (DecorSprites.animated).
static func drawn_live(d: Dictionary) -> bool:
	return DecorSprites.animated(d.kind, d.seed, d.size, d.at)


## A pile's parts it draws itself: all but those drawn live (drawn_live), each by a sprite_only node of its own.
func pile_parts_drawn() -> Array:
	return parts.filter(func(p: Dictionary) -> bool: return not drawn_live(p))


## A blast reached it: char it, or knock it down when the hit is strong enough.
func hit(amount: float, damage_kind: StringName) -> void:
	if down:
		return
	if amount >= KNOCK_AT or damage_kind == &"stone":
		down = true
		if is_instance_valid(_glow):
			_glow.queue_free()
	else:
		char_amount = minf(char_amount + amount / CHAR_PER, 1.0)
	self_modulate = _tint()
	queue_redraw()
	for f in followers:
		if is_instance_valid(f):
			f.down = down
			f.char_amount = char_amount
			f.self_modulate = f._tint()
			f.queue_redraw()


func _draw() -> void:
	var sc := ArtTuning.scale(tuning_key())
	if sc != 1.0:
		# Scaled about the ground point it stands on (this node's origin).
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(sc, sc))
	ArtKit.begin()
	if kind == Kind.PILE:
		# Each piece in its own colour tuning (a pile only holds pieces drawn at their own size).
		for p: Dictionary in pile_parts_drawn():
			ArtKit.color_mul = ArtTuning.tint(String(Kind.keys()[p.kind]).to_lower())
			DecorArt.paint(p.kind, p.at, p.size, p.seed, position, down)
		ArtKit.color_mul = Color.WHITE
	else:
		DecorArt.paint(kind, at, size, seed_value, position, down)
	ArtKit.flush(self)
