extends RefCounted
## v0.10 M4 Halcyon's Searchlight (Searchlight), the logic alone: beams from the Temple's spire, each a pool of light
## swept round it on a predictable path; a second beam 30 s after the first; a Will-o'-Wisp's decoy holding the nearest
## beam 5 s; in the clock's last 20 s a beam stopping to search at the latest noise; touches() within a pool.

const DT := 0.05
const SPIRE := Vector2(0.8, -8.7)


static func _run(l: Searchlight, seconds: float, time_left := 999.0) -> void:
	for i in roundi(seconds / DT):
		l.step(DT, time_left)


static func run(t) -> void:
	_sweep(t)
	_second(t)
	_decoy(t)
	_search(t)
	_out(t)
	_cone(t)
	_fade(t)


static func _sweep(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	t.check(l.beams() == 0 and not l.touches(SPIRE) and l.aim(0) == Vector2.INF, "asleep, there is no beam and nothing is seen")
	l.light()
	t.check(l.on and l.beams() == 1 and l.aim(0).distance_to(l.sweep_point(0, 0.0)) < 0.001
		and absf(l.aim(0).distance_to(SPIRE) - Searchlight.NEAR) < 0.001, "lit: one beam, starting near the spire")
	_run(l, 10.0)
	t.check(l.aim(0).distance_to(l.sweep_point(0, 10.0)) < 0.05, "it follows its predictable path (%s)" % l.aim(0))
	var within := true
	for k in 80:
		var r := l.sweep_point(0, float(k) * 0.5).distance_to(SPIRE)
		within = within and r >= Searchlight.NEAR - 0.001 and r <= Searchlight.FAR + 0.001
	t.check(within, "its pool swings between NEAR and FAR of the spire")
	var turned := (l.sweep_point(0, 5.0) - SPIRE).angle() - (PI * 0.5 + Searchlight.SPIN * 5.0)
	t.check(absf(wrapf(turned, -PI, PI)) < 0.001, "and turns round the spire at SPIN")
	var at := l.aim(0)
	t.check(l.touches(at) and l.touches(at + Vector2(Searchlight.POOL_R - 0.05, 0.0)), "within its pool, it touches")
	t.check(not l.touches(at + Vector2(Searchlight.POOL_R + 0.05, 0.0)), "just outside, it does not")


static func _second(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.light()
	_run(l, Searchlight.SECOND_AFTER - 1.0)
	t.check(l.beams() == 1 and l.aim(1) == Vector2.INF, "one beam until 30 s after it lit")
	_run(l, 1.5)
	t.check(l.beams() == 2 and l.aim(1).distance_to(l.sweep_point(1, l.beam_age(1))) < 0.05 and l.touches(l.aim(1)),
		"then a second, on its own path, and it touches too")
	var turned := (l.sweep_point(1, 2.0) - SPIRE).angle() - (-PI * 0.5 - Searchlight.SPIN * 2.0)
	t.check(absf(wrapf(turned, -PI, PI)) < 0.001, "turning the other way")
	var bench := Searchlight.new().setup(SPIRE)
	bench.light(Searchlight.SECOND_AFTER)
	t.check(bench.beams() == 2 and bench.aim(1).distance_to(bench.sweep_point(1, 0.0)) < 0.001,
		"lit from 30 s in (the bench), both beams sweep at once")


## A Will-o'-Wisp before the light wakes decoys nothing (review focus 4's noise and decoy); after, the nearest beam goes
## to it, stays DECOY_SECONDS, and takes up its sweep again.
static func _decoy(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.lure(SPIRE + Vector2(0.0, 10.0))
	t.check(l.decoy_beam == -1 and l.decoy_left == 0.0, "a wisp before the light wakes decoys nothing")
	l.light()
	_run(l, 2.0)
	var lure_at := l.aim(0) + Vector2(4.0, 0.0)
	l.lure(lure_at)
	t.check(l.decoy_beam == 0 and is_equal_approx(l.decoy_left, Searchlight.DECOY_SECONDS), "a wisp: the nearest beam takes the decoy")
	_run(l, 1.0)
	t.check(l.aim(0).distance_to(lure_at) < 0.05, "it goes to the light")
	_run(l, Searchlight.DECOY_SECONDS - 1.2)
	t.check(l.aim(0).distance_to(lure_at) < 0.05, "and stays on it for 5 s")
	_run(l, 10.0)
	t.check(l.decoy_beam == -1 and l.aim(0).distance_to(l.sweep_point(0, l.age)) < 0.05, "then takes up its sweep again")


## Noise moves no beam until the clock's last 20 s; then the nearest beam goes to the latest noise and stops there, a
## newer noise moves it, and a noise heard before the light woke still counts. With two beams, one follows a decoy and
## the other searches; with one, the decoy holds it first.
static func _search(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	var early := SPIRE + Vector2(-6.0, 12.0)
	l.hear(early)
	l.light()
	_run(l, 5.0, 60.0)
	t.check(not l.searching and l.search_beam == -1 and l.aim(0).distance_to(l.sweep_point(0, l.age)) < 0.05,
		"before the last 20 s, noise moves no beam")
	_run(l, 8.0, Searchlight.SEARCH_LAST)
	t.check(l.searching and l.search_beam == 0 and l.aim(0).distance_to(early) < 0.05,
		"in the last 20 s the beam goes to the latest noise (heard before it woke) and stops there")
	_run(l, 3.0, Searchlight.SEARCH_LAST - 8.0)
	t.check(l.aim(0).distance_to(early) < 0.05, "it searches there")
	var later := SPIRE + Vector2(8.0, 10.0)
	l.hear(later)
	_run(l, 5.0, 5.0)
	t.check(l.aim(0).distance_to(later) < 0.05, "a newer noise moves the search")

	var l2 := Searchlight.new().setup(SPIRE)
	l2.light()
	_run(l2, Searchlight.SECOND_AFTER + 1.0)
	var wisp_at := l2.aim(0) + Vector2(-1.0, 1.0)
	var noise_at := l2.aim(1) + Vector2(1.0, 1.0)
	l2.hear(noise_at)
	l2.lure(wisp_at)
	_run(l2, 2.0, Searchlight.SEARCH_LAST)
	t.check(l2.decoy_beam >= 0 and l2.search_beam >= 0 and l2.decoy_beam != l2.search_beam
		and l2.aim(l2.decoy_beam).distance_to(wisp_at) < 0.05 and l2.aim(l2.search_beam).distance_to(noise_at) < 0.05,
		"with two beams, one follows the decoy and the other searches")

	var l3 := Searchlight.new().setup(SPIRE)
	l3.light()
	_run(l3, 2.0)
	var w3 := l3.aim(0) + Vector2(2.0, 0.0)
	var n3 := l3.aim(0) + Vector2(-2.0, 0.0)
	l3.hear(n3)
	l3.lure(w3)
	_run(l3, 2.0, 10.0)
	t.check(l3.aim(0).distance_to(w3) < 0.05, "one beam: the decoy holds it before the search")
	_run(l3, Searchlight.DECOY_SECONDS, 10.0)
	t.check(l3.search_beam == 0 and l3.aim(0).distance_to(n3) < 0.05, "then it searches")


static func _out(t) -> void:
	var l := Searchlight.new().setup(SPIRE)
	l.light()
	_run(l, Searchlight.SECOND_AFTER + 1.0)
	var at := l.aim(0)
	l.put_out()
	t.check(not l.on and l.beams() == 0 and l.aim(0) == Vector2.INF and not l.touches(at), "put out, the beams die")
	_run(l, 1.0)
	t.check(l.beams() == 0 and l.age > 0.0, "and stepping it does nothing")


## The cone SearchlightFx draws: from the lamp, narrow, down onto its pool's two sides across the beam.
static func _cone(t) -> void:
	var top := Vector2(0.0, -200.0)
	var pts := SearchlightFx.cone_points(top, Vector2.ZERO, Searchlight.POOL_R)
	var semi := Iso.radius_to_screen(Searchlight.POOL_R)
	t.check(pts.size() == 4 and pts[0].distance_to(top) <= SearchlightFx.LAMP_HALF + 0.001
		and pts[1].distance_to(top) <= SearchlightFx.LAMP_HALF + 0.001, "the cone starts narrow at the lamp")
	t.check(absf(pts[2].distance_to(pts[3]) - semi.x * 2.0) < 0.01 and ((pts[2] + pts[3]) * 0.5).length() < 0.01,
		"and spans its pool's width across the beam, centred on the pool")


## A beam's alpha ramps over FADE_SECONDS, up when it lights and down when it goes out, rather than stepping.
static func _fade(t) -> void:
	var a := 0.0
	var steps: Array[float] = []
	for i in 10:
		a = SearchlightFx.fade_step(a, true, 0.05)
		steps.append(a)
	t.check(steps[0] > 0.0 and steps[0] < 0.1 and steps[9] > steps[0] and steps[9] < 1.0,
		"a beam lighting comes up in steps, not at once (%s)" % steps[0])
	for i in 20:
		a = SearchlightFx.fade_step(a, true, 0.05)
	t.near(a, 1.0, 0.0001, "and reaches full after FADE_SECONDS")
	var down := SearchlightFx.fade_step(a, false, 0.05)
	t.check(down > 0.0 and down < a, "a beam going out dims by a step, not to nothing")
	for i in 20:
		down = SearchlightFx.fade_step(down, false, 0.05)
	t.near(down, 0.0, 0.0001, "and is gone after FADE_SECONDS")
