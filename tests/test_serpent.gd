extends RefCounted
## The Pale Serpent (Death, Tier V): a drag, once a descent. A vast feathered serpent rises out of the ground at the press and
## glides along the drag (LENGTH at most) over 10 s, then loops once through its end. Anyone out in the open (not indoors,
## not guised) within BAND of the head's path as it passes dies at once, silently, as &"shadow" -- a whole body, so it leaves
## a remain -- and no house is touched. Anyone out in the open within SIGHT of it as it rises is slowed to 0.6 for 20 s, and
## takes the plague too if Pestilence's is in town.

const RD := preload("res://tests/test_raise_dead.gd")
const FxStage := preload("res://tests/fx_stage.gd")
const DT := 0.05


static func _cast(made: Array, at: Vector2, to: Vector2) -> PaleSerpentFx:
	var dir := (to - at).normalized() if to.distance_to(at) > 0.01 else Vector2.RIGHT
	return FxTimeline.cast(PaleSerpentFx, made[5], at, {"dir": dir, "to": to}) as PaleSerpentFx


static func run(t) -> void:
	var made := RD._setup()
	_book(t)
	_path(t)
	_heads(t)
	_size(t)
	_seamless(t)
	_band(t, made)
	_souls(t, made)
	_remains(t, made)
	_structures(t, made)
	_sight(t, made)
	_plague(t, made)
	_escaped(t, made)
	_exit(t, made)
	_loud(t, made)
	_once(t, made)
	_aim(t, made)
	_street(t, made)
	_decoy(t, made)
	await _staged(t, made)
	RD._done(made)


## Everyone back out in the open, well and whole, off in the corner; no remain left lying.
static func _reset(made: Array) -> void:
	for p in (made[0] as Crowd).citizens + (made[0] as Crowd).soldiers:
		if is_instance_valid(p):
			p.inside = false
			p.sick_left = 0.0
			p.statuses.erase(&"guise")
	RD._clear_all(made)


## The nth citizen still alive (the serpent kills some in every test), calm, at `at`.
static func _put(made: Array, n: int, at: Vector2) -> Person:
	var alive := (made[0] as Crowd).citizens.filter(func(q: Person) -> bool: return is_instance_valid(q) and q.is_alive())
	var p: Person = alive[n]
	p.ground_pos = at
	p.mind = Person.Mind.CALM
	return p


## The row, its tables, its icons, the brief's numbers, its cues; a shadow death is a whole body and a quiet one.
static func _book(t) -> void:
	var b := PowerBook.get_power("serpent")
	t.check(not b.is_empty() and int(b.dp) == 6 and float(b.cooldown) == 999.0 and String(b.aim) == "drag"
		and PowerBook.authority_of("serpent") == "death" and not PowerBook.is_quiet("serpent")
		and String(b.get("path", "")) == "res://src/fx/death/pale_serpent.gd",
		"The Pale Serpent: Death's 6 DP, once a descent, a drag, loud (%s)" % [b])
	var area: Dictionary = Targeting.AREAS.get("serpent", {})
	t.check(PowerBook.REACH.has("serpent") and is_equal_approx(PowerBook.impact("serpent"), PaleSerpentFx.T_RISE)
		and PowerBook.family("serpent") == "death" and Rules.POWER_KINDS.get("serpent", []) == [&"shadow"]
		and area.get("shape", "") == "lane" and is_equal_approx(float(area.get("length", 0.0)), PaleSerpentFx.LENGTH)
		and is_equal_approx(float(area.get("half", 0.0)), PaleSerpentFx.BAND) and bool(area.get("follow", false))
		and Targeting.AREA_STATS.get("serpent", {}) == {"length": "LENGTH"},
		"its reach, impact (the head risen: the first shadow), family, kills (shadow) and area (the drag's lane)")
	t.check(PowerBook.icon("serpent") != null and PowerBook.hud_icon("serpent") != null and PowerBook.clip("serpent") != null,
		"it has its icons and clip")
	t.check(PaleSerpentFx.LENGTH == 14.0 and PaleSerpentFx.GLIDE == 10.0 and PaleSerpentFx.CIRCLE_R == 4.0
		and PaleSerpentFx.CIRCLE == 3.0 and PaleSerpentFx.BAND == 2.0 and PaleSerpentFx.SIGHT == 12.0
		and PaleSerpentFx.SICK == 20.0, "the numbers of the brief")
	t.check(Sfx.CATALOG.has(&"serpent_rise") and Sfx.CATALOG.has(&"serpent_glide"), "its cues (wind and feathers) are catalogued")
	t.check(Remains.BODY_KINDS.has(&"shadow") and DeathVoices.QUIET_KINDS.has(&"shadow"),
		"a shadow death is a whole body and makes no cry")
	t.check(PaleSerpentFx.HEADS.size() == 5 and (PaleSerpentFx.HEADS["east"] as Texture2D).get_size() == Vector2(64, 64)
		and PaleSerpentFx.TAIL.get_size() == Vector2(64, 48), "the Task 1 sheet is there (preloaded)")


