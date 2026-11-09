class_name AnathemaFx
extends FxTimeline
## Anathema (Dominion, Tier IV): the district is told what its buildings are. Every standing building within RADIUS of
## the click (MARKED roles; never the Citadel) is marked for SPAN (Crowd.mark_structure()), T_CAST after the cast. The
## mark is the cast's mode:
##   CURSED    the buildings are damned. Nobody will be inside one: a shelter among them empties, its people running,
##             and takes nobody in (ShelterManager); a fire on one is left to burn (FireManager: no crew turns out, the
##             crew at it stands down); the keeper will not climb a cursed Bell Tower (BellNetwork); and whoever stands
##             idle within SHUN_R of one walks away from it.
##   HALLOWED  the buildings are holy, and everyone must be inside. Each citizen within RADIUS goes into the nearest
##             hallowed building that takes people (ShelterManager.send_in(): past its capacity) and stays there
##             whatever happens to it -- struck, burning, the town evacuating -- until the mark lifts or it falls on
##             them; with no such building in the district they crowd its nearest door instead.
## The god touches no stone: the buildings are whole, and what they are for is gone, or is a tomb. Quiet, but for the
## book entry's "alarm". The cast locks the other slots until the marks are laid.

const RADIUS := 6.0
const SPAN := 40.0
const T_CAST := 1.0
const SHUN_R := 1.2
const SHUN_EVERY := 1.0
const SHUN_WALK := 2.5
## Spreading Mark (level 5): a building this near a marked one's footprint takes the mark SPREAD_AT s after.
const SPREAD_R := 3.0
const SPREAD_AT := 20.0
const MARKED := [&"house", &"tower", &"temple", &"barracks", &"market", &"dock", &"farm"]
const CURSED := &"cursed"
const HALLOWED := &"hallowed"
const CURSE := Color("9a5cff")
const HALLOW := Color("ffe9a8")
const CURSE_LIFE := [Color("c8a0ff"), Color("7a3cf0"), Color("3b1470"), Color(0.1, 0.03, 0.18, 0.55)]
## The curse's sign: a cross struck through.
const DAMNED: Array[int] = [0b10001, 0b01010, 0b00100, 0b01010, 0b10001]

var mark := CURSED
## The buildings marked, and how many people it moved (shunned off, or sent in).
var buildings: Array[Structure] = []
var moved := 0
## Level 5 (Spreading Mark): the buildings the mark spread to.
var spread: Array[Structure] = []

var _shun_in := 0.0
var _motes_in := 0.0
## This cast's district and span at its ability level (RADIUS and SPAN at level 1).
var lv_radius := RADIUS
var lv_span := SPAN
var _twist := false


## The buildings a cast at `at` would mark.
static func marked_at(env: EnvironmentField, at: Vector2, r := RADIUS) -> Array[Structure]:
	var out: Array[Structure] = []
	for s in env.near(at, r):
		if is_instance_valid(s) and not s.destroyed and s.role in MARKED and s.center().distance_to(at) <= r:
			out.append(s)
	return out


func _build() -> void:
	lv_radius = float(PowerBook.stat(extra, "anathema", "RADIUS", RADIUS))
	lv_span = float(PowerBook.stat(extra, "anathema", "SPAN", SPAN))
	_twist = PowerBook.twist_at(extra, "anathema")
	mark = HALLOWED if String(extra.get("mode", "cursed")) == "hallowed" else CURSED
	duration = T_CAST + lv_span + 0.5
	busy = T_CAST
	at(T_CAST, _lay)
	if _twist:
		at(T_CAST + SPREAD_AT, _spread)
	ctx.play(&"q_anathema", origin)
	if not DominionParts.staged(self):
		return
	var col := HALLOW if mark == HALLOWED else CURSE
	DominionParts.sky_sigil(self, origin, 130.0, 130.0, col, T_CAST, 2.0)
	DominionParts.ground_sigil(self, origin, lv_radius, col, T_CAST, 1.5)
	var glyph: Array[int] = []
	glyph.assign(DominionParts.HALO if mark == HALLOWED else DAMNED)
	var icon := DominionParts.icon(self, origin, glyph, Color("fff6d8") if mark == HALLOWED else Color("e0d0ff"), T_CAST + 2.5, 130.0)
	icon.px = 4


