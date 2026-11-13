extends Node2D
func _ready() -> void:
	var marcador := get_node_or_null("Node/" + Global.from_word + "Pos")
	if marcador:
		$Player/Player.global_position = marcador.global_position	
func _process(delta: float) -> void:
	pass
