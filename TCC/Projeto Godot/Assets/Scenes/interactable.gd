extends Node2D
class_name DialogueInteractable

@export var dialogue_data: DialogueData
@export var interaction_area: Area2D

# Referência ao jogador enquanto ele está dentro da área de interação.
var _player: CharacterBody2D = null

# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# INTERAÇÃO: tecla "interagir" (E) com o jogador dentro da área
func _unhandled_input(event: InputEvent) -> void:

	if _player == null or not event.is_action_pressed("interagir"):
		return

	# Só inicia se o jogador estiver em IDLE/WALK (evita reabrir durante o diálogo).
	if not _player.has_method("pode_dialogar") or not _player.pode_dialogar():
		return

	if dialogue_data == null:
		push_warning("Interactable: dialogue_data vazio em " + name)
		return

	get_viewport().set_input_as_handled()

	# AJUSTAR: nome real da função de início no DialogueManager.gd
	DialogueManager.start_dialogue(dialogue_data, _player)

# ------------------------------------------------------------------------------
# PROCURA RECURSIVAMENTE UMA ÁREA2D NOS FILHOS DO OBJETO
func _find_interaction_area(node: Node) -> Area2D:

	for child in node.get_children():
		if child is Area2D:
			return child as Area2D
		var found := _find_interaction_area(child)
		if found != null:
			return found
	return null

# ------------------------------------------------------------------------------
# DETECTA ENTRADA / SAÍDA DO JOGADOR
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player = body

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
