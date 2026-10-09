extends Node2D
class_name EnergyBurst

## Layered procedural lightning strike with a bright core, animated filaments,
## radial impact rings and a bounded secondary particle burst.

const PARTICLE_SCRIPT = preload("res://scripts/visuals/energy_particles.gd")

var strength: float = 1.0
var seed_value: int = 1
var age: float = 0.0
var lifetime: float = 0.92
var branch_budget: int = 4
var layer_budget: int = 2
var burst_color: Color = Color(0.18, 0.92, 1.0, 1.0)

var _paths: Array[PackedVector2Array] = []
var _branch_starts: Array[float] = []
var _spark_directions: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()

const STRIKE_TIME: float = 0.095
const HOLD_TIME: float = 0.16
const ARC_SEGMENTS: int = 14
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
    _spark_directions.clear()

    var main := PackedVector2Array()
    main.append(Vector2(_rng.randf_range(-10.0, 10.0), -360.0 * strength))
    for i in range(1, ARC_SEGMENTS):
        var t := float(i) / float(ARC_SEGMENTS)
        var envelope := sin(t * PI * 0.82)
        var spread := lerpf(18.0, 58.0, t) * strength
        main.append(Vector2(_rng.randf_range(-spread, spread) * envelope, lerpf(-360.0, -5.0, t) * strength))
    main.append(Vector2(_rng.randf_range(-12.0, 12.0) * strength, 0.0))
    _paths.append(main)
    _branch_starts.append(0.0)

    for i in range(branch_budget):
        var source_index := _rng.randi_range(2, main.size() - 3)
        var source := main[source_index]
        var side := -1.0 if i % 2 == 0 else 1.0
        var branch := PackedVector2Array()
        branch.append(source)
        var end := source + Vector2(side * _rng.randf_range(42.0, 132.0) * strength, _rng.randf_range(-34.0, 58.0) * strength)
        branch.append(source.lerp(end, 0.32) + Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-18.0, 18.0)))
        branch.append(source.lerp(end, 0.70) + Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-10.0, 10.0)))
        branch.append(end)
        _paths.append(branch)
        _branch_starts.append(float(source_index) / float(main.size() - 1))

    if layer_budget >= 2:
        var fork_count := mini(3 + layer_budget, branch_budget + 2)
        for i in range(fork_count):
            var source_index := _rng.randi_range(2, main.size() - 3)
            var source := main[source_index]
            var fork := PackedVector2Array([source])
            var side := -1.0 if _rng.randf() < 0.5 else 1.0
            fork.append(source + Vector2(side * _rng.randf_range(24.0, 70.0) * strength, _rng.randf_range(16.0, 58.0) * strength))
            _paths.append(fork)
            _branch_starts.append(float(source_index) / float(main.size() - 1))

    for i in range(8 + layer_budget * 5):
        _spark_directions.append(Vector2.from_angle(_rng.randf_range(0.0, TAU)))

