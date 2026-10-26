# Define que o Script opere com o objeto do tipo Node (Genérico)
extends Node
# @onready significa que essa variável só será atribuída quando o nó já estiver pronto na cena
@onready var heartbeat = get_node("/root/Dungeon Scene/Music Assets/Heartbeat")

# @export faz a variável aparecer no Inspector da Godot.
# Em resumo, podemos mudar o valor direto na interface do editor, sem mexer no código.
# OBS: o operador := significa declaração com tipagem automática (type inference)
@export var ansiedade := 0.0
@export var taxa_crescimento := 0.5
@export var ansiedade_max := 100.0

# Função chamada a cada frame, de acordo com a taxa de quadros do jogo. 
# É usada para tudo que depende de tempo contínuo, como animações, efeitos visuais, ou contadores.
# O parâmetro delta representa o tempo decorrido desde o último frame.
func _process(delta):
	
	# Define um acrescimo ao parâmetro de ansiedade de acordo com o tempo decorrido
	ansiedade += taxa_crescimento * delta
	# Define os limites minimos e máximos da ansiedade
	ansiedade = min(ansiedade, ansiedade_max)
	# O som acelera progressivamente de acordo com o grau de ansiedade
	heartbeat.pitch_scale = 1.0 + (ansiedade * 0.1)
	
	# log
	# print(ansiedade)
