extends CanvasLayer
## Autoload "Transicao" (dono: P1). Cena: transicao.tscn.
## Corte seco para outra cena (sem fade: é decisão do roteiro). Fica por cima
## de tudo (Layer 100, acima de diálogo e pausa) e continua rodando com o jogo
## pausado (Process Mode = Always, definido na cena).
##
## Sem class_name de propósito (conflitaria com o nome do autoload).

## Emitido quando a cena nova já está desenhando e o preto foi escondido.
signal corte_concluido

## Verdadeiro de quando o preto liga até o corte_concluido. A Pausa (P3) lê isto.
var em_corte: bool = false

@onready var preto: ColorRect = $Preto


func _ready() -> void:
	# Garante o estado inicial mesmo que alguém tenha deixado o Preto visível
	# no editor para enxergá-lo.
	preto.hide()


## Troca para a cena em 'caminho'. 'segurar' (opcional, em segundos) é quanto
## tempo ficar com o preto na tela depois que a cena nova já está carregada.
func cortar_para(caminho: String, segurar: float = 0.0) -> void:
	# 1. Corte em andamento: ignora o novo pedido.
	if em_corte:
		return

	# 2. Cena inexistente: erro no Depurador e nada acontece.
	if not ResourceLoader.exists(caminho):
		push_error("Transicao: a cena '%s' não existe." % caminho)
		return

	em_corte = true
	var estava_pausado := get_tree().paused

	# 3. Preto instantâneo (sem fade) e despausa, para a cena nova já nascer
	# rodando. Enquanto o preto está visível, ele também engole os cliques:
	# com Ignore, um clique no meio do corte vazaria para a cena velha (ou
	# para a nova, durante o 'segurar').
	preto.mouse_filter = Control.MOUSE_FILTER_STOP
	preto.show()
	get_tree().paused = false

	# 4. Pede a troca. Se a engine recusar, desfaz tudo para o jogo não ficar
	# preso numa tela preta.
	var erro := get_tree().change_scene_to_file(caminho)
	if erro != OK:
		push_error("Transicao: change_scene_to_file('%s') falhou (erro %d: %s)." % [caminho, erro, error_string(erro)])
		_encerrar(estava_pausado)
		return

	# 5. Dois frames: a troca só acontece no fim do frame atual, e o segundo
	# deixa a cena nova desenhar a primeira imagem por trás do preto.
	await get_tree().process_frame
	await get_tree().process_frame

	# 6. Segura o preto, se pedido.
	if segurar > 0.0:
		await get_tree().create_timer(segurar).timeout

	# 7. Esconde o preto, desliga em_corte e avisa.
	_encerrar(false)
	corte_concluido.emit()


func _encerrar(repausar: bool) -> void:
	preto.hide()
	preto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	em_corte = false
	if repausar:
		get_tree().paused = true
