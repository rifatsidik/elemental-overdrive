extends Node2D
class_name OverdriveElementalCombatLab

const ADAPTER_SCRIPT = preload("res://scripts/combat/world_adapter.gd")
const ROUTER_SCRIPT = preload("res://scripts/visuals/element_vfx_router.gd")
const DUMMY_SCRIPT = preload("res://scripts/lab/lab_combat_dummy.gd")
const PERFORMANCE_SCRIPT = preload("res://scripts/performance/performance_director.gd")

var adapter: OverdriveCombatWorldAdapter
var router: OverdriveElementVFXRouter
var performance_director: OverdrivePerformanceDirector
var caster: Node2D
var dummies: Array[OverdriveLabCombatDummy] = []
var selected_element: StringName = &"lightning"
var previous_element: StringName = &""
var _telemetry_timer: float = 0.0
var _last_message: String = "Click a target to test the selected element."

const ABILITY_PROFILES := {
	&"lightning": {
		"ability_id": &"lab_arc_bolt", "element_id": &"lightning",
		"damage": 14.0, "impulse": 140.0, "cooldown": 0.35,
		"chain": true, "chain_range": 280.0, "max_range": 900.0
	},
	&"wind": {
		"ability_id": &"lab_gale_pulse", "element_id": &"wind",
		"damage": 8.0, "impulse": 220.0, "cooldown": 0.25,
		"max_range": 900.0
	},
	&"fire": {
		"ability_id": &"lab_flare", "element_id": &"fire",
		"damage": 12.0, "impulse": 45.0, "cooldown": 0.45,
		"max_range": 900.0,
		"status_parameters": {"damage_per_tick": 3.0, "tick_interval": 0.4}
	},
	&"water": {
		"ability_id": &"lab_pressure_wave", "element_id": &"water",
		"damage": 9.0, "impulse": 160.0, "cooldown": 0.3,
		"max_range": 900.0
	}
}

func _ready() -> void:
	adapter = ADAPTER_SCRIPT.new()
	adapter.name = "CombatWorldAdapter"
	add_child(adapter)
	router = ROUTER_SCRIPT.new()
	router.name = "ElementVFXRouter"
	add_child(router)
	router.bind_adapter(adapter)
	performance_director = PERFORMANCE_SCRIPT.new()
	performance_director.name = "PerformanceDirector"
	add_child(performance_director)
	caster = Node2D.new()
	caster.name = "LabCaster"
	add_child(caster)
	_layout_combatants()
	_update_quality_budgets()
	queue_redraw()

func _layout_combatants() -> void:
	for dummy in dummies:
		if is_instance_valid(dummy):
			dummy.queue_free()
	dummies.clear()
	var size := get_viewport_rect().size
	caster.position = Vector2(120.0, size.y * 0.62)
	var positions := [
		Vector2(size.x * 0.42, size.y * 0.34),
		Vector2(size.x * 0.58, size.y * 0.50),
		Vector2(size.x * 0.75, size.y * 0.32),
		Vector2(size.x * 0.82, size.y * 0.68),
		Vector2(size.x * 0.56, size.y * 0.74)
	]
	for i in range(positions.size()):
		var dummy: OverdriveLabCombatDummy = DUMMY_SCRIPT.new()
		dummy.name = "Target_%02d" % (i + 1)
		dummy.combatant_id = StringName("TARGET-%02d" % (i + 1))
		dummy.position = positions[i]
		add_child(dummy)
		dummies.append(dummy)

func _process(delta: float) -> void:
	_telemetry_timer += delta
	if _telemetry_timer >= 0.15:
		_telemetry_timer = 0.0
		performance_director.set_active_effects(router.get_child_count())
		_update_quality_budgets()
		queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_cast_at(event.position, event.shift_pressed)
	elif event is InputEventScreenTouch and event.pressed:
		_cast_at(event.position, false)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q:
				selected_element = &"lightning"
			KEY_W:
				selected_element = &"wind"
			KEY_E:
				selected_element = &"fire"
			KEY_R:
				selected_element = &"water"
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
			KEY_T:
				_play_skill(&"fire_tornado")
			KEY_G:
				_play_skill(&"fire_burst")
			KEY_Y:
				_play_skill(&"water_jet_burst")
			KEY_U:
				_play_skill(&"water_torrent")
			KEY_I:
				_play_skill(&"wind_cyclone")
			KEY_O:
				_play_skill(&"wind_blade_storm")
			KEY_X:
				_reset_targets()
		_update_quality_budgets()
		queue_redraw()

