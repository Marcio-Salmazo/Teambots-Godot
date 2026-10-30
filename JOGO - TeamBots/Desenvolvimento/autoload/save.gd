extends Node
## Autoload "Save" (dono: P1).
## Grava e lê user://save.json. Sem cena, só script.
##
## Formato: { "versao": 1, "capitulo": <int>, "flags": { "<nome>": <valor> } }
## "versao" serve para migrar saves antigos se o formato mudar.
## Sem class_name de propósito (conflitaria com o nome do autoload).

const CAMINHO := "user://save.json"
const VERSAO := 1

## Marcações livres, por exemplo Save.flags["cap1_alavanca"] = true quando o
## puzzle for resolvido.
var flags: Dictionary = {}


func _ready() -> void:
	# O sinal manda o número do capítulo; salvar() não recebe nada.
	GameManager.capitulo_mudou.connect(salvar.unbind(1))


func existe_save() -> bool:
	return FileAccess.file_exists(CAMINHO)


## Monta os três campos e grava. Se não abrir o arquivo, registra o erro com o
## código e sai, sem travar o jogo.
func salvar() -> void:
	var dados := {
		"versao": VERSAO,
		"capitulo": GameManager.capitulo_atual,
		"flags": flags,
	}

	var arquivo := FileAccess.open(CAMINHO, FileAccess.WRITE)
	if arquivo == null:
		push_error("Save: não foi possível abrir '%s' para escrita (erro %d: %s)." % [CAMINHO, FileAccess.get_open_error(), error_string(FileAccess.get_open_error())])
		return

	if not arquivo.store_string(JSON.stringify(dados, "\t")):
		push_error("Save: falha ao escrever em '%s' (erro %d)." % [CAMINHO, arquivo.get_error()])
	arquivo.close()


## Devolve true se carregou, false se não. Save inexistente, ilegível ou
## corrompido nunca derruba o jogo: o arquivo é ignorado e o estado atual fica
## como estava.
func carregar() -> bool:
	if not existe_save():
		return false

	var arquivo := FileAccess.open(CAMINHO, FileAccess.READ)
	if arquivo == null:
		push_error("Save: não foi possível abrir '%s' para leitura (erro %d: %s)." % [CAMINHO, FileAccess.get_open_error(), error_string(FileAccess.get_open_error())])
		return false

	var texto := arquivo.get_as_text()
	arquivo.close()

	# JSON.new().parse() em vez de JSON.parse_string(): o segundo imprime um
	# ERROR da engine no Depurador para um caso que aqui é tratado normalmente.
	var json := JSON.new()
	if json.parse(texto) != OK:
		push_warning("Save: save corrompido (linha %d: %s), ignorando '%s'." % [json.get_error_line(), json.get_error_message(), CAMINHO])
		return false

	var dados: Variant = json.data
	if not dados is Dictionary:
		push_warning("Save: save corrompido (não é um dicionário JSON), ignorando '%s'." % CAMINHO)
		return false

	# O JSON devolve número decimal (1.0): converter para inteiro. Chave
	# faltando (ou com tipo estranho) cai no padrão em vez de quebrar.
	var capitulo: Variant = dados.get("capitulo", 1)
	GameManager.capitulo_atual = int(capitulo) if (capitulo is float or capitulo is int) else 1

	var marcacoes: Variant = dados.get("flags", {})
	flags = marcacoes if marcacoes is Dictionary else {}
	return true
