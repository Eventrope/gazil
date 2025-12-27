extends Control

@onready var event_title: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/EventTitle
@onready var event_description: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/EventDescription
@onready var choices_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var outcome_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/OutcomeLabel
@onready var continue_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton

var current_event: GameEvent = null

func _ready() -> void:
	current_event = EventManager.get_current_event()

	if current_event == null:
		# No event, return to map
		get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
		return

	_display_event()

func _display_event() -> void:
	event_title.text = current_event.event_name
	event_description.text = current_event.description

	# Set title color based on event type
	match current_event.event_type:
		"good":
			event_title.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		"bad":
			event_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		_:
			event_title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))

	# Create choice buttons
	for i in range(current_event.get_choice_count()):
		var button := Button.new()
		button.text = current_event.get_choice_text(i)
		button.custom_minimum_size = Vector2(400, 45)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_on_choice_pressed.bind(i))

		# Add risk indicator if there's a success chance
		if current_event.has_success_chance(i):
			var chance := current_event.get_success_chance(i)
			button.text += " [%d%% success]" % int(chance * 100)

		choices_container.add_child(button)

func _on_choice_pressed(choice_index: int) -> void:
	# Hide choices
	for child in choices_container.get_children():
		child.queue_free()

	# Execute the choice
	var result := EventManager.execute_choice(choice_index)

	# Show outcome
	outcome_label.text = result["message"]
	outcome_label.visible = true

	# Add effect details
	var effects: Dictionary = result.get("effects", {})
	if not effects.is_empty():
		var effects_text := _format_effects(effects)
		if not effects_text.is_empty():
			outcome_label.text += "\n\n" + effects_text

	# Color outcome based on whether it was good or bad
	if _is_positive_outcome(effects):
		outcome_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	elif _is_negative_outcome(effects):
		outcome_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		outcome_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	continue_button.visible = true

func _format_effects(effects: Dictionary) -> String:
	var parts: Array[String] = []

	if effects.has("credits"):
		var amount: int = effects["credits"]
		if amount > 0:
			parts.append("+%d credits" % amount)
		else:
			parts.append("%d credits" % amount)

	if effects.has("fuel"):
		var amount: int = effects["fuel"]
		if amount > 0:
			parts.append("+%d fuel" % amount)
		else:
			parts.append("%d fuel" % amount)

	if effects.has("cargo_lost"):
		var lost: Dictionary = effects["cargo_lost"]
		for commodity_id in lost:
			var commodity := DataRepo.get_commodity(commodity_id)
			var commodity_name: String = commodity.commodity_name if commodity else commodity_id
			parts.append("Lost %d %s" % [lost[commodity_id], commodity_name])

	if effects.has("cargo_gained"):
		var gained: Dictionary = effects["cargo_gained"]
		for commodity_id in gained:
			var commodity := DataRepo.get_commodity(commodity_id)
			var commodity_name: String = commodity.commodity_name if commodity else commodity_id
			parts.append("Gained %d %s" % [gained[commodity_id], commodity_name])

	return ", ".join(parts)

func _is_positive_outcome(effects: Dictionary) -> bool:
	if effects.get("credits", 0) > 0:
		return true
	if effects.get("fuel", 0) > 0:
		return true
	if effects.has("cargo_gained"):
		return true
	return false

func _is_negative_outcome(effects: Dictionary) -> bool:
	if effects.get("credits", 0) < 0:
		return true
	if effects.get("fuel", 0) < 0:
		return true
	if effects.has("cargo_lost"):
		return true
	return false

func _on_continue_pressed() -> void:
	# Check game over conditions
	var game_over := GameState.check_game_over()
	if game_over["game_over"]:
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
