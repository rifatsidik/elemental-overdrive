extends Node2D
class_name OverdriveElementProjectile

## Presentation-only projectile ribbon. Gameplay collision/damage remains authoritative elsewhere.
var element_id: StringName = &"fire"
var travel_vector: Vector2 = Vector2.RIGHT * 240.0
var strength: float = 1.0
var tint: Color = Color.WHITE
var age: float = 0.0
var lifetime: float = 0.24
var layer_budget: int = 2
var _seed: int = 1
var _rng := RandomNumberGenerator.new()
var _droplet_offsets: Array[Vector2] = []
signal arrived(element_id: StringName, target_position: Vector2, source_position: Vector2, strength: float, color: Color)

func configure(new_element: StringName, destination_offset: Vector2, new_strength: float, new_seed: int, layers: int, color: Color) -> void:
	element_id = new_element
	travel_vector = destination_offset
	strength = clampf(new_strength, 0.35, 2.0)
	_seed = new_seed
	_rng.seed = _seed
	layer_budget = clampi(layers, 1, 3)
	tint = color
	# Water needs controlled alpha layering; additive blending made the ribbons clip into a noisy white streak.
	var projectile_material := CanvasItemMaterial.new()
	projectile_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX if element_id == &"water" else CanvasItemMaterial.BLEND_MODE_ADD
	material = projectile_material
	lifetime = clampf(destination_offset.length() / 1900.0, 0.12, 0.38)
	_droplet_offsets.clear()
	for i in range(12 + layer_budget * 4):
		_droplet_offsets.append(Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)))
	queue_redraw()

func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	set_process(true)

func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		arrived.emit(element_id, position + travel_vector, position, strength, tint)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if travel_vector.length_squared() < 1.0:
		return
	var t := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - smoothstep(0.72, 1.0, t)
	var head := travel_vector * t
	var direction := travel_vector.normalized()
	var normal := Vector2(-direction.y, direction.x)
	match element_id:
		&"fire":
			_draw_fire(head, direction, normal, fade, t)
		&"water":
			_draw_water(head, direction, normal, fade, t)
		&"wind":
			_draw_wind(head, direction, normal, fade, t)

func _draw_fire(head: Vector2, direction: Vector2, normal: Vector2, fade: float, t: float) -> void:
	var length := (54.0 + 16.0 * sin(age * 58.0)) * strength
	var width := 10.0 * strength
	for layer in range(layer_budget + 1):
		var offset := normal * sin(age * 32.0 + float(layer)) * 4.0 * strength
		var tail := head - direction * length * (1.0 + float(layer) * 0.3) + offset
		var alpha := fade * (0.28 / float(layer + 1))
		draw_line(tail, head + offset, Color(1.0, 0.12 + float(layer) * 0.13, 0.015, alpha), width * (2.4 - float(layer) * 0.35), true)
		draw_line(tail, head + offset, Color(1.0, 0.42 + float(layer) * 0.12, 0.04, alpha * 1.8), width * (0.95 - float(layer) * 0.12), true)
	draw_line(head - direction * length * 1.05, head, Color(1.0, 0.25, 0.025, fade * 0.92), width * 1.2, true)
	draw_line(head - direction * length * 0.72, head, Color(1.0, 0.92, 0.6, fade), width * 0.34, true)
	draw_circle(head, 8.0 * strength * fade, Color(1.0, 0.72, 0.2, fade * 0.78))
	draw_circle(head, 3.5 * strength * fade, Color(1.0, 1.0, 0.82, fade))

func _draw_water(head: Vector2, direction: Vector2, normal: Vector2, fade: float, t: float) -> void:
	var tail_length := (78.0 + 18.0 * sin(age * 45.0)) * strength
	var tail := head - direction * tail_length
	var wave := sin(age * 37.0 + float(_seed % 19)) * 5.0 * strength
	var width := (8.0 + 4.0 * sin(age * 24.0)) * strength
	# Broad liquid body, two flowing ribbons, and a bright pressurized core.
	draw_line(tail, head, Color(0.015, 0.18, 1.0, fade * 0.22), width * 4.4, true)
	draw_line(tail + normal * wave, head, Color(0.02, 0.46, 1.0, fade * 0.62), width * 2.0, true)
	draw_line(tail - normal * wave, head, Color(0.0, 0.82, 1.0, fade * 0.76), width * 1.3, true)
	draw_line(tail + normal * wave * 0.35, head, Color(0.82, 0.98, 1.0, fade * 0.96), width * 0.38, true)
	for i in range(_droplet_offsets.size()):
		var offset: Vector2 = _droplet_offsets[i]
		var along := fposmod(float(i) * 0.173 + age * 5.5, 1.0)
		var pos := head - direction * along * tail_length + normal * offset.x * (13.0 + 7.0 * sin(age * 29.0 + float(i))) * strength
		var radius := (1.4 + absf(offset.y) * 2.8) * strength * fade
		draw_line(pos - direction * radius * 3.0, pos, Color(0.12, 0.6, 1.0, fade * 0.55), radius, true)
		draw_circle(pos, radius, Color(0.72, 0.96, 1.0, fade * 0.85))
	draw_circle(head, 10.0 * strength * fade, Color(0.06, 0.56, 1.0, fade * 0.42))
	draw_circle(head, 4.5 * strength * fade, Color(0.92, 1.0, 1.0, fade))

func _draw_wind(head: Vector2, direction: Vector2, normal: Vector2, fade: float, t: float) -> void:
	# A traveling sword-like crescent, not a circular explosion.
	var width := (46.0 + 10.0 * sin(age * 31.0)) * strength
	var reach := 68.0 * strength
	for layer in range(layer_budget + 1):
		var points := PackedVector2Array()
		var segments := 16
		for i in range(segments + 1):
			var angle := lerpf(-1.05, 1.05, float(i) / float(segments))
			var radius := reach * (1.0 + 0.13 * sin(angle * 4.0 + age * 30.0))
			points.append(head + direction * cos(angle) * radius + normal * sin(angle) * radius * 0.78)
		var alpha := fade * (0.24 / float(layer + 1))
		draw_polyline(points, Color(0.12, 1.0, 0.78, alpha), width * (1.5 - float(layer) * 0.18), true)
		draw_polyline(points, Color(0.5, 1.0, 0.9, alpha * 2.2), maxf(1.0, width * (0.48 - float(layer) * 0.06)), true)
		draw_polyline(points, Color(0.96, 1.0, 1.0, fade * 0.92), maxf(1.0, width * 0.11), true)
	var tail := head - direction * 54.0 * strength
	draw_line(tail + normal * 8.0 * strength, head + normal * 3.0 * strength, Color(0.25, 1.0, 0.83, fade * 0.75), 3.0 * strength, true)
	draw_line(tail - normal * 8.0 * strength, head - normal * 3.0 * strength, Color(0.92, 1.0, 0.98, fade * 0.75), 1.6 * strength, true)
