extends RefCounted
## Covered-outline (TagOutlines, 2026-11-17 "Option A"): who gets an outline -- a person the map tags, drawn, standing, with a world sprite
## drawn in front of them that meets their body -- in the tag's colour; never an untagged person, one in the open, one indoors, hidden or
## dead; the occluders' visibility-layer bits follow exactly the slots that hold them and are all given back. The pixels themselves (the
## outline only over the covered part, gone in the open) are checked windowed by tools/dev/outline_check.gd: a headless run draws nothing.

const RED := Color(0.7843, 0.2039, 0.1647)
const BLUE := Color(0.5608, 0.7216, 1.0)


static func run(t) -> void:
	await t.process_frame
	_unit(t)
	await _mission(t)


## A person standing at ground point `g`, drawn (as the people sprites draw a grown body) and kept still.
static func _person(world: Node2D, g: Vector2) -> Person:
	var p := Person.new()
	p.ground_pos = g
	p.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(p)
	p.position = Iso.ground_to_screen(g).round()
	p.drawn_src = Rect2(0, 0, 24, 24)
	p.drawn_dst = Rect2(-12, -21, 24, 24)
	p.drawn_upright = true
	return p


static func _house(world: Node2D, fp: Rect2) -> Structure:
	var s := Structure.new().setup(fp, 40.0, Structure.Kind.HOUSE, 1)
	s.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(s)
	return s


static func _ids(occ: Array[Dictionary]) -> Dictionary:
	var out := {}
	for it in occ:
		out[(it.node as Object).get_instance_id()] = it
	return out


static func _who(ol: TagOutlines) -> Array:
	return ol.outlined().map(func(e: Array) -> Person: return e[0])


