extends Node2D
class_name GameRoot

## Main scene coordinator. Keep gameplay systems separated as the project grows.

const PLAYER_SCRIPT := preload("res://scripts/actors/player_controller.gd")
const ENEMY_SCRIPT := preload("res://scripts/actors/enemy_actor.gd")
const FX_SCRIPT := preload("res://scripts/visuals/fx_layer.gd")

var arena_size := Vector2(1600.0, 900.0)
var player: Node2D
var enemies: Array[Node2D] = []
var fx_layer: Node2D
var spawn_timer := 0.0
var elapsed := 0.0
var kills := 0
var wave := 1

func _ready() -> void:
    get_viewport().size_changed.connect(_on_viewport_resized)
    arena_size = get_viewport_rect().size
    fx_layer = Node2D.new()
    fx_layer.name = "FXLayer"
    fx_layer.set_script(FX_SCRIPT)
    add_child(fx_layer)

    player = Node2D.new()
    player.name = "Player"
    player.set_script(PLAYER_SCRIPT)
    add_child(player)
    player.position = arena_size * Vector2(0.5, 0.56)

    for i in range(6):
        _spawn_enemy()
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    spawn_timer -= delta
    if spawn_timer <= 0.0 and _alive_enemy_count() < 18:
        _spawn_enemy()
        spawn_timer = maxf(0.35, 1.15 - float(wave) * 0.04)
    if _alive_enemy_count() == 0:
        wave += 1
        for i in range(mini(5 + wave * 2, 18)):
            _spawn_enemy()
    queue_redraw()

func _spawn_enemy() -> void:
    var enemy := Node2D.new()
    enemy.name = "Enemy"
    enemy.set_script(ENEMY_SCRIPT)
    add_child(enemy)
    var margin := 44.0
    var side := randi() % 4
    match side:
        0: enemy.position = Vector2(randf_range(margin, arena_size.x - margin), 100.0)
        1: enemy.position = Vector2(arena_size.x - margin, randf_range(110.0, arena_size.y - margin))
        2: enemy.position = Vector2(randf_range(margin, arena_size.x - margin), arena_size.y - margin)
        _: enemy.position = Vector2(margin, randf_range(110.0, arena_size.y - margin))
    enemy.set_meta("target", player)

func _alive_enemy_count() -> int:
    var count := 0
    for enemy in enemies:
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
            count += 1
    return count

func _on_viewport_resized() -> void:
    arena_size = get_viewport_rect().size
    queue_redraw()

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#050711"))
    for x in range(0, int(size.x) + 1, 48):
        draw_line(Vector2(x, 72), Vector2(x, size.y), Color(0.12, 0.25, 0.42, 0.22), 1.0)
    for y in range(72, int(size.y) + 1, 48):
        draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.12, 0.25, 0.42, 0.22), 1.0)
    draw_rect(Rect2(0, 0, size.x, 72), Color(0.015, 0.02, 0.06, 0.94))
    draw_string(ThemeDB.fallback_font, Vector2(24, 31), "ELEMENTAL OVERDRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#aafaff"))
    draw_string(ThemeDB.fallback_font, Vector2(24, 54), "FOUNDATION BUILD  //  SURVIVE AND CHAIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#7188b7"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 24, 34), "WAVE %02d" % wave, HORIZONTAL_ALIGNMENT_RIGHT, -1, 18, Color("#ffd34d"))
    draw_string(ThemeDB.fallback_font, Vector2(size.x - 24, 55), "KILLS %04d" % kills, HORIZONTAL_ALIGNMENT_RIGHT, -1, 13, Color("#ff5478"))
