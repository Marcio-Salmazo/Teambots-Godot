extends CharacterBody2D

const ACAO_INTERAGIR := &"interagir"

@export var menu_dialogo: CanvasLayer
@export var label_texto: Label

@export var nome_personagem: String = "NPC1"
@export var falas: Array[String] = [
	"Nunca ninguém chegou ao meu peito.
Nem punho de homem, nem fio de aço.
Eu matava sem pressa e dormia sem peso:
nada em mim dava lugar a um laço.",
	"Até você.
Com você tudo em mim ficou aceso, e eu quis ficar.
Depois, no duelo, vi o seu golpe recuar
só para não me derrotar,
e algo em mim, ali, deixou de respirar.",
	"O erro foi ter deixado você me ver.
Agora você está pálido, desarmado,
e eu, que só aprendi a tirar vidas,
vou buscar a sua do outro lado.",
"Quando você cair, eu te levanto.
A sua contenção vai ceder
enquanto o meu peito cede também.
E eu, enfim, vou sorrir
quando a sua lâmina encontrar
o único lugar que ninguém alcançou.",
]

@onready var area_interacao: Area2D = $Area2D

var indice_fala: int = 0
var em_dialogo: bool = false
var jogador_proximo: PlayerProtagonista = null


func _ready() -> void:
	if menu_dialogo != null:
		menu_dialogo.hide()

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


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ACAO_INTERAGIR):
		return

	if em_dialogo:
		_avancar_fala()
		get_viewport().set_input_as_handled()
	elif is_instance_valid(jogador_proximo) and jogador_proximo.estado_atual == PlayerProtagonista.Estado.NORMAL:
		_iniciar_dialogo()
		get_viewport().set_input_as_handled()


func _on_area_2d_body_entered(body: Node2D) -> void:
	var jogador := body as PlayerProtagonista
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
	label_texto.text = "%s: %s" % [nome_personagem, falas[indice_fala]]


func _encerrar_dialogo() -> void:
	em_dialogo = false
	menu_dialogo.hide()
	if is_instance_valid(jogador_proximo):
		jogador_proximo.encerrar_dialogo()


func _exit_tree() -> void:
	if em_dialogo and is_instance_valid(jogador_proximo):
		jogador_proximo.encerrar_dialogo()
