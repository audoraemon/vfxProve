extends RefCounted
## v0.11.2 Task 9 (spec 2.3, 2.4, 6.3): what each power sounds like, in measured numbers.
##
## Played level = a file's LUFS (tools/audio/loudness.tsv, written by tools/audio/loudness.py) + the catalog's db + the call's
## offset in the power's script (a non-literal offset counts as its largest literal); a cue with variants counts as its
## loudest variant. A loud power's main cue is its loudest played cue. The floor is the loud powers' median main-cue
## played level - 6 LU, rounded down to 0.5; it is measured once and never tuned to pass.

## The loud powers' median main cue is -14.55 LUFS (14 powers, `python tools/audio/loudness.py --table`); -14.55 - 6 = -20.55,
## rounded down to a half: -21.0.
const QUIET_FLOOR := -21.0
const FLOOR_BELOW := 6.0
const FLOOR_STEP := 0.5
## A loud power whose main cue sits under the floor, with its number. Measured: none (the quietest, Smite, is -20.4).
const LOUD_EXEMPT := {}
## The quiet keys still without their own q_<key> cue; Tasks 13 and 14 empty it, one key per line (a key that already plays its cue must leave). Tasks 13 and 14 took all 24 (v0.11.2).
## The Veil's seven waited for their sounds (V10); Veil Task 12 gave them theirs and emptied it (VD1).
const PENDING_QUIET := []
## The Veil's seven new powers cast with v_<key> (tools/audio/foley/ability/veil/), not q_<key> (VD1). The silent god's cues are
## quiet, low and close: a cast or a moment plays within VEIL_BAND over the floor, a held loop under its cast, none ducks or
## has an aftermath.
const VEIL_SEVEN := ["slumber", "cloak", "dreamless", "dread", "shadowplay", "swallow", "evernight"]
const VEIL_BAND := 3.0
## A Veil moment cue -> the script that plays it.
const VEIL_MOMENTS := {
	&"q_blight_ill": "res://src/fx/quiet/blight.gd",
	&"v_pale_eye": "res://src/fx/veil/pale_eye.gd",
}
## Review pass 2 (spec 4, VR2S): the Swallowing Dark is the one Veil power the god hears as a doomsday, so its cues leave the quiet band:
## its fold hits at least as loud as the Tier 5 doomsdays' main hits as played (and no more than SWALLOW_OVER over the loudest), ducks
## the music within their ducks, and its rumble loops under the cast. The town still hears none of it (the power stays quiet).
const DOOMSDAYS := ["tempest", "shatter", "tsunami", "gravetide", "deaddoors", "cage"]
const SWALLOW_CUES := [&"v_swallow", &"v_swallow_loop", &"v_swallow_heave", &"v_swallow_take"]
const SWALLOW_OVER := 2.0
const TSV := "res://tools/audio/loudness.tsv"
## Spec 6.3 row 4: the death cues' played levels relative to the loud median, and how far either way is allowed.
const DEATH_REL := {&"cit_death": -4.0, &"sol_death": -4.0, &"cit_fall": -9.0}
const DEATH_TOL := 2.0


static func run(t) -> void:
	var rows := _rows()
	t.check(rows.size() > 0, "loudness.tsv has rows (python tools/audio/loudness.py writes it)")
	_rows_cover_the_catalog(t, rows)
	var lufs := _loudest(rows)
	var mains := {}  # key -> [main cue, played level] for every key that plays a catalogued cue
	for key in PowerBook.keys():
		var best := _main(PowerBook.get_power(key).path, lufs)
		if not best.is_empty():
			mains[key] = best
	var median := _loud_median(mains)
	_floor(t, mains, median)
	_quiet_cues(t)
	_deaths(t, lufs, median)
	_hits_and_lantern(t, lufs, median)
	_veil(t, lufs)
	_swallow(t, lufs, mains)
	_sanity(t)


