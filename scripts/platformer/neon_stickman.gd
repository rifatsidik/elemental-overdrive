extends CharacterBody2D
class_name NeonStickman

## Sprite-free neon stickman. Every body part is drawn procedurally in _draw().

signal landed_impact(strength: float)

@export var run_speed: float = 330.0
@export var acceleration: float = 1900.0
@export var air_control: float = 0.72
@export var jump_velocity: float = -590.0
@export var gravity: float = 1550.0
@export var dash_speed: float = 760.0
@export var dash_duration: float = 0.14

var facing: float = 1.0
var gait_time: float = 0.0
var dash_time: float = 0.0
var dash_cooldown: float = 0.0
var was_on_floor: bool = false
var landing_flash: float = 0.0
var touch_horizontal: float = 0.0

const CYAN := Color(0.10, 0.92, 1.0, 1.0)
const BLUE := Color(0.12, 0.35, 1.0, 1.0)
const WHITE := Color(0.88, 1.0, 1.0, 1.0)

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    var capsule := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 11.0
    shape.height = 58.0
    capsule.shape = shape
    capsule.position = Vector2(0.0, -36.0)
    add_child(capsule)
    var additive := CanvasItemMaterial.new()
    additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
    material = additive

func _physics_process(delta: float) -> void:
    var horizontal: float = Input.get_axis("move_left", "move_right")
    if absf(touch_horizontal) > 0.05:
        horizontal = touch_horizontal
    elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        horizontal = -1.0
    elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        horizontal = 1.0

    if absf(horizontal) > 0.05:
        facing = signf(horizontal)

    var control_factor: float = air_control if not is_on_floor() else 1.0
    if dash_time > 0.0:
        dash_time = maxf(0.0, dash_time - delta)
        velocity.x = facing * dash_speed
        velocity.y = minf(velocity.y, 80.0)
    else:
        velocity.x = move_toward(velocity.x, horizontal * run_speed, acceleration * control_factor * delta)

    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        if velocity.y > 0.0:
            velocity.y = 0.0
        if Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_SPACE) and not was_on_floor:
            velocity.y = jump_velocity

    if (Input.is_action_just_pressed("dash") or Input.is_key_pressed(KEY_SHIFT)) and dash_cooldown <= 0.0:
        _start_dash()

    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    var grounded_before_move: bool = is_on_floor()
    move_and_slide()
    if not grounded_before_move and is_on_floor():
        landing_flash = 0.16
        landed_impact.emit(clampf(absf(velocity.y) / 800.0, 0.25, 1.0))
    landing_flash = maxf(0.0, landing_flash - delta)
    if absf(velocity.x) > 30.0 and is_on_floor():
        gait_time += delta * clampf(absf(velocity.x) / run_speed, 0.4, 1.8) * 10.0
    else:
        gait_time += delta * 1.8
    was_on_floor = is_on_floor()
    queue_redraw()

func jump_from_touch() -> void:
    if is_on_floor():
        velocity.y = jump_velocity

func dash_from_touch() -> void:
    if dash_cooldown <= 0.0:
        _start_dash()

func _start_dash() -> void:
    dash_time = dash_duration
    dash_cooldown = 0.52
    velocity.x = facing * dash_speed

