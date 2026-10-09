extends Node2D
class_name OverdriveWaterBurst

## Dynamic liquid impact: a broad water sheet, curling jets, surface ripples and ballistic droplets.
## This renderer is presentation-only; combat damage and physics are owned by the world adapter.
var age: float = 0.0
var lifetime: float = 1.05
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.06, 0.42, 0.86, 1.0)
var _droplet_velocities: Array[Vector2] = []
var _droplet_sizes: PackedFloat32Array = PackedFloat32Array()
var _jet_angles: PackedFloat32Array = PackedFloat32Array()
var _jet_heights: PackedFloat32Array = PackedFloat32Array()
var _jet_sides: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(0.06, 0.42, 0.86, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 1.65)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_droplet_velocities.clear()
	_droplet_sizes.clear()
	_jet_angles.clear()
	_jet_heights.clear()
	_jet_sides.clear()
	for i in range(12 + layer_budget * 5):
		var angle := _rng.randf_range(-PI * 0.88, -PI * 0.12)
		var speed := _rng.randf_range(70.0, 260.0)
		_droplet_velocities.append(Vector2.from_angle(angle) * speed + Vector2(_rng.randf_range(-45.0, 45.0), -_rng.randf_range(15.0, 100.0)))
		_droplet_sizes.append(_rng.randf_range(1.5, 4.6))
	for i in range(5 + layer_budget * 2):
		_jet_angles.append(_rng.randf_range(-PI * 0.94, -PI * 0.06))
		_jet_heights.append(_rng.randf_range(40.0, 105.0))
		_jet_sides.append(_rng.randf_range(0.82, 1.22))
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
	var p := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - smoothstep(0.58, 1.0, p)
	var burst := 1.0 - smoothstep(0.0, 0.18, age)
	var spread := smoothstep(0.02, 0.34, age)
	var collapse := smoothstep(0.58, 1.0, p)

	# Low, widening pool at the base anchors the splash to a surface.
	var pool_rx := (12.0 + 78.0 * spread) * strength
	var pool_ry := (4.0 + 9.0 * spread) * strength
	var pool := PackedVector2Array()
	for i in range(33):
		var a := TAU * float(i) / 32.0
		pool.append(Vector2(cos(a) * pool_rx, 13.0 + sin(a) * pool_ry))
	draw_colored_polygon(pool, Color(0.015, 0.22, 0.56, fade * 0.32))
	var pool_highlight := PackedVector2Array()
	for i in range(17):
		var a := PI * float(i) / 16.0
		pool_highlight.append(Vector2(cos(a) * pool_rx * 0.84, 13.0 - sin(a) * pool_ry * 0.7))
	draw_polyline(pool_highlight, Color(0.42, 0.82, 0.98, fade * 0.7), 1.7 * strength, true)

	# A continuous, uneven liquid sheet grows outward then collapses.
	var half_width := (18.0 + 57.0 * spread) * strength
	var sheet_height := (25.0 + 49.0 * burst) * strength * (1.0 - collapse * 0.42)
	var sheet := PackedVector2Array()
	var samples := 22
	for i in range(samples + 1):
		var u := float(i) / float(samples)
		var x := lerpf(-half_width, half_width, u)
		var arch := pow(maxf(0.0, sin(PI * u)), 0.62)
		var turbulence := (sin(u * 24.0 - age * 22.0) * 3.0 + sin(u * 41.0 + age * 17.0) * 1.2) * strength
		sheet.append(Vector2(x, 9.0 - arch * sheet_height + turbulence))
	for i in range(samples, -1, -1):
		var u := float(i) / float(samples)
		sheet.append(Vector2(lerpf(-half_width, half_width, u), 13.0 + sin(u * TAU * 3.0 + age * 8.0) * 1.6 * strength))
	draw_colored_polygon(sheet, Color(0.02, 0.36, 0.72, fade * 0.78))
	var sheet_glint := PackedVector2Array()
	for i in range(2, samples - 2):
		var point: Vector2 = sheet[i]
		if i % 4 != 0:
			sheet_glint.append(point + Vector2(0.0, 2.0 * strength))
	if sheet_glint.size() > 1:
		draw_polyline(sheet_glint, Color(0.56, 0.9, 1.0, fade * 0.86), 1.6 * strength, true)

	# Curled water fingers peel off the sheet, each with a broad body and a narrow highlight.
	for i in range(_jet_angles.size()):
		var angle: float = _jet_angles[i]
		var height: float = _jet_heights[i] * strength * (1.0 - collapse * 0.48)
		var side := Vector2(cos(angle), sin(angle))
		var base := Vector2(side.x * half_width * 0.62, 7.0)
		var control := base + Vector2(side.x * height * 0.3, -height * 0.95)
		var tip := base + Vector2(side.x * height * 0.62, -height * 0.22)
		tip.x *= _jet_sides[i]
		var curve := PackedVector2Array()
		for step in range(15):
			var t := float(step) / 14.0
			var q := 1.0 - t
			var point := base * q * q + control * 2.0 * q * t + tip * t * t
			point.x += sin(t * PI * 2.0 + age * 12.0 + float(i)) * 2.2 * strength
			curve.append(point)
		var jet_alpha := fade * (1.0 - float(i % 3) * 0.13)
		draw_polyline(curve, Color(0.015, 0.2, 0.52, jet_alpha * 0.9), 6.0 * strength, true)
		draw_polyline(curve, Color(0.03, 0.52, 0.84, jet_alpha), 3.0 * strength, true)
		draw_polyline(curve, Color(0.68, 0.94, 1.0, jet_alpha * 0.9), 1.0 * strength, true)

	# Unevenly timed ripples spread across the surface instead of concentric sci-fi rings.
	for i in range(layer_budget + 1):
		var ring_t := clampf(age / (0.38 + float(i) * 0.13), 0.0, 1.0)
		var rx := (20.0 + ring_t * (70.0 + float(i) * 18.0)) * strength
		var ry := (5.0 + ring_t * 13.0) * strength
		var ripple := PackedVector2Array()
		for j in range(29):
			var a := PI * float(j) / 28.0
			var wobble := 1.0 + 0.035 * sin(a * 7.0 + age * 9.0 + float(i))
			ripple.append(Vector2(cos(a) * rx * wobble, 14.0 + sin(a) * ry * wobble))
		var alpha := (1.0 - ring_t) * fade * (0.72 / float(i + 1))
		draw_polyline(ripple, Color(0.18, 0.58, 0.84, alpha), maxf(1.0, 2.2 - float(i) * 0.3), true)
		if i == 0:
			draw_polyline(ripple.slice(3, 13), Color(0.72, 0.94, 1.0, alpha * 0.9), 1.1 * strength, true)

	# Droplets follow ballistic arcs; elongated tails are aligned with their actual motion.
	for i in range(_droplet_velocities.size()):
		var velocity: Vector2 = _droplet_velocities[i]
		var position := velocity * age + Vector2(0.0, 260.0 * age * age)
		var current_velocity := velocity + Vector2(0.0, 520.0 * age)
		var radius: float = _droplet_sizes[i] * strength * fade
		var tail := position - current_velocity.normalized() * (4.0 + current_velocity.length() * 0.018)
		draw_line(tail, position, Color(0.02, 0.24, 0.6, fade * 0.55), maxf(1.0, radius * 0.95), true)
		draw_circle(position, radius, Color(0.12, 0.53, 0.82, fade * 0.94))
		draw_circle(position - Vector2(radius * 0.22, radius * 0.3), radius * 0.34, Color(0.88, 0.98, 1.0, fade * 0.9))

	# Small pressure glint fades first, leaving the fluid silhouette readable.
	draw_circle(Vector2(-2.0, 2.0), (4.0 + 7.0 * burst) * strength, Color(0.56, 0.88, 1.0, fade * burst * 0.72))
