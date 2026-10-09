extends Node
class_name OverdriveCombatWorldAdapter

const EXECUTOR_SCRIPT = preload("res://scripts/combat/ability_executor.gd")
const CHAIN_MANAGER_SCRIPT = preload("res://scripts/combat/chain_reaction_manager.gd")

signal ability_resolved(result: Dictionary)
signal hit_applied(caster: Node, target: Node, hit: Dictionary)
signal reaction_triggered(reaction: Dictionary)

var executor: OverdriveAbilityExecutor
var chain_manager: OverdriveChainReactionManager

func _ready() -> void:
	executor = EXECUTOR_SCRIPT.new()
	executor.name = "AbilityExecutor"
	executor.register_default_elements()
	add_child(executor)
	chain_manager = CHAIN_MANAGER_SCRIPT.new()

## targets must already be candidate hits from a collision/raycast/overlap query.
## The adapter performs final range, type, defeat, and duplicate validation.
## It does not discover targets by scanning the entire scene.
func execute_ability(
	ability: Dictionary,
	caster: Node2D,
	targets: Array,
	context: Dictionary = {}
) -> Dictionary:
	if not is_instance_valid(executor):
		return {"accepted": false, "reason": "executor_unavailable"}

	var resolved_context := context.duplicate(false)
	var origin: Vector2 = caster.global_position if is_instance_valid(caster) else Vector2.ZERO
	if resolved_context.get("origin") is Vector2:
		origin = resolved_context["origin"]
	resolved_context["origin"] = origin
	resolved_context["caster_id"] = StringName(
		resolved_context.get("caster_id", caster.name if is_instance_valid(caster) else &"environment")
	)

	var candidate_targets := targets.duplicate()
	if bool(ability.get("chain", false)):
		var candidates: Array = resolved_context.get("chain_candidates", targets)
		var excluded: Array[int] = []
		for target in targets:
			if is_instance_valid(target):
				excluded.append(target.get_instance_id())
		var element_id := StringName(ability.get("element_id", &""))
		var secondary_id := StringName(resolved_context.get("secondary_element_id", &""))
		var chain_limit := executor.get_chain_budget(element_id, secondary_id, resolved_context)
		var chain_origin := origin
		if not targets.is_empty() and is_instance_valid(targets[0]) and targets[0] is Node2D:
			chain_origin = (targets[0] as Node2D).global_position
		var chained := chain_manager.select_targets(
			chain_origin,
			candidates,
			excluded,
			chain_limit,
			maxf(0.0, float(ability.get("chain_range", 360.0)))
		)
		for target in chained:
			candidate_targets.append(target)

	var max_range := maxf(0.0, float(ability.get("max_range", 1200.0)))
	var valid_targets: Array[OverdriveCombatant] = []
	var target_ids: Array[String] = []
	var seen_ids: Dictionary = {}
	var seen_combatant_ids: Dictionary = {}
	for target in candidate_targets:
		if not is_instance_valid(target) or not target is OverdriveCombatant:
			continue
		var combatant := target as OverdriveCombatant
		if combatant.is_defeated:
			continue
		var instance_id := combatant.get_instance_id()
		var stable_id := String(combatant.combatant_id)
		if seen_ids.has(instance_id) or seen_combatant_ids.has(stable_id):
			continue
		if max_range > 0.0 and origin.distance_to(combatant.global_position) > max_range:
			continue
		seen_ids[instance_id] = true
		seen_combatant_ids[stable_id] = true
		valid_targets.append(combatant)
		target_ids.append(String(combatant.combatant_id))
	resolved_context["target_ids"] = target_ids

	var result := executor.execute_ability(ability, resolved_context)
	if not bool(result.get("accepted", false)):
		ability_resolved.emit(result)
		return result

	var allowed_ids: Array = result.get("target_ids", [])
	var hits: Array[Dictionary] = []
	var status_id := StringName(result.get("status_id", &""))
	var status_duration := maxf(0.0, float(result.get("status_duration", 0.0)))
	var damage := maxf(0.0, float(result.get("damage", 0.0)))
	var impulse_magnitude := maxf(0.0, float(result.get("impulse", 0.0)))
	var element_id := StringName(result.get("element_id", &""))
	var status_parameters: Dictionary = ability.get("status_parameters", {})
	for target in valid_targets:
		if not allowed_ids.has(String(target.combatant_id)) or target.is_defeated:
			continue
		var actual_damage := target.apply_damage(damage, element_id)
		var status_applied := false
		if not target.is_defeated and status_id != &"" and status_duration > 0.0:
			var params := status_parameters.duplicate(false)
			params["source_element"] = element_id
			status_applied = target.apply_status(status_id, status_duration, params)
		var impulse := Vector2.ZERO
		var direction := target.global_position - origin
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		if impulse_magnitude > 0.0:
			impulse = target.apply_impulse(direction, impulse_magnitude)
		var hit := {
			"target_id": target.combatant_id,
			"position": target.global_position,
			"damage": actual_damage,
			"health_remaining": target.current_health,
			"status_id": status_id if status_applied else &"",
			"status_applied": status_applied,
			"impulse": impulse
		}
		hits.append(hit)
		hit_applied.emit(caster, target, hit)

	result["hits"] = hits
	result["hit_count"] = hits.size()
	ability_resolved.emit(result)
	var reaction: Dictionary = result.get("reaction", {})
	if bool(reaction.get("triggered", false)):
		reaction_triggered.emit(reaction)
	return result