## The head's run: from the press along the drag, clamped to LENGTH (and MIN_LENGTH); then a loop of CIRCLE_R through the end.
static func _path(t) -> void:
	var at := Vector2(2.0, 3.0)
	t.check(PaleSerpentFx.end_of(at, {"dir": Vector2.RIGHT, "to": at + Vector2(30.0, 0.0)}).is_equal_approx(at + Vector2(14.0, 0.0))
		and PaleSerpentFx.end_of(at, {"dir": Vector2.DOWN, "to": at + Vector2(0.0, 6.0)}).is_equal_approx(at + Vector2(0.0, 6.0))
		and PaleSerpentFx.end_of(at, {"dir": Vector2.RIGHT, "to": at}).is_equal_approx(at + Vector2(PaleSerpentFx.MIN_LENGTH, 0.0)),
		"the drag is clamped to LENGTH, a short one kept, a click runs MIN_LENGTH")
	# Review IMPORTANT 1: the way is the drag's as Targeting reads it (extra.dir: DEFAULT_DIR under DRAG_MIN), never the jitter
	# of a short drag; only the length comes from where it ended.
	var jitter := PaleSerpentFx.end_of(at, {"dir": Vector2.RIGHT, "to": at + Vector2(0.0, 0.2)})
	t.check(jitter.is_equal_approx(at + Vector2(PaleSerpentFx.MIN_LENGTH, 0.0)),
		"a 0.2-long drag goes along extra.dir, as the preview shows (%s)" % [jitter - at])
	t.check(PaleSerpentFx.end_of(at, {"dir": Vector2.DOWN, "to": at + Vector2(3.0, 9.0)}).is_equal_approx(at + Vector2(0.0, sqrt(90.0))),
		"the way is extra.dir's, the length the drag's")
	var fx := PaleSerpentFx.new()
	fx.origin = at
	fx.extra = {"dir": Vector2.RIGHT, "to": at + Vector2(10.0, 0.0)}
	fx.plan()
	var end := at + Vector2(10.0, 0.0)
	var far := 0.0
	for i in 41:
		far = maxf(far, fx.head_at(PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE + PaleSerpentFx.CIRCLE * float(i) / 40.0).distance_to(end))
	t.check(fx.head_at(0.0).is_equal_approx(at) and fx.head_at(PaleSerpentFx.T_RISE).is_equal_approx(at)
		and fx.head_at(PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE * 0.5).is_equal_approx(at + Vector2(5.0, 0.0))
		and fx.head_at(PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE).is_equal_approx(end)
		and fx.head_at(PaleSerpentFx.glide_end()).distance_to(end) < 0.01 and is_equal_approx(far, PaleSerpentFx.CIRCLE_R * 2.0),
		"it rises at the press, glides to the end over GLIDE, loops once through it (%.2f across)" % far)
	fx.free()


## The head drawn for its heading on screen: five drawn ways, the west three mirrored from the east.
static func _heads(t) -> void:
	t.check(PaleSerpentFx.head_for(Vector2(1, 0)) == ["east", false] and PaleSerpentFx.head_for(Vector2(-1, 0)) == ["east", true]
		and PaleSerpentFx.head_for(Vector2(0, 1)) == ["south", false] and PaleSerpentFx.head_for(Vector2(0, -1)) == ["north", false]
		and PaleSerpentFx.head_for(Vector2(1, 1)) == ["south-east", false] and PaleSerpentFx.head_for(Vector2(-1, 1)) == ["south-east", true]
		and PaleSerpentFx.head_for(Vector2(1, -1)) == ["north-east", false] and PaleSerpentFx.head_for(Vector2(-1, -1)) == ["north-east", true],
		"a head for each of the eight ways")


