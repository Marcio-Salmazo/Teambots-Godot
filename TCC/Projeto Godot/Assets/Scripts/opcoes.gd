extends Control

const BRILHO_CENA := preload("res://Assets/Scenes/brilho.tscn")

# Camada de brilho (CanvasLayer com brilho.gd). Usa o autoload "Brilho" só se
# ele realmente tiver definir()/valor; senão cria a própria camada em /root.
var _brilho: Node


func _ready() -> void:
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.6)

	await _garantir_brilho()
	$BrilhoBarrinha.value = _brilho.valor
	_atualizar_sombra(_brilho.valor)


func _garantir_brilho() -> void:
	var raiz := get_tree().root

	# 1) Autoload "Brilho" correto (CanvasLayer com brilho.gd)
	var autoload := raiz.get_node_or_null("Brilho")
	if autoload != null:
		if autoload.has_method("definir"):
			_brilho = autoload
			return
		var script_atual = autoload.get_script()
		push_warning("O nó 'Brilho' em /root é %s (script: %s), não a cena brilho.tscn. Corrija o Autoload." % [
			autoload.get_class(),
			script_atual.resource_path if script_atual else "nenhum"
		])

	# 2) Camada criada por este script em uma visita anterior às Opções
	var criada := raiz.get_node_or_null("BrilhoCamada")
	if criada != null:
		_brilho = criada
		return

	# 3) Cria a camada
	_brilho = BRILHO_CENA.instantiate()
	_brilho.name = "BrilhoCamada"
	raiz.add_child.call_deferred(_brilho)
	await _brilho.ready


func _on_brilho_barrinha_value_changed(value: float) -> void:
	if _brilho == null:
		return
	_brilho.definir(value)
	_atualizar_sombra(value)
	

func _atualizar_sombra(valor: float) -> void:
	var t := inverse_lerp($BrilhoBarrinha.min_value, $BrilhoBarrinha.max_value, valor)
	$Sombra.modulate.a = t


func _on_voltar_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	await tween.finished
	get_tree().change_scene_to_file("res://Assets/Scenes/menu_principal.tscn")


func _on_musica_barrinha_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Musica")
	if bus == -1:
		push_warning("Barramento 'Musica' não existe no Audio Bus Layout.")
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))


func _on_som_barrinha_2_value_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(value))
