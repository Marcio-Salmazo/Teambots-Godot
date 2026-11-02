extends Area2D

## Nó que esta área deve seguir (ex.: o Sprite2D do ghost).
@export var alvo: Node2D
## Deslocamento em relação ao centro do alvo.
@export var deslocamento: Vector2 = Vector2.ZERO

## Marque SOMENTE na menor área: ao tocar o player, aplica a penalidade e o fantasma some.
## As áreas maiores ficam desmarcadas e só cuidam do áudio.
@export var causa_contato: bool = false
## Quanto do fator do player é tirado por toque (0.25 = 25 pontos percentuais).
@export var penalidade: float = 0.25

@onready var reprodutor_audio = $AudioStreamPlayer2D
@onready var fantasma := get_parent() as FantasmaSombra


func _physics_process(_delta: float) -> void:
	if is_instance_valid(alvo):
		global_position = alvo.global_position + deslocamento

	if causa_contato and fantasma != null and fantasma.ativo:
		for corpo in get_overlapping_bodies():
			var jogador := corpo as PlayerController
			if jogador:
				jogador.levar_penalidade(penalidade)
				fantasma.sumir()  # desativa o fantasma: para este script também
				return


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and reprodutor_audio.stream != null and not reprodutor_audio.playing:
		reprodutor_audio.play()


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		reprodutor_audio.stop()
