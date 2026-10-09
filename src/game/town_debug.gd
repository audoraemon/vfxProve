extends Node2D
## Debug scene for Kingdoms Amid Kataclysm: the town of Aldermere and its fortified Royal Citadel on the shared
## Battlefield, its people (110 citizens and 50 soldiers, --people=N to scale), and every power castable from
## the keyboard. No rules yet (milestone 3).
## Flags after `--`: --capture-town [--only=<shot file prefix>] [--frames=N] [--dim=0..1] (screenshots; --dim darkens
## the scene as a power's dim does, to see the lights at dusk), --citadel-test (scripted strikes on the Citadel, logged),
## --crowd-test (scripted panic, logged), --bench [--only=<power key>] (frame times while that power plays
## beside the Citadel), --no-showcase (leaves out the GPT showcase district east and north of the walls, GptShowcase:
## on by default here and only here), --showcase-state=damaged|ruins (its buildings cracked or fallen),
## --showcase-page=N (which page of its rows: the meadow holds about thirty buildings at a time). F9 shows or hides
## the showcase's labels, F10 shows its next page.

## The spec's crowd: 110 citizens and 50 soldiers. --people=N scales both for benching.
const PEOPLE := Crowd.CITIZENS + Crowd.SOLDIERS
const PAN_SPEED := 320.0
## Pan limits (screen px) and the furthest zoom out: the map is 60 x 60 units since the town scale upgrade.
const PAN_MIN := Vector2(-1700, -900)
const PAN_MAX := Vector2(1700, 1000)
const ZOOM_MIN := 0.3
const ZOOM_MAX := 1.6
const DRAG_MIN := 0.5
## Keys 1-9, 0 and - pick PowerBook.POWERS[0..10].
const POWER_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS]
const KEY_LABELS := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-"]
## Meadow green (TownFloor.GRASS[2]), not the sandbox's near-black: TownFloor.FILL cannot cover the whole
## viewport at ZOOM_MIN with the pan limits, so any gap at the edge blends into grass instead of showing a void.
const CLEAR := Color("6e8230")
## [file, ground point to look at, zoom] for --capture-town.
const TOWN_SHOTS := [
	["town_overview.png", Vector2(0, 2), 0.3],
	# The whole capital (--city=capital): its 80x80 map at a glance.
	["capital_overview.png", Vector2(0, 0), 0.17],
	# Its east stone bridge and the third bridge, between the two wall rings.
	["capital_bridges.png", Vector2(9, 8), 0.6],
	# The old town's ring (the Keep, the noble, civic and guild quarters, the Great Market, the old town houses), the
	# harbour district and its quay, and the new town's ring south of the river (crafts, new town, tanners, poor and road
	# quarters).
	["capital_old_town.png", Vector2(-3, -13), 0.5],
	["capital_harbour.png", Vector2(28, -9), 0.75],
	["capital_south.png", Vector2(-4, 23), 0.5],
	# Polish 1: the Keep's courtyard (the royal garden and the drill yard), the third crossing, the harbour's quay (the
	# crane, the ferry landing, the dock warehouses), the wash houses on the north bank and the sluice.
	["capital_keep_court.png", Vector2(-15.5, -24.5), 1.0],
	["capital_third_bridge.png", Vector2(14, 8), 1.0],
	["capital_quay.png", Vector2(31.5, -2.5), 0.85],
	["capital_wash.png", Vector2(-1, 5.5), 0.7],
	["capital_sluice.png", Vector2(-27.6, 5.5), 1.3],
	# Polish 2: the Keep's service yard, the Keep's gate with its steps, the south district gate across its lane,
	# the cathedral close (the churchyard and the pilgrim plaza), the aqueduct feeding the cistern.
	["capital_keep_yard.png", Vector2(11.0, -25.0), 1.0],
	["capital_keep_gate.png", Vector2(4.0, -22.0), 1.4],
	["capital_district_gate.png", Vector2(-4.0, 28.0), 1.2],
	["capital_close.png", Vector2(-3.0, -13.5), 1.0],
	["capital_aqueduct.png", Vector2(22.0, -28.5), 0.75],
	# Polish 3: the map's edge as far as a player can pan each way at the mission's furthest zoom (an _edge_ shot's
	# camera is clamped as the mission's is, Mission.clamp_view()), and the river's west end running on into the band.
	["capital_edge_n.png", Vector2(0, -70), 0.5],
	["capital_edge_e.png", Vector2(70, 0), 0.5],
	["capital_edge_s.png", Vector2(0, 70), 0.5],
	["capital_edge_w.png", Vector2(-70, 0), 0.5],
	["capital_edge_river_w.png", Vector2(-70, 9), 0.6],
	# The Keep's grounds with the watchtower on its wall line, the drill yard's two rows of dummies, the avenues of the
	# old and the new town, a house block close-up per district, the south suburbs, gallows hill and the tournament field.
	["capital_keep.png", Vector2(3.0, -23.5), 1.0],
	["capital_drill.png", Vector2(-11.5, -24.8), 1.3],
	["capital_avenue_old.png", Vector2(-6.0, -9.5), 0.8],
	["capital_avenue_civic.png", Vector2(5.0, -15.0), 0.9],
	["capital_avenue_new.png", Vector2(-6.0, 21.0), 0.8],
	["capital_houses_noble.png", Vector2(-15.0, -15.5), 1.0],
	["capital_houses_guild.png", Vector2(12.5, -14.0), 1.0],
	["capital_houses_market.png", Vector2(-18.0, -4.0), 1.0],
	["capital_houses_oldtown.png", Vector2(5.0, -3.0), 1.0],
	["capital_houses_crafts.png", Vector2(-23.0, 19.0), 1.0],
	["capital_houses_newtown.png", Vector2(-1.0, 19.5), 1.0],
	["capital_houses_tanners.png", Vector2(17.0, 17.0), 1.0],
	["capital_houses_poor.png", Vector2(-19.0, 28.0), 1.0],
	["capital_houses_road.png", Vector2(10.0, 28.0), 1.0],
	["capital_suburbs.png", Vector2(-14.0, 37.0), 0.7],
	["capital_tournament.png", Vector2(14.0, 37.0), 0.8],
	["capital_south_fields.png", Vector2(28.0, 34.0), 0.6],
	["town_citadel.png", TownLayout.CITADEL_ORIGIN, 1.0],
	["town_edge_n.png", Vector2(0, -70), 0.5],
	["town_edge_e.png", Vector2(70, 0), 0.5],
	["town_edge_s.png", Vector2(0, 70), 0.5],
	["town_edge_w.png", Vector2(-70, 0), 0.5],
	["town_market.png", Vector2(0.8, 2.0), 1.0],
	["town_crowd.png", Vector2(-4.0, 6.0), 0.8],
	["town_main_gate.png", Vector2(2.7, 16.0), 1.0],
	["town_side_gate.png", Vector2(16.0, 9.0), 1.0],
	["town_river_farms.png", Vector2(2.0, 24.0), 0.5],
	["town_windmill.png", Vector2(-10.0, -24.0), 1.0],
	["town_watermill.png", Vector2(-4.0, 24.5), 1.0],
	["town_pasture_east.png", Vector2(21.5, 4.0), 1.0],
	["town_fountain.png", Vector2(0.8, 5.7), 1.6],
	["town_well.png", Vector2(-13.85, 1.85), 1.6],
	["town_bell_tower.png", Vector2(7.55, 1.35), 1.3],
	["town_corner_south.png", Vector2(16.0, 16.0), 1.0],
	["town_corner_east.png", Vector2(16.0, -16.0), 1.0],
	# The west branch's source: the cliff, its waterfall and the pool below (the overview's north-west bend).
	["town_waterfall.png", Vector2(-27.6, -1.6), 1.6],
	["town_east_quarter.png", Vector2(12.4, 0.6), 1.4],
	# The market's north torches and the walkway lamp; the west street's lamps beside a market corner torch.
	["town_torches.png", Vector2(1.4, -2.6), 2.2],
	["town_lamps.png", Vector2(-6.0, 8.6), 2.2],
	# The GPT showcase district (GptShowcase): all of it, then each category's row (Vector2.INF: framed on the row's
	# sprites, GptShowcase.shot_frame, the zoom fitting them, at most this one). Later batches add their rows' shots here.
	["showcase_overview.png", Vector2.INF, 0.6],
	["showcase_overview_2.png", Vector2.INF, 0.6],
	["showcase_overview_3.png", Vector2.INF, 0.6],
	["showcase_overview_4.png", Vector2.INF, 0.6],
	["showcase_housing.png", Vector2.INF, 1.6],
	["showcase_faith.png", Vector2.INF, 1.6],
	["showcase_trade.png", Vector2.INF, 1.6],
	["showcase_food.png", Vector2.INF, 1.6],
	["showcase_public.png", Vector2.INF, 1.6],
	["showcase_defence.png", Vector2.INF, 1.6],
	["showcase_crafts.png", Vector2.INF, 1.6],
	["showcase_civic_b.png", Vector2.INF, 1.6],
	["showcase_water.png", Vector2.INF, 1.6],
	["showcase_transport.png", Vector2.INF, 1.6],
	["showcase_defence_b.png", Vector2.INF, 1.6],
	["showcase_small.png", Vector2.INF, 1.6],
	# The forest ring outside the west wall, and the oaks between the west district's cottages.
	["town_forest.png", Vector2(-18.2, -4.0), 1.4],
	["town_oaks.png", Vector2(-10.0, 4.5), 1.6],
	# The north-west farm's barn and the carpenter's workshop (the warehouse sets), each then damaged and fallen.
	["town_barn.png", Vector2(-12.6, -28.4), 2.0],
	["town_carpenter.png", Vector2(11.2, 12.3), 1.6],
	["town_barn_damaged.png", Vector2(-12.6, -28.4), 2.0],
	["town_carpenter_damaged.png", Vector2(11.2, 12.3), 1.6],
	["town_barn_ruins.png", Vector2(-12.6, -28.4), 2.0],
	["town_carpenter_ruins.png", Vector2(11.2, 12.3), 1.6],
	# The mills (batch 3 sets), damaged and fallen (town_windmill / town_watermill above show them whole).
	["town_windmill_damaged.png", Vector2(-10.0, -24.0), 1.0],
	["town_watermill_damaged.png", Vector2(-4.0, 24.5), 1.0],
	["town_windmill_ruins.png", Vector2(-10.0, -24.0), 1.0],
	["town_watermill_ruins.png", Vector2(-4.0, 24.5), 1.0],
	# The farm fields (batch 3 sets) with farmers set down in them: the north fields by the windmill, the south wheat by
	# the river, the south-east cabbages; then the north fields trampled (below 65% health) and burnt flat.
	["town_fields_north.png", Vector2(-16.0, -25.0), 1.2],
	["town_fields_south.png", Vector2(-16.5, 28.0), 1.2],
	["town_fields_cabbage.png", Vector2(10.0, 28.0), 1.2],
	["town_fields_damaged.png", Vector2(-16.0, -25.0), 1.2],
	["town_fields_ruins.png", Vector2(-16.0, -25.0), 1.2],
	# The south road's stone bridge and the dock below the postern, people on them (_stage_shot); then cracked and
	# fallen (kept last: they break the bridge and the dock for any shot after them).
	["town_bridge.png", Vector2(2.7, 22.2), 1.3],
	["town_dock.png", Vector2(-5.6, 20.0), 2.0],
	["town_bridge_damaged.png", Vector2(2.7, 22.2), 1.3],
	["town_dock_damaged.png", Vector2(-5.6, 20.0), 2.0],
	["town_bridge_ruins.png", Vector2(2.7, 22.2), 1.3],
	["town_dock_ruins.png", Vector2(-5.6, 20.0), 2.0],
]
## [time, power key, ground point] for --citadel-test.
const CITADEL_CASTS := [
	[0.5, "judgement", TownLayout.CITADEL_ORIGIN],
	[12.0, "cinder", TownLayout.CITADEL_ORIGIN + Vector2(-4.5, 0.9)],
	[22.0, "nova", TownLayout.CITADEL_ORIGIN],
	[30.0, "judgement", TownLayout.CITADEL_ORIGIN],
	[40.0, "nova", TownLayout.CITADEL_ORIGIN],
	[48.0, "orbital", TownLayout.CITADEL_ORIGIN],
]
const CITADEL_SHOTS := [0.3, 4.0, 9.5, 14.0, 18.0, 25.5, 33.0, 43.5, 52.0]
const CITADEL_TEST_END := 60.0
## [time, power key, ground point] for --crowd-test: enough violence to start a panic and a rally.
const CROWD_CASTS := [
	[1.0, "heaven", Vector2(-2.0, 3.0)],
	[8.0, "tornado", Vector2(3.0, 5.0)],
	[18.0, "cinder", Vector2(0.8, 1.0)],
]
const CROWD_SHOTS := [0.5, 3.0, 10.0, 16.0, 24.0, 34.0]
const CROWD_TEST_END := 40.0

