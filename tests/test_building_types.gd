extends RefCounted
## The capital's building types (Task 10, BuildingTypes): one data row per ChatGPT set (kind, hp, height, walkable,
## flat, burns, smokes), the single source CapitalPlots plots from. Checked on the real capital Town, built once: one
## placed structure per set takes its row's health, a hit damages it, a fall reaches its ruins, the burning sets catch
## fire and the rest do not, the smoking sets smoke from their art's chimney key, and the walkable sets are open
## ground on the walk grid.


static func run(t) -> void:
	_table(t)
	var c := City.by_id(&"capital") as CapitalCity
	if c == null:
		t.check(false, "the capital builds")
		return
	_plots_read_table(t, c)
	_street_props(t, c)
	_aldermere_untouched(t)
	_placed(t)
	City.use(&"aldermere")


## Every set has a row; the smoking sets are exactly the ones whose art has a chimney key; the walkable and flat sets
## are the ones the plan names; the props are in the table but never placed.
static func _table(t) -> void:
	var man := SpriteArt.manifest()
	var missing: Array = []
	var smoke_bad: Array = []
	var shape_bad: Array = []
	for k: String in man:
		if not k.begins_with("gpt_"):
			continue
		var info := BuildingTypes.info(StringName(k))
		if info.is_empty():
			missing.append(k)
			continue
		for key in ["kind", "hp", "height", "walkable", "flat", "burns", "smokes"]:
			if not info.has(key):
				shape_bad.append("%s.%s" % [k, key])
		if bool(info.get("smokes", false)) != man[k].has("chimney"):
			smoke_bad.append(k)
		if info.has("height") and not is_equal_approx(float(info.height), float(man[k].height)):
			shape_bad.append(k + " height")
		if info.has("hp") and float(info.hp) <= 0.0:
			shape_bad.append(k + " hp")
	t.check(missing.is_empty(), "every ChatGPT set has a building type (missing %s)" % [missing])
	t.check(shape_bad.is_empty(), "every type has kind, hp, height (the blockout's), walkable, flat, burns, smokes (%s)"
		% [shape_bad])
	t.check(smoke_bad.is_empty(), "the smoking types are exactly the sets with a chimney key (%s)" % [smoke_bad])
	t.check(BuildingTypes.info(&"gpt_nothing").is_empty() and BuildingTypes.info(&"").is_empty(),
		"an unknown tag has no type")
	var walk := []
	var flat := []
	for k: StringName in BuildingTypes.TYPES:
		if BuildingTypes.info(k).walkable:
			walk.append(String(k))
		if BuildingTypes.info(k).flat:
			flat.append(String(k))
	walk.sort()
	flat.sort()
	t.check(walk == ["gpt_districtgate", "gpt_ferry", "gpt_footbridge", "gpt_sluice", "gpt_vineyard"],
		"the walkable types: the bridges, ferry landing, sluice, district gate and vineyard (%s)" % [walk])
	t.check(flat == ["gpt_ferry", "gpt_footbridge", "gpt_sluice", "gpt_vineyard"],
		"the flat types: the bridges, ferry landing, sluice and vineyard (%s)" % [flat])
	t.check(not BuildingTypes.info(&"gpt_fishpond").walkable and not BuildingTypes.info(&"gpt_monument").walkable,
		"the fishpond's rim and the monument's plinth are not walked on")
	# Masonry with nothing to catch: the walls, towers, gates, stone water works, monuments and the graveyard.
	for k: StringName in [&"gpt_aqueduct", &"gpt_barbican", &"gpt_watchtower", &"gpt_districtgate", &"gpt_cistern",
			&"gpt_fishpond", &"gpt_monument", &"gpt_milestone", &"gpt_waysidecross", &"gpt_graveyard", &"gpt_sluice"]:
		t.check(not BuildingTypes.info(k).burns, "%s does not burn" % k)
	for k: StringName in [&"gpt_inn", &"gpt_shacks", &"gpt_orchard", &"gpt_fishmarket", &"gpt_armoury", &"gpt_chapel"]:
		t.check(BuildingTypes.info(k).burns, "%s burns" % k)
	# The walkable kinds the engine knows stay walkable; data adds the district gate's paving only.
	for k: StringName in BuildingTypes.TYPES:
		var i := BuildingTypes.info(k)
		if int(i.kind) in Structure.WALKABLE:
			t.check(i.walkable, "%s of a walkable kind is walkable" % k)
		if int(i.kind) in Structure.FLAT:
			t.check(i.flat, "%s of a flat kind is flat" % k)


