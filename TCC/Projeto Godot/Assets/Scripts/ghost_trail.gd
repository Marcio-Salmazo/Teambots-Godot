extends Node2D

@export var lifetime: float = 0.3
var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	modulate.a = 1.0 - (timer / lifetime)
	if timer >= lifetime:
		queue_free()
