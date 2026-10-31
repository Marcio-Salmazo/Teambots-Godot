# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR ESPECIFICAMENTE COM ANIMAÇÕES DO PLAYER
# ==============================================================================
extends Node

# ------------------------------------------------------------------------------
# Referências externas para os Sprites do jogador e do ataque
@export var player_sprite_path: NodePath
@onready var player_sprite = get_node(player_sprite_path)

# ------------------------------------------------------------------------------
# Lista de estados possíveis voltados para a implementação do FSM
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK
}
	
# ==============================================================================
# FUNÇÃO AUXILIAR PARA EVITAR QUE UMA MESMA ANIMAÇÃO SEJA REINICIADA
# ==============================================================================
func _play(anim_name: String):
	
	if player_sprite.animation != anim_name:
		player_sprite.play(anim_name)

# ==============================================================================
# FUNÇÃO QUE GERENCIA AS ANIMAÇÕES ESPECÍFICAS DO SPRITE DO JOGADOR
# ==============================================================================
func update_player_animation(state):

	match state:

		PlayerState.WALL_SLIDE:
			_play("Player WallJump")
		PlayerState.JUMP:
			_play("Player Jump")
		PlayerState.FALL:
			_play("Player Fall")
		PlayerState.WALK:
			_play("Player Walk")
		PlayerState.IDLE:
			_play("Player Idle")
