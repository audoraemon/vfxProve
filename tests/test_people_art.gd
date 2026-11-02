extends RefCounted
## PeopleArt: which design a citizen or soldier wears, and where its frames sit in the people atlas.

const R := CitizenProfile.Role


static func run(t) -> void:
	_designs(t)
	_frames(t)
	_poses(t)
	_merged_looks(t)
	_cached_frames(t)
	_rows(t)
	_info_table(t)
	_getup(t)
	_mirror(t)
	_fallback(t)
	_pack(t)
	t.check(_crowd_run(true) == _crowd_run(false), "people sprites on or off, the crowd does exactly the same")
	SpriteArt.set_enabled(true)


## A person shows the animation for what it does, facing the way it last stepped.
static func _poses(t) -> void:
	SpriteArt.set_enabled(true)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var p := Person.new()
	p.rng.seed = 21
	p.bounds = TownLayout.MAP
	p.setup_person(false, Vector2(2.7, 2.0), grid)
	t.check(p._sprite_pose()[0] == &"idle", "a person standing shows idle")
	p.set_goal(Vector2(2.7, 12.0))
	var walked := 0
	var faced := 0
	for i in 120:
		var before := p.ground_pos
		p.tick(1.0 / 60.0)
		var d := p.ground_pos - before
		if d.length_squared() > 1e-10:
			walked += 1 if p._sprite_pose()[0] == &"walk" else 0
			var right := d.x - d.y > 0.0
			var back := d.x + d.y < 0.0
			var want: int = (PeopleArt.Facing.NE if right else PeopleArt.Facing.NW) if back \
				else (PeopleArt.Facing.SE if right else PeopleArt.Facing.SW)
			faced += 1 if p._sprite_pose()[1] == want or absf(d.x - d.y) < 1e-6 or absf(d.x + d.y) < 1e-6 else 0
	t.check(walked > 60 and walked == faced, "walking, it shows walk facing the way it steps (%d / %d)" % [faced, walked])
	p.panic(p.ground_pos + Vector2(0.0, -1.0))
	for i in 120:
		if not p.startled():
			break
		p.tick(1.0 / 60.0)  # v0.11.2: frozen in fright first
	var ran := 0
	var fled := 0
	for i in 60:
		p.tick(1.0 / 60.0)
		# A runner can trip: on one knee it shows the stumble, not the run.
		if p._stride and p.is_running() and p._stumble <= 0.0:
			fled += 1
			ran += 1 if p._sprite_pose()[0] == &"run" else 0
	t.check(fled > 10 and ran == fled, "a frightened person runs (%d of %d steps)" % [ran, fled])
	p._stumble = 0.3
	t.check(p._sprite_pose()[0] == &"stumble", "a stumble shows on one knee")
	p._stumble = 0.0
	p.die(&"nova", p.ground_pos + Vector2(1, 0))
	p.tick(1.0)
	var pose := p._sprite_pose()
	var last := PeopleArt.frame_count(p._design(), &"death", pose[1]) - 1
	t.check(pose[0] == &"death" and pose[2] == last, "dead, it falls and lies on its last death frame")
	var g := Person.new()
	g.rng.seed = 22
	g.bounds = TownLayout.MAP
	g.setup_person(true, Vector2(2.7, 2.0), grid)
	t.check(g._design() == "guard", "a soldier wears the guard's design")
	t.check(g._sprite_tint().a == 0.0, "an unhurt person is drawn untinted")
	g.flash(0.2)
	t.check(g._sprite_tint().a > 0.9, "a hit flashes its silhouette")
	p.free()
	g.free()