func _cast_at(pointer: Vector2, combine_with_previous: bool) -> void:
	var nearest: OverdriveLabCombatDummy
	var nearest_distance := INF
	for dummy in dummies:
		if not is_instance_valid(dummy) or dummy.is_defeated:
			continue
		var distance := pointer.distance_to(dummy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = dummy
	if nearest == null or nearest_distance > 150.0:
		_last_message = "Aim closer to a live target."
		queue_redraw()
		return

	var ability: Dictionary = ABILITY_PROFILES[selected_element].duplicate(true)
	var context: Dictionary = {"chain_candidates": dummies}
	if combine_with_previous and previous_element != &"":
		context["secondary_element_id"] = previous_element
		context["wet_surface"] = nearest.has_status(&"soaked")
	var result := adapter.execute_ability(ability, caster, [nearest], context)
	if bool(result.get("accepted", false)):
		var reaction: Dictionary = result.get("reaction", {})
		_last_message = String(reaction.get("reaction_id", "none")) + "  /  hits: " + str(result.get("hit_count", 0))
	else:
		_last_message = "Ability rejected: " + String(result.get("reason", "unknown"))
	previous_element = selected_element
	queue_redraw()

func _play_skill(skill_id: StringName) -> void:
	var skill_position := get_global_mouse_position()
	var played := router.play_skill(skill_id, skill_position, 1.0)
	_last_message = "Skill preview: " + String(skill_id) if played else "Skill effect cap reached."
	queue_redraw()

func _reset_targets() -> void:
	for dummy in dummies:
		if not is_instance_valid(dummy):
			continue
		dummy.current_health = dummy.max_health
		dummy.is_defeated = false
		if is_instance_valid(dummy.status_controller):
			dummy.status_controller.clear_all()
	_last_message = "Targets and statuses reset."
	queue_redraw()

func _update_quality_budgets() -> void:
	if not is_instance_valid(router) or not is_instance_valid(performance_director):
		return
	var active := router.get_child_count()
	var active_limit := 24
	if performance_director.quality == OverdrivePerformanceDirector.Quality.LOW:
		active_limit = 10
	elif performance_director.quality == OverdrivePerformanceDirector.Quality.HIGH:
		active_limit = 36
	router.set_quality_budgets(
		performance_director.lightning_branch_budget(),
		performance_director.visual_layer_budget(),
		active_limit
	)

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#03040b"))
	for x in range(0, int(size.x) + 1, 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.10, 0.32, 0.55, 0.12), 1.0)
	for y in range(0, int(size.y) + 1, 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.10, 0.32, 0.55, 0.12), 1.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 132.0)), Color(0.012, 0.018, 0.045, 0.98))
	draw_line(Vector2(0.0, 132.0), Vector2(size.x, 132.0), Color(0.0, 0.85, 1.0, 0.42), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 34.0), "OVERDRIVE / ELEMENTAL COMBAT LAB", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, Color("#c7ffff"))
	draw_string(ThemeDB.fallback_font, Vector2(25.0, 60.0), "Q LIGHTNING   W WIND   E FIRE   R WATER   /   SHIFT+CLICK: COMBINE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("#8bb9d9"))
	draw_string(ThemeDB.fallback_font, Vector2(25.0, 82.0), "0 AUTO QUALITY   1 LOW   2 BALANCED   3 HIGH   X RESET TARGETS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("#8bb9d9"))
	draw_string(ThemeDB.fallback_font, Vector2(25.0, 103.0), "T FIRE TORNADO   G FIRE BURST   Y WATER JET   U WATER TORRENT   I WIND CYCLONE   O BLADE STORM", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("#8bb9d9"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 24.0, 34.0), "QUALITY: " + performance_director.quality_label(), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 15, Color("#ffe18a"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 24.0, 59.0), "FPS %03d  /  %.1f ms  /  FX %02d" % [int(round(performance_director.fps_average)), performance_director.frame_time_ms, router.get_child_count()], HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 12, Color("#ff8ab4"))
	draw_line(caster.position, get_global_mouse_position(), Color(0.18, 0.92, 1.0, 0.12), 1.0, true)
	draw_circle(caster.position, 18.0, Color(0.0, 0.45, 0.8, 0.22))
	draw_arc(caster.position, 23.0, 0.0, TAU, 32, Color(0.25, 0.9, 1.0, 0.8), 2.0, true)
	draw_circle(caster.position, 5.0, Color(0.8, 1.0, 1.0, 0.95))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, size.y - 48.0), "SELECTED: " + String(selected_element).to_upper() + "    " + _last_message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 48.0, 14, _selected_color())
	draw_string(ThemeDB.fallback_font, Vector2(24.0, size.y - 25.0), "Tap/click close to a target. Hold SHIFT to combine with the previous element.", HORIZONTAL_ALIGNMENT_LEFT, size.x - 48.0, 12, Color("#719abf"))

func _selected_color() -> Color:
	match selected_element:
		&"lightning":
			return Color(0.18, 0.92, 1.0, 1.0)
		&"wind":
			return Color(0.55, 1.0, 0.82, 1.0)
		&"fire":
			return Color(1.0, 0.34, 0.08, 1.0)
		&"water":
			return Color(0.12, 0.48, 1.0, 1.0)
		_:
			return Color.WHITE
