extends Node2D
## Procedural pixel-art dungeon art prototype.
## All shapes are drawn at integer-like coordinates so the scene works without external assets.

const TILE := 32
const ROOM := Rect2i(80, 64, 800, 416)

var hero := Vector2(420, 270)
var hero_facing := 1.0
var hero_hp := 86
var hero_level := 3
var attack_timer := 0.0
var hit_flash := 0.0
var time_passed := 0.0
var enemies: Array[Dictionary] = [
	{"pos": Vector2(315, 245), "kind": 0, "hp": 3, "phase": 0.2},
	{"pos": Vector2(610, 300), "kind": 1, "hp": 2, "phase": 1.7},
	{"pos": Vector2(535, 170), "kind": 2, "hp": 4, "phase": 2.8}
]
var loot := Vector2(480, 360)
var chest_open := false
var gold := 12

func _process(delta: float) -> void:
	time_passed += delta
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction.length_squared() > 0.0:
		hero += direction.normalized() * 145.0 * delta
		if absf(direction.x) > 0.01:
			hero_facing = signf(direction.x)
	hero.x = clampf(hero.x, ROOM.position.x + 35, ROOM.end.x - 35)
	hero.y = clampf(hero.y, ROOM.position.y + 42, ROOM.end.y - 34)
	for enemy in enemies:
		var p: Vector2 = enemy["pos"]
		var to_hero := hero - p
		if to_hero.length() > 30.0 and to_hero.length() < 230.0:
			p += to_hero.normalized() * 22.0 * delta
			enemy["pos"] = p
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		attack_timer = 0.22
		var defeated: Array[int] = []
		for i in range(enemies.size()):
			var p: Vector2 = enemies[i]["pos"]
			if p.distance_to(hero + Vector2(hero_facing * 25.0, 0.0)) < 65.0:
				enemies[i]["hp"] = int(enemies[i]["hp"]) - 1
				if int(enemies[i]["hp"]) <= 0:
					defeated.append(i)
					gold += 3
		for i in range(defeated.size() - 1, -1, -1):
			enemies.remove_at(defeated[i])
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if hero.distance_to(Vector2(720, 145)) < 90.0:
			chest_open = true
			gold += 8

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#090c12"))
	_draw_floor()
	_draw_walls()
	_draw_props()
	_draw_loot()
	for enemy in enemies:
		_draw_enemy(enemy)
	_draw_hero()
	_draw_hud()
	_draw_vignette()

func _draw_floor() -> void:
	for y in range(ROOM.position.y, ROOM.end.y, TILE):
		for x in range(ROOM.position.x, ROOM.end.x, TILE):
			var tx := int(x / TILE)
			var ty := int(y / TILE)
			var base := Color("#252b35") if (tx + ty) % 2 == 0 else Color("#202630")
			draw_rect(Rect2(x, y, TILE, TILE), base)
			draw_rect(Rect2(x + 2, y + 2, TILE - 4, TILE - 4), Color("#29313c"))
			draw_line(Vector2(x + 4, y + 5), Vector2(x + 13, y + 5), Color("#37404b"), 1.0)
			if (tx * 7 + ty * 13) % 9 == 0:
				draw_rect(Rect2(x + 21, y + 20, 3, 2), Color("#111820"))
			if (tx * 3 + ty * 5) % 17 == 0:
				draw_rect(Rect2(x + 7, y + 23, 2, 2), Color("#58616a"))

func _draw_walls() -> void:
	for x in range(ROOM.position.x - TILE, ROOM.end.x + TILE, TILE):
		_draw_stone(Vector2(x, ROOM.position.y - TILE), true)
		_draw_stone(Vector2(x, ROOM.end.y), true)
	for y in range(ROOM.position.y, ROOM.end.y, TILE):
		_draw_stone(Vector2(ROOM.position.x - TILE, y), true)
		_draw_stone(Vector2(ROOM.end.x, y), true)
	# Deep side alcoves add a readable dungeon silhouette.
	for i in range(4):
		_draw_stone(Vector2(ROOM.position.x + 90 + i * TILE, ROOM.position.y + 65), false)
		_draw_stone(Vector2(ROOM.end.x - 160 + i * TILE, ROOM.end.y - 100), false)

