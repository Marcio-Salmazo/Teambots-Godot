extends CanvasLayer

# REFERÊNCIAS À INTERFACE
@onready var dialogue_root: Control = $DialogueRoot
@onready var dialogue_text: RichTextLabel = $DialogueRoot/CenterContainer/DialogueText
@onready var continue_hint: Label = $DialogueRoot/ContinueHint


# CONFIGURAÇÕES DO TYPEWRITER
@export_group("Typewriter")
@export var characters_per_second: float = 25.0
@export var nome: String

var typing_active: bool = false
var typing_progress: float = 0.0
var hint_timer: float = 0.0

# FADE IN
@export_group("Fade In")
@export var initial_delay: float = 2.0
@export var fade_duration: float = 2.0

# JUMPSCARE
@onready var jumpscare_image: TextureRect = $JumpscareImage
@onready var jumpscare_sound: AudioStreamPlayer = $JumpscareSound
@onready var black_screen: ColorRect = $BlackScreen

var ending_dialogue := false
var jumpscare_active := false

@export_group("Jumpscare")
@export var jumpscare_delay: float = 1.0
@export var jumpscare_duration: float = 0.05

# CONFIGURAÇÕES
const ACTION_ADVANCE := &"avancar_dialogo"

# CONTROLE
var dialogue_index: int = 0
var dialogue_active: bool = false

# DADOS DA NARRATIVA
var dialogue_lines: Array[Dictionary] = [
	{
		"text": "VOCÊ SABE QUE NÃO ESTÁ BEM, NÉ?",
		"size": 100,
		"color": "#b3b3b3",
		"font": "res://Assets/Fonts/CrimsonRitual.ttf"
	},
	{
		"text": "Eu estou bem...",
		"size": 40,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "É sério... eu estou bem...",
		"size": 32,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "MAS VOCÊ SABE QUE NÃO ESTÁ BEM!",
		"size": 80,
		"color": "#b3b3b3",
		"font": "res://Assets/Fonts/CrimsonRitual.ttf"
	},
	{
		"text": "EU ESTOU BEM!",
		"size": 50,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "Eu estou bem...!",
		"size": 30,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "eu estou bem...",
		"size": 20,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "Eu...",
		"size": 15,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	},
	{
		"text": "Eu... estou bem?",
		"size": 12,
		"color": "#787878",
		"font": "res://Assets/Fonts/Pixelta.ttf"
	}
]

# --------------------------------------------------
# INICIALIZAÇÃO

func _ready() -> void:
	dialogue_text.bbcode_enabled = true
	var bobbing_effect = load("res://Assets/Scripts/BobbingEffect.gd").new()
	dialogue_text.install_effect(bobbing_effect)
	
	dialogue_root.show()
	continue_hint.hide() 
	
	dialogue_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_index = 0
	
	dialogue_root.modulate.a = 0.0
	show_current_line()
	
	await get_tree().create_timer(initial_delay).timeout
	
	var tween = create_tween()
	tween.tween_property(dialogue_root, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	dialogue_active = true
	
# --------------------------------------------------
# RECEBE O COMANDO DO JOGADOR

func _unhandled_input(event: InputEvent) -> void:
	if not dialogue_active:
		return
		
	if event.is_action_pressed(ACTION_ADVANCE):
		if event is InputEventKey and event.echo:
			return

		# Pega a referência do Viewport ANTES de qualquer chance de mudar de cena
		var vp = get_viewport()

		if typing_active:
			dialogue_text.visible_characters = -1
			typing_active = false
		else:
			advance_dialogue()
		
		# Verifica se a referência é válida antes de consumir o input
		if vp:
			vp.set_input_as_handled()

# --------------------------------------------------
# EXIBE A FALA ATUAL

func show_current_line() -> void:
	if dialogue_index >= dialogue_lines.size():
		end_dialogue()
		return

	var line: Dictionary = dialogue_lines[dialogue_index]

	dialogue_text.parse_bbcode("[bobbing]" + line.get("text", "") + "[/bobbing]")
	start_typing()

	dialogue_text.add_theme_font_size_override("normal_font_size", line.get("size", 28))
	dialogue_text.add_theme_color_override("default_color", Color(line.get("color", "#FFFFFF")))

	var font_path: String = line.get("font", "")
	if font_path != "":
		var custom_font := load(font_path) as Font
		if custom_font != null:
			dialogue_text.add_theme_font_override("normal_font", custom_font)
	else:
		dialogue_text.remove_theme_font_override("normal_font")

# --------------------------------------------------
# AVANÇA PARA A PRÓXIMA FALA

func advance_dialogue() -> void:
	if ending_dialogue:
		return

	if dialogue_index >= dialogue_lines.size() - 1:
		ending_dialogue = true
		dialogue_active = false
		dialogue_root.hide()
		
		# Faz o código pausar aqui e esperar a função inteira do jumpscare terminar
		await trigger_jumpscare()
		
		# Se precisar de um tempo extra ALÉM do jumpscare (ex: 1.5 segundos de tela preta), 
		# você pode adicionar um timer manual assim:
		await get_tree().create_timer(1.5).timeout
		
		change_level()
		
		return

	dialogue_index += 1
	show_current_line()

# --------------------------------------------------
# FINALIZA A NARRATIVA

func end_dialogue() -> void:
	dialogue_active = false
	dialogue_root.hide()

# --------------------------------------------------
# VERIFICA SE A NARRATIVA ESTÁ ATIVA

func is_dialogue_active() -> bool:
	return dialogue_active

# --------------------------------------------------
func _process(delta: float) -> void:
	
	if not typing_active:
		if dialogue_active and not ending_dialogue:
			hint_timer += delta
			if hint_timer >= 5.0 and not continue_hint.visible:
				continue_hint.show()
		
		if continue_hint.visible:
			continue_hint.modulate.a = abs(sin(Time.get_ticks_msec() * 0.003))
			
		return
		
	typing_progress += delta * characters_per_second
	var total_characters = dialogue_text.get_total_character_count()
	dialogue_text.visible_characters = min(int(typing_progress), total_characters)
		
	if dialogue_text.visible_characters >= total_characters:
		typing_active = false

# --------------------------------------------------
func start_typing() -> void:
	typing_progress = 0.0
	dialogue_text.visible_characters = 0
	typing_active = true
	
	hint_timer = 0.0
	continue_hint.hide()
	continue_hint.modulate.a = 1.0

# --------------------------------------------------
# FUNÇÃO DE GATILHO DO JUMPSCARE
func trigger_jumpscare() -> void:
	await get_tree().create_timer(jumpscare_delay).timeout
	
	jumpscare_image.show()
	jumpscare_sound.play()
	jumpscare_active = true

	await get_tree().create_timer(jumpscare_duration).timeout

	jumpscare_image.hide()
	black_screen.show()
	jumpscare_active = false

func change_level():
	get_tree().change_scene_to_file("res://Assets/Scenes/" + nome + ".tscn")
