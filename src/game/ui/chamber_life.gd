class_name ChamberLife
extends RefCounted
## God's Chamber step 7 (docs/superpowers/specs/2026-11-26-kak-chamber-life-design.md): the room's idle life and its state objects, as
## data. `state()` reads what the room shows of the god (candles for the tier, cups for the conquered towns, the hourglass for the
## Lantern's Notice, the window and hourglass for the Hunt, the brazier for Faith to spend, the runes for points to spend, the Rite
## Door); `frame(t)` says what to draw at time t: the masks and patches of assets/chamber/life/ (built by
## concepts/chamber/build_chamber_art.py from the painting) with their alphas, and a few code-drawn pixels. No node, no clock, no
## random of its own: the same t and state always give the same frame, and nothing here can touch a night.
##
## A glow mask is a lit copy of the painting (each pixel's colour brightened by GLOW_BOOST, alpha = how lit it is), drawn with a
## normal blend: at alpha a it brightens the painted light by a x GLOW_BOOST, so no light moves by more than 25%.

## Off in FLOW, --capture and headless runs (Game, like GodChamber.transitions): the room is drawn at t = 0, the state still shown.
static var moving := true

const DIR := "life/"
const GLOW_BOOST := 0.25
## Comfort limits (design section 3): no light changes faster than MAX_RATE times a second; no pulse is shorter than MIN_PERIOD.
const MAX_RATE := 3
const MIN_PERIOD := 2.0
## The most pieces one frame draws (every state on, four candles out and smoking); about the design's 40 draw calls (measured 50).
const MAX_PIECES := 56
const CANDLES := 5

## Every mask and patch file with its room rect and layer (measured on the built wall.png / desk.png; the build script has the same).
const FILES := {
	"brazier_glow": {"layer": "wall", "rect": Rect2(582, 186, 40, 48)},
	"brazier_flame": {"layer": "wall", "rect": Rect2(588, 190, 26, 30)},
	"shelf_glow": {"layer": "wall", "rect": Rect2(512, 162, 32, 32)},
	"lantern_glow": {"layer": "wall", "rect": Rect2(298, 58, 34, 42)},
	"door_glow": {"layer": "wall", "rect": Rect2(140, 92, 70, 190)},
	"tree_glow": {"layer": "wall", "rect": Rect2(-15, 130, 75, 185)},
	"map_lit": {"layer": "wall", "rect": Rect2(215, 232, 200, 28)},
	"map_pins_0": {"layer": "wall", "rect": Rect2(215, 232, 200, 28)},
	"map_pins_1": {"layer": "wall", "rect": Rect2(215, 232, 200, 28)},
	"candle_lit_0": {"layer": "wall", "rect": Rect2(555, 205, 8, 25)},
	"candle_glow_0": {"layer": "wall", "rect": Rect2(555, 205, 8, 25)},
	"candle_glow_1": {"layer": "wall", "rect": Rect2(564, 203, 8, 25)},
	"candle_glow_2": {"layer": "wall", "rect": Rect2(574, 195, 8, 33)},
	"candle_glow_3": {"layer": "wall", "rect": Rect2(620, 203, 9, 33)},
	"candle_glow_4": {"layer": "wall", "rect": Rect2(630, 207, 9, 29)},
	"candle_out_0": {"layer": "wall", "rect": Rect2(555, 205, 8, 25)},
	"candle_out_1": {"layer": "wall", "rect": Rect2(564, 203, 8, 25)},
	"candle_out_2": {"layer": "wall", "rect": Rect2(574, 195, 8, 33)},
	"candle_out_3": {"layer": "wall", "rect": Rect2(620, 203, 9, 33)},
	"candle_out_4": {"layer": "wall", "rect": Rect2(630, 207, 9, 29)},
	"candle_warm_0": {"layer": "wall", "rect": Rect2(555, 205, 8, 25)},
	"candle_warm_1": {"layer": "wall", "rect": Rect2(564, 203, 8, 25)},
	"candle_warm_2": {"layer": "wall", "rect": Rect2(574, 195, 8, 33)},
	"candle_warm_3": {"layer": "wall", "rect": Rect2(620, 203, 9, 33)},
	"candle_warm_4": {"layer": "wall", "rect": Rect2(630, 207, 9, 29)},
	"trophy_gold_0": {"layer": "wall", "rect": Rect2(489, 78, 28, 25)},
	"trophy_dull_0": {"layer": "wall", "rect": Rect2(489, 78, 28, 25)},
	"trophy_glint_0": {"layer": "wall", "rect": Rect2(489, 78, 28, 25)},
	"trophy_gold_1": {"layer": "wall", "rect": Rect2(521, 77, 28, 25)},
	"trophy_dull_1": {"layer": "wall", "rect": Rect2(521, 77, 28, 25)},
	"trophy_glint_1": {"layer": "wall", "rect": Rect2(521, 77, 28, 25)},
	"window_red": {"layer": "wall", "rect": Rect2(280, 110, 75, 118)},
	"window_moon_red": {"layer": "wall", "rect": Rect2(320, 120, 22, 30)},
	"window_horizon": {"layer": "wall", "rect": Rect2(280, 110, 75, 118)},
	"window_stars_0": {"layer": "wall", "rect": Rect2(280, 110, 75, 118)},
	"window_stars_1": {"layer": "wall", "rect": Rect2(280, 110, 75, 118)},
	"window_stars_2": {"layer": "wall", "rect": Rect2(280, 110, 75, 118)},
	"desk_candle_glow": {"layer": "desk", "rect": Rect2(48, 283, 60, 60)},
	"hourglass_empty": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
	"hourglass_sand_low": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
	"hourglass_sand_up": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
	"hourglass_sand_low_red": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
	"hourglass_sand_up_red": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
	"hourglass_sand_glow": {"layer": "desk", "rect": Rect2(606, 300, 30, 47)},
}