func _draw_stone(p: Vector2, raised: bool) -> void:
	var shade := Color("#394453") if raised else Color("#343c49")
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(30, 30)), Color("#111720"))
	draw_rect(Rect2(p + Vector2(2, 2), Vector2(28, 27)), shade)
	draw_rect(Rect2(p + Vector2(4, 4), Vector2(22, 3)), Color("#536071"))
	draw_rect(Rect2(p + Vector2(4, 8), Vector2(3, 14)), Color("#414c5b"))
	draw_rect(Rect2(p + Vector2(8, 22), Vector2(17, 3)), Color("#252d38"))
	draw_rect(Rect2(p + Vector2(24, 11), Vector2(3, 8)), Color("#2a323d"))
	draw_rect(Rect2(p + Vector2(12, 13), Vector2(5, 2)), Color("#465363"))

func _draw_props() -> void:
	# Wall torches with animated amber light.
	for torch in [Vector2(112, 180), Vector2(848, 180), Vector2(112, 390), Vector2(848, 390)]:
		var pulse := 0.75 + 0.25 * sin(time_passed * 5.0 + torch.y)
		draw_circle(torch, 32.0 * pulse, Color(1.0, 0.48, 0.12, 0.045))
		draw_circle(torch, 19.0 * pulse, Color(1.0, 0.58, 0.18, 0.07))
		draw_rect(Rect2(torch.x - 3, torch.y - 7, 6, 19), Color("#68432d"))
		draw_rect(Rect2(torch.x - 3, torch.y - 13, 6, 9), Color("#ff9b36"))
		draw_rect(Rect2(torch.x - 1, torch.y - 17, 3, 7), Color("#ffe6a0"))
	# Mossy broken masonry.
	for rock in [Vector2(165, 315), Vector2(795, 235), Vector2(230, 420)]:
		draw_rect(Rect2(rock.x, rock.y, 24, 13), Color("#4b5b52"))
		draw_rect(Rect2(rock.x + 4, rock.y - 5, 17, 11), Color("#657367"))
		draw_rect(Rect2(rock.x + 4, rock.y - 5, 8, 3), Color("#84947a"))
		draw_rect(Rect2(rock.x + 2, rock.y + 9, 22, 4), Color("#202a2b"))
	# Treasure chest.
	var chest := Vector2(720, 145)
	draw_rect(Rect2(chest.x - 2, chest.y + 16, 42, 5), Color("#11151b"))
	draw_rect(Rect2(chest.x, chest.y, 38, 20), Color("#8a4d25"))
	draw_rect(Rect2(chest.x + 2, chest.y + 3, 34, 14), Color("#b66b2e"))
	draw_rect(Rect2(chest.x, chest.y + 7, 38, 4), Color("#e0a344"))
	draw_rect(Rect2(chest.x + 16, chest.y + 7, 6, 8), Color("#f3d477"))
	draw_rect(Rect2(chest.x + 18, chest.y + 9, 2, 3), Color("#563923"))
	if chest_open:
		draw_rect(Rect2(chest.x - 1, chest.y - 8, 40, 8), Color("#bd7b35"))
		draw_rect(Rect2(chest.x + 3, chest.y - 6, 32, 4), Color("#f1c96a"))
	else:
		draw_rect(Rect2(chest.x + 2, chest.y - 3, 34, 7), Color("#70401f"))

func _draw_loot() -> void:
	var bob := sin(time_passed * 4.0) * 3.0
	draw_circle(loot + Vector2(0, 4 + bob), 13, Color(0.2, 0.9, 1.0, 0.08))
	draw_rect(Rect2(loot.x - 5, loot.y - 7 + bob, 10, 12), Color("#e6a52d"))
	draw_rect(Rect2(loot.x - 3, loot.y - 9 + bob, 6, 3), Color("#ffe18a"))
	draw_rect(Rect2(loot.x - 2, loot.y - 4 + bob, 4, 5), Color("#fff0b1"))

