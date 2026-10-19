extends RefCounted
## v0.11.2 spec §1: no mission narrows the draft. Every mission, campaign night, tier mission, board card and Long Night act
## drafts from PowerBook.keys(); the slots, DP and the believer unlock economy stay.

static func run(t) -> void:
	var defs: Array[MissionDef] = []
	defs.append_array(MissionBook.all())
	defs.append_array(MissionBook.campaign_missions())
	defs.append_array(MissionBook.tier_missions())
	for id in TierBook.all():
		defs.append(TierBook.board(id))
	for m in defs:
		t.check(m.powers() == PowerBook.keys(), "%s: every power in its draft" % m.id)
		for a: ActDef in m.acts:
			t.check(a.powers() == PowerBook.keys(), "%s/%s: every power" % [m.id, a.id])
	var b := TierBook.board("bell_ringers")
	t.check(b.slots == 3 and b.dp_capacity == TierBook.dp(2), "the tier's slots and DP stay")
	var s := DescendState.new()
	t.check(not s.is_unlocked("nova"), "the unlock economy stays: a fresh god has not unlocked Nova")
