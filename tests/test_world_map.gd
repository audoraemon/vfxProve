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
	_starts_on_aldermere_when_nothing_draws(t)
	_conquered_dim_and_line(t)
	_window_sizes(t)
	_painted_map(t)
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
	var god := _dim_god()
	t.check(GodNight.draw(god, "capital") == "" and GodNight.draw(god, "aldermere") != "", "setup: a Hunt is due; the Capital draws nothing, Aldermere still does (%s, %s)" % [GodNight.draw(god, "capital"), GodNight.draw(god, "aldermere")])
	var made2 := _make(god)
	var map2: WorldMap = made2[0]
	var got2: Array = made2[1]
	t.check(map2.spot_state("capital") == "dim", "a Hunt night is due and the Capital does not host it: dim (%s)" % map2.spot_state("capital"))
	map2.select("capital")
	map2._unhandled_input(_key(KEY_ENTER))
	t.check(got2.is_empty() and map2.line == WorldMap.NO_NIGHT, "Enter on a dim town emits nothing and says so (%s, %s)" % [got2, map2.line])
	map2.free()


## An open Capital where no night is drawn: Notice is full, so a Hunt night is due, and the Hunt is Aldermere-only.
static func _dim_god() -> GodSlot:
	var god := _open_both()
	god.notice = 100
	return god


## Final review 4: the last town is the Capital, but no night is drawn there (a Hunt is due, and the Hunt is not hosted in the Capital): the map opens on Aldermere.
static func _starts_on_aldermere_when_nothing_draws(t) -> void:
	var god := _dim_god()
	god.last_town = "capital"
	t.check(GodNight.draw(god, "capital") == "" and GodNight.draw(god, "aldermere") != "", "setup: a Hunt is due, nothing is drawn in the Capital")
	var made := _make(god)
	var map: WorldMap = made[0]
	t.check(map.selected == "aldermere", "the last town draws nothing: the map starts on Aldermere (%s)" % map.selected)
	map.free()


## Final review 5: a conquered town that draws nothing is dim (spec 4.6), still marked Conquered on its plate; and a refusal's line goes
## when the selection moves.
static func _conquered_dim_and_line(t) -> void:
	var god := _dim_god()
	god.believers["capital"] = Conquest.population("capital")
	var made := _make(god)
	var map: WorldMap = made[0]
	t.check(map.spot_state("capital") == "dim", "a conquered Capital where no night is drawn is dim (%s)" % map.spot_state("capital"))
	t.check(Array(map.info_lines("capital")).has("Conquered"), "its plate still says Conquered (%s)" % [map.info_lines("capital")])
	map.select("capital")
	t.check(map.selected == "capital", "a dim town is selectable")
	map.press_descend()
	t.check(map.line == WorldMap.NO_NIGHT, "a refusal says so (%s)" % map.line)
	map.select("aldermere")
	t.check(map.line == "", "moving the selection clears the line (%s)" % map.line)
	map.free()


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
		# the real path: the blocker's units (frame units scaled and offset), through its gui_input signal
		var blocker := map._ui.get_parent() as Control
		var f: float = map._ui.scale.x
		blocker.gui_input.emit(_click(map._ui.position + WorldLayout.spot("capital").place * f))
		t.check(map.selected == "capital", "%s: a click on the Capital through the blocker selects it (%s)" % [area, map.selected])
		blocker.gui_input.emit(_click(map._ui.position + map.back_rect().get_center() * f))
		t.check((made[1] as Array) == ["back"], "%s: a click on Back through the blocker emits back (%s)" % [area, made[1]])
		map._on_gui_input(_click(WorldLayout.spot("capital").place))
		map._on_gui_input(_click(WorldLayout.spot("aldermere").place))
		t.check(map.selected == "aldermere", "%s: a click on Aldermere selects it (%s)" % [area, map.selected])
		map.free()
		UiScale.clear_test_area()


