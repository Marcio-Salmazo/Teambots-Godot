extends Node
## Autoload "GameManager" (dono: P1).
## Guarda o estado global do jogo e avisa os outros sistemas quando algo muda.
## Quem declara o modo é a fase (Fase.modo); aqui só se registra e repassa.
##
## Sem class_name de propósito: o nome "GameManager" já é o do autoload, e
## declarar os dois dá erro de "classe esconde autoload".

enum Modo { SOMBRA, PROTAGONISTA, TRANSICAO }

## Emitido só quando o modo realmente muda.
signal modo_mudou(novo: Modo)
## Emitido ao iniciar um capítulo. O Save escuta este sinal para salvar sozinho.
signal capitulo_mudou(numero: int)

const TENSAO_MAXIMA := 3

## Número do capítulo -> cena inicial dele. Novas entradas entram conforme
## as fases existirem.
const CAPITULOS := {
	1: "res://fases/cap1/memoria_sombra.tscn",
}

var modo_atual: Modo = Modo.SOMBRA
var capitulo_atual: int = 1

## Inteiro de 0 a 3 usado pelos eventos de terror (P6). Volta a 0 a cada
## capítulo novo. O setter segura o valor dentro da faixa.
var tensao: int = 0:
	set(valor):
		tensao = clampi(valor, 0, TENSAO_MAXIMA)


## Se o modo pedido já é o atual, não faz nada (evita sinal repetido).
func mudar_modo(novo: Modo) -> void:
	if novo == modo_atual:
		return
	modo_atual = novo
	modo_mudou.emit(novo)


## Grava o capítulo, zera a tensão, avisa, volta o modo para SOMBRA e pede à
## Transicao um corte para a cena inicial do capítulo. Número fora do mapa:
## erro claro no Depurador e nada muda.
func iniciar_capitulo(numero: int) -> void:
	if not CAPITULOS.has(numero):
		push_error("GameManager: o capítulo %d não existe em CAPITULOS (existentes: %s)." % [numero, CAPITULOS.keys()])
		return

	capitulo_atual = numero
	tensao = 0
	capitulo_mudou.emit(numero)
	mudar_modo(Modo.SOMBRA)
	Transicao.cortar_para(CAPITULOS[numero])
