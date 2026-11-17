extends Sprite2D

@export var nome: String

const FORCA_VIBRACAO := 2.5
const DOOR_OPEN_SFX = preload("res://Assets/AudioStream/doorOpen.wav")
const DOOR_LOCK_SFX = preload("res://Assets/AudioStream/lockedDoor.wav")

var intensidade_vibracao: float = 0.0
var decaimento: float = 20.0
var _player_na_area := false

@onready var _area: Area2D = $Area2D


func _ready() -> void:
	_area.body_entered.connect(_on_area_body_entered)
	_area.body_exited.connect(_on_area_body_exited)


func _process(delta: float) -> void:
	if intensidade_vibracao > 0.0:
		offset = Vector2(
			randf_range(-intensidade_vibracao, intensidade_vibracao),
			randf_range(-intensidade_vibracao, intensidade_vibracao)
		)
		intensidade_vibracao = move_toward(intensidade_vibracao, 0.0, decaimento * delta)
	else:
		offset = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if _player_na_area and event.is_action_pressed("interagir"):
		vibrar(FORCA_VIBRACAO)


func vibrar(forca: float = 5.0) -> void:
	intensidade_vibracao = forca


func _on_area_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player_na_area = true


func _on_area_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player_na_area = false
