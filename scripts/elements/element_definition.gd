extends Resource
class_name OverdriveElementDefinition

## Data-only description of an element. Keep simulation properties separate
## from its renderer so visual quality cannot alter combat outcomes.

@export var element_id: StringName = &"lightning"
@export var display_name: String = "Lightning"
@export var visual_color: Color = Color(0.18, 0.92, 1.0, 1.0)
@export_range(0.0, 5.0, 0.05) var damage_scale: float = 1.0
@export_range(0.0, 5.0, 0.05) var impulse_scale: float = 1.0
@export var status_id: StringName = &"charged"
@export_range(0.0, 30.0, 0.1) var status_duration: float = 1.0
@export_range(1, 16, 1) var max_chain_targets: int = 3
@export var tags: Array[StringName] = []

func to_payload() -> Dictionary:
	return {
		"element_id": element_id,
		"display_name": display_name,
		"visual_color": visual_color,
		"damage_scale": damage_scale,
		"impulse_scale": impulse_scale,
		"status_id": status_id,
		"status_duration": status_duration,
		"max_chain_targets": max_chain_targets,
		"tags": tags.duplicate()
	}