## A crowd through panic, blasts, a freeze and deaths, with people sprites on or off: everyone's state, as text.
static func _crowd_run(sprites: bool) -> String:
	SpriteArt.set_enabled(sprites)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var field := EnemyField.new()
	field.env = env
	field.bounds = TownLayout.MAP
	var world := Node2D.new()
	var crowd := Crowd.new().setup(field, env, town, grid, world, 5)
	crowd.spawn()
	var people: Array = crowd.citizens + crowd.soldiers
	for i in 240:
		if i == 30:
			for k in range(0, people.size(), 3):
				people[k].panic(people[k].ground_pos + Vector2(0.5, 0.5))
		if i == 90:
			for k in range(1, people.size(), 7):
				people[k].die(&"nova", people[k].ground_pos + Vector2(1, 0))
			for k in range(2, people.size(), 9):
				people[k].freeze(1.0)
		crowd.step_people(1.0 / 60.0)
		for p in people:
			# Whatever the drawing reads must change nothing.
			p._art_signature()
	var rows := PackedStringArray()
	for p in people:
		rows.append("%s %d %d %d %.3f %.3f" % [p.ground_pos, p.mind, p.state, p.rng.state, p._stumble, p.sick_left])
	world.free()
	return "\n".join(rows)


## Every role and corps maps to a design the atlas has; only the two-look roles use the second look.
static func _designs(t) -> void:
	t.check(PeopleArt.ready(), "the people atlas and manifest load")
	for role in R.values():
		for look in [0.1, 0.9]:
			var d := PeopleArt.design_for(false, role, 0, look)
			t.check(PeopleArt.has(d), "citizen role %s (look %.1f) wears '%s', which the atlas has" % [R.keys()[role], look, d])
	for corps in Person.Corps.values():
		var d := PeopleArt.design_for(true, 0, corps, 0.5)
		t.check(PeopleArt.has(d), "corps %s wears '%s'" % [Person.Corps.keys()[corps], d])
	t.check(PeopleArt.CITIZEN[R.CLERGY].size() == 1 and PeopleArt.CITIZEN[R.RESIDENT].size() == 2,
		"residents have two looks, the clergy one")
	var a := PeopleArt.wanted(false, R.RESIDENT, 0, 0.1)
	var b := PeopleArt.wanted(false, R.RESIDENT, 0, 0.9)
	var c := PeopleArt.wanted(false, R.CLERGY, 0, 0.9)
	t.check(a == "resident_a" and b == "resident_b" and c == "clergy", "the look picks between a role's two designs")


## Each frame is a cell inside the atlas, its silhouette in the silhouette block, and the feet inside the cell.
static func _frames(t) -> void:
	var atlas := PeopleArt.atlas()
	var size := Vector2(atlas.get_size())
	var w := PeopleArt.white_rect()
	t.check(atlas.get_image().get_pixelv(Vector2i(w.position)) == Color.WHITE, "the atlas has a white pixel for shadows")
	for d in ["resident_a", "guard"]:
		var foot := PeopleArt.foot(d)
		t.check(Rect2(Vector2.ZERO, PeopleArt.cell()).has_point(foot - Vector2(0, 1)), "%s's feet are inside its cell" % d)
		for anim in PeopleArt.ANIMS:
			for f in PeopleArt.Facing.values():
				var n := PeopleArt.frame_count(d, anim, f)
				t.check(n >= 1, "%s has %s frames facing %d" % [d, anim, f])
				var last := PeopleArt.frame_rect(d, anim, f, n - 1)
				var sil := PeopleArt.silhouette_rect(d, anim, f, n - 1)
				t.check(last.size == PeopleArt.cell() and Rect2(Vector2.ZERO, size).encloses(last)
					and Rect2(Vector2.ZERO, size).encloses(sil) and sil.position != last.position,
					"%s %s %d: the last frame and its silhouette are cells in the atlas" % [d, anim, f])
				t.check(PeopleArt.frame_rect(d, anim, f, n + 3) == PeopleArt.frame_rect(d, anim, f, (n + 3) % n),
					"%s %s frames wrap" % [d, anim])


