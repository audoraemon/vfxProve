extends RefCounted
## God P3 Task 5 (plan P3-17, P3-18; MS §2, §3.4-3.5, §5; pre-flight R2 R12 G5): key C and the chain's aim, the chain plate above the slot row's right
## end (clear of the slots, the stack, the strip, the modes plate and the tags' labels), the rings on tags, the director's strip rows merged with
## the timeline's, and a won rite's plate and larger rise. A stub rite stands in for the director (its plate words, strip rows and tag ring are
## set by the test); the keys run through a real Mission's _unhandled_input on a stub world, as test_legend does (pre-flight G5).

const DT := 0.05
const SIX := ["doom", "whisper", "smite", "noleave", "deathmark", "belllies"]
const THREE := ["doom", "whisper", "smite"]
const FAR := Vector2(5.5, 12.5)


## A rite's director with a plate, strip rows and a tag ring the tests set, and one victim to chain (the real chain, on the real walk grid).
class StubRite extends RiteDirector:
	var plate := "READY"
	var rows: Array[Dictionary] = []
	var key_answer := ""
	var tag_ring := -1.0
	## Where the one tag sits (screen pixels with an identity camera, lift 0), whether it is edge-arrowed, and its label.
	var tag_screen := Vector2.INF
	var tag_edge := false

	func rite_id() -> String:
		return RiteBook.FIRST_TASTE

	func victim_word() -> String:
		return "LAMPLIGHTER"

	func _appoint_victims() -> Array[Person]:
		var out: Array[Person] = []
		var v := _citizen_near(FAR, CitizenProfile.Role.RESIDENT, out)
		if v != null:
			_set_down(v, _walkable(FAR))
			v.go_duty(v.ground_pos)
			out.append(v)
		return out

	func chain_plate() -> String:
		return plate

	func chain_key() -> String:
		return key_answer if key_answer != "" else super.chain_key()

	func strip_rows() -> Array[Dictionary]:
		return rows

	func tags() -> Array[MapTag]:
		var out: Array[MapTag] = []
		var t := MapTag.person(Vector2(2.0, 3.0) if tag_screen == Vector2.INF else Iso.screen_to_ground(tag_screen), Color.RED, "CAPTIVE", tag_edge)
		t.lift = 0.0
		t.ring = tag_ring
		out.append(t)
		return out


static func run(t) -> void:
	_chain_rect_3(t)
	_chain_rect_6(t)
	_chain_rect_modes(t)
	_chain_states(t)
	_chains_key(t)
	_refused_shows(t)
	_tags_clear_chain(t)
	_arrows_clear_chain(t)
	_refused_once(t)
	_strip_merges(t)
	_ring_redraw(t)
	_rise_scale(t)
	_rite_plate(t)
	_chain_hidden(t)
	_keys_drive_the_chain(t)
	_aim_never_outlives(t)
	_win_ending(t)
	Hud.reset_session()


# --- The world -------------------------------------------------------------------------------------------