## cue/file rows of the TSV: [{cue, file, lufs, peak}]
static func _rows() -> Array:
	var out := []
	var lines := FileAccess.get_file_as_string(TSV).split("\n", false)
	for i in range(1, lines.size()):
		var f := lines[i].strip_edges().split("\t")
		if f.size() == 4:
			out.append({"cue": StringName(f[0]), "file": f[1], "lufs": float(f[2]), "peak": float(f[3])})
	return out


## (d): every file the catalog plays has a row.
static func _rows_cover_the_catalog(t, rows: Array) -> void:
	var have := {}
	for r in rows:
		have[r.file] = r
	var missing := ""
	for cue in Sfx.CATALOG:
		for path in Sfx.paths_for(cue):
			if not have.has(path):
				missing += " " + path.get_file()
	t.check(missing == "", "every catalog file has a loudness row (missing:%s; run python tools/audio/loudness.py)" % missing)


## cue -> its loudest variant's LUFS.
static func _loudest(rows: Array) -> Dictionary:
	var out := {}
	for r in rows:
		out[r.cue] = maxf(float(out.get(r.cue, -999.0)), r.lufs)
	return out


## The played level of a catalogued cue called with `offset`; NAN when the cue has no measure.
static func played(cue: StringName, offset: float, lufs: Dictionary) -> float:
	if not lufs.has(cue) or not Sfx.CATALOG.has(cue):
		return NAN
	return float(lufs[cue]) + float(Sfx.CATALOG[cue].get("db", 0.0)) + offset


## Every `.play(&"cue", pos, offset)` in a script: [[cue, offset], ...]. A call with no offset has 0; a non-literal offset
## is its largest decimal literal.
static func plays(path: String) -> Array:
	var src := FileAccess.get_file_as_string(path)
	var out := []
	var head := RegEx.new()
	head.compile("\\.play\\(\\s*&\"(\\w+)\"")
	var literal := RegEx.new()
	literal.compile("(?<![\\w.])-?\\d+\\.\\d+")
	for m in head.search_all(src):
		var args := _args(src.substr(m.get_end()))
		var offset := 0.0
		if args.size() >= 3 and args[2] != "":
			var best := -INF
			for lit in literal.search_all(args[2]):
				best = maxf(best, float(lit.get_string()))
			offset = best if best > -INF else 0.0
		out.append([StringName(m.get_string(1)), offset])
	return out


