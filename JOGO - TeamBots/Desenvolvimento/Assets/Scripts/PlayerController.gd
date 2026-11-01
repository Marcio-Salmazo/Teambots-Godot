# ==============================================================================
# PLAYER CONTROLLER - TOP DOWN MOVEMENT
# ==============================================================================

class_name PlayerProtagonista
extends CharacterBody2D


# ==============================================================================
# REFERÊNCIAS EXTERNAS
# ==============================================================================

@export var animation_controller_path: NodePath
@onready var animation_controller = get_node_or_null(animation_controller_path)

@export var attack_controller_path: NodePath
@onready var attack_controller = get_node_or_null(attack_controller_path)

# Decide se o jogador anda (EstadoNormal) ou fica parado conversando (EstadoDialogo).
# Se não for atribuída, o player continua se movendo livremente, como antes.
@export var state_machine: StateMachine


# ==============================================================================
# REFERÊNCIAS INTERNAS
# ==============================================================================

@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Player Sprite"
@onready var sprite = $"Player Visuals/Player Sprite/AnimatedSprite2D (player)"
@onready var player_pivot = $"Player Visuals/Player Pivot"

# ==============================================================================
# SISTEMA DE ESTADOS (FSM)
# ==============================================================================

enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK
}

var current_state: PlayerState = PlayerState.IDLE
var previous_state: PlayerState = PlayerState.IDLE

# 1 = direita | -1 = esquerda
var facing_direction: int = 1


# ==============================================================================
# VARIÁVEIS DE MOVIMENTAÇÃO
# ==============================================================================

const SPEED := 100.0
const ACCELERATION := 200.0
const FRICTION := 800.0


# ==============================================================================
# CONTROLE DE PULO
# ==============================================================================

const JUMP_FORCE := -220.0
const JUMP_GRAVITY := 600.0

var jump_velocity := 0.0
var jump_offset := 0.0
var is_jumping := false

var visuals_initial_position: Vector2


# ==============================================================================
# INICIALIZAÇÃO
# ==============================================================================

func _ready():

	# O movimento Top-Down não utiliza gravidade.
	# O personagem se movimenta livremente nos dois eixos.

	# MOTION_MODE_FLOATING = modo top-down: sem chão/teto/parede. No modo padrão (GROUNDED) a Godot
	# classifica colisões como chão/parede e aplica snap e slide de plataforma, o que "gruda" o
	# personagem ao andar rente aos objetos.
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	visuals_initial_position = visuals.position


# ==============================================================================
# LOOP PRINCIPAL DE FÍSICA
# ==============================================================================

func _physics_process(delta):

	# 1. Processa a movimentação do jogador (delegada ao estado atual, quando há StateMachine)
	if state_machine:
		state_machine.physics_update(delta)
	else:
		processar_movimento(delta)

	# 2. Executa o movimento considerando colisões
	move_and_slide()

	# 4. Atualiza o estado atual do jogador
	_update_state()

	# 5. Atualiza as animações
	_update_animation(current_state)

	# 6. Atualiza a orientação do pivô de ataque
	player_pivot.scale.x = facing_direction


# ==============================================================================
# CONTROLE DE MOVIMENTAÇÃO
# ==============================================================================

func processar_movimento(delta):

	# Recebe os comandos nos quatro sentidos.
	# O Input.get_vector normaliza automaticamente as diagonais.

	var direction := Input.get_vector(
		"mov_esq",
		"mov_dir",
		"mov_cima",
		"mov_baixo"
	)

	# Atualiza a direção horizontal do personagem.
	if direction.x != 0:
		facing_direction = int(sign(direction.x))

	# Calcula a velocidade desejada nos dois eixos.
	var target_velocity = direction * SPEED

	# Aplica aceleração e fricção independentemente nos dois eixos.
	velocity.x = move_toward(
		velocity.x,
		target_velocity.x,
		(ACCELERATION if direction.x != 0 else FRICTION) * delta
	)

	velocity.y = move_toward(
		velocity.y,
		target_velocity.y,
		(ACCELERATION if direction.y != 0 else FRICTION) * delta
	)

# ==============================================================================
# INTEGRAÇÃO COM DIÁLOGO (usada pelo NPC e pelos estados)
# ==============================================================================

const ESTADO_NORMAL := "EstadoNormal"
const ESTADO_DIALOGO := "EstadoDialogo"

# Chamado pelo EstadoDialogo: sem input, apenas freia até parar.
func frear(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

# O NPC só inicia uma conversa se o jogador estiver no estado normal.
func pode_dialogar() -> bool:
	return state_machine != null and state_machine.is_in_state(ESTADO_NORMAL)

func iniciar_dialogo() -> void:
	if state_machine:
		state_machine.transition_to(ESTADO_DIALOGO)

func encerrar_dialogo() -> void:
	if state_machine:
		state_machine.transition_to(ESTADO_NORMAL)


# ==============================================================================
# CONTROLE DO SISTEMA DE ESTADOS (FSM)
# ==============================================================================

func _update_state():

	# Verifica se o personagem está se movimentando.
	if velocity.length() > 5:
		current_state = PlayerState.WALK

	# Caso contrário, permanece parado.
	else:
		current_state = PlayerState.IDLE

	# Atualiza o estado anterior quando ocorre uma mudança.
	if current_state != previous_state:
		previous_state = current_state


# ==============================================================================
# CONTROLE DE ANIMAÇÕES
# ==============================================================================

func _update_animation(param_current_state):

	# Envia o estado atual para o controlador de animações.
	if animation_controller:
		animation_controller.update_player_animation(param_current_state)

	# Inverte o sprite conforme a última direção horizontal.
	sprite.flip_h = facing_direction < 0

	# Mantém o pivô de ataque orientado corretamente.
	player_pivot.scale.x = facing_direction


# ==============================================================================
# CONTROLE DE VISIBILIDADE DOS ELEMENTOS
# ==============================================================================

func handle_state(state):

	match state:

		PlayerState.ATTACK:
			player_pivot.visible = true

		_:
			player_pivot.visible = false
