class_name UiScaleNotifier
extends RefCounted
## UiScale is all statics and a static class cannot own a signal, so this object carries it. Emitted after every apply.

signal changed(layout: Dictionary)
