class_name WishDef
extends RefCounted
## One wish of the pool (v0.11 M1, spec §5.3): its words on the HUD, its kind, its believers before the tier's multiplier,
## the Wish script that runs it with that script's settings, and the mission tags it is never drawn beside.

var id := ""
## "Burn the moneylender's house": the HUD's line, and the results'.
var text := ""
## "ruin", "punish", "rescue", "mercy", "sign", (v0.11 M2) "faith" or (v0.11 M3) "fright".
var kind := ""
var reward := 0
## A Wish script (RuinWish, PunishWish, ...), made fresh for each night the wish is heard.
var runner: GDScript
## The script's own settings: a target's role and label, "unseen", ...
var params := {}
## Mission tags (MissionDef.mission_tags) the wish is never drawn beside.
var clashes := PackedStringArray()
## The lowest tier whose nights can hear it (v0.11 M3): 1 for most, Omen's own two 2. WishBook.pool_for() leaves out the higher
## ones before the draw shuffles, so a Tier 1 night shuffles exactly the wishes it always did.
var min_tier := 1


static func make(p_id: String, p_text: String, p_kind: String, p_reward: int, p_runner: GDScript, p_params := {},
		p_clashes := PackedStringArray(), p_min_tier := 1) -> WishDef:
	var d := WishDef.new()
	d.id = p_id
	d.text = p_text
	d.kind = p_kind
	d.reward = p_reward
	d.runner = p_runner
	d.params = p_params
	d.clashes = p_clashes
	d.min_tier = p_min_tier
	return d


## A fresh Wish for one night, not yet given its people (Wish.choose()).
func instance() -> Wish:
	var w := runner.new() as Wish
	w.def = self
	return w
