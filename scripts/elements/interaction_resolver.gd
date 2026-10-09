extends RefCounted
class_name OverdriveInteractionResolver

## Pure rules layer: returns gameplay modifiers and presentation hints.
## It never applies damage, moves bodies, or spawns visual effects.

func resolve(primary_element: StringName, secondary_element: StringName, context: Dictionary = {}) -> Dictionary:
	if primary_element == &"" or secondary_element == &"":
		return _no_reaction()

	var pair: Array[String] = [String(primary_element), String(secondary_element)]
	pair.sort()
	var pair_key := "%s|%s" % [pair[0], pair[1]]

	match pair_key:
		"fire|wind":
			return _reaction("fire_spread", "Wind feeds and directs the flame.", 1.15, 1.25, &"burning", 1.5, 1)
		"fire|water":
			return _reaction("steam_burst", "Water suppresses fire and creates a steam burst.", 0.65, 0.8, &"steamed", 0.8, 1)
		"lightning|water":
			var wet_surface: bool = bool(context.get("wet_surface", false))
			var targets := 5 if wet_surface else 3
			return _reaction("conductive_chain", "Water conducts the strike along a bounded chain.", 1.0, 1.0, &"charged", 1.2, targets)
		"water|wind":
			return _reaction("driven_spray", "Wind redirects water and increases its push.", 0.9, 1.4, &"soaked", 1.0, 1)
		"lightning|wind":
			return _reaction("ionized_gust", "A gust bends the arc toward nearby targets.", 1.05, 1.15, &"charged", 1.0, 4)
		_:
			if primary_element == secondary_element:
				return _reaction("elemental_resonance", "Matching elements resonate.", 1.1, 1.0, &"", 0.0, 1)
			return _no_reaction()

func _reaction(
	reaction_id: String,
	description: String,
	damage_multiplier: float,
	impulse_multiplier: float,
	status_id: StringName,
	status_duration: float,
	max_chain_targets: int
) -> Dictionary:
	return {
		"triggered": true,
		"reaction_id": reaction_id,
		"description": description,
		"damage_multiplier": damage_multiplier,
		"impulse_multiplier": impulse_multiplier,
		"status_id": status_id,
		"status_duration": status_duration,
		"max_chain_targets": max_chain_targets
	}

func _no_reaction() -> Dictionary:
	return {
		"triggered": false,
		"reaction_id": "none",
		"description": "",
		"damage_multiplier": 1.0,
		"impulse_multiplier": 1.0,
		"status_id": &"",
		"status_duration": 0.0,
		"max_chain_targets": 1
	}
