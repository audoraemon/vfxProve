class_name RescueManager
extends RefCounted
## Rescue squads (v0.07): the barracks yard's soldiers, in squads of Crowd.RESCUE_SQUAD. A shelter that collapses
## traps TRAPPED_SHARE of those inside under its rubble instead of killing them (ShelterManager hands them over:
## trap()); they live TRAPPED_LIFE. The nearest free squad runs to the rubble and, with one of them within DIG_REACH,
## digs one out every DIG_TIME; the freed come out at the rubble's edge, frightened. Untended, the trapped die there. A
## squad with nothing to dig turns out to the nearest fire (FireManager.enlist()) until the town evacuates.

signal first_rescue

## The share of a collapsed shelter's people who are trapped rather than killed.
const TRAPPED_SHARE := 0.6
## How long the trapped live under the rubble, how long one takes to dig out, and how near a squad member must be.
const TRAPPED_LIFE := 45.0
const DIG_TIME := 3.0
const DIG_REACH := 1.2
## How often squads are given work.
const EVERY := 0.5
const DUST := Color(0.62, 0.56, 0.48)

## Each trapped person: {"p": Person, "left": seconds to live, "site": the rubble}.
var trapped: Array = []
## Each squad: {"members": Array of Person, "site": Structure being dug (null when free), "spot": where it digs,
## "dig": progress on the next one, 0..1}.
var squads: Array = []
var rescued := 0
var died := 0
var _crowd: Crowd
var _field: EnemyField
var _in := 0.0
var _announced := false


func setup(crowd: Crowd, field: EnemyField) -> RescueManager:
	_crowd = crowd
	_field = field
	var squad: Array = []
	for p in crowd.soldiers:
		if p.corps == Person.Corps.RESCUE:
			squad.append(p)
			if squad.size() == Crowd.RESCUE_SQUAD:
				squads.append({"members": squad, "site": null, "spot": Vector2.INF, "dig": 0.0})
				squad = []
	if not squad.is_empty():
		squads.append({"members": squad, "site": null, "spot": Vector2.INF, "dig": 0.0})
	return self


## The trapped from a shelter's collapse: hidden under the rubble with TRAPPED_LIFE to live.
func trap(people: Array, s: Structure) -> void:
	for p in people:
		if not is_instance_valid(p):
			continue
		var q: Person = p
		q.inside = true
		q.visible = false
		q.shelter = null
		q.ground_pos = s.center()
		trapped.append({"p": q, "left": TRAPPED_LIFE, "site": s})


func trapped_at(s: Structure) -> int:
	var n := 0
	for t in trapped:
		if t.site == s:
			n += 1
	return n


func step(delta: float) -> void:
	for t in trapped.duplicate():
		t.left = float(t.left) - delta
		if float(t.left) <= 0.0:
			_die(t)
	for sq in squads:
		if sq.site != null:
			_dig(sq, delta)
	_in -= delta
	if _in <= 0.0:
		_in = EVERY
		_assign()


func _living(sq: Dictionary) -> Array:
	var out: Array = []
	for m in sq.members:
		if is_instance_valid(m) and (m as Person).is_alive():
			out.append(m)
	return out


## Free squads to the rubble with nobody digging (nearest first); the rest to fires, or back to their posts.
func _assign() -> void:
	var sites: Array = []
	for t in trapped:
		if not sites.has(t.site):
			sites.append(t.site)
	for s in sites:
		var dug := false
		for sq in squads:
			dug = dug or sq.site == s
		if dug:
			continue
		var best: Dictionary = {}
		var best_d := INF
		for sq in squads:
			var crew := _living(sq)
			if sq.site != null or crew.is_empty():
				continue
			var d := (crew[0] as Person).ground_pos.distance_to((s as Structure).center())
			if d < best_d:
				best_d = d
				best = sq
		if best.is_empty():
			continue
		var site: Structure = s
		var crew := _living(best)
		var away := (crew[0] as Person).ground_pos - site.center()
		var dir := away.normalized() if away.length() > 0.01 else Vector2.DOWN
		best.site = site
		best.dig = 0.0
		best.spot = _crowd._spot_near(site.center() + dir * (site.footprint.size.length() * 0.5 + 0.3), 0.2)
		for i in crew.size():
			var m: Person = crew[i]
			if m.mind == Person.Mind.ASSIST:
				m.stand_down()
			# At a run: the trapped have little time.
			m.send_to_post(_crowd._spot_near(best.spot + Vector2(0.4 * float(i), 0.0), 0.15), false, true)
	var evacuating := _crowd.alarms.stage >= AlarmManager.Stage.EVACUATION
	for sq in squads:
		if sq.site != null:
			continue
		var crew := _living(sq)
		if crew.is_empty():
			continue
		var at_fire := false
		for m in crew:
			at_fire = at_fire or (m as Person).mind == Person.Mind.ASSIST
		if at_fire:
			continue
		var fire: Structure = null if evacuating else _nearest_fire((crew[0] as Person).ground_pos)
		for m in crew:
			var p: Person = m
			if fire != null:
				_crowd.fires.enlist(p, fire)
			elif p.mind != Person.Mind.POST or p.anchor != p.post:
				p.send_to_post(p.post if p.post != Vector2.INF else p.ground_pos)


