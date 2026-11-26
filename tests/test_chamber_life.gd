extends RefCounted
## God's Chamber step 7 (docs/superpowers/specs/2026-11-26-kak-chamber-life-design.md section 7): the room's life and state objects.
## Every source sits in the room and every mask or patch file matches its rect; the state follows the god (candles count the tier,
## cups the conquered towns, the hourglass the Notice, the window and hourglass the Hunt, the brazier and runes the badges' rules);
## a frame depends on t alone, stops with `moving` off, keeps the comfort limits, and rides the parallax. Section 9: the room's
## sound -- its cues in the catalog, its bed with the room, no take twice in a row, and a calm minute within bounds.


static func run(t) -> void:
	var was_moving := ChamberLife.moving
	ChamberLife.moving = true
	_files(t)
	_clone(t)
	_unlit(t)
	_blood_moon(t)
	_vignette(t)
	_closed_door(t)
	_rims(t)
	_state(t)
	_frames(t)
	_comfort(t)
	_parallax(t)
	_in_room(t)
	_sound_catalog(t)
	_sound_plan(t)
	_sound_with_room(t)
	ChamberLife.moving = was_moving


static func _slot(tier := 1, points := 0, faith := 0, notice := 0) -> GodSlot:
	var g := GodSlot.make(1, "ruin", 77)
	g.tier = tier
	g.level = tier * 10 - 5
	g.points = points
	g.faith = faith
	g.notice = notice
	return g


static func _st(g: GodSlot) -> Dictionary:
	return ChamberLife.state(g, HubStatus.new(g))


static func _files(t) -> void:
	t.check(ChamberLife.FILES.size() >= 30, "the life pass has its masks and patches (%d)" % ChamberLife.FILES.size())
	var bad := ""
	for name: String in ChamberLife.FILES:
		var row: Dictionary = ChamberLife.FILES[name]
		var tex := ChamberArt.texture("life/" + name)
		var r: Rect2 = row.rect
		if tex == null:
			bad += " %s(missing)" % name
		elif Vector2(tex.get_size()) != r.size:
			bad += " %s(%s vs %s)" % [name, tex.get_size(), r.size]
	t.check(bad == "", "every mask and patch file exists and matches its rect's size (not:%s)" % bad)


static func _in_room(t) -> void:
	var out := ""
	for name: String in ChamberLife.FILES:
		var r: Rect2 = ChamberLife.FILES[name].rect
		if not ChamberLayout.ROOM.encloses(r):
			out += " " + name
	t.check(out == "", "every source rect lies inside the room (not:%s)" % out)
	for src: Dictionary in ChamberLife.SOURCES:
		t.check(ChamberLayout.ROOM.encloses(src.rect), "source %s lies inside the room" % src.name)


static func _lit(frame: Array) -> int:
	var n := 0
	for p: Dictionary in frame:
		if String(p.get("tex", "")).begins_with("candle_glow_"):
			n += 1
	return n


static func _has(frame: Array, tex: String) -> bool:
	for p: Dictionary in frame:
		if p.get("tex", "") == tex:
			return true
	return false


