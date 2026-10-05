class_name GazeMeter
extends RefCounted
## Halcyon's Gaze (v0.10, spec §3.4): how near the Lantern is to looking at the town, from 0 to FULL. It never falls
## during a night. A death someone sees adds SEEN_DEATH; each Faithful praying adds PRAYER_PER_SECOND, at most
## PRAYER_CAP a second in all; the searchlight touching its quarry adds SEARCHLIGHT; a report reaching the Temple, or
## the bell, fills it. Full, it says so once (`filled`), and GazeObjective loses the night.

signal filled

const FULL := 100.0
const SEEN_DEATH := 10.0
const PRAYER_PER_SECOND := 1.0
const PRAYER_CAP := 6.0
const SEARCHLIGHT := 50.0

var value := 0.0


func add(amount: float) -> void:
	if amount <= 0.0 or is_full():
		return
	value = minf(FULL, value + amount)
	if is_full():
		filled.emit()


func seen_death() -> void:
	add(SEEN_DEATH)


## `praying` Faithful at prayer for `delta` seconds.
func pray(praying: int, delta: float) -> void:
	add(minf(float(praying) * PRAYER_PER_SECOND, PRAYER_CAP) * delta)


func fill() -> void:
	add(FULL)


func fraction() -> float:
	return value / FULL


func is_full() -> bool:
	return value >= FULL
