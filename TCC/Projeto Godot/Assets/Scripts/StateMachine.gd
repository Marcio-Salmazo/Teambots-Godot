class_name PlayerStateMachine
extends Node

# ESTADOS DISPONÍVEIS
enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL
}

# SINAL DE MUDANÇA DE ESTADO
signal state_changed(current_state: int, previous_state: int)

# REFERÊNCIA AO PLAYER
@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

# INICIALIZAÇÃO DOS ESTADOS PADRÃO
var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# ------------------------------------------------------------------------------
# INICIALIZAÇÃO
func _ready():

	# Verifica se o nó pai é um CharacterBody2D.
	if player == null:
		push_error(
            "StateMachine: O nó pai precisa ser um CharacterBody2D."
		)

# ------------------------------------------------------------------------------
# ATUALIZAÇÃO DA FSM
func update_state():

	# Impede a execução caso a referência ao Player seja inválida.
	if player == null:
		return

	var next_state: PlayerState

	# Verifica se o personagem está andando.
	if player.velocity.length() > 5:
		next_state = PlayerState.WALK

	# Caso contrário, permanece parado.
	else:
		next_state = PlayerState.IDLE

	# Verifica se houve uma mudança de estado.
	if next_state != current_state:

		# Armazena o estado anterior.
		previous_state = current_state
		# Atualiza o estado atual.
		current_state = next_state
		# Notifica os outros componentes.
		state_changed.emit(current_state, previous_state)
