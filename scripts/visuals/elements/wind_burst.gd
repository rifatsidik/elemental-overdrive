extends Node2D
class_name OverdriveWindBurst

var age: float = 0.0
var lifetime: float = 0.52
var strength: float = 1.0
var layer_budget: int = 2
var tint: Color = Color(0.55, 1.0, 0.82, 1.0)

func configure(new_strength: float, layers: int, color: Color = Color(0.55, 1.0, 0.82, 1.0)) -> void:
	strength = clampf(new_strength, 0.25, 2.0)
	layer_budget = clampi(layers, 1, 3)
	tint = color
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
	var rotation := age * 8.0
	for i in range(layer_budget):
		var radius := (12.0 + progress * (38.0 + float(i) * 11.0)) * strength
		var start_angle := rotation + float(i) * 1.8
		var sweep := lerpf(1.7, 3.8, progress)
		var color := Color(tint.r, tint.g, tint.b, fade * (0.72 / float(i + 1)))
		draw_arc(Vector2.ZERO, radius, start_angle, start_angle + sweep, 32, color, maxf(1.0, 3.0 - float(i)), true)
		draw_arc(Vector2.ZERO, radius * 0.72, start_angle + PI, start_angle + PI + sweep * 0.65, 24, Color(0.88, 1.0, 0.96, fade * 0.48 / float(i + 1)), 1.2, true)
	for i in range(6 + layer_budget * 2):
		var angle := rotation * 0.6 + TAU * float(i) / float(6 + layer_budget * 2)
		var direction := Vector2.from_angle(angle)
		var inner := direction * (8.0 + progress * 18.0) * strength
		var outer := direction * (18.0 + progress * 62.0) * strength
		draw_line(inner, outer, Color(tint.r, tint.g, tint.b, fade * 0.38), 1.4, true)
