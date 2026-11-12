class_name GodSelectScreen
extends Node
## The god select (god P1, spec §4 and §12; restyled as "God's Paths", round 2): six grey stone statues, one on each of the ruined temple
## background's own platforms (RING[0] at the back, the rest clockwise), lit when picked and dimmed otherwise, each with its name carved on
## the platform's front, in a courtyard with braziers and drifting leaves; a statue's dark box stands in when its art is missing. A panel
## at the top centre shows the selected type's name, its three verbs, one line of flavour, its two Tier 1 spots ("Not yet chosen" while
## the tree is empty) and its two neighbours. Choose, or Enter, picks it -- once, for the slot being made (spec §4) -- and Esc or Back
## goes back. The screen only reports; Game makes the god.

## "chosen" (`chosen_type` is the type) or "back".
signal action(name: String)

## Where each type's statue stands (its plinth's bottom centre, on the background's platform) and where its name is carved on the
## platform's front, both in `GodTree.RING` order: Ruin at the back, then clockwise.
const FEET := [Vector2(324, 151), Vector2(476, 170), Vector2(521, 253), Vector2(317, 300), Vector2(118, 253), Vector2(161, 170)]
const NAME_AT := [Vector2(324, 158), Vector2(476, 177), Vector2(521, 273), Vector2(317, 321), Vector2(118, 274), Vector2(161, 177)]
## The centre pool, where the selected god's emblem turns (centre of its 72 px frames), behind the statues.
const EMBLEM_AT := Vector2(320, 200)
## How long the old emblem takes to fade out when the pick changes.
const EMBLEM_FADE := 0.2
## Frame rates: the statue effects (burst then loop), the emblem's turn, the entrance flash, the sparks' twinkle.
const FX_FPS := 12.0
const EMBLEM_FPS := 8.0
const FLASH_FPS := 12.0
const SPARK_FPS := 10.0
## The burst set's frame count, and so how long it plays, once, after a pick.
const BURST_FRAMES := 8
const BURST_TIME := BURST_FRAMES / FX_FPS
## Where the statue's feet are inside an effect frame (112x128).
const FX_ANCHOR := Vector2(56.0, 119.0)
## The emblem's scale-in: one value per ENTRANCE_STEP seconds, starting ENTRANCE_DELAY after the pick (the flash covers the start).
const ENTRANCE_DELAY := 0.08
const ENTRANCE_STEP := 0.042
const ENTRANCE_SCALES := [0.35, 0.6, 0.85, 1.08, 1.12, 1.05]
const SPARK_COUNT := 6
## The sparks' orbit round the emblem: half-width, half-height, how far up from its centre; a turn takes ORBIT_TIME seconds.
const ORBIT_RX := 44.0
const ORBIT_RY := 14.0
const ORBIT_UP := 4.0
const ORBIT_TIME := 4.0
## The top panel the selected type's lines are drawn in, and the two buttons.
const INFO_RECT := Rect2(186.0, 2.0, 268.0, 66.0)
const CHOOSE_RECT := Rect2(520.0, 334.0, 112.0, 18.0)
const BACK_RECT := Rect2(8.0, 334.0, 90.0, 18.0)
## A statue's sprite size; its plinth's bottom centre is at (32, 79).
const STATUE_SIZE := Vector2(64.0, 80.0)
## How wide a statue's clickable body column is (64, the sprite's width, would overlap Death's and Dominion's).
const BODY_W := 40.0
## What each type does, in three words, in the top panel.
const VERBS := {
	"ruin": "Destroy · Collapse · Erase",
	"passage": "Open · Move · Close",
	"veil": "Conceal · Obscure · Displace",
	"decree": "Law · Bind · Enforce",
	"death": "Wither · Harvest · Release",
	"dominion": "Control · Command · Bend",
}

## Each god's colour: its statue's aura, its emblem's glow and pool ring, and its verbs in the top panel.
const GOD_COL := {
	"ruin": Color("e8602a"), "passage": Color("4a90e8"), "veil": Color("3ab8a8"),
	"decree": Color("f0d890"), "death": Color("98d880"), "dominion": Color("a060e0"),
}
## Where the four braziers stand (bottom centre of each).
const BRAZIERS := [Vector2(22, 248), Vector2(618, 248), Vector2(222, 318), Vector2(418, 318)]
const LEAF_COUNT := 8

