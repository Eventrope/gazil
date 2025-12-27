extends Control

@onready var load_game_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/LoadGameButton

func _ready() -> void:
	# Disable load button if no save exists
	load_game_button.disabled = not GameState.has_save_game()

func _on_new_game_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _on_load_game_pressed() -> void:
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
