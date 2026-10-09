extends Node2D
class_name EnemyActor

@export var move_speed := 72.0
@export var health := 3
var target: Node2D
var hue_color := Color("#ff4778")
var pulse := 0.0

func _ready() -> void:
    var palette: Array[Color] = [Color("#ff4778"), Color("#ff8d48"), Color("#b56cff")]
    hue_color = palette[randi() % palette.size()]
    target = get_meta("target", null)

func _process(delta: float) -> void:
    pulse += delta * 4.0
    if is_instance_valid(target):
        var delta_to_target: Vector2 = target.global_position - global_position
        if delta_to_target.length_squared() > 1.0:
            global_position += delta_to_target.normalized() * move_speed * delta
    queue_redraw()

func _draw() -> void:
    var radius := 14.0 + sin(pulse) * 1.5
    draw_circle(Vector2.ZERO, radius + 8.0, Color(hue_color.r, hue_color.g, hue_color.b, 0.08))
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, -radius), Vector2(radius, 0), Vector2(0, radius), Vector2(-radius, 0)
    ]), hue_color)
    draw_circle(Vector2.ZERO, 3.0, Color("#170d22"))
