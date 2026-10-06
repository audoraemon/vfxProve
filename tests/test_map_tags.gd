extends RefCounted
## v0.10 M6 the map's tags (spec §2): MapTag's three kinds; where the HUD puts a tag's diamond and its label, and off
## screen its arrow; labels never overlap, the first listed being the one kept (a director lists its most important tags
## first, so a crowded view keeps their labels) and they stay inside the screen; a tag without a label or a point shows
## none; a plain tag shows anywhere on screen, one with an arrow takes its arrow at the rim; one measure for a plate.

const VIEW := Vector2(640.0, 360.0)
## The camera for these checks: the ground's origin at the screen's centre, no zoom.
const MID := Vector2(320.0, 180.0)


static func _tags(list: Array) -> Array[MapTag]:
	var out: Array[MapTag] = []
	out.assign(list)
	return out


static func run(t) -> void:
	_kinds(t)
	_points(t)
	_labels(t)
	_edge(t)
	_frame(t)


static func _kinds(t) -> void:
	var p := MapTag.person(Vector2(1.0, 2.0), Color.RED, "WREN", true)
	t.check(p.at == Vector2(1.0, 2.0) and p.color == Color.RED and p.label == "WREN" and p.edge and p.rise == 0.0
		and p.lift == MapTag.PERSON_LIFT and p.size == MapTag.SIZE and not p.outline.has_area(), "a person's tag")
	var bare := MapTag.person(Vector2.ZERO, Color.RED)
	t.check(not bare.edge and bare.label == "", "a person's tag has no label and no arrow unless asked")
	var pip := MapTag.pip(Vector2.ZERO, Color.RED)
	t.check(pip.label == "" and pip.size == MapTag.PIP_SIZE and pip.size < MapTag.SIZE and not pip.edge,
		"a pip: small and bare")
	var pl := MapTag.place(Vector2.ZERO, Color.GOLD, "TEMPLE", 40.0)
	t.check(pl.rise == 40.0 and pl.lift == MapTag.PLACE_LIFT and pl.edge and pl.label == "TEMPLE",
		"a place: raised, labelled, pointed at from the edge")
	t.check(not MapTag.place(Vector2.ZERO, Color.GOLD, "DOOR", 0.0, false).edge, "a place may go without its arrow")
	t.check(MapTag.SIZE == Hud.MARK_R and MapTag.PERSON_LIFT == 22.0, "a person's tag sits where v0.10's marks sat")
	t.check(p.valid() and not MapTag.person(Vector2.INF, Color.RED).valid(), "a tag at no point is not valid")


static func _points(t) -> void:
	var xf := Transform2D(0.0, MID)
	var pl := MapTag.place(Vector2.ZERO, Color.GOLD, "TEMPLE", 40.0)
	var want := (MID + Iso.ground_to_screen(Vector2.ZERO) - Vector2(0.0, 40.0 + MapTag.PLACE_LIFT)).round()
	t.check(Hud.tag_point(pl, xf) == want, "a place's diamond: up its rise, then its lift (%s)" % Hud.tag_point(pl, xf))
	var zoomed := Transform2D(0.0, Vector2(0.5, 0.5), 0.0, MID)
	var p := MapTag.person(Vector2.ZERO, Color.RED)
	var want_p := (MID + Iso.ground_to_screen(Vector2.ZERO) * 0.5 - Vector2(0.0, MapTag.PERSON_LIFT)).round()
	t.check(Hud.tag_point(p, zoomed) == want_p, "the lift is in screen pixels, whatever the zoom")
	var shape := Hud.mark_shape(Vector2(50.0, 50.0), MapTag.PIP_SIZE)
	t.check(shape[0] == Vector2(50.0, 50.0 - MapTag.PIP_SIZE) and shape[1] == Vector2(50.0 + MapTag.PIP_SIZE, 50.0),
		"a pip's diamond is its own size")


