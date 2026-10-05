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
## Where people died, waiting for judge_deaths().
var _deaths: Array[Vector2] = []


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


## Someone died at `at` (v0.10 M3, for every Night 2 director): judge_deaths() decides whether anyone saw it.
func note_death(at: Vector2) -> void:
	_deaths.append(at)


## Each noted death that someone living saw (Crowd.nearest_witness()) adds SEEN_DEATH. It waits while the crowd is
## still judging a Silent Doom's victims, so a cast's victims never witness each other.
func judge_deaths(crowd: Crowd) -> void:
	if _deaths.is_empty() or crowd == null or not crowd._doomed.is_empty():
		return
	for at in _deaths:
		if crowd.nearest_witness(at) != null:
			seen_death()
	_deaths.clear()
