extends Node2D
## NULL//ENTITY — playable glyph-survivor prototype.
## All player/enemy visuals are procedurally drawn from glyphs and geometry.

const GLYPHS: String = "01{}[]<>/\\|+=-*.:;#"
const BG := Color(0.012, 0.016, 0.027)
const WHITE := Color(0.82, 0.92, 1.0)
const CYAN := Color(0.20, 0.84, 1.0)
const PURPLE := Color(0.70, 0.36, 1.0)
const RED := Color(1.0, 0.28, 0.43)
const GOLD := Color(1.0, 0.68, 0.22)

var player_pos := Vector2(380.0, 430.0)
var player_velocity := Vector2.ZERO
var player_hp: float = 100.0
var player_xp: int = 0
var level: int = 1
var kills: int = 0
var elapsed: float = 0.0
var spawn_clock: float = 0.0
var attack_clock: float = 0.0
var invuln_clock: float = 0.0
var flash_clock: float = 0.0
var game_over: bool = false
var enemies: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var bolts: Array[Dictionary] = []
var chain_lines: Array[Dictionary] = []
var upgrades: Array[String] = ["VOID PULSE", "CHAIN LIGHTNING", "GLYPH FRACTURE"]
var active_upgrade: int = 0
var touch_move: float = 0.0
var touch_attack: bool = false

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	get_window().title = "NULL//ENTITY — Survivor Prototype"
	for i in range(7):
		_spawn_enemy(true)
	queue_redraw()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	if Input.is_key_pressed(KEY_R) and game_over:
		_restart()
	if game_over:
		_update_particles(delta)
		queue_redraw()
		return
	elapsed += delta
	spawn_clock += delta
	attack_clock += delta
	invuln_clock = maxf(0.0, invuln_clock - delta)
	flash_clock = maxf(0.0, flash_clock - delta)
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if direction.length() > 1.0:
		direction = direction.normalized()
	player_velocity = player_velocity.lerp(direction * 260.0, minf(1.0, delta * 9.0))
	player_pos += player_velocity * delta
	var size := get_viewport_rect().size
	player_pos.x = clampf(player_pos.x, 70.0, size.x - 70.0)
	player_pos.y = clampf(player_pos.y, 155.0, size.y - 70.0)
	if spawn_clock > maxf(0.34, 1.25 - elapsed * 0.006):
		spawn_clock = 0.0
		_spawn_enemy(false)
	_update_enemies(delta)
	if attack_clock >= maxf(0.23, 0.82 - float(level - 1) * 0.07):
		attack_clock = 0.0
		_auto_attack()
	_update_bolts(delta)
	_update_chains(delta)
	_update_particles(delta)
	queue_redraw()

func _spawn_enemy(initial: bool) -> void:
	var size := get_viewport_rect().size
	var edge: int = randi() % 4
	var pos := Vector2.ZERO
	match edge:
		0: pos = Vector2(randf_range(40, size.x - 40), 140)
		1: pos = Vector2(size.x - 30, randf_range(160, size.y - 30))
		2: pos = Vector2(randf_range(40, size.x - 40), size.y - 28)
		_: pos = Vector2(30, randf_range(160, size.y - 30))
	var roll: int = randi() % 100
	var kind: String = "DRONE"
	var hp: float = 2.0
	var speed: float = randf_range(45.0, 72.0)
	if roll > 82:
		kind = "WISP"
		hp = 3.0
		speed *= 0.8
	elif roll > 58:
		kind = "SHARD"
		hp = 1.0
		speed *= 1.65
	elif roll > 45 and elapsed > 18.0:
		kind = "CUBOID"
		hp = 7.0
		speed *= 0.55
	if initial:
		speed *= 0.8
	enemies.append({"pos": pos, "hp": hp, "max_hp": hp, "speed": speed, "kind": kind, "phase": randf() * TAU, "hit": 0.0, "radius": 12.0 if kind != "CUBOID" else 19.0})