static func _unit(t) -> void:
	var world := Node2D.new()
	world.name = "WorldLayer"
	world.y_sort_enabled = true
	t.root.add_child(world)
	var p := _person(world, Vector2(5, 5))  # feet at (0, 160)
	var front := _house(world, Rect2(5.2, 5.2, 1.5, 1.5))  # sorts at y 214, its box over the body
	var behind := _house(world, Rect2(3.0, 3.0, 1.5, 1.5))  # sorts at y 144: drawn before the body, though its box meets it
	var far := _house(world, Rect2(20.0, 5.0, 1.0, 1.0))
	var q := _person(world, Vector2(5.1, 5.1))  # untagged, just as hidden
	var r := _person(world, Vector2(14, 2))  # tagged, in the open
	var ol := TagOutlines.new()
	ol.world = world
	t.root.add_child(ol)
	var tags: Array[MapTag] = [MapTag.person(p, RED, "PATROL"), MapTag.person(r, BLUE, "WISH"), MapTag.person(Vector2(5, 5), RED, "SPOT"),
		MapTag.place(Vector2(5, 5), BLUE, "HOME")]

	var want := TagOutlines.wanted(tags)
	t.check(want.size() == 2 and want[0][0] == p and want[0][1] == RED and want[1][0] == r and want[1][1] == BLUE,
		"wanted(): the tagged people, each with its tag's colour; a spot and a place are no one (%s)" % [want])
	var occ := ol.occluders_of(p).map(func(it: Dictionary) -> Node: return it.node)
	t.check(front in occ and not behind in occ and not far in occ and not q in occ and not p in occ,
		"occluders_of(): the house in front that meets the body; not the one sorted behind, not the far one, never a person (%s)" % [occ])
	t.check(ol.occluders_of(r).is_empty(), "occluders_of(): a person in the open has none")

	ol.update(tags)
	t.check(_who(ol) == [p], "covered and tagged: outlined; tagged in the open, untagged behind the same house: not (%s)" % [_who(ol)])
	t.check(ol.outlined()[0][1] == RED and ol._slots[0].mat.get_shader_parameter("tag_color") == RED, "the outline takes its tag's colour")
	var bit := ol._slots[0].mask.bit
	t.check(front.visibility_layer & bit != 0 and behind.visibility_layer & bit == 0 and far.visibility_layer & bit == 0,
		"only the occluder carries the mask's bit (the mask renders just it)")
	t.check(world.visibility_layer & TagOutlines.ALL_BITS == TagOutlines.ALL_BITS and world.visibility_layer & 1 == 1,
		"its ancestors carry every mask bit and keep their own layer")
	var vp := ol._slots[0].mask.vp
	t.check(vp.canvas_cull_mask == bit and vp.world_2d == ol.world_vp.world_2d and ol.masks_on() == 1
		and ol._slots[0].mat.get_shader_parameter("mask") == vp.get_texture(),
		"its mask viewport shares the world, renders only its bit, and the copy reads it")
	t.check(ol._slots[0].copy.visible and ol._slots[0].copy.src == p.drawn_src and ol._slots[0].copy.dst == p.drawn_dst,
		"the copy traces the person's drawn frame")

	# Two tags on one person: the first one's colour (the mission's own tags come first).
	var two: Array[MapTag] = [MapTag.person(p, BLUE, "ACOLYTE"), MapTag.person(p, RED)]
	ol.update(two)
	t.check(ol.outlined().size() == 1 and ol.outlined()[0][1] == BLUE, "one outline a person, in its first tag's colour")

	# Indoors, hidden, faded, dead or not standing: no outline, and the bit is given back.
	var cases := {
		"indoors": func(on: bool) -> void: p.inside = on,
		"hidden": func(on: bool) -> void: p.visible = not on,
		"faded out": func(on: bool) -> void: p.modulate.a = 0.0 if on else 1.0,
		"dead": func(on: bool) -> void: p.state = DummyEnemy.State.DEAD if on else DummyEnemy.State.WANDER,
		"hoisted": func(on: bool) -> void: p.drawn_upright = not on,
		"in the open (its occluder gone)": func(on: bool) -> void: front.visible = not on,
	}
	for k: String in cases:
		(cases[k] as Callable).call(true)
		ol.update(tags)
		t.check(ol.outlined().is_empty() and front.visibility_layer & TagOutlines.ALL_BITS == 0,
			"%s: no outline and no bit left on the occluder (%s)" % [k, _who(ol)])
		(cases[k] as Callable).call(false)
		ol.update(tags)
		t.check(_who(ol) == [p], "%s undone: outlined again" % k)

	# Masks are shared unless they would clash: a second covered person far off shares p's; one standing in front of p's house (which
	# meets its body) and behind a house of its own may not -- p's mask would hide it where it shows.
	var r_house := _house(world, Rect2(14.2, 2.2, 1.5, 1.5))
	ol.update(tags)
	t.check(_who(ol) == [p, r] and ol.masks_on() == 1 and ol._slots[1].mask == ol._slots[0].mask,
		"two covered people far apart: one mask between them (%d)" % ol.masks_on())
	r_house.visible = false
	var b := _person(world, Vector2(6.9, 6.9))  # feet at y 220.8: in front of p's house, whose box meets its body
	var b_house := _house(world, Rect2(7.2, 7.2, 1.5, 1.5))
	var with_b: Array[MapTag] = [MapTag.person(p, RED, "PATROL"), MapTag.person(b, BLUE, "WISH")]
	t.check(TagOutlines.clash({"ids": _ids(ol.occluders_of(p)), "body": ol.body_box(p)}, {"ids": _ids(ol.occluders_of(b)), "body": ol.body_box(b)}),
		"clash(): p's house meets b's body and is not in front of b")
	ol.update(with_b)
	t.check(_who(ol) == [p, b] and ol.masks_on() == 2 and ol._slots[0].mask != ol._slots[1].mask
		and front.visibility_layer & ol._slots[1].mask.bit == 0 and b_house.visibility_layer & ol._slots[1].mask.bit != 0,
		"clashing people: a mask each, b's without p's house (%d masks)" % ol.masks_on())
	ol.update(tags)
	t.check(ol.masks_on() == 1 and _who(ol) == [p] and _bit_faults(ol).is_empty(),
		"b untagged again: its mask stops and gives back every bit p's mask does not hold (%s)" % [_bit_faults(ol)])
	for n: Node in [b, b_house, r_house]:
		world.remove_child(n)
		n.free()

	# A higher z draws in front whatever its sort key: bunting strung over the street (Decor z 1) sorted before the body still covers it.
	front.visible = false
	var bunting := Decor.new().setup(Decor.Kind.BUNTING, Vector2(4.6, 4.6), Vector2(1.0, 0.0), 3)
	bunting.process_mode = Node.PROCESS_MODE_DISABLED
	world.add_child(bunting)
	t.check(bunting.position.y < p.position.y and ol.occluders_of(p).any(func(it: Dictionary) -> bool: return it.node == bunting),
		"a higher z (bunting) in front though it sorts before the body")
	world.remove_child(bunting)
	bunting.free()
	front.visible = true

	# The slot limit: more covered people than slots, the first SLOTS (tag order) are outlined.
	var many: Array[MapTag] = []
	var crowd: Array[Person] = []
	for i in TagOutlines.SLOTS + 2:
		var c := _person(world, Vector2(5.0 + 0.05 * i, 5.0))
		crowd.append(c)
		many.append(MapTag.pip(c, RED))
	ol.update(many)
	t.check(ol.outlined().size() == TagOutlines.SLOTS and _who(ol) == crowd.slice(0, TagOutlines.SLOTS),
		"at most SLOTS outlines, the first tags' (%d)" % ol.outlined().size())
	var none: Array[MapTag] = []
	ol.update(none)
	t.check(ol.outlined().is_empty() and front.visibility_layer & TagOutlines.ALL_BITS == 0, "no tags: no outline, no bit")

	# Leaving the tree gives every bit back (the occluders' and their ancestors').
	ol.update(tags)
	t.check(front.visibility_layer & TagOutlines.ALL_BITS != 0, "outlined again before the layer goes")
	t.root.remove_child(ol)
	t.check(front.visibility_layer & TagOutlines.ALL_BITS == 0 and world.visibility_layer & TagOutlines.ALL_BITS == 0
		and world.visibility_layer == 1, "the layer gone: no mask bit left anywhere")
	ol.free()
	t.root.remove_child(world)
	world.free()