## The moving sources: their glow (`tex`), how fast they may change (`rate`: smooth-noise knots a second) or pulse (`period` s),
## and the alpha range a flicker keeps to.
const SOURCES := [
	{"name": "brazier", "tex": "brazier_glow", "rect": Rect2(582, 186, 40, 48), "rate": 3.0, "alpha": Vector2(0.3, 1.0)},
	{"name": "altar candles", "tex": "candle_glow_0", "rect": Rect2(555, 195, 84, 41), "rate": 1.5, "alpha": Vector2(0.3, 0.95)},
	{"name": "unlit candles in the brazier's light", "tex": "candle_warm_0", "rect": Rect2(555, 195, 84, 41), "rate": 3.0,
		"alpha": Vector2(0.15, 0.6)},
	{"name": "unlit candles' smoke", "rect": Rect2(555, 185, 84, 40), "period": 11.0},
	{"name": "shelf candles", "tex": "shelf_glow", "rect": Rect2(512, 162, 32, 32), "rate": 1.5, "alpha": Vector2(0.3, 0.95)},
	{"name": "desk candle", "tex": "desk_candle_glow", "rect": Rect2(48, 283, 60, 60), "rate": 2.0, "alpha": Vector2(0.3, 1.0)},
	{"name": "lantern", "tex": "lantern_glow", "rect": Rect2(298, 58, 34, 42), "period": 4.0, "alpha": Vector2(0.15, 0.85)},
	{"name": "Rite Door", "tex": "door_glow", "rect": Rect2(140, 92, 70, 190), "period": 2.5, "alpha": Vector2(0.1, 0.95)},
	{"name": "Ability Tree runes", "tex": "tree_glow", "rect": Rect2(-15, 130, 75, 185), "period": 3.0, "fast_period": 2.0,
		"alpha": Vector2(0.1, 1.0)},
	{"name": "World table map", "tex": "map_lit", "rect": Rect2(215, 232, 200, 28), "period": 8.0},
	{"name": "map pins", "tex": "map_pins_0", "rect": Rect2(215, 232, 200, 28), "period": 2.4, "alpha": Vector2(0.0, 0.7)},
	{"name": "window stars", "tex": "window_stars_0", "rect": Rect2(280, 110, 75, 73), "rate": 1.0, "alpha": Vector2(0.0, 0.85)},
	{"name": "window sea", "rect": Rect2(284, 184, 66, 18), "period": 3.0},
	{"name": "trophy glint", "rect": Rect2(489, 77, 60, 26), "period": 6.0},
	{"name": "hourglass (the Hunt)", "tex": "hourglass_sand_glow", "rect": Rect2(606, 300, 30, 47), "period": 2.5, "alpha": Vector2(0.0, 1.0)},
]

