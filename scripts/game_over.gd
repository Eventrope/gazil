extends Control

@onready var result_label: Label = $CenterContainer/VBoxContainer/ResultLabel
@onready var reason_label: Label = $CenterContainer/VBoxContainer/ReasonLabel
@onready var days_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/DaysStat
@onready var trades_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/TradesStat
@onready var distance_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/DistanceStat
@onready var events_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/EventsStat
@onready var earned_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/EarnedStat
@onready var final_credits_stat: Label = $CenterContainer/VBoxContainer/StatsContainer/FinalCreditsStat

# Optional nodes for competition mode
var leaderboard_container: VBoxContainer = null
var awards_container: VBoxContainer = null

func _ready() -> void:
	var game_over: Dictionary = GameState.check_game_over()
	var player: Player = GameState.player

	if GameState.competition_mode:
		_setup_competition_results(game_over)
	else:
		_setup_classic_results(game_over)

	# Display statistics
	days_stat.text = "Days Played: %d" % player.day
	trades_stat.text = "Trades Made: %d" % player.statistics.get("trades_made", 0)
	distance_stat.text = "Distance Traveled: %d light years" % player.statistics.get("distance_traveled", 0)
	events_stat.text = "Events Survived: %d" % player.statistics.get("events_survived", 0)
	earned_stat.text = "Total Credits Earned: %s" % _format_number(player.statistics.get("credits_earned", 0))
	final_credits_stat.text = "Final Credits: %s" % _format_number(player.credits)

	if game_over["won"]:
		final_credits_stat.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))

func _setup_classic_results(game_over: Dictionary) -> void:
	if game_over["won"]:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	else:
		result_label.text = "GAME OVER"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	reason_label.text = game_over["reason"]

func _setup_competition_results(game_over: Dictionary) -> void:
	var rank: int = game_over.get("rank", 0)

	if game_over["won"]:
		result_label.text = "1ST PLACE!"
		result_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold
	elif rank == 2:
		result_label.text = "2ND PLACE"
		result_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))  # Silver
	elif rank == 3:
		result_label.text = "3RD PLACE"
		result_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))  # Bronze
	elif rank > 0:
		result_label.text = "#%d PLACE" % rank
		result_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	else:
		result_label.text = "ELIMINATED"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))

	reason_label.text = game_over["reason"]

	# Add final leaderboard
	_add_final_leaderboard()

	# Add awards
	_add_awards()

func _add_final_leaderboard() -> void:
	var stats_container = $CenterContainer/VBoxContainer/StatsContainer
	if stats_container == null:
		return

	# Create leaderboard section
	leaderboard_container = VBoxContainer.new()
	leaderboard_container.name = "LeaderboardSection"

	var separator: HSeparator = HSeparator.new()
	leaderboard_container.add_child(separator)

	var title: Label = Label.new()
	title.text = "FINAL STANDINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	leaderboard_container.add_child(title)

	var leaderboard: Array = BotManager.get_leaderboard()
	for entry in leaderboard:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var rank_label: Label = Label.new()
		rank_label.text = "#%d" % entry["rank"]
		rank_label.custom_minimum_size.x = 40
		hbox.add_child(rank_label)

		var name_label: Label = Label.new()
		name_label.text = entry["name"]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if entry["is_player"]:
			name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
			name_label.text += " (You)"
		elif entry.get("is_eliminated", false):
			name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			name_label.text += " [OUT]"
		elif entry.has("color"):
			name_label.add_theme_color_override("font_color", entry["color"])

		hbox.add_child(name_label)

		var credits_label: Label = Label.new()
		credits_label.text = _format_number(entry["credits"])
		credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		credits_label.custom_minimum_size.x = 100
		hbox.add_child(credits_label)

		leaderboard_container.add_child(hbox)

	stats_container.add_child(leaderboard_container)
	stats_container.move_child(leaderboard_container, 0)

func _add_awards() -> void:
	var stats_container = $CenterContainer/VBoxContainer/StatsContainer
	if stats_container == null:
		return

	# Create awards section
	awards_container = VBoxContainer.new()
	awards_container.name = "AwardsSection"

	var separator: HSeparator = HSeparator.new()
	awards_container.add_child(separator)

	var title: Label = Label.new()
	title.text = "AWARDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	awards_container.add_child(title)

	var awards: Array = _calculate_awards()
	for award in awards:
		var hbox: HBoxContainer = HBoxContainer.new()

		var trophy: Label = Label.new()
		trophy.text = award["emoji"]
		trophy.custom_minimum_size.x = 30
		hbox.add_child(trophy)

		var award_label: Label = Label.new()
		award_label.text = "%s: %s" % [award["title"], award["winner"]]
		award_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		if award.get("is_player", false):
			award_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))

		hbox.add_child(award_label)
		awards_container.add_child(hbox)

	stats_container.add_child(awards_container)

func _calculate_awards() -> Array:
	var awards: Array = []
	var player: Player = GameState.player
	var bots: Array = BotManager.bots

	# Most Trades
	var most_trades := {"name": "You", "count": player.statistics.get("trades_made", 0), "is_player": true}
	for bot in bots:
		if bot.statistics.get("trades_made", 0) > most_trades["count"]:
			most_trades = {"name": bot.bot_name, "count": bot.statistics["trades_made"], "is_player": false}
	awards.append({
		"emoji": "📈",
		"title": "Most Trades",
		"winner": "%s (%d)" % [most_trades["name"], most_trades["count"]],
		"is_player": most_trades["is_player"]
	})

	# Most Distance
	var most_distance := {"name": "You", "count": player.statistics.get("distance_traveled", 0), "is_player": true}
	for bot in bots:
		if bot.statistics.get("distance_traveled", 0) > most_distance["count"]:
			most_distance = {"name": bot.bot_name, "count": bot.statistics["distance_traveled"], "is_player": false}
	awards.append({
		"emoji": "🚀",
		"title": "Most Distance",
		"winner": "%s (%d ly)" % [most_distance["name"], most_distance["count"]],
		"is_player": most_distance["is_player"]
	})

	# Most Events Survived
	var most_events := {"name": "You", "count": player.statistics.get("events_survived", 0), "is_player": true}
	for bot in bots:
		if bot.statistics.get("events_survived", 0) > most_events["count"]:
			most_events = {"name": bot.bot_name, "count": bot.statistics["events_survived"], "is_player": false}
	awards.append({
		"emoji": "🛡️",
		"title": "Luckiest Survivor",
		"winner": "%s (%d events)" % [most_events["name"], most_events["count"]],
		"is_player": most_events["is_player"]
	})

	# Most Dramatic Collapse (lowest credits among eliminated bots, or player if eliminated)
	var eliminated_bots: Array = []
	for bot in bots:
		if bot.is_eliminated:
			eliminated_bots.append(bot)

	if not eliminated_bots.is_empty():
		var worst := eliminated_bots[0]
		for bot in eliminated_bots:
			if bot.credits < worst.credits:
				worst = bot
		awards.append({
			"emoji": "💥",
			"title": "Most Dramatic Collapse",
			"winner": worst.bot_name,
			"is_player": false
		})

	return awards

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
	get_tree().change_scene_to_file("res://scenes/game_setup.tscn")

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
