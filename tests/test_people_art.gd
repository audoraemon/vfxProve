extends RefCounted
## PeopleArt: which design a citizen or soldier wears, and where its frames sit in the people atlas.

const R := CitizenProfile.Role


static func run(t) -> void:
	_designs(t)
	_frames(t)


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
