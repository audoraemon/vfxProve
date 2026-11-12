extends RefCounted
## Remembrance wired into Game (Skill Tree wheel, Task 5): the two routes, the god's file left byte for byte alone, Leave returning to the
## same Authority and power, and the Remembrance pause (Resume and Leave only).

const BASE := "user://test_remembrance_game_"
const FILE := "user://test_remembrance_game_1.cfg"
const SAVE := "user://test_remembrance_game_save.cfg"
const SETTINGS := "user://test_remembrance_game_settings.cfg"


static func run(t) -> void:
	_clear()
	_routes(t)
	await _remembrance_leaves_save_alone(t)
	await _leave_returns_to_selection(t)
	await _back_during_fade(t)
	await _casts_through_targeting(t)
	await _tree_state_kept(t)
	_clear()


static func _clear() -> void:
	City.use(&"aldermere")  # the memory is the Capital's
	for f in [FILE, SAVE, SETTINGS]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	GodTree.dev_fill = false


static func _routes(t) -> void:
	t.check(Game.next_screen("tree:remember") == Game.Screen.MISSION and Game.next_screen("pause:leave_memory") == Game.Screen.TREE,
		"tree:remember leads to the mission and pause:leave_memory to the tree")
	t.check(Game.next_screen("tree:back") == Game.Screen.HUB, "the tree's own Back still goes to the hub")


## A Game on the Endless god, in the tree, the files its own.
static func _game(t, god: GodSlot) -> Game:
	GodTree.dev_fill = true
	var game: Game = load("res://scenes/game.tscn").instantiate()
	game.save_path = SAVE
	game.settings_path = SETTINGS
	game.god_base = BASE
	game.god_slot = 1
	t.root.add_child(game)
	await t.process_frame
	game.god = god  # _ready() opens the title, which puts the god down
	game.go_to(Game.Screen.TREE)
	return game


static func _in_memory(game: Game) -> bool:
	return game.screen == Game.Screen.MISSION and is_instance_valid(game._mission) and game._mission.started()


