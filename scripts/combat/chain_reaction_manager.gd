extends RefCounted
class_name OverdriveChainReactionManager

## Selects chain candidates without applying damage. Callers own authoritative
## hit application. Instance IDs are used to guard duplicates and cycles.

func select_targets(
	origin: Vector2,
	candidates: Array,
	excluded_instance_ids: Array[int],
	max_targets: int,
	max_distance: float
) -> Array[Node2D]:
	var available: Array[Dictionary] = []
	var seen: Dictionary = {}
	for candidate in candidates:
		if not is_instance_valid(candidate) or not candidate is Node2D:
			continue
		if candidate.has_method("get") and bool(candidate.get("is_defeated")):
			continue
		var instance_id: int = candidate.get_instance_id()
		if excluded_instance_ids.has(instance_id) or seen.has(instance_id):
			continue
		var distance := origin.distance_to((candidate as Node2D).global_position)
		if max_distance > 0.0 and distance > max_distance:
			continue
		seen[instance_id] = true
		available.append({"node": candidate, "distance": distance, "instance_id": instance_id})
	available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance"]) < float(b["distance"])
	)
	var result: Array[Node2D] = []
	var limit := clampi(max_targets, 0, 32)
	for entry in available:
		if result.size() >= limit:
			break
		result.append(entry["node"] as Node2D)
	return result
