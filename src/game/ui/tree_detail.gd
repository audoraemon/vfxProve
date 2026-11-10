class_name TreeDetail
extends RefCounted
## What the Skill Tree's detail panel says about a power (statics only): its tags, a two-line description, the numbers the next level
## changes, and the state of the buy button. Pure data; the screen draws it.

## What a refused learn says, by GodSlot.refusal(); "tier" takes the spot's tier.
const REFUSALS := {"unknown": "Not yet chosen", "far": "Too far from your nature", "tier": "Awaken to Tier %d",
	"max": "Already at level 5", "points": "Not enough ability points"}
const ROMAN := ["I", "II", "III", "IV", "V"]
## The description keeps to this many lines.
const DESCRIPTION_LINES := 2


## [AUTHORITY, "TIER n", "QUIET" | "LOUD"] for a power ("TIER ?" when it sits in no spot).
static func tags(key: String) -> PackedStringArray:
	var tier := int(GodTree.spot_of(key).get("tier", 0))
	var roman := String(ROMAN[tier - 1]) if tier >= 1 and tier <= ROMAN.size() else "?"
	return PackedStringArray([PowerBook.authority_of(key).to_upper(), "TIER " + roman, "QUIET" if PowerBook.is_quiet(key) else "LOUD"])


## The power's blurb wrapped to `width` px, cut to two lines (the second ends "..." if the text went on).
static func description(key: String, width: float) -> PackedStringArray:
	var lines := UiTheme.wrap(PowerBook.blurb(key), width, UiTheme.SIZE_SMALL)
	if lines.size() <= DESCRIPTION_LINES:
		return lines
	var last := lines[DESCRIPTION_LINES - 1]
	while last.length() > 1 and UiTheme.width(last + "...", UiTheme.SIZE_SMALL) > width:
		last = last.substr(0, last.length() - 1).strip_edges(false, true)
	return PackedStringArray([lines[0], last + "..."])


## The level column: {"head", "rows", "might", "twist"}. head is "LEARN" (rows = level 1's numbers, old == new), "LEVEL n -> n+1"
## (rows = what that level changes) or "MAX"; a power without a table has head PowerBook.NO_LEVELS, no rows and no twist.
static func level_column(slot: GodSlot, key: String) -> Dictionary:
	var have := slot.level_of(key)
	var might := str(PowerBook.might(key, maxi(have, 1)))
	if not PowerBook.has_levels(key):
		return {"head": PowerBook.NO_LEVELS, "rows": [], "might": might, "twist": ""}
	var head := "MAX"
	var rows := []
	if have == 0:
		head = "LEARN"
		var first: Dictionary = (PowerBook.get_power(key).levels as Array)[0]
		for name: String in first:
			if PowerBook.TWIST_KEYS.has(name):
				continue
			var label := PowerBook._stat_label(PowerBook.get_power(key), name)
			var v := PowerBook._stat_text(first[name])
			rows.append({"label": label, "old": v, "new": v})
	elif have < PowerBook.MAX_LEVEL:
		head = "LEVEL %d -> %d" % [have, have + 1]
		rows = PowerBook.level_rows(key, have + 1)
		var next := PowerBook.might(key, have + 1)
		if next != PowerBook.might(key, have):
			might = "%d -> %d" % [PowerBook.might(key, have), next]
	var twist := PowerBook.twist(key)
	if twist != "":
		twist = "Level %d . %s" % [PowerBook.MAX_LEVEL, twist.split(". ")[0]]
	return {"head": head, "rows": rows, "might": might, "twist": twist}


## The buy button: {"label": "LEARN" | "RAISE" | "MAX", "cost", "enabled", "reason"}; reason is REFUSALS' words while refused.
static func buy_button(slot: GodSlot, key: String, tier: int) -> Dictionary:
	var have := slot.level_of(key)
	var label := "LEARN" if have == 0 else ("MAX" if have >= PowerBook.MAX_LEVEL else "RAISE")
	var why := slot.refusal(key)
	var reason := ""
	if why != "":
		reason = String(REFUSALS.get(why, why))
		if why == "tier":
			reason = reason % tier
	return {"label": label, "cost": slot.cost(key), "enabled": why == "", "reason": reason}
