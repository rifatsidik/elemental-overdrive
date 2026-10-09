extends Node2D
class_name EnergyBurst

## Directional procedural lightning. The leader travels from its supplied source
## to the impact point; no hard-coded sky origin is required.
const PARTICLE_SCRIPT = preload("res://scripts/visuals/energy_particles.gd")

var strength: float = 1.0
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 0.62
var branch_budget: int = 4
var layer_budget: int = 2
var burst_color: Color = Color(0.18, 0.92, 1.0, 1.0)
var start_point: Vector2 = Vector2(0.0, -255.0)

var _paths: Array[PackedVector2Array] = []
var _branch_starts: Array[float] = []
var _path_scales: Array[float] = []
var _spark_directions: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()

const STRIKE_TIME: float = 0.082
const MAIN_SEGMENTS: int = 18
const MAX_BRANCHES: int = 8

func configure(new_strength: float, new_seed: int, branches: int, layers: int, source_offset: Vector2 = Vector2(0.0, -255.0)) -> void:
	strength = clampf(new_strength, 0.1, 2.0)
	seed_value = new_seed
	branch_budget = clampi(branches, 1, MAX_BRANCHES)
	layer_budget = clampi(layers, 1, 4)
	start_point = source_offset
	_rng.seed = seed_value
	age = 0.0
	_build_paths()

	var sparks = PARTICLE_SCRIPT.new()
	sparks.name = "EnergyParticles"
	add_child(sparks)
	sparks.configure(seed_value ^ 0x5F3759DF, 12 + layer_budget * 12, strength)
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

	var travel := -start_point
	if travel.length() < 24.0:
		travel = Vector2(0.0, -110.0)
	var forward := travel.normalized()
	var sideways := Vector2(-forward.y, forward.x)
	var distance := travel.length()
	var main := PackedVector2Array()
	var lateral := _rng.randf_range(-3.0, 3.0) * strength
	main.append(start_point + sideways * lateral)
	for i in range(1, MAIN_SEGMENTS):
		var t := float(i) / float(MAIN_SEGMENTS)
		var envelope := pow(maxf(0.0, sin(t * PI)), 0.72)
		lateral += (-lateral * 0.16 + _rng.randf_range(-distance * 0.075, distance * 0.075) * envelope) * strength
		lateral = clampf(lateral, -minf(58.0, distance * 0.22) * strength, minf(58.0, distance * 0.22) * strength)
		main.append(start_point.lerp(Vector2.ZERO, t) + sideways * lateral)
	main.append(Vector2.ZERO)
	_paths.append(main)
	_branch_starts.append(0.0)
	_path_scales.append(1.0)

	for i in range(branch_budget):
		var source_index := _rng.randi_range(3, main.size() - 4)
		var source := main[source_index]
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var segments := _rng.randi_range(3, 6)
		var branch := PackedVector2Array([source])
		var point := source
		var total_length := _rng.randf_range(26.0, 72.0) * strength
		for segment in range(segments):
			var t := float(segment + 1) / float(segments)
			point += sideways * (side * total_length / float(segments) + _rng.randf_range(-9.0, 9.0) * strength)
			point += forward * (_rng.randf_range(4.0, 15.0) * strength)
			branch.append(point)
		_paths.append(branch)
		_branch_starts.append(float(source_index) / float(main.size() - 1))
		_path_scales.append(_rng.randf_range(0.34, 0.56))

	if layer_budget >= 2:
		var twig_count := mini(4, int(ceil(float(branch_budget) * 0.5)))
		for i in range(twig_count):
			var source_index := _rng.randi_range(5, main.size() - 5)
			var source := main[source_index]
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			var twig := PackedVector2Array([source])
			twig.append(source + sideways * side * _rng.randf_range(12.0, 34.0) * strength + forward * _rng.randf_range(8.0, 28.0) * strength)
			_paths.append(twig)
			_branch_starts.append(float(source_index) / float(main.size() - 1))
			_path_scales.append(0.22)

	for i in range(10 + layer_budget * 5):
		_spark_directions.append(Vector2.from_angle(_rng.randf_range(0.0, TAU)))

func _draw() -> void:
	var light := _flash_envelope()
	var pulse := 0.76 + 0.24 * absf(sin(age * 91.0 + float(seed_value % 37)))
	var energy := light * pulse
	var impact := 1.0 - clampf(age / 0.28, 0.0, 1.0)
	var afterglow := 1.0 - smoothstep(0.0, lifetime, age)

	draw_circle(Vector2.ZERO, (34.0 + 34.0 * impact) * strength, Color(0.025, 0.18, 1.0, 0.085 * afterglow))
	draw_circle(Vector2.ZERO, (19.0 + 20.0 * impact) * strength, Color(0.0, 0.72, 1.0, 0.17 * afterglow))
	draw_circle(Vector2.ZERO, 4.5 * strength, Color(0.88, 1.0, 1.0, 0.85 * energy))
	for ring_index in range(layer_budget):
		var ring_progress := clampf(age / (0.19 + float(ring_index) * 0.045), 0.0, 1.0)
		var ring_radius := lerpf(4.0, 66.0 + float(ring_index) * 20.0, ring_progress) * strength
		var ring_alpha := (1.0 - ring_progress) * afterglow * (0.46 / float(ring_index + 1))
		var ring_color := Color(0.12, 0.58, 1.0, ring_alpha) if ring_index % 2 == 0 else Color(0.1, 1.0, 0.92, ring_alpha * 0.7)
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 40, ring_color, maxf(1.0, 3.8 - float(ring_index)), true)

	if age < 0.2:
		var spark_progress := clampf(age / 0.2, 0.0, 1.0)
		for i in range(mini(_spark_directions.size(), 7 + layer_budget * 3)):
			var direction := _spark_directions[i]
			var start := direction * (5.0 * strength)
			var finish := direction * (10.0 + 82.0 * spark_progress) * strength
			var spark_alpha := (1.0 - spark_progress) * energy
			draw_line(start, finish, Color(0.12, 0.72, 1.0, spark_alpha * 0.68), 2.4, true)
			draw_line(start, finish, Color(0.82, 1.0, 1.0, spark_alpha * 0.9), 1.1, true)

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
		var broad_width := (18.0 if is_main else 9.5) * path_scale * strength
		draw_polyline(visible_points, Color(0.015, 0.12, 1.0, 0.17 * flicker), broad_width, true)
		draw_polyline(visible_points, Color(0.0, 0.52, 1.0, 0.30 * flicker), broad_width * 0.62, true)
		if layer_budget >= 2:
			draw_polyline(visible_points, Color(0.0, 0.94, 1.0, 0.56 * flicker), broad_width * 0.30, true)
		if layer_budget >= 3:
			draw_polyline(visible_points, Color(0.68, 1.0, 1.0, 0.82 * flicker), broad_width * 0.15, true)
		draw_polyline(visible_points, Color(0.96, 1.0, 1.0, flicker), maxf(1.0, (1.8 if is_main else 1.0) * path_scale * strength), true)

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
	if age < STRIKE_TIME:
		return lerpf(0.28, 1.0, clampf(age / STRIKE_TIME, 0.0, 1.0))
	if age < 0.125:
		return 0.96
	if age < 0.165:
		return 0.18
	if age < 0.235:
		return 0.86
	return 0.82 * (1.0 - smoothstep(0.235, lifetime, age))