## The painted map: every spot has its ribbon and picture on the vellum, the card and the tab keep clear of them, names fit their ribbons,
## the fog lies on what the god cannot reach, and the god's colour is the type's.
static func _painted_map(t) -> void:
	t.check(ResourceLoader.exists("res://assets/chamber/map.png"), "the painted map is in the project")
	var page := Rect2(0.0, 0.0, 640.0, 360.0)
	t.check(page.encloses(WorldMap.PLATE) and WorldLayout.LAND.encloses(WorldMap.PLATE), "the info card lies on the vellum")
	t.check(page.encloses(WorldMap.BACK), "the Back tab is on the page")
	for id in WorldLayout.ids():
		var rib := WorldLayout.ribbon(id)
		var span := WorldLayout.span(id)
		var p: Vector2 = WorldLayout.spot(id).place
		t.check(rib.size.x > 40.0 and WorldLayout.LAND.encloses(rib), "%s has a ribbon on the vellum (%s)" % [id, rib])
		t.check(rib.end.y < p.y and absf(rib.get_center().x - p.x) < span.x, "%s's ribbon is above its picture" % id)
		t.check(not rib.intersects(WorldMap.PLATE) and not Rect2(p - span, span * 2.0).intersects(WorldMap.PLATE), "%s keeps clear of the info card" % id)
		var size := WorldMap._fit_size(WorldLayout.name_of(id), rib.size.x - 4.0)
		t.check(size >= 7 and UiTheme.width(WorldLayout.name_of(id), size) <= rib.size.x - 4.0, "%s's name fits its ribbon at size %d" % [id, size])
	for r: Dictionary in WorldLayout.ROUTES:
		t.check(WorldLayout.is_town(r.from) and not WorldLayout.is_town(r.to) and WorldLayout.LAND.has_point(r.via), "a way runs from a town to a sealed spot (%s to %s)" % [r.from, r.to])
	var fresh: WorldMap = _make(_slot())[0]
	t.check(fresh.fog_of("aldermere") == 0.0 and fresh.fog_of("capital") > 0.5 and fresh.fog_of("capital") < 1.0 and fresh.fog_of("vael") == 1.0,
		"fog: none on an open town, some on a locked one, all on a sealed one (%s %s %s)" % [fresh.fog_of("aldermere"), fresh.fog_of("capital"), fresh.fog_of("vael")])
	t.check(fresh.god_color() == WorldMap.GOD_COL["ruin"], "the faith on the map is the god's colour")
	t.check(not WorldMap.moving and fresh._reveal.is_empty(), "a headless map is at rest: nothing drifts, nothing is revealed")
	fresh.free()
	var both: WorldMap = _make(_open_both())[0]
	t.check(both.fog_of("capital") == 0.0, "an opened Capital has no fog")
	both.free()
	t.check(WorldMap.GOD_COL == GodSelectScreen.GOD_COL, "the map's god colours are the God's Paths screen's")
	# The second round: painted pieces, the land-shaped faith, the coded road, the cloud banks.
	for name: String in ["land", "note", "seal", "seal_off", "tag", "pointer", "ship_0", "ship_1", "cloud_0", "cloud_5"]:
		t.check(ResourceLoader.exists("res://assets/chamber/map/%s.png" % name), "the map's %s is in the project" % name)
	t.check(ResourceLoader.exists("res://src/game/ui/world_faith.gdshader"), "the faith shader is in the project")
	t.check(WorldMap.faith_reach(0.0) == 0.0 and WorldMap.faith_reach(0.1) > 30.0 and WorldMap.faith_reach(1.0) > WorldMap.faith_reach(0.5),
		"faith reaches nowhere at 0, some way at once, further as the people turn")
	var page2 := Rect2(0.0, 0.0, 640.0, 360.0)
	for id in WorldLayout.ids():
		var full := WorldMap.cloud_bank(id)
		var thin := WorldMap.cloud_bank(id, true)
		t.check(full.size() >= 4 and thin.size() < full.size(), "%s: a sealed bank covers, a locked one is a ring (%d, %d)" % [id, full.size(), thin.size()])
		var rib2 := WorldLayout.ribbon(id)
		var clear := true
		for c: Array in full:
			var w: float = c[2]
			clear = clear and not Rect2((c[1] as Vector2) - Vector2(w, w * 0.4) * 0.5, Vector2(w, w * 0.4)).grow(-6.0).intersects(rib2)
		t.check(clear, "%s's clouds leave its ribbon to be read" % id)
	for id: String in WorldLayout.ROAD_PATHS:
		var path: Array = WorldLayout.ROAD_PATHS[id]
		var on_page := true
		for q: Vector2 in path:
			on_page = on_page and WorldLayout.LAND.has_point(q)
		t.check(WorldLayout.is_town(id) and path.size() >= 3 and on_page, "the road to %s runs over the vellum" % id)
	for q: Vector2 in WorldLayout.SHIPS:
		t.check(page2.has_point(q) and not WorldMap.PLATE.has_point(q), "a ship rides off the card (%s)" % q)
	var m1: WorldMap = _make(_slot())[0]
	t.check(m1.road_part("capital") < 1.0 and m1.road_part("capital") > 0.0, "the road to a locked Capital is inked part of the way")
	t.check((m1.faith_colors()[0] as Color) != WorldMap.GOD_COL["ruin"], "Ruin's hold is an ember, not the vellum's own orange")
	m1.free()
	var m2: WorldMap = _make(_open_both())[0]
	t.check(m2.road_part("capital") == 1.0, "the road to an open Capital is whole")
	t.check(page2.encloses(m2.descend_rect()) and WorldMap.PLATE.encloses(m2.descend_rect()), "the Descend seal is on the card")
	m2.free()

