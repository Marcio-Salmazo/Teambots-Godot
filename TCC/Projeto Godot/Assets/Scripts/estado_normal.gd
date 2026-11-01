extends State
class_name EstadoNormal

@export var actor: PlayerController

# Estado padrão do jogador: movimento livre nos dois eixos (top-down).
# A lógica de movimento fica no PlayerController; o estado só decide QUANDO ela roda.
func physics_update(delta: float) -> void:
	actor.processar_movimento(delta)