func _draw() -> void:
    var speed_ratio: float = clampf(absf(velocity.x) / run_speed, 0.0, 1.4)
    var airborne: bool = not is_on_floor()
    var dash_factor: float = 1.0 if dash_time > 0.0 else 0.0
    var bob: float = 0.0 if airborne else sin(gait_time * 2.0) * 2.2 * speed_ratio
    var lean: float = clampf(velocity.x / run_speed, -1.0, 1.0) * 5.0
    var hip := Vector2(lean * 0.45, -37.0 + bob)
    var chest := Vector2(lean, -55.0 + bob)
    var head := Vector2(lean + facing * 2.0, -72.0 + bob)
    var shoulder_l := chest + Vector2(-10.0, 1.0)
    var shoulder_r := chest + Vector2(10.0, 1.0)

    var stride: float = sin(gait_time) * 17.0 * speed_ratio
    var lift: float = absf(cos(gait_time)) * 5.0 * speed_ratio
    var knee_l := hip + Vector2(-8.0 + stride * 0.40, 17.0 - lift)
    var knee_r := hip + Vector2(8.0 - stride * 0.40, 17.0 - lift)
    var foot_l := knee_l + Vector2(-stride * 0.78, 17.0 + lift)
    var foot_r := knee_r + Vector2(stride * 0.78, 17.0 + lift)
    if airborne:
        knee_l = hip + Vector2(-13.0, 12.0)
        knee_r = hip + Vector2(12.0, 9.0)
        foot_l = knee_l + Vector2(-7.0 * facing, 10.0)
        foot_r = knee_r + Vector2(12.0 * facing, 7.0)
    if dash_factor > 0.0:
        chest.x -= facing * 7.0
        head.x -= facing * 9.0
        foot_l.x -= facing * 12.0
        foot_r.x -= facing * 12.0

    var core_color: Color = Color(0.05, 0.62, 1.0, 1.0) if dash_factor > 0.0 else CYAN
    var core_width: float = 4.2 if dash_factor > 0.0 else 3.2
    if dash_factor > 0.0:
        for i in range(4):
            var trail_offset := Vector2(-facing * float(i + 1) * 10.0, float(i % 2) * 3.0)
            _neon_line(chest + trail_offset, hip + trail_offset, BLUE, 8.0 - float(i), 0.12)
            _neon_line(chest + trail_offset, hip + trail_offset, CYAN, 2.0, 0.28)

    _limb(hip, knee_l, foot_l, core_color, core_width)
    _limb(hip, knee_r, foot_r, core_color, core_width)
    _neon_line(shoulder_l, shoulder_l + Vector2(-7.0 - stride * 0.35, 12.0 + sin(gait_time + PI) * 5.0), BLUE, 9.0, 0.16)
    _neon_line(shoulder_r, shoulder_r + Vector2(7.0 + stride * 0.35, 12.0 + sin(gait_time) * 5.0), BLUE, 9.0, 0.16)
    var elbow_l := shoulder_l + Vector2(-7.0 - stride * 0.35, 12.0 + sin(gait_time + PI) * 5.0)
    var elbow_r := shoulder_r + Vector2(7.0 + stride * 0.35, 12.0 + sin(gait_time) * 5.0)
    var hand_l := elbow_l + Vector2(-4.0 + stride * 0.25, 9.0)
    var hand_r := elbow_r + Vector2(4.0 - stride * 0.25, 9.0)
    if airborne:
        elbow_l = shoulder_l + Vector2(-15.0, 7.0)
        elbow_r = shoulder_r + Vector2(13.0, 2.0)
        hand_l = elbow_l + Vector2(-5.0, -4.0)
        hand_r = elbow_r + Vector2(7.0, -6.0)
    _neon_line(shoulder_l, elbow_l, core_color, core_width, 0.95)
    _neon_line(elbow_l, hand_l, core_color, core_width - 0.6, 0.95)
    _neon_line(shoulder_r, elbow_r, core_color, core_width, 0.95)
    _neon_line(elbow_r, hand_r, core_color, core_width - 0.6, 0.95)
    _neon_line(chest, hip, BLUE, 12.0, 0.22)
    _neon_line(chest, hip, core_color, core_width + 1.0, 0.95)

    draw_circle(chest, 5.5, Color(0.05, 0.45, 1.0, 0.28))
    draw_circle(chest, 3.0, Color(0.2, 0.95, 1.0, 0.95))
    draw_circle(chest, 1.2, WHITE)
    draw_arc(head, 9.0, 0.0, TAU, 36, Color(0.05, 0.35, 1.0, 0.35), 8.0, true)
    draw_arc(head, 9.0, 0.0, TAU, 36, core_color, 3.0, true)
    draw_arc(head, 9.0, -0.35, PI + 0.7, 20, WHITE, 1.2, true)
    _neon_line(head + Vector2(-5.0, 1.0), head + Vector2(5.0, 1.0), WHITE, 2.0, 0.95)
    _neon_line(head + Vector2(facing * 2.0, -2.0), head + Vector2(facing * 6.0, -2.0), CYAN, 1.8, 1.0)
    for joint in [shoulder_l, shoulder_r, elbow_l, elbow_r, hip, knee_l, knee_r]:
        draw_circle(joint, 2.6, Color(0.25, 0.98, 1.0, 0.92))
    if landing_flash > 0.0:
        var flash_alpha: float = landing_flash / 0.16
        draw_arc(Vector2(0.0, -2.0), 18.0 + (1.0 - flash_alpha) * 30.0, 0.0, TAU, 40, Color(0.1, 0.9, 1.0, flash_alpha * 0.65), 2.0, true)

func _limb(a: Vector2, b: Vector2, foot: Vector2, tint: Color, width: float) -> void:
    _neon_line(a, b, BLUE, width + 7.0, 0.16)
    _neon_line(b, foot, BLUE, width + 6.0, 0.16)
    _neon_line(a, b, tint, width, 0.95)
    _neon_line(b, foot, tint, width - 0.5, 0.95)
    _neon_line(b, foot, WHITE, 1.1, 0.72)
    _neon_line(foot, foot + Vector2(7.0 * facing, 0.0), tint, 2.4, 0.95)

func _neon_line(a: Vector2, b: Vector2, tint: Color, width: float, alpha: float) -> void:
    draw_line(a, b, Color(tint.r, tint.g, tint.b, tint.a * alpha), width, true)
