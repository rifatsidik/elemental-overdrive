extends Node2D
class_name NeonPlatformerLab

const PLAYER_SCRIPT = preload("res://scripts/platformer/neon_stickman.gd")

var player: NeonStickman
var world_time: float = 0.0
var touch_left: bool = false
var touch_right: bool = false
var touch_jump: bool = false
var touch_dash: bool = false

func _ready() -> void:
    _setup_input()
    _build_level()
    player = PLAYER_SCRIPT.new()
    player.name = "NeonStickman"
    player.position = Vector2(210.0, 690.0)
    add_child(player)
    player.landed_impact.connect(_on_player_landed)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.position = Vector2(192.0, -120.0)
    player.add_child(camera)
    queue_redraw()

func _setup_input() -> void:
    for action_name in ["move_left", "move_right", "jump", "dash"]:
        if not InputMap.has_action(action_name):
            InputMap.add_action(action_name)
    _add_action_key("move_left", KEY_A)
    _add_action_key("move_left", KEY_LEFT)
    _add_action_key("move_right", KEY_D)
    _add_action_key("move_right", KEY_RIGHT)
    _add_action_key("jump", KEY_SPACE)
    _add_action_key("jump", KEY_W)
    _add_action_key("jump", KEY_UP)
    _add_action_key("dash", KEY_SHIFT)

func _add_action_key(action_name: String, key: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = key
    InputMap.action_add_event(action_name, event)

func _build_level() -> void:
    _add_platform(Rect2(0.0, 760.0, 440.0, 80.0))
    _add_platform(Rect2(520.0, 680.0, 250.0, 34.0))
    _add_platform(Rect2(860.0, 590.0, 240.0, 34.0))
    _add_platform(Rect2(1180.0, 500.0, 250.0, 34.0))
    _add_platform(Rect2(1510.0, 610.0, 260.0, 34.0))
    _add_platform(Rect2(1870.0, 520.0, 250.0, 34.0))
    _add_platform(Rect2(2210.0, 690.0, 560.0, 80.0))
    _add_platform(Rect2(2920.0, 590.0, 260.0, 34.0))
    _add_platform(Rect2(3280.0, 500.0, 280.0, 34.0))
    _add_platform(Rect2(3650.0, 690.0, 650.0, 80.0))

func _add_platform(rect: Rect2) -> void:
    var body := StaticBody2D.new()
    body.position = rect.position
    body.name = "Platform"
    body.collision_layer = 1
    body.collision_mask = 1
    var shape_node := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = rect.size
    shape_node.shape = shape
    shape_node.position = rect.size * 0.5
    body.add_child(shape_node)
    add_child(body)
    body.set_meta("platform_rect", rect)

func _process(_delta: float) -> void:
    if is_instance_valid(player):
        player.touch_horizontal = -1.0 if touch_left else 1.0 if touch_right else 0.0
    queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        var pos: Vector2 = event.position
        if event.pressed:
            if pos.y > get_viewport_rect().size.y * 0.62:
                if pos.x < get_viewport_rect().size.x * 0.28:
                    touch_left = true
                elif pos.x < get_viewport_rect().size.x * 0.5:
                    touch_right = true
                elif pos.x < get_viewport_rect().size.x * 0.76:
                    touch_jump = true
                    if is_instance_valid(player):
                        player.jump_from_touch()
                else:
                    touch_dash = true
                    if is_instance_valid(player):
                        player.dash_from_touch()
        else:
            touch_left = false
            touch_right = false
            touch_jump = false
            touch_dash = false

func _on_player_landed(_strength: float) -> void:
    pass

func _draw() -> void:
    var view_size: Vector2 = get_viewport_rect().size
    var camera_x: float = 0.0
    if is_instance_valid(player):
        camera_x = player.global_position.x - view_size.x * 0.38
    draw_rect(Rect2(Vector2.ZERO, view_size), Color("#040611"))
    for i in range(22):
        var x: float = fposmod(float(i) * 80.0 - fposmod(camera_x, 80.0), view_size.x)
        draw_line(Vector2(x, 0.0), Vector2(x, view_size.y), Color(0.08, 0.35, 0.55, 0.12), 1.0)
    for y in range(0, int(view_size.y), 48):
        draw_line(Vector2(0.0, float(y)), Vector2(view_size.x, float(y)), Color(0.08, 0.35, 0.55, 0.11), 1.0)

    for child in get_children():
        if child is StaticBody2D and child.has_meta("platform_rect"):
            var rect: Rect2 = child.get_meta("platform_rect")
            var screen_rect := Rect2(rect.position - Vector2(camera_x, 0.0), rect.size)
            draw_rect(screen_rect, Color(0.025, 0.055, 0.12, 0.95))
            draw_line(screen_rect.position, screen_rect.position + Vector2(screen_rect.size.x, 0.0), Color(0.08, 0.72, 1.0, 0.7), 3.0, true)
            draw_line(screen_rect.position + Vector2(0.0, 4.0), screen_rect.position + Vector2(screen_rect.size.x, 4.0), Color(0.05, 0.35, 0.9, 0.24), 1.0, true)

    draw_rect(Rect2(0.0, 0.0, view_size.x, 84.0), Color(0.015, 0.025, 0.07, 0.96))
    draw_string(ThemeDB.fallback_font, Vector2(24.0, 33.0), "OVERDRIVE // NEON PLATFORMER", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("#aafaff"))
    draw_string(ThemeDB.fallback_font, Vector2(25.0, 57.0), "PROCEDURAL CHARACTER  /  NO SPRITE TEXTURES", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#6f91bf"))
    draw_string(ThemeDB.fallback_font, Vector2(view_size.x - 24.0, 33.0), "MOVE  A/D  |  JUMP  SPACE  |  DASH  SHIFT", HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 14, Color("#ffd34d"))
    draw_string(ThemeDB.fallback_font, Vector2(view_size.x - 24.0, 57.0), "WIP: CHARACTER + PLATFORM PHYSICS", HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 12, Color("#6f91bf"))
    _draw_touch_button(Vector2(74.0, view_size.y - 72.0), "◀", touch_left)
    _draw_touch_button(Vector2(154.0, view_size.y - 72.0), "▶", touch_right)
    _draw_touch_button(Vector2(view_size.x - 164.0, view_size.y - 72.0), "JUMP", touch_jump)
    _draw_touch_button(Vector2(view_size.x - 70.0, view_size.y - 72.0), "DASH", touch_dash)

func _draw_touch_button(center: Vector2, label: String, active: bool) -> void:
    var color := Color(0.05, 0.65, 0.95, 0.6 if active else 0.18)
    draw_circle(center, 32.0, Color(color.r, color.g, color.b, 0.12))
    draw_arc(center, 32.0, 0.0, TAU, 40, Color(0.12, 0.86, 1.0, 0.8), 2.0, true)
    draw_string(ThemeDB.fallback_font, center + Vector2(-26.0, 5.0), label, HORIZONTAL_ALIGNMENT_CENTER, 52.0, 12, Color("#d7ffff"))