var _bf: Battlefield
var _town: Town
var _grid: WalkGrid
var _crowd: Crowd
## The GPT showcase district (dev only), or null with --no-showcase, and the page of it shown.
var _showcase: GptShowcase
var _showcase_page := 1
var _selected := 0
var _pressing := false
var _press_ground := Vector2.ZERO
var _hud: Label
var _drag_line: Node2D
var _destroyed := 0
## Game-time seconds since the scene started (follows Engine.time_scale like the effects' clocks).
var _t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(CLEAR)
	_bf = Battlefield.new()
	_bf.name = "Battlefield"
	add_child(_bf)
	_bf.ctx.impact.dim_scale = 0.4
	_bf.ctx.env.structure_destroyed.connect(_on_structure_destroyed)
	_drag_line = Node2D.new()
	_drag_line.name = "DragLine"
	_drag_line.z_index = 5
	_drag_line.z_as_relative = false  # absolute z 5: above the world (0), below the overhead layer (8).
	_drag_line.draw.connect(_draw_drag_line)
	_bf.ground_plane.add_child(_drag_line)
	_hud = _bf.add_debug_label()
	var args := OS.get_cmdline_user_args()
	var scripted := "--capture-town" in args or "--citadel-test" in args or "--crowd-test" in args or "--bench" in args
	_rebuild(7 if scripted else Time.get_ticks_usec())
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(Vector2(0.8, 2.0)).round()
	await FxParts.prewarm(_bf.ctx.distort)
	if "--capture-town" in args:
		var frames := Battlefield.arg_value(args, "--frames")
		var dim := Battlefield.arg_value(args, "--dim")
		if dim != "":
			_bf.ctx.impact.dim(float(dim), 100.0)
		_capture_town(Battlefield.arg_value(args, "--only"), int(frames) if frames != "" else 1)
	elif "--citadel-test" in args:
		_citadel_test()
	elif "--crowd-test" in args:
		_crowd_test()
	elif "--bench" in args:
		_run_bench(Battlefield.arg_value(args, "--only"))


