extends Node
class_name OverdriveAbilityExecutor

const ELEMENT_DEFINITION_SCRIPT = preload("res://scripts/elements/element_definition.gd")
const INTERACTION_RESOLVER_SCRIPT = preload("res://scripts/elements/interaction_resolver.gd")

signal ability_executed(result: Dictionary)
signal ability_rejected(ability_id: StringName, reason: String)

## This executor resolves an ability into a simulation event. The caller remains
## responsible for authoritative hit detection, health, impulses, and world state.
## It deliberately has no dependency on VFX quality or renderer nodes.

var _elements: Dictionary = {}
var _cooldowns: Dictionary = {}
var _interaction_resolver = INTERACTION_RESOLVER_SCRIPT.new()

func _process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, float(_cooldowns[key]) - delta)

func register_element(definition: Resource) -> bool:
	if definition == null:
		return false
	var raw_id: Variant = definition.get("element_id")
	if raw_id == null or String(raw_id).is_empty():
		push_warning("Cannot register an elemental definition without element_id.")
		return false
	_elements[StringName(raw_id)] = definition
	return true

func register_default_elements() -> void:
	_register_default(&"lightning", "Lightning", Color(0.18, 0.92, 1.0, 1.0), 1.0, 1.0, &"charged", 1.0, 4, [&"conductive", &"fast"])
	_register_default(&"wind", "Wind", Color(0.55, 1.0, 0.82, 1.0), 0.8, 1.35, &"staggered", 0.7, 2, [&"force", &"redirect"])
	_register_default(&"fire", "Fire", Color(1.0, 0.34, 0.08, 1.0), 1.15, 0.9, &"burning", 2.5, 1, [&"heat", &"flammable"])
	_register_default(&"water", "Water", Color(0.12, 0.48, 1.0, 1.0), 0.9, 1.1, &"soaked", 1.5, 2, [&"wet", &"pressure"])

func _register_default(
	element_id: StringName,
	display_name: String,
	visual_color: Color,
	damage_scale: float,
	impulse_scale: float,
	status_id: StringName,
	status_duration: float,
	max_chain_targets: int,
	tags: Array
) -> void:
	var definition = ELEMENT_DEFINITION_SCRIPT.new()
	definition.set("element_id", element_id)
	definition.set("display_name", display_name)
	definition.set("visual_color", visual_color)
	definition.set("damage_scale", damage_scale)
	definition.set("impulse_scale", impulse_scale)
	definition.set("status_id", status_id)
	definition.set("status_duration", status_duration)
	definition.set("max_chain_targets", max_chain_targets)
	definition.set("tags", tags)
	register_element(definition)

func has_element(element_id: StringName) -> bool:
	return _elements.has(element_id)

func get_element_payload(element_id: StringName) -> Dictionary:
	if not _elements.has(element_id):
		return {}
	return _elements[element_id].to_payload()

func execute_ability(ability: Dictionary, context: Dictionary = {}) -> Dictionary:
	var ability_id := StringName(ability.get("ability_id", &""))
	var element_id := StringName(ability.get("element_id", &""))
	if ability_id == &"":
		return _reject(ability_id, "missing_ability_id")
	if not _elements.has(element_id):
		return _reject(ability_id, "unknown_element")
	if not bool(ability.get("enabled", true)):
		return _reject(ability_id, "ability_disabled")

	var caster_id := StringName(context.get("caster_id", &"default"))
	var cooldown_key := "%s::%s" % [String(caster_id), String(ability_id)]
	if float(_cooldowns.get(cooldown_key, 0.0)) > 0.0:
		return _reject(ability_id, "cooldown_active")

	var definition: Resource = _elements[element_id]
	var damage: float = maxf(0.0, float(ability.get("damage", 10.0)))
	var impulse: float = maxf(0.0, float(ability.get("impulse", 0.0)))
	var status_id: StringName = StringName(definition.get("status_id"))
	var status_duration: float = maxf(0.0, float(definition.get("status_duration")))
	var damage_multiplier := float(definition.get("damage_scale"))
	var impulse_multiplier := float(definition.get("impulse_scale"))
	var max_targets := maxi(1, int(definition.get("max_chain_targets")))
	var reaction: Dictionary = _interaction_resolver._no_reaction()

	var secondary_id := StringName(context.get("secondary_element_id", &""))
	if secondary_id != &"":
		reaction = _interaction_resolver.resolve(element_id, secondary_id, context)
		if bool(reaction.get("triggered", false)):
			damage_multiplier *= float(reaction.get("damage_multiplier", 1.0))
			impulse_multiplier *= float(reaction.get("impulse_multiplier", 1.0))
			var reaction_status := StringName(reaction.get("status_id", &""))
			if reaction_status != &"":
				status_id = reaction_status
				status_duration = maxf(status_duration, float(reaction.get("status_duration", 0.0)))
			max_targets = mini(max_targets, maxi(1, int(reaction.get("max_chain_targets", 1))))

	var requested_targets: Array = context.get("target_ids", [])
	var resolved_targets: Array = []
	for target_id in requested_targets:
		if resolved_targets.size() >= max_targets:
			break
		if target_id != null and not resolved_targets.has(target_id):
			resolved_targets.append(target_id)

	var cooldown_seconds := maxf(0.0, float(ability.get("cooldown", 0.0)))
	if cooldown_seconds > 0.0:
		_cooldowns[cooldown_key] = cooldown_seconds

	var result := {
		"accepted": true,
		"ability_id": ability_id,
		"element_id": element_id,
		"visual_color": definition.get("visual_color"),
		"base_damage": damage,
		"damage": damage * damage_multiplier,
		"base_impulse": impulse,
		"impulse": impulse * impulse_multiplier,
		"status_id": status_id,
		"status_duration": status_duration,
		"target_ids": resolved_targets,
		"max_chain_targets": max_targets,
		"reaction": reaction,
		"cooldown": cooldown_seconds,
		"context": context.duplicate(true)
	}
	ability_executed.emit(result)
	return result

func _reject(ability_id: StringName, reason: String) -> Dictionary:
	var result := {"accepted": false, "ability_id": ability_id, "reason": reason}
	ability_rejected.emit(ability_id, reason)
	return result
