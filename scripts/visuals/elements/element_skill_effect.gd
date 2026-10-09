extends Node2D
class_name OverdriveElementSkillEffect

## Reusable skill presentation layer. This does not apply gameplay damage or forces.
var skill_id: StringName = &"fire_burst"
var strength: float = 1.0
var age: float = 0.0
var lifetime: float = 0.95
var layer_budget: int = 2
var tint: Color = Color.WHITE
var _seed: int = 1
var _rng := RandomNumberGenerator.new()
var _particles: Array[Dictionary] = []

const SKILL_PRESETS := {
	&"fire_tornado": { "lifetime": 1.35, "strength": 1.55, "layers": 3, "color": Color(1.0, 0.22, 0.025, 1.0) },
	&"fire_burst": { "lifetime": 0.82, "strength": 1.65, "layers": 3, "color": Color(1.0, 0.38, 0.04, 1.0) },
	&"water_jet_burst": { "lifetime": 0.95, "strength": 1.6, "layers": 3, "color": Color(0.1, 0.64, 1.0, 1.0) },
	&"water_torrent": { "lifetime": 1.25, "strength": 1.55, "layers": 3, "color": Color(0.12, 0.52, 1.0, 1.0) },
	&"wind_cyclone": { "lifetime": 1.25, "strength": 1.45, "layers": 3, "color": Color(0.38, 1.0, 0.82, 1.0) },
	&"wind_blade_storm": { "lifetime": 0.9, "strength": 1.55, "layers": 3, "color": Color(0.5, 1.0, 0.84, 1.0) }
}

func configure(new_skill_id: StringName, new_seed: int, scale: float = 1.0, layers: int = 2) -> void:
	skill_id = new_skill_id
	var preset: Dictionary = SKILL_PRESETS.get(skill_id, SKILL_PRESETS[&"fire_burst"])
	strength = clampf(scale * float(preset["strength"]), 0.35, 2.5)
	lifetime = float(preset["lifetime"])
	layer_budget = mini(clampi(layers, 1, 3), int(preset["layers"]))
	tint = preset["color"]
	_seed = new_seed
	_rng.seed = _seed
	_particles.clear()
	for i in range(18 + layer_budget * 10):
		var angle := _rng.randf_range(0.0, TAU)
		var speed := _rng.randf_range(35.0, 180.0) * strength
		_particles.append({
			"angle": angle,
			"speed": speed,
			"radius": _rng.randf_range(1.2, 4.0) * strength,
			"phase": _rng.randf_range(0.0, TAU),
			"rise": _rng.randf_range(30.0, 125.0) * strength
		})
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
	var p := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - p
	match skill_id:
		&"fire_tornado":
			_draw_tornado(p, fade, true)
		&"wind_cyclone":
			_draw_tornado(p, fade, false)
		&"fire_burst":
			_draw_fire_burst(p, fade)
		&"water_jet_burst":
			_draw_water_burst(p, fade)
		&"water_torrent":
			_draw_torrent(p, fade)
		&"wind_blade_storm":
			_draw_blade_storm(p, fade)

func _draw_tornado(progress: float, fade: float, fire: bool) -> void:
	var height := (155.0 if fire else 140.0) * strength
	var max_radius := (62.0 if fire else 70.0) * strength
	var rotation_speed := age * (13.0 if fire else 9.0)
	draw_circle(Vector2.ZERO, max_radius * (0.55 + 0.25 * (1.0 - progress)), Color(tint.r, tint.g, tint.b, fade * 0.12))
	for i in range(7 + layer_budget * 2):
		var t := float(i) / float(7 + layer_budget * 2)
		var y := lerpf(height * 0.5, -height * 0.5, t)
		var radius := lerpf(max_radius * 0.22, max_radius, t)
		var angle := rotation_speed * (1.0 if fire else -1.0) + t * TAU * 2.4
		var center := Vector2(cos(angle) * radius, y)
		var next_t := minf(1.0, t + 0.12)
		var next_angle := rotation_speed * (1.0 if fire else -1.0) + next_t * TAU * 2.4
		var next_point := Vector2(cos(next_angle) * lerpf(max_radius * 0.22, max_radius, next_t), lerpf(height * 0.5, -height * 0.5, next_t))
		var width := (8.0 + 8.0 * sin(t * PI)) * strength
		draw_line(center, next_point, Color(tint.r, tint.g * 0.45, tint.b * 0.15, fade * 0.28), width * 2.3, true)
		draw_line(center, next_point, Color(tint.r, tint.g, tint.b, fade * 0.82), width, true)
		draw_line(center, next_point, Color(1.0, 0.94, 0.72, fade * 0.78), maxf(1.0, width * 0.22), true)
	for particle in _particles:
		var t := fposmod(age * 1.3 + float(particle["phase"]) / TAU, 1.0)
		var angle := float(particle["angle"]) + rotation_speed * (1.0 if fire else -1.0) + t * TAU * 2.0
		var radius := lerpf(max_radius * 0.12, max_radius * 0.9, t)
		var pos := Vector2(cos(angle) * radius, lerpf(height * 0.48, -height * 0.48, t))
		var dot_radius: float = float(particle["radius"]) * fade
		draw_circle(pos, dot_radius * 1.8, Color(tint.r, tint.g, tint.b, fade * 0.24))
		draw_circle(pos, dot_radius, Color(1.0, 0.92, 0.62, fade * 0.85) if fire else Color(0.9, 1.0, 0.98, fade * 0.85))

