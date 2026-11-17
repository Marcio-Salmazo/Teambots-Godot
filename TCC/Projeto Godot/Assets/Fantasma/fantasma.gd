class_name FantasmaSombra
extends Sprite2D

## Quem o fantasma persegue (o protagonista). Arraste o nó "Player" do jogador aqui.
@export var alvo: Node2D
## Velocidade de perseguição em pixels/segundo. O jogador anda a 125,
## então valores menores que isso dão ao jogador chance de fugir.
@export var velocidade: float = 70.0
@export var tempo_para_reaparecer: float = 2.0
## Grupo dos Marker2D que servem de ponto de nascimento do fantasma.
@export var grupo_spawn: StringName = &"spawn_fantasma"
## Pontos mais perto que isso do jogador são descartados (evita nascer em cima dele).
## Se todos estiverem perto, sorteia entre todos.
@export var distancia_minima_spawn: float = 300.0

var ativo := true
var posicao_inicial: Vector2  # posição da cena: fallback se não houver Marker2D no grupo


func _ready() -> void:
	posicao_inicial = global_position
	if alvo == null:
		push_warning("Fantasma: 'alvo' não definido. Arraste o jogador para o campo Alvo no Inspector.")

	global_position = _escolher_spawn()
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
	global_position = _escolher_spawn()
	# O projeto usa physics interpolation: sem isto o fantasma "deslizaria"
	# da posição antiga até a inicial em vez de aparecer direto nela.
	reset_physics_interpolation()
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	ativo = true


# Garante que o som de tensão das áreas pare quando o fantasma some.
func _parar_audios() -> void:
	for no in find_children("*", "AudioStreamPlayer", true, false):
		no.stop()


# Sorteia um Marker2D do grupo, preferindo os que estão longe do jogador.
func _escolher_spawn() -> Vector2:
	var pontos: Array = get_tree().get_nodes_in_group(grupo_spawn)
	if pontos.is_empty():
		push_warning("Fantasma: nenhum nó no grupo '%s'; usando a posição da cena." % grupo_spawn)
		return posicao_inicial

	if is_instance_valid(alvo):
		var longe: Array = []
		for p: Node2D in pontos:
			if p.global_position.distance_to(alvo.global_position) >= distancia_minima_spawn:
				longe.append(p)
		if not longe.is_empty():
			pontos = longe

	return (pontos.pick_random() as Node2D).global_position