## CapitalPlots plots each set with its type's kind and height (the table is the single source).
static func _plots_read_table(t, c: CapitalCity) -> void:
	var bad := ""
	var n := 0
	for d: Dictionary in c.structures():
		if d.role != CapitalPlots.ROLE:
			continue
		n += 1
		var i := BuildingTypes.info(d.tag)
		if d.kind != int(i.kind) or not is_equal_approx(d.height, float(i.height)):
			bad = String(d.tag)
	t.check(n > 100 and bad == "", "every ChatGPT plot takes its type's kind and height (%d plots; bad %s)" % [n, bad])


## A street prop stands against a building front along its whole back edge: both ends and the middle (Task 8 review).
static func _street_props(t, c: CapitalCity) -> void:
	var backs: Array[Rect2] = []
	for d: Dictionary in c.structures():
		var walked: bool = d.kind in Structure.WALKABLE or (d.role == CapitalPlots.ROLE
			and bool(BuildingTypes.info(d.tag).get("walkable", false)))
		if not walked:
			backs.append(d.rect)
	backs.append_array(c.gardens())
	var bad := 0
	for p: Dictionary in c.street_props():
		var r: Rect2 = p.rect
		var ok := false
		# Whichever side the building is on, the three back samples PROP_BACK beyond it all lie in a building or garden.
		for away: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			var pts: Array[Vector2] = []
			if away.x != 0.0:
				var x := r.end.x if away.x > 0.0 else r.position.x
				pts = [Vector2(x, r.position.y + 0.05), Vector2(x, r.get_center().y), Vector2(x, r.end.y - 0.05)]
			else:
				var y := r.end.y if away.y > 0.0 else r.position.y
				pts = [Vector2(r.position.x + 0.05, y), Vector2(r.get_center().x, y), Vector2(r.end.x - 0.05, y)]
			var all := true
			for g in pts:
				var hit := false
				for b in backs:
					hit = hit or b.has_point(g + away * CapitalCity.PROP_BACK)
				all = all and hit
			ok = ok or all
		if not ok:
			bad += 1
	t.check(not c.street_props().is_empty() and bad == 0,
		"every street prop has a building behind both ends and its middle (%d of %d not)" % [bad, c.street_props().size()])


## Aldermere has no ChatGPT plots, so no structure of it reads the table: its kinds keep their health and walkability.
static func _aldermere_untouched(t) -> void:
	City.use(&"aldermere")
	var any := false
	for d: Dictionary in City.current().structures():
		any = any or d.role == CapitalPlots.ROLE
	t.check(not any, "Aldermere has no ChatGPT plots")
	var s := Structure.new().setup(Rect2(0, 0, 1, 1), 20.0, Structure.Kind.HOUSE, 1, &"house", &"gpt_manor")
	t.check(is_equal_approx(s.max_hp, 50.0), "a house that is not a ChatGPT plot keeps its kind's health")
	t.check(FireManager.burns(s), "an Aldermere house burns")
	s.free()
	var k := Structure.new().setup(Rect2(0, 0, 1, 1), 20.0, Structure.Kind.KEEP, 1, &"tower")
	t.check(not FireManager.burns(k) and not k.walkable, "an Aldermere tower neither burns nor is walked through")
	k.free()


