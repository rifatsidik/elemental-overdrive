extends Node2D
class_name OverdriveEngineLab

const CORE_SCRIPT = preload("res://scripts/core/overdrive_core.gd")
const PERFORMANCE_SCRIPT = preload("res://scripts/performance/performance_director.gd")
const ENERGY_BURST_SCRIPT = preload("res://scripts/visuals/energy_burst.gd")

var core: OverdriveCore
var performance_director: OverdrivePerformanceDirector
var burst_count: int = 0
var _telemetry_timer: float = 0.0

func _ready() -> void:
    core = CORE_SCRIPT.new()
    core.name = "OverdriveCore"
    add_child(core)
    performance_director = PERFORMANCE_SCRIPT.new()
    performance_director.name = "PerformanceDirector"
    add_child(performance_director)
    core.energy_burst_requested.connect(_on_energy_burst_requested)
    _spawn_demo_burst(get_viewport_rect().size * Vector2(0.5, 0.53), 1.0)
    queue_redraw()

func _process(delta: float) -> void:
    _telemetry_timer += delta
    if _telemetry_timer >= 0.12:
        _telemetry_timer = 0.0
        performance_director.set_active_effects(get_child_burst_count())
        queue_redraw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        core.request_energy_burst(event.position, 1.0)
    elif event is InputEventScreenTouch and event.pressed:
        core.request_energy_burst(event.position, 1.0)
    elif event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_0:
                performance_director.set_adaptive(true)
            KEY_1:
                performance_director.set_adaptive(false)
                performance_director.set_quality(OverdrivePerformanceDirector.Quality.LOW)
            KEY_2:
                performance_director.set_adaptive(false)
                performance_director.set_quality(OverdrivePerformanceDirector.Quality.BALANCED)
            KEY_3:
                performance_director.set_adaptive(false)
                performance_director.set_quality(OverdrivePerformanceDirector.Quality.HIGH)
        queue_redraw()

func _spawn_demo_burst(origin: Vector2, strength: float) -> void:
    core.request_energy_burst(origin, strength)

func _on_energy_burst_requested(origin: Vector2, strength: float, seed_value: int) -> void:
    var burst: EnergyBurst = ENERGY_BURST_SCRIPT.new()
    burst.position = origin
    burst.name = "EnergyBurst_%03d" % (burst_count + 1)
    add_child(burst)
    burst.configure(
        strength,
        seed_value,
        performance_director.lightning_branch_budget(),
        performance_director.visual_layer_budget()
    )
    burst_count += 1

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#03040b"))
    for x in range(0, int(size.x) + 1, 48):
        draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.10, 0.32, 0.55, 0.13), 1.0)
    for y in range(0, int(size.y) + 1, 48):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.10, 0.32, 0.55, 0.13), 1.0)

    # Subtle scanlines and corner accents make the lab feel like a VFX console.
    for y in range(108, int(size.y) - 70, 5):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.15, 0.34, 0.52, 0.025), 1.0)
    draw_rect(Rect2(0.0, 0.0, size.x, 92.0), Color(0.012, 0.018, 0.045, 0.97))
    draw_line(Vector2(0.0, 92.0), Vector2(size.x, 92.0), Color(0.0, 0.85, 1.0, 0.42), 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(26.0, 35.0), "OVERDRIVE ENGINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 25, Color("#c7ffff"))
    draw_string(ThemeDB.fallback_font, Vector2(27.0, 61.0), "VFX LAB  /  LIGHTNING • PLASMA • IMPACT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#719abf"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 26.0, 32.0), "QUALITY: " + performance_director.quality_label(), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 16, Color("#ffe18a"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 26.0, 55.0), "FPS: %03d   FRAME: %4.1f ms   FX: %03d" % [int(round(performance_director.fps_average)), performance_director.frame_time_ms, get_child_burst_count()], HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 13, Color("#ff8ab4"))
    draw_string(ThemeDB.fallback_font, Vector2(26.0, size.y - 38.0), "CLICK / TAP: STRIKE     0 AUTO     1 LOW     2 BALANCED     3 HIGH", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("#a5c8e8"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 26.0, size.y - 38.0), "PROCEDURAL VFX SYSTEMS", HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 12, Color("#5d86a9"))

func get_child_burst_count() -> int:
    var count := 0
    for child in get_children():
        if child is Node2D and child.name.begins_with("EnergyBurst_"):
            count += 1
    return count