func _draw_enemy(enemy: Dictionary) -> void:
	var p: Vector2 = enemy["pos"]
	var bob := sin(time_passed * 4.0 + float(enemy["phase"])) * 2.0
	var y := p.y + bob
	_draw_ellipse(p + Vector2(0, 14), Vector2(17, 6), Color(0, 0, 0, 0.42))
	match int(enemy["kind"]):
		0: # Skeleton
			draw_rect(Rect2(p.x - 9, y - 13, 18, 21), Color("#665e5a"))
			draw_rect(Rect2(p.x - 8, y - 23, 16, 13), Color("#c9c6b6"))
			draw_rect(Rect2(p.x - 5, y - 19, 3, 3), Color("#ff535d"))
			draw_rect(Rect2(p.x + 2, y - 19, 3, 3), Color("#ff535d"))
			draw_rect(Rect2(p.x - 7, y - 2, 5, 12), Color("#b7b4a5"))
			draw_rect(Rect2(p.x + 3, y - 2, 5, 12), Color("#b7b4a5"))
			draw_rect(Rect2(p.x - 15, y - 7, 5, 15), Color("#a7a292"))
		1: # Slime
			draw_rect(Rect2(p.x - 15, y - 9, 30, 16), Color("#477e69"))
			draw_rect(Rect2(p.x - 10, y - 14, 20, 7), Color("#62b38b"))
			draw_rect(Rect2(p.x - 8, y - 4, 4, 4), Color("#e4f3cb"))
			draw_rect(Rect2(p.x + 4, y - 4, 4, 4), Color("#e4f3cb"))
			draw_rect(Rect2(p.x - 7, y - 3, 2, 3), Color("#203d39"))
			draw_rect(Rect2(p.x + 5, y - 3, 2, 3), Color("#203d39"))
		_: # Floating wisp
			draw_circle(p, 13, Color(0.15, 0.82, 1.0, 0.12))
			draw_rect(Rect2(p.x - 9, y - 11, 18, 18), Color("#3b9fb9"))
			draw_rect(Rect2(p.x - 6, y - 15, 12, 6), Color("#83f0ef"))
			draw_rect(Rect2(p.x - 5, y - 5, 3, 4), Color("#e1ffff"))
			draw_rect(Rect2(p.x + 3, y - 5, 3, 4), Color("#e1ffff"))
	_draw_hp_bar(p + Vector2(-13, -32), int(enemy["hp"]), 4)

func _draw_hero() -> void:
	var p := hero
	var bob := 0.0 if attack_timer > 0.0 else sin(time_passed * 9.0) * 1.5
	_draw_ellipse(p + Vector2(0, 15), Vector2(15, 5), Color(0, 0, 0, 0.5))
	# Boots and legs
	draw_rect(Rect2(p.x - 8, p.y + 3 + bob, 6, 10), Color("#3b3544"))
	draw_rect(Rect2(p.x + 2, p.y + 3 - bob, 6, 10), Color("#3b3544"))
	draw_rect(Rect2(p.x - 10, p.y + 10 + bob, 9, 4), Color("#d19a52"))
	draw_rect(Rect2(p.x + 1, p.y + 10 - bob, 9, 4), Color("#d19a52"))
	# Tunic, belt and arms
	draw_rect(Rect2(p.x - 10, p.y - 12, 20, 19), Color("#8c3f32"))
	draw_rect(Rect2(p.x - 8, p.y - 10, 16, 13), Color("#d95d3e"))
	draw_rect(Rect2(p.x - 10, p.y + 2, 20, 4), Color("#e7b85b"))
	draw_rect(Rect2(p.x - 13, p.y - 9, 5, 13), Color("#e7b85b"))
	draw_rect(Rect2(p.x + 8, p.y - 9, 5, 13), Color("#e7b85b"))
	# Head, hair and face
	draw_rect(Rect2(p.x - 8, p.y - 28, 16, 16), Color("#e6b477"))
	draw_rect(Rect2(p.x - 9, p.y - 30, 18, 7), Color("#873d25"))
	draw_rect(Rect2(p.x - 8, p.y - 27, 5, 4), Color("#873d25"))
	draw_rect(Rect2(p.x + 2, p.y - 22, 3, 3), Color("#342d30"))
	# Sword and swing
	var sword_start := p + Vector2(hero_facing * 10.0, -5)
	var sword_end := p + Vector2(hero_facing * (27.0 if attack_timer <= 0.0 else 43.0), -15 if attack_timer > 0.0 else -24)
	draw_line(sword_start, sword_end, Color("#e0e9ed"), 4.0)
	draw_line(sword_start, sword_start + Vector2(-hero_facing * 4.0, 7.0), Color("#e4b65f"), 3.0)
	draw_rect(Rect2(sword_end - Vector2(2, 2), Vector2(4, 4)), Color("#ffffff"))
	if attack_timer > 0.0:
		draw_arc(p + Vector2(hero_facing * 12, -7), 28.0, -1.1 if hero_facing > 0 else 2.1, 0.6 if hero_facing > 0 else 3.8, 12, Color("#fff0ad"), 3.0)