## The real capital Town, built once: one placed structure per set.
static func _placed(t) -> void:
	City.use(&"capital")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var one := {}
	for s in env.structures():
		if String(s.art_tag).begins_with("gpt_") and not one.has(s.art_tag):
			one[s.art_tag] = s
	var placed := CapitalPlots.plotted_sets().size()
	t.check(one.size() == placed, "one placed structure for each of the %d placed sets (%d)" % [placed, one.size()])
	var smokers: Array[Structure] = town.smoke._houses if is_instance_valid(town.smoke) else ([] as Array[Structure])
	var fires := FireManager.new()
	var tags: Array = one.keys()
	tags.sort()
	var bad := {"hp": [], "walk": [], "flat": [], "grid": [], "smoke": [], "tip": [], "fire": [], "hit": [],
		"damaged": [], "ruins": []}
	# Standing checks first, on the untouched town.
	for tag: StringName in tags:
		var s: Structure = one[tag]
		var i := BuildingTypes.info(tag)
		if not is_equal_approx(s.max_hp, float(i.hp)) or not is_equal_approx(s.hp, float(i.hp)):
			bad.hp.append(tag)
		if s.walkable != bool(i.walkable):
			bad.walk.append(tag)
		if (s.z_index == -1) != bool(i.flat):
			bad.flat.append(tag)
		if bool(i.walkable):
			# Every walk-grid cell whose centre lies on it is open ground.
			var r := s.footprint
			var y := floorf(r.position.y / WalkGrid.CELL) * WalkGrid.CELL + WalkGrid.CELL * 0.5
			var open := true
			var cells := 0
			while y < r.end.y:
				var x := floorf(r.position.x / WalkGrid.CELL) * WalkGrid.CELL + WalkGrid.CELL * 0.5
				while x < r.end.x:
					if r.has_point(Vector2(x, y)):
						cells += 1
						open = open and grid.walkable(Vector2(x, y))
					x += WalkGrid.CELL
				y += WalkGrid.CELL
			if not open or cells == 0:
				bad.grid.append(tag)
		elif minf(s.footprint.size.x, s.footprint.size.y) >= 0.5 and grid.walkable(s.center()):
			bad.grid.append(tag)
		if smokers.has(s) != bool(i.smokes):
			bad.smoke.append(tag)
		if bool(i.smokes):
			var c: Vector2 = s.sprite.get("chimney", Vector2.INF)
			var at: Vector2 = s.sprite.get("anchor", Vector2.ZERO)
			if c == Vector2.INF or ChimneySmoke.tip_of(s) != c - at:
				bad.tip.append(tag)
		fires.ignite(s, 0.5)
		if fires.is_burning(s) != bool(i.burns) or FireManager.burns(s) != bool(i.burns):
			bad.fire.append(tag)
	t.check(bad.hp.is_empty(), "each placed set has its type's health (%s)" % [bad.hp])
	t.check(bad.walk.is_empty(), "each placed set is walkable as its type says (%s)" % [bad.walk])
	t.check(bad.flat.is_empty(), "each placed set lies flat as its type says (%s)" % [bad.flat])
	t.check(bad.grid.is_empty(), "the walkable sets are open on the walk grid, the solid ones closed (%s)" % [bad.grid])
	t.check(bad.smoke.is_empty(), "the smoking sets smoke, the rest do not (%s)" % [bad.smoke])
	t.check(bad.tip.is_empty(), "each smoking set smokes from its art's chimney key (%s)" % [bad.tip])
	t.check(bad.fire.is_empty(), "the burning sets catch fire, the rest do not (%s)" % [bad.fire])
	var smoking := 0
	for tag: StringName in tags:
		if BuildingTypes.info(tag).smokes:
			smoking += 1
	t.check(smoking >= 25, "a good share of the sets smoke (%d)" % smoking)
	# Then the damage: a hit, a crack, a fall.
	for tag: StringName in tags:
		var s: Structure = one[tag]
		s.damage(s.max_hp * 0.2, s.center(), &"stone")
		if s.destroyed or s.hp >= s.max_hp:
			bad.hit.append(tag)
		s.damage(s.max_hp * 0.3, s.center(), &"stone")
		var cracks := not s.kind in Structure.NO_CRACKS or s.kind == Structure.Kind.FARM_FIELD
		if cracks and s.sprite_state() != &"damaged":
			bad.damaged.append(tag)
		s.destroy(s.center(), &"stone")
		for k in 4:
			s._process(0.5)
		if not s.destroyed or s.sprite_state() != &"ruins" or not (s.sprite.get("stills", {}) as Dictionary).has(&"ruins"):
			bad.ruins.append("%s:%s" % [tag, s.sprite_state()])
	t.check(bad.hit.is_empty(), "a hit damages each set and leaves it standing (%s)" % [bad.hit])
	t.check(bad.damaged.is_empty(), "a hard-hit set shows its damaged still (%s)" % [bad.damaged])
	t.check(bad.ruins.is_empty(), "each set brought down reaches its ruins (%s)" % [bad.ruins])
	town.teardown()
	town.free()
	City.use(&"aldermere")
