extends Node2D
class_name EnergyBurst

## Fast, layered procedural lightning strike with a bright core and expanding impact rings.

var strength: float = 1.0
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 0.82
var branch_budget: int = 4
var layer_budget: int = 2
var burst_color: Color = Color(0.18, 0.92, 1.0, 1.0)
var _paths: Array[PackedVector2Array] = []
var _rng := RandomNumberGenerator.new()

const STRIKE_TIME: float = 0.105
const HOLD_TIME: float = 0.19

func configure(new_strength: float, new_seed: int, branches: int, layers: int) -> void:
    strength = clampf(new_strength, 0.1, 2.0)
    seed_value = new_seed
    branch_budget = clampi(branches, 1, 8)
    layer_budget = clampi(layers, 1, 3)
    _rng.seed = seed_value
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
    var main_points := PackedVector2Array()
    var segment_count: int = 12
    main_points.append(Vector2(_rng.randf_range(-24.0, 24.0), -340.0 * strength))
    for i in range(1, segment_count):
        var ratio: float = float(i) / float(segment_count)
        var next_y: float = lerpf(-340.0, -8.0, ratio) * strength
        var x_spread: float = lerpf(12.0, 48.0, ratio) * strength
        main_points.append(Vector2(_rng.randf_range(-x_spread, x_spread), next_y))
    main_points.append(Vector2(_rng.randf_range(-9.0, 9.0) * strength, 0.0))
    _paths.append(main_points)

    for branch_index in range(branch_budget):
        var start_index: int = _rng.randi_range(2, segment_count - 2)
        var start_point: Vector2 = main_points[start_index]
        var direction: float = -1.0 if branch_index % 2 == 0 else 1.0
        var branch_points := PackedVector2Array()
        branch_points.append(start_point)
        var branch_length: float = _rng.randf_range(38.0, 110.0) * strength
        var end_point: Vector2 = start_point + Vector2(direction * branch_length, _rng.randf_range(-24.0, 48.0) * strength)
        branch_points.append(start_point.lerp(end_point, 0.48) + Vector2(0.0, _rng.randf_range(-16.0, 16.0)))
        branch_points.append(end_point)
        _paths.append(branch_points)

    if layer_budget >= 2:
        var fork_count: int = mini(3, branch_budget)
        for fork_index in range(fork_count):
            var source_index: int = _rng.randi_range(2, main_points.size() - 3)
            var source: Vector2 = main_points[source_index]
            var fork := PackedVector2Array()
            fork.append(source)
            fork.append(source + Vector2(_rng.randf_range(-28.0, 28.0) * strength, _rng.randf_range(18.0, 46.0) * strength))
            _paths.append(fork)

func _draw() -> void:
    var progress: float = clampf(age / lifetime, 0.0, 1.0)
    var strike_progress: float = clampf(age / STRIKE_TIME, 0.0, 1.0)
    var decay_progress: float = clampf((age - HOLD_TIME) / maxf(0.001, lifetime - HOLD_TIME), 0.0, 1.0)
    var fade: float = 1.0 - smoothstep(0.0, 1.0, decay_progress)
    var impact_pulse: float = 1.0 - clampf(age / 0.24, 0.0, 1.0)
    var radius: float = lerpf(10.0, 155.0, smoothstep(0.0, 1.0, progress)) * strength

    # Procedural impact glow remains visible without HDR post-processing.
    draw_circle(Vector2.ZERO, (28.0 + 48.0 * impact_pulse) * strength, Color(0.05, 0.7, 1.0, 0.08 * fade))
    draw_circle(Vector2.ZERO, (15.0 + 22.0 * impact_pulse) * strength, Color(0.28, 0.88, 1.0, 0.16 * fade))
    draw_circle(Vector2.ZERO, 5.5 * strength, Color(0.88, 1.0, 1.0, fade))

    for ring_index in range(layer_budget):
        var ring_radius: float = radius * (1.0 + float(ring_index) * 0.34)
        var ring_alpha: float = fade * (0.36 / float(ring_index + 1))
        draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 72, Color(0.16, 0.78, 1.0, ring_alpha), maxf(1.0, 5.0 - float(ring_index) * 1.3), true)

    for path_index in range(_paths.size()):
        var points: PackedVector2Array = _paths[path_index]
        var is_branch: bool = path_index > 0
        var reveal: float = strike_progress
        if is_branch:
            reveal = clampf((age - 0.025) / maxf(0.001, STRIKE_TIME - 0.025), 0.0, 1.0)
        for segment_index in range(points.size() - 1):
            var segment_start: float = float(segment_index) / float(points.size() - 1)
            if segment_start > reveal:
                continue
            var segment_end: float = minf(float(segment_index + 1) / float(points.size() - 1), reveal)
            var segment_fraction: float = clampf((segment_end - segment_start) * float(points.size() - 1), 0.0, 1.0)
            var a: Vector2 = points[segment_index]
            var b: Vector2 = a.lerp(points[segment_index + 1], segment_fraction)
            var wobble: float = sin(age * 95.0 + float(segment_index * 7 + path_index * 11)) * 4.5 * fade
            var animated_a: Vector2 = a + Vector2(wobble, 0.0)
            var animated_b: Vector2 = b + Vector2(-wobble, 0.0)
            var branch_scale: float = 0.58 if is_branch else 1.0

            # Wide atmospheric halo, saturated electric body, then near-white hot core.
            draw_line(animated_a, animated_b, Color(0.08, 0.32, 1.0, 0.12 * fade), 22.0 * branch_scale * strength, true)
            draw_line(animated_a, animated_b, Color(0.15, 0.72, 1.0, 0.26 * fade), 13.0 * branch_scale * strength, true)
            if layer_budget >= 2:
                draw_line(animated_a, animated_b, Color(0.65, 0.96, 1.0, 0.76 * fade), 5.0 * branch_scale * strength, true)
            draw_line(animated_a, animated_b, Color(0.96, 1.0, 1.0, fade * (1.0 if not is_branch else 0.7)), 2.0 * branch_scale * strength, true)

    if age < 0.28:
        var spark_count: int = 12 if layer_budget >= 2 else 6
        for spark_index in range(spark_count):
            var angle: float = TAU * float(spark_index) / float(spark_count) + float(seed_value % 17) * 0.12
            var travel: float = (22.0 + 74.0 * clampf(age / 0.28, 0.0, 1.0)) * strength
            draw_line(Vector2.from_angle(angle) * (9.0 * strength), Vector2.from_angle(angle) * travel, Color(0.45, 0.92, 1.0, fade * 0.8), 2.0, true)
