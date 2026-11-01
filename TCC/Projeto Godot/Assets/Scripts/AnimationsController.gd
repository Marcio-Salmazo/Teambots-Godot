extends Node


# REFERÊNCIAS EXTERNAS AO SPRITE DO PLAYER
@export var player_sprite_path: NodePath
@onready var player_sprite: AnimatedSprite2D = get_node_or_null(
	player_sprite_path
)

# ------------------------------------------------------------------------------
# VERIFICAÇÃO INICIAL SE O SPRITE DO PLAYER FOI ENCONTRADO
func _ready():

	if player_sprite == null:
		push_error("AnimationController: Player Sprite não encontrado.")

# ------------------------------------------------------------------------------
# FUNÇÃO DE REPRODUÇÃO DAS ANIMAÇÕES
func _play(anim_name: String):

	if player_sprite == null:
		return

	# Verifica se a animação existe.
	if not player_sprite.sprite_frames.has_animation(anim_name):
		push_warning("Animação não encontrada: " + anim_name)
		return

	# Evita reiniciar uma animação que já está sendo executada.
	if player_sprite.animation != anim_name:
		player_sprite.play(anim_name)

# ------------------------------------------------------------------------------
# GERENCIAMENTO DAS ANIMAÇÕES DO JOGADOR
func update_player_animation(state: int):

	match state:

		PlayerStateMachine.PlayerState.IDLE:
			_play("Player Idle")

		PlayerStateMachine.PlayerState.WALK:
			_play("Player Walk")
