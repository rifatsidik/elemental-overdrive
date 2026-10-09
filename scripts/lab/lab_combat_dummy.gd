extends "res://scripts/combat/combatant.gd"
class_name OverdriveLabCombatDummy

var _pulse_time: float = 0.0

func _ready() -> void:
	super._ready()
	queue_redraw()

func _process(delta: float) -> void:
	_pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var health_ratio := get_health_ratio()
	var alive := not is_defeated
	var pulse := 0.5 + 0.5 * sin(_pulse_time * 3.0)
	var core_color := Color(0.16, 0.85, 1.0, 1.0) if alive else Color(0.24, 0.28, 0.36, 0.8)
	draw_circle(Vector2.ZERO, 25.0, Color(0.02, 0.06, 0.13, 0.95))
	draw_arc(Vector2.ZERO, 29.0, 0.0, TAU, 48, Color(core_color.r, core_color.g, core_color.b, 0.45 + pulse * 0.25), 2.0, true)
	draw_circle(Vector2.ZERO, 15.0, Color(core_color.r, core_color.g, core_color.b, 0.18))
	draw_circle(Vector2.ZERO, 6.0, core_color)
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color(0.92, 1.0, 1.0, 0.95))
	draw_rect(Rect2(Vector2(-38.0, -43.0), Vector2(76.0, 5.0)), Color(0.025, 0.04, 0.08, 0.95))
	draw_rect(Rect2(Vector2(-38.0, -43.0), Vector2(76.0 * health_ratio, 5.0)), Color(0.16, 1.0, 0.68, 0.92) if alive else Color(0.35, 0.38, 0.44, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(-38.0, -51.0), String(combatant_id), HORIZONTAL_ALIGNMENT_LEFT, 76.0, 11, Color(0.68, 0.88, 1.0, 0.95))
	if is_instance_valid(status_controller):
		var active := status_controller.active_statuses()
		for i in range(active.size()):
			var color := Color(1.0, 0.38, 0.08, 1.0)
			match active[i]:
				&"soaked":
					color = Color(0.15, 0.55, 1.0, 1.0)
				&"charged":
					color = Color(0.2, 0.95, 1.0, 1.0)
				&"staggered":
					color = Color(0.62, 1.0, 0.78, 1.0)
				&"steamed":
					color = Color(0.85, 0.92, 1.0, 1.0)
			draw_circle(Vector2(-13.0 + float(i) * 13.0, 36.0), 4.0, color)
	if is_defeated:
		draw_string(ThemeDB.fallback_font, Vector2(-26.0, 6.0), "DOWN", HORIZONTAL_ALIGNMENT_LEFT, 52.0, 10, Color(0.95, 0.35, 0.5, 1.0))