static func _state(t) -> void:
	var life := ChamberLife.new()
	for tier in range(1, 6):
		var st := _st(_slot(tier))
		life.st = st
		var f := life.frame(1.0)
		t.check(st.lit == tier and _lit(f) == tier, "tier %d lights %d candles (state %d, glows %d)" % [tier, tier, st.lit, _lit(f)])
		var outs := 0
		for i in ChamberLife.CANDLES:
			outs += 1 if _has(f, "candle_out_%d" % i) else 0
		t.check(outs == ChamberLife.CANDLES - tier, "tier %d: the other %d candles are out" % [tier, ChamberLife.CANDLES - tier])
	var lo := _slot(1)
	lo.tier = 0
	var hi := _slot(5)
	hi.tier = 9
	t.check(_st(lo).lit == 1 and _st(hi).lit == 5, "the candles clamp outside tiers 1-5 (%d, %d)" % [_st(lo).lit, _st(hi).lit])
	t.check(_has(life.frame(0.0), "candle_lit_0"), "the fifth candle (cloned from the painting) is drawn while lit")

	# The cups: one per town in Conquest.towns() order, gleaming once conquered.
	var towns := Conquest.towns()
	t.check(towns.size() >= 2 and towns[0] == "aldermere" and towns[1] == "capital", "the cups follow Aldermere, then the Capital")
	var g := _slot(3)
	t.check(_st(g).cups == [false, false], "no town conquered: both cups dull (%s)" % [_st(g).cups])
	g.believers["capital"] = Conquest.population("capital")
	g.opened.append("capital")
	t.check(_st(g).cups == [false, true], "the Capital conquered: the second cup gleams (%s)" % [_st(g).cups])
	g.believers["aldermere"] = Conquest.population("aldermere")
	life.st = _st(g)
	t.check(life.st.cups == [true, true], "both conquered: both gleam")
	var f2 := life.frame(0.0)
	t.check(_has(f2, "trophy_gold_0") and _has(f2, "trophy_gold_1") and not _has(f2, "trophy_dull_0"), "gleaming cups draw gold")
	var glint := false
	for k in 120:
		glint = glint or _has(life.frame(k * 0.05), "trophy_glint_1")
	t.check(glint, "a glint sweeps a conquered cup within its 6 s")
	life.st = _st(_slot(3))
	t.check(_has(life.frame(0.0), "trophy_dull_1") and not _has(life.frame(0.0), "trophy_gold_1"), "an unconquered cup is dull")

	# The hourglass: the sand in the lower bulb is the Notice.
	for notice in [0, 30, 70, 100]:
		var s := _st(_slot(2, 0, 0, notice))
		t.check(is_equal_approx(s.sand, notice / 100.0), "Notice %d fills the lower bulb to %.2f (%.2f)" % [notice, notice / 100.0, s.sand])
	life.st = _st(_slot(2, 0, 0, 0))
	var empty := _sand_rows(life.frame(0.0))
	life.st = _st(_slot(2, 0, 0, 60))
	var mid := _sand_rows(life.frame(0.0))
	life.st = _st(_slot(2, 0, 0, 99))
	var full := _sand_rows(life.frame(0.0))
	t.check(empty < mid and mid < full, "more Notice, more sand below (%d < %d < %d rows)" % [empty, mid, full])

	# The Hunt: the window and the hourglass turn red.
	var calm := _st(_slot(2, 0, 0, 40))
	var hunt_slot := _slot(2, 0, 0, GodSlot.NOTICE_MAX)
	var hunt := _st(hunt_slot)
	t.check(not calm.hunt and hunt.hunt == not GodNight.hunt_for(hunt_slot).is_empty() and hunt.hunt, "the Hunt is due at a full Notice")
	life.st = hunt
	var fh := life.frame(0.0)
	t.check(_has(fh, "window_red") and _has(fh, "window_moon_red") and _has(fh, "hourglass_sand_low_red"), "the Hunt turns the window and the hourglass red")
	life.st = calm
	var fc := life.frame(0.0)
	t.check(not _has(fc, "window_red") and not _has(fc, "hourglass_sand_low_red"), "no Hunt: the night sky as painted")

	# The brazier and the runes follow the badges' rules exactly.
	GodChamber.transitions = false
	for pts in [0, 2]:
		for faith in [0, 5, 500]:
			var gs := _slot(2, pts, faith)
			var ch := GodChamber.new().setup(gs)
			var s := _st(gs)
			t.check(s.high == ch.badge("faith") and s.fast == ch.badge("tree"),
				"points %d faith %d: brazier high %s = Faith badge, runes fast %s = Tree badge" % [pts, faith, s.high, s.fast])
			ch.free()
	life.st = _st(_slot(2, 0, 500))
	t.check(life.st.high and _has(life.frame(0.5), "brazier_flame"), "Faith to spend: the brazier burns higher")
	life.st = _st(_slot(2, 0, 0))
	t.check(not life.st.high and not _has(life.frame(0.5), "brazier_flame"), "no Faith to spend: the brazier as painted")


