extends Control
## Cena de apoio dos testes: registra em que frame ficou pronta e conta cliques no botão.

var cliques := 0


func _ready() -> void:
	get_tree().root.set_meta("pronta_" + name, Engine.get_process_frames())
	$Botao.pressed.connect(func() -> void: cliques += 1)
