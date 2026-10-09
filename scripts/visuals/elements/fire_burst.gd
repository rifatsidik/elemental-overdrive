extends Node2D
class_name OverdriveFireBurst

var age: float = 0.0
var lifetime: float = 0.72
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(1.0, 0.34, 0.08, 1.0)
var _flame_angles: PackedFloat32Array = PackedFloat32Array()
var _flame_lengths: PackedFloat32Array = PackedFloat32Array()
var _ember_velocities: Array[Vector2] = []
var _ember_sizes: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(1.0, 0.34, 0.08, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.25)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_flame_angles.clear()
	_flame_lengths.clear()
	_ember_velocities.clear()
	_ember_sizes.clear()
	for i in range(9 + layer_budget * 5):
		_flame_angles.append(_rng.randf_range(-PI, PI))
		_flame_lengths.append(_rng.randf_range(34.0, 82.0))
	for i in range(10 + layer_budget * 5):
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(55.0, 230.0)
		_ember_velocities.append(Vector2.from_angle(angle) * speed + Vector2(0.0, -_rng.randf_range(25.0, 125.0)))
		_ember_sizes.append(_rng.randf_range(1.3, 3.6))
	age = 0.0
	queue_redraw()

func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	set_process(true)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - progress
	var flare := 1.0 - smoothstep(0.0, 0.22, age)
	# Hot core, orange bloom, and two rapidly expanding heat fronts.
	draw_circle(Vector2.ZERO, (18.0 + 18.0 * flare) * strength, Color(1.0, 0.12, 0.015, fade * 0.18))
	draw_circle(Vector2.ZERO, (11.0 + 10.0 * flare) * strength, Color(1.0, 0.3, 0.025, fade * 0.32))
	draw_circle(Vector2.ZERO, (4.0 + 5.0 * flare) * strength, Color(1.0, 0.9, 0.55, fade * 0.92))
	for i in range(layer_budget):
		var ring_progress := clampf(age / (0.24 + float(i) * 0.09), 0.0, 1.0)
		var radius := (8.0 + ring_progress * (70.0 + float(i) * 22.0)) * strength
		var alpha := (1.0 - ring_progress) * (0.65 / float(i + 1))
		draw_arc(Vector2.ZERO, radius, float(i) * 0.9 + age * 2.0, float(i) * 0.9 + age * 2.0 + PI * 1.72, 40, Color(1.0, 0.2 + float(i) * 0.12, 0.025, alpha), maxf(1.0, 4.2 - float(i)), true)
	for i in range(_flame_angles.size()):
		var angle: float = _flame_angles[i]
		var wobble := sin(age * 25.0 + float(i) * 1.7) * 0.17
		var direction := Vector2(cos(angle + wobble), sin(angle + wobble) - 0.82).normalized()
		var length: float = _flame_lengths[i] * strength * fade
		var base := direction * (5.0 * strength)
		var tip := direction * length + Vector2(0.0, -length * 0.3)
		var width := maxf(1.0, (5.6 - progress * 4.0) * strength)
		draw_line(base, tip, Color(tint.r, tint.g * 0.35, tint.b * 0.15, fade * 0.25), width * 3.0, true)
		draw_line(base, tip, Color(1.0, 0.24 + 0.18 * sin(age * 32.0 + float(i)), 0.025, fade * 0.76), width * 1.35, true)
		draw_line(base, base.lerp(tip, 0.64), Color(1.0, 0.9, 0.55, fade * 0.92), maxf(1.0, width * 0.36), true)
	for i in range(_ember_velocities.size()):
		var velocity: Vector2 = _ember_velocities[i]
		var position := velocity * age + Vector2(0.0, 95.0 * age * age)
		var radius: float = _ember_sizes[i] * strength * fade
		var tail := position - velocity.normalized() * (8.0 + velocity.length() * 0.025)
		draw_line(tail, position, Color(1.0, 0.2, 0.025, fade * 0.48), maxf(1.0, radius * 1.8), true)
		draw_circle(position, radius * 1.9, Color(1.0, 0.24, 0.015, fade * 0.18))
		draw_circle(position, radius, Color(1.0, 0.88, 0.48, fade * 0.92))
