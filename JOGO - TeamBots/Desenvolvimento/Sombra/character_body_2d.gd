class_name PlayerSombra
extends CharacterBody2D


const VELOCIDADE := 400.0
const VELOCIDADE_PULO := -500.0 
const DESACELERACAO := 1500.0
const MAX_PULOS := 2


var pulos_realizados := 0
enum Estado { NORMAL, DASH }
var estado_atual: Estado = Estado.NORMAL

var em_dash: bool = false
var velocidade_dash: float = 700.0
var duracao_dash: float = 0.2
var temporizador_dash: float = 0.0 
var tempo_recarga_dash: float = 0.2
var usou_dash_no_ar: bool = false 
var direcao_dash: Vector2 = Vector2.ZERO

@export var ghost_scene: PackedScene
const INTERVALO_GHOST := 0.03
var ghost_timer := 0.0

@onready var sprite_animado: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if tempo_recarga_dash > 0:
		tempo_recarga_dash -= delta

	if not is_on_floor():
		if estado_atual != Estado.DASH:
			velocity += get_gravity() * delta
	else:
		usou_dash_no_ar = false
		pulos_realizados = 0

	match estado_atual:
		Estado.NORMAL:
			_estado_normal(delta)
		Estado.DASH:
			_estado_dash(delta)

	move_and_slide()
	_atualizar_animacao()


func _estado_normal(delta: float) -> void:
	if Input.is_action_just_pressed("pular") and pulos_realizados < MAX_PULOS:
		velocity.y = VELOCIDADE_PULO
		pulos_realizados += 1

	var direcao := Vector2(
		Input.get_axis("mover_esq", "mover_dir"), 
		Input.get_axis("mover_cim","mover_bai")
	).normalized()
	
	if Input.is_action_just_pressed("dash") and tempo_recarga_dash <= 0:
		if is_on_floor() or not usou_dash_no_ar:
			iniciar_dash(direcao)
			return 
	
	if direcao.x != 0:
		velocity.x = direcao.x * VELOCIDADE
	else:
		velocity.x = move_toward(velocity.x, 0.0, DESACELERACAO * delta)


func iniciar_dash(direcao_escolhida: Vector2) -> void:
	estado_atual = Estado.DASH
	em_dash = true
	temporizador_dash = duracao_dash
	tempo_recarga_dash = 0.5 
	
	ghost_timer = 0.0 
	
	if not is_on_floor():
		usou_dash_no_ar = true
		
	if direcao_escolhida == Vector2.ZERO:
		direcao_escolhida.x = -1.0 if sprite_animado.flip_h else 1.0
		
	direcao_dash = direcao_escolhida
	velocity.y = 0


func _estado_dash(delta: float) -> void:
	velocity = direcao_dash * velocidade_dash
	
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = INTERVALO_GHOST
		spawn_ghost()
	
	temporizador_dash -= delta
	
	if temporizador_dash <= 0:
		em_dash = false
		estado_atual = Estado.NORMAL


func _atualizar_animacao() -> void:
	if absf(velocity.x) > 1.0 and estado_atual != Estado.DASH:
		sprite_animado.flip_h = velocity.x < 0.0

	if estado_atual == Estado.DASH:
		pass
	elif not is_on_floor():
		_tocar(&"pulando")
	elif absf(velocity.x) > 10.0:
		_tocar(&"andando")
	else:
		_tocar(&"parado")


func _tocar(nome_animacao: StringName) -> void:
	if sprite_animado.animation != nome_animacao:
		sprite_animado.play(nome_animacao)


func spawn_ghost() -> void:
	if ghost_scene == null:
		return
		
	var g := ghost_scene.instantiate()
	get_parent().add_child(g)
	
	var s: Sprite2D = g.get_node("Sprite2D")
	s.texture = sprite_animado.sprite_frames.get_frame_texture(sprite_animado.animation, sprite_animado.frame)
	s.flip_h = sprite_animado.flip_h
	s.scale = sprite_animado.scale
	s.offset = sprite_animado.offset
	s.modulate = Color.BLACK
	
	g.global_position = sprite_animado.global_position
