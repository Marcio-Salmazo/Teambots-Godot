# CONTROLADOR DO JOGADOR COM DASH (usado somente pela cena playercomDASH)
# Herda tudo do PlayerController (movimento, diálogo, penalidade do fantasma).
# Por herdar, as checagens "body is PlayerController" dos outros scripts continuam valendo.
# Aqui só mudam o loop de física e a lógica do dash.
class_name PlayerControllerDash
extends PlayerController


# ------------------------------------------------------------------------------
# VARIÁVEIS DO DASH (ação "dash" no Mapa de Entrada: Shift ou botão direito do mouse)
@export_group("Dash")
@export var dash_speed: float = 400.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.6
@export var ghost_trail_scene: PackedScene = preload("res://Assets/Scenes/ghost_trail.tscn")
@export var ghost_interval: float = 0.05
## Cor/opacidade inicial da sombra (o fade até 0 é feito em ghost_trail.gd).
@export var ghost_color: Color = Color(0, 0, 0, 0.5)
@export_group("")

var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var ghost_timer: float = 0.0

# ------------------------------------------------------------------------------
# LOOP PRINCIPAL DE FÍSICA (substitui o do PlayerController para incluir o dash)
func _physics_process(delta: float) -> void:
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
	elif state_machine.can_move():
		# Processa os comandos de movimentação (herdado do PlayerController).
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
# LÓGICA DO DASH
func _iniciar_dash() -> void:
	var direction := Input.get_vector("mov_esquerda", "mov_direita", "mov_cima", "mov_baixo")

	if direction == Vector2.ZERO:
		# Sem input: dash para o lado em que o personagem está olhando.
		direction = _direcao_olhando()
	elif direction.x != 0:
		# Com input: já vira o sprite para a direção do dash.
		facing_direction = int(sign(direction.x))
		_update_facing_direction()

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
		# de dash_speed até SPEED a só ACCELERATION px/s² (deslizando na direção antiga).
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
		push_warning("PlayerControllerDash: ghost_trail precisa ter um filho Sprite2D.")
		ghost.free()
		return

	# Visual: congela o frame atual do player como silhueta.
	ghost_sprite.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost_sprite.centered = sprite.centered
	ghost_sprite.offset = sprite.offset
	ghost_sprite.texture_filter = sprite.texture_filter
	# Usa _deve_espelhar() (e não sprite.flip_h): o flip do sprite só é atualizado no
	# fim do _physics_process, então no 1º frame do dash ele ainda estaria invertido.
	ghost_sprite.flip_h = _deve_espelhar()
	ghost_sprite.modulate = ghost_color

	# A sombra fica parada no mundo: desliga a interpolação de física (ligada no
	# projeto) para ela não "deslizar" a partir da origem no primeiro frame.
	ghost.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	ghost.z_index = z_index

	var pai := get_parent()
	pai.add_child(ghost)
	# Copia posição, rotação e escala do sprite.
	ghost.global_transform = sprite.global_transform
	# Mesmo z_index do player, mas logo ANTES dele na árvore => desenha atrás.
	pai.move_child(ghost, get_index())
