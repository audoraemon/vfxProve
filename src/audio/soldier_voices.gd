class_name SoldierVoices
extends RefCounted
## Fighting and orders, heard (natural sound pass 5). Crowd asks blow() for every blow that lands and order() when it
## sends soldiers out; Ambience plays the soldiers' march (sol_step) itself. Pure logic, like DeathVoices: it draws no
## random number, reads no person and changes nothing the simulation reads.
##
## A soldier's blow is a spear's thrust (sol_strike), anyone else's a fist or a shove (cit_blow). A token budget (TOKENS,
## refilled REFILL a second) keeps a street brawl from becoming a drum roll. An order is shouted at most once every
## ORDER_REST seconds.

const TOKENS := 5.0
const REFILL := 4.0
const ORDER_REST := 4.0

var blows := 0  ## blow cues handed out
var orders := 0  ## orders shouted

var _tokens := TOKENS
var _clock := -INF  ## the crowd clock of the last call
var _order_at := -INF


## The cue for a blow struck at crowd clock `now`, by a soldier or not; &"" when the budget is spent.
func blow(by_soldier: bool, now: float) -> StringName:
	_refill(now)
	if _tokens < 1.0:
		return &""
	_tokens -= 1.0
	blows += 1
	return &"sol_strike" if by_soldier else &"cit_blow"


## Whether an order may be shouted at crowd clock `now`.
func order(now: float) -> bool:
	if now - _order_at < ORDER_REST and now >= _order_at:
		return false
	_order_at = now
	orders += 1
	return true


func _refill(now: float) -> void:
	if _clock != -INF and now >= _clock:
		_tokens = minf(TOKENS, _tokens + REFILL * (now - _clock))
	_clock = now
