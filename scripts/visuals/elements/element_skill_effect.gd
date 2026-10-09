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
	# Keep water ribbons translucent; fire/wind retain additive energy glow.
	var skill_material := CanvasItemMaterial.new()
	skill_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX if String(skill_id).begins_with("water_") else CanvasItemMaterial.BLEND_MODE_ADD
	material = skill_material
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
	var skill_material := CanvasItemMaterial.new()
	skill_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX if String(skill_id).begins_with("water_") else CanvasItemMaterial.BLEND_MODE_ADD
	material = skill_material
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
	if fire:
		_draw_fire_tornado(progress, fade)
		return
	var height := 140.0 * strength
	var max_radius := 70.0 * strength
	var rotation_speed := age * 9.0
	draw_circle(Vector2.ZERO, max_radius * (0.55 + 0.25 * (1.0 - progress)), Color(tint.r, tint.g, tint.b, fade * 0.12))
	for i in range(7 + layer_budget * 2):
		var t := float(i) / float(7 + layer_budget * 2)
		var y := lerpf(height * 0.5, -height * 0.5, t)
		var radius := lerpf(max_radius * 0.22, max_radius, t)
		var angle := -rotation_speed + t * TAU * 2.4
		var center := Vector2(cos(angle) * radius, y)
		var next_t := minf(1.0, t + 0.12)
		var next_angle := -rotation_speed + next_t * TAU * 2.4
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
		draw_circle(pos, dot_radius, Color(0.9, 1.0, 0.98, fade * 0.85))

func _draw_fire_burst(progress: float, fade: float) -> void:
	# Flame tongues rise from a hot base; avoid abstract energy rings.
	var flare := 1.0 - smoothstep(0.0, 0.22, age)
	draw_circle(Vector2(0.0, 8.0 * strength), (20.0 + flare * 15.0) * strength, Color(1.0, 0.12, 0.015, fade * 0.2))
	draw_circle(Vector2(0.0, 7.0 * strength), (10.0 + flare * 8.0) * strength, Color(1.0, 0.36, 0.025, fade * 0.42))
	var tongue_count := 6 + layer_budget * 2
	for i in range(tongue_count):
		var u := float(i) / float(maxi(1, tongue_count - 1))
		var angle := lerpf(-1.12, 1.12, u) + sin(age * 17.0 + float(i) * 2.1) * 0.13
		var direction := Vector2(sin(angle), -cos(angle)).normalized()
		var base := Vector2(lerpf(-15.0, 15.0, u) * strength, 10.0 * strength)
		var length := (48.0 + 42.0 * (0.5 + 0.5 * sin(float(i) * 2.7 + age * 11.0))) * strength * (1.0 - progress * 0.3)
		var width := (9.0 + 5.0 * sin(float(i) * 1.9 + age * 13.0)) * strength
		var phase := float(i) * 1.73
		draw_colored_polygon(_build_flame_shape(base, direction, length, width, phase), Color(1.0, 0.12, 0.012, fade * 0.92))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.06, direction, length * 0.78, width * 0.62, phase + 0.8), Color(1.0, 0.38, 0.025, fade * 0.96))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.12, direction, length * 0.56, width * 0.28, phase + 1.6), Color(1.0, 0.88, 0.32, fade * 0.96))
	for particle in _particles:
		var angle: float = float(particle["angle"])
		var speed: float = float(particle["speed"])
		var pos := Vector2(cos(angle) * speed * age * 0.72, -absf(sin(angle)) * speed * age - 25.0 * age + 38.0 * age * age)
		var r: float = float(particle["radius"]) * fade * 0.72
		draw_circle(pos, r * 1.8, Color(1.0, 0.2, 0.01, fade * 0.18))
		draw_circle(pos, r, Color(1.0, 0.82, 0.3, fade * 0.92))

