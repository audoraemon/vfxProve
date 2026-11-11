class_name AnimalVoices
extends RefCounted
## The town's dogs and cats, heard (natural sound pass 5). AnimalPack says what an animal just did (say()): it barks or
## meows at rest, yelps or hisses as it runs from danger, growls or yowls when a power turns it, snaps or hisses as it
## bites, and cries out as it dies. The cue fits the kind (a dog's or a cat's) and is pitched to the breed: a wolfhound
## low, a terrier high. It draws from its own rng and changes nothing the animals or the crowd read, so behaviour is the
## same whether or not anyone listens. A token budget (TOKENS, refilled REFILL a second) and a rest per animal (REST)
## keep a pack from drowning the town; a death skips the chance and the rest, but not the budget.

enum Act { IDLE, FLEE, ANGRY, BITE, DIE, CALL }

## Per act: the dog's cue, the cat's cue, and the chance it makes a sound at all.
const CUES := {
	Act.IDLE: [&"dog_bark", &"cat_meow", 0.7],
	Act.FLEE: [&"dog_yelp", &"cat_hiss", 0.5],
	Act.ANGRY: [&"dog_growl", &"cat_yowl", 1.0],
	Act.BITE: [&"dog_bark", &"cat_hiss", 0.6],
	Act.DIE: [&"dog_yelp", &"cat_yowl", 1.0],
	Act.CALL: [&"dog_bark", &"cat_meow", 1.0],  # Ambience's call near the camera: always heard
}
## Each breed's voice: big dogs lower, small ones higher; the cats near their own.
const PITCH := {
	Animal.Breed.HOUND: 0.95, Animal.Breed.SHEPHERD: 0.9, Animal.Breed.TERRIER: 1.18, Animal.Breed.WOLFHOUND: 0.8,
	Animal.Breed.SPANIEL: 1.08, Animal.Breed.TABBY: 1.0, Animal.Breed.BLACK_CAT: 0.94, Animal.Breed.GREY_CAT: 1.04,
	Animal.Breed.WHITE_CAT: 1.1, Animal.Breed.BROWN_CAT: 0.97,
}
## A call at rest is a little softer than one in alarm, and a dying cry a little lower.
const IDLE_DB := -1.5
const DIE_PITCH := 0.92
const TOKENS := 4.0
const REFILL := 2.5
const REST := 1.2
const SEED := 5150

var played := 0  ## cues handed out

var _rng := RandomNumberGenerator.new()
var _tokens := TOKENS
var _clock := 0.0
var _rest := {}  ## animal instance id -> clock it may sound again


func _init() -> void:
	_rng.seed = SEED


func step(delta: float) -> void:
	_clock += delta
	_tokens = minf(TOKENS, _tokens + REFILL * delta)


## The cue for `dog` (or a cat) with instance id `id` doing `act`, or &"" when it stays quiet. Plays nothing.
func pick(id: int, dog: bool, act: Act) -> StringName:
	var row: Array = CUES[act]
	if act != Act.DIE:
		if float(_rest.get(id, -INF)) > _clock or _rng.randf() >= float(row[2]):
			return &""
	if _tokens < 1.0:
		return &""
	_tokens -= 1.0
	_rest[id] = _clock + REST
	played += 1
	return row[0] if dog else row[1]


## Plays what `a` doing `act` sounds like, at the animal, through `sfx` (an Sfx).
func say(sfx: Node, a: Animal, act: Act) -> void:
	if sfx == null or a == null:
		return
	var cue := pick(a.get_instance_id(), a.is_dog(), act)
	if cue == &"":
		return
	var p: AudioStreamPlayer2D = sfx.play(cue, a.ground_pos, IDLE_DB if act in [Act.IDLE, Act.CALL] else 0.0)
	if p != null:
		sfx.set_voice_pitch(p, float(PITCH.get(a.breed, 1.0)) * (DIE_PITCH if act == Act.DIE else 1.0))
