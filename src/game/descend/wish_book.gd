class_name WishBook
extends RefCounted
## The wishes a board night may hear (v0.11 M1, spec §5): the pool, and the draw. The draw is seeded, so a restart hears the
## same. It is filtered: a wish whose tags clash with the mission's, or whose targets the town cannot give, is left out, and
## a mission with too few eligible wishes offers what it can, possibly none.


## The pool at M1 (spec §5.3), in the spec's order; the Rescue, Mercy and family wishes join it later in M1.
static func pool() -> Array[WishDef]:
	var out: Array[WishDef] = [
		WishDef.make("moneylender", "Burn the moneylender's house", "ruin", 10, RuinWish,
			{"role": "house", "label": "MONEYLENDER"}, PackedStringArray(["spares_houses"])),
		WishDef.make("watchtower", "Bring down the watchtower", "ruin", 15, RuinWish, {"role": "tower", "label": "WATCHTOWER"}),
		WishDef.make("tax_collector", "Strike down the cruel tax collector", "punish", 10, PunishWish,
			{"label": "TAX COLLECTOR", "unseen": false}),
		WishDef.make("informer", "Kill the informer, unseen", "punish", 15, PunishWish, {"label": "INFORMER", "unseen": true}),
		WishDef.make("sign", "Show me a sign", "sign", 5, SignWish),
	]
	return out


## Up to `count` wishes for a night (spec §5.1), tried in an order `rng` shuffles. A wish whose clashes meet `tags` is
## skipped, as is one whose choose() finds no targets in the town. No two share a person or a building.
static func draw(defs: Array[WishDef], count: int, tags: PackedStringArray, crowd: Crowd, town: Town,
		rng: RandomNumberGenerator) -> Array[Wish]:
	var order: Array[WishDef] = defs.duplicate()
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	var out: Array[Wish] = []
	var taken := []
	for d in order:
		if out.size() >= count:
			break
		if clashes(d, tags):
			continue
		var w := d.instance()
		if w.choose(crowd, town, rng, taken):
			out.append(w)
	return out


## The wish lists a tag the mission declares.
static func clashes(d: WishDef, tags: PackedStringArray) -> bool:
	for tag in d.clashes:
		if tags.has(tag):
			return true
	return false