## The type chosen by confirm(), or "".
var chosen_type := ""
## The ring position (0-5) in the top panel; clicks and Left/Right move it.
var selected := 0
var _ui: Control
var _hover := ""
var _clock := 0.0
var _draws := 0  # how many times the screen has drawn to the end (tests read it)
var _unloaded: Array[String] = []  # frame steps still to do (LOAD_STEPS per god), nearest god first
var _prev_scale := 0.0
var _prev_bob := 0.0
var _prev_frame := 0
## One drifting leaf each: x start, y start, fall speed, sway phase, spin speed.
var _leaves: Array[PackedFloat32Array] = []
## Seconds since the current pick (restarts on a new pick, not on a repeat).
var fx_age := 0.0
var _prev_type := ""
var _prev_age := 0.0
## One orbiting spark each: start phase (a turn is 0-1), its ellipse's half-width and half-height.
var _sparks: Array[PackedFloat32Array] = []


func setup() -> GodSelectScreen:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_ui.draw.connect(_draw_ui)
	_ui.gui_input.connect(_on_gui_input)
	layer.add_child(_ui)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for k in LEAF_COUNT:
		_leaves.append(PackedFloat32Array([rng.randf_range(0.0, 640.0), rng.randf_range(0.0, 380.0), rng.randf_range(10.0, 22.0),
			rng.randf_range(0.0, TAU), rng.randf_range(-1.5, 1.5)]))
	GodSelectArt.frame_set("brazier")
	_load_god(GodTree.RING[selected])
	_queue_rest()
	_build_ring_points()
	for k in SPARK_COUNT:
		_sparks.append(PackedFloat32Array([float(k) / SPARK_COUNT + rng.randf_range(-0.04, 0.04),
			ORBIT_RX + rng.randf_range(-3.0, 3.0), ORBIT_RY + rng.randf_range(-1.5, 1.5)]))
	return self


func _process(delta: float) -> void:
	advance(delta)
	_redraw()


## Steps the clock that drives the animated bits (braziers, leaves, emblem, sparks and the power effect).
func advance(delta: float) -> void:
	_clock += delta
	fx_age += delta
	if not _unloaded.is_empty():
		_do_step(_unloaded.pop_front())
	if _prev_type != "":
		_prev_age += delta
		if _prev_age >= EMBLEM_FADE:
			_prev_type = ""


## The frame sets one god's emblem and effect use.
static func god_sets(type: String) -> PackedStringArray:
	return PackedStringArray(["emblem_" + type, "emblem_flash_" + type, "emblem_spark_" + type, "fx_%s_burst" % type, "fx_%s_loop" % type])


## The queue's steps for one god, one per advance(): the 24-frame emblem in thirds, the small sets, the 16-frame loop in halves. A
## "@n@last" step reads that frame number and the seven after it; the last step of a set also assembles it (`frame_set`).
const LOAD_STEPS := ["emblem_%s@1@0", "emblem_%s@9@0", "emblem_%s@17@1", "emblem_flash_%s", "emblem_spark_%s", "fx_%s_burst",
	"fx_%s_loop@1@0", "fx_%s_loop@9@1"]


## Does one queue step.
static func _do_step(step: String) -> void:
	if not step.contains("@"):
		GodSelectArt.frame_set(step)
		return
	var parts := step.split("@")
	for n in range(int(parts[1]), int(parts[1]) + 8):
		GodSelectArt.texture("%s_%d" % [parts[0], n])
	if parts[2] == "1":
		GodSelectArt.frame_set(parts[0])


## Loads all of one god's sets now (a pick never loads inside a draw call) and takes them off the queue.
func _load_god(type: String) -> void:
	for set_name in god_sets(type):
		GodSelectArt.frame_set(set_name)
	for step in LOAD_STEPS:
		_unloaded.erase(step % type)


