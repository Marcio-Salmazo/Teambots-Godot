class_name PlayerProtagonista
extends CharacterBody2D

const SPEED := 400.0
const JUMP_VELOCITY := 0.0
const DESACELERACAO := 1500.0

enum Estado { NORMAL, DIALOGO }

var estado_atual: Estado = Estado.NORMAL

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match estado_atual:
		Estado.NORMAL:
			_estado_normal(delta)
		Estado.DIALOGO:
			_estado_dialogo(delta)

	move_and_slide()
	_atualizar_animacao()


func _estado_normal(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("mover_esq", "mover_dir")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, DESACELERACAO * delta)


func _estado_dialogo(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, DESACELERACAO * delta)


func _atualizar_animacao() -> void:
	if absf(velocity.x) > 1.0:
		anim.flip_h = velocity.x < 0.0

	if not is_on_floor():
		_tocar(&"pulando")
	elif absf(velocity.x) > 10.0:
		_tocar(&"andando")
	else:
		_tocar(&"parado")


func _tocar(nome: StringName) -> void:
	if anim.animation != nome:
		anim.play(nome)


func iniciar_dialogo() -> void:
	estado_atual = Estado.DIALOGO


func encerrar_dialogo() -> void:
	estado_atual = Estado.NORMAL
