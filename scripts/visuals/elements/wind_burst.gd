extends Node2D
class_name OverdriveWindBurst

var age: float = 0.0
var lifetime: float = 0.68
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.55, 1.0, 0.82, 1.0)

func configure(new_strength: float, layers: int, color: Color = Color(0.55, 1.0, 0.82, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.25)
	layer_budget = clampi(layers, 1, 3)
	tint = color
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
	var progress := clampf(age / lifetime, 0.0, 1.0)
	var fade := 1.0 - progress
	var punch := 1.0 - smoothstep(0.0, 0.24, age)
	var rotation := age * 9.5
	# Expanding pressure front with offset, broken rings for a turbulent silhouette.
	draw_circle(Vector2.ZERO, (15.0 + progress * 28.0) * strength, Color(tint.r, tint.g, tint.b, punch * 0.11))
	for i in range(layer_budget + 1):
		var radius := (18.0 + progress * (66.0 + float(i) * 17.0)) * strength
		var start_angle := rotation * (1.0 if i % 2 == 0 else -0.72) + float(i) * 1.73
		var sweep := lerpf(1.25, 4.7, progress)
		var alpha := fade * (0.76 / float(i + 1))
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + sweep, 42, Color(tint.r, tint.g, tint.b, alpha), maxf(1.2, 5.0 - float(i)), true)
		draw_arc(Vector2.ZERO, radius * 0.73, start_angle + PI, start_angle + PI + sweep * 0.48, 30, Color(0.9, 1.0, 0.97, alpha * 0.7), maxf(1.0, 2.4 - float(i) * 0.4), true)
	# Fast, tapered-looking gusts cut across the expanding vortex.
	var gust_count := 5 + layer_budget * 3
	for i in range(gust_count):
		var angle := rotation * 0.58 + TAU * float(i) / float(gust_count)
		var direction := Vector2.from_angle(angle)
		var tangent := Vector2(-direction.y, direction.x)
		var inner := direction * (7.0 + progress * 18.0) * strength
		var outer := direction * (28.0 + progress * 92.0) * strength
		var sweep_offset := tangent * sin(age * 18.0 + float(i) * 2.1) * 13.0 * strength
		draw_line(inner, outer + sweep_offset, Color(tint.r, tint.g, tint.b, fade * 0.25), 7.0 * strength, true)
		draw_line(inner, outer + sweep_offset, Color(tint.r, tint.g, tint.b, fade * 0.8), 2.1 * strength, true)
		draw_line(inner.lerp(outer, 0.38), outer + sweep_offset * 0.7, Color(0.94, 1.0, 0.98, fade * 0.9), 1.0 * strength, true)
	# Bright central pressure flash fades faster than the outer turbulence.
	draw_circle(Vector2.ZERO, (7.0 + 12.0 * punch) * strength, Color(0.65, 1.0, 0.9, punch * 0.32))
	draw_arc(Vector2.ZERO, (11.0 + progress * 20.0) * strength, rotation, rotation + PI * 1.7, 32, Color(0.95, 1.0, 0.98, fade * 0.85), 2.0 * strength, true)
