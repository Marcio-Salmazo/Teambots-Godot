# CONTROLA O COMPORTAMENTO DO JOGADOR
class_name PlayerController
extends CharacterBody2D


# ------------------------------------------------------------------------------
# REFERÊNCIAS À COMPONENTES EXTERNOS E GLOBAIS
@export var animation_controller_path: NodePath
@onready var animation_controller: Node = get_node_or_null(animation_controller_path)

@export var state_machine_path: NodePath
@onready var state_machine: PlayerStateMachine = (
	get_node_or_null(state_machine_path) as PlayerStateMachine
	if not state_machine_path.is_empty()
	else get_node_or_null("StateMachine") as PlayerStateMachine
)

# ------------------------------------------------------------------------------
# REFERÊNCIAS À COMPONENTES INTERNOS DA CENA
@onready var visuals = $"Player Visuals"
@onready var spr_rotator = $"Player Visuals/Player Sprite"
@onready var sprite: AnimatedSprite2D = $"Player Visuals/Player Sprite/AnimatedSprite2D (player)"

# ------------------------------------------------------------------------------
# CONSTANTES E VARIÁVEIS
const SPEED := 75.0
const ACCELERATION := 250.0
const FRICTION := 800.0

## Marque como true se a arte original do personagem foi desenhada olhando para a direita.
## Desmarque se a arte original foi desenhada olhando para a esquerda.
@export var sprite_olha_para_direita: bool = true

# 1 = direita | -1 = esquerda
var facing_direction: int = 1

# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# PENALIDADE CAUSADA PELO FANTASMA (PERMANENTE: não há recuperação)
# Multiplica a velocidade: 1.0 = normal. Cada toque do fantasma reduz o fator.
var fator_debuff: float = 1.0
# Piso do fator: o jogador nunca fica abaixo desse valor da velocidade base.
# Com 0.0 o jogador pararia de vez (e na casa não há dash para escapar).
@export_range(0.0, 1.0, 0.05) var fator_minimo: float = 0.0
# Guarda o tween do feedback visual para não acumular vários ao levar golpes seguidos.
var _tween_piscar: Tween

# ------------------------------------------------------------------------------
# FUNÇÃO DE INICIALIZAÇÃO
func _ready() -> void:
	# Modo de movimentação flutuante para perspectivas top-down
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	# Verifica a presença de uma FSM
	if state_machine == null:
		push_error("PlayerController: StateMachine não encontrada.")
		return

	# Verifica se o nó atribuído como AnimationController realmente possui o método esperado
	if animation_controller == null or not animation_controller.has_method("update_player_animation"):
		push_error("PlayerController: AnimationController inválido ou não atribuído no Inspetor.")

	# Aplica a orientação inicial do sprite
	_update_facing_direction()

	# Conecta o sinal da FSM à função _on_state_changed
	state_machine.state_changed.connect(_on_state_changed)
	# Executa manualmente o método de atualização dos estados para animações
	_on_state_changed(state_machine.current_state, state_machine.previous_state)

# ------------------------------------------------------------------------------
# LOOP PRINCIPAL DE FÍSICA
func _physics_process(delta: float) -> void:
	if state_machine == null:
		return
	elif state_machine.can_move():
		# Processa os comandos de movimentação.
		processar_movimento(delta)
	else:
		# Desacelera até parar.
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	# Executa o movimento considerando as colisões.
	move_and_slide()
	# Atualiza a máquina de estados.
	state_machine.update_state()
	# Atualiza a orientação dos elementos visuais.
	_update_facing_direction()

# ------------------------------------------------------------------------------
# CONTROLE DE MOVIMENTAÇÃO
func processar_movimento(delta: float) -> void:
	var direction := Input.get_vector("mov_esquerda", "mov_direita", "mov_cima", "mov_baixo")
	move_and_slide()

	# Atualiza a direção horizontal (1 = direita, -1 = esquerda).
	if direction.x != 0:
		facing_direction = int(sign(direction.x))

	# Calcula a velocidade desejada (SPEED é a base; o fantasma reduz o fator).
	var target_velocity := direction * SPEED * fator_debuff

	# Aplica aceleração ou fricção no eixo X.
	velocity.x = move_toward(velocity.x, target_velocity.x,
		(ACCELERATION if direction.x != 0 else FRICTION) * delta)

	# Aplica aceleração ou fricção no eixo Y.
	velocity.y = move_toward(velocity.y, target_velocity.y,
		(ACCELERATION if direction.y != 0 else FRICTION) * delta)

# ------------------------------------------------------------------------------
# LÓGICA DO DASH
func _direcao_olhando() -> Vector2:
	return Vector2(facing_direction, 0)

func _iniciar_dash() -> void:
	var direction := Input.get_vector("mov_esquerda", "mov_direita", "mov_cima", "mov_baixo")

	if direction == Vector2.ZERO:
		# Sem input: dash para o lado em que o personagem está olhando.
		direction = _direcao_olhando()
	elif direction.x != 0:
		# Com input: já vira o sprite para a direção do dash.
		facing_direction = int(sign(direction.x))
		_update_facing_direction()

	
# ------------------------------------------------------------------------------
# ATUALIZAÇÃO DA DIREÇÃO
func _deve_espelhar() -> bool:
	if sprite_olha_para_direita:
		return facing_direction < 0
	return facing_direction > 0

func _update_facing_direction() -> void:
	if sprite != null:
		sprite.flip_h = _deve_espelhar()

# ------------------------------------------------------------------------------
# ALTERAÇÃO DE ESTADOS
func _on_state_changed(current_state: int, _previous_state: int) -> void:
	if animation_controller != null and animation_controller.has_method("update_player_animation"):
		animation_controller.update_player_animation(current_state)

# ------------------------------------------------------------------------------
# FUNÇÕES DE CONTROLE DO DIÁLOGO
func pode_dialogar() -> bool:
	if state_machine == null:
		return false

	return (state_machine.is_in_state(PlayerStateMachine.PlayerState.IDLE)
		or state_machine.is_in_state(PlayerStateMachine.PlayerState.WALK))

func iniciar_dialogo() -> void:
	if state_machine != null:
		state_machine.start_dialogue()

func encerrar_dialogo() -> void:
	if state_machine != null:
		state_machine.end_dialogue()

# ------------------------------------------------------------------------------
# PENALIDADE DO FANTASMA
func levar_penalidade(quantidade: float) -> void:
	fator_debuff = maxf(fator_minimo, fator_debuff - quantidade)
	_piscar()

func _piscar() -> void:
	if _tween_piscar != null and _tween_piscar.is_valid():
		_tween_piscar.kill()
	sprite.modulate = Color.BLACK
	_tween_piscar = create_tween()
	_tween_piscar.tween_property(sprite, "modulate", Color.WHITE, 0.4)
