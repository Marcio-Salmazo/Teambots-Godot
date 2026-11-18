extends Area2D

@export var sprite_alvo: Sprite2D
@export var nome: String

const STAIRS_SFX = preload("res://Assets/AudioStream/walkingStairs.wav")
# Deixe true para testar; depois de resolver, troque para false.
const DEBUG := true
# TESTE: com true, aperta interagir só toca o som e NÃO troca de cena.
# Depois do teste, troque para false para a escada voltar a funcionar.
const TESTE_SEM_TROCAR := false

var _player_na_area := false
var _usada := false

func _cena() -> String:
	return str(owner.name) if owner else str(name)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	if DEBUG:
		print("[escada] pronta em '%s' -> '%s'" % [_cena(), nome])

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = true
		if sprite_alvo:
			sprite_alvo.z_index = 0

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		_player_na_area = false
		if sprite_alvo:
			sprite_alvo.z_index = 3

# Não depende só do sinal body_entered: se o player nasce já dentro da área
# (caso do corredor), consulta a sobreposição direto na física.
func _player_dentro() -> bool:
	if _player_na_area:
		return true
	for b in get_overlapping_bodies():
		if b is CharacterBody2D:
			return true
	return false

# Toca o som num player filho da RAIZ da árvore: ele sobrevive à troca de cena,
# então o som não é cortado quando a cena atual é liberada.
func _tocar_som() -> void:
	var p := AudioStreamPlayer.new()
	p.stream = STAIRS_SFX
	if AudioServer.get_bus_index(&"SFX") != -1:
		p.bus = &"SFX"
	p.autoplay = true
	p.finished.connect(p.queue_free)
	if DEBUG:
		p.finished.connect(func(): print("[escada] som terminou de tocar"))
	get_tree().root.add_child.call_deferred(p)
	if DEBUG:
		print("[escada] som da escada (%.2fs, bus '%s') em '%s'" % [STAIRS_SFX.get_length(), p.bus, _cena()])
		for i in AudioServer.bus_count:
			print("[escada]   bus %d '%s' | %.1f dB | mudo=%s" % [i, AudioServer.get_bus_name(i), AudioServer.get_bus_volume_db(i), AudioServer.is_bus_mute(i)])

func _input(event: InputEvent) -> void:
	if _usada:
		return
	if event.is_action_pressed("interagir"):
		var dentro := _player_dentro()
		if DEBUG:
			print("[escada] 'interagir' em '%s' -> '%s' | dentro=%s" % [_cena(), nome, dentro])
		if not dentro:
			return
		_usada = true
		get_viewport().set_input_as_handled()
		_tocar_som()
		if TESTE_SEM_TROCAR:
			print("[escada] TESTE: cena NAO trocada, só o som")
			_usada = false
			return
		change_level.call_deferred()

func change_level() -> void:
	if nome.is_empty():
		push_error("pathway '%s' em '%s': 'nome' vazio no Inspector" % [name, owner.name])
		return
	if nome == "null":
		return
	var caminho := "res://Assets/Scenes/" + nome + ".tscn"
	if not ResourceLoader.exists(caminho):
		push_error("pathway '%s' em '%s': cena '%s' não existe" % [name, owner.name, caminho])
		return
	Global.from_world = owner.name
	Fade.change_scene(caminho)