static func _sand_rows(frame: Array) -> int:
	for p: Dictionary in frame:
		if p.get("tex", "") == "hourglass_sand_low" or p.get("tex", "") == "hourglass_sand_low_red":
			return int((p.rect as Rect2).size.y)
	return 0


static func _frames(t) -> void:
	var life := ChamberLife.new()
	var g := _slot(3, 2, 500, 50)
	life.st = _st(g)
	t.check(str(life.frame(3.7)) == str(life.frame(3.7)), "the same t gives the same frame")
	t.check(str(life.frame(3.7)) != str(life.frame(4.1)), "the room moves at rest")
	ChamberLife.moving = false
	t.check(str(life.frame(0.0)) == str(life.frame(5.5)) and str(life.frame(0.0)) == str(life.frame(123.4)), "moving off: the frame does not change with t")
	t.check(_lit(life.frame(9.0)) == 3 and _has(life.frame(9.0), "brazier_flame"), "moving off: the state objects are still shown")
	ChamberLife.moving = true
	# Two rooms at once give the same frame: no clock and no random of their own beyond t.
	var other := ChamberLife.new()
	other.st = life.st
	t.check(str(other.frame(7.25)) == str(life.frame(7.25)), "two rooms at the same t agree")
	var most := 0
	var hunt := _slot(5, 2, 500, GodSlot.NOTICE_MAX)
	hunt.believers["aldermere"] = Conquest.population("aldermere")
	for tier in [1, 5]:
		hunt.tier = tier
		life.st = _st(hunt)
		life.st.door = "lit"
		for k in 600:
			most = maxi(most, life.frame(k * 0.137).size())
	t.check(most <= ChamberLife.MAX_PIECES, "at most %d pieces a frame with every state on (%d)" % [ChamberLife.MAX_PIECES, most])
	var t0 := Time.get_ticks_usec()
	for k in 600:
		life.frame(k / 60.0)
	var per := float(Time.get_ticks_usec() - t0) / 600.0
	t.check(per < 300.0, "a frame's life costs under 0.3 ms to work out (%.0f us)" % per)


static func _comfort(t) -> void:
	for src: Dictionary in ChamberLife.SOURCES:
		if src.has("rate"):
			t.check(float(src.rate) <= ChamberLife.MAX_RATE, "%s changes at most %d times a second (%s)" % [src.name, ChamberLife.MAX_RATE, src.rate])
		if src.has("period"):
			t.check(float(src.period) >= ChamberLife.MIN_PERIOD, "%s pulses no shorter than 2 s (%s)" % [src.name, src.period])
		if src.has("fast_period"):
			t.check(float(src.fast_period) >= ChamberLife.MIN_PERIOD, "%s's fast pulse is no shorter than 2 s" % src.name)
	# Every glow's alpha stays inside its bounds, and its swing times the mask's boost is at most 25% of the light.
	var life := ChamberLife.new()
	var g := _slot(5, 2, 500, GodSlot.NOTICE_MAX)
	g.believers["aldermere"] = Conquest.population("aldermere")
	g.believers["capital"] = Conquest.population("capital")
	life.st = _st(g)
	life.st.door = "lit"
	var bounds := {}
	for src: Dictionary in ChamberLife.SOURCES:
		if src.has("alpha"):
			bounds[src.tex] = src.alpha
			var a: Vector2 = src.alpha
			t.check((a.y - a.x) * ChamberLife.GLOW_BOOST <= 0.25 + 0.0001 and a.x >= 0.0 and a.y <= 1.0,
				"%s moves the light by at most 25%% (alpha %s)" % [src.name, a])
	var outside := ""
	for k in 400:
		for p: Dictionary in life.frame(k * 0.0731):
			var tex: String = p.get("tex", "")
			if bounds.has(tex):
				var a: Vector2 = bounds[tex]
				if p.alpha < a.x - 0.0001 or p.alpha > a.y + 0.0001:
					outside += " %s=%.2f" % [tex, p.alpha]
	t.check(outside == "", "every flicker's alpha stays within its bounds (not:%s)" % outside.left(200))
	# No light changes faster than 3 times a second: sampled at 60 fps, a flicker's alpha turns (rises after falling) at most
	# 3 times in any second.
	var turns := {}
	var last := {}
	var dir := {}
	for k in 600:
		for p: Dictionary in life.frame(k / 60.0):
			var tex: String = p.get("tex", "")
			if not bounds.has(tex):
				continue
			if last.has(tex):
				var d := signf(p.alpha - last[tex])
				if d != 0.0 and dir.has(tex) and d != dir[tex]:
					turns[tex] = int(turns.get(tex, 0)) + 1
				if d != 0.0:
					dir[tex] = d
			last[tex] = p.alpha
	var fast := ""
	for tex: String in turns:
		if int(turns[tex]) > ChamberLife.MAX_RATE * 10 + 1:
			fast += " %s(%d)" % [tex, turns[tex]]
	t.check(fast == "", "no light turns more than %d times a second over 10 s (not:%s)" % [ChamberLife.MAX_RATE, fast])


