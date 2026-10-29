extends Node2D

@export var lifetime: float = 0.3
var tempo_decorrido: float = 0.0

func _process(delta: float) -> void:
	tempo_decorrido += delta
	
	# Interpola a transparência (Alpha) de 0.5 até 0.0 com base no tempo
	modulate.a = lerpf(0.5, 0.0, tempo_decorrido / lifetime)
	
	# Elimina o nó da árvore de cena quando o tempo de vida expira
	if tempo_decorrido >= lifetime:
		queue_free()
