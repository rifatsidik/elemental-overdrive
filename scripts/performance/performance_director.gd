extends Node
class_name OverdrivePerformanceDirector

## Quality budgets and conservative adaptive scaling. This is a heuristic, not a substitute
## for profiling on target Android devices.

enum Quality { LOW, BALANCED, HIGH }

var quality: Quality = Quality.BALANCED
var adaptive_enabled: bool = true
var fps_average: float = 0.0
var frame_time_ms: float = 0.0
var active_effects: int = 0
var _fps_initialized: bool = false
var _decision_timer: float = 0.0
var _low_fps_time: float = 0.0
var _high_fps_time: float = 0.0

const ADAPT_INTERVAL := 1.25
const LOW_FPS_THRESHOLD := 48.0
const HIGH_FPS_THRESHOLD := 58.0

func _process(delta: float) -> void:
    if delta <= 0.0:
        return
    var current_fps := 1.0 / delta
    frame_time_ms = delta * 1000.0
    if not _fps_initialized:
        fps_average = current_fps
        _fps_initialized = true
    else:
        # Smooth short spikes without hiding sustained performance changes.
        fps_average = lerpf(fps_average, current_fps, 0.10)

    if not adaptive_enabled:
        return

    _decision_timer += delta
    if fps_average < LOW_FPS_THRESHOLD:
        _low_fps_time += delta
        _high_fps_time = 0.0
    elif fps_average > HIGH_FPS_THRESHOLD:
        _high_fps_time += delta
        _low_fps_time = 0.0
    else:
        _low_fps_time = maxf(0.0, _low_fps_time - delta * 0.5)
        _high_fps_time = maxf(0.0, _high_fps_time - delta * 0.5)

    if _decision_timer < ADAPT_INTERVAL:
        return
    _decision_timer = 0.0

    if _low_fps_time >= 1.6 and quality != Quality.LOW:
        set_quality(Quality(maxi(0, int(quality) - 1)))
        _low_fps_time = 0.0
        _high_fps_time = 0.0
    elif _high_fps_time >= 5.0 and quality != Quality.HIGH:
        set_quality(Quality(mini(2, int(quality) + 1)))
        _low_fps_time = 0.0
        _high_fps_time = 0.0

func set_quality(next_quality: Quality) -> void:
    quality = next_quality

func set_adaptive(enabled: bool) -> void:
    adaptive_enabled = enabled
    _low_fps_time = 0.0
    _high_fps_time = 0.0
    _decision_timer = 0.0

func set_active_effects(count: int) -> void:
    active_effects = maxi(0, count)

func lightning_branch_budget() -> int:
    var budget := 4
    match quality:
        Quality.LOW:
            budget = 2
        Quality.HIGH:
            budget = 7
        _:
            budget = 4
    # Reduce new effect complexity when many effects overlap.
    if active_effects >= 12:
        budget = maxi(1, int(floor(float(budget) * 0.55)))
    elif active_effects >= 7:
        budget = maxi(1, int(floor(float(budget) * 0.75)))
    return budget

func visual_layer_budget() -> int:
    var budget := 2
    match quality:
        Quality.LOW:
            budget = 1
        Quality.HIGH:
            budget = 3
        _:
            budget = 2
    if active_effects >= 10:
        budget = maxi(1, budget - 1)
    return budget

func quality_label() -> String:
    var label := "BALANCED"
    match quality:
        Quality.LOW:
            label = "LOW"
        Quality.HIGH:
            label = "HIGH"
        _:
            label = "BALANCED"
    return label + (" / AUTO" if adaptive_enabled else " / MANUAL")
