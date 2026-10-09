extends Node2D
class_name OverdriveWaterBurst

var age: float = 0.0
var lifetime: float = 0.76
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.12, 0.48, 1.0, 1.0)
var _droplet_velocities: Array[Vector2] = []
var _droplet_sizes: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(0.12, 0.48, 1.0, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.25)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_droplet_velocities.clear()
	_droplet_sizes.clear()
	for i in range(12 + layer_budget * 6):
		_droplet_velocities.append(Vector2(_rng.randf_range(-175.0, 175.0), _rng.randf_range(-225.0, -42.0)))
		_droplet_sizes.append(_rng.randf_range(2.0, 5.2))
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
	var splash := 1.0 - smoothstep(0.0, 0.2, age)
	# Bright liquid core and multiple expanding, broken splash rims.
	draw_circle(Vector2.ZERO, (16.0 + 16.0 * splash) * strength, Color(0.04, 0.38, 1.0, fade * 0.18))
	draw_circle(Vector2.ZERO, (7.0 + 6.0 * splash) * strength, Color(0.35, 0.86, 1.0, fade * 0.42))
	for i in range(layer_budget + 1):
		var ring_progress := clampf(age / (0.22 + float(i) * 0.085), 0.0, 1.0)
		var radius := (10.0 + ring_progress * (66.0 + float(i) * 18.0)) * strength
		var start_angle := progress * (2.0 + float(i) * 0.55) + float(i) * 1.8
		var sweep := PI * (1.2 + 0.18 * sin(age * 15.0 + float(i)))
		var alpha := (1.0 - ring_progress) * (0.78 / float(i + 1))
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + sweep, 40, Color(tint.r, tint.g, tint.b, alpha), maxf(1.0, 4.0 - float(i) * 0.65), true)
		draw_arc(Vector2.ZERO, radius * 0.82, start_angle + PI * 0.6, start_angle + PI * 1.18, 22, Color(0.72, 0.95, 1.0, alpha * 0.8), 1.4, true)
	for i in range(_droplet_velocities.size()):
		var velocity: Vector2 = _droplet_velocities[i]
		var position := velocity * age + Vector2(0.0, 260.0 * age * age)
		var radius: float = _droplet_sizes[i] * strength * fade
		var tail := position - velocity.normalized() * (7.0 + velocity.length() * 0.035)
		draw_line(tail, position, Color(tint.r, tint.g, tint.b, fade * 0.45), maxf(1.0, radius * 1.25), true)
		draw_circle(position, radius * 1.8, Color(0.05, 0.38, 1.0, fade * 0.18))
		draw_circle(position, radius, Color(tint.r, tint.g, tint.b, fade * 0.9))
		draw_circle(position - Vector2(radius * 0.25, radius * 0.3), radius * 0.42, Color(0.88, 0.98, 1.0, fade * 0.95))
