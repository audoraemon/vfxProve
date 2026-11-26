class_name NightThreat
extends RefCounted
## A thing that ends the night if nobody interferes (loss warning, Discord idea "More Effect on Losing situation"): a Herald nearing the Temple,
## the bell's climb that would fill Halcyon's Gaze, a standard nearing its second house. MissionDirector.threats() lists them, Rules.threat()
## picks the soonest and ThreatAlert shows it. A threat is a plain Dictionary:
##   id     StringName  the same thing keeps the same id while it runs (a relay carries the same word on), a new one gets a new id
##   title  String      what happens, in capitals ("THE HERALD REACHES THE TEMPLE")
##   act    String      what to do, in capitals ("STOP HIM")
##   eta    float       seconds until it happens, as the strip counts them (mission seconds where the director's own countdown is)
##   at     Vector2     the ground point it is happening at (optional)
## Only reads: making or reading one changes nothing in the night and draws no random number.


## A threat record. `at` Vector2.INF leaves the point out.
static func make(id: StringName, title: String, act: String, eta: float, at := Vector2.INF) -> Dictionary:
	var out := {"id": id, "title": title, "act": act, "eta": maxf(eta, 0.0)}
	if at != Vector2.INF:
		out["at"] = at
	return out


## The soonest of `list` (the first of equals), {} for none; a threat with no finite eta is left out.
static func soonest(list: Array) -> Dictionary:
	var best := {}
	var best_eta := INF
	for t: Dictionary in list:
		var eta := float(t.get("eta", INF))
		if eta < best_eta:
			best_eta = eta
			best = t
	return best


## The threats of `list` from its `k`-th soonest on, when `k` more of them end the night (the first of two seized believers delivered is no
## loss, the second is): the soonest of what is left is then the moment the night is lost. Nothing for `k` < 1 or fewer than `k`.
static func decisive(list: Array, k: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if k < 1 or list.size() < k:
		return out
	var sorted := list.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.eta) < float(b.eta))
	for i in range(k - 1, sorted.size()):
		out.append(sorted[i])
	return out


## `list`'s threats with each id given `suffix` (a sub-director's: "herald" of the second star is "herald_1").
static func suffixed(list: Array, suffix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in list:
		var c := t.duplicate()
		c["id"] = StringName("%s_%s" % [String(t.get("id", "")), suffix])
		out.append(c)
	return out
