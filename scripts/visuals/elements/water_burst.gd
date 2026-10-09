extends Node2D
class_name OverdriveWaterBurst

## Water impact: pressure core, crown splash, rising jets, droplets and broad wave rings.
var age: float = 0.0
var lifetime: float = 0.9
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.12, 0.48, 1.0, 1.0)
var _droplet_velocities: Array[Vector2] = []
var _droplet_sizes: PackedFloat32Array = PackedFloat32Array()
var _jet_angles: PackedFloat32Array = PackedFloat32Array()
var _jet_heights: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(0.12, 0.48, 1.0, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.25)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_droplet_velocities.clear()
	_droplet_sizes.clear()
	_jet_angles.clear()
	_jet_heights.clear()
	for i in range(16 + layer_budget * 8):
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(75.0, 310.0)
		_droplet_velocities.append(Vector2.from_angle(angle) * speed + Vector2(0.0, -_rng.randf_range(25.0, 110.0)))
		_droplet_sizes.append(_rng.randf_range(2.0, 6.2))
	for i in range(9 + layer_budget * 3):
		_jet_angles.append(_rng.randf_range(-PI * 0.92, -PI * 0.08))
		_jet_heights.append(_rng.randf_range(42.0, 115.0))
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
	var punch := 1.0 - smoothstep(0.0, 0.24, age)
	var expanding := smoothstep(0.0, 0.48, age)
	# Stronger blue volume behind the white-blue liquid core.
	draw_circle(Vector2.ZERO, (20.0 + 27.0 * punch) * strength, Color(0.015, 0.22, 1.0, fade * 0.2))
	draw_circle(Vector2.ZERO, (13.0 + 14.0 * punch) * strength, Color(0.0, 0.58, 1.0, fade * 0.34))
	draw_circle(Vector2.ZERO, (5.0 + 7.0 * punch) * strength, Color(0.82, 0.98, 1.0, fade * 0.92))
	# Large, staggered wavefronts instead of tiny concentric rings.
	for i in range(layer_budget + 2):
		var ring_progress := clampf(age / (0.3 + float(i) * 0.095), 0.0, 1.0)
		var radius := (14.0 + ring_progress * (94.0 + float(i) * 23.0)) * strength
		var start_angle := age * (1.8 + float(i) * 0.38) + float(i) * 1.64
		var sweep := PI * (1.12 + 0.24 * sin(age * 12.0 + float(i)))
		var alpha := (1.0 - ring_progress) * (0.82 / float(i + 1))
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + sweep, 52, Color(tint.r, tint.g, tint.b, alpha), maxf(1.2, 5.2 - float(i) * 0.65), true)
		draw_arc(Vector2.ZERO, radius * 0.87, start_angle + PI * 0.72, start_angle + PI * 1.25, 28, Color(0.84, 0.98, 1.0, alpha * 0.92), maxf(1.0, 2.0 - float(i) * 0.2), true)
	# Liquid crown: tall asymmetric jets curl away from the center.
	for i in range(_jet_angles.size()):
		var angle: float = _jet_angles[i]
		var height: float = _jet_heights[i] * strength * (1.0 - progress * 0.65)
		var side := Vector2(cos(angle), sin(angle))
		var base := side * (7.0 + 12.0 * expanding) * strength
		var mid := side * (20.0 + height * 0.45) + Vector2(0.0, -height * 0.68)
		var tip := side * (32.0 + height * 0.65) + Vector2(0.0, -height * 0.12)
		var curve := PackedVector2Array([base, mid, tip])
		draw_polyline(curve, Color(0.0, 0.34, 1.0, fade * 0.3), 8.0 * strength, true)
		draw_polyline(curve, Color(0.05, 0.72, 1.0, fade * 0.8), 3.4 * strength, true)
		draw_polyline(curve, Color(0.88, 0.99, 1.0, fade * 0.95), 1.15 * strength, true)
	# Droplets use gravity and bright specular highlights for a wet, liquid read.
	for i in range(_droplet_velocities.size()):
		var velocity: Vector2 = _droplet_velocities[i]
		var position := velocity * age + Vector2(0.0, 300.0 * age * age)
		var radius: float = _droplet_sizes[i] * strength * fade
		var tail := position - velocity.normalized() * (10.0 + velocity.length() * 0.04)
		draw_line(tail, position, Color(0.02, 0.34, 1.0, fade * 0.42), maxf(1.0, radius * 1.9), true)
		draw_line(tail.lerp(position, 0.45), position, Color(0.22, 0.82, 1.0, fade * 0.76), maxf(1.0, radius * 0.8), true)
		draw_circle(position, radius * 1.65, Color(0.02, 0.42, 1.0, fade * 0.2))
		draw_circle(position, radius, Color(tint.r, tint.g, tint.b, fade * 0.94))
		draw_circle(position - Vector2(radius * 0.26, radius * 0.34), radius * 0.42, Color(0.95, 1.0, 1.0, fade * 0.98))
	# A final sweeping highlight makes the hit feel like a heavy volume of water.
	draw_arc(Vector2.ZERO, (8.0 + expanding * 32.0) * strength, age * 4.2, age * 4.2 + PI * 1.62, 42, Color(0.8, 0.98, 1.0, fade * 0.75), 2.3 * strength, true)