static func _bytes(file: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(file)


static func _remembrance_leaves_save_alone(t) -> void:
	var god := GodSlot.make(1, "ruin", 4242)
	god.level = 4
	god.points = 0
	god.night = 5
	god.last_mission = MissionBook.WARNING
	god.learned = {"smite": 2}
	t.check(Game.write_god(god, FILE) == "", "the test god is written")
	var before := _bytes(FILE)
	var night := god.night
	var learned := god.learned.duplicate()
	var game := await _game(t, god)
	var tree: SkillTreeScreen = game._screen_node
	tree.select(1, 3, 0)
	var key := tree.selected_key()
	t.check(key != "" and god.level_of(key) == 0, "a Tier 3 power the god cannot buy is selected (%s)" % key)
	tree.action.emit("remember")
	await game._until(func() -> bool: return _in_memory(game), 30.0)
	t.check(_in_memory(game) and game._mission.remembrance == key and game._remembering == key, "Remember opens the memory of %s" % key)
	t.check(game._mission._aim.slot == 0, "and focuses its one slot (keys 1-5 are the level picker's)")
	var refusals := []
	for i in 3:
		await game._until(func() -> bool: return game._mission.rules().refusal(0) != "busy", 10.0)  # a cast in flight holds the next
		refusals.append(game._mission.rules().refusal(0))
		game._mission.rules().cast(0, CapitalCity.MARKET_SQUARE.get_center())
	t.check(refusals == ["", "", ""], "three free casts, none refused (%s)" % [refusals])
	var first_id := game._mission.get_instance_id()
	var first: Mission = game._mission
	first._memory.press(KEY_4)
	t.check(game._memory_level == 4, "a level pick keeps Game's level in step (%d)" % game._memory_level)
	Engine.time_scale = 0.2  # a hit's dip, as the toggle finds it
	first._memory.press(KEY_N)
	t.check(Engine.time_scale == 1.0, "the toggle restores Engine.time_scale (%f)" % Engine.time_scale)
	await t.process_frame
	await t.process_frame
	t.check(not is_instance_valid(first), "the old mission is freed after the toggle")
	await game._until(func() -> bool: return _in_memory(game) and game._mission.get_instance_id() != first_id, 30.0)
	t.check(game._mission.get_instance_id() != first_id and game._mission.memory_night and game._mission.remembrance == key and game._mission.rules().level_of(0) == 4, "N rebuilds the memory at night, the same power")
	game._mission._memory.press(KEY_5)
	t.check(game._mission.rules().level_of(0) == 5, "key 5 picks level 5")
	game._open_pause()
	t.check(is_instance_valid(game._pause) and game._pause.actions() == PackedStringArray(["resume", "leave_memory"]),
		"the Remembrance pause offers exactly Resume and Leave (%s)" % [game._pause.actions() if is_instance_valid(game._pause) else "-"])
	game._pause.action.emit("leave_memory")
	t.check(game.screen == Game.Screen.TREE and game._remembering == "" and not is_instance_valid(game._mission),
		"Leave returns to the tree and clears the memory")
	t.check(_bytes(FILE) == before, "the god's file is byte for byte what it was")
	t.check(game.god.in_night == "" and game.god.night == night and game.god.learned == learned,
		"no night in progress, the night count and the learned levels unchanged")
	game.queue_free()
	await t.process_frame
	_clear()


static func _leave_returns_to_selection(t) -> void:
	var god := GodSlot.make(1, "ruin", 77)
	god.level = 10
	god.learned = {"smite": 3}
	var game := await _game(t, god)
	var tree: SkillTreeScreen = game._screen_node
	tree.centre(2)
	tree.select(2, 1, 1)
	var want := tree.state()
	var key := tree.selected_key()
	tree.action.emit("remember")
	await game._until(func() -> bool: return _in_memory(game), 30.0)
	await game._until(func() -> bool: return not game._fading, 10.0)  # screen actions wait out the fade
	game._open_pause()
	game._pause.action.emit("leave_memory")
	var back: SkillTreeScreen = game._screen_node
	t.check(game.screen == Game.Screen.TREE and back != tree and back.state() == want and back.selected_key() == key,
		"Leave opens the tree on the same Authority and power (%s vs %s)" % [back.state(), want])
	back.action.emit("back")
	t.check(game.screen == Game.Screen.HUB, "and the tree's Back still goes to the hub")
	game.queue_free()
	await t.process_frame
	_clear()


## Esc or BACK in the 0.25 s fade into the memory must not turn it into a real night.
static func _back_during_fade(t) -> void:
	var god := GodSlot.make(1, "ruin", 31)
	god.level = 6
	god.night = 2
	t.check(Game.write_god(god, FILE) == "", "the fade test god is written")
	var before := _bytes(FILE)
	var game := await _game(t, god)
	var tree: SkillTreeScreen = game._screen_node
	tree.action.emit("remember")
	tree.action.emit("back")
	t.check(game._remembering != "" and game.screen == Game.Screen.TREE, "Back in the fade is dropped (%s)" % [Game.Screen.keys()[game.screen]])
	await game._until(func() -> bool: return _in_memory(game), 30.0)
	t.check(_in_memory(game) and game._mission.remembrance != "" and game._remembering != "", "the screen ends in the memory, still remembering")
	t.check(game.god.in_night == "" and _bytes(FILE) == before, "no night began and the god's file is untouched")
	game.queue_free()
	await t.process_frame
	_clear()


static func _key_event(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


## A cast through Targeting (the way a player does it) leaves the slot focused, and a level-5 follow-up click works.
static func _casts_through_targeting(t) -> void:
	var god := GodSlot.make(1, "dominion", 55)
	god.level = 10
	var game := await _game(t, god)
	var tree: SkillTreeScreen = game._screen_node
	var found := false
	for col in tree.columns().size():
		for tier in range(1, GodTree.TIERS + 1):
			for i in GodTree.PER_TIER:
				if not found and tree.key_at(col, tier, i) == "wisp":
					tree.select(col, tier, i)
					found = true
	t.check(found, "the wisp has a spot on the wheel")
	tree.action.emit("remember")
	await game._until(func() -> bool: return _in_memory(game), 30.0)
	var m: Mission = game._mission
	var aim: Targeting = m._aim
	var at := CapitalCity.MARKET_SQUARE.get_center()
	m._memory.press(KEY_5)
	t.check(m.rules().level_of(0) == 5, "level 5 is picked")
	await game._until(func() -> bool: return m.rules().refusal(0) != "busy", 10.0)
	aim.press(at)
	aim.release(at)
	t.check(aim.slot == 0, "after a cast the slot is focused again")
	await game._until(func() -> bool: return m.rules().can_recast(0), 10.0)
	var recasts := [0]
	m.rules().recast_made.connect(func(_s: int, _k: String, _a: Vector2) -> void: recasts[0] += 1)
	aim.press(at)
	aim.release(at)
	t.check(recasts[0] == 1 and aim.slot == 0, "the second click sends the light and the slot stays focused (%d)" % recasts[0])
	await game._until(func() -> bool: return m.rules().refusal(0) != "busy" and not m.rules().can_recast(0), 30.0)
	aim.press(at)
	aim.release(at)
	t.check(aim.slot == 0, "a further cast through Targeting keeps the slot")
	m._memory._input(_key_event(KEY_1))  # the overlay takes the key before Mission's slot keys see it
	t.check(m.rules().level_of(0) == 1 and aim.slot == 0, "key 1 picks level 1 and does not unfocus (level %d)" % m.rules().level_of(0))
	# Esc with no aim in progress opens the pause at once; one half-placed aim is only cancelled.
	aim.placed = true
	m._unhandled_input(_key_event(KEY_ESCAPE))
	t.check(not is_instance_valid(game._pause) and not aim.placed, "Esc on a half-placed aim only cancels it")
	m._unhandled_input(_key_event(KEY_ESCAPE))
	t.check(is_instance_valid(game._pause), "the next Esc opens the Remembrance pause")
	game.queue_free()
	await t.process_frame
	_clear()


## The tree's centred Authority and selection are kept for the session, for this god only.
static func _tree_state_kept(t) -> void:
	var god := GodSlot.make(1, "ruin", 77)
	god.level = 10
	var game := await _game(t, god)
	var tree: SkillTreeScreen = game._screen_node
	var other := (tree.centred + 1) % tree.columns().size()
	tree.centre(other)
	tree.select(other, 1, 1)
	var want := tree.state()
	tree.action.emit("back")
	game.go_to(Game.Screen.TREE)
	var again: SkillTreeScreen = game._screen_node
	t.check(again.state() == want, "the hub -> tree round trip keeps the centre and the selection (%s vs %s)" % [again.state(), want])
	var fresh := GodSlot.make(2, "death", 78)
	fresh.level = 10
	game.god_slot = 2
	game.god = fresh
	game.go_to(Game.Screen.TREE)
	var second: SkillTreeScreen = game._screen_node
	t.check(second.centred == second.columns().find("death"), "another god opens on its own default (centred %d)" % second.centred)
	game.queue_free()
	await t.process_frame
	_clear()
