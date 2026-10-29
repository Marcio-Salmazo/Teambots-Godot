extends SceneTree
## Teste automatizado dos autoloads do P1 (GameManager, Save, Transicao).
## Roda sem janela e sem editor:
##
##   godot --headless --path <projeto> -s res://tests/teste_p1.gd -- tudo
##   godot --headless --path <projeto> -s res://tests/teste_p1.gd -- gravar
##   godot --headless --path <projeto> -s res://tests/teste_p1.gd -- ler
##
## "gravar" e "ler" são dois processos separados, para provar que o save
## sobrevive a fechar e abrir o jogo. Precisa de tests/cena_a.tscn,
## tests/cena_b.tscn e res://fases/cap1/memoria_sombra.tscn (qualquer cena).
## Sai com código 0 se tudo passou, 1 se algo falhou.

const CENA_A := "res://tests/cena_a.tscn"
const CENA_B := "res://tests/cena_b.tscn"
const CENA_CAP1 := "res://fases/cap1/memoria_sombra.tscn"
const SAVE := "user://save.json"

# Um script rodado com -s é compilado antes de os autoloads virarem nomes
# globais; por isso eles são buscados em root (e não se faz preload dos scripts
# deles aqui, que os compilaria cedo demais). Enums e constantes de GameManager
# são lidos do próprio script em _initialize.
var gm: Node
var sv: Node
var tr: Node
var GM := {}   # { "Modo": {...}, "CAPITULOS": {...} }

var total := 0
var falhas := 0
var cortes_vistos := 0


func _initialize() -> void:
	gm = root.get_node("GameManager")
	sv = root.get_node("Save")
	tr = root.get_node("Transicao")
	var constantes: Dictionary = gm.get_script().get_script_constant_map()
	GM = {"Modo": constantes.get("Modo", {}), "CAPITULOS": constantes.get("CAPITULOS", {})}
	tr.corte_concluido.connect(func() -> void: cortes_vistos += 1)
	var args := OS.get_cmdline_user_args()
	var modo: String = args[0] if args.size() > 0 else "tudo"
	_rodar(modo)


func _rodar(modo: String) -> void:
	# Em _initialize os autoloads ainda não entraram na árvore nem rodaram _ready.
	await process_frame
	await process_frame
	# A janela headless do modo -s nasce com 64x64: pequena demais para os
	# cliques de teste caírem dentro dela.
	root.size = Vector2i(1152, 648)
	await process_frame
	match modo:
		"tudo":
			await _t_instalacao()
			await _t_gamemanager()
			await _t_transicao()
			await _t_cliques()
			await _t_save()
		"gravar":
			await _t_gravar()
		"ler":
			await _t_ler()
	print("\nRESULTADO [%s]: %d verificações, %d falhas" % [modo, total, falhas])
	quit(1 if falhas > 0 else 0)


# ---------------------------------------------------------------- utilidades

func ok(condicao: bool, nome: String, detalhe: String = "") -> void:
	total += 1
	if condicao:
		print("  PASS  ", nome)
	else:
		falhas += 1
		print("  FAIL  ", nome, ("   -> " + detalhe) if detalhe != "" else "")


func titulo(texto: String) -> void:
	print("\n== ", texto)


func frames(n: int) -> void:
	for i in n:
		await process_frame


## Espera o próximo corte_concluido (até 'limite' segundos). Devolve se veio.
func esperar_corte(limite: float = 3.0) -> bool:
	var estado := {"veio": false}
	tr.corte_concluido.connect(func() -> void: estado.veio = true, CONNECT_ONE_SHOT)
	var inicio := Time.get_ticks_msec()
	while not estado.veio and (Time.get_ticks_msec() - inicio) < limite * 1000.0:
		await process_frame
	return estado.veio


func cena_atual_path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func apagar_save() -> void:
	var real := ProjectSettings.globalize_path(SAVE)
	if DirAccess.dir_exists_absolute(real):
		DirAccess.remove_absolute(real)
	elif FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(real)


func escrever_save(texto: String) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(texto)
	f.close()


