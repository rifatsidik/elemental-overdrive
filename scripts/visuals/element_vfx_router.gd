extends Node2D
class_name OverdriveElementVFXRouter

const LIGHTNING_SCRIPT = preload("res://scripts/visuals/energy_burst.gd")
const WIND_SCRIPT = preload("res://scripts/visuals/elements/wind_burst.gd")
const FIRE_SCRIPT = preload("res://scripts/visuals/elements/fire_burst.gd")
const WATER_SCRIPT = preload("res://scripts/visuals/elements/water_burst.gd")
const PROJECTILE_SCRIPT = preload("res://scripts/visuals/elements/element_projectile.gd")
const SKILL_SCRIPT = preload("res://scripts/visuals/elements/element_skill_effect.gd")

@export_range(1, 64, 1) var max_active_effects: int = 24
var branch_budget: int = 4
var layer_budget: int = 2
var _sequence: int = 0

const SKILL_ELEMENT := {
	&"fire_tornado": &"fire",
	&"fire_burst": &"fire",
	&"water_jet_burst": &"water",
	&"water_torrent": &"water",
	&"wind_cyclone": &"wind",
	&"wind_blade_storm": &"wind"
}

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

## Explicit skill presentation API for future abilities. Does not alter combat simulation.
func play_skill(skill_id: StringName, world_position: Vector2, scale: float = 1.0) -> bool:
	if not SKILL_ELEMENT.has(skill_id) or get_child_count() >= max_active_effects:
		return false
	_sequence += 1
	var effect = SKILL_SCRIPT.new()
	effect.name = "SkillVFX_%s_%03d" % [String(skill_id), _sequence]
	effect.position = to_local(world_position)
	add_child(effect)
	effect.configure(skill_id, int((Time.get_ticks_usec() + _sequence * 104729) % 2147483647), scale, layer_budget)
	return true

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
		var strength := _strength_from_damage(float(result.get("damage", 10.0))) * _element_size_multiplier(effect_element)
		if effect_element == &"fire" or effect_element == &"water" or effect_element == &"wind":
			if _spawn_projectile(effect_element, source_local, target_local, strength, color):
				continue
		_spawn_effect(effect_element, target_local, source_local - target_local, strength, color)

func _spawn_projectile(element_id: StringName, source: Vector2, target: Vector2, strength: float, color: Color) -> bool:
	if source.distance_to(target) < 20.0 or get_child_count() >= max_active_effects:
		return false
	_sequence += 1
	var projectile = PROJECTILE_SCRIPT.new()
	projectile.name = "ProjectileVFX_%s_%03d" % [String(element_id), _sequence]
	projectile.position = source
	add_child(projectile)
	projectile.arrived.connect(_on_projectile_arrived)
	projectile.configure(element_id, target - source, strength, int((Time.get_ticks_usec() + _sequence * 7919) % 2147483647), layer_budget, color)
	return true

func _on_projectile_arrived(element_id: StringName, target: Vector2, source: Vector2, strength: float, color: Color) -> void:
	if get_child_count() >= max_active_effects:
		return
	_spawn_effect(element_id, target, source - target, strength, color)

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
			return 2.0
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
