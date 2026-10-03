extends RefCounted
## The power book: 17 draftable powers with valid effect scripts, icons, prices, cooldowns, aim and Authority.

## v0.07's cooldowns (kak-v0.07.1), which v0.08's may lengthen but never shorten (spec §2).
const V07_COOLDOWNS := {
	"doom": 2.5, "wisp": 25.0, "discord": 20.0, "heaven": 20.0, "blight": 25.0, "thorns": 30.0, "tornado": 30.0,
	"pestilence": 40.0, "dragon": 35.0, "tsunami": 40.0, "gravity": 45.0, "laser": 45.0, "orbital": 45.0,
	"cinder": 50.0, "judgement": 60.0, "glacial": 60.0, "nova": 120.0,
}


static func run(t) -> void:
	t.check(PowerBook.POWERS.size() == 17, "17 powers")
	var keys := {}
	var drag := []
	var problems: Array[String] = []
	for p: Dictionary in PowerBook.POWERS:
		if keys.has(p.key):
			problems.append("duplicate key %s" % p.key)
		keys[p.key] = true
		if not ResourceLoader.exists(p.path):
			problems.append("missing effect %s" % p.path)
		if not p.aim in ["click", "drag"]:
			problems.append("bad aim for %s" % p.key)
		if p.dp <= 0 or p.cooldown <= 0.0:
			problems.append("bad cost or cooldown for %s" % p.key)
		var big := PowerBook.icon(p.key)
		var small := PowerBook.hud_icon(p.key)
		if big == null or big.get_width() != 84 or small == null or small.get_width() != 42:
			problems.append("icon sizes for %s" % p.key)
		if p.aim == "drag":
			drag.append(p.key)
	t.check(problems.is_empty(), "power book problems: %s" % [problems])
	t.check(drag == ["heaven", "thorns", "tsunami", "laser"], "drag powers (%s)" % [drag])
	var nova := PowerBook.get_power("nova")
	t.check(nova.dp == 4 and nova.cooldown == 120.0 and nova.name == "Nuclear Nova", "the nova entry")
	t.check(PowerBook.get_power("nope").is_empty(), "an unknown key gives an empty entry")
	t.check(Array(PowerBook.keys()) == ["doom", "wisp", "discord", "heaven", "blight", "thorns", "tornado", "pestilence",
		"dragon", "tsunami", "gravity", "laser", "orbital", "cinder", "judgement", "glacial", "nova"],
		"the book's order, cheapest first by v0.07's costs (%s)" % [PowerBook.keys()])
	var quiet := []
	for key in PowerBook.keys():
		if PowerBook.is_quiet(key):
			quiet.append(key)
	t.check(quiet == ["doom", "wisp", "discord", "blight", "thorns", "pestilence"],
		"the quiet powers: no danger for the town to see (%s)" % [quiet])
	var authorities_ok := true
	for p: Dictionary in PowerBook.POWERS:
		authorities_ok = authorities_ok and PowerBook.AUTHORITIES.has(String(p.get("authority", "")))
	t.check(authorities_ok and PowerBook.AUTHORITY_TITLES.size() == PowerBook.AUTHORITIES.size(),
		"every power has a known Authority, and every Authority a title")
	t.check(Array(PowerBook.of_authority("veil")) == ["doom", "blight"] and PowerBook.authority_of("nova") == "ruin",
		"powers by Authority (veil: %s)" % [PowerBook.of_authority("veil")])
	t.check(PowerBook.authority_title("lifedeath") == "LIFE/DEATH" and PowerBook.authority_title("nope") == "",
		"an Authority's title, and none for a stranger")

	# v0.08 prices and cooldowns (spec §2): a price of 1 to 4 DP from the loadout budget, and a cooldown never shorter
	# than v0.07's -- checked against v0.07's table, not worked out from it.
	var problems_08: Array[String] = []
	for p: Dictionary in PowerBook.POWERS:
		if int(p.dp) < 1 or int(p.dp) > 4:
			problems_08.append("%s costs %d" % [p.key, p.dp])
		if not V07_COOLDOWNS.has(p.key) or float(p.cooldown) < float(V07_COOLDOWNS[p.key]):
			problems_08.append("%s cools in %.1f s" % [p.key, p.cooldown])
	t.check(problems_08.is_empty(), "prices are 1-4 DP and no cooldown got shorter (%s)" % [problems_08])
