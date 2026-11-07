
extends Sprite2D

# Intensidade dos movimentos
@export_group("Rotation")
@export var rotation_amplitude: float = 0.35
@export var rotation_speed: float = 0.35

@export_group("Movement")
@export var movement_amplitude: Vector2 = Vector2(2.0, 3.0)
@export var movement_speed: float = 0.45

@export_group("Breathing")
@export var scale_amplitude: float = 0.003
@export var scale_speed: float = 0.3

# Transformação original
var initial_position: Vector2
var initial_rotation: float
var initial_scale: Vector2

var elapsed_time: float = 0.0


func _ready() -> void:
	initial_position = position
	initial_rotation = rotation
	initial_scale = scale


func _process(delta: float) -> void:
	elapsed_time += delta

	# Movimento de rotação (tilt)
	rotation = initial_rotation + deg_to_rad(
		sin(elapsed_time * rotation_speed) * rotation_amplitude
	)

	# Pequeno deslocamento horizontal e vertical
	position = initial_position + Vector2(
		sin(elapsed_time * movement_speed) * movement_amplitude.x,
		cos(elapsed_time * movement_speed * 0.8) * movement_amplitude.y
	)

	# Efeito de respiração
	var breathing = sin(elapsed_time * scale_speed)

	scale = initial_scale * (
		1.0 + breathing * scale_amplitude
	)
