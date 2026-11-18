extends CanvasLayer

@onready var escuro: ColorRect = $Escuro

var valor := 1.0

func _ready() -> void:
	definir(1.0)

func definir(novo_valor: float) -> void:
	valor = clampf(novo_valor, 0.4, 1.0)
	escuro.color = Color(0, 0, 0, 1.0 - valor)
