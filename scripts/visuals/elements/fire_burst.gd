extends Node2D
class_name OverdriveFireBurst

var age: float = 0.0
var lifetime: float = 0.58
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(1.0, 0.34, 0.08, 1.0)
var _flame_angles: PackedFloat32Array = PackedFloat32Array()
var _flame_lengths: PackedFloat32Array = PackedFloat32Array()
var _rng := RandomNumberGenerator.new()

func configure(new_strength: float, seed_value: int, layers: int, color: Color = Color(1.0, 0.34, 0.08, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.0)
	layer_budget = clampi(layers, 1, 3)
	tint = color
	_rng.seed = seed_value
	_flame_angles.clear()
	_flame_lengths.clear()
	for i in range(6 + layer_budget * 3):
		_flame_angles.append(_rng.randf_range(-PI, PI))
		_flame_lengths.append(_rng.randf_range(20.0, 48.0))
	age = 0.0
	queue_redraw()

func _ready() -> void:
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
	draw_circle(Vector2.ZERO, (8.0 + 14.0 * fade) * strength, Color(1.0, 0.16, 0.025, fade * 0.24))
	draw_circle(Vector2.ZERO, 5.0 * strength, Color(1.0, 0.72, 0.18, fade * 0.72))
	for i in range(_flame_angles.size()):
		var angle: float = _flame_angles[i]
		var direction := Vector2(cos(angle), sin(angle) - 0.72).normalized()
		var length: float = _flame_lengths[i] * strength * fade
		var base := direction * (3.0 * strength)
		var tip := direction * length + Vector2(0.0, -length * 0.22)
		var width := maxf(1.0, (4.0 - progress * 3.0) * strength)
		draw_line(base, tip, Color(tint.r, tint.g * 0.58, tint.b * 0.35, fade * 0.48), width * 2.0, true)
		draw_line(base, tip, Color(1.0, 0.82, 0.34, fade * 0.82), width, true)
		if layer_budget >= 2:
			draw_line(base, base.lerp(tip, 0.58), Color(1.0, 0.98, 0.78, fade * 0.68), maxf(1.0, width * 0.35), true)