## The sets of the other five gods, nearest the selected one on the ring first; advance() loads one set per call.
func _queue_rest() -> void:
	_unloaded.clear()
	var n := GodTree.RING.size()
	var order: Array[int] = []
	for d in range(1, n / 2 + 1):
		for i in [(selected + d) % n, (selected - d + n) % n]:
			if i != selected and not order.has(i):
				order.append(i)
	for i in order:
		for step in LOAD_STEPS:
			_unloaded.append(step % GodTree.RING[i])


## The two pool rings' pixels (rounded points, and each point's place in the dash pattern 0-1), made once.
static var _ring_pts: Array[PackedVector2Array] = []
static var _ring_phase: Array[PackedFloat32Array] = []
## Per ring: half-width, half-height, dashes round it, share of each dash lit, dash turn per second, lighten amount.
const RINGS := [[46.0, 10.0, 36.0, 0.75, 0.6, 0.3], [39.0, 8.0, 30.0, 0.5, -0.4, 0.0]]


static func _build_ring_points() -> void:
	if not _ring_pts.is_empty():
		return
	var centre := Vector2(EMBLEM_AT.x, EMBLEM_AT.y + 33.0)
	for r in RINGS:
		var pts := PackedVector2Array()
		var ph := PackedFloat32Array()
		var steps := int(r[0] * PI)
		for n in steps:
			var a := TAU * n / steps
			pts.append((centre + Vector2(cos(a) * r[0], sin(a) * r[1])).round())
			ph.append(a / TAU * r[2])
		_ring_pts.append(pts)
		_ring_phase.append(ph)


## The type whose emblem shows: the selected one.
func emblem_type() -> String:
	return GodTree.RING[selected]


## "burst" for the first BURST_TIME after a pick, then "loop".
func fx_phase() -> String:
	return "burst" if fx_age < BURST_TIME else "loop"


## Which of the emblem's turn frames shows now (0 when it has none). The turn counts from the pick, so it always enters face-on.
func emblem_frame() -> int:
	var n := GodSelectArt.frame_set("emblem_" + emblem_type()).size()
	return int(fx_age * EMBLEM_FPS) % n if n > 0 else 0


## The emblem's scale: 0 for the first moments after a pick (the flash covers them), then a quick scale-in up to 1.0.
func entrance_scale() -> float:
	var t := fx_age - ENTRANCE_DELAY
	if t < 0.0:
		return 0.0
	var k := int(t / ENTRANCE_STEP)
	return ENTRANCE_SCALES[k] if k < ENTRANCE_SCALES.size() else 1.0


## The scale the outgoing emblem fades out at: what it had when the pick changed (0 when none is fading).
func outgoing_scale() -> float:
	return _prev_scale if _prev_type != "" else 0.0


func _bob() -> float:
	return roundf(2.0 * sin(TAU * _clock / 2.6))


func spark_count() -> int:
	return _sparks.size()


## Where spark `k` is on its orbit, in radians (0 is the right, PI/2 the front).
func spark_angle(k: int) -> float:
	return TAU * (_clock / ORBIT_TIME + _sparks[k][0])


## True when spark `k` is on the near half of its orbit (drawn in front of the emblem), false on the far half (behind it).
func spark_in_front(k: int) -> bool:
	return sin(spark_angle(k)) >= 0.0


## Spark `k`'s centre on the screen, given the emblem's bob.
func spark_pos(k: int, bob: float) -> Vector2:
	var a := spark_angle(k)
	return EMBLEM_AT + Vector2(_sparks[k][1] * cos(a), bob + _sparks[k][2] * sin(a) - ORBIT_UP)


## A statue's brightness: 1.0 selected, 0.86 under the mouse, 0.72 otherwise.
func lit(i: int) -> float:
	if i == selected:
		return 1.0
	return 0.86 if _hover == "ring:%d" % i else 0.72


## Where type `i`'s statue's feet stand (0-5): its plinth's bottom centre.
static func feet(i: int) -> Vector2:
	return FEET[i]


## Where type `i`'s sprite is drawn: its top left is `feet(i)` - (32, 79), so the plinth's bottom centre lands on `feet(i)`.
static func statue_rect(i: int) -> Rect2:
	return Rect2(feet(i) - Vector2(32.0, 79.0), STATUE_SIZE)


