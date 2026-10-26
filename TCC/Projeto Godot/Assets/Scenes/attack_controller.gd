extends Node

# Permite definir no inspetor o objeto ideal
# Recebe o nó no caminho especificado previamente
@export var hitbox_path: NodePath
@onready var hitbox = get_node(hitbox_path)

# var animation_controller recebe os dados do nó Player Animations
@export var animation_controller_path : NodePath
@onready var animation_controller = get_node(animation_controller_path)

var attacking := false # Flag para o status do ataque

# ==================================================================================================
# 									FUNÇÕES DO SCRIPT
# ==================================================================================================

# Função para inicializar o ataque
func handle_attack():
	
	# Caso a flag já indique um ataque em andamento, a função é encerrada
	if attacking:
		return
		
	# Ativa a flag da função
	attacking = true
	# Ativa o parâmetro de monitoramento da hitbox de ataque
	hitbox.monitoring = true

# ..................................................................................................

func _process(delta: float) -> void:
	
	# A variável que se conecta ao controlador de ataques executa a função Update_state
	# responsável por pegar o estado atual do personagem e aplicar o evento de ataque
	if Input.is_action_just_pressed("attack"):
		handle_attack()
	

	# Caso a flag indique que não há um ataque em andamento, a função é encerrada
	#if not attacking:
		#return
	
	
	## O tempo de ataque é reduzido de acordo com o tempo
	#attack_timer -= delta
	## Caso o tempo acabe, a flag é atualizada e o parâmetro de 
	## monitoramento da hitbox de ataque é desativado
	#if attack_timer <= 0:
		#attacking = false
		#hitbox.monitoring = false
		
	# Chama a função responsável por atualizar as animações de acordo com o status do Jogador
	#animation_controller.update_event_attack(attacking)	