## Index of a source in SOURCES, for its alpha range.
const BRAZIER := 0
const UNLIT := 2
const HOURGLASS := 14
## The fifth candle (the painting has four on the altar): candle 1's pixels moved CLONE_DX left, CLONE_SHORTER rows shorter and
## CLONE_LOWER rows lower (the build pass's CANDLE_CLONE, CLONE_SHORTER, CLONE_LOWER).
const CLONE_DX := -9
const CLONE_SHORTER := 4
const CLONE_LOWER := 2
## The top of each candle's dark wick once it is out (room units; printed by the build pass), where its smoke starts.
const WICKS := [Vector2(558, 217), Vector2(567, 211), Vector2(577, 202), Vector2(624, 213), Vector2(634, 209)]
## An unlit candle's smoke: now and then (SMOKE_CHANCE of its cycles, each SMOKE_PERIOD + i x SMOKE_STEP s) a thin wisp of
## SMOKE_PIXELS 1-unit pixels rises SMOKE_RISE units over SMOKE_TIME s, faint (at most SMOKE_ALPHA).
const SMOKE_PERIOD := 11.0
const SMOKE_STEP := 1.7
const SMOKE_CHANCE := 0.25
const SMOKE_TIME := 3.2
const SMOKE_RISE := 10.0
const SMOKE_PIXELS := 3
const SMOKE_ALPHA := 0.28
const SMOKE := Color(0.62, 0.58, 0.56)

## Where the moving pixels are (room units).
const SPARK_FROM := Vector2(600, 204)
const MOTES := Rect2(150, 150, 50, 125)
const SEA := Rect2(284, 184, 66, 18)
## The hourglass (desk layer): the rows of its lower and upper bulbs' sand in its mask (texture rows), and the stream's column.
const SAND_LOW := Vector2i(28, 42)
const SAND_UP := Vector2i(9, 21)
const STREAM_X := 620.0

const SPARK := Color(1.0, 0.62, 0.22)
const MOTE := Color(1.0, 0.86, 0.6)
const SHIMMER := Color(0.62, 0.78, 1.0)
const SAND := Color(0.76, 0.56, 0.38)

## What the room shows (state()); frame() reads it.
var st := {}


## The god's state as the room shows it: "lit" (candles, 1-5 by tier), "cups" (one per cup, in Conquest.towns() order: conquered),
## "sand" (the lower bulb, the Notice's fill 0-1), "hunt" (the Hunt is due), "high" (the brazier: Faith to spend, the Faith badge's
## rule), "fast" (the runes: points to spend, the Tree badge's rule) and "door" ("lit", "dim" or "closed", as GodChamber draws it).
static func state(slot: GodSlot, status: HubStatus) -> Dictionary:
	var towns := Conquest.towns()
	var cups := []
	for i in 2:
		cups.append(i < towns.size() and Conquest.conquered(slot, towns[i]))
	var door := "closed"
	if status.awaken_shown():
		door = "dim" if status.awaken_dim() else "lit"
	return {"lit": clampi(slot.tier, 1, CANDLES), "cups": cups, "sand": status.notice_fill(), "hunt": not GodNight.hunt_for(slot).is_empty(),
		"high": status.faith_affordable(), "fast": slot.points > 0, "door": door}


## A piece's rect on screen (frame units) with its layer's parallax shift; GodChamber also stretches the desk's in a very wide window.
static func placed(piece: Dictionary, mouse01: Vector2) -> Rect2:
	var r: Rect2 = piece.rect
	return Rect2(r.position + ChamberLayout.shift(piece.layer, mouse01), r.size)