static func _parallax(t) -> void:
	var life := ChamberLife.new()
	life.st = _st(_slot(3, 2, 500, 50))
	var f := life.frame(2.0)
	var mouse := Vector2(0.8, -0.6)
	var wall_shift := ChamberLayout.shift("wall", mouse)
	var desk_shift := ChamberLayout.shift("desk", mouse)
	var bad := ""
	var layers := {}
	for p: Dictionary in f:
		var r := ChamberLife.placed(p, mouse)
		var want: Vector2 = (p.rect as Rect2).position + (desk_shift if p.layer == "desk" else wall_shift)
		layers[p.layer] = true
		if r.position != want or r.size != (p.rect as Rect2).size:
			bad += " " + str(p.get("tex", "px"))
	t.check(bad == "" and layers.has("wall") and layers.has("desk"), "life pieces move with their layer's parallax shift (not:%s)" % bad)
	t.check(wall_shift != desk_shift, "the desk's pieces move more than the wall's")


# --- round 2: the fifth candle, unlit wax and smoke, the blood moon ------------------------------------------------------------------

static func _image(name: String) -> Image:
	return ChamberArt.texture(name).get_image()


## The candle's own pixels in `img` (warm, lit wax or flame, or near white), as room rows and columns: [left, right, top, bottom].
static func _extent(img: Image, origin: Vector2, only_opaque: bool) -> Array:
	var box := [INF, -INF, INF, -INF]
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var warm := (c.h < 0.15 or c.h > 0.95) and c.s > 0.2 and c.v > 0.55 or c.s < 0.12 and c.v > 0.9
			if only_opaque or warm:
				box = [minf(box[0], origin.x + x), maxf(box[1], origin.x + x), minf(box[2], origin.y + y), maxf(box[3], origin.y + y)]
	return box