## "the kill lane is 4 wide": the shadow takes everyone out in the open within BAND (2.0) of the head's path as it passes
## (a soldier too), as &"shadow" -- one 1.9 off it too; not one 2.4 off it, nor one indoors or guised on it; the first at
## the impact.
static func _band(t, made: Array) -> void:
	_reset(made)
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var to := at + Vector2(14.0, 0.0)
	var side := Vector2.RIGHT.orthogonal()  # the loop turns to this side; the spared stand on the other
	var first := _put(made, 0, at)
	var on := _put(made, 1, at + Vector2(5.0, 0.0))
	var edge := _put(made, 2, at + Vector2(7.0, 0.0) - side * 1.9)
	var off := _put(made, 3, at + Vector2(7.0, 0.0) - side * 2.4)
	var indoor := _put(made, 4, at + Vector2(3.0, 0.0))
	indoor.inside = true
	var guised := _put(made, 5, at + Vector2(4.0, 0.0))
	guised.statuses[&"guise"] = 60.0
	var soldier: Person = (made[0] as Crowd).soldiers.filter(func(q: Person) -> bool: return q.is_alive())[0]
	soldier.ground_pos = at + Vector2(9.0, 0.0)
	var kinds := {}
	var on_kill := func(e: DummyEnemy, kind: StringName) -> void: kinds[e.get_instance_id()] = kind
	field.enemy_killed.connect(on_kill)
	var fx := _cast(made, at, to)
	RD._run(fx, PaleSerpentFx.T_RISE - 0.1)
	t.check(first.is_alive(), "nobody dies while it is still rising")
	RD._run(fx, 0.15)
	t.check(not first.is_alive() and is_equal_approx(fx.first_kill_at, PowerBook.impact("serpent")),
		"the one at the press dies as the head is up, at the power's impact (%.2f)" % fx.first_kill_at)
	var reach := PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE * (5.0 - PaleSerpentFx.BAND) / 14.0
	RD._run(fx, reach - fx.t - 0.15)
	t.check(on.is_alive(), "one ahead of it lives until the shadow reaches them")
	RD._run(fx, 0.3)
	t.check(not on.is_alive(), "and dies as it does")
	RD._run(fx, PaleSerpentFx.glide_end() - fx.t + 0.2)
	t.check(PaleSerpentFx.BAND == 2.0 and not edge.is_alive() and off.is_alive(),
		"the kill lane is 4 wide: 1.9 off the path dies, 2.4 off it lives")
	t.check(not soldier.is_alive(), "a soldier on it dies")
	t.check(indoor.is_alive() and guised.is_alive(), "one indoors or guised on it lives")
	t.check(kinds.get(first.get_instance_id()) == &"shadow" and kinds.get(on.get_instance_id()) == &"shadow"
		and kinds.get(edge.get_instance_id()) == &"shadow" and fx.taken.size() == 4,
		"each dies as shadow (%d taken)" % fx.taken.size())
	field.enemy_killed.disconnect(on_kill)
	fx.end_now()


## R11: twice the size -- the sprites drawn at SCALE 2, the neck and tail twice as wide, a longer, higher, wilder body; the
## final loop the user likes kept as it was.
static func _size(t) -> void:
	t.check(PaleSerpentFx.R_NECK == 28.0 and PaleSerpentFx.R_TAIL == 16.0 and PaleSerpentFx.SCALE == 2.0, "twice the size")
	t.check(PaleSerpentFx.SEGMENTS == 30 and PaleSerpentFx.GAP == 0.45 and PaleSerpentFx.LIFT == 60.0 and PaleSerpentFx.WAVE == 10.0,
		"a longer body, higher over its shadow, with a wilder wave (R11)")
	t.check(PaleSerpentFx.CIRCLE_R == 4.0 and PaleSerpentFx.LENGTH == 14.0, "the loop is kept")
	t.check(PaleSerpentFx.NECK_SOCKET.size() == 5 and PaleSerpentFx.NECK_SOCKET.has_all(PaleSerpentFx.HEADS.keys())
		and is_equal_approx(PaleSerpentFx.SOUL_FLY, 0.7), "a measured neck socket for each head; a soul flies 0.7 s")


## R11, the seam: the collar (piece 1) sits on the head's neck socket and every piece overlaps the next, for drags along
## all eight ways, through the whole glide and the loop.
static func _seamless(t) -> void:
	var worst_socket := 0.0
	var worst_pair := ""
	var bad := 0
	var at := Vector2(2.0, 3.0)
	for w in 8:
		var dir := Vector2.RIGHT.rotated(float(w) * PI * 0.25)
		var fx := PaleSerpentFx.new()
		fx.origin = at
		fx.extra = {"dir": dir, "to": at + dir * PaleSerpentFx.LENGTH}
		fx.plan()
		var time := PaleSerpentFx.T_RISE + 0.1
		while time <= PaleSerpentFx.glide_end() + 0.001:
			var ps: Array[Dictionary] = fx.pieces_at(time)
			var gap := (ps[1].sp as Vector2).distance_to(fx.socket_at(time))
			worst_socket = maxf(worst_socket, gap)
			if gap > 1.0:
				bad += 1
			var prev := {}
			for k in ps.size():
				var q: Dictionary = ps[k]
				if not bool(q.get("vis", true)):
					continue
				if not prev.is_empty():
					var d := (prev.sp as Vector2).distance_to(q.sp)
					if d >= (float(prev.r) + float(q.r)) * 0.75:
						bad += 1
						if worst_pair == "":
							worst_pair = "way %d t %.2f piece %d: %.1f px apart, radii %.1f + %.1f" % [w, time, k, d, prev.r, q.r]
				prev = q
			time += 0.05
		fx.free()
	t.check(bad == 0 and worst_socket <= 1.0,
		"seamless: every joint overlaps through the glide and the loop (%d bad; socket off %.2f px; %s)" % [bad, worst_socket, worst_pair])


