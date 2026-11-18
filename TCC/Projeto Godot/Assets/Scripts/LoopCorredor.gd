extends Node2D

@export_file("*.tscn") var next_scene_path: String

static var corridor_visits: int = 0

@onready var iteration1 = $Iteration1
@onready var iteration2 = $Iteration2
@onready var iteration3 = $Iteration3
@onready var transicao = $Transicao/pathway


func _ready() -> void:

	# Controla a visibilidade das iterações
	iteration1.visible = corridor_visits == 0
	iteration2.visible = corridor_visits == 1
	iteration3.visible = corridor_visits == 2

	# Conecta o sinal de interação da porta
	transicao.interaction_requested.connect(_on_transition_interacted)


func _on_transition_interacted() -> void:

	corridor_visits += 1

	print("Iteração atual: ", corridor_visits)

	if corridor_visits < 3:

		# Recarrega o próprio corredor
		get_tree().reload_current_scene()

	else:

		# Executa a função change_level do pathway.gd
		transicao.change_level.call_deferred()
