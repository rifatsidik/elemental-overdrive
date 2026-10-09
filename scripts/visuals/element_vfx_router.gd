extends Node2D
class_name OverdriveElementVFXRouter

const LIGHTNING_SCRIPT = preload("res://scripts/visuals/energy_burst.gd")
const WIND_SCRIPT = preload("res://scripts/visuals/elements/wind_burst.gd")
const FIRE_SCRIPT = preload("res://scripts/visuals/elements/fire_burst.gd")
const WATER_SCRIPT = preload("res://scripts/visuals/elements/water_burst.gd")

@export_range(1, 64, 1) var max_active_effects: int = 24
var branch_budget: int = 4
var layer_budget: int = 2
var _sequence: int = 0

func bind_adapter(adapter: Node) -> bool:
	if not is_instance_valid(adapter) or not adapter.has_signal("ability_resolved"):
		return false
	var callback := Callable(self, "present_result")
	if not adapter.is_connected("ability_resolved", callback):
		adapter.connect("ability_resolved", callback)
	return true

func set_quality_budgets(branches: int, layers: int, active_limit: int) -> void:
	branch_budget = clampi(branches, 1, 8)
	layer_budget = clampi(layers, 1, 3)
	max_active_effects = clampi(active_limit, 1, 64)

## Presentation-only consumer. Effects never change combat outcomes.
func present_result(result: Dictionary) -> void:
	if not bool(result.get("accepted", false)):
		return
	var hits: Array = result.get("hits", [])
	var element_id := StringName(result.get("element_id", &""))
	var reaction: Dictionary = result.get("reaction", {})
	var reaction_id := StringName(reaction.get("reaction_id", &""))
	var source_world: Vector2 = result.get("origin", global_position)
	var source_local := to_local(source_world)
	for hit in hits:
		if get_child_count() >= max_active_effects:
			break
		if not (hit is Dictionary) or not (hit.get("position") is Vector2):
			continue
		var hit_world: Vector2 = hit["position"]
		var target_local := to_local(hit_world)
		var effect_element := element_id
		var color := _element_color(element_id)
		if reaction_id == &"steam_burst":
			effect_element = &"water"
			color = Color(0.78, 0.92, 1.0, 1.0)
		var size_multiplier := _element_size_multiplier(effect_element)
		_spawn_effect(effect_element, target_local, source_local - target_local, _strength_from_damage(float(result.get("damage", 10.0))) * size_multiplier, color)

func _spawn_effect(element_id: StringName, origin: Vector2, source_offset: Vector2, strength: float, color: Color) -> void:
	_sequence += 1
	var seed_value := int((Time.get_ticks_usec() + _sequence * 7919) % 2147483647)
	var effect: Node2D
	match element_id:
		&"lightning":
			effect = LIGHTNING_SCRIPT.new()
		&"wind":
			effect = WIND_SCRIPT.new()
		&"fire":
			effect = FIRE_SCRIPT.new()
		&"water":
			effect = WATER_SCRIPT.new()
		_:
			return
	effect.position = origin
	effect.name = "ElementVFX_%s_%03d" % [String(element_id), _sequence]
	add_child(effect)
	match element_id:
		&"lightning":
			effect.call("configure", strength, seed_value, branch_budget, layer_budget, source_offset)
		&"wind":
			effect.call("configure", strength, layer_budget, color)
		&"fire":
			effect.call("configure", strength, seed_value, layer_budget, color)
		&"water":
			effect.call("configure", strength, seed_value, layer_budget, color)

func _strength_from_damage(damage: float) -> float:
	return clampf(0.9 + maxf(0.0, damage) / 80.0, 0.9, 1.6)

func _element_size_multiplier(element_id: StringName) -> float:
	match element_id:
		&"lightning":
			return 1.0
		&"wind":
			return 1.7
		&"fire":
			return 1.65
		&"water":
			return 1.8
		_:
			return 1.0

func _element_color(element_id: StringName) -> Color:
	match element_id:
		&"lightning":
			return Color(0.18, 0.92, 1.0, 1.0)
		&"wind":
			return Color(0.55, 1.0, 0.82, 1.0)
		&"fire":
			return Color(1.0, 0.34, 0.08, 1.0)
		&"water":
			return Color(0.12, 0.48, 1.0, 1.0)
		_:
			return Color.WHITE
