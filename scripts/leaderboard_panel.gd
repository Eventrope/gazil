extends PanelContainer
class_name LeaderboardPanel

# Displays the competition leaderboard

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var entries_container: VBoxContainer = $VBoxContainer/ScrollContainer/EntriesContainer
@onready var collapse_button: Button = $VBoxContainer/CollapseButton

var is_collapsed := true

func _ready() -> void:
	if not GameState.competition_mode:
		hide()
		return

	collapse_button.pressed.connect(_on_collapse_pressed)
	refresh()

	# Auto-refresh when bots are processed
	GameState.bots_processed.connect(_on_bots_processed)
	GameState.day_advanced.connect(_on_day_advanced)

func _on_bots_processed(_actions: Array) -> void:
	refresh()

func _on_day_advanced(_day: int) -> void:
	refresh()

func refresh() -> void:
	if not GameState.competition_mode:
		hide()
		return

	show()

	# Clear existing entries
	for child in entries_container.get_children():
		child.queue_free()

	var leaderboard: Array = BotManager.get_leaderboard()

	if is_collapsed:
		# Show only top 3 and player position
		_add_collapsed_view(leaderboard)
	else:
		# Show full leaderboard
		_add_full_view(leaderboard)

func _add_collapsed_view(leaderboard: Array) -> void:
	title_label.text = "LEADERBOARD (Top 3)"

	var player_shown := false
	var count := 0

	for entry in leaderboard:
		if count < 3:
			_add_entry(entry)
			if entry["is_player"]:
				player_shown = true
			count += 1
		elif entry["is_player"] and not player_shown:
			# Add separator
			var sep: Label = Label.new()
			sep.text = "..."
			sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			entries_container.add_child(sep)
			_add_entry(entry)
			break

	collapse_button.text = "Show All"

func _add_full_view(leaderboard: Array) -> void:
	title_label.text = "LEADERBOARD"

	for entry in leaderboard:
		_add_entry(entry)

	collapse_button.text = "Collapse"

func _add_entry(entry: Dictionary) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Rank
	var rank_label: Label = Label.new()
	rank_label.text = "#%d" % entry["rank"]
	rank_label.custom_minimum_size.x = 40
	hbox.add_child(rank_label)

	# Name
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

	# Credits
	var credits_label: Label = Label.new()
	credits_label.text = _format_credits(entry["credits"])
	credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	credits_label.custom_minimum_size.x = 80
	hbox.add_child(credits_label)

	entries_container.add_child(hbox)

func _format_credits(amount: int) -> String:
	if amount >= 1000000:
		return "%.1fM" % (amount / 1000000.0)
	elif amount >= 1000:
		return "%.1fK" % (amount / 1000.0)
	else:
		return str(amount)

func _on_collapse_pressed() -> void:
	is_collapsed = not is_collapsed
	refresh()