## "each kill's soul streams into it": SOUL_FLY after each kill, on the effect's clock (staged or not), its soul arrives.
static func _souls(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var first := _put(made, 0, at)
	_put(made, 1, at + Vector2(3.0, 0.0))
	_put(made, 2, at + Vector2(6.0, 0.5))
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + 0.3)
	t.check(not first.is_alive() and fx.souls_in == 0, "a soul is still on its way just after the kill (%d in)" % fx.souls_in)
	RD._run(fx, PaleSerpentFx.SOUL_FLY)
	t.check(fx.souls_in == 1, "and arrives SOUL_FLY after it (%d in)" % fx.souls_in)
	RD._run(fx, PaleSerpentFx.glide_end() + PaleSerpentFx.SOUL_FLY + 0.1 - fx.t)
	t.check(fx.souls_in == fx.taken.size() and fx.souls_in > 0,
		"each kill's soul streams into it (%d of %d)" % [fx.souls_in, fx.taken.size()])
	fx.end_now()


## Staged (the effect in the tree with an Impact, as in the game): the pieces, the cold glow and the souls flying in as wisps
## are drawn, and none of it changes the logic -- the same run headless and staged takes as many and counts as many souls.
static func _staged(t, made: Array) -> void:
	var plain := _soul_run(made, false)
	var ctx: FxContext = made[5]
	var keep := [ctx.overhead, ctx.ground, ctx.overhead_back]
	var stage := Node2D.new()
	t.root.add_child(stage)
	await t.process_frame  # (the tree is only live after the first frame)
	ctx.overhead = Node2D.new()
	ctx.ground = Node2D.new()
	ctx.overhead_back = Node2D.new()
	for n in [ctx.ground, ctx.overhead_back, ctx.overhead]:
		stage.add_child(n)
	var stub := FxStage.StageImpact.new()
	ctx.impact = stub
	var lit := _soul_run(made, true)
	var cut := _cut(made)
	await t.process_frame
	ctx.impact = null
	stub.free()
	ctx.overhead = keep[0]
	ctx.ground = keep[1]
	ctx.overhead_back = keep[2]
	t.root.remove_child(stage)
	stage.free()
	t.check(int(lit.pieces) == PaleSerpentFx.SEGMENTS + 2, "staged: head, collar, discs and tail all show in the glide (%d)" % lit.pieces)
	t.check(int(lit.glow) > 0 and int(lit.glow_off) == 0,
		"staged: a cold glow lights the ground under the head (%d frames lit, %d off it)" % [lit.glow, lit.glow_off])
	t.check(int(lit.wisps) > 0 and int(lit.taken) > 0, "staged: the souls fly in as wisps (%d at once)" % lit.wisps)
	t.check(int(lit.taken) == int(plain.taken) and int(lit.souls) == int(plain.souls) and int(lit.souls) == int(lit.taken),
		"staged or not, the same dead and the same souls (%d/%d staged, %d/%d headless)" % [lit.souls, lit.taken, plain.souls, plain.taken])
	t.check(int(cut.bad) == 0 and int(cut.ways) == 8 and int(cut.poses) > 0,
		"the collar as drawn covers the head's whole neck cut as drawn, on every heading (%d ways, %d poses, %d bad; %s)"
		% [cut.ways, cut.poses, cut.bad, cut.worst])


## Every opaque pixel of each head sheet's neck cut row (its lowest opaque row), in sprite px.
static func _cut_rows() -> Dictionary:
	var rows := {}
	for key in PaleSerpentFx.HEADS:
		var tex: Texture2D = PaleSerpentFx.HEADS[key]
		var img := tex.get_image()
		if img == null or img.is_empty():
			img = Image.load_from_file(tex.resource_path)  # (the dummy renderer keeps no pixels: the sheet itself)
		var px: Array[Vector2] = []
		for y in range(img.get_height() - 1, -1, -1):
			for x in img.get_width():
				if img.get_pixel(x, y).a >= 0.5:
					px.append(Vector2(x, y))
			if not px.is_empty():
				break
		rows[key] = px
	return rows


