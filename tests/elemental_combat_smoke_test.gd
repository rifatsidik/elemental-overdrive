extends SceneTree

const EXECUTOR_SCRIPT = preload("res://scripts/combat/ability_executor.gd")
const RESOLVER_SCRIPT = preload("res://scripts/elements/interaction_resolver.gd")
const ELEMENT_SCRIPT = preload("res://scripts/elements/element_definition.gd")

func _initialize() -> void:
	var executor: Node = EXECUTOR_SCRIPT.new()
	root.add_child.call_deferred(executor)
	call_deferred("_run_tests", executor)

func _run_tests(executor: Node) -> void:
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
		"cooldown": 1.0
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

	var element = ELEMENT_SCRIPT.new()
	element.element_id = &"test_element"
	assert(element.to_payload().get("element_id") == &"test_element")

	print("OVERDRIVE elemental combat smoke tests: PASS")
	executor.queue_free()
	quit(0)