## Type `i`'s hit box (0-5): the statue's body column, BODY_W wide, down to the carved name.
static func ring_rect(i: int) -> Rect2:
	var top := feet(i).y - 79.0
	return Rect2(feet(i).x - BODY_W * 0.5, top, BODY_W, NAME_AT[i].y + 6.0 - top)


## A type's three verbs for the top panel, or "" for a type that is not on the ring.
static func verbs(type: String) -> String:
	return String(VERBS.get(type, ""))


## What the top panel says of a type: its title, its flavour line, its Tier 1 spots' power names (or "Not yet chosen"), and its
## neighbours. Empty for a type that is not on the ring.
func type_lines(type: String) -> PackedStringArray:
	if not GodTree.RING.has(type):
		return PackedStringArray()
	var names := PackedStringArray()
	for i in GodTree.PER_TIER:
		var key := GodTree.spot(type, 1, i)
		names.append(String(PowerBook.get_power(key).name) if key != "" else GodTree.NOT_CHOSEN)
	var beside := PackedStringArray()
	for n in GodTree.neighbours(type):
		beside.append(PowerBook.authority_title(n))
	# Decree's two Tier 1 names are too long for one row with the label (2026-11-12): the bare names then.
	var tier := "Tier 1: %s" % ", ".join(names)
	if UiTheme.width(tier, UiTheme.SIZE_SMALL) > INFO_RECT.size.x - 16.0:
		tier = ", ".join(names)
	return PackedStringArray([PowerBook.authority_title(type), String(GodTree.FLAVOUR.get(type, "")),
		tier, "Neighbours: %s" % ", ".join(beside)])


## Puts the top panel on ring position `i` (0-5); it does not choose.
func select(i: int) -> void:
	var was := selected
	selected = clampi(i, 0, GodTree.RING.size() - 1)
	if selected != was:
		_load_god(GodTree.RING[selected])
		_prev_type = GodTree.RING[was]
		_prev_scale = entrance_scale()
		_prev_bob = _bob()
		_prev_frame = emblem_frame()
		_prev_age = 0.0
		fx_age = 0.0
	_redraw()


## Chooses the selected type: `chosen_type` is set and "chosen" is emitted.
func confirm() -> void:
	chosen_type = GodTree.RING[selected]
	UiSound.play(&"ui_manifest")
	action.emit("chosen")


## What is under a point: "ring:<i>", "choose:0", "back:0" or "".
func hit(point: Vector2) -> String:
	for i in GodTree.RING.size():
		if ring_rect(i).has_point(point):
			return "ring:%d" % i
	if CHOOSE_RECT.has_point(point):
		return "choose:0"
	if BACK_RECT.has_point(point):
		return "back:0"
	return ""


## A left click at a screen point.
func click(point: Vector2) -> void:
	var h := hit(point)
	if h == "":
		return
	var parts := h.split(":")
	match parts[0]:
		"ring":
			UiSound.play(&"ui_click")
			select(int(parts[1]))
		"choose":
			confirm()
		"back":
			UiSound.play(&"ui_click")
			action.emit("back")


func _redraw() -> void:
	if _ui != null:
		_ui.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_ESCAPE:
			UiSound.play(&"ui_click")
			action.emit("back")
		KEY_LEFT:
			UiSound.play(&"ui_hover")
			select((selected + GodTree.RING.size() - 1) % GodTree.RING.size())
		KEY_RIGHT:
			UiSound.play(&"ui_hover")
			select((selected + 1) % GodTree.RING.size())
		KEY_ENTER, KEY_KP_ENTER:
			confirm()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := hit(event.position)
		if h != _hover:
			_hover = h
			if h != "":
				UiSound.play(&"ui_hover")
			_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click(event.position)