## Staged, for drags along all eight ways through the glide and the loop: each frame, every pixel of the head's neck cut as
## the head piece draws it (its position + lift, mirrored, at SCALE) must lie on the collar piece as drawn (its position +
## lift): within its green disc (r) or across its feather skirt (skirt.x..skirt.y, r / 2 high), give or take 1 px. Read off
## the drawn pieces, so a drift between _pose and pieces_at shows too.
static func _cut(made: Array) -> Dictionary:
	var rows := _cut_rows()
	var out := {"bad": 0, "ways": 0, "poses": 0, "worst": ""}
	var seen := {}
	var worst := 0.0
	for w in 8:
		_reset(made)
		var at := RD._empty(made)
		var dir := Vector2.RIGHT.rotated(float(w) * PI * 0.25)
		var fx := _cast(made, at, at + dir * PaleSerpentFx.LENGTH)
		while not fx.finished and fx.t < PaleSerpentFx.glide_end():
			fx._process(DT)
			if fx.t < PaleSerpentFx.T_RISE + 0.1:
				continue
			var head: PaleSerpentFx.Piece = fx._pieces[0]
			var collar: PaleSerpentFx.Piece = fx._pieces[1]
			if not head.visible or not collar.visible:
				continue
			out.poses = int(out.poses) + 1
			seen["%s%s" % [head.head, "<" if head.mirror else ""]] = true
			var pivot := head.position + head.lift
			var centre := collar.position + collar.lift
			var m := -1.0 if head.mirror else 1.0
			for p in rows[head.head]:
				var q: Vector2 = pivot + Vector2(m * PaleSerpentFx.SCALE, PaleSerpentFx.SCALE) * (p + Vector2(0.5, 1.0) - PaleSerpentFx.HEAD_PIVOT)
				var d := q - centre
				var on_disc := d.length() <= collar.r + 1.0
				var sk := collar.skirt
				var on_skirt := sk != Vector2.ZERO and d.x >= sk.x - 1.0 and d.x <= sk.y + 1.0 and absf(d.y) <= collar.r * 0.5 + 1.0
				if not on_disc and not on_skirt:
					out.bad = int(out.bad) + 1
					var off := d.length() - collar.r
					if off > worst:
						worst = off
						out.worst = "%s%s pixel %s %.1f px off the collar" % [head.head, " mirrored" if head.mirror else "", p, off]
		fx.end_now()
	out.ways = seen.size()
	return out


## Three in the lane; the serpent run past its glide and its last soul's flight; what it took and drew.
static func _soul_run(made: Array, staged: bool) -> Dictionary:
	_reset(made)
	var at := RD._empty(made)
	for i in 3:
		_put(made, i, at + Vector2(2.0 + 3.0 * float(i), 0.3 * float(i)))
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	var out := {"pieces": 0, "glow": 0, "glow_off": 0, "wisps": 0}
	for i in roundi((PaleSerpentFx.glide_end() + PaleSerpentFx.SOUL_FLY + 0.2) / DT):
		if fx.finished:
			break
		fx._process(DT)
		if staged:
			if fx.t > PaleSerpentFx.T_RISE + 6.0 and fx.t < PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE:
				out.pieces = maxi(int(out.pieces), fx._pieces.filter(func(q: Node2D) -> bool: return q.visible).size())
			if is_instance_valid(fx._glow) and float(fx._glow.mat.get_shader_parameter("intensity")) > 0.0:
				out.glow = int(out.glow) + 1
				if not fx._glow.position.is_equal_approx(fx.head_at(fx.t)):
					out.glow_off = int(out.glow_off) + 1
			out.wisps = maxi(int(out.wisps), fx._wisps.size())
	out.taken = fx.taken.size()
	out.souls = fx.souls_in
	fx.end_now()
	return out


