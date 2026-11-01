
extends Node2D
class_name Interactable

@export var dialogue_data: DialogueData
@export var interaction_area: Area2D


func _ready() -> void:

	# Procura automaticamente a Area2D caso não tenha sido atribuída.
	if interaction_area == null:
		interaction_area = _find_interaction_area(self)

	if interaction_area == null:
		push_error("Interactable: nenhuma Area2D encontrada em " + name)
		return

	# Conecta os sinais de detecção.
	if not interaction_area.body_entered.is_connected(_on_body_entered):
		interaction_area.body_entered.connect(_on_body_entered)

	if not interaction_area.body_exited.is_connected(_on_body_exited):
		interaction_area.body_exited.connect(_on_body_exited)


# Procura recursivamente uma Area2D nos filhos do objeto.
func _find_interaction_area(node: Node) -> Area2D:

	for child in node.get_children():

		if child is Area2D:
			return child as Area2D

		var found := _find_interaction_area(child)

		if found != null:
			return found

	return null


# Detecta a entrada do jogador.
func _on_body_entered(body: Node2D) -> void:

	if body is PlayerController:
		DialogueManager.set_interactable(self, body)

# Detecta a saída do jogador.
func _on_body_exited(body: Node2D) -> void:

	if body is PlayerController:
		DialogueManager.clear_interactable(self)
