extends Camera2D

@export var player: CharacterBody2D
@export var fixed_y: float

func _ready():
	global_position.y = fixed_y

func _process(_delta):
	global_position.x = player.global_position.x
