extends Node
class_name OverdriveCore

## Shared timing and event contract. This module has no gameplay dependencies.

signal energy_burst_requested(origin: Vector2, strength: float, seed_value: int)

var elapsed_seconds: float = 0.0
var effect_sequence: int = 0

func _process(delta: float) -> void:
    elapsed_seconds += delta

func request_energy_burst(origin: Vector2, strength: float = 1.0) -> void:
    effect_sequence += 1
    var seed_value: int = int((effect_sequence * 7919 + Time.get_ticks_usec()) % 2147483647)
    energy_burst_requested.emit(origin, clampf(strength, 0.1, 2.0), seed_value)