static func _world(powers: Array) -> Dictionary:
	var def := MissionBook.first_taste()
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.profile = def.response_profile(ResponseProfile.DEFAULT)
	crowd.spawn()
	var rules := Rules.new().setup(PackedStringArray(powers), null, env, field, crowd, town, def)
	rules.caster = func(_s: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var director := StubRite.new().setup(rules, crowd, town, null) as StubRite
	rules.director = director
	var aim := Targeting.new().setup(rules, crowd)
	var hud := Hud.new().setup(rules, crowd, town, aim)
	return {"env": env, "town": town, "field": field, "world": world, "crowd": crowd, "rules": rules, "d": director, "aim": aim,
		"hud": hud}


static func _done(s: Dictionary) -> void:
	(s.hud as Hud).free()
	(s.aim as Targeting).free()
	var rules: Rules = s.rules
	rules.teardown()
	rules.free()
	(s.crowd as Crowd).clear()
	(s.field as EnemyField).clear()
	(s.field as EnemyField).free()
	(s.env as EnvironmentField).clear()
	(s.env as EnvironmentField).free()
	(s.town as Town).free()
	(s.crowd as Crowd).free()
	(s.world as Node).free()


## A Mission with just what the keys touch (the suite runs outside a scene tree, where a real Mission's _ready() never comes): the world's rules,
## aim and HUD, and a battlefield's HUD layer. The real start() is FLOW's.
static func _mission(s: Dictionary) -> Mission:
	var m := Mission.new()
	m._bf = Battlefield.new()
	m._bf.hud_layer = CanvasLayer.new()
	m._rules = s.rules
	m._aim = s.aim
	m._hud = s.hud
	return m


static func _drop(m: Mission) -> void:
	m._bf.hud_layer.free()
	m._bf.free()
	m.free()


static func _key(code: Key, mods := {}) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	e.ctrl_pressed = bool(mods.get("ctrl", false))
	e.shift_pressed = bool(mods.get("shift", false))
	e.alt_pressed = bool(mods.get("alt", false))
	e.meta_pressed = bool(mods.get("meta", false))
	return e


static func _click(at: Vector2, button := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.position = at
	return e


## The fixture the plate's geometry tests need: the stack, the strip and the slots all up, or the intersections below would be vacuous (pre-flight R12).
static func _full(t, s: Dictionary, label: String) -> void:
	var hud: Hud = s.hud
	(s.d as StubRite).rows = [{"in": 30.0, "label": "CLERGY"}]
	t.check(hud.stack_rect().has_area(), "%s: the stack has an area to keep clear of (%s)" % [label, hud.stack_rect()])
	t.check(hud.events_rect(640.0).has_area(), "%s: the strip has an area to keep clear of (%s)" % [label, hud.events_rect(640.0)])
	t.check(hud.chain_shown(), "%s: the plate shows in a rite" % label)


static func _chain_rect_3(t) -> void:
	var s := _world(THREE)
	_full(t, s, "3 slots")
	_rect_checks(t, s, "3 slots")
	_done(s)


static func _chain_rect_6(t) -> void:
	var s := _world(SIX)
	_full(t, s, "6 slots")
	_rect_checks(t, s, "6 slots")
	_done(s)


## The plate is 100 x 20, ends at the slots' right end, sits 4 px above them, and touches nothing else the HUD draws.
static func _rect_checks(t, s: Dictionary, label: String) -> void:
	var hud: Hud = s.hud
	var r := hud.chain_rect()
	t.check(r.size == Vector2(100.0, 20.0) and is_equal_approx(r.end.x, hud.slots_rect().end.x)
		and is_equal_approx(r.end.y + 4.0, Hud.SLOT_TOP), "%s: 100 x 20, ends at the slots' right end, 4 px above them (%s)" % [label, r])
	var clear := true
	for i in (s.rules as Rules).loadout.size():
		clear = clear and not r.intersects(hud.slot_rect(i))
	t.check(clear, "%s: clear of every slot" % label)
	t.check(not r.intersects(hud.stack_rect()) and not r.intersects(hud.events_rect(640.0)) and not r.intersects(hud.ascend_rect()),
		"%s: clear of the stack, the strip and the ASCEND plate" % label)
	t.check(Rect2(0.0, 0.0, 640.0, 360.0).encloses(r), "%s: inside the screen" % label)
	t.check(hud.chain_label() == "C CHAIN", "%s: the label reads C CHAIN" % label)


## Pre-flight R2: The Bell Lies in the last slot, focused, draws its modes plate over the row's right end; the plate steps up out of its way.
static func _chain_rect_modes(t) -> void:
	var s := _world(SIX)
	var hud: Hud = s.hud
	var aim: Targeting = s.aim
	var base := hud.chain_rect()
	t.check(is_equal_approx(base.position.y, Hud.SLOT_TOP - Hud.CHAIN_GAP - Hud.CHAIN_SIZE.y) and not hud.modes_rect().has_area(),
		"nothing focused: the plate at its place and no modes plate (%s)" % base)
	aim.pick(5)
	var modes := hud.modes_rect()
	t.check(modes.has_area() and modes.intersects(base), "The Bell Lies focused: its modes plate lies where the plate would be (%s over %s)" % [modes, base])
	var lifted := hud.chain_rect()
	t.check(not lifted.intersects(modes) and is_equal_approx(lifted.position.y, base.position.y - Hud.PLATE_H - Hud.CHAIN_GAP)
		and is_equal_approx(lifted.end.x, base.end.x), "the plate steps up one PLATE_H + 4, clear of the modes plate (%s)" % lifted)
	var clear := true
	for i in SIX.size():
		clear = clear and not lifted.intersects(hud.slot_rect(i))
	t.check(clear and Rect2(0.0, 0.0, 640.0, 360.0).encloses(lifted), "and of the slots and inside the screen")
	aim.pick(0)
	t.check(is_equal_approx(hud.chain_rect().position.y, base.position.y), "another power focused (no modes): back at its place")
	_done(s)


static func _chain_states(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	var seen: Array[String] = []
	for words in ["READY", "DRAG 0:41", "0:06"]:
		d.plate = words
		seen.append(hud.chain_state())
	t.check(seen == ["READY", "DRAG 0:41", "0:06"], "the plate reads the director's words (%s)" % [seen])
	d.plate = "READY"
	var ready := hud._signature()
	d.plate = "DRAG 0:41"
	t.check(hud._signature() != ready, "and a change of words redraws the HUD")
	ready = hud._signature()
	hud.chain_aiming = true
	t.check(hud._signature() != ready, "so does the aim turning the frame gold")
	_done(s)


static func _chains_key(t) -> void:
	t.check(Mission.chains(_key(KEY_C)) and not Mission.chains(_key(KEY_X)), "C is the chain's key, only C")
	t.check(not Mission.chains(_key(KEY_C, {"ctrl": true})) and not Mission.chains(_key(KEY_C, {"shift": true}))
		and not Mission.chains(_key(KEY_C, {"alt": true})) and not Mission.chains(_key(KEY_C, {"meta": true})), "with a modifier it is not")
	var echo := _key(KEY_C)
	echo.echo = true
	var up := _key(KEY_C)
	up.pressed = false
	t.check(not Mission.chains(echo) and not Mission.chains(up), "a held C and a release are not")
	t.check(not Mission.SLOT_KEYS.has(Mission.CHAIN_KEY) and Mission.CHAIN_KEY != KEY_F and Mission.CHAIN_KEY != KEY_H and Mission.CHAIN_KEY != KEY_R,
		"and no other mission key is C")


static func _refused_shows(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	t.check(not hud.chain_flashing() and hud.banners().is_empty(), "no refusal yet: no flash, no words")
	hud.chain_refused("NOT A LAMPLIGHTER")
	t.check(hud.chain_flashing() and hud.banners() == PackedStringArray(["NOT A LAMPLIGHTER"]),
		"a refusal flashes the plate and queues its words (%s)" % [hud.banners()])
	hud.advance(Hud.FLASH_SECONDS + 0.05)
	t.check(not hud.chain_flashing() and hud.banners() == PackedStringArray(["NOT A LAMPLIGHTER"]), "the flash is over in %.2f s, the banner has its own time" % Hud.FLASH_SECONDS)
	_done(s)


## A tag whose label would lie under the plate has it moved off or left out, through the HUD's own layout (_lay_out_tags(), the one _draw_tags() draws),
## so dropping the chain rect from its plates fails here (task 5 review minor).
static func _tags_clear_chain(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	var chain := hud.chain_rect()
	d.tag_screen = chain.get_center() + Vector2(0.0, 6.0)  # the diamond inside the plate's lower half, its label above it
	var layout := hud._lay_out_tags()
	var k: Dictionary = layout[0]
	t.check(String(k.mode) == "map" and (not bool(k.show) or not (k.label as Rect2).intersects(chain)),
		"the HUD's layout keeps the label off the plate (%s over %s, shown %s)" % [k.label, chain, k.show])
	var tags: Array[MapTag] = [d.tags()[0]]
	var bare := Hud.tag_layout(tags, Transform2D.IDENTITY, Vector2(640.0, 360.0))
	var e: Dictionary = bare[0]
	t.check(String(e.mode) == "map" and bool(e.show) and (e.label as Rect2).intersects(chain),
		"and without the plate counted the label would lie on it (%s, shown %s)" % [e.label, e.show])
	_done(s)


## Review I1: the plate is a keepout for edge arrows and diamonds too. A victim far to the south-east gets an arrow on the frame's bottom edge right
## over the plate's x-range; a victim's diamond under the plate becomes an arrow above it.
static func _arrows_clear_chain(t) -> void:
	var s := _world(SIX)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	var chain := hud.chain_rect()
	var view := Vector2(640.0, 360.0)
	d.tag_edge = true
	d.tag_screen = Vector2(2900.0, 1365.0)
	var tags: Array[MapTag] = [d.tags()[0]]
	var bare: Dictionary = Hud.tag_layout(tags, Transform2D.IDENTITY, view)[0]
	var pad := Vector2.ONE * Hud.ARROW_PAD
	t.check(String(bare.mode) == "arrow" and Rect2((bare.arrow as Vector2) - pad, pad * 2.0).intersects(chain),
		"far south-east: without the keepout the arrow's tip sits on the plate (%s over %s)" % [bare.arrow, chain])
	var e: Dictionary = hud._lay_out_tags()[0]
	var tip: Vector2 = e.arrow
	t.check(String(e.mode) == "arrow" and not Rect2(tip - pad, pad * 2.0).intersects(chain) and Rect2(Vector2.ZERO, view).has_point(tip),
		"with it the HUD's layout puts the tip clear of the plate (%s, plate %s)" % [tip, chain])
	t.check((e.dir as Vector2).x > 0.0 and (e.dir as Vector2).y > 0.0 and (not bool(e.show) or not (e.label as Rect2).intersects(chain)),
		"still pointing south-east, its label off the plate")
	# A diamond under the plate: an edge tag becomes an arrow above it; a tag without edge keeps its diamond.
	d.tag_screen = chain.get_center()
	var under: Dictionary = hud._lay_out_tags()[0]
	var tip2: Vector2 = under.arrow
	t.check(String(under.mode) == "arrow" and not Rect2(tip2 - pad, pad * 2.0).intersects(chain),
		"a diamond under the plate becomes an arrow above it (%s)" % [under.mode])
	d.tag_edge = false
	t.check(String((hud._lay_out_tags()[0] as Dictionary).mode) == "map", "a tag without edge keeps its diamond")
	_done(s)


## Review I3: the same refusal twice running is queued once, however often C is pressed; a different one queues, and then the first again.
static func _refused_once(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	for i in 10:
		hud.chain_refused(RiteDirector.ONE_CHAIN)
	t.check(hud.banners() == PackedStringArray([RiteDirector.ONE_CHAIN]), "ten refusals with the same words queue one banner (%s)" % [hud.banners()])
	t.check(hud.chain_flashing(), "and the plate still flashes")
	hud.chain_refused(RiteDirector.NOT_READY)
	hud.chain_refused(RiteDirector.NOT_READY)
	hud.chain_refused(RiteDirector.ONE_CHAIN)
	t.check(hud.banners() == PackedStringArray([RiteDirector.ONE_CHAIN, RiteDirector.NOT_READY, RiteDirector.ONE_CHAIN]),
		"other words queue, and the first again after them (%s)" % [hud.banners()])
	_done(s)


static func _strip_merges(t) -> void:
	Hud.details = true  # the strip lists two rows expanded
	var s := _world(THREE)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	t.check(hud.event_rows().is_empty() and not hud.events_rect(640.0).has_area(), "no rows anywhere: no strip")
	d.timeline = EventTimeline.new().add(20.0, "tl", "TIMELINE")
	d.rows = [{"in": 40.0, "label": "LATE MARCH"}, {"in": 12.0, "label": "CLERGY MARCH"}]
	var rows := hud.event_rows()
	t.check(rows.size() == 2 and String(rows[0][1]) == "CLERGY MARCH" and String(rows[0][0]) == "0:12" and String(rows[1][1]) == "TIMELINE",
		"the director's rows sort with the timeline's, soonest first (%s)" % [rows])
	Hud.details = false
	rows = hud.event_rows()
	t.check(rows.size() == 1 and String(rows[0][1]) == "CLERGY MARCH", "collapsed, the soonest of all (%s)" % [rows])
	d.rows = [{"in": 5.0, "clock": "CLEANSING 0:12", "label": "SHRINE"}]
	rows = hud.event_rows()
	t.check(String(rows[0][0]) == "CLEANSING 0:12", "a row may carry its own clock text (%s)" % [rows])
	Hud.reset_session()
	_done(s)


## A ring that fills (a grip on a captive who stands still) must redraw the tag layer; the default (-1) draws as every tag always did.
static func _ring_redraw(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	t.check(MapTag.person(Vector2.ZERO, Color.RED).ring == -1.0, "a tag has no ring by default")
	var none := hud._tag_signature()
	t.check(none != "" and none == hud._tag_signature(), "no ring: the layer's signature is stable")
	d.tag_ring = 0.25
	var quarter := hud._tag_signature()
	d.tag_ring = 0.5
	var half := hud._tag_signature()
	t.check(quarter != none and half != quarter, "a filling ring changes the signature, so the layer redraws (%s)" % [[none == quarter, quarter == half]])
	d.tag_ring = 0.5
	t.check(hud._tag_signature() == half, "and the same fill does not")
	_done(s)


static func _rise_scale(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	t.check(is_equal_approx(hud.rise_scale(), 1.0), "the ascent's column is drawn at scale 1")
	hud.rise(Vector2(1.0, 2.0))
	t.check(is_equal_approx(hud.rise_scale(), 1.0) and hud.rising(), "rise(at) is the ascent's, as before")
	hud.rise(RiteDirector.SHRINE, Mission.RITE_RISE)
	t.check(is_equal_approx(hud.rise_scale(), 2.0) and hud.rising(), "a rite's column is twice as wide (%s)" % hud.rise_scale())
	hud.rise(Vector2(1.0, 2.0))
	t.check(is_equal_approx(hud.rise_scale(), 1.0), "the next ascent is the plain one again")
	_done(s)


static func _rite_plate(t) -> void:
	var s := _world(SIX)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	d.rows = [{"in": 30.0, "label": "CLERGY"}]
	t.check(hud.stack_rect().has_area() and hud.events_rect(640.0).has_area() and hud.chain_shown() and not hud.rite_plate_up()
		and not hud.rite_plate_rect().has_area(), "before the win: the stack, the strip and the chain plate are up and no win plate")
	var before := hud._signature()
	var lines := RiteBook.plate_lines(RiteBook.FIRST_TASTE)
	hud.show_rite_plate(lines)
	var r := hud.rite_plate_rect()
	t.check(hud.rite_plate_up() and r.position.y == Hud.RITE_PLATE_TOP and r.size.y == Hud.RITE_PLATE_H and absf(r.get_center().x - 320.0) <= 1.0
		and Rect2(0.0, 0.0, 640.0, 360.0).encloses(r), "the plate is centred, 80 tall, inside the screen (%s)" % r)
	# Review I2: the banner's bar (the last shard's banner is up as the plate is) and Cael's line stay uncovered, however wide they are.
	var bar := Rect2(0.0, Hud.BANNER_TOP, 640.0, Hud.BANNER_H)
	var cael := Rect2(0.0, Hud.SUBTITLE_TOP, 640.0, Hud.SUBTITLE_H)
	t.check(not r.intersects(bar) and not r.intersects(cael) and r.position.y > bar.end.y and r.position.y > cael.end.y,
		"the plate lies below the banner's bar (%s) and Cael's line (%s), covering neither" % [bar, cael])
	t.check(not hud.stack_rect().has_area() and not hud.events_rect(640.0).has_area() and not hud.chain_shown(),
		"and it replaces the stack, the strip and the chain plate")
	var rest := UiTheme.wrap(lines[2], Hud.RITE_PLATE_WRAP, UiTheme.SIZE_SMALL)
	t.check(lines.size() == 3 and rest.size() <= 2 and r.size.x >= UiTheme.width(lines[0], UiTheme.SIZE_BIG),
		"the three lines fit it (the stolen gift wraps to %d)" % rest.size())
	t.check(hud._signature() != before, "showing it redraws the HUD")
	var layout := Hud.tag_layout(hud.all_tags(), Transform2D.IDENTITY, Vector2(640.0, 360.0), hud.stack_rect())
	t.check(layout.size() == 1, "the tags are still laid out")
	_done(s)


## The plate waits for play: not in the tour's intro (its caption lies there, pre-flight R2), not once the night is over.
static func _chain_hidden(t) -> void:
	var s := _world(THREE)
	var hud: Hud = s.hud
	var rules: Rules = s.rules
	t.check(hud.chain_shown(), "in play the plate shows")
	hud.intro = true
	t.check(not hud.chain_shown(), "during the intro it does not")
	hud.intro = false
	rules.force_end(true, "shards")
	t.check(not hud.chain_shown(), "once the night is over it does not")
	_done(s)
	var plain := Hud.new()
	t.check(not plain.chain_shown() and plain.chain_state() == "" and plain.chain_rect() == Rect2(), "a HUD with no rules shows nothing")
	plain.free()


## Pre-flight G5: the keys, the plate click, Esc and the right-click through a real Mission's _unhandled_input.
static func _keys_drive_the_chain(t) -> void:
	var s := _world(THREE)
	var m := _mission(s)
	var hud: Hud = s.hud
	var d: StubRite = s.d
	var aim: Targeting = s.aim
	# C with the chain ready: the aim begins, the focused slot is let go, the plate goes gold.
	m._unhandled_input(_key(KEY_1))
	t.check(aim.slot == 0 and not m.chain_aim, "slot 1 focused, no chain aim")
	m._unhandled_input(_key(KEY_C))
	t.check(m.chain_aim and hud.chain_aiming and aim.slot == -1, "C: the aim is up, the plate is gold, the slot is let go")
	m._unhandled_input(_key(KEY_C))
	t.check(not m.chain_aim and not hud.chain_aiming, "C again lets the aim go")
	# A slot key, a slot click, Esc and the right-click end it.
	m._unhandled_input(_key(KEY_C))
	m._unhandled_input(_key(KEY_2))
	t.check(not m.chain_aim and aim.slot == 1, "a slot key ends the aim and focuses the slot")
	m._unhandled_input(_key(KEY_C))
	m._unhandled_input(_click(hud.slot_rect(0).get_center()))
	t.check(not m.chain_aim and aim.slot == 0, "a click on a slot ends it too and focuses that slot")
	var pauses := [0]
	m.pause_pressed.connect(func() -> void: pauses[0] += 1)
	m._unhandled_input(_key(KEY_C))
	m._unhandled_input(_key(KEY_ESCAPE))
	t.check(not m.chain_aim and not hud.chain_aiming and pauses[0] == 0, "Esc ends it, and opens no pause menu (%d)" % pauses[0])
	m._unhandled_input(_key(KEY_C))
	m._unhandled_input(_click(Vector2(100.0, 100.0), MOUSE_BUTTON_RIGHT))
	t.check(not m.chain_aim, "a right-click ends it")
	# A click on the chain plate is C.
	m._unhandled_input(_click(hud.chain_rect().get_center()))
	t.check(m.chain_aim, "a click on the plate is C: the aim is up")
	m._unhandled_input(_click(hud.chain_rect().get_center()))
	t.check(not m.chain_aim, "and again lets it go")
	# The aim click: a refusal keeps the aim and shows the words; the victim chains him and ends it.
	m._unhandled_input(_key(KEY_C))
	m.chain_click(Vector2(-14.0, -14.0))
	t.check(m.chain_aim and hud.chain_flashing() and hud.banners().has("NOT A LAMPLIGHTER") and d.chain_state == RiteDirector.Chain.READY,
		"a click on no one: NOT A LAMPLIGHTER, the plate flashes, the aim stays (%s)" % [hud.banners()])
	var victim: Person = d.marked[0] if not d.marked.is_empty() else null
	t.check(victim != null, "the stub marked a victim to chain")
	if victim != null:
		m.chain_click(victim.ground_pos)
		t.check(not m.chain_aim and d.chain_state == RiteDirector.Chain.BITE and d.captive == victim,
			"a click on a marked victim chains him and ends the aim (%s)" % [d.chain_state])
		# Not ready now: C is refused with the director's words, flashes, and begins no aim.
		hud.advance(1.0)
		var banners := hud.banners().size()
		for i in 10:
			m._unhandled_input(_key(KEY_C))
		t.check(not m.chain_aim and hud.chain_flashing() and hud.banners().size() == banners + 1 and hud.banners()[banners] == RiteDirector.ONE_CHAIN,
			"C ten times during a chain: ONE CHAIN AT A TIME queued once, the plate flashes, no aim (%s)" % [hud.banners()])
	# A Yank is the director's own; Mission only clicks.
	hud.advance(1.0)
	d.key_answer = "yank"
	var seen := hud.banners().size()
	m._unhandled_input(_key(KEY_C))
	t.check(not m.chain_aim and not hud.chain_flashing() and hud.banners().size() == seen, "a Yank is no refusal and no aim")
	d.key_answer = ""
	# C with the interface hidden brings it back, as a slot key does.
	d.chain_state = RiteDirector.Chain.READY
	m.set_ui_hidden(true)
	m._unhandled_input(_key(KEY_C))
	t.check(not m.ui_hidden and m.chain_aim, "C while hidden shows the interface and begins the aim")
	m._unhandled_input(_key(KEY_C))
	# The key is ignored off a rite (a Tier 1 mission has no chain) and in the intro and the ending.
	m._intro_left = 2.0
	m._unhandled_input(_key(KEY_C))
	t.check(not m.chain_aim, "in the intro C does nothing")
	m._intro_left = 0.0
	m._ending = true
	m._unhandled_input(_key(KEY_C))
	t.check(not m.chain_aim, "in the ending C does nothing")
	m._ending = false
	var rules: Rules = s.rules
	rules.director = null
	m._unhandled_input(_key(KEY_C))
	t.check(not m.chain_aim and not hud.chain_shown(), "off a rite C does nothing and the HUD has no plate")
	rules.director = d
	_drop(m)
	_done(s)


## The aim never outlives its chain: a chain that began another way, or the night's end, lets it go.
static func _aim_never_outlives(t) -> void:
	var s := _world(THREE)
	var m := _mission(s)
	var d: StubRite = s.d
	m.chain_aim = true
	m._sync_chain_aim()
	t.check(m.chain_aim, "a ready chain keeps its aim")
	d.chain_state = RiteDirector.Chain.BITE
	m._sync_chain_aim()
	t.check(not m.chain_aim and not (s.hud as Hud).chain_aiming, "a chain that began lets the aim go")
	d.chain_state = RiteDirector.Chain.READY
	m.chain_aim = true
	m._ending = true
	m._sync_chain_aim()
	t.check(not m.chain_aim, "and so does the ending")
	m._ending = false
	_drop(m)
	_done(s)


## A won rite: the light rises from the shrine at RITE_RISE and the plate carries RiteBook's lines; a lost one does neither.
static func _win_ending(t) -> void:
	var s := _world(THREE)
	var m := _mission(s)
	var hud: Hud = s.hud
	var rules: Rules = s.rules
	t.check(not m._rite_won(), "a rite not yet won is not")
	m._show_rite_win()
	t.check(hud.rite_plate_up() and hud.rising() and is_equal_approx(hud.rise_scale(), Mission.RITE_RISE),
		"the win shows the plate and a column twice as wide")
	t.check(hud._rite_lines == RiteBook.plate_lines(RiteBook.FIRST_TASTE), "with RiteBook's lines (%s)" % [hud._rite_lines])
	t.check(Mission.RITE_SECONDS == 4.0 and Mission.RITE_SECONDS > Mission.ENDING_SECONDS and Mission.RITE_RISE == 2.0, "the plate waits 4 s")
	rules.won = true
	t.check(m._rite_won(), "won, and a rite: the ending is the rite's")
	rules.director = null
	t.check(not m._rite_won(), "won off a rite: the ordinary ending")
	rules.director = s.d
	_drop(m)
	_done(s)