## Fresh town: clear the battlefield, build Aldermere and its Citadel, spawn the placeholder units.
func _rebuild(seed_value: int) -> void:
	_bf.reset(seed_value)
	_destroyed = 0
	if is_instance_valid(_town):
		_town.teardown()
		# Parents may be mid-teardown here, so never free a tree-resident town immediately.
		if _town.is_inside_tree():
			_town.queue_free()
		else:
			_town.free()
	if is_instance_valid(_crowd):
		_crowd.clear()
		if _crowd.is_inside_tree():
			_crowd.queue_free()
		else:
			_crowd.free()
	if is_instance_valid(_showcase):
		_showcase.teardown()
		_showcase.queue_free()
		_showcase = null
	var args := OS.get_cmdline_user_args()
	# The city to build: --city=<id>, Aldermere by default.
	var city := Battlefield.arg_value(args, "--city")
	City.use(StringName(city) if city != "" else &"aldermere")
	_bf.ctx.field.bounds = City.current().map()
	# The GPT showcase district is laid out round Aldermere's walls (TownLayout): Aldermere only.
	var showcase := GptShowcase.wanted(args) and City.current().id() == &"aldermere"
	_town = Town.new()
	_town.name = "Town"
	if showcase:
		_town.keep_clear = GptShowcase.clear_rects()
	add_child(_town)
	_town.build(_bf.ctx.env, _bf.ground_plane, _bf.camera)
	_town.sfx = _bf.ctx.sfx
	if showcase:
		# After the town: every town building keeps its seed; before the walk grid, which then walks round it.
		_showcase_page = GptShowcase.page_arg(args)
		_build_showcase()
	_grid = WalkGrid.new().setup(_bf.ctx.env, _town)
	_crowd = Crowd.new()
	_crowd.name = "Crowd"
	add_child(_crowd)
	_crowd.setup(_bf.ctx.field, _bf.ctx.env, _town, _grid, _bf.ctx.world, seed_value)
	var wanted := Battlefield.arg_value(OS.get_cmdline_user_args(), "--people")
	# The city's own numbers (CityDef.citizens(), soldiers(); Aldermere's PEOPLE), --people=N scaling both.
	var town_people := City.current().citizens() + City.current().soldiers()
	var people := int(wanted) if wanted != "" else town_people
	var citizens := roundi(float(people) * float(City.current().citizens()) / float(town_people))
	_crowd.spawn(citizens, people - citizens)


