extends Node2D
class_name EnergyBurst

## Procedural lightning strike: jagged leader, asymmetric downward forks,
## staged reveal, rapid re-strikes, and a short luminous afterglow.
## Geometry is generated once per strike; per-frame work is bounded to drawing.

const PARTICLE_SCRIPT = preload("res://scripts/visuals/energy_particles.gd")

var strength: float = 1.0
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 0.62
var branch_budget: int = 4
var layer_budget: int = 2
var burst_color: Color = Color(0.18, 0.92, 1.0, 1.0)

var _paths: Array[PackedVector2Array] = []
var _branch_starts: Array[float] = []
var _path_scales: Array[float] = []
var _spark_directions: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()

const STRIKE_TIME: float = 0.082
const BOLT_HEIGHT: float = 360.0
const MAIN_SEGMENTS: int = 18
const MAX_BRANCHES: int = 8

func configure(new_strength: float, new_seed: int, branches: int, layers: int) -> void:
	strength = clampf(new_strength, 0.1, 2.0)
	seed_value = new_seed
	branch_budget = clampi(branches, 1, MAX_BRANCHES)
	layer_budget = clampi(layers, 1, 4)
	_rng.seed = seed_value
	age = 0.0
	_build_paths()

	var sparks = PARTICLE_SCRIPT.new()
	sparks.name = "EnergyParticles"
	add_child(sparks)
	sparks.configure(seed_value ^ 0x5F3759DF, 10 + layer_budget * 10, strength)
	queue_redraw()

func _ready() -> void:
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive_material
	set_process(true)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _build_paths() -> void:
	_paths.clear()
	_branch_starts.clear()
	_path_scales.clear()
	_spark_directions.clear()

	# A constrained random walk produces a coherent leader instead of
	# unrelated zigzags: each step remembers the previous lateral position.
	var main := PackedVector2Array()
	var x := _rng.randf_range(-8.0, 8.0) * strength
	main.append(Vector2(x, -BOLT_HEIGHT * strength))
	for i in range(1, MAIN_SEGMENTS):
		var t := float(i) / float(MAIN_SEGMENTS)
		var envelope := pow(maxf(0.0, sin(t * PI)), 0.72)
		var correction := -x * 0.16
		x += (correction + _rng.randf_range(-31.0, 31.0) * envelope) * strength
		x = clampf(x, -76.0 * strength, 76.0 * strength)
		main.append(Vector2(x, lerpf(-BOLT_HEIGHT * strength, 0.0, t)))
	main.append(Vector2(_rng.randf_range(-10.0, 10.0) * strength, 0.0))
	_paths.append(main)
	_branch_starts.append(0.0)
	_path_scales.append(1.0)

	# Realistic forks are irregular and mostly travel downward/outward;
	# alternating fixed left/right branches would look too decorative.
	for i in range(branch_budget):
		var source_index := _rng.randi_range(3, main.size() - 4)
		var source := main[source_index]
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var segments := _rng.randi_range(3, 6)
		var branch := PackedVector2Array()
		branch.append(source)
		var point := source
		var total_length := _rng.randf_range(44.0, 116.0) * strength
		for segment in range(segments):
			var t := float(segment + 1) / float(segments)
			var step_x := side * total_length / float(segments)
			step_x += _rng.randf_range(-15.0, 15.0) * strength
			var step_y := _rng.randf_range(9.0, 25.0) * strength
			point += Vector2(step_x, step_y)
			# Branches taper back toward the strike's center less as they grow.
			point.x = lerpf(point.x, source.x + side * total_length, 0.12 * t)
			branch.append(point)
		_paths.append(branch)
		_branch_starts.append(float(source_index) / float(main.size() - 1))
		_path_scales.append(_rng.randf_range(0.36, 0.58))

	# Tiny side leaders add fine branching without multiplying geometry heavily.
	if layer_budget >= 2:
		var twig_count := mini(3, int(floor(float(branch_budget) * 0.5)))
		for i in range(twig_count):
			var source_index := _rng.randi_range(5, main.size() - 5)
			var source := main[source_index]
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			var twig := PackedVector2Array([source])
			twig.append(source + Vector2(side * _rng.randf_range(18.0, 44.0) * strength, _rng.randf_range(15.0, 42.0) * strength))
			_paths.append(twig)
			_branch_starts.append(float(source_index) / float(main.size() - 1))
			_path_scales.append(0.24)

	for i in range(8 + layer_budget * 4):
		_spark_directions.append(Vector2.from_angle(_rng.randf_range(0.0, TAU)))