func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		var pos: Vector2 = e["pos"]
		var to_player: Vector2 = player_pos - pos
		var dist: float = maxf(0.01, to_player.length())
		var speed: float = float(e["speed"])
		var motion: Vector2 = to_player / dist
		if e["kind"] == "WISP":
			motion = (to_player / dist + Vector2(0, sin(elapsed * 3.0 + float(e["phase"])) * 0.55)).normalized()
		elif e["kind"] == "SHARD":
			motion = (to_player / dist + Vector2(0, sin(elapsed * 7.0 + float(e["phase"])) * 0.25)).normalized()
		pos += motion * speed * delta
		e["pos"] = pos
		e["phase"] = float(e["phase"]) + delta
		e["hit"] = maxf(0.0, float(e["hit"]) - delta)
		if dist < float(e["radius"]) + 18.0 and invuln_clock <= 0.0:
			player_hp -= 12.0 if e["kind"] != "CUBOID" else 20.0
			invuln_clock = 0.65
			_emit_burst(player_pos, RED, 12)
			if player_hp <= 0.0:
				player_hp = 0.0
				game_over = true
		enemies[i] = e

func _auto_attack() -> void:
	if enemies.is_empty():
		return
	var candidates: Array[int] = []
	for i in range(enemies.size()):
		candidates.append(i)
	candidates.sort_custom(func(a: int, b: int) -> bool:
		return player_pos.distance_squared_to(enemies[a]["pos"]) < player_pos.distance_squared_to(enemies[b]["pos"])
	)
	var target: Vector2 = enemies[candidates[0]]["pos"]
	bolts.append({"from": player_pos, "to": target, "pos": player_pos, "life": 0.0, "target_index": candidates[0]})

func _update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[i]
		b["life"] = float(b["life"]) + delta
		var start: Vector2 = b["from"]
		var target: Vector2 = b["to"]
		var pos: Vector2 = start.lerp(target, minf(1.0, float(b["life"]) * 7.5))
		b["pos"] = pos
		if float(b["life"]) > 0.16 or pos.distance_to(target) < 12.0:
			var hit_index: int = -1
			var best_dist: float = 40.0
			for j in range(enemies.size()):
				var d: float = target.distance_to(enemies[j]["pos"])
				if d < best_dist:
					best_dist = d
					hit_index = j
			if hit_index >= 0:
				_damage_enemy(hit_index, 1.0 + float(level - 1) * 0.35)
			bolts.remove_at(i)
		else:
			bolts[i] = b

func _damage_enemy(index: int, amount: float) -> void:
	if index < 0 or index >= enemies.size():
		return
	var e: Dictionary = enemies[index]
	e["hp"] = float(e["hp"]) - amount
	e["hit"] = 0.12
	var pos: Vector2 = e["pos"]
	_emit_burst(pos, CYAN, 4)
	if float(e["hp"]) <= 0.0:
		kills += 1
		player_xp += 1
		_emit_burst(pos, WHITE, 14)
		_emit_burst(pos, PURPLE, 7)
		if player_xp >= level * 7:
			player_xp = 0
			level += 1
			player_hp = minf(100.0, player_hp + 12.0)
			active_upgrade = (active_upgrade + 1) % upgrades.size()
			_emit_burst(player_pos, GOLD, 30)
		# Chain lightning jumps to up to two nearby enemies.
		var chained: int = 0
		for j in range(enemies.size()):
			if j == index or chained >= 2:
				continue
			if pos.distance_to(enemies[j]["pos"]) < 150.0:
				chain_lines.append({"a": pos, "b": enemies[j]["pos"], "life": 0.22})
				_emit_burst(enemies[j]["pos"], CYAN, 8)
				var next_enemy: Dictionary = enemies[j]
				next_enemy["hp"] = float(next_enemy["hp"]) - 1.0
				enemies[j] = next_enemy
				chained += 1
		enemies.remove_at(index)
	else:
		enemies[index] = e

func _update_chains(delta: float) -> void:
	for i in range(chain_lines.size() - 1, -1, -1):
		var line: Dictionary = chain_lines[i]
		line["life"] = float(line["life"]) - delta
		if float(line["life"]) <= 0.0:
			chain_lines.remove_at(i)
		else:
			chain_lines[i] = line

func _emit_burst(pos: Vector2, color: Color, amount: int) -> void:
	var budget: int = mini(amount, 32)
	for i in range(budget):
		var angle: float = randf() * TAU
		var speed: float = randf_range(25.0, 180.0)
		particles.append({"pos": pos, "vel": Vector2.RIGHT.rotated(angle) * speed, "life": randf_range(0.18, 0.65), "max_life": 0.65, "color": color, "glyph": randi() % GLYPHS.length()})
	while particles.size() > 260:
		particles.pop_front()

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["life"] = float(p["life"]) - delta
		var particle_pos: Vector2 = p["pos"]
		var particle_vel: Vector2 = p["vel"]
		p["pos"] = particle_pos + particle_vel * delta
		p["vel"] = particle_vel * 0.92
		if float(p["life"]) <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = p

