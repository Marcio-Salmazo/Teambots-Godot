extends Area2D

@export var sprite_alvo: Sprite2D 

@export var nome: String
const DOOR_OPEN_SFX = preload("res://Assets/AudioStream/doorOpen.wav")
const DOOR_LOCK_SFX = preload("res://Assets/AudioStream/lockedDoor.wav")

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
	if not _player_na_area or Fade.transitioning:
		return
	if event.is_action_pressed("interagir"):
		print("[escada] ", owner.name, " -> ", nome)
		if nome == "Room" || nome == "Main House" :
			AudioManager.play_sfx(DOOR_OPEN_SFX)
		else:
			AudioManager.play_sfx(DOOR_LOCK_SFX)
		
		change_level()

func change_level() -> void:
	if nome.is_empty():
		push_error("pathway '%s' em '%s': 'nome' vazio no Inspector" % [name, owner.name])
		return
	if nome == "null":
		return
	var caminho := "res://Assets/Scenes/" + nome + ".tscn"
	if not ResourceLoader.exists(caminho):
		push_error("pathway '%s' em '%s': cena '%s' não existe" % [name, owner.name, caminho])
		return
	Global.from_world = owner.name
	Fade.change_scene(caminho)
