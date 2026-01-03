extends PanelContainer
class_name BotNewsPopup

# Shows a "Meanwhile..." summary of bot actions after player travel

signal closed()

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var news_container: VBoxContainer = $VBoxContainer/ScrollContainer/NewsContainer
@onready var close_button: Button = $VBoxContainer/CloseButton

var news_items: Array = []

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	hide()

func show_news(bot_actions: Array) -> void:
	if bot_actions.is_empty():
		closed.emit()
		return

	# Clear existing news
	for child in news_container.get_children():
		child.queue_free()

	# Get recent bot news from BotManager
	news_items = BotManager.get_recent_news(10)

	if news_items.is_empty():
		# No news generated, just show a summary
		_add_summary(bot_actions)
	else:
		_add_headlines()

	show()

func _add_summary(bot_actions: Array) -> void:
	title_label.text = "MEANWHILE..."

	var action_counts := {}
	for action in bot_actions:
		var action_type: String = action.get("action", "unknown")
		action_counts[action_type] = action_counts.get(action_type, 0) + 1

	var summary: Label = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.text = "While you were traveling, your competitors were busy:\n\n"

	if action_counts.get("buy", 0) > 0 or action_counts.get("sell", 0) > 0:
		summary.text += "• %d trades were made\n" % (action_counts.get("buy", 0) + action_counts.get("sell", 0))
	if action_counts.get("travel", 0) > 0:
		summary.text += "• %d ships moved to new locations\n" % action_counts.get("travel", 0)

	news_container.add_child(summary)

func _add_headlines() -> void:
	title_label.text = "GALACTIC NEWS"

	for item in news_items:
		var headline: String = item.get("headline", "")
		if headline.is_empty():
			continue

		var news_label: Label = Label.new()
		news_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		news_label.text = "• " + headline
		news_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Color based on type
		var news_type: String = item.get("type", "")
		match news_type:
			"bankruptcy":
				news_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			"event_loss":
				news_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.3))
			"major_buy", "major_sell":
				news_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
			_:
				news_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

		news_container.add_child(news_label)

		# Add spacing
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.y = 8
		news_container.add_child(spacer)

func _on_close_pressed() -> void:
	hide()
	BotManager.clear_news()  # Clear news after viewing
	closed.emit()