## What to draw at time t, back to front: patches, glows, then moving pixels. Each piece is {"tex": a FILES name or "" for a pixel
## rect, "layer", "rect" (room units, where it is drawn), "alpha", and "src" (the texture region, for a band or a level) or "color"
## (a pixel rect's colour)}. With `moving` off it is the frame at t = 0.
func frame(t: float) -> Array:
	if not moving:
		t = 0.0
	var out: Array = []
	var lit: int = st.get("lit", 1)
	var high: bool = st.get("high", false)
	var hunt: bool = st.get("hunt", false)
	# Patches first: the candles that are out (and the fifth candle, which the painting has not), the cups, the emptied hourglass.
	var brazier_light := noise(1, t, 3.0)
	var unlit := SOURCES[UNLIT].alpha as Vector2
	for i in CANDLES:
		if i >= lit:
			out.append(_tex("candle_out_%d" % i, 1.0))
			out.append(_tex("candle_warm_%d" % i, lerpf(unlit.x, unlit.y, brazier_light)))
		elif i == 0:
			out.append(_tex("candle_lit_0", 1.0))
	var cups: Array = st.get("cups", [])
	for i in 2:
		var gleams: bool = i < cups.size() and cups[i]
		out.append(_tex(("trophy_gold_%d" if gleams else "trophy_dull_%d") % i, 1.0))
	out.append(_tex("hourglass_empty", 1.0))
	_sand(out, t, float(st.get("sand", 0.0)), hunt)
	if hunt:
		# The blood moon: the sky reddened, a red-orange glow on the horizon over the sea, the crescent red.
		out.append(_tex("window_red", 0.6))
		out.append(_tex("window_horizon", 0.9))
		out.append(_tex("window_moon_red", 1.0))
	# The lights: flickers by smooth noise, pulses by slow sines.
	var brazier := SOURCES[BRAZIER].alpha as Vector2
	var lo := lerpf(brazier.x, brazier.y, 0.4) if high else brazier.x
	out.append(_tex("brazier_glow", lerpf(lo, brazier.y, brazier_light)))
	if high:
		# Burning higher: the painted flame drawn again, taller, over itself.
		var r: Rect2 = FILES.brazier_flame.rect
		var h := r.size.y * (1.3 + 0.12 * noise(2, t, 3.0))
		out.append(_tex("brazier_flame", 0.7, Rect2(r.position.x, r.end.y - h, r.size.x, h)))
	var candle := SOURCES[1].alpha as Vector2
	for i in mini(lit, CANDLES):
		out.append(_tex("candle_glow_%d" % i, lerpf(candle.x, candle.y, noise(10 + i, t, 1.5))))
	out.append(_tex("shelf_glow", lerpf(candle.x, candle.y, noise(20, t, 1.5))))
	var desk := SOURCES[5].alpha as Vector2
	out.append(_tex("desk_candle_glow", lerpf(desk.x, desk.y, noise(21, t, 2.0))))
	out.append(_tex("lantern_glow", _pulse(t, 4.0, SOURCES[6].alpha, 0.0)))
	if st.get("door", "closed") == "lit":
		out.append(_tex("door_glow", _pulse(t, 2.5, SOURCES[7].alpha, 0.0)))
	var runes := Vector2(0.1, 0.6)
	if st.get("fast", false):
		runes = Vector2(0.4, 1.0)
	out.append(_tex("tree_glow", _pulse(t, 2.0 if st.get("fast", false) else 3.0, runes, 0.0)))
	_map(out, t)
	for g in 3:
		out.append(_tex("window_stars_%d" % g, lerpf(0.0, 0.85, noise(40 + g, t, 1.0))))
	_glints(out, t, cups)
	# Moving pixels.
	_sparks(out, t, 5 if high else 3)
	if st.get("door", "closed") == "lit":
		_motes(out, t)
	_sea(out, t)
	for i in range(lit, CANDLES):
		_smoke(out, t, i)
	return out


func _tex(name: String, alpha: float, rect := Rect2()) -> Dictionary:
	var row: Dictionary = FILES[name]
	return {"tex": name, "layer": row.layer, "rect": rect if rect.has_area() else row.rect, "alpha": alpha}


