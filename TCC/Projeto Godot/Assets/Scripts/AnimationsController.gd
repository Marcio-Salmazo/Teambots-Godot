extends Node
# DECIDE QUAL ANIMAÇÃO O SPRITE DO PLAYER TOCA EM CADA ESTADO DA FSM

# REFERÊNCIAS EXTERNAS AO SPRITE DO PLAYER
@export var player_sprite_path: NodePath
@onready var player_sprite: AnimatedSprite2D = get_node_or_null(player_sprite_path)

# ------------------------------------------------------------------------------
# NOMES DAS ANIMAÇÕES
# Cada lista é testada em ordem e vale a primeira que existir no SpriteFrames do
# sprite. Assim as cenas antigas ("Player Idle" / "Player Walk") e a cena da Lucy
# ("andando") funcionam com o mesmo script. Para usar outro nome, é só incluí-lo
# aqui ou editar a lista no Inspetor do nó "Animations Controller".
@export var walk_animations: Array[StringName] = [&"Player Walk", &"andando"]
@export var idle_animations: Array[StringName] = [&"Player Idle", &"parado"]

## Quando não existe animação de "parado", o personagem congela neste frame da
## animação de andar (frame 0 da Lucy = em pé, pés juntos).
@export var idle_fallback_frame: int = 0

# ------------------------------------------------------------------------------
# VERIFICAÇÃO INICIAL SE O SPRITE DO PLAYER FOI ENCONTRADO
func _ready():
	if player_sprite == null:
		push_error("AnimationController: Player Sprite não encontrado.")

# ------------------------------------------------------------------------------
# PROCURA A PRIMEIRA ANIMAÇÃO DA LISTA QUE EXISTE NO SPRITEFRAMES
func _first_existing(names: Array[StringName]) -> StringName:
	if player_sprite == null or player_sprite.sprite_frames == null:
		return &""
	for anim in names:
		if player_sprite.sprite_frames.has_animation(anim):
			return anim
	return &""

# ------------------------------------------------------------------------------
# FUNÇÕES DE REPRODUÇÃO DAS ANIMAÇÕES
func _play(anim_name: StringName) -> void:
	# Evita reiniciar uma animação que já está sendo executada. Também confere
	# is_playing(): o nó pode já vir da cena com essa animação selecionada, só que
	# parada, e nesse caso é preciso chamar play() mesmo com o nome igual.
	if player_sprite.animation != anim_name or not player_sprite.is_playing():
		player_sprite.play(anim_name)

func _play_walk() -> void:
	if player_sprite == null:
		return
	var anim := _first_existing(walk_animations)
	if anim.is_empty():
		push_warning("AnimationController: nenhuma animação de andar encontrada (testadas: %s)." % [walk_animations])
		return
	_play(anim)

func _play_idle() -> void:
	if player_sprite == null:
		return
	# Se existir uma animação de parado, toca ela.
	var idle := _first_existing(idle_animations)
	if not idle.is_empty():
		_play(idle)
		return
	# Senão, congela um frame da animação de andar.
	var walk := _first_existing(walk_animations)
	if walk.is_empty():
		push_warning("AnimationController: nenhuma animação de parado ou de andar encontrada.")
		return
	player_sprite.animation = walk
	player_sprite.stop()
	var ultimo_frame := player_sprite.sprite_frames.get_frame_count(walk) - 1
	player_sprite.frame = clampi(idle_fallback_frame, 0, ultimo_frame)

# ------------------------------------------------------------------------------
# GERENCIAMENTO DAS ANIMAÇÕES DO JOGADOR
func update_player_animation(state: int):

	match state:
		PlayerStateMachine.PlayerState.IDLE, PlayerStateMachine.PlayerState.DIALOGUE:
			_play_idle()
		PlayerStateMachine.PlayerState.WALK, PlayerStateMachine.PlayerState.DASH:
			_play_walk()
