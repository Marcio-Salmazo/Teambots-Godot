# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR ESPECIFICAMENTE COM ANIMAÇÕES DO PLAYER
# ==============================================================================
extends Node

# ------------------------------------------------------------------------------
# Referências externas para os Sprites do jogador e do ataque
@export var player_sprite_path: NodePath
@onready var player_sprite = get_node(player_sprite_path)

@export var blade_effects_sprite_path: NodePath
@onready var blade_sprite = get_node(blade_effects_sprite_path)

@export var atack_controler_path: NodePath
@onready var attack_controller = get_node(atack_controler_path)

# ------------------------------------------------------------------------------
# Sinais a serem enviados para os demais scripts associados
signal ANIM_FINISHED_ATK

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
# FUNÇÃO READY PARA INICIALIZAÇÃO
# ==============================================================================
func _ready():
		
	# Estado normal do sprite do ataque fica escondido
	blade_sprite.hide()
	
	# Conecta os sinais recebidos de attack controller 
	# às funções de animção do ataque
	if attack_controller.has_signal("ATK_CONTROLLER_ATK_STARTED"):
		attack_controller.ATK_CONTROLLER_ATK_STARTED.connect(_on_attack_start)	
		
	if attack_controller.has_signal("ATK_CONTROLLER_ATK_FINISHED"):
		attack_controller.ATK_CONTROLLER_ATK_FINISHED.connect(_on_attack_end)

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
		PlayerState.ATTACK:
			
			_play("Player Attack")
			blade_sprite.show() 
			blade_sprite.play("Blade Animation")
			
			if blade_sprite.animation_finished:
				emit_signal("ANIM_FINISHED_ATK")

# ==============================================================================
# ANIMAÇÃO DE ATAQUE - START
# ==============================================================================
func _on_attack_start():
	pass
	# Exibe o sprite e toca a animação
	#blade_sprite.show() 
	#blade_sprite.play("Blade Animation")
	
# ==============================================================================
# CALLBACK DE ANIMAÇÃO - END 
# ==============================================================================
func _on_attack_end():
	
	# Esconde o sprite
	blade_sprite.hide()