static func _clone(t) -> void:
	# The fifth candle is candle 1 moved left, shorter and standing lower, so it is no twin of its neighbour.
	var wall := _image("wall")
	var r1: Rect2 = ChamberLife.FILES.candle_out_1.rect
	var src := _extent(wall.get_region(Rect2i(int(r1.position.x) + 100, int(r1.position.y), int(r1.size.x), int(r1.size.y))), r1.position, false)
	var r0: Rect2 = ChamberLife.FILES.candle_lit_0.rect
	var copy := _extent(_image("life/candle_lit_0"), r0.position, true)
	t.check(copy[0] == src[0] + ChamberLife.CLONE_DX, "the fifth candle stands %d units left of candle 1 (%s vs %s)" % [-ChamberLife.CLONE_DX, copy[0], src[0]])
	t.check(copy[3] == src[3] + ChamberLife.CLONE_LOWER, "its base is %d units lower (%s vs %s)" % [ChamberLife.CLONE_LOWER, copy[3], src[3]])
	var h_src: float = src[3] - src[2]
	var h_copy: float = copy[3] - copy[2]
	t.check(h_copy == h_src - ChamberLife.CLONE_SHORTER and ChamberLife.CLONE_SHORTER >= 3 and ChamberLife.CLONE_SHORTER <= 4,
		"and it is %d units shorter (%s vs %s)" % [ChamberLife.CLONE_SHORTER, h_copy, h_src])
	t.check(ChamberLife.FILES.candle_glow_0.rect == r0 and ChamberLife.FILES.candle_out_0.rect == r0 and ChamberLife.FILES.candle_warm_0.rect == r0,
		"its flame, glow and unlit picture sit where it stands")


static func _unlit(t) -> void:
	# A put-out candle keeps warm wax, only darker: of the pixels it changes, none is lit (no flame, no pale wax) and every one with
	# any light is warm and coloured, never grey.
	var wall := _image("wall")
	var grey := ""
	var lit := 0
	for i in ChamberLife.CANDLES:
		var r: Rect2 = ChamberLife.FILES["candle_out_%d" % i].rect
		var img := _image("life/candle_out_%d" % i)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				var w := wall.get_pixel(int(r.position.x) + 100 + x, int(r.position.y) + y)
				if c.is_equal_approx(w):
					continue
				if c.v > 0.8:
					lit += 1
				if c.v > 0.25 and not ((c.h < 0.12 or c.h > 0.95) and c.s >= 0.35 and c.v <= 0.75):
					grey += " %d:(%d,%d)" % [i, x, y]
	t.check(lit == 0, "a put-out candle shows no flame and no lit wax (%d pixels)" % lit)
	t.check(grey == "", "its wax stays warm, only darker (not:%s)" % grey.left(160))
	var life := ChamberLife.new()
	life.st = _st(_slot(2))
	var f := life.frame(1.0)
	var warm := 0
	for i in ChamberLife.CANDLES:
		warm += 1 if _has(f, "candle_warm_%d" % i) else 0
	t.check(warm == 3 and not _has(f, "candle_warm_0") and not _has(f, "candle_warm_1"), "the brazier lights the three put-out candles, not the lit ones")
	# Smoke: now and then a faint wisp from an unlit wick, never from a lit one, never at rest (t = 0).
	life.st = _st(_slot(1))
	var smoke := 0
	var frames := 0
	var faint := true
	var from_lit := false
	for k in 3600:
		var any := false
		for p: Dictionary in life.frame(k / 60.0):
			if p.tex == "" and (p.color as Color).is_equal_approx(ChamberLife.SMOKE):
				smoke += 1
				any = true
				faint = faint and p.alpha <= ChamberLife.SMOKE_ALPHA + 0.0001
				from_lit = from_lit or absf((p.rect as Rect2).position.x - ChamberLife.WICKS[0].x) < 2.0
		frames += 1 if any else 0
	t.check(smoke > 0 and faint and not from_lit, "unlit candles smoke now and then, faintly, the lit one never (%d smoke pixels in 60 s)" % smoke)
	var still := false
	for p: Dictionary in life.frame(0.0):
		still = still or p.tex == "" and (p.color as Color).is_equal_approx(ChamberLife.SMOKE)
	t.check(not still, "no smoke in the still room (t = 0)")
	t.check(frames < 3600 * 0.4, "and it is rare: four put-out candles smoke in %d of 3600 frames" % frames)


