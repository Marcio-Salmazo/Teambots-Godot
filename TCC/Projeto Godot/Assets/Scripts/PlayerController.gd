# ==============================================================================
# PLAYER CONTROLLER - TOP DOWN
# ==============================================================================

class_name PlayerController
extends CharacterBody2D


# ==============================================================================
# REFERÊNCIAS EXTERNAS
# ==============================================================================

@export var animation_controller_path: NodePath
@onready var animation_controller = get_node_or_null(animation_controller_path)

@export var state_machine_path: NodePath
@onready var state_machine = get_node_or_null(state_machine_path)

# ==============================================================================
# REFERÊNCIAS INTERNAS
# ==============================================================================

@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Player Sprite"
@onready var sprite = $"Player Visuals/Player Sprite/AnimatedSprite2D (player)"

const SPEED := 125.0
const ACCELERATION := 250.0
const FRICTION := 800.0

# 1 = direita | -1 = esquerda
var facing_direction: int = -1

# ------------------------------------------------------------------------------
# INICIALIZAÇÃO
func _ready():

	# Conecta o sinal da FSM ao controlador do jogador.
	state_machine.state_changed.connect(_on_state_changed)

	# Inicializa a apresentação do estado atual.
	_on_state_changed(
		state_machine.current_state,
		state_machine.previous_state
	)


# ------------------------------------------------------------------------------
# LOOP PRINCIPAL DE FÍSICA
func _physics_process(delta):

	# Processa a movimentação.
	_handle_movement(delta)
	# Executa o movimento considerando as colisões.
	move_and_slide()
	# Solicita à FSM que avalie uma possível transição.
	state_machine.update_state()
	# Atualiza a orientação dos elementos visuais.
	_update_facing_direction()

# ------------------------------------------------------------------------------
# CONTROLE DE MOVIMENTAÇÃO
func _handle_movement(delta):

	# Recebe os comandos nos quatro sentidos.
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	# Atualiza a direção horizontal.
	if direction.x != 0:
		facing_direction = -1 * int(sign(direction.x))

	# Calcula a velocidade desejada.
	var target_velocity := direction * SPEED

	# Aplica aceleração ou fricção no eixo X.
	velocity.x = move_toward(velocity.x, target_velocity.x,
		(ACCELERATION if direction.x != 0 else FRICTION) * delta)

	# Aplica aceleração ou fricção no eixo Y.
	velocity.y = move_toward(velocity.y, target_velocity.y,
		(ACCELERATION if direction.y != 0 else FRICTION) * delta)


# ------------------------------------------------------------------------------
# ATUALIZAÇÃO DA DIREÇÃO
func _update_facing_direction():
	
	# Inverte o sprite conforme a direção horizontal.
	sprite.flip_h = facing_direction < 0

# ------------------------------------------------------------------------------
# ALTERAÇÃO DE ESTADOS
func _on_state_changed(current_state: int, _previous_state: int):

	# Atualiza o controlador de animações.
	if animation_controller:
		animation_controller.update_player_animation(current_state)
