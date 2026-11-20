extends RefCounted
## World Map + Conquer Progress Task 5: the World Map page -- six spots (two towns, four sealed), the sealed and the locked refuse, the
## last town, Enter and Esc, the arrows, the blocked and dim lines, the conquered seal, and the page at four window shapes.


static func run(t) -> void:
	GodTree.dev_fill = true
	_six_spots(t)
	_sealed_refuse(t)
	_locked_refuse(t)
	_starts_on_last(t)
	_locked_last_town(t)
	_enter_descends(t)
	_esc_backs(t)
	_arrows(t)
	_blocked(t)
	_dim_town(t)
	_conquered_seal(t)
	_window_sizes(t)
	GodTree.dev_fill = false


static func _click(at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = at
	return e


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _slot() -> GodSlot:
	return GodSlot.make(1, "ruin", 7)


## A god with both towns open (the Capital opened by Aldermere's 132).
static func _open_both() -> GodSlot:
	var god := _slot()
	god.believers["aldermere"] = 132
	god.opened.append("capital")
	return god


## A map on the tree, its actions collected: [map, got].
static func _make(god: GodSlot) -> Array:
	var map := WorldMap.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(map)
	map.setup(god)
	var got := []
	map.action.connect(func(what: String) -> void: got.append(what))
	return [map, got]


static func _six_spots(t) -> void:
	t.check(WorldLayout.ids().size() == 6, "the map has six spots (%s)" % [WorldLayout.ids()])
	var towns := 0
	var sealed := 0
	for id in WorldLayout.ids():
		if WorldLayout.is_town(id):
			towns += 1
		else:
			sealed += 1
	t.check(towns == 2 and sealed == 4, "two towns and four sealed spots (%d, %d)" % [towns, sealed])
	var ids := WorldLayout.ids()
	for i in ids.size():
		var r := WorldLayout.spot_rect(ids[i])
		t.check(WorldLayout.LAND.encloses(r) and r.position.y >= ChamberLayout.BAR_H, "%s sits inside the land and below the bar" % ids[i])
		t.check(WorldLayout.at(WorldLayout.spot(ids[i]).place) == ids[i], "at(place) finds %s" % ids[i])
		for j in range(i + 1, ids.size()):
			t.check(not r.intersects(WorldLayout.spot_rect(ids[j])), "%s and %s do not touch" % [ids[i], ids[j]])
	t.check(WorldLayout.at(Vector2(5.0, 5.0)) == "", "a point far from every spot finds none")
	t.check(WorldLayout.name_of("aldermere") == "Aldermere" and WorldLayout.name_of("vael") == "Vael Crossing", "names: towns from Conquest, sealed spots their own")


static func _sealed_refuse(t) -> void:
	var made := _make(_open_both())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	var before := map.selected
	for id: String in ["thornwick", "saltmere", "greyhollow", "vael"]:
		map.click(WorldLayout.spot(id).place)
		t.check(map.selected == before and got.is_empty(), "a click on sealed %s selects nothing and emits nothing (%s, %s)" % [id, map.selected, got])
		t.check(map.info_lines(id)[1] == "Beyond your reach" and map.spot_state(id) == "sealed", "%s says it is beyond reach" % id)
	t.check(not map.select("thornwick"), "select(thornwick) is refused")
	map.free()


static func _locked_refuse(t) -> void:
	var made := _make(_slot())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	t.check(map.spot_state("capital") == "locked", "a fresh god: the Capital is locked (%s)" % map.spot_state("capital"))
	map.click(WorldLayout.spot("capital").place)
	t.check(map.selected == "aldermere" and got.is_empty(), "a click on the locked Capital selects nothing (%s)" % map.selected)
	t.check(map.info_lines("capital")[1] == "Conquer 60% of Aldermere", "the lock line (%s)" % [map.info_lines("capital")])
	map.free()


static func _starts_on_last(t) -> void:
	var god := _open_both()
	god.last_town = "capital"
	var made := _make(god)
	t.check((made[0] as WorldMap).selected == "capital", "the map opens on the town last played (%s)" % (made[0] as WorldMap).selected)
	(made[0] as WorldMap).free()


static func _locked_last_town(t) -> void:
	var god := _slot()
	god.last_town = "capital"  # in memory only: never opened
	var made := _make(god)
	var map: WorldMap = made[0]
	var got: Array = made[1]
	t.check(map.selected == "aldermere", "a last town that is not open falls back to Aldermere (%s)" % map.selected)
	map._unhandled_input(_key(KEY_ENTER))
	t.check(got == ["descend"] and map.selected == "aldermere", "Enter descends into Aldermere (%s)" % [got])
	map.free()


static func _enter_descends(t) -> void:
	var made := _make(_slot())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	map._unhandled_input(_key(KEY_ENTER))
	t.check(got == ["descend"], "Enter emits descend once (%s)" % [got])
	got.clear()
	map._unhandled_input(_key(KEY_KP_ENTER))
	t.check(got == ["descend"], "KP Enter emits descend once (%s)" % [got])
	got.clear()
	map._on_gui_input(_click(WorldLayout.spot("aldermere").place))
	t.check(got == ["descend"], "a click on the selected spot descends (%s)" % [got])
	got.clear()
	map._on_gui_input(_click(map.descend_rect().get_center()))
	t.check(got == ["descend"], "a click on the Descend button descends (%s)" % [got])
	map.free()


static func _esc_backs(t) -> void:
	var made := _make(_slot())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	map._unhandled_input(_key(KEY_ESCAPE))
	t.check(got == ["back"], "Esc backs out (%s)" % [got])
	got.clear()
	map._on_gui_input(_click(map.back_rect().get_center()))
	t.check(got == ["back"], "the Back button backs out (%s)" % [got])
	map.free()


static func _arrows(t) -> void:
	var made := _make(_open_both())
	var map: WorldMap = made[0]
	t.check(map.selected == "aldermere", "both open: the map starts on Aldermere")
	map._unhandled_input(_key(KEY_RIGHT))
	t.check(map.selected == "capital", "Right from Aldermere selects the Capital (%s)" % map.selected)
	map._unhandled_input(_key(KEY_LEFT))
	t.check(map.selected == "aldermere", "Left returns (%s)" % map.selected)
	map.free()
	# Arrows never select a sealed or locked spot, though one lies that way: with the Capital locked, no arrow leaves Aldermere; with
	# both open, every arrow from either town ends on a spot that can be selected.
	var dirs := {KEY_UP: Vector2.UP, KEY_DOWN: Vector2.DOWN, KEY_LEFT: Vector2.LEFT, KEY_RIGHT: Vector2.RIGHT}
	for god: GodSlot in [_slot(), _open_both()]:
		var m: WorldMap = _make(god)[0]
		for start in ["aldermere", "capital"]:
			if not m.select(start):
				continue
			for code: Key in dirs:
				var from: Vector2 = WorldLayout.spot(start).place
				var barred := false  # a spot that cannot be selected lies in this direction
				for id in WorldLayout.ids():
					if not m.selectable(id) and ((WorldLayout.spot(id).place as Vector2) - from).normalized().dot(dirs[code]) > 0.0:
						barred = true
				m.select(start)
				m._unhandled_input(_key(code))
				t.check(m.selectable(m.selected) and WorldLayout.is_town(m.selected),
					"%s, arrow %d from %s lands on a selectable town, not a barred spot (%s; barred spot that way: %s)" % [god.opened, code, start, m.selected, barred])
		m.free()
	var locked: WorldMap = _make(_slot())[0]
	var barred_any := false
	for id in WorldLayout.ids():
		barred_any = barred_any or not locked.selectable(id)
	t.check(barred_any and not locked.select("capital") and locked.selected == "aldermere", "a locked Capital cannot be selected, and a sealed spot exists to be refused")
	locked.free()


static func _blocked(t) -> void:
	GodTree.dev_fill = false
	GodTree.use_table(GodTree.blank())
	var made := _make(_slot())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	map._unhandled_input(_key(KEY_ENTER))
	t.check(got.is_empty() and map.line == HubStatus.BLOCKED, "nothing to draft: Enter emits nothing and says so (%s, %s)" % [got, map.line])
	map.free()
	GodTree.use_table({})
	GodTree.dev_fill = true


static func _dim_town(t) -> void:
	var made := _make(_open_both())
	var map: WorldMap = made[0]
	var got: Array = made[1]
	t.check(map.spot_state("capital") == "open", "the open Capital hosts a tier 1 night: open (%s)" % map.spot_state("capital"))
	map.select("capital")
	map._unhandled_input(_key(KEY_ENTER))
	t.check(got == ["descend"], "Enter on the open Capital emits descend (%s)" % [got])
	map.free()
	var none_tier := 0
	for k in range(2, 6):
		var hosts := false
		for id in TierBook.missions(k):
			hosts = hosts or MissionBook.hostable(id, City.by_id(&"capital"))
		if not hosts:
			none_tier = k
			break
	t.check(none_tier > 0, "some tier is hosted by nothing in the Capital (%d)" % none_tier)
	var god := _open_both()
	god.tier = none_tier
	var made2 := _make(god)
	var map2: WorldMap = made2[0]
	var got2: Array = made2[1]
	t.check(map2.spot_state("capital") == "dim", "at a tier the Capital hosts none of: dim (%s)" % map2.spot_state("capital"))
	map2.select("capital")
	map2._unhandled_input(_key(KEY_ENTER))
	t.check(got2.is_empty() and map2.line == WorldMap.NO_NIGHT, "Enter on a dim town emits nothing and says so (%s, %s)" % [got2, map2.line])
	map2.free()


static func _conquered_seal(t) -> void:
	var god := _slot()
	god.believers["aldermere"] = Conquest.population("aldermere")
	var made := _make(god)
	var map: WorldMap = made[0]
	t.check(map.spot_state("aldermere") == "conquered", "a full town is conquered (%s)" % map.spot_state("aldermere"))
	t.check(Array(map.info_lines("aldermere")).has("Conquered"), "its plate says Conquered (%s)" % [map.info_lines("aldermere")])
	map.free()


static func _window_sizes(t) -> void:
	for area: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(1024, 768)]:
		UiScale.set_test_area(area)
		var made := _make(_open_both())
		var map: WorldMap = made[0]
		var back := UiScale.backdrop(map._ui)
		t.check(back.encloses(map.back_rect()) and back.encloses(map.descend_rect()), "%s: the Back and Descend buttons are on the screen" % area)
		t.check(map._ui.mouse_filter == Control.MOUSE_FILTER_IGNORE and (map._ui.get_parent() as Control).mouse_filter == Control.MOUSE_FILTER_STOP,
			"%s: the blocker takes the mouse, the 640x360 child ignores it" % area)
		for id in WorldLayout.ids():
			var r := WorldLayout.spot_rect(id)
			t.check(not r.intersects(map.back_rect()) and not r.intersects(map.descend_rect()), "%s: the buttons stay off %s" % [area, id])
		map._on_gui_input(_click(WorldLayout.spot("capital").place))
		t.check(map.selected == "capital", "%s: a click on the Capital selects it (%s)" % [area, map.selected])
		map._on_gui_input(_click(WorldLayout.spot("aldermere").place))
		t.check(map.selected == "aldermere", "%s: a click on Aldermere selects it (%s)" % [area, map.selected])
		map.free()
		UiScale.clear_test_area()