func _build_flame_shape(base: Vector2, direction: Vector2, length: float, half_width: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var normal := Vector2(-direction.y, direction.x)
	var segments := 12
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var shape_width := half_width * pow(1.0 - t, 0.78) * (0.82 + 0.18 * sin(t * PI * 3.0 + phase))
		var sway := sin(t * 7.0 + phase + age * 18.0) * half_width * 0.2 * t
		points.append(base + direction * length * t + normal * (sway + shape_width))
	for i in range(segments, -1, -1):
		var t := float(i) / float(segments)
		var shape_width := half_width * pow(1.0 - t, 0.78) * (0.82 + 0.18 * sin(t * PI * 3.0 + phase))
		var sway := sin(t * 7.0 + phase + age * 18.0) * half_width * 0.2 * t
		points.append(base + direction * length * t + normal * (sway - shape_width))
	return points

func _draw_fire_tornado(progress: float, fade: float) -> void:
	# Layered flame tongues wrap upward around a central rising draft.
	var height := 175.0 * strength
	var layers := 5 + layer_budget * 2
	for i in range(layers):
		var t := float(i) / float(maxi(1, layers - 1))
		var y := lerpf(height * 0.48, -height * 0.46, t)
		var envelope := 0.25 + 0.75 * sin(PI * t)
		var orbit := age * 7.5 + t * TAU * 1.7
		var side := sin(orbit + float(i) * 0.7) * 38.0 * strength * envelope
		var base := Vector2(side, y)
		var direction := Vector2(sin(orbit * 0.3) * 0.32, -1.0).normalized()
		var length := (48.0 + 38.0 * envelope) * strength * (1.0 - progress * 0.2)
		var width := (13.0 + 7.0 * envelope) * strength
		var phase := float(i) * 1.31
		draw_colored_polygon(_build_flame_shape(base, direction, length, width, phase), Color(1.0, 0.1, 0.008, fade * 0.72))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.08, direction, length * 0.74, width * 0.62, phase + 0.9), Color(1.0, 0.34, 0.018, fade * 0.86))
		draw_colored_polygon(_build_flame_shape(base + direction * length * 0.15, direction, length * 0.52, width * 0.25, phase + 1.8), Color(1.0, 0.86, 0.3, fade * 0.88))
	for particle in _particles:
		var t := fposmod(age * 0.9 + float(particle["phase"]) / TAU, 1.0)
		var angle := float(particle["angle"]) + age * 3.0
		var radius := lerpf(8.0, 42.0 * strength, t)
		var pos := Vector2(cos(angle) * radius, lerpf(height * 0.42, -height * 0.46, t))
		var r: float = float(particle["radius"]) * fade * 0.65
		draw_circle(pos, r * 1.8, Color(1.0, 0.18, 0.01, fade * 0.16))
		draw_circle(pos, r, Color(1.0, 0.8, 0.3, fade * 0.9))

func _draw_water_burst(progress: float, fade: float) -> void:
	# A pressurized water sheet with a broad, uneven crest and round droplets.
	var expansion := smoothstep(0.0, 0.62, progress)
	var collapse := smoothstep(0.55, 1.0, progress)
	var width := (26.0 + 92.0 * expansion) * strength
	var height := (35.0 + 58.0 * (1.0 - collapse)) * strength
	var sheet := PackedVector2Array()
	for i in range(25):
		var u := float(i) / 24.0
		var x := lerpf(-width, width, u)
		var crest := pow(maxf(0.0, sin(PI * u)), 0.58)
		var wobble := sin(u * 24.0 + age * 21.0) * 3.2 * strength
		sheet.append(Vector2(x, -crest * height + wobble))
	for i in range(24, -1, -1):
		var u := float(i) / 24.0
		sheet.append(Vector2(lerpf(-width, width, u), 8.0 + sin(u * TAU * 2.0 - age * 8.0) * 1.8 * strength))
	draw_colored_polygon(sheet, Color(0.02, 0.3, 0.67, fade * 0.82))
	var crest_line := PackedVector2Array()
	for i in range(2, 23):
		crest_line.append(sheet[i] + Vector2(0.0, 2.0 * strength))
	draw_polyline(crest_line, Color(0.48, 0.85, 1.0, fade * 0.9), 2.0 * strength, true)
	# Outward droplets arc down under gravity; they are not uniform radial rays.
	for particle in _particles:
		var angle: float = float(particle["angle"])
		var speed: float = float(particle["speed"]) * 0.85
		var dir := Vector2.from_angle(angle)
		var pos := dir * speed * age + Vector2(0.0, 210.0 * age * age)
		var r: float = float(particle["radius"]) * 0.72 * fade
		draw_circle(pos, r, Color(0.22, 0.65, 0.9, fade * 0.9))
		draw_circle(pos - Vector2(r * 0.2, r * 0.3), r * 0.3, Color(0.9, 0.99, 1.0, fade * 0.8))
	# A flattened expanding ripple reads as a surface disturbance.
	var ripple_points := PackedVector2Array()
	var rx := (18.0 + progress * 72.0) * strength
	var ry := (4.0 + progress * 13.0) * strength
	for i in range(33):
		var a := PI * float(i) / 32.0
		ripple_points.append(Vector2(cos(a) * rx, 13.0 + sin(a) * ry))
	draw_polyline(ripple_points, Color(0.3, 0.7, 0.94, fade * 0.7), 2.0 * strength, true)

