class_name Children
extends RefCounted
## The town's children (Discord idea "child population": "make it more natural"). Crowd.spawn_children() adds
## SHARE of the town's grown citizens as children, after everyone else and on a generator of their own (the crowd's
## seed + SEED_OFFSET), so nobody spawned before them moves. Each is a full citizen of Role.CHILD: in a family that has
## grown-ups, at its home, with a few places to play near it, killable and counted like anyone. A frightened child runs
## to a grown-up of its own family nearby (Person.panic()) and keeps close; it leaves with its household. The directors
## never cast a child in a part (Wish.NOT_LAY and the pickers that skip Person.is_child()).
##
## With `enabled` off there are none: the exact references and the suite run without them (as AnimalPack.enabled).

static var enabled := true

## Children per grown citizen spawned (Aldermere's 220: 40).
const SHARE := 0.18
## Their generator's seed past the crowd's (AnimalPack's is its own).
const SEED_OFFSET := 83
## The anchors() kinds a child plays at, and how many of the nearest to home it may pick 1-3 from. When a town has
## none, the grown-ups' leisure (CitizenProfile.LEISURE).
const PLAY := ["plaza", "water"]
const PLAY_NEAREST := 4
## How far from home it starts.
const START_SPREAD := 0.6
## A child's walking pace against a grown-up's (panic and flight are the same).
const WALK_PACE := 1.1
## A frightened child looks for a grown-up of its family within this, and keeps this close to them.
const FOLLOW_REACH := 6.0
const FOLLOW_GAP := 0.6


## How many children a town of `adults` grown citizens has.
static func count_for(adults: int) -> int:
	return roundi(SHARE * float(maxi(adults, 0)))
