class_name SpriteView
extends Node2D
## One building sprite (SpriteArt) on a Structure: a still, or a frame of its idle strip, drawn with the footprint's
## front corner at this node's origin through structure_sprite.gdshader, which lights, chars and frosts it like the
## procedural art and clips it along the footprint's ground line for a collapse or a laser cut. A deep footprint shows a
## wide sprite mirrored (scale.x = -1); the clip works in the sprite's own pixels, so it mirrors with it.

const SHADER := preload("res://src/environment/art/structure_sprite.gdshader")
## Clip modes (the shader's cut_mode): everything, what is above the cut line, or what is below it.
const KEEP_ALL := 0
const KEEP_ABOVE := 1
const KEEP_BELOW := -1

var sprite := {}
var still := &"intact"
var frame := 0
## The draw's modulate: the blight's tint, a fade.
var color := Color.WHITE
var _mat: ShaderMaterial
## The clip last handed to the shader (set_cut()); NAN until the first.
var _cut := [NAN, NAN, NAN]
## Playing the intact still's idle strip on its own clock (play_idle()): the view steps its frames itself, so the
## Structure under it can sleep (Structure._can_idle()) while its banner waves or its chimney smokes.
var playing := false
var _clock := 0.0


## `left` and `right`: the footprint's left and right corners relative to its front corner, in the structure's space
## (Structure._s[3] and _s[1]).
func setup(sprite_set: Dictionary, left: Vector2, right: Vector2) -> SpriteView:
	sprite = sprite_set
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	var m := -1.0 if sprite.mirror else 1.0
	scale = Vector2(m, 1.0)
	# In the sprite's own pixels a mirrored right corner is the left one.
	var a := Vector2(left.x * m, left.y)
	var b := Vector2(right.x * m, right.y)
	_mat.set_shader_parameter("corner_left", a if a.x < b.x else b)
	_mat.set_shader_parameter("corner_right", b if a.x < b.x else a)
	_mat.set_shader_parameter("anchor", sprite.anchor)
	return self


## Show `st` (&"intact", &"damaged", &"ruins", or &"collapse", the set's generated collapse), and stop playing the idle
## strip (play_idle()). The intact still shows its idle strip's `frame_index` when the set has one; the collapse holds
## its last frame. Redraws only on a change.
func show_still(st: StringName, frame_index := 0) -> void:
	_stop()
	_show(st, frame_index)


## Play the intact still's idle strip from `t` seconds on (Structure._time, so it starts on the frame the structure
## would have shown), stepping it in _process() on the view's own clock. Already playing, it keeps its clock: the
## structure's time stands still while it sleeps. A set without an idle strip just shows its intact still.
func play_idle(t: float) -> void:
	if frame_count(&"intact") <= 1:
		show_still(&"intact")
		return
	if playing and still == &"intact":
		return
	playing = true
	_clock = t
	_show(&"intact", int(_clock * float(sprite.fps)))
	set_process(true)


func _ready() -> void:
	# A script with _process() starts processing on entering the tree; only a playing view needs to.
	set_process(playing)


## Steps the idle strip: a redraw only when the frame changes (sprite.fps), and none while the structure's whole
## screen box is off screen (Structure.view); the frame it lands on then is drawn when it comes back.
func _process(delta: float) -> void:
	var fps := float(sprite.fps)
	var n := int(sprite.frames)
	# Wrapped to one loop of the strip, so the clock never grows without bound.
	_clock = fmod(_clock + delta, float(n) / fps)
	var f := int(_clock * fps) % n
	if f == frame:
		return
	var host := get_parent() as Structure
	if host != null and Structure.view.has_area() and not Structure.view.intersects(host.view_box()):
		return
	frame = f
	queue_redraw()


func _stop() -> void:
	if playing:
		playing = false
		set_process(false)


func _show(st: StringName, frame_index: int) -> void:
	var n := frame_count(st)
	var f := 0
	if n > 1:
		f = clampi(frame_index, 0, n - 1) if st == &"collapse" else frame_index % n
	if st == still and f == frame:
		return
	still = st
	frame = f
	queue_redraw()


## Frames the still `st` steps through (1 for a plain still).
func frame_count(st: StringName) -> int:
	if st == &"collapse":
		return maxi(int(sprite.collapse_frames), 1)
	if st == &"intact" and sprite.idle != null:
		return int(sprite.frames)
	return 1


func set_color(c: Color) -> void:
	if c != color:
		color = c
		queue_redraw()


## Clip along the ground line raised by `lift` px (see the shader); `molten` lights a stump's cut edge.
func set_cut(mode: int, lift: float, molten := 0.0) -> void:
	# An animated sprite syncs every frame (Structure._sync_sprite()), and a parameter set reaches the renderer even
	# when its value is the same, so only a change is passed on.
	if _cut[0] == float(mode) and _cut[1] == lift and _cut[2] == molten:
		return
	_cut = [float(mode), lift, molten]
	_mat.set_shader_parameter("cut_mode", mode)
	_mat.set_shader_parameter("cut_lift", lift)
	_mat.set_shader_parameter("molten", molten)


func set_light(light: Color, ambient: float, scorch: float, frost: float, tint: Color) -> void:
	_mat.set_shader_parameter("light_col", Vector3(light.r, light.g, light.b))
	_mat.set_shader_parameter("ambient", ambient)
	_mat.set_shader_parameter("scorch", scorch)
	_mat.set_shader_parameter("frost", frost)
	_mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))


func _draw() -> void:
	var size: Vector2 = sprite.size
	var at: Vector2 = sprite.anchor
	var tex: Texture2D
	if still == &"collapse":
		tex = sprite.collapse
	elif still == &"intact" and sprite.idle != null:
		tex = sprite.idle
	else:
		tex = sprite.stills[still]
	var origin := Vector2(frame * size.x, 0.0)
	var src := Rect2(origin, size)
	# A strip piece draws only its stretch of the strip (SpriteArt.strip_piece); strips have no idle or collapse, so
	# its frame is always 0.
	var region: Rect2 = sprite.get("region", Rect2())
	if region.has_area():
		src = region
	_mat.set_shader_parameter("frame_origin", origin)
	draw_texture_rect_region(tex, Rect2(src.position - origin - at, src.size), src, color)
