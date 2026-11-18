extends Control



func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)
	$BrilhoBarrinha.value = Brilho.valor
	_atualizar_sombra(Brilho.valor)

func _on_brilho_barrinha_value_changed(value: float) -> void:
	Brilho.definir(value)
	_atualizar_sombra(value)

func _atualizar_sombra(valor: float) -> void:
	var t := inverse_lerp($BrilhoBarrinha.min_value, $BrilhoBarrinha.max_value, valor)
	$Sombra.modulate.a = t

func _process(_delta: float) -> void:
	pass

func _on_voltar_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file("res://Assets/Scenes/Menu Scenes/menu_principal.tscn")

func _on_musica_barrinha_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Musica")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))

func _on_som_barrinha_2_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