func _cast(power: Dictionary, ground: Vector2, extra := {}) -> FxTimeline:
	if power.is_empty():
		push_warning("Unknown power")
		return null
	if is_instance_valid(_crowd):
		_crowd.on_cast(ground)
	return FxTimeline.cast(load(power.path), _bf.ctx, ground, extra)


func _on_structure_destroyed(_s: Structure, _kind: StringName) -> void:
	_destroyed += 1


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var i := POWER_KEYS.find(event.physical_keycode)
		if i >= 0:
			_selected = i
		elif event.physical_keycode == KEY_R:
			_rebuild(Time.get_ticks_usec())
		elif event.physical_keycode == KEY_F9 and is_instance_valid(_showcase):
			_showcase.toggle_labels()
		elif event.physical_keycode == KEY_F10 and is_instance_valid(_showcase):
			_show_page(_showcase_page % GptShowcase.pages() + 1)
		elif event.physical_keycode == KEY_ESCAPE:
			_bf.quit()
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan(-event.relative / _bf.camera.zoom.x)
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var z := _bf.camera.zoom.x * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.1)
		_bf.camera.zoom = Vector2.ONE * clampf(z, ZOOM_MIN, ZOOM_MAX)
		_pan(Vector2.ZERO)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_ground = _bf.mouse_ground()
		elif _pressing:
			_pressing = false
			_drag_line.queue_redraw()
			var power: Dictionary = PowerBook.POWERS[_selected]
			var extra := {}
			if power.aim == "drag":
				var drag := _bf.mouse_ground() - _press_ground
				extra["dir"] = drag.normalized() if drag.length() >= DRAG_MIN else Vector2(1, 0)
			_cast(power, _press_ground, extra)


