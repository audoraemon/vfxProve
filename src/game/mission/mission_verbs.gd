class_name MissionVerbs
extends RefCounted
## The verb vocabulary (Mission clarity, spec §3): twelve words that name what the player does to a target, each tied to
## the powers whose effect does it. A mission's steps and hints use these words and no power name; the tests find them in a
## text (named_in) and prove each one in a Kit world; the legend's third page lists them with the player's own powers.
## Reads PowerBook only. Nothing here touches a mission.

## Spec §3's table, in order. "keys" are the powers in book order (powers() re-sorts them by PowerBook.POWERS).
## Scare has no keys of its own: it is every power that is not quiet (the town's fright), so its row says "loud".
## Kill: the strike, fire and death families but guise (it disguises) and ember (it lights a building, the fire is the town's),
## plus doom, hellspark, houndgate, breath and cage. Task 1 read each fx file: each of these has a path that kills a person.
const VERBS := [
	{"v": "kill", "word": "Kill", "does": "they die, by any power",
		"keys": ["doom", "smite", "deathmark", "raise", "hellspark", "breath", "heaven", "scatter", "houndgate", "gravecall", "tornado",
			"pestilence", "walker", "dragon", "tsunami", "gravity", "laser", "orbital", "cinder", "judgement", "glacial", "solaris",
			"gatebelow", "tempest", "shatter", "pale", "cage", "serpent", "gravetide", "nova"]},
	{"v": "scare", "word": "Scare", "does": "citizens run from a loud power near them", "keys": [], "loud": true},
	{"v": "lead", "word": "Lead", "does": "one walks where you click", "keys": ["whisper"]},
	{"v": "lure", "word": "Lure", "does": "they walk to a light or a body and stare", "keys": ["deathmark", "windfall", "wisp"]},
	{"v": "confuse", "word": "Confuse", "does": "they wander, blind, and drop their task", "keys": ["discord"]},
	{"v": "hold", "word": "Hold", "does": "the god's hand on a mind: they drop their task",
		"keys": ["whisper", "deathmark", "windfall", "wisp", "discord", "belllies", "congregation", "oath", "echo", "turncoat", "clearmind",
			"saint", "priority", "verdict", "anathema", "sanctuary", "voice", "schism", "fargate"]},
	{"v": "burn", "word": "Burn", "does": "sets a building alight", "keys": ["ember", "dragon", "cinder"]},
	{"v": "strike", "word": "Strike", "does": "a blow on a building or thing",
		"keys": ["smite", "heaven", "scatter", "tornado", "tsunami", "gravity", "laser", "orbital", "judgement", "glacial", "solaris",
			"tempest", "shatter", "nova"]},
	{"v": "rot", "word": "Rot", "does": "rots a building or a thing", "keys": ["blight"]},
	{"v": "seal", "word": "Seal", "does": "NO LEAVING on a door", "keys": ["noleave"]},
	{"v": "banish", "word": "Banish", "does": "sets them down outside the walls", "keys": ["mirror", "skylift"]},
	{"v": "calm", "word": "Calm", "does": "ALL IS WELL: the town stands down", "keys": ["belllies"]},
]


static func _row(verb: String) -> Dictionary:
	for r: Dictionary in VERBS:
		if r.v == verb:
			return r
	return {}


## The verbs, in table order.
static func verbs() -> PackedStringArray:
	var out := PackedStringArray()
	for r: Dictionary in VERBS:
		out.append(r.v)
	return out


## The powers of a verb, in book order (PowerBook.POWERS). Scare: every power that is not quiet.
static func powers(verb: String) -> PackedStringArray:
	var row := _row(verb)
	var out := PackedStringArray()
	if row.is_empty():
		return out
	for p: Dictionary in PowerBook.POWERS:
		var k: String = p.key
		if bool(row.get("loud", false)):
			if not PowerBook.is_quiet(k):
				out.append(k)
		elif (row.keys as Array).has(k):
			out.append(k)
	return out


## The verbs a power does, in table order.
static func verbs_of(key: String) -> PackedStringArray:
	var out := PackedStringArray()
	for r: Dictionary in VERBS:
		if powers(r.v).has(key):
			out.append(r.v)
	return out


## The capitalised word ("Kill"), or "" for an unknown verb.
static func word(verb: String) -> String:
	return String(_row(verb).get("word", ""))


## The legend's words for a verb, or "".
static func does(verb: String) -> String:
	return String(_row(verb).get("does", ""))


## The verbs whose word stands in `text` as a whole word, any case, in table order ("burning" is not "burn"). A mention that forbids
## the verb is skipped (pre-flight I10): one with "not" or "never" in the three words before it in its clause ("do not kill them",
## "never burn"), or "none", "no one" or "nobody" right after it ("kill none"): a text that says not to kill does not need a case
## where killing counts.
static func named_in(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var low := text.to_lower()
	for r: Dictionary in VERBS:
		var w: String = String(r.v)
		var from := 0
		while true:
			var at := low.find(w, from)
			if at < 0:
				break
			var before := at == 0 or not _letter(low[at - 1])
			var end := at + w.length()
			var after := end >= low.length() or not _letter(low[end])
			if before and after and not _forbidden(low, at, end):
				out.append(w)
				break
			from = at + 1
	return out


## Whether the verb standing at low[at:end] is named only to be refused (named_in()).
static func _forbidden(low: String, at: int, end: int) -> bool:
	var clause := low.substr(0, at)
	for stop in [",", ".", ";", ":", "(", ")", "!", "?"]:
		clause = clause.get_slice(stop, clause.get_slice_count(stop) - 1)
	var words := clause.split(" ", false)
	for i in range(maxi(0, words.size() - 3), words.size()):
		if words[i] == "not" or words[i] == "never":
			return true
	var tail := low.substr(end, 12).strip_edges()
	return tail.begins_with("none") or tail.begins_with("no one") or tail.begins_with("nobody")


static func _letter(c: String) -> bool:
	var u := c.unicode_at(0)
	return (u >= 97 and u <= 122) or (u >= 48 and u <= 57) or c == "_"


## The legend's third page: [[verb word, does, equipped power names, other power names], ...] in table order.
## A power is equipped when its key is in `loadout`.
static func legend_rows(loadout: PackedStringArray) -> Array:
	var out := []
	for r: Dictionary in VERBS:
		var mine := []
		var rest := []
		for k in powers(r.v):
			var n := String(PowerBook.get_power(k).get("name", k))
			if loadout.has(k):
				mine.append(n)
			else:
				rest.append(n)
		out.append([r.word, r.does, mine, rest])
	return out
