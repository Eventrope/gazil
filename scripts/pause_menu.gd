extends CanvasLayer

signal resumed
signal save_requested
signal main_menu_requested

@onready var background: ColorRect = $Background
@onready var save_button: Button = $CenterContainer/Panel/VBoxContainer/ButtonContainer/SaveButton

var _is_visible := false

func _ready() -> void:
	# Ensure we can process input even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Only show pause menu during active gameplay
		if not GameState.is_game_active:
			return

		if _is_visible:
			hide_menu()
		else:
			show_menu()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	_is_visible = true
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	_is_visible = false
	visible = false
	if get_tree():
		get_tree().paused = false

func is_menu_visible() -> bool:
	return _is_visible

func _on_resume_pressed() -> void:
	hide_menu()
	resumed.emit()

func _on_save_pressed() -> void:
	if GameState.save_game():
		# Show brief confirmation
		save_button.text = "Saved!"
		save_button.disabled = true
		await get_tree().create_timer(1.0).timeout
		save_button.text = "Save Game"
		save_button.disabled = false
	else:
		save_button.text = "Save Failed"
		await get_tree().create_timer(1.0).timeout
		save_button.text = "Save Game"
	save_requested.emit()

func _on_main_menu_pressed() -> void:
	hide_menu()
	GameState.return_to_main_menu()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	main_menu_requested.emit()