func _process(delta: float) -> void:
	_t += delta
	var pan := Battlefield.key_pan_dir()
	if pan != Vector2.ZERO:
		# Pan in real time regardless of hit-stop, faster when zoomed out.
		var real_delta := delta / maxf(Engine.time_scale, 0.001)
		_pan(pan.normalized() * PAN_SPEED * real_delta / _bf.camera.zoom.x)
	if _pressing:
		_drag_line.queue_redraw()
	_update_hud()


## Panned within PAN_MIN..PAN_MAX, the view kept on the drawn ground (TownFloor.keep_in_view(), polish 3).
func _pan(by: Vector2) -> void:
	_bf.camera.position = TownFloor.keep_in_view((_bf.camera.position + by).clamp(PAN_MIN, PAN_MAX), _bf.camera.zoom.x,
		get_viewport().get_visible_rect().size)


func _draw_drag_line() -> void:
	if not _pressing or PowerBook.POWERS[_selected].aim != "drag":
		return
	var col := Color(1, 0.35, 0.2, 0.9)
	_drag_line.draw_line(_press_ground, _bf.mouse_ground(), col, -1.0)
	_drag_line.draw_rect(Rect2(_press_ground - Vector2(0.08, 0.08), Vector2(0.16, 0.16)), col)


func _update_hud() -> void:
	if _town == null or not is_instance_valid(_town.citadel) or not is_instance_valid(_crowd):
		return
	var power: Dictionary = PowerBook.POWERS[_selected]
	var cit := _town.citadel
	var text := "KAK town debug   [%s] %s  (%s, %d DP)\nCitadel %d%%   parts %d/9   buildings down %d\nCitizens %d   soldiers %d   escaped %d   alarm %d%%\n1-9 0 - pick   LMB cast (drag: line powers)   WASD / middle-drag pan   wheel zoom   R rebuild   Esc quit" % [
		KEY_LABELS[_selected], power.name, power.aim, power.dp, roundi(cit.fraction() * 100.0), cit.standing_parts(),
		_destroyed, _crowd.alive_citizens(), _crowd.alive_soldiers(), _crowd.escaped_count, roundi(_crowd.alarm)]
	if _hud.text != text:
		_hud.text = text


