extends Node2D
class_name OverdriveWaterBurst

## Controlled liquid impact: readable pressure core, smooth crown jets, droplets and ripples.
## Water uses alpha blending so layered cyan/white strokes do not saturate into a noisy neon blob.
var age: float = 0.0
var lifetime: float = 0.92
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.08, 0.48, 1.0, 1.0)
var _droplet_velocities: Array[Vector2] = []
var _droplet_sizes: PackedFloat32Array = PackedFloat32Array()
var _jet_angles: PackedFloat32Array = PackedFloat32Array()
var _jet_heights: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(0.08, 0.48, 1.0, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 1.8)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_droplet_velocities.clear()
	_droplet_sizes.clear()
	_jet_angles.clear()
	_jet_heights.clear()
	for i in range(14 + layer_budget * 5):
		var angle := _rng.randf_range(-PI * 0.94, PI * 0.94)
		var speed := _rng.randf_range(65.0, 245.0)
		_droplet_velocities.append(Vector2.from_angle(angle) * speed + Vector2(0.0, -_rng.randf_range(20.0, 95.0)))
		_droplet_sizes.append(_rng.randf_range(1.6, 4.8))
	for i in range(7 + layer_budget * 2):
		_jet_angles.append(_rng.randf_range(-PI * 0.91, -PI * 0.09))
		_jet_heights.append(_rng.randf_range(38.0, 92.0))
	age = 0.0
	queue_redraw()

func _ready() -> void:
	var liquid_material := CanvasItemMaterial.new()
	liquid_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	material = liquid_material
	set_process(true)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - smoothstep(0.48, 1.0, progress)
	var impact_pulse := 1.0 - smoothstep(0.0, 0.2, age)
	var expansion := smoothstep(0.0, 0.48, age)

	# Compact, layered pressure core: deep blue body, cyan shell, pearl-white glint.
	draw_circle(Vector2.ZERO, (22.0 + 17.0 * impact_pulse) * strength, Color(0.015, 0.16, 0.62, fade * 0.26))
	draw_circle(Vector2.ZERO, (15.0 + 12.0 * impact_pulse) * strength, Color(0.0, 0.48, 0.9, fade * 0.46))
	draw_circle(Vector2(-2.0, -2.0), (6.0 + 5.0 * impact_pulse) * strength, Color(0.7, 0.96, 1.0, fade * 0.9))

	# Broad, staggered ripples with restrained line widths and non-uniform gaps.
	for i in range(layer_budget + 1):
		var ring_t := clampf(age / (0.32 + float(i) * 0.11), 0.0, 1.0)
		var radius := (18.0 + ring_t * (78.0 + float(i) * 18.0)) * strength
		var alpha := (1.0 - ring_t) * fade * (0.58 / float(i + 1))
		var start := age * (1.2 + float(i) * 0.23) + float(i) * 1.7
		var sweep := PI * (1.1 + 0.12 * sin(age * 8.0 + float(i)))
		draw_arc(Vector2.ZERO, radius, start, start + sweep, 40, Color(0.02, 0.48, 0.88, alpha), maxf(1.0, 3.6 - float(i) * 0.55), true)
		draw_arc(Vector2.ZERO, radius * 0.9, start + 2.0, start + 2.0 + sweep * 0.62, 28, Color(0.65, 0.94, 1.0, alpha * 0.82), maxf(1.0, 1.45 - float(i) * 0.12), true)

	# Crown splash: quadratic curves are sampled into smooth liquid arcs (no sharp three-point kinks).
	for i in range(_jet_angles.size()):
		var angle: float = _jet_angles[i]
		var height: float = _jet_heights[i] * strength * (1.0 - progress * 0.52)
		var side := Vector2(cos(angle), sin(angle))
		var base := side * (7.0 + 11.0 * expansion) * strength
		var control := side * (22.0 + height * 0.24) + Vector2(0.0, -height * 0.78)
		var tip := side * (26.0 + height * 0.5) + Vector2(0.0, -height * 0.22)
		var curve := PackedVector2Array()
		for step in range(13):
			var t := float(step) / 12.0
			var one_minus_t := 1.0 - t
			curve.append(base * one_minus_t * one_minus_t + control * 2.0 * one_minus_t * t + tip * t * t)
		var jet_fade := fade * (1.0 - float(i % 3) * 0.12)
		draw_polyline(curve, Color(0.02, 0.24, 0.72, jet_fade * 0.34), 7.0 * strength, true)
		draw_polyline(curve, Color(0.02, 0.62, 0.96, jet_fade * 0.82), 3.0 * strength, true)
		draw_polyline(curve, Color(0.72, 0.96, 1.0, jet_fade * 0.9), 1.0 * strength, true)

	# Droplets separate from the splash silhouette and fall under a simple ballistic arc.
	for i in range(_droplet_velocities.size()):
		var velocity: Vector2 = _droplet_velocities[i]
		var position := velocity * age + Vector2(0.0, 250.0 * age * age)
		var radius: float = _droplet_sizes[i] * strength * fade
		var tail := position - velocity.normalized() * (5.0 + velocity.length() * 0.025)
		draw_line(tail, position, Color(0.02, 0.34, 0.82, fade * 0.48), maxf(1.0, radius * 1.25), true)
		draw_circle(position, radius, Color(0.12, 0.62, 0.96, fade * 0.88))
		draw_circle(position - Vector2(radius * 0.22, radius * 0.28), radius * 0.34, Color(0.9, 0.99, 1.0, fade * 0.9))

	# Final liquid crescent anchors the impact and makes the water read as a heavy splash.
	var crescent_radius := (12.0 + expansion * 34.0) * strength
	draw_arc(Vector2.ZERO, crescent_radius, PI * 0.12 + age * 1.5, PI * 0.88 + age * 1.5, 36, Color(0.74, 0.96, 1.0, fade * 0.78), 2.0 * strength, true)
