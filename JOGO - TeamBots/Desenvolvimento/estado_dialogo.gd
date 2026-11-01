extends State
class_name EstadoDialogo

@export var actor: PlayerProtagonista

# Durante a conversa o jogador ignora o input de movimento e apenas freia até parar.
func physics_update(delta: float) -> void:
	actor.frear(delta)