# --- Scripted runs ---------------------------------------------------------

## The showcase district's page `_showcase_page`, built into the field (after the town).
func _build_showcase() -> void:
	_showcase = GptShowcase.new()
	_showcase.name = "GptShowcase"
	add_child(_showcase)
	_showcase.build(_bf.ctx.env, self, GptShowcase.state_arg(OS.get_cmdline_user_args()), _showcase_page)


## The showcase's page `page` instead of the one shown (its buildings taken out of the field, the other's put in; the
## walk grid keeps the first page's, which only matters to a citizen walking out into the meadow).
func _show_page(page: int) -> void:
	_showcase.teardown(_bf.ctx.env)
	_showcase.queue_free()
	_showcase_page = page
	_build_showcase()


## Every TOWN_SHOTS shot, or with `only` just the one whose file name starts with it (e.g. town_overview). With
## `frames` above 1, each shot is saved that many times a quarter of a second apart (name_0.png, name_1.png...), to
## show what moves.
func _capture_town(only := "", frames := 1) -> void:
	_hud.visible = false
	for shot in TOWN_SHOTS:
		if only != "" and not String(shot[0]).begins_with(only):
			continue
		var at: Vector2 = shot[1]
		if not at.is_finite():
			var row := String(shot[0]).trim_prefix("showcase_").trim_suffix(".png")
			if is_instance_valid(_showcase) and GptShowcase.shot_page(row) != _showcase_page:
				_show_page(GptShowcase.shot_page(row))
				await _bf.wait_frames(10)
			var frame := GptShowcase.shot_frame(row)
			var vp := get_viewport().get_visible_rect().size
			_bf.camera.zoom = Vector2.ONE * minf(float(shot[2]), minf(vp.x / (frame.size.x + 60.0),
				vp.y / (frame.size.y + 60.0)))
			_bf.camera.position = frame.get_center().round()
		else:
			_bf.camera.zoom = Vector2.ONE * float(shot[2])
			_bf.camera.position = (Iso.ground_to_screen(at) + Vector2(0, -30)).round()
			if String(shot[0]).contains("_edge_"):
				_bf.camera.position = Mission.clamp_view(Iso.ground_to_screen(at), float(shot[2]),
					get_viewport().get_visible_rect().size).round()
		await _stage_shot(String(shot[0]))
		await _bf.wait_frames(20)
		if frames <= 1:
			await _bf.save_capture(shot[0])
			continue
		for i in frames:
			await _bf.save_capture(String(shot[0]).replace(".png", "_%d.png" % i))
			await _bf.wait_frames(15)
	await _bf.quit()