static func _blood_moon(t) -> void:
	var life := ChamberLife.new()
	var g := _slot(3, 0, 0, GodSlot.NOTICE_MAX)
	life.st = _st(g)
	var f := life.frame(0.0)
	for tex in ["window_red", "window_horizon", "window_moon_red", "hourglass_sand_low_red"]:
		t.check(_has(f, tex), "the Hunt due: %s is drawn" % tex)
	t.check(not _has(f, "hourglass_sand_low"), "the Hunt due: the sand is red, not as painted")
	var stars := 0.0
	var calm_stars := 0.0
	var calm := ChamberLife.new()
	calm.st = _st(_slot(3, 0, 0, 40))
	for k in 60:
		for p: Dictionary in life.frame(k * 0.5):
			if String(p.tex).begins_with("window_stars_"):
				stars += p.alpha
		for p: Dictionary in calm.frame(k * 0.5):
			if String(p.tex).begins_with("window_stars_"):
				calm_stars += p.alpha
	t.check(is_equal_approx(stars, calm_stars), "the stars keep twinkling under the blood moon (%.1f vs %.1f)" % [stars, calm_stars])
	# The red sand pulses: a lit copy over it, period >= 2 s, at most 25% brighter.
	var lo := INF
	var hi := -INF
	for k in 300:
		for p: Dictionary in life.frame(k / 60.0):
			if p.tex == "hourglass_sand_glow":
				lo = minf(lo, p.alpha)
				hi = maxf(hi, p.alpha)
	t.check(hi > lo and (hi - lo) * ChamberLife.GLOW_BOOST <= 0.25 + 0.0001, "the red sand pulses by at most 25%% (alpha %.2f-%.2f)" % [lo, hi])
	var src: Dictionary = ChamberLife.SOURCES[ChamberLife.HOURGLASS]
	t.check(src.tex == "hourglass_sand_glow" and float(src.period) >= ChamberLife.MIN_PERIOD, "its pulse is no shorter than 2 s (%s)" % src.period)
	calm.st = _st(_slot(3, 0, 0, 40))
	var fc := calm.frame(0.0)
	t.check(not _has(fc, "window_horizon") and not _has(fc, "window_moon_red") and not _has(fc, "hourglass_sand_glow"), "no Hunt: no blood moon")


# --- round 3: the vignette, the closed door's stone -----------------------------------------------------------------------------------

static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


static func _vignette(t) -> void:
	var v := _image("life/vignette")
	t.check(v != null and v.get_size() == Vector2i(840, 360), "the vignette covers the room")
	if v == null:
		return
	var a := func(x: int, y: int) -> float: return v.get_pixel(x + 100, y).a
	# The frame's top corners, the side walls and the ceiling darken 15-20% (the bottom corners are the tree's stone, the altar and the
	# desk); the room's middle not at all.
	var corners: Array = [a.call(2, 24), a.call(637, 24), a.call(2, 100), a.call(637, 120)]
	var ok := true
	for c: float in corners:
		ok = ok and c >= 0.15 and c <= 0.2001
	t.check(ok, "the frame's corners and side walls darken by 15-20%% (%s)" % [corners])
	t.check(a.call(320, 200) <= 0.01, "the room's middle is not darkened (%.3f)" % a.call(320, 200))
	t.check(a.call(320, 30) >= 0.12 and a.call(320, 30) <= 0.2001, "the ceiling darkens (%.2f)" % a.call(320, 30))
	var most := 0.0
	for y in 360:
		for x in 840:
			most = maxf(most, v.get_pixel(x, y).a)
	t.check(most <= 0.2001, "nowhere more than 20%% (%.3f)" % most)
	# Not the four stations: their middles and most of their pictures are left alone.
	for key: String in ChamberLayout.ORDER:
		var r: Rect2 = ChamberLayout.STATIONS[key].rect
		var c := r.get_center()
		t.check(a.call(int(c.x), int(c.y)) <= 0.01, "%s is not darkened (%.3f)" % [key, a.call(int(c.x), int(c.y))])
	# The map table stays the brightest object in the room after it.
	var wall := _image("wall")
	var mean := func(r: Rect2) -> float:
		var sum := 0.0
		for y in range(int(r.position.y), int(r.end.y)):
			for x in range(int(r.position.x), int(r.end.x)):
				sum += _lum(wall.get_pixel(x + 100, y)) * (1.0 - v.get_pixel(x + 100, y).a)
		return sum / (r.size.x * r.size.y)
	var map: float = mean.call(Rect2(222, 235, 186, 21))
	var brightest := true
	for r: Rect2 in [Rect2(122, 82, 112, 148), Rect2(553, 194, 87, 104), Rect2(2, 130, 56, 152), Rect2(282, 112, 70, 110), Rect2(302, 64, 25, 30)]:
		brightest = brightest and mean.call(r) < map
	t.check(brightest, "the map table stays the brightest object (%.3f)" % map)
	var life := ChamberLife.new()
	life.st = _st(_slot(2))
	t.check(_has(life.frame(0.0), "vignette") == false, "the vignette is not a life piece (GodChamber draws it under the life)")


