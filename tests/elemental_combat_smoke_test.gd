extends SceneTree

const EXECUTOR_SCRIPT = preload("res://scripts/combat/ability_executor.gd")
const WORLD_ADAPTER_SCRIPT = preload("res://scripts/combat/world_adapter.gd")
const COMBATANT_SCRIPT = preload("res://scripts/combat/combatant.gd")
const RESOLVER_SCRIPT = preload("res://scripts/elements/interaction_resolver.gd")
const ELEMENT_SCRIPT = preload("res://scripts/elements/element_definition.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var executor = EXECUTOR_SCRIPT.new()
	root.add_child(executor)
	executor.register_default_elements()
	assert(executor.has_element(&"lightning"))
	assert(executor.has_element(&"wind"))
	assert(executor.has_element(&"fire"))
	assert(executor.has_element(&"water"))

	var ability := {
		"ability_id": &"test_arc",
		"element_id": &"lightning",
		"damage": 10.0,
		"impulse": 5.0,
		"cooldown": 1.0,
		"chain": true
	}
	var result: Dictionary = executor.execute_ability(ability, {
		"caster_id": &"test_caster",
		"target_ids": ["a", "b", "a", "c", "d"]
	})
	assert(bool(result.get("accepted", false)))
	assert(is_finite(float(result.get("damage", -1.0))))
	assert(result.get("target_ids", []).size() == 4)

	var cooldown_result: Dictionary = executor.execute_ability(ability, {"caster_id": &"test_caster"})
	assert(not bool(cooldown_result.get("accepted", true)))
	assert(String(cooldown_result.get("reason", "")) == "cooldown_active")

	var invalid_result: Dictionary = executor.execute_ability({"ability_id": &"bad", "element_id": &"unknown"})
	assert(not bool(invalid_result.get("accepted", true)))

	var resolver = RESOLVER_SCRIPT.new()
	var forward: Dictionary = resolver.resolve(&"lightning", &"water", {"wet_surface": true})
	var reverse: Dictionary = resolver.resolve(&"water", &"lightning", {"wet_surface": true})
	assert(forward.get("reaction_id") == "conductive_chain")
	assert(forward.get("reaction_id") == reverse.get("reaction_id"))
	assert(int(forward.get("max_chain_targets", 0)) == 5)
	assert(executor.get_chain_budget(&"lightning", &"water", {"wet_surface": true}) == 5)

	var element = ELEMENT_SCRIPT.new()
	element.element_id = &"test_element"
	assert(element.to_payload().get("element_id") == &"test_element")

	var adapter = WORLD_ADAPTER_SCRIPT.new()
	root.add_child(adapter)
	var combatant = COMBATANT_SCRIPT.new()
	combatant.combatant_id = &"dummy"
	combatant.position = Vector2(24.0, 0.0)
	root.add_child(combatant)
	var world_result: Dictionary = adapter.execute_ability(
		{
			"ability_id": &"test_fire",
			"element_id": &"fire",
			"damage": 10.0,
			"impulse": 0.0,
			"max_range": 100.0
		},
		null,
		[combatant]
	)
	assert(bool(world_result.get("accepted", false)))
	assert(int(world_result.get("hit_count", 0)) == 1)
	assert(combatant.current_health < combatant.max_health)
	assert(combatant.has_status(&"burning"))

	print("OVERDRIVE elemental combat smoke tests: PASS")
	root.remove_child(combatant)
	combatant.free()
	root.remove_child(adapter)
	adapter.free()
	root.remove_child(executor)
	executor.free()
	quit(0)