## Dev staging for the bridge and dock shots: a few citizens set down along the bridge's road or on the dock's planks
## (they walk on from there), and for the _damaged / _ruins shots the structure cracked or brought down first.
func _stage_shot(file: String) -> void:
	var s: Structure = null
	if file.begins_with("town_fields"):
		await _stage_fields(file)
		return
	if file.begins_with("town_bridge"):
		s = _town.bridge
	elif file.begins_with("town_dock"):
		s = _town.dock
	elif file.begins_with("town_barn") or file.begins_with("town_carpenter") or file.begins_with("town_windmill") \
			or file.begins_with("town_watermill"):
		var plot: Rect2 = TownLayout.CARPENTER
		if file.begins_with("town_barn"):
			plot = TownLayout.BARNS[0]
		elif file.begins_with("town_windmill"):
			plot = TownLayout.WINDMILL
		elif file.begins_with("town_watermill"):
			plot = TownLayout.WATERMILL
		for b: Structure in _town._built:
			if is_instance_valid(b) and b.footprint == plot:
				s = b
				break
		if s != null and file.ends_with("_damaged.png"):
			s.crack()
		elif s != null and file.ends_with("_ruins.png"):
			s.destroy(s.center(), &"stone")
			await _bf.wait_frames(240)
		return
	if not is_instance_valid(s) or not is_instance_valid(_crowd):
		return
	var r := s.footprint
	var n := 6 if s == _town.bridge else 3
	for i in mini(n, _crowd.citizens.size()):
		var p: Person = _crowd.citizens[i]
		var k := (float(i) + 0.5) / float(n)
		p.ground_pos = r.position + r.size * (Vector2(0.5 + 0.25 * (float(i % 2) - 0.5), k) if r.size.y > r.size.x \
			else Vector2(k, 0.5))
		p._sync_position()
	if file.ends_with("_damaged.png"):
		s.crack()
	elif file.ends_with("_ruins.png"):
		s.destroy(s.center(), &"stone")
		await _bf.wait_frames(240)


## Dev staging for the field shots: the fields round the shot's point get two farmers each, set down among the crops
## (they walk on from there); _damaged drops them under 65% health (trampled), _ruins burns them flat.
func _stage_fields(file: String) -> void:
	var at: Vector2 = Vector2.ZERO
	for shot in TOWN_SHOTS:
		if shot[0] == file:
			at = shot[1]
	var fields: Array[Structure] = []
	for b: Structure in _town._built:
		if is_instance_valid(b) and b.kind == Structure.Kind.FARM_FIELD and b.footprint.get_center().distance_to(at) < 8.0:
			fields.append(b)
	var i := 0
	for f in fields:
		if file.ends_with("_damaged.png"):
			f.hp = f.max_hp * 0.5
			f.wake()
		elif file.ends_with("_ruins.png"):
			f.destroy(f.center(), &"stone")
		if not is_instance_valid(_crowd):
			continue
		for k in 2:
			if i >= _crowd.citizens.size():
				break
			var p: Person = _crowd.citizens[i]
			p.ground_pos = f.footprint.position + f.footprint.size * Vector2(0.3 + 0.4 * k, 0.45 + 0.2 * k)
			p._sync_position()
			i += 1
	if file.ends_with("_ruins.png"):
		await _bf.wait_frames(240)


