extends Node2D
class_name EnergyBurst

## Bounded procedural lightning and shockwave test effect.

var strength: float = 1.0
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 0.72
var branch_budget: int = 4
var layer_budget: int = 2
var burst_color: Color = Color(0.18, 0.92, 1.0, 1.0)
var _paths: Array[PackedVector2Array] = []

func configure(new_strength: float, new_seed: int, branches: int, layers: int) -> void:
    strength = clampf(new_strength, 0.1, 2.0)
    seed_value = new_seed
    branch_budget = clampi(branches, 1, 8)
    layer_budget = clampi(layers, 1, 3)
    _build_paths()
    queue_redraw()

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
        return
    queue_redraw()

func _build_paths() -> void:
    _paths.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var main_points := PackedVector2Array()
    main_points.append(Vector2.ZERO)
    var segment_count: int = 9
    for i in range(1, segment_count):
        var ratio: float = float(i) / float(segment_count)
        var side_offset: float = rng.randf_range(-34.0, 34.0) * strength
        main_points.append(Vector2(lerpf(-150.0, 150.0, ratio) * strength, side_offset))
    main_points.append(Vector2(175.0 * strength, -12.0 * strength))
    _paths.append(main_points)

    for branch_index in range(branch_budget):
        var start_index: int = rng.randi_range(2, segment_count - 2)
        var start_point: Vector2 = main_points[start_index]
        var direction: float = -1.0 if branch_index % 2 == 0 else 1.0
        var branch_points := PackedVector2Array()
        branch_points.append(start_point)
        var end_point: Vector2 = start_point + Vector2(rng.randf_range(-42.0, 42.0), direction * rng.randf_range(36.0, 92.0) * strength)
        branch_points.append(start_point.lerp(end_point, 0.45))
        branch_points.append(end_point)
        _paths.append(branch_points)

func _draw() -> void:
    var progress: float = clampf(age / lifetime, 0.0, 1.0)
    var fade: float = 1.0 - progress
    var pulse: float = 0.82 + 0.18 * sin(age * 38.0)
    var radius: float = lerpf(8.0, 118.0, progress) * strength
    for layer_index in range(layer_budget):
        var layer_scale: float = 1.0 + float(layer_index) * 0.55
        var ring_color: Color = Color(0.12, 0.86, 1.0, fade * 0.5 / float(layer_index + 1))
        draw_arc(Vector2.ZERO, radius * layer_scale, 0.0, TAU, 64, ring_color, maxf(1.0, 5.0 - float(layer_index) * 1.5), true)

    for path_index in range(_paths.size()):
        var points: PackedVector2Array = _paths[path_index]
        var is_branch: bool = path_index > 0
        for segment_index in range(points.size() - 1):
            var a: Vector2 = points[segment_index]
            var b: Vector2 = points[segment_index + 1]
            var wobble: float = sin(age * 52.0 + float(segment_index * 7 + path_index * 11)) * 3.0 * fade
            var animated_a: Vector2 = a + Vector2(0.0, wobble)
            var animated_b: Vector2 = b + Vector2(0.0, -wobble)
            for layer_index in range(layer_budget):
                var width: float = (7.0 - float(layer_index) * 2.0) * (0.55 if is_branch else 1.0)
                var alpha: float = fade * (0.14 if layer_index == 0 else 0.38 if layer_index == 1 else 0.95)
                var color: Color = Color(burst_color.r, burst_color.g, burst_color.b, alpha * pulse)
                draw_line(animated_a, animated_b, color, maxf(1.0, width - float(layer_index) * 1.4), true)

    draw_circle(Vector2.ZERO, 7.0 * strength * fade, Color(0.72, 1.0, 1.0, fade * 0.85))
