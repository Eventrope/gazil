extends Control

@onready var news_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/NewsList
@onready var no_news_label: Label = $MarginContainer/VBoxContainer/NoNewsLabel
@onready var day_label: Label = $MarginContainer/VBoxContainer/Header/DayLabel

func _ready() -> void:
	_update_day_label()
	_build_news_list()

func _update_day_label() -> void:
	if GameState.player:
		day_label.text = "Day: %d" % GameState.player.day

func _build_news_list() -> void:
	# Clear existing
	for child in news_list.get_children():
		child.queue_free()

	var active_events := GameState.get_active_news_events()

	if active_events.is_empty():
		no_news_label.visible = true
		return

	no_news_label.visible = false

	for event in active_events:
		var card := _create_news_card(event)
		news_list.add_child(card)

func _create_news_card(event: NewsEvent) -> PanelContainer:
	var card := PanelContainer.new()

	# Style based on category
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	match event.category:
		"economic":
			style.bg_color = Color(0.15, 0.12, 0.05, 1)
			style.border_color = Color(0.8, 0.6, 0.2, 1)
		"political":
			style.bg_color = Color(0.15, 0.05, 0.05, 1)
			style.border_color = Color(0.8, 0.2, 0.2, 1)
		"natural":
			style.bg_color = Color(0.05, 0.1, 0.15, 1)
			style.border_color = Color(0.2, 0.5, 0.8, 1)
		_:
			style.bg_color = Color(0.1, 0.1, 0.12, 1)
			style.border_color = Color(0.4, 0.4, 0.5, 1)

	style.border_width_left = 3
	style.border_width_right = 0
	style.border_width_top = 0
	style.border_width_bottom = 0

	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Header row: category icon + headline + duration
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)

	# Category icon/label
	var category_label := Label.new()
	category_label.add_theme_font_size_override("font_size", 14)
	match event.category:
		"economic":
			category_label.text = "[ECONOMIC]"
			category_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2, 1))
		"political":
			category_label.text = "[POLITICAL]"
			category_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1))
		"natural":
			category_label.text = "[NATURAL]"
			category_label.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9, 1))
	header.add_child(category_label)

	# Headline
	var headline := Label.new()
	headline.text = event.headline
	headline.add_theme_font_size_override("font_size", 20)
	headline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(headline)

	# Duration
	var days_left := event.days_remaining(GameState.player.day)
	var duration_label := Label.new()
	if days_left == 1:
		duration_label.text = "1 day remaining"
	else:
		duration_label.text = "%d days remaining" % days_left
	duration_label.add_theme_font_size_override("font_size", 14)
	duration_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7, 1))
	header.add_child(duration_label)

	# Description
	var description := Label.new()
	description.text = event.description
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description)

	# Effects summary
	var effects_text := _format_effects(event)
	if not effects_text.is_empty():
		var effects_label := Label.new()
		effects_label.text = effects_text
		effects_label.add_theme_font_size_override("font_size", 14)
		effects_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.5, 1))
		vbox.add_child(effects_label)

	return card

func _format_effects(event: NewsEvent) -> String:
	var parts: Array[String] = []

	# Affected locations
	var planets := event.get_affected_planets_list()
	if not planets.is_empty():
		var planet_names: Array[String] = []
		for planet_id in planets:
			if planet_id == "All Locations":
				planet_names.append(planet_id)
			else:
				var planet := DataRepo.get_planet(planet_id)
				if planet:
					planet_names.append(planet.planet_name)
				else:
					planet_names.append(planet_id.capitalize())
		parts.append("Locations: " + ", ".join(planet_names))

	# Effects
	var effect_parts: Array[String] = []

	if event.get_price_modifier() != 1.0:
		var mod := event.get_price_modifier()
		if mod > 1.0:
			effect_parts.append("Prices +%d%%" % [int((mod - 1.0) * 100)])
		else:
			effect_parts.append("Prices -%d%%" % [int((1.0 - mod) * 100)])

	if event.get_travel_time_modifier() > 1.0:
		effect_parts.append("Travel +%d%%" % [int((event.get_travel_time_modifier() - 1.0) * 100)])

	if event.blocks_access():
		effect_parts.append("Access Blocked")

	if event.get_event_chance_modifier() > 1.0:
		effect_parts.append("Increased Danger")

	if not effect_parts.is_empty():
		parts.append("Effects: " + ", ".join(effect_parts))

	return " | ".join(parts)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
