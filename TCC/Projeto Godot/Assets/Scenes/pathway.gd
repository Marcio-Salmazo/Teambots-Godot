
extends Area2D

@export var sprite_alvo: Sprite2D
@export var nome: String

const DOOR_OPEN_SFX = preload("res://Assets/AudioStream/doorOpen.wav")
const DOOR_LOCK_SFX = preload("res://Assets/AudioStream/lockedDoor.wav")

signal interaction_requested

var _player_na_area := false


func _ready() -> void:
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = true
		if sprite_alvo:
			sprite_alvo.z_index = 0


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = false
		if sprite_alvo:
			sprite_alvo.z_index = 3


func _unhandled_input(event: InputEvent) -> void:
	if _player_na_area and event.is_action_pressed("interagir"):

		print("[escada] ", owner.name, " -> ", nome)

		if nome == "Room" || nome == "Main House":
			AudioManager.play_sfx(DOOR_OPEN_SFX)
		else:
			AudioManager.play_sfx(DOOR_LOCK_SFX)

		# EXCEÇÃO: cena do corredor
		if get_tree().current_scene.scene_file_path == "res://Assets/Scenes/loop_corredor.tscn":
			interaction_requested.emit()

		# TODAS AS OUTRAS CENAS
		else:
			change_level.call_deferred()


func change_level() -> void:
	if nome.is_empty():
		push_error("pathway '%s' em '%s': 'nome' vazio no Inspector" % [name, owner.name])
		return

	if nome == "null":
		return

	Global.from_world = owner.name
	get_tree().change_scene_to_file("res://Assets/Scenes/" + nome + ".tscn")
