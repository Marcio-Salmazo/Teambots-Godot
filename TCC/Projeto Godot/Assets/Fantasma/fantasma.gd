class_name FantasmaSombra
extends Sprite2D

## Quem o fantasma persegue (o protagonista). Arraste o nó "Player" do jogador aqui.
@export var alvo: Node2D
## Velocidade de perseguição em pixels/segundo. O jogador anda a 125,
## então valores menores que isso dão ao jogador chance de fugir.
@export var velocidade: float = 70.0
@export var tempo_para_reaparecer: float = 2.0
@export var distancia_minima_do_jogador: float = 100.0
@export var spawn_aleatorio_no_inicio: bool = true

## Grupo dos Marker2D que servem de ponto de spawn.
const GRUPO_SPAWN := "spawn_fantasma"

var ativo := true
var posicao_inicial: Vector2


func _ready() -> void:
	posicao_inicial = global_position
	if alvo == null:
		push_warning("Fantasma: 'alvo' não definido. Arraste o jogador para o campo Alvo no Inspector.")
	if spawn_aleatorio_no_inicio:
		global_position = _sortear_posicao()
		reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if is_instance_valid(alvo):
		global_position = global_position.move_toward(alvo.global_position, velocidade * delta)


# Chamado pela hitbox quando o fantasma encosta no player.
func sumir() -> void:
	if not ativo:
		return
	ativo = false
	visible = false
	# DISABLED desliga o _physics_process e tira as Area2D filhas da física
	# (CollisionObject2D.disable_mode padrão = remover do mundo de física).
	process_mode = Node.PROCESS_MODE_DISABLED
	_parar_audios()

	# Timer da árvore (não do nó): continua rodando mesmo com o fantasma desativado.
	await get_tree().create_timer(tempo_para_reaparecer).timeout
	reaparecer()


func reaparecer() -> void:
	# Posição ANTES de reativar, para a hitbox não "ver" o player no lugar antigo.
	global_position = _sortear_posicao()
	# O projeto usa physics interpolation: sem isto o fantasma "deslizaria"
	# da posição antiga até a nova em vez de aparecer direto nela.
	reset_physics_interpolation()
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	ativo = true


## Sorteia um Marker2D do grupo que esteja longe o bastante do jogador.
## Se todos estiverem perto demais, usa o mais distante.
## Se não houver nenhum ponto no grupo, volta para a posição inicial.
func _sortear_posicao() -> Vector2:
	var pontos := get_tree().get_nodes_in_group(GRUPO_SPAWN)
	if pontos.is_empty():
		push_warning("Fantasma: nenhum Marker2D no grupo '%s'." % GRUPO_SPAWN)
		return posicao_inicial

	var validos: Array[Vector2] = []
	var mais_longe := posicao_inicial
	var maior_distancia := -1.0

	for ponto in pontos:
		var pos := (ponto as Node2D).global_position
		var distancia: float = INF
		if is_instance_valid(alvo):
			distancia = pos.distance_to(alvo.global_position)
		if distancia >= distancia_minima_do_jogador:
			validos.append(pos)
		if distancia > maior_distancia:
			maior_distancia = distancia
			mais_longe = pos

	var escolhido: Vector2 = mais_longe if validos.is_empty() else validos.pick_random()
	# Diagnóstico do spawn: pode apagar esta linha depois de testar.
	print("[SPAWN] pontos no grupo: %d | longe o bastante: %d | escolhido: %s" % [pontos.size(), validos.size(), escolhido])
	return escolhido


# Garante que o som de tensão das áreas pare quando o fantasma some.
# AudioStreamPlayer2D NÃO herda de AudioStreamPlayer, então o filtro precisa citar os dois.
func _parar_audios() -> void:
	for tipo in ["AudioStreamPlayer", "AudioStreamPlayer2D"]:
		for no in find_children("*", tipo, true, false):
			no.stop()