func _draw_torrent(progress: float, fade: float) -> void:
	# One continuous twisting liquid volume with a broad silhouette, not thin vertical strands.
	var height := 185.0 * strength
	var half_width := 25.0 * strength
	var body := PackedVector2Array()
	var inner_body := PackedVector2Array()
	var segments := 24
	for i in range(segments + 1):
		var u := float(i) / float(segments)
		var y := lerpf(-height * 0.52, height * 0.48, u)
		var envelope := 0.38 + 0.62 * sin(PI * u)
		var center_x := sin(u * TAU * 1.25 - age * 5.0) * half_width * 0.62 * envelope
		center_x += sin(u * 13.0 + age * 8.0) * 2.0 * strength
		var width := half_width * envelope * (0.82 + 0.18 * sin(u * 19.0 - age * 12.0))
		body.append(Vector2(center_x - width, y))
		inner_body.append(Vector2(center_x - width * 0.52, y))
	for i in range(segments, -1, -1):
		var u := float(i) / float(segments)
		var y := lerpf(-height * 0.52, height * 0.48, u)
		var envelope := 0.38 + 0.62 * sin(PI * u)
		var center_x := sin(u * TAU * 1.25 - age * 5.0) * half_width * 0.62 * envelope
		center_x += sin(u * 13.0 + age * 8.0) * 2.0 * strength
		var width := half_width * envelope * (0.82 + 0.18 * sin(u * 19.0 - age * 12.0))
		body.append(Vector2(center_x + width, y))
		inner_body.append(Vector2(center_x + width * 0.38, y))
	draw_colored_polygon(body, Color(0.015, 0.24, 0.6, fade * 0.84))
	draw_colored_polygon(inner_body, Color(0.02, 0.5, 0.84, fade * 0.88))
	# Broken, short surface glints read as reflected light, not long blades.
	for i in range(5):
		var u := fposmod(float(i) * 0.21 + age * 0.37, 0.9) + 0.05
		var y := lerpf(-height * 0.42, height * 0.38, u)
		var envelope := 0.38 + 0.62 * sin(PI * u)
		var center_x := sin(u * TAU * 1.25 - age * 5.0) * half_width * 0.62 * envelope
		var glint_width := (5.0 + 8.0 * sin(age * 9.0 + float(i))) * strength
		draw_line(Vector2(center_x - glint_width, y), Vector2(center_x + glint_width, y - 2.0), Color(0.62, 0.9, 1.0, fade * 0.72), 1.5 * strength, true)
	for i in range(8 + layer_budget * 3):
		var angle := age * 3.2 + float(i) * TAU / float(8 + layer_budget * 3)
		var speed := (32.0 + float(i % 4) * 11.0) * strength
		var pos := Vector2(cos(angle) * speed * progress, 24.0 + sin(angle) * speed * 0.18 + 25.0 * progress * progress)
		var r := (1.8 + float(i % 3) * 0.7) * strength * fade
		draw_circle(pos, r, Color(0.5, 0.82, 0.98, fade * 0.88))
	var ring := PackedVector2Array()
	for i in range(33):
		var a := PI * float(i) / 32.0
		ring.append(Vector2(cos(a) * (20.0 + progress * 54.0) * strength, 20.0 + sin(a) * (5.0 + progress * 10.0) * strength))
	draw_polyline(ring, Color(tint.r, tint.g, tint.b, fade * 0.76), 2.4 * strength)

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