## Develop-Main's looks on the sprites (v0.07.1 Pestilence, v0.08 watchman and Mind Whisper): the sick sprite takes its
## stage's colour as strongly as the procedural body does and redraws at each stage; the watchman wears a stand-in
## design, his lantern hangs beside the sprite, and a whisper or his running redraws him.
static func _merged_looks(t) -> void:
	SpriteArt.set_enabled(true)
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var p := Person.new()
	p.rng.seed = 23
	p.bounds = TownLayout.MAP
	p.setup_person(false, Vector2(2.7, 2.0), grid)
	var sig_well := p._art_signature()
	t.check(p._sprite_tint().a == 0.0, "a healthy sprite is untinted")
	p.infect(PlagueManager.PLAGUE_LIFE)
	var sigs := {}
	var tints_ok := true
	for stage in range(1, Person.SICK_STAGES + 1):
		# Just inside each stage's share of the sickness.
		p.sick_left = PlagueManager.PLAGUE_LIFE * (1.0 - (float(stage) - 0.5) / float(Person.SICK_STAGES))
		var want := Color(Person.SICK_COLORS[stage - 1], Person.SICK_CLOTH)
		tints_ok = tints_ok and p.sick_stage() == stage and p._sprite_tint().is_equal_approx(want)
		sigs[p._art_signature()] = true
	t.check(tints_ok, "a sick sprite takes each stage's colour, green to red, at SICK_CLOTH")
	t.check(sigs.size() == Person.SICK_STAGES and not sigs.has(sig_well), "and redraws at every stage")
	p.sick_left = 0.0
	var w := Person.new()
	w.rng.seed = 24
	w.bounds = TownLayout.MAP
	w.setup_person(false, Vector2(2.7, 2.0), grid)
	var prof := CitizenProfile.new()
	prof.role = R.WATCHMAN
	w.profile = prof
	t.check(PeopleArt.wanted(false, R.WATCHMAN, 0, 0.5) == "watchman", "the watchman has a design of his own to come")
	t.check(not PeopleArt.has("watchman") and w._design() == PeopleArt.STAND_INS["watchman"]
		and PeopleArt.has(w._design()), "until then he wears the bellkeeper's (%s)" % w._design())
	t.check(w._is_watchman() and not p._is_watchman(), "only the watchman carries a lantern")
	var cell := Rect2(-PeopleArt.foot(w._design()), PeopleArt.cell())
	w._facing = 1
	var right := w._sprite_lantern()
	w._facing = -1
	var left := w._sprite_lantern()
	t.check(right.x >= 3 and left.x == -right.x - 1 and right.y < -4 and right.y > -12
		and cell.has_point(Vector2(right)) and cell.has_point(Vector2(left) + Vector2(0, 2)),
		"his lantern hangs beside the sprite at hand height, mirrored by facing (%s / %s)" % [right, left])
	var sig_calm := w._art_signature()
	w.whisper(w.ground_pos + Vector2(0.0, 0.3), 3.0)
	t.check(w.mind == Person.Mind.WHISPERED and w._art_signature() != sig_calm, "a whisper redraws him with its eye")
	p.free()
	w.free()


## The per-frame shortcuts (perf, integrate): a design's cached frame table gives the manifest's numbers; a standing
## sprite person keeps its signature through an idle frame and changes it on the next, so it redraws at the idle
## animation's rate and not every frame; and the quiet signature is the full fold's own integer.
static func _cached_frames(t) -> void:
	SpriteArt.set_enabled(true)
	var same := true
	for d in ["resident_a", "guard", "bellkeeper"]:
		var info := PeopleArt.info(d)
		same = same and info[2] == PeopleArt.foot(d) and info[3] == PeopleArt.cell()
		for a in PeopleArt.ANIMS.size():
			for f in PeopleArt.Facing.values():
				var n := PeopleArt.frame_count(d, PeopleArt.ANIMS[a], f)
				same = same and info[4][a * 4 + f] == n
				for k in [0, n - 1, n + 2]:
					var off := Vector2((k % n) * info[3].x, (a * 4 + f) * info[3].y)
					same = same and (info[0] as Vector2) + off == PeopleArt.frame_rect(d, PeopleArt.ANIMS[a], f, k).position \
						and (info[1] as Vector2) + off == PeopleArt.silhouette_rect(d, PeopleArt.ANIMS[a], f, k).position
	t.check(same, "PeopleArt.info() holds the manifest's frames, silhouettes, foot, cell and frame counts")
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var p := Person.new()
	p.rng.seed = 25
	p.bounds = TownLayout.MAP
	p.setup_person(false, Vector2(2.7, 2.0), grid)
	var fps: float = PeopleArt.FPS[&"idle"]
	p._anim = 0.1 / fps
	var a0 := p._art_signature()
	p._anim = 0.9 / fps
	var a1 := p._art_signature()
	p._anim = 1.1 / fps
	var b := p._art_signature()
	t.check(p._sprite_pose()[0] == &"idle" and a0 == a1 and b != a0,
		"a standing person keeps its signature through an idle frame and changes it on the next")
	var quiet := p._art_signature()
	p._flash = 0.001  # takes the full fold, with a flash term that rounds to 0: the same picture
	t.check(p._art_signature() == quiet, "the quiet signature is the full fold's integer")
	p._flash = 0.0
	p.whisper(p.ground_pos + Vector2(0.0, 0.3), 3.0)
	quiet = p._art_signature()
	p._flash = 0.001
	t.check(p.mind == Person.Mind.WHISPERED and p._art_signature() == quiet, "whispered too")
	p.free()



