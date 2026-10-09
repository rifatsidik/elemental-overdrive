extends Node2D
class_name OverdriveCombatant

const STATUS_CONTROLLER_SCRIPT = preload("res://scripts/combat/status_controller.gd")

signal damaged(amount: float, source_element: StringName, remaining_health: float)
signal healed(amount: float, remaining_health: float)
signal impulse_received(impulse: Vector2)
signal defeated

@export var combatant_id: StringName = &""
@export_range(1.0, 100000.0, 1.0) var max_health: float = 100.0
@export var destroy_on_defeat: bool = false

var current_health: float = 100.0
var is_defeated: bool = false
var status_controller: OverdriveStatusController

func _ready() -> void:
	current_health = clampf(current_health, 0.0, max_health)
	if combatant_id == &"":
		combatant_id = StringName("combatant_%d" % get_instance_id())
	status_controller = STATUS_CONTROLLER_SCRIPT.new()
	status_controller.name = "StatusController"
	status_controller.host = self
	add_child(status_controller)

func apply_damage(amount: float, source_element: StringName = &"") -> float:
	if is_defeated or amount <= 0.0:
		return 0.0
	var applied := minf(current_health, amount)
	current_health = maxf(0.0, current_health - applied)
	damaged.emit(applied, source_element, current_health)
	if current_health <= 0.0:
		is_defeated = true
		defeated.emit()
		if destroy_on_defeat:
			queue_free()
	return applied

func apply_heal(amount: float) -> float:
	if is_defeated or amount <= 0.0:
		return 0.0
	var before := current_health
	current_health = minf(max_health, current_health + amount)
	var applied := current_health - before
	if applied > 0.0:
		healed.emit(applied, current_health)
	return applied

func apply_status(status_id: StringName, duration: float, parameters: Dictionary = {}) -> bool:
	if not is_instance_valid(status_controller):
		return false
	return status_controller.apply_status(status_id, duration, parameters)

func has_status(status_id: StringName) -> bool:
	return is_instance_valid(status_controller) and status_controller.has_status(status_id)

func apply_impulse(direction: Vector2, magnitude: float) -> Vector2:
	if is_defeated or magnitude <= 0.0 or direction.is_zero_approx():
		return Vector2.ZERO
	var impulse := direction.normalized() * magnitude
	if self is RigidBody2D:
		(self as RigidBody2D).apply_central_impulse(impulse)
	elif self is CharacterBody2D:
		(self as CharacterBody2D).velocity += impulse
	impulse_received.emit(impulse)
	return impulse

func get_health_ratio() -> float:
	if max_health <= 0.0:
		return 0.0
	return current_health / max_health
