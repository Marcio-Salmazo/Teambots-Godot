# CONTROLA O COMPORTAMENTO DO JOGADOR
class_name PlayerController
extends CharacterBody2D


# ------------------------------------------------------------------------------
# REFERÊNCIAS À COMPONENTES EXTERNOS E GLOBAIS
@export var animation_controller_path: NodePath
@onready var animation_controller = get_node_or_null(animation_controller_path)
@export var state_machine_path: NodePath
@onready var state_machine: PlayerStateMachine = $StateMachine

# ------------------------------------------------------------------------------
# REFERÊNCIAS À COMPONENTES INTERNOS DA CENA
@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Player Sprite"
@onready var sprite = $"Player Visuals/Player Sprite/AnimatedSprite2D (player)"

# ------------------------------------------------------------------------------
# CONSTANTES E VARIÁVEIS
const SPEED := 125.0
const ACCELERATION := 250.0
const FRICTION := 800.0
# 1 = direita | -1 = esquerda
var facing_direction: int = -1

# ------------------------------------------------------------------------------
# FUNÇÃO DE INICIALIZAÇÃO
func _ready() -> void:
	
	# Modo de movimentação flutuante para perspectivas top-down
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	# Verifica a presença de uma FSM
	if state_machine == null:
		push_error("PlayerController: StateMachine não encontrada.")
		return
	
	# Conecta o sinal da FSM à função _on_state_changed
	state_machine.state_changed.connect(_on_state_changed)
	# Executa manualmente o método de atualização dos estados para animações
	_on_state_changed(state_machine.current_state,
					state_machine.previous_state)

# ------------------------------------------------------------------------------
# LOOP PRINCIPAL DE FÍSICA
func _physics_process(delta: float) -> void:
	
	# _physics_process() é executada repetidamente em intervalos controlados
	# Verifica a presença de uma FSM
	if state_machine == null:
		return
	
	# Verifica se o jogador pode se movimentar.
	if state_machine.can_move():
		# Processa os comandos de movimentação.
		processar_movimento(delta)
	else:
		# Desacelera até parar.
		velocity = velocity.move_toward(Vector2.ZERO,FRICTION * delta)
	
	# Executa o movimento considerando as colisões.
	move_and_slide()
	# Atualiza a máquina de estados.
	state_machine.update_state()
	# Atualiza a orientação dos elementos visuais.
	_update_facing_direction()

# ------------------------------------------------------------------------------
# CONTROLE DE MOVIMENTAÇÃO
func processar_movimento(delta):

	# Recebe os comandos nos quatro sentidos.
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down")

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
	# Opera como uma ponte entre a FSM e o controlador de animações.
	# Atualiza o controlador de animações.
	if animation_controller:
		animation_controller.update_player_animation(current_state)

# ------------------------------------------------------------------------------
# FUNÇÕES DE CONTROLE DO DIÁLOGO
func pode_dialogar() -> bool:
	if state_machine == null:
		return false

	return (state_machine.is_in_state(PlayerStateMachine.PlayerState.IDLE)
		or state_machine.is_in_state(PlayerStateMachine.PlayerState.WALK))

# Inicia o diálogo.
func iniciar_dialogo() -> void:
	if state_machine != null:
		state_machine.start_dialogue()

# Encerra o diálogo.
func encerrar_dialogo() -> void:
	if state_machine != null:
		state_machine.end_dialogue()
