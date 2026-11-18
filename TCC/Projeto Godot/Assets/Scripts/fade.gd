extends CanvasLayer

const FADE_OUT_TIME := 0.3
const FADE_IN_TIME := 0.3

var transitioning := false

var _rect: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func change_scene(path: String) -> void:
	if transitioning:
		return
	transitioning = true

	await _fade_to(1.0, FADE_OUT_TIME)

	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Fade: falha ao carregar '%s' (erro %d)" % [path, err])
		await _fade_to(0.0, FADE_IN_TIME)
		transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame

	await _fade_to(0.0, FADE_IN_TIME)
	transitioning = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", alpha, duration)
	await tween.finished
