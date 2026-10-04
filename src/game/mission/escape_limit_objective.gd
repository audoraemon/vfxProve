class_name EscapeLimitObjective
extends Objective
## The people got away (v0.08; before, Rules._check_end()'s second test): `limit` citizens reaching an exit fails it.

var limit := Rules.ESCAPE_LIMIT


func _init(most := Rules.ESCAPE_LIMIT) -> void:
	limit = most
	label = "Let fewer than %d escape" % most
	reason = "escapes"


func check(rules: Rules) -> Status:
	return Status.FAILED if rules.crowd().escaped_count >= limit else Status.PENDING