func _draw_ui() -> void:
	var bg := GodSelectArt.texture("background")
	if bg != null:
		_ui.draw_texture_rect(bg, Rect2(0, 0, 640, 360), false)
	else:
		_ui.draw_rect(Rect2(0, 0, 640, 360), Color(0.03, 0.03, 0.05, 1.0))
	_draw_braziers()
	_draw_emblem()
	var order := [0, 1, 2, 3, 4, 5]
	order.sort_custom(func(a: int, b: int) -> bool: return FEET[a].y < FEET[b].y)
	for i in order:
		_draw_statue(i)
		if i == selected:
			_draw_fx(i)
		_draw_name(i)
	_draw_leaves()
	var back_col := Color(0, 0, 0, 0.55)
	_ui.draw_rect(Rect2(0, 0, 182, 59), back_col)
	UiTheme.text(_ui, Vector2(10, 20), "GOD'S PATHS", UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	UiTheme.text(_ui, Vector2(10, 32), "CHOOSE YOUR AUTHORITY", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(10, 45), "A god's type is chosen once,", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(10, 56), "for this slot.", UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_ui.draw_rect(Rect2(452, 0, 188, 32), back_col)
	var keys := ["Left / Right look round the ring", "Enter chooses · Esc goes back"]
	var kx := minf(466.0, 634.0 - maxf(UiTheme.width(keys[0], UiTheme.SIZE_SMALL), UiTheme.width(keys[1], UiTheme.SIZE_SMALL)))
	UiTheme.text(_ui, Vector2(kx, 14), keys[0], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	UiTheme.text(_ui, Vector2(kx, 26), keys[1], UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
	_draw_info()
	var choose_on := _hover == "choose:0"
	_ui.draw_rect(CHOOSE_RECT, Color(0.1, 0.09, 0.07, 0.9) if choose_on else Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, CHOOSE_RECT, choose_on)
	var go := "Enter Path ›"
	UiTheme.text(_ui, Vector2(roundf(CHOOSE_RECT.get_center().x - UiTheme.width(go) * 0.5), CHOOSE_RECT.position.y + 14.0), go,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD)
	_ui.draw_rect(BACK_RECT, Color(0.04, 0.04, 0.06, 0.85))
	UiTheme.frame(_ui, BACK_RECT, _hover == "back:0")
	var back := "‹ Back"
	UiTheme.text(_ui, Vector2(roundf(BACK_RECT.get_center().x - UiTheme.width(back) * 0.5), BACK_RECT.position.y + 14.0), back,
		UiTheme.SIZE_BODY, UiTheme.COL_GOLD if _hover == "back:0" else UiTheme.COL_TEXT)
	_draws += 1


## Type `i`'s name carved on its platform's front: light stone letters with a 1 px dark outline, gold when selected or hovered.
func _draw_name(i: int) -> void:
	var title := PowerBook.authority_title(GodTree.RING[i])
	var size := UiTheme.SIZE_SMALL
	if UiTheme.width(title, size) > 60.0:
		size -= 1
	var on := i == selected
	var at := Vector2(roundf(NAME_AT[i].x - UiTheme.width(title, size) * 0.5), NAME_AT[i].y + 4.0)
	var col := UiTheme.COL_GOLD if on or _hover == "ring:%d" % i else Color("b2b8c8")
	var dark := Color(0.03, 0.03, 0.06, 0.95)
	for d in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		_ui.draw_string(UiTheme.font(), at + d, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, dark)
	_ui.draw_string(UiTheme.font(), at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## The height of the top panel's text for `flavour_rows` rows of flavour and `tail_rows` small rows (name, verbs, flavour, then the tail).
static func info_height(flavour_rows: int, tail_rows: int) -> float:
	return 16.0 + 11.0 + 16.0 + (flavour_rows - 1) * UiTheme.LINE_BODY + tail_rows * 10.0 + 3.0


## Type `i`'s statue, its plinth on `feet(i)`, over a small contact shadow, dimmed unless picked, with a soft aura in the god's colour;
## today's box if no art.
func _draw_statue(i: int) -> void:
	var tex := GodSelectArt.texture("statue_" + String(GodTree.RING[i]))
	if tex == null:
		_ui.draw_rect(ring_rect(i), Color(0.04, 0.04, 0.06, 0.4))
		return
	var v := lit(i)
	var top_left := statue_rect(i).position
	_ui.draw_set_transform(feet(i) + Vector2(0.0, -1.0), 0.0, Vector2(1.0, 0.22))
	_ui.draw_circle(Vector2.ZERO, 26.0, Color(0, 0, 0, 0.35))
	var col: Color = GOD_COL.get(GodTree.RING[i], Color.WHITE)
	_ui.draw_set_transform(top_left + Vector2(32.0, 36.0), 0.0, Vector2(1.0, 1.3))
	for r in [30.0, 22.0, 15.0]:
		_ui.draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, 0.07 * v * v))
	_ui.draw_set_transform(Vector2.ZERO)
	_ui.draw_texture(tex, top_left, Color(v, v, v, 1.0))


## The selected god's power effect, grown from its statue's feet: the burst frames once, then the loop frames. Skipped when its art is
## missing.
func _draw_fx(i: int) -> void:
	var type: String = GodTree.RING[i]
	var tex: Texture2D = null
	if fx_age < BURST_TIME:
		var burst := GodSelectArt.frame_set("fx_%s_burst" % type)
		if not burst.is_empty():
			tex = burst[mini(int(fx_age * FX_FPS), burst.size() - 1)]
	else:
		var loop := GodSelectArt.frame_set("fx_%s_loop" % type)
		if not loop.is_empty():
			tex = loop[int((fx_age - BURST_TIME) * FX_FPS) % loop.size()]
	if tex != null:
		_ui.draw_texture(tex, (feet(i) - FX_ANCHOR).floor())


## The pool: glow, the ring of light, the emblem (turning, bobbing, with its reflection), the sparks behind and in front, and the flash on
## a new pick. Drawn before the statues. Nothing at all when the emblem's art is missing.
func _draw_emblem() -> void:
	var type := emblem_type()
	var col: Color = GOD_COL.get(type, Color.WHITE)
	var turn := GodSelectArt.frame_set("emblem_" + type)
	if turn.is_empty():
		return
	if _prev_type != "":
		var old := GodSelectArt.frame_set("emblem_" + _prev_type)
		if not old.is_empty():
			if _prev_scale > 0.0:
				var otex: Texture2D = old[_prev_frame % old.size()]
				var osize := Vector2(otex.get_size() * _prev_scale).round().max(Vector2(2, 2))
				_ui.draw_texture_rect(otex, Rect2((EMBLEM_AT + Vector2(0.0, _prev_bob) - osize * 0.5).floor(), osize), false,
					Color(1, 1, 1, 1.0 - _prev_age / EMBLEM_FADE))
	var scale := entrance_scale()
	if scale <= 0.0:
		_draw_flash(type)
		return
	var bob := _bob()
	var pulse := 0.5 + 0.5 * sin(TAU * _clock / 1.4)
	var glow_at := EMBLEM_AT + Vector2(0.0, bob)
	for g in [[34.0, 0.08], [28.0, 0.1], [22.0, 0.12]]:
		_ui.draw_circle(glow_at, g[0] * minf(1.0, scale), Color(col.r, col.g, col.b, g[1] + 0.05 * pulse))
	_draw_pool_ring(col, 0.55 + 0.3 * pulse)
	var tex: Texture2D = turn[emblem_frame()]
	var size := Vector2(tex.get_size() * scale).round().max(Vector2(2, 2))
	var ry := EMBLEM_AT.y + 33.0
	var half := Vector2(size.x, roundf(size.y * 0.5))
	_ui.draw_texture_rect(tex, Rect2(Vector2(EMBLEM_AT.x - half.x * 0.5, ry + 3.0 + half.y).floor(), Vector2(half.x, -half.y)), false, Color(1, 1, 1, 0.2))
	var sparks := GodSelectArt.frame_set("emblem_spark_" + type)
	if not sparks.is_empty():
		for k in _sparks.size():
			if not spark_in_front(k):
				_draw_spark(sparks, k, bob, 0.75)
	_ui.draw_texture_rect(tex, Rect2((EMBLEM_AT + Vector2(0.0, bob) - size * 0.5).floor(), size), false)
	if not sparks.is_empty():
		for k in _sparks.size():
			if spark_in_front(k):
				_draw_spark(sparks, k, bob, 1.0)
	_draw_flash(type)


func _draw_spark(sparks: Array[Texture2D], k: int, bob: float, alpha: float) -> void:
	var tex: Texture2D = sparks[(int(_clock * SPARK_FPS) + k) % sparks.size()]
	_ui.draw_texture(tex, (spark_pos(k, bob) - tex.get_size() * 0.5).floor(), Color(1, 1, 1, alpha))


func _draw_flash(type: String) -> void:
	var flash := GodSelectArt.frame_set("emblem_flash_" + type)
	var k := int(fx_age * FLASH_FPS)
	if k < flash.size():
		_ui.draw_texture(flash[k], (EMBLEM_AT - flash[k].get_size() * 0.5).floor())


## Two dashed ellipses of light on the pool under the emblem, turning slowly against each other, a pixel at a time (the points are
## precomputed; each frame only tests which dashes are lit).
func _draw_pool_ring(col: Color, alpha: float) -> void:
	for k in RINGS.size():
		var r: Array = RINGS[k]
		var c := col.lightened(r[5]) if r[5] > 0.0 else col
		c.a = alpha
		var pts := _ring_pts[k]
		var ph := _ring_phase[k]
		var turn: float = _clock * r[4]
		for n in pts.size():
			if fposmod(ph[n] + turn, 1.0) < r[3]:
				_ui.draw_rect(Rect2(pts[n], Vector2.ONE), c)


func _draw_braziers() -> void:
	var fr := GodSelectArt.frame_set("brazier")
	if fr.is_empty():
		return
	for k in BRAZIERS.size():
		var tex: Texture2D = fr[int(_clock * 8.0 + k * 3) % fr.size()]
		_ui.draw_texture(tex, BRAZIERS[k] - Vector2(tex.get_width() * 0.5, tex.get_height() - 1.0))


## Red leaves drifting down and wrapping; each position is a function of the clock.
func _draw_leaves() -> void:
	var leaf := GodSelectArt.texture("leaf")
	if leaf == null:
		return
	for l in _leaves:
		var y := fposmod(l[1] + _clock * l[2], 380.0) - 10.0
		var x: float = l[0] + sin(_clock * 0.8 + l[3]) * 14.0
		_ui.draw_set_transform(Vector2(x, y), _clock * l[4] + l[3])
		_ui.draw_texture(leaf, -leaf.get_size() * 0.5)
	_ui.draw_set_transform(Vector2.ZERO)


## The selected type's lines in the top panel: name, verbs in the god's colour, flavour, then Tier 1 and Neighbours each on its own line.
func _draw_info() -> void:
	var type: String = GodTree.RING[selected]
	var lines := type_lines(type)
	var w := INFO_RECT.size.x - 16.0
	_ui.draw_rect(INFO_RECT, Color(0.03, 0.03, 0.06, 0.88))
	UiTheme.frame(_ui, INFO_RECT, true)
	var x := INFO_RECT.get_center().x
	var y := INFO_RECT.position.y + 16.0
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(lines[0], UiTheme.SIZE_BIG) * 0.5), y), lines[0], UiTheme.SIZE_BIG, UiTheme.COL_GOLD)
	y += 11.0
	var vcol: Color = Color(GOD_COL.get(type, Color.WHITE)).lightened(0.25)
	var verb := verbs(type)
	UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(verb, UiTheme.SIZE_SMALL) * 0.5), y), verb, UiTheme.SIZE_SMALL, vcol)
	y += 16.0
	for row in UiTheme.wrap(lines[1], w, UiTheme.SIZE_BODY):
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row) * 0.5), y), row, UiTheme.SIZE_BODY, UiTheme.COL_TEXT)
		y += UiTheme.LINE_BODY
	y -= UiTheme.LINE_BODY - 10.0
	for k in [2, 3]:
		var row := UiTheme.fit(lines[k], w, UiTheme.SIZE_SMALL)
		UiTheme.text(_ui, Vector2(roundf(x - UiTheme.width(row, UiTheme.SIZE_SMALL) * 0.5), y), row, UiTheme.SIZE_SMALL, UiTheme.COL_DIM)
		y += 10.0