func _draw_fire_burst(progress: float, fade: float) -> void:
	var radius := (18.0 + progress * 118.0) * strength
	draw_circle(Vector2.ZERO, radius * 0.38, Color(1.0, 0.14, 0.01, fade * 0.2))
	for i in range(3 + layer_budget):
		var ring := radius * (0.45 + float(i) * 0.18)
		draw_arc(Vector2.ZERO, ring, age * (4.0 + float(i)), age * (4.0 + float(i)) + PI * 1.7, 52, Color(tint.r, tint.g * 0.7, tint.b, fade * (0.8 / float(i + 1))), maxf(1.2, 5.0 - float(i)), true)
	for particle in _particles:
		var angle: float = float(particle["angle"])
		var distance: float = float(particle["speed"]) * age
		var dir := Vector2.from_angle(angle)
		var pos := dir * distance + Vector2(0.0, 45.0 * age * age)
		var r: float = float(particle["radius"]) * fade
		draw_line(pos - dir * r * 5.0, pos, Color(1.0, 0.18, 0.01, fade * 0.5), r * 1.7, true)
		draw_circle(pos, r, Color(1.0, 0.85, 0.46, fade * 0.95))

func _draw_water_burst(progress: float, fade: float) -> void:
	var radius := (12.0 + progress * 112.0) * strength
	draw_circle(Vector2.ZERO, radius * 0.42, Color(0.02, 0.42, 1.0, fade * 0.2))
	for i in range(4 + layer_budget):
		var ring := radius * (0.4 + float(i) * 0.14)
		draw_arc(Vector2.ZERO, ring, age * (3.5 + float(i) * 0.7), age * (3.5 + float(i) * 0.7) + PI * 1.45, 48, Color(tint.r, tint.g, tint.b, fade * (0.8 / float(i + 1))), maxf(1.0, 4.5 - float(i) * 0.5), true)
	for particle in _particles:
		var angle: float = float(particle["angle"])
		var dir := Vector2.from_angle(angle)
		var distance: float = float(particle["speed"]) * age
		var pos := dir * distance + Vector2(0.0, 95.0 * age * age)
		var r: float = float(particle["radius"]) * fade
		draw_line(pos - dir * r * 5.0, pos, Color(0.1, 0.55, 1.0, fade * 0.58), r * 1.4, true)
		draw_circle(pos, r, Color(0.8, 0.98, 1.0, fade * 0.92))

func _draw_torrent(progress: float, fade: float) -> void:
	for i in range(5 + layer_budget * 2):
		var phase := age * 12.0 + float(i) * TAU / float(5 + layer_budget * 2)
		var radius := (30.0 + float(i % 4) * 18.0) * strength
		var center := Vector2(cos(phase) * radius, sin(phase * 0.7) * 38.0 * strength)
		var end := center + Vector2(cos(phase + 0.9), -1.4).normalized() * (65.0 + 25.0 * sin(phase)) * strength
		draw_line(center, end, Color(0.0, 0.28, 1.0, fade * 0.26), 12.0 * strength, true)
		draw_line(center, end, Color(0.12, 0.72, 1.0, fade * 0.75), 5.0 * strength, true)
		draw_line(center, end, Color(0.9, 1.0, 1.0, fade * 0.9), 1.4 * strength, true)
	draw_arc(Vector2.ZERO, (20.0 + progress * 58.0) * strength, age * 5.0, age * 5.0 + TAU * 0.86, 52, Color(tint.r, tint.g, tint.b, fade * 0.8), 3.0 * strength, true)

func _draw_blade_storm(progress: float, fade: float) -> void:
	var count := 4 + layer_budget * 2
	for i in range(count):
		var angle := age * (4.0 if i % 2 == 0 else -3.5) + TAU * float(i) / float(count)
		var direction := Vector2.from_angle(angle)
		var tangent := Vector2(-direction.y, direction.x)
		var center := direction * (25.0 + 25.0 * sin(age * 8.0 + float(i))) * strength
		var points := PackedVector2Array([center - tangent * 16.0 * strength, center + direction * 42.0 * strength, center + tangent * 16.0 * strength])
		draw_polyline(points, Color(tint.r, tint.g, tint.b, fade * 0.3), 12.0 * strength, true)
		draw_polyline(points, Color(0.9, 1.0, 0.96, fade * 0.88), 2.2 * strength, true)
