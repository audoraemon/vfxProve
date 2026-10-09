extends RefCounted
## The ChatGPT sets painted with water at their quay (capital polish 1): the crane, the ferry landing, the dock
## warehouse, the wash house and the sluice. Their painted water is cut out of all three stills by the converter
## (gpt_convert.py cut_water, the strip's depth in the manifest as water_depth), and the capital stands each one over its
## real river or harbour basin: its water strip (BuildingTypes.OVER_WATER, the same depth) on the water, its quay's edge
## on the bank, the rest on dry ground. The river under them stays water to the walkers, they are not crossings, and
## the people who work at them stand on dry ground. The drawbridge has no river or moat gate to stand at and is dropped.

## The sets cut and stood over water.
const WET := [&"gpt_crane", &"gpt_ferry", &"gpt_sluice", &"gpt_warehouse", &"gpt_washhouse"]
## A painted-water px: a clear mid blue (gpt_convert.water_mask()'s test) on the plot's ground strip.
const STRIP_SLACK := 0.05


static func run(t) -> void:
	_table(t)
	_art(t)
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_placed(t, c)
	_dropped(t, c)
	_anchors(t, c)
	_town(t)
	City.use(&"aldermere")


## OVER_WATER names exactly the cut sets, each at its manifest's water_depth; no other set carries one.
static func _table(t) -> void:
	var keys: Array = []
	for k: StringName in BuildingTypes.OVER_WATER:
		keys.append(String(k))
	keys.sort()
	t.check(keys == ["gpt_crane", "gpt_ferry", "gpt_sluice", "gpt_warehouse", "gpt_washhouse"], "the over-water sets: the crane, ferry landing, sluice, dock warehouse and wash house (%s)" % [keys])
	var man := SpriteArt.manifest()
	for k: String in man:
		if not k.begins_with("gpt_"):
			continue
		var info := BuildingTypes.info(StringName(k))
		if StringName(k) in WET:
			t.check(info.over_water and is_equal_approx(float(info.water_depth), float(man[k].get("water_depth", -1.0))),
				"%s stands over water by its art's strip (%s, manifest %s)" % [k, info.get("water_depth"),
				man[k].get("water_depth")])
			t.check(float(info.water_depth) > 0.0 and float(info.water_depth) < CapitalPlots.SETS[StringName(k)][0].y,
				"%s's strip is part of its plot's depth" % k)
		else:
			t.check(not info.over_water and float(info.water_depth) == 0.0 and not man[k].has("water_depth"),
				"%s does not stand over water" % k)
	t.check(not BuildingTypes.over_water(&"") and not BuildingTypes.over_water(&"stone"), "nothing else is over water")


## Every still of every cut set has no painted water left on its plot's ground strip, and keeps pixels there (posts,
## piles, the pier, the raft, a quay's front) or on its dry part: the cut took the water only.
static func _art(t) -> void:
	var man := SpriteArt.manifest()
	for k: StringName in WET:
		var e: Dictionary = man[String(k)]
		var a := Vector2(e.anchor[0], e.anchor[1])
		var depth := float(e.water_depth)
		for state in ["intact", "damaged", "ruins"]:
			var img := Image.load_from_file(ProjectSettings.globalize_path(
				"res://assets/pixellab/buildings/%s/%s.png" % [k, state]))
			var wet := 0
			var kept := 0
			for y in img.get_height():
				for x in img.get_width():
					var px := img.get_pixel(x, y)
					if px.a8 == 0:
						continue
					var d := Vector2(x + 0.5, y + 0.5) - a
					var v := (d.y / 16.0 - d.x / 32.0) / 2.0
					var on_strip := v > -depth + STRIP_SLACK and v <= 0.1
					var blue := px.b8 > 120 and px.b8 - px.r8 > 60 and px.b8 > px.g8 + 10
					if on_strip and blue:
						wet += 1
					kept += 1
			t.check(wet == 0, "%s %s has no painted water left on its strip (%d px)" % [k, state, wet])
			t.check(kept > 200, "%s %s keeps its building (%d px)" % [k, state, kept])


static func _bank_of(c: CapitalCity, r: Rect2) -> float:
	for w: Rect2 in c.rivers():
		if absf(w.position.y - (r.end.y - BuildingTypes.info(_tag_at(c, r)).water_depth)) < 0.001:
			return w.position.y
	return INF


static func _tag_at(c: CapitalCity, r: Rect2) -> StringName:
	for d: Dictionary in c.structures():
		if d.rect == r:
			return d.tag
	return &""


