extends Area2D

@export var nome: String

var _player_na_area := false

func _ready() -> void:
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_na_area and event.is_action_pressed("interagir"):
		change_level.call_deferred()

func change_level() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/" + nome + ".tscn")