func _region(name: String, alpha: float, src: Rect2) -> Dictionary:
	var row: Dictionary = FILES[name]
	var r: Rect2 = row.rect
	return {"tex": name, "layer": row.layer, "rect": Rect2(r.position + src.position, src.size), "alpha": alpha, "src": src}


func _px(layer: String, rect: Rect2, color: Color, alpha: float) -> Dictionary:
	return {"tex": "", "layer": layer, "rect": rect, "alpha": alpha, "color": color}


## A slow sine between span.x and span.y, `period` seconds round, starting at the low end at t = 0 (plus `phase` of a turn).
static func _pulse(t: float, period: float, span: Vector2, phase: float) -> float:
	return lerpf(span.x, span.y, 0.5 - 0.5 * cos(TAU * (t / period + phase)))


## Smooth value noise in 0..1: `rate` random knots a second, eased between (so it turns at most `rate` times a second). Hashed from
## (seed, knot), so it is the same for the same t and needs no random generator.
static func noise(seed: int, t: float, rate: float) -> float:
	var x := maxf(t, 0.0) * rate
	var k := int(floor(x))
	var f := x - float(k)
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(hash01(seed, k), hash01(seed, k + 1), f)


## A number in 0..1 from two integers, the same every time.
static func hash01(a: int, b: int) -> float:
	var h := (a * 374761393 + b * 668265263 + 1442695041) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	h = h ^ (h >> 16)
	return float(h % 10007) / 10006.0


## The sand: the lower bulb filled to the Notice, the upper holding the rest, and while both hold some, a thin stream between. Under
## the Hunt the sand is red and the lower bulb's pulses (a lit copy over it, period 2.5 s, at most GLOW_BOOST brighter).
func _sand(out: Array, t: float, fill: float, hunt := false) -> void:
	fill = clampf(fill, 0.0, 1.0)
	var low_rows := SAND_LOW.y - SAND_LOW.x + 1
	var up_rows := SAND_UP.y - SAND_UP.x + 1
	var n := int(round(low_rows * fill))
	var m := int(round(up_rows * (1.0 - fill)))
	var red := "_red" if hunt else ""
	if n > 0:
		out.append(_region("hourglass_sand_low" + red, 1.0, Rect2(0, SAND_LOW.y + 1 - n, 30, n)))
		if hunt:
			out.append(_region("hourglass_sand_glow", _pulse(t, 2.5, SOURCES[HOURGLASS].alpha, 0.0), Rect2(0, SAND_LOW.y + 1 - n, 30, n)))
	if m > 0:
		out.append(_region("hourglass_sand_up" + red, 1.0, Rect2(0, SAND_UP.y + 1 - m, 30, m)))
	if n < low_rows and m > 0:
		var r: Rect2 = FILES.hourglass_empty.rect
		var top: float = r.position.y + SAND_UP.y + 1
		var bottom: float = r.position.y + SAND_LOW.y + 1 - n
		var length: float = bottom - top
		out.append(_px("desk", Rect2(STREAM_X, top, 1, length), SAND, 0.85))
		# A gap falls down the stream, so the sand is seen to run.
		var gap := fmod(t * 12.0, maxf(length, 1.0))
		out.append(_px("desk", Rect2(STREAM_X, top + floor(gap), 1, 1), Color(0.19, 0.13, 0.17), 1.0))


## The map: a soft band of light crossing the water every 8 s, and the town pins twinkling in two groups.
func _map(out: Array, t: float) -> void:
	var r: Rect2 = FILES.map_lit.rect
	var x: float = -24.0 + (r.size.x + 48.0) * fposmod(t / 8.0, 1.0)
	for band: Array in [[x - 12.0, 8.0, 0.45], [x - 4.0, 8.0, 0.9], [x + 4.0, 8.0, 0.45]]:
		var a := maxf(float(band[0]), 0.0)
		var b := minf(float(band[0]) + float(band[1]), r.size.x)
		if b > a:
			out.append(_region("map_lit", float(band[2]), Rect2(round(a), 0, round(b) - round(a), r.size.y)))
	for g in 2:
		out.append(_tex("map_pins_%d" % g, _pulse(t, 2.4, Vector2(0.0, 0.7), 0.5 * g)))


