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
# VARIÁVEIS DO DASH (ação "dash" no Mapa de Entrada: Shift ou botão direito do mouse)
@export_category("Dash")
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6
@export var ghost_trail_scene: PackedScene = preload("res://Assets/Scenes/ghost_trail.tscn")
@export var ghost_interval: float = 0.05
## Cor/opacidade inicial da sombra (o fade até 0 é feito em ghost_trail.gd).
@export var ghost_color: Color = Color(0, 0, 0, 0.5)

var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var ghost_timer: float = 0.0

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
	
	# Contagem regressiva do cooldown do dash.
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta

	# Inicia o dash (não vale em cooldown, durante outro dash nem em diálogo).
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0 and not is_dashing and state_machine.can_move():
		_iniciar_dash()

	if is_dashing:
		# Durante o dash, a velocidade é controlada só pelo dash.
		_processar_dash(delta)
	# Verifica se o jogador pode se movimentar.
	elif state_machine.can_move():
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
## Direção horizontal para onde o personagem está olhando.
## A arte original olha para a ESQUERDA e o sprite é espelhado (flip_h) quando
## facing_direction < 0. Ou seja: facing_direction == -1 significa olhando para a DIREITA,
## então o vetor precisa do sinal invertido.
func _direcao_olhando() -> Vector2:
	return Vector2(-facing_direction, 0)

func _iniciar_dash() -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if direction == Vector2.ZERO:
		# Sem input: dash para o lado em que o personagem está olhando.
		direction = _direcao_olhando()
	elif direction.x != 0:
		# Com input: já vira o sprite para a direção do dash.
		facing_direction = -1 * int(sign(direction.x))

	dash_direction = direction.normalized()
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	ghost_timer = 0.0
	state_machine.change_state(PlayerStateMachine.PlayerState.DASH)

func _processar_dash(delta: float) -> void:
	dash_timer -= delta
	velocity = dash_direction * dash_speed * fator_debuff

	_gerar_ghost_trail(delta)

	if dash_timer <= 0.0:
		is_dashing = false
		# Corta a velocidade que sobrou do dash. Sem isso, processar_movimento() reduz
		# de dash_speed até SPEED a só ACCELERATION px/s² (~1 s deslizando na direção
		# antiga, mesmo você já apontando para outro lado).
		velocity = velocity.limit_length(SPEED * fator_debuff)
		state_machine.change_state(PlayerStateMachine.PlayerState.IDLE)
		state_machine.update_state()

func _gerar_ghost_trail(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer > 0.0 or ghost_trail_scene == null:
		return
	ghost_timer = ghost_interval

	var ghost := ghost_trail_scene.instantiate() as Node2D
	var ghost_sprite := ghost.get_node_or_null("Sprite2D") as Sprite2D
	if ghost_sprite == null:
		push_warning("PlayerController: ghost_trail precisa ter um filho Sprite2D.")
		ghost.free()
		return

	# Visual: congela o frame atual do player como silhueta.
	ghost_sprite.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost_sprite.centered = sprite.centered
	ghost_sprite.offset = sprite.offset
	ghost_sprite.texture_filter = sprite.texture_filter
	# Usa facing_direction (e não sprite.flip_h): o flip do sprite só é atualizado no
	# fim do _physics_process, então no 1º frame do dash ele ainda estaria invertido.
	ghost_sprite.flip_h = facing_direction < 0
	ghost_sprite.modulate = ghost_color

	# A sombra fica parada no mundo: desliga a interpolação de física (ligada no
	# projeto) para ela não "deslizar" a partir da origem no primeiro frame.
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	ghost.z_index = z_index

	var pai := get_parent()
	pai.add_child(ghost)
	# Copia posição, rotação e escala do sprite (player 2.5 x sprite 0.04 = 0.1).
	ghost.global_transform = sprite.global_transform
	# Mesmo z_index do player, mas logo ANTES dele na árvore => desenha atrás.
	pai.move_child(ghost, get_index())

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

# ------------------------------------------------------------------------------
# PENALIDADE DO FANTASMA
# Chamada pelo fantasma (area_2d.gd / hitbox_fantasma.gd) quando ele toca o jogador.
# Sem imunidade: o fantasma some depois do toque, então cada toque vale um golpe.
func levar_penalidade(quantidade: float) -> void:
	fator_debuff = maxf(fator_minimo, fator_debuff - quantidade)
	_piscar()

# Feedback visual: o sprite fica preto e volta ao normal.
func _piscar() -> void:
	if _tween_piscar != null and _tween_piscar.is_valid():
		_tween_piscar.kill()
	sprite.modulate = Color.BLACK
	_tween_piscar = create_tween()
	_tween_piscar.tween_property(sprite, "modulate", Color.WHITE, 0.4)
