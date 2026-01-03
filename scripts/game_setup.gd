extends Control

# Game setup screen - allows configuration before starting a new game

@onready var mode_option: OptionButton = $CenterContainer/VBoxContainer/ModeContainer/ModeOption
@onready var bot_count_slider: HSlider = $CenterContainer/VBoxContainer/CompetitionSettings/BotCountContainer/BotCountSlider
@onready var bot_count_label: Label = $CenterContainer/VBoxContainer/CompetitionSettings/BotCountContainer/BotCountLabel
@onready var difficulty_option: OptionButton = $CenterContainer/VBoxContainer/CompetitionSettings/DifficultyContainer/DifficultyOption
@onready var game_length_option: OptionButton = $CenterContainer/VBoxContainer/CompetitionSettings/GameLengthContainer/GameLengthOption
@onready var debug_check: CheckBox = $CenterContainer/VBoxContainer/CompetitionSettings/DebugContainer/DebugCheck
@onready var competition_settings: VBoxContainer = $CenterContainer/VBoxContainer/CompetitionSettings

var competition_mode := false

func _ready() -> void:
	# Set up mode options
	mode_option.add_item("Classic Mode", 0)
	mode_option.add_item("Competition Mode", 1)
	mode_option.selected = 0

	# Set up difficulty options
	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Medium", 1)
	difficulty_option.add_item("Hard", 2)
	difficulty_option.selected = 1

	# Set up game length options
	game_length_option.add_item("100 Days (Short)", 0)
	game_length_option.add_item("200 Days (Standard)", 1)
	game_length_option.add_item("300 Days (Long)", 2)
	game_length_option.selected = 1

	# Set up bot count slider
	bot_count_slider.min_value = 3
	bot_count_slider.max_value = 10
	bot_count_slider.value = 5
	bot_count_slider.step = 1
	_update_bot_count_label(5)

	# Initially hide competition settings
	competition_settings.hide()

func _on_mode_option_item_selected(index: int) -> void:
	competition_mode = index == 1
	if competition_mode:
		competition_settings.show()
	else:
		competition_settings.hide()

func _on_bot_count_slider_value_changed(value: float) -> void:
	_update_bot_count_label(int(value))

func _update_bot_count_label(count: int) -> void:
	bot_count_label.text = "%d Opponents" % count

func _on_start_pressed() -> void:
	var num_bots: int = int(bot_count_slider.value)

	var difficulty_str := "medium"
	match difficulty_option.selected:
		0:
			difficulty_str = "easy"
		1:
			difficulty_str = "medium"
		2:
			difficulty_str = "hard"

	var game_days := 200
	match game_length_option.selected:
		0:
			game_days = 100
		1:
			game_days = 200
		2:
			game_days = 300

	# Set debug mode
	GameState.debug_bots = debug_check.button_pressed

	# Start the game with selected settings
	GameState.start_new_game(competition_mode, num_bots, difficulty_str, game_days)
	get_tree().change_scene_to_file("res://scenes/ship_selection.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