func ler_save_cru() -> Variant:
	var f := FileAccess.open(SAVE, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


func clicar(pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = pos
	ev.global_position = pos
	ev.pressed = true
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(ev)
	var solta := ev.duplicate() as InputEventMouseButton
	solta.pressed = false
	solta.button_mask = 0
	root.push_input(solta)


# ------------------------------------------------------------------- testes

func _t_instalacao() -> void:
	titulo("Instalação dos autoloads")
	var nomes: Array[String] = []
	for filho in root.get_children():
		nomes.append(String(filho.name))
	print("  filhos do root: ", nomes)
	ok(nomes.slice(0, 3) == ["GameManager", "Save", "Transicao"], "ordem: GameManager, Save, Transicao")
	for nome in ["GameManager", "Save", "Transicao"]:
		var cfg := String(ProjectSettings.get_setting("autoload/" + nome, ""))
		ok(cfg.begins_with("*"), "%s registrado como singleton (começa com *)" % nome, cfg)

	ok(tr.layer == 100, "Transicao.layer == 100", str(tr.layer))
	ok(tr.process_mode == Node.PROCESS_MODE_ALWAYS, "Transicao.process_mode == Always")
	var preto := tr.get_node("Preto") as ColorRect
	ok(preto != null, "filho ColorRect chamado Preto")
	ok(not preto.visible, "Preto começa escondido")
	ok(preto.color == Color.BLACK, "Preto é preto opaco", str(preto.color))
	ok(preto.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Preto começa com Mouse Filter = Ignore")
	ok(preto.anchor_left == 0.0 and preto.anchor_top == 0.0 and preto.anchor_right == 1.0 and preto.anchor_bottom == 1.0, "Preto é Full Rect")
	ok(not tr.em_corte, "em_corte começa falso")


func _t_gamemanager() -> void:
	titulo("GameManager")
	ok(GM.Modo.keys() == ["SOMBRA", "PROTAGONISTA", "TRANSICAO"], "enum Modo tem SOMBRA, PROTAGONISTA e TRANSICAO", str(GM.Modo))
	ok(gm.modo_atual == GM.Modo["SOMBRA"], "modo_atual começa em SOMBRA")
	ok(gm.capitulo_atual == 1, "capitulo_atual começa em 1")
	ok(gm.tensao == 0, "tensao começa em 0")
	ok(GM.CAPITULOS.get(1) == CENA_CAP1, "mapa de capítulos: 1 -> memoria_sombra.tscn")

	# mudar_modo
	var modos: Array = []
	var conexao := func(novo: int) -> void: modos.append(novo)
	gm.modo_mudou.connect(conexao)
	gm.mudar_modo(GM.Modo["SOMBRA"])
	ok(modos.is_empty(), "mudar_modo para o modo atual não emite sinal")
	gm.mudar_modo(GM.Modo["PROTAGONISTA"])
	ok(modos == [GM.Modo["PROTAGONISTA"]] and gm.modo_atual == GM.Modo["PROTAGONISTA"], "mudar_modo(PROTAGONISTA) grava e emite uma vez", str(modos))
	gm.mudar_modo(GM.Modo["PROTAGONISTA"])
	ok(modos.size() == 1, "repetir o mesmo modo não emite de novo")
	gm.mudar_modo(GM.Modo["TRANSICAO"])
	ok(modos.size() == 2 and gm.modo_atual == GM.Modo["TRANSICAO"], "mudar_modo(TRANSICAO) emite")

	# tensão fica em 0..3
	gm.tensao = 7
	ok(gm.tensao == 3, "tensao > 3 é limitada a 3", str(gm.tensao))
	gm.tensao = -2
	ok(gm.tensao == 0, "tensao < 0 é limitada a 0", str(gm.tensao))

	# iniciar_capitulo (capítulo que existe)
	apagar_save()
	gm.tensao = 2
	gm.mudar_modo(GM.Modo["PROTAGONISTA"])
	modos.clear()
	var capitulos: Array = []
	gm.capitulo_mudou.connect(func(n: int) -> void: capitulos.append(n))
	gm.iniciar_capitulo(1)
	ok(capitulos == [1], "iniciar_capitulo(1) emite capitulo_mudou(1)", str(capitulos))
	ok(gm.tensao == 0, "iniciar_capitulo zera a tensao")
	ok(gm.modo_atual == GM.Modo["SOMBRA"] and modos == [GM.Modo["SOMBRA"]], "iniciar_capitulo volta o modo para SOMBRA (e emite modo_mudou)", str(modos))
	ok(tr.em_corte, "iniciar_capitulo pede o corte para a Transicao")
	ok(await esperar_corte(), "corte do capítulo concluiu")
	ok(cena_atual_path() == CENA_CAP1, "cena atual é a inicial do capítulo 1", cena_atual_path())

	# iniciar_capitulo (capítulo inexistente): erro claro e nada muda
	capitulos.clear()
	modos.clear()
	gm.mudar_modo(GM.Modo["PROTAGONISTA"])
	modos.clear()
	gm.tensao = 2
	var antes_cortes := cortes_vistos
	gm.iniciar_capitulo(99)
	await frames(5)
	ok(capitulos.is_empty(), "capítulo 99: não emite capitulo_mudou")
	ok(gm.capitulo_atual == 1, "capítulo 99: capitulo_atual não muda", str(gm.capitulo_atual))
	ok(gm.tensao == 2 and gm.modo_atual == GM.Modo["PROTAGONISTA"] and modos.is_empty(), "capítulo 99: tensao e modo intactos")
	ok(not tr.em_corte and cortes_vistos == antes_cortes and cena_atual_path() == CENA_CAP1, "capítulo 99: nenhum corte, a cena continua a mesma")
	gm.iniciar_capitulo(0)
	gm.iniciar_capitulo(-1)
	await frames(2)
	ok(gm.capitulo_atual == 1 and not tr.em_corte, "capítulos 0 e -1: nada acontece")
	gm.modo_mudou.disconnect(conexao)
	gm.mudar_modo(GM.Modo["SOMBRA"])
	gm.tensao = 0


func _t_transicao() -> void:
	titulo("Transicao")
	var preto := tr.get_node("Preto") as ColorRect

	# 3: liga o Preto na hora, sem fade
	tr.cortar_para(CENA_A)
	ok(tr.em_corte, "em_corte fica verdadeiro assim que o corte começa")
	ok(preto.visible and preto.modulate.a == 1.0 and preto.color.a == 1.0, "Preto aparece instantaneamente, opaco (sem fade)")

	# 1: pedido durante um corte é ignorado
	var antes := cortes_vistos
	tr.cortar_para(CENA_B)
	ok(await esperar_corte(), "corte A concluiu")
	await frames(10)
	ok(cena_atual_path() == CENA_A, "segundo pedido durante o corte foi ignorado (ficou na cena A)", cena_atual_path())
	ok(cortes_vistos - antes == 1, "corte_concluido emitido uma única vez", str(cortes_vistos - antes))
	ok(not tr.em_corte and not preto.visible, "ao concluir: em_corte falso e Preto escondido")

	# 5: a cena nova já desenhou pelo menos um frame antes do Preto sumir
	var pronta: int = root.get_meta("pronta_CenaA", -1)
	ok(pronta >= 0 and Engine.get_process_frames() - pronta >= 1, "cena nova já tinha rodado >= 1 frame quando o Preto sumiu", "pronta=%d agora=%d" % [pronta, Engine.get_process_frames()])

	# 2: caminho inexistente
	var cena_antes := cena_atual_path()
	tr.cortar_para("res://nao_existe.tscn")
	await frames(3)
	ok(not tr.em_corte and not preto.visible and cena_atual_path() == cena_antes, "caminho inexistente: nada acontece")
	tr.cortar_para("")
	await frames(3)
	ok(not tr.em_corte and not preto.visible and cena_atual_path() == cena_antes, "caminho vazio: nada acontece")

	# 3: despausa o jogo
	paused = true
	tr.cortar_para(CENA_B)
	ok(not paused, "o corte despausa o jogo")
	ok(await esperar_corte(), "corte com o jogo pausado concluiu")
	ok(cena_atual_path() == CENA_B and not paused, "chegou na cena B e o jogo segue despausado")

	# 6: segurar
	var t0 := Time.get_ticks_msec()
	tr.cortar_para(CENA_A, 0.4)
	await frames(6)
	ok(cena_atual_path() == CENA_A and preto.visible and tr.em_corte, "segurar: cena nova já carregada e o Preto continua na tela")
	ok(await esperar_corte(), "corte com segurar concluiu")
	var dt := Time.get_ticks_msec() - t0
	ok(dt >= 390, "segurar=0.4 segurou pelo menos 0,4 s", "%d ms" % dt)
	ok(not preto.visible and not tr.em_corte, "depois do segurar: Preto escondido e em_corte falso")

	# 4: a engine recusa a troca (arquivo existe mas não é cena)
	paused = true
	tr.cortar_para("res://autoload/game_manager.gd")
	await frames(4)
	ok(not tr.em_corte and not preto.visible, "troca recusada pela engine: não fica preso na tela preta")
	ok(paused, "troca recusada: o estado de pausa original é restaurado")
	ok(cena_atual_path() == CENA_A, "troca recusada: a cena atual continua a mesma", cena_atual_path())
	paused = false


func _t_cliques() -> void:
	titulo("Transicao: clique não vaza durante o corte")
	var preto := tr.get_node("Preto") as ColorRect
	tr.cortar_para(CENA_A)
	await esperar_corte()
	var pos := Vector2(200, 150)

	# controle: fora de um corte, o clique injetado chega no botão
	clicar(pos)
	await frames(2)
	ok(current_scene.cliques == 1, "controle: sem corte, o clique chega no botão da cena", str(current_scene.cliques))

	# durante o corte: o clique não pode chegar na cena velha. (Na 4.7 a cena
	# antiga já sai da árvore no mesmo frame, então aqui isto é só uma guarda
	# caso o comportamento mude; o vazamento que existe de fato é abaixo.)
	var cena_velha := current_scene
	tr.cortar_para(CENA_B, 0.5)
	ok(preto.visible and preto.mouse_filter == Control.MOUSE_FILTER_STOP, "com o Preto visível, o Mouse Filter é Stop")
	clicar(pos)  # a cena antiga ainda existe neste frame; o 'pressed' dispararia na hora
	var vazou_velha: int = cena_velha.cliques - 1
	ok(vazou_velha == 0, "(guarda) clique no mesmo frame do corte não atinge a cena antiga", str(vazou_velha))

	# ...nem para a cena nova enquanto o preto está sendo segurado
	await frames(6)
	ok(cena_atual_path() == CENA_B and preto.visible, "(cena nova já está por baixo do Preto)")
	clicar(pos)
	await frames(2)
	ok(current_scene.cliques == 0, "clique durante o 'segurar' não vazou para a cena nova", str(current_scene.cliques))

	# depois do corte, tudo volta ao normal
	await esperar_corte()
	ok(preto.mouse_filter == Control.MOUSE_FILTER_IGNORE, "depois do corte o Mouse Filter volta a Ignore")
	clicar(pos)
	await frames(2)
	ok(current_scene.cliques == 1, "depois do corte, o clique volta a chegar na cena", str(current_scene.cliques))


func _t_save() -> void:
	titulo("Save")
	apagar_save()
	gm.capitulo_atual = 1
	sv.flags = {}

	ok(not sv.existe_save(), "sem arquivo: existe_save() é falso")
	ok(not sv.carregar(), "sem arquivo: carregar() devolve falso")

	# salvar()
	sv.flags = {"cap1_alavanca": true, "contador": 3}
	sv.salvar()
	ok(sv.existe_save(), "salvar() cria user://save.json")
	var cru: Variant = ler_save_cru()
	ok(cru is Dictionary and cru.get("versao") == 1.0, "JSON tem versao = 1", str(cru))
	ok(cru is Dictionary and cru.get("capitulo") == 1.0, "JSON tem o capitulo atual", str(cru))
	ok(cru is Dictionary and cru.get("flags", {}).get("cap1_alavanca") == true, "JSON tem as flags", str(cru))

	# autosave pelo sinal
	apagar_save()
	sv.flags = {"cap1_alavanca": true}
	gm.iniciar_capitulo(1)
	ok(sv.existe_save(), "iniciar_capitulo salva sozinho (Save.salvar ligado a capitulo_mudou)")
	cru = ler_save_cru()
	ok(cru is Dictionary and cru.get("capitulo") == 1.0 and cru.get("flags", {}).get("cap1_alavanca") == true, "o autosave gravou capítulo e flags", str(cru))
	await esperar_corte()

	# round trip
	gm.capitulo_atual = 7
	sv.flags = {}
	ok(sv.carregar(), "carregar() devolve verdadeiro com save válido")
	ok(gm.capitulo_atual == 1 and typeof(gm.capitulo_atual) == TYPE_INT, "capítulo volta como inteiro", str(gm.capitulo_atual))
	ok(sv.flags.get("cap1_alavanca") == true, "flags voltam do arquivo")

	# o JSON entrega decimal (3.0): vira inteiro
	escrever_save('{"versao": 1, "capitulo": 3.0, "flags": {"x": 1}}')
	ok(sv.carregar() and gm.capitulo_atual == 3 and typeof(gm.capitulo_atual) == TYPE_INT, "capitulo 3.0 do JSON vira int 3", str(gm.capitulo_atual))

	# chaves faltando: valem os padrões
	gm.capitulo_atual = 5
	sv.flags = {"sobrou": true}
	escrever_save('{"versao": 1}')
	ok(sv.carregar() and gm.capitulo_atual == 1 and sv.flags.is_empty(), "sem 'capitulo' e sem 'flags': capítulo 1 e flags vazias", "cap=%d flags=%s" % [gm.capitulo_atual, sv.flags])
	escrever_save('{"versao": 1, "capitulo": 2, "flags": {"a": true}}')
	sv.carregar()
	escrever_save('{"versao": 1, "capitulo": 4}')
	ok(sv.carregar() and gm.capitulo_atual == 4 and sv.flags.is_empty(), "sem 'flags': flags ficam vazias (não sobra lixo)", str(sv.flags))
	escrever_save('{"versao": 1, "flags": {"b": 1}}')
	ok(sv.carregar() and gm.capitulo_atual == 1 and sv.flags.get("b") == 1.0, "sem 'capitulo': capítulo 1, flags carregadas")

	# tipos errados dentro de um JSON válido
	escrever_save('{"versao": 1, "capitulo": "abc", "flags": [1, 2]}')
	ok(sv.carregar() and gm.capitulo_atual == 1 and sv.flags.is_empty(), "capitulo texto e flags lista: usa os padrões, sem erro de script")
	escrever_save('{"versao": 1, "capitulo": {"a": 1}, "flags": null}')
	ok(sv.carregar() and gm.capitulo_atual == 1 and sv.flags.is_empty(), "capitulo dicionário e flags nulas: usa os padrões, sem erro de script")

	# save corrompido: devolve falso, ignora o arquivo e não mexe no estado
	var corrompidos := {
		"arquivo vazio": "",
		"lixo que não é JSON": "{{{ isto não é json",
		"JSON cortado no meio": '{"versao": 1, "capitulo": ',
		"lista em vez de dicionário": "[1, 2, 3]",
		"número solto": "42",
		"texto solto": '"oi"',
		"null": "null",
	}
	for nome in corrompidos:
		gm.capitulo_atual = 6
		sv.flags = {"intacta": true}
		escrever_save(corrompidos[nome])
		var r: bool = sv.carregar()
		ok(not r and gm.capitulo_atual == 6 and sv.flags == {"intacta": true}, "corrompido (%s): falso e estado intacto" % nome, "r=%s cap=%d flags=%s" % [r, gm.capitulo_atual, sv.flags])

	# não conseguir gravar: o save.json é uma pasta
	apagar_save()
	var real := ProjectSettings.globalize_path(SAVE)
	DirAccess.make_dir_absolute(real)
	sv.salvar()
	ok(true, "salvar() sem conseguir abrir o arquivo não derruba o jogo")
	ok(not sv.existe_save() and not sv.carregar(), "com save.json ilegível: existe_save e carregar dão falso")
	DirAccess.remove_absolute(real)
	apagar_save()
	gm.capitulo_atual = 1
	sv.flags = {}


func _t_gravar() -> void:
	titulo("Processo 1: gravar")
	apagar_save()
	ok(not sv.existe_save(), "começa sem save")
	sv.flags = {"cap1_alavanca": true}
	gm.iniciar_capitulo(1)
	await esperar_corte()
	ok(sv.existe_save(), "o save foi gravado pelo autosave")


func _t_ler() -> void:
	titulo("Processo 2: ler (jogo reaberto)")
	ok(sv.flags.is_empty() and gm.capitulo_atual == 1, "processo novo começa com flags vazias")
	ok(sv.existe_save(), "existe_save() verdadeiro depois de reabrir o jogo")
	gm.capitulo_atual = 9
	ok(sv.carregar(), "carregar() verdadeiro")
	ok(gm.capitulo_atual == 1, "capítulo restaurado", str(gm.capitulo_atual))
	ok(sv.flags.get("cap1_alavanca") == true, "flag restaurada")
	apagar_save()
