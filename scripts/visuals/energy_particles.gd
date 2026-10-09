extends Node2D
class_name EnergyParticles

## Small bounded CPU particle burst for bright sparks and molten fragments.
## Kept independent from gameplay physics; all motion is decorative.

var seed_value: int = 1
var particle_count: int = 24
var strength: float = 1.0
var age: float = 0.0
var lifetime: float = 0.48
var _particles: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func configure(new_seed: int, new_count: int, new_strength: float) -> void:
    seed_value = new_seed
    particle_count = clampi(new_count, 4, 96)
    strength = clampf(new_strength, 0.1, 2.0)
    _rng.seed = seed_value
    _particles.clear()
    for i in range(particle_count):
        var angle := _rng.randf_range(0.0, TAU)
        var speed := _rng.randf_range(95.0, 460.0) * strength
        var velocity := Vector2.from_angle(angle) * speed
        velocity.y += _rng.randf_range(-130.0, 65.0) * strength
        _particles.append({
            "position": Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-4.0, 4.0)),
            "velocity": velocity,
            "size": _rng.randf_range(1.0, 3.4) * strength,
            "life": _rng.randf_range(0.22, lifetime),
            "max_life": lifetime,
            "hue": _rng.randf_range(0.0, 1.0),
            "spin": _rng.randf_range(-8.0, 8.0)
        })
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    var alive := false
    for particle in _particles:
        var life_left: float = particle["life"]
        if life_left <= 0.0:
            continue
        alive = true
        particle["life"] = life_left - delta
        var velocity: Vector2 = particle["velocity"]
        velocity.y += 620.0 * strength * delta
        particle["velocity"] = velocity
        particle["position"] = (particle["position"] as Vector2) + velocity * delta
        particle["velocity"] = velocity * (1.0 - minf(0.85, delta * 1.25))
    if not alive or age >= lifetime:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    for particle in _particles:
        var life_left: float = particle["life"]
        if life_left <= 0.0:
            continue
        var alpha := clampf(life_left / maxf(0.001, float(particle["max_life"])), 0.0, 1.0)
        var pos: Vector2 = particle["position"]
        var velocity: Vector2 = particle["velocity"]
        var size: float = particle["size"]
        var hue: float = particle["hue"]
        var color := Color(0.10, 0.70 + hue * 0.25, 1.0, alpha)
        if hue > 0.72:
            color = Color(0.35, 1.0, 0.82, alpha)
        var tail := pos - velocity.normalized() * minf(18.0 * strength, velocity.length() * 0.035)
        draw_line(tail, pos, Color(color.r, color.g, color.b, alpha * 0.48), maxf(1.0, size * 1.25), true)
        draw_circle(pos, size * 2.2, Color(color.r, color.g, color.b, alpha * 0.12))
        draw_circle(pos, size, Color(0.88, 1.0, 1.0, alpha))