## "leaves remains (shadow is a body kind)": each one the shadow took lies whole where they fell, a remain Raise can take.
static func _remains(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var p := _put(made, 0, at + Vector2(3.0, 0.0))
	var design := p._design()
	var fx := _cast(made, at, at + Vector2(10.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE * 0.5)
	var r := crowd.remains.pick(p.ground_pos)
	t.check(not p.is_alive() and r != null and r.kind == &"shadow", "a whole body lies there, a shadow remain")
	t.check(crowd.remains.pick(p.ground_pos, true) != null, "its soul still near: ready to rise")
	fx.end_now()
	if r == null:
		return
	var raise := RD._cast(made, r.pos, "zombie")
	RD._run(raise, RaiseTheDeadFx.T_RISE + 0.1)
	var up := raise.visitors.living()
	t.check(up.size() == 1 and up[0].breed == Animal.Breed.ZOMBIE and up[0].worn == design,
		"Raise the Dead raises it: a zombie in their own look (%d up)" % up.size())
	raise.end_now()


## "no structure damaged": the serpent's run across a house leaves every building as it was.
static func _structures(t, made: Array) -> void:
	_reset(made)
	var env: EnvironmentField = made[1]
	var house := RD._house(env, made[2])
	t.check(house != null, "(a house)")
	if house == null:
		return
	var before := {}
	for s in env.structures():
		before[s] = [s.hp, s.destroyed]
	var at := house.center() - Vector2(7.0, 0.0)
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.glide_end() + 0.5)
	var hurt := 0
	for s in env.structures():
		if before.has(s) and (s.hp != before[s][0] or s.destroyed != before[s][1]):
			hurt += 1
	t.check(hurt == 0, "no house is touched (%d changed)" % hurt)
	fx.end_now()


## "seen within 12: slowed 20 s": one out in the open within SIGHT as it rises walks at 0.6 for SICK, then is let go; one past
## 12 and one indoors are not; no plague in town, nobody catches it.
static func _sight(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var near := _put(made, 0, at - Vector2(8.0, 0.0))
	var far := _put(made, 1, at - Vector2(13.0, 0.0))
	var indoor := _put(made, 2, at - Vector2(5.0, 0.0))
	indoor.inside = true
	var guised := _put(made, 3, at - Vector2(6.0, 0.0))
	guised.statuses[&"guise"] = 60.0
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + 0.1)
	t.check(is_equal_approx(near.pace_hold(), PaleSerpentFx.SICK_PACE) and far.pace_hold() == 1.0 and indoor.pace_hold() == 1.0
		and guised.pace_hold() == 1.0,
		"seen within 12: slowed to 0.6; not past 12, indoors or guised (%.2f, %.2f, %.2f, %.2f)" % [near.pace_hold(), far.pace_hold(), indoor.pace_hold(), guised.pace_hold()])
	t.check(near.sick_left == 0.0, "no plague in town: nobody catches it")
	indoor.inside = false
	RD._run(fx, PaleSerpentFx.SICK - 0.3)
	t.check(is_equal_approx(near.pace_hold(), PaleSerpentFx.SICK_PACE) and not fx.finished, "still slowed near the 20 s")
	RD._run(fx, 0.5)
	t.check(near.pace_hold() == 1.0 and indoor.pace_hold() == 1.0, "let go at 20 s (%.2f)" % near.pace_hold())
	t.check(fx.finished, "and the serpent's work is done")


## If Pestilence's plague is in town (anyone sick), the one who sees it catches it too.
static func _plague(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var near := _put(made, 0, at - Vector2(6.0, 0.0))
	var ill := _put(made, 1, Vector2(-27.0, -27.0))
	ill.sick_left = 30.0
	t.check(PaleSerpentFx.plague_live(crowd), "(the plague is in town)")
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + 0.1)
	t.check(is_equal_approx(near.pace_hold(), PaleSerpentFx.SICK_PACE) and is_equal_approx(near.sick_left, PlagueManager.PLAGUE_LIFE),
		"seen with the plague in town: slowed and sick (%.2f)" % near.sick_left)
	fx.end_now()
	t.check(near.pace_hold() == 1.0, "cut short, let go")
	ill.sick_left = 0.0
	near.sick_left = 0.0
	t.check(not PaleSerpentFx.plague_live(crowd), "(and none once nobody is sick)")


## A held one who leaves the town mid-effect (Crowd.escape frees them) is let go without an error; the rest at 20 s.
static func _escaped(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var field: EnemyField = made[3]
	var at := RD._empty(made)
	var gone := _put(made, 0, at - Vector2(5.0, 0.0))
	var stays := _put(made, 1, at - Vector2(7.0, 0.0))
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + 0.1)
	var id := gone.get_instance_id()
	t.check(fx._held.has(id) and fx._held.has(stays.get_instance_id()), "(both held)")
	crowd.citizens.erase(gone)
	field.remove(gone)
	gone.free()
	RD._run(fx, PaleSerpentFx.SICK)
	t.check(fx._held.is_empty() and stays.pace_hold() == 1.0, "the one who left is let go without an error, the other at 20 s")
	fx.end_now()
	t.check(fx.finished, "and it ends cleanly")


## Freed without _finish (a mission torn down mid-glide): _exit_tree still lets every pace go.
static func _exit(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var near := _put(made, 0, at - Vector2(5.0, 0.0))
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + 0.1)
	t.check(near.pace_hold() < 1.0, "(held)")
	fx._exit_tree()
	t.check(near.pace_hold() == 1.0 and fx._held.is_empty(), "freed without its end, it still lets every pace go")
	fx.end_now()
	t.check(near.pace_hold() == 1.0, "and its end after that changes nothing")


## Loud: the cast is held as a danger by the town until its impact, and the head frightens the street round it as it goes.
static func _loud(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var at := RD._empty(made)
	var held := crowd.held_count()
	crowd.on_cast(at, Vector2.RIGHT, PaleSerpentFx.LENGTH, "serpent")
	t.check(crowd.held_count() == held + 1, "the cast is a danger the town sees (held for its impact)")
	crowd.drop_held()
	# Review IMPORTANT 2b: the fright rolls along behind the head (FRIGHT_BACK), over the street it has passed; the street
	# ahead is not sent running before the shadow reaches it.
	var watcher := _put(made, 0, at + Vector2(4.0, 0.0) - Vector2.RIGHT.orthogonal() * 2.5)
	var ahead := _put(made, 1, at + Vector2(13.0, 0.0) - Vector2.RIGHT.orthogonal() * 2.5)
	var fx := _cast(made, at, at + Vector2(14.0, 0.0))
	RD._run(fx, PaleSerpentFx.T_RISE + PaleSerpentFx.GLIDE * 0.3)
	t.check(watcher.mind == Person.Mind.CALM, "one beside its path ahead of the head is not frightened yet (%s)" % Person.Mind.keys()[watcher.mind])
	RD._run(fx, PaleSerpentFx.GLIDE * 0.45)
	t.check(watcher.is_alive() and watcher.mind != Person.Mind.CALM,
		"once it has passed, the street behind it is frightened (%s)" % Person.Mind.keys()[watcher.mind])
	t.check(ahead.mind != Person.Mind.PANIC and ahead.mind != Person.Mind.FLEE,
		"while the street ahead is not sent running (%s)" % Person.Mind.keys()[ahead.mind])
	fx.end_now()


## "once a descent": its cooldown outlasts the longest night; cast once, the slot refuses again.
static func _once(t, made: Array) -> void:
	_reset(made)
	var rules := Rules.new().setup(PackedStringArray(["serpent"]), null, made[1], made[3], made[0], made[6])
	var casts := []
	rules.caster = func(_script: GDScript, ground: Vector2, extra: Dictionary) -> FxTimeline:
		casts.append([ground, extra])
		return null
	var refused := []
	rules.cast_refused.connect(func(_slot: int, reason: String) -> void: refused.append(reason))
	var at := RD._empty(made)
	rules.cast(0, at, {"dir": Vector2.RIGHT, "to": at + Vector2(8.0, 0.0)})
	t.check(casts.size() == 1 and rules.cooldown_left(0) > TierBook.clock(5), "cast once, it waits out the longest night (%.0f s)" % rules.cooldown_left(0))
	rules.cast(0, at, {"dir": Vector2.RIGHT, "to": at + Vector2(8.0, 0.0)})
	t.check(casts.size() == 1 and refused == ["cooldown"], "a second cast is refused (%s)" % [refused])
	rules.free()


## Targeting (review IMPORTANT 2a and the minors): the serpent's lane follows the drag, clamped; tsunami's stays its own. The
## serpent's danger is held at the press only (the street ahead is not warned); tsunami's and windfall's along their lanes
## as before. The preview rings the loop at the lane's end, on the side it turns.
static func _aim(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	crowd.drop_held()
	var rules := Rules.new().setup(PackedStringArray(["serpent", "tsunami", "windfall"]), null, made[1], made[3], made[0], made[6])
	rules.caster = func(_script: GDScript, _g: Vector2, _e: Dictionary) -> FxTimeline: return null
	var aim := Targeting.new().setup(rules, crowd)
	var at := Vector2(0.0, 0.0)
	aim.pick(0)
	aim.press(at)
	aim.hover(at + Vector2(6.0, 0.0))
	var six := aim._lane_len_of(aim.area())
	aim.hover(at + Vector2(30.0, 0.0))
	var far := aim._lane_len_of(aim.area())
	aim.hover(at + Vector2(1.0, 0.0))
	var short := aim._lane_len_of(aim.area())
	t.check(is_equal_approx(six, 6.0) and is_equal_approx(far, PaleSerpentFx.LENGTH) and is_equal_approx(short, PaleSerpentFx.MIN_LENGTH),
		"the serpent's lane follows the drag, clamped (%.1f, %.1f, %.1f)" % [six, far, short])
	var loop := Targeting.loop_centre(Targeting.AREAS["serpent"], at, Vector2.RIGHT, 10.0)
	t.check(float(Targeting.AREAS["serpent"].get("loop", 0.0)) == PaleSerpentFx.CIRCLE_R
		and loop.is_equal_approx(at + Vector2(10.0, 0.0) + Vector2.RIGHT.orthogonal() * PaleSerpentFx.CIRCLE_R),
		"the preview rings the loop at the lane's end, on the side it turns (%s)" % [loop])
	aim.hover(at + Vector2(9.0, 0.0))
	aim.release(at + Vector2(9.0, 0.0))
	var held: Dictionary = crowd._held_dangers.back() if not crowd._held_dangers.is_empty() else {}
	t.check(held.get("key", "") == "serpent" and (held.get("points", []) as Array).size() == 1 and (held.points[0] as Vector2).is_equal_approx(at),
		"the serpent's danger is held at the press only (%s)" % [held.get("points", [])])
	crowd.drop_held()
	aim.pick(1)
	aim.press(at)
	aim.hover(at + Vector2(30.0, 0.0))
	t.check(is_equal_approx(aim._lane_len_of(aim.area()), float(Targeting.AREAS["tsunami"].length)), "tsunami's lane keeps its own length")
	aim.release(at + Vector2(30.0, 0.0))
	held = crowd._held_dangers.back() if not crowd._held_dangers.is_empty() else {}
	var want := Crowd.cast_points(at, Vector2.RIGHT, float(Targeting.AREAS["tsunami"].length), Crowd._cast_radius("tsunami"))
	t.check(held.get("key", "") == "tsunami" and held.get("points", []) == want, "tsunami's danger is held along its lane as before (%d points)" % want.size())
	crowd.drop_held()
	aim.pick(2)
	aim.press(at)
	aim.hover(at + Vector2(0.0, 5.0))
	aim.release(at + Vector2(0.0, 5.0))
	held = crowd._held_dangers.back() if not crowd._held_dangers.is_empty() else {}
	var w: Dictionary = Targeting.AREAS["windfall"]
	want = Crowd.cast_points(Targeting.lane_start("windfall", at, Vector2.DOWN), Vector2.DOWN, float(w.length), Crowd._cast_radius("windfall"))
	t.check(held.get("key", "") == "windfall" and held.get("points", []) == want, "and windfall's, centred on its press (%d points)" % want.size())
	crowd.drop_held()
	rules.free()
	aim.free()


## Review IMPORTANT 2c: the town steps along with the serpent. Ten calm people stand in a walkable street lane of 14, within
## the band, 1.3 apart; the serpent is cast down it through Targeting (its danger held as the game holds it); the crowd and
## every person are stepped with the effect for the whole glide. It must kill at least 3 of them.
static func _street(t, made: Array) -> void:
	_reset(made)
	var crowd: Crowd = made[0]
	var grid: WalkGrid = made[2]
	crowd.drop_held()
	var at := Vector2.INF
	for i in 1600:
		var c := grid.nearest_walkable(Vector2(-20.0 + float(i % 40), -20.0 + float(i / 40)))
		if c == Vector2.INF or (made[3] as EnemyField).in_radius(c + Vector2(7.0, 0.0), 10.0).size() > 0:
			continue
		var ok := true
		for k in 29:
			var g := c + Vector2(0.5 * float(k), 0.0)
			if not (grid.walkable(g) and grid.walkable(g + Vector2(0.0, 1.0)) and grid.walkable(g - Vector2(0.0, 1.0))):
				ok = false
				break
		if ok:
			at = c
			break
	t.check(at != Vector2.INF, "(a straight street of 14)")
	if at == Vector2.INF:
		return
	var lane: Array[Person] = []
	for i in 10:
		var p := _put(made, i, at + Vector2(1.2 + 1.3 * float(i), 0.5 if i % 2 == 0 else -0.5))
		p._goal = Vector2.INF
		p._path = PackedVector2Array()
		p._target = p.ground_pos
		lane.append(p)
	var rules := Rules.new().setup(PackedStringArray(["serpent"]), null, made[1], made[3], made[0], made[6])
	var fxs: Array = []
	rules.caster = func(s: GDScript, g: Vector2, e: Dictionary) -> FxTimeline:
		var fx := FxTimeline.cast(s, made[5], g, e)
		fxs.append(fx)
		return fx
	var aim := Targeting.new().setup(rules, crowd)
	aim.pick(0)
	aim.press(at)
	aim.hover(at + Vector2(14.0, 0.0))
	aim.release(at + Vector2(14.0, 0.0))
	t.check(fxs.size() == 1, "(cast through Targeting)")
	if fxs.is_empty():
		rules.free()
		aim.free()
		return
	var fx: PaleSerpentFx = fxs[0]
	for i in roundi((PaleSerpentFx.glide_end() + 0.5) / DT):
		crowd.advance(DT)
		for p in crowd.citizens + crowd.soldiers:
			if is_instance_valid(p):
				p.tick(DT)
		if not fx.finished:
			fx._process(DT)
	var dead := lane.filter(func(p: Person) -> bool: return not is_instance_valid(p) or not p.is_alive()).size()
	print("SERPENT street: %d of 10 in the lane killed (fx took %d)" % [dead, fx.taken.size()])
	t.check(dead >= 3, "a street of ten, the town stepping too: it kills at least 3 in the lane (%d)" % dead)
	fx.end_now()
	crowd.drop_held()
	rules.free()
	aim.free()


## A decoy (Mirrorfold's glass twin) is no one: the shadow passes over it, as Pale Reign's does, and takes the real one behind it.
static func _decoy(t, made: Array) -> void:
	_reset(made)
	var at := RD._empty(made)
	var to := at + Vector2(14.0, 0.0)
	var twin := _put(made, 0, at + Vector2(4.0, 0.0))
	twin.set_meta(&"decoy", true)
	var real := _put(made, 1, at + Vector2(6.0, 0.0))
	var fx := _cast(made, at, to)
	RD._run(fx, PaleSerpentFx.glide_end() + 0.2)
	t.check(twin.is_alive() and not fx.taken.has(twin), "a decoy on the path is never taken")
	t.check(not real.is_alive() and fx.taken.has(real), "and the real one past it is")
	fx.end_now()
	twin.remove_meta(&"decoy")