func _lay() -> void:
	buildings = marked_at(ctx.env, origin, lv_radius)
	if ctx.crowd != null:
		for s in buildings:
			ctx.crowd.mark_structure(s, mark, lv_span)
		if mark == HALLOWED:
			_gather(buildings, DominionParts.near(ctx.field, origin, lv_radius))
	ctx.play(&"jg_rise", origin, -8.0)
	if not DominionParts.staged(self):
		return
	var col := HALLOW if mark == HALLOWED else CURSE
	for s in buildings:
		_show(s, lv_span)
	DominionParts.pulse(self, origin, lv_radius, col, 0.7, 1.5)
	var wave := FxParts.shockwave(self, origin, lv_radius, VoiceOfGodFx.SOLAR if mark == HALLOWED else FxParts.VOID)
	wave.set_param("thickness", 0.06)
	wave.tween_param("progress", 0.05, 1.0, 0.7, 0.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	wave.tween_param("fade", 1.0, 0.0, 0.3, 0.45)
	wave.life = 0.8


## The mark shown on one building: its shroud and its sign.
func _show(s: Structure, life: float) -> void:
	var col := HALLOW if mark == HALLOWED else CURSE
	var glyph: Array[int] = []
	glyph.assign(DominionParts.HALO if mark == HALLOWED else DAMNED)
	var shroud := Shroud.new()
	shroud.fx = self
	shroud.rect = s.footprint.grow(0.12)
	shroud.z_index = 3
	track(shroud, ctx.ground)
	DominionParts.icon(self, s.center(), glyph, col, life, s.height + 16.0)


## Spreading Mark (level 5): once, SPREAD_AT after the marks are laid, every standing building of a marked role that is
## not marked yet and lies within SPREAD_R of a marked one's footprint takes the same mark for what is left of the
## span. The spread ones do not spread. HALLOWED: the citizens near them are sent in.
func _spread() -> void:
	var first := buildings.duplicate()
	var fresh: Array[Structure] = []
	for m in first:
		if not is_instance_valid(m):
			continue
		for s in ctx.env.structures():
			if not is_instance_valid(s) or s.destroyed or not s.role in MARKED or buildings.has(s) or fresh.has(s):
				continue
			if m.footprint.grow(SPREAD_R).intersects(s.footprint):
				fresh.append(s)
	if fresh.is_empty():
		return
	var left := maxf(T_CAST + lv_span - t, 0.5)
	for s in fresh:
		buildings.append(s)
		spread.append(s)
		if ctx.crowd != null:
			ctx.crowd.mark_structure(s, mark, left)
	if mark == HALLOWED and ctx.crowd != null:
		var folk: Array[Person] = []
		for e in ctx.field.alive():
			var p := e as Person
			if p == null:
				continue
			for s in fresh:
				if s.distance_to(p.ground_pos) <= SPREAD_R:
					folk.append(p)
					break
		_gather(fresh, folk)
	if not DominionParts.staged(self):
		return
	for s in fresh:
		_show(s, left)
	DominionParts.pulse(self, origin, lv_radius + SPREAD_R, HALLOW if mark == HALLOWED else CURSE, 0.5, 1.0)


## HALLOWED: every citizen among `folk` is sent into the nearest of `among` that takes people; with none, to the
## nearest door.
func _gather(among: Array[Structure], folk: Array) -> void:
	var houses: Array[Structure] = []
	for s in among:
		if ctx.crowd.shelters != null and ctx.crowd.shelters.shelters.has(s):
			houses.append(s)
	for p: Person in folk:
		if p.soldier or p.resists_mind():
			continue
		var best: Structure = null
		for s in houses if not houses.is_empty() else among:
			if best == null or s.distance_to(p.ground_pos) < best.distance_to(p.ground_pos):
				best = s
		if best == null:
			continue
		if not houses.is_empty():
			ctx.crowd.shelters.send_in(p, best)
		else:
			var away := p.ground_pos - best.center()
			var door := best.center() + (away.normalized() if away.length() > 0.01 else Vector2.DOWN) * (best.footprint.size.length() * 0.5 + 0.4)
			p.compel(door, maxf(T_CAST + lv_span - t, 0.5), 0.8, HALLOW, true, &"kneel", DominionParts.HALO)
		moved += 1


## Whether the marks hold now.
func holding() -> bool:
	return t >= T_CAST and t < T_CAST + lv_span


func _fx_process(delta: float) -> void:
	if not holding():
		return
	if mark == CURSED:
		# Whoever stands idle by a cursed wall walks away from it.
		_shun_in -= delta
		if _shun_in <= 0.0:
			_shun_in = SHUN_EVERY
			for s in buildings:
				if not is_instance_valid(s) or s.destroyed:
					continue
				for e in ctx.field.in_radius(s.center(), s.footprint.size.length() * 0.5 + SHUN_R):
					var p := e as Person
					if p == null or p.inside or p.soldier or p.resists_mind():
						continue
					if not (p.mind == Person.Mind.CALM or p.mind == Person.Mind.RECOVER or p.mind == Person.Mind.OBSERVE):
						continue
					if s.distance_to(p.ground_pos) > SHUN_R:
						continue
					var away := p.ground_pos - s.center()
					var to := p.ground_pos + (away.normalized() if away.length() > 0.01 else Vector2.DOWN) * SHUN_WALK
					if p.grid != null:
						var w := p.grid.nearest_walkable(to)
						if w != Vector2.INF:
							to = w
					if p.compel(to, 3.0, 0.5, CURSE, false, &"", DAMNED):
						moved += 1
	if not DominionParts.staged(self):
		return
	_motes_in -= delta
	if _motes_in <= 0.0:
		_motes_in = 0.6
		if not buildings.is_empty():
			var s := buildings[ctx.rng.randi() % buildings.size()]
			if is_instance_valid(s) and not s.destroyed:
				var c := s.center() + Vector2(ctx.rng.randf_range(-0.5, 0.5), ctx.rng.randf_range(-0.5, 0.5)) * s.footprint.size
				DominionParts.motes(self, c, DominionParts.GOLD_LIFE if mark == HALLOWED else CURSE_LIFE, 5)


## How much of the marks show: in as they are laid, out as they lift.
func shown() -> float:
	return clampf(minf((t - T_CAST) / 0.6, (T_CAST + lv_span + 0.4 - t) / 0.8), 0.0, 1.0)


## The mark on one building's ground: its footprint edged and washed in the mark's colour, breathing.
class Shroud extends Node2D:
	var fx: AnathemaFx
	var rect := Rect2()

	func _process(_delta: float) -> void:
		if fx.t > T_CAST + fx.lv_span + 0.5:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var a := fx.shown()
		if a <= 0.0:
			return
		var col := HALLOW if fx.mark == HALLOWED else CURSE
		var breathe := 0.8 + 0.2 * sin(fx.t * 1.6 + rect.position.x)
		draw_rect(rect, Color(col, 0.16 * a * breathe))
		draw_rect(rect, Color(0.05, 0.03, 0.08, 0.7 * a), false, 0.2)
		draw_rect(rect, Color(col, 0.95 * a * breathe), false, 0.08)
