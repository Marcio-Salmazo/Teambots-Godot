extends Area2D

@export var nome: String

var _mudando := false

func _on_body_entered(body: Node2D) -> void:
	if _mudando or not (body is CharacterBody2D):
		return
	_mudando = true
	change_level.call_deferred()

func change_level() -> void:
	Global.from_word = "Room"   # cena de onde o jogador está saindo
	get_tree().change_scene_to_file("res://Assets/Scenes/" + nome + ".tscn")
