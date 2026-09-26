extends SceneTree
## Dev: writes the town's layout to captures/layout.json for tools/dev/match_layout.py -- every structure's rect,
## kind, role and art tag, the Citadel's parts and the fountains, as TownLayout lays them out.
## Usage: godot --headless --path . -s tools/dev/dump_layout.gd


func _init() -> void:
	var items: Array = []
	for d in TownLayout.structures():
		var r: Rect2 = d.rect
		items.append({"rect": [r.position.x, r.position.y, r.size.x, r.size.y], "kind": Structure.Kind.keys()[d.kind],
			"role": String(d.role), "tag": String(d.tag)})
	for r: Rect2 in Citadel.TOWERS + Citadel.WALLS + [Citadel.KEEP]:
		var g := Rect2(r.position + TownLayout.CITADEL_ORIGIN, r.size)
		items.append({"rect": [g.position.x, g.position.y, g.size.x, g.size.y], "kind": "KEEP", "role": "citadel", "tag": ""})
	for r: Rect2 in TownLayout.FOUNTAINS:
		items.append({"rect": [r.position.x, r.position.y, r.size.x, r.size.y], "kind": "FOUNTAIN", "role": "decor", "tag": ""})
	var out := {"structures": items, "citadel": [TownLayout.CITADEL_ORIGIN.x, TownLayout.CITADEL_ORIGIN.y],
		"town": [TownLayout.TOWN.position.x, TownLayout.TOWN.position.y, TownLayout.TOWN.size.x, TownLayout.TOWN.size.y]}
	var dir := ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("layout.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("layout: %d structures" % items.size())
	quit()