static func _labels(t) -> void:
	var xf := Transform2D(0.0, MID)
	var a := MapTag.person(Vector2.ZERO, Color.RED, "INQUISITOR")
	var b := MapTag.person(Vector2.ZERO, Color.RED, "TO THE TEMPLE")
	var bare := MapTag.person(Vector2.ZERO, Color.RED)
	var lay := Hud.tag_layout(_tags([bare, a, b]), xf, VIEW)
	t.check(lay.size() == 3 and String(lay[0].mode) == "map" and not bool(lay[0].show), "a bare tag shows no label")
	t.check(bool(lay[1].show) and not bool(lay[2].show) and String(lay[2].mode) == "map",
		"two labels at one point: the first listed stays, the second is left out, its diamond still shown")
	var r: Rect2 = lay[1].label
	var c: Vector2 = lay[1].c
	t.check(r.end.y <= c.y - a.size and absf(r.get_center().x - c.x) <= 1.0
		and is_equal_approx(r.size.x, UiTheme.width("INQUISITOR", UiTheme.SIZE_SMALL) + 2.0),
		"a label sits centred above its diamond, as wide as its words (%s over %s)" % [r, c])
	var apart := Hud.tag_layout(_tags([a, MapTag.person(Vector2(0.0, 6.0), Color.RED, "WREN")]), xf, VIEW)
	t.check(bool(apart[0].show) and bool(apart[1].show), "labels apart both show")
	var edge_xf := Transform2D(0.0, Vector2(12.0, 180.0))
	var left := Hud.tag_layout(_tags([MapTag.person(Vector2.ZERO, Color.RED, "HALCYON'S FLAME")]), edge_xf, VIEW)
	var lr: Rect2 = left[0].label
	t.check(String(left[0].mode) == "map" and lr.position.x == 0.0 and Rect2(Vector2.ZERO, VIEW).encloses(lr),
		"a label by the screen's edge is kept inside it (%s)" % lr)
	t.check(Hud.tag_layout(_tags([MapTag.person(Vector2.INF, Color.RED, "X")]), xf, VIEW).is_empty(),
		"a tag at no point is left out")
	# The first-listed label is kept whatever its length: the same two the other way round keep the other one.
	var flipped := Hud.tag_layout(_tags([b, a]), xf, VIEW)
	t.check(bool(flipped[0].show) and not bool(flipped[1].show) and (flipped[0].tag as MapTag).label == "TO THE TEMPLE",
		"the first-listed label is the one kept, whatever its length")
	# A partial overlap counts, and a label left out blocks nothing: `high` overlaps only the dropped `mid`.
	var low := MapTag.person(Vector2.ZERO, Color.RED, "INQUISITOR")
	var mid := MapTag.person(Vector2.ZERO, Color.RED, "INQUISITOR")
	mid.lift += 6.0
	var high := MapTag.person(Vector2.ZERO, Color.RED, "INQUISITOR")
	high.lift += 14.0
	var stack := Hud.tag_layout(_tags([low, mid, high]), xf, VIEW)
	t.check(bool(stack[0].show) and not bool(stack[1].show) and bool(stack[2].show),
		"a partial overlap counts, and a label left out blocks nothing")
	# By the screen's very edge a plain tag still shows; one with an arrow takes its arrow.
	var rim := Transform2D(0.0, Vector2(5.0, 180.0) - Iso.ground_to_screen(Vector2.ZERO))
	var rimmed := Hud.tag_layout(_tags([MapTag.person(Vector2.ZERO, Color.RED), MapTag.person(Vector2.ZERO, Color.RED, "WREN", true)]),
		rim, VIEW)
	t.check(String(rimmed[0].mode) == "map" and String(rimmed[1].mode) == "arrow",
		"by the screen's very edge a plain tag still shows; one with an arrow takes its arrow")
	t.check(Hud.plate_size("WREN") == Vector2(UiTheme.width("WREN", UiTheme.SIZE_SMALL) + 2.0, Hud.PLATE_H),
		"one plate measure: the words' width and a pixel each side")


static func _edge(t) -> void:
	var xf := Transform2D(0.0, MID)
	var far := Vector2(400.0, 0.0)
	var off := MapTag.person(far, Color.RED, "WREN")
	var arrow := MapTag.person(far, Color.RED, "WREN", true)
	var lay := Hud.tag_layout(_tags([off, arrow]), xf, VIEW)
	t.check(String(lay[0].mode) == "" and not bool(lay[0].show), "off screen without an arrow: nothing shown")
	var at: Vector2 = lay[1].arrow
	t.check(String(lay[1].mode) == "arrow" and Hud.tag_frame(VIEW).grow(0.5).has_point(at)
		and at.distance_to(Hud.frame_point(Hud.tag_point(arrow, xf), Hud.tag_frame(VIEW))) < 0.01,
		"off screen with one: an arrow at the edge, pointing its way (%s)" % at)
	var lr: Rect2 = lay[1].label
	t.check(bool(lay[1].show) and Rect2(Vector2.ZERO, VIEW).encloses(lr) and not lr.has_point(at),
		"its label beside it, inside the screen, clear of the tip (%s)" % lr)
	t.check(Hud.tag_frame(VIEW).has_point(MID) and not Hud.tag_frame(VIEW).has_point(Vector2(-5.0, 180.0))
		and not Hud.tag_frame(VIEW).has_point(Vector2(5.0, 180.0)), "the frame holds the middle, not the margin or beyond")


## The arrows' frame (v0.10 M6): below the clock, the Gaze bar and the events plate, above the slot row. A tag under the slot row or under
## the clock is pointed at from inside it; a plain tag there still shows.
static func _frame(t) -> void:
	var f := Hud.tag_frame(VIEW)
	t.check(f.position == Vector2(Hud.EDGE_MARGIN, Hud.TAG_TOP) and f.end.y <= Hud.SLOT_TOP and f.end.x == VIEW.x - Hud.EDGE_MARGIN,
		"the arrows' frame: in from the sides, below the clock and the events plate, above the slots (%s)" % f)
	var low := Transform2D(0.0, Vector2(320.0, 350.0) - Iso.ground_to_screen(Vector2.ZERO))
	var under := Hud.tag_layout(_tags([MapTag.place(Vector2.ZERO, Color.GOLD, "LANTERN"), MapTag.person(Vector2.ZERO, Color.RED)]),
		low, VIEW)
	t.check(String(under[0].mode) == "arrow" and (under[0].arrow as Vector2).y <= f.end.y + 0.01 and String(under[1].mode) == "map",
		"a place under the slot row is pointed at from above it; a plain tag there still shows")
	var high := Transform2D(0.0, Vector2(320.0, 30.0) - Iso.ground_to_screen(Vector2.ZERO))
	var over := Hud.tag_layout(_tags([MapTag.place(Vector2.ZERO, Color.GOLD, "TEMPLE")]), high, VIEW)
	t.check(String(over[0].mode) == "arrow" and absf((over[0].arrow as Vector2).y - Hud.TAG_TOP) < 0.01,
		"a place under the clock is pointed at from just below the events plate")
	t.check(Hud.edge_point(Vector2(900.0, 180.0), VIEW) == Vector2(VIEW.x - Hud.EDGE_MARGIN, 180.0),
		"The Warning's marker keeps its own frame: the whole screen, EDGE_MARGIN in")
