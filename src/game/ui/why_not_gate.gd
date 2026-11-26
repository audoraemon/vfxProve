class_name WhyNotGate
extends RefCounted
## The rate limit on a why-not banner (Mission clarity, spec 6.1): a cast that landed on a target and did not count says why, but never
## twice in REPEAT seconds for the same words, and never within GAP seconds of the last one shown, so a Heaven Splitter's strokes or two
## casts a second apart put up one banner. Pure bookkeeping on the clock the HUD hands it (real seconds); it reads and writes nothing else.

const REPEAT := 30.0
const GAP := 4.0

## The text -> the clock it was last shown at.
var _shown := {}
var _last := -INF


## Whether `text` may be shown at `now`; true records it as shown. "" is never shown.
func allow(text: String, now: float) -> bool:
	if text == "":
		return false
	if now - _last < GAP:
		return false
	if _shown.has(text) and now - float(_shown[text]) < REPEAT:
		return false
	_shown[text] = now
	_last = now
	return true
