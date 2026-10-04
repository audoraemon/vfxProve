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
## The shared idle clock's shader global (project.godot [shader_globals]): seconds of game time, wrapped every
## IDLE_WRAP seconds (a whole number of loops for every strip in the manifest: 4-6 frames at 3-8 fps).
const IDLE_TIME := &"idle_time"
const IDLE_WRAP := 1440.0
## ArtKit.hash01 salt for a view's idle phase, from its structure's seed.
const SALT_PHASE := 95

## The idle clock: game seconds (time scale and pause applied: IdleClock steps it from its _process delta).
static var idle_time := 0.0

var sprite := {}
var still := &"intact"
var frame := 0
## The draw's modulate: the blight's tint, a fade.
var color := Color.WHITE
var _mat: ShaderMaterial
## The clip last handed to the shader (set_cut()); NAN until the first.
var _cut := [NAN, NAN, NAN]
## Playing the intact still's idle strip (play_idle()): the shader steps its frames from the shared idle clock
## (IDLE_TIME) and this view's phase, so neither the view nor the Structure under it processes (Structure._can_idle()).
var playing := false
## Where in its loop this view's strip runs, in frames [0, frames): from its structure's seed, so neighbours (a forest's
## trees) do not sway in step.
var phase := 0.0


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


## Advance the shared idle clock by `delta` game seconds and hand it to the shaders (IdleClock calls this once a frame).
static func advance(delta: float) -> void:
	idle_time = fmod(idle_time + delta, IDLE_WRAP)
	RenderingServer.global_shader_parameter_set(IDLE_TIME, idle_time)


## Play the intact still's idle strip: the shader picks the frame from the shared idle clock (advance()) plus this
## view's phase, its structure's seed hashed (SALT_PHASE), so the view needs no processing at all. `_t` (the structure's
## time) is kept for callers; the clock is shared. A set without an idle strip just shows its intact still.
func play_idle(_t := 0.0) -> void:
	if frame_count(&"intact") <= 1:
		show_still(&"intact")
		return
	if playing and still == &"intact":
		return
	var host := get_parent() as Structure
	phase = ArtKit.hash01(host.rng.seed, SALT_PHASE) * float(sprite.frames) if host != null else 0.0
	_show(&"intact", 0)
	playing = true
	_set_idle(int(sprite.frames))


## The frame the shader shows now: the playing strip's from the idle clock and phase, else the still's.
func shown_frame() -> int:
	if not playing:
		return frame
	return posmod(int(floor(idle_time * float(sprite.fps) + phase)), int(sprite.frames))


func _set_idle(frames: int) -> void:
	_mat.set_shader_parameter("idle_frames", frames)
	if frames > 1:
		_mat.set_shader_parameter("idle_fps", float(sprite.fps))
		_mat.set_shader_parameter("idle_phase", phase)
		_mat.set_shader_parameter("frame_w", float((sprite.size as Vector2).x))


func _stop() -> void:
	if playing:
		playing = false
		_set_idle(1)


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
