extends Node
class_name OverdriveStatusController

signal status_applied(status_id: StringName, duration: float)
signal status_expired(status_id: StringName)
signal burn_tick(damage: float)

## Timed statuses are simulation state, not visual effects.
## Status IDs are extensible; only statuses with explicit behavior cause gameplay changes.

var host: Node
var _statuses: Dictionary = {}

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	for key in _statuses.keys():
		if not _statuses.has(key):
			continue
		var state: Dictionary = _statuses[key]
		state["remaining"] = maxf(0.0, float(state.get("remaining", 0.0)) - delta)
		if StringName(key) == &"burning":
			var interval := maxf(0.1, float(state.get("tick_interval", 0.5)))
			var tick_timer := float(state.get("tick_timer", 0.0)) + delta
			while tick_timer >= interval and float(state["remaining"]) > 0.0:
				tick_timer -= interval
				var damage := maxf(0.0, float(state.get("damage_per_tick", 2.0)))
				if is_instance_valid(host) and host.has_method("apply_damage") and damage > 0.0:
					host.call("apply_damage", damage, &"burning")
					burn_tick.emit(damage)
			state["tick_timer"] = tick_timer
		if float(state["remaining"]) <= 0.0:
			_statuses.erase(key)
			status_expired.emit(StringName(key))
		else:
			_statuses[key] = state

func apply_status(status_id: StringName, duration: float, parameters: Dictionary = {}) -> bool:
	if status_id == &"" or duration <= 0.0:
		return false
	var state: Dictionary = _statuses.get(status_id, {})
	state["remaining"] = maxf(float(state.get("remaining", 0.0)), duration)
	state["tick_interval"] = maxf(0.1, float(parameters.get("tick_interval", state.get("tick_interval", 0.5))))
	state["damage_per_tick"] = maxf(0.0, float(parameters.get("damage_per_tick", state.get("damage_per_tick", 2.0))))
	state["source_element"] = StringName(parameters.get("source_element", state.get("source_element", &"")))
	state["tick_timer"] = float(state.get("tick_timer", 0.0))
	_statuses[status_id] = state
	status_applied.emit(status_id, float(state["remaining"]))
	return true

func remove_status(status_id: StringName) -> bool:
	if not _statuses.has(status_id):
		return false
	_statuses.erase(status_id)
	status_expired.emit(status_id)
	return true

func has_status(status_id: StringName) -> bool:
	return _statuses.has(status_id)

func get_remaining(status_id: StringName) -> float:
	if not _statuses.has(status_id):
		return 0.0
	return float(_statuses[status_id].get("remaining", 0.0))

func clear_all() -> void:
	var keys := _statuses.keys()
	_statuses.clear()
	for key in keys:
		status_expired.emit(StringName(key))

func active_statuses() -> Array[StringName]:
	var result: Array[StringName] = []
	for key in _statuses.keys():
		result.append(StringName(key))
	return result
