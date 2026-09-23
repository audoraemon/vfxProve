extends RefCounted
## The power book: 11 draftable powers with valid effect scripts, icons, costs, cooldowns and aim.


static func run(t) -> void:
	t.check(PowerBook.POWERS.size() == 11, "11 powers")
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
	t.check(drag == ["heaven", "tsunami", "laser"], "drag powers (%s)" % [drag])
	var nova := PowerBook.get_power("nova")
	t.check(nova.dp == 40 and nova.cooldown == 120.0 and nova.name == "Nuclear Nova", "the nova entry")
	t.check(PowerBook.get_power("nope").is_empty(), "an unknown key gives an empty entry")
	t.check(PowerBook.keys()[0] == "heaven" and PowerBook.keys()[10] == "nova", "spec order, cheapest first")