## The top-level comma-separated arguments of a call whose cue has just been read (so the first one is empty).
static func _args(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var depth := 0
	var cur := ""
	for i in text.length():
		var c := text[i]
		if c == "(" or c == "[" or c == "{":
			depth += 1
		elif c == ")" or c == "]" or c == "}":
			if depth == 0:
				out.append(cur.strip_edges())
				return out
			depth -= 1
		if c == "," and depth == 0:
			out.append(cur.strip_edges())
			cur = ""
		else:
			cur += c
	return out


## [cue, level] of the loudest catalogued cue a script plays, or [] when it plays none.
static func _main(path: String, lufs: Dictionary) -> Array:
	var best := []
	for p in plays(path):
		var level := played(p[0], p[1], lufs)
		if not is_nan(level) and (best.is_empty() or level > best[1]):
			best = [p[0], level]
	return best


static func _loud_median(mains: Dictionary) -> float:
	var levels := []
	for key in mains:
		if not PowerBook.is_quiet(key) and PowerBook.IMPACT.has(key):
			levels.append(mains[key][1])
	levels.sort()
	if levels.is_empty():
		return NAN
	var n := levels.size()
	return levels[n / 2] if n % 2 == 1 else (levels[n / 2 - 1] + levels[n / 2]) / 2.0


## (a) and (f): every key plays a cue at or over the floor (a pending quiet key is skipped), and the floor is what the
## measure gives.
static func _floor(t, mains: Dictionary, median: float) -> void:
	var loud := 0
	for key in PowerBook.keys():
		if PowerBook.IMPACT.has(key):
			loud += 1
	t.check(loud == 36, "thirty-six loud powers (got %d)" % loud)
	t.check(not is_nan(median), "a loud median can be measured")
	var raw := median - FLOOR_BELOW
	t.check(QUIET_FLOOR <= raw + 0.001 and raw - QUIET_FLOOR < FLOOR_STEP + 0.001,
		"QUIET_FLOOR %.2f is the measured floor %.2f (loud median %.2f - %.0f) rounded down to %.1f" % [QUIET_FLOOR, raw, median, FLOOR_BELOW, FLOOR_STEP])
	for key in PowerBook.keys():
		if PENDING_QUIET.has(key):
			continue
		if not mains.has(key):
			t.check(false, "%s: its script plays no catalogued cue" % key)
			continue
		var level: float = mains[key][1]
		if LOUD_EXEMPT.has(key):
			t.check(level < QUIET_FLOOR and absf(level - float(LOUD_EXEMPT[key])) < 0.5,
				"%s is exempt at %.1f (measured %.1f, floor %.1f)" % [key, float(LOUD_EXEMPT[key]), level, QUIET_FLOOR])
		else:
			t.check(level >= QUIET_FLOOR, "%s: its loudest cue %s plays at %.1f, under the floor %.1f" % [key, mains[key][0], level, QUIET_FLOOR])
	for key in LOUD_EXEMPT:
		t.check(PowerBook.IMPACT.has(key), "LOUD_EXEMPT holds only loud powers (%s)" % key)


## A quiet key's own cast cue: v_<key> for the Veil's seven (VD1), q_<key> for every other.
static func own_cue(key: String) -> StringName:
	return StringName(("v_" if key in VEIL_SEVEN else "q_") + key)


## (b) and (c): every quiet key not pending plays its own cue (own_cue); no two q_ or v_ cues share a file.
static func _quiet_cues(t) -> void:
	for key in PENDING_QUIET:
		t.check(PowerBook.is_quiet(key), "PENDING_QUIET %s is a quiet power" % key)
	var quiet := 0
	for key in PowerBook.keys():
		if not PowerBook.is_quiet(key):
			continue
		quiet += 1
		var cue := own_cue(key)
		var plays_it := false
		for p in plays(PowerBook.get_power(key).path):
			plays_it = plays_it or p[0] == cue
		if PENDING_QUIET.has(key):
			t.check(not plays_it, "%s is still pending but already plays %s: take it off PENDING_QUIET" % [key, cue])
		else:
			t.check(Sfx.CATALOG.has(cue) and plays_it, "%s plays its own cue %s" % [key, cue])
	t.check(quiet == 48, "forty-eight quiet powers (got %d)" % quiet)
	var owner_of := {}
	var shared := ""
	for cue in Sfx.CATALOG:
		if not String(cue).begins_with("q_") and not String(cue).begins_with("v_"):
			continue
		for path in Sfx.paths_for(cue):
			if owner_of.has(path) and owner_of[path] != cue:
				shared += " %s/%s" % [owner_of[path], cue]
			owner_of[path] = cue
	t.check(shared == "", "no two q_ or v_ cues share a file (shared:%s)" % shared)


## (e): the death cues sit where spec 6.3 row 4 puts them, relative to the loud median.
static func _deaths(t, lufs: Dictionary, median: float) -> void:
	for cue in DEATH_REL:
		var level := played(cue, 0.0, lufs)
		var want: float = median + float(DEATH_REL[cue])
		t.check(not is_nan(level) and absf(level - want) <= DEATH_TOL,
			"%s plays at %.1f, within %.0f of %.1f (loud median %.1f %+.0f)" % [cue, level, DEATH_TOL, want, median, DEATH_REL[cue]])
	var wave := played(&"crowd_death_wave", 0.0, lufs)
	t.check(not is_nan(wave) and wave <= median, "crowd_death_wave plays at %.1f, at most the loud median %.1f" % [wave, median])


## v0.11.2 Task 13: the effect cues q_<key>_hit sit in the code that has the moment, at a level in the floor..median + 2 band, and
## the Lantern's three cues (LanternWatch plays them at the Temple) are catalogued near the loud median.
const HIT_SOURCES := {
	"doom": "res://src/fx/quiet/silent_doom.gd",
	"blight": "res://src/fx/quiet/blight.gd",
	"deathmark": "res://src/fx/death/death_mark.gd",
	"ember": "res://src/fx/ruin/ember.gd",
	"thorns": "res://src/fx/control/thornwall.gd",
	"mirror": "res://src/fx/control/mirrorfold_passage.gd",
	"madness": "res://src/game/crowd/madness_manager.gd",
	"sealed": "res://src/fx/decree/the_sealed_verdict.gd",
}
const LANTERN_BAND := 3.0


static func _hits_and_lantern(t, lufs: Dictionary, median: float) -> void:
	for key in HIT_SOURCES:
		var cue := StringName("q_%s_hit" % key)
		var level := played(cue, 0.0, lufs)
		t.check(Sfx.CATALOG.has(cue) and not is_nan(level), "%s is catalogued and measured" % cue)
		t.check(level >= QUIET_FLOOR and level <= median + 2.0,
			"%s plays at %.1f, within the floor %.1f and the loud median + 2 (%.1f)" % [cue, level, QUIET_FLOOR, median + 2.0])
		t.check(FileAccess.get_file_as_string(HIT_SOURCES[key]).contains('&"%s"' % cue), "%s plays %s at its moment" % [HIT_SOURCES[key].get_file(), cue])
	t.check(not FileAccess.get_file_as_string(HIT_SOURCES["ember"]).contains("dr_ignite"), "the ember's own spark replaces dr_ignite")
	for cue in [LanternWatch.CUE_FLARE, LanternWatch.CUE_BURN, LanternWatch.CUE_BLIND]:
		var level := played(cue, 0.0, lufs)
		t.check(Sfx.CATALOG.has(cue) and not is_nan(level) and level >= median - LANTERN_BAND and level <= median + 2.0,
			"%s plays at %.1f, within %.0f under the loud median %.1f and +2" % [cue, level, LANTERN_BAND, median])


## Veil Task 12 (spec 6): the Veil's seven cast cues, the Swallowing Dark's taking and Blight's sickness on a person play quiet --
## within VEIL_BAND over the floor -- from the script that has the moment; Evernight's held night loops, plays under its cast and is
## faded out by the effect; no Veil cue ducks the music or calls an aftermath.
static func _veil(t, lufs: Dictionary) -> void:
	var moments := {}
	for key in VEIL_SEVEN:
		if key != "swallow":
			moments[StringName("v_" + key)] = PowerBook.get_power(key).path
	moments.merge(VEIL_MOMENTS)
	for cue: StringName in moments:
		var path: String = moments[cue]
		var level := NAN
		for p in plays(path):
			if p[0] == cue:
				level = played(cue, p[1], lufs) if is_nan(level) else maxf(level, played(cue, p[1], lufs))
		t.check(Sfx.CATALOG.has(cue) and not is_nan(level), "%s is catalogued, measured and played by %s" % [cue, path.get_file()])
		t.check(level >= QUIET_FLOOR and level <= QUIET_FLOOR + VEIL_BAND,
			"%s plays at %.1f, quiet: within the floor %.1f and %.1f" % [cue, level, QUIET_FLOOR, QUIET_FLOOR + VEIL_BAND])
	var loop := &"v_evernight_loop"
	var night: String = PowerBook.get_power("evernight").path
	var held := NAN
	for p in plays(night):
		if p[0] == loop:
			held = played(loop, p[1], lufs)
	t.check(Sfx.CATALOG.has(loop) and Sfx.CATALOG[loop].get("loop", false), "%s is a catalogued loop" % loop)
	t.check(not is_nan(held) and held < played(&"v_evernight", 0.0, lufs),
		"%s plays at %.1f, under Evernight's cast %.1f" % [loop, held, played(&"v_evernight", 0.0, lufs)])
	t.check(FileAccess.get_file_as_string(night).contains("fade_out("), "evernight.gd fades its held night out")
	for cue in Sfx.CATALOG:
		if (String(cue).begins_with("v_") or cue == &"q_blight_ill") and cue != &"v_swallow_take":
			t.check(not Sfx.DUCKS.has(cue) and not Sfx.AFTERMATH.has(cue), "%s neither ducks nor has an aftermath" % cue)


## Review pass 2 (spec 4): the Swallowing Dark's four cues, as played, against the doomsdays.
static func _swallow(t, lufs: Dictionary, mains: Dictionary) -> void:
	var path: String = PowerBook.get_power("swallow").path
	var level := {}
	for p in plays(path):
		if p[0] in SWALLOW_CUES:
			level[p[0]] = played(p[0], p[1], lufs)
	for cue: StringName in SWALLOW_CUES:
		t.check(Sfx.CATALOG.has(cue) and level.has(cue) and not is_nan(level[cue]), "%s is catalogued, measured and played by %s" % [cue, path.get_file()])
	if level.size() < SWALLOW_CUES.size():
		return
	var loudest := -INF
	var ducks: Array = []
	for key in DOOMSDAYS:
		t.check(mains.has(key) and not PowerBook.is_quiet(key), "%s is a loud doomsday with a main cue" % key)
		if mains.has(key):
			loudest = maxf(loudest, float(mains[key][1]))
			if Sfx.DUCKS.has(mains[key][0]):
				ducks.append(float(Sfx.DUCKS[mains[key][0]]))
	var take: float = level[&"v_swallow_take"]
	t.check(take >= loudest - 0.001 and take <= loudest + SWALLOW_OVER,
		"v_swallow_take plays at %.1f: at least the loudest doomsday hit %.1f, at most %.0f over it" % [take, loudest, SWALLOW_OVER])
	t.check(level[&"v_swallow"] > QUIET_FLOOR + VEIL_BAND and level[&"v_swallow"] < take,
		"v_swallow (the cast) plays at %.1f: over the quiet Veil band (%.1f), under the fold %.1f" % [level[&"v_swallow"], QUIET_FLOOR + VEIL_BAND, take])
	t.check(level[&"v_swallow_heave"] < take, "v_swallow_heave plays at %.1f, under the fold %.1f" % [level[&"v_swallow_heave"], take])
	var loop: Dictionary = Sfx.CATALOG[&"v_swallow_loop"]
	t.check(loop.get("loop", false) and int(loop.get("voices", 2)) == 1 and level[&"v_swallow_loop"] < level[&"v_swallow"],
		"v_swallow_loop is a one-voice loop at %.1f, under the cast %.1f" % [level[&"v_swallow_loop"], level[&"v_swallow"]])
	t.check(FileAccess.get_file_as_string(path).contains("ctx.fade_out("), "the_swallowing_dark.gd fades its rumble out")
	ducks.sort()
	var duck := float(Sfx.DUCKS.get(&"v_swallow_take", 0.0))
	t.check(ducks.size() >= 3 and duck >= ducks[0] and duck <= ducks[-1],
		"v_swallow_take ducks the music by %.0f dB, within the doomsdays' ducks %s" % [duck, ducks])
	for cue: StringName in SWALLOW_CUES:
		t.check(not Sfx.AFTERMATH.has(cue) and (cue == &"v_swallow_take" or not Sfx.DUCKS.has(cue)),
			"%s: only the fold ducks, none has an aftermath" % cue)
	t.check(PowerBook.is_quiet("swallow"), "the Swallowing Dark stays quiet to the town")


## The reader itself: a few known calls, so a parser that silently reads nothing cannot pass the floor by default.
static func _sanity(t) -> void:
	var smite := plays("res://src/fx/ruin/smite.gd")
	t.check(smite.has([&"smite_strike", -3.0]) and smite.has([&"smite_call", -4.0]), "reads smite's cues and offsets (%s)" % [smite])
	var hs := plays("res://src/fx/set2/heaven_splitter.gd")
	t.check(hs.has([&"hs_erupt", -2.0]), "a conditional offset counts as its largest literal (%s)" % [hs])
	var bare := plays("res://src/fx/set2/judgement_of_the_ancients.gd")
	t.check(bare.has([&"jg_hands", 0.0]), "a call with no offset is 0 (%s)" % [bare])