## The atlas has nine animations (v0.12 people animations): idle walk run stumble death scream lurch swing getup.
static func _rows(t) -> void:
	t.check(PeopleArt.ANIMS.size() == 9, "people have nine animations")
	t.check(PeopleArt.FPS_AT.size() == 9 and PeopleArt.ONCE_AT.size() == 9, "each has an fps and a hold flag")
	var agree := true
	for a in PeopleArt.ANIMS.size():
		agree = agree and PeopleArt.FPS_AT[a] == PeopleArt.FPS[PeopleArt.ANIMS[a]] 			and PeopleArt.ONCE_AT[a] == PeopleArt.ONCE.has(PeopleArt.ANIMS[a])
	t.check(agree, "FPS_AT and ONCE_AT agree with FPS and ONCE")


## Every design's frame table holds 9 * 4 frame counts.
static func _info_table(t) -> void:
	var ok := true
	for d in PeopleArt.manifest().designs.keys():
		ok = ok and PeopleArt.info(d)[4].size() == 36
	t.check(ok, "every design's frame table has 36 frame counts")


## "getup" is the death fall played backwards, frame for frame.
static func _getup(t) -> void:
	var img := PeopleArt.atlas().get_image()
	var same := true
	for d in ["resident_a", "guard"]:
		for f in PeopleArt.Facing.values():
			var n := PeopleArt.frame_count(d, &"death", f)
			same = same and PeopleArt.frame_count(d, &"getup", f) == n
			for i in n:
				var up := img.get_region(Rect2i(PeopleArt.frame_rect(d, &"getup", f, i)))
				var down := img.get_region(Rect2i(PeopleArt.frame_rect(d, &"death", f, n - 1 - i)))
				same = same and _same_cell(up, down)
	t.check(same, "getup frame i is death frame n-1-i")


## A direction the art lacks is its partner flipped left-right: south-west from south-east, north-west from north-east.
## The feet stay on the same row, and a flipped 24 px cell moves the foot column by at most a pixel.
static func _mirror(t) -> void:
	var img := PeopleArt.atlas().get_image()
	var same := true
	var feet := true
	for pair in [["resident_a", &"scream"], ["guard", &"swing"]]:
		var d: String = pair[0]
		var a: StringName = pair[1]
		for from_to in [[PeopleArt.Facing.SE, PeopleArt.Facing.SW], [PeopleArt.Facing.NE, PeopleArt.Facing.NW]]:
			var n := PeopleArt.frame_count(d, a, from_to[0])
			same = same and n == PeopleArt.frame_count(d, a, from_to[1]) and n > 1
			for i in n:
				var src := img.get_region(Rect2i(PeopleArt.frame_rect(d, a, from_to[0], i)))
				var dst := img.get_region(Rect2i(PeopleArt.frame_rect(d, a, from_to[1], i)))
				src.flip_x()
				same = same and _same_cell(src, dst)
				var r1 := src.get_used_rect()
				var r2 := dst.get_used_rect()
				feet = feet and r1.end.y == r2.end.y and absi((r1.position.x + r1.end.x) / 2 - (r2.position.x + r2.end.x) / 2) <= 1
	t.check(same, "a mirrored direction is its partner flipped, frame for frame (scream, swing)")
	t.check(feet, "and its feet stand on the same row and within a pixel of the same column")


