
extends RichTextEffect

# Nome da tag BBCode personalizada
var bbcode := "bobbing"

# Configurações do movimento
@export var amplitude: float = 1.0
@export var speed: float = 4.0
@export var frequency: float = 0.5


func _process_custom_fx(char_fx: CharFXTransform) -> bool:

	# Calcula a movimentação individual de cada caractere
	var movement = sin(
		char_fx.elapsed_time * speed +
		char_fx.relative_index * frequency
	)

	# Mantém o deslocamento alinhado aos pixels
	char_fx.offset.y += round(movement * amplitude)

	return true
