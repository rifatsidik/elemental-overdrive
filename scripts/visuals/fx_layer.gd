extends Node2D
class_name FXLayer

## Dedicated layer for pooled lightning, impacts, particles, and screen effects.
## Visual effects will be added here so combat logic stays independent.

var intensity := 1.0

func _ready() -> void:
    z_index = 20
    set_process(false)