## A design with no art for a new row shows its idle there; no hole, no error.
static func _fallback(t) -> void:
	var img := PeopleArt.atlas().get_image()
	var ok := true
	var same := true
	for d in PeopleArt.manifest().designs.keys():
		for a in [&"scream", &"lurch", &"swing"]:
			for f in PeopleArt.Facing.values():
				ok = ok and PeopleArt.frame_count(d, a, f) >= 1
		# Until a design is given scream art, its scream is its idle.
		var n := PeopleArt.frame_count(d, &"scream", 0)
		if n == PeopleArt.frame_count(d, &"idle", 0):
			var a0 := img.get_region(Rect2i(PeopleArt.frame_rect(d, &"scream", 0, 0)))
			var b0 := img.get_region(Rect2i(PeopleArt.frame_rect(d, &"idle", 0, 0)))
			same = same and _same_cell(a0, b0)
	t.check(ok, "a design lacking new art has frames in every new row")
	t.check(same, "and a scream it lacks is its idle")
	# Back-view screams rejected on review (make_people_atlas.py REJECTED) show the idle, both back directions.
	var back := true
	for d in ["merchant_a", "craft_a", "engineer"]:
		for f in [PeopleArt.Facing.NE, PeopleArt.Facing.NW]:
			back = back and PeopleArt.frame_count(d, &"scream", f) == PeopleArt.frame_count(d, &"idle", f)
			back = back and _same_cell(img.get_region(Rect2i(PeopleArt.frame_rect(d, &"scream", f, 0))),
				img.get_region(Rect2i(PeopleArt.frame_rect(d, &"idle", f, 0))))
		back = back and PeopleArt.frame_count(d, &"scream", PeopleArt.Facing.SE) > PeopleArt.frame_count(d, &"idle", PeopleArt.Facing.SE)
	t.check(back, "a rejected back-view scream is the idle, the front view keeps its art")
	t.check((PeopleArt.info("merchant_a")[5] >> 5) & 1 == 0 and (PeopleArt.info("resident_a")[5] >> 5) & 1 == 1,
		"the own-art bit is clear for a scream with a rejected direction, set for one without")


## Frame, animation and facing round-trip through the pose code for every animation.
static func _pack(t) -> void:
	var ok := true
	for a in 9:
		for f in 4:
			for k in 21:
				var code := k << 6 | a << 2 | f
				ok = ok and (code >> 2 & 15) == a and (code & 3) == f and (code >> 6) == k
	t.check(ok, "the pose code round-trips frame, animation and facing for all nine animations")
	# And the person's own: a held animation's code reads back through _sprite_pose().
	var env := EnvironmentField.new()
	var town := Town.new()
	town.build(env)
	var grid := WalkGrid.new().setup(env, town)
	var p := Person.new()
	p.rng.seed = 26
	p.bounds = TownLayout.MAP
	p.setup_person(false, Vector2(2.7, 2.0), grid)
	p.die(&"nova", p.ground_pos + Vector2(1, 0))
	p.tick(1.0)
	var pose := p._sprite_pose()
	var code := p._sprite_pose_code()
	t.check(PeopleArt.ANIMS[code >> 2 & 15] == pose[0] and (code & 3) == pose[1] and (code >> 6) == pose[2],
		"_sprite_pose() unpacks _sprite_pose_code()")
	p.free()


## Two atlas cells show the same picture: the same alpha, and the same colour where there is any. (Import fixes the colour
## of transparent pixels from their neighbours, so those bytes differ between cells.)
static func _same_cell(a: Image, b: Image) -> bool:
	if a.get_size() != b.get_size():
		return false
	for y in a.get_height():
		for x in a.get_width():
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			if not is_equal_approx(p.a, q.a) or (p.a > 0.0 and not p.is_equal_approx(q)):
				return false
	return true
