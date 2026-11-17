extends Node2D


func _ready() -> void:
	var origem := String(Global.from_world) if Global.from_world != null else ""
	Global.from_world = null  # consome: não vale para a próxima cena
	if origem.is_empty():
		return  # início do jogo ou entrada sem origem: o jogador fica onde a cena o colocou

	var marcador := get_node_or_null(origem + "Pos") as Marker2D
	if marcador == null:
		push_warning("Levels: marcador '%sPos' não existe em '%s'." % [origem, name])
		return

	var jogador := $Player/Player as CharacterBody2D
	jogador.global_position = marcador.global_position
	jogador.reset_physics_interpolation()

	# A câmera já se posicionou no _ready dela (que roda ANTES do da raiz),
	# ainda no ponto antigo. Sem isto ela "desliza" até o jogador ao entrar na cena.
	var camera := $Player/Camera2D as Camera2D
	camera.global_position = jogador.global_position
	camera.reset_smoothing()
	camera.reset_physics_interpolation()


func _on_pathway_2_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
