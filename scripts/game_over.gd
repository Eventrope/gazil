extends Control

@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var reason_label: Label = $CenterContainer/VBoxContainer/ReasonLabel
@onready var days_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/DaysStat
@onready var trades_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/TradesStat
@onready var distance_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/DistanceStat
@onready var events_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/EventsStat
@onready var earned_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/EarnedStat
@onready var final_credits_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/FinalCreditsStat

func _ready() -> void:
	var game_over := GameState.check_game_over()
	var player := GameState.player

	if game_over["won"]:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		result_label.text = "GAME OVER"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	reason_label.text = game_over["reason"]

	# Display statistics
	days_stat.text = "Days Played: %d" % player.day
	trades_stat.text = "Trades Made: %d" % player.statistics.get("trades_made", 0)
	distance_stat.text = "Distance Traveled: %d light years" % player.statistics.get("distance_traveled", 0)
	events_stat.text = "Events Survived: %d" % player.statistics.get("events_survived", 0)
	earned_stat.text = "Total Credits Earned: %s" % _format_number(player.statistics.get("credits_earned", 0))
	final_credits_stat.text = "Final Credits: %s" % _format_number(player.credits)

	if game_over["won"]:
		final_credits_stat.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))

func _format_number(num: int) -> String:
	var str_num := str(num)
	var result := ""
	var count := 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result

func _on_play_again_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
