class_name WitnessObjective
extends StarsObjective
## Silence the witness's main objective (god P5, MS §3, Ruling P5-12): StarsObjective's count of witnesses stopped, DONE at all of them, that FAILS
## `word` the moment the director's lost_reason() says so (a witness at the Temple's door). It never reads lost_reason() before the win: the winning
## strike and the loss can fall in one frame and the win is checked first (MS §0).

## The reason a loss gives (the results' title is keyed by it).
const LOST := "word"

## The reason a win gives, kept so a check after a loss still reads right.
var _won := "witnesses"


## The label, the reason a win gives (`witnesses`) and the HUD's words before the count (StarsObjective's, with the Hunt's words as the defaults).
func _init(text := "Silence the witnesses", why := "witnesses", counted := "Witnesses silenced") -> void:
	super(text, why, counted)
	_won = why


## DONE with every witness stopped, else FAILED when the word reached the Temple (`word`), else PENDING.
func check(rules: Rules) -> Status:
	var s := super(rules)
	if s == Status.DONE:
		reason = _won
		return s
	if rules.director != null and rules.director.lost_reason() == LOST:
		reason = LOST
		return Status.FAILED
	return s