static func _closed_door(t) -> void:
	# The closed door's put-out light is cool stone like the wall's (red over green, blue highest), never green or teal: of the
	# pixels the closed patch recolours, none has more green than red.
	var img := ChamberArt.texture("awaken_closed").get_image()
	var lit := ChamberArt.texture("awaken").get_image()
	var green := 0
	var changed := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.05 or c.is_equal_approx(lit.get_pixel(x, y)):
				continue
			changed += 1
			if c.g > c.r + 0.01:
				green += 1
	t.check(changed > 500 and green == 0, "no green-dominant pixel in the closed door's stone (%d of %d recoloured)" % [green, changed])


## Round 3b: the hover rims follow the painting, traced from its pixels. No rim has a straight horizontal or vertical run longer than
## its station's pin, and a pin is long only where the painted object's edge is straight: the World Table's top and front edges, the
## tree stone's right side (the dark seam that parts it from the wall), the altar's right side (the pillar at the painting's edge),
## the Rite Door's step. [longest horizontal, longest vertical in the left half, longest vertical in the right half]
const RIM_PINS := {
	"descend": [224, 14, 14],
	"tree": [16, 22, 110],
	"faith": [10, 26, 62],
	"awaken": [130, 28, 28],
}


static func _longest(img: Image, horizontal: bool, from: int, to: int) -> int:
	var best := 0
	var w := img.get_width()
	var h := img.get_height()
	if horizontal:
		for y in h:
			var n := 0
			for x in w:
				n = n + 1 if img.get_pixel(x, y).a > 0.5 else 0
				best = maxi(best, n)
	else:
		for x in range(from, to):
			var n := 0
			for y in h:
				n = n + 1 if img.get_pixel(x, y).a > 0.5 else 0
				best = maxi(best, n)
	return best


static func _rims(t) -> void:
	for key: String in RIM_PINS:
		var img := _image("life/rim_" + key)
		var pin: Array = RIM_PINS[key]
		var half := img.get_width() / 2
		var runs := [_longest(img, true, 0, 0), _longest(img, false, 0, half), _longest(img, false, half, img.get_width())]
		t.check(runs[0] <= pin[0] and runs[1] <= pin[1] and runs[2] <= pin[2],
			"%s's rim follows the painting: straight runs %s within its pins %s" % [key, runs, pin])
	# The altar's left side, the one that read as a box edge, is no longer one long line.
	var altar := _longest(_image("life/rim_faith"), false, 0, 50)
	t.check(altar <= 26, "the altar's rim has no long straight left side (%d px)" % altar)


# --- the room's sound (section 9) --------------------------------------------------------------------------------------------------------

static func _sound_catalog(t) -> void:
	var missing := ""
	for cue: StringName in ChamberSound.CUES:
		if not Sfx.CATALOG.has(cue):
			missing += " " + cue
			continue
		for path in Sfx.paths_for(cue):
			if not ResourceLoader.exists(path):
				missing += " " + path.get_file()
	t.check(missing == "", "every room cue is in the Sfx catalog with its takes (not:%s)" % missing)
	t.check(bool(Sfx.CATALOG.get(ChamberSound.BED, {}).get("loop", false)), "the room's bed loops")
	for cue: StringName in ChamberSound.KINDS:
		t.check(Sfx.paths_for(cue).size() >= 2, "%s has at least two takes" % cue)


