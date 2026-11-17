extends Sprite2D

@export var nome: String

const FORCA_VIBRACAO := 15.0
const DOOR_OPEN_SFX = preload("res://Assets/AudioStream/doorOpen.wav")
const DOOR_LOCK_SFX = preload("res://Assets/AudioStream/lockedDoor.wav")

var intensidade_vibracao: float = 0.0
var decaimento: float = 20.0
var _player_na_area := false

# Area2D filha direta do Sprite0021 (a que NÃO é instância de pathway.tscn).
@onready var _area: Area2D = $Area2D


func _ready() -> void:
	# Conecta por código: não depende do painel de Sinais, onde o destino
	# padrão é o nó raiz da cena e a conexão acaba indo para o script errado.
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


# PlayerController é o class_name do script do CharacterBody2D do jogador.
# Não depende de grupo "player" (que não existe em nenhum nó do projeto).
func _on_area_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		_player_na_area = true


func _on_area_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		_player_na_area = false
