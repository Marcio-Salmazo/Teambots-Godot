extends CanvasLayer

# REFERÊNCIAS À INTERFACE
@onready var panel: Control = $DialoguePanel
@onready var speaker_label: Label = $"DialoguePanel/MarginContainer/VBox Container/Speaker Label"
@onready var dialogue_text: Label = $"DialoguePanel/MarginContainer/VBox Container/Dialog Text"

# OBJETO PRÓXIMO DO JOGADOR
var current_interactable: Interactable = null
# JOGADOR ENVOLVIDO NA CONVERSA
var current_player: PlayerController = null
# DADOS DA CONVERSA
var current_lines: Array[String] = []
var current_speaker: String = ""
# CONTROLE DO DIÁLOGO
var dialogue_index: int = 0
var dialogue_active: bool = false
# AÇÃO DE INTERAÇÃO
const ACTION_INTERACT := &"interagir"

# ------------------------------------------------------------------------------
# INICIALIZAÇÃO
func _ready() -> void:
	panel.hide()
	if not InputMap.has_action(ACTION_INTERACT):
		push_error("DialogueManager: A ação 'interagir' não existe no InputMap.")

# ------------------------------------------------------------------------------
# REGISTRA O OBJETO PRÓXIMO DO JOGADOR
func set_interactable(interactable: Interactable,player: PlayerController) -> void:

	if dialogue_active:
		return
	current_interactable = interactable
	current_player = player

# ------------------------------------------------------------------------------
# REMOVE O OBJETO QUANDO O JOGADOR SE AFASTA
func clear_interactable(interactable: Interactable) -> void:

	if current_interactable != interactable:
		return
	current_interactable = null
	if not dialogue_active:
		current_player = null

# ------------------------------------------------------------------------------
# RECEBE OS COMANDOS DO JOGADOR
func _unhandled_input(event: InputEvent) -> void:

	if not event.is_action_pressed(ACTION_INTERACT):
		return

	if dialogue_active:
		advance_dialogue()
	elif is_instance_valid(current_interactable):
		if not is_instance_valid(current_player):
			return
		if not current_player.pode_dialogar():
			return

		start_dialogue(current_interactable.dialogue_data,current_player)
	else:
		return
	get_viewport().set_input_as_handled()

# ------------------------------------------------------------------------------
# INICIA UMA CONVERSA
func start_dialogue(data: DialogueData,player: PlayerController) -> void:

	if dialogue_active:
		return
	if data == null or data.lines.is_empty():
		push_warning("DialogueManager: Diálogo vazio ou não configurado.")
		return
	if not is_instance_valid(player):
		return
	if not player.pode_dialogar():
		return
		
	# Armazena os dados
	current_lines = data.lines.duplicate()
	current_speaker = data.speaker
	current_player = player

	# Inicializa o controle
	dialogue_index = 0
	dialogue_active = true
	# Altera o estado do jogador
	current_player.iniciar_dialogo()
	
	# Exibe a interface
	panel.show()
	show_current_line()

# ------------------------------------------------------------------------------
# EXIBE A FALA ATUAL
func show_current_line() -> void:

	if dialogue_index >= current_lines.size():
		end_dialogue()
		return
		
	speaker_label.text = current_speaker
	dialogue_text.text = current_lines[dialogue_index]

# ------------------------------------------------------------------------------
# AVANÇA PARA A PRÓXIMA FALA
func advance_dialogue() -> void:

	dialogue_index += 1
	if dialogue_index < current_lines.size():
		show_current_line()
	else:
		end_dialogue()

# ------------------------------------------------------------------------------
# FINALIZA A CONVERSA
func end_dialogue() -> void:

	dialogue_active = false
	panel.hide()
	# Libera o jogador
	if is_instance_valid(current_player):
		current_player.encerrar_dialogo()

	# Limpa os dados da conversa
	current_lines.clear()
	current_speaker = ""
	dialogue_index = 0
	current_player = null

# ------------------------------------------------------------------------------
# VERIFICA SE EXISTE UMA CONVERSA ATIVA
func is_dialogue_active() -> bool:
	return dialogue_active

# ------------------------------------------------------------------------------
# GARANTE A LIBERAÇÃO DO JOGADOR
func _exit_tree() -> void:
	if dialogue_active and is_instance_valid(current_player):
		current_player.encerrar_dialogo()