## Scripted strikes on the Citadel: the titan's punches, a volcano beside it, then novas, the titan again and an
## orbital strike until it falls. Logs its health every second and at each collapse, and captures key moments.
func _citadel_test() -> void:
	var cit := _town.citadel
	cit.part_collapsed.connect(_log_part)
	_bf.camera.zoom = Vector2.ONE * 0.8
	_bf.camera.position = (Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN) + Vector2(0, -60)).round()
	await _bf.wait_frames(10)
	_t = 0.0
	var casts := CITADEL_CASTS.duplicate()
	var shots := CITADEL_SHOTS.duplicate()
	var next_log := 0.0
	var fall_time := -1.0
	while _t < CITADEL_TEST_END:
		while not casts.is_empty() and _t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			print("CAST %s t=%.2f" % [c[1], _t])
			_cast(PowerBook.get_power(c[1]), c[2])
		if not shots.is_empty() and _t >= float(shots[0]):
			await _bf.save_capture("citadel_%05d.png" % int(float(shots.pop_front()) * 1000.0))
		if _t >= next_log:
			next_log += 1.0
			print("CITADEL t=%.1f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])
		if cit.is_fallen() and fall_time < 0.0:
			fall_time = _t
			print("CITADEL FALLEN t=%.2f" % _t)
		if fall_time >= 0.0 and _t >= fall_time + 3.0:
			await _bf.save_capture("citadel_fallen.png")
			break
		await get_tree().process_frame
	print("CITADEL result fallen=%s frac=%.2f standing=%d t=%.1f" % [cit.is_fallen(), cit.fraction(), cit.standing_parts(), _t])
	await _bf.quit()


## Scripted run for the people: a few casts in the streets, then a log of what the crowd does — how many are
## alive, fleeing, queueing and escaped, and what the alarm is doing.
func _crowd_test() -> void:
	_bf.camera.zoom = Vector2.ONE * 0.6
	_bf.camera.position = (Iso.ground_to_screen(Vector2(0.8, 3.0)) + Vector2(0, -30)).round()
	await _bf.wait_frames(10)
	_t = 0.0
	var casts := CROWD_CASTS.duplicate()
	var shots := CROWD_SHOTS.duplicate()
	var next_log := 0.0
	var gates_shot := false
	while _t < CROWD_TEST_END:
		while not casts.is_empty() and _t >= float(casts[0][0]):
			var c: Array = casts.pop_front()
			print("CAST %s t=%.1f" % [c[1], _t])
			_cast(PowerBook.get_power(c[1]), c[2])
		if not shots.is_empty() and _t >= float(shots[0]):
			await _bf.save_capture("crowd_%05d.png" % int(float(shots.pop_front()) * 1000.0))
		# Close on each gate for its waiting crowd (milestone 6): these are the frames the user judges the
		# queue by, taken once mid-run while there is still a crowd to see -- by the end of the run everyone
		# who was ever going to escape already has, and the gates stand empty.
		if not gates_shot and _t >= 18.0:
			gates_shot = true
			var saved_zoom := _bf.camera.zoom
			var saved_position := _bf.camera.position
			for i in _town.gates.size():
				var g: Structure = _town.gates[i]
				_bf.camera.zoom = Vector2.ONE * 1.2
				_bf.camera.position = Iso.ground_to_screen(g.center() - g.center().normalized() * 3.2).round()
				await _bf.wait_frames(3)
				await _bf.save_capture("crowd_gate_%d.png" % i)
			_bf.camera.zoom = saved_zoom
			_bf.camera.position = saved_position
		if _t >= next_log:
			next_log += 1.0
			var fleeing := 0
			var waiting := 0
			for p in _crowd.citizens:
				if not is_instance_valid(p) or not p.is_alive():
					continue
				if p.mind == Person.Mind.FLEE:
					fleeing += 1
				if p.queue_spot != Vector2.INF:
					waiting += 1
			print("CROWD t=%.1f citizens=%d soldiers=%d fleeing=%d queued=%d escaped=%d alarm=%d rallied=%s" % [
				_t, _crowd.alive_citizens(), _crowd.alive_soldiers(), fleeing, waiting, _crowd.escaped_count,
				roundi(_crowd.alarm), _crowd.soldiers.size() > 0 and is_instance_valid(_crowd.soldiers[0]) \
					and _crowd.soldiers[0].mind == Person.Mind.RALLY])
		await get_tree().process_frame
	print("CROWD result citizens=%d escaped=%d alarm=%d" % [_crowd.alive_citizens(), _crowd.escaped_count, roundi(_crowd.alarm)])
	await _bf.quit()


func _log_part(_p: Structure) -> void:
	var cit := _town.citadel
	print("CITADEL part down t=%.2f frac=%.2f standing=%d" % [_t, cit.fraction(), cit.standing_parts()])


func _run_bench(only: String) -> void:
	_hud.visible = false
	_bf.camera.zoom = Vector2.ONE * 0.75
	_bf.camera.position = Iso.ground_to_screen(TownLayout.CITADEL_ORIGIN).round()
	await _bf.wait_frames(10)
	if only != "":
		_cast(PowerBook.get_power(only), TownLayout.CITADEL_ORIGIN + Vector2(-3.0, 2.0), {"dir": Vector2(1, 0)})
	await _bf.bench("town-" + (only if only != "" else "idle"))
	await _bf.quit()