## A glint sweeping a conquered cup: a thin band of light across it in its first second of every 6, the two cups half a second apart.
func _glints(out: Array, t: float, cups: Array) -> void:
	for i in 2:
		if not (i < cups.size() and cups[i]):
			continue
		var p := fposmod(t - 0.5 * i, 6.0)
		if p >= 1.0:
			continue
		var w: float = FILES["trophy_glint_%d" % i].rect.size.x
		var x := roundf(-3.0 + (w + 3.0) * p)
		var a := maxf(x, 0.0)
		var b := minf(x + 3.0, w)
		if b > a:
			out.append(_region("trophy_glint_%d" % i, 0.8, Rect2(a, 0, b - a, 25)))


## Sparks rising off the brazier and fading, each on its own cycle.
func _sparks(out: Array, t: float, count: int) -> void:
	for j in count:
		var period := 1.7 + 0.2 * j
		var shifted := t + period * float(j) / float(count)
		var cycle := int(floor(shifted / period))
		var age := shifted - cycle * period
		var life := 0.8 + 0.7 * hash01(100 + j, cycle)
		if age >= life:
			continue
		var p := age / life
		var x := SPARK_FROM.x + (hash01(200 + j, cycle) - 0.5) * 14.0 + sin(p * 3.0 + j) * 2.0
		var y := SPARK_FROM.y - p * (24.0 + 12.0 * hash01(300 + j, cycle))
		out.append(_px("wall", Rect2(round(x), round(y), 1, 1), SPARK, 1.0 - p))


## Dust motes drifting slowly up through the Rite Door's light.
func _motes(out: Array, t: float) -> void:
	for j in 5:
		var x := MOTES.position.x + hash01(400, j) * MOTES.size.x + sin(t * 0.5 + j * 1.7) * 3.0
		var y := MOTES.end.y - fposmod(t * 4.0 + hash01(500, j) * MOTES.size.y, MOTES.size.y)
		var edge := minf(minf(y - MOTES.position.y, MOTES.end.y - y) / 20.0, 1.0)
		out.append(_px("wall", Rect2(round(x), round(y), 1, 1), MOTE, 0.45 * maxf(edge, 0.0)))


## Now and then a thin wisp of smoke rises from an unlit candle's wick: rare, slow and faint, on the candle's own cycle (hashed, so the
## same t gives the same wisp). Never at t = 0, so a still photograph shows none.
func _smoke(out: Array, t: float, i: int) -> void:
	var period := SMOKE_PERIOD + SMOKE_STEP * i
	var shifted := t + 2.1 * i
	var cycle := int(floor(shifted / period))
	var age := shifted - cycle * period - (period - SMOKE_TIME)
	if age < 0.0 or hash01(900 + i, cycle) >= SMOKE_CHANCE:
		return
	var wick: Vector2 = WICKS[i]
	for k in SMOKE_PIXELS:
		var p := age / SMOKE_TIME - 0.12 * k
		if p < 0.0 or p > 1.0:
			continue
		var x := wick.x + roundf(sin(p * 5.0 + i) * 1.2)
		var y := wick.y - 1.0 - roundf(p * SMOKE_RISE)
		out.append(_px("wall", Rect2(x, y, 1, 1), SMOKE, SMOKE_ALPHA * (1.0 - p) * (1.0 if k == 0 else 0.7)))


## Thin lines of moonlight moving slowly on the sea in the window.
func _sea(out: Array, t: float) -> void:
	for j in 4:
		var length: float = 3.0 + floor(hash01(600, j) * 3.0)
		var y: float = SEA.position.y + 1.0 + j * 4.0 + floor(hash01(700, j) * 3.0)
		var x: float = SEA.position.x + fposmod(t * (2.0 + j * 0.5) + hash01(800, j) * SEA.size.x, SEA.size.x - length)
		out.append(_px("wall", Rect2(round(x), y, length, 1), SHIMMER, _pulse(t, 3.0 + j * 0.4, Vector2(0.1, 0.45), 0.25 * j)))
