# ==============================================================================
# SCRIPT DESENVOLVIDO PARA LIDAR APENAS COM A EXECUÇÃO DO ATAQUE DO PLAYER
# ENVOLVENDO SINAIS E DETECÇÃO/CONTROLE DE HITBOX
# ==============================================================================
extends Node

# ------------------------------------------------------------------------------
# Sinais a serem enviados para os demais scripts associados

#zzzzzsignal ATK_CONTROLLER_ATK_STARTED
signal ATK_CONTROLLER_ATK_FINISHED

# ------------------------------------------------------------------------------
# Referência externa para o HitBox
@export var hitbox_path : NodePath
@onready var attack_hitbox : Area2D = get_node(hitbox_path)

# Referência externa para o Animator Controller
@export var animator_controller_path : NodePath
@onready var animator_controller = get_node(animator_controller_path)

# ==============================================================================
# FUNÇÃO READY PARA INICIALIZAÇÃO
# ==============================================================================
func _ready():

	# Garante que a hitbox começa desligada
	if attack_hitbox:
		attack_hitbox.monitoring = false

	# conecta o sinal de fim da animação, proveniente do AnimatorController.gd
	# à função local 'end_attack' responsável por gerenciar as modificações
	# associadas ao fim do Ataque
	if animator_controller:
		if animator_controller.has_signal("ANIM_FINISHED_ATK"):
			animator_controller.ANIM_FINISHED_ATK.connect(end_attack)

# ==============================================================================
# FUNÇÃO QUE INICIALIZA O ATAQUE
# ==============================================================================
func start_attack():
	
	# ativa hitbox
	if attack_hitbox:
		attack_hitbox.monitoring = true
		
	# Emite um sinal que o fluxo foi iniciado (O qual servirá como referência
	# para os demais Scripts que lidam com a mecânica de ataque)
	# emit_signal("ATK_CONTROLLER_ATK_STARTED")

# ==============================================================================
# FINALIZAR ATAQUE
# ==============================================================================
func end_attack():
	
	# Desativa hitbox
	if attack_hitbox:
		attack_hitbox.monitoring = false
		
	# Emite um sinal que o fluxo foi encerrado (O qual servirá como referência
	# para o Script PlayerController.gd)
	emit_signal("ATK_CONTROLLER_ATK_FINISHED")