func _restart() -> void:
	player_pos = Vector2(380.0, 430.0)
	player_hp = 100.0
	player_xp = 0
	level = 1
	kills = 0
	elapsed = 0.0
	spawn_clock = 0.0
	attack_clock = 0.0
	invuln_clock = 0.0
	game_over = false
	enemies.clear()
	particles.clear()
	bolts.clear()
	chain_lines.clear()
	for i in range(7):
		_spawn_enemy(true)

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), BG, true)
	# Grid and glyph floor.
	for x in range(0, int(size.x), 48):
		draw_line(Vector2(x, 112), Vector2(x, size.y - 34), Color(0.18, 0.29, 0.39, 0.12), 1.0)
	for y in range(120, int(size.y), 48):
		draw_line(Vector2(28, y), Vector2(size.x - 28, y), Color(0.18, 0.29, 0.39, 0.12), 1.0)
	for x in range(18, int(size.x), 13):
		var idx: int = int(x / 13) % GLYPHS.length()
		draw_string(ThemeDB.fallback_font, Vector2(x, size.y - 16), GLYPHS.substr(idx, 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.23, 0.41, 0.52, 0.55))
	_draw_hud(size)
	for e in enemies:
		_draw_enemy(e)
	for b in bolts:
		var p: Vector2 = b["pos"]
		_draw_glyph(p, int(elapsed * 30.0), CYAN, 17)
		_draw_line_glow(Vector2(b["from"]), p, CYAN, 1.3)
	for c in chain_lines:
		_draw_chain(Vector2(c["a"]), Vector2(c["b"]), CYAN)
	_draw_player()
	_draw_particles()
	if game_over:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.72), true)
		_draw_center_text(size, "ENTITY FRACTURED", "PRESS R TO REFORM")

func _draw_hud(size: Vector2) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(32, 38), "NULL//ENTITY", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(34, 60), "GLYPH SURVIVOR  /  PROTOTYPE 01", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.42, 0.64, 0.76))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, 35), "WAVE %02d" % (1 + int(elapsed / 25.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, 57), "KILLS  %03d" % kills, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 220, 78), "LEVEL  %02d" % level, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, PURPLE)
	draw_rect(Rect2(32, 78, 180, 7), Color(0.18, 0.24, 0.30), true)
	draw_rect(Rect2(32, 78, 180.0 * player_hp / 100.0, 7), RED, true)
	draw_string(ThemeDB.fallback_font, Vector2(32, 105), "HP %03d" % int(player_hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, WHITE)
	draw_rect(Rect2(32, size.y - 42, 180, 5), Color(0.18, 0.24, 0.30), true)
	draw_rect(Rect2(32, size.y - 42, 180.0 * float(player_xp) / float(maxi(1, level * 7)), 5), CYAN, true)
	draw_string(ThemeDB.fallback_font, Vector2(230, size.y - 37), "EVOLUTION %d / %d" % [player_xp, level * 7], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.48, 0.72, 0.84))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 300, size.y - 38), "WASD / ARROWS  MOVE   •   AUTO ATTACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.52, 0.64, 0.72))

func _draw_player() -> void:
	var pulse: float = 1.0 + sin(elapsed * 5.0) * 0.10
	for i in range(3):
		var radius: float = (19.0 + float(i) * 9.0) * pulse
		draw_arc(player_pos, radius, elapsed * (0.6 + i * 0.25), elapsed * (0.6 + i * 0.25) + PI * 1.45, 32, Color(CYAN.r, CYAN.g, CYAN.b, 0.30 - i * 0.06), 1.3, true)
	for i in range(12):
		var angle: float = float(i) * TAU / 12.0 + elapsed * 1.2
		var p: Vector2 = player_pos + Vector2.RIGHT.rotated(angle) * (26.0 + sin(elapsed * 3.0 + i) * 3.0)
		_draw_glyph(p, i * 3 + int(elapsed * 4.0), WHITE, 10)
	draw_circle(player_pos, 11.0 * pulse, Color(CYAN.r, CYAN.g, CYAN.b, 0.22))
	draw_arc(player_pos, 12.0 * pulse, 0, TAU, 24, WHITE, 2.0, true)
	_draw_glyph(player_pos + Vector2(-5, 5), int(elapsed * 10.0), WHITE, 14)
	_draw_glyph(player_pos + Vector2(5, -3), int(elapsed * 7.0) + 4, CYAN, 12)

