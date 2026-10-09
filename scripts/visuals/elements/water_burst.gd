extends Node2D
class_name OverdriveWaterBurst

var age: float = 0.0
var lifetime: float = 0.62
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.12, 0.48, 1.0, 1.0)
var _droplet_velocities: Array[Vector2] = []
var _droplet_sizes: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(0.12, 0.48, 1.0, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.0)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_droplet_velocities.clear()
	_droplet_sizes.clear()
	for i in range(8 + layer_budget * 4):
		_droplet_velocities.append(Vector2(_rng.randf_range(-105.0, 105.0), _rng.randf_range(-150.0, -35.0)))
		_droplet_sizes.append(_rng.randf_range(1.5, 3.8))
	age = 0.0
	queue_redraw()

func _ready() -> void:
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
	for i in range(layer_budget):
		var radius := (8.0 + progress * (42.0 + float(i) * 14.0)) * strength
		var alpha := fade * (0.68 / float(i + 1))
		draw_arc(Vector2.ZERO, radius, progress * 2.0 + float(i), progress * 2.0 + float(i) + PI * 1.45, 32, Color(tint.r, tint.g, tint.b, alpha), maxf(1.0, 2.8 - float(i)), true)
	for i in range(_droplet_velocities.size()):
		var velocity := _droplet_velocities[i]
		var position := velocity * age + Vector2(0.0, 170.0 * age * age)
		var radius: float = _droplet_sizes[i] * strength * fade
		draw_circle(position, radius, Color(tint.r, tint.g, tint.b, fade * 0.72))
		draw_circle(position - Vector2(radius * 0.25, radius * 0.3), radius * 0.38, Color(0.82, 0.96, 1.0, fade * 0.82))
