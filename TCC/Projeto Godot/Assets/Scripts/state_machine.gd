class_name StateMachine
extends Node

@export var initial_state: State
var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_child_transition)
		else:
			push_warning("StateMachine '%s': o filho '%s' não tem script que estende State e foi ignorado." % [get_path(), child.name])

	if initial_state == null:
		for child in get_children():
			if child is State:
				initial_state = child
				push_warning("StateMachine '%s': 'initial_state' não atribuído no Inspector. Usando '%s'." % [get_path(), child.name])
				break

	if initial_state == null:
		push_error("StateMachine '%s': nenhum State encontrado. Os nós filhos precisam ter um script que estende State." % get_path())
		return

	current_state = initial_state
	current_state.enter()

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

# Chamado pelos próprios estados através do sinal 'transitioned'.
func on_child_transition(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
	transition_to(new_state_name)

# Chamado de fora (ex.: Player/NPC) quando a troca não parte do estado atual.
func transition_to(new_state_name: String) -> void:
	var new_state: State = states.get(new_state_name.to_lower())
	if new_state == null:
		push_warning("StateMachine '%s': estado '%s' não existe. Disponíveis: %s" % [get_path(), new_state_name, states.keys()])
		return
	if new_state == current_state:
		return

	if current_state:
		current_state.exit()

	# Atualiza antes do enter(): se o enter() emitir 'transitioned', o guard de on_child_transition já enxerga o estado novo.
	current_state = new_state
	current_state.enter()

func is_in_state(state_name: String) -> bool:
	return current_state != null and current_state.name.to_lower() == state_name.to_lower()
