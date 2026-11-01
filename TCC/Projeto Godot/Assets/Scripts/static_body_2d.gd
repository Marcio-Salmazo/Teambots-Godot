extends Node2D
# Interação por diálogo. Pode ser anexado a qualquer nó 2D (CharacterBody2D de um NPC, StaticBody2D de
# um objeto etc.). A conversa é detectada pela Area2D em 'area_interacao'; se ficar vazio, usa a primeira
# Area2D encontrada entre os descendentes. Essa Area2D precisa ser MAIOR que o colisor sólido do corpo:
# o jogador (máscara 2) não atravessa o colisor, então uma área do mesmo tamanho nunca chega a sobrepô-lo.

const ACAO_INTERAGIR := &"interagir"

@export var menu_dialogo: CanvasLayer
@export var label_texto: Label

@export var nome_personagem: String = ""
@export var falas: Array[String] = [
	"“Eu só pedia água. Uma vez por semana... e nem isso. Olha pra mim, murchando na janela, e você nem percebe. Se nem de uma plantinha você consegue cuidar, como vai cuidar do resto?”"
	
]

@export var area_interacao: Area2D

var indice_fala: int = 0
var em_dialogo: bool = false
var jogador_proximo: PlayerController = null


func _ready() -> void:
	if menu_dialogo != null:
		menu_dialogo.hide()

	if area_interacao == null:
		area_interacao = _buscar_area(self)
	if area_interacao == null:
		push_error("NPC '%s': nenhuma Area2D encontrada. Atribua 'area_interacao' no Inspector." % name)
		set_process_unhandled_input(false)
		return

	if not area_interacao.body_entered.is_connected(_on_area_2d_body_entered):
		area_interacao.body_entered.connect(_on_area_2d_body_entered)
	if not area_interacao.body_exited.is_connected(_on_area_2d_body_exited):
		area_interacao.body_exited.connect(_on_area_2d_body_exited)

	var config_ok := true
	if menu_dialogo == null or label_texto == null:
		push_error("NPC '%s': atribua 'menu_dialogo' e 'label_texto' no Inspector." % name)
		config_ok = false
	if not InputMap.has_action(ACAO_INTERAGIR):
		push_error("NPC '%s': a ação '%s' não existe. Crie em Projeto → Configurações do Projeto → Mapa de Entrada." % [name, ACAO_INTERAGIR])
		config_ok = false

	set_process_unhandled_input(config_ok)


func _buscar_area(raiz: Node) -> Area2D:
	for filho in raiz.get_children():
		if filho is Area2D:
			return filho as Area2D
		var achada := _buscar_area(filho)
		if achada != null:
			return achada
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ACAO_INTERAGIR):
		return

	if em_dialogo:
		_avancar_fala()
		get_viewport().set_input_as_handled()
		
	elif is_instance_valid(jogador_proximo) and jogador_proximo.pode_dialogar():
		
		_iniciar_dialogo()
		get_viewport().set_input_as_handled()


func _on_area_2d_body_entered(body: Node2D) -> void:
	var jogador := body as PlayerController
	if jogador == null:
		return
	jogador_proximo = jogador


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body != jogador_proximo:
		return
	if em_dialogo:
		_encerrar_dialogo()
	jogador_proximo = null


func _iniciar_dialogo() -> void:
	if falas.is_empty():
		push_warning("NPC '%s' não tem falas." % name)
		return

	em_dialogo = true
	indice_fala = 0
	jogador_proximo.iniciar_dialogo()
	menu_dialogo.show()
	_mostrar_fala()


func _avancar_fala() -> void:
	indice_fala += 1
	if indice_fala < falas.size():
		_mostrar_fala()
	else:
		_encerrar_dialogo()


func _mostrar_fala() -> void:
	label_texto.text = "%s %s" % [nome_personagem, falas[indice_fala]]


func _encerrar_dialogo() -> void:
	em_dialogo = false
	menu_dialogo.hide()
	if is_instance_valid(jogador_proximo):
		jogador_proximo.encerrar_dialogo()


func _exit_tree() -> void:
	if em_dialogo and is_instance_valid(jogador_proximo):
		jogador_proximo.encerrar_dialogo()