func _draw() -> void:
    var progress := clampf(age / lifetime, 0.0, 1.0)
    var strike := clampf(age / STRIKE_TIME, 0.0, 1.0)
    var decay := clampf((age - HOLD_TIME) / maxf(0.001, lifetime - HOLD_TIME), 0.0, 1.0)
    var fade := 1.0 - smoothstep(0.0, 1.0, decay)
    var impact := 1.0 - clampf(age / 0.30, 0.0, 1.0)
    var pulse := 0.72 + 0.28 * absf(sin(age * 76.0 + float(seed_value % 31)))
    var radius := lerpf(8.0, 178.0, smoothstep(0.0, 1.0, progress)) * strength

    draw_circle(Vector2.ZERO, (46.0 + 54.0 * impact) * strength, Color(0.04, 0.28, 1.0, 0.075 * fade))
    draw_circle(Vector2.ZERO, (27.0 + 34.0 * impact) * strength, Color(0.02, 0.76, 1.0, 0.13 * fade))
    draw_circle(Vector2.ZERO, (13.0 + 11.0 * impact) * strength, Color(0.52, 0.98, 1.0, 0.23 * fade))
    draw_circle(Vector2.ZERO, 5.0 * strength, Color(1.0, 1.0, 1.0, fade * pulse))

    for ring_index in range(layer_budget):
        var ring_radius := radius * (1.0 + float(ring_index) * 0.28)
        var ring_alpha := fade * (0.52 / float(ring_index + 1))
        var ring_color := Color(0.12, 0.58, 1.0, ring_alpha) if ring_index % 2 == 0 else Color(0.1, 1.0, 0.92, ring_alpha * 0.72)
        draw_arc(Vector2.ZERO, ring_radius, age * 0.8, TAU + age * 0.8, 64, ring_color, maxf(1.0, 4.5 - float(ring_index)), true)

    if age < 0.22:
        for i in range(mini(_spark_directions.size(), 8 + layer_budget * 4)):
            var dir := _spark_directions[i]
            var travel := (16.0 + 118.0 * clampf(age / 0.22, 0.0, 1.0)) * strength
            var start := dir * (7.0 * strength)
            var finish := dir * travel
            draw_line(start, finish, Color(0.18, 0.8, 1.0, fade * 0.68), 2.0, true)
            draw_line(start, finish, Color(0.82, 1.0, 1.0, fade * 0.8), 1.0, true)

    for path_index in range(_paths.size()):
        var points := _paths[path_index]
        var is_main := path_index == 0
        var start_at := _branch_starts[path_index]
        var reveal := strike
        if not is_main:
            reveal = clampf((strike - start_at * 0.58) / maxf(0.001, 1.0 - start_at * 0.58), 0.0, 1.0)
        if age > STRIKE_TIME:
            reveal = 1.0
        for segment_index in range(points.size() - 1):
            var segment_start := float(segment_index) / float(points.size() - 1)
            if segment_start > reveal:
                continue
            var segment_end := minf(float(segment_index + 1) / float(points.size() - 1), reveal)
            var fraction := clampf((segment_end - segment_start) * float(points.size() - 1), 0.0, 1.0)
            var a := points[segment_index]
            var b := a.lerp(points[segment_index + 1], fraction)
            var wave := sin(age * (83.0 + float(path_index % 4) * 11.0) + float(segment_index * 9 + path_index * 13))
            var jitter := Vector2(wave * (2.0 + layer_budget) * fade, cos(age * 51.0 + float(path_index)) * 2.2 * fade)
            var aa := a + jitter
            var bb := b - jitter * 0.7
            var branch_scale := 1.0 if is_main else 0.46
            var flicker := 0.72 + 0.28 * absf(sin(age * 97.0 + float(path_index * 17)))
            var hot := fade * flicker

            draw_line(aa, bb, Color(0.015, 0.12, 1.0, 0.12 * hot), 28.0 * branch_scale * strength, true)
            draw_line(aa, bb, Color(0.0, 0.52, 1.0, 0.20 * hot), 18.0 * branch_scale * strength, true)
            draw_line(aa, bb, Color(0.0, 1.0, 0.96, 0.34 * hot), 10.0 * branch_scale * strength, true)
            if layer_budget >= 2:
                draw_line(aa, bb, Color(0.70, 1.0, 1.0, 0.72 * hot), 4.6 * branch_scale * strength, true)
            draw_line(aa, bb, Color(1.0, 1.0, 1.0, hot), 1.8 * branch_scale * strength, true)

            if layer_budget >= 3 and segment_index % 3 == 0 and age < 0.30:
                var mid := aa.lerp(bb, 0.58)
                var tangent := (bb - aa).orthogonal().normalized()
                var tip := mid + tangent * _arc_offset(path_index, segment_index) * strength
                draw_line(mid, tip, Color(0.15, 0.88, 1.0, hot * 0.8), 1.5, true)

func _arc_offset(path_index: int, segment_index: int) -> float:
    return sin(float(seed_value % 997) * 0.071 + float(path_index * 19 + segment_index * 37) * 1.713) * 13.0