func _draw() -> void:
	var light := _flash_envelope()
	var pulse := 0.76 + 0.24 * absf(sin(age * 91.0 + float(seed_value % 37)))
	var energy := light * pulse
	var impact := 1.0 - clampf(age / 0.28, 0.0, 1.0)
	var afterglow := 1.0 - smoothstep(0.0, lifetime, age)

	# Compact impact bloom and expanding rings: keep the brightest area at
	# the strike endpoint instead of flooding the entire screen with haze.
	draw_circle(Vector2.ZERO, (42.0 + 46.0 * impact) * strength, Color(0.025, 0.18, 1.0, 0.075 * afterglow))
	draw_circle(Vector2.ZERO, (22.0 + 24.0 * impact) * strength, Color(0.0, 0.72, 1.0, 0.13 * afterglow))
	draw_circle(Vector2.ZERO, 5.0 * strength, Color(0.88, 1.0, 1.0, 0.78 * energy))
	for ring_index in range(layer_budget):
		var ring_progress := clampf(age / (0.19 + float(ring_index) * 0.045), 0.0, 1.0)
		var ring_radius := lerpf(4.0, 92.0 + float(ring_index) * 28.0, ring_progress) * strength
		var ring_alpha := (1.0 - ring_progress) * afterglow * (0.42 / float(ring_index + 1))
		var ring_color := Color(0.12, 0.58, 1.0, ring_alpha) if ring_index % 2 == 0 else Color(0.1, 1.0, 0.92, ring_alpha * 0.7)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 40, ring_color, maxf(1.0, 3.5 - float(ring_index)), true)

	# Short streaks leave the impact in a radial burst, then disappear quickly.
	if age < 0.18:
		var spark_progress := clampf(age / 0.18, 0.0, 1.0)
		for i in range(mini(_spark_directions.size(), 6 + layer_budget * 3)):
			var direction := _spark_directions[i]
			var start := direction * (5.0 * strength)
			var finish := direction * (12.0 + 100.0 * spark_progress) * strength
			var spark_alpha := (1.0 - spark_progress) * energy
			draw_line(start, finish, Color(0.12, 0.72, 1.0, spark_alpha * 0.62), 2.0, true)
			draw_line(start, finish, Color(0.82, 1.0, 1.0, spark_alpha * 0.82), 1.0, true)

	for path_index in range(_paths.size()):
		var source_points := _paths[path_index]
		var is_main := path_index == 0
		var reveal := clampf(age / STRIKE_TIME, 0.0, 1.0)
		if not is_main:
			var start_at := _branch_starts[path_index]
			reveal = clampf((reveal - start_at) / maxf(0.001, 1.0 - start_at), 0.0, 1.0)
		if age >= STRIKE_TIME:
			reveal = 1.0
		if reveal <= 0.0:
			continue

		var visible_points := _revealed_points(source_points, reveal)
		if visible_points.size() < 2:
			continue
		var path_scale := _path_scales[path_index]
		var flicker := energy * (0.82 + 0.18 * absf(sin(age * 137.0 + float(path_index * 17))))
		var broad_width := (22.0 if is_main else 13.0) * path_scale * strength
		draw_polyline(visible_points, Color(0.015, 0.12, 1.0, 0.12 * flicker), broad_width, true)
		draw_polyline(visible_points, Color(0.0, 0.52, 1.0, 0.24 * flicker), broad_width * 0.62, true)
		if layer_budget >= 2:
			draw_polyline(visible_points, Color(0.0, 0.94, 1.0, 0.48 * flicker), broad_width * 0.30, true)
		if layer_budget >= 3:
			draw_polyline(visible_points, Color(0.68, 1.0, 1.0, 0.76 * flicker), broad_width * 0.15, true)
		draw_polyline(visible_points, Color(0.92, 1.0, 1.0, flicker), maxf(1.0, (2.0 if is_main else 1.15) * path_scale * strength), true)

func _revealed_points(path: PackedVector2Array, reveal: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	if path.size() < 2:
		return result
	var segment_count := path.size() - 1
	var visible_segments := reveal * float(segment_count)
	var complete_segments := mini(int(floor(visible_segments)), segment_count)
	for i in range(complete_segments + 1):
		result.append(path[i])
	if complete_segments < segment_count and result.size() > 0:
		var fraction := visible_segments - float(complete_segments)
		if fraction > 0.001:
			result.append(path[complete_segments].lerp(path[complete_segments + 1], fraction))
	return result

func _flash_envelope() -> float:
	# A leader flash, a tiny dark gap, then one weaker return stroke.
	if age < STRIKE_TIME:
		return lerpf(0.28, 1.0, clampf(age / STRIKE_TIME, 0.0, 1.0))
	if age < 0.125:
		return 0.96
	if age < 0.165:
		return 0.18
	if age < 0.235:
		return 0.86
	return 0.82 * (1.0 - smoothstep(0.235, lifetime, age))
