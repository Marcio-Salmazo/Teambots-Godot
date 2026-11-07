# A ideia é representar o comportamento do personagem por meio de um conjunto 
# limitado de estados. Em vez de espalhar verificações pelo código inteiro
class_name PlayerStateMachine
extends Node

# ------------------------------------------------------------------------------
# ESTADOS DISPONÍVEIS
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	DIALOGUE
}

# SINAL DE MUDANÇA DE ESTADO
# INFORMA OS ESTADOS ATUAIS E PRÉVIOS
signal state_changed(current_state: int, previous_state: int)

# REFERÊNCIA AO JOGADOR
@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

# INICIALIZAÇÃO DOS ESTADOS
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE
# CONTROLE DE DIÁLOGO
var dialogue_active: bool = false

# ------------------------------------------------------------------------------
# EXECUTADA QUANDO O NÓ ESTÁ PRONTO NA ÁRVORE DE CENAS
func _ready() -> void:
	if player == null:
		push_error("StateMachine: O nó pai precisa ser CharacterBody2D.")

# ------------------------------------------------------------------------------
# AVALIAÇÃO CONTÍNUA DA SIATUAÇÃO ATUAL DO PERSONAGEM
# DETERMINA O PRÓXIMO ESTADO
# CHAMADA CONTINUAMENTE PELO PLAYER CONTROLLER
func update_state() -> void:

	if player == null or dialogue_active:
		return
	
	# Variável que armazena o estado que deverá ser aplicado ao personagem.
	var next_state: PlayerState

	# Em um jogo Top Down, verificamos a velocidade
	# nos dois eixos para identificar a movimentação.
	if player.velocity.length() > 5:
		next_state = PlayerState.WALK
	else:
		next_state = PlayerState.IDLE
	change_state(next_state)

# ------------------------------------------------------------------------------
# ALTERAÇÃO DO ESTADO
func change_state(new_state: PlayerState) -> void:

	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state
	# Emissão do sinal de mudança de estado
	state_changed.emit(current_state, previous_state)

# ------------------------------------------------------------------------------
# VERIFICA O ESTADO ATUAL
func is_in_state(state: PlayerState) -> bool:
	return current_state == state
	
# ------------------------------------------------------------------------------
# FUNÇÕES DE CONTROLE DE DIALOGO
func start_dialogue() -> void:

	if dialogue_active:
		return
	dialogue_active = true
	change_state(PlayerState.DIALOGUE)

# Finaliza o diálogo
func end_dialogue() -> void:

	if not dialogue_active:
		return
	dialogue_active = false
	# Reavalia a velocidade atual do personagem para determinar 
	# se ele deve retornar a IDLE ou WALK.
	update_state()

# ------------------------------------------------------------------------------
# VERIFICA SE A MOVIMENTAÇÃO É POSSÍVEL
func can_move() -> bool:
	return not dialogue_active
