extends Node2D
class_name PlayerController

@export var move_speed := 310.0
var facing := Vector2.RIGHT
var arena_bounds := Rect2(24.0, 84.0, 1552.0, 790.0)
var attack_clock := 0.0

func _process(delta: float) -> void:
    var direction := Vector2.ZERO
    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        direction.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        direction.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        direction.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        direction.y += 1.0
    if direction.length_squared() > 1.0:
        direction = direction.normalized()
    position += direction * move_speed * delta
    if direction.length_squared() > 0.01:
        facing = direction
    var bounds := get_viewport_rect().size
    position.x = clampf(position.x, 24.0, bounds.x - 24.0)
    position.y = clampf(position.y, 88.0, bounds.y - 25.0)
    queue_redraw()

func _draw() -> void:
    var glow := Color("#ffd34d")
    draw_circle(Vector2.ZERO, 38.0, Color(glow.r, glow.g, glow.b, 0.07))
    draw_circle(Vector2.ZERO, 27.0, Color(glow.r, glow.g, glow.b, 0.12))
    draw_circle(Vector2.ZERO, 16.0, Color("#aafaff"))
    draw_colored_polygon(PackedVector2Array([
        facing * 31.0,
        facing.rotated(2.45) * 13.0,
        facing.rotated(-2.45) * 13.0
    ]), Color.WHITE)
    draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 36, Color(0.45, 0.95, 1.0, 0.8), 2.0, true)
