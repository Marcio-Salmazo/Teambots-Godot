
extends Area2D

@export var proxima_cena: String = "res://Assets/Scenes/Startup.tscn"
@onready var animacao: AnimatedSprite2D = $AnimatedSprite2D

var ativado := false

func _ready() -> void:
	animacao.visible = false
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if ativado:
		return

	if body.is_in_group("jogador"):
		ativado = true

		animacao.visible = true
		animacao.play()

		await animacao.animation_finished

		get_tree().change_scene_to_file(proxima_cena)