static func _sound_plan(t) -> void:
	var worst := 0
	var total := 0
	var repeats := 0
	var kinds_twice := 0
	for seed in 20:
		var plan := ChamberSound.new()
		plan.setup(_st(_slot(3, 0, 0, 40)), seed)
		var heard := plan.calm_minute()
		worst = maxi(worst, heard.size())
		total += heard.size()
		var last_path := ""
		var last_cue := ""
		for e: Dictionary in heard:
			repeats += 1 if e.path == last_path else 0
			kinds_twice += 1 if e.cue == last_cue else 0
			last_path = e.path
			last_cue = e.cue
		plan.free()
	t.check(worst <= ChamberSound.MAX_PER_MINUTE and total >= 20 * 3,
		"a calm minute has at most %d room sounds (worst %d, mean %.1f)" % [ChamberSound.MAX_PER_MINUTE, worst, total / 20.0])
	t.check(repeats == 0 and kinds_twice == 0, "no take and no kind twice in a row (%d, %d)" % [repeats, kinds_twice])
	# The Hunt makes the wind a moan; a burning-high brazier lets its logs settle louder.
	var plan := ChamberSound.new()
	plan.setup(_st(_slot(3, 0, 0, GodSlot.NOTICE_MAX)), 3)
	var cues := {}
	for k in 40:
		for e: Dictionary in plan.calm_minute():
			cues[e.cue] = true
	t.check(cues.has(&"chamber_moan") and not cues.has(&"chamber_wind"), "the Hunt's sky moans instead of the wind (%s)" % [cues.keys()])
	t.check(not cues.has(&"chamber_sand"), "a full hourglass makes no sand hiss")
	plan.free()
	# State sounds: once, on entering, the first time the state is seen.
	ChamberSound.heard.clear()
	var g := _slot(3, 0, 0, GodSlot.NOTICE_MAX)
	g.believers["aldermere"] = Conquest.population("aldermere")
	var first := ChamberSound.new()
	first.setup(_st(g), 1)
	var opening := first.step(1.5)
	var names := opening.map(func(e: Dictionary) -> StringName: return e.cue)
	t.check(names.has(&"chamber_chime") and names.has(&"chamber_swell"), "a cup's first gleam chimes and the Hunt swells on entering (%s)" % [names])
	first.free()
	var again := ChamberSound.new()
	again.setup(_st(g), 1)
	names = again.step(1.5).map(func(e: Dictionary) -> StringName: return e.cue)
	t.check(not names.has(&"chamber_chime") and not names.has(&"chamber_swell"), "and not again the next time (%s)" % [names])
	again.free()
	ChamberSound.heard.clear()


static func _sound_with_room(t) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	GodChamber.transitions = false
	var was := ChamberSound.enabled
	var forced := ChamberSound.force
	ChamberSound.enabled = false
	var quiet := GodChamber.new()
	tree.root.add_child(quiet)
	quiet.setup(_slot(2))
	t.check(quiet.room_sound() == null, "sound off (FLOW, --capture, headless): no room sound")
	quiet.free()
	ChamberSound.enabled = true
	ChamberSound.force = true
	var room := GodChamber.new()
	tree.root.add_child(room)
	room.setup(_slot(2))
	var snd := room.room_sound()
	t.check(snd != null and snd.bed_target() > 0.0, "the bed starts with the room")
	room.status.awaken = ""
	room._press("tree")
	t.check(snd != null and snd.bed_target() == 0.0, "and fades when a page opens")
	room.free()
	t.check(not is_instance_valid(snd), "and is gone with the room")
	ChamberSound.enabled = was
	ChamberSound.force = forced
