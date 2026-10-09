extends Node
class_name OverdrivePerformanceDirector

## Central quality budget. Actual FPS is measured by the lab; no target is assumed achieved.

enum Quality { LOW, BALANCED, HIGH }

var quality: Quality = Quality.BALANCED
var fps_average: float = 0.0
var _fps_initialized: bool = false

func _process(delta: float) -> void:
    if delta <= 0.0:
        return
    var current_fps: float = 1.0 / delta
    if not _fps_initialized:
        fps_average = current_fps
        _fps_initialized = true
    else:
        fps_average = lerpf(fps_average, current_fps, 0.08)

func set_quality(next_quality: Quality) -> void:
    quality = next_quality

func lightning_branch_budget() -> int:
    match quality:
        Quality.LOW:
            return 2
        Quality.HIGH:
            return 7
        _:
            return 4

func visual_layer_budget() -> int:
    match quality:
        Quality.LOW:
            return 1
        Quality.HIGH:
            return 3
        _:
            return 2

func quality_label() -> String:
    match quality:
        Quality.LOW:
            return "LOW"
        Quality.HIGH:
            return "HIGH"
        _:
            return "BALANCED"
