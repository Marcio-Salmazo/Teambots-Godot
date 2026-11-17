extends Camera2D

@export var player: Node2D
@export var follow_speed: float = 8.0

func _ready() -> void:
	if player:
		global_position = player.global_position
		reset_smoothing()

func _physics_process(delta: float) -> void:
	if not player:
		return
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(player.global_position, weight)
