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
	for i in range(7 + layer_budget * 3):
		_flame_angles.append(_rng.randf_range(-1.12, 1.12))
		_flame_lengths.append(_rng.randf_range(42.0, 88.0))
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
	var flare := 1.0 - smoothstep(0.0, 0.2, age)
	draw_circle(Vector2(0.0, 9.0 * strength), (20.0 + 15.0 * flare) * strength, Color(1.0, 0.1, 0.008, fade * 0.2))
	draw_circle(Vector2(0.0, 8.0 * strength), (11.0 + 8.0 * flare) * strength, Color(1.0, 0.34, 0.018, fade * 0.42))
	for i in range(_flame_angles.size()):
		var angle: float = _flame_angles[i] + sin(age * 18.0 + float(i) * 1.8) * 0.16
		var direction := Vector2(sin(angle), -cos(angle)).normalized()
		var length: float = _flame_lengths[i] * strength * (1.0 - progress * 0.28)
		var base := Vector2(sin(float(i) * 1.71 + age * 3.0) * 10.0 * strength, 10.0 * strength)
		var width := (8.0 + 5.0 * sin(float(i) * 2.3 + age * 11.0)) * strength
		var phase := float(i) * 1.37
		draw_colored_polygon(_build_flame_shape(base, direction, length, width, phase), Color(1.0, 0.1, 0.006, fade * 0.86))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.07, direction, length * 0.78, width * 0.62, phase + 0.8), Color(1.0, 0.36, 0.02, fade * 0.94))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.14, direction, length * 0.55, width * 0.28, phase + 1.6), Color(1.0, 0.88, 0.32, fade * 0.95))
	for i in range(_ember_velocities.size()):
		var velocity: Vector2 = _ember_velocities[i]
		var position := velocity * age * 0.55 + Vector2(0.0, -38.0 * age + 115.0 * age * age)
		var radius: float = _ember_sizes[i] * strength * fade
		draw_circle(position, radius * 1.7, Color(1.0, 0.18, 0.008, fade * 0.2))
		draw_circle(position, radius, Color(1.0, 0.86, 0.36, fade * 0.92))

func _build_flame_shape(base: Vector2, direction: Vector2, length: float, half_width: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var normal := Vector2(-direction.y, direction.x)
	var segments := 12
	for i in range(segments + 1):
		var u := float(i) / float(segments)
		var shape_width := half_width * pow(1.0 - u, 0.78) * (0.82 + 0.18 * sin(u * PI * 3.0 + phase))
		var sway := sin(u * 7.0 + phase + age * 18.0) * half_width * 0.2 * u
		points.append(base + direction * length * u + normal * (sway + shape_width))
	for i in range(segments, -1, -1):
		var u := float(i) / float(segments)
		var shape_width := half_width * pow(1.0 - u, 0.78) * (0.82 + 0.18 * sin(u * PI * 3.0 + phase))
		var sway := sin(u * 7.0 + phase + age * 18.0) * half_width * 0.2 * u
		points.append(base + direction * length * u + normal * (sway - shape_width))
	return points