func _draw_hud() -> void:
	draw_rect(Rect2(18, 16, 244, 82), Color(0.035, 0.045, 0.065, 0.92))
	draw_rect(Rect2(18, 16, 244, 82), Color("#49515e"), false, 1.0)
	_text(Vector2(30, 36), "CRYPT // FLOOR 01", Color("#d9e1ec"), 14)
	_text(Vector2(30, 55), "HERO  •  LV %02d" % hero_level, Color("#e5b967"), 12)
	draw_rect(Rect2(30, 64, 210, 10), Color("#171b23"))
	draw_rect(Rect2(32, 66, 206 * float(hero_hp) / 100.0, 6), Color("#d64c51"))
	_text(Vector2(30, 91), "HP %d / 100" % hero_hp, Color("#f0c6c4"), 10)
	draw_rect(Rect2(696, 16, 246, 82), Color(0.035, 0.045, 0.065, 0.92))
	draw_rect(Rect2(696, 16, 246, 82), Color("#49515e"), false, 1.0)
	_text(Vector2(710, 37), "INVENTORY", Color("#d9e1ec"), 12)
	_text(Vector2(710, 59), "GOLD  %03d" % gold, Color("#f0c45f"), 15)
	_text(Vector2(710, 81), "%02d ENEMIES REMAIN" % enemies.size(), Color("#9cc9d5"), 10)
	draw_rect(Rect2(18, 497, 540, 27), Color(0.035, 0.045, 0.065, 0.88))
	_text(Vector2(29, 515), "MOVE  WASD / ARROWS     ATTACK  SPACE     OPEN CHEST  E", Color("#b8c4d4"), 11)
	_text(Vector2(730, 515), "ART LAB  •  PROTOTYPE 01", Color("#71849a"), 10)

func _draw_vignette() -> void:
	draw_rect(Rect2(0, 0, 960, 8), Color(0, 0, 0, 0.28))
	draw_rect(Rect2(0, 532, 960, 8), Color(0, 0, 0, 0.42))
	draw_rect(Rect2(0, 0, 8, 540), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(952, 0, 8, 540), Color(0, 0, 0, 0.3))

func _draw_hp_bar(p: Vector2, hp: int, maximum: int) -> void:
	draw_rect(Rect2(p, Vector2(26, 4)), Color("#151820"))
	draw_rect(Rect2(p + Vector2(1, 1), Vector2(24.0 * float(hp) / float(maximum), 2)), Color("#d9575b"))

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var next_angle := TAU * float(i + 1) / 12.0
		draw_colored_polygon(PackedVector2Array([
			center,
			center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y),
			center + Vector2(cos(next_angle) * radius.x, sin(next_angle) * radius.y)
		]), color)

func _text(position: Vector2, value: String, color: Color, size: int) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