## Lost Lamb at night, hosted (headless: nothing is drawn and frame_pre_draw never fires, so the test calls the layer's refresh() each frame;
## the people still draw their frames and the layer does its bookkeeping): every outline
## is a tagged person's, drawn, with an occluder in front, in its tag's colour; every covered tagged person (within SLOTS) has one; no
## untagged or indoor person ever does; the bits are exactly the slots'; hiding the HUD takes them all away.
static func _mission(t) -> void:
	var was := Settings.live_zoom_out
	Settings.live_zoom_out = Settings.ZOOM_OUT_FAR
	WorldView.test_host = true
	var wv := WorldView.new()
	t.root.add_child(wv)
	await t.process_frame
	City.use(&"aldermere")
	var m: Mission = load("res://scenes/mission.tscn").instantiate()
	m.autostart = false
	m.mission_id = "lost_lamb"
	m.board = true
	m.look_override = Town.Look.NIGHT
	wv.host(m)
	if not m.is_prewarmed:
		await m.prewarmed
	m.start(PackedStringArray(["heaven", "tsunami", "cinder", "nova"]), 7)
	m.skip_intro()
	await t.process_frame
	var ol := m._outlines
	t.check(ol != null and ol.is_inside_tree() and ol.layer == TagOutlines.LAYER and ol.world == m._bf.get_node("WorldLayer"),
		"the mission puts the outline layer on its battlefield")
	var faults := PackedStringArray()
	var outlined_n := 0
	var tagged_n := 0
	for z: float in [0.5, 0.85, 1.6]:
		m._bf.camera.zoom_to(z)
		for f in 40:
			await t.process_frame
			ol.refresh()  # what frame_pre_draw runs before each drawn frame (a headless run draws none, so never emits it)
			if f % 5 != 4:
				continue
			var tags := m._hud.all_tags()
			var want := TagOutlines.wanted(tags)
			var colour := {}
			for w: Array in want:
				colour[(w[0] as Person).get_instance_id()] = w[1]
			tagged_n += want.size()
			var got := {}
			for o: Array in ol.outlined():
				var p: Person = o[0]
				got[p.get_instance_id()] = true
				outlined_n += 1
				if not colour.has(p.get_instance_id()):
					faults.append("an untagged (or undrawn) person is outlined")
				elif colour[p.get_instance_id()] != o[1]:
					faults.append("an outline is not its tag's colour")
				if p.inside or not p.tag_drawn() or not p.is_alive():
					faults.append("an indoor, hidden or dead person is outlined")
				if ol.occluders_of(p).is_empty():
					faults.append("a person in the open is outlined")
			var n := 0
			for w: Array in want:
				if n >= TagOutlines.SLOTS:
					break
				if not ol.occluders_of(w[0]).is_empty():
					n += 1
					if not got.has((w[0] as Person).get_instance_id()):
						faults.append("a covered tagged person has no outline")
			faults.append_array(_bit_faults(ol))
	t.check(tagged_n > 0 and outlined_n > 0, "lost_lamb: tagged people were seen (%d) and some covered ones outlined (%d)" % [tagged_n, outlined_n])
	t.check(faults.is_empty(), "lost_lamb: every outline is a covered, drawn, tagged person's in its colour, every covered one has one, bits exact (%d faults: %s)" % [
		faults.size(), "; ".join(faults.slice(0, 4))])
	# Untagged people never: none of the crowd outside the tags.
	var tagged := {}
	for w: Array in TagOutlines.wanted(m._hud.all_tags()):
		tagged[(w[0] as Person).get_instance_id()] = true
	var stray := 0
	for o: Array in ol.outlined():
		if not tagged.has((o[0] as Person).get_instance_id()):
			stray += 1
	t.check(stray == 0, "no untagged person is outlined")
	# The interface hidden (the player's toggle): no outlines and no bits.
	m.set_ui_hidden(true)
	await t.process_frame
	ol.refresh()
	t.check(ol.outlined().is_empty() and _bit_faults(ol).is_empty() and _bits_left(ol) == 0, "the interface hidden: no outline, no bit")
	m.set_ui_hidden(false)
	await t.process_frame
	wv.get_parent().remove_child(wv)
	t.check(_bits_left(ol) == 0, "the mission gone: no mask bit left on the world")
	wv.free()
	await t.process_frame
	WorldView.test_host = false
	Settings.live_zoom_out = was


## Each index entry's mask bits are exactly the masks holding it.
static func _bit_faults(ol: TagOutlines) -> PackedStringArray:
	var out := PackedStringArray()
	for it: Dictionary in ol._items:
		for ci: Variant in it.items:
			if not is_instance_valid(ci):
				continue
			var want := 0
			for m in ol._masks:
				if m.occ.has((it.node as Object).get_instance_id()):
					want |= m.bit
			if ci.visibility_layer & TagOutlines.ALL_BITS != want:
				out.append("%s carries bits %x, its slots %x" % [ci.name, ci.visibility_layer & TagOutlines.ALL_BITS, want])
	return out


## Mask bits left on any occluder of the index.
static func _bits_left(ol: TagOutlines) -> int:
	var n := 0
	for it: Dictionary in ol._items:
		for ci: Variant in it.items:
			if is_instance_valid(ci) and ci.visibility_layer & TagOutlines.ALL_BITS != 0:
				n += 1
	return n
