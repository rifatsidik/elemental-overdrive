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
	# A pressurized water sheet that tears into curved fingers and falls as droplets.
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
	# A few compact, thick curls; the broad sheet and droplets carry the splash.
	for i in range(3 + layer_budget):
		var u := float(i) / float(2 + layer_budget)
		var side := lerpf(-1.0, 1.0, u)
		var base := Vector2(side * width * 0.7, 1.0)
		var h := (24.0 + 14.0 * sin(age * 8.0 + float(i) * 1.7)) * strength
		var control := base + Vector2(side * h * 0.2, -h * 0.78)
		var tip := base + Vector2(side * h * 0.36 + sin(age * 13.0 + float(i)) * 2.0, -h * 0.3)
		var curve := PackedVector2Array()
		for step in range(13):
			var t := float(step) / 12.0
			var q := 1.0 - t
			curve.append(base * q * q + control * 2.0 * q * t + tip * t * t)
		draw_polyline(curve, Color(0.015, 0.22, 0.55, fade * 0.88), 8.0 * strength, true)
		draw_polyline(curve, Color(0.02, 0.5, 0.82, fade * 0.94), 4.5 * strength, true)
		var glint := PackedVector2Array()
		for glint_index in range(3, 7):
			glint.append(curve[glint_index])
		draw_polyline(glint, Color(0.72, 0.95, 1.0, fade * 0.84), 1.2 * strength, true)
		draw_circle(tip, 2.5 * strength, Color(0.42, 0.8, 0.98, fade * 0.9))
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
	# A thick, continuously twisting column of water built from tapered fluid ribbons.
	var height := 185.0 * strength
	var width := 34.0 * strength
	for strand in range(3 + layer_budget):
		var phase := age * (5.0 + float(strand) * 0.7) + float(strand) * TAU / float(3 + layer_budget)
		var points := PackedVector2Array()
		var highlight := PackedVector2Array()
		var segments := 22
		for i in range(segments + 1):
			var u := float(i) / float(segments)
			var y := lerpf(height * 0.48, -height * 0.52, u)
			var envelope := 0.35 + 0.65 * sin(PI * u)
			var x := sin(u * TAU * 1.5 + phase) * width * envelope
			x += sin(u * 15.0 - age * 19.0 + float(strand)) * 3.0 * strength
			points.append(Vector2(x, y))
			highlight.append(Vector2(x + 2.5 * strength, y))
		var ribbon_width := (7.0 + 5.0 * sin(phase)) * strength
		draw_polyline(points, Color(0.015, 0.24, 0.6, fade * 0.76), ribbon_width * 1.9, true)
		draw_polyline(points, Color(0.02, 0.48, 0.79, fade * 0.92), ribbon_width, true)
		draw_polyline(highlight, Color(0.56, 0.86, 1.0, fade * 0.84), maxf(1.0, ribbon_width * 0.22), true)
	# Water breaks off at the base in uneven beads.
	for i in range(8 + layer_budget * 3):
		var angle := age * 3.2 + float(i) * TAU / float(8 + layer_budget * 3)
		var speed := (32.0 + float(i % 4) * 11.0) * strength
		var pos := Vector2(cos(angle) * speed * progress, 24.0 + sin(angle) * speed * 0.18 + 25.0 * progress * progress)
		var r := (1.8 + float(i % 3) * 0.7) * strength * fade
		draw_circle(pos, r, Color(0.5, 0.82, 0.98, fade * 0.88))
	# Pressure ring is flattened to the floor plane.
	var ring := PackedVector2Array()
	for i in range(33):
		var a := PI * float(i) / 32.0
		ring.append(Vector2(cos(a) * (20.0 + progress * 54.0) * strength, 20.0 + sin(a) * (5.0 + progress * 10.0) * strength))
	draw_polyline(ring, Color(tint.r, tint.g, tint.b, fade * 0.76), 2.4 * strength, true)

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
