class_name MightPool
extends RefCounted
## The Might gauge's numbers (Endless Night): a capacity, a refill time and the value now. Casting pays from `value`, `advance`
## refills it at `capacity / refill_seconds` per second. Pure arithmetic; no scene, no save.

## Seconds an empty gauge takes to fill with no Faith upgrade bought.
const REFILL_SECONDS := 60.0
## Seconds each FASTER MIGHT upgrade takes off the refill.
const REFILL_STEP := 5.0
## The refill never gets faster than this many seconds.
const REFILL_FLOOR := 30.0
## Tolerance for `can_pay` and `whole`, so float drift never blocks a payable cast.
const EPSILON := 0.0001

## The most Might the gauge holds.
var capacity := 0.0
## Seconds an empty gauge takes to fill.
var refill_seconds := REFILL_SECONDS
## Might held now, 0..capacity.
var value := 0.0


## A full gauge of `size`; `seconds` is clamped up to REFILL_FLOOR.
static func make(size: int, seconds := REFILL_SECONDS) -> MightPool:
	var p := MightPool.new()
	p.capacity = float(size)
	p.refill_seconds = maxf(seconds, REFILL_FLOOR)
	p.value = p.capacity
	return p


## The tier's gauge: its Divine Power as the size, the base refill.
static func for_tier(tier: int) -> MightPool:
	return make(TierBook.dp(tier), REFILL_SECONDS)


## The god's gauge: its Might as the size, its FASTER MIGHT refill.
static func for_god(god: GodSlot) -> MightPool:
	return make(god.max_might(), god.refill_seconds())


## Refill seconds after `bought` FASTER MIGHT upgrades.
static func refill_for(bought: int) -> float:
	return maxf(REFILL_SECONDS - REFILL_STEP * bought, REFILL_FLOOR)


## Might gained per second.
func rate() -> float:
	return capacity / refill_seconds


## Refills `delta` seconds' worth, clamped at capacity.
func advance(delta: float) -> void:
	value = minf(value + rate() * delta, capacity)


## True when `cost` can be paid now.
func can_pay(cost: float) -> bool:
	return value + EPSILON >= cost


## Pays `cost`; false and unchanged when it cannot.
func pay(cost: float) -> bool:
	if not can_pay(cost):
		return false
	value = maxf(value - cost, 0.0)
	return true


## Fills the gauge.
func refill() -> void:
	value = capacity


## Whole Might held, the number the bar shows.
func whole() -> int:
	return floori(value + EPSILON)