func _nearest_fire(from: Vector2) -> Structure:
	var fm := _crowd.fires
	if fm == null:
		return null
	var best: Structure = null
	for s: Structure in fm.fires.keys():
		if not is_instance_valid(s) or float(fm.fires[s].intensity) >= FireManager.ABANDON or fm.nearest_water(s.center()) == null:
			continue
		var d := s.center().distance_to(from)
		if d <= FireManager.RECRUIT_REACH and (best == null or d < best.center().distance_to(from)):
			best = s
	return best


func _dig(sq: Dictionary, delta: float) -> void:
	var site: Structure = sq.site
	var crew := _living(sq)
	# Nobody left to dig, or nobody left under the rubble: the site is free for another squad.
	if crew.is_empty() or trapped_at(site) == 0:
		sq.site = null
		sq.dig = 0.0
		return
	var close := false
	for m in crew:
		var p: Person = m
		close = close or (not p.has_goal() and p.ground_pos.distance_to(sq.spot) <= DIG_REACH)
	if not close:
		return
	sq.dig = float(sq.dig) + delta / DIG_TIME
	if float(sq.dig) < 1.0:
		return
	sq.dig = 0.0
	for t in trapped:
		if t.site == site:
			_free(t, sq.spot)
			break


func _free(t: Dictionary, at: Vector2) -> void:
	trapped.erase(t)
	var p: Person = t.p
	if not is_instance_valid(p):
		return
	var site: Structure = t.site
	p.inside = false
	p.visible = true
	p.ground_pos = _crowd._spot_near(at, 0.3)
	_field.add(p)
	# As ShelterManager throws people out of a building hit hard: out of the shelter's ways, and running.
	p.leave_shelter(false)
	p.panic(site.center(), site.footprint.size.length() * 0.5)
	rescued += 1
	if not _announced:
		_announced = true
		first_rescue.emit()


func _die(t: Dictionary) -> void:
	trapped.erase(t)
	var p: Person = t.p
	if not is_instance_valid(p):
		return
	var site: Structure = t.site
	p.inside = false
	p.visible = true
	p.ground_pos = site.center()
	_field.add(p)
	_field.kill(p, &"collapse", site.center())
	died += 1


## A dust plume and the count over each rubble with people under it. Into `ci`, world space.
func draw(ci: CanvasItem) -> void:
	var counts := {}
	for t in trapped:
		counts[t.site] = int(counts.get(t.site, 0)) + 1
	var now := float(Time.get_ticks_msec()) * 0.001
	for s in counts:
		var site: Structure = s
		var at := Iso.ground_to_screen(site.center())
		for k in 6:
			var rise := fmod(now * 0.4 + float(k) * 0.17, 1.0)
			var c := DUST
			c.a = 0.6 * (1.0 - rise)
			ci.draw_rect(Rect2((at + Vector2(sin(float(k) * 2.3) * 6.0, -4.0 - rise * 22.0)).round(), Vector2(2, 2)), c)
		var label := "%d" % int(counts[s])
		var w := UiTheme.width(label, UiTheme.SIZE_SMALL)
		ci.draw_rect(Rect2(at + Vector2(-4, -36), Vector2(maxf(9.0, w + 4.0), 10)), Color(0, 0, 0, 0.6))
		UiTheme.text(ci, at + Vector2(-2, -28), label, UiTheme.SIZE_SMALL, Color.WHITE)


func clear() -> void:
	trapped.clear()
	squads.clear()
	rescued = 0
	died = 0
