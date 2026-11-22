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


## `list`'s threats with each id given `suffix` (a sub-director's: "herald" of the second star is "herald_1").
static func suffixed(list: Array, suffix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: Dictionary in list:
		var c := t.duplicate()
		c["id"] = StringName("%s_%s" % [String(t.get("id", "")), suffix])
		out.append(c)
	return out
