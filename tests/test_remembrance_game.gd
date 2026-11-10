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
