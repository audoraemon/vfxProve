class_name Duty
extends RefCounted
## The base of a guard job kind (soldier duties). A duty posts its jobs on the board's tick and owns their steps, tags and
## drawing; it never picks men: GuardJobs alone decides who goes where. Every virtual does nothing by default.

## The board this duty is registered on and the crowd it works in.
var board: GuardJobs
var crowd: Crowd


## Wires the duty to its board and crowd.
func setup(b: GuardJobs, c: Crowd) -> Duty:
	board = b
	crowd = c
	return self


## Which GuardJobs.Kind this duty posts (-1: none).
func kind() -> int:
	return -1


## Once a board tick: look for work and `board.post()` it.
func post_jobs() -> void:
	pass


## Whether `p` may take `job` (on top of being free).
func may_take(_job: GuardJobs.Job, _p: Person) -> bool:
	return true


## Where "nearest free man first" is measured from.
func target(job: GuardJobs.Job) -> Vector2:
	return job.at


## How many more men a job that once had its full crew still wants (the fixed-crew rule).
func refills(_job: GuardJobs.Job) -> int:
	return 0


## Whether a man may be pulled off another post for this job when no free man is left.
func may_pull(_job: GuardJobs.Job) -> bool:
	return false


## A man was put on the job.
func on_taken(_job: GuardJobs.Job, _p: Person) -> void:
	pass


## Whether a crew man is still doing the job (false: the board drops him).
func still_on(_job: GuardJobs.Job, _p: Person) -> bool:
	return true


## A man left the job (dropped, dead, or the job ended).
func on_dropped(_job: GuardJobs.Job, _p: Person) -> void:
	pass


## Every frame for each live job of this kind: only counts clocks, never searches.
func tick(_job: GuardJobs.Job, _delta: float) -> void:
	pass


## Whether the job is over (the board ends it at its next tick).
func done(_job: GuardJobs.Job) -> bool:
	return false


## The map tags of one live job.
func tags(_job: GuardJobs.Job) -> Array[MapTag]:
	return []


## Map tags of this duty that belong to no job (a standing duty's: the gate guards), after the jobs' own.
func standing_tags() -> Array[MapTag]:
	return []


## The board closed (the Citadel fell): the duty lets go of whatever it set on men that no job of its holds.
func on_close() -> void:
	pass


## Drawing over the people (the response drawer's).
func draw(_canvas: Node2D) -> void:
	pass


## Drawing on the ground, under the people (the response drawer's ground layer).
func draw_ground(_canvas: Node2D) -> void:
	pass


## Whether anything of this duty is on show now (the response drawer redraws while any duty shows).
func showing() -> bool:
	return false


## A new crowd or act: forget everything.
func clear() -> void:
	pass
