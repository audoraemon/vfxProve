class_name Overrides
extends RefCounted
## A town's changes to a mission (v0.12, spec 1.5): {"def": {MissionDef property: value}, "director": {director town var: value}},
## from CityDef.mission_overrides(). apply() sets each key with set() and reports every key it could not set, so an override
## can never be silent: an unknown key, a value of another type than the property holds, or a value the property did not take.

## The two sections of an overrides dictionary.
const KEYS := ["def", "director"]


## Sets each of `values` on `target`. Returns (and push_errors) the keys it did not set: no such property, a value whose type
## differs from the property's current one (an override file writes floats with a decimal point and tags as &"..."), or a
## value that is not what the property reads back. A typed array property takes an untyped literal through assign().
static func apply(target: Object, values: Dictionary) -> PackedStringArray:
	var bad := PackedStringArray()
	var props := {}
	for p: Dictionary in target.get_property_list():
		props[p["name"]] = true
	for key: Variant in values:
		var prop := String(key)
		if not props.has(prop):
			bad.append(prop)
			push_error("Overrides: %s has no property '%s'" % [_name_of(target), prop])
			continue
		var want: Variant = values[key]
		var now: Variant = target.get(prop)
		if now != null and typeof(want) != typeof(now):
			bad.append(prop)
			push_error("Overrides: '%s' of %s is a %s, not a %s" % [prop, _name_of(target), type_string(typeof(now)), type_string(typeof(want))])
			continue
		if now is Array and (now as Array).is_typed():
			var typed := Array([], (now as Array).get_typed_builtin(), (now as Array).get_typed_class_name(), (now as Array).get_typed_script())
			typed.assign(want)
			# assign() of elements that cannot convert only prints an engine error and leaves the copy short or empty.
			var same := typed.size() == (want as Array).size()
			for i in (typed.size() if same else 0):
				same = same and typeof(typed[i]) == typeof(want[i]) and typed[i] == want[i]
			if not same:
				bad.append(prop)
				push_error("Overrides: '%s' of %s has elements of the wrong type" % [prop, _name_of(target)])
				continue
			want = typed
		target.set(prop, want)
		if target.get(prop) != want:
			bad.append(prop)
			push_error("Overrides: '%s' of %s did not take the value" % [prop, _name_of(target)])
	return bad


static func _name_of(target: Object) -> String:
	var script := target.get_script() as Script
	if script != null and script.resource_path != "":
		return script.resource_path.get_file()
	return target.get_class()