func _draw_enemy(e: Dictionary) -> void:
	var pos: Vector2 = e["pos"]
	var kind: String = e["kind"]
	var radius: float = float(e["radius"])
	var color: Color = WHITE
	if kind == "WISP":
		color = PURPLE
	elif kind == "SHARD":
		color = RED
	elif kind == "CUBOID":
		color = GOLD
	var rotation: float = float(e["phase"]) * (1.1 if kind != "CUBOID" else 0.3)
	if kind == "DRONE":
		var pts := PackedVector2Array()
		for i in range(3):
			pts.append(pos + Vector2.UP.rotated(rotation + float(i) * TAU / 3.0) * radius)
		for i in range(3):
			draw_line(pts[i], pts[(i + 1) % 3], color, 1.7, true)
		for p in pts:
			_draw_glyph(p, int(p.x + p.y), color, 9)
		_draw_glyph(pos, 2, color, 12)
	elif kind == "WISP":
		draw_arc(pos, radius, rotation, rotation + TAU * 0.8, 24, color, 2.0, true)
		draw_arc(pos, radius * 0.55, -rotation, -rotation + TAU * 0.7, 20, WHITE, 1.0, true)
		_draw_glyph(pos, 7, color, 13)
	elif kind == "SHARD":
		var a := pos + Vector2.UP.rotated(rotation) * radius * 1.4
		var b := pos + Vector2.RIGHT.rotated(rotation) * radius * 0.65
		var c := pos + Vector2.DOWN.rotated(rotation) * radius * 1.4
		var d := pos + Vector2.LEFT.rotated(rotation) * radius * 0.65
		draw_line(a, b, color, 2.0, true)
		draw_line(b, c, color, 2.0, true)
		draw_line(c, d, color, 2.0, true)
		draw_line(d, a, color, 2.0, true)
		_draw_glyph(pos, 11, WHITE, 11)
	else:
		var rect := Rect2(pos - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
		draw_rect(rect, Color(color.r, color.g, color.b, 0.10), true)
		draw_rect(rect, color, false, 2.0)
		_draw_glyph(pos + Vector2(-5, 5), 8, color, 13)
		_draw_glyph(pos + Vector2(5, -5), 0, WHITE, 12)
	if float(e["hit"]) > 0.0:
		draw_arc(pos, radius + 6.0, 0, TAU, 24, CYAN, 2.0, true)
	var hp_ratio: float = clampf(float(e["hp"]) / float(e["max_hp"]), 0.0, 1.0)
	if hp_ratio < 1.0:
		draw_line(pos + Vector2(-radius, radius + 7), pos + Vector2(-radius + radius * 2.0 * hp_ratio, radius + 7), color, 2.0, true)

func _draw_particles() -> void:
	for p in particles:
		var life_ratio: float = clampf(float(p["life"]) / float(p["max_life"]), 0.0, 1.0)
		var c: Color = p["color"]
		c.a *= life_ratio
		_draw_glyph(p["pos"], int(p["glyph"]), c, 8.0 * life_ratio + 5.0)

func _draw_glyph(pos: Vector2, index: int, color: Color, font_size: float) -> void:
	var glyph: String = GLYPHS.substr(posmod(index, GLYPHS.length()), 1)
	draw_string(ThemeDB.fallback_font, pos, glyph, HORIZONTAL_ALIGNMENT_CENTER, -1, maxi(8, int(font_size)), color)

func _draw_line_glow(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(a, b, Color(color.r, color.g, color.b, 0.18), width * 5.0, true)
	draw_line(a, b, color, width, true)

func _draw_chain(a: Vector2, b: Vector2, color: Color) -> void:
	var points := PackedVector2Array([a])
	var segments: int = 7
	for i in range(1, segments):
		var t: float = float(i) / float(segments)
		var p: Vector2 = a.lerp(b, t)
		p += Vector2(randf_range(-9, 9), randf_range(-9, 9))
		points.append(p)
	points.append(b)
	for i in range(points.size() - 1):
		_draw_line_glow(points[i], points[i + 1], color, 1.3)

func _draw_center_text(size: Vector2, title: String, subtitle: String) -> void:
	draw_string(ThemeDB.fallback_font, size * 0.5 + Vector2(-140, -12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, WHITE)
	draw_string(ThemeDB.fallback_font, size * 0.5 + Vector2(-100, 24), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, CYAN)
