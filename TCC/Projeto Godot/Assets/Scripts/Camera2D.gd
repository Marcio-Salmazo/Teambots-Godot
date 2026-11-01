extends Camera2D

# REFERÊNCIA AO PLAYER
@export var player: CharacterBody2D

# LIMITES MANUAIS DA CAMERA
@export var level_left: float = 0.0
@export var level_right: float = 864.0

# ------------------------------------------------------------------------------
# INICIALIZAÇÃO DA POSIÇÃO PADRÃO EM Y (SEM ALTERAÇÕES)
func _ready():
	limit_left = int(level_left)
	limit_right = int(level_right)
	global_position.y = player.global_position.y

# ------------------------------------------------------------------------------
# ATUALIZAÇÃO DA POSIÇÃO PADRÃO EM X (DE ACORDO COM O PLAYER)
func _process(_delta):
	global_position.x = player.global_position.x
