
class_name PlayerStateMachine
extends Node

# Estados disponíveis
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	DIALOGUE
}

# Sinal de mudança de estado
signal state_changed(current_state: int, previous_state: int)

# Referência ao jogador
@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

# Controle dos estados
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# Controle de diálogo
var dialogue_active: bool = false


func _ready() -> void:

	if player == null:
		push_error("StateMachine: O nó pai precisa ser CharacterBody2D.")


# Atualiza o estado do jogador
func update_state() -> void:

	if player == null or dialogue_active:
		return

	var next_state: PlayerState

	# Em um jogo Top Down, verificamos a velocidade
	# nos dois eixos para identificar a movimentação.

	if player.velocity.length() > 5:
		next_state = PlayerState.WALK

	else:
		next_state = PlayerState.IDLE

	change_state(next_state)


# Altera o estado atual
func change_state(new_state: PlayerState) -> void:

	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	state_changed.emit(current_state, previous_state)


# Inicia o diálogo
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
	update_state()


# Verifica o estado atual
func is_in_state(state: PlayerState) -> bool:

	return current_state == state


# Verifica se o jogador pode se movimentar
func can_move() -> bool:

	return not dialogue_active