## Each over-water plot: its strip lies wholly on the river or the basin, from a bank line (the water's north edge) to
## its front; its dry part lies wholly off the water. Unturned (the water side is the painting's front-left, south).
static func _placed(t, c: CapitalCity) -> void:
	var found := {}
	for d: Dictionary in c.structures():
		if d.role != CapitalPlots.ROLE or not BuildingTypes.over_water(d.tag):
			continue
		found[d.tag] = int(found.get(d.tag, 0)) + 1
		var r: Rect2 = d.rect
		var depth: float = BuildingTypes.info(d.tag).water_depth
		var strip := Rect2(r.position.x, r.end.y - depth, r.size.x, depth)
		var dry := Rect2(r.position, Vector2(r.size.x, r.size.y - depth))
		var on := 0.0
		var dry_wet := 0.0
		var bank := false
		for w: Rect2 in c.rivers():
			on += strip.intersection(w).get_area() if strip.intersects(w) else 0.0
			dry_wet += dry.intersection(w).get_area() if dry.intersects(w) else 0.0
			bank = bank or (absf(w.position.y - strip.position.y) < 0.001 and w.position.x <= r.position.x
				and w.end.x >= r.end.x)
		t.check(is_equal_approx(on, strip.get_area()) and dry_wet < 0.0001 and bank,
			"%s %s: its strip stands on the water from the bank, its dry part on land (on %.3f of %.3f, dry wet %.3f)"
			% [d.tag, r, on, strip.get_area(), dry_wet])
	for k: StringName in WET:
		t.check(found.has(k), "%s stands over the water in the capital" % k)
	t.check(found.get(&"gpt_warehouse", 0) == 3 and found.get(&"gpt_washhouse", 0) == 2,
		"three dock warehouses and two wash houses (%s)" % [found])


## The drawbridge: no gate of the capital faces open water (its river gates land the stone bridges), so it is not
## placed, and it is listed with the unused sets.
static func _dropped(t, c: CapitalCity) -> void:
	var placed := false
	for d: Dictionary in c.structures():
		placed = placed or d.tag == &"gpt_drawbridge"
	t.check(not placed and &"gpt_drawbridge" in CapitalPlots.UNUSED, "the drawbridge is not placed (unused)")


## The harbour's and the wash houses' working spots stand on dry ground, beside the set's dry part.
static func _anchors(t, c: CapitalCity) -> void:
	var a := c.anchors()
	var wet: Array = []
	for k: String in ["harbour", "wash"]:
		for g: Vector2 in a.get(k, []):
			for w: Rect2 in c.rivers():
				if w.grow(0.2).has_point(g):
					wet.append([k, g])
	t.check(wet.is_empty() and (a.get("wash", []) as Array).size() == 6, "the harbour and wash spots are on dry ground (%s)"
		% [wet])


## Through the real town and walk grid: the over-water sets are not crossings (Town.bridges is the three stone bridges);
## the water under each stays closed to walkers, standing or fallen; a walkable one's dry part is open.
static func _town(t) -> void:
	City.use(&"capital")
	var c := City.current() as CapitalCity
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var crossings: Array[Rect2] = []
	for b: Structure in town.bridges:
		crossings.append(b.footprint)
	var same := crossings.size() == CapitalCity.BRIDGES.size()
	for b: Rect2 in CapitalCity.BRIDGES:
		same = same and b in crossings
	t.check(same, "Town.bridges is the three stone bridges (%s)" % [crossings])
	var sets: Array[Structure] = []
	for s: Structure in env.structures():
		if s.role == CapitalPlots.ROLE and BuildingTypes.over_water(s.art_tag):
			sets.append(s)
	var open_water: Array = []
	var dry_shut: Array = []
	for s in sets:
		var r := s.footprint
		var depth: float = BuildingTypes.info(s.art_tag).water_depth
		var y := r.end.y - depth + 0.25
		while y < r.end.y:
			var x := r.position.x + 0.25
			while x < r.end.x:
				if grid.walkable(Vector2(x, y)):
					open_water.append([s.art_tag, Vector2(x, y)])
				x += 0.5
			y += 0.5
		if s.walkable and r.size.y - depth >= 0.5:
			var g := Vector2(r.get_center().x, r.position.y + 0.25)
			if not grid.walkable(g):
				dry_shut.append([s.art_tag, g])
	t.check(sets.size() >= 8 and open_water.is_empty(), "the water under the over-water sets stays closed (%d sets; open %s)"
		% [sets.size(), open_water.slice(0, 4)])
	t.check(dry_shut.is_empty(), "a walkable one's dry part is open ground (%s)" % [dry_shut])
	for s in sets:
		s.destroy(s.center(), &"nova")
	var after: Array = []
	for s in sets:
		var r := s.footprint
		var depth: float = BuildingTypes.info(s.art_tag).water_depth
		var g := Vector2(r.get_center().x, r.end.y - depth * 0.5)
		if depth >= 0.5 and grid.walkable(g):
			after.append([s.art_tag, g])
	t.check(after.is_empty(), "fallen, their water stays closed (%s)" % [after])
	town.free()
	City.use(&"aldermere")
