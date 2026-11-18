extends Control

func _ready() -> void:
	for botao in $VBoxContainer.get_children():
		if botao is Button:
			botao.mouse_entered.connect(_on_botao_hover.bind(botao, true))
			botao.mouse_exited.connect(_on_botao_hover.bind(botao, false))

func _on_botao_hover(botao: Button, dentro: bool) -> void:
	botao.pivot_offset = botao.size / 2
	var escala := Vector2(1.15, 1.15) if dentro else Vector2.ONE
	var cor := Color(2.137, 2.137, 2.137, 0.188) if dentro else Color.WHITE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(botao, "scale", escala, 0.12)
	tween.tween_property(botao, "modulate", cor, 0.12)


func _on_sair_do_jogo_pressed() -> void:
	get_tree().quit()

func _on_creditos_pressed() -> void:
		get_tree().change_scene_to_file("res://Assets/Scenes/Menu Scenes/creditos.tscn")

func _on_opcoes_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://Assets/Scenes/Menu Scenes/opcoes.tscn")

func _on_iniciar_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scenes/Startup.tscn")
